#!/bin/bash
# =============================================================================
# 00_c_prepare_patches_and_ple.sh
# =============================================================================
# One-time preparation step:
# 1. Extracts baseline files from base image and generates overlay patches
# 2. Builds the packed memory-mapped PLE table (~27 GB) from downloaded weights
# =============================================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

MODEL_ID="nvidia/Qwen3.8-Flash-Next-NVFP4"
IMAGE="${VLLM_IMAGE:-vllm/vllm-openai:qwen38-flash-next}"
HF_CACHE_DIR="${HF_HOME:-$HOME/.cache/huggingface}"
ORG="${MODEL_ID%%/*}"
NAME="${MODEL_ID##*/}"
MODEL_PATH="$HF_CACHE_DIR/hub/models--${ORG}--${NAME}"

echo "=== Step 1: Checking Base Docker Image ==="
if ! docker image inspect "$IMAGE" &>/dev/null; then
    echo "📥 Pulling base image: $IMAGE ..."
    docker pull "$IMAGE"
fi

echo "=== Step 2: Preparing Patches ==="
VLLM_PKG="/usr/local/lib/python3.12/dist-packages/vllm"
PLE_PKG="$VLLM_PKG/models/qwen3_8_flash_next/nvidia/ple_layer.py"
MODELOPT_PKG="$VLLM_PKG/model_executor/layers/quantization/modelopt.py"
QSA_OPS_PKG="$VLLM_PKG/models/qwen3_8_flash_next/nvidia/ops/qsa.py"
QSA_NVIDIA_PKG="$VLLM_PKG/models/qwen3_8_flash_next/nvidia/qsa.py"
MTP_PKG="$VLLM_PKG/models/qwen3_8_flash_next/nvidia/mtp.py"
OFFLOAD_DIR="$SCRIPT_DIR/files/ple_offload"

mkdir -p "$SCRIPT_DIR/files" "$OFFLOAD_DIR/orig"

extract() { # <path-in-image> <dest>
    if [ ! -f "$2" ]; then
        echo "📦 Extracting $(basename "$1") from image..."
        local tmp
        tmp=$(docker create "$IMAGE" /bin/true)
        docker cp "$tmp:$1" "$2"
        docker rm "$tmp" >/dev/null 2>&1
    fi
}

extract "$PLE_PKG" "$SCRIPT_DIR/files/ple_layer_patched.py.orig"
python3 "$SCRIPT_DIR/files/patch_ple_layer.py"

extract "$MODELOPT_PKG" "$SCRIPT_DIR/files/modelopt_patched.py.orig"
python3 "$SCRIPT_DIR/files/patch_modelopt_mxfp8.py"

extract "$QSA_OPS_PKG" "$SCRIPT_DIR/files/qsa_ops_patched.py.orig"
extract "$QSA_NVIDIA_PKG" "$SCRIPT_DIR/files/qsa_nvidia_patched.py.orig"
python3 "$SCRIPT_DIR/files/patch_qsa_fp8_kv.py"

extract "$MTP_PKG" "$SCRIPT_DIR/files/mtp_patched.py.orig"
python3 "$SCRIPT_DIR/files/patch_mtp_draft_vocab.py"

for f in ple_offload_layer connector worker protocol; do
    case "$f" in
        ple_offload_layer) src="$VLLM_PKG/model_executor/layers/ple_offload_layer.py" ;;
        *)                 src="$VLLM_PKG/v1/ple_offload/$f.py" ;;
    esac
    extract "$src" "$OFFLOAD_DIR/orig/$f.py"
done
python3 "$SCRIPT_DIR/files/patch_ple_offload.py"
echo "✅ All patches prepared."

echo "=== Step 3: Checking / Building Packed PLE Table ==="
PLE_CACHE_HOST="$HOME/.cache/vllm/ple_cache/${ORG}--${NAME}"
mkdir -p "$PLE_CACHE_HOST"

if ! ls "$PLE_CACHE_HOST"/*.packed_u8 >/dev/null 2>&1; then
    if [ ! -d "$MODEL_PATH/snapshots" ]; then
        echo "⚠️  Model snapshot not found at $MODEL_PATH/snapshots. Please run ./00_b_pre_download_model.sh first!"
        exit 1
    fi
    SNAPSHOT_REL=$(ls "$MODEL_PATH/snapshots" 2>/dev/null | head -1 || true)
    if [ -z "$SNAPSHOT_REL" ]; then
        echo "⚠️  No snapshot found in $MODEL_PATH/snapshots!"
        exit 1
    fi
    echo "🔨 Building packed PLE table (one-time operation, ~40 s, <1 GiB RAM)..."
    docker run --rm --name "plebuild-${NAME}" --memory 8g --cpus 8 \
        -v "$MODEL_PATH:/m:ro" -v "$HOME/.cache/vllm/ple_cache:/out" \
        -v "$SCRIPT_DIR/files/build_ple_packed_table.py:/b.py:ro" \
        --entrypoint python3 "$IMAGE" -u /b.py "/m/$SNAPSHOT_REL" "/out/${ORG}--${NAME}"
fi

echo "✅ Packed PLE table verified: $(ls "$PLE_CACHE_HOST"/*.packed_u8 | head -1)"
