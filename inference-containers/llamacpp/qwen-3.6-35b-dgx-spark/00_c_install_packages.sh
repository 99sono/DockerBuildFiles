#!/bin/bash
source ../../../commonScripts/lib.sh
conda_install_packages "testLlamaCppQwen" huggingface_hub jq curl
source "$(conda info --base)/etc/profile.d/conda.sh"
conda activate testLlamaCppQwen
pip install openai python-dotenv
