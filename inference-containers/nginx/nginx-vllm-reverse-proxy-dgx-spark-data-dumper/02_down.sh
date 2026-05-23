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

# ============================================================
# Optional: Clear captured log files for privacy/cleanup
# ============================================================
echo ""
echo "Would you like to clear captured log files? [y/N]"
read -r response
if [[ "$response" =~ ^([yY][eE][sS]|[yY])$ ]]; then
  rm -f ./logs/requests.log ./logs/responses.log ./logs/access.log ./logs/error.log
  echo "Captured logs cleared."
else
  echo "Log files preserved in ./logs/."
fi

echo "Debug proxy stopped."
