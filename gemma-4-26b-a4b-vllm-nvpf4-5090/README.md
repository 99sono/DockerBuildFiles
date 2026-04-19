# Gemma-4-26B NVFP4 - VRAM Recovery Setup (RTX 5090)

This setup represents a strategic shift from the 35B parameter "Blue Whale" models to a more balanced 26B architecture. By optimizing the parameter footprint, we reclaim over 5GB of VRAM, allowing for a massive context window within a stable 80% VRAM budget.

## The Strategy: "VRAM Recovery"
- **The Problem:** 35B models (like Qwen 3.6) at NVFP4 quantization consume ~25.7GB of "static tax" (weights + kernels), leaving almost zero room for context at an 80% utilization limit.
- **The Solution:** By moving to the **Gemma-4-26B** class, the static footprint drops to ~17GB. This "reclaimed" 8GB is converted entirely into KV cache.
- **The Result:** We achieve a full **128K context window** while strictly respecting the "Line in the Sand" (80% utilization), leaving 20% (6.4GB) free for the host OS and WSL2.

## Hardware Optimization: Blackwell SM 12.0
- **Native FP4 Execution:** This setup uses the `NVFP4` weights + activations via Red Hat AI's optimized checkpoint.
- **FlashInfer/CUTLASS Path:** We leverage `--moe-backend flashinfer_cutlass`, which is the high-speed path designed specifically for Blackwell Tensor Cores. Expect performance in the 250+ tokens/sec range.

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
Verify the 128K context capacity and response quality:
```bash
conda activate testVllmGemma
python 04_test_vllm_curl.py
```

## API Access
- **Endpoint:** `http://localhost:8000/v1`
- **Model Name:** `gemma-4-26b-it-nvfp4`
