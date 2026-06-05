# docker compose yml
```yml
services:
  gemma-4-12b-server:
    # Official multi-arch image with CUDA 13 support for ARM64 / aarch64.
    image: ghcr.io/ggml-org/llama.cpp:server-cuda13
    container_name: gemma-4-12b-dgx-spark
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

    # 70GB shm_size for GB10 unified memory architecture (generous headroom).
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
      # Model: Gemma 4 12B Unified quantization (UD-Q4_K_XL) by Unsloth.
      # Encoder-free architecture — vision and audio baked into the model itself.
      - "-hf"
      - "unsloth/gemma-4-12b-it-GGUF:UD-Q4_K_XL"

      # --- SPECULATIVE DECODING / MTP (Commented out - causes crashes on current llama.cpp)
      # Note: spec-type is called "draft-mtp", not "mtp". Re-enable when stable.
      # 2. ASSISTANT MODEL (0.4B Drafter - Direct BF16 from official repo)
      # - "--spec-draft-hf"
      # - "google/gemma-4-12B-it-assistant"
      # 3. MTP SPECULATION SETTINGS
      # - "--spec-type"
      # - "draft-mtp"
      # - "--spec-draft-n-max"
      # - "2"

      # Aliased name presented in /v1/models API response.
      - "--alias"
      - "${INFERENCE_MODEL_ALIAS:-gemma-4-12b}"

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

      # Forces the OS to lock/pin memory footprint, preventing paging on GB10.
      - "--mlock"

      # Native FlashAttention-2 acceleration for deep context layers.
      - "--flash-attn"
      - "on"

      # Q8_0 KV-cache: High precision (8-bit) to avoid logic errors in long contexts.
      - "--cache-type-k"
      - "q8_0"
      - "--cache-type-v"
      - "q8_0"

      # 2.65M global context — 10x increase leveraging GB10's 128GB unified memory headroom.
      - "--ctx-size"
      - "2649600"

      # 10 concurrent slots for parallel sub-agent workloads.
      # Each slot gets ctx_size / np tokens (2649600 / 10 = ~265K per slot).
      - "--parallel"
      - "10"

      # --- SAMPLING (Gemma 4 standard) ---
      # temperature=1.0, top_p=0.95, top_k=64 per Google DeepMind / Unsloth docs.
      - "--temp"
      - "1.0"
      - "--top-p"
      - "0.95"
      - "--top-k"
      - "64"

    networks:
      - development-network

networks:
  # Allows this server to communicate with other internal tools/proxies.
  development-network:
    external: true

```

# llamacpp log
```log
warn: LLAMA_ARG_HOST environment variable is set, but will be overwritten by command line argument --host
0.32.620.252 I log_info: verbosity = 3 (adjust with the `-lv N` CLI arg)
0.32.620.256 I device_info:
0.32.620.381 I   - CUDA0   : NVIDIA GB10 (122500 MiB, 116953 MiB free)
0.32.620.384 I   - CPU     : CPU (122500 MiB, 122500 MiB free)
0.32.620.571 I system_info: n_threads = 20 (n_threads_batch = 20) / 20 | CUDA : ARCHS = 750,800,860,890,900,1200,1210 | USE_GRAPHS = 1 | PEER_MAX_BATCH_SIZE = 128 | BLACKWELL_NATIVE_FP4 = 1 | CPU : NEON = 1 | ARM_FMA = 1 | FP16_VA = 1 | MATMUL_INT8 = 1 | SVE = 1 | DOTPROD = 1 | SVE_CNT = 16 | OPENMP = 1 | REPACK = 1 | 
0.32.620.654 I srv          init: running without SSL
0.32.620.664 I srv          init: api_keys: ****key
0.32.620.669 I srv          init: using 19 threads for HTTP server
0.32.620.963 I srv         start: binding port with default address family
0.32.622.104 I srv  llama_server: loading model
0.32.622.109 I srv    load_model: loading model '/root/.cache/huggingface/hub/models--unsloth--gemma-4-12b-it-GGUF/snapshots/b5f80f1dd8eddc9c2593e7e54e6af2deb93e2510/gemma-4-12b-it-UD-Q4_K_XL.gguf'
0.32.738.450 I srv    load_model: [mtmd] estimated worst-case memory usage of mmproj is 354.46 MiB
0.32.738.511 I common_init_result: fitting params to device memory ...
0.32.738.511 I common_init_result: (for bugs during this step try to reproduce them with -fit off, or provide --verbose logs if the bug only occurs with -fit on)
0.33.577.964 W load: control-looking token:    212 '</s>' was not control-type; this is probably a bug in the model. its type will be overridden
0.33.578.362 W load: control-looking token:     50 '<|tool_response>' was not control-type; this is probably a bug in the model. its type will be overridden
0.33.583.455 W load: control-looking token:      1 '<eos>' was not control-type; this is probably a bug in the model. its type will be overridden
0.33.597.631 W load: special_eog_ids contains '<|tool_response>', removing '</s>' token from EOG list
0.34.028.011 W warning: failed to mlock 707899392-byte buffer (after previously locking 0 bytes): Cannot allocate memory
Try increasing RLIMIT_MEMLOCK ('ulimit -l' as root).
0.37.865.641 W llama_context: n_ctx_seq (264960) > n_ctx_train (262144) -- possible training context overflow
0.39.033.954 I common_init_from_params: warming up the model with an empty run - please wait ... (--no-warmup to disable)
0.39.371.667 W init_audio: audio input is in experimental stage and may have reduced quality:
    https://github.com/ggml-org/llama.cpp/discussions/13759
0.39.371.677 I srv    load_model: loaded multimodal model, '/root/.cache/huggingface/hub/models--unsloth--gemma-4-12b-it-GGUF/snapshots/b5f80f1dd8eddc9c2593e7e54e6af2deb93e2510/mmproj-BF16.gguf'
0.39.371.686 I srv    load_model: initializing slots, n_slots = 10
0.39.371.690 W srv    load_model: the slot context (264960) exceeds the training context of the model (262144) - capping
0.39.694.111 W common_speculative_init: no implementations specified for speculative decoding
0.39.694.119 I slot   load_model: id  0 | task -1 | new slot, n_ctx = 262144
0.39.694.123 I slot   load_model: id  1 | task -1 | new slot, n_ctx = 262144
0.39.694.123 I slot   load_model: id  2 | task -1 | new slot, n_ctx = 262144
0.39.694.123 I slot   load_model: id  3 | task -1 | new slot, n_ctx = 262144
0.39.694.123 I slot   load_model: id  4 | task -1 | new slot, n_ctx = 262144
0.39.694.124 I slot   load_model: id  5 | task -1 | new slot, n_ctx = 262144
0.39.694.124 I slot   load_model: id  6 | task -1 | new slot, n_ctx = 262144
0.39.694.124 I slot   load_model: id  7 | task -1 | new slot, n_ctx = 262144
0.39.694.124 I slot   load_model: id  8 | task -1 | new slot, n_ctx = 262144
0.39.694.124 I slot   load_model: id  9 | task -1 | new slot, n_ctx = 262144
0.39.694.189 I srv    load_model: prompt cache is enabled, size limit: 8192 MiB
0.39.694.189 I srv    load_model: use `--cache-ram 0` to disable the prompt cache
0.39.694.190 I srv    load_model: for more info see https://github.com/ggml-org/llama.cpp/pull/16391
0.39.694.190 I srv    load_model: context checkpoints enabled, max = 32, min spacing = 256
0.39.694.202 W srv          init: --cache-idle-slots requires --kv-unified, disabling
0.39.699.501 I init: chat template, example_format: '<|turn>system
<|think|>
You are a helpful assistant<turn|>
<|turn>user
Hello<turn|>
<|turn>model
Hi there<turn|>
<|turn>user
How are you?<turn|>
<|turn>model
'
0.39.699.945 I srv          init: init: chat template, thinking = 1
0.39.699.972 I srv  llama_server: model loaded
0.39.699.976 I srv  llama_server: server is listening on http://0.0.0.0:8000
0.39.699.980 I srv  update_slots: all slots are idle
3.56.600.254 I srv  params_from_: Chat format: peg-gemma4
3.56.601.083 I slot get_availabl: id  9 | task -1 | selected slot by LRU, t_last = -1
3.56.601.086 I srv  get_availabl: updating prompt cache
3.56.601.089 I srv          load:  - looking for better prompt, base f_keep = -1.000, sim = 0.000
3.56.601.093 I srv        update:  - cache state: 0 prompts, 0.000 MiB (limits: 8192.000 MiB, 2649600 tokens, 8589934592 est)
3.56.601.093 I srv  get_availabl: prompt cache update took 0.01 ms
3.56.601.128 I slot launch_slot_: id  9 | task 0 | processing task, is_child = 0
3.56.730.267 I srv  params_from_: Chat format: peg-gemma4
3.56.802.889 I slot get_availabl: id  8 | task -1 | selected slot by LRU, t_last = -1
3.56.802.893 I srv  get_availabl: updating prompt cache
3.56.802.895 I srv          load:  - looking for better prompt, base f_keep = -1.000, sim = 0.000
3.56.802.897 I srv        update:  - cache state: 0 prompts, 0.000 MiB (limits: 8192.000 MiB, 2649600 tokens, 8589934592 est)
3.56.802.898 I srv  get_availabl: prompt cache update took 0.00 ms
3.56.803.145 I slot launch_slot_: id  8 | task 3 | processing task, is_child = 0
4.00.190.014 I slot print_timing: id  8 | task 3 | prompt processing, n_tokens =   6144, progress = 0.80, t =   3.39 s / 1814.07 tokens per second
4.00.190.183 I slot print_timing: id  9 | task 0 | prompt processing, n_tokens =    546, progress = 0.97, t =   3.59 s / 152.13 tokens per second
4.00.353.638 I slot create_check: id  9 | task 0 | created context checkpoint 1 of 32 (pos_min = 0, pos_max = 545, n_tokens = 546, size = 90.652 MiB)
4.01.043.908 I slot print_timing: id  8 | task 3 | prompt processing, n_tokens =   7200, progress = 0.93, t =   4.24 s / 1697.81 tokens per second
4.01.044.138 I slot print_timing: id  9 | task 0 | prompt processing, n_tokens =    557, progress = 0.99, t =   4.44 s / 125.37 tokens per second
4.01.436.547 I slot print_timing: id  8 | task 3 | prompt processing, n_tokens =   7701, progress = 1.00, t =   4.63 s / 1662.07 tokens per second
4.01.477.427 I slot create_check: id  8 | task 3 | created context checkpoint 1 of 32 (pos_min = 6165, pos_max = 7700, n_tokens = 7701, size = 170.013 MiB)
4.01.573.628 I slot print_timing: id  8 | task 3 | prompt processing, n_tokens =   7712, progress = 1.00, t =   4.77 s / 1616.61 tokens per second
4.01.708.807 I reasoning-budget: activated, budget=2147483647 tokens
4.03.997.004 I reasoning-budget: deactivated (natural end)
4.04.664.346 I slot print_timing: id  8 | task 3 | prompt eval time =    4859.62 ms /  7716 tokens (    0.63 ms per token,  1587.78 tokens per second)
4.04.664.348 I slot print_timing: id  8 | task 3 |        eval time =    3001.56 ms /    68 tokens (   44.14 ms per token,    22.65 tokens per second)
4.04.664.349 I slot print_timing: id  8 | task 3 |       total time =    7861.18 ms /  7784 tokens
4.04.664.354 I slot print_timing: id  8 | task 3 |    graphs reused =          0
4.04.665.148 I slot      release: id  8 | task 3 | stop processing: n_tokens = 7783, truncated = 0
4.05.871.627 I slot print_timing: id  9 | task 0 | n_decoded =    100, tg =  22.55 t/s
4.08.903.604 I slot print_timing: id  9 | task 0 | n_decoded =    176, tg =  23.57 t/s
4.11.912.255 I slot print_timing: id  9 | task 0 | n_decoded =    251, tg =  23.96 t/s
4.14.928.782 I slot print_timing: id  9 | task 0 | n_decoded =    326, tg =  24.16 t/s
4.15.089.412 I slot print_timing: id  9 | task 0 | prompt eval time =    4835.37 ms /   561 tokens (    8.62 ms per token,   116.02 tokens per second)
4.15.089.414 I slot print_timing: id  9 | task 0 |        eval time =   13652.90 ms /   330 tokens (   41.37 ms per token,    24.17 tokens per second)
4.15.089.415 I slot print_timing: id  9 | task 0 |       total time =   18488.27 ms /   891 tokens
4.15.089.416 I slot print_timing: id  9 | task 0 |    graphs reused =          0
4.15.089.461 I slot      release: id  9 | task 0 | stop processing: n_tokens = 890, truncated = 0
4.15.089.466 I srv  update_slots: all slots are idle
8.46.179.309 I srv  params_from_: Chat format: peg-gemma4
8.46.179.568 I slot get_availabl: id  8 | task -1 | selected slot by LCP similarity, sim_best = 0.240 (> 0.100 thold), f_keep = 0.001
8.46.179.571 I srv  get_availabl: updating prompt cache
8.46.180.783 W srv   prompt_save:  - saving prompt with length 7783, total state size = 234.707 MiB (draft: 0.000 MiB)
8.46.272.546 I srv          load:  - looking for better prompt, base f_keep = 0.001, sim = 0.240
8.46.272.555 I srv        update:  - cache state: 1 prompts, 404.720 MiB (limits: 8192.000 MiB, 2649600 tokens, 2649600 est)
8.46.272.556 I srv        update:    - prompt 0xca58b036e280:    7783 tokens, checkpoints:  1,   404.720 MiB
8.46.272.557 I srv  get_availabl: prompt cache update took 92.98 ms
8.46.272.623 I slot launch_slot_: id  8 | task 338 | processing task, is_child = 0
8.46.272.632 I slot update_slots: id  8 | task 338 | Checking checkpoint with [6165, 7700] against 0...
8.46.272.633 W slot update_slots: id  8 | task 338 | forcing full prompt re-processing due to lack of cache data (likely due to SWA or hybrid/recurrent memory, see https://github.com/ggml-org/llama.cpp/pull/13194#issuecomment-2868343055)
8.46.272.634 W slot update_slots: id  8 | task 338 | erased invalidated context checkpoint (pos_min = 6165, pos_max = 7700, n_tokens = 7701, n_swa = 1024, pos_next = 0, size = 170.013 MiB)
8.46.334.251 I slot create_check: id  8 | task 338 | created context checkpoint 1 of 32 (pos_min = 0, pos_max = 7, n_tokens = 8, size = 1.329 MiB)
8.50.334.485 I slot print_timing: id  8 | task 338 | n_decoded =    100, tg =  25.59 t/s
8.53.367.371 I slot print_timing: id  8 | task 338 | n_decoded =    177, tg =  25.50 t/s
8.55.024.243 I slot print_timing: id  8 | task 338 | prompt eval time =     154.09 ms /    25 tokens (    6.16 ms per token,   162.24 tokens per second)
8.55.024.246 I slot print_timing: id  8 | task 338 |        eval time =    8597.51 ms /   219 tokens (   39.26 ms per token,    25.47 tokens per second)
8.55.024.247 I slot print_timing: id  8 | task 338 |       total time =    8751.61 ms /   244 tokens
8.55.024.248 I slot print_timing: id  8 | task 338 |    graphs reused =          0
8.55.024.260 I slot      release: id  8 | task 338 | stop processing: n_tokens = 243, truncated = 0
8.55.024.277 I srv  update_slots: all slots are idle
8.55.047.282 I srv  params_from_: Chat format: peg-gemma4
8.55.047.468 I slot get_availabl: id  7 | task -1 | selected slot by LRU, t_last = -1
8.55.047.472 I srv  get_availabl: updating prompt cache
8.55.047.476 I srv          load:  - looking for better prompt, base f_keep = -1.000, sim = 0.000
8.55.047.479 I srv        update:  - cache state: 1 prompts, 404.720 MiB (limits: 8192.000 MiB, 2649600 tokens, 2649600 est)
8.55.047.479 I srv        update:    - prompt 0xca58b036e280:    7783 tokens, checkpoints:  1,   404.720 MiB
8.55.047.480 I srv  get_availabl: prompt cache update took 0.01 ms
8.55.047.536 I slot launch_slot_: id  7 | task 560 | processing task, is_child = 0
8.55.099.033 I slot create_check: id  7 | task 560 | created context checkpoint 1 of 32 (pos_min = 0, pos_max = 7, n_tokens = 8, size = 1.329 MiB)
8.55.243.445 I slot create_check: id  7 | task 560 | created context checkpoint 2 of 32 (pos_min = 0, pos_max = 275, n_tokens = 276, size = 45.824 MiB)
8.59.227.455 I slot print_timing: id  7 | task 560 | n_decoded =    100, tg =  25.39 t/s
9.02.245.084 I slot print_timing: id  7 | task 560 | n_decoded =    176, tg =  25.30 t/s
9.05.269.890 I slot print_timing: id  7 | task 560 | n_decoded =    252, tg =  25.25 t/s
9.08.307.770 I slot print_timing: id  7 | task 560 | n_decoded =    328, tg =  25.19 t/s
9.11.345.242 I slot print_timing: id  7 | task 560 | n_decoded =    404, tg =  25.16 t/s
9.13.383.011 I slot print_timing: id  7 | task 560 | prompt eval time =     240.73 ms /   280 tokens (    0.86 ms per token,  1163.15 tokens per second)
9.13.383.016 I slot print_timing: id  7 | task 560 |        eval time =   18094.74 ms /   455 tokens (   39.77 ms per token,    25.15 tokens per second)
9.13.383.017 I slot print_timing: id  7 | task 560 |       total time =   18335.46 ms /   735 tokens
9.13.383.018 I slot print_timing: id  7 | task 560 |    graphs reused =          0
9.13.383.057 I slot      release: id  7 | task 560 | stop processing: n_tokens = 734, truncated = 0
9.13.383.062 I srv  update_slots: all slots are idle
9.13.403.415 I srv  params_from_: Chat format: peg-gemma4
9.13.403.686 I slot get_availabl: id  6 | task -1 | selected slot by LRU, t_last = -1
9.13.403.687 I srv  get_availabl: updating prompt cache
9.13.403.690 I srv          load:  - looking for better prompt, base f_keep = -1.000, sim = 0.000
9.13.403.698 I srv        update:  - cache state: 1 prompts, 404.720 MiB (limits: 8192.000 MiB, 2649600 tokens, 2649600 est)
9.13.403.698 I srv        update:    - prompt 0xca58b036e280:    7783 tokens, checkpoints:  1,   404.720 MiB
9.13.403.699 I srv  get_availabl: prompt cache update took 0.01 ms
9.13.403.747 I slot launch_slot_: id  6 | task 1018 | processing task, is_child = 0
9.13.454.883 I slot create_check: id  6 | task 1018 | created context checkpoint 1 of 32 (pos_min = 0, pos_max = 7, n_tokens = 8, size = 1.329 MiB)
9.13.622.579 I slot create_check: id  6 | task 1018 | created context checkpoint 2 of 32 (pos_min = 0, pos_max = 330, n_tokens = 331, size = 54.956 MiB)
9.17.605.401 I slot print_timing: id  6 | task 1018 | n_decoded =    100, tg =  25.40 t/s
9.20.626.137 I slot print_timing: id  6 | task 1018 | n_decoded =    176, tg =  25.30 t/s
9.23.631.918 I slot print_timing: id  6 | task 1018 | n_decoded =    251, tg =  25.19 t/s
9.26.635.758 I slot print_timing: id  6 | task 1018 | n_decoded =    326, tg =  25.14 t/s
9.29.642.044 I slot print_timing: id  6 | task 1018 | n_decoded =    401, tg =  25.10 t/s
9.31.692.839 I slot print_timing: id  6 | task 1018 | prompt eval time =     264.80 ms /   335 tokens (    0.79 ms per token,  1265.09 tokens per second)
9.31.692.845 I slot print_timing: id  6 | task 1018 |        eval time =   18024.28 ms /   452 tokens (   39.88 ms per token,    25.08 tokens per second)
9.31.692.846 I slot print_timing: id  6 | task 1018 |       total time =   18289.08 ms /   787 tokens
9.31.692.847 I slot print_timing: id  6 | task 1018 |    graphs reused =          0
9.31.692.890 I slot      release: id  6 | task 1018 | stop processing: n_tokens = 786, truncated = 0
9.31.692.896 I srv  update_slots: all slots are idle
9.31.710.645 I srv  params_from_: Chat format: peg-gemma4
9.31.711.043 I slot get_availabl: id  5 | task -1 | selected slot by LRU, t_last = -1
9.31.711.045 I srv  get_availabl: updating prompt cache
9.31.711.050 I srv          load:  - looking for better prompt, base f_keep = -1.000, sim = 0.000
9.31.711.064 I srv        update:  - cache state: 1 prompts, 404.720 MiB (limits: 8192.000 MiB, 2649600 tokens, 2649600 est)
9.31.711.064 I srv        update:    - prompt 0xca58b036e280:    7783 tokens, checkpoints:  1,   404.720 MiB
9.31.711.065 I srv  get_availabl: prompt cache update took 0.02 ms
9.31.711.151 I slot launch_slot_: id  5 | task 1473 | processing task, is_child = 0
9.31.763.129 I slot create_check: id  5 | task 1473 | created context checkpoint 1 of 32 (pos_min = 0, pos_max = 7, n_tokens = 8, size = 1.329 MiB)
9.35.871.662 I slot print_timing: id  5 | task 1473 | n_decoded =    100, tg =  25.33 t/s
9.38.896.430 I slot print_timing: id  5 | task 1473 | n_decoded =    176, tg =  25.24 t/s
9.41.922.781 I slot print_timing: id  5 | task 1473 | n_decoded =    252, tg =  25.20 t/s
9.42.639.025 I slot print_timing: id  5 | task 1473 | prompt eval time =     212.62 ms /   224 tokens (    0.95 ms per token,  1053.54 tokens per second)
9.42.639.029 I slot print_timing: id  5 | task 1473 |        eval time =   10715.24 ms /   270 tokens (   39.69 ms per token,    25.20 tokens per second)
9.42.639.030 I slot print_timing: id  5 | task 1473 |       total time =   10927.86 ms /   494 tokens
9.42.639.031 I slot print_timing: id  5 | task 1473 |    graphs reused =          0
9.42.639.065 I slot      release: id  5 | task 1473 | stop processing: n_tokens = 493, truncated = 0
9.42.639.069 I srv  update_slots: all slots are idle
10.31.427.106 I srv  params_from_: Chat format: peg-gemma4
10.31.443.651 I slot get_availabl: id  4 | task -1 | selected slot by LRU, t_last = -1
10.31.443.655 I srv  get_availabl: updating prompt cache
10.31.443.658 I srv          load:  - looking for better prompt, base f_keep = -1.000, sim = 0.000
10.31.443.663 I srv          load:  - found better prompt with f_keep = 0.586, sim = 0.764
10.31.460.430 I srv        update:  - cache state: 0 prompts, 0.000 MiB (limits: 8192.000 MiB, 2649600 tokens, 8589934592 est)
10.31.460.434 I srv  get_availabl: prompt cache update took 16.78 ms
10.31.460.527 I slot launch_slot_: id  4 | task 1746 | processing task, is_child = 0
10.31.460.536 I slot update_slots: id  4 | task 1746 | Checking checkpoint with [6165, 7700] against 3540...
10.31.460.537 W slot update_slots: id  4 | task 1746 | forcing full prompt re-processing due to lack of cache data (likely due to SWA or hybrid/recurrent memory, see https://github.com/ggml-org/llama.cpp/pull/13194#issuecomment-2868343055)
10.31.460.538 W slot update_slots: id  4 | task 1746 | erased invalidated context checkpoint (pos_min = 6165, pos_max = 7700, n_tokens = 7701, n_swa = 1024, pos_next = 0, size = 170.013 MiB)
10.32.522.767 I srv  params_from_: Chat format: peg-gemma4
10.33.572.774 I slot get_availabl: id  3 | task -1 | selected slot by LRU, t_last = -1
10.33.572.778 I srv  get_availabl: updating prompt cache
10.33.572.781 I srv          load:  - looking for better prompt, base f_keep = -1.000, sim = 0.000
10.33.572.783 I srv        update:  - cache state: 0 prompts, 0.000 MiB (limits: 8192.000 MiB, 2649600 tokens, 8589934592 est)
10.33.572.784 I srv  get_availabl: prompt cache update took 0.01 ms
10.33.572.905 I slot launch_slot_: id  3 | task 1749 | processing task, is_child = 0
10.33.651.439 I srv  params_from_: Chat format: peg-gemma4
10.34.682.970 I slot get_availabl: id  2 | task -1 | selected slot by LRU, t_last = -1
10.34.682.974 I srv  get_availabl: updating prompt cache
10.34.682.977 I srv          load:  - looking for better prompt, base f_keep = -1.000, sim = 0.000
10.34.682.979 I srv        update:  - cache state: 0 prompts, 0.000 MiB (limits: 8192.000 MiB, 2649600 tokens, 8589934592 est)
10.34.682.980 I srv  get_availabl: prompt cache update took 0.01 ms
10.34.683.086 I slot launch_slot_: id  2 | task 1751 | processing task, is_child = 0
10.34.772.746 I srv  params_from_: Chat format: peg-gemma4
10.35.787.678 I slot get_availabl: id  1 | task -1 | selected slot by LRU, t_last = -1
10.35.787.682 I srv  get_availabl: updating prompt cache
10.35.787.685 I srv          load:  - looking for better prompt, base f_keep = -1.000, sim = 0.000
10.35.787.687 I srv        update:  - cache state: 0 prompts, 0.000 MiB (limits: 8192.000 MiB, 2649600 tokens, 8589934592 est)
10.35.787.688 I srv  get_availabl: prompt cache update took 0.01 ms
10.35.787.798 I slot launch_slot_: id  1 | task 1753 | processing task, is_child = 0
10.35.899.408 I srv  params_from_: Chat format: peg-gemma4
10.36.898.526 I slot get_availabl: id  0 | task -1 | selected slot by LRU, t_last = -1
10.36.898.530 I srv  get_availabl: updating prompt cache
10.36.898.533 I srv          load:  - looking for better prompt, base f_keep = -1.000, sim = 0.000
10.36.898.534 I srv        update:  - cache state: 0 prompts, 0.000 MiB (limits: 8192.000 MiB, 2649600 tokens, 8589934592 est)
10.36.898.535 I srv  get_availabl: prompt cache update took 0.01 ms
10.36.898.643 I slot launch_slot_: id  0 | task 1755 | processing task, is_child = 0
10.39.144.016 I slot print_timing: id  1 | task 1753 | prompt processing, n_tokens =   2048, progress = 0.34, t =   3.36 s / 610.21 tokens per second
10.40.427.644 I slot print_timing: id  0 | task 1755 | prompt processing, n_tokens =   5456, progress = 0.91, t =   3.53 s / 1546.05 tokens per second
10.40.427.818 I slot print_timing: id  1 | task 1753 | prompt processing, n_tokens =   2736, progress = 0.46, t =   4.64 s / 589.65 tokens per second
10.41.603.596 I slot print_timing: id  0 | task 1755 | prompt processing, n_tokens =   5886, progress = 0.99, t =   4.70 s / 1251.03 tokens per second
10.41.676.522 I slot create_check: id  0 | task 1755 | created context checkpoint 1 of 32 (pos_min = 4350, pos_max = 5885, n_tokens = 5886, size = 170.013 MiB)
10.41.676.531 I slot print_timing: id  1 | task 1753 | prompt processing, n_tokens =   4354, progress = 0.73, t =   5.89 s / 739.38 tokens per second
10.41.676.660 I slot print_timing: id  2 | task 1751 | prompt processing, n_tokens =   2048, progress = 0.34, t =   6.99 s / 292.84 tokens per second
10.42.892.655 I slot print_timing: id  0 | task 1755 | prompt processing, n_tokens =   5968, progress = 1.00, t =   5.99 s / 995.66 tokens per second
10.42.893.445 I slot print_timing: id  1 | task 1753 | prompt processing, n_tokens =   5456, progress = 0.91, t =   7.11 s / 767.84 tokens per second
10.42.893.704 I slot print_timing: id  2 | task 1751 | prompt processing, n_tokens =   2912, progress = 0.49, t =   8.21 s / 354.66 tokens per second
10.44.222.003 I slot print_timing: id  1 | task 1753 | prompt processing, n_tokens =   5886, progress = 0.99, t =   8.43 s / 697.87 tokens per second
10.44.273.785 I slot create_check: id  1 | task 1753 | created context checkpoint 1 of 32 (pos_min = 4350, pos_max = 5885, n_tokens = 5886, size = 170.013 MiB)
10.44.273.792 I slot print_timing: id  2 | task 1751 | prompt processing, n_tokens =   4526, progress = 0.76, t =   9.59 s / 471.92 tokens per second
10.44.273.925 I slot print_timing: id  3 | task 1749 | prompt processing, n_tokens =   2048, progress = 0.34, t =  10.70 s / 191.38 tokens per second
10.45.593.233 I reasoning-budget: activated, budget=2147483647 tokens
10.45.593.269 I slot print_timing: id  1 | task 1753 | prompt processing, n_tokens =   5968, progress = 1.00, t =   9.81 s / 608.64 tokens per second
10.45.594.011 I slot print_timing: id  2 | task 1751 | prompt processing, n_tokens =   5456, progress = 0.91, t =  10.91 s / 500.05 tokens per second
10.45.594.140 I slot print_timing: id  3 | task 1749 | prompt processing, n_tokens =   3083, progress = 0.52, t =  12.02 s / 256.46 tokens per second
10.46.905.244 I slot print_timing: id  2 | task 1751 | prompt processing, n_tokens =   5886, progress = 0.99, t =  12.22 s / 481.58 tokens per second
10.46.950.744 I slot create_check: id  2 | task 1751 | created context checkpoint 1 of 32 (pos_min = 4350, pos_max = 5885, n_tokens = 5886, size = 170.013 MiB)
10.46.950.750 I slot print_timing: id  3 | task 1749 | prompt processing, n_tokens =   4696, progress = 0.79, t =  13.38 s / 351.03 tokens per second
10.46.950.874 I slot print_timing: id  4 | task 1746 | prompt processing, n_tokens =   4096, progress = 0.69, t =  15.49 s / 264.42 tokens per second
10.48.240.821 I reasoning-budget: activated, budget=2147483647 tokens
10.48.240.843 I slot print_timing: id  2 | task 1751 | prompt processing, n_tokens =   5968, progress = 1.00, t =  13.56 s / 440.19 tokens per second
10.48.241.585 I slot print_timing: id  3 | task 1749 | prompt processing, n_tokens =   5456, progress = 0.91, t =  14.67 s / 371.95 tokens per second
10.48.241.717 I slot print_timing: id  4 | task 1746 | prompt processing, n_tokens =   5300, progress = 0.89, t =  16.78 s / 315.83 tokens per second
10.48.717.269 I slot print_timing: id  3 | task 1749 | prompt processing, n_tokens =   5886, progress = 0.99, t =  15.14 s / 388.66 tokens per second
10.48.761.347 I slot create_check: id  3 | task 1749 | created context checkpoint 1 of 32 (pos_min = 4350, pos_max = 5885, n_tokens = 5886, size = 170.013 MiB)
10.48.761.353 I slot print_timing: id  4 | task 1746 | prompt processing, n_tokens =   5456, progress = 0.91, t =  17.30 s / 315.36 tokens per second
10.49.132.601 I reasoning-budget: activated, budget=2147483647 tokens
10.49.132.786 I slot print_timing: id  3 | task 1749 | prompt processing, n_tokens =   5968, progress = 1.00, t =  15.56 s / 383.55 tokens per second
10.49.133.540 I slot print_timing: id  4 | task 1746 | prompt processing, n_tokens =   5886, progress = 0.99, t =  17.67 s / 333.05 tokens per second
10.49.174.980 I slot create_check: id  4 | task 1746 | created context checkpoint 1 of 32 (pos_min = 4350, pos_max = 5885, n_tokens = 5886, size = 170.013 MiB)
10.49.362.764 I slot print_timing: id  4 | task 1746 | prompt processing, n_tokens =   5968, progress = 1.00, t =  17.90 s / 333.37 tokens per second
10.49.472.812 I reasoning-budget: activated, budget=2147483647 tokens
10.49.535.626 I reasoning-budget: activated, budget=2147483647 tokens
10.55.114.853 I slot print_timing: id  0 | task 1755 | n_decoded =    100, tg =   9.18 t/s
10.55.240.470 I slot print_timing: id  1 | task 1753 | n_decoded =    100, tg =  12.00 t/s
10.55.363.415 I slot print_timing: id  2 | task 1751 | n_decoded =    100, tg =  15.05 t/s
10.55.488.556 I slot print_timing: id  3 | task 1749 | n_decoded =    100, tg =  16.32 t/s
10.55.551.533 I slot print_timing: id  4 | task 1746 | n_decoded =    100, tg =  16.45 t/s
10.56.361.745 I reasoning-budget: deactivated (natural end)
10.56.920.587 I reasoning-budget: deactivated (natural end)
10.58.044.969 I slot print_timing: id  3 | task 1749 | prompt eval time =   15789.82 ms /  5972 tokens (    2.64 ms per token,   378.22 tokens per second)
10.58.044.974 I slot print_timing: id  3 | task 1749 |        eval time =    8682.22 ms /   141 tokens (   61.58 ms per token,    16.24 tokens per second)
10.58.044.975 I slot print_timing: id  3 | task 1749 |       total time =   24472.04 ms /  6113 tokens
10.58.044.976 I slot print_timing: id  3 | task 1749 |    graphs reused =          0
10.58.045.869 I slot      release: id  3 | task 1749 | stop processing: n_tokens = 6112, truncated = 0
10.58.138.520 I slot print_timing: id  0 | task 1755 | n_decoded =    148, tg =  10.63 t/s
10.58.279.806 I srv  params_from_: Chat format: peg-gemma4
10.58.327.835 I slot print_timing: id  1 | task 1753 | n_decoded =    148, tg =  12.96 t/s
10.58.328.360 I slot get_availabl: id  3 | task -1 | selected slot by LCP similarity, sim_best = 0.978 (> 0.100 thold), f_keep = 0.996
10.58.328.446 I slot launch_slot_: id  3 | task 1911 | processing task, is_child = 0
10.58.529.775 I slot print_timing: id  2 | task 1751 | n_decoded =    147, tg =  14.98 t/s
10.58.571.997 I slot create_check: id  3 | task 1911 | created context checkpoint 2 of 32 (pos_min = 4681, pos_max = 6216, n_tokens = 6217, size = 170.013 MiB)
10.58.717.533 I reasoning-budget: deactivated (natural end)
10.58.718.404 I slot print_timing: id  4 | task 1746 | n_decoded =    145, tg =  15.69 t/s
10.58.780.417 I reasoning-budget: activated, budget=2147483647 tokens
10.58.965.806 I slot print_timing: id  2 | task 1751 | prompt eval time =   14034.16 ms /  5972 tokens (    2.35 ms per token,   425.53 tokens per second)
10.58.965.809 I slot print_timing: id  2 | task 1751 |        eval time =   10248.55 ms /   152 tokens (   67.42 ms per token,    14.83 tokens per second)
10.58.965.810 I slot print_timing: id  2 | task 1751 |       total time =   24282.71 ms /  6124 tokens
10.58.965.811 I slot print_timing: id  2 | task 1751 |    graphs reused =          0
10.58.966.089 I slot      release: id  2 | task 1751 | stop processing: n_tokens = 6123, truncated = 0
10.59.195.616 I srv  params_from_: Chat format: peg-gemma4
10.59.245.939 I slot get_availabl: id  2 | task -1 | selected slot by LCP similarity, sim_best = 0.978 (> 0.100 thold), f_keep = 0.996
10.59.246.029 I slot launch_slot_: id  2 | task 1921 | processing task, is_child = 0
10.59.485.891 I slot create_check: id  2 | task 1921 | created context checkpoint 2 of 32 (pos_min = 4692, pos_max = 6227, n_tokens = 6228, size = 170.013 MiB)
10.59.692.547 I reasoning-budget: activated, budget=2147483647 tokens
11.00.000.747 I reasoning-budget: deactivated (natural end)
11.00.307.870 I reasoning-budget: deactivated (natural end)
11.00.744.425 I slot print_timing: id  1 | task 1753 | prompt eval time =   11117.42 ms /  5972 tokens (    1.86 ms per token,   537.18 tokens per second)
11.00.744.428 I slot print_timing: id  1 | task 1753 |        eval time =   13839.03 ms /   177 tokens (   78.19 ms per token,    12.79 tokens per second)
11.00.744.429 I slot print_timing: id  1 | task 1753 |       total time =   24956.44 ms /  6149 tokens
11.00.744.430 I slot print_timing: id  1 | task 1753 |    graphs reused =          0
11.00.744.695 I slot      release: id  1 | task 1753 | stop processing: n_tokens = 6148, truncated = 0
11.00.956.533 I srv  params_from_: Chat format: peg-gemma4
11.01.030.465 I slot get_availabl: id  1 | task -1 | selected slot by LCP similarity, sim_best = 0.978 (> 0.100 thold), f_keep = 0.996
11.01.030.556 I slot launch_slot_: id  1 | task 1945 | processing task, is_child = 0
11.01.229.415 I slot print_timing: id  0 | task 1755 | n_decoded =    183, tg =  10.76 t/s
11.01.270.241 I slot create_check: id  1 | task 1945 | created context checkpoint 2 of 32 (pos_min = 4740, pos_max = 6252, n_tokens = 6253, size = 170.013 MiB)
11.01.475.991 I reasoning-budget: activated, budget=2147483647 tokens
11.01.724.689 I slot print_timing: id  4 | task 1746 | n_decoded =    182, tg =  14.86 t/s
11.02.032.572 I slot print_timing: id  4 | task 1746 | prompt eval time =   18013.47 ms /  5972 tokens (    3.02 ms per token,   331.53 tokens per second)
11.02.032.576 I slot print_timing: id  4 | task 1746 |        eval time =   12558.56 ms /   187 tokens (   67.16 ms per token,    14.89 tokens per second)
11.02.032.577 I slot print_timing: id  4 | task 1746 |       total time =   30572.03 ms /  6159 tokens
11.02.032.578 I slot print_timing: id  4 | task 1746 |    graphs reused =          0
11.02.032.849 I slot      release: id  4 | task 1746 | stop processing: n_tokens = 6158, truncated = 0
11.02.173.728 I srv  params_from_: Chat format: peg-gemma4
11.02.200.112 I slot get_availabl: id  4 | task -1 | selected slot by LCP similarity, sim_best = 0.978 (> 0.100 thold), f_keep = 0.996
11.02.200.204 I slot launch_slot_: id  4 | task 1961 | processing task, is_child = 0
11.02.402.479 I slot create_check: id  4 | task 1961 | created context checkpoint 2 of 32 (pos_min = 4740, pos_max = 6262, n_tokens = 6263, size = 170.013 MiB)
11.02.511.737 I slot print_timing: id  0 | task 1755 | prompt eval time =    7323.32 ms /  5972 tokens (    1.23 ms per token,   815.48 tokens per second)
11.02.511.740 I slot print_timing: id  0 | task 1755 |        eval time =   18289.75 ms /   199 tokens (   91.91 ms per token,    10.88 tokens per second)
11.02.511.741 I slot print_timing: id  0 | task 1755 |       total time =   25613.07 ms /  6171 tokens
11.02.511.743 I slot print_timing: id  0 | task 1755 |    graphs reused =          0
11.02.512.012 I slot      release: id  0 | task 1755 | stop processing: n_tokens = 6170, truncated = 0
11.02.566.476 I reasoning-budget: activated, budget=2147483647 tokens
11.02.690.627 I srv  params_from_: Chat format: peg-gemma4
11.02.731.260 I slot get_availabl: id  0 | task -1 | selected slot by LCP similarity, sim_best = 0.978 (> 0.100 thold), f_keep = 0.996
11.02.731.351 I slot launch_slot_: id  0 | task 1968 | processing task, is_child = 0
11.02.768.855 I slot create_check: id  0 | task 1968 | created context checkpoint 2 of 32 (pos_min = 4634, pos_max = 6142, n_tokens = 6143, size = 170.013 MiB)
11.03.090.405 I reasoning-budget: activated, budget=2147483647 tokens
11.05.898.460 I slot print_timing: id  3 | task 1911 | n_decoded =    100, tg =  13.93 t/s
11.06.456.383 I slot print_timing: id  2 | task 1921 | n_decoded =    100, tg =  14.65 t/s
11.07.874.414 I slot print_timing: id  1 | task 1945 | n_decoded =    100, tg =  15.48 t/s
11.08.805.140 I slot print_timing: id  4 | task 1961 | n_decoded =    100, tg =  15.89 t/s
11.08.929.478 I slot print_timing: id  3 | task 1911 | n_decoded =    149, tg =  14.59 t/s
11.09.176.748 I slot print_timing: id  0 | task 1968 | n_decoded =    100, tg =  16.26 t/s
11.09.489.485 I slot print_timing: id  2 | task 1921 | n_decoded =    149, tg =  15.11 t/s
11.10.923.895 I slot print_timing: id  1 | task 1945 | n_decoded =    149, tg =  15.67 t/s
11.11.858.642 I slot print_timing: id  4 | task 1961 | n_decoded =    149, tg =  15.94 t/s
11.11.983.011 I slot print_timing: id  3 | task 1911 | n_decoded =    198, tg =  14.93 t/s
11.12.230.827 I slot print_timing: id  0 | task 1968 | n_decoded =    149, tg =  16.19 t/s
11.12.544.093 I slot print_timing: id  2 | task 1921 | n_decoded =    198, tg =  15.33 t/s
11.12.667.936 I reasoning-budget: deactivated (natural end)
11.13.976.117 I slot print_timing: id  1 | task 1945 | n_decoded =    198, tg =  15.76 t/s
11.14.911.153 I slot print_timing: id  4 | task 1961 | n_decoded =    198, tg =  15.97 t/s
11.15.035.666 I slot print_timing: id  3 | task 1911 | n_decoded =    247, tg =  15.14 t/s
11.15.283.849 I slot print_timing: id  0 | task 1968 | n_decoded =    198, tg =  16.15 t/s
11.15.596.472 I slot print_timing: id  2 | task 1921 | n_decoded =    247, tg =  15.47 t/s
11.16.531.493 I slot print_timing: id  3 | task 1911 | prompt eval time =     389.69 ms /   136 tokens (    2.87 ms per token,   348.99 tokens per second)
11.16.531.497 I slot print_timing: id  3 | task 1911 |        eval time =   17813.33 ms /   271 tokens (   65.73 ms per token,    15.21 tokens per second)
11.16.531.497 I slot print_timing: id  3 | task 1911 |       total time =   18203.03 ms /   407 tokens
11.16.531.499 I slot print_timing: id  3 | task 1911 |    graphs reused =          0
11.16.531.774 I slot      release: id  3 | task 1911 | stop processing: n_tokens = 6491, truncated = 0
11.17.002.333 I slot print_timing: id  1 | task 1945 | n_decoded =    244, tg =  15.65 t/s
11.17.659.990 I reasoning-budget: deactivated (natural end)
11.17.943.294 I slot print_timing: id  4 | task 1961 | n_decoded =    239, tg =  15.49 t/s
11.18.319.027 I slot print_timing: id  0 | task 1968 | n_decoded =    237, tg =  15.50 t/s
11.18.412.817 I reasoning-budget: deactivated (natural end)
11.18.602.398 I slot print_timing: id  2 | task 1921 | n_decoded =    284, tg =  14.97 t/s
11.19.166.862 I reasoning-budget: deactivated (natural end)
11.20.015.026 I slot print_timing: id  1 | task 1945 | n_decoded =    276, tg =  14.84 t/s
11.20.958.295 I slot print_timing: id  4 | task 1961 | n_decoded =    271, tg =  14.69 t/s
11.21.334.787 I slot print_timing: id  0 | task 1968 | n_decoded =    269, tg =  14.69 t/s
11.21.618.154 I slot print_timing: id  2 | task 1921 | n_decoded =    316, tg =  14.37 t/s
11.23.039.275 I slot print_timing: id  1 | task 1945 | n_decoded =    308, tg =  14.24 t/s
11.23.510.444 I slot print_timing: id  2 | task 1921 | prompt eval time =     384.37 ms /   136 tokens (    2.83 ms per token,   353.82 tokens per second)
11.23.510.448 I slot print_timing: id  2 | task 1921 |        eval time =   23879.94 ms /   336 tokens (   71.07 ms per token,    14.07 tokens per second)
11.23.510.448 I slot print_timing: id  2 | task 1921 |       total time =   24264.31 ms /   472 tokens
11.23.510.449 I slot print_timing: id  2 | task 1921 |    graphs reused =          0
11.23.510.730 I slot      release: id  2 | task 1921 | stop processing: n_tokens = 6567, truncated = 0
11.24.038.067 I slot print_timing: id  4 | task 1961 | n_decoded =    304, tg =  14.12 t/s
11.24.388.499 I slot print_timing: id  0 | task 1968 | n_decoded =    302, tg =  14.14 t/s
11.24.915.037 I slot print_timing: id  4 | task 1961 | prompt eval time =     312.85 ms /   136 tokens (    2.30 ms per token,   434.72 tokens per second)
11.24.915.041 I slot print_timing: id  4 | task 1961 |        eval time =   22401.97 ms /   314 tokens (   71.34 ms per token,    14.02 tokens per second)
11.24.915.041 I slot print_timing: id  4 | task 1961 |       total time =   22714.81 ms /   450 tokens
11.24.915.043 I slot print_timing: id  4 | task 1961 |    graphs reused =          0
11.24.915.321 I slot      release: id  4 | task 1961 | stop processing: n_tokens = 6580, truncated = 0
11.25.056.809 I slot print_timing: id  0 | task 1968 | prompt eval time =     295.85 ms /   136 tokens (    2.18 ms per token,   459.70 tokens per second)
11.25.056.812 I slot print_timing: id  0 | task 1968 |        eval time =   22029.60 ms /   311 tokens (   70.83 ms per token,    14.12 tokens per second)
11.25.056.813 I slot print_timing: id  0 | task 1968 |       total time =   22325.45 ms /   447 tokens
11.25.056.813 I slot print_timing: id  0 | task 1968 |    graphs reused =          0
11.25.057.069 I slot      release: id  0 | task 1968 | stop processing: n_tokens = 6589, truncated = 0
11.26.063.607 I slot print_timing: id  1 | task 1945 | n_decoded =    356, tg =  14.44 t/s
11.27.768.973 I reasoning-budget: deactivated (natural end)
11.29.102.788 I slot print_timing: id  1 | task 1945 | n_decoded =    429, tg =  15.49 t/s
11.30.351.222 I slot print_timing: id  1 | task 1945 | prompt eval time =     383.33 ms /   136 tokens (    2.82 ms per token,   354.79 tokens per second)
11.30.351.224 I slot print_timing: id  1 | task 1945 |        eval time =   28937.33 ms /   459 tokens (   63.04 ms per token,    15.86 tokens per second)
11.30.351.225 I slot print_timing: id  1 | task 1945 |       total time =   29320.66 ms /   595 tokens
11.30.351.226 I slot print_timing: id  1 | task 1945 |    graphs reused =          0
11.30.351.488 I slot      release: id  1 | task 1945 | stop processing: n_tokens = 6715, truncated = 0
11.30.351.505 I srv  update_slots: all slots are idle
11.34.412.773 I srv  params_from_: Chat format: peg-gemma4
11.34.429.920 I slot get_availabl: id  0 | task -1 | selected slot by LCP similarity, sim_best = 0.987 (> 0.100 thold), f_keep = 0.895
11.34.430.082 I slot launch_slot_: id  0 | task 2408 | processing task, is_child = 0
11.34.430.092 I slot update_slots: id  0 | task 2408 | Checking checkpoint with [4634, 6142] against 4870...
11.34.434.152 W slot update_slots: id  0 | task 2408 | restored context checkpoint (pos_min = 4634, pos_max = 6142, n_tokens = 6143, n_past = 5894, size = 170.013 MiB)
11.34.434.153 W slot update_slots: id  0 | task 2408 | erased invalidated context checkpoint (pos_min = 4634, pos_max = 6142, n_tokens = 6143, n_swa = 1024, pos_next = 5894, size = 170.013 MiB)
11.34.601.937 I reasoning-budget: activated, budget=2147483647 tokens
11.38.646.634 I slot print_timing: id  0 | task 2408 | n_decoded =    100, tg =  24.46 t/s
11.39.966.233 I reasoning-budget: deactivated (natural end)
11.41.080.055 I slot print_timing: id  0 | task 2408 | prompt eval time =     128.36 ms /    78 tokens (    1.65 ms per token,   607.65 tokens per second)
11.41.080.057 I slot print_timing: id  0 | task 2408 |        eval time =    6521.60 ms /   159 tokens (   41.02 ms per token,    24.38 tokens per second)
11.41.080.058 I slot print_timing: id  0 | task 2408 |       total time =    6649.96 ms /   237 tokens
11.41.080.059 I slot print_timing: id  0 | task 2408 |    graphs reused =          0
11.41.080.318 I slot      release: id  0 | task 2408 | stop processing: n_tokens = 6130, truncated = 0
11.41.080.334 I srv  update_slots: all slots are idle
11.41.283.116 I srv  params_from_: Chat format: peg-gemma4
11.41.299.972 I slot get_availabl: id  0 | task -1 | selected slot by LCP similarity, sim_best = 0.978 (> 0.100 thold), f_keep = 0.996
11.41.300.091 I slot launch_slot_: id  0 | task 2569 | processing task, is_child = 0
11.41.300.104 I slot update_slots: id  0 | task 2569 | Checking checkpoint with [4350, 5885] against 5079...
11.41.304.133 W slot update_slots: id  0 | task 2569 | restored context checkpoint (pos_min = 4350, pos_max = 5885, n_tokens = 5886, n_past = 5885, size = 170.013 MiB)
11.41.543.596 I slot create_check: id  0 | task 2569 | created context checkpoint 2 of 32 (pos_min = 4862, pos_max = 6234, n_tokens = 6235, size = 170.013 MiB)
11.41.635.890 I reasoning-budget: activated, budget=2147483647 tokens
11.45.723.466 I slot print_timing: id  0 | task 2569 | n_decoded =    100, tg =  24.21 t/s
11.48.726.401 I slot print_timing: id  0 | task 2569 | n_decoded =    172, tg =  24.11 t/s
11.51.729.009 I slot print_timing: id  0 | task 2569 | n_decoded =    244, tg =  24.07 t/s
11.52.021.023 I reasoning-budget: deactivated (natural end)
11.54.605.375 I slot print_timing: id  0 | task 2569 | prompt eval time =     292.64 ms /   354 tokens (    0.83 ms per token,  1209.66 tokens per second)
11.54.605.377 I slot print_timing: id  0 | task 2569 |        eval time =   13012.63 ms /   313 tokens (   41.57 ms per token,    24.05 tokens per second)
11.54.605.377 I slot print_timing: id  0 | task 2569 |       total time =   13305.27 ms /   667 tokens
11.54.605.378 I slot print_timing: id  0 | task 2569 |    graphs reused =          0
11.54.605.646 I slot      release: id  0 | task 2569 | stop processing: n_tokens = 6551, truncated = 0
11.54.605.664 I srv  update_slots: all slots are idle
11.58.935.969 I srv  params_from_: Chat format: peg-gemma4
11.58.952.920 I slot get_availabl: id  0 | task -1 | selected slot by LCP similarity, sim_best = 1.000 (> 0.100 thold), f_keep = 0.912
11.58.953.064 I slot launch_slot_: id  0 | task 2885 | processing task, is_child = 0
11.58.953.075 I slot update_slots: id  0 | task 2885 | Checking checkpoint with [4862, 6234] against 4947...
11.58.957.144 W slot update_slots: id  0 | task 2885 | restored context checkpoint (pos_min = 4862, pos_max = 6234, n_tokens = 6235, n_past = 5972, size = 170.013 MiB)
11.58.957.146 W slot update_slots: id  0 | task 2885 | erased invalidated context checkpoint (pos_min = 4862, pos_max = 6234, n_tokens = 6235, n_swa = 1024, pos_next = 5972, size = 170.013 MiB)
11.58.967.318 W slot update_slots: id  0 | task 2885 | need to evaluate at least 1 token for each active slot (n_past = 5972, task.n_tokens() = 5972)
11.58.967.319 W slot update_slots: id  0 | task 2885 | n_past was set to 5971
11.59.056.751 I reasoning-budget: activated, budget=2147483647 tokens
12.00.280.351 I srv  params_from_: Chat format: peg-gemma4
12.00.300.169 I slot get_availabl: id  9 | task -1 | selected slot by LRU, t_last = 527217966577
12.00.300.171 I srv  get_availabl: updating prompt cache
12.00.301.332 W srv   prompt_save:  - saving prompt with length 890, total state size = 155.163 MiB (draft: 0.000 MiB)
12.00.359.183 I srv          load:  - looking for better prompt, base f_keep = 0.007, sim = 0.000
12.00.359.191 I srv        update:  - cache state: 1 prompts, 245.815 MiB (limits: 8192.000 MiB, 2649600 tokens, 2649600 est)
12.00.359.192 I srv        update:    - prompt 0xca58b2f816d0:     890 tokens, checkpoints:  1,   245.815 MiB
12.00.359.193 I srv  get_availabl: prompt cache update took 59.02 ms
12.00.359.260 I slot launch_slot_: id  9 | task 2918 | processing task, is_child = 0
12.00.359.267 I slot update_slots: id  9 | task 2918 | Checking checkpoint with [0, 545] against 0...
12.00.361.823 W slot update_slots: id  9 | task 2918 | restored context checkpoint (pos_min = 0, pos_max = 545, n_tokens = 546, n_past = 6, size = 90.652 MiB)
12.00.361.825 W slot update_slots: id  9 | task 2918 | erased invalidated context checkpoint (pos_min = 0, pos_max = 545, n_tokens = 546, n_swa = 1024, pos_next = 6, size = 90.652 MiB)
12.00.469.687 I slot create_check: id  9 | task 2918 | created context checkpoint 1 of 32 (pos_min = 0, pos_max = 42, n_tokens = 43, size = 7.140 MiB)
12.04.050.255 I slot print_timing: id  9 | task 2918 | prompt processing, n_tokens =   6178, progress = 0.44, t =   3.69 s / 1673.81 tokens per second
12.05.301.683 I slot print_timing: id  9 | task 2918 | prompt processing, n_tokens =   8225, progress = 0.58, t =   4.94 s / 1664.17 tokens per second
12.06.588.317 I slot print_timing: id  9 | task 2918 | prompt processing, n_tokens =  10272, progress = 0.73, t =   6.23 s / 1649.05 tokens per second
12.07.906.646 I slot print_timing: id  9 | task 2918 | prompt processing, n_tokens =  12319, progress = 0.87, t =   7.55 s / 1632.22 tokens per second
12.08.757.168 I slot print_timing: id  9 | task 2918 | prompt processing, n_tokens =  13579, progress = 0.96, t =   8.40 s / 1616.95 tokens per second
12.08.801.761 I slot create_check: id  9 | task 2918 | created context checkpoint 2 of 32 (pos_min = 12049, pos_max = 13584, n_tokens = 13585, size = 170.013 MiB)
12.09.179.965 I slot print_timing: id  9 | task 2918 | prompt processing, n_tokens =  14091, progress = 1.00, t =   8.82 s / 1597.49 tokens per second
12.09.226.707 I slot create_check: id  9 | task 2918 | created context checkpoint 3 of 32 (pos_min = 12561, pos_max = 14096, n_tokens = 14097, size = 170.013 MiB)
12.14.301.036 I slot print_timing: id  0 | task 2885 | n_decoded =    100, tg =   6.54 t/s
12.16.092.484 I reasoning-budget: deactivated (natural end)
12.17.369.731 I slot print_timing: id  0 | task 2885 | n_decoded =    136, tg =   7.41 t/s
12.17.799.550 I slot print_timing: id  9 | task 2918 | n_decoded =    100, tg =  11.80 t/s
12.18.394.664 I slot print_timing: id  0 | task 2885 | prompt eval time =      59.65 ms /     1 tokens (   59.65 ms per token,    16.76 tokens per second)
12.18.394.668 I slot print_timing: id  0 | task 2885 |        eval time =   19381.93 ms /   148 tokens (  130.96 ms per token,     7.64 tokens per second)
12.18.394.669 I slot print_timing: id  0 | task 2885 |       total time =   19441.58 ms /   149 tokens
12.18.394.670 I slot print_timing: id  0 | task 2885 |    graphs reused =          0
12.18.395.089 I slot      release: id  0 | task 2885 | stop processing: n_tokens = 6119, truncated = 0
12.18.614.233 I srv  params_from_: Chat format: peg-gemma4
12.18.655.076 I slot get_availabl: id  0 | task -1 | selected slot by LCP similarity, sim_best = 0.978 (> 0.100 thold), f_keep = 0.996
12.18.655.165 I slot launch_slot_: id  0 | task 3041 | processing task, is_child = 0
12.18.655.171 I slot update_slots: id  0 | task 3041 | Checking checkpoint with [4350, 5885] against 5068...
12.18.659.189 W slot update_slots: id  0 | task 3041 | restored context checkpoint (pos_min = 4350, pos_max = 5885, n_tokens = 5886, n_past = 5885, size = 170.013 MiB)
12.19.018.947 I slot create_check: id  0 | task 3041 | created context checkpoint 2 of 32 (pos_min = 4862, pos_max = 6223, n_tokens = 6224, size = 170.013 MiB)
12.19.200.829 I reasoning-budget: activated, budget=2147483647 tokens
12.20.826.554 I slot print_timing: id  9 | task 2918 | n_decoded =    136, tg =  11.82 t/s
12.23.901.511 I slot print_timing: id  9 | task 2918 | n_decoded =    172, tg =  11.80 t/s
12.26.977.096 I slot print_timing: id  9 | task 2918 | n_decoded =    208, tg =  11.78 t/s
12.27.574.398 I slot print_timing: id  0 | task 3041 | n_decoded =    100, tg =  11.82 t/s
12.30.051.064 I slot print_timing: id  9 | task 2918 | n_decoded =    244, tg =  11.77 t/s
12.30.648.714 I slot print_timing: id  0 | task 3041 | n_decoded =    136, tg =  11.79 t/s
12.33.127.424 I slot print_timing: id  9 | task 2918 | n_decoded =    280, tg =  11.76 t/s
12.33.725.137 I slot print_timing: id  0 | task 3041 | n_decoded =    172, tg =  11.77 t/s
12.36.204.122 I slot print_timing: id  9 | task 2918 | n_decoded =    316, tg =  11.76 t/s
12.36.802.625 I slot print_timing: id  0 | task 3041 | n_decoded =    208, tg =  11.76 t/s
12.39.281.814 I slot print_timing: id  9 | task 2918 | n_decoded =    352, tg =  11.75 t/s
12.39.879.721 I slot print_timing: id  0 | task 3041 | n_decoded =    244, tg =  11.75 t/s
12.42.360.471 I slot print_timing: id  9 | task 2918 | n_decoded =    388, tg =  11.74 t/s
12.42.958.325 I slot print_timing: id  0 | task 3041 | n_decoded =    280, tg =  11.74 t/s
12.43.385.677 I reasoning-budget: deactivated (natural end)
12.45.437.342 I slot print_timing: id  9 | task 2918 | n_decoded =    424, tg =  11.74 t/s
12.46.035.317 I slot print_timing: id  0 | task 3041 | n_decoded =    316, tg =  11.74 t/s
12.48.087.691 I slot print_timing: id  0 | task 3041 | prompt eval time =     456.83 ms /   343 tokens (    1.33 ms per token,   750.82 tokens per second)
12.48.087.695 I slot print_timing: id  0 | task 3041 |        eval time =   28975.68 ms /   340 tokens (   85.22 ms per token,    11.73 tokens per second)
12.48.087.695 I slot print_timing: id  0 | task 3041 |       total time =   29432.51 ms /   683 tokens
12.48.087.696 I slot print_timing: id  0 | task 3041 |    graphs reused =          0
12.48.087.969 I slot      release: id  0 | task 3041 | stop processing: n_tokens = 6567, truncated = 0
12.48.477.719 I slot print_timing: id  9 | task 2918 | n_decoded =    464, tg =  11.85 t/s
12.51.493.076 I slot print_timing: id  9 | task 2918 | n_decoded =    534, tg =  12.66 t/s
12.54.508.269 I slot print_timing: id  9 | task 2918 | n_decoded =    604, tg =  13.37 t/s
12.55.222.251 I srv  params_from_: Chat format: peg-gemma4
12.55.240.629 I slot get_availabl: id  0 | task -1 | selected slot by LCP similarity, sim_best = 0.987 (> 0.100 thold), f_keep = 0.898
12.55.240.726 I slot launch_slot_: id  0 | task 3550 | processing task, is_child = 0
12.55.240.733 I slot update_slots: id  0 | task 3550 | Checking checkpoint with [4862, 6223] against 4870...
12.55.244.771 W slot update_slots: id  0 | task 3550 | restored context checkpoint (pos_min = 4862, pos_max = 6223, n_tokens = 6224, n_past = 5894, size = 170.013 MiB)
12.55.244.773 W slot update_slots: id  0 | task 3550 | erased invalidated context checkpoint (pos_min = 4862, pos_max = 6223, n_tokens = 6224, n_swa = 1024, pos_next = 5894, size = 170.013 MiB)
12.55.546.914 I reasoning-budget: activated, budget=2147483647 tokens
12.57.509.063 I slot print_timing: id  9 | task 2918 | n_decoded =    647, tg =  13.43 t/s
13.00.574.063 I slot print_timing: id  9 | task 2918 | n_decoded =    683, tg =  13.33 t/s
13.03.638.750 I slot print_timing: id  9 | task 2918 | n_decoded =    719, tg =  13.24 t/s
13.03.894.292 I slot print_timing: id  0 | task 3550 | n_decoded =    100, tg =  11.86 t/s
13.06.704.026 I slot print_timing: id  9 | task 2918 | n_decoded =    755, tg =  13.16 t/s
13.06.959.572 I reasoning-budget: deactivated (natural end)
13.06.959.585 I slot print_timing: id  0 | task 3550 | n_decoded =    136, tg =  11.83 t/s
13.09.265.576 I slot print_timing: id  0 | task 3550 | prompt eval time =     219.51 ms /    78 tokens (    2.81 ms per token,   355.33 tokens per second)
13.09.265.579 I slot print_timing: id  0 | task 3550 |        eval time =   13805.32 ms /   163 tokens (   84.70 ms per token,    11.81 tokens per second)
13.09.265.580 I slot print_timing: id  0 | task 3550 |       total time =   14024.83 ms /   241 tokens
13.09.265.581 I slot print_timing: id  0 | task 3550 |    graphs reused =          0
13.09.266.241 I slot      release: id  0 | task 3550 | stop processing: n_tokens = 6134, truncated = 0
13.09.525.656 I srv  params_from_: Chat format: peg-gemma4
13.09.570.636 I slot get_availabl: id  0 | task -1 | selected slot by LCP similarity, sim_best = 0.978 (> 0.100 thold), f_keep = 0.996
13.09.570.727 I slot launch_slot_: id  0 | task 3721 | processing task, is_child = 0
13.09.570.733 I slot update_slots: id  0 | task 3721 | Checking checkpoint with [4350, 5885] against 5083...
13.09.574.726 W slot update_slots: id  0 | task 3721 | restored context checkpoint (pos_min = 4350, pos_max = 5885, n_tokens = 5886, n_past = 5885, size = 170.013 MiB)
13.09.895.141 I slot print_timing: id  9 | task 2918 | n_decoded =    794, tg =  13.11 t/s
13.09.929.999 I slot create_check: id  0 | task 3721 | created context checkpoint 2 of 32 (pos_min = 4862, pos_max = 6238, n_tokens = 6239, size = 170.013 MiB)
13.10.110.704 I reasoning-budget: activated, budget=2147483647 tokens
13.12.938.678 I slot print_timing: id  9 | task 2918 | n_decoded =    829, tg =  13.03 t/s
13.16.020.728 I slot print_timing: id  9 | task 2918 | n_decoded =    865, tg =  12.97 t/s
13.18.502.767 I slot print_timing: id  0 | task 3721 | n_decoded =    100, tg =  11.79 t/s
13.19.101.425 I slot print_timing: id  9 | task 2918 | n_decoded =    901, tg =  12.91 t/s
13.21.583.367 I slot print_timing: id  0 | task 3721 | n_decoded =    136, tg =  11.77 t/s
13.22.182.393 I slot print_timing: id  9 | task 2918 | n_decoded =    937, tg =  12.86 t/s
13.24.665.201 I slot print_timing: id  0 | task 3721 | n_decoded =    172, tg =  11.75 t/s
13.25.265.015 I slot print_timing: id  9 | task 2918 | n_decoded =    973, tg =  12.81 t/s
13.27.747.489 I slot print_timing: id  0 | task 3721 | n_decoded =    208, tg =  11.74 t/s
13.28.347.199 I slot print_timing: id  9 | task 2918 | n_decoded =   1009, tg =  12.77 t/s
13.30.831.364 I slot print_timing: id  0 | task 3721 | n_decoded =    244, tg =  11.73 t/s
13.31.430.947 I slot print_timing: id  9 | task 2918 | n_decoded =   1045, tg =  12.73 t/s
13.33.915.621 I slot print_timing: id  0 | task 3721 | n_decoded =    280, tg =  11.72 t/s
13.34.515.009 I slot print_timing: id  9 | task 2918 | n_decoded =   1081, tg =  12.69 t/s
13.37.000.597 I slot print_timing: id  0 | task 3721 | n_decoded =    316, tg =  11.71 t/s
13.37.600.157 I slot print_timing: id  9 | task 2918 | n_decoded =   1117, tg =  12.65 t/s
13.40.083.208 I slot print_timing: id  0 | task 3721 | n_decoded =    352, tg =  11.71 t/s
13.40.682.739 I slot print_timing: id  9 | task 2918 | n_decoded =   1153, tg =  12.62 t/s
13.42.995.112 I reasoning-budget: deactivated (natural end)
13.43.166.292 I slot print_timing: id  0 | task 3721 | n_decoded =    388, tg =  11.71 t/s
13.43.766.495 I slot print_timing: id  9 | task 2918 | n_decoded =   1189, tg =  12.59 t/s
13.46.249.710 I slot print_timing: id  0 | task 3721 | n_decoded =    424, tg =  11.70 t/s
13.46.850.171 I slot print_timing: id  9 | task 2918 | n_decoded =   1225, tg =  12.56 t/s
13.48.306.501 I slot print_timing: id  0 | task 3721 | prompt eval time =     453.41 ms /   358 tokens (    1.27 ms per token,   789.57 tokens per second)
13.48.306.504 I slot print_timing: id  0 | task 3721 |        eval time =   38282.35 ms /   448 tokens (   85.45 ms per token,    11.70 tokens per second)
13.48.306.505 I slot print_timing: id  0 | task 3721 |       total time =   38735.76 ms /   806 tokens
13.48.306.506 I slot print_timing: id  0 | task 3721 |    graphs reused =          0
13.48.306.778 I slot      release: id  0 | task 3721 | stop processing: n_tokens = 6690, truncated = 0
13.49.868.247 I slot print_timing: id  9 | task 2918 | n_decoded =   1278, tg =  12.71 t/s
13.52.004.560 I srv  params_from_: Chat format: peg-gemma4
13.52.030.049 I slot get_availabl: id  0 | task -1 | selected slot by LCP similarity, sim_best = 0.987 (> 0.100 thold), f_keep = 0.881
13.52.030.148 I slot launch_slot_: id  0 | task 4259 | processing task, is_child = 0
13.52.030.155 I slot update_slots: id  0 | task 4259 | Checking checkpoint with [4862, 6238] against 4870...
13.52.034.197 W slot update_slots: id  0 | task 4259 | restored context checkpoint (pos_min = 4862, pos_max = 6238, n_tokens = 6239, n_past = 5894, size = 170.013 MiB)
13.52.034.199 W slot update_slots: id  0 | task 4259 | erased invalidated context checkpoint (pos_min = 4862, pos_max = 6238, n_tokens = 6239, n_swa = 1024, pos_next = 5894, size = 170.013 MiB)
13.52.334.013 I reasoning-budget: activated, budget=2147483647 tokens
13.52.931.181 I slot print_timing: id  9 | task 2918 | n_decoded =   1338, tg =  12.91 t/s
13.56.000.212 I slot print_timing: id  9 | task 2918 | n_decoded =   1374, tg =  12.88 t/s
13.59.070.587 I slot print_timing: id  9 | task 2918 | n_decoded =   1410, tg =  12.85 t/s
14.00.690.152 I slot print_timing: id  0 | task 4259 | n_decoded =    100, tg =  11.84 t/s
14.02.140.567 I slot print_timing: id  9 | task 2918 | n_decoded =   1446, tg =  12.82 t/s
14.03.759.856 I slot print_timing: id  0 | task 4259 | n_decoded =    136, tg =  11.81 t/s
14.05.208.481 I slot print_timing: id  9 | task 2918 | n_decoded =   1482, tg =  12.79 t/s
14.06.828.226 I slot print_timing: id  0 | task 4259 | n_decoded =    172, tg =  11.80 t/s
14.07.254.167 I slot print_timing: id  9 | task 2918 | prompt eval time =    8962.80 ms / 14095 tokens (    0.64 ms per token,  1572.61 tokens per second)
14.07.254.171 I slot print_timing: id  9 | task 2918 |        eval time =  117932.09 ms /  1506 tokens (   78.31 ms per token,    12.77 tokens per second)
14.07.254.172 I slot print_timing: id  9 | task 2918 |       total time =  126894.90 ms / 15601 tokens
14.07.254.173 I slot print_timing: id  9 | task 2918 |    graphs reused =          0
14.07.254.402 I slot      release: id  9 | task 2918 | stop processing: n_tokens = 15606, truncated = 0
14.07.299.463 I srv  params_from_: Chat format: peg-gemma4
14.07.340.590 I slot get_availabl: id  8 | task -1 | selected slot by LRU, t_last = 527497901376
14.07.340.593 I srv  get_availabl: updating prompt cache
14.07.341.749 W srv   prompt_save:  - saving prompt with length 243, total state size = 42.366 MiB (draft: 0.000 MiB)
14.07.354.031 I srv          load:  - looking for better prompt, base f_keep = 0.045, sim = 0.001
14.07.354.038 I srv        update:  - cache state: 2 prompts, 289.510 MiB (limits: 8192.000 MiB, 2649600 tokens, 2649600 est)
14.07.354.039 I srv        update:    - prompt 0xca58b2f816d0:     890 tokens, checkpoints:  1,   245.815 MiB
14.07.354.039 I srv        update:    - prompt 0xca58b046c470:     243 tokens, checkpoints:  1,    43.695 MiB
14.07.354.040 I srv  get_availabl: prompt cache update took 13.45 ms
14.07.354.102 I slot launch_slot_: id  8 | task 4440 | processing task, is_child = 0
14.07.354.108 I slot update_slots: id  8 | task 4440 | Checking checkpoint with [0, 7] against 0...
14.07.354.814 W slot update_slots: id  8 | task 4440 | restored context checkpoint (pos_min = 0, pos_max = 7, n_tokens = 8, n_past = 7, size = 1.329 MiB)
14.09.793.741 I reasoning-budget: deactivated (natural end)
14.11.008.690 I slot print_timing: id  0 | task 4259 | n_decoded =    183, tg =   9.75 t/s
14.11.008.703 I slot print_timing: id  8 | task 4440 | prompt processing, n_tokens =   6142, progress = 0.41, t =   3.65 s / 1680.62 tokens per second
14.12.247.991 I slot print_timing: id  8 | task 4440 | prompt processing, n_tokens =   8189, progress = 0.55, t =   4.89 s / 1673.31 tokens per second
14.13.529.313 I slot print_timing: id  8 | task 4440 | prompt processing, n_tokens =  10236, progress = 0.68, t =   6.18 s / 1657.60 tokens per second
14.14.852.663 I slot print_timing: id  0 | task 4259 | n_decoded =    186, tg =   8.23 t/s
14.14.852.678 I slot print_timing: id  8 | task 4440 | prompt processing, n_tokens =  12283, progress = 0.82, t =   7.50 s / 1638.05 tokens per second
14.16.214.951 I slot print_timing: id  8 | task 4440 | prompt processing, n_tokens =  14330, progress = 0.96, t =   8.86 s / 1617.23 tokens per second
14.16.374.548 I slot print_timing: id  8 | task 4440 | prompt processing, n_tokens =  14483, progress = 0.97, t =   9.02 s / 1605.58 tokens per second
14.16.420.893 I slot create_check: id  8 | task 4440 | created context checkpoint 2 of 32 (pos_min = 12954, pos_max = 14489, n_tokens = 14490, size = 170.013 MiB)
14.16.798.270 I slot print_timing: id  8 | task 4440 | prompt processing, n_tokens =  14995, progress = 1.00, t =   9.44 s / 1587.75 tokens per second
14.16.840.750 I slot create_check: id  8 | task 4440 | created context checkpoint 3 of 32 (pos_min = 13466, pos_max = 15001, n_tokens = 15002, size = 170.013 MiB)
14.17.873.045 I slot print_timing: id  0 | task 4259 | n_decoded =    201, tg =   7.84 t/s
14.18.554.013 I slot print_timing: id  0 | task 4259 | prompt eval time =     216.49 ms /    78 tokens (    2.78 ms per token,   360.29 tokens per second)
14.18.554.016 I slot print_timing: id  0 | task 4259 |        eval time =   26307.36 ms /   209 tokens (  125.87 ms per token,     7.94 tokens per second)
14.18.554.017 I slot print_timing: id  0 | task 4259 |       total time =   26523.85 ms /   287 tokens
14.18.554.018 I slot print_timing: id  0 | task 4259 |    graphs reused =          0
14.18.554.268 I slot      release: id  0 | task 4259 | stop processing: n_tokens = 6180, truncated = 0
14.18.700.339 I srv  params_from_: Chat format: peg-gemma4
14.18.728.611 I slot get_availabl: id  0 | task -1 | selected slot by LCP similarity, sim_best = 0.978 (> 0.100 thold), f_keep = 0.996
14.18.728.708 I slot launch_slot_: id  0 | task 4475 | processing task, is_child = 0
14.18.728.715 I slot update_slots: id  0 | task 4475 | Checking checkpoint with [4350, 5885] against 5129...
14.18.732.730 W slot update_slots: id  0 | task 4475 | restored context checkpoint (pos_min = 4350, pos_max = 5885, n_tokens = 5886, n_past = 5885, size = 170.013 MiB)
14.19.156.160 I slot create_check: id  0 | task 4475 | created context checkpoint 2 of 32 (pos_min = 4862, pos_max = 6284, n_tokens = 6285, size = 170.013 MiB)
14.19.337.474 I reasoning-budget: activated, budget=2147483647 tokens
14.25.496.025 I slot print_timing: id  8 | task 4440 | n_decoded =    100, tg =  11.68 t/s
14.27.720.855 I slot print_timing: id  0 | task 4475 | n_decoded =    100, tg =  11.80 t/s
14.28.577.075 I slot print_timing: id  8 | task 4440 | n_decoded =    136, tg =  11.68 t/s
14.30.803.213 I slot print_timing: id  0 | task 4475 | n_decoded =    136, tg =  11.77 t/s
14.31.659.964 I slot print_timing: id  8 | task 4440 | n_decoded =    172, tg =  11.68 t/s
14.33.886.390 I slot print_timing: id  0 | task 4475 | n_decoded =    172, tg =  11.75 t/s
14.34.742.690 I slot print_timing: id  8 | task 4440 | n_decoded =    208, tg =  11.68 t/s
14.36.969.717 I slot print_timing: id  0 | task 4475 | n_decoded =    208, tg =  11.74 t/s
14.37.398.167 W srv          stop: cancel task, id_task = 4475
14.37.483.567 I slot      release: id  0 | task 4475 | stop processing: n_tokens = 6502, truncated = 0
14.37.743.724 I slot print_timing: id  8 | task 4440 | n_decoded =    246, tg =  11.82 t/s
14.40.756.592 I slot print_timing: id  8 | task 4440 | n_decoded =    316, tg =  13.27 t/s
14.43.773.882 I slot print_timing: id  8 | task 4440 | n_decoded =    386, tg =  14.38 t/s
14.46.791.094 I slot print_timing: id  8 | task 4440 | n_decoded =    456, tg =  15.27 t/s
14.49.808.314 I slot print_timing: id  8 | task 4440 | n_decoded =    526, tg =  16.00 t/s
14.52.824.908 I slot print_timing: id  8 | task 4440 | n_decoded =    596, tg =  16.61 t/s
14.52.867.923 I slot print_timing: id  8 | task 4440 | prompt eval time =    9580.46 ms / 14999 tokens (    0.64 ms per token,  1565.58 tokens per second)
14.52.867.926 I slot print_timing: id  8 | task 4440 |        eval time =   35933.35 ms /   597 tokens (   60.19 ms per token,    16.61 tokens per second)
14.52.867.927 I slot print_timing: id  8 | task 4440 |       total time =   45513.81 ms / 15596 tokens
14.52.867.928 I slot print_timing: id  8 | task 4440 |    graphs reused =          0
14.52.868.188 I slot      release: id  8 | task 4440 | stop processing: n_tokens = 15602, truncated = 0
14.52.868.195 I srv  update_slots: all slots are idle
15.10.437.511 I srv  params_from_: Chat format: peg-gemma4
15.10.446.962 I slot get_availabl: id  0 | task -1 | selected slot by LCP similarity, sim_best = 1.000 (> 0.100 thold), f_keep = 0.918
15.10.447.172 I slot launch_slot_: id  0 | task 5050 | processing task, is_child = 0
15.10.447.188 I slot update_slots: id  0 | task 5050 | Checking checkpoint with [4862, 6284] against 4947...
15.10.451.361 W slot update_slots: id  0 | task 5050 | restored context checkpoint (pos_min = 4862, pos_max = 6284, n_tokens = 6285, n_past = 5972, size = 170.013 MiB)
15.10.451.363 W slot update_slots: id  0 | task 5050 | erased invalidated context checkpoint (pos_min = 4862, pos_max = 6284, n_tokens = 6285, n_swa = 1024, pos_next = 5972, size = 170.013 MiB)
15.10.465.517 W slot update_slots: id  0 | task 5050 | need to evaluate at least 1 token for each active slot (n_past = 5972, task.n_tokens() = 5972)
15.10.465.518 W slot update_slots: id  0 | task 5050 | n_past was set to 5971
15.10.556.641 I reasoning-budget: activated, budget=2147483647 tokens
15.11.552.218 I srv  params_from_: Chat format: peg-gemma4
15.11.586.264 I slot get_availabl: id  1 | task -1 | selected slot by LCP similarity, sim_best = 0.987 (> 0.100 thold), f_keep = 0.878
15.11.586.388 I slot launch_slot_: id  1 | task 5078 | processing task, is_child = 0
15.11.586.395 I slot update_slots: id  1 | task 5078 | Checking checkpoint with [4740, 6252] against 4870...
15.11.590.437 W slot update_slots: id  1 | task 5078 | restored context checkpoint (pos_min = 4740, pos_max = 6252, n_tokens = 6253, n_past = 5894, size = 170.013 MiB)
15.11.590.439 W slot update_slots: id  1 | task 5078 | erased invalidated context checkpoint (pos_min = 4740, pos_max = 6252, n_tokens = 6253, n_swa = 1024, pos_next = 5894, size = 170.013 MiB)
15.11.850.811 I reasoning-budget: activated, budget=2147483647 tokens
15.12.707.461 I srv  params_from_: Chat format: peg-gemma4
15.12.735.704 I slot get_availabl: id  2 | task -1 | selected slot by LCP similarity, sim_best = 0.987 (> 0.100 thold), f_keep = 0.897
15.12.735.817 I slot launch_slot_: id  2 | task 5102 | processing task, is_child = 0
15.12.735.825 I slot update_slots: id  2 | task 5102 | Checking checkpoint with [4692, 6227] against 4869...
15.12.739.955 W slot update_slots: id  2 | task 5102 | restored context checkpoint (pos_min = 4692, pos_max = 6227, n_tokens = 6228, n_past = 5893, size = 170.013 MiB)
15.12.739.957 W slot update_slots: id  2 | task 5102 | erased invalidated context checkpoint (pos_min = 4692, pos_max = 6227, n_tokens = 6228, n_swa = 1024, pos_next = 5893, size = 170.013 MiB)
15.13.012.546 I reasoning-budget: activated, budget=2147483647 tokens
15.15.293.712 I slot print_timing: id  0 | task 5050 | n_decoded =    100, tg =  20.91 t/s
15.16.648.807 I slot print_timing: id  1 | task 5078 | n_decoded =    100, tg =  20.65 t/s
15.17.720.776 I reasoning-budget: deactivated (natural end)
15.17.769.765 I slot print_timing: id  2 | task 5102 | n_decoded =    100, tg =  20.81 t/s
15.18.302.618 I slot print_timing: id  0 | task 5050 | n_decoded =    162, tg =  20.79 t/s
15.19.037.430 I slot print_timing: id  0 | task 5050 | prompt eval time =      64.05 ms /     1 tokens (   64.05 ms per token,    15.61 tokens per second)
15.19.037.434 I slot print_timing: id  0 | task 5050 |        eval time =    8526.18 ms /   177 tokens (   48.17 ms per token,    20.76 tokens per second)
15.19.037.434 I slot print_timing: id  0 | task 5050 |       total time =    8590.24 ms /   178 tokens
15.19.037.435 I slot print_timing: id  0 | task 5050 |    graphs reused =          0
15.19.037.692 I slot      release: id  0 | task 5050 | stop processing: n_tokens = 6148, truncated = 0
15.19.243.829 I srv  params_from_: Chat format: peg-gemma4
15.19.265.961 I reasoning-budget: deactivated (natural end)
15.19.266.210 I slot get_availabl: id  0 | task -1 | selected slot by LCP similarity, sim_best = 0.978 (> 0.100 thold), f_keep = 0.996
15.19.266.296 I slot launch_slot_: id  0 | task 5235 | processing task, is_child = 0
15.19.266.304 I slot update_slots: id  0 | task 5235 | Checking checkpoint with [4350, 5885] against 5097...
15.19.270.312 W slot update_slots: id  0 | task 5235 | restored context checkpoint (pos_min = 4350, pos_max = 5885, n_tokens = 5886, n_past = 5885, size = 170.013 MiB)
15.19.640.174 I slot create_check: id  0 | task 5235 | created context checkpoint 2 of 32 (pos_min = 4862, pos_max = 6252, n_tokens = 6253, size = 170.013 MiB)
15.19.735.813 I slot print_timing: id  1 | task 5078 | n_decoded =    157, tg =  19.80 t/s
15.19.785.600 I reasoning-budget: activated, budget=2147483647 tokens
15.19.889.328 I reasoning-budget: deactivated (natural end)
15.20.771.661 I slot print_timing: id  2 | task 5102 | n_decoded =    155, tg =  19.85 t/s
15.20.919.146 I slot print_timing: id  1 | task 5078 | prompt eval time =     220.00 ms /    78 tokens (    2.82 ms per token,   354.55 tokens per second)
15.20.919.149 I slot print_timing: id  1 | task 5078 |        eval time =    9112.75 ms /   181 tokens (   50.35 ms per token,    19.86 tokens per second)
15.20.919.149 I slot print_timing: id  1 | task 5078 |       total time =    9332.75 ms /   259 tokens
15.20.919.151 I slot print_timing: id  1 | task 5078 |    graphs reused =          0
15.20.919.552 I slot      release: id  1 | task 5078 | stop processing: n_tokens = 6152, truncated = 0
15.21.111.757 I srv  params_from_: Chat format: peg-gemma4
15.21.172.880 I slot get_availabl: id  1 | task -1 | selected slot by LCP similarity, sim_best = 0.978 (> 0.100 thold), f_keep = 0.996
15.21.172.975 I slot launch_slot_: id  1 | task 5266 | processing task, is_child = 0
15.21.172.983 I slot update_slots: id  1 | task 5266 | Checking checkpoint with [4350, 5885] against 5101...
15.21.177.007 W slot update_slots: id  1 | task 5266 | restored context checkpoint (pos_min = 4350, pos_max = 5885, n_tokens = 5886, n_past = 5885, size = 170.013 MiB)
15.21.599.865 I slot create_check: id  1 | task 5266 | created context checkpoint 2 of 32 (pos_min = 4862, pos_max = 6256, n_tokens = 6257, size = 170.013 MiB)
15.21.735.264 I slot print_timing: id  2 | task 5102 | prompt eval time =     228.51 ms /    79 tokens (    2.89 ms per token,   345.71 tokens per second)
15.21.735.266 I slot print_timing: id  2 | task 5102 |        eval time =    8770.92 ms /   164 tokens (   53.48 ms per token,    18.70 tokens per second)
15.21.735.267 I slot print_timing: id  2 | task 5102 |       total time =    8999.44 ms /   243 tokens
15.21.735.268 I slot print_timing: id  2 | task 5102 |    graphs reused =          0
15.21.735.547 I slot      release: id  2 | task 5102 | stop processing: n_tokens = 6135, truncated = 0
15.21.782.170 I reasoning-budget: activated, budget=2147483647 tokens
15.21.918.294 I srv  params_from_: Chat format: peg-gemma4
15.21.968.658 I slot get_availabl: id  2 | task -1 | selected slot by LCP similarity, sim_best = 0.978 (> 0.100 thold), f_keep = 0.996
15.21.968.753 I slot launch_slot_: id  2 | task 5274 | processing task, is_child = 0
15.21.968.760 I slot update_slots: id  2 | task 5274 | Checking checkpoint with [4350, 5885] against 5084...
15.21.972.777 W slot update_slots: id  2 | task 5274 | restored context checkpoint (pos_min = 4350, pos_max = 5885, n_tokens = 5886, n_past = 5885, size = 170.013 MiB)
15.22.318.813 I slot create_check: id  2 | task 5274 | created context checkpoint 2 of 32 (pos_min = 4862, pos_max = 6239, n_tokens = 6240, size = 170.013 MiB)
15.22.467.970 I reasoning-budget: activated, budget=2147483647 tokens
15.25.472.247 I slot print_timing: id  0 | task 5235 | n_decoded =    100, tg =  17.43 t/s
15.26.974.006 I slot print_timing: id  1 | task 5266 | n_decoded =    100, tg =  19.09 t/s
15.27.372.963 I slot print_timing: id  2 | task 5274 | n_decoded =    100, tg =  20.18 t/s
15.28.476.482 I slot print_timing: id  0 | task 5235 | n_decoded =    160, tg =  18.30 t/s
15.29.980.232 I slot print_timing: id  1 | task 5266 | n_decoded =    160, tg =  19.41 t/s
15.30.380.911 I slot print_timing: id  2 | task 5274 | n_decoded =    160, tg =  20.09 t/s
15.31.481.235 I slot print_timing: id  0 | task 5235 | n_decoded =    220, tg =  18.73 t/s
15.32.988.258 I slot print_timing: id  1 | task 5266 | n_decoded =    220, tg =  19.55 t/s
15.33.391.468 I slot print_timing: id  2 | task 5274 | n_decoded =    220, tg =  20.05 t/s
15.33.844.901 I reasoning-budget: deactivated (natural end)
15.34.498.099 I slot print_timing: id  0 | task 5235 | n_decoded =    280, tg =  18.97 t/s
15.36.006.383 I slot print_timing: id  1 | task 5266 | n_decoded =    280, tg =  19.62 t/s
15.36.413.578 I slot print_timing: id  2 | task 5274 | n_decoded =    280, tg =  20.01 t/s
15.36.965.324 I slot print_timing: id  0 | task 5235 | prompt eval time =     469.24 ms /   372 tokens (    1.26 ms per token,   792.77 tokens per second)
15.36.965.327 I slot print_timing: id  0 | task 5235 |        eval time =   17229.78 ms /   329 tokens (   52.37 ms per token,    19.09 tokens per second)
15.36.965.328 I slot print_timing: id  0 | task 5235 |       total time =   17699.02 ms /   701 tokens
15.36.965.329 I slot print_timing: id  0 | task 5235 |    graphs reused =          0
15.36.965.608 I slot      release: id  0 | task 5235 | stop processing: n_tokens = 6585, truncated = 0
15.38.063.438 I reasoning-budget: deactivated (natural end)
15.39.017.034 I slot print_timing: id  1 | task 5266 | n_decoded =    344, tg =  19.91 t/s
15.39.426.147 I slot print_timing: id  2 | task 5274 | n_decoded =    345, tg =  20.28 t/s
15.40.880.093 I slot print_timing: id  2 | task 5274 | prompt eval time =     449.30 ms /   359 tokens (    1.25 ms per token,   799.02 tokens per second)
15.40.880.096 I slot print_timing: id  2 | task 5274 |        eval time =   18462.04 ms /   377 tokens (   48.97 ms per token,    20.42 tokens per second)
15.40.880.097 I slot print_timing: id  2 | task 5274 |       total time =   18911.33 ms /   736 tokens
15.40.880.098 I slot print_timing: id  2 | task 5274 |    graphs reused =          0
15.40.880.370 I slot      release: id  2 | task 5274 | stop processing: n_tokens = 6620, truncated = 0
15.42.053.220 I slot print_timing: id  1 | task 5266 | n_decoded =    413, tg =  20.33 t/s
15.43.010.738 I reasoning-budget: deactivated (natural end)
15.45.090.352 I slot print_timing: id  1 | task 5266 | n_decoded =    486, tg =  20.81 t/s
15.45.589.836 I slot print_timing: id  1 | task 5266 | prompt eval time =     562.04 ms /   376 tokens (    1.49 ms per token,   668.99 tokens per second)
15.45.589.838 I slot print_timing: id  1 | task 5266 |        eval time =   23854.81 ms /   498 tokens (   47.90 ms per token,    20.88 tokens per second)
15.45.589.839 I slot print_timing: id  1 | task 5266 |       total time =   24416.85 ms /   874 tokens
15.45.589.840 I slot print_timing: id  1 | task 5266 |    graphs reused =          0
15.45.590.108 I slot      release: id  1 | task 5266 | stop processing: n_tokens = 6758, truncated = 0
15.45.590.140 I srv  update_slots: all slots are idle
21.05.948.955 I srv  params_from_: Chat format: peg-gemma4
21.05.957.991 I slot get_availabl: id  9 | task -1 | selected slot by LCP similarity, sim_best = 0.937 (> 0.100 thold), f_keep = 0.904
21.05.958.139 I slot launch_slot_: id  9 | task 5768 | processing task, is_child = 0
21.05.958.161 I slot update_slots: id  9 | task 5768 | Checking checkpoint with [12561, 14096] against 13077...
21.05.962.288 W slot update_slots: id  9 | task 5768 | restored context checkpoint (pos_min = 12561, pos_max = 14096, n_tokens = 14097, n_past = 14096, size = 170.013 MiB)
21.06.418.973 I slot create_check: id  9 | task 5768 | created context checkpoint 4 of 32 (pos_min = 13235, pos_max = 14770, n_tokens = 14771, size = 170.013 MiB)
21.06.447.059 I srv  process_chun: processing image...
21.07.374.361 I srv  process_chun: image processed in 927 ms
21.07.881.016 I slot create_check: id  9 | task 5768 | created context checkpoint 5 of 32 (pos_min = 13503, pos_max = 15038, n_tokens = 15039, size = 170.013 MiB)
21.12.194.706 I slot print_timing: id  9 | task 5768 | n_decoded =    100, tg =  23.46 t/s
21.15.206.733 I slot print_timing: id  9 | task 5768 | n_decoded =    170, tg =  23.37 t/s
21.18.218.062 I slot print_timing: id  9 | task 5768 | n_decoded =    240, tg =  23.33 t/s
21.21.229.881 I slot print_timing: id  9 | task 5768 | n_decoded =    310, tg =  23.31 t/s
21.24.251.263 I slot print_timing: id  9 | task 5768 | n_decoded =    380, tg =  23.29 t/s
21.27.273.075 I slot print_timing: id  9 | task 5768 | n_decoded =    450, tg =  23.27 t/s
21.30.295.998 I slot print_timing: id  9 | task 5768 | n_decoded =    520, tg =  23.25 t/s
21.33.326.244 I slot print_timing: id  9 | task 5768 | n_decoded =    590, tg =  23.23 t/s
21.36.354.314 I slot print_timing: id  9 | task 5768 | n_decoded =    660, tg =  23.22 t/s
21.39.384.688 I slot print_timing: id  9 | task 5768 | n_decoded =    730, tg =  23.21 t/s
21.42.410.895 I slot print_timing: id  9 | task 5768 | n_decoded =    800, tg =  23.20 t/s
21.45.437.054 I slot print_timing: id  9 | task 5768 | n_decoded =    870, tg =  23.20 t/s
21.48.453.561 I slot print_timing: id  9 | task 5768 | n_decoded =    940, tg =  23.20 t/s
21.51.471.900 I slot print_timing: id  9 | task 5768 | n_decoded =   1010, tg =  23.20 t/s
21.54.491.750 I slot print_timing: id  9 | task 5768 | n_decoded =   1080, tg =  23.20 t/s
21.57.524.722 I slot print_timing: id  9 | task 5768 | n_decoded =   1150, tg =  23.19 t/s
22.00.555.999 I slot print_timing: id  9 | task 5768 | n_decoded =   1220, tg =  23.18 t/s
22.02.463.555 I slot print_timing: id  9 | task 5768 | prompt eval time =    1973.89 ms /   947 tokens (    2.08 ms per token,   479.76 tokens per second)
22.02.463.557 I slot print_timing: id  9 | task 5768 |        eval time =   54531.51 ms /  1264 tokens (   43.14 ms per token,    23.18 tokens per second)
22.02.463.558 I slot print_timing: id  9 | task 5768 |       total time =   56505.40 ms /  2211 tokens
22.02.463.559 I slot print_timing: id  9 | task 5768 |    graphs reused =          0
22.02.463.813 I slot      release: id  9 | task 5768 | stop processing: n_tokens = 16306, truncated = 0
22.02.463.834 I srv  update_slots: all slots are idle
22.02.497.241 I srv  params_from_: Chat format: peg-gemma4
22.02.497.367 I slot get_availabl: id  8 | task -1 | selected slot by LCP similarity, sim_best = 0.962 (> 0.100 thold), f_keep = 0.961
22.02.497.433 I slot launch_slot_: id  8 | task 7037 | processing task, is_child = 0
22.02.497.450 I slot update_slots: id  8 | task 7037 | Checking checkpoint with [13466, 15001] against 13972...
22.02.501.535 W slot update_slots: id  8 | task 7037 | restored context checkpoint (pos_min = 13466, pos_max = 15001, n_tokens = 15002, n_past = 14996, size = 170.013 MiB)
22.02.501.537 W slot update_slots: id  8 | task 7037 | erased invalidated context checkpoint (pos_min = 13466, pos_max = 15001, n_tokens = 15002, n_swa = 1024, pos_next = 14996, size = 170.013 MiB)
22.02.615.933 I slot create_check: id  8 | task 7037 | created context checkpoint 3 of 32 (pos_min = 13978, pos_max = 15071, n_tokens = 15072, size = 170.013 MiB)
22.02.963.408 I slot create_check: id  8 | task 7037 | created context checkpoint 4 of 32 (pos_min = 14048, pos_max = 15583, n_tokens = 15584, size = 170.013 MiB)
22.07.301.276 I slot print_timing: id  8 | task 7037 | n_decoded =    100, tg =  23.33 t/s
22.10.327.925 I slot print_timing: id  8 | task 7037 | n_decoded =    170, tg =  23.25 t/s
22.13.354.358 I slot print_timing: id  8 | task 7037 | n_decoded =    240, tg =  23.21 t/s
22.16.386.495 I slot print_timing: id  8 | task 7037 | n_decoded =    310, tg =  23.18 t/s
22.19.416.097 I slot print_timing: id  8 | task 7037 | n_decoded =    380, tg =  23.17 t/s
22.22.445.778 I slot print_timing: id  8 | task 7037 | n_decoded =    450, tg =  23.16 t/s
22.25.477.157 I slot print_timing: id  8 | task 7037 | n_decoded =    520, tg =  23.15 t/s
22.28.516.163 I slot print_timing: id  8 | task 7037 | n_decoded =    590, tg =  23.14 t/s
22.31.551.286 I slot print_timing: id  8 | task 7037 | n_decoded =    660, tg =  23.13 t/s
22.32.201.404 I slot print_timing: id  8 | task 7037 | prompt eval time =     517.20 ms /   592 tokens (    0.87 ms per token,  1144.64 tokens per second)
22.32.201.407 I slot print_timing: id  8 | task 7037 |        eval time =   29186.77 ms /   675 tokens (   43.24 ms per token,    23.13 tokens per second)
22.32.201.408 I slot print_timing: id  8 | task 7037 |       total time =   29703.96 ms /  1267 tokens
22.32.201.409 I slot print_timing: id  8 | task 7037 |    graphs reused =          0
22.32.201.702 I slot      release: id  8 | task 7037 | stop processing: n_tokens = 16262, truncated = 0
22.32.201.715 I srv  update_slots: all slots are idle
```
