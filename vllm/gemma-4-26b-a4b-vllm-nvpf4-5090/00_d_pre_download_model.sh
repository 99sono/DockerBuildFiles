#!/bin/bash
# =============================================================================
# 00_d_pre_download_model.sh
# =============================================================================

set -euo pipefail

ENV_NAME="testVllmGemma"
MODEL_ID="RedHatAI/gemma-4-26B-A4B-it-NVFP4"
SPECULATOR_ID="RedHatAI/gemma-4-26B-A4B-it-speculator.eagle3"
CACHE_DIR="$HOME/.cache/huggingface"

echo "📥 Preparing to pre-download models to global cache:"
echo "   - Base       : $MODEL_ID"
echo "   - Speculator : $SPECULATOR_ID"

if ! conda env list | grep -q "^$ENV_NAME "; then
    echo "❌ Conda environment '$ENV_NAME' not found. Run 00_b and 00_c first."
    exit 1
fi

echo "🚀 Starting download of base model..."
if command -v hf &> /dev/null; then
    hf download "$MODEL_ID"
    echo "🚀 Starting download of speculator..."
    hf download "$SPECULATOR_ID"
else
    conda run -n "$ENV_NAME" huggingface-cli download "$MODEL_ID"
    conda run -n "$ENV_NAME" huggingface-cli download "$SPECULATOR_ID"
fi

echo ""
echo "✅ Download complete!"
