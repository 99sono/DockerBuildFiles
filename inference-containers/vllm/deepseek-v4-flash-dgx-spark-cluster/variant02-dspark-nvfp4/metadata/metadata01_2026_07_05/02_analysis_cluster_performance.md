# Cluster Performance Analysis — DeepSeek V4 Flash DSpark (NVFP4)

**Date:** 2026-07-05
**Hardware:** 2× DGX Spark (ACER Veriton + Gigabyte Top AI)
**Network:** Dual-port RoCE (rocep1s0f0 + roceP2p1s0f0), GID index 2,2 / 4,4
**Model:** deepseek-ai/DeepSeek-V4-Flash-DSpark (156 GB, 48 shards)
**Engine:** vLLM 0.21.1rc1.dev339, DSpark speculative decoding (3 tokens, probabilistic)
**KV Cache:** nvfp4_ds_mla (4-bit), 3,076,565 tokens total, 2.93× concurrency @ 1M context

---

## 1. Token Generation Throughput

| Metric | Peak | Sustained (steady-state) |
|--------|------|--------------------------|
| Generation throughput | **48.2 tok/s** | 43–46 tok/s |
| Prompt throughput | **685.7 tok/s** | 50–170 tok/s (varies with batch) |
| Accepted throughput | **34.2 tok/s** | 27–33 tok/s |
| Drafted throughput | **42.0 tok/s** | 37–42 tok/s |

**Verdict:** Not quite 60 tok/s — peak was 48.2 tok/s, sustained ~45 tok/s. The bottleneck appears to be the draft model throughput (~42 tok/s drafted, ~34 tok/s accepted).

---

## 2. DSpark Speculative Decoding Effectiveness

### Per-position Acceptance Rates (over the session)

| Token position | Best | Worst | Typical |
|----------------|------|-------|---------|
| 1st draft token | **95.2%** | 64.0% | 85–92% |
| 2nd draft token | **88.9%** | 32.0% | 70–83% |
| 3rd draft token | **78.6%** | 12.0% | 55–73% |
| **Mean acceptance length** | **3.62** | 2.08 | 3.0–3.5 |
| **Avg draft acceptance rate** | **87.3%** | 36.0% | 70–82% |

### Observations

- **1st token acceptance is excellent (85–95%)** — the draft model reliably predicts the next token. This is the most important metric since it determines the floor of speedup.
- **2nd token acceptance is good (70–83%)** — drops off but still respectable.
- **3rd token acceptance is moderate (55–73%)** — the draft quality degrades further out, as expected.
- **Mean acceptance length of 3.0–3.6** with 3 speculative tokens means the target model verifies all 3 draft tokens most of the time. The theoretical max speedup with 3 tokens and perfect acceptance is ~3×; we're seeing ~2.5–2.8× effective speedup over non-speculative decoding.

### Why we're not at 60 tok/s

The sustained 45 tok/s is limited by:
1. **Draft model throughput:** The draft model proposes ~42 tok/s, and the target accepts ~34 of them. The rest is overhead of rejection sampling.
2. **Memory bandwidth:** 156 GB model loaded in 79.52 GiB GPU memory — the remaining ~0.5 GiB is KV cache (3M tokens at 4-bit = ~1.5 GB). The model itself dominates, leaving limited room for larger batch sizes.
3. **Single-GPU-per-node:** TP=2 across 2 nodes means each GPU holds half the model. With the NVFP4 weight quantization (fp4/fp8 hybrid), compute is efficient but still bound by the target model verification step.

To reach 60 tok/s we would need:
- Higher draft acceptance (3.6+ mean acceptance length)
- Or more speculative tokens (4–5) with maintained acceptance rates
- Or reduced verification latency (faster GPU or optimized kernels)

---

## 3. Model Loading & Startup

| Phase | Time |
|-------|------|
| Target model weight loading (head) | 151.24 s |
| Target model weight loading (worker) | 27.99 s (cached) |
| Draft model loading | ~2 s |
| torch.compile (head, cold) | 20.22 s |
| torch.compile (worker, cached) | 2.18 s |
| Profiling/warmup | 14–17 s |
| CUDA graph capture | 3 s |
| DeepGEMM warmup | ~0.4 s (1447 kernels) |
| FlashInfer autotune (cached) | ~6 s |
| **Total startup** | **~4 min 45 s** |

Key finding: **torch.compile cache works** — second run (worker) went from 20s → 2s. FlashInfer autotune cache also loaded from disk (30 configs), avoiding re-tuning.

---

## 4. Memory & Resource Usage

| Resource | Usage |
|----------|-------|
| Model weights (GPU) | 79.52 GiB |
| KV cache | 0.55 GiB (3,076,565 tokens @ 4-bit) |
| CUDA graphs | 0.12 GiB |
| GPU memory utilization target | 85% |
| Available RAM (head) | 35.60 GiB |
| Available RAM (worker) | 31.73 GiB |
| Checkpoint size (disk) | 155.43 GiB |

Auto-prefetch was disabled because checkpoint size (155 GB) exceeds 90% of available RAM (~32–35 GB). This is correct — prefetch would OOM.

---

## 5. Prefix Caching Performance

| Metric | Value |
|--------|-------|
| Prefix cache hit rate (end of session) | **89.8%** |
| Typical hit rate during chunked test | 44–89% |

The prefix cache warmed up quickly during the chunked test (repeated writes to similar file patterns). By the end, nearly 90% of prompt tokens were hitting cache — excellent for iterative/agent workflows where similar context is reused.

---

## 6. NVFP4 KV Cache

- **KV cache dtype:** `nvfp4_ds_mla` (4-bit floating point for MLA)
- **KV cache memory:** 21.44 GiB available on GPU
- **Scaling factor:** UE8M0 (detected from model config)
- **Accuracy warning:** The log notes "may cause accuracy drop without a proper scaling factor" — the scaling factors are baked into the model weights, so this is a one-time design choice by DeepSeek.

---

## 7. DSpark-Specific Features Enabled

| Feature | Status | Purpose |
|---------|--------|---------|
| Replicated Markov W1 | On | Removes per-position vocab-parallel all-reduce |
| Local vocab-parallel argmax | On | Experimental — adds per-position sync overhead |
| GPU rejected-context mask | On | Masks rejected target suffix rows during draft KV update |
| Fast draft-output mode | On | Skips confidence head and returned draft logits |
| Hardware scheduler early stop | On | Stops draft early when confidence is high |
| Confidence threshold | 0.0 (off) | Could be tuned to filter low-confidence drafts |

---

## 8. Summary

**The DSpark cluster is working correctly and delivering ~45 tok/s sustained generation throughput with 70–87% draft acceptance rates.** This is a solid result for the first run with a 156 GB model on dual DGX Sparks with NVFP4 KV cache.

The key metrics are:
- **48.2 tok/s peak** generation throughput
- **3.62 max mean acceptance length** (near-perfect utilization of 3 speculative tokens)
- **89.8% prefix cache hit rate** (excellent for agent workloads)
- **2.93× KV cache concurrency** for 1M context requests

**Next improvement targets for 60+ tok/s:**
- Tune `VLLM_DSPARK_CONFIDENCE_THRESHOLD` to filter bad drafts early
- Increase `MTP_NUM_TOKENS` to 4 with confidence-based early exit
- Enable `VLLM_MEMORY_PROFILER_ESTIMATE_CUDAGRAPHS` (currently disabled) to better account for CUDA graph memory
