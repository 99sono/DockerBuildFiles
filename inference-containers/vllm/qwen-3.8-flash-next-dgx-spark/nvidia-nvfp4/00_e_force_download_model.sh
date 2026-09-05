#!/bin/bash
source ../../../../commonScripts/lib.sh
set -euo pipefail

MODEL_ID="nvidia/Qwen3.8-Flash-Next-NVFP4"
CACHE_DIR="$HOME/.cache/huggingface"

echo "📥 Force pre-downloading model: $MODEL_ID to global cache"
mkdir -p "$CACHE_DIR"

export HF_XET_HIGH_PERFORMANCE=1

echo "🚀 Starting download..."
hf download "$MODEL_ID"

echo ""
echo "✅ Download complete! Weights stored in $CACHE_DIR"
