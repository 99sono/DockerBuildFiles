# Atlas vs vLLM — Qwen3.6-35B-A3B NVFP4 Notes

**Date:** 2026-05-19  
**Hardware:** DGX Spark (GB10, 128 GB UMA)  
**Model:** RedHatAI/Qwen3.6-35B-A3B-NVFP4

---

## Verdict: Atlas is Faster Than vLLM — Despite Broken Speculator

### Startup Time

| Engine | Cold Start |
|--------|-----------|
| **Atlas** | ~54 seconds (weights load → listening) |
| vLLM | ~287 seconds (146s load + 160s torch.compile/warmup) |
| **Winner** | **Atlas, 5× faster** |

### Decode Speed Comparison

| Engine | Config | Decode tok/s | Notes |
|--------|--------|-------------|-------|
| **Atlas (spec OFF)** | pure NVFP4 KV, 16K prefill, 0.70 util | 51.8–52.9 | Clean baseline, no speculation overhead |
| **Atlas (spec ON, NVFP4)** | MTP K=2, 8K prefill, `--mtp-quantization nvfp4` | 56–72 | ~20-30% faster despite ~96% reject rate |
| **Atlas (spec ON, FP8)** | MTP K=2, 8K prefill, `--mtp-quantization fp8` | 70–80 | Slightly faster but less efficient per cli.rs |
| vLLM (spec ON, MTP) | fp8_e4m3 KV, 65K batched tokens, MTP spec | 19–52 (avg ~30) | MTP acceptance 70-99% but still slower overall |

**Atlas is consistently faster in decode throughput**, even when its speculator is catastrophically rejecting tokens.

### The Speculator Paradox

The MTP speculative decoder on Atlas has an **extremely high rejection rate (~96% K2 reject)**. The full model overrides nearly every draft proposal the speculator makes. You would expect this to be a net loss — propose + verify costs time, and almost nothing gets accepted.

But the logs tell a different story:

- **Without speculation:** 51.8–52.9 tok/s
- **With speculation (NVFP4):** 56–72 tok/s
- **With speculation (FP8):** 70–80 tok/s

Even at 96% rejection, the cheap K1 draft step is accepted enough to amortize the verify cost and net a **+20-30% throughput gain**. It's counterintuitive but measurable.

The speculator also generates a very large log volume — every SSM prefill entry for both target and draft gets logged, plus MTP expert quantization lines at startup. The logs are verbose but the speed is real.

### Decision: Keep Speculation ON with 1 Draft Token

We keep `--num-drafts 1` (K=2 verify) because:
- Top performance comes at K=2 — the single draft token is fast enough to amortize
- Higher K would add more draft overhead without proportional acceptance gain
- NVFP4 quantization (`--mtp-quantization nvfp4`) chosen over FP8 for fused device-side expert dispatch (cli.rs:150-153)

Despite the massive number of rejects and the verbose logging, speculation is a net win on this hardware+model combination.

### Why vLLM Falls Behind

vLLM's MTP speculator actually achieves **70-99% acceptance** vs Atlas's ~4%, yet still delivers lower throughput (~30 tok/s avg). This suggests:
- vLLM's torch.compile overhead and Python stack add per-token latency
- The MTP head in vLLM may be running on a different code path with less optimization
- Atlas's CUDA-native pipeline has lower per-step overhead even with bad speculation

---

## Current Config (Final)

| Setting | Value | Rationale |
|---------|-------|-----------|
| `--kv-cache-dtype` | `nvfp4` | Best on GB10, no clipping warnings |
| `--kv-high-precision-layers` | disabled (commented) | Pure NVFP4 saves memory, quality OK so far |
| `--gpu-memory-utilization` | `0.75` | Single model, ample memory available |
| `--max-prefill-tokens` | `16384` | Covers typical 14K prompts, lean buffer arena |
| `--max-seq-len` | `200000` | Within native 262K context window |
| `--mtp-quantization` | `nvfp4` | Fastest fused expert dispatch |
| `--num-drafts` | `1` | K=2 verify, top performance point |
| `--speculative` | **enabled** | +20-30% throughput despite 96% rejection |

---

## Open Questions

- SSM snapshot prefix cache still recomputes all KV on hit (`no SSM snapshot — recomputing all KV`). Engine-level issue, not configurable.
- Whether pure NVFP4 KV causes coherence issues on very long outputs (>32K tokens). Monitor quality.
- If Atlas's MTP speculator improves in future releases, acceptance rate and throughput could both jump.
