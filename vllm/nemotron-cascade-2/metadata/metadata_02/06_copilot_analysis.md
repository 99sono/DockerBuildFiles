
This crash is **not random**, and it is **not caused by Cline** or your prompt pattern.

What you just hit is a **known, reproducible failure mode of NVFP4 MoE on desktop Blackwell (SM120 / RTX 5090)** when using **FlashInfer CUTLASS FP4 kernels + CUDA graphs + large context**.

Let me explain *exactly* what happened, why it happens right around **\~29–30k tokens**, and what you should do next.

***

## What the error actually means (plain English)

    torch.AcceleratorError: CUDA error: an illegal instruction was encountered

This error **does not mean**:

*   out of memory
*   bad prompt
*   bug in Cline
*   Python error

It means:

> **The GPU executed a CUDA instruction that is invalid for this specific SM version.**

On Blackwell, this almost always points to:

*   **a kernel compiled for SM 12.0 being executed on SM 12.1**
*   **or a CUTLASS TMA (Tensor Memory Access) kernel selecting an illegal warp specialization**

This is *well‑documented* right now for:

*   vLLM
*   FlashInfer
*   NVFP4 MoE
*   SM120/121 consumer Blackwell

 [\[github.com\]](https://github.com/vllm-project/vllm/issues/38208), [\[huggingface.co\]](https://huggingface.co/nologik/vllm-dgx-spark/discussions/1), [\[blog.avarok.net\]](https://blog.avarok.net/from-20-to-35-tokens-second-optimizing-nvfp4-inference-on-blackwell-gb10-306a84bff467)

***

## Why it crashed at \~29,622 tokens specifically

From your dump:

    num_computed_tokens=[29622]
    num_output_tokens=[2]
    total_num_scheduled_tokens=1

This tells us:

*   Prefill already happened successfully
*   Decoder entered **single‑token step**
*   CUDA graph replay was attempted
*   **An FP4 MoE grouped GEMM kernel executed**
*   GPU hit an illegal instruction during the async copy fence

This exact pattern is reported in:

*   vLLM issue #38208 (Nemotron NVFP4 + CUDA graph) [\[github.com\]](https://github.com/vllm-project/vllm/issues/38208)
*   FlashInfer FP4 MoE on Spark / SM120 [\[github.com\]](https://github.com/flashinfer-ai/flashinfer/issues/2065)
*   Multiple SM120 NVFP4 MoE benchmarks [\[discuss.vllm.ai\]](https://discuss.vllm.ai/t/sm120-rtx-pro-6000-nvfp4-moe-performance-report-qwen3-5-397b/2536)

The trigger conditions are:

✅ FP4 MoE  
✅ FlashInfer CUTLASS backend  
✅ CUDA graphs enabled  
✅ Long context (≥ \~25–30k tokens)  
✅ Decode stage

You hit **all five**.

***

## Why this started happening only after “things seemed faster”

This part is important.

Earlier you were likely on:

*   fallback kernels
*   eager execution
*   slower MoE path

Once you:

*   enabled FP4 correctly
*   removed `--enforce-eager`
*   enabled CUDA graphs
*   pushed context higher

You crossed from:

> **“slow but safe” → “fast but unstable kernel path”**

This exact trade‑off is known and acknowledged by both vLLM and FlashInfer maintainers.

***

## This is confirmed SM120 behavior (not just you)

From real reports on RTX 5090 / RTX PRO 6000 (SM120):

*   **FlashInfer CUTLASS NVFP4 MoE path is unstable**
*   Certain TMA warp‑specialized grouped GEMMs fail
*   They either:
    *   produce garbage output
    *   slow down drastically
    *   or crash with`illegal instruction`

 [\[discuss.vllm.ai\]](https://discuss.vllm.ai/t/sm120-rtx-pro-6000-nvfp4-moe-performance-report-qwen3-5-397b/2536), [\[blog.avarok.net\]](https://blog.avarok.net/from-20-to-35-tokens-second-optimizing-nvfp4-inference-on-blackwell-gb10-306a84bff467)

***

## What you should do *right now* (safe, pragmatic fixes)

You have two realistic options.

***

### ✅ **Option A: Stay on vLLM, sacrifice FP4 MoE kernels**

This is the **recommended stability path today** on RTX 5090.

Force Marlin MoE backend (W4A16 internally, FP4 weights still loaded):

```yaml
environment:
  VLLM_MOE_FORCE_MARLIN: "1"
```

or CLI:

```bash
--moe-backend marlin
```

What you get:

*   ✅ No illegal instruction crashes
*   ✅ CUDA graphs remain safe
*   ✅ Stable long‑context generation
*   ❌ Slightly lower peak throughput than ideal FP4

This is exactly what experienced SM120 users are doing right now.

 [\[discuss.vllm.ai\]](https://discuss.vllm.ai/t/sm120-rtx-pro-6000-nvfp4-moe-performance-report-qwen3-5-397b/2536)

***

### ✅ **Option B: Disable CUDA graphs just for MoE**

If you want to keep pure FP4 kernels:

```bash
--enforce-eager
```

This avoids CUDA graph replay entirely.

Trade‑off:

*   ✅ More stable than graph replay
*   ❌ Slower decode (\~20–30% loss)
*   ❌ Still *can* crash at very long contexts

This is **not as reliable** as Option A.

***

## ❌ What will NOT actually fix this

Just so you don’t waste time:

*   ❌ Changing prompt size alone
*   ❌ Prefix caching tweaks
*   ❌ Different client (Cline vs curl)
*   ❌ More VRAM
*   ❌ Different batch size

The crash happens **inside a single kernel invocation**.

***

## Why SGLang sometimes survives when vLLM doesn’t

You may see people say:

> “It works in SGLang”

That’s because:

*   SGLang uses **different kernel selection**
*   Or avoids CUDA graph replay differently

But even SGLang reports **NVFP4 MoE illegal instruction crashes** on SM120 under certain workloads.

 [\[joshua8.ai\]](https://joshua8.ai/minimax-m25-rtx-6000-blackwell-sglang-guide/)

***

## Bottom line (very important)

You did **nothing wrong**.

You discovered a **real edge of the current Blackwell FP4 software stack**.

### Your choices today on RTX 5090:

| Goal           | Recommendation                    |
| -------------- | --------------------------------- |
| Stability      | **Marlin MoE backend**            |
| Peak FP4 speed | Datacenter Blackwell (B200/GB200) |
| Experimenting  | FP4 + eager (expect crashes)      |

This *will* get fixed upstream — but as of **April 2026**, this is the reality.

***

## If you want, next steps I can help with

*   Provide a **crash‑proof docker‑compose variant** (Marlin‑forced)
*   Tune Marlin path for max batch‑1 speed
*   Show how to detect **kernel path selection** in logs
*   Compare vLLM vs SGLang realistically on SM120
*   Explain which future fixes to watch in FlashInfer / vLLM

Just tell me.
