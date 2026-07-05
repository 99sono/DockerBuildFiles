#!/bin/bash
set -euo pipefail

ENV_NAME="${1:-testVllmDeepSeek}"
MODEL_ID="deepseek-ai/DeepSeek-V4-Flash-DSpark"
CACHE_DIR="$HOME/.cache/huggingface"

echo "Pre-downloading model: $MODEL_ID to global cache"
echo "Using conda env: $ENV_NAME"
mkdir -p "$CACHE_DIR"

if ! conda env list | grep -q "^$ENV_NAME "; then
    echo "Conda environment '$ENV_NAME' not found."
    echo "Usage: $0 [conda_env_name]  (default: testVllmDeepSeek)"
    exit 1
fi

echo "Starting download..."
source "$(conda info --base)/etc/profile.d/conda.sh"
conda activate "$ENV_NAME"
hf download "$MODEL_ID"

echo ""
echo "Download complete! Weights stored in $CACHE_DIR"
