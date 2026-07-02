# Qwen3.6-27B-NVFP4 Inference Configuration

This directory contains the configuration and scripts for deploying the **NVIDIA Qwen3.6-27B-NVFP4** model on a **DGX Spark** (Blackwell GB10, ARM64, 128GB unified memory) using **vLLM**.

## Model Description
The Qwen3.6-27B-NVFP4 is a dense model (27B parameters) using NVIDIA's NVFP4 quantization for optimized inference on Blackwell architecture. It features Hybrid Attention (Gated DeltaNet + Gated Attention) and supports multimodal inputs (text, image, video).

- **Model ID:** `nvidia/Qwen3.6-27B-NVFP4`
- **Base Model:** Qwen/Qwen3.6-27B
- **License:** Apache 2.0
- **Model Card:** [Link to HuggingFace Model Card](https://huggingface.co/nvidia/Qwen3.6-27B-NVFP4)

## Key Configuration Details
- **Quantization:** `modelopt`
- **Max Model Length:** 262,144
- **KV Cache Dtype:** `fp8`
- **Memory Utilization:** 0.70
- **Batching:**
    - `max-num-seqs`: 8
    - `max-num-batched-tokens`: 65,536
- **Parsers:**
    - Reasoning: `qwen3`
    - Tool Call: `qwen3_coder`

## MTP Speculative Decoding

MTP (Multi-Token Prediction) is part of the Qwen3.6 architecture and is quantization-agnostic — it works with FP8, BF16, and NVFP4 checkpoints alike. This config enables it via `--speculative-config '{"method":"mtp","num_speculative_tokens":1}'`. Expect ~1.5–1.9× decode speedup on Blackwell.

## Known Trade-off: Marlin vs Native FP4

The DGX Spark (Blackwell GB10) **does** have native FP4 tensor cores, but vLLM reports:

```
Your GPU does not have native support for FP4 computation but FP4 quantization is being used.
Weight-only FP4 compression will be used leveraging the Marlin kernel.
```

This warning is **misleading** — the hardware absolutely supports FP4. The issue is that vLLM's GPU detection checks against a hardcoded SM whitelist which doesn't yet include consumer Blackwell SKUs (GB10, SM 121a). The Marlin backend dequantizes NVFP4 weights to BF16 on-the-fly rather than feeding them directly into FP4 tensor cores.

NVIDIA themselves recommend this path for stability on GB10. The performance impact is minimal on a dense 27B model with abundant memory bandwidth (128GB UMA at ~273 GB/s). Once vLLM upstream updates their SM whitelist, the warning will disappear without any config changes.

If native FP4 paths are desired, swap `--moe-backend` to `flashinfer_cutlass` or `flashinfer_trtllm` — test with small workloads first, as GB10 + FlashInfer FP4 has shown instability.

## Scripts Reference
| Script | Description |
| --- | --- |
| `00_a_pull_vllm_image.sh` | Pulls the vLLM nightly Docker image |
| `00_b_pre_download_model.sh` | Pre-downloads the model weights to the global cache |
| `00_e_force_download_model.sh` | Force-downloads the model weights to the global cache |
| `01_up.sh` | Starts the inference server |
| `02_down.sh` | Stops the inference server |
| `03_enter_container.sh` | Enters the running inference container |
| `05_a_follow_logs.sh` | Follows the container logs |
| `05_b_dump_logs.sh` | Dumps the container logs to a file with a timestamp |

## Usage
1. Copy `.env.example` to `.env` and update values.
2. Run `./00_a_pull_vllm_image.sh`.
3. Run `./00_b_pre_download_model.sh`.
4. Run `./01_up.sh`.
