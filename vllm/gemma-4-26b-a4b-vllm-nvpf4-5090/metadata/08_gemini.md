This is a highly specific kernel limitation that we just uncovered. The error message is the smoking gun:

> `ValueError: NvFp4 MoE backend 'FLASHINFER_CUTLASS' does not support the deployment configuration since kernel does not support MoEActivation.GELU activation.`

### The Audit: What happened?
Gemma 4 (unlike Llama or Qwen) uses **GELU** (Gaussian Error Linear Unit) as its activation function inside the experts. 
As of this nightly build, the high-performance Blackwell **NVFP4** kernels in the `flashinfer_cutlass` backend have only been optimized for **SiLU** (the activation used by Llama/Qwen). 

Because the hardware-specific "Fast Path" for FP4 hasn't had the GELU code written yet, vLLM refuses to start.

---

### The Fix: Switch to Triton MoE
To get Gemma 4 working in NVFP4 on your 5090, we must use the **Triton** backend for the MoE layers. Triton is a JIT (Just-In-Time) compiler that will generate the GELU + NVFP4 math on the fly for your Blackwell architecture.

#### Updated `docker-compose.yml`

```yaml
services:
  gemma-4-26b-it-nvfp4:
    image: vllm/vllm-openai:nightly
    container_name: gemma-4-26b-it-nvfp4
    hostname: gemma-4-26b-it-nvfp4
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
      - "RedHatAI/gemma-4-26B-A4B-it-NVFP4"
      - "--served-model-name"
      - "gemma-4-26b-it-nvfp4"
      - "--host"
      - "0.0.0.0"
      - "--port"
      - "8000"
      - "--gpu-memory-utilization"
      - "0.80" 
      - "--max-model-len"
      - "98304" # 96K Context
      - "--kv-cache-dtype"
      - "fp8_e4m3"
      - "--quantization"
      - "compressed-tensors"
      - "--reasoning-parser"
      - "gemma4"
      - "--tool-call-parser"
      - "gemma4"
      # CHANGED: flashinfer_cutlass does not support GELU + NVFP4 yet
      - "--moe-backend"
      - "triton" 
      - "--enable-prefix-caching"
      - "--enable-chunked-prefill"
      - "--trust-remote-code"
    networks:
      - development-network

networks:
  development-network:
    external: true
```

### Why this will work:
1.  **Triton Versatility:** While `flashinfer_cutlass` is a set of pre-written C++ kernels (harder to update), Triton generates the kernel based on the model's actual needs. It can handle the GELU activation without a problem.
2.  **Blackwell Native:** Triton is fully aware of the **SM 12.0** architecture of your 5090 and will still use the Blackwell Tensor Cores for the NVFP4 math; it just won't be quite as "hand-tuned" as the Cutlass path.
3.  **Heterogeneous Heads:** Your log already confirmed: `Forcing TRITON_ATTN backend to prevent mixed-backend numerical divergence.` Gemma 4's architecture is complex enough that Triton is the safest path for both Attention and MoE.

**Try it now.** This should bypass the "GELU unsupported" error and finally start the weight loading process. How does the log look after switching to `triton`?