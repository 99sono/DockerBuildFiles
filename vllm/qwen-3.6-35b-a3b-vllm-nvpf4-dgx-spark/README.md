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

## docker-compose02.yml — PrismaQuant on DGX Spark

This directory also contains an optimized configuration using **PrismaQuant 4.75-bit** quantization for the **DGX Spark** (Grace Blackwell ARM64) platform.

### Quick Start (DGX Spark)

```bash
# 1. Pull the vLLM image (same image as above)
./00_a_pull_vllm_image.sh

# 2. Pre-download PrismaQuant model weights
./00_d_pre_download_model_prisma.sh

# 3. Start with docker-compose02.yml
./01_up_prisma.sh

# 4. Stop
./02_down_prisma.sh
```

### Key Differences from docker-compose.yml

| Parameter | docker-compose.yml (NVFP4) | docker-compose02.yml (PrismaQuant) |
|---|---|---|
| Model | `RedHatAI/Qwen3.6-35B-A3B-NVFP4` | `rdtand/Qwen3.6-35B-A3B-PrismaQuant-4.75bit-vllm` |
| GPU Mem Util | 0.65 | **0.80** |
| KV Cache Dtype | fp8_e4m3 | **fp8** |
| Max Num Seqs | 8 | **10** |
| Max Num Batched Tokens | 65536 | **32768** |
| Speculative Tokens (MTP) | 2 | **3** |
| Attention Backend | *(none)* | **flashinfer** |
| Moe Backend | flashinfer_cutlass | *(none)* |
| Hardware | RTX 5090 (32GB) | **DGX Spark (128GB UMA)** |

### Performance Summary (DGX Spark)

| Metric | Value |
|---|---|
| Prefill speed | ~400-1,500 tokens/s |
| Decode speed | ~45-50 tokens/s avg |
| Spec acceptance rate | ~63-93% |
| Cold start | ~6 minutes |

See `metadata/metadata_05_2026_05_21/03_qwen3.6_35b_analysis_of_log.md` for full benchmark analysis.

### 🔗 Credits

The `docker-compose02.yml` configuration was adapted from the **Spark Arena leaderboard**:
- **Source**: https://spark-arena.com/leaderboard
- **Submitted by**: [Sean Williams](https://forums.developer.nvidia.com/u/seanthomaswilliams)

The PrismaQuant 4.75-bit quantization with MTP speculative decoding (n=3) and FlashInfer attention backend is an optimized configuration specifically tuned for the DGX Spark (Grace Blackwell ARM64) platform.

### Quality & Reliability

> **Note on model quality comparison:**
>
> The Red Hat NVFP4 model (`RedHatAI/Qwen3.6-35B-A3B-NVFP4`) demonstrated significant hallucinations and doom loops during testing. In contrast, the **rdtand/Qwen3.6-35B-A3B-PrismaQuant-4.75bit-vllm** model has not exhibited any doom loops and appears to work solidly as a main model with "cline" coding agent.
>
> This PrismaQuant model is now the **primary model for the DGX Spark** due to its very good speed and reliability.
>
> **Comparison with other models tested on DGX Spark:**
>
> | Model | Quality | Speed | Verdict |
> |---|---|---|---|
> | **PrismaQuant 35B (MTP)** | Excellent, no doom loops | ~45-50 tok/s decode, ~850-900 tok/s prefill | ✅ **Best overall for DGX Spark** |
> | LlamaCPP 27B | Excellent output quality | Slow tokens/second | ⚠️ Good quality but too slow |
> | RedHat NVFP4 35B | Hallucinations, doom loops | Good speed | ❌ Unreliable |
>
> The MTP 35B model excels at both prefill and decode on the DGX Spark. Batched request testing should yield very high aggregate tokens/second throughput.

## Files

| File | Purpose |
|------|---------|
| `docker-compose.yml` | Main orchestration config (NVFP4, RTX 5090) |
| `docker-compose02.yml` | PrismaQuant config (DGX Spark, ARM64) |
| `00_a_pull_vllm_image.sh` | Pull vLLM Docker image |
| `00_d_pre_download_model.sh` | Pre-download NVFP4 model weights |
| `00_d_pre_download_model_prisma.sh` | Pre-download PrismaQuant model weights |
| `01_up.sh` / `02_down.sh` | Start/stop NVFP4 server |
| `01_up_prisma.sh` / `02_down_prisma.sh` | Start/stop PrismaQuant server |
| `03_enter_container.sh` | Enter container shell |
| `04_test_vllm_curl.py` | Test API client |
| `05_docker_logs.sh` | View NVFP4 container logs |
| `05_docker_logs_prisma.sh` | View PrismaQuant container logs |
