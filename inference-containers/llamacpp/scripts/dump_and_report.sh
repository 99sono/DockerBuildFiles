#!/bin/bash
# =============================================================================
# dump_and_report.sh — dump llama.cpp container logs, then build a markdown
# performance report from them.
#
# Usage:
#   ./dump_and_report.sh [CONTAINER]
#     CONTAINER   docker container name (default: qwen-3.8-27b-5090)
#
# Writes into the CURRENT WORKING DIRECTORY:
#   <TIMESTAMP>_<CONTAINER>_log_dump.txt   (timestamped log dump, masked)
#   <TIMESTAMP>_<CONTAINER>_log_report.md  (markdown performance report)
#
# Requires: a running container (docker), python3.
# =============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/../../../commonScripts/lib.sh"
load_env

CONTAINER="${1:-qwen-3.8-27b-5090}"
TIMESTAMP="$(date +%Y-%m-%d_%H-%M-%S)"
OUTPUT_FILE="${TIMESTAMP}_${CONTAINER}_log_dump.txt"
REPORT_FILE="${TIMESTAMP}_${CONTAINER}_log_report.md"

echo ">> Dumping logs from container '$CONTAINER'..."
docker_logs_dump_container "$CONTAINER" "$OUTPUT_FILE"

echo ""
echo ">> Generating markdown report..."
python3 "$SCRIPT_DIR/parse_llamacpp_log.py" "$OUTPUT_FILE" > "$REPORT_FILE"

echo ""
echo "Done."
echo "  Log dump : $OUTPUT_FILE"
echo "  Report   : $REPORT_FILE"
