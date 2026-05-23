#!/bin/bash
# =============================================================================
# 00_c_install_packages.sh
# Installs required packages inside the testVllm conda environment
# =============================================================================

set -euo pipefail

ENV_NAME="testVllm"

echo "📦 Installing packages into conda environment: $ENV_NAME"

# Activate the environment
conda activate "$ENV_NAME"

# Install main dependencies
conda install -y -c conda-forge openai rich python-dotenv

echo ""
echo "✅ Packages installed successfully!"
echo ""
echo "You can now run the test using:"
echo "    conda activate $ENV_NAME"
echo "    python 04_test_vllm.py"
echo ""
echo "Recommended: Create the Python test script next."
