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
| Atlas | `ATLAS_MODEL_NAME` | `ATLAS_MODEL_NAME=qwen3.6-27b` |

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
└── nginx/             ← Reverse proxy configs
    └── nginx-vllm-reverse-proxy-dgx-spark/
```

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

Each directory contains an `.env.example` template. Copy to `.env` and set credentials:

```bash
cp .env.example .env
# Edit .env with your actual values
```

Engine-specific env vars vary — see each engine's directory for details.

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
- Uses `ATLAS_MODEL_NAME` env var for aliasing
- Designed for DGX Spark hardware

## Client Scripts

Test scripts in each directory use the simplified model name:
- Python clients read from `.env` files via `os.environ.get("MODEL_NAME", "default")`
- Shell scripts use `MODEL="${ENV_VAR:-default_value}"`
- Hardcoded model names in test scripts always use the simplified form (never HuggingFace IDs)