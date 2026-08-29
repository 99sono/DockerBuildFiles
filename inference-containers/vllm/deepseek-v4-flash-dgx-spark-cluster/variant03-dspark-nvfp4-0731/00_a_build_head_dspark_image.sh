#!/usr/bin/env bash
set -euo pipefail

# =============================================================================
# Variant03 — Build the DSpark runtime image for the HEAD node (this node only)
# =============================================================================
# Runs the shared build engine with WORKER_BUILD=0 so no image is pushed to the
# worker. Use on spark01 (head) when you only need this node's copy, or on any
# node that must build locally without touching the other one.
#
# To also build on the worker node in one go, use:
#   00_b_build_worker_dspark_image.sh   (WORKER_BUILD=1, needs WORKER_HOST in .env)
# =============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
export WORKER_BUILD=0
exec "$SCRIPT_DIR/00_build_dspark_image.sh"