#!/bin/bash
# =============================================================================
# 01_up.sh
# =============================================================================
# Start the Gemma 4 DGX Spark vLLM server.

set -euo pipefail

echo "🚀 Starting Gemma-4 DGX Spark setup (NVFP4, ARM64)..."
docker compose -f docker-compose.yml up -d

echo "------------------------------------------------"
echo "Server is initializing. Monitor logs with: ./05_docker_logs.sh"