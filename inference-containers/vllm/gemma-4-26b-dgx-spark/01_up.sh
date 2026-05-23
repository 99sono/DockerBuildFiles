#!/bin/bash
source ../../../commonScripts/lib.sh
echo "Starting Gemma-4 DGX Spark setup (NVFP4, ARM64)..."
docker_compose_up "docker-compose.yml"
