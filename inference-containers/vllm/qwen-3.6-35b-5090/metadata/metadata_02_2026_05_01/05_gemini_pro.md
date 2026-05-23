You nailed it. You are 100% correct, and your intuition about the inference engines and the architecture is exactly why you are seeing this massive discrepancy. 

You aren't just missing CUDA graphs; you are literally running Qwen in **Software Emulation Mode**.

### 🕵️ The "Aha!" Moment from Your Logs
Look at this exact line from your successful Qwen boot log:
> `WARNING 05-01 19:01:42 [marlin_utils_fp4.py:300] Your GPU does not have native support for FP4 computation but FP4 quantization is being used. Weight-only FP4 compression will be used leveraging the Marlin kernel. This may degrade performance...`

**Here is the brutal translation:** The `marlin` backend does not recognize the RTX 5090's SM120 architecture natively yet. Instead of using your Blackwell FP4 Tensor Cores, it is falling back to standard 16-bit math and unpacking the 4-bit weights on the fly. You are doing software math. 

Your Gemma 4 setup is using `cutlass`. The `cutlass` backend JIT-compiles custom kernels that hook *directly* into the Blackwell FP4 silicon. That is why your Gemma model flies.

### 🧠 Why did Cutlass work on Gemma but crash on Qwen?
You hit the nail on the head: **Architecture and Size.**
1.  **Total VRAM:** Gemma is 26B (~15GB NVFP4). Qwen is 35B (~21.8GB NVFP4).
2.  **Sliding Window Attention (SWA):** Gemma uses SWA. Qwen uses Full Attention. SWA means Gemma's KV Cache is tiny. 

When you tried to run `cutlass` on Qwen earlier, the 21.8GB weights + the massive Qwen KV Cache starved the GPU. When the JIT compiler tried to allocate "workspace" memory to build the native FP4 kernels and CUDA graphs, it ran out of room and threw that bizarre `Failed to initialize the TMA descriptor` error. (It was an Out-of-Memory error hiding behind a hardware failure).

### 🚀 The "Kick-Ass" Gemma Protocol for Qwen
Since we know `cutlass` works in your WSL2 environment (proven by Gemma), we just need to trick vLLM into leaving enough empty VRAM during the boot sequence so the Qwen Cutlass kernels can compile.

We will remove the eager mode, bring back Cutlass, and drastically lower the `gpu-memory-utilization` to starve the KV cache during boot so the JIT compiler can feast.

**Use this exact Compose:**

```yaml
version: "3.9"

services:
  qwen3-6-moe-nvfp4:
    image: vllm/vllm-openai:v0.20.0-cu130-ubuntu2404
    container_name: qwen3-6-moe-35b-a3b-nvfp4
    hostname: qwen3-6-moe-35b-a3b-nvfp4
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
      # Let FlashInfer autotune so Cutlass can find the fast Blackwell path
      VLLM_WORKER_MULTIPROC_METHOD: spawn
      PYTORCH_CUDA_ALLOC_CONF: "expandable_segments:True"
      HF_HUB_ENABLE_HF_TRANSFER: "1"

    command:
      - "--model"
      - "RedHatAI/Qwen3.6-35B-A3B-NVFP4"
      - "--served-model-name"
      - "RedHatAI/Qwen3.6-35B-A3B-NVFP4"
      - "--trust-remote-code"
      - "--host"
      - "0.0.0.0"
      - "--port"
      - "8000"

      # 1. THE VRAM TRICK: Drop to 70% utilization.
      # This reserves ~9.6 GB of pure, untouched VRAM specifically for 
      # the Cutlass compiler and CUDA graph capture to do their heavy lifting.
      - "--gpu-memory-utilization"
      - "0.70"  

      # 2. Keep context and batching low so we don't blow up the workspace
      - "--max-model-len"
      - "8192"
      - "--max-num-seqs"
      - "2"
      - "--max-num-batched-tokens"
      - "4096" 

      - "--kv-cache-dtype"
      - "fp8_e4m3"
      - "--quantization"
      - "compressed-tensors"
      - "--reasoning-parser"
      - "qwen3"
      - "--tool-call-parser"
      - "qwen3_coder"

      # 3. BACK TO NATIVE SILICON SPEED
      - "--moe-backend"
      - "cutlass"

      - "--enable-prefix-caching"
      - "--enable-chunked-prefill"

      # 4. BRING BACK CUDA GRAPHS, BUT LIMIT THEM
      # This prevents the WSL2 memory crash while still giving you the speed boost.
      - "--max-cudagraph-capture-size"
      - "4"

    networks:
      - development-network

networks:
  development-network:
    external: true
```

If this boots, the "Marlin Emulation" warning will vanish, CUDA graphs will capture, and your generation speeds should skyrocket to match your Gemma 4 performance. Let me know what the logs say!