#!/bin/bash
# =============================================================================
# 00_c_install_packages.sh
# =============================================================================

set -euo pipefail

ENV_NAME="testVllmGemma"

echo "📦 Installing packages into: $ENV_NAME"

source $(conda info --base)/etc/profile.d/conda.sh
conda activate "$ENV_NAME"

pip install --upgrade pip
pip install openai rich huggingface_hub

echo ""
echo "✅ Packages installed successfully!"
