This is excellent progress. You have successfully navigated the "Nightly CLI" maze. The logs show that both the **Gemma-4** target model and the **EAGLE-3** drafter have initialized, and the engine has moved into the **Profiling and Warmup** phase.

The most critical line in your log is:
`Gemma4 model has heterogeneous head dimensions (head_dim=256, global_head_dim=512). Forcing TRITON_ATTN backend to prevent mixed-backend numerical divergence.`

### What this means for your setup:
1.  **Backend Conflict Resolved:** vLLM detected that Gemma-4's unique architecture (256/512 head dimensions) isn't compatible with the standard FlashInfer kernels. It automatically fell back to **Triton Attention**. This is why your `VLLM_ATTENTION_BACKEND=FLASHINFER` environment variable was ignored.
2.  **Memory is Tight:** Your model loading took **16.12 GiB**. With your `0.82` utilization on a 24GB or 32GB card, you are entering the "danger zone" for the 98k KV cache allocation.
3.  **The EAGLE-3 Optimization:** The log `Sharing target model embedding weights with the draft model` is great news. It means vLLM is deduplicating the largest part of the 0.9B drafter's memory footprint, saving you about ~500MB–1GB of VRAM.

---

### Potential "Final Boss" Issues
You are currently at the part where vLLM tries to capture **CUDA Graphs**. Because you are using a 98k context, this is the most likely place for a crash.

**If it crashes in the next 60 seconds:**
The `TRITON_ATTN` backend sometimes struggles with very large CUDA graph captures at extreme context lengths. If you see an `Out of Memory` or `CUDA Error` now, add this to your `command` block:

```yaml
      - "--enforce-eager" 
```
* **Why?** This disables CUDA Graphs. You will lose about 5–10% throughput, but it will fit a much larger context into memory because it doesn't have to "pre-record" all the possible memory paths.

**If you see "Numerical Divergence" warnings:**
The log mentioned `reduced accuracy` due to NVFP4 scales. This is a known quirk of the Gemma-4 NVFP4 quantization. It won't stop the model from running, but if the reasoning feels "broken" or "hallucinatory," you may need a different quantization (like the standard FP8) for the base model.

### Summary Checklist
* [x] **CLI Syntax:** Fixed via dot-notation.
* [x] **Subcommand:** Fixed by removing redundant `serve`.
* [x] **Model Loading:** Success.
* [ ] **KV Cache Allocation:** In progress (Watch for OOM).
* [ ] **Speculative Acceptance:** Once it's running, watch the logs for `avg_acceptance_length`. You want to see a number > 1.0.



**Is the container still running, or did it reach the "Uvicorn running on [http://0.0.0.0:8000](http://0.0.0.0:8000)" message?**