# Docker Compose Configuration
```yaml
services:
  gemma-4-12b-server:
    # Official multi-arch image with CUDA 13 support for AMD64.
    image: ghcr.io/ggml-org/llama.cpp:server-cuda13
    container_name: gemma-4-12b-5090
    hostname: inference-server
    platform: linux/amd64
    # All models served on port 8000. Single-model capacity avoids client port mismatches.
    ports:
      - "${INFERENCE_SERVER_PORT:-8000}:8000"

    volumes:
      # Central workstation cache to avoid redundant downloads.
      - ~/.cache/huggingface:/root/.cache/huggingface
      # Shared memory for high-speed KV cache paging.
      - /dev/shm:/dev/shm

    # 32GB shm_size matches RTX 5090 VRAM; crucial for large context windows (256k).
    shm_size: "32g"
    ipc: host

    deploy:
      resources:
        reservations:
          devices:
            - capabilities: [gpu]

    environment:
      - CUDA_VISIBLE_DEVICES=0
      # Critical: Forces the container to use Blackwell-optimized libraries.
      - LD_LIBRARY_PATH=/usr/local/cuda-12.8/lib64
      - HF_HOME=/root/.cache/huggingface
      - NVIDIA_VISIBLE_DEVICES=0
    command:
      # Model: Gemma 4 12B Unified quantization (UD-Q4_K_XL) by Unsloth.
      # Encoder-free architecture — vision and audio baked into the model itself.
      - "-hf"
      - "unsloth/gemma-4-12b-it-GGUF:UD-Q4_K_XL"

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

      # Load the full graph into GPU VRAM.
      - "--n-gpu-layers"
      - "999"

      # Forces the OS to lock/pin memory footprint, preventing paging on RTX 5090.
      - "--mlock"

      # Native FlashAttention-2 acceleration for deep context layers.
      - "--flash-attn"
      - "on"

      # Q8_0 KV-cache: High precision (8-bit) to avoid logic errors in long contexts.
      - "--cache-type-k"
      - "q8_0"
      - "--cache-type-v"
      - "q8_0"

      # 256K context — Gemma 4 12B's native max context length, fits in 32GB VRAM.
      - "--ctx-size"
      - "262144"

      # Required for Gemma 4 chat template and native thinking token handling.
      - "--jinja"

      # Single concurrent slot — RTX 5090 has 32GB VRAM, optimized for one heavy session.
      - "--parallel"
      - "1"

      # --- THREADING OPTIMIZATION ---
      # 12 threads for single-token generation (lean, CPU cache friendly).
      # 24 threads for batch verification bursts using SMT cores.
      - "--threads"
      - "12"
      - "--threads-batch"
      - "24"

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

# vllm log
```
warn: LLAMA_ARG_HOST environment variable is set, but will be overwritten by command line argument --host
0.00.688.409 I log_info: verbosity = 3 (adjust with the `-lv N` CLI arg)
0.00.688.440 I device_info:
0.00.985.703 I   - CUDA0   : NVIDIA GeForce RTX 5090 (32606 MiB, 30930 MiB free)
0.00.985.736 I   - CPU     : AMD Ryzen 9 5950X 16-Core Processor (64297 MiB, 64297 MiB free)
0.00.985.834 I system_info: n_threads = 12 (n_threads_batch = 24) / 32 | CUDA : ARCHS = 750,800,860,890,900,1200,1210 | USE_GRAPHS = 1 | PEER_MAX_BATCH_SIZE = 128 | BLACKWELL_NATIVE_FP4 = 1 | CPU : SSE3 = 1 | SSSE3 = 1 | AVX = 1 | AVX2 = 1 | F16C = 1 | FMA = 1 | BMI2 = 1 | LLAMAFILE = 1 | OPENMP = 1 | REPACK = 1 | 
0.00.985.952 I srv          init: running without SSL
0.00.985.972 I srv          init: api_keys: ****-key
0.00.986.008 I srv          init: using 31 threads for HTTP server
0.00.986.117 I srv         start: binding port with default address family
0.00.988.235 I srv  llama_server: loading model
0.00.988.279 I srv    load_model: loading model '/root/.cache/huggingface/hub/models--unsloth--gemma-4-12b-it-GGUF/snapshots/3f09de26549e6d7ea54f1b83755149f840fcd333/gemma-4-12b-it-UD-Q4_K_XL.gguf'
0.01.219.340 I srv    load_model: [mtmd] estimated worst-case memory usage of mmproj is 354.46 MiB
0.01.219.383 I common_init_result: fitting params to device memory ...
0.01.219.384 I common_init_result: (for bugs during this step try to reproduce them with -fit off, or provide --verbose logs if the bug only occurs with -fit on)
0.02.352.598 W load: control-looking token:    212 '</s>' was not control-type; this is probably a bug in the model. its type will be overridden
0.02.353.195 W load: control-looking token:     50 '<|tool_response>' was not control-type; this is probably a bug in the model. its type will be overridden
0.02.361.079 W load: control-looking token:      1 '<eos>' was not control-type; this is probably a bug in the model. its type will be overridden
0.02.386.955 W load: special_eog_ids contains '<|tool_response>', removing '</s>' token from EOG list
0.04.051.005 I common_init_from_params: warming up the model with an empty run - please wait ... (--no-warmup to disable)
0.04.351.940 W init_audio: audio input is in experimental stage and may have reduced quality:
    https://github.com/ggml-org/llama.cpp/discussions/13759
0.04.351.968 I srv    load_model: loaded multimodal model, '/root/.cache/huggingface/hub/models--unsloth--gemma-4-12b-it-GGUF/snapshots/3f09de26549e6d7ea54f1b83755149f840fcd333/mmproj-BF16.gguf'
0.04.351.984 I srv    load_model: initializing slots, n_slots = 1
0.04.384.019 W common_speculative_init: no implementations specified for speculative decoding
0.04.384.048 I slot   load_model: id  0 | task -1 | new slot, n_ctx = 262144
0.04.384.165 I srv    load_model: prompt cache is enabled, size limit: 8192 MiB
0.04.384.184 I srv    load_model: use `--cache-ram 0` to disable the prompt cache
0.04.384.185 I srv    load_model: for more info see https://github.com/ggml-org/llama.cpp/pull/16391
0.04.384.185 I srv    load_model: context checkpoints enabled, max = 32, min spacing = 256
0.04.384.207 W srv          init: --cache-idle-slots requires --kv-unified, disabling
0.04.390.536 I init: chat template, example_format: '<|turn>system
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
0.04.391.169 I srv          init: init: chat template, thinking = 1
0.04.391.228 I srv  llama_server: model loaded
0.04.391.233 I srv  llama_server: server is listening on http://0.0.0.0:8000
0.04.391.239 I srv  update_slots: all slots are idle
0.18.982.806 I srv  params_from_: Chat format: peg-gemma4
0.19.014.747 I slot get_availabl: id  0 | task -1 | selected slot by LRU, t_last = -1
0.19.014.776 I srv  get_availabl: updating prompt cache
0.19.014.784 I srv          load:  - looking for better prompt, base f_keep = -1.000, sim = 0.000
0.19.014.789 I srv        update:  - cache state: 0 prompts, 0.000 MiB (limits: 8192.000 MiB, 262144 tokens, 8589934592 est)
0.19.014.790 I srv  get_availabl: prompt cache update took 0.01 ms
0.19.014.997 I slot launch_slot_: id  0 | task 0 | processing task, is_child = 0
0.20.022.008 I slot create_check: id  0 | task 0 | created context checkpoint 1 of 32 (pos_min = 6219, pos_max = 7754, n_tokens = 7755, size = 170.013 MiB)
0.20.139.691 I reasoning-budget: activated, budget=2147483647 tokens
0.21.089.302 I reasoning-budget: deactivated (natural end)
0.21.223.794 I slot print_timing: id  0 | task 0 | n_decoded =    100, tg =  89.73 t/s
0.21.234.959 I slot print_timing: id  0 | task 0 | prompt eval time =    1510.69 ms /  7772 tokens (    0.19 ms per token,  5144.67 tokens per second)
0.21.234.984 I slot print_timing: id  0 | task 0 |        eval time =    1125.59 ms /   101 tokens (   11.14 ms per token,    89.73 tokens per second)
0.21.234.985 I slot print_timing: id  0 | task 0 |       total time =    2636.28 ms /  7873 tokens
0.21.234.992 I slot print_timing: id  0 | task 0 |    graphs reused =          0
0.21.235.607 I slot      release: id  0 | task 0 | stop processing: n_tokens = 7872, truncated = 0
0.21.235.639 I srv  update_slots: all slots are idle
1.18.911.488 I srv  params_from_: Chat format: peg-gemma4
1.18.943.315 I slot get_availabl: id  0 | task -1 | selected slot by LCP similarity, sim_best = 0.990 (> 0.100 thold), f_keep = 0.987
1.18.943.512 I slot launch_slot_: id  0 | task 108 | processing task, is_child = 0
1.18.852.088 I reasoning-budget: activated, budget=2147483647 tokens
1.19.926.695 I slot print_timing: id  0 | task 108 | n_decoded =    100, tg =  90.04 t/s
1.21.176.561 I reasoning-budget: deactivated (natural end)
1.21.386.723 I slot print_timing: id  0 | task 108 | prompt eval time =     289.29 ms /    76 tokens (    3.81 ms per token,   262.71 tokens per second)
1.21.386.745 I slot print_timing: id  0 | task 108 |        eval time =    2570.63 ms /   233 tokens (   11.03 ms per token,    90.64 tokens per second)
1.21.386.746 I slot print_timing: id  0 | task 108 |       total time =    2859.91 ms /   309 tokens
1.21.386.747 I slot print_timing: id  0 | task 108 |    graphs reused =          0
1.21.387.288 I slot      release: id  0 | task 108 | stop processing: n_tokens = 8080, truncated = 0
1.21.387.330 I srv  update_slots: all slots are idle
1.22.014.242 I srv  params_from_: Chat format: peg-gemma4
1.22.037.058 I slot get_availabl: id  0 | task -1 | selected slot by LCP similarity, sim_best = 0.730 (> 0.100 thold), f_keep = 0.998
1.22.037.240 I slot launch_slot_: id  0 | task 344 | processing task, is_child = 0
1.22.587.329 I slot create_check: id  0 | task 344 | created context checkpoint 2 of 32 (pos_min = 8984, pos_max = 10519, n_tokens = 10520, size = 170.013 MiB)
1.22.837.472 I slot create_check: id  0 | task 344 | created context checkpoint 3 of 32 (pos_min = 9496, pos_max = 11031, n_tokens = 11032, size = 170.013 MiB)
1.22.882.442 I reasoning-budget: activated, budget=2147483647 tokens
1.23.962.841 I slot print_timing: id  0 | task 344 | n_decoded =    100, tg =  90.91 t/s
1.24.044.016 I reasoning-budget: deactivated (natural end)
1.24.836.214 I slot print_timing: id  0 | task 344 | prompt eval time =     825.58 ms /  2975 tokens (    0.28 ms per token,  3603.53 tokens per second)
1.24.836.237 I slot print_timing: id  0 | task 344 |        eval time =    2390.46 ms /   218 tokens (   10.97 ms per token,    91.20 tokens per second)
1.24.836.238 I slot print_timing: id  0 | task 344 |       total time =    3216.04 ms /  3193 tokens
1.24.836.239 I slot print_timing: id  0 | task 344 |    graphs reused =          0
1.24.836.871 I slot      release: id  0 | task 344 | stop processing: n_tokens = 11253, truncated = 0
1.24.836.911 I srv  update_slots: all slots are idle
7.11.008.965 I srv  params_from_: Chat format: peg-gemma4
7.11.034.848 I slot get_availabl: id  0 | task -1 | selected slot by LCP similarity, sim_best = 0.715 (> 0.100 thold), f_keep = 0.697
7.11.035.037 I slot launch_slot_: id  0 | task 566 | processing task, is_child = 0
7.11.035.076 I slot update_slots: id  0 | task 566 | Checking checkpoint with [9496, 11031] against 6823...
7.11.035.077 I slot update_slots: id  0 | task 566 | Checking checkpoint with [8984, 10519] against 6823...
7.11.035.078 I slot update_slots: id  0 | task 566 | Checking checkpoint with [6219, 7754] against 6823...
7.11.107.969 W slot update_slots: id  0 | task 566 | restored context checkpoint (pos_min = 6219, pos_max = 7754, n_tokens = 7755, n_past = 7754, size = 170.013 MiB)
7.11.107.994 W slot update_slots: id  0 | task 566 | erased invalidated context checkpoint (pos_min = 8984, pos_max = 10519, n_tokens = 10520, n_swa = 1024, pos_next = 7754, size = 170.013 MiB)
7.11.118.531 W slot update_slots: id  0 | task 566 | erased invalidated context checkpoint (pos_min = 9496, pos_max = 11031, n_tokens = 11032, n_swa = 1024, pos_next = 7754, size = 170.013 MiB)
7.11.855.099 I slot create_check: id  0 | task 566 | created context checkpoint 2 of 32 (pos_min = 9433, pos_max = 10893, n_tokens = 10894, size = 170.013 MiB)
7.11.940.039 I reasoning-budget: activated, budget=2147483647 tokens
7.13.046.876 I slot print_timing: id  0 | task 566 | n_decoded =    100, tg =  88.81 t/s
7.13.662.235 I reasoning-budget: deactivated (natural end)
7.14.422.550 I slot print_timing: id  0 | task 566 | prompt eval time =     885.80 ms /  3219 tokens (    0.28 ms per token,  3633.99 tokens per second)
7.14.422.573 I slot print_timing: id  0 | task 566 |        eval time =    2501.63 ms /   222 tokens (   11.27 ms per token,    88.74 tokens per second)
7.14.422.574 I slot print_timing: id  0 | task 566 |       total time =    3387.43 ms /  3441 tokens
7.14.422.575 I slot print_timing: id  0 | task 566 |    graphs reused =          0
7.14.423.323 I slot      release: id  0 | task 566 | stop processing: n_tokens = 11194, truncated = 0
7.14.423.374 I srv  update_slots: all slots are idle
7.14.684.542 I srv  params_from_: Chat format: peg-gemma4
7.14.711.271 I slot get_availabl: id  0 | task -1 | selected slot by LCP similarity, sim_best = 0.990 (> 0.100 thold), f_keep = 0.994
7.14.711.440 I slot launch_slot_: id  0 | task 793 | processing task, is_child = 0
7.14.941.088 I slot create_check: id  0 | task 793 | created context checkpoint 3 of 32 (pos_min = 9836, pos_max = 11234, n_tokens = 11235, size = 170.013 MiB)
7.14.984.994 I reasoning-budget: activated, budget=2147483647 tokens
7.15.570.984 I reasoning-budget: deactivated (natural end)
7.15.695.857 I slot print_timing: id  0 | task 793 | n_decoded =    100, tg =  87.11 t/s
7.16.269.333 I slot print_timing: id  0 | task 793 | prompt eval time =     253.62 ms /   112 tokens (    2.26 ms per token,   441.61 tokens per second)
7.16.269.356 I slot print_timing: id  0 | task 793 |        eval time =    1721.39 ms /   150 tokens (   11.48 ms per token,    87.14 tokens per second)
7.16.269.357 I slot print_timing: id  0 | task 793 |       total time =    1975.01 ms /   262 tokens
7.16.269.357 I slot print_timing: id  0 | task 793 |    graphs reused =          0
7.16.269.979 I slot      release: id  0 | task 793 | stop processing: n_tokens = 11388, truncated = 0
7.16.270.020 I srv  update_slots: all slots are idle
7.16.443.407 I srv  params_from_: Chat format: peg-gemma4
7.16.469.877 I slot get_availabl: id  0 | task -1 | selected slot by LCP similarity, sim_best = 0.991 (> 0.100 thold), f_keep = 0.995
7.16.470.038 I slot launch_slot_: id  0 | task 945 | processing task, is_child = 0
7.16.551.237 I reasoning-budget: activated, budget=2147483647 tokens
7.16.791.868 I reasoning-budget: deactivated (natural end)
7.17.088.842 I slot print_timing: id  0 | task 945 | prompt eval time =      59.35 ms /   106 tokens (    0.56 ms per token,  1785.99 tokens per second)
7.17.088.864 I slot print_timing: id  0 | task 945 |        eval time =     559.38 ms /    49 tokens (   11.42 ms per token,    87.60 tokens per second)
7.17.088.864 I slot print_timing: id  0 | task 945 |       total time =     618.73 ms /   155 tokens
7.17.088.865 I slot print_timing: id  0 | task 945 |    graphs reused =          0
7.17.089.487 I slot      release: id  0 | task 945 | stop processing: n_tokens = 11480, truncated = 0
7.17.089.525 I srv  update_slots: all slots are idle
7.17.265.685 I srv  params_from_: Chat format: peg-gemma4
7.17.293.291 I slot get_availabl: id  0 | task -1 | selected slot by LCP similarity, sim_best = 0.983 (> 0.100 thold), f_keep = 0.998
7.17.293.476 I slot launch_slot_: id  0 | task 996 | processing task, is_child = 0
7.17.538.641 I slot create_check: id  0 | task 996 | created context checkpoint 4 of 32 (pos_min = 10248, pos_max = 11646, n_tokens = 11647, size = 170.013 MiB)
7.17.591.582 I reasoning-budget: activated, budget=2147483647 tokens
7.17.956.925 I reasoning-budget: deactivated (natural end)
7.18.115.021 I slot print_timing: id  0 | task 996 | prompt eval time =     277.76 ms /   197 tokens (    1.41 ms per token,   709.24 tokens per second)
7.18.115.041 I slot print_timing: id  0 | task 996 |        eval time =     813.46 ms /    70 tokens (   11.62 ms per token,    86.05 tokens per second)
7.18.115.042 I slot print_timing: id  0 | task 996 |       total time =    1091.23 ms /   267 tokens
7.18.115.043 I slot print_timing: id  0 | task 996 |    graphs reused =          0
7.18.115.695 I slot      release: id  0 | task 996 | stop processing: n_tokens = 11720, truncated = 0
7.18.115.736 I srv  update_slots: all slots are idle
7.18.342.094 I srv  params_from_: Chat format: peg-gemma4
7.18.369.379 I slot get_availabl: id  0 | task -1 | selected slot by LCP similarity, sim_best = 0.939 (> 0.100 thold), f_keep = 0.999
7.18.369.542 I slot launch_slot_: id  0 | task 1068 | processing task, is_child = 0
7.18.595.194 I slot create_check: id  0 | task 1068 | created context checkpoint 5 of 32 (pos_min = 10553, pos_max = 11951, n_tokens = 11952, size = 170.013 MiB)
7.18.847.440 I slot create_check: id  0 | task 1068 | created context checkpoint 6 of 32 (pos_min = 10929, pos_max = 12463, n_tokens = 12464, size = 170.013 MiB)
7.18.890.873 I reasoning-budget: activated, budget=2147483647 tokens
7.19.613.601 I reasoning-budget: deactivated (natural end)
7.19.881.735 I slot print_timing: id  0 | task 1068 | n_decoded =    100, tg =  86.37 t/s
7.20.065.272 I slot print_timing: id  0 | task 1068 | prompt eval time =     501.44 ms /   763 tokens (    0.66 ms per token,  1521.61 tokens per second)
7.20.065.296 I slot print_timing: id  0 | task 1068 |        eval time =    1341.29 ms /   116 tokens (   11.56 ms per token,    86.48 tokens per second)
7.20.065.296 I slot print_timing: id  0 | task 1068 |       total time =    1842.74 ms /   879 tokens
7.20.065.298 I slot print_timing: id  0 | task 1068 |    graphs reused =          0
7.20.065.960 I slot      release: id  0 | task 1068 | stop processing: n_tokens = 12583, truncated = 0
7.20.065.999 I srv  update_slots: all slots are idle
7.20.247.461 I srv  params_from_: Chat format: peg-gemma4
7.20.273.949 I slot get_availabl: id  0 | task -1 | selected slot by LCP similarity, sim_best = 0.890 (> 0.100 thold), f_keep = 0.996
7.20.274.114 I slot launch_slot_: id  0 | task 1187 | processing task, is_child = 0
7.20.681.097 I slot create_check: id  0 | task 1187 | created context checkpoint 7 of 32 (pos_min = 12023, pos_max = 13558, n_tokens = 13559, size = 170.013 MiB)
7.20.943.334 I slot create_check: id  0 | task 1187 | created context checkpoint 8 of 32 (pos_min = 12535, pos_max = 14070, n_tokens = 14071, size = 170.013 MiB)
7.20.987.890 I reasoning-budget: activated, budget=2147483647 tokens
7.22.887.379 I slot print_timing: id  0 | task 1187 | n_decoded =    168, tg =  87.54 t/s
7.23.052.181 I reasoning-budget: deactivated (natural end)
7.23.839.704 I slot print_timing: id  0 | task 1187 | prompt eval time =     694.01 ms /  1544 tokens (    0.45 ms per token,  2224.76 tokens per second)
7.23.839.724 I slot print_timing: id  0 | task 1187 |        eval time =    2871.51 ms /   250 tokens (   11.49 ms per token,    87.06 tokens per second)
7.23.839.725 I slot print_timing: id  0 | task 1187 |       total time =    3565.52 ms /  1794 tokens
7.23.839.726 I slot print_timing: id  0 | task 1187 |    graphs reused =          0
7.23.840.447 I slot      release: id  0 | task 1187 | stop processing: n_tokens = 14324, truncated = 0
7.23.840.489 I srv  update_slots: all slots are idle
9.31.255.718 I srv  params_from_: Chat format: peg-gemma4
9.31.286.953 I slot get_availabl: id  0 | task -1 | selected slot by LCP similarity, sim_best = 0.597 (> 0.100 thold), f_keep = 0.766
9.31.287.148 I slot launch_slot_: id  0 | task 1440 | processing task, is_child = 0
9.31.287.186 I slot update_slots: id  0 | task 1440 | Checking checkpoint with [12535, 14070] against 9948...
9.31.287.187 I slot update_slots: id  0 | task 1440 | Checking checkpoint with [12023, 13558] against 9948...
9.31.287.187 I slot update_slots: id  0 | task 1440 | Checking checkpoint with [10929, 12463] against 9948...
9.31.287.188 I slot update_slots: id  0 | task 1440 | Checking checkpoint with [10553, 11951] against 9948...
9.31.287.189 I slot update_slots: id  0 | task 1440 | Checking checkpoint with [10248, 11646] against 9948...
9.31.287.190 I slot update_slots: id  0 | task 1440 | Checking checkpoint with [9836, 11234] against 9948...
9.31.330.258 W slot update_slots: id  0 | task 1440 | restored context checkpoint (pos_min = 9836, pos_max = 11234, n_tokens = 11235, n_past = 10973, size = 170.013 MiB)
9.31.330.281 W slot update_slots: id  0 | task 1440 | erased invalidated context checkpoint (pos_min = 9836, pos_max = 11234, n_tokens = 11235, n_swa = 1024, pos_next = 10973, size = 170.013 MiB)
9.31.341.421 W slot update_slots: id  0 | task 1440 | erased invalidated context checkpoint (pos_min = 10248, pos_max = 11646, n_tokens = 11647, n_swa = 1024, pos_next = 10973, size = 170.013 MiB)
9.31.352.337 W slot update_slots: id  0 | task 1440 | erased invalidated context checkpoint (pos_min = 10553, pos_max = 11951, n_tokens = 11952, n_swa = 1024, pos_next = 10973, size = 170.013 MiB)
9.31.363.899 W slot update_slots: id  0 | task 1440 | erased invalidated context checkpoint (pos_min = 10929, pos_max = 12463, n_tokens = 12464, n_swa = 1024, pos_next = 10973, size = 170.013 MiB)
9.31.374.874 W slot update_slots: id  0 | task 1440 | erased invalidated context checkpoint (pos_min = 12023, pos_max = 13558, n_tokens = 13559, n_swa = 1024, pos_next = 10973, size = 170.013 MiB)
9.31.386.000 W slot update_slots: id  0 | task 1440 | erased invalidated context checkpoint (pos_min = 12535, pos_max = 14070, n_tokens = 14071, n_swa = 1024, pos_next = 10973, size = 170.013 MiB)
9.32.074.494 I slot create_check: id  0 | task 1440 | created context checkpoint 3 of 32 (pos_min = 12218, pos_max = 13753, n_tokens = 13754, size = 170.013 MiB)
9.32.937.064 I slot create_check: id  0 | task 1440 | created context checkpoint 4 of 32 (pos_min = 16338, pos_max = 17873, n_tokens = 17874, size = 170.013 MiB)
9.33.196.940 I slot create_check: id  0 | task 1440 | created context checkpoint 5 of 32 (pos_min = 16851, pos_max = 18385, n_tokens = 18386, size = 170.013 MiB)
9.33.244.460 I reasoning-budget: activated, budget=2147483647 tokens
9.34.380.730 I slot print_timing: id  0 | task 1440 | n_decoded =    100, tg =  86.34 t/s
9.36.882.618 I slot print_timing: id  0 | task 1440 | n_decoded =    357, tg =  85.69 t/s
9.38.629.189 I reasoning-budget: deactivated (natural end)
9.39.745.871 I slot print_timing: id  0 | task 1440 | prompt eval time =    1935.35 ms /  7417 tokens (    0.26 ms per token,  3832.39 tokens per second)
9.39.745.893 I slot print_timing: id  0 | task 1440 |        eval time =    7029.50 ms /   602 tokens (   11.68 ms per token,    85.64 tokens per second)
9.39.745.894 I slot print_timing: id  0 | task 1440 |       total time =    8964.85 ms /  8019 tokens
9.39.745.895 I slot print_timing: id  0 | task 1440 |    graphs reused =          0
9.39.746.836 I slot      release: id  0 | task 1440 | stop processing: n_tokens = 18991, truncated = 0
9.39.746.881 I srv  update_slots: all slots are idle
35.54.170.980 I srv  params_from_: Chat format: peg-gemma4
35.54.213.420 I slot get_availabl: id  0 | task -1 | selected slot by LCP similarity, sim_best = 0.994 (> 0.100 thold), f_keep = 0.968
35.54.213.658 I slot launch_slot_: id  0 | task 2049 | processing task, is_child = 0
35.54.213.709 I slot update_slots: id  0 | task 2049 | Checking checkpoint with [16851, 18385] against 17365...
35.54.276.891 W slot update_slots: id  0 | task 2049 | restored context checkpoint (pos_min = 16851, pos_max = 18385, n_tokens = 18386, n_past = 18385, size = 170.013 MiB)
35.54.561.887 I reasoning-budget: activated, budget=2147483647 tokens
35.55.552.331 I reasoning-budget: deactivated (natural end)
35.55.574.032 I reasoning-budget: re-activated on new start tag, budget=2147483647 tokens
35.55.595.682 I reasoning-budget: deactivated (natural end)
35.55.660.323 I slot print_timing: id  0 | task 2049 | n_decoded =    100, tg =  89.47 t/s
35.55.914.121 I slot print_timing: id  0 | task 2049 | prompt eval time =     328.90 ms /   119 tokens (    2.76 ms per token,   361.81 tokens per second)
35.55.914.140 I slot print_timing: id  0 | task 2049 |        eval time =    1371.49 ms /   123 tokens (   11.15 ms per token,    89.68 tokens per second)
35.55.914.141 I slot print_timing: id  0 | task 2049 |       total time =    1700.39 ms /   242 tokens
35.55.914.142 I slot print_timing: id  0 | task 2049 |    graphs reused =          0
35.55.915.233 I slot      release: id  0 | task 2049 | stop processing: n_tokens = 18626, truncated = 0
35.55.915.277 I srv  update_slots: all slots are idle
35.56.138.502 I srv  params_from_: Chat format: peg-gemma4
35.56.176.478 I slot get_availabl: id  0 | task -1 | selected slot by LCP similarity, sim_best = 0.983 (> 0.100 thold), f_keep = 0.998
35.56.176.662 I slot launch_slot_: id  0 | task 2175 | processing task, is_child = 0
35.56.424.593 I slot create_check: id  0 | task 2175 | created context checkpoint 6 of 32 (pos_min = 17541, pos_max = 18916, n_tokens = 18917, size = 170.013 MiB)
35.56.467.739 I reasoning-budget: activated, budget=2147483647 tokens
35.57.872.436 I reasoning-budget: deactivated (natural end)
35.58.249.977 I slot print_timing: id  0 | task 2175 | n_decoded =    200, tg =  90.15 t/s
35.58.316.676 I slot print_timing: id  0 | task 2175 | prompt eval time =     271.62 ms /   328 tokens (    0.83 ms per token,  1207.59 tokens per second)
35.58.316.698 I slot print_timing: id  0 | task 2175 |        eval time =    2285.30 ms /   206 tokens (   11.09 ms per token,    90.14 tokens per second)
35.58.316.698 I slot print_timing: id  0 | task 2175 |       total time =    2556.92 ms /   534 tokens
35.58.316.699 I slot print_timing: id  0 | task 2175 |    graphs reused =          0
35.58.317.671 I slot      release: id  0 | task 2175 | stop processing: n_tokens = 19126, truncated = 0
35.58.317.717 I srv  update_slots: all slots are idle
35.58.626.651 I srv  params_from_: Chat format: peg-gemma4
35.58.664.982 I slot get_availabl: id  0 | task -1 | selected slot by LCP similarity, sim_best = 0.495 (> 0.100 thold), f_keep = 0.998
35.58.665.159 I slot launch_slot_: id  0 | task 2383 | processing task, is_child = 0
36.01.688.197 I slot print_timing: id  0 | task 2383 | prompt processing, n_tokens =  16384, progress = 0.92, t =   3.02 s / 5419.79 tokens per second
36.02.107.934 I slot print_timing: id  0 | task 2383 | prompt processing, n_tokens =  18432, progress = 0.97, t =   3.44 s / 5353.88 tokens per second
36.02.287.738 I slot print_timing: id  0 | task 2383 | prompt processing, n_tokens =  18977, progress = 0.99, t =   3.62 s / 5238.59 tokens per second
36.02.501.658 I slot create_check: id  0 | task 2383 | created context checkpoint 7 of 32 (pos_min = 36527, pos_max = 38062, n_tokens = 38063, size = 170.013 MiB)
36.02.556.518 I slot print_timing: id  0 | task 2383 | prompt processing, n_tokens =  19489, progress = 1.00, t =   3.89 s / 5008.33 tokens per second
36.02.757.604 I slot create_check: id  0 | task 2383 | created context checkpoint 8 of 32 (pos_min = 37040, pos_max = 38574, n_tokens = 38575, size = 170.013 MiB)
36.21.171.119 I reasoning-budget: activated, budget=2147483647 tokens
36.03.557.103 I slot print_timing: id  0 | task 2383 | n_decoded =    100, tg =  83.43 t/s
36.03.956.885 I reasoning-budget: deactivated (natural end)
36.04.260.804 I slot print_timing: id  0 | task 2383 | prompt eval time =    4118.11 ms / 19493 tokens (    0.21 ms per token,  4733.48 tokens per second)
36.04.260.824 I slot print_timing: id  0 | task 2383 |        eval time =    1902.37 ms /   160 tokens (   11.89 ms per token,    84.11 tokens per second)
36.04.260.825 I slot print_timing: id  0 | task 2383 |       total time =    6020.49 ms / 19653 tokens
36.04.260.826 I slot print_timing: id  0 | task 2383 |    graphs reused =          0
36.04.262.378 I slot      release: id  0 | task 2383 | stop processing: n_tokens = 38738, truncated = 0
36.04.262.420 I srv  update_slots: all slots are idle
36.04.573.313 I srv  params_from_: Chat format: peg-gemma4
36.04.615.708 I slot get_availabl: id  0 | task -1 | selected slot by LCP similarity, sim_best = 0.998 (> 0.100 thold), f_keep = 0.999
36.04.615.896 I slot launch_slot_: id  0 | task 2555 | processing task, is_child = 0
36.04.695.146 I reasoning-budget: activated, budget=2147483647 tokens
36.05.116.580 I reasoning-budget: deactivated (natural end)
36.05.719.838 I slot print_timing: id  0 | task 2555 | prompt eval time =      58.36 ms /    59 tokens (    0.99 ms per token,  1011.00 tokens per second)
36.05.719.864 I slot print_timing: id  0 | task 2555 |        eval time =    1045.49 ms /    91 tokens (   11.49 ms per token,    87.04 tokens per second)
36.05.719.865 I slot print_timing: id  0 | task 2555 |       total time =    1103.85 ms /   150 tokens
36.05.719.867 I slot print_timing: id  0 | task 2555 |    graphs reused =          0
36.05.721.678 I slot      release: id  0 | task 2555 | stop processing: n_tokens = 38860, truncated = 0
36.05.721.704 I srv  update_slots: all slots are idle
36.05.998.795 I srv  params_from_: Chat format: peg-gemma4
36.06.037.834 I slot get_availabl: id  0 | task -1 | selected slot by LCP similarity, sim_best = 0.916 (> 0.100 thold), f_keep = 0.999
36.06.038.039 I slot launch_slot_: id  0 | task 2648 | processing task, is_child = 0
36.06.826.299 I slot create_check: id  0 | task 2648 | created context checkpoint 9 of 32 (pos_min = 40315, pos_max = 41850, n_tokens = 41851, size = 170.013 MiB)
36.07.095.076 I slot create_check: id  0 | task 2648 | created context checkpoint 10 of 32 (pos_min = 40827, pos_max = 42362, n_tokens = 42363, size = 170.013 MiB)
36.07.136.854 I reasoning-budget: activated, budget=2147483647 tokens
36.07.462.579 I reasoning-budget: deactivated (natural end)
36.07.409.582 I slot print_timing: id  0 | task 2648 | prompt eval time =    1080.29 ms /  3561 tokens (    0.30 ms per token,  3296.34 tokens per second)
36.07.409.602 I slot print_timing: id  0 | task 2648 |        eval time =     700.65 ms /    61 tokens (   11.49 ms per token,    87.06 tokens per second)
36.07.409.603 I slot print_timing: id  0 | task 2648 |       total time =    1780.94 ms /  3622 tokens
36.07.409.604 I slot print_timing: id  0 | task 2648 |    graphs reused =          0
36.07.411.290 I slot      release: id  0 | task 2648 | stop processing: n_tokens = 42427, truncated = 0
36.07.411.330 I srv  update_slots: all slots are idle
36.09.576.024 I srv  params_from_: Chat format: peg-gemma4
36.09.615.635 I slot get_availabl: id  0 | task -1 | selected slot by LCP similarity, sim_best = 0.998 (> 0.100 thold), f_keep = 0.999
36.09.615.841 I slot launch_slot_: id  0 | task 2713 | processing task, is_child = 0
36.09.708.222 I reasoning-budget: activated, budget=2147483647 tokens
36.09.891.516 I reasoning-budget: deactivated (natural end)
36.10.260.790 I slot print_timing: id  0 | task 2713 | prompt eval time =      67.95 ms /    77 tokens (    0.88 ms per token,  1133.24 tokens per second)
36.10.260.809 I slot print_timing: id  0 | task 2713 |        eval time =     576.94 ms /    42 tokens (   13.74 ms per token,    72.80 tokens per second)
36.10.260.810 I slot print_timing: id  0 | task 2713 |       total time =     644.88 ms /   119 tokens
36.10.260.811 I slot print_timing: id  0 | task 2713 |    graphs reused =          0
36.10.262.341 I slot      release: id  0 | task 2713 | stop processing: n_tokens = 42513, truncated = 0
36.10.262.383 I srv  update_slots: all slots are idle
36.26.008.253 I srv  params_from_: Chat format: peg-gemma4
36.26.074.190 I slot get_availabl: id  0 | task -1 | selected slot by LCP similarity, sim_best = 0.440 (> 0.100 thold), f_keep = 0.435
36.26.074.210 I srv  get_availabl: updating prompt cache
36.26.075.232 W srv   prompt_save:  - saving prompt with length 42513, total state size = 523.390 MiB (draft: 0.000 MiB)
36.28.208.905 I srv          load:  - looking for better prompt, base f_keep = 0.435, sim = 0.440
36.28.208.947 I srv        update:  - cache state: 1 prompts, 2223.517 MiB (limits: 8192.000 MiB, 262144 tokens, 262144 est)
36.28.208.951 I srv        update:    - prompt 0x58a7499534e0:   42513 tokens, checkpoints: 10,  2223.517 MiB
36.28.208.953 I srv  get_availabl: prompt cache update took 2634.80 ms
36.28.209.159 I slot launch_slot_: id  0 | task 2757 | processing task, is_child = 0
36.28.209.201 I slot update_slots: id  0 | task 2757 | Checking checkpoint with [40827, 42362] against 17479...
36.28.209.202 I slot update_slots: id  0 | task 2757 | Checking checkpoint with [40315, 41850] against 17479...
36.28.209.202 I slot update_slots: id  0 | task 2757 | Checking checkpoint with [37040, 38574] against 17479...
36.28.209.203 I slot update_slots: id  0 | task 2757 | Checking checkpoint with [36527, 38062] against 17479...
36.28.209.204 I slot update_slots: id  0 | task 2757 | Checking checkpoint with [17541, 18916] against 17479...
36.28.209.205 I slot update_slots: id  0 | task 2757 | Checking checkpoint with [16851, 18385] against 17479...
36.28.230.280 W slot update_slots: id  0 | task 2757 | restored context checkpoint (pos_min = 16851, pos_max = 18385, n_tokens = 18386, n_past = 18385, size = 170.013 MiB)
36.28.230.307 W slot update_slots: id  0 | task 2757 | erased invalidated context checkpoint (pos_min = 17541, pos_max = 18916, n_tokens = 18917, n_swa = 1024, pos_next = 18385, size = 170.013 MiB)
36.28.240.858 W slot update_slots: id  0 | task 2757 | erased invalidated context checkpoint (pos_min = 36527, pos_max = 38062, n_tokens = 38063, n_swa = 1024, pos_next = 18385, size = 170.013 MiB)
36.28.251.264 W slot update_slots: id  0 | task 2757 | erased invalidated context checkpoint (pos_min = 37040, pos_max = 38574, n_tokens = 38575, n_swa = 1024, pos_next = 18385, size = 170.013 MiB)
36.28.261.701 W slot update_slots: id  0 | task 2757 | erased invalidated context checkpoint (pos_min = 40315, pos_max = 41850, n_tokens = 41851, n_swa = 1024, pos_next = 18385, size = 170.013 MiB)
36.28.272.087 W slot update_slots: id  0 | task 2757 | erased invalidated context checkpoint (pos_min = 40827, pos_max = 42362, n_tokens = 42363, n_swa = 1024, pos_next = 18385, size = 170.013 MiB)
36.31.266.687 I slot print_timing: id  0 | task 2757 | prompt processing, n_tokens =  16384, progress = 0.83, t =   3.06 s / 5358.64 tokens per second
36.31.677.372 I slot print_timing: id  0 | task 2757 | prompt processing, n_tokens =  18432, progress = 0.88, t =   3.47 s / 5314.61 tokens per second
36.32.097.911 I slot print_timing: id  0 | task 2757 | prompt processing, n_tokens =  20480, progress = 0.92, t =   3.89 s / 5266.52 tokens per second
36.32.525.259 I slot print_timing: id  0 | task 2757 | prompt processing, n_tokens =  22528, progress = 0.97, t =   4.32 s / 5219.57 tokens per second
36.32.713.540 I slot print_timing: id  0 | task 2757 | prompt processing, n_tokens =  23159, progress = 0.99, t =   4.50 s / 5141.48 tokens per second
36.32.782.158 I slot print_timing: id  0 | task 2757 | prompt processing, n_tokens =  23658, progress = 1.00, t =   4.57 s / 5173.45 tokens per second
36.32.467.863 I slot create_check: id  0 | task 2757 | created context checkpoint 6 of 32 (pos_min = 40507, pos_max = 42042, n_tokens = 42043, size = 170.013 MiB)
36.32.489.128 I slot print_timing: id  0 | task 2757 | prompt processing, n_tokens =  23671, progress = 1.00, t =   4.78 s / 4951.38 tokens per second
36.32.536.180 I reasoning-budget: activated, budget=2147483647 tokens
36.33.670.877 I slot print_timing: id  0 | task 2757 | n_decoded =    100, tg =  86.70 t/s
36.33.826.460 I reasoning-budget: deactivated (natural end)
36.34.324.227 I slot print_timing: id  0 | task 2757 | prompt eval time =    4809.05 ms / 23675 tokens (    0.20 ms per token,  4923.01 tokens per second)
36.34.324.251 I slot print_timing: id  0 | task 2757 |        eval time =    1806.71 ms /   156 tokens (   11.58 ms per token,    86.34 tokens per second)
36.34.324.251 I slot print_timing: id  0 | task 2757 |       total time =    6615.76 ms / 23831 tokens
36.34.324.252 I slot print_timing: id  0 | task 2757 |    graphs reused =          0
36.34.326.029 I slot      release: id  0 | task 2757 | stop processing: n_tokens = 42215, truncated = 0
36.34.326.069 I srv  update_slots: all slots are idle
36.34.601.624 I srv  params_from_: Chat format: peg-gemma4
36.34.675.471 I slot get_availabl: id  0 | task -1 | selected slot by LCP similarity, sim_best = 0.998 (> 0.100 thold), f_keep = 0.999
36.34.675.683 I slot launch_slot_: id  0 | task 2928 | processing task, is_child = 0
36.34.755.427 I reasoning-budget: activated, budget=2147483647 tokens
36.34.781.220 I reasoning-budget: deactivated (natural end)
36.35.042.580 I slot print_timing: id  0 | task 2928 | prompt eval time =      60.12 ms /    92 tokens (    0.65 ms per token,  1530.30 tokens per second)
36.35.042.604 I slot print_timing: id  0 | task 2928 |        eval time =     306.71 ms /    26 tokens (   11.80 ms per token,    84.77 tokens per second)
36.35.042.604 I slot print_timing: id  0 | task 2928 |       total time =     366.83 ms /   118 tokens
36.35.042.605 I slot print_timing: id  0 | task 2928 |    graphs reused =          0
36.35.044.197 I slot      release: id  0 | task 2928 | stop processing: n_tokens = 42289, truncated = 0
36.35.044.237 I srv  update_slots: all slots are idle
39.21.477.754 I srv  params_from_: Chat format: peg-gemma4
39.21.542.214 I slot get_availabl: id  0 | task -1 | selected slot by LCP similarity, sim_best = 0.992 (> 0.100 thold), f_keep = 0.995
39.21.542.455 I slot launch_slot_: id  0 | task 2956 | processing task, is_child = 0
39.21.887.500 I slot create_check: id  0 | task 2956 | created context checkpoint 7 of 32 (pos_min = 40846, pos_max = 42381, n_tokens = 42382, size = 170.013 MiB)
39.21.930.244 I reasoning-budget: activated, budget=2147483647 tokens
39.23.069.202 I slot print_timing: id  0 | task 2956 | n_decoded =    100, tg =  86.35 t/s
39.25.652.680 I slot print_timing: id  0 | task 2956 | n_decoded =    361, tg =  86.78 t/s
39.26.744.161 I reasoning-budget: deactivated (natural end)
39.27.468.914 I slot print_timing: id  0 | task 2956 | prompt eval time =     368.60 ms /   326 tokens (    1.13 ms per token,   884.43 tokens per second)
39.27.468.936 I slot print_timing: id  0 | task 2956 |        eval time =    6236.44 ms /   541 tokens (   11.53 ms per token,    86.75 tokens per second)
39.27.468.937 I slot print_timing: id  0 | task 2956 |       total time =    6605.03 ms /   867 tokens
39.27.468.939 I slot print_timing: id  0 | task 2956 |    graphs reused =          0
39.27.470.917 I slot      release: id  0 | task 2956 | stop processing: n_tokens = 42926, truncated = 0
39.27.470.962 I srv  update_slots: all slots are idle
39.27.786.760 I srv  params_from_: Chat format: peg-gemma4
39.27.851.827 I slot get_availabl: id  0 | task -1 | selected slot by LCP similarity, sim_best = 0.998 (> 0.100 thold), f_keep = 0.999
39.27.852.033 I slot launch_slot_: id  0 | task 3500 | processing task, is_child = 0
39.27.885.450 I slot create_check: id  0 | task 3500 | created context checkpoint 8 of 32 (pos_min = 41642, pos_max = 42861, n_tokens = 42862, size = 170.013 MiB)
39.27.963.016 I reasoning-budget: activated, budget=2147483647 tokens
39.27.988.768 I reasoning-budget: deactivated (natural end)
39.28.646.285 I slot print_timing: id  0 | task 3500 | prompt eval time =     247.02 ms /    80 tokens (    3.09 ms per token,   323.86 tokens per second)
39.28.646.309 I slot print_timing: id  0 | task 3500 |        eval time =     702.90 ms /    60 tokens (   11.71 ms per token,    85.36 tokens per second)
39.28.646.309 I slot print_timing: id  0 | task 3500 |       total time =     949.92 ms /   140 tokens
39.28.646.310 I slot print_timing: id  0 | task 3500 |    graphs reused =          0
39.28.647.916 I slot      release: id  0 | task 3500 | stop processing: n_tokens = 43001, truncated = 0
39.28.647.956 I srv  update_slots: all slots are idle
39.28.969.568 I srv  params_from_: Chat format: peg-gemma4
39.29.039.403 I slot get_availabl: id  0 | task -1 | selected slot by LCP similarity, sim_best = 0.998 (> 0.100 thold), f_keep = 0.999
39.29.039.616 I slot launch_slot_: id  0 | task 3562 | processing task, is_child = 0
39.29.039.679 I slot update_slots: id  0 | task 3562 | Checking checkpoint with [41642, 42861] against 41917...
39.29.061.772 W slot update_slots: id  0 | task 3562 | restored context checkpoint (pos_min = 41642, pos_max = 42861, n_tokens = 42862, n_past = 42861, size = 170.013 MiB)
39.29.160.648 I reasoning-budget: activated, budget=2147483647 tokens
39.30.314.061 I slot print_timing: id  0 | task 3562 | n_decoded =    100, tg =  85.19 t/s
39.32.459.026 I reasoning-budget: deactivated (natural end)
39.32.724.368 I slot print_timing: id  0 | task 3562 | prompt eval time =     100.50 ms /   188 tokens (    0.53 ms per token,  1870.63 tokens per second)
39.32.724.394 I slot print_timing: id  0 | task 3562 |        eval time =    3584.18 ms /   308 tokens (   11.64 ms per token,    85.93 tokens per second)
39.32.724.394 I slot print_timing: id  0 | task 3562 |       total time =    3684.68 ms /   496 tokens
39.32.724.396 I slot print_timing: id  0 | task 3562 |    graphs reused =          0
39.32.726.069 I slot      release: id  0 | task 3562 | stop processing: n_tokens = 43356, truncated = 0
39.32.726.109 I srv  update_slots: all slots are idle
39.33.011.789 I srv  params_from_: Chat format: peg-gemma4
39.33.075.008 I slot get_availabl: id  0 | task -1 | selected slot by LCP similarity, sim_best = 0.998 (> 0.100 thold), f_keep = 0.999
39.33.075.388 I slot launch_slot_: id  0 | task 3872 | processing task, is_child = 0
39.32.832.985 I slot create_check: id  0 | task 3872 | created context checkpoint 9 of 32 (pos_min = 41838, pos_max = 43331, n_tokens = 43332, size = 170.013 MiB)
39.32.908.524 I reasoning-budget: activated, budget=2147483647 tokens
39.34.035.339 I slot print_timing: id  0 | task 3872 | n_decoded =    100, tg =  87.30 t/s
39.35.272.684 I reasoning-budget: deactivated (natural end)
39.35.719.307 I slot print_timing: id  0 | task 3872 | prompt eval time =     231.47 ms /    69 tokens (    3.35 ms per token,   298.10 tokens per second)
39.35.719.327 I slot print_timing: id  0 | task 3872 |        eval time =    2829.40 ms /   245 tokens (   11.55 ms per token,    86.59 tokens per second)
39.35.719.328 I slot print_timing: id  0 | task 3872 |       total time =    3060.86 ms /   314 tokens
39.35.719.328 I slot print_timing: id  0 | task 3872 |    graphs reused =          0
39.35.721.124 I slot      release: id  0 | task 3872 | stop processing: n_tokens = 43645, truncated = 0
39.35.721.163 I srv  update_slots: all slots are idle
```
