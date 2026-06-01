# Qwen Performance Analysis — DGX Spark + vLLM Nightly

**Analysis performed by:** Qwen 3.6 27B (orchestrator, RTX 5090)
**Source log:** `02_vllm_log_normal_frontend.md`
**Date:** 2026-06-02

---

## TL;DR

The DGX Spark is a school bus. It was born to run MoE in the 3B–4B active parameter range and batch requests aggressively. The more we batch, the better vLLM runs on this hardware. At 4 concurrent sessions, aggregate generation throughput hits **~189 tok/s**. With only 1 session, active decode runs at **~60 tok/s** — perfectly usable, but the GPU is underutilized. The KV cache headroom is enormous — even 4 requests barely touch 1.5% of available capacity. For local single-user setups where you can't sustain that many parallel sessions, the very generous 262K context window lets you use the Spark for long-context workloads instead.

---

## Startup and Memory Profile

| Metric | Value |
|---|---|
| **Total startup time** | ~158 seconds (2 min 38 s) — 132 s main model + 19 s drafter |
| **Compilation overhead** | 38.7 s (torch.compile for backbone + eagle_head) |
| **Model memory** | 21.93 GiB (NVFP4 compressed, 3 shards loaded from page cache) |
| **Available KV cache** | 74.76 GiB → 6.45M tokens capacity |
| **Max concurrency at full context (262K)** | 24.62 sessions theoretically |
| **Actual max_num_seqs limit** | 5 (we're capping far below hardware limits) |

The Spark has 128 GB UMA memory. After loading the model, there's roughly 90+ GiB left for KV cache — that's the big picture here. The hardware is massively over-provisioned for what we typically feed it.

---

## Throughput by Concurrency Level

This is the most important data from the log. Note: vLLM averages over 10-second windows, so numbers include idle time between request bursts — actual per-request decode speeds are higher than these averages suggest.

| Running Reqs | Avg Generation Throughput (logged) | Per-Session (est.) |
|---|---|---|
| **1 req** | 26 – 59 tok/s *(avg includes idle gaps)* | ~60 tok/s during active decode |
| **2 reqs** | 86 – 124 tok/s | 43 – 62 tok/s each |
| **3 reqs** | 100 – 126 tok/s | 33 – 42 tok/s each |
| **4 reqs** | **120 – 189 tok/s** | **30 – 47 tok/s each** |

### The curve tells a clear story:

- **1 session = decent but underutilized.** A single decode path gets ~60 tok/s during active generation, but the Spark has far more capacity sitting idle.
- **2–4 sessions = sweet spot.** Aggregate throughput scales well — 4 requests sustain ~180 tok/s total while using under 1.5% KV cache. Per-session latency stays reasonable (30–60 tok/s), fast enough for interactive use.
- **We're not maxing out the bus.** KV cache stays under 1.5% even at 4 concurrent requests. The Spark could sustain many more sessions before hitting memory pressure.

This is textbook MoE behavior: the active parameters per layer are only ~3B, so each forward pass is cheap on the GB10 GPU. Batching lets you amortize kernel launch and memory bandwidth costs across multiple sequences simultaneously.

---

## Speculative Decoding (MTP) — Mixed Results

The MTP (Multi-Token Prediction) speculative decoder shows highly variable acceptance:

| Concurrency | Avg Draft Acceptance | Accepted tok/s |
|---|---|---|
| 1 req | **80 – 88%** | negligible (low volume) |
| 2 reqs | 56 – 78% | moderate |
| 3 reqs | **52 – 56%** | 58 – 65 tok/s |
| 4 reqs | **52 – 63%** | 63 – 106 tok/s |

### Key observations:

- At low concurrency, MTP works well (80-88% acceptance at 1 req). The drafter model is accurate enough.
- Under batch load, acceptance drops to 52–63%. This means a significant fraction of speculative tokens are being rejected — wasted compute on the drafter pass.
- At high concurrency with low acceptance, MTP may actually be **hurting** throughput compared to straight decode, since the drafter forward pass adds overhead and many speculated tokens get discarded.

### Recommendation:
With 4+ concurrent sessions, consider running without speculative decoding to compare raw throughput. The MTP gain may be marginal or negative at scale. For single-session interactive use, MTP is worth keeping.

---

## Kernel Warmup Gaps

At 22:00:44 (well after startup), the log shows a burst of Triton kernel JIT compilations during inference:

```
WARNING 06-01 22:00:44 [jit_monitor.py] Triton kernel JIT compilation during inference: _zero_kv_blocks_kernel
WARNING 06-01 22:00:44 [jit_monitor.py] Triton kernel JIT compilation during inference: _compute_slot_mapping_kernel
... (14 more kernels through 22:00:51)
```

Plus at 22:10:50 another late compilation of `_topk_topp_kernel`.

**These cause latency spikes.** The warmup phase didn't cover all shapes/configs seen in actual workloads. If you need consistent first-token latency, extending warmup to exercise more request shapes would help. For throughput-bound workloads this is less critical — the one-time cost is small relative to total generation time.

---

## NVFP4 on GB10 — Running via Marlin by Intentional Choice

The log explicitly warns:

```
Your GPU does not have native support for FP4 computation but FP4 quantization is being used.
Weight-only FP4 compression will be used leveraging the Marlin kernel.
This may degrade performance for compute-heavy workloads.
```

**But this is misleading.** The DGX Spark (GB10, Blackwell) *does* have native FP4 tensor cores. However, we're following NVIDIA's own recommendation from the [HF model card](https://huggingface.co/nvidia/Qwen3.6-35B-A3B-NVFP4), which sets `VLLM_USE_FLASHINFER_MOE_FP4=0` and uses Marlin as the MoE backend — explicitly disabling FlashInfer's FP4 path for stability on GB10 (SM 121a).

What's actually happening: NVFP4 weights are dequantized to BF16 on-the-fly via Marlin kernels rather than being consumed natively by the FP4 tensor cores. The throughput numbers above already reflect this constraint — the Spark still performs well despite it.

**The trade-off:** correctness and stability over raw speed. Native FlashInfer FP4 paths (via `flashinfer_cutlass` or `flashinfer_trtllm`) may be available soon, but as of today NVIDIA's own guidance is to stay off them on this hardware. If you want to experiment with unlocking native FP4 compute:

- Swap `--moe-backend marlin` → `flashinfer_cutlass` (hinted at by the env var `VLLM_FP8_MOE_BACKEND=flashinfer_cutlass`)
- Or try `--moe-backend flashinfer_trtllm`
- Test with small workloads first — early GB10 + FlashInfer FP4 has been unstable in practice

---

## Prefix Caching — Working Well

Prefix cache hit rate climbs from **31.9% → 73.4%** over the log window. This makes sense: the opencode orchestrator sends system prompts and context that overlap between sub-agent requests, and prefix caching reuses the KV cache for those shared prefixes rather than recomputing them. At 73% hit rate, roughly 3 out of every 4 prompt tokens are served from cache — significant savings for multi-agent orchestration workloads.

---

## AutoTuner Warnings

Several fp8_gemm shapes fall outside the tuning bucket range at runtime:

```
[AutoTuner]: No tuned config covers fp8_gemm input_shapes=(torch.Size([1, 4256, ...]))
falling back to runner=CutlassFp8GemmRunner tactic=-1
This shape is outside the tuning bucket range -- expand tuning_buckets / max_num_tokens during the next tuning pass
```

The shapes (batch=1, seq_len=4256) appear with longer prompts. The autotuner was configured for shorter sequences and these large shapes fall through the cracks, falling back to a generic kernel that's slower. If you regularly send long prompts, worth investigating expanding the tuning range.

---

## 5090 + Spark: Complementary Architectures, Not Rivals

This is worth stating explicitly: **the RTX 5090 and DGX Spark are not competitors — they're complementary.** The reason becomes obvious when you consider memory bandwidth.

| | RTX 5090 | DGX Spark (GB10) |
|---|---|---|
| **Memory** | GDDR7, ~4 TB/s | UMA DDR5, ~58 GB/s |
| **Bandwidth ratio** | **~70x faster** | bottleneck for dense models |

A 27B **dense** model moves all 27B parameters every forward pass. On the 5090's GDDR7 that's fine — plenty of bandwidth. On the Spark's UMA, it's a death sentence: each token waits while gigabytes shuffle through slow memory. A 27B dense model on the Spark would have **terrible** latency.

But a **MoE** model (3B active, 35B total) only moves ~3B parameters per token. The Spark can actually keep up — and when you batch requests so each memory fetch serves multiple sequences simultaneously, throughput skyrockets.

This dictates the natural division of labor:

- **5090 runs Qwen 27B (dense)** as orchestrator — plans, coordinates, reviews. Fast enough for single-session interactive use at decent token/s.
- **Spark runs Qwen3.6-35B (MoE)** as worker horses — batched parallel execution where the 3B active params per layer play to the Spark's strengths.

The 27B on the 5090 is the brain. The MoE on the Spark is the army. They're built for exactly these two roles.

---

## Conclusion: The Spark Is a Throughput Beast

The DGX Spark with its GB10 GPU is not about raw single-stream inference speed. It's designed for one thing: **batch throughput of MoE models in the 3B–4B active parameter range.**

### What works well:
- **Multi-agent orchestration** (this exact use case) — 4 parallel agents hitting ~180 tok/s aggregate
- **High-concurrency serving** — the KV cache can sustain many more sessions than we're testing with
- **Long-context workloads** — 262K max context with massive headroom means you can feed huge documents and still have room for dozens of sessions

### Where it could be better:
- **Single-session throughput is good (~60 tok/s) but the GPU sits mostly idle.** You're using a school bus for a solo ride — perfectly fine, but most of the engine goes untapped.
- **MTP speculation under load** — acceptance degrades at concurrency > 2, questionable net benefit

### Strategic takeaway:
For a local RTX 5090 setup where you can only sustain 1 session at a time anyway, don't fight the architecture. Use the Spark for what it's good at: batch multiple requests (multi-agent, parallel pipelines, API serving) or lean into the generous context window for long-document tasks where the KV cache headroom matters more than raw speed per token.

The school bus isn't fast on an empty road. But fill it up and it cruises effortlessly.
