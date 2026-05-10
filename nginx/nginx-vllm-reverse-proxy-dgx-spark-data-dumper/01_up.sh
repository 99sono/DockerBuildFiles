#!/usr/bin/env bash
set -euo pipefail

# ============================================================
# Configuration
# ============================================================
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"
source "$SCRIPT_DIR/00_env.sh"

# ============================================================
# Main: Start the debug proxy in detached mode
# ============================================================
echo "Starting debug proxy on port $DEBUG_PROXY_PORT ..."
docker compose -f "$SCRIPT_DIR/docker-compose.debug.yml" up -d

echo "Done. Debug proxy is running."
echo "  Container: $DEBUG_CONTAINER_NAME"
echo "  URL: http://$(hostname):$DEBUG_PROXY_PORT"
echo ""
echo "View requests:  ./04_follow_requests.sh"
echo "View responses: ./05_follow_responses.sh"