# docker compose

```yml
services:
  qwopus-27b-mtp-server:
    image: ghcr.io/ggml-org/llama.cpp:server-cuda13
    container_name: qwopus36-27b-mtp-5090
    hostname: inference-server
    platform: linux/amd64
    ports:
      - "${INFERENCE_SERVER_PORT:-8000}:8000"
    volumes:
      - ~/.cache/huggingface:/root/.cache/huggingface
      - /dev/shm:/dev/shm
    shm_size: "32g"
    ipc: host
    deploy:
      resources:
        reservations:
          devices:
            - capabilities: [gpu]
    environment:
      - CUDA_VISIBLE_DEVICES=0
      - LD_LIBRARY_PATH=/usr/local/cuda-12.8/lib64
      - HF_HOME=/root/.cache/huggingface
      - NVIDIA_VISIBLE_DEVICES=0
    command:
      - "-hf"
      # Model: Qwopus3.6-27B-v2 MTP quantization (Q4_K_M) by Jackrong.
      - "Jackrong/Qwopus3.6-27B-v2-MTP-GGUF:Q4_K_M"
      - "--alias"
      - "${INFERENCE_MODEL_ALIAS:-qwopus3.6-27b-v2-mtp}"
      - "--host"
      - "0.0.0.0"
      - "--port"
      - "${INFERENCE_SERVER_PORT:-8000}"
      - "--api-key"
      - "${INFERENCE_API_KEY:-dummy-key}"
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
      - "--threads"
      - "12"
      - "--threads-batch"
      - "24"
      # --- SPECULATIVE DECODING (MTP) ---
      - "--spec-type"
      - "draft-mtp"
      - "--spec-draft-n-max"
      - "2"
      - "--spec-draft-p-min"
      - "0.8"
      # --- SAMPLING ---
      - "--temp"
      - "1.0"
      - "--top-p"
      - "0.95"
      - "--top-k"
      - "20"
      - "--presence-penalty"
      - "1.5"
      # force system to keep model in RAM rather than swapping or compressing
      - "--mlock"
    networks:
      - development-network
networks:
  development-network:
    external: true
```    

# lammacpp log

```log
warn: LLAMA_ARG_HOST environment variable is set, but will be overwritten by command line argument --host
0.00.640.271 I log_info: verbosity = 3 (adjust with the `-lv N` CLI arg)
0.00.640.301 I device_info:
0.00.893.202 I   - CUDA0   : NVIDIA GeForce RTX 5090 (32606 MiB, 30930 MiB free)
0.00.893.227 I   - CPU     : AMD Ryzen 9 5950X 16-Core Processor (64297 MiB, 64297 MiB free)
0.00.893.306 I system_info: n_threads = 12 (n_threads_batch = 24) / 32 | CUDA : ARCHS = 750,800,860,890,900,1200,1210 | USE_GRAPHS = 1 | PEER_MAX_BATCH_SIZE = 128 | BLACKWELL_NATIVE_FP4 = 1 | CPU : SSE3 = 1 | SSSE3 = 1 | AVX = 1 | AVX2 = 1 | F16C = 1 | FMA = 1 | BMI2 = 1 | LLAMAFILE = 1 | OPENMP = 1 | REPACK = 1 | 
0.00.893.331 I srv  llama_server: n_parallel is set to auto, using n_parallel = 4 and kv_unified = true
0.00.893.366 I srv          init: running without SSL
0.00.893.379 I srv          init: api_keys: ****-key
0.00.893.394 I srv          init: using 31 threads for HTTP server
0.00.893.466 I srv         start: binding port with default address family
0.00.895.316 I srv  llama_server: loading model
0.00.895.340 I srv    load_model: loading model '/root/.cache/huggingface/hub/models--Jackrong--Qwopus3.6-27B-v2-MTP-GGUF/snapshots/5a93ddf665b431238d479f55a9fa9a503a64084b/Qwopus3.6-27B-v2-MTP-Q4_K_M.gguf'
0.01.220.773 I srv    load_model: [mtmd] estimated worst-case memory usage of mmproj is 1161.02 MiB
0.01.594.477 I srv    load_model: [spec] estimated memory usage of MTP context is 1129.00 MiB
0.01.594.520 I common_init_result: fitting params to device memory ...
0.01.594.531 I common_init_result: (for bugs during this step try to reproduce them with -fit off, or provide --verbose logs if the bug only occurs with -fit on)
0.05.676.707 W llama_context: n_ctx_seq (131072) < n_ctx_train (262144) -- the full capacity of the model will not be utilized
0.05.903.577 I common_init_from_params: warming up the model with an empty run - please wait ... (--no-warmup to disable)
0.05.995.339 I srv    load_model: creating MTP draft context against the target model '/root/.cache/huggingface/hub/models--Jackrong--Qwopus3.6-27B-v2-MTP-GGUF/snapshots/5a93ddf665b431238d479f55a9fa9a503a64084b/Qwopus3.6-27B-v2-MTP-Q4_K_M.gguf'
0.05.995.433 W llama_context: n_ctx_seq (131072) < n_ctx_train (262144) -- the full capacity of the model will not be utilized
0.06.211.587 W load_hparams: Qwen-VL models require at minimum 1024 image tokens to function correctly on grounding tasks
0.06.211.611 W load_hparams: if you encounter problems with accuracy, try adding --image-min-tokens 1024
0.06.211.611 W load_hparams: more info: https://github.com/ggml-org/llama.cpp/issues/16842

0.06.510.297 I srv    load_model: loaded multimodal model, '/root/.cache/huggingface/hub/models--Jackrong--Qwopus3.6-27B-v2-MTP-GGUF/snapshots/5a93ddf665b431238d479f55a9fa9a503a64084b/mmproj-F32.gguf'
0.06.510.331 I srv    load_model: initializing slots, n_slots = 4
0.06.539.418 I common_context_can_seq_rm: the context supports bounded partial sequence removal
0.06.558.585 I common_speculative_impl_draft_mtp: adding speculative implementation 'draft-mtp'
0.06.558.606 I common_speculative_impl_draft_mtp: - n_max=2, n_min=0, p_min=0.80, n_embd=5120, backend_sampling=1
0.06.558.608 I common_speculative_impl_draft_mtp: - gpu_layers=-1, cache_k=f16, cache_v=f16, ctx_tgt=yes, ctx_dft=yes, devices=[default]
0.06.558.825 I srv    load_model: speculative decoding context initialized
0.06.558.843 I slot   load_model: id  0 | task -1 | new slot, n_ctx = 131072
0.06.558.847 I slot   load_model: id  1 | task -1 | new slot, n_ctx = 131072
0.06.558.847 I slot   load_model: id  2 | task -1 | new slot, n_ctx = 131072
0.06.558.848 I slot   load_model: id  3 | task -1 | new slot, n_ctx = 131072
0.06.558.905 I srv    load_model: prompt cache is enabled, size limit: 8192 MiB
0.06.558.911 I srv    load_model: use `--cache-ram 0` to disable the prompt cache
0.06.558.911 I srv    load_model: for more info see https://github.com/ggml-org/llama.cpp/pull/16391
0.06.558.911 I srv    load_model: context checkpoints enabled, max = 32, min spacing = 256
0.06.558.925 I srv          init: idle slots will be saved to prompt cache and cleared upon starting a new task
0.06.572.001 I init: chat template, example_format: '<|im_start|>system
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
0.06.582.292 I srv          init: init: chat template, thinking = 1
0.06.582.356 I srv  llama_server: model loaded
0.06.582.362 I srv  llama_server: server is listening on http://0.0.0.0:8000
0.06.582.368 I srv  update_slots: all slots are idle
0.51.583.307 I srv  params_from_: Chat format: peg-native
0.51.633.600 I slot get_availabl: id  3 | task -1 | selected slot by LRU, t_last = -1
0.51.633.620 I srv  get_availabl: updating prompt cache
0.51.633.626 I srv          load:  - looking for better prompt, base f_keep = -1.000, sim = 0.000
0.51.633.630 I srv        update:  - cache state: 0 prompts, 0.000 MiB (limits: 8192.000 MiB, 131072 tokens, 8589934592 est)
0.51.633.631 I srv  get_availabl: prompt cache update took 0.01 ms
0.51.634.745 I reasoning-budget: activated, budget=2147483647 tokens
0.51.634.791 I slot launch_slot_: id  3 | task 0 | processing task, is_child = 0
0.54.751.609 I slot print_timing: id  3 | task 0 | prompt processing, n_tokens =   8192, progress = 0.16, t =   3.12 s / 2627.31 tokens per second
0.55.413.322 I slot print_timing: id  3 | task 0 | prompt processing, n_tokens =  10240, progress = 0.21, t =   3.78 s / 2709.19 tokens per second
0.56.081.758 I slot print_timing: id  3 | task 0 | prompt processing, n_tokens =  12288, progress = 0.25, t =   4.45 s / 2762.49 tokens per second
0.56.761.439 I slot print_timing: id  3 | task 0 | prompt processing, n_tokens =  14336, progress = 0.29, t =   5.13 s / 2795.72 tokens per second
0.57.455.436 I slot print_timing: id  3 | task 0 | prompt processing, n_tokens =  16384, progress = 0.33, t =   5.82 s / 2814.23 tokens per second
0.58.155.488 I slot print_timing: id  3 | task 0 | prompt processing, n_tokens =  18432, progress = 0.37, t =   6.52 s / 2826.17 tokens per second
0.58.867.468 I slot print_timing: id  3 | task 0 | prompt processing, n_tokens =  20480, progress = 0.41, t =   7.23 s / 2831.13 tokens per second
0.59.591.470 I slot print_timing: id  3 | task 0 | prompt processing, n_tokens =  22528, progress = 0.45, t =   7.96 s / 2831.25 tokens per second
1.00.329.757 I slot print_timing: id  3 | task 0 | prompt processing, n_tokens =  24576, progress = 0.49, t =   8.70 s / 2826.39 tokens per second
1.01.081.750 I slot print_timing: id  3 | task 0 | prompt processing, n_tokens =  26624, progress = 0.54, t =   9.45 s / 2818.19 tokens per second
1.01.855.478 I slot print_timing: id  3 | task 0 | prompt processing, n_tokens =  28672, progress = 0.58, t =  10.22 s / 2805.23 tokens per second
1.17.633.466 I slot print_timing: id  3 | task 0 | prompt processing, n_tokens =  30720, progress = 0.62, t =  11.01 s / 2789.85 tokens per second
1.03.461.930 I slot print_timing: id  3 | task 0 | prompt processing, n_tokens =  32768, progress = 0.66, t =  11.82 s / 2771.92 tokens per second
1.04.290.073 I slot print_timing: id  3 | task 0 | prompt processing, n_tokens =  34816, progress = 0.70, t =  12.65 s / 2752.35 tokens per second
1.05.137.115 I slot print_timing: id  3 | task 0 | prompt processing, n_tokens =  36864, progress = 0.74, t =  13.50 s / 2731.35 tokens per second
1.06.011.932 I slot print_timing: id  3 | task 0 | prompt processing, n_tokens =  38912, progress = 0.78, t =  14.37 s / 2707.60 tokens per second
1.06.908.801 I slot print_timing: id  3 | task 0 | prompt processing, n_tokens =  40960, progress = 0.82, t =  15.27 s / 2682.68 tokens per second
1.07.828.225 I slot print_timing: id  3 | task 0 | prompt processing, n_tokens =  43008, progress = 0.87, t =  16.19 s / 2656.83 tokens per second
1.08.772.044 I slot print_timing: id  3 | task 0 | prompt processing, n_tokens =  45056, progress = 0.91, t =  17.13 s / 2630.00 tokens per second
1.09.743.655 I slot print_timing: id  3 | task 0 | prompt processing, n_tokens =  47104, progress = 0.95, t =  18.10 s / 2602.01 tokens per second
1.10.741.015 I slot print_timing: id  3 | task 0 | prompt processing, n_tokens =  49152, progress = 0.99, t =  19.10 s / 2573.37 tokens per second
1.10.785.754 I slot print_timing: id  3 | task 0 | prompt processing, n_tokens =  49172, progress = 0.99, t =  19.14 s / 2568.40 tokens per second
1.11.021.530 I slot print_timing: id  3 | task 0 | prompt processing, n_tokens =  49630, progress = 1.00, t =  19.38 s / 2560.79 tokens per second
1.11.393.605 I slot create_check: id  3 | task 0 | created context checkpoint 1 of 32 (pos_min = 49629, pos_max = 49629, n_tokens = 49630, size = 344.440 MiB)
1.11.446.921 I slot print_timing: id  3 | task 0 | prompt processing, n_tokens =  49684, progress = 1.00, t =  19.81 s / 2508.51 tokens per second
1.12.753.975 I reasoning-budget: deactivated (natural end)
1.13.536.493 I slot print_timing: id  3 | task 0 | n_decoded =    101, tg =  50.05 t/s
1.13.606.619 I slot print_timing: id  3 | task 0 | prompt eval time =   19877.71 ms / 49688 tokens (    0.40 ms per token,  2499.68 tokens per second)
1.13.606.645 I slot print_timing: id  3 | task 0 |        eval time =    2088.00 ms /   103 tokens (   20.27 ms per token,    49.33 tokens per second)
1.13.606.646 I slot print_timing: id  3 | task 0 |       total time =   21965.70 ms / 49791 tokens
1.13.606.651 I slot print_timing: id  3 | task 0 |    graphs reused =         18
1.13.606.652 I slot print_timing: id  3 | task 0 | draft acceptance = 0.84615 (   44 accepted /    52 generated)
1.13.606.674 I statistics        draft-mtp: #calls(b,g,a) =    1     60     36, #gen drafts =     36, #acc drafts =    31, #gen tokens =     52, #acc tokens =    44, dur(b,g,a) = 0.004, 184.459, 0.076 ms
1.13.608.000 I slot      release: id  3 | task 0 | stop processing: n_tokens = 49792, truncated = 0
1.13.608.024 I srv  update_slots: all slots are idle
2.57.680.972 I srv  params_from_: Chat format: peg-native
2.57.733.294 I slot get_availabl: id  3 | task -1 | selected slot by LCP similarity, sim_best = 0.953 (> 0.100 thold), f_keep = 0.998
2.57.733.931 I reasoning-budget: activated, budget=2147483647 tokens
2.57.734.008 I slot launch_slot_: id  3 | task 89 | processing task, is_child = 0
2.57.734.076 I slot update_slots: id  3 | task 89 | Checking checkpoint with [49629, 49629] against 49685...
2.57.854.618 W slot update_slots: id  3 | task 89 | restored context checkpoint (pos_min = 49629, pos_max = 49629, n_tokens = 49630, n_past = 49630, size = 344.440 MiB)
2.59.417.529 I slot create_check: id  3 | task 89 | created context checkpoint 2 of 32 (pos_min = 51630, pos_max = 51630, n_tokens = 51631, size = 352.295 MiB)
3.00.069.116 I slot create_check: id  3 | task 89 | created context checkpoint 3 of 32 (pos_min = 52142, pos_max = 52142, n_tokens = 52143, size = 354.304 MiB)
3.02.021.882 I slot print_timing: id  3 | task 89 | n_decoded =    100, tg =  52.21 t/s
3.02.062.558 I reasoning-budget: deactivated (natural end)
3.03.417.263 I slot print_timing: id  3 | task 89 | prompt eval time =    2372.51 ms /  2517 tokens (    0.94 ms per token,  1060.90 tokens per second)
3.03.417.285 I slot print_timing: id  3 | task 89 |        eval time =    3310.53 ms /   173 tokens (   19.14 ms per token,    52.26 tokens per second)
3.03.417.285 I slot print_timing: id  3 | task 89 |       total time =    5683.05 ms /  2690 tokens
3.03.417.286 I slot print_timing: id  3 | task 89 |    graphs reused =         63
3.03.417.287 I slot print_timing: id  3 | task 89 | draft acceptance = 0.82759 (   72 accepted /    87 generated)
3.03.417.300 I statistics        draft-mtp: #calls(b,g,a) =    2    160     92, #gen drafts =     92, #acc drafts =    80, #gen tokens =    139, #acc tokens =   116, dur(b,g,a) = 0.005, 473.852, 0.195 ms
3.03.418.615 I slot      release: id  3 | task 89 | stop processing: n_tokens = 52319, truncated = 0
3.03.418.680 I srv  update_slots: all slots are idle
5.09.386.920 I srv  params_from_: Chat format: peg-native
4.54.459.101 I slot get_availabl: id  3 | task -1 | selected slot by LCP similarity, sim_best = 0.996 (> 0.100 thold), f_keep = 0.997
4.54.459.842 I reasoning-budget: activated, budget=2147483647 tokens
4.54.459.917 I slot launch_slot_: id  3 | task 194 | processing task, is_child = 0
4.54.459.976 I slot update_slots: id  3 | task 194 | Checking checkpoint with [52142, 52142] against 52144...
4.54.585.036 W slot update_slots: id  3 | task 194 | restored context checkpoint (pos_min = 52142, pos_max = 52142, n_tokens = 52143, n_past = 52143, size = 354.304 MiB)
4.56.761.329 I slot print_timing: id  3 | task 194 | n_decoded =    100, tg =  55.25 t/s
4.57.013.759 I reasoning-budget: deactivated (natural end)
4.58.408.614 I slot print_timing: id  3 | task 194 | prompt eval time =     491.43 ms /   217 tokens (    2.26 ms per token,   441.57 tokens per second)
4.58.408.633 I slot print_timing: id  3 | task 194 |        eval time =    3457.06 ms /   222 tokens (   15.57 ms per token,    64.22 tokens per second)
4.58.408.634 I slot print_timing: id  3 | task 194 |       total time =    3948.49 ms /   439 tokens
4.58.408.635 I slot print_timing: id  3 | task 194 |    graphs reused =        118
4.58.408.636 I slot print_timing: id  3 | task 194 | draft acceptance = 0.90370 (  122 accepted /   135 generated)
4.58.408.647 I statistics        draft-mtp: #calls(b,g,a) =    3    260    166, #gen drafts =    166, #acc drafts =   149, #gen tokens =    274, #acc tokens =   238, dur(b,g,a) = 0.006, 806.143, 0.374 ms
4.58.410.024 I slot      release: id  3 | task 194 | stop processing: n_tokens = 52582, truncated = 0
4.58.410.089 I srv  update_slots: all slots are idle
4.58.608.744 I srv  params_from_: Chat format: peg-native
4.58.662.710 I slot get_availabl: id  3 | task -1 | selected slot by LCP similarity, sim_best = 0.960 (> 0.100 thold), f_keep = 1.000
4.58.663.363 I reasoning-budget: activated, budget=2147483647 tokens
4.58.663.439 I slot launch_slot_: id  3 | task 298 | processing task, is_child = 0
4.58.663.511 I slot update_slots: id  3 | task 298 | Checking checkpoint with [52142, 52142] against 52581...
4.58.709.494 W slot update_slots: id  3 | task 298 | restored context checkpoint (pos_min = 52142, pos_max = 52142, n_tokens = 52143, n_past = 52143, size = 354.304 MiB)
4.59.309.670 I slot create_check: id  3 | task 298 | created context checkpoint 4 of 32 (pos_min = 52582, pos_max = 52582, n_tokens = 52583, size = 356.031 MiB)
5.00.605.045 I slot create_check: id  3 | task 298 | created context checkpoint 5 of 32 (pos_min = 54235, pos_max = 54235, n_tokens = 54236, size = 362.520 MiB)
5.01.283.595 I slot create_check: id  3 | task 298 | created context checkpoint 6 of 32 (pos_min = 54747, pos_max = 54747, n_tokens = 54748, size = 364.530 MiB)
5.01.805.073 I reasoning-budget: deactivated (natural end)
5.02.464.489 I slot print_timing: id  3 | task 298 | n_decoded =    100, tg =  87.47 t/s
5.04.184.374 I slot print_timing: id  3 | task 298 | prompt eval time =    2651.41 ms /  2609 tokens (    1.02 ms per token,   984.01 tokens per second)
5.04.184.395 I slot print_timing: id  3 | task 298 |        eval time =    2863.31 ms /   268 tokens (   10.68 ms per token,    93.60 tokens per second)
5.04.184.396 I slot print_timing: id  3 | task 298 |       total time =    5514.71 ms /  2877 tokens
5.04.184.397 I slot print_timing: id  3 | task 298 |    graphs reused =        202
5.04.184.398 I slot print_timing: id  3 | task 298 | draft acceptance = 0.98295 (  173 accepted /   176 generated)
5.04.184.409 I statistics        draft-mtp: #calls(b,g,a) =    4    354    256, #gen drafts =    256, #acc drafts =   238, #gen tokens =    450, #acc tokens =   411, dur(b,g,a) = 0.008, 1149.134, 0.593 ms
5.04.185.777 I slot      release: id  3 | task 298 | stop processing: n_tokens = 55019, truncated = 0
5.04.185.840 I srv  update_slots: all slots are idle
5.04.380.271 I srv  params_from_: Chat format: peg-native
5.04.428.995 I slot get_availabl: id  3 | task -1 | selected slot by LCP similarity, sim_best = 0.894 (> 0.100 thold), f_keep = 1.000
5.04.429.622 I reasoning-budget: activated, budget=2147483647 tokens
5.04.429.706 I slot launch_slot_: id  3 | task 397 | processing task, is_child = 0
5.04.429.773 I slot update_slots: id  3 | task 397 | Checking checkpoint with [54747, 54747] against 55018...
5.04.478.142 W slot update_slots: id  3 | task 397 | restored context checkpoint (pos_min = 54747, pos_max = 54747, n_tokens = 54748, n_past = 54748, size = 364.530 MiB)
5.05.021.156 I slot create_check: id  3 | task 397 | created context checkpoint 7 of 32 (pos_min = 55020, pos_max = 55020, n_tokens = 55021, size = 365.601 MiB)
5.08.351.356 I slot print_timing: id  3 | task 397 | prompt processing, n_tokens =   6269, progress = 0.99, t =   3.92 s / 1598.58 tokens per second
5.08.787.415 I slot create_check: id  3 | task 397 | created context checkpoint 8 of 32 (pos_min = 61016, pos_max = 61016, n_tokens = 61017, size = 389.138 MiB)
5.09.092.343 I slot print_timing: id  3 | task 397 | prompt processing, n_tokens =   6781, progress = 1.00, t =   4.66 s / 1454.34 tokens per second
5.09.532.156 I slot create_check: id  3 | task 397 | created context checkpoint 9 of 32 (pos_min = 61528, pos_max = 61528, n_tokens = 61529, size = 391.147 MiB)
5.10.082.598 I reasoning-budget: deactivated (natural end)
5.11.532.811 I slot print_timing: id  3 | task 397 | n_decoded =    100, tg =  51.09 t/s
5.13.802.921 I slot print_timing: id  3 | task 397 | prompt eval time =    5138.57 ms /  6785 tokens (    0.76 ms per token,  1320.41 tokens per second)
5.13.802.940 I slot print_timing: id  3 | task 397 |        eval time =    4227.31 ms /   208 tokens (   20.32 ms per token,    49.20 tokens per second)
5.13.802.941 I slot print_timing: id  3 | task 397 |       total time =    9365.88 ms /  6993 tokens
5.13.802.941 I slot print_timing: id  3 | task 397 |    graphs reused =        252
5.13.802.942 I slot print_timing: id  3 | task 397 | draft acceptance = 0.87500 (   91 accepted /   104 generated)
5.13.802.954 I statistics        draft-mtp: #calls(b,g,a) =    5    472    325, #gen drafts =    325, #acc drafts =   300, #gen tokens =    554, #acc tokens =   502, dur(b,g,a) = 0.010, 1516.673, 0.777 ms
5.13.804.443 I slot      release: id  3 | task 397 | stop processing: n_tokens = 61742, truncated = 0
5.13.804.504 I srv  update_slots: all slots are idle
6.17.692.503 I srv  params_from_: Chat format: peg-native
6.17.753.005 I slot get_availabl: id  3 | task -1 | selected slot by LCP similarity, sim_best = 0.849 (> 0.100 thold), f_keep = 0.848
6.17.753.680 I reasoning-budget: activated, budget=2147483647 tokens
6.17.753.754 I slot launch_slot_: id  3 | task 522 | processing task, is_child = 0
6.17.753.795 I slot update_slots: id  3 | task 522 | Checking checkpoint with [61528, 61528] against 52357...
6.17.753.814 I slot update_slots: id  3 | task 522 | Checking checkpoint with [61016, 61016] against 52357...
6.17.753.816 I slot update_slots: id  3 | task 522 | Checking checkpoint with [55020, 55020] against 52357...
6.17.753.817 I slot update_slots: id  3 | task 522 | Checking checkpoint with [54747, 54747] against 52357...
6.17.753.817 I slot update_slots: id  3 | task 522 | Checking checkpoint with [54235, 54235] against 52357...
6.17.753.818 I slot update_slots: id  3 | task 522 | Checking checkpoint with [52582, 52582] against 52357...
6.17.753.818 I slot update_slots: id  3 | task 522 | Checking checkpoint with [52142, 52142] against 52357...
6.17.878.711 W slot update_slots: id  3 | task 522 | restored context checkpoint (pos_min = 52142, pos_max = 52142, n_tokens = 52143, n_past = 52143, size = 354.304 MiB)
6.17.878.732 W slot update_slots: id  3 | task 522 | erased invalidated context checkpoint (pos_min = 52582, pos_max = 52582, n_tokens = 52583, n_swa = 0, pos_next = 52143, size = 356.031 MiB)
6.17.898.566 W slot update_slots: id  3 | task 522 | erased invalidated context checkpoint (pos_min = 54235, pos_max = 54235, n_tokens = 54236, n_swa = 0, pos_next = 52143, size = 362.520 MiB)
6.17.918.673 W slot update_slots: id  3 | task 522 | erased invalidated context checkpoint (pos_min = 54747, pos_max = 54747, n_tokens = 54748, n_swa = 0, pos_next = 52143, size = 364.530 MiB)
6.17.938.791 W slot update_slots: id  3 | task 522 | erased invalidated context checkpoint (pos_min = 55020, pos_max = 55020, n_tokens = 55021, n_swa = 0, pos_next = 52143, size = 365.601 MiB)
6.17.959.203 W slot update_slots: id  3 | task 522 | erased invalidated context checkpoint (pos_min = 61016, pos_max = 61016, n_tokens = 61017, n_swa = 0, pos_next = 52143, size = 389.138 MiB)
6.17.981.175 W slot update_slots: id  3 | task 522 | erased invalidated context checkpoint (pos_min = 61528, pos_max = 61528, n_tokens = 61529, n_swa = 0, pos_next = 52143, size = 391.147 MiB)
6.21.424.756 I slot print_timing: id  3 | task 522 | prompt processing, n_tokens =   6144, progress = 0.95, t =   3.67 s / 1673.55 tokens per second
6.22.572.448 I slot print_timing: id  3 | task 522 | prompt processing, n_tokens =   8192, progress = 0.98, t =   4.82 s / 1699.96 tokens per second
6.23.010.009 I slot print_timing: id  3 | task 522 | prompt processing, n_tokens =   8975, progress = 0.99, t =   5.26 s / 1707.41 tokens per second
6.23.274.119 I slot print_timing: id  3 | task 522 | prompt processing, n_tokens =   9420, progress = 1.00, t =   5.52 s / 1706.33 tokens per second
6.23.699.659 I slot create_check: id  3 | task 522 | created context checkpoint 4 of 32 (pos_min = 61562, pos_max = 61562, n_tokens = 61563, size = 391.281 MiB)
6.23.762.316 I slot print_timing: id  3 | task 522 | prompt processing, n_tokens =   9487, progress = 1.00, t =   6.01 s / 1578.85 tokens per second
6.25.053.666 I reasoning-budget: deactivated (natural end)
6.25.507.583 I slot print_timing: id  3 | task 522 | n_decoded =    100, tg =  58.88 t/s
6.26.090.411 I slot print_timing: id  3 | task 522 | prompt eval time =    6055.40 ms /  9491 tokens (    0.64 ms per token,  1567.36 tokens per second)
6.26.090.433 I slot print_timing: id  3 | task 522 |        eval time =    2281.02 ms /   151 tokens (   15.11 ms per token,    66.20 tokens per second)
6.26.090.434 I slot print_timing: id  3 | task 522 |       total time =    8336.42 ms /  9642 tokens
6.26.090.435 I slot print_timing: id  3 | task 522 |    graphs reused =        286
6.26.090.435 I slot print_timing: id  3 | task 522 | draft acceptance = 0.94382 (   84 accepted /    89 generated)
6.26.090.447 I statistics        draft-mtp: #calls(b,g,a) =    6    538    376, #gen drafts =    376, #acc drafts =   350, #gen tokens =    643, #acc tokens =   586, dur(b,g,a) = 0.012, 1735.735, 0.896 ms
6.26.091.972 I slot      release: id  3 | task 522 | stop processing: n_tokens = 61784, truncated = 0
6.26.092.029 I srv  update_slots: all slots are idle
6.26.282.957 I srv  params_from_: Chat format: peg-native
6.26.343.946 I slot get_availabl: id  3 | task -1 | selected slot by LCP similarity, sim_best = 0.993 (> 0.100 thold), f_keep = 1.000
6.26.344.553 I reasoning-budget: activated, budget=2147483647 tokens
6.26.344.633 I slot launch_slot_: id  3 | task 597 | processing task, is_child = 0
6.26.344.699 I slot update_slots: id  3 | task 597 | Checking checkpoint with [61562, 61562] against 61783...
6.26.395.018 W slot update_slots: id  3 | task 597 | restored context checkpoint (pos_min = 61562, pos_max = 61562, n_tokens = 61563, n_past = 61563, size = 391.281 MiB)
6.27.263.097 I slot create_check: id  3 | task 597 | created context checkpoint 5 of 32 (pos_min = 62217, pos_max = 62217, n_tokens = 62218, size = 393.852 MiB)
6.29.136.568 I slot print_timing: id  3 | task 597 | n_decoded =    102, tg =  55.57 t/s
6.29.717.189 I reasoning-budget: deactivated (natural end)
6.32.146.924 I slot print_timing: id  3 | task 597 | n_decoded =    306, tg =  63.15 t/s
6.33.333.113 I slot print_timing: id  3 | task 597 | prompt eval time =     956.10 ms /   659 tokens (    1.45 ms per token,   689.26 tokens per second)
6.33.333.135 I slot print_timing: id  3 | task 597 |        eval time =    6032.07 ms /   413 tokens (   14.61 ms per token,    68.47 tokens per second)
6.33.333.136 I slot print_timing: id  3 | task 597 |       total time =    6988.17 ms /  1072 tokens
6.33.333.137 I slot print_timing: id  3 | task 597 |    graphs reused =        398
6.33.333.138 I slot print_timing: id  3 | task 597 | draft acceptance = 0.97510 (  235 accepted /   241 generated)
6.33.333.150 I statistics        draft-mtp: #calls(b,g,a) =    7    715    510, #gen drafts =    510, #acc drafts =   481, #gen tokens =    884, #acc tokens =   821, dur(b,g,a) = 0.013, 2344.589, 1.204 ms
6.33.334.770 I slot      release: id  3 | task 597 | stop processing: n_tokens = 62634, truncated = 0
6.33.334.834 I srv  update_slots: all slots are idle
6.33.563.968 I srv  params_from_: Chat format: peg-native
6.33.631.337 I slot get_availabl: id  3 | task -1 | selected slot by LCP similarity, sim_best = 0.993 (> 0.100 thold), f_keep = 1.000
6.33.632.125 I reasoning-budget: activated, budget=2147483647 tokens
6.33.632.206 I slot launch_slot_: id  3 | task 779 | processing task, is_child = 0
6.33.632.263 I slot update_slots: id  3 | task 779 | Checking checkpoint with [62217, 62217] against 62633...
6.33.687.747 W slot update_slots: id  3 | task 779 | restored context checkpoint (pos_min = 62217, pos_max = 62217, n_tokens = 62218, n_past = 62218, size = 393.852 MiB)
6.34.473.758 I slot create_check: id  3 | task 779 | created context checkpoint 6 of 32 (pos_min = 62635, pos_max = 62635, n_tokens = 62636, size = 395.493 MiB)
6.34.929.149 I slot create_check: id  3 | task 779 | created context checkpoint 7 of 32 (pos_min = 63068, pos_max = 63068, n_tokens = 63069, size = 397.192 MiB)
6.36.988.216 I slot print_timing: id  3 | task 779 | n_decoded =    102, tg =  50.56 t/s
6.39.059.553 I reasoning-budget: deactivated (natural end)
6.39.596.548 I slot print_timing: id  3 | task 779 | n_decoded =    273, tg =  54.12 t/s
6.41.626.748 I slot print_timing: id  3 | task 779 | prompt eval time =    1587.37 ms /   855 tokens (    1.86 ms per token,   538.63 tokens per second)
6.41.626.770 I slot print_timing: id  3 | task 779 |        eval time =    7074.08 ms /   436 tokens (   16.22 ms per token,    61.63 tokens per second)
6.41.626.770 I slot print_timing: id  3 | task 779 |       total time =    8661.45 ms /  1291 tokens
6.41.626.771 I slot print_timing: id  3 | task 779 |    graphs reused =        536
6.41.626.772 I slot print_timing: id  3 | task 779 | draft acceptance = 0.96667 (  232 accepted /   240 generated)
6.41.626.784 I statistics        draft-mtp: #calls(b,g,a) =    8    920    641, #gen drafts =    641, #acc drafts =   608, #gen tokens =   1124, #acc tokens =  1053, dur(b,g,a) = 0.015, 3027.224, 1.521 ms
6.41.628.348 I slot      release: id  3 | task 779 | stop processing: n_tokens = 63510, truncated = 0
6.41.628.410 I srv  update_slots: all slots are idle
6.41.845.421 I srv  params_from_: Chat format: peg-native
6.41.909.339 I slot get_availabl: id  3 | task -1 | selected slot by LCP similarity, sim_best = 1.000 (> 0.100 thold), f_keep = 1.000
6.41.910.129 I reasoning-budget: activated, budget=2147483647 tokens
6.41.910.215 I slot launch_slot_: id  3 | task 989 | processing task, is_child = 0
6.41.910.280 I slot update_slots: id  3 | task 989 | Checking checkpoint with [63068, 63068] against 63509...
6.41.961.058 W slot update_slots: id  3 | task 989 | restored context checkpoint (pos_min = 63068, pos_max = 63068, n_tokens = 63069, n_past = 63069, size = 397.192 MiB)
6.42.677.405 I slot create_check: id  3 | task 989 | created context checkpoint 8 of 32 (pos_min = 63509, pos_max = 63509, n_tokens = 63510, size = 398.923 MiB)
6.43.005.420 I reasoning-budget: deactivated (natural end)
6.44.110.237 I slot print_timing: id  3 | task 989 | n_decoded =    102, tg =  76.00 t/s
6.46.561.404 I slot print_timing: id  3 | task 989 | prompt eval time =     857.74 ms /   458 tokens (    1.87 ms per token,   533.96 tokens per second)
6.46.561.424 I slot print_timing: id  3 | task 989 |        eval time =    3798.53 ms /   332 tokens (   11.44 ms per token,    87.40 tokens per second)
6.46.561.424 I slot print_timing: id  3 | task 989 |       total time =    4656.26 ms /   790 tokens
6.46.561.426 I slot print_timing: id  3 | task 989 |    graphs reused =        632
6.46.561.426 I slot print_timing: id  3 | task 989 | draft acceptance = 0.99074 (  214 accepted /   216 generated)
6.46.561.438 I statistics        draft-mtp: #calls(b,g,a) =    9   1037    753, #gen drafts =    753, #acc drafts =   718, #gen tokens =   1340, #acc tokens =  1267, dur(b,g,a) = 0.017, 3463.466, 1.750 ms
6.46.563.040 I slot      release: id  3 | task 989 | stop processing: n_tokens = 63858, truncated = 0
6.46.563.102 I srv  update_slots: all slots are idle
6.46.792.752 I srv  params_from_: Chat format: peg-native
6.46.857.590 I slot get_availabl: id  3 | task -1 | selected slot by LCP similarity, sim_best = 0.999 (> 0.100 thold), f_keep = 1.000
6.46.858.358 I reasoning-budget: activated, budget=2147483647 tokens
6.46.858.442 I slot launch_slot_: id  3 | task 1110 | processing task, is_child = 0
6.46.858.523 I slot update_slots: id  3 | task 1110 | Checking checkpoint with [63509, 63509] against 63857...
6.46.909.333 W slot update_slots: id  3 | task 1110 | restored context checkpoint (pos_min = 63509, pos_max = 63509, n_tokens = 63510, n_past = 63510, size = 398.923 MiB)
6.47.574.524 I slot create_check: id  3 | task 1110 | created context checkpoint 9 of 32 (pos_min = 63859, pos_max = 63859, n_tokens = 63860, size = 400.297 MiB)
6.47.859.207 I reasoning-budget: deactivated (natural end)
6.48.785.341 I slot print_timing: id  3 | task 1110 | n_decoded =    101, tg =  90.29 t/s
6.49.923.878 I slot print_timing: id  3 | task 1110 | prompt eval time =     808.10 ms /   386 tokens (    2.09 ms per token,   477.67 tokens per second)
6.49.923.897 I slot print_timing: id  3 | task 1110 |        eval time =    2250.64 ms /   205 tokens (   10.98 ms per token,    91.09 tokens per second)
6.49.923.898 I slot print_timing: id  3 | task 1110 |       total time =    3058.74 ms /   591 tokens
6.49.923.899 I slot print_timing: id  3 | task 1110 |    graphs reused =        693
6.49.923.899 I slot print_timing: id  3 | task 1110 | draft acceptance = 1.00000 (  133 accepted /   133 generated)
6.49.923.911 I statistics        draft-mtp: #calls(b,g,a) =   10   1108    820, #gen drafts =    820, #acc drafts =   785, #gen tokens =   1473, #acc tokens =  1400, dur(b,g,a) = 0.019, 3725.844, 1.875 ms
6.49.925.548 I slot      release: id  3 | task 1110 | stop processing: n_tokens = 64100, truncated = 0
6.49.925.609 I srv  update_slots: all slots are idle
6.50.159.709 I srv  params_from_: Chat format: peg-native
6.50.222.405 I slot get_availabl: id  3 | task -1 | selected slot by LCP similarity, sim_best = 1.000 (> 0.100 thold), f_keep = 1.000
6.50.223.052 I reasoning-budget: activated, budget=2147483647 tokens
6.50.223.132 I slot launch_slot_: id  3 | task 1185 | processing task, is_child = 0
6.50.223.201 I slot update_slots: id  3 | task 1185 | Checking checkpoint with [63859, 63859] against 64099...
6.50.274.595 W slot update_slots: id  3 | task 1185 | restored context checkpoint (pos_min = 63859, pos_max = 63859, n_tokens = 63860, n_past = 63860, size = 400.297 MiB)
6.50.764.036 I reasoning-budget: deactivated (natural end)
6.51.794.813 I slot print_timing: id  3 | task 1185 | n_decoded =    110, tg =  87.37 t/s
6.51.854.385 I slot print_timing: id  3 | task 1185 | prompt eval time =     312.44 ms /   260 tokens (    1.20 ms per token,   832.17 tokens per second)
6.51.854.408 I slot print_timing: id  3 | task 1185 |        eval time =    1318.63 ms /   116 tokens (   11.37 ms per token,    87.97 tokens per second)
6.51.854.409 I slot print_timing: id  3 | task 1185 |       total time =    1631.06 ms /   376 tokens
6.51.854.409 I slot print_timing: id  3 | task 1185 |    graphs reused =        725
6.51.854.410 I slot print_timing: id  3 | task 1185 | draft acceptance = 1.00000 (   74 accepted /    74 generated)
6.51.854.422 I statistics        draft-mtp: #calls(b,g,a) =   11   1149    858, #gen drafts =    858, #acc drafts =   823, #gen tokens =   1547, #acc tokens =  1474, dur(b,g,a) = 0.021, 3873.427, 1.966 ms
6.51.856.072 I slot      release: id  3 | task 1185 | stop processing: n_tokens = 64235, truncated = 0
6.51.856.147 I srv  update_slots: all slots are idle
6.52.115.475 I srv  params_from_: Chat format: peg-native
6.52.179.983 I slot get_availabl: id  3 | task -1 | selected slot by LCP similarity, sim_best = 1.000 (> 0.100 thold), f_keep = 1.000
6.52.180.595 I reasoning-budget: activated, budget=2147483647 tokens
6.52.180.668 I slot launch_slot_: id  3 | task 1230 | processing task, is_child = 0
6.52.180.735 I slot update_slots: id  3 | task 1230 | Checking checkpoint with [63859, 63859] against 64234...
6.52.232.476 W slot update_slots: id  3 | task 1230 | restored context checkpoint (pos_min = 63859, pos_max = 63859, n_tokens = 63860, n_past = 63860, size = 400.297 MiB)
6.52.913.483 I slot create_check: id  3 | task 1230 | created context checkpoint 10 of 32 (pos_min = 64236, pos_max = 64236, n_tokens = 64237, size = 401.777 MiB)
6.53.192.993 I reasoning-budget: deactivated (natural end)
7.09.533.853 I slot print_timing: id  3 | task 1230 | prompt eval time =     822.10 ms /   395 tokens (    2.08 ms per token,   480.48 tokens per second)
7.09.533.873 I slot print_timing: id  3 | task 1230 |        eval time =    1558.04 ms /   137 tokens (   11.37 ms per token,    87.93 tokens per second)
7.09.533.874 I slot print_timing: id  3 | task 1230 |       total time =    2380.13 ms /   532 tokens
7.09.533.874 I slot print_timing: id  3 | task 1230 |    graphs reused =        767
7.09.533.875 I slot print_timing: id  3 | task 1230 | draft acceptance = 1.00000 (   88 accepted /    88 generated)
7.09.533.886 I statistics        draft-mtp: #calls(b,g,a) =   12   1197    902, #gen drafts =    902, #acc drafts =   867, #gen tokens =   1635, #acc tokens =  1562, dur(b,g,a) = 0.022, 4056.934, 2.069 ms
6.54.561.823 I slot      release: id  3 | task 1230 | stop processing: n_tokens = 64391, truncated = 0
6.54.561.885 I srv  update_slots: all slots are idle
6.54.830.625 I srv  params_from_: Chat format: peg-native
6.54.900.239 I slot get_availabl: id  3 | task -1 | selected slot by LCP similarity, sim_best = 1.000 (> 0.100 thold), f_keep = 1.000
6.54.900.954 I reasoning-budget: activated, budget=2147483647 tokens
6.54.901.034 I slot launch_slot_: id  3 | task 1282 | processing task, is_child = 0
6.54.901.116 I slot update_slots: id  3 | task 1282 | Checking checkpoint with [64236, 64236] against 64390...
6.54.956.574 W slot update_slots: id  3 | task 1282 | restored context checkpoint (pos_min = 64236, pos_max = 64236, n_tokens = 64237, n_past = 64237, size = 401.777 MiB)
6.55.304.366 I reasoning-budget: deactivated (natural end)
6.56.264.990 I slot print_timing: id  3 | task 1282 | n_decoded =    102, tg =  90.98 t/s
6.56.580.299 I slot print_timing: id  3 | task 1282 | prompt eval time =     242.64 ms /   174 tokens (    1.39 ms per token,   717.11 tokens per second)
6.56.580.320 I slot print_timing: id  3 | task 1282 |        eval time =    1436.43 ms /   127 tokens (   11.31 ms per token,    88.41 tokens per second)
6.56.580.320 I slot print_timing: id  3 | task 1282 |       total time =    1679.07 ms /   301 tokens
6.56.580.321 I slot print_timing: id  3 | task 1282 |    graphs reused =        805
6.56.580.322 I slot print_timing: id  3 | task 1282 | draft acceptance = 0.97674 (   84 accepted /    86 generated)
6.56.580.334 I statistics        draft-mtp: #calls(b,g,a) =   13   1241    946, #gen drafts =    946, #acc drafts =   910, #gen tokens =   1721, #acc tokens =  1646, dur(b,g,a) = 0.023, 4221.249, 2.159 ms
6.56.582.089 I slot      release: id  3 | task 1282 | stop processing: n_tokens = 64539, truncated = 0
6.56.582.177 I srv  update_slots: all slots are idle
6.56.816.946 I srv  params_from_: Chat format: peg-native
6.56.881.659 I slot get_availabl: id  3 | task -1 | selected slot by LCP similarity, sim_best = 1.000 (> 0.100 thold), f_keep = 1.000
6.56.882.428 I reasoning-budget: activated, budget=2147483647 tokens
6.56.882.518 I slot launch_slot_: id  3 | task 1330 | processing task, is_child = 0
6.56.882.602 I slot update_slots: id  3 | task 1330 | Checking checkpoint with [64236, 64236] against 64538...
6.56.934.514 W slot update_slots: id  3 | task 1330 | restored context checkpoint (pos_min = 64236, pos_max = 64236, n_tokens = 64237, n_past = 64237, size = 401.777 MiB)
6.57.579.594 I slot create_check: id  3 | task 1330 | created context checkpoint 11 of 32 (pos_min = 64538, pos_max = 64538, n_tokens = 64539, size = 402.963 MiB)
6.57.860.329 I reasoning-budget: deactivated (natural end)
6.59.197.198 I slot print_timing: id  3 | task 1330 | prompt eval time =     787.05 ms /   320 tokens (    2.46 ms per token,   406.58 tokens per second)
6.59.197.219 I slot print_timing: id  3 | task 1330 |        eval time =    1527.42 ms /   140 tokens (   10.91 ms per token,    91.66 tokens per second)
6.59.197.220 I slot print_timing: id  3 | task 1330 |       total time =    2314.47 ms /   460 tokens
6.59.197.221 I slot print_timing: id  3 | task 1330 |    graphs reused =        850
6.59.197.221 I slot print_timing: id  3 | task 1330 | draft acceptance = 1.00000 (   93 accepted /    93 generated)
6.59.197.234 I statistics        draft-mtp: #calls(b,g,a) =   14   1289    994, #gen drafts =    994, #acc drafts =   958, #gen tokens =   1814, #acc tokens =  1739, dur(b,g,a) = 0.025, 4402.524, 2.259 ms
6.59.198.905 I slot      release: id  3 | task 1330 | stop processing: n_tokens = 64698, truncated = 0
6.59.198.967 I srv  update_slots: all slots are idle
6.59.422.322 I srv  params_from_: Chat format: peg-native
6.59.486.856 I slot get_availabl: id  3 | task -1 | selected slot by LCP similarity, sim_best = 1.000 (> 0.100 thold), f_keep = 1.000
6.59.487.512 I reasoning-budget: activated, budget=2147483647 tokens
6.59.487.592 I slot launch_slot_: id  3 | task 1382 | processing task, is_child = 0
6.59.487.662 I slot update_slots: id  3 | task 1382 | Checking checkpoint with [64538, 64538] against 64697...
6.59.541.773 W slot update_slots: id  3 | task 1382 | restored context checkpoint (pos_min = 64538, pos_max = 64538, n_tokens = 64539, n_past = 64539, size = 402.963 MiB)
7.00.046.932 I reasoning-budget: deactivated (natural end)
7.01.094.818 I slot print_timing: id  3 | task 1382 | n_decoded =    101, tg =  73.91 t/s
7.01.593.841 I slot print_timing: id  3 | task 1382 | prompt eval time =     239.89 ms /   177 tokens (    1.36 ms per token,   737.84 tokens per second)
7.01.593.863 I slot print_timing: id  3 | task 1382 |        eval time =    1865.60 ms /   142 tokens (   13.14 ms per token,    76.12 tokens per second)
7.01.593.864 I slot print_timing: id  3 | task 1382 |       total time =    2105.49 ms /   319 tokens
7.01.593.865 I slot print_timing: id  3 | task 1382 |    graphs reused =        889
7.01.593.866 I slot print_timing: id  3 | task 1382 | draft acceptance = 0.95604 (   87 accepted /    91 generated)
7.01.593.877 I statistics        draft-mtp: #calls(b,g,a) =   15   1344   1041, #gen drafts =   1041, #acc drafts =  1003, #gen tokens =   1905, #acc tokens =  1826, dur(b,g,a) = 0.027, 4595.827, 2.360 ms
7.01.595.505 I slot      release: id  3 | task 1382 | stop processing: n_tokens = 64858, truncated = 0
7.01.595.567 I srv  update_slots: all slots are idle
7.01.801.103 I srv  params_from_: Chat format: peg-native
7.01.868.533 I slot get_availabl: id  3 | task -1 | selected slot by LCP similarity, sim_best = 0.995 (> 0.100 thold), f_keep = 1.000
7.01.869.310 I reasoning-budget: activated, budget=2147483647 tokens
7.01.869.388 I slot launch_slot_: id  3 | task 1441 | processing task, is_child = 0
7.01.869.455 I slot update_slots: id  3 | task 1441 | Checking checkpoint with [64538, 64538] against 64857...
7.01.920.404 W slot update_slots: id  3 | task 1441 | restored context checkpoint (pos_min = 64538, pos_max = 64538, n_tokens = 64539, n_past = 64539, size = 402.963 MiB)
7.02.568.224 I slot create_check: id  3 | task 1441 | created context checkpoint 12 of 32 (pos_min = 64858, pos_max = 64858, n_tokens = 64859, size = 404.219 MiB)
7.03.189.872 I slot create_check: id  3 | task 1441 | created context checkpoint 13 of 32 (pos_min = 65175, pos_max = 65175, n_tokens = 65176, size = 405.463 MiB)
7.03.386.026 I reasoning-budget: deactivated (natural end)
7.04.351.760 I slot print_timing: id  3 | task 1441 | n_decoded =    102, tg =  90.94 t/s
7.04.862.820 I slot print_timing: id  3 | task 1441 | prompt eval time =    1360.61 ms /   641 tokens (    2.12 ms per token,   471.11 tokens per second)
7.04.862.842 I slot print_timing: id  3 | task 1441 |        eval time =    1639.43 ms /   153 tokens (   10.72 ms per token,    93.32 tokens per second)
7.04.862.843 I slot print_timing: id  3 | task 1441 |       total time =    3000.04 ms /   794 tokens
7.04.862.843 I slot print_timing: id  3 | task 1441 |    graphs reused =        937
7.04.862.844 I slot print_timing: id  3 | task 1441 | draft acceptance = 1.00000 (  100 accepted /   100 generated)
7.04.862.856 I statistics        draft-mtp: #calls(b,g,a) =   16   1396   1091, #gen drafts =   1091, #acc drafts =  1053, #gen tokens =   2005, #acc tokens =  1926, dur(b,g,a) = 0.029, 4786.959, 2.459 ms
7.04.864.490 I slot      release: id  3 | task 1441 | stop processing: n_tokens = 65332, truncated = 0
7.04.864.550 I srv  update_slots: all slots are idle
7.05.105.345 I srv  params_from_: Chat format: peg-native
7.05.170.371 I slot get_availabl: id  3 | task -1 | selected slot by LCP similarity, sim_best = 1.000 (> 0.100 thold), f_keep = 1.000
7.05.171.073 I reasoning-budget: activated, budget=2147483647 tokens
7.05.171.163 I slot launch_slot_: id  3 | task 1498 | processing task, is_child = 0
7.05.171.232 I slot update_slots: id  3 | task 1498 | Checking checkpoint with [65175, 65175] against 65331...
7.05.224.294 W slot update_slots: id  3 | task 1498 | restored context checkpoint (pos_min = 65175, pos_max = 65175, n_tokens = 65176, n_past = 65176, size = 405.463 MiB)
7.05.666.383 I reasoning-budget: deactivated (natural end)
7.07.371.069 I slot print_timing: id  3 | task 1498 | n_decoded =    131, tg =  66.83 t/s
7.07.496.789 I slot print_timing: id  3 | task 1498 | prompt eval time =     239.53 ms /   176 tokens (    1.36 ms per token,   734.78 tokens per second)
7.07.496.809 I slot print_timing: id  3 | task 1498 |        eval time =    2085.91 ms /   136 tokens (   15.34 ms per token,    65.20 tokens per second)
7.07.496.810 I slot print_timing: id  3 | task 1498 |       total time =    2325.43 ms /   312 tokens
7.07.496.811 I slot print_timing: id  3 | task 1498 |    graphs reused =        968
7.07.496.812 I slot print_timing: id  3 | task 1498 | draft acceptance = 0.97468 (   77 accepted /    79 generated)
7.07.496.822 I statistics        draft-mtp: #calls(b,g,a) =   17   1455   1135, #gen drafts =   1135, #acc drafts =  1096, #gen tokens =   2084, #acc tokens =  2003, dur(b,g,a) = 0.031, 4986.942, 2.567 ms
7.07.498.405 I slot      release: id  3 | task 1498 | stop processing: n_tokens = 65488, truncated = 0
7.07.498.465 I srv  update_slots: all slots are idle
9.35.393.378 I srv  params_from_: Chat format: peg-native
9.35.456.239 I slot get_availabl: id  3 | task -1 | selected slot by LCP similarity, sim_best = 0.948 (> 0.100 thold), f_keep = 0.941
9.35.456.910 I reasoning-budget: activated, budget=2147483647 tokens
9.35.457.000 I slot launch_slot_: id  3 | task 1561 | processing task, is_child = 0
9.35.457.067 I slot update_slots: id  3 | task 1561 | Checking checkpoint with [65175, 65175] against 61631...
9.35.457.087 I slot update_slots: id  3 | task 1561 | Checking checkpoint with [64858, 64858] against 61631...
9.35.457.088 I slot update_slots: id  3 | task 1561 | Checking checkpoint with [64538, 64538] against 61631...
9.35.457.089 I slot update_slots: id  3 | task 1561 | Checking checkpoint with [64236, 64236] against 61631...
9.35.457.089 I slot update_slots: id  3 | task 1561 | Checking checkpoint with [63859, 63859] against 61631...
9.35.457.090 I slot update_slots: id  3 | task 1561 | Checking checkpoint with [63509, 63509] against 61631...
9.35.457.090 I slot update_slots: id  3 | task 1561 | Checking checkpoint with [63068, 63068] against 61631...
9.35.457.090 I slot update_slots: id  3 | task 1561 | Checking checkpoint with [62635, 62635] against 61631...
9.35.457.091 I slot update_slots: id  3 | task 1561 | Checking checkpoint with [62217, 62217] against 61631...
9.35.457.091 I slot update_slots: id  3 | task 1561 | Checking checkpoint with [61562, 61562] against 61631...
9.35.593.776 W slot update_slots: id  3 | task 1561 | restored context checkpoint (pos_min = 61562, pos_max = 61562, n_tokens = 61563, n_past = 61563, size = 391.281 MiB)
9.35.593.800 W slot update_slots: id  3 | task 1561 | erased invalidated context checkpoint (pos_min = 62217, pos_max = 62217, n_tokens = 62218, n_swa = 0, pos_next = 61563, size = 393.852 MiB)
9.35.615.684 W slot update_slots: id  3 | task 1561 | erased invalidated context checkpoint (pos_min = 62635, pos_max = 62635, n_tokens = 62636, n_swa = 0, pos_next = 61563, size = 395.493 MiB)
9.35.637.529 W slot update_slots: id  3 | task 1561 | erased invalidated context checkpoint (pos_min = 63068, pos_max = 63068, n_tokens = 63069, n_swa = 0, pos_next = 61563, size = 397.192 MiB)
9.35.660.252 W slot update_slots: id  3 | task 1561 | erased invalidated context checkpoint (pos_min = 63509, pos_max = 63509, n_tokens = 63510, n_swa = 0, pos_next = 61563, size = 398.923 MiB)
9.35.682.249 W slot update_slots: id  3 | task 1561 | erased invalidated context checkpoint (pos_min = 63859, pos_max = 63859, n_tokens = 63860, n_swa = 0, pos_next = 61563, size = 400.297 MiB)
9.35.704.669 W slot update_slots: id  3 | task 1561 | erased invalidated context checkpoint (pos_min = 64236, pos_max = 64236, n_tokens = 64237, n_swa = 0, pos_next = 61563, size = 401.777 MiB)
9.35.727.084 W slot update_slots: id  3 | task 1561 | erased invalidated context checkpoint (pos_min = 64538, pos_max = 64538, n_tokens = 64539, n_swa = 0, pos_next = 61563, size = 402.963 MiB)
9.35.749.474 W slot update_slots: id  3 | task 1561 | erased invalidated context checkpoint (pos_min = 64858, pos_max = 64858, n_tokens = 64859, n_swa = 0, pos_next = 61563, size = 404.219 MiB)
9.35.772.085 W slot update_slots: id  3 | task 1561 | erased invalidated context checkpoint (pos_min = 65175, pos_max = 65175, n_tokens = 65176, n_swa = 0, pos_next = 61563, size = 405.463 MiB)
9.38.294.414 I slot create_check: id  3 | task 1561 | created context checkpoint 5 of 32 (pos_min = 64920, pos_max = 64920, n_tokens = 64921, size = 404.462 MiB)
9.40.171.919 I slot print_timing: id  3 | task 1561 | n_decoded =    102, tg =  58.29 t/s
9.40.954.883 I slot print_timing: id  3 | task 1561 | prompt eval time =    2964.35 ms /  3445 tokens (    0.86 ms per token,  1162.14 tokens per second)
9.40.954.905 I slot print_timing: id  3 | task 1561 |        eval time =    2532.69 ms /   176 tokens (   14.39 ms per token,    69.49 tokens per second)
9.40.954.905 I slot print_timing: id  3 | task 1561 |       total time =    5497.04 ms /  3621 tokens
9.40.954.906 I slot print_timing: id  3 | task 1561 |    graphs reused =       1013
9.40.954.907 I slot print_timing: id  3 | task 1561 | draft acceptance = 0.93519 (  101 accepted /   108 generated)
9.40.954.919 I statistics        draft-mtp: #calls(b,g,a) =   18   1529   1198, #gen drafts =   1198, #acc drafts =  1155, #gen tokens =   2192, #acc tokens =  2104, dur(b,g,a) = 0.033, 5252.602, 2.704 ms
9.40.956.525 I slot      release: id  3 | task 1561 | stop processing: n_tokens = 65183, truncated = 0
9.40.956.583 I srv  update_slots: all slots are idle
10.43.900.057 I srv  params_from_: Chat format: peg-native
10.43.964.048 I slot get_availabl: id  3 | task -1 | selected slot by LCP similarity, sim_best = 1.000 (> 0.100 thold), f_keep = 0.997
10.43.964.843 I reasoning-budget: activated, budget=2147483647 tokens
10.43.964.945 I slot launch_slot_: id  3 | task 1641 | processing task, is_child = 0
10.43.965.027 I slot update_slots: id  3 | task 1641 | Checking checkpoint with [64920, 64920] against 65005...
10.44.107.160 W slot update_slots: id  3 | task 1641 | restored context checkpoint (pos_min = 64920, pos_max = 64920, n_tokens = 64921, n_past = 64921, size = 404.462 MiB)
10.46.338.690 I slot print_timing: id  3 | task 1641 | n_decoded =    100, tg =  54.27 t/s
10.48.187.091 I slot print_timing: id  3 | task 1641 | prompt eval time =     530.93 ms /   115 tokens (    4.62 ms per token,   216.60 tokens per second)
10.48.187.111 I slot print_timing: id  3 | task 1641 |        eval time =    3691.02 ms /   257 tokens (   14.36 ms per token,    69.63 tokens per second)
10.48.187.111 I slot print_timing: id  3 | task 1641 |       total time =    4221.95 ms /   372 tokens
10.48.187.112 I slot print_timing: id  3 | task 1641 |    graphs reused =       1082
10.48.187.113 I slot print_timing: id  3 | task 1641 | draft acceptance = 0.94268 (  148 accepted /   157 generated)
10.48.187.124 I statistics        draft-mtp: #calls(b,g,a) =   19   1637   1282, #gen drafts =   1282, #acc drafts =  1235, #gen tokens =   2349, #acc tokens =  2252, dur(b,g,a) = 0.035, 5629.094, 2.892 ms
10.48.188.736 I slot      release: id  3 | task 1641 | stop processing: n_tokens = 65292, truncated = 0
10.48.188.804 I srv  update_slots: all slots are idle
11.20.566.322 I srv  params_from_: Chat format: peg-native
11.20.637.953 I slot get_availabl: id  3 | task -1 | selected slot by LCP similarity, sim_best = 0.995 (> 0.100 thold), f_keep = 0.996
11.20.638.748 I reasoning-budget: activated, budget=2147483647 tokens
11.20.638.841 I slot launch_slot_: id  3 | task 1753 | processing task, is_child = 0
11.20.638.929 I slot update_slots: id  3 | task 1753 | Checking checkpoint with [64920, 64920] against 65033...
11.20.798.062 W slot update_slots: id  3 | task 1753 | restored context checkpoint (pos_min = 64920, pos_max = 64920, n_tokens = 64921, n_past = 64921, size = 404.462 MiB)
11.21.820.570 I slot create_check: id  3 | task 1753 | created context checkpoint 6 of 32 (pos_min = 65327, pos_max = 65327, n_tokens = 65328, size = 406.060 MiB)
11.24.224.852 I slot print_timing: id  3 | task 1753 | n_decoded =    100, tg =  42.36 t/s
11.26.112.526 I slot print_timing: id  3 | task 1753 | prompt eval time =    1225.21 ms /   411 tokens (    2.98 ms per token,   335.45 tokens per second)
11.26.112.549 I slot print_timing: id  3 | task 1753 |        eval time =    4664.98 ms /   284 tokens (   16.43 ms per token,    60.88 tokens per second)
11.26.112.550 I slot print_timing: id  3 | task 1753 |       total time =    5890.18 ms /   695 tokens
11.26.112.550 I slot print_timing: id  3 | task 1753 |    graphs reused =       1159
11.26.112.551 I slot print_timing: id  3 | task 1753 | draft acceptance = 0.92899 (  157 accepted /   169 generated)
11.26.112.564 I statistics        draft-mtp: #calls(b,g,a) =   20   1763   1375, #gen drafts =   1375, #acc drafts =  1322, #gen tokens =   2518, #acc tokens =  2409, dur(b,g,a) = 0.037, 6088.632, 3.109 ms
11.26.114.335 I slot      release: id  3 | task 1753 | stop processing: n_tokens = 65615, truncated = 0
11.26.114.412 I srv  update_slots: all slots are idle
11.58.411.419 I srv  params_from_: Chat format: peg-native
11.58.481.663 I slot get_availabl: id  3 | task -1 | selected slot by LCP similarity, sim_best = 1.000 (> 0.100 thold), f_keep = 0.996
11.58.482.482 I reasoning-budget: activated, budget=2147483647 tokens
11.58.482.566 I slot launch_slot_: id  3 | task 1883 | processing task, is_child = 0
11.58.482.642 I slot update_slots: id  3 | task 1883 | Checking checkpoint with [65327, 65327] against 65329...
11.58.636.768 W slot update_slots: id  3 | task 1883 | restored context checkpoint (pos_min = 65327, pos_max = 65327, n_tokens = 65328, n_past = 65328, size = 406.060 MiB)
12.00.852.077 I slot print_timing: id  3 | task 1883 | n_decoded =    101, tg =  44.30 t/s
12.03.879.665 I slot print_timing: id  3 | task 1883 | n_decoded =    294, tg =  55.40 t/s
12.05.657.896 I reasoning-budget: deactivated (natural end)
12.06.906.211 I slot print_timing: id  3 | task 1883 | n_decoded =    479, tg =  57.48 t/s
12.09.092.357 I slot print_timing: id  3 | task 1883 | prompt eval time =     505.66 ms /    33 tokens (   15.32 ms per token,    65.26 tokens per second)
12.09.092.377 I slot print_timing: id  3 | task 1883 |        eval time =   10520.05 ms /   678 tokens (   15.52 ms per token,    64.45 tokens per second)
12.09.092.378 I slot print_timing: id  3 | task 1883 |       total time =   11025.71 ms /   711 tokens
12.09.092.379 I slot print_timing: id  3 | task 1883 |    graphs reused =       1355
12.09.092.380 I slot print_timing: id  3 | task 1883 | draft acceptance = 0.94819 (  366 accepted /   386 generated)
12.09.092.391 I statistics        draft-mtp: #calls(b,g,a) =   21   2074   1589, #gen drafts =   1589, #acc drafts =  1525, #gen tokens =   2904, #acc tokens =  2775, dur(b,g,a) = 0.038, 7107.272, 3.572 ms
12.09.094.066 I slot      release: id  3 | task 1883 | stop processing: n_tokens = 66038, truncated = 0
12.09.094.134 I srv  update_slots: all slots are idle
12.09.332.839 I srv  params_from_: Chat format: peg-native
12.09.397.982 I slot get_availabl: id  3 | task -1 | selected slot by LCP similarity, sim_best = 0.992 (> 0.100 thold), f_keep = 1.000
12.09.398.749 I reasoning-budget: activated, budget=2147483647 tokens
12.09.398.834 I slot launch_slot_: id  3 | task 2198 | processing task, is_child = 0
12.09.398.887 I slot update_slots: id  3 | task 2198 | Checking checkpoint with [65327, 65327] against 66037...
12.09.451.495 W slot update_slots: id  3 | task 2198 | restored context checkpoint (pos_min = 65327, pos_max = 65327, n_tokens = 65328, n_past = 65328, size = 406.060 MiB)
12.25.272.268 I slot create_check: id  3 | task 2198 | created context checkpoint 7 of 32 (pos_min = 66039, pos_max = 66039, n_tokens = 66040, size = 408.855 MiB)
12.26.083.867 I slot create_check: id  3 | task 2198 | created context checkpoint 8 of 32 (pos_min = 66566, pos_max = 66566, n_tokens = 66567, size = 410.923 MiB)
12.27.751.457 I reasoning-budget: deactivated (natural end)
12.28.083.276 I slot print_timing: id  3 | task 2198 | n_decoded =    101, tg =  51.54 t/s
12.15.048.491 I slot print_timing: id  3 | task 2198 | prompt eval time =    1758.53 ms /  1243 tokens (    1.41 ms per token,   706.84 tokens per second)
12.15.048.511 I slot print_timing: id  3 | task 2198 |        eval time =    3890.38 ms /   254 tokens (   15.32 ms per token,    65.29 tokens per second)
12.15.048.512 I slot print_timing: id  3 | task 2198 |       total time =    5648.91 ms /  1497 tokens
12.15.048.513 I slot print_timing: id  3 | task 2198 |    graphs reused =       1419
12.15.048.513 I slot print_timing: id  3 | task 2198 | draft acceptance = 0.97260 (  142 accepted /   146 generated)
12.15.048.525 I statistics        draft-mtp: #calls(b,g,a) =   22   2185   1670, #gen drafts =   1670, #acc drafts =  1603, #gen tokens =   3050, #acc tokens =  2917, dur(b,g,a) = 0.039, 7477.469, 3.765 ms
12.15.050.162 I slot      release: id  3 | task 2198 | stop processing: n_tokens = 66824, truncated = 0
12.15.050.226 I srv  update_slots: all slots are idle
12.15.283.922 I srv  params_from_: Chat format: peg-native
12.15.350.570 I slot get_availabl: id  3 | task -1 | selected slot by LCP similarity, sim_best = 0.991 (> 0.100 thold), f_keep = 0.996
12.15.351.363 I reasoning-budget: activated, budget=2147483647 tokens
12.15.351.447 I slot launch_slot_: id  3 | task 2314 | processing task, is_child = 0
12.15.351.514 I slot update_slots: id  3 | task 2314 | Checking checkpoint with [66566, 66566] against 66569...
12.15.404.543 W slot update_slots: id  3 | task 2314 | restored context checkpoint (pos_min = 66566, pos_max = 66566, n_tokens = 66567, n_past = 66567, size = 410.923 MiB)
12.16.080.801 I slot create_check: id  3 | task 2314 | created context checkpoint 9 of 32 (pos_min = 66944, pos_max = 66944, n_tokens = 66945, size = 412.407 MiB)
12.17.973.558 I slot print_timing: id  3 | task 2314 | n_decoded =    100, tg =  58.65 t/s
12.19.890.474 I reasoning-budget: deactivated (natural end)
12.20.993.013 I slot print_timing: id  3 | task 2314 | n_decoded =    268, tg =  56.65 t/s
12.21.211.397 I slot print_timing: id  3 | task 2314 | prompt eval time =     916.76 ms /   574 tokens (    1.60 ms per token,   626.12 tokens per second)
12.21.211.418 I slot print_timing: id  3 | task 2314 |        eval time =    4948.99 ms /   281 tokens (   17.61 ms per token,    56.78 tokens per second)
12.21.211.419 I slot print_timing: id  3 | task 2314 |       total time =    5865.75 ms /   855 tokens
12.21.211.420 I slot print_timing: id  3 | task 2314 |    graphs reused =       1478
12.21.211.421 I slot print_timing: id  3 | task 2314 | draft acceptance = 0.91720 (  144 accepted /   157 generated)
12.21.211.432 I statistics        draft-mtp: #calls(b,g,a) =   23   2322   1763, #gen drafts =   1763, #acc drafts =  1689, #gen tokens =   3207, #acc tokens =  3061, dur(b,g,a) = 0.041, 7922.860, 3.986 ms
12.21.213.021 I slot      release: id  3 | task 2314 | stop processing: n_tokens = 67422, truncated = 0
12.21.213.079 I srv  update_slots: all slots are idle
12.21.458.883 I srv  params_from_: Chat format: peg-native
12.21.526.594 I slot get_availabl: id  3 | task -1 | selected slot by LCP similarity, sim_best = 0.997 (> 0.100 thold), f_keep = 1.000
12.21.527.414 I reasoning-budget: activated, budget=2147483647 tokens
12.21.527.493 I slot launch_slot_: id  3 | task 2456 | processing task, is_child = 0
12.21.527.563 I slot update_slots: id  3 | task 2456 | Checking checkpoint with [66944, 66944] against 67421...
12.21.581.310 W slot update_slots: id  3 | task 2456 | restored context checkpoint (pos_min = 66944, pos_max = 66944, n_tokens = 66945, n_past = 66945, size = 412.407 MiB)
12.22.370.448 I slot create_check: id  3 | task 2456 | created context checkpoint 10 of 32 (pos_min = 67422, pos_max = 67422, n_tokens = 67423, size = 414.283 MiB)
12.23.738.850 I reasoning-budget: deactivated (natural end)
12.24.312.722 I slot print_timing: id  3 | task 2456 | prompt eval time =    1014.59 ms /   706 tokens (    1.44 ms per token,   695.85 tokens per second)
12.24.312.741 I slot print_timing: id  3 | task 2456 |        eval time =    1770.33 ms /    91 tokens (   19.45 ms per token,    51.40 tokens per second)
12.24.312.742 I slot print_timing: id  3 | task 2456 |       total time =    2784.92 ms /   797 tokens
12.24.312.743 I slot print_timing: id  3 | task 2456 |    graphs reused =       1497
12.24.312.744 I slot print_timing: id  3 | task 2456 | draft acceptance = 0.95455 (   42 accepted /    44 generated)
12.24.312.757 I statistics        draft-mtp: #calls(b,g,a) =   24   2372   1790, #gen drafts =   1790, #acc drafts =  1715, #gen tokens =   3251, #acc tokens =  3103, dur(b,g,a) = 0.043, 8072.406, 4.052 ms
12.24.314.308 I slot      release: id  3 | task 2456 | stop processing: n_tokens = 67743, truncated = 0
12.24.314.368 I srv  update_slots: all slots are idle
12.24.540.590 I srv  params_from_: Chat format: peg-native
12.24.608.626 I slot get_availabl: id  3 | task -1 | selected slot by LCP similarity, sim_best = 0.959 (> 0.100 thold), f_keep = 1.000
12.24.609.440 I reasoning-budget: activated, budget=2147483647 tokens
12.24.609.532 I slot launch_slot_: id  3 | task 2511 | processing task, is_child = 0
12.24.609.602 I slot update_slots: id  3 | task 2511 | Checking checkpoint with [67422, 67422] against 67742...
12.24.662.970 W slot update_slots: id  3 | task 2511 | restored context checkpoint (pos_min = 67422, pos_max = 67422, n_tokens = 67423, n_past = 67423, size = 414.283 MiB)
12.25.281.647 I slot create_check: id  3 | task 2511 | created context checkpoint 11 of 32 (pos_min = 67742, pos_max = 67742, n_tokens = 67743, size = 415.539 MiB)
12.27.277.098 I slot create_check: id  3 | task 2511 | created context checkpoint 12 of 32 (pos_min = 70131, pos_max = 70131, n_tokens = 70132, size = 424.917 MiB)
12.28.075.945 I slot create_check: id  3 | task 2511 | created context checkpoint 13 of 32 (pos_min = 70643, pos_max = 70643, n_tokens = 70644, size = 426.927 MiB)
12.29.823.585 I slot print_timing: id  3 | task 2511 | n_decoded =    100, tg =  58.55 t/s
12.32.283.635 I reasoning-budget: deactivated (natural end)
12.32.822.899 I slot print_timing: id  3 | task 2511 | n_decoded =    261, tg =  55.38 t/s
12.35.540.287 I slot print_timing: id  3 | task 2511 | prompt eval time =    3500.33 ms /  3225 tokens (    1.09 ms per token,   921.34 tokens per second)
12.35.540.308 I slot print_timing: id  3 | task 2511 |        eval time =    7423.94 ms /   433 tokens (   17.15 ms per token,    58.32 tokens per second)
12.35.540.309 I slot print_timing: id  3 | task 2511 |       total time =   10924.27 ms /  3658 tokens
12.35.540.310 I slot print_timing: id  3 | task 2511 |    graphs reused =       1602
12.35.540.311 I slot print_timing: id  3 | task 2511 | draft acceptance = 0.94937 (  225 accepted /   237 generated)
12.35.540.323 I statistics        draft-mtp: #calls(b,g,a) =   25   2579   1926, #gen drafts =   1926, #acc drafts =  1845, #gen tokens =   3488, #acc tokens =  3328, dur(b,g,a) = 0.045, 8754.659, 4.376 ms
12.35.542.115 I slot      release: id  3 | task 2511 | stop processing: n_tokens = 71080, truncated = 0
12.35.542.175 I srv  update_slots: all slots are idle
13.34.373.253 I srv  params_from_: Chat format: peg-native
13.34.449.435 I slot get_availabl: id  3 | task -1 | selected slot by LCP similarity, sim_best = 0.932 (> 0.100 thold), f_keep = 0.920
13.34.450.357 I reasoning-budget: activated, budget=2147483647 tokens
13.34.450.446 I slot launch_slot_: id  3 | task 2724 | processing task, is_child = 0
13.34.450.520 I slot update_slots: id  3 | task 2724 | Checking checkpoint with [70643, 70643] against 65358...
13.34.450.538 I slot update_slots: id  3 | task 2724 | Checking checkpoint with [70131, 70131] against 65358...
13.34.450.539 I slot update_slots: id  3 | task 2724 | Checking checkpoint with [67742, 67742] against 65358...
13.34.450.540 I slot update_slots: id  3 | task 2724 | Checking checkpoint with [67422, 67422] against 65358...
13.34.450.540 I slot update_slots: id  3 | task 2724 | Checking checkpoint with [66944, 66944] against 65358...
13.34.450.541 I slot update_slots: id  3 | task 2724 | Checking checkpoint with [66566, 66566] against 65358...
13.34.450.541 I slot update_slots: id  3 | task 2724 | Checking checkpoint with [66039, 66039] against 65358...
13.34.450.542 I slot update_slots: id  3 | task 2724 | Checking checkpoint with [65327, 65327] against 65358...
13.34.604.936 W slot update_slots: id  3 | task 2724 | restored context checkpoint (pos_min = 65327, pos_max = 65327, n_tokens = 65328, n_past = 65328, size = 406.060 MiB)
13.34.604.959 W slot update_slots: id  3 | task 2724 | erased invalidated context checkpoint (pos_min = 66039, pos_max = 66039, n_tokens = 66040, n_swa = 0, pos_next = 65328, size = 408.855 MiB)
13.34.631.460 W slot update_slots: id  3 | task 2724 | erased invalidated context checkpoint (pos_min = 66566, pos_max = 66566, n_tokens = 66567, n_swa = 0, pos_next = 65328, size = 410.923 MiB)
13.34.656.709 W slot update_slots: id  3 | task 2724 | erased invalidated context checkpoint (pos_min = 66944, pos_max = 66944, n_tokens = 66945, n_swa = 0, pos_next = 65328, size = 412.407 MiB)
13.34.681.839 W slot update_slots: id  3 | task 2724 | erased invalidated context checkpoint (pos_min = 67422, pos_max = 67422, n_tokens = 67423, n_swa = 0, pos_next = 65328, size = 414.283 MiB)
13.34.707.342 W slot update_slots: id  3 | task 2724 | erased invalidated context checkpoint (pos_min = 67742, pos_max = 67742, n_tokens = 67743, n_swa = 0, pos_next = 65328, size = 415.539 MiB)
13.34.733.363 W slot update_slots: id  3 | task 2724 | erased invalidated context checkpoint (pos_min = 70131, pos_max = 70131, n_tokens = 70132, n_swa = 0, pos_next = 65328, size = 424.917 MiB)
13.34.759.412 W slot update_slots: id  3 | task 2724 | erased invalidated context checkpoint (pos_min = 70643, pos_max = 70643, n_tokens = 70644, n_swa = 0, pos_next = 65328, size = 426.927 MiB)
13.37.270.404 I slot print_timing: id  3 | task 2724 | prompt processing, n_tokens =   4096, progress = 0.99, t =   3.23 s / 1268.25 tokens per second
13.37.437.437 I slot print_timing: id  3 | task 2724 | prompt processing, n_tokens =   4297, progress = 0.99, t =   3.40 s / 1265.06 tokens per second
13.37.762.292 I slot print_timing: id  3 | task 2724 | prompt processing, n_tokens =   4760, progress = 1.00, t =   3.72 s / 1279.04 tokens per second
13.38.156.681 I slot create_check: id  3 | task 2724 | created context checkpoint 7 of 32 (pos_min = 70087, pos_max = 70087, n_tokens = 70088, size = 424.744 MiB)
13.38.215.957 I slot print_timing: id  3 | task 2724 | prompt processing, n_tokens =   4809, progress = 1.00, t =   4.18 s / 1151.80 tokens per second
13.40.280.287 I slot print_timing: id  3 | task 2724 | n_decoded =    102, tg =  50.71 t/s
13.40.612.181 I reasoning-budget: deactivated (natural end)
13.41.352.155 I slot print_timing: id  3 | task 2724 | prompt eval time =    4227.97 ms /  4813 tokens (    0.88 ms per token,  1138.37 tokens per second)
13.41.352.175 I slot print_timing: id  3 | task 2724 |        eval time =    3500.00 ms /   199 tokens (   17.59 ms per token,    56.86 tokens per second)
13.41.352.175 I slot print_timing: id  3 | task 2724 |       total time =    7727.97 ms /  5012 tokens
13.41.352.176 I slot print_timing: id  3 | task 2724 |    graphs reused =       1653
13.41.352.177 I slot print_timing: id  3 | task 2724 | draft acceptance = 0.89076 (  106 accepted /   119 generated)
13.41.352.190 I statistics        draft-mtp: #calls(b,g,a) =   26   2671   1991, #gen drafts =   1991, #acc drafts =  1904, #gen tokens =   3607, #acc tokens =  3434, dur(b,g,a) = 0.047, 9084.894, 4.546 ms
13.41.353.873 I slot      release: id  3 | task 2724 | stop processing: n_tokens = 70339, truncated = 0
13.41.353.932 I srv  update_slots: all slots are idle
13.41.646.398 I srv  params_from_: Chat format: peg-native
13.41.716.220 I slot get_availabl: id  3 | task -1 | selected slot by LCP similarity, sim_best = 0.998 (> 0.100 thold), f_keep = 1.000
13.41.716.917 I reasoning-budget: activated, budget=2147483647 tokens
13.41.717.005 I slot launch_slot_: id  3 | task 2823 | processing task, is_child = 0
13.41.717.085 I slot update_slots: id  3 | task 2823 | Checking checkpoint with [70087, 70087] against 70338...
13.41.773.782 W slot update_slots: id  3 | task 2823 | restored context checkpoint (pos_min = 70087, pos_max = 70087, n_tokens = 70088, n_past = 70088, size = 424.744 MiB)
13.42.541.636 I slot create_check: id  3 | task 2823 | created context checkpoint 8 of 32 (pos_min = 70508, pos_max = 70508, n_tokens = 70509, size = 426.397 MiB)
13.43.252.797 I reasoning-budget: deactivated (natural end)
13.43.906.200 I slot print_timing: id  3 | task 2823 | prompt eval time =     863.61 ms /   425 tokens (    2.03 ms per token,   492.12 tokens per second)
13.43.906.220 I slot print_timing: id  3 | task 2823 |        eval time =    1325.75 ms /    93 tokens (   14.26 ms per token,    70.15 tokens per second)
13.43.906.221 I slot print_timing: id  3 | task 2823 |       total time =    2189.36 ms /   518 tokens
13.43.906.222 I slot print_timing: id  3 | task 2823 |    graphs reused =       1675
13.43.906.222 I slot print_timing: id  3 | task 2823 | draft acceptance = 0.98214 (   55 accepted /    56 generated)
13.43.906.234 I statistics        draft-mtp: #calls(b,g,a) =   27   2708   2022, #gen drafts =   2022, #acc drafts =  1934, #gen tokens =   3663, #acc tokens =  3489, dur(b,g,a) = 0.048, 9216.728, 4.612 ms
13.43.907.943 I slot      release: id  3 | task 2823 | stop processing: n_tokens = 70605, truncated = 0
13.43.908.006 I srv  update_slots: all slots are idle
13.44.149.694 I srv  params_from_: Chat format: peg-native
13.44.219.705 I slot get_availabl: id  3 | task -1 | selected slot by LCP similarity, sim_best = 0.997 (> 0.100 thold), f_keep = 1.000
13.44.220.357 I reasoning-budget: activated, budget=2147483647 tokens
13.44.220.440 I slot launch_slot_: id  3 | task 2864 | processing task, is_child = 0
13.44.220.512 I slot update_slots: id  3 | task 2864 | Checking checkpoint with [70508, 70508] against 70604...
13.44.275.216 W slot update_slots: id  3 | task 2864 | restored context checkpoint (pos_min = 70508, pos_max = 70508, n_tokens = 70509, n_past = 70509, size = 426.397 MiB)
13.44.989.778 I slot create_check: id  3 | task 2864 | created context checkpoint 9 of 32 (pos_min = 70798, pos_max = 70798, n_tokens = 70799, size = 427.535 MiB)
13.46.838.202 I reasoning-budget: deactivated (natural end)
13.47.039.853 I slot print_timing: id  3 | task 2864 | n_decoded =    102, tg =  50.77 t/s
13.47.605.492 I slot print_timing: id  3 | task 2864 | prompt eval time =     809.07 ms /   294 tokens (    2.75 ms per token,   363.38 tokens per second)
13.47.605.512 I slot print_timing: id  3 | task 2864 |        eval time =    2574.57 ms /   141 tokens (   18.26 ms per token,    54.77 tokens per second)
13.47.605.513 I slot print_timing: id  3 | task 2864 |       total time =    3383.64 ms /   435 tokens
13.47.605.513 I slot print_timing: id  3 | task 2864 |    graphs reused =       1709
13.47.605.514 I slot print_timing: id  3 | task 2864 | draft acceptance = 0.89474 (   68 accepted /    76 generated)
13.47.605.525 I statistics        draft-mtp: #calls(b,g,a) =   28   2780   2068, #gen drafts =   2068, #acc drafts =  1976, #gen tokens =   3739, #acc tokens =  3557, dur(b,g,a) = 0.050, 9443.969, 4.720 ms
13.47.607.215 I slot      release: id  3 | task 2864 | stop processing: n_tokens = 70943, truncated = 0
13.47.607.275 I srv  update_slots: all slots are idle
13.47.838.451 I srv  params_from_: Chat format: peg-native
13.47.909.429 I slot get_availabl: id  3 | task -1 | selected slot by LCP similarity, sim_best = 0.998 (> 0.100 thold), f_keep = 1.000
13.47.910.209 I reasoning-budget: activated, budget=2147483647 tokens
13.47.910.300 I slot launch_slot_: id  3 | task 2940 | processing task, is_child = 0
13.47.910.373 I slot update_slots: id  3 | task 2940 | Checking checkpoint with [70798, 70798] against 70942...
13.47.966.906 W slot update_slots: id  3 | task 2940 | restored context checkpoint (pos_min = 70798, pos_max = 70798, n_tokens = 70799, n_past = 70799, size = 427.535 MiB)
13.48.652.553 I slot create_check: id  3 | task 2940 | created context checkpoint 10 of 32 (pos_min = 71056, pos_max = 71056, n_tokens = 71057, size = 428.548 MiB)
13.49.911.880 I reasoning-budget: deactivated (natural end)
13.50.249.048 I slot print_timing: id  3 | task 2940 | n_decoded =    101, tg =  64.90 t/s
13.50.723.549 I slot print_timing: id  3 | task 2940 | prompt eval time =     782.42 ms /   262 tokens (    2.99 ms per token,   334.86 tokens per second)
13.50.723.570 I slot print_timing: id  3 | task 2940 |        eval time =    2030.67 ms /   135 tokens (   15.04 ms per token,    66.48 tokens per second)
13.50.723.571 I slot print_timing: id  3 | task 2940 |       total time =    2813.09 ms /   397 tokens
13.50.723.572 I slot print_timing: id  3 | task 2940 |    graphs reused =       1734
13.50.723.572 I slot print_timing: id  3 | task 2940 | draft acceptance = 1.00000 (   79 accepted /    79 generated)
13.50.723.584 I statistics        draft-mtp: #calls(b,g,a) =   29   2835   2111, #gen drafts =   2111, #acc drafts =  2019, #gen tokens =   3818, #acc tokens =  3636, dur(b,g,a) = 0.052, 9637.677, 4.818 ms
13.50.725.301 I slot      release: id  3 | task 2940 | stop processing: n_tokens = 71195, truncated = 0
13.50.725.361 I srv  update_slots: all slots are idle
13.50.983.673 I srv  params_from_: Chat format: peg-native
13.51.055.154 I slot get_availabl: id  3 | task -1 | selected slot by LCP similarity, sim_best = 0.998 (> 0.100 thold), f_keep = 1.000
13.51.055.847 I reasoning-budget: activated, budget=2147483647 tokens
13.51.055.931 I slot launch_slot_: id  3 | task 2999 | processing task, is_child = 0
13.51.056.004 I slot update_slots: id  3 | task 2999 | Checking checkpoint with [71056, 71056] against 71194...
13.51.110.804 W slot update_slots: id  3 | task 2999 | restored context checkpoint (pos_min = 71056, pos_max = 71056, n_tokens = 71057, n_past = 71057, size = 428.548 MiB)
13.51.813.129 I slot create_check: id  3 | task 2999 | created context checkpoint 11 of 32 (pos_min = 71364, pos_max = 71364, n_tokens = 71365, size = 429.757 MiB)
13.53.145.101 I reasoning-budget: deactivated (natural end)
13.53.511.436 I slot print_timing: id  3 | task 2999 | n_decoded =    101, tg =  60.92 t/s
13.55.865.826 I slot print_timing: id  3 | task 2999 | prompt eval time =     797.35 ms /   312 tokens (    2.56 ms per token,   391.30 tokens per second)
13.55.865.847 I slot print_timing: id  3 | task 2999 |        eval time =    4018.11 ms /   298 tokens (   13.48 ms per token,    74.16 tokens per second)
13.55.865.848 I slot print_timing: id  3 | task 2999 |       total time =    4815.46 ms /   610 tokens
13.55.865.849 I slot print_timing: id  3 | task 2999 |    graphs reused =       1810
13.55.865.850 I slot print_timing: id  3 | task 2999 | draft acceptance = 0.98387 (  183 accepted /   186 generated)
13.55.865.860 I statistics        draft-mtp: #calls(b,g,a) =   30   2949   2208, #gen drafts =   2208, #acc drafts =  2115, #gen tokens =   4004, #acc tokens =  3819, dur(b,g,a) = 0.053, 10048.243, 5.022 ms
13.55.867.555 I slot      release: id  3 | task 2999 | stop processing: n_tokens = 71666, truncated = 0
13.55.867.616 I srv  update_slots: all slots are idle
13.56.153.733 I srv  params_from_: Chat format: peg-native
13.56.226.980 I slot get_availabl: id  3 | task -1 | selected slot by LCP similarity, sim_best = 1.000 (> 0.100 thold), f_keep = 1.000
13.56.227.733 I reasoning-budget: activated, budget=2147483647 tokens
13.56.227.820 I slot launch_slot_: id  3 | task 3117 | processing task, is_child = 0
13.56.227.892 I slot update_slots: id  3 | task 3117 | Checking checkpoint with [71364, 71364] against 71665...
13.56.284.597 W slot update_slots: id  3 | task 3117 | restored context checkpoint (pos_min = 71364, pos_max = 71364, n_tokens = 71365, n_past = 71365, size = 429.757 MiB)
13.56.962.906 I slot create_check: id  3 | task 3117 | created context checkpoint 12 of 32 (pos_min = 71667, pos_max = 71667, n_tokens = 71668, size = 430.946 MiB)
13.57.282.639 I reasoning-budget: deactivated (natural end)
13.58.303.571 I slot print_timing: id  3 | task 3117 | n_decoded =    102, tg =  81.85 t/s
13.58.978.649 I slot print_timing: id  3 | task 3117 | prompt eval time =     829.45 ms /   321 tokens (    2.58 ms per token,   387.01 tokens per second)
13.58.978.670 I slot print_timing: id  3 | task 3117 |        eval time =    1920.94 ms /   151 tokens (   12.72 ms per token,    78.61 tokens per second)
13.58.978.671 I slot print_timing: id  3 | task 3117 |       total time =    2750.39 ms /   472 tokens
13.58.978.672 I slot print_timing: id  3 | task 3117 |    graphs reused =       1854
13.58.978.673 I slot print_timing: id  3 | task 3117 | draft acceptance = 1.00000 (   96 accepted /    96 generated)
13.58.978.685 I statistics        draft-mtp: #calls(b,g,a) =   31   3005   2258, #gen drafts =   2258, #acc drafts =  2165, #gen tokens =   4100, #acc tokens =  3915, dur(b,g,a) = 0.054, 10252.192, 5.123 ms
13.58.980.411 I slot      release: id  3 | task 3117 | stop processing: n_tokens = 71838, truncated = 0
13.58.980.473 I srv  update_slots: all slots are idle
13.59.217.876 I srv  params_from_: Chat format: peg-native
13.59.290.038 I slot get_availabl: id  3 | task -1 | selected slot by LCP similarity, sim_best = 1.000 (> 0.100 thold), f_keep = 1.000
13.59.290.780 I reasoning-budget: activated, budget=2147483647 tokens
13.59.290.866 I slot launch_slot_: id  3 | task 3177 | processing task, is_child = 0
13.59.290.938 I slot update_slots: id  3 | task 3177 | Checking checkpoint with [71667, 71667] against 71837...
13.59.347.430 W slot update_slots: id  3 | task 3177 | restored context checkpoint (pos_min = 71667, pos_max = 71667, n_tokens = 71668, n_past = 71668, size = 430.946 MiB)
14.15.128.661 I reasoning-budget: deactivated (natural end)
14.01.311.183 I slot print_timing: id  3 | task 3177 | n_decoded =    139, tg =  80.10 t/s
14.02.546.934 I slot print_timing: id  3 | task 3177 | prompt eval time =     285.34 ms /   188 tokens (    1.52 ms per token,   658.87 tokens per second)
14.02.546.956 I slot print_timing: id  3 | task 3177 |        eval time =    2970.84 ms /   232 tokens (   12.81 ms per token,    78.09 tokens per second)
14.02.546.956 I slot print_timing: id  3 | task 3177 |       total time =    3256.17 ms /   420 tokens
14.02.546.958 I slot print_timing: id  3 | task 3177 |    graphs reused =       1917
14.02.546.958 I slot print_timing: id  3 | task 3177 | draft acceptance = 0.99324 (  147 accepted /   148 generated)
14.02.546.971 I statistics        draft-mtp: #calls(b,g,a) =   32   3091   2333, #gen drafts =   2333, #acc drafts =  2240, #gen tokens =   4248, #acc tokens =  4062, dur(b,g,a) = 0.055, 10566.371, 5.311 ms
14.02.548.698 I slot      release: id  3 | task 3177 | stop processing: n_tokens = 72089, truncated = 0
14.02.548.765 I srv  update_slots: all slots are idle
14.02.792.973 I srv  params_from_: Chat format: peg-native
14.02.871.022 I slot get_availabl: id  3 | task -1 | selected slot by LCP similarity, sim_best = 1.000 (> 0.100 thold), f_keep = 1.000
14.02.871.820 I reasoning-budget: activated, budget=2147483647 tokens
14.02.871.918 I slot launch_slot_: id  3 | task 3267 | processing task, is_child = 0
14.02.871.994 I slot update_slots: id  3 | task 3267 | Checking checkpoint with [71667, 71667] against 72088...
14.02.929.089 W slot update_slots: id  3 | task 3267 | restored context checkpoint (pos_min = 71667, pos_max = 71667, n_tokens = 71668, n_past = 71668, size = 430.946 MiB)
14.03.680.275 I slot create_check: id  3 | task 3267 | created context checkpoint 13 of 32 (pos_min = 72088, pos_max = 72088, n_tokens = 72089, size = 432.599 MiB)
14.04.042.698 I reasoning-budget: deactivated (natural end)
14.04.967.998 I slot print_timing: id  3 | task 3267 | n_decoded =    102, tg =  85.50 t/s
14.05.348.610 I slot print_timing: id  3 | task 3267 | prompt eval time =     902.98 ms /   439 tokens (    2.06 ms per token,   486.17 tokens per second)
14.05.348.630 I slot print_timing: id  3 | task 3267 |        eval time =    1566.82 ms /   137 tokens (   11.44 ms per token,    87.44 tokens per second)
14.05.348.631 I slot print_timing: id  3 | task 3267 |       total time =    2469.80 ms /   576 tokens
14.05.348.632 I slot print_timing: id  3 | task 3267 |    graphs reused =       1960
14.05.348.633 I slot print_timing: id  3 | task 3267 | draft acceptance = 1.00000 (   89 accepted /    89 generated)
14.05.348.646 I statistics        draft-mtp: #calls(b,g,a) =   33   3139   2378, #gen drafts =   2378, #acc drafts =  2285, #gen tokens =   4337, #acc tokens =  4151, dur(b,g,a) = 0.056, 10748.346, 5.402 ms
14.05.350.392 I slot      release: id  3 | task 3267 | stop processing: n_tokens = 72244, truncated = 0
14.05.350.452 I srv  update_slots: all slots are idle
14.05.589.886 I srv  params_from_: Chat format: peg-native
14.05.662.545 I slot get_availabl: id  3 | task -1 | selected slot by LCP similarity, sim_best = 1.000 (> 0.100 thold), f_keep = 1.000
14.05.663.249 I reasoning-budget: activated, budget=2147483647 tokens
14.05.663.338 I slot launch_slot_: id  3 | task 3319 | processing task, is_child = 0
14.05.663.410 I slot update_slots: id  3 | task 3319 | Checking checkpoint with [72088, 72088] against 72243...
14.05.719.570 W slot update_slots: id  3 | task 3319 | restored context checkpoint (pos_min = 72088, pos_max = 72088, n_tokens = 72089, n_past = 72089, size = 432.599 MiB)
14.06.306.602 I reasoning-budget: deactivated (natural end)
14.07.984.574 I slot print_timing: id  3 | task 3319 | n_decoded =    164, tg =  79.18 t/s
14.08.610.201 I slot print_timing: id  3 | task 3319 | prompt eval time =     249.73 ms /   174 tokens (    1.44 ms per token,   696.75 tokens per second)
14.08.610.221 I slot print_timing: id  3 | task 3319 |        eval time =    2696.95 ms /   210 tokens (   12.84 ms per token,    77.87 tokens per second)
14.08.610.221 I slot print_timing: id  3 | task 3319 |       total time =    2946.68 ms /   384 tokens
14.08.610.222 I slot print_timing: id  3 | task 3319 |    graphs reused =       2018
14.08.610.223 I slot print_timing: id  3 | task 3319 | draft acceptance = 0.98496 (  131 accepted /   133 generated)
14.08.610.234 I statistics        draft-mtp: #calls(b,g,a) =   34   3218   2446, #gen drafts =   2446, #acc drafts =  2352, #gen tokens =   4470, #acc tokens =  4282, dur(b,g,a) = 0.058, 11033.056, 5.544 ms
14.08.611.949 I slot      release: id  3 | task 3319 | stop processing: n_tokens = 72473, truncated = 0
14.08.612.012 I srv  update_slots: all slots are idle
14.08.858.101 I srv  params_from_: Chat format: peg-native
14.08.931.214 I slot get_availabl: id  3 | task -1 | selected slot by LCP similarity, sim_best = 1.000 (> 0.100 thold), f_keep = 1.000
14.08.931.958 I reasoning-budget: activated, budget=2147483647 tokens
14.08.932.047 I slot launch_slot_: id  3 | task 3402 | processing task, is_child = 0
14.08.932.121 I slot update_slots: id  3 | task 3402 | Checking checkpoint with [72088, 72088] against 72472...
14.08.989.100 W slot update_slots: id  3 | task 3402 | restored context checkpoint (pos_min = 72088, pos_max = 72088, n_tokens = 72089, n_past = 72089, size = 432.599 MiB)
14.09.736.901 I slot create_check: id  3 | task 3402 | created context checkpoint 14 of 32 (pos_min = 72473, pos_max = 72473, n_tokens = 72474, size = 434.110 MiB)
14.10.321.620 I reasoning-budget: deactivated (natural end)
14.11.208.999 I slot print_timing: id  3 | task 3402 | prompt eval time =     898.25 ms /   403 tokens (    2.23 ms per token,   448.65 tokens per second)
14.11.209.020 I slot print_timing: id  3 | task 3402 |        eval time =    1378.56 ms /    90 tokens (   15.32 ms per token,    65.29 tokens per second)
14.11.209.021 I slot print_timing: id  3 | task 3402 |       total time =    2276.82 ms /   493 tokens
14.11.209.022 I slot print_timing: id  3 | task 3402 |    graphs reused =       2040
14.11.209.022 I slot print_timing: id  3 | task 3402 | draft acceptance = 0.89474 (   51 accepted /    57 generated)
14.11.209.033 I statistics        draft-mtp: #calls(b,g,a) =   35   3256   2478, #gen drafts =   2478, #acc drafts =  2380, #gen tokens =   4527, #acc tokens =  4333, dur(b,g,a) = 0.060, 11168.557, 5.613 ms
14.11.210.766 I slot      release: id  3 | task 3402 | stop processing: n_tokens = 72581, truncated = 0
14.11.210.830 I srv  update_slots: all slots are idle
14.11.457.987 I srv  params_from_: Chat format: peg-native
14.11.531.800 I slot get_availabl: id  3 | task -1 | selected slot by LCP similarity, sim_best = 0.998 (> 0.100 thold), f_keep = 1.000
14.11.532.649 I reasoning-budget: activated, budget=2147483647 tokens
14.11.532.745 I slot launch_slot_: id  3 | task 3444 | processing task, is_child = 0
14.11.532.818 I slot update_slots: id  3 | task 3444 | Checking checkpoint with [72473, 72473] against 72580...
14.11.590.233 W slot update_slots: id  3 | task 3444 | restored context checkpoint (pos_min = 72473, pos_max = 72473, n_tokens = 72474, n_past = 72474, size = 434.110 MiB)
14.12.253.784 I reasoning-budget: deactivated (natural end)
14.12.949.917 I slot print_timing: id  3 | task 3444 | prompt eval time =     271.71 ms /   230 tokens (    1.18 ms per token,   846.48 tokens per second)
14.12.949.939 I slot print_timing: id  3 | task 3444 |        eval time =    1145.27 ms /    82 tokens (   13.97 ms per token,    71.60 tokens per second)
14.12.949.939 I slot print_timing: id  3 | task 3444 |       total time =    1416.98 ms /   312 tokens
14.12.949.940 I slot print_timing: id  3 | task 3444 |    graphs reused =       2062
14.12.949.941 I slot print_timing: id  3 | task 3444 | draft acceptance = 1.00000 (   49 accepted /    49 generated)
14.12.949.953 I statistics        draft-mtp: #calls(b,g,a) =   36   3289   2504, #gen drafts =   2504, #acc drafts =  2406, #gen tokens =   4576, #acc tokens =  4382, dur(b,g,a) = 0.062, 11283.386, 5.664 ms
14.12.951.674 I slot      release: id  3 | task 3444 | stop processing: n_tokens = 72786, truncated = 0
14.12.951.738 I srv  update_slots: all slots are idle
14.13.186.620 I srv  params_from_: Chat format: peg-native
14.13.260.692 I slot get_availabl: id  3 | task -1 | selected slot by LCP similarity, sim_best = 0.998 (> 0.100 thold), f_keep = 1.000
14.13.261.493 I reasoning-budget: activated, budget=2147483647 tokens
14.13.261.584 I slot launch_slot_: id  3 | task 3481 | processing task, is_child = 0
14.13.261.672 I slot update_slots: id  3 | task 3481 | Checking checkpoint with [72473, 72473] against 72785...
14.13.318.220 W slot update_slots: id  3 | task 3481 | restored context checkpoint (pos_min = 72473, pos_max = 72473, n_tokens = 72474, n_past = 72474, size = 434.110 MiB)
14.13.961.763 I slot create_check: id  3 | task 3481 | created context checkpoint 15 of 32 (pos_min = 72786, pos_max = 72786, n_tokens = 72787, size = 435.339 MiB)
14.14.387.237 I reasoning-budget: deactivated (natural end)
14.15.360.876 I slot print_timing: id  3 | task 3481 | n_decoded =    102, tg =  82.95 t/s
14.16.394.389 I slot print_timing: id  3 | task 3481 | prompt eval time =     869.92 ms /   461 tokens (    1.89 ms per token,   529.93 tokens per second)
14.16.394.408 I slot print_timing: id  3 | task 3481 |        eval time =    2263.22 ms /   189 tokens (   11.97 ms per token,    83.51 tokens per second)
14.16.394.409 I slot print_timing: id  3 | task 3481 |       total time =    3133.14 ms /   650 tokens
14.16.394.410 I slot print_timing: id  3 | task 3481 |    graphs reused =       2120
14.16.394.410 I slot print_timing: id  3 | task 3481 | draft acceptance = 0.99187 (  122 accepted /   123 generated)
14.16.394.423 I statistics        draft-mtp: #calls(b,g,a) =   37   3357   2566, #gen drafts =   2566, #acc drafts =  2468, #gen tokens =   4699, #acc tokens =  4504, dur(b,g,a) = 0.064, 11534.998, 5.781 ms
14.16.396.392 I slot      release: id  3 | task 3481 | stop processing: n_tokens = 73125, truncated = 0
14.16.396.458 I srv  update_slots: all slots are idle
14.16.649.106 I srv  params_from_: Chat format: peg-native
14.16.724.462 I slot get_availabl: id  3 | task -1 | selected slot by LCP similarity, sim_best = 1.000 (> 0.100 thold), f_keep = 1.000
14.16.725.243 I reasoning-budget: activated, budget=2147483647 tokens
14.16.725.326 I slot launch_slot_: id  3 | task 3553 | processing task, is_child = 0
14.16.725.399 I slot update_slots: id  3 | task 3553 | Checking checkpoint with [72786, 72786] against 73124...
14.16.783.499 W slot update_slots: id  3 | task 3553 | restored context checkpoint (pos_min = 72786, pos_max = 72786, n_tokens = 72787, n_past = 72787, size = 435.339 MiB)
14.17.514.060 I slot create_check: id  3 | task 3553 | created context checkpoint 16 of 32 (pos_min = 73124, pos_max = 73124, n_tokens = 73125, size = 436.665 MiB)
14.17.973.822 I reasoning-budget: deactivated (natural end)
14.18.984.386 I slot print_timing: id  3 | task 3553 | prompt eval time =     884.22 ms /   356 tokens (    2.48 ms per token,   402.61 tokens per second)
14.18.984.407 I slot print_timing: id  3 | task 3553 |        eval time =    1374.65 ms /    92 tokens (   14.94 ms per token,    66.93 tokens per second)
14.18.984.408 I slot print_timing: id  3 | task 3553 |       total time =    2258.87 ms /   448 tokens
14.18.984.409 I slot print_timing: id  3 | task 3553 |    graphs reused =       2137
14.18.984.409 I slot print_timing: id  3 | task 3553 | draft acceptance = 0.98214 (   55 accepted /    56 generated)
14.18.984.421 I statistics        draft-mtp: #calls(b,g,a) =   38   3394   2597, #gen drafts =   2597, #acc drafts =  2498, #gen tokens =   4755, #acc tokens =  4559, dur(b,g,a) = 0.066, 11667.842, 5.855 ms
14.18.986.136 I slot      release: id  3 | task 3553 | stop processing: n_tokens = 73235, truncated = 0
14.18.986.198 I srv  update_slots: all slots are idle
14.19.224.881 I srv  params_from_: Chat format: peg-native
14.19.298.163 I slot get_availabl: id  3 | task -1 | selected slot by LCP similarity, sim_best = 0.998 (> 0.100 thold), f_keep = 1.000
14.19.298.830 I reasoning-budget: activated, budget=2147483647 tokens
14.19.298.914 I slot launch_slot_: id  3 | task 3594 | processing task, is_child = 0
14.19.298.992 I slot update_slots: id  3 | task 3594 | Checking checkpoint with [73124, 73124] against 73234...
14.19.355.885 W slot update_slots: id  3 | task 3594 | restored context checkpoint (pos_min = 73124, pos_max = 73124, n_tokens = 73125, n_past = 73125, size = 436.665 MiB)
14.19.966.991 I reasoning-budget: deactivated (natural end)
14.20.829.217 I slot print_timing: id  3 | task 3594 | n_decoded =    100, tg =  79.19 t/s
14.21.640.609 I slot print_timing: id  3 | task 3594 | prompt eval time =     267.00 ms /   227 tokens (    1.18 ms per token,   850.18 tokens per second)
14.21.640.628 I slot print_timing: id  3 | task 3594 |        eval time =    2074.10 ms /   166 tokens (   12.49 ms per token,    80.03 tokens per second)
14.21.640.629 I slot print_timing: id  3 | task 3594 |       total time =    2341.10 ms /   393 tokens
14.21.640.630 I slot print_timing: id  3 | task 3594 |    graphs reused =       2186
14.21.640.631 I slot print_timing: id  3 | task 3594 | draft acceptance = 0.99048 (  104 accepted /   105 generated)
14.21.640.644 I statistics        draft-mtp: #calls(b,g,a) =   39   3456   2651, #gen drafts =   2651, #acc drafts =  2552, #gen tokens =   4860, #acc tokens =  4663, dur(b,g,a) = 0.067, 11890.767, 5.961 ms
14.21.642.328 I slot      release: id  3 | task 3594 | stop processing: n_tokens = 73518, truncated = 0
14.21.642.393 I srv  update_slots: all slots are idle
14.21.930.045 I srv  params_from_: Chat format: peg-native
14.22.003.834 I slot get_availabl: id  3 | task -1 | selected slot by LCP similarity, sim_best = 1.000 (> 0.100 thold), f_keep = 1.000
14.22.004.537 I reasoning-budget: activated, budget=2147483647 tokens
14.22.004.622 I slot launch_slot_: id  3 | task 3660 | processing task, is_child = 0
14.22.004.696 I slot update_slots: id  3 | task 3660 | Checking checkpoint with [73124, 73124] against 73517...
14.22.062.359 W slot update_slots: id  3 | task 3660 | restored context checkpoint (pos_min = 73124, pos_max = 73124, n_tokens = 73125, n_past = 73125, size = 436.665 MiB)
14.22.766.668 I slot create_check: id  3 | task 3660 | created context checkpoint 17 of 32 (pos_min = 73518, pos_max = 73518, n_tokens = 73519, size = 438.212 MiB)
14.23.130.504 I reasoning-budget: deactivated (natural end)
14.24.152.954 I slot print_timing: id  3 | task 3660 | prompt eval time =     856.75 ms /   412 tokens (    2.08 ms per token,   480.89 tokens per second)
14.24.152.974 I slot print_timing: id  3 | task 3660 |        eval time =    1291.39 ms /    87 tokens (   14.84 ms per token,    67.37 tokens per second)
14.24.152.975 I slot print_timing: id  3 | task 3660 |       total time =    2148.14 ms /   499 tokens
14.24.152.976 I slot print_timing: id  3 | task 3660 |    graphs reused =       2206
14.24.152.977 I slot print_timing: id  3 | task 3660 | draft acceptance = 0.96226 (   51 accepted /    53 generated)
14.24.152.989 I statistics        draft-mtp: #calls(b,g,a) =   40   3491   2680, #gen drafts =   2680, #acc drafts =  2580, #gen tokens =   4913, #acc tokens =  4714, dur(b,g,a) = 0.069, 12016.550, 6.026 ms
14.24.154.734 I slot      release: id  3 | task 3660 | stop processing: n_tokens = 73623, truncated = 0
14.24.154.797 I srv  update_slots: all slots are idle
14.24.433.241 I srv  params_from_: Chat format: peg-native
14.24.511.652 I slot get_availabl: id  3 | task -1 | selected slot by LCP similarity, sim_best = 0.993 (> 0.100 thold), f_keep = 1.000
14.24.512.419 I reasoning-budget: activated, budget=2147483647 tokens
14.24.512.519 I slot launch_slot_: id  3 | task 3699 | processing task, is_child = 0
14.24.512.599 I slot update_slots: id  3 | task 3699 | Checking checkpoint with [73518, 73518] against 73622...
14.24.578.030 W slot update_slots: id  3 | task 3699 | restored context checkpoint (pos_min = 73518, pos_max = 73518, n_tokens = 73519, n_past = 73519, size = 438.212 MiB)
14.25.521.044 I slot create_check: id  3 | task 3699 | created context checkpoint 18 of 32 (pos_min = 74105, pos_max = 74105, n_tokens = 74106, size = 440.516 MiB)
14.25.860.225 I reasoning-budget: deactivated (natural end)
14.27.500.638 I slot print_timing: id  3 | task 3699 | n_decoded =    100, tg =  51.66 t/s
14.28.664.799 I slot print_timing: id  3 | task 3699 | prompt eval time =    1115.78 ms /   591 tokens (    1.89 ms per token,   529.68 tokens per second)
14.28.664.820 I slot print_timing: id  3 | task 3699 |        eval time =    3099.77 ms /   157 tokens (   19.74 ms per token,    50.65 tokens per second)
14.28.664.821 I slot print_timing: id  3 | task 3699 |       total time =    4215.54 ms /   748 tokens
14.28.664.822 I slot print_timing: id  3 | task 3699 |    graphs reused =       2248
14.28.664.823 I slot print_timing: id  3 | task 3699 | draft acceptance = 0.87640 (   78 accepted /    89 generated)
14.28.664.861 I statistics        draft-mtp: #calls(b,g,a) =   41   3570   2731, #gen drafts =   2731, #acc drafts =  2625, #gen tokens =   5002, #acc tokens =  4792, dur(b,g,a) = 0.072, 12290.794, 6.150 ms
14.28.666.964 I slot      release: id  3 | task 3699 | stop processing: n_tokens = 74267, truncated = 0
14.28.667.033 I srv  update_slots: all slots are idle
14.28.950.611 I srv  params_from_: Chat format: peg-native
14.29.032.766 I slot get_availabl: id  3 | task -1 | selected slot by LCP similarity, sim_best = 0.998 (> 0.100 thold), f_keep = 1.000
14.29.033.505 I reasoning-budget: activated, budget=2147483647 tokens
14.29.033.593 I slot launch_slot_: id  3 | task 3783 | processing task, is_child = 0
14.29.033.673 I slot update_slots: id  3 | task 3783 | Checking checkpoint with [74105, 74105] against 74266...
14.29.096.081 W slot update_slots: id  3 | task 3783 | restored context checkpoint (pos_min = 74105, pos_max = 74105, n_tokens = 74106, n_past = 74106, size = 440.516 MiB)
14.29.845.415 I slot create_check: id  3 | task 3783 | created context checkpoint 19 of 32 (pos_min = 74383, pos_max = 74383, n_tokens = 74384, size = 441.607 MiB)
14.30.352.248 I reasoning-budget: deactivated (natural end)
14.31.558.710 I slot print_timing: id  3 | task 3783 | n_decoded =    100, tg =  47.95 t/s
14.32.803.350 I slot print_timing: id  3 | task 3783 | prompt eval time =     856.55 ms /   282 tokens (    3.04 ms per token,   329.23 tokens per second)
14.32.803.371 I slot print_timing: id  3 | task 3783 |        eval time =    3330.14 ms /   161 tokens (   20.68 ms per token,    48.35 tokens per second)
14.32.803.371 I slot print_timing: id  3 | task 3783 |       total time =    4186.69 ms /   443 tokens
14.32.803.372 I slot print_timing: id  3 | task 3783 |    graphs reused =       2279
14.32.803.373 I slot print_timing: id  3 | task 3783 | draft acceptance = 0.87234 (   82 accepted /    94 generated)
14.32.803.385 I statistics        draft-mtp: #calls(b,g,a) =   42   3650   2786, #gen drafts =   2786, #acc drafts =  2674, #gen tokens =   5096, #acc tokens =  4874, dur(b,g,a) = 0.074, 12590.532, 6.303 ms
14.32.805.321 I slot      release: id  3 | task 3783 | stop processing: n_tokens = 74550, truncated = 0
14.32.805.394 I srv  update_slots: all slots are idle
```