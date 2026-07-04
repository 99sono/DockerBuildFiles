#!/bin/bash
source ../../../../commonScripts/lib.sh
echo "Stopping Qwopus3.6-35B-A3B-v1 MTP on DGX Spark (llama.cpp)..."
docker_compose_down "docker-compose.yml"
