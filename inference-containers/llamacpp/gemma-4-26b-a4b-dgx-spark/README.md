# Gemma 4 26B A4B MoE Server on DGX Spark — GB10 Grace Blackwell (llama.cpp)

> Mixture-of-Experts architecture • 25.2B total / 3.8B active params • Text, Image • NVIDIA Grace Blackwell Superchip • ARM64 Optimized

**Target Hardware:** Acer Veriton GN100 / DGX Spark (NVIDIA GB10, 128GB Unified Memory LPDDR5X, ARM64/aarch64)
**Variant:** Unsloth (`unsloth/gemma-4-26b-A4B-moE-it-GGUF:UD-Q4_K_XL`)
**Text Capacity:** 256K tokens (full context window) • Sliding window: 1024
**Vocabulary:** 262K tokens • Architecture: MoE, 128 experts per layer, 25.2B total params / 3.8B active params
**Server Port:** `8000`

---

## Quick Start

```bash
# 1. Pull the multi-arch image (ARM64)
./00_a_pull_image.sh

# 2. Pre-download model weights (Unsloth UD-Q4_K_XL, ~17 GB + mmproj ~550 MB)
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
llamacpp/gemma-4-26b-a4b-dgx-spark/
├── docker-compose.yml              # Main compose config (UD-Q4_K_XL)
├── .env.example                    # Environment variables template
├── 00_a_pull_image.sh              # Pull ggml-org/llama.cpp:server-cuda13 (ARM64)
├── 00_b_create_conda_env.sh         # Create conda environment for tools
├── 00_c_install_packages.sh         # Install test client deps (openai)
├── 00_d_pre_download_model.sh       # Pre-download Unsloth GGUF (~17 GB + mmproj)
├── 00_e_force_download_model.sh     # Force re-download (bypasses local cache)
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
| **Model** | `-hf unsloth/gemma-4-26b-A4B-moE-it-GGUF:UD-Q4_K_XL` | Unsloth Dynamic 2.0 4-bit, ~17 GB |
| **Vision Projector** | `--mmproj <mmproj-BF16.gguf>` | Separate vision projector (~550 MB) |
| **Port** | `8000:8000` | Host 8000 → Container 8000 |
| **Platform** | `linux/arm64` | Native ARMv9 Grace CPU |
| **GPU Layers** | `999` | Full GPU offload (all layers to unified memory) |
| **Context Size** | `262144` (256K) | Full context window capacity |
| **Parallel Slots** | `--parallel 15` | 15 concurrent slots — MoE enables higher concurrency |
| **KV Cache** | `q8_0` (K & V) | High precision cache |
| **Batch Size** | `512` | Optimized for LPDDR5X bandwidth (~300 GB/s) |
| **Flash Attention** | `--flash-attn on` | Native Blackwell acceleration |
| **Shared Memory** | `shm_size: "80g"` | Larger shared memory for model size + KV cache |
| **Chat Template** | `--jinja` | Required for Gemma 4 thinking tokens (`<|think|>`) and multimodal formatting |

### Unified Memory Architecture

The GB10 Grace Blackwell Superchip uses 128GB of unified LPDDR5X memory (~300 GB/s bandwidth) shared between the Grace CPU and Blackwell GPU. There is no discrete VRAM copy phase over PCIe — the entire memory pool is transparently accessible.

The model weights (~17 GB at Q4_K_XL) plus the separate vision projector (~550 MB) and KV cache for the full 256K context window fit within the 128GB unified pool. With `shm_size: "80g"`, the container has dedicated shared memory for high-speed KV cache paging while leaving the majority of RAM available for the CPU-side model loading, context processing, and KV cache expansion.

### Why a MoE 26B Model on DGX Spark

Unlike the Dense 12B model in the sibling container, the Gemma 4 26B A4B (All-4-Big) uses a Mixture-of-Experts architecture: **25.2B total parameters, but only 3.8B active per forward pass**. This means inference computes only ~1/7th of the model's parameters each step, making it faster than a dense model of comparable total size.

- **Per-step weight read:** ~3 GB (3.8B active params × 4 bits/8 bits/param)
- **Theoretical max at 300 GB/s:** ~100 tok/s
- **Actual expectation:** 35-55 tok/s (MoE routing overhead + KV cache management at large context)

The MoE architecture enables higher parallel concurrency (15 slots vs. 10 for the Dense 12B) because each active request consumes less memory for computations, allowing more slots to share the GPU's unified memory.

For most use cases where total quality matters less than throughput on the DGX Spark, the Dense 12B model may actually deliver faster per-request latency. But when you need the reasoning depth of a 26B-class model while retaining the throughput benefits of a small model, the A4B MoE is the right choice.

---

## Server Command Breakdown

```bash
# Core model loading
-hf unsloth/gemma-4-26b-A4B-moE-it-GGUF:UD-Q4_K_XL
--host 0.0.0.0
--port 8000

# GPU offload (entire model to unified memory pool)
--n-gpu-layers 999

# Vision — Requires separate mmproj file (unlike encoder-free 12B)
--mmproj /path/to/mmproj-BF16.gguf

# Attention & memory
--flash-attn on
--cache-type-k q8_0
--cache-type-v q8_0
--ctx-size 262144

# 15 concurrent slots — MoE routing lowers per-slot active compute
# Each slot gets ctx_size / np tokens (~17.5K per slot at 256K context)
--parallel 15

# Batch optimization (LPDDR5X bandwidth tuned)
--batch-size 512
--ubatch-size 512

# Sampling parameters (Gemma 4 standard)
--temp 1.0
--top-p 0.95
--top-k 64

# No MTP speculative decoding — Gemma 4 26B A4B has no MTP heads (despite being MoE)
--mtp-speculative 0

# No presence-penalty — keep at 1.0 per Unsloth recommendation
```

---

## Mixture-of-Experts Architecture — A4B (All-4-Big)

### How It Works

The Gemma 4 26B A4B is a Mixture-of-Experts (MoE) model with a unique architecture:

- **128 experts per layer** — but only **8 are active** per token, plus **1 shared expert** used by all tokens
- **25.2B total parameters** across all experts and layers
- **3.8B active parameters** per forward pass (roughly 1/7th of total)

The router network in each layer selects the top-8 experts for each token. This means the model has the capacity of a 25B dense model but the compute cost of a much smaller model during inference.

### A4B: The "All-4-Big" Design

The "A4B" naming (All-4-Big) refers to how the experts are organized: all experts are equally "big" (no small/large expert split), and the architecture was specifically designed to maximize capacity without increasing active compute. This is a refinement over early MoE designs that split experts into "small" and "large" categories.

### MoE on DGX Spark

The DGX Spark's 128GB unified memory provides ample room for the full 128-expert parameter footprint (25.2B at Q4 ≈ 12.6 GB, plus router weights ≈ 4.4 GB). The key advantage is that while all experts are resident in memory, only the 8 active ones per layer need computation per token — keeping memory bandwidth as the primary bottleneck, not compute.

---

## Multimodal Capabilities — Vision with Separate mmproj

### Key Difference from the 12B Dense Model

Unlike the Gemma 4 12B Unified model which uses an encoder-free architecture (no `--mmproj` needed), the **Gemma 4 26B A4B MoE requires a separate vision projector file** (`mmproj-BF16.gguf`):

| Aspect | Gemma 4 12B (Encoder-Free) | Gemma 4 26B A4B (Separate mmproj) |
|--------|--------------------------|----------------------------------|
| **Files** | Single GGUF | Model GGUF + `mmproj-BF16.gguf` (2 files) |
| **Vision** | Integrated into transformer | Separate vision projector |
| **mmproj flag** | Not needed | Required (`--mmproj`) |
| **Total size** | 7.37 GB | ~17 GB + ~550 MB mmproj |
| **Audio support** | Yes | No (only E2B/E4B variants have audio) |

This architecture uses a separate vision encoder/transformer that projects image features into the language model's embedding space, rather than integrating vision natively into the transformer layers.

### No Audio Support on This Variant

The Gemma 4 26B model family includes variants with audio capability (E2B, E4B). **The A4B variant does not support audio** — it is text and image only. For audio support, use the E2B or E4B MoE variant instead (see `gemma-4-e2b-dgx-spark` or `gemma-4-e4b-dgx-spark`).

### Loading the mmproj

The vision projector (`mmproj-BF16.gguf`) is downloaded alongside the model weights during the pre-download step. It should be mounted or copied into the container and referenced with the `--mmproj` flag in the server command.

The projector is in BF16 format to preserve vision feature quality. Quantizing the mmproj introduces noticeable degradation in image understanding accuracy.

---

## Thinking Mode

Gemma 4 26B A4B MoE supports structured reasoning via the `<|think|>` token. This is not a separate mode — it's triggered by including the token in the system prompt.

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

When thinking is disabled (no `<|think|>` in system prompt), the model may emit empty thought blocks:

```
<|channel>thought
<channel|>
[final answer]
```

### Server Requirement: `--jinja`

While thinking mode itself is triggered via the prompt, the llama.cpp server **must** be started with the `--jinja` flag. This ensures the correct Gemma 4 Jinja chat template is applied, which properly handles `<|think|>` and `<|channel>` control tokens, multimodal inputs, and multi-turn conversation structure. Without it, raw control tokens may leak into the final output.

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
    "model": "gemma-4-26b-a4b",
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
    "model": "gemma-4-26b-a4b",
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

**Vision — Send an image (requires --mmproj):**

```bash
curl -s http://localhost:8000/v1/chat/completions \
  -H "Content-Type: application/json" \
  -d '{
    "model": "gemma-4-26b-a4b",
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

On first start, the GGUF model and mmproj will download from Hugging Face to `~/.cache/huggingface/`. This is expected and may take several minutes depending on your connection. The pre-download script (`00_d_pre_download_model.sh`) speeds up subsequent starts. The total download is approximately 17.5 GB (model ~17 GB + mmproj ~550 MB).

### Shared Memory

This model uses `shm_size: "80g"` to accommodate the larger parameter footprint and KV cache buffer. If you encounter OOM or shared memory issues:

```bash
# Check container shared memory
docker inspect gemma-4-26b-a4b-dgx-spark | grep -i shm

# Check host memory
free -h
```

### Vision Requires --mmproj Flag

A key difference from the 12B Unified model: this model **requires** the `--mmproj` flag for vision. If you start the server without it, text chat will work normally, but any image sent to the server will be rejected. Ensure the `mmproj-BF16.gguf` file is present and the flag is in your server command:

```yaml
command: -hf unsloth/gemma-4-26b-A4B-moE-it-GGUF:UD-Q4_K_XL --mmproj /path/to/mmproj-BF16.gguf ...
```

### No Audio on This Variant

The A4B MoE variant does not support audio. If you need audio capabilities, use the E2B or E4B MoE variant, or the 12B Unified model which has all three modalities (text, image, audio) via the encoder-free architecture.

### No Speculative Decoding (MTP Disabled)

Gemma 4 26B A4B has no Multi-Token Prediction (MTP) heads, even though it is an MoE model. The MTP architecture was only implemented on select models in the Gemma 4 family. This is explicitly disabled:

```
--mtp-speculative 0
```

Performance is not significantly impacted — MoE routing overhead and memory bandwidth remain the primary throughput factors, and speculative decoding would need a very different target model to be effective.

### Generation Quality with top-k = 64

This setup uses `--top-k 64` following Google/Unsloth Gemma recommendations. Gemma 4's training and vocabulary (262K tokens) benefit from a wider sampling range than smaller models:

- **top-k 64**: Standard — matches Google's reference implementations
- **top-k 20**: More conservative — may feel more deterministic but less creative
- **top-p 0.95** is used alongside top-k (dual-sampling), providing additional control

---

## Benchmark Results

### Text Benchmarks (Source: HuggingFace Leaderboard)

| Benchmark | Gemma 4 26B A4B MoE |
|-----------|-------------------|
| MMLU Pro | 81.0% |
| AIME 2026 no tools | 82.4% |
| LiveCodeBench v6 | 77.3% |
| Codeforces ELO | 1810 |
| GPQA Diamond | 82.1% |
| Tau2 | 76.0% |
| BigBench Extra Hard | 58.2% |
| MMMLU | 87.5% |

### Vision

| Benchmark | Gemma 4 26B A4B MoE |
|-----------|-------------------|
| MMMU Pro | 73.5% |
| OmniDocBench 1.5 (lower=better) | 0.141 |
| MATH-Vision | 84.3% |

### Comparison: MoE 26B A4B vs. Dense 12B

| Metric | 26B A4B MoE | 12B Dense |
|--------|-------------|-----------|
| **Total Params** | 25.2B | 12B |
| **Active Params** | 3.8B | 12B |
| **Model Size (Q4)** | ~17 GB | ~7.37 GB |
| **Parallel Slots** | 15 | 10 |
| **MMLU Pro** | 81.0% | 77.2% |
| **Vision (MMMU Pro)** | 73.5% | 69.1% |
| **Audio Support** | No | Yes |

The MoE 26B delivers notably higher bench scores with only the same active-param compute footprint as the 12B dense model — that's the MoE advantage. The tradeoff is larger memory footprint and the need for a separate `mmproj` file rather than the encoder-free convenience of the 12B.

---

## Docker Image

The DGX Spark uses `ghcr.io/ggml-org/llama.cpp:server-cuda13` — the official multi-arch image with ARM64 support for the NVIDIA Grace Blackwell Superchip.

### Available Tags

Hosted on GitHub Container Registry: [ggml-org/llama.cpp versions](https://github.com/ggml-org/llama.cpp/pkgs/container/llama.cpp/versions)

---

## License & Credits

- **llama.cpp**: [ggml-org/llama.cpp](https://github.com/ggml-org/llama.cpp)
- **Gemma 4 26B A4B MoE by Google DeepMind**: [Google DeepMind](https://ai.google.dev/gemma) — Apache 2.0
- **Unsloth GGUF Quantization**: [unsloth/gemma-4-26b-A4B-moE-it-GGUF](https://huggingface.co/unsloth/gemma-4-26b-A4B-moE-it-GGUF) — UD-Q4_K_XL (Dynamic 2.0 4-bit)

---

## References

- [Unsloth Gemma 4 GGUF Models](https://huggingface.co/unsloth/gemma-4-12b-it-GGUF)
- [Unsloth Dynamic 2.0 GGUFs Documentation](https://unsloth.ai/docs/basics/unsloth-dynamic-2.0-ggufs)
- [Official Gemma 4 Documentation by Google](https://ai.google.dev/gemma/docs/core)
