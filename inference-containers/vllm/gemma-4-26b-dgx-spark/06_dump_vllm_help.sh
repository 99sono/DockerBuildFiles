#!/bin/bash
# =============================================================================
# 06_dump_vllm_help.sh
# =============================================================================
# Dump the vLLM serve --help output from the running container.

set -euo pipefail

echo "📖 Dumping vLLM serve --help output..."
docker exec -it gemma-4-26b-it-nvfp4-spark vllm serve --help