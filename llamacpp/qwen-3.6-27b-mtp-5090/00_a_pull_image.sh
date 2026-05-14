#!/bin/bash
echo "Pulling llama.cpp server image (CUDA 12.8+ for Blackwell MMQ kernels)..."
docker pull havenoammo/llama:cuda13-server
echo "Success: Image pulled."