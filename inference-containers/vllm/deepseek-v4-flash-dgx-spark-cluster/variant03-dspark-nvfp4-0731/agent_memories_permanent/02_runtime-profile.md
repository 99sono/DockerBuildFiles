# Runtime Profile

The tuned profile this variant ships with (the "0731 CURRENT BEST" profile) and the
reasoning behind each knob. These live in the per-node `.env` (committed defaults in
`.env.example`).

## Core serving / parallelism

| Knob | Value | Why |
|---|---|---|
| `MAX_MODEL_LEN` | `1048576` | Full 1M context — the point of the 0731 release. |
| `MAX_NUM_BATCHED_TOKENS` | `8192` | Chunked prefill ceiling; bounds per-step memory for long prompts. |
| `MAX_NUM_SEQS` | `6` | Concurrency cap; 1M-ctx KV is large, so keep in-flight sequences low. |
| `GPU_MEMORY_UTILIZATION` | `0.78` | Leave headroom for 1M KV growth; 0.9+ OOMs under long-context load. |
| `VLLM_ENGINE_READY_TIMEOUT_S` | `3600` | Cold start (156 GB load + torch.compile) exceeds the default timeout. |

## DSpark / speculative decoding

| Knob | Value | Why |
|---|---|---|
| `MTP_NUM_TOKENS` | `5` | Speculative draft length, locked at k≤5 (matches `dspark_block_size=5`). |
| `DSPARK_SLOT_CLAMP` | `1` | **Protective clamp, do not casually disable.** See below. |
| `VLLM_DSPARK_CONFIDENCE_SCHEDULER` | `off` | Part of the upstream profile; leave as-is. |

### `DSPARK_SLOT_CLAMP` — the one knob with a story

A stale/out-of-range ring-buffer `slot_index` (observed after request condensation at
long context) made a KV gather read row ≥ `num_rows`, triggering a device-side
`indexSelectSmallIndex` assert that **killed the worker**. The clamp bounds the slot
into range on-device so the gather degrades to a *rejected speculation* instead of a
crash. It's graph-safe (pure device op, baked into the captured CUDA graph) and only
affects the draft path — a clamped (wrong) slot yields a bad draft token that the
target model rejects at verification, so it can't corrupt output.

`DSPARK_SLOT_CLAMP=0` is the A/B **kill switch**: it reverts to detect-and-log only
(so you can verify the clamp is load-bearing on your rig). Read once at import.
Keep `1` in production.

## Quantization note

"NVFP4" refers to the **KV cache dtype** (`nvfp4_ds_mla`) + the B12X MoE backend —
both live **in the image**, not the checkpoint. The checkpoint is pre-quantized
(FP4 experts + FP8 e4m3). `scale_fmt=ue8m0` in `config.json` auto-enables UE8M0 for
DeepGEMM at boot.

## `reasoning_effort` behavior (post-upstream-sync)

`reasoning_effort="max"` now injects DeepSeek's real 526-char max-thinking text
instead of the generic "high" text. `"high"` / omitted are unchanged. Folded in via
the upstream sync — don't "fix" the max-text length back.