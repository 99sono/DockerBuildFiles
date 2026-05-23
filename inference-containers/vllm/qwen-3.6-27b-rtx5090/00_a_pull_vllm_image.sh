#!/bin/bash
source ../../../commonScripts/lib.sh
echo "Pulling latest vLLM images via Docker Compose..."
docker_compose_pull "docker-compose.yml"
