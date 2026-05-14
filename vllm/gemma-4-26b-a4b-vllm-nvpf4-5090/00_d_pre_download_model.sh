#!/bin/bash
# =============================================================================
# 00_d_pre_download_model.sh
# =============================================================================
# Pre-download the NVIDIA Gemma 4 model weights to the local HuggingFace cache.

set -euo pipefail

ENV_NAME="testVllmGemma"
MODEL_ID="nvidia/Gemma-4-26B-A4B-NVFP4"
CACHE_DIR="$HOME/.cache/huggingface"

echo "📥 Preparing to pre-download model to cache:"
echo "   - Model: $MODEL_ID"
echo "   - Cache: $CACHE_DIR"

if ! conda env list | grep -q "^$ENV_NAME "; then
    echo "❌ Conda environment '$ENV_NAME' not found. Run 00_b and 00_c first."
    exit 1
fi

echo "🚀 Starting download of model..."
if command -v huggingface-cli &> /dev/null; then
    huggingface-cli download "$MODEL_ID"
else
    conda run -n "$ENV_NAME" huggingface-cli download "$MODEL_ID"
fi

echo ""
echo "✅ Download complete!"