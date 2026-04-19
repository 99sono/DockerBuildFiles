#!/bin/bash
# =============================================================================
# 00_c_install_packages.sh
# Installs required packages inside the testVllmQwen conda environment
# =============================================================================

set -euo pipefail

ENV_NAME="testVllmQwen"

echo "📦 Installing packages into conda environment: $ENV_NAME"

# Activate the environment (using source to ensure it works in bash)
# Note: conda activate usually requires conda init to be set up.
# We'll use 'conda run' or similar if needed, but for scripts, source is common.
source $(conda info --base)/etc/profile.d/conda.sh
conda activate "$ENV_NAME"

# Install main dependencies
pip install --upgrade pip
pip install openai rich huggingface_hub

echo ""
echo "✅ Packages installed successfully!"
echo ""
echo "You can now run the test using:"
echo "    conda activate $ENV_NAME"
echo "    python 04_test_vllm_curl.py"
