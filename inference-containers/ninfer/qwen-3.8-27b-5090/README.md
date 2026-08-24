# Qwen3.8-27B Server on RTX 5090 (NInfer Turbo)

> NVFP4 Quantized • MTP-3 speculative decoding • Blackwell SM 12.0 • OpenAI-compatible API

**Target Hardware:** RTX 5090 (32 GB GDDR7, SM 12.0, x86_64)  
**Engine:** [NInfer](https://github.com/Neroued/ninfer) (C++/CUDA inference engine for RTX 5090)  
**Model:** [`neroued/Qwen3.8-27B-nvfp4-NInfer`](https://huggingface.co/neroued/Qwen3.8-27B-nvfp4-NInfer) (`qwen3_8_27b_nvfp4.ninfer`, 20.02 GiB)  
**Speculative Decoding:** MTP-3 (`--spec mtp --draft-tokens 3`)  
**KV Cache:** INT8 group-64 (`--kv-dtype int8`)  
**Server Port:** `8000`

---

## Benchmark Analysis & Validation

This setup was built to test and validate the claim made by Marshall Gould on X regarding running Qwen 3.8-27B (NVFP4) on a single RTX 5090 with MTP-3 speculative decoding and thinking mode.

### Single-Stream Serving (`Concurrency = 1`)
- **Decode Throughput:** **151.5 tok/s**
- **Prefill Throughput:** **502.8 tok/s**
- **Time To First Token (TTFT):** **319 ms**
- **MTP-3 Speculative Draft Acceptance:** **59.3%** (~2.78 tokens per round)
- **Model Load Time:** **6.89 s** into VRAM

### Concurrent Saturated Serving (`Concurrency = 8`)
- **Tested Workload:** 8 simultaneous reasoning streams generating 1,500 tokens each (12,000 tokens total)
- **Observed Peak Interval Decode Throughput:** **687.8 tokens/second**
- **Sustained Aggregate Decode Throughput:** **630.4 – 687.8 tokens/second**
- **Conclusion:** The claimed ~580–600 aggregate tokens/sec on an RTX 5090 holds up and is fully verified locally on WSL2 Docker with Blackwell NVFP4 kernels + MTP-3.

---

## Credits & Acknowledgements

- **NInfer Engine:** [https://github.com/Neroued/ninfer](https://github.com/Neroued/ninfer) by Neroued — from-scratch C++/CUDA inference engine optimized for single-GPU RTX 5090.
- **Model Checkpoints:** [neroued/Qwen3.8-27B-nvfp4-NInfer](https://huggingface.co/neroued/Qwen3.8-27B-nvfp4-NInfer)

---

## Quick Start

```bash
# 1. Build the NInfer Docker image
./00_a_build_image.sh

# 2. Create host-side conda env & tools
./00_b_create_conda_env.sh
./00_c_install_packages.sh

# 3. Pre-download the NInfer artifact into ./nvfp4/models/ (~20.02 GB)
cd nvfp4 && ./00_d_pre_download_model.sh

# 4. Start the server
cd nvfp4 && ./01_up.sh

# 5. Test single-stream prompt
./04_test_curl.sh

# 6. Test 8-stream concurrency benchmark
python3 test/bench_concurrency.py
```

---

## Scripts

```
qwen-3.8-27b-5090/
├── 00_a_build_image.sh             # Build ninfer:latest Docker image
├── 00_b_create_conda_env.sh        # Create testNInferQwen conda env
├── 00_c_install_packages.sh        # Install huggingface-hub, openai, python-dotenv
├── 04_test_curl.sh                 # Test API call on port 8000
├── .env.example                    # Environment template
├── README.md                       # Full documentation & benchmark analysis
├── test/
│   ├── bench_concurrency.py        # 8-stream concurrency benchmark
│   ├── test_file_01_prompt.md      # Test reasoning prompt
│   └── test_output_01.md           # Model generated response
└── nvfp4/
    ├── 00_d_pre_download_model.sh  # Pre-download NInfer artifact (skip if cached)
    ├── 00_e_force_download_model.sh# Force re-download artifact
    ├── 01_up.sh                    # Start server (docker compose up -d)
    ├── 02_down.sh                  # Stop server
    ├── 03_enter_container.sh       # Bash into running container
    ├── 05_a_follow_logs.sh         # Live tail of logs
    ├── 05_b_dump_logs.sh           # Dump container logs
    ├── 06_dump_help.sh             # Dump ninfer-serve CLI options
    └── docker-compose.yml          # NInfer server compose recipe with MTP-3
```
