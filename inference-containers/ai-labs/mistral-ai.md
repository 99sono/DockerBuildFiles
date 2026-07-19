---
lab: "Mistral AI"
slug: "mistral-ai"
openness: "open-weight"
local_support: "yes"
updated: "2026-07-19"
notable_models:
  - name: "Mistral Large 3 (675B MoE)"
    size: "675B total / 41B active"
    license: "Apache 2.0"
  - name: "Mixtral 8x22B"
    size: "141B total / 39B active"
    license: "Apache 2.0"
  - name: "Mistral NeMo 12B"
    size: "12B"
    license: "Apache 2.0"
  - name: "Magistral Small 24B"
    size: "24B"
    license: "Apache 2.0"
  - name: "Codestral Mamba 7B"
    size: "7B"
    license: "Apache 2.0"
---

# Mistral AI

## Overview

Mistral AI is a French AI lab founded in April 2023 in Paris by Arthur Mensch (CEO, ex-Google DeepMind), Guillaume Lample (Chief Science Officer, ex-Meta LLaMA), and Timothée Lacroix (CTO, ex-Meta LLaMA). It is Europe's leading independent frontier lab and a self-described open-weight champion: from its debut Mistral 7B (Sep 2023) it has published downloadable weights for the vast majority of its models, in deliberate contrast to the closed-API posture of OpenAI, Anthropic, and Google. Mistral pairs an open model portfolio (Mistral / Mixtral / Codestral / Magistral / Ministral families) with a commercial API ("La Plateforme") and a consumer assistant (Le Chat / Vibe). A notable 2025–2026 policy shift: Mistral moved its flagship **Mistral Large** series from the restrictive **Mistral Research License (MRL)** to the fully permissive **Apache 2.0** license — Mistral Large 3 (Dec 2025) ships open weights under Apache 2.0, the first time a Mistral flagship MoE was released with no commercial restriction.

## Release Cadence

- **2023-09-27** — Mistral 7B (7.3B), Apache 2.0, the debut open-weight model.
- **2023-12-08** — Mixtral 8x7B (46.7B/12.9B active), Apache 2.0; first open MoE.
- **2024-02-26** — Mistral Large 1.0 (proprietary), Mistral Small 1.0 (proprietary).
- **2024-04-10** — Mixtral 8x22B (141B/39B active), Apache 2.0.
- **2024-05-29** — Codestral 22B (code model, Mistral Non-Production License — non-commercial).
- **2024-07-16** — Codestral Mamba 7B (Mamba2, Apache 2.0) and Mathstral 7B (Apache 2.0).
- **2024-07-18** — Mistral NeMo 12B, with NVIDIA, Apache 2.0, 128K context.
- **2024-07-24** — Mistral Large 2 (123B, MRL — open weights but no commercial use without license).
- **2024-09-11** — Pixtral 12B (multimodal, Apache 2.0).
- **2024-10-16** — Ministral 3B (proprietary) and Ministral 8B (MRL).
- **2024-11-18** — Mistral Large 2.1 / Pixtral Large (MRL).
- **2025-01** — Mistral Small 3 (24B, Apache 2.0); Codestral 25.01 (proprietary).
- **2025-02-17** — Mistral Saba (24B, Apache 2.0, Arabic/South-Indian languages).
- **2025-03-17** — Mistral Small 3.1 (24B multimodal, Apache 2.0, 128K).
- **2025-05-07** — Mistral Medium 3 (proprietary frontier).
- **2025-05-21** — Devstral Small (24B agentic coding, Apache 2.0).
- **2025-06-10** — Magistral Small (24B reasoning, Apache 2.0) and Magistral Medium (proprietary).
- **2025-06-20** — Mistral Small 3.2 (24B, Apache 2.0).
- **2025-07** — Voxtral (audio; Small/Mini Apache 2.0), Codestral 2508 (proprietary).
- **2025-12-02** — **Mistral Large 3** (675B/41B active MoE, **Apache 2.0**, 256K, multimodal) and Ministral 3 (3B/8B/14B, Apache 2.0).
- **2026-03-16** — Mistral Small 4 (119B MoE, Apache 2.0).
- **2026-04-29** — Mistral Medium 3.5 (128B, modified MIT — flagship merged model).
- **2026 summer** — Next open-weight flagship announced by Arthur Mensch (TechCrunch, Jul 2026); early access July 2026, specs undisclosed.

Cadence accelerated from roughly one major release per quarter in 2023–2024 to multiple substantial releases per year by 2025–2026, spanning text, code, reasoning, multimodal, audio, and edge tiers. Mistral has consistently been the most open-weight-forward of the frontier labs.

## Models & Sizes

| Model | Release | Total Params | Active (if MoE) | Context | License | Open? |
|--------|---------|--------------|-----------------|---------|---------|-------|
| Mistral 7B (v0.1/v0.2/v0.3) | 2023-09-27 | 7.3B | — | 8K (v0.1), 32K (v0.2+) | Apache 2.0 | Open-weight |
| Mixtral 8x7B | 2023-12-08 | 46.7B | 12.9B | 32K | Apache 2.0 | Open-weight (MoE) |
| Mistral Large 1.0 | 2024-02-26 | ~32B | — | 32K | Mistral Commercial (proprietary) | Closed/API |
| Mixtral 8x22B | 2024-04-10 | 141B | 39B | 64K | Apache 2.0 | Open-weight (MoE) |
| Codestral 22B | 2024-05-29 | 22B | — | 32K | Mistral Non-Production License | Open-weight (non-commercial) |
| Mathstral 7B | 2024-07-16 | 7B | — | 32K | Apache 2.0 | Open-weight |
| Codestral Mamba 7B | 2024-07-16 | 7B | — | 256K | Apache 2.0 | Open-weight (Mamba2) |
| Mistral NeMo 12B | 2024-07-18 | 12B | — | 128K | Apache 2.0 | Open-weight |
| Mistral Large 2 (24.07) | 2024-07-24 | 123B | — | 128K | Mistral Research License (MRL) | Open-weight (no commercial) |
| Pixtral 12B | 2024-09-11 | 12B | — | 128K | Apache 2.0 | Open-weight (multimodal) |
| Ministral 8B | 2024-10-16 | 8B | — | 128K | Mistral Research License (MRL) | Open-weight (no commercial) |
| Ministral 3B | 2024-10-16 | 3B | — | 128K | Proprietary | Closed/API |
| Mistral Large 2.1 (24.11) | 2024-11-18 | 123B | — | 128K | Mistral Research License (MRL) | Open-weight (no commercial) |
| Pixtral Large | 2024-11-18 | 124B | — | 128K | Mistral Research License (MRL) | Open-weight (no commercial) |
| Mistral Small 3 | 2025-01-30 | 24B | — | 32K | Apache 2.0 | Open-weight |
| Mistral Saba | 2025-02-17 | 24B | — | 32K | Apache 2.0 | Open-weight |
| Mistral Small 3.1 | 2025-03-17 | 24B | — | 128K | Apache 2.0 | Open-weight (multimodal) |
| Devstral Small | 2025-05-21 | 24B | — | 128K | Apache 2.0 | Open-weight (agentic coding) |
| Magistral Small | 2025-06-10 | 24B | — | 128K | Apache 2.0 | Open-weight (reasoning) |
| Magistral Medium | 2025-06-10 | not disclosed | — | 40K | Proprietary | Closed/API |
| Mistral Small 3.2 | 2025-06-20 | 24B | — | 128K | Apache 2.0 | Open-weight |
| Mistral Large 3 | 2025-12-02 | 675B | 41B | 256K | Apache 2.0 | Open-weight (MoE, multimodal) |
| Ministral 3 (3B/8B/14B) | 2025-12-02 | 3B/8B/14B | — | 128K | Apache 2.0 | Open-weight (edge) |
| Mistral Small 4 | 2026-03-16 | 119B | ~4B (128 experts) | 128K | Apache 2.0 | Open-weight (MoE, multimodal) |
| Mistral Medium 3.5 | 2026-04-29 | 128B | — | 128K | Modified MIT | Open-weight (commercial-friendly) |

## Openness Status

Mistral is the most consistently **open-weight** of the frontier labs. Its small and mid-tier models — Mistral 7B, the entire Mixtral family, NeMo, Pixtral, the Small/Saba/Devstral/Magistral lines, Ministral 3, and Mistral Small 4 — are published under the fully permissive **Apache 2.0** license (free commercial use, modification, redistribution).

The key nuance is the **flagship tier**:
- **Mistral Large 1.0 / 2 / 2.1 and Pixtral Large** were released under the **Mistral Research License (MRL)** — open weights but **non-commercial** without a separate paid license. Ministral 8B also shipped under MRL.
- **A decisive policy change arrived with Mistral Large 3 (2025-12-02)**: the flagship is a 675B/41B-active MoE published under **Apache 2.0**, removing all commercial restrictions. This aligns Mistral's flagship openness with its smaller models for the first time.
- Codestral 22B (the original code model) used the **Mistral Non-Production License** (non-commercial), whereas its successor Codestral Mamba 7B is Apache 2.0. Later Codestral revisions (25.01, 2508) became proprietary API models.
- Mistral Medium 3.5 (2026-04) ships under a **modified MIT license**, also commercial-friendly.

What remains not "fully open": training data and full training code are not released, and the frontier Medium series (Medium 3, Medium 3.5) is either proprietary or only recently license-relaxed. So Mistral is best described as **open-weight (most tiers Apache 2.0) but not fully open (no data/code release)**.

## Serving (vLLM / llama.cpp / Atlas)

- **vLLM**: All standard Mistral dense and MoE architectures are supported (MistralForCausalLM, MixtralForCausalLM). Mixtral 8x7B/8x22B run as expert-routed MoE; Mistral Large 3 (675B/41B) and Mistral Small 4 (119B/~4B active) serve via vLLM with FP8/AWQ/GPTQ quantization. Pre-quantized AWQ/GPTQ checkpoints are common on Hugging Face for the smaller models.
- **llama.cpp / GGUF**: Mistral 7B, Mixtral 8x7B, Mistral NeMo 12B, Mistral Small 3/3.1/3.2, Pixtral 12B, and Magistral Small 24B all have official or community GGUF checkpoints. Magistral Small 24B quantizes well: Q4_K_M ≈ 15.2 GB VRAM (fits a 16/24 GB GPU), Q8_0 ≈ 26 GB, FP16 ≈ 48.5 GB. Mixtral 8x7B Q4_K_M runs on a single 24 GB GPU. Codestral Mamba (Mamba2) was not initially supported in llama.cpp (Mistral noted "keep an eye out for support") and relies on `mistral-inference` / TensorRT-LLM instead.
- **Quantization formats**: GGUF (Q3_K–Q8_0), AWQ, GPTQ, FP8 for vLLM; BF16/FP16 for full-precision serving. MoE note: Mixtral 8x22B loads all 141B params (39B active/token), and Mistral Large 3 loads all 675B (41B active/token) — memory footprint resembles the total size despite MoE active savings.
- **NOT yet runnable in this repo**: no Mistral models are currently deployed in `inference-containers/` (only Qwen, Gemma, DeepSeek, and Nemotron are). All mainstream Mistral open-weight models are fully runnable on consumer/edge hardware via vLLM or llama.cpp — there is no engine blocker.

## References

- Official site: https://mistral.ai/
- Mistral news / Research: https://mistral.ai/news and https://mistral.ai/news?category=Research
- Mistral Large 3 launch blog: https://mistral.ai/news/mistral-3
- Mistral Large 3 model card (docs): https://docs.mistral.ai/models/model-cards/mistral-large-3-25-12
- Magistral announcement: https://mistral.ai/news/magistral
- Codestral Mamba announcement: https://mistral.ai/news/codestral-mamba/
- Mixtral 8x22B / 8x7B: https://mistral.ai/news/mixtral-8x22b/ and https://mistral.ai/news/mixtral/
- Mistral NeMo: https://mistral.ai/news/mistral-nemo/
- Mistral Large 2: https://mistral.ai/news/mistral-large-2407
- Mistral Research License (MRL): https://mistral.ai/licenses/MRL-0.1.md
- Mistral model catalog / docs: https://docs.mistral.ai/getting-started/models
- Model hub (Hugging Face): https://huggingface.co/mistralai
- Mistral Large 3 on HF: https://huggingface.co/mistralai/Mistral-Large-3-675B-Instruct-2512
- Magistral Small on HF: https://huggingface.co/mistralai/Magistral-Small-2506
- Codestral Mamba on HF: https://huggingface.co/mistralai/Mamba-Codestral-7B-v0.1
- Mixtral 8x22B on HF: https://huggingface.co/mistralai/Mixtral-8x22B-v0.1
- Magistral technical paper (arXiv): https://arxiv.org/abs/2506.10910
- Mamba architecture (arXiv): https://arxiv.org/abs/2312.00752

## Local Deployment in This Repo

This repo does **not** yet deploy any Mistral AI model — only Qwen, Gemma, DeepSeek, and Nemotron are currently served under `inference-containers/`. Mistral's open-weight models are fully compatible with the repo's vLLM and llama.cpp pipelines, so adding them is straightforward. Suggested fits:

- **RTX 5090 (24–32 GB)**: Mistral **Magistral Small 24B** (Apache 2.0 reasoning model, Q4_K_M GGUF ≈ 15.2 GB) or **Mistral Small 3.1/3.2 24B** (multimodal, Q4_K_M ≈ 15 GB) via llama.cpp; **Mixtral 8x7B** (Q4_K_M) also fits comfortably for an MoE option. For a vLLM GPU-serving demo, Mistral Small 4 (119B/~4B active) is feasible at FP8 since only ~4B params are active per token.
- **DGX Spark (128 GB)**: **Mistral Large 3** (675B total / 41B active, Apache 2.0) is the flagship open-weight MoE and fits in memory at BF16/FP8; **Mixtral 8x22B** and the full **Magistral Small 24B** at FP16 also run well. DGX Spark is the natural home for the only truly frontier-class open Mistral model (Large 3).
