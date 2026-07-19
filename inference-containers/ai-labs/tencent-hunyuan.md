---
lab: "Tencent Hunyuan (Hy3)"
slug: "tencent-hunyuan"
openness: "open-weight"
local_support: "partial"
updated: "2026-07-19"
notable_models:
  - name: "Hy3"
    size: "295B total / 21B active (MoE)"
    license: "Apache 2.0"
  - name: "Hy3-preview"
    size: "295B total / 21B active (MoE)"
    license: "Apache 2.0 (preview: more restrictive)"
  - name: "Hunyuan-A13B"
    size: "13B (dense MoE, earlier gen)"
    license: "Apache 2.0"
  - name: "HunyuanVideo / Hunyuan3D"
    size: "multimodal open models"
    license: "Apache 2.0 / open"
---

# Tencent Hunyuan (Hy3)

## Overview

Tencent Hunyuan (international brand shortened to "Tencent HY", so "Hy3" = the third major generation of
the Hunyuan family) is Tencent's foundation-model lab, the same team behind the models powering WeChat,
QQ, and Tencent Cloud. Hunyuan has shipped open weights since 2023 (the Hunyuan-A13B chat model under
Apache 2.0), and in 2026 it re-entered the frontier open-weight race with **Hy3**, a 295B-parameter sparse
MoE reasoning/agent model. Hy3 is positioned as a *cost-efficient* open model: it targets practical work
(complex reasoning, coding, multi-step agent tasks, 256K context) rather than raw leaderboard dominance,
and it is notable for launching under a permissive **Apache 2.0** license — making it one of the few
frontier-class open MoEs (alongside GLM-5.2, Kimi K3, and DeepSeek-V4) that can be fine-tuned and
commercialized without restriction.

Hy3's differentiator is its sparse-routing efficiency: 295B total capacity with only **21B active per
token** (192 experts, top-8 routing, plus a 3.8B MTP layer), the same architectural family as GLM-5.2 and
Kimi K2. On paper it rivals models 2–5× its active count; independent reporting (AI Beat, VentureBeat,
Simon Willison) places it in the same tier as GLM-5.2 on most tasks except coding.

## Release Cadence

- **2023-09** — Hunyuan base model; **Hunyuan-A13B** chat (13B MoE, Apache 2.0) opens Tencent's weights.
- **2024** — Hunyuan exhibit at WAIC; multimodal expansion (HunyuanVideo, Hunyuan3D open releases).
- **2026-04-23** — **Hy3-preview** released (first model from the Feb-2026 pre-training/RL rebuild); used a
  more restrictive license initially.
- **2026-07-06** — **Hy3** full open release under **Apache 2.0** (following preview feedback from 50+
  products, scaled-up post-training). Topped OpenRouter's weekly usage leaderboard shortly after launch;
  free API tier ran through 2026-07-21.
- **2026-07-14** — Official **1-bit and 4-bit GGUF quantizations** shipped, enabling llama.cpp / MTP runs
  on a single ~96 GB GPU.

Cadence is sparse-but-strategic: Tencent had been quiet on open frontier weights, then used the Hy3
preview → full-release arc in 2026 to re-enter the open race with an Apache-2.0 flagship. The strategic
direction is clearly **agent-oriented, cost-efficient MoE** rather than maximum-parameter bragging rights.

## Models & Sizes

| Model | Release | Total Params | Active (if MoE) | Context | License | Open? |
|--------|---------|--------------|-----------------|---------|---------|-------|
| Hunyuan-A13B | 2023-09 | 13B | MoE (8 experts) | 32K | Apache 2.0 | Open-weight |
| HunyuanVideo | 2024 | — | — | — | Apache 2.0 | Open (multimodal) |
| Hunyuan3D | 2024 | — | — | — | Apache 2.0 | Open (multimodal) |
| Hy3-preview | 2026-04-23 | 295B | 21B | 256K | restricted (preview) | Open-weight (preview) |
| **Hy3** | 2026-07-06 | 295B | 21B (+3.8B MTP) | 256K | **Apache 2.0** | Open-weight (MoE, reasoning+agent) |

## Openness Status

Hy3 is **open-weight under Apache 2.0** — the most permissive tier, allowing commercial use, modification,
and fine-tuning with no field-of-use restrictions (contrast with NVIDIA's Open Model License or older
Hunyuan/more-restrictive preview terms). What is published:

- **Weights** on Hugging Face (`tencent/Hy3`), ModelScope, GitCode, and CNB; BF16 (598 GB) and FP8 (300 GB)
  checkpoints, plus official 1-bit/4-bit GGUF quants (2026-07-14).
- **Code & recipes**: vLLM and SGLang serving configs, MTP/speculative-decoding recipes, and fine-tuning /
  RL post-training scripts in the `Tencent-Hunyuan/Hy3` GitHub repo.
- **What is NOT released**: full pre-training data and the from-scratch training run. So Hy3 is
  **open-weight + open-recipe (Apache 2.0)**, not "fully open" in the OLMo sense (no training corpus). Its
  openness posture is comparable to Mistral/DeepSeek/GLM frontier MoEs.

## Serving (vLLM / llama.cpp / Atlas)

- **vLLM / SGLang**: Official recipes support Hy3 with speculative decoding (MTP, 2 draft tokens). Tencent
  recommends **eight high-memory GPUs** for self-hosting the full BF16/FP8 model — i.e. a datacenter-class
  setup, not a single edge box.
- **llama.cpp / GGUF**: Official 4-bit GGUF (shipped 2026-07-14) runs on a single **~96 GB GPU** with MTP;
  this is the realistic local path and implies a 4-bit weight footprint around ~150 GB (so two DGX Sparks
  at 128 GB each, tensor-parallel, is the *minimum* edge configuration — and even that is tight).
- **Quantization**: BF16, FP8, and 1-bit/4-bit GGUF all published; NVFP4/GGUF paths work via the standard
  MoE backends. No special engine blocker — Hy3 is a standard MoE (80 layers + 1 MTP, 192 experts/top-8).

## References

- Official Hy3 research page: https://hunyuan.tencent.com/research/hy3
- Tencent announcement: https://www.tencent.com/en-us/articles/2202386.html
- GitHub (Tencent-Hunyuan/Hy3): https://github.com/Tencent-Hunyuan/Hy3
- Hugging Face (Hy3): https://huggingface.co/tencent/Hy3
- ModelScope: https://modelscope.cn/models/Tencent-Hunyuan/Hy3
- OpenRouter (Hy3 :free): https://openrouter.ai/tencent/hy3:free
- AI Beat analysis: https://ai-beat.github.io/news/2026/07/hy3-tencent-open-moe/
- Simon Willison on Hy3: https://simonwillison.net/2026/jul/6/hy3/

## Local Deployment in This Repo

This repo **does not** yet deploy any Tencent Hunyuan model — only Qwen, Gemma, DeepSeek, Nemotron, and
Mistral are currently served under `inference-containers/`.

Local-fit verdict against this repo's hardware ceiling (single DGX Spark 128 GB / max 2 Sparks; 5090 ≤~27B):

- **Hy3 (295B/21B) is at or beyond the local limit.** Its 21B *active* count is fine (well within the
  ~12–13B-on-Spark comfort zone we use as a rule of thumb, and far cheaper than it looks), but the **295B
  total weights** are the problem: FP8 = 300 GB, BF16 = 598 GB. Two DGX Sparks give only 256 GB unified
  total, so even the 4-bit GGUF (~150 GB) is a *stretch* for a 2-Spark tensor-parallel setup and the
  official guidance (eight high-memory GPUs) puts full Hy3 firmly in **cluster territory**. It is **not** a
  clean single-Spark or dual-Spark fit — list it as a local candidate only in the "needs 2 Sparks at
  4-bit, borderline" tier, not a comfortable one.
- **The realistic local Tencent candidate is the older Hunyuan-A13B** (13B MoE, Apache 2.0) — that fits a
  5090 or a single DGX Spark trivially and is the model to actually experiment with here.

Suggested next step: add a `vllm/` or `llamacpp/` folder for **Hunyuan-A13B** on 5090/DGX Spark; treat Hy3
as a "deploy-if-you-cluster-two-Sparks-at-4-bit" stretch goal rather than a standard local model.
