#!/bin/bash
source ../../../commonScripts/lib.sh
CONTAINER=$(docker ps --format '{{.Names}}' | grep -E '^gemma-4-12b-5090$' | head -1)
if [ -z "$CONTAINER" ]; then echo "⚠️  No active inference container found."; exit 0; fi
docker_compose_down
