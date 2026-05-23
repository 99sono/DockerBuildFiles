#!/bin/bash
# =============================================================================
# 03_enter_container.sh
# =============================================================================
# Enter the Gemma 4 DGX Spark container shell.

set -euo pipefail

echo "🔑 Entering container gemma-4-26b-it-nvfp4-spark..."
docker exec -it gemma-4-26b-it-nvfp4-spark bash