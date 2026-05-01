#!/bin/bash
# =============================================================================
# 02_a_down_normal.sh
# =============================================================================

set -euo pipefail

echo "🛑 Stopping NORMAL Qwen 3.6 NVFP4 MTP server..."

docker compose -f docker-compose.yml down
