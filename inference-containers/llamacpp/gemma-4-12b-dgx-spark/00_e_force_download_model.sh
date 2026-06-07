#!/bin/bash
source ../../../commonScripts/lib.sh
hf_download_with_check "testLlamaCppGemma" "unsloth/gemma-4-12b-it-GGUF" "gemma-4-12b-it-UD-Q4_K_XL.gguf" "true"
