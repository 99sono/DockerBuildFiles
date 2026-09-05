#!/bin/bash
# =====================================================================
# STEP 1/3 — create the conda env used by the vLLM log-parser toolchain.
#
# Pipeline (all files live in this directory):
#   01_create_conda_env_for_parse_script.sh   <- this: env "testVLLMLogParse" (python 3.12)
#   02_install_python_tools.sh                -> verify stdlib imports (pure-stdlib parser: no pkgs)
#   03_parse_docker_log_file_to_markdown_report.sh <log.txt> [out.md]
#                                              -> run parse_docker_log.py -> Markdown report
#
# Re-running is safe: if the env already exists, the helper asks whether to
# recreate it ("prompt" mode) and keeps the existing one on "N".
# =====================================================================
# Shared helpers: conda_create_env, conda_env_exists, logging, etc.
# Relative depth: log-parser/ -> vllm/ -> inference-containers/ -> repo root
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../../../commonScripts/lib.sh"
# conda_create_env <env-name> <python-version> <force|prompt>
conda_create_env "testVLLMLogParse" "3.12" "prompt"