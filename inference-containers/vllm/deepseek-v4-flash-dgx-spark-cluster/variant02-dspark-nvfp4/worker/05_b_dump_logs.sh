#!/bin/bash
# Dump worker container logs to a timestamped file in metadata/ for analysis.
# Non-following snapshot — full log, no truncation.
# Sensitive values (api_key) are masked with "dummy-key" before writing.
# Use 05_a_follow_logs.sh for live tail instead.

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../../../../../commonScripts/lib.sh"
load_env

CONTAINER="deepseek-v4-flash-dspark-worker"
TIMESTAMP=$(date +"%Y-%m-%d_%H-%M-%S")
DATE_STR=$(date +%Y-%m-%d)
METADATA_DIR="${SCRIPT_DIR}/metadata/${DATE_STR}"
mkdir -p "$METADATA_DIR"
OUTPUT_FILE="${METADATA_DIR}/${TIMESTAMP}_${CONTAINER}_log_dump.txt"

docker_logs_dump_container "$CONTAINER" "$OUTPUT_FILE"

# Additional security check: explicitly scrub any occurrence of INFERENCE_API_KEY
if [[ -n "${INFERENCE_API_KEY:-}" ]] && [[ "${INFERENCE_API_KEY}" != "dummy-key" ]]; then
  sed -i "s/${INFERENCE_API_KEY}/dummy-key/g" "$OUTPUT_FILE"
fi

# Fail-safe assertion: delete the dump and abort if the key survived every mask
if [[ -n "${INFERENCE_API_KEY:-}" ]] && [[ "${INFERENCE_API_KEY}" != "dummy-key" ]] \
   && grep -F -q -- "$INFERENCE_API_KEY" "$OUTPUT_FILE"; then
  echo "❌ CRITICAL: API key leak detected in $OUTPUT_FILE — deleting dump." >&2
  rm -f "$OUTPUT_FILE"
  exit 1
fi

echo ""
echo "First 20 lines (preview):"
echo "---------------------------------------------------"
head -n 20 "$OUTPUT_FILE"
