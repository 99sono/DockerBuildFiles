#!/bin/bash
# Ensure the host-side conda env is active so the `hf` CLI is on PATH.
source "$(conda info --base)/etc/profile.d/conda.sh"
conda activate testSGLangQwen
hf download thinkingmachines/Inkling-2-Mini
