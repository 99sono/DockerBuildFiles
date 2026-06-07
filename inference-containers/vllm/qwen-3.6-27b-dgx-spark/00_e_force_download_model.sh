#!/bin/bash
# =============================================================================
# 00_e_force_download_model.sh
# Force download the Qwen3.6-27B NVFP4 MTP model weights into the local cache
# =============================================================================

source ../../../commonScripts/lib.sh

set -euo pipefail

ENV_NAME="testVllmQwen27B"
MODEL_ID="sakamakismile/Qwen3.6-27B-Text-NVFP4-MTP"
CACHE_DIR="$HOME/.cache/huggingface"

echo "📥 Preparing to force-download model: $MODEL_ID to global cache"
mkdir -p "$CACHE_DIR"

if ! conda_env_exists "$ENV_NAME"; then
    echo "❌ Conda environment '$ENV_NAME' not found. Please run 00_b and 00_c first."
    exit 1
fi

echo "🚀 Starting download..."
hf_download_with_check "$ENV_NAME" "$MODEL_ID" "" "true"

echo ""
echo "✅ Download complete! Weights are stored in $CACHE_DIR"
