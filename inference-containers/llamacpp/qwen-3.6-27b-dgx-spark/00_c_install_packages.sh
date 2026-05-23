#!/bin/bash
# =============================================================================
# 00_c_install_packages.sh
# Installs required packages inside the testLlamaCppQwen conda environment
# =============================================================================

set -euo pipefail

ENV_NAME="testLlamaCppQwen"

echo "📦 Installing packages into conda environment: $ENV_NAME"

# Activate the environment (using source to ensure it works in bash)
source $(conda info --base)/etc/profile.d/conda.sh
conda activate "$ENV_NAME"

# Install main dependencies
conda install -y -c conda-forge huggingface_hub jq curl

# Install Python OpenAI SDK and dotenv for API key loading
pip install openai python-dotenv

echo ""
echo "✅ Packages installed successfully!"
echo ""
echo "You can now run tests using:"
echo "    conda activate $ENV_NAME"
echo "    python 04_test_curl.py"
