#!/bin/bash
# =============================================================================
# 00_d_pre_download_model.sh
# =============================================================================

set -euo pipefail

ENV_NAME="testVllmQwen"
MODEL_ID="sakamakismile/Qwen3.6-27B-Text-NVFP4-MTP"
CACHE_DIR="$HOME/.cache/huggingface"

echo "📥 Preparing to pre-download model to global cache:"
echo "   - Target  : $MODEL_ID"

if ! conda env list | grep -q "^$ENV_NAME "; then
    echo "❌ Conda environment '$ENV_NAME' not found. Run 00_b and 00_c first."
    exit 1
fi

echo "🚀 Starting download of target model..."
if command -v hf &> /dev/null; then
    hf download "$MODEL_ID"
else
    conda run -n "$ENV_NAME" huggingface-cli download "$MODEL_ID"
fi

echo ""
echo "✅ Download complete! Models cached at: $CACHE_DIR"
echo "🚀 Next: ./01_a_up_dflash.sh"