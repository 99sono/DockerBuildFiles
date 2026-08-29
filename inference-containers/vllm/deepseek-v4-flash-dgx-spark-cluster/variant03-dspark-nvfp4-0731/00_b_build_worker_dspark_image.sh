#!/usr/bin/env bash
set -euo pipefail

# =============================================================================
# Variant03 — Build the DSpark runtime image for the WORKER node
# =============================================================================
# Runs the shared build engine with WORKER_BUILD=1: builds on this node AND
# rsyncs the variant folder to WORKER_HOST and rebuilds there. Run from the
# head (spark01) to provision both nodes in one step.
#
# WORKER_HOST (SSH-able, e.g. "sono99@10.0.1.2") must be set in the shared .env
# or environment. For a local-only build use:
#   00_a_build_head_dspark_image.sh   (WORKER_BUILD=0)
# =============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
export WORKER_BUILD=1
exec "$SCRIPT_DIR/00_build_dspark_image.sh"