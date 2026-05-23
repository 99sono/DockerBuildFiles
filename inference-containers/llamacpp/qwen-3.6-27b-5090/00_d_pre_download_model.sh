#!/bin/bash
# =============================================================================
# 00_d_pre_download_model.sh
# =============================================================================
# Pre-download Qwen 3.6 27B MTP GGUF to the central HuggingFace cache.

set -euo pipefail

ENV_NAME="testLlamaCppQwen"
# The exact Repo ID and Filename for the MTP-optimized GGUF
MODEL_ID="unsloth/Qwen3.6-27B-MTP-GGUF"
MODEL_FILE="Qwen3.6-27B-UD-Q4_K_XL.gguf"
CACHE_DIR="$HOME/.cache/huggingface"

echo "📥 Preparing to pre-download model to central cache:"
echo "   - Model ID: $MODEL_ID"
echo "   - File    : $MODEL_FILE"
echo "   - Cache   : $CACHE_DIR"

if ! conda env list | grep -q "^$ENV_NAME "; then
    echo "❌ Conda environment '$ENV_NAME' not found. Run 00_b and 00_c first."
    exit 1
fi

echo "🚀 Starting download of specific GGUF file..."
# Using --include ensures we don't pull every single quantization in the repo
conda run -n "$ENV_NAME" hf download "$MODEL_ID" "$MODEL_FILE"

echo ""
echo "✅ Download complete! Standard HF Hub structure created."
echo "🚀 Next: ./01_a_up_server.sh"