#!/bin/bash
source ../../../commonScripts/lib.sh
CONTAINER=$(docker ps --format '{{.Names}}' | grep -E '^(qwen-3\.6-35b-mtp-dgx-spark|qwopus36-35b-mtp-dgx-spark)$' | head -1)
if [ -z "$CONTAINER" ]; then echo "❌ No active inference container found." >&2; exit 1; fi
echo "Entering container: $CONTAINER"
docker_exec_enter "$CONTAINER"
