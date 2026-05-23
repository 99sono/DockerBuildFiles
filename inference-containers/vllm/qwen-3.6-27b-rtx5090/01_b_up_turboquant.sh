#!/bin/bash
# =============================================================================
# 01_b_up_turboquant.sh
# =============================================================================

set -euo pipefail

echo "🚀 Starting TURBOQUANT Qwen 3.6 NVFP4 MTP setup (k8v4 Compression, 256K Context)..."

# Ensure common network exists
../../commonScripts/create_development_network.sh

docker compose -f docker-compose-turboquant.yml up -d

echo ""
echo "✅ TurboQuant server started in background."
echo "📺 Monitor logs with: docker logs -f qwen-3-6-27b-nvfp4-mtp-turbo"
echo "🧪 Test with: ./04_test_vllm_curl.py"
