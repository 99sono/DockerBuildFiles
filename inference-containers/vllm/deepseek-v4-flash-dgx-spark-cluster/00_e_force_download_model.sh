#!/bin/bash
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../../../commonScripts/lib.sh"

set -euo pipefail

ENV_NAME="testVllmDeepSeek"
MODEL_ID="deepseek-ai/DeepSeek-V4-Flash"
CACHE_DIR="$HOME/.cache/huggingface"

echo "Force-downloading model: $MODEL_ID to global cache"
mkdir -p "$CACHE_DIR"

if ! conda_env_exists "$ENV_NAME"; then
    echo "Conda environment '$ENV_NAME' not found. Please run 00_b_create_conda_env.sh and 00_c_install_packages.sh first."
    exit 1
fi

echo "Starting download..."
hf_download_with_check "$ENV_NAME" "$MODEL_ID" "" "true"

echo ""
echo "Download complete! Weights stored in $CACHE_DIR"
