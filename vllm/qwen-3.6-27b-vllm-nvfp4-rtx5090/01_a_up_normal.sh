#!/bin/bash
# =============================================================================
# 01_a_up_normal.sh
# =============================================================================

set -euo pipefail

echo "🚀 Starting NORMAL Qwen 3.6 NVFP4 MTP setup (FP8 KV Cache, 128K Context)..."

# Ensure common network exists
../../commonScripts/create_development_network.sh

docker compose -f docker-compose.yml up -d

echo ""
echo "✅ Server started in background."
echo "📺 Monitor logs with: ./05_docker_logs.sh"
echo "🧪 Test with: ./04_test_vllm_curl.py"
