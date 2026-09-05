#!/bin/bash
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../../../../../commonScripts/lib.sh"
load_env
cd "$SCRIPT_DIR"

DATE_STR=$(date +%Y-%m-%d)
DUMP_DIR="$SCRIPT_DIR/metadata/$DATE_STR"
mkdir -p "$DUMP_DIR"

DUMP_FILE="$DUMP_DIR/01_vllm_head_log.txt"
echo "Dumping docker logs to $DUMP_FILE ..."
docker logs qwen38-flash-next-head 2>&1 | sed -E 's/(Bearer |api-key[:= ]+)[A-Za-z0-9_-]{10,}/\1[REDACTED]/g' > "$DUMP_FILE"
echo "Done ($(wc -l < "$DUMP_FILE") lines)."
