#!/bin/bash
source ../../../commonScripts/lib.sh
echo "Starting Atlas Qwen3.6-27B-FP8 (Dense) on DGX Spark (GB10)..."
check_env_exists
docker_compose_up
