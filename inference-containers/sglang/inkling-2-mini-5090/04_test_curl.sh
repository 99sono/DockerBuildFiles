#!/bin/bash
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# Ensure the host-side conda env is active so the openai client is importable.
source "$(conda info --base)/etc/profile.d/conda.sh"
conda activate testSGLangQwen
( cd "$SCRIPT_DIR" && source ../../../commonScripts/lib.sh && load_env && python3 ../../../commonScripts/test_client.py )
