#!/bin/bash
source ../../../../commonScripts/lib.sh
echo "Stopping Qwopus3.6-27B-Coder MTP on DGX Spark (llama.cpp)..."
docker_compose_down "docker-compose.yml"
