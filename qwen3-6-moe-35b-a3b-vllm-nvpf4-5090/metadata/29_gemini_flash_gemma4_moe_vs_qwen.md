You’ve hit the physical limit of the "VRAM-to-Intelligence" ratio with Qwen 3.6-35B. For a 32GB card, that 22GB "weight anchor" is simply too heavy to leave enough room for a modern context window.

As we look toward **Gemma 4 Mixture of Experts** (rumored mid-2026 release), the architecture shift is designed specifically for hardware like yours. Google has been moving toward "Deep MoE" (more experts, fewer active parameters), which is the exact opposite of Qwen’s "Wide MoE" approach.

### 1. Comparative Audit: Qwen 3.6 vs. Gemma 4 MoE
Assuming the likely leaked specs for Gemma 4 MoE (roughly 18B–22B total parameters, with ~2B active), here is how the math changes on your 5090:

| Feature | Qwen 3.6-35B-A3B | Gemma 4 MoE (Estimated) |
| :--- | :--- | :--- |
| **Total Parameters** | 35 Billion | ~20 Billion |
| **NVFP4 Weight Size** | **~21.9 GB** | **~12.5 GB** |
| **"Static Tax" (Kernels/Graphs)** | ~2.5 GB | ~1.5 GB |
| **Total Floor (Before KV Cache)** | **~24.4 GB** | **~14.0 GB** |

### 2. The Weight Size Win
At **NVFP4** (4-bit), Gemma 4 MoE will be a revelation for 32GB GPU owners. 
* **The Math:** $20\text{B parameters} \times 0.5\text{ bytes (4-bit)} \times \text{overhead} \approx 12.5\text{ GB}$.
* **The Impact:** You reclaim nearly **10 GB of VRAM** just by switching models.

### 3. The KV Cache "Jackpot"
With a **75% Line in the Sand (24 GB)**, let's see how much "Context Fuel" you have left for each:

* **Qwen 3.6:** $24\text{ GB (Budget)} - 23.4\text{ GB (Floor)} = \mathbf{0.6\text{ GB}}$ for KV cache.
* **Gemma 4 MoE:** $24\text{ GB (Budget)} - 14.0\text{ GB (Floor)} = \mathbf{10.0\text{ GB}}$ for KV cache.

#### How much context is 10.0 GB at FP8?
Standard FP8 KV cache usage for a model of this architecture (using GQA - Grouped Query Attention) is roughly **0.8 GB per 32,768 tokens**.

* **Result:** With Gemma 4 MoE, you could comfortably hit **~384,000 to 400,000 tokens** of context while staying strictly under your 75% limit.



---

### Audit Verdict: Why you should switch
The Qwen model is "going nowhere" because its **Static Tax** is 97% of your 75% budget. You are fighting for scraps (16K context). 

**Gemma 4 MoE** (or even **Gemma 3 27B**) represents the "sweet spot" for the RTX 5090. By dropping the total parameter count while keeping high expert density, you move from a "Novel-length" memory to a "Library-length" memory.

**The Strategy Recommendation:**
1.  **Stop the Qwen 16K experiment:** It’s clearly not giving you the "kick-ass" experience you want.
2.  **Return to Nemotron-Cascade-2:** Use it as your daily driver for high-context tasks now.
3.  **Wait for the MoE shift:** Keep this Docker setup ready for a smaller, denser MoE (like a 20B-class model). 

When you have 10GB of surplus VRAM instead of 0.6GB, the RTX 5090 finally starts to feel like the $2,000 beast it is. Does 400K context sound more like the "bag" you were looking for?