#!/bin/bash
source ../../../commonScripts/lib.sh
load_env
echo "Starting Qwopus3.6-35B-A3B-v1 MTP on DGX Spark GB10 (llama.cpp)..."
docker_compose_up "docker-compose-qwopus.yml"
