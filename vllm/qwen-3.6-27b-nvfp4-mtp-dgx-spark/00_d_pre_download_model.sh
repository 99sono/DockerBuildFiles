#!/bin/bash
# =============================================================================
# 00_d_pre_download_model.sh
# Downloads the Qwen3.6-27B NVFP4 MTP model weights into the local cache
# =============================================================================

set -euo pipefail

ENV_NAME="testVllmQwen27B"
MODEL_ID="sakamakismile/Qwen3.6-27B-Text-NVFP4-MTP"
CACHE_DIR="$HOME/.cache/huggingface"

echo "📥 Preparing to pre-download model: $MODEL_ID to global cache"
mkdir -p "$CACHE_DIR"

if ! conda env list | grep -q "^$ENV_NAME "; then
    echo "❌ Conda environment '$ENV_NAME' not found. Please run 00_b and 00_c first."
    exit 1
fi

echo "🚀 Starting download..."
hf download "$MODEL_ID"

echo ""
echo "✅ Download complete! Weights are stored in $CACHE_DIR"