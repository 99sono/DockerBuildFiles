#!/bin/bash
# Ensure the host-side conda env is active so the `hf` CLI is on PATH.
source "$(conda info --base)/etc/profile.d/conda.sh"
conda activate testNInferQwen
source ../../../../commonScripts/lib.sh
hf_download_with_check "testNInferQwen" "neroued/Qwen3.8-27B-nvfp4-NInfer" "qwen3_8_27b_nvfp4.ninfer" "true" "models"
