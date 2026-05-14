#!/bin/bash
# =============================================================================
# 00_c_install_packages.sh
# =============================================================================
# Install Python packages into the conda environment for API testing.

set -euo pipefail

ENV_NAME="testVllmGemmaSpark"

echo "📦 Installing packages into: $ENV_NAME"

source $(conda info --base)/etc/profile.d/conda.sh
conda activate "$ENV_NAME"

conda install -y -c conda-forge openai rich huggingface_hub

echo ""
echo "✅ Packages installed successfully!"