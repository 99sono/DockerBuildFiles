#!/bin/bash
# Start the HEAD node container on this machine (spark01, node-rank=0).
# Serves the API on port 8000.
#
# Usage: sudo ./01_up.sh
#
# IMPORTANT: Start the WORKER node FIRST, then the HEAD.
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$SCRIPT_DIR"

# Ensure .env exists at the parent level
if [ ! -f ../.env ]; then
  if [ -f ../.env.example ]; then
    cp ../.env.example ../.env
    echo "Created ../.env from .env.example — edit it with your settings."
  else
    echo "WARNING: no ../.env or ../.env.example found. Using defaults."
  fi
fi

docker compose up -d
echo ""
echo "Head container launched. Wait ~6-7 min for model loading."
echo "Monitor: docker compose logs -f"
echo "Test:    curl http://localhost:8000/v1/models"
