# Gemma-4-26B-A4B-NVFP4 on DGX Spark (128GB UMA)

## Status: 🚧 In Progress

This folder contains the complete setup for running the **Gemma-4-26B-A4B-NVFP4** quantized model via vLLM on a **DGX Spark** (Grace Blackwell, 128GB Unified Memory).

## Requirements

- **GPU:** DGX Spark (Grace Blackwell, 128GB Unified Memory, ARM64)
- **Docker:** With NVIDIA CUDA toolkit support
- **Docker Compose:** v2.x+

## Quick Start

```bash
# 1. Pull the vLLM image
./00_a_pull_vllm_image.sh

# 2. Create conda environment
./00_b_create_conda_env.sh

# 3. Install required packages
./00_c_install_packages.sh

# 4. Pre-download model weights
./00_d_pre_download_model.sh

# 5. Start the server
./01_up.sh

# 6. Test the API
python 04_test_vllm_curl.py

# 7. Stop the server
./02_down.sh
```

## Key Configuration (docker-compose.yml)

| Parameter | Value | Purpose |
|-----------|-------|---------|
| `--max-model-len` | 256000 | Maximum context window (prompt + response) |
| `--max-num-batched-tokens` | 32768 | Prefill batch size |
| `--gpu-memory-utilization` | 0.85 | 85% of 128GB UMA reserved for model + KV cache |
| `--max-num-seqs` | 4 | Concurrent request sequences |
| `--kv-cache-dtype` | fp8_e4m3 | FP8 KV cache for memory efficiency |
| `--moe-backend` | flashinfer_cutlass | Fast MoE kernel fusion for Blackwell |

### Context Length Limits

With this configuration:
- **Max total tokens:** 256,000 (prompt + response combined)
- **Available KV cache:** ~300,000+ tokens (slightly more than max-model-len)
- **Example:** You can process a large document and receive a response within the context window

### Memory Optimization

The DGX Spark's 128GB Unified Memory Architecture allows for:
- `--gpu-memory-utilization: 0.85` = ~108.8 GB for model weights + KV cache
- `--max-num-batched-tokens: 32768` = fast prefill with good KV cache headroom

### No Speculative Decoding

Speculative decoding has been **removed** from this configuration as it was proven unstable on DGX Spark. The setup runs pure vLLM with MoE kernels only.

## Model Architecture

- **Model:** RedHatAI/gemma-4-26B-A4B-it-NVFP4
- **Type:** Mixture-of-Experts (MoE)
- **Quantization:** NVFP4 (NVIDIA FP4)
- **KV Cache:** fp8_e4m3 (8-bit floating point)

## Troubleshooting

### Container Fails to Start
1. Check logs: `./05_docker_logs.sh`
2. Ensure the development network exists: `docker network ls | grep development-network`
3. Verify GPU access: `docker run --gpus all nvidia/cuda:12.0-base nvidia-smi`

### OOM (Out of Memory)
If you see OOM errors, try:
1. Lower `--max-num-batched-tokens` to 16384
2. Lower `--max-model-len` to 131072
3. Reduce `--gpu-memory-utilization` to 0.75

### Slow Startup
The model takes ~60-120 seconds to load. Monitor progress with:
```bash
./05_docker_logs.sh
```

## API Endpoint

```
http://localhost:8000/v1/chat/completions
```

## Files

| File | Purpose |
|------|---------|
| `docker-compose.yml` | Main orchestration config (ARM64, no speculative decoding) |
| `.env.example` | Environment variable template |
| `00_env.sh` | Environment variable setup |
| `00_a_pull_vllm_image.sh` | Pull vLLM Docker image |
| `00_b_create_conda_env.sh` | Create conda environment for Python tools |
| `00_c_install_packages.sh` | Install Python packages (openai, rich, etc.) |
| `00_d_pre_download_model.sh` | Pre-download model weights to local cache |
| `01_up.sh` | Start the server |
| `02_down.sh` | Stop the server |
| `03_enter_container.sh` | Enter container shell |
| `04_test_vllm_curl.py` | Test API client |
| `05_docker_logs.sh` | View container logs |
| `06_dump_vllm_help.sh` | Dump vLLM serve help output |