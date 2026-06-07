#!/bin/bash
source ../../../commonScripts/lib.sh
load_env
CONTAINER="gemma-4-12b-5090"
if [ -z "$CONTAINER" ]; then echo "❌ No active inference container found." >&2; exit 1; fi
docker_logs_follow_container "$CONTAINER"
