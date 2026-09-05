#!/bin/bash
# =============================================================================
# 00_b_pre_download_model.sh
# =============================================================================
# Downloads the NVFP4 model weights to the local Hugging Face cache:
#   ~/.cache/huggingface/hub/
#
# Usage:
#   bash 00_b_pre_download_model.sh
# Overriding model ID:
#   MODEL_ID="nvidia/Qwen3.8-Flash-Next-NVFP4" bash 00_b_pre_download_model.sh
# =============================================================================
set -euo pipefail

MODEL_ID="${MODEL_ID:-Mia-AiLab/Qwen3.8-Flash-Next-NVFP4}"
HF_CACHE_DIR="${HF_HOME:-$HOME/.cache/huggingface}"
HUB_PATH="$HF_CACHE_DIR/hub"

echo "=== Downloading Model: $MODEL_ID ==="
echo "Target cache: $HUB_PATH"
mkdir -p "$HUB_PATH"

if command -v hf &>/dev/null; then
    echo "Using hf CLI..."
    HF_HOME="$HF_CACHE_DIR" hf download "$MODEL_ID" --cache-dir "$HUB_PATH"
elif command -v huggingface-cli &>/dev/null; then
    echo "Using huggingface-cli..."
    HF_HOME="$HF_CACHE_DIR" huggingface-cli download "$MODEL_ID" --cache-dir "$HUB_PATH"
elif command -v uvx &>/dev/null; then
    echo "Using uvx..."
    HF_HOME="$HF_CACHE_DIR" uvx hf download "$MODEL_ID" --cache-dir "$HUB_PATH"
else
    echo "ERROR: No HuggingFace download tool found (hf, huggingface-cli, or uvx)."
    exit 1
fi

ORG="${MODEL_ID%%/*}"
NAME="${MODEL_ID##*/}"
MODEL_PATH="$HUB_PATH/models--${ORG}--${NAME}"

if [ -d "$MODEL_PATH" ]; then
    SIZE=$(du -sh "$MODEL_PATH" 2>/dev/null | cut -f1)
    echo "✅ Download complete: $MODEL_PATH ($SIZE)"
else
    echo "❌ Download completed but directory $MODEL_PATH was not found."
    exit 1
fi
