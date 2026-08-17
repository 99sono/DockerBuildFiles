#!/bin/bash
# Dump container logs to a timestamped file, then generate a markdown
# performance report from them via the shared llama.cpp log parser
# (inference-containers/llamacpp/scripts/parse_llamacpp_log.py).
# Non-following snapshot — full log, no truncation.
# Sensitive values (api_key) are masked with "dummy-key" before writing.
# Use 05_a_follow_logs.sh for live tail instead.

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../../../../commonScripts/lib.sh"
load_env

CONTAINER="qwen-3.8-27b-5090"
TIMESTAMP=$(date +"%Y-%m-%d_%H-%M-%S")
OUTPUT_FILE="${SCRIPT_DIR}/${TIMESTAMP}_${CONTAINER}_log_dump.txt"
REPORT_FILE="${SCRIPT_DIR}/${TIMESTAMP}_${CONTAINER}_log_report.md"
PARSER="$(cd "$SCRIPT_DIR/../../../../inference-containers/llamacpp/scripts" && pwd)/parse_llamacpp_log.py"

docker_logs_dump_container "$CONTAINER" "$OUTPUT_FILE"

echo ""
echo "First 20 lines (preview):"
echo "---------------------------------------------------"
head -n 20 "$OUTPUT_FILE"

echo ""
echo ">> Generating performance report..."
python3 "$PARSER" "$OUTPUT_FILE" > "$REPORT_FILE"
echo "  Report : $REPORT_FILE"
