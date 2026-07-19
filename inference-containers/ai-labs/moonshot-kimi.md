---
lab: "Moonshot AI (Kimi)"
slug: "moonshot-kimi"
openness: "open-weight"
local_support: "yes"
updated: "2026-07-19"
notable_models:
  - name: "Kimi K1.5"
    size: "undisclosed (RL multimodal reasoning)"
    license: "closed (paper + distilled derivatives only)"
  - name: "Kimi-VL"
    size: "16B total / 3B active (MoE VLM)"
    license: "MIT"
  - name: "Kimi K2"
    size: "1.04T total / 32.6B active (MoE)"
    license: "Modified MIT"
  - name: "Kimi K2.5"
    size: "1T total / 32B active (MoE, multimodal)"
    license: "Modified MIT"
  - name: "Kimi K3"
    size: "2.8T total / ~50B active (MoE, 16 of 896 experts)"
    license: "Modified MIT (weights due 2026-07-27)"
---

# Moonshot AI (Kimi)

## Overview

Moonshot AI is a Beijing-based AI lab founded in March 2023 by Yang Zhilin (CEO, ex-Google Brain/Meta AI), Zhou Xinyu, and Wu Yuxin — all Tsinghua University alumni. The company name references Pink Floyd's *The Dark Side of the Moon*, Yang's favorite record. It is one of China's leading "AI Tiger" startups (backed by Alibaba, Tencent, and HongShan / ex-Sequoia China) and is best known for **Kimi**, its long-context chatbot and model family. Kimi was the first assistant to ship a 128K-token (later 2M-character) context window, and Moonshot has since become the most aggressive open-weight frontier lab in China.

Moonshot's open-weight posture is unusually strong: from **Kimi K2 (July 2025)** onward it has published downloadable weights for its flagship MoE series — including the 1T-parameter K2, the multimodal K2.5, and the 2.8T-parameter K3 (weights due 2026-07-27) — under a permissive **Modified MIT License**. This makes Kimi the open-weight rival most directly trading blows with Claude Opus and GPT-5.x at the frontier, particularly on agentic coding. A notable 2026 episode: Cursor's **Composer 2 / 2.5** coding models were built by fine-tuning **Kimi K2.5**, demonstrating how an open Kimi checkpoint bootstrapped another commercial lab's training.

## Release Cadence

- **2023-10** — Kimi chatbot launches (closed beta); first public 128K-context model.
- **2024-11** — Kimi Explore Edition (autonomous search) goes global; MAU exceeds 36M.
- **2025-01-20** — **Kimi K1.5** multimodal RL reasoning model (paper + smaller distilled derivatives; full weights not released). Claimed o1-level math/coding/vision.
- **2025-04** — **Kimi-VL** (16B/3B MoE vision-language model, MIT) and June **Kimi-VL-Thinking** — Moonshot's first open multimodal release.
- **2025-06** — **Kimi-Dev** (72B coding model, based on Qwen2.5-72B, MIT).
- **2025-07-11** — **Kimi K2** (1.04T/32.6B MoE, Modified MIT) — the largest open-weight model at release; trained with the novel MuonClip optimizer on 15.5T tokens.
- **2025-09-05** — **Kimi-K2-Instruct-0905**: context window doubled 128K → 256K.
- **2025-10** — **Kimi Linear** (48B/3B MoE, KDA attention) for edge/efficient inference.
- **2025-11-06** — **Kimi K2 Thinking** (reasoning variant, native tool-use + thinking, Modified MIT, INT4 QAT).
- **2026-01-27** — **Kimi K2.5** (1T/32B MoE, native multimodal w/ MoonViT, Agent Swarm, Modified MIT) — current "most famous open model" and the checkpoint Cursor fine-tuned into Composer 2/2.5.
- **2026-04-20** — **Kimi K2.6** (1T/32B MoE, +300-agent Swarm, native video, MoonViT-3D, Modified MIT).
- **2026-06-12** — **Kimi K2.7 Code** (coding-focused 1T/32B MoE, thinking-only, Modified MIT; later GA inside GitHub Copilot).
- **2026-07-16** — **Kimi K3** (2.8T MoE, 16 of 896 experts active, 1M context, native vision, Kimi Delta Attention + Attention Residuals). API live; **open weights scheduled for 2026-07-27** under Modified MIT.

Cadence accelerated sharply: roughly one major open release per quarter in 2025 to multiple per year through 2026, spanning reasoning, vision-language, lightweight MoE, and frontier agentic coding tiers. Moonshot is the most open-weight-forward of the Chinese frontier labs and the only one to have repeatedly set the upper bound of open-model size (K2 → K2.5 → K3).

## Models & Sizes

| Model | Release | Total Params | Active (if MoE) | Context | License | Open? |
|--------|---------|--------------|-----------------|---------|---------|-------|
| Kimi K1.5 | 2025-01-20 | undisclosed | — | 128K | Closed (paper only) | Paper + distilled derivatives |
| Kimi-VL (A3B) | 2025-04 | 16B | 3B (2.8B LLM) | 128K | MIT | Open-weight (VLM) |
| Kimi-VL-Thinking | 2025-06 | 16B | 3B | 128K | MIT | Open-weight (VLM reasoning) |
| Kimi-Dev | 2025-06 | 72B | — | — | MIT | Open-weight (coding) |
| Kimi Linear | 2025-10 | 48B | 3B | 128K | Modified MIT | Open-weight (MoE, edge) |
| Kimi K2 (Base/Instruct) | 2025-07-11 | 1.04T | 32.6B | 128K | Modified MIT | Open-weight (MoE) |
| Kimi-K2-Instruct-0905 | 2025-09-05 | 1.04T | 32.6B | 256K | Modified MIT | Open-weight (MoE) |
| Kimi K2 Thinking | 2025-11-06 | 1.04T | 32.6B | 256K | Modified MIT | Open-weight (reasoning MoE, INT4) |
| Kimi K2.5 | 2026-01-27 | 1T | 32B | 256K | Modified MIT | Open-weight (multimodal MoE) |
| Kimi K2.6 | 2026-04-20 | 1T | 32B | 256K | Modified MIT | Open-weight (multimodal MoE) |
| Kimi K2.7 Code | 2026-06-12 | 1T | 32B | 256K | Modified MIT | Open-weight (coding MoE) |
| Kimi K3 | 2026-07-16 | 2.8T | ~50B (16/896 experts) | 1M | Modified MIT | Weights due 2026-07-27 |

## Openness Status

Moonshot is firmly **open-weight** and, since K2, has released its flagship tiers with downloadable weights. The licensing nuance:

- **Kimi K1.5 (Jan 2025)** was a *closed* research release — only the arXiv paper and some smaller distilled variants appeared on Hugging Face; the full base model was never published. Moonshot's openness began in earnest with **Kimi-VL (April 2025, MIT)** and **Kimi K2 (July 2025, Modified MIT)**.
- **K2 / K2.5 / K2.6 / K2.7 Code / K2 Thinking** all ship under Moonshot's **Modified MIT License** — permissive enough for commercial use, with an attribution/commercial clause: products exceeding 100M monthly active users or $20M monthly revenue must obtain a separate license and provide attribution. (This clause is what triggered the 2026 Cursor/Composer 2 dispute, where Cursor fine-tuned K2.5 without upfront attribution.)
- **Kimi K3 (July 2026)** debuted API-first; Moonshot committed to releasing the full 2.8T weights by **2026-07-27** under the same Modified MIT posture — which would make it the largest open-weight model ever published.
- **Smaller open releases** (Kimi-VL, Kimi-Dev) use the plain **MIT** license.

What remains *not* fully open: training data, full training code, and the K1.5 base checkpoint are not released. Moonshot also keeps some products API-only (e.g. the `moonshot-v1` chat series); the K2.5 and earlier `kimi-k2*` API IDs were sunset through 2026. So Moonshot is best described as **open-weight (flagship MoE series under Modified MIT) but not fully open (no data/code release, K1.5 closed)**.

## Serving (vLLM / llama.cpp / GGUF)

- **vLLM**: The Kimi K2 architecture is natively supported. vLLM v0.10.0rc1+ serves `moonshotai/Kimi-K2-Instruct` with FP8 (the weights ship in native FP8/INT4), BF16, and tensor/data-parallel + expert-parallel strategies. vLLM provides a dedicated `kimi_k2` tool-call parser (`--enable-auto-tool-choice --tool-call-parser kimi_k2`) for agentic tool use. K2.5, K2.6, K2 Thinking, and Kimi Linear all have official vLLM recipe guides. SGLang and KTransformers are also officially recommended, and Moonshot ships a `deploy_guidance.md` in the `MoonshotAI/Kimi-K2` repo. Recommended minimum for K2 FP8 @ 128K is a **16-GPU cluster (H800/H200)**; smaller footprints require aggressive quantization.
- **llama.cpp / GGUF**: The full K2 family is available as Unsloth/Kimi-K2 GGUF quants (e.g. `unsloth/Kimi-K2-Instruct-GGUF`, `unsloth/Kimi-K2-Thinking-GGUF`, `unsloth/Kimi-K2.6-GGUF`). Because Kimi's MoE weights are INT4-native, `UD-Q8_K_XL` is effectively lossless and `UD-Q4_K_XL` near-lossless. Memory footprint resembles the *total* size (K2 ≈ 584–595 GB at Q4/Q8; K2.6 full precision ≈ 610 GB). The 1-bit/2-bit dynamic quants (UD-TQ1_0 ≈ 340 GB, UD-Q2_K_XL ≈ 350–375 GB) run on a single 24 GB GPU via CPU/SSD offload at ~10 tok/s. K2.5 vision support in llama.cpp is not yet available (text only locally); K2.6 GGUF *does* support vision.
- **Quantization formats**: native FP8 and INT4 (QAT for K2 Thinking), GGUF (Q2–Q8, dynamic Unsloth quants), AWQ, and compressed-tensors INT4. KV-cache in FP8 is supported in vLLM.
- **NOT yet runnable in this repo**: no Kimi / Moonshot models are currently deployed in `inference-containers/` (only Qwen, Gemma, DeepSeek, and Nemotron are). All mainstream Kimi open-weight models are fully runnable on consumer/edge or multi-GPU hardware via vLLM or llama.cpp — there is no engine blocker.

## References

- Official site: https://www.moonshot.ai/ and https://www.kimi.com/
- Kimi API platform docs: https://platform.kimi.ai/docs and https://platform.moonshot.ai/docs
- Kimi K3 tech blog: https://www.kimi.com/blog/kimi-k3
- Kimi K2.5 tech blog: https://www.kimi.com/blog/kimi-k2-5
- Kimi K2 technical report (arXiv): https://arxiv.org/abs/2507.20534
- Kimi K2.5 technical report (arXiv): https://arxiv.org/abs/2602.02276
- Kimi K1.5 technical report (arXiv): https://arxiv.org/abs/2501.12599
- Kimi-VL technical report (arXiv): https://arxiv.org/abs/2504.07491
- Model hub (Hugging Face): https://huggingface.co/moonshotai
- Kimi K2-Instruct: https://huggingface.co/moonshotai/Kimi-K2-Instruct
- Kimi K2.5: https://huggingface.co/moonshotai/Kimi-K2.5
- Kimi K2.6: https://huggingface.co/moonshotai/Kimi-K2.6
- Kimi-VL collection: https://huggingface.co/collections/moonshotai/kimi-vl-a3b-67f67b6ac91d3b03d382dd85
- Kimi K2 GitHub / deploy guide: https://github.com/MoonshotAI/Kimi-K2
- Kimi-VL GitHub: https://github.com/MoonshotAI/Kimi-VL
- vLLM Kimi-K2 recipe: https://docs.vllm.ai/projects/recipes/en/latest/moonshotai/Kimi-K2.html
- Unsloth Kimi-K2 GGUF: https://huggingface.co/unsloth/Kimi-K2-Instruct-GGUF
- Unsloth Kimi-K2.6 GGUF: https://huggingface.co/unsloth/Kimi-K2.6-GGUF
- Wikipedia (Moonshot AI / Kimi): https://en.wikipedia.org/wiki/Moonshot_AI

## Local Deployment in This Repo

This repo does **not** yet deploy any Moonshot AI / Kimi model — only Qwen, Gemma, DeepSeek, and Nemotron are currently served under `inference-containers/`. Kimi's open-weight models are fully compatible with the repo's vLLM and llama.cpp pipelines, so adding them is straightforward. Suggested fits:

- **RTX 5090 (24–32 GB)**: **Kimi-VL (16B/3B MoE, MIT)** is the practical local pick — a capable open vision-language model that fits comfortably via GGUF at Q4. For text-only edge use, **Kimi Linear (48B/3B MoE)** also runs on consumer hardware. The K2.x 1T MoE family does **not** fit on a single 5090 at usable speed (even the 1-bit/2-bit GGUF needs ~350 GB RAM+VRAM).
- **DGX Spark (128 GB)**: the natural home for a real Kimi flagship. **Kimi K2 / K2.5 / K2.6 (1T total / 32B active)** serve at a 2-bit dynamic GGUF (~350 GB) within 128 GB unified memory, or via CPU-offload at reduced speed; active-per-token cost tracks the ~32B active params, not the 1T headline. **Kimi K3 (2.8T / ~50B active, 16/896 experts)** is too large for a single DGX Spark even quantized — it needs multi-GPU (16× H200-class) at FP8 and is best reserved for the largest nodes once its weights drop on 2026-07-27.
