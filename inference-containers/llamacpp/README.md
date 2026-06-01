# llama.cpp HTTP Server Reference

llama.cpp's built-in HTTP server — a lightweight OpenAI-compatible API for LLM inference.

- **Source:** [ggml-org/llama.cpp/tools/server](https://github.com/ggml-org/llama.cpp/tree/master/tools/server)
- **Full parameter reference:** [README.md](https://github.com/ggml-org/llama.cpp/blob/master/tools/server/README.md)

---

## Docker Images

| Image | Architecture | Notes |
|-------|-------------|-------|
| `ghcr.io/ggml-org/llama.cpp:server-cuda13` | AMD64 / ARM64 (multi-arch) | Official multi-arch image with MTP support |
| `havenoammo/llama:cuda13-server` | AMD64 | Temporary — includes MTP patch before official merge |

---

## Commonly Used Parameters

### Model Loading

| Parameter | Description | Default |
|-----------|-------------|---------|
| `-m, --model FNAME` | GGUF model path | (required) |
| `-hf, --hf-repo USER/MODEL[:QUANT]` | Load from HuggingFace hub | — |
| `--n-gpu-layers N` | Layers to offload to GPU (use `999` for all) | auto |
| `--ctx-size N` | Context window size in tokens | 0 = model default |

### Memory

| Parameter | Description | Default |
|-----------|-------------|---------|
| `--mlock` | Keep model weights in RAM (prevent swapping) | disabled |
| `--mmap` / `--no-mmap` | Memory-map the model file | enabled |
| `--cache-type-k TYPE` | KV cache K data type (`f32, f16, bf16, q8_0, q4_0`) | f16 |
| `--cache-type-v TYPE` | KV cache V data type (`f32, f16, bf16, q8_0, q4_0`) | f16 |

### Threading & Performance

| Parameter | Description | Default |
|-----------|-------------|---------|
| `-t, --threads N` | CPU threads for generation | -1 = auto |
| `-tb, --threads-batch N` | CPU threads for batch operations | same as `--threads` |
| `--flash-attn [on\|off\|auto]` | Enable Flash Attention | auto |
| `--batch-size N` | Logical batch size | 2048 |
| `-ub, --ubatch-size N` | Physical batch size | 512 |

### Server & API

| Parameter | Description | Default |
|-----------|-------------|---------|
| `--host HOST` | Bind address (use `0.0.0.0` for Docker) | 127.0.0.1 |
| `--port PORT` | Listen port | 8080 |
| `-np, --parallel N` | Server slots (concurrent requests) | -1 = auto |
| `--alias STRING` | Model alias exposed via `/v1/models` API | — |

### Speculative Decoding

| Parameter | Description | Default |
|-----------|-------------|---------|
| `--spec-type none,draft-simple,draft-mtp,...` | Enable speculative decoding types | none |
| `--spec-draft-n-max N` | Max tokens to draft ahead | 3 |
| `--spec-draft-p-min P` | Min confidence for draft proposals | 0.0 = disabled |
| `--spec-draft-hf USER/MODEL[:QUANT]` | Draft model from HuggingFace | — |

### Sampling & Generation

| Parameter | Description | Default |
|-----------|-------------|---------|
| `-s, --seed N` | RNG seed (-1 = random) | -1 |
| `--temp, --temperature N` | Sampling temperature | 0.80 |
| `--top-k N` | Top-k sampling (0 = disabled) | 40 |
| `--top-p N` | Top-p / nucleus sampling (1.0 = disabled) | 0.95 |
| `--min-p N` | Min-p sampling (0.0 = disabled) | 0.05 |
| `--repeat-penalty N` | Penalize repeated token sequences | 1.0 |
| `--presence-penalty N` | Penalize presence of tokens in context | 0.0 |
| `--frequency-penalty N` | Penalize frequency of tokens in context | 0.0 |

### Chat & Inference Control

| Parameter | Description | Default |
|-----------|-------------|---------|
| `-n, --predict N` | Tokens to generate (-1 = infinite) | -1 |
| `--reasoning-format FORMAT` | Thought tag handling (`none, deepseek, deepseek-legacy`) | auto |
| `--jinja, --no-jinja` | Use Jinja template engine for chat | enabled |
| `--chat-template TEMPLATE` | Built-in or custom Jinja template | model default |

---

## Quick Start

```bash
# Pull image
docker pull ghcr.io/ggml-org/llama.cpp:server-cuda13

# Run with a local GGUF
docker run -d -p 8000:8000 --name llama-server \
  --gpus all \
  ghcr.io/ggml-org/llama.cpp:server-cuda13 \
  /bin/sh -c 'llama-server \
    -m /models/model.gguf \
    --host 0.0.0.0 --port 8000 \
    --n-gpu-layers 999 --threads 12 --ctx-size 8192'

# Test
curl http://localhost:8000/v1/models | jq .
curl http://localhost:8000/v1/chat/completions \
  -H "Content-Type: application/json" \
  -d '{"model":"model","messages":[{"role":"user","content":"Hello!"}], "max_tokens":64}' | jq .
```

---

## Parameter Intuition

### `--threads` vs `--threads-batch`

- **`--threads`** (generation): CPU threads for single-token generation. Mostly GPU-bound, diminishing returns past ~10.
- **`--threads-batch`** (batch/verification): CPU threads for batch operations like MTP verification and prompt processing. Memory-bound — SMT cores excel here. Can scale higher than `--threads`.

### `--ctx-size`

Larger context = more KV cache memory. For a 27B model at Q4, each 1K tokens uses roughly 50-60MB of KV cache. Set based on your expected max prompt + generation length.

### Speculative Decoding

Shorter chains (`--spec-draft-n-max`) with higher confidence (`--spec-draft-p-min`) give steadier performance. Longer chains (`n_max = 3+`) have higher peak speed but more variance — if a draft fails mid-chain, you fall back to baseline generation anyway.

### `--cache-type-k/v`

Higher precision KV cache (q8_0) reduces logic errors in long reasoning chains but uses more memory. Drop to q4_k only if VRAM-constrained.

---

## Monitoring Server Stats

```bash
# List models via API
curl http://localhost:8000/v1/models | jq .

# Check slot/queue status
curl http://localhost:8000/server-slots | jq .
curl http://localhost:8000/server-queues | jq .
```
