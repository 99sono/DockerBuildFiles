#!/bin/bash
set -euo pipefail

ENV_NAME="testVllmDeepSeek"

echo "Installing packages into conda environment: $ENV_NAME"

source "$(conda info --base)/etc/profile.d/conda.sh"
conda activate "$ENV_NAME"

conda install -y -c conda-forge openai rich huggingface_hub python-dotenv

echo ""
echo "Packages installed successfully!"
