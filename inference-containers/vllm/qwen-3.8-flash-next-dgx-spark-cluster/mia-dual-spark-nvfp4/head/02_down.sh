#!/bin/bash
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../../../../../commonScripts/lib.sh"
load_env
cd "$SCRIPT_DIR"
docker_compose_down
