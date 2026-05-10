#!/usr/bin/env bash
set -euo pipefail

# ============================================================
# Configuration
# ============================================================
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"
source "$SCRIPT_DIR/00_env.sh"

# ============================================================
# Main: Follow nginx container logs in real-time
# (like tail -f, shows last 200 lines)
# ============================================================
echo "Following $NGINX_CONTAINER_NAME container logs (last 200 lines) ..."
echo "Press Ctrl+C to stop following."
echo "---------------------------------------------------"

docker compose --project-name "$PROJECT_NAME" logs -f --tail=200