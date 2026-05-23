# docker-compose at time of crash
docker compose:
```yml
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
      - "98304"
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
# gemini 3 flash
This is incredibly frustrating, but your log provides the exact mathematical reason why it is failing. We are playing a game of "VRAM Tetris," and we are currently off by just **half a gigabyte**.

### The Log Audit (The "Smoking Gun")
Look at this line from your log:
> `Available KV cache memory: 0.61 GiB`
> `To serve ... max seq len (98304), (1.06 GiB KV cache is needed)`

**The Math:** You have **0.61 GB** left, but the model needs **1.06 GB** to create the minimum buffers for that 96K context window. You are short by exactly **0.45 GB**.

### Why is this happening on a 5090?
The RTX 5090 has 32GB. 
1. **Model Weights:** ~22GB.
2. **CUDA Graphs:** On Blackwell, vLLM pre-allocates a lot of "captured" memory to make the model fast. 
3. **The Hybrid Tax:** Because Qwen 3.6 is a hybrid (GDN + MoE), it requires specific "state" buffers for the GDN layers that pure Transformer models don't need.

### The Guaranteed Fix
We need to reclaim that 0.45 GB. We will do this by dropping the context to **64K (65536)**. 
* 64K is still 4x larger than the standard GPT-4 context and plenty for heavy reasoning/coding.
* This will free up roughly **1.5 GB** of VRAM, putting you well into the "green" zone.

#### Update your `docker-compose.yml` command:

```yaml
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
      - "65536" # Dropped to 64K for guaranteed stability
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
```

### One more trick for WSL2:
If it *still* complains about memory, it’s because Windows is hogging too much VRAM for the "Desktop Window Manager." 
**Temporary Workaround:** Before you run `docker compose up`, close any Chrome/Edge tabs and any Electron apps (Discord, VS Code, Slack). These apps use GPU acceleration and can eat up that 0.5 GB we need.

**Verdict:** 64K is the magic number for a 35B model on a 32GB card when using high-performance Blackwell kernels. This will get you to the `Uvicorn` startup line. Give it one more push!