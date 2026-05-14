#!/bin/bash
# =============================================================================
# 02_down.sh
# =============================================================================
# Stop the Gemma 4 DGX Spark vLLM server.

set -euo pipefail

echo "🛑 Stopping Gemma-4 DGX Spark..."
docker compose -f docker-compose.yml down

echo "✅ Server stopped."