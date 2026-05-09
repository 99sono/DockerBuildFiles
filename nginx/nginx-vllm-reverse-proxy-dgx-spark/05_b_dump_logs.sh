#!/usr/bin/env bash
set -euo pipefail

# 05_b_dump_logs.sh
# Dump nginx container logs to a local file for analysis.
# Use this to capture a snapshot of logs for debugging or review.

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

echo "Dumping nginx-proxy container logs ..."

docker logs nginx-proxy > nginx_logs_dump.txt 2>&1

echo "Done! Logs saved to nginx_logs_dump.txt"
echo "Last 20 lines:"
echo "---------------------------------------------------"
tail -n 20 nginx_logs_dump.txt