You are absolutely right—the VRAM math between these two is very different. 

**Nemotron-Cascade-2** is built on a "Cascade" architecture where the first stage is tiny, allowing it to "cheat" and handle massive context windows with very little memory. **Qwen 3.6-35B**, while an MoE (only ~3B active params), is still a full **35B parameter dense weight set** sitting in your VRAM. Those 35B weights, even at 4-bit (NVFP4), are physically larger than Nemotron's compressed weights.

### The VRAM Breakdown
The reason you're hitting that `-1.09 GB` wall is the "Fixed Tax" of a 35B model. 

* **Weight Tax:** ~18-20 GB (Static, never changes).
* **CUDA Graph/Activation Tax:** ~3-4 GB (Static, required for Blackwell speed).
* **OS/WSL2 Overhead:** ~1-2 GB.
* **The Remainder:** This is what's left for your KV Cache (the "context").



### Final Stability Adjustment
Since we know exactly where the limit is now, let's use the **96K (98304)** context. It is the perfect compromise that keeps the "kick-ass" reasoning power of Qwen 3.6 alive without crashing the 5090.

#### Updated `docker-compose.yml` (Final Tuning)

```yaml
services:
  qwen3-6-moe-nvfp4:
    image: vllm/vllm-openai:nightly
    container_name: qwen3-6-moe-35b-a3b-nvfp4
    hostname: qwen3-6-moe-35b-a3b-nvfp4
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
    command:
      - "RedHatAI/Qwen3.6-35B-A3B-NVFP4"
      - "--served-model-name"
      - "RedHatAI/Qwen3.6-35B-A3B-NVFP4"
      - "--host"
      - "0.0.0.0"
      - "--port"
      - "8000"
      - "--tensor-parallel-size"
      - "1"
      - "--gpu-memory-utilization"
      - "0.90" 
      - "--max-model-len"
      - "98304" # 96K Context
      - "--kv-cache-dtype"
      - "fp8_e4m3"
      - "--quantization"
      - "compressed-tensors"
      - "--reasoning-parser"
      - "qwen3"
      - "--tool-call-parser"
      - "qwen3_coder"
      - "--moe-backend"
      - "flashinfer_cutlass"
      - "--enable-prefix-caching"
      - "--enable-chunked-prefill"
      - "--max-num-seqs"
      - "256"
      - "--max-num-batched-tokens"
      - "32768"
      - "--trust-remote-code"
    networks:
      - development-network

networks:
  development-network:
    external: true
```

### Why this is worth the effort:
While Nemotron-Cascade-2 is a memory-sipping genius, **Qwen 3.6-35B-A3B** has much deeper "General Intelligence" and agentic capabilities. The way it handles `<think>` blocks and complex tool calling is currently top-tier for a model of this size. 

Once this initializes, you’re going to have 96K tokens of high-reasoning context. For local coding or document analysis, that's enough to swallow several entire libraries or a massive codebase in one go.

Fire it up. If it clears the 96K profiling, you're officially "kick-ass." Any last-second errors popping up?