#!/bin/bash
echo "Pulling llama.cpp server image (CUDA, ARM64 for GB10 Grace Blackwell)..."
source ../../../commonScripts/lib.sh
docker_compose_pull
