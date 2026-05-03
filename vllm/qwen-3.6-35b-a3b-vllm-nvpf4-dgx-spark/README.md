# Qwen3.6-35B-A3B-NVFP4 on RTX 5090 (32GB)

## Status: ✅ Working - 65K Context Achieved

This folder contains the complete setup for running the **Qwen3.6-35B-A3B-NVFP4** quantized model via vLLM on an RTX 5090 (32GB VRAM). The configuration supports up to **65,536 tokens** of context (prompt + response).

## Requirements

- **GPU:** RTX 5090 (32GB VRAM)
- **Docker:** With NVIDIA CUDA toolkit support
- **Docker Compose:** v2.x+

## Quick Start

```bash
# 1. Pull the vLLM image
./00_a_pull_vllm_image.sh

# 2. Pre-download model weights
./00_d_pre_download_model.sh

# 3. Start the server
docker compose up -d

# 4. Test the API
python 04_test_vllm_curl.py

# 5. Stop the server
./02_down.sh
```

## Key Configuration (docker-compose.yml)

| Parameter | Value | Purpose |
|-----------|-------|---------|
| `--max-model-len` | 65536 | Maximum context window (prompt + response) |
| `--max-num-batched-tokens` | 8192 | Prefill batch size (sweet spot for 65k context) |
| `--gpu-memory-utilization` | 0.90 | 90% of VRAM reserved for model + KV cache |
| `--max-num-seqs` | 1 | Single-user mode (saves memory) |
| `--kv-cache-dtype` | fp8_e4m3 | FP8 KV cache for memory efficiency |
| `--moe-backend` | cutlass | Fast MoE kernel fusion |

### Context Length Limits

With this configuration:
- **Max total tokens:** 65,536 (prompt + response combined)
- **Available KV cache:** ~75,000 tokens (slightly more than max-model-len)
- **Example:** You can paste a 50K token document and receive a ~15K token response

### Prefill Performance

`--max-num-batched-tokens` controls how many tokens are processed during the prompt prefill phase (before output tokens start generating):

| Batch Size | Prefill Speed | KV Cache Room | 65K Context? |
|------------|---------------|---------------|--------------|
| 16384 | Fastest | ~33K tokens | ❌ No (OOM) |
| **8192** | **Good** | **~75K tokens** | ✅ **Yes (recommended)** |
| 4096 | Slowest | ~75K+ tokens | ✅ Yes |

## Model Architecture

- **Model:** RedHatAI/Qwen3.6-35B-A3B-NVFP4
- **Type:** Mixture-of-Experts (MoE) with active params ~35B, total ~191B
- **Quantization:** NVFP4 (NVIDIA FP4)
- **Activation:** Activates ~3.5B parameters per token
- **KV Cache:** fp8_e4m3 (8-bit floating point)

## Troubleshooting

### OOM (Out of Memory)
If you see OOM errors, try:
1. Lower `--max-model-len` to 32768
2. Lower `--max-num-batched-tokens` to 4096
3. Reduce `--gpu-memory-utilization` to 0.85

### Slow Startup
The model takes ~90-120 seconds to load. Monitor progress with:
```bash
docker compose logs -f --tail=100
```

### V2 Model Runner Crash
If enabling `VLLM_USE_V2_MODEL_RUNNER` causes crashes, keep it commented out. The V2 runner (async CPU/GPU overlap) requires additional memory during initialization and may not be compatible with 65K context on limited VRAM.

## API Endpoint

```
http://localhost:8000/v1/chat/completions
```

## Files

| File | Purpose |
|------|---------|
| `docker-compose.yml` | Main orchestration config |
| `00_a_pull_vllm_image.sh` | Pull vLLM Docker image |
| `00_d_pre_download_model.sh` | Pre-download model weights |
| `01_up.sh` / `02_down.sh` | Start/stop the server |
| `03_enter_container.sh` | Enter container shell |
| `04_test_vllm_curl.py` | Test API client |
| `05_docker_logs.sh` | View container logs |View container logs |