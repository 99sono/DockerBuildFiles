#!/bin/bash
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../../../../commonScripts/lib.sh"
load_env
CONTAINER="qwopus36-35b-mtp-dgx-spark"
TIMESTAMP=$(date +"%Y-%m-%d_%H-%M-%S")
OUTPUT_FILE="${SCRIPT_DIR}/${TIMESTAMP}_${CONTAINER}_log_dump.txt"
docker_logs_dump_container "$CONTAINER" "$OUTPUT_FILE"
echo ""
echo "First 20 lines (preview):"
echo "---------------------------------------------------"
head -n 20 "$OUTPUT_FILE"
