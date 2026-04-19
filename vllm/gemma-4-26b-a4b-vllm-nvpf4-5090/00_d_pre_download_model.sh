#!/bin/bash
# =============================================================================
# 00_d_pre_download_model.sh
# =============================================================================

set -euo pipefail

ENV_NAME="testVllmGemma"
MODEL_ID="RedHatAI/gemma-4-26B-A4B-it-NVFP4"
CACHE_DIR="$HOME/.cache/huggingface"

echo "📥 Preparing to pre-download model: $MODEL_ID to global cache"

if ! conda env list | grep -q "^$ENV_NAME "; then
    echo "❌ Conda environment '$ENV_NAME' not found. Run 00_b and 00_c first."
    exit 1
fi

echo "🚀 Starting download..."
if command -v hf &> /dev/null; then
    hf download "$MODEL_ID"
else
    conda run -n "$ENV_NAME" huggingface-cli download "$MODEL_ID"
fi

echo ""
echo "✅ Download complete!"
