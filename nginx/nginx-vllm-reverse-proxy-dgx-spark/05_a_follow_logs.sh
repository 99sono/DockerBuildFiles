#!/usr/bin/env bash
set -euo pipefail

# 05_a_follow_logs.sh
# Follow nginx container logs in real-time (like tail -f).
# Use this during development to monitor requests and errors live.

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

echo "Following nginx-proxy container logs (last 200 lines) ..."
echo "Press Ctrl+C to stop following."
echo "---------------------------------------------------"

docker compose --project-name vllm-https logs -f --tail=200