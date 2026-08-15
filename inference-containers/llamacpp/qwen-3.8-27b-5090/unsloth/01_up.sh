#!/bin/bash
source ../../../../commonScripts/lib.sh
load_env
echo "Starting Qwen3.8-27B on RTX 5090 (llama.cpp)..."
docker_compose_up
