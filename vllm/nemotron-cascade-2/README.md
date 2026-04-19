# Nemotron-Cascade-2-30B-A3B-NVFP4 (vLLM)

This directory contains a configured environment to run the [Nemotron-Cascade-2-30B-A3B-NVFP4](https://huggingface.co/chankhavu/Nemotron-Cascade-2-30B-A3B-NVFP4) model using [vLLM](https://github.com/vllm-project/vllm).

## Overview

This setup leverages vLLM's ability to run high-performance inference on hybrid Attention/SSM architectures. The model uses **NVFP4 (NVIDIA Floating Point 4)** quantization, which is remarkably memory-efficient for its size (30B parameters).

## Configuration

The main configuration is located in `docker-compose.yml`.

### Architecture & Memory Management

- **NVFP4 Support**: Native support for the model's 4-bit weights.
- **Hybrid SSM/Attention**: Nemotron-Cascade-2 uses a mix of Attention and Mamba layers. The SSM states are kept in `float32` for stability.
- **Context Management**: `--max-model-len` is currently set to `131072` (128k) to balance deep context capacity with the RTX 5090's VRAM limits.

### Current Implementation Status

While advanced KV-cache compression techniques like **TurboQuant** and **TriAttention** were explored, they are currently disabled to maintain stability with the latest vLLM image and Blackwell/WSL2 environment. The current setup relies on the efficiency of the NVFP4 architecture.

## Deployment

The environment is managed via Docker Compose. The configuration includes a custom `entrypoint.sh` to ensure stability on Blackwell/WSL2 systems.

### Running the model:
1. Ensure the `development-network` exists.
2. Run `./01_docker_compose_up.sh`.

## Testing

Use the provided `04_test_vllm_curl.py` script to test the model. You can modify the prompts in the `test/` directory to observe performance under different context lengths.
