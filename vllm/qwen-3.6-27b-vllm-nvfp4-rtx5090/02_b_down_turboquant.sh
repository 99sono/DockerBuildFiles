#!/bin/bash
# =============================================================================
# 02_b_down_turboquant.sh
# =============================================================================

set -euo pipefail

echo "🛑 Stopping TURBOQUANT Qwen 3.6 NVFP4 MTP server..."

docker compose -f docker-compose-turboquant.yml down
