#!/bin/bash
source ../../../commonScripts/lib.sh
load_env
echo "Starting Gemma 4 12B Unified on RTX 5090 (llama.cpp)..."
docker_compose_up
