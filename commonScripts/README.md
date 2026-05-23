# commonScripts

Shared utilities used across all inference-container projects.

## Files

### `lib.sh`

Centralized Bash helper functions sourced by every script under `inference-containers/`. Sourcing pattern:

```bash
source ../../../commonScripts/lib.sh
```

**Design rules:**
- Functions never modify state beyond what the caller intends
- All functions use `local` variables — no leakage
- Missing required arguments trigger a usage message + exit 1
- No function reads `.env` directly — call `load_env()` first

**Available functions:**

| Function | Purpose |
|---|---|
| `resolve_common_dir` | Resolves the absolute path of this commonScripts directory |
| `load_env` | Exports all non-comment key=value pairs from local `.env` |
| `check_env_exists` | Guard: exits 1 if `.env` is missing (fail-fast for startup scripts) |
| `conda_env_exists <name>` | Checks whether a conda environment exists |
| `conda_create_env <name> [pyver] [force\|prompt]` | Creates or recreates a conda env |
| `conda_install_packages <env_name> pkg1 [pkg2 …]` | Installs packages from conda-forge into the given env |
| `docker_compose_pull [compose_file]` | Pulls images (optional specific file) |
| `docker_compose_up [compose_file]` | Starts containers; ensures shared dev network exists first |
| `docker_compose_down [compose_file]` | Stops and removes containers |
| `docker_logs_follow_container <name>` | Follows logs for a running container (exits if not running) |
| `docker_logs_follow_compose [compose_file]` | Follows compose logs (last 100 lines) |
| `docker_exec_enter <name>` | Interactive bash inside a running container |
| `hf_download_with_check <env> <model_id> [file]` | Downloads HF model after verifying conda env exists |

### `test_client.py`

Consolidated Python OpenAI-compatible API test client. Reads config from local `.env`, sends a chat completion request, writes output to disk, and reports token usage.

**Key features:**
- Auto-detects system CA bundle for HTTPS with self-signed certs (`/etc/ssl/certs/ca-certificates.crt`)
- Falls back to `reasoning_content` field when `content` is empty (llama.cpp MTP behavior)
- Connection-level diagnostics on failure (URL, model, masked API key)

**Environment variables** (all optional, with defaults):

| Variable | Default |
|---|---|
| `INFERENCE_SERVER_URL` | `http://localhost:8000/v1` |
| `INFERENCE_MODEL_ALIAS` | `qwen3.6-27b` |
| `INFERENCE_API_KEY` | `dummy-key` |
| `TEST_PROMPT_FILE` | `test/test_file_01_prompt.md` |
| `TEST_OUTPUT_FILE` | `test/test_output_01.md` |
| `INFERENCE_TEMP` | `1.0` |
| `INFERENCE_TOP_P` | `0.95` |
| `INFERENCE_MAX_TOKENS` | `20000` |

### `create_development_network.sh`

Creates the shared Docker network used by all inference containers (auto-sourced by `docker_compose_up`).

### `.env.example`

Template showing common environment variables for use in project-specific `.env` files.
