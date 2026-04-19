# Gemma 4 26B-A4B - RTX 5090 High-Context Setup

This setup is optimized for the **RTX 5090 (32GB VRAM)** using the stable **vLLM v0.19.1+** engine. It represents the successful pivot from the "Blue Whale" (Qwen 3.6 35B) to the high-performance Gemma 4 architecture.

## The VRAM Recovery
After hitting a physical VRAM dead-end with Qwen 3.6, this project reclaimed its capabilities by switching to **Gemma 4 26B-A4B**.
- **Static Tax Reduced:** The weight footprint dropped from 22GB to ~13GB, reclaiming 9GB of VRAM.
- **Context Breakthrough:** This reduction allowed the context window to expand from an unusable 8K to a **stable 96K (98,304 tokens)** while maintaining a strict **80% VRAM utilization limit**.
- **Engine:** Powered by vLLM **v0.19.1+** for native Gemma 4 MoE support and stable Blackwell SM 12.0 kernel acceleration.

## Hardware Optimization
- **Native FP4:** Uses `NVFP4` weights + activations via Red Hat AI.
- **Blackwell Path:** Leveraging `flashinfer_cutlass` for maximum throughput on the 5090 (estimated 250+ tokens/sec).
- **Stability:** Strict 20% headroom (0.80 utilization) ensures the host OS and WSL2 remain responsive.

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
Verify the 96K context capacity and reasoning performance:
```bash
conda activate testVllmGemma
python 04_test_vllm_curl.py
```

## API Access
- **Endpoint:** `http://localhost:8000/v1`
- **Model Name:** `gemma-4-26b-it-nvfp4`
- **Reasoning:** Native `<thought>` block parsing enabled.
