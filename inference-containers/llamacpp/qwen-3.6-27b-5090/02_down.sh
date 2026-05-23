#!/bin/bash
source ../../../commonScripts/lib.sh
CONTAINER=$(docker ps --format '{{.Names}}' | grep -E '^(qwen-3\.6-27b-mtp-5090|qwopus36-27b-mtp-5090)$' | head -1)
if [ -z "$CONTAINER" ]; then echo "⚠️  No active inference container found."; exit 0; fi
if [[ "$CONTAINER" == qwopus* ]]; then docker_compose_down "docker-compose-qwopus.yml"; else docker_compose_down; fi
