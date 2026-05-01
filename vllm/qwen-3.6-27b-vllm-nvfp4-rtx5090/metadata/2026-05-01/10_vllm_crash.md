# docker compose

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
      VLLM_FLASHINFER_CHECK_SAFE_OPS: "0"
      VLLM_WORKER_MULTIPROC_METHOD: spawn
      PYTORCH_CUDA_ALLOC_CONF: "expandable_segments:True"
      # This helps skip the vision check on some vLLM versions
      VLLM_IMAGE_FETCH_TIMEOUT: "5"

    command:
      - "sakamakismile/Qwen3.6-27B-Text-NVFP4-MTP"
      - "--served-model-name"
      - "qwen3.6-27b-text-nvfp4-mtp"
      - "--trust-remote-code"
      - "--host"
      - "0.0.0.0"
      - "--port"
      - "8000"

      # 1. FIX: Force Text-Only Mode to prevent the 'OSError: Can't load image processor'
      - "--task"
      - "generate"
      
      # 2. FIX: Limit multimodal modalities to 0
      - "--limit-mm-per-prompt"
      - "image=0,video=0"

      - "--gpu-memory-utilization"
      - "0.82"
      - "--max-model-len"
      - "32768"
      - "--kv-cache-dtype"
      - "fp8"

      # 3. FIX: Use 'triton' to stay away from the TMA Blackwell driver issues for now
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
2026-05-01 19:01:27.278 | WARNING 05-01 17:01:27 [interface.py:686] Using 'pin_memory=False' as WSL is detected. This may slow down the performance.
2026-05-01 19:01:27.374 | usage: vllm serve [model_tag] [options]
2026-05-01 19:01:27.374 | vllm serve: error: argument --limit-mm-per-prompt: Value image=0,video=0 cannot be converted to <function loads at 0x7c9c81af8900>.