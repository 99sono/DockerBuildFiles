# Experiment 03: TRITON_MLA + enforce_eager (no CUDA graphs)

**Date:** 2026-06-28  
**Status:** IN PROGRESS  
**Base image:** `aidendle94/sparkrun-vllm-ds4-gb10:production-ready`

## Previous Attempts

| # | Config | Result |
|---|---|---|
| 01 | TRITON_MLA + CUTLASS (auto) + CUDA graphs | Model loaded (66 GB), froze during warmup — hard power-off |
| 02 | MLA disabled + MARLIN + enforce_eager | MARLIN PTX toolchain mismatch: `cudaErrorUnsupportedPtxVersion` |
| **03** | **TRITON_MLA + CUTLASS (auto) + enforce_eager** | **Current attempt** |

## Hypothesis

Experiment 01's freeze was caused by CUDA graph capture after model load,
not by the CUTLASS MoE kernel itself. With `--enforce-eager` to skip both
CUDA graphs and torch.compile, TRITON_MLA should survive startup.

TRITON_MLA works on this image (confirmed in exp 01 — it selected and
initialized without error). The MARLIN backend has a PTX version mismatch
with the DGX Spark's CUDA driver, making it unusable. CUTLASS is the only
viable NVFP4 GEMM backend available on SM 12.1a.

## Configuration Changes From Exp 02

- Removed `VLLM_MLA_DISABLE=1` — re-enable TRITON_MLA
- Removed `VLLM_NVFP4_GEMM_BACKEND=marlin` — let CUTLASS auto-select
- Removed `VLLM_USE_FLASHINFER_MOE_FP4=0` — no longer needed
- Removed `VLLM_TEST_FORCE_FP8_MARLIN=1` — no longer needed
- Kept `--enforce-eager` — skip CUDA graph capture (key fix)
- Kept `--tokenizer-mode mistral`, `--config-format mistral`, `--load-format mistral`
- Added `--attention-backend TRITON_MLA` back
- Added `TORCH_CUDA_ARCH_LIST: "12.1a"` (from DeepSeek config)
- `--max-model-len`: 262144
- `--max-num-seqs`: 3
- `--gpu-memory-utilization`: 0.80

## Expected Outcome

- If freeze still occurs: root cause is not CUDA graphs but either CUTLASS
  itself or hitting >95% UMA utilization during KV cache init.
  Next: reduce `--gpu-memory-utilization` to 0.75 or `--max-model-len` to 40000.
- If server starts: verify API, benchmark throughput at 3 concurrent sessions.
