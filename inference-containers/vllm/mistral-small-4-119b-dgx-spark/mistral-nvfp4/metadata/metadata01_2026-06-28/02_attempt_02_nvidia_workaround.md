# Experiment 02: NVIDIA Workaround — MLA Disabled + MARLIN + enforce_eager

**Date:** 2026-06-28  
**Status:** ATTEMPT IN PROGRESS  
**Base image:** `aidendle94/sparkrun-vllm-ds4-gb10:production-ready`  
**Reference:** https://forums.developer.nvidia.com/t/running-mistral-small-4-119b-nvfp4-on-nvidia-dgx-spark-gb10/363863

## Hypothesis

The MLA head_size=320 is not functional on SM 12.1a (rejected by all backends
per the forum post). Disabling MLA (`VLLM_MLA_DISABLE=1`) falls back to standard
attention. Combined with MARLIN instead of CUTLASS for NVFP4 GEMM, and skipping
CUDA graph capture (`--enforce-eager`), the server should start without freezing.

## Changes From Experiment 01

| Aspect | Experiment 01 | Experiment 02 |
|---|---|---|
| MLA | TRITON_MLA (enabled) | **Disabled** (`VLLM_MLA_DISABLE=1`) |
| MoE backend | FlashInferCutlass (auto) | **MARLIN** (`VLLM_NVFP4_GEMM_BACKEND=marlin`) |
| FlashInfer MoE | enabled | **Disabled** (`VLLM_USE_FLASHINFER_MOE_FP4=0`) |
| Tokenizer | auto (HF) | **mistral-native** (`--tokenizer-mode mistral`) |
| Config format | auto (HF) | **mistral** (`--config-format mistral`) |
| Load format | auto (HF) | **mistral** (`--load-format mistral`) |
| CUDA graphs | enabled (default) | **Disabled** (`--enforce-eager`) |
| Frontend | Rust frontend disabled | same |
| max-model-len | 262144 | 262144 (unchanged) |
| max-num-seqs | 1 | **3** |
| gpu-memory-utilization | 0.80 | 0.80 (unchanged) |

## Configuration

```yaml
# Environment additions
VLLM_MLA_DISABLE: "1"
VLLM_NVFP4_GEMM_BACKEND: marlin
VLLM_USE_FLASHINFER_MOE_FP4: "0"
VLLM_TEST_FORCE_FP8_MARLIN: "1"

# vLLM args changes
--tokenizer-mode: mistral
--config-format: mistral
--load-format: mistral
--enforce-eager
--max-num-seqs: 3
# Removed: --attention-backend TRITON_MLA
```

## Risks

- **KV cache size with standard attention at 262K:** ~34 GB (fp8) vs ~335 MiB
  with MLA. Model (66 GB) + KV cache (34 GB) + OS (~20 GB) = ~120 GB out of
  128 GB. Very tight — may OOM.
- Forum post caps at 40K context for this reason. If OOM occurs, reduce
  `--max-model-len` to 40000 or lower `--gpu-memory-utilization` to 0.75.
- `--enforce-eager` disables CUDA graph optimization — throughput will be lower
  but startup should succeed.
- MARLIN backend may have different performance characteristics than CUTLASS.

## Expected Outcome

- If freeze persists: root cause is NOT CUDA graphs or CUTLASS — likely a
  driver-level memory addressing issue at >90% UMA utilization.
- If OOM (exit code 137): reduce max-model-len or gpu-memory-utilization.
- If server starts: verify with curl and benchmark throughput at 3 concurrent
  sessions.
