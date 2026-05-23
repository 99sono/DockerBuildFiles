#!/bin/bash
source ../../../commonScripts/lib.sh
echo "Starting TURBOQUANT Qwen 3.6 NVFP4 MTP setup (k8v4 Compression, 256K Context) on RTX 5090..."
docker_compose_up "docker-compose-turboquant.yml"
