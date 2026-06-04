#!/bin/bash
source ../../../commonScripts/lib.sh
# Main MoE model (25.2B total, 3.8B active params)
hf_download_with_check "testLlamaCppGemma26b" "unsloth/gemma-4-26B-A4B-it-GGUF" "UD-Q4_K_XL/gemma-4-26B-A4B-it-UD-Q4_K_XL.gguf"
# Vision projector (required — this is NOT an encoder-free model like 12B)
hf_download_with_check "testLlamaCppGemma26b" "unsloth/gemma-4-26B-A4B-it-GGUF" "mmproj-BF16.gguf"
