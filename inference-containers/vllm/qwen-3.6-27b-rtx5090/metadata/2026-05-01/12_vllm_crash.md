# compose

```yml
version: "3.9"

services:
  qwen-3-6-27b-nvfp4-mtp:
    image: vllm/vllm-openai:v0.20.0-cu130-ubuntu2404
    container_name: qwen-3-6-27b-nvfp4-mtp-stable
    hostname: qwen-3-6-27b-nvfp4-mtp
    platform: linux/amd64
    ports:
      - "8000:8000"
    volumes:
      - ~/.cache/huggingface:/root/.cache/huggingface
      - /dev/shm:/dev/shm
    shm_size: "32g"
    ipc: host
    deploy:
      resources:
        reservations:
          devices:
            - capabilities: [gpu]
    environment:
      FLASHINFER_AUTOTUNE: "0"
      VLLM_WORKER_MULTIPROC_METHOD: spawn
      PYTORCH_CUDA_ALLOC_CONF: "expandable_segments:True"

    command:
      - "sakamakismile/Qwen3.6-27B-Text-NVFP4-MTP"
      - "--served-model-name"
      - "qwen3.6-27b-text-nvfp4-mtp"
      - "--trust-remote-code"
      - "--host"
      - "0.0.0.0"
      - "--port"
      - "8000"

      # 1. FIX: Use the native flag to strip vision logic
      - "--language-model-only"
      
      # 2. FIX: Explicitly set task to generate to avoid multimodal checks
      - "--task"
      - "generate"

      - "--gpu-memory-utilization"
      - "0.80"
      - "--max-model-len"
      - "32768"
      - "--kv-cache-dtype"
      - "fp8"

      # 3. FIX: Staying with Triton/Eager for Sm120/WSL2 stability
      - "--quantization"
      - "compressed-tensors"
      - "--moe-backend"
      - "triton" 

      - "--enable-prefix-caching"
      - "--enable-chunked-prefill"
      - "--reasoning-parser"
      - "qwen3"
      - "--enforce-eager"

    networks:
      - development-network

networks:
  development-network:
    external: true
```    

# vllm log
2026-05-01 19:03:56.126 | WARNING 05-01 17:03:56 [interface.py:686] Using 'pin_memory=False' as WSL is detected. This may slow down the performance.
2026-05-01 19:03:56.222 | usage: vllm [-h] [-v]
2026-05-01 19:03:56.222 |             {chat,complete,serve,launch,bench,collect-env,run-batch} ...
2026-05-01 19:03:56.222 | vllm: error: unrecognized arguments: --task generate