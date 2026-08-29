#!/bin/bash
# =============================================================================
# Variant03 — Pre-download DeepSeek-V4-Flash-0731 (official) to global HF cache
# =============================================================================
# Downloads deepseek-ai/DeepSeek-V4-Flash-0731 (~167GB) into ~/.cache/huggingface
# so the containers can mount it offline. Run this yourself on BOTH nodes:
#   bash 00_d_pre_download_model.sh
# Overridable:
#   MODEL_ID=<hf-repo-id> bash 00_d_pre_download_model.sh   (different repo)
#   ENV_NAME=<conda-env>  bash 00_d_pre_download_model.sh   (conda env with hf CLI)
# =============================================================================
set -euo pipefail

ENV_NAME="${1:-${ENV_NAME:-testVllmDeepSeek}}"
MODEL_ID="${MODEL_ID:-deepseek-ai/DeepSeek-V4-Flash-0731}"
CACHE_DIR="${HF_HOME:-$HOME/.cache/huggingface}"

echo "Model:        $MODEL_ID"
echo "Target cache: $CACHE_DIR"
echo "Conda env:    $ENV_NAME"
echo ""

if ! conda env list | grep -q "^${ENV_NAME} "; then
  echo "ERROR: conda env '$ENV_NAME' not found." >&2
  echo "Usage: bash 00_d_pre_download_model.sh [conda_env_name]" >&2
  exit 1
fi

mkdir -p "$CACHE_DIR"
echo "Starting download (resumable)..."
source "$(conda info --base)/etc/profile.d/conda.sh"
conda activate "$ENV_NAME"

hf download "$MODEL_ID"

echo ""
echo "Done. Verify with:"
echo "  ls $CACHE_DIR/hub/models--deepseek-ai--DeepSeek-V4-Flash-0731"
echo "  du -sh $CACHE_DIR/hub/models--deepseek-ai--DeepSeek-V4-Flash-0731"