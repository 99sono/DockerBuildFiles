---
lab: "Google (Gemma)"
slug: "google-gemma"
openness: "open-weight"
local_support: "yes"
updated: "2026-07-19"
notable_models:
  - name: "Gemma 4 31B Dense"
    size: "30.7B (dense, all active)"
    license: "Apache 2.0"
  - name: "Gemma 4 26B A4B MoE"
    size: "25.2B total / 3.8B active"
    license: "Apache 2.0"
  - name: "Gemma 4 12B Unified"
    size: "11.95B"
    license: "Apache 2.0"
  - name: "Gemma 3 27B"
    size: "27B"
    license: "Gemma Terms of Use"
  - name: "Gemma 2 27B"
    size: "27B"
    license: "Gemma Terms of Use"
  - name: "Gemma 1 7B"
    size: "7B"
    license: "Gemma Terms of Use"
---

# Google (Gemma)

## Overview

Gemma is a family of lightweight, open-weight models built by Google DeepMind from the same research and technology behind the Gemini frontier models. First released in February 2024, Gemma spans text-only, code, vision-language, recurrent (Griffin), and multimodal variants, and has been downloaded hundreds of millions of times. In the open-model landscape Gemma is Google's counterpart to Meta's Llama and Mistral's open models, positioned toward practical, on-device, and single-GPU deployment. A notable 2026 policy shift: Gemma 4 moved from the restrictive Gemma Terms of Use to a fully permissive **Apache 2.0** license.

The top-of-the-line member of the Gemma 4 family is the **Gemma 4 31B Dense** (30.7B params) — Google's flagship open-weight model, maximizing raw quality and serving as a strong foundation for fine-tuning. It is the leading model in the *dense* open category on the Arena AI text leaderboard (Elo ~1451). The **26B A4B MoE** is the efficiency-focused alternative in the same tier: it activates only 3.8B of its 25.2B params per token for high tokens/sec, whereas the 31B Dense activates all 30.7B params on every token (no MoE routing savings).

## Release Cadence

- **2024-02-21** — Gemma 1 (2B, 7B), plus CodeGemma.
- **2024-04-05** — Gemma 1.1 update.
- **2024-06-27** — Gemma 2 (2B, 9B, 27B), plus RecurrentGemma and PaliGemma.
- **2025-03-12** — Gemma 3 (1B, 4B, 12B, 27B); Gemma 3n (E2B, E4B); Gemma 3 270M (2025-08-14).
- **2026-03-31** — Gemma 4 initial release (E2B, E4B, 26B A4B MoE, 31B Dense).
- **2026-04-16** — Gemma 4 MTP drafters (E2B, E4B, 26B A4B, 31B).
- **2026-06-03** — Gemma 4 12B Unified (encoder-free multimodal).

Cadence accelerated from roughly annual (Gemma 1→2) to several substantial releases per year by 2025–2026, with a clear push toward agentic, multimodal, and edge-deployable models.

## Models & Sizes

| Model | Release | Total Params | Active (if MoE) | Context | License | Open? |
|--------|---------|--------------|-----------------|---------|---------|-------|
| Gemma 1 (2B / 7B) | 2024-02-21 | 2B / 7B | — | 8K | Gemma Terms of Use | Open-weight |
| Gemma 1.1 (2B / 7B) | 2024-04-05 | 2B / 7B | — | 8K | Gemma Terms of Use | Open-weight |
| CodeGemma (2B / 7B) | 2024-04 | 2B / 7B | — | 8K | Gemma Terms of Use | Open-weight |
| RecurrentGemma (2B / 9B) | 2024 | 2B / 9B | — | 8K | Gemma Terms of Use | Open-weight (Griffin recurrent) |
| Gemma 2 (2B / 9B / 27B) | 2024-06-27 | 2B / 9B / 27B | — | 8K | Gemma Terms of Use | Open-weight |
| Gemma 3 (1B / 4B / 12B / 27B) | 2025-03-12 | 1B / 4B / 12B / 27B | — | 128K (32K for 1B) | Gemma Terms of Use | Open-weight (multimodal) |
| Gemma 3n (E2B / E4B) | 2025 | ~2B / ~4B eff. | — | 128K | Gemma Terms of Use | Open-weight (multimodal) |
| Gemma 4 E2B | 2026-03-31 | 2.3B eff. (5.1B w/ emb.) | — | 128K | Apache 2.0 | Open-weight (text/img/audio) |
| Gemma 4 E4B | 2026-03-31 | 4.5B eff. (8B w/ emb.) | — | 128K | Apache 2.0 | Open-weight (text/img/audio) |
| Gemma 4 12B Unified | 2026-06-03 | 11.95B | — | 256K | Apache 2.0 | Open-weight (encoder-free multimodal) |
| Gemma 4 26B A4B MoE | 2026-03-31 | 25.2B | 3.8B | 256K | Apache 2.0 | Open-weight (MoE) |
| Gemma 4 31B Dense (flagship) | 2026-03-31 | 30.7B | all 30.7B active (dense) | 256K | Apache 2.0 | Open-weight (multimodal: text+image) |

## Openness Status

Gemma has always been **open-weight** (weights + a permissive-ish usage license, both pretrained and instruction-tuned variants published), but historically under the **Gemma Terms of Use** — a custom Google license that is NOT OSI-approved and restricts use (e.g., certain fields, large-scale services, and responsible-use clauses), making it less permissive than Apache 2.0. Gemma 3 and earlier therefore sit in the "open-weight but restricted" category.

A major policy change arrived with **Gemma 4 (2026-03-31)**: the entire family is released under the **Apache 2.0** license — fully permissive, allowing commercial use, modification, and redistribution without field-of-use restrictions. This brings Gemma in line with (and arguably ahead of) Llama/Mistral on licensing friction.

At the top of the Gemma 4 lineup, the **31B Dense** is the flagship top-of-the-line **dense** open-weight model — chosen for maximum quality and fine-tuning headroom — while the **26B A4B MoE** is the efficient (3.8B-active) alternative for latency-sensitive serving. Both ship in pre-trained and instruction-tuned variants under Apache 2.0.

What remains not "fully open": training data, full training code, and the Gemini frontier models themselves are not released. So Gemma is open-weight (now Apache 2.0) but not fully open (no data/code release).

## Serving (vLLM / llama.cpp / Atlas)

- **vLLM**: Gemma 4 26B A4B (NVFP4) is runnable; Gemma 4 also ships Compressed-Tensors (`-w4a16-ct`) checkpoints for cloud serving. The 31B Dense has a published vLLM recipe (see below).
- **llama.cpp / GGUF**: Gemma 4 E2B, E4B, 12B, 26B A4B, and 31B have official GGUF checkpoints for drop-in local use. Q4_0 quantization ~14.4 GB for 26B A4B, ~6.7 GB for 12B. Community Unsloth GGUFs for the 31B are available (`unsloth/gemma-4-31B-it-GGUF`, verified live).
- **MTP drafters** (2026-04-16) reduce latency for speculative decoding across E2B, E4B, 26B A4B, and 31B.
- MoE note: 26B A4B loads all 25.2B params (only 3.8B active/token), so memory footprint resembles a dense 26B despite 4B-class active cost.
- **31B Dense local-feasibility (honest note)**: being **dense**, the 31B activates **all 30.7B params on every token** — there are no MoE expert-routing savings. Google's own guidance targets unquantized bf16 at ~80GB (H100 / RTX 6000 Pro); QAT / GGUF quantized checkpoints are provided for consumer GPUs. On a single **RTX 5090 (24–32GB)** the 31B is heavy and realistically needs **MTP / speculative decoding active** (and/or aggressive GGUF quantization, e.g. Q4) to be tolerable. By contrast the 26B A4B MoE only pays for 3.8B active params per token, making it the far friendlier consumer-GPU default. For a compact **dense** local model, Qwen3.6-27B remains the go-to; the Gemma 4 31B is the top-of-line dense open option but demands more headroom.
- **NOT yet deployed in this repo**: the 31B Dense is not currently served here (only Gemma 4 26B & 12B are). No known blocker for Gemma 4 — all sizes serve on consumer GPUs; Gemma 1/2/3 remain served via standard transformers/vLLM stacks.

## References

- Official site: https://deepmind.google/models/gemma/gemma-4/
- Gemma 4 launch blog: https://blog.google/innovation-and-ai/technology/developers-tools/gemma-4/
- Gemma 4 12B blog: https://blog.google/innovation-and-ai/technology/developers-tools/introducing-gemma-4-12b/
- Gemma docs / releases: https://ai.google.dev/gemma/docs/releases
- Gemma 4 model overview: https://ai.google.dev/gemma/docs/core
- Gemma 4 model card: https://ai.google.dev/gemma/docs/core/model_card_4
- Gemma 3 launch: https://blog.google/innovation-and-ai/technology/developers-tools/gemma-3/
- Gemma 3 Technical Report: https://arxiv.org/html/2503.19786v1
- Gemma 1 launch: https://blog.google/innovation-and-ai/technology/developers-tools/gemma-open-models/
- Gemma 2 launch: https://blog.google/innovation-and-ai/technology/developers-tools/google-gemma-2/
- PyTorch impl: https://github.com/google/gemma_pytorch/
- Model hub: https://huggingface.co/google and https://www.kaggle.com/models/google/gemma

### Local-serving recipes
- vLLM recipe — Gemma 4 26B-A4B: https://recipes.vllm.ai/Google/gemma-4-26B-A4B-it
- vLLM recipe — Gemma 4 31B (Dense): https://recipes.vllm.ai/Google/gemma-4-31B-it (verified HTTP 200)
- Unsloth GGUF — Gemma 4 31B: https://huggingface.co/unsloth/gemma-4-31B-it-GGUF (verified HTTP 200)
- Unsloth "Run Gemma 4 locally" guide: https://unsloth.ai/docs/models/gemma-4

## Local Deployment in This Repo

This repo serves Gemma 4 locally on consumer and edge hardware:

- **Gemma 4 26B A4B (NVFP4, vLLM)** on RTX 5090: [inference-containers/vllm/gemma-4-26b-5090](../vllm/gemma-4-26b-5090) and DGX Spark: [inference-containers/vllm/gemma-4-26b-dgx-spark](../vllm/gemma-4-26b-dgx-spark)
- **Gemma 4 12B (llama.cpp GGUF)** on RTX 5090: [inference-containers/llamacpp/gemma-4-12b-5090](../llamacpp/gemma-4-12b-5090) and DGX Spark: [inference-containers/llamacpp/gemma-4-12b-dgx-spark](../llamacpp/gemma-4-12b-dgx-spark)
- **Gemma 4 26B A4B (llama.cpp GGUF)** on DGX Spark: [inference-containers/llamacpp/gemma-4-26b-a4b-dgx-spark](../llamacpp/gemma-4-26b-a4b-dgx-spark)
