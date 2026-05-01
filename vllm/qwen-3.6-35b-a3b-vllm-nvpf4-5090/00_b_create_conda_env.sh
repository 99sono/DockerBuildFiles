#!/bin/bash
# =============================================================================
# 00_b_create_conda_env.sh
# Creates a clean conda environment for testing vLLM OpenAI client
# =============================================================================

set -euo pipefail

ENV_NAME="testVllmQwen"

echo "🚀 Creating conda environment: $ENV_NAME"

# Check if environment already exists
if conda env list | grep -q "^$ENV_NAME "; then
    echo "⚠️  Environment '$ENV_NAME' already exists."
    read -p "Do you want to recreate it? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "Keeping existing environment."
        exit 0
    fi
    echo "Removing old environment..."
    conda env remove -n "$ENV_NAME" -y
fi

# Create new environment with Python 3.12
conda create -n "$ENV_NAME" python=3.12.11 -y

echo "✅ Environment '$ENV_NAME' created successfully."
echo ""
echo "To activate it, run:"
echo "    conda activate $ENV_NAME"
echo ""
echo "Next step: Install required packages with 00_c_install_packages.sh"
