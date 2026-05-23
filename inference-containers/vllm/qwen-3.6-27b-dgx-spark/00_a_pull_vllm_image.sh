#!/bin/bash
# =============================================================================
# 00_a_pull_vllm_image.sh
# Pulls the vLLM Docker image for this configuration
# =============================================================================

set -euo pipefail

echo "Pulling latest vLLM images via Docker Compose..."
docker compose -f docker-compose.yml pull
echo "Success: Images pulled."