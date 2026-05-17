#!/bin/bash
# =============================================================================
# 00_c_install_packages.sh
# Installs required packages inside the testAtlasQwen conda environment
# =============================================================================

set -euo pipefail

ENV_NAME="testAtlasQwen"

echo "📦 Installing packages into conda environment: $ENV_NAME"

# Activate the environment (using source to ensure it works in bash)
source $(conda info --base)/etc/profile.d/conda.sh
conda activate "$ENV_NAME"

# Install main dependencies
conda install -y -c conda-forge openai rich huggingface_hub python-dotenv

echo ""
echo "✅ Packages installed successfully!"
echo ""
echo "You can now run the test using:"
echo "    conda activate $ENV_NAME"
echo "    python 04_test_atlas_curl.py"
