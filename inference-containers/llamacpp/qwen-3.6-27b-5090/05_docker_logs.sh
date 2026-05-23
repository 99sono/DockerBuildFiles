#!/bin/bash
source ../../../commonScripts/lib.sh
load_env
CONTAINER=$(docker ps --format '{{.Names}}' | grep -E '^(qwen-3\.6-27b-mtp-5090|qwopus36-27b-mtp-5090)$' | head -1)
if [ -z "$CONTAINER" ]; then echo "❌ No active inference container found." >&2; exit 1; fi
docker_logs_follow_container "$CONTAINER"
