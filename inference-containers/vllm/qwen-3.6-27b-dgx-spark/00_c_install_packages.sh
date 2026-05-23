#!/bin/bash
# =============================================================================
# 00_c_install_packages.sh
# Installs required packages inside the testVllmQwen27B conda environment
# =============================================================================

set -euo pipefail

ENV_NAME="testVllmQwen27B"

echo "📦 Installing packages into conda environment: $ENV_NAME"

source $(conda info --base)/etc/profile.d/conda.sh
conda activate "$ENV_NAME"

conda install -y -c conda-forge openai rich huggingface_hub python-dotenv

echo ""
echo "✅ Packages installed successfully!"
echo ""
echo "You can now run the test using:"
echo "    conda activate $ENV_NAME"
echo "    python 04_test_vllm_curl.py"