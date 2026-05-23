# docker compsoe
```yml
services:
  qwopus-35b-mtp-server:
    # Official multi-arch image with CUDA 13 support for ARM64 / aarch64.
    image: ghcr.io/ggml-org/llama.cpp:server-cuda13
    container_name: qwopus36-35b-mtp-dgx-spark
    hostname: inference-server
    platform: linux/arm64
    # All models served on port 8000. Single-model capacity avoids client port mismatches.
    ports:
      - "${INFERENCE_SERVER_PORT:-8000}:8000"

    volumes:
      # Central workstation cache to avoid redundant downloads.
      - ~/.cache/huggingface:/root/.cache/huggingface
      # Shared memory for high-speed KV cache paging.
      - /dev/shm:/dev/shm

    # 70GB shm_size for GB10 unified memory architecture.
    shm_size: "70g"
    ipc: host

    deploy:
      resources:
        reservations:
          devices:
            - driver: nvidia
              count: 1
              capabilities: [gpu]

    environment:
      - CUDA_VISIBLE_DEVICES=0
      - NVIDIA_VISIBLE_DEVICES=0
      - HF_HOME=/root/.cache/huggingface
    command:
      # Loads directly from central cache via the -hf flag.
      - "-hf"
      # Model: Qwopus3.6-35B-A3B-v1 MTP quantization (Q4_K_M) by Jackrong.
      - "Jackrong/Qwopus3.6-35B-A3B-v1-MTP-GGUF:Qwopus3.6-35B-A3B-v1-MTP-Q4_K_M"
      # Aliased name presented in /v1/models API response.
      - "--alias"
      - "${INFERENCE_MODEL_ALIAS:-qwen3.6-35b}"
      # API key authentication (Bearer token on all routes).
      - "--api-key"
      - "${INFERENCE_API_KEY:-dummy-key}"
      # Bind to all interfaces for network access.
      - "--host"
      - "0.0.0.0"
      # Internal container port.
      - "--port"
      - "${INFERENCE_SERVER_PORT:-8000}"
      # Load the full graph into the unified memory pool.
      - "--n-gpu-layers"
      - "999"
      # Native FlashAttention-2 acceleration for deep context layers.
      - "--flash-attn"
      - "on"
      # Q8_0 KV-cache: High precision (8-bit) to avoid "doom loop" logic errors.
      - "--cache-type-k"
      - "q8_0"
      - "--cache-type-v"
      - "q8_0"
      # 180k context window (model trained on 256k; 180k is a good balance for long-context tasks).
      - "--ctx-size"
      - "184320"
      # --- BATCH OPTIMIZATION ---
      # Calibrated for high-bandwidth LPDDR5X unified controllers.
      - "--batch-size"
      - "512"
      - "--ubatch-size"
      - "512"
      # --- SPECULATIVE DECODING (MTP) ---
      # Standardized upstream syntax for Multi-Token Prediction models.
      - "--spec-type"
      - "draft-mtp"
      # Aggressive: 3 draft tokens with moderate confidence threshold.
      # Benchmarked at n_max=2 / p_min=0.85 with 90-93% acceptance — safe to push harder.
      - "--spec-draft-n-max"
      - "3"
      # Lowered from 0.85 to 0.75: the MTP heads are confident enough, and we want to accept more speculative tokens.
      - "--spec-draft-p-min"
      - "0.75"
      # --- SAMPLING ---
      - "--temp"
      - "1.0"
      - "--top-p"
      - "0.95"
      - "--top-k"
      - "20"
      # Slightly higher penalty to keep the model focused during long code generations.
      - "--presence-penalty"
      - "1.5"

    networks:
      - development-network

networks:
  # Allows this server to communicate with other internal tools/proxies.
  development-network:
    external: true

```

# llamacpp log

```
warn: LLAMA_ARG_HOST environment variable is set, but will be overwritten by command line argument --host
0.00.829.473 I log_info: verbosity = 3 (adjust with the `-lv N` CLI arg)
0.00.829.480 I device_info:
0.00.829.666 I   - CUDA0   : NVIDIA GB10 (122500 MiB, 117824 MiB free)
0.00.829.674 I   - CPU     : CPU (122500 MiB, 122500 MiB free)
0.00.829.740 I system_info: n_threads = 20 (n_threads_batch = 20) / 20 | CUDA : ARCHS = 750,800,860,890,900,1200,1210 | USE_GRAPHS = 1 | PEER_MAX_BATCH_SIZE = 128 | BLACKWELL_NATIVE_FP4 = 1 | CPU : NEON = 1 | ARM_FMA = 1 | FP16_VA = 1 | MATMUL_INT8 = 1 | SVE = 1 | DOTPROD = 1 | SVE_CNT = 16 | OPENMP = 1 | REPACK = 1 |
0.00.829.744 I srv  llama_server: n_parallel is set to auto, using n_parallel = 4 and kv_unified = true
0.00.829.772 I srv          init: running without SSL
0.00.829.789 I srv          init: api_keys: ****eiro
0.00.829.800 I srv          init: using 19 threads for HTTP server
0.00.829.886 I srv         start: binding port with default address family
0.00.831.007 I srv  llama_server: loading model
0.00.831.014 I srv    load_model: loading model '/root/.cache/huggingface/hub/models--Jackrong--Qwopus3.6-35B-A3B-v1-MTP-GGUF/snapshots/619faa66e85a83f8c73fa24f0f8d819a57597951/Qwopus3.6-35B-A3B-v1-MTP-Q4_K_M.gguf'
0.00.831.038 I common_init_result: fitting params to device memory ...
0.00.831.038 I common_init_result: (for bugs during this step try to reproduce them with -fit off, or provide --verbose logs if the bug only occurs with -fit on)
0.05.433.319 W llama_context: n_ctx_seq (184320) < n_ctx_train (262144) -- the full capacity of the model will not be utilized
0.05.679.461 I common_init_from_params: warming up the model with an empty run - please wait ... (--no-warmup to disable)
0.06.128.767 I srv    load_model: creating MTP draft context against the target model '/root/.cache/huggingface/hub/models--Jackrong--Qwopus3.6-35B-A3B-v1-MTP-GGUF/snapshots/619faa66e85a83f8c73fa24f0f8d819a57597951/Qwopus3.6-35B-A3B-v1-MTP-Q4_K_M.gguf'
0.06.128.803 W llama_context: n_ctx_seq (184320) < n_ctx_train (262144) -- the full capacity of the model will not be utilized
0.06.325.920 I srv    load_model: initializing slots, n_slots = 4
0.06.358.838 I common_context_can_seq_rm: the context supports bounded partial sequence removal
0.06.560.609 I common_speculative_impl_draft_mtp: adding speculative implementation 'draft-mtp'
0.06.560.615 I common_speculative_impl_draft_mtp: - n_max=3, n_min=0, p_min=0.75, n_embd=2048, backend_sampling=1
0.06.560.617 I common_speculative_impl_draft_mtp: - gpu_layers=-1, cache_k=f16, cache_v=f16, ctx_tgt=yes, ctx_dft=yes, devices=[default]
0.06.560.788 I srv    load_model: speculative decoding context initialized
0.06.560.788 I slot   load_model: id  0 | task -1 | new slot, n_ctx = 184320
0.06.560.791 I slot   load_model: id  1 | task -1 | new slot, n_ctx = 184320
0.06.560.791 I slot   load_model: id  2 | task -1 | new slot, n_ctx = 184320
0.06.560.792 I slot   load_model: id  3 | task -1 | new slot, n_ctx = 184320
0.06.560.857 I srv    load_model: prompt cache is enabled, size limit: 8192 MiB
0.06.560.857 I srv    load_model: use `--cache-ram 0` to disable the prompt cache
0.06.560.857 I srv    load_model: for more info see https://github.com/ggml-org/llama.cpp/pull/16391
0.06.560.868 I srv          init: idle slots will be saved to prompt cache and cleared upon starting a new task
0.06.570.533 I init: chat template, example_format: '<|im_start|>system
You are a helpful assistant<|im_end|>
<|im_start|>user
Hello<|im_end|>
<|im_start|>assistant
Hi there<|im_end|>
<|im_start|>user
How are you?<|im_end|>
<|im_start|>assistant
<think>
'
0.06.577.604 I srv          init: init: chat template, thinking = 1
0.06.577.629 I srv  llama_server: model loaded
0.06.577.632 I srv  llama_server: server is listening on http://0.0.0.0:8000
0.06.577.636 I srv  update_slots: all slots are idle
1.28.053.512 I srv  params_from_: Chat format: peg-native
1.28.056.503 I slot get_availabl: id  3 | task -1 | selected slot by LRU, t_last = -1
1.28.056.507 I srv  get_availabl: updating prompt cache
1.28.056.512 I srv          load:  - looking for better prompt, base f_keep = -1.000, sim = 0.000
1.28.056.515 I srv        update:  - cache state: 0 prompts, 0.000 MiB (limits: 8192.000 MiB, 184320 tokens, 8589934592 est)
1.28.056.516 I srv  get_availabl: prompt cache update took 0.01 ms
1.28.057.100 I reasoning-budget: activated, budget=2147483647 tokens
1.28.057.117 I slot launch_slot_: id  3 | task 0 | processing task, is_child = 0
1.30.511.039 I slot create_check: id  3 | task 0 | created context checkpoint 1 of 32 (pos_min = 4170, pos_max = 4170, n_tokens = 4171, size = 67.221 MiB)
1.30.785.276 I slot create_check: id  3 | task 0 | created context checkpoint 2 of 32 (pos_min = 4678, pos_max = 4678, n_tokens = 4679, size = 67.757 MiB)
1.31.232.918 I reasoning-budget: deactivated (natural end)
1.32.006.044 I slot print_timing: id  3 | task 0 | n_decoded =    100, tg =  84.56 t/s
1.33.019.318 I slot print_timing: id  3 | task 0 | prompt eval time =    2766.16 ms /  4683 tokens (    0.59 ms per token,  1692.96 tokens per second)
1.33.019.321 I slot print_timing: id  3 | task 0 |        eval time =    2195.86 ms /   195 tokens (   11.26 ms per token,    88.80 tokens per second)
1.33.019.322 I slot print_timing: id  3 | task 0 |       total time =    4962.02 ms /  4878 tokens
1.33.019.326 I slot print_timing: id  3 | task 0 |    graphs reused =         28
1.33.019.327 I slot print_timing: id  3 | task 0 | draft acceptance = 0.94483 (  137 accepted /   145 generated)
1.33.019.346 I statistics        draft-mtp: #calls(b,g,a) =    1     58     56, #gen drafts =     56, #acc drafts =    55, #gen tokens =    145, #acc tokens =   137, dur(b,g,a) = 0.003, 420.200, 0.019 ms
1.33.019.527 I slot      release: id  3 | task 0 | stop processing: n_tokens = 4878, truncated = 0
1.33.019.533 I srv  update_slots: all slots are idle
1.33.112.454 I srv  params_from_: Chat format: peg-native
1.33.115.531 I slot get_availabl: id  3 | task -1 | selected slot by LCP similarity, sim_best = 0.249 (> 0.100 thold), f_keep = 1.000
1.33.116.055 I reasoning-budget: activated, budget=2147483647 tokens
1.33.116.468 I slot launch_slot_: id  3 | task 70 | processing task, is_child = 0
1.33.116.505 W slot update_slots: id  3 | task 70 | n_past = 4878, slot.prompt.tokens.size() = 4878, seq_id = 3, pos_min = 4877, n_swa = 0
1.33.116.505 I slot update_slots: id  3 | task 70 | Checking checkpoint with [4678, 4678] against 4877...
1.33.119.362 W slot update_slots: id  3 | task 70 | restored context checkpoint (pos_min = 4678, pos_max = 4678, n_tokens = 4679, n_past = 4679, size = 67.757 MiB)
1.36.294.484 I slot print_timing: id  3 | task 70 | prompt processing, n_tokens =   6144, progress = 0.55, t =   3.18 s / 1933.31 tokens per second
1.36.568.975 I slot print_timing: id  3 | task 70 | prompt processing, n_tokens =   6656, progress = 0.58, t =   3.45 s / 1927.89 tokens per second
1.36.844.907 I slot print_timing: id  3 | task 70 | prompt processing, n_tokens =   7168, progress = 0.60, t =   3.73 s / 1922.54 tokens per second
1.37.119.211 I slot print_timing: id  3 | task 70 | prompt processing, n_tokens =   7680, progress = 0.63, t =   4.00 s / 1918.70 tokens per second
1.37.389.173 I slot print_timing: id  3 | task 70 | prompt processing, n_tokens =   8192, progress = 0.66, t =   4.27 s / 1917.30 tokens per second
1.37.389.369 I slot update_slots: id  3 | task 70 | 8192 tokens since last checkpoint at 4679, creating new checkpoint during processing at position 13383
1.37.414.330 I slot create_check: id  3 | task 70 | created context checkpoint 3 of 32 (pos_min = 12870, pos_max = 12870, n_tokens = 12871, size = 76.414 MiB)
1.37.682.633 I slot print_timing: id  3 | task 70 | prompt processing, n_tokens =   8704, progress = 0.68, t =   4.57 s / 1906.21 tokens per second
1.37.956.358 I slot print_timing: id  3 | task 70 | prompt processing, n_tokens =   9216, progress = 0.71, t =   4.84 s / 1904.19 tokens per second
1.38.235.476 I slot print_timing: id  3 | task 70 | prompt processing, n_tokens =   9728, progress = 0.74, t =   5.12 s / 1900.38 tokens per second
1.38.513.983 I slot print_timing: id  3 | task 70 | prompt processing, n_tokens =  10240, progress = 0.76, t =   5.40 s / 1897.18 tokens per second
1.38.795.407 I slot print_timing: id  3 | task 70 | prompt processing, n_tokens =  10752, progress = 0.79, t =   5.68 s / 1893.32 tokens per second
1.39.080.042 I slot print_timing: id  3 | task 70 | prompt processing, n_tokens =  11264, progress = 0.81, t =   5.96 s / 1888.82 tokens per second
1.39.363.132 I slot print_timing: id  3 | task 70 | prompt processing, n_tokens =  11776, progress = 0.84, t =   6.25 s / 1885.18 tokens per second
1.39.642.389 I slot print_timing: id  3 | task 70 | prompt processing, n_tokens =  12288, progress = 0.87, t =   6.53 s / 1882.97 tokens per second
1.39.929.604 I slot print_timing: id  3 | task 70 | prompt processing, n_tokens =  12800, progress = 0.89, t =   6.81 s / 1878.73 tokens per second
1.40.205.083 I slot print_timing: id  3 | task 70 | prompt processing, n_tokens =  13312, progress = 0.92, t =   7.09 s / 1877.95 tokens per second
1.40.486.856 I slot print_timing: id  3 | task 70 | prompt processing, n_tokens =  13824, progress = 0.94, t =   7.37 s / 1875.62 tokens per second
1.40.765.475 I slot print_timing: id  3 | task 70 | prompt processing, n_tokens =  14336, progress = 0.97, t =   7.65 s / 1874.24 tokens per second
1.40.872.481 I slot print_timing: id  3 | task 70 | prompt processing, n_tokens =  14410, progress = 0.97, t =   7.76 s / 1857.92 tokens per second
1.40.900.825 I slot create_check: id  3 | task 70 | created context checkpoint 4 of 32 (pos_min = 19088, pos_max = 19088, n_tokens = 19089, size = 82.984 MiB)
1.41.182.038 I slot print_timing: id  3 | task 70 | prompt processing, n_tokens =  14918, progress = 1.00, t =   8.07 s / 1849.60 tokens per second
1.41.213.703 I slot create_check: id  3 | task 70 | created context checkpoint 5 of 32 (pos_min = 19596, pos_max = 19596, n_tokens = 19597, size = 83.521 MiB)
1.42.701.766 I slot print_timing: id  3 | task 70 | n_decoded =    101, tg =  69.48 t/s
1.45.703.574 I slot print_timing: id  3 | task 70 | n_decoded =    332, tg =  74.52 t/s
1.48.736.878 I slot print_timing: id  3 | task 70 | n_decoded =    578, tg =  77.18 t/s
1.51.740.232 I slot print_timing: id  3 | task 70 | n_decoded =    746, tg =  71.10 t/s
1.54.743.523 I slot print_timing: id  3 | task 70 | n_decoded =    920, tg =  68.17 t/s
1.57.770.883 I slot print_timing: id  3 | task 70 | n_decoded =   1086, tg =  65.73 t/s
2.00.208.022 I reasoning-budget: deactivated (natural end)
2.00.804.058 I slot print_timing: id  3 | task 70 | n_decoded =   1249, tg =  63.87 t/s
2.03.807.085 I slot print_timing: id  3 | task 70 | n_decoded =   1442, tg =  63.92 t/s
2.06.809.644 I slot print_timing: id  3 | task 70 | n_decoded =   1664, tg =  65.10 t/s
2.09.820.005 I slot print_timing: id  3 | task 70 | n_decoded =   1847, tg =  64.64 t/s
2.12.857.271 I slot print_timing: id  3 | task 70 | n_decoded =   2001, tg =  63.30 t/s
2.15.879.342 I slot print_timing: id  3 | task 70 | n_decoded =   2170, tg =  62.66 t/s
2.18.888.811 I slot print_timing: id  3 | task 70 | n_decoded =   2342, tg =  62.22 t/s
2.21.910.513 I slot print_timing: id  3 | task 70 | n_decoded =   2549, tg =  62.69 t/s
2.23.190.809 I slot print_timing: id  3 | task 70 | prompt eval time =    8131.48 ms / 14922 tokens (    0.54 ms per token,  1835.09 tokens per second)
2.23.190.813 I slot print_timing: id  3 | task 70 |        eval time =   41942.65 ms /  2618 tokens (   16.02 ms per token,    62.42 tokens per second)
2.23.190.813 I slot print_timing: id  3 | task 70 |       total time =   50074.13 ms / 17540 tokens
2.23.190.814 I slot print_timing: id  3 | task 70 |    graphs reused =        548
2.23.190.815 I slot print_timing: id  3 | task 70 | draft acceptance = 0.89307 ( 1353 accepted /  1515 generated)
2.23.190.828 I statistics        draft-mtp: #calls(b,g,a) =    2   1324    804, #gen drafts =    804, #acc drafts =   740, #gen tokens =   1660, #acc tokens =  1490, dur(b,g,a) = 0.006, 7224.855, 0.247 ms
2.23.191.280 I slot      release: id  3 | task 70 | stop processing: n_tokens = 22220, truncated = 0
2.23.191.335 I srv  update_slots: all slots are idle

```