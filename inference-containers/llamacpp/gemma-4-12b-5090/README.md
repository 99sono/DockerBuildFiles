# Gemma 4 12B Unified — RTX 5090 (llama.cpp)

Optimized `llama.cpp` Docker container for serving **Gemma 4 12B Unified** (`UD-Q4_K_XL`) on an NVIDIA RTX 5090 (Blackwell, 32GB VRAM).

## Hardware & Architecture Notes

### RTX 5090 Constraints
The RTX 5090 has 32GB of GDDR7 memory with a blistering **1.7 TB/s memory bandwidth**. This setup is optimized for a single heavy inference session (`--parallel 1`), maximizing decode speed rather than multi-tenant concurrency.

### Memory Math & Hybrid Attention
| Component | Size (approx.) |
|---|---|
| Model weights (`UD-Q4_K_XL`) | ~7.4 GB |
| KV cache (`q8_0`, 256K ctx, parallel=1) | ~21 GB |
| CUDA overhead & buffers | ~1–2 GB |
| **Total** | **~30 GB / 32 GB** |

Running a 256K context window with `q8_0` KV cache on just 32GB VRAM appears impossible for a standard dense model. However, Gemma 4 uses a **hybrid attention mechanism** that interleaves **1024-token local sliding window attention** with full global attention (only every few layers). Because the vast majority of the 48 layers only cache the 1024-token sliding window instead of the entire 256K context, the KV cache footprint is drastically reduced, allowing it to fit comfortably within the 5090's VRAM.

### Blackwell SM120 & CUDA 12.8 Override
The container uses the `ghcr.io/ggml-org/llama.cpp:server-cuda13` image but overrides `LD_LIBRARY_PATH` to `/usr/local/cuda-12.8/lib64`. The pure CUDA 13 runtime has known bugs where it fails to offload layers to the GPU and silently falls back to the CPU. CUDA 12.8 contains mature, fully optimized **MMQ (Multi-Matrix Quantization)** kernels for Blackwell SM120. Overriding the library path bypasses the CUDA 13 offloading bugs and guarantees 100% GPU utilization with maximum Blackwell speedups.

## Configuration Highlights

- **`--jinja`** — Strictly required by Unsloth for the Gemma 4 chat template and native thinking token (`<|think|>`) handling.
- **Single-slot parallelism** — `--parallel 1` maximizes VRAM availability for deep context windows.
- **Threading** — `--threads 12` / `--threads-batch 24` tuned for single-token generation and batch verification on SMT-enabled CPUs.
- **Sampling** — Unsloth-standard: `temp=1.0`, `top_p=0.95`, `top_k=64`.

## Setup

```bash
# Pre-download model to HF cache (skips if already cached)
./00_d_pre_download_model.sh

# Force re-download (bypasses local cache, useful for corrupted files or updates)
./00_e_force_download_model.sh
```

## Usage

```bash
# Start the inference server
./01_up.sh

# Follow logs
./05_docker_logs.sh

# Test API connectivity
./04_test_curl.sh

# Stop the server
./02_down.sh
```

Or directly via Docker Compose:
```bash
docker compose up -d
```

## References

- [Unsloth Gemma 4 12B GGUF Model Card](https://huggingface.co/unsloth/gemma-4-12b-it-GGUF)
- [Unsloth Dynamic 2.0 GGUFs Documentation](https://unsloth.ai/docs/basics/unsloth-dynamic-2.0-ggufs)
- [Official Gemma 4 Documentation by Google](https://ai.google.dev/gemma/docs/core)
