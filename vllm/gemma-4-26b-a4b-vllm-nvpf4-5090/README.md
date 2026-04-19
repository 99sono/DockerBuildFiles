# Gemma 4 26B-A4B - RTX 5090 High-Context Setup

This setup is optimized for the **RTX 5090 (32GB VRAM)** using **vLLM nightly**. It features two distinct configurations: a baseline high-quality setup and an experimental TurboQuant setup for extreme context windows.

## Configurations

### 1. Normal (Baseline)
- **KV Cache:** `fp8_e4m3` (Standard FP8 for high quality).
- **Context Window:** 96K tokens.
- **Utilization:** 0.92 (Strict ~2.5GB headroom for OS).
- **Use case:** Default daily usage where quality and stability are paramount.

### 2. TurboQuant (Experimental)
> [!CAUTION]
> **CURRENTLY BROKEN:** This configuration is currently non-functional for Gemma-4 due to a known vLLM issue where the forced Triton attention backend (required for Gemma-4's heterogeneous head dimensions) does not yet support the TurboQuant KV cache data type. 
> See tracked issue: [vLLM #40094](https://github.com/vllm-project/vllm/issues/40094)

- **KV Cache:** `turboquant_k8v4` (FP8 keys + 4-bit values).
- **Compression:** Expected 2.5–4× KV cache savings.
- **Context Window:** **~200K tokens** (196,608).
- **Use case:** Research and long-context processing (Needle-in-a-Haystack, deep reasoning).
- **Warning:** TurboQuant is experimental in nightly builds. Monitor logs for errors related to Gemma-4's heterogeneous head dimensions.

### 3. Inference Optimization & Speculative Decoding
**Note:** Speculative decoding has been **disabled** in the production configuration.

#### Speculative Decoding Experiment
We attempted to use the `RedHatAI/gemma-4-26B-speculator-eagle-3` (0.9B) draft model to accelerate the `Gemma-4-26B-A4B` (NVFP4) base model. However, the experiment yielded the following results:

* **Acceptance Rate:** The experiment showed a near-zero acceptance rate (**0.1% – 1.4%**), meaning the draft model failed to predict the base model's tokens effectively.
* **Task Incompatibility:** The speculator struggled specifically with the complex syntax of **git diffs and code generation**, leading to a "Mean Acceptance Length" of ~1.00.
* **Quantization Drift:** There appears to be a logical mismatch between the 4-bit NVFP4 base weights and the speculator's predictions, resulting in constant rejections.

#### Decision & Architecture
* **Reasoning:** The decision to disable speculative decoding was driven by data from the vLLM metrics logs.
* **VRAM & Context:** By removing the speculator, we eliminated verification overhead and reclaimed VRAM to prioritize a more stable **64k context window**.
* **Performance:** Standard generation via the **Triton/Cutlass** backends proved more performant and reliable for coding workflows.

## Usage Scripts

Run the scripts in sequence for setup and orchestration:

### Environment Setup
- `./00_a_pull_vllm_image.sh`: Fetches the `vllm-openai:nightly` image.
- `./00_b_create_conda_env.sh`: Creates the `testVllmGemma` Conda environment.
- `./00_c_install_packages.sh`: Installs Python dependencies.
- `./00_d_pre_download_model.sh`: Downloads weights to global cache.

### Server Orchestration
- `./01_a_up_normal.sh`: Starts the baseline (96K) configuration.
- `./01_b_up_turboquant.sh`: Starts the TurboQuant (~200K) configuration.
- `./01_c_up_eagle3.sh`: Starts the EAGLE-3 speculative decoding configuration.
- `./02_a_down_normal.sh`: Stops the normal server.
- `./02_b_down_turboquant.sh`: Stops the TurboQuant server.
- `./02_c_down_eagle3.sh`: Stops the EAGLE-3 server.
- `./05_docker_logs.sh`: Monitor the active container's logs.

### Testing
- `./04_test_vllm_curl.py`: Python client for API verification.

## Recommendations
1. **Load Normal First:** Ensure the model loads and functions correctly with the normal configuration before trying TurboQuant.
2. **Quality Monitoring:** In TurboQuant mode, pay close attention to output quality on very long sequences, as 4-bit value quantization may introduce artifacts.
3. **VRAM Audit:** Compare VRAM usage and throughput (tokens/sec) between the 96K and 200K setups.
