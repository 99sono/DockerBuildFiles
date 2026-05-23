# Inference Containers

Containerized LLM inference servers. One model per container, consistent API interface across all engines and hardware configurations.

## Architecture

```
Client (port 8000) ──→ [Inference Container]
                          │
Local Dev:  direct port 8000
DGX Spark:  nginx reverse proxy → HTTPS (still reaches port 8000 internally)
```

## Core Rules

### 1. Port 8000 Everywhere

**Every inference container exposes its API on port 8000.** This ensures client scripts, curl commands, and proxy configurations never need to change when switching between models, engines, or hardware.

- vLLM: `--port 8000`
- llama.cpp: `--port 8000`
- Atlas: port 8000 in docker-compose

**Local development:** Direct access to `http://localhost:8000`
**DGX Spark:** nginx reverse proxy maps HTTPS to port 8000 internally. The proxy config never changes.

### 2. Model Name Abstraction

Each inference engine supports presenting a **clean, alias model name** that differs from the HuggingFace model ID. This is essential for experimentation — you can swap models without changing client code.

| Engine | Parameter | Example |
|--------|-----------|---------|
| vLLM | `--served-model-name` | `--served-model-name qwen3.6-27b` |
| llama.cpp | `--alias` | `--alias qwen3.6-27b` |
| Atlas | `--model-name` (from env `INFERENCE_MODEL_ALIAS`) | `INFERENCE_MODEL_ALIAS=qwen3.6-27b` |

**Naming Convention:**
- Only the **model family** in the exposed name
- **No quantization tags** (`nvfp4`, `fp8`, `prismaquant`, etc.)
- **No engine tags** (`mtp` as quantization, `vllm`, `llamacpp`)
- **No instruct suffix** (`it`)
- **Always lowercase**

Examples:
- ❌ `Qwen3.6-27B-Text-NVFP4-MTP` → ✅ `qwen3.6-27b`
- ❌ `gemma-4-26b-it-nvfp4` → ✅ `gemma-4-26b`
- ❌ `nemotron-cascade-2-nvfp4` → ✅ `nemotron-cascade-2`
- ❌ `RedHatAI/Qwen3.6-35B-A3B-NVFP4` → ✅ `qwen3.6-35b`

### 3. Folder Naming Convention

Folder names follow the pattern: `{model-family}-{hardware-suffix}`

**Pattern:** `{model-name}-{size}-{hardware}`

Where:
- **model-name** = model family (e.g., `qwen-3.6`, `gemma-4`)
- **size** = parameter size (e.g., `27b`, `35b`, `26b`)
- **hardware-suffix** = target hardware platform (required for all folders)

**Hardware suffixes:**
| Suffix | Architecture | Hardware |
|--------|--------------|----------|
| `-5090` | AMD64 | RTX 5090 (consumer GPU) |
| `-rtx5090` | AMD64 | RTX 5090 (consumer GPU) |
| `-dgx-spark` | ARM64 | NVIDIA DGX Spark (Grace Blackwell) |

**What to EXCLUDE from folder names:**
- Quantization: `nvfp4`, `fp8`, `mtp` (quantization), `prismaquant`, etc.
- Engine: `vllm`, `llamacpp`, `atlas`
- Architecture variants: `a3b`, `a4b` (these are model family details)

**Examples:**
| ❌ Old | ✅ New |
|--------|--------|
| `qwen-3.6-35b-a3b-vllm-nvpf4-dgx-spark` | `qwen-3.6-35b-dgx-spark` |
| `qwen-3.6-35b-a3b-vllm-nvpf4-5090` | `qwen-3.6-35b-5090` |
| `qwen-3.6-27b-nvfp4-mtp-dgx-spark` | `qwen-3.6-27b-dgx-spark` |
| `qwen-3.6-27b-vllm-nvfp4-rtx5090` | `qwen-3.6-27b-rtx5090` |
| `gemma-4-26b-a4b-vllm-nvpf4-5090` | `gemma-4-26b-5090` |
| `qwen-3.6-27b-mtp-5090` (llamacpp) | `qwen-3.6-27b-5090` |

**Why this convention:**
- You may want to try different quantizations of the same model. If NVFP4 underperforms, switch to PrismaQuant or INT8 without renaming folders.
- Different engines (vLLM vs llama.cpp) can serve the same model.
- Hardware suffix helps you quickly identify which models run on your available hardware.

### 3. One Model Per Container

Each container serves exactly **one model**. This simplifies resource management and avoids client-side routing complexity.

## Directory Structure

```
inference-containers/
├── vllm/              ← vLLM inference servers
│   ├── qwen-3.6-35b-dgx-spark/
│   ├── qwen-3.6-35b-5090/
│   ├── qwen-3.6-27b-dgx-spark/
│   ├── qwen-3.6-27b-rtx5090/
│   ├── gemma-4-26b-dgx-spark/
│   ├── gemma-4-26b-5090/
│   └── ...
├── llamacpp/          ← llama.cpp inference servers
│   ├── qwen-3.6-27b-dgx-spark/
│   └── qwen-3.6-27b-5090/
├── atlas/             ← Atlas FP8 inference servers
│   ├── qwen-3.6-35b-dgx-spark/
│   └── qwen-3.6-27b-dgx-spark/
├── ollama/            ← Ollama inference server
└── nginx/             ← Reverse proxy configs
    └── nginx-vllm-reverse-proxy-dgx-spark/

## Script Convention

Each model directory follows a numbered script convention for consistency:

| Prefix | Purpose |
|--------|---------|
| `00_*` | Setup: pull images, create conda env, install packages, pre-download model |
| `01_up.sh` | Start the container (`docker compose up -d`) |
| `02_down.sh` | Stop and remove containers (`docker compose down`) |
| `03_enter_container.sh` | Bash into the running container |
| `04_*` | Test scripts: list models, curl chat completion, python client |
| `05_*` | Diagnostics: view logs, dump to metadata folder |

## Environment Files

All inference containers use a **unified, framework-agnostic** set of environment variables prefixed with `INFERENCE_`. This means the same variable names work across vLLM, llama.cpp, and Atlas — no need to remember different prefixes per engine.

Each directory contains an `.env.example` template. Copy to `.env` and set credentials:

```bash
cp .env.example .env
# Edit .env with your actual values
```

### Unified Variables

| Variable | Purpose | docker-compose usage | Test script usage |
|---|---|---|---|
| `INFERENCE_API_KEY` | Server authentication token | `${INFERENCE_API_KEY:-dummy-key}` | Client API key |
| `INFERENCE_MODEL_ALIAS` | Name exposed in `/v1/models` API | Parametrizes `--alias` / `--served-model-name` | Model name for requests |
| `INFERENCE_SERVER_PORT` | Host↔container port mapping | `"${INFERENCE_SERVER_PORT:-8000}:8000"` | — |
| `INFERENCE_SERVER_URL` | Client-facing URL | Not used in compose | Test script base URL |

**Pattern:** All docker-compose.yml files use `${VAR:-default}` syntax, meaning a `.env` file is **optional** — defaults are built into the compose file. The `.env` file is only needed when you want to override a default (e.g., change API key, or point test scripts through nginx proxy).

**DGX Spark note:** `INFERENCE_SERVER_URL=https://localhost/v1` because traffic goes through the nginx reverse proxy. The container still listens on internal HTTP 8000, but clients connect via HTTPS through the proxy.

**Engine-specific vars:** Atlas uses `ATLAS_MODEL_ID` only as an inline default in `docker-compose.yml` — it is NOT in `.env` files since it's a non-controllable HuggingFace path, not a user-configurable parameter. Container names are hardcoded in compose files and shell scripts — no env variable for them.

## Inference Engines

### vLLM (`vllm/`)
- Best for FP8/quantized models on NVIDIA GPUs
- Uses `--served-model-name` for model aliasing (exposed in `/v1/models` API)
- Supports prefix caching, continuous batching
- Images: `havenoammo/vllm-openai:nightly` or similar

### llama.cpp (`llamacpp/`)
- GGUF format, supports speculative decoding (MTP, Eagle3)
- Uses `--alias` for model aliasing
- Best for single-GPU setups (RTX 5090, consumer cards)
- Image: `havenoammo/llama:cuda13-server`

### Atlas (`atlas/`)
- RedHat/QuantaBay FP8 inference on DGX Spark
- Uses `INFERENCE_MODEL_ALIAS` env var for model aliasing (unified across engines)
- Retains `ATLAS_MODEL_ID` for engine-specific HuggingFace model path
- Designed for DGX Spark hardware

## Client Scripts

Test scripts read configuration from `.env` using the unified `INFERENCE_*` variables:
- Python clients use `load_dotenv()` then `os.environ.get("INFERENCE_SERVER_URL", "default")` for URL, `INFERENCE_MODEL_ALIAS` for model name, and `INFERENCE_API_KEY` for auth
- Shell scripts use hardcoded container names (matching docker-compose.yml `container_name`) for `docker exec`, `docker logs`, etc.
- All test scripts use the simplified model alias (never HuggingFace IDs)