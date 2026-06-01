#!/bin/bash
set -euo pipefail

MODEL_ID="nvidia/Qwen3.6-35B-A3B-NVFP4"
CACHE_DIR="$HOME/.cache/huggingface"

echo "📥 Pre-downloading model: $MODEL_ID to global cache"
mkdir -p "$CACHE_DIR"

export HF_HUB_ENABLE_HF_TRANSFER=1
echo "🚀 Starting download..."
hf download "$MODEL_ID"

echo ""
echo "✅ Download complete! Weights stored in $CACHE_DIR"
