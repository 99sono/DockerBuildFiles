# git diff

```diff
diff --git a/vllm/qwen-3.6-27b-vllm-nvfp4-rtx5090/docker-compose.yml b/vllm/qwen-3.6-27b-vllm-nvfp4-rtx5090/docker-compose.yml
index deed75b..8122c3f 100644
--- a/vllm/qwen-3.6-27b-vllm-nvfp4-rtx5090/docker-compose.yml
+++ b/vllm/qwen-3.6-27b-vllm-nvfp4-rtx5090/docker-compose.yml
@@ -6,91 +6,61 @@ services:
     container_name: qwen-3-6-27b-nvfp4-mtp-stable
     hostname: qwen-3-6-27b-nvfp4-mtp
     platform: linux/amd64
-
     ports:
       - "8000:8000"
-
     volumes:
       - ~/.cache/huggingface:/root/.cache/huggingface
       - /dev/shm:/dev/shm
-
     shm_size: "32g"
     ipc: host
-
     deploy:
       resources:
         reservations:
           devices:
             - capabilities: [gpu]
-
     environment:
-      # Required for Blackwell + WSL2 stability
+      # JIT Tuning disabled to protect the WSL2 driver
+      FLASHINFER_AUTOTUNE: "0"
       VLLM_WORKER_MULTIPROC_METHOD: spawn
-
-      # Critical for very large KV-cache allocations
-      PYTORCH_CUDA_ALLOC_CONF: expandable_segments:True
-
-      # Optional but useful for faster model pulls
-      HF_HUB_ENABLE_HF_TRANSFER: "1"
+      PYTORCH_CUDA_ALLOC_CONF: "expandable_segments:True"
 
     command:
-      # Model paths (pulled from global HF cache)
-      # there is an NVFP4 version https://huggingface.co/sakamakismile/Qwen3.6-27B-NVFP4
-      # https://huggingface.co/sakamakismile/Qwen3.6-27B-Text-NVFP4-MTP
-      # 
+      - "--model"
       - "sakamakismile/Qwen3.6-27B-Text-NVFP4-MTP"
       - "--served-model-name"
       - "qwen3.6-27b-text-nvfp4-mtp"
       - "--trust-remote-code"
-
-      # Required
       - "--host"
       - "0.0.0.0"
       - "--port"
       - "8000"
 
-      # Memory budget
-      - "--gpu-memory-utilization"
-      - "0.9"
+      # 1. FIX: Just use the valid flag to bypass the missing vision config
+      - "--language-model-only"
 
-      # ===== Long-context experiment =====
+      # 2. CONSERVATIVE MEMORY & CONTEXT
+      - "--gpu-memory-utilization"
+      - "0.80"
       - "--max-model-len"
-      - "131072"
-
-      # Batching (intentionally conservative for long windows)
-      - "--max-num-seqs"
-      - "2"
-      - "--max-num-batched-tokens"
-      - "16384"
-
-      # KV cache
+      - "32768"
       - "--kv-cache-dtype"
       - "fp8"
 
-      # Quantization
+      # 3. KERNEL STABILITY (Triton over Cutlass to avoid TMA descriptor crash)
       - "--quantization"
-      - "modelopt"
+      - "compressed-tensors"
+      - "--moe-backend"
+      - "triton" 
 
-      # Long-context ergonomics
+      # 4. ENGINE ERGONOMICS
       - "--enable-prefix-caching"
       - "--enable-chunked-prefill"
-
-      # Reasoning + tools
       - "--reasoning-parser"
       - "qwen3"
-      - "--language-model-only"
-
-      # NVFP4 MoE backend (performance path)
-      - "--moe-backend"
-      - "cutlass"
-
-      # Speculative Decoding
-      - "--speculative-config"
-      - '{"method":"qwen3_5_mtp","num_speculative_tokens":3}'
-
-      # Optional ultra-stability fallback (DISABLED by default)
-      # - "--moe-backend"
-      # - "marlin"
+      
+      # 5. WSL2 GRAPH CRASH PREVENTION
+      # quote: (APIServer pid=1) INFO 05-01 17:08:18 [vllm.py:1089] Cudagraph is disabled under eager mode
+      - "--enforce-eager"
 
     networks:
       - development-network
```
