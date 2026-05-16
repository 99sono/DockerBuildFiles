# Qwen3.6-27B MTP Server on DGX Spark - GB10 Grace Blackwell (llama.cpp)

> Multi-Token Prediction speculative decoding • NVIDIA Grace Blackwell Superchip • ARM64 Optimized

**Target Hardware:** Acer Veriton GN100 / DGX Spark (NVIDIA GB10, 128GB Unified Memory LPDDR5X, ARM64/aarch64)
**Model:** `unsloth/Qwen3.6-27B-MTP-GGUF:UD-Q4_K_XL`
**Speculative Decoding:** MTP (`--spec-type draft-mtp`) with `--spec-draft-n-max 2`
**Server Port:** `8081`

---

## Quick Start

```bash
# 1. Pull the multi-arch image (ARM64)
./00_a_pull_image.sh

# 2. Create conda environment for host-side tools
./00_b_create_conda_env.sh
./00_c_install_packages.sh

# 3. Start the server
./01_a_up_server.sh

# 4. Test the server (Python script - requires `pip install openai`)
python 04_test_curl.py

# 5. Monitor logs
./05_docker_logs.sh
```

---

## Project Structure

```
llamacpp/qwen-3.6-27b-mtp-dgx-spark/
├── 00_a_pull_image.sh          # Pull ghcr.io/ggerganov/llama.cpp:cuda (ARM64)
├── 00_b_create_conda_env.sh    # Create conda env for host tools
├── 00_c_install_packages.sh    # Install huggingface-hub, jq, curl
├── docker-compose.yml           # llama-server MTP spec config (GB10 optimized)
├── 01_a_up_server.sh            # Start server (docker compose up -d)
├── 02_a_down_server.sh          # Stop server (docker compose down)
├── 03_enter_container.sh        # Enter container for debugging
├── 04_test_curl.py              # Test API call on port 8081 (Python)
├── 05_docker_logs.sh            # Follow server logs
├── 06_dump_help.sh              # Dump server version/help
├── .env.example                 # Environment variables template
├── README.md                    # This file
└── test/                        # Test scripts
```

---

## Docker Compose Configuration

### Key Settings

| Setting | Value | Purpose |
|---------|-------|---------|
| **Image** | `ghcr.io/ggerganov/llama.cpp:cuda` | Official multi-arch CUDA image (ARM64) |
| **Model** | `-hf unsloth/Qwen3.6-27B-MTP-GGUF:UD-Q4_K_XL` | Load from HuggingFace hub |
| **Port** | `8081:8080` | Host 8081 → Container 8080 |
| **Platform** | `linux/arm64` | Native ARMv9 Grace CPU |
| **GPU Layers** | `999` | Full GPU offload (all layers to unified memory) |
| **Context Size** | `131072` (128K) | Max context window |
| **KV Cache** | `q8_0` (K & V) | High precision cache |
| **Memory Lock** | `--mlock` | Pin memory to prevent paging on unified memory |
| **Batch Size** | `512` | Optimized for LPDDR5X bandwidth (~273 GB/s) |
| **Speculative** | `draft-mtp` with `draft-n-max 2` | Multi-Token Prediction (upstream syntax) |
| **Flash Attention** | `--flash-attn` | Native Blackwell acceleration |

### Unified Memory Architecture

The GB10 Grace Blackwell Superchip uses 128GB of unified LPDDR5X memory (~273 GB/s bandwidth) shared between the Grace CPU and Blackwell GPU. There is no discrete VRAM copy phase over PCIe - the entire memory pool is transparently accessible.

### Memory Pinning (`--mlock`)

Critical on unified memory setups: forces the Linux kernel to pin the model weights in physical RAM, preventing paging to disk which would severely degrade inference performance.

### Centralized Cache Strategy

The `-hf` flag in docker-compose.yml loads the GGUF model directly from the HuggingFace hub into the central `~/.cache/huggingface/` directory. No local model files or download scripts needed.

---

## Server Command Breakdown

```bash
# Core model loading
-hf unsloth/Qwen3.6-27B-MTP-GGUF:UD-Q4_K_XL
--host 0.0.0.0
--port 8080

# GPU offload (everything to unified memory pool)
--n-gpu-layers 999

# Attention & memory
--flash-attn
--cache-type-k q8_0
--cache-type-v q8_0
--ctx-size 131072

# Unified memory locking (critical for GB10)
--mlock

# Batch optimization (LPDDR5X bandwidth tuned)
--batch-size 512
--ubatch-size 512

# MTP Speculative Decoding
--spec-type draft-mtp
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
python 04_test_curl.py
```

The test reads the prompt from `test/test_file_01_prompt.md`, sends it to the server, and saves the response to `test/test_output_01.md`.

### Manual cURL Test

**Check available models:**
```bash
curl -s http://localhost:8081/v1/models | jq .
```

**Send a completion request:**
```bash
curl -s http://localhost:8081/v1/chat/completions \
  -H "Content-Type: application/json" \
  -d '{
    "model": "unsloth/Qwen3.6-27B-MTP-GGUF:UD-Q4_K_XL",
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
docker logs qwen-3.6-27b-mtp-dgx-spark | grep -i "mtp\|accept"

# Check memory usage
nvidia-smi
```

---

## Troubleshooting

### First Run: Large Download
On first start, the GGUF model will download to `~/.cache/huggingface/`. This is expected and may take several minutes depending on your connection.

### Memory Pinning Verification
Check logs for successful memory lock. If `--mlock` fails, the model may page to disk and performance will degrade significantly.

### Unified Memory
If you see micro-stutters, verify memory availability:
```bash
# Check container memory
docker inspect qwen-3.6-27b-mtp-dgx-spark | grep -i shm

# Check host memory
free -h
```

### MTP Acceptance Rate
- **>50%**: Excellent speedup (140+ tokens/s target)
- **20-50%**: Moderate speedup
- **<20%**: Speculative decoding may slow down generation

---

## Comparison: RTX 5090 (x86_64) vs DGX Spark GB10 (ARM64)

| Aspect | RTX 5090 (5090 folder) | DGX Spark GB10 (this folder) |
|--------|----------------------|------------------------------|
| **Architecture** | x86_64, discrete VRAM | ARM64, unified memory (128GB) |
| **GPU Memory** | 32GB GDDR7 | 128GB LPDDR5X (~273 GB/s) |
| **Docker Image** | `havenoammo/llama:cuda13-server` | `ghcr.io/ggerganov/llama.cpp:cuda` |
| **Platform** | `linux/amd64` | `linux/arm64` |
| **Memory Lock** | Not set | `--mlock` (required) |
| **Spec Flag** | `--spec-type mtp` | `--spec-type draft-mtp` |
| **Batch Size** | Default | `512` / `512` (tuned for UM) |
| **shm_size** | `32g` | `16g` |
| **LD_LIBRARY_PATH** | Hardcoded x86 path | Removed (native ARM64 paths) |

---

## License & Credits

- **llama.cpp**: [ggml-org/llama.cpp](https://github.com/ggml-org/llama.cpp)
- **Model**: [unsloth/Qwen3.6-27B-MTP-GGUF](https://huggingface.co/unsloth/Qwen3.6-27B-MTP-GGUF)
- **Docker Image**: [ggerganov/llama.cpp](https://github.com/ggerganov/llama.cpp)
