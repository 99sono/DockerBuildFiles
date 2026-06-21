#!/bin/bash
# Dump worker container logs to a timestamped file in metadata/ for analysis.
# Non-following snapshot — full log, no truncation.
# Sensitive values (api_key) are masked with "dummy-key" before writing.
# Use 05_a_follow_logs.sh for live tail instead.

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../../../../commonScripts/lib.sh"
load_env

CONTAINER="deepseek-v4-flash-worker"
TIMESTAMP=$(date +"%Y-%m-%d_%H-%M-%S")
METADATA_DIR="${SCRIPT_DIR}/../metadata"
mkdir -p "$METADATA_DIR"
OUTPUT_FILE="${METADATA_DIR}/${TIMESTAMP}_${CONTAINER}_log_dump.txt"

docker_logs_dump_container "$CONTAINER" "$OUTPUT_FILE"

echo ""
echo "First 20 lines (preview):"
echo "---------------------------------------------------"
head -n 20 "$OUTPUT_FILE"
