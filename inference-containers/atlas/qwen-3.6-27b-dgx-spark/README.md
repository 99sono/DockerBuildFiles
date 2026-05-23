# Qwen3.6-27B-FP8 (Dense) on Atlas (DGX Spark / GB10)

Atlas inference engine running Qwen3.6-27B dense FP8 with MTP speculative decoding (K=2 draft head).

**Source Recipe:** [qwen3.6-27b-dense-fp8-mtp-atlas.yaml](https://github.com/Avarok-Cybersecurity/atlas-recipes/blob/main/recipes/qwen3.6/qwen3.6-27b-dense-fp8-mtp-atlas.yaml) · [Atlas GitHub](https://github.com/Avarok-Cybersecurity/atlas)

## Quick Start

```bash
# 1. Set up auth token
cp .env.example .env
# Edit .env — replace dummy-key with a strong token:
#   openssl rand -hex 24

# 2. Pull image
./00_a_pull_image.sh

# 3. Start the server
./01_up.sh

# 4. Monitor startup (first load: model download + initialization)
./05_a_docker_logs.sh
```

## Authentication

Atlas uses `--auth-token` for single-token auth. The token comes from `ATLAS_API_KEY` in `.env`:

```bash
curl http://localhost:8000/v1/chat/completions \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"model":"Qwen3.6-27B-FP8","messages":[{"role":"user","content":"Hello!"}]}'
```

The `.env` file is gitignored. Use `.env.example` as template: `cp .env.example .env`.

> For production with multiple tokens, switch to `--auth-tokens-file` (see Atlas quickstart).

## Test with Python SDK

```bash
# Set up conda env (one-time)
./00_b_create_conda_env.sh
./00_c_install_packages.sh

# Run test
conda activate testAtlas27BFp8
python 04_c_test_python_client.py
```

## GPU Memory Tuning

| Setting | Value | Notes |
|---------|-------|-------|
| `--gpu-memory-utilization` | `0.88` | 88% of GB10 (~119GB), recipe default |
| `--kv-cache-dtype` | **`bf16`** | **MANDATORY** for dense models — FP8/NVFP4 KV breaks dense attention (timeouts + CUDA graph thrash) |

## Pre-download Model (Optional)

```bash
./00_d_pre_download_model.sh
```

Downloads `Qwen/Qwen3.6-27B-FP8` into `~/.cache/huggingface` for faster first startup.

## First-Request Cold Start

The first `/v1/chat/completions` request will pause 5-30 seconds for CUDA graph capture and kernel autotuning. This is normal — don't Ctrl-C. Subsequent requests are 3-5× faster.

To warm up at startup, add `--warmup-prompt /path/to/prompt.txt` to the command in docker-compose.yml.

## Model Specs

| Property | Value |
|----------|-------|
| Model | Qwen/Qwen3.6-27B-FP8 |
| Total params | 27B (dense) |
| Quantization | Native FP8 E4M3 |
| KV Cache dtype | BF16 (hard requirement for dense attention) |
| Max context | ~1M tokens native |
| Active max-seq-len | 60,000 (capped to fit concurrency=10 in KV pool on single GB10) |
| MTP | Yes (K=2 speculative decoding with FP8 draft head) |

## Context Length Trade-off

The recipe caps `--max-seq-len` at 60,000 because the full spark-arena-v2 concurrency=10 sweep fits in the KV pool on a single GB10 at that length. Cells at depth > max_model_len will be skipped. For full long-context support (up to ~1M), use `--tp 2 / EP=2` across multiple nodes.

## Critical: BF16 KV Cache Warning

Unlike MoE models where FP8 or NVFP4 KV cache may work, **dense attention models require BF16 precision in the KV cache**. The Atlas recipe explicitly states:

> "KV stays BF16 (FP8/NVFP4 KV breaks dense attention — request timeouts + CUDA graph thrash)"

This is a hard requirement. Do not change `--kv-cache-dtype` from `bf16`.

## Speculative Decoding (MTP K=2)

This model is large enough that without MTP, throughput will be terrible on single-GPU setups. The upstream-bundled MTP draft head (`mtp.safetensors`) uses FP8 e4m3 linear + BF16 norms. With 2 draft tokens and even partial acceptance rates, the verify step amortizes to significant speedup compared to standard autoregressive decoding.

## File Structure

```
├── docker-compose.yml          # Atlas service with auth + GPU tuning (BF16 KV cache!)
├── .env.example                # Token template (committed, copy to .env)
├── 00_env.sh.example           # Shell env loader template
├── 00_a_pull_image.sh          # Pull latest image
├── 00_b_create_conda_env.sh    # Create test conda environment
├── 00_c_install_packages.sh    # Install Python dependencies
├── 00_d_pre_download_model.sh  # Pre-download model weights
├── 01_up.sh                    # Start container
├── 02_down.sh                  # Stop container
├── 03_enter_container.sh       # Bash into container
├── 04_a_list_models.sh         # List available models via curl
├── 04_b_chat_completion.sh     # Test chat completion via curl
├── 04_c_test_python_client.py  # OpenAI client test script
├── 05_a_docker_logs.sh         # Stream container logs (live tail)
├── 05_b_log_to_metadata_folder.sh  # Dump logs to metadata/ timestamps
└── test/
    └── test_file_01_prompt.md  # Default prompt
```

## Notes

- **Image:** `avarok/atlas-gb10:latest` — GB10/SM121 only (not compatible with RTX 5090)
- **Network:** Uses `development-network` external network, port `8000`
- **Auth token:** `ATLAS_API_KEY` in `.env` (gitignored)
- **Cache:** HuggingFace weights persisted at `~/.cache/huggingface`
- **shm_size / ipc:** Set to `32g` / `host` for GPU memory sharing
