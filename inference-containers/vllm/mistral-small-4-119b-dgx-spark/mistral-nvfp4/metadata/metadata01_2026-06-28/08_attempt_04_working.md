# Experiment 04: WORKING — vLLM Nightly + NVIDIA Recipe

**Date:** 2026-06-28  
**Status:** ✅ WORKING  
**Base image:** `vllm/vllm-openai:nightly` (v0.23.1rc1)

## Result

Server started successfully after ~7 min model load. Verified with API calls.

## Final Working Config

- **Image:** `vllm/vllm-openai:nightly`
- **MLA:** Disabled (`VLLM_MLA_DISABLE=1`) — standard FLASHINFER attention
- **NVFP4 GEMM:** FlashInferCutlass (auto-selected)
- **MoE backend:** MARLIN — works on nightly (PTX mismatch on DeepSeek fork)
- **enforce_eager:** true (skip CUDA graphs + torch.compile)
- **max-model-len:** 40000
- **gpu-memory-utilization:** 0.75
- **max-num-seqs:** 3
- **Tokenizer/config/load:** mistral-native format

## Performance

- **Weight loading:** ~7 min (13 shards, ~40s each — MARLIN prep adds time)
- **Prompt throughput:** 59.4 tok/s
- **Generation throughput:** 9.8 tok/s
- **KV cache usage:** 0.0% (idle)

## Key Insight

DeepSeek fork image (`aidendle94/sparkrun-vllm-ds4-gb10:production-ready`) has
MARLIN compiled with incompatible CUDA PTX for DGX Spark driver. CUTLASS NVFP4
causes hard GPU driver freeze. The upstream nightly image has MARLIN compiled
with a compatible toolchain and works for both weight prep and inference.
