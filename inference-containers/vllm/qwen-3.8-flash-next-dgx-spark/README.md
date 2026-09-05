# Qwen 3.8 Flash Next on DGX Spark (ARM64 / Blackwell GB10)

This directory provides Docker Compose configurations for running **Qwen 3.8 Flash Next** on a single DGX Spark (NVIDIA Blackwell GB10, 128GB unified memory) using **vLLM** with PLE CPU-offloading and memory-mapped execution.

---

## 📁 Available Presets

| Preset | Target Model | PLE Table Format | Table Size | DGX Spark Single-Node Status |
|---|---|---|---|---|
| **[`mia-nvfp4/`](mia-nvfp4)** | [`Mia-AiLab/Qwen3.8-Flash-Next-NVFP4`](https://huggingface.co/Mia-AiLab/Qwen3.8-Flash-Next-NVFP4) | NVFP4 (W4A8 block scales) | **~26.8 GiB** | **✅ Working (Tested & Verified)** |

*(Note: The official [`nvidia/Qwen3.8-Flash-Next-NVFP4`](https://huggingface.co/nvidia/Qwen3.8-Flash-Next-NVFP4) is excluded because its uncompressed 51.2 GiB FP8 PLE table cannot mathematically fit in a single 128 GB DGX Spark unified memory envelope alongside model weights and KV cache. See architectural context below.)*

---

## 🧠 Architectural Context: The PLE Table on Unified Memory

Running Qwen 3.8 Flash Next on a single DGX Spark (121.7 GiB usable unified memory) imposes severe memory headroom constraints:

1. **Why NVIDIA's Official FP8 Checkpoint Fails on Single Node**:
   - NVIDIA's official checkpoint kept the 51B parameter PLE n-gram table uncompressed in **FP8 (`F8_E4M3`, 160 B/row)**, generating a massive **51.2 GiB** table.
   - On a 121.7 GiB box, alongside ~72 GiB model weights, ~16 GiB FP8 KV cache, and the mandatory $\ge 26\text{ GiB}$ OS/driver safety reserve, holding a 51.2 GiB page-cache footprint mathematically exceeds host unified memory and triggers kernel allocation lockups (`NV_ERR_NO_MEMORY`).

2. **Why Mia AI Lab's NVFP4 Checkpoint Succeeds**:
   - Mia AI Lab ([`MiaAI-Lab/Qwen3.8-Flash-Next-Single-DGX-Spark`](https://github.com/MiaAI-Lab/Qwen3.8-Flash-Next-Single-DGX-Spark)) specifically post-quantized the PLE n-gram table into **NVFP4 (90 B/row: 80B uint8 codes + 10B FP8 scales)**.
   - This compresses the table to **26.8 GiB**, providing a **24.4 GiB saving** that allows the entire pipeline (weights, KV cache, offload mmap, and OS reserve) to comfortably fit within 121.7 GiB unified memory.

---

## 🚀 Quick Start (Recommended Preset)

```bash
cd mia-nvfp4

# 1. Download Mia AI Lab checkpoint (~99 GB)
./00_b_pre_download_model.sh

# 2. Extract vLLM baseline files, apply GB10 patches, and build 26.8 GB packed table
./00_c_prepare_patches_and_ple.sh

# 3. Launch server
./01_up.sh

# 4. Follow logs
./05_a_follow_logs.sh

# 5. Run test suite
python3 04_test_vllm_curl.py
```
