# docker compose

```yml

ervices:
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
      - "-hf"
      - "unsloth/gemma-4-12b-it-GGUF:UD-Q4_K_XL"

      # --- SPECULATIVE DECODING / MTP (NOW ACTIVE & STABLE) ---
      # 1. ASSISTANT MODEL (Specify the GGUF version of the assistant)
      # auto discovery is used
      # - "--model-draft"
      # - "MTP/gemma-4-12b-it-BF16-MTP.gguf"
      # 2. MTP SPECULATION SETTINGS
      - "--spec-type"
      - "draft-mtp"
      - "--spec-draft-n-max"
      - "4" 

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
      - "--parallel"
      - "10"

      # Required for Gemma 4 chat template and native thinking token handling.
      - "--jinja"

      # --- SAMPLING (Gemma 4 standard) ---
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

# llama cpp log

```log
warn: LLAMA_ARG_HOST environment variable is set, but will be overwritten by command line argument --host
0.00.786.256 I log_info: verbosity = 3 (adjust with the `-lv N` CLI arg)
0.00.786.259 I device_info:
0.00.877.116 I   - CUDA0   : NVIDIA GB10 (124544 MiB, 116510 MiB free)
0.00.877.126 I   - CPU     : CPU (124544 MiB, 124544 MiB free)
0.00.877.208 I system_info: n_threads = 20 (n_threads_batch = 20) / 20 | CUDA : ARCHS = 750,800,860,890,900,1200,1210 | USE_GRAPHS = 1 | PEER_MAX_BATCH_SIZE = 128 | BLACKWELL_NATIVE_FP4 = 1 | CPU : NEON = 1 | ARM_FMA = 1 | FP16_VA = 1 | MATMUL_INT8 = 1 | SVE = 1 | DOTPROD = 1 | SVE_CNT = 16 | OPENMP = 1 | REPACK = 1 | 
0.00.877.236 I srv          init: running without SSL
0.00.877.247 I srv          init: api_keys: ****eiro
0.00.877.275 I srv          init: using 19 threads for HTTP server
0.00.877.459 I srv         start: binding port with default address family
0.00.878.582 I srv  llama_server: loading model
0.00.878.589 I srv    load_model: loading model '/root/.cache/huggingface/hub/models--unsloth--gemma-4-12b-it-GGUF/snapshots/3249fa54d5efa384afc552cc6700ad091efd5c39/gemma-4-12b-it-UD-Q4_K_XL.gguf'
0.01.175.535 I srv    load_model: [mtmd] estimated worst-case memory usage of mmproj is 354.46 MiB
0.02.390.520 E llama_init_from_model: failed to initialize the context: Gemma4Assistant requires ctx_other to be set (this warning is normal during memory fitting)
0.02.477.130 W srv    load_model: [spec] failed to measure draft model memory: failed to create llama_context from model
0.02.477.151 I common_init_result: fitting params to device memory ...
0.02.477.152 I common_init_result: (for bugs during this step try to reproduce them with -fit off, or provide --verbose logs if the bug only occurs with -fit on)
0.04.266.658 W load: control-looking token:    212 '</s>' was not control-type; this is probably a bug in the model. its type will be overridden
0.04.267.049 W load: control-looking token:     50 '<|tool_response>' was not control-type; this is probably a bug in the model. its type will be overridden
0.04.272.442 W load: control-looking token:      1 '<eos>' was not control-type; this is probably a bug in the model. its type will be overridden
0.04.288.681 W load: special_eog_ids contains '<|tool_response>', removing '</s>' token from EOG list
0.05.180.150 W warning: failed to mlock 707899392-byte buffer (after previously locking 0 bytes): Cannot allocate memory
Try increasing RLIMIT_MEMLOCK ('ulimit -l' as root).
0.05.499.618 W llama_context: n_ctx_seq (264960) > n_ctx_train (262144) -- possible training context overflow
0.06.700.214 I common_init_from_params: warming up the model with an empty run - please wait ... (--no-warmup to disable)
0.06.908.955 I srv    load_model: loading draft model '/root/.cache/huggingface/hub/models--unsloth--gemma-4-12b-it-GGUF/snapshots/3249fa54d5efa384afc552cc6700ad091efd5c39/mtp-gemma-4-12b-it.gguf'
0.07.251.106 W load: control-looking token:    212 '</s>' was not control-type; this is probably a bug in the model. its type will be overridden
0.07.251.519 W load: control-looking token:     50 '<|tool_response>' was not control-type; this is probably a bug in the model. its type will be overridden
0.07.271.494 W load: special_eog_ids contains '<|tool_response>', removing '</s>' token from EOG list
0.07.313.939 W warning: failed to mlock 300982272-byte buffer (after previously locking 0 bytes): Cannot allocate memory
Try increasing RLIMIT_MEMLOCK ('ulimit -l' as root).
0.07.513.998 W llama_context: n_ctx_seq (264960) > n_ctx_train (262144) -- possible training context overflow
0.07.526.607 W llama_kv_cache: layer   3: sharing with layer 47. k = 0xe31092c88000, v = 0xe310e8b24000
0.07.526.732 W llama_kv_cache: layer   0: sharing with layer 46. k = 0xe314bb640000, v = 0xe314bd620000
0.07.526.733 W llama_kv_cache: layer   1: sharing with layer 46. k = 0xe314bb640000, v = 0xe314bd620000
0.07.526.734 W llama_kv_cache: layer   2: sharing with layer 46. k = 0xe314bb640000, v = 0xe314bd620000
0.07.878.961 W init_audio: audio input is in experimental stage and may have reduced quality:
    https://github.com/ggml-org/llama.cpp/discussions/13759
0.07.878.970 I srv    load_model: loaded multimodal model, '/root/.cache/huggingface/hub/models--unsloth--gemma-4-12b-it-GGUF/snapshots/3249fa54d5efa384afc552cc6700ad091efd5c39/mmproj-BF16.gguf'
0.07.878.981 I srv    load_model: initializing slots, n_slots = 10
0.07.878.984 W srv    load_model: the slot context (264960) exceeds the training context of the model (262144) - capping
0.08.203.031 I common_speculative_impl_draft_mtp: adding speculative implementation 'draft-mtp'
0.08.203.038 I common_speculative_impl_draft_mtp: - n_max=4, n_min=0, p_min=0.00, n_embd=3840, backend_sampling=1
0.08.203.040 I common_speculative_impl_draft_mtp: - gpu_layers=-1, cache_k=f16, cache_v=f16, ctx_tgt=yes, ctx_dft=yes, devices=[default]
0.08.595.825 I srv    load_model: speculative decoding context initialized
0.08.595.833 I slot   load_model: id  0 | task -1 | new slot, n_ctx = 262144
0.08.595.843 I slot   load_model: id  1 | task -1 | new slot, n_ctx = 262144
0.08.595.844 I slot   load_model: id  2 | task -1 | new slot, n_ctx = 262144
0.08.595.844 I slot   load_model: id  3 | task -1 | new slot, n_ctx = 262144
0.08.595.844 I slot   load_model: id  4 | task -1 | new slot, n_ctx = 262144
0.08.595.845 I slot   load_model: id  5 | task -1 | new slot, n_ctx = 262144
0.08.595.845 I slot   load_model: id  6 | task -1 | new slot, n_ctx = 262144
0.08.595.845 I slot   load_model: id  7 | task -1 | new slot, n_ctx = 262144
0.08.595.845 I slot   load_model: id  8 | task -1 | new slot, n_ctx = 262144
0.08.595.845 I slot   load_model: id  9 | task -1 | new slot, n_ctx = 262144
0.08.595.892 I srv    load_model: prompt cache is enabled, size limit: 8192 MiB
0.08.595.892 I srv    load_model: use `--cache-ram 0` to disable the prompt cache
0.08.595.892 I srv    load_model: for more info see https://github.com/ggml-org/llama.cpp/pull/16391
0.08.595.892 I srv    load_model: context checkpoints enabled, max = 32, min spacing = 256
0.08.595.905 I srv          init: idle slots will be saved to prompt cache upon starting a new task
0.08.601.453 I init: chat template, example_format: '<|turn>system
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
0.08.601.896 I srv          init: init: chat template, thinking = 1
0.08.601.926 I srv  llama_server: model loaded
0.08.601.929 I srv  llama_server: server is listening on http://0.0.0.0:8000
0.08.601.933 I srv  update_slots: all slots are idle
3.38.505.431 I srv  params_from_: Chat format: peg-gemma4
3.38.505.567 I slot get_availabl: id  9 | task -1 | selected slot by LRU, t_last = -1
3.38.505.570 I srv  get_availabl: updating prompt cache
3.38.505.575 I srv          load:  - looking for better prompt, base f_keep = -1.000, sim = 0.000
3.38.505.579 I srv        update:  - cache state: 0 prompts, 0.000 MiB (limits: 8192.000 MiB, 2649600 tokens, 8589934592 est)
3.38.505.580 I srv  get_availabl: prompt cache update took 0.01 ms
3.38.505.636 I slot launch_slot_: id  9 | task 0 | processing task, is_child = 0
3.38.505.638 I slot process_sing: id  0 | task -1 | saving idle slot to prompt cache
3.38.505.638 I slot process_sing: id  1 | task -1 | saving idle slot to prompt cache
3.38.505.639 I slot process_sing: id  2 | task -1 | saving idle slot to prompt cache
3.38.505.639 I slot process_sing: id  3 | task -1 | saving idle slot to prompt cache
3.38.505.639 I slot process_sing: id  4 | task -1 | saving idle slot to prompt cache
3.38.505.639 I slot process_sing: id  5 | task -1 | saving idle slot to prompt cache
3.38.505.640 I slot process_sing: id  6 | task -1 | saving idle slot to prompt cache
3.38.505.640 I slot process_sing: id  7 | task -1 | saving idle slot to prompt cache
3.38.505.642 I slot process_sing: id  8 | task -1 | saving idle slot to prompt cache
3.38.578.504 I slot create_check: id  9 | task 0 | created context checkpoint 1 of 32 (pos_min = 0, pos_max = 7, n_tokens = 8, size = 1.329 MiB)
3.39.996.561 I slot print_timing: id  9 | task 0 | prompt eval time =     176.94 ms /    22 tokens (    8.04 ms per token,   124.34 tokens per second)
3.39.996.567 I slot print_timing: id  9 | task 0 |        eval time =    1313.86 ms /    90 tokens (   14.60 ms per token,    68.50 tokens per second)
3.39.996.568 I slot print_timing: id  9 | task 0 |       total time =    1490.79 ms /   112 tokens
3.39.996.572 I slot print_timing: id  9 | task 0 |    graphs reused =         25
3.39.996.573 I slot print_timing: id  9 | task 0 | draft acceptance = 0.65000 (   65 accepted /   100 generated)
3.39.996.593 I statistics        draft-mtp: #calls(b,g,a) =    1     25     25, #gen drafts =     25, #acc drafts =    21, #gen tokens =    100, #acc tokens =    65, dur(b,g,a) = 0.003, 227.012, 0.006 ms
3.39.996.620 I slot      release: id  9 | task 0 | stop processing: n_tokens = 112, truncated = 0
3.39.996.625 I srv  update_slots: all slots are idle
6.34.465.611 W srv    operator(): unauthorized: Invalid API Key
13.09.821.269 I srv  params_from_: Chat format: peg-gemma4
13.09.821.440 I slot get_availabl: id  9 | task -1 | selected slot by LCP similarity, sim_best = 0.500 (> 0.100 thold), f_keep = 0.098
13.09.821.445 I srv  get_availabl: updating prompt cache
13.09.823.079 W srv   prompt_save:  - saving prompt with length 112, total state size = 19.527 MiB (draft: 0.000 MiB)
13.09.830.430 I srv          load:  - looking for better prompt, base f_keep = 0.098, sim = 0.500
13.09.830.444 I srv        update:  - cache state: 1 prompts, 20.856 MiB (limits: 8192.000 MiB, 2649600 tokens, 2649600 est)
13.09.830.446 I srv        update:    - prompt 0xb639a4cacf50:     112 tokens, checkpoints:  1,    20.856 MiB
13.09.830.447 I srv  get_availabl: prompt cache update took 9.00 ms
13.09.830.515 I slot launch_slot_: id  9 | task 29 | processing task, is_child = 0
13.09.830.516 I slot process_sing: id  0 | task -1 | saving idle slot to prompt cache
13.09.830.517 I slot process_sing: id  1 | task -1 | saving idle slot to prompt cache
13.09.830.517 I slot process_sing: id  2 | task -1 | saving idle slot to prompt cache
13.09.830.518 I slot process_sing: id  3 | task -1 | saving idle slot to prompt cache
13.09.830.518 I slot process_sing: id  4 | task -1 | saving idle slot to prompt cache
13.09.830.519 I slot process_sing: id  5 | task -1 | saving idle slot to prompt cache
13.09.830.519 I slot process_sing: id  6 | task -1 | saving idle slot to prompt cache
13.09.830.519 I slot process_sing: id  7 | task -1 | saving idle slot to prompt cache
13.09.830.519 I slot process_sing: id  8 | task -1 | saving idle slot to prompt cache
13.09.830.531 I slot update_slots: id  9 | task 29 | Checking checkpoint with [0, 7] against 0...
13.09.831.381 W slot update_slots: id  9 | task 29 | restored context checkpoint (pos_min = 0, pos_max = 7, n_tokens = 8, n_past = 7, size = 1.329 MiB)
13.11.369.727 I slot print_timing: id  9 | task 29 | prompt eval time =     154.95 ms /    15 tokens (   10.33 ms per token,    96.81 tokens per second)
13.11.369.731 I slot print_timing: id  9 | task 29 |        eval time =    1384.13 ms /    79 tokens (   17.52 ms per token,    57.08 tokens per second)
13.11.369.731 I slot print_timing: id  9 | task 29 |       total time =    1539.07 ms /    94 tokens
13.11.369.732 I slot print_timing: id  9 | task 29 |    graphs reused =         47
13.11.369.733 I slot print_timing: id  9 | task 29 | draft acceptance = 0.61957 (   57 accepted /    92 generated)
13.11.369.747 I statistics        draft-mtp: #calls(b,g,a) =    2     48     48, #gen drafts =     48, #acc drafts =    39, #gen tokens =    192, #acc tokens =   122, dur(b,g,a) = 0.005, 460.368, 0.019 ms
13.11.369.761 I slot      release: id  9 | task 29 | stop processing: n_tokens = 102, truncated = 0
13.11.369.772 I srv  update_slots: all slots are idle
13.11.385.976 I srv  params_from_: Chat format: peg-gemma4
13.11.386.227 I slot get_availabl: id  8 | task -1 | selected slot by LRU, t_last = -1
13.11.386.230 I srv  get_availabl: updating prompt cache
13.11.386.233 I srv          load:  - looking for better prompt, base f_keep = -1.000, sim = 0.000
13.11.386.236 I srv        update:  - cache state: 1 prompts, 20.856 MiB (limits: 8192.000 MiB, 2649600 tokens, 2649600 est)
13.11.386.251 I srv        update:    - prompt 0xb639a4cacf50:     112 tokens, checkpoints:  1,    20.856 MiB
13.11.386.252 I srv  get_availabl: prompt cache update took 0.02 ms
13.11.386.284 I slot launch_slot_: id  8 | task 56 | processing task, is_child = 0
13.11.386.286 I slot process_sing: id  0 | task -1 | saving idle slot to prompt cache
13.11.386.286 I slot process_sing: id  1 | task -1 | saving idle slot to prompt cache
13.11.386.287 I slot process_sing: id  2 | task -1 | saving idle slot to prompt cache
13.11.386.287 I slot process_sing: id  3 | task -1 | saving idle slot to prompt cache
13.11.386.287 I slot process_sing: id  4 | task -1 | saving idle slot to prompt cache
13.11.386.288 I slot process_sing: id  5 | task -1 | saving idle slot to prompt cache
13.11.386.289 I slot process_sing: id  6 | task -1 | saving idle slot to prompt cache
13.11.386.289 I slot process_sing: id  7 | task -1 | saving idle slot to prompt cache
13.11.386.289 I slot process_sing: id  9 | task -1 | saving idle slot to prompt cache
13.11.387.607 W srv   prompt_save:  - saving prompt with length 102, total state size = 17.784 MiB (draft: 0.000 MiB)
13.11.393.922 I srv        update:  - cache state: 2 prompts, 39.969 MiB (limits: 8192.000 MiB, 2649600 tokens, 2649600 est)
13.11.393.926 I srv        update:    - prompt 0xb639a4cacf50:     112 tokens, checkpoints:  1,    20.856 MiB
13.11.393.926 I srv        update:    - prompt 0xb63981c727c0:     102 tokens, checkpoints:  1,    19.113 MiB
13.11.453.883 I slot create_check: id  8 | task 56 | created context checkpoint 1 of 32 (pos_min = 0, pos_max = 7, n_tokens = 8, size = 1.329 MiB)
13.11.614.127 I slot create_check: id  8 | task 56 | created context checkpoint 2 of 32 (pos_min = 0, pos_max = 270, n_tokens = 271, size = 44.994 MiB)
13.13.350.162 I slot print_timing: id  8 | task 56 | n_decoded =    102, tg =  60.56 t/s
13.16.380.867 I slot print_timing: id  8 | task 56 | n_decoded =    286, tg =  60.66 t/s
13.18.044.995 I slot print_timing: id  8 | task 56 | prompt eval time =     271.87 ms /   275 tokens (    0.99 ms per token,  1011.53 tokens per second)
13.18.045.000 I slot print_timing: id  8 | task 56 |        eval time =    6379.07 ms /   397 tokens (   16.07 ms per token,    62.23 tokens per second)
13.18.045.000 I slot print_timing: id  8 | task 56 |       total time =    6650.94 ms /   672 tokens
13.18.045.001 I slot print_timing: id  8 | task 56 |    graphs reused =        159
13.18.045.002 I slot print_timing: id  8 | task 56 | draft acceptance = 0.62061 (  283 accepted /   456 generated)
13.18.045.017 I statistics        draft-mtp: #calls(b,g,a) =    3    162    162, #gen drafts =    162, #acc drafts =   134, #gen tokens =    648, #acc tokens =   405, dur(b,g,a) = 0.006, 1539.078, 0.076 ms
13.18.045.052 I slot      release: id  8 | task 56 | stop processing: n_tokens = 672, truncated = 0
13.18.045.060 I srv  update_slots: all slots are idle
13.18.060.387 I srv  params_from_: Chat format: peg-gemma4
13.18.060.489 I slot get_availabl: id  7 | task -1 | selected slot by LRU, t_last = -1
13.18.060.491 I srv  get_availabl: updating prompt cache
13.18.060.494 I srv          load:  - looking for better prompt, base f_keep = -1.000, sim = 0.000
13.18.060.497 I srv        update:  - cache state: 2 prompts, 39.969 MiB (limits: 8192.000 MiB, 2649600 tokens, 2649600 est)
13.18.060.498 I srv        update:    - prompt 0xb639a4cacf50:     112 tokens, checkpoints:  1,    20.856 MiB
13.18.060.498 I srv        update:    - prompt 0xb63981c727c0:     102 tokens, checkpoints:  1,    19.113 MiB
13.18.060.499 I srv  get_availabl: prompt cache update took 0.01 ms
13.18.060.550 I slot launch_slot_: id  7 | task 174 | processing task, is_child = 0
13.18.060.551 I slot process_sing: id  0 | task -1 | saving idle slot to prompt cache
13.18.060.551 I slot process_sing: id  1 | task -1 | saving idle slot to prompt cache
13.18.060.552 I slot process_sing: id  2 | task -1 | saving idle slot to prompt cache
13.18.060.552 I slot process_sing: id  3 | task -1 | saving idle slot to prompt cache
13.18.060.552 I slot process_sing: id  4 | task -1 | saving idle slot to prompt cache
13.18.060.552 I slot process_sing: id  5 | task -1 | saving idle slot to prompt cache
13.18.060.553 I slot process_sing: id  6 | task -1 | saving idle slot to prompt cache
13.18.060.553 I slot process_sing: id  8 | task -1 | saving idle slot to prompt cache
13.18.061.569 W srv   prompt_save:  - saving prompt with length 672, total state size = 117.157 MiB (draft: 0.000 MiB)
13.18.103.786 I srv        update:  - cache state: 3 prompts, 203.450 MiB (limits: 8192.000 MiB, 2649600 tokens, 2649600 est)
13.18.103.794 I srv        update:    - prompt 0xb639a4cacf50:     112 tokens, checkpoints:  1,    20.856 MiB
13.18.103.794 I srv        update:    - prompt 0xb63981c727c0:     102 tokens, checkpoints:  1,    19.113 MiB
13.18.103.795 I srv        update:    - prompt 0xb639a46dfdf0:     672 tokens, checkpoints:  2,   163.481 MiB
13.18.103.796 I slot process_sing: id  9 | task -1 | saving idle slot to prompt cache
13.18.104.704 W srv   prompt_save:  - saving prompt with length 102, total state size = 17.784 MiB (draft: 0.000 MiB)
13.18.104.706 I srv         alloc:  - prompt is already in the cache, skipping
13.18.170.453 I slot create_check: id  7 | task 174 | created context checkpoint 1 of 32 (pos_min = 0, pos_max = 7, n_tokens = 8, size = 1.329 MiB)
13.18.360.470 I slot create_check: id  7 | task 174 | created context checkpoint 2 of 32 (pos_min = 0, pos_max = 325, n_tokens = 326, size = 54.126 MiB)
13.19.988.573 I slot print_timing: id  7 | task 174 | n_decoded =    100, tg =  63.31 t/s
13.23.009.806 I slot print_timing: id  7 | task 174 | n_decoded =    275, tg =  59.77 t/s
13.26.059.555 I slot print_timing: id  7 | task 174 | n_decoded =    467, tg =  61.04 t/s
13.29.098.283 I slot print_timing: id  7 | task 174 | n_decoded =    669, tg =  62.59 t/s
13.32.115.467 I slot print_timing: id  7 | task 174 | n_decoded =    841, tg =  61.36 t/s
13.32.291.958 I slot print_timing: id  7 | task 174 | prompt eval time =     304.16 ms /   330 tokens (    0.92 ms per token,  1084.94 tokens per second)
13.32.291.962 I slot print_timing: id  7 | task 174 |        eval time =   13882.96 ms /   853 tokens (   16.28 ms per token,    61.44 tokens per second)
13.32.291.963 I slot print_timing: id  7 | task 174 |       total time =   14187.12 ms /  1183 tokens
13.32.291.964 I slot print_timing: id  7 | task 174 |    graphs reused =        402
13.32.291.965 I slot print_timing: id  7 | task 174 | draft acceptance = 0.61538 (  608 accepted /   988 generated)
13.32.291.979 I statistics        draft-mtp: #calls(b,g,a) =    4    409    409, #gen drafts =    409, #acc drafts =   337, #gen tokens =   1636, #acc tokens =  1013, dur(b,g,a) = 0.008, 3879.868, 0.211 ms
13.32.292.020 I slot      release: id  7 | task 174 | stop processing: n_tokens = 1185, truncated = 0
13.32.292.028 I srv  update_slots: all slots are idle
13.32.305.096 I srv  params_from_: Chat format: peg-gemma4
13.32.305.372 I slot get_availabl: id  6 | task -1 | selected slot by LRU, t_last = -1
13.32.305.376 I srv  get_availabl: updating prompt cache
13.32.305.379 I srv          load:  - looking for better prompt, base f_keep = -1.000, sim = 0.000
13.32.305.383 I srv        update:  - cache state: 3 prompts, 203.450 MiB (limits: 8192.000 MiB, 2649600 tokens, 2649600 est)
13.32.305.384 I srv        update:    - prompt 0xb639a4cacf50:     112 tokens, checkpoints:  1,    20.856 MiB
13.32.305.384 I srv        update:    - prompt 0xb63981c727c0:     102 tokens, checkpoints:  1,    19.113 MiB
13.32.305.385 I srv        update:    - prompt 0xb639a46dfdf0:     672 tokens, checkpoints:  2,   163.481 MiB
13.32.305.385 I srv  get_availabl: prompt cache update took 0.01 ms
13.32.305.419 I slot launch_slot_: id  6 | task 425 | processing task, is_child = 0
13.32.305.420 I slot process_sing: id  0 | task -1 | saving idle slot to prompt cache
13.32.305.421 I slot process_sing: id  1 | task -1 | saving idle slot to prompt cache
13.32.305.421 I slot process_sing: id  2 | task -1 | saving idle slot to prompt cache
13.32.305.421 I slot process_sing: id  3 | task -1 | saving idle slot to prompt cache
13.32.305.421 I slot process_sing: id  4 | task -1 | saving idle slot to prompt cache
13.32.305.422 I slot process_sing: id  5 | task -1 | saving idle slot to prompt cache
13.32.305.422 I slot process_sing: id  7 | task -1 | saving idle slot to prompt cache
13.32.306.437 W srv   prompt_save:  - saving prompt with length 1185, total state size = 179.863 MiB (draft: 0.000 MiB)
13.32.364.751 I srv        update:  - cache state: 4 prompts, 438.768 MiB (limits: 8192.000 MiB, 2649600 tokens, 2649600 est)
13.32.364.758 I srv        update:    - prompt 0xb639a4cacf50:     112 tokens, checkpoints:  1,    20.856 MiB
13.32.364.758 I srv        update:    - prompt 0xb63981c727c0:     102 tokens, checkpoints:  1,    19.113 MiB
13.32.364.758 I srv        update:    - prompt 0xb639a46dfdf0:     672 tokens, checkpoints:  2,   163.481 MiB
13.32.364.759 I srv        update:    - prompt 0xb639a46dc9f0:    1185 tokens, checkpoints:  2,   235.318 MiB
13.32.364.760 I slot process_sing: id  8 | task -1 | saving idle slot to prompt cache
13.32.365.705 W srv   prompt_save:  - saving prompt with length 672, total state size = 117.157 MiB (draft: 0.000 MiB)
13.32.365.709 I srv         alloc:  - prompt is already in the cache, skipping
13.32.365.710 I slot process_sing: id  9 | task -1 | saving idle slot to prompt cache
13.32.366.570 W srv   prompt_save:  - saving prompt with length 102, total state size = 17.784 MiB (draft: 0.000 MiB)
13.32.366.572 I srv         alloc:  - prompt is already in the cache, skipping
13.32.425.115 I slot create_check: id  6 | task 425 | created context checkpoint 1 of 32 (pos_min = 0, pos_max = 7, n_tokens = 8, size = 1.329 MiB)
13.34.001.519 I slot print_timing: id  6 | task 425 | n_decoded =    100, tg =  70.85 t/s
13.35.902.076 I slot print_timing: id  6 | task 425 | prompt eval time =     223.35 ms /   219 tokens (    1.02 ms per token,   980.54 tokens per second)
13.35.902.083 I slot print_timing: id  6 | task 425 |        eval time =    3312.03 ms /   237 tokens (   13.97 ms per token,    71.56 tokens per second)
13.35.902.083 I slot print_timing: id  6 | task 425 |       total time =    3535.37 ms /   456 tokens
13.35.902.084 I slot print_timing: id  6 | task 425 |    graphs reused =        461
13.35.902.086 I slot print_timing: id  6 | task 425 | draft acceptance = 0.72541 (  177 accepted /   244 generated)
13.35.902.100 I statistics        draft-mtp: #calls(b,g,a) =    5    470    470, #gen drafts =    470, #acc drafts =   389, #gen tokens =   1880, #acc tokens =  1190, dur(b,g,a) = 0.010, 4444.817, 0.243 ms
13.35.902.132 I slot      release: id  6 | task 425 | stop processing: n_tokens = 457, truncated = 0
13.35.902.139 I srv  update_slots: all slots are idle
15.57.080.958 I srv  params_from_: Chat format: peg-gemma4
15.57.081.147 I slot get_availabl: id  9 | task -1 | selected slot by LCP similarity, sim_best = 0.244 (> 0.100 thold), f_keep = 0.216
15.57.081.150 I srv  get_availabl: updating prompt cache
15.57.082.765 W srv   prompt_save:  - saving prompt with length 102, total state size = 17.784 MiB (draft: 0.000 MiB)
15.57.082.771 I srv         alloc:  - prompt is already in the cache, skipping
15.57.082.772 I srv          load:  - looking for better prompt, base f_keep = 0.216, sim = 0.244
15.57.082.776 I srv        update:  - cache state: 4 prompts, 438.768 MiB (limits: 8192.000 MiB, 2649600 tokens, 2649600 est)
15.57.082.777 I srv        update:    - prompt 0xb639a4cacf50:     112 tokens, checkpoints:  1,    20.856 MiB
15.57.082.778 I srv        update:    - prompt 0xb63981c727c0:     102 tokens, checkpoints:  1,    19.113 MiB
15.57.082.780 I srv        update:    - prompt 0xb639a46dfdf0:     672 tokens, checkpoints:  2,   163.481 MiB
15.57.082.781 I srv        update:    - prompt 0xb639a46dc9f0:    1185 tokens, checkpoints:  2,   235.318 MiB
15.57.082.781 I srv  get_availabl: prompt cache update took 1.63 ms
15.57.082.832 I slot launch_slot_: id  9 | task 490 | processing task, is_child = 0
15.57.082.835 I slot process_sing: id  0 | task -1 | saving idle slot to prompt cache
15.57.082.836 I slot process_sing: id  1 | task -1 | saving idle slot to prompt cache
15.57.082.836 I slot process_sing: id  2 | task -1 | saving idle slot to prompt cache
15.57.082.837 I slot process_sing: id  3 | task -1 | saving idle slot to prompt cache
15.57.082.837 I slot process_sing: id  4 | task -1 | saving idle slot to prompt cache
15.57.082.838 I slot process_sing: id  5 | task -1 | saving idle slot to prompt cache
15.57.082.839 I slot process_sing: id  6 | task -1 | saving idle slot to prompt cache
15.57.084.474 W srv   prompt_save:  - saving prompt with length 457, total state size = 79.674 MiB (draft: 0.000 MiB)
15.57.105.278 I srv        update:  - cache state: 5 prompts, 519.772 MiB (limits: 8192.000 MiB, 2649600 tokens, 2649600 est)
15.57.105.288 I srv        update:    - prompt 0xb639a4cacf50:     112 tokens, checkpoints:  1,    20.856 MiB
15.57.105.289 I srv        update:    - prompt 0xb63981c727c0:     102 tokens, checkpoints:  1,    19.113 MiB
15.57.105.290 I srv        update:    - prompt 0xb639a46dfdf0:     672 tokens, checkpoints:  2,   163.481 MiB
15.57.105.290 I srv        update:    - prompt 0xb639a46dc9f0:    1185 tokens, checkpoints:  2,   235.318 MiB
15.57.105.291 I srv        update:    - prompt 0xb639a86b7bd0:     457 tokens, checkpoints:  1,    81.003 MiB
15.57.105.292 I slot process_sing: id  7 | task -1 | saving idle slot to prompt cache
15.57.106.976 W srv   prompt_save:  - saving prompt with length 1185, total state size = 179.863 MiB (draft: 0.000 MiB)
15.57.106.982 I srv         alloc:  - prompt is already in the cache, skipping
15.57.106.983 I slot process_sing: id  8 | task -1 | saving idle slot to prompt cache
15.57.108.759 W srv   prompt_save:  - saving prompt with length 672, total state size = 117.157 MiB (draft: 0.000 MiB)
15.57.108.764 I srv         alloc:  - prompt is already in the cache, skipping
15.57.108.778 I slot update_slots: id  9 | task 490 | Checking checkpoint with [0, 7] against 0...
15.57.109.678 W slot update_slots: id  9 | task 490 | restored context checkpoint (pos_min = 0, pos_max = 7, n_tokens = 8, n_past = 7, size = 1.329 MiB)
15.59.038.133 I slot print_timing: id  9 | task 490 | n_decoded =    103, tg =  58.65 t/s
16.02.070.119 I slot print_timing: id  9 | task 490 | n_decoded =    240, tg =  50.12 t/s
16.05.085.951 I slot print_timing: id  9 | task 490 | n_decoded =    410, tg =  52.54 t/s
16.08.122.667 I slot print_timing: id  9 | task 490 | n_decoded =    583, tg =  53.78 t/s
16.11.176.786 I slot print_timing: id  9 | task 490 | n_decoded =    720, tg =  51.82 t/s
16.14.204.590 I slot print_timing: id  9 | task 490 | n_decoded =    906, tg =  53.54 t/s
16.17.255.073 I slot print_timing: id  9 | task 490 | n_decoded =   1054, tg =  52.77 t/s
16.19.050.936 I slot print_timing: id  9 | task 490 | prompt eval time =     173.00 ms /    83 tokens (    2.08 ms per token,   479.76 tokens per second)
16.19.050.939 I slot print_timing: id  9 | task 490 |        eval time =   21769.04 ms /  1141 tokens (   19.08 ms per token,    52.41 tokens per second)
16.19.050.939 I slot print_timing: id  9 | task 490 |       total time =   21942.04 ms /  1224 tokens
16.19.050.941 I slot print_timing: id  9 | task 490 |    graphs reused =        803
16.19.050.942 I slot print_timing: id  9 | task 490 | draft acceptance = 0.57133 (  793 accepted /  1388 generated)
16.19.050.956 I statistics        draft-mtp: #calls(b,g,a) =    6    817    817, #gen drafts =    817, #acc drafts =   666, #gen tokens =   3268, #acc tokens =  1983, dur(b,g,a) = 0.011, 8005.009, 0.394 ms
16.19.050.974 I slot      release: id  9 | task 490 | stop processing: n_tokens = 1230, truncated = 0
16.19.050.988 I srv  update_slots: all slots are idle
16.19.071.820 I srv  params_from_: Chat format: peg-gemma4
16.19.071.986 I slot get_availabl: id  8 | task -1 | selected slot by LCP similarity, sim_best = 0.317 (> 0.100 thold), f_keep = 0.394
16.19.071.990 I srv  get_availabl: updating prompt cache
16.19.073.016 W srv   prompt_save:  - saving prompt with length 672, total state size = 117.157 MiB (draft: 0.000 MiB)
16.19.073.021 I srv         alloc:  - prompt is already in the cache, skipping
16.19.073.022 I srv          load:  - looking for better prompt, base f_keep = 0.394, sim = 0.317
16.19.073.025 I srv        update:  - cache state: 5 prompts, 519.772 MiB (limits: 8192.000 MiB, 2649600 tokens, 2649600 est)
16.19.073.026 I srv        update:    - prompt 0xb639a4cacf50:     112 tokens, checkpoints:  1,    20.856 MiB
16.19.073.026 I srv        update:    - prompt 0xb63981c727c0:     102 tokens, checkpoints:  1,    19.113 MiB
16.19.073.027 I srv        update:    - prompt 0xb639a46dfdf0:     672 tokens, checkpoints:  2,   163.481 MiB
16.19.073.027 I srv        update:    - prompt 0xb639a46dc9f0:    1185 tokens, checkpoints:  2,   235.318 MiB
16.19.073.028 I srv        update:    - prompt 0xb639a86b7bd0:     457 tokens, checkpoints:  1,    81.003 MiB
16.19.073.028 I srv  get_availabl: prompt cache update took 1.04 ms
16.19.073.075 I slot launch_slot_: id  8 | task 841 | processing task, is_child = 0
16.19.073.076 I slot process_sing: id  0 | task -1 | saving idle slot to prompt cache
16.19.073.076 I slot process_sing: id  1 | task -1 | saving idle slot to prompt cache
16.19.073.076 I slot process_sing: id  2 | task -1 | saving idle slot to prompt cache
16.19.073.076 I slot process_sing: id  3 | task -1 | saving idle slot to prompt cache
16.19.073.077 I slot process_sing: id  4 | task -1 | saving idle slot to prompt cache
16.19.073.077 I slot process_sing: id  5 | task -1 | saving idle slot to prompt cache
16.19.073.077 I slot process_sing: id  6 | task -1 | saving idle slot to prompt cache
16.19.074.028 W srv   prompt_save:  - saving prompt with length 457, total state size = 79.674 MiB (draft: 0.000 MiB)
16.19.074.030 I srv         alloc:  - prompt is already in the cache, skipping
16.19.074.031 I slot process_sing: id  7 | task -1 | saving idle slot to prompt cache
16.19.075.093 W srv   prompt_save:  - saving prompt with length 1185, total state size = 179.863 MiB (draft: 0.000 MiB)
16.19.075.096 I srv         alloc:  - prompt is already in the cache, skipping
16.19.075.096 I slot process_sing: id  9 | task -1 | saving idle slot to prompt cache
16.19.076.009 W srv   prompt_save:  - saving prompt with length 1230, total state size = 180.237 MiB (draft: 0.000 MiB)
16.19.120.991 I srv        update:  - cache state: 6 prompts, 701.338 MiB (limits: 8192.000 MiB, 2649600 tokens, 2649600 est)
16.19.120.996 I srv        update:    - prompt 0xb639a4cacf50:     112 tokens, checkpoints:  1,    20.856 MiB
16.19.120.996 I srv        update:    - prompt 0xb63981c727c0:     102 tokens, checkpoints:  1,    19.113 MiB
16.19.120.996 I srv        update:    - prompt 0xb639a46dfdf0:     672 tokens, checkpoints:  2,   163.481 MiB
16.19.120.997 I srv        update:    - prompt 0xb639a46dc9f0:    1185 tokens, checkpoints:  2,   235.318 MiB
16.19.120.997 I srv        update:    - prompt 0xb639a86b7bd0:     457 tokens, checkpoints:  1,    81.003 MiB
16.19.120.997 I srv        update:    - prompt 0xb639a47c1650:    1230 tokens, checkpoints:  1,   181.566 MiB
16.19.121.010 I slot update_slots: id  8 | task 841 | Checking checkpoint with [0, 270] against 0...
16.19.121.010 I slot update_slots: id  8 | task 841 | Checking checkpoint with [0, 7] against 0...
16.19.121.856 W slot update_slots: id  8 | task 841 | restored context checkpoint (pos_min = 0, pos_max = 7, n_tokens = 8, n_past = 7, size = 1.329 MiB)
16.19.121.859 W slot update_slots: id  8 | task 841 | erased invalidated context checkpoint (pos_min = 0, pos_max = 270, n_tokens = 271, n_swa = 1024, pos_next = 7, size = 44.994 MiB)
16.19.352.009 I slot create_check: id  8 | task 841 | created context checkpoint 2 of 32 (pos_min = 0, pos_max = 320, n_tokens = 321, size = 53.296 MiB)
16.19.670.531 I slot create_check: id  8 | task 841 | created context checkpoint 3 of 32 (pos_min = 0, pos_max = 832, n_tokens = 833, size = 138.302 MiB)
16.21.377.290 I slot print_timing: id  8 | task 841 | n_decoded =    100, tg =  60.40 t/s
16.24.417.466 I slot print_timing: id  8 | task 841 | n_decoded =    242, tg =  51.53 t/s
16.27.466.464 I slot print_timing: id  8 | task 841 | n_decoded =    409, tg =  52.81 t/s
16.29.123.180 I slot print_timing: id  8 | task 841 | prompt eval time =     600.44 ms /   830 tokens (    0.72 ms per token,  1382.33 tokens per second)
16.29.123.185 I slot print_timing: id  8 | task 841 |        eval time =    9401.61 ms /   515 tokens (   18.26 ms per token,    54.78 tokens per second)
16.29.123.186 I slot print_timing: id  8 | task 841 |       total time =   10002.05 ms /  1345 tokens
16.29.123.187 I slot print_timing: id  8 | task 841 |    graphs reused =        956
16.29.123.187 I slot print_timing: id  8 | task 841 | draft acceptance = 0.57692 (  360 accepted /   624 generated)
16.29.123.200 I statistics        draft-mtp: #calls(b,g,a) =    7    973    973, #gen drafts =    973, #acc drafts =   792, #gen tokens =   3892, #acc tokens =  2343, dur(b,g,a) = 0.012, 9563.366, 0.461 ms
16.29.123.259 I slot      release: id  8 | task 841 | stop processing: n_tokens = 1353, truncated = 0
16.29.123.269 I srv  update_slots: all slots are idle
18.24.390.529 I srv  params_from_: Chat format: peg-gemma4
18.24.392.206 I slot get_availabl: id  5 | task -1 | selected slot by LRU, t_last = -1
18.24.392.210 I srv  get_availabl: updating prompt cache
18.24.392.213 I srv          load:  - looking for better prompt, base f_keep = -1.000, sim = 0.000
18.24.392.219 I srv        update:  - cache state: 6 prompts, 701.338 MiB (limits: 8192.000 MiB, 2649600 tokens, 2649600 est)
18.24.392.220 I srv        update:    - prompt 0xb639a4cacf50:     112 tokens, checkpoints:  1,    20.856 MiB
18.24.392.220 I srv        update:    - prompt 0xb63981c727c0:     102 tokens, checkpoints:  1,    19.113 MiB
18.24.392.221 I srv        update:    - prompt 0xb639a46dfdf0:     672 tokens, checkpoints:  2,   163.481 MiB
18.24.392.221 I srv        update:    - prompt 0xb639a46dc9f0:    1185 tokens, checkpoints:  2,   235.318 MiB
18.24.392.222 I srv        update:    - prompt 0xb639a86b7bd0:     457 tokens, checkpoints:  1,    81.003 MiB
18.24.392.222 I srv        update:    - prompt 0xb639a47c1650:    1230 tokens, checkpoints:  1,   181.566 MiB
18.24.392.223 I srv  get_availabl: prompt cache update took 0.01 ms
18.24.392.256 I slot launch_slot_: id  5 | task 1002 | processing task, is_child = 0
18.24.392.257 I slot process_sing: id  0 | task -1 | saving idle slot to prompt cache
18.24.392.258 I slot process_sing: id  1 | task -1 | saving idle slot to prompt cache
18.24.392.258 I slot process_sing: id  2 | task -1 | saving idle slot to prompt cache
18.24.392.258 I slot process_sing: id  3 | task -1 | saving idle slot to prompt cache
18.24.392.258 I slot process_sing: id  4 | task -1 | saving idle slot to prompt cache
18.24.392.259 I slot process_sing: id  6 | task -1 | saving idle slot to prompt cache
18.24.393.217 W srv   prompt_save:  - saving prompt with length 457, total state size = 79.674 MiB (draft: 0.000 MiB)
18.24.393.221 I srv         alloc:  - prompt is already in the cache, skipping
18.24.393.221 I slot process_sing: id  7 | task -1 | saving idle slot to prompt cache
18.24.394.468 W srv   prompt_save:  - saving prompt with length 1185, total state size = 179.863 MiB (draft: 0.000 MiB)
18.24.394.470 I srv         alloc:  - prompt is already in the cache, skipping
18.24.394.471 I slot process_sing: id  8 | task -1 | saving idle slot to prompt cache
18.24.395.447 W srv   prompt_save:  - saving prompt with length 1353, total state size = 181.259 MiB (draft: 0.000 MiB)
18.24.481.266 I srv        update:  - cache state: 7 prompts, 1075.523 MiB (limits: 8192.000 MiB, 2649600 tokens, 2649600 est)
18.24.481.272 I srv        update:    - prompt 0xb639a4cacf50:     112 tokens, checkpoints:  1,    20.856 MiB
18.24.481.272 I srv        update:    - prompt 0xb63981c727c0:     102 tokens, checkpoints:  1,    19.113 MiB
18.24.481.273 I srv        update:    - prompt 0xb639a46dfdf0:     672 tokens, checkpoints:  2,   163.481 MiB
18.24.481.273 I srv        update:    - prompt 0xb639a46dc9f0:    1185 tokens, checkpoints:  2,   235.318 MiB
18.24.481.273 I srv        update:    - prompt 0xb639a86b7bd0:     457 tokens, checkpoints:  1,    81.003 MiB
18.24.481.274 I srv        update:    - prompt 0xb639a47c1650:    1230 tokens, checkpoints:  1,   181.566 MiB
18.24.481.274 I srv        update:    - prompt 0xb639a4c95e50:    1353 tokens, checkpoints:  3,   374.186 MiB
18.24.481.275 I slot process_sing: id  9 | task -1 | saving idle slot to prompt cache
18.24.482.290 W srv   prompt_save:  - saving prompt with length 1230, total state size = 180.237 MiB (draft: 0.000 MiB)
18.24.482.295 I srv         alloc:  - prompt is already in the cache, skipping
18.24.905.674 I slot create_check: id  5 | task 1002 | created context checkpoint 1 of 32 (pos_min = 0, pos_max = 601, n_tokens = 602, size = 99.949 MiB)
18.25.138.626 I slot create_check: id  5 | task 1002 | created context checkpoint 2 of 32 (pos_min = 0, pos_max = 900, n_tokens = 901, size = 149.591 MiB)
18.25.501.597 I slot create_check: id  5 | task 1002 | created context checkpoint 3 of 32 (pos_min = 0, pos_max = 1412, n_tokens = 1413, size = 170.013 MiB)
18.27.615.271 I slot print_timing: id  5 | task 1002 | n_decoded =    100, tg =  48.68 t/s
18.30.619.392 I slot print_timing: id  5 | task 1002 | n_decoded =    197, tg =  38.94 t/s
18.33.680.039 I slot print_timing: id  5 | task 1002 | n_decoded =    330, tg =  40.64 t/s
18.36.735.294 I slot print_timing: id  5 | task 1002 | n_decoded =    457, tg =  40.90 t/s
18.39.792.421 I slot print_timing: id  5 | task 1002 | n_decoded =    577, tg =  40.54 t/s
18.42.820.397 I slot print_timing: id  5 | task 1002 | n_decoded =    689, tg =  39.92 t/s
18.45.836.330 I slot print_timing: id  5 | task 1002 | n_decoded =    827, tg =  40.79 t/s
18.48.894.688 I slot print_timing: id  5 | task 1002 | n_decoded =    938, tg =  40.20 t/s
18.51.930.365 I slot print_timing: id  5 | task 1002 | n_decoded =   1095, tg =  41.53 t/s
18.53.337.681 I slot print_timing: id  5 | task 1002 | prompt eval time =    1078.48 ms /  1417 tokens (    0.76 ms per token,  1313.89 tokens per second)
18.53.337.685 I slot print_timing: id  5 | task 1002 |        eval time =   27776.78 ms /  1157 tokens (   24.01 ms per token,    41.65 tokens per second)
18.53.337.685 I slot print_timing: id  5 | task 1002 |       total time =   28855.25 ms /  2574 tokens
18.53.337.686 I slot print_timing: id  5 | task 1002 |    graphs reused =       1371
18.53.337.687 I slot print_timing: id  5 | task 1002 | draft acceptance = 0.43765 (  737 accepted /  1684 generated)
18.53.337.701 I statistics        draft-mtp: #calls(b,g,a) =    8   1394   1394, #gen drafts =   1394, #acc drafts =  1085, #gen tokens =   5576, #acc tokens =  3080, dur(b,g,a) = 0.013, 14130.595, 0.638 ms
18.53.337.781 I slot      release: id  5 | task 1002 | stop processing: n_tokens = 2575, truncated = 0
18.53.337.790 I srv  update_slots: all slots are idle
18.53.361.582 I srv  params_from_: Chat format: peg-gemma4
18.53.361.857 I slot get_availabl: id  8 | task -1 | selected slot by LCP similarity, sim_best = 0.367 (> 0.100 thold), f_keep = 0.611
18.53.361.924 I slot launch_slot_: id  8 | task 1428 | processing task, is_child = 0
18.53.361.925 I slot process_sing: id  0 | task -1 | saving idle slot to prompt cache
18.53.361.926 I slot process_sing: id  1 | task -1 | saving idle slot to prompt cache
18.53.361.926 I slot process_sing: id  2 | task -1 | saving idle slot to prompt cache
18.53.361.926 I slot process_sing: id  3 | task -1 | saving idle slot to prompt cache
18.53.361.927 I slot process_sing: id  4 | task -1 | saving idle slot to prompt cache
18.53.361.927 I slot process_sing: id  5 | task -1 | saving idle slot to prompt cache
18.53.362.891 W srv   prompt_save:  - saving prompt with length 2575, total state size = 191.417 MiB (draft: 0.000 MiB)
18.53.506.556 I srv        update:  - cache state: 8 prompts, 1686.494 MiB (limits: 8192.000 MiB, 2649600 tokens, 2649600 est)
18.53.506.562 I srv        update:    - prompt 0xb639a4cacf50:     112 tokens, checkpoints:  1,    20.856 MiB
18.53.506.562 I srv        update:    - prompt 0xb63981c727c0:     102 tokens, checkpoints:  1,    19.113 MiB
18.53.506.563 I srv        update:    - prompt 0xb639a46dfdf0:     672 tokens, checkpoints:  2,   163.481 MiB
18.53.506.564 I srv        update:    - prompt 0xb639a46dc9f0:    1185 tokens, checkpoints:  2,   235.318 MiB
18.53.506.564 I srv        update:    - prompt 0xb639a86b7bd0:     457 tokens, checkpoints:  1,    81.003 MiB
18.53.506.564 I srv        update:    - prompt 0xb639a47c1650:    1230 tokens, checkpoints:  1,   181.566 MiB
18.53.506.565 I srv        update:    - prompt 0xb639a4c95e50:    1353 tokens, checkpoints:  3,   374.186 MiB
18.53.506.565 I srv        update:    - prompt 0xb639a4cadb10:    2575 tokens, checkpoints:  3,   610.970 MiB
18.53.506.566 I slot process_sing: id  6 | task -1 | saving idle slot to prompt cache
18.53.507.545 W srv   prompt_save:  - saving prompt with length 457, total state size = 79.674 MiB (draft: 0.000 MiB)
18.53.507.553 I srv         alloc:  - prompt is already in the cache, skipping
18.53.507.553 I slot process_sing: id  7 | task -1 | saving idle slot to prompt cache
18.53.508.508 W srv   prompt_save:  - saving prompt with length 1185, total state size = 179.863 MiB (draft: 0.000 MiB)
18.53.508.512 I srv         alloc:  - prompt is already in the cache, skipping
18.53.508.513 I slot process_sing: id  9 | task -1 | saving idle slot to prompt cache
18.53.509.625 W srv   prompt_save:  - saving prompt with length 1230, total state size = 180.237 MiB (draft: 0.000 MiB)
18.53.509.627 I srv         alloc:  - prompt is already in the cache, skipping
18.53.509.643 I slot update_slots: id  8 | task 1428 | Checking checkpoint with [0, 832] against 0...
18.53.509.643 I slot update_slots: id  8 | task 1428 | Checking checkpoint with [0, 320] against 0...
18.53.511.460 W slot update_slots: id  8 | task 1428 | restored context checkpoint (pos_min = 0, pos_max = 320, n_tokens = 321, n_past = 320, size = 53.296 MiB)
18.53.511.463 W slot update_slots: id  8 | task 1428 | erased invalidated context checkpoint (pos_min = 0, pos_max = 832, n_tokens = 833, n_swa = 1024, pos_next = 320, size = 138.302 MiB)
18.54.383.078 I slot create_check: id  8 | task 1428 | created context checkpoint 3 of 32 (pos_min = 204, pos_max = 1739, n_tokens = 1740, size = 170.013 MiB)
18.54.754.273 I slot create_check: id  8 | task 1428 | created context checkpoint 4 of 32 (pos_min = 716, pos_max = 2251, n_tokens = 2252, size = 170.013 MiB)
18.56.549.155 I slot print_timing: id  8 | task 1428 | n_decoded =    102, tg =  58.78 t/s
18.59.578.685 I slot print_timing: id  8 | task 1428 | n_decoded =    245, tg =  51.42 t/s
19.02.633.105 I slot print_timing: id  8 | task 1428 | n_decoded =    413, tg =  52.82 t/s
19.05.679.298 I slot print_timing: id  8 | task 1428 | n_decoded =    600, tg =  55.22 t/s
19.07.034.666 I slot print_timing: id  8 | task 1428 | prompt eval time =    1303.98 ms /  1936 tokens (    0.67 ms per token,  1484.69 tokens per second)
19.07.034.670 I slot print_timing: id  8 | task 1428 |        eval time =   12220.93 ms /   682 tokens (   17.92 ms per token,    55.81 tokens per second)
19.07.034.671 I slot print_timing: id  8 | task 1428 |       total time =   13524.91 ms /  2618 tokens
19.07.034.672 I slot print_timing: id  8 | task 1428 |    graphs reused =       1573
19.07.034.673 I slot print_timing: id  8 | task 1428 | draft acceptance = 0.57888 (  477 accepted /   824 generated)
19.07.034.687 I statistics        draft-mtp: #calls(b,g,a) =    9   1600   1600, #gen drafts =   1600, #acc drafts =  1243, #gen tokens =   6400, #acc tokens =  3557, dur(b,g,a) = 0.014, 16180.077, 0.730 ms
19.07.034.807 I slot      release: id  8 | task 1428 | stop processing: n_tokens = 2939, truncated = 0
19.07.034.821 I srv  update_slots: all slots are idle
33.17.267.281 I srv  params_from_: Chat format: peg-gemma4
33.17.269.229 I slot get_availabl: id  4 | task -1 | selected slot by LRU, t_last = -1
33.17.269.233 I srv  get_availabl: updating prompt cache
33.17.269.236 I srv          load:  - looking for better prompt, base f_keep = -1.000, sim = 0.000
33.17.269.243 I srv        update:  - cache state: 8 prompts, 1686.494 MiB (limits: 8192.000 MiB, 2649600 tokens, 2649600 est)
33.17.269.244 I srv        update:    - prompt 0xb639a4cacf50:     112 tokens, checkpoints:  1,    20.856 MiB
33.17.269.245 I srv        update:    - prompt 0xb63981c727c0:     102 tokens, checkpoints:  1,    19.113 MiB
33.17.269.246 I srv        update:    - prompt 0xb639a46dfdf0:     672 tokens, checkpoints:  2,   163.481 MiB
33.17.269.247 I srv        update:    - prompt 0xb639a46dc9f0:    1185 tokens, checkpoints:  2,   235.318 MiB
33.17.269.247 I srv        update:    - prompt 0xb639a86b7bd0:     457 tokens, checkpoints:  1,    81.003 MiB
33.17.269.247 I srv        update:    - prompt 0xb639a47c1650:    1230 tokens, checkpoints:  1,   181.566 MiB
33.17.269.248 I srv        update:    - prompt 0xb639a4c95e50:    1353 tokens, checkpoints:  3,   374.186 MiB
33.17.269.249 I srv        update:    - prompt 0xb639a4cadb10:    2575 tokens, checkpoints:  3,   610.970 MiB
33.17.269.249 I srv  get_availabl: prompt cache update took 0.02 ms
33.17.269.288 I slot launch_slot_: id  4 | task 1638 | processing task, is_child = 0
33.17.269.289 I slot process_sing: id  0 | task -1 | saving idle slot to prompt cache
33.17.269.290 I slot process_sing: id  1 | task -1 | saving idle slot to prompt cache
33.17.269.290 I slot process_sing: id  2 | task -1 | saving idle slot to prompt cache
33.17.269.290 I slot process_sing: id  3 | task -1 | saving idle slot to prompt cache
33.17.269.291 I slot process_sing: id  5 | task -1 | saving idle slot to prompt cache
33.17.270.307 W srv   prompt_save:  - saving prompt with length 2575, total state size = 191.417 MiB (draft: 0.000 MiB)
33.17.270.313 I srv         alloc:  - prompt is already in the cache, skipping
33.17.270.314 I slot process_sing: id  6 | task -1 | saving idle slot to prompt cache
33.17.271.341 W srv   prompt_save:  - saving prompt with length 457, total state size = 79.674 MiB (draft: 0.000 MiB)
33.17.271.344 I srv         alloc:  - prompt is already in the cache, skipping
33.17.271.345 I slot process_sing: id  7 | task -1 | saving idle slot to prompt cache
33.17.272.401 W srv   prompt_save:  - saving prompt with length 1185, total state size = 179.863 MiB (draft: 0.000 MiB)
33.17.272.404 I srv         alloc:  - prompt is already in the cache, skipping
33.17.272.404 I slot process_sing: id  8 | task -1 | saving idle slot to prompt cache
33.17.273.393 W srv   prompt_save:  - saving prompt with length 2939, total state size = 194.443 MiB (draft: 0.000 MiB)
33.17.412.924 I srv        update:  - cache state: 9 prompts, 2275.587 MiB (limits: 8192.000 MiB, 2649600 tokens, 2649600 est)
33.17.412.928 I srv        update:    - prompt 0xb639a4cacf50:     112 tokens, checkpoints:  1,    20.856 MiB
33.17.412.928 I srv        update:    - prompt 0xb63981c727c0:     102 tokens, checkpoints:  1,    19.113 MiB
33.17.412.929 I srv        update:    - prompt 0xb639a46dfdf0:     672 tokens, checkpoints:  2,   163.481 MiB
33.17.412.929 I srv        update:    - prompt 0xb639a46dc9f0:    1185 tokens, checkpoints:  2,   235.318 MiB
33.17.412.929 I srv        update:    - prompt 0xb639a86b7bd0:     457 tokens, checkpoints:  1,    81.003 MiB
33.17.412.929 I srv        update:    - prompt 0xb639a47c1650:    1230 tokens, checkpoints:  1,   181.566 MiB
33.17.412.930 I srv        update:    - prompt 0xb639a4c95e50:    1353 tokens, checkpoints:  3,   374.186 MiB
33.17.412.930 I srv        update:    - prompt 0xb639a4cadb10:    2575 tokens, checkpoints:  3,   610.970 MiB
33.17.412.930 I srv        update:    - prompt 0xb639a46d9890:    2939 tokens, checkpoints:  4,   589.093 MiB
33.17.412.931 I slot process_sing: id  9 | task -1 | saving idle slot to prompt cache
33.17.413.826 W srv   prompt_save:  - saving prompt with length 1230, total state size = 180.237 MiB (draft: 0.000 MiB)
33.17.413.831 I srv         alloc:  - prompt is already in the cache, skipping
33.17.419.607 I srv  params_from_: Chat format: peg-gemma4
33.17.476.244 I slot get_availabl: id  3 | task -1 | selected slot by LRU, t_last = -1
33.17.476.249 I srv  get_availabl: updating prompt cache
33.17.476.251 I srv          load:  - looking for better prompt, base f_keep = -1.000, sim = 0.000
33.17.476.255 I srv        update:  - cache state: 9 prompts, 2275.587 MiB (limits: 8192.000 MiB, 2649600 tokens, 2649600 est)
33.17.476.256 I srv        update:    - prompt 0xb639a4cacf50:     112 tokens, checkpoints:  1,    20.856 MiB
33.17.476.256 I srv        update:    - prompt 0xb63981c727c0:     102 tokens, checkpoints:  1,    19.113 MiB
33.17.476.256 I srv        update:    - prompt 0xb639a46dfdf0:     672 tokens, checkpoints:  2,   163.481 MiB
33.17.476.257 I srv        update:    - prompt 0xb639a46dc9f0:    1185 tokens, checkpoints:  2,   235.318 MiB
33.17.476.257 I srv        update:    - prompt 0xb639a86b7bd0:     457 tokens, checkpoints:  1,    81.003 MiB
33.17.476.257 I srv        update:    - prompt 0xb639a47c1650:    1230 tokens, checkpoints:  1,   181.566 MiB
33.17.476.258 I srv        update:    - prompt 0xb639a4c95e50:    1353 tokens, checkpoints:  3,   374.186 MiB
33.17.476.258 I srv        update:    - prompt 0xb639a4cadb10:    2575 tokens, checkpoints:  3,   610.970 MiB
33.17.476.258 I srv        update:    - prompt 0xb639a46d9890:    2939 tokens, checkpoints:  4,   589.093 MiB
33.17.476.259 I srv  get_availabl: prompt cache update took 0.01 ms
33.17.476.441 I slot launch_slot_: id  3 | task 1640 | processing task, is_child = 0
33.17.476.444 I slot process_sing: id  0 | task -1 | saving idle slot to prompt cache
33.17.476.445 I slot process_sing: id  1 | task -1 | saving idle slot to prompt cache
33.17.476.445 I slot process_sing: id  2 | task -1 | saving idle slot to prompt cache
33.17.476.445 I slot process_sing: id  5 | task -1 | saving idle slot to prompt cache
33.17.477.450 W srv   prompt_save:  - saving prompt with length 2575, total state size = 191.417 MiB (draft: 0.000 MiB)
33.17.477.455 I srv         alloc:  - prompt is already in the cache, skipping
33.17.477.456 I slot process_sing: id  6 | task -1 | saving idle slot to prompt cache
33.17.478.481 W srv   prompt_save:  - saving prompt with length 457, total state size = 79.674 MiB (draft: 0.000 MiB)
33.17.478.485 I srv         alloc:  - prompt is already in the cache, skipping
33.17.478.486 I slot process_sing: id  7 | task -1 | saving idle slot to prompt cache
33.17.479.421 W srv   prompt_save:  - saving prompt with length 1185, total state size = 179.863 MiB (draft: 0.000 MiB)
33.17.479.423 I srv         alloc:  - prompt is already in the cache, skipping
33.17.479.424 I slot process_sing: id  8 | task -1 | saving idle slot to prompt cache
33.17.480.722 W srv   prompt_save:  - saving prompt with length 2939, total state size = 194.443 MiB (draft: 0.000 MiB)
33.17.480.728 I srv         alloc:  - prompt is already in the cache, skipping
33.17.480.728 I slot process_sing: id  9 | task -1 | saving idle slot to prompt cache
33.17.481.699 W srv   prompt_save:  - saving prompt with length 1230, total state size = 180.237 MiB (draft: 0.000 MiB)
33.17.481.701 I srv         alloc:  - prompt is already in the cache, skipping
33.21.113.506 I slot print_timing: id  3 | task 1640 | prompt processing, n_tokens =   6144, progress = 0.85, t =   3.63 s / 1691.73 tokens per second
33.21.113.636 I slot print_timing: id  4 | task 1638 | prompt processing, n_tokens =     46, progress = 0.08, t =   3.70 s / 12.43 tokens per second
33.21.820.711 I slot print_timing: id  3 | task 1640 | prompt processing, n_tokens =   6703, progress = 0.93, t =   4.34 s / 1544.83 tokens per second
33.21.820.847 I slot print_timing: id  4 | task 1638 | prompt processing, n_tokens =    546, progress = 0.97, t =   4.41 s / 123.89 tokens per second
33.21.844.159 I slot create_check: id  4 | task 1638 | created context checkpoint 1 of 32 (pos_min = 0, pos_max = 545, n_tokens = 546, size = 90.652 MiB)
33.22.222.054 I slot print_timing: id  3 | task 1640 | prompt processing, n_tokens =   7203, progress = 1.00, t =   4.74 s / 1519.51 tokens per second
33.22.263.357 I slot create_check: id  3 | task 1640 | created context checkpoint 1 of 32 (pos_min = 5667, pos_max = 7202, n_tokens = 7203, size = 170.013 MiB)
33.22.263.365 I slot print_timing: id  4 | task 1638 | prompt processing, n_tokens =    558, progress = 0.99, t =   4.85 s / 115.06 tokens per second
33.22.402.324 I slot print_timing: id  3 | task 1640 | prompt processing, n_tokens =   7215, progress = 1.00, t =   4.92 s / 1466.28 tokens per second
33.22.583.447 I reasoning-budget: activated, budget=2147483647 tokens
33.24.525.755 I slot print_timing: id  4 | task 1638 | n_decoded =    103, tg =  48.27 t/s
33.25.372.808 I slot print_timing: id  3 | task 1640 | n_decoded =    101, tg =  35.22 t/s
33.25.452.521 I reasoning-budget: deactivated (natural end)
33.25.771.683 I slot print_timing: id  3 | task 1640 | prompt eval time =    5023.21 ms /  7219 tokens (    0.70 ms per token,  1437.13 tokens per second)
33.25.771.686 I slot print_timing: id  3 | task 1640 |        eval time =    3266.63 ms /   118 tokens (   27.68 ms per token,    36.12 tokens per second)
33.25.771.686 I slot print_timing: id  3 | task 1640 |       total time =    8289.85 ms /  7337 tokens
33.25.771.687 I slot print_timing: id  3 | task 1640 |    graphs reused =       1614
33.25.771.688 I slot print_timing: id  3 | task 1640 | draft acceptance = 0.45833 (   77 accepted /   168 generated)
33.25.771.701 I statistics        draft-mtp: #calls(b,g,a) =   11   1643   1684, #gen drafts =   1685, #acc drafts =  1306, #gen tokens =   6740, #acc tokens =  3741, dur(b,g,a) = 0.016, 16696.326, 0.775 ms
33.25.772.010 I slot      release: id  3 | task 1640 | stop processing: n_tokens = 7338, truncated = 0
33.27.526.417 I slot print_timing: id  4 | task 1638 | prompt eval time =    4977.86 ms /   562 tokens (    8.86 ms per token,   112.90 tokens per second)
33.27.526.420 I slot print_timing: id  4 | task 1638 |        eval time =    5134.60 ms /   248 tokens (   20.70 ms per token,    48.30 tokens per second)
33.27.526.421 I slot print_timing: id  4 | task 1638 |       total time =   10112.46 ms /   810 tokens
33.27.526.422 I slot print_timing: id  4 | task 1638 |    graphs reused =       1643
33.27.526.423 I slot print_timing: id  4 | task 1638 | draft acceptance = 0.59459 (  176 accepted /   296 generated)
33.27.526.434 I statistics        draft-mtp: #calls(b,g,a) =   11   1674   1716, #gen drafts =   1716, #acc drafts =  1330, #gen tokens =   6864, #acc tokens =  3810, dur(b,g,a) = 0.016, 16994.202, 0.789 ms
33.27.526.487 I slot      release: id  4 | task 1638 | stop processing: n_tokens = 812, truncated = 0
33.27.526.492 I slot print_timing: id  4 | task -1 | n_decoded =    248, tg =  48.30 t/s
33.27.526.494 I srv  update_slots: all slots are idle
34.51.005.422 I srv  params_from_: Chat format: peg-gemma4
34.51.006.222 I slot get_availabl: id  4 | task -1 | selected slot by LCP similarity, sim_best = 0.973 (> 0.100 thold), f_keep = 0.676
34.51.006.304 I slot launch_slot_: id  4 | task 1721 | processing task, is_child = 0
34.51.006.310 I slot process_sing: id  0 | task -1 | saving idle slot to prompt cache
34.51.006.311 I slot process_sing: id  1 | task -1 | saving idle slot to prompt cache
34.51.006.311 I slot process_sing: id  2 | task -1 | saving idle slot to prompt cache
34.51.006.311 I slot process_sing: id  3 | task -1 | saving idle slot to prompt cache
34.51.008.272 W srv   prompt_save:  - saving prompt with length 7338, total state size = 231.008 MiB (draft: 0.000 MiB)
34.51.097.026 I srv  params_from_: Chat format: peg-gemma4
34.51.105.972 I srv        update:  - cache state: 10 prompts, 2676.607 MiB (limits: 8192.000 MiB, 2649600 tokens, 2649600 est)
34.51.105.979 I srv        update:    - prompt 0xb639a4cacf50:     112 tokens, checkpoints:  1,    20.856 MiB
34.51.105.980 I srv        update:    - prompt 0xb63981c727c0:     102 tokens, checkpoints:  1,    19.113 MiB
34.51.105.980 I srv        update:    - prompt 0xb639a46dfdf0:     672 tokens, checkpoints:  2,   163.481 MiB
34.51.105.981 I srv        update:    - prompt 0xb639a46dc9f0:    1185 tokens, checkpoints:  2,   235.318 MiB
34.51.105.981 I srv        update:    - prompt 0xb639a86b7bd0:     457 tokens, checkpoints:  1,    81.003 MiB
34.51.105.981 I srv        update:    - prompt 0xb639a47c1650:    1230 tokens, checkpoints:  1,   181.566 MiB
34.51.105.982 I srv        update:    - prompt 0xb639a4c95e50:    1353 tokens, checkpoints:  3,   374.186 MiB
34.51.105.982 I srv        update:    - prompt 0xb639a4cadb10:    2575 tokens, checkpoints:  3,   610.970 MiB
34.51.105.982 I srv        update:    - prompt 0xb639a46d9890:    2939 tokens, checkpoints:  4,   589.093 MiB
34.51.105.983 I srv        update:    - prompt 0xb639a84535e0:    7338 tokens, checkpoints:  1,   401.021 MiB
34.51.105.984 I slot process_sing: id  5 | task -1 | saving idle slot to prompt cache
34.51.107.024 W srv   prompt_save:  - saving prompt with length 2575, total state size = 191.417 MiB (draft: 0.000 MiB)
34.51.107.032 I srv         alloc:  - prompt is already in the cache, skipping
34.51.107.033 I slot process_sing: id  6 | task -1 | saving idle slot to prompt cache
34.51.107.983 W srv   prompt_save:  - saving prompt with length 457, total state size = 79.674 MiB (draft: 0.000 MiB)
34.51.107.989 I srv         alloc:  - prompt is already in the cache, skipping
34.51.107.990 I slot process_sing: id  7 | task -1 | saving idle slot to prompt cache
34.51.109.064 W srv   prompt_save:  - saving prompt with length 1185, total state size = 179.863 MiB (draft: 0.000 MiB)
34.51.109.069 I srv         alloc:  - prompt is already in the cache, skipping
34.51.109.069 I slot process_sing: id  8 | task -1 | saving idle slot to prompt cache
34.51.110.216 W srv   prompt_save:  - saving prompt with length 2939, total state size = 194.443 MiB (draft: 0.000 MiB)
34.51.110.228 I srv         alloc:  - prompt is already in the cache, skipping
34.51.110.229 I slot process_sing: id  9 | task -1 | saving idle slot to prompt cache
34.51.111.155 W srv   prompt_save:  - saving prompt with length 1230, total state size = 180.237 MiB (draft: 0.000 MiB)
34.51.111.159 I srv         alloc:  - prompt is already in the cache, skipping
34.51.111.178 I slot update_slots: id  4 | task 1721 | Checking checkpoint with [0, 545] against 0...
34.51.114.184 W slot update_slots: id  4 | task 1721 | restored context checkpoint (pos_min = 0, pos_max = 545, n_tokens = 546, n_past = 545, size = 90.652 MiB)
34.51.158.396 I slot get_availabl: id  3 | task -1 | selected slot by LCP similarity, sim_best = 0.998 (> 0.100 thold), f_keep = 0.982
34.51.158.561 I slot launch_slot_: id  3 | task 1722 | processing task, is_child = 0
34.51.158.562 I slot process_sing: id  0 | task -1 | saving idle slot to prompt cache
34.51.158.563 I slot process_sing: id  1 | task -1 | saving idle slot to prompt cache
34.51.158.563 I slot process_sing: id  2 | task -1 | saving idle slot to prompt cache
34.51.158.564 I slot process_sing: id  5 | task -1 | saving idle slot to prompt cache
34.51.159.566 W srv   prompt_save:  - saving prompt with length 2575, total state size = 191.417 MiB (draft: 0.000 MiB)
34.51.159.575 I srv         alloc:  - prompt is already in the cache, skipping
34.51.159.575 I slot process_sing: id  6 | task -1 | saving idle slot to prompt cache
34.51.160.682 W srv   prompt_save:  - saving prompt with length 457, total state size = 79.674 MiB (draft: 0.000 MiB)
34.51.160.684 I srv         alloc:  - prompt is already in the cache, skipping
34.51.160.685 I slot process_sing: id  7 | task -1 | saving idle slot to prompt cache
34.51.161.702 W srv   prompt_save:  - saving prompt with length 1185, total state size = 179.863 MiB (draft: 0.000 MiB)
34.51.161.704 I srv         alloc:  - prompt is already in the cache, skipping
34.51.161.705 I slot process_sing: id  8 | task -1 | saving idle slot to prompt cache
34.51.162.707 W srv   prompt_save:  - saving prompt with length 2939, total state size = 194.443 MiB (draft: 0.000 MiB)
34.51.162.712 I srv         alloc:  - prompt is already in the cache, skipping
34.51.162.713 I slot process_sing: id  9 | task -1 | saving idle slot to prompt cache
34.51.163.631 W srv   prompt_save:  - saving prompt with length 1230, total state size = 180.237 MiB (draft: 0.000 MiB)
34.51.163.634 I srv         alloc:  - prompt is already in the cache, skipping
34.51.414.520 I reasoning-budget: activated, budget=2147483647 tokens
34.51.414.994 I reasoning-budget: deactivated (natural end)
34.51.911.406 I slot print_timing: id  3 | task 1722 | prompt eval time =     177.69 ms /    15 tokens (   11.85 ms per token,    84.42 tokens per second)
34.51.911.410 I slot print_timing: id  3 | task 1722 |        eval time =     569.93 ms /    31 tokens (   18.38 ms per token,    54.39 tokens per second)
34.51.911.410 I slot print_timing: id  3 | task 1722 |       total time =     747.62 ms /    46 tokens
34.51.911.412 I slot print_timing: id  3 | task 1722 |    graphs reused =       1649
34.51.911.413 I slot print_timing: id  3 | task 1722 | draft acceptance = 0.85714 (   24 accepted /    28 generated)
34.51.911.427 I statistics        draft-mtp: #calls(b,g,a) =   13   1681   1729, #gen drafts =   1730, #acc drafts =  1343, #gen tokens =   6920, #acc tokens =  3855, dur(b,g,a) = 0.018, 17083.630, 0.802 ms
34.51.911.740 I slot      release: id  3 | task 1722 | stop processing: n_tokens = 7252, truncated = 0
34.52.160.719 I srv  params_from_: Chat format: peg-gemma4
34.52.231.218 I slot get_availabl: id  3 | task -1 | selected slot by LCP similarity, sim_best = 0.984 (> 0.100 thold), f_keep = 0.996
34.52.231.314 I slot launch_slot_: id  3 | task 1737 | processing task, is_child = 0
34.52.231.315 I slot process_sing: id  0 | task -1 | saving idle slot to prompt cache
34.52.231.316 I slot process_sing: id  1 | task -1 | saving idle slot to prompt cache
34.52.231.316 I slot process_sing: id  2 | task -1 | saving idle slot to prompt cache
34.52.231.316 I slot process_sing: id  5 | task -1 | saving idle slot to prompt cache
34.52.232.293 W srv   prompt_save:  - saving prompt with length 2575, total state size = 191.417 MiB (draft: 0.000 MiB)
34.52.232.302 I srv         alloc:  - prompt is already in the cache, skipping
34.52.232.302 I slot process_sing: id  6 | task -1 | saving idle slot to prompt cache
34.52.233.159 W srv   prompt_save:  - saving prompt with length 457, total state size = 79.674 MiB (draft: 0.000 MiB)
34.52.233.161 I srv         alloc:  - prompt is already in the cache, skipping
34.52.233.162 I slot process_sing: id  7 | task -1 | saving idle slot to prompt cache
34.52.234.085 W srv   prompt_save:  - saving prompt with length 1185, total state size = 179.863 MiB (draft: 0.000 MiB)
34.52.234.088 I srv         alloc:  - prompt is already in the cache, skipping
34.52.234.088 I slot process_sing: id  8 | task -1 | saving idle slot to prompt cache
34.52.235.526 W srv   prompt_save:  - saving prompt with length 2939, total state size = 194.443 MiB (draft: 0.000 MiB)
34.52.235.532 I srv         alloc:  - prompt is already in the cache, skipping
34.52.235.533 I slot process_sing: id  9 | task -1 | saving idle slot to prompt cache
34.52.236.435 W srv   prompt_save:  - saving prompt with length 1230, total state size = 180.237 MiB (draft: 0.000 MiB)
34.52.236.438 I srv         alloc:  - prompt is already in the cache, skipping
34.52.582.066 I reasoning-budget: activated, budget=2147483647 tokens
34.52.582.535 I reasoning-budget: deactivated (natural end)
34.53.142.704 I slot print_timing: id  3 | task 1737 | prompt eval time =     253.20 ms /   114 tokens (    2.22 ms per token,   450.23 tokens per second)
34.53.142.707 I slot print_timing: id  3 | task 1737 |        eval time =     640.13 ms /    25 tokens (   25.61 ms per token,    39.05 tokens per second)
34.53.142.707 I slot print_timing: id  3 | task 1737 |       total time =     893.33 ms /   139 tokens
34.53.142.709 I slot print_timing: id  3 | task 1737 |    graphs reused =       1661
34.53.142.710 I slot print_timing: id  3 | task 1737 | draft acceptance = 0.56250 (   18 accepted /    32 generated)
34.53.142.722 I statistics        draft-mtp: #calls(b,g,a) =   14   1696   1752, #gen drafts =   1753, #acc drafts =  1365, #gen tokens =   7012, #acc tokens =  3922, dur(b,g,a) = 0.019, 17261.494, 0.820 ms
34.53.143.055 I slot      release: id  3 | task 1737 | stop processing: n_tokens = 7361, truncated = 0
34.53.208.549 I slot print_timing: id  4 | task 1721 | n_decoded =    101, tg =  54.10 t/s
34.56.235.336 I slot print_timing: id  4 | task 1721 | n_decoded =    291, tg =  59.47 t/s
34.56.581.325 I slot print_timing: id  4 | task 1721 | prompt eval time =     230.48 ms /    19 tokens (   12.13 ms per token,    82.44 tokens per second)
34.56.581.328 I slot print_timing: id  4 | task 1721 |        eval time =    5239.54 ms /   318 tokens (   16.48 ms per token,    60.69 tokens per second)
34.56.581.329 I slot print_timing: id  4 | task 1721 |       total time =    5470.03 ms /   337 tokens
34.56.581.330 I slot print_timing: id  4 | task 1721 |    graphs reused =       1720
34.56.581.331 I slot print_timing: id  4 | task 1721 | draft acceptance = 0.71084 (  236 accepted /   332 generated)
34.56.581.343 I statistics        draft-mtp: #calls(b,g,a) =   14   1757   1814, #gen drafts =   1814, #acc drafts =  1422, #gen tokens =   7256, #acc tokens =  4088, dur(b,g,a) = 0.019, 17847.411, 0.851 ms
34.56.581.395 I slot      release: id  4 | task 1721 | stop processing: n_tokens = 883, truncated = 0
34.56.581.405 I srv  update_slots: all slots are idle
35.11.390.855 I srv  params_from_: Chat format: peg-gemma4
35.11.403.557 I slot get_availabl: id  3 | task -1 | selected slot by LCP similarity, sim_best = 0.995 (> 0.100 thold), f_keep = 0.996
35.11.403.695 I slot launch_slot_: id  3 | task 1810 | processing task, is_child = 0
35.11.403.697 I slot process_sing: id  0 | task -1 | saving idle slot to prompt cache
35.11.403.698 I slot process_sing: id  1 | task -1 | saving idle slot to prompt cache
35.11.403.698 I slot process_sing: id  2 | task -1 | saving idle slot to prompt cache
35.11.403.698 I slot process_sing: id  4 | task -1 | saving idle slot to prompt cache
35.11.404.682 W srv   prompt_save:  - saving prompt with length 883, total state size = 153.943 MiB (draft: 0.000 MiB)
35.11.466.589 I srv        update:  - cache state: 11 prompts, 2921.202 MiB (limits: 8192.000 MiB, 2649600 tokens, 2649600 est)
35.11.466.595 I srv        update:    - prompt 0xb639a4cacf50:     112 tokens, checkpoints:  1,    20.856 MiB
35.11.466.595 I srv        update:    - prompt 0xb63981c727c0:     102 tokens, checkpoints:  1,    19.113 MiB
35.11.466.596 I srv        update:    - prompt 0xb639a46dfdf0:     672 tokens, checkpoints:  2,   163.481 MiB
35.11.466.596 I srv        update:    - prompt 0xb639a46dc9f0:    1185 tokens, checkpoints:  2,   235.318 MiB
35.11.466.596 I srv        update:    - prompt 0xb639a86b7bd0:     457 tokens, checkpoints:  1,    81.003 MiB
35.11.466.597 I srv        update:    - prompt 0xb639a47c1650:    1230 tokens, checkpoints:  1,   181.566 MiB
35.11.466.597 I srv        update:    - prompt 0xb639a4c95e50:    1353 tokens, checkpoints:  3,   374.186 MiB
35.11.466.597 I srv        update:    - prompt 0xb639a4cadb10:    2575 tokens, checkpoints:  3,   610.970 MiB
35.11.466.597 I srv        update:    - prompt 0xb639a46d9890:    2939 tokens, checkpoints:  4,   589.093 MiB
35.11.466.598 I srv        update:    - prompt 0xb639a84535e0:    7338 tokens, checkpoints:  1,   401.021 MiB
35.11.466.598 I srv        update:    - prompt 0xb639a9287360:     883 tokens, checkpoints:  1,   244.595 MiB
35.11.466.599 I slot process_sing: id  5 | task -1 | saving idle slot to prompt cache
35.11.468.340 W srv   prompt_save:  - saving prompt with length 2575, total state size = 191.417 MiB (draft: 0.000 MiB)
35.11.468.380 I srv         alloc:  - prompt is already in the cache, skipping
35.11.468.380 I slot process_sing: id  6 | task -1 | saving idle slot to prompt cache
35.11.469.350 W srv   prompt_save:  - saving prompt with length 457, total state size = 79.674 MiB (draft: 0.000 MiB)
35.11.469.353 I srv         alloc:  - prompt is already in the cache, skipping
35.11.469.354 I slot process_sing: id  7 | task -1 | saving idle slot to prompt cache
35.11.470.283 W srv   prompt_save:  - saving prompt with length 1185, total state size = 179.863 MiB (draft: 0.000 MiB)
35.11.470.286 I srv         alloc:  - prompt is already in the cache, skipping
35.11.470.286 I slot process_sing: id  8 | task -1 | saving idle slot to prompt cache
35.11.471.195 W srv   prompt_save:  - saving prompt with length 2939, total state size = 194.443 MiB (draft: 0.000 MiB)
35.11.471.200 I srv         alloc:  - prompt is already in the cache, skipping
35.11.471.200 I slot process_sing: id  9 | task -1 | saving idle slot to prompt cache
35.11.472.171 W srv   prompt_save:  - saving prompt with length 1230, total state size = 180.237 MiB (draft: 0.000 MiB)
35.11.472.173 I srv         alloc:  - prompt is already in the cache, skipping
35.11.697.056 I reasoning-budget: activated, budget=2147483647 tokens
35.11.697.523 I reasoning-budget: deactivated (natural end)
35.12.232.432 I slot print_timing: id  3 | task 1810 | prompt eval time =     164.14 ms /    39 tokens (    4.21 ms per token,   237.60 tokens per second)
35.12.232.435 I slot print_timing: id  3 | task 1810 |        eval time =     595.98 ms /    38 tokens (   15.68 ms per token,    63.76 tokens per second)
35.12.232.436 I slot print_timing: id  3 | task 1810 |       total time =     760.12 ms /    77 tokens
35.12.232.437 I slot print_timing: id  3 | task 1810 |    graphs reused =       1728
35.12.232.438 I slot print_timing: id  3 | task 1810 | draft acceptance = 0.80556 (   29 accepted /    36 generated)
35.12.232.451 I statistics        draft-mtp: #calls(b,g,a) =   15   1766   1823, #gen drafts =   1823, #acc drafts =  1431, #gen tokens =   7292, #acc tokens =  4117, dur(b,g,a) = 0.021, 17946.894, 0.859 ms
35.12.232.928 I slot      release: id  3 | task 1810 | stop processing: n_tokens = 7412, truncated = 0
35.12.233.012 I srv  update_slots: all slots are idle
35.12.325.597 I srv  params_from_: Chat format: peg-gemma4
35.12.342.012 I slot get_availabl: id  3 | task -1 | selected slot by LCP similarity, sim_best = 0.976 (> 0.100 thold), f_keep = 0.995
35.12.342.227 I slot launch_slot_: id  3 | task 1823 | processing task, is_child = 0
35.12.342.230 I slot process_sing: id  0 | task -1 | saving idle slot to prompt cache
35.12.342.231 I slot process_sing: id  1 | task -1 | saving idle slot to prompt cache
35.12.342.231 I slot process_sing: id  2 | task -1 | saving idle slot to prompt cache
35.12.342.232 I slot process_sing: id  4 | task -1 | saving idle slot to prompt cache
35.12.343.270 W srv   prompt_save:  - saving prompt with length 883, total state size = 153.943 MiB (draft: 0.000 MiB)
35.12.343.279 I srv         alloc:  - prompt is already in the cache, skipping
35.12.343.280 I slot process_sing: id  5 | task -1 | saving idle slot to prompt cache
35.12.344.182 W srv   prompt_save:  - saving prompt with length 2575, total state size = 191.417 MiB (draft: 0.000 MiB)
35.12.344.186 I srv         alloc:  - prompt is already in the cache, skipping
35.12.344.186 I slot process_sing: id  6 | task -1 | saving idle slot to prompt cache
35.12.345.088 W srv   prompt_save:  - saving prompt with length 457, total state size = 79.674 MiB (draft: 0.000 MiB)
35.12.345.090 I srv         alloc:  - prompt is already in the cache, skipping
35.12.345.090 I slot process_sing: id  7 | task -1 | saving idle slot to prompt cache
35.12.345.958 W srv   prompt_save:  - saving prompt with length 1185, total state size = 179.863 MiB (draft: 0.000 MiB)
35.12.345.960 I srv         alloc:  - prompt is already in the cache, skipping
35.12.345.961 I slot process_sing: id  8 | task -1 | saving idle slot to prompt cache
35.12.346.957 W srv   prompt_save:  - saving prompt with length 2939, total state size = 194.443 MiB (draft: 0.000 MiB)
35.12.346.961 I srv         alloc:  - prompt is already in the cache, skipping
35.12.346.961 I slot process_sing: id  9 | task -1 | saving idle slot to prompt cache
35.12.347.837 W srv   prompt_save:  - saving prompt with length 1230, total state size = 180.237 MiB (draft: 0.000 MiB)
35.12.347.840 I srv         alloc:  - prompt is already in the cache, skipping
35.12.520.548 I slot create_check: id  3 | task 1823 | created context checkpoint 2 of 32 (pos_min = 6016, pos_max = 7551, n_tokens = 7552, size = 170.013 MiB)
35.12.640.255 I reasoning-budget: activated, budget=2147483647 tokens
35.14.029.723 I reasoning-budget: deactivated (natural end)
35.14.303.972 I slot print_timing: id  3 | task 1823 | n_decoded =    100, tg =  57.86 t/s
35.14.646.896 I slot print_timing: id  3 | task 1823 | prompt eval time =     227.81 ms /   182 tokens (    1.25 ms per token,   798.92 tokens per second)
35.14.646.899 I slot print_timing: id  3 | task 1823 |        eval time =    2071.11 ms /   124 tokens (   16.70 ms per token,    59.87 tokens per second)
35.14.646.900 I slot print_timing: id  3 | task 1823 |       total time =    2298.92 ms /   306 tokens
35.14.646.901 I slot print_timing: id  3 | task 1823 |    graphs reused =       1758
35.14.646.902 I slot print_timing: id  3 | task 1823 | draft acceptance = 0.75000 (   93 accepted /   124 generated)
35.14.646.918 I statistics        draft-mtp: #calls(b,g,a) =   16   1797   1854, #gen drafts =   1854, #acc drafts =  1460, #gen tokens =   7416, #acc tokens =  4210, dur(b,g,a) = 0.023, 18300.575, 0.874 ms
35.14.647.493 I slot      release: id  3 | task 1823 | stop processing: n_tokens = 7680, truncated = 0
35.14.647.509 I srv  update_slots: all slots are idle
35.27.164.754 I srv  params_from_: Chat format: peg-gemma4
35.27.179.309 I slot get_availabl: id  3 | task -1 | selected slot by LCP similarity, sim_best = 0.992 (> 0.100 thold), f_keep = 0.984
35.27.179.477 I slot launch_slot_: id  3 | task 1857 | processing task, is_child = 0
35.27.179.483 I slot process_sing: id  0 | task -1 | saving idle slot to prompt cache
35.27.179.487 I slot process_sing: id  1 | task -1 | saving idle slot to prompt cache
35.27.179.488 I slot process_sing: id  2 | task -1 | saving idle slot to prompt cache
35.27.179.488 I slot process_sing: id  4 | task -1 | saving idle slot to prompt cache
35.27.180.458 W srv   prompt_save:  - saving prompt with length 883, total state size = 153.943 MiB (draft: 0.000 MiB)
35.27.180.464 I srv         alloc:  - prompt is already in the cache, skipping
35.27.180.464 I slot process_sing: id  5 | task -1 | saving idle slot to prompt cache
35.27.181.667 W srv   prompt_save:  - saving prompt with length 2575, total state size = 191.417 MiB (draft: 0.000 MiB)
35.27.181.670 I srv         alloc:  - prompt is already in the cache, skipping
35.27.181.670 I slot process_sing: id  6 | task -1 | saving idle slot to prompt cache
35.27.182.583 W srv   prompt_save:  - saving prompt with length 457, total state size = 79.674 MiB (draft: 0.000 MiB)
35.27.182.586 I srv         alloc:  - prompt is already in the cache, skipping
35.27.182.586 I slot process_sing: id  7 | task -1 | saving idle slot to prompt cache
35.27.183.578 W srv   prompt_save:  - saving prompt with length 1185, total state size = 179.863 MiB (draft: 0.000 MiB)
35.27.183.586 I srv         alloc:  - prompt is already in the cache, skipping
35.27.183.586 I slot process_sing: id  8 | task -1 | saving idle slot to prompt cache
35.27.184.861 W srv   prompt_save:  - saving prompt with length 2939, total state size = 194.443 MiB (draft: 0.000 MiB)
35.27.184.867 I srv         alloc:  - prompt is already in the cache, skipping
35.27.184.868 I slot process_sing: id  9 | task -1 | saving idle slot to prompt cache
35.27.186.130 W srv   prompt_save:  - saving prompt with length 1230, total state size = 180.237 MiB (draft: 0.000 MiB)
35.27.186.132 I srv         alloc:  - prompt is already in the cache, skipping
35.27.424.889 I reasoning-budget: activated, budget=2147483647 tokens
35.28.950.034 I reasoning-budget: deactivated (natural end)
35.29.154.664 I slot print_timing: id  3 | task 1857 | n_decoded =    101, tg =  56.24 t/s
35.29.815.324 I slot print_timing: id  3 | task 1857 | prompt eval time =     172.38 ms /    64 tokens (    2.69 ms per token,   371.28 tokens per second)
35.29.815.326 I slot print_timing: id  3 | task 1857 |        eval time =    2456.66 ms /   139 tokens (   17.67 ms per token,    56.58 tokens per second)
35.29.815.327 I slot print_timing: id  3 | task 1857 |       total time =    2629.03 ms /   203 tokens
35.29.815.329 I slot print_timing: id  3 | task 1857 |    graphs reused =       1793
35.29.815.330 I slot print_timing: id  3 | task 1857 | draft acceptance = 0.68919 (  102 accepted /   148 generated)
35.29.815.345 I statistics        draft-mtp: #calls(b,g,a) =   17   1834   1891, #gen drafts =   1891, #acc drafts =  1491, #gen tokens =   7564, #acc tokens =  4312, dur(b,g,a) = 0.025, 18715.612, 0.898 ms
35.29.815.655 I slot      release: id  3 | task 1857 | stop processing: n_tokens = 7759, truncated = 0
35.29.815.676 I srv  update_slots: all slots are idle
35.29.963.729 I srv  params_from_: Chat format: peg-gemma4
35.29.977.434 I slot get_availabl: id  3 | task -1 | selected slot by LCP similarity, sim_best = 0.987 (> 0.100 thold), f_keep = 0.993
35.29.977.661 I slot launch_slot_: id  3 | task 1898 | processing task, is_child = 0
35.29.977.663 I slot process_sing: id  0 | task -1 | saving idle slot to prompt cache
35.29.977.664 I slot process_sing: id  1 | task -1 | saving idle slot to prompt cache
35.29.977.666 I slot process_sing: id  2 | task -1 | saving idle slot to prompt cache
35.29.977.666 I slot process_sing: id  4 | task -1 | saving idle slot to prompt cache
35.29.978.725 W srv   prompt_save:  - saving prompt with length 883, total state size = 153.943 MiB (draft: 0.000 MiB)
35.29.978.733 I srv         alloc:  - prompt is already in the cache, skipping
35.29.978.734 I slot process_sing: id  5 | task -1 | saving idle slot to prompt cache
35.29.979.680 W srv   prompt_save:  - saving prompt with length 2575, total state size = 191.417 MiB (draft: 0.000 MiB)
35.29.979.684 I srv         alloc:  - prompt is already in the cache, skipping
35.29.979.684 I slot process_sing: id  6 | task -1 | saving idle slot to prompt cache
35.29.980.612 W srv   prompt_save:  - saving prompt with length 457, total state size = 79.674 MiB (draft: 0.000 MiB)
35.29.980.614 I srv         alloc:  - prompt is already in the cache, skipping
35.29.980.615 I slot process_sing: id  7 | task -1 | saving idle slot to prompt cache
35.29.981.526 W srv   prompt_save:  - saving prompt with length 1185, total state size = 179.863 MiB (draft: 0.000 MiB)
35.29.981.529 I srv         alloc:  - prompt is already in the cache, skipping
35.29.981.529 I slot process_sing: id  8 | task -1 | saving idle slot to prompt cache
35.29.982.519 W srv   prompt_save:  - saving prompt with length 2939, total state size = 194.443 MiB (draft: 0.000 MiB)
35.29.982.524 I srv         alloc:  - prompt is already in the cache, skipping
35.29.982.524 I slot process_sing: id  9 | task -1 | saving idle slot to prompt cache
35.29.983.452 W srv   prompt_save:  - saving prompt with length 1230, total state size = 180.237 MiB (draft: 0.000 MiB)
35.29.983.454 I srv         alloc:  - prompt is already in the cache, skipping
35.30.473.914 I slot print_timing: id  3 | task 1898 | prompt eval time =     145.59 ms /   104 tokens (    1.40 ms per token,   714.33 tokens per second)
35.30.473.917 I slot print_timing: id  3 | task 1898 |        eval time =     344.73 ms /    15 tokens (   22.98 ms per token,    43.51 tokens per second)
35.30.473.918 I slot print_timing: id  3 | task 1898 |       total time =     490.32 ms /   119 tokens
35.30.473.919 I slot print_timing: id  3 | task 1898 |    graphs reused =       1797
35.30.473.920 I slot print_timing: id  3 | task 1898 | draft acceptance = 0.55000 (   11 accepted /    20 generated)
35.30.473.935 I statistics        draft-mtp: #calls(b,g,a) =   18   1839   1896, #gen drafts =   1896, #acc drafts =  1496, #gen tokens =   7584, #acc tokens =  4323, dur(b,g,a) = 0.027, 18775.526, 0.901 ms
35.30.474.283 I slot      release: id  3 | task 1898 | stop processing: n_tokens = 7825, truncated = 0
35.30.474.300 I srv  update_slots: all slots are idle
37.41.181.414 I srv  params_from_: Chat format: peg-gemma4
37.41.182.335 I slot get_availabl: id  4 | task -1 | selected slot by LCP similarity, sim_best = 0.935 (> 0.100 thold), f_keep = 0.622
37.41.182.403 I slot launch_slot_: id  4 | task 1906 | processing task, is_child = 0
37.41.182.404 I slot process_sing: id  0 | task -1 | saving idle slot to prompt cache
37.41.182.405 I slot process_sing: id  1 | task -1 | saving idle slot to prompt cache
37.41.182.405 I slot process_sing: id  2 | task -1 | saving idle slot to prompt cache
37.41.182.406 I slot process_sing: id  3 | task -1 | saving idle slot to prompt cache
37.41.183.415 W srv   prompt_save:  - saving prompt with length 7825, total state size = 235.056 MiB (draft: 0.000 MiB)
37.41.309.537 I srv  params_from_: Chat format: peg-gemma4
37.41.327.119 I srv        update:  - cache state: 12 prompts, 3496.283 MiB (limits: 8192.000 MiB, 2649600 tokens, 2649600 est)
37.41.327.124 I srv        update:    - prompt 0xb639a4cacf50:     112 tokens, checkpoints:  1,    20.856 MiB
37.41.327.125 I srv        update:    - prompt 0xb63981c727c0:     102 tokens, checkpoints:  1,    19.113 MiB
37.41.327.125 I srv        update:    - prompt 0xb639a46dfdf0:     672 tokens, checkpoints:  2,   163.481 MiB
37.41.327.126 I srv        update:    - prompt 0xb639a46dc9f0:    1185 tokens, checkpoints:  2,   235.318 MiB
37.41.327.126 I srv        update:    - prompt 0xb639a86b7bd0:     457 tokens, checkpoints:  1,    81.003 MiB
37.41.327.127 I srv        update:    - prompt 0xb639a47c1650:    1230 tokens, checkpoints:  1,   181.566 MiB
37.41.327.127 I srv        update:    - prompt 0xb639a4c95e50:    1353 tokens, checkpoints:  3,   374.186 MiB
37.41.327.127 I srv        update:    - prompt 0xb639a4cadb10:    2575 tokens, checkpoints:  3,   610.970 MiB
37.41.327.128 I srv        update:    - prompt 0xb639a46d9890:    2939 tokens, checkpoints:  4,   589.093 MiB
37.41.327.128 I srv        update:    - prompt 0xb639a84535e0:    7338 tokens, checkpoints:  1,   401.021 MiB
37.41.327.128 I srv        update:    - prompt 0xb639a9287360:     883 tokens, checkpoints:  1,   244.595 MiB
37.41.327.128 I srv        update:    - prompt 0xb639a8128da0:    7825 tokens, checkpoints:  2,   575.081 MiB
37.41.327.129 I slot process_sing: id  5 | task -1 | saving idle slot to prompt cache
37.41.328.111 W srv   prompt_save:  - saving prompt with length 2575, total state size = 191.417 MiB (draft: 0.000 MiB)
37.41.328.118 I srv         alloc:  - prompt is already in the cache, skipping
37.41.328.118 I slot process_sing: id  6 | task -1 | saving idle slot to prompt cache
37.41.329.420 W srv   prompt_save:  - saving prompt with length 457, total state size = 79.674 MiB (draft: 0.000 MiB)
37.41.329.424 I srv         alloc:  - prompt is already in the cache, skipping
37.41.329.424 I slot process_sing: id  7 | task -1 | saving idle slot to prompt cache
37.41.330.690 W srv   prompt_save:  - saving prompt with length 1185, total state size = 179.863 MiB (draft: 0.000 MiB)
37.41.330.694 I srv         alloc:  - prompt is already in the cache, skipping
37.41.330.694 I slot process_sing: id  8 | task -1 | saving idle slot to prompt cache
37.41.331.739 W srv   prompt_save:  - saving prompt with length 2939, total state size = 194.443 MiB (draft: 0.000 MiB)
37.41.331.745 I srv         alloc:  - prompt is already in the cache, skipping
37.41.331.745 I slot process_sing: id  9 | task -1 | saving idle slot to prompt cache
37.41.332.735 W srv   prompt_save:  - saving prompt with length 1230, total state size = 180.237 MiB (draft: 0.000 MiB)
37.41.332.738 I srv         alloc:  - prompt is already in the cache, skipping
37.41.332.747 I slot get_availabl: id  3 | task -1 | selected slot by LCP similarity, sim_best = 0.263 (> 0.100 thold), f_keep = 0.244
37.41.332.747 I srv  get_availabl: updating prompt cache
37.41.334.156 W srv   prompt_save:  - saving prompt with length 7825, total state size = 235.056 MiB (draft: 0.000 MiB)
37.41.334.166 I srv         alloc:  - prompt is already in the cache, skipping
37.41.334.168 I srv          load:  - looking for better prompt, base f_keep = 0.244, sim = 0.263
37.41.334.174 I srv        update:  - cache state: 12 prompts, 3496.283 MiB (limits: 8192.000 MiB, 2649600 tokens, 2649600 est)
37.41.334.174 I srv        update:    - prompt 0xb639a4cacf50:     112 tokens, checkpoints:  1,    20.856 MiB
37.41.334.175 I srv        update:    - prompt 0xb63981c727c0:     102 tokens, checkpoints:  1,    19.113 MiB
37.41.334.175 I srv        update:    - prompt 0xb639a46dfdf0:     672 tokens, checkpoints:  2,   163.481 MiB
37.41.334.175 I srv        update:    - prompt 0xb639a46dc9f0:    1185 tokens, checkpoints:  2,   235.318 MiB
37.41.334.176 I srv        update:    - prompt 0xb639a86b7bd0:     457 tokens, checkpoints:  1,    81.003 MiB
37.41.334.176 I srv        update:    - prompt 0xb639a47c1650:    1230 tokens, checkpoints:  1,   181.566 MiB
37.41.334.176 I srv        update:    - prompt 0xb639a4c95e50:    1353 tokens, checkpoints:  3,   374.186 MiB
37.41.334.177 I srv        update:    - prompt 0xb639a4cadb10:    2575 tokens, checkpoints:  3,   610.970 MiB
37.41.334.177 I srv        update:    - prompt 0xb639a46d9890:    2939 tokens, checkpoints:  4,   589.093 MiB
37.41.334.177 I srv        update:    - prompt 0xb639a84535e0:    7338 tokens, checkpoints:  1,   401.021 MiB
37.41.334.178 I srv        update:    - prompt 0xb639a9287360:     883 tokens, checkpoints:  1,   244.595 MiB
37.41.334.178 I srv        update:    - prompt 0xb639a8128da0:    7825 tokens, checkpoints:  2,   575.081 MiB
37.41.334.178 I srv  get_availabl: prompt cache update took 1.43 ms
37.41.334.320 I slot launch_slot_: id  3 | task 1907 | processing task, is_child = 0
37.41.334.321 I slot process_sing: id  0 | task -1 | saving idle slot to prompt cache
37.41.334.322 I slot process_sing: id  1 | task -1 | saving idle slot to prompt cache
37.41.334.322 I slot process_sing: id  2 | task -1 | saving idle slot to prompt cache
37.41.334.322 I slot process_sing: id  5 | task -1 | saving idle slot to prompt cache
37.41.335.424 W srv   prompt_save:  - saving prompt with length 2575, total state size = 191.417 MiB (draft: 0.000 MiB)
37.41.335.427 I srv         alloc:  - prompt is already in the cache, skipping
37.41.335.428 I slot process_sing: id  6 | task -1 | saving idle slot to prompt cache
37.41.336.431 W srv   prompt_save:  - saving prompt with length 457, total state size = 79.674 MiB (draft: 0.000 MiB)
37.41.336.433 I srv         alloc:  - prompt is already in the cache, skipping
37.41.336.433 I slot process_sing: id  7 | task -1 | saving idle slot to prompt cache
37.41.337.547 W srv   prompt_save:  - saving prompt with length 1185, total state size = 179.863 MiB (draft: 0.000 MiB)
37.41.337.549 I srv         alloc:  - prompt is already in the cache, skipping
37.41.337.549 I slot process_sing: id  8 | task -1 | saving idle slot to prompt cache
37.41.338.632 W srv   prompt_save:  - saving prompt with length 2939, total state size = 194.443 MiB (draft: 0.000 MiB)
37.41.338.637 I srv         alloc:  - prompt is already in the cache, skipping
37.41.338.637 I slot process_sing: id  9 | task -1 | saving idle slot to prompt cache
37.41.339.618 W srv   prompt_save:  - saving prompt with length 1230, total state size = 180.237 MiB (draft: 0.000 MiB)
37.41.339.621 I srv         alloc:  - prompt is already in the cache, skipping
37.41.339.636 I slot update_slots: id  3 | task 1907 | Checking checkpoint with [6016, 7551] against 883...
37.41.339.636 I slot update_slots: id  3 | task 1907 | Checking checkpoint with [5667, 7202] against 883...
37.41.339.637 W slot update_slots: id  3 | task 1907 | forcing full prompt re-processing due to lack of cache data (likely due to SWA or hybrid/recurrent memory, see https://github.com/ggml-org/llama.cpp/pull/13194#issuecomment-2868343055)
37.41.339.639 W slot update_slots: id  3 | task 1907 | erased invalidated context checkpoint (pos_min = 5667, pos_max = 7202, n_tokens = 7203, n_swa = 1024, pos_next = 0, size = 170.013 MiB)
37.41.358.927 W slot update_slots: id  3 | task 1907 | erased invalidated context checkpoint (pos_min = 6016, pos_max = 7551, n_tokens = 7552, n_swa = 1024, pos_next = 0, size = 170.013 MiB)
37.45.019.548 I slot print_timing: id  3 | task 1907 | prompt processing, n_tokens =   6144, progress = 0.85, t =   3.68 s / 1669.61 tokens per second
37.45.019.678 I slot update_slots: id  4 | task 1906 | Checking checkpoint with [0, 545] against 0...
37.45.022.214 W slot update_slots: id  4 | task 1906 | restored context checkpoint (pos_min = 0, pos_max = 545, n_tokens = 546, n_past = 545, size = 90.652 MiB)
37.45.457.971 I slot print_timing: id  3 | task 1907 | prompt processing, n_tokens =   6731, progress = 0.93, t =   4.12 s / 1634.40 tokens per second
37.45.825.696 I slot print_timing: id  3 | task 1907 | prompt processing, n_tokens =   7206, progress = 0.99, t =   4.49 s / 1606.31 tokens per second
37.45.870.462 I slot create_check: id  3 | task 1907 | created context checkpoint 1 of 32 (pos_min = 5670, pos_max = 7205, n_tokens = 7206, size = 170.013 MiB)
37.46.015.247 I slot print_timing: id  3 | task 1907 | prompt processing, n_tokens =   7243, progress = 1.00, t =   4.68 s / 1549.10 tokens per second
37.46.195.972 I reasoning-budget: activated, budget=2147483647 tokens
37.48.224.467 I slot print_timing: id  4 | task 1906 | n_decoded =    103, tg =  46.42 t/s
37.49.154.637 I slot print_timing: id  3 | task 1907 | n_decoded =    102, tg =  33.57 t/s
37.50.403.104 I reasoning-budget: deactivated (natural end)
37.50.887.953 I slot print_timing: id  3 | task 1907 | prompt eval time =    4776.73 ms /  7247 tokens (    0.66 ms per token,  1517.15 tokens per second)
37.50.887.957 I slot print_timing: id  3 | task 1907 |        eval time =    4771.42 ms /   180 tokens (   26.51 ms per token,    37.72 tokens per second)
37.50.887.957 I slot print_timing: id  3 | task 1907 |       total time =    9548.15 ms /  7427 tokens
37.50.887.958 I slot print_timing: id  3 | task 1907 |    graphs reused =       1856
37.50.887.959 I slot print_timing: id  3 | task 1907 | draft acceptance = 0.48770 (  119 accepted /   244 generated)
37.50.887.974 I statistics        draft-mtp: #calls(b,g,a) =   20   1901   2018, #gen drafts =   2019, #acc drafts =  1591, #gen tokens =   8076, #acc tokens =  4596, dur(b,g,a) = 0.031, 19532.040, 0.991 ms
37.50.888.288 I slot      release: id  3 | task 1907 | stop processing: n_tokens = 7427, truncated = 0
37.51.200.533 I srv  params_from_: Chat format: peg-gemma4
37.51.218.394 I slot get_availabl: id  3 | task -1 | selected slot by LCP similarity, sim_best = 0.974 (> 0.100 thold), f_keep = 0.996
37.51.218.490 I slot launch_slot_: id  3 | task 1981 | processing task, is_child = 0
37.51.218.491 I slot process_sing: id  0 | task -1 | saving idle slot to prompt cache
37.51.218.492 I slot process_sing: id  1 | task -1 | saving idle slot to prompt cache
37.51.218.492 I slot process_sing: id  2 | task -1 | saving idle slot to prompt cache
37.51.218.493 I slot process_sing: id  5 | task -1 | saving idle slot to prompt cache
37.51.219.513 W srv   prompt_save:  - saving prompt with length 2575, total state size = 191.417 MiB (draft: 0.000 MiB)
37.51.219.522 I srv         alloc:  - prompt is already in the cache, skipping
37.51.219.523 I slot process_sing: id  6 | task -1 | saving idle slot to prompt cache
37.51.220.479 W srv   prompt_save:  - saving prompt with length 457, total state size = 79.674 MiB (draft: 0.000 MiB)
37.51.220.481 I srv         alloc:  - prompt is already in the cache, skipping
37.51.220.482 I slot process_sing: id  7 | task -1 | saving idle slot to prompt cache
37.51.221.538 W srv   prompt_save:  - saving prompt with length 1185, total state size = 179.863 MiB (draft: 0.000 MiB)
37.51.221.540 I srv         alloc:  - prompt is already in the cache, skipping
37.51.221.541 I slot process_sing: id  8 | task -1 | saving idle slot to prompt cache
37.51.222.513 W srv   prompt_save:  - saving prompt with length 2939, total state size = 194.443 MiB (draft: 0.000 MiB)
37.51.222.519 I srv         alloc:  - prompt is already in the cache, skipping
37.51.222.519 I slot process_sing: id  9 | task -1 | saving idle slot to prompt cache
37.51.223.437 W srv   prompt_save:  - saving prompt with length 1230, total state size = 180.237 MiB (draft: 0.000 MiB)
37.51.223.440 I srv         alloc:  - prompt is already in the cache, skipping
37.51.424.941 I slot print_timing: id  4 | task 1906 | n_decoded =    244, tg =  45.02 t/s
37.51.477.695 I slot create_check: id  3 | task 1981 | created context checkpoint 2 of 32 (pos_min = 6060, pos_max = 7595, n_tokens = 7596, size = 170.013 MiB)
37.51.660.989 I reasoning-budget: activated, budget=2147483647 tokens
37.53.263.933 I slot print_timing: id  3 | task 1981 | n_decoded =    101, tg =  60.01 t/s
37.54.446.555 I reasoning-budget: deactivated (natural end)
37.54.449.053 I slot print_timing: id  4 | task 1906 | n_decoded =    374, tg =  44.29 t/s
37.55.712.132 I slot print_timing: id  3 | task 1981 | prompt eval time =     347.54 ms /   200 tokens (    1.74 ms per token,   575.48 tokens per second)
37.55.712.135 I slot print_timing: id  3 | task 1981 |        eval time =    4131.35 ms /   208 tokens (   19.86 ms per token,    50.35 tokens per second)
37.55.712.136 I slot print_timing: id  3 | task 1981 |       total time =    4478.88 ms /   408 tokens
37.55.712.138 I slot print_timing: id  3 | task 1981 |    graphs reused =       1911
37.55.712.139 I slot print_timing: id  3 | task 1981 | draft acceptance = 0.75000 (  156 accepted /   208 generated)
37.55.712.153 I statistics        draft-mtp: #calls(b,g,a) =   21   1960   2129, #gen drafts =   2130, #acc drafts =  1680, #gen tokens =   8520, #acc tokens =  4899, dur(b,g,a) = 0.033, 20265.668, 1.068 ms
37.55.712.473 I slot      release: id  3 | task 1981 | stop processing: n_tokens = 7808, truncated = 0
37.55.986.211 I srv  params_from_: Chat format: peg-gemma4
37.56.052.481 I slot get_availabl: id  3 | task -1 | selected slot by LCP similarity, sim_best = 0.894 (> 0.100 thold), f_keep = 0.993
37.56.052.587 I slot launch_slot_: id  3 | task 2041 | processing task, is_child = 0
37.56.052.588 I slot process_sing: id  0 | task -1 | saving idle slot to prompt cache
37.56.052.588 I slot process_sing: id  1 | task -1 | saving idle slot to prompt cache
37.56.052.589 I slot process_sing: id  2 | task -1 | saving idle slot to prompt cache
37.56.052.589 I slot process_sing: id  5 | task -1 | saving idle slot to prompt cache
37.56.053.775 W srv   prompt_save:  - saving prompt with length 2575, total state size = 191.417 MiB (draft: 0.000 MiB)
37.56.053.784 I srv         alloc:  - prompt is already in the cache, skipping
37.56.053.784 I slot process_sing: id  6 | task -1 | saving idle slot to prompt cache
37.56.054.982 W srv   prompt_save:  - saving prompt with length 457, total state size = 79.674 MiB (draft: 0.000 MiB)
37.56.054.984 I srv         alloc:  - prompt is already in the cache, skipping
37.56.054.985 I slot process_sing: id  7 | task -1 | saving idle slot to prompt cache
37.56.056.176 W srv   prompt_save:  - saving prompt with length 1185, total state size = 179.863 MiB (draft: 0.000 MiB)
37.56.056.179 I srv         alloc:  - prompt is already in the cache, skipping
37.56.056.179 I slot process_sing: id  8 | task -1 | saving idle slot to prompt cache
37.56.057.687 W srv   prompt_save:  - saving prompt with length 2939, total state size = 194.443 MiB (draft: 0.000 MiB)
37.56.057.692 I srv         alloc:  - prompt is already in the cache, skipping
37.56.057.693 I slot process_sing: id  9 | task -1 | saving idle slot to prompt cache
37.56.059.171 W srv   prompt_save:  - saving prompt with length 1230, total state size = 180.237 MiB (draft: 0.000 MiB)
37.56.059.174 I srv         alloc:  - prompt is already in the cache, skipping
37.56.454.468 I slot create_check: id  3 | task 2041 | created context checkpoint 3 of 32 (pos_min = 6613, pos_max = 8148, n_tokens = 8149, size = 170.013 MiB)
37.56.895.978 I slot create_check: id  3 | task 2041 | created context checkpoint 4 of 32 (pos_min = 7125, pos_max = 8660, n_tokens = 8661, size = 170.013 MiB)
37.57.088.795 I reasoning-budget: activated, budget=2147483647 tokens
37.57.505.438 I slot print_timing: id  4 | task 1906 | prompt eval time =     985.61 ms /    42 tokens (   23.47 ms per token,    42.61 tokens per second)
37.57.505.442 I slot print_timing: id  4 | task 1906 |        eval time =   11500.01 ms /   479 tokens (   24.01 ms per token,    41.65 tokens per second)
37.57.505.443 I slot print_timing: id  4 | task 1906 |       total time =   12485.62 ms /   521 tokens
37.57.505.444 I slot print_timing: id  4 | task 1906 |    graphs reused =       1920
37.57.505.445 I slot print_timing: id  4 | task 1906 | draft acceptance = 0.64074 (  346 accepted /   540 generated)
37.57.505.459 I statistics        draft-mtp: #calls(b,g,a) =   22   1974   2150, #gen drafts =   2150, #acc drafts =  1700, #gen tokens =   8600, #acc tokens =  4968, dur(b,g,a) = 0.035, 20430.834, 1.085 ms
37.57.505.518 I slot      release: id  4 | task 1906 | stop processing: n_tokens = 1068, truncated = 0
37.57.505.529 I slot print_timing: id  4 | task -1 | n_decoded =    479, tg =  41.65 t/s
37.59.107.840 I slot print_timing: id  3 | task 2041 | n_decoded =    100, tg =  47.59 t/s
38.00.638.343 I reasoning-budget: deactivated (natural end)
38.02.139.773 I slot print_timing: id  3 | task 2041 | n_decoded =    276, tg =  53.77 t/s
38.02.751.928 I slot print_timing: id  3 | task 2041 | prompt eval time =     938.18 ms /   915 tokens (    1.03 ms per token,   975.29 tokens per second)
38.02.751.931 I slot print_timing: id  3 | task 2041 |        eval time =    5745.22 ms /   306 tokens (   18.78 ms per token,    53.26 tokens per second)
38.02.751.931 I slot print_timing: id  3 | task 2041 |       total time =    6683.40 ms /  1221 tokens
38.02.751.932 I slot print_timing: id  3 | task 2041 |    graphs reused =       1995
38.02.751.933 I slot print_timing: id  3 | task 2041 | draft acceptance = 0.66369 (  223 accepted /   336 generated)
38.02.751.946 I statistics        draft-mtp: #calls(b,g,a) =   22   2052   2228, #gen drafts =   2228, #acc drafts =  1766, #gen tokens =   8912, #acc tokens =  5167, dur(b,g,a) = 0.035, 21312.066, 1.136 ms
38.02.752.325 I slot      release: id  3 | task 2041 | stop processing: n_tokens = 8972, truncated = 0
38.02.752.345 I srv  update_slots: all slots are idle
43.49.785.160 I srv  params_from_: Chat format: peg-gemma4
43.49.799.985 I slot get_availabl: id  3 | task -1 | selected slot by LCP similarity, sim_best = 0.671 (> 0.100 thold), f_keep = 0.808
43.49.800.158 I slot launch_slot_: id  3 | task 2129 | processing task, is_child = 0
43.49.800.161 I slot process_sing: id  0 | task -1 | saving idle slot to prompt cache
43.49.800.161 I slot process_sing: id  1 | task -1 | saving idle slot to prompt cache
43.49.800.162 I slot process_sing: id  2 | task -1 | saving idle slot to prompt cache
43.49.800.162 I slot process_sing: id  4 | task -1 | saving idle slot to prompt cache
43.49.801.172 W srv   prompt_save:  - saving prompt with length 1068, total state size = 178.890 MiB (draft: 0.000 MiB)
43.49.872.150 I srv        update:  - cache state: 13 prompts, 3765.826 MiB (limits: 8192.000 MiB, 2649600 tokens, 2649600 est)
43.49.872.156 I srv        update:    - prompt 0xb639a4cacf50:     112 tokens, checkpoints:  1,    20.856 MiB
43.49.872.156 I srv        update:    - prompt 0xb63981c727c0:     102 tokens, checkpoints:  1,    19.113 MiB
43.49.872.156 I srv        update:    - prompt 0xb639a46dfdf0:     672 tokens, checkpoints:  2,   163.481 MiB
43.49.872.157 I srv        update:    - prompt 0xb639a46dc9f0:    1185 tokens, checkpoints:  2,   235.318 MiB
43.49.872.157 I srv        update:    - prompt 0xb639a86b7bd0:     457 tokens, checkpoints:  1,    81.003 MiB
43.49.872.157 I srv        update:    - prompt 0xb639a47c1650:    1230 tokens, checkpoints:  1,   181.566 MiB
43.49.872.158 I srv        update:    - prompt 0xb639a4c95e50:    1353 tokens, checkpoints:  3,   374.186 MiB
43.49.872.158 I srv        update:    - prompt 0xb639a4cadb10:    2575 tokens, checkpoints:  3,   610.970 MiB
43.49.872.158 I srv        update:    - prompt 0xb639a46d9890:    2939 tokens, checkpoints:  4,   589.093 MiB
43.49.872.159 I srv        update:    - prompt 0xb639a84535e0:    7338 tokens, checkpoints:  1,   401.021 MiB
43.49.872.159 I srv        update:    - prompt 0xb639a9287360:     883 tokens, checkpoints:  1,   244.595 MiB
43.49.872.159 I srv        update:    - prompt 0xb639a8128da0:    7825 tokens, checkpoints:  2,   575.081 MiB
43.49.872.160 I srv        update:    - prompt 0xb639a8151fa0:    1068 tokens, checkpoints:  1,   269.542 MiB
43.49.872.160 I slot process_sing: id  5 | task -1 | saving idle slot to prompt cache
43.49.873.202 W srv   prompt_save:  - saving prompt with length 2575, total state size = 191.417 MiB (draft: 0.000 MiB)
43.49.873.208 I srv         alloc:  - prompt is already in the cache, skipping
43.49.873.209 I slot process_sing: id  6 | task -1 | saving idle slot to prompt cache
43.49.874.104 W srv   prompt_save:  - saving prompt with length 457, total state size = 79.674 MiB (draft: 0.000 MiB)
43.49.874.107 I srv         alloc:  - prompt is already in the cache, skipping
43.49.874.107 I slot process_sing: id  7 | task -1 | saving idle slot to prompt cache
43.49.875.161 W srv   prompt_save:  - saving prompt with length 1185, total state size = 179.863 MiB (draft: 0.000 MiB)
43.49.875.164 I srv         alloc:  - prompt is already in the cache, skipping
43.49.875.164 I slot process_sing: id  8 | task -1 | saving idle slot to prompt cache
43.49.876.224 W srv   prompt_save:  - saving prompt with length 2939, total state size = 194.443 MiB (draft: 0.000 MiB)
43.49.876.229 I srv         alloc:  - prompt is already in the cache, skipping
43.49.876.230 I slot process_sing: id  9 | task -1 | saving idle slot to prompt cache
43.49.877.392 W srv   prompt_save:  - saving prompt with length 1230, total state size = 180.237 MiB (draft: 0.000 MiB)
43.49.877.395 I srv         alloc:  - prompt is already in the cache, skipping
43.49.877.415 I slot update_slots: id  3 | task 2129 | Checking checkpoint with [7125, 8660] against 6223...
43.49.877.417 I slot update_slots: id  3 | task 2129 | Checking checkpoint with [6613, 8148] against 6223...
43.49.877.417 I slot update_slots: id  3 | task 2129 | Checking checkpoint with [6060, 7595] against 6223...
43.49.877.418 I slot update_slots: id  3 | task 2129 | Checking checkpoint with [5670, 7205] against 6223...
43.49.881.828 W slot update_slots: id  3 | task 2129 | restored context checkpoint (pos_min = 5670, pos_max = 7205, n_tokens = 7206, n_past = 7205, size = 170.013 MiB)
43.49.881.831 W slot update_slots: id  3 | task 2129 | erased invalidated context checkpoint (pos_min = 6060, pos_max = 7595, n_tokens = 7596, n_swa = 1024, pos_next = 7205, size = 170.013 MiB)
43.49.893.844 W slot update_slots: id  3 | task 2129 | erased invalidated context checkpoint (pos_min = 6613, pos_max = 8148, n_tokens = 8149, n_swa = 1024, pos_next = 7205, size = 170.013 MiB)
43.49.904.689 W slot update_slots: id  3 | task 2129 | erased invalidated context checkpoint (pos_min = 7125, pos_max = 8660, n_tokens = 8661, n_swa = 1024, pos_next = 7205, size = 170.013 MiB)
43.50.835.604 I slot create_check: id  3 | task 2129 | created context checkpoint 2 of 32 (pos_min = 6954, pos_max = 8489, n_tokens = 8490, size = 170.013 MiB)
43.52.141.054 I slot create_check: id  3 | task 2129 | created context checkpoint 3 of 32 (pos_min = 8748, pos_max = 10283, n_tokens = 10284, size = 170.013 MiB)
43.52.542.946 I slot create_check: id  3 | task 2129 | created context checkpoint 4 of 32 (pos_min = 9260, pos_max = 10795, n_tokens = 10796, size = 170.013 MiB)
43.52.671.027 I reasoning-budget: activated, budget=2147483647 tokens
43.54.338.776 I slot print_timing: id  3 | task 2129 | n_decoded =    101, tg =  58.27 t/s
43.57.355.396 I slot print_timing: id  3 | task 2129 | n_decoded =    225, tg =  47.37 t/s
44.00.366.068 I slot print_timing: id  3 | task 2129 | n_decoded =    371, tg =  47.81 t/s
44.03.398.599 I slot print_timing: id  3 | task 2129 | n_decoded =    532, tg =  49.29 t/s
44.06.414.537 I slot print_timing: id  3 | task 2129 | n_decoded =    666, tg =  48.23 t/s
44.09.449.715 I slot print_timing: id  3 | task 2129 | n_decoded =    819, tg =  48.62 t/s
44.12.489.565 I slot print_timing: id  3 | task 2129 | n_decoded =    976, tg =  49.08 t/s
44.14.741.289 I reasoning-budget: deactivated (natural end)
44.15.534.471 I slot print_timing: id  3 | task 2129 | n_decoded =   1135, tg =  49.50 t/s
44.16.806.744 I slot print_timing: id  3 | task 2129 | prompt eval time =    2728.04 ms /  3595 tokens (    0.76 ms per token,  1317.79 tokens per second)
44.16.806.747 I slot print_timing: id  3 | task 2129 |        eval time =   24201.13 ms /  1220 tokens (   19.84 ms per token,    50.41 tokens per second)
44.16.806.748 I slot print_timing: id  3 | task 2129 |       total time =   26929.17 ms /  4815 tokens
44.16.806.749 I slot print_timing: id  3 | task 2129 |    graphs reused =       2326
44.16.806.750 I slot print_timing: id  3 | task 2129 | draft acceptance = 0.65774 (  884 accepted /  1344 generated)
44.16.806.764 I statistics        draft-mtp: #calls(b,g,a) =   23   2388   2564, #gen drafts =   2564, #acc drafts =  2048, #gen tokens =  10256, #acc tokens =  6051, dur(b,g,a) = 0.037, 25493.657, 1.347 ms
44.16.807.167 I slot      release: id  3 | task 2129 | stop processing: n_tokens = 12020, truncated = 0
44.16.807.191 I srv  update_slots: all slots are idle
44.16.917.648 I srv  params_from_: Chat format: peg-gemma4
44.16.936.846 I slot get_availabl: id  3 | task -1 | selected slot by LCP similarity, sim_best = 0.294 (> 0.100 thold), f_keep = 0.989
44.16.937.006 I slot launch_slot_: id  3 | task 2470 | processing task, is_child = 0
44.16.937.008 I slot process_sing: id  0 | task -1 | saving idle slot to prompt cache
44.16.937.009 I slot process_sing: id  1 | task -1 | saving idle slot to prompt cache
44.16.937.009 I slot process_sing: id  2 | task -1 | saving idle slot to prompt cache
44.16.937.009 I slot process_sing: id  4 | task -1 | saving idle slot to prompt cache
44.16.938.015 W srv   prompt_save:  - saving prompt with length 1068, total state size = 178.890 MiB (draft: 0.000 MiB)
44.16.938.024 I srv         alloc:  - prompt is already in the cache, skipping
44.16.938.025 I slot process_sing: id  5 | task -1 | saving idle slot to prompt cache
44.16.939.057 W srv   prompt_save:  - saving prompt with length 2575, total state size = 191.417 MiB (draft: 0.000 MiB)
44.16.939.062 I srv         alloc:  - prompt is already in the cache, skipping
44.16.939.062 I slot process_sing: id  6 | task -1 | saving idle slot to prompt cache
44.16.939.983 W srv   prompt_save:  - saving prompt with length 457, total state size = 79.674 MiB (draft: 0.000 MiB)
44.16.939.986 I srv         alloc:  - prompt is already in the cache, skipping
44.16.939.986 I slot process_sing: id  7 | task -1 | saving idle slot to prompt cache
44.16.941.009 W srv   prompt_save:  - saving prompt with length 1185, total state size = 179.863 MiB (draft: 0.000 MiB)
44.16.941.012 I srv         alloc:  - prompt is already in the cache, skipping
44.16.941.012 I slot process_sing: id  8 | task -1 | saving idle slot to prompt cache
44.16.942.047 W srv   prompt_save:  - saving prompt with length 2939, total state size = 194.443 MiB (draft: 0.000 MiB)
44.16.942.052 I srv         alloc:  - prompt is already in the cache, skipping
44.16.942.052 I slot process_sing: id  9 | task -1 | saving idle slot to prompt cache
44.16.942.980 W srv   prompt_save:  - saving prompt with length 1230, total state size = 180.237 MiB (draft: 0.000 MiB)
44.16.942.984 I srv         alloc:  - prompt is already in the cache, skipping
44.19.979.487 I slot print_timing: id  3 | task 2470 | prompt processing, n_tokens =   4096, progress = 0.40, t =   3.04 s / 1348.93 tokens per second
44.20.504.451 I slot print_timing: id  3 | task 2470 | prompt processing, n_tokens =   4765, progress = 0.41, t =   3.56 s / 1337.94 tokens per second
44.20.545.513 I slot create_check: id  3 | task 2470 | created context checkpoint 5 of 32 (pos_min = 15111, pos_max = 16646, n_tokens = 16647, size = 170.013 MiB)
44.22.126.220 I slot print_timing: id  3 | task 2470 | prompt processing, n_tokens =   6813, progress = 0.46, t =   5.18 s / 1314.43 tokens per second
44.23.739.222 I slot print_timing: id  3 | task 2470 | prompt processing, n_tokens =   8861, progress = 0.51, t =   6.80 s / 1303.81 tokens per second
44.25.397.704 I slot print_timing: id  3 | task 2470 | prompt processing, n_tokens =  10909, progress = 0.56, t =   8.45 s / 1290.29 tokens per second
44.27.087.560 I slot print_timing: id  3 | task 2470 | prompt processing, n_tokens =  12957, progress = 0.61, t =  10.14 s / 1277.24 tokens per second
44.28.806.663 I slot print_timing: id  3 | task 2470 | prompt processing, n_tokens =  15005, progress = 0.67, t =  11.86 s / 1264.79 tokens per second
44.30.569.849 I slot print_timing: id  3 | task 2470 | prompt processing, n_tokens =  17053, progress = 0.72, t =  13.63 s / 1251.43 tokens per second
44.32.363.692 I slot print_timing: id  3 | task 2470 | prompt processing, n_tokens =  19101, progress = 0.77, t =  15.42 s / 1238.66 tokens per second
44.34.208.233 I slot print_timing: id  3 | task 2470 | prompt processing, n_tokens =  21149, progress = 0.82, t =  17.27 s / 1224.95 tokens per second
44.36.064.085 I slot print_timing: id  3 | task 2470 | prompt processing, n_tokens =  23197, progress = 0.87, t =  19.12 s / 1213.16 tokens per second
44.37.958.759 I slot print_timing: id  3 | task 2470 | prompt processing, n_tokens =  25245, progress = 0.92, t =  21.02 s / 1201.24 tokens per second
44.39.880.027 I slot print_timing: id  3 | task 2470 | prompt processing, n_tokens =  27293, progress = 0.97, t =  22.94 s / 1189.91 tokens per second
44.40.623.996 I slot print_timing: id  3 | task 2470 | prompt processing, n_tokens =  28001, progress = 0.99, t =  23.68 s / 1182.42 tokens per second
44.40.662.514 I slot create_check: id  3 | task 2470 | created context checkpoint 6 of 32 (pos_min = 38347, pos_max = 39882, n_tokens = 39883, size = 170.013 MiB)
44.41.161.225 I slot print_timing: id  3 | task 2470 | prompt processing, n_tokens =  28513, progress = 1.00, t =  24.22 s / 1177.34 tokens per second
44.41.208.070 I slot create_check: id  3 | task 2470 | created context checkpoint 7 of 32 (pos_min = 38859, pos_max = 40394, n_tokens = 40395, size = 170.013 MiB)
44.41.355.747 I reasoning-budget: activated, budget=2147483647 tokens
44.43.378.268 I slot print_timing: id  3 | task 2470 | n_decoded =    102, tg =  48.48 t/s
44.46.425.739 I slot print_timing: id  3 | task 2470 | n_decoded =    243, tg =  47.17 t/s
44.49.467.128 I slot print_timing: id  3 | task 2470 | n_decoded =    371, tg =  45.28 t/s
44.49.889.639 I reasoning-budget: deactivated (natural end)
44.51.776.299 I slot print_timing: id  3 | task 2470 | prompt eval time =   24331.08 ms / 28517 tokens (    0.85 ms per token,  1172.04 tokens per second)
44.51.776.303 I slot print_timing: id  3 | task 2470 |        eval time =   10502.06 ms /   492 tokens (   21.35 ms per token,    46.85 tokens per second)
44.51.776.303 I slot print_timing: id  3 | task 2470 |       total time =   34833.14 ms / 29009 tokens
44.51.776.305 I slot print_timing: id  3 | task 2470 |    graphs reused =       2448
44.51.776.306 I slot print_timing: id  3 | task 2470 | draft acceptance = 0.73400 (  367 accepted /   500 generated)
44.51.776.322 I statistics        draft-mtp: #calls(b,g,a) =   24   2513   2689, #gen drafts =   2689, #acc drafts =  2160, #gen tokens =  10756, #acc tokens =  6418, dur(b,g,a) = 0.040, 27578.535, 1.435 ms
44.51.777.173 I slot      release: id  3 | task 2470 | stop processing: n_tokens = 40891, truncated = 0
44.51.777.197 I srv  update_slots: all slots are idle
44.51.946.781 I srv  params_from_: Chat format: peg-gemma4
44.51.968.572 I slot get_availabl: id  3 | task -1 | selected slot by LCP similarity, sim_best = 0.996 (> 0.100 thold), f_keep = 0.997
44.51.968.735 I slot launch_slot_: id  3 | task 2613 | processing task, is_child = 0
44.51.968.737 I slot process_sing: id  0 | task -1 | saving idle slot to prompt cache
44.51.968.738 I slot process_sing: id  1 | task -1 | saving idle slot to prompt cache
44.51.968.738 I slot process_sing: id  2 | task -1 | saving idle slot to prompt cache
44.51.968.738 I slot process_sing: id  4 | task -1 | saving idle slot to prompt cache
44.51.969.820 W srv   prompt_save:  - saving prompt with length 1068, total state size = 178.890 MiB (draft: 0.000 MiB)
44.51.969.830 I srv         alloc:  - prompt is already in the cache, skipping
44.51.969.831 I slot process_sing: id  5 | task -1 | saving idle slot to prompt cache
44.51.970.838 W srv   prompt_save:  - saving prompt with length 2575, total state size = 191.417 MiB (draft: 0.000 MiB)
44.51.970.843 I srv         alloc:  - prompt is already in the cache, skipping
44.51.970.843 I slot process_sing: id  6 | task -1 | saving idle slot to prompt cache
44.51.971.761 W srv   prompt_save:  - saving prompt with length 457, total state size = 79.674 MiB (draft: 0.000 MiB)
44.51.971.764 I srv         alloc:  - prompt is already in the cache, skipping
44.51.971.764 I slot process_sing: id  7 | task -1 | saving idle slot to prompt cache
44.51.972.710 W srv   prompt_save:  - saving prompt with length 1185, total state size = 179.863 MiB (draft: 0.000 MiB)
44.51.972.713 I srv         alloc:  - prompt is already in the cache, skipping
44.51.972.713 I slot process_sing: id  8 | task -1 | saving idle slot to prompt cache
44.51.973.750 W srv   prompt_save:  - saving prompt with length 2939, total state size = 194.443 MiB (draft: 0.000 MiB)
44.51.973.756 I srv         alloc:  - prompt is already in the cache, skipping
44.51.973.756 I slot process_sing: id  9 | task -1 | saving idle slot to prompt cache
44.51.974.660 W srv   prompt_save:  - saving prompt with length 1230, total state size = 180.237 MiB (draft: 0.000 MiB)
44.51.974.663 I srv         alloc:  - prompt is already in the cache, skipping
44.52.020.936 I slot create_check: id  3 | task 2613 | created context checkpoint 8 of 32 (pos_min = 39355, pos_max = 40785, n_tokens = 40786, size = 170.013 MiB)
44.52.353.426 I reasoning-budget: activated, budget=2147483647 tokens
44.54.927.101 I reasoning-budget: deactivated (natural end)
44.55.593.431 I slot print_timing: id  3 | task 2613 | n_decoded =    102, tg =  30.70 t/s
44.55.693.466 I slot print_timing: id  3 | task 2613 | prompt eval time =     296.26 ms /   167 tokens (    1.77 ms per token,   563.70 tokens per second)
44.55.693.469 I slot print_timing: id  3 | task 2613 |        eval time =    3422.38 ms /   106 tokens (   32.29 ms per token,    30.97 tokens per second)
44.55.693.469 I slot print_timing: id  3 | task 2613 |       total time =    3718.64 ms /   273 tokens
44.55.693.470 I slot print_timing: id  3 | task 2613 |    graphs reused =       2486
44.55.693.471 I slot print_timing: id  3 | task 2613 | draft acceptance = 0.41250 (   66 accepted /   160 generated)
44.55.693.486 I statistics        draft-mtp: #calls(b,g,a) =   25   2553   2729, #gen drafts =   2729, #acc drafts =  2187, #gen tokens =  10916, #acc tokens =  6484, dur(b,g,a) = 0.042, 28243.667, 1.455 ms
44.55.694.340 I slot      release: id  3 | task 2613 | stop processing: n_tokens = 41059, truncated = 0
44.55.694.363 I srv  update_slots: all slots are idle
44.55.841.076 I srv  params_from_: Chat format: peg-gemma4
44.55.864.275 I slot get_availabl: id  3 | task -1 | selected slot by LCP similarity, sim_best = 0.998 (> 0.100 thold), f_keep = 0.999
44.55.864.440 I slot launch_slot_: id  3 | task 2656 | processing task, is_child = 0
44.55.864.440 I slot process_sing: id  0 | task -1 | saving idle slot to prompt cache
44.55.864.441 I slot process_sing: id  1 | task -1 | saving idle slot to prompt cache
44.55.864.441 I slot process_sing: id  2 | task -1 | saving idle slot to prompt cache
44.55.864.441 I slot process_sing: id  4 | task -1 | saving idle slot to prompt cache
44.55.865.422 W srv   prompt_save:  - saving prompt with length 1068, total state size = 178.890 MiB (draft: 0.000 MiB)
44.55.865.430 I srv         alloc:  - prompt is already in the cache, skipping
44.55.865.430 I slot process_sing: id  5 | task -1 | saving idle slot to prompt cache
44.55.866.400 W srv   prompt_save:  - saving prompt with length 2575, total state size = 191.417 MiB (draft: 0.000 MiB)
44.55.866.404 I srv         alloc:  - prompt is already in the cache, skipping
44.55.866.405 I slot process_sing: id  6 | task -1 | saving idle slot to prompt cache
44.55.867.511 W srv   prompt_save:  - saving prompt with length 457, total state size = 79.674 MiB (draft: 0.000 MiB)
44.55.867.514 I srv         alloc:  - prompt is already in the cache, skipping
44.55.867.514 I slot process_sing: id  7 | task -1 | saving idle slot to prompt cache
44.55.868.478 W srv   prompt_save:  - saving prompt with length 1185, total state size = 179.863 MiB (draft: 0.000 MiB)
44.55.868.481 I srv         alloc:  - prompt is already in the cache, skipping
44.55.868.481 I slot process_sing: id  8 | task -1 | saving idle slot to prompt cache
44.55.869.539 W srv   prompt_save:  - saving prompt with length 2939, total state size = 194.443 MiB (draft: 0.000 MiB)
44.55.869.543 I srv         alloc:  - prompt is already in the cache, skipping
44.55.869.543 I slot process_sing: id  9 | task -1 | saving idle slot to prompt cache
44.55.870.502 W srv   prompt_save:  - saving prompt with length 1230, total state size = 180.237 MiB (draft: 0.000 MiB)
44.55.870.505 I srv         alloc:  - prompt is already in the cache, skipping
44.56.036.382 I slot create_check: id  3 | task 2656 | created context checkpoint 9 of 32 (pos_min = 39567, pos_max = 41102, n_tokens = 41103, size = 170.013 MiB)
44.56.182.110 I reasoning-budget: activated, budget=2147483647 tokens
44.57.201.728 I reasoning-budget: deactivated (natural end)
44.57.719.798 I slot print_timing: id  3 | task 2656 | prompt eval time =     231.12 ms /    78 tokens (    2.96 ms per token,   337.49 tokens per second)
44.57.719.801 I slot print_timing: id  3 | task 2656 |        eval time =    1617.99 ms /    59 tokens (   27.42 ms per token,    36.46 tokens per second)
44.57.719.801 I slot print_timing: id  3 | task 2656 |       total time =    1849.11 ms /   137 tokens
44.57.719.803 I slot print_timing: id  3 | task 2656 |    graphs reused =       2504
44.57.719.804 I slot print_timing: id  3 | task 2656 | draft acceptance = 0.52632 (   40 accepted /    76 generated)
44.57.719.818 I statistics        draft-mtp: #calls(b,g,a) =   26   2572   2748, #gen drafts =   2748, #acc drafts =  2203, #gen tokens =  10992, #acc tokens =  6524, dur(b,g,a) = 0.045, 28559.527, 1.468 ms
44.57.720.668 I slot      release: id  3 | task 2656 | stop processing: n_tokens = 41166, truncated = 0
44.57.720.689 I srv  update_slots: all slots are idle
44.57.878.308 I srv  params_from_: Chat format: peg-gemma4
44.57.899.569 I slot get_availabl: id  3 | task -1 | selected slot by LCP similarity, sim_best = 0.987 (> 0.100 thold), f_keep = 0.999
44.57.899.735 I slot launch_slot_: id  3 | task 2678 | processing task, is_child = 0
44.57.899.736 I slot process_sing: id  0 | task -1 | saving idle slot to prompt cache
44.57.899.737 I slot process_sing: id  1 | task -1 | saving idle slot to prompt cache
44.57.899.737 I slot process_sing: id  2 | task -1 | saving idle slot to prompt cache
44.57.899.737 I slot process_sing: id  4 | task -1 | saving idle slot to prompt cache
44.57.900.776 W srv   prompt_save:  - saving prompt with length 1068, total state size = 178.890 MiB (draft: 0.000 MiB)
44.57.900.784 I srv         alloc:  - prompt is already in the cache, skipping
44.57.900.785 I slot process_sing: id  5 | task -1 | saving idle slot to prompt cache
44.57.901.778 W srv   prompt_save:  - saving prompt with length 2575, total state size = 191.417 MiB (draft: 0.000 MiB)
44.57.901.782 I srv         alloc:  - prompt is already in the cache, skipping
44.57.901.782 I slot process_sing: id  6 | task -1 | saving idle slot to prompt cache
44.57.902.690 W srv   prompt_save:  - saving prompt with length 457, total state size = 79.674 MiB (draft: 0.000 MiB)
44.57.902.693 I srv         alloc:  - prompt is already in the cache, skipping
44.57.902.693 I slot process_sing: id  7 | task -1 | saving idle slot to prompt cache
44.57.903.714 W srv   prompt_save:  - saving prompt with length 1185, total state size = 179.863 MiB (draft: 0.000 MiB)
44.57.903.717 I srv         alloc:  - prompt is already in the cache, skipping
44.57.903.717 I slot process_sing: id  8 | task -1 | saving idle slot to prompt cache
44.57.904.692 W srv   prompt_save:  - saving prompt with length 2939, total state size = 194.443 MiB (draft: 0.000 MiB)
44.57.904.696 I srv         alloc:  - prompt is already in the cache, skipping
44.57.904.697 I slot process_sing: id  9 | task -1 | saving idle slot to prompt cache
44.57.905.664 W srv   prompt_save:  - saving prompt with length 1230, total state size = 180.237 MiB (draft: 0.000 MiB)
44.57.905.666 I srv         alloc:  - prompt is already in the cache, skipping
44.58.536.665 I slot create_check: id  3 | task 2678 | created context checkpoint 10 of 32 (pos_min = 40151, pos_max = 41686, n_tokens = 41687, size = 170.013 MiB)
44.58.675.276 I reasoning-budget: activated, budget=2147483647 tokens
45.00.991.138 I slot print_timing: id  3 | task 2678 | n_decoded =    102, tg =  42.70 t/s
45.03.200.129 I reasoning-budget: deactivated (natural end)
45.04.001.540 I slot print_timing: id  3 | task 2678 | n_decoded =    237, tg =  43.89 t/s
45.04.338.356 I slot print_timing: id  3 | task 2678 | prompt eval time =     696.46 ms /   552 tokens (    1.26 ms per token,   792.58 tokens per second)
45.04.338.360 I slot print_timing: id  3 | task 2678 |        eval time =    5736.04 ms /   253 tokens (   22.67 ms per token,    44.11 tokens per second)
45.04.338.361 I slot print_timing: id  3 | task 2678 |       total time =    6432.51 ms /   805 tokens
45.04.338.362 I slot print_timing: id  3 | task 2678 |    graphs reused =       2572
45.04.338.363 I slot print_timing: id  3 | task 2678 | draft acceptance = 0.65357 (  183 accepted /   280 generated)
45.04.338.378 I statistics        draft-mtp: #calls(b,g,a) =   27   2642   2818, #gen drafts =   2818, #acc drafts =  2261, #gen tokens =  11272, #acc tokens =  6707, dur(b,g,a) = 0.046, 29671.108, 1.507 ms
45.04.339.266 I slot      release: id  3 | task 2678 | stop processing: n_tokens = 41944, truncated = 0
45.04.339.289 I srv  update_slots: all slots are idle
45.04.505.189 I srv  params_from_: Chat format: peg-gemma4
45.04.523.488 I slot get_availabl: id  3 | task -1 | selected slot by LCP similarity, sim_best = 0.997 (> 0.100 thold), f_keep = 0.998
45.04.523.647 I slot launch_slot_: id  3 | task 2752 | processing task, is_child = 0
45.04.523.649 I slot process_sing: id  0 | task -1 | saving idle slot to prompt cache
45.04.523.650 I slot process_sing: id  1 | task -1 | saving idle slot to prompt cache
45.04.523.650 I slot process_sing: id  2 | task -1 | saving idle slot to prompt cache
45.04.523.650 I slot process_sing: id  4 | task -1 | saving idle slot to prompt cache
45.04.524.758 W srv   prompt_save:  - saving prompt with length 1068, total state size = 178.890 MiB (draft: 0.000 MiB)
45.04.524.765 I srv         alloc:  - prompt is already in the cache, skipping
45.04.524.766 I slot process_sing: id  5 | task -1 | saving idle slot to prompt cache
45.04.525.754 W srv   prompt_save:  - saving prompt with length 2575, total state size = 191.417 MiB (draft: 0.000 MiB)
45.04.525.760 I srv         alloc:  - prompt is already in the cache, skipping
45.04.525.760 I slot process_sing: id  6 | task -1 | saving idle slot to prompt cache
45.04.526.683 W srv   prompt_save:  - saving prompt with length 457, total state size = 79.674 MiB (draft: 0.000 MiB)
45.04.526.685 I srv         alloc:  - prompt is already in the cache, skipping
45.04.526.685 I slot process_sing: id  7 | task -1 | saving idle slot to prompt cache
45.04.527.659 W srv   prompt_save:  - saving prompt with length 1185, total state size = 179.863 MiB (draft: 0.000 MiB)
45.04.527.662 I srv         alloc:  - prompt is already in the cache, skipping
45.04.527.662 I slot process_sing: id  8 | task -1 | saving idle slot to prompt cache
45.04.528.733 W srv   prompt_save:  - saving prompt with length 2939, total state size = 194.443 MiB (draft: 0.000 MiB)
45.04.528.737 I srv         alloc:  - prompt is already in the cache, skipping
45.04.528.738 I slot process_sing: id  9 | task -1 | saving idle slot to prompt cache
45.04.529.664 W srv   prompt_save:  - saving prompt with length 1230, total state size = 180.237 MiB (draft: 0.000 MiB)
45.04.529.669 I srv         alloc:  - prompt is already in the cache, skipping
45.04.740.495 I slot create_check: id  3 | task 2752 | created context checkpoint 11 of 32 (pos_min = 40477, pos_max = 42012, n_tokens = 42013, size = 170.013 MiB)
45.04.886.588 I reasoning-budget: activated, budget=2147483647 tokens
45.07.017.527 I slot print_timing: id  3 | task 2752 | n_decoded =    105, tg =  47.46 t/s
45.07.092.837 I reasoning-budget: deactivated (natural end)
45.07.541.880 I slot print_timing: id  3 | task 2752 | prompt eval time =     275.12 ms /   141 tokens (    1.95 ms per token,   512.51 tokens per second)
45.07.541.884 I slot print_timing: id  3 | task 2752 |        eval time =    2736.91 ms /   127 tokens (   21.55 ms per token,    46.40 tokens per second)
45.07.541.884 I slot print_timing: id  3 | task 2752 |       total time =    3012.03 ms /   268 tokens
45.07.541.885 I slot print_timing: id  3 | task 2752 |    graphs reused =       2604
45.07.541.886 I slot print_timing: id  3 | task 2752 | draft acceptance = 0.71970 (   95 accepted /   132 generated)
45.07.541.902 I statistics        draft-mtp: #calls(b,g,a) =   28   2675   2851, #gen drafts =   2851, #acc drafts =  2291, #gen tokens =  11404, #acc tokens =  6802, dur(b,g,a) = 0.050, 30203.486, 1.531 ms
45.07.542.789 I slot      release: id  3 | task 2752 | stop processing: n_tokens = 42145, truncated = 0
45.07.542.814 I srv  update_slots: all slots are idle
45.07.700.449 I srv  params_from_: Chat format: peg-gemma4
45.07.719.360 I slot get_availabl: id  3 | task -1 | selected slot by LCP similarity, sim_best = 0.999 (> 0.100 thold), f_keep = 0.999
45.07.719.544 I slot launch_slot_: id  3 | task 2788 | processing task, is_child = 0
45.07.719.545 I slot process_sing: id  0 | task -1 | saving idle slot to prompt cache
45.07.719.546 I slot process_sing: id  1 | task -1 | saving idle slot to prompt cache
45.07.719.546 I slot process_sing: id  2 | task -1 | saving idle slot to prompt cache
45.07.719.546 I slot process_sing: id  4 | task -1 | saving idle slot to prompt cache
45.07.720.547 W srv   prompt_save:  - saving prompt with length 1068, total state size = 178.890 MiB (draft: 0.000 MiB)
45.07.720.554 I srv         alloc:  - prompt is already in the cache, skipping
45.07.720.555 I slot process_sing: id  5 | task -1 | saving idle slot to prompt cache
45.07.721.572 W srv   prompt_save:  - saving prompt with length 2575, total state size = 191.417 MiB (draft: 0.000 MiB)
45.07.721.576 I srv         alloc:  - prompt is already in the cache, skipping
45.07.721.576 I slot process_sing: id  6 | task -1 | saving idle slot to prompt cache
45.07.722.562 W srv   prompt_save:  - saving prompt with length 457, total state size = 79.674 MiB (draft: 0.000 MiB)
45.07.722.565 I srv         alloc:  - prompt is already in the cache, skipping
45.07.722.565 I slot process_sing: id  7 | task -1 | saving idle slot to prompt cache
45.07.723.592 W srv   prompt_save:  - saving prompt with length 1185, total state size = 179.863 MiB (draft: 0.000 MiB)
45.07.723.594 I srv         alloc:  - prompt is already in the cache, skipping
45.07.723.595 I slot process_sing: id  8 | task -1 | saving idle slot to prompt cache
45.07.724.592 W srv   prompt_save:  - saving prompt with length 2939, total state size = 194.443 MiB (draft: 0.000 MiB)
45.07.724.597 I srv         alloc:  - prompt is already in the cache, skipping
45.07.724.597 I slot process_sing: id  9 | task -1 | saving idle slot to prompt cache
45.07.725.834 W srv   prompt_save:  - saving prompt with length 1230, total state size = 180.237 MiB (draft: 0.000 MiB)
45.07.725.837 I srv         alloc:  - prompt is already in the cache, skipping
45.07.960.315 I reasoning-budget: activated, budget=2147483647 tokens
45.10.092.300 I slot print_timing: id  3 | task 2788 | n_decoded =    120, tg =  54.23 t/s
45.13.157.350 I slot print_timing: id  3 | task 2788 | n_decoded =    227, tg =  43.01 t/s
45.14.624.972 I reasoning-budget: deactivated (natural end)
45.16.207.219 I slot print_timing: id  3 | task 2788 | n_decoded =    373, tg =  44.79 t/s
45.16.290.995 I slot print_timing: id  3 | task 2788 | prompt eval time =     153.41 ms /    46 tokens (    3.34 ms per token,   299.84 tokens per second)
45.16.290.998 I slot print_timing: id  3 | task 2788 |        eval time =    8411.61 ms /   378 tokens (   22.25 ms per token,    44.94 tokens per second)
45.16.290.999 I slot print_timing: id  3 | task 2788 |       total time =    8565.03 ms /   424 tokens
45.16.291.000 I slot print_timing: id  3 | task 2788 |    graphs reused =       2705
45.16.291.001 I slot print_timing: id  3 | task 2788 | draft acceptance = 0.65625 (  273 accepted /   416 generated)
45.16.291.015 I statistics        draft-mtp: #calls(b,g,a) =   29   2779   2955, #gen drafts =   2955, #acc drafts =  2379, #gen tokens =  11820, #acc tokens =  7075, dur(b,g,a) = 0.053, 31858.274, 1.601 ms
45.16.291.905 I slot      release: id  3 | task 2788 | stop processing: n_tokens = 42544, truncated = 0
45.16.291.929 I srv  update_slots: all slots are idle
45.16.488.535 I srv  params_from_: Chat format: peg-gemma4
45.16.508.973 I slot get_availabl: id  3 | task -1 | selected slot by LCP similarity, sim_best = 0.997 (> 0.100 thold), f_keep = 0.998
45.16.509.140 I slot launch_slot_: id  3 | task 2895 | processing task, is_child = 0
45.16.509.140 I slot process_sing: id  0 | task -1 | saving idle slot to prompt cache
45.16.509.141 I slot process_sing: id  1 | task -1 | saving idle slot to prompt cache
45.16.509.141 I slot process_sing: id  2 | task -1 | saving idle slot to prompt cache
45.16.509.142 I slot process_sing: id  4 | task -1 | saving idle slot to prompt cache
45.16.510.133 W srv   prompt_save:  - saving prompt with length 1068, total state size = 178.890 MiB (draft: 0.000 MiB)
45.16.510.144 I srv         alloc:  - prompt is already in the cache, skipping
45.16.510.144 I slot process_sing: id  5 | task -1 | saving idle slot to prompt cache
45.16.511.128 W srv   prompt_save:  - saving prompt with length 2575, total state size = 191.417 MiB (draft: 0.000 MiB)
45.16.511.132 I srv         alloc:  - prompt is already in the cache, skipping
45.16.511.132 I slot process_sing: id  6 | task -1 | saving idle slot to prompt cache
45.16.512.064 W srv   prompt_save:  - saving prompt with length 457, total state size = 79.674 MiB (draft: 0.000 MiB)
45.16.512.067 I srv         alloc:  - prompt is already in the cache, skipping
45.16.512.067 I slot process_sing: id  7 | task -1 | saving idle slot to prompt cache
45.16.512.966 W srv   prompt_save:  - saving prompt with length 1185, total state size = 179.863 MiB (draft: 0.000 MiB)
45.16.512.969 I srv         alloc:  - prompt is already in the cache, skipping
45.16.512.969 I slot process_sing: id  8 | task -1 | saving idle slot to prompt cache
45.16.514.009 W srv   prompt_save:  - saving prompt with length 2939, total state size = 194.443 MiB (draft: 0.000 MiB)
45.16.514.014 I srv         alloc:  - prompt is already in the cache, skipping
45.16.514.014 I slot process_sing: id  9 | task -1 | saving idle slot to prompt cache
45.16.514.929 W srv   prompt_save:  - saving prompt with length 1230, total state size = 180.237 MiB (draft: 0.000 MiB)
45.16.514.932 I srv         alloc:  - prompt is already in the cache, skipping
45.16.559.340 I slot create_check: id  3 | task 2895 | created context checkpoint 12 of 32 (pos_min = 41008, pos_max = 42437, n_tokens = 42438, size = 170.013 MiB)
45.16.837.802 I reasoning-budget: activated, budget=2147483647 tokens
45.19.267.603 I slot print_timing: id  3 | task 2895 | n_decoded =    102, tg =  40.69 t/s
45.22.331.784 I slot print_timing: id  3 | task 2895 | n_decoded =    202, tg =  36.26 t/s
45.25.391.539 I slot print_timing: id  3 | task 2895 | n_decoded =    319, tg =  36.96 t/s
45.28.443.711 I slot print_timing: id  3 | task 2895 | n_decoded =    424, tg =  36.29 t/s
45.31.520.102 I slot print_timing: id  3 | task 2895 | n_decoded =    536, tg =  36.32 t/s
45.34.571.784 I slot print_timing: id  3 | task 2895 | n_decoded =    657, tg =  36.89 t/s
45.37.577.645 I slot print_timing: id  3 | task 2895 | n_decoded =    789, tg =  37.90 t/s
45.40.402.718 I reasoning-budget: deactivated (natural end)
45.40.651.780 I slot print_timing: id  3 | task 2895 | n_decoded =    886, tg =  37.09 t/s
45.43.707.913 I slot print_timing: id  3 | task 2895 | n_decoded =   1027, tg =  38.11 t/s
45.46.752.725 I slot print_timing: id  3 | task 2895 | n_decoded =   1162, tg =  38.74 t/s
45.49.809.927 I slot print_timing: id  3 | task 2895 | n_decoded =   1325, tg =  40.09 t/s
45.52.885.398 I slot print_timing: id  3 | task 2895 | n_decoded =   1489, tg =  41.22 t/s
45.55.948.516 I slot print_timing: id  3 | task 2895 | n_decoded =   1631, tg =  41.62 t/s
45.59.024.283 I slot print_timing: id  3 | task 2895 | n_decoded =   1780, tg =  42.12 t/s
46.02.067.272 I slot print_timing: id  3 | task 2895 | n_decoded =   1931, tg =  42.62 t/s
46.05.068.608 I slot print_timing: id  3 | task 2895 | n_decoded =   2108, tg =  43.64 t/s
46.08.142.807 I slot print_timing: id  3 | task 2895 | n_decoded =   2278, tg =  44.33 t/s
46.11.214.612 I slot print_timing: id  3 | task 2895 | n_decoded =   2453, tg =  45.05 t/s
46.14.288.970 I slot print_timing: id  3 | task 2895 | n_decoded =   2625, tg =  45.63 t/s
46.17.301.289 I slot print_timing: id  3 | task 2895 | n_decoded =   2789, tg =  46.07 t/s
46.20.309.925 I slot print_timing: id  3 | task 2895 | n_decoded =   2935, tg =  46.18 t/s
46.23.320.996 I slot print_timing: id  3 | task 2895 | n_decoded =   3085, tg =  46.35 t/s
46.26.333.574 I slot print_timing: id  3 | task 2895 | n_decoded =   3270, tg =  47.00 t/s
46.29.360.860 I slot print_timing: id  3 | task 2895 | n_decoded =   3433, tg =  47.29 t/s
46.30.728.205 W srv          stop: cancel task, id_task = 2895
46.30.808.552 I slot      release: id  3 | task 2895 | stop processing: n_tokens = 46064, truncated = 0
46.30.808.583 I srv  update_slots: all slots are idle
51.27.127.574 I srv  params_from_: Chat format: peg-gemma4
51.27.154.854 I slot get_availabl: id  3 | task -1 | selected slot by LCP similarity, sim_best = 0.260 (> 0.100 thold), f_keep = 0.234
51.27.154.863 I srv  get_availabl: updating prompt cache
51.27.156.575 W srv   prompt_save:  - saving prompt with length 46064, total state size = 552.907 MiB (draft: 0.000 MiB)
51.27.756.787 I srv          load:  - looking for better prompt, base f_keep = 0.234, sim = 0.260
51.27.756.810 I srv        update:  - cache state: 14 prompts, 6358.885 MiB (limits: 8192.000 MiB, 2649600 tokens, 2649600 est)
51.27.756.812 I srv        update:    - prompt 0xb639a4cacf50:     112 tokens, checkpoints:  1,    20.856 MiB
51.27.756.812 I srv        update:    - prompt 0xb63981c727c0:     102 tokens, checkpoints:  1,    19.113 MiB
51.27.756.813 I srv        update:    - prompt 0xb639a46dfdf0:     672 tokens, checkpoints:  2,   163.481 MiB
51.27.756.813 I srv        update:    - prompt 0xb639a46dc9f0:    1185 tokens, checkpoints:  2,   235.318 MiB
51.27.756.813 I srv        update:    - prompt 0xb639a86b7bd0:     457 tokens, checkpoints:  1,    81.003 MiB
51.27.756.814 I srv        update:    - prompt 0xb639a47c1650:    1230 tokens, checkpoints:  1,   181.566 MiB
51.27.756.814 I srv        update:    - prompt 0xb639a4c95e50:    1353 tokens, checkpoints:  3,   374.186 MiB
51.27.756.814 I srv        update:    - prompt 0xb639a4cadb10:    2575 tokens, checkpoints:  3,   610.970 MiB
51.27.756.815 I srv        update:    - prompt 0xb639a46d9890:    2939 tokens, checkpoints:  4,   589.093 MiB
51.27.756.815 I srv        update:    - prompt 0xb639a84535e0:    7338 tokens, checkpoints:  1,   401.021 MiB
51.27.756.816 I srv        update:    - prompt 0xb639a9287360:     883 tokens, checkpoints:  1,   244.595 MiB
51.27.756.816 I srv        update:    - prompt 0xb639a8128da0:    7825 tokens, checkpoints:  2,   575.081 MiB
51.27.756.816 I srv        update:    - prompt 0xb639a8151fa0:    1068 tokens, checkpoints:  1,   269.542 MiB
51.27.756.817 I srv        update:    - prompt 0xb639b06fc320:   46064 tokens, checkpoints: 12,  2593.060 MiB
51.27.756.818 I srv  get_availabl: prompt cache update took 601.95 ms
51.27.756.980 I slot launch_slot_: id  3 | task 3830 | processing task, is_child = 0
51.27.756.981 I slot process_sing: id  0 | task -1 | saving idle slot to prompt cache
51.27.756.982 I slot process_sing: id  1 | task -1 | saving idle slot to prompt cache
51.27.756.982 I slot process_sing: id  2 | task -1 | saving idle slot to prompt cache
51.27.756.983 I slot process_sing: id  4 | task -1 | saving idle slot to prompt cache
51.27.757.929 W srv   prompt_save:  - saving prompt with length 1068, total state size = 178.890 MiB (draft: 0.000 MiB)
51.27.757.934 I srv         alloc:  - prompt is already in the cache, skipping
51.27.757.934 I slot process_sing: id  5 | task -1 | saving idle slot to prompt cache
51.27.759.018 W srv   prompt_save:  - saving prompt with length 2575, total state size = 191.417 MiB (draft: 0.000 MiB)
51.27.759.024 I srv         alloc:  - prompt is already in the cache, skipping
51.27.759.024 I slot process_sing: id  6 | task -1 | saving idle slot to prompt cache
51.27.760.045 W srv   prompt_save:  - saving prompt with length 457, total state size = 79.674 MiB (draft: 0.000 MiB)
51.27.760.048 I srv         alloc:  - prompt is already in the cache, skipping
51.27.760.048 I slot process_sing: id  7 | task -1 | saving idle slot to prompt cache
51.27.761.089 W srv   prompt_save:  - saving prompt with length 1185, total state size = 179.863 MiB (draft: 0.000 MiB)
51.27.761.092 I srv         alloc:  - prompt is already in the cache, skipping
51.27.761.092 I slot process_sing: id  8 | task -1 | saving idle slot to prompt cache
51.27.762.113 W srv   prompt_save:  - saving prompt with length 2939, total state size = 194.443 MiB (draft: 0.000 MiB)
51.27.762.119 I srv         alloc:  - prompt is already in the cache, skipping
51.27.762.120 I slot process_sing: id  9 | task -1 | saving idle slot to prompt cache
51.27.763.134 W srv   prompt_save:  - saving prompt with length 1230, total state size = 180.237 MiB (draft: 0.000 MiB)
51.27.763.137 I srv         alloc:  - prompt is already in the cache, skipping
51.27.763.157 I slot update_slots: id  3 | task 3830 | Checking checkpoint with [41008, 42437] against 9776...
51.27.763.157 I slot update_slots: id  3 | task 3830 | Checking checkpoint with [40477, 42012] against 9776...
51.27.763.158 I slot update_slots: id  3 | task 3830 | Checking checkpoint with [40151, 41686] against 9776...
51.27.763.158 I slot update_slots: id  3 | task 3830 | Checking checkpoint with [39567, 41102] against 9776...
51.27.763.159 I slot update_slots: id  3 | task 3830 | Checking checkpoint with [39355, 40785] against 9776...
51.27.763.159 I slot update_slots: id  3 | task 3830 | Checking checkpoint with [38859, 40394] against 9776...
51.27.763.159 I slot update_slots: id  3 | task 3830 | Checking checkpoint with [38347, 39882] against 9776...
51.27.763.160 I slot update_slots: id  3 | task 3830 | Checking checkpoint with [15111, 16646] against 9776...
51.27.763.160 I slot update_slots: id  3 | task 3830 | Checking checkpoint with [9260, 10795] against 9776...
51.27.767.572 W slot update_slots: id  3 | task 3830 | restored context checkpoint (pos_min = 9260, pos_max = 10795, n_tokens = 10796, n_past = 10795, size = 170.013 MiB)
51.27.767.575 W slot update_slots: id  3 | task 3830 | erased invalidated context checkpoint (pos_min = 15111, pos_max = 16646, n_tokens = 16647, n_swa = 1024, pos_next = 10795, size = 170.013 MiB)
51.27.786.557 W slot update_slots: id  3 | task 3830 | erased invalidated context checkpoint (pos_min = 38347, pos_max = 39882, n_tokens = 39883, n_swa = 1024, pos_next = 10795, size = 170.013 MiB)
51.27.805.631 W slot update_slots: id  3 | task 3830 | erased invalidated context checkpoint (pos_min = 38859, pos_max = 40394, n_tokens = 40395, n_swa = 1024, pos_next = 10795, size = 170.013 MiB)
51.27.819.179 W slot update_slots: id  3 | task 3830 | erased invalidated context checkpoint (pos_min = 39355, pos_max = 40785, n_tokens = 40786, n_swa = 1024, pos_next = 10795, size = 170.013 MiB)
51.27.833.666 W slot update_slots: id  3 | task 3830 | erased invalidated context checkpoint (pos_min = 39567, pos_max = 41102, n_tokens = 41103, n_swa = 1024, pos_next = 10795, size = 170.013 MiB)
51.27.846.731 W slot update_slots: id  3 | task 3830 | erased invalidated context checkpoint (pos_min = 40151, pos_max = 41686, n_tokens = 41687, n_swa = 1024, pos_next = 10795, size = 170.013 MiB)
51.27.860.166 W slot update_slots: id  3 | task 3830 | erased invalidated context checkpoint (pos_min = 40477, pos_max = 42012, n_tokens = 42013, n_swa = 1024, pos_next = 10795, size = 170.013 MiB)
51.27.873.662 W slot update_slots: id  3 | task 3830 | erased invalidated context checkpoint (pos_min = 41008, pos_max = 42437, n_tokens = 42438, n_swa = 1024, pos_next = 10795, size = 170.013 MiB)
51.30.788.791 I slot print_timing: id  3 | task 3830 | prompt processing, n_tokens =   4096, progress = 0.36, t =   3.03 s / 1353.76 tokens per second
51.32.303.368 I slot print_timing: id  3 | task 3830 | prompt processing, n_tokens =   6144, progress = 0.41, t =   4.54 s / 1353.24 tokens per second
51.33.837.175 I slot print_timing: id  3 | task 3830 | prompt processing, n_tokens =   8192, progress = 0.46, t =   6.07 s / 1348.69 tokens per second
51.35.414.987 I slot print_timing: id  3 | task 3830 | prompt processing, n_tokens =  10240, progress = 0.51, t =   7.65 s / 1338.24 tokens per second
51.37.032.579 I slot print_timing: id  3 | task 3830 | prompt processing, n_tokens =  12288, progress = 0.55, t =   9.27 s / 1325.65 tokens per second
51.38.664.375 I slot print_timing: id  3 | task 3830 | prompt processing, n_tokens =  14336, progress = 0.60, t =  10.90 s / 1315.08 tokens per second
51.40.332.381 I slot print_timing: id  3 | task 3830 | prompt processing, n_tokens =  16384, progress = 0.65, t =  12.57 s / 1303.50 tokens per second
51.42.044.373 I slot print_timing: id  3 | task 3830 | prompt processing, n_tokens =  18432, progress = 0.70, t =  14.28 s / 1290.65 tokens per second
51.43.787.615 I slot print_timing: id  3 | task 3830 | prompt processing, n_tokens =  20480, progress = 0.75, t =  16.02 s / 1278.05 tokens per second
51.45.568.469 I slot print_timing: id  3 | task 3830 | prompt processing, n_tokens =  22528, progress = 0.80, t =  17.81 s / 1265.24 tokens per second
51.47.375.947 I slot print_timing: id  3 | task 3830 | prompt processing, n_tokens =  24576, progress = 0.85, t =  19.61 s / 1253.06 tokens per second
51.49.222.207 I slot print_timing: id  3 | task 3830 | prompt processing, n_tokens =  26624, progress = 0.90, t =  21.46 s / 1240.69 tokens per second
51.51.113.724 I slot print_timing: id  3 | task 3830 | prompt processing, n_tokens =  28672, progress = 0.95, t =  23.35 s / 1227.89 tokens per second
51.52.036.997 I slot print_timing: id  3 | task 3830 | prompt processing, n_tokens =  29633, progress = 0.97, t =  24.27 s / 1220.78 tokens per second
51.52.081.136 I slot create_check: id  3 | task 3830 | created context checkpoint 5 of 32 (pos_min = 38892, pos_max = 40427, n_tokens = 40428, size = 170.013 MiB)
51.52.726.932 I slot print_timing: id  3 | task 3830 | prompt processing, n_tokens =  30288, progress = 0.99, t =  24.96 s / 1213.28 tokens per second
51.52.768.818 I slot create_check: id  3 | task 3830 | created context checkpoint 6 of 32 (pos_min = 39547, pos_max = 41082, n_tokens = 41083, size = 170.013 MiB)
51.53.262.234 I slot print_timing: id  3 | task 3830 | prompt processing, n_tokens =  30800, progress = 1.00, t =  25.50 s / 1207.89 tokens per second
51.53.308.727 I slot create_check: id  3 | task 3830 | created context checkpoint 7 of 32 (pos_min = 40060, pos_max = 41594, n_tokens = 41595, size = 170.013 MiB)
51.53.453.134 I reasoning-budget: activated, budget=2147483647 tokens
51.55.403.423 I slot print_timing: id  3 | task 3830 | n_decoded =    100, tg =  49.26 t/s
51.58.478.484 I slot print_timing: id  3 | task 3830 | n_decoded =    271, tg =  53.08 t/s
52.01.537.971 I slot print_timing: id  3 | task 3830 | n_decoded =    390, tg =  47.77 t/s
52.04.606.483 I slot print_timing: id  3 | task 3830 | n_decoded =    510, tg =  45.40 t/s
52.06.787.002 I reasoning-budget: deactivated (natural end)
52.07.614.954 I slot print_timing: id  3 | task 3830 | n_decoded =    622, tg =  43.68 t/s
52.08.203.291 I slot print_timing: id  3 | task 3830 | prompt eval time =   25610.09 ms / 30804 tokens (    0.83 ms per token,  1202.81 tokens per second)
52.08.203.295 I slot print_timing: id  3 | task 3830 |        eval time =   14829.91 ms /   650 tokens (   22.82 ms per token,    43.83 tokens per second)
52.08.203.295 I slot print_timing: id  3 | task 3830 |       total time =   40440.00 ms / 31454 tokens
52.08.203.297 I slot print_timing: id  3 | task 3830 |    graphs reused =       3801
52.08.203.297 I slot print_timing: id  3 | task 3830 | draft acceptance = 0.63798 (  467 accepted /   732 generated)
52.08.203.312 I statistics        draft-mtp: #calls(b,g,a) =   31   3893   4069, #gen drafts =   4069, #acc drafts =  3339, #gen tokens =  16276, #acc tokens = 10116, dur(b,g,a) = 0.060, 49507.584, 2.295 ms
52.08.204.194 I slot      release: id  3 | task 3830 | stop processing: n_tokens = 42249, truncated = 0
52.08.204.220 I srv  update_slots: all slots are idle
52.41.439.921 I srv  params_from_: Chat format: peg-gemma4
52.41.471.013 I slot get_availabl: id  3 | task -1 | selected slot by LCP similarity, sim_best = 0.998 (> 0.100 thold), f_keep = 0.985
52.41.471.233 I slot launch_slot_: id  3 | task 4032 | processing task, is_child = 0
52.41.471.239 I slot process_sing: id  0 | task -1 | saving idle slot to prompt cache
52.41.471.240 I slot process_sing: id  1 | task -1 | saving idle slot to prompt cache
52.41.471.241 I slot process_sing: id  2 | task -1 | saving idle slot to prompt cache
52.41.471.241 I slot process_sing: id  4 | task -1 | saving idle slot to prompt cache
52.41.472.990 W srv   prompt_save:  - saving prompt with length 1068, total state size = 178.890 MiB (draft: 0.000 MiB)
52.41.473.001 I srv         alloc:  - prompt is already in the cache, skipping
52.41.473.002 I slot process_sing: id  5 | task -1 | saving idle slot to prompt cache
52.41.474.895 W srv   prompt_save:  - saving prompt with length 2575, total state size = 191.417 MiB (draft: 0.000 MiB)
52.41.474.905 I srv         alloc:  - prompt is already in the cache, skipping
52.41.474.905 I slot process_sing: id  6 | task -1 | saving idle slot to prompt cache
52.41.476.797 W srv   prompt_save:  - saving prompt with length 457, total state size = 79.674 MiB (draft: 0.000 MiB)
52.41.476.802 I srv         alloc:  - prompt is already in the cache, skipping
52.41.476.803 I slot process_sing: id  7 | task -1 | saving idle slot to prompt cache
52.41.478.533 W srv   prompt_save:  - saving prompt with length 1185, total state size = 179.863 MiB (draft: 0.000 MiB)
52.41.478.540 I srv         alloc:  - prompt is already in the cache, skipping
52.41.478.540 I slot process_sing: id  8 | task -1 | saving idle slot to prompt cache
52.41.480.588 W srv   prompt_save:  - saving prompt with length 2939, total state size = 194.443 MiB (draft: 0.000 MiB)
52.41.480.598 I srv         alloc:  - prompt is already in the cache, skipping
52.41.480.601 I slot process_sing: id  9 | task -1 | saving idle slot to prompt cache
52.41.482.394 W srv   prompt_save:  - saving prompt with length 1230, total state size = 180.237 MiB (draft: 0.000 MiB)
52.41.482.402 I srv         alloc:  - prompt is already in the cache, skipping
52.41.482.451 I slot update_slots: id  3 | task 4032 | Checking checkpoint with [40060, 41594] against 40575...
52.41.486.929 W slot update_slots: id  3 | task 4032 | restored context checkpoint (pos_min = 40060, pos_max = 41594, n_tokens = 41595, n_past = 41594, size = 170.013 MiB)
52.41.813.839 I reasoning-budget: activated, budget=2147483647 tokens
52.43.636.009 I slot print_timing: id  3 | task 4032 | n_decoded =    100, tg =  52.59 t/s
52.46.644.910 I slot print_timing: id  3 | task 4032 | n_decoded =    228, tg =  46.43 t/s
52.49.705.419 I slot print_timing: id  3 | task 4032 | n_decoded =    374, tg =  46.92 t/s
52.52.786.706 I slot print_timing: id  3 | task 4032 | n_decoded =    481, tg =  43.52 t/s
52.55.866.303 I slot print_timing: id  3 | task 4032 | n_decoded =    644, tg =  45.57 t/s
52.57.594.294 I reasoning-budget: deactivated (natural end)
52.58.888.778 I slot print_timing: id  3 | task 4032 | n_decoded =    816, tg =  47.57 t/s
53.00.089.763 I slot print_timing: id  3 | task 4032 | prompt eval time =     251.81 ms /   108 tokens (    2.33 ms per token,   428.90 tokens per second)
53.00.089.767 I slot print_timing: id  3 | task 4032 |        eval time =   18355.40 ms /   890 tokens (   20.62 ms per token,    48.49 tokens per second)
53.00.089.767 I slot print_timing: id  3 | task 4032 |       total time =   18607.21 ms /   998 tokens
53.00.089.769 I slot print_timing: id  3 | task 4032 |    graphs reused =       4017
53.00.089.770 I slot print_timing: id  3 | task 4032 | draft acceptance = 0.75113 (  667 accepted /   888 generated)
53.00.089.784 I statistics        draft-mtp: #calls(b,g,a) =   32   4115   4291, #gen drafts =   4291, #acc drafts =  3539, #gen tokens =  17164, #acc tokens = 10783, dur(b,g,a) = 0.062, 53086.613, 2.395 ms
53.00.090.670 I slot      release: id  3 | task 4032 | stop processing: n_tokens = 42591, truncated = 0
53.00.090.696 I srv  update_slots: all slots are idle
53.00.295.748 I srv  params_from_: Chat format: peg-gemma4
53.00.331.965 I slot get_availabl: id  3 | task -1 | selected slot by LCP similarity, sim_best = 0.598 (> 0.100 thold), f_keep = 0.996
53.00.332.150 I slot launch_slot_: id  3 | task 4258 | processing task, is_child = 0
53.00.332.153 I slot process_sing: id  0 | task -1 | saving idle slot to prompt cache
53.00.332.153 I slot process_sing: id  1 | task -1 | saving idle slot to prompt cache
53.00.332.153 I slot process_sing: id  2 | task -1 | saving idle slot to prompt cache
53.00.332.154 I slot process_sing: id  4 | task -1 | saving idle slot to prompt cache
53.00.333.265 W srv   prompt_save:  - saving prompt with length 1068, total state size = 178.890 MiB (draft: 0.000 MiB)
53.00.333.272 I srv         alloc:  - prompt is already in the cache, skipping
53.00.333.272 I slot process_sing: id  5 | task -1 | saving idle slot to prompt cache
53.00.334.583 W srv   prompt_save:  - saving prompt with length 2575, total state size = 191.417 MiB (draft: 0.000 MiB)
53.00.334.587 I srv         alloc:  - prompt is already in the cache, skipping
53.00.334.587 I slot process_sing: id  6 | task -1 | saving idle slot to prompt cache
53.00.335.565 W srv   prompt_save:  - saving prompt with length 457, total state size = 79.674 MiB (draft: 0.000 MiB)
53.00.335.567 I srv         alloc:  - prompt is already in the cache, skipping
53.00.335.567 I slot process_sing: id  7 | task -1 | saving idle slot to prompt cache
53.00.336.539 W srv   prompt_save:  - saving prompt with length 1185, total state size = 179.863 MiB (draft: 0.000 MiB)
53.00.336.541 I srv         alloc:  - prompt is already in the cache, skipping
53.00.336.541 I slot process_sing: id  8 | task -1 | saving idle slot to prompt cache
53.00.337.557 W srv   prompt_save:  - saving prompt with length 2939, total state size = 194.443 MiB (draft: 0.000 MiB)
53.00.337.561 I srv         alloc:  - prompt is already in the cache, skipping
53.00.337.562 I slot process_sing: id  9 | task -1 | saving idle slot to prompt cache
53.00.338.478 W srv   prompt_save:  - saving prompt with length 1230, total state size = 180.237 MiB (draft: 0.000 MiB)
53.00.338.480 I srv         alloc:  - prompt is already in the cache, skipping
53.04.717.318 I slot print_timing: id  3 | task 4258 | prompt processing, n_tokens =   4096, progress = 0.66, t =   4.38 s / 935.41 tokens per second
53.05.552.039 I slot print_timing: id  3 | task 4258 | prompt processing, n_tokens =   4803, progress = 0.67, t =   5.21 s / 921.25 tokens per second
53.05.595.685 I slot create_check: id  3 | task 4258 | created context checkpoint 8 of 32 (pos_min = 45702, pos_max = 47237, n_tokens = 47238, size = 170.013 MiB)
53.07.812.098 I slot print_timing: id  3 | task 4258 | prompt processing, n_tokens =   6851, progress = 0.69, t =   7.47 s / 916.69 tokens per second
53.10.032.374 I slot print_timing: id  3 | task 4258 | prompt processing, n_tokens =   8899, progress = 0.72, t =   9.69 s / 918.00 tokens per second
53.12.279.824 I slot print_timing: id  3 | task 4258 | prompt processing, n_tokens =  10947, progress = 0.75, t =  11.94 s / 916.73 tokens per second
53.14.596.192 I slot print_timing: id  3 | task 4258 | prompt processing, n_tokens =  12995, progress = 0.78, t =  14.26 s / 911.44 tokens per second
53.17.081.380 I slot print_timing: id  3 | task 4258 | prompt processing, n_tokens =  15043, progress = 0.81, t =  16.74 s / 898.47 tokens per second
53.19.419.893 I slot print_timing: id  3 | task 4258 | prompt processing, n_tokens =  17091, progress = 0.84, t =  19.08 s / 895.69 tokens per second
53.21.771.063 I slot print_timing: id  3 | task 4258 | prompt processing, n_tokens =  19139, progress = 0.87, t =  21.43 s / 892.99 tokens per second
53.24.122.219 I slot print_timing: id  3 | task 4258 | prompt processing, n_tokens =  21187, progress = 0.90, t =  23.78 s / 890.82 tokens per second
53.26.517.456 I slot print_timing: id  3 | task 4258 | prompt processing, n_tokens =  23235, progress = 0.93, t =  26.18 s / 887.54 tokens per second
53.28.472.594 I srv  params_from_: Chat format: peg-gemma4
53.28.944.301 I slot get_availabl: id  5 | task -1 | selected slot by LCP similarity, sim_best = 0.440 (> 0.100 thold), f_keep = 0.004
53.28.944.309 I srv  get_availabl: updating prompt cache
53.28.945.344 W srv   prompt_save:  - saving prompt with length 2575, total state size = 191.417 MiB (draft: 0.000 MiB)
53.28.945.353 I srv         alloc:  - prompt is already in the cache, skipping
53.28.945.354 I srv          load:  - looking for better prompt, base f_keep = 0.004, sim = 0.440
53.28.945.362 I srv        update:  - cache state: 14 prompts, 6358.885 MiB (limits: 8192.000 MiB, 2649600 tokens, 2649600 est)
53.28.945.362 I srv        update:    - prompt 0xb639a4cacf50:     112 tokens, checkpoints:  1,    20.856 MiB
53.28.945.363 I srv        update:    - prompt 0xb63981c727c0:     102 tokens, checkpoints:  1,    19.113 MiB
53.28.945.363 I srv        update:    - prompt 0xb639a46dfdf0:     672 tokens, checkpoints:  2,   163.481 MiB
53.28.945.364 I srv        update:    - prompt 0xb639a46dc9f0:    1185 tokens, checkpoints:  2,   235.318 MiB
53.28.945.364 I srv        update:    - prompt 0xb639a86b7bd0:     457 tokens, checkpoints:  1,    81.003 MiB
53.28.945.364 I srv        update:    - prompt 0xb639a47c1650:    1230 tokens, checkpoints:  1,   181.566 MiB
53.28.945.365 I srv        update:    - prompt 0xb639a4c95e50:    1353 tokens, checkpoints:  3,   374.186 MiB
53.28.945.365 I srv        update:    - prompt 0xb639a4cadb10:    2575 tokens, checkpoints:  3,   610.970 MiB
53.28.945.365 I srv        update:    - prompt 0xb639a46d9890:    2939 tokens, checkpoints:  4,   589.093 MiB
53.28.945.365 I srv        update:    - prompt 0xb639a84535e0:    7338 tokens, checkpoints:  1,   401.021 MiB
53.28.945.366 I srv        update:    - prompt 0xb639a9287360:     883 tokens, checkpoints:  1,   244.595 MiB
53.28.945.366 I srv        update:    - prompt 0xb639a8128da0:    7825 tokens, checkpoints:  2,   575.081 MiB
53.28.945.366 I srv        update:    - prompt 0xb639a8151fa0:    1068 tokens, checkpoints:  1,   269.542 MiB
53.28.945.367 I srv        update:    - prompt 0xb639b06fc320:   46064 tokens, checkpoints: 12,  2593.060 MiB
53.28.945.367 I srv  get_availabl: prompt cache update took 1.06 ms
53.28.945.432 I slot launch_slot_: id  5 | task 4272 | processing task, is_child = 0
53.28.945.433 I slot process_sing: id  0 | task -1 | saving idle slot to prompt cache
53.28.945.433 I slot process_sing: id  1 | task -1 | saving idle slot to prompt cache
53.28.945.433 I slot process_sing: id  2 | task -1 | saving idle slot to prompt cache
53.28.945.434 I slot process_sing: id  4 | task -1 | saving idle slot to prompt cache
53.28.946.513 W srv   prompt_save:  - saving prompt with length 1068, total state size = 178.890 MiB (draft: 0.000 MiB)
53.28.946.517 I srv         alloc:  - prompt is already in the cache, skipping
53.28.946.518 I slot process_sing: id  6 | task -1 | saving idle slot to prompt cache
53.28.947.510 W srv   prompt_save:  - saving prompt with length 457, total state size = 79.674 MiB (draft: 0.000 MiB)
53.28.947.512 I srv         alloc:  - prompt is already in the cache, skipping
53.28.947.513 I slot process_sing: id  7 | task -1 | saving idle slot to prompt cache
53.28.948.560 W srv   prompt_save:  - saving prompt with length 1185, total state size = 179.863 MiB (draft: 0.000 MiB)
53.28.948.562 I srv         alloc:  - prompt is already in the cache, skipping
53.28.948.562 I slot process_sing: id  8 | task -1 | saving idle slot to prompt cache
53.28.949.624 W srv   prompt_save:  - saving prompt with length 2939, total state size = 194.443 MiB (draft: 0.000 MiB)
53.28.949.628 I srv         alloc:  - prompt is already in the cache, skipping
53.28.949.628 I slot process_sing: id  9 | task -1 | saving idle slot to prompt cache
53.28.950.919 W srv   prompt_save:  - saving prompt with length 1230, total state size = 180.237 MiB (draft: 0.000 MiB)
53.28.950.921 I srv         alloc:  - prompt is already in the cache, skipping
53.28.950.927 I slot print_timing: id  3 | task 4258 | prompt processing, n_tokens =  25283, progress = 0.95, t =  28.61 s / 883.64 tokens per second
53.31.559.896 I slot print_timing: id  3 | task 4258 | prompt processing, n_tokens =  27331, progress = 0.98, t =  31.22 s / 875.39 tokens per second
53.31.560.028 I slot update_slots: id  5 | task 4272 | Checking checkpoint with [0, 1412] against 0...
53.31.560.028 I slot update_slots: id  5 | task 4272 | Checking checkpoint with [0, 900] against 0...
53.31.560.029 I slot update_slots: id  5 | task 4272 | Checking checkpoint with [0, 601] against 0...
53.31.560.029 W slot update_slots: id  5 | task 4272 | forcing full prompt re-processing due to lack of cache data (likely due to SWA or hybrid/recurrent memory, see https://github.com/ggml-org/llama.cpp/pull/13194#issuecomment-2868343055)
53.31.560.030 W slot update_slots: id  5 | task 4272 | erased invalidated context checkpoint (pos_min = 0, pos_max = 601, n_tokens = 602, n_swa = 1024, pos_next = 0, size = 99.949 MiB)
53.31.571.388 W slot update_slots: id  5 | task 4272 | erased invalidated context checkpoint (pos_min = 0, pos_max = 900, n_tokens = 901, n_swa = 1024, pos_next = 0, size = 149.591 MiB)
53.31.588.115 W slot update_slots: id  5 | task 4272 | erased invalidated context checkpoint (pos_min = 0, pos_max = 1412, n_tokens = 1413, n_swa = 1024, pos_next = 0, size = 170.013 MiB)
53.32.665.851 I slot print_timing: id  3 | task 4258 | prompt processing, n_tokens =  28039, progress = 0.99, t =  32.33 s / 867.35 tokens per second
53.32.708.654 I slot create_check: id  3 | task 4258 | created context checkpoint 9 of 32 (pos_min = 68938, pos_max = 70473, n_tokens = 70474, size = 170.013 MiB)
53.32.709.526 I slot create_check: id  5 | task 4272 | created context checkpoint 1 of 32 (pos_min = 0, pos_max = 7, n_tokens = 8, size = 1.329 MiB)
53.33.420.235 I slot print_timing: id  3 | task 4258 | prompt processing, n_tokens =  28551, progress = 1.00, t =  33.08 s / 863.04 tokens per second
53.33.469.944 I slot create_check: id  3 | task 4258 | created context checkpoint 10 of 32 (pos_min = 69450, pos_max = 70985, n_tokens = 70986, size = 170.013 MiB)
53.33.749.631 I reasoning-budget: activated, budget=2147483647 tokens
53.33.750.092 I reasoning-budget: deactivated (natural end)
53.37.117.937 I slot print_timing: id  3 | task 4258 | n_decoded =    100, tg =  28.37 t/s
53.38.391.952 I slot print_timing: id  5 | task 4272 | n_decoded =    100, tg =  20.84 t/s
53.40.145.615 I slot print_timing: id  3 | task 4258 | n_decoded =    176, tg =  26.86 t/s
53.41.434.835 I slot print_timing: id  5 | task 4272 | n_decoded =    178, tg =  22.70 t/s
53.43.211.510 I slot print_timing: id  3 | task 4258 | n_decoded =    249, tg =  25.89 t/s
53.44.507.541 I slot print_timing: id  5 | task 4272 | n_decoded =    256, tg =  23.46 t/s
53.45.971.576 I slot print_timing: id  5 | task 4272 | prompt eval time =    2033.39 ms /    25 tokens (   81.34 ms per token,    12.29 tokens per second)
53.45.971.580 I slot print_timing: id  5 | task 4272 |        eval time =   12378.03 ms /   295 tokens (   41.96 ms per token,    23.83 tokens per second)
53.45.971.581 I slot print_timing: id  5 | task 4272 |       total time =   14411.42 ms /   320 tokens
53.45.971.582 I slot print_timing: id  5 | task 4272 |    graphs reused =       4017
53.45.971.583 I slot print_timing: id  5 | task 4272 | draft acceptance = 0.71429 (  220 accepted /   308 generated)
53.45.971.594 I statistics        draft-mtp: #calls(b,g,a) =   34   4192   4445, #gen drafts =   4445, #acc drafts =  3679, #gen tokens =  17780, #acc tokens = 11242, dur(b,g,a) = 0.065, 55460.628, 2.514 ms
53.45.971.609 I slot      release: id  5 | task 4272 | stop processing: n_tokens = 322, truncated = 0
53.45.990.931 I srv  params_from_: Chat format: peg-gemma4
53.46.072.755 I slot get_availabl: id  8 | task -1 | selected slot by LCP similarity, sim_best = 0.781 (> 0.100 thold), f_keep = 0.081
53.46.072.758 I srv  get_availabl: updating prompt cache
53.46.073.932 W srv   prompt_save:  - saving prompt with length 2939, total state size = 194.443 MiB (draft: 0.000 MiB)
53.46.073.941 I srv         alloc:  - prompt is already in the cache, skipping
53.46.073.942 I srv          load:  - looking for better prompt, base f_keep = 0.081, sim = 0.781
53.46.073.950 I srv        update:  - cache state: 14 prompts, 6358.885 MiB (limits: 8192.000 MiB, 2649600 tokens, 2649600 est)
53.46.073.950 I srv        update:    - prompt 0xb639a4cacf50:     112 tokens, checkpoints:  1,    20.856 MiB
53.46.073.951 I srv        update:    - prompt 0xb63981c727c0:     102 tokens, checkpoints:  1,    19.113 MiB
53.46.073.951 I srv        update:    - prompt 0xb639a46dfdf0:     672 tokens, checkpoints:  2,   163.481 MiB
53.46.073.951 I srv        update:    - prompt 0xb639a46dc9f0:    1185 tokens, checkpoints:  2,   235.318 MiB
53.46.073.952 I srv        update:    - prompt 0xb639a86b7bd0:     457 tokens, checkpoints:  1,    81.003 MiB
53.46.073.952 I srv        update:    - prompt 0xb639a47c1650:    1230 tokens, checkpoints:  1,   181.566 MiB
53.46.073.952 I srv        update:    - prompt 0xb639a4c95e50:    1353 tokens, checkpoints:  3,   374.186 MiB
53.46.073.953 I srv        update:    - prompt 0xb639a4cadb10:    2575 tokens, checkpoints:  3,   610.970 MiB
53.46.073.953 I srv        update:    - prompt 0xb639a46d9890:    2939 tokens, checkpoints:  4,   589.093 MiB
53.46.073.953 I srv        update:    - prompt 0xb639a84535e0:    7338 tokens, checkpoints:  1,   401.021 MiB
53.46.073.954 I srv        update:    - prompt 0xb639a9287360:     883 tokens, checkpoints:  1,   244.595 MiB
53.46.073.954 I srv        update:    - prompt 0xb639a8128da0:    7825 tokens, checkpoints:  2,   575.081 MiB
53.46.073.954 I srv        update:    - prompt 0xb639a8151fa0:    1068 tokens, checkpoints:  1,   269.542 MiB
53.46.073.955 I srv        update:    - prompt 0xb639b06fc320:   46064 tokens, checkpoints: 12,  2593.060 MiB
53.46.073.955 I srv  get_availabl: prompt cache update took 1.20 ms
53.46.074.002 I slot launch_slot_: id  8 | task 4355 | processing task, is_child = 0
53.46.074.003 I slot process_sing: id  0 | task -1 | saving idle slot to prompt cache
53.46.074.003 I slot process_sing: id  1 | task -1 | saving idle slot to prompt cache
53.46.074.003 I slot process_sing: id  2 | task -1 | saving idle slot to prompt cache
53.46.074.004 I slot process_sing: id  4 | task -1 | saving idle slot to prompt cache
53.46.075.069 W srv   prompt_save:  - saving prompt with length 1068, total state size = 178.890 MiB (draft: 0.000 MiB)
53.46.075.073 I srv         alloc:  - prompt is already in the cache, skipping
53.46.075.074 I slot process_sing: id  5 | task -1 | saving idle slot to prompt cache
53.46.076.419 W srv   prompt_save:  - saving prompt with length 322, total state size = 56.138 MiB (draft: 0.000 MiB)
53.46.092.488 I srv        update:  - cache state: 15 prompts, 6416.353 MiB (limits: 8192.000 MiB, 2649600 tokens, 2649600 est)
53.46.092.503 I srv        update:    - prompt 0xb639a4cacf50:     112 tokens, checkpoints:  1,    20.856 MiB
53.46.092.504 I srv        update:    - prompt 0xb63981c727c0:     102 tokens, checkpoints:  1,    19.113 MiB
53.46.092.505 I srv        update:    - prompt 0xb639a46dfdf0:     672 tokens, checkpoints:  2,   163.481 MiB
53.46.092.506 I srv        update:    - prompt 0xb639a46dc9f0:    1185 tokens, checkpoints:  2,   235.318 MiB
53.46.092.507 I srv        update:    - prompt 0xb639a86b7bd0:     457 tokens, checkpoints:  1,    81.003 MiB
53.46.092.508 I srv        update:    - prompt 0xb639a47c1650:    1230 tokens, checkpoints:  1,   181.566 MiB
53.46.092.509 I srv        update:    - prompt 0xb639a4c95e50:    1353 tokens, checkpoints:  3,   374.186 MiB
53.46.092.510 I srv        update:    - prompt 0xb639a4cadb10:    2575 tokens, checkpoints:  3,   610.970 MiB
53.46.092.511 I srv        update:    - prompt 0xb639a46d9890:    2939 tokens, checkpoints:  4,   589.093 MiB
53.46.092.512 I srv        update:    - prompt 0xb639a84535e0:    7338 tokens, checkpoints:  1,   401.021 MiB
53.46.092.512 I srv        update:    - prompt 0xb639a9287360:     883 tokens, checkpoints:  1,   244.595 MiB
53.46.092.513 I srv        update:    - prompt 0xb639a8128da0:    7825 tokens, checkpoints:  2,   575.081 MiB
53.46.092.514 I srv        update:    - prompt 0xb639a8151fa0:    1068 tokens, checkpoints:  1,   269.542 MiB
53.46.092.514 I srv        update:    - prompt 0xb639b06fc320:   46064 tokens, checkpoints: 12,  2593.060 MiB
53.46.092.515 I srv        update:    - prompt 0xb639b0248190:     322 tokens, checkpoints:  1,    57.468 MiB
53.46.092.518 I slot process_sing: id  6 | task -1 | saving idle slot to prompt cache
53.46.093.592 W srv   prompt_save:  - saving prompt with length 457, total state size = 79.674 MiB (draft: 0.000 MiB)
53.46.093.598 I srv         alloc:  - prompt is already in the cache, skipping
53.46.093.598 I slot process_sing: id  7 | task -1 | saving idle slot to prompt cache
53.46.094.617 W srv   prompt_save:  - saving prompt with length 1185, total state size = 179.863 MiB (draft: 0.000 MiB)
53.46.094.621 I srv         alloc:  - prompt is already in the cache, skipping
53.46.094.622 I slot process_sing: id  9 | task -1 | saving idle slot to prompt cache
53.46.095.681 W srv   prompt_save:  - saving prompt with length 1230, total state size = 180.237 MiB (draft: 0.000 MiB)
53.46.095.684 I srv         alloc:  - prompt is already in the cache, skipping
53.46.119.431 I slot update_slots: id  8 | task 4355 | Checking checkpoint with [716, 2251] against 0...
53.46.119.434 I slot update_slots: id  8 | task 4355 | Checking checkpoint with [204, 1739] against 0...
53.46.119.434 I slot update_slots: id  8 | task 4355 | Checking checkpoint with [0, 320] against 0...
53.46.119.435 I slot update_slots: id  8 | task 4355 | Checking checkpoint with [0, 7] against 0...
53.46.120.678 W slot update_slots: id  8 | task 4355 | restored context checkpoint (pos_min = 0, pos_max = 7, n_tokens = 8, n_past = 7, size = 1.329 MiB)
53.46.120.682 W slot update_slots: id  8 | task 4355 | erased invalidated context checkpoint (pos_min = 0, pos_max = 320, n_tokens = 321, n_swa = 1024, pos_next = 7, size = 53.296 MiB)
53.46.126.169 W slot update_slots: id  8 | task 4355 | erased invalidated context checkpoint (pos_min = 204, pos_max = 1739, n_tokens = 1740, n_swa = 1024, pos_next = 7, size = 170.013 MiB)
53.46.143.892 W slot update_slots: id  8 | task 4355 | erased invalidated context checkpoint (pos_min = 716, pos_max = 2251, n_tokens = 2252, n_swa = 1024, pos_next = 7, size = 170.013 MiB)
53.46.267.150 I slot print_timing: id  3 | task 4258 | n_decoded =    327, tg =  25.80 t/s
53.46.568.348 I slot create_check: id  8 | task 4355 | created context checkpoint 2 of 32 (pos_min = 0, pos_max = 301, n_tokens = 302, size = 50.141 MiB)
53.49.318.485 I slot print_timing: id  3 | task 4258 | n_decoded =    407, tg =  25.88 t/s
53.50.984.401 I slot print_timing: id  8 | task 4355 | n_decoded =    103, tg =  23.96 t/s
53.52.343.992 I slot print_timing: id  3 | task 4258 | n_decoded =    495, tg =  26.40 t/s
53.54.020.003 I slot print_timing: id  8 | task 4355 | n_decoded =    180, tg =  24.54 t/s
53.55.403.135 I slot print_timing: id  3 | task 4258 | n_decoded =    584, tg =  26.78 t/s
53.57.084.041 I slot print_timing: id  8 | task 4355 | n_decoded =    255, tg =  24.52 t/s
53.58.460.869 I slot print_timing: id  3 | task 4258 | n_decoded =    671, tg =  26.98 t/s
54.00.134.868 I slot print_timing: id  8 | task 4355 | n_decoded =    318, tg =  23.64 t/s
54.01.505.466 I slot print_timing: id  3 | task 4258 | n_decoded =    746, tg =  26.73 t/s
54.03.174.267 I slot print_timing: id  8 | task 4355 | n_decoded =    397, tg =  24.08 t/s
54.04.555.649 I slot print_timing: id  3 | task 4258 | n_decoded =    826, tg =  26.68 t/s
54.05.620.418 I slot print_timing: id  8 | task 4355 | prompt eval time =     566.32 ms /   299 tokens (    1.89 ms per token,   527.97 tokens per second)
54.05.620.423 I slot print_timing: id  8 | task 4355 |        eval time =   18934.54 ms /   457 tokens (   41.43 ms per token,    24.14 tokens per second)
54.05.620.423 I slot print_timing: id  8 | task 4355 |       total time =   19500.86 ms /   756 tokens
54.05.620.425 I slot print_timing: id  8 | task 4355 |    graphs reused =       4018
54.05.620.426 I slot print_timing: id  8 | task 4355 | draft acceptance = 0.67137 (  333 accepted /   496 generated)
54.05.620.440 I statistics        draft-mtp: #calls(b,g,a) =   35   4320   4697, #gen drafts =   4697, #acc drafts =  3908, #gen tokens =  18788, #acc tokens = 11991, dur(b,g,a) = 0.066, 59267.323, 2.666 ms
54.05.620.478 I slot      release: id  8 | task 4355 | stop processing: n_tokens = 763, truncated = 0
54.05.637.855 I srv  params_from_: Chat format: peg-gemma4
54.05.720.718 I slot get_availabl: id  7 | task -1 | selected slot by LCP similarity, sim_best = 0.814 (> 0.100 thold), f_keep = 0.248
54.05.720.723 I srv  get_availabl: updating prompt cache
54.05.721.757 W srv   prompt_save:  - saving prompt with length 1185, total state size = 179.863 MiB (draft: 0.000 MiB)
54.05.721.763 I srv         alloc:  - prompt is already in the cache, skipping
54.05.721.764 I srv          load:  - looking for better prompt, base f_keep = 0.248, sim = 0.814
54.05.721.772 I srv        update:  - cache state: 15 prompts, 6416.353 MiB (limits: 8192.000 MiB, 2649600 tokens, 2649600 est)
54.05.721.773 I srv        update:    - prompt 0xb639a4cacf50:     112 tokens, checkpoints:  1,    20.856 MiB
54.05.721.773 I srv        update:    - prompt 0xb63981c727c0:     102 tokens, checkpoints:  1,    19.113 MiB
54.05.721.774 I srv        update:    - prompt 0xb639a46dfdf0:     672 tokens, checkpoints:  2,   163.481 MiB
54.05.721.774 I srv        update:    - prompt 0xb639a46dc9f0:    1185 tokens, checkpoints:  2,   235.318 MiB
54.05.721.774 I srv        update:    - prompt 0xb639a86b7bd0:     457 tokens, checkpoints:  1,    81.003 MiB
54.05.721.774 I srv        update:    - prompt 0xb639a47c1650:    1230 tokens, checkpoints:  1,   181.566 MiB
54.05.721.775 I srv        update:    - prompt 0xb639a4c95e50:    1353 tokens, checkpoints:  3,   374.186 MiB
54.05.721.775 I srv        update:    - prompt 0xb639a4cadb10:    2575 tokens, checkpoints:  3,   610.970 MiB
54.05.721.775 I srv        update:    - prompt 0xb639a46d9890:    2939 tokens, checkpoints:  4,   589.093 MiB
54.05.721.776 I srv        update:    - prompt 0xb639a84535e0:    7338 tokens, checkpoints:  1,   401.021 MiB
54.05.721.776 I srv        update:    - prompt 0xb639a9287360:     883 tokens, checkpoints:  1,   244.595 MiB
54.05.721.776 I srv        update:    - prompt 0xb639a8128da0:    7825 tokens, checkpoints:  2,   575.081 MiB
54.05.721.777 I srv        update:    - prompt 0xb639a8151fa0:    1068 tokens, checkpoints:  1,   269.542 MiB
54.05.721.777 I srv        update:    - prompt 0xb639b06fc320:   46064 tokens, checkpoints: 12,  2593.060 MiB
54.05.721.777 I srv        update:    - prompt 0xb639b0248190:     322 tokens, checkpoints:  1,    57.468 MiB
54.05.721.777 I srv  get_availabl: prompt cache update took 1.05 ms
54.05.721.826 I slot launch_slot_: id  7 | task 4484 | processing task, is_child = 0
54.05.721.829 I slot process_sing: id  0 | task -1 | saving idle slot to prompt cache
54.05.721.829 I slot process_sing: id  1 | task -1 | saving idle slot to prompt cache
54.05.721.829 I slot process_sing: id  2 | task -1 | saving idle slot to prompt cache
54.05.721.830 I slot process_sing: id  4 | task -1 | saving idle slot to prompt cache
54.05.722.923 W srv   prompt_save:  - saving prompt with length 1068, total state size = 178.890 MiB (draft: 0.000 MiB)
54.05.722.928 I srv         alloc:  - prompt is already in the cache, skipping
54.05.722.928 I slot process_sing: id  5 | task -1 | saving idle slot to prompt cache
54.05.723.949 W srv   prompt_save:  - saving prompt with length 322, total state size = 56.138 MiB (draft: 0.000 MiB)
54.05.723.951 I srv         alloc:  - prompt is already in the cache, skipping
54.05.723.952 I slot process_sing: id  6 | task -1 | saving idle slot to prompt cache
54.05.724.966 W srv   prompt_save:  - saving prompt with length 457, total state size = 79.674 MiB (draft: 0.000 MiB)
54.05.724.968 I srv         alloc:  - prompt is already in the cache, skipping
54.05.724.969 I slot process_sing: id  8 | task -1 | saving idle slot to prompt cache
54.05.725.930 W srv   prompt_save:  - saving prompt with length 763, total state size = 133.022 MiB (draft: 0.000 MiB)
54.05.773.725 I srv        update:  - cache state: 16 prompts, 6600.845 MiB (limits: 8192.000 MiB, 2649600 tokens, 2649600 est)
54.05.773.729 I srv        update:    - prompt 0xb639a4cacf50:     112 tokens, checkpoints:  1,    20.856 MiB
54.05.773.730 I srv        update:    - prompt 0xb63981c727c0:     102 tokens, checkpoints:  1,    19.113 MiB
54.05.773.730 I srv        update:    - prompt 0xb639a46dfdf0:     672 tokens, checkpoints:  2,   163.481 MiB
54.05.773.731 I srv        update:    - prompt 0xb639a46dc9f0:    1185 tokens, checkpoints:  2,   235.318 MiB
54.05.773.731 I srv        update:    - prompt 0xb639a86b7bd0:     457 tokens, checkpoints:  1,    81.003 MiB
54.05.773.732 I srv        update:    - prompt 0xb639a47c1650:    1230 tokens, checkpoints:  1,   181.566 MiB
54.05.773.732 I srv        update:    - prompt 0xb639a4c95e50:    1353 tokens, checkpoints:  3,   374.186 MiB
54.05.773.732 I srv        update:    - prompt 0xb639a4cadb10:    2575 tokens, checkpoints:  3,   610.970 MiB
54.05.773.733 I srv        update:    - prompt 0xb639a46d9890:    2939 tokens, checkpoints:  4,   589.093 MiB
54.05.773.733 I srv        update:    - prompt 0xb639a84535e0:    7338 tokens, checkpoints:  1,   401.021 MiB
54.05.773.734 I srv        update:    - prompt 0xb639a9287360:     883 tokens, checkpoints:  1,   244.595 MiB
54.05.773.734 I srv        update:    - prompt 0xb639a8128da0:    7825 tokens, checkpoints:  2,   575.081 MiB
54.05.773.734 I srv        update:    - prompt 0xb639a8151fa0:    1068 tokens, checkpoints:  1,   269.542 MiB
54.05.773.735 I srv        update:    - prompt 0xb639b06fc320:   46064 tokens, checkpoints: 12,  2593.060 MiB
54.05.773.735 I srv        update:    - prompt 0xb639b0248190:     322 tokens, checkpoints:  1,    57.468 MiB
54.05.773.735 I srv        update:    - prompt 0xb639b0680930:     763 tokens, checkpoints:  2,   184.492 MiB
54.05.773.736 I slot process_sing: id  9 | task -1 | saving idle slot to prompt cache
54.05.774.812 W srv   prompt_save:  - saving prompt with length 1230, total state size = 180.237 MiB (draft: 0.000 MiB)
54.05.774.817 I srv         alloc:  - prompt is already in the cache, skipping
54.05.794.854 I slot update_slots: id  7 | task 4484 | Checking checkpoint with [0, 325] against 0...
54.05.794.856 I slot update_slots: id  7 | task 4484 | Checking checkpoint with [0, 7] against 0...
54.05.797.474 W slot update_slots: id  7 | task 4484 | restored context checkpoint (pos_min = 0, pos_max = 7, n_tokens = 8, n_past = 7, size = 1.329 MiB)
54.05.797.477 W slot update_slots: id  7 | task 4484 | erased invalidated context checkpoint (pos_min = 0, pos_max = 325, n_tokens = 326, n_swa = 1024, pos_next = 7, size = 54.126 MiB)
54.06.245.319 I slot create_check: id  7 | task 4484 | created context checkpoint 2 of 32 (pos_min = 0, pos_max = 356, n_tokens = 357, size = 59.273 MiB)
54.07.579.842 I slot print_timing: id  3 | task 4258 | n_decoded =    912, tg =  26.83 t/s
54.10.604.350 I slot print_timing: id  3 | task 4258 | n_decoded =    984, tg =  26.59 t/s
54.10.759.898 I slot print_timing: id  7 | task 4484 | n_decoded =    104, tg =  23.67 t/s
54.13.668.120 I slot print_timing: id  3 | task 4258 | n_decoded =   1063, tg =  26.53 t/s
54.13.825.865 I slot print_timing: id  7 | task 4484 | n_decoded =    172, tg =  23.06 t/s
54.16.716.428 I slot print_timing: id  3 | task 4258 | n_decoded =   1149, tg =  26.64 t/s
54.16.875.100 I slot print_timing: id  7 | task 4484 | n_decoded =    246, tg =  23.41 t/s
54.19.785.331 I slot print_timing: id  3 | task 4258 | n_decoded =   1244, tg =  26.93 t/s
54.19.943.902 I slot print_timing: id  7 | task 4484 | n_decoded =    306, tg =  22.54 t/s
54.22.852.694 I slot print_timing: id  3 | task 4258 | n_decoded =   1335, tg =  27.10 t/s
54.23.017.129 I slot print_timing: id  7 | task 4484 | n_decoded =    375, tg =  22.52 t/s
54.25.940.270 I slot print_timing: id  3 | task 4258 | n_decoded =   1423, tg =  27.18 t/s
54.26.105.096 I slot print_timing: id  7 | task 4484 | n_decoded =    436, tg =  22.09 t/s
54.29.041.468 I slot print_timing: id  3 | task 4258 | n_decoded =   1509, tg =  27.21 t/s
54.29.198.463 I slot print_timing: id  7 | task 4484 | n_decoded =    508, tg =  22.25 t/s
54.32.139.738 I slot print_timing: id  3 | task 4258 | n_decoded =   1603, tg =  27.38 t/s
54.32.288.495 I slot print_timing: id  7 | task 4484 | n_decoded =    579, tg =  22.34 t/s
54.35.146.666 I slot print_timing: id  3 | task 4258 | n_decoded =   1706, tg =  27.72 t/s
54.35.294.483 I slot print_timing: id  7 | task 4484 | n_decoded =    632, tg =  21.85 t/s
54.37.721.855 I slot print_timing: id  7 | task 4484 | prompt eval time =     571.19 ms /   354 tokens (    1.61 ms per token,   619.76 tokens per second)
54.37.721.860 I slot print_timing: id  7 | task 4484 |        eval time =   31355.69 ms /   688 tokens (   45.58 ms per token,    21.94 tokens per second)
54.37.721.860 I slot print_timing: id  7 | task 4484 |       total time =   31926.88 ms /  1042 tokens
54.37.721.862 I slot print_timing: id  7 | task 4484 |    graphs reused =       4019
54.37.721.863 I slot print_timing: id  7 | task 4484 | draft acceptance = 0.57933 (  482 accepted /   832 generated)
54.37.721.876 I statistics        draft-mtp: #calls(b,g,a) =   36   4532   5117, #gen drafts =   5117, #acc drafts =  4272, #gen tokens =  20468, #acc tokens = 13183, dur(b,g,a) = 0.068, 65516.157, 2.920 ms
54.37.721.918 I slot      release: id  7 | task 4484 | stop processing: n_tokens = 1051, truncated = 0
54.37.735.307 I srv  params_from_: Chat format: peg-gemma4
54.37.821.788 I slot get_availabl: id  6 | task -1 | selected slot by LCP similarity, sim_best = 0.732 (> 0.100 thold), f_keep = 0.400
54.37.821.790 I srv  get_availabl: updating prompt cache
54.37.823.084 W srv   prompt_save:  - saving prompt with length 457, total state size = 79.674 MiB (draft: 0.000 MiB)
54.37.823.090 I srv         alloc:  - prompt is already in the cache, skipping
54.37.823.091 I srv          load:  - looking for better prompt, base f_keep = 0.400, sim = 0.732
54.37.823.100 I srv        update:  - cache state: 16 prompts, 6600.845 MiB (limits: 8192.000 MiB, 2649600 tokens, 2649600 est)
54.37.823.101 I srv        update:    - prompt 0xb639a4cacf50:     112 tokens, checkpoints:  1,    20.856 MiB
54.37.823.101 I srv        update:    - prompt 0xb63981c727c0:     102 tokens, checkpoints:  1,    19.113 MiB
54.37.823.102 I srv        update:    - prompt 0xb639a46dfdf0:     672 tokens, checkpoints:  2,   163.481 MiB
54.37.823.102 I srv        update:    - prompt 0xb639a46dc9f0:    1185 tokens, checkpoints:  2,   235.318 MiB
54.37.823.102 I srv        update:    - prompt 0xb639a86b7bd0:     457 tokens, checkpoints:  1,    81.003 MiB
54.37.823.103 I srv        update:    - prompt 0xb639a47c1650:    1230 tokens, checkpoints:  1,   181.566 MiB
54.37.823.103 I srv        update:    - prompt 0xb639a4c95e50:    1353 tokens, checkpoints:  3,   374.186 MiB
54.37.823.103 I srv        update:    - prompt 0xb639a4cadb10:    2575 tokens, checkpoints:  3,   610.970 MiB
54.37.823.104 I srv        update:    - prompt 0xb639a46d9890:    2939 tokens, checkpoints:  4,   589.093 MiB
54.37.823.104 I srv        update:    - prompt 0xb639a84535e0:    7338 tokens, checkpoints:  1,   401.021 MiB
54.37.823.104 I srv        update:    - prompt 0xb639a9287360:     883 tokens, checkpoints:  1,   244.595 MiB
54.37.823.105 I srv        update:    - prompt 0xb639a8128da0:    7825 tokens, checkpoints:  2,   575.081 MiB
54.37.823.105 I srv        update:    - prompt 0xb639a8151fa0:    1068 tokens, checkpoints:  1,   269.542 MiB
54.37.823.105 I srv        update:    - prompt 0xb639b06fc320:   46064 tokens, checkpoints: 12,  2593.060 MiB
54.37.823.106 I srv        update:    - prompt 0xb639b0248190:     322 tokens, checkpoints:  1,    57.468 MiB
54.37.823.106 I srv        update:    - prompt 0xb639b0680930:     763 tokens, checkpoints:  2,   184.492 MiB
54.37.823.106 I srv  get_availabl: prompt cache update took 1.32 ms
54.37.823.155 I slot launch_slot_: id  6 | task 4697 | processing task, is_child = 0
54.37.823.156 I slot process_sing: id  0 | task -1 | saving idle slot to prompt cache
54.37.823.156 I slot process_sing: id  1 | task -1 | saving idle slot to prompt cache
54.37.823.156 I slot process_sing: id  2 | task -1 | saving idle slot to prompt cache
54.37.823.157 I slot process_sing: id  4 | task -1 | saving idle slot to prompt cache
54.37.824.427 W srv   prompt_save:  - saving prompt with length 1068, total state size = 178.890 MiB (draft: 0.000 MiB)
54.37.824.432 I srv         alloc:  - prompt is already in the cache, skipping
54.37.824.432 I slot process_sing: id  5 | task -1 | saving idle slot to prompt cache
54.37.825.660 W srv   prompt_save:  - saving prompt with length 322, total state size = 56.138 MiB (draft: 0.000 MiB)
54.37.825.662 I srv         alloc:  - prompt is already in the cache, skipping
54.37.825.662 I slot process_sing: id  7 | task -1 | saving idle slot to prompt cache
54.37.826.869 W srv   prompt_save:  - saving prompt with length 1051, total state size = 178.749 MiB (draft: 0.000 MiB)
54.37.883.828 I srv        update:  - cache state: 17 prompts, 6840.196 MiB (limits: 8192.000 MiB, 2649600 tokens, 2649600 est)
54.37.883.835 I srv        update:    - prompt 0xb639a4cacf50:     112 tokens, checkpoints:  1,    20.856 MiB
54.37.883.835 I srv        update:    - prompt 0xb63981c727c0:     102 tokens, checkpoints:  1,    19.113 MiB
54.37.883.835 I srv        update:    - prompt 0xb639a46dfdf0:     672 tokens, checkpoints:  2,   163.481 MiB
54.37.883.836 I srv        update:    - prompt 0xb639a46dc9f0:    1185 tokens, checkpoints:  2,   235.318 MiB
54.37.883.836 I srv        update:    - prompt 0xb639a86b7bd0:     457 tokens, checkpoints:  1,    81.003 MiB
54.37.883.836 I srv        update:    - prompt 0xb639a47c1650:    1230 tokens, checkpoints:  1,   181.566 MiB
54.37.883.836 I srv        update:    - prompt 0xb639a4c95e50:    1353 tokens, checkpoints:  3,   374.186 MiB
54.37.883.837 I srv        update:    - prompt 0xb639a4cadb10:    2575 tokens, checkpoints:  3,   610.970 MiB
54.37.883.837 I srv        update:    - prompt 0xb639a46d9890:    2939 tokens, checkpoints:  4,   589.093 MiB
54.37.883.837 I srv        update:    - prompt 0xb639a84535e0:    7338 tokens, checkpoints:  1,   401.021 MiB
54.37.883.838 I srv        update:    - prompt 0xb639a9287360:     883 tokens, checkpoints:  1,   244.595 MiB
54.37.883.838 I srv        update:    - prompt 0xb639a8128da0:    7825 tokens, checkpoints:  2,   575.081 MiB
54.37.883.838 I srv        update:    - prompt 0xb639a8151fa0:    1068 tokens, checkpoints:  1,   269.542 MiB
54.37.883.839 I srv        update:    - prompt 0xb639b06fc320:   46064 tokens, checkpoints: 12,  2593.060 MiB
54.37.883.839 I srv        update:    - prompt 0xb639b0248190:     322 tokens, checkpoints:  1,    57.468 MiB
54.37.883.839 I srv        update:    - prompt 0xb639b0680930:     763 tokens, checkpoints:  2,   184.492 MiB
54.37.883.839 I srv        update:    - prompt 0xb639a47ca1f0:    1051 tokens, checkpoints:  2,   239.351 MiB
54.37.883.840 I slot process_sing: id  8 | task -1 | saving idle slot to prompt cache
54.37.884.832 W srv   prompt_save:  - saving prompt with length 763, total state size = 133.022 MiB (draft: 0.000 MiB)
54.37.884.841 I srv         alloc:  - prompt is already in the cache, skipping
54.37.884.842 I slot process_sing: id  9 | task -1 | saving idle slot to prompt cache
54.37.885.865 W srv   prompt_save:  - saving prompt with length 1230, total state size = 180.237 MiB (draft: 0.000 MiB)
54.37.885.868 I srv         alloc:  - prompt is already in the cache, skipping
54.37.909.089 I slot update_slots: id  6 | task 4697 | Checking checkpoint with [0, 7] against 0...
54.37.909.861 W slot update_slots: id  6 | task 4697 | restored context checkpoint (pos_min = 0, pos_max = 7, n_tokens = 8, n_past = 7, size = 1.329 MiB)
54.38.237.612 I slot print_timing: id  3 | task 4258 | n_decoded =   1798, tg =  27.81 t/s
54.41.317.501 I slot print_timing: id  3 | task 4258 | n_decoded =   1887, tg =  27.86 t/s
54.42.024.381 I slot print_timing: id  6 | task 4697 | n_decoded =    101, tg =  27.70 t/s
54.44.319.513 I slot print_timing: id  3 | task 4258 | n_decoded =   1978, tg =  27.97 t/s
54.45.025.736 I slot print_timing: id  6 | task 4697 | n_decoded =    161, tg =  24.22 t/s
54.46.425.390 I slot print_timing: id  6 | task 4697 | prompt eval time =     468.65 ms /   243 tokens (    1.93 ms per token,   518.51 tokens per second)
54.46.425.394 I slot print_timing: id  6 | task 4697 |        eval time =    8047.53 ms /   198 tokens (   40.64 ms per token,    24.60 tokens per second)
54.46.425.395 I slot print_timing: id  6 | task 4697 |       total time =    8516.18 ms /   441 tokens
54.46.425.396 I slot print_timing: id  6 | task 4697 |    graphs reused =       4020
54.46.425.397 I slot print_timing: id  6 | task 4697 | draft acceptance = 0.62281 (  142 accepted /   228 generated)
54.46.425.411 I statistics        draft-mtp: #calls(b,g,a) =   37   4593   5235, #gen drafts =   5235, #acc drafts =  4372, #gen tokens =  20940, #acc tokens = 13511, dur(b,g,a) = 0.070, 67206.864, 3.004 ms
54.46.425.445 I slot      release: id  6 | task 4697 | stop processing: n_tokens = 449, truncated = 0
54.47.344.465 I slot print_timing: id  3 | task 4258 | n_decoded =   2069, tg =  28.05 t/s
54.50.402.172 I slot print_timing: id  3 | task 4258 | n_decoded =   2210, tg =  28.77 t/s
54.53.407.001 I slot print_timing: id  3 | task 4258 | n_decoded =   2365, tg =  29.63 t/s
54.56.427.303 I slot print_timing: id  3 | task 4258 | n_decoded =   2518, tg =  30.40 t/s
54.59.497.097 I slot print_timing: id  3 | task 4258 | n_decoded =   2690, tg =  31.31 t/s
55.02.568.721 I slot print_timing: id  3 | task 4258 | n_decoded =   2854, tg =  32.08 t/s
55.05.639.279 I slot print_timing: id  3 | task 4258 | n_decoded =   3012, tg =  32.72 t/s
55.08.720.691 I slot print_timing: id  3 | task 4258 | n_decoded =   3169, tg =  33.31 t/s
55.11.808.582 I slot print_timing: id  3 | task 4258 | n_decoded =   3326, tg =  33.86 t/s
55.14.813.126 I slot print_timing: id  3 | task 4258 | n_decoded =   3490, tg =  34.48 t/s
55.17.840.149 I slot print_timing: id  3 | task 4258 | n_decoded =   3655, tg =  35.06 t/s
55.20.881.062 I slot print_timing: id  3 | task 4258 | n_decoded =   3782, tg =  35.25 t/s
55.23.118.560 I reasoning-budget: re-activated on new start tag, budget=2147483647 tokens
55.23.119.028 I reasoning-budget: deactivated (natural end)
55.23.780.420 I slot print_timing: id  3 | task 4258 | prompt eval time =   33254.60 ms / 28555 tokens (    1.16 ms per token,   858.68 tokens per second)
55.23.780.423 I slot print_timing: id  3 | task 4258 |        eval time =  110187.22 ms /  3881 tokens (   28.39 ms per token,    35.22 tokens per second)
55.23.780.423 I slot print_timing: id  3 | task 4258 |       total time =  143441.82 ms / 32436 tokens
55.23.780.424 I slot print_timing: id  3 | task 4258 |    graphs reused =       4449
55.23.780.425 I slot print_timing: id  3 | task 4258 | draft acceptance = 0.81011 ( 2965 accepted /  3660 generated)
55.23.780.437 I statistics        draft-mtp: #calls(b,g,a) =   37   5030   5672, #gen drafts =   5672, #acc drafts =  4783, #gen tokens =  22688, #acc tokens = 14925, dur(b,g,a) = 0.070, 75287.541, 3.218 ms
55.23.781.677 I slot      release: id  3 | task 4258 | stop processing: n_tokens = 74870, truncated = 0
55.23.781.708 I srv  update_slots: all slots are idle
55.24.021.374 I srv  params_from_: Chat format: peg-gemma4
55.24.056.496 I slot get_availabl: id  3 | task -1 | selected slot by LCP similarity, sim_best = 0.948 (> 0.100 thold), f_keep = 0.948
55.24.056.762 I slot launch_slot_: id  3 | task 5195 | processing task, is_child = 0
55.24.056.766 I slot process_sing: id  0 | task -1 | saving idle slot to prompt cache
55.24.056.767 I slot process_sing: id  1 | task -1 | saving idle slot to prompt cache
55.24.056.768 I slot process_sing: id  2 | task -1 | saving idle slot to prompt cache
55.24.056.768 I slot process_sing: id  4 | task -1 | saving idle slot to prompt cache
55.24.057.982 W srv   prompt_save:  - saving prompt with length 1068, total state size = 178.890 MiB (draft: 0.000 MiB)
55.24.057.990 I srv         alloc:  - prompt is already in the cache, skipping
55.24.057.990 I slot process_sing: id  5 | task -1 | saving idle slot to prompt cache
55.24.058.983 W srv   prompt_save:  - saving prompt with length 322, total state size = 56.138 MiB (draft: 0.000 MiB)
55.24.058.986 I srv         alloc:  - prompt is already in the cache, skipping
55.24.058.986 I slot process_sing: id  6 | task -1 | saving idle slot to prompt cache
55.24.059.902 W srv   prompt_save:  - saving prompt with length 449, total state size = 78.280 MiB (draft: 0.000 MiB)
55.24.065.089 I srv        update:  - cache state: 18 prompts, 6919.805 MiB (limits: 8192.000 MiB, 2649600 tokens, 2649600 est)
55.24.065.091 I srv        update:    - prompt 0xb639a4cacf50:     112 tokens, checkpoints:  1,    20.856 MiB
55.24.065.092 I srv        update:    - prompt 0xb63981c727c0:     102 tokens, checkpoints:  1,    19.113 MiB
55.24.065.092 I srv        update:    - prompt 0xb639a46dfdf0:     672 tokens, checkpoints:  2,   163.481 MiB
55.24.065.093 I srv        update:    - prompt 0xb639a46dc9f0:    1185 tokens, checkpoints:  2,   235.318 MiB
55.24.065.093 I srv        update:    - prompt 0xb639a86b7bd0:     457 tokens, checkpoints:  1,    81.003 MiB
55.24.065.094 I srv        update:    - prompt 0xb639a47c1650:    1230 tokens, checkpoints:  1,   181.566 MiB
55.24.065.094 I srv        update:    - prompt 0xb639a4c95e50:    1353 tokens, checkpoints:  3,   374.186 MiB
55.24.065.094 I srv        update:    - prompt 0xb639a4cadb10:    2575 tokens, checkpoints:  3,   610.970 MiB
55.24.065.095 I srv        update:    - prompt 0xb639a46d9890:    2939 tokens, checkpoints:  4,   589.093 MiB
55.24.065.095 I srv        update:    - prompt 0xb639a84535e0:    7338 tokens, checkpoints:  1,   401.021 MiB
55.24.065.096 I srv        update:    - prompt 0xb639a9287360:     883 tokens, checkpoints:  1,   244.595 MiB
55.24.065.096 I srv        update:    - prompt 0xb639a8128da0:    7825 tokens, checkpoints:  2,   575.081 MiB
55.24.065.096 I srv        update:    - prompt 0xb639a8151fa0:    1068 tokens, checkpoints:  1,   269.542 MiB
55.24.065.097 I srv        update:    - prompt 0xb639b06fc320:   46064 tokens, checkpoints: 12,  2593.060 MiB
55.24.065.097 I srv        update:    - prompt 0xb639b0248190:     322 tokens, checkpoints:  1,    57.468 MiB
55.24.065.098 I srv        update:    - prompt 0xb639b0680930:     763 tokens, checkpoints:  2,   184.492 MiB
55.24.065.098 I srv        update:    - prompt 0xb639a47ca1f0:    1051 tokens, checkpoints:  2,   239.351 MiB
55.24.065.098 I srv        update:    - prompt 0xb639a8e71b30:     449 tokens, checkpoints:  1,    79.609 MiB
55.24.065.099 I slot process_sing: id  7 | task -1 | saving idle slot to prompt cache
55.24.066.158 W srv   prompt_save:  - saving prompt with length 1051, total state size = 178.749 MiB (draft: 0.000 MiB)
55.24.066.165 I srv         alloc:  - prompt is already in the cache, skipping
55.24.066.165 I slot process_sing: id  8 | task -1 | saving idle slot to prompt cache
55.24.067.092 W srv   prompt_save:  - saving prompt with length 763, total state size = 133.022 MiB (draft: 0.000 MiB)
55.24.067.096 I srv         alloc:  - prompt is already in the cache, skipping
55.24.067.097 I slot process_sing: id  9 | task -1 | saving idle slot to prompt cache
55.24.068.040 W srv   prompt_save:  - saving prompt with length 1230, total state size = 180.237 MiB (draft: 0.000 MiB)
55.24.068.042 I srv         alloc:  - prompt is already in the cache, skipping
55.24.068.086 I slot update_slots: id  3 | task 5195 | Checking checkpoint with [69450, 70985] against 69966...
55.24.072.317 W slot update_slots: id  3 | task 5195 | restored context checkpoint (pos_min = 69450, pos_max = 70985, n_tokens = 70986, n_past = 70985, size = 170.013 MiB)
55.27.761.453 I slot print_timing: id  3 | task 5195 | prompt processing, n_tokens =   3406, progress = 0.99, t =   3.69 s / 922.19 tokens per second
55.27.802.954 I slot create_check: id  3 | task 5195 | created context checkpoint 11 of 32 (pos_min = 72855, pos_max = 74390, n_tokens = 74391, size = 170.013 MiB)
55.28.372.339 I slot print_timing: id  3 | task 5195 | prompt processing, n_tokens =   3918, progress = 1.00, t =   4.30 s / 910.26 tokens per second
55.28.421.054 I slot create_check: id  3 | task 5195 | created context checkpoint 12 of 32 (pos_min = 73367, pos_max = 74902, n_tokens = 74903, size = 170.013 MiB)
55.28.572.420 I reasoning-budget: activated, budget=2147483647 tokens
55.28.572.883 I reasoning-budget: deactivated (natural end)
55.30.405.129 I slot print_timing: id  3 | task 5195 | n_decoded =    100, tg =  52.14 t/s
55.33.472.471 I slot print_timing: id  3 | task 5195 | n_decoded =    242, tg =  48.54 t/s
55.36.537.035 I slot print_timing: id  3 | task 5195 | n_decoded =    386, tg =  47.95 t/s
55.39.545.746 I slot print_timing: id  3 | task 5195 | n_decoded =    538, tg =  48.65 t/s
55.40.462.127 W srv          stop: cancel task, id_task = 5195
55.40.547.714 I slot      release: id  3 | task 5195 | stop processing: n_tokens = 75490, truncated = 0
55.40.547.736 I srv  update_slots: all slots are idle
56.17.538.464 I srv  params_from_: Chat format: peg-gemma4
56.17.579.316 I slot get_availabl: id  3 | task -1 | selected slot by LCP similarity, sim_best = 0.562 (> 0.100 thold), f_keep = 0.552
56.17.579.554 I slot launch_slot_: id  3 | task 5338 | processing task, is_child = 0
56.17.579.557 I slot process_sing: id  0 | task -1 | saving idle slot to prompt cache
56.17.579.558 I slot process_sing: id  1 | task -1 | saving idle slot to prompt cache
56.17.579.558 I slot process_sing: id  2 | task -1 | saving idle slot to prompt cache
56.17.579.559 I slot process_sing: id  4 | task -1 | saving idle slot to prompt cache
56.17.581.391 W srv   prompt_save:  - saving prompt with length 1068, total state size = 178.890 MiB (draft: 0.000 MiB)
56.17.581.403 I srv         alloc:  - prompt is already in the cache, skipping
56.17.581.404 I slot process_sing: id  5 | task -1 | saving idle slot to prompt cache
56.17.583.188 W srv   prompt_save:  - saving prompt with length 322, total state size = 56.138 MiB (draft: 0.000 MiB)
56.17.583.197 I srv         alloc:  - prompt is already in the cache, skipping
56.17.583.198 I slot process_sing: id  6 | task -1 | saving idle slot to prompt cache
56.17.585.154 W srv   prompt_save:  - saving prompt with length 449, total state size = 78.280 MiB (draft: 0.000 MiB)
56.17.585.166 I srv         alloc:  - prompt is already in the cache, skipping
56.17.585.167 I slot process_sing: id  7 | task -1 | saving idle slot to prompt cache
56.17.586.976 W srv   prompt_save:  - saving prompt with length 1051, total state size = 178.749 MiB (draft: 0.000 MiB)
56.17.586.987 I srv         alloc:  - prompt is already in the cache, skipping
56.17.586.988 I slot process_sing: id  8 | task -1 | saving idle slot to prompt cache
56.17.588.777 W srv   prompt_save:  - saving prompt with length 763, total state size = 133.022 MiB (draft: 0.000 MiB)
56.17.588.789 I srv         alloc:  - prompt is already in the cache, skipping
56.17.588.790 I slot process_sing: id  9 | task -1 | saving idle slot to prompt cache
56.17.590.559 W srv   prompt_save:  - saving prompt with length 1230, total state size = 180.237 MiB (draft: 0.000 MiB)
56.17.590.566 I srv         alloc:  - prompt is already in the cache, skipping
56.17.590.616 I slot update_slots: id  3 | task 5338 | Checking checkpoint with [73367, 74902] against 40678...
56.17.590.616 I slot update_slots: id  3 | task 5338 | Checking checkpoint with [72855, 74390] against 40678...
56.17.590.617 I slot update_slots: id  3 | task 5338 | Checking checkpoint with [69450, 70985] against 40678...
56.17.590.618 I slot update_slots: id  3 | task 5338 | Checking checkpoint with [68938, 70473] against 40678...
56.17.590.618 I slot update_slots: id  3 | task 5338 | Checking checkpoint with [45702, 47237] against 40678...
56.17.590.619 I slot update_slots: id  3 | task 5338 | Checking checkpoint with [40060, 41594] against 40678...
56.17.595.699 W slot update_slots: id  3 | task 5338 | restored context checkpoint (pos_min = 40060, pos_max = 41594, n_tokens = 41595, n_past = 41594, size = 170.013 MiB)
56.17.595.717 W slot update_slots: id  3 | task 5338 | erased invalidated context checkpoint (pos_min = 45702, pos_max = 47237, n_tokens = 47238, n_swa = 1024, pos_next = 41594, size = 170.013 MiB)
56.17.609.648 W slot update_slots: id  3 | task 5338 | erased invalidated context checkpoint (pos_min = 68938, pos_max = 70473, n_tokens = 70474, n_swa = 1024, pos_next = 41594, size = 170.013 MiB)
56.17.624.312 W slot update_slots: id  3 | task 5338 | erased invalidated context checkpoint (pos_min = 69450, pos_max = 70985, n_tokens = 70986, n_swa = 1024, pos_next = 41594, size = 170.013 MiB)
56.17.637.517 W slot update_slots: id  3 | task 5338 | erased invalidated context checkpoint (pos_min = 72855, pos_max = 74390, n_tokens = 74391, n_swa = 1024, pos_next = 41594, size = 170.013 MiB)
56.17.655.875 W slot update_slots: id  3 | task 5338 | erased invalidated context checkpoint (pos_min = 73367, pos_max = 74902, n_tokens = 74903, n_swa = 1024, pos_next = 41594, size = 170.013 MiB)
56.21.608.546 I slot print_timing: id  3 | task 5338 | prompt processing, n_tokens =   4096, progress = 0.62, t =   4.02 s / 1019.42 tokens per second
56.23.621.151 I slot print_timing: id  3 | task 5338 | prompt processing, n_tokens =   6144, progress = 0.64, t =   6.03 s / 1018.81 tokens per second
56.25.670.814 I slot print_timing: id  3 | task 5338 | prompt processing, n_tokens =   8192, progress = 0.67, t =   8.08 s / 1013.83 tokens per second
56.27.764.426 I slot print_timing: id  3 | task 5338 | prompt processing, n_tokens =  10240, progress = 0.70, t =  10.17 s / 1006.50 tokens per second
56.29.894.093 I slot print_timing: id  3 | task 5338 | prompt processing, n_tokens =  12288, progress = 0.73, t =  12.30 s / 998.74 tokens per second
56.32.036.650 I slot print_timing: id  3 | task 5338 | prompt processing, n_tokens =  14336, progress = 0.75, t =  14.45 s / 992.38 tokens per second
56.34.205.970 I slot print_timing: id  3 | task 5338 | prompt processing, n_tokens =  16384, progress = 0.78, t =  16.62 s / 986.07 tokens per second
56.36.413.479 I slot print_timing: id  3 | task 5338 | prompt processing, n_tokens =  18432, progress = 0.81, t =  18.82 s / 979.23 tokens per second
56.38.661.717 I slot print_timing: id  3 | task 5338 | prompt processing, n_tokens =  20480, progress = 0.84, t =  21.07 s / 971.95 tokens per second
56.40.938.162 I slot print_timing: id  3 | task 5338 | prompt processing, n_tokens =  22528, progress = 0.86, t =  23.35 s / 964.90 tokens per second
56.43.251.130 I slot print_timing: id  3 | task 5338 | prompt processing, n_tokens =  24576, progress = 0.89, t =  25.66 s / 957.73 tokens per second
56.45.614.154 I slot print_timing: id  3 | task 5338 | prompt processing, n_tokens =  26624, progress = 0.92, t =  28.02 s / 950.06 tokens per second
56.48.004.212 I slot print_timing: id  3 | task 5338 | prompt processing, n_tokens =  28672, progress = 0.95, t =  30.41 s / 942.74 tokens per second
56.50.417.617 I slot print_timing: id  3 | task 5338 | prompt processing, n_tokens =  30720, progress = 0.97, t =  32.83 s / 935.81 tokens per second
56.52.154.033 I slot print_timing: id  3 | task 5338 | prompt processing, n_tokens =  32150, progress = 0.99, t =  34.56 s / 930.17 tokens per second
56.52.699.294 I slot print_timing: id  3 | task 5338 | prompt processing, n_tokens =  32598, progress = 1.00, t =  35.11 s / 928.49 tokens per second
56.52.741.887 I slot create_check: id  3 | task 5338 | created context checkpoint 8 of 32 (pos_min = 72661, pos_max = 74191, n_tokens = 74192, size = 170.013 MiB)
56.52.864.225 I slot print_timing: id  3 | task 5338 | prompt processing, n_tokens =  32662, progress = 1.00, t =  35.27 s / 925.96 tokens per second
56.53.032.821 I reasoning-budget: activated, budget=2147483647 tokens
56.53.033.272 I reasoning-budget: deactivated (natural end)
56.54.847.460 I slot print_timing: id  3 | task 5338 | n_decoded =    100, tg =  52.43 t/s
56.57.895.861 I slot print_timing: id  3 | task 5338 | n_decoded =    244, tg =  49.24 t/s
57.00.943.573 I slot print_timing: id  3 | task 5338 | n_decoded =    387, tg =  48.36 t/s
57.04.016.980 I slot print_timing: id  3 | task 5338 | n_decoded =    548, tg =  49.47 t/s
57.07.082.455 I slot print_timing: id  3 | task 5338 | n_decoded =    699, tg =  49.43 t/s
57.10.148.570 I slot print_timing: id  3 | task 5338 | n_decoded =    854, tg =  49.63 t/s
57.13.208.767 I slot print_timing: id  3 | task 5338 | n_decoded =    998, tg =  49.24 t/s
57.16.280.941 I slot print_timing: id  3 | task 5338 | n_decoded =   1141, tg =  48.88 t/s
57.19.364.981 I slot print_timing: id  3 | task 5338 | n_decoded =   1298, tg =  49.12 t/s
57.22.380.360 I slot print_timing: id  3 | task 5338 | n_decoded =   1445, tg =  49.08 t/s
57.25.392.168 I slot print_timing: id  3 | task 5338 | n_decoded =   1583, tg =  48.78 t/s
57.28.440.465 I slot print_timing: id  3 | task 5338 | n_decoded =   1736, tg =  48.90 t/s
57.31.490.283 I slot print_timing: id  3 | task 5338 | n_decoded =   1880, tg =  48.77 t/s
57.32.317.525 W srv          stop: cancel task, id_task = 5338
57.32.403.714 I slot      release: id  3 | task 5338 | stop processing: n_tokens = 76185, truncated = 0
57.32.403.742 I srv  update_slots: all slots are idle
```
