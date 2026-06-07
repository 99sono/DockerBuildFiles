#!/bin/bash
# =============================================================================
# 00_e_force_download_model.sh
# Force download the Qwen3.6-35B-A3B PrismaQuant 4.75-bit model weights into local cache
# =============================================================================

source ../../../commonScripts/lib.sh

set -euo pipefail

ENV_NAME="testVllmQwen"
MODEL_ID="rdtand/Qwen3.6-35B-A3B-PrismaQuant-4.75bit"
CACHE_DIR="$HOME/.cache/huggingface"

echo "📥 Preparing to force-download model: $MODEL_ID to global cache"
mkdir -p "$CACHE_DIR"

# Check if conda environment exists
if ! conda_env_exists "$ENV_NAME"; then
    echo "❌ Conda environment '$ENV_NAME' not found. Please run 00_b and 00_c first."
    exit 1
fi

echo "🚀 Starting download..."
hf_download_with_check "$ENV_NAME" "$MODEL_ID" "" "true"

echo ""
echo "✅ Download complete! Weights are stored in $CACHE_DIR"
