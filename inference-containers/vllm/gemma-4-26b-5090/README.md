# Gemma-4-26B-A4B-NVFP4 on RTX 5090 (32GB)

## Status: ✅ Working - NVIDIA Official Model

This folder contains the complete setup for running the **Gemma-4-26B-A4B-NVFP4** quantized model via vLLM on an **RTX 5090 (32GB VRAM)**.

## Requirements

- **GPU:** RTX 5090 (32GB VRAM)
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

# 5. Start the server (normal mode)
./01_a_up_normal.sh
# Or turboquant mode: ./01_b_up_turboquant.sh
# Or eagle3 speculative mode: ./01_c_up_eagle3.sh

# 6. Test the API
python 04_test_vllm_curl.py

# 7. Stop the server (matching mode)
./02_a_down_normal.sh
# Or turboquant: ./02_b_down_turboquant.sh
# Or eagle3: ./02_c_down_eagle3.sh
```

## Key Configuration (docker-compose.yml)

| Parameter | Value | Purpose |
|-----------|-------|---------|
| `--max-model-len` | 256000 | Maximum context window (prompt + response) |
| `--max-num-batched-tokens` | 16384 | Prefill batch size (conservative for long windows) |
| `--gpu-memory-utilization` | 0.85 | 85% of VRAM reserved for model + KV cache |
| `--max-num-seqs` | 2 | Single-user mode (saves memory) |
| `--kv-cache-dtype` | fp8_e4m3 | FP8 KV cache for memory efficiency |
| `--moe-backend` | cutlass | Fast MoE kernel fusion |

### Benchmark Parameters

Test script uses NVIDIA's benchmark parameters:
- `temperature=1.0`
- `top_p=0.95`
- `max_new_tokens=131072`

## Model Architecture

- **Model:** nvidia/Gemma-4-26B-A4B-NVFP4 (NVIDIA official)
- **Type:** Mixture-of-Experts (MoE) with active parameters ~35B
- **Quantization:** NVFP4 (NVIDIA FP4)
- **KV Cache:** fp8_e4m3 (8-bit floating point)
- **Context Window:** 256K tokens

### Benchmark Results (NVIDIA official vs RedHat community)

| Benchmark | RedHat AI | NVIDIA Official |
|-----------|-----------|-----------------|
| GPQA Diamond | 79.90% | 79.90% |
| AIME 2025 | 88.95% | 90.00% |
| MMLU Pro | 84.80% | 84.80% |
| LiveCodeBench | 79.80% | 79.80% |
| IFEval | 96.40% | 96.40% |

## Troubleshooting

### OOM (Out of Memory)
If you see OOM errors, try:
1. Lower `--max-model-len` to 131072
2. Lower `--max-num-batched-tokens` to 8192
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
| `docker-compose.yml` | Main orchestration config (amd64) |
| `00_a_pull_vllm_image.sh` | Pull vLLM Docker image |
| `00_b_create_conda_env.sh` | Create conda environment |
| `00_c_install_packages.sh` | Install required Python packages |
| `00_d_pre_download_model.sh` | Pre-download model weights from HuggingFace |
| `00_e_vllm_entrypoint.sh` | Custom vLLM entrypoint wrapper |
| `01_a_up_normal.sh` | Start server in normal mode |
| `01_b_up_turboquant.sh` | Start server with TurboQuant acceleration |
| `01_c_up_eagle3.sh` | Start server with Eagle-3 speculative decoding |
| `02_a_down_normal.sh` | Stop normal mode server |
| `02_b_down_turboquant.sh` | Stop turboquant mode server |
| `02_c_down_eagle3.sh` | Stop eagle3 mode server |
| `03_enter_container.sh` | Enter container shell |
| `04_test_vllm_curl.py` | Test API client (temperature=1.0, top_p=0.95) |
| `05_docker_logs.sh` | View container logs |
| `06_dump_vllm_help.sh` | Dump vLLM serve help output |