---
lab: "Alibaba (Qwen)"
slug: "alibaba-qwen"
openness: "partial"
local_support: "yes"
updated: "2026-07-19"
notable_models:
  - name: "Qwen3.6-27B"
    size: "27B (dense)"
    license: "Apache 2.0"
  - name: "Qwen3.6-35B-A3B"
    size: "35B total / 3B active"
    license: "Apache 2.0"
  - name: "Qwen3.5-397B-A17B"
    size: "397B total / 17B active"
    license: "Apache 2.0"
  - name: "Qwen3.6-Max-Preview"
    size: "undisclosed (MoE)"
    license: "Closed (API-only)"
---

# Alibaba (Qwen)

## Overview

Qwen (Tongyi Qianwen) is the large language model family developed by Alibaba Cloud and the Alibaba DAMO Academy, first launched in April 2023 with the open-source release of Qwen-7B in August 2023. It has grown into one of the most prolific and widely-downloaded open-weight model families in the world, with more than 100 open-weight releases and billions of downloads across Hugging Face and ModelScope. In the open-model landscape Qwen is Alibaba's counterpart to Meta's Llama and Google's Gemma, and is widely regarded as the leading open-weight family out of China, spanning dense, MoE, code, vision-language, and omni-modal (audio+video) variants.

A notable 2026 policy shift: while Qwen's small and mid-tier models remain fully open (Apache 2.0, self-hostable), Alibaba's **frontier flagship tier has moved to closed weights** — Qwen3.6-Max-Preview (April 2026) and Qwen3.7-Max (May 2026) ship API-only with no open release. This marks Alibaba's first sustained turn toward the OpenAI/Anthropic "frontier-closed, smaller-open" strategy.

## Release Cadence

- **2023-08** — Qwen-7B (and Qwen-14B) open-source under the custom Tongyi-Qianwen License; Qwen-VL vision-language model.
- **2024-01** — Qwen1.5 (0.5B–72B) under the Tongyi-Qianwen License.
- **2024-06-06** — Qwen2 (0.5B, 1.5B, 7B, 57B-A14B MoE, 72B); first flagship under Apache 2.0 (72B kept custom license).
- **2024-09-19** — Qwen2.5 (0.5B–72B, Coder, Math); largest open-source release to date, mostly Apache 2.0. Qwen2-VL (72B) follows.
- **2025-01** — Qwen2.5-Max (proprietary API flagship); Qwen2.5-VL (3B/7B/32B/72B); Qwen2.5-Omni-7B (omni-modal).
- **2025-03** — QwQ-32B reasoning model (Apache 2.0).
- **2025-04-28** — Qwen3 (0.6B–32B dense + 30B-A3B, 235B-A22B MoE), all Apache 2.0; hybrid thinking/non-thinking modes.
- **2025-09-11** — Qwen3-Next-80B-A3B (hybrid linear-attention research model).
- **2026-02-16** — Qwen3.5-397B-A17B (flagship MoE, Apache 2.0) — first open-weight model with the Gated DeltaNet + MoE hybrid architecture.
- **2026-02-24** — Qwen3.5-122B-A10B, Qwen3.5-35B-A3B, Qwen3.5-27B.
- **2026-03-02** — Qwen3.5 small tier (0.8B, 2B, 4B, 9B).
- **2026-04-16** — Qwen3.6-35B-A3B (open, Apache 2.0).
- **2026-04-20** — Qwen3.6-Max-Preview (closed, API-only) — Alibaba's first closed-weights flagship.
- **2026-04-22** — Qwen3.6-27B (open, Apache 2.0) — the dense open flagship.
- **2026-05-20** — Qwen3.7-Max / Qwen3.7-Plus (closed previews, API-only).

Cadence accelerated sharply: from roughly one or two major generations per year (Qwen1.5→Qwen2→Qwen2.5) to multiple substantial releases per year by 2025–2026, with a clear push toward agentic coding, multimodal unification (single text+vision backbone), and hybrid linear-attention (Gated DeltaNet) architectures.

## Models & Sizes

| Model | Release | Total Params | Active (if MoE) | Context | License | Open? |
|--------|---------|--------------|-----------------|---------|---------|-------|
| Qwen-7B / 14B | 2023-08 | 7B / 14B | — | 8K (32K extend) | Tongyi-Qianwen | Open-weight (restricted) |
| Qwen1.5 (0.5B–72B) | 2024-01 | 0.5B–72B | — | 32K | Tongyi-Qianwen | Open-weight (restricted) |
| Qwen2 (0.5B/1.5B/7B/57B-A14B) | 2024-06-06 | 0.5B–57B | 14B (MoE) | 128K | Apache 2.0 | Open-weight |
| Qwen2-72B | 2024-06-06 | 72B | — | 32K | Tongyi-Qianwen | Open-weight (restricted) |
| Qwen2.5 (0.5B–72B) | 2024-09-19 | 0.5B–72B | — | 128K | Apache 2.0 (3B/72B custom) | Open-weight |
| Qwen2.5-Coder (1.5B/7B/32B) | 2024-11 | 1.5B–32B | — | 128K | Apache 2.0 | Open-weight |
| Qwen2.5-VL (3B/7B/32B/72B) | 2025-01 | 3B–72B | — | 128K | Apache 2.0 | Open-weight |
| QwQ-32B | 2025-03 | 32B | — | 32K | Apache 2.0 | Open-weight |
| Qwen3 (0.6B–32B dense) | 2025-04-28 | 0.6B–32B | — | 128K | Apache 2.0 | Open-weight |
| Qwen3-30B-A3B | 2025-04-28 | 30B | 3B | 128K | Apache 2.0 | Open-weight (MoE) |
| Qwen3-235B-A22B | 2025-04-28 | 235B | 22B | 128K | Apache 2.0 | Open-weight (MoE) |
| Qwen3-Next-80B-A3B | 2025-09-11 | 80B | 3B | 256K (YA) | Apache 2.0 | Open-weight (research) |
| Qwen3.5-397B-A17B | 2026-02-16 | 397B | 17B | 262K (1M YA) | Apache 2.0 | Open-weight (MoE) |
| Qwen3.5-122B-A10B | 2026-02-24 | 122B | 10B | 262K | Apache 2.0 | Open-weight (MoE) |
| Qwen3.5-27B | 2026-02-24 | 27B | — | 262K | Apache 2.0 | Open-weight (dense, multimodal) |
| Qwen3.5-35B-A3B | 2026-02-24 | 35B | 3B | 262K | Apache 2.0 | Open-weight (MoE) |
| Qwen3.5 (0.8B/2B/4B/9B) | 2026-03-02 | 0.8B–9B | — | 262K | Apache 2.0 | Open-weight (small) |
| Qwen3.6-35B-A3B | 2026-04-16 | 35B | 3B | 262K (1M YA) | Apache 2.0 | Open-weight (MoE) |
| Qwen3.6-27B | 2026-04-22 | 27B | — | 262K (1M YA) | Apache 2.0 | Open-weight (dense, multimodal) |
| Qwen3.6-Max-Preview | 2026-04-20 | undisclosed (~35B MoE) | — | 256K | Closed (API-only) | Closed |
| Qwen3.6-Plus | 2026-04 | undisclosed | — | 1M | Closed (API-only) | Closed |
| Qwen3.7-Max / Plus | 2026-05 | undisclosed | — | — | Closed (API-only) | Closed |

## Openness Status

Qwen's small and mid-tier models are **open-weight under Apache 2.0** — permissive, allowing commercial use, modification, and redistribution without field-of-use restrictions. This has been the case across virtually every open release since Qwen2 (June 2024), including the entire Qwen3, Qwen3.5, and Qwen3.6 open families (all Apache 2.0, with only the original Qwen/Qwen1.5/Qwen2-72B using the custom Tongyi-Qianwen License).

**The important 2026 policy nuance — frontier tier closing:** Starting with Qwen3.6-Max-Preview (2026-04-20), Alibaba's top-tier frontier models no longer ship open weights. The pattern across 2026:

- **Open & self-hostable (≤ ~35B class):** Qwen3.6-27B (dense), Qwen3.6-35B-A3B (MoE), and the entire Qwen3.5 family including the 397B-A17B MoE flagship. These remain Apache-2.0 and freely downloadable.
- **Closed (API-only):** Qwen3.6-Max-Preview, Qwen3.6-Plus, Qwen3.7-Max, Qwen3.7-Plus. No Hugging Face weights, no fine-tuning, no self-hosting.

Independent analysts (DeepLearning.AI "The Batch," AgentMarketCap, AIToolsRecap) characterize this as Alibaba's first sustained shift "from open to closed" at the frontier, mirroring OpenAI/Anthropic, motivated by turning top-tier models into revenue via the Alibaba Cloud Model Studio API and the newly-charged Qwen Code CLI. The reported strategy: **keep smaller models (27B and below) openly released while withholding frontier weights.** This is consistent with the repo's own focus — Qwen3.6-27B is widely cited as the best small local model for consumer GPUs and single DGX Spark units, and the 35B-A3B MoE is the efficient open counterpart.

What remains not "fully open" even for the open models: training data and full training code are not released. So Qwen is open-weight (Apache 2.0) but not fully open (no data/code release), and now only partially open overall given the closed frontier tier.

## Serving (vLLM / llama.cpp / Atlas)

- **vLLM**: Qwen3.6 models require vLLM ≥ 0.17.0. The Qwen3.6-35B-A3B MoE serves from BF16, Qwen's official FP8 checkpoint, or NVIDIA's ModelOpt **NVFP4** checkpoint (`nvidia/Qwen3.6-35B-A3B-NVFP4`) — the NVFP4 build is explicitly validated on **NVIDIA Blackwell (DGX Spark / GB10)**. All Qwen3.6 checkpoints share the same architecture/`model_type` as Qwen3.5 and load with the `Qwen3_5` classes in Transformers. **MTP (multi-token prediction) speculative decoding** is supported for both 27B and 35B-A3B to boost throughput.
- **llama.cpp / GGUF**: Qwen3.6-27B and 35B-A3B have community GGUF builds (Unsloth Dynamic, etc.). The 27B in **UD-Q4_K_XL** (~16–22 GB) and **Q4_K_M** (~16.8 GB) runs on 24 GB cards; llama.cpp merged native **MTP** support for Qwen3.6 (PR #22673, May 2026). The 35B-A3B in UD-Q4_K_XL is ~22.4 GB and runs ~101 tok/s on an RTX 3090.
- **Atlas (GB10 / DGX Spark)**: FP8 serving of Qwen3.6 on the GB10 (DGX Spark) is supported via the same NVFP4/FP8 checkpoints.
- **Note**: Qwen3.6-27B is natively multimodal (text + image + video); vision requires a separate `mmproj` file in llama.cpp. DFlash block-diffusion speculative decoding currently supports the 27B dense only, not the 35B MoE.

## References

- Official site / chat: https://qwen.ai and https://chat.qwen.ai
- Qwen GitHub org: https://github.com/QwenLM
- Qwen3.6 GitHub: https://github.com/QwenLM/Qwen3.6
- Qwen3.6-27B model card (HF): https://huggingface.co/Qwen/Qwen3.6-27B
- Qwen3.6-35B-A3B model card (HF): https://huggingface.co/Qwen/Qwen3.6-35B-A3B
- Qwen3.6 collection (HF): https://huggingface.co/collections/Qwen/qwen36
- Qwen3.5 collection (HF): https://huggingface.co/collections/Qwen/qwen35
- Qwen3.6-27B release blog: https://qwen.ai/blog?id=qwen3.6-27b
- Qwen3.6-35B-A3B release blog: https://qwen.ai/blog?id=qwen3.6-35b-a3b
- Qwen3.5 release blog: https://qwen.ai/blog?id=qwen3.5
- vLLM recipe (Qwen3.6-35B-A3B, NVFP4/MTP): https://recipes.vllm.ai/Qwen/Qwen3.6-35B-A3B

### Local-serving recipes
- vLLM recipe — Qwen3.6-35B-A3B: https://recipes.vllm.ai/Qwen/Qwen3.6-35B-A3B
- Unsloth GGUF — Qwen3.6-27B: https://huggingface.co/unsloth/Qwen3.6-27B-GGUF
- NVIDIA NVFP4 checkpoint: https://huggingface.co/nvidia/Qwen3.6-35B-A3B-NVFP4
- ModelScope (Alibaba mirror): https://modelscope.cn/collections/Qwen/Qwen36
- Qwen2.5 blog: https://qwenlm.github.io/blog/qwen2.5 (now https://qwen.ai/blog?id=qwen2.5)
- Qwen2 technical report (arXiv): https://arxiv.org/abs/2407.10671
- Qwen2.5 technical report (arXiv): https://arxiv.org/abs/2412.15115
- Artificial Analysis (Qwen3.6-Max): https://artificialanalysis.ai/models/qwen3-6-max
- Wikipedia (Qwen): https://en.wikipedia.org/wiki/Qwen

## Local Deployment in This Repo

This repo serves Qwen3.6 locally on consumer (RTX 5090) and edge (DGX Spark) hardware — the 27B dense and 35B-A3B MoE, both Apache-2.0 and the repo's primary local Qwen models:

- **Qwen3.6-27B (vLLM, NVFP4-MTP)** on RTX 5090: [inference-containers/vllm/qwen-3.6-27b-rtx5090](../vllm/qwen-3.6-27b-rtx5090) and DGX Spark: [inference-containers/vllm/qwen-3.6-27b-dgx-spark](../vllm/qwen-3.6-27b-dgx-spark)
- **Qwen3.6-35B-A3B (vLLM, NVFP4-MTP)** on RTX 5090: [inference-containers/vllm/qwen-3.6-35b-5090](../vllm/qwen-3.6-35b-5090) and DGX Spark: [inference-containers/vllm/qwen-3.6-35b-dgx-spark](../vllm/qwen-3.6-35b-dgx-spark)
- **Qwen3.6-27B (llama.cpp GGUF, UD-Q4_K_XL + MTP)** on RTX 5090: [inference-containers/llamacpp/qwen-3.6-27b-5090](../llamacpp/qwen-3.6-27b-5090) and DGX Spark: [inference-containers/llamacpp/qwen-3.6-27b-dgx-spark](../llamacpp/qwen-3.6-27b-dgx-spark)
- **Qwen3.6-35B-A3B (llama.cpp GGUF)** on DGX Spark: [inference-containers/llamacpp/qwen-3.6-35b-dgx-spark](../llamacpp/qwen-3.6-35b-dgx-spark)
- **Qwen3.6-27B (Atlas FP8, GB10)** on DGX Spark: [inference-containers/atlas/qwen-3.6-27b-dgx-spark](../atlas/qwen-3.6-27b-dgx-spark)
- **Qwen3.6-35B-A3B (Atlas FP8, GB10)** on DGX Spark: [inference-containers/atlas/qwen-3.6-35b-dgx-spark](../atlas/qwen-3.6-35b-dgx-spark)
