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
> **CURRENTLY BROKEN:** This configuration is currently non-functional for Gemma-4 due to a critical incompatibility between the **NVFP4 quantization** and the **Triton backend**. 
> 
> **The Problem:** The `vLLM` implementation for `NVFP4` (required for the Gemma-4-26B-A4B-it-NVFP4 model) does not support the `triton` based MoE backend because the specific kernels required for handling **GELU** activation in the NVFP4 path are not yet available in the `triton` backend.
> 
> **The Fix:** To avoid errors, use a supported backend such as `cutlass` or `marlin`.
> 
> See detailed analysis in the metadata.
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
- `./01_a_up_normal.sh`: Starts the baseline (64K) configuration.
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

## Monitoring & Optimization

When running the vLLM server, monitor the following log patterns to ensure optimal performance and to avoid "undertuning" your configuration:

### 1. KV Cache & Context Window
To ensure you are not hitting the limits of your configured context window, watch these metrics:
* **`GPU KV cache usage`**: A high percentage (e.s. >90%) indicates you are nearing the limit of your allocated-memory for the context window.
* **`Available KV cache memory`**: If this value becomes very low or negative, you may need to increase `gpu_memory_utilization` or reduce `max_model_len`.
* **`Prefix cache hit rate`**: A high hit rate (e.g., >80%) confirms that your prefix caching is working efficiently and saving computation.

**Example log entry for these metrics:**
`2026-04-19 18:00:49 [loggers.py:271] Engine 000: Avg prompt throughput: 384.9 tokens/s, Avg generation throughput: 104.7 tokens/s, Running: 1 reqs, Waiting: 0 reqs, GPU KV cache usage: 5.0%, Prefix cache hit rate: 87.8%`

### 2. Advanced Memory Profiling
If you want more accurate memory accounting, use the following environment variable:
`VLLM_MEMORY_PROFILER_ESTIMATE_CUDAGRAPHS=1`

**Note:** When enabling this, you should increase your `--gpu-memory-utilization` (e.g., from `0.85` to `0.86`) to maintain the same effective KV cache size, as the profiling accounts for additional memory used by CUDA graphs.

### 3. Troubleshooting
* **`Out of Memory (OOM)`**: If you see CUDA OOM errors, your `max_model_len` is too large for your available VRAM or your `gpu_memory_utilization` is too low to accommodate the model weights and the requested context.
* **`pin_memory=False`**: If you see this warning, it is often due to running in a WSL2 environment, which may slightly impact performance.
