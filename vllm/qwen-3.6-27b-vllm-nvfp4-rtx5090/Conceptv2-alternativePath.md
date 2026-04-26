# 🎯 Direct Answer: Which Model Is "Smarter" / Closer to Original Precision?

## 🏆 Short Answer

**`rdtand/Qwen3.6-27B-PrismaQuant-5.5bit-vllm` is theoretically closer to the original BF16 precision** — but with a major caveat that likely makes it the *wrong choice for your DFlash goal*.

---

## 📊 Precision Comparison (BF16 Baseline = 100%)

| Metric | Official BF16 | NVFP4 (sakamakismile) | PrismaQuant 5.5-bit |
|--------|--------------|----------------------|-------------------|
| **Disk Size** | ~54 GB | ~19.7 GB (−64%) | ~19 GB (−65%) |
| **Avg Bits/Param** | 16.0 | 4.0 (uniform) | **5.5 (mixed)** |
| **Quantization Strategy** | None | Uniform NVFP4 + BF16 passthrough | **Fisher sensitivity + activation-aware export** |
| **High-Sensitivity Layer Protection** | N/A | Manual (lm_head, vision, gates) | **Automatic per-Linear allocation** |
| **Measured Output MSE vs RTN** | 1.00× | ~0.45× (estimated) | **0.33×** [[PrismaQuant README]] |
| **Predicted Δloss (lower=better)** | 0 | ~500–550 (estimated) | **477** [[PrismaQuant README]] |
| **Speculative Decoding** | External (DFlash or MTP) | External (DFlash or MTP) | **Integrated MTP head only** |

---

## 🔬 Why PrismaQuant Is Theoretically Closer to BF16

### 1. **Per-Linear Sensitivity Allocation**
PrismaQuant measures Fisher information for *each Linear layer* and assigns precision accordingly:

```
High-sensitivity layers (30 Linears) → MXFP8 (8-bit) or BF16
Medium-sensitivity (300 Linears) → NVFP4 (4-bit)  
Low-sensitivity / passthrough (112+ Linears) → BF16 preserved
```

This is smarter than uniform NVFP4, which quantizes *all* Linear layers to 4-bit regardless of sensitivity.

### 2. **Activation-Aware Export Passes**
PrismaQuant applies two closed-form optimization passes during export [[PrismaQuant README]]:

| Pass | Effect |
|------|--------|
| **GPTQ-OBS rounding** | Propagates quantization error block-wise using cached activations → 0.41× MSE vs RTN |
| **Per-group scale sweep** | Enumerates 32 candidate scales per 16-weight group, picks MSE-minimizing combo → **0.33× MSE vs RTN** |

Uniform NVFP4 typically uses simpler RTN (round-to-nearest) without activation-aware refinement.

### 3. **Pareto-Knee Selection at 5.5 bpp**
The 5.5 bits-per-parameter target was selected via the **Kneedle algorithm** as the optimal trade-off point on the Δloss-vs-bpp curve [[PrismaQuant README]]:

```
4.75 bpp → +48% Δloss, −14% size  (steep loss curve)
5.25 bpp → +12% Δloss, −5% size
5.50 bpp → ← KNEE: max marginal gain per bit
6.00 bpp → −18% Δloss, +9% size   (diminishing returns)
```

This is a principled, data-driven choice — not an arbitrary "4-bit because it fits."

---

## ⚠️ The Critical Caveat: Speculative Decoding Incompatibility

| Feature | PrismaQuant 5.5-bit | Official/NVFP4 + DFlash |
|---------|-------------------|------------------------|
| **Speculation Method** | Integrated **MTP head** (multi-token prediction) | External **DFlash drafter** (block diffusion) |
| **Speedup Potential** | ~1.8–2.3× | **~3–5×** (with α ≥ 0.65) |
| **Drafter VRAM** | 0 GB (integrated) | ~4.1 GB (separate 2B model) |
| **Compatibility with Your Guide** | ❌ Requires MTP config | ✅ Matches DFlash workflow |

> 🚫 **You cannot use DFlash with the PrismaQuant model**. The speculative decoding methods are mutually exclusive.

If your goal is **maximum throughput via DFlash**, the PrismaQuant model is not an option — regardless of its slightly better precision.

---

## 🧠 "Smarter" Depends on Your Definition

| Definition of "Smarter" | Winner |
|-------------------------|--------|
| **Closest to BF16 perplexity / quality** | PrismaQuant 5.5-bit (theoretically) |
| **Best speed/quality trade-off for long-context generation** | Official/NVFP4 + DFlash |
| **Most flexible / compatible with inference engines** | NVFP4 (simpler quantization, wider support) |
| **Best for multimodal tasks** | PrismaQuant (vision encoder preserved with sensitivity-aware quantization) |
| **Best for your stated RTX 5090 + DFlash goal** | **Official/NVFP4 + DFlash** |

---

## 🎯 Recommendation for Your Use Case

Since you explicitly want **DFlash speculative decoding on an RTX 5090**, here is the optimal path:

### Option A: Maximum Compatibility + Good Precision
```yaml
--model sakamakismile/Qwen3.6-27B-NVFP4  # or official Qwen/Qwen3.6-27B
--speculative-config '{"method":"dflash","model":"z-lab/Qwen3.6-27B-DFlash","num_speculative_tokens":10}'
--kv-cache-dtype fp8_e4m3
--gpu-memory-utilization 0.88
```
- ✅ Works with your existing Docker workflow
- ✅ DFlash speedup: 3–5×
- ✅ Precision: Very good (hybrid NVFP4/BF16 protects critical layers)
- ✅ VRAM: Fits 128k context @ batch 24 on 32 GB

### Option B: If You Want to Try PrismaQuant Anyway
```yaml
--model rdtand/Qwen3.6-27B-PrismaQuant-5.5bit-vllm
--speculative-config '{"method":"mtp","num_speculative_tokens":3}'  # MTP only, not DFlash
--max-model-len 65536  # Reduced for vision overhead
--gpu-memory-utilization 0.85
```
- ✅ Slightly better theoretical precision
- ✅ Integrated MTP (no separate drafter download)
- ❌ DFlash incompatible
- ❌ Speedup limited to ~1.8–2.3×
- ❌ Vision encoder adds ~1–2 GB VRAM overhead

---

## 🔍 How to Verify Precision Yourself (If You're Curious)

If you want to empirically compare quality (not just trust predicted Δloss):

```bash
# 1. Run a small benchmark suite on both models
python -c "
import requests, json, statistics

def benchmark(model_name, base_url='http://localhost:8000/v1'):
    prompts = [
        'Solve: If x^2 + 5x + 6 = 0, find x.',
        'Explain quantum entanglement in 3 sentences.',
        'Write a Python function to reverse a linked list.',
    ]
    results = []
    for p in prompts:
        r = requests.post(f'{base_url}/completions', json={
            'model': model_name,
            'prompt': p,
            'max_tokens': 200,
            'temperature': 0.0  # deterministic for comparison
        })
        if r.ok:
            results.append(r.json()['choices'][0]['text'])
    return results

# Compare outputs side-by-side
nvfp4_out = benchmark('qwen3.6-27b-nvfp4')
prisma_out = benchmark('qwen3.6-27b-prismaquant')
for i, (n, p) in enumerate(zip(nvfp4_out, prisma_out)):
    print(f'Prompt {i+1}:\nNVFP4: {n[:200]}...\nPrisma: {p[:200]}...\n---')
"
```

Look for:
- Logical consistency in reasoning tasks
- Code correctness in programming tasks
- Factual accuracy in knowledge tasks

In practice, most users report **negligible quality differences** between well-quantized 4–6 bpp models on real-world tasks — the theoretical Δloss advantage of PrismaQuant rarely translates to noticeable improvements outside of benchmark suites.

---

## 🏁 Final Verdict

| Goal | Recommended Model |
|------|-----------------|
| **DFlash speculative decoding + high throughput** | `sakamakismile/Qwen3.6-27B-NVFP4` + `z-lab/Qwen3.6-27B-DFlash` |
| **Maximum theoretical precision + MTP speculation** | `rdtand/Qwen3.6-27B-PrismaQuant-5.5bit-vllm` |
| **Baseline for comparison / research** | Official `Qwen/Qwen3.6-27B` (BF16, if you have multi-GPU) |

> For your RTX 5090 + DFlash workflow: **stick with NVFP4 + DFlash**. The precision difference is unlikely to matter in practice, and you gain 2× the speedup potential.

If you later want to experiment with PrismaQuant + MTP as a separate project, the guide can be adapted — just let me know. 🚀
