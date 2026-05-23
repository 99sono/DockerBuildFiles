# docker compsoe
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

# vllm log
```
2026-05-17 11:03:17.169 | warn: LLAMA_ARG_HOST environment variable is set, but will be overwritten by command line argument --host
2026-05-17 11:03:17.644 | 0.00.720.589 I log_info: verbosity = 3 (adjust with the `-lv N` CLI arg)
2026-05-17 11:03:17.644 | 0.00.720.620 I device_info:
2026-05-17 11:03:17.897 | 0.00.973.866 I   - CUDA0   : NVIDIA GeForce RTX 5090 (32606 MiB, 30930 MiB free)
2026-05-17 11:03:17.897 | 0.00.973.904 I   - CPU     : AMD Ryzen 9 5950X 16-Core Processor (64297 MiB, 64297 MiB free)
2026-05-17 11:03:17.897 | 0.00.973.981 I system_info: n_threads = 12 (n_threads_batch = 24) / 32 | CUDA : ARCHS = 750,800,860,890,1200,1210 | USE_GRAPHS = 1 | PEER_MAX_BATCH_SIZE = 128 | BLACKWELL_NATIVE_FP4 = 1 | CPU : SSE3 = 1 | SSSE3 = 1 | AVX = 1 | AVX2 = 1 | F16C = 1 | FMA = 1 | BMI2 = 1 | LLAMAFILE = 1 | OPENMP = 1 | REPACK = 1 | 
2026-05-17 11:03:17.897 | 0.00.973.999 I srv          main: n_parallel is set to auto, using n_parallel = 4 and kv_unified = true
2026-05-17 11:03:17.897 | 0.00.974.061 I srv          init: running without SSL
2026-05-17 11:03:17.897 | 0.00.974.084 I srv          init: using 31 threads for HTTP server
2026-05-17 11:03:17.898 | 0.00.974.169 I srv         start: binding port with default address family
2026-05-17 11:03:17.900 | 0.00.976.099 I srv          main: loading model
2026-05-17 11:03:17.900 | 0.00.976.125 I srv    load_model: loading model '/root/.cache/huggingface/hub/models--unsloth--Qwen3.6-27B-MTP-GGUF/snapshots/ac393bc3d23fd5a929a85e2f33c7c4fd5be02d43/Qwen3.6-27B-UD-Q4_K_XL.gguf'
2026-05-17 11:03:17.900 | 0.00.976.181 I common_init_result: fitting params to device memory ...
2026-05-17 11:03:17.900 | 0.00.976.198 I common_init_result: (for bugs during this step try to reproduce them with -fit off, or provide --verbose logs if the bug only occurs with -fit on)
2026-05-17 11:03:35.422 | 0.18.498.194 W llama_context: n_ctx_seq (131072) < n_ctx_train (262144) -- the full capacity of the model will not be utilized
2026-05-17 11:03:35.796 | 0.18.872.351 W common_init_from_params: warming up the model with an empty run - please wait ... (--no-warmup to disable)
2026-05-17 11:03:36.083 | 0.19.159.867 I srv    load_model: creating MTP draft context against the target model '/root/.cache/huggingface/hub/models--unsloth--Qwen3.6-27B-MTP-GGUF/snapshots/ac393bc3d23fd5a929a85e2f33c7c4fd5be02d43/Qwen3.6-27B-UD-Q4_K_XL.gguf'
2026-05-17 11:03:36.083 | 0.19.159.957 W llama_context: n_ctx_seq (131072) < n_ctx_train (262144) -- the full capacity of the model will not be utilized
2026-05-17 11:03:36.414 | 0.19.490.575 W load_hparams: Qwen-VL models require at minimum 1024 image tokens to function correctly on grounding tasks
2026-05-17 11:03:36.414 | 0.19.490.593 W load_hparams: if you encounter problems with accuracy, try adding --image-min-tokens 1024
2026-05-17 11:03:36.414 | 0.19.490.593 W load_hparams: more info: https://github.com/ggml-org/llama.cpp/issues/16842
2026-05-17 11:03:36.414 | 
2026-05-17 11:03:37.283 | 0.20.358.926 I srv    load_model: loaded multimodal model, '/root/.cache/huggingface/hub/models--unsloth--Qwen3.6-27B-MTP-GGUF/snapshots/ac393bc3d23fd5a929a85e2f33c7c4fd5be02d43/mmproj-BF16.gguf'
2026-05-17 11:03:37.283 | 0.20.358.952 I srv    load_model: initializing slots, n_slots = 4
2026-05-17 11:03:37.326 | 0.20.402.011 I common_context_can_seq_rm: the context supports bounded partial sequence removal
2026-05-17 11:03:37.359 | 0.20.435.501 I common_speculative_init: adding speculative implementation 'draft-mtp'
2026-05-17 11:03:37.359 | 0.20.435.921 I srv    load_model: speculative decoding context initialized
2026-05-17 11:03:37.359 | 0.20.435.941 I slot   load_model: id  0 | task -1 | new slot, n_ctx = 131072
2026-05-17 11:03:37.359 | 0.20.435.944 I slot   load_model: id  1 | task -1 | new slot, n_ctx = 131072
2026-05-17 11:03:37.359 | 0.20.435.945 I slot   load_model: id  2 | task -1 | new slot, n_ctx = 131072
2026-05-17 11:03:37.359 | 0.20.435.945 I slot   load_model: id  3 | task -1 | new slot, n_ctx = 131072
2026-05-17 11:03:37.359 | 0.20.436.010 I srv    load_model: prompt cache is enabled, size limit: 8192 MiB
2026-05-17 11:03:37.359 | 0.20.436.014 I srv    load_model: use `--cache-ram 0` to disable the prompt cache
2026-05-17 11:03:37.359 | 0.20.436.014 I srv    load_model: for more info see https://github.com/ggml-org/llama.cpp/pull/16391
2026-05-17 11:03:37.359 | 0.20.436.028 I srv          init: idle slots will be saved to prompt cache and cleared upon starting a new task
2026-05-17 11:03:37.372 | 0.20.448.905 I init: chat template, example_format: '<|im_start|>system
2026-05-17 11:03:37.372 | You are a helpful assistant<|im_end|>
2026-05-17 11:03:37.373 | <|im_start|>user
2026-05-17 11:03:37.373 | Hello<|im_end|>
2026-05-17 11:03:37.373 | <|im_start|>assistant
2026-05-17 11:03:37.373 | Hi there<|im_end|>
2026-05-17 11:03:37.373 | <|im_start|>user
2026-05-17 11:03:37.373 | How are you?<|im_end|>
2026-05-17 11:03:37.373 | <|im_start|>assistant
2026-05-17 11:03:37.373 | <think>
2026-05-17 11:03:37.373 | '
2026-05-17 11:03:37.382 | 0.20.458.283 I srv          init: init: chat template, thinking = 1
2026-05-17 11:03:37.382 | 0.20.458.331 I srv          main: model loaded
2026-05-17 11:03:37.382 | 0.20.458.335 I srv          main: server is listening on http://0.0.0.0:8000
2026-05-17 11:03:37.382 | 0.20.458.338 I srv  update_slots: all slots are idle
2026-05-17 11:04:12.961 | 0.56.037.355 I srv  params_from_: Chat format: peg-native
2026-05-17 11:04:12.962 | 0.56.038.618 I slot get_availabl: id  3 | task -1 | selected slot by LRU, t_last = -1
2026-05-17 11:04:12.962 | 0.56.038.634 I srv  get_availabl: updating prompt cache
2026-05-17 11:04:12.962 | 0.56.038.638 I srv          load:  - looking for better prompt, base f_keep = -1.000, sim = 0.000
2026-05-17 11:04:12.962 | 0.56.038.640 I srv        update:  - cache state: 0 prompts, 0.000 MiB (limits: 8192.000 MiB, 131072 tokens, 8589934592 est)
2026-05-17 11:04:12.962 | 0.56.038.640 I srv  get_availabl: prompt cache update took 0.01 ms
2026-05-17 11:04:12.963 | 0.56.039.301 I reasoning-budget: activated, budget=2147483647 tokens
2026-05-17 11:04:12.963 | 0.56.039.349 I slot launch_slot_: id  3 | task 0 | processing task, is_child = 0
2026-05-17 11:04:16.124 | 0.59.200.451 I slot print_timing: id  3 | task 0 | prompt processing, n_tokens =   2048, progress = 0.06, t =   3.16 s / 647.88 tokens per second
2026-05-17 11:04:16.863 | 0.59.939.382 I slot print_timing: id  3 | task 0 | prompt processing, n_tokens =   4096, progress = 0.12, t =   3.90 s / 1050.25 tokens per second
2026-05-17 11:04:17.602 | 1.00.678.845 I slot print_timing: id  3 | task 0 | prompt processing, n_tokens =   6144, progress = 0.19, t =   4.64 s / 1324.29 tokens per second
2026-05-17 11:04:18.346 | 1.01.422.781 I slot print_timing: id  3 | task 0 | prompt processing, n_tokens =   8192, progress = 0.25, t =   5.38 s / 1521.71 tokens per second
2026-05-17 11:04:18.346 | 1.01.422.976 I slot update_slots: id  3 | task 0 | 8192 tokens since last checkpoint at 0, creating new checkpoint during processing at position 10240
2026-05-17 11:04:18.519 | 1.01.595.392 I slot create_check: id  3 | task 0 | created context checkpoint 1 of 32 (pos_min = 8191, pos_max = 8191, n_tokens = 8192, size = 166.782 MiB)
2026-05-17 11:04:19.288 | 1.02.364.729 I slot print_timing: id  3 | task 0 | prompt processing, n_tokens =  10240, progress = 0.31, t =   6.33 s / 1618.88 tokens per second
2026-05-17 11:04:20.057 | 1.03.133.890 I slot print_timing: id  3 | task 0 | prompt processing, n_tokens =  12288, progress = 0.37, t =   7.09 s / 1732.04 tokens per second
2026-05-17 11:04:20.837 | 1.03.913.390 I slot print_timing: id  3 | task 0 | prompt processing, n_tokens =  14336, progress = 0.43, t =   7.87 s / 1820.67 tokens per second
2026-05-17 11:04:21.630 | 1.04.706.374 I slot print_timing: id  3 | task 0 | prompt processing, n_tokens =  16384, progress = 0.49, t =   8.67 s / 1890.39 tokens per second
2026-05-17 11:04:21.630 | 1.04.706.562 I slot update_slots: id  3 | task 0 | 8192 tokens since last checkpoint at 8192, creating new checkpoint during processing at position 18432
2026-05-17 11:04:21.836 | 1.04.912.145 I slot create_check: id  3 | task 0 | created context checkpoint 2 of 32 (pos_min = 16383, pos_max = 16383, n_tokens = 16384, size = 183.939 MiB)
2026-05-17 11:04:22.641 | 1.05.717.341 I slot print_timing: id  3 | task 0 | prompt processing, n_tokens =  18432, progress = 0.56, t =   9.68 s / 1904.53 tokens per second
2026-05-17 11:04:23.462 | 1.06.537.962 I slot print_timing: id  3 | task 0 | prompt processing, n_tokens =  20480, progress = 0.62, t =  10.50 s / 1950.74 tokens per second
2026-05-17 11:04:24.299 | 1.07.375.277 I slot print_timing: id  3 | task 0 | prompt processing, n_tokens =  22528, progress = 0.68, t =  11.34 s / 1987.31 tokens per second
2026-05-17 11:04:25.150 | 1.08.226.068 I slot print_timing: id  3 | task 0 | prompt processing, n_tokens =  24576, progress = 0.74, t =  12.19 s / 2016.62 tokens per second
2026-05-17 11:04:25.150 | 1.08.226.257 I slot update_slots: id  3 | task 0 | 8192 tokens since last checkpoint at 16384, creating new checkpoint during processing at position 26624
2026-05-17 11:04:25.376 | 1.08.452.823 I slot create_check: id  3 | task 0 | created context checkpoint 3 of 32 (pos_min = 24575, pos_max = 24575, n_tokens = 24576, size = 201.095 MiB)
2026-05-17 11:04:26.251 | 1.09.327.496 I slot print_timing: id  3 | task 0 | prompt processing, n_tokens =  26624, progress = 0.80, t =  13.29 s / 2003.59 tokens per second
2026-05-17 11:04:27.138 | 1.10.214.540 I slot print_timing: id  3 | task 0 | prompt processing, n_tokens =  28672, progress = 0.86, t =  14.18 s / 2022.69 tokens per second
2026-05-17 11:04:28.049 | 1.11.125.109 I slot print_timing: id  3 | task 0 | prompt processing, n_tokens =  30720, progress = 0.93, t =  15.09 s / 2036.36 tokens per second
2026-05-17 11:04:28.932 | 1.12.008.751 I slot print_timing: id  3 | task 0 | prompt processing, n_tokens =  32675, progress = 0.98, t =  15.97 s / 2046.10 tokens per second
2026-05-17 11:04:29.178 | 1.12.254.721 I slot create_check: id  3 | task 0 | created context checkpoint 4 of 32 (pos_min = 32674, pos_max = 32674, n_tokens = 32675, size = 218.056 MiB)
2026-05-17 11:04:29.397 | 1.12.473.679 I slot print_timing: id  3 | task 0 | prompt processing, n_tokens =  33187, progress = 1.00, t =  16.45 s / 2017.60 tokens per second
2026-05-17 11:04:29.650 | 1.12.726.836 I slot create_check: id  3 | task 0 | created context checkpoint 5 of 32 (pos_min = 33186, pos_max = 33186, n_tokens = 33187, size = 219.129 MiB)
2026-05-17 11:04:29.854 | 1.12.930.368 I slot print_timing: id  3 | task 0 | 
2026-05-17 11:04:29.854 | prompt eval time =   16743.45 ms / 33191 tokens (    0.50 ms per token,  1982.33 tokens per second)
2026-05-17 11:04:29.854 |        eval time =     161.86 ms /     8 tokens (   20.23 ms per token,    49.43 tokens per second)
2026-05-17 11:04:29.854 |       total time =   16905.31 ms / 33199 tokens
2026-05-17 11:04:29.854 | draft acceptance rate = 0.37500 (    3 accepted /     8 generated)
2026-05-17 11:04:29.854 | 1.12.930.414 I statistics draft-mtp: #calls(b,g,a) = 1 4 4, #gen drafts = 4, #acc drafts = 2, #gen tokens = 8, #acc tokens = 3, dur(b,g,a) = 0.006, 21.272, 0.010 ms
2026-05-17 11:04:29.855 | 1.12.931.215 I slot      release: id  3 | task 0 | stop processing: n_tokens = 33198, truncated = 0
2026-05-17 11:04:29.855 | 1.12.931.237 I srv  update_slots: all slots are idle
2026-05-17 11:04:57.330 | 1.40.406.770 I srv  params_from_: Chat format: peg-native
2026-05-17 11:04:57.331 | 1.40.407.986 I slot get_availabl: id  3 | task -1 | selected slot by LCP similarity, sim_best = 0.990 (> 0.100 thold), f_keep = 0.990
2026-05-17 11:04:57.332 | 1.40.408.576 I reasoning-budget: activated, budget=2147483647 tokens
2026-05-17 11:04:57.332 | 1.40.408.655 I slot launch_slot_: id  3 | task 23 | processing task, is_child = 0
2026-05-17 11:04:57.332 | 1.40.408.706 W slot update_slots: id  3 | task 23 | n_past = 32876, slot.prompt.tokens.size() = 33198, seq_id = 3, pos_min = 33197, n_swa = 0
2026-05-17 11:04:57.332 | 1.40.408.709 I slot update_slots: id  3 | task 23 | Checking checkpoint with [33186, 33186] against 32876...
2026-05-17 11:04:57.332 | 1.40.408.709 I slot update_slots: id  3 | task 23 | Checking checkpoint with [32674, 32674] against 32876...
2026-05-17 11:04:57.413 | 1.40.489.345 W slot update_slots: id  3 | task 23 | restored context checkpoint (pos_min = 32674, pos_max = 32674, n_tokens = 32675, n_past = 32675, size = 218.056 MiB)
2026-05-17 11:04:57.413 | 1.40.489.368 W slot update_slots: id  3 | task 23 | erased invalidated context checkpoint (pos_min = 33186, pos_max = 33186, n_tokens = 33187, n_swa = 0, pos_next = 32675, size = 219.129 MiB)
2026-05-17 11:04:57.974 | 1.41.050.157 I slot create_check: id  3 | task 23 | created context checkpoint 5 of 32 (pos_min = 33214, pos_max = 33214, n_tokens = 33215, size = 219.187 MiB)
2026-05-17 11:04:58.689 | 1.41.765.415 I reasoning-budget: deactivated (natural end)
2026-05-17 11:04:58.887 | 1.41.963.225 I slot print_timing: id  3 | task 23 | 
2026-05-17 11:04:58.887 | prompt eval time =     679.35 ms /   544 tokens (    1.25 ms per token,   800.77 tokens per second)
2026-05-17 11:04:58.887 |        eval time =     875.02 ms /    65 tokens (   13.46 ms per token,    74.28 tokens per second)
2026-05-17 11:04:58.887 |       total time =    1554.37 ms /   609 tokens
2026-05-17 11:04:58.887 | draft acceptance rate = 0.63793 (   37 accepted /    58 generated)
2026-05-17 11:04:58.887 | 1.41.963.257 I statistics draft-mtp: #calls(b,g,a) = 2 33 33, #gen drafts = 33, #acc drafts = 25, #gen tokens = 66, #acc tokens = 40, dur(b,g,a) = 0.007, 149.973, 0.074 ms
2026-05-17 11:04:58.888 | 1.41.964.211 I slot      release: id  3 | task 23 | stop processing: n_tokens = 33285, truncated = 0
2026-05-17 11:04:58.888 | 1.41.964.276 I srv  update_slots: all slots are idle
2026-05-17 11:05:10.292 | 1.53.368.661 I srv  params_from_: Chat format: peg-native
2026-05-17 11:05:10.293 | 1.53.369.941 I slot get_availabl: id  3 | task -1 | selected slot by LCP similarity, sim_best = 0.989 (> 0.100 thold), f_keep = 0.989
2026-05-17 11:05:10.294 | 1.53.370.712 I reasoning-budget: activated, budget=2147483647 tokens
2026-05-17 11:05:10.294 | 1.53.370.789 I slot launch_slot_: id  3 | task 56 | processing task, is_child = 0
2026-05-17 11:05:10.294 | 1.53.370.857 W slot update_slots: id  3 | task 56 | n_past = 32904, slot.prompt.tokens.size() = 33285, seq_id = 3, pos_min = 33284, n_swa = 0
2026-05-17 11:05:10.294 | 1.53.370.864 I slot update_slots: id  3 | task 56 | Checking checkpoint with [33214, 33214] against 32904...
2026-05-17 11:05:10.294 | 1.53.370.864 I slot update_slots: id  3 | task 56 | Checking checkpoint with [32674, 32674] against 32904...
2026-05-17 11:05:10.376 | 1.53.452.468 W slot update_slots: id  3 | task 56 | restored context checkpoint (pos_min = 32674, pos_max = 32674, n_tokens = 32675, n_past = 32675, size = 218.056 MiB)
2026-05-17 11:05:10.376 | 1.53.452.489 W slot update_slots: id  3 | task 56 | erased invalidated context checkpoint (pos_min = 33214, pos_max = 33214, n_tokens = 33215, n_swa = 0, pos_next = 32675, size = 219.187 MiB)
2026-05-17 11:05:10.959 | 1.54.035.323 I slot create_check: id  3 | task 56 | created context checkpoint 5 of 32 (pos_min = 33250, pos_max = 33250, n_tokens = 33251, size = 219.263 MiB)
2026-05-17 11:05:12.173 | 1.55.249.753 I slot print_timing: id  3 | task 56 | n_decoded =    100, tg =  84.80 t/s
2026-05-17 11:05:12.708 | 1.55.784.138 I reasoning-budget: deactivated (natural end)
2026-05-17 11:05:14.167 | 1.57.243.057 I slot print_timing: id  3 | task 56 | 
2026-05-17 11:05:14.167 | prompt eval time =     699.48 ms /   580 tokens (    1.21 ms per token,   829.18 tokens per second)
2026-05-17 11:05:14.167 |        eval time =    3172.59 ms /   272 tokens (   11.66 ms per token,    85.73 tokens per second)
2026-05-17 11:05:14.167 |       total time =    3872.07 ms /   852 tokens
2026-05-17 11:05:14.167 | draft acceptance rate = 0.74091 (  163 accepted /   220 generated)
2026-05-17 11:05:14.167 | 1.57.243.090 I statistics draft-mtp: #calls(b,g,a) = 3 143 143, #gen drafts = 143, #acc drafts = 117, #gen tokens = 286, #acc tokens = 203, dur(b,g,a) = 0.009, 629.836, 0.307 ms
2026-05-17 11:05:14.167 | 1.57.243.930 I slot      release: id  3 | task 56 | stop processing: n_tokens = 33528, truncated = 0
2026-05-17 11:05:14.168 | 1.57.243.996 I srv  update_slots: all slots are idle
2026-05-17 11:05:33.804 | 2.16.880.091 I srv  params_from_: Chat format: peg-native
2026-05-17 11:05:33.805 | 2.16.881.343 I slot get_availabl: id  3 | task -1 | selected slot by LCP similarity, sim_best = 0.985 (> 0.100 thold), f_keep = 0.982
2026-05-17 11:05:33.805 | 2.16.882.006 I reasoning-budget: activated, budget=2147483647 tokens
2026-05-17 11:05:33.806 | 2.16.882.090 I slot launch_slot_: id  3 | task 170 | processing task, is_child = 0
2026-05-17 11:05:33.806 | 2.16.882.140 W slot update_slots: id  3 | task 170 | n_past = 32940, slot.prompt.tokens.size() = 33528, seq_id = 3, pos_min = 33527, n_swa = 0
2026-05-17 11:05:33.806 | 2.16.882.159 I slot update_slots: id  3 | task 170 | Checking checkpoint with [33250, 33250] against 32940...
2026-05-17 11:05:33.806 | 2.16.882.159 I slot update_slots: id  3 | task 170 | Checking checkpoint with [32674, 32674] against 32940...
2026-05-17 11:05:33.888 | 2.16.964.474 W slot update_slots: id  3 | task 170 | restored context checkpoint (pos_min = 32674, pos_max = 32674, n_tokens = 32675, n_past = 32675, size = 218.056 MiB)
2026-05-17 11:05:33.888 | 2.16.964.499 W slot update_slots: id  3 | task 170 | erased invalidated context checkpoint (pos_min = 33250, pos_max = 33250, n_tokens = 33251, n_swa = 0, pos_next = 32675, size = 219.263 MiB)
2026-05-17 11:05:34.392 | 2.17.468.326 I slot create_check: id  3 | task 170 | created context checkpoint 5 of 32 (pos_min = 32909, pos_max = 32909, n_tokens = 32910, size = 218.549 MiB)
2026-05-17 11:05:34.866 | 2.17.942.733 I slot create_check: id  3 | task 170 | created context checkpoint 6 of 32 (pos_min = 33421, pos_max = 33421, n_tokens = 33422, size = 219.621 MiB)
2026-05-17 11:05:35.766 | 2.18.842.096 I reasoning-budget: deactivated (natural end)
2026-05-17 11:05:36.224 | 2.19.300.393 I slot print_timing: id  3 | task 170 | n_decoded =    100, tg =  75.70 t/s
2026-05-17 11:05:37.319 | 2.20.394.974 I slot print_timing: id  3 | task 170 | 
2026-05-17 11:05:37.319 | prompt eval time =    1097.17 ms /   751 tokens (    1.46 ms per token,   684.49 tokens per second)
2026-05-17 11:05:37.319 |        eval time =    2415.52 ms /   195 tokens (   12.39 ms per token,    80.73 tokens per second)
2026-05-17 11:05:37.319 |       total time =    3512.69 ms /   946 tokens
2026-05-17 11:05:37.319 | draft acceptance rate = 0.65476 (  110 accepted /   168 generated)
2026-05-17 11:05:37.319 | 2.20.395.006 I statistics draft-mtp: #calls(b,g,a) = 4 227 227, #gen drafts = 227, #acc drafts = 183, #gen tokens = 454, #acc tokens = 313, dur(b,g,a) = 0.010, 991.512, 0.486 ms
2026-05-17 11:05:37.319 | 2.20.395.861 I slot      release: id  3 | task 170 | stop processing: n_tokens = 33620, truncated = 0
2026-05-17 11:05:37.319 | 2.20.395.955 I srv  update_slots: all slots are idle
2026-05-17 11:05:55.763 | 2.38.839.376 I srv  params_from_: Chat format: peg-native
2026-05-17 11:05:55.764 | 2.38.840.630 I slot get_availabl: id  3 | task -1 | selected slot by LCP similarity, sim_best = 0.986 (> 0.100 thold), f_keep = 0.985
2026-05-17 11:05:55.765 | 2.38.841.194 I reasoning-budget: activated, budget=2147483647 tokens
2026-05-17 11:05:55.765 | 2.38.841.302 I slot launch_slot_: id  3 | task 258 | processing task, is_child = 0
2026-05-17 11:05:55.765 | 2.38.841.350 W slot update_slots: id  3 | task 258 | n_past = 33111, slot.prompt.tokens.size() = 33620, seq_id = 3, pos_min = 33619, n_swa = 0
2026-05-17 11:05:55.765 | 2.38.841.370 I slot update_slots: id  3 | task 258 | Checking checkpoint with [33421, 33421] against 33111...
2026-05-17 11:05:55.765 | 2.38.841.371 I slot update_slots: id  3 | task 258 | Checking checkpoint with [32909, 32909] against 33111...
2026-05-17 11:05:55.847 | 2.38.923.735 W slot update_slots: id  3 | task 258 | restored context checkpoint (pos_min = 32909, pos_max = 32909, n_tokens = 32910, n_past = 32910, size = 218.549 MiB)
2026-05-17 11:05:55.847 | 2.38.923.757 W slot update_slots: id  3 | task 258 | erased invalidated context checkpoint (pos_min = 33421, pos_max = 33421, n_tokens = 33422, n_swa = 0, pos_next = 32910, size = 219.621 MiB)
2026-05-17 11:05:56.299 | 2.39.375.086 I slot create_check: id  3 | task 258 | created context checkpoint 6 of 32 (pos_min = 33069, pos_max = 33069, n_tokens = 33070, size = 218.884 MiB)
2026-05-17 11:05:56.776 | 2.39.852.451 I slot create_check: id  3 | task 258 | created context checkpoint 7 of 32 (pos_min = 33581, pos_max = 33581, n_tokens = 33582, size = 219.956 MiB)
2026-05-17 11:05:57.320 | 2.40.395.999 I reasoning-budget: deactivated (natural end)
2026-05-17 11:05:58.126 | 2.41.202.500 I slot print_timing: id  3 | task 258 | n_decoded =    100, tg =  76.08 t/s
2026-05-17 11:06:01.122 | 2.44.198.751 I slot print_timing: id  3 | task 258 | n_decoded =    316, tg =  73.10 t/s
2026-05-17 11:06:02.840 | 2.45.916.322 I slot print_timing: id  3 | task 258 | 
2026-05-17 11:06:02.840 | prompt eval time =    1046.61 ms /   676 tokens (    1.55 ms per token,   645.89 tokens per second)
2026-05-17 11:06:02.840 |        eval time =    6040.23 ms /   446 tokens (   13.54 ms per token,    73.84 tokens per second)
2026-05-17 11:06:02.840 |       total time =    7086.85 ms /  1122 tokens
2026-05-17 11:06:02.840 | draft acceptance rate = 0.54953 (  233 accepted /   424 generated)
2026-05-17 11:06:02.840 | 2.45.916.354 I statistics draft-mtp: #calls(b,g,a) = 5 439 439, #gen drafts = 439, #acc drafts = 320, #gen tokens = 878, #acc tokens = 546, dur(b,g,a) = 0.012, 1916.222, 0.959 ms
2026-05-17 11:06:02.841 | 2.45.917.199 I slot      release: id  3 | task 258 | stop processing: n_tokens = 34031, truncated = 0
2026-05-17 11:06:02.841 | 2.45.917.281 I srv  update_slots: all slots are idle
2026-05-17 11:10:16.468 | 6.59.544.114 I srv  params_from_: Chat format: peg-native
2026-05-17 11:10:16.469 | 6.59.545.344 I slot get_availabl: id  3 | task -1 | selected slot by LCP similarity, sim_best = 0.870 (> 0.100 thold), f_keep = 0.978
2026-05-17 11:10:16.469 | 6.59.545.994 I reasoning-budget: activated, budget=2147483647 tokens
2026-05-17 11:10:16.469 | 6.59.546.083 I slot launch_slot_: id  3 | task 474 | processing task, is_child = 0
2026-05-17 11:10:16.470 | 6.59.546.132 W slot update_slots: id  3 | task 474 | n_past = 33271, slot.prompt.tokens.size() = 34031, seq_id = 3, pos_min = 34030, n_swa = 0
2026-05-17 11:10:16.470 | 6.59.546.151 I slot update_slots: id  3 | task 474 | Checking checkpoint with [33581, 33581] against 33271...
2026-05-17 11:10:16.470 | 6.59.546.151 I slot update_slots: id  3 | task 474 | Checking checkpoint with [33069, 33069] against 33271...
2026-05-17 11:10:16.553 | 6.59.629.867 W slot update_slots: id  3 | task 474 | restored context checkpoint (pos_min = 33069, pos_max = 33069, n_tokens = 33070, n_past = 33070, size = 218.884 MiB)
2026-05-17 11:10:16.553 | 6.59.629.890 W slot update_slots: id  3 | task 474 | erased invalidated context checkpoint (pos_min = 33581, pos_max = 33581, n_tokens = 33582, n_swa = 0, pos_next = 33070, size = 219.956 MiB)
2026-05-17 11:10:19.178 | 7.02.254.374 I slot create_check: id  3 | task 474 | created context checkpoint 7 of 32 (pos_min = 37736, pos_max = 37736, n_tokens = 37737, size = 228.658 MiB)
2026-05-17 11:10:19.679 | 7.02.755.376 I slot create_check: id  3 | task 474 | created context checkpoint 8 of 32 (pos_min = 38248, pos_max = 38248, n_tokens = 38249, size = 229.730 MiB)
2026-05-17 11:10:20.890 | 7.03.966.318 I slot print_timing: id  3 | task 474 | n_decoded =    100, tg =  85.06 t/s
2026-05-17 11:10:21.033 | 7.04.109.907 I reasoning-budget: deactivated (natural end)
2026-05-17 11:10:22.218 | 7.05.293.945 I slot print_timing: id  3 | task 474 | 
2026-05-17 11:10:22.218 | prompt eval time =    3244.48 ms /  5183 tokens (    0.63 ms per token,  1597.48 tokens per second)
2026-05-17 11:10:22.221 |        eval time =    2503.20 ms /   230 tokens (   10.88 ms per token,    91.88 tokens per second)
2026-05-17 11:10:22.221 |       total time =    5747.68 ms /  5413 tokens
2026-05-17 11:10:22.221 | draft acceptance rate = 0.84706 (  144 accepted /   170 generated)
2026-05-17 11:10:22.221 | 7.05.293.978 I statistics draft-mtp: #calls(b,g,a) = 6 524 524, #gen drafts = 524, #acc drafts = 397, #gen tokens = 1048, #acc tokens = 690, dur(b,g,a) = 0.013, 2275.189, 1.135 ms
2026-05-17 11:10:22.221 | 7.05.294.989 I slot      release: id  3 | task 474 | stop processing: n_tokens = 38482, truncated = 0
2026-05-17 11:10:22.221 | 7.05.295.060 I srv  update_slots: all slots are idle
2026-05-17 11:10:22.372 | 7.05.448.344 I srv  params_from_: Chat format: peg-native
2026-05-17 11:10:22.373 | 7.05.449.599 I slot get_availabl: id  3 | task -1 | selected slot by LCP similarity, sim_best = 0.995 (> 0.100 thold), f_keep = 1.000
2026-05-17 11:10:22.374 | 7.05.450.193 I reasoning-budget: activated, budget=2147483647 tokens
2026-05-17 11:10:22.374 | 7.05.450.269 I slot launch_slot_: id  3 | task 565 | processing task, is_child = 0
2026-05-17 11:10:22.624 | 7.05.700.505 I slot create_check: id  3 | task 565 | created context checkpoint 9 of 32 (pos_min = 38481, pos_max = 38481, n_tokens = 38482, size = 230.218 MiB)
2026-05-17 11:10:22.993 | 7.06.069.338 I slot create_check: id  3 | task 565 | created context checkpoint 10 of 32 (pos_min = 38675, pos_max = 38675, n_tokens = 38676, size = 230.624 MiB)
2026-05-17 11:10:23.364 | 7.06.440.409 I reasoning-budget: deactivated (natural end)
2026-05-17 11:10:23.922 | 7.06.998.349 I slot print_timing: id  3 | task 565 | 
2026-05-17 11:10:23.922 | prompt eval time =     653.88 ms /   198 tokens (    3.30 ms per token,   302.81 tokens per second)
2026-05-17 11:10:23.922 |        eval time =     894.01 ms /    83 tokens (   10.77 ms per token,    92.84 tokens per second)
2026-05-17 11:10:23.922 |       total time =    1547.89 ms /   281 tokens
2026-05-17 11:10:23.922 | draft acceptance rate = 0.88333 (   53 accepted /    60 generated)
2026-05-17 11:10:23.922 | 7.06.998.380 I statistics draft-mtp: #calls(b,g,a) = 7 554 554, #gen drafts = 554, #acc drafts = 424, #gen tokens = 1108, #acc tokens = 743, dur(b,g,a) = 0.015, 2404.503, 1.192 ms
2026-05-17 11:10:23.923 | 7.06.999.356 I slot      release: id  3 | task 565 | stop processing: n_tokens = 38763, truncated = 0
2026-05-17 11:10:23.923 | 7.06.999.414 I srv  update_slots: all slots are idle
2026-05-17 11:10:24.064 | 7.07.140.557 I srv  params_from_: Chat format: peg-native
2026-05-17 11:10:24.065 | 7.07.141.771 I slot get_availabl: id  3 | task -1 | selected slot by LCP similarity, sim_best = 0.939 (> 0.100 thold), f_keep = 1.000
2026-05-17 11:10:24.066 | 7.07.142.436 I reasoning-budget: activated, budget=2147483647 tokens
2026-05-17 11:10:24.066 | 7.07.142.518 I slot launch_slot_: id  3 | task 598 | processing task, is_child = 0
2026-05-17 11:10:25.334 | 7.08.410.270 I slot create_check: id  3 | task 598 | created context checkpoint 11 of 32 (pos_min = 40772, pos_max = 40772, n_tokens = 40773, size = 235.016 MiB)
2026-05-17 11:10:25.842 | 7.08.918.223 I slot create_check: id  3 | task 598 | created context checkpoint 12 of 32 (pos_min = 41284, pos_max = 41284, n_tokens = 41285, size = 236.088 MiB)
2026-05-17 11:10:27.112 | 7.10.188.491 I slot print_timing: id  3 | task 598 | n_decoded =    100, tg =  80.95 t/s
2026-05-17 11:10:29.619 | 7.12.695.026 I reasoning-budget: deactivated (natural end)
2026-05-17 11:10:30.124 | 7.13.200.514 I slot print_timing: id  3 | task 598 | n_decoded =    333, tg =  78.25 t/s
2026-05-17 11:10:33.125 | 7.16.201.238 I slot print_timing: id  3 | task 598 | n_decoded =    575, tg =  79.24 t/s
2026-05-17 11:10:36.133 | 7.19.209.772 I slot print_timing: id  3 | task 598 | n_decoded =    802, tg =  78.13 t/s
2026-05-17 11:10:39.143 | 7.22.219.213 I slot print_timing: id  3 | task 598 | n_decoded =   1034, tg =  77.90 t/s
2026-05-17 11:10:42.172 | 7.25.248.441 I slot print_timing: id  3 | task 598 | n_decoded =   1264, tg =  77.53 t/s
2026-05-17 11:10:45.185 | 7.28.261.054 I slot print_timing: id  3 | task 598 | n_decoded =   1495, tg =  77.40 t/s
2026-05-17 11:10:48.196 | 7.31.272.497 I slot print_timing: id  3 | task 598 | n_decoded =   1751, tg =  78.42 t/s
2026-05-17 11:10:48.282 | 7.31.358.086 I slot print_timing: id  3 | task 598 | 
2026-05-17 11:10:48.282 | prompt eval time =    1810.39 ms /  2526 tokens (    0.72 ms per token,  1395.28 tokens per second)
2026-05-17 11:10:48.282 |        eval time =   22413.05 ms /  1752 tokens (   12.79 ms per token,    78.17 tokens per second)
2026-05-17 11:10:48.282 |       total time =   24223.44 ms /  4278 tokens
2026-05-17 11:10:48.282 | draft acceptance rate = 0.67651 ( 1008 accepted /  1490 generated)
2026-05-17 11:10:48.282 | 7.31.358.120 I statistics draft-mtp: #calls(b,g,a) = 8 1299 1299, #gen drafts = 1299, #acc drafts = 997, #gen tokens = 2598, #acc tokens = 1751, dur(b,g,a) = 0.016, 5731.927, 2.756 ms
2026-05-17 11:10:48.283 | 7.31.359.180 I slot      release: id  3 | task 598 | stop processing: n_tokens = 43042, truncated = 0
2026-05-17 11:10:48.283 | 7.31.359.240 I srv  update_slots: all slots are idle
2026-05-17 11:11:11.133 | 7.54.209.512 I srv  params_from_: Chat format: peg-native
2026-05-17 11:11:11.134 | 7.54.210.803 I slot get_availabl: id  3 | task -1 | selected slot by LCP similarity, sim_best = 0.998 (> 0.100 thold), f_keep = 1.000
2026-05-17 11:11:11.135 | 7.54.211.576 I reasoning-budget: activated, budget=2147483647 tokens
2026-05-17 11:11:11.135 | 7.54.211.659 I slot launch_slot_: id  3 | task 1347 | processing task, is_child = 0
2026-05-17 11:11:11.425 | 7.54.501.413 I slot create_check: id  3 | task 1347 | created context checkpoint 13 of 32 (pos_min = 43041, pos_max = 43041, n_tokens = 43042, size = 239.768 MiB)
2026-05-17 11:11:11.842 | 7.54.918.616 I slot create_check: id  3 | task 1347 | created context checkpoint 14 of 32 (pos_min = 43144, pos_max = 43144, n_tokens = 43145, size = 239.983 MiB)
2026-05-17 11:11:12.873 | 7.55.949.585 I reasoning-budget: deactivated (natural end)
2026-05-17 11:11:13.189 | 7.56.265.339 I slot print_timing: id  3 | task 1347 | n_decoded =    100, tg =  76.37 t/s
2026-05-17 11:11:13.348 | 7.56.424.281 I slot print_timing: id  3 | task 1347 | 
2026-05-17 11:11:13.348 | prompt eval time =     744.02 ms /   107 tokens (    6.95 ms per token,   143.81 tokens per second)
2026-05-17 11:11:13.348 |        eval time =    1468.35 ms /   111 tokens (   13.23 ms per token,    75.59 tokens per second)
2026-05-17 11:11:13.348 |       total time =    2212.37 ms /   218 tokens
2026-05-17 11:11:13.348 | draft acceptance rate = 0.69565 (   64 accepted /    92 generated)
2026-05-17 11:11:13.348 | 7.56.424.317 I statistics draft-mtp: #calls(b,g,a) = 9 1345 1345, #gen drafts = 1345, #acc drafts = 1034, #gen tokens = 2690, #acc tokens = 1815, dur(b,g,a) = 0.018, 5948.754, 2.872 ms
2026-05-17 11:11:13.349 | 7.56.425.485 I slot      release: id  3 | task 1347 | stop processing: n_tokens = 43259, truncated = 0
2026-05-17 11:11:13.349 | 7.56.425.533 I srv  update_slots: all slots are idle
2026-05-17 11:11:56.438 | 8.39.514.381 I srv  params_from_: Chat format: peg-native
2026-05-17 11:11:56.439 | 8.39.515.602 I slot get_availabl: id  3 | task -1 | selected slot by LCP similarity, sim_best = 0.886 (> 0.100 thold), f_keep = 0.877
2026-05-17 11:11:56.440 | 8.39.516.210 I reasoning-budget: activated, budget=2147483647 tokens
2026-05-17 11:11:56.440 | 8.39.516.292 I slot launch_slot_: id  3 | task 1396 | processing task, is_child = 0
2026-05-17 11:11:56.440 | 8.39.516.341 W slot update_slots: id  3 | task 1396 | n_past = 37938, slot.prompt.tokens.size() = 43259, seq_id = 3, pos_min = 43258, n_swa = 0
2026-05-17 11:11:56.440 | 8.39.516.342 I slot update_slots: id  3 | task 1396 | Checking checkpoint with [43144, 43144] against 37938...
2026-05-17 11:11:56.440 | 8.39.516.343 I slot update_slots: id  3 | task 1396 | Checking checkpoint with [43041, 43041] against 37938...
2026-05-17 11:11:56.440 | 8.39.516.344 I slot update_slots: id  3 | task 1396 | Checking checkpoint with [41284, 41284] against 37938...
2026-05-17 11:11:56.440 | 8.39.516.344 I slot update_slots: id  3 | task 1396 | Checking checkpoint with [40772, 40772] against 37938...
2026-05-17 11:11:56.440 | 8.39.516.345 I slot update_slots: id  3 | task 1396 | Checking checkpoint with [38675, 38675] against 37938...
2026-05-17 11:11:56.440 | 8.39.516.345 I slot update_slots: id  3 | task 1396 | Checking checkpoint with [38481, 38481] against 37938...
2026-05-17 11:11:56.440 | 8.39.516.346 I slot update_slots: id  3 | task 1396 | Checking checkpoint with [38248, 38248] against 37938...
2026-05-17 11:11:56.440 | 8.39.516.347 I slot update_slots: id  3 | task 1396 | Checking checkpoint with [37736, 37736] against 37938...
2026-05-17 11:11:56.526 | 8.39.602.305 W slot update_slots: id  3 | task 1396 | restored context checkpoint (pos_min = 37736, pos_max = 37736, n_tokens = 37737, n_past = 37737, size = 228.658 MiB)
2026-05-17 11:11:56.526 | 8.39.602.330 W slot update_slots: id  3 | task 1396 | erased invalidated context checkpoint (pos_min = 38248, pos_max = 38248, n_tokens = 38249, n_swa = 0, pos_next = 37737, size = 229.730 MiB)
2026-05-17 11:11:56.539 | 8.39.615.167 W slot update_slots: id  3 | task 1396 | erased invalidated context checkpoint (pos_min = 38481, pos_max = 38481, n_tokens = 38482, n_swa = 0, pos_next = 37737, size = 230.218 MiB)
2026-05-17 11:11:56.552 | 8.39.628.073 W slot update_slots: id  3 | task 1396 | erased invalidated context checkpoint (pos_min = 38675, pos_max = 38675, n_tokens = 38676, n_swa = 0, pos_next = 37737, size = 230.624 MiB)
2026-05-17 11:11:56.564 | 8.39.640.953 W slot update_slots: id  3 | task 1396 | erased invalidated context checkpoint (pos_min = 40772, pos_max = 40772, n_tokens = 40773, n_swa = 0, pos_next = 37737, size = 235.016 MiB)
2026-05-17 11:11:56.578 | 8.39.654.163 W slot update_slots: id  3 | task 1396 | erased invalidated context checkpoint (pos_min = 41284, pos_max = 41284, n_tokens = 41285, n_swa = 0, pos_next = 37737, size = 236.088 MiB)
2026-05-17 11:11:56.591 | 8.39.667.534 W slot update_slots: id  3 | task 1396 | erased invalidated context checkpoint (pos_min = 43041, pos_max = 43041, n_tokens = 43042, n_swa = 0, pos_next = 37737, size = 239.768 MiB)
2026-05-17 11:11:56.604 | 8.39.680.989 W slot update_slots: id  3 | task 1396 | erased invalidated context checkpoint (pos_min = 43144, pos_max = 43144, n_tokens = 43145, n_swa = 0, pos_next = 37737, size = 239.983 MiB)
2026-05-17 11:11:59.398 | 8.42.474.593 I slot create_check: id  3 | task 1396 | created context checkpoint 8 of 32 (pos_min = 42301, pos_max = 42301, n_tokens = 42302, size = 238.218 MiB)
2026-05-17 11:11:59.658 | 8.42.734.089 I slot print_timing: id  3 | task 1396 | prompt processing, n_tokens =   5077, progress = 1.00, t =   3.22 s / 1575.26 tokens per second
2026-05-17 11:11:59.928 | 8.43.004.534 I slot create_check: id  3 | task 1396 | created context checkpoint 9 of 32 (pos_min = 42813, pos_max = 42813, n_tokens = 42814, size = 239.290 MiB)
2026-05-17 11:12:01.223 | 8.44.299.078 I slot print_timing: id  3 | task 1396 | n_decoded =    100, tg =  79.44 t/s
2026-05-17 11:12:01.713 | 8.44.789.782 I reasoning-budget: deactivated (natural end)
2026-05-17 11:12:04.226 | 8.47.302.373 I slot print_timing: id  3 | task 1396 | n_decoded =    341, tg =  80.01 t/s
2026-05-17 11:12:07.232 | 8.50.308.768 I slot print_timing: id  3 | task 1396 | n_decoded =    599, tg =  82.41 t/s
2026-05-17 11:12:10.234 | 8.53.310.656 I slot print_timing: id  3 | task 1396 | n_decoded =    857, tg =  83.44 t/s
2026-05-17 11:12:11.526 | 8.54.602.768 I slot print_timing: id  3 | task 1396 | 
2026-05-17 11:12:11.526 | prompt eval time =    3529.01 ms /  5081 tokens (    0.69 ms per token,  1439.78 tokens per second)
2026-05-17 11:12:11.526 |        eval time =   11562.48 ms /   958 tokens (   12.07 ms per token,    82.85 tokens per second)
2026-05-17 11:12:11.526 |       total time =   15091.49 ms /  6039 tokens
2026-05-17 11:12:11.526 | draft acceptance rate = 0.72692 (  567 accepted /   780 generated)
2026-05-17 11:12:11.526 | 8.54.602.797 I statistics draft-mtp: #calls(b,g,a) = 10 1735 1735, #gen drafts = 1735, #acc drafts = 1352, #gen tokens = 3470, #acc tokens = 2382, dur(b,g,a) = 0.020, 7656.182, 3.658 ms
2026-05-17 11:12:11.527 | 8.54.603.876 I slot      release: id  3 | task 1396 | stop processing: n_tokens = 43775, truncated = 0
2026-05-17 11:12:11.527 | 8.54.603.940 I srv  update_slots: all slots are idle
2026-05-17 11:12:33.870 | 9.16.946.105 I srv  params_from_: Chat format: peg-native
2026-05-17 11:12:33.871 | 9.16.947.331 I slot get_availabl: id  3 | task -1 | selected slot by LCP similarity, sim_best = 0.979 (> 0.100 thold), f_keep = 0.971
2026-05-17 11:12:33.871 | 9.16.947.972 I reasoning-budget: activated, budget=2147483647 tokens
2026-05-17 11:12:33.871 | 9.16.948.046 I slot launch_slot_: id  3 | task 1792 | processing task, is_child = 0
2026-05-17 11:12:33.872 | 9.16.948.100 W slot update_slots: id  3 | task 1792 | n_past = 42503, slot.prompt.tokens.size() = 43775, seq_id = 3, pos_min = 43774, n_swa = 0
2026-05-17 11:12:33.872 | 9.16.948.117 I slot update_slots: id  3 | task 1792 | Checking checkpoint with [42813, 42813] against 42503...
2026-05-17 11:12:33.872 | 9.16.948.118 I slot update_slots: id  3 | task 1792 | Checking checkpoint with [42301, 42301] against 42503...
2026-05-17 11:12:33.960 | 9.17.036.145 W slot update_slots: id  3 | task 1792 | restored context checkpoint (pos_min = 42301, pos_max = 42301, n_tokens = 42302, n_past = 42302, size = 238.218 MiB)
2026-05-17 11:12:33.960 | 9.17.036.169 W slot update_slots: id  3 | task 1792 | erased invalidated context checkpoint (pos_min = 42813, pos_max = 42813, n_tokens = 42814, n_swa = 0, pos_next = 42302, size = 239.290 MiB)
2026-05-17 11:12:34.647 | 9.17.723.113 I slot create_check: id  3 | task 1792 | created context checkpoint 9 of 32 (pos_min = 42907, pos_max = 42907, n_tokens = 42908, size = 239.487 MiB)
2026-05-17 11:12:35.107 | 9.18.183.067 I slot create_check: id  3 | task 1792 | created context checkpoint 10 of 32 (pos_min = 43419, pos_max = 43419, n_tokens = 43420, size = 240.559 MiB)
2026-05-17 11:12:36.429 | 9.19.505.849 I slot print_timing: id  3 | task 1792 | n_decoded =    102, tg =  79.25 t/s
2026-05-17 11:12:37.180 | 9.20.256.519 I slot print_timing: id  3 | task 1792 | 
2026-05-17 11:12:37.180 | prompt eval time =    1270.54 ms /  1122 tokens (    1.13 ms per token,   883.09 tokens per second)
2026-05-17 11:12:37.180 |        eval time =    2037.74 ms /   174 tokens (   11.71 ms per token,    85.39 tokens per second)
2026-05-17 11:12:37.180 |       total time =    3308.29 ms /  1296 tokens
2026-05-17 11:12:37.180 | draft acceptance rate = 0.79104 (  106 accepted /   134 generated)
2026-05-17 11:12:37.180 | 9.20.256.550 I statistics draft-mtp: #calls(b,g,a) = 11 1802 1802, #gen drafts = 1802, #acc drafts = 1409, #gen tokens = 3604, #acc tokens = 2488, dur(b,g,a) = 0.022, 7951.898, 3.790 ms
2026-05-17 11:12:37.181 | 9.20.257.667 I slot      release: id  3 | task 1792 | stop processing: n_tokens = 43597, truncated = 0
2026-05-17 11:12:37.181 | 9.20.257.726 I srv  update_slots: all slots are idle
2026-05-17 11:14:01.033 | 10.44.109.662 I srv  params_from_: Chat format: peg-native
2026-05-17 11:14:01.034 | 10.44.110.946 I slot get_availabl: id  3 | task -1 | selected slot by LCP similarity, sim_best = 0.998 (> 0.100 thold), f_keep = 0.995
2026-05-17 11:14:01.035 | 10.44.111.638 I reasoning-budget: activated, budget=2147483647 tokens
2026-05-17 11:14:01.035 | 10.44.111.728 I slot launch_slot_: id  3 | task 1863 | processing task, is_child = 0
2026-05-17 11:14:01.035 | 10.44.111.783 W slot update_slots: id  3 | task 1863 | n_past = 43362, slot.prompt.tokens.size() = 43597, seq_id = 3, pos_min = 43596, n_swa = 0
2026-05-17 11:14:01.035 | 10.44.111.784 I slot update_slots: id  3 | task 1863 | Checking checkpoint with [43419, 43419] against 43362...
2026-05-17 11:14:01.035 | 10.44.111.785 I slot update_slots: id  3 | task 1863 | Checking checkpoint with [42907, 42907] against 43362...
2026-05-17 11:14:01.127 | 10.44.203.282 W slot update_slots: id  3 | task 1863 | restored context checkpoint (pos_min = 42907, pos_max = 42907, n_tokens = 42908, n_past = 42908, size = 239.487 MiB)
2026-05-17 11:14:01.127 | 10.44.203.309 W slot update_slots: id  3 | task 1863 | erased invalidated context checkpoint (pos_min = 43419, pos_max = 43419, n_tokens = 43420, n_swa = 0, pos_next = 42908, size = 240.559 MiB)
2026-05-17 11:14:01.774 | 10.44.850.105 I slot create_check: id  3 | task 1863 | created context checkpoint 10 of 32 (pos_min = 43446, pos_max = 43446, n_tokens = 43447, size = 240.616 MiB)
2026-05-17 11:14:02.134 | 10.45.210.334 I reasoning-budget: deactivated (natural end)
2026-05-17 11:14:02.936 | 10.46.011.967 I slot print_timing: id  3 | task 1863 | n_decoded =    101, tg =  89.86 t/s
2026-05-17 11:14:05.937 | 10.49.013.905 I slot print_timing: id  3 | task 1863 | n_decoded =    394, tg =  95.49 t/s
2026-05-17 11:14:08.956 | 10.52.032.006 I slot print_timing: id  3 | task 1863 | n_decoded =    692, tg =  96.86 t/s
2026-05-17 11:14:11.962 | 10.55.038.437 I slot print_timing: id  3 | task 1863 | n_decoded =    967, tg =  95.27 t/s
2026-05-17 11:14:14.968 | 10.58.044.389 I slot print_timing: id  3 | task 1863 | n_decoded =   1234, tg =  93.79 t/s
2026-05-17 11:14:17.989 | 11.01.065.352 I slot print_timing: id  3 | task 1863 | n_decoded =   1468, tg =  90.74 t/s
2026-05-17 11:14:20.996 | 11.04.072.681 I slot print_timing: id  3 | task 1863 | n_decoded =   1713, tg =  89.29 t/s
2026-05-17 11:14:24.016 | 11.07.092.125 I slot print_timing: id  3 | task 1863 | n_decoded =   1962, tg =  88.36 t/s
2026-05-17 11:14:27.031 | 11.10.107.299 I slot print_timing: id  3 | task 1863 | n_decoded =   2200, tg =  87.23 t/s
2026-05-17 11:14:30.055 | 11.13.131.351 I slot print_timing: id  3 | task 1863 | n_decoded =   2452, tg =  86.81 t/s
2026-05-17 11:14:33.059 | 11.16.135.300 I slot print_timing: id  3 | task 1863 | n_decoded =   2689, tg =  86.05 t/s
2026-05-17 11:14:36.086 | 11.19.161.906 I slot print_timing: id  3 | task 1863 | n_decoded =   2944, tg =  85.89 t/s
2026-05-17 11:14:39.099 | 11.22.175.290 I slot print_timing: id  3 | task 1863 | n_decoded =   3201, tg =  85.84 t/s
2026-05-17 11:14:42.118 | 11.25.194.850 I slot print_timing: id  3 | task 1863 | n_decoded =   3483, tg =  86.41 t/s
2026-05-17 11:14:45.135 | 11.28.211.510 I slot print_timing: id  3 | task 1863 | n_decoded =   3729, tg =  86.07 t/s
2026-05-17 11:14:48.163 | 11.31.239.843 I slot print_timing: id  3 | task 1863 | n_decoded =   3998, tg =  86.25 t/s
2026-05-17 11:14:51.188 | 11.34.264.220 I slot print_timing: id  3 | task 1863 | n_decoded =   4272, tg =  86.51 t/s
2026-05-17 11:14:53.482 | 11.36.558.592 I slot print_timing: id  3 | task 1863 | 
2026-05-17 11:14:53.482 | prompt eval time =     776.06 ms /   543 tokens (    1.43 ms per token,   699.69 tokens per second)
2026-05-17 11:14:53.482 |        eval time =   51673.11 ms /  4479 tokens (   11.54 ms per token,    86.68 tokens per second)
2026-05-17 11:14:53.482 |       total time =   52449.17 ms /  5022 tokens
2026-05-17 11:14:53.482 | draft acceptance rate = 0.82721 ( 2791 accepted /  3374 generated)
2026-05-17 11:14:53.482 | 11.36.558.629 I statistics draft-mtp: #calls(b,g,a) = 12 3489 3489, #gen drafts = 3489, #acc drafts = 2901, #gen tokens = 6978, #acc tokens = 5279, dur(b,g,a) = 0.023, 15340.257, 7.211 ms
2026-05-17 11:14:53.483 | 11.36.559.948 I slot      release: id  3 | task 1863 | stop processing: n_tokens = 47929, truncated = 0
2026-05-17 11:14:53.484 | 11.36.560.051 I srv  update_slots: all slots are idle
2026-05-17 11:14:53.709 | 11.36.785.377 I srv  params_from_: Chat format: peg-native
2026-05-17 11:14:53.710 | 11.36.786.628 I slot get_availabl: id  3 | task -1 | selected slot by LCP similarity, sim_best = 1.000 (> 0.100 thold), f_keep = 1.000
2026-05-17 11:14:53.711 | 11.36.787.406 I reasoning-budget: activated, budget=2147483647 tokens
2026-05-17 11:14:53.711 | 11.36.787.499 I slot launch_slot_: id  3 | task 3554 | processing task, is_child = 0
2026-05-17 11:14:53.977 | 11.37.053.272 I slot create_check: id  3 | task 3554 | created context checkpoint 11 of 32 (pos_min = 47928, pos_max = 47928, n_tokens = 47929, size = 250.002 MiB)
2026-05-17 11:14:54.384 | 11.37.460.812 I reasoning-budget: deactivated (natural end)
2026-05-17 11:14:55.401 | 11.38.477.320 I slot print_timing: id  3 | task 3554 | n_decoded =    100, tg =  74.88 t/s
2026-05-17 11:14:57.780 | 11.40.856.039 I slot print_timing: id  3 | task 3554 | 
2026-05-17 11:14:57.780 | prompt eval time =     354.18 ms /    21 tokens (   16.87 ms per token,    59.29 tokens per second)
2026-05-17 11:14:57.780 |        eval time =    3714.17 ms /   293 tokens (   12.68 ms per token,    78.89 tokens per second)
2026-05-17 11:14:57.780 |       total time =    4068.35 ms /   314 tokens
2026-05-17 11:14:57.780 | draft acceptance rate = 0.72500 (  174 accepted /   240 generated)
2026-05-17 11:14:57.780 | 11.40.856.073 I statistics draft-mtp: #calls(b,g,a) = 13 3609 3609, #gen drafts = 3609, #acc drafts = 3002, #gen tokens = 7218, #acc tokens = 5453, dur(b,g,a) = 0.024, 15893.365, 7.473 ms
2026-05-17 11:14:57.781 | 11.40.857.287 I slot      release: id  3 | task 3554 | stop processing: n_tokens = 48244, truncated = 0
2026-05-17 11:14:57.781 | 11.40.857.346 I srv  update_slots: all slots are idle
```