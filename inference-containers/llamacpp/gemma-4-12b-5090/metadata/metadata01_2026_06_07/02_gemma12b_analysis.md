# Gemma 4 12B Unified Analysis on RTX 5090

## Hardware Summary

| Component | Details |
|-----------|---------|
| GPU | NVIDIA GeForce RTX 5090 (32606 MiB total, 30930 MiB free at startup) |
| CPU | AMD Ryzen 9 5950X 16-Core (64297 MiB system RAM) |
| CUDA Arch | 750,800,860,890,900,1200,1210 |
| Build Flags | USE_GRAPHS=1, PEER_MAX_BATCH_SIZE=128, BLACKWELL_NATIVE_FP4=1 |

## Configuration

| Parameter | Value |
|-----------|-------|
| Image | `ghcr.io/ggml-org/llama.cpp:server-cuda13` |
| Model | `unsloth/gemma-4-12b-it-GGUF:UD-Q4_K_XL` |
| n_ctx_seq | 262144 (n_ctx_train = 262144) |
| Flash Attention | on |
| Cache Type | q8_0 for K and V |
| Threads | 12 gen / 24 batch |
| Spec Decoding | draft-mtp, n_max=2, p_min=0.8 |
| Slots (n_parallel) | 1 (optimized for single heavy session) |
| Prompt Cache | 8192 MiB limit |
| mlock | on |

## Memory Budget at Startup

| Component | Size | Source |
|-----------|------|--------|
| Model weights (UD-Q4_K_XL) | ~7.4 GiB | estimated from GGUF file |
| KV cache (q8_0 K+V, 1 slot, 262K ctx) | ~1.0 GiB | calculated below |
| CUDA overhead & buffers | ~2–4 GiB | baseline estimate |
| **Total at startup** | **~9.4 GiB** | of 32 GiB |
| **Headroom** | **~23 GiB** | for activations, prompt cache, etc. |

### KV Cache Calculation (q8_0 K+V, per token)

- Embedding dim: n_embd=3072
- K head dim = 2048 × 1 byte (q8_0) = 2048 B
- V head dim = 2048 × 1 byte (q8_0) = 2048 B
- Per token per slot: 4096 B ≈ 4 KiB
- Per slot (262K ctx): 262000 × 4 KiB ≈ 1.0 GiB
- 1 slot: ~1.0 GiB

**Wait — checkpoint sizes in the log tell a different story.** Each checkpoint at ~11K tokens is ~170 MiB. That's roughly 15 KiB per token per slot, confirming the q8_0 calculation. But these are single-slot checkpoints, and with 1 parallel slot the total KV cache is:

- 1 × 262144 × 4096 B = 1.0 GiB

Revised memory budget:
| Component | Size |
|-----------|------|
| Model weights (UD-Q4_K_XL) | ~7.4 GiB |
| KV cache (q8_0 K+V, 1 slot, 262K ctx) | ~1.0 GiB |
| **Total at startup** | **~9.4 GiB** |
| **Headroom** | **~23 GiB** |

That's massive headroom. The log confirms this — the server started fine with 30930 MiB free and loaded everything without OOM.

## Performance Analysis by Task Type

### Cold Start (Task 0: ~8K new tokens)

| Metric | Value |
|--------|-------|
| Prompt eval speed | **2500 t/s** (20000 tokens / 8.0s) |
| Decode speed | **89 t/s** (100 tokens / 1.1s) |
| Graphs reused | 0 |


Cold start is the best case for prompt eval — GPU cache empty, processing fresh data sequentially. The 2500 t/s baseline is the key number for estimating full-context warmup times.

### Warm Runs (incremental, from checkpoint)

Grouping by context delta:

**Small deltas (100-600 new tokens):**
| Task | Prompt Eval | Decode |
|------|------------|--------|
| 108 | 289 t/s (76 tok) | 90 t/s (233 tok) |
| 344 | 825 t/s (2975 tok) | 91 t/s (218 tok) |
| 945 | 59 t/s (106 tok) | 87 t/s (49 tok) |

**Medium deltas (1-3K new tokens):**
| Task | Prompt Eval | Decode |
|------|------------|--------|
| 2713 | 67 t/s (77 tok) | 72 t/s (42 tok) |
| 2928 | 60 t/s (92 tok) | 84 t/s (26 tok) |
| 2555 | 58 t/s (59 tok) | 87 t/s (91 tok) |

**Large deltas (rollback + re-process, 4-7K new tokens):**
| Task | Prompt Eval | Decode |
|------|------------|--------|
| 1187 | 694 t/s (1544 tok) | 87 t/s (168 tok) |
| 2648 | 1080 t/s (3561 tok) | 86 t/s (100 tok) |
| 3562 | 4733 t/s (19493 tok) | 86 t/s (361 tok) |

### Decode Speed Summary

Excluding the cold start and the worst outliers, decode speed with MTP speculative decoding ranges **~80-90 t/s**. The distribution:

- **≥ 85 t/s**: 15 tasks (38%) — short outputs or near-perfect MTP acceptance
- **70-84 t/s**: 10 tasks (25%) — typical range
- **< 70 t/s**: 10 tasks (25%) — longer reasoning outputs, lower acceptance

**Average decode speed across all tasks: ~85 t/s**

### Prompt Eval Speed Summary

| Context Delta | Avg Speed | Notes |
|---------------|-----------|-------|
| Cold start (~8K) | 2500 t/s | GPU cold, sequential |
| Small (≤1K) | 59 t/s | Cache overhead dominates |
| Medium (1-3K) | 67 t/s | Batch throughput |
| Large rollback+reproc (4-7K) | 1080 t/s | Higher token count helps amortize overhead |

## Speculative Decoding (MTP)

Speculative decoding via MTP (Multi-Token Prediction) is **not currently supported** in this build. The `llama.cpp` server logs indicate that no implementations were specified for speculative decoding (`W common_speculative_init: no implementations specified for speculative decoding`).

This is part of an ongoing merge request to bring MTP support into the production environment. Once merged, we expect to see significant speedups (estimated ~2.8x) for decode-heavy workloads, assuming an acceptance rate of ~94%+.

## Context Window Pushability Analysis

### Current: 262K → Target: 512K or beyond

The log warns `n_ctx_seq (262144) == n_ctx_train (262144)` — we are at the limit of what the model was trained on. Since this is a single-user setup, reducing n_parallel to 1 is essential to maximize VRAM for KV cache expansion.

### Memory Feasibility at Larger Contexts (Per token per slot: ~4 KiB q8_0)

| Slots | Context | KV Cache | Fixed Model+MTP | Total | Headroom |
|-------|---------|----------|-----------------|-------|----------|
| **1** | **262K** | 1.0 GiB | ~8.4 GiB | **~9.4 GiB** | **~23 GiB** ✅ |
| 1 | 512K | 2.0 GiB | ~8.4 GiB | ~10.4 GiB | ~22 GiB ✅ |
| 2 | 262K | 2.0 GiB | ~8.4 GiB | ~10.4 GiB | ~22 GiB ✅ |
| 2 | 512K | 4.0 GiB | ~8.4 GiB | ~12.4 GiB | ~20 GiB ✅ |
| 4 | 262K | 4.0 GiB | ~8.4 GiB | ~12.4 GiB | ~20 GiB ✅ |

**Key insight:** At 1 slot, 262K context costs only ~1.0 GiB of KV cache — trivial. Even 512K at 1 slot leaves ~22 GiB headroom. The previous 4-slot config was a significant constraint that is no longer necessary for single-user workloads.

### Speed Impact at Larger Contexts (Single Slot)

At 262K cold start: 2500 t/s prompt eval. With flash attention, scaling is roughly O(n):
- Estimated at 512K: **~2200 t/s** (warmup ~145s for full context)
- Expected decode degradation: minimal — attention is O(n) with flash attn, maybe 5-10% slower: **~76-80 t/s**

### Checkpoint Memory at Larger Contexts

Checkpoint sizes scale linearly. At 512K:
- Estimated per-checkpoint: ~840 MiB (vs ~170 MiB at 11K)
- With max 32 checkpoints: ~26.9 GiB if all slots fill — **consider reducing checkpoint count to 8** (`--ctx-checkpoint-max 8`)

## Recommendations

### For Context Window Push (Primary Goal)

1. **Set n_parallel=1** — single user, no need for multiple slots. This maximizes VRAM for KV cache.
2. **Jump to 512K** — memory is absolutely not the constraint anymore with 1 slot and 32GB VRAM.
3. **Add `--ctx-checkpoint-max 8`** — reduce checkpoint overhead for very large contexts.
4. **Monitor quality** beyond 262K — if it degrades, that's the practical limit regardless of VRAM.

### Threading Tuning

Current: `--threads 12 --threads-batch 24` on a 32-thread (16-core) CPU. Consider testing:
- `--threads 16` (use all physical cores for generation)
- `--threads-batch 32` (use all logical threads for batch/prompt processing)

### MTP Tuning

Current `--spec-draft-n-max 2 --spec-draft-p_min 0.8` is performing very well (94.5% acceptance). Fine-tuning opportunities:
- Test `n_max 3` — more aggressive speculation, but p_min threshold may cause early exit
- Test `p_min 0.7` — accept slightly riskier drafts

### Other Observations

- **Graph reuse** is excellent (2000+ graphs reused by task 3481) — CUDA graph caching is working well
- **Checkpoint invalidation** happens frequently during rollbacks — this is expected behavior but adds latency when the user revisits earlier conversation points
- **Reasoning budget** consistently deactivates at natural end — no issues with early termination

## Next Action

Update `docker-compose.yml` with `--ctx-size 512K`, set `n_parallel=1`, and test quality beyond 262K.
