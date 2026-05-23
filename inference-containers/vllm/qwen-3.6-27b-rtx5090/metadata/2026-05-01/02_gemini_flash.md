The root cause of this explosion is a **"device not ready"** error during the FlashInfer autotuning process. This typically happens because the RTX 5090 (Blackwell) is trying to run highly optimized **NVFP4** kernels that are hitting a synchronization or timeout issue within the WSL2/Docker environment.

Here is the audit of your crash and how to fix it to get that MTP model running:

### 1. The Critical Failure: `RuntimeError: CUDA driver error: device not ready`
The logs show the engine was halfway through tuning the `fp4_gemm` kernels (87% complete) when the GPU essentially "stopped responding" to the driver. This is common on Blackwell in WSL2 when **CUDA Graphs** and **FlashInfer autotuning** collide during the warmup phase.

### 2. Fixes for the Docker Compose

#### **A. Disable FlashInfer Autotuning (Stability Path)**
FlashInfer is trying to benchmark the best NVFP4 path on the fly. On a single GPU, you can bypass this "hanging" by forcing vLLM to use pre-calculated paths.
*   **Add this Env Var:** `VLLM_FLASHINFER_CHECK_SAFE_OPS=0`
*   **And this Env Var:** `FLASHINFER_AUTOTUNE=0`

#### **B. Fix the Speculative Method**
The log explicitly warned you: `method qwen3_5_mtp is deprecated`.
*   **Change:** `{"method":"qwen3_5_mtp"}` to `{"method":"mtp"}`.

#### **C. Adjust the Quantization Flag**
While the checkpoint says `modelopt`, for this specific Sakamakismile MTP merge, vLLM often prefers the more generic `compressed-tensors` or `fp4` flag to trigger the correct Cutlass kernels.

### 3. Revised `command` Section
Update your `command` list to this for maximum Blackwell/WSL2 stability:

```yaml
    command:
      - "sakamakismile/Qwen3.6-27B-Text-NVFP4-MTP"
      - "--served-model-name"
      - "qwen3.6-27b-text-nvfp4-mtp"
      - "--trust-remote-code"
      - "--host"
      - "0.0.0.0"
      - "--port"
      - "8000"
      - "--gpu-memory-utilization"
      - "0.82" # Dropped slightly for MTP overhead safety
      - "--max-model-len"
      - "131072"
      - "--kv-cache-dtype"
      - "fp8"
      - "--quantization"
      - "compressed-tensors" # More stable than 'modelopt' for MTP
      - "--enable-prefix-caching"
      - "--enable-chunked-prefill"
      - "--reasoning-parser"
      - "qwen3"
      # Force the Backend: Add --attention-backend flashinfer. The log showed it was trying to decide between FLASHINFER and TRITON. Forcing one reduces the warmup complexity.
      - "--attention-backend flashinfer"
      - "--moe-backend"
      - "cutlass"
      - "--speculative-config"
      - '{"method":"mtp","num_speculative_tokens":3}'
      - "--enforce-eager" # CRITICAL: This bypasses the CUDA Graph profiling that caused the hang
```

### 4. Why `--enforce-eager`?
In your logs, the crash happened exactly when vLLM started "Profiling CUDA graph memory." On WSL2, Blackwell's memory management can be finicky with CUDA Graphs. Adding `--enforce-eager` disables the graph capture. You lose a tiny bit of throughput (~5-10%), but it prevents the "Device not ready" crash entirely.

### 5. Final Hardware Check
Since you are on WSL2:
1.  **Update your Host Driver:** Ensure you are on the latest NVIDIA Game Ready or Studio driver (v570+ is recommended for Blackwell support).
2.  **WSL Config:** Ensure your `.wslconfig` has enough system RAM allocated (at least 64GB), as vLLM spawns multiple processes for MTP that require shared memory.

**Try running with `--enforce-eager` and `quantization: compressed-tensors` first.** If it boots, we can then try to re-enable CUDA graphs for that extra speed boost.


# Gemini feedback 02

Looking closely at your log, the answer is a mix of **VRAM pressure** and a **kernel synchronization failure**. 

You are right that the official Hugging Face model card doesn't mandate the settings I suggested, but they are likely testing on **A100/H100/H200** GPUs (SM 80/90). The **RTX 5090 (SM 12.0)** on **WSL2** adds a layer of complexity—specifically how the Windows host manages the GPU driver compared to a native Linux server.

Here is the breakdown of why it "blew up" and if VRAM is the culprit:

### 1. Was it a lack of VRAM? (The "Soft" OOM)
Yes and No. You didn't get a standard `OutOfMemoryError`, but you hit a **Profiling Timeout**.
*   **The Log Evidence:** `Available KV cache memory: 6.56 GiB`. 
*   **The Problem:** For a 128k context window, 6.56 GB is **extremely tight**. When vLLM attempted the "warmup" (the autotuning of the FP4 kernels), it tried to allocate temporary workspace buffers. 
*   **The Result:** Because your `gpu-memory-utilization` was at **0.9**, vLLM had already "locked away" almost everything else. The autotuner likely tried to grab a few hundred MBs for its tests, found the cupboard bare, and the CUDA driver effectively "timed out" trying to find space, leading to the `device not ready` error.



### 2. The MTP "Double-Dip"
The log shows: `Detected MTP model. Sharing target model embedding weights... Sharing target model lm_head weights...`
Even though MTP shares weights, it still requires **separate KV cache space** for the speculative heads. 
*   Standard Qwen 3.6 27B has a certain KV overhead.
*   The MTP version adds extra "drafting" overhead.
On a 32GB card, running **128k context** with **MTP** at **90% utilization** leaves almost zero room for the **FlashInfer JIT compiler** to work.

### 3. Why the "Hugging Face Settings" didn't work for you
The people who uploaded the model are likely running on **Linux Native**.
*   **WSL2 Overhead:** Windows takes a small "tax" on VRAM to manage the display and the DWM (Desktop Window Manager). Even if your monitor is off, the driver reserves a buffer.
*   **The "Device Not Ready" Loop:** This specific error in your log (`RuntimeError: CUDA driver error: device not ready`) is the classic WSL2 signature of a **GPU TDR (Timeout Detection and Recovery)**. The GPU took too long to respond during the autotuning, and Windows "restarted" the driver link while the Docker container was still using it.

---

### How to adapt the Guide for the 5090
If you want to keep that **128k context**, you have to compromise on the "buffer" space to let the kernels initialize.

**Try these three surgical changes to your Compose:**
1.  **Lower Utilization:** Set `--gpu-memory-utilization 0.82`. This sounds counter-intuitive (you want more memory), but it leaves 18% of the card "unmanaged" by vLLM. The FlashInfer autotuner will use this "free" space to compile its kernels. Once it finishes, it releases it.
2.  **Force the Backend:** Add `--attention-backend flashinfer`. The log showed it was trying to decide between `FLASHINFER` and `TRITON`. Forcing one reduces the warmup complexity.
3.  **Bypass Autotuning:** Add the environment variable `VLLM_FLASHINFER_CHECK_SAFE_OPS=0`.

**My recommendation:** If it still fails with `device not ready`, it is a hardware-timing issue with WSL2. In that case, use `--enforce-eager`. It's the only way to tell vLLM: *"Don't try to be clever and profile the card, just run the model."*

Does the log show any "Mamba" related errors further up? I noticed a warning about `Mamba cache mode`. Qwen 3.6 uses a hybrid architecture, and Mamba layers can be very picky about how they share memory with speculative heads.