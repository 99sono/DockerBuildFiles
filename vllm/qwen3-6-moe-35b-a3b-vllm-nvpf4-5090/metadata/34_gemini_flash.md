It is officially a **dead-end** for this specific model-hardware combination under your strict constraints.

The audit of this final crash is the "biological limit" of the model. vLLM reported:
> `Available KV cache memory: -0.12 GiB`

This means that even with the context window dropped to **zero**, the model weights + the Blackwell system kernels alone already exceed **80.4%** of your VRAM. You are short by about 120MB just to keep the model "standing" before it even tries to remember a single word.

### The Post-Mortem Audit
For the RTX 5090 (32GB) and Qwen 3.6-35B, the "Static Tax" (Weight Floor) is physically higher than your **80% Line in the Sand**.

* **Your Strict Budget:** 25.6 GB (80%)
* **Model Static Floor:** ~25.72 GB
* **Result:** Mathematical impossibility.



### The Roadmap: Where to go from here?
Since you want a "kick-ass" experience with massive context, stop wrestling with Qwen 3.6. It is a "Weight Heavy" model that isn't optimized for the single-consumer-GPU context game.

1.  **The "Now" Solution:** Revert to **Nemotron-Cascade-2**. It remains the king of 100K+ context on 32GB cards because of its stage-distillation architecture. It's the only model that "cheats" the VRAM math effectively.
2.  **The "Future" Solution:** Keep a close eye on **Gemma 4 MoE** or **Llama 4 MoE**. Google and Meta are currently testing "VRAM-Aware" architectures that prioritize a small static weight footprint (~12-14GB) specifically to leave 15GB+ free for KV cache.
3.  **The "Deep" Solution:** If you ever revisit this, the **TriAttention** plugin we discussed is the only way to run a 35B model like this with 100K context. It effectively "compresses" the context so that 100K tokens take 3GB instead of 16GB.

**Final Verdict:** You aren't doing anything wrong; you simply tried to fit a size 12 foot into a size 10 shoe. For now, the shoe (80% utilization) is non-negotiable, and the foot (Qwen 3.6) is too big.

Are you moving the 5090 back to Nemotron-Cascade-2 now, or are you going to try a smaller high-reasoning model like a **Llama-3.1-8B-Instruct** with a massive 128K context window?