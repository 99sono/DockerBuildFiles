#!/bin/bash
# Pre-download DeepSeek-V4-Flash model weights to the host HuggingFace cache.
# Both nodes need this to avoid downloading 150 GB at cold start.
set -euo pipefail

IMAGE="aidendle94/sparkrun-vllm-ds4-gb10:production-ready"
MODEL="deepseek-ai/DeepSeek-V4-Flash"
CACHE_DIR="$HOME/.cache/huggingface"

mkdir -p "$CACHE_DIR"

docker run --rm \
  -v "$CACHE_DIR":/cache/huggingface \
  -e HF_HOME=/cache/huggingface \
  "$IMAGE" \
  bash -c "huggingface-cli download $MODEL && echo 'Download complete.'"
