# docker compose
```yaml
# Gemma-4-26B NVFP4 - EAGLE-3 Speculative Decoding Configuration
# Accelerates inference by predicting future tokens via a 0.9B draft model.

services:
  gemma-4-26b-it-nvfp4-eagle3:
    image: vllm/vllm-openai:nightly
    container_name: gemma-4-26b-it-nvfp4-eagle3
    hostname: gemma-4-26b-it-nvfp4-eagle3
    runtime: nvidia
    restart: unless-stopped
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
      - NVIDIA_VISIBLE_DEVICES=all
      - HF_HUB_ENABLE_HF_TRANSFER=1
      - VLLM_WORKER_MULTIPROC_METHOD=spawn
      - VLLM_ATTENTION_BACKEND=FLASHINFER
    command:
      - "RedHatAI/gemma-4-26B-A4B-it-NVFP4"
      - "--served-model-name"
      - "gemma-4-26b-it-nvfp4"
      # --- EAGLE-3 SPECULATIVE DECODING ---
      - "--speculative-model"
      - "RedHatAI/gemma-4-26B-A4B-it-speculator.eagle3"
      - "--num-speculative-tokens"
      - "5"
      - "--use-v2-block-manager"
      # -----------------------------------
      - "--host"
      - "0.0.0.0"
      - "--port"
      - "8000"
      - "--gpu-memory-utilization"
      - "0.82" # Safety buffer (82%) for speculator weights/cache
      - "--max-model-len"
      - "98304" # 96K Context
      - "--max-num-batched-tokens"
      - "8192"
      - "--kv-cache-dtype"
      - "fp8_e4m3"
      - "--quantization"
      - "compressed-tensors"
      - "--enable-prefix-caching"
      - "--enable-chunked-prefill"
      - "--max-num-seqs"
      - "2"
      - "--reasoning-parser"
      - "gemma4"
      - "--tool-call-parser"
      - "gemma4"
      - "--moe-backend"
      - "cutlass"
      - "--trust-remote-code"
    networks:
      - development-network

networks:
  development-network:
    external: true

```

# vllm log

2026-04-19 17:01:17.288 | WARNING 04-19 15:01:17 [interface.py:686] Using 'pin_memory=False' as WSL is detected. This may slow down the performance.
2026-04-19 17:01:17.382 | usage: vllm [-h] [-v]
2026-04-19 17:01:17.382 |             {chat,complete,serve,launch,bench,collect-env,run-batch} ...
2026-04-19 17:01:17.382 | vllm: error: unrecognized arguments: --speculative-model RedHatAI/gemma-4-26B-A4B-it-speculator.eagle3 --num-speculative-tokens 5 --use-v2-block-manager
2026-04-19 17:01:25.451 | WARNING 04-19 15:01:25 [interface.py:686] Using 'pin_memory=False' as WSL is detected. This may slow down the performance.
2026-04-19 17:01:25.500 | usage: vllm [-h] [-v]
2026-04-19 17:01:25.500 |             {chat,complete,serve,launch,bench,collect-env,run-batch} ...
2026-04-19 17:01:25.500 | vllm: error: unrecognized arguments: --speculative-model RedHatAI/gemma-4-26B-A4B-it-speculator.eagle3 --num-speculative-tokens 5 --use-v2-block-manager
2026-04-19 17:01:32.949 | WARNING 04-19 15:01:32 [interface.py:686] Using 'pin_memory=False' as WSL is detected. This may slow down the performance.
2026-04-19 17:01:33.001 | usage: vllm [-h] [-v]
2026-04-19 17:01:33.001 |             {chat,complete,serve,launch,bench,collect-env,run-batch} ...
2026-04-19 17:01:33.001 | vllm: error: unrecognized arguments: --speculative-model RedHatAI/gemma-4-26B-A4B-it-speculator.eagle3 --num-speculative-tokens 5 --use-v2-block-manager
2026-04-19 17:01:40.289 | WARNING 04-19 15:01:40 [interface.py:686] Using 'pin_memory=False' as WSL is detected. This may slow down the performance.
2026-04-19 17:01:40.340 | usage: vllm [-h] [-v]
2026-04-19 17:01:40.340 |             {chat,complete,serve,launch,bench,collect-env,run-batch} ...
2026-04-19 17:01:40.340 | vllm: error: unrecognized arguments: --speculative-model RedHatAI/gemma-4-26B-A4B-it-speculator.eagle3 --num-speculative-tokens 5 --use-v2-block-manager
2026-04-19 17:01:47.966 | WARNING 04-19 15:01:47 [interface.py:686] Using 'pin_memory=False' as WSL is detected. This may slow down the performance.
2026-04-19 17:01:48.019 | usage: vllm [-h] [-v]
2026-04-19 17:01:48.019 |             {chat,complete,serve,launch,bench,collect-env,run-batch} ...
2026-04-19 17:01:48.019 | vllm: error: unrecognized arguments: --speculative-model RedHatAI/gemma-4-26B-A4B-it-speculator.eagle3 --num-speculative-tokens 5 --use-v2-block-manager

