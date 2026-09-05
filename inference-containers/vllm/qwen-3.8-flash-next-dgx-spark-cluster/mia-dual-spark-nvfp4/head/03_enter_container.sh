#!/bin/bash
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../../../../../commonScripts/lib.sh"
load_env
cd "$SCRIPT_DIR"
docker exec -it qwen38-flash-next-head bash
