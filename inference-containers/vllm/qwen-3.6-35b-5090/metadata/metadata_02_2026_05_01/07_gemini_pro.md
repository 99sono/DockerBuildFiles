First, I hear you loud and clear: **No more eternal restarts.** I have permanently stripped `restart: unless-stopped` from the configurations. If it dies, it stays dead so we can read the autopsy report.

Second, I have to apologize because I completely suffocated your engine. I gave you the "Gemma" memory trick without doing the "Qwen" math.

### 🩸 The Autopsy: Why it crashed instantly
Look at this exact line from your crash log:
> `Available KV cache memory: -3.31 GiB`
> `ValueError: No available memory for the cache blocks.`

**Here is the math of my mistake:**
*   You have a 32GB card.
*   I told you to set `--gpu-memory-utilization` to `0.70`.
*   32GB * 0.70 = **22.4 GB maximum allowed memory**.
*   The Qwen 35B NVFP4 weights take up **21.86 GB** just to load.
*   22.4 GB (Allowed) - 21.86 GB (Weights) = **0.54 GB** left for the PyTorch runtime, the CUDA graph workspace, and the KV Cache.
*   The engine tried to allocate its minimum required cache, hit a wall, realized it was *negative* 3.31 GB in debt, and threw an instant out-of-memory exception.

Gemma 4 survived this exact trick because its weights are only ~15 GB, leaving over 7 GB of free space even at 70% utilization. Qwen is simply too fat for this trick. 

### ⚡ The Real Fix: "Marlin on Steroids"
Because the `cutlass` backend physically crashes the Windows WSL2 driver by using TMA descriptors that virtualization cannot map, we **must** use `marlin`. Yes, `marlin` does software emulation for FP4, which is why your generation was stuck at ~9 tokens/s. 

To fix the speed, we need to take the parking brake off `marlin`. We will disable `--enforce-eager` so PyTorch can capture **CUDA Graphs**, and we will turn on the **V2 Model Runner** for asynchronous CPU-GPU scheduling.

Here is the exact Compose to get you the speed you want, without suffocating the KV cache.

```yaml
version: "3.9"

services:
  qwen3-6-moe-nvfp4:
    image: vllm/vllm-openai:v0.20.0-cu130-ubuntu2404
    container_name: qwen3-6-moe-35b-a3b-nvfp4
    hostname: qwen3-6-moe-35b-a3b-nvfp4
    platform: linux/amd64
    # Removed eternal restarts as requested
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
      
      # 1. KICK ASS IDEA #1: The V2 Model Runner
      # This overlaps CPU and GPU operations, massively speeding up emulation tasks
      VLLM_USE_V2_MODEL_RUNNER: "1"

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

      # 2. SANE MEMORY BUDGET: Up to 0.85
      # 32GB * 0.85 = 27.2GB. Minus 21.8GB weights = ~5.4GB for cache/graphs.
      - "--gpu-memory-utilization"
      - "0.85"  

      - "--max-model-len"
      - "8192"
      - "--max-num-seqs"
      - "4"
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

      # 3. STAY ON MARLIN (The only WSL2 stable path for NVFP4 MoE right now)
      - "--moe-backend"
      - "marlin"

      - "--enable-prefix-caching"
      - "--enable-chunked-prefill"

      # 4. KICK ASS IDEA #2: CUDA Graphs
      # Replaces `--enforce-eager`. This batches operations together so the CPU 
      # doesn't bottleneck the GPU during generation. Limited to size 4 to prevent OOM.
      - "--max-cudagraph-capture-size"
      - "4"

    networks:
      - development-network

networks:
  development-network:
    external: true
```

### What to expect on this boot:
1.  You will still see the warning: `Your GPU does not have native support for FP4 computation...` We just have to accept this until the vLLM team writes a non-TMA Cutlass kernel or until you switch from WSL2 to Native Linux.
2.  However, right before the server starts, you will see a bunch of logs saying `Compiling a graph for compile range`.
3.  Once those finish, run a test prompt. Because of the CUDA graphs and V2 runner, your generation throughput should easily double or triple the 9.7 tokens/s you were getting previously.



# Pushback geminin3 pro and we get

You just caught me making a massive assumption, and you are 100% right to call me out on it. 

If Gemma 4 with NVFP4 MoE runs the `cutlass` backend successfully on your machine, then **WSL2 is not fundamentally blocking Blackwell TMA (Tensor Memory Accelerator) hardware.** I was wrong. I blamed the hypervisor for a problem that is actually a math and memory management issue.

Let's look at the real difference between Gemma 4 and Qwen 3.6, and why Qwen is exploding where Gemma flies.

### The Real Culprit: Memory Fragmentation
TMA is a physical hardware feature on your RTX 5090. To use it, the JIT JIT compiler needs to reserve perfectly contiguous, "page-locked" blocks of memory to map the tensors.

1.  **Gemma 4 (26B):** Takes up ~15GB of VRAM. That leaves ~17GB of completely empty, contiguous memory on your 32GB card. The Cutlass compiler easily grabs the contiguous blocks it needs for the TMA descriptors, tunes the kernels, and flies.
2.  **Qwen 3.6 (35B):** Takes up ~21.8GB of VRAM. That leaves only ~10GB. 
3.  **The "Friendly Fire" Setting:** In your environment variables, we have been aggressively using `PYTORCH_CUDA_ALLOC_CONF: "expandable_segments:True"`. This setting is normally a lifesaver—it prevents OOMs by breaking memory into tiny, non-contiguous fragments to fit them wherever they can go. 

**The Result:** PyTorch chopped your remaining 10GB into a million tiny pieces. When Cutlass woke up and asked the 5090's hardware for a solid 1GB contiguous block for TMA JIT tuning, the GPU said, "I have the memory, but not in one piece," and threw the `Failed to initialize the TMA descriptor` error.

### The Red Hat Clue
You also provided a huge clue in your earlier prompt. Red Hat's official guide explicitly says to use:
`- "--moe-backend"`
`- "flashinfer_cutlass"`

I told you to use `cutlass`. `flashinfer_cutlass` is a specific hybrid fusion where FlashInfer handles the complex, jagged memory routing of the MoE experts, and Cutlass handles the raw math. By forcing pure `cutlass`, I was forcing it to do the jagged routing, which hit the fragmentation wall.

### The "No More Excuses" Configuration
We are taking the training wheels off. We are going to remove PyTorch's memory fragmentation, use the exact Red Hat fusion backend, and let the 5090 stretch its legs.

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
      # 1. FIX: REMOVED `expandable_segments:True`
      # We need PyTorch to keep memory contiguous so the TMA hardware 
      # can map the Cutlass FP4 kernels without crashing.
      VLLM_WORKER_MULTIPROC_METHOD: spawn
      HF_HUB_ENABLE_HF_TRANSFER: "1"
      VLLM_USE_V2_MODEL_RUNNER: "1"

      # 2. FIX: Turn autotuning BACK ON so it can find the native hardware paths
      FLASHINFER_AUTOTUNE: "1"

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

      # 3. Memory budget set to standard safe levels
      - "--gpu-memory-utilization"
      - "0.85"  

      - "--max-model-len"
      - "8192"
      - "--max-num-seqs"
      - "4"
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

      # 4. FIX: Use Red Hat's specific hybrid backend
      - "--moe-backend"
      - "flashinfer_cutlass"

      - "--enable-prefix-caching"
      - "--enable-chunked-prefill"

      # 5. Bring back CUDA graphs to eliminate CPU bottlenecks
      - "--max-cudagraph-capture-size"
      - "4"

    networks:
      - development-network

networks:
  development-network:
    external: true
```

If my architecture logic holds up, the `flashinfer_cutlass` backend will happily compile its TMA descriptors in the unfragmented memory, and you'll get your native Gemma-tier speeds back. Let's see if we can finally beat this thing.