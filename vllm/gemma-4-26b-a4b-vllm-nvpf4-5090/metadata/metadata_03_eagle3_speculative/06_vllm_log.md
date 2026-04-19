# docker compose 

docker compose yaml.
```yaml
services:
  gemma-4-26b-it-nvfp4-eagle3:
    image: vllm/vllm-openai:nightly
    container_name: gemma-4-26b-it-nvfp4-eagle3
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
      # 1. Model as a POSITIONAL argument (No --model, no "serve")
      - "RedHatAI/gemma-4-26B-A4B-it-NVFP4"
      - "--served-model-name"
      - "gemma-4-26b-it-nvfp4"
      # 2. Speculative Flags (Standard CLI syntax)
      - "--speculative-method"
      - "eagle"
      - "--speculative-model"
      - "RedHatAI/gemma-4-26B-A4B-it-speculator.eagle3"
      - "--num-speculative-tokens"
      - "3"
      # 3. Performance & Memory
      - "--gpu-memory-utilization"
      - "0.82"
      - "--max-model-len"
      - "98304"
      - "--kv-cache-dtype"
      - "fp8_e4m3"
      - "--quantization"
      - "compressed-tensors"
      - "--enable-prefix-caching"
      - "--enable-chunked-prefill"
      - "--max-num-seqs"
      - "2"
      - "--moe-backend"
      - "cutlass"
      - "--trust-remote-code"
      - "--host"
      - "0.0.0.0"

    networks:
      - development-network

networks:
  development-network:
    external: true
```

# vllm log
2026-04-19 17:18:28.402 | WARNING 04-19 15:18:28 [interface.py:686] Using 'pin_memory=False' as WSL is detected. This may slow down the performance.
2026-04-19 17:18:28.500 | usage: vllm [-h] [-v]
2026-04-19 17:18:28.500 |             {chat,complete,serve,launch,bench,collect-env,run-batch} ...
2026-04-19 17:18:28.500 | vllm: error: unrecognized arguments: --speculative-method eagle --speculative-model RedHatAI/gemma-4-26B-A4B-it-speculator.eagle3 --num-speculative-tokens 3
2026-04-19 17:18:36.525 | WARNING 04-19 15:18:36 [interface.py:686] Using 'pin_memory=False' as WSL is detected. This may slow down the performance.
2026-04-19 17:18:36.578 | usage: vllm [-h] [-v]
2026-04-19 17:18:36.578 |             {chat,complete,serve,launch,bench,collect-env,run-batch} ...
2026-04-19 17:18:36.578 | vllm: error: unrecognized arguments: --speculative-method eagle --speculative-model RedHatAI/gemma-4-26B-A4B-it-speculator.eagle3 --num-speculative-tokens 3
2026-04-19 17:18:44.129 | WARNING 04-19 15:18:44 [interface.py:686] Using 'pin_memory=False' as WSL is detected. This may slow down the performance.
2026-04-19 17:18:44.179 | usage: vllm [-h] [-v]
2026-04-19 17:18:44.179 |             {chat,complete,serve,launch,bench,collect-env,run-batch} ...
2026-04-19 17:18:44.179 | vllm: error: unrecognized arguments: --speculative-method eagle --speculative-model RedHatAI/gemma-4-26B-A4B-it-speculator.eagle3 --num-speculative-tokens 3
2026-04-19 17:18:51.473 | WARNING 04-19 15:18:51 [interface.py:686] Using 'pin_memory=False' as WSL is detected. This may slow down the performance.
2026-04-19 17:18:51.523 | usage: vllm [-h] [-v]
2026-04-19 17:18:51.523 |             {chat,complete,serve,launch,bench,collect-env,run-batch} ...
2026-04-19 17:18:51.523 | vllm: error: unrecognized arguments: --speculative-method eagle --speculative-model RedHatAI/gemma-4-26B-A4B-it-speculator.eagle3 --num-speculative-tokens 3
2026-04-19 17:18:59.094 | WARNING 04-19 15:18:59 [interface.py:686] Using 'pin_memory=False' as WSL is detected. This may slow down the performance.
2026-04-19 17:18:59.143 | usage: vllm [-h] [-v]
2026-04-19 17:18:59.143 |             {chat,complete,serve,launch,bench,collect-env,run-batch} ...
2026-04-19 17:18:59.143 | vllm: error: unrecognized arguments: --speculative-method eagle --speculative-model RedHatAI/gemma-4-26B-A4B-it-speculator.eagle3 --num-speculative-tokens 3
2026-04-19 17:19:07.853 | WARNING 04-19 15:19:07 [interface.py:686] Using 'pin_memory=False' as WSL is detected. This may slow down the performance.
2026-04-19 17:19:07.905 | usage: vllm [-h] [-v]
2026-04-19 17:19:07.905 |             {chat,complete,serve,launch,bench,collect-env,run-batch} ...
2026-04-19 17:19:07.905 | vllm: error: unrecognized arguments: --speculative-method eagle --speculative-model RedHatAI/gemma-4-26B-A4B-it-speculator.eagle3 --num-speculative-tokens 3
2026-04-19 17:19:18.179 | WARNING 04-19 15:19:18 [interface.py:686] Using 'pin_memory=False' as WSL is detected. This may slow down the performance.
2026-04-19 17:19:18.231 | usage: vllm [-h] [-v]
2026-04-19 17:19:18.231 |             {chat,complete,serve,launch,bench,collect-env,run-batch} ...
2026-04-19 17:19:18.231 | vllm: error: unrecognized arguments: --speculative-method eagle --speculative-model RedHatAI/gemma-4-26B-A4B-it-speculator.eagle3 --num-speculative-tokens 3