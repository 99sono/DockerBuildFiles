# DockerBuildFiles

Docker Compose configurations and shared helper scripts for running LLM inference servers on two local hardware targets: **RTX 5090** (AMD64) and **NVIDIA DGX Spark** (ARM64).

## Structure

```
DockerBuildFiles/
├── inference-containers/    ← LLM inference servers, grouped by backend
│   ├── llamacpp/            ← llama.cpp (GGUF) — MTP speculative decoding
│   ├── vllm/                ← vLLM — FP8/quantized models on NVIDIA GPUs
│   ├── ollama/              ← Ollama (OpenAI-compatible API)
│   ├── atlas/               ← Atlas FP8 (RedHat/QuantaBay) on DGX Spark
│   ├── nginx/               ← Reverse proxy configs (DGX Spark HTTPS)
│   ├── open-webui/          ← Open WebUI frontends
│   ├── ai-labs/             ← Model catalog docs, one .md per AI lab
│   ├── bookmarks/           ← Model reference notes
│   └── multi-agent-orchestration-test/
├── commonScripts/           ← Shared utilities (see below)
│   ├── lib.sh               ← Bash function library, sourced by all project scripts
│   ├── test_client.py       ← Consolidated Python OpenAI-compatible API test client
│   └── create_development_network.sh  ← Shared Docker network setup
├── 01_a_git_number_of_commits_ahead.sh  ← Root-level git helpers
├── 01_b_git_diff_dump_against_origin.sh
├── cliCurllToolDump/        ← curl output dumps for API testing
├── dev-image/               ← VS Code dev container
├── docker-hello-world/      ← Minimal sanity-check container
├── gpu-burn/                ← GPU stress test
└── nvidia-cuda-sample/      ← CUDA install experiments
```

## Inference Containers

Each backend directory contains one folder per model+hardware target, named `{model-name}-{size}-{hardware}` (e.g. `qwen-3.8-27b-5090`, `gemma-4-26b-dgx-spark`). Core conventions — **port 8000 everywhere**, **one model per container**, clean lowercase **model aliases**, folder naming rules — are documented in [`inference-containers/README.md`](inference-containers/README.md).

Current projects (examples):

| Backend | Project | Hardware |
|---|---|---|
| llamacpp | `qwen-3.8-27b-5090` | RTX 5090 |
| llamacpp | `qwen-3.6-27b-5090`, `qwen-3.6-35b-dgx-spark`, `gemma-4-12b-*` | RTX 5090 / DGX Spark |
| vllm | `qwen-3.6-35b-5090`, `qwen-3.6-27b-rtx5090`, `gemma-4-26b-5090` | RTX 5090 |
| vllm | `qwen-3.6-35b-dgx-spark`, `mistral-small-4-119b-dgx-spark`, `deepseek-v4-flash-dgx-spark-cluster` | DGX Spark |
| atlas | `qwen-3.6-27b-dgx-spark`, `qwen-3.6-35b-dgx-spark` | DGX Spark |

## Per-Project Layout

Every project follows the same numbered script convention (thin wrappers around `lib.sh`):

```
<project>/                       ← e.g. llamacpp/qwen-3.8-27b-5090/
├── 00_a_pull_image.sh           # docker compose pull
├── 00_b_create_conda_env.sh     # Create conda env for host-side tools
├── 00_c_install_packages.sh     # Install packages into that env
├── 04_test_curl.sh              # Run commonScripts/test_client.py against the server
├── .env.example                 # Committed template (copy to .env)
├── .env                         # Your config (gitignored)
├── test/                        # Test prompts + outputs for test_client.py
├── metadata/                    # Benchmark logs, VRAM traces
└── unsloth/                     # (llama.cpp) compose + server scripts live here
    ├── 00_d_pre_download_model.sh   # Download GGUF externally (served via -m)
    ├── 00_e_force_download_model.sh
    ├── 01_up.sh                 # Start server (docker compose up -d)
    ├── 02_down.sh               # Stop and remove containers
    ├── 03_enter_container.sh    # Bash into the running container
    ├── 05_a_follow_logs.sh      # Live tail of logs
    ├── 05_b_dump_logs.sh        # Dump logs to file (api_key masked)
    ├── 06_dump_help.sh          # Dump server version/help
    ├── docker-compose.yml
    └── models/                  # Downloaded GGUF (gitignored)
```

Projects without a sub-folder keep `01_up.sh`, `02_down.sh`, `docker-compose.yml`, etc. directly in the project root.

## Quick Start

Using the current RTX 5090 project as the example:

```bash
cd inference-containers/llamacpp/qwen-3.8-27b-5090

# 1. Optional: customize config (compose has ${VAR:-default} built in, so this is optional)
cp .env.example .env

# 2. One-time setup: image + host-side conda env + packages
./00_a_pull_image.sh
./00_b_create_conda_env.sh
./00_c_install_packages.sh

# 3. Pre-download the GGUF (~17.9 GB) — llama.cpp serves the local file, never downloads
cd unsloth
./00_d_pre_download_model.sh

# 4. Start the server (script ensures the shared dev network exists first, then docker compose up -d)
./01_up.sh
./05_a_follow_logs.sh          # watch startup (Ctrl-C when healthy)

# 5. Test it
cd ..
./04_test_curl.sh
```

Stop when done: `cd unsloth && ./02_down.sh`

## Shared Script Library

All wrapper scripts are a few lines long and source the shared library:

```bash
source ../../../commonScripts/lib.sh        ← from <project>/
source ../../../../commonScripts/lib.sh     ← from <project>/<subfolder>/ (e.g. unsloth/)
```

Key functions in [`commonScripts/lib.sh`](commonScripts/README.md) (full list in its README):

| Function | Purpose |
|---|---|
| `load_env` | Exports key=value pairs from the local `.env` |
| `docker_compose_pull/up/down` | Compose lifecycle; `up` ensures the shared `development-network` exists first |
| `conda_create_env`, `conda_install_packages` | Host-side conda env management |
| `hf_download_with_check <env> <repo> [file] [force] [local_dir]` | HuggingFace download with env pre-check; `local_dir` writes to `./models/` for local serving |
| `docker_logs_follow_compose`, `docker_logs_dump_container` | Log tail / masked dump |
| `docker_exec_enter <container>` | Interactive bash in the container |

## Environment Files & Variables

- **`.env`** is gitignored (may contain private API keys); **`.env.example`** is committed as the template per project.
- All `docker-compose.yml` files use `${VAR:-default}` syntax, so `.env` is **optional** — defaults are built in.
- Variables use a unified, framework-agnostic `INFERENCE_` prefix that works across llama.cpp, vLLM, and Atlas:

| Variable | Purpose |
|---|---|
| `INFERENCE_API_KEY` | Server authentication token |
| `INFERENCE_MODEL_ALIAS` | Name exposed in `/v1/models` (parametrizes `--alias` / `--served-model-name`) |
| `INFERENCE_SERVER_PORT` | Host↔container port mapping (internal port always 8000) |
| `INFERENCE_SERVER_URL` | Client-facing URL for test scripts |

DGX Spark projects set `INFERENCE_SERVER_URL=https://localhost/v1` because traffic goes through the nginx reverse proxy. Details in [`inference-containers/README.md`](inference-containers/README.md).
