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
- **Memory Utilization:** 0.85
- **Batching:**
    - `max-num-seqs`: 8
    - `max-num-batched-tokens`: 65,536
- **Parsers:**
    - Reasoning: `qwen3`
    - Tool Call: `qwen3_coder`

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
