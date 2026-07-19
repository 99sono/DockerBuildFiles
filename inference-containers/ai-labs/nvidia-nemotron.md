---
lab: "NVIDIA (Nemotron)"
slug: "nvidia-nemotron"
openness: "open-weight"
local_support: "yes"
updated: "2026-07-19"
notable_models:
  - name: "Nemotron-Cascade-2-30B-A3B"
    size: "30B total / 3B active (NVFP4)"
    license: "NVIDIA Open Model License"
  - name: "Nemotron 3 Ultra 550B-A55B"
    size: "550B total / 55B active"
    license: "NVIDIA Open Model License"
  - name: "Nemotron 3 Super 120B-A12B"
    size: "120B total / 12B active"
    license: "NVIDIA Open Model License"
  - name: "Nemotron 3 Nano 30B-A3B"
    size: "30B total / 3B active"
    license: "NVIDIA Open Model License"
  - name: "Nemotron-4 340B"
    size: "340B"
    license: "NVIDIA Open Model License"
---

# NVIDIA (Nemotron)

## Overview

NVIDIA Nemotron is NVIDIA's family of open models, datasets, and post-training techniques purpose-built for efficient, transparent, agentic AI. The lineage traces back to the Megatron-LM and NeMo frameworks (2019–2022), with the first "Nemotron" branded models (Nemotron-3 8B) appearing in November 2023. NVIDIA positions Nemotron as an **open platform**: not only are model weights published, but — unlike most open-weight labs — NVIDIA also releases substantial training data, synthetic-data-generation pipelines, and training recipes (the steps to recreate the models). Under the leadership of Bryan Catanzaro (VP of Applied Deep Learning Research), the program's explicit goal is to give enterprises and sovereign-AI builders the transparency to customize models aligned to their own data and regulations.

Nemotron spans text/reasoning LLMs, multimodal (vision, speech, Omni), retrieval, reward, and safety models, organized into tiers: **Nano** (edge/PC/cheap sub-agents), **Super** (single-GPU high-throughput), and **Ultra** (multi-GPU datacenter frontier reasoning). The 2025–2026 generation (Nemotron 3 and Nemotron-Cascade) introduced a hybrid **Mamba-Transformer MoE** architecture with up to 1M-token context, multi-token prediction (MTP), and NVFP4 training for Blackwell. Unlike the fully-permissive Apache 2.0 used by some labs, Nemotron ships under the **NVIDIA Open Model License** — permissive for commercial use and modification, but with specific field-of-use and redistribution restrictions that stop short of "fully open."

## Release Cadence

- **2023-11** — Nemotron-3 8B (base/chat-SFT/chat-RLHF), enterprise-ready NeMo models; NVIDIA AI Foundation Models.
- **2024-02** — Nemotron-4 15B (multilingual, 8T tokens, ~15B params). [arXiv:2402.16819]
- **2024-06-14** — **Nemotron-4 340B** (Base / Instruct / Reward), ~340B params, trained on 9T tokens. Introduces the NVIDIA Open Model License. [arXiv:2406.11704]
- **2024-07 → 2024-09** — Minitron / Nemotron-Mini 4B and Mini Hindi 4B (pruned from 15B).
- **2024-09** — Nemotron-H (hybrid Mamba-Transformer, 8B).
- **2024-10** — Llama-3.1-Nemotron-70B-Instruct and -Reward (RL-tuned from Meta Llama 3.1 70B); Llama-3.1-Nemotron-51B (Oct 24).
- **2025-05-23** — Llama Nemotron Nano 4B / Super 49B / Ultra 253B (reasoning models, GTC25).
- **2025-08-19** — Nemotron Nano 2 (hybrid Mamba-Transformer, 9B).
- **2025-09-05** — Nemotron Nano 2 9B.
- **2025-12-02** — Nemotron Nano 2 12B.
- **2025-12-15** — **Nemotron 3 family announced**: Nano 30B-A3B ships immediately; Super and Ultra teased for H1 2026. Hybrid Mamba-Transformer MoE, 1M context. [NVIDIA Newsroom]
- **2026-03-11** — **Nemotron 3 Super 120B-A12B** released (NVFP4, LatentMoE, MTP).
- **2026-03-16/19** — **Nemotron-Cascade-2-30B-A3B** released (post-trained from Nemotron-3 Nano base with Cascade RL; gold-medal IMO 2025 / IOI 2025). [research.nvidia.com/labs/nemotron/nemotron-cascade-2]
- **2026-04-28/29** — Nemotron 3 Nano Omni (multimodal text/image/video/audio sub-agent); Nemotron 3.5 Content Safety (Jun 4).
- **2026-06-04** — **Nemotron 3 Ultra 550B-A55B** released at GTC San Jose 2026 — frontier open reasoning model for long-running agents. [research.nvidia.com/labs/nemotron/Nemotron-3-Ultra]

Cadence accelerated sharply: from one-off releases in 2023–2024 to a steady multi-model-per-quarter drumbeat through 2025–2026, with the newest generations (Nemotron 3 Nano/Super/Ultra, Nemotron-Cascade-2) landing in the first half of 2026. The strategic direction is clearly toward **hybrid efficient architectures and agentic/long-context workloads**, with open data and recipes as a differentiator.

## Models & Sizes

| Model | Release | Total Params | Active (if MoE) | Context | License | Open? |
|--------|---------|--------------|-----------------|---------|---------|-------|
| Nemotron-3 8B (base/chat) | 2023-11 | 8B | — | 4K | NVIDIA Open Model License | Open-weight |
| Nemotron-4 15B | 2024-02 | 15B | — | 4K | NVIDIA Open Model License | Open-weight |
| Nemotron-4 340B (Base/Instruct/Reward) | 2024-06 | 340B | — | 4K | NVIDIA Open Model License | Open-weight |
| Nemotron-Mini 4B / Mini Hindi 4B | 2024-08/09 | 4B | — | 4K | NVIDIA Open Model License | Open-weight |
| Nemotron-H 8B | 2024-09 | 8B | — | — | NVIDIA Open Model License | Open-weight (hybrid Mamba-TF) |
| Llama-3.1-Nemotron-70B-Instruct/Reward | 2024-10 | 70B | — | 128K | NVIDIA Open Model License | Open-weight |
| Llama-3.1-Nemotron-51B | 2024-10 | 51B | — | 128K | NVIDIA Open Model License | Open-weight |
| Llama Nemotron Nano 4B / Super 49B / Ultra 253B | 2025-05 | 4B / 49B / 253B | — | 128K | NVIDIA Open Model License | Open-weight (reasoning) |
| Nemotron Nano 2 (9B) | 2025-08/09 | 9B | — | 131K | NVIDIA Open Model License | Open-weight (hybrid Mamba-TF) |
| Nemotron Nano 2 12B | 2025-12-02 | 12B | — | 131K | NVIDIA Open Model License | Open-weight |
| Nemotron 3 Nano 30B-A3B | 2025-12-15 | 30B | 3.2B | 1M (262K HF) | NVIDIA Open Model License | Open-weight (hybrid MoE) |
| Nemotron 3 Super 120B-A12B | 2026-03-11 | 120B | 12B | 1M (256K HF) | NVIDIA Open Model License | Open-weight (NVFP4, LatentMoE, MTP) |
| **Nemotron-Cascade-2-30B-A3B** | 2026-03-19 | 30B | 3B | 262K | NVIDIA Open Model License | Open-weight (Cascade RL, thinking+instruct) |
| Nemotron 3 Nano Omni 30B-A3B | 2026-04-28 | 30B | 3B | 256K | NVIDIA Open Model License | Open-weight (multimodal) |
| Nemotron 3 Ultra 550B-A55B | 2026-06-04 | 550B | 55B | 1M | NVIDIA Open Model License | Open-weight (NVFP4, frontier reasoning) |
| Nemotron 3.5 Content Safety | 2026-06-04 | — | — | 128K | NVIDIA Open Model License | Open-weight |

## Openness Status

NVIDIA describes Nemotron as a family of **open models with open weights, training data, and recipes**. In practice this is stronger than typical open-weight releases (which ship only weights) but weaker than "fully open":

- **Weights are open** and downloadable from Hugging Face (`nvidia/`) and NGC, under the **NVIDIA Open Model License**. This license is permissive — it allows distribution, modification, and commercial use of the models and their outputs, without attribution requirements — but it is **not** Apache 2.0/MIT. It carries field-of-use and redistribution conditions (e.g., restrictions on using the models to train competing foundation models and on certain regulatory circumventions), so it is best classified as **open-weight (permissive but restricted)** rather than fully open.
- **Training data and recipes are released** to an unusual degree: Nemotron-4 340B open-sourced its >98%-synthetic alignment pipeline; Nemotron 3 ships open datasets, RL environments, and the NeMo/NeMo-RL post-training recipes (e.g., the Cascade-2 SFT and RL datasets are on Hugging Face). The `NVIDIA-NeMo/Nemotron` GitHub hub collects training recipes, deployment cookbooks, and use-case examples under Apache 2.0.
- **What is NOT released**: NVIDIA does not publish fully reproducible from-scratch pre-training runs for every model, and the underlying Megatron/NeMo training infrastructure, while open-source as a framework, is operated by NVIDIA. So Nemotron is **open-weight + open-data/recipe, under a restricted-but-commercial-friendly license** — more open than Meta Llama's community license in data transparency, but with more usage constraints than Apache 2.0 labs like Mistral.

Supporting tooling is also open: **NVIDIA Model Optimizer (ModelOpt)** (Apache 2.0) provides quantization (incl. NVFP4), pruning, distillation, and speculative decoding for TensorRT-LLM / vLLM deployment — the closest thing to a dedicated "Nemotron-Optimizer" in the ecosystem.

## Serving (vLLM / llama.cpp / Atlas)

- **vLLM**: Nemotron-4 340B, Llama-Nemotron, and the Nemotron 3 / Cascade-2 families are served via vLLM using `--trust-remote-code`. The hybrid Mamba-Transformer models require the SSM cache kept in `float32` (`--mamba-ssm-cache-dtype float32`) and use the `nemotron_v3` reasoning parser. MoE backends include MARLIN and FlashInfer NVFP4 paths. Multi-token prediction (MTP) layers are supported for speculative-style generation on Super/Ultra.
- **NVFP4 / FP8**: Nemotron 3 Super and Ultra are trained and distributed in **NVFP4** (NVIDIA 4-bit float, Blackwell), served via vLLM `modelopt_fp4` quantization; KV cache commonly set to `fp8_e4m3`. This repo's container runs the NVFP4-quantized Cascade-2 checkpoint (`chankhavu/Nemotron-Cascade-2-30B-A3B-NVFP4`) at `--max-model-len 256000`. Dense Nemotron-4 340B was sized to fit FP8 on one 8×H100 DGX node.
- **llama.cpp / GGUF**: Community and official GGUF builds exist for the smaller Nemotron models (Nemotron-3 Nano 30B-A3B, Nemotron Nano 2, Llama-Nemotron Nano 4B). Nemotron-Cascade-2-30B-A3B quantizes well: Q4_K_M ≈ 18.9 GB download / ~21 GB VRAM, Q8_0 ≈ 33.8 GB, FP16 ≈ 63 GB — runnable on an RTX 5090 (32 GB) at Q4_K_M and comfortably on DGX Spark (128 GB). The hybrid Mamba layers need a llama.cpp build with mamba/SSM support (NVIDIA published a dedicated "Nemotron 3 Nano with llama.cpp Playbook" for DGX Spark/GB10).
- **Other engines**: TensorRT-LLM (NVIDIA-native, best NVFP4 throughput), SGLang, Ollama, and NVIDIA NIM microservices; Docker Model Runner via `docker model run hf.co/nvidia/Nemotron-Cascade-2-30B-A3B`.

## References

- Official Nemotron page: https://www.nvidia.com/en-us/ai-data-science/foundation-models/nemotron/
- NVIDIA Developer Nemotron topic: https://developer.nvidia.com/topics/ai/nemotron
- NVIDIA Newsroom — Nemotron 3 debut: https://nvidianews.nvidia.com/news/nvidia-debuts-nemotron-3-family-of-open-models
- NVIDIA Open Model License: https://www.nvidia.com/en-us/agreements/enterprise-software/nvidia-open-model-license/
- Nemotron-4 340B technical report (arXiv): https://arxiv.org/abs/2406.11704
- Nemotron-4 340B research page: https://research.nvidia.com/publication/2024-06_nemotron-4-340b
- Nemotron-4 340B HF collection: https://huggingface.co/collections/nvidia/nemotron-4-340b-666b7ebaf1b3867caf2f1911
- Nemotron-4 340B-Instruct HF: https://huggingface.co/nvidia/Nemotron-4-340B-Instruct
- Nemotron 3 family page: https://research.nvidia.com/labs/nemotron/Nemotron-3/
- Nemotron 3 white paper: https://research.nvidia.com/labs/nemotron/files/NVIDIA-Nemotron-3-White-Paper.pdf
- Nemotron 3 Ultra: https://research.nvidia.com/labs/nemotron/Nemotron-3-Ultra/
- Nemotron 3 Ultra HF (BF16): https://huggingface.co/nvidia/NVIDIA-Nemotron-3-Ultra-550B-A55B-BF16
- Nemotron 3 Super HF (NVFP4): https://huggingface.co/nvidia/NVIDIA-Nemotron-3-Super-120B-A12B-FP8
- Nemotron 3 Nano HF collection: https://huggingface.co/collections/nvidia/nvidia-nemotron-v3
- **Nemotron-Cascade-2 page**: https://research.nvidia.com/labs/nemotron/nemotron-cascade-2/
- **Nemotron-Cascade-2-30B-A3B HF**: https://huggingface.co/nvidia/Nemotron-Cascade-2-30B-A3B
- Nemotron-Cascade-2 SFT data: https://huggingface.co/datasets/nvidia/Nemotron-Cascade-2-SFT-Data
- Nemotron-Cascade-2 RL data: https://huggingface.co/datasets/nvidia/Nemotron-Cascade-2-RL-data
- Nemotron-Cascade-2 technical report (arXiv): https://arxiv.org/abs/2603.19220
- NeMo Nemotron asset hub (GitHub, Apache 2.0): https://github.com/NVIDIA-NeMo/Nemotron
- NeMo-RL post-training library: https://github.com/NVIDIA-NeMo/RL
- NVIDIA Model Optimizer (ModelOpt, Apache 2.0): https://github.com/NVIDIA/Model-Optimizer
- build.nvidia.com (demo endpoints / NIM): https://build.nvidia.com/ and https://build.nvidia.com/nvidia/nemotron-3-nano-30b-a3b
- Nemotron 3 Nano llama.cpp Playbook (DGX Spark): https://forums.developer.nvidia.com/t/nemotron-3-nano-30b-with-llama-cpp-playbook/355147

### Local-serving recipes
- vLLM recipe — Nemotron 3 Nano 30B-A3B: https://recipes.vllm.ai/nvidia/NVIDIA-Nemotron-3-Nano-30B-A3B-BF16
- Unsloth "Run Nemotron 3 locally" guide: https://unsloth.ai/docs/models/nemotron-3
- Unsloth GGUF — Nemotron 3 Nano 30B-A3B: https://huggingface.co/unsloth/Nemotron-3-Nano-30B-A3B-GGUF

> Note: **Nemotron-Cascade-2** (the model deployed in this repo) has no official vLLM Recipes page and no Unsloth GGUF; run it via the NVIDIA-hosted vLLM launch command on its HF card (`nvidia/Nemotron-Cascade-2-30B-A3B`) or third-party GGUFs (`bartowski/nvidia_Nemotron-Cascade-2-30B-A3B-GGUF`).

## Local Deployment in This Repo

This repo **does** deploy a Nemotron model: **Nemotron-Cascade-2-30B-A3B-NVFP4** served via **vLLM** at `inference-containers/vllm/nemotron-cascade-2/`.

- **Engine**: `vllm/vllm-openai:nightly` under Docker Compose, with `--trust-remote-code`, `--quantization modelopt_fp4` (weights stay NVFP4), `--kv-cache-dtype fp8_e4m3`, `--max-model-len 256000`, and `--mamba-ssm-cache-dtype float32` for the hybrid SSM/Attention layers. Reasoning uses the `nemotron_v3` parser; tool calls use the `qwen3_coder` parser.
- **Checkpoint**: `chankhavu/Nemotron-Cascade-2-30B-A3B-NVFP4` (a community NVFP4 quant of the 30B-A3B model; the original `nvidia/Nemotron-Cascade-2-30B-A3B` is also on Hugging Face).
- **Hardware fit**: At NVFP4 the 30B/3B-active MoE fits comfortably on a single **RTX 5090 (32 GB)** with headroom for 256K context; it is the natural consumer-GPU Nemotron deployment in this repo. On **DGX Spark (128 GB)** the same container runs with margin to spare and can host larger Nemotron 3 variants (Nano 30B-A3B BF16, or even Super 120B-A12B-NVFP4) if swapped into the compose config. The setup is tuned for Blackwell + WSL2 stability (`VLLM_WORKER_MULTIPROC_METHOD=spawn`, `expandable_segments:True`).

This is the only Nemotron container currently present under `inference-containers/`. The Llama-Nemotron, Nemotron 3 Nano, and Nemotron 3 Super/Ultra checkpoints are all directly runnable with the same vLLM + NVFP4 recipe by changing the `command` model id in `docker-compose.yml`.
