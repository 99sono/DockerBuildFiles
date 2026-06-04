# Gemma 4 12B Unified Server on DGX Spark — GB10 Grace Blackwell (llama.cpp)

> Encoder-free "Unified" multimodal architecture • Text, Image, Audio • NVIDIA Grace Blackwell Superchip • ARM64 Optimized

**Target Hardware:** Acer Veriton GN100 / DGX Spark (NVIDIA GB10, 128GB Unified Memory LPDDR5X, ARM64/aarch64)
**Variant:** Unsloth (`unsloth/gemma-4-12b-it-GGUF-it:UD-Q4_K_XL`)
**Text Capacity:** 256K tokens (full context window) • Sliding window: 1024
**Vocabulary:** 262K tokens • Architecture: Dense, 48 layers, 11.95B parameters
**Server Port:** `8000`

---

## Quick Start

```bash
# 1. Pull the multi-arch image (ARM64)
./00_a_pull_image.sh

# 2. Pre-download model weights (Unsloth UD-Q4_K_XL, 7.37 GB)
./00_d_pre_download_model.sh

# 3. Start the server
./01_up.sh

# 4. Test the server (Python script - requires `pip install openai`)
./04_test_curl.sh

# 5. Monitor logs
./05_docker_logs.sh
```

---

## Project Structure

```
llamacpp/gemma-4-12b-dgx-spark/
├── docker-compose.yml              # Main compose config (UD-Q4_K_XL)
├── .env.example                    # Environment variables template
├── 00_a_pull_image.sh              # Pull ggml-org/llama.cpp:server-cuda13 (ARM64)
├── 00_b_create_conda_env.sh         # Create conda environment for tools
├── 00_c_install_packages.sh         # Install test client deps (openai)
├── 00_d_pre_download_model.sh       # Pre-download Unsloth GGUF (~7.37 GB)
├── 01_up.sh                        # Start the server
├── 02_down.sh                      # Stop and remove containers
├── 03_enter_container.sh           # Enter container for debugging
├── 04_test_curl.sh                 # Test API call on port 8000
├── 05_docker_logs.sh               # Follow logs of active container (auto-detect)
├── 06_dump_help.sh                 # Show help + dump server version/info
├── README.md                       # This file
├── test/                           # Test prompt files
│   └── test_file_01_prompt.md
└── metadata/                       # Benchmark logs, traces
```

---

## Docker Compose Configuration

### Key Settings

| Setting | Value | Purpose |
|---------|-------|---------|
| **Image** | `ghcr.io/ggml-org/llama.cpp:server-cuda13` | Official multi-arch CUDA 13 image (ARM64) |
| **Model** | `-hf unsloth/gemma-4-12b-it-GGUF-it:UD-Q4_K_XL` | Unsloth Dynamic 2.0 4-bit, 7.37 GB |
| **Port** | `8000:8000` | Host 8000 → Container 8000 |
| **Platform** | `linux/arm64` | Native ARMv9 Grace CPU |
| **GPU Layers** | `999` | Full GPU offload (all layers to unified memory) |
| **Context Size** | `262144` (256K) | Full context window capacity |
| **Parallel Slots** | `--parallel 10` | 10 concurrent slots for sub-agent workloads (~26K ctx/slot) |
| **KV Cache** | `q8_0` (K & V) | High precision cache |
| **Batch Size** | `512` | Optimized for LPDDR5X bandwidth (~300 GB/s) |
| **Flash Attention** | `--flash-attn on` | Native Blackwell acceleration |

### Unified Memory Architecture

The GB10 Grace Blackwell Superchip uses 128GB of unified LPDDR5X memory (~300 GB/s bandwidth) shared between the Grace CPU and Blackwell GPU. There is no discrete VRAM copy phase over PCIe — the entire memory pool is transparently accessible.

The model weights (7.37 GB at Q4_K_XL) plus KV cache for the full 256K context window easily fit within the 128GB unified pool. With `shm_size: "70g"`, the container has dedicated shared memory for high-speed KV cache paging while leaving the majority of RAM available for the CPU-side model loading, context processing, and KV cache expansion.

### Why a Dense 12B Model on DGX Spark

At just 12B active parameters, this model is one of the most memory-efficient options on the 128GB platform. The DGX Spark's memory bandwidth (~300 GB/s LPDDR5X) is the limiting factor for decode speed, not compute. A 12B model at Q4 quantization reads only ~3 GB of weights per decode step:

- **Per-step weight read:** ~3 GB (12B params × 4 bits/8 bits/param)
- **Theoretical max at 300 GB/s:** ~100 tok/s
- **Actual expectation:** 50-70 tok/s (limited by CPU-side ops, context processing, and multimodal overhead)

This makes it ideal for latency-sensitive use cases, high-throughput serving, and scenarios where the multimodal capabilities of the "Unified" architecture are needed.

---

## Server Command Breakdown

```bash
# Core model loading
-hf unsloth/gemma-4-12b-it-GGUF-it:UD-Q4_K_XL
--host 0.0.0.0
--port 8000

# GPU offload (entire model to unified memory pool)
--n-gpu-layers 999

# Attention & memory
--flash-attn on
--cache-type-k q8_0
--cache-type-v q8_0
--ctx-size 262144

# 10 concurrent slots for parallel sub-agent workloads
# Each slot gets ctx_size / np tokens (~26K per slot at 256K context)
--parallel 10

# Batch optimization (LPDDR5X bandwidth tuned)
--batch-size 512
--ubatch-size 512

# Sampling parameters (Gemma 4 standard)
--temp 1.0
--top-p 0.95
--top-k 64

# No speculative decoding — Gemma 4 has no MTP heads
# No presence-penalty — keep at 1.0 per Unsloth recommendation
```

---

## Multimodal Capabilities — Encoder-Free "Unified" Architecture

### What "Unified" Means

Gemma 4 12B Unified uses Google DeepMind's encoder-free architecture. Unlike traditional multimodal models that use a separate vision/audio encoder connected to the language backbone, Gemma 4 integrates all modalities directly into the transformer layers:

- **No separate vision encoder** (`--mmproj` not needed)
- **No separate audio encoder**
- **No cross-attention or projection layers** bridging modalities
- **Text, image, and audio tokens all flow through the same transformer**

This means you download a single GGUF file (7.37 GB) and get everything — text generation, image understanding, and audio comprehension — baked into one model.

### No mmproj File Needed

In most llamacpp multimodal setups, you need a separate multimodal projector (`mmproj.gguf`) that bridges a vision encoder's output to the language model embeddings. Gemma 4 Unified eliminates this entirely:

| Aspect | Traditional Multimodal | Gemma 4 Unified |
|--------|----------------------|-----------------|
| **Files** | Model GGUF + `mmproj.gguf` (2 files) | Single GGUF |
| **Vision** | Separate encoder + projector | Integrated into transformer |
| **Audio** | Separate encoder | Integrated into transformer |
| **Total size** | ~12 GB (model + projector) | 7.37 GB |
| **Loading complexity** | Two file paths, cross-attention config | Single file, native loading |

### Supported Multimodal Tokens

Gemma 4 was trained on a unified token space where image and audio patches are tokenized alongside text. The model's 262K vocabulary includes special tokens for:

- `<|img|>` — Image patch start
- `<|audio|>` — Audio segment start
- Standard text tokens

When sending image/audio data to the server, it should be base64-encoded in the message content as per the OpenAI-compatible API format.

---

## Thinking Mode

Gemma 4 12B Unified supports structured reasoning via the `<|think|>` token. This is not a separate mode — it's triggered by including the token in the system prompt.

### Enabling Thinking

Add `<|think|>` at the start of your system prompt to enable the model's structured reasoning:

```json
{
  "messages": [
    {
      "role": "system",
      "content": "<|think|>You are a helpful assistant that reasons through problems step by step before answering."
    },
    {
      "role": "user",
      "content": "Solve this math problem: What is 2^10 + 3^5?"
    }
  ]
}
```

### Output Structure

When thinking is enabled, the model produces output in this format:

```
<|channel>thought
[step-by-step reasoning goes here]
<channel|>
[final answer]
```

When thinking is disabled (no `<|think|>` in system prompt), larger models like Gemma 4 still emit empty thought blocks:

```
<|channel>thought
<channel|>
[final answer]
```

This behavior is consistent across all model sizes in the Gemma 4 family.

### No Special Flag Needed

Thinking mode is purely prompt-based — no llama.cpp command-line flag is required. The model recognizes `<|think|>` in the system prompt and adjusts its generation pattern accordingly.

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
curl -s http://localhost:8000/v1/models | jq .
```

**Send a text generation request:**

```bash
curl -s http://localhost:8000/v1/chat/completions \
  -H "Content-Type: application/json" \
  -d '{
    "model": "gemma-4-12b",
    "messages": [
      {"role": "user", "content": "Hello! Introduce yourself."}
    ],
    "max_tokens": 64
  }' | jq .
```

**Enable thinking mode:**

```bash
curl -s http://localhost:8000/v1/chat/completions \
  -H "Content-Type: application/json" \
  -d '{
    "model": "gemma-4-12b",
    "messages": [
      {
        "role": "system",
        "content": "<|think|>Think step by step before answering."
      },
      {"role": "user", "content": "Explain quantum entanglement simply."}
    ],
    "max_tokens": 512,
    "temperature": 0.7
  }' | jq .
```

**Vision — Send an image:**

```bash
curl -s http://localhost:8000/v1/chat/completions \
  -H "Content-Type: application/json" \
  -d '{
    "model": "gemma-4-12b",
    "messages": [
      {
        "role": "user",
        "content": [
          {"type": "text", "text": "What is in this image?"},
          {
            "type": "image_url",
            "image_url": {"url": "data:image/png;base64,<base64-encoded-image>" }
          }
        ]
      }
    ],
    "max_tokens": 256
  }' | jq .
```

---

## Monitoring

```bash
# Follow logs (auto-detects active container)
./05_docker_logs.sh

# Check memory usage
free -h

# Verify container status
docker ps | grep gemma
```

---

## Troubleshooting

### First Run: Large Download

On first start, the GGUF model will download from Hugging Face to `~/.cache/huggingface/`. This is expected and may take several minutes depending on your connection. The pre-download script (`00_d_pre_download_model.sh`) speeds up subsequent starts.

### Unified Memory

The model is small enough that it should not stress the 128GB unified memory. If you see issues:

```bash
# Check container shared memory
docker inspect gemma-4-12b-dgx-spark | grep -i shm

# Check host memory
free -h
```

### Generation Quality with top-k = 64

This setup uses `--top-k 64` following Google/Unsloth Gemma recommendations. Gemma 4's training and vocabulary (262K tokens) benefit from a wider sampling range than smaller models:

- **top-k 64**: Standard — matches Google's reference implementations
- **top-k 20**: More conservative — may feel more deterministic but less creative
- **top-p 0.95** is used alongside top-k (dual-sampling), providing additional control

### No Speculative Decoding Available

Gemma 4 does not have Multi-Token Prediction (MTP) heads, so `--spec-type` options are not supported. The model cannot use MTP speculative decoding. This does not significantly impact performance for a 12B model, where the decode speed is dominated by memory bandwidth rather than sequential generation overhead.

### "No mmproj" Clarification

If you're following documentation for multimodal models that require an `mmproj.gguf`, note that Gemma 4 Unified does not use one. Vision and audio are baked into the model architecture itself. The single `gemma-4-12b-it-UD-Q4_K_XL.gguf` file (7.37 GB) is all you need.

---

## Benchmark Results

### Text Benchmarks (Source: HuggingFace Leaderboard)

| Benchmark | Gemma 4 12B Unified |
|-----------|-------------------|
| MMLU Pro | 77.2% |
| AIME 2026 no tools | 77.5% |
| LiveCodeBench v6 | 72.0% |
| Codeforces ELO | 1659 |
| GPQA Diamond | 78.8% |
| Tau2 | 69.0% |
| BigBench Extra Hard | 53.0% |
| MMMLU | 83.4% |

### Vision

| Benchmark | Gemma 4 12B Unified |
|-----------|-------------------|
| MMMU Pro | 69.1% |
| OmniDocBench 1.5 (lower=better) | 0.164 |
| MATH-Vision | 79.7% |

### Audio

| Benchmark | Gemma 4 12B Unified |
|-----------|-------------------|
| CoVoST | 38.5% |
| FLEURS (lower=better) | 0.069 |

---

## Docker Image

The DGX Spark uses `ghcr.io/ggml-org/llama.cpp:server-cuda13` — the official multi-arch image with ARM64 support for the NVIDIA Grace Blackwell Superchip.

### Available Tags

Hosted on GitHub Container Registry: [ggml-org/llama.cpp versions](https://github.com/ggml-org/llama.cpp/pkgs/container/llama.cpp/versions)

---

## License & Credits

- **llama.cpp**: [ggml-org/llama.cpp](https://github.com/ggml-org/llama.cpp)
- **Gemma 4 12B by Google DeepMind**: [Google DeepMind](https://ai.google.dev/gemma) — Apache 2.0
- **Unsloth GGUF Quantization**: [unsloth/gemma-4-12b-it-GGUF-it](https://huggingface.co/unsloth/gemma-4-12b-it-GGUF-it) — UD-Q4_K_XL (Dynamic 2.0 4-bit)
