#!/bin/bash
echo "Pulling llama.cpp server image (CUDA, ARM64 for GB10 Grace Blackwell)..."
docker pull ghcr.io/ggerganov/llama.cpp:cuda
echo "Success: Image pulled."
