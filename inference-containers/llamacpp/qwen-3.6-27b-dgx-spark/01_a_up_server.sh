#!/bin/bash
source ../../../commonScripts/lib.sh
load_env
echo "Starting Qwen3.6-27B MTP on DGX Spark GB10 (llama.cpp)..."
docker_compose_up
