#!/bin/bash
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../../../../commonScripts/lib.sh"

# Ensure local .env exists (copy from parent if needed)
if [ ! -f "$SCRIPT_DIR/.env" ] && [ -f "$SCRIPT_DIR/../.env" ]; then
  cp "$SCRIPT_DIR/../.env" "$SCRIPT_DIR/.env"
  echo "Created $SCRIPT_DIR/.env from parent .env"
fi

load_env
docker_compose_up
