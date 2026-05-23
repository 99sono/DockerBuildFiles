# docker compose

```yml
services:
  qwen-27b-mtp-server:
    # CUDA 12.8+ base ensures Blackwell SM120 support is native.
    image: havenoammo/llama:cuda13-server
    # Necessary to use the havenammo image. the llama cpp still lacks MTP. They will build it soon.
    #     2026-05-17 10:32:17.831 | warn: LLAMA_ARG_HOST environment variable is set, but will be overwritten by command line argument --host
    # 2026-05-17 10:32:17.832 | error while handling argument "--spec-type": unknown speculative type: mtp
    # 2026-05-17 10:32:17.832 | 
    # 2026-05-17 10:32:17.832 | usage:
    # 2026-05-17 10:32:17.832 | --spec-type none,draft-simple,draft-eagle3,ngram-simple,ngram-map-k,ngram-map-k4v,ngram-mod,ngram-cache
    # 2026-05-17 10:32:17.832 |                                         comma-separated list of types of speculative decoding to use (default:
    # 2026-05-17 10:32:17.832 |                                         none)
    # 2026-05-17 10:32:17.832 |                                         
    # 2026-05-17 10:32:17.832 |                                         (env: LLAMA_ARG_SPEC_TYPE)
    # 2026-05-17 10:32:17.832 | 
    # 2026-05-17 10:32:17.832 | 
    # 2026-05-17 10:32:17.832 | to show complete usage, run with -h
        # image: ghcr.io/ggml-org/llama.cpp:server-cuda13
    container_name: qwen-3.6-27b-mtp-5090
    hostname: inference-server
    platform: linux/amd64
    # All models served on port 8000. Single-model capacity avoids client port mismatches.
    ports:
      - "${INFERENCE_SERVER_PORT:-8000}:8000"

    volumes:
      # Use the central workstation cache to avoid redundant 20GB downloads.
      - ~/.cache/huggingface:/root/.cache/huggingface
      # Shared memory access is vital for high-speed KV cache paging in WSL2.
      - /dev/shm:/dev/shm

    # 32GB shm_size matches your VRAM; crucial for large context windows (128k+).
    shm_size: "32g"
    ipc: host

    deploy:
      resources:
        reservations:
          devices:
            - capabilities: [gpu] # Pass-through for the 5090.

    environment:
      - CUDA_VISIBLE_DEVICES=0
      # Critical: Forces the container to use Blackwell-optimized libraries.
      # This enables the 5.7x speedup via MMQ kernels.
      - LD_LIBRARY_PATH=/usr/local/cuda-12.8/lib64
      - HF_HOME=/root/.cache/huggingface
      - NVIDIA_VISIBLE_DEVICES=0

    command:
      # Loads directly from your central cache via the -hf flag.
      - "-hf"
      # Model: Qwen3.6-27B MTP quantization (UD-Q4_K_XL).
      - "unsloth/Qwen3.6-27B-MTP-GGUF:UD-Q4_K_XL"
      # Aliased name presented in /v1/models API response.
      - "--alias"
      - "${INFERENCE_MODEL_ALIAS:-qwen3.6-27b}"
      # Bind to all interfaces for network access.
      - "--host"
      - "0.0.0.0"
      # Internal container port.
      - "--port"
      - "${INFERENCE_SERVER_PORT:-8000}"
      # API key authentication
      - "--api-key"
      - "${INFERENCE_API_KEY:-dummy-key}"
      # Ensure 100% of the model stays on the 5090's 32GB VRAM.
      - "--n-gpu-layers"
      - "999"
      # Blackwell-native acceleration for long-context attention.
      - "--flash-attn"
      - "on"
      # Q8_0 KV-cache: High precision (8-bit) to avoid "doom loop" logic errors.
      - "--cache-type-k"
      - "q8_0"
      - "--cache-type-v"
      - "q8_0"
      # 128k context — goldilocks zone for high-performance coding tasks.
      - "--ctx-size"
      - "131072"

      # --- THREADING OPTIMIZATION ---
      # 12 threads for single-token generation (lean, CPU cache friendly).
      # 24 threads for batch/MTP verification bursts using SMT cores on the 5950X.
      - "--threads"
      - "12"
      - "--threads-batch"
      - "24"

      # --- SPECULATIVE DECODING ---
      # MTP draft: parallel multi-token prediction, verified in one forward pass.
      - "--spec-type"
      - "draft-mtp"
      # 2 tokens (not 3) to prevent acceptance collapse at deep context.
      # At ~52% per-token acceptance: 0.52^2 = 27% chain success vs 0.52^3 = 14%.
      - "--spec-draft-n-max"
      - "2"
      # Strict confidence threshold to avoid garbage draft tokens.
      - "--spec-draft-p-min"
      - "0.8"

      # --- SAMPLING ---
      - "--temp"
      - "1.0"
      - "--top-p"
      - "0.95"
      - "--top-k"
      - "20"
      # Keeps the model focused during long code generations.
      - "--presence-penalty"
      - "1.5"

    networks:
      - development-network

networks:
  # Allows this server to communicate with your other internal tools/proxies.
  development-network:
    external: true
```

# llamacpp.log
```log
2026-05-23 18:06:09.535 | warn: LLAMA_ARG_HOST environment variable is set, but will be overwritten by command line argument --host
2026-05-23 18:06:10.028 | 0.00.900.843 I log_info: verbosity = 3 (adjust with the `-lv N` CLI arg)
2026-05-23 18:06:10.028 | 0.00.900.869 I device_info:
2026-05-23 18:06:10.318 | 0.01.190.507 I   - CUDA0   : NVIDIA GeForce RTX 5090 (32606 MiB, 30930 MiB free)
2026-05-23 18:06:10.318 | 0.01.190.546 I   - CPU     : AMD Ryzen 9 5950X 16-Core Processor (64297 MiB, 64297 MiB free)
2026-05-23 18:06:10.321 | 0.01.193.741 I system_info: n_threads = 12 (n_threads_batch = 24) / 32 | CUDA : ARCHS = 750,800,860,890,1200,1210 | USE_GRAPHS = 1 | PEER_MAX_BATCH_SIZE = 128 | BLACKWELL_NATIVE_FP4 = 1 | CPU : SSE3 = 1 | SSSE3 = 1 | AVX = 1 | AVX2 = 1 | F16C = 1 | FMA = 1 | BMI2 = 1 | LLAMAFILE = 1 | OPENMP = 1 | REPACK = 1 | 
2026-05-23 18:06:10.321 | 0.01.193.760 I srv          main: n_parallel is set to auto, using n_parallel = 4 and kv_unified = true
2026-05-23 18:06:10.321 | 0.01.193.981 I srv          init: running without SSL
2026-05-23 18:06:10.321 | 0.01.194.011 I srv          init: api_keys: ****-key
2026-05-23 18:06:10.321 | 0.01.194.030 I srv          init: using 31 threads for HTTP server
2026-05-23 18:06:10.322 | 0.01.194.110 I srv         start: binding port with default address family
2026-05-23 18:06:10.323 | 0.01.196.026 I srv          main: loading model
2026-05-23 18:06:10.324 | 0.01.196.255 I srv    load_model: loading model '/root/.cache/huggingface/hub/models--unsloth--Qwen3.6-27B-MTP-GGUF/snapshots/b3a58239d8d40b953e34936c9afeb28baa518230/Qwen3.6-27B-UD-Q4_K_XL.gguf'
2026-05-23 18:06:10.324 | 0.01.196.938 I common_init_result: fitting params to device memory ...
2026-05-23 18:06:10.324 | 0.01.196.954 I common_init_result: (for bugs during this step try to reproduce them with -fit off, or provide --verbose logs if the bug only occurs with -fit on)
2026-05-23 18:06:28.332 | 0.19.204.000 W llama_context: n_ctx_seq (131072) < n_ctx_train (262144) -- the full capacity of the model will not be utilized
2026-05-23 18:06:28.706 | 0.19.578.261 W common_init_from_params: warming up the model with an empty run - please wait ... (--no-warmup to disable)
2026-05-23 18:06:29.036 | 0.19.908.087 I srv    load_model: creating MTP draft context against the target model '/root/.cache/huggingface/hub/models--unsloth--Qwen3.6-27B-MTP-GGUF/snapshots/b3a58239d8d40b953e34936c9afeb28baa518230/Qwen3.6-27B-UD-Q4_K_XL.gguf'
2026-05-23 18:06:29.036 | 0.19.908.189 W llama_context: n_ctx_seq (131072) < n_ctx_train (262144) -- the full capacity of the model will not be utilized
2026-05-23 18:06:29.369 | 0.20.241.176 W load_hparams: Qwen-VL models require at minimum 1024 image tokens to function correctly on grounding tasks
2026-05-23 18:06:29.369 | 0.20.241.197 W load_hparams: if you encounter problems with accuracy, try adding --image-min-tokens 1024
2026-05-23 18:06:29.369 | 0.20.241.197 W load_hparams: more info: https://github.com/ggml-org/llama.cpp/issues/16842
2026-05-23 18:06:29.369 | 
2026-05-23 18:06:30.215 | 0.21.087.751 I srv    load_model: loaded multimodal model, '/root/.cache/huggingface/hub/models--unsloth--Qwen3.6-27B-MTP-GGUF/snapshots/b3a58239d8d40b953e34936c9afeb28baa518230/mmproj-BF16.gguf'
2026-05-23 18:06:30.215 | 0.21.087.775 I srv    load_model: initializing slots, n_slots = 4
2026-05-23 18:06:30.250 | 0.21.122.117 I common_context_can_seq_rm: the context supports bounded partial sequence removal
2026-05-23 18:06:30.267 | 0.21.139.884 I common_speculative_init: adding speculative implementation 'draft-mtp'
2026-05-23 18:06:30.268 | 0.21.140.290 I srv    load_model: speculative decoding context initialized
2026-05-23 18:06:30.268 | 0.21.140.307 I slot   load_model: id  0 | task -1 | new slot, n_ctx = 131072
2026-05-23 18:06:30.268 | 0.21.140.310 I slot   load_model: id  1 | task -1 | new slot, n_ctx = 131072
2026-05-23 18:06:30.268 | 0.21.140.310 I slot   load_model: id  2 | task -1 | new slot, n_ctx = 131072
2026-05-23 18:06:30.268 | 0.21.140.311 I slot   load_model: id  3 | task -1 | new slot, n_ctx = 131072
2026-05-23 18:06:30.268 | 0.21.140.374 I srv    load_model: prompt cache is enabled, size limit: 8192 MiB
2026-05-23 18:06:30.268 | 0.21.140.390 I srv    load_model: use `--cache-ram 0` to disable the prompt cache
2026-05-23 18:06:30.268 | 0.21.140.391 I srv    load_model: for more info see https://github.com/ggml-org/llama.cpp/pull/16391
2026-05-23 18:06:30.268 | 0.21.140.407 I srv          init: idle slots will be saved to prompt cache and cleared upon starting a new task
2026-05-23 18:06:30.281 | 0.21.153.311 I init: chat template, example_format: '<|im_start|>system
2026-05-23 18:06:30.281 | You are a helpful assistant<|im_end|>
2026-05-23 18:06:30.281 | <|im_start|>user
2026-05-23 18:06:30.281 | Hello<|im_end|>
2026-05-23 18:06:30.281 | <|im_start|>assistant
2026-05-23 18:06:30.281 | Hi there<|im_end|>
2026-05-23 18:06:30.281 | <|im_start|>user
2026-05-23 18:06:30.281 | How are you?<|im_end|>
2026-05-23 18:06:30.281 | <|im_start|>assistant
2026-05-23 18:06:30.281 | <think>
2026-05-23 18:06:30.281 | '
2026-05-23 18:06:30.290 | 0.21.162.318 I srv          init: init: chat template, thinking = 1
2026-05-23 18:06:30.290 | 0.21.162.354 I srv          main: model loaded
2026-05-23 18:06:30.290 | 0.21.162.357 I srv          main: server is listening on http://0.0.0.0:8000
2026-05-23 18:06:30.290 | 0.21.162.359 I srv  update_slots: all slots are idle
2026-05-23 18:08:00.739 | 1.51.611.215 I srv  params_from_: Chat format: peg-native
2026-05-23 18:08:00.739 | 1.51.611.483 I slot get_availabl: id  3 | task -1 | selected slot by LRU, t_last = -1
2026-05-23 18:08:00.739 | 1.51.611.511 I srv  get_availabl: updating prompt cache
2026-05-23 18:08:00.739 | 1.51.611.517 I srv          load:  - looking for better prompt, base f_keep = -1.000, sim = 0.000
2026-05-23 18:08:00.739 | 1.51.611.519 I srv        update:  - cache state: 0 prompts, 0.000 MiB (limits: 8192.000 MiB, 131072 tokens, 8589934592 est)
2026-05-23 18:08:00.739 | 1.51.611.520 I srv  get_availabl: prompt cache update took 0.01 ms
2026-05-23 18:08:00.739 | 1.51.611.619 I slot launch_slot_: id  3 | task 0 | processing task, is_child = 0
2026-05-23 18:08:00.885 | 1.51.757.764 I srv  params_from_: Chat format: peg-native
2026-05-23 18:08:01.640 | 1.52.512.028 I slot get_availabl: id  2 | task -1 | selected slot by LRU, t_last = -1
2026-05-23 18:08:01.640 | 1.52.512.049 I srv  get_availabl: updating prompt cache
2026-05-23 18:08:01.640 | 1.52.512.053 I srv          load:  - looking for better prompt, base f_keep = -1.000, sim = 0.000
2026-05-23 18:08:01.640 | 1.52.512.055 I srv        update:  - cache state: 0 prompts, 0.000 MiB (limits: 8192.000 MiB, 131072 tokens, 8589934592 est)
2026-05-23 18:08:01.640 | 1.52.512.056 I srv  get_availabl: prompt cache update took 0.01 ms
2026-05-23 18:08:01.640 | 1.52.512.971 I reasoning-budget: activated, budget=2147483647 tokens
2026-05-23 18:08:01.640 | 1.52.513.005 I slot launch_slot_: id  2 | task 2 | processing task, is_child = 0
2026-05-23 18:08:04.226 | 1.55.098.772 I slot print_timing: id  2 | task 2 | prompt processing, n_tokens =   2048, progress = 0.24, t =   3.09 s / 661.88 tokens per second
2026-05-23 18:08:05.018 | 1.55.890.341 I slot print_timing: id  2 | task 2 | prompt processing, n_tokens =   4096, progress = 0.47, t =   3.89 s / 1054.10 tokens per second
2026-05-23 18:08:05.815 | 1.56.687.783 I slot print_timing: id  2 | task 2 | prompt processing, n_tokens =   6144, progress = 0.71, t =   4.68 s / 1311.92 tokens per second
2026-05-23 18:08:05.815 | 1.56.687.981 I slot print_timing: id  3 | task 0 | prompt processing, n_tokens =    359, progress = 0.41, t =   5.58 s / 64.28 tokens per second
2026-05-23 18:08:05.993 | 1.56.865.677 I slot create_check: id  3 | task 0 | created context checkpoint 1 of 32 (pos_min = 358, pos_max = 358, n_tokens = 359, size = 150.378 MiB)
2026-05-23 18:08:06.519 | 1.57.391.774 I slot print_timing: id  2 | task 2 | prompt processing, n_tokens =   8180, progress = 0.94, t =   5.71 s / 1431.96 tokens per second
2026-05-23 18:08:06.698 | 1.57.570.836 I slot create_check: id  2 | task 2 | created context checkpoint 1 of 32 (pos_min = 8179, pos_max = 8179, n_tokens = 8180, size = 166.757 MiB)
2026-05-23 18:08:06.698 | 1.57.570.862 I slot print_timing: id  3 | task 0 | prompt processing, n_tokens =    371, progress = 0.42, t =   6.79 s / 54.62 tokens per second
2026-05-23 18:08:07.104 | 1.57.976.205 I slot print_timing: id  2 | task 2 | prompt processing, n_tokens =   8692, progress = 1.00, t =   6.30 s / 1380.37 tokens per second
2026-05-23 18:08:07.303 | 1.58.175.872 I slot create_check: id  2 | task 2 | created context checkpoint 2 of 32 (pos_min = 8691, pos_max = 8691, n_tokens = 8692, size = 167.830 MiB)
2026-05-23 18:08:07.303 | 1.58.175.896 I slot print_timing: id  3 | task 0 | prompt processing, n_tokens =    871, progress = 1.00, t =   7.40 s / 117.74 tokens per second
2026-05-23 18:08:07.483 | 1.58.355.819 I slot create_check: id  3 | task 0 | created context checkpoint 2 of 32 (pos_min = 870, pos_max = 870, n_tokens = 871, size = 151.450 MiB)
2026-05-23 18:08:08.926 | 1.59.798.746 I reasoning-budget: deactivated (natural end)
2026-05-23 18:08:09.544 | 2.00.416.675 I slot print_timing: id  2 | task 2 | 
2026-05-23 18:08:09.544 | prompt eval time =    6766.44 ms /  8696 tokens (    0.78 ms per token,  1285.17 tokens per second)
2026-05-23 18:08:09.544 |        eval time =    1970.73 ms /    62 tokens (   31.79 ms per token,    31.46 tokens per second)
2026-05-23 18:08:09.544 |       total time =    8737.17 ms /  8758 tokens
2026-05-23 18:08:09.544 | draft acceptance rate = 0.76000 (   38 accepted /    50 generated)
2026-05-23 18:08:09.544 | 2.00.416.719 I statistics draft-mtp: #calls(b,g,a) = 2 25 49, #gen drafts = 50, #acc drafts = 43, #gen tokens = 100, #acc tokens = 77, dur(b,g,a) = 0.006, 136.464, 0.112 ms
2026-05-23 18:08:09.545 | 2.00.417.182 I slot      release: id  2 | task 2 | stop processing: n_tokens = 8759, truncated = 0
2026-05-23 18:08:09.978 | 2.00.849.997 I slot print_timing: id  3 | task 0 | n_decoded =    102, tg =  42.45 t/s
2026-05-23 18:08:12.583 | 2.03.455.466 I slot print_timing: id  3 | task 0 | n_decoded =    372, tg =  68.57 t/s
2026-05-23 18:08:15.600 | 2.06.472.638 I slot print_timing: id  3 | task 0 | n_decoded =    659, tg =  78.06 t/s
2026-05-23 18:08:16.644 | 2.07.516.315 I slot print_timing: id  3 | task 0 | 
2026-05-23 18:08:16.644 | prompt eval time =    7668.96 ms /   875 tokens (    8.76 ms per token,   114.10 tokens per second)
2026-05-23 18:08:16.644 |        eval time =    9486.26 ms /   756 tokens (   12.55 ms per token,    79.69 tokens per second)
2026-05-23 18:08:16.644 |       total time =   17155.21 ms /  1631 tokens
2026-05-23 18:08:16.644 | draft acceptance rate = 0.79281 (  463 accepted /   584 generated)
2026-05-23 18:08:16.644 | 2.07.516.348 I statistics draft-mtp: #calls(b,g,a) = 2 292 317, #gen drafts = 317, #acc drafts = 273, #gen tokens = 634, #acc tokens = 501, dur(b,g,a) = 0.006, 1279.973, 0.589 ms
2026-05-23 18:08:16.644 | 2.07.516.418 I slot      release: id  3 | task 0 | stop processing: n_tokens = 1630, truncated = 0
2026-05-23 18:08:16.644 | 2.07.516.447 I srv  update_slots: all slots are idle
2026-05-23 18:10:29.736 | 4.20.607.970 I srv  params_from_: Chat format: peg-native
2026-05-23 18:10:29.738 | 4.20.610.500 I slot get_availabl: id  2 | task -1 | selected slot by LCP similarity, sim_best = 0.948 (> 0.100 thold), f_keep = 0.957
2026-05-23 18:10:29.739 | 4.20.611.327 I reasoning-budget: activated, budget=2147483647 tokens
2026-05-23 18:10:29.739 | 4.20.611.450 I slot launch_slot_: id  2 | task 301 | processing task, is_child = 0
2026-05-23 18:10:29.739 | 4.20.611.481 I slot slot_save_an: id  3 | task -1 | saving idle slot to prompt cache
2026-05-23 18:10:29.739 | 4.20.611.891 W srv   prompt_save:  - saving prompt with length 1630, total state size = 207.192 MiB (draft: 3.414 MiB)
2026-05-23 18:10:30.476 | 4.21.347.948 I slot prompt_clear: id  3 | task -1 | clearing prompt with 1630 tokens
2026-05-23 18:10:30.476 | 4.21.348.515 I srv        update:  - cache state: 1 prompts, 509.021 MiB (limits: 8192.000 MiB, 131072 tokens, 131072 est)
2026-05-23 18:10:30.476 | 4.21.348.536 I srv        update:    - prompt 0x63d3aecbf9f0:    1630 tokens, checkpoints:  2,   509.021 MiB
2026-05-23 18:10:30.476 | 4.21.348.640 W slot update_slots: id  2 | task 301 | n_past = 8381, slot.prompt.tokens.size() = 8759, seq_id = 2, pos_min = 8758, n_swa = 0
2026-05-23 18:10:30.476 | 4.21.348.659 I slot update_slots: id  2 | task 301 | Checking checkpoint with [8691, 8691] against 8381...
2026-05-23 18:10:30.476 | 4.21.348.660 I slot update_slots: id  2 | task 301 | Checking checkpoint with [8179, 8179] against 8381...
2026-05-23 18:10:30.546 | 4.21.418.128 W slot update_slots: id  2 | task 301 | restored context checkpoint (pos_min = 8179, pos_max = 8179, n_tokens = 8180, n_past = 8180, size = 166.757 MiB)
2026-05-23 18:10:30.546 | 4.21.418.151 W slot update_slots: id  2 | task 301 | erased invalidated context checkpoint (pos_min = 8691, pos_max = 8691, n_tokens = 8692, n_swa = 0, pos_next = 8180, size = 167.830 MiB)
2026-05-23 18:10:30.869 | 4.21.741.521 I slot create_check: id  2 | task 301 | created context checkpoint 2 of 32 (pos_min = 8323, pos_max = 8323, n_tokens = 8324, size = 167.059 MiB)
2026-05-23 18:10:31.287 | 4.22.159.676 I slot create_check: id  2 | task 301 | created context checkpoint 3 of 32 (pos_min = 8835, pos_max = 8835, n_tokens = 8836, size = 168.131 MiB)
2026-05-23 18:10:31.951 | 4.22.823.790 I reasoning-budget: deactivated (natural end)
2026-05-23 18:10:31.855 | 4.22.727.339 I slot print_timing: id  2 | task 301 | n_decoded =    100, tg =  96.72 t/s
2026-05-23 18:10:32.178 | 4.23.050.187 I slot print_timing: id  2 | task 301 | 
2026-05-23 18:10:32.178 | prompt eval time =     846.14 ms /   660 tokens (    1.28 ms per token,   780.01 tokens per second)
2026-05-23 18:10:32.178 |        eval time =    1356.68 ms /   122 tokens (   11.12 ms per token,    89.93 tokens per second)
2026-05-23 18:10:32.178 |       total time =    2202.83 ms /   782 tokens
2026-05-23 18:10:32.178 | draft acceptance rate = 0.93023 (   80 accepted /    86 generated)
2026-05-23 18:10:32.178 | 4.23.050.222 I statistics draft-mtp: #calls(b,g,a) = 3 335 360, #gen drafts = 360, #acc drafts = 314, #gen tokens = 720, #acc tokens = 581, dur(b,g,a) = 0.007, 1475.509, 0.685 ms
2026-05-23 18:10:32.178 | 4.23.050.614 I slot      release: id  2 | task 301 | stop processing: n_tokens = 8963, truncated = 0
2026-05-23 18:10:32.178 | 4.23.050.692 I srv  update_slots: all slots are idle
2026-05-23 18:10:32.309 | 4.23.181.504 I srv  params_from_: Chat format: peg-native
2026-05-23 18:10:32.310 | 4.23.182.835 I slot get_availabl: id  2 | task -1 | selected slot by LCP similarity, sim_best = 0.705 (> 0.100 thold), f_keep = 0.993
2026-05-23 18:10:32.311 | 4.23.183.469 I reasoning-budget: activated, budget=2147483647 tokens
2026-05-23 18:10:32.311 | 4.23.183.542 I slot launch_slot_: id  2 | task 348 | processing task, is_child = 0
2026-05-23 18:10:32.311 | 4.23.183.575 W slot update_slots: id  2 | task 348 | n_past = 8903, slot.prompt.tokens.size() = 8963, seq_id = 2, pos_min = 8962, n_swa = 0
2026-05-23 18:10:32.311 | 4.23.183.576 I slot update_slots: id  2 | task 348 | Checking checkpoint with [8835, 8835] against 8903...
2026-05-23 18:10:32.333 | 4.23.205.623 W slot update_slots: id  2 | task 348 | restored context checkpoint (pos_min = 8835, pos_max = 8835, n_tokens = 8836, n_past = 8836, size = 168.131 MiB)
2026-05-23 18:10:33.934 | 4.24.806.628 I slot create_check: id  2 | task 348 | created context checkpoint 4 of 32 (pos_min = 12109, pos_max = 12109, n_tokens = 12110, size = 174.988 MiB)
2026-05-23 18:10:34.369 | 4.25.241.694 I slot create_check: id  2 | task 348 | created context checkpoint 5 of 32 (pos_min = 12621, pos_max = 12621, n_tokens = 12622, size = 176.060 MiB)
2026-05-23 18:10:35.300 | 4.26.172.136 I reasoning-budget: deactivated (natural end)
2026-05-23 18:10:35.592 | 4.26.464.696 I slot print_timing: id  2 | task 348 | n_decoded =    101, tg =  85.10 t/s
2026-05-23 18:10:38.098 | 4.28.970.291 I slot print_timing: id  2 | task 348 | n_decoded =    401, tg =  95.64 t/s
2026-05-23 18:10:41.105 | 4.31.977.452 I slot print_timing: id  2 | task 348 | n_decoded =    702, tg =  97.50 t/s
2026-05-23 18:10:41.163 | 4.32.035.229 I slot print_timing: id  2 | task 348 | 
2026-05-23 18:10:41.163 | prompt eval time =    2094.11 ms /  3790 tokens (    0.55 ms per token,  1809.84 tokens per second)
2026-05-23 18:10:41.163 |        eval time =    7257.52 ms /   707 tokens (   10.27 ms per token,    97.42 tokens per second)
2026-05-23 18:10:41.163 |       total time =    9351.63 ms /  4497 tokens
2026-05-23 18:10:41.163 | draft acceptance rate = 0.95473 (  464 accepted /   486 generated)
2026-05-23 18:10:41.163 | 4.32.035.265 I statistics draft-mtp: #calls(b,g,a) = 4 578 603, #gen drafts = 603, #acc drafts = 550, #gen tokens = 1206, #acc tokens = 1045, dur(b,g,a) = 0.008, 2579.645, 1.226 ms
2026-05-23 18:10:41.163 | 4.32.035.785 I slot      release: id  2 | task 348 | stop processing: n_tokens = 13333, truncated = 0
2026-05-23 18:10:41.163 | 4.32.035.851 I srv  update_slots: all slots are idle
2026-05-23 18:10:41.362 | 4.32.234.294 I srv  params_from_: Chat format: peg-native
2026-05-23 18:10:41.363 | 4.32.235.643 I slot get_availabl: id  2 | task -1 | selected slot by LCP similarity, sim_best = 0.721 (> 0.100 thold), f_keep = 1.000
2026-05-23 18:10:41.364 | 4.32.236.285 I reasoning-budget: activated, budget=2147483647 tokens
2026-05-23 18:10:41.364 | 4.32.236.377 I slot launch_slot_: id  2 | task 596 | processing task, is_child = 0
2026-05-23 18:10:43.130 | 4.34.002.580 I slot create_check: id  2 | task 596 | created context checkpoint 6 of 32 (pos_min = 17977, pos_max = 17977, n_tokens = 17978, size = 187.277 MiB)
2026-05-23 18:10:43.582 | 4.34.454.132 I slot create_check: id  2 | task 596 | created context checkpoint 7 of 32 (pos_min = 18489, pos_max = 18489, n_tokens = 18490, size = 188.349 MiB)
2026-05-23 18:10:43.810 | 4.34.682.595 I reasoning-budget: deactivated (natural end)
2026-05-23 18:10:44.734 | 4.35.606.444 I slot print_timing: id  2 | task 596 | n_decoded =    100, tg =  89.47 t/s
2026-05-23 18:10:47.243 | 4.38.115.440 I slot print_timing: id  2 | task 596 | n_decoded =    397, tg =  96.17 t/s
2026-05-23 18:10:49.880 | 4.40.752.823 I slot print_timing: id  2 | task 596 | 
2026-05-23 18:10:49.880 | prompt eval time =    2752.90 ms /  5161 tokens (    0.53 ms per token,  1874.75 tokens per second)
2026-05-23 18:10:49.880 |        eval time =    6842.83 ms /   664 tokens (   10.31 ms per token,    97.04 tokens per second)
2026-05-23 18:10:49.880 |       total time =    9595.73 ms /  5825 tokens
2026-05-23 18:10:49.880 | draft acceptance rate = 0.97333 (  438 accepted /   450 generated)
2026-05-23 18:10:49.880 | 4.40.752.858 I statistics draft-mtp: #calls(b,g,a) = 5 803 828, #gen drafts = 828, #acc drafts = 772, #gen tokens = 1656, #acc tokens = 1483, dur(b,g,a) = 0.009, 3612.520, 1.730 ms
2026-05-23 18:10:49.881 | 4.40.753.513 I slot      release: id  2 | task 596 | stop processing: n_tokens = 19157, truncated = 0
2026-05-23 18:10:49.881 | 4.40.753.585 I srv  update_slots: all slots are idle
2026-05-23 18:10:50.066 | 4.40.938.856 I srv  params_from_: Chat format: peg-native
2026-05-23 18:10:50.068 | 4.40.940.197 I slot get_availabl: id  2 | task -1 | selected slot by LCP similarity, sim_best = 0.862 (> 0.100 thold), f_keep = 1.000
2026-05-23 18:10:50.068 | 4.40.940.856 I reasoning-budget: activated, budget=2147483647 tokens
2026-05-23 18:10:50.068 | 4.40.940.931 I slot launch_slot_: id  2 | task 827 | processing task, is_child = 0
2026-05-23 18:10:51.462 | 4.42.333.878 I slot create_check: id  2 | task 827 | created context checkpoint 8 of 32 (pos_min = 21707, pos_max = 21707, n_tokens = 21708, size = 195.089 MiB)
2026-05-23 18:10:51.936 | 4.42.808.302 I slot create_check: id  2 | task 827 | created context checkpoint 9 of 32 (pos_min = 22219, pos_max = 22219, n_tokens = 22220, size = 196.161 MiB)
2026-05-23 18:10:51.817 | 4.42.689.657 I reasoning-budget: deactivated (natural end)
2026-05-23 18:10:52.694 | 4.43.566.313 I slot print_timing: id  2 | task 827 | n_decoded =    102, tg =  89.52 t/s
2026-05-23 18:10:55.712 | 4.46.584.799 I slot print_timing: id  2 | task 827 | n_decoded =    396, tg =  95.24 t/s
2026-05-23 18:10:56.080 | 4.46.952.131 I slot print_timing: id  2 | task 827 | 
2026-05-23 18:10:56.080 | prompt eval time =    1908.54 ms /  3067 tokens (    0.62 ms per token,  1606.99 tokens per second)
2026-05-23 18:10:56.080 |        eval time =    4525.26 ms /   430 tokens (   10.52 ms per token,    95.02 tokens per second)
2026-05-23 18:10:56.080 |       total time =    6433.80 ms /  3497 tokens
2026-05-23 18:10:56.080 | draft acceptance rate = 0.96918 (  283 accepted /   292 generated)
2026-05-23 18:10:56.080 | 4.46.952.168 I statistics draft-mtp: #calls(b,g,a) = 6 949 974, #gen drafts = 974, #acc drafts = 914, #gen tokens = 1948, #acc tokens = 1766, dur(b,g,a) = 0.010, 4284.927, 2.061 ms
2026-05-23 18:10:56.080 | 4.46.952.911 I slot      release: id  2 | task 827 | stop processing: n_tokens = 22653, truncated = 0
2026-05-23 18:10:56.080 | 4.46.952.979 I srv  update_slots: all slots are idle
2026-05-23 18:10:56.270 | 4.47.142.286 I srv  params_from_: Chat format: peg-native
2026-05-23 18:10:56.271 | 4.47.143.681 I slot get_availabl: id  2 | task -1 | selected slot by LCP similarity, sim_best = 0.801 (> 0.100 thold), f_keep = 0.981
2026-05-23 18:10:56.272 | 4.47.144.371 I reasoning-budget: activated, budget=2147483647 tokens
2026-05-23 18:10:56.272 | 4.47.144.457 I slot launch_slot_: id  2 | task 978 | processing task, is_child = 0
2026-05-23 18:10:56.272 | 4.47.144.501 W slot update_slots: id  2 | task 978 | n_past = 22223, slot.prompt.tokens.size() = 22653, seq_id = 2, pos_min = 22652, n_swa = 0
2026-05-23 18:10:56.272 | 4.47.144.502 I slot update_slots: id  2 | task 978 | Checking checkpoint with [22219, 22219] against 22223...
2026-05-23 18:10:56.304 | 4.47.176.497 W slot update_slots: id  2 | task 978 | restored context checkpoint (pos_min = 22219, pos_max = 22219, n_tokens = 22220, n_past = 22220, size = 196.161 MiB)
2026-05-23 18:10:58.417 | 4.49.289.121 I slot create_check: id  2 | task 978 | created context checkpoint 10 of 32 (pos_min = 27218, pos_max = 27218, n_tokens = 27219, size = 206.630 MiB)
2026-05-23 18:10:58.924 | 4.49.796.688 I slot create_check: id  2 | task 978 | created context checkpoint 11 of 32 (pos_min = 27730, pos_max = 27730, n_tokens = 27731, size = 207.702 MiB)
2026-05-23 18:10:59.320 | 4.50.192.567 I reasoning-budget: deactivated (natural end)
2026-05-23 18:11:00.196 | 4.51.067.926 I slot print_timing: id  2 | task 978 | n_decoded =    101, tg =  81.85 t/s
2026-05-23 18:11:02.695 | 4.53.567.429 I slot print_timing: id  2 | task 978 | n_decoded =    383, tg =  90.43 t/s
2026-05-23 18:11:04.139 | 4.55.011.107 I slot print_timing: id  2 | task 978 | 
2026-05-23 18:11:04.139 | prompt eval time =    3190.14 ms /  5515 tokens (    0.58 ms per token,  1728.76 tokens per second)
2026-05-23 18:11:04.139 |        eval time =    5678.82 ms /   514 tokens (   11.05 ms per token,    90.51 tokens per second)
2026-05-23 18:11:04.139 |       total time =    8868.96 ms /  6029 tokens
2026-05-23 18:11:04.139 | draft acceptance rate = 0.94101 (  335 accepted /   356 generated)
2026-05-23 18:11:04.139 | 4.55.011.143 I statistics draft-mtp: #calls(b,g,a) = 7 1127 1152, #gen drafts = 1152, #acc drafts = 1083, #gen tokens = 2304, #acc tokens = 2101, dur(b,g,a) = 0.011, 5130.388, 2.464 ms
2026-05-23 18:11:04.140 | 4.55.012.006 I slot      release: id  2 | task 978 | stop processing: n_tokens = 28248, truncated = 0
2026-05-23 18:11:04.140 | 4.55.012.078 I srv  update_slots: all slots are idle
2026-05-23 18:11:04.349 | 4.55.221.535 I srv  params_from_: Chat format: peg-native
2026-05-23 18:11:04.351 | 4.55.222.912 I slot get_availabl: id  2 | task -1 | selected slot by LCP similarity, sim_best = 0.904 (> 0.100 thold), f_keep = 0.994
2026-05-23 18:11:04.351 | 4.55.223.581 I reasoning-budget: activated, budget=2147483647 tokens
2026-05-23 18:11:04.351 | 4.55.223.659 I slot launch_slot_: id  2 | task 1162 | processing task, is_child = 0
2026-05-23 18:11:04.351 | 4.55.223.707 W slot update_slots: id  2 | task 1162 | n_past = 28065, slot.prompt.tokens.size() = 28248, seq_id = 2, pos_min = 28247, n_swa = 0
2026-05-23 18:11:04.351 | 4.55.223.707 I slot update_slots: id  2 | task 1162 | Checking checkpoint with [27730, 27730] against 28065...
2026-05-23 18:11:04.383 | 4.55.255.476 W slot update_slots: id  2 | task 1162 | restored context checkpoint (pos_min = 27730, pos_max = 27730, n_tokens = 27731, n_past = 27731, size = 207.702 MiB)
2026-05-23 18:11:06.046 | 4.56.918.851 I slot create_check: id  2 | task 1162 | created context checkpoint 12 of 32 (pos_min = 30524, pos_max = 30524, n_tokens = 30525, size = 213.554 MiB)
2026-05-23 18:11:06.570 | 4.57.442.300 I slot create_check: id  2 | task 1162 | created context checkpoint 13 of 32 (pos_min = 31036, pos_max = 31036, n_tokens = 31037, size = 214.626 MiB)
2026-05-23 18:11:06.785 | 4.57.657.635 I reasoning-budget: deactivated (natural end)
2026-05-23 18:11:07.223 | 4.58.095.317 I slot print_timing: id  2 | task 1162 | n_decoded =    101, tg =  90.61 t/s
2026-05-23 18:11:10.234 | 5.01.106.579 I slot print_timing: id  2 | task 1162 | n_decoded =    380, tg =  92.10 t/s
2026-05-23 18:11:12.176 | 5.03.048.526 I slot print_timing: id  2 | task 1162 | 
2026-05-23 18:11:12.176 | prompt eval time =    2257.30 ms /  3310 tokens (    0.68 ms per token,  1466.35 tokens per second)
2026-05-23 18:11:12.176 |        eval time =    6569.56 ms /   604 tokens (   10.88 ms per token,    91.94 tokens per second)
2026-05-23 18:11:12.176 |       total time =    8826.86 ms /  3914 tokens
2026-05-23 18:11:12.176 | draft acceptance rate = 0.99505 (  402 accepted /   404 generated)
2026-05-23 18:11:12.176 | 5.03.048.562 I statistics draft-mtp: #calls(b,g,a) = 8 1329 1354, #gen drafts = 1354, #acc drafts = 1285, #gen tokens = 2708, #acc tokens = 2503, dur(b,g,a) = 0.013, 6106.078, 2.919 ms
2026-05-23 18:11:12.177 | 5.03.049.506 I slot      release: id  2 | task 1162 | stop processing: n_tokens = 31645, truncated = 0
2026-05-23 18:11:12.177 | 5.03.049.574 I srv  update_slots: all slots are idle
2026-05-23 18:11:12.395 | 5.03.267.414 I srv  params_from_: Chat format: peg-native
2026-05-23 18:11:12.396 | 5.03.268.789 I slot get_availabl: id  2 | task -1 | selected slot by LCP similarity, sim_best = 0.889 (> 0.100 thold), f_keep = 1.000
2026-05-23 18:11:12.397 | 5.03.269.462 I reasoning-budget: activated, budget=2147483647 tokens
2026-05-23 18:11:12.397 | 5.03.269.545 I slot launch_slot_: id  2 | task 1369 | processing task, is_child = 0
2026-05-23 18:11:14.465 | 5.05.337.791 I slot create_check: id  2 | task 1369 | created context checkpoint 14 of 32 (pos_min = 35093, pos_max = 35093, n_tokens = 35094, size = 223.122 MiB)
2026-05-23 18:11:15.015 | 5.05.887.777 I slot create_check: id  2 | task 1369 | created context checkpoint 15 of 32 (pos_min = 35605, pos_max = 35605, n_tokens = 35606, size = 224.195 MiB)
2026-05-23 18:11:14.963 | 5.05.835.197 I reasoning-budget: deactivated (natural end)
2026-05-23 18:11:15.877 | 5.06.749.322 I slot print_timing: id  2 | task 1369 | n_decoded =    102, tg =  90.38 t/s
2026-05-23 18:11:18.321 | 5.09.193.422 I slot print_timing: id  2 | task 1369 | 
2026-05-23 18:11:18.321 | prompt eval time =    2656.42 ms /  3965 tokens (    0.67 ms per token,  1492.61 tokens per second)
2026-05-23 18:11:18.321 |        eval time =    3766.84 ms /   341 tokens (   11.05 ms per token,    90.53 tokens per second)
2026-05-23 18:11:18.321 |       total time =    6423.26 ms /  4306 tokens
2026-05-23 18:11:18.321 | draft acceptance rate = 0.99123 (  226 accepted /   228 generated)
2026-05-23 18:11:18.321 | 5.09.193.457 I statistics draft-mtp: #calls(b,g,a) = 9 1443 1468, #gen drafts = 1468, #acc drafts = 1399, #gen tokens = 2936, #acc tokens = 2729, dur(b,g,a) = 0.014, 6648.655, 3.171 ms
2026-05-23 18:11:18.322 | 5.09.194.478 I slot      release: id  2 | task 1369 | stop processing: n_tokens = 35950, truncated = 0
2026-05-23 18:11:18.322 | 5.09.194.546 I srv  update_slots: all slots are idle
2026-05-23 18:11:18.541 | 5.09.413.659 I srv  params_from_: Chat format: peg-native
2026-05-23 18:11:18.543 | 5.09.415.025 I slot get_availabl: id  2 | task -1 | selected slot by LCP similarity, sim_best = 0.915 (> 0.100 thold), f_keep = 1.000
2026-05-23 18:11:18.543 | 5.09.415.705 I reasoning-budget: activated, budget=2147483647 tokens
2026-05-23 18:11:18.543 | 5.09.415.786 I slot launch_slot_: id  2 | task 1488 | processing task, is_child = 0
2026-05-23 18:11:20.345 | 5.11.217.860 I slot create_check: id  2 | task 1488 | created context checkpoint 16 of 32 (pos_min = 38754, pos_max = 38754, n_tokens = 38755, size = 230.790 MiB)
2026-05-23 18:11:20.920 | 5.11.792.927 I slot create_check: id  2 | task 1488 | created context checkpoint 17 of 32 (pos_min = 39266, pos_max = 39266, n_tokens = 39267, size = 231.862 MiB)
2026-05-23 18:11:21.238 | 5.12.110.082 I reasoning-budget: deactivated (natural end)
2026-05-23 18:11:22.137 | 5.13.009.557 I slot print_timing: id  2 | task 1488 | n_decoded =    101, tg =  85.93 t/s
2026-05-23 18:11:24.415 | 5.15.287.173 I slot print_timing: id  2 | task 1488 | 
2026-05-23 18:11:24.415 | prompt eval time =    2418.18 ms /  3321 tokens (    0.73 ms per token,  1373.35 tokens per second)
2026-05-23 18:11:24.415 |        eval time =    3953.63 ms /   345 tokens (   11.46 ms per token,    87.26 tokens per second)
2026-05-23 18:11:24.415 |       total time =    6371.81 ms /  3666 tokens
2026-05-23 18:11:24.415 | draft acceptance rate = 0.97863 (  229 accepted /   234 generated)
2026-05-23 18:11:24.415 | 5.15.287.209 I statistics draft-mtp: #calls(b,g,a) = 10 1560 1585, #gen drafts = 1585, #acc drafts = 1515, #gen tokens = 3170, #acc tokens = 2958, dur(b,g,a) = 0.016, 7207.219, 3.464 ms
2026-05-23 18:11:24.416 | 5.15.288.289 I slot      release: id  2 | task 1488 | stop processing: n_tokens = 39617, truncated = 0
2026-05-23 18:11:24.416 | 5.15.288.358 I srv  update_slots: all slots are idle
2026-05-23 18:11:24.624 | 5.15.496.788 I srv  params_from_: Chat format: peg-native
2026-05-23 18:11:24.626 | 5.15.498.179 I slot get_availabl: id  2 | task -1 | selected slot by LCP similarity, sim_best = 0.925 (> 0.100 thold), f_keep = 1.000
2026-05-23 18:11:24.626 | 5.15.498.921 I reasoning-budget: activated, budget=2147483647 tokens
2026-05-23 18:11:24.626 | 5.15.499.003 I slot launch_slot_: id  2 | task 1610 | processing task, is_child = 0
2026-05-23 18:11:26.471 | 5.17.343.900 I slot create_check: id  2 | task 1610 | created context checkpoint 18 of 32 (pos_min = 42299, pos_max = 42299, n_tokens = 42300, size = 238.214 MiB)
2026-05-23 18:11:27.062 | 5.17.933.964 I slot create_check: id  2 | task 1610 | created context checkpoint 19 of 32 (pos_min = 42811, pos_max = 42811, n_tokens = 42812, size = 239.286 MiB)
2026-05-23 18:11:27.118 | 5.17.990.159 I reasoning-budget: deactivated (natural end)
2026-05-23 18:11:27.858 | 5.18.730.068 I slot print_timing: id  2 | task 1610 | n_decoded =    102, tg =  81.20 t/s
2026-05-23 18:11:27.991 | 5.18.863.526 I slot print_timing: id  2 | task 1610 | 
2026-05-23 18:11:27.991 | prompt eval time =    2475.12 ms /  3199 tokens (    0.77 ms per token,  1292.46 tokens per second)
2026-05-23 18:11:27.991 |        eval time =    1389.60 ms /   114 tokens (   12.19 ms per token,    82.04 tokens per second)
2026-05-23 18:11:27.991 |       total time =    3864.72 ms /  3313 tokens
2026-05-23 18:11:27.991 | draft acceptance rate = 0.87805 (   72 accepted /    82 generated)
2026-05-23 18:11:27.991 | 5.18.863.564 I statistics draft-mtp: #calls(b,g,a) = 11 1601 1626, #gen drafts = 1626, #acc drafts = 1553, #gen tokens = 3252, #acc tokens = 3030, dur(b,g,a) = 0.018, 7405.867, 3.550 ms
2026-05-23 18:11:27.992 | 5.18.864.725 I slot      release: id  2 | task 1610 | stop processing: n_tokens = 42929, truncated = 0
2026-05-23 18:11:27.992 | 5.18.864.787 I srv  update_slots: all slots are idle
2026-05-23 18:11:28.219 | 5.19.091.652 I srv  params_from_: Chat format: peg-native
2026-05-23 18:11:28.221 | 5.19.093.031 I slot get_availabl: id  2 | task -1 | selected slot by LCP similarity, sim_best = 0.988 (> 0.100 thold), f_keep = 1.000
2026-05-23 18:11:28.221 | 5.19.093.711 I reasoning-budget: activated, budget=2147483647 tokens
2026-05-23 18:11:28.221 | 5.19.093.796 I slot launch_slot_: id  2 | task 1656 | processing task, is_child = 0
2026-05-23 18:11:28.518 | 5.19.390.481 I slot create_check: id  2 | task 1656 | created context checkpoint 20 of 32 (pos_min = 42928, pos_max = 42928, n_tokens = 42929, size = 239.531 MiB)
2026-05-23 18:11:29.111 | 5.19.983.383 I slot create_check: id  2 | task 1656 | created context checkpoint 21 of 32 (pos_min = 43435, pos_max = 43435, n_tokens = 43436, size = 240.593 MiB)
2026-05-23 18:11:29.679 | 5.20.551.057 I reasoning-budget: deactivated (natural end)
2026-05-23 18:11:30.891 | 5.21.763.349 I slot print_timing: id  2 | task 1656 | n_decoded =    141, tg =  81.03 t/s
2026-05-23 18:11:31.878 | 5.22.749.923 I slot print_timing: id  2 | task 1656 | 
2026-05-23 18:11:31.878 | prompt eval time =     929.17 ms /   511 tokens (    1.82 ms per token,   549.95 tokens per second)
2026-05-23 18:11:31.878 |        eval time =    2726.74 ms /   228 tokens (   11.96 ms per token,    83.62 tokens per second)
2026-05-23 18:11:31.878 |       total time =    3655.91 ms /   739 tokens
2026-05-23 18:11:31.878 | draft acceptance rate = 0.93671 (  148 accepted /   158 generated)
2026-05-23 18:11:31.878 | 5.22.749.961 I statistics draft-mtp: #calls(b,g,a) = 12 1680 1705, #gen drafts = 1705, #acc drafts = 1628, #gen tokens = 3410, #acc tokens = 3178, dur(b,g,a) = 0.021, 7794.453, 3.718 ms
2026-05-23 18:11:31.879 | 5.22.751.228 I slot      release: id  2 | task 1656 | stop processing: n_tokens = 43667, truncated = 0
2026-05-23 18:11:31.879 | 5.22.751.302 I srv  update_slots: all slots are idle
2026-05-23 18:11:32.140 | 5.23.012.545 I srv  params_from_: Chat format: peg-native
2026-05-23 18:11:32.141 | 5.23.013.940 I slot get_availabl: id  2 | task -1 | selected slot by LCP similarity, sim_best = 0.989 (> 0.100 thold), f_keep = 1.000
2026-05-23 18:11:32.142 | 5.23.014.698 I reasoning-budget: activated, budget=2147483647 tokens
2026-05-23 18:11:32.142 | 5.23.014.788 I slot launch_slot_: id  2 | task 1738 | processing task, is_child = 0
2026-05-23 18:11:31.918 | 5.22.789.997 I slot create_check: id  2 | task 1738 | created context checkpoint 22 of 32 (pos_min = 43666, pos_max = 43666, n_tokens = 43667, size = 241.077 MiB)
2026-05-23 18:11:32.491 | 5.23.363.088 I slot create_check: id  2 | task 1738 | created context checkpoint 23 of 32 (pos_min = 44144, pos_max = 44144, n_tokens = 44145, size = 242.078 MiB)
2026-05-23 18:11:32.915 | 5.23.786.947 I reasoning-budget: deactivated (natural end)
2026-05-23 18:11:34.129 | 5.25.001.756 I slot print_timing: id  2 | task 1738 | n_decoded =    102, tg =  63.80 t/s
2026-05-23 18:11:37.137 | 5.28.009.135 I slot print_timing: id  2 | task 1738 | n_decoded =    342, tg =  74.25 t/s
2026-05-23 18:11:39.673 | 5.30.545.362 I slot print_timing: id  2 | task 1738 | n_decoded =    556, tg =  72.81 t/s
2026-05-23 18:11:42.158 | 5.33.029.970 I slot print_timing: id  2 | task 1738 | n_decoded =    756, tg =  71.03 t/s
2026-05-23 18:11:45.180 | 5.36.052.717 I slot print_timing: id  2 | task 1738 | n_decoded =    957, tg =  70.02 t/s
2026-05-23 18:11:47.722 | 5.38.594.615 I slot print_timing: id  2 | task 1738 | n_decoded =   1162, tg =  69.64 t/s
2026-05-23 18:11:50.619 | 5.41.491.390 I slot print_timing: id  2 | task 1738 | 
2026-05-23 18:11:50.619 | prompt eval time =     896.01 ms /   482 tokens (    1.86 ms per token,   537.94 tokens per second)
2026-05-23 18:11:50.619 |        eval time =   19583.63 ms /  1356 tokens (   14.44 ms per token,    69.24 tokens per second)
2026-05-23 18:11:50.619 |       total time =   20479.64 ms /  1838 tokens
2026-05-23 18:11:50.619 | draft acceptance rate = 0.66609 (  774 accepted /  1162 generated)
2026-05-23 18:11:50.619 | 5.41.491.424 I statistics draft-mtp: #calls(b,g,a) = 13 2261 2286, #gen drafts = 2286, #acc drafts = 2073, #gen tokens = 4572, #acc tokens = 3952, dur(b,g,a) = 0.023, 10642.036, 4.997 ms
2026-05-23 18:11:50.620 | 5.41.492.708 I slot      release: id  2 | task 1738 | stop processing: n_tokens = 45504, truncated = 0
2026-05-23 18:11:50.620 | 5.41.492.786 I srv  update_slots: all slots are idle
2026-05-23 18:13:14.312 | 7.05.183.948 I srv  params_from_: Chat format: peg-native
2026-05-23 18:13:14.313 | 7.05.185.301 I slot get_availabl: id  2 | task -1 | selected slot by LCP similarity, sim_best = 0.998 (> 0.100 thold), f_keep = 1.000
2026-05-23 18:13:14.314 | 7.05.186.081 I reasoning-budget: activated, budget=2147483647 tokens
2026-05-23 18:13:14.314 | 7.05.186.166 I slot launch_slot_: id  2 | task 2322 | processing task, is_child = 0
2026-05-23 18:13:14.672 | 7.05.544.024 I slot create_check: id  2 | task 2322 | created context checkpoint 24 of 32 (pos_min = 45503, pos_max = 45503, n_tokens = 45504, size = 244.924 MiB)
2026-05-23 18:13:15.140 | 7.06.012.381 I slot create_check: id  2 | task 2322 | created context checkpoint 25 of 32 (pos_min = 45594, pos_max = 45594, n_tokens = 45595, size = 245.114 MiB)
2026-05-23 18:13:15.741 | 7.06.613.128 I reasoning-budget: deactivated (natural end)
2026-05-23 18:13:16.443 | 7.07.315.162 I slot print_timing: id  2 | task 2322 | n_decoded =    102, tg =  80.69 t/s
2026-05-23 18:13:18.971 | 7.09.842.994 I slot print_timing: id  2 | task 2322 | n_decoded =    340, tg =  79.21 t/s
2026-05-23 18:13:22.004 | 7.12.876.109 I slot print_timing: id  2 | task 2322 | n_decoded =    566, tg =  77.26 t/s
2026-05-23 18:13:22.322 | 7.13.194.092 W srv          stop: cancel task, id_task = 2322
2026-05-23 18:13:22.354 | 7.13.226.890 I slot      release: id  2 | task 2322 | stop processing: n_tokens = 46225, truncated = 0
2026-05-23 18:13:22.354 | 7.13.226.963 I srv  update_slots: all slots are idle
2026-05-23 18:13:36.245 | 7.27.117.303 I srv  params_from_: Chat format: peg-native
2026-05-23 18:13:36.246 | 7.27.118.625 I slot get_availabl: id  2 | task -1 | selected slot by LCP similarity, sim_best = 0.189 (> 0.100 thold), f_keep = 0.184
2026-05-23 18:13:36.246 | 7.27.118.647 I srv  get_availabl: updating prompt cache
2026-05-23 18:13:36.248 | 7.27.120.679 W srv   prompt_save:  - saving prompt with length 46225, total state size = 1782.130 MiB (draft: 96.808 MiB)
2026-05-23 18:13:43.294 | 7.34.166.319 I srv          load:  - looking for better prompt, base f_keep = 0.184, sim = 0.189
2026-05-23 18:13:43.294 | 7.34.166.357 I srv        update:  - cache state: 2 prompts, 7594.318 MiB (limits: 8192.000 MiB, 131072 tokens, 131072 est)
2026-05-23 18:13:43.294 | 7.34.166.362 I srv        update:    - prompt 0x63d3aecbf9f0:    1630 tokens, checkpoints:  2,   509.021 MiB
2026-05-23 18:13:43.294 | 7.34.166.363 I srv        update:    - prompt 0x63d3af0f95b0:   46225 tokens, checkpoints: 25,  7085.298 MiB
2026-05-23 18:13:43.294 | 7.34.166.364 I srv  get_availabl: prompt cache update took 8054.42 ms
2026-05-23 18:13:43.294 | 7.34.167.005 I reasoning-budget: activated, budget=2147483647 tokens
2026-05-23 18:13:43.295 | 7.34.167.120 I slot launch_slot_: id  2 | task 2571 | processing task, is_child = 0
2026-05-23 18:13:43.295 | 7.34.167.155 W slot update_slots: id  2 | task 2571 | n_past = 8525, slot.prompt.tokens.size() = 46225, seq_id = 2, pos_min = 46224, n_swa = 0
2026-05-23 18:13:43.295 | 7.34.167.156 I slot update_slots: id  2 | task 2571 | Checking checkpoint with [45594, 45594] against 8525...
2026-05-23 18:13:43.295 | 7.34.167.157 I slot update_slots: id  2 | task 2571 | Checking checkpoint with [45503, 45503] against 8525...
2026-05-23 18:13:43.295 | 7.34.167.157 I slot update_slots: id  2 | task 2571 | Checking checkpoint with [44144, 44144] against 8525...
2026-05-23 18:13:43.295 | 7.34.167.159 I slot update_slots: id  2 | task 2571 | Checking checkpoint with [43666, 43666] against 8525...
2026-05-23 18:13:43.295 | 7.34.167.159 I slot update_slots: id  2 | task 2571 | Checking checkpoint with [43435, 43435] against 8525...
2026-05-23 18:13:43.295 | 7.34.167.160 I slot update_slots: id  2 | task 2571 | Checking checkpoint with [42928, 42928] against 8525...
2026-05-23 18:13:43.295 | 7.34.167.161 I slot update_slots: id  2 | task 2571 | Checking checkpoint with [42811, 42811] against 8525...
2026-05-23 18:13:43.295 | 7.34.167.162 I slot update_slots: id  2 | task 2571 | Checking checkpoint with [42299, 42299] against 8525...
2026-05-23 18:13:43.295 | 7.34.167.162 I slot update_slots: id  2 | task 2571 | Checking checkpoint with [39266, 39266] against 8525...
2026-05-23 18:13:43.295 | 7.34.167.163 I slot update_slots: id  2 | task 2571 | Checking checkpoint with [38754, 38754] against 8525...
2026-05-23 18:13:43.295 | 7.34.167.163 I slot update_slots: id  2 | task 2571 | Checking checkpoint with [35605, 35605] against 8525...
2026-05-23 18:13:43.295 | 7.34.167.164 I slot update_slots: id  2 | task 2571 | Checking checkpoint with [35093, 35093] against 8525...
2026-05-23 18:13:43.295 | 7.34.167.164 I slot update_slots: id  2 | task 2571 | Checking checkpoint with [31036, 31036] against 8525...
2026-05-23 18:13:43.295 | 7.34.167.165 I slot update_slots: id  2 | task 2571 | Checking checkpoint with [30524, 30524] against 8525...
2026-05-23 18:13:43.295 | 7.34.167.166 I slot update_slots: id  2 | task 2571 | Checking checkpoint with [27730, 27730] against 8525...
2026-05-23 18:13:43.295 | 7.34.167.166 I slot update_slots: id  2 | task 2571 | Checking checkpoint with [27218, 27218] against 8525...
2026-05-23 18:13:43.295 | 7.34.167.167 I slot update_slots: id  2 | task 2571 | Checking checkpoint with [22219, 22219] against 8525...
2026-05-23 18:13:43.295 | 7.34.167.168 I slot update_slots: id  2 | task 2571 | Checking checkpoint with [21707, 21707] against 8525...
2026-05-23 18:13:43.295 | 7.34.167.168 I slot update_slots: id  2 | task 2571 | Checking checkpoint with [18489, 18489] against 8525...
2026-05-23 18:13:43.295 | 7.34.167.169 I slot update_slots: id  2 | task 2571 | Checking checkpoint with [17977, 17977] against 8525...
2026-05-23 18:13:43.295 | 7.34.167.169 I slot update_slots: id  2 | task 2571 | Checking checkpoint with [12621, 12621] against 8525...
2026-05-23 18:13:43.295 | 7.34.167.170 I slot update_slots: id  2 | task 2571 | Checking checkpoint with [12109, 12109] against 8525...
2026-05-23 18:13:43.295 | 7.34.167.170 I slot update_slots: id  2 | task 2571 | Checking checkpoint with [8835, 8835] against 8525...
2026-05-23 18:13:43.295 | 7.34.167.170 I slot update_slots: id  2 | task 2571 | Checking checkpoint with [8323, 8323] against 8525...
2026-05-23 18:13:43.322 | 7.34.194.599 W slot update_slots: id  2 | task 2571 | restored context checkpoint (pos_min = 8323, pos_max = 8323, n_tokens = 8324, n_past = 8324, size = 167.059 MiB)
2026-05-23 18:13:43.322 | 7.34.194.625 W slot update_slots: id  2 | task 2571 | erased invalidated context checkpoint (pos_min = 8835, pos_max = 8835, n_tokens = 8836, n_swa = 0, pos_next = 8324, size = 168.131 MiB)
2026-05-23 18:13:43.333 | 7.34.205.156 W slot update_slots: id  2 | task 2571 | erased invalidated context checkpoint (pos_min = 12109, pos_max = 12109, n_tokens = 12110, n_swa = 0, pos_next = 8324, size = 174.988 MiB)
2026-05-23 18:13:43.344 | 7.34.216.632 W slot update_slots: id  2 | task 2571 | erased invalidated context checkpoint (pos_min = 12621, pos_max = 12621, n_tokens = 12622, n_swa = 0, pos_next = 8324, size = 176.060 MiB)
2026-05-23 18:13:43.355 | 7.34.227.455 W slot update_slots: id  2 | task 2571 | erased invalidated context checkpoint (pos_min = 17977, pos_max = 17977, n_tokens = 17978, n_swa = 0, pos_next = 8324, size = 187.277 MiB)
2026-05-23 18:13:43.367 | 7.34.239.103 W slot update_slots: id  2 | task 2571 | erased invalidated context checkpoint (pos_min = 18489, pos_max = 18489, n_tokens = 18490, n_swa = 0, pos_next = 8324, size = 188.349 MiB)
2026-05-23 18:13:43.378 | 7.34.250.953 W slot update_slots: id  2 | task 2571 | erased invalidated context checkpoint (pos_min = 21707, pos_max = 21707, n_tokens = 21708, n_swa = 0, pos_next = 8324, size = 195.089 MiB)
2026-05-23 18:13:43.391 | 7.34.263.071 W slot update_slots: id  2 | task 2571 | erased invalidated context checkpoint (pos_min = 22219, pos_max = 22219, n_tokens = 22220, n_swa = 0, pos_next = 8324, size = 196.161 MiB)
2026-05-23 18:13:43.403 | 7.34.275.709 W slot update_slots: id  2 | task 2571 | erased invalidated context checkpoint (pos_min = 27218, pos_max = 27218, n_tokens = 27219, n_swa = 0, pos_next = 8324, size = 206.630 MiB)
2026-05-23 18:13:43.417 | 7.34.289.295 W slot update_slots: id  2 | task 2571 | erased invalidated context checkpoint (pos_min = 27730, pos_max = 27730, n_tokens = 27731, n_swa = 0, pos_next = 8324, size = 207.702 MiB)
2026-05-23 18:13:43.430 | 7.34.302.332 W slot update_slots: id  2 | task 2571 | erased invalidated context checkpoint (pos_min = 30524, pos_max = 30524, n_tokens = 30525, n_swa = 0, pos_next = 8324, size = 213.554 MiB)
2026-05-23 18:13:43.443 | 7.34.315.531 W slot update_slots: id  2 | task 2571 | erased invalidated context checkpoint (pos_min = 31036, pos_max = 31036, n_tokens = 31037, n_swa = 0, pos_next = 8324, size = 214.626 MiB)
2026-05-23 18:13:43.456 | 7.34.328.693 W slot update_slots: id  2 | task 2571 | erased invalidated context checkpoint (pos_min = 35093, pos_max = 35093, n_tokens = 35094, n_swa = 0, pos_next = 8324, size = 223.122 MiB)
2026-05-23 18:13:43.470 | 7.34.342.453 W slot update_slots: id  2 | task 2571 | erased invalidated context checkpoint (pos_min = 35605, pos_max = 35605, n_tokens = 35606, n_swa = 0, pos_next = 8324, size = 224.195 MiB)
2026-05-23 18:13:43.484 | 7.34.356.240 W slot update_slots: id  2 | task 2571 | erased invalidated context checkpoint (pos_min = 38754, pos_max = 38754, n_tokens = 38755, n_swa = 0, pos_next = 8324, size = 230.790 MiB)
2026-05-23 18:13:43.499 | 7.34.371.386 W slot update_slots: id  2 | task 2571 | erased invalidated context checkpoint (pos_min = 39266, pos_max = 39266, n_tokens = 39267, n_swa = 0, pos_next = 8324, size = 231.862 MiB)
2026-05-23 18:13:43.513 | 7.34.385.847 W slot update_slots: id  2 | task 2571 | erased invalidated context checkpoint (pos_min = 42299, pos_max = 42299, n_tokens = 42300, n_swa = 0, pos_next = 8324, size = 238.214 MiB)
2026-05-23 18:13:43.528 | 7.34.400.517 W slot update_slots: id  2 | task 2571 | erased invalidated context checkpoint (pos_min = 42811, pos_max = 42811, n_tokens = 42812, n_swa = 0, pos_next = 8324, size = 239.286 MiB)
2026-05-23 18:13:43.543 | 7.34.415.230 W slot update_slots: id  2 | task 2571 | erased invalidated context checkpoint (pos_min = 42928, pos_max = 42928, n_tokens = 42929, n_swa = 0, pos_next = 8324, size = 239.531 MiB)
2026-05-23 18:13:43.557 | 7.34.429.939 W slot update_slots: id  2 | task 2571 | erased invalidated context checkpoint (pos_min = 43435, pos_max = 43435, n_tokens = 43436, n_swa = 0, pos_next = 8324, size = 240.593 MiB)
2026-05-23 18:13:43.572 | 7.34.444.764 W slot update_slots: id  2 | task 2571 | erased invalidated context checkpoint (pos_min = 43666, pos_max = 43666, n_tokens = 43667, n_swa = 0, pos_next = 8324, size = 241.077 MiB)
2026-05-23 18:13:43.588 | 7.34.460.257 W slot update_slots: id  2 | task 2571 | erased invalidated context checkpoint (pos_min = 44144, pos_max = 44144, n_tokens = 44145, n_swa = 0, pos_next = 8324, size = 242.078 MiB)
2026-05-23 18:13:43.603 | 7.34.475.263 W slot update_slots: id  2 | task 2571 | erased invalidated context checkpoint (pos_min = 45503, pos_max = 45503, n_tokens = 45504, n_swa = 0, pos_next = 8324, size = 244.924 MiB)
2026-05-23 18:13:43.618 | 7.34.490.499 W slot update_slots: id  2 | task 2571 | erased invalidated context checkpoint (pos_min = 45594, pos_max = 45594, n_tokens = 45595, n_swa = 0, pos_next = 8324, size = 245.114 MiB)
2026-05-23 18:13:47.093 | 7.37.965.656 I slot print_timing: id  2 | task 2571 | prompt processing, n_tokens =   8192, progress = 0.37, t =   3.80 s / 2156.64 tokens per second
2026-05-23 18:13:47.093 | 7.37.965.857 I slot update_slots: id  2 | task 2571 | 8192 tokens since last checkpoint at 8324, creating new checkpoint during processing at position 18564
2026-05-23 18:13:47.245 | 7.38.117.148 I slot create_check: id  2 | task 2571 | created context checkpoint 3 of 32 (pos_min = 16515, pos_max = 16515, n_tokens = 16516, size = 184.215 MiB)
2026-05-23 18:13:47.635 | 7.38.507.719 I slot print_timing: id  2 | task 2571 | prompt processing, n_tokens =  10240, progress = 0.41, t =   4.84 s / 2114.91 tokens per second
2026-05-23 18:13:48.549 | 7.39.421.344 I slot print_timing: id  2 | task 2571 | prompt processing, n_tokens =  12288, progress = 0.46, t =   5.76 s / 2135.02 tokens per second
2026-05-23 18:13:49.484 | 7.40.356.027 I slot print_timing: id  2 | task 2571 | prompt processing, n_tokens =  14336, progress = 0.50, t =   6.69 s / 2142.86 tokens per second
2026-05-23 18:13:50.431 | 7.41.303.656 I slot print_timing: id  2 | task 2571 | prompt processing, n_tokens =  16384, progress = 0.55, t =   7.64 s / 2145.13 tokens per second
2026-05-23 18:13:50.431 | 7.41.303.862 I slot update_slots: id  2 | task 2571 | 8192 tokens since last checkpoint at 16516, creating new checkpoint during processing at position 26756
2026-05-23 18:13:50.683 | 7.41.555.522 I slot create_check: id  2 | task 2571 | created context checkpoint 4 of 32 (pos_min = 24707, pos_max = 24707, n_tokens = 24708, size = 201.371 MiB)
2026-05-23 18:13:51.656 | 7.42.528.350 I slot print_timing: id  2 | task 2571 | prompt processing, n_tokens =  18432, progress = 0.59, t =   8.86 s / 2079.79 tokens per second
2026-05-23 18:13:52.158 | 7.43.030.038 I slot print_timing: id  2 | task 2571 | prompt processing, n_tokens =  20480, progress = 0.64, t =   9.86 s / 2077.49 tokens per second
2026-05-23 18:13:53.166 | 7.44.038.263 I slot print_timing: id  2 | task 2571 | prompt processing, n_tokens =  22528, progress = 0.69, t =  10.87 s / 2073.20 tokens per second
2026-05-23 18:13:54.193 | 7.45.065.091 I slot print_timing: id  2 | task 2571 | prompt processing, n_tokens =  24576, progress = 0.73, t =  11.89 s / 2066.41 tokens per second
2026-05-23 18:13:54.193 | 7.45.065.291 I slot update_slots: id  2 | task 2571 | 8192 tokens since last checkpoint at 24708, creating new checkpoint during processing at position 34948
2026-05-23 18:13:54.467 | 7.45.339.609 I slot create_check: id  2 | task 2571 | created context checkpoint 5 of 32 (pos_min = 32899, pos_max = 32899, n_tokens = 32900, size = 218.528 MiB)
2026-05-23 18:13:55.515 | 7.46.387.679 I slot print_timing: id  2 | task 2571 | prompt processing, n_tokens =  26624, progress = 0.78, t =  13.22 s / 2014.58 tokens per second
2026-05-23 18:13:56.592 | 7.47.464.775 I slot print_timing: id  2 | task 2571 | prompt processing, n_tokens =  28672, progress = 0.82, t =  14.29 s / 2006.05 tokens per second
2026-05-23 18:13:57.204 | 7.48.076.030 I slot print_timing: id  2 | task 2571 | prompt processing, n_tokens =  30720, progress = 0.87, t =  15.40 s / 1994.32 tokens per second
2026-05-23 18:13:58.339 | 7.49.211.423 I slot print_timing: id  2 | task 2571 | prompt processing, n_tokens =  32768, progress = 0.91, t =  16.54 s / 1981.24 tokens per second
2026-05-23 18:13:58.339 | 7.49.211.630 I slot update_slots: id  2 | task 2571 | 8192 tokens since last checkpoint at 32900, creating new checkpoint during processing at position 43140
2026-05-23 18:14:04.533 | 7.55.405.039 I slot create_check: id  2 | task 2571 | created context checkpoint 6 of 32 (pos_min = 41091, pos_max = 41091, n_tokens = 41092, size = 235.684 MiB)
2026-05-23 18:13:59.632 | 7.50.504.629 I slot print_timing: id  2 | task 2571 | prompt processing, n_tokens =  34816, progress = 0.96, t =  17.98 s / 1935.99 tokens per second
2026-05-23 18:14:00.445 | 7.51.317.240 I slot print_timing: id  2 | task 2571 | prompt processing, n_tokens =  36184, progress = 0.99, t =  18.80 s / 1925.07 tokens per second
2026-05-23 18:14:00.743 | 7.51.615.472 I slot create_check: id  2 | task 2571 | created context checkpoint 7 of 32 (pos_min = 44507, pos_max = 44507, n_tokens = 44508, size = 242.838 MiB)
2026-05-23 18:14:01.044 | 7.51.916.144 I slot print_timing: id  2 | task 2571 | prompt processing, n_tokens =  36696, progress = 1.00, t =  19.40 s / 1892.02 tokens per second
2026-05-23 18:14:01.348 | 7.52.220.016 I slot create_check: id  2 | task 2571 | created context checkpoint 8 of 32 (pos_min = 45019, pos_max = 45019, n_tokens = 45020, size = 243.910 MiB)
2026-05-23 18:14:01.965 | 7.52.837.872 I reasoning-budget: deactivated (natural end)
2026-05-23 18:14:02.351 | 7.53.223.315 I slot print_timing: id  2 | task 2571 | n_decoded =    100, tg =  76.15 t/s
2026-05-23 18:14:05.351 | 7.56.223.529 I slot print_timing: id  2 | task 2571 | n_decoded =    355, tg =  82.30 t/s
2026-05-23 18:14:07.853 | 7.58.725.038 I slot print_timing: id  2 | task 2571 | n_decoded =    591, tg =  80.79 t/s
2026-05-23 18:14:10.860 | 8.01.732.294 I slot print_timing: id  2 | task 2571 | n_decoded =    812, tg =  78.66 t/s
2026-05-23 18:14:13.358 | 8.04.230.479 I slot print_timing: id  2 | task 2571 | n_decoded =   1022, tg =  76.68 t/s
2026-05-23 18:14:16.362 | 8.07.234.613 I slot print_timing: id  2 | task 2571 | n_decoded =   1254, tg =  76.78 t/s
2026-05-23 18:14:18.888 | 8.09.760.127 I slot print_timing: id  2 | task 2571 | n_decoded =   1490, tg =  76.99 t/s
2026-05-23 18:14:21.905 | 8.12.777.180 I slot print_timing: id  2 | task 2571 | n_decoded =   1736, tg =  77.60 t/s
2026-05-23 18:14:24.421 | 8.15.292.895 I slot print_timing: id  2 | task 2571 | n_decoded =   1990, tg =  78.39 t/s
2026-05-23 18:14:27.063 | 8.17.935.366 I slot print_timing: id  2 | task 2571 | n_decoded =   2247, tg =  79.12 t/s
2026-05-23 18:14:29.955 | 8.20.827.168 I slot print_timing: id  2 | task 2571 | n_decoded =   2476, tg =  78.78 t/s
2026-05-23 18:14:32.464 | 8.23.335.990 I slot print_timing: id  2 | task 2571 | n_decoded =   2714, tg =  78.81 t/s
2026-05-23 18:14:35.473 | 8.26.345.775 I slot print_timing: id  2 | task 2571 | n_decoded =   2945, tg =  78.64 t/s
2026-05-23 18:14:37.990 | 8.28.861.976 I slot print_timing: id  2 | task 2571 | n_decoded =   3197, tg =  79.01 t/s
2026-05-23 18:14:41.022 | 8.31.894.512 I slot print_timing: id  2 | task 2571 | n_decoded =   3450, tg =  79.32 t/s
2026-05-23 18:14:43.531 | 8.34.403.212 I slot print_timing: id  2 | task 2571 | n_decoded =   3665, tg =  78.82 t/s
2026-05-23 18:14:46.561 | 8.37.433.911 I slot print_timing: id  2 | task 2571 | n_decoded =   3903, tg =  78.80 t/s
2026-05-23 18:14:49.075 | 8.39.947.282 I slot print_timing: id  2 | task 2571 | n_decoded =   4139, tg =  78.77 t/s
2026-05-23 18:14:52.080 | 8.42.952.047 I slot print_timing: id  2 | task 2571 | n_decoded =   4348, tg =  78.27 t/s
2026-05-23 18:14:54.511 | 8.45.382.993 I slot print_timing: id  2 | task 2571 | n_decoded =   4563, tg =  77.90 t/s
2026-05-23 18:14:57.514 | 8.48.386.455 I slot print_timing: id  2 | task 2571 | n_decoded =   4758, tg =  77.27 t/s
2026-05-23 18:15:00.116 | 8.50.988.281 I slot print_timing: id  2 | task 2571 | n_decoded =   4975, tg =  77.02 t/s
2026-05-23 18:15:02.631 | 8.53.502.954 I slot print_timing: id  2 | task 2571 | n_decoded =   5168, tg =  76.44 t/s
2026-05-23 18:15:05.666 | 8.56.538.264 I slot print_timing: id  2 | task 2571 | n_decoded =   5412, tg =  76.61 t/s
2026-05-23 18:15:06.695 | 8.57.567.907 I slot print_timing: id  2 | task 2571 | 
2026-05-23 18:15:06.696 | prompt eval time =   19739.17 ms / 36700 tokens (    0.54 ms per token,  1859.25 tokens per second)
2026-05-23 18:15:06.696 |        eval time =   71673.91 ms /  5498 tokens (   13.04 ms per token,    76.71 tokens per second)
2026-05-23 18:15:06.696 |       total time =   91413.08 ms / 42198 tokens
2026-05-23 18:15:06.696 | draft acceptance rate = 0.80346 ( 3389 accepted /  4218 generated)
2026-05-23 18:15:06.696 | 8.57.567.944 I statistics draft-mtp: #calls(b,g,a) = 15 4615 4640, #gen drafts = 4640, #acc drafts = 4100, #gen tokens = 9280, #acc tokens = 7722, dur(b,g,a) = 0.025, 21928.733, 9.437 ms
2026-05-23 18:15:06.697 | 8.57.569.095 I slot      release: id  2 | task 2571 | stop processing: n_tokens = 50522, truncated = 0
2026-05-23 18:15:06.697 | 8.57.569.201 I srv  update_slots: all slots are idle
2026-05-23 18:15:06.951 | 8.57.823.848 I srv  params_from_: Chat format: peg-native
2026-05-23 18:15:06.953 | 8.57.825.210 I slot get_availabl: id  2 | task -1 | selected slot by LCP similarity, sim_best = 1.000 (> 0.100 thold), f_keep = 1.000
2026-05-23 18:15:06.953 | 8.57.825.935 I reasoning-budget: activated, budget=2147483647 tokens
2026-05-23 18:15:06.953 | 8.57.826.025 I slot launch_slot_: id  2 | task 4701 | processing task, is_child = 0
2026-05-23 18:15:07.219 | 8.58.091.110 I slot create_check: id  2 | task 4701 | created context checkpoint 9 of 32 (pos_min = 50521, pos_max = 50521, n_tokens = 50522, size = 255.433 MiB)
2026-05-23 18:15:07.541 | 8.58.412.997 I reasoning-budget: deactivated (natural end)
2026-05-23 18:15:08.269 | 8.59.141.857 I slot print_timing: id  2 | task 4701 | n_decoded =    100, tg =  68.89 t/s
2026-05-23 18:15:10.632 | 9.01.504.776 I slot print_timing: id  2 | task 4701 | 
2026-05-23 18:15:10.632 | prompt eval time =     359.21 ms /    20 tokens (   17.96 ms per token,    55.68 tokens per second)
2026-05-23 18:15:10.632 |        eval time =    3814.49 ms /   259 tokens (   14.73 ms per token,    67.90 tokens per second)
2026-05-23 18:15:10.632 |       total time =    4173.70 ms /   279 tokens
2026-05-23 18:15:10.632 | draft acceptance rate = 0.66216 (  147 accepted /   222 generated)
2026-05-23 18:15:10.632 | 9.01.504.810 I statistics draft-mtp: #calls(b,g,a) = 16 4726 4751, #gen drafts = 4751, #acc drafts = 4186, #gen tokens = 9502, #acc tokens = 7869, dur(b,g,a) = 0.027, 22470.930, 9.675 ms
2026-05-23 18:15:10.634 | 9.01.506.107 I slot      release: id  2 | task 4701 | stop processing: n_tokens = 50800, truncated = 0
2026-05-23 18:15:10.634 | 9.01.506.169 I srv  update_slots: all slots are idle
2026-05-23 18:18:58.572 | 12.49.444.342 I srv  params_from_: Chat format: peg-native
2026-05-23 18:18:58.573 | 12.49.445.722 I slot get_availabl: id  2 | task -1 | selected slot by LCP similarity, sim_best = 0.878 (> 0.100 thold), f_keep = 0.885
2026-05-23 18:18:58.574 | 12.49.446.398 I reasoning-budget: activated, budget=2147483647 tokens
2026-05-23 18:18:58.574 | 12.49.446.480 I slot launch_slot_: id  2 | task 4815 | processing task, is_child = 0
2026-05-23 18:18:58.574 | 12.49.446.540 W slot update_slots: id  2 | task 4815 | n_past = 44962, slot.prompt.tokens.size() = 50800, seq_id = 2, pos_min = 50799, n_swa = 0
2026-05-23 18:18:58.574 | 12.49.446.559 I slot update_slots: id  2 | task 4815 | Checking checkpoint with [50521, 50521] against 44962...
2026-05-23 18:18:58.574 | 12.49.446.559 I slot update_slots: id  2 | task 4815 | Checking checkpoint with [45019, 45019] against 44962...
2026-05-23 18:18:58.574 | 12.49.446.560 I slot update_slots: id  2 | task 4815 | Checking checkpoint with [44507, 44507] against 44962...
2026-05-23 18:18:58.678 | 12.49.550.136 W slot update_slots: id  2 | task 4815 | restored context checkpoint (pos_min = 44507, pos_max = 44507, n_tokens = 44508, n_past = 44508, size = 242.838 MiB)
2026-05-23 18:18:58.678 | 12.49.550.166 W slot update_slots: id  2 | task 4815 | erased invalidated context checkpoint (pos_min = 45019, pos_max = 45019, n_tokens = 45020, n_swa = 0, pos_next = 44508, size = 243.910 MiB)
2026-05-23 18:18:58.693 | 12.49.565.074 W slot update_slots: id  2 | task 4815 | erased invalidated context checkpoint (pos_min = 50521, pos_max = 50521, n_tokens = 50522, n_swa = 0, pos_next = 44508, size = 255.433 MiB)
2026-05-23 18:19:02.611 | 12.53.482.961 I slot print_timing: id  2 | task 4815 | prompt processing, n_tokens =   6144, progress = 0.99, t =   4.04 s / 1522.13 tokens per second
2026-05-23 18:19:02.677 | 12.53.549.064 I slot print_timing: id  2 | task 4815 | prompt processing, n_tokens =   6214, progress = 0.99, t =   4.10 s / 1514.67 tokens per second
2026-05-23 18:19:08.556 | 12.59.428.008 I slot create_check: id  2 | task 4815 | created context checkpoint 8 of 32 (pos_min = 50721, pos_max = 50721, n_tokens = 50722, size = 255.852 MiB)
2026-05-23 18:19:02.822 | 12.53.694.875 I slot print_timing: id  2 | task 4815 | prompt processing, n_tokens =   6726, progress = 1.00, t =   4.65 s / 1445.89 tokens per second
2026-05-23 18:19:03.132 | 12.54.004.681 I slot create_check: id  2 | task 4815 | created context checkpoint 9 of 32 (pos_min = 51233, pos_max = 51233, n_tokens = 51234, size = 256.924 MiB)
2026-05-23 18:19:04.339 | 12.55.211.887 I reasoning-budget: deactivated (natural end)
2026-05-23 18:19:04.406 | 12.55.278.797 I slot print_timing: id  2 | task 4815 | n_decoded =    101, tg =  81.87 t/s
2026-05-23 18:19:04.849 | 12.55.721.134 I slot print_timing: id  2 | task 4815 | 
2026-05-23 18:19:04.849 | prompt eval time =    5001.91 ms /  6730 tokens (    0.74 ms per token,  1345.49 tokens per second)
2026-05-23 18:19:04.849 |        eval time =    1675.99 ms /   139 tokens (   12.06 ms per token,    82.94 tokens per second)
2026-05-23 18:19:04.849 |       total time =    6677.90 ms /  6869 tokens
2026-05-23 18:19:04.849 | draft acceptance rate = 0.91837 (   90 accepted /    98 generated)
2026-05-23 18:19:04.849 | 12.55.721.168 I statistics draft-mtp: #calls(b,g,a) = 17 4775 4800, #gen drafts = 4800, #acc drafts = 4232, #gen tokens = 9600, #acc tokens = 7959, dur(b,g,a) = 0.028, 22702.349, 9.756 ms
2026-05-23 18:19:04.850 | 12.55.722.577 I slot      release: id  2 | task 4815 | stop processing: n_tokens = 51377, truncated = 0
2026-05-23 18:19:04.850 | 12.55.722.656 I srv  update_slots: all slots are idle
2026-05-23 18:19:05.077 | 12.55.949.136 I srv  params_from_: Chat format: peg-native
2026-05-23 18:19:05.078 | 12.55.950.490 I slot get_availabl: id  2 | task -1 | selected slot by LCP similarity, sim_best = 0.920 (> 0.100 thold), f_keep = 1.000
2026-05-23 18:19:05.079 | 12.55.951.133 I reasoning-budget: activated, budget=2147483647 tokens
2026-05-23 18:19:05.079 | 12.55.951.216 I slot launch_slot_: id  2 | task 4871 | processing task, is_child = 0
2026-05-23 18:19:07.956 | 12.58.827.988 I slot create_check: id  2 | task 4871 | created context checkpoint 10 of 32 (pos_min = 55311, pos_max = 55311, n_tokens = 55312, size = 265.464 MiB)
2026-05-23 18:19:07.794 | 12.58.666.033 I slot print_timing: id  2 | task 4871 | prompt processing, n_tokens =   4447, progress = 1.00, t =   3.21 s / 1385.68 tokens per second
2026-05-23 18:19:08.111 | 12.58.982.978 I slot create_check: id  2 | task 4871 | created context checkpoint 11 of 32 (pos_min = 55823, pos_max = 55823, n_tokens = 55824, size = 266.537 MiB)
2026-05-23 18:19:09.627 | 13.00.499.824 I slot print_timing: id  2 | task 4871 | n_decoded =    101, tg =  68.39 t/s
2026-05-23 18:19:12.659 | 13.03.531.886 I slot print_timing: id  2 | task 4871 | n_decoded =    315, tg =  69.86 t/s
2026-05-23 18:19:15.185 | 13.06.057.105 I slot print_timing: id  2 | task 4871 | n_decoded =    509, tg =  67.55 t/s
2026-05-23 18:19:17.068 | 13.07.940.306 I reasoning-budget: deactivated (natural end)
2026-05-23 18:19:17.624 | 13.08.496.807 I slot print_timing: id  2 | task 4871 | 
2026-05-23 18:19:17.624 | prompt eval time =    3566.02 ms /  4451 tokens (    0.80 ms per token,  1248.17 tokens per second)
2026-05-23 18:19:17.624 |        eval time =    9975.15 ms /   664 tokens (   15.02 ms per token,    66.57 tokens per second)
2026-05-23 18:19:17.624 |       total time =   13541.17 ms /  5115 tokens
2026-05-23 18:19:17.624 | draft acceptance rate = 0.63699 (  372 accepted /   584 generated)
2026-05-23 18:19:17.624 | 13.08.496.843 I statistics draft-mtp: #calls(b,g,a) = 18 5067 5092, #gen drafts = 5092, #acc drafts = 4450, #gen tokens = 10184, #acc tokens = 8331, dur(b,g,a) = 0.029, 24106.320, 10.279 ms
2026-05-23 18:19:17.626 | 13.08.498.258 I slot      release: id  2 | task 4871 | stop processing: n_tokens = 56492, truncated = 0
2026-05-23 18:19:17.626 | 13.08.498.326 I srv  update_slots: all slots are idle
2026-05-23 18:19:17.871 | 13.08.743.455 I srv  params_from_: Chat format: peg-native
2026-05-23 18:19:17.872 | 13.08.744.814 I slot get_availabl: id  2 | task -1 | selected slot by LCP similarity, sim_best = 0.881 (> 0.100 thold), f_keep = 1.000
2026-05-23 18:19:17.873 | 13.08.745.503 I reasoning-budget: activated, budget=2147483647 tokens
2026-05-23 18:19:17.873 | 13.08.745.581 I slot launch_slot_: id  2 | task 5168 | processing task, is_child = 0
2026-05-23 18:19:21.657 | 13.12.529.666 I slot print_timing: id  2 | task 5168 | prompt processing, n_tokens =   6144, progress = 0.98, t =   4.29 s / 1433.70 tokens per second
2026-05-23 18:19:22.332 | 13.13.204.301 I slot print_timing: id  2 | task 5168 | prompt processing, n_tokens =   7085, progress = 0.99, t =   4.96 s / 1428.41 tokens per second
2026-05-23 18:19:22.667 | 13.13.539.574 I slot create_check: id  2 | task 5168 | created context checkpoint 12 of 32 (pos_min = 63576, pos_max = 63576, n_tokens = 63577, size = 282.773 MiB)
2026-05-23 18:19:23.039 | 13.13.911.423 I slot print_timing: id  2 | task 5168 | prompt processing, n_tokens =   7597, progress = 1.00, t =   5.67 s / 1340.53 tokens per second
2026-05-23 18:19:22.884 | 13.13.756.150 I slot create_check: id  2 | task 5168 | created context checkpoint 13 of 32 (pos_min = 64088, pos_max = 64088, n_tokens = 64089, size = 283.846 MiB)
2026-05-23 18:19:24.594 | 13.15.466.752 I slot print_timing: id  2 | task 5168 | n_decoded =    101, tg =  60.47 t/s
2026-05-23 18:19:26.474 | 13.17.346.075 I reasoning-budget: deactivated (natural end)
2026-05-23 18:19:27.284 | 13.18.156.515 I slot print_timing: id  2 | task 5168 | n_decoded =    295, tg =  63.04 t/s
2026-05-23 18:19:30.119 | 13.20.991.325 I slot print_timing: id  2 | task 5168 | n_decoded =    499, tg =  64.90 t/s
2026-05-23 18:19:32.641 | 13.23.513.693 I slot print_timing: id  2 | task 5168 | n_decoded =    693, tg =  64.70 t/s
2026-05-23 18:19:35.662 | 13.26.533.969 I slot print_timing: id  2 | task 5168 | n_decoded =    927, tg =  67.51 t/s
2026-05-23 18:19:38.161 | 13.29.033.503 I slot print_timing: id  2 | task 5168 | n_decoded =   1169, tg =  69.86 t/s
2026-05-23 18:19:41.190 | 13.32.062.115 I slot print_timing: id  2 | task 5168 | n_decoded =   1401, tg =  70.90 t/s
2026-05-23 18:19:43.696 | 13.34.568.506 I slot print_timing: id  2 | task 5168 | n_decoded =   1601, tg =  70.32 t/s
2026-05-23 18:19:46.725 | 13.37.597.296 I slot print_timing: id  2 | task 5168 | n_decoded =   1817, tg =  70.43 t/s
2026-05-23 18:19:49.235 | 13.40.107.516 I slot print_timing: id  2 | task 5168 | n_decoded =   2026, tg =  70.33 t/s
2026-05-23 18:19:52.267 | 13.43.138.955 I slot print_timing: id  2 | task 5168 | n_decoded =   2262, tg =  71.04 t/s
2026-05-23 18:19:54.738 | 13.45.610.152 I slot print_timing: id  2 | task 5168 | n_decoded =   2497, tg =  71.63 t/s
2026-05-23 18:19:57.755 | 13.48.626.968 I slot print_timing: id  2 | task 5168 | n_decoded =   2739, tg =  72.31 t/s
2026-05-23 18:20:00.328 | 13.51.199.998 I slot print_timing: id  2 | task 5168 | n_decoded =   2979, tg =  72.82 t/s
2026-05-23 18:20:02.834 | 13.53.706.745 I slot print_timing: id  2 | task 5168 | n_decoded =   3217, tg =  73.25 t/s
2026-05-23 18:20:05.840 | 13.56.712.414 I slot print_timing: id  2 | task 5168 | n_decoded =   3441, tg =  73.34 t/s
2026-05-23 18:20:08.352 | 13.59.224.058 I slot print_timing: id  2 | task 5168 | n_decoded =   3683, tg =  73.77 t/s
2026-05-23 18:20:11.368 | 14.02.240.387 I slot print_timing: id  2 | task 5168 | n_decoded =   3924, tg =  74.12 t/s
2026-05-23 18:20:13.893 | 14.04.765.035 I slot print_timing: id  2 | task 5168 | n_decoded =   4153, tg =  74.20 t/s
2026-05-23 18:20:16.916 | 14.07.788.783 I slot print_timing: id  2 | task 5168 | n_decoded =   4389, tg =  74.40 t/s
2026-05-23 18:20:19.429 | 14.10.301.592 I slot print_timing: id  2 | task 5168 | n_decoded =   4616, tg =  74.44 t/s
2026-05-23 18:20:22.172 | 14.13.044.059 I slot print_timing: id  2 | task 5168 | n_decoded =   4836, tg =  74.38 t/s
2026-05-23 18:20:24.965 | 14.15.837.391 I slot print_timing: id  2 | task 5168 | n_decoded =   5060, tg =  74.37 t/s
2026-05-23 18:20:27.979 | 14.18.851.377 I slot print_timing: id  2 | task 5168 | n_decoded =   5253, tg =  73.93 t/s
2026-05-23 18:20:30.484 | 14.21.356.483 I slot print_timing: id  2 | task 5168 | n_decoded =   5459, tg =  73.71 t/s
2026-05-23 18:20:32.981 | 14.23.853.637 I slot print_timing: id  2 | task 5168 | n_decoded =   5667, tg =  73.53 t/s
2026-05-23 18:20:35.990 | 14.26.862.047 I slot print_timing: id  2 | task 5168 | n_decoded =   5860, tg =  73.18 t/s
2026-05-23 18:20:38.543 | 14.29.415.778 I slot print_timing: id  2 | task 5168 | n_decoded =   6054, tg =  72.83 t/s
2026-05-23 18:20:41.545 | 14.32.416.968 I slot print_timing: id  2 | task 5168 | n_decoded =   6256, tg =  72.63 t/s
2026-05-23 18:20:44.078 | 14.34.950.073 I slot print_timing: id  2 | task 5168 | n_decoded =   6451, tg =  72.35 t/s
2026-05-23 18:20:47.094 | 14.37.966.765 I slot print_timing: id  2 | task 5168 | n_decoded =   6670, tg =  72.36 t/s
2026-05-23 18:20:49.609 | 14.40.481.135 I slot print_timing: id  2 | task 5168 | n_decoded =   6890, tg =  72.38 t/s
2026-05-23 18:20:50.593 | 14.41.465.209 I slot print_timing: id  2 | task 5168 | 
2026-05-23 18:20:50.593 | prompt eval time =    6059.83 ms /  7601 tokens (    0.80 ms per token,  1254.33 tokens per second)
2026-05-23 18:20:50.593 |        eval time =   96180.13 ms /  6965 tokens (   13.81 ms per token,    72.42 tokens per second)
2026-05-23 18:20:50.593 |       total time =  102239.96 ms / 14566 tokens
2026-05-23 18:20:50.593 | draft acceptance rate = 0.83872 ( 4363 accepted /  5202 generated)
2026-05-23 18:20:50.593 | 14.41.465.248 I statistics draft-mtp: #calls(b,g,a) = 19 7668 7693, #gen drafts = 7693, #acc drafts = 6769, #gen tokens = 15386, #acc tokens = 12694, dur(b,g,a) = 0.030, 37211.373, 15.318 ms
2026-05-23 18:20:50.595 | 14.41.466.966 I slot      release: id  2 | task 5168 | stop processing: n_tokens = 71057, truncated = 0
2026-05-23 18:20:50.595 | 14.41.467.089 I srv  update_slots: all slots are idle
2026-05-23 18:20:50.931 | 14.41.803.034 I srv  params_from_: Chat format: peg-native
2026-05-23 18:20:50.932 | 14.41.804.459 I slot get_availabl: id  2 | task -1 | selected slot by LCP similarity, sim_best = 1.000 (> 0.100 thold), f_keep = 1.000
2026-05-23 18:20:50.933 | 14.41.805.166 I reasoning-budget: activated, budget=2147483647 tokens
2026-05-23 18:20:50.933 | 14.41.805.259 I slot launch_slot_: id  2 | task 7776 | processing task, is_child = 0
2026-05-23 18:20:51.308 | 14.42.180.401 I slot create_check: id  2 | task 7776 | created context checkpoint 14 of 32 (pos_min = 71056, pos_max = 71056, n_tokens = 71057, size = 298.439 MiB)
2026-05-23 18:20:51.698 | 14.42.570.795 I reasoning-budget: deactivated (natural end)
2026-05-23 18:20:53.069 | 14.43.941.872 I slot print_timing: id  2 | task 7776 | n_decoded =    102, tg =  61.68 t/s
2026-05-23 18:20:55.611 | 14.46.483.425 I slot print_timing: id  2 | task 7776 | n_decoded =    276, tg =  58.86 t/s
2026-05-23 18:20:55.759 | 14.46.631.084 I slot print_timing: id  2 | task 7776 | 
2026-05-23 18:20:55.759 | prompt eval time =     482.62 ms /    21 tokens (   22.98 ms per token,    43.51 tokens per second)
2026-05-23 18:20:55.759 |        eval time =    4836.85 ms /   284 tokens (   17.03 ms per token,    58.72 tokens per second)
2026-05-23 18:20:55.759 |       total time =    5319.47 ms /   305 tokens
2026-05-23 18:20:55.759 | draft acceptance rate = 0.60078 (  155 accepted /   258 generated)
2026-05-23 18:20:55.759 | 14.46.631.117 I statistics draft-mtp: #calls(b,g,a) = 20 7797 7822, #gen drafts = 7822, #acc drafts = 6865, #gen tokens = 15644, #acc tokens = 12849, dur(b,g,a) = 0.032, 37876.098, 15.618 ms
2026-05-23 18:20:55.760 | 14.46.632.825 I slot      release: id  2 | task 7776 | stop processing: n_tokens = 71362, truncated = 0
2026-05-23 18:20:55.760 | 14.46.632.892 I srv  update_slots: all slots are idle
2026-05-23 18:22:37.060 | 16.27.932.045 I srv  params_from_: Chat format: peg-native
2026-05-23 18:22:37.061 | 16.27.933.415 I slot get_availabl: id  2 | task -1 | selected slot by LCP similarity, sim_best = 0.721 (> 0.100 thold), f_keep = 0.717
2026-05-23 18:22:37.062 | 16.27.934.101 I reasoning-budget: activated, budget=2147483647 tokens
2026-05-23 18:22:37.062 | 16.27.934.182 I slot launch_slot_: id  2 | task 7908 | processing task, is_child = 0
2026-05-23 18:22:37.062 | 16.27.934.248 W slot update_slots: id  2 | task 7908 | n_past = 51176, slot.prompt.tokens.size() = 71362, seq_id = 2, pos_min = 71361, n_swa = 0
2026-05-23 18:22:37.062 | 16.27.934.249 I slot update_slots: id  2 | task 7908 | Checking checkpoint with [71056, 71056] against 51176...
2026-05-23 18:22:37.062 | 16.27.934.250 I slot update_slots: id  2 | task 7908 | Checking checkpoint with [64088, 64088] against 51176...
2026-05-23 18:22:37.062 | 16.27.934.251 I slot update_slots: id  2 | task 7908 | Checking checkpoint with [63576, 63576] against 51176...
2026-05-23 18:22:37.062 | 16.27.934.252 I slot update_slots: id  2 | task 7908 | Checking checkpoint with [55823, 55823] against 51176...
2026-05-23 18:22:37.062 | 16.27.934.252 I slot update_slots: id  2 | task 7908 | Checking checkpoint with [55311, 55311] against 51176...
2026-05-23 18:22:37.062 | 16.27.934.252 I slot update_slots: id  2 | task 7908 | Checking checkpoint with [51233, 51233] against 51176...
2026-05-23 18:22:37.062 | 16.27.934.254 I slot update_slots: id  2 | task 7908 | Checking checkpoint with [50721, 50721] against 51176...
2026-05-23 18:22:37.172 | 16.28.044.571 W slot update_slots: id  2 | task 7908 | restored context checkpoint (pos_min = 50721, pos_max = 50721, n_tokens = 50722, n_past = 50722, size = 255.852 MiB)
2026-05-23 18:22:37.172 | 16.28.044.600 W slot update_slots: id  2 | task 7908 | erased invalidated context checkpoint (pos_min = 51233, pos_max = 51233, n_tokens = 51234, n_swa = 0, pos_next = 50722, size = 256.924 MiB)
2026-05-23 18:22:37.189 | 16.28.061.471 W slot update_slots: id  2 | task 7908 | erased invalidated context checkpoint (pos_min = 55311, pos_max = 55311, n_tokens = 55312, n_swa = 0, pos_next = 50722, size = 265.464 MiB)
2026-05-23 18:22:37.205 | 16.28.077.748 W slot update_slots: id  2 | task 7908 | erased invalidated context checkpoint (pos_min = 55823, pos_max = 55823, n_tokens = 55824, n_swa = 0, pos_next = 50722, size = 266.537 MiB)
2026-05-23 18:22:37.222 | 16.28.094.693 W slot update_slots: id  2 | task 7908 | erased invalidated context checkpoint (pos_min = 63576, pos_max = 63576, n_tokens = 63577, n_swa = 0, pos_next = 50722, size = 282.773 MiB)
2026-05-23 18:22:37.240 | 16.28.112.604 W slot update_slots: id  2 | task 7908 | erased invalidated context checkpoint (pos_min = 64088, pos_max = 64088, n_tokens = 64089, n_swa = 0, pos_next = 50722, size = 283.846 MiB)
2026-05-23 18:22:37.258 | 16.28.130.434 W slot update_slots: id  2 | task 7908 | erased invalidated context checkpoint (pos_min = 71056, pos_max = 71056, n_tokens = 71057, n_swa = 0, pos_next = 50722, size = 298.439 MiB)
2026-05-23 18:22:40.062 | 16.30.934.316 I slot print_timing: id  2 | task 7908 | prompt processing, n_tokens =   4096, progress = 0.77, t =   3.11 s / 1315.21 tokens per second
2026-05-23 18:22:41.411 | 16.32.283.687 I slot print_timing: id  2 | task 7908 | prompt processing, n_tokens =   6144, progress = 0.80, t =   4.46 s / 1376.44 tokens per second
2026-05-23 18:22:42.802 | 16.33.674.168 I slot print_timing: id  2 | task 7908 | prompt processing, n_tokens =   8192, progress = 0.83, t =   5.85 s / 1399.34 tokens per second
2026-05-23 18:22:42.802 | 16.33.674.371 I slot update_slots: id  2 | task 7908 | 8192 tokens since last checkpoint at 50722, creating new checkpoint during processing at position 60962
2026-05-23 18:22:43.115 | 16.33.987.695 I slot create_check: id  2 | task 7908 | created context checkpoint 9 of 32 (pos_min = 58913, pos_max = 58913, n_tokens = 58914, size = 273.008 MiB)
2026-05-23 18:22:44.052 | 16.34.924.072 I slot print_timing: id  2 | task 7908 | prompt processing, n_tokens =  10240, progress = 0.86, t =   7.61 s / 1346.43 tokens per second
2026-05-23 18:22:45.526 | 16.36.398.099 I slot print_timing: id  2 | task 7908 | prompt processing, n_tokens =  12288, progress = 0.89, t =   9.08 s / 1353.40 tokens per second
2026-05-23 18:22:47.034 | 16.37.906.277 I slot print_timing: id  2 | task 7908 | prompt processing, n_tokens =  14336, progress = 0.92, t =  10.59 s / 1354.05 tokens per second
2026-05-23 18:22:48.070 | 16.38.942.007 I slot print_timing: id  2 | task 7908 | prompt processing, n_tokens =  16384, progress = 0.95, t =  12.12 s / 1351.41 tokens per second
2026-05-23 18:22:48.070 | 16.38.942.211 I slot update_slots: id  2 | task 7908 | 8192 tokens since last checkpoint at 58914, creating new checkpoint during processing at position 69154
2026-05-23 18:22:48.416 | 16.39.288.328 I slot create_check: id  2 | task 7908 | created context checkpoint 10 of 32 (pos_min = 67105, pos_max = 67105, n_tokens = 67106, size = 290.164 MiB)
2026-05-23 18:22:49.988 | 16.40.860.006 I slot print_timing: id  2 | task 7908 | prompt processing, n_tokens =  18432, progress = 0.97, t =  14.04 s / 1312.67 tokens per second
2026-05-23 18:22:51.038 | 16.41.910.575 I slot print_timing: id  2 | task 7908 | prompt processing, n_tokens =  19759, progress = 0.99, t =  15.09 s / 1309.22 tokens per second
2026-05-23 18:22:51.398 | 16.42.270.622 I slot create_check: id  2 | task 7908 | created context checkpoint 11 of 32 (pos_min = 70480, pos_max = 70480, n_tokens = 70481, size = 297.232 MiB)
2026-05-23 18:22:51.795 | 16.42.667.405 I slot print_timing: id  2 | task 7908 | prompt processing, n_tokens =  20271, progress = 1.00, t =  15.85 s / 1279.00 tokens per second
2026-05-23 18:22:52.162 | 16.43.034.601 I slot create_check: id  2 | task 7908 | created context checkpoint 12 of 32 (pos_min = 70992, pos_max = 70992, n_tokens = 70993, size = 298.305 MiB)
2026-05-23 18:22:53.265 | 16.44.137.092 I slot print_timing: id  2 | task 7908 | n_decoded =    101, tg =  64.65 t/s
2026-05-23 18:22:55.077 | 16.45.949.486 I reasoning-budget: deactivated (natural end)
2026-05-23 18:22:56.270 | 16.47.142.783 I slot print_timing: id  2 | task 7908 | n_decoded =    295, tg =  64.58 t/s
2026-05-23 18:22:58.799 | 16.49.671.736 I slot print_timing: id  2 | task 7908 | n_decoded =    500, tg =  65.81 t/s
2026-05-23 18:23:01.809 | 16.52.681.591 I slot print_timing: id  2 | task 7908 | n_decoded =    676, tg =  63.73 t/s
2026-05-23 18:23:04.216 | 16.55.088.622 I slot print_timing: id  2 | task 7908 | n_decoded =    900, tg =  66.03 t/s
2026-05-23 18:23:07.248 | 16.58.120.469 I slot print_timing: id  2 | task 7908 | n_decoded =   1097, tg =  65.84 t/s
2026-05-23 18:23:09.871 | 17.00.743.288 I slot print_timing: id  2 | task 7908 | n_decoded =   1299, tg =  66.04 t/s
2026-05-23 18:23:12.896 | 17.03.768.608 I slot print_timing: id  2 | task 7908 | n_decoded =   1513, tg =  66.66 t/s
2026-05-23 18:23:15.397 | 17.06.269.548 I slot print_timing: id  2 | task 7908 | n_decoded =   1712, tg =  66.62 t/s
2026-05-23 18:23:18.408 | 17.09.280.660 I slot print_timing: id  2 | task 7908 | n_decoded =   1940, tg =  67.58 t/s
2026-05-23 18:23:20.940 | 17.11.812.331 I slot print_timing: id  2 | task 7908 | n_decoded =   2162, tg =  68.11 t/s
2026-05-23 18:23:23.443 | 17.14.315.564 I slot print_timing: id  2 | task 7908 | n_decoded =   2384, tg =  68.62 t/s
2026-05-23 18:23:26.480 | 17.17.352.047 I slot print_timing: id  2 | task 7908 | n_decoded =   2598, tg =  68.76 t/s
2026-05-23 18:23:28.990 | 17.19.862.759 I slot print_timing: id  2 | task 7908 | n_decoded =   2826, tg =  69.28 t/s
2026-05-23 18:23:31.672 | 17.22.544.479 I slot print_timing: id  2 | task 7908 | n_decoded =   3053, tg =  69.69 t/s
2026-05-23 18:23:34.514 | 17.25.385.999 I slot print_timing: id  2 | task 7908 | n_decoded =   3251, tg =  69.44 t/s
2026-05-23 18:23:37.540 | 17.28.412.418 I slot print_timing: id  2 | task 7908 | n_decoded =   3470, tg =  69.62 t/s
2026-05-23 18:23:40.056 | 17.30.928.225 I slot print_timing: id  2 | task 7908 | n_decoded =   3649, tg =  69.03 t/s
2026-05-23 18:23:43.059 | 17.33.931.391 I slot print_timing: id  2 | task 7908 | n_decoded =   3828, tg =  68.53 t/s
2026-05-23 18:23:45.591 | 17.36.462.979 I slot print_timing: id  2 | task 7908 | n_decoded =   4025, tg =  68.34 t/s
2026-05-23 18:23:48.090 | 17.38.962.693 I slot print_timing: id  2 | task 7908 | n_decoded =   4196, tg =  67.79 t/s
2026-05-23 18:23:49.235 | 17.40.107.819 I slot print_timing: id  2 | task 7908 | 
2026-05-23 18:23:49.236 | prompt eval time =   16257.57 ms / 20275 tokens (    0.80 ms per token,  1247.11 tokens per second)
2026-05-23 18:23:49.236 |        eval time =   63038.91 ms /  4270 tokens (   14.76 ms per token,    67.74 tokens per second)
2026-05-23 18:23:49.236 |       total time =   79296.48 ms / 24545 tokens
2026-05-23 18:23:49.236 | draft acceptance rate = 0.75766 ( 2573 accepted /  3396 generated)
2026-05-23 18:23:49.236 | 17.40.107.865 I statistics draft-mtp: #calls(b,g,a) = 21 9495 9520, #gen drafts = 9520, #acc drafts = 8274, #gen tokens = 19040, #acc tokens = 15422, dur(b,g,a) = 0.033, 46283.444, 18.531 ms
2026-05-23 18:23:49.238 | 17.40.110.080 I slot      release: id  2 | task 7908 | stop processing: n_tokens = 75268, truncated = 0
2026-05-23 18:23:49.238 | 17.40.110.194 I srv  update_slots: all slots are idle
2026-05-23 18:23:49.488 | 17.40.360.790 I srv  params_from_: Chat format: peg-native
2026-05-23 18:23:49.490 | 17.40.362.223 I slot get_availabl: id  2 | task -1 | selected slot by LCP similarity, sim_best = 1.000 (> 0.100 thold), f_keep = 1.000
2026-05-23 18:23:49.491 | 17.40.363.022 I reasoning-budget: activated, budget=2147483647 tokens
2026-05-23 18:23:49.491 | 17.40.363.114 I slot launch_slot_: id  2 | task 9619 | processing task, is_child = 0
2026-05-23 18:23:49.806 | 17.40.678.038 I slot create_check: id  2 | task 9619 | created context checkpoint 13 of 32 (pos_min = 75267, pos_max = 75267, n_tokens = 75268, size = 307.258 MiB)
2026-05-23 18:23:50.522 | 17.41.394.451 I reasoning-budget: deactivated (natural end)
2026-05-23 18:23:51.273 | 17.42.145.144 I slot print_timing: id  2 | task 9619 | n_decoded =    100, tg =  73.31 t/s
2026-05-23 18:23:53.795 | 17.44.667.058 I slot print_timing: id  2 | task 9619 | n_decoded =    333, tg =  75.93 t/s
2026-05-23 18:23:54.276 | 17.45.148.688 I slot print_timing: id  2 | task 9619 | 
2026-05-23 18:23:54.276 | prompt eval time =     417.68 ms /    19 tokens (   21.98 ms per token,    45.49 tokens per second)
2026-05-23 18:23:54.276 |        eval time =    4866.98 ms /   368 tokens (   13.23 ms per token,    75.61 tokens per second)
2026-05-23 18:23:54.276 |       total time =    5284.66 ms /   387 tokens
2026-05-23 18:23:54.276 | draft acceptance rate = 0.91154 (  237 accepted /   260 generated)
2026-05-23 18:23:54.276 | 17.45.148.723 I statistics draft-mtp: #calls(b,g,a) = 22 9625 9650, #gen drafts = 9650, #acc drafts = 8398, #gen tokens = 19300, #acc tokens = 15659, dur(b,g,a) = 0.034, 46925.783, 18.762 ms
2026-05-23 18:23:54.278 | 17.45.150.629 I slot      release: id  2 | task 9619 | stop processing: n_tokens = 75654, truncated = 0
2026-05-23 18:23:54.278 | 17.45.150.695 I srv  update_slots: all slots are idle
2026-05-23 18:23:54.533 | 17.45.404.964 I srv  params_from_: Chat format: peg-native
2026-05-23 18:23:54.534 | 17.45.406.347 I slot get_availabl: id  2 | task -1 | selected slot by LCP similarity, sim_best = 0.995 (> 0.100 thold), f_keep = 1.000
2026-05-23 18:23:54.535 | 17.45.407.051 I reasoning-budget: activated, budget=2147483647 tokens
2026-05-23 18:23:54.535 | 17.45.407.131 I slot launch_slot_: id  2 | task 9752 | processing task, is_child = 0
2026-05-23 18:23:54.906 | 17.45.778.306 I slot create_check: id  2 | task 9752 | created context checkpoint 14 of 32 (pos_min = 75653, pos_max = 75653, n_tokens = 75654, size = 308.066 MiB)
2026-05-23 18:23:55.637 | 17.46.508.964 I slot create_check: id  2 | task 9752 | created context checkpoint 15 of 32 (pos_min = 76040, pos_max = 76040, n_tokens = 76041, size = 308.876 MiB)
2026-05-23 18:23:57.145 | 17.48.017.485 I slot print_timing: id  2 | task 9752 | n_decoded =    101, tg =  68.96 t/s
2026-05-23 18:23:57.584 | 17.48.456.632 I reasoning-budget: deactivated (natural end)
2026-05-23 18:23:59.619 | 17.50.491.698 I slot print_timing: id  2 | task 9752 | n_decoded =    330, tg =  73.34 t/s
2026-05-23 18:24:02.640 | 17.53.512.896 I slot print_timing: id  2 | task 9752 | n_decoded =    567, tg =  75.39 t/s
2026-05-23 18:24:05.222 | 17.56.094.470 I slot print_timing: id  2 | task 9752 | n_decoded =    804, tg =  76.21 t/s
2026-05-23 18:24:08.253 | 17.59.125.755 I slot print_timing: id  2 | task 9752 | n_decoded =   1041, tg =  76.65 t/s
2026-05-23 18:24:09.954 | 18.00.826.882 I slot print_timing: id  2 | task 9752 | 
2026-05-23 18:24:09.955 | prompt eval time =    1145.50 ms /   391 tokens (    2.93 ms per token,   341.34 tokens per second)
2026-05-23 18:24:09.955 |        eval time =   15775.48 ms /  1210 tokens (   13.04 ms per token,    76.70 tokens per second)
2026-05-23 18:24:09.955 |       total time =   16920.98 ms /  1601 tokens
2026-05-23 18:24:09.955 | draft acceptance rate = 0.96610 (  798 accepted /   826 generated)
2026-05-23 18:24:09.955 | 18.00.826.919 I statistics draft-mtp: #calls(b,g,a) = 23 10038 10063, #gen drafts = 10063, #acc drafts = 8800, #gen tokens = 20126, #acc tokens = 16457, dur(b,g,a) = 0.035, 49036.314, 19.528 ms
2026-05-23 18:24:09.956 | 18.00.828.747 I slot      release: id  2 | task 9752 | stop processing: n_tokens = 77256, truncated = 0
2026-05-23 18:24:09.956 | 18.00.828.816 I srv  update_slots: all slots are idle
2026-05-23 18:24:10.249 | 18.01.121.284 I srv  params_from_: Chat format: peg-native
2026-05-23 18:24:10.250 | 18.01.122.705 I slot get_availabl: id  2 | task -1 | selected slot by LCP similarity, sim_best = 1.000 (> 0.100 thold), f_keep = 1.000
2026-05-23 18:24:10.251 | 18.01.123.436 I reasoning-budget: activated, budget=2147483647 tokens
2026-05-23 18:24:10.251 | 18.01.123.519 I slot launch_slot_: id  2 | task 10168 | processing task, is_child = 0
2026-05-23 18:24:10.646 | 18.01.518.447 I slot create_check: id  2 | task 10168 | created context checkpoint 16 of 32 (pos_min = 77255, pos_max = 77255, n_tokens = 77256, size = 311.421 MiB)
2026-05-23 18:24:11.983 | 18.02.855.821 I reasoning-budget: deactivated (natural end)
2026-05-23 18:24:12.359 | 18.03.231.295 I slot print_timing: id  2 | task 10168 | n_decoded =    101, tg =  62.89 t/s
2026-05-23 18:24:14.862 | 18.05.734.523 I slot print_timing: id  2 | task 10168 | n_decoded =    341, tg =  73.98 t/s
2026-05-23 18:24:15.163 | 18.06.035.056 I slot print_timing: id  2 | task 10168 | 
2026-05-23 18:24:15.163 | prompt eval time =     501.61 ms /    19 tokens (   26.40 ms per token,    37.88 tokens per second)
2026-05-23 18:24:15.163 |        eval time =    4910.12 ms /   365 tokens (   13.45 ms per token,    74.34 tokens per second)
2026-05-23 18:24:15.163 |       total time =    5411.73 ms /   384 tokens
2026-05-23 18:24:15.163 | draft acceptance rate = 0.90000 (  234 accepted /   260 generated)
2026-05-23 18:24:15.163 | 18.06.035.092 I statistics draft-mtp: #calls(b,g,a) = 24 10168 10193, #gen drafts = 10193, #acc drafts = 8920, #gen tokens = 20386, #acc tokens = 16691, dur(b,g,a) = 0.036, 49681.396, 19.760 ms
2026-05-23 18:24:15.164 | 18.06.036.928 I slot      release: id  2 | task 10168 | stop processing: n_tokens = 77639, truncated = 0
2026-05-23 18:24:15.164 | 18.06.036.999 I srv  update_slots: all slots are idle
2026-05-23 18:24:15.431 | 18.06.303.068 I srv  params_from_: Chat format: peg-native
2026-05-23 18:24:15.432 | 18.06.304.494 I slot get_availabl: id  2 | task -1 | selected slot by LCP similarity, sim_best = 0.995 (> 0.100 thold), f_keep = 1.000
2026-05-23 18:24:15.433 | 18.06.305.240 I reasoning-budget: activated, budget=2147483647 tokens
2026-05-23 18:24:15.433 | 18.06.305.328 I slot launch_slot_: id  2 | task 10301 | processing task, is_child = 0
2026-05-23 18:24:15.813 | 18.06.685.090 I slot create_check: id  2 | task 10301 | created context checkpoint 17 of 32 (pos_min = 77638, pos_max = 77638, n_tokens = 77639, size = 312.223 MiB)
2026-05-23 18:24:16.551 | 18.07.423.264 I slot create_check: id  2 | task 10301 | created context checkpoint 18 of 32 (pos_min = 78025, pos_max = 78025, n_tokens = 78026, size = 313.034 MiB)
2026-05-23 18:24:17.183 | 18.08.054.987 I reasoning-budget: deactivated (natural end)
2026-05-23 18:24:17.968 | 18.08.840.774 I slot print_timing: id  2 | task 10301 | n_decoded =    102, tg =  74.32 t/s
2026-05-23 18:24:20.481 | 18.11.353.147 I slot print_timing: id  2 | task 10301 | n_decoded =    335, tg =  76.40 t/s
2026-05-23 18:24:23.532 | 18.14.404.405 I slot print_timing: id  2 | task 10301 | n_decoded =    564, tg =  75.84 t/s
2026-05-23 18:24:26.062 | 18.16.934.134 I slot print_timing: id  2 | task 10301 | n_decoded =    801, tg =  76.52 t/s
2026-05-23 18:24:26.531 | 18.17.403.354 I slot print_timing: id  2 | task 10301 | 
2026-05-23 18:24:26.531 | prompt eval time =    1162.62 ms /   391 tokens (    2.97 ms per token,   336.31 tokens per second)
2026-05-23 18:24:26.531 |        eval time =   11220.13 ms /   857 tokens (   13.09 ms per token,    76.38 tokens per second)
2026-05-23 18:24:26.531 |       total time =   12382.75 ms /  1248 tokens
2026-05-23 18:24:26.531 | draft acceptance rate = 0.97759 (  567 accepted /   580 generated)
2026-05-23 18:24:26.531 | 18.17.403.390 I statistics draft-mtp: #calls(b,g,a) = 25 10458 10483, #gen drafts = 10483, #acc drafts = 9206, #gen tokens = 20966, #acc tokens = 17258, dur(b,g,a) = 0.037, 51187.775, 20.319 ms
2026-05-23 18:24:26.533 | 18.17.405.260 I slot      release: id  2 | task 10301 | stop processing: n_tokens = 78887, truncated = 0
2026-05-23 18:24:26.533 | 18.17.405.333 I srv  update_slots: all slots are idle
2026-05-23 18:24:26.839 | 18.17.711.378 I srv  params_from_: Chat format: peg-native
2026-05-23 18:24:26.840 | 18.17.712.776 I slot get_availabl: id  2 | task -1 | selected slot by LCP similarity, sim_best = 1.000 (> 0.100 thold), f_keep = 1.000
2026-05-23 18:24:26.841 | 18.17.713.524 I reasoning-budget: activated, budget=2147483647 tokens
2026-05-23 18:24:26.841 | 18.17.713.607 I slot launch_slot_: id  2 | task 10594 | processing task, is_child = 0
2026-05-23 18:24:27.217 | 18.18.089.262 I slot create_check: id  2 | task 10594 | created context checkpoint 19 of 32 (pos_min = 78886, pos_max = 78886, n_tokens = 78887, size = 314.837 MiB)
2026-05-23 18:24:27.790 | 18.18.662.853 I reasoning-budget: deactivated (natural end)
2026-05-23 18:24:28.570 | 18.19.442.891 I slot print_timing: id  2 | task 10594 | n_decoded =    109, tg =  74.28 t/s
2026-05-23 18:24:29.606 | 18.20.478.154 I slot print_timing: id  2 | task 10594 | 
2026-05-23 18:24:29.606 | prompt eval time =     478.65 ms /    20 tokens (   23.93 ms per token,    41.78 tokens per second)
2026-05-23 18:24:29.606 |        eval time =    2502.66 ms /   190 tokens (   13.17 ms per token,    75.92 tokens per second)
2026-05-23 18:24:29.606 |       total time =    2981.31 ms /   210 tokens
2026-05-23 18:24:29.606 | draft acceptance rate = 0.95385 (  124 accepted /   130 generated)
2026-05-23 18:24:29.606 | 18.20.478.191 I statistics draft-mtp: #calls(b,g,a) = 26 10523 10548, #gen drafts = 10548, #acc drafts = 9269, #gen tokens = 21096, #acc tokens = 17382, dur(b,g,a) = 0.038, 51518.354, 20.436 ms
2026-05-23 18:24:29.608 | 18.20.480.084 I slot      release: id  2 | task 10594 | stop processing: n_tokens = 79096, truncated = 0
2026-05-23 18:24:29.608 | 18.20.480.151 I srv  update_slots: all slots are idle
2026-05-23 18:24:29.921 | 18.20.793.843 I srv  params_from_: Chat format: peg-native
2026-05-23 18:24:29.923 | 18.20.795.263 I slot get_availabl: id  2 | task -1 | selected slot by LCP similarity, sim_best = 1.000 (> 0.100 thold), f_keep = 1.000
2026-05-23 18:24:29.924 | 18.20.796.026 I reasoning-budget: activated, budget=2147483647 tokens
2026-05-23 18:24:29.924 | 18.20.796.125 I slot launch_slot_: id  2 | task 10662 | processing task, is_child = 0
2026-05-23 18:24:30.311 | 18.21.183.061 I slot create_check: id  2 | task 10662 | created context checkpoint 20 of 32 (pos_min = 79095, pos_max = 79095, n_tokens = 79096, size = 315.274 MiB)
2026-05-23 18:24:30.855 | 18.21.727.181 I reasoning-budget: deactivated (natural end)
2026-05-23 18:24:31.773 | 18.22.645.609 I slot print_timing: id  2 | task 10662 | n_decoded =    102, tg =  75.50 t/s
2026-05-23 18:24:34.087 | 18.24.959.790 I slot print_timing: id  2 | task 10662 | 
2026-05-23 18:24:34.087 | prompt eval time =     498.27 ms /    21 tokens (   23.73 ms per token,    42.15 tokens per second)
2026-05-23 18:24:34.087 |        eval time =    4164.86 ms /   323 tokens (   12.89 ms per token,    77.55 tokens per second)
2026-05-23 18:24:34.087 |       total time =    4663.13 ms /   344 tokens
2026-05-23 18:24:34.087 | draft acceptance rate = 0.98165 (  214 accepted /   218 generated)
2026-05-23 18:24:34.087 | 18.24.959.823 I statistics draft-mtp: #calls(b,g,a) = 27 10632 10657, #gen drafts = 10657, #acc drafts = 9378, #gen tokens = 21314, #acc tokens = 17596, dur(b,g,a) = 0.040, 52058.276, 20.631 ms
2026-05-23 18:24:34.089 | 18.24.961.721 I slot      release: id  2 | task 10662 | stop processing: n_tokens = 79440, truncated = 0
2026-05-23 18:24:34.089 | 18.24.961.790 I srv  update_slots: all slots are idle
2026-05-23 18:24:34.357 | 18.25.229.368 I srv  params_from_: Chat format: peg-native
2026-05-23 18:24:34.358 | 18.25.230.781 I slot get_availabl: id  2 | task -1 | selected slot by LCP similarity, sim_best = 0.995 (> 0.100 thold), f_keep = 1.000
2026-05-23 18:24:34.359 | 18.25.231.491 I reasoning-budget: activated, budget=2147483647 tokens
2026-05-23 18:24:34.359 | 18.25.231.578 I slot launch_slot_: id  2 | task 10774 | processing task, is_child = 0
2026-05-23 18:24:34.733 | 18.25.605.912 I slot create_check: id  2 | task 10774 | created context checkpoint 21 of 32 (pos_min = 79439, pos_max = 79439, n_tokens = 79440, size = 315.995 MiB)
2026-05-23 18:24:35.479 | 18.26.351.401 I slot create_check: id  2 | task 10774 | created context checkpoint 22 of 32 (pos_min = 79825, pos_max = 79825, n_tokens = 79826, size = 316.803 MiB)
2026-05-23 18:24:35.921 | 18.26.793.476 I reasoning-budget: deactivated (natural end)
2026-05-23 18:24:36.941 | 18.27.812.937 I slot print_timing: id  2 | task 10774 | n_decoded =    100, tg =  70.50 t/s
2026-05-23 18:24:38.548 | 18.29.419.941 I slot print_timing: id  2 | task 10774 | 
2026-05-23 18:24:38.548 | prompt eval time =    1162.75 ms /   390 tokens (    2.98 ms per token,   335.41 tokens per second)
2026-05-23 18:24:38.548 |        eval time =    3025.41 ms /   225 tokens (   13.45 ms per token,    74.37 tokens per second)
2026-05-23 18:24:38.548 |       total time =    4188.16 ms /   615 tokens
2026-05-23 18:24:38.548 | draft acceptance rate = 0.93590 (  146 accepted /   156 generated)
2026-05-23 18:24:38.548 | 18.29.419.979 I statistics draft-mtp: #calls(b,g,a) = 28 10710 10735, #gen drafts = 10735, #acc drafts = 9453, #gen tokens = 21470, #acc tokens = 17742, dur(b,g,a) = 0.041, 52457.725, 20.778 ms
2026-05-23 18:24:38.549 | 18.29.421.983 I slot      release: id  2 | task 10774 | stop processing: n_tokens = 80054, truncated = 0
2026-05-23 18:24:38.550 | 18.29.422.056 I srv  update_slots: all slots are idle
2026-05-23 18:24:38.423 | 18.29.295.515 I srv  params_from_: Chat format: peg-native
2026-05-23 18:24:38.425 | 18.29.296.954 I slot get_availabl: id  2 | task -1 | selected slot by LCP similarity, sim_best = 0.997 (> 0.100 thold), f_keep = 1.000
2026-05-23 18:24:38.425 | 18.29.297.670 I reasoning-budget: activated, budget=2147483647 tokens
2026-05-23 18:24:38.425 | 18.29.297.752 I slot launch_slot_: id  2 | task 10855 | processing task, is_child = 0
2026-05-23 18:24:38.822 | 18.29.694.305 I slot create_check: id  2 | task 10855 | created context checkpoint 23 of 32 (pos_min = 80053, pos_max = 80053, n_tokens = 80054, size = 317.281 MiB)
2026-05-23 18:24:39.449 | 18.30.321.762 I slot create_check: id  2 | task 10855 | created context checkpoint 24 of 32 (pos_min = 80279, pos_max = 80279, n_tokens = 80280, size = 317.754 MiB)
2026-05-23 18:24:40.115 | 18.30.987.689 I reasoning-budget: deactivated (natural end)
2026-05-23 18:24:40.876 | 18.31.748.721 I slot print_timing: id  2 | task 10855 | n_decoded =    100, tg =  72.30 t/s
2026-05-23 18:24:43.343 | 18.34.215.654 I slot print_timing: id  2 | task 10855 | 
2026-05-23 18:24:43.343 | prompt eval time =    1067.56 ms /   230 tokens (    4.64 ms per token,   215.45 tokens per second)
2026-05-23 18:24:43.343 |        eval time =    4344.02 ms /   334 tokens (   13.01 ms per token,    76.89 tokens per second)
2026-05-23 18:24:43.343 |       total time =    5411.58 ms /   564 tokens
2026-05-23 18:24:43.343 | draft acceptance rate = 0.96053 (  219 accepted /   228 generated)
2026-05-23 18:24:43.343 | 18.34.215.690 I statistics draft-mtp: #calls(b,g,a) = 29 10824 10849, #gen drafts = 10849, #acc drafts = 9564, #gen tokens = 21698, #acc tokens = 17961, dur(b,g,a) = 0.042, 53019.408, 20.965 ms
2026-05-23 18:24:43.345 | 18.34.217.593 I slot      release: id  2 | task 10855 | stop processing: n_tokens = 80617, truncated = 0
2026-05-23 18:24:43.345 | 18.34.217.665 I srv  update_slots: all slots are idle
2026-05-23 18:24:43.615 | 18.34.487.589 I srv  params_from_: Chat format: peg-native
2026-05-23 18:24:43.617 | 18.34.489.008 I slot get_availabl: id  2 | task -1 | selected slot by LCP similarity, sim_best = 0.995 (> 0.100 thold), f_keep = 1.000
2026-05-23 18:24:43.617 | 18.34.489.715 I reasoning-budget: activated, budget=2147483647 tokens
2026-05-23 18:24:43.617 | 18.34.489.801 I slot launch_slot_: id  2 | task 10972 | processing task, is_child = 0
2026-05-23 18:24:44.004 | 18.34.876.516 I slot create_check: id  2 | task 10972 | created context checkpoint 25 of 32 (pos_min = 80616, pos_max = 80616, n_tokens = 80617, size = 318.460 MiB)
2026-05-23 18:24:44.750 | 18.35.622.141 I slot create_check: id  2 | task 10972 | created context checkpoint 26 of 32 (pos_min = 81005, pos_max = 81005, n_tokens = 81006, size = 319.275 MiB)
2026-05-23 18:24:45.305 | 18.36.177.422 I reasoning-budget: deactivated (natural end)
2026-05-23 18:24:46.280 | 18.37.152.364 I slot print_timing: id  2 | task 10972 | n_decoded =    101, tg =  67.91 t/s
2026-05-23 18:24:48.795 | 18.39.667.778 I slot print_timing: id  2 | task 10972 | n_decoded =    320, tg =  71.06 t/s
2026-05-23 18:24:51.822 | 18.42.694.122 I slot print_timing: id  2 | task 10972 | n_decoded =    541, tg =  71.85 t/s
2026-05-23 18:24:54.312 | 18.45.184.282 I slot print_timing: id  2 | task 10972 | n_decoded =    738, tg =  70.05 t/s
2026-05-23 18:24:57.188 | 18.48.060.733 I srv  params_from_: Chat format: peg-native
2026-05-23 18:24:57.211 | 18.48.082.990 I slot get_availabl: id  1 | task -1 | selected slot by LRU, t_last = -1
2026-05-23 18:24:57.211 | 18.48.083.010 I srv  get_availabl: updating prompt cache
2026-05-23 18:24:57.211 | 18.48.083.013 I srv          load:  - looking for better prompt, base f_keep = -1.000, sim = 0.000
2026-05-23 18:24:57.211 | 18.48.083.026 I srv        update:  - cache state: 2 prompts, 7594.318 MiB (limits: 8192.000 MiB, 131072 tokens, 131072 est)
2026-05-23 18:24:57.211 | 18.48.083.027 I srv        update:    - prompt 0x63d3aecbf9f0:    1630 tokens, checkpoints:  2,   509.021 MiB
2026-05-23 18:24:57.211 | 18.48.083.045 I srv        update:    - prompt 0x63d3af0f95b0:   46225 tokens, checkpoints: 25,  7085.298 MiB
2026-05-23 18:24:57.211 | 18.48.083.046 I srv  get_availabl: prompt cache update took 0.04 ms
2026-05-23 18:24:57.211 | 18.48.083.540 I reasoning-budget: activated, budget=2147483647 tokens
2026-05-23 18:24:57.211 | 18.48.083.574 I slot launch_slot_: id  1 | task 11322 | processing task, is_child = 0
2026-05-23 18:24:58.610 | 18.49.482.784 I slot print_timing: id  2 | task 10972 | n_decoded =    927, tg =  60.51 t/s
2026-05-23 18:25:00.513 | 18.51.385.402 I slot print_timing: id  1 | task 11322 | prompt processing, n_tokens =   4090, progress = 0.56, t =   3.78 s / 1080.90 tokens per second
2026-05-23 18:25:02.410 | 18.53.281.999 I slot print_timing: id  2 | task 10972 | n_decoded =    933, tg =  48.80 t/s
2026-05-23 18:25:02.421 | 18.53.293.632 I slot print_timing: id  1 | task 11322 | prompt processing, n_tokens =   6135, progress = 0.84, t =   5.69 s / 1077.81 tokens per second
2026-05-23 18:25:03.072 | 18.53.944.524 I slot print_timing: id  1 | task 11322 | prompt processing, n_tokens =   6778, progress = 0.93, t =   6.34 s / 1068.58 tokens per second
2026-05-23 18:25:03.260 | 18.54.131.943 I slot create_check: id  1 | task 11322 | created context checkpoint 1 of 32 (pos_min = 6777, pos_max = 6777, n_tokens = 6778, size = 163.821 MiB)
2026-05-23 18:25:03.290 | 18.54.162.206 I slot print_timing: id  1 | task 11322 | prompt processing, n_tokens =   7290, progress = 1.00, t =   7.07 s / 1031.31 tokens per second
2026-05-23 18:25:03.478 | 18.54.350.231 I slot create_check: id  1 | task 11322 | created context checkpoint 2 of 32 (pos_min = 7289, pos_max = 7289, n_tokens = 7290, size = 164.893 MiB)
2026-05-23 18:25:04.950 | 18.55.822.461 I slot print_timing: id  2 | task 10972 | n_decoded =    984, tg =  44.39 t/s
2026-05-23 18:25:06.421 | 18.57.293.086 I reasoning-budget: deactivated (natural end)
2026-05-23 18:25:07.607 | 18.58.479.722 I slot print_timing: id  1 | task 11322 | n_decoded =    101, tg =  24.98 t/s
2026-05-23 18:25:08.008 | 18.58.880.201 I slot print_timing: id  2 | task 10972 | n_decoded =   1075, tg =  42.62 t/s
2026-05-23 18:25:10.188 | 19.01.060.077 I slot print_timing: id  1 | task 11322 | n_decoded =    194, tg =  27.23 t/s
2026-05-23 18:25:10.596 | 19.01.468.485 I slot print_timing: id  2 | task 10972 | n_decoded =   1168, tg =  41.25 t/s
2026-05-23 18:25:11.634 | 19.02.506.086 I slot print_timing: id  1 | task 11322 | 
2026-05-23 18:25:11.634 | prompt eval time =    7343.17 ms /  7294 tokens (    1.01 ms per token,   993.30 tokens per second)
2026-05-23 18:25:11.634 |        eval time =    8569.00 ms /   234 tokens (   36.62 ms per token,    27.31 tokens per second)
2026-05-23 18:25:11.634 |       total time =   15912.17 ms /  7528 tokens
2026-05-23 18:25:11.634 | draft acceptance rate = 0.86628 (  149 accepted /   172 generated)
2026-05-23 18:25:11.634 | 19.02.506.122 I statistics draft-mtp: #calls(b,g,a) = 31 11263 11373, #gen drafts = 11374, #acc drafts = 10038, #gen tokens = 22748, #acc tokens = 18866, dur(b,g,a) = 0.045, 55395.080, 22.036 ms
2026-05-23 18:25:11.634 | 19.02.506.451 I slot      release: id  1 | task 11322 | stop processing: n_tokens = 7529, truncated = 0
2026-05-23 18:25:11.773 | 19.02.645.433 I srv  params_from_: Chat format: peg-native
2026-05-23 18:25:11.808 | 19.02.680.664 I slot get_availabl: id  1 | task -1 | selected slot by LCP similarity, sim_best = 0.807 (> 0.100 thold), f_keep = 1.000
2026-05-23 18:25:11.809 | 19.02.681.183 I reasoning-budget: activated, budget=2147483647 tokens
2026-05-23 18:25:11.809 | 19.02.681.276 I slot launch_slot_: id  1 | task 11419 | processing task, is_child = 0
2026-05-23 18:25:13.290 | 19.04.162.522 I slot create_check: id  1 | task 11419 | created context checkpoint 3 of 32 (pos_min = 8813, pos_max = 8813, n_tokens = 8814, size = 168.085 MiB)
2026-05-23 18:25:13.334 | 19.04.206.119 I slot print_timing: id  2 | task 10972 | n_decoded =   1212, tg =  38.42 t/s
2026-05-23 18:25:13.540 | 19.04.412.166 I slot create_check: id  1 | task 11419 | created context checkpoint 4 of 32 (pos_min = 9325, pos_max = 9325, n_tokens = 9326, size = 169.157 MiB)
2026-05-23 18:25:14.622 | 19.05.494.807 I reasoning-budget: deactivated (natural end)
2026-05-23 18:25:16.427 | 19.07.299.002 I slot print_timing: id  2 | task 10972 | n_decoded =   1299, tg =  37.50 t/s
2026-05-23 18:25:17.119 | 19.07.991.197 I slot print_timing: id  1 | task 11419 | n_decoded =    101, tg =  28.93 t/s
2026-05-23 18:25:19.002 | 19.09.874.554 I slot print_timing: id  2 | task 10972 | n_decoded =   1378, tg =  36.53 t/s
2026-05-23 18:25:19.704 | 19.10.576.792 I slot print_timing: id  1 | task 11419 | n_decoded =    194, tg =  29.46 t/s
2026-05-23 18:25:21.811 | 19.12.682.990 I slot print_timing: id  2 | task 10972 | n_decoded =   1468, tg =  36.02 t/s
2026-05-23 18:25:22.510 | 19.13.382.352 I slot print_timing: id  1 | task 11419 | n_decoded =    284, tg =  29.53 t/s
2026-05-23 18:25:24.544 | 19.15.416.333 I slot print_timing: id  2 | task 10972 | n_decoded =   1555, tg =  35.53 t/s
2026-05-23 18:25:25.243 | 19.16.115.376 I slot print_timing: id  1 | task 11419 | n_decoded =    374, tg =  29.62 t/s
2026-05-23 18:25:27.549 | 19.18.421.309 I slot print_timing: id  2 | task 10972 | n_decoded =   1638, tg =  35.02 t/s
2026-05-23 18:25:28.250 | 19.19.122.308 I slot print_timing: id  1 | task 11419 | n_decoded =    464, tg =  29.68 t/s
2026-05-23 18:25:30.077 | 19.20.949.384 I slot print_timing: id  2 | task 10972 | n_decoded =   1723, tg =  34.60 t/s
2026-05-23 18:25:30.731 | 19.21.603.674 I srv  params_from_: Chat format: peg-native
2026-05-23 18:25:30.780 | 19.21.652.460 I slot print_timing: id  1 | task 11419 | n_decoded =    554, tg =  29.70 t/s
2026-05-23 18:25:30.783 | 19.21.655.888 I slot get_availabl: id  0 | task -1 | selected slot by LRU, t_last = -1
2026-05-23 18:25:30.783 | 19.21.655.909 I srv  get_availabl: updating prompt cache
2026-05-23 18:25:30.783 | 19.21.655.912 I srv          load:  - looking for better prompt, base f_keep = -1.000, sim = 0.000
2026-05-23 18:25:30.783 | 19.21.655.926 I srv        update:  - cache state: 2 prompts, 7594.318 MiB (limits: 8192.000 MiB, 131072 tokens, 131072 est)
2026-05-23 18:25:30.783 | 19.21.655.927 I srv        update:    - prompt 0x63d3aecbf9f0:    1630 tokens, checkpoints:  2,   509.021 MiB
2026-05-23 18:25:30.783 | 19.21.655.928 I srv        update:    - prompt 0x63d3af0f95b0:   46225 tokens, checkpoints: 25,  7085.298 MiB
2026-05-23 18:25:30.783 | 19.21.655.929 I srv  get_availabl: prompt cache update took 0.02 ms
2026-05-23 18:25:30.784 | 19.21.656.439 I reasoning-budget: activated, budget=2147483647 tokens
2026-05-23 18:25:30.784 | 19.21.656.474 I slot launch_slot_: id  0 | task 11609 | processing task, is_child = 0
2026-05-23 18:25:34.411 | 19.25.283.180 I slot print_timing: id  1 | task 11419 | n_decoded =    560, tg =  24.57 t/s
2026-05-23 18:25:34.414 | 19.25.286.577 I slot print_timing: id  2 | task 10972 | n_decoded =   1750, tg =  32.03 t/s
2026-05-23 18:25:34.424 | 19.25.296.837 I slot print_timing: id  0 | task 11609 | prompt processing, n_tokens =   4084, progress = 0.56, t =   4.14 s / 986.36 tokens per second
2026-05-23 18:25:36.518 | 19.27.390.378 I slot print_timing: id  0 | task 11609 | prompt processing, n_tokens =   6126, progress = 0.84, t =   6.23 s / 982.67 tokens per second
2026-05-23 18:25:37.247 | 19.28.119.815 I slot print_timing: id  0 | task 11609 | prompt processing, n_tokens =   6752, progress = 0.93, t =   6.96 s / 969.63 tokens per second
2026-05-23 18:25:37.431 | 19.28.303.381 I slot create_check: id  0 | task 11609 | created context checkpoint 1 of 32 (pos_min = 6751, pos_max = 6751, n_tokens = 6752, size = 163.767 MiB)
2026-05-23 18:25:38.043 | 19.28.915.740 I slot print_timing: id  1 | task 11419 | n_decoded =    569, tg =  21.53 t/s
2026-05-23 18:25:38.047 | 19.28.919.160 I slot print_timing: id  2 | task 10972 | n_decoded =   1759, tg =  30.19 t/s
2026-05-23 18:25:38.054 | 19.28.926.144 I slot print_timing: id  0 | task 11609 | prompt processing, n_tokens =   7264, progress = 1.00, t =   7.77 s / 934.90 tokens per second
2026-05-23 18:25:38.240 | 19.29.112.665 I slot create_check: id  0 | task 11609 | created context checkpoint 2 of 32 (pos_min = 7263, pos_max = 7263, n_tokens = 7264, size = 164.839 MiB)
2026-05-23 18:25:40.594 | 19.31.466.335 I slot print_timing: id  1 | task 11419 | n_decoded =    626, tg =  21.24 t/s
2026-05-23 18:25:40.597 | 19.31.469.857 I slot print_timing: id  2 | task 10972 | n_decoded =   1816, tg =  29.62 t/s
2026-05-23 18:25:41.045 | 19.31.917.030 I reasoning-budget: deactivated (natural end)
2026-05-23 18:25:42.400 | 19.33.272.202 I slot print_timing: id  1 | task 11419 | 
2026-05-23 18:25:42.400 | prompt eval time =    2306.44 ms /  1801 tokens (    1.28 ms per token,   780.86 tokens per second)
2026-05-23 18:25:42.400 |        eval time =   31276.91 ms /   660 tokens (   47.39 ms per token,    21.10 tokens per second)
2026-05-23 18:25:42.400 |       total time =   33583.35 ms /  2461 tokens
2026-05-23 18:25:42.400 | draft acceptance rate = 0.98423 (  437 accepted /   444 generated)
2026-05-23 18:25:42.400 | 19.33.272.234 I statistics draft-mtp: #calls(b,g,a) = 33 11492 11854, #gen drafts = 11855, #acc drafts = 10498, #gen tokens = 23710, #acc tokens = 19772, dur(b,g,a) = 0.048, 56967.725, 23.262 ms
2026-05-23 18:25:42.400 | 19.33.272.714 I slot      release: id  1 | task 11419 | stop processing: n_tokens = 9989, truncated = 0
2026-05-23 18:25:42.586 | 19.33.458.660 I srv  params_from_: Chat format: peg-native
2026-05-23 18:25:42.613 | 19.33.485.254 I slot get_availabl: id  1 | task -1 | selected slot by LCP similarity, sim_best = 0.659 (> 0.100 thold), f_keep = 1.000
2026-05-23 18:25:42.613 | 19.33.485.775 I reasoning-budget: activated, budget=2147483647 tokens
2026-05-23 18:25:42.613 | 19.33.485.880 I slot launch_slot_: id  1 | task 11648 | processing task, is_child = 0
2026-05-23 18:25:44.278 | 19.35.149.939 I slot print_timing: id  2 | task 10972 | n_decoded =   1861, tg =  28.41 t/s
2026-05-23 18:25:46.462 | 19.37.334.825 I slot print_timing: id  1 | task 11648 | prompt processing, n_tokens =   4084, progress = 0.93, t =   4.34 s / 940.39 tokens per second
2026-05-23 18:25:47.186 | 19.38.058.537 I slot print_timing: id  1 | task 11648 | prompt processing, n_tokens =   4658, progress = 0.97, t =   5.07 s / 919.36 tokens per second
2026-05-23 18:25:47.427 | 19.38.299.255 I slot create_check: id  1 | task 11648 | created context checkpoint 5 of 32 (pos_min = 14646, pos_max = 14646, n_tokens = 14647, size = 180.301 MiB)
2026-05-23 18:25:48.070 | 19.38.941.963 I slot print_timing: id  2 | task 10972 | n_decoded =   1870, tg =  26.99 t/s
2026-05-23 18:25:48.076 | 19.38.948.750 I slot print_timing: id  1 | task 11648 | prompt processing, n_tokens =   5170, progress = 1.00, t =   5.96 s / 867.92 tokens per second
2026-05-23 18:25:47.858 | 19.38.730.249 I slot create_check: id  1 | task 11648 | created context checkpoint 6 of 32 (pos_min = 15158, pos_max = 15158, n_tokens = 15159, size = 181.373 MiB)
2026-05-23 18:25:48.252 | 19.39.124.283 I slot print_timing: id  0 | task 11609 | n_decoded =    102, tg =   8.97 t/s
2026-05-23 18:25:49.011 | 19.39.883.663 I reasoning-budget: deactivated (natural end)
2026-05-23 18:25:50.697 | 19.41.569.067 I slot print_timing: id  2 | task 10972 | n_decoded =   1927, tg =  26.61 t/s
2026-05-23 18:25:51.303 | 19.42.175.755 I slot print_timing: id  0 | task 11609 | n_decoded =    159, tg =  11.02 t/s
2026-05-23 18:25:52.069 | 19.42.941.402 I slot print_timing: id  0 | task 11609 | 
2026-05-23 18:25:52.069 | prompt eval time =    8090.86 ms /  7268 tokens (    1.11 ms per token,   898.30 tokens per second)
2026-05-23 18:25:52.069 |        eval time =   15190.38 ms /   173 tokens (   87.81 ms per token,    11.39 tokens per second)
2026-05-23 18:25:52.069 |       total time =   23281.24 ms /  7441 tokens
2026-05-23 18:25:52.069 | draft acceptance rate = 0.84375 (  108 accepted /   128 generated)
2026-05-23 18:25:52.069 | 19.42.941.437 I statistics draft-mtp: #calls(b,g,a) = 34 11526 11948, #gen drafts = 11950, #acc drafts = 10589, #gen tokens = 23900, #acc tokens = 19951, dur(b,g,a) = 0.050, 57261.191, 23.519 ms
2026-05-23 18:25:52.069 | 19.42.941.840 I slot      release: id  0 | task 11609 | stop processing: n_tokens = 7440, truncated = 0
2026-05-23 18:25:52.215 | 19.43.087.032 I srv  params_from_: Chat format: peg-native
2026-05-23 18:25:52.292 | 19.43.164.501 I slot get_availabl: id  0 | task -1 | selected slot by LCP similarity, sim_best = 0.671 (> 0.100 thold), f_keep = 1.000
2026-05-23 18:25:52.293 | 19.43.165.009 I reasoning-budget: activated, budget=2147483647 tokens
2026-05-23 18:25:52.293 | 19.43.165.095 I slot launch_slot_: id  0 | task 11683 | processing task, is_child = 0
2026-05-23 18:25:54.018 | 19.44.890.294 I slot print_timing: id  2 | task 10972 | n_decoded =   1962, tg =  25.74 t/s
2026-05-23 18:25:55.315 | 19.46.187.820 I slot print_timing: id  0 | task 11683 | prompt processing, n_tokens =   3138, progress = 0.95, t =   3.52 s / 892.52 tokens per second
2026-05-23 18:25:55.506 | 19.46.378.656 I slot create_check: id  0 | task 11683 | created context checkpoint 3 of 32 (pos_min = 10577, pos_max = 10577, n_tokens = 10578, size = 171.779 MiB)
2026-05-23 18:25:56.175 | 19.47.047.388 I slot print_timing: id  0 | task 11683 | prompt processing, n_tokens =   3650, progress = 1.00, t =   4.38 s / 834.20 tokens per second
2026-05-23 18:25:56.385 | 19.47.257.503 I slot create_check: id  0 | task 11683 | created context checkpoint 4 of 32 (pos_min = 11089, pos_max = 11089, n_tokens = 11090, size = 172.852 MiB)
2026-05-23 18:25:56.834 | 19.47.706.352 I slot print_timing: id  1 | task 11648 | n_decoded =    102, tg =  10.86 t/s
2026-05-23 18:25:57.143 | 19.48.015.365 I slot print_timing: id  2 | task 10972 | n_decoded =   1981, tg =  24.96 t/s
2026-05-23 18:25:58.472 | 19.49.343.967 I reasoning-budget: deactivated (natural end)
2026-05-23 18:25:59.390 | 19.50.262.440 I slot print_timing: id  1 | task 11648 | n_decoded =    162, tg =  13.01 t/s
2026-05-23 18:25:59.703 | 19.50.575.510 I slot print_timing: id  2 | task 10972 | n_decoded =   2039, tg =  24.74 t/s
2026-05-23 18:26:01.877 | 19.52.749.849 I slot print_timing: id  0 | task 11683 | n_decoded =    101, tg =  17.23 t/s
2026-05-23 18:26:02.499 | 19.53.371.486 I slot print_timing: id  1 | task 11648 | n_decoded =    222, tg =  14.27 t/s
2026-05-23 18:26:02.812 | 19.53.684.600 I slot print_timing: id  2 | task 10972 | n_decoded =   2099, tg =  24.54 t/s
2026-05-23 18:26:04.490 | 19.55.362.739 I slot print_timing: id  0 | task 11683 | n_decoded =    161, tg =  17.95 t/s
2026-05-23 18:26:05.118 | 19.55.990.548 I slot print_timing: id  1 | task 11648 | n_decoded =    282, tg =  15.10 t/s
2026-05-23 18:26:05.427 | 19.56.299.313 I slot print_timing: id  2 | task 10972 | n_decoded =   2152, tg =  24.28 t/s
2026-05-23 18:26:07.633 | 19.58.505.048 I slot print_timing: id  0 | task 11683 | 
2026-05-23 18:26:07.633 | prompt eval time =    4722.21 ms /  3654 tokens (    1.29 ms per token,   773.79 tokens per second)
2026-05-23 18:26:07.633 |        eval time =   12112.04 ms /   219 tokens (   55.31 ms per token,    18.08 tokens per second)
2026-05-23 18:26:07.633 |       total time =   16834.26 ms /  3873 tokens
2026-05-23 18:26:07.633 | draft acceptance rate = 0.91026 (  142 accepted /   156 generated)
2026-05-23 18:26:07.633 | 19.58.505.086 I statistics draft-mtp: #calls(b,g,a) = 35 11610 12194, #gen drafts = 12196, #acc drafts = 10825, #gen tokens = 24392, #acc tokens = 20418, dur(b,g,a) = 0.051, 57998.894, 24.201 ms
2026-05-23 18:26:07.633 | 19.58.505.541 I slot      release: id  0 | task 11683 | stop processing: n_tokens = 11314, truncated = 0
2026-05-23 18:26:07.633 | 19.58.505.597 I slot print_timing: id  0 | task -1 | n_decoded =    219, tg =  18.08 t/s
2026-05-23 18:26:07.758 | 19.58.629.972 I srv  params_from_: Chat format: peg-native
2026-05-23 18:26:07.859 | 19.58.731.826 I slot get_availabl: id  0 | task -1 | selected slot by LCP similarity, sim_best = 0.954 (> 0.100 thold), f_keep = 1.000
2026-05-23 18:26:07.860 | 19.58.732.372 I reasoning-budget: activated, budget=2147483647 tokens
2026-05-23 18:26:07.860 | 19.58.732.462 I slot launch_slot_: id  0 | task 11768 | processing task, is_child = 0
2026-05-23 18:26:08.223 | 19.59.095.238 I slot create_check: id  0 | task 11768 | created context checkpoint 5 of 32 (pos_min = 11348, pos_max = 11348, n_tokens = 11349, size = 173.394 MiB)
2026-05-23 18:26:08.390 | 19.59.262.008 I slot print_timing: id  1 | task 11648 | n_decoded =    342, tg =  15.24 t/s
2026-05-23 18:26:08.393 | 19.59.265.308 I slot print_timing: id  2 | task 10972 | n_decoded =   2206, tg =  23.95 t/s
2026-05-23 18:26:08.616 | 19.59.488.726 I slot create_check: id  0 | task 11768 | created context checkpoint 6 of 32 (pos_min = 11860, pos_max = 11860, n_tokens = 11861, size = 174.466 MiB)
2026-05-23 18:26:10.137 | 20.01.009.321 I reasoning-budget: deactivated (natural end)
2026-05-23 18:26:11.537 | 20.02.409.745 I slot print_timing: id  1 | task 11648 | n_decoded =    399, tg =  15.59 t/s
2026-05-23 18:26:11.541 | 20.02.413.542 I slot print_timing: id  2 | task 10972 | n_decoded =   2255, tg =  23.67 t/s
2026-05-23 18:26:13.827 | 20.04.699.331 I slot print_timing: id  0 | task 11768 | n_decoded =    102, tg =  18.30 t/s
2026-05-23 18:26:14.137 | 20.05.009.172 I slot print_timing: id  1 | task 11648 | n_decoded =    459, tg =  16.00 t/s
2026-05-23 18:26:14.140 | 20.05.012.846 I slot print_timing: id  2 | task 10972 | n_decoded =   2312, tg =  23.51 t/s
2026-05-23 18:26:16.754 | 20.07.626.093 I slot print_timing: id  0 | task 11768 | n_decoded =    162, tg =  18.67 t/s
2026-05-23 18:26:17.068 | 20.07.940.272 I slot print_timing: id  1 | task 11648 | n_decoded =    519, tg =  16.32 t/s
2026-05-23 18:26:17.071 | 20.07.943.574 I slot print_timing: id  2 | task 10972 | n_decoded =   2372, tg =  23.38 t/s
2026-05-23 18:26:19.528 | 20.10.400.782 I slot print_timing: id  0 | task 11768 | n_decoded =    222, tg =  18.85 t/s
2026-05-23 18:26:19.840 | 20.10.712.880 I slot print_timing: id  1 | task 11648 | n_decoded =    579, tg =  16.59 t/s
2026-05-23 18:26:19.844 | 20.10.716.263 I slot print_timing: id  2 | task 10972 | n_decoded =   2431, tg =  23.25 t/s
2026-05-23 18:26:22.654 | 20.13.526.284 I slot print_timing: id  0 | task 11768 | n_decoded =    282, tg =  18.92 t/s
2026-05-23 18:26:22.967 | 20.13.839.212 I slot print_timing: id  1 | task 11648 | n_decoded =    639, tg =  16.80 t/s
2026-05-23 18:26:22.970 | 20.13.842.352 I slot print_timing: id  2 | task 10972 | n_decoded =   2491, tg =  23.13 t/s
2026-05-23 18:26:23.172 | 20.14.044.001 I slot print_timing: id  1 | task 11648 | 
2026-05-23 18:26:23.172 | prompt eval time =    6325.51 ms /  5174 tokens (    1.22 ms per token,   817.96 tokens per second)
2026-05-23 18:26:23.172 |        eval time =   38229.92 ms /   640 tokens (   59.73 ms per token,    16.74 tokens per second)
2026-05-23 18:26:23.172 |       total time =   44555.43 ms /  5814 tokens
2026-05-23 18:26:23.172 | draft acceptance rate = 0.99070 (  426 accepted /   430 generated)
2026-05-23 18:26:23.172 | 20.14.044.040 I statistics draft-mtp: #calls(b,g,a) = 36 11714 12502, #gen drafts = 12503, #acc drafts = 11127, #gen tokens = 25006, #acc tokens = 21015, dur(b,g,a) = 0.052, 58912.622, 25.044 ms
2026-05-23 18:26:23.172 | 20.14.044.586 I slot      release: id  1 | task 11648 | stop processing: n_tokens = 15804, truncated = 0
2026-05-23 18:26:23.285 | 20.14.157.120 I slot print_timing: id  2 | task 10972 | 
2026-05-23 18:26:23.285 | prompt eval time =    1175.04 ms /   393 tokens (    2.99 ms per token,   334.46 tokens per second)
2026-05-23 18:26:23.285 |        eval time =  108007.45 ms /  2496 tokens (   43.27 ms per token,    23.11 tokens per second)
2026-05-23 18:26:23.285 |       total time =  109182.48 ms /  2889 tokens
2026-05-23 18:26:23.285 | draft acceptance rate = 0.90067 ( 1605 accepted /  1782 generated)
2026-05-23 18:26:23.285 | 20.14.157.151 I statistics draft-mtp: #calls(b,g,a) = 36 11715 12505, #gen drafts = 12505, #acc drafts = 11130, #gen tokens = 25010, #acc tokens = 21021, dur(b,g,a) = 0.052, 58920.313, 25.053 ms
2026-05-23 18:26:23.287 | 20.14.159.264 I slot      release: id  2 | task 10972 | stop processing: n_tokens = 83506, truncated = 0
2026-05-23 18:26:23.382 | 20.14.254.240 I srv  params_from_: Chat format: peg-native
2026-05-23 18:26:23.399 | 20.14.271.033 I slot get_availabl: id  1 | task -1 | selected slot by LCP similarity, sim_best = 0.772 (> 0.100 thold), f_keep = 1.000
2026-05-23 18:26:23.399 | 20.14.271.651 I reasoning-budget: activated, budget=2147483647 tokens
2026-05-23 18:26:23.399 | 20.14.271.731 I slot launch_slot_: id  1 | task 11874 | processing task, is_child = 0
2026-05-23 18:26:23.399 | 20.14.271.750 I slot slot_save_an: id  2 | task -1 | saving idle slot to prompt cache
2026-05-23 18:26:23.403 | 20.14.275.245 W srv   prompt_save:  - saving prompt with length 83506, total state size = 3098.763 MiB (draft: 174.884 MiB)
2026-05-23 18:26:23.404 | 20.14.276.238 I srv  params_from_: Chat format: peg-native
2026-05-23 18:26:34.669 | 20.25.541.859 I slot prompt_clear: id  2 | task -1 | clearing prompt with 83506 tokens
2026-05-23 18:26:34.686 | 20.25.558.041 W srv        update:  - cache size limit reached, removing oldest entry (size = 509.021 MiB)
2026-05-23 18:26:34.723 | 20.25.595.620 W srv        update:  - cache size limit reached, removing oldest entry (size = 7085.298 MiB)
2026-05-23 18:26:35.176 | 20.26.048.471 I srv        update:  - cache state: 1 prompts, 10326.332 MiB (limits: 8192.000 MiB, 131072 tokens, 131072 est)
2026-05-23 18:26:35.176 | 20.26.048.497 I srv        update:    - prompt 0x63d3b1e44540:   83506 tokens, checkpoints: 26, 10326.332 MiB
2026-05-23 18:26:35.176 | 20.26.048.506 I slot get_availabl: id  3 | task -1 | selected slot by LRU, t_last = 264438943
2026-05-23 18:26:35.176 | 20.26.048.507 I srv  get_availabl: updating prompt cache
2026-05-23 18:26:35.176 | 20.26.048.509 I srv          load:  - looking for better prompt, base f_keep = -1.000, sim = 0.000
2026-05-23 18:26:35.176 | 20.26.048.513 I srv        update:  - cache state: 1 prompts, 10326.332 MiB (limits: 8192.000 MiB, 131072 tokens, 131072 est)
2026-05-23 18:26:35.176 | 20.26.048.513 I srv        update:    - prompt 0x63d3b1e44540:   83506 tokens, checkpoints: 26, 10326.332 MiB
2026-05-23 18:26:35.176 | 20.26.048.514 I srv  get_availabl: prompt cache update took 0.01 ms
2026-05-23 18:26:35.178 | 20.26.050.288 I reasoning-budget: activated, budget=2147483647 tokens
2026-05-23 18:26:35.178 | 20.26.050.366 I slot launch_slot_: id  3 | task 11875 | processing task, is_child = 0
2026-05-23 18:26:37.479 | 20.28.351.071 I slot print_timing: id  0 | task 11768 | n_decoded =    303, tg =   9.70 t/s
2026-05-23 18:26:39.193 | 20.30.065.791 I slot print_timing: id  1 | task 11874 | prompt processing, n_tokens =   4090, progress = 0.97, t =   4.51 s / 907.12 tokens per second
2026-05-23 18:26:39.193 | 20.30.065.947 W slot update_slots: id  3 | task 11875 | erased invalidated context checkpoint (pos_min = 358, pos_max = 358, n_tokens = 359, n_swa = 0, pos_next = 0, size = 150.378 MiB)
2026-05-23 18:26:39.203 | 20.30.075.445 W slot update_slots: id  3 | task 11875 | erased invalidated context checkpoint (pos_min = 870, pos_max = 870, n_tokens = 871, n_swa = 0, pos_next = 0, size = 151.450 MiB)
2026-05-23 18:26:41.447 | 20.32.319.729 I slot print_timing: id  0 | task 11768 | n_decoded =    309, tg =   8.66 t/s
2026-05-23 18:26:41.453 | 20.32.325.686 I slot print_timing: id  1 | task 11874 | prompt processing, n_tokens =   4155, progress = 0.97, t =   6.77 s / 613.86 tokens per second
2026-05-23 18:26:41.706 | 20.32.578.708 I slot create_check: id  1 | task 11874 | created context checkpoint 7 of 32 (pos_min = 19958, pos_max = 19958, n_tokens = 19959, size = 191.426 MiB)
2026-05-23 18:26:43.419 | 20.34.291.324 I slot print_timing: id  1 | task 11874 | prompt processing, n_tokens =   4667, progress = 1.00, t =   9.23 s / 505.37 tokens per second
2026-05-23 18:26:43.714 | 20.34.586.133 I slot create_check: id  1 | task 11874 | created context checkpoint 8 of 32 (pos_min = 20470, pos_max = 20470, n_tokens = 20471, size = 192.498 MiB)
2026-05-23 18:26:43.714 | 20.34.586.158 I slot print_timing: id  3 | task 11875 | prompt processing, n_tokens =   3513, progress = 0.49, t =   5.02 s / 699.71 tokens per second
2026-05-23 18:26:46.002 | 20.36.874.339 I slot print_timing: id  0 | task 11768 | n_decoded =    315, tg =   7.73 t/s
2026-05-23 18:26:46.010 | 20.36.882.086 I slot print_timing: id  3 | task 11875 | prompt processing, n_tokens =   5554, progress = 0.77, t =   7.32 s / 759.10 tokens per second
2026-05-23 18:26:47.335 | 20.38.207.829 I slot print_timing: id  3 | task 11875 | prompt processing, n_tokens =   6685, progress = 0.93, t =   8.64 s / 773.52 tokens per second
2026-05-23 18:26:47.526 | 20.38.398.115 I slot create_check: id  3 | task 11875 | created context checkpoint 1 of 32 (pos_min = 6684, pos_max = 6684, n_tokens = 6685, size = 163.626 MiB)
2026-05-23 18:26:48.210 | 20.39.082.549 I slot print_timing: id  3 | task 11875 | prompt processing, n_tokens =   7197, progress = 1.00, t =   9.52 s / 756.22 tokens per second
2026-05-23 18:26:48.418 | 20.39.290.704 I slot create_check: id  3 | task 11875 | created context checkpoint 2 of 32 (pos_min = 7196, pos_max = 7196, n_tokens = 7197, size = 164.699 MiB)
2026-05-23 18:26:48.531 | 20.39.403.417 I slot print_timing: id  0 | task 11768 | n_decoded =    333, tg =   7.60 t/s
2026-05-23 18:26:49.829 | 20.40.701.635 I reasoning-budget: deactivated (natural end)
2026-05-23 18:26:51.555 | 20.42.427.816 I slot print_timing: id  0 | task 11768 | n_decoded =    390, tg =   8.33 t/s
2026-05-23 18:26:52.785 | 20.43.657.832 I slot print_timing: id  1 | task 11874 | n_decoded =    100, tg =  13.71 t/s
2026-05-23 18:26:53.662 | 20.44.534.239 I slot print_timing: id  3 | task 11875 | n_decoded =    102, tg =  16.70 t/s
2026-05-23 18:26:54.118 | 20.44.990.610 I slot print_timing: id  0 | task 11768 | n_decoded =    450, tg =   9.02 t/s
2026-05-23 18:26:54.124 | 20.44.996.447 I slot print_timing: id  3 | task 11875 | 
2026-05-23 18:26:54.124 | prompt eval time =    9866.12 ms /  7201 tokens (    1.37 ms per token,   729.87 tokens per second)
2026-05-23 18:26:54.124 |        eval time =    6571.50 ms /   110 tokens (   59.74 ms per token,    16.74 tokens per second)
2026-05-23 18:26:54.124 |       total time =   16437.62 ms /  7311 tokens
2026-05-23 18:26:54.124 | draft acceptance rate = 0.80952 (   68 accepted /    84 generated)
2026-05-23 18:26:54.124 | 20.44.996.479 I statistics draft-mtp: #calls(b,g,a) = 38 11767 12644, #gen drafts = 12644, #acc drafts = 11261, #gen tokens = 25288, #acc tokens = 21278, dur(b,g,a) = 0.058, 59381.124, 25.477 ms
2026-05-23 18:26:54.124 | 20.44.996.903 I slot      release: id  3 | task 11875 | stop processing: n_tokens = 7311, truncated = 0
2026-05-23 18:26:54.286 | 20.45.158.498 I srv  params_from_: Chat format: peg-native
2026-05-23 18:26:54.341 | 20.45.213.256 I slot get_availabl: id  3 | task -1 | selected slot by LCP similarity, sim_best = 0.830 (> 0.100 thold), f_keep = 1.000
2026-05-23 18:26:54.341 | 20.45.213.811 I reasoning-budget: activated, budget=2147483647 tokens
2026-05-23 18:26:54.342 | 20.45.214.026 I slot launch_slot_: id  3 | task 11928 | processing task, is_child = 0
2026-05-23 18:26:55.483 | 20.46.355.610 I slot print_timing: id  1 | task 11874 | n_decoded =    140, tg =  13.34 t/s
2026-05-23 18:26:55.697 | 20.46.569.423 I slot create_check: id  3 | task 11928 | created context checkpoint 3 of 32 (pos_min = 8290, pos_max = 8290, n_tokens = 8291, size = 166.990 MiB)
2026-05-23 18:26:56.583 | 20.47.455.548 I slot create_check: id  3 | task 11928 | created context checkpoint 4 of 32 (pos_min = 8802, pos_max = 8802, n_tokens = 8803, size = 168.062 MiB)
2026-05-23 18:26:57.171 | 20.48.043.369 I slot print_timing: id  0 | task 11768 | n_decoded =    474, tg =   8.96 t/s
2026-05-23 18:26:57.637 | 20.48.509.696 I reasoning-budget: deactivated (natural end)
2026-05-23 18:26:58.556 | 20.49.428.427 I slot print_timing: id  1 | task 11874 | n_decoded =    170, tg =  12.53 t/s
2026-05-23 18:26:59.042 | 20.49.914.402 I slot print_timing: id  3 | task 11928 | 
2026-05-23 18:26:59.042 | prompt eval time =    2372.82 ms /  1496 tokens (    1.59 ms per token,   630.47 tokens per second)
2026-05-23 18:26:59.042 |        eval time =    2814.69 ms /    49 tokens (   57.44 ms per token,    17.41 tokens per second)
2026-05-23 18:26:59.042 |       total time =    5187.51 ms /  1545 tokens
2026-05-23 18:26:59.042 | draft acceptance rate = 0.88889 (   32 accepted /    36 generated)
2026-05-23 18:26:59.042 | 20.49.914.443 I statistics draft-mtp: #calls(b,g,a) = 39 11790 12708, #gen drafts = 12708, #acc drafts = 11320, #gen tokens = 25416, #acc tokens = 21389, dur(b,g,a) = 0.060, 59572.057, 25.648 ms
2026-05-23 18:26:59.042 | 20.49.914.887 I slot      release: id  3 | task 11928 | stop processing: n_tokens = 8857, truncated = 0
2026-05-23 18:26:59.210 | 20.50.082.415 I srv  params_from_: Chat format: peg-native
2026-05-23 18:26:59.259 | 20.50.131.362 I slot get_availabl: id  3 | task -1 | selected slot by LCP similarity, sim_best = 0.835 (> 0.100 thold), f_keep = 1.000
2026-05-23 18:26:59.260 | 20.50.131.971 I reasoning-budget: activated, budget=2147483647 tokens
2026-05-23 18:26:59.260 | 20.50.132.068 I slot launch_slot_: id  3 | task 11952 | processing task, is_child = 0
2026-05-23 18:27:00.636 | 20.51.507.961 I slot print_timing: id  0 | task 11768 | n_decoded =    528, tg =   9.28 t/s
2026-05-23 18:27:00.839 | 20.51.710.973 I slot create_check: id  3 | task 11952 | created context checkpoint 5 of 32 (pos_min = 10094, pos_max = 10094, n_tokens = 10095, size = 170.768 MiB)
2026-05-23 18:27:01.519 | 20.52.391.010 I slot print_timing: id  1 | task 11874 | n_decoded =    196, tg =  11.51 t/s
2026-05-23 18:27:01.732 | 20.52.604.170 I slot create_check: id  3 | task 11952 | created context checkpoint 6 of 32 (pos_min = 10606, pos_max = 10606, n_tokens = 10607, size = 171.840 MiB)
2026-05-23 18:27:03.296 | 20.54.168.051 I reasoning-budget: deactivated (natural end)
2026-05-23 18:27:03.769 | 20.54.640.909 I slot print_timing: id  0 | task 11768 | n_decoded =    570, tg =   9.50 t/s
2026-05-23 18:27:04.099 | 20.54.970.959 I slot print_timing: id  1 | task 11874 | n_decoded =    250, tg =  12.44 t/s
2026-05-23 18:27:06.411 | 20.57.283.579 I slot print_timing: id  0 | task 11768 | n_decoded =    627, tg =   9.93 t/s
2026-05-23 18:27:07.034 | 20.57.905.985 I slot print_timing: id  3 | task 11952 | n_decoded =    102, tg =  18.00 t/s
2026-05-23 18:27:07.187 | 20.58.059.541 I slot print_timing: id  1 | task 11874 | n_decoded =    306, tg =  13.19 t/s
2026-05-23 18:27:08.990 | 20.59.862.403 I slot print_timing: id  0 | task 11768 | n_decoded =    687, tg =  10.37 t/s
2026-05-23 18:27:09.608 | 21.00.480.464 I slot print_timing: id  3 | task 11952 | n_decoded =    162, tg =  18.53 t/s
2026-05-23 18:27:09.631 | 21.00.503.515 I slot print_timing: id  1 | task 11874 | n_decoded =    350, tg =  13.32 t/s
2026-05-23 18:27:11.934 | 21.02.806.539 I slot print_timing: id  0 | task 11768 | n_decoded =    746, tg =  10.76 t/s
2026-05-23 18:27:12.549 | 21.03.421.224 I slot print_timing: id  3 | task 11952 | n_decoded =    222, tg =  18.79 t/s
2026-05-23 18:27:12.699 | 21.03.571.340 I slot print_timing: id  1 | task 11874 | n_decoded =    387, tg =  13.19 t/s
2026-05-23 18:27:13.544 | 21.04.416.412 I slot print_timing: id  0 | task 11768 | 
2026-05-23 18:27:13.544 | prompt eval time =    1384.24 ms /   551 tokens (    2.51 ms per token,   398.05 tokens per second)
2026-05-23 18:27:13.544 |        eval time =   71299.24 ms /   785 tokens (   90.83 ms per token,    11.01 tokens per second)
2026-05-23 18:27:13.544 |       total time =   72683.48 ms /  1336 tokens
2026-05-23 18:27:13.544 | draft acceptance rate = 0.98485 (  520 accepted /   528 generated)
2026-05-23 18:27:13.544 | 21.04.416.448 I statistics draft-mtp: #calls(b,g,a) = 40 11879 12968, #gen drafts = 12970, #acc drafts = 11559, #gen tokens = 25940, #acc tokens = 21855, dur(b,g,a) = 0.062, 60326.788, 26.389 ms
2026-05-23 18:27:13.545 | 21.04.417.002 I slot      release: id  0 | task 11768 | stop processing: n_tokens = 12649, truncated = 0
2026-05-23 18:27:13.767 | 21.04.639.077 I srv  params_from_: Chat format: peg-native
2026-05-23 18:27:13.768 | 21.04.640.447 I slot get_availabl: id  0 | task -1 | selected slot by LCP similarity, sim_best = 0.785 (> 0.100 thold), f_keep = 1.000
2026-05-23 18:27:13.768 | 21.04.641.012 I reasoning-budget: activated, budget=2147483647 tokens
2026-05-23 18:27:13.769 | 21.04.641.130 I slot launch_slot_: id  0 | task 12042 | processing task, is_child = 0
2026-05-23 18:27:16.039 | 21.06.911.854 I slot print_timing: id  1 | task 11874 | n_decoded =    411, tg =  12.44 t/s
2026-05-23 18:27:16.043 | 21.06.915.396 I slot print_timing: id  3 | task 11952 | n_decoded =    258, tg =  16.46 t/s
2026-05-23 18:27:17.031 | 21.07.903.559 I slot print_timing: id  0 | task 12042 | prompt processing, n_tokens =   2955, progress = 0.97, t =   3.26 s / 907.70 tokens per second
2026-05-23 18:27:17.254 | 21.08.126.189 I slot create_check: id  0 | task 12042 | created context checkpoint 7 of 32 (pos_min = 15603, pos_max = 15603, n_tokens = 15604, size = 182.305 MiB)
2026-05-23 18:27:17.930 | 21.08.802.678 I slot print_timing: id  0 | task 12042 | prompt processing, n_tokens =   3467, progress = 1.00, t =   4.15 s / 834.50 tokens per second
2026-05-23 18:27:18.191 | 21.09.063.046 I slot create_check: id  0 | task 12042 | created context checkpoint 8 of 32 (pos_min = 16115, pos_max = 16115, n_tokens = 16116, size = 183.377 MiB)
2026-05-23 18:27:18.596 | 21.09.468.536 I slot print_timing: id  1 | task 11874 | n_decoded =    430, tg =  11.91 t/s
2026-05-23 18:27:18.599 | 21.09.471.617 I slot print_timing: id  3 | task 11952 | n_decoded =    282, tg =  15.05 t/s
2026-05-23 18:27:19.960 | 21.10.832.860 I reasoning-budget: deactivated (natural end)
2026-05-23 18:27:21.646 | 21.12.518.716 I slot print_timing: id  1 | task 11874 | n_decoded =    471, tg =  12.03 t/s
2026-05-23 18:27:21.650 | 21.12.522.110 I slot print_timing: id  3 | task 11952 | n_decoded =    342, tg =  15.70 t/s
2026-05-23 18:27:23.322 | 21.14.194.038 I slot print_timing: id  0 | task 12042 | n_decoded =    100, tg =  18.20 t/s
2026-05-23 18:27:24.196 | 21.15.067.944 I slot print_timing: id  1 | task 11874 | n_decoded =    509, tg =  12.06 t/s
2026-05-23 18:27:24.198 | 21.15.070.794 I slot print_timing: id  3 | task 11952 | n_decoded =    402, tg =  16.19 t/s
2026-05-23 18:27:25.885 | 21.16.757.187 I slot print_timing: id  0 | task 12042 | n_decoded =    160, tg =  18.70 t/s
2026-05-23 18:27:27.277 | 21.18.149.842 I slot print_timing: id  1 | task 11874 | n_decoded =    554, tg =  12.23 t/s
2026-05-23 18:27:27.280 | 21.18.152.817 I slot print_timing: id  3 | task 11952 | n_decoded =    462, tg =  16.55 t/s
2026-05-23 18:27:28.470 | 21.19.342.057 I slot print_timing: id  0 | task 12042 | n_decoded =    220, tg =  18.89 t/s
2026-05-23 18:27:29.869 | 21.20.741.624 I slot print_timing: id  1 | task 11874 | n_decoded =    598, tg =  12.36 t/s
2026-05-23 18:27:29.872 | 21.20.744.470 I slot print_timing: id  3 | task 11952 | n_decoded =    522, tg =  16.83 t/s
2026-05-23 18:27:31.574 | 21.22.446.006 I slot print_timing: id  0 | task 12042 | n_decoded =    280, tg =  18.99 t/s
2026-05-23 18:27:32.977 | 21.23.849.021 I slot print_timing: id  1 | task 11874 | n_decoded =    647, tg =  12.57 t/s
2026-05-23 18:27:32.980 | 21.23.852.066 I slot print_timing: id  3 | task 11952 | n_decoded =    582, tg =  17.06 t/s
2026-05-23 18:27:34.162 | 21.25.034.010 I slot print_timing: id  0 | task 12042 | n_decoded =    340, tg =  19.06 t/s
2026-05-23 18:27:34.781 | 21.25.653.652 I slot print_timing: id  3 | task 11952 | 
2026-05-23 18:27:34.781 | prompt eval time =    2600.86 ms /  1754 tokens (    1.48 ms per token,   674.39 tokens per second)
2026-05-23 18:27:34.781 |        eval time =   36417.05 ms /   626 tokens (   58.17 ms per token,    17.19 tokens per second)
2026-05-23 18:27:34.781 |       total time =   39017.91 ms /  2380 tokens
2026-05-23 18:27:34.781 | draft acceptance rate = 0.99048 (  416 accepted /   420 generated)
2026-05-23 18:27:34.781 | 21.25.653.683 I statistics draft-mtp: #calls(b,g,a) = 41 12005 13342, #gen drafts = 13342, #acc drafts = 11900, #gen tokens = 26684, #acc tokens = 22498, dur(b,g,a) = 0.064, 61409.977, 27.428 ms
2026-05-23 18:27:34.782 | 21.25.654.198 I slot      release: id  3 | task 11952 | stop processing: n_tokens = 11237, truncated = 0
2026-05-23 18:27:35.016 | 21.25.888.538 I srv  params_from_: Chat format: peg-native
2026-05-23 18:27:35.099 | 21.25.971.121 I slot get_availabl: id  3 | task -1 | selected slot by LCP similarity, sim_best = 0.682 (> 0.100 thold), f_keep = 1.000
2026-05-23 18:27:35.099 | 21.25.971.679 I reasoning-budget: activated, budget=2147483647 tokens
2026-05-23 18:27:35.099 | 21.25.971.775 I slot launch_slot_: id  3 | task 12170 | processing task, is_child = 0
2026-05-23 18:27:37.011 | 21.27.883.711 I slot print_timing: id  0 | task 12042 | n_decoded =    364, tg =  17.30 t/s
2026-05-23 18:27:37.013 | 21.27.885.925 I slot print_timing: id  1 | task 11874 | n_decoded =    694, tg =  12.31 t/s
2026-05-23 18:27:39.130 | 21.30.001.965 I slot print_timing: id  3 | task 12170 | prompt processing, n_tokens =   4084, progress = 0.93, t =   4.53 s / 901.58 tokens per second
2026-05-23 18:27:39.911 | 21.30.783.780 I slot print_timing: id  0 | task 12042 | n_decoded =    370, tg =  15.36 t/s
2026-05-23 18:27:39.913 | 21.30.785.265 I slot print_timing: id  1 | task 11874 | n_decoded =    698, tg =  11.75 t/s
2026-05-23 18:27:39.920 | 21.30.792.837 I slot print_timing: id  3 | task 12170 | prompt processing, n_tokens =   4722, progress = 0.97, t =   5.32 s / 887.48 tokens per second
2026-05-23 18:27:40.125 | 21.30.997.252 I slot create_check: id  3 | task 12170 | created context checkpoint 7 of 32 (pos_min = 15958, pos_max = 15958, n_tokens = 15959, size = 183.049 MiB)
2026-05-23 18:27:40.802 | 21.31.674.193 I slot print_timing: id  3 | task 12170 | prompt processing, n_tokens =   5234, progress = 1.00, t =   6.20 s / 843.92 tokens per second
2026-05-23 18:27:41.050 | 21.31.922.682 I slot create_check: id  3 | task 12170 | created context checkpoint 8 of 32 (pos_min = 16470, pos_max = 16470, n_tokens = 16471, size = 184.121 MiB)
2026-05-23 18:27:41.964 | 21.32.836.723 I reasoning-budget: deactivated (natural end)
2026-05-23 18:27:43.036 | 21.33.907.974 I slot print_timing: id  0 | task 12042 | n_decoded =    412, tg =  15.14 t/s
2026-05-23 18:27:43.039 | 21.33.911.054 I slot print_timing: id  1 | task 11874 | n_decoded =    727, tg =  11.62 t/s
2026-05-23 18:27:45.612 | 21.36.484.810 I slot print_timing: id  0 | task 12042 | n_decoded =    472, tg =  15.58 t/s
2026-05-23 18:27:45.614 | 21.36.486.966 I slot print_timing: id  1 | task 11874 | n_decoded =    768, tg =  11.70 t/s
2026-05-23 18:27:45.922 | 21.36.794.415 I slot print_timing: id  3 | task 12170 | n_decoded =    101, tg =  19.32 t/s
2026-05-23 18:27:48.676 | 21.39.548.087 I slot print_timing: id  0 | task 12042 | n_decoded =    532, tg =  15.95 t/s
2026-05-23 18:27:48.677 | 21.39.549.639 I slot print_timing: id  1 | task 11874 | n_decoded =    806, tg =  11.73 t/s
2026-05-23 18:27:48.482 | 21.39.354.319 I slot print_timing: id  3 | task 12170 | n_decoded =    161, tg =  19.42 t/s
2026-05-23 18:27:51.246 | 21.42.118.783 I slot print_timing: id  0 | task 12042 | n_decoded =    592, tg =  16.25 t/s
2026-05-23 18:27:51.249 | 21.42.121.830 I slot print_timing: id  1 | task 11874 | n_decoded =    848, tg =  11.82 t/s
2026-05-23 18:27:51.556 | 21.42.428.925 I slot print_timing: id  3 | task 12170 | n_decoded =    221, tg =  19.45 t/s
2026-05-23 18:27:53.281 | 21.44.153.710 I slot print_timing: id  0 | task 12042 | 
2026-05-23 18:27:53.281 | prompt eval time =    4551.76 ms /  3471 tokens (    1.31 ms per token,   762.56 tokens per second)
2026-05-23 18:27:53.281 |        eval time =   38456.05 ms /   629 tokens (   61.14 ms per token,    16.36 tokens per second)
2026-05-23 18:27:53.281 |       total time =   43007.81 ms /  4100 tokens
2026-05-23 18:27:53.281 | draft acceptance rate = 0.97887 (  417 accepted /   426 generated)
2026-05-23 18:27:53.281 | 21.44.153.746 I statistics draft-mtp: #calls(b,g,a) = 42 12098 13611, #gen drafts = 13613, #acc drafts = 12135, #gen tokens = 27226, #acc tokens = 22942, dur(b,g,a) = 0.065, 62213.743, 28.172 ms
2026-05-23 18:27:53.282 | 21.44.154.356 I slot      release: id  0 | task 12042 | stop processing: n_tokens = 16750, truncated = 0
2026-05-23 18:27:53.488 | 21.44.360.099 I srv  params_from_: Chat format: peg-native
2026-05-23 18:27:53.506 | 21.44.378.133 I slot get_availabl: id  0 | task -1 | selected slot by LCP similarity, sim_best = 0.821 (> 0.100 thold), f_keep = 1.000
2026-05-23 18:27:53.506 | 21.44.378.678 I reasoning-budget: activated, budget=2147483647 tokens
2026-05-23 18:27:53.506 | 21.44.378.778 I slot launch_slot_: id  0 | task 12263 | processing task, is_child = 0
2026-05-23 18:27:55.256 | 21.46.128.664 I slot print_timing: id  1 | task 11874 | n_decoded =    879, tg =  11.52 t/s
2026-05-23 18:27:55.259 | 21.46.131.563 I slot print_timing: id  3 | task 12170 | n_decoded =    263, tg =  16.89 t/s
2026-05-23 18:27:56.566 | 21.47.438.436 I slot print_timing: id  0 | task 12263 | prompt processing, n_tokens =   3140, progress = 0.97, t =   3.56 s / 882.14 tokens per second
2026-05-23 18:27:56.858 | 21.47.730.167 I slot create_check: id  0 | task 12263 | created context checkpoint 9 of 32 (pos_min = 19889, pos_max = 19889, n_tokens = 19890, size = 191.281 MiB)
2026-05-23 18:27:57.533 | 21.48.405.184 I slot print_timing: id  0 | task 12263 | prompt processing, n_tokens =   3652, progress = 1.00, t =   4.53 s / 806.85 tokens per second
2026-05-23 18:27:57.824 | 21.48.696.645 I slot create_check: id  0 | task 12263 | created context checkpoint 10 of 32 (pos_min = 20401, pos_max = 20401, n_tokens = 20402, size = 192.353 MiB)
2026-05-23 18:27:58.264 | 21.49.136.558 I slot print_timing: id  1 | task 11874 | n_decoded =    891, tg =  11.24 t/s
2026-05-23 18:27:58.267 | 21.49.139.722 I slot print_timing: id  3 | task 12170 | n_decoded =    278, tg =  14.96 t/s
2026-05-23 18:27:58.527 | 21.49.399.135 I reasoning-budget: deactivated (natural end)
2026-05-23 18:28:00.827 | 21.51.699.592 I slot print_timing: id  1 | task 11874 | n_decoded =    932, tg =  11.32 t/s
2026-05-23 18:28:00.831 | 21.51.703.192 I slot print_timing: id  3 | task 12170 | n_decoded =    338, tg =  15.62 t/s
2026-05-23 18:28:02.666 | 21.53.537.965 I slot print_timing: id  0 | task 12263 | n_decoded =    100, tg =  19.23 t/s
2026-05-23 18:28:09.415 | 22.00.287.676 I slot print_timing: id  1 | task 11874 | n_decoded =    972, tg =  11.38 t/s
2026-05-23 18:28:09.419 | 22.00.291.209 I slot print_timing: id  3 | task 12170 | n_decoded =    398, tg =  16.12 t/s
2026-05-23 18:28:05.151 | 21.56.023.622 I slot print_timing: id  0 | task 12263 | n_decoded =    160, tg =  19.37 t/s
2026-05-23 18:28:06.393 | 21.57.265.110 I slot print_timing: id  1 | task 11874 | n_decoded =   1019, tg =  11.52 t/s
2026-05-23 18:28:06.396 | 21.57.268.523 I slot print_timing: id  3 | task 12170 | n_decoded =    458, tg =  16.49 t/s
2026-05-23 18:28:06.548 | 21.57.420.548 I reasoning-budget: deactivated (natural end)
2026-05-23 18:28:08.246 | 21.59.118.899 I slot print_timing: id  0 | task 12263 | n_decoded =    220, tg =  19.38 t/s
2026-05-23 18:28:09.052 | 21.59.924.522 I slot print_timing: id  1 | task 11874 | n_decoded =   1068, tg =  11.66 t/s
2026-05-23 18:28:09.055 | 21.59.927.924 I slot print_timing: id  3 | task 12170 | n_decoded =    518, tg =  16.78 t/s
2026-05-23 18:28:09.515 | 22.00.387.667 I slot print_timing: id  1 | task 11874 | 
2026-05-23 18:28:09.515 | prompt eval time =   11813.78 ms /  4671 tokens (    2.53 ms per token,   395.39 tokens per second)
2026-05-23 18:28:09.515 |        eval time =   92024.40 ms /  1076 tokens (   85.52 ms per token,    11.69 tokens per second)
2026-05-23 18:28:09.515 |       total time =  103838.17 ms /  5747 tokens
2026-05-23 18:28:09.515 | draft acceptance rate = 0.65203 (  609 accepted /   934 generated)
2026-05-23 18:28:09.515 | 22.00.387.700 I statistics draft-mtp: #calls(b,g,a) = 43 12189 13879, #gen drafts = 13880, #acc drafts = 12375, #gen tokens = 27760, #acc tokens = 23405, dur(b,g,a) = 0.066, 62996.388, 28.880 ms
2026-05-23 18:28:09.516 | 22.00.388.422 I slot      release: id  1 | task 11874 | stop processing: n_tokens = 21551, truncated = 0
2026-05-23 18:28:09.713 | 22.00.585.239 I srv  params_from_: Chat format: peg-native
2026-05-23 18:28:09.743 | 22.00.615.105 I slot get_availabl: id  1 | task -1 | selected slot by LCP similarity, sim_best = 0.999 (> 0.100 thold), f_keep = 1.000
2026-05-23 18:28:09.743 | 22.00.615.636 I reasoning-budget: activated, budget=2147483647 tokens
2026-05-23 18:28:09.743 | 22.00.615.758 I slot launch_slot_: id  1 | task 12355 | processing task, is_child = 0
2026-05-23 18:28:10.064 | 22.00.936.543 I slot create_check: id  1 | task 12355 | created context checkpoint 9 of 32 (pos_min = 21550, pos_max = 21550, n_tokens = 21551, size = 194.760 MiB)
2026-05-23 18:28:10.838 | 22.01.710.824 I slot print_timing: id  0 | task 12263 | n_decoded =    274, tg =  19.06 t/s
2026-05-23 18:28:12.091 | 22.02.963.795 I slot print_timing: id  3 | task 12170 | n_decoded =    572, tg =  16.87 t/s
2026-05-23 18:28:13.442 | 22.04.314.209 I slot print_timing: id  0 | task 12263 | n_decoded =    334, tg =  19.11 t/s
2026-05-23 18:28:13.796 | 22.04.667.999 I slot print_timing: id  3 | task 12170 | 
2026-05-23 18:28:13.796 | prompt eval time =    6588.02 ms /  5238 tokens (    1.26 ms per token,   795.08 tokens per second)
2026-05-23 18:28:13.796 |        eval time =   36103.98 ms /   612 tokens (   58.99 ms per token,    16.95 tokens per second)
2026-05-23 18:28:13.796 |       total time =   42692.00 ms /  5850 tokens
2026-05-23 18:28:13.796 | draft acceptance rate = 0.99512 (  408 accepted /   410 generated)
2026-05-23 18:28:13.796 | 22.04.668.038 I statistics draft-mtp: #calls(b,g,a) = 44 12218 13963, #gen drafts = 13963, #acc drafts = 12455, #gen tokens = 27926, #acc tokens = 23564, dur(b,g,a) = 0.067, 63243.648, 29.116 ms
2026-05-23 18:28:13.796 | 22.04.668.697 I slot      release: id  3 | task 12170 | stop processing: n_tokens = 17088, truncated = 0
2026-05-23 18:28:13.958 | 22.04.830.631 I srv  params_from_: Chat format: peg-native
2026-05-23 18:28:14.009 | 22.04.881.213 I slot get_availabl: id  3 | task -1 | selected slot by LCP similarity, sim_best = 0.746 (> 0.100 thold), f_keep = 1.000
2026-05-23 18:28:14.009 | 22.04.881.752 I reasoning-budget: activated, budget=2147483647 tokens
2026-05-23 18:28:14.009 | 22.04.881.870 I slot launch_slot_: id  3 | task 12385 | processing task, is_child = 0
2026-05-23 18:28:18.503 | 22.09.375.638 I slot print_timing: id  0 | task 12263 | n_decoded =    352, tg =  15.62 t/s
2026-05-23 18:28:18.522 | 22.09.394.488 I slot print_timing: id  3 | task 12385 | prompt processing, n_tokens =   4084, progress = 0.92, t =   4.51 s / 906.35 tokens per second
2026-05-23 18:28:19.400 | 22.10.272.546 I slot print_timing: id  3 | task 12385 | prompt processing, n_tokens =   5302, progress = 0.98, t =   5.89 s / 900.71 tokens per second
2026-05-23 18:28:19.665 | 22.10.537.634 I slot create_check: id  3 | task 12385 | created context checkpoint 9 of 32 (pos_min = 22389, pos_max = 22389, n_tokens = 22390, size = 196.517 MiB)
2026-05-23 18:28:20.341 | 22.11.213.214 I slot print_timing: id  3 | task 12385 | prompt processing, n_tokens =   5814, progress = 1.00, t =   6.83 s / 851.60 tokens per second
2026-05-23 18:28:20.628 | 22.11.500.626 I slot create_check: id  3 | task 12385 | created context checkpoint 10 of 32 (pos_min = 22901, pos_max = 22901, n_tokens = 22902, size = 197.589 MiB)
2026-05-23 18:28:21.074 | 22.11.946.783 I slot print_timing: id  0 | task 12263 | n_decoded =    367, tg =  14.33 t/s
2026-05-23 18:28:21.389 | 22.12.260.928 I slot print_timing: id  1 | task 12355 | n_decoded =    100, tg =   8.32 t/s
2026-05-23 18:28:22.314 | 22.13.186.563 I reasoning-budget: deactivated (natural end)
2026-05-23 18:28:23.649 | 22.14.521.520 I slot print_timing: id  0 | task 12263 | n_decoded =    427, tg =  14.88 t/s
2026-05-23 18:28:23.960 | 22.14.831.940 I slot print_timing: id  1 | task 12355 | n_decoded =    157, tg =  10.40 t/s
2026-05-23 18:28:24.609 | 22.15.481.067 I slot print_timing: id  3 | task 12385 | 
2026-05-23 18:28:24.609 | prompt eval time =    7253.06 ms /  5818 tokens (    1.25 ms per token,   802.14 tokens per second)
2026-05-23 18:28:24.609 |        eval time =    4347.80 ms /    73 tokens (   59.56 ms per token,    16.79 tokens per second)
2026-05-23 18:28:24.609 |       total time =   11600.86 ms /  5891 tokens
2026-05-23 18:28:24.609 | draft acceptance rate = 0.82143 (   46 accepted /    56 generated)
2026-05-23 18:28:24.609 | 22.15.481.100 I statistics draft-mtp: #calls(b,g,a) = 45 12253 14061, #gen drafts = 14061, #acc drafts = 12548, #gen tokens = 28122, #acc tokens = 23747, dur(b,g,a) = 0.069, 63551.370, 29.388 ms
2026-05-23 18:28:24.609 | 22.15.481.798 I slot      release: id  3 | task 12385 | stop processing: n_tokens = 22980, truncated = 0
2026-05-23 18:28:24.849 | 22.15.721.582 I srv  params_from_: Chat format: peg-native
2026-05-23 18:28:24.938 | 22.15.810.194 I slot get_availabl: id  3 | task -1 | selected slot by LCP similarity, sim_best = 0.955 (> 0.100 thold), f_keep = 1.000
2026-05-23 18:28:24.938 | 22.15.810.755 I reasoning-budget: activated, budget=2147483647 tokens
2026-05-23 18:28:24.938 | 22.15.810.874 I slot launch_slot_: id  3 | task 12422 | processing task, is_child = 0
2026-05-23 18:28:25.975 | 22.16.847.170 I slot create_check: id  3 | task 12422 | created context checkpoint 11 of 32 (pos_min = 23541, pos_max = 23541, n_tokens = 23542, size = 198.929 MiB)
2026-05-23 18:28:26.931 | 22.17.803.705 I slot create_check: id  3 | task 12422 | created context checkpoint 12 of 32 (pos_min = 24053, pos_max = 24053, n_tokens = 24054, size = 200.002 MiB)
2026-05-23 18:28:27.072 | 22.17.944.628 I slot print_timing: id  0 | task 12263 | n_decoded =    463, tg =  14.42 t/s
2026-05-23 18:28:27.075 | 22.17.947.661 I slot print_timing: id  1 | task 12355 | n_decoded =    187, tg =  10.27 t/s
2026-05-23 18:28:29.645 | 22.20.517.543 I slot print_timing: id  0 | task 12263 | n_decoded =    523, tg =  14.86 t/s
2026-05-23 18:28:29.648 | 22.20.520.489 I slot print_timing: id  1 | task 12355 | n_decoded =    243, tg =  11.42 t/s
2026-05-23 18:28:31.652 | 22.22.524.795 I slot print_timing: id  3 | task 12422 | n_decoded =    101, tg =  18.77 t/s
2026-05-23 18:28:32.427 | 22.23.299.420 I slot print_timing: id  0 | task 12263 | n_decoded =    583, tg =  15.23 t/s
2026-05-23 18:28:32.429 | 22.23.300.957 I slot print_timing: id  1 | task 12355 | n_decoded =    278, tg =  11.41 t/s
2026-05-23 18:28:34.242 | 22.25.114.258 I slot print_timing: id  0 | task 12263 | 
2026-05-23 18:28:34.242 | prompt eval time =    4953.32 ms /  3656 tokens (    1.35 ms per token,   738.09 tokens per second)
2026-05-23 18:28:34.242 |        eval time =   40282.00 ms /   620 tokens (   64.97 ms per token,    15.39 tokens per second)
2026-05-23 18:28:34.242 |       total time =   45235.32 ms /  4276 tokens
2026-05-23 18:28:34.242 | draft acceptance rate = 0.99279 (  413 accepted /   416 generated)
2026-05-23 18:28:34.242 | 22.25.114.296 I statistics draft-mtp: #calls(b,g,a) = 46 12312 14230, #gen drafts = 14232, #acc drafts = 12696, #gen tokens = 28464, #acc tokens = 24035, dur(b,g,a) = 0.071, 64057.521, 29.847 ms
2026-05-23 18:28:34.243 | 22.25.115.253 I slot      release: id  0 | task 12263 | stop processing: n_tokens = 21027, truncated = 0
2026-05-23 18:28:34.445 | 22.25.317.420 I srv  params_from_: Chat format: peg-native
2026-05-23 18:28:34.460 | 22.25.332.224 I slot print_timing: id  3 | task 12422 | n_decoded =    158, tg =  18.84 t/s
2026-05-23 18:28:34.460 | 22.25.332.267 I slot get_availabl: id  0 | task -1 | selected slot by LCP similarity, sim_best = 0.872 (> 0.100 thold), f_keep = 1.000
2026-05-23 18:28:34.460 | 22.25.332.816 I reasoning-budget: activated, budget=2147483647 tokens
2026-05-23 18:28:34.460 | 22.25.332.914 I slot launch_slot_: id  0 | task 12481 | processing task, is_child = 0
2026-05-23 18:28:36.699 | 22.27.571.458 I slot print_timing: id  1 | task 12355 | n_decoded =    308, tg =  10.68 t/s
2026-05-23 18:28:37.764 | 22.28.635.946 I slot create_check: id  0 | task 12481 | created context checkpoint 11 of 32 (pos_min = 23600, pos_max = 23600, n_tokens = 23601, size = 199.053 MiB)
2026-05-23 18:28:38.431 | 22.29.302.932 I slot print_timing: id  3 | task 12422 | n_decoded =    167, tg =  13.51 t/s
2026-05-23 18:28:38.437 | 22.29.309.828 I slot print_timing: id  0 | task 12481 | prompt processing, n_tokens =   3086, progress = 1.00, t =   3.97 s / 777.32 tokens per second
2026-05-23 18:28:38.763 | 22.29.635.811 I slot create_check: id  0 | task 12481 | created context checkpoint 12 of 32 (pos_min = 24112, pos_max = 24112, n_tokens = 24113, size = 200.125 MiB)
2026-05-23 18:28:39.314 | 22.30.185.946 I slot print_timing: id  1 | task 12355 | n_decoded =    321, tg =  10.05 t/s
2026-05-23 18:28:41.008 | 22.31.880.490 I slot print_timing: id  3 | task 12422 | n_decoded =    218, tg =  14.12 t/s
2026-05-23 18:28:42.374 | 22.33.246.673 I slot print_timing: id  1 | task 12355 | n_decoded =    362, tg =  10.34 t/s
2026-05-23 18:28:43.546 | 22.34.418.615 I slot print_timing: id  0 | task 12481 | n_decoded =    101, tg =  17.91 t/s
2026-05-23 18:28:43.552 | 22.34.424.347 I slot print_timing: id  3 | task 12422 | n_decoded =    259, tg =  14.02 t/s
2026-05-23 18:28:43.701 | 22.34.573.702 I reasoning-budget: deactivated (natural end)
2026-05-23 18:28:44.931 | 22.35.803.379 I slot print_timing: id  1 | task 12355 | n_decoded =    407, tg =  10.69 t/s
2026-05-23 18:28:46.621 | 22.37.492.871 I slot print_timing: id  0 | task 12481 | n_decoded =    154, tg =  17.67 t/s
2026-05-23 18:28:46.626 | 22.37.498.040 I slot print_timing: id  3 | task 12422 | n_decoded =    313, tg =  14.52 t/s
2026-05-23 18:28:47.998 | 22.38.870.504 I reasoning-budget: deactivated (natural end)
2026-05-23 18:28:47.999 | 22.38.871.565 I slot print_timing: id  1 | task 12355 | n_decoded =    445, tg =  10.82 t/s
2026-05-23 18:28:49.187 | 22.40.059.469 I slot print_timing: id  0 | task 12481 | n_decoded =    202, tg =  17.14 t/s
2026-05-23 18:28:49.193 | 22.40.065.559 I slot print_timing: id  3 | task 12422 | n_decoded =    373, tg =  15.15 t/s
2026-05-23 18:28:50.575 | 22.41.447.309 I slot print_timing: id  1 | task 12355 | n_decoded =    500, tg =  11.31 t/s
2026-05-23 18:28:52.300 | 22.43.172.562 I slot print_timing: id  0 | task 12481 | n_decoded =    254, tg =  17.05 t/s
2026-05-23 18:28:52.306 | 22.43.178.341 I slot print_timing: id  3 | task 12422 | n_decoded =    433, tg =  15.61 t/s
2026-05-23 18:28:53.694 | 22.44.566.823 I slot print_timing: id  1 | task 12355 | n_decoded =    560, tg =  11.83 t/s
2026-05-23 18:28:54.885 | 22.45.756.973 I slot print_timing: id  0 | task 12481 | n_decoded =    299, tg =  16.63 t/s
2026-05-23 18:28:54.891 | 22.45.763.274 I slot print_timing: id  3 | task 12422 | n_decoded =    491, tg =  15.93 t/s
2026-05-23 18:28:56.280 | 22.47.151.988 I slot print_timing: id  1 | task 12355 | n_decoded =    618, tg =  12.26 t/s
2026-05-23 18:28:57.968 | 22.48.840.317 I slot print_timing: id  0 | task 12481 | n_decoded =    344, tg =  16.33 t/s
2026-05-23 18:28:57.975 | 22.48.847.243 I slot print_timing: id  3 | task 12422 | n_decoded =    551, tg =  16.25 t/s
2026-05-23 18:28:58.854 | 22.49.726.361 I slot print_timing: id  1 | task 12355 | n_decoded =    676, tg =  12.63 t/s
2026-05-23 18:29:00.559 | 22.51.431.249 I slot print_timing: id  0 | task 12481 | n_decoded =    386, tg =  15.97 t/s
2026-05-23 18:29:00.568 | 22.51.440.199 I slot print_timing: id  3 | task 12422 | n_decoded =    611, tg =  16.51 t/s
2026-05-23 18:29:01.965 | 22.52.837.725 I slot print_timing: id  1 | task 12355 | n_decoded =    736, tg =  13.00 t/s
2026-05-23 18:29:03.663 | 22.54.535.519 I slot print_timing: id  0 | task 12481 | n_decoded =    443, tg =  16.24 t/s
2026-05-23 18:29:03.670 | 22.54.542.900 I slot print_timing: id  3 | task 12422 | n_decoded =    671, tg =  16.72 t/s
2026-05-23 18:29:04.562 | 22.55.434.807 I slot print_timing: id  1 | task 12355 | n_decoded =    796, tg =  13.33 t/s
2026-05-23 18:29:06.273 | 22.57.145.230 I slot print_timing: id  0 | task 12481 | n_decoded =    492, tg =  16.20 t/s
2026-05-23 18:29:06.280 | 22.57.151.939 I slot print_timing: id  3 | task 12422 | n_decoded =    731, tg =  16.91 t/s
2026-05-23 18:29:07.661 | 22.58.533.163 I slot print_timing: id  1 | task 12355 | n_decoded =    856, tg =  13.63 t/s
2026-05-23 18:29:08.857 | 22.59.729.605 I slot print_timing: id  0 | task 12481 | n_decoded =    533, tg =  15.93 t/s
2026-05-23 18:29:08.864 | 22.59.736.475 I slot print_timing: id  3 | task 12422 | n_decoded =    791, tg =  17.09 t/s
2026-05-23 18:29:10.250 | 23.01.122.441 I slot print_timing: id  1 | task 12355 | n_decoded =    915, tg =  13.89 t/s
2026-05-23 18:29:11.960 | 23.02.832.765 I slot print_timing: id  0 | task 12481 | n_decoded =    579, tg =  15.84 t/s
2026-05-23 18:29:11.967 | 23.02.839.568 I slot print_timing: id  3 | task 12422 | n_decoded =    851, tg =  17.23 t/s
2026-05-23 18:29:13.349 | 23.04.221.622 I slot print_timing: id  1 | task 12355 | n_decoded =    975, tg =  14.13 t/s
2026-05-23 18:29:14.537 | 23.05.409.412 I slot print_timing: id  0 | task 12481 | n_decoded =    633, tg =  15.97 t/s
2026-05-23 18:29:14.544 | 23.05.416.539 I slot print_timing: id  3 | task 12422 | n_decoded =    911, tg =  17.36 t/s
2026-05-23 18:29:15.937 | 23.06.809.603 I slot print_timing: id  1 | task 12355 | n_decoded =   1035, tg =  14.36 t/s
2026-05-23 18:29:17.620 | 23.08.492.366 I slot print_timing: id  0 | task 12481 | n_decoded =    687, tg =  16.08 t/s
2026-05-23 18:29:17.626 | 23.08.498.943 I slot print_timing: id  3 | task 12422 | n_decoded =    971, tg =  17.48 t/s
2026-05-23 18:29:19.008 | 23.09.880.878 I slot print_timing: id  1 | task 12355 | n_decoded =   1095, tg =  14.57 t/s
2026-05-23 18:29:20.200 | 23.11.072.289 I slot print_timing: id  0 | task 12481 | n_decoded =    742, tg =  16.20 t/s
2026-05-23 18:29:20.206 | 23.11.078.841 I slot print_timing: id  3 | task 12422 | n_decoded =   1031, tg =  17.58 t/s
2026-05-23 18:29:21.588 | 23.12.459.977 I slot print_timing: id  1 | task 12355 | n_decoded =   1155, tg =  14.76 t/s
2026-05-23 18:29:23.275 | 23.14.147.831 I slot print_timing: id  0 | task 12481 | n_decoded =    782, tg =  16.00 t/s
2026-05-23 18:29:23.282 | 23.14.154.586 I slot print_timing: id  3 | task 12422 | n_decoded =   1091, tg =  17.68 t/s
2026-05-23 18:29:24.170 | 23.15.042.793 I slot print_timing: id  1 | task 12355 | n_decoded =   1215, tg =  14.94 t/s
2026-05-23 18:29:25.860 | 23.16.732.412 I slot print_timing: id  0 | task 12481 | n_decoded =    840, tg =  16.17 t/s
2026-05-23 18:29:25.866 | 23.16.738.630 I slot print_timing: id  3 | task 12422 | n_decoded =   1151, tg =  17.76 t/s
2026-05-23 18:29:26.997 | 23.17.868.990 I slot print_timing: id  1 | task 12355 | n_decoded =   1275, tg =  15.11 t/s
2026-05-23 18:29:28.685 | 23.19.556.997 I slot print_timing: id  0 | task 12481 | n_decoded =    881, tg =  16.01 t/s
2026-05-23 18:29:28.691 | 23.19.563.726 I slot print_timing: id  3 | task 12422 | n_decoded =   1210, tg =  17.83 t/s
2026-05-23 18:29:29.802 | 23.20.674.092 I slot print_timing: id  1 | task 12355 | n_decoded =   1335, tg =  15.27 t/s
2026-05-23 18:29:31.510 | 23.22.382.767 I slot print_timing: id  0 | task 12481 | n_decoded =    928, tg =  15.97 t/s
2026-05-23 18:29:31.517 | 23.22.389.158 I slot print_timing: id  3 | task 12422 | n_decoded =   1270, tg =  17.90 t/s
2026-05-23 18:29:32.903 | 23.23.775.029 I slot print_timing: id  1 | task 12355 | n_decoded =   1395, tg =  15.41 t/s
2026-05-23 18:29:34.086 | 23.24.958.732 I slot print_timing: id  0 | task 12481 | n_decoded =    970, tg =  15.85 t/s
2026-05-23 18:29:34.093 | 23.24.965.639 I slot print_timing: id  3 | task 12422 | n_decoded =   1330, tg =  17.97 t/s
2026-05-23 18:29:35.474 | 23.26.346.422 I slot print_timing: id  1 | task 12355 | n_decoded =   1455, tg =  15.54 t/s
2026-05-23 18:29:37.157 | 23.28.029.464 I slot print_timing: id  0 | task 12481 | n_decoded =   1010, tg =  15.72 t/s
2026-05-23 18:29:37.164 | 23.28.036.409 I slot print_timing: id  3 | task 12422 | n_decoded =   1390, tg =  18.03 t/s
2026-05-23 18:29:38.533 | 23.29.404.980 I slot print_timing: id  1 | task 12355 | n_decoded =   1511, tg =  15.63 t/s
2026-05-23 18:29:39.737 | 23.30.609.451 I slot print_timing: id  0 | task 12481 | n_decoded =   1061, tg =  15.76 t/s
2026-05-23 18:29:39.744 | 23.30.616.655 I slot print_timing: id  3 | task 12422 | n_decoded =   1450, tg =  18.08 t/s
2026-05-23 18:29:41.129 | 23.32.000.960 I slot print_timing: id  1 | task 12355 | n_decoded =   1571, tg =  15.75 t/s
2026-05-23 18:29:42.827 | 23.33.699.024 I slot print_timing: id  0 | task 12481 | n_decoded =   1111, tg =  15.77 t/s
2026-05-23 18:29:42.834 | 23.33.705.825 I slot print_timing: id  3 | task 12422 | n_decoded =   1510, tg =  18.13 t/s
2026-05-23 18:29:43.718 | 23.34.590.008 I slot print_timing: id  1 | task 12355 | n_decoded =   1631, tg =  15.86 t/s
2026-05-23 18:29:45.410 | 23.36.282.420 I slot print_timing: id  0 | task 12481 | n_decoded =   1169, tg =  15.90 t/s
2026-05-23 18:29:45.416 | 23.36.288.366 I slot print_timing: id  3 | task 12422 | n_decoded =   1570, tg =  18.18 t/s
2026-05-23 18:29:45.563 | 23.36.435.820 I slot print_timing: id  1 | task 12355 | 
2026-05-23 18:29:45.563 | prompt eval time =     619.45 ms /    28 tokens (   22.12 ms per token,    45.20 tokens per second)
2026-05-23 18:29:45.563 |        eval time =  104709.34 ms /  1666 tokens (   62.85 ms per token,    15.91 tokens per second)
2026-05-23 18:29:45.563 |       total time =  105328.79 ms /  1694 tokens
2026-05-23 18:29:45.563 | draft acceptance rate = 0.88143 ( 1063 accepted /  1206 generated)
2026-05-23 18:29:45.563 | 23.36.435.850 I statistics draft-mtp: #calls(b,g,a) = 47 12796 15677, #gen drafts = 15678, #acc drafts = 14005, #gen tokens = 31356, #acc tokens = 26545, dur(b,g,a) = 0.073, 68266.965, 33.905 ms
2026-05-23 18:29:45.564 | 23.36.436.577 I slot      release: id  1 | task 12355 | stop processing: n_tokens = 23245, truncated = 0
2026-05-23 18:29:45.788 | 23.36.660.220 I srv  params_from_: Chat format: peg-native
2026-05-23 18:29:45.894 | 23.36.766.602 I slot get_availabl: id  1 | task -1 | selected slot by LCP similarity, sim_best = 0.996 (> 0.100 thold), f_keep = 1.000
2026-05-23 18:29:45.895 | 23.36.767.154 I reasoning-budget: activated, budget=2147483647 tokens
2026-05-23 18:29:45.895 | 23.36.767.258 I slot launch_slot_: id  1 | task 12967 | processing task, is_child = 0
2026-05-23 18:29:46.269 | 23.37.141.454 I slot create_check: id  1 | task 12967 | created context checkpoint 10 of 32 (pos_min = 23244, pos_max = 23244, n_tokens = 23245, size = 198.307 MiB)
2026-05-23 18:29:46.835 | 23.37.707.053 I slot create_check: id  1 | task 12967 | created context checkpoint 11 of 32 (pos_min = 23340, pos_max = 23340, n_tokens = 23341, size = 198.508 MiB)
2026-05-23 18:29:47.740 | 23.38.612.504 I reasoning-budget: deactivated (natural end)
2026-05-23 18:29:48.503 | 23.39.375.793 I slot print_timing: id  0 | task 12481 | n_decoded =   1209, tg =  15.78 t/s
2026-05-23 18:29:48.510 | 23.39.382.158 I slot print_timing: id  3 | task 12422 | n_decoded =   1618, tg =  18.09 t/s
2026-05-23 18:29:51.098 | 23.41.970.144 I slot print_timing: id  0 | task 12481 | n_decoded =   1250, tg =  15.68 t/s
2026-05-23 18:29:51.104 | 23.41.976.630 I slot print_timing: id  3 | task 12422 | n_decoded =   1678, tg =  18.13 t/s
2026-05-23 18:29:51.724 | 23.42.595.981 I slot print_timing: id  1 | task 12967 | n_decoded =    101, tg =  19.24 t/s
2026-05-23 18:29:53.677 | 23.44.549.537 I slot print_timing: id  0 | task 12481 | n_decoded =   1309, tg =  15.81 t/s
2026-05-23 18:29:53.684 | 23.44.556.167 I slot print_timing: id  3 | task 12422 | n_decoded =   1738, tg =  18.17 t/s
2026-05-23 18:29:54.295 | 23.45.167.783 I slot print_timing: id  1 | task 12967 | n_decoded =    161, tg =  19.33 t/s
2026-05-23 18:29:56.766 | 23.47.638.021 I slot print_timing: id  0 | task 12481 | n_decoded =   1368, tg =  15.93 t/s
2026-05-23 18:29:56.773 | 23.47.644.956 I slot print_timing: id  3 | task 12422 | n_decoded =   1798, tg =  18.21 t/s
2026-05-23 18:29:57.383 | 23.48.255.650 I slot print_timing: id  1 | task 12967 | n_decoded =    221, tg =  19.36 t/s
2026-05-23 18:29:59.353 | 23.50.224.992 I slot print_timing: id  0 | task 12481 | n_decoded =   1420, tg =  15.96 t/s
2026-05-23 18:29:59.360 | 23.50.232.237 I slot print_timing: id  3 | task 12422 | n_decoded =   1858, tg =  18.25 t/s
2026-05-23 18:29:59.975 | 23.50.847.055 I slot print_timing: id  1 | task 12967 | n_decoded =    281, tg =  19.38 t/s
2026-05-23 18:30:02.450 | 23.53.321.952 I slot print_timing: id  0 | task 12481 | n_decoded =   1467, tg =  15.94 t/s
2026-05-23 18:30:02.456 | 23.53.328.535 I slot print_timing: id  3 | task 12422 | n_decoded =   1918, tg =  18.28 t/s
2026-05-23 18:30:03.080 | 23.53.951.952 I slot print_timing: id  1 | task 12967 | n_decoded =    341, tg =  19.37 t/s
2026-05-23 18:30:05.053 | 23.55.925.679 I slot print_timing: id  0 | task 12481 | n_decoded =   1526, tg =  16.04 t/s
2026-05-23 18:30:05.059 | 23.55.931.867 I slot print_timing: id  3 | task 12422 | n_decoded =   1978, tg =  18.31 t/s
2026-05-23 18:30:05.675 | 23.56.547.354 I slot print_timing: id  1 | task 12967 | n_decoded =    401, tg =  19.37 t/s
2026-05-23 18:30:08.141 | 23.59.013.182 I slot print_timing: id  0 | task 12481 | n_decoded =   1584, tg =  16.12 t/s
2026-05-23 18:30:08.147 | 23.59.019.723 I slot print_timing: id  3 | task 12422 | n_decoded =   2038, tg =  18.35 t/s
2026-05-23 18:30:08.759 | 23.59.630.962 I slot print_timing: id  1 | task 12967 | n_decoded =    461, tg =  19.38 t/s
2026-05-23 18:30:10.737 | 24.01.609.633 I slot print_timing: id  0 | task 12481 | n_decoded =   1639, tg =  16.17 t/s
2026-05-23 18:30:10.743 | 24.01.615.652 I slot print_timing: id  3 | task 12422 | n_decoded =   2098, tg =  18.37 t/s
2026-05-23 18:30:11.358 | 24.02.230.647 I slot print_timing: id  1 | task 12967 | n_decoded =    521, tg =  19.38 t/s
2026-05-23 18:30:13.822 | 24.04.694.501 I slot print_timing: id  0 | task 12481 | n_decoded =   1694, tg =  16.22 t/s
2026-05-23 18:30:13.829 | 24.04.701.828 I slot print_timing: id  3 | task 12422 | n_decoded =   2158, tg =  18.40 t/s
2026-05-23 18:30:13.943 | 24.04.815.439 I slot print_timing: id  1 | task 12967 | n_decoded =    581, tg =  19.38 t/s
2026-05-23 18:30:16.409 | 24.07.281.105 I slot print_timing: id  0 | task 12481 | n_decoded =   1753, tg =  16.30 t/s
2026-05-23 18:30:16.415 | 24.07.287.486 I slot print_timing: id  3 | task 12422 | n_decoded =   2218, tg =  18.43 t/s
2026-05-23 18:30:17.022 | 24.07.894.388 I slot print_timing: id  1 | task 12967 | n_decoded =    641, tg =  19.39 t/s
2026-05-23 18:30:18.968 | 24.09.840.809 I slot print_timing: id  0 | task 12481 | n_decoded =   1808, tg =  16.35 t/s
2026-05-23 18:30:18.976 | 24.09.848.079 I slot print_timing: id  3 | task 12422 | n_decoded =   2278, tg =  18.46 t/s
2026-05-23 18:30:19.583 | 24.10.455.736 I slot print_timing: id  1 | task 12967 | n_decoded =    701, tg =  19.41 t/s
2026-05-23 18:30:20.080 | 24.10.952.519 I slot print_timing: id  3 | task 12422 | 
2026-05-23 18:30:20.080 | prompt eval time =    2123.48 ms /  1078 tokens (    1.97 ms per token,   507.66 tokens per second)
2026-05-23 18:30:20.080 |        eval time =  124529.31 ms /  2297 tokens (   54.21 ms per token,    18.45 tokens per second)
2026-05-23 18:30:20.080 |       total time =  126652.78 ms /  3375 tokens
2026-05-23 18:30:20.080 | draft acceptance rate = 0.97497 ( 1519 accepted /  1558 generated)
2026-05-23 18:30:20.080 | 24.10.952.556 I statistics draft-mtp: #calls(b,g,a) = 48 13038 16399, #gen drafts = 16399, #acc drafts = 14705, #gen tokens = 32798, #acc tokens = 27919, dur(b,g,a) = 0.074, 70369.079, 35.944 ms
2026-05-23 18:30:20.081 | 24.10.953.276 I slot      release: id  3 | task 12422 | stop processing: n_tokens = 26356, truncated = 0
2026-05-23 18:30:20.348 | 24.11.220.279 I srv  params_from_: Chat format: peg-native
2026-05-23 18:30:20.403 | 24.11.275.917 I slot get_availabl: id  3 | task -1 | selected slot by LCP similarity, sim_best = 0.993 (> 0.100 thold), f_keep = 1.000
2026-05-23 18:30:20.404 | 24.11.276.489 I reasoning-budget: activated, budget=2147483647 tokens
2026-05-23 18:30:20.404 | 24.11.276.595 I slot launch_slot_: id  3 | task 13210 | processing task, is_child = 0
2026-05-23 18:30:20.590 | 24.11.462.218 I slot create_check: id  3 | task 13210 | created context checkpoint 13 of 32 (pos_min = 26355, pos_max = 26355, n_tokens = 26356, size = 204.823 MiB)
2026-05-23 18:30:21.281 | 24.12.153.244 I slot create_check: id  3 | task 13210 | created context checkpoint 14 of 32 (pos_min = 26540, pos_max = 26540, n_tokens = 26541, size = 205.210 MiB)
2026-05-23 18:30:21.881 | 24.12.753.136 I slot print_timing: id  0 | task 12481 | n_decoded =   1853, tg =  16.30 t/s
2026-05-23 18:30:22.497 | 24.13.369.423 I slot print_timing: id  1 | task 12967 | n_decoded =    746, tg =  19.02 t/s
2026-05-23 18:30:22.499 | 24.13.371.078 I reasoning-budget: deactivated (natural end)
2026-05-23 18:30:24.659 | 24.15.531.173 I slot print_timing: id  0 | task 12481 | n_decoded =   1903, tg =  16.30 t/s
2026-05-23 18:30:25.291 | 24.16.163.832 I slot print_timing: id  1 | task 12967 | n_decoded =    806, tg =  19.04 t/s
2026-05-23 18:30:26.869 | 24.17.741.019 I slot print_timing: id  3 | task 13210 | n_decoded =    101, tg =  17.52 t/s
2026-05-23 18:30:27.698 | 24.18.570.620 I slot print_timing: id  0 | task 12481 | n_decoded =   1943, tg =  16.22 t/s
2026-05-23 18:30:28.337 | 24.19.209.711 I slot print_timing: id  1 | task 12967 | n_decoded =    863, tg =  19.02 t/s
2026-05-23 18:30:29.421 | 24.20.293.044 I slot print_timing: id  3 | task 13210 | n_decoded =    157, tg =  17.81 t/s
2026-05-23 18:30:30.227 | 24.21.099.217 I slot print_timing: id  0 | task 12481 | n_decoded =   1996, tg =  16.25 t/s
2026-05-23 18:30:30.878 | 24.21.750.700 I slot print_timing: id  1 | task 12967 | n_decoded =    920, tg =  19.00 t/s
2026-05-23 18:30:32.448 | 24.23.320.608 I slot print_timing: id  3 | task 13210 | n_decoded =    213, tg =  17.98 t/s
2026-05-23 18:30:33.378 | 24.24.250.078 I slot print_timing: id  0 | task 12481 | n_decoded =   2052, tg =  16.29 t/s
2026-05-23 18:30:34.017 | 24.24.889.427 I slot print_timing: id  1 | task 12967 | n_decoded =    980, tg =  19.01 t/s
2026-05-23 18:30:35.081 | 24.25.953.256 I slot print_timing: id  3 | task 13210 | n_decoded =    273, tg =  18.23 t/s
2026-05-23 18:30:36.022 | 24.26.894.427 I slot print_timing: id  0 | task 12481 | n_decoded =   2110, tg =  16.34 t/s
2026-05-23 18:30:36.661 | 24.27.533.494 I slot print_timing: id  1 | task 12967 | n_decoded =   1040, tg =  19.02 t/s
2026-05-23 18:30:37.449 | 24.28.321.064 I slot print_timing: id  1 | task 12967 | 
2026-05-23 18:30:37.449 | prompt eval time =    1072.59 ms /   100 tokens (   10.73 ms per token,    93.23 tokens per second)
2026-05-23 18:30:37.449 |        eval time =   55480.81 ms /  1054 tokens (   52.64 ms per token,    19.00 tokens per second)
2026-05-23 18:30:37.449 |       total time =   56553.40 ms /  1154 tokens
2026-05-23 18:30:37.449 | draft acceptance rate = 0.99716 (  702 accepted /   704 generated)
2026-05-23 18:30:37.449 | 24.28.321.098 I statistics draft-mtp: #calls(b,g,a) = 49 13153 16738, #gen drafts = 16739, #acc drafts = 15029, #gen tokens = 33478, #acc tokens = 28544, dur(b,g,a) = 0.076, 71396.912, 36.933 ms
2026-05-23 18:30:37.449 | 24.28.321.870 I slot      release: id  1 | task 12967 | stop processing: n_tokens = 24399, truncated = 0
2026-05-23 18:30:37.712 | 24.28.584.275 I srv  params_from_: Chat format: peg-native
2026-05-23 18:30:37.791 | 24.28.663.882 I slot get_availabl: id  1 | task -1 | selected slot by LCP similarity, sim_best = 0.996 (> 0.100 thold), f_keep = 1.000
2026-05-23 18:30:37.792 | 24.28.664.431 I reasoning-budget: activated, budget=2147483647 tokens
2026-05-23 18:30:37.792 | 24.28.664.549 I slot launch_slot_: id  1 | task 13326 | processing task, is_child = 0
2026-05-23 18:30:38.190 | 24.29.062.315 I slot create_check: id  1 | task 13326 | created context checkpoint 12 of 32 (pos_min = 24398, pos_max = 24398, n_tokens = 24399, size = 200.724 MiB)
2026-05-23 18:30:38.391 | 24.29.263.522 I slot print_timing: id  3 | task 13210 | n_decoded =    330, tg =  18.05 t/s
2026-05-23 18:30:38.795 | 24.29.667.184 I slot create_check: id  1 | task 13326 | created context checkpoint 13 of 32 (pos_min = 24494, pos_max = 24494, n_tokens = 24495, size = 200.925 MiB)
2026-05-23 18:30:39.099 | 24.29.971.675 I slot print_timing: id  0 | task 12481 | n_decoded =   2148, tg =  16.25 t/s
2026-05-23 18:30:39.223 | 24.30.095.447 I reasoning-budget: deactivated (natural end)
2026-05-23 18:30:40.951 | 24.31.823.501 I slot print_timing: id  3 | task 13210 | n_decoded =    381, tg =  17.85 t/s
2026-05-23 18:30:41.750 | 24.32.622.512 I slot print_timing: id  0 | task 12481 | n_decoded =   2208, tg =  16.31 t/s
2026-05-23 18:30:43.948 | 24.34.820.725 I slot print_timing: id  1 | task 13326 | n_decoded =    100, tg =  18.15 t/s
2026-05-23 18:30:43.951 | 24.34.823.715 I slot print_timing: id  3 | task 13210 | n_decoded =    438, tg =  17.99 t/s
2026-05-23 18:30:44.378 | 24.35.249.907 I slot print_timing: id  0 | task 12481 | n_decoded =   2268, tg =  16.38 t/s
2026-05-23 18:30:46.548 | 24.37.420.309 I slot print_timing: id  1 | task 13326 | n_decoded =    159, tg =  18.46 t/s
2026-05-23 18:30:46.551 | 24.37.423.233 I slot print_timing: id  3 | task 13210 | n_decoded =    498, tg =  18.14 t/s
2026-05-23 18:30:47.474 | 24.38.346.696 I slot print_timing: id  0 | task 12481 | n_decoded =   2319, tg =  16.38 t/s
2026-05-23 18:30:49.143 | 24.40.014.953 I slot print_timing: id  1 | task 13326 | n_decoded =    219, tg =  18.71 t/s
2026-05-23 18:30:49.145 | 24.40.017.808 I slot print_timing: id  3 | task 13210 | n_decoded =    558, tg =  18.27 t/s
2026-05-23 18:30:50.079 | 24.40.950.934 I slot print_timing: id  0 | task 12481 | n_decoded =   2366, tg =  16.35 t/s
2026-05-23 18:30:52.281 | 24.43.153.804 I slot print_timing: id  1 | task 13326 | n_decoded =    279, tg =  18.79 t/s
2026-05-23 18:30:52.284 | 24.43.156.624 I slot print_timing: id  3 | task 13210 | n_decoded =    618, tg =  18.35 t/s
2026-05-23 18:30:53.207 | 24.44.079.399 I slot print_timing: id  0 | task 12481 | n_decoded =   2417, tg =  16.35 t/s
2026-05-23 18:30:53.992 | 24.44.864.261 I slot print_timing: id  1 | task 13326 | 
2026-05-23 18:30:53.992 | prompt eval time =    1138.91 ms /   100 tokens (   11.39 ms per token,    87.80 tokens per second)
2026-05-23 18:30:53.992 |        eval time =   16555.92 ms /   311 tokens (   53.23 ms per token,    18.78 tokens per second)
2026-05-23 18:30:53.992 |       total time =   17694.83 ms /   411 tokens
2026-05-23 18:30:53.992 | draft acceptance rate = 0.96698 (  205 accepted /   212 generated)
2026-05-23 18:30:53.992 | 24.44.864.294 I statistics draft-mtp: #calls(b,g,a) = 50 13264 17066, #gen drafts = 17067, #acc drafts = 15341, #gen tokens = 34134, #acc tokens = 29156, dur(b,g,a) = 0.078, 72379.789, 37.862 ms
2026-05-23 18:30:53.993 | 24.44.865.100 I slot      release: id  1 | task 13326 | stop processing: n_tokens = 24810, truncated = 0
2026-05-23 18:30:53.729 | 24.44.601.568 I srv  params_from_: Chat format: peg-native
2026-05-23 18:30:53.825 | 24.44.697.565 I slot get_availabl: id  1 | task -1 | selected slot by LCP similarity, sim_best = 0.999 (> 0.100 thold), f_keep = 1.000
2026-05-23 18:30:53.826 | 24.44.698.125 I reasoning-budget: activated, budget=2147483647 tokens
2026-05-23 18:30:53.826 | 24.44.698.230 I slot launch_slot_: id  1 | task 13438 | processing task, is_child = 0
2026-05-23 18:30:54.215 | 24.45.087.517 I slot create_check: id  1 | task 13438 | created context checkpoint 14 of 32 (pos_min = 24809, pos_max = 24809, n_tokens = 24810, size = 201.585 MiB)
2026-05-23 18:30:54.840 | 24.45.712.284 I slot print_timing: id  3 | task 13210 | n_decoded =    672, tg =  18.29 t/s
2026-05-23 18:30:55.765 | 24.46.637.744 I slot print_timing: id  0 | task 12481 | n_decoded =   2467, tg =  16.35 t/s
2026-05-23 18:30:57.930 | 24.48.802.561 I slot print_timing: id  3 | task 13210 | n_decoded =    732, tg =  18.38 t/s
2026-05-23 18:30:58.856 | 24.49.728.825 I slot print_timing: id  0 | task 12481 | n_decoded =   2511, tg =  16.31 t/s
2026-05-23 18:31:00.533 | 24.51.405.001 I slot print_timing: id  3 | task 13210 | n_decoded =    792, tg =  18.44 t/s
2026-05-23 18:31:00.689 | 24.51.561.724 I slot print_timing: id  1 | task 13438 | n_decoded =    101, tg =  15.13 t/s
2026-05-23 18:31:01.471 | 24.52.343.294 I slot print_timing: id  0 | task 12481 | n_decoded =   2570, tg =  16.36 t/s
2026-05-23 18:31:01.793 | 24.52.665.453 I reasoning-budget: deactivated (natural end)
2026-05-23 18:31:03.663 | 24.54.534.968 I slot print_timing: id  3 | task 13210 | n_decoded =    846, tg =  18.36 t/s
2026-05-23 18:31:03.821 | 24.54.693.786 I slot print_timing: id  1 | task 13438 | n_decoded =    155, tg =  15.80 t/s
2026-05-23 18:31:04.091 | 24.54.963.219 I slot print_timing: id  0 | task 12481 | n_decoded =   2612, tg =  16.30 t/s
2026-05-23 18:31:04.566 | 24.55.438.152 I slot print_timing: id  3 | task 13210 | 
2026-05-23 18:31:04.566 | prompt eval time =    1186.50 ms /   189 tokens (    6.28 ms per token,   159.29 tokens per second)
2026-05-23 18:31:04.566 |        eval time =   47474.23 ms /   871 tokens (   54.51 ms per token,    18.35 tokens per second)
2026-05-23 18:31:04.566 |       total time =   48660.73 ms /  1060 tokens
2026-05-23 18:31:04.566 | draft acceptance rate = 0.96801 (  575 accepted /   594 generated)
2026-05-23 18:31:04.566 | 24.55.438.183 I statistics draft-mtp: #calls(b,g,a) = 51 13340 17290, #gen drafts = 17290, #acc drafts = 15535, #gen tokens = 34580, #acc tokens = 29520, dur(b,g,a) = 0.080, 73050.296, 38.470 ms
2026-05-23 18:31:04.567 | 24.55.439.043 I slot      release: id  3 | task 13210 | stop processing: n_tokens = 27417, truncated = 0
2026-05-23 18:31:06.376 | 24.57.248.243 I slot print_timing: id  1 | task 13438 | n_decoded =    223, tg =  17.34 t/s
2026-05-23 18:31:07.105 | 24.57.977.155 I slot print_timing: id  0 | task 12481 | n_decoded =   2684, tg =  16.44 t/s
2026-05-23 18:31:08.913 | 24.59.785.809 I slot print_timing: id  1 | task 13438 | n_decoded =    305, tg =  19.19 t/s
2026-05-23 18:31:09.649 | 25.00.521.396 I slot print_timing: id  0 | task 12481 | n_decoded =   2756, tg =  16.58 t/s
2026-05-23 18:31:11.975 | 25.02.847.367 I slot print_timing: id  1 | task 13438 | n_decoded =    392, tg =  20.68 t/s
2026-05-23 18:31:12.706 | 25.03.578.414 I slot print_timing: id  0 | task 12481 | n_decoded =   2836, tg =  16.75 t/s
2026-05-23 18:31:14.524 | 25.05.396.125 I slot print_timing: id  1 | task 13438 | n_decoded =    476, tg =  21.63 t/s
2026-05-23 18:31:15.136 | 25.06.008.895 I slot print_timing: id  0 | task 12481 | n_decoded =   2923, tg =  16.96 t/s
2026-05-23 18:31:17.446 | 25.08.318.899 I slot print_timing: id  1 | task 13438 | n_decoded =    563, tg =  22.46 t/s
2026-05-23 18:31:18.181 | 25.09.053.596 I slot print_timing: id  0 | task 12481 | n_decoded =   2995, tg =  17.07 t/s
2026-05-23 18:31:20.104 | 25.10.976.036 I slot print_timing: id  1 | task 13438 | n_decoded =    650, tg =  23.14 t/s
2026-05-23 18:31:20.849 | 25.11.721.782 I slot print_timing: id  0 | task 12481 | n_decoded =   3056, tg =  17.12 t/s
2026-05-23 18:31:23.184 | 25.14.056.115 I slot print_timing: id  1 | task 13438 | n_decoded =    737, tg =  23.64 t/s
2026-05-23 18:31:23.918 | 25.14.790.634 I slot print_timing: id  0 | task 12481 | n_decoded =   3141, tg =  17.30 t/s
2026-05-23 18:31:25.734 | 25.16.606.306 I slot print_timing: id  1 | task 13438 | n_decoded =    824, tg =  24.08 t/s
2026-05-23 18:31:26.472 | 25.17.344.266 I slot print_timing: id  0 | task 12481 | n_decoded =   3213, tg =  17.41 t/s
2026-05-23 18:31:28.789 | 25.19.661.588 I slot print_timing: id  1 | task 13438 | n_decoded =    910, tg =  24.41 t/s
2026-05-23 18:31:29.029 | 25.19.900.928 I slot print_timing: id  0 | task 12481 | n_decoded =   3288, tg =  17.52 t/s
2026-05-23 18:31:31.352 | 25.22.223.944 I slot print_timing: id  1 | task 13438 | n_decoded =    988, tg =  24.49 t/s
2026-05-23 18:31:31.882 | 25.22.754.637 I slot print_timing: id  1 | task 13438 | 
2026-05-23 18:31:31.882 | prompt eval time =     688.24 ms /    26 tokens (   26.47 ms per token,    37.78 tokens per second)
2026-05-23 18:31:31.882 |        eval time =   40865.91 ms /  1003 tokens (   40.74 ms per token,    24.54 tokens per second)
2026-05-23 18:31:31.882 |       total time =   41554.14 ms /  1029 tokens
2026-05-23 18:31:31.882 | draft acceptance rate = 0.91525 (  648 accepted /   708 generated)
2026-05-23 18:31:31.882 | 25.22.754.668 I statistics draft-mtp: #calls(b,g,a) = 51 13623 17856, #gen drafts = 17856, #acc drafts = 16058, #gen tokens = 35712, #acc tokens = 30521, dur(b,g,a) = 0.080, 75030.009, 39.917 ms
2026-05-23 18:31:31.883 | 25.22.755.434 I slot      release: id  1 | task 13438 | stop processing: n_tokens = 25838, truncated = 0
2026-05-23 18:31:32.043 | 25.22.915.037 I slot print_timing: id  0 | task 12481 | n_decoded =   3366, tg =  17.65 t/s
2026-05-23 18:31:33.233 | 25.24.105.503 I reasoning-budget: deactivated (natural end)
2026-05-23 18:31:34.570 | 25.25.442.487 I slot print_timing: id  0 | task 12481 | n_decoded =   3556, tg =  18.36 t/s
2026-05-23 18:31:37.572 | 25.28.444.100 I slot print_timing: id  0 | task 12481 | n_decoded =   3764, tg =  19.14 t/s
2026-05-23 18:31:40.101 | 25.30.973.762 I slot print_timing: id  0 | task 12481 | n_decoded =   3973, tg =  19.89 t/s
2026-05-23 18:31:42.779 | 25.33.651.438 I slot print_timing: id  0 | task 12481 | n_decoded =   4183, tg =  20.63 t/s
2026-05-23 18:31:45.661 | 25.36.533.531 I slot print_timing: id  0 | task 12481 | n_decoded =   4392, tg =  21.34 t/s
2026-05-23 18:31:48.681 | 25.39.553.260 I slot print_timing: id  0 | task 12481 | n_decoded =   4602, tg =  22.04 t/s
2026-05-23 18:31:51.211 | 25.42.083.408 I slot print_timing: id  0 | task 12481 | n_decoded =   4812, tg =  22.72 t/s
2026-05-23 18:31:51.475 | 25.42.347.393 I slot print_timing: id  0 | task 12481 | 
2026-05-23 18:31:51.475 | prompt eval time =    4439.14 ms /  3090 tokens (    1.44 ms per token,   696.08 tokens per second)
2026-05-23 18:31:51.475 |        eval time =  212097.22 ms /  4830 tokens (   43.91 ms per token,    22.77 tokens per second)
2026-05-23 18:31:51.475 |       total time =  216536.36 ms /  7920 tokens
2026-05-23 18:31:51.475 | draft acceptance rate = 0.83767 ( 3024 accepted /  3610 generated)
2026-05-23 18:31:51.475 | 25.42.347.428 I statistics draft-mtp: #calls(b,g,a) = 51 14123 18356, #gen drafts = 18356, #acc drafts = 16550, #gen tokens = 36712, #acc tokens = 31493, dur(b,g,a) = 0.080, 77797.147, 40.989 ms
2026-05-23 18:31:51.476 | 25.42.348.143 I slot      release: id  0 | task 12481 | stop processing: n_tokens = 28946, truncated = 0
2026-05-23 18:31:51.476 | 25.42.348.243 I srv  update_slots: all slots are idle
2026-05-23 18:31:51.720 | 25.42.592.446 I srv  params_from_: Chat format: peg-native
2026-05-23 18:31:51.721 | 25.42.593.621 I slot get_availabl: id  0 | task -1 | selected slot by LCP similarity, sim_best = 0.996 (> 0.100 thold), f_keep = 1.000
2026-05-23 18:31:51.722 | 25.42.594.278 I reasoning-budget: activated, budget=2147483647 tokens
2026-05-23 18:31:51.722 | 25.42.594.386 I slot launch_slot_: id  0 | task 14295 | processing task, is_child = 0
2026-05-23 18:31:51.722 | 25.42.594.407 I slot slot_save_an: id  1 | task -1 | saving idle slot to prompt cache
2026-05-23 18:31:51.724 | 25.42.596.050 W srv   prompt_save:  - saving prompt with length 25838, total state size = 1062.133 MiB (draft: 54.112 MiB)
2026-05-23 18:31:59.212 | 25.50.083.995 I slot prompt_clear: id  1 | task -1 | clearing prompt with 25838 tokens
2026-05-23 18:31:59.219 | 25.50.091.938 W srv        update:  - cache size limit reached, removing oldest entry (size = 10326.332 MiB)
2026-05-23 18:31:59.390 | 25.50.262.252 I srv        update:  - cache state: 1 prompts, 3668.498 MiB (limits: 8192.000 MiB, 131072 tokens, 131072 est)
2026-05-23 18:31:59.390 | 25.50.262.275 I srv        update:    - prompt 0x63d3ad757780:   25838 tokens, checkpoints: 14,  3668.498 MiB
2026-05-23 18:31:59.390 | 25.50.262.276 I slot slot_save_an: id  3 | task -1 | saving idle slot to prompt cache
2026-05-23 18:31:59.393 | 25.50.265.755 W srv   prompt_save:  - saving prompt with length 27417, total state size = 1117.898 MiB (draft: 57.419 MiB)
2026-05-23 18:32:05.689 | 25.56.561.345 I slot prompt_clear: id  3 | task -1 | clearing prompt with 27417 tokens
2026-05-23 18:32:05.696 | 25.56.568.278 I srv        update:  - cache state: 2 prompts, 7362.621 MiB (limits: 8192.000 MiB, 131072 tokens, 131072 est)
2026-05-23 18:32:05.696 | 25.56.568.301 I srv        update:    - prompt 0x63d3ad757780:   25838 tokens, checkpoints: 14,  3668.498 MiB
2026-05-23 18:32:05.696 | 25.56.568.303 I srv        update:    - prompt 0x63d3b1e44540:   27417 tokens, checkpoints: 14,  3694.122 MiB
2026-05-23 18:32:06.145 | 25.57.016.973 I slot create_check: id  0 | task 14295 | created context checkpoint 13 of 32 (pos_min = 28945, pos_max = 28945, n_tokens = 28946, size = 210.247 MiB)
2026-05-23 18:32:06.756 | 25.57.628.437 I slot create_check: id  0 | task 14295 | created context checkpoint 14 of 32 (pos_min = 29052, pos_max = 29052, n_tokens = 29053, size = 210.471 MiB)
2026-05-23 18:32:07.890 | 25.58.762.814 I reasoning-budget: deactivated (natural end)
2026-05-23 18:32:08.362 | 25.59.234.578 I slot print_timing: id  0 | task 14295 | n_decoded =    101, tg =  64.91 t/s
2026-05-23 18:32:10.802 | 26.01.674.771 I slot print_timing: id  0 | task 14295 | n_decoded =    311, tg =  67.94 t/s
2026-05-23 18:32:13.819 | 26.04.691.571 I slot print_timing: id  0 | task 14295 | n_decoded =    521, tg =  68.60 t/s
2026-05-23 18:32:16.420 | 26.07.292.517 I slot print_timing: id  0 | task 14295 | n_decoded =    731, tg =  68.82 t/s
2026-05-23 18:32:18.936 | 26.09.808.620 I slot print_timing: id  0 | task 14295 | n_decoded =    941, tg =  69.00 t/s
2026-05-23 18:32:19.109 | 26.09.981.749 I slot print_timing: id  0 | task 14295 | 
2026-05-23 18:32:19.109 | prompt eval time =    1107.72 ms /   111 tokens (    9.98 ms per token,   100.21 tokens per second)
2026-05-23 18:32:19.109 |        eval time =   13811.39 ms /   953 tokens (   14.49 ms per token,    69.00 tokens per second)
2026-05-23 18:32:19.109 |       total time =   14919.11 ms /  1064 tokens
2026-05-23 18:32:19.109 | draft acceptance rate = 0.98750 (  632 accepted /   640 generated)
2026-05-23 18:32:19.109 | 26.09.981.783 I statistics draft-mtp: #calls(b,g,a) = 52 14443 18676, #gen drafts = 18676, #acc drafts = 16867, #gen tokens = 37352, #acc tokens = 32125, dur(b,g,a) = 0.082, 79529.739, 41.724 ms
2026-05-23 18:32:19.110 | 26.09.982.659 I slot      release: id  0 | task 14295 | stop processing: n_tokens = 30009, truncated = 0
2026-05-23 18:32:19.110 | 26.09.982.741 I srv  update_slots: all slots are idle
2026-05-23 18:32:19.313 | 26.10.185.439 I srv  params_from_: Chat format: peg-native
2026-05-23 18:32:19.314 | 26.10.186.626 I slot get_availabl: id  0 | task -1 | selected slot by LCP similarity, sim_best = 0.997 (> 0.100 thold), f_keep = 1.000
2026-05-23 18:32:19.315 | 26.10.187.898 I reasoning-budget: activated, budget=2147483647 tokens
2026-05-23 18:32:19.315 | 26.10.188.024 I slot launch_slot_: id  0 | task 14618 | processing task, is_child = 0
2026-05-23 18:32:19.763 | 26.10.635.307 I slot create_check: id  0 | task 14618 | created context checkpoint 15 of 32 (pos_min = 30008, pos_max = 30008, n_tokens = 30009, size = 212.473 MiB)
2026-05-23 18:32:20.340 | 26.11.212.893 I slot create_check: id  0 | task 14618 | created context checkpoint 16 of 32 (pos_min = 30095, pos_max = 30095, n_tokens = 30096, size = 212.655 MiB)
2026-05-23 18:32:21.938 | 26.12.810.090 I reasoning-budget: deactivated (natural end)
2026-05-23 18:32:22.070 | 26.12.942.311 I slot print_timing: id  0 | task 14618 | n_decoded =    100, tg =  59.59 t/s
2026-05-23 18:32:24.595 | 26.15.467.528 I slot print_timing: id  0 | task 14618 | n_decoded =    309, tg =  65.77 t/s
2026-05-23 18:32:27.622 | 26.18.494.713 I slot print_timing: id  0 | task 14618 | n_decoded =    519, tg =  67.18 t/s
2026-05-23 18:32:30.162 | 26.21.034.207 I slot print_timing: id  0 | task 14618 | n_decoded =    726, tg =  67.44 t/s
2026-05-23 18:32:33.167 | 26.24.039.897 I slot print_timing: id  0 | task 14618 | n_decoded =    930, tg =  67.54 t/s
2026-05-23 18:32:33.211 | 26.24.083.542 I slot print_timing: id  0 | task 14618 | 
2026-05-23 18:32:33.211 | prompt eval time =    1076.02 ms /    91 tokens (   11.82 ms per token,    84.57 tokens per second)
2026-05-23 18:32:33.211 |        eval time =   13814.19 ms /   933 tokens (   14.81 ms per token,    67.54 tokens per second)
2026-05-23 18:32:33.211 |       total time =   14890.21 ms /  1024 tokens
2026-05-23 18:32:33.211 | draft acceptance rate = 0.97003 (  615 accepted /   634 generated)
2026-05-23 18:32:33.211 | 26.24.083.578 I statistics draft-mtp: #calls(b,g,a) = 53 14760 18993, #gen drafts = 18993, #acc drafts = 17177, #gen tokens = 37986, #acc tokens = 32740, dur(b,g,a) = 0.084, 81272.870, 42.467 ms
2026-05-23 18:32:33.212 | 26.24.084.585 I slot      release: id  0 | task 14618 | stop processing: n_tokens = 31032, truncated = 0
2026-05-23 18:32:33.212 | 26.24.084.655 I srv  update_slots: all slots are idle
2026-05-23 18:32:33.421 | 26.24.293.769 I srv  params_from_: Chat format: peg-native
2026-05-23 18:32:33.422 | 26.24.294.905 I slot get_availabl: id  0 | task -1 | selected slot by LCP similarity, sim_best = 0.997 (> 0.100 thold), f_keep = 1.000
2026-05-23 18:32:33.424 | 26.24.296.230 I reasoning-budget: activated, budget=2147483647 tokens
2026-05-23 18:32:33.424 | 26.24.296.397 I slot launch_slot_: id  0 | task 14938 | processing task, is_child = 0
2026-05-23 18:32:33.880 | 26.24.752.558 I slot create_check: id  0 | task 14938 | created context checkpoint 17 of 32 (pos_min = 31031, pos_max = 31031, n_tokens = 31032, size = 214.616 MiB)
2026-05-23 18:32:33.966 | 26.24.838.291 I slot create_check: id  0 | task 14938 | created context checkpoint 18 of 32 (pos_min = 31118, pos_max = 31118, n_tokens = 31119, size = 214.798 MiB)
2026-05-23 18:32:34.635 | 26.25.507.084 I reasoning-budget: deactivated (natural end)
2026-05-23 18:32:35.736 | 26.26.608.407 I slot print_timing: id  0 | task 14938 | n_decoded =    100, tg =  58.14 t/s
2026-05-23 18:32:38.509 | 26.29.381.446 I slot print_timing: id  0 | task 14938 | 
2026-05-23 18:32:38.509 | prompt eval time =    1093.78 ms /    91 tokens (   12.02 ms per token,    83.20 tokens per second)
2026-05-23 18:32:38.509 |        eval time =    4795.90 ms /   298 tokens (   16.09 ms per token,    62.14 tokens per second)
2026-05-23 18:32:38.509 |       total time =    5889.69 ms /   389 tokens
2026-05-23 18:32:38.509 | draft acceptance rate = 0.89720 (  192 accepted /   214 generated)
2026-05-23 18:32:38.509 | 26.29.381.480 I statistics draft-mtp: #calls(b,g,a) = 54 14867 19100, #gen drafts = 19100, #acc drafts = 17277, #gen tokens = 38200, #acc tokens = 32932, dur(b,g,a) = 0.087, 81884.925, 42.750 ms
2026-05-23 18:32:38.510 | 26.29.382.563 I slot      release: id  0 | task 14938 | stop processing: n_tokens = 31422, truncated = 0
2026-05-23 18:32:38.510 | 26.29.382.618 I slot print_timing: id  0 | task -1 | n_decoded =    298, tg =  62.12 t/s
2026-05-23 18:32:38.510 | 26.29.382.623 I srv  update_slots: all slots are idle
2026-05-23 18:32:38.686 | 26.29.558.584 I srv  params_from_: Chat format: peg-native
2026-05-23 18:32:38.687 | 26.29.559.800 I slot get_availabl: id  0 | task -1 | selected slot by LCP similarity, sim_best = 0.977 (> 0.100 thold), f_keep = 1.000
2026-05-23 18:32:38.688 | 26.29.560.880 I reasoning-budget: activated, budget=2147483647 tokens
2026-05-23 18:32:38.689 | 26.29.561.040 I slot launch_slot_: id  0 | task 15048 | processing task, is_child = 0
2026-05-23 18:32:39.207 | 26.30.079.530 I slot create_check: id  0 | task 15048 | created context checkpoint 19 of 32 (pos_min = 31651, pos_max = 31651, n_tokens = 31652, size = 215.914 MiB)
2026-05-23 18:32:40.201 | 26.31.073.703 I slot create_check: id  0 | task 15048 | created context checkpoint 20 of 32 (pos_min = 32163, pos_max = 32163, n_tokens = 32164, size = 216.986 MiB)
2026-05-23 18:32:40.782 | 26.31.654.558 I reasoning-budget: deactivated (natural end)
2026-05-23 18:32:41.876 | 26.32.748.308 I slot print_timing: id  0 | task 15048 | n_decoded =    101, tg =  62.16 t/s
2026-05-23 18:32:44.393 | 26.35.265.499 I slot print_timing: id  0 | task 15048 | n_decoded =    306, tg =  66.03 t/s
2026-05-23 18:32:44.524 | 26.35.396.861 I slot print_timing: id  0 | task 15048 | 
2026-05-23 18:32:44.525 | prompt eval time =    1766.93 ms /   746 tokens (    2.37 ms per token,   422.20 tokens per second)
2026-05-23 18:32:44.525 |        eval time =    4765.72 ms /   315 tokens (   15.13 ms per token,    66.10 tokens per second)
2026-05-23 18:32:44.525 |       total time =    6532.64 ms /  1061 tokens
2026-05-23 18:32:44.525 | draft acceptance rate = 0.94037 (  205 accepted /   218 generated)
2026-05-23 18:32:44.525 | 26.35.396.896 I statistics draft-mtp: #calls(b,g,a) = 55 14976 19209, #gen drafts = 19209, #acc drafts = 17381, #gen tokens = 38418, #acc tokens = 33137, dur(b,g,a) = 0.088, 82486.455, 43.032 ms
2026-05-23 18:32:44.525 | 26.35.397.836 I slot      release: id  0 | task 15048 | stop processing: n_tokens = 32482, truncated = 0
2026-05-23 18:32:44.525 | 26.35.397.913 I srv  update_slots: all slots are idle
2026-05-23 18:32:44.772 | 26.35.644.744 I srv  params_from_: Chat format: peg-native
2026-05-23 18:32:44.774 | 26.35.646.102 I slot get_availabl: id  0 | task -1 | selected slot by LCP similarity, sim_best = 0.999 (> 0.100 thold), f_keep = 1.000
2026-05-23 18:32:44.775 | 26.35.647.193 I reasoning-budget: activated, budget=2147483647 tokens
2026-05-23 18:32:44.775 | 26.35.647.355 I slot launch_slot_: id  0 | task 15161 | processing task, is_child = 0
2026-05-23 18:32:45.180 | 26.36.052.707 I slot create_check: id  0 | task 15161 | created context checkpoint 21 of 32 (pos_min = 32481, pos_max = 32481, n_tokens = 32482, size = 217.652 MiB)
2026-05-23 18:32:45.612 | 26.36.484.759 I reasoning-budget: deactivated (natural end)
2026-05-23 18:32:47.403 | 26.38.275.021 I slot print_timing: id  0 | task 15161 | n_decoded =    130, tg =  61.58 t/s
2026-05-23 18:32:49.905 | 26.40.777.822 I slot print_timing: id  0 | task 15161 | n_decoded =    331, tg =  64.71 t/s
2026-05-23 18:32:52.942 | 26.43.813.964 I slot print_timing: id  0 | task 15161 | n_decoded =    541, tg =  66.37 t/s
2026-05-23 18:32:55.476 | 26.46.348.420 I slot print_timing: id  0 | task 15161 | n_decoded =    751, tg =  67.13 t/s
2026-05-23 18:32:58.502 | 26.49.374.583 I slot print_timing: id  0 | task 15161 | n_decoded =    958, tg =  67.40 t/s
2026-05-23 18:33:01.025 | 26.51.897.545 I slot print_timing: id  0 | task 15161 | n_decoded =   1168, tg =  67.77 t/s
2026-05-23 18:33:03.224 | 26.54.096.109 I slot print_timing: id  0 | task 15161 | 
2026-05-23 18:33:03.224 | prompt eval time =     516.37 ms /    19 tokens (   27.18 ms per token,    36.80 tokens per second)
2026-05-23 18:33:03.224 |        eval time =   19434.00 ms /  1306 tokens (   14.88 ms per token,    67.20 tokens per second)
2026-05-23 18:33:03.224 |       total time =   19950.37 ms /  1325 tokens
2026-05-23 18:33:03.224 | draft acceptance rate = 0.95871 (  859 accepted /   896 generated)
2026-05-23 18:33:03.224 | 26.54.096.147 I statistics draft-mtp: #calls(b,g,a) = 56 15424 19657, #gen drafts = 19657, #acc drafts = 17814, #gen tokens = 39314, #acc tokens = 33996, dur(b,g,a) = 0.090, 85037.365, 44.137 ms
2026-05-23 18:33:03.225 | 26.54.097.020 I slot      release: id  0 | task 15161 | stop processing: n_tokens = 33808, truncated = 0
2026-05-23 18:33:03.225 | 26.54.097.087 I srv  update_slots: all slots are idle
2026-05-23 18:33:03.627 | 26.54.499.608 I srv  params_from_: Chat format: peg-native
2026-05-23 18:33:03.629 | 26.54.501.083 I slot get_availabl: id  2 | task -1 | selected slot by LRU, t_last = 1458459653
2026-05-23 18:33:03.629 | 26.54.501.107 I srv  get_availabl: updating prompt cache
2026-05-23 18:33:03.629 | 26.54.501.111 I srv          load:  - looking for better prompt, base f_keep = -1.000, sim = 0.000
2026-05-23 18:33:03.629 | 26.54.501.130 I srv        update:  - cache state: 2 prompts, 7362.621 MiB (limits: 8192.000 MiB, 131072 tokens, 131072 est)
2026-05-23 18:33:03.629 | 26.54.501.131 I srv        update:    - prompt 0x63d3ad757780:   25838 tokens, checkpoints: 14,  3668.498 MiB
2026-05-23 18:33:03.629 | 26.54.501.132 I srv        update:    - prompt 0x63d3b1e44540:   27417 tokens, checkpoints: 14,  3694.122 MiB
2026-05-23 18:33:03.629 | 26.54.501.132 I srv  get_availabl: prompt cache update took 0.02 ms
2026-05-23 18:33:03.630 | 26.54.502.163 I reasoning-budget: activated, budget=2147483647 tokens
2026-05-23 18:33:03.630 | 26.54.502.361 I slot launch_slot_: id  2 | task 15612 | processing task, is_child = 0
2026-05-23 18:33:03.630 | 26.54.502.385 I slot slot_save_an: id  0 | task -1 | saving idle slot to prompt cache
2026-05-23 18:33:03.632 | 26.54.504.145 W srv   prompt_save:  - saving prompt with length 33808, total state size = 1343.606 MiB (draft: 70.803 MiB)
2026-05-23 18:33:12.245 | 27.03.117.653 I slot prompt_clear: id  0 | task -1 | clearing prompt with 33808 tokens
2026-05-23 18:33:12.253 | 27.03.125.290 W srv        update:  - cache size limit reached, removing oldest entry (size = 3668.498 MiB)
2026-05-23 18:33:12.489 | 27.03.361.572 W srv        update:  - cache size limit reached, removing oldest entry (size = 3694.122 MiB)
2026-05-23 18:33:12.727 | 27.03.598.975 I srv        update:  - cache state: 1 prompts, 5439.010 MiB (limits: 8192.000 MiB, 131072 tokens, 131072 est)
2026-05-23 18:33:12.727 | 27.03.599.001 I srv        update:    - prompt 0x63d3b4e23fc0:   33808 tokens, checkpoints: 21,  5439.010 MiB
2026-05-23 18:33:12.727 | 27.03.599.671 W slot update_slots: id  2 | task 15612 | erased invalidated context checkpoint (pos_min = 8179, pos_max = 8179, n_tokens = 8180, n_swa = 0, pos_next = 0, size = 166.757 MiB)
2026-05-23 18:33:12.738 | 27.03.610.045 W slot update_slots: id  2 | task 15612 | erased invalidated context checkpoint (pos_min = 8323, pos_max = 8323, n_tokens = 8324, n_swa = 0, pos_next = 0, size = 167.059 MiB)
2026-05-23 18:33:12.748 | 27.03.620.187 W slot update_slots: id  2 | task 15612 | erased invalidated context checkpoint (pos_min = 16515, pos_max = 16515, n_tokens = 16516, n_swa = 0, pos_next = 0, size = 184.215 MiB)
2026-05-23 18:33:12.761 | 27.03.633.286 W slot update_slots: id  2 | task 15612 | erased invalidated context checkpoint (pos_min = 24707, pos_max = 24707, n_tokens = 24708, n_swa = 0, pos_next = 0, size = 201.371 MiB)
2026-05-23 18:33:12.775 | 27.03.647.031 W slot update_slots: id  2 | task 15612 | erased invalidated context checkpoint (pos_min = 32899, pos_max = 32899, n_tokens = 32900, n_swa = 0, pos_next = 0, size = 218.528 MiB)
2026-05-23 18:33:12.790 | 27.03.662.093 W slot update_slots: id  2 | task 15612 | erased invalidated context checkpoint (pos_min = 41091, pos_max = 41091, n_tokens = 41092, n_swa = 0, pos_next = 0, size = 235.684 MiB)
2026-05-23 18:33:12.806 | 27.03.678.058 W slot update_slots: id  2 | task 15612 | erased invalidated context checkpoint (pos_min = 44507, pos_max = 44507, n_tokens = 44508, n_swa = 0, pos_next = 0, size = 242.838 MiB)
2026-05-23 18:33:12.822 | 27.03.694.611 W slot update_slots: id  2 | task 15612 | erased invalidated context checkpoint (pos_min = 50721, pos_max = 50721, n_tokens = 50722, n_swa = 0, pos_next = 0, size = 255.852 MiB)
2026-05-23 18:33:12.840 | 27.03.712.238 W slot update_slots: id  2 | task 15612 | erased invalidated context checkpoint (pos_min = 58913, pos_max = 58913, n_tokens = 58914, n_swa = 0, pos_next = 0, size = 273.008 MiB)
2026-05-23 18:33:12.859 | 27.03.731.754 W slot update_slots: id  2 | task 15612 | erased invalidated context checkpoint (pos_min = 67105, pos_max = 67105, n_tokens = 67106, n_swa = 0, pos_next = 0, size = 290.164 MiB)
2026-05-23 18:33:12.879 | 27.03.751.577 W slot update_slots: id  2 | task 15612 | erased invalidated context checkpoint (pos_min = 70480, pos_max = 70480, n_tokens = 70481, n_swa = 0, pos_next = 0, size = 297.232 MiB)
2026-05-23 18:33:12.900 | 27.03.772.170 W slot update_slots: id  2 | task 15612 | erased invalidated context checkpoint (pos_min = 70992, pos_max = 70992, n_tokens = 70993, n_swa = 0, pos_next = 0, size = 298.305 MiB)
2026-05-23 18:33:12.920 | 27.03.792.393 W slot update_slots: id  2 | task 15612 | erased invalidated context checkpoint (pos_min = 75267, pos_max = 75267, n_tokens = 75268, n_swa = 0, pos_next = 0, size = 307.258 MiB)
2026-05-23 18:33:12.942 | 27.03.814.687 W slot update_slots: id  2 | task 15612 | erased invalidated context checkpoint (pos_min = 75653, pos_max = 75653, n_tokens = 75654, n_swa = 0, pos_next = 0, size = 308.066 MiB)
2026-05-23 18:33:12.963 | 27.03.835.847 W slot update_slots: id  2 | task 15612 | erased invalidated context checkpoint (pos_min = 76040, pos_max = 76040, n_tokens = 76041, n_swa = 0, pos_next = 0, size = 308.876 MiB)
2026-05-23 18:33:12.985 | 27.03.857.076 W slot update_slots: id  2 | task 15612 | erased invalidated context checkpoint (pos_min = 77255, pos_max = 77255, n_tokens = 77256, n_swa = 0, pos_next = 0, size = 311.421 MiB)
2026-05-23 18:33:13.006 | 27.03.878.465 W slot update_slots: id  2 | task 15612 | erased invalidated context checkpoint (pos_min = 77638, pos_max = 77638, n_tokens = 77639, n_swa = 0, pos_next = 0, size = 312.223 MiB)
2026-05-23 18:33:13.028 | 27.03.900.150 W slot update_slots: id  2 | task 15612 | erased invalidated context checkpoint (pos_min = 78025, pos_max = 78025, n_tokens = 78026, n_swa = 0, pos_next = 0, size = 313.034 MiB)
2026-05-23 18:33:13.049 | 27.03.921.484 W slot update_slots: id  2 | task 15612 | erased invalidated context checkpoint (pos_min = 78886, pos_max = 78886, n_tokens = 78887, n_swa = 0, pos_next = 0, size = 314.837 MiB)
2026-05-23 18:33:13.070 | 27.03.942.870 W slot update_slots: id  2 | task 15612 | erased invalidated context checkpoint (pos_min = 79095, pos_max = 79095, n_tokens = 79096, n_swa = 0, pos_next = 0, size = 315.274 MiB)
2026-05-23 18:33:13.092 | 27.03.964.292 W slot update_slots: id  2 | task 15612 | erased invalidated context checkpoint (pos_min = 79439, pos_max = 79439, n_tokens = 79440, n_swa = 0, pos_next = 0, size = 315.995 MiB)
2026-05-23 18:33:13.113 | 27.03.985.790 W slot update_slots: id  2 | task 15612 | erased invalidated context checkpoint (pos_min = 79825, pos_max = 79825, n_tokens = 79826, n_swa = 0, pos_next = 0, size = 316.803 MiB)
2026-05-23 18:33:13.135 | 27.04.007.242 W slot update_slots: id  2 | task 15612 | erased invalidated context checkpoint (pos_min = 80053, pos_max = 80053, n_tokens = 80054, n_swa = 0, pos_next = 0, size = 317.281 MiB)
2026-05-23 18:33:13.156 | 27.04.028.878 W slot update_slots: id  2 | task 15612 | erased invalidated context checkpoint (pos_min = 80279, pos_max = 80279, n_tokens = 80280, n_swa = 0, pos_next = 0, size = 317.754 MiB)
2026-05-23 18:33:13.178 | 27.04.050.460 W slot update_slots: id  2 | task 15612 | erased invalidated context checkpoint (pos_min = 80616, pos_max = 80616, n_tokens = 80617, n_swa = 0, pos_next = 0, size = 318.460 MiB)
2026-05-23 18:33:13.200 | 27.04.072.036 W slot update_slots: id  2 | task 15612 | erased invalidated context checkpoint (pos_min = 81005, pos_max = 81005, n_tokens = 81006, n_swa = 0, pos_next = 0, size = 319.275 MiB)
2026-05-23 18:33:15.363 | 27.06.235.299 I slot print_timing: id  2 | task 15612 | prompt processing, n_tokens =   6144, progress = 0.07, t =   3.14 s / 1959.29 tokens per second
2026-05-23 18:33:16.188 | 27.07.060.612 I slot print_timing: id  2 | task 15612 | prompt processing, n_tokens =   8192, progress = 0.09, t =   3.96 s / 2068.09 tokens per second
2026-05-23 18:33:16.188 | 27.07.060.842 I slot update_slots: id  2 | task 15612 | 8192 tokens since last checkpoint at 0, creating new checkpoint during processing at position 10240
2026-05-23 18:33:16.222 | 27.07.094.692 I slot create_check: id  2 | task 15612 | created context checkpoint 1 of 32 (pos_min = 8191, pos_max = 8191, n_tokens = 8192, size = 166.782 MiB)
2026-05-23 18:33:17.066 | 27.07.938.407 I slot print_timing: id  2 | task 15612 | prompt processing, n_tokens =  10240, progress = 0.12, t =   4.84 s / 2116.17 tokens per second
2026-05-23 18:33:17.922 | 27.08.793.916 I slot print_timing: id  2 | task 15612 | prompt processing, n_tokens =  12288, progress = 0.14, t =   5.69 s / 2157.89 tokens per second
2026-05-23 18:33:18.794 | 27.09.666.785 I slot print_timing: id  2 | task 15612 | prompt processing, n_tokens =  14336, progress = 0.17, t =   6.57 s / 2182.93 tokens per second
2026-05-23 18:33:19.174 | 27.10.046.318 I slot print_timing: id  2 | task 15612 | prompt processing, n_tokens =  16384, progress = 0.19, t =   7.46 s / 2197.70 tokens per second
2026-05-23 18:33:19.174 | 27.10.046.536 I slot update_slots: id  2 | task 15612 | 8192 tokens since last checkpoint at 8192, creating new checkpoint during processing at position 18432
2026-05-23 18:33:19.317 | 27.10.189.507 I slot create_check: id  2 | task 15612 | created context checkpoint 2 of 32 (pos_min = 16383, pos_max = 16383, n_tokens = 16384, size = 183.939 MiB)
2026-05-23 18:33:20.240 | 27.11.111.841 I slot print_timing: id  2 | task 15612 | prompt processing, n_tokens =  18432, progress = 0.21, t =   8.52 s / 2163.23 tokens per second
2026-05-23 18:33:21.156 | 27.12.028.606 I slot print_timing: id  2 | task 15612 | prompt processing, n_tokens =  20480, progress = 0.24, t =   9.44 s / 2170.10 tokens per second
2026-05-23 18:33:22.094 | 27.12.966.191 I slot print_timing: id  2 | task 15612 | prompt processing, n_tokens =  22528, progress = 0.26, t =  10.37 s / 2171.38 tokens per second
2026-05-23 18:33:23.046 | 27.13.918.303 I slot print_timing: id  2 | task 15612 | prompt processing, n_tokens =  24576, progress = 0.28, t =  11.33 s / 2169.67 tokens per second
2026-05-23 18:33:23.046 | 27.13.918.528 I slot update_slots: id  2 | task 15612 | 8192 tokens since last checkpoint at 16384, creating new checkpoint during processing at position 26624
2026-05-23 18:33:23.224 | 27.14.096.363 I slot create_check: id  2 | task 15612 | created context checkpoint 3 of 32 (pos_min = 24575, pos_max = 24575, n_tokens = 24576, size = 201.095 MiB)
2026-05-23 18:33:24.196 | 27.15.068.448 I slot print_timing: id  2 | task 15612 | prompt processing, n_tokens =  26624, progress = 0.31, t =  12.48 s / 2133.81 tokens per second
2026-05-23 18:33:24.696 | 27.15.568.022 I slot print_timing: id  2 | task 15612 | prompt processing, n_tokens =  28672, progress = 0.33, t =  13.47 s / 2128.55 tokens per second
2026-05-23 18:33:25.711 | 27.16.583.544 I slot print_timing: id  2 | task 15612 | prompt processing, n_tokens =  30720, progress = 0.35, t =  14.49 s / 2120.71 tokens per second
2026-05-23 18:33:26.752 | 27.17.624.445 I slot print_timing: id  2 | task 15612 | prompt processing, n_tokens =  32768, progress = 0.38, t =  15.53 s / 2110.44 tokens per second
2026-05-23 18:33:26.752 | 27.17.624.658 I slot update_slots: id  2 | task 15612 | 8192 tokens since last checkpoint at 24576, creating new checkpoint during processing at position 34816
2026-05-23 18:33:26.942 | 27.17.814.128 I slot create_check: id  2 | task 15612 | created context checkpoint 4 of 32 (pos_min = 32767, pos_max = 32767, n_tokens = 32768, size = 218.251 MiB)
2026-05-23 18:33:28.008 | 27.18.880.558 I slot print_timing: id  2 | task 15612 | prompt processing, n_tokens =  34816, progress = 0.40, t =  16.78 s / 2074.51 tokens per second
2026-05-23 18:33:29.096 | 27.19.968.703 I slot print_timing: id  2 | task 15612 | prompt processing, n_tokens =  36864, progress = 0.43, t =  17.87 s / 2062.80 tokens per second
2026-05-23 18:33:29.715 | 27.20.587.143 I slot print_timing: id  2 | task 15612 | prompt processing, n_tokens =  38912, progress = 0.45, t =  18.99 s / 2049.00 tokens per second
2026-05-23 18:33:30.857 | 27.21.729.816 I slot print_timing: id  2 | task 15612 | prompt processing, n_tokens =  40960, progress = 0.47, t =  20.13 s / 2034.43 tokens per second
2026-05-23 18:33:30.857 | 27.21.730.035 I slot update_slots: id  2 | task 15612 | 8192 tokens since last checkpoint at 32768, creating new checkpoint during processing at position 43008
2026-05-23 18:33:31.086 | 27.21.958.508 I slot create_check: id  2 | task 15612 | created context checkpoint 5 of 32 (pos_min = 40959, pos_max = 40959, n_tokens = 40960, size = 235.407 MiB)
2026-05-23 18:33:32.008 | 27.22.880.513 I slot print_timing: id  2 | task 15612 | prompt processing, n_tokens =  43008, progress = 0.50, t =  21.53 s / 1997.18 tokens per second
2026-05-23 18:33:33.204 | 27.24.076.463 I slot print_timing: id  2 | task 15612 | prompt processing, n_tokens =  45056, progress = 0.52, t =  22.73 s / 1982.20 tokens per second
2026-05-23 18:33:34.188 | 27.25.060.190 I slot print_timing: id  2 | task 15612 | prompt processing, n_tokens =  47104, progress = 0.54, t =  23.96 s / 1965.63 tokens per second
2026-05-23 18:33:35.444 | 27.26.316.001 I slot print_timing: id  2 | task 15612 | prompt processing, n_tokens =  49152, progress = 0.57, t =  25.22 s / 1948.96 tokens per second
2026-05-23 18:33:35.444 | 27.26.316.207 I slot update_slots: id  2 | task 15612 | 8192 tokens since last checkpoint at 40960, creating new checkpoint during processing at position 51200
2026-05-23 18:33:35.777 | 27.26.649.492 I slot create_check: id  2 | task 15612 | created context checkpoint 6 of 32 (pos_min = 49151, pos_max = 49151, n_tokens = 49152, size = 252.564 MiB)
2026-05-23 18:33:37.060 | 27.27.932.221 I slot print_timing: id  2 | task 15612 | prompt processing, n_tokens =  51200, progress = 0.59, t =  26.84 s / 1907.90 tokens per second
2026-05-23 18:33:38.419 | 27.29.290.998 I slot print_timing: id  2 | task 15612 | prompt processing, n_tokens =  53248, progress = 0.61, t =  28.19 s / 1888.59 tokens per second
2026-05-23 18:33:39.282 | 27.30.154.509 I slot print_timing: id  2 | task 15612 | prompt processing, n_tokens =  55296, progress = 0.64, t =  29.57 s / 1870.30 tokens per second
2026-05-23 18:33:40.653 | 27.31.525.347 I slot print_timing: id  2 | task 15612 | prompt processing, n_tokens =  57344, progress = 0.66, t =  30.94 s / 1853.62 tokens per second
2026-05-23 18:33:40.653 | 27.31.525.575 I slot update_slots: id  2 | task 15612 | 8192 tokens since last checkpoint at 49152, creating new checkpoint during processing at position 59392
2026-05-23 18:33:41.069 | 27.31.941.517 I slot create_check: id  2 | task 15612 | created context checkpoint 7 of 32 (pos_min = 57343, pos_max = 57343, n_tokens = 57344, size = 269.720 MiB)
2026-05-23 18:33:42.478 | 27.33.349.959 I slot print_timing: id  2 | task 15612 | prompt processing, n_tokens =  59392, progress = 0.69, t =  32.76 s / 1812.90 tokens per second
2026-05-23 18:33:43.939 | 27.34.811.743 I slot print_timing: id  2 | task 15612 | prompt processing, n_tokens =  61440, progress = 0.71, t =  34.22 s / 1795.31 tokens per second
2026-05-23 18:33:44.931 | 27.35.803.660 I slot print_timing: id  2 | task 15612 | prompt processing, n_tokens =  63488, progress = 0.73, t =  35.71 s / 1777.93 tokens per second
2026-05-23 18:33:46.453 | 27.37.325.205 I slot print_timing: id  2 | task 15612 | prompt processing, n_tokens =  65536, progress = 0.76, t =  37.23 s / 1760.27 tokens per second
2026-05-23 18:33:46.453 | 27.37.325.409 I slot update_slots: id  2 | task 15612 | 8192 tokens since last checkpoint at 57344, creating new checkpoint during processing at position 67584
2026-05-23 18:33:46.805 | 27.37.677.041 I slot create_check: id  2 | task 15612 | created context checkpoint 8 of 32 (pos_min = 65535, pos_max = 65535, n_tokens = 65536, size = 286.876 MiB)
2026-05-23 18:33:48.355 | 27.39.227.769 I slot print_timing: id  2 | task 15612 | prompt processing, n_tokens =  67584, progress = 0.78, t =  39.13 s / 1727.03 tokens per second
2026-05-23 18:33:49.439 | 27.40.311.649 I slot print_timing: id  2 | task 15612 | prompt processing, n_tokens =  69632, progress = 0.80, t =  40.72 s / 1710.10 tokens per second
2026-05-23 18:33:51.049 | 27.41.921.095 I slot print_timing: id  2 | task 15612 | prompt processing, n_tokens =  71680, progress = 0.83, t =  42.33 s / 1693.46 tokens per second
2026-05-23 18:33:52.681 | 27.43.553.623 I slot print_timing: id  2 | task 15612 | prompt processing, n_tokens =  73728, progress = 0.85, t =  43.96 s / 1677.16 tokens per second
2026-05-23 18:33:52.681 | 27.43.553.837 I slot update_slots: id  2 | task 15612 | 8192 tokens since last checkpoint at 65536, creating new checkpoint during processing at position 75776
2026-05-23 18:33:53.057 | 27.43.929.349 I slot create_check: id  2 | task 15612 | created context checkpoint 9 of 32 (pos_min = 73727, pos_max = 73727, n_tokens = 73728, size = 304.032 MiB)
2026-05-23 18:33:54.228 | 27.45.100.370 I slot print_timing: id  2 | task 15612 | prompt processing, n_tokens =  75776, progress = 0.87, t =  46.01 s / 1647.08 tokens per second
2026-05-23 18:33:55.941 | 27.46.813.781 I slot print_timing: id  2 | task 15612 | prompt processing, n_tokens =  77824, progress = 0.90, t =  47.72 s / 1630.85 tokens per second
2026-05-23 18:33:57.684 | 27.48.555.943 I slot print_timing: id  2 | task 15612 | prompt processing, n_tokens =  79872, progress = 0.92, t =  49.46 s / 1614.82 tokens per second
2026-05-23 18:33:58.968 | 27.49.840.462 I slot print_timing: id  2 | task 15612 | prompt processing, n_tokens =  81920, progress = 0.94, t =  51.22 s / 1599.33 tokens per second
2026-05-23 18:33:58.968 | 27.49.840.669 I slot update_slots: id  2 | task 15612 | 8192 tokens since last checkpoint at 73728, creating new checkpoint during processing at position 83968
2026-05-23 18:33:59.321 | 27.50.193.027 I slot create_check: id  2 | task 15612 | created context checkpoint 10 of 32 (pos_min = 81919, pos_max = 81919, n_tokens = 81920, size = 321.189 MiB)
2026-05-23 18:34:01.119 | 27.51.991.409 I slot print_timing: id  2 | task 15612 | prompt processing, n_tokens =  83968, progress = 0.97, t =  53.40 s / 1572.29 tokens per second
2026-05-23 18:34:02.950 | 27.53.822.666 I slot print_timing: id  2 | task 15612 | prompt processing, n_tokens =  86016, progress = 0.99, t =  55.24 s / 1557.24 tokens per second
2026-05-23 18:34:03.091 | 27.53.963.764 I slot print_timing: id  2 | task 15612 | prompt processing, n_tokens =  86179, progress = 0.99, t =  55.38 s / 1556.22 tokens per second
2026-05-23 18:34:03.493 | 27.54.365.422 I slot create_check: id  2 | task 15612 | created context checkpoint 11 of 32 (pos_min = 86178, pos_max = 86178, n_tokens = 86179, size = 330.108 MiB)
2026-05-23 18:34:03.949 | 27.54.821.815 I slot print_timing: id  2 | task 15612 | prompt processing, n_tokens =  86691, progress = 1.00, t =  56.24 s / 1541.58 tokens per second
2026-05-23 18:34:04.364 | 27.55.236.810 I slot create_check: id  2 | task 15612 | created context checkpoint 12 of 32 (pos_min = 86690, pos_max = 86690, n_tokens = 86691, size = 331.180 MiB)
2026-05-23 18:34:04.760 | 27.55.632.556 I reasoning-budget: deactivated (natural end)
2026-05-23 18:34:05.445 | 27.56.317.622 I slot print_timing: id  2 | task 15612 | n_decoded =    102, tg =  66.78 t/s
2026-05-23 18:34:08.470 | 27.59.342.200 I slot print_timing: id  2 | task 15612 | n_decoded =    336, tg =  73.81 t/s
2026-05-23 18:34:08.672 | 27.59.544.158 I slot print_timing: id  2 | task 15612 | 
2026-05-23 18:34:08.672 | prompt eval time =   56697.25 ms / 86695 tokens (    0.65 ms per token,  1529.09 tokens per second)
2026-05-23 18:34:08.672 |        eval time =    4753.87 ms /   346 tokens (   13.74 ms per token,    72.78 tokens per second)
2026-05-23 18:34:08.672 |       total time =   61451.13 ms / 87041 tokens
2026-05-23 18:34:08.672 | draft acceptance rate = 0.94583 (  227 accepted /   240 generated)
2026-05-23 18:34:08.672 | 27.59.544.197 I statistics draft-mtp: #calls(b,g,a) = 57 15544 19777, #gen drafts = 19777, #acc drafts = 17930, #gen tokens = 39554, #acc tokens = 34223, dur(b,g,a) = 0.091, 85647.380, 44.340 ms
2026-05-23 18:34:08.674 | 27.59.546.303 I slot      release: id  2 | task 15612 | stop processing: n_tokens = 87042, truncated = 0
2026-05-23 18:34:08.674 | 27.59.546.392 I srv  update_slots: all slots are idle
2026-05-23 18:34:08.951 | 27.59.823.542 I srv  params_from_: Chat format: peg-native
2026-05-23 18:34:08.953 | 27.59.825.014 I slot get_availabl: id  2 | task -1 | selected slot by LCP similarity, sim_best = 0.996 (> 0.100 thold), f_keep = 1.000
2026-05-23 18:34:08.953 | 27.59.825.962 I reasoning-budget: activated, budget=2147483647 tokens
2026-05-23 18:34:08.954 | 27.59.826.103 I slot launch_slot_: id  2 | task 15778 | processing task, is_child = 0
2026-05-23 18:34:09.357 | 28.00.229.498 I slot create_check: id  2 | task 15778 | created context checkpoint 13 of 32 (pos_min = 87041, pos_max = 87041, n_tokens = 87042, size = 331.916 MiB)
2026-05-23 18:34:09.631 | 28.00.503.749 I slot create_check: id  2 | task 15778 | created context checkpoint 14 of 32 (pos_min = 87426, pos_max = 87426, n_tokens = 87427, size = 332.722 MiB)
2026-05-23 18:34:10.364 | 28.01.236.746 I reasoning-budget: deactivated (natural end)
2026-05-23 18:34:11.120 | 28.01.992.883 I slot print_timing: id  2 | task 15778 | n_decoded =    101, tg =  69.94 t/s
2026-05-23 18:34:14.152 | 28.05.023.970 I slot print_timing: id  2 | task 15778 | n_decoded =    327, tg =  73.07 t/s
2026-05-23 18:34:14.355 | 28.05.227.811 I slot print_timing: id  2 | task 15778 | 
2026-05-23 18:34:14.355 | prompt eval time =    1230.57 ms /   389 tokens (    3.16 ms per token,   316.11 tokens per second)
2026-05-23 18:34:14.355 |        eval time =    5173.39 ms /   374 tokens (   13.83 ms per token,    72.29 tokens per second)
2026-05-23 18:34:14.355 |       total time =    6403.96 ms /   763 tokens
2026-05-23 18:34:14.355 | draft acceptance rate = 0.95349 (  246 accepted /   258 generated)
2026-05-23 18:34:14.355 | 28.05.227.848 I statistics draft-mtp: #calls(b,g,a) = 58 15673 19906, #gen drafts = 19906, #acc drafts = 18056, #gen tokens = 39812, #acc tokens = 34469, dur(b,g,a) = 0.093, 86328.383, 44.583 ms
2026-05-23 18:34:14.357 | 28.05.229.966 I slot      release: id  2 | task 15778 | stop processing: n_tokens = 87806, truncated = 0
2026-05-23 18:34:14.358 | 28.05.230.048 I srv  update_slots: all slots are idle
2026-05-23 18:34:14.683 | 28.05.555.240 I srv  params_from_: Chat format: peg-native
2026-05-23 18:34:14.684 | 28.05.556.699 I slot get_availabl: id  2 | task -1 | selected slot by LCP similarity, sim_best = 0.998 (> 0.100 thold), f_keep = 1.000
2026-05-23 18:34:14.685 | 28.05.557.473 I reasoning-budget: activated, budget=2147483647 tokens
2026-05-23 18:34:14.685 | 28.05.557.570 I slot launch_slot_: id  2 | task 15910 | processing task, is_child = 0
2026-05-23 18:34:15.085 | 28.05.957.747 I slot create_check: id  2 | task 15910 | created context checkpoint 15 of 32 (pos_min = 87805, pos_max = 87805, n_tokens = 87806, size = 333.516 MiB)
2026-05-23 18:34:15.718 | 28.06.590.890 I slot create_check: id  2 | task 15910 | created context checkpoint 16 of 32 (pos_min = 88013, pos_max = 88013, n_tokens = 88014, size = 333.951 MiB)
2026-05-23 18:34:16.374 | 28.07.245.972 I reasoning-budget: deactivated (natural end)
2026-05-23 18:34:17.217 | 28.08.089.586 I slot print_timing: id  2 | task 15910 | n_decoded =    101, tg =  69.55 t/s
2026-05-23 18:34:19.728 | 28.10.600.619 I slot print_timing: id  2 | task 15910 | 
2026-05-23 18:34:19.728 | prompt eval time =    1079.53 ms /   212 tokens (    5.09 ms per token,   196.38 tokens per second)
2026-05-23 18:34:19.728 |        eval time =    4470.98 ms /   332 tokens (   13.47 ms per token,    74.26 tokens per second)
2026-05-23 18:34:19.728 |       total time =    5550.51 ms /   544 tokens
2026-05-23 18:34:19.728 | draft acceptance rate = 0.96460 (  218 accepted /   226 generated)
2026-05-23 18:34:19.728 | 28.10.600.654 I statistics draft-mtp: #calls(b,g,a) = 59 15786 20019, #gen drafts = 20019, #acc drafts = 18167, #gen tokens = 40038, #acc tokens = 34687, dur(b,g,a) = 0.094, 86897.924, 44.767 ms
2026-05-23 18:34:19.730 | 28.10.602.737 I slot      release: id  2 | task 15910 | stop processing: n_tokens = 88349, truncated = 0
2026-05-23 18:34:19.730 | 28.10.602.807 I slot print_timing: id  2 | task -1 | n_decoded =    332, tg =  74.22 t/s
2026-05-23 18:34:19.730 | 28.10.602.832 I srv  update_slots: all slots are idle
2026-05-23 18:34:20.044 | 28.10.916.036 I srv  params_from_: Chat format: peg-native
2026-05-23 18:34:20.045 | 28.10.917.469 I slot get_availabl: id  2 | task -1 | selected slot by LCP similarity, sim_best = 0.996 (> 0.100 thold), f_keep = 1.000
2026-05-23 18:34:20.046 | 28.10.918.279 I reasoning-budget: activated, budget=2147483647 tokens
2026-05-23 18:34:20.046 | 28.10.918.384 I slot launch_slot_: id  2 | task 16026 | processing task, is_child = 0
2026-05-23 18:34:20.454 | 28.11.326.733 I slot create_check: id  2 | task 16026 | created context checkpoint 17 of 32 (pos_min = 88348, pos_max = 88348, n_tokens = 88349, size = 334.653 MiB)
2026-05-23 18:34:21.245 | 28.12.117.608 I slot create_check: id  2 | task 16026 | created context checkpoint 18 of 32 (pos_min = 88735, pos_max = 88735, n_tokens = 88736, size = 335.463 MiB)
2026-05-23 18:34:22.015 | 28.12.887.626 I reasoning-budget: deactivated (natural end)
2026-05-23 18:34:22.910 | 28.13.782.078 I slot print_timing: id  2 | task 16026 | n_decoded =    100, tg =  61.77 t/s
2026-05-23 18:34:25.446 | 28.16.318.808 I slot print_timing: id  2 | task 16026 | n_decoded =    305, tg =  65.58 t/s
2026-05-23 18:34:28.280 | 28.19.152.034 I slot print_timing: id  2 | task 16026 | n_decoded =    519, tg =  67.58 t/s
2026-05-23 18:34:29.106 | 28.19.978.695 I slot print_timing: id  2 | task 16026 | 
2026-05-23 18:34:29.106 | prompt eval time =    1244.56 ms /   391 tokens (    3.18 ms per token,   314.17 tokens per second)
2026-05-23 18:34:29.106 |        eval time =    8506.11 ms /   563 tokens (   15.11 ms per token,    66.19 tokens per second)
2026-05-23 18:34:29.106 |       total time =    9750.68 ms /   954 tokens
2026-05-23 18:34:29.106 | draft acceptance rate = 0.82547 (  350 accepted /   424 generated)
2026-05-23 18:34:29.106 | 28.19.978.730 I statistics draft-mtp: #calls(b,g,a) = 60 15998 20231, #gen drafts = 20231, #acc drafts = 18351, #gen tokens = 40462, #acc tokens = 35037, dur(b,g,a) = 0.096, 88030.102, 45.159 ms
2026-05-23 18:34:29.108 | 28.19.980.844 I slot      release: id  2 | task 16026 | stop processing: n_tokens = 89302, truncated = 0
2026-05-23 18:34:29.108 | 28.19.980.918 I srv  update_slots: all slots are idle
2026-05-23 18:34:29.306 | 28.20.178.366 I srv  params_from_: Chat format: peg-native
2026-05-23 18:34:29.307 | 28.20.179.791 I slot get_availabl: id  2 | task -1 | selected slot by LCP similarity, sim_best = 0.939 (> 0.100 thold), f_keep = 1.000
2026-05-23 18:34:29.308 | 28.20.180.553 I reasoning-budget: activated, budget=2147483647 tokens
2026-05-23 18:34:29.308 | 28.20.180.653 I slot launch_slot_: id  2 | task 16241 | processing task, is_child = 0
2026-05-23 18:34:33.142 | 28.24.014.337 I slot print_timing: id  2 | task 16241 | prompt processing, n_tokens =   4096, progress = 0.98, t =   3.83 s / 1068.43 tokens per second
2026-05-23 18:34:34.287 | 28.25.159.083 I slot print_timing: id  2 | task 16241 | prompt processing, n_tokens =   5257, progress = 0.99, t =   4.98 s / 1055.96 tokens per second
2026-05-23 18:34:34.211 | 28.25.083.546 I slot create_check: id  2 | task 16241 | created context checkpoint 19 of 32 (pos_min = 94558, pos_max = 94558, n_tokens = 94559, size = 347.658 MiB)
2026-05-23 18:34:34.695 | 28.25.567.299 I slot print_timing: id  2 | task 16241 | prompt processing, n_tokens =   5769, progress = 1.00, t =   5.89 s / 979.84 tokens per second
2026-05-23 18:34:35.133 | 28.26.005.403 I slot create_check: id  2 | task 16241 | created context checkpoint 20 of 32 (pos_min = 95070, pos_max = 95070, n_tokens = 95071, size = 348.730 MiB)
2026-05-23 18:34:36.735 | 28.27.607.275 I slot print_timing: id  2 | task 16241 | n_decoded =    101, tg =  64.98 t/s
2026-05-23 18:34:39.264 | 28.30.136.093 I slot print_timing: id  2 | task 16241 | n_decoded =    292, tg =  63.69 t/s
2026-05-23 18:34:40.515 | 28.31.387.815 I reasoning-budget: deactivated (natural end)
2026-05-23 18:34:42.279 | 28.33.151.599 I slot print_timing: id  2 | task 16241 | n_decoded =    489, tg =  64.34 t/s
2026-05-23 18:34:44.797 | 28.35.669.517 I slot print_timing: id  2 | task 16241 | n_decoded =    690, tg =  64.94 t/s
2026-05-23 18:34:46.723 | 28.37.595.735 I slot print_timing: id  2 | task 16241 | 
2026-05-23 18:34:46.723 | prompt eval time =    6373.15 ms /  5773 tokens (    1.10 ms per token,   905.83 tokens per second)
2026-05-23 18:34:46.723 |        eval time =   12551.82 ms /   824 tokens (   15.23 ms per token,    65.65 tokens per second)
2026-05-23 18:34:46.723 |       total time =   18924.97 ms /  6597 tokens
2026-05-23 18:34:46.723 | draft acceptance rate = 0.83766 (  516 accepted /   616 generated)
2026-05-23 18:34:46.723 | 28.37.595.771 I statistics draft-mtp: #calls(b,g,a) = 61 16306 20539, #gen drafts = 20539, #acc drafts = 18621, #gen tokens = 41078, #acc tokens = 35553, dur(b,g,a) = 0.098, 89687.482, 45.720 ms
2026-05-23 18:34:46.726 | 28.37.598.086 I slot      release: id  2 | task 16241 | stop processing: n_tokens = 95899, truncated = 0
2026-05-23 18:34:46.726 | 28.37.598.166 I srv  update_slots: all slots are idle
2026-05-23 18:34:47.045 | 28.37.916.961 I srv  params_from_: Chat format: peg-native
2026-05-23 18:34:47.046 | 28.37.918.433 I slot get_availabl: id  2 | task -1 | selected slot by LCP similarity, sim_best = 0.996 (> 0.100 thold), f_keep = 1.000
2026-05-23 18:34:47.047 | 28.37.919.190 I reasoning-budget: activated, budget=2147483647 tokens
2026-05-23 18:34:47.047 | 28.37.919.299 I slot launch_slot_: id  2 | task 16555 | processing task, is_child = 0
2026-05-23 18:34:47.477 | 28.38.349.215 I slot create_check: id  2 | task 16555 | created context checkpoint 21 of 32 (pos_min = 95898, pos_max = 95898, n_tokens = 95899, size = 350.464 MiB)
2026-05-23 18:34:48.307 | 28.39.179.492 I slot create_check: id  2 | task 16555 | created context checkpoint 22 of 32 (pos_min = 96289, pos_max = 96289, n_tokens = 96290, size = 351.283 MiB)
2026-05-23 18:34:49.488 | 28.40.360.554 I slot print_timing: id  2 | task 16555 | n_decoded =    101, tg =  61.77 t/s
2026-05-23 18:34:49.691 | 28.40.562.959 I reasoning-budget: deactivated (natural end)
2026-05-23 18:34:51.549 | 28.42.421.386 I slot print_timing: id  2 | task 16555 | 
2026-05-23 18:34:51.549 | prompt eval time =    1307.45 ms /   395 tokens (    3.31 ms per token,   302.11 tokens per second)
2026-05-23 18:34:51.549 |        eval time =    3695.86 ms /   237 tokens (   15.59 ms per token,    64.13 tokens per second)
2026-05-23 18:34:51.549 |       total time =    5003.31 ms /   632 tokens
2026-05-23 18:34:51.549 | draft acceptance rate = 0.81667 (  147 accepted /   180 generated)
2026-05-23 18:34:51.549 | 28.42.421.425 I statistics draft-mtp: #calls(b,g,a) = 62 16396 20629, #gen drafts = 20629, #acc drafts = 18702, #gen tokens = 41258, #acc tokens = 35700, dur(b,g,a) = 0.099, 90170.787, 45.886 ms
2026-05-23 18:34:51.551 | 28.42.423.695 I slot      release: id  2 | task 16555 | stop processing: n_tokens = 96531, truncated = 0
2026-05-23 18:34:51.551 | 28.42.423.772 I srv  update_slots: all slots are idle
2026-05-23 18:34:51.888 | 28.42.760.802 I srv  params_from_: Chat format: peg-native
2026-05-23 18:34:51.890 | 28.42.762.258 I slot get_availabl: id  2 | task -1 | selected slot by LCP similarity, sim_best = 0.999 (> 0.100 thold), f_keep = 1.000
2026-05-23 18:34:51.891 | 28.42.763.249 I reasoning-budget: activated, budget=2147483647 tokens
2026-05-23 18:34:51.891 | 28.42.763.354 I slot launch_slot_: id  2 | task 16648 | processing task, is_child = 0
2026-05-23 18:34:52.318 | 28.43.190.011 I slot create_check: id  2 | task 16648 | created context checkpoint 23 of 32 (pos_min = 96530, pos_max = 96530, n_tokens = 96531, size = 351.788 MiB)
2026-05-23 18:34:52.917 | 28.43.789.339 I reasoning-budget: deactivated (natural end)
2026-05-23 18:34:53.475 | 28.44.347.780 I slot print_timing: id  2 | task 16648 | 
2026-05-23 18:34:53.475 | prompt eval time =     562.20 ms /    63 tokens (    8.92 ms per token,   112.06 tokens per second)
2026-05-23 18:34:53.475 |        eval time =    1436.79 ms /    95 tokens (   15.12 ms per token,    66.12 tokens per second)
2026-05-23 18:34:53.475 |       total time =    1998.98 ms /   158 tokens
2026-05-23 18:34:53.475 | draft acceptance rate = 0.91176 (   62 accepted /    68 generated)
2026-05-23 18:34:53.475 | 28.44.347.817 I statistics draft-mtp: #calls(b,g,a) = 63 16430 20663, #gen drafts = 20663, #acc drafts = 18734, #gen tokens = 41326, #acc tokens = 35762, dur(b,g,a) = 0.101, 90352.960, 45.950 ms
2026-05-23 18:34:53.478 | 28.44.350.419 I slot      release: id  2 | task 16648 | stop processing: n_tokens = 96690, truncated = 0
2026-05-23 18:34:53.478 | 28.44.350.498 I srv  update_slots: all slots are idle
2026-05-23 18:34:53.781 | 28.44.653.526 I srv  params_from_: Chat format: peg-native
2026-05-23 18:34:53.782 | 28.44.654.941 I slot get_availabl: id  2 | task -1 | selected slot by LCP similarity, sim_best = 0.999 (> 0.100 thold), f_keep = 1.000
2026-05-23 18:34:53.783 | 28.44.655.750 I reasoning-budget: activated, budget=2147483647 tokens
2026-05-23 18:34:53.783 | 28.44.655.847 I slot launch_slot_: id  2 | task 16685 | processing task, is_child = 0
2026-05-23 18:34:54.210 | 28.45.082.055 I slot create_check: id  2 | task 16685 | created context checkpoint 24 of 32 (pos_min = 96689, pos_max = 96689, n_tokens = 96690, size = 352.121 MiB)
2026-05-23 18:34:54.696 | 28.45.568.539 I slot create_check: id  2 | task 16685 | created context checkpoint 25 of 32 (pos_min = 96818, pos_max = 96818, n_tokens = 96819, size = 352.391 MiB)
2026-05-23 18:34:55.294 | 28.46.166.098 I reasoning-budget: deactivated (natural end)
2026-05-23 18:34:56.198 | 28.47.070.176 I slot print_timing: id  2 | task 16685 | n_decoded =    100, tg =  68.83 t/s
2026-05-23 18:34:56.842 | 28.47.714.336 I slot print_timing: id  2 | task 16685 | 
2026-05-23 18:34:56.842 | prompt eval time =    1040.74 ms /   133 tokens (    7.83 ms per token,   127.79 tokens per second)
2026-05-23 18:34:56.842 |        eval time =    2096.67 ms /   143 tokens (   14.66 ms per token,    68.20 tokens per second)
2026-05-23 18:34:56.842 |       total time =    3137.42 ms /   276 tokens
2026-05-23 18:34:56.842 | draft acceptance rate = 0.94000 (   94 accepted /   100 generated)
2026-05-23 18:34:56.842 | 28.47.714.372 I statistics draft-mtp: #calls(b,g,a) = 64 16480 20713, #gen drafts = 20713, #acc drafts = 18783, #gen tokens = 41426, #acc tokens = 35856, dur(b,g,a) = 0.103, 90621.298, 46.050 ms
2026-05-23 18:34:56.844 | 28.47.716.579 I slot      release: id  2 | task 16685 | stop processing: n_tokens = 96967, truncated = 0
2026-05-23 18:34:56.844 | 28.47.716.651 I srv  update_slots: all slots are idle
2026-05-23 18:34:57.172 | 28.48.043.986 I srv  params_from_: Chat format: peg-native
2026-05-23 18:34:57.173 | 28.48.045.391 I slot get_availabl: id  2 | task -1 | selected slot by LCP similarity, sim_best = 1.000 (> 0.100 thold), f_keep = 1.000
2026-05-23 18:34:57.174 | 28.48.046.200 I reasoning-budget: activated, budget=2147483647 tokens
2026-05-23 18:34:57.174 | 28.48.046.289 I slot launch_slot_: id  2 | task 16738 | processing task, is_child = 0
2026-05-23 18:34:57.605 | 28.48.477.570 I slot create_check: id  2 | task 16738 | created context checkpoint 26 of 32 (pos_min = 96966, pos_max = 96966, n_tokens = 96967, size = 352.701 MiB)
2026-05-23 18:34:58.099 | 28.48.971.474 I reasoning-budget: deactivated (natural end)
2026-05-23 18:34:59.233 | 28.50.105.477 I slot print_timing: id  2 | task 16738 | n_decoded =    103, tg =  67.97 t/s
2026-05-23 18:35:01.424 | 28.52.296.038 I slot print_timing: id  2 | task 16738 | 
2026-05-23 18:35:01.424 | prompt eval time =     543.56 ms /    18 tokens (   30.20 ms per token,    33.12 tokens per second)
2026-05-23 18:35:01.424 |        eval time =    4207.30 ms /   289 tokens (   14.56 ms per token,    68.69 tokens per second)
2026-05-23 18:35:01.424 |       total time =    4750.86 ms /   307 tokens
2026-05-23 18:35:01.424 | draft acceptance rate = 0.93564 (  189 accepted /   202 generated)
2026-05-23 18:35:01.424 | 28.52.296.073 I statistics draft-mtp: #calls(b,g,a) = 65 16581 20814, #gen drafts = 20814, #acc drafts = 18881, #gen tokens = 41628, #acc tokens = 36045, dur(b,g,a) = 0.104, 91166.987, 46.242 ms
2026-05-23 18:35:01.426 | 28.52.298.384 I slot      release: id  2 | task 16738 | stop processing: n_tokens = 97275, truncated = 0
2026-05-23 18:35:01.426 | 28.52.298.460 I srv  update_slots: all slots are idle
2026-05-23 18:35:01.821 | 28.52.693.485 I srv  params_from_: Chat format: peg-native
2026-05-23 18:35:01.823 | 28.52.694.977 I slot get_availabl: id  2 | task -1 | selected slot by LCP similarity, sim_best = 1.000 (> 0.100 thold), f_keep = 1.000
2026-05-23 18:35:01.823 | 28.52.695.876 I reasoning-budget: activated, budget=2147483647 tokens
2026-05-23 18:35:01.823 | 28.52.695.990 I slot launch_slot_: id  2 | task 16842 | processing task, is_child = 0
2026-05-23 18:35:02.255 | 28.53.126.977 I slot create_check: id  2 | task 16842 | created context checkpoint 27 of 32 (pos_min = 97274, pos_max = 97274, n_tokens = 97275, size = 353.346 MiB)
2026-05-23 18:35:03.128 | 28.54.000.348 I reasoning-budget: deactivated (natural end)
2026-05-23 18:35:04.067 | 28.54.939.031 I slot print_timing: id  2 | task 16842 | n_decoded =    100, tg =  59.17 t/s
2026-05-23 18:35:06.566 | 28.57.438.041 I slot print_timing: id  2 | task 16842 | n_decoded =    313, tg =  66.65 t/s
2026-05-23 18:35:08.750 | 28.59.622.520 I slot print_timing: id  2 | task 16842 | 
2026-05-23 18:35:08.750 | prompt eval time =     552.77 ms /    38 tokens (   14.55 ms per token,    68.74 tokens per second)
2026-05-23 18:35:08.750 |        eval time =    6880.88 ms /   441 tokens (   15.60 ms per token,    64.09 tokens per second)
2026-05-23 18:35:08.750 |       total time =    7433.65 ms /   479 tokens
2026-05-23 18:35:08.750 | draft acceptance rate = 0.81250 (  273 accepted /   336 generated)
2026-05-23 18:35:08.750 | 28.59.622.558 I statistics draft-mtp: #calls(b,g,a) = 66 16749 20982, #gen drafts = 20982, #acc drafts = 19027, #gen tokens = 41964, #acc tokens = 36318, dur(b,g,a) = 0.106, 92060.769, 46.543 ms
2026-05-23 18:35:08.752 | 28.59.624.898 I slot      release: id  2 | task 16842 | stop processing: n_tokens = 97754, truncated = 0
2026-05-23 18:35:08.754 | 28.59.625.001 I srv  update_slots: all slots are idle
2026-05-23 18:35:08.831 | 28.59.703.579 I srv  params_from_: Chat format: peg-native
2026-05-23 18:35:08.832 | 28.59.704.684 I slot get_availabl: id  2 | task -1 | selected slot by LCP similarity, sim_best = 0.366 (> 0.100 thold), f_keep = 0.026
2026-05-23 18:35:08.832 | 28.59.704.704 I srv  get_availabl: updating prompt cache
2026-05-23 18:35:08.836 | 28.59.708.806 W srv   prompt_save:  - saving prompt with length 97754, total state size = 3601.952 MiB (draft: 204.723 MiB)
2026-05-23 18:35:20.726 | 29.11.598.794 I srv          load:  - looking for better prompt, base f_keep = 0.026, sim = 0.366
2026-05-23 18:35:20.726 | 29.11.598.842 W srv        update:  - cache size limit reached, removing oldest entry (size = 5439.010 MiB)
2026-05-23 18:35:21.068 | 29.11.940.765 I srv        update:  - cache state: 1 prompts, 11865.800 MiB (limits: 8192.000 MiB, 131072 tokens, 131072 est)
2026-05-23 18:35:21.068 | 29.11.940.787 I srv        update:    - prompt 0x63d3b4a1f8e0:   97754 tokens, checkpoints: 27, 11865.800 MiB
2026-05-23 18:35:21.068 | 29.11.940.789 I srv  get_availabl: prompt cache update took 13877.99 ms
2026-05-23 18:35:21.069 | 29.11.941.418 I reasoning-budget: activated, budget=2147483647 tokens
2026-05-23 18:35:21.069 | 29.11.941.533 I slot launch_slot_: id  2 | task 17013 | processing task, is_child = 0
2026-05-23 18:35:21.069 | 29.11.941.567 W slot update_slots: id  2 | task 17013 | n_past = 2504, slot.prompt.tokens.size() = 97754, seq_id = 2, pos_min = 97753, n_swa = 0
2026-05-23 18:35:21.069 | 29.11.941.568 I slot update_slots: id  2 | task 17013 | Checking checkpoint with [97274, 97274] against 2504...
2026-05-23 18:35:21.069 | 29.11.941.569 I slot update_slots: id  2 | task 17013 | Checking checkpoint with [96966, 96966] against 2504...
2026-05-23 18:35:21.069 | 29.11.941.570 I slot update_slots: id  2 | task 17013 | Checking checkpoint with [96818, 96818] against 2504...
2026-05-23 18:35:21.069 | 29.11.941.571 I slot update_slots: id  2 | task 17013 | Checking checkpoint with [96689, 96689] against 2504...
2026-05-23 18:35:21.069 | 29.11.941.572 I slot update_slots: id  2 | task 17013 | Checking checkpoint with [96530, 96530] against 2504...
2026-05-23 18:35:21.069 | 29.11.941.572 I slot update_slots: id  2 | task 17013 | Checking checkpoint with [96289, 96289] against 2504...
2026-05-23 18:35:21.069 | 29.11.941.572 I slot update_slots: id  2 | task 17013 | Checking checkpoint with [95898, 95898] against 2504...
2026-05-23 18:35:21.069 | 29.11.941.573 I slot update_slots: id  2 | task 17013 | Checking checkpoint with [95070, 95070] against 2504...
2026-05-23 18:35:21.069 | 29.11.941.574 I slot update_slots: id  2 | task 17013 | Checking checkpoint with [94558, 94558] against 2504...
2026-05-23 18:35:21.069 | 29.11.941.575 I slot update_slots: id  2 | task 17013 | Checking checkpoint with [88735, 88735] against 2504...
2026-05-23 18:35:21.069 | 29.11.941.576 I slot update_slots: id  2 | task 17013 | Checking checkpoint with [88348, 88348] against 2504...
2026-05-23 18:35:21.069 | 29.11.941.576 I slot update_slots: id  2 | task 17013 | Checking checkpoint with [88013, 88013] against 2504...
2026-05-23 18:35:21.069 | 29.11.941.577 I slot update_slots: id  2 | task 17013 | Checking checkpoint with [87805, 87805] against 2504...
2026-05-23 18:35:21.069 | 29.11.941.578 I slot update_slots: id  2 | task 17013 | Checking checkpoint with [87426, 87426] against 2504...
2026-05-23 18:35:21.069 | 29.11.941.579 I slot update_slots: id  2 | task 17013 | Checking checkpoint with [87041, 87041] against 2504...
2026-05-23 18:35:21.069 | 29.11.941.579 I slot update_slots: id  2 | task 17013 | Checking checkpoint with [86690, 86690] against 2504...
2026-05-23 18:35:21.069 | 29.11.941.580 I slot update_slots: id  2 | task 17013 | Checking checkpoint with [86178, 86178] against 2504...
2026-05-23 18:35:21.069 | 29.11.941.581 I slot update_slots: id  2 | task 17013 | Checking checkpoint with [81919, 81919] against 2504...
2026-05-23 18:35:21.069 | 29.11.941.581 I slot update_slots: id  2 | task 17013 | Checking checkpoint with [73727, 73727] against 2504...
2026-05-23 18:35:21.069 | 29.11.941.582 I slot update_slots: id  2 | task 17013 | Checking checkpoint with [65535, 65535] against 2504...
2026-05-23 18:35:21.069 | 29.11.941.582 I slot update_slots: id  2 | task 17013 | Checking checkpoint with [57343, 57343] against 2504...
2026-05-23 18:35:21.069 | 29.11.941.583 I slot update_slots: id  2 | task 17013 | Checking checkpoint with [49151, 49151] against 2504...
2026-05-23 18:35:21.069 | 29.11.941.584 I slot update_slots: id  2 | task 17013 | Checking checkpoint with [40959, 40959] against 2504...
2026-05-23 18:35:21.069 | 29.11.941.585 I slot update_slots: id  2 | task 17013 | Checking checkpoint with [32767, 32767] against 2504...
2026-05-23 18:35:21.069 | 29.11.941.585 I slot update_slots: id  2 | task 17013 | Checking checkpoint with [24575, 24575] against 2504...
2026-05-23 18:35:21.069 | 29.11.941.585 I slot update_slots: id  2 | task 17013 | Checking checkpoint with [16383, 16383] against 2504...
2026-05-23 18:35:21.069 | 29.11.941.586 I slot update_slots: id  2 | task 17013 | Checking checkpoint with [8191, 8191] against 2504...
2026-05-23 18:35:21.069 | 29.11.941.586 W slot update_slots: id  2 | task 17013 | forcing full prompt re-processing due to lack of cache data (likely due to SWA or hybrid/recurrent memory, see https://github.com/ggml-org/llama.cpp/pull/13194#issuecomment-2868343055)
2026-05-23 18:35:21.069 | 29.11.941.587 W slot update_slots: id  2 | task 17013 | erased invalidated context checkpoint (pos_min = 8191, pos_max = 8191, n_tokens = 8192, n_swa = 0, pos_next = 0, size = 166.782 MiB)
2026-05-23 18:35:21.069 | 29.11.941.590 W slot update_slots: id  2 | task 17013 | erased invalidated context checkpoint (pos_min = 16383, pos_max = 16383, n_tokens = 16384, n_swa = 0, pos_next = 0, size = 183.939 MiB)
2026-05-23 18:35:21.082 | 29.11.954.762 W slot update_slots: id  2 | task 17013 | erased invalidated context checkpoint (pos_min = 24575, pos_max = 24575, n_tokens = 24576, n_swa = 0, pos_next = 0, size = 201.095 MiB)
2026-05-23 18:35:21.097 | 29.11.968.959 W slot update_slots: id  2 | task 17013 | erased invalidated context checkpoint (pos_min = 32767, pos_max = 32767, n_tokens = 32768, n_swa = 0, pos_next = 0, size = 218.251 MiB)
2026-05-23 18:35:21.111 | 29.11.983.919 W slot update_slots: id  2 | task 17013 | erased invalidated context checkpoint (pos_min = 40959, pos_max = 40959, n_tokens = 40960, n_swa = 0, pos_next = 0, size = 235.407 MiB)
2026-05-23 18:35:21.127 | 29.11.999.517 W slot update_slots: id  2 | task 17013 | erased invalidated context checkpoint (pos_min = 49151, pos_max = 49151, n_tokens = 49152, n_swa = 0, pos_next = 0, size = 252.564 MiB)
2026-05-23 18:35:21.144 | 29.12.016.103 W slot update_slots: id  2 | task 17013 | erased invalidated context checkpoint (pos_min = 57343, pos_max = 57343, n_tokens = 57344, n_swa = 0, pos_next = 0, size = 269.720 MiB)
2026-05-23 18:35:21.161 | 29.12.033.590 W slot update_slots: id  2 | task 17013 | erased invalidated context checkpoint (pos_min = 65535, pos_max = 65535, n_tokens = 65536, n_swa = 0, pos_next = 0, size = 286.876 MiB)
2026-05-23 18:35:21.179 | 29.12.051.716 W slot update_slots: id  2 | task 17013 | erased invalidated context checkpoint (pos_min = 73727, pos_max = 73727, n_tokens = 73728, n_swa = 0, pos_next = 0, size = 304.032 MiB)
2026-05-23 18:35:21.198 | 29.12.070.753 W slot update_slots: id  2 | task 17013 | erased invalidated context checkpoint (pos_min = 81919, pos_max = 81919, n_tokens = 81920, n_swa = 0, pos_next = 0, size = 321.189 MiB)
2026-05-23 18:35:21.219 | 29.12.091.387 W slot update_slots: id  2 | task 17013 | erased invalidated context checkpoint (pos_min = 86178, pos_max = 86178, n_tokens = 86179, n_swa = 0, pos_next = 0, size = 330.108 MiB)
2026-05-23 18:35:21.240 | 29.12.112.162 W slot update_slots: id  2 | task 17013 | erased invalidated context checkpoint (pos_min = 86690, pos_max = 86690, n_tokens = 86691, n_swa = 0, pos_next = 0, size = 331.180 MiB)
2026-05-23 18:35:21.260 | 29.12.132.809 W slot update_slots: id  2 | task 17013 | erased invalidated context checkpoint (pos_min = 87041, pos_max = 87041, n_tokens = 87042, n_swa = 0, pos_next = 0, size = 331.916 MiB)
2026-05-23 18:35:21.282 | 29.12.154.281 W slot update_slots: id  2 | task 17013 | erased invalidated context checkpoint (pos_min = 87426, pos_max = 87426, n_tokens = 87427, n_swa = 0, pos_next = 0, size = 332.722 MiB)
2026-05-23 18:35:21.303 | 29.12.175.440 W slot update_slots: id  2 | task 17013 | erased invalidated context checkpoint (pos_min = 87805, pos_max = 87805, n_tokens = 87806, n_swa = 0, pos_next = 0, size = 333.516 MiB)
2026-05-23 18:35:21.324 | 29.12.196.579 W slot update_slots: id  2 | task 17013 | erased invalidated context checkpoint (pos_min = 88013, pos_max = 88013, n_tokens = 88014, n_swa = 0, pos_next = 0, size = 333.951 MiB)
2026-05-23 18:35:21.345 | 29.12.217.667 W slot update_slots: id  2 | task 17013 | erased invalidated context checkpoint (pos_min = 88348, pos_max = 88348, n_tokens = 88349, n_swa = 0, pos_next = 0, size = 334.653 MiB)
2026-05-23 18:35:21.366 | 29.12.238.711 W slot update_slots: id  2 | task 17013 | erased invalidated context checkpoint (pos_min = 88735, pos_max = 88735, n_tokens = 88736, n_swa = 0, pos_next = 0, size = 335.463 MiB)
2026-05-23 18:35:21.388 | 29.12.260.102 W slot update_slots: id  2 | task 17013 | erased invalidated context checkpoint (pos_min = 94558, pos_max = 94558, n_tokens = 94559, n_swa = 0, pos_next = 0, size = 347.658 MiB)
2026-05-23 18:35:21.410 | 29.12.282.218 W slot update_slots: id  2 | task 17013 | erased invalidated context checkpoint (pos_min = 95070, pos_max = 95070, n_tokens = 95071, n_swa = 0, pos_next = 0, size = 348.730 MiB)
2026-05-23 18:35:21.432 | 29.12.304.039 W slot update_slots: id  2 | task 17013 | erased invalidated context checkpoint (pos_min = 95898, pos_max = 95898, n_tokens = 95899, n_swa = 0, pos_next = 0, size = 350.464 MiB)
2026-05-23 18:35:21.454 | 29.12.326.430 W slot update_slots: id  2 | task 17013 | erased invalidated context checkpoint (pos_min = 96289, pos_max = 96289, n_tokens = 96290, n_swa = 0, pos_next = 0, size = 351.283 MiB)
2026-05-23 18:35:21.476 | 29.12.348.745 W slot update_slots: id  2 | task 17013 | erased invalidated context checkpoint (pos_min = 96530, pos_max = 96530, n_tokens = 96531, n_swa = 0, pos_next = 0, size = 351.788 MiB)
2026-05-23 18:35:21.498 | 29.12.370.756 W slot update_slots: id  2 | task 17013 | erased invalidated context checkpoint (pos_min = 96689, pos_max = 96689, n_tokens = 96690, n_swa = 0, pos_next = 0, size = 352.121 MiB)
2026-05-23 18:35:21.521 | 29.12.393.232 W slot update_slots: id  2 | task 17013 | erased invalidated context checkpoint (pos_min = 96818, pos_max = 96818, n_tokens = 96819, n_swa = 0, pos_next = 0, size = 352.391 MiB)
2026-05-23 18:35:21.544 | 29.12.415.948 W slot update_slots: id  2 | task 17013 | erased invalidated context checkpoint (pos_min = 96966, pos_max = 96966, n_tokens = 96967, n_swa = 0, pos_next = 0, size = 352.701 MiB)
2026-05-23 18:35:21.566 | 29.12.437.927 W slot update_slots: id  2 | task 17013 | erased invalidated context checkpoint (pos_min = 97274, pos_max = 97274, n_tokens = 97275, n_swa = 0, pos_next = 0, size = 353.346 MiB)
2026-05-23 18:35:24.095 | 29.14.967.597 I slot print_timing: id  2 | task 17013 | prompt processing, n_tokens =   6328, progress = 0.92, t =   3.03 s / 2091.19 tokens per second
2026-05-23 18:35:24.126 | 29.14.998.382 I slot create_check: id  2 | task 17013 | created context checkpoint 1 of 32 (pos_min = 6327, pos_max = 6327, n_tokens = 6328, size = 162.879 MiB)
2026-05-23 18:35:24.328 | 29.15.200.755 I slot print_timing: id  2 | task 17013 | prompt processing, n_tokens =   6840, progress = 1.00, t =   3.26 s / 2098.68 tokens per second
2026-05-23 18:35:24.461 | 29.15.333.549 I slot create_check: id  2 | task 17013 | created context checkpoint 2 of 32 (pos_min = 6839, pos_max = 6839, n_tokens = 6840, size = 163.951 MiB)
2026-05-23 18:35:24.789 | 29.15.661.086 I reasoning-budget: deactivated (natural end)
2026-05-23 18:35:25.237 | 29.16.109.407 I slot print_timing: id  2 | task 17013 | n_decoded =    100, tg =  91.33 t/s
2026-05-23 18:35:28.249 | 29.19.121.780 I slot print_timing: id  2 | task 17013 | n_decoded =    411, tg = 100.06 t/s
2026-05-23 18:35:28.622 | 29.19.494.686 I slot print_timing: id  2 | task 17013 | 
2026-05-23 18:35:28.622 | prompt eval time =    3427.50 ms /  6844 tokens (    0.50 ms per token,  1996.79 tokens per second)
2026-05-23 18:35:28.622 |        eval time =    4480.24 ms /   449 tokens (    9.98 ms per token,   100.22 tokens per second)
2026-05-23 18:35:28.622 |       total time =    7907.74 ms /  7293 tokens
2026-05-23 18:35:28.622 | draft acceptance rate = 0.95779 (  295 accepted /   308 generated)
2026-05-23 18:35:28.622 | 29.19.494.721 I statistics draft-mtp: #calls(b,g,a) = 67 16903 21136, #gen drafts = 21136, #acc drafts = 19179, #gen tokens = 42272, #acc tokens = 36613, dur(b,g,a) = 0.107, 92734.494, 46.843 ms
2026-05-23 18:35:28.623 | 29.19.495.116 I slot      release: id  2 | task 17013 | stop processing: n_tokens = 7293, truncated = 0
2026-05-23 18:35:28.623 | 29.19.495.191 I srv  update_slots: all slots are idle
2026-05-23 18:35:28.738 | 29.19.610.854 I srv  params_from_: Chat format: peg-native
2026-05-23 18:35:28.740 | 29.19.612.146 I slot get_availabl: id  2 | task -1 | selected slot by LCP similarity, sim_best = 0.858 (> 0.100 thold), f_keep = 1.000
2026-05-23 18:35:28.740 | 29.19.612.946 I reasoning-budget: activated, budget=2147483647 tokens
2026-05-23 18:35:28.741 | 29.19.613.104 I slot launch_slot_: id  2 | task 17174 | processing task, is_child = 0
2026-05-23 18:35:29.176 | 29.20.048.443 I slot create_check: id  2 | task 17174 | created context checkpoint 3 of 32 (pos_min = 7982, pos_max = 7982, n_tokens = 7983, size = 166.345 MiB)
2026-05-23 18:35:29.517 | 29.20.389.153 I slot create_check: id  2 | task 17174 | created context checkpoint 4 of 32 (pos_min = 8494, pos_max = 8494, n_tokens = 8495, size = 167.417 MiB)
2026-05-23 18:35:29.806 | 29.20.678.450 I reasoning-budget: deactivated (natural end)
2026-05-23 18:35:30.747 | 29.21.619.327 I slot print_timing: id  2 | task 17174 | n_decoded =    154, tg =  90.67 t/s
2026-05-23 18:35:33.753 | 29.24.625.320 I slot print_timing: id  2 | task 17174 | n_decoded =    454, tg =  96.50 t/s
2026-05-23 18:35:36.270 | 29.27.142.787 I slot print_timing: id  2 | task 17174 | n_decoded =    754, tg =  97.71 t/s
2026-05-23 18:35:39.293 | 29.30.164.928 I slot print_timing: id  2 | task 17174 | n_decoded =   1054, tg =  98.15 t/s
2026-05-23 18:35:41.806 | 29.32.678.153 I slot print_timing: id  2 | task 17174 | n_decoded =   1351, tg =  98.23 t/s
2026-05-23 18:35:44.319 | 29.35.191.789 I slot print_timing: id  2 | task 17174 | n_decoded =   1654, tg =  98.65 t/s
2026-05-23 18:35:47.323 | 29.38.195.176 I slot print_timing: id  2 | task 17174 | n_decoded =   1963, tg =  99.29 t/s
2026-05-23 18:35:49.841 | 29.40.713.452 I slot print_timing: id  2 | task 17174 | n_decoded =   2272, tg =  99.67 t/s
2026-05-23 18:35:52.861 | 29.43.733.463 I slot print_timing: id  2 | task 17174 | n_decoded =   2581, tg =  99.98 t/s
2026-05-23 18:35:53.098 | 29.43.970.602 I slot print_timing: id  2 | task 17174 | 
2026-05-23 18:35:53.098 | prompt eval time =     813.91 ms /  1206 tokens (    0.67 ms per token,  1481.73 tokens per second)
2026-05-23 18:35:53.098 |        eval time =   26053.34 ms /  2604 tokens (   10.01 ms per token,    99.95 tokens per second)
2026-05-23 18:35:53.098 |       total time =   26867.25 ms /  3810 tokens
2026-05-23 18:35:53.098 | draft acceptance rate = 0.98970 ( 1730 accepted /  1748 generated)
2026-05-23 18:35:53.098 | 29.43.970.635 I statistics draft-mtp: #calls(b,g,a) = 68 17777 22010, #gen drafts = 22010, #acc drafts = 20046, #gen tokens = 44020, #acc tokens = 38343, dur(b,g,a) = 0.108, 96773.583, 48.780 ms
2026-05-23 18:35:53.099 | 29.43.971.026 I slot      release: id  2 | task 17174 | stop processing: n_tokens = 11103, truncated = 0
2026-05-23 18:35:53.099 | 29.43.971.096 I srv  update_slots: all slots are idle
2026-05-23 18:35:53.274 | 29.44.146.254 I srv  params_from_: Chat format: peg-native
2026-05-23 18:35:53.275 | 29.44.147.395 I slot get_availabl: id  2 | task -1 | selected slot by LCP similarity, sim_best = 0.413 (> 0.100 thold), f_keep = 1.000
2026-05-23 18:35:53.276 | 29.44.148.199 I reasoning-budget: activated, budget=2147483647 tokens
2026-05-23 18:35:53.276 | 29.44.148.328 I slot launch_slot_: id  2 | task 18052 | processing task, is_child = 0
2026-05-23 18:35:55.427 | 29.46.299.738 I slot update_slots: id  2 | task 18052 | 8192 tokens since last checkpoint at 8495, creating new checkpoint during processing at position 19295
2026-05-23 18:35:55.556 | 29.46.428.093 I slot create_check: id  2 | task 18052 | created context checkpoint 5 of 32 (pos_min = 17246, pos_max = 17246, n_tokens = 17247, size = 185.746 MiB)
2026-05-23 18:35:56.465 | 29.47.337.163 I slot print_timing: id  2 | task 18052 | prompt processing, n_tokens =   8192, progress = 0.72, t =   3.68 s / 2224.35 tokens per second
2026-05-23 18:35:57.391 | 29.48.263.203 I slot print_timing: id  2 | task 18052 | prompt processing, n_tokens =  10240, progress = 0.79, t =   4.61 s / 2221.78 tokens per second
2026-05-23 18:35:58.335 | 29.49.207.565 I slot print_timing: id  2 | task 18052 | prompt processing, n_tokens =  12288, progress = 0.87, t =   5.55 s / 2212.75 tokens per second
2026-05-23 18:35:59.299 | 29.50.171.031 I slot print_timing: id  2 | task 18052 | prompt processing, n_tokens =  14336, progress = 0.95, t =   6.52 s / 2199.87 tokens per second
2026-05-23 18:35:59.299 | 29.50.171.214 I slot update_slots: id  2 | task 18052 | 8192 tokens since last checkpoint at 17247, creating new checkpoint during processing at position 26398
2026-05-23 18:35:59.466 | 29.50.338.784 I slot create_check: id  2 | task 18052 | created context checkpoint 6 of 32 (pos_min = 25438, pos_max = 25438, n_tokens = 25439, size = 202.902 MiB)
2026-05-23 18:35:59.406 | 29.50.278.867 I slot print_timing: id  2 | task 18052 | prompt processing, n_tokens =  15295, progress = 0.98, t =   7.13 s / 2144.10 tokens per second
2026-05-23 18:35:59.646 | 29.50.518.662 I slot create_check: id  2 | task 18052 | created context checkpoint 7 of 32 (pos_min = 26397, pos_max = 26397, n_tokens = 26398, size = 204.911 MiB)
2026-05-23 18:35:59.890 | 29.50.762.132 I slot print_timing: id  2 | task 18052 | prompt processing, n_tokens =  15807, progress = 1.00, t =   7.62 s / 2075.29 tokens per second
2026-05-23 18:36:00.150 | 29.51.022.895 I slot create_check: id  2 | task 18052 | created context checkpoint 8 of 32 (pos_min = 26909, pos_max = 26909, n_tokens = 26910, size = 205.983 MiB)
2026-05-23 18:36:01.373 | 29.52.245.655 I slot print_timing: id  2 | task 18052 | n_decoded =    100, tg =  84.65 t/s
2026-05-23 18:36:04.379 | 29.55.251.524 I slot print_timing: id  2 | task 18052 | n_decoded =    362, tg =  86.46 t/s
2026-05-23 18:36:06.911 | 29.57.782.958 I slot print_timing: id  2 | task 18052 | n_decoded =    654, tg =  90.67 t/s
2026-05-23 18:36:09.433 | 30.00.305.000 I slot print_timing: id  2 | task 18052 | n_decoded =    898, tg =  87.73 t/s
2026-05-23 18:36:12.448 | 30.03.320.135 I slot print_timing: id  2 | task 18052 | n_decoded =   1189, tg =  89.73 t/s
2026-05-23 18:36:14.972 | 30.05.844.395 I slot print_timing: id  2 | task 18052 | n_decoded =   1458, tg =  89.58 t/s
2026-05-23 18:36:17.884 | 30.08.755.914 I slot print_timing: id  2 | task 18052 | n_decoded =   1740, tg =  90.23 t/s
2026-05-23 18:36:20.506 | 30.11.378.176 I slot print_timing: id  2 | task 18052 | n_decoded =   2005, tg =  89.86 t/s
2026-05-23 18:36:23.532 | 30.14.404.367 I slot print_timing: id  2 | task 18052 | n_decoded =   2271, tg =  89.63 t/s
2026-05-23 18:36:26.039 | 30.16.910.956 I slot print_timing: id  2 | task 18052 | n_decoded =   2530, tg =  89.26 t/s
2026-05-23 18:36:26.622 | 30.17.494.142 I reasoning-budget: deactivated (natural end)
2026-05-23 18:36:29.055 | 30.19.927.841 I slot print_timing: id  2 | task 18052 | n_decoded =   2790, tg =  88.97 t/s
2026-05-23 18:36:31.563 | 30.22.435.767 I slot print_timing: id  2 | task 18052 | n_decoded =   3071, tg =  89.35 t/s
2026-05-23 18:36:34.565 | 30.25.437.328 I slot print_timing: id  2 | task 18052 | n_decoded =   3354, tg =  89.75 t/s
2026-05-23 18:36:36.691 | 30.27.562.960 I slot print_timing: id  2 | task 18052 | 
2026-05-23 18:36:36.691 | prompt eval time =    7918.86 ms / 15811 tokens (    0.50 ms per token,  1996.62 tokens per second)
2026-05-23 18:36:36.691 |        eval time =   39998.16 ms /  3578 tokens (   11.18 ms per token,    89.45 tokens per second)
2026-05-23 18:36:36.691 |       total time =   47917.02 ms / 19389 tokens
2026-05-23 18:36:36.691 | draft acceptance rate = 0.88575 ( 2287 accepted /  2582 generated)
2026-05-23 18:36:36.691 | 30.27.562.997 I statistics draft-mtp: #calls(b,g,a) = 69 19068 23301, #gen drafts = 23301, #acc drafts = 21233, #gen tokens = 46602, #acc tokens = 40630, dur(b,g,a) = 0.111, 102778.033, 51.281 ms
2026-05-23 18:36:36.691 | 30.27.563.837 I slot      release: id  2 | task 18052 | stop processing: n_tokens = 30492, truncated = 0
2026-05-23 18:36:36.691 | 30.27.563.930 I srv  update_slots: all slots are idle
2026-05-23 18:36:37.097 | 30.27.969.510 I srv  params_from_: Chat format: peg-native
2026-05-23 18:36:37.098 | 30.27.970.903 I slot get_availabl: id  3 | task -1 | selected slot by LRU, t_last = 1768284192
2026-05-23 18:36:37.098 | 30.27.970.932 I srv  get_availabl: updating prompt cache
2026-05-23 18:36:37.098 | 30.27.970.936 I srv          load:  - looking for better prompt, base f_keep = -1.000, sim = 0.000
2026-05-23 18:36:37.098 | 30.27.971.019 I srv          load:  - found better prompt with f_keep = 1.000, sim = 0.989
2026-05-23 18:36:37.875 | 30.28.746.969 I srv        update:  - cache state: 0 prompts, 0.000 MiB (limits: 8192.000 MiB, 131072 tokens, 8589934592 est)
2026-05-23 18:36:37.875 | 30.28.746.992 I srv  get_availabl: prompt cache update took 776.06 ms
2026-05-23 18:36:37.875 | 30.28.747.735 I reasoning-budget: activated, budget=2147483647 tokens
2026-05-23 18:36:37.875 | 30.28.747.847 I slot launch_slot_: id  3 | task 19354 | processing task, is_child = 0
2026-05-23 18:36:37.875 | 30.28.747.867 I slot slot_save_an: id  2 | task -1 | saving idle slot to prompt cache
2026-05-23 18:36:37.877 | 30.28.749.454 W srv   prompt_save:  - saving prompt with length 30492, total state size = 1226.496 MiB (draft: 63.858 MiB)
2026-05-23 18:36:39.962 | 30.30.834.341 I slot prompt_clear: id  2 | task -1 | clearing prompt with 30492 tokens
2026-05-23 18:36:39.968 | 30.30.840.593 I srv        update:  - cache state: 1 prompts, 2686.630 MiB (limits: 8192.000 MiB, 131072 tokens, 131072 est)
2026-05-23 18:36:39.968 | 30.30.840.627 I srv        update:    - prompt 0x63d3b432d280:   30492 tokens, checkpoints:  8,  2686.630 MiB
2026-05-23 18:36:41.010 | 30.31.882.432 I slot create_check: id  3 | task 19354 | created context checkpoint 28 of 32 (pos_min = 98303, pos_max = 98303, n_tokens = 98304, size = 355.501 MiB)
2026-05-23 18:36:41.902 | 30.32.774.784 I slot create_check: id  3 | task 19354 | created context checkpoint 29 of 32 (pos_min = 98815, pos_max = 98815, n_tokens = 98816, size = 356.573 MiB)
2026-05-23 18:36:43.630 | 30.34.502.256 I reasoning-budget: deactivated (natural end)
2026-05-23 18:36:43.678 | 30.34.550.123 I slot print_timing: id  3 | task 19354 | n_decoded =    102, tg =  50.29 t/s
2026-05-23 18:36:46.529 | 30.37.401.004 I slot print_timing: id  3 | task 19354 | n_decoded =    306, tg =  60.39 t/s
2026-05-23 18:36:47.775 | 30.38.647.043 I slot print_timing: id  3 | task 19354 | 
2026-05-23 18:36:47.775 | prompt eval time =    1984.30 ms /  1066 tokens (    1.86 ms per token,   537.22 tokens per second)
2026-05-23 18:36:47.775 |        eval time =    6312.71 ms /   390 tokens (   16.19 ms per token,    61.78 tokens per second)
2026-05-23 18:36:47.775 |       total time =    8297.01 ms /  1456 tokens
2026-05-23 18:36:47.775 | draft acceptance rate = 0.87943 (  248 accepted /   282 generated)
2026-05-23 18:36:47.775 | 30.38.647.108 I statistics draft-mtp: #calls(b,g,a) = 70 19209 23442, #gen drafts = 23442, #acc drafts = 21361, #gen tokens = 46884, #acc tokens = 40878, dur(b,g,a) = 0.113, 103560.145, 51.583 ms
2026-05-23 18:36:47.777 | 30.38.649.411 I slot      release: id  3 | task 19354 | stop processing: n_tokens = 99209, truncated = 0
2026-05-23 18:36:47.777 | 30.38.649.486 I srv  update_slots: all slots are idle
2026-05-23 18:36:48.045 | 30.38.917.349 I srv  params_from_: Chat format: peg-native
2026-05-23 18:36:48.045 | 30.38.917.557 I slot get_availabl: id  1 | task -1 | selected slot by LRU, t_last = 1798097045
2026-05-23 18:36:48.045 | 30.38.917.581 I srv  get_availabl: updating prompt cache
2026-05-23 18:36:48.045 | 30.38.917.584 I srv          load:  - looking for better prompt, base f_keep = -1.000, sim = 0.000
2026-05-23 18:36:48.045 | 30.38.917.592 I srv        update:  - cache state: 1 prompts, 2686.630 MiB (limits: 8192.000 MiB, 131072 tokens, 131072 est)
2026-05-23 18:36:48.045 | 30.38.917.593 I srv        update:    - prompt 0x63d3b432d280:   30492 tokens, checkpoints:  8,  2686.630 MiB
2026-05-23 18:36:48.045 | 30.38.917.594 I srv  get_availabl: prompt cache update took 0.01 ms
2026-05-23 18:36:48.045 | 30.38.917.932 I slot launch_slot_: id  1 | task 19499 | processing task, is_child = 0
2026-05-23 18:36:48.045 | 30.38.917.958 I slot slot_save_an: id  3 | task -1 | saving idle slot to prompt cache
2026-05-23 18:36:48.050 | 30.38.922.003 W srv   prompt_save:  - saving prompt with length 99209, total state size = 3653.338 MiB (draft: 207.770 MiB)
2026-05-23 18:37:01.059 | 30.51.931.427 I slot prompt_clear: id  3 | task -1 | clearing prompt with 99209 tokens
2026-05-23 18:37:01.075 | 30.51.947.598 W srv        update:  - cache size limit reached, removing oldest entry (size = 2686.630 MiB)
2026-05-23 18:37:01.242 | 30.52.114.166 I srv        update:  - cache state: 1 prompts, 12629.260 MiB (limits: 8192.000 MiB, 131072 tokens, 131072 est)
2026-05-23 18:37:01.242 | 30.52.114.191 I srv        update:    - prompt 0x63d3af1762d0:   99209 tokens, checkpoints: 29, 12629.260 MiB
2026-05-23 18:37:01.242 | 30.52.114.681 W slot update_slots: id  1 | task 19499 | erased invalidated context checkpoint (pos_min = 6777, pos_max = 6777, n_tokens = 6778, n_swa = 0, pos_next = 0, size = 163.821 MiB)
2026-05-23 18:37:01.252 | 30.52.124.195 W slot update_slots: id  1 | task 19499 | erased invalidated context checkpoint (pos_min = 7289, pos_max = 7289, n_tokens = 7290, n_swa = 0, pos_next = 0, size = 164.893 MiB)
2026-05-23 18:37:01.262 | 30.52.134.142 W slot update_slots: id  1 | task 19499 | erased invalidated context checkpoint (pos_min = 8813, pos_max = 8813, n_tokens = 8814, n_swa = 0, pos_next = 0, size = 168.085 MiB)
2026-05-23 18:37:01.271 | 30.52.143.682 W slot update_slots: id  1 | task 19499 | erased invalidated context checkpoint (pos_min = 9325, pos_max = 9325, n_tokens = 9326, n_swa = 0, pos_next = 0, size = 169.157 MiB)
2026-05-23 18:37:01.281 | 30.52.153.422 W slot update_slots: id  1 | task 19499 | erased invalidated context checkpoint (pos_min = 14646, pos_max = 14646, n_tokens = 14647, n_swa = 0, pos_next = 0, size = 180.301 MiB)
2026-05-23 18:37:01.293 | 30.52.165.056 W slot update_slots: id  1 | task 19499 | erased invalidated context checkpoint (pos_min = 15158, pos_max = 15158, n_tokens = 15159, n_swa = 0, pos_next = 0, size = 181.373 MiB)
2026-05-23 18:37:01.305 | 30.52.177.188 W slot update_slots: id  1 | task 19499 | erased invalidated context checkpoint (pos_min = 19958, pos_max = 19958, n_tokens = 19959, n_swa = 0, pos_next = 0, size = 191.426 MiB)
2026-05-23 18:37:01.317 | 30.52.189.452 W slot update_slots: id  1 | task 19499 | erased invalidated context checkpoint (pos_min = 20470, pos_max = 20470, n_tokens = 20471, n_swa = 0, pos_next = 0, size = 192.498 MiB)
2026-05-23 18:37:01.330 | 30.52.202.098 W slot update_slots: id  1 | task 19499 | erased invalidated context checkpoint (pos_min = 21550, pos_max = 21550, n_tokens = 21551, n_swa = 0, pos_next = 0, size = 194.760 MiB)
2026-05-23 18:37:01.342 | 30.52.214.740 W slot update_slots: id  1 | task 19499 | erased invalidated context checkpoint (pos_min = 23244, pos_max = 23244, n_tokens = 23245, n_swa = 0, pos_next = 0, size = 198.307 MiB)
2026-05-23 18:37:01.355 | 30.52.227.682 W slot update_slots: id  1 | task 19499 | erased invalidated context checkpoint (pos_min = 23340, pos_max = 23340, n_tokens = 23341, n_swa = 0, pos_next = 0, size = 198.508 MiB)
2026-05-23 18:37:01.368 | 30.52.240.644 W slot update_slots: id  1 | task 19499 | erased invalidated context checkpoint (pos_min = 24398, pos_max = 24398, n_tokens = 24399, n_swa = 0, pos_next = 0, size = 200.724 MiB)
2026-05-23 18:37:01.381 | 30.52.253.622 W slot update_slots: id  1 | task 19499 | erased invalidated context checkpoint (pos_min = 24494, pos_max = 24494, n_tokens = 24495, n_swa = 0, pos_next = 0, size = 200.925 MiB)
2026-05-23 18:37:01.394 | 30.52.266.631 W slot update_slots: id  1 | task 19499 | erased invalidated context checkpoint (pos_min = 24809, pos_max = 24809, n_tokens = 24810, n_swa = 0, pos_next = 0, size = 201.585 MiB)
2026-05-23 18:37:04.598 | 30.55.470.436 I slot print_timing: id  1 | task 19499 | prompt processing, n_tokens =   8192, progress = 0.14, t =   3.36 s / 2441.18 tokens per second
2026-05-23 18:37:04.598 | 30.55.470.649 I slot update_slots: id  1 | task 19499 | 8192 tokens since last checkpoint at 0, creating new checkpoint during processing at position 10240
2026-05-23 18:37:04.730 | 30.55.602.415 I slot create_check: id  1 | task 19499 | created context checkpoint 1 of 32 (pos_min = 8191, pos_max = 8191, n_tokens = 8192, size = 166.782 MiB)
2026-05-23 18:37:05.059 | 30.55.931.836 I slot print_timing: id  1 | task 19499 | prompt processing, n_tokens =  10240, progress = 0.17, t =   4.32 s / 2372.03 tokens per second
2026-05-23 18:37:05.911 | 30.56.783.216 I slot print_timing: id  1 | task 19499 | prompt processing, n_tokens =  12288, progress = 0.21, t =   5.17 s / 2377.55 tokens per second
2026-05-23 18:37:06.782 | 30.57.653.993 I slot print_timing: id  1 | task 19499 | prompt processing, n_tokens =  14336, progress = 0.24, t =   6.04 s / 2373.85 tokens per second
2026-05-23 18:37:07.665 | 30.58.537.726 I slot print_timing: id  1 | task 19499 | prompt processing, n_tokens =  16384, progress = 0.28, t =   6.92 s / 2366.65 tokens per second
2026-05-23 18:37:07.665 | 30.58.537.938 I slot update_slots: id  1 | task 19499 | 8192 tokens since last checkpoint at 8192, creating new checkpoint during processing at position 18432
2026-05-23 18:37:07.803 | 30.58.675.185 I slot create_check: id  1 | task 19499 | created context checkpoint 2 of 32 (pos_min = 16383, pos_max = 16383, n_tokens = 16384, size = 183.939 MiB)
2026-05-23 18:37:08.700 | 30.59.572.210 I slot print_timing: id  1 | task 19499 | prompt processing, n_tokens =  18432, progress = 0.31, t =   7.96 s / 2316.35 tokens per second
2026-05-23 18:37:09.605 | 31.00.477.712 I slot print_timing: id  1 | task 19499 | prompt processing, n_tokens =  20480, progress = 0.35, t =   8.86 s / 2310.77 tokens per second
2026-05-23 18:37:09.983 | 31.00.855.374 I slot print_timing: id  1 | task 19499 | prompt processing, n_tokens =  22528, progress = 0.38, t =   9.78 s / 2302.38 tokens per second
2026-05-23 18:37:10.969 | 31.01.841.333 I slot print_timing: id  1 | task 19499 | prompt processing, n_tokens =  24576, progress = 0.42, t =  10.77 s / 2281.76 tokens per second
2026-05-23 18:37:10.969 | 31.01.841.658 I slot update_slots: id  1 | task 19499 | 8192 tokens since last checkpoint at 16384, creating new checkpoint during processing at position 26624
2026-05-23 18:37:11.188 | 31.02.060.681 I slot create_check: id  1 | task 19499 | created context checkpoint 3 of 32 (pos_min = 24575, pos_max = 24575, n_tokens = 24576, size = 201.095 MiB)
2026-05-23 18:37:12.151 | 31.03.023.694 I slot print_timing: id  1 | task 19499 | prompt processing, n_tokens =  26624, progress = 0.45, t =  11.95 s / 2227.39 tokens per second
2026-05-23 18:37:13.129 | 31.04.001.722 I slot print_timing: id  1 | task 19499 | prompt processing, n_tokens =  28672, progress = 0.49, t =  12.93 s / 2217.30 tokens per second
2026-05-23 18:37:14.130 | 31.05.002.005 I slot print_timing: id  1 | task 19499 | prompt processing, n_tokens =  30720, progress = 0.52, t =  13.93 s / 2205.11 tokens per second
2026-05-23 18:37:14.698 | 31.05.570.790 I slot print_timing: id  1 | task 19499 | prompt processing, n_tokens =  32768, progress = 0.56, t =  14.96 s / 2190.93 tokens per second
2026-05-23 18:37:14.699 | 31.05.571.021 I slot update_slots: id  1 | task 19499 | 8192 tokens since last checkpoint at 24576, creating new checkpoint during processing at position 34816
2026-05-23 18:37:14.947 | 31.05.819.851 I slot create_check: id  1 | task 19499 | created context checkpoint 4 of 32 (pos_min = 32767, pos_max = 32767, n_tokens = 32768, size = 218.251 MiB)
2026-05-23 18:37:15.993 | 31.06.865.089 I slot print_timing: id  1 | task 19499 | prompt processing, n_tokens =  34816, progress = 0.59, t =  16.25 s / 2142.45 tokens per second
2026-05-23 18:37:17.068 | 31.07.940.339 I slot print_timing: id  1 | task 19499 | prompt processing, n_tokens =  36864, progress = 0.62, t =  17.33 s / 2127.70 tokens per second
2026-05-23 18:37:18.167 | 31.09.039.746 I slot print_timing: id  1 | task 19499 | prompt processing, n_tokens =  38912, progress = 0.66, t =  18.43 s / 2111.89 tokens per second
2026-05-23 18:37:19.293 | 31.10.165.666 I slot print_timing: id  1 | task 19499 | prompt processing, n_tokens =  40960, progress = 0.69, t =  19.55 s / 2095.02 tokens per second
2026-05-23 18:37:19.293 | 31.10.165.866 I slot update_slots: id  1 | task 19499 | 8192 tokens since last checkpoint at 32768, creating new checkpoint during processing at position 43008
2026-05-23 18:37:19.578 | 31.10.450.438 I slot create_check: id  1 | task 19499 | created context checkpoint 5 of 32 (pos_min = 40959, pos_max = 40959, n_tokens = 40960, size = 235.407 MiB)
2026-05-23 18:37:20.228 | 31.11.100.197 I slot print_timing: id  1 | task 19499 | prompt processing, n_tokens =  43008, progress = 0.73, t =  20.99 s / 2049.27 tokens per second
2026-05-23 18:37:21.412 | 31.12.284.672 I slot print_timing: id  1 | task 19499 | prompt processing, n_tokens =  45056, progress = 0.76, t =  22.17 s / 2032.16 tokens per second
2026-05-23 18:37:22.624 | 31.13.496.822 I slot print_timing: id  1 | task 19499 | prompt processing, n_tokens =  47104, progress = 0.80, t =  23.38 s / 2014.40 tokens per second
2026-05-23 18:37:23.869 | 31.14.741.397 I slot print_timing: id  1 | task 19499 | prompt processing, n_tokens =  49152, progress = 0.83, t =  24.63 s / 1995.76 tokens per second
2026-05-23 18:37:23.869 | 31.14.741.624 I slot update_slots: id  1 | task 19499 | 8192 tokens since last checkpoint at 40960, creating new checkpoint during processing at position 51200
2026-05-23 18:37:24.187 | 31.15.059.088 I slot create_check: id  1 | task 19499 | created context checkpoint 6 of 32 (pos_min = 49151, pos_max = 49151, n_tokens = 49152, size = 252.564 MiB)
2026-05-23 18:37:24.957 | 31.15.828.974 I slot print_timing: id  1 | task 19499 | prompt processing, n_tokens =  51200, progress = 0.87, t =  26.22 s / 1952.97 tokens per second
2026-05-23 18:37:26.270 | 31.17.142.298 I slot print_timing: id  1 | task 19499 | prompt processing, n_tokens =  53248, progress = 0.90, t =  27.53 s / 1934.19 tokens per second
2026-05-23 18:37:27.606 | 31.18.478.828 I slot print_timing: id  1 | task 19499 | prompt processing, n_tokens =  55296, progress = 0.94, t =  28.87 s / 1915.59 tokens per second
2026-05-23 18:37:28.964 | 31.19.836.561 I slot print_timing: id  1 | task 19499 | prompt processing, n_tokens =  57344, progress = 0.97, t =  30.22 s / 1897.29 tokens per second
2026-05-23 18:37:28.964 | 31.19.836.756 I slot update_slots: id  1 | task 19499 | 8192 tokens since last checkpoint at 49152, creating new checkpoint during processing at position 58498
2026-05-23 18:37:29.295 | 31.20.167.881 I slot create_check: id  1 | task 19499 | created context checkpoint 7 of 32 (pos_min = 57343, pos_max = 57343, n_tokens = 57344, size = 269.720 MiB)
2026-05-23 18:37:29.592 | 31.20.464.081 I slot print_timing: id  1 | task 19499 | prompt processing, n_tokens =  58498, progress = 0.99, t =  31.35 s / 1865.75 tokens per second
2026-05-23 18:37:29.927 | 31.20.799.047 I slot create_check: id  1 | task 19499 | created context checkpoint 8 of 32 (pos_min = 58497, pos_max = 58497, n_tokens = 58498, size = 272.137 MiB)
2026-05-23 18:37:30.277 | 31.21.149.428 I slot print_timing: id  1 | task 19499 | prompt processing, n_tokens =  59010, progress = 1.00, t =  32.04 s / 1841.82 tokens per second
2026-05-23 18:37:30.629 | 31.21.501.209 I slot create_check: id  1 | task 19499 | created context checkpoint 9 of 32 (pos_min = 59009, pos_max = 59009, n_tokens = 59010, size = 273.209 MiB)
2026-05-23 18:37:32.259 | 31.23.131.025 I slot print_timing: id  1 | task 19499 | n_decoded =    102, tg =  64.23 t/s
2026-05-23 18:37:34.764 | 31.25.636.691 I slot print_timing: id  1 | task 19499 | n_decoded =    308, tg =  67.04 t/s
2026-05-23 18:37:37.517 | 31.28.389.793 I slot print_timing: id  1 | task 19499 | n_decoded =    533, tg =  70.07 t/s
2026-05-23 18:37:40.283 | 31.31.155.598 I slot print_timing: id  1 | task 19499 | n_decoded =    753, tg =  70.95 t/s
2026-05-23 18:37:43.297 | 31.34.169.050 I slot print_timing: id  1 | task 19499 | n_decoded =    961, tg =  70.52 t/s
2026-05-23 18:37:45.819 | 31.36.691.160 I slot print_timing: id  1 | task 19499 | n_decoded =   1180, tg =  70.87 t/s
2026-05-23 18:37:48.824 | 31.39.696.106 I slot print_timing: id  1 | task 19499 | n_decoded =   1419, tg =  72.20 t/s
2026-05-23 18:37:49.607 | 31.40.479.528 I slot print_timing: id  1 | task 19499 | 
2026-05-23 18:37:49.607 | prompt eval time =   32432.31 ms / 59014 tokens (    0.55 ms per token,  1819.61 tokens per second)
2026-05-23 18:37:49.607 |        eval time =   20438.04 ms /  1477 tokens (   13.84 ms per token,    72.27 tokens per second)
2026-05-23 18:37:49.607 |       total time =   52870.36 ms / 60491 tokens
2026-05-23 18:37:49.607 | draft acceptance rate = 0.78125 (  900 accepted /  1152 generated)
2026-05-23 18:37:49.607 | 31.40.479.590 I statistics draft-mtp: #calls(b,g,a) = 71 19785 24018, #gen drafts = 24018, #acc drafts = 21851, #gen tokens = 48036, #acc tokens = 41778, dur(b,g,a) = 0.115, 106493.392, 52.854 ms
2026-05-23 18:37:49.608 | 31.40.480.980 I slot      release: id  1 | task 19499 | stop processing: n_tokens = 60490, truncated = 0
2026-05-23 18:37:49.609 | 31.40.481.065 I srv  update_slots: all slots are idle
2026-05-23 18:37:49.771 | 31.40.642.951 I srv  params_from_: Chat format: peg-native
2026-05-23 18:37:49.772 | 31.40.644.355 I slot get_availabl: id  0 | task -1 | selected slot by LRU, t_last = 1898449513
2026-05-23 18:37:49.772 | 31.40.644.376 I srv  get_availabl: updating prompt cache
2026-05-23 18:37:49.772 | 31.40.644.379 I srv          load:  - looking for better prompt, base f_keep = -1.000, sim = 0.000
2026-05-23 18:37:49.772 | 31.40.644.417 I srv        update:  - cache state: 1 prompts, 12629.260 MiB (limits: 8192.000 MiB, 131072 tokens, 131072 est)
2026-05-23 18:37:49.772 | 31.40.644.418 I srv        update:    - prompt 0x63d3af1762d0:   99209 tokens, checkpoints: 29, 12629.260 MiB
2026-05-23 18:37:49.772 | 31.40.644.419 I srv  get_availabl: prompt cache update took 0.04 ms
2026-05-23 18:37:49.773 | 31.40.645.058 I reasoning-budget: activated, budget=2147483647 tokens
2026-05-23 18:37:49.773 | 31.40.645.330 I slot launch_slot_: id  0 | task 20107 | processing task, is_child = 0
2026-05-23 18:37:49.773 | 31.40.645.357 I slot slot_save_an: id  1 | task -1 | saving idle slot to prompt cache
2026-05-23 18:37:49.775 | 31.40.647.911 W srv   prompt_save:  - saving prompt with length 60490, total state size = 2285.920 MiB (draft: 126.682 MiB)
2026-05-23 18:37:54.277 | 31.45.149.327 I slot prompt_clear: id  1 | task -1 | clearing prompt with 60490 tokens
2026-05-23 18:37:54.287 | 31.45.159.917 W srv        update:  - cache size limit reached, removing oldest entry (size = 12629.260 MiB)
2026-05-23 18:37:54.568 | 31.45.440.351 I srv        update:  - cache state: 1 prompts, 4359.024 MiB (limits: 8192.000 MiB, 131072 tokens, 131072 est)
2026-05-23 18:37:54.568 | 31.45.440.373 I srv        update:    - prompt 0x63d3b432d280:   60490 tokens, checkpoints:  9,  4359.024 MiB
2026-05-23 18:37:54.568 | 31.45.440.676 W slot update_slots: id  0 | task 20107 | erased invalidated context checkpoint (pos_min = 6751, pos_max = 6751, n_tokens = 6752, n_swa = 0, pos_next = 0, size = 163.767 MiB)
2026-05-23 18:37:54.578 | 31.45.450.624 W slot update_slots: id  0 | task 20107 | erased invalidated context checkpoint (pos_min = 7263, pos_max = 7263, n_tokens = 7264, n_swa = 0, pos_next = 0, size = 164.839 MiB)
2026-05-23 18:37:54.588 | 31.45.460.587 W slot update_slots: id  0 | task 20107 | erased invalidated context checkpoint (pos_min = 10577, pos_max = 10577, n_tokens = 10578, n_swa = 0, pos_next = 0, size = 171.779 MiB)
2026-05-23 18:37:54.599 | 31.45.470.896 W slot update_slots: id  0 | task 20107 | erased invalidated context checkpoint (pos_min = 11089, pos_max = 11089, n_tokens = 11090, n_swa = 0, pos_next = 0, size = 172.852 MiB)
2026-05-23 18:37:54.609 | 31.45.481.088 W slot update_slots: id  0 | task 20107 | erased invalidated context checkpoint (pos_min = 11348, pos_max = 11348, n_tokens = 11349, n_swa = 0, pos_next = 0, size = 173.394 MiB)
2026-05-23 18:37:54.618 | 31.45.490.869 W slot update_slots: id  0 | task 20107 | erased invalidated context checkpoint (pos_min = 11860, pos_max = 11860, n_tokens = 11861, n_swa = 0, pos_next = 0, size = 174.466 MiB)
2026-05-23 18:37:54.629 | 31.45.501.265 W slot update_slots: id  0 | task 20107 | erased invalidated context checkpoint (pos_min = 15603, pos_max = 15603, n_tokens = 15604, n_swa = 0, pos_next = 0, size = 182.305 MiB)
2026-05-23 18:37:54.639 | 31.45.511.067 W slot update_slots: id  0 | task 20107 | erased invalidated context checkpoint (pos_min = 16115, pos_max = 16115, n_tokens = 16116, n_swa = 0, pos_next = 0, size = 183.377 MiB)
2026-05-23 18:37:54.651 | 31.45.523.038 W slot update_slots: id  0 | task 20107 | erased invalidated context checkpoint (pos_min = 19889, pos_max = 19889, n_tokens = 19890, n_swa = 0, pos_next = 0, size = 191.281 MiB)
2026-05-23 18:37:54.663 | 31.45.535.397 W slot update_slots: id  0 | task 20107 | erased invalidated context checkpoint (pos_min = 20401, pos_max = 20401, n_tokens = 20402, n_swa = 0, pos_next = 0, size = 192.353 MiB)
2026-05-23 18:37:54.675 | 31.45.547.918 W slot update_slots: id  0 | task 20107 | erased invalidated context checkpoint (pos_min = 23600, pos_max = 23600, n_tokens = 23601, n_swa = 0, pos_next = 0, size = 199.053 MiB)
2026-05-23 18:37:54.688 | 31.45.560.839 W slot update_slots: id  0 | task 20107 | erased invalidated context checkpoint (pos_min = 24112, pos_max = 24112, n_tokens = 24113, n_swa = 0, pos_next = 0, size = 200.125 MiB)
2026-05-23 18:37:54.701 | 31.45.573.817 W slot update_slots: id  0 | task 20107 | erased invalidated context checkpoint (pos_min = 28945, pos_max = 28945, n_tokens = 28946, n_swa = 0, pos_next = 0, size = 210.247 MiB)
2026-05-23 18:37:54.716 | 31.45.588.205 W slot update_slots: id  0 | task 20107 | erased invalidated context checkpoint (pos_min = 29052, pos_max = 29052, n_tokens = 29053, n_swa = 0, pos_next = 0, size = 210.471 MiB)
2026-05-23 18:37:54.730 | 31.45.601.902 W slot update_slots: id  0 | task 20107 | erased invalidated context checkpoint (pos_min = 30008, pos_max = 30008, n_tokens = 30009, n_swa = 0, pos_next = 0, size = 212.473 MiB)
2026-05-23 18:37:54.743 | 31.45.615.743 W slot update_slots: id  0 | task 20107 | erased invalidated context checkpoint (pos_min = 30095, pos_max = 30095, n_tokens = 30096, n_swa = 0, pos_next = 0, size = 212.655 MiB)
2026-05-23 18:37:54.757 | 31.45.629.499 W slot update_slots: id  0 | task 20107 | erased invalidated context checkpoint (pos_min = 31031, pos_max = 31031, n_tokens = 31032, n_swa = 0, pos_next = 0, size = 214.616 MiB)
2026-05-23 18:37:54.771 | 31.45.643.521 W slot update_slots: id  0 | task 20107 | erased invalidated context checkpoint (pos_min = 31118, pos_max = 31118, n_tokens = 31119, n_swa = 0, pos_next = 0, size = 214.798 MiB)
2026-05-23 18:37:54.785 | 31.45.657.428 W slot update_slots: id  0 | task 20107 | erased invalidated context checkpoint (pos_min = 31651, pos_max = 31651, n_tokens = 31652, n_swa = 0, pos_next = 0, size = 215.914 MiB)
2026-05-23 18:37:54.799 | 31.45.671.845 W slot update_slots: id  0 | task 20107 | erased invalidated context checkpoint (pos_min = 32163, pos_max = 32163, n_tokens = 32164, n_swa = 0, pos_next = 0, size = 216.986 MiB)
2026-05-23 18:37:54.813 | 31.45.685.898 W slot update_slots: id  0 | task 20107 | erased invalidated context checkpoint (pos_min = 32481, pos_max = 32481, n_tokens = 32482, n_swa = 0, pos_next = 0, size = 217.652 MiB)
2026-05-23 18:37:58.267 | 31.49.139.331 I slot print_timing: id  0 | task 20107 | prompt processing, n_tokens =   8192, progress = 0.41, t =   3.70 s / 2214.86 tokens per second
2026-05-23 18:37:58.267 | 31.49.139.557 I slot update_slots: id  0 | task 20107 | 8192 tokens since last checkpoint at 0, creating new checkpoint during processing at position 10240
2026-05-23 18:37:58.395 | 31.49.267.855 I slot create_check: id  0 | task 20107 | created context checkpoint 1 of 32 (pos_min = 8191, pos_max = 8191, n_tokens = 8192, size = 166.782 MiB)
2026-05-23 18:37:59.228 | 31.50.100.423 I slot print_timing: id  0 | task 20107 | prompt processing, n_tokens =  10240, progress = 0.52, t =   4.66 s / 2197.55 tokens per second
2026-05-23 18:37:59.585 | 31.50.457.090 I slot print_timing: id  0 | task 20107 | prompt processing, n_tokens =  12288, progress = 0.62, t =   5.51 s / 2230.04 tokens per second
2026-05-23 18:38:00.450 | 31.51.321.886 I slot print_timing: id  0 | task 20107 | prompt processing, n_tokens =  14336, progress = 0.72, t =   6.38 s / 2248.78 tokens per second
2026-05-23 18:38:01.330 | 31.52.202.481 I slot print_timing: id  0 | task 20107 | prompt processing, n_tokens =  16384, progress = 0.83, t =   7.26 s / 2258.12 tokens per second
2026-05-23 18:38:01.330 | 31.52.202.695 I slot update_slots: id  0 | task 20107 | 8192 tokens since last checkpoint at 8192, creating new checkpoint during processing at position 18432
2026-05-23 18:38:01.481 | 31.52.353.478 I slot create_check: id  0 | task 20107 | created context checkpoint 2 of 32 (pos_min = 16383, pos_max = 16383, n_tokens = 16384, size = 183.939 MiB)
2026-05-23 18:38:02.376 | 31.53.248.497 I slot print_timing: id  0 | task 20107 | prompt processing, n_tokens =  18432, progress = 0.93, t =   8.30 s / 2220.29 tokens per second
2026-05-23 18:38:02.793 | 31.53.665.151 I slot print_timing: id  0 | task 20107 | prompt processing, n_tokens =  19335, progress = 0.97, t =   8.72 s / 2217.76 tokens per second
2026-05-23 18:38:02.978 | 31.53.850.120 I slot create_check: id  0 | task 20107 | created context checkpoint 3 of 32 (pos_min = 19334, pos_max = 19334, n_tokens = 19335, size = 190.119 MiB)
2026-05-23 18:38:03.205 | 31.54.077.124 I slot print_timing: id  0 | task 20107 | prompt processing, n_tokens =  19847, progress = 1.00, t =   9.13 s / 2173.76 tokens per second
2026-05-23 18:38:03.573 | 31.54.445.504 I slot create_check: id  0 | task 20107 | created context checkpoint 4 of 32 (pos_min = 19846, pos_max = 19846, n_tokens = 19847, size = 191.191 MiB)
2026-05-23 18:38:04.383 | 31.55.255.073 I slot print_timing: id  0 | task 20107 | n_decoded =    100, tg =  79.65 t/s
2026-05-23 18:38:06.215 | 31.57.086.974 I reasoning-budget: deactivated (natural end)
2026-05-23 18:38:07.373 | 31.58.245.822 I slot print_timing: id  0 | task 20107 | n_decoded =    337, tg =  79.06 t/s
2026-05-23 18:38:07.673 | 31.58.544.970 I slot print_timing: id  0 | task 20107 | 
2026-05-23 18:38:07.673 | prompt eval time =    9536.89 ms / 19851 tokens (    0.48 ms per token,  2081.50 tokens per second)
2026-05-23 18:38:07.673 |        eval time =    4561.55 ms /   356 tokens (   12.81 ms per token,    78.04 tokens per second)
2026-05-23 18:38:07.673 |       total time =   14098.44 ms / 20207 tokens
2026-05-23 18:38:07.673 | draft acceptance rate = 0.68667 (  206 accepted /   300 generated)
2026-05-23 18:38:07.673 | 31.58.545.016 I statistics draft-mtp: #calls(b,g,a) = 72 19935 24168, #gen drafts = 24168, #acc drafts = 21967, #gen tokens = 48336, #acc tokens = 41984, dur(b,g,a) = 0.117, 107235.151, 53.300 ms
2026-05-23 18:38:07.673 | 31.58.545.706 I slot      release: id  0 | task 20107 | stop processing: n_tokens = 20207, truncated = 0
2026-05-23 18:38:07.673 | 31.58.545.800 I srv  update_slots: all slots are idle
2026-05-23 18:50:15.880 | 44.06.751.935 I srv  params_from_: Chat format: peg-native
2026-05-23 18:50:15.881 | 44.06.753.372 I slot get_availabl: id  0 | task -1 | selected slot by LCP similarity, sim_best = 0.937 (> 0.100 thold), f_keep = 0.982
2026-05-23 18:50:15.882 | 44.06.754.362 I reasoning-budget: activated, budget=2147483647 tokens
2026-05-23 18:50:15.882 | 44.06.754.554 I slot launch_slot_: id  0 | task 20270 | processing task, is_child = 0
2026-05-23 18:50:15.882 | 44.06.754.601 W slot update_slots: id  0 | task 20270 | n_past = 19849, slot.prompt.tokens.size() = 20207, seq_id = 0, pos_min = 20206, n_swa = 0
2026-05-23 18:50:15.882 | 44.06.754.602 I slot update_slots: id  0 | task 20270 | Checking checkpoint with [19846, 19846] against 19849...
2026-05-23 18:50:15.965 | 44.06.837.889 W slot update_slots: id  0 | task 20270 | restored context checkpoint (pos_min = 19846, pos_max = 19846, n_tokens = 19847, n_past = 19847, size = 191.191 MiB)
2026-05-23 18:50:16.191 | 44.07.062.937 I slot create_check: id  0 | task 20270 | created context checkpoint 5 of 32 (pos_min = 20657, pos_max = 20657, n_tokens = 20658, size = 192.890 MiB)
2026-05-23 18:50:16.634 | 44.07.506.659 I slot create_check: id  0 | task 20270 | created context checkpoint 6 of 32 (pos_min = 21169, pos_max = 21169, n_tokens = 21170, size = 193.962 MiB)
2026-05-23 18:50:17.868 | 44.08.740.235 I slot print_timing: id  0 | task 20270 | n_decoded =    100, tg =  83.62 t/s
2026-05-23 18:50:20.874 | 44.11.746.071 I slot print_timing: id  0 | task 20270 | n_decoded =    330, tg =  78.54 t/s
2026-05-23 18:50:21.205 | 44.12.077.492 I reasoning-budget: deactivated (natural end)
2026-05-23 18:50:23.375 | 44.14.247.606 I slot print_timing: id  0 | task 20270 | n_decoded =    581, tg =  80.65 t/s
2026-05-23 18:50:24.830 | 44.15.702.300 I slot print_timing: id  0 | task 20270 | 
2026-05-23 18:50:24.830 | prompt eval time =    1295.44 ms /  1327 tokens (    0.98 ms per token,  1024.36 tokens per second)
2026-05-23 18:50:24.830 |        eval time =    8658.81 ms /   707 tokens (   12.25 ms per token,    81.65 tokens per second)
2026-05-23 18:50:24.830 |       total time =    9954.25 ms /  2034 tokens
2026-05-23 18:50:24.830 | draft acceptance rate = 0.71306 (  415 accepted /   582 generated)
2026-05-23 18:50:24.830 | 44.15.702.333 I statistics draft-mtp: #calls(b,g,a) = 73 20226 24459, #gen drafts = 24459, #acc drafts = 22199, #gen tokens = 48918, #acc tokens = 42399, dur(b,g,a) = 0.119, 108562.577, 53.913 ms
2026-05-23 18:50:24.831 | 44.15.703.061 I slot      release: id  0 | task 20270 | stop processing: n_tokens = 21880, truncated = 0
2026-05-23 18:50:24.831 | 44.15.703.149 I srv  update_slots: all slots are idle
2026-05-23 18:50:25.033 | 44.15.905.561 I srv  params_from_: Chat format: peg-native
2026-05-23 18:50:25.035 | 44.15.907.037 I slot get_availabl: id  0 | task -1 | selected slot by LCP similarity, sim_best = 0.906 (> 0.100 thold), f_keep = 1.000
2026-05-23 18:50:25.035 | 44.15.907.828 I reasoning-budget: activated, budget=2147483647 tokens
2026-05-23 18:50:25.035 | 44.15.907.951 I slot launch_slot_: id  0 | task 20565 | processing task, is_child = 0
2026-05-23 18:50:26.093 | 44.16.965.898 I slot create_check: id  0 | task 20565 | created context checkpoint 7 of 32 (pos_min = 23646, pos_max = 23646, n_tokens = 23647, size = 199.149 MiB)
2026-05-23 18:50:26.054 | 44.16.926.843 I slot create_check: id  0 | task 20565 | created context checkpoint 8 of 32 (pos_min = 24158, pos_max = 24158, n_tokens = 24159, size = 200.222 MiB)
2026-05-23 18:50:27.424 | 44.18.295.900 I slot print_timing: id  0 | task 20565 | n_decoded =    100, tg =  75.34 t/s
2026-05-23 18:50:30.429 | 44.21.300.939 I slot print_timing: id  0 | task 20565 | n_decoded =    337, tg =  77.79 t/s
2026-05-23 18:50:31.396 | 44.22.268.569 I reasoning-budget: deactivated (natural end)
2026-05-23 18:50:32.933 | 44.23.805.262 I slot print_timing: id  0 | task 20565 | n_decoded =    596, tg =  81.22 t/s
2026-05-23 18:50:35.631 | 44.26.503.822 I slot print_timing: id  0 | task 20565 | 
2026-05-23 18:50:35.631 | prompt eval time =    1555.88 ms /  2283 tokens (    0.68 ms per token,  1467.34 tokens per second)
2026-05-23 18:50:35.631 |        eval time =   10037.05 ms /   845 tokens (   11.88 ms per token,    84.19 tokens per second)
2026-05-23 18:50:35.631 |       total time =   11592.93 ms /  3128 tokens
2026-05-23 18:50:35.631 | draft acceptance rate = 0.77492 (  513 accepted /   662 generated)
2026-05-23 18:50:35.632 | 44.26.503.858 I statistics draft-mtp: #calls(b,g,a) = 74 20557 24790, #gen drafts = 24790, #acc drafts = 22476, #gen tokens = 49580, #acc tokens = 42912, dur(b,g,a) = 0.121, 110075.952, 54.671 ms
2026-05-23 18:50:35.632 | 44.26.504.620 I slot      release: id  0 | task 20565 | stop processing: n_tokens = 25007, truncated = 0
2026-05-23 18:50:35.632 | 44.26.504.688 I srv  update_slots: all slots are idle
2026-05-23 18:50:35.835 | 44.26.706.977 I srv  params_from_: Chat format: peg-native
2026-05-23 18:50:35.836 | 44.26.708.370 I slot get_availabl: id  0 | task -1 | selected slot by LCP similarity, sim_best = 0.956 (> 0.100 thold), f_keep = 1.000
2026-05-23 18:50:35.837 | 44.26.709.205 I reasoning-budget: activated, budget=2147483647 tokens
2026-05-23 18:50:35.837 | 44.26.709.305 I slot launch_slot_: id  0 | task 20900 | processing task, is_child = 0
2026-05-23 18:50:36.408 | 44.27.280.770 I slot create_check: id  0 | task 20900 | created context checkpoint 9 of 32 (pos_min = 25650, pos_max = 25650, n_tokens = 25651, size = 203.346 MiB)
2026-05-23 18:50:36.390 | 44.27.262.471 I slot create_check: id  0 | task 20900 | created context checkpoint 10 of 32 (pos_min = 26162, pos_max = 26162, n_tokens = 26163, size = 204.419 MiB)
2026-05-23 18:50:37.637 | 44.28.509.389 I slot print_timing: id  0 | task 20900 | n_decoded =    101, tg =  83.58 t/s
2026-05-23 18:50:40.648 | 44.31.519.905 I slot print_timing: id  0 | task 20900 | n_decoded =    302, tg =  71.58 t/s
2026-05-23 18:50:41.017 | 44.31.889.277 I reasoning-budget: deactivated (natural end)
2026-05-23 18:50:43.148 | 44.34.020.143 I slot print_timing: id  0 | task 20900 | n_decoded =    555, tg =  76.87 t/s
2026-05-23 18:50:43.209 | 44.34.081.809 I slot print_timing: id  0 | task 20900 | 
2026-05-23 18:50:43.209 | prompt eval time =    1092.04 ms /  1160 tokens (    0.94 ms per token,  1062.23 tokens per second)
2026-05-23 18:50:43.209 |        eval time =    7281.79 ms /   560 tokens (   13.00 ms per token,    76.90 tokens per second)
2026-05-23 18:50:43.209 |       total time =    8373.84 ms /  1720 tokens
2026-05-23 18:50:43.209 | draft acceptance rate = 0.66946 (  320 accepted /   478 generated)
2026-05-23 18:50:43.209 | 44.34.081.849 I statistics draft-mtp: #calls(b,g,a) = 75 20796 25029, #gen drafts = 25029, #acc drafts = 22659, #gen tokens = 50058, #acc tokens = 43232, dur(b,g,a) = 0.122, 111181.443, 55.178 ms
2026-05-23 18:50:43.210 | 44.34.082.736 I slot      release: id  0 | task 20900 | stop processing: n_tokens = 26726, truncated = 0
2026-05-23 18:50:43.210 | 44.34.082.813 I srv  update_slots: all slots are idle
2026-05-23 18:50:43.385 | 44.34.257.300 I srv  params_from_: Chat format: peg-native
2026-05-23 18:50:43.386 | 44.34.258.721 I slot get_availabl: id  0 | task -1 | selected slot by LCP similarity, sim_best = 0.991 (> 0.100 thold), f_keep = 1.000
2026-05-23 18:50:43.387 | 44.34.259.728 I reasoning-budget: activated, budget=2147483647 tokens
2026-05-23 18:50:43.387 | 44.34.259.841 I slot launch_slot_: id  0 | task 21143 | processing task, is_child = 0
2026-05-23 18:50:43.640 | 44.34.512.292 I slot create_check: id  0 | task 21143 | created context checkpoint 11 of 32 (pos_min = 26725, pos_max = 26725, n_tokens = 26726, size = 205.598 MiB)
2026-05-23 18:50:44.025 | 44.34.897.171 I slot create_check: id  0 | task 21143 | created context checkpoint 12 of 32 (pos_min = 26973, pos_max = 26973, n_tokens = 26974, size = 206.117 MiB)
2026-05-23 18:50:46.156 | 44.37.028.133 I slot print_timing: id  0 | task 21143 | n_decoded =    169, tg =  80.86 t/s
2026-05-23 18:50:48.450 | 44.39.322.857 I slot print_timing: id  0 | task 21143 | n_decoded =    364, tg =  71.19 t/s
2026-05-23 18:50:49.372 | 44.40.244.058 I reasoning-budget: deactivated (natural end)
2026-05-23 18:50:50.983 | 44.41.855.774 I slot print_timing: id  0 | task 21143 | 
2026-05-23 18:50:50.983 | prompt eval time =     678.14 ms /   252 tokens (    2.69 ms per token,   371.60 tokens per second)
2026-05-23 18:50:50.983 |        eval time =    7917.87 ms /   600 tokens (   13.20 ms per token,    75.78 tokens per second)
2026-05-23 18:50:50.984 |       total time =    8596.01 ms /   852 tokens
2026-05-23 18:50:50.984 | draft acceptance rate = 0.65385 (  340 accepted /   520 generated)
2026-05-23 18:50:50.984 | 44.41.855.815 I statistics draft-mtp: #calls(b,g,a) = 76 21056 25289, #gen drafts = 25289, #acc drafts = 22855, #gen tokens = 50578, #acc tokens = 43572, dur(b,g,a) = 0.123, 112378.963, 55.716 ms
2026-05-23 18:50:50.984 | 44.41.856.719 I slot      release: id  0 | task 21143 | stop processing: n_tokens = 27578, truncated = 0
2026-05-23 18:50:50.984 | 44.41.856.810 I srv  update_slots: all slots are idle
2026-05-23 18:50:51.172 | 44.42.044.356 I srv  params_from_: Chat format: peg-native
2026-05-23 18:50:51.173 | 44.42.045.827 I slot get_availabl: id  0 | task -1 | selected slot by LCP similarity, sim_best = 0.999 (> 0.100 thold), f_keep = 1.000
2026-05-23 18:50:51.174 | 44.42.046.787 I reasoning-budget: activated, budget=2147483647 tokens
2026-05-23 18:50:51.174 | 44.42.046.916 I slot launch_slot_: id  0 | task 21406 | processing task, is_child = 0
2026-05-23 18:50:51.417 | 44.42.289.226 I slot create_check: id  0 | task 21406 | created context checkpoint 13 of 32 (pos_min = 27577, pos_max = 27577, n_tokens = 27578, size = 207.382 MiB)
2026-05-23 18:50:52.928 | 44.43.800.422 I slot print_timing: id  0 | task 21406 | n_decoded =    100, tg =  70.34 t/s
2026-05-23 18:50:55.908 | 44.46.780.485 I reasoning-budget: deactivated (natural end)
2026-05-23 18:50:55.943 | 44.46.815.044 I slot print_timing: id  0 | task 21406 | n_decoded =    319, tg =  71.91 t/s
2026-05-23 18:50:58.444 | 44.49.316.548 I slot print_timing: id  0 | task 21406 | n_decoded =    566, tg =  76.02 t/s
2026-05-23 18:51:00.403 | 44.51.275.053 I slot print_timing: id  0 | task 21406 | 
2026-05-23 18:51:00.403 | prompt eval time =     331.64 ms /    39 tokens (    8.50 ms per token,   117.60 tokens per second)
2026-05-23 18:51:00.403 |        eval time =    9403.90 ms /   703 tokens (   13.38 ms per token,    74.76 tokens per second)
2026-05-23 18:51:00.403 |       total time =    9735.54 ms /   742 tokens
2026-05-23 18:51:00.403 | draft acceptance rate = 0.64706 (  396 accepted /   612 generated)
2026-05-23 18:51:00.403 | 44.51.275.090 I statistics draft-mtp: #calls(b,g,a) = 77 21362 25595, #gen drafts = 25595, #acc drafts = 23082, #gen tokens = 51190, #acc tokens = 43968, dur(b,g,a) = 0.124, 113821.124, 56.360 ms
2026-05-23 18:51:00.404 | 44.51.275.996 I slot      release: id  0 | task 21406 | stop processing: n_tokens = 28319, truncated = 0
2026-05-23 18:51:00.404 | 44.51.276.094 I srv  update_slots: all slots are idle
2026-05-23 18:55:05.968 | 48.56.840.408 I srv  params_from_: Chat format: peg-native
2026-05-23 18:55:05.969 | 48.56.841.789 I slot get_availabl: id  0 | task -1 | selected slot by LCP similarity, sim_best = 0.794 (> 0.100 thold), f_keep = 0.737
2026-05-23 18:55:05.970 | 48.56.842.783 I reasoning-budget: activated, budget=2147483647 tokens
2026-05-23 18:55:05.970 | 48.56.842.915 I slot launch_slot_: id  0 | task 21715 | processing task, is_child = 0
2026-05-23 18:55:05.970 | 48.56.842.961 W slot update_slots: id  0 | task 21715 | n_past = 20859, slot.prompt.tokens.size() = 28319, seq_id = 0, pos_min = 28318, n_swa = 0
2026-05-23 18:55:05.970 | 48.56.842.966 I slot update_slots: id  0 | task 21715 | Checking checkpoint with [27577, 27577] against 20859...
2026-05-23 18:55:05.970 | 48.56.842.966 I slot update_slots: id  0 | task 21715 | Checking checkpoint with [26973, 26973] against 20859...
2026-05-23 18:55:05.970 | 48.56.842.967 I slot update_slots: id  0 | task 21715 | Checking checkpoint with [26725, 26725] against 20859...
2026-05-23 18:55:05.971 | 48.56.842.968 I slot update_slots: id  0 | task 21715 | Checking checkpoint with [26162, 26162] against 20859...
2026-05-23 18:55:05.971 | 48.56.842.969 I slot update_slots: id  0 | task 21715 | Checking checkpoint with [25650, 25650] against 20859...
2026-05-23 18:55:05.971 | 48.56.842.970 I slot update_slots: id  0 | task 21715 | Checking checkpoint with [24158, 24158] against 20859...
2026-05-23 18:55:05.971 | 48.56.842.971 I slot update_slots: id  0 | task 21715 | Checking checkpoint with [23646, 23646] against 20859...
2026-05-23 18:55:05.971 | 48.56.842.972 I slot update_slots: id  0 | task 21715 | Checking checkpoint with [21169, 21169] against 20859...
2026-05-23 18:55:05.971 | 48.56.842.973 I slot update_slots: id  0 | task 21715 | Checking checkpoint with [20657, 20657] against 20859...
2026-05-23 18:55:06.056 | 48.56.928.543 W slot update_slots: id  0 | task 21715 | restored context checkpoint (pos_min = 20657, pos_max = 20657, n_tokens = 20658, n_past = 20658, size = 192.890 MiB)
2026-05-23 18:55:06.056 | 48.56.928.572 W slot update_slots: id  0 | task 21715 | erased invalidated context checkpoint (pos_min = 21169, pos_max = 21169, n_tokens = 21170, n_swa = 0, pos_next = 20658, size = 193.962 MiB)
2026-05-23 18:55:06.070 | 48.56.941.948 W slot update_slots: id  0 | task 21715 | erased invalidated context checkpoint (pos_min = 23646, pos_max = 23646, n_tokens = 23647, n_swa = 0, pos_next = 20658, size = 199.149 MiB)
2026-05-23 18:55:06.082 | 48.56.954.661 W slot update_slots: id  0 | task 21715 | erased invalidated context checkpoint (pos_min = 24158, pos_max = 24158, n_tokens = 24159, n_swa = 0, pos_next = 20658, size = 200.222 MiB)
2026-05-23 18:55:06.098 | 48.56.969.956 W slot update_slots: id  0 | task 21715 | erased invalidated context checkpoint (pos_min = 25650, pos_max = 25650, n_tokens = 25651, n_swa = 0, pos_next = 20658, size = 203.346 MiB)
2026-05-23 18:55:06.110 | 48.56.982.894 W slot update_slots: id  0 | task 21715 | erased invalidated context checkpoint (pos_min = 26162, pos_max = 26162, n_tokens = 26163, n_swa = 0, pos_next = 20658, size = 204.419 MiB)
2026-05-23 18:55:06.124 | 48.56.996.104 W slot update_slots: id  0 | task 21715 | erased invalidated context checkpoint (pos_min = 26725, pos_max = 26725, n_tokens = 26726, n_swa = 0, pos_next = 20658, size = 205.598 MiB)
2026-05-23 18:55:06.137 | 48.57.009.173 W slot update_slots: id  0 | task 21715 | erased invalidated context checkpoint (pos_min = 26973, pos_max = 26973, n_tokens = 26974, n_swa = 0, pos_next = 20658, size = 206.117 MiB)
2026-05-23 18:55:06.150 | 48.57.022.420 W slot update_slots: id  0 | task 21715 | erased invalidated context checkpoint (pos_min = 27577, pos_max = 27577, n_tokens = 27578, n_swa = 0, pos_next = 20658, size = 207.382 MiB)
2026-05-23 18:55:08.286 | 48.59.158.439 I slot create_check: id  0 | task 21715 | created context checkpoint 6 of 32 (pos_min = 25744, pos_max = 25744, n_tokens = 25745, size = 203.543 MiB)
2026-05-23 18:55:08.522 | 48.59.394.283 I slot print_timing: id  0 | task 21715 | prompt processing, n_tokens =   5599, progress = 1.00, t =   3.05 s / 1835.08 tokens per second
2026-05-23 18:55:08.783 | 48.59.655.590 I slot create_check: id  0 | task 21715 | created context checkpoint 7 of 32 (pos_min = 26256, pos_max = 26256, n_tokens = 26257, size = 204.615 MiB)
2026-05-23 18:55:09.938 | 49.00.810.014 I reasoning-budget: deactivated (natural end)
2026-05-23 18:55:10.064 | 49.00.936.093 I slot print_timing: id  0 | task 21715 | n_decoded =    101, tg =  81.48 t/s
2026-05-23 18:55:12.571 | 49.03.443.864 I slot print_timing: id  0 | task 21715 | n_decoded =    374, tg =  88.03 t/s
2026-05-23 18:55:15.599 | 49.06.471.799 I slot print_timing: id  0 | task 21715 | n_decoded =    656, tg =  90.15 t/s
2026-05-23 18:55:16.095 | 49.06.967.050 I slot print_timing: id  0 | task 21715 | 
2026-05-23 18:55:16.095 | prompt eval time =    3353.20 ms /  5603 tokens (    0.60 ms per token,  1670.94 tokens per second)
2026-05-23 18:55:16.095 |        eval time =    7771.65 ms /   698 tokens (   11.13 ms per token,    89.81 tokens per second)
2026-05-23 18:55:16.095 |       total time =   11124.85 ms /  6301 tokens
2026-05-23 18:55:16.095 | draft acceptance rate = 0.89044 (  447 accepted /   502 generated)
2026-05-23 18:55:16.095 | 49.06.967.090 I statistics draft-mtp: #calls(b,g,a) = 78 21613 25846, #gen drafts = 25846, #acc drafts = 23317, #gen tokens = 51692, #acc tokens = 44415, dur(b,g,a) = 0.140, 114963.754, 56.924 ms
2026-05-23 18:55:16.096 | 49.06.968.159 I slot      release: id  0 | task 21715 | stop processing: n_tokens = 26959, truncated = 0
2026-05-23 18:55:16.096 | 49.06.968.269 I srv  update_slots: all slots are idle
2026-05-23 18:55:16.286 | 49.07.158.015 I srv  params_from_: Chat format: peg-native
2026-05-23 18:55:16.287 | 49.07.159.398 I slot get_availabl: id  0 | task -1 | selected slot by LCP similarity, sim_best = 0.948 (> 0.100 thold), f_keep = 1.000
2026-05-23 18:55:16.288 | 49.07.160.242 I reasoning-budget: activated, budget=2147483647 tokens
2026-05-23 18:55:16.288 | 49.07.160.355 I slot launch_slot_: id  0 | task 21972 | processing task, is_child = 0
2026-05-23 18:55:16.476 | 49.07.348.409 I slot create_check: id  0 | task 21972 | created context checkpoint 8 of 32 (pos_min = 27907, pos_max = 27907, n_tokens = 27908, size = 208.073 MiB)
2026-05-23 18:55:16.972 | 49.07.844.200 I slot create_check: id  0 | task 21972 | created context checkpoint 9 of 32 (pos_min = 28419, pos_max = 28419, n_tokens = 28420, size = 209.145 MiB)
2026-05-23 18:55:18.192 | 49.09.064.410 I slot print_timing: id  0 | task 21972 | n_decoded =    101, tg =  85.37 t/s
2026-05-23 18:55:21.194 | 49.12.066.361 I slot print_timing: id  0 | task 21972 | n_decoded =    334, tg =  79.81 t/s
2026-05-23 18:55:22.243 | 49.13.115.191 I reasoning-budget: deactivated (natural end)
2026-05-23 18:55:23.702 | 49.14.573.985 I slot print_timing: id  0 | task 21972 | 
2026-05-23 18:55:23.702 | prompt eval time =    1227.38 ms /  1465 tokens (    0.84 ms per token,  1193.60 tokens per second)
2026-05-23 18:55:23.705 |        eval time =    7186.78 ms /   570 tokens (   12.61 ms per token,    79.31 tokens per second)
2026-05-23 18:55:23.705 |       total time =    8414.16 ms /  2035 tokens
2026-05-23 18:55:23.705 | draft acceptance rate = 0.72103 (  336 accepted /   466 generated)
2026-05-23 18:55:23.705 | 49.14.574.018 I statistics draft-mtp: #calls(b,g,a) = 79 21846 26079, #gen drafts = 26079, #acc drafts = 23501, #gen tokens = 52158, #acc tokens = 44751, dur(b,g,a) = 0.141, 116047.558, 57.422 ms
2026-05-23 18:55:23.705 | 49.14.574.871 I slot      release: id  0 | task 21972 | stop processing: n_tokens = 28993, truncated = 0
2026-05-23 18:55:23.705 | 49.14.574.942 I slot print_timing: id  0 | task -1 | n_decoded =    570, tg =  79.30 t/s
2026-05-23 18:55:23.705 | 49.14.574.946 I srv  update_slots: all slots are idle
2026-05-23 18:55:23.917 | 49.14.789.314 I srv  params_from_: Chat format: peg-native
2026-05-23 18:55:23.918 | 49.14.790.744 I slot get_availabl: id  0 | task -1 | selected slot by LCP similarity, sim_best = 0.997 (> 0.100 thold), f_keep = 1.000
2026-05-23 18:55:23.919 | 49.14.791.538 I reasoning-budget: activated, budget=2147483647 tokens
2026-05-23 18:55:23.919 | 49.14.791.651 I slot launch_slot_: id  0 | task 22209 | processing task, is_child = 0
2026-05-23 18:55:24.176 | 49.15.048.514 I slot create_check: id  0 | task 22209 | created context checkpoint 10 of 32 (pos_min = 28992, pos_max = 28992, n_tokens = 28993, size = 210.345 MiB)
2026-05-23 18:55:24.504 | 49.15.376.243 I slot create_check: id  0 | task 22209 | created context checkpoint 11 of 32 (pos_min = 29088, pos_max = 29088, n_tokens = 29089, size = 210.546 MiB)
2026-05-23 18:55:26.709 | 49.17.581.310 I slot print_timing: id  0 | task 22209 | n_decoded =    176, tg =  81.22 t/s
2026-05-23 18:55:27.156 | 49.18.027.935 I reasoning-budget: deactivated (natural end)
2026-05-23 18:55:28.055 | 49.18.927.873 I slot print_timing: id  0 | task 22209 | 
2026-05-23 18:55:28.055 | prompt eval time =     622.52 ms /   100 tokens (    6.23 ms per token,   160.64 tokens per second)
2026-05-23 18:55:28.055 |        eval time =    4013.15 ms /   319 tokens (   12.58 ms per token,    79.49 tokens per second)
2026-05-23 18:55:28.055 |       total time =    4635.67 ms /   419 tokens
2026-05-23 18:55:28.056 | draft acceptance rate = 0.73643 (  190 accepted /   258 generated)
2026-05-23 18:55:28.056 | 49.18.927.910 I statistics draft-mtp: #calls(b,g,a) = 80 21975 26208, #gen drafts = 26208, #acc drafts = 23606, #gen tokens = 52416, #acc tokens = 44941, dur(b,g,a) = 0.143, 116647.537, 57.711 ms
2026-05-23 18:55:28.056 | 49.18.928.861 I slot      release: id  0 | task 22209 | stop processing: n_tokens = 29412, truncated = 0
2026-05-23 18:55:28.056 | 49.18.928.947 I srv  update_slots: all slots are idle
2026-05-23 18:55:28.249 | 49.19.121.870 I srv  params_from_: Chat format: peg-native
2026-05-23 18:55:28.251 | 49.19.123.273 I slot get_availabl: id  0 | task -1 | selected slot by LCP similarity, sim_best = 0.999 (> 0.100 thold), f_keep = 1.000
2026-05-23 18:55:28.252 | 49.19.124.064 I reasoning-budget: activated, budget=2147483647 tokens
2026-05-23 18:55:28.252 | 49.19.124.178 I slot launch_slot_: id  0 | task 22341 | processing task, is_child = 0
2026-05-23 18:55:28.508 | 49.19.380.695 I slot create_check: id  0 | task 22341 | created context checkpoint 12 of 32 (pos_min = 29411, pos_max = 29411, n_tokens = 29412, size = 211.223 MiB)
2026-05-23 18:55:29.938 | 49.20.810.220 I slot print_timing: id  0 | task 22341 | n_decoded =    100, tg =  74.66 t/s
2026-05-23 18:55:32.443 | 49.23.314.989 I slot print_timing: id  0 | task 22341 | n_decoded =    325, tg =  74.78 t/s
2026-05-23 18:55:32.836 | 49.23.708.820 I reasoning-budget: deactivated (natural end)
2026-05-23 18:55:34.370 | 49.25.242.580 I slot print_timing: id  0 | task 22341 | 
2026-05-23 18:55:34.370 | prompt eval time =     346.42 ms /    37 tokens (    9.36 ms per token,   106.81 tokens per second)
2026-05-23 18:55:34.370 |        eval time =    6273.71 ms /   484 tokens (   12.96 ms per token,    77.15 tokens per second)
2026-05-23 18:55:34.370 |       total time =    6620.13 ms /   521 tokens
2026-05-23 18:55:34.370 | draft acceptance rate = 0.69802 (  282 accepted /   404 generated)
2026-05-23 18:55:34.370 | 49.25.242.615 I statistics draft-mtp: #calls(b,g,a) = 81 22177 26410, #gen drafts = 26410, #acc drafts = 23762, #gen tokens = 52820, #acc tokens = 45223, dur(b,g,a) = 0.144, 117581.190, 58.134 ms
2026-05-23 18:55:34.371 | 49.25.243.526 I slot      release: id  0 | task 22341 | stop processing: n_tokens = 29933, truncated = 0
2026-05-23 18:55:34.371 | 49.25.243.596 I srv  update_slots: all slots are idle
2026-05-23 18:55:34.539 | 49.25.411.246 I srv  params_from_: Chat format: peg-native
2026-05-23 18:55:34.540 | 49.25.412.667 I slot get_availabl: id  0 | task -1 | selected slot by LCP similarity, sim_best = 0.996 (> 0.100 thold), f_keep = 1.000
2026-05-23 18:55:34.541 | 49.25.413.440 I reasoning-budget: activated, budget=2147483647 tokens
2026-05-23 18:55:34.541 | 49.25.413.551 I slot launch_slot_: id  0 | task 22546 | processing task, is_child = 0
2026-05-23 18:55:34.800 | 49.25.672.824 I slot create_check: id  0 | task 22546 | created context checkpoint 13 of 32 (pos_min = 29932, pos_max = 29932, n_tokens = 29933, size = 212.314 MiB)
2026-05-23 18:55:35.148 | 49.26.020.027 I slot create_check: id  0 | task 22546 | created context checkpoint 14 of 32 (pos_min = 30057, pos_max = 30057, n_tokens = 30058, size = 212.576 MiB)
2026-05-23 18:55:36.387 | 49.27.259.796 I slot print_timing: id  0 | task 22546 | n_decoded =    102, tg =  84.92 t/s
2026-05-23 18:55:37.577 | 49.28.449.705 I reasoning-budget: deactivated (natural end)
2026-05-23 18:55:38.895 | 49.29.767.894 I slot print_timing: id  0 | task 22546 | n_decoded =    346, tg =  82.06 t/s
2026-05-23 18:55:41.904 | 49.32.776.173 I slot print_timing: id  0 | task 22546 | n_decoded =    617, tg =  85.40 t/s
2026-05-23 18:55:44.425 | 49.35.297.764 I slot print_timing: id  0 | task 22546 | n_decoded =    899, tg =  87.79 t/s
2026-05-23 18:55:46.942 | 49.37.814.689 I slot print_timing: id  0 | task 22546 | n_decoded =   1156, tg =  87.20 t/s
2026-05-23 18:55:49.162 | 49.40.033.912 I slot print_timing: id  0 | task 22546 | 
2026-05-23 18:55:49.162 | prompt eval time =     644.84 ms /   129 tokens (    5.00 ms per token,   200.05 tokens per second)
2026-05-23 18:55:49.162 |        eval time =   15671.98 ms /  1345 tokens (   11.65 ms per token,    85.82 tokens per second)
2026-05-23 18:55:49.162 |       total time =   16316.83 ms /  1474 tokens
2026-05-23 18:55:49.162 | draft acceptance rate = 0.85585 (  849 accepted /   992 generated)
2026-05-23 18:55:49.162 | 49.40.033.960 I statistics draft-mtp: #calls(b,g,a) = 82 22673 26906, #gen drafts = 26906, #acc drafts = 24207, #gen tokens = 53812, #acc tokens = 46072, dur(b,g,a) = 0.145, 119855.901, 59.163 ms
2026-05-23 18:55:49.163 | 49.40.035.290 I slot      release: id  0 | task 22546 | stop processing: n_tokens = 31407, truncated = 0
2026-05-23 18:55:49.163 | 49.40.035.428 I srv  update_slots: all slots are idle
2026-05-23 18:55:49.375 | 49.40.247.765 I srv  params_from_: Chat format: peg-native
2026-05-23 18:55:49.377 | 49.40.249.127 I slot get_availabl: id  0 | task -1 | selected slot by LCP similarity, sim_best = 0.999 (> 0.100 thold), f_keep = 1.000
2026-05-23 18:55:49.377 | 49.40.249.952 I reasoning-budget: activated, budget=2147483647 tokens
2026-05-23 18:55:49.378 | 49.40.250.090 I slot launch_slot_: id  0 | task 23045 | processing task, is_child = 0
2026-05-23 18:55:49.643 | 49.40.515.001 I slot create_check: id  0 | task 23045 | created context checkpoint 15 of 32 (pos_min = 31406, pos_max = 31406, n_tokens = 31407, size = 215.401 MiB)
2026-05-23 18:55:49.997 | 49.40.869.017 I reasoning-budget: deactivated (natural end)
2026-05-23 18:55:50.955 | 49.41.827.034 I slot print_timing: id  0 | task 23045 | n_decoded =    100, tg =  81.55 t/s
2026-05-23 18:55:53.654 | 49.44.526.578 I slot print_timing: id  0 | task 23045 | n_decoded =    362, tg =  85.53 t/s
2026-05-23 18:55:56.662 | 49.47.534.321 I slot print_timing: id  0 | task 23045 | n_decoded =    626, tg =  86.46 t/s
2026-05-23 18:55:59.171 | 49.50.043.419 I slot print_timing: id  0 | task 23045 | n_decoded =    906, tg =  88.39 t/s
2026-05-23 18:56:01.676 | 49.52.547.883 I slot print_timing: id  0 | task 23045 | n_decoded =   1167, tg =  88.04 t/s
2026-05-23 18:56:04.703 | 49.55.575.469 I slot print_timing: id  0 | task 23045 | n_decoded =   1447, tg =  88.87 t/s
2026-05-23 18:56:07.204 | 49.58.075.990 I slot print_timing: id  0 | task 23045 | n_decoded =   1717, tg =  89.03 t/s
2026-05-23 18:56:10.225 | 50.01.097.451 I slot print_timing: id  0 | task 23045 | n_decoded =   1983, tg =  88.90 t/s
2026-05-23 18:56:12.728 | 50.03.600.071 I slot print_timing: id  0 | task 23045 | 
2026-05-23 18:56:12.728 | prompt eval time =     350.46 ms /    20 tokens (   17.52 ms per token,    57.07 tokens per second)
2026-05-23 18:56:12.728 |        eval time =   25317.14 ms /  2233 tokens (   11.34 ms per token,    88.20 tokens per second)
2026-05-23 18:56:12.728 |       total time =   25667.60 ms /  2253 tokens
2026-05-23 18:56:12.728 | draft acceptance rate = 0.90377 ( 1437 accepted /  1590 generated)
2026-05-23 18:56:12.728 | 50.03.600.107 I statistics draft-mtp: #calls(b,g,a) = 83 23468 27701, #gen drafts = 27701, #acc drafts = 24956, #gen tokens = 55402, #acc tokens = 47509, dur(b,g,a) = 0.146, 123499.041, 60.779 ms
2026-05-23 18:56:12.728 | 50.03.601.027 I slot      release: id  0 | task 23045 | stop processing: n_tokens = 33659, truncated = 0
2026-05-23 18:56:12.728 | 50.03.601.100 I slot print_timing: id  0 | task -1 | n_decoded =   2233, tg =  88.20 t/s
2026-05-23 18:56:12.728 | 50.03.601.124 I srv  update_slots: all slots are idle
2026-05-23 18:56:12.947 | 50.03.819.399 I srv  params_from_: Chat format: peg-native
2026-05-23 18:56:12.948 | 50.03.820.791 I slot get_availabl: id  0 | task -1 | selected slot by LCP similarity, sim_best = 0.999 (> 0.100 thold), f_keep = 1.000
2026-05-23 18:56:12.949 | 50.03.821.600 I reasoning-budget: activated, budget=2147483647 tokens
2026-05-23 18:56:12.949 | 50.03.821.709 I slot launch_slot_: id  0 | task 23843 | processing task, is_child = 0
2026-05-23 18:56:13.220 | 50.04.092.751 I slot create_check: id  0 | task 23843 | created context checkpoint 16 of 32 (pos_min = 33658, pos_max = 33658, n_tokens = 33659, size = 220.117 MiB)
2026-05-23 18:56:13.856 | 50.04.728.738 I reasoning-budget: deactivated (natural end)
2026-05-23 18:56:15.733 | 50.06.605.870 I slot print_timing: id  0 | task 23843 | n_decoded =    210, tg =  86.47 t/s
2026-05-23 18:56:17.644 | 50.08.516.635 I slot print_timing: id  0 | task 23843 | 
2026-05-23 18:56:17.644 | prompt eval time =     355.32 ms /    21 tokens (   16.92 ms per token,    59.10 tokens per second)
2026-05-23 18:56:17.644 |        eval time =    4833.18 ms /   430 tokens (   11.24 ms per token,    88.97 tokens per second)
2026-05-23 18:56:17.644 |       total time =    5188.50 ms /   451 tokens
2026-05-23 18:56:17.644 | draft acceptance rate = 0.94295 (  281 accepted /   298 generated)
2026-05-23 18:56:17.644 | 50.08.516.677 I statistics draft-mtp: #calls(b,g,a) = 84 23617 27850, #gen drafts = 27850, #acc drafts = 25100, #gen tokens = 55700, #acc tokens = 47790, dur(b,g,a) = 0.147, 124193.748, 61.123 ms
2026-05-23 18:56:17.645 | 50.08.517.753 I slot      release: id  0 | task 23843 | stop processing: n_tokens = 34110, truncated = 0
2026-05-23 18:56:17.645 | 50.08.517.839 I srv  update_slots: all slots are idle
2026-05-23 18:56:17.867 | 50.08.739.447 I srv  params_from_: Chat format: peg-native
2026-05-23 18:56:17.868 | 50.08.740.872 I slot get_availabl: id  0 | task -1 | selected slot by LCP similarity, sim_best = 0.999 (> 0.100 thold), f_keep = 1.000
2026-05-23 18:56:17.869 | 50.08.741.873 I reasoning-budget: activated, budget=2147483647 tokens
2026-05-23 18:56:17.869 | 50.08.741.990 I slot launch_slot_: id  0 | task 23995 | processing task, is_child = 0
2026-05-23 18:56:18.138 | 50.09.010.216 I slot create_check: id  0 | task 23995 | created context checkpoint 17 of 32 (pos_min = 34109, pos_max = 34109, n_tokens = 34110, size = 221.062 MiB)
2026-05-23 18:56:18.784 | 50.09.656.732 I reasoning-budget: deactivated (natural end)
2026-05-23 18:56:19.394 | 50.10.266.403 I slot print_timing: id  0 | task 23995 | n_decoded =    102, tg =  87.45 t/s
2026-05-23 18:56:21.911 | 50.12.783.187 I slot print_timing: id  0 | task 23995 | n_decoded =    381, tg =  91.06 t/s
2026-05-23 18:56:22.643 | 50.13.515.664 I slot print_timing: id  0 | task 23995 | 
2026-05-23 18:56:22.643 | prompt eval time =     357.75 ms /    37 tokens (    9.67 ms per token,   103.42 tokens per second)
2026-05-23 18:56:22.643 |        eval time =    4916.31 ms /   447 tokens (   11.00 ms per token,    90.92 tokens per second)
2026-05-23 18:56:22.643 |       total time =    5274.06 ms /   484 tokens
2026-05-23 18:56:22.643 | draft acceptance rate = 0.97682 (  295 accepted /   302 generated)
2026-05-23 18:56:22.643 | 50.13.515.700 I statistics draft-mtp: #calls(b,g,a) = 85 23768 28001, #gen drafts = 28001, #acc drafts = 25248, #gen tokens = 56002, #acc tokens = 48085, dur(b,g,a) = 0.148, 124891.159, 61.441 ms
2026-05-23 18:56:22.644 | 50.13.516.695 I slot      release: id  0 | task 23995 | stop processing: n_tokens = 34593, truncated = 0
2026-05-23 18:56:22.644 | 50.13.516.773 I srv  update_slots: all slots are idle
2026-05-23 18:56:22.878 | 50.13.750.524 I srv  params_from_: Chat format: peg-native
2026-05-23 18:56:22.880 | 50.13.752.005 I slot get_availabl: id  0 | task -1 | selected slot by LCP similarity, sim_best = 0.999 (> 0.100 thold), f_keep = 1.000
2026-05-23 18:56:22.880 | 50.13.752.914 I reasoning-budget: activated, budget=2147483647 tokens
2026-05-23 18:56:22.880 | 50.13.753.021 I slot launch_slot_: id  0 | task 24149 | processing task, is_child = 0
2026-05-23 18:56:23.149 | 50.14.021.344 I slot create_check: id  0 | task 24149 | created context checkpoint 18 of 32 (pos_min = 34592, pos_max = 34592, n_tokens = 34593, size = 222.073 MiB)
2026-05-23 18:56:24.297 | 50.15.169.329 I reasoning-budget: deactivated (natural end)
2026-05-23 18:56:24.914 | 50.15.785.961 I slot print_timing: id  0 | task 24149 | n_decoded =    131, tg =  78.40 t/s
2026-05-23 18:56:26.558 | 50.17.430.249 I slot print_timing: id  0 | task 24149 | 
2026-05-23 18:56:26.558 | prompt eval time =     361.81 ms /    47 tokens (    7.70 ms per token,   129.90 tokens per second)
2026-05-23 18:56:26.558 |        eval time =    3815.92 ms /   326 tokens (   11.71 ms per token,    85.43 tokens per second)
2026-05-23 18:56:26.558 |       total time =    4177.73 ms /   373 tokens
2026-05-23 18:56:26.558 | draft acceptance rate = 0.87712 (  207 accepted /   236 generated)
2026-05-23 18:56:26.558 | 50.17.430.285 I statistics draft-mtp: #calls(b,g,a) = 86 23886 28119, #gen drafts = 28119, #acc drafts = 25356, #gen tokens = 56238, #acc tokens = 48292, dur(b,g,a) = 0.149, 125440.033, 61.718 ms
2026-05-23 18:56:26.559 | 50.17.431.273 I slot      release: id  0 | task 24149 | stop processing: n_tokens = 34965, truncated = 0
2026-05-23 18:56:26.559 | 50.17.431.350 I srv  update_slots: all slots are idle
2026-05-23 18:56:26.795 | 50.17.667.047 I srv  params_from_: Chat format: peg-native
2026-05-23 18:56:26.796 | 50.17.668.450 I slot get_availabl: id  0 | task -1 | selected slot by LCP similarity, sim_best = 0.999 (> 0.100 thold), f_keep = 1.000
2026-05-23 18:56:26.797 | 50.17.669.349 I reasoning-budget: activated, budget=2147483647 tokens
2026-05-23 18:56:26.797 | 50.17.669.451 I slot launch_slot_: id  0 | task 24270 | processing task, is_child = 0
2026-05-23 18:56:27.070 | 50.17.942.442 I slot create_check: id  0 | task 24270 | created context checkpoint 19 of 32 (pos_min = 34964, pos_max = 34964, n_tokens = 34965, size = 222.852 MiB)
2026-05-23 18:56:27.683 | 50.18.555.829 I reasoning-budget: deactivated (natural end)
2026-05-23 18:56:28.419 | 50.19.291.354 I slot print_timing: id  0 | task 24270 | n_decoded =    100, tg =  79.25 t/s
2026-05-23 18:56:30.252 | 50.21.124.677 I slot print_timing: id  0 | task 24270 | 
2026-05-23 18:56:30.252 | prompt eval time =     359.93 ms /    22 tokens (   16.36 ms per token,    61.12 tokens per second)
2026-05-23 18:56:30.252 |        eval time =    3095.06 ms /   269 tokens (   11.51 ms per token,    86.91 tokens per second)
2026-05-23 18:56:30.252 |       total time =    3454.99 ms /   291 tokens
2026-05-23 18:56:30.252 | draft acceptance rate = 0.91579 (  174 accepted /   190 generated)
2026-05-23 18:56:30.252 | 50.21.124.713 I statistics draft-mtp: #calls(b,g,a) = 87 23981 28214, #gen drafts = 28214, #acc drafts = 25447, #gen tokens = 56428, #acc tokens = 48466, dur(b,g,a) = 0.151, 125886.320, 61.945 ms
2026-05-23 18:56:30.253 | 50.21.125.754 I slot      release: id  0 | task 24270 | stop processing: n_tokens = 35256, truncated = 0
2026-05-23 18:56:30.253 | 50.21.125.830 I srv  update_slots: all slots are idle
2026-05-23 18:56:30.511 | 50.21.383.473 I srv  params_from_: Chat format: peg-native
2026-05-23 18:56:30.512 | 50.21.384.863 I slot get_availabl: id  0 | task -1 | selected slot by LCP similarity, sim_best = 0.999 (> 0.100 thold), f_keep = 1.000
2026-05-23 18:56:30.513 | 50.21.385.745 I reasoning-budget: activated, budget=2147483647 tokens
2026-05-23 18:56:30.513 | 50.21.385.848 I slot launch_slot_: id  0 | task 24368 | processing task, is_child = 0
2026-05-23 18:56:30.788 | 50.21.660.153 I slot create_check: id  0 | task 24368 | created context checkpoint 20 of 32 (pos_min = 35255, pos_max = 35255, n_tokens = 35256, size = 223.462 MiB)
2026-05-23 18:56:32.002 | 50.22.874.497 I reasoning-budget: deactivated (natural end)
2026-05-23 18:56:31.669 | 50.22.541.896 I slot print_timing: id  0 | task 24368 | n_decoded =    101, tg =  77.97 t/s
2026-05-23 18:56:34.695 | 50.25.567.713 I slot print_timing: id  0 | task 24368 | n_decoded =    364, tg =  84.24 t/s
2026-05-23 18:56:37.219 | 50.28.091.664 I slot print_timing: id  0 | task 24368 | n_decoded =    638, tg =  86.78 t/s
2026-05-23 18:56:40.227 | 50.31.099.362 I slot print_timing: id  0 | task 24368 | n_decoded =    903, tg =  87.16 t/s
2026-05-23 18:56:40.515 | 50.31.387.068 I slot print_timing: id  0 | task 24368 | 
2026-05-23 18:56:40.515 | prompt eval time =     360.96 ms /    24 tokens (   15.04 ms per token,    66.49 tokens per second)
2026-05-23 18:56:40.515 |        eval time =   10647.49 ms /   925 tokens (   11.51 ms per token,    86.87 tokens per second)
2026-05-23 18:56:40.515 |       total time =   11008.45 ms /   949 tokens
2026-05-23 18:56:40.515 | draft acceptance rate = 0.91871 (  599 accepted /   652 generated)
2026-05-23 18:56:40.515 | 50.31.387.105 I statistics draft-mtp: #calls(b,g,a) = 88 24307 28540, #gen drafts = 28540, #acc drafts = 25754, #gen tokens = 57080, #acc tokens = 49065, dur(b,g,a) = 0.152, 127414.751, 62.676 ms
2026-05-23 18:56:40.516 | 50.31.388.131 I slot      release: id  0 | task 24368 | stop processing: n_tokens = 36205, truncated = 0
2026-05-23 18:56:40.516 | 50.31.388.211 I srv  update_slots: all slots are idle
2026-05-23 18:56:40.732 | 50.31.604.151 I srv  params_from_: Chat format: peg-native
2026-05-23 18:56:40.733 | 50.31.605.537 I slot get_availabl: id  0 | task -1 | selected slot by LCP similarity, sim_best = 0.985 (> 0.100 thold), f_keep = 1.000
2026-05-23 18:56:40.734 | 50.31.606.297 I reasoning-budget: activated, budget=2147483647 tokens
2026-05-23 18:56:40.734 | 50.31.606.392 I slot launch_slot_: id  0 | task 24697 | processing task, is_child = 0
2026-05-23 18:56:41.057 | 50.31.929.470 I slot create_check: id  0 | task 24697 | created context checkpoint 21 of 32 (pos_min = 36241, pos_max = 36241, n_tokens = 36242, size = 225.527 MiB)
2026-05-23 18:56:41.606 | 50.32.478.720 I slot create_check: id  0 | task 24697 | created context checkpoint 22 of 32 (pos_min = 36753, pos_max = 36753, n_tokens = 36754, size = 226.599 MiB)
2026-05-23 18:56:41.927 | 50.32.799.131 I reasoning-budget: deactivated (natural end)
2026-05-23 18:56:42.737 | 50.33.609.334 I slot print_timing: id  0 | task 24697 | n_decoded =    115, tg =  72.72 t/s
2026-05-23 18:56:43.153 | 50.34.025.510 I slot print_timing: id  0 | task 24697 | 
2026-05-23 18:56:43.153 | prompt eval time =     916.09 ms /   553 tokens (    1.66 ms per token,   603.65 tokens per second)
2026-05-23 18:56:43.153 |        eval time =    2129.38 ms /   164 tokens (   12.98 ms per token,    77.02 tokens per second)
2026-05-23 18:56:43.153 |       total time =    3045.48 ms /   717 tokens
2026-05-23 18:56:43.153 | draft acceptance rate = 0.76154 (   99 accepted /   130 generated)
2026-05-23 18:56:43.153 | 50.34.025.545 I statistics draft-mtp: #calls(b,g,a) = 89 24372 28605, #gen drafts = 28605, #acc drafts = 25808, #gen tokens = 57210, #acc tokens = 49164, dur(b,g,a) = 0.154, 127720.269, 62.817 ms
2026-05-23 18:56:43.154 | 50.34.026.617 I slot      release: id  0 | task 24697 | stop processing: n_tokens = 36922, truncated = 0
2026-05-23 18:56:43.154 | 50.34.026.693 I srv  update_slots: all slots are idle
2026-05-23 18:56:43.442 | 50.34.314.574 I srv  params_from_: Chat format: peg-native
2026-05-23 18:56:43.443 | 50.34.316.000 I slot get_availabl: id  0 | task -1 | selected slot by LCP similarity, sim_best = 0.977 (> 0.100 thold), f_keep = 0.996
2026-05-23 18:56:43.444 | 50.34.316.857 I slot launch_slot_: id  0 | task 24766 | processing task, is_child = 0
2026-05-23 18:56:43.444 | 50.34.316.913 W slot update_slots: id  0 | task 24766 | n_past = 36757, slot.prompt.tokens.size() = 36922, seq_id = 0, pos_min = 36921, n_swa = 0
2026-05-23 18:56:43.444 | 50.34.316.914 I slot update_slots: id  0 | task 24766 | Checking checkpoint with [36753, 36753] against 36757...
2026-05-23 18:56:43.484 | 50.34.356.014 W slot update_slots: id  0 | task 24766 | restored context checkpoint (pos_min = 36753, pos_max = 36753, n_tokens = 36754, n_past = 36754, size = 226.599 MiB)
2026-05-23 18:56:43.968 | 50.34.839.956 I slot create_check: id  0 | task 24766 | created context checkpoint 23 of 32 (pos_min = 37117, pos_max = 37117, n_tokens = 37118, size = 227.361 MiB)
2026-05-23 18:56:44.520 | 50.35.392.460 I slot create_check: id  0 | task 24766 | created context checkpoint 24 of 32 (pos_min = 37629, pos_max = 37629, n_tokens = 37630, size = 228.434 MiB)
2026-05-23 18:56:45.907 | 50.36.779.160 I slot print_timing: id  0 | task 24766 | n_decoded =    102, tg =  75.70 t/s
2026-05-23 18:56:46.763 | 50.37.635.742 I slot print_timing: id  0 | task 24766 | 
2026-05-23 18:56:46.763 | prompt eval time =    1114.58 ms /   880 tokens (    1.27 ms per token,   789.53 tokens per second)
2026-05-23 18:56:46.763 |        eval time =    2572.34 ms /   197 tokens (   13.06 ms per token,    76.58 tokens per second)
2026-05-23 18:56:46.763 |       total time =    3686.92 ms /  1077 tokens
2026-05-23 18:56:46.763 | draft acceptance rate = 0.74684 (  118 accepted /   158 generated)
2026-05-23 18:56:46.763 | 50.37.635.784 I statistics draft-mtp: #calls(b,g,a) = 90 24451 28684, #gen drafts = 28684, #acc drafts = 25873, #gen tokens = 57368, #acc tokens = 49282, dur(b,g,a) = 0.156, 128107.855, 62.997 ms
2026-05-23 18:56:46.764 | 50.37.636.872 I slot      release: id  0 | task 24766 | stop processing: n_tokens = 37831, truncated = 0
2026-05-23 18:56:46.764 | 50.37.636.948 I srv  update_slots: all slots are idle
2026-05-23 18:59:08.202 | 52.59.073.999 I srv  params_from_: Chat format: peg-native
2026-05-23 18:59:08.203 | 52.59.075.416 I slot get_availabl: id  0 | task -1 | selected slot by LCP similarity, sim_best = 0.723 (> 0.100 thold), f_keep = 0.693
2026-05-23 18:59:08.204 | 52.59.076.266 I reasoning-budget: activated, budget=2147483647 tokens
2026-05-23 18:59:08.204 | 52.59.076.381 I slot launch_slot_: id  0 | task 24849 | processing task, is_child = 0
2026-05-23 18:59:08.204 | 52.59.076.429 W slot update_slots: id  0 | task 24849 | n_past = 26199, slot.prompt.tokens.size() = 37831, seq_id = 0, pos_min = 37830, n_swa = 0
2026-05-23 18:59:08.204 | 52.59.076.430 I slot update_slots: id  0 | task 24849 | Checking checkpoint with [37629, 37629] against 26199...
2026-05-23 18:59:08.204 | 52.59.076.431 I slot update_slots: id  0 | task 24849 | Checking checkpoint with [37117, 37117] against 26199...
2026-05-23 18:59:08.204 | 52.59.076.431 I slot update_slots: id  0 | task 24849 | Checking checkpoint with [36753, 36753] against 26199...
2026-05-23 18:59:08.204 | 52.59.076.432 I slot update_slots: id  0 | task 24849 | Checking checkpoint with [36241, 36241] against 26199...
2026-05-23 18:59:08.204 | 52.59.076.433 I slot update_slots: id  0 | task 24849 | Checking checkpoint with [35255, 35255] against 26199...
2026-05-23 18:59:08.204 | 52.59.076.434 I slot update_slots: id  0 | task 24849 | Checking checkpoint with [34964, 34964] against 26199...
2026-05-23 18:59:08.204 | 52.59.076.434 I slot update_slots: id  0 | task 24849 | Checking checkpoint with [34592, 34592] against 26199...
2026-05-23 18:59:08.204 | 52.59.076.435 I slot update_slots: id  0 | task 24849 | Checking checkpoint with [34109, 34109] against 26199...
2026-05-23 18:59:08.204 | 52.59.076.436 I slot update_slots: id  0 | task 24849 | Checking checkpoint with [33658, 33658] against 26199...
2026-05-23 18:59:08.204 | 52.59.076.437 I slot update_slots: id  0 | task 24849 | Checking checkpoint with [31406, 31406] against 26199...
2026-05-23 18:59:08.204 | 52.59.076.437 I slot update_slots: id  0 | task 24849 | Checking checkpoint with [30057, 30057] against 26199...
2026-05-23 18:59:08.204 | 52.59.076.438 I slot update_slots: id  0 | task 24849 | Checking checkpoint with [29932, 29932] against 26199...
2026-05-23 18:59:08.204 | 52.59.076.438 I slot update_slots: id  0 | task 24849 | Checking checkpoint with [29411, 29411] against 26199...
2026-05-23 18:59:08.204 | 52.59.076.439 I slot update_slots: id  0 | task 24849 | Checking checkpoint with [29088, 29088] against 26199...
2026-05-23 18:59:08.204 | 52.59.076.440 I slot update_slots: id  0 | task 24849 | Checking checkpoint with [28992, 28992] against 26199...
2026-05-23 18:59:08.204 | 52.59.076.440 I slot update_slots: id  0 | task 24849 | Checking checkpoint with [28419, 28419] against 26199...
2026-05-23 18:59:08.204 | 52.59.076.441 I slot update_slots: id  0 | task 24849 | Checking checkpoint with [27907, 27907] against 26199...
2026-05-23 18:59:08.204 | 52.59.076.442 I slot update_slots: id  0 | task 24849 | Checking checkpoint with [26256, 26256] against 26199...
2026-05-23 18:59:08.204 | 52.59.076.443 I slot update_slots: id  0 | task 24849 | Checking checkpoint with [25744, 25744] against 26199...
2026-05-23 18:59:08.298 | 52.59.170.712 W slot update_slots: id  0 | task 24849 | restored context checkpoint (pos_min = 25744, pos_max = 25744, n_tokens = 25745, n_past = 25745, size = 203.543 MiB)
2026-05-23 18:59:08.298 | 52.59.170.736 W slot update_slots: id  0 | task 24849 | erased invalidated context checkpoint (pos_min = 26256, pos_max = 26256, n_tokens = 26257, n_swa = 0, pos_next = 25745, size = 204.615 MiB)
2026-05-23 18:59:08.311 | 52.59.183.329 W slot update_slots: id  0 | task 24849 | erased invalidated context checkpoint (pos_min = 27907, pos_max = 27907, n_tokens = 27908, n_swa = 0, pos_next = 25745, size = 208.073 MiB)
2026-05-23 18:59:08.324 | 52.59.196.708 W slot update_slots: id  0 | task 24849 | erased invalidated context checkpoint (pos_min = 28419, pos_max = 28419, n_tokens = 28420, n_swa = 0, pos_next = 25745, size = 209.145 MiB)
2026-05-23 18:59:08.337 | 52.59.209.720 W slot update_slots: id  0 | task 24849 | erased invalidated context checkpoint (pos_min = 28992, pos_max = 28992, n_tokens = 28993, n_swa = 0, pos_next = 25745, size = 210.345 MiB)
2026-05-23 18:59:08.350 | 52.59.222.704 W slot update_slots: id  0 | task 24849 | erased invalidated context checkpoint (pos_min = 29088, pos_max = 29088, n_tokens = 29089, n_swa = 0, pos_next = 25745, size = 210.546 MiB)
2026-05-23 18:59:08.363 | 52.59.235.710 W slot update_slots: id  0 | task 24849 | erased invalidated context checkpoint (pos_min = 29411, pos_max = 29411, n_tokens = 29412, n_swa = 0, pos_next = 25745, size = 211.223 MiB)
2026-05-23 18:59:08.377 | 52.59.249.022 W slot update_slots: id  0 | task 24849 | erased invalidated context checkpoint (pos_min = 29932, pos_max = 29932, n_tokens = 29933, n_swa = 0, pos_next = 25745, size = 212.314 MiB)
2026-05-23 18:59:08.390 | 52.59.262.224 W slot update_slots: id  0 | task 24849 | erased invalidated context checkpoint (pos_min = 30057, pos_max = 30057, n_tokens = 30058, n_swa = 0, pos_next = 25745, size = 212.576 MiB)
2026-05-23 18:59:08.403 | 52.59.275.321 W slot update_slots: id  0 | task 24849 | erased invalidated context checkpoint (pos_min = 31406, pos_max = 31406, n_tokens = 31407, n_swa = 0, pos_next = 25745, size = 215.401 MiB)
2026-05-23 18:59:08.416 | 52.59.288.812 W slot update_slots: id  0 | task 24849 | erased invalidated context checkpoint (pos_min = 33658, pos_max = 33658, n_tokens = 33659, n_swa = 0, pos_next = 25745, size = 220.117 MiB)
2026-05-23 18:59:08.430 | 52.59.302.373 W slot update_slots: id  0 | task 24849 | erased invalidated context checkpoint (pos_min = 34109, pos_max = 34109, n_tokens = 34110, n_swa = 0, pos_next = 25745, size = 221.062 MiB)
2026-05-23 18:59:08.444 | 52.59.316.323 W slot update_slots: id  0 | task 24849 | erased invalidated context checkpoint (pos_min = 34592, pos_max = 34592, n_tokens = 34593, n_swa = 0, pos_next = 25745, size = 222.073 MiB)
2026-05-23 18:59:08.458 | 52.59.330.303 W slot update_slots: id  0 | task 24849 | erased invalidated context checkpoint (pos_min = 34964, pos_max = 34964, n_tokens = 34965, n_swa = 0, pos_next = 25745, size = 222.852 MiB)
2026-05-23 18:59:08.472 | 52.59.344.021 W slot update_slots: id  0 | task 24849 | erased invalidated context checkpoint (pos_min = 35255, pos_max = 35255, n_tokens = 35256, n_swa = 0, pos_next = 25745, size = 223.462 MiB)
2026-05-23 18:59:08.485 | 52.59.357.871 W slot update_slots: id  0 | task 24849 | erased invalidated context checkpoint (pos_min = 36241, pos_max = 36241, n_tokens = 36242, n_swa = 0, pos_next = 25745, size = 225.527 MiB)
2026-05-23 18:59:08.499 | 52.59.371.845 W slot update_slots: id  0 | task 24849 | erased invalidated context checkpoint (pos_min = 36753, pos_max = 36753, n_tokens = 36754, n_swa = 0, pos_next = 25745, size = 226.599 MiB)
2026-05-23 18:59:08.513 | 52.59.385.792 W slot update_slots: id  0 | task 24849 | erased invalidated context checkpoint (pos_min = 37117, pos_max = 37117, n_tokens = 37118, n_swa = 0, pos_next = 25745, size = 227.361 MiB)
2026-05-23 18:59:08.528 | 52.59.400.211 W slot update_slots: id  0 | task 24849 | erased invalidated context checkpoint (pos_min = 37629, pos_max = 37629, n_tokens = 37630, n_swa = 0, pos_next = 25745, size = 228.434 MiB)
2026-05-23 18:59:11.549 | 53.02.421.718 I slot print_timing: id  0 | task 24849 | prompt processing, n_tokens =   6144, progress = 0.88, t =   3.35 s / 1836.60 tokens per second
2026-05-23 18:59:12.077 | 53.02.949.513 I slot print_timing: id  0 | task 24849 | prompt processing, n_tokens =   8192, progress = 0.94, t =   4.37 s / 1873.14 tokens per second
2026-05-23 18:59:12.077 | 53.02.949.734 I slot update_slots: id  0 | task 24849 | 8192 tokens since last checkpoint at 25745, creating new checkpoint during processing at position 35735
2026-05-23 18:59:12.335 | 53.03.207.923 I slot create_check: id  0 | task 24849 | created context checkpoint 7 of 32 (pos_min = 33936, pos_max = 33936, n_tokens = 33937, size = 220.699 MiB)
2026-05-23 18:59:13.278 | 53.04.150.317 I slot print_timing: id  0 | task 24849 | prompt processing, n_tokens =   9990, progress = 0.99, t =   5.57 s / 1792.18 tokens per second
2026-05-23 18:59:13.563 | 53.04.435.249 I slot create_check: id  0 | task 24849 | created context checkpoint 8 of 32 (pos_min = 35734, pos_max = 35734, n_tokens = 35735, size = 224.465 MiB)
2026-05-23 18:59:13.827 | 53.04.698.948 I slot print_timing: id  0 | task 24849 | prompt processing, n_tokens =  10502, progress = 1.00, t =   6.12 s / 1715.22 tokens per second
2026-05-23 18:59:14.108 | 53.04.980.005 I slot create_check: id  0 | task 24849 | created context checkpoint 9 of 32 (pos_min = 36246, pos_max = 36246, n_tokens = 36247, size = 225.537 MiB)
2026-05-23 18:59:14.191 | 53.05.063.560 I reasoning-budget: deactivated (natural end)
2026-05-23 18:59:14.648 | 53.05.520.528 I slot print_timing: id  0 | task 24849 | 
2026-05-23 18:59:14.648 | prompt eval time =    6442.81 ms / 10506 tokens (    0.61 ms per token,  1630.65 tokens per second)
2026-05-23 18:59:14.648 |        eval time =     501.20 ms /    39 tokens (   12.85 ms per token,    77.81 tokens per second)
2026-05-23 18:59:14.648 |       total time =    6944.02 ms / 10545 tokens
2026-05-23 18:59:14.648 | draft acceptance rate = 0.92857 (   26 accepted /    28 generated)
2026-05-23 18:59:14.648 | 53.05.520.565 I statistics draft-mtp: #calls(b,g,a) = 91 24465 28698, #gen drafts = 28698, #acc drafts = 25886, #gen tokens = 57396, #acc tokens = 49308, dur(b,g,a) = 0.158, 128170.933, 63.026 ms
2026-05-23 18:59:14.649 | 53.05.521.511 I slot      release: id  0 | task 24849 | stop processing: n_tokens = 36291, truncated = 0
2026-05-23 18:59:14.649 | 53.05.521.591 I srv  update_slots: all slots are idle
2026-05-23 18:59:14.846 | 53.05.718.463 I srv  params_from_: Chat format: peg-native
2026-05-23 18:59:14.847 | 53.05.719.863 I slot get_availabl: id  0 | task -1 | selected slot by LCP similarity, sim_best = 0.960 (> 0.100 thold), f_keep = 0.999
2026-05-23 18:59:14.848 | 53.05.720.767 I reasoning-budget: activated, budget=2147483647 tokens
2026-05-23 18:59:14.848 | 53.05.720.885 I slot launch_slot_: id  0 | task 24871 | processing task, is_child = 0
2026-05-23 18:59:14.848 | 53.05.720.944 W slot update_slots: id  0 | task 24871 | n_past = 36250, slot.prompt.tokens.size() = 36291, seq_id = 0, pos_min = 36290, n_swa = 0
2026-05-23 18:59:14.848 | 53.05.720.944 I slot update_slots: id  0 | task 24871 | Checking checkpoint with [36246, 36246] against 36250...
2026-05-23 18:59:14.896 | 53.05.767.991 W slot update_slots: id  0 | task 24871 | restored context checkpoint (pos_min = 36246, pos_max = 36246, n_tokens = 36247, n_past = 36247, size = 225.537 MiB)
2026-05-23 18:59:15.695 | 53.06.567.143 I slot create_check: id  0 | task 24871 | created context checkpoint 10 of 32 (pos_min = 37260, pos_max = 37260, n_tokens = 37261, size = 227.661 MiB)
2026-05-23 18:59:16.257 | 53.07.129.361 I slot create_check: id  0 | task 24871 | created context checkpoint 11 of 32 (pos_min = 37772, pos_max = 37772, n_tokens = 37773, size = 228.733 MiB)
2026-05-23 18:59:16.791 | 53.07.663.049 I reasoning-budget: deactivated (natural end)
2026-05-23 18:59:17.068 | 53.07.940.492 I slot print_timing: id  0 | task 24871 | n_decoded =    100, tg =  78.61 t/s
2026-05-23 18:59:20.071 | 53.10.942.969 I slot print_timing: id  0 | task 24871 | n_decoded =    338, tg =  79.07 t/s
2026-05-23 18:59:22.595 | 53.13.467.035 I slot print_timing: id  0 | task 24871 | n_decoded =    564, tg =  77.27 t/s
2026-05-23 18:59:25.618 | 53.16.490.609 I slot print_timing: id  0 | task 24871 | n_decoded =    817, tg =  79.15 t/s
2026-05-23 18:59:28.141 | 53.19.013.657 I slot print_timing: id  0 | task 24871 | n_decoded =   1070, tg =  80.17 t/s
2026-05-23 18:59:31.168 | 53.22.040.227 I slot print_timing: id  0 | task 24871 | n_decoded =   1330, tg =  81.23 t/s
2026-05-23 18:59:33.679 | 53.24.551.144 I slot print_timing: id  0 | task 24871 | n_decoded =   1593, tg =  82.15 t/s
2026-05-23 18:59:36.696 | 53.27.567.924 I slot print_timing: id  0 | task 24871 | n_decoded =   1861, tg =  83.05 t/s
2026-05-23 18:59:39.200 | 53.30.072.531 I slot print_timing: id  0 | task 24871 | n_decoded =   2107, tg =  82.91 t/s
2026-05-23 18:59:40.231 | 53.31.103.636 I slot print_timing: id  0 | task 24871 | 
2026-05-23 18:59:40.231 | prompt eval time =    1447.49 ms /  1530 tokens (    0.95 ms per token,  1057.01 tokens per second)
2026-05-23 18:59:40.231 |        eval time =   26444.76 ms /  2200 tokens (   12.02 ms per token,    83.19 tokens per second)
2026-05-23 18:59:40.231 |       total time =   27892.24 ms /  3730 tokens
2026-05-23 18:59:40.231 | draft acceptance rate = 0.85406 ( 1387 accepted /  1624 generated)
2026-05-23 18:59:40.231 | 53.31.103.669 I statistics draft-mtp: #calls(b,g,a) = 92 25277 29510, #gen drafts = 29510, #acc drafts = 26622, #gen tokens = 59020, #acc tokens = 50695, dur(b,g,a) = 0.160, 131935.331, 64.790 ms
2026-05-23 18:59:40.232 | 53.31.104.791 I slot      release: id  0 | task 24871 | stop processing: n_tokens = 39976, truncated = 0
2026-05-23 18:59:40.232 | 53.31.104.872 I srv  update_slots: all slots are idle
2026-05-23 18:59:40.490 | 53.31.362.316 I srv  params_from_: Chat format: peg-native
2026-05-23 18:59:40.491 | 53.31.363.803 I slot get_availabl: id  0 | task -1 | selected slot by LCP similarity, sim_best = 0.999 (> 0.100 thold), f_keep = 1.000
2026-05-23 18:59:40.492 | 53.31.364.787 I reasoning-budget: activated, budget=2147483647 tokens
2026-05-23 18:59:40.492 | 53.31.364.920 I slot launch_slot_: id  0 | task 25687 | processing task, is_child = 0
2026-05-23 18:59:40.776 | 53.31.648.115 I slot create_check: id  0 | task 25687 | created context checkpoint 12 of 32 (pos_min = 39975, pos_max = 39975, n_tokens = 39976, size = 233.347 MiB)
2026-05-23 18:59:41.148 | 53.32.020.550 I reasoning-budget: deactivated (natural end)
2026-05-23 18:59:41.898 | 53.32.770.919 I slot print_timing: id  0 | task 25687 | 
2026-05-23 18:59:41.899 | prompt eval time =     373.70 ms /    21 tokens (   17.80 ms per token,    56.19 tokens per second)
2026-05-23 18:59:41.899 |        eval time =    1031.83 ms /    87 tokens (   11.86 ms per token,    84.32 tokens per second)
2026-05-23 18:59:41.899 |       total time =    1405.53 ms /   108 tokens
2026-05-23 18:59:41.899 | draft acceptance rate = 0.96667 (   58 accepted /    60 generated)
2026-05-23 18:59:41.899 | 53.32.770.956 I statistics draft-mtp: #calls(b,g,a) = 93 25307 29540, #gen drafts = 29540, #acc drafts = 26652, #gen tokens = 59080, #acc tokens = 50753, dur(b,g,a) = 0.162, 132074.864, 64.854 ms
2026-05-23 18:59:41.900 | 53.32.772.013 I slot      release: id  0 | task 25687 | stop processing: n_tokens = 40085, truncated = 0
2026-05-23 18:59:41.900 | 53.32.772.094 I srv  update_slots: all slots are idle
2026-05-23 18:59:42.108 | 53.32.980.777 I srv  params_from_: Chat format: peg-native
2026-05-23 18:59:42.110 | 53.32.982.207 I slot get_availabl: id  0 | task -1 | selected slot by LCP similarity, sim_best = 1.000 (> 0.100 thold), f_keep = 1.000
2026-05-23 18:59:42.111 | 53.32.983.034 I reasoning-budget: activated, budget=2147483647 tokens
2026-05-23 18:59:42.111 | 53.32.983.141 I slot launch_slot_: id  0 | task 25720 | processing task, is_child = 0
2026-05-23 18:59:41.901 | 53.32.773.369 I slot create_check: id  0 | task 25720 | created context checkpoint 13 of 32 (pos_min = 40084, pos_max = 40084, n_tokens = 40085, size = 233.575 MiB)
2026-05-23 18:59:42.265 | 53.33.137.033 I reasoning-budget: deactivated (natural end)
2026-05-23 18:59:42.952 | 53.33.824.112 I slot print_timing: id  0 | task 25720 | 
2026-05-23 18:59:42.952 | prompt eval time =     368.73 ms /    16 tokens (   23.05 ms per token,    43.39 tokens per second)
2026-05-23 18:59:42.952 |        eval time =     964.68 ms /    87 tokens (   11.09 ms per token,    90.19 tokens per second)
2026-05-23 18:59:42.952 |       total time =    1333.42 ms /   103 tokens
2026-05-23 18:59:42.952 | draft acceptance rate = 1.00000 (   58 accepted /    58 generated)
2026-05-23 18:59:42.952 | 53.33.824.146 I statistics draft-mtp: #calls(b,g,a) = 94 25336 29569, #gen drafts = 29569, #acc drafts = 26681, #gen tokens = 59138, #acc tokens = 50811, dur(b,g,a) = 0.163, 132211.787, 64.918 ms
2026-05-23 18:59:42.953 | 53.33.825.269 I slot      release: id  0 | task 25720 | stop processing: n_tokens = 40188, truncated = 0
2026-05-23 18:59:42.953 | 53.33.825.346 I srv  update_slots: all slots are idle
2026-05-23 18:59:43.160 | 53.34.032.622 I srv  params_from_: Chat format: peg-native
2026-05-23 18:59:43.162 | 53.34.034.036 I slot get_availabl: id  0 | task -1 | selected slot by LCP similarity, sim_best = 1.000 (> 0.100 thold), f_keep = 1.000
2026-05-23 18:59:43.162 | 53.34.034.895 I reasoning-budget: activated, budget=2147483647 tokens
2026-05-23 18:59:43.162 | 53.34.035.025 I slot launch_slot_: id  0 | task 25752 | processing task, is_child = 0
2026-05-23 18:59:43.446 | 53.34.318.627 I slot create_check: id  0 | task 25752 | created context checkpoint 14 of 32 (pos_min = 40187, pos_max = 40187, n_tokens = 40188, size = 233.791 MiB)
2026-05-23 18:59:43.809 | 53.34.681.865 I reasoning-budget: deactivated (natural end)
2026-05-23 18:59:44.694 | 53.35.566.494 I slot print_timing: id  0 | task 25752 | n_decoded =    100, tg =  86.08 t/s
2026-05-23 18:59:45.406 | 53.36.278.716 I slot print_timing: id  0 | task 25752 | 
2026-05-23 18:59:45.406 | prompt eval time =     369.48 ms /    17 tokens (   21.73 ms per token,    46.01 tokens per second)
2026-05-23 18:59:45.406 |        eval time =    1873.98 ms /   163 tokens (   11.50 ms per token,    86.98 tokens per second)
2026-05-23 18:59:45.406 |       total time =    2243.46 ms /   180 tokens
2026-05-23 18:59:45.406 | draft acceptance rate = 0.92982 (  106 accepted /   114 generated)
2026-05-23 18:59:45.406 | 53.36.278.751 I statistics draft-mtp: #calls(b,g,a) = 95 25393 29626, #gen drafts = 29626, #acc drafts = 26736, #gen tokens = 59252, #acc tokens = 50917, dur(b,g,a) = 0.164, 132478.028, 65.032 ms
2026-05-23 18:59:45.407 | 53.36.279.906 I slot      release: id  0 | task 25752 | stop processing: n_tokens = 40368, truncated = 0
2026-05-23 18:59:45.407 | 53.36.279.977 I srv  update_slots: all slots are idle
2026-05-23 18:59:45.657 | 53.36.529.048 I srv  params_from_: Chat format: peg-native
2026-05-23 18:59:45.658 | 53.36.530.443 I slot get_availabl: id  0 | task -1 | selected slot by LCP similarity, sim_best = 1.000 (> 0.100 thold), f_keep = 1.000
2026-05-23 18:59:45.659 | 53.36.531.335 I reasoning-budget: activated, budget=2147483647 tokens
2026-05-23 18:59:45.659 | 53.36.531.441 I slot launch_slot_: id  0 | task 25812 | processing task, is_child = 0
2026-05-23 18:59:45.942 | 53.36.814.060 I slot create_check: id  0 | task 25812 | created context checkpoint 15 of 32 (pos_min = 40367, pos_max = 40367, n_tokens = 40368, size = 234.168 MiB)
2026-05-23 18:59:46.306 | 53.37.178.573 I reasoning-budget: deactivated (natural end)
2026-05-23 18:59:47.013 | 53.37.885.752 I slot print_timing: id  0 | task 25812 | 
2026-05-23 18:59:47.013 | prompt eval time =     369.67 ms /    18 tokens (   20.54 ms per token,    48.69 tokens per second)
2026-05-23 18:59:47.013 |        eval time =     984.26 ms /    82 tokens (   12.00 ms per token,    83.31 tokens per second)
2026-05-23 18:59:47.013 |       total time =    1353.93 ms /   100 tokens
2026-05-23 18:59:47.013 | draft acceptance rate = 0.98214 (   55 accepted /    56 generated)
2026-05-23 18:59:47.013 | 53.37.885.787 I statistics draft-mtp: #calls(b,g,a) = 96 25421 29654, #gen drafts = 29654, #acc drafts = 26764, #gen tokens = 59308, #acc tokens = 50972, dur(b,g,a) = 0.165, 132610.211, 65.094 ms
2026-05-23 18:59:47.014 | 53.37.886.858 I slot      release: id  0 | task 25812 | stop processing: n_tokens = 40469, truncated = 0
2026-05-23 18:59:47.014 | 53.37.886.935 I srv  update_slots: all slots are idle
2026-05-23 18:59:47.215 | 53.38.087.476 I srv  params_from_: Chat format: peg-native
2026-05-23 18:59:47.216 | 53.38.088.894 I slot get_availabl: id  0 | task -1 | selected slot by LCP similarity, sim_best = 0.951 (> 0.100 thold), f_keep = 1.000
2026-05-23 18:59:47.217 | 53.38.089.817 I reasoning-budget: activated, budget=2147483647 tokens
2026-05-23 18:59:47.217 | 53.38.089.918 I slot launch_slot_: id  0 | task 25843 | processing task, is_child = 0
2026-05-23 18:59:47.907 | 53.38.779.527 I slot create_check: id  0 | task 25843 | created context checkpoint 16 of 32 (pos_min = 42026, pos_max = 42026, n_tokens = 42027, size = 237.642 MiB)
2026-05-23 18:59:48.488 | 53.39.360.889 I slot create_check: id  0 | task 25843 | created context checkpoint 17 of 32 (pos_min = 42538, pos_max = 42538, n_tokens = 42539, size = 238.714 MiB)
2026-05-23 18:59:49.511 | 53.40.383.601 I reasoning-budget: deactivated (natural end)
2026-05-23 18:59:50.029 | 53.40.901.076 I slot print_timing: id  0 | task 25843 | n_decoded =    101, tg =  67.26 t/s
2026-05-23 18:59:51.143 | 53.42.015.180 I slot print_timing: id  0 | task 25843 | 
2026-05-23 18:59:51.143 | prompt eval time =    1810.23 ms /  2074 tokens (    0.87 ms per token,  1145.71 tokens per second)
2026-05-23 18:59:51.143 |        eval time =    2615.73 ms /   191 tokens (   13.69 ms per token,    73.02 tokens per second)
2026-05-23 18:59:51.143 |       total time =    4425.95 ms /  2265 tokens
2026-05-23 18:59:51.143 | draft acceptance rate = 0.68750 (  110 accepted /   160 generated)
2026-05-23 18:59:51.143 | 53.42.015.215 I statistics draft-mtp: #calls(b,g,a) = 97 25501 29734, #gen drafts = 29734, #acc drafts = 26825, #gen tokens = 59468, #acc tokens = 51082, dur(b,g,a) = 0.167, 132984.292, 65.255 ms
2026-05-23 18:59:51.144 | 53.42.016.357 I slot      release: id  0 | task 25843 | stop processing: n_tokens = 42733, truncated = 0
2026-05-23 18:59:51.144 | 53.42.016.435 I srv  update_slots: all slots are idle
2026-05-23 18:59:51.378 | 53.42.250.759 I srv  params_from_: Chat format: peg-native
2026-05-23 18:59:51.380 | 53.42.252.203 I slot get_availabl: id  0 | task -1 | selected slot by LCP similarity, sim_best = 0.999 (> 0.100 thold), f_keep = 1.000
2026-05-23 18:59:51.381 | 53.42.253.058 I reasoning-budget: activated, budget=2147483647 tokens
2026-05-23 18:59:51.381 | 53.42.253.173 I slot launch_slot_: id  0 | task 25927 | processing task, is_child = 0
2026-05-23 18:59:51.673 | 53.42.545.045 I slot create_check: id  0 | task 25927 | created context checkpoint 18 of 32 (pos_min = 42732, pos_max = 42732, n_tokens = 42733, size = 239.121 MiB)
2026-05-23 18:59:51.920 | 53.42.792.054 I reasoning-budget: deactivated (natural end)
2026-05-23 18:59:52.551 | 53.43.423.671 I slot print_timing: id  0 | task 25927 | n_decoded =    100, tg =  77.07 t/s
2026-05-23 18:59:52.879 | 53.43.751.679 I slot print_timing: id  0 | task 25927 | 
2026-05-23 18:59:52.879 | prompt eval time =     380.25 ms /    27 tokens (   14.08 ms per token,    71.01 tokens per second)
2026-05-23 18:59:52.879 |        eval time =    1625.50 ms /   125 tokens (   13.00 ms per token,    76.90 tokens per second)
2026-05-23 18:59:52.879 |       total time =    2005.75 ms /   152 tokens
2026-05-23 18:59:52.879 | draft acceptance rate = 0.77551 (   76 accepted /    98 generated)
2026-05-23 18:59:52.879 | 53.43.751.718 I statistics draft-mtp: #calls(b,g,a) = 98 25550 29783, #gen drafts = 29783, #acc drafts = 26865, #gen tokens = 59566, #acc tokens = 51158, dur(b,g,a) = 0.168, 133215.809, 65.356 ms
2026-05-23 18:59:52.880 | 53.43.752.950 I slot      release: id  0 | task 25927 | stop processing: n_tokens = 42885, truncated = 0
2026-05-23 18:59:52.880 | 53.43.753.026 I srv  update_slots: all slots are idle
2026-05-23 18:59:53.080 | 53.43.952.413 I srv  params_from_: Chat format: peg-native
2026-05-23 18:59:53.081 | 53.43.953.825 I slot get_availabl: id  0 | task -1 | selected slot by LCP similarity, sim_best = 1.000 (> 0.100 thold), f_keep = 1.000
2026-05-23 18:59:53.082 | 53.43.954.589 I reasoning-budget: activated, budget=2147483647 tokens
2026-05-23 18:59:53.082 | 53.43.954.699 I slot launch_slot_: id  0 | task 25979 | processing task, is_child = 0
2026-05-23 18:59:53.371 | 53.44.243.568 I slot create_check: id  0 | task 25979 | created context checkpoint 19 of 32 (pos_min = 42884, pos_max = 42884, n_tokens = 42885, size = 239.439 MiB)
2026-05-23 18:59:53.965 | 53.44.837.235 I reasoning-budget: deactivated (natural end)
2026-05-23 18:59:55.112 | 53.45.984.268 I slot print_timing: id  0 | task 25979 | 
2026-05-23 18:59:55.112 | prompt eval time =     381.16 ms /    21 tokens (   18.15 ms per token,    55.10 tokens per second)
2026-05-23 18:59:55.112 |        eval time =    1845.72 ms /   146 tokens (   12.64 ms per token,    79.10 tokens per second)
2026-05-23 18:59:55.112 |       total time =    2226.88 ms /   167 tokens
2026-05-23 18:59:55.112 | draft acceptance rate = 0.82727 (   91 accepted /   110 generated)
2026-05-23 18:59:55.112 | 53.45.984.306 I statistics draft-mtp: #calls(b,g,a) = 99 25605 29838, #gen drafts = 29838, #acc drafts = 26914, #gen tokens = 59676, #acc tokens = 51249, dur(b,g,a) = 0.169, 133475.539, 65.473 ms
2026-05-23 18:59:55.113 | 53.45.985.507 I slot      release: id  0 | task 25979 | stop processing: n_tokens = 43052, truncated = 0
2026-05-23 18:59:55.113 | 53.45.985.581 I srv  update_slots: all slots are idle
2026-05-23 18:59:55.326 | 53.46.198.495 I srv  params_from_: Chat format: peg-native
2026-05-23 18:59:55.327 | 53.46.199.882 I slot get_availabl: id  0 | task -1 | selected slot by LCP similarity, sim_best = 0.997 (> 0.100 thold), f_keep = 1.000
2026-05-23 18:59:55.328 | 53.46.200.646 I reasoning-budget: activated, budget=2147483647 tokens
2026-05-23 18:59:55.328 | 53.46.200.750 I slot launch_slot_: id  0 | task 26037 | processing task, is_child = 0
2026-05-23 18:59:55.622 | 53.46.494.266 I slot create_check: id  0 | task 26037 | created context checkpoint 20 of 32 (pos_min = 43051, pos_max = 43051, n_tokens = 43052, size = 239.789 MiB)
2026-05-23 18:59:56.011 | 53.46.883.762 I slot create_check: id  0 | task 26037 | created context checkpoint 21 of 32 (pos_min = 43178, pos_max = 43178, n_tokens = 43179, size = 240.055 MiB)
2026-05-23 18:59:57.354 | 53.48.226.478 I slot print_timing: id  0 | task 26037 | n_decoded =    102, tg =  63.79 t/s
2026-05-23 18:59:58.258 | 53.49.130.912 I reasoning-budget: deactivated (natural end)
2026-05-23 18:59:59.021 | 53.49.893.587 I slot print_timing: id  0 | task 26037 | 
2026-05-23 18:59:59.021 | prompt eval time =     722.89 ms /   131 tokens (    5.52 ms per token,   181.22 tokens per second)
2026-05-23 18:59:59.021 |        eval time =    3266.03 ms /   230 tokens (   14.20 ms per token,    70.42 tokens per second)
2026-05-23 18:59:59.021 |       total time =    3988.92 ms /   361 tokens
2026-05-23 18:59:59.021 | draft acceptance rate = 0.65657 (  130 accepted /   198 generated)
2026-05-23 18:59:59.021 | 53.49.893.622 I statistics draft-mtp: #calls(b,g,a) = 100 25704 29937, #gen drafts = 29937, #acc drafts = 26986, #gen tokens = 59874, #acc tokens = 51379, dur(b,g,a) = 0.171, 133952.632, 65.680 ms
2026-05-23 18:59:59.022 | 53.49.894.788 I slot      release: id  0 | task 26037 | stop processing: n_tokens = 43412, truncated = 0
2026-05-23 18:59:59.022 | 53.49.894.867 I srv  update_slots: all slots are idle
2026-05-23 18:59:59.285 | 53.50.157.522 I srv  params_from_: Chat format: peg-native
2026-05-23 18:59:59.287 | 53.50.158.982 I slot get_availabl: id  0 | task -1 | selected slot by LCP similarity, sim_best = 0.996 (> 0.100 thold), f_keep = 1.000
2026-05-23 18:59:59.287 | 53.50.159.851 I reasoning-budget: activated, budget=2147483647 tokens
2026-05-23 18:59:59.287 | 53.50.159.971 I slot launch_slot_: id  0 | task 26139 | processing task, is_child = 0
2026-05-23 18:59:59.582 | 53.50.454.325 I slot create_check: id  0 | task 26139 | created context checkpoint 22 of 32 (pos_min = 43411, pos_max = 43411, n_tokens = 43412, size = 240.543 MiB)
2026-05-23 18:59:59.993 | 53.50.865.542 I slot create_check: id  0 | task 26139 | created context checkpoint 23 of 32 (pos_min = 43579, pos_max = 43579, n_tokens = 43580, size = 240.894 MiB)
2026-05-23 19:00:00.373 | 53.51.245.425 I reasoning-budget: deactivated (natural end)
2026-05-23 19:00:01.333 | 53.52.205.228 I slot print_timing: id  0 | task 26139 | n_decoded =    100, tg =  76.95 t/s
2026-05-23 19:00:01.728 | 53.52.600.886 I slot print_timing: id  0 | task 26139 | 
2026-05-23 19:00:01.729 | prompt eval time =     745.49 ms /   172 tokens (    4.33 ms per token,   230.72 tokens per second)
2026-05-23 19:00:01.729 |        eval time =    1695.21 ms /   130 tokens (   13.04 ms per token,    76.69 tokens per second)
2026-05-23 19:00:01.729 |       total time =    2440.70 ms /   302 tokens
2026-05-23 19:00:01.729 | draft acceptance rate = 0.76471 (   78 accepted /   102 generated)
2026-05-23 19:00:01.729 | 53.52.600.920 I statistics draft-mtp: #calls(b,g,a) = 101 25755 29988, #gen drafts = 29988, #acc drafts = 27028, #gen tokens = 59976, #acc tokens = 51457, dur(b,g,a) = 0.173, 134192.989, 65.783 ms
2026-05-23 19:00:01.730 | 53.52.602.153 I slot      release: id  0 | task 26139 | stop processing: n_tokens = 43713, truncated = 0
2026-05-23 19:00:01.730 | 53.52.602.227 I srv  update_slots: all slots are idle
2026-05-23 19:00:01.995 | 53.52.867.885 I srv  params_from_: Chat format: peg-native
2026-05-23 19:00:01.997 | 53.52.869.344 I slot get_availabl: id  0 | task -1 | selected slot by LCP similarity, sim_best = 0.998 (> 0.100 thold), f_keep = 1.000
2026-05-23 19:00:01.998 | 53.52.870.289 I reasoning-budget: activated, budget=2147483647 tokens
2026-05-23 19:00:01.998 | 53.52.870.395 I slot launch_slot_: id  0 | task 26193 | processing task, is_child = 0
2026-05-23 19:00:02.294 | 53.53.166.689 I slot create_check: id  0 | task 26193 | created context checkpoint 24 of 32 (pos_min = 43712, pos_max = 43712, n_tokens = 43713, size = 241.173 MiB)
2026-05-23 19:00:02.180 | 53.53.052.028 I slot create_check: id  0 | task 26193 | created context checkpoint 25 of 32 (pos_min = 43814, pos_max = 43814, n_tokens = 43815, size = 241.387 MiB)
2026-05-23 19:00:02.500 | 53.53.372.824 I reasoning-budget: deactivated (natural end)
2026-05-23 19:00:03.860 | 53.54.732.637 I slot print_timing: id  0 | task 26193 | n_decoded =    130, tg =  79.20 t/s
2026-05-23 19:00:05.041 | 53.55.913.492 I slot print_timing: id  0 | task 26193 | 
2026-05-23 19:00:05.041 | prompt eval time =     721.25 ms /   106 tokens (    6.80 ms per token,   146.97 tokens per second)
2026-05-23 19:00:05.041 |        eval time =    2822.26 ms /   221 tokens (   12.77 ms per token,    78.31 tokens per second)
2026-05-23 19:00:05.041 |       total time =    3543.51 ms /   327 tokens
2026-05-23 19:00:05.041 | draft acceptance rate = 0.80952 (  136 accepted /   168 generated)
2026-05-23 19:00:05.041 | 53.55.913.527 I statistics draft-mtp: #calls(b,g,a) = 102 25839 30072, #gen drafts = 30072, #acc drafts = 27101, #gen tokens = 60144, #acc tokens = 51593, dur(b,g,a) = 0.174, 134603.026, 65.979 ms
2026-05-23 19:00:05.042 | 53.55.914.703 I slot      release: id  0 | task 26193 | stop processing: n_tokens = 44039, truncated = 0
2026-05-23 19:00:05.042 | 53.55.914.777 I srv  update_slots: all slots are idle
2026-05-23 19:03:36.145 | 57.27.017.824 I srv  params_from_: Chat format: peg-native
2026-05-23 19:03:36.147 | 57.27.019.640 I slot get_availabl: id  0 | task -1 | selected slot by LCP similarity, sim_best = 0.831 (> 0.100 thold), f_keep = 0.822
2026-05-23 19:03:36.148 | 57.27.020.416 I reasoning-budget: activated, budget=2147483647 tokens
2026-05-23 19:03:36.148 | 57.27.020.525 I slot launch_slot_: id  0 | task 26280 | processing task, is_child = 0
2026-05-23 19:03:36.148 | 57.27.020.563 W slot update_slots: id  0 | task 26280 | n_past = 36189, slot.prompt.tokens.size() = 44039, seq_id = 0, pos_min = 44038, n_swa = 0
2026-05-23 19:03:36.148 | 57.27.020.581 I slot update_slots: id  0 | task 26280 | Checking checkpoint with [43814, 43814] against 36189...
2026-05-23 19:03:36.148 | 57.27.020.581 I slot update_slots: id  0 | task 26280 | Checking checkpoint with [43712, 43712] against 36189...
2026-05-23 19:03:36.148 | 57.27.020.582 I slot update_slots: id  0 | task 26280 | Checking checkpoint with [43579, 43579] against 36189...
2026-05-23 19:03:36.148 | 57.27.020.584 I slot update_slots: id  0 | task 26280 | Checking checkpoint with [43411, 43411] against 36189...
2026-05-23 19:03:36.148 | 57.27.020.584 I slot update_slots: id  0 | task 26280 | Checking checkpoint with [43178, 43178] against 36189...
2026-05-23 19:03:36.148 | 57.27.020.585 I slot update_slots: id  0 | task 26280 | Checking checkpoint with [43051, 43051] against 36189...
2026-05-23 19:03:36.148 | 57.27.020.587 I slot update_slots: id  0 | task 26280 | Checking checkpoint with [42884, 42884] against 36189...
2026-05-23 19:03:36.148 | 57.27.020.588 I slot update_slots: id  0 | task 26280 | Checking checkpoint with [42732, 42732] against 36189...
2026-05-23 19:03:36.148 | 57.27.020.589 I slot update_slots: id  0 | task 26280 | Checking checkpoint with [42538, 42538] against 36189...
2026-05-23 19:03:36.148 | 57.27.020.590 I slot update_slots: id  0 | task 26280 | Checking checkpoint with [42026, 42026] against 36189...
2026-05-23 19:03:36.148 | 57.27.020.590 I slot update_slots: id  0 | task 26280 | Checking checkpoint with [40367, 40367] against 36189...
2026-05-23 19:03:36.148 | 57.27.020.592 I slot update_slots: id  0 | task 26280 | Checking checkpoint with [40187, 40187] against 36189...
2026-05-23 19:03:36.148 | 57.27.020.594 I slot update_slots: id  0 | task 26280 | Checking checkpoint with [40084, 40084] against 36189...
2026-05-23 19:03:36.148 | 57.27.020.595 I slot update_slots: id  0 | task 26280 | Checking checkpoint with [39975, 39975] against 36189...
2026-05-23 19:03:36.148 | 57.27.020.596 I slot update_slots: id  0 | task 26280 | Checking checkpoint with [37772, 37772] against 36189...
2026-05-23 19:03:36.148 | 57.27.020.597 I slot update_slots: id  0 | task 26280 | Checking checkpoint with [37260, 37260] against 36189...
2026-05-23 19:03:36.148 | 57.27.020.597 I slot update_slots: id  0 | task 26280 | Checking checkpoint with [36246, 36246] against 36189...
2026-05-23 19:03:36.148 | 57.27.020.598 I slot update_slots: id  0 | task 26280 | Checking checkpoint with [35734, 35734] against 36189...
2026-05-23 19:03:36.246 | 57.27.118.061 W slot update_slots: id  0 | task 26280 | restored context checkpoint (pos_min = 35734, pos_max = 35734, n_tokens = 35735, n_past = 35735, size = 224.465 MiB)
2026-05-23 19:03:36.246 | 57.27.118.089 W slot update_slots: id  0 | task 26280 | erased invalidated context checkpoint (pos_min = 36246, pos_max = 36246, n_tokens = 36247, n_swa = 0, pos_next = 35735, size = 225.537 MiB)
2026-05-23 19:03:36.260 | 57.27.132.022 W slot update_slots: id  0 | task 26280 | erased invalidated context checkpoint (pos_min = 37260, pos_max = 37260, n_tokens = 37261, n_swa = 0, pos_next = 35735, size = 227.661 MiB)
2026-05-23 19:03:36.274 | 57.27.146.078 W slot update_slots: id  0 | task 26280 | erased invalidated context checkpoint (pos_min = 37772, pos_max = 37772, n_tokens = 37773, n_swa = 0, pos_next = 35735, size = 228.733 MiB)
2026-05-23 19:03:36.288 | 57.27.160.172 W slot update_slots: id  0 | task 26280 | erased invalidated context checkpoint (pos_min = 39975, pos_max = 39975, n_tokens = 39976, n_swa = 0, pos_next = 35735, size = 233.347 MiB)
2026-05-23 19:03:36.302 | 57.27.174.635 W slot update_slots: id  0 | task 26280 | erased invalidated context checkpoint (pos_min = 40084, pos_max = 40084, n_tokens = 40085, n_swa = 0, pos_next = 35735, size = 233.575 MiB)
2026-05-23 19:03:36.317 | 57.27.189.341 W slot update_slots: id  0 | task 26280 | erased invalidated context checkpoint (pos_min = 40187, pos_max = 40187, n_tokens = 40188, n_swa = 0, pos_next = 35735, size = 233.791 MiB)
2026-05-23 19:03:36.331 | 57.27.203.726 W slot update_slots: id  0 | task 26280 | erased invalidated context checkpoint (pos_min = 40367, pos_max = 40367, n_tokens = 40368, n_swa = 0, pos_next = 35735, size = 234.168 MiB)
2026-05-23 19:03:36.346 | 57.27.218.137 W slot update_slots: id  0 | task 26280 | erased invalidated context checkpoint (pos_min = 42026, pos_max = 42026, n_tokens = 42027, n_swa = 0, pos_next = 35735, size = 237.642 MiB)
2026-05-23 19:03:36.361 | 57.27.232.939 W slot update_slots: id  0 | task 26280 | erased invalidated context checkpoint (pos_min = 42538, pos_max = 42538, n_tokens = 42539, n_swa = 0, pos_next = 35735, size = 238.714 MiB)
2026-05-23 19:03:36.375 | 57.27.247.648 W slot update_slots: id  0 | task 26280 | erased invalidated context checkpoint (pos_min = 42732, pos_max = 42732, n_tokens = 42733, n_swa = 0, pos_next = 35735, size = 239.121 MiB)
2026-05-23 19:03:36.390 | 57.27.262.566 W slot update_slots: id  0 | task 26280 | erased invalidated context checkpoint (pos_min = 42884, pos_max = 42884, n_tokens = 42885, n_swa = 0, pos_next = 35735, size = 239.439 MiB)
2026-05-23 19:03:36.405 | 57.27.277.428 W slot update_slots: id  0 | task 26280 | erased invalidated context checkpoint (pos_min = 43051, pos_max = 43051, n_tokens = 43052, n_swa = 0, pos_next = 35735, size = 239.789 MiB)
2026-05-23 19:03:36.420 | 57.27.292.681 W slot update_slots: id  0 | task 26280 | erased invalidated context checkpoint (pos_min = 43178, pos_max = 43178, n_tokens = 43179, n_swa = 0, pos_next = 35735, size = 240.055 MiB)
2026-05-23 19:03:36.435 | 57.27.307.654 W slot update_slots: id  0 | task 26280 | erased invalidated context checkpoint (pos_min = 43411, pos_max = 43411, n_tokens = 43412, n_swa = 0, pos_next = 35735, size = 240.543 MiB)
2026-05-23 19:03:36.451 | 57.27.322.806 W slot update_slots: id  0 | task 26280 | erased invalidated context checkpoint (pos_min = 43579, pos_max = 43579, n_tokens = 43580, n_swa = 0, pos_next = 35735, size = 240.894 MiB)
2026-05-23 19:03:36.465 | 57.27.337.673 W slot update_slots: id  0 | task 26280 | erased invalidated context checkpoint (pos_min = 43712, pos_max = 43712, n_tokens = 43713, n_swa = 0, pos_next = 35735, size = 241.173 MiB)
2026-05-23 19:03:36.480 | 57.27.352.701 W slot update_slots: id  0 | task 26280 | erased invalidated context checkpoint (pos_min = 43814, pos_max = 43814, n_tokens = 43815, n_swa = 0, pos_next = 35735, size = 241.387 MiB)
2026-05-23 19:03:39.458 | 57.30.330.817 I slot print_timing: id  0 | task 26280 | prompt processing, n_tokens =   6144, progress = 0.96, t =   3.81 s / 1613.41 tokens per second
2026-05-23 19:03:40.121 | 57.30.993.180 I slot print_timing: id  0 | task 26280 | prompt processing, n_tokens =   7287, progress = 0.99, t =   4.47 s / 1630.04 tokens per second
2026-05-23 19:03:40.395 | 57.31.267.146 I slot create_check: id  0 | task 26280 | created context checkpoint 9 of 32 (pos_min = 43021, pos_max = 43021, n_tokens = 43022, size = 239.726 MiB)
2026-05-23 19:03:40.683 | 57.31.555.780 I slot print_timing: id  0 | task 26280 | prompt processing, n_tokens =   7799, progress = 1.00, t =   5.03 s / 1549.56 tokens per second
2026-05-23 19:03:40.983 | 57.31.854.951 I slot create_check: id  0 | task 26280 | created context checkpoint 10 of 32 (pos_min = 43533, pos_max = 43533, n_tokens = 43534, size = 240.798 MiB)
2026-05-23 19:03:41.408 | 57.32.280.098 I reasoning-budget: deactivated (natural end)
2026-05-23 19:03:42.303 | 57.33.175.808 I slot print_timing: id  0 | task 26280 | n_decoded =    101, tg =  78.84 t/s
2026-05-23 19:03:43.662 | 57.34.534.434 I slot print_timing: id  0 | task 26280 | 
2026-05-23 19:03:43.662 | prompt eval time =    5371.78 ms /  7803 tokens (    0.69 ms per token,  1452.59 tokens per second)
2026-05-23 19:03:43.662 |        eval time =    3141.18 ms /   245 tokens (   12.82 ms per token,    78.00 tokens per second)
2026-05-23 19:03:43.662 |       total time =    8512.96 ms /  8048 tokens
2026-05-23 19:03:43.662 | draft acceptance rate = 0.79787 (  150 accepted /   188 generated)
2026-05-23 19:03:43.662 | 57.34.534.467 I statistics draft-mtp: #calls(b,g,a) = 103 25933 30166, #gen drafts = 30166, #acc drafts = 27184, #gen tokens = 60332, #acc tokens = 51743, dur(b,g,a) = 0.176, 135046.401, 66.181 ms
2026-05-23 19:03:43.663 | 57.34.535.801 I slot      release: id  0 | task 26280 | stop processing: n_tokens = 43782, truncated = 0
2026-05-23 19:03:43.663 | 57.34.535.889 I srv  update_slots: all slots are idle
2026-05-23 19:03:43.929 | 57.34.801.015 I srv  params_from_: Chat format: peg-native
2026-05-23 19:03:43.930 | 57.34.802.364 I slot get_availabl: id  0 | task -1 | selected slot by LCP similarity, sim_best = 0.991 (> 0.100 thold), f_keep = 1.000
2026-05-23 19:03:43.931 | 57.34.803.185 I reasoning-budget: activated, budget=2147483647 tokens
2026-05-23 19:03:43.931 | 57.34.803.284 I slot launch_slot_: id  0 | task 26381 | processing task, is_child = 0
2026-05-23 19:03:44.224 | 57.35.096.720 I slot create_check: id  0 | task 26381 | created context checkpoint 11 of 32 (pos_min = 43781, pos_max = 43781, n_tokens = 43782, size = 241.317 MiB)
2026-05-23 19:03:44.748 | 57.35.620.243 I slot create_check: id  0 | task 26381 | created context checkpoint 12 of 32 (pos_min = 44157, pos_max = 44157, n_tokens = 44158, size = 242.105 MiB)
2026-05-23 19:03:45.913 | 57.36.785.018 I reasoning-budget: deactivated (natural end)
2026-05-23 19:03:46.246 | 57.37.118.594 I slot print_timing: id  0 | task 26381 | n_decoded =    102, tg =  69.89 t/s
2026-05-23 19:03:48.747 | 57.39.619.799 I slot print_timing: id  0 | task 26381 | n_decoded =    305, tg =  68.38 t/s
2026-05-23 19:03:51.752 | 57.42.624.861 I slot print_timing: id  0 | task 26381 | n_decoded =    511, tg =  68.45 t/s
2026-05-23 19:03:53.364 | 57.44.236.313 I slot print_timing: id  0 | task 26381 | 
2026-05-23 19:03:53.364 | prompt eval time =     855.71 ms /   380 tokens (    2.25 ms per token,   444.07 tokens per second)
2026-05-23 19:03:53.364 |        eval time =    9577.94 ms /   692 tokens (   13.84 ms per token,    72.25 tokens per second)
2026-05-23 19:03:53.364 |       total time =   10433.66 ms /  1072 tokens
2026-05-23 19:03:53.364 | draft acceptance rate = 0.71228 (  406 accepted /   570 generated)
2026-05-23 19:03:53.364 | 57.44.236.346 I statistics draft-mtp: #calls(b,g,a) = 104 26218 30451, #gen drafts = 30451, #acc drafts = 27406, #gen tokens = 60902, #acc tokens = 52149, dur(b,g,a) = 0.177, 136391.891, 66.761 ms
2026-05-23 19:03:53.365 | 57.44.237.524 I slot      release: id  0 | task 26381 | stop processing: n_tokens = 44853, truncated = 0
2026-05-23 19:03:53.365 | 57.44.237.596 I srv  update_slots: all slots are idle
2026-05-23 19:03:53.487 | 57.44.359.225 I srv  params_from_: Chat format: peg-native
2026-05-23 19:03:53.488 | 57.44.360.360 I slot get_availabl: id  0 | task -1 | selected slot by LCP similarity, sim_best = 0.356 (> 0.100 thold), f_keep = 0.056
2026-05-23 19:03:53.488 | 57.44.360.380 I srv  get_availabl: updating prompt cache
2026-05-23 19:03:53.490 | 57.44.362.326 W srv   prompt_save:  - saving prompt with length 44853, total state size = 1733.676 MiB (draft: 93.934 MiB)
2026-05-23 19:03:57.955 | 57.48.827.274 I srv          load:  - looking for better prompt, base f_keep = 0.056, sim = 0.356
2026-05-23 19:03:57.955 | 57.48.827.307 W srv        update:  - cache size limit reached, removing oldest entry (size = 4359.024 MiB)
2026-05-23 19:03:58.224 | 57.49.096.630 I srv        update:  - cache state: 1 prompts, 4271.250 MiB (limits: 8192.000 MiB, 131072 tokens, 131072 est)
2026-05-23 19:03:58.224 | 57.49.096.653 I srv        update:    - prompt 0x63d3aef62a60:   44853 tokens, checkpoints: 12,  4271.250 MiB
2026-05-23 19:03:58.224 | 57.49.096.655 I srv  get_availabl: prompt cache update took 5237.93 ms
2026-05-23 19:03:58.225 | 57.49.097.334 I reasoning-budget: activated, budget=2147483647 tokens
2026-05-23 19:03:58.225 | 57.49.097.444 I slot launch_slot_: id  0 | task 26669 | processing task, is_child = 0
2026-05-23 19:03:58.225 | 57.49.097.477 W slot update_slots: id  0 | task 26669 | n_past = 2504, slot.prompt.tokens.size() = 44853, seq_id = 0, pos_min = 44852, n_swa = 0
2026-05-23 19:03:58.225 | 57.49.097.478 I slot update_slots: id  0 | task 26669 | Checking checkpoint with [44157, 44157] against 2504...
2026-05-23 19:03:58.225 | 57.49.097.479 I slot update_slots: id  0 | task 26669 | Checking checkpoint with [43781, 43781] against 2504...
2026-05-23 19:03:58.225 | 57.49.097.480 I slot update_slots: id  0 | task 26669 | Checking checkpoint with [43533, 43533] against 2504...
2026-05-23 19:03:58.225 | 57.49.097.481 I slot update_slots: id  0 | task 26669 | Checking checkpoint with [43021, 43021] against 2504...
2026-05-23 19:03:58.225 | 57.49.097.481 I slot update_slots: id  0 | task 26669 | Checking checkpoint with [35734, 35734] against 2504...
2026-05-23 19:03:58.225 | 57.49.097.481 I slot update_slots: id  0 | task 26669 | Checking checkpoint with [33936, 33936] against 2504...
2026-05-23 19:03:58.225 | 57.49.097.482 I slot update_slots: id  0 | task 26669 | Checking checkpoint with [25744, 25744] against 2504...
2026-05-23 19:03:58.225 | 57.49.097.482 I slot update_slots: id  0 | task 26669 | Checking checkpoint with [20657, 20657] against 2504...
2026-05-23 19:03:58.225 | 57.49.097.483 I slot update_slots: id  0 | task 26669 | Checking checkpoint with [19846, 19846] against 2504...
2026-05-23 19:03:58.225 | 57.49.097.483 I slot update_slots: id  0 | task 26669 | Checking checkpoint with [19334, 19334] against 2504...
2026-05-23 19:03:58.225 | 57.49.097.484 I slot update_slots: id  0 | task 26669 | Checking checkpoint with [16383, 16383] against 2504...
2026-05-23 19:03:58.225 | 57.49.097.484 I slot update_slots: id  0 | task 26669 | Checking checkpoint with [8191, 8191] against 2504...
2026-05-23 19:03:58.225 | 57.49.097.485 W slot update_slots: id  0 | task 26669 | forcing full prompt re-processing due to lack of cache data (likely due to SWA or hybrid/recurrent memory, see https://github.com/ggml-org/llama.cpp/pull/13194#issuecomment-2868343055)
2026-05-23 19:03:58.225 | 57.49.097.486 W slot update_slots: id  0 | task 26669 | erased invalidated context checkpoint (pos_min = 8191, pos_max = 8191, n_tokens = 8192, n_swa = 0, pos_next = 0, size = 166.782 MiB)
2026-05-23 19:03:58.236 | 57.49.108.402 W slot update_slots: id  0 | task 26669 | erased invalidated context checkpoint (pos_min = 16383, pos_max = 16383, n_tokens = 16384, n_swa = 0, pos_next = 0, size = 183.939 MiB)
2026-05-23 19:03:58.246 | 57.49.118.498 W slot update_slots: id  0 | task 26669 | erased invalidated context checkpoint (pos_min = 19334, pos_max = 19334, n_tokens = 19335, n_swa = 0, pos_next = 0, size = 190.119 MiB)
2026-05-23 19:03:58.256 | 57.49.128.255 W slot update_slots: id  0 | task 26669 | erased invalidated context checkpoint (pos_min = 19846, pos_max = 19846, n_tokens = 19847, n_swa = 0, pos_next = 0, size = 191.191 MiB)
2026-05-23 19:03:58.268 | 57.49.140.759 W slot update_slots: id  0 | task 26669 | erased invalidated context checkpoint (pos_min = 20657, pos_max = 20657, n_tokens = 20658, n_swa = 0, pos_next = 0, size = 192.890 MiB)
2026-05-23 19:03:58.278 | 57.49.150.305 W slot update_slots: id  0 | task 26669 | erased invalidated context checkpoint (pos_min = 25744, pos_max = 25744, n_tokens = 25745, n_swa = 0, pos_next = 0, size = 203.543 MiB)
2026-05-23 19:03:58.293 | 57.49.165.338 W slot update_slots: id  0 | task 26669 | erased invalidated context checkpoint (pos_min = 33936, pos_max = 33936, n_tokens = 33937, n_swa = 0, pos_next = 0, size = 220.699 MiB)
2026-05-23 19:03:58.308 | 57.49.180.241 W slot update_slots: id  0 | task 26669 | erased invalidated context checkpoint (pos_min = 35734, pos_max = 35734, n_tokens = 35735, n_swa = 0, pos_next = 0, size = 224.465 MiB)
2026-05-23 19:03:58.322 | 57.49.194.425 W slot update_slots: id  0 | task 26669 | erased invalidated context checkpoint (pos_min = 43021, pos_max = 43021, n_tokens = 43022, n_swa = 0, pos_next = 0, size = 239.726 MiB)
2026-05-23 19:03:58.337 | 57.49.209.881 W slot update_slots: id  0 | task 26669 | erased invalidated context checkpoint (pos_min = 43533, pos_max = 43533, n_tokens = 43534, n_swa = 0, pos_next = 0, size = 240.798 MiB)
2026-05-23 19:03:58.353 | 57.49.225.027 W slot update_slots: id  0 | task 26669 | erased invalidated context checkpoint (pos_min = 43781, pos_max = 43781, n_tokens = 43782, n_swa = 0, pos_next = 0, size = 241.317 MiB)
2026-05-23 19:03:58.368 | 57.49.240.375 W slot update_slots: id  0 | task 26669 | erased invalidated context checkpoint (pos_min = 44157, pos_max = 44157, n_tokens = 44158, n_swa = 0, pos_next = 0, size = 242.105 MiB)
2026-05-23 19:04:00.831 | 57.51.703.607 I slot create_check: id  0 | task 26669 | created context checkpoint 1 of 32 (pos_min = 6518, pos_max = 6518, n_tokens = 6519, size = 163.279 MiB)
2026-05-23 19:04:01.032 | 57.51.904.423 I slot print_timing: id  0 | task 26669 | prompt processing, n_tokens =   7031, progress = 1.00, t =   3.03 s / 2323.89 tokens per second
2026-05-23 19:04:01.164 | 57.52.036.035 I slot create_check: id  0 | task 26669 | created context checkpoint 2 of 32 (pos_min = 7030, pos_max = 7030, n_tokens = 7031, size = 164.351 MiB)
2026-05-23 19:04:01.909 | 57.52.781.910 I reasoning-budget: deactivated (natural end)
2026-05-23 19:04:08.168 | 57.59.040.543 I slot print_timing: id  0 | task 26669 | n_decoded =    102, tg =  79.92 t/s
2026-05-23 19:04:02.887 | 57.53.759.521 I slot print_timing: id  0 | task 26669 | 
2026-05-23 19:04:02.887 | prompt eval time =    3193.26 ms /  7035 tokens (    0.45 ms per token,  2203.08 tokens per second)
2026-05-23 19:04:02.887 |        eval time =    1968.79 ms /   157 tokens (   12.54 ms per token,    79.74 tokens per second)
2026-05-23 19:04:02.887 |       total time =    5162.05 ms /  7192 tokens
2026-05-23 19:04:02.887 | draft acceptance rate = 0.63043 (   87 accepted /   138 generated)
2026-05-23 19:04:02.887 | 57.53.759.555 I statistics draft-mtp: #calls(b,g,a) = 105 26287 30520, #gen drafts = 30520, #acc drafts = 27458, #gen tokens = 61040, #acc tokens = 52236, dur(b,g,a) = 0.179, 136697.724, 66.905 ms
2026-05-23 19:04:02.888 | 57.53.759.961 I slot      release: id  0 | task 26669 | stop processing: n_tokens = 7191, truncated = 0
2026-05-23 19:04:02.888 | 57.53.760.031 I srv  update_slots: all slots are idle
2026-05-23 19:04:03.169 | 57.54.041.051 I srv  params_from_: Chat format: peg-native
2026-05-23 19:04:03.170 | 57.54.042.429 I slot get_availabl: id  2 | task -1 | selected slot by LRU, t_last = 2133456553
2026-05-23 19:04:03.170 | 57.54.042.461 I srv  get_availabl: updating prompt cache
2026-05-23 19:04:03.170 | 57.54.042.466 I srv          load:  - looking for better prompt, base f_keep = -1.000, sim = 0.000
2026-05-23 19:04:03.170 | 57.54.042.510 I srv          load:  - found better prompt with f_keep = 0.987, sim = 0.984
2026-05-23 19:04:03.555 | 57.54.427.368 I srv        update:  - cache state: 0 prompts, 0.000 MiB (limits: 8192.000 MiB, 131072 tokens, 8589934592 est)
2026-05-23 19:04:03.555 | 57.54.427.392 I srv  get_availabl: prompt cache update took 384.93 ms
2026-05-23 19:04:03.556 | 57.54.428.083 I reasoning-budget: activated, budget=2147483647 tokens
2026-05-23 19:04:03.556 | 57.54.428.236 I slot launch_slot_: id  2 | task 26745 | processing task, is_child = 0
2026-05-23 19:04:03.556 | 57.54.428.260 I slot slot_save_an: id  0 | task -1 | saving idle slot to prompt cache
2026-05-23 19:04:03.556 | 57.54.428.880 W srv   prompt_save:  - saving prompt with length 7191, total state size = 403.587 MiB (draft: 15.060 MiB)
2026-05-23 19:04:04.017 | 57.54.889.103 I slot prompt_clear: id  0 | task -1 | clearing prompt with 7191 tokens
2026-05-23 19:04:04.018 | 57.54.890.955 I srv        update:  - cache state: 1 prompts, 731.217 MiB (limits: 8192.000 MiB, 131072 tokens, 131072 est)
2026-05-23 19:04:04.018 | 57.54.890.979 I srv        update:    - prompt 0x63d3aef69790:    7191 tokens, checkpoints:  2,   731.217 MiB
2026-05-23 19:04:04.019 | 57.54.891.807 W slot update_slots: id  2 | task 26745 | n_past = 44282, slot.prompt.tokens.size() = 44853, seq_id = 2, pos_min = 44852, n_swa = 0
2026-05-23 19:04:04.019 | 57.54.891.830 I slot update_slots: id  2 | task 26745 | Checking checkpoint with [44157, 44157] against 44282...
2026-05-23 19:04:04.061 | 57.54.933.000 W slot update_slots: id  2 | task 26745 | restored context checkpoint (pos_min = 44157, pos_max = 44157, n_tokens = 44158, n_past = 44158, size = 242.105 MiB)
2026-05-23 19:04:04.439 | 57.55.311.430 I slot create_check: id  2 | task 26745 | created context checkpoint 13 of 32 (pos_min = 44502, pos_max = 44502, n_tokens = 44503, size = 242.827 MiB)
2026-05-23 19:04:04.960 | 57.55.832.193 I slot create_check: id  2 | task 26745 | created context checkpoint 14 of 32 (pos_min = 45014, pos_max = 45014, n_tokens = 45015, size = 243.900 MiB)
2026-05-23 19:04:05.831 | 57.56.702.993 I reasoning-budget: deactivated (natural end)
2026-05-23 19:04:06.306 | 57.57.178.088 I slot print_timing: id  2 | task 26745 | 
2026-05-23 19:04:06.306 | prompt eval time =     981.05 ms /   861 tokens (    1.14 ms per token,   877.63 tokens per second)
2026-05-23 19:04:06.306 |        eval time =    1305.07 ms /    88 tokens (   14.83 ms per token,    67.43 tokens per second)
2026-05-23 19:04:06.306 |       total time =    2286.12 ms /   949 tokens
2026-05-23 19:04:06.306 | draft acceptance rate = 0.65789 (   50 accepted /    76 generated)
2026-05-23 19:04:06.306 | 57.57.178.125 I statistics draft-mtp: #calls(b,g,a) = 106 26325 30558, #gen drafts = 30558, #acc drafts = 27487, #gen tokens = 61116, #acc tokens = 52286, dur(b,g,a) = 0.181, 136884.855, 66.983 ms
2026-05-23 19:04:06.307 | 57.57.179.393 I slot      release: id  2 | task 26745 | stop processing: n_tokens = 45107, truncated = 0
2026-05-23 19:04:06.307 | 57.57.179.465 I srv  update_slots: all slots are idle
```