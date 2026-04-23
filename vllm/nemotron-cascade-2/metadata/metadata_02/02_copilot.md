# docker compose

```yaml
# Nemotron-Cascade-2-30B-A3B-NVFP4 (Optimized Speed Path)
# Hardware: RTX 5090 (Blackwell) + WSL2
# Strategy: Native Blackwell FP4 execution with high batching

services:
  nemotron-cascade:
    image: vllm/vllm-openai:nightly
    container_name: nemotron-cascade-2-nvfp4
    hostname: nemotron-cascade-2-nvfp4
    platform: linux/amd64
    ports:
      - "8000:8000"
    volumes:
      - ~/.cache/huggingface:/root/.cache/huggingface
    ipc: host

    deploy:
      resources:
        reservations:
          devices:
            - capabilities: [gpu]

    environment:
      # Use 'spawn' for stability on Blackwell cards in WSL2
      - VLLM_WORKER_MULTIPROC_METHOD=spawn
      # Enable high-performance MoE kernels for FP8/FP4
      - VLLM_USE_FLASHINFER_MOE_FP8=1
      - VLLM_FLASHINFER_MOE_BACKEND=throughput

    command:
      - "chankhavu/Nemotron-Cascade-2-30B-A3B-NVFP4"
      - "--served-model-name"
      - "chankhavu/Nemotron-Cascade-2-30B-A3B-NVFP4"
      - "--trust-remote-code"
      - "--quantization"
      - "modelopt_fp4"
      - "--kv-cache-dtype"
      - "fp8_e4m3"
      - "--gpu-memory-utilization"
      - "0.85"
      - "--max-model-len"
      - "196608"
      - "--max-num-batched-tokens"
      - "32768"
      - "--mamba-ssm-cache-dtype"
      - "float32"
      - "--enforce-eager"
      - "--tool-call-parser"
      - "qwen3_coder"
      - "--reasoning-parser"
      - "nemotron_v3"

    networks:
      - development-network

networks:
  development-network:
    external: true
```    

# Metadata
You’re not imagining things — **\~17 tok/s on a 5090 for Nemotron‑Cascade‑2 NVFP4 is a classic “falling off the fast path” symptom**, and your config actually makes it *more* likely. The short answer is: **yes, vLLM nightly (or a newer Blackwell‑enabled image) is very likely a better fit**, *but* there are also a few concrete knobs you can turn immediately that explain the behavior you’re seeing.

Below I’ll break this down into **what’s going wrong**, **what to change right now**, and **what moving to nightly really buys you**, grounded in current Blackwell/NVFP4 state.

***

## 1. What the logs are telling us

    Avg generation throughput: ~17 tokens/s
    Running: 1 reqs
    GPU KV cache usage: 7.5%
    Prefix cache hit rate: 0.0%

This combination strongly suggests:

1.  **You’re decode‑bound at batch=1**
2.  **MoE FP4 kernels are *not* the dominating cost**
3.  vLLM is effectively running in a *low‑occupancy interactive path*

That matches known behavior on **desktop Blackwell (SM120/SM121)** when:

*   CUDA graphs aren’t engaged
*   Decode batch is tiny
*   Or FlashInfer FP4 kernels aren’t fully selected

Blackwell FP4 shines at **moderate decode batching**, not single‑token interactive decode unless the right path is used. [\[huggingface.co\]](https://huggingface.co/blog/apsys/blackwell-nvfp4-comparison)

***

## 2. Critical issue in your config (this is big)

### ❌ You enabled the *wrong* MoE kernel flag

```yaml
- VLLM_USE_FLASHINFER_MOE_FP8=1
```

But your model is **NVFP4**, not FP8.

For FP4 MoE on Blackwell, vLLM explicitly requires:

```bash
VLLM_USE_FLASHINFER_MOE_FP4=1
```

This is documented in vLLM’s Blackwell FP4 guidance and recent benchmarking posts. [\[vllm-proje....github.io\]](https://vllm-project.github.io/2026/02/13/gb300-deepseek.html)

What happens otherwise:

*   vLLM silently falls back to **non‑FP4 MoE kernels**
*   You pay FP4 dequant overhead without FP4 tensor‑core throughput
*   Decode collapses to \~10–20 tok/s (exactly what you see)

✅ **Fix immediately**:

```yaml
environment:
  - VLLM_WORKER_MULTIPROC_METHOD=spawn
  - VLLM_USE_FLASHINFER_MOE_FP4=1
  - VLLM_FLASHINFER_MOE_BACKEND=throughput
```

***

## 3. You’re kneecapping decode with eager mode

```yaml
--enforce-eager
```

This completely **disables CUDA Graph capture**, which is *the* main decode accelerator on Blackwell for small batches.

On NVFP4 models, eager mode:

*   Prevents kernel fusion
*   Forces repeated launch overhead
*   Reduces SM occupancy at decode batch=1

Multiple Blackwell benchmarks show **5–10× decode differences** between eager and captured paths for NVFP4 MoE models. [\[vllm.ai\]](https://vllm.ai/blog/dsr1-gb200-part1)

✅ **Action**: remove it

```diff
- --enforce-eager
```

Instead, explicitly allow graph capture:

```yaml
--max-cudagraph-capture-size 512
```

(This is the value NVIDIA and vLLM folks are actually using for Nemotron‑Cascade NVFP4.) [\[forums.dev...nvidia.com\]](https://forums.developer.nvidia.com/t/psa-state-of-fp4-nvfp4-support-for-dgx-spark-in-vllm/353069?page=10)

***

## 4. Max context length is hurting you *right now*

```yaml
--max-model-len 196608
```

Even with only a short prompt, this forces:

*   KV cache sized for \~200k tokens
*   Larger paging tables
*   More conservative scheduling

On Blackwell, long‑context KV allocation **lowers decode occupancy**, especially with FP8 KV caches. [\[forums.dev...nvidia.com\]](https://forums.developer.nvidia.com/t/psa-state-of-fp4-nvfp4-support-for-dgx-spark-in-vllm/353069?page=10)

✅ If you’re benchmarking speed, temporarily drop to:

```yaml
--max-model-len 65536
```

You can raise it again later once decode batching is healthy.

***

## 5. You aren’t actually batching decode

```yaml
--max-num-batched-tokens 32768
Running: 1 reqs
```

This flag only matters **when vLLM actually has multiple sequences**.

At batch=1:

*   MoE routing overhead dominates
*   FP4 wins are minimal
*   vLLM is slower than you expect (this is well documented) [\[huggingface.co\]](https://huggingface.co/blog/apsys/blackwell-nvfp4-comparison)

✅ For throughput testing:

*   Send **8–32 concurrent requests**
*   Or increase `--max-num-seqs` explicitly:

```yaml
--max-num-seqs 128
```

***

## 6. Yes — vLLM nightly *is* meaningfully better here

Why nightly helps (today):

*   Desktop Blackwell (RTX 5090) is **SM120**
*   NVFP4 work landed **first for datacenter Blackwell (SM100)**
*   Nightly includes:
    *   New CUTLASS FP4 schedules
    *   Better FlashInfer FP4 dispatch
    *   Fewer fallback paths

This gap is explicitly acknowledged by both NVIDIA and vLLM maintainers. [\[allenkuo.medium.com\]](https://allenkuo.medium.com/finishing-what-we-started-gemma-4-nvfp4-on-vllm-desktop-blackwell-wsl2-b2088c34815a)

✅ Recommendation:

```yaml
image: vllm/vllm-openai:nightly
```

If you want *maximum* performance, some users even report better results with **NVIDIA’s NGC vLLM images** compiled against newer CUDA/CUTLASS, but nightly is the lowest‑effort step first. [\[allenkuo.medium.com\]](https://allenkuo.medium.com/finishing-what-we-started-gemma-4-nvfp4-on-vllm-desktop-blackwell-wsl2-b2088c34815a)

***

## 7. A “known good” delta you can try immediately

Here’s a minimal patch that usually moves **\~15 tok/s → 60–100+ tok/s** on a 5090 under light batching:

```diff
environment:
-  VLLM_USE_FLASHINFER_MOE_FP8=1
+  VLLM_USE_FLASHINFER_MOE_FP4=1

command:
-  --enforce-eager
+  --max-cudagraph-capture-size 512
+  --max-num-seqs 128
-  --max-model-len 196608
+  --max-model-len 65536
```

***

## Bottom line

Your setup is **very close**, but currently:

*   ❌ FP4 MoE kernel is not engaged
*   ❌ CUDA graphs are disabled
*   ❌ Decode batch is too small
*   ❌ Context length suppresses occupancy
*   ✅ Hardware and model choice are fine

Switching to **vLLM nightly + the FP4 flag fix alone** is usually enough to cross from “disappointing” into “this is why Blackwell exists.”

If you want, next step we can:

*   Tune for **latency vs throughput**
*   Compare against **SGLang FP4** (it wins at batch=1)
*   Or validate **actual kernel selection** via vLLM debug logs

Just tell me which direction you want to push.
