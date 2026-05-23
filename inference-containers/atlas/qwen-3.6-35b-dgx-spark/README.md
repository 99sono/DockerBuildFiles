# Qwen3.6-35B-A3B NVFP4 on Atlas (DGX Spark / GB10)

Pure Rust inference engine running Qwen3.6-35B MoE with NVFP4 quantization on a single DGX Spark.

**Reference:** [Atlas Spark announcement by Azeez](https://x.com/AtlasInference/status/2055740933057007745?s=20) · [Quickstart Guide](https://github.com/Avarok-Cybersecurity/atlas)

## Quick Start

```bash
# 1. Set up auth token (same pattern as vLLM folders)
cp .env.example .env
# Edit .env — replace dummy-key with a strong token:
#   openssl rand -hex 24

# 2. Pull image
./00_a_pull_image.sh

# 3. Start the server
./01_up.sh

# 4. Monitor startup (first load: 2-5 min + model download)
./05_a_docker_logs.sh
```

## Authentication

Atlas uses `--auth-token` for single-token auth. The token comes from `INFERENCE_API_KEY` in `.env`:

```bash
curl https://localhost/v1/chat/completions \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"model":"qwen3.6-35b","messages":[{"role":"user","content":"Hello!"}]}'
```

The `.env` file is gitignored. Use `.env.example` as template: `cp .env.example .env`.

> For production with multiple tokens, switch to `--auth-tokens-file` (see Atlas quickstart).

## Test with Python SDK

```bash
# Set up conda env (one-time)
./00_b_create_conda_env.sh
./00_c_install_packages.sh

# Run test
conda activate testAtlasQwen
python 04_c_test_python_client.py
```

## GPU Memory Tuning

| Setting | Value | Notes |
|---------|-------|-------|
| `--gpu-memory-utilization` | `0.65` | 65% of GB10 (~78GB), tuned for Spark stability |

Reduced from the default `0.88` to leave headroom for CUDA context, buffer arena, and KV cache on DGX Spark's 119.7 GB. Increase if you need more concurrent sequences or longer context.

## Pre-download Model (Optional)

```bash
./00_d_pre_download_model.sh
```

Downloads `RedHatAI/Qwen3.6-35B-A3B-NVFP4` into `~/.cache/huggingface` for faster first startup.

## First-Request Cold Start

The first `/v1/chat/completions` request will pause 5-30 seconds for CUDA graph capture and kernel autotuning. This is normal — don't Ctrl-C. Subsequent requests are 3-5× faster.

To warm up at startup, add `--warmup-prompt /path/to/prompt.txt` to the command.

## Model Specs

| Property | Value |
|----------|-------|
| Model | RedHatAI/Qwen3.6-35B-A3B-NVFP4 |
| Total params | 35B |
| Active params | ~3B (MoE) |
| Quantization | NVFP4 (E2M1 weights, FP8 scales) |
| Max context | 128K tokens |
| MTP | Yes (speculative decoding enabled) |
| Tool calling | qwen3_coder parser |

## File Structure

```
├── docker-compose.yml           # Atlas service with auth + GPU tuning
├── .env.example                 # Token template (committed, copy to .env)
├── 00_env.sh.example            # Shell env loader template
├── 00_a_pull_image.sh           # Pull latest image
├── 00_b_create_conda_env.sh     # Create test conda environment
├── 00_c_install_packages.sh     # Install Python dependencies
├── 00_d_pre_download_model.sh   # Pre-download model weights
├── 01_up.sh                     # Start container
├── 02_down.sh                   # Stop container
├── 03_enter_container.sh        # Bash into container
├── 04_a_list_models.sh          # List available models via curl
├── 04_b_chat_completion.sh      # Chat completion test via curl
├── 04_c_test_python_client.py   # OpenAI client test script
├── 05_a_docker_logs.sh          # Stream container logs
├── 05_b_log_to_metadata_folder.sh # Dump logs to metadata/ directory
└── test/
    └── test_file_01_prompt.md   # Default prompt
```

## Notes

- **Image:** `avarok/atlas-gb10:latest` — GB10/SM121 only (not compatible with RTX 5090)
- **Network:** Uses `development-network` external network, port `8000`
- **Auth token:** `INFERENCE_API_KEY` in `.env` (gitignored)
- **Cache:** HuggingFace weights persisted at `~/.cache/huggingface`
- **shm_size / ipc:** Set to `32g` / `host` for GPU memory sharing
