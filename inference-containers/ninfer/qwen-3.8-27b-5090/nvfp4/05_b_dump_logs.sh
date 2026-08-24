#!/bin/bash
# =============================================================================
# 05_b_dump_logs.sh — Dump NInfer container logs to timestamped file
# =============================================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TIMESTAMP=$(date +"%Y-%m-%d_%H-%M-%S")
CONTAINER="qwen-3.8-27b-ninfer-5090"
OUT_FILE="${SCRIPT_DIR}/${TIMESTAMP}_${CONTAINER}_log_dump.txt"

echo "Dumping logs for container: ${CONTAINER}"
docker logs "${CONTAINER}" > "${OUT_FILE}" 2>&1
echo "Logs written to: ${OUT_FILE}"
