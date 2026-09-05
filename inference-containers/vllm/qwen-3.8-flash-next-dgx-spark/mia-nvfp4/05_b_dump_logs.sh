#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../../../../commonScripts/lib.sh"
load_env

CONTAINER="qwen38-flash-next-mia-nvfp4"
DATE_STR=$(date +%Y-%m-%d)
DATE_DIR="${SCRIPT_DIR}/metadata/${DATE_STR}"
mkdir -p "$DATE_DIR"

OUTPUT_FILE="${1:-${DATE_DIR}/01_vllm_log.txt}"

# Dump container logs with sensitive masking
docker_logs_dump_container "$CONTAINER" "$OUTPUT_FILE"

# Additional security check: explicitly scrub any occurrence of INFERENCE_API_KEY
if [[ -n "${INFERENCE_API_KEY:-}" ]]; then
  sed -i "s/${INFERENCE_API_KEY}/dummy-key/g" "$OUTPUT_FILE"
fi

# Mirror to parent metadata directory so parser can find it at either scope
PARENT_METADATA_DIR="${SCRIPT_DIR}/../metadata/${DATE_STR}"
mkdir -p "$PARENT_METADATA_DIR"
cp "$OUTPUT_FILE" "${PARENT_METADATA_DIR}/01_vllm_log.txt"

# Verify password did not leak
if [[ -n "${INFERENCE_API_KEY:-}" ]] && (grep -F -q "$INFERENCE_API_KEY" "$OUTPUT_FILE" || grep -F -q "$INFERENCE_API_KEY" "${PARENT_METADATA_DIR}/01_vllm_log.txt"); then
  echo "❌ CRITICAL: Password leak detected! Aborting." >&2
  rm -f "$OUTPUT_FILE" "${PARENT_METADATA_DIR}/01_vllm_log.txt"
  exit 1
fi

echo "✅ Verified clean of passwords. Log saved to:"
echo "   - $OUTPUT_FILE"
echo "   - ${PARENT_METADATA_DIR}/01_vllm_log.txt"
echo ""
echo "First 20 lines (preview):"
echo "---------------------------------------------------"
head -n 20 "$OUTPUT_FILE"

