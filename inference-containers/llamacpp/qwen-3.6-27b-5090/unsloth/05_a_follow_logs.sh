#!/bin/bash
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../../../../commonScripts/lib.sh"
docker_logs_follow_compose docker-compose.yml