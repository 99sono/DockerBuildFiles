---
lab: "Thinking Machines Lab"
slug: "thinking-machines"
openness: "open-weight"
local_support: "partial"
updated: "2026-07-19"
notable_models:
  - name: "Inkling"
    size: "975B total / 41B active"
    license: "Apache 2.0"
  - name: "Inkling-Small (pending)"
    size: "276B total / 12B active"
    license: "Apache 2.0"
---

# Thinking Machines Lab

## Overview

Thinking Machines Lab is a U.S. AI research and product company founded in February 2025 by Mira Murati (CEO, former Chief Technology Officer of OpenAI) alongside a team drawn heavily from OpenAI, Anthropic, Meta, and Mistral. The lab is best known for its **Tinker** fine-tuning/training platform and, as of July 2026, for **Inkling** — its first production model and its first open-weights release. Inkling is a 975B-parameter sparse Mixture-of-Experts (MoE) multimodal transformer (text/image/audio input, text output) trained on 45 trillion tokens, released under the fully permissive **Apache 2.0** license with full weights on Hugging Face. Crucially, Thinking Machines explicitly positions Inkling *not* as a frontier benchmark champion but as a customizable base model — "Inkling is not the strongest overall model available today, open or closed" — monetized through enterprise fine-tuning on Tinker rather than metered API access. With Meta retreating from large open releases after Llama 4 and Chinese labs (DeepSeek, Qwen, GLM, Kimi) dominating the open-weights field, Inkling is widely described as the largest U.S.-built open-weights model released to date.

## Release Cadence

This is the lab's **first model release**. Prior to Inkling, Thinking Machines published only research previews and blog posts ("Connectionism" series); Inkling is its debut production language model and first open-weights drop.

- **2025-02** — Company founded by Mira Murati (ex-OpenAI CTO) and team.
- **2025–2026** — Research previews and technical blog posts; no production models.
- **2026-07-15** — **Inkling** released: 975B/41B MoE, Apache 2.0, full weights on Hugging Face; immediately fine-tunable on Tinker.
- **2026-07-15** — **Inkling-Small** (276B/12B active) previewed; weights pending completion of testing.

Strategy: a single, deliberate open-weights debut aimed at the enterprise fine-tuning market. The lab's thesis is that AI *shaped by organizations for their own use cases* outperforms one-size-fits-all models. By releasing Apache-2.0 weights and routing revenue through Tinker (LoRA fine-tuning, downloadable self-hosted checkpoints, with a promise that user data is not used to train its own models), Thinking Machines differentiates against closed frontier labs (OpenAI, Anthropic, Google) and against Meta, which has stopped shipping large open models. Inkling is framed as the first in a family of models of different sizes.

## Models & Sizes

| Model | Release | Total Params | Active (if MoE) | Context | License | Open? |
|--------|---------|--------------|-----------------|---------|---------|-------|
| Inkling | 2026-07-15 | 975B | 41B | 1M (256K on Tinker) | Apache 2.0 | Open-weight (MoE, multimodal) |
| Inkling-Small (preview) | 2026-07-15 (weights pending) | 276B | 12B | (expected 1M-class) | Apache 2.0 | Open-weight pending |

Inkling architecture details (from the official model card): 66-layer decoder-only transformer with a sparse MoE feed-forward backbone; each token routed to **6 of 256 routed experts + 2 shared experts** (256 routed + 2 shared, matching the DeepSeek-V3 family design). Routing uses a sigmoid-based router with **auxiliary-loss-free** load-balancing bias. Attention is a hybrid of local and global layers. Numerics supported: **BF16, MXFP8, NVFP4**. Trained on Nvidia GB300 NVL72 systems across 45T multimodal tokens (text, images, audio, video); synthetic data from open-weight models (incl. Kimi K2.5) was used in an early SFT stage. Artificial Analysis ranks Inkling at **41** on its Intelligence Index — the leading open-weights model from a U.S. lab (ahead of Nemotron 3 Ultra at 38, Gemma 4 31B at 29, gpt-oss-120b at 24).

## Openness Status

Thinking Machines' debut is **fully open-weight under Apache 2.0** — free commercial use, modification, and redistribution, with no use-policy toll. This is a clean, permissive posture (no Mistral-style MRL restriction). What is *not* released:
- Training data and full training code are not published (the Training Data Documentation is minimal — public internet + third-party + synthetic, with no detailed provenance).
- Inkling-Small weights are still pending.
- The lab also offers a hosted Tinker API (256K context) and third-party API endpoints (Together, Fireworks, Modal, Databricks, Baseten), but the open weights themselves carry no commercial restriction.

So the lab is best described as **open-weight (Apache 2.0, no commercial restriction) but not fully open (no data/code release)** — and this is a deliberate strategic choice to use open weights as a customer-acquisition flywheel for the Tinker platform.

## Serving (vLLM / llama.cpp / Atlas)

Inkling is a 975B/41B-active MoE — far too large for any single consumer GPU. Per the official model card, the hardware floor is:

- **BF16 checkpoint**: ≥ 2 TB aggregated VRAM → 8× NVIDIA B300 GPUs, or 16× NVIDIA H200 GPUs.
- **NVFP4 quantized checkpoint**: ≥ 600 GB aggregated VRAM →
  - W4A4 on 4× NVIDIA B300 GPUs (requires SM100+ / Blackwell),
  - W4A16 on 8× NVIDIA H200 GPUs.

The model card explicitly lists supported inference frameworks: **SGLang, vLLM, TokenSpeed, Unsloth, or Hugging Face Transformers**. Notes:
- **vLLM**: Supported as an official path; FP8 (MXFP8) and NVFP4 quantization are the practical serving formats. The 41B active/token footprint makes per-request cost moderate, but all 975B parameters must reside in aggregated VRAM.
- **llama.cpp / GGUF**: Not confirmed at launch. The custom MoE layout (256 routed + 2 shared experts, hybrid local/global attention, multimodal encoders) is non-standard and would require explicit upstream support — not a drop-in GGUF today.
- **DGX Spark**: A single DGX Spark (128 GB) is **insufficient** for Inkling at any precision. A multi-node B300/H200 cluster is required; DGX Spark-class hardware only becomes relevant for the pending Inkling-Small (276B/12B active), which may fit a high-memory single node at aggressive quantization.
- **NOT yet runnable in this repo**: no Thinking Machines models are deployed in `inference-containers/`. The 975B Inkling is a multi-GPU cluster workload, not a consumer/edge demo. Inkling-Small, once weights ship, is the realistic candidate for constrained local serving.

## References

- Official site: https://thinkingmachines.ai/
- Inkling announcement ("Introducing Inkling"): https://thinkingmachines.ai/news/introducing-inkling/
- Inkling product page: https://thinkingmachines.ai/inkling/
- Inkling model card: https://thinkingmachines.ai/model-card/inkling
- Training data documentation: https://thinkingmachines.ai/training-data-documentation/
- Model Acceptable Use Policy: https://thinkingmachines.ai/model-acceptable-use-policy/
- Tinker platform: https://thinkingmachines.ai/tinker/
- Tinker docs: https://tinker-docs.thinkingmachines.ai/tinker/
- Tinker cookbook (GitHub): https://github.com/thinking-machines-lab/tinker-cookbook
- Hugging Face (Inkling weights): https://huggingface.co/thinkingmachines/inkling
- Artificial Analysis coverage: https://artificialanalysis.ai/articles/thinking-machines-has-released-inkling-the-new-leading-u-s-open-weights-model
- Artificial Analysis model page: https://artificialanalysis.ai/models/inkling
- Simon Willison (Inkling link blog): https://simonwillison.net/2026/Jul/16/inkling
- TechCrunch (2026-07-15): Thinking Machines amps up its bet against one-size-fits-all AI
- MarkTechPost (2026-07-15): https://www.marktechpost.com/2026/07/15/thinking-machines-lab-releases-inkling-a-975b-parameter-open-weights-multimodal-moe-with-41b-active-parameters-and-controllable-thinking-effort
- Techzine (2026-07-16): https://www.techzine.eu/news/analytics/142945/thinking-machines-lab-releases-inkling-an-open-weights-model

## Local Deployment in This Repo

This repo does **not** deploy any Thinking Machines Lab model — only Qwen, Gemma, DeepSeek, and Nemotron are currently served under `inference-containers/`. Given Inkling's 975B/41B footprint, it is **not feasible on the RTX 5090 or a single DGX Spark**; it requires a multi-GPU B300/H200 cluster (8× B300 for BF16, or 4× B300 for NVFP4 W4A4). The realistic path for this repo is to wait for **Inkling-Small (276B/12B active, Apache 2.0, weights pending)**, which at aggressive NVFP4/GGUF quantization could be a candidate for a DGX Spark-class (128 GB) node once engine support (vLLM/llama.cpp) lands for the custom MoE layout. No Thinking Machines model should be added to the repo until Inkling-Small weights are published and a serving engine confirms support.
