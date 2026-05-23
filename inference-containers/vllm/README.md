# Configuring CLINE with vLLM

This document summarizes the vLLM models that can be run locally with CLINE
and provides the maximum context length (token limit) each model supports.
CLINE expects an OpenAI-compatible endpoint.

## OpenAI Compatible Endpoint

**URL:** `http://localhost:8000/v1`  
**API Key:** Any string (no security enabled by default). Replace with a real key for production.

## Model Compatibility Table

| Model ID | Context Length (tokens) |
|----------|--------------------------|
| `gemma-4-26b-it-nvfp4` | 256,000 |
| `nemotron-cascade-2-nvfp4` | 256,000 |
| `qwen3.6-27b-text-nvfp4-mtp` | 32768 |

## Quick Start

1. Pull the desired model image.
2. Start the model with the appropriate parameters.
3. Use CLINE with the above endpoint.

*Refer to the `vllm/README.md` for model pull instructions.*