#!/bin/bash
# Load .env from script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
[ -f "$SCRIPT_DIR/.env" ] && export $(grep -v '^#' "$SCRIPT_DIR/.env" | xargs)

CONTAINER="qwen-3-6-27b-fp8-mtp-atlas"
echo "Entering Atlas container (${CONTAINER})..."
docker exec -it "${CONTAINER}" bash
