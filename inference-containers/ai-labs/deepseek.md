---
lab: "DeepSeek"
slug: "deepseek"
openness: "open-weight"
local_support: "yes"
updated: "2026-07-19"
notable_models:
  - name: "DeepSeek-V4-Flash"
    size: "284B total / 13B active"
    license: "MIT"
  - name: "DeepSeek-V4-Pro"
    size: "1.6T total / 49B active"
    license: "MIT"
  - name: "DeepSeek-V3.2"
    size: "671B total / 37B active"
    license: "MIT"
  - name: "DeepSeek-R1"
    size: "671B total / 37B active"
    license: "MIT"
  - name: "DeepSeek-V3"
    size: "671B total / 37B active"
    license: "MIT"
---

# DeepSeek

## Overview

DeepSeek is a Chinese AI lab (Hangzhou-based, founded 2023 as a spin-off of the quantitative hedge fund High-Flyer) best known for a series of highly capable, openly-licensed Mixture-of-Experts (MoE) foundation models. It rose to global prominence with the December 2024 release of DeepSeek-V3 — a 671B-parameter MoE trained for a reported ~$5.57M of disclosed GPU compute — and the January 2025 release of DeepSeek-R1, a reasoning model that matched OpenAI's o1 at a fraction of the cost. In the open-model landscape DeepSeek is the leading open-weight challenger to Meta's Llama and Mistral, distinguished by aggressive architectural innovation (MLA, DeepSeekMoE, MTP, sparse attention, mHC) rather than raw scale alone. As of 2026 it ships frontier-scale open-weight models (V4-Pro at 1.6T parameters) under the permissive MIT license.

## Release Cadence

- **2023-11-29** — DeepSeek-LLM (7B, 67B Base/Chat), the lab's first open models; DeepSeek-Coder (1.3B–33B).
- **2024-05-06** — DeepSeek-V2 (236B / 21B active MoE), introducing Multi-head Latent Attention (MLA) and DeepSeekMoE; V2-Lite (16B / 2.4B) on 2024-05-16.
- **2024-09-05** — DeepSeek-V2.5, a merged general+coding chat model (V2.5-1210 revision on 2024-12-10).
- **2024-11-20** — DeepSeek-R1-Lite-Preview (reasoning preview).
- **2024-12-26** — DeepSeek-V3 (671B / 37B active MoE, 64K context, FP8 training); V3-0324 update on 2025-03-24.
- **2025-01-20** — DeepSeek-R1 and R1-Zero (671B / 37B), MIT-licensed, plus six R1-distill dense models (1.5B–70B). R1-0528 upgrade on 2025-05-28.
- **2025-08-21** — DeepSeek-V3.1 (hybrid reasoning, 128K context); V3.1-Terminus on 2025-09-22.
- **2025-09-29** — DeepSeek-V3.2-Exp (introduces DeepSeek Sparse Attention / DSA).
- **2025-12-01** — DeepSeek-V3.2 and V3.2-Speciale (DSA becomes standard; reasoning-in-tool-use).
- **2026-04-24** — DeepSeek-V4 (Preview): V4-Pro (1.6T / 49B) and V4-Flash (284B / 13B), both 1M context, MIT license, with CSA/HCA hybrid attention, mHC, and Muon optimizer.

Cadence accelerated from roughly one major family per year (V2 → V3) to multiple substantial releases per year by 2025–2026, with a clear shift toward long-context efficiency and agentic/reasoning-first capabilities.

## Models & Sizes

| Model | Release | Total Params | Active (if MoE) | Context | License | Open? |
|--------|---------|--------------|-----------------|---------|---------|-------|
| DeepSeek-LLM 7B / 67B | 2023-11-29 | 7B / 67B | — | 4K | MIT | Open-weight (dense) |
| DeepSeek-Coder (1.3B–33B) | 2023-11 | 1.3B–33B | — | 16K | MIT / DeepSeek License | Open-weight (dense) |
| DeepSeek-V2 (Lite) | 2024-05-06 | 236B (16B Lite) | 21B (2.4B Lite) | 128K (32K Lite) | MIT / DeepSeek Model License | Open-weight (MoE) |
| DeepSeek-V2.5 | 2024-09-05 | 236B | 21B | 128K | MIT / DeepSeek Model License | Open-weight (MoE) |
| DeepSeek-R1 / R1-Zero | 2025-01-20 | 671B | 37B | 128K | MIT | Open-weight (MoE) |
| DeepSeek-R1-Distill (Qwen/Llama 1.5B–70B) | 2025-01-20 | 1.5B–70B | — | 32K–128K | MIT (R1) / Apache 2.0 & Llama licenses (bases) | Open-weight (dense) |
| DeepSeek-V3 (V3-0324) | 2024-12-26 | 671B | 37B | 64K (128K via V3.1) | MIT / DeepSeek Model License | Open-weight (MoE) |
| DeepSeek-V3.1 / -Terminus | 2025-08-21 | 671B | 37B | 128K | MIT | Open-weight (MoE, hybrid reasoning) |
| DeepSeek-V3.2 / -Speciale | 2025-12-01 | 671B | 37B | 128K | MIT | Open-weight (MoE + DSA) |
| DeepSeek-V4-Flash | 2026-04-24 | 284B | 13B | 1M | MIT | Open-weight (MoE) |
| DeepSeek-V4-Flash-Base | 2026-04-24 | 284B | 13B | 1M | MIT | Open-weight (MoE) |
| DeepSeek-V4-Pro | 2026-04-24 | 1.6T | 49B | 1M | MIT | Open-weight (MoE) |
| DeepSeek-V4-Pro-Base | 2026-04-24 | 1.6T | 49B | 1M | MIT | Open-weight (MoE) |

## Openness Status

DeepSeek is **open-weight**: every major model (V2, V3, V3.1/3.2, R1, V4) ships publicly downloadable weights on Hugging Face and ModelScope. Licensing evolved toward maximal permissiveness:

- The **code repositories** are MIT-licensed throughout.
- **DeepSeek-V3/V3.1/V3.2 weights** on Hugging Face are tagged **MIT** (the repo README references a custom "Model License" for the base/Chat weights that permits commercial use; HF-hosted weights explicitly carry MIT).
- **DeepSeek-R1** and all R1-distills are **MIT** — explicitly "distill & commercialize freely."
- **DeepSeek-V4** (Pro and Flash, base and instruct) weights are **MIT**-licensed — the most permissive yet, matching/exceeding Llama and Gemma 4 on licensing friction.

Importantly, DeepSeek does **not** release training data or full training code, so the lab is open-weight but not fully open (no data/code release). Architectural innovations are, however, well documented in open arXiv papers. The V4 release notably adds FP4+FP8 quantization-aware-trained weights, making frontier-scale models practical on constrained hardware.

## Architectural Innovations

DeepSeek is distinguished by a steady stream of architecture-first efficiency work:

- **Multi-head Latent Attention (MLA)** — introduced in V2; low-rank joint compression of KV caches, cutting KV memory by ~93.3% vs MHA. Retained through V3/V3.1/V3.2.
- **DeepSeekMoE** — fine-grained expert segmentation with shared experts and top-k routing (256 routed experts, 8 active + 1 shared in V3/V3.2); auxiliary-loss-free load balancing in V3.
- **Multi-Token Prediction (MTP)** — V3 introduced an MTP training objective (and a drafter head) that also accelerates speculative decoding at inference.
- **DeepSeek Sparse Attention (DSA)** — introduced in V3.2-Exp / V3.2; a fine-grained, learned sparse attention (with a "Lightning Indexer") that slashes long-context compute and KV cost with negligible quality loss.
- **Hybrid CSA + HCA attention** (V4) — Compressed Sparse Attention and Heavily Compressed Attention combine a learned token-level compressor with a sliding-window local branch and sparse selection, enabling a 1M-token context at a fraction of V3.2's FLOPs/KV.
- **Manifold-Constrained Hyper-Connections (mHC)** (V4) — replaces residual connections with `hc_mult=4` parallel residual streams mixed via doubly-stochastic (Sinkhorn–Knopp) projection matrices, stabilizing signal propagation at trillion-parameter scale (Xie et al., 2026).
- **Muon optimizer** (V4) — replaces AdamW for most parameters (Newton-Schulz orthogonalization), giving faster convergence and stability during 32T+ token pre-training.
- **Hash-MoE bootstrap** (V4) — the first few MoE layers use a frozen token-id→expert-id hash table for warm-up routing stability.
- **Quantization-Aware Training** (V4) — MoE expert weights stored/served at FP4, all other params at FP8; base models FP8 throughout.

## Serving (vLLM / llama.cpp / Atlas)

- **vLLM**: Full support for the V3 family (FP8 and BF16, tensor + pipeline parallelism, expert-parallel "Wide-EP" serving, disaggregated prefill/decode) — see the vLLM team's large-scale DeepSeek serving write-up. **DeepSeek-V4 is supported in vLLM as of the 2026-04-24 release** (same-day), including FP4+FP8 quantized weights; the V4-Flash instruct model (~160 GB HF footprint, ~13B active) is the practical local tier.
- **llama.cpp / GGUF**: DeepSeek-V3 and V2.5 have community GGUF builds (e.g., `unsloth/DeepSeek-V3-GGUF`, `lmstudio-community/DeepSeek-V2.5-GGUF`); V4 GGUF/imatrix builds are emerging. Q4_K_M of DeepSeek-V3 (~671B) is roughly 400 GB; V4-Flash's 284B total at FP4/INT4 can fit on a single RTX 5090-class 32 GB card for inference thanks to 13B active + compressed weights, though 2-node clusters are recommended for full-throughput serving.
- **FP8 / NVFP4**: V3 ships native FP8 weights (BF16 conversion script provided). V4 ships FP4 (experts) + FP8 (rest) weights and serves efficiently on NVIDIA Blackwell (GB200) NVFP4 kernels per vLLM's 2026-02 deep-dive.
- **MTP**: V3/V4 MTP heads enable speculative decoding for higher throughput.
- **MoE note**: memory footprint is set by *total* params, compute by *active* params — e.g., V4-Flash loads 284B weights but only does ~13B/token of compute.
- **NOT yet runnable**: No hard blocker for V4 — same-day vLLM support landed; GGUF tooling for V4 is still maturing (use FP4/FP8 checkpoints directly or vLLM).

## References

- Official site: https://www.deepseek.com/ and https://chat.deepseek.com/
- API / news docs: https://api-docs.deepseek.com/news/
- DeepSeek-LLM (2023, arXiv 2401.02954): https://arxiv.org/abs/2401.02954
- DeepSeek-V2 (2024, arXiv 2405.04434): https://arxiv.org/abs/2405.04434
- DeepSeek-V3 Technical Report (2024, arXiv 2412.19437): https://arxiv.org/abs/2412.19437
- DeepSeek-R1 (2025, arXiv 2501.12948): https://arxiv.org/abs/2501.12948
- DeepSeek-V3.2-Exp / DSA (2025, arXiv 2512.02556): https://arxiv.org/abs/2512.02556
- DeepSeek-V4: Towards Highly Efficient Million-Token Context Intelligence (2026, arXiv 2606.19348): https://arxiv.org/html/2606.19348
- DeepSeek-V4 Hugging Face blog: https://huggingface.co/blog/deepseekv4
- Model hub (HF): https://huggingface.co/deepseek-ai and the V4 collection: https://huggingface.co/collections/deepseek-ai/deepseek-v4
- ModelScope mirror: https://modelscope.cn/models/deepseek-ai
- vLLM large-scale DeepSeek serving: https://blog.vllm.ai/2025/12/17/large-scale-serving.html
- vLLM V4 / NVFP4 on GB200: https://blog.vllm.ai/2026/02/03/v4-gb200.html

### Local-serving recipes
- vLLM recipe — DeepSeek-V4-Flash: https://recipes.vllm.ai/deepseek-ai/DeepSeek-V4-Flash
- vLLM recipe — DeepSeek-V3: https://recipes.vllm.ai/deepseek-ai/DeepSeek-V3
- Unsloth "Run DeepSeek-V4 locally" guide: https://unsloth.ai/docs/models/deepseek-v4
- Unsloth GGUF — DeepSeek-V4-Flash: https://huggingface.co/unsloth/DeepSeek-V4-Flash-GGUF

## Local Deployment in This Repo

This repo serves DeepSeek locally on edge/cluster hardware:

- **DeepSeek-V4-Flash (vLLM, 2-node DGX Spark cluster)**: [inference-containers/vllm/deepseek-v4-flash-dgx-spark-cluster](../vllm/deepseek-v4-flash-dgx-spark-cluster) — a head/worker multi-node setup running the 284B/13B MIT-licensed MoE at a 1M-token context, using FP4+FP8 weights via vLLM.

Other DeepSeek families (V3/V3.2/R1/V2.5) are straightforward to add here using the vLLM FP8/BF16 and llama.cpp GGUF paths documented above; the V4-Flash cluster is the reference frontier deployment.
