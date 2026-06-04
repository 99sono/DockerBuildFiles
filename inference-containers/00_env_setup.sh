#!/bin/bash
# =============================================================================
# 00_env_setup.sh — Initialize .env files with proper permissions across all
#                   inference-container projects.
#
# Recursively walks every project directory under inference-containers/:
#   - Copies .env.example → .env if .env is missing (gitignored)
#   - Ensures .env and .env.example are owner-read-only (mode 600)
#
# Why 600? .env files contain secrets (API keys, tokens). Restricting to
# owner-read/write prevents other users on shared systems from reading them.
# =============================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECTS_ROOT="$SCRIPT_DIR"

COPIED=0
PERMS_FIXED=0
EXISTS=0

# Find every .env.example file recursively (handles nested projects like
# vllm/qwen-3.6-35b-dgx-spark/nvidia-nvfp4/.env.example)
while IFS= read -r example_file; do
  project_dir="$(dirname "$example_file")"
  env_file="$project_dir/.env"

  # If .env doesn't exist yet, copy from the template
  if [ -f "$env_file" ]; then
    EXISTS=$((EXISTS + 1))
  else
    cp "$example_file" "$env_file"
    echo "   copied: $env_file"
    COPIED=$((COPIED + 1))
  fi

  # Force 600 on .env (owner read/write only) — secrets protection
  current_perms=$(stat -c "%a" "$env_file")
  if [ "$current_perms" != "600" ]; then
    chmod 600 "$env_file"
    PERMS_FIXED=$((PERMS_FIXED + 1))
  fi

  # Force 600 on .env.example too — same file, template may contain real values
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
