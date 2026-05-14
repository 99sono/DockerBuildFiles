# Qwen3.6-27B MTP Server on RTX 5090 (llama.cpp)

> Multi-Token Prediction speculative decoding • Blackwell SM 12.0 Optimized • Microwave-ready Docker

**Target Hardware:** RTX 5090 (32 GB GDDR7, SM 12.0, x86_64)
**Model:** unsloth/Qwen3.6-27B-A3B-GGUF:UD-Q4_K_XL
**Speculative Decoding:** MTP (Multi-Token Prediction) with `--spec-draft-n-max 2`
**Server Port:** `8081`

---

## Quick Start

```bash
# 1. Pull the pre-built image
./00_a_pull_image.sh

# 2. Create conda environment for host-side tools
./00_b_create_conda_env.sh
./00_c_install_packages.sh

# 3. Start the server
./01_a_up_server.sh

# 4. Test the server
./04_test_curl.sh

# 5. Monitor logs
./05_docker_logs.sh
```

---

## Project Structure

```
llamacpp/qwen-3.6-27b-mtp-5090/
├── 00_a_pull_image.sh          # Pull havenoammo/llama:cuda13-server
├── 00_b_create_conda_env.sh    # Create conda env for host tools
├── 00_c_install_packages.sh    # Install huggingface-hub, jq, curl
├── docker-compose.yml           # llama-server MTP spec config
├── 01_a_up_server.sh            # Start server (docker compose up -d)
├── 02_a_down_server.sh          # Stop server (docker compose down)
├── 03_enter_container.sh        # Enter container for debugging
├── 04_test_curl.sh              # Test API call on port 8081
├── 05_docker_logs.sh            # Follow server logs
├── 06_dump_help.sh              # Dump server version/help
├── .env.example                 # Environment variables template
├── README.md                    # This file
├── metadata/                    # Benchmark logs, VRAM traces
└── test/                        # Test scripts
```

---

## Docker Compose Configuration

### Key Settings

| Setting | Value | Purpose |
|---------|-------|---------|
| **Image** | `havenoammo/llama:cuda13-server` | Pre-built CUDA 12.8+ for MMQ kernels |
| **Model** | `-hf unsloth/Qwen3.6-27B-A3B-GGUF:UD-Q4_K_XL` | Load from HuggingFace hub |
| **Port** | `8081:8080` | Host 8081 → Container 8080 |
| **GPU Layers** | `999` | Full GPU offload (all layers) |
| **Context Size** | `131072` (128K) | Max context window |
| **KV Cache** | `q8_0` (K & V) | High precision cache |
| **Speculative** | `mtp` with `draft-n-max 2` | Multi-Token Prediction |
| **Flash Attention** | `--flash-attn` | Native SM 120 acceleration |

### Centralized Cache Strategy

The `-hf` flag in docker-compose.yml loads the GGUF model directly from the HuggingFace hub into the central `~/.cache/huggingface/` directory. No local model files or download scripts needed.

---

## Server Command Breakdown

```bash
# Core model loading
-hf unsloth/Qwen3.6-27B-A3B-GGUF:UD-Q4_K_XL
--host 0.0.0.0
--port 8080

# GPU offload (everything to GPU)
--n-gpu-layers 999

# Attention & memory
--flash-attn
--cache-type-k q8_0
--cache-type-v q8_0
--ctx-size 131072

# MTP Speculative Decoding
--spec-type mtp
--spec-draft-n-max 2

# Generation parameters
--temp 1.0
--top-p 0.95
--top-k 20
--presence-penalty 1.5
```

---

## Testing

### Quick Test
```bash
./04_test_curl.sh
```

### Manual cURL Test
```bash
curl -s http://localhost:8081/v1/chat/completions \
  -H "Content-Type: application/json" \
  -d '{
    "model": "unsloth/Qwen3.6-27B-A3B-GGUF:UD-Q4_K_XL",
    "messages": [
      {"role": "user", "content": "Hello!"}
    ],
    "max_tokens": 64
  }' | jq .
```

---

## Monitoring

```bash
# Follow logs
./05_docker_logs.sh

# View MTP acceptance rate in logs
docker logs qwen-3.6-27b-mtp-5090 | grep -i "mtp\|accept"

# Check VRAM usage
nvidia-smi
```

---

## Troubleshooting

### First Run: Large Download
On first start, the GGUF model will download to `~/.cache/huggingface/`. This is expected and may take several minutes depending on your connection.

### MMQ Kernel Verification
Check logs for MMQ kernel activation. If the server falls back to generic cuBLAS, performance will be significantly degraded.

### WSL2 Memory
If you see micro-stutters, verify WSL2 memory allocation:
```bash
# Check container memory
docker inspect qwen-3.6-27b-mtp-5090 | grep -i shm
```

### MTP Acceptance Rate
- **>50%**: Excellent speedup (140+ tokens/s target)
- **20-50%**: Moderate speedup
- **<20%**: Speculative decoding may slow down generation

---

## Comparison: vLLM vs llama.cpp

| Aspect | vLLM (NVFP4) | llama.cpp (GGUF + MTP) |
|--------|-------------|------------------------|
| **Throughput** | High (steady) | Very high (ramps up with MTP) |
| **VRAM Overhead** | Higher (FP8 KV cache) | Lower (quantized GGUF) |
| **Speculative** | Native MTP support | MTP via draft tokens |
| **Build Required** | Pull image | Pull image (no build) |
| **Best For** | Multi-user, varied prompts | Repetitive/pattern-heavy tasks |

---

## License & Credits

- **llama.cpp**: [ggml-org/llama.cpp](https://github.com/ggml-org/llama.cpp)
- **Model**: [unsloth/Qwen3.6-27B-A3B-GGUF](https://huggingface.co/unsloth/Qwen3.6-27B-A3B-GGUF)
- **Docker Image**: [havenoammo/llama](https://hub.docker.com/r/havenoammo/llama)