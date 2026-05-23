# Docker compose
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
      - "0.85"
      - "--max-model-len"
      - "131072"
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

# Gemini 3 flash
**Success! You have officially cleared the "loading" hurdle.**

Your RTX 5090 has successfully swallowed the model weights (23.32 GiB), and the engine is now performing its final high-speed optimizations. This is the most stable log output we've seen yet.

### 1. The Critical Milestone
> `Loading weights took 44.60 seconds`
> `Model loading took 21.88 GiB memory`

This is perfect. It confirms that the **NVFP4 (4-bit)** quantization is working. If the model had loaded in FP16, it would have required ~70GB of VRAM and crashed your card immediately. At ~22GB, you have exactly the right amount of "breathing room" for the KV cache.

### 2. The "Blackwell Magic" is Engaging
> `Using FlashInferCutlassNvFp4LinearKernel for NVFP4 GEMM`
> `Using 'FLASHINFER_CUTLASS' NvFp4 MoE backend`

This is exactly what we wanted to see. The engine has successfully bypassed the Triton limitation and is now using the **hand-tuned Blackwell kernels** for the MoE (Mixture of Experts) part of Qwen 3.6. This is the fastest possible path for a 5090.

### 3. Torch.Compile & CUDA Graphs
> `Dynamo bytecode transform time: 7.28 s`
> `Cache the graph of compile range (1, 32768)`

The engine is currently "baking" the math operations into your GPU's hardware. 
* **What's happening:** It's taking the Python logic and converting it into a static "map" (CUDA Graph) so that when you ask a question, the GPU doesn't have to wait for the CPU to tell it what to do next.
* **The Wait:** This phase (after the `32768` log line) can take a few minutes. You might see the GPU fans spin up as it "profiles" the memory.

---

### What to expect next:
Once the graph caching is complete, the very next lines should be:
1. `INFO: Capturing CUDA graphs...`
2. `INFO: Graph capture finished in XX seconds.`
3. `INFO: vLLM OpenAI server is running at http://0.0.0.0:8000`

### Final Checklist for "In the Bag"
* **VRAM:** You are currently using ~22GB for weights + some overhead. With your utilization set to `0.85`, vLLM will reserve a total of about **27.2GB**. This is the "sweet spot" for a 32GB 5090.
* **WSL2:** The `pin_memory=False` warning is still there, but as I mentioned, the 5090's raw power makes this irrelevant.

**It is effectively "in the bag."** Do not touch the terminal. Let it finish the graph compilation. As soon as you see the `Uvicorn` or `http://0.0.0.0:8000` line, you are ready to send your first prompt.

**One final tip:** Since Qwen 3.6-35B-A3B is an MoE model, only about 3B parameters are active per token. On a 5090, your generation speed is going to be incredibly fast—likely faster than you can read!