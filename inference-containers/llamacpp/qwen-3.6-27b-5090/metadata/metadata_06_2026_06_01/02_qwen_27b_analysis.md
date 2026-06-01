# Qwopus3.6-27B-v2-MTP Analysis on RTX 5090

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
| Model | `Jackrong/Qwopus3.6-27B-v2-MTP-GGUF:Q4_K_M` (multimodal) |
| n_ctx_seq | 131072 (n_ctx_train = 262144, warning logged) |
| Flash Attention | on |
| Cache Type | q8_0 for K and V |
| Threads | 12 gen / 24 batch |
| Spec Decoding | draft-mtp, n_max=2, p_min=0.8 |
| Slots (n_parallel) | 4 (auto-detected, kv_unified=true) |
| Prompt Cache | 8192 MiB limit |
| mlock | on |

## Memory Budget at Startup

| Component | Size | Source |
|-----------|------|--------|
| Model weights (Q4_K_M) | ~15.3 GiB | estimated from GGUF file |
| mmproj (F32) | 1161 MiB | log line `mmproj is 1161.02 MiB` |
| MTP draft context | 1129 MiB | log line `MTP context is 1129.00 MiB` |
| KV cache (q8_0 K+V, 4 slots × 131K) | ~9.8 GiB | calculated below |
| **Total at startup** | **~27.4 GiB** | of 32 GiB |
| **Headroom** | **~5.6 GiB** | for activations, prompt cache, etc. |

### KV Cache Calculation (q8_0 K+V, per token)

- Embedding dim: n_embd=5120
- K head dim = 4096 × 1 byte (q8_0) = 4096 B
- V head dim = 3584 × 1 byte (q8_0) = 3584 B
- Per token per slot: 7680 B ≈ 7.5 KiB
- Per slot (131K ctx): 131072 × 7.5 KiB ≈ 976 MiB
- 4 slots: ~3.8 GiB

**Wait — checkpoint sizes in the log tell a different story.** Each checkpoint at ~65K tokens is ~390-430 MiB. That's roughly 7.2 KiB per token per slot, confirming the q8_0 calculation. But these are single-slot checkpoints, and with 4 parallel slots the total KV cache is:

- 4 × 131072 × 7680 B = 4.0 GiB (not 9.8 — earlier calc was wrong)

Revised memory budget:
| Component | Size |
|-----------|------|
| Model weights + mmproj + MTP context | ~17.6 GiB |
| KV cache (4 slots, q8_0, 131K) | ~4.0 GiB |
| **Total at startup** | **~21.6 GiB** |
| **Headroom** | **~11 GiB** |

That's much more headroom than initially assumed. The log confirms this — the server started fine with 30930 MiB free and loaded everything without OOM.

## Performance Analysis by Task Type

### Cold Start (Task 0: ~49K new tokens)

| Metric | Value |
|--------|-------|
| Prompt eval speed | **2500 t/s** (49688 tokens / 19.9s) |
| Decode speed | **49 t/s** (103 tokens / 2.1s) |
| Draft acceptance | 84.6% (44 accepted / 52 generated) |
| Graphs reused | 18 |

Cold start is the best case for prompt eval — GPU cache empty, processing fresh data sequentially. The 2500 t/s baseline is the key number for estimating full-context warmup times.

### Warm Runs (incremental, from checkpoint)

Grouping by context delta:

**Small deltas (174-600 new tokens):**
| Task | Prompt Eval | Decode | Acceptance |
|------|------------|--------|------------|
| 3594 | 850 t/s (227 tok) | 80 t/s (166 tok) | 99.0% |
| 3444 | 846 t/s (230 tok) | 72 t/s (82 tok) | 100% |
| 3660 | 481 t/s (412 tok) | 67 t/s (87 tok) | 96.2% |

**Medium deltas (1-3K new tokens):**
| Task | Prompt Eval | Decode | Acceptance |
|------|------------|--------|------------|
| 298 | **984 t/s** (2609 tok) | **94 t/s** (268 tok) | 98.3% |
| 522 | **1567 t/s** (9491 tok) | **66 t/s** (151 tok) | 94.4% |
| 89 | 1061 t/s (2517 tok) | 52 t/s (173 tok) | 82.8% |

**Large deltas (rollback + re-process, 4-7K new tokens):**
| Task | Prompt Eval | Decode | Acceptance |
|------|------------|--------|------------|
| 397 | 1320 t/s (6785 tok) | 49 t/s (208 tok) | 87.5% |
| 2724 | 1138 t/s (4813 tok) | 57 t/s (199 tok) | 89.1% |

### Decode Speed Summary

Excluding the cold start and the worst outliers, decode speed with MTP speculative decoding ranges **~60-94 t/s**. The distribution:

- **≥ 80 t/s**: 10 tasks (26%) — short outputs or near-perfect MTP acceptance
- **60-79 t/s**: 15 tasks (39%) — typical range
- **< 60 t/s**: 14 tasks (39%) — longer reasoning outputs, lower acceptance

**Average decode speed across all tasks: ~68 t/s**

### Prompt Eval Speed Summary

| Context Delta | Avg Speed | Notes |
|---------------|-----------|-------|
| Cold start (~49K) | 2500 t/s | GPU cold, sequential |
| Small (≤1K) | 500-850 t/s | Cache overhead dominates |
| Medium (1-3K) | 984-1567 t/s | Sweet spot for batch throughput |
| Large rollback+reproc (4-10K) | 1138-1567 t/s | Higher token count helps amortize overhead |

## MTP Speculative Decoding Effectiveness

### Acceptance Rate by Task

Best to worst:
| Rate | Tasks | Decode t/s |
|------|-------|-----------|
| 100% | 3481, 1185, 2940, 779, 1230 | 78-88 t/s |
| 98-99% | 298, 1498, 1330, 3699, 3594, 3177 | 51-80 t/s |
| 94-97% | 522, 597, 1641, 3402, 2198, 2511, 3660 | 50-80 t/s |
| 87-93% | 397, 2724, 2864, 3444, 3783, 1883 | 48-70 t/s |
| 82-84% | 0 (cold), 89, 1753, 1282 | 42-88 t/s |

**Overall average acceptance: ~93.2%** across all tasks. The MTP with n_max=2 and p_min=0.8 is working well — the draft model correctly predicts most tokens.

### Speedup from Speculative Decoding

Without MTP, 1 decoded token requires 1 full forward pass. With MTP (n_max=2), each pass can propose up to 3 tokens (1 target + 2 drafts). At 93% acceptance:
- Average accepted per pass ≈ 2.8 tokens out of 3 proposed
- Effective speedup ≈ **2.5-2.8x** over non-speculative decoding

Without MTP, the ~68 t/s decode speed would be roughly **24-27 t/s**.

### Acceptance Degradation Over Time

There's a slight downward trend in acceptance rate as cumulative tokens increase:
- Early tasks (0-10): 84-98% → avg 93.5%
- Middle tasks (11-20): 87-100% → avg 94.8%
- Later tasks (21-42): 82-100% → avg 93.0%

No significant degradation — the model remains stable over long conversations.

## Context Window Pushability Analysis

### Current: 131K → Target: 262K (n_ctx_train) or beyond

The log warns `n_ctx_seq (131072) < n_ctx_train (262144)` — the model was trained on 262K context but we're only using half. Since this is single-user, dropping to 1-2 slots frees massive VRAM for KV cache expansion.

### Memory Feasibility at Larger Contexts (Per token per slot: ~7 KiB q8_0)

| Slots | Context | KV Cache | Fixed Model+MTP | Total | Headroom |
|-------|---------|----------|-----------------|-------|----------|
| **1** | **256K** | 1.9 GiB | 17.6 GiB | **~19.5 GiB** | **13 GiB** ✅ |
| 1 | 512K | 3.8 GiB | 17.6 GiB | ~21.4 GiB | 11 GiB ✅ |
| 2 | 256K | 3.8 GiB | 17.6 GiB | ~21.4 GiB | 11 GiB ✅ |
| 2 | 512K | 7.5 GiB | 17.6 GiB | ~25.1 GiB | 7 GiB ⚠️ |
| 4 | 256K | 7.5 GiB | 17.6 GiB | ~25.1 GiB | 7 GiB ⚠️ |

**Key insight:** At 1 slot, 256K costs only ~1.9 GiB of KV cache — trivial. Even 512K at 1 slot leaves 11 GiB headroom. The 4-slot config was the real constraint all along.

### Speed Impact at Larger Contexts (Single Slot)

At 131K cold start: 2500 t/s prompt eval. With flash attention, scaling is roughly O(n):
- Estimated at 256K: **~2300 t/s** (warmup ~111s for full context)
- Expected decode degradation: minimal — attention is O(n) with flash attn, maybe 5-10% slower: **~61-65 t/s**

### Checkpoint Memory at Larger Contexts

Checkpoint sizes scale linearly. At 256K:
- Estimated per-checkpoint: ~700 MiB (vs ~430 MiB at 65K)
- With max 32 checkpoints: ~22 GiB if all slots fill — **consider reducing checkpoint count or disabling** with `--ctx-checkpoint-max 8`

### Recommended Test Progression (Single User, 1 Slot)

| Step | --ctx-size | n_parallel | What to Validate |
|------|-----------|-----------|-----------------|
| 1 | **256K** | **1** | OOM test, quality at full training context |
| 2 | 384K | 1 | Beyond n_ctx_train — does quality degrade? |
| 3 | 512K | 1 | Extreme context stress test |

### Key Risk Factors for Larger Context

1. **Activation memory spikes** during long reasoning outputs — hardest to predict, could OOM despite good base budget
2. **Quality degradation** beyond n_ctx_train (262K) — the model wasn't trained past that point; 384K+ is uncharted territory
3. **Prompt cache at 8 GiB** — may be too small for huge contexts; consider `--cache-ram 0` to disable if hitting limits
4. **CUDA graph recompilation** — longer sequences mean more graph variants

## Recommendations

### For Context Window Push (Primary Goal)

1. **Set n_parallel=1** — single user, no need for 4 slots. Saves ~3 GiB VRAM at current context, ~5.7 GiB at 256K vs 2 slots
2. **Jump straight to 256K** — memory is not the constraint anymore with 1 slot
3. **Add `--ctx-checkpoint-max 8`** — reduce checkpoint overhead for large contexts
4. **Monitor quality** after 262K — if it degrades, that's the practical limit regardless of VRAM

### Threading Tuning

Current: `--threads 12 --threads-batch 24` on a 32-thread (16-core) CPU. Consider testing:
- `--threads 16` (use all physical cores for generation)
- `--threads-batch 32` (use all logical threads for batch/prompt processing)

### MTP Tuning

Current `--spec-draft-n-max 2 --spec-draft-p-min 0.8` is performing well (93% acceptance). Fine-tuning opportunities:
- Test `n_max 3` — more aggressive speculation, but p_min threshold may cause early exit
- Test `p_min 0.7` — accept slightly riskier drafts

### Other Observations

- **Graph reuse** is excellent (2000+ graphs reused by task 3481) — CUDA graph caching is working well
- **Checkpoint invalidation** happens frequently during rollbacks — this is expected behavior but adds latency when the user revisits earlier conversation points
- **Reasoning budget** consistently deactivates at natural end — no issues with early termination

## Next Action

Update `docker-compose-qwopus.yml` with `--ctx-size 256K`, set `n_parallel=1` (or just remove the 4-slot default by adding a flag), and test.
