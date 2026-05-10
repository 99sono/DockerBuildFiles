#!/usr/bin/env bash
set -euo pipefail

# ============================================================
# Configuration
# ============================================================
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"
source "$SCRIPT_DIR/00_env.sh"

# ============================================================
# Main: Stop and remove the debug proxy container
# ============================================================
echo "Stopping debug proxy ..."
docker compose -f "$SCRIPT_DIR/docker-compose.debug.yml" down

echo "Debug proxy stopped."