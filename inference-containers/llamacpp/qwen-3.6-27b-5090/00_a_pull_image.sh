#!/bin/bash
echo "Pulling llama.cpp server image (CUDA 12.8+ for Blackwell MMQ kernels)..."
docker pull havenoammo/llama:cuda13-server
# docker pull ghcr.io/ggml-org/llama.cpp:server-cuda13
echo "Success: Image pulled."