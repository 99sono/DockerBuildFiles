#!/bin/bash
echo "Pulling llama.cpp server image (CUDA, ARM64 for GB10 Grace Blackwell)..."
docker pull ghcr.io/ggml-org/llama.cpp:server-cuda13
echo "Success: Image pulled."
