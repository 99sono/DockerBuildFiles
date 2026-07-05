#!/bin/bash
set -euo pipefail

ENV_NAME="testVllmDeepSeek"

echo "Creating conda environment: $ENV_NAME"

if conda env list | grep -q "^$ENV_NAME "; then
    echo "Environment '$ENV_NAME' already exists."
    read -p "Do you want to recreate it? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "Keeping existing environment."
        exit 0
    fi
    echo "Removing old environment..."
    conda env remove -n "$ENV_NAME" -y
fi

conda create -n "$ENV_NAME" python=3.12.11 -y

echo "Environment '$ENV_NAME' created successfully."
echo ""
echo "Next step: run 00_c_install_packages.sh"
