#!/bin/bash
source ../../../commonScripts/lib.sh
echo "Starting NORMAL Qwen 3.6 NVFP4 MTP setup (FP8 KV Cache, 128K Context) on RTX 5090..."
docker_compose_up "docker-compose.yml"
