#!/bin/bash
source ../../../commonScripts/lib.sh
echo "Starting Atlas Qwen3.6-35B-A3B NVFP4 on DGX Spark (GB10)..."
check_env_exists
docker_compose_up
