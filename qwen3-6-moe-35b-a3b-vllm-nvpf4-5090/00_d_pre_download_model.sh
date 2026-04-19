#!/bin/bash
# =============================================================================
# 00_d_pre_download_model.sh
# Downloads the Qwen model weights into the local cache directory
# =============================================================================

set -euo pipefail

ENV_NAME="testVllmQwen"
MODEL_ID="RedHatAI/Qwen3.6-35B-A3B-NVFP4"
CACHE_DIR="./hf-cache"

echo "📥 Preparing to pre-download model: $MODEL_ID"
mkdir -p "$CACHE_DIR"

# Check if conda environment exists
if ! conda env list | grep -q "^$ENV_NAME "; then
    echo "❌ Conda environment '$ENV_NAME' not found. Please run 00_b and 00_c first."
    exit 1
fi

echo "🚀 Starting download via huggingface-cli..."
# Use conda run to execute the command inside the environment
conda run -n "$ENV_NAME" huggingface-cli download "$MODEL_ID" --local-dir "$CACHE_DIR" --local-dir-use-symlinks False

echo ""
echo "✅ Download complete! Weights are stored in $CACHE_DIR"
