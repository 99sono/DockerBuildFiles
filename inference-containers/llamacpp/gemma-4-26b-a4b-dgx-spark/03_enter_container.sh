#!/bin/bash
source ../../../commonScripts/lib.sh
CONTAINER="gemma-4-26b-a4b-dgx-spark"
if [ -z "$CONTAINER" ]; then echo "❌ No active inference container found." >&2; exit 1; fi
echo "Entering container: $CONTAINER"
docker_exec_enter "$CONTAINER"
