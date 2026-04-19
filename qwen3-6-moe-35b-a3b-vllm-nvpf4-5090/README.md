# ⚠️ Warning: Hardware Limitation (Technical Dead-End)

The **Qwen3.6-35B-A3B NVFP4** model is a "Blue Whale" for consumer-grade hardware. Despite the power of the RTX 5090 (32GB VRAM), this specific implementation has reached a technical dead-end under standard stability constraints.

## Technical Post-Mortem: The "Static Tax"

Extensive testing on an RTX 5090 (32GB) revealed that the model's **Static Tax** (Weights + Blackwell Kernels + Activation Buffers) is approximately **25.72 GB**. 

- **The 80% Utilization Wall:** If a strict 80% utilization limit (25.6 GB) is enforced to preserve system stability and OS headroom, the model physically cannot boot.
- **The Failure of the "Absolute Floor":** Even when stripping the configuration to the bare minimum—**8K context** and only **32 parallel sequences**—the engine reported **-0.12 GiB available KV cache memory**.
- **The Verdict:** On a 32GB card, this model is unusable for local agentic workflows unless the user is willing to push utilization to **95%+**, leaving zero VRAM headroom for the OS, WSL2, or display.

## Comparison: Qwen vs. Nemotron-Cascade-2

For local development on a single 32GB card, architecture currently beats raw parameter count when context window is the priority:

| Metric | Qwen 3.6-35B-A3B | Nemotron-Cascade-2 |
| :--- | :--- | :--- |
| **VRAM Footprint (Weights)** | ~22 GB (NVFP4) | ~14 GB (Stage 1 distillation) |
| **Context Limit (on 32GB)** | **~8K - 16K** (at 90%+ util) | **100K+** (at 75% util) |
| **Status on 5090** | **Dead End** for Agents | **Recommended** for Agents |

## Scripts Overview (Archival/Debug Only)

The following scripts remain for archival and debugging purposes, but they will likely fail on a single 32GB card under default settings.

### 1. Environment & Model Setup
- **`00_a_pull_vllm_image.sh`**: Fetches the `vllm/vllm-openai:nightly` Docker image.
- **`00_b_create_conda_env.sh`**: Creates the `testVllmQwen` Conda environment.
- **`00_c_install_packages.sh`**: Installs Python dependencies.
- **`00_d_pre_download_model.sh`**: Downloads model weights to global cache.

### 2. Orchestration
- **`01_up.sh`**: Launches the server (Warning: High OOM risk).
- **`02_down.sh`**: Stops the container.
- **`03_enter_container.sh`**: Interactive shell access.

### 3. Testing & Logs
- **`04_test_vllm_curl.py`**: Python client for API verification.
- **`05_docker_logs.sh`**: Monitor the initialization failure logs.

## Hardware Optimization Tip (Host)
To prevent the 5090 from staying in low-power P-states:
```bash
nvidia-smi -pm 1
nvidia-smi --lock-gpu-clocks=2500,2500
```
