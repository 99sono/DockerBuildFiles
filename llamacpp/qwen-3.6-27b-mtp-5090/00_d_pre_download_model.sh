#!/bin/bash
# =============================================================================
# 00_d_pre_download_model.sh
# Pre-downloads the GGUF model to HuggingFace central cache
# =============================================================================

set -euo pipefail

ENV_NAME="testLlamaCppQwen"
# Use the dedicated MTP repository for the best speedup results
MODEL_REPO="unsloth/Qwen3.6-27B-MTP-GGUF"
# The specific UD-Q4_K_XL quant you requested
MODEL_FILE="Qwen3.6-27B-UD-Q4_K_XL.gguf"
CACHE_DIR="$HOME/.cache/huggingface"

echo "📥 Pre-downloading GGUF model to central cache:"
echo "   - Repo : $MODEL_REPO"
echo "   - File : $MODEL_FILE"
echo "   - Cache: $CACHE_DIR"

if ! conda env list | grep -q "^$ENV_NAME "; then
    echo "❌ Conda environment '$ENV_NAME' not found. Run 00_b and 00_c first."
    exit 1
fi

echo "🚀 Starting download..."
# Pass $MODEL_REPO and $MODEL_FILE as separate arguments
# The --local-dir flag ensures it lands exactly where your Docker mount expects it
conda run -n "$ENV_NAME" hf download "$MODEL_REPO" "$MODEL_FILE" --local-dir "$CACHE_DIR"

echo ""
echo "✅ Download complete! GGUF cached at: $CACHE_DIR"
echo "🚀 Next: ./01_a_up_server.sh"
