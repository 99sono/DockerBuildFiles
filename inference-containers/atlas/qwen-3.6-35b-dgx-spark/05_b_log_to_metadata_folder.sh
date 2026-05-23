#!/bin/bash
# Dump Atlas container logs to a timestamped file in metadata/
# Non-following snapshot for debugging sessions.
# Use 05_docker_logs.sh for live tail instead.

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
METADATA_DIR="${SCRIPT_DIR}/metadata"
CONTAINER="qwen-3-6-35b-a3b-nvfp4-atlas"
TIMESTAMP=$(date +"%Y-%m-%d_%H-%M-%S")
LOG_FILE="${METADATA_DIR}/${TIMESTAMP}_atlas_log.txt"

if ! docker ps --format '{{.Names}}' | grep -q "^${CONTAINER}$"; then
    echo "❌ Container '${CONTAINER}' is not running."
    exit 1
fi

mkdir -p "${METADATA_DIR}"

echo "📋 Dumping logs for '${CONTAINER}'..."
docker logs "${CONTAINER}" > "${LOG_FILE}" 2>&1

LINE_COUNT=$(wc -l < "${LOG_FILE}")
FILE_SIZE=$(du -h "${LOG_FILE}" | cut -f1)

echo ""
echo "   File      : ${LOG_FILE}"
echo "   Lines     : ${LINE_COUNT}"
echo "   Size      : ${FILE_SIZE}"
echo ""
echo "✅ Done."
