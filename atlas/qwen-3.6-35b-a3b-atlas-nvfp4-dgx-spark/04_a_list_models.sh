#!/usr/bin/env bash
set -euo pipefail

# =============================================================================
# 04_a_list_models.sh - List available models on Atlas server
# =============================================================================
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if [ -f "$SCRIPT_DIR/.env" ]; then
    export $(grep -v '^#' "$SCRIPT_DIR/.env" | xargs)
fi

ATLAS_API_KEY="${ATLAS_API_KEY:-dummy-key}"

echo "📋 Listing models on Atlas server..."
echo "   URL       : http://localhost:8000/v1/models"
echo "   API Key   : ${ATLAS_API_KEY:0:4}...${ATLAS_API_KEY: -4}"
echo "------------------------------------------------------------"

curl -s http://localhost:8000/v1/models \
  -H "Authorization: Bearer $ATLAS_API_KEY" | python3 -m json.tool

echo ""
echo "✅ Done."
