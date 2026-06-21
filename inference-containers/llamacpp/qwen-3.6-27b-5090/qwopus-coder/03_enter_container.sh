#!/bin/bash
source ../../../../commonScripts/lib.sh
CONTAINER="qwopus36-27b-coder-5090"
if ! docker ps --format '{{.Names}}' | grep -q "^${CONTAINER}$"; then
  echo "❌ Container '$CONTAINER' is not running." >&2; exit 1
fi
echo "Entering container: $CONTAINER"
docker_exec_enter "$CONTAINER"
