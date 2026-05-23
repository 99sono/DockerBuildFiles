#!/bin/bash
source ../../../commonScripts/lib.sh
load_env
echo "Stopping llama.cpp 35B server on DGX Spark..."
docker_compose_down
