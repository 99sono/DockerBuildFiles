#!/bin/bash
set -euo pipefail

MODEL_ID="mistralai/Mistral-Small-4-119B-2603-NVFP4"
CACHE_DIR="$HOME/.cache/huggingface"

echo "Pre-downloading model: $MODEL_ID to global cache"
mkdir -p "$CACHE_DIR"

export HF_HUB_ENABLE_HF_TRANSFER=1
echo "Starting download..."
hf download "$MODEL_ID"

echo ""
echo "Download complete! Weights stored in $CACHE_DIR"
