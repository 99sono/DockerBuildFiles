#!/bin/bash
# =============================================================================
# 00_env_setup.sh — Initialize .env files with proper permissions across all
#                   inference-container projects.
#
# Recursively walks every project directory under inference-containers/:
#   - Copies .env.example → .env if .env is missing (gitignored)
#   - Ensures .env and .env.example are owner-read-only (mode 600)
# =============================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECTS_ROOT="$SCRIPT_DIR"

COPIED=0
PERMS_FIXED=0
EXISTS=0

while IFS= read -r example_file; do
  project_dir="$(dirname "$example_file")"
  env_file="$project_dir/.env"

  if [ -f "$env_file" ]; then
    EXISTS=$((EXISTS + 1))
  else
    cp "$example_file" "$env_file"
    echo "   copied: $env_file"
    COPIED=$((COPIED + 1))
  fi

  # Force 600 on both files (owner read/write only).
  current_perms=$(stat -c "%a" "$env_file")
  if [ "$current_perms" != "600" ]; then
    chmod 600 "$env_file"
    PERMS_FIXED=$((PERMS_FIXED + 1))
  fi

  example_perms=$(stat -c "%a" "$example_file")
  if [ "$example_perms" != "600" ]; then
    chmod 600 "$example_file"
    PERMS_FIXED=$((PERMS_FIXED + 1))
  fi
done < <(find "$PROJECTS_ROOT" -name ".env.example" -type f)

echo ""
echo "=== .env Setup Summary ==="
echo "   Already exists : $EXISTS"
echo "   Copied from example: $COPIED"
echo "   Permissions fixed : $PERMS_FIXED"
echo ""
echo "=== .env Setup Summary ==="
echo "   Already exists : $EXISTS"
echo "   Copied from example: $COPIED"
echo "   Permissions fixed : $PERMS_FIXED"
echo ""
