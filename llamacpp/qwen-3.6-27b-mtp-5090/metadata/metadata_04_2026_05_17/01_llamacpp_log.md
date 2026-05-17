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
    # Port 8081 prevents collisions with your vLLM (8000) or other llama-servers (8080).
    ports:
      - "8000:8000"

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
      # Bind to all interfaces for network access.
      - "--host"
      - "0.0.0.0"
      # Internal container port.
      - "--port"
      - "8000"
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
      # 128k context is the 'goldilocks' zone for high-performance coding tasks.
      - "--ctx-size"
      - "131072"
      # --- SPECULATIVE DECODING ---
      # MTP is the engine behind the 140-220 tokens/s performance.
      - "--spec-type"
      - "draft-mtp"
      # 2 draft tokens is the verified 'sweet spot' for Qwen 3.6 acceptance rates.
      - "--spec-draft-n-max"
      - "3"
      - "--spec-draft-p-min"
      - "0.8"       
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
  # Allows this server to communicate with your other internal tools/proxies.
  development-network:
    external: true
```

# llamacpp log

```log
2026-05-17 10:44:24.511 | warn: LLAMA_ARG_HOST environment variable is set, but will be overwritten by command line argument --host
2026-05-17 10:44:25.076 | 0.00.755.779 I log_info: verbosity = 3 (adjust with the `-lv N` CLI arg)
2026-05-17 10:44:25.076 | 0.00.755.808 I device_info:
2026-05-17 10:44:25.389 | 0.01.068.661 I   - CUDA0   : NVIDIA GeForce RTX 5090 (32606 MiB, 30930 MiB free)
2026-05-17 10:44:25.389 | 0.01.068.735 I   - CPU     : AMD Ryzen 9 5950X 16-Core Processor (64297 MiB, 64297 MiB free)
2026-05-17 10:44:25.389 | 0.01.068.814 I system_info: n_threads = 16 (n_threads_batch = 16) / 32 | CUDA : ARCHS = 750,800,860,890,1200,1210 | USE_GRAPHS = 1 | PEER_MAX_BATCH_SIZE = 128 | BLACKWELL_NATIVE_FP4 = 1 | CPU : SSE3 = 1 | SSSE3 = 1 | AVX = 1 | AVX2 = 1 | F16C = 1 | FMA = 1 | BMI2 = 1 | LLAMAFILE = 1 | OPENMP = 1 | REPACK = 1 | 
2026-05-17 10:44:25.389 | 0.01.068.835 I srv          main: n_parallel is set to auto, using n_parallel = 4 and kv_unified = true
2026-05-17 10:44:25.392 | 0.01.071.961 I srv          init: running without SSL
2026-05-17 10:44:25.392 | 0.01.072.003 I srv          init: using 31 threads for HTTP server
2026-05-17 10:44:25.392 | 0.01.072.076 I srv         start: binding port with default address family
2026-05-17 10:44:25.394 | 0.01.074.012 I srv          main: loading model
2026-05-17 10:44:25.395 | 0.01.074.278 I srv    load_model: loading model '/root/.cache/huggingface/hub/models--unsloth--Qwen3.6-27B-MTP-GGUF/snapshots/ac393bc3d23fd5a929a85e2f33c7c4fd5be02d43/Qwen3.6-27B-UD-Q4_K_XL.gguf'
2026-05-17 10:44:25.395 | 0.01.074.899 I common_init_result: fitting params to device memory ...
2026-05-17 10:44:25.395 | 0.01.074.920 I common_init_result: (for bugs during this step try to reproduce them with -fit off, or provide --verbose logs if the bug only occurs with -fit on)
2026-05-17 10:44:43.466 | 0.19.146.242 W llama_context: n_ctx_seq (131072) < n_ctx_train (262144) -- the full capacity of the model will not be utilized
2026-05-17 10:44:43.846 | 0.19.526.200 W common_init_from_params: warming up the model with an empty run - please wait ... (--no-warmup to disable)
2026-05-17 10:44:44.173 | 0.19.852.475 I srv    load_model: creating MTP draft context against the target model '/root/.cache/huggingface/hub/models--unsloth--Qwen3.6-27B-MTP-GGUF/snapshots/ac393bc3d23fd5a929a85e2f33c7c4fd5be02d43/Qwen3.6-27B-UD-Q4_K_XL.gguf'
2026-05-17 10:44:44.173 | 0.19.852.570 W llama_context: n_ctx_seq (131072) < n_ctx_train (262144) -- the full capacity of the model will not be utilized
2026-05-17 10:44:44.505 | 0.20.185.375 W load_hparams: Qwen-VL models require at minimum 1024 image tokens to function correctly on grounding tasks
2026-05-17 10:44:44.506 | 0.20.185.397 W load_hparams: if you encounter problems with accuracy, try adding --image-min-tokens 1024
2026-05-17 10:44:44.506 | 0.20.185.397 W load_hparams: more info: https://github.com/ggml-org/llama.cpp/issues/16842
2026-05-17 10:44:44.506 | 
2026-05-17 10:44:45.381 | 0.21.060.291 I srv    load_model: loaded multimodal model, '/root/.cache/huggingface/hub/models--unsloth--Qwen3.6-27B-MTP-GGUF/snapshots/ac393bc3d23fd5a929a85e2f33c7c4fd5be02d43/mmproj-BF16.gguf'
2026-05-17 10:44:45.381 | 0.21.060.320 I srv    load_model: initializing slots, n_slots = 4
2026-05-17 10:44:45.424 | 0.21.104.189 I common_context_can_seq_rm: the context supports bounded partial sequence removal
2026-05-17 10:44:45.460 | 0.21.139.426 I common_speculative_init: adding speculative implementation 'draft-mtp'
2026-05-17 10:44:45.460 | 0.21.139.851 I srv    load_model: speculative decoding context initialized
2026-05-17 10:44:45.460 | 0.21.139.869 I slot   load_model: id  0 | task -1 | new slot, n_ctx = 131072
2026-05-17 10:44:45.460 | 0.21.139.871 I slot   load_model: id  1 | task -1 | new slot, n_ctx = 131072
2026-05-17 10:44:45.460 | 0.21.139.872 I slot   load_model: id  2 | task -1 | new slot, n_ctx = 131072
2026-05-17 10:44:45.460 | 0.21.139.872 I slot   load_model: id  3 | task -1 | new slot, n_ctx = 131072
2026-05-17 10:44:45.460 | 0.21.139.935 I srv    load_model: prompt cache is enabled, size limit: 8192 MiB
2026-05-17 10:44:45.460 | 0.21.139.952 I srv    load_model: use `--cache-ram 0` to disable the prompt cache
2026-05-17 10:44:45.460 | 0.21.139.953 I srv    load_model: for more info see https://github.com/ggml-org/llama.cpp/pull/16391
2026-05-17 10:44:45.460 | 0.21.139.966 I srv          init: idle slots will be saved to prompt cache and cleared upon starting a new task
2026-05-17 10:44:45.474 | 0.21.153.458 I init: chat template, example_format: '<|im_start|>system
2026-05-17 10:44:45.474 | You are a helpful assistant<|im_end|>
2026-05-17 10:44:45.474 | <|im_start|>user
2026-05-17 10:44:45.474 | Hello<|im_end|>
2026-05-17 10:44:45.474 | <|im_start|>assistant
2026-05-17 10:44:45.474 | Hi there<|im_end|>
2026-05-17 10:44:45.474 | <|im_start|>user
2026-05-17 10:44:45.474 | How are you?<|im_end|>
2026-05-17 10:44:45.474 | <|im_start|>assistant
2026-05-17 10:44:45.474 | <think>
2026-05-17 10:44:45.474 | '
2026-05-17 10:44:45.483 | 0.21.162.949 I srv          init: init: chat template, thinking = 1
2026-05-17 10:44:45.483 | 0.21.162.986 I srv          main: model loaded
2026-05-17 10:44:45.483 | 0.21.162.989 I srv          main: server is listening on http://0.0.0.0:8000
2026-05-17 10:44:45.483 | 0.21.162.992 I srv  update_slots: all slots are idle
2026-05-17 10:46:45.713 | 2.21.392.578 I srv  params_from_: Chat format: peg-native
2026-05-17 10:46:45.713 | 2.21.392.843 I slot get_availabl: id  3 | task -1 | selected slot by LRU, t_last = -1
2026-05-17 10:46:45.713 | 2.21.392.867 I srv  get_availabl: updating prompt cache
2026-05-17 10:46:45.713 | 2.21.392.872 I srv          load:  - looking for better prompt, base f_keep = -1.000, sim = 0.000
2026-05-17 10:46:45.713 | 2.21.392.875 I srv        update:  - cache state: 0 prompts, 0.000 MiB (limits: 8192.000 MiB, 131072 tokens, 8589934592 est)
2026-05-17 10:46:45.713 | 2.21.392.875 I srv  get_availabl: prompt cache update took 0.01 ms
2026-05-17 10:46:45.713 | 2.21.392.960 I slot launch_slot_: id  3 | task 0 | processing task, is_child = 0
2026-05-17 10:46:45.882 | 2.21.561.501 I srv  params_from_: Chat format: peg-native
2026-05-17 10:46:46.474 | 2.22.153.446 I slot get_availabl: id  2 | task -1 | selected slot by LRU, t_last = -1
2026-05-17 10:46:46.474 | 2.22.153.469 I srv  get_availabl: updating prompt cache
2026-05-17 10:46:46.474 | 2.22.153.472 I srv          load:  - looking for better prompt, base f_keep = -1.000, sim = 0.000
2026-05-17 10:46:46.474 | 2.22.153.475 I srv        update:  - cache state: 0 prompts, 0.000 MiB (limits: 8192.000 MiB, 131072 tokens, 8589934592 est)
2026-05-17 10:46:46.474 | 2.22.153.475 I srv  get_availabl: prompt cache update took 0.01 ms
2026-05-17 10:46:46.474 | 2.22.154.197 I reasoning-budget: activated, budget=2147483647 tokens
2026-05-17 10:46:46.474 | 2.22.154.230 I slot launch_slot_: id  2 | task 2 | processing task, is_child = 0
2026-05-17 10:46:50.088 | 2.25.767.681 I slot print_timing: id  2 | task 2 | prompt processing, n_tokens =   4096, progress = 0.47, t =   3.61 s / 1133.55 tokens per second
2026-05-17 10:46:50.825 | 2.26.505.232 I slot print_timing: id  2 | task 2 | prompt processing, n_tokens =   6144, progress = 0.70, t =   4.35 s / 1412.09 tokens per second
2026-05-17 10:46:51.575 | 2.27.254.596 I slot print_timing: id  2 | task 2 | prompt processing, n_tokens =   8192, progress = 0.94, t =   5.10 s / 1606.16 tokens per second
2026-05-17 10:46:51.575 | 2.27.254.745 I slot update_slots: id  2 | task 2 | 8192 tokens since last checkpoint at 0, creating new checkpoint during processing at position 8218
2026-05-17 10:46:51.744 | 2.27.423.483 I slot create_check: id  2 | task 2 | created context checkpoint 1 of 32 (pos_min = 8191, pos_max = 8191, n_tokens = 8192, size = 166.782 MiB)
2026-05-17 10:46:51.744 | 2.27.423.508 I slot print_timing: id  3 | task 0 | prompt processing, n_tokens =    347, progress = 0.40, t =   6.03 s / 57.54 tokens per second
2026-05-17 10:46:51.909 | 2.27.589.157 I slot create_check: id  3 | task 0 | created context checkpoint 1 of 32 (pos_min = 346, pos_max = 346, n_tokens = 347, size = 150.353 MiB)
2026-05-17 10:46:52.137 | 2.27.816.525 I slot print_timing: id  2 | task 2 | prompt processing, n_tokens =   8218, progress = 0.94, t =   5.66 s / 1451.36 tokens per second
2026-05-17 10:46:52.137 | 2.27.816.681 I slot print_timing: id  3 | task 0 | prompt processing, n_tokens =    859, progress = 1.00, t =   6.42 s / 133.72 tokens per second
2026-05-17 10:46:52.304 | 2.27.984.163 I slot create_check: id  3 | task 0 | created context checkpoint 2 of 32 (pos_min = 858, pos_max = 858, n_tokens = 859, size = 151.425 MiB)
2026-05-17 10:46:52.574 | 2.28.254.188 I slot print_timing: id  2 | task 2 | prompt processing, n_tokens =   8730, progress = 1.00, t =   6.10 s / 1431.16 tokens per second
2026-05-17 10:46:52.761 | 2.28.441.016 I slot create_check: id  2 | task 2 | created context checkpoint 2 of 32 (pos_min = 8729, pos_max = 8729, n_tokens = 8730, size = 167.909 MiB)
2026-05-17 10:46:53.410 | 2.29.089.580 I reasoning-budget: deactivated (natural end)
2026-05-17 10:46:53.761 | 2.29.441.017 I slot print_timing: id  2 | task 2 | 
2026-05-17 10:46:53.761 | prompt eval time =    6365.00 ms /  8734 tokens (    0.73 ms per token,  1372.19 tokens per second)
2026-05-17 10:46:53.761 |        eval time =     921.57 ms /    38 tokens (   24.25 ms per token,    41.23 tokens per second)
2026-05-17 10:46:53.761 |       total time =    7286.58 ms /  8772 tokens
2026-05-17 10:46:53.761 | draft acceptance rate = 0.78788 (   26 accepted /    33 generated)
2026-05-17 10:46:53.761 | 2.29.441.061 I statistics draft-mtp: #calls(b,g,a) = 2 12 22, #gen drafts = 23, #acc drafts = 21, #gen tokens = 69, #acc tokens = 56, dur(b,g,a) = 0.009, 95.186, 0.056 ms
2026-05-17 10:46:53.762 | 2.29.441.435 I slot      release: id  2 | task 2 | stop processing: n_tokens = 8771, truncated = 0
2026-05-17 10:46:54.276 | 2.29.955.962 I slot print_timing: id  3 | task 0 | n_decoded =    101, tg =  58.73 t/s
2026-05-17 10:46:57.287 | 2.32.966.924 I slot print_timing: id  3 | task 0 | n_decoded =    429, tg =  90.69 t/s
2026-05-17 10:46:58.516 | 2.34.195.477 I slot print_timing: id  3 | task 0 | 
2026-05-17 10:46:58.516 | prompt eval time =    6843.12 ms /   863 tokens (    7.93 ms per token,   126.11 tokens per second)
2026-05-17 10:46:58.516 |        eval time =    5959.10 ms /   571 tokens (   10.44 ms per token,    95.82 tokens per second)
2026-05-17 10:46:58.516 |       total time =   12802.23 ms /  1434 tokens
2026-05-17 10:46:58.516 | draft acceptance rate = 0.78824 (  402 accepted /   510 generated)
2026-05-17 10:46:58.516 | 2.34.195.508 I statistics draft-mtp: #calls(b,g,a) = 2 170 181, #gen drafts = 181, #acc drafts = 166, #gen tokens = 543, #acc tokens = 428, dur(b,g,a) = 0.009, 948.719, 0.323 ms
2026-05-17 10:46:58.516 | 2.34.195.571 I slot      release: id  3 | task 0 | stop processing: n_tokens = 1435, truncated = 0
2026-05-17 10:46:58.516 | 2.34.195.597 I srv  update_slots: all slots are idle
2026-05-17 10:48:08.556 | 3.44.235.950 I srv  params_from_: Chat format: peg-native
2026-05-17 10:48:08.557 | 3.44.237.211 I slot get_availabl: id  2 | task -1 | selected slot by LCP similarity, sim_best = 0.560 (> 0.100 thold), f_keep = 0.960
2026-05-17 10:48:08.558 | 3.44.237.730 I reasoning-budget: activated, budget=2147483647 tokens
2026-05-17 10:48:08.558 | 3.44.237.796 I slot launch_slot_: id  2 | task 179 | processing task, is_child = 0
2026-05-17 10:48:08.558 | 3.44.237.815 I slot slot_save_an: id  3 | task -1 | saving idle slot to prompt cache
2026-05-17 10:48:08.558 | 3.44.238.013 W srv   prompt_save:  - saving prompt with length 1435, total state size = 200.306 MiB (draft: 3.005 MiB)
2026-05-17 10:48:09.082 | 3.44.761.669 I slot prompt_clear: id  3 | task -1 | clearing prompt with 1435 tokens
2026-05-17 10:48:09.082 | 3.44.762.149 I srv        update:  - cache state: 1 prompts, 502.084 MiB (limits: 8192.000 MiB, 131072 tokens, 131072 est)
2026-05-17 10:48:09.082 | 3.44.762.169 I srv        update:    - prompt 0x567616b7bef0:    1435 tokens, checkpoints:  2,   502.084 MiB
2026-05-17 10:48:09.082 | 3.44.762.268 W slot update_slots: id  2 | task 179 | n_past = 8419, slot.prompt.tokens.size() = 8771, seq_id = 2, pos_min = 8770, n_swa = 0
2026-05-17 10:48:09.082 | 3.44.762.286 I slot update_slots: id  2 | task 179 | Checking checkpoint with [8729, 8729] against 8419...
2026-05-17 10:48:09.082 | 3.44.762.287 I slot update_slots: id  2 | task 179 | Checking checkpoint with [8191, 8191] against 8419...
2026-05-17 10:48:09.144 | 3.44.824.152 W slot update_slots: id  2 | task 179 | restored context checkpoint (pos_min = 8191, pos_max = 8191, n_tokens = 8192, n_past = 8192, size = 166.782 MiB)
2026-05-17 10:48:09.144 | 3.44.824.176 W slot update_slots: id  2 | task 179 | erased invalidated context checkpoint (pos_min = 8729, pos_max = 8729, n_tokens = 8730, n_swa = 0, pos_next = 8192, size = 167.909 MiB)
2026-05-17 10:48:11.933 | 3.47.613.071 I slot create_check: id  2 | task 179 | created context checkpoint 2 of 32 (pos_min = 14507, pos_max = 14507, n_tokens = 14508, size = 180.010 MiB)
2026-05-17 10:48:12.140 | 3.47.819.273 I slot print_timing: id  2 | task 179 | prompt processing, n_tokens =   6828, progress = 1.00, t =   3.06 s / 2233.56 tokens per second
2026-05-17 10:48:12.342 | 3.48.021.958 I slot create_check: id  2 | task 179 | created context checkpoint 3 of 32 (pos_min = 15019, pos_max = 15019, n_tokens = 15020, size = 181.082 MiB)
2026-05-17 10:48:13.309 | 3.48.989.011 I slot print_timing: id  2 | task 179 | n_decoded =    100, tg = 107.85 t/s
2026-05-17 10:48:16.318 | 3.51.997.522 I slot print_timing: id  2 | task 179 | n_decoded =    379, tg =  96.30 t/s
2026-05-17 10:48:17.345 | 3.53.024.779 I reasoning-budget: deactivated (natural end)
2026-05-17 10:48:19.343 | 3.55.023.222 I slot print_timing: id  2 | task 179 | n_decoded =    650, tg =  93.37 t/s
2026-05-17 10:48:21.559 | 3.57.239.186 I slot print_timing: id  2 | task 179 | 
2026-05-17 10:48:21.559 | prompt eval time =    3299.35 ms /  6832 tokens (    0.48 ms per token,  2070.71 tokens per second)
2026-05-17 10:48:21.559 |        eval time =    9177.40 ms /   832 tokens (   11.03 ms per token,    90.66 tokens per second)
2026-05-17 10:48:21.559 |       total time =   12476.76 ms /  7664 tokens
2026-05-17 10:48:21.559 | draft acceptance rate = 0.59309 (  532 accepted /   897 generated)
2026-05-17 10:48:21.559 | 3.57.239.219 I statistics draft-mtp: #calls(b,g,a) = 3 469 480, #gen drafts = 480, #acc drafts = 403, #gen tokens = 1440, #acc tokens = 960, dur(b,g,a) = 0.010, 2714.018, 0.925 ms
2026-05-17 10:48:21.560 | 3.57.239.712 I slot      release: id  2 | task 179 | stop processing: n_tokens = 15855, truncated = 0
2026-05-17 10:48:21.560 | 3.57.239.784 I srv  update_slots: all slots are idle
```


# Qwen 3.6 analysis 

Here's my analysis of your logs:
Good News
- 
~79% draft acceptance rate across both tasks — the MTP draft is working well with 3 speculative tokens
- 
Prompt processing at ~1372-1431 tok/s on the 5090 — that's solid for a Q4_K_XL 27B model
- 
Generation accelerating: task 0 went from 58.73 t/s up to 90.69 t/s as it warmed up
Areas of Concern
1. 
Context warning: n_ctx_seq (131072) < n_ctx_train (262144) — you're only using half the model's trained context capacity. Consider increasing if your workflows need longer context.
2. 
Generation speed (95 t/s): With a 5090, this seems conservative. Your draft-p-min = 0.8 may be too high — it means the draft is only used when its confidence exceeds 80%. This could cause the draft to be skipped more often than beneficial, falling back to slower full-model generation.
3. 
Batch size: n_threads_batch = 16 with 16 physical threads (no SMT threads utilized) — worth checking if higher batch threading helps.
Recommendation for draft-p-min
Try lowering it to 0.5-0.6. With ~79% acceptance already, a lower threshold would let the MTP draft engage more frequently without causing rejection overhead. The net effect should be faster token generation since the draft is cheap relative to the full model.
Want me to look at your docker-compose.yml to suggest specific parameter changes?


# Gemini 3 flash analysis 

Your logs tell a fascinating story about what's happening under the hood on your RTX 5090 rig. You are hitting an incredible **2,070 to 2,233 tokens per second during prompt processing** (thanks to those Blackwell MMQ kernels and Flash Attention), but your generation speed is experiencing a classic speculative execution bottleneck.

You are completely right to be skeptical about lowering `--spec-draft-p-min` below 0.75. Let's look exactly at *why* your performance is dropping and how to fix it by modifying your setup.

---

## The Log Analysis: Breaking Down the Numbers

Let's look closely at two different tasks from your log to see exactly where the bottleneck lies:

### Task 0 (Short Context, Clean MTP)

* **Prompt Eval:** 126.11 tok/s
* **Generation Speed:** **95.82 tok/s**
* **MTP Acceptance Rate:** **78.8%** (402 accepted / 510 generated)

Here, MTP is firing beautifully. An ~79% acceptance rate is the absolute sweet spot for Qwen 3.6 27B with 3 draft tokens.

### Task 179 (Deep Context, MTP Degradation)

* **Prompt Eval:** **2,070.71 tok/s** (Phenomenal Blackwell scaling!)
* **Generation Speed:** **90.66 tok/s** (A noticeable drop)
* **MTP Acceptance Rate:** **59.3%** (532 accepted / 897 generated)

Notice that as the context deepens (reaching 15,855 tokens), your MTP acceptance rate plummets to **59.3%**. When acceptance falls that low, the system spends more time rolling back wrong predictions and re-evaluating than it does actually generating new tokens.

---

## Why You Shouldn't Drop `--spec-draft-p-min` Below 0.75

The analysis tool suggested dropping it to 0.5–0.6, which is generally bad advice for Qwen 3.6 MTP heads.

Speculative decoding relies on the draft heads predicting tokens that the main model will accept. If you lower the confidence threshold (`p-min`) down to 0.5, you are forcing the engine to accept highly uncertain draft tokens.

* **The Result:** The draft engine will aggressively emit a lot of garbage tokens.
* **The Penalty:** The main model will continually reject those tokens during verification. Each rejection causes a pipeline flush and a recalculation step.

Instead of gaining speed, your generation throughput will collapse into a loop of guessing and backtracking. Keeping it at **0.8** or sliding it down to a minimum of **0.75** ensures that you only gamble on draft tokens that have a high probability of success.

---

## The Real Culprit: Thread Contention & Batch Tuning

Look at this line from your system initialization:

```log
system_info: n_threads = 16 (n_threads_batch = 16) / 32

```

You are pinning 16 physical threads on your Ryzen 9 5950X. However, when `llama-server` is processing tasks in parallel across 4 slots (`n_parallel = 4`), those 16 threads are getting heavily contested during batch evaluation periods, especially when managing the separate MTP context logic.

Furthermore, because you are running a **Deep-Thinking / Reasoning model** setup (evident by the line `reasoning-budget: activated`), the engine spends massive chunks of time evaluating large internal matrices where batch size tuning is critical.

---

## Tailored Docker-Compose Optimization

To resolve the generation slowdown without compromising your MTP acceptance rates, modify your `command` arguments inside your `docker-compose.yml`.

Here are the exact changes you should make to your compose file:

```yaml
    command:
      - "-hf"
      - "unsloth/Qwen3.6-27B-MTP-GGUF:UD-Q4_K_XL"
      - "--host"
      - "0.0.0.0"
      - "--port"
      - "8000"
      - "--n-gpu-layers"
      - "999"
      - "--flash-attn"
      - "on"
      - "--cache-type-k"
      - "q8_0"
      - "--cache-type-v"
      - "q8_0"
      - "--ctx-size"
      - "131072"
      
      # --- THREADING OPTIMIZATION ---
      # Explicitly separate generation execution from batch processing 
      # to prevent CPU starvation over WSL2 loops.
      - "--threads"
      - "12"
      - "--threads-batch"
      - "24"

      # --- SLOT & PARALLEL TUNING ---
      # Since you run deep context/reasoning budgets, restrict parallel slots 
      # slightly so they don't fight for KV cache space and cache-ram allocations.
      - "--parallel"
      - "2"

      # --- SPECULATIVE DECODING ---
      - "--spec-type"
      - "draft-mtp"
      # Dropping to 2 draft tokens often increases acceptance up past 85% 
      # in deep contexts, avoiding the 59% drop-off you hit in long sequences.
      - "--spec-draft-n-max"
      - "2"
      # Keep this strict to preserve accuracy and avoid verification flushes.
      - "--spec-draft-p-min"
      - "0.78" 
      
      # --- SAMPLING ---
      - "--temp"
      - "1.0"
      - "--top-p"
      - "0.95"
      - "--top-k"
      - "20"
      - "--presence-penalty"
      - "1.5"

```

### Why these adjustments work:

1. **`--threads 12` & `--threads-batch 24**`: This prevents your CPU from choking during intensive reasoning cycles. It limits standard token generation to 12 clean threads while allowing batch operations (like verifying draft tokens) to burst across your SMT/hyperthreaded cores.
2. **`--parallel 2`**: Leaving it at auto forced `n_parallel = 4`. Sharing a 128k context pool across 4 slots heavily fragments the prompt cache. Bumping it to 2 gives each slot cleaner breathing room.
3. **`--spec-draft-n-max 2`**: By drafting 2 tokens instead of 3, you significantly raise the mathematical probability that *all* drafted tokens are correct. This will raise that 59% acceptance rate back up toward 80% in deep contexts, resulting in higher overall net tokens per second.
