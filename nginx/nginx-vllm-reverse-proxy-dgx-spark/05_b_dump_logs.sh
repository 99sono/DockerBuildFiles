#!/usr/bin/env bash
set -euo pipefail

# ============================================================
# Configuration
# ============================================================
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"
source "$SCRIPT_DIR/00_env.sh"

# Get the nginx container name from environment configuration
CONTAINER_NAME="$NGINX_CONTAINER_NAME"

# ============================================================
# Pre-flight check: Verify container is running
# ============================================================
if ! docker ps --format '{{.Names}}' | grep -qx "$CONTAINER_NAME"; then
    echo "Error: Container '$CONTAINER_NAME' is not running." >&2
    exit 1
fi

# ============================================================
# Main: Dump container logs to local file for analysis
# ============================================================
echo "Dumping $CONTAINER_NAME container logs ..."

docker logs "$CONTAINER_NAME" > nginx_logs_dump.txt 2>&1

echo "Done! Logs saved to nginx_logs_dump.txt"
echo "Last 20 lines:"
echo "---------------------------------------------------"
tail -n 20 nginx_logs_dump.txt