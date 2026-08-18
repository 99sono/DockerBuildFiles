#!/usr/bin/env bash
set -euo pipefail

# =============================================================================
# Variant03 — Build DSpark NVFP4 Stage C runtime image (DeepSeek-V4-Flash-0731)
# =============================================================================
# Distinct image tags from variant02 so both images can coexist on a node:
#   base overlay  -> vllm-dspark-runtime:mia-raf-pr1-0731
#   stage A/B/C   -> ...-nvfp4-a / -nvfp4-b
#   final         -> vllm-dspark-runtime:dspark-nvfp4-stage-c-0731
#
# The overlay already carries Patch 4 (shared-experts gate_up_proj) baked in,
# which is the 0731 speedup. Verify with:
#   grep -n shared_experts.gate_up_proj recipe/overlay/vllm/v1/spec_decode/dspark.py
# =============================================================================

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
RECIPE_DIR="$SCRIPT_DIR/recipe"

DSPARK_VLLM_IMAGE="${DSPARK_VLLM_IMAGE:-vllm-dspark-runtime:dspark-nvfp4-stage-c-0731}"
DSPARK_BASE_IMAGE="${DSPARK_BASE_IMAGE:-vllm-dspark-runtime:mia-raf-pr1-0731}"
WORKER_BUILD="${WORKER_BUILD:-1}"

if [ -f "$SCRIPT_DIR/.env" ]; then
  set -a
  source "$SCRIPT_DIR/.env"
  set +a
fi

# Verify overlay sources exist
bash "$RECIPE_DIR/verify-overlay-sources.sh" \
  "$RECIPE_DIR/Dockerfile.dspark-runtime-overlay" \
  "$RECIPE_DIR/overlay"

# Sanity: Patch 4 must be baked into the overlay (0731 speedup)
if ! grep -q "shared_experts.gate_up_proj" "$RECIPE_DIR/overlay/vllm/v1/spec_decode/dspark.py"; then
  echo "ERROR: Patch 4 (shared_experts.gate_up_proj) missing from overlay — 0731 would run at half speed." >&2
  exit 1
fi

build_local() {
  echo "=== Stage 1: Base DSpark overlay ($DSPARK_BASE_IMAGE) ==="
  docker build \
    -f "$RECIPE_DIR/Dockerfile.dspark-runtime-overlay" \
    -t "$DSPARK_BASE_IMAGE" \
    "$RECIPE_DIR/overlay"

  docker run --rm --entrypoint /opt/env/bin/python "$DSPARK_BASE_IMAGE" -c \
    "import vllm.v1.spec_decode.dspark as d; import vllm.v1.spec_decode.dspark_proposer as p; print('dspark overlay ok', d.__name__, p.__name__)"

  echo "=== Stage 2: NVFP4 Stage A (dtype plumbing) ==="
  docker build \
    --build-arg BASE_IMAGE="$DSPARK_BASE_IMAGE" \
    -f "$RECIPE_DIR/nvfp4/Dockerfile.stage-a" \
    -t "$DSPARK_BASE_IMAGE-nvfp4-a" \
    "$SCRIPT_DIR"

  echo "=== Stage 3: NVFP4 Stage B (probe path) ==="
  docker build \
    --build-arg BASE_IMAGE="$DSPARK_BASE_IMAGE-nvfp4-a" \
    -f "$RECIPE_DIR/nvfp4/Dockerfile.stage-b" \
    -t "$DSPARK_BASE_IMAGE-nvfp4-b" \
    "$SCRIPT_DIR"

  echo "=== Stage 4: NVFP4 Stage C (padded envelope) ==="
  docker build \
    --build-arg BASE_IMAGE="$DSPARK_BASE_IMAGE-nvfp4-b" \
    -f "$RECIPE_DIR/nvfp4/Dockerfile.stage-c" \
    -t "$DSPARK_VLLM_IMAGE" \
    "$SCRIPT_DIR"

  docker run --rm --entrypoint /opt/env/bin/python "$DSPARK_VLLM_IMAGE" -c \
    "import vllm; print('dspark nvfp4 stage-c 0731 image ok', vllm.__version__)"

  # Import-check the new overlay modules (mirrors the Dockerfile RUN check)
  docker run --rm --entrypoint /opt/env/bin/python "$DSPARK_VLLM_IMAGE" -c \
    "import vllm.tool_parsers.deepseekv32_tool_parser as t; print('deepseekv32_tool_parser ok', t.DeepSeekV32ToolParser.__name__)"
}

build_worker() {
  local worker_host="${1:?WORKER_HOST required}"
  local checkout="$2"
  echo "=== Building on worker: $worker_host ==="
  ssh "$worker_host" "mkdir -p '$checkout'"
  rsync -az --delete "$SCRIPT_DIR/" "$worker_host:$checkout/"
  ssh "$worker_host" "cd '$checkout' && DSPARK_BASE_IMAGE='$DSPARK_BASE_IMAGE' DSPARK_VLLM_IMAGE='$DSPARK_VLLM_IMAGE' WORKER_BUILD=0 ./00_a_build_dspark_image.sh"
}

echo "============================================"
echo " Building DSpark NVFP4 Stage C Runtime Image"
echo " (DeepSeek-V4-Flash-0731, Patch 4 baked in)"
echo "============================================"

build_local "$SCRIPT_DIR"

if [ "$WORKER_BUILD" = "1" ]; then
  : "${WORKER_HOST:?WORKER_HOST must be set in .env or environment}"
  build_worker "$WORKER_HOST" "${WORKER_SCRIPT_DIR:-${WORKER_DIR:-$SCRIPT_DIR}}"
fi

echo ""
echo "DSpark image build complete: $DSPARK_VLLM_IMAGE"