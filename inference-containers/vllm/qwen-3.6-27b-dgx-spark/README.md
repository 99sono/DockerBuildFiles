# Qwen3.6-27B NVFP4 MTP on DGX Spark (llama.cpp alternative)

> Native vLLM deployment with Multi-Token Prediction • NVIDIA Grace Blackwell Superchip • ARM64 Optimized

**Target Hardware:** Acer Veriton GN100 / DGX Spark (NVIDIA GB10, 128GB Unified Memory LPDDR5X, ARM64/aarch64)
**Model:** `sakamakismile/Qwen3.6-27B-Text-NVFP4-MTP`
**Speculative Decoding:** Native MTP (`mtp`) with `num_speculative_tokens: 3`
**Quantization:** modelopt NVFP4 (native fast path on Blackwell SM120)

---

## Quick Start

```bash
# 1. Pull the vLLM image
./00_a_pull_vllm_image.sh

# 2. Create conda environment for host-side tools
./00_b_create_conda_env.sh
./00_c_install_packages.sh

# 3. (Optional) Pre-download model weights
./00_d_pre_download_model.sh

# 4. Start the server
./01_up.sh

# 5. Test the API
python 04_test_vllm_curl.py

# 6. Monitor logs
./05_docker_logs.sh

# 7. Stop the server
./02_down.sh
```

---

## Project Structure

```
vllm/qwen-3.6-27b-nvfp4-mtp-dgx-spark/
├── docker-compose.yml           # vLLM service config (GB10 optimized, MTP enabled)
├── .env.example                 # Environment variables template
├── 00_env.sh                    # Runtime environment loader (gitignored)
├── 00_a_pull_vllm_image.sh      # Pull vLLM Docker image
├── 00_b_create_conda_env.sh     # Create conda env for host tools
├── 00_c_install_packages.sh     # Install openai, rich, huggingface_hub
├── 00_d_pre_download_model.sh   # Pre-download model weights to HF cache
├── 01_up.sh                     # Start server (docker compose up -d)
├── 02_down.sh                   # Stop server (docker compose down)
├── 03_enter_container.sh        # Enter container for debugging
├── 04_test_vllm_curl.py         # Test API endpoints with auth and tool choice
└── 05_docker_logs.sh            # Follow server logs
```

---

## Docker Compose Configuration

### Key Settings

| Setting | Value | Purpose |
|---------|-------|---------|
| **Image** | `vllm/vllm-openai:v0.20.2-ubuntu2404` | vLLM official multi-arch image (ARM64) |
| **Model** | `sakamakismile/Qwen3.6-27B-Text-NVFP4-MTP` | NVFP4 MTP model with restored bf16 MTP head |
| **Quantization** | `modelopt` | Native fast path on Blackwell SM120 (not `compressed-tensors`) |
| **Language Model Only** | `--language-model-only` | Required — vision tower stripped in this build |
| **Platform** | `linux/arm64` | Native ARMv9 Grace CPU |
| **GPU Memory** | `0.9` | 90% of 128GB UMA reserved for model + KV cache |
| **Context Size** | `262144` (256K) | Full trained context window |
| **Max Sequences** | `2` | Load-bearing — 4+ will OOM during cuda-graph capture with MTP + 256K + fp8 KV |
| **KV Cache** | `fp8` | Halves KV memory; lifts concurrency at 256K from ~4× to ~7× |
| **Batched Tokens** | `65536` | Godzilla mode prefill — leverages 128GB UMA |
| **MTP** | `qwen3_5_mtp` with `num_speculative_tokens: 3` | Native Multi-Token Prediction (single MTP layer applied recursively 3×) |
| **Reasoning Parser** | `qwen3` | Native reasoning format handling |
| **Tool Call Parser** | `qwen3_coder` | Proper code block parsing in agentic tool calls |
| **Auto Tool Choice** | enabled | Prevents HTTP 400 on `tool_choice: auto` requests |

### Why `modelopt` over `compressed-tensors`

The `compressed-tensors` quantization path is slower on Blackwell SM120. The `modelopt` format is NVIDIA's native fast path, delivering ~1.67-1.74× throughput improvement over `compressed-tensors` on Blackwell hardware.

### MTP Speculative Decoding

This model has the MTP head restored in bf16 (the original Qwen3.6-27B-NVFP4 had it dropped). The `qwen3_5_mtp` speculative method applies the single MTP layer recursively 3 times per draft pass, yielding:

- **Per-position acceptance:** ~87% / 72% / 61%
- **Mean accepted length:** ~3.0 - 4.0 tokens per draft pass
- **Throughput multiplier:** ~1.9× decode speedup vs non-MTP baseline

### Unified Memory Architecture

The GB10 Grace Blackwell Superchip uses 128GB of unified LPDDR5X memory (~273 GB/s bandwidth) shared between the Grace CPU and Blackwell GPU. There is no discrete VRAM copy phase over PCIe — the entire memory pool is transparently accessible.

### Centralized Cache Strategy

The model is loaded directly from the HuggingFace hub. On first run, vLLM downloads the safetensors weights to `~/.cache/huggingface/`. Use `00_d_pre_download_model.sh` to pre-download before starting the server.

---

## Server Command Breakdown

```bash
# Model identity
--model sakamakismile/Qwen3.6-27B-Text-NVFP4-MTP
--served-model-name Qwen3.6-27B-Text-NVFP4-MTP

# Quantization (critical for SM120 performance)
--quantization modelopt
--language-model-only

# Memory & scaling
--gpu-memory-utilization 0.9
--max-model-len 262144
--max-num-seqs 2
--kv-cache-dtype fp8

# Prefill acceleration (Godzilla mode)
--max-num-batched-tokens 65536
--enable-chunked-prefill
--enable-prefix-caching

# Native MTP speculative decoding
--speculative-config '{"method":"qwen3_5_mtp","num_speculative_tokens":3}'

# Parsers & tool support
--reasoning-parser qwen3
--tool-call-parser qwen3_coder
--enable-auto-tool-choice

# Startup optimizations
--safetensors-load-strategy prefetch
--max-cudagraph-capture-size 1

# Authentication & networking
--api-key ${VLLM_API_KEY:-dummy-key}
--host 0.0.0.0
--port 8000
```

---

## Testing

### Quick Test
```bash
conda activate testVllmQwen27B
python 04_test_vllm_curl.py
```

The test runs 4 scenarios:
1. Health check (`/health`)
2. Model listing (`/v1/models`)
3. Standard chat completion
4. Tool call with `tool_choice: auto`

### Manual cURL Test

**Check available models:**
```bash
curl -s https://spark-8ddc/v1/models \
  -H "Authorization: Bearer YOUR_API_KEY" \
  --cacert ../nginx/nginx-vllm-reverse-proxy-dgx-spark/nginx-proxy/ssl/nginx-selfsigned.crt | jq .
```

**Send a completion request:**
```bash
curl -s https://spark-8ddc/v1/chat/completions \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer YOUR_API_KEY" \
  --cacert ../nginx/nginx-vllm-reverse-proxy-dgx-spark/nginx-proxy/ssl/nginx-selfsigned.crt \
  -d '{
    "model": "Qwen3.6-27B-Text-NVFP4-MTP",
    "messages": [
      {"role": "user", "content": "Hello!"}
    ],
    "max_tokens": 64
  }' | jq .
```

---

## Performance Reference

Verified on Blackwell hardware (RTX PRO 6000, but applicable to GB10 with more memory headroom):

| Configuration | Single Request (tok/s) | 2-Parallel (tok/s) | vs Baseline |
|---------------|------------------------|--------------------|-------------|
| Baseline (compressed-tensors, no MTP) | 56 / 59 / 59 | 119 / 119 | 1.0× |
| This config (modelopt + MTP n=3) | 104 / 98 / 100 | 189 / 207 | **1.74×** |

*(S = 50-token, M = 350-token, L = 700-token decodes)*

---

## Monitoring

```bash
# Follow logs
./05_docker_logs.sh

# View MTP acceptance rate in logs
docker logs qwen-3.6-27b-nvfp4-mtp-dgx-spark | grep -i "mtp\|accept"

# Check memory usage
nvidia-smi
```

---

## Troubleshooting

### OOM during startup
If you see OOM during cuda-graph capture, `--max-num-seqs 2` is the verified safe limit with MTP n=3 + 256K context + fp8 KV. Do not increase it.

### Slow startup
The model takes ~90-120 seconds to load. Monitor progress with:
```bash
docker logs -f qwen-3.6-27b-nvfp4-mtp-dgx-spark
```

### MTP not accepting
If MTP acceptance rate is near 0%, verify the model has the MTP head (the `-Text-NVFP4-MTP` variant has it restored). The original `Qwen3.6-27B-NVFP4` does not include it.

### Nginx upstream-not-found crash
If nginx exits immediately with code 1:
```bash
docker logs nginx-proxy
# → nginx: [emerg] host not found in upstream "inference-server"
```
This means the vLLM container is not running yet. Start this server first, then start nginx.

---

## Comparison: This Model vs Qwen3.6-27B-NVFP4 (baseline)

| Feature | Baseline (`Qwen3.6-27B-NVFP4`) | This (`Qwen3.6-27B-Text-NVFP4-MTP`) |
|---------|--------------------------------|--------------------------------------|
| Quantization | `compressed-tensors` | `modelopt` (native SM120 fast path) |
| MTP head | ❌ Dropped during export | ✅ Restored in bf16 |
| Vision tower | Present | Stripped (text-only) |
| Speculative decoding | Not available | `qwen3_5_mtp` n=3, ~1.9× speedup |
| Recommended quantization flag | `--quantization compressed-tensors` | `--quantization modelopt` |
| Requires `--language-model-only` | No | Yes |

---

## Source References

- **Model:** [sakamakismile/Qwen3.6-27B-Text-NVFP4-MTP](https://huggingface.co/sakamakismile/Qwen3.6-27B-Text-NVFP4-MTP)
- **vLLM:** [vllm-project/vllm](https://github.com/vllm-project/vllm)
- **Quantization pipeline:** [lna-lab/GGUF-to-NVFP4-SM120](https://github.com/lna-lab/GGUF-to-NVFP4-SM120)