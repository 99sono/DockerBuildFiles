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
#       <framework>/               ← llamacpp | vllm | atlas
#         <project>/              ← e.g. qwen-3.6-27b-5090, gemma-4-26b-dgx-spark
#           docker-compose.yml
#           00_a_pull_image.sh    ← thin wrapper scripts (3–8 lines each)
#           01_a_up_server.sh
#           02_a_down_server.sh
#           ...
#           .env.example          ← per-project template (restore from git)
#           .env                  ← user's actual config (gitignored)
#
# Sourcing pattern (every script under inference-containers/<fw>/<project>/):
#   source ../../../commonScripts/lib.sh
#
# Design rules:
#   1. Functions never modify state beyond what the caller intends.
#   2. All functions use `local` variables to avoid leakage.
#   3. Missing required arguments trigger a usage message + exit 1.
#   4. No function reads .env directly — use load_env() first.
# =============================================================================

set -euo pipefail

resolve_common_dir() {
  echo "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
}

# --- ENV LOADING ---

## load_env
# Loads the local .env file into shell variables. Safe to call multiple times.
# Reads from the same directory as the calling script.
# Side effect: exports all non-comment key=value pairs from .env.
# Returns: 0 always (no-op if .env is absent).
load_env() {
  local script_dir
  script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
  if [ -f "$script_dir/.env" ]; then
    export $(grep -v '^#' "$script_dir/.env" | xargs)
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

## conda_env_exists <name>
# Checks whether a conda environment exists.
# Args:  name — conda environment name to check
# Returns: 0 if found, 1 if not found (does not exit).
conda_env_exists() {
  local name="$1"
  conda env list | grep -q "^${name} "
}

## conda_create_env <name> [python_version] [force|prompt]
# Creates a conda environment, prompting or forcing removal if it already exists.
# Args:  name         — conda environment name (required)
#        python_ver   — Python version, default "3.12"
#        mode         — "prompt" (ask user, default) or "force" (auto-remove)
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
docker_compose_pull() {
  local cf="${1:-}"
  if [ -n "$cf" ]; then docker compose -f "$cf" pull; else docker compose pull; fi
}

## docker_compose_up [compose_file]
# Starts containers via docker compose (detached mode). Ensures the shared
# development network exists first by sourcing create_development_network.sh.
# Args:  compose_file — optional path to a specific docker-compose file.
docker_compose_up() {
  local cf="${1:-}"
  source "$(resolve_common_dir)/create_development_network.sh"
  if [ -n "$cf" ]; then docker compose -f "$cf" up -d; else docker compose up -d; fi
}

## docker_compose_down [compose_file]
# Stops and removes containers via docker compose.
# Args:  compose_file — optional path to a specific docker-compose file.
docker_compose_down() {
  local cf="${1:-}"
  if [ -n "$cf" ]; then docker compose -f "$cf" down; else docker compose down; fi
}

# --- DOCKER LOGS ---

## docker_logs_follow_container <container_name>
# Follows logs for a specific running container. Exits with error if not running.
# Args:  container_name — exact Docker container name (required)
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
docker_logs_follow_compose() {
  local cf="${1:-docker-compose.yml}"
  docker compose -f "$cf" logs -f --tail=100
}

# --- DOCKER EXEC ---

## docker_exec_enter <container_name>
# Opens an interactive bash shell inside a running container.
# Args:  container_name — exact Docker container name (required)
docker_exec_enter() {
  local container="${1:?Usage: docker_exec_enter <name>}"
  docker exec -it "$container" bash
}

# --- MODEL DOWNLOAD ---

## hf_download_with_check <env_name> <model_id> [file]
# Downloads a model from Hugging Face, verifying the conda env exists first.
# Uses `conda run -n` internally to leverage the correct environment.
# Args:  env_name   — conda environment name (must exist)
#        model_id   — HuggingFace repo ID (e.g., unsloth/Qwen3.6-27B-MTP-GGUF)
#        file       — optional specific filename within the repo; if omitted,
#                     downloads the entire repo
hf_download_with_check() {
  local env_name="${1:?Usage: hf_download_with_check <env_name> <model_id> [file]}"
  local model_id="$2"
  local model_file="${3:-}"

  if ! conda_env_exists "$env_name"; then
    echo "❌ Conda env '$env_name' not found. Run 00_b and 00_c first." >&2; exit 1
  fi
  mkdir -p "$HOME/.cache/huggingface"
  if [ -n "$model_file" ]; then
    hf download "$model_id" "$model_file"
  else
    hf download "$model_id"
  fi
}
