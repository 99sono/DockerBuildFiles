#!/bin/bash
# =============================================================================
# 00_d_pre_download_model.sh
# Downloads the Qwen model weights into the local cache directory
# =============================================================================

set -euo pipefail

ENV_NAME="testVllmQwen"
MODEL_ID="RedHatAI/Qwen3.6-35B-A3B-NVFP4"
CACHE_DIR="$HOME/.cache/huggingface"

echo "📥 Preparing to pre-download model: $MODEL_ID to global cache"
mkdir -p "$CACHE_DIR"

# Check if conda environment exists
if ! conda env list | grep -q "^$ENV_NAME "; then
    echo "❌ Conda environment '$ENV_NAME' not found. Please run 00_b and 00_c first."
    exit 1
fi

echo "🚀 Starting download..."
hf download "$MODEL_ID"

echo ""
echo "✅ Download complete! Weights are stored in $CACHE_DIR"
