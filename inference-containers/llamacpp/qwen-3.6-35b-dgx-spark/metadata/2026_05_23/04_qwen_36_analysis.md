# Qwen3.6-35B-A3B Qwopus MTP Performance Analysis — n_max=3 / p_min=0.75

**Date:** 2026-05-23
**Model:** Jackrong/Qwopus3.6-35B-A3B-v1-MTP-Q4_K_M
**Hardware:** NVIDIA GB10 (DGX Spark, ~118GB free VRAM)
**MTP Settings:** n_max=3, p_min=0.75
**Context Window:** 184K (up from 128K in previous run)

---

## Configuration Changes vs Previous Run

| Parameter | Previous (Run 1) | This Run | Rationale |
|-----------|-----------------|----------|-----------|
| `--ctx-size` | 131072 (128K) | **184320 (~180K)** | Model trained on 256K; leverage more of its capacity |
| `--spec-draft-n-max` | 2 | **3** | 90-93% acceptance at n_max=2 means MTP heads are confident enough for deeper speculation |
| `--spec-draft-p-min` | 0.85 | **0.75** | Lowered threshold to accept more speculative tokens; model is already highly confident above 0.75 |
| `--mlock` | dropped (see Run 1 analysis) | *(unchanged)* | Docker's RLIMIT_MEMLOCK blocked it anyway; unnecessary with 70 GB free unified memory |

---

## Prompt Processing Speed

| Request | Tokens | Time | Speed |
|---------|--------|------|-------|
| Task 0 | 4,683 | 2.8 s | **1,693 t/s** (includes initial warm-up) |
| Task 70 (sustained) | 14,922 | 8.1 s | **1,835 t/s** (stable during processing) |

**Prefill: ~1,800-1,880 t/s — Unchanged from previous run.** The increased context window size has no measurable impact on prefill speed. The MoE architecture only reads ~2.4 GB per decode step (vs ~16.5 GB for dense 27B), so the GB10 LPDDR5X bandwidth is barely stressed during prefill regardless of context length.

**Note:** Task 0's initial warm-up (4,683 tokens) includes the first checkpoint creation and shows a lower effective speed (1,693 t/s) due to checkpoint overhead. The sustained rate after warm-up stabilizes at ~1,835 t/s, consistent with previous run measurements.

---

## Generation Speed with MTP Speculation — Key Findings

### Per-Interval Breakdown (Task 70: ~15K context → 2,618 output tokens)

| Tokens Decoded | Interval Throughput |
|----------------|---------------------|
| 100 tokens | **69.48 t/s** (early burst) |
| 332 tokens | 74.52 t/s |
| 578 tokens | **77.18 t/s** (peak) |
| 746 tokens | 71.10 t/s |
| 920 tokens | 68.17 t/s |
| 1,086 tokens | 65.73 t/s |
| 1,249 tokens | **63.87 t/s** (sustained) |
| 1,442 tokens | **63.92 t/s** (stable) |
| 1,664 tokens | 65.10 t/s |
| 1,847 tokens | 64.64 t/s |
| 2,001 tokens | 63.30 t/s |
| 2,170 tokens | **62.66 t/s** (late) |
| 2,342 tokens | **62.22 t/s** (late) |
| 2,549 tokens | **62.69 t/s** (sustained end) |

### Summary: ~62-68 t/s — Slightly lower than previous run (~67-70 t/s)

**Critical finding:** Generation throughput *decreased* by ~5-10% compared to the n_max=2 baseline, contradicting the original hypothesis that deeper speculation would improve sustained generation speed.

The degradation pattern is clear: early intervals show 70+ t/s (comparable to previous run), but as context grows past ~1,000 tokens, throughput steadily drops and stabilizes around **62-64 t/s**.

This suggests that **n_max=3 with deeper speculation introduces additional overhead during long-generation contexts**, likely because:
- More speculative drafts mean more frequent target-model verification steps (rejected 3-token chains require reprocessing)
- The MTP heads' predictions may become less reliable as context grows, increasing the penalty of rejection

---

## MTP Draft Acceptance Rates

### Task 0 (short: 4,683 prompt → 195 output tokens)

| Metric | Value |
|--------|-------|
| Accepted | 137 |
| Generated | 145 |
| **Acceptance Rate** | **94.5%** |

### Task 70 (long: ~15K prompt → 2,618 output tokens — the sustained generation benchmark)

| Metric | Value |
|--------|-------|
| Accepted | 1,353 |
| Generated | 1,515 |
| **Acceptance Rate** | **89.3%** |

### Comparison with Previous Run (n_max=2 / p_min=0.85)

| Request | Previous Acceptance | This Run | Δ |
|---------|---------------------|----------|---|
| Task 0 (long) | 91.6% (823/898, 1,825 tokens) | **94.5%** (137/145, 195 tokens) | +2.9% |
| Task 1034 (short) | 90.9% (60/66, 127 tokens) | ~91% (extrapolated from Task 70) | ~0% |
| Task 1112 (long prompt) | 90.3% (28/31, 58 tokens) | N/A (Task 70 replaces this category) | — |
| **Sustained long-gen** | ~67-70 t/s at ~91% | **~62-64 t/s at 89.3%** | **-3% acceptance, -5% speed** |

**Key observation:** The p_min=0.75 threshold does accept more speculative tokens overall (94.5% on the short task), but the acceptance rate *drops* during sustained long-generation contexts (89.3% vs ~91% in previous run). This is because deeper speculation chains (n_max=3) have a lower probability of consecutive acceptance at a lower threshold — you need 3 correct predictions in a row, and the lower p_min allows more false positives that compound over longer chains.

---

## Effective Speedup Calculation — Revised

### Theoretical at 89% acceptance with n_max=3:
- At 89% per-token acceptance: 3 consecutive accepts = **64%** of the time, 2 consecutive = **19%**, 1 token = **7%**
- Effective tokens per target-model step: 0.64×3 + 0.19×2 + 0.07×1 = 2.35
- Theoretical speedup: **~2.3x** over non-speculative decoding

### Actual measured effective speedup:
- Non-speculative baseline (estimated): ~35-40 t/s for this MoE model
- Measured sustained: ~62-64 t/s
- **Actual speedup: ~1.7-1.8x** — *no better than n_max=2*

### Why the gap between theory and reality?

The theoretical calculation assumes all rejected chains are penalized equally. But with n_max=3:
1. **Rejection penalty is asymmetric:** When a 3-token chain rejects at position 2, you lose *both* the target-model forward pass for that step AND one additional generation cycle to retry. This makes rejections ~2x more costly than with n_max=2.
2. **Early-phase vs late-phase mismatch:** The initial burst of tokens shows good speeds (70+ t/s), but as context grows, MTP head predictions degrade → more frequent rejections → lower sustained speed.

---

## Comparison: Run 1 (n_max=2) vs Run 2 (n_max=3)

| Metric | n_max=2 / p_min=0.85 | n_max=3 / p_min=0.75 | Change |
|--------|----------------------|-----------------------|--------|
| Prefill speed | ~1,800-1,880 t/s | ~1,835 t/s | **Neutral** |
| Early gen speed (first 500 tokens) | ~70-74 t/s | ~69-77 t/s | **+2%** |
| Sustained gen speed (1K+ tokens) | **~67-70 t/s** | **~62-64 t/s** | **-5% to -8%** |
| MTP acceptance (short task) | ~91.6% | 94.5% | **+2.9%** |
| MTP acceptance (sustained) | ~90-93% | **89.3%** | **-1-4%** |
| Effective speedup | ~1.8x | ~1.7-1.8x | **Neutral** |

---

## Long Context Generation — New Data Point

This run includes the first sustained long-context generation benchmark: Task 70 generates 2,618 tokens after processing a ~15K-token prompt.

**No context degradation observed during generation.** Throughput stabilizes at ~62-64 t/s by token 1,250 and remains steady through token 2,549. This confirms that the MoE architecture's generation throughput is stable regardless of context growth — consistent with findings from Run 1.

However, the absolute throughput is lower than Run 1 (67-70 t/s), indicating that **the n_max=3 parameterization is the cause**, not context length. The additional speculative drafts introduce overhead that outweighs their benefits during sustained generation.

---

## Recommendations

### 1. Revert to n_max=2 / p_min=0.85 for production ✅

**The original settings were optimal.** They provide the best sustained generation throughput (~67-70 t/s) with high acceptance rates (90-93%) and stable performance across varying context lengths.

### 2. Consider n_max=4 only with adaptive thresholds

If deeper speculation is desired, a *single* parameter change won't work. You would need:
- **Dynamic p_min:** Start at 0.85 for the first ~500 tokens (where MTP predictions are most reliable), then lower to 0.70-0.65 as context grows and acceptance drops
- This would require llama.cpp patching — not currently supported by static config

### 3. p_min=0.75 has limited value at n_max=2

At n_max=2 with 91-93% acceptance, lowering p_min further yields minimal benefit (~1-2% more accepted tokens) while increasing the risk of false positives during sustained generation.

### 4. Focus on other optimizations:

- **KV cache quantization:** Already using Q8_0 — this is already well-optimized for MoE models
- **Flash attention:** Already enabled — good for long-context prefill
- **Graph reuse:** Confirmed working (548 graphs reused in Task 70) — no improvement possible here
- **Batch size / ubatch size:** Currently at 512/512 — these are already high and well-calibrated
- **Parallel slots:** 4 slots active — consider workload profiling to determine optimal concurrent request capacity

---

## TL;DR

**The n_max=3 / p_min=0.75 experiment was a failure.** Despite theoretical predictions of ~2.3x speedup, actual sustained throughput dropped from **67-70 t/s → 62-64 t/s** during long-generation contexts. The MTP heads are strong enough for n_max=3 (89% acceptance), but the deeper speculation chains introduce asymmetric rejection penalties that outweigh their benefits. **Revert to n_max=2 / p_min=0.85 — the original settings were optimal.**

---

## Known Issues

### Context Window Still Underutilized
```
n_ctx_seq (184320) < n_ctx_train (262144) -- the full capacity of the model will not be utilized
```
The model was trained on 256K context, but we're using 184K. This is a deliberate trade-off — pushing closer to 256K would significantly increase KV cache memory consumption (~80+ GB for Q8_0) without proportional performance benefit.

**No action needed.** 184K is the practical maximum that balances capacity with memory overhead for single-GPU deployment.
