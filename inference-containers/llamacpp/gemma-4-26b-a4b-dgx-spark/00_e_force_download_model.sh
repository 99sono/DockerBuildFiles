#!/bin/bash
source ../../../commonScripts/lib.sh
# Main MoE model (25.2B total, 3.8B active params)
hf_download_with_check "testLlamaCppGemma" "unsloth/gemma-4-26B-A4B-it-GGUF" "gemma-4-26B-A4B-it-UD-Q4_K_XL.gguf" "true"
# Vision projector (required — this is NOT an encoder-free model like 12B)
hf_download_with_check "testLlamaCppGemma" "unsloth/gemma-4-26B-A4B-it-GGUF" "mmproj-BF16.gguf" "true"
