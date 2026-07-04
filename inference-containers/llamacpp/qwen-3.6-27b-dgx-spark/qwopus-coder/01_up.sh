#!/bin/bash
source ../../../../commonScripts/lib.sh
load_env
echo "Starting Qwopus3.6-27B-Coder MTP on DGX Spark (llama.cpp)..."
docker_compose_up "docker-compose.yml"
