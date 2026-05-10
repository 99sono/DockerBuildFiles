#!/usr/bin/env bash
set -euo pipefail

# ============================================================
# Configuration
# ============================================================
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"
source "$SCRIPT_DIR/00_env.sh"

# ============================================================
# Pre-flight check: Verify container is running
# ============================================================
if ! docker ps --format '{{.Names}}' | grep -qx "$DEBUG_CONTAINER_NAME"; then
    echo "Error: Container '$DEBUG_CONTAINER_NAME' is not running." >&2
    exit 1
fi

# ============================================================
# Main: Dump container logs to local file for analysis
# ============================================================
LOG_FILE="$SCRIPT_DIR/debug_logs/docker_logs_dump.txt"
echo "Dumping $DEBUG_CONTAINER_NAME container logs to $(basename "$LOG_FILE") ..."

docker logs "$DEBUG_CONTAINER_NAME" > "$LOG_FILE" 2>&1

echo "Done! Logs saved to $(basename "$LOG_FILE")"
echo "Last 20 lines:"
echo "---------------------------------------------------"
tail -n 20 "$LOG_FILE"