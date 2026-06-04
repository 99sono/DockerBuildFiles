#!/bin/bash
source ../../../commonScripts/lib.sh
CONTAINER=$(docker ps --format '{{.Names}}' | grep -E '^gemma-4\.26b-a4b-dgx-spark$' | head -1)
if [ -z "$CONTAINER" ]; then echo "⚠️  No active inference container found."; exit 0; fi
docker_compose_down
