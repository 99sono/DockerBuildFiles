#!/bin/bash
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../../../../commonScripts/lib.sh"
load_env

echo "=========================================="
echo "  Qwen3.8-27B (NVFP4) — SGLang Help"
echo "=========================================="
echo ""

CONTAINER="qwen-3.8-27b-sglang-5090"
if docker ps --format '{{.Names}}' | grep -q "^${CONTAINER}$"; then
  echo "Active container: $CONTAINER"
  echo "Dumping SGLang server version/help info..."
  echo ""
  docker exec "$CONTAINER" python -m sglang --version 2>&1 || true
  docker exec "$CONTAINER" sglang serve --help 2>&1 | head -100 || true
else
  echo "Container '$CONTAINER' is not running — showing help only."
  echo "Start it first with: ./01_up.sh"
fi
