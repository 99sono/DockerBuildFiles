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
# Main: Enter the container with an interactive bash shell
# ============================================================
echo "Entering nginx container '$CONTAINER_NAME' ..."
docker exec -it "$CONTAINER_NAME" /bin/bash