---
lab: "AI2 (Allen Institute for AI) — OLMo"
slug: "ai2-olmo"
openness: "fully-open"
local_support: "yes"
updated: "2026-07-19"
notable_models:
  - name: "OLMo 3 (7B / 32B)"
    size: "7B / 32B"
    license: "Apache 2.0 (fully open: weights + data + code + logs)"
  - name: "OLMo 2 (7B / 13B / 32B)"
    size: "7B / 13B / 32B"
    license: "Apache 2.0 (fully open)"
  - name: "OLMoE (1.3B active / 6.9B total)"
    size: "7B total / 1.3B active"
    license: "Apache 2.0 (fully open)"
  - name: "OLMo (1B / 7B)"
    size: "1B / 7B"
    license: "Apache 2.0 (fully open)"
---

# AI2 (Allen Institute for AI) — OLMo

## Overview

The Allen Institute for AI (Ai2) is a nonprofit AI research institute based in Seattle, Washington, founded in 2014 by the late Paul Allen. Its OLMo (Open Language Model) program, launched February 2024, is the clearest embodiment of Ai2's "open-first" philosophy: OLMo is the **only** major lab in this repo's survey that releases **fully open** models — meaning not just weights, but the complete training data (Dolma / Dolma 3), training code (OLMo / OLMo-core), evaluation code, intermediate checkpoints at every training stage, and Weights & Biases training logs. Ai2 deliberately distinguishes "fully open" from the weaker "open-weight" label used by Meta, Mistral, Qwen, and others — those labs ship final checkpoints but withhold pretraining corpora, full code, and training logs. Under CEO Ali Farhadi, Ai2 has positioned OLMo as both a scientific instrument (to study how language models actually work) and, since OLMo 2/3, a competitive real-world alternative usable commercially under Apache 2.0. A landmark 2025 NSF–Nvidia $152M initiative selected Ai2 to build fully open multimodal scientific models, cementing its role as the open counterweight to concentrated frontier labs.

## Release Cadence

- **2024-02-01** — OLMo 1.0 (1B, 7B), the first truly open LM; full data (Dolma 3T tokens), code, logs, 500+ intermediate checkpoints, Apache 2.0.
- **2024-09-04** — OLMoE (1.3B active / 6.9B total MoE, joint with Contextual AI), fully open; 244 pretraining checkpoints, Apache 2.0.
- **2024-11-26** — OLMo 2 (7B, 13B), staged training to 5T tokens, fully open, Apache 2.0; 7B outperforms Llama 3.1 8B.
- **2025-03-13** — OLMo 2 32B (trained to 6T tokens via OLMo-core), first fully-open model to beat GPT-3.5-Turbo / GPT-4o-mini; Apache 2.0.
- **2025-11-20** — **OLMo 3** (7B, 32B) with the "model flow" release: Base, Instruct, Think (reasoning), and RL-Zero variants; 65K context; full Dolma 3 data transparency. Apache 2.0.
- **2025-12-12** — OLMo 3.1 (Think 32B, Instruct 32B) extends the RL runs; OLMo 3.1 Think 32B called the strongest fully-open thinking model to date.

Cadence moved from a single debut model (2024-02) to multiple substantial fully-open releases per year through 2025, and — uniquely — each release expanded the *scope* of openness (more checkpoints, more data, full post-training recipes via Tülu 3 / Dolci) rather than narrowing it. Ai2 is the only lab here that has never retreated from full openness.

## Models & Sizes

| Model | Release | Total Params | Active (if MoE) | Context | License | Open? |
|--------|---------|--------------|-----------------|---------|---------|-------|
| OLMo 1B | 2024-02-01 | 1B | — | 2K | Apache 2.0 | Fully open (data+code+logs) |
| OLMo 7B | 2024-02-01 | 7B | — | 2K | Apache 2.0 | Fully open (data+code+logs) |
| OLMoE-1B-7B | 2024-09-04 | 6.9B | 1.3B | 4K | Apache 2.0 | Fully open (MoE, data+code+logs) |
| OLMo 2 7B | 2024-11-26 | 7B | — | 4K | Apache 2.0 | Fully open |
| OLMo 2 13B | 2024-11-26 | 13B | — | 4K | Apache 2.0 | Fully open |
| OLMo 2 32B | 2025-03-13 | 32B | — | 4K | Apache 2.0 | Fully open |
| OLMo 3 7B | 2025-11-20 | 7B | — | 65K | Apache 2.0 | Fully open (model flow) |
| OLMo 3 32B | 2025-11-20 | 32B | — | 65K | Apache 2.0 | Fully open (model flow) |
| OLMo 3.1 Think/Instruct 32B | 2025-12-12 | 32B | — | 65K | Apache 2.0 | Fully open (model flow) |

## Openness Status

Ai2/OLMo is the **only fully-open** entry in this repo's lab survey. The defining distinction:

- **Open-weight** labs (Mistral, Qwen, Gemma, DeepSeek, Nemotron) publish final checkpoints and sometimes recipes, but withhold the pretraining corpus and full training code/logs.
- **Fully-open** (OLMo, since day one) publishes **weights + training data + training code + evaluation code + intermediate checkpoints + training logs**, all under the permissive **Apache 2.0** license (free commercial use, modification, redistribution, no output restrictions).

Every OLMo generation has honored this. OLMo 1 (Feb 2024) shipped 500+ intermediate checkpoints per base model and the full Dolma 3T-token corpus. OLMo 2 added staged pretraining (OLMo-Mix-1124 → Dolmino-Mix-1124) and Tülu 3 post-training, releasing all code, checkpoints, and logs. OLMo 3 operationalized openness as a "model flow" — the entire lifecycle from raw data (Dolma 3, ~9.3T tokens) through mid-training (Dolmino) and long-context (Longmino) to post-training (Instruct / Think / RL-Zero), with checkpoints at every milestone and a dedicated tool (OLMoTrace) to trace outputs back to specific pretraining data points. Notably, OLMo 3 Think 32B's reasoning traces can be traced back to the training data that produced them — impossible with any open-weight-only model. The only things not released are unrelated third-party upstream web sources that Dolma aggregated; the curated, decontaminated training mixes themselves are public.

## Serving (vLLM / llama.cpp / Atlas)

- **vLLM**: Native OLMo 2 support landed in vLLM 0.7.2+ (`OLMoForCausalLM`, `Olmo2ForCausalLM`). OLMo 2 7B/13B/32B serve via vLLM in BF16 (32B needs ~65 GB VRAM, so tensor-parallel `--tensor-parallel-size 2` across two GPUs). AWQ-INT4 variants (e.g. `neuralmagic/OLMo-2-1124-13B-Instruct-AWQ`) run on 12+ GB VRAM. OLMo 3 needs a current vLLM build (OLMo 3 support merged after the 2025-11 release). GGUF can also be served via the vLLM GGUF plugin, though this path is experimental/under-optimized.
- **llama.cpp / GGUF**: OLMo 2 32B has official-compatible GGUF quants (tensorblock, mradermacher, bartowski) — Q4_K_M ≈ 19.5 GB, Q6_K ≈ 26.5 GB, Q8_0 ≈ 34.3 GB. OLMo 2 7B/13B also have community GGUFs (Q4_K_M ≈ 4.5 GB / 8 GB). A known early llama.cpp bug with the 32B **Instruct** variant (wrong `attn_k_norm` tensor shape under GQA) was resolved in llama.cpp commit b4896+; use a recent build. OLMoE GGUF (`OLMoE-1B-7B-0924-GGUF`) runs in llama.cpp. OLMo 3 GGUF quants are emerging (Q4_K_M for the 7B ≈ 4–5 GB; 32B Q4_K_M ≈ 20 GB).
- **Quantization formats**: GGUF (Q2_K–Q8_0), AWQ for vLLM. Native OLMo context is 4K for OLMo 1/2 (RoPE-scaling to 8K possible) and 65K for OLMo 3.
- **NOT yet runnable in this repo**: no OLMo models are currently deployed in `inference-containers/` (only Qwen, Gemma, DeepSeek, Nemotron, and Mistral-adjacent are). All OLMo open models are fully runnable on consumer/edge hardware via vLLM or llama.cpp — there is no engine blocker.

## References

- Official site: https://allenai.org/
- OLMo / language models hub: https://allenai.org/olmo and https://allenai.org/language-models
- OLMo 1 blog & launch: https://allenai.org/blog/olmo-open-language-model-87ccfc95f580
- OLMo 2 blog: https://allenai.org/blog/olmo2 and https://allenai.org/olmo2
- OLMo 2 32B blog: https://allenai.org/blog/olmo2-32b
- OLMoE blog: https://allenai.org/blog/olmoe-an-open-small-and-state-of-the-art-mixture-of-experts-model-c258432d0514
- OLMo 3 blog: https://allenai.org/blog/olmo3
- OLMo 3.1 update: https://allenai.org/blog/olmo3 (Update 12/12)
- OLMo paper (arXiv): https://arxiv.org/abs/2402.00838
- OLMo 2 paper "2 OLMo 2 Furious" (arXiv): https://arxiv.org/abs/2501.00656
- OLMoE paper (arXiv): https://arxiv.org/abs/2409.02060
- OLMo 3 paper (arXiv): https://arxiv.org/abs/2512.13961
- OLMo 3 technical report PDF: https://www.datocms-assets.com/64837/1765558567-olmo_3_technical_report-4.pdf
- Model hub (Hugging Face): https://huggingface.co/allenai
- OLMo 7B: https://huggingface.co/allenai/OLMo-7B
- OLMo 2 32B: https://huggingface.co/allenai/OLMo-2-0325-32B
- OLMo 2 32B GGUF: https://huggingface.co/tensorblock/OLMo-2-0325-32B-GGUF
- OLMoE: https://huggingface.co/allenai/OLMoE-1B-7B-0924
- OLMo 3 7B: https://huggingface.co/allenai/Olmo-3-1025-7B
- Training code (OLMo-core): https://github.com/allenai/OLMo-core
- Original OLMo repo: https://github.com/allenai/OLMo
- Training data (Dolma): https://huggingface.co/datasets/allenai/dolma
- OLMoTrace (trace outputs to data): https://allenai.org/olmotrace

## Local Deployment in This Repo

This repo does **not** yet deploy any Ai2/OLMo model — only Qwen, Gemma, DeepSeek, and Nemotron are currently served under `inference-containers/`. OLMo's fully-open models are fully compatible with the repo's vLLM and llama.cpp pipelines, so adding them is straightforward and on-brand (the repo already values open models). Suggested fits:

- **RTX 5090 (24–32 GB)**: **OLMo 2 32B** (Q4_K_M GGUF ≈ 19.5 GB via llama.cpp, or BF16 13B fits comfortably) or **OLMoE-1B-7B** (7B total / 1.3B active, Q4_K_M ≈ 4.5 GB — an efficient MoE option that fits even smaller cards). For vLLM GPU serving, **OLMo 3 7B** (Q4_K_M ≈ 4–5 GB, 65K context) is an ideal demonstration of a fully-open model at consumer scale.
- **DGX Spark (128 GB)**: **OLMo 2 32B** at BF16/FP16 (~65 GB) or **OLMo 3 32B** (Base/Think/Instruct, 65K context) at BF16 — the natural home for the strongest fully-open reasoning model (OLMo 3 Think 32B), where the full open model flow (data + checkpoints) can be studied end-to-end.
