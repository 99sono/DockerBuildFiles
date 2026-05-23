#!/bin/bash
source ../../../commonScripts/lib.sh
echo "Pulling latest vLLM image for DGX Spark (ARM64)..."
docker_compose_pull "docker-compose.yml"
