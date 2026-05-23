# DockerComposeFiles

Collection of docker-compose configurations for running inference containers and related services.

## Contents

### Inference Containers (`inference-containers/`)
Docker Compose setups for running large language model inference servers, organized by backend:

- **llama.cpp** - GGUF-based inference with MTP speculative decoding
- **vLLM** - High-throughput inference server
- **ollama** - OpenAI-compatible API serving
- **atlas** - NVIDIA Atlas (TensorRT-LLM) deployments
- **nginx** - Reverse proxy configurations for load balancing across backends

Each model configuration includes its own directory with:
- `docker-compose.yml` — container configuration, networking, GPU passthrough
- `metadata/` — benchmark logs, analysis reports, and performance data

### Utility Scripts (`commonScripts/`, root level)
- Git helper scripts for comparing commits against origin
- CLI curl tool dumps for API testing

## Quick Start

1. Navigate to the desired model directory:
   ```bash
   cd inference-containers/llamacpp/qwen-3.6-35b-dgx-spark
   ```

2. Review the configuration and any metadata available:
   ```bash
   ls metadata/
   ```

3. Run it:
   ```bash
   docker compose up -d
   ```

## Environment Variables

Each configuration accepts environment variables for port, model alias, API key, etc.
See the individual `docker-compose.yml` files for details.
