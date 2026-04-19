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

## Quick Start
1. Ensure you have NVIDIA Driver **581.57+** and WSL **2.7.0+**.
2. Run the following:
```bash
chmod +x *.sh
./00_a_pull_vllm_image.sh
./01_up.sh
```

## Testing
A Conda-based test environment is provided to verify the model output:
1. `./00_b_create_conda_env.sh`
2. `./00_c_install_packages.sh`
3. `conda activate testVllmQwen`
4. `python 04_test_vllm_curl.py`

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
