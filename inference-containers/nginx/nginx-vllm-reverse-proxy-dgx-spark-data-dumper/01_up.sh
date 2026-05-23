#!/usr/bin/env bash
set -euo pipefail

# ============================================================
# Configuration
# ============================================================
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"
source "$SCRIPT_DIR/00_env.sh"

# ============================================================
# Ensure logs directory has correct permissions for Lua scripts
# ============================================================
# The Nginx worker runs as 'nobody' and needs write access to create
# and append to log files. Since ./logs is a host-mounted volume,
# the directory must be world-writable for file creation, while
# specific files need targeted permissions.
mkdir -p ./logs
touch ./logs/requests.log ./logs/responses.log ./logs/access.log ./logs/error.log
chmod 777 ./logs                  # directory: world-accessible for file creation
chmod 666 ./logs/requests.log ./logs/responses.log  # Lua scripts: read+write
chmod 644 ./logs/access.log ./logs/error.log        # nginx master (root): owner read+write

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