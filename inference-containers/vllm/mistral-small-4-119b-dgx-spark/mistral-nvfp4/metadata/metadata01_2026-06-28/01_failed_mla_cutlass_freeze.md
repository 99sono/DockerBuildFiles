# Experiment 01: MLA + CUTLASS — System Freeze After Model Load

**Date:** 2026-06-28  
**Status:** FAILED — system froze twice, both requiring hard power-off  
**Base image:** `aidendle94/sparkrun-vllm-ds4-gb10:production-ready`

## Hypothesis

The DeepSeek vLLM fork (v0.21.1rc1) has working TRITON_MLA with head_size=320
support. Running Mistral Small 4 with native MLA attention + CUTLASS NVFP4 GEMM
should work on DGX Spark SM 12.1a.

## Configuration

```yaml
# Environment
VLLM_WORKER_MULTIPROC_METHOD: spawn
PYTORCH_CUDA_ALLOC_CONF: expandable_segments:True
HF_HUB_ENABLE_HF_TRANSFER: "1"
FLASHINFER_DISABLE_VERSION_CHECK: "1"
CUTE_DSL_ARCH: sm_121a
VLLM_USE_RUST_FRONTEND: "0"

# Network (bridge mode, GLOO/NCCL forced to eth0)
GLOO_SOCKET_IFNAME: eth0
NCCL_SOCKET_IFNAME: eth0
TP_SOCKET_IFNAME: eth0
OMPI_MCA_btl_tcp_if_include: eth0
MN_IF_NAME: eth0

# vLLM args
--attention-backend: TRITON_MLA
--dtype: auto
--kv-cache-dtype: fp8
--gpu-memory-utilization: 0.80
--max-model-len: 262144
--max-num-seqs: 1
--max-num-batched-tokens: 8192
--enable-prefix-caching
--enable-chunked-prefill
--tool-call-parser: mistral
--enable-auto-tool-choice
--reasoning-parser: mistral
```

## What Happened

1. Model loaded successfully — 66.06 GiB, all 13 safetensors shards, 453 seconds
2. DeepGEMM E8M0 detected and enabled
3. Selected `FlashInferCutlassNvFp4LinearKernel` for NVFP4 GEMM (auto-selected
   over FLASHINFER_TRTLLM, FLASHINFER_CUTEDSL, VLLM_CUTLASS, MARLIN, EMULATION)
4. Selected `FLASHINFER_CUTLASS` NvFp4 MoE backend
5. `torch.compile` completed (10.42 s)
6. **System froze immediately after** — no log output past `monitor.py:53`

## Root Cause Analysis

- **Kernel-level freeze** (not container OOM) — required power button, not just
  container restart. Indicates GPU driver hang or memory controller deadlock.
- Possible triggers: CUDA graph capture on UMA after 66 GiB allocation, CUTLASS
  kernel bug on SM 12.1a, or swap thrashing when vLLM faults all pages back in
  during warmup.
- Available RAM before load: 45.50 GiB. Model: 65.95 GiB. OS had to reclaim
  ~20 GiB from page cache — fragile state.
- CUTLASS is known to be buggy on DGX Spark per community reports.

## Lessons

- TRITON_MLA works for model loading on this image but something in the
  post-load pipeline (graph capture / KV cache init / kernel warmup) triggers
  a hard freeze.
- DeepSeek vLLM at 0.21.1rc1 auto-selects CUTLASS for NVFP4 — may need to
  force MARLIN.
- `--enforce-eager` should be used to skip CUDA graph capture.
- `mem_limit: 100g` with `memswap_limit: 100g` prevented swap death but
  didn't prevent the kernel-level freeze.
