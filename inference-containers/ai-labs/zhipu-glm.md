---
lab: "Zhipu AI (GLM)"
slug: "zhipu-glm"
openness: "open-weight"
local_support: "yes"
updated: "2026-07-19"
notable_models:
  - name: "GLM-5.2 (753B MoE)"
    size: "753B total / 40B active"
    license: "MIT"
  - name: "GLM-5 / GLM-5.1 (744B MoE)"
    size: "744B total / 40-44B active"
    license: "MIT"
  - name: "GLM-4.7 (355B MoE)"
    size: "355B total / 32B active"
    license: "MIT"
  - name: "GLM-4.6 (357B MoE)"
    size: "357B total / 32B active"
    license: "MIT"
  - name: "GLM-4.5 (355B MoE)"
    size: "355B total / 32B active"
    license: "MIT"
  - name: "GLM-4-9B / GLM-4-32B (dense)"
    size: "9B / 32B"
    license: "Apache 2.0"
  - name: "ChatGLM-6B (open chat lineage)"
    size: "6.2B"
    license: "Apache 2.0"
---

# Zhipu AI (GLM)

## Overview

Zhipu AI (智谱, internationally rebranded as **Z.ai**) is a Beijing AI lab founded in 2019 by Tang Jie (唐杰) and Li Juanzi (李涓子), professors at Tsinghua University's Knowledge Engineering Group (KEG). It grew directly out of Tsinghua academic research and is widely regarded as one of China's "AI Tigers" (六小虎). Zhipu became the first large-model company to list as a public stock, and has positioned itself as one of the most aggressively open-weight-forward frontier labs in China.

The GLM lineage runs from the GLM-130B base model, through the ChatGLM chat series (ChatGLM-6B, open-sourced March 2023, drew 10M+ Hugging Face downloads in 2023 alone), into the current GLM-4, GLM-4.5/4.6/4.7, and GLM-5/5.1/5.2 generations. Zhipu's hallmark is shipping frontier-class models as **open weights** — the entire GLM-4.5+ flagship line is published under the permissive **MIT** license (the smaller GLM-4 dense models under Apache-2.0), in deliberate contrast to the closed-API posture of OpenAI, Anthropic, and Google. A notable 2026 milestone: **GLM-5.2 (June 2026, 753B MoE, MIT)** is widely reported as the strongest open-weight coding/reasoning model of the year, outperforming Thinking Machines Lab's open-weights **Inkling** on agentic and reasoning benchmarks (e.g., Terminal-Bench 2.1: 81.0 vs 63.8; SWE-bench Pro: 62.1 vs 54.3).

## Release Cadence

Zhipu moved from a slow, research-driven cadence (ChatGLM-6B in 2023, GLM-4 in early 2024) to a rapid multi-release-per-year pace across 2025–2026, with a clear policy of open-weighting its flagships:

- **2021-12** — GLM architecture introduced at Tsinghua KEG (bilingual GLM-130B base model).
- **2023-03-14** — ChatGLM-6B (6.2B), open-sourced under Apache-2.0; runs on a consumer GPU via INT4.
- **2024-01-16** — GLM-4 flagship announced (closed API tiers + open GLM-4-9B series).
- **2024-06-05** — GLM-4-9B series open-sourced (128K, plus GLM-4-9B-Chat-1M and GLM-4V-9B multimodal); Apache-2.0.
- **2025-04-14** — GLM-4-32B-0414 series open-sourced (dense 32B, with GLM-Z1-32B reasoning variant); Apache-2.0.
- **2025-07-02** — GLM-4.1V-9B-Thinking open-source VLM.
- **2025-07-28** — **GLM-4.5** (355B/32B MoE, MIT) and **GLM-4.5-Air** (106B/12B MoE); first open agentic MoE flagship.
- **2025-09-30** — **GLM-4.6** (≈357B/32B MoE, 200K context, MIT); substantial coding/agentic gains.
- **2025-12-08** — **GLM-4.6V** (106B multimodal + 9B Flash, MIT) with native tool use.
- **2025-12-23** — **GLM-4.7** (≈355–400B/32B MoE, 200K context, MIT); final 4.x flagship.
- **2026-02-11** — **GLM-5** (744B/44B active MoE, 200K context, MIT); trained on Huawei Ascend (no NVIDIA), "Agentic Engineering" framing.
- **2026-03** — **GLM-5 Turbo** (200K context, MIT).
- **2026-04-07** — **GLM-5.1** (744B/40B active MoE, 200K, MIT); SOTA 58.4% on SWE-bench Pro.
- **2026-04** — **GLM-5V-Turbo** (multimodal, 200K), **GLM-5 9B** (262K context dense).
- **2026-06-13/16** — **GLM-5.2** (753B/40B active MoE, 1M context, MIT); strongest open-weight coding model of 2026, beats Thinking Machines' Inkling on reasoning/coding.

Cadence accelerated from roughly one major release per year (2023–2024) to a near-quarterly frontier cadence by 2025–2026. Critically, Zhipu has open-weighted essentially every flagship since GLM-4.5 — a sharper open commitment than many Western frontier labs, though it still holds back some commercial API-only tiers (e.g., GLM-4-Plus-class and certain "Flash" endpoints).

## Models & Sizes

| Model | Release | Total Params | Active (if MoE) | Context | License | Open? |
|--------|---------|--------------|-----------------|---------|---------|-------|
| ChatGLM-6B | 2023-03 | 6.2B | — | 8K (32K later) | Apache 2.0 | Open-weight |
| GLM-4-9B / 9B-Chat / Chat-1M | 2024-06 | 9B | — | 128K (1M variant) | Apache 2.0 | Open-weight |
| GLM-4V-9B | 2024-06 | 9B | — | 128K | Apache 2.0 | Open-weight (multimodal) |
| GLM-4-32B-0414 / Z1-32B | 2025-04 | 32B | — | 32K–128K | Apache 2.0 | Open-weight |
| GLM-4.5 | 2025-07-28 | 355B | 32B | 128K | MIT | Open-weight (MoE) |
| GLM-4.5-Air | 2025-07-28 | 106B | 12B | 128K | MIT | Open-weight (MoE) |
| GLM-4.6 | 2025-09-30 | ~357B | 32B | 200K | MIT | Open-weight (MoE) |
| GLM-4.6V | 2025-12-08 | 106B | — | 128K | MIT | Open-weight (multimodal) |
| GLM-4.6V-Flash | 2025-12-08 | 9B | — | 128K | MIT | Open-weight (multimodal, edge) |
| GLM-4.7 | 2025-12-23 | ~355–400B | 32B | 200K | MIT | Open-weight (MoE) |
| GLM-5 | 2026-02-11 | 744B | 44B | 200K | MIT | Open-weight (MoE) |
| GLM-5 Turbo | 2026-03 | 744B | — | 200K | MIT | Open-weight (MoE) |
| GLM-5 9B | 2026-02 | 9B | — | 262K | MIT | Open-weight (dense) |
| GLM-5V-Turbo | 2026-04 | not disclosed | — | 200K | MIT | Open-weight (multimodal) |
| GLM-5.1 | 2026-04-07 | 744B | 40B | 200K | MIT | Open-weight (MoE) |
| GLM-5.2 | 2026-06-13/16 | 753B | 40B | 1M | MIT | Open-weight (MoE) |

## Openness Status

Zhipu is one of the most consistently **open-weight** frontier labs. Unlike many Western labs that reserve flagships for closed APIs, Zhipu has open-weighted its entire GLM-4.5→5.2 flagship line under the fully permissive **MIT** license — free commercial use, modification, and redistribution, with no regional restrictions. The smaller dense GLM-4 models (9B, 32B, ChatGLM-6B) ship under **Apache-2.0**. The open set spans text, code, reasoning, multimodal (GLM-4.6V, GLM-5V-Turbo), edge/Flash (GLM-4.6V-Flash 9B), and a 9B dense variant.

What remains **not fully open**: training data and full training code are not released (the GLM-4.5 technical report describes methods and releases code/models, but not the full corpus), and some commercial tiers — such as GLM-4-Plus-class API endpoints and certain "Flash" hosted variants — are API-only/closed. So Zhipu is best described as **open-weight (flagship MoE under MIT, smaller models Apache-2.0) but not fully open (no data/code release)**. Its open-weight posture is notably stronger than Mistral's historical MRL-restricted flagships and comparable to DeepSeek's open releases.

## Serving (vLLM / llama.cpp / Atlas)

- **vLLM**: The GLM-4.5/4.6/4.7 and GLM-5/5.1/5.2 MoE architectures are supported via the `Glm4MoeForCausalLM` class (merged into vLLM/Transformers) with FP8/AWQ/GPTQ quantization. Pre-quantized FP8 checkpoints (including the MoE flagships) are published by Z.ai on Hugging Face / ModelScope. GLM-5.2's MTP layer is used for speculative decoding. SGLang and KTransformers are also officially listed serving backends.
- **llama.cpp / GGUF**: GLM-4.5 family has community and official-ish GGUF checkpoints (k-quants Q2–Q8, EXL2, MLX for Apple Silicon). The MoE flagships are large: GLM-4.5 (355B total / 32B active) and GLM-5.2 (753B total / 40B active) must load all total params into memory, so they are DGX-Spark-class deployments. The small dense models — **GLM-4-9B** (Q4_K_M ≈ 5.5 GB, fits a 8–16 GB GPU) and **GLM-4-32B** (Q4_K_M ≈ 19 GB) — are ideal llama.cpp targets. GLM-4.6V-Flash (9B) is explicitly positioned for local/edge deployment.
- **Quantization formats**: GGUF (Q2_K–Q8_0, IQ quants), AWQ, GPTQ, FP8 (vLLM), BF16/FP16 full precision. MoE note: GLM-5.2 loads all 753B params (40B active/token) — memory resembles total size despite MoE active savings; FP8 roughly halves it.
- **NOT yet runnable in this repo**: no Zhipu/GLM models are currently deployed in `inference-containers/` (only Qwen, Gemma, DeepSeek, and Nemotron are). All mainstream GLM open-weight models are fully runnable on consumer/edge hardware via vLLM or llama.cpp — there is no engine blocker.

## References

- Official site (international): https://z.ai/
- Zhipu AI (China): https://www.zhipuai.cn / bigmodel.cn
- GLM-5.2 blog & launch: https://z.ai/blog/glm-5.2
- GLM-5.1 blog: https://z.ai/blog/glm-5.1
- GLM-4.6 blog: https://z.ai/blog/glm-4.6
- GLM-4.6V blog: https://z.ai/blog/glm-4.6v
- GLM-4.5 GitHub: https://github.com/zai-org/GLM-4.5
- GLM-5 GitHub (GLM-5.2/5.1/5): https://github.com/zai-org/GLM-5
- GLM-4 GitHub (incl. 9B, 32B, 4.1V): https://github.com/zai-org/GLM-4
- GLM-4.5 technical report (arXiv:2508.06471): https://arxiv.org/abs/2508.06471
- GLM-5 technical report (arXiv:2602.15763): https://arxiv.org/abs/2602.15763
- IndexShare attention (arXiv:2603.12201): https://arxiv.org/abs/2603.12201
- ChatGLM family report GLM-130B→GLM-4 (arXiv:2406.12793): https://arxiv.org/abs/2406.12793
- Model hub (Hugging Face, zai-org): https://huggingface.co/zai-org
- GLM-5.2 on HF: https://huggingface.co/zai-org/GLM-5.2
- GLM-4.5 on HF: https://huggingface.co/zai-org/GLM-4.5
- GLM-4.6 on HF: https://huggingface.co/zai-org/GLM-4.6
- Model hub (ModelScope, ZhipuAI): https://modelscope.cn/organization/ZhipuAI
- GLM-5.2 vs Thinking Machines Inkling (VentureBeat): https://venturebeat.com/ai/thinking-machines-open-sources-first-multimodal-language-model-inkling-focused-on-low-cost-and-resistance-to-censorship

## Local Deployment in This Repo

This repo does **not** yet deploy any Zhipu AI / GLM model — only Qwen, Gemma, DeepSeek, and Nemotron are currently served under `inference-containers/`. Zhipu's open-weight models are fully compatible with the repo's vLLM and llama.cpp pipelines, so adding them is straightforward. Suggested fits:

- **RTX 5090 (24–32 GB)**: **GLM-4-9B-Chat / GLM-4-32B-0414** are the practical local targets — GLM-4-9B at Q4_K_M ≈ 5.5 GB (fits any 8 GB+ GPU) and GLM-4-32B at Q4_K_M ≈ 19 GB (fits a 24 GB 5090) via llama.cpp. For a vLLM GPU-serving demo, GLM-4.6V-Flash (9B multimodal) is a strong edge/multimodal option. The 355B+ MoE flagships do **not** fit a single 5090.
- **DGX Spark (128 GB)**: **GLM-4.5 / GLM-4.6 / GLM-4.7** (355B total / 32B active, MIT) fit in memory at BF16/FP8 and are the natural open-agentic MoE targets. **GLM-5 / GLM-5.1 / GLM-5.2** (744–753B total / 40–44B active) are frontier-class MoEs that load at FP8 within 128 GB and represent the most capable open Zhipu models available for self-hosting on DGX Spark.
