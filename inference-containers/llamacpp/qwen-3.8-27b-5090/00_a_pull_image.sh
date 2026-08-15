#!/bin/bash
echo "Pulling llama.cpp server image (CUDA 12.8+ for Blackwell MMQ kernels)..."
source ../../../commonScripts/lib.sh
docker_compose_pull
