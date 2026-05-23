# Qwen3.6-35B-A3B MTP Server on DGX Spark - GB10 Grace Blackwell (llama.cpp)

> Multi-Token Prediction speculative decoding • MoE 35B/3B active • NVIDIA Grace Blackwell Superchip • ARM64 Optimized

**Target Hardware:** Acer Veriton GN100 / DGX Spark (NVIDIA GB10, 128GB Unified Memory LPDDR5X, ARM64/aarch64)
**Variants:** Unsloth (`unsloth/Qwen3.6-35B-A3B-MTP-GGUF:UD-Q4_K_XL`) | Qwopus (`Jackrong/Qwopus3.6-35B-A3B-v1-MTP-GGUF:Qwopus3.6-35B-A3B-v1-MTP-Q4_K_M`)
**Speculative Decoding:** MTP (`--spec-type draft-mtp`) with `--spec-draft-n-max 2` and `--spec-draft-p-min 0.85`
**Server Port:** `8000`

---

## Quick Start

```bash
# 1. Pull the multi-arch image (ARM64)
./00_a_pull_image.sh

# 2. Pre-download model weights (unsloth variant)
./00_d_pre_download_model_unsloth.sh

# Or for qwopus variant:
./00_d_pre_download_model_qwopus.sh

# 3. Start the server (unsloth)
./01_up_unsloth.sh

# Or start qwopus:
./01_up_qwopus.sh

# 4. Test the server (Python script - requires `pip install openai`)
./04_test_curl.sh

# 5. Monitor logs
./05_docker_logs.sh
```

---

## Project Structure

```
llamacpp/qwen-3.6-35b-dgx-spark/
├── docker-compose.yml              # Unsloth variant (UD-Q4_K_XL)
├── docker-compose-qwopus.yml       # Qwopus variant (Q4_K_M)
├── .env.example                    # Environment variables template
├── 00_a_pull_image.sh             # Pull ggml-org/llama.cpp:server-cuda13 (ARM64)
├── 00_d_pre_download_model_unsloth.sh   # Pre-download unsloth GGUF
├── 00_d_pre_download_model_qwopus.sh    # Pre-download qwopus GGUF
├── 01_up_unsloth.sh               # Start unsloth server
├── 01_up_qwopus.sh                # Start qwopus server
├── 02_down.sh                     # Stop and remove containers
├── 03_enter_container.sh          # Enter container for debugging
├── 04_test_curl.sh                # Test API call on port 8000
├── 05_docker_logs.sh              # Follow unsloth server logs
├── 05_docker_logs_qwopus.sh       # Follow qwopus server logs
├── 06_dump_help.sh                # Dump server version/help
├── README.md                      # This file
├── test/                          # Test prompt files
└── metadata/                      # Benchmark logs, VRAM traces
```

---

## Docker Compose Configuration

### Key Settings

| Setting | Value | Purpose |
|---------|-------|---------|
| **Image** | `ghcr.io/ggml-org/llama.cpp:server-cuda13` | Official multi-arch CUDA 13 image (ARM64) |
| **Unsloth Model** | `-hf unsloth/Qwen3.6-35B-A3B-MTP-GGUF:UD-Q4_K_XL` | Best UD 4-bit quant, ~22.9 GB |
| **Qwopus Model** | `-hf Jackrong/Qwopus3.6-35B-A3B-v1-MTP-GGUF:Qwopus3.6-35B-A3B-v1-MTP-Q4_K_M` | Fine-tuned variant, ~21.7 GB |
| **Port** | `8000:8000` | Host 8000 → Container 8000 |
| **Platform** | `linux/arm64` | Native ARMv9 Grace CPU |
| **GPU Layers** | `999` | Full GPU offload (all layers to unified memory) |
| **Context Size** | `131072` (128K) | Max context window |
| **KV Cache** | `q8_0` (K & V) | High precision cache |
| **Memory Lock** | `--mlock` | Pin memory to prevent paging on unified memory |
| **Batch Size** | `512` | Optimized for LPDDR5X bandwidth (~273 GB/s) |
| **Speculative** | `draft-mtp` with `n-max 2`, `p-min 0.85` | Conservative MTP settings |
| **Flash Attention** | `--flash-attn on` | Native Blackwell acceleration |

### Unified Memory Architecture

The GB10 Grace Blackwell Superchip uses 128GB of unified LPDDR5X memory (~273 GB/s bandwidth) shared between the Grace CPU and Blackwell GPU. There is no discrete VRAM copy phase over PCIe — the entire memory pool is transparently accessible.

### Why MoE Matters for DGX Spark

With only **3B active parameters per token** (out of 35B total), this MoE model should decode much faster than the 27B dense model on the same hardware, despite having more total parameters. The bottleneck shifts from compute to memory bandwidth — and with 128GB unified memory at ~273 GB/s, there's plenty of headroom.

### Memory Pinning (`--mlock`)

Critical on unified memory setups: forces the Linux kernel to pin the model weights in physical RAM, preventing paging to disk which would severely degrade inference performance.

---

## Variant Comparison

| Aspect | Unsloth | Qwopus |
|--------|---------|--------|
| **Source** | `unsloth/Qwen3.6-35B-A3B-MTP-GGUF` | `Jackrong/Qwopus3.6-35B-A3B-v1-MTP-GGUF` |
| **Quantization** | UD-Q4_K_XL (~22.9 GB) | Q4_K_M (~21.7 GB) |
| **Container Name** | `qwen-3.6-35b-mtp-dgx-spark` | `qwopus36-35b-mtp-dgx-spark` |
| **Compose File** | `docker-compose.yml` | `docker-compose-qwopus.yml` |
| **Training** | Base model, no fine-tuning | LoRA fine-tuned (~9% params), 3-stage curriculum |
| **Benchmark Score** | N/A (base) | 88.6 overall (independent benchmark) |
| **Vision Support** | Yes (Qwen3.6 native) | Yes (requires `mmproj.gguf`) |

---

## Server Command Breakdown (Unsloth)

```bash
# Core model loading
-hf unsloth/Qwen3.6-35B-A3B-MTP-GGUF:UD-Q4_K_XL
--host 0.0.0.0
--port 8000

# GPU offload (everything to unified memory pool)
--n-gpu-layers 999

# Attention & memory
--flash-attn on
--cache-type-k q8_0
--cache-type-v q8_0
--ctx-size 131072

# Unified memory locking (critical for GB10)
--mlock

# Batch optimization (LPDDR5X bandwidth tuned)
--batch-size 512
--ubatch-size 512

# MTP Speculative Decoding (conservative mode)
--spec-type draft-mtp
--spec-draft-n-max 2
--spec-draft-p-min 0.85

# Generation parameters
--temp 1.0
--top-p 0.95
--top-k 20
--presence-penalty 1.5
```

---

## MTP Speculative Decoding — Why Conservative Settings?

The `--spec-draft-n-max 2` and `--spec-draft-p-min 0.85` settings were carried over from the proven 27B DGX Spark benchmarks. On that setup:

| Config | `n-max` | `p-min` | Gen Speed (1st req) | Gen Speed (2nd req) | Draft Acceptance |
|--------|---------|---------|---------------------|---------------------|-----------------|
| **Conservative** | 2 | 0.85 | ~18-22 tok/s | ~21-22 tok/s | 72-94% |
| Aggressive (TESTED) | 3 | 0.75 | 16.83 tok/s | 14.90 tok/s | 53-64% |

**Lesson learned:** Aggressive settings actually **degraded** performance by 10-32%. The MTP heads on Qwen3.6 are already highly accurate (~80%+ per-token acceptance), so shorter chains with higher confidence avoid expensive verification overhead when longer speculative sequences fail.

For the 35B MoE variant, these same values serve as a starting point — expect the decode speed to be notably faster due to the MoE architecture's lower active parameter count.

---

## Testing

### Quick Test

```bash
./04_test_curl.sh
```

The test reads the prompt from `test/test_file_01_prompt.md`, sends it to the server, and saves the response.

### Manual cURL Test

**Check available models:**

```bash
curl -s https://localhost/v1/models | jq .
```

**Send a completion request:**

```bash
curl -s https://localhost/v1/chat/completions \
  -H "Content-Type: application/json" \
  -d '{
    "model": "qwen3.6-35b",
    "messages": [
      {"role": "user", "content": "Hello!"}
    ],
    "max_tokens": 64
  }' | jq .
```

---

## Monitoring

```bash
# Follow logs (unsloth)
./05_docker_logs.sh

# Follow logs (qwopus)
./05_docker_logs_qwopus.sh

# View MTP acceptance rate in logs
docker logs qwen-3.6-35b-mtp-dgx-spark | grep -i "mtp\|accept"

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
# Check container shared memory
docker inspect qwen-3.6-35b-mtp-dgx-spark | grep -i shm

# Check host memory
free -h
```

### MTP Acceptance Rate

With conservative settings (`--spec-draft-n-max 2`, `--spec-draft-p-min 0.85`):

- **>70%**: Excellent — MTP heads are confident, good speedup expected
- **50-70%**: Moderate speedup
- **<50%**: Something is wrong; check context length and model compatibility

### Context Capacity Warning

```
n_ctx_seq (131072) < n_ctx_train (262144) -- the full capacity of the model will not be utilized
```

This is expected. The model was trained on 256K context; we're using 128K. Fine for most workloads.

---

## Comparison: 35B MoE vs 27B Dense on DGX Spark

### Why MoE Should Be Much Faster

The DGX Spark's bottleneck is memory bandwidth (~273 GB/s LPDDR5X), not compute (1 PFLOP). Both the 27B and 35B are memory-bound:

**27B Dense — reads ALL weights per decode step:**
- 27B active params = ~16.5 GB per decode pass at Q4
- At 273 GB/s: theoretical max ≈ **16 tok/s** (matches observed 18-22 tok/s with MTP)

**35B MoE — reads ONLY active expert weights per decode step:**
- 3B active params = ~2.4 GB per decode pass at Q4 (same quant)
- All ~22.9 GB loaded once at startup, but only the routed experts are read/computed per token
- At 273 GB/s: theoretical max ≈ **113 tok/s** — dramatically higher ceiling

The RTX 5090's speed advantage comes from its 1700 GB/s GDDR7 bandwidth (vs 273 GB/s), not compute power. The DGX Spark has more FLOPs but is starved by LPDDR5X bandwidth when feeding a dense model.

| Aspect | 27B Dense (current) | 35B MoE (this setup) |
|--------|-------------------|---------------------|
| **Active params** | ~27B per token | ~3B per token |
| **Weight read per decode step** | ~16.5 GB | ~2.4 GB |
| **Total memory footprint** | ~16.5 GB Q4 | ~22.9 GB Q4 (all experts pre-loaded) |
| **Bottleneck** | Memory bandwidth | Memory bandwidth (but 7× less data per step) |
| **MTP support** | Yes (verified, ~18-22 tok/s) | Yes (expected significantly faster) |
| **Vision** | No | Yes |
| **vLLM decode speed (reference)** | N/A (llamacpp only) | ~45-50 tok/s (PrismaQuant 35B, different path) |

---

## Docker Image

The DGX Spark uses `ghcr.io/ggml-org/llama.cpp:server-cuda13` — the official multi-arch image with ARM64 support and MTP speculative decoding built in.

### Available Tags

Hosted on GitHub Container Registry: [ggml-org/llama.cpp versions](https://github.com/ggml-org/llama.cpp/pkgs/container/llama.cpp/versions)

---

## License & Credits

- **llama.cpp**: [ggml-org/llama.cpp](https://github.com/ggml-org/llama.cpp)
- **Unsloth MTP GGUF**: [unsloth/Qwen3.6-35B-A3B-MTP-GGUF](https://huggingface.co/unsloth/Qwen3.6-35B-A3B-MTP-GGUF)
- **Qwopus MTP GGUF**: [Jackrong/Qwopus3.6-35B-A3B-v1-MTP-GGUF](https://huggingface.co/Jackrong/Qwopus3.6-35B-A3B-v1-MTP-GGUF)
- **Qwopus base model**: [Jackrong/Qwopus3.6-35B-A3B-v1](https://huggingface.co/Jackrong/Qwopus3.6-35B-A3B-v1)
