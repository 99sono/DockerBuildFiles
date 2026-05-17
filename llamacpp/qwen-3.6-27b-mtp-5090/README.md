# Qwen3.6-27B MTP Server on RTX 5090 (llama.cpp)

> Multi-Token Prediction speculative decoding • Blackwell SM 12.0 Optimized • Microwave-ready Docker

**Target Hardware:** RTX 5090 (32 GB GDDR7, SM 12.0, x86_64)
**Model:** `unsloth/Qwen3.6-27B-MTP-GGUF:UD-Q4_K_XL`
**Speculative Decoding:** MTP (Multi-Token Prediction) with `--spec-draft-n-max 2`
**Server Port:** `8000`

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

# 4. Test the server (Python script - requires `pip install openai`)
python 04_test_curl.py

# 5. Monitor logs
./05_docker_logs.sh
```

---

## Project Structure

```
llamacpp/qwen3.6-27b-mtp-5090/
├── 00_a_pull_image.sh          # Pull havenoammo/llama:cuda13-server
├── 00_b_create_conda_env.sh    # Create conda env for host tools
├── 00_c_install_packages.sh    # Install huggingface-hub, jq, curl
├── docker-compose.yml           # llama-server MTP spec config
├── 01_a_up_server.sh            # Start server (docker compose up -d)
├── 02_a_down_server.sh          # Stop server (docker compose down)
├── 03_enter_container.sh        # Enter container for debugging
├── 04_test_curl.py              # Test API call on port 8000 (Python)
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
| **Image** | `havenoammo/llama:cuda13-server` | Pre-built CUDA 12.8+ with MTP patch for Blackwell MMQ kernels |
| **Model** | `-hf unsloth/Qwen3.6-27B-MTP-GGUF:UD-Q4_K_XL` | Load from HuggingFace hub |
| **Port** | `8000:8000` | Host 8000 → Container 8000 (consistent across inference engines for reverse proxy) |
| **GPU Layers** | `999` | Full GPU offload (all layers on the 5090) |
| **Context Size** | `131072` (128K) | Max context window |
| **KV Cache** | `q8_0` (K & V) | High precision cache to avoid logic errors in reasoning |
| **Speculative** | `draft-mtp` with `n-max 2`, `p-min 0.8` | Multi-Token Prediction, tuned for deep context stability |
| **Threading** | `threads=12`, `threads-batch=24` | Split generation from batch/MTP verification |
| **Flash Attention** | `on` | Native SM 120 acceleration |

### Centralized Cache Strategy

The `-hf` flag in docker-compose.yml loads the GGUF model directly from the HuggingFace hub into the central `~/.cache/huggingface/` directory. No local model files or download scripts needed.

---

## Why havenoammo Image?

As of 2026-05-17, MTP speculative decoding support is **not yet merged** into official llama.cpp. The feature lives in PR [#22673](https://github.com/ggml-org/llama.cpp/pull/22673), expected to merge within ~24 hours.

### Official Images (pre-MTP)
```
ghcr.io/ggml-org/llama.cpp:server-cuda13
```
Available at [GitHub Container Registry](https://github.com/ggml-org/llama.cpp/pkgs/container/llama.cpp/versions?filters%5Bversion_type%5D=tagged), but lack `draft-mtp` support. Attempting `--spec-type draft-mtp` produces:
```
error while handling argument "--spec-type": unknown speculative type: mtp
```

### havenoammo Image (with MTP)
```
havenoammo/llama:cuda13-server
```
Includes the MTP patch from PR #22673 plus CUDA 12.8 libraries for Blackwell SM 120 native support (MMQ kernels, FP4).

### Migration Plan
Once PR #22673 merges and a tagged release is cut on the official repo, switch back:
```yaml
# Replace in docker-compose.yml:
image: ghcr.io/ggml-org/llama.cpp:server-cuda13  # (once MTP is available)
```

---

## Understanding MTP (Multi-Token Prediction)

### How It Works

Qwen 3.6 models have built-in "draft heads" that predict multiple tokens ahead simultaneously, **without needing a separate small draft model**. The MTP heads share weights with the main model and are packaged in the same GGUF file.

Key difference from traditional speculative decoding:
- **Traditional:** A small draft model (e.g., Qwen3.5 0.8B) speculatively generates N tokens, then the main model verifies each one sequentially. A single rejection breaks the chain — it's a cascade.
- **MTP:** The draft heads predict all tokens in parallel. The main model verifies them in a **single forward pass** — not a cascade. If token 2 is wrong, tokens 1 and beyond are discarded, but verification cost is flat regardless of chain length.

### Chain Success Math

The probability that the entire drafted chain gets accepted is the per-token acceptance rate raised to the power of `--spec-draft-n-max`:

```
P(full chain accepted) = P(per token)^n_max
```

At ~52% per-token acceptance (typical at deep context >15k tokens):
- **n-max = 3:** 0.52³ ≈ **14%** full-chain success → 86% of the time you fall back to near-baseline speed
- **n-max = 2:** 0.52² ≈ **27%** full-chain success → doubles the chance of speculative gain

This is why we use `--spec-draft-n-max 2` — it's a much better statistical gamble for deep-thinking/reasoning workloads with long context.

### Benchmarks (from PR #22673, DGX Spark)

Baseline without MTP: **~7 tokens/s**

| Config | Acceptance Rate | Avg tok/s | Wall Time (9 tasks) |
|--------|---------------|-----------|---------------------|
| No MTP | N/A | 7.2 | 201s |
| MTP, n-max = 3 | **72.2%** | ~17.5 | 84s |
| MTP, n-max = 2 | **82.6%** | ~16.3 | 90s |
| Draft model (Qwen3.5 0.8B), n-max=16 | 67.7% | varies (12-48) | 81s |

At n-max=3 you get slightly higher peak speed when acceptance is good, but more variance. At n-max=2 you get steadier performance with higher aggregate acceptance. For our RTX 5090 setup with Q4_K_XL quant and long reasoning contexts, **n-max=2 is the stable choice**.

---

## Parameter Intuition

### Threading: `--threads` vs `--threads-batch`

```
n_threads = 16 (n_threads_batch = 24) / 32
              ^^^^^^^^    ^^^^^^^^^^^     ^^^
              gen threads  batch threads   total CPU threads available
```

- **`--threads` (generation):** Controls CPU parallelism for single-token generation. Generation is mostly GPU-bound, so more threads gives diminishing returns past ~10. We use **12** — lean, better CPU cache behavior on the Ryzen 9 5950X.
- **`--threads-batch` (batch/verification):** Controls parallelism for batch operations: MTP draft verification, prompt preprocessing, matrix math. This is memory-bound work where SMT (hyperthreading) cores excel — fetching vectors, parallel dot products across KV cache. We use **24** (12 physical + 12 SMT), leaving headroom for OS and HTTP server threads.

Old setup ran both at 16. By splitting them, MTP verification bursts can scale up while single-token generation stays lean. Note: this is a marginal optimization — the heavy lifting happens on the GPU. The real speed win comes from `--spec-draft-n-max`.

### Speculative Decoding: `--spec-draft-n-max` and `--spec-draft-p-min`

- **`--spec-draft-n-max`** (chain length): How many tokens MTP predicts ahead. Shorter chain = higher full-chain acceptance, especially at deep context (>15k tokens). We use **2**.
  - At short context (<8k), per-token acceptance is ~79%: 0.79²=62% vs 0.79³=49% — both good, difference is small
  - At deep context (>15k), per-token drops to ~52%: 0.52²=27% vs 0.52³=14% — **doubling matters**

- **`--spec-draft-p-min`** (confidence threshold): Minimum confidence for draft tokens to be proposed. Too low = garbage proposals that waste verification cycles. Too high = missed speculative opportunities, falling back to baseline generation. We use **0.8** — conservative, protects reasoning quality.

### KV Cache: `--cache-type-k` and `--cache-type-v`

Controls quantization of the KV cache. Higher precision = better quality (fewer logic errors in reasoning) but more VRAM.
- **q8_0** (our choice): Sweet spot — high precision without excessive VRAM cost. On a 32GB 5090 with a Q4 model, we have headroom.
- **Don't drop to q4_k** unless you're VRAM-constrained — it introduces enough imprecision to cause "doom loop" logic errors in long reasoning chains.

### Context Size: `--ctx-size`

We use 131072 (128K). The model was trained on 262144 (256K) context, so you'll see a warning:
```
n_ctx_seq (131072) < n_ctx_train (262144) -- the full capacity of the model will not be utilized
```

This is fine for most workloads. Increase to 262144 if your tasks regularly exceed 128K tokens, but expect higher VRAM usage and slower prompt eval as context grows past the cache size.

### Sampling Parameters

| Parameter | Value | Purpose |
|---|---|---|
| `--temp` | 1.0 | Standard temperature for balanced creativity |
| `--top-p` | 0.95 | Nucleus sampling cutoff — filters bottom 5% of token distribution |
| `--top-k` | 20 | Limits candidate pool to top 20 tokens per step |
| `--presence-penalty` | 1.5 | Discourages repetition, keeps model focused during long code generation |

---

## Advanced: MTP + n-gram Speculative Decoding (Experimental)

You can combine MTP with n-gram speculative decoding for potentially higher speedup on repetitive/pattern-heavy tasks (like code generation):

```bash
llama-server -hf unsloth/Qwen3.6-27B-MTP-GGUF:UD-Q4_K_XL \
  --spec-type draft-mtp --spec-draft-n-max 2 \
  --spec-type ngram-mod \
    --spec-ngram-mod-n-match 24 \
    --spec-ngram-mod-n-min 48 \
    --spec-ngram-mod-n-max 64
```

Or use the shorthand default preset:
```bash
llama-server -hf unsloth/Qwen3.6-27B-MTP-GGUF:UD-Q4_K_XL \
  --spec-default --spec-type draft-mtp --spec-draft-n-max 2
```

> **Warning:** This is experimental and primarily beneficial on non-CUDA systems where MTP alone may not provide enough speedup. On the RTX 5090, MTP alone already achieves ~90+ tok/s generation. The n-gram layer adds CPU overhead that may not be worth it when you have a fast GPU. Test carefully with your workload.

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
curl -s http://localhost:8000/v1/models | jq .
```

**Send a completion request:**
```bash
curl -s http://localhost:8000/v1/chat/completions \
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
docker logs qwen-3.6-27b-mtp-5090 | grep -i "draft.*accept\|mtp"

# Check VRAM usage
nvidia-smi
```

### Reading the Log Output

Key lines to watch after a task completes:

```
eval time =    5959.10 ms /   571 tokens (   10.44 ms per token,    95.82 tokens per second)
draft acceptance rate = 0.78824 (  402 accepted /   510 generated)
statistics draft-mtp: #calls(b,g,a) = 2 170 181, #gen drafts = 181, #acc drafts = 166, ...
```

### MTP Acceptance Rate Thresholds

- **>75%**: Optimal sweet spot — full speculative speedup realized (~90+ t/s on RTX 5090)
- **50-75%**: Degraded performance at deep context — expected behavior. If using n-max=3, consider dropping to 2
- **<50%**: MTP barely helping — speculative overhead may be exceeding gains. Check that `--spec-type draft-mtp` is active and the GGUF has MTP heads

### Expected Performance on RTX 5090

| Context Depth | Prompt Eval | Generation (t/s) | Acceptance Rate |
|---|---|---|---|
| Short (<8K tokens) | ~1400 tok/s | ~95 t/s | ~79% |
| Deep (>15K tokens) | ~2000+ tok/s (cached context) | ~90 t/s | ~60-80% (improved with n-max=2) |

---

## Troubleshooting

### First Run: Large Download
On first start, the GGUF model will download to `~/.cache/huggingface/`. This is expected and may take several minutes depending on your connection.

### MMQ Kernel Verification
Check logs for Blackwell kernel activation:
```
BLACKWELL_NATIVE_FP4 = 1
USE_GRAPHS = 1
```
If the server falls back to generic cuBLAS, performance will be significantly degraded. Ensure `LD_LIBRARY_PATH=/usr/local/cuda-12.8/lib64` is set.

### WSL2 Memory
If you see micro-stutters, verify WSL2 memory allocation:
```bash
# Check container shared memory
docker inspect qwen-3.6-27b-mtp-5090 | grep -i shm
```

### Vision Model Warning
You may see this warning (harmless if you're not using vision):
```
Qwen-VL models require at minimum 1024 image tokens to function correctly on grounding tasks
```
Add `--no-mmproj` to the command if you don't need vision support — it frees up VRAM.

### Context Capacity Warning
```
n_ctx_seq (131072) < n_ctx_train (262144) -- the full capacity of the model will not be utilized
```
This is expected. The model was trained on 256K context; we're using 128K. Fine for most workloads.

---

## Comparison: vLLM vs llama.cpp

| Aspect | vLLM (NVFP4) | llama.cpp (GGUF + MTP) |
|--------|-------------|------------------------|
| **Throughput** | High (steady) | Very high (ramps up with MTP) |
| **VRAM Overhead** | Higher (FP8 KV cache) | Lower (quantized GGUF) |
| **Speculative** | Native MTP support | MTP via `draft-mtp` speculative decoding |
| **Build Required** | Pull image | Pull image (no build) |
| **Best For** | Multi-user, varied prompts | Repetitive/pattern-heavy tasks, deep reasoning |
| **Context Speed** | Consistent across depth | Prompt eval 1400-2200+ tok/s on 5090 |

---

## License & Credits

- **llama.cpp**: [ggml-org/llama.cpp](https://github.com/ggml-org/llama.cpp)
- **MTP Support PR**: [#22673](https://github.com/ggml-org/llama.cpp/pull/22673) by am17an (with contributions from ggerganov)
- **Model**: [unsloth/Qwen3.6-27B-MTP-GGUF](https://huggingface.co/unsloth/Qwen3.6-27B-MTP-GGUF)
- **Docker Image**: [havenoammo/llama](https://hub.docker.com/r/havenoammo/llama) (temporary, pending official MTP merge)
