#!/bin/bash
# =============================================================================
# 06_dump_vllm_help.sh
# Dumps the help output of the vLLM serve command to help identify valid flags.
# =============================================================================

IMAGE="vllm/vllm-openai:nightly"
OUTPUT_FILE="vllm_serve_help.txt"

echo "🔍 Pulling and running help for $IMAGE..."

# Run the help command and capture to both terminal and file
docker run --rm --gpus all "$IMAGE" serve --help=all > "$OUTPUT_FILE" 2>&1

echo "✅ Help output saved to: $OUTPUT_FILE"
echo "------------------------------------------------"
echo "Top 50 lines of help output:"
head -n 50 "$OUTPUT_FILE"
