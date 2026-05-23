# Qwen 3.6 27B Text NVFP4 MTP (RTX 5090 / Blackwell)

This project provides orchestration for the `sakamakismile/Qwen3.6-27B-Text-NVFP4-MTP` model using vLLM. It is specifically tuned for the **NVIDIA RTX 5090 (Blackwell)** hardware with **32GB VRAM**.

## 🚀 Key Features
- **NVFP4 Quantization:** Uses `modelopt` for high-performance Blackwell-native FP4.
- **MTP Speculative Decoding:** Built-in `qwen3_5_mtp` recursive speculative decoding (3 tokens) for significantly higher throughput.
- **Extreme Context:** Targetting 256K (Standard FP8) and up to 320K (TurboQuant).
- **WSL2 Stability:** Optimized with `expandable_segments` and `spawn` multiprocess method.

## 🛠️ Setup Sequence

1.  **Pull Image:** `./00_a_pull_vllm_image.sh`
2.  **Conda Env:** `./00_b_create_conda_env.sh` (Creates `testVllmQwen`)
3.  **Packages:** `./00_c_install_packages.sh`
4.  **Download Model:** `./00_d_pre_download_model.sh` (Pulls from sakamakismile/Qwen3.6-27B-Text-NVFP4-MTP)

## 🚦 Orchestration

- **Normal Start (128K Context):** `./01_a_up_normal.sh`
- **TurboQuant Start (256K Context):** `./01_b_up_turboquant.sh`
- **Logs:** `./05_docker_logs.sh`
- **Test:** `./04_test_vllm_curl.py`

## ⚠️ Known Parameters
- **Quantization:** `modelopt`
- **Speculative Config:** `{"method":"qwen3_5_mtp","num_speculative_tokens":3}`
- **Reasoning Parser:** `qwen3`
- **KV Cache DType:** `fp8` (Normal) or `turboquant_k8v4` (Turbo)
