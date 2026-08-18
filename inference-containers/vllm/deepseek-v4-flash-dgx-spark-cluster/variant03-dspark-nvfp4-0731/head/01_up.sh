#!/bin/bash
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../../../../../commonScripts/lib.sh"

if [ ! -f "$SCRIPT_DIR/.env" ] && [ -f "$SCRIPT_DIR/../env.example.head" ]; then
  cp "$SCRIPT_DIR/../env.example.head" "$SCRIPT_DIR/.env"
  echo "Created $SCRIPT_DIR/.env from ../env.example.head"
fi

load_env
cd "$SCRIPT_DIR"
docker_compose_up
