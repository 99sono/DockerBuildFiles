#!/bin/bash
# =============================================================================
# 00_a_prepare_patches.sh
# =============================================================================
# Dual DGX Spark Cluster (Mia AI Lab NVFP4 Recipe)
#
# Extracts baseline files from base image and generates overlay patches:
# 1. ple_layer.py: Mixed NVFP4/FP8 PLE dispatch
# 2. modelopt.py: MXFP8 fallback + FP8_BLOCK_SCALES MoE routing for MTP
# 3. qsa_ops / qsa_nvidia: FP8 KV cache support for QSA sparse attention
# 4. mtp.py: MTP drafting support
# 5. config.json / hf_quant_config.json: Absolute-index MTP aliases (if needed)
# =============================================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

IMAGE="${VLLM_IMAGE:-vllm/vllm-openai:qwen38-flash-next}"
FILES_DIR="$SCRIPT_DIR/files"

echo "=== Step 1: Checking Base Docker Image ($IMAGE) ==="
if ! docker image inspect "$IMAGE" &>/dev/null; then
    echo "📥 Pulling base image: $IMAGE ..."
    docker pull "$IMAGE"
fi
echo "✅ Docker image verified: $IMAGE"

echo "=== Step 2: Extracting and Generating Overlay Patches ==="
VLLM_PKG="/usr/local/lib/python3.12/dist-packages/vllm"
PLE_PKG="$VLLM_PKG/models/qwen3_8_flash_next/nvidia/ple_layer.py"
MODELOPT_PKG="$VLLM_PKG/model_executor/layers/quantization/modelopt.py"
QSA_OPS_PKG="$VLLM_PKG/models/qwen3_8_flash_next/nvidia/ops/qsa.py"
QSA_NVIDIA_PKG="$VLLM_PKG/models/qwen3_8_flash_next/nvidia/qsa.py"
MTP_PKG="$VLLM_PKG/models/qwen3_8_flash_next/nvidia/mtp.py"

extract() { # <path-in-image> <dest>
    if [ ! -f "$2" ]; then
        echo "📦 Extracting $(basename "$1") from image..."
        local tmp
        tmp=$(docker create "$IMAGE" /bin/true)
        docker cp "$tmp:$1" "$2"
        docker rm "$tmp" >/dev/null 2>&1
    fi
}

mkdir -p "$FILES_DIR"

# 1. PLE Layer Patch
extract "$PLE_PKG" "$FILES_DIR/ple_layer_patched.py.orig"
python3 "$FILES_DIR/patch_ple_layer.py"
echo "✅ ple_layer patch ready"

# 2. ModelOpt Patch (MXFP8 fallback + FP8_BLOCK_SCALES MoE routing)
extract "$MODELOPT_PKG" "$FILES_DIR/modelopt_patched.py.orig"
python3 "$FILES_DIR/patch_modelopt_mxfp8.py"
python3 "$FILES_DIR/patch_modelopt_fp8_block_moe.py"
echo "✅ modelopt patch ready (MXFP8 fallback + FP8_BLOCK_SCALES MoE)"

# 3. QSA FP8 KV Cache Patch
extract "$QSA_OPS_PKG" "$FILES_DIR/qsa_ops_patched.py.orig"
extract "$QSA_NVIDIA_PKG" "$FILES_DIR/qsa_nvidia_patched.py.orig"
python3 "$FILES_DIR/patch_qsa_fp8_kv.py"
echo "✅ QSA FP8 KV cache patch ready"

# 4. MTP Reduced Draft Vocab Patch
extract "$MTP_PKG" "$FILES_DIR/mtp_patched.py.orig"
python3 "$FILES_DIR/patch_mtp_draft_vocab.py"
echo "✅ MTP draft patch ready"

# 5. Checkpoint Config Aliasing for MTP
HF_CACHE_DIR="${HF_HOME:-$HOME/.cache/huggingface}"
MODEL_ID="${MODEL_ID:-Mia-AiLab/Qwen3.8-Flash-Next-NVFP4}"
ORG="${MODEL_ID%%/*}"
NAME="${MODEL_ID##*/}"
MODEL_PATH="$HF_CACHE_DIR/hub/models--${ORG}--${NAME}"

if [ -d "$MODEL_PATH/snapshots" ]; then
    SNAPSHOT_DIR=$(ls -d "$MODEL_PATH/snapshots"/* 2>/dev/null | head -1 || true)
    if [ -n "$SNAPSHOT_DIR" ]; then
        echo "=== Step 3: Checking Checkpoint Config ($SNAPSHOT_DIR) ==="
        PATCHED_FILES=$(python3 "$FILES_DIR/patch_checkpoint_config.py" "$SNAPSHOT_DIR" "$FILES_DIR")
        if [ -n "$PATCHED_FILES" ]; then
            echo "✅ Generated patched configs: $PATCHED_FILES"
        else
            echo "✅ Checkpoint already declares absolute MTP layer indices (no config patching required)."
        fi
        MTP_ALGO=$(python3 "$FILES_DIR/patch_checkpoint_config.py" --mtp-moe-algo "$SNAPSHOT_DIR")
        echo "✅ MTP MoE algorithm verified: $MTP_ALGO"
    fi
fi

echo ""
echo "🎉 All patches prepared successfully in $FILES_DIR"
