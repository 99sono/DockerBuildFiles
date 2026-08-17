#!/bin/bash
source ../../../../commonScripts/lib.sh
load_env
echo "Starting Qwen3.8-27B NVFP4 on RTX 5090 (SGLang)..."
docker_compose_up
