#!/bin/bash
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../../../../commonScripts/lib.sh"
load_env

echo "=========================================="
echo "  Qwen3.6-27B (Unsloth) — llama.cpp Help"
echo "=========================================="
echo ""

CONTAINER="qwen-3.6-27b-mtp-5090"
if docker ps --format '{{.Names}}' | grep -q "^${CONTAINER}$"; then
  echo "Active container: $CONTAINER"
  echo "Dumping llama.cpp server version/help info..."
  echo ""
  docker exec "$CONTAINER" llama-server --version 2>&1 || true
  docker exec "$CONTAINER" llama-server --help 2>&1 | head -100 || true
else
  echo "Container '$CONTAINER' is not running — showing help only."
  echo "Start it first with: ./01_up.sh"
fi