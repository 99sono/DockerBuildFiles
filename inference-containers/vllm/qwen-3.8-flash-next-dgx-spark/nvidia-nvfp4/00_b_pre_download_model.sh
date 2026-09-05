#!/bin/bash
set -euo pipefail

MODEL_ID="nvidia/Qwen3.8-Flash-Next-NVFP4"
CACHE_DIR="$HOME/.cache/huggingface"

echo "📥 Pre-downloading model: $MODEL_ID to global cache"
mkdir -p "$CACHE_DIR"

export HF_XET_HIGH_PERFORMANCE=1

# Check disk space before proceeding (~99 GB model + 27 GB packed PLE = ~130 GB required)
AVAIL_GIB=$(df -BG --output=avail "$(dirname "$CACHE_DIR")" 2>/dev/null | tail -1 | tr -dc '0-9' || echo 0)
if [ -n "$AVAIL_GIB" ] && [ "$AVAIL_GIB" -lt 130 ]; then
    echo "⚠️  WARNING: Only ${AVAIL_GIB} GiB free on $(dirname "$CACHE_DIR")."
    echo "    The checkpoint is ~99 GB and builds a ~27 GB packed PLE table on first launch."
    echo "    ~130 GiB free is the safe figure."
fi

echo "🚀 Starting download..."
hf download "$MODEL_ID"

echo ""
echo "✅ Download complete! Weights stored in $CACHE_DIR"
