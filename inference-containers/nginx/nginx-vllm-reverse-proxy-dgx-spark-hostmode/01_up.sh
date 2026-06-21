#!/usr/bin/env bash
set -euo pipefail

# ============================================================
# Configuration
# ============================================================
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"
source "$SCRIPT_DIR/00_env.sh"

# ============================================================
# Main: Start the docker compose stack in detached mode
# (no --wait since host network mode doesn't support health checks)
# ============================================================
docker compose --project-name "$PROJECT_NAME" up -d