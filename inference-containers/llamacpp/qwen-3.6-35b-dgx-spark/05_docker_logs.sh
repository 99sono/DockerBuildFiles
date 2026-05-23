#!/bin/bash
source ../../../commonScripts/lib.sh
load_env
CONTAINER=$(docker ps --format '{{.Names}}' | grep -E '^(qwen-3\.6-35b-mtp-dgx-spark|qwopus36-35b-mtp-dgx-spark)$' | head -1)
if [ -z "$CONTAINER" ]; then echo "❌ No active inference container found." >&2; exit 1; fi
docker_logs_follow_container "$CONTAINER"
