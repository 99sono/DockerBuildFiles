#!/usr/bin/env bash
set -euo pipefail

# ============================================================
# Configuration
# ============================================================
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"
source "$SCRIPT_DIR/00_env.sh"

# ============================================================
# Main: Follow debug response logs in real-time
# ============================================================
LOG_FILE="$SCRIPT_DIR/logs/responses.log"

if [[ ! -f "$LOG_FILE" ]]; then
    echo "Warning: $LOG_FILE not found. Start the debug proxy first with ./01_up.sh"
    exit 1
fi

echo "Following responses.log (press Ctrl+C to stop) ..."
tail -f "$LOG_FILE"