#!/bin/bash
# Start the WORKER node container on this machine (spark02, node-rank=1).
# Headless — no API server, only participates in NCCL collective.
#
# Usage: sudo ./01_up.sh
#
# IMPORTANT: Start the WORKER FIRST, then the HEAD.
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$SCRIPT_DIR"

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
echo "Worker container launched. Now start the HEAD node on spark01."
echo "Monitor: docker compose logs -f"
