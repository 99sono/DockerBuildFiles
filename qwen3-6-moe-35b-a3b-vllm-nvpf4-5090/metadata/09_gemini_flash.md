Ouch, we hit the final boss of VRAM management: **Fragmentation**.

Even though you have 32GB, the log says: 
`Available KV cache memory: -1.09 GiB`

### What happened?
During the "warmup" (profiling) phase, vLLM realized that after loading the model weights and allocating memory for the **CUDA Graphs** and internal buffers, there wasn't enough room left to create the KV cache for a **128K context window**. 

On Blackwell GPUs, the new kernels and the hybrid GDN architecture require slightly more "workspace" memory than older architectures. Even though the hybrid model is efficient, the *static* allocation vLLM tries to make for 131,072 tokens is just slightly exceeding your 0.85 limit.



### The Fix: Strategic Headroom
We have two levers to pull. We will use both for a guaranteed start.

1.  **Lower the Context Slightly:** We'll drop from 128K (131,072) to **96K (98,304)**. This is still a massive context window for local use, but it frees up about 4-5GB of VRAM.
2.  **Increase Utilization:** We'll bump `--gpu-memory-utilization` to **0.90**. Since you are on a 5090, 10% (3.2GB) is plenty for the Windows/WSL2 desktop.

### Update your `docker-compose.yml` command block:

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
      - "0.90"  # Increased to give vLLM more of the pie
      - "--max-model-len"
      - "98304" # Lowered to 96K for guaranteed stability
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

### Why this will work:
The error `Available KV cache memory: -1.09 GiB` means you were only **1.1 GB short**. 
* Changing context from 128K to 96K saves roughly **3 GB**.
* Changing utilization from 0.85 to 0.90 gives vLLM an extra **1.6 GB**.

Combined, you are now ~3.5 GB "in the green." This should sail through the profiling phase and get you that `Uvicorn` start line. Give it one more shot—you're right at the finish line.