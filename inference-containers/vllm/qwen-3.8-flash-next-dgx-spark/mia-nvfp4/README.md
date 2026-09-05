# Qwen 3.8 Flash Next NVFP4 on DGX Spark (ARM64 / Blackwell GB10)

This directory contains the production Docker configuration and helper scripts to run **`Mia-AiLab/Qwen3.8-Flash-Next-NVFP4`** on a **single DGX Spark** (NVIDIA Blackwell GB10, 128GB unified memory) using **vLLM** with PLE CPU-offloading and memory-mapped page cache execution.

---

## 🌟 Acknowledgements & Model Choice

### Why `Mia-AiLab/Qwen3.8-Flash-Next-NVFP4` instead of `nvidia/Qwen3.8-Flash-Next-NVFP4`?

Running Qwen 3.8 Flash Next at **TP=1 on a single DGX Spark** (121.7 GiB usable unified memory) imposes severe memory constraints:
* **The Problem with NVIDIA Official Checkpoint**: NVIDIA's official checkpoint (`nvidia/Qwen3.8-Flash-Next-NVFP4`) left the massive 51B parameter PLE n-gram table uncompressed in **FP8 (`F8_E4M3`, 160 bytes/row)**, which requires **51.2 GiB** on disk and in memory map. Combined with ~72 GiB model weights, a 16 GiB KV cache, and the mandatory 26 GiB OS/driver reserve, a 51.2 GiB page-cache footprint mathematically exceeds single-node unified memory and triggers kernel allocation failures and lockups.
* **The Mia AI Lab Innovation**: Mia AI Lab ([`MiaAI-Lab/Qwen3.8-Flash-Next-Single-DGX-Spark`](https://github.com/MiaAI-Lab/Qwen3.8-Flash-Next-Single-DGX-Spark)) post-quantized the PLE n-gram table into **NVFP4 (`U8` codes + `F8_E4M3` scales, 90 bytes/row)**, shrinking the table from 51.2 GiB down to **26.8 GiB**. That **24.4 GiB memory saving** is the exact breakthrough that allows the model to run reliably on a single DGX Spark with 262k context.

1. **Model Checkpoint**:
   - **Model ID:** [`Mia-AiLab/Qwen3.8-Flash-Next-NVFP4`](https://huggingface.co/Mia-AiLab/Qwen3.8-Flash-Next-NVFP4)
   - **Quantization:** NVIDIA Model Optimizer (`modelopt` v0.46.0) + Mia AI Lab NVFP4 PLE table.
   - **Format:** Mixed-precision NVFP4 (W4A4 routed MoE experts, NVFP4 PLE n-gram embeddings, FP8 MTP routed experts, BF16 attention layers & shared experts).
   - **Parameters:** 125B total, 6B activated MoE, 51B n-gram PLE embedding, 4B MTP.

2. **Single DGX Spark Serving Architecture & Patches**:
   - **Repository:** [`MiaAI-Lab/Qwen3.8-Flash-Next-Single-DGX-Spark`](https://github.com/MiaAI-Lab/Qwen3.8-Flash-Next-Single-DGX-Spark) by Mia's AI Lab.
   - **Innovations Incorporated:**
     - **Memory-Mapped PLE Offload (`mmap` + `MADV_RANDOM`)**: Keeps the compressed 26.8 GiB PLE table in evictable host page cache with zero resident GPU/RAM overhead.
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
Download the Mia AI Lab NVFP4 checkpoint to the global Hugging Face cache:
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

---

## 🧠 Deep-Dive: Memory Management & Safety on DGX Spark (GB10)

The DGX Spark features **128 GB of unified LPDDR5X memory** (121.69 GiB usable) shared dynamically between the CPU and the Blackwell GPU. Running a massive 125B MoE model (with a 51B n-gram PLE embedding) at **TP=1 on a single node** carries distinct memory hazards that were identified and solved by Mia's AI Lab:

### 1. The Unified Memory "Death Spiral" Hazard
* **The Problem:** vLLM detects GB10 as an integrated GPU and calculates "free GPU memory" based on host `MemAvailable` (which includes Linux page cache). If unconstrained, vLLM attempts to occupy `GMU × MemTotal` (e.g. 90–95%), allocating GPU memory straight out of the operating system's page cache and kernel buffers.
* **The Consequence:** When host memory runs dry on unified architecture, the Linux kernel **does not trigger an OOM kill**. Instead, the NVIDIA GPU driver starts failing memory allocations (`NV_ERR_NO_MEMORY` in `journalctl -k`), and the entire machine experiences a **hard kernel lockup / freeze** requiring a physical power cycle.
* **The Fix (`HOST_RESERVE_GIB=26`):**
  We strictly cap the container's GPU allocation ceiling to `MemTotal - 26 GiB` (`--gpu-memory-utilization 0.78`). This reserve guarantees memory for:
  - Host OS processes & co-tenants (~7 GiB)
  - vLLM host-side processes (~6 GiB)
  - PLE memory-mapped page cache (≥ 6 GiB)
  - NVIDIA kernel driver free-page reserve (≥ 3 GiB)
  - Dynamic request workspace growth (2–3 GiB)

### 2. Why Memory-Mapped PLE Offload (`mmap` + `MADV_RANDOM`) is Essential
* The PLE n-gram embedding table is **~26.8 GiB to 51 GiB** on its own.
* Storing the PLE table in anonymous RAM or GPU VRAM would drive non-evictable memory to ~104 GiB + KV cache, blowing past the safety ceiling.
* By building a packed uint8 table (`00_c_prepare_patches_and_ple.sh` via `build_ple_packed_table.py`) and memory-mapping it with `MADV_RANDOM`:
  - The table is held as **file-backed, evictable page cache**.
  - Disk reads per decoded token drop from ~1,366 KiB down to **57 KiB** (a 24× reduction).
  - The non-evictable resident footprint drops to **~77 GiB + KV cache**, freeing ~16.5 GiB for almost **1,000,000 FP8 KV tokens**.

### 3. GB10 CUDA Stream Ops Bug & Host Handshake
* Blackwell GB10 reports `CU_DEVICE_ATTRIBUTE_CAN_USE_STREAM_MEM_OPS = 0`.
* Upstream vLLM stock offload code attempts to synchronize the CPU offload worker and GPU stream using `cuStreamWaitValue32` / `cuStreamWriteValue32`. On GB10, this causes the GPU worker to **deadlock and hang forever right after CUDA graph capture**.
* The applied patch (`patch_ple_offload.py`) introduces a clean host-side handshake using a shared-memory sequence flag, completely eliminating the deadlock on GB10.

### 4. QSA Sparse Attention FP8 KV Cache Hoist
* Stock vLLM previously rejected FP8 KV on Qwen Sparse Attention (`QSA`).
* The included `patch_qsa_fp8_kv.py` hoists the scalar scales outside the tensor core dots, keeping the full tile size (`block_n`), avoiding FP32 tile materialization, and making FP8 KV caching fast, mathematically exact to within 1 BF16 ULP, and fully functional on DGX Spark.
