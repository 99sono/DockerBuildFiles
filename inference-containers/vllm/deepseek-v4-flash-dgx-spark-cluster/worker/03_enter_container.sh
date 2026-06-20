#!/bin/bash
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../../../../commonScripts/lib.sh"
docker_exec_enter deepseek-v4-flash-worker
