#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"
source "$SCRIPT_DIR/00_env.sh"

CONTAINER_NAME="$NGINX_CONTAINER_NAME"

if ! docker ps --format '{{.Names}}' | grep -qx "$CONTAINER_NAME"; then
    echo "Error: Container '$CONTAINER_NAME' is not running." >&2
    exit 1
fi

echo "Entering nginx container '$CONTAINER_NAME' ..."
docker exec -it "$CONTAINER_NAME" /bin/bash