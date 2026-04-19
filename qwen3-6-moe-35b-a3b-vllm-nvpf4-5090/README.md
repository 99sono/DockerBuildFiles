# Qwen3.6-35B-A3B NVFP4 - RTX 5090 Optimized Setup

This configuration is specifically tuned for the **RTX 5090 (Blackwell SM 12.0)** and the **Qwen 3.6 Hybrid GDN/MoE** architecture.

## Model Highlights
- **Architecture:** Hybrid Gated DeltaNet (GDN) + Mixture of Experts (MoE).
- **Quantization:** NVFP4 (weights + activations) via Red Hat AI.
- **Context:** Native 256K support (Configured for 128K stable on single 5090).

## Why this configuration?
- **Triton MoE Backend:** As of April 2026, Triton is the only backend providing mathematically perfect outputs for NVFP4 on SM 12.0. (Avoids the 'Marlin' repetition bug).
- **GDN Hybrid Advantage:** Only ~25% of layers use full KV cache, making 128K context extremely light on VRAM.
- **V2 Model Runner:** Enabled via Environment Variable to unlock Blackwell-specific hardware acceleration.

## Scripts Overview

The setup is organized into numbered scripts to be run in sequence:

### 1. Environment & Model Setup
- **`00_a_pull_vllm_image.sh`**: Fetches the `vllm/vllm-openai:nightly` Docker image (optimized for Blackwell/SM 12.0).
- **`00_b_create_conda_env.sh`**: Creates a local Conda environment (`testVllmQwen`) for testing and model management.
- **`00_c_install_packages.sh`**: Installs necessary Python dependencies (`openai`, `rich`, `huggingface_hub`) into the Conda environment.
- **`00_d_pre_download_model.sh`**: Downloads the model weights directly to your global `~/.cache/huggingface` directory. This ensures the model is ready before the container starts and can be shared across other projects or VMs.

### 2. Orchestration
- **`01_up.sh`**: Launches the vLLM server in detached mode using Docker Compose.
- **`02_down.sh`**: Gracefully stops and removes the container.
- **`03_enter_container.sh`**: Opens an interactive bash shell inside the running container for debugging.

### 3. Testing
- **`04_test_vllm_curl.py`**: A Python client script to verify the API. It sends a sample prompt and saves the response to `test/test_output_01.md`.

## Recommended Workflow

1. **Prepare the Host Environment:**
   ```bash
   ./00_a_pull_vllm_image.sh
   ./00_b_create_conda_env.sh
   ./00_c_install_packages.sh
   ```

2. **Pre-download Model Weights:**
   ```bash
   ./00_d_pre_download_model.sh
   ```

3. **Start the Server:**
   ```bash
   ./01_up.sh
   # Monitor initialization with: docker logs -f qwen3-6-moe-35b-a3b-nvfp4
   ```

4. **Run a Test:**
   ```bash
   conda activate testVllmQwen
   python 04_test_vllm_curl.py
   ```

## Hardware Optimization Tip (Run on Host)
To prevent the 5090 from staying in low-power P-states during inference:
```bash
nvidia-smi -pm 1
nvidia-smi --lock-gpu-clocks=2500,2500
```

## API Access
- **Endpoint:** `http://localhost:8000/v1`
- **Swagger Docs:** `http://localhost:8000/docs`
- **Compatible Frontends:** Open WebUI, SillyTavern, Any OpenAI-Compatible SDK.

---
*Note on flashinfer_cutlass: If you update your vllm:nightly and want to test the absolute maximum speed (250+ tokens/sec), change triton to flashinfer_cutlass in the docker-compose.yml. If the model output looks like random letters, switch back to triton immediately.*
