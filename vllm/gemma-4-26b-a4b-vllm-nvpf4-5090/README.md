# Gemma 4 26B-A4B - RTX 5090 High-Context Setup

This setup is optimized for the **RTX 5090 (32GB VRAM)** using the stable **vLLM v0.19.0+** engine. It focuses on maximizing context window capacity by leveraging the efficiency of the Gemma 4 26B MoE architecture.

## The VRAM Recovery Strategy
- **The Problem:** 35B models (like Qwen 3.6) at NVFP4 quantization consume ~25.7GB of "static tax" (weights + kernels), leaving almost zero room for context at an 80% utilization limit.
- **The Recovery:** By switching to the **Gemma-4-26B** class, we reduce the 'Static Tax' by approximately **9GB**. 
- **The Result:** This reclaimed VRAM allows us to support a massive **96K context window (98,304 tokens)** while strictly respecting the "Line in the Sand" (80% utilization), leaving 20% (6.4GB) free for the host OS and WSL2.

## Stable Engine: vLLM v0.19.0
We have moved away from `nightly` builds to the stable `latest` release. This version includes:
- **Native Gemma 4 Support:** Expert-routing and `p-RoPE` optimizations.
- **Blackwell Stability:** Stable kernels for SM 12.0 (RTX 5090).
- **Predictable Memory:** Improved buffer management compared to experimental builds.

## Quick Start
1. **Prepare Host Environment:**
   ```bash
   chmod +x *.sh
   ./00_a_pull_vllm_image.sh
   ./00_b_create_conda_env.sh
   ./00_c_install_packages.sh
   ```
2. **Pre-download Model:**
   ```bash
   ./00_d_pre_download_model.sh
   ```
3. **Launch Server:**
   ```bash
   ./01_up.sh
   ```

## Testing
Verify the 96K context capacity and response quality:
```bash
conda activate testVllmGemma
python 04_test_vllm_curl.py
```

## API Access
- **Endpoint:** `http://localhost:8000/v1`
- **Model Name:** `gemma-4-26b-it-nvfp4`
