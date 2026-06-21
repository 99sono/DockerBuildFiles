#!/bin/bash
source ../../../../commonScripts/lib.sh
load_env
echo "Starting Qwopus3.6-27B-v2 MTP on RTX 5090 (llama.cpp)..."
docker_compose_up
