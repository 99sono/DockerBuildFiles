#!/bin/bash
# =============================================================================
# 00_a_pull_vllm_image.sh
# =============================================================================
# Pull the vLLM Docker image for DGX Spark (ARM64).

set -euo pipefail

echo "🚀 Pulling latest vLLM image via Docker Compose..."
docker compose -f docker-compose.yml pull
echo "✅ Success: Image pulled."