#!/bin/bash
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
[ -f "$SCRIPT_DIR/.env" ] && export $(grep -v '^#' "$SCRIPT_DIR/.env" | xargs)
echo "Entering llama.cpp server container..."
docker exec -it qwen-3.6-27b-mtp-dgx-spark /bin/bash