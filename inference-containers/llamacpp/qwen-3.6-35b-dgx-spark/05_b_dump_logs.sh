#!/bin/bash
# Dump container logs to a timestamped file for analysis.
# Non-following snapshot — full log, no truncation.
# Sensitive values (api_key) are masked with "dummy-key" before writing.
# Use 05_a_follow_logs.sh for live tail instead.

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../../../commonScripts/lib.sh"
load_env

CONTAINER="qwen-3.6-35b-mtp-dgx-spark"
TIMESTAMP=$(date +"%Y-%m-%d_%H-%M-%S")
OUTPUT_FILE="${SCRIPT_DIR}/${TIMESTAMP}_${CONTAINER}_log_dump.txt"

docker_logs_dump_container "$CONTAINER" "$OUTPUT_FILE"

echo ""
echo "First 20 lines (preview):"
echo "---------------------------------------------------"
head -n 20 "$OUTPUT_FILE"
