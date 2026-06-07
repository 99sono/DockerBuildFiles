# Gemma 4 12B Unified — DGX Spark (llama.cpp)

Optimized `llama.cpp` Docker container for serving **Gemma 4 12B Unified** (`UD-Q4_K_XL`) on the NVIDIA DGX Spark (GB10 Grace Blackwell, ARM64).

## Hardware & Architecture Notes

### DGX Spark GB10
The DGX Spark features a GB10 GPU with **128GB of unified memory** and a dedicated 300 GB/s memory bus. While the bandwidth is lower than discrete consumer GPUs, the massive memory pool enables unprecedented context lengths and multi-agent concurrency that no single consumer card can match.

### Memory Math & Hybrid Attention
| Component | Size (approx.) |
|---|---|
| Model weights (`UD-Q4_K_XL`) | ~7.4 GB |
| KV cache (`q8_0`, 2.6M ctx, parallel=10) | ~50+ GB (spread across slots) |
| CUDA overhead & buffers | ~2–4 GB |
| **Total** | **well within 128GB unified memory** |

Running a massive 2.6M context window with `q8_0` KV cache across 10 parallel slots is only possible thanks to Gemma 4's **hybrid attention mechanism**. Gemma 4 interleaves **1024-token local sliding window attention** with full global attention (only every few layers). Because most of the 48 layers only cache the 1024-token sliding window, the KV cache footprint per token is drastically smaller than standard dense models. Combined with the GB10's 128GB unified memory pool, this enables simultaneous multi-agent workloads at scale.

### ARM64 / aarch64 Multi-Arch Support
The container uses the official `linux/arm64` platform build (`server-cuda13`), leveraging native CUDA 13 support for the GB10 Grace Blackwell architecture. The `--mlock` flag pins memory to prevent OS-level paging on the unified memory bus.

## Configuration Highlights

- **`--jinja`** — Strictly required by Unsloth for the Gemma 4 chat template and native thinking token (`<|think|>`) handling.
- **Massive context** — `--ctx-size 2649600` (2.65M tokens), leveraging the GB10's 128GB memory headroom (~10x standard context).
- **Multi-agent parallelism** — `--parallel 10` for concurrent sub-agent workloads, with ~265K tokens per slot.
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
