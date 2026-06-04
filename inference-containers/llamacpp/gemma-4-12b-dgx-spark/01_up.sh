#!/bin/bash
source ../../../commonScripts/lib.sh
load_env
echo "Starting Gemma 4 12B Unified on DGX Spark GB10 (llama.cpp)..."
docker_compose_up
