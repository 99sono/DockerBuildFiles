# Qwen 3.8 Flash Next NVFP4 on DGX Spark (ARM64 / Blackwell GB10)

This directory contains the production Docker configuration and helper scripts to run **NVIDIA's official `nvidia/Qwen3.8-Flash-Next-NVFP4`** model on a **single DGX Spark** (NVIDIA Blackwell GB10, 128GB unified memory) using **vLLM** with PLE CPU-offloading and memory-mapped page cache execution.

---

## 🌟 Acknowledgements & References

This configuration builds upon and combines two key pieces of work from the AI community:

1. **Model Checkpoint**:
   - **Model ID:** [`nvidia/Qwen3.8-Flash-Next-NVFP4`](https://huggingface.co/nvidia/Qwen3.8-Flash-Next-NVFP4)
   - **Quantization:** NVIDIA Model Optimizer (`modelopt` v0.46.0).
   - **Format:** Mixed-precision NVFP4 (W4A4 routed MoE experts, FP8 PLE n-gram embeddings, FP8 MTP routed experts, BF16 attention layers & shared experts).
   - **Parameters:** 125B total, 6B activated MoE, 51B n-gram PLE embedding, 4B MTP.

2. **Single DGX Spark Serving Architecture & Patches**:
   - **Repository:** [`MiaAI-Lab/Qwen3.8-Flash-Next-Single-DGX-Spark`](https://github.com/MiaAI-Lab/Qwen3.8-Flash-Next-Single-DGX-Spark) by Mia's AI Lab.
   - **Innovations Incorporated:**
     - **Memory-Mapped PLE Offload (`mmap` + `MADV_RANDOM`)**: Prevents kernel memory exhaustion on unified memory by keeping the massive 26.8–51 GB PLE n-gram table in evictable host page cache rather than GPU/anonymous RAM.
     - **GB10 CUDA Stream Deadlock Fix**: Replaces `cuStreamWaitValue32` with a robust host-side handshake to resolve GB10 CUDA stream synchronization lockups after graph capture.
     - **QSA Sparse Attention FP8 KV Kernel Patch**: Enables FP8 KV caching on QSA layers (`patch_qsa_fp8_kv.py`), nearly doubling KV cache capacity.
     - **Host Safety Guard**: Enforces `HOST_RESERVE_GIB=26` headroom to guarantee the host OS and NVIDIA kernel driver never run out of free pages on unified memory.

---

## 🏗️ Architecture & Memory Profile (Single Spark TP=1)

On a single DGX Spark (121.7 GiB usable LPDDR5X unified memory shared by CPU and GPU):

| Component | Footprint | Storage / Memory Location |
|---|---|---|
| **Checkpoint on Disk** | ~98.6 GiB | NVMe (`~/.cache/huggingface`) |
| **PLE Packed Table** | ~26.8 GiB | NVMe mmap (`~/.cache/vllm/ple_cache`) |
| **Model Weights on GPU** | ~71.8 GiB | GPU Resident Memory |
| **vLLM Runtime & Activations** | ~5.6 GiB | GPU Resident Memory |
| **KV Cache Arena (FP8)** | ~16.5 GiB | GPU Memory (**~992,000 tokens**, ~3.8× 262k window) |
| **Host / Driver Reserve** | ≥ 26 GiB | Host RAM (Guaranteed safety margin) |

---

## 🚀 Quick Start

### 1. Pre-download Model Weights
Download the official NVIDIA NVFP4 checkpoint to the global Hugging Face cache:
```bash
./00_b_pre_download_model.sh
```

### 2. Prepare Patches & Packed PLE Table
Run the one-time preparation script to build the packed PLE table and prepare overlay patches:
```bash
./00_c_prepare_patches_and_ple.sh
```

### 3. Start the Server
Launch the inference server in the background:
```bash
./01_up.sh
```

### 4. Monitor & Inspect
- **Follow logs in real time:**
  ```bash
  ./05_a_follow_logs.sh
  ```
- **Dump logs with timestamp:**
  ```bash
  ./05_b_dump_logs.sh
  ```

### 5. Run Health & API Validation Tests
```bash
python3 04_test_vllm_curl.py
```

### 6. Stop Server Gracefully
```bash
./02_down.sh
```

---

## ⚙️ Key Configuration Details

- **Docker Base Image:** `vllm/vllm-openai:qwen38-flash-next` (or `vllm/vllm-openai:nightly` with commit `d4d703caf908786416585ceb1f369e2e0363358b`+)
- **Platform:** `linux/arm64`
- **Internal Port:** `8000` (Mapped to host `${INFERENCE_SERVER_PORT:-8000}`)
- **Max Model Length:** `262144` (Native 262k context; extensible to 512k via YaRN)
- **Quantization:** `modelopt`
- **KV Cache Dtype:** `fp8`
- **Batching:** `--max-num-seqs 4`, `--max-num-batched-tokens 2048`
- **Speculative Decoding:** `--speculative-config '{"method":"mtp","num_speculative_tokens":3}'`
- **Parsers:** `--reasoning-parser qwen3`, `--tool-call-parser qwen3_coder`
