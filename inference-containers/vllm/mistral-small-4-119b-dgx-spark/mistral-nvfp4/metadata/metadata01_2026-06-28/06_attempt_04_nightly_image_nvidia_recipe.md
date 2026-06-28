# Experiment 04: vLLM Nightly Image + NVIDIA Recipe (MLA disabled + MARLIN)

**Date:** 2026-06-28  
**Status:** ATTEMPT IN PROGRESS  
**Base image:** `vllm/vllm-openai:nightly`

## Previous Attempts

| # | Image | Config | Result |
|---|---|---|---|
| 01 | DeepSeek fork | TRITON_MLA + CUTLASS + CUDA graphs | Froze during warmup — hard power-off |
| 02 | DeepSeek fork | MLA disabled + MARLIN + enforce_eager | MARLIN PTX toolchain mismatch |
| 03 | DeepSeek fork | TRITON_MLA + CUTLASS + enforce_eager | Froze after model load — hard power-off |
| **04** | **nightly** | **MLA disabled + MARLIN + 40K ctx** | **Current attempt** |

## Root Cause Analysis

`--enforce-eager` eliminated CUDA graph capture and torch.compile as the cause
in experiment 03. The freeze still occurred, pointing to:

1. **CUTLASS NVFP4 kernel** crashing the GPU driver during weight prep
   (`process_weights_after_loading`)
2. **KV cache allocation** at >95% UMA utilization with 262K MLA context

Since both MARLIN and CUTLASS are broken on the DeepSeek image (MARLIN = PTX
mismatch, CUTLASS = hard freeze), switching to the upstream nightly image
where MARLIN is compiled with a compatible CUDA toolchain.

## Live Results (partial)

MARLIN backend works on nightly image (no PTX crash unlike DeepSeek fork).
Kernel selection at runtime:
- **Attention:** `FLASHINFER` (standard, MLA disabled via `VLLM_MLA_DISABLE=1`)
- **NVFP4 GEMM:** `FlashInferCutlassNvFp4LinearKernel` (CUTLASS for linear weights)
- **MoE:** `MARLIN` — successfully selected and functional

Model loading in progress (~7 min for 13 shards).

## Configuration

Based on NVIDIA forum working config + Qwen 3.6 NVFP4 precedent:

```yaml
image: vllm/vllm-openai:nightly

# Env vars
VLLM_MLA_DISABLE: "1"

# Command
--max-model-len: 40000
--gpu-memory-utilization: 0.75
--moe-backend: marlin
--attention-backend: flashinfer
--tokenizer-mode: mistral
--config-format: mistral
--load-format: mistral
--enforce-eager
--max-num-seqs: 3
```

Context capped at 40K (NVIDIA's proven max) — standard attention KV cache
at 262K would exceed 128 GB UMA. Can try increasing later if stable.

## Expected Outcome

- If MARLIN also crashes on nightly: NVFP4 on DGX Spark may need a
  newer CUDA driver or a Spark-specific vLLM build.
- If server starts: gradually increase max-model-len and max-num-seqs.
