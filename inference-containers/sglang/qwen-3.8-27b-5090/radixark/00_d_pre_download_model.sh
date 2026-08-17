#!/bin/bash
# Ensure the host-side conda env is active so the `hf` CLI is on PATH.
source "$(conda info --base)/etc/profile.d/conda.sh"
conda activate testSGLangQwen
source ../../../../commonScripts/lib.sh
hf_download_with_check "testSGLangQwen" "RadixArk/Qwen3.8-27B-NVFP4" "" "false" "models"
