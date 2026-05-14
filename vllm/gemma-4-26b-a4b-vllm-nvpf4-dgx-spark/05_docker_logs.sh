#!/bin/bash
# =============================================================================
# 05_docker_logs.sh
# =============================================================================
# View the Gemma 4 DGX Spark container logs in real-time.

set -euo pipefail

echo "📋 Watching container logs..."
docker compose -f docker-compose.yml logs -f --tail=100