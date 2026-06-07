#!/bin/bash
echo "Pulling llama.cpp server image (CUDA, AMD64 for RTX 5090 Blackwell)..."
source ../../../commonScripts/lib.sh
docker_compose_pull
