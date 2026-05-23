#!/bin/bash
source ../../../commonScripts/lib.sh
echo "Starting Qwen3.6-35B-A3B NVFP4 on RTX 5090..."
docker_compose_up "docker-compose.yml"
