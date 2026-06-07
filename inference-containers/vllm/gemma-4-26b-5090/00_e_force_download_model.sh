#!/bin/bash
# =============================================================================
# 00_e_force_download_model.sh
# Force download the NVIDIA Gemma 4 model weights to the local HuggingFace cache.
# =============================================================================

source ../../../commonScripts/lib.sh

set -euo pipefail

ENV_NAME="testVllmGemma"
MODEL_ID="nvidia/Gemma-4-26B-A4B-NVFP4"
CACHE_DIR="$HOME/.cache/huggingface"

echo "📥 Preparing to force-download model to cache:"
echo "   - Model: $MODEL_ID"
echo "   - Cache: $CACHE_DIR"

if ! conda_env_exists "$ENV_NAME"; then
    echo "❌ Conda environment '$ENV_NAME' not found. Run 00_b and 00_c first."
    exit 1
fi

echo "🚀 Starting download of model..."
hf_download_with_check "$ENV_NAME" "$MODEL_ID" "" "true"

echo ""
echo "✅ Download complete!"
