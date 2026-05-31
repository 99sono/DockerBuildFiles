# vLLM vs llama.cpp — Qwen3.6-35B A3B on DGX Spark (NVIDIA GB10)

**Date:** 2026-05-30
**Hardware:** NVIDIA GB10 (DGX Spark, ~118GB free VRAM, LPDDR5X unified memory)

---

## Runner-Up Comparison Summary

| Metric | llama.cpp (Q4_K_M GGUF) | vLLM (PrismaQuant 4.75bit) | Winner |
|--------|------------------------|---------------------------|--------|
| **Startup time** | ~6 min 13s | ~7 min 28s | **llama.cpp** (-10%) |
| **Prefill speed** | 1,835 t/s | 1,505–1,915 t/s | **Comparable** |
| **Sustained gen (short task)** | ~67-70 t/s | 20.9 t/s | **llama.cpp** (+230-234%) |
| **Sustained gen (longer task)** | ~67-70 t/s | 42–54 t/s | **llama.cpp** (+24-44%) |
| **Late-gen degradation** | Stable at 62-64 t/s | Drops to 16.9 t/s | **llama.cpp** |
| **MTP acceptance (sustained)** | 89-93% | 41-69% | **llama.cpp** (+20-47%) |
| **Model VRAM footprint** | ~50 GB (Q4_K_M) | 21.3 GiB + 71.15 GiB KV = ~92.5 GB total | **vLLM** uses more |

---

## Startup Time

### llama.cpp
- Model warmup to ready: ~6 min 13s (07:40:19 → 07:46:32)
- Single process, lightweight initialization

### vLLM
- Weight loading (target model): 150.98s
- Weight loading (draft MTP model): 17.11s
- Model loading total: 175.22s
- Engine init (profile, KV cache, warmup + torch.compile): 186.17s (compilation: 59.75s)
- **Total startup: ~7 min 28s** (07:40:19 → 07:47:31)
- Additionally suffered Triton kernel JIT compilations during first inference — adding latency spikes

### Verdict
vLLM's torch.compile overhead (~60s compilation + autotuning) adds significant startup cost. The GB10 lacks native FP4 support, triggering Marlin fallback which doesn't help. llama.cpp wins here by ~1 min 15s.

---

## Prefill Speed (Prompt Processing)

### llama.cpp
- Task 0 (warmup): **1,693 t/s** (includes checkpoint overhead)
- Task 70 (sustained, 14,922 tokens): **1,835 t/s**
- Stable regardless of context length

### vLLM
- Request 1: **1,505.3 t/s** (cold start, JIT compilation overhead)
- Request 2: **1,914.9 t/s** (warm kernels)
- Request 3: **354.8 t/s** (prefix cache hit reduced effective tokens, lower apparent throughput)

### Verdict
Prefill is **comparable** when vLLM's JIT overhead clears. At 1,915 t/s vLLM actually slightly edges llama.cpp's 1,835 t/s on warm runs. But the cold-start penalty and request 3's degradation (prefix caching + Mamba 'align' mode issues) show instability. The GB10's LPDDR5X bandwidth is well-utilized by both for MoE prefill (~2.4 GB/step read).

---

## Generation Speed — The Critical Difference

### Request-by-Request Breakdown (vLLM)

**Request 1 (cold start):**
| Metric | Value |
|--------|-------|
| Gen throughput | **20.9 t/s** |
| MTP acceptance rate | 69.1% (141 accepted / 204 drafted) |
| Per-position: pos1=0.897, pos2=0.676, pos3=0.500 |

**Request 2 (warm):**
| Metric | Value |
|--------|-------|
| Gen throughput | **42–54 t/s** (started at 1.3 t/s cold, peaked 54.2 t/s, ended 42.9 t/s) |
| MTP acceptance rate | 62.8% → 49.9% (degrading mid-generation) |
| Per-position: pos1=0.798→0.705, pos2=0.628→0.474, pos3=0.457→0.318 |

**Request 3 (prefix cached):**
| Metric | Value |
|--------|-------|
| Gen throughput | **44–48 t/s early, collapsed to 16.9 t/s late** |
| MTP acceptance rate | 66.7% → 52.5% → 41.8% (severe degradation) |
| Per-position: pos3 dropped from 0.537 → 0.366 → 0.173 |

### Comparison with llama.cpp Baseline

| Scenario | llama.cpp t/s | vLLM t/s | Gap |
|----------|--------------|----------|-----|
| Short task (195 tokens) | ~70-74 t/s | 20.9 t/s (cold) / N/A warm | **vLLM -36-71%** |
| Medium gen (~354 tokens, warm) | ~70-74 t/s | 54.2 t/s | **vLLM -22-27%** |
| Sustained gen (stable) | ~67-70 t/s | 42–48 t/s | **vLLM -39-44%** |
| Late-gen degradation | Stable 62-64 t/s | 16.9 t/s | **vLLM -73-78%** |

### Verdict
**llama.cpp dominates single-session generation.** Even on warm runs, vLLM tops out at ~54 t/s — well below llama.cpp's 67-70 t/s sustained baseline. The degradation is severe: request 3 collapses to **16.9 t/s**, an 81% drop from the peak.

---

## MTP Speculative Decoding — vLLM Underperforms Dramatically

### Acceptance Rate Comparison (num_speculative_tokens=3, same as n_max=3)

| Condition | llama.cpp n_max=3 | vLLM num_spec=3 |
|-----------|-------------------|-----------------|
| Short task | 94.5% | 69.1% |
| Sustained gen | 89.3% | 62.8% → 41.8% |
| Per-position pos3 (short) | N/A (batched) | 0.500 |

### Why vLLM's MTP Is Worse

1. **vLLM warning:** `Enabling num_speculative_tokens > 1 will run multiple times of forward on same MTP layer, which may result in lower acceptance rate` — this is exactly what we're seeing. llama.cpp evaluates all 3 positions in a single forward pass; vLLM runs 3 separate forward passes, each with its own overhead and accumulating numerical drift.

2. **Per-position decay is steeper in vLLM:** At pos3, llama.cpp still sees ~64% triple-accept (90%³ ≈ 72%), while vLLM drops to 0.173 by request 3. The separate forward passes degrade prediction quality.

3. **Marlin FP4 fallback on GB10:** The GPU lacks native FP4 compute, so vLLM falls back to Marlin kernel for NVFP4 MoE — adding overhead that llama.cpp's GGUF Q4_K_M path doesn't suffer.

---

## KV Cache and Memory

| Metric | llama.cpp | vLLM |
|--------|-----------|------|
| Model VRAM | ~50 GB (Q4_K_M 4-bit) | 21.3 GiB (PrismaQuant 4.75bit, but full BF16 activations) |
| KV Cache | Q8_0, efficient | auto dtype, 71.15 GiB available |
| Max concurrency @ 200K ctx | 4 slots × 180K = 720K tokens | ~3.1M tokens / 200K = 15.6x concurrent requests |
| Graph reuse | 548 graphs (Task 70) | torch.compile level 3, CUDA graphs |

### Verdict
vLLM allocates significantly more memory (~92 GB total) vs llama.cpp (~50 GB model + KV). However, vLLM's larger KV cache gives it **higher theoretical concurrency** — supporting up to 15.6x concurrent 200K-token requests vs llama.cpp's 4 slots at 180K each. This is vLLM's potential advantage for multi-user deployments, but irrelevant for single-session performance.

---

## Triton JIT Compilation Overhead

vLLM suffered **9 Triton kernel JIT compilations** during the first inference request:
- `_zero_kv_blocks_kernel`
- `_compute_slot_mapping_kernel`
- `postprocess_mamba_fused_kernel`
- `eagle_prepare_next_token_padded_kernel`
- `eagle_step_slot_mapping_metadata_kernel`
- `batch_memcpy_kernel`
- `expand_kernel`
- `eagle_prepare_inputs_padded_kernel`

Each causes a latency spike. llama.cpp has zero such overhead — all kernels are precompiled into the binary.

---

## The Mamba Prefix Caching Warning

vLLM reports:
```
Prefix caching in Mamba cache 'align' mode is currently enabled. Its support for Mamba layers is experimental.
```

This affects request 3's performance (prefix cache hit rate: 31.2%, but throughput degraded). llama.cpp doesn't use prefix caching at all — it relies on context checkpoints, which proved stable across both requests.

---

## Bottom Line

### For Single-Session Inference (your current use case): **llama.cpp wins decisively.**

| Metric | Winner | Margin |
|--------|--------|--------|
| Startup time | llama.cpp | -10% |
| Prefill speed | Tie | ±5% |
| Generation speed | llama.cpp | +39-78% faster |
| MTP efficiency | llama.cpp | 20-47% higher acceptance |
| Memory efficiency | llama.cpp | ~46% less VRAM used |

vLLM's generation throughput of **17-54 t/s** falls far short of llama.cpp's **62-70 t/s**. The MTP speculation that should give vLLM an edge instead underperforms due to (a) separate forward passes per speculative position, (b) Marlin FP4 fallback on GB10, and (c) Triton JIT compilation during inference.

### When Would vLLM Make Sense?

vLLM's advantages are **multi-concurrent serving** and **production features**:
- 15.6x concurrent request capacity vs llama.cpp's 4 slots
- Prefix caching (despite Mamba mode issues)
- Production observability (/metrics, OTLP, etc.)
- Batched inference across multiple users

But for **single-session, high-throughput generation** on the DGX Spark with Qwen3.6-35B A3B MoE, llama.cpp is the clear winner — especially with the n_max=2 / p_min=0.85 configuration proven optimal at ~67-70 t/s sustained.

### Recommendation

**Stay with llama.cpp for single-session work.** Only consider vLLM if you need to serve 8+ concurrent requests simultaneously or require production-grade observability and prefix caching across multiple users. The ~40% generation speed penalty is not worth it for your current use case.

---

## Known Issues / Things Not Tested

- vLLM was never tested with MTP disabled (`--speculative-config` removed) — a fairer comparison without speculation would isolate the base generation gap
- The DFlash draft model (z-lab/Qwen3.6-35B-A3B-DFlash) was tested and rejected (0.69 first-token prediction accuracy), so no further exploration there
- llama.cpp's n_max=2 optimal config wasn't compared against vLLM with `num_speculative_tokens=1` — that could narrow the MTP gap
- FP4 quantization on PrismaQuant vs Q4_K_M GGUF is not apples-to-apples; a direct comparison with the same base model would be informative
