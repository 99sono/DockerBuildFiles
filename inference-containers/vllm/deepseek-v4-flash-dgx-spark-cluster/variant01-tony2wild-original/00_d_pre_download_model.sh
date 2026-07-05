#!/bin/bash
set -euo pipefail

ENV_NAME="testVllmDeepSeek"
MODEL_ID="deepseek-ai/DeepSeek-V4-Flash"
CACHE_DIR="$HOME/.cache/huggingface"

echo "Pre-downloading model: $MODEL_ID to global cache"
mkdir -p "$CACHE_DIR"

if ! conda env list | grep -q "^$ENV_NAME "; then
    echo "Conda environment '$ENV_NAME' not found. Please run 00_b_create_conda_env.sh and 00_c_install_packages.sh first."
    exit 1
fi

echo "Starting download..."
hf download "$MODEL_ID"

echo ""
echo "Download complete! Weights stored in $CACHE_DIR"
