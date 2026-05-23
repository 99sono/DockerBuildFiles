#!/bin/bash
# Live tail of Atlas container logs. Ctrl+C to stop.
# For timestamped snapshot dumps, use 05_b_log_to_metadata_folder.sh instead.

# Load .env from script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
[ -f "$SCRIPT_DIR/.env" ] && export $(grep -v '^#' "$SCRIPT_DIR/.env" | xargs)

CONTAINER="qwen-3-6-35b-a3b-nvfp4-atlas"

if ! docker ps --format '{{.Names}}' | grep -q "^${CONTAINER}$"; then
    echo "❌ Container '${CONTAINER}' is not running."
    exit 1
fi

echo "📋 Displaying logs for '${CONTAINER}' (Ctrl+C to stop)..."
docker logs -f "${CONTAINER}"
