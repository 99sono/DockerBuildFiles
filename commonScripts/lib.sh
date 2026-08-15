#!/bin/bash
# =============================================================================
# lib.sh — Shared function library for inference container shell scripts
# =============================================================================
# Purpose: Centralized helper functions to eliminate duplication across all
#          inference-container project folders (llamacpp, vllm, atlas).
#
# Project structure:
#   DockerBuildFiles/
#     commonScripts/
#       lib.sh                     ← this file
#       test_client.py             ← consolidated Python OpenAI client tester
#       create_development_network.sh
#     inference-containers/
#       <framework>/               ← llamacpp | vllm | atlas | open-webui
#         <project>/              ← e.g. qwen-3.6-27b-5090, gemma-4-26b-dgx-spark
#                                   (some projects have sub-folders, e.g. unsloth/)
#           docker-compose.yml
#           00_a_pull_image.sh     ← thin wrapper scripts (a few lines each):
#           00_b_create_conda_env.sh
#           00_c_install_packages.sh
#           00_d_pre_download_model.sh
#           00_e_force_download_model.sh
#           01_up.sh
#           02_down.sh
#           03_enter_container.sh
#           04_test_curl.sh
#           05_a_follow_logs.sh
#           05_b_dump_logs.sh
#           ...
#           .env.example           ← per-project template (restore from git)
#           .env                   ← user's actual config (gitignored)
#
# Sourcing pattern (every wrapper script under inference-containers/...):
#   source ../../../commonScripts/lib.sh          ← from <project>/ (1 level deep)
#   source ../../../../commonScripts/lib.sh       ← from <project>/<subfolder>/ (2 levels deep)
#
# Design rules:
#   1. Functions never modify state beyond what the caller intends.
#   2. All functions use `local` variables to avoid leakage.
#   3. Functions that need required arguments validate them with `${1:?...}`
#      usage strings (a missing argument prints usage and exits 1).
#   4. No function reads .env directly — use load_env() first.
# =============================================================================

set -euo pipefail

# --- UTILITIES ---

## resolve_common_dir
# Prints the absolute path of the directory that contains this file
# (i.e. commonScripts/), regardless of the caller's current directory.
# Used internally by docker_compose_up() to source
# create_development_network.sh. Safe to call from any project folder.
# Returns: 0; prints the resolved absolute path to stdout.
resolve_common_dir() {
  echo "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
}

# --- ENV LOADING ---

## load_env
# Loads the local .env file into shell variables. Safe to call multiple times.
# Reads from the same directory as the calling script.
# Returns: 0 always (no-op if .env is absent).
# Side effect: exports all non-comment key=value pairs from .env.
load_env() {
  local script_dir
  local caller="${BASH_SOURCE[1]:-}"
  if [ -n "$caller" ]; then
    script_dir="$(cd "$(dirname "$caller")" && pwd)"
  else
    script_dir="$PWD"
  fi
  if [ -f "$script_dir/.env" ]; then
    export $(sed 's/[[:space:]]*#.*//; /^[[:space:]]*$/d' "$script_dir/.env" | xargs)
  fi
}

## check_env_exists
# Atlas-style guard: exits with error if .env is missing in the current directory.
# Use at the top of startup scripts (01_up.sh) to fail fast.
# Returns: 0 if .env exists, exits 1 otherwise.
check_env_exists() {
  if [ ! -f .env ]; then
    echo "❌ Missing .env — copy from .env.example and add your auth token." >&2
    echo "   cp .env.example .env" >&2
    exit 1
  fi
}

# --- CONDA ENVIRONMENT ---

## conda_env_exists <env_name>
# Checks whether a conda environment exists.
# Args:  env_name — conda environment name to check
# Returns: 0 if found, 1 if not found (does not exit).
conda_env_exists() {
  local name="$1"
  conda env list | grep -q "^${name} "
}

## conda_create_env <env_name> [python_version] [force|prompt]
# Creates a conda environment, prompting or forcing removal if it already exists.
# Args:  env_name       — conda environment name (required)
#        python_version — Python version, default "3.12"
#        mode           — "prompt" (ask user, default) or "force" (auto-remove)
# Returns: 0 on success or if environment already exists with prompt=skip.
conda_create_env() {
  local name="${1:?Usage: conda_create_env <name> [python_version] [force|prompt]}"
  local pyver="${2:-3.12}"
  local mode="${3:-prompt}"

  if conda_env_exists "$name"; then
    if [ "$mode" = "force" ]; then
      echo "⚠️  Environment '$name' exists, recreating..."
      conda env remove -n "$name" -y
    else
      echo "⚠️  Environment '$name' already exists."
      read -p "Recreate it? (y/N): " -r
      if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "Keeping existing environment."
        return 0
      fi
      conda env remove -n "$name" -y
    fi
  fi
  conda create -n "$name" python="$pyver" -y
}

## conda_install_packages <env_name> pkg1 [pkg2 ...]
# Activates a conda environment and installs packages from conda-forge.
# Args:  env_name — conda environment to activate (required)
#        pkgs     — one or more package names (e.g., pytorch cpuonly)
# Returns: exit status of `conda install` (non-zero on failure).
# Side effect: activates the conda env in the current shell session.
conda_install_packages() {
  local name="${1:?Usage: conda_install_packages <env_name> pkg1 [pkg2 ...]}"
  shift
  source "$(conda info --base)/etc/profile.d/conda.sh"
  conda activate "$name"
  conda install -y -c conda-forge "$@"
}

# --- DOCKER COMPOSE ---

## docker_compose_pull [compose_file]
# Pulls latest images via docker compose.
# Args:  compose_file — optional path to a specific docker-compose file.
#                       If omitted, uses the default (docker-compose.yml in cwd).
# Returns: exit status of `docker compose pull`.
docker_compose_pull() {
  local cf="${1:-}"
  if [ -n "$cf" ]; then docker compose -f "$cf" pull; else docker compose pull; fi
}

## docker_compose_up [compose_file]
# Starts containers via docker compose (detached mode). Ensures the shared
# development network exists first by sourcing create_development_network.sh.
# Args:  compose_file — optional path to a specific docker-compose file.
# Returns: exit status of `docker compose up -d`.
docker_compose_up() {
  local cf="${1:-}"
  source "$(resolve_common_dir)/create_development_network.sh"
  if [ -n "$cf" ]; then docker compose -f "$cf" up -d; else docker compose up -d; fi
}

## docker_compose_down [compose_file]
# Stops and removes containers via docker compose.
# Args:  compose_file — optional path to a specific docker-compose file.
# Returns: exit status of `docker compose down`.
docker_compose_down() {
  local cf="${1:-}"
  if [ -n "$cf" ]; then docker compose -f "$cf" down; else docker compose down; fi
}

# --- DOCKER LOGS ---

## docker_logs_follow_container <container_name>
# Follows logs for a specific running container. Exits with error if not running.
# Args:  container_name — exact Docker container name (required)
# Returns: 0 while following logs (blocking until interrupted); exits 1
#          if the container is not running.
docker_logs_follow_container() {
  local container="${1:?Usage: docker_logs_follow_container <name>}"
  if ! docker ps --format '{{.Names}}' | grep -q "^${container}$"; then
    echo "❌ Container '$container' is not running." >&2; exit 1
  fi
  docker logs -f "$container"
}

## docker_logs_follow_compose [compose_file]
# Follows logs for all services in a compose file (last 100 lines).
# Args:  compose_file — path to docker-compose file, default "docker-compose.yml"
# Returns: 0 while following logs (blocking until interrupted).
docker_logs_follow_compose() {
  local cf="${1:-docker-compose.yml}"
  docker compose -f "$cf" logs -f --tail=100
}

## docker_logs_dump_container <container_name> [output_file]
# Dumps all logs from a container to a file, masking sensitive values
# (e.g., api_key) before writing. Exits with error if not running.
# Args:  container_name — exact Docker container name (required)
#        output_file    — optional output path, default "<container>_log_dump.txt"
# Returns: 0 on success; exits 1 if the container is not running.
# Side effect: writes the log dump file and prints a summary to stdout.
docker_logs_dump_container() {
  local container="${1:?Usage: docker_logs_dump_container <name> [output_file]}"
  local outfile="${2:-${container}_log_dump.txt}"

  if ! docker ps --format '{{.Names}}' | grep -q "^${container}$"; then
    echo "❌ Container '$container' is not running." >&2; exit 1
  fi

  # Mask sensitive values: replace api_key content with dummy-key
  docker logs "$container" 2>&1 | sed -E \
    -e "s/api_key': \['[^']+'\]/api_key': ['dummy-key']/g" \
    > "$outfile"

  local line_count file_size
  line_count=$(wc -l < "$outfile")
  file_size=$(du -h "$outfile" | cut -f1)

  echo "📋 Log dump complete (sensitive values masked)."
  echo "   Container : $container"
  echo "   File      : $outfile"
  echo "   Lines     : $line_count"
  echo "   Size      : $file_size"
}

# --- DOCKER EXEC ---

## docker_exec_enter <container_name>
# Opens an interactive bash shell inside a running container.
# Args:  container_name — exact Docker container name (required)
# Returns: exit status of the shell inside the container (e.g., when the user exits).
docker_exec_enter() {
  local container="${1:?Usage: docker_exec_enter <name>}"
  docker exec -it "$container" bash
}

# --- MODEL DOWNLOAD ---

## hf_download_with_check <env_name> <model_id> [file] [force] [local_dir]
# Downloads a model from Hugging Face, verifying the conda env exists first.
# Uses the `hf` CLI directly in the current shell (not via `conda run`);
# the env is only checked for existence, not activated.
# Args:  env_name   — conda environment name (must exist)
#        model_id   — HuggingFace repo ID (e.g., unsloth/Qwen3.8-27B-GGUF)
#        file       — optional specific filename within the repo; if omitted,
#                     downloads the entire repo
#        force      — optional, set to "true" to force a re-download
#        local_dir  — optional local directory for --local-dir (explicit path,
#                     independent of the HF cache). Use this when the model must
#                     be downloaded BEFORE the container starts and served via -m.
# Returns: exit status of `hf download` (non-zero on failure); exits 1 if the
#          conda env does not exist.
# Side effect: creates $HOME/.cache/huggingface (and local_dir if given) as needed.
hf_download_with_check() {
  # -- Parse positional arguments --------------------------------------------------
  # ${1:?...} fails with a usage message if env_name is missing; the rest fall
  # back to empty/false defaults so the function works when only args 1–2 given.
  local env_name="${1:?Usage: hf_download_with_check <env_name> <model_id> [file] [force] [local_dir]}"
  local model_id="$2"
  local model_file="${3:-}"
  local force="${4:-false}"
  local local_dir="${5:-}"

  # -- Pre-flight checks -----------------------------------------------------------
  # Fail fast if the conda env is missing (it's required for `hf` to exist).
  if ! conda_env_exists "$env_name"; then
    echo "❌ Conda env '$env_name' not found. Run 00_b and 00_c first." >&2; exit 1
  fi
  # Ensure the default HF cache dir exists so downloads never fail on a missing parent.
  mkdir -p "$HOME/.cache/huggingface"

  # -- Build extra CLI flags -------------------------------------------------------
  local extra_args=""
  # --force-download makes `hf` re-fetch even if a cached copy exists.
  if [ "$force" = "true" ]; then
    extra_args="--force-download"
  fi
  # --local-dir writes to an explicit path (independent of the HF cache), used
  # when the model must exist on disk before the container starts (served via -m).
  if [ -n "$local_dir" ]; then
    mkdir -p "$local_dir"
    extra_args="$extra_args --local-dir $local_dir"
  fi

  # -- Download --------------------------------------------------------------------
  # Single-file download when a filename is given; otherwise the whole repo.
  if [ -n "$model_file" ]; then
    hf download "$model_id" "$model_file" $extra_args
  else
    hf download "$model_id" $extra_args
  fi
}
