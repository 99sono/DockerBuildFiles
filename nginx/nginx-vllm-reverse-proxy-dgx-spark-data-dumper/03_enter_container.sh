#!/usr/bin/env bash
set -euo pipefail

# ============================================================
# Configuration
# ============================================================
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"
source "$SCRIPT_DIR/00_env.sh"

# ============================================================
# Main: Enter the debug proxy container with an interactive bash shell
# ============================================================
echo "Entering debug proxy container '$DEBUG_CONTAINER_NAME' ..."
docker exec -it "$DEBUG_CONTAINER_NAME" /bin/bash