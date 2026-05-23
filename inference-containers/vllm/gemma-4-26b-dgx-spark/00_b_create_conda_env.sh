#!/bin/bash
# =============================================================================
# 00_b_create_conda_env.sh
# =============================================================================
# Create conda environment for Python tools and testing.

set -euo pipefail

ENV_NAME="testVllmGemmaSpark"

echo "🚀 Creating conda environment: $ENV_NAME"

if conda env list | grep -q "^$ENV_NAME "; then
    echo "⚠️  Environment '$ENV_NAME' already exists. Re-creating..."
    conda env remove -n "$ENV_NAME" -y
fi

conda create -n "$ENV_NAME" python=3.12 -y

echo "✅ Environment '$ENV_NAME' created successfully."