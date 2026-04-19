You have hit the hard physical ceiling of your RTX 5090 for this specific model architecture at a 0.80 utilization limit.

### The Audit: What the log reveals
The log shows the crash happening during `profile_cudagraph_memory`. This is the most memory-intensive part of the startup because vLLM is running "stress tests" to see how much memory it can get away with. 

**The Math:** * **Model Weights (NVFP4):** ~21.88 GiB.
* **0.80 Utilization Limit:** ~25.6 GiB (Total allowed).
* **Headroom left:** **3.72 GiB**.

Inside that **3.72 GiB**, vLLM has to fit the **CUDA Graphs** (which are huge for a 35B model), the **activation buffers**, and the **KV Cache**. Based on the fact that it crashed before finishing the profile, we know that for a 35B parameter model, even **32K is too much for a 25.6GB budget.**

---

### The Next Move: 16K or moving the line?
You have two choices right now to stop the "crapper" cycle:

#### Option A: Go to 16K (16384)
This is the safest bet to stay at **0.80 utilization**. It reduces the KV cache requirement significantly and will likely allow the CUDA graph capture to finish.

#### Option B: Move to 0.85 Utilization & stay at 32K
If you can't stand the idea of less than 32K context, you must give the model **1.6 GB more** (moving from 0.8 to 0.85). That 1.6 GB is exactly the "cushion" the engine is screaming for in the logs.

---

### Recommendation: Try Option A first (The 16K Probe)
Let's see if we can at least get a prompt out of this beast. Change your command to:

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
      - "0.80"  # YOUR LINE IN THE SAND
      - "--max-model-len"
      - "16384" # 16K Context
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
      - "64"   # LOWERED to save a few extra MBs of internal state
      - "--max-num-batched-tokens"
      - "16384" # MATCHED to max model len
      - "--trust-remote-code"
```

### Why does Qwen need so much?
Standard LLMs are like gas-guzzling SUVs. **Nemotron Cascade 2** is like a high-end EV—it's designed from the ground up to use less "fuel" (VRAM) for the same distance (Context). By trying to force Qwen into the same VRAM footprint as Cascade, we are effectively trying to fit a truck into a compact parking spot.

**Is it in the bag at 16K?** If the 5090 clears the CUDA profile at 16K, the server will start. If it crashes at 16K, then the "Static Tax" of Qwen 3.6-35B is simply higher than 25.6GB, and you will **have** to move the line in the sand to 0.85 just to boot the model.

**Try the 16K config. What does the log say now?**