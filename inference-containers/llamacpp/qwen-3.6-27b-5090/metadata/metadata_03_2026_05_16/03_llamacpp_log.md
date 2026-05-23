# docker-compose
```yml
services:
  qwen-27b-mtp-server:
    # CUDA 12.8+ base ensures Blackwell SM120 support is native.
    image: havenoammo/llama:cuda13-server
    container_name: qwen-3.6-27b-mtp-5090
    hostname: llama-server
    platform: linux/amd64
    # Port 8081 prevents collisions with your vLLM (8000) or other llama-servers (8080).
    ports:
      - "8081:8080"

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
      - "8080"
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
      - "mtp"
      # 2 draft tokens is the verified 'sweet spot' for Qwen 3.6 acceptance rates.
      - "--spec-draft-n-max"
      - "2"
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


# llammacpp log

```log
2026-05-16 22:21:26.334 | ggml_cuda_init: found 1 CUDA devices (Total VRAM: 32606 MiB):
2026-05-16 22:21:26.334 |   Device 0: NVIDIA GeForce RTX 5090, compute capability 12.0, VMM: yes, VRAM: 32606 MiB
2026-05-16 22:21:26.334 | load_backend: loaded CUDA backend from /app/libggml-cuda.so
2026-05-16 22:21:26.364 | load_backend: loaded CPU backend from /app/libggml-cpu-haswell.so
2026-05-16 22:21:26.364 | warn: LLAMA_ARG_HOST environment variable is set, but will be overwritten by command line argument --host
2026-05-16 22:21:26.535 | common_download_file_single_online: HEAD failed, status: 404
2026-05-16 22:21:26.536 | no remote preset found, skipping
2026-05-16 22:21:26.894 | main: n_parallel is set to auto, using n_parallel = 4 and kv_unified = true
2026-05-16 22:21:26.894 | build_info: b484-2c4055912
2026-05-16 22:21:26.894 | system_info: n_threads = 16 (n_threads_batch = 16) / 32 | CUDA : ARCHS = 750,800,860,890,1200,1210 | USE_GRAPHS = 1 | PEER_MAX_BATCH_SIZE = 128 | BLACKWELL_NATIVE_FP4 = 1 | CPU : SSE3 = 1 | SSSE3 = 1 | AVX = 1 | AVX2 = 1 | F16C = 1 | FMA = 1 | BMI2 = 1 | LLAMAFILE = 1 | OPENMP = 1 | REPACK = 1 | 
2026-05-16 22:21:26.894 | Running without SSL
2026-05-16 22:21:26.894 | init: using 31 threads for HTTP server
2026-05-16 22:21:26.894 | start: binding port with default address family
2026-05-16 22:21:26.896 | main: loading model
2026-05-16 22:21:26.897 | srv    load_model: loading model '/root/.cache/huggingface/hub/models--unsloth--Qwen3.6-27B-MTP-GGUF/snapshots/ac393bc3d23fd5a929a85e2f33c7c4fd5be02d43/Qwen3.6-27B-UD-Q4_K_XL.gguf'
2026-05-16 22:21:26.897 | common_init_result: fitting params to device memory, for bugs during this step try to reproduce them with -fit off, or provide --verbose logs if the bug only occurs with -fit on
2026-05-16 22:21:26.897 | common_params_fit_impl: getting device memory data for initial parameters:
2026-05-16 22:21:27.630 | common_memory_breakdown_print: | memory breakdown [MiB] | total    free     self   model   context   compute    unaccounted |
2026-05-16 22:21:27.630 | common_memory_breakdown_print: |   - CUDA0 (RTX 5090)   | 32606 = 30330 + (21832 = 16386 +    4950 +     495) +      -19555 |
2026-05-16 22:21:27.630 | common_memory_breakdown_print: |   - Host               |                    958 =   682 +       0 +     276                |
2026-05-16 22:21:27.673 | common_params_fit_impl: projected to use 21832 MiB of device memory vs. 30330 MiB of free device memory
2026-05-16 22:21:27.673 | common_params_fit_impl: will leave 8497 >= 1024 MiB of free device memory, no changes needed
2026-05-16 22:21:27.673 | common_fit_params: successfully fit params to free device memory
2026-05-16 22:21:27.673 | common_fit_params: fitting params to free memory took 0.78 seconds
2026-05-16 22:21:27.704 | llama_model_loader: loaded meta data with 52 key-value pairs and 866 tensors from /root/.cache/huggingface/hub/models--unsloth--Qwen3.6-27B-MTP-GGUF/snapshots/ac393bc3d23fd5a929a85e2f33c7c4fd5be02d43/Qwen3.6-27B-UD-Q4_K_XL.gguf (version GGUF V3 (latest))
2026-05-16 22:21:27.704 | llama_model_loader: Dumping metadata keys/values. Note: KV overrides do not apply in this output.
2026-05-16 22:21:27.704 | llama_model_loader: - kv   0:                       general.architecture str              = qwen35
2026-05-16 22:21:27.704 | llama_model_loader: - kv   1:                               general.type str              = model
2026-05-16 22:21:27.704 | llama_model_loader: - kv   2:                     general.sampling.top_k i32              = 20
2026-05-16 22:21:27.704 | llama_model_loader: - kv   3:                     general.sampling.top_p f32              = 0.950000
2026-05-16 22:21:27.704 | llama_model_loader: - kv   4:                      general.sampling.temp f32              = 1.000000
2026-05-16 22:21:27.704 | llama_model_loader: - kv   5:                               general.name str              = Qwen3.6-27B
2026-05-16 22:21:27.704 | llama_model_loader: - kv   6:                           general.basename str              = Qwen3.6-27B
2026-05-16 22:21:27.704 | llama_model_loader: - kv   7:                       general.quantized_by str              = Unsloth
2026-05-16 22:21:27.704 | llama_model_loader: - kv   8:                         general.size_label str              = 27B
2026-05-16 22:21:27.704 | llama_model_loader: - kv   9:                            general.license str              = apache-2.0
2026-05-16 22:21:27.704 | llama_model_loader: - kv  10:                       general.license.link str              = https://huggingface.co/Qwen/Qwen3.6-2...
2026-05-16 22:21:27.704 | llama_model_loader: - kv  11:                           general.repo_url str              = https://huggingface.co/unsloth
2026-05-16 22:21:27.704 | llama_model_loader: - kv  12:                   general.base_model.count u32              = 1
2026-05-16 22:21:27.704 | llama_model_loader: - kv  13:                  general.base_model.0.name str              = Qwen3.6 27B
2026-05-16 22:21:27.704 | llama_model_loader: - kv  14:          general.base_model.0.organization str              = Qwen
2026-05-16 22:21:27.704 | llama_model_loader: - kv  15:              general.base_model.0.repo_url str              = https://huggingface.co/Qwen/Qwen3.6-27B
2026-05-16 22:21:27.704 | llama_model_loader: - kv  16:                               general.tags arr[str,2]       = ["unsloth", "image-text-to-text"]
2026-05-16 22:21:27.704 | llama_model_loader: - kv  17:                         qwen35.block_count u32              = 65
2026-05-16 22:21:27.704 | llama_model_loader: - kv  18:                      qwen35.context_length u32              = 262144
2026-05-16 22:21:27.704 | llama_model_loader: - kv  19:                    qwen35.embedding_length u32              = 5120
2026-05-16 22:21:27.704 | llama_model_loader: - kv  20:                 qwen35.feed_forward_length u32              = 17408
2026-05-16 22:21:27.704 | llama_model_loader: - kv  21:                qwen35.attention.head_count u32              = 24
2026-05-16 22:21:27.704 | llama_model_loader: - kv  22:             qwen35.attention.head_count_kv u32              = 4
2026-05-16 22:21:27.704 | llama_model_loader: - kv  23:             qwen35.rope.dimension_sections arr[i32,4]       = [11, 11, 10, 0]
2026-05-16 22:21:27.704 | llama_model_loader: - kv  24:                      qwen35.rope.freq_base f32              = 10000000.000000
2026-05-16 22:21:27.704 | llama_model_loader: - kv  25:    qwen35.attention.layer_norm_rms_epsilon f32              = 0.000001
2026-05-16 22:21:27.704 | llama_model_loader: - kv  26:                qwen35.attention.key_length u32              = 256
2026-05-16 22:21:27.704 | llama_model_loader: - kv  27:              qwen35.attention.value_length u32              = 256
2026-05-16 22:21:27.704 | llama_model_loader: - kv  28:                     qwen35.ssm.conv_kernel u32              = 4
2026-05-16 22:21:27.704 | llama_model_loader: - kv  29:                      qwen35.ssm.state_size u32              = 128
2026-05-16 22:21:27.704 | llama_model_loader: - kv  30:                     qwen35.ssm.group_count u32              = 16
2026-05-16 22:21:27.704 | llama_model_loader: - kv  31:                  qwen35.ssm.time_step_rank u32              = 48
2026-05-16 22:21:27.704 | llama_model_loader: - kv  32:                      qwen35.ssm.inner_size u32              = 6144
2026-05-16 22:21:27.704 | llama_model_loader: - kv  33:             qwen35.full_attention_interval u32              = 4
2026-05-16 22:21:27.704 | llama_model_loader: - kv  34:                qwen35.rope.dimension_count u32              = 64
2026-05-16 22:21:27.704 | llama_model_loader: - kv  35:                qwen35.nextn_predict_layers u32              = 1
2026-05-16 22:21:27.704 | llama_model_loader: - kv  36:                       tokenizer.ggml.model str              = gpt2
2026-05-16 22:21:27.704 | llama_model_loader: - kv  37:                         tokenizer.ggml.pre str              = qwen35
2026-05-16 22:21:27.722 | llama_model_loader: - kv  38:                      tokenizer.ggml.tokens arr[str,248320]  = ["!", "\"", "#", "$", "%", "&", "'", ...
2026-05-16 22:21:27.728 | llama_model_loader: - kv  39:                  tokenizer.ggml.token_type arr[i32,248320]  = [1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, ...
2026-05-16 22:21:27.745 | llama_model_loader: - kv  40:                      tokenizer.ggml.merges arr[str,247587]  = ["Ġ Ġ", "ĠĠ ĠĠ", "i n", "Ġ t",...
2026-05-16 22:21:27.745 | llama_model_loader: - kv  41:                tokenizer.ggml.eos_token_id u32              = 248046
2026-05-16 22:21:27.745 | llama_model_loader: - kv  42:            tokenizer.ggml.padding_token_id u32              = 248055
2026-05-16 22:21:27.745 | llama_model_loader: - kv  43:                tokenizer.ggml.bos_token_id u32              = 248044
2026-05-16 22:21:27.746 | llama_model_loader: - kv  44:               tokenizer.ggml.add_bos_token bool             = false
2026-05-16 22:21:27.746 | llama_model_loader: - kv  45:                    tokenizer.chat_template str              = {%- set image_count = namespace(value...
2026-05-16 22:21:27.746 | llama_model_loader: - kv  46:               general.quantization_version u32              = 2
2026-05-16 22:21:27.746 | llama_model_loader: - kv  47:                          general.file_type u32              = 15
2026-05-16 22:21:27.746 | llama_model_loader: - kv  48:                      quantize.imatrix.file str              = Qwen3.6-27B-GGUF/imatrix_unsloth.gguf
2026-05-16 22:21:27.746 | llama_model_loader: - kv  49:                   quantize.imatrix.dataset str              = unsloth_calibration_Qwen3.6-27B.txt
2026-05-16 22:21:27.746 | llama_model_loader: - kv  50:             quantize.imatrix.entries_count u32              = 496
2026-05-16 22:21:27.746 | llama_model_loader: - kv  51:              quantize.imatrix.chunks_count u32              = 76
2026-05-16 22:21:27.746 | llama_model_loader: - type  f32:  456 tensors
2026-05-16 22:21:27.746 | llama_model_loader: - type q8_0:   49 tensors
2026-05-16 22:21:27.746 | llama_model_loader: - type q4_K:  225 tensors
2026-05-16 22:21:27.746 | llama_model_loader: - type q5_K:   70 tensors
2026-05-16 22:21:27.746 | llama_model_loader: - type q6_K:   66 tensors
2026-05-16 22:21:27.746 | print_info: file format = GGUF V3 (latest)
2026-05-16 22:21:27.746 | print_info: file type   = Q4_K - Medium
2026-05-16 22:21:27.746 | print_info: file size   = 16.67 GiB (5.24 BPW) 
2026-05-16 22:21:27.746 | llama_prepare_model_devices: using device CUDA0 (NVIDIA GeForce RTX 5090) (0000:0b:00.0) - 30930 MiB free
2026-05-16 22:21:27.833 | load: 0 unused tokens
2026-05-16 22:21:27.859 | load: printing all EOG tokens:
2026-05-16 22:21:27.859 | load:   - 248044 ('<|endoftext|>')
2026-05-16 22:21:27.859 | load:   - 248046 ('<|im_end|>')
2026-05-16 22:21:27.859 | load:   - 248063 ('<|fim_pad|>')
2026-05-16 22:21:27.859 | load:   - 248064 ('<|repo_name|>')
2026-05-16 22:21:27.859 | load:   - 248065 ('<|file_sep|>')
2026-05-16 22:21:27.859 | load: special tokens cache size = 33
2026-05-16 22:21:27.924 | load: token to piece cache size = 1.7581 MB
2026-05-16 22:21:27.924 | print_info: arch                  = qwen35
2026-05-16 22:21:27.924 | print_info: vocab_only            = 0
2026-05-16 22:21:27.924 | print_info: no_alloc              = 0
2026-05-16 22:21:27.924 | print_info: n_ctx_train           = 262144
2026-05-16 22:21:27.924 | print_info: n_embd                = 5120
2026-05-16 22:21:27.924 | print_info: n_embd_inp            = 5120
2026-05-16 22:21:27.924 | print_info: n_layer               = 65
2026-05-16 22:21:27.924 | print_info: n_head                = 24
2026-05-16 22:21:27.924 | print_info: n_head_kv             = 4
2026-05-16 22:21:27.924 | print_info: n_rot                 = 64
2026-05-16 22:21:27.924 | print_info: n_swa                 = 0
2026-05-16 22:21:27.924 | print_info: is_swa_any            = 0
2026-05-16 22:21:27.924 | print_info: n_embd_head_k         = 256
2026-05-16 22:21:27.924 | print_info: n_embd_head_v         = 256
2026-05-16 22:21:27.924 | print_info: n_gqa                 = 6
2026-05-16 22:21:27.924 | print_info: n_embd_k_gqa          = 1024
2026-05-16 22:21:27.924 | print_info: n_embd_v_gqa          = 1024
2026-05-16 22:21:27.924 | print_info: f_norm_eps            = 0.0e+00
2026-05-16 22:21:27.924 | print_info: f_norm_rms_eps        = 1.0e-06
2026-05-16 22:21:27.924 | print_info: f_clamp_kqv           = 0.0e+00
2026-05-16 22:21:27.924 | print_info: f_max_alibi_bias      = 0.0e+00
2026-05-16 22:21:27.924 | print_info: f_logit_scale         = 0.0e+00
2026-05-16 22:21:27.924 | print_info: f_attn_scale          = 0.0e+00
2026-05-16 22:21:27.924 | print_info: f_attn_value_scale    = 0.0000
2026-05-16 22:21:27.924 | print_info: n_ff                  = 17408
2026-05-16 22:21:27.924 | print_info: n_expert              = 0
2026-05-16 22:21:27.924 | print_info: n_expert_used         = 0
2026-05-16 22:21:27.924 | print_info: n_expert_groups       = 0
2026-05-16 22:21:27.924 | print_info: n_group_used          = 0
2026-05-16 22:21:27.924 | print_info: causal attn           = 1
2026-05-16 22:21:27.924 | print_info: pooling type          = -1
2026-05-16 22:21:27.924 | print_info: rope type             = 40
2026-05-16 22:21:27.924 | print_info: rope scaling          = linear
2026-05-16 22:21:27.924 | print_info: freq_base_train       = 10000000.0
2026-05-16 22:21:27.924 | print_info: freq_scale_train      = 1
2026-05-16 22:21:27.924 | print_info: n_ctx_orig_yarn       = 262144
2026-05-16 22:21:27.924 | print_info: rope_yarn_log_mul     = 0.0000
2026-05-16 22:21:27.924 | print_info: rope_finetuned        = unknown
2026-05-16 22:21:27.924 | print_info: mrope sections        = [11, 11, 10, 0]
2026-05-16 22:21:27.924 | print_info: ssm_d_conv            = 4
2026-05-16 22:21:27.924 | print_info: ssm_d_inner           = 6144
2026-05-16 22:21:27.924 | print_info: ssm_d_state           = 128
2026-05-16 22:21:27.924 | print_info: ssm_dt_rank           = 48
2026-05-16 22:21:27.924 | print_info: ssm_n_group           = 16
2026-05-16 22:21:27.924 | print_info: ssm_dt_b_c_rms        = 0
2026-05-16 22:21:27.924 | print_info: model type            = 27B
2026-05-16 22:21:27.924 | print_info: model params          = 27.32 B
2026-05-16 22:21:27.924 | print_info: general.name          = Qwen3.6-27B
2026-05-16 22:21:27.924 | print_info: vocab type            = BPE
2026-05-16 22:21:27.924 | print_info: n_vocab               = 248320
2026-05-16 22:21:27.924 | print_info: n_merges              = 247587
2026-05-16 22:21:27.924 | print_info: BOS token             = 248044 '<|endoftext|>'
2026-05-16 22:21:27.924 | print_info: EOS token             = 248046 '<|im_end|>'
2026-05-16 22:21:27.924 | print_info: EOT token             = 248046 '<|im_end|>'
2026-05-16 22:21:27.924 | print_info: PAD token             = 248055 '<|vision_pad|>'
2026-05-16 22:21:27.924 | print_info: LF token              = 198 'Ċ'
2026-05-16 22:21:27.924 | print_info: FIM PRE token         = 248060 '<|fim_prefix|>'
2026-05-16 22:21:27.924 | print_info: FIM SUF token         = 248062 '<|fim_suffix|>'
2026-05-16 22:21:27.924 | print_info: FIM MID token         = 248061 '<|fim_middle|>'
2026-05-16 22:21:27.924 | print_info: FIM PAD token         = 248063 '<|fim_pad|>'
2026-05-16 22:21:27.924 | print_info: FIM REP token         = 248064 '<|repo_name|>'
2026-05-16 22:21:27.924 | print_info: FIM SEP token         = 248065 '<|file_sep|>'
2026-05-16 22:21:27.924 | print_info: EOG token             = 248044 '<|endoftext|>'
2026-05-16 22:21:27.924 | print_info: EOG token             = 248046 '<|im_end|>'
2026-05-16 22:21:27.924 | print_info: EOG token             = 248063 '<|fim_pad|>'
2026-05-16 22:21:27.924 | print_info: EOG token             = 248064 '<|repo_name|>'
2026-05-16 22:21:27.924 | print_info: EOG token             = 248065 '<|file_sep|>'
2026-05-16 22:21:27.924 | print_info: max token length      = 256
2026-05-16 22:21:27.924 | load_tensors: loading model tensors, this can take a while... (mmap = true, direct_io = false)
2026-05-16 22:21:42.654 | load_tensors: offloading output layer to GPU
2026-05-16 22:21:42.654 | load_tensors: offloading 64 repeating layers to GPU
2026-05-16 22:21:42.654 | load_tensors: offloaded 66/66 layers to GPU
2026-05-16 22:21:42.654 | load_tensors:   CPU_Mapped model buffer size =   682.03 MiB
2026-05-16 22:21:42.654 | load_tensors:        CUDA0 model buffer size = 16386.94 MiB
2026-05-16 22:21:45.557 | .............................................................................................
2026-05-16 22:21:45.561 | common_init_result: added <|endoftext|> logit bias = -inf
2026-05-16 22:21:45.561 | common_init_result: added <|im_end|> logit bias = -inf
2026-05-16 22:21:45.561 | common_init_result: added <|fim_pad|> logit bias = -inf
2026-05-16 22:21:45.561 | common_init_result: added <|repo_name|> logit bias = -inf
2026-05-16 22:21:45.561 | common_init_result: added <|file_sep|> logit bias = -inf
2026-05-16 22:21:45.561 | llama_context: constructing llama_context
2026-05-16 22:21:45.561 | llama_context: n_seq_max     = 4
2026-05-16 22:21:45.561 | llama_context: n_ctx         = 131072
2026-05-16 22:21:45.561 | llama_context: n_ctx_seq     = 131072
2026-05-16 22:21:45.561 | llama_context: n_batch       = 2048
2026-05-16 22:21:45.561 | llama_context: n_ubatch      = 512
2026-05-16 22:21:45.561 | llama_context: causal_attn   = 1
2026-05-16 22:21:45.561 | llama_context: flash_attn    = enabled
2026-05-16 22:21:45.561 | llama_context: kv_unified    = true
2026-05-16 22:21:45.561 | llama_context: freq_base     = 10000000.0
2026-05-16 22:21:45.561 | llama_context: freq_scale    = 1
2026-05-16 22:21:45.561 | llama_context: n_ctx_seq (131072) < n_ctx_train (262144) -- the full capacity of the model will not be utilized
2026-05-16 22:21:45.566 | llama_context:  CUDA_Host  output buffer size =     3.79 MiB
2026-05-16 22:21:45.593 | llama_kv_cache:      CUDA0 KV buffer size =  4352.00 MiB
2026-05-16 22:21:45.621 | llama_kv_cache: size = 4352.00 MiB (131072 cells,  16 layers,  4/1 seqs), K (q8_0): 2176.00 MiB, V (q8_0): 2176.00 MiB
2026-05-16 22:21:45.621 | llama_kv_cache: attn_rot_k = 1, n_embd_head_k_all = 256
2026-05-16 22:21:45.621 | llama_kv_cache: attn_rot_v = 1, n_embd_head_k_all = 256
2026-05-16 22:21:45.629 | llama_memory_recurrent:      CUDA0 RS buffer size =   598.50 MiB
2026-05-16 22:21:45.629 | llama_memory_recurrent: size =  598.50 MiB (     4 cells,  65 layers,  4 seqs), R (f32):   22.50 MiB, S (f32):  576.00 MiB
2026-05-16 22:21:45.629 | sched_reserve: reserving ...
2026-05-16 22:21:45.651 | sched_reserve: resolving fused Gated Delta Net support:
2026-05-16 22:21:45.652 | sched_reserve: fused Gated Delta Net (autoregressive) enabled
2026-05-16 22:21:45.653 | sched_reserve: fused Gated Delta Net (chunked) enabled
2026-05-16 22:21:45.933 | sched_reserve:      CUDA0 compute buffer size =   495.00 MiB
2026-05-16 22:21:45.933 | sched_reserve:  CUDA_Host compute buffer size =   276.29 MiB
2026-05-16 22:21:45.933 | sched_reserve: graph nodes  = 3849
2026-05-16 22:21:45.933 | sched_reserve: graph splits = 2
2026-05-16 22:21:45.933 | sched_reserve: reserve took 303.60 ms, sched copies = 1
2026-05-16 22:21:45.933 | common_init_from_params: warming up the model with an empty run - please wait ... (--no-warmup to disable)
2026-05-16 22:21:46.227 | srv    load_model: creating MTP draft context against the target model '/root/.cache/huggingface/hub/models--unsloth--Qwen3.6-27B-MTP-GGUF/snapshots/ac393bc3d23fd5a929a85e2f33c7c4fd5be02d43/Qwen3.6-27B-UD-Q4_K_XL.gguf'
2026-05-16 22:21:46.227 | llama_context: constructing llama_context
2026-05-16 22:21:46.227 | llama_context: n_seq_max     = 4
2026-05-16 22:21:46.227 | llama_context: n_ctx         = 131072
2026-05-16 22:21:46.227 | llama_context: n_ctx_seq     = 131072
2026-05-16 22:21:46.227 | llama_context: n_batch       = 2048
2026-05-16 22:21:46.227 | llama_context: n_ubatch      = 512
2026-05-16 22:21:46.227 | llama_context: causal_attn   = 1
2026-05-16 22:21:46.227 | llama_context: flash_attn    = enabled
2026-05-16 22:21:46.227 | llama_context: kv_unified    = true
2026-05-16 22:21:46.227 | llama_context: freq_base     = 10000000.0
2026-05-16 22:21:46.227 | llama_context: freq_scale    = 1
2026-05-16 22:21:46.227 | llama_context: n_ctx_seq (131072) < n_ctx_train (262144) -- the full capacity of the model will not be utilized
2026-05-16 22:21:46.232 | llama_context:  CUDA_Host  output buffer size =     3.79 MiB
2026-05-16 22:21:46.240 | llama_kv_cache:      CUDA0 KV buffer size =   272.00 MiB
2026-05-16 22:21:46.242 | llama_kv_cache: size =  272.00 MiB (131072 cells,   1 layers,  4/1 seqs), K (q8_0):  136.00 MiB, V (q8_0):  136.00 MiB
2026-05-16 22:21:46.242 | llama_kv_cache: attn_rot_k = 1, n_embd_head_k_all = 256
2026-05-16 22:21:46.242 | llama_kv_cache: attn_rot_v = 1, n_embd_head_k_all = 256
2026-05-16 22:21:46.242 | sched_reserve: reserving ...
2026-05-16 22:21:46.266 | sched_reserve: resolving fused Gated Delta Net support:
2026-05-16 22:21:46.266 | sched_reserve: fused Gated Delta Net (autoregressive) enabled
2026-05-16 22:21:46.266 | sched_reserve: fused Gated Delta Net (chunked) enabled
2026-05-16 22:21:46.553 | sched_reserve:      CUDA0 compute buffer size =   495.00 MiB
2026-05-16 22:21:46.553 | sched_reserve:  CUDA_Host compute buffer size =   276.28 MiB
2026-05-16 22:21:46.553 | sched_reserve: graph nodes  = 62
2026-05-16 22:21:46.553 | sched_reserve: graph splits = 2
2026-05-16 22:21:46.553 | sched_reserve: reserve took 310.25 ms, sched copies = 1
2026-05-16 22:21:46.567 | clip_model_loader: model name:   Qwen3.6-27B
2026-05-16 22:21:46.567 | clip_model_loader: description:  
2026-05-16 22:21:46.567 | clip_model_loader: GGUF version: 3
2026-05-16 22:21:46.567 | clip_model_loader: alignment:    32
2026-05-16 22:21:46.567 | clip_model_loader: n_tensors:    334
2026-05-16 22:21:46.567 | clip_model_loader: n_kv:         33
2026-05-16 22:21:46.567 | 
2026-05-16 22:21:46.567 | clip_model_loader: has vision encoder
2026-05-16 22:21:46.567 | clip_ctx: CLIP using CUDA0 backend
2026-05-16 22:21:46.568 | load_hparams: Qwen-VL models require at minimum 1024 image tokens to function correctly on grounding tasks
2026-05-16 22:21:46.568 | load_hparams: if you encounter problems with accuracy, try adding --image-min-tokens 1024
2026-05-16 22:21:46.568 | load_hparams: more info: https://github.com/ggml-org/llama.cpp/issues/16842
2026-05-16 22:21:46.568 | 
2026-05-16 22:21:46.568 | load_hparams: projector:          qwen3vl_merger
2026-05-16 22:21:46.568 | load_hparams: n_embd:             1152
2026-05-16 22:21:46.568 | load_hparams: n_head:             16
2026-05-16 22:21:46.568 | load_hparams: n_ff:               4304
2026-05-16 22:21:46.568 | load_hparams: n_layer:            27
2026-05-16 22:21:46.568 | load_hparams: ffn_op:             gelu
2026-05-16 22:21:46.568 | load_hparams: projection_dim:     5120
2026-05-16 22:21:46.568 | 
2026-05-16 22:21:46.568 | --- vision hparams ---
2026-05-16 22:21:46.568 | load_hparams: image_size:         768
2026-05-16 22:21:46.568 | load_hparams: patch_size:         16
2026-05-16 22:21:46.568 | load_hparams: has_llava_proj:     0
2026-05-16 22:21:46.568 | load_hparams: minicpmv_version:   0
2026-05-16 22:21:46.568 | load_hparams: n_merge:            2
2026-05-16 22:21:46.568 | load_hparams: n_wa_pattern: 0
2026-05-16 22:21:46.568 | load_hparams: image_min_pixels:   8192
2026-05-16 22:21:46.568 | load_hparams: image_max_pixels:   4194304
2026-05-16 22:21:46.568 | 
2026-05-16 22:21:46.568 | load_hparams: model size:         887.99 MiB
2026-05-16 22:21:46.568 | load_hparams: metadata size:      0.12 MiB
2026-05-16 22:21:47.450 | warmup: warmup with image size = 1472 x 1472
2026-05-16 22:21:47.452 | alloc_compute_meta:      CUDA0 compute buffer size =   248.10 MiB
2026-05-16 22:21:47.452 | alloc_compute_meta:        CPU compute buffer size =    24.93 MiB
2026-05-16 22:21:47.452 | alloc_compute_meta: graph splits = 1, nodes = 823
2026-05-16 22:21:47.452 | warmup: flash attention is enabled
2026-05-16 22:21:47.452 | srv    load_model: loaded multimodal model, '/root/.cache/huggingface/hub/models--unsloth--Qwen3.6-27B-MTP-GGUF/snapshots/ac393bc3d23fd5a929a85e2f33c7c4fd5be02d43/mmproj-BF16.gguf'
2026-05-16 22:21:47.452 | srv    load_model: initializing slots, n_slots = 4
2026-05-16 22:21:47.489 | common_context_can_seq_rm: the context does not support partial sequence removal
2026-05-16 22:21:47.519 | srv    load_model: speculative decoding will use checkpoints
2026-05-16 22:21:47.519 | common_speculative_init: adding speculative implementation 'mtp'
2026-05-16 22:21:47.520 | srv    load_model: speculative decoding context initialized
2026-05-16 22:21:47.520 | slot   load_model: id  0 | task -1 | new slot, n_ctx = 131072
2026-05-16 22:21:47.520 | slot   load_model: id  1 | task -1 | new slot, n_ctx = 131072
2026-05-16 22:21:47.520 | slot   load_model: id  2 | task -1 | new slot, n_ctx = 131072
2026-05-16 22:21:47.520 | slot   load_model: id  3 | task -1 | new slot, n_ctx = 131072
2026-05-16 22:21:47.520 | srv    load_model: prompt cache is enabled, size limit: 8192 MiB
2026-05-16 22:21:47.520 | srv    load_model: use `--cache-ram 0` to disable the prompt cache
2026-05-16 22:21:47.520 | srv    load_model: for more info see https://github.com/ggml-org/llama.cpp/pull/16391
2026-05-16 22:21:47.520 | srv          init: init: idle slots will be saved to prompt cache and cleared upon starting a new task
2026-05-16 22:21:47.532 | init: chat template, example_format: '<|im_start|>system
2026-05-16 22:21:47.532 | You are a helpful assistant<|im_end|>
2026-05-16 22:21:47.532 | <|im_start|>user
2026-05-16 22:21:47.532 | Hello<|im_end|>
2026-05-16 22:21:47.532 | <|im_start|>assistant
2026-05-16 22:21:47.532 | Hi there<|im_end|>
2026-05-16 22:21:47.532 | <|im_start|>user
2026-05-16 22:21:47.532 | How are you?<|im_end|>
2026-05-16 22:21:47.532 | <|im_start|>assistant
2026-05-16 22:21:47.532 | <think>
2026-05-16 22:21:47.532 | '
2026-05-16 22:21:47.542 | srv          init: init: chat template, thinking = 1
2026-05-16 22:21:47.542 | main: model loaded
2026-05-16 22:21:47.542 | main: server is listening on http://0.0.0.0:8000
2026-05-16 22:21:47.542 | main: starting the main loop...
2026-05-16 22:21:47.542 | srv  update_slots: all slots are idle
2026-05-16 22:30:36.388 | srv  params_from_: Chat format: peg-native
2026-05-16 22:30:36.390 | slot get_availabl: id  3 | task -1 | selected slot by LRU, t_last = -1
2026-05-16 22:30:36.390 | srv  get_availabl: updating prompt cache
2026-05-16 22:30:36.390 | srv          load:  - looking for better prompt, base f_keep = -1.000, sim = 0.000
2026-05-16 22:30:36.390 | srv        update:  - cache state: 0 prompts, 0.000 MiB (limits: 8192.000 MiB, 131072 tokens, 8589934592 est)
2026-05-16 22:30:36.390 | srv  get_availabl: prompt cache update took 0.01 ms
2026-05-16 22:30:36.391 | slot launch_slot_: id  3 | task -1 | sampler chain: logits -> penalties -> ?dry -> ?top-n-sigma -> top-k -> ?typical -> ?top-p -> min-p -> ?xtc -> ?temp-ext -> dist 
2026-05-16 22:30:36.391 | slot launch_slot_: id  3 | task 0 | processing task, is_child = 0
2026-05-16 22:30:36.391 | slot update_slots: id  3 | task 0 | new prompt, n_ctx_slot = 131072, n_keep = 0, task.n_tokens = 862
2026-05-16 22:30:36.391 | slot update_slots: id  3 | task 0 | n_tokens = 0, memory_seq_rm [0, end)
2026-05-16 22:30:36.391 | slot update_slots: id  3 | task 0 | prompt processing progress, n_tokens = 346, batch.n_tokens = 346, progress = 0.401392
2026-05-16 22:30:36.548 | srv  params_from_: Chat format: peg-native
2026-05-16 22:30:37.144 | slot get_availabl: id  2 | task -1 | selected slot by LRU, t_last = -1
2026-05-16 22:30:37.144 | srv  get_availabl: updating prompt cache
2026-05-16 22:30:37.144 | srv          load:  - looking for better prompt, base f_keep = -1.000, sim = 0.000
2026-05-16 22:30:37.144 | srv        update:  - cache state: 0 prompts, 0.000 MiB (limits: 8192.000 MiB, 131072 tokens, 8589934592 est)
2026-05-16 22:30:37.144 | srv  get_availabl: prompt cache update took 0.01 ms
2026-05-16 22:30:37.149 | reasoning-budget: activated, budget=2147483647 tokens
2026-05-16 22:30:37.149 | slot launch_slot_: id  2 | task -1 | sampler chain: logits -> penalties -> ?dry -> ?top-n-sigma -> top-k -> ?typical -> ?top-p -> min-p -> ?xtc -> ?temp-ext -> dist 
2026-05-16 22:30:37.149 | slot launch_slot_: id  2 | task 2 | processing task, is_child = 0
2026-05-16 22:30:37.149 | slot update_slots: id  2 | task 2 | new prompt, n_ctx_slot = 131072, n_keep = 0, task.n_tokens = 8733
2026-05-16 22:30:37.149 | slot update_slots: id  2 | task 2 | n_tokens = 0, memory_seq_rm [0, end)
2026-05-16 22:30:37.149 | slot update_slots: id  2 | task 2 | prompt processing progress, n_tokens = 2048, batch.n_tokens = 2048, progress = 0.234513
2026-05-16 22:30:40.063 | slot update_slots: id  2 | task 2 | n_tokens = 2048, memory_seq_rm [2048, end)
2026-05-16 22:30:40.063 | slot update_slots: id  2 | task 2 | prompt processing progress, n_tokens = 4096, batch.n_tokens = 2048, progress = 0.469026
2026-05-16 22:30:40.804 | slot update_slots: id  2 | task 2 | n_tokens = 4096, memory_seq_rm [4096, end)
2026-05-16 22:30:40.804 | slot update_slots: id  2 | task 2 | prompt processing progress, n_tokens = 6144, batch.n_tokens = 2048, progress = 0.703538
2026-05-16 22:30:41.544 | slot update_slots: id  2 | task 2 | n_tokens = 6144, memory_seq_rm [6144, end)
2026-05-16 22:30:41.546 | slot update_slots: id  2 | task 2 | prompt processing progress, n_tokens = 8192, batch.n_tokens = 2048, progress = 0.938051
2026-05-16 22:30:42.294 | slot update_slots: id  2 | task 2 | n_tokens = 8192, memory_seq_rm [8192, end)
2026-05-16 22:30:42.294 | slot update_slots: id  2 | task 2 | 8192 tokens since last checkpoint at 0, creating new checkpoint during processing at position 8217
2026-05-16 22:30:42.294 | slot update_slots: id  2 | task 2 | prompt processing progress, n_tokens = 8217, batch.n_tokens = 25, progress = 0.940914
2026-05-16 22:30:42.465 | slot create_check: id  2 | task 2 | created context checkpoint 1 of 32 (pos_min = 8191, pos_max = 8191, n_tokens = 8192, size = 166.782 MiB)
2026-05-16 22:30:42.465 | slot update_slots: id  3 | task 0 | n_tokens = 346, memory_seq_rm [346, end)
2026-05-16 22:30:42.465 | slot update_slots: id  3 | task 0 | prompt processing progress, n_tokens = 858, batch.n_tokens = 537, progress = 0.995360
2026-05-16 22:30:42.637 | slot create_check: id  3 | task 0 | created context checkpoint 1 of 32 (pos_min = 345, pos_max = 345, n_tokens = 346, size = 150.351 MiB)
2026-05-16 22:30:42.866 | slot update_slots: id  2 | task 2 | n_tokens = 8217, memory_seq_rm [8217, end)
2026-05-16 22:30:42.866 | slot update_slots: id  2 | task 2 | prompt processing progress, n_tokens = 8729, batch.n_tokens = 512, progress = 0.999542
2026-05-16 22:30:42.866 | slot update_slots: id  3 | task 0 | n_tokens = 858, memory_seq_rm [858, end)
2026-05-16 22:30:42.866 | slot init_sampler: id  3 | task 0 | init sampler, took 0.15 ms, tokens: text = 862, total = 862
2026-05-16 22:30:42.866 | slot update_slots: id  3 | task 0 | prompt processing done, n_tokens = 862, batch.n_tokens = 516
2026-05-16 22:30:43.034 | slot create_check: id  3 | task 0 | created context checkpoint 2 of 32 (pos_min = 857, pos_max = 857, n_tokens = 858, size = 151.423 MiB)
2026-05-16 22:30:43.282 | srv  log_server_r: done request: POST /v1/chat/completions 172.18.0.1 200
2026-05-16 22:30:43.300 | ~llama_io_write_device: allocated 'CUDA0' buffer 149.625 MiB
2026-05-16 22:30:43.305 | slot update_slots: id  2 | task 2 | n_tokens = 8729, memory_seq_rm [8729, end)
2026-05-16 22:30:43.306 | slot init_sampler: id  2 | task 2 | init sampler, took 1.16 ms, tokens: text = 8733, total = 8733
2026-05-16 22:30:43.306 | slot update_slots: id  2 | task 2 | prompt processing done, n_tokens = 8733, batch.n_tokens = 7
2026-05-16 22:30:43.494 | slot create_check: id  2 | task 2 | created context checkpoint 2 of 32 (pos_min = 8728, pos_max = 8728, n_tokens = 8729, size = 167.907 MiB)
2026-05-16 22:30:43.569 | srv  log_server_r: done request: POST /v1/chat/completions 172.18.0.1 200
2026-05-16 22:30:43.582 | ~llama_io_write_device: allocated 'CUDA0' buffer 149.625 MiB
2026-05-16 22:30:44.375 | reasoning-budget: deactivated (natural end)
2026-05-16 22:30:44.722 | slot print_timing: id  2 | task 2 | 
2026-05-16 22:30:44.722 | prompt eval time =    6419.23 ms /  8733 tokens (    0.74 ms per token,  1360.44 tokens per second)
2026-05-16 22:30:44.722 |        eval time =    1153.51 ms /    43 tokens (   26.83 ms per token,    37.28 tokens per second)
2026-05-16 22:30:44.722 |       total time =    7572.74 ms /  8776 tokens
2026-05-16 22:30:44.722 | draft acceptance rate = 1.00000 (   26 accepted /    26 generated)
2026-05-16 22:30:44.722 | statistics mtp: #calls(b,g,a) = 2 17 28, #gen drafts = 28, #acc drafts = 28, #gen tokens = 48, #acc tokens = 48, dur(b,g,a) = 0.009, 97.349, 0.006 ms
2026-05-16 22:30:44.723 | slot      release: id  2 | task 2 | stop processing: n_tokens = 8775, truncated = 0
2026-05-16 22:30:56.448 | slot print_timing: id  3 | task 0 | 
2026-05-16 22:30:56.448 | prompt eval time =    6890.11 ms /   862 tokens (    7.99 ms per token,   125.11 tokens per second)
2026-05-16 22:30:56.448 |        eval time =   13167.09 ms /   840 tokens (   15.68 ms per token,    63.80 tokens per second)
2026-05-16 22:30:56.448 |       total time =   20057.20 ms /  1702 tokens
2026-05-16 22:30:56.448 | draft acceptance rate = 0.97951 (  478 accepted /   488 generated)
2026-05-16 22:30:56.448 | statistics mtp: #calls(b,g,a) = 2 361 295, #gen drafts = 295, #acc drafts = 295, #gen tokens = 514, #acc tokens = 504, dur(b,g,a) = 0.009, 1287.095, 0.113 ms
2026-05-16 22:30:56.448 | slot      release: id  3 | task 0 | stop processing: n_tokens = 1701, truncated = 0
2026-05-16 22:30:56.448 | srv  update_slots: all slots are idle
2026-05-16 22:36:26.895 | srv  params_from_: Chat format: peg-native
2026-05-16 22:36:26.897 | slot get_availabl: id  3 | task -1 | selected slot by LCP similarity, sim_best = 0.620 (> 0.100 thold), f_keep = 0.319
2026-05-16 22:36:26.897 | srv  get_availabl: updating prompt cache
2026-05-16 22:36:26.897 | srv   prompt_save:  - saving prompt with length 1701, total state size = 209.700 MiB (draft: 3.562 MiB)
2026-05-16 22:36:27.074 | srv  params_from_: Chat format: peg-native
2026-05-16 22:36:27.542 | srv          load:  - looking for better prompt, base f_keep = 0.319, sim = 0.620
2026-05-16 22:36:27.542 | srv        update:  - cache state: 1 prompts, 511.474 MiB (limits: 8192.000 MiB, 131072 tokens, 131072 est)
2026-05-16 22:36:27.542 | srv        update:    - prompt 0x590a375b35b0:    1701 tokens, checkpoints:  2,   511.474 MiB
2026-05-16 22:36:27.542 | srv  get_availabl: prompt cache update took 645.21 ms
2026-05-16 22:36:27.543 | slot launch_slot_: id  3 | task -1 | sampler chain: logits -> penalties -> ?dry -> ?top-n-sigma -> top-k -> ?typical -> ?top-p -> min-p -> ?xtc -> ?temp-ext -> dist 
2026-05-16 22:36:27.543 | slot launch_slot_: id  3 | task 389 | processing task, is_child = 0
2026-05-16 22:36:27.543 | slot slot_save_an: id  2 | task -1 | saving idle slot to prompt cache
2026-05-16 22:36:27.543 | srv   prompt_save:  - saving prompt with length 8775, total state size = 459.529 MiB (draft: 18.377 MiB)
2026-05-16 22:36:28.562 | slot prompt_clear: id  2 | task -1 | clearing prompt with 8775 tokens
2026-05-16 22:36:28.564 | srv        update:  - cache state: 2 prompts, 1305.692 MiB (limits: 8192.000 MiB, 131072 tokens, 131072 est)
2026-05-16 22:36:28.564 | srv        update:    - prompt 0x590a375b35b0:    1701 tokens, checkpoints:  2,   511.474 MiB
2026-05-16 22:36:28.564 | srv        update:    - prompt 0x590a377c4bf0:    8775 tokens, checkpoints:  2,   794.218 MiB
2026-05-16 22:36:28.564 | slot get_availabl: id  1 | task -1 | selected slot by LRU, t_last = -1
2026-05-16 22:36:28.564 | srv  get_availabl: updating prompt cache
2026-05-16 22:36:28.564 | srv          load:  - looking for better prompt, base f_keep = -1.000, sim = 0.000
2026-05-16 22:36:28.564 | srv          load:  - found better prompt with f_keep = 0.915, sim = 0.919
2026-05-16 22:36:36.341 | srv        update:  - cache state: 1 prompts, 511.474 MiB (limits: 8192.000 MiB, 131072 tokens, 131072 est)
2026-05-16 22:36:36.341 | srv        update:    - prompt 0x590a375b35b0:    1701 tokens, checkpoints:  2,   511.474 MiB
2026-05-16 22:36:36.341 | srv  get_availabl: prompt cache update took 7776.64 ms
2026-05-16 22:36:36.342 | reasoning-budget: activated, budget=2147483647 tokens
2026-05-16 22:36:36.342 | slot launch_slot_: id  1 | task -1 | sampler chain: logits -> penalties -> ?dry -> ?top-n-sigma -> top-k -> ?typical -> ?top-p -> min-p -> ?xtc -> ?temp-ext -> dist 
2026-05-16 22:36:36.342 | slot launch_slot_: id  1 | task 390 | processing task, is_child = 0
2026-05-16 22:36:36.342 | slot update_slots: id  1 | task 390 | new prompt, n_ctx_slot = 131072, n_keep = 0, task.n_tokens = 8742
2026-05-16 22:36:36.342 | slot update_slots: id  1 | task 390 | n_past = 8032, slot.prompt.tokens.size() = 8775, seq_id = 1, pos_min = 8774, n_swa = 0
2026-05-16 22:36:36.342 | slot update_slots: id  1 | task 390 | Checking checkpoint with [8728, 8728] against 8032...
2026-05-16 22:36:36.342 | slot update_slots: id  1 | task 390 | Checking checkpoint with [8191, 8191] against 8032...
2026-05-16 22:36:36.342 | slot update_slots: id  1 | task 390 | forcing full prompt re-processing due to lack of cache data (likely due to SWA or hybrid/recurrent memory, see https://github.com/ggml-org/llama.cpp/pull/13194#issuecomment-2868343055)
2026-05-16 22:36:36.342 | slot update_slots: id  1 | task 390 | erased invalidated context checkpoint (pos_min = 8191, pos_max = 8191, n_tokens = 8192, n_swa = 0, pos_next = 0, size = 166.782 MiB)
2026-05-16 22:36:36.351 | slot update_slots: id  1 | task 390 | erased invalidated context checkpoint (pos_min = 8728, pos_max = 8728, n_tokens = 8729, n_swa = 0, pos_next = 0, size = 167.907 MiB)
2026-05-16 22:36:36.361 | slot update_slots: id  1 | task 390 | n_tokens = 0, memory_seq_rm [0, end)
2026-05-16 22:36:36.363 | slot update_slots: id  1 | task 390 | prompt processing progress, n_tokens = 2048, batch.n_tokens = 2048, progress = 0.234271
2026-05-16 22:36:37.161 | slot update_slots: id  1 | task 390 | n_tokens = 2048, memory_seq_rm [2048, end)
2026-05-16 22:36:37.161 | slot update_slots: id  1 | task 390 | prompt processing progress, n_tokens = 4096, batch.n_tokens = 2048, progress = 0.468543
2026-05-16 22:36:37.908 | slot update_slots: id  1 | task 390 | n_tokens = 4096, memory_seq_rm [4096, end)
2026-05-16 22:36:37.908 | slot update_slots: id  1 | task 390 | prompt processing progress, n_tokens = 6144, batch.n_tokens = 2048, progress = 0.702814
2026-05-16 22:36:38.651 | slot update_slots: id  1 | task 390 | n_tokens = 6144, memory_seq_rm [6144, end)
2026-05-16 22:36:38.652 | slot update_slots: id  1 | task 390 | prompt processing progress, n_tokens = 8192, batch.n_tokens = 2048, progress = 0.937085
2026-05-16 22:36:39.396 | slot update_slots: id  1 | task 390 | n_tokens = 8192, memory_seq_rm [8192, end)
2026-05-16 22:36:39.396 | slot update_slots: id  1 | task 390 | 8192 tokens since last checkpoint at 0, creating new checkpoint during processing at position 8226
2026-05-16 22:36:39.396 | slot update_slots: id  1 | task 390 | prompt processing progress, n_tokens = 8226, batch.n_tokens = 34, progress = 0.940975
2026-05-16 22:36:39.569 | slot create_check: id  1 | task 390 | created context checkpoint 1 of 32 (pos_min = 8191, pos_max = 8191, n_tokens = 8192, size = 166.782 MiB)
2026-05-16 22:36:39.570 | slot update_slots: id  3 | task 389 | new prompt, n_ctx_slot = 131072, n_keep = 0, task.n_tokens = 874
2026-05-16 22:36:39.570 | slot update_slots: id  3 | task 389 | n_past = 542, slot.prompt.tokens.size() = 1701, seq_id = 3, pos_min = 1700, n_swa = 0
2026-05-16 22:36:39.570 | slot update_slots: id  3 | task 389 | Checking checkpoint with [857, 857] against 542...
2026-05-16 22:36:39.570 | slot update_slots: id  3 | task 389 | Checking checkpoint with [345, 345] against 542...
2026-05-16 22:36:39.587 | slot update_slots: id  3 | task 389 | restored context checkpoint (pos_min = 345, pos_max = 345, n_tokens = 346, n_past = 346, size = 150.351 MiB)
2026-05-16 22:36:39.587 | slot update_slots: id  3 | task 389 | erased invalidated context checkpoint (pos_min = 857, pos_max = 857, n_tokens = 858, n_swa = 0, pos_next = 346, size = 151.423 MiB)
2026-05-16 22:36:39.596 | slot update_slots: id  3 | task 389 | n_tokens = 346, memory_seq_rm [346, end)
2026-05-16 22:36:39.596 | slot update_slots: id  3 | task 389 | prompt processing progress, n_tokens = 358, batch.n_tokens = 46, progress = 0.409611
2026-05-16 22:36:39.697 | slot update_slots: id  1 | task 390 | n_tokens = 8226, memory_seq_rm [8226, end)
2026-05-16 22:36:39.697 | slot update_slots: id  1 | task 390 | prompt processing progress, n_tokens = 8738, batch.n_tokens = 512, progress = 0.999542
2026-05-16 22:36:39.697 | slot update_slots: id  3 | task 389 | n_tokens = 358, memory_seq_rm [358, end)
2026-05-16 22:36:39.698 | slot update_slots: id  3 | task 389 | prompt processing progress, n_tokens = 870, batch.n_tokens = 1024, progress = 0.995423
2026-05-16 22:36:40.074 | slot update_slots: id  1 | task 390 | n_tokens = 8738, memory_seq_rm [8738, end)
2026-05-16 22:36:40.075 | slot init_sampler: id  1 | task 390 | init sampler, took 1.23 ms, tokens: text = 8742, total = 8742
2026-05-16 22:36:40.075 | slot update_slots: id  1 | task 390 | prompt processing done, n_tokens = 8742, batch.n_tokens = 4
2026-05-16 22:36:40.194 | slot create_check: id  1 | task 390 | created context checkpoint 2 of 32 (pos_min = 8737, pos_max = 8737, n_tokens = 8738, size = 167.926 MiB)
2026-05-16 22:36:40.194 | slot update_slots: id  3 | task 389 | n_tokens = 870, memory_seq_rm [870, end)
2026-05-16 22:36:40.195 | slot init_sampler: id  3 | task 389 | init sampler, took 0.14 ms, tokens: text = 874, total = 874
2026-05-16 22:36:40.195 | slot update_slots: id  3 | task 389 | prompt processing done, n_tokens = 874, batch.n_tokens = 8
2026-05-16 22:36:40.364 | slot create_check: id  3 | task 389 | created context checkpoint 2 of 32 (pos_min = 869, pos_max = 869, n_tokens = 870, size = 151.448 MiB)
2026-05-16 22:36:40.432 | srv  log_server_r: done request: POST /v1/chat/completions 172.18.0.1 200
2026-05-16 22:36:40.433 | srv  log_server_r: done request: POST /v1/chat/completions 172.18.0.1 200
2026-05-16 22:36:40.440 | ~llama_io_write_device: allocated 'CUDA0' buffer 149.625 MiB
2026-05-16 22:36:41.453 | reasoning-budget: deactivated (natural end)
2026-05-16 22:36:43.739 | slot print_timing: id  1 | task 390 | 
2026-05-16 22:36:43.739 | prompt eval time =    4089.71 ms /  8742 tokens (    0.47 ms per token,  2137.56 tokens per second)
2026-05-16 22:36:43.739 |        eval time =    3307.12 ms /   113 tokens (   29.27 ms per token,    34.17 tokens per second)
2026-05-16 22:36:43.739 |       total time =    7396.83 ms /  8855 tokens
2026-05-16 22:36:43.739 | draft acceptance rate = 0.97222 (   70 accepted /    72 generated)
2026-05-16 22:36:43.739 | statistics mtp: #calls(b,g,a) = 4 406 371, #gen drafts = 372, #acc drafts = 371, #gen tokens = 655, #acc tokens = 641, dur(b,g,a) = 0.012, 1504.803, 0.141 ms
2026-05-16 22:36:43.739 | slot      release: id  1 | task 390 | stop processing: n_tokens = 8854, truncated = 0
2026-05-16 22:36:43.893 | srv  params_from_: Chat format: peg-native
2026-05-16 22:36:43.930 | slot get_availabl: id  1 | task -1 | selected slot by LCP similarity, sim_best = 0.894 (> 0.100 thold), f_keep = 1.000
2026-05-16 22:36:43.931 | reasoning-budget: activated, budget=2147483647 tokens
2026-05-16 22:36:43.931 | slot launch_slot_: id  1 | task -1 | sampler chain: logits -> penalties -> ?dry -> ?top-n-sigma -> top-k -> ?typical -> ?top-p -> min-p -> ?xtc -> ?temp-ext -> dist 
2026-05-16 22:36:43.931 | slot launch_slot_: id  1 | task 448 | processing task, is_child = 0
2026-05-16 22:36:43.938 | slot update_slots: id  1 | task 448 | new prompt, n_ctx_slot = 131072, n_keep = 0, task.n_tokens = 9903
2026-05-16 22:36:43.938 | slot update_slots: id  1 | task 448 | n_tokens = 8854, memory_seq_rm [8854, end)
2026-05-16 22:36:43.938 | slot update_slots: id  1 | task 448 | prompt processing progress, n_tokens = 9387, batch.n_tokens = 536, progress = 0.947895
2026-05-16 22:36:44.208 | slot update_slots: id  1 | task 448 | n_tokens = 9387, memory_seq_rm [9387, end)
2026-05-16 22:36:44.208 | slot update_slots: id  1 | task 448 | prompt processing progress, n_tokens = 9899, batch.n_tokens = 515, progress = 0.999596
2026-05-16 22:36:44.390 | slot create_check: id  1 | task 448 | created context checkpoint 3 of 32 (pos_min = 9386, pos_max = 9386, n_tokens = 9387, size = 169.285 MiB)
2026-05-16 22:36:44.623 | slot update_slots: id  1 | task 448 | n_tokens = 9899, memory_seq_rm [9899, end)
2026-05-16 22:36:44.624 | slot init_sampler: id  1 | task 448 | init sampler, took 1.33 ms, tokens: text = 9903, total = 9903
2026-05-16 22:36:44.624 | slot update_slots: id  1 | task 448 | prompt processing done, n_tokens = 9903, batch.n_tokens = 6
2026-05-16 22:36:44.821 | slot create_check: id  1 | task 448 | created context checkpoint 4 of 32 (pos_min = 9898, pos_max = 9898, n_tokens = 9899, size = 170.357 MiB)
2026-05-16 22:36:44.881 | srv  log_server_r: done request: POST /v1/chat/completions 172.18.0.1 200
2026-05-16 22:36:52.373 | reasoning-budget: deactivated (natural end)
2026-05-16 22:36:57.747 | slot print_timing: id  1 | task 448 | 
2026-05-16 22:36:57.747 | prompt eval time =     942.51 ms /  1049 tokens (    0.90 ms per token,  1112.98 tokens per second)
2026-05-16 22:36:57.747 |        eval time =   13736.17 ms /   402 tokens (   34.17 ms per token,    29.27 tokens per second)
2026-05-16 22:36:57.747 |       total time =   14678.68 ms /  1451 tokens
2026-05-16 22:36:57.747 | draft acceptance rate = 0.97071 (  232 accepted /   239 generated)
2026-05-16 22:36:57.747 | statistics mtp: #calls(b,g,a) = 5 602 670, #gen drafts = 671, #acc drafts = 670, #gen tokens = 1177, #acc tokens = 1154, dur(b,g,a) = 0.013, 2449.552, 0.263 ms
2026-05-16 22:36:57.747 | slot      release: id  1 | task 448 | stop processing: n_tokens = 10304, truncated = 0
2026-05-16 22:37:05.064 | slot print_timing: id  3 | task 389 | 
2026-05-16 22:37:05.064 | prompt eval time =     863.31 ms /   528 tokens (    1.64 ms per token,   611.60 tokens per second)
2026-05-16 22:37:05.064 |        eval time =   25501.13 ms /  1091 tokens (   23.37 ms per token,    42.78 tokens per second)
2026-05-16 22:37:05.064 |       total time =   26364.44 ms /  1619 tokens
2026-05-16 22:37:05.064 | draft acceptance rate = 0.98771 (  643 accepted /   651 generated)
2026-05-16 22:37:05.064 | statistics mtp: #calls(b,g,a) = 5 817 839, #gen drafts = 839, #acc drafts = 839, #gen tokens = 1476, #acc tokens = 1449, dur(b,g,a) = 0.013, 3193.862, 0.337 ms
2026-05-16 22:37:05.064 | slot      release: id  3 | task 389 | stop processing: n_tokens = 1964, truncated = 0
2026-05-16 22:37:05.064 | srv  update_slots: all slots are idle
2026-05-16 22:37:43.392 | srv  params_from_: Chat format: peg-native
2026-05-16 22:37:43.396 | slot get_availabl: id  1 | task -1 | selected slot by LCP similarity, sim_best = 0.859 (> 0.100 thold), f_keep = 0.818
2026-05-16 22:37:43.397 | reasoning-budget: activated, budget=2147483647 tokens
2026-05-16 22:37:43.397 | slot launch_slot_: id  1 | task -1 | sampler chain: logits -> penalties -> ?dry -> ?top-n-sigma -> top-k -> ?typical -> ?top-p -> min-p -> ?xtc -> ?temp-ext -> dist 
2026-05-16 22:37:43.397 | slot launch_slot_: id  1 | task 870 | processing task, is_child = 0
2026-05-16 22:37:43.397 | slot slot_save_an: id  3 | task -1 | saving idle slot to prompt cache
2026-05-16 22:37:43.398 | srv   prompt_save:  - saving prompt with length 1964, total state size = 218.988 MiB (draft: 4.113 MiB)
2026-05-16 22:37:44.476 | slot prompt_clear: id  3 | task -1 | clearing prompt with 1964 tokens
2026-05-16 22:37:44.476 | srv        update:  - cache state: 2 prompts, 1032.261 MiB (limits: 8192.000 MiB, 131072 tokens, 131072 est)
2026-05-16 22:37:44.476 | srv        update:    - prompt 0x590a375b35b0:    1701 tokens, checkpoints:  2,   511.474 MiB
2026-05-16 22:37:44.476 | srv        update:    - prompt 0x590a376f79d0:    1964 tokens, checkpoints:  2,   520.787 MiB
2026-05-16 22:37:44.476 | slot update_slots: id  1 | task 870 | new prompt, n_ctx_slot = 131072, n_keep = 0, task.n_tokens = 9811
2026-05-16 22:37:44.476 | slot update_slots: id  1 | task 870 | n_past = 8427, slot.prompt.tokens.size() = 10304, seq_id = 1, pos_min = 10303, n_swa = 0
2026-05-16 22:37:44.476 | slot update_slots: id  1 | task 870 | Checking checkpoint with [9898, 9898] against 8427...
2026-05-16 22:37:44.476 | slot update_slots: id  1 | task 870 | Checking checkpoint with [9386, 9386] against 8427...
2026-05-16 22:37:44.476 | slot update_slots: id  1 | task 870 | Checking checkpoint with [8737, 8737] against 8427...
2026-05-16 22:37:44.476 | slot update_slots: id  1 | task 870 | Checking checkpoint with [8191, 8191] against 8427...
2026-05-16 22:37:44.539 | slot update_slots: id  1 | task 870 | restored context checkpoint (pos_min = 8191, pos_max = 8191, n_tokens = 8192, n_past = 8192, size = 166.782 MiB)
2026-05-16 22:37:44.539 | slot update_slots: id  1 | task 870 | erased invalidated context checkpoint (pos_min = 8737, pos_max = 8737, n_tokens = 8738, n_swa = 0, pos_next = 8192, size = 167.926 MiB)
2026-05-16 22:37:44.548 | slot update_slots: id  1 | task 870 | erased invalidated context checkpoint (pos_min = 9386, pos_max = 9386, n_tokens = 9387, n_swa = 0, pos_next = 8192, size = 169.285 MiB)
2026-05-16 22:37:44.558 | slot update_slots: id  1 | task 870 | erased invalidated context checkpoint (pos_min = 9898, pos_max = 9898, n_tokens = 9899, n_swa = 0, pos_next = 8192, size = 170.357 MiB)
2026-05-16 22:37:44.568 | slot update_slots: id  1 | task 870 | n_tokens = 8192, memory_seq_rm [8192, end)
2026-05-16 22:37:44.568 | slot update_slots: id  1 | task 870 | prompt processing progress, n_tokens = 9295, batch.n_tokens = 1103, progress = 0.947406
2026-05-16 22:37:45.258 | slot update_slots: id  1 | task 870 | n_tokens = 9295, memory_seq_rm [9295, end)
2026-05-16 22:37:45.258 | slot update_slots: id  1 | task 870 | prompt processing progress, n_tokens = 9807, batch.n_tokens = 512, progress = 0.999592
2026-05-16 22:37:45.371 | slot create_check: id  1 | task 870 | created context checkpoint 2 of 32 (pos_min = 9294, pos_max = 9294, n_tokens = 9295, size = 169.092 MiB)
2026-05-16 22:37:45.563 | slot update_slots: id  1 | task 870 | n_tokens = 9807, memory_seq_rm [9807, end)
2026-05-16 22:37:45.564 | slot init_sampler: id  1 | task 870 | init sampler, took 1.31 ms, tokens: text = 9811, total = 9811
2026-05-16 22:37:45.564 | slot update_slots: id  1 | task 870 | prompt processing done, n_tokens = 9811, batch.n_tokens = 4
2026-05-16 22:37:45.688 | slot create_check: id  1 | task 870 | created context checkpoint 3 of 32 (pos_min = 9806, pos_max = 9806, n_tokens = 9807, size = 170.165 MiB)
2026-05-16 22:37:45.724 | srv  log_server_r: done request: POST /v1/chat/completions 172.18.0.1 200
2026-05-16 22:37:46.014 | reasoning-budget: deactivated (natural end)
2026-05-16 22:37:46.759 | slot print_timing: id  1 | task 870 | 
2026-05-16 22:37:46.759 | prompt eval time =    1247.12 ms /  1619 tokens (    0.77 ms per token,  1298.19 tokens per second)
2026-05-16 22:37:46.759 |        eval time =    1034.88 ms /    85 tokens (   12.18 ms per token,    82.13 tokens per second)
2026-05-16 22:37:46.759 |       total time =    2282.01 ms /  1704 tokens
2026-05-16 22:37:46.759 | draft acceptance rate = 0.96491 (   55 accepted /    57 generated)
2026-05-16 22:37:46.759 | statistics mtp: #calls(b,g,a) = 6 846 868, #gen drafts = 868, #acc drafts = 868, #gen tokens = 1533, #acc tokens = 1504, dur(b,g,a) = 0.014, 3313.382, 0.348 ms
2026-05-16 22:37:46.759 | slot      release: id  1 | task 870 | stop processing: n_tokens = 9895, truncated = 0
2026-05-16 22:37:46.759 | srv  update_slots: all slots are idle
2026-05-16 22:37:46.894 | srv  params_from_: Chat format: peg-native
2026-05-16 22:37:46.897 | slot get_availabl: id  1 | task -1 | selected slot by LCP similarity, sim_best = 0.994 (> 0.100 thold), f_keep = 1.000
2026-05-16 22:37:46.898 | reasoning-budget: activated, budget=2147483647 tokens
2026-05-16 22:37:46.898 | slot launch_slot_: id  1 | task -1 | sampler chain: logits -> penalties -> ?dry -> ?top-n-sigma -> top-k -> ?typical -> ?top-p -> min-p -> ?xtc -> ?temp-ext -> dist 
2026-05-16 22:37:46.898 | slot launch_slot_: id  1 | task 906 | processing task, is_child = 0
2026-05-16 22:37:46.898 | slot update_slots: id  1 | task 906 | new prompt, n_ctx_slot = 131072, n_keep = 0, task.n_tokens = 9958
2026-05-16 22:37:46.898 | slot update_slots: id  1 | task 906 | n_tokens = 9895, memory_seq_rm [9895, end)
2026-05-16 22:37:46.898 | slot update_slots: id  1 | task 906 | prompt processing progress, n_tokens = 9954, batch.n_tokens = 59, progress = 0.999598
2026-05-16 22:37:47.094 | slot create_check: id  1 | task 906 | created context checkpoint 4 of 32 (pos_min = 9894, pos_max = 9894, n_tokens = 9895, size = 170.349 MiB)
2026-05-16 22:37:47.146 | slot update_slots: id  1 | task 906 | n_tokens = 9954, memory_seq_rm [9954, end)
2026-05-16 22:37:47.148 | slot init_sampler: id  1 | task 906 | init sampler, took 1.37 ms, tokens: text = 9958, total = 9958
2026-05-16 22:37:47.148 | slot update_slots: id  1 | task 906 | prompt processing done, n_tokens = 9958, batch.n_tokens = 4
2026-05-16 22:37:47.183 | srv  log_server_r: done request: POST /v1/chat/completions 172.18.0.1 200
2026-05-16 22:37:47.303 | reasoning-budget: deactivated (natural end)
2026-05-16 22:37:47.561 | slot print_timing: id  1 | task 906 | 
2026-05-16 22:37:47.561 | prompt eval time =     284.06 ms /    63 tokens (    4.51 ms per token,   221.78 tokens per second)
2026-05-16 22:37:47.561 |        eval time =     378.19 ms /    26 tokens (   14.55 ms per token,    68.75 tokens per second)
2026-05-16 22:37:47.561 |       total time =     662.25 ms /    89 tokens
2026-05-16 22:37:47.561 | draft acceptance rate = 1.00000 (   16 accepted /    16 generated)
2026-05-16 22:37:47.561 | statistics mtp: #calls(b,g,a) = 7 855 877, #gen drafts = 877, #acc drafts = 877, #gen tokens = 1549, #acc tokens = 1520, dur(b,g,a) = 0.015, 3353.985, 0.353 ms
2026-05-16 22:37:47.561 | slot      release: id  1 | task 906 | stop processing: n_tokens = 9983, truncated = 0
2026-05-16 22:37:47.561 | srv  update_slots: all slots are idle
2026-05-16 22:45:09.150 | srv  params_from_: Chat format: peg-native
2026-05-16 22:45:09.152 | slot get_availabl: id  0 | task -1 | selected slot by LRU, t_last = -1
2026-05-16 22:45:09.152 | srv  get_availabl: updating prompt cache
2026-05-16 22:45:09.152 | srv          load:  - looking for better prompt, base f_keep = -1.000, sim = 0.000
2026-05-16 22:45:09.152 | srv          load:  - found better prompt with f_keep = 0.319, sim = 0.550
2026-05-16 22:45:09.253 | srv        update:  - cache state: 1 prompts, 520.787 MiB (limits: 8192.000 MiB, 131072 tokens, 131072 est)
2026-05-16 22:45:09.253 | srv        update:    - prompt 0x590a376f79d0:    1964 tokens, checkpoints:  2,   520.787 MiB
2026-05-16 22:45:09.253 | srv  get_availabl: prompt cache update took 101.66 ms
2026-05-16 22:45:09.254 | slot launch_slot_: id  0 | task -1 | sampler chain: logits -> penalties -> ?dry -> ?top-n-sigma -> top-k -> ?typical -> ?top-p -> min-p -> ?xtc -> ?temp-ext -> dist 
2026-05-16 22:45:09.254 | slot launch_slot_: id  0 | task 920 | processing task, is_child = 0
2026-05-16 22:45:09.254 | slot slot_save_an: id  1 | task -1 | saving idle slot to prompt cache
2026-05-16 22:45:09.255 | srv   prompt_save:  - saving prompt with length 9983, total state size = 502.191 MiB (draft: 20.907 MiB)
2026-05-16 22:45:09.288 | srv  params_from_: Chat format: peg-native
2026-05-16 22:45:09.709 | slot prompt_clear: id  1 | task -1 | clearing prompt with 9983 tokens
2026-05-16 22:45:09.711 | srv        update:  - cache state: 2 prompts, 1699.366 MiB (limits: 8192.000 MiB, 131072 tokens, 131072 est)
2026-05-16 22:45:09.711 | srv        update:    - prompt 0x590a376f79d0:    1964 tokens, checkpoints:  2,   520.787 MiB
2026-05-16 22:45:09.711 | srv        update:    - prompt 0x590a34fb7950:    9983 tokens, checkpoints:  4,  1178.579 MiB
2026-05-16 22:45:09.711 | slot get_availabl: id  2 | task -1 | selected slot by LRU, t_last = 7100880076
2026-05-16 22:45:09.711 | srv  get_availabl: updating prompt cache
2026-05-16 22:45:09.711 | srv          load:  - looking for better prompt, base f_keep = -1.000, sim = 0.000
2026-05-16 22:45:09.711 | srv          load:  - found better prompt with f_keep = 0.805, sim = 0.907
2026-05-16 22:45:09.834 | srv        update:  - cache state: 1 prompts, 520.787 MiB (limits: 8192.000 MiB, 131072 tokens, 131072 est)
2026-05-16 22:45:09.834 | srv        update:    - prompt 0x590a376f79d0:    1964 tokens, checkpoints:  2,   520.787 MiB
2026-05-16 22:45:09.834 | srv  get_availabl: prompt cache update took 123.13 ms
2026-05-16 22:45:09.835 | reasoning-budget: activated, budget=2147483647 tokens
2026-05-16 22:45:09.835 | slot launch_slot_: id  2 | task -1 | sampler chain: logits -> penalties -> ?dry -> ?top-n-sigma -> top-k -> ?typical -> ?top-p -> min-p -> ?xtc -> ?temp-ext -> dist 
2026-05-16 22:45:09.835 | slot launch_slot_: id  2 | task 921 | processing task, is_child = 0
2026-05-16 22:45:09.835 | slot update_slots: id  0 | task 920 | new prompt, n_ctx_slot = 131072, n_keep = 0, task.n_tokens = 985
2026-05-16 22:45:09.835 | slot update_slots: id  0 | task 920 | n_past = 542, slot.prompt.tokens.size() = 1701, seq_id = 0, pos_min = 1700, n_swa = 0
2026-05-16 22:45:09.835 | slot update_slots: id  0 | task 920 | Checking checkpoint with [857, 857] against 542...
2026-05-16 22:45:09.835 | slot update_slots: id  0 | task 920 | Checking checkpoint with [345, 345] against 542...
2026-05-16 22:45:09.862 | slot update_slots: id  0 | task 920 | restored context checkpoint (pos_min = 345, pos_max = 345, n_tokens = 346, n_past = 346, size = 150.351 MiB)
2026-05-16 22:45:09.862 | slot update_slots: id  0 | task 920 | erased invalidated context checkpoint (pos_min = 857, pos_max = 857, n_tokens = 858, n_swa = 0, pos_next = 346, size = 151.423 MiB)
2026-05-16 22:45:09.871 | slot update_slots: id  0 | task 920 | n_tokens = 346, memory_seq_rm [346, end)
2026-05-16 22:45:09.871 | slot update_slots: id  0 | task 920 | prompt processing progress, n_tokens = 469, batch.n_tokens = 123, progress = 0.476142
2026-05-16 22:45:09.871 | slot update_slots: id  2 | task 921 | new prompt, n_ctx_slot = 131072, n_keep = 0, task.n_tokens = 8856
2026-05-16 22:45:09.871 | slot update_slots: id  2 | task 921 | n_past = 8032, slot.prompt.tokens.size() = 9983, seq_id = 2, pos_min = 9982, n_swa = 0
2026-05-16 22:45:09.871 | slot update_slots: id  2 | task 921 | Checking checkpoint with [9894, 9894] against 8032...
2026-05-16 22:45:09.871 | slot update_slots: id  2 | task 921 | Checking checkpoint with [9806, 9806] against 8032...
2026-05-16 22:45:09.871 | slot update_slots: id  2 | task 921 | Checking checkpoint with [9294, 9294] against 8032...
2026-05-16 22:45:09.871 | slot update_slots: id  2 | task 921 | Checking checkpoint with [8191, 8191] against 8032...
2026-05-16 22:45:09.871 | slot update_slots: id  2 | task 921 | forcing full prompt re-processing due to lack of cache data (likely due to SWA or hybrid/recurrent memory, see https://github.com/ggml-org/llama.cpp/pull/13194#issuecomment-2868343055)
2026-05-16 22:45:09.871 | slot update_slots: id  2 | task 921 | erased invalidated context checkpoint (pos_min = 8191, pos_max = 8191, n_tokens = 8192, n_swa = 0, pos_next = 0, size = 166.782 MiB)
2026-05-16 22:45:09.880 | slot update_slots: id  2 | task 921 | erased invalidated context checkpoint (pos_min = 9294, pos_max = 9294, n_tokens = 9295, n_swa = 0, pos_next = 0, size = 169.092 MiB)
2026-05-16 22:45:09.888 | slot update_slots: id  2 | task 921 | erased invalidated context checkpoint (pos_min = 9806, pos_max = 9806, n_tokens = 9807, n_swa = 0, pos_next = 0, size = 170.165 MiB)
2026-05-16 22:45:09.897 | slot update_slots: id  2 | task 921 | erased invalidated context checkpoint (pos_min = 9894, pos_max = 9894, n_tokens = 9895, n_swa = 0, pos_next = 0, size = 170.349 MiB)
2026-05-16 22:45:09.910 | slot update_slots: id  2 | task 921 | n_tokens = 0, memory_seq_rm [0, end)
2026-05-16 22:45:09.912 | slot update_slots: id  2 | task 921 | prompt processing progress, n_tokens = 1925, batch.n_tokens = 2048, progress = 0.217367
2026-05-16 22:45:10.739 | slot update_slots: id  0 | task 920 | n_tokens = 469, memory_seq_rm [469, end)
2026-05-16 22:45:10.739 | slot update_slots: id  0 | task 920 | prompt processing progress, n_tokens = 981, batch.n_tokens = 512, progress = 0.995939
2026-05-16 22:45:10.856 | slot create_check: id  0 | task 920 | created context checkpoint 2 of 32 (pos_min = 468, pos_max = 468, n_tokens = 469, size = 150.608 MiB)
2026-05-16 22:45:10.856 | slot update_slots: id  2 | task 921 | n_tokens = 1925, memory_seq_rm [1925, end)
2026-05-16 22:45:10.856 | slot update_slots: id  2 | task 921 | prompt processing progress, n_tokens = 3461, batch.n_tokens = 2048, progress = 0.390808
2026-05-16 22:45:11.617 | slot update_slots: id  0 | task 920 | n_tokens = 981, memory_seq_rm [981, end)
2026-05-16 22:45:11.617 | slot init_sampler: id  0 | task 920 | init sampler, took 0.15 ms, tokens: text = 985, total = 985
2026-05-16 22:45:11.617 | slot update_slots: id  0 | task 920 | prompt processing done, n_tokens = 985, batch.n_tokens = 4
2026-05-16 22:45:11.758 | slot create_check: id  0 | task 920 | created context checkpoint 3 of 32 (pos_min = 980, pos_max = 980, n_tokens = 981, size = 151.681 MiB)
2026-05-16 22:45:11.758 | slot update_slots: id  2 | task 921 | n_tokens = 3461, memory_seq_rm [3461, end)
2026-05-16 22:45:11.758 | slot update_slots: id  2 | task 921 | prompt processing progress, n_tokens = 5505, batch.n_tokens = 2048, progress = 0.621612
2026-05-16 22:45:12.545 | srv  log_server_r: done request: POST /v1/chat/completions 172.18.0.1 200
2026-05-16 22:45:12.558 | ~llama_io_write_device: allocated 'CUDA0' buffer 149.625 MiB
2026-05-16 22:45:12.563 | slot update_slots: id  2 | task 921 | n_tokens = 5505, memory_seq_rm [5505, end)
2026-05-16 22:45:12.563 | slot update_slots: id  2 | task 921 | prompt processing progress, n_tokens = 7550, batch.n_tokens = 2048, progress = 0.852529
2026-05-16 22:45:13.359 | slot update_slots: id  2 | task 921 | n_tokens = 7550, memory_seq_rm [7550, end)
2026-05-16 22:45:13.359 | slot update_slots: id  2 | task 921 | prompt processing progress, n_tokens = 8340, batch.n_tokens = 793, progress = 0.941734
2026-05-16 22:45:13.708 | slot update_slots: id  2 | task 921 | n_tokens = 8340, memory_seq_rm [8340, end)
2026-05-16 22:45:13.709 | slot update_slots: id  2 | task 921 | prompt processing progress, n_tokens = 8852, batch.n_tokens = 515, progress = 0.999548
2026-05-16 22:45:13.849 | slot create_check: id  2 | task 921 | created context checkpoint 1 of 32 (pos_min = 8339, pos_max = 8339, n_tokens = 8340, size = 167.092 MiB)
2026-05-16 22:45:14.083 | slot update_slots: id  2 | task 921 | n_tokens = 8852, memory_seq_rm [8852, end)
2026-05-16 22:45:14.085 | slot init_sampler: id  2 | task 921 | init sampler, took 1.19 ms, tokens: text = 8856, total = 8856
2026-05-16 22:45:14.085 | slot update_slots: id  2 | task 921 | prompt processing done, n_tokens = 8856, batch.n_tokens = 7
2026-05-16 22:45:14.264 | slot create_check: id  2 | task 921 | created context checkpoint 2 of 32 (pos_min = 8851, pos_max = 8851, n_tokens = 8852, size = 168.165 MiB)
2026-05-16 22:45:14.324 | srv  log_server_r: done request: POST /v1/chat/completions 172.18.0.1 200
2026-05-16 22:45:15.576 | reasoning-budget: deactivated (natural end)
2026-05-16 22:45:17.712 | slot print_timing: id  2 | task 921 | 
2026-05-16 22:45:17.712 | prompt eval time =    4452.45 ms /  8856 tokens (    0.50 ms per token,  1989.02 tokens per second)
2026-05-16 22:45:17.712 |        eval time =    3387.88 ms /   103 tokens (   32.89 ms per token,    30.40 tokens per second)
2026-05-16 22:45:17.712 |       total time =    7840.33 ms /  8959 tokens
2026-05-16 22:45:17.712 | draft acceptance rate = 0.95312 (   61 accepted /    64 generated)
2026-05-16 22:45:17.712 | statistics mtp: #calls(b,g,a) = 9 907 948, #gen drafts = 948, #acc drafts = 948, #gen tokens = 1676, #acc tokens = 1644, dur(b,g,a) = 0.019, 3606.920, 0.382 ms
2026-05-16 22:45:17.712 | slot      release: id  2 | task 921 | stop processing: n_tokens = 8958, truncated = 0
2026-05-16 22:45:17.924 | srv  params_from_: Chat format: peg-native
2026-05-16 22:45:17.945 | slot get_availabl: id  2 | task -1 | selected slot by LCP similarity, sim_best = 0.926 (> 0.100 thold), f_keep = 1.000
2026-05-16 22:45:17.946 | reasoning-budget: activated, budget=2147483647 tokens
2026-05-16 22:45:17.946 | slot launch_slot_: id  2 | task -1 | sampler chain: logits -> penalties -> ?dry -> ?top-n-sigma -> top-k -> ?typical -> ?top-p -> min-p -> ?xtc -> ?temp-ext -> dist 
2026-05-16 22:45:17.946 | slot launch_slot_: id  2 | task 983 | processing task, is_child = 0
2026-05-16 22:45:17.949 | slot update_slots: id  2 | task 983 | new prompt, n_ctx_slot = 131072, n_keep = 0, task.n_tokens = 9677
2026-05-16 22:45:17.949 | slot update_slots: id  2 | task 983 | n_tokens = 8958, memory_seq_rm [8958, end)
2026-05-16 22:45:17.949 | slot update_slots: id  2 | task 983 | prompt processing progress, n_tokens = 9161, batch.n_tokens = 204, progress = 0.946678
2026-05-16 22:45:18.080 | slot update_slots: id  2 | task 983 | n_tokens = 9161, memory_seq_rm [9161, end)
2026-05-16 22:45:18.080 | slot update_slots: id  2 | task 983 | prompt processing progress, n_tokens = 9673, batch.n_tokens = 514, progress = 0.999587
2026-05-16 22:45:18.272 | slot create_check: id  2 | task 983 | created context checkpoint 3 of 32 (pos_min = 9160, pos_max = 9160, n_tokens = 9161, size = 168.812 MiB)
2026-05-16 22:45:18.497 | slot update_slots: id  2 | task 983 | n_tokens = 9673, memory_seq_rm [9673, end)
2026-05-16 22:45:18.499 | slot init_sampler: id  2 | task 983 | init sampler, took 1.31 ms, tokens: text = 9677, total = 9677
2026-05-16 22:45:18.499 | slot update_slots: id  2 | task 983 | prompt processing done, n_tokens = 9677, batch.n_tokens = 5
2026-05-16 22:45:18.694 | slot create_check: id  2 | task 983 | created context checkpoint 4 of 32 (pos_min = 9672, pos_max = 9672, n_tokens = 9673, size = 169.884 MiB)
2026-05-16 22:45:18.753 | srv  log_server_r: done request: POST /v1/chat/completions 172.18.0.1 200
2026-05-16 22:45:19.834 | reasoning-budget: deactivated (natural end)
2026-05-16 22:45:25.813 | slot print_timing: id  2 | task 983 | 
2026-05-16 22:45:25.813 | prompt eval time =     804.15 ms /   719 tokens (    1.12 ms per token,   894.11 tokens per second)
2026-05-16 22:45:25.813 |        eval time =    7060.26 ms /   273 tokens (   25.86 ms per token,    38.67 tokens per second)
2026-05-16 22:45:25.813 |       total time =    7864.41 ms /   992 tokens
2026-05-16 22:45:25.813 | draft acceptance rate = 1.00000 (  178 accepted /   178 generated)
2026-05-16 22:45:25.813 | statistics mtp: #calls(b,g,a) = 10 1013 1115, #gen drafts = 1115, #acc drafts = 1115, #gen tokens = 1987, #acc tokens = 1954, dur(b,g,a) = 0.020, 4108.118, 0.458 ms
2026-05-16 22:45:25.814 | slot      release: id  2 | task 983 | stop processing: n_tokens = 9949, truncated = 0
2026-05-16 22:45:25.972 | srv  params_from_: Chat format: peg-native
2026-05-16 22:45:26.007 | slot get_availabl: id  2 | task -1 | selected slot by LCP similarity, sim_best = 0.861 (> 0.100 thold), f_keep = 1.000
2026-05-16 22:45:26.008 | reasoning-budget: activated, budget=2147483647 tokens
2026-05-16 22:45:26.008 | slot launch_slot_: id  2 | task -1 | sampler chain: logits -> penalties -> ?dry -> ?top-n-sigma -> top-k -> ?typical -> ?top-p -> min-p -> ?xtc -> ?temp-ext -> dist 
2026-05-16 22:45:26.008 | slot launch_slot_: id  2 | task 1089 | processing task, is_child = 0
2026-05-16 22:45:26.015 | slot update_slots: id  2 | task 1089 | new prompt, n_ctx_slot = 131072, n_keep = 0, task.n_tokens = 11556
2026-05-16 22:45:26.015 | slot update_slots: id  2 | task 1089 | n_tokens = 9949, memory_seq_rm [9949, end)
2026-05-16 22:45:26.015 | slot update_slots: id  2 | task 1089 | prompt processing progress, n_tokens = 11040, batch.n_tokens = 1094, progress = 0.955348
2026-05-16 22:45:26.486 | slot update_slots: id  2 | task 1089 | n_tokens = 11040, memory_seq_rm [11040, end)
2026-05-16 22:45:26.486 | slot update_slots: id  2 | task 1089 | prompt processing progress, n_tokens = 11552, batch.n_tokens = 515, progress = 0.999654
2026-05-16 22:45:26.681 | slot create_check: id  2 | task 1089 | created context checkpoint 5 of 32 (pos_min = 11039, pos_max = 11039, n_tokens = 11040, size = 172.747 MiB)
2026-05-16 22:45:26.915 | slot update_slots: id  2 | task 1089 | n_tokens = 11552, memory_seq_rm [11552, end)
2026-05-16 22:45:26.916 | slot init_sampler: id  2 | task 1089 | init sampler, took 1.52 ms, tokens: text = 11556, total = 11556
2026-05-16 22:45:26.916 | slot update_slots: id  2 | task 1089 | prompt processing done, n_tokens = 11556, batch.n_tokens = 5
2026-05-16 22:45:27.121 | slot create_check: id  2 | task 1089 | created context checkpoint 6 of 32 (pos_min = 11551, pos_max = 11551, n_tokens = 11552, size = 173.819 MiB)
2026-05-16 22:45:27.179 | srv  log_server_r: done request: POST /v1/chat/completions 172.18.0.1 200
2026-05-16 22:45:34.993 | reasoning-budget: deactivated (natural end)
2026-05-16 22:45:39.538 | slot print_timing: id  2 | task 1089 | 
2026-05-16 22:45:39.538 | prompt eval time =    1164.01 ms /  1607 tokens (    0.72 ms per token,  1380.57 tokens per second)
2026-05-16 22:45:39.539 |        eval time =   13222.42 ms /   384 tokens (   34.43 ms per token,    29.04 tokens per second)
2026-05-16 22:45:39.539 |       total time =   14386.43 ms /  1991 tokens
2026-05-16 22:45:39.539 | draft acceptance rate = 0.97717 (  214 accepted /   219 generated)
2026-05-16 22:45:39.539 | statistics mtp: #calls(b,g,a) = 11 1207 1391, #gen drafts = 1391, #acc drafts = 1391, #gen tokens = 2472, #acc tokens = 2430, dur(b,g,a) = 0.021, 4995.012, 0.574 ms
2026-05-16 22:45:39.539 | slot      release: id  2 | task 1089 | stop processing: n_tokens = 11939, truncated = 0
2026-05-16 22:45:39.733 | srv  params_from_: Chat format: peg-native
2026-05-16 22:45:39.760 | slot get_availabl: id  2 | task -1 | selected slot by LCP similarity, sim_best = 0.981 (> 0.100 thold), f_keep = 1.000
2026-05-16 22:45:39.761 | reasoning-budget: activated, budget=2147483647 tokens
2026-05-16 22:45:39.761 | slot launch_slot_: id  2 | task -1 | sampler chain: logits -> penalties -> ?dry -> ?top-n-sigma -> top-k -> ?typical -> ?top-p -> min-p -> ?xtc -> ?temp-ext -> dist 
2026-05-16 22:45:39.761 | slot launch_slot_: id  2 | task 1287 | processing task, is_child = 0
2026-05-16 22:45:39.768 | slot update_slots: id  2 | task 1287 | new prompt, n_ctx_slot = 131072, n_keep = 0, task.n_tokens = 12175
2026-05-16 22:45:39.768 | slot update_slots: id  2 | task 1287 | n_tokens = 11939, memory_seq_rm [11939, end)
2026-05-16 22:45:39.768 | slot update_slots: id  2 | task 1287 | prompt processing progress, n_tokens = 12171, batch.n_tokens = 235, progress = 0.999671
2026-05-16 22:45:39.981 | slot create_check: id  2 | task 1287 | created context checkpoint 7 of 32 (pos_min = 11938, pos_max = 11938, n_tokens = 11939, size = 174.630 MiB)
2026-05-16 22:45:40.113 | slot update_slots: id  2 | task 1287 | n_tokens = 12171, memory_seq_rm [12171, end)
2026-05-16 22:45:40.114 | slot init_sampler: id  2 | task 1287 | init sampler, took 1.64 ms, tokens: text = 12175, total = 12175
2026-05-16 22:45:40.114 | slot update_slots: id  2 | task 1287 | prompt processing done, n_tokens = 12175, batch.n_tokens = 7
2026-05-16 22:45:40.334 | slot create_check: id  2 | task 1287 | created context checkpoint 8 of 32 (pos_min = 12170, pos_max = 12170, n_tokens = 12171, size = 175.116 MiB)
2026-05-16 22:45:40.397 | srv  log_server_r: done request: POST /v1/chat/completions 172.18.0.1 200
2026-05-16 22:45:42.318 | reasoning-budget: deactivated (natural end)
2026-05-16 22:45:45.369 | slot print_timing: id  2 | task 1287 | 
2026-05-16 22:45:45.369 | prompt eval time =     629.53 ms /   236 tokens (    2.67 ms per token,   374.88 tokens per second)
2026-05-16 22:45:45.369 |        eval time =    4971.97 ms /   165 tokens (   30.13 ms per token,    33.19 tokens per second)
2026-05-16 22:45:45.369 |       total time =    5601.50 ms /   401 tokens
2026-05-16 22:45:45.369 | draft acceptance rate = 1.00000 (   98 accepted /    98 generated)
2026-05-16 22:45:45.369 | statistics mtp: #calls(b,g,a) = 12 1285 1514, #gen drafts = 1514, #acc drafts = 1514, #gen tokens = 2686, #acc tokens = 2644, dur(b,g,a) = 0.022, 5368.439, 0.629 ms
2026-05-16 22:45:45.370 | slot      release: id  2 | task 1287 | stop processing: n_tokens = 12339, truncated = 0
2026-05-16 22:45:45.572 | srv  params_from_: Chat format: peg-native
2026-05-16 22:45:45.602 | slot get_availabl: id  2 | task -1 | selected slot by LCP similarity, sim_best = 0.955 (> 0.100 thold), f_keep = 1.000
2026-05-16 22:45:45.603 | reasoning-budget: activated, budget=2147483647 tokens
2026-05-16 22:45:45.603 | slot launch_slot_: id  2 | task -1 | sampler chain: logits -> penalties -> ?dry -> ?top-n-sigma -> top-k -> ?typical -> ?top-p -> min-p -> ?xtc -> ?temp-ext -> dist 
2026-05-16 22:45:45.603 | slot launch_slot_: id  2 | task 1365 | processing task, is_child = 0
2026-05-16 22:45:45.610 | slot update_slots: id  2 | task 1365 | new prompt, n_ctx_slot = 131072, n_keep = 0, task.n_tokens = 12916
2026-05-16 22:45:45.610 | slot update_slots: id  2 | task 1365 | n_tokens = 12339, memory_seq_rm [12339, end)
2026-05-16 22:45:45.611 | slot update_slots: id  2 | task 1365 | prompt processing progress, n_tokens = 12400, batch.n_tokens = 64, progress = 0.960050
2026-05-16 22:45:45.684 | slot update_slots: id  2 | task 1365 | n_tokens = 12400, memory_seq_rm [12400, end)
2026-05-16 22:45:45.684 | slot update_slots: id  2 | task 1365 | prompt processing progress, n_tokens = 12912, batch.n_tokens = 515, progress = 0.999690
2026-05-16 22:45:45.910 | slot create_check: id  2 | task 1365 | created context checkpoint 9 of 32 (pos_min = 12399, pos_max = 12399, n_tokens = 12400, size = 175.595 MiB)
2026-05-16 22:45:46.151 | slot update_slots: id  2 | task 1365 | n_tokens = 12912, memory_seq_rm [12912, end)
2026-05-16 22:45:46.152 | slot init_sampler: id  2 | task 1365 | init sampler, took 1.68 ms, tokens: text = 12916, total = 12916
2026-05-16 22:45:46.152 | slot update_slots: id  2 | task 1365 | prompt processing done, n_tokens = 12916, batch.n_tokens = 7
2026-05-16 22:45:46.357 | slot create_check: id  2 | task 1365 | created context checkpoint 10 of 32 (pos_min = 12911, pos_max = 12911, n_tokens = 12912, size = 176.667 MiB)
2026-05-16 22:45:46.420 | srv  log_server_r: done request: POST /v1/chat/completions 172.18.0.1 200
2026-05-16 22:45:48.774 | srv          stop: cancel task, id_task = 1365
2026-05-16 22:45:48.846 | slot      release: id  2 | task 1365 | stop processing: n_tokens = 12982, truncated = 0
2026-05-16 22:45:57.195 | slot print_timing: id  0 | task 920 | 
2026-05-16 22:45:57.195 | prompt eval time =    2709.33 ms /   639 tokens (    4.24 ms per token,   235.85 tokens per second)
2026-05-16 22:45:57.195 |        eval time =   45513.86 ms /  1721 tokens (   26.45 ms per token,    37.81 tokens per second)
2026-05-16 22:45:57.195 |       total time =   48223.19 ms /  2360 tokens
2026-05-16 22:45:57.195 | draft acceptance rate = 0.98931 ( 1018 accepted /  1029 generated)
2026-05-16 22:45:57.195 | statistics mtp: #calls(b,g,a) = 13 1574 1782, #gen drafts = 1782, #acc drafts = 1782, #gen tokens = 3174, #acc tokens = 3124, dur(b,g,a) = 0.023, 6482.698, 0.752 ms
2026-05-16 22:45:57.195 | slot      release: id  0 | task 920 | stop processing: n_tokens = 2705, truncated = 0
2026-05-16 22:45:57.195 | srv  update_slots: all slots are idle
2026-05-16 22:46:47.407 | srv  params_from_: Chat format: peg-native
2026-05-16 22:46:47.411 | slot get_availabl: id  2 | task -1 | selected slot by LCP similarity, sim_best = 0.674 (> 0.100 thold), f_keep = 0.658
2026-05-16 22:46:47.412 | reasoning-budget: activated, budget=2147483647 tokens
2026-05-16 22:46:47.412 | slot launch_slot_: id  2 | task -1 | sampler chain: logits -> penalties -> ?dry -> ?top-n-sigma -> top-k -> ?typical -> ?top-p -> min-p -> ?xtc -> ?temp-ext -> dist 
2026-05-16 22:46:47.412 | slot launch_slot_: id  2 | task 1662 | processing task, is_child = 0
2026-05-16 22:46:47.412 | slot slot_save_an: id  0 | task -1 | saving idle slot to prompt cache
2026-05-16 22:46:47.413 | srv   prompt_save:  - saving prompt with length 2705, total state size = 245.158 MiB (draft: 5.665 MiB)
2026-05-16 22:46:49.059 | slot prompt_clear: id  0 | task -1 | clearing prompt with 2705 tokens
2026-05-16 22:46:49.060 | srv        update:  - cache state: 2 prompts, 1218.584 MiB (limits: 8192.000 MiB, 131072 tokens, 131072 est)
2026-05-16 22:46:49.060 | srv        update:    - prompt 0x590a376f79d0:    1964 tokens, checkpoints:  2,   520.787 MiB
2026-05-16 22:46:49.060 | srv        update:    - prompt 0x590a320b3a50:    2705 tokens, checkpoints:  3,   697.797 MiB
2026-05-16 22:46:49.060 | slot update_slots: id  2 | task 1662 | new prompt, n_ctx_slot = 131072, n_keep = 0, task.n_tokens = 12668
2026-05-16 22:46:49.060 | slot update_slots: id  2 | task 1662 | n_past = 8541, slot.prompt.tokens.size() = 12982, seq_id = 2, pos_min = 12981, n_swa = 0
2026-05-16 22:46:49.060 | slot update_slots: id  2 | task 1662 | Checking checkpoint with [12911, 12911] against 8541...
2026-05-16 22:46:49.060 | slot update_slots: id  2 | task 1662 | Checking checkpoint with [12399, 12399] against 8541...
2026-05-16 22:46:49.060 | slot update_slots: id  2 | task 1662 | Checking checkpoint with [12170, 12170] against 8541...
2026-05-16 22:46:49.060 | slot update_slots: id  2 | task 1662 | Checking checkpoint with [11938, 11938] against 8541...
2026-05-16 22:46:49.060 | slot update_slots: id  2 | task 1662 | Checking checkpoint with [11551, 11551] against 8541...
2026-05-16 22:46:49.060 | slot update_slots: id  2 | task 1662 | Checking checkpoint with [11039, 11039] against 8541...
2026-05-16 22:46:49.060 | slot update_slots: id  2 | task 1662 | Checking checkpoint with [9672, 9672] against 8541...
2026-05-16 22:46:49.060 | slot update_slots: id  2 | task 1662 | Checking checkpoint with [9160, 9160] against 8541...
2026-05-16 22:46:49.060 | slot update_slots: id  2 | task 1662 | Checking checkpoint with [8851, 8851] against 8541...
2026-05-16 22:46:49.060 | slot update_slots: id  2 | task 1662 | Checking checkpoint with [8339, 8339] against 8541...
2026-05-16 22:46:49.124 | slot update_slots: id  2 | task 1662 | restored context checkpoint (pos_min = 8339, pos_max = 8339, n_tokens = 8340, n_past = 8340, size = 167.092 MiB)
2026-05-16 22:46:49.124 | slot update_slots: id  2 | task 1662 | erased invalidated context checkpoint (pos_min = 8851, pos_max = 8851, n_tokens = 8852, n_swa = 0, pos_next = 8340, size = 168.165 MiB)
2026-05-16 22:46:49.133 | slot update_slots: id  2 | task 1662 | erased invalidated context checkpoint (pos_min = 9160, pos_max = 9160, n_tokens = 9161, n_swa = 0, pos_next = 8340, size = 168.812 MiB)
2026-05-16 22:46:49.141 | slot update_slots: id  2 | task 1662 | erased invalidated context checkpoint (pos_min = 9672, pos_max = 9672, n_tokens = 9673, n_swa = 0, pos_next = 8340, size = 169.884 MiB)
2026-05-16 22:46:49.154 | slot update_slots: id  2 | task 1662 | erased invalidated context checkpoint (pos_min = 11039, pos_max = 11039, n_tokens = 11040, n_swa = 0, pos_next = 8340, size = 172.747 MiB)
2026-05-16 22:46:49.165 | slot update_slots: id  2 | task 1662 | erased invalidated context checkpoint (pos_min = 11551, pos_max = 11551, n_tokens = 11552, n_swa = 0, pos_next = 8340, size = 173.819 MiB)
2026-05-16 22:46:49.175 | slot update_slots: id  2 | task 1662 | erased invalidated context checkpoint (pos_min = 11938, pos_max = 11938, n_tokens = 11939, n_swa = 0, pos_next = 8340, size = 174.630 MiB)
2026-05-16 22:46:49.185 | slot update_slots: id  2 | task 1662 | erased invalidated context checkpoint (pos_min = 12170, pos_max = 12170, n_tokens = 12171, n_swa = 0, pos_next = 8340, size = 175.116 MiB)
2026-05-16 22:46:49.195 | slot update_slots: id  2 | task 1662 | erased invalidated context checkpoint (pos_min = 12399, pos_max = 12399, n_tokens = 12400, n_swa = 0, pos_next = 8340, size = 175.595 MiB)
2026-05-16 22:46:49.205 | slot update_slots: id  2 | task 1662 | erased invalidated context checkpoint (pos_min = 12911, pos_max = 12911, n_tokens = 12912, n_swa = 0, pos_next = 8340, size = 176.667 MiB)
2026-05-16 22:46:49.215 | slot update_slots: id  2 | task 1662 | n_tokens = 8340, memory_seq_rm [8340, end)
2026-05-16 22:46:49.216 | slot update_slots: id  2 | task 1662 | prompt processing progress, n_tokens = 10388, batch.n_tokens = 2048, progress = 0.820019
2026-05-16 22:46:50.135 | slot update_slots: id  2 | task 1662 | n_tokens = 10388, memory_seq_rm [10388, end)
2026-05-16 22:46:50.135 | slot update_slots: id  2 | task 1662 | prompt processing progress, n_tokens = 12152, batch.n_tokens = 1764, progress = 0.959267
2026-05-16 22:46:50.823 | slot update_slots: id  2 | task 1662 | n_tokens = 12152, memory_seq_rm [12152, end)
2026-05-16 22:46:50.823 | slot update_slots: id  2 | task 1662 | prompt processing progress, n_tokens = 12664, batch.n_tokens = 512, progress = 0.999684
2026-05-16 22:46:50.961 | slot create_check: id  2 | task 1662 | created context checkpoint 2 of 32 (pos_min = 12151, pos_max = 12151, n_tokens = 12152, size = 175.076 MiB)
2026-05-16 22:46:51.155 | slot update_slots: id  2 | task 1662 | n_tokens = 12664, memory_seq_rm [12664, end)
2026-05-16 22:46:51.157 | slot init_sampler: id  2 | task 1662 | init sampler, took 1.74 ms, tokens: text = 12668, total = 12668
2026-05-16 22:46:51.157 | slot update_slots: id  2 | task 1662 | prompt processing done, n_tokens = 12668, batch.n_tokens = 4
2026-05-16 22:46:51.327 | slot create_check: id  2 | task 1662 | created context checkpoint 3 of 32 (pos_min = 12663, pos_max = 12663, n_tokens = 12664, size = 176.148 MiB)
2026-05-16 22:46:51.361 | srv  log_server_r: done request: POST /v1/chat/completions 172.18.0.1 200
2026-05-16 22:46:54.923 | reasoning-budget: deactivated (natural end)
2026-05-16 22:46:56.050 | slot print_timing: id  2 | task 1662 | 
2026-05-16 22:46:56.050 | prompt eval time =    2300.59 ms /  4328 tokens (    0.53 ms per token,  1881.25 tokens per second)
2026-05-16 22:46:56.050 |        eval time =    4689.12 ms /   282 tokens (   16.63 ms per token,    60.14 tokens per second)
2026-05-16 22:46:56.050 |       total time =    6989.71 ms /  4610 tokens
2026-05-16 22:46:56.050 | draft acceptance rate = 0.97452 (  153 accepted /   157 generated)
2026-05-16 22:46:56.050 | statistics mtp: #calls(b,g,a) = 14 1702 1875, #gen drafts = 1875, #acc drafts = 1875, #gen tokens = 3331, #acc tokens = 3277, dur(b,g,a) = 0.024, 6942.745, 0.794 ms
2026-05-16 22:46:56.051 | slot      release: id  2 | task 1662 | stop processing: n_tokens = 12949, truncated = 0
2026-05-16 22:46:56.051 | srv  update_slots: all slots are idle
2026-05-16 22:46:56.202 | srv  params_from_: Chat format: peg-native
2026-05-16 22:46:56.205 | slot get_availabl: id  2 | task -1 | selected slot by LCP similarity, sim_best = 0.981 (> 0.100 thold), f_keep = 1.000
2026-05-16 22:46:56.206 | reasoning-budget: activated, budget=2147483647 tokens
2026-05-16 22:46:56.206 | slot launch_slot_: id  2 | task -1 | sampler chain: logits -> penalties -> ?dry -> ?top-n-sigma -> top-k -> ?typical -> ?top-p -> min-p -> ?xtc -> ?temp-ext -> dist 
2026-05-16 22:46:56.206 | slot launch_slot_: id  2 | task 1806 | processing task, is_child = 0
2026-05-16 22:46:56.206 | slot update_slots: id  2 | task 1806 | new prompt, n_ctx_slot = 131072, n_keep = 0, task.n_tokens = 13200
2026-05-16 22:46:56.206 | slot update_slots: id  2 | task 1806 | n_tokens = 12949, memory_seq_rm [12949, end)
2026-05-16 22:46:56.206 | slot update_slots: id  2 | task 1806 | prompt processing progress, n_tokens = 13196, batch.n_tokens = 247, progress = 0.999697
2026-05-16 22:46:56.408 | slot create_check: id  2 | task 1806 | created context checkpoint 4 of 32 (pos_min = 12948, pos_max = 12948, n_tokens = 12949, size = 176.745 MiB)
2026-05-16 22:46:56.515 | slot update_slots: id  2 | task 1806 | n_tokens = 13196, memory_seq_rm [13196, end)
2026-05-16 22:46:56.517 | slot init_sampler: id  2 | task 1806 | init sampler, took 1.79 ms, tokens: text = 13200, total = 13200
2026-05-16 22:46:56.517 | slot update_slots: id  2 | task 1806 | prompt processing done, n_tokens = 13200, batch.n_tokens = 4
2026-05-16 22:46:56.715 | slot create_check: id  2 | task 1806 | created context checkpoint 5 of 32 (pos_min = 13195, pos_max = 13195, n_tokens = 13196, size = 177.262 MiB)
2026-05-16 22:46:56.751 | srv  log_server_r: done request: POST /v1/chat/completions 172.18.0.1 200
2026-05-16 22:46:59.618 | reasoning-budget: deactivated (natural end)
2026-05-16 22:47:01.371 | slot print_timing: id  2 | task 1806 | 
2026-05-16 22:47:01.371 | prompt eval time =     544.87 ms /   251 tokens (    2.17 ms per token,   460.66 tokens per second)
2026-05-16 22:47:01.371 |        eval time =    4619.87 ms /   310 tokens (   14.90 ms per token,    67.10 tokens per second)
2026-05-16 22:47:01.371 |       total time =    5164.74 ms /   561 tokens
2026-05-16 22:47:01.371 | draft acceptance rate = 0.98361 (  180 accepted /   183 generated)
2026-05-16 22:47:01.371 | statistics mtp: #calls(b,g,a) = 15 1831 1977, #gen drafts = 1977, #acc drafts = 1977, #gen tokens = 3514, #acc tokens = 3457, dur(b,g,a) = 0.026, 7417.311, 0.848 ms
2026-05-16 22:47:01.371 | slot      release: id  2 | task 1806 | stop processing: n_tokens = 13509, truncated = 0
2026-05-16 22:47:01.371 | srv  update_slots: all slots are idle
2026-05-16 22:47:01.511 | srv  params_from_: Chat format: peg-native
2026-05-16 22:47:01.513 | slot get_availabl: id  2 | task -1 | selected slot by LCP similarity, sim_best = 0.924 (> 0.100 thold), f_keep = 1.000
2026-05-16 22:47:01.515 | reasoning-budget: activated, budget=2147483647 tokens
2026-05-16 22:47:01.515 | slot launch_slot_: id  2 | task -1 | sampler chain: logits -> penalties -> ?dry -> ?top-n-sigma -> top-k -> ?typical -> ?top-p -> min-p -> ?xtc -> ?temp-ext -> dist 
2026-05-16 22:47:01.515 | slot launch_slot_: id  2 | task 1948 | processing task, is_child = 0
2026-05-16 22:47:01.515 | slot update_slots: id  2 | task 1948 | new prompt, n_ctx_slot = 131072, n_keep = 0, task.n_tokens = 14622
2026-05-16 22:47:01.515 | slot update_slots: id  2 | task 1948 | n_tokens = 13509, memory_seq_rm [13509, end)
2026-05-16 22:47:01.515 | slot update_slots: id  2 | task 1948 | prompt processing progress, n_tokens = 14106, batch.n_tokens = 597, progress = 0.964711
2026-05-16 22:47:01.772 | slot update_slots: id  2 | task 1948 | n_tokens = 14106, memory_seq_rm [14106, end)
2026-05-16 22:47:01.772 | slot update_slots: id  2 | task 1948 | prompt processing progress, n_tokens = 14618, batch.n_tokens = 512, progress = 0.999726
2026-05-16 22:47:01.978 | slot create_check: id  2 | task 1948 | created context checkpoint 6 of 32 (pos_min = 14105, pos_max = 14105, n_tokens = 14106, size = 179.168 MiB)
2026-05-16 22:47:02.173 | slot update_slots: id  2 | task 1948 | n_tokens = 14618, memory_seq_rm [14618, end)
2026-05-16 22:47:02.174 | slot init_sampler: id  2 | task 1948 | init sampler, took 1.94 ms, tokens: text = 14622, total = 14622
2026-05-16 22:47:02.174 | slot update_slots: id  2 | task 1948 | prompt processing done, n_tokens = 14622, batch.n_tokens = 4
2026-05-16 22:47:02.382 | slot create_check: id  2 | task 1948 | created context checkpoint 7 of 32 (pos_min = 14617, pos_max = 14617, n_tokens = 14618, size = 180.240 MiB)
2026-05-16 22:47:02.417 | srv  log_server_r: done request: POST /v1/chat/completions 172.18.0.1 200
2026-05-16 22:47:03.568 | reasoning-budget: deactivated (natural end)
2026-05-16 22:47:06.563 | slot print_timing: id  2 | task 1948 | 
2026-05-16 22:47:06.563 | prompt eval time =     902.12 ms /  1113 tokens (    0.81 ms per token,  1233.75 tokens per second)
2026-05-16 22:47:06.563 |        eval time =    4146.16 ms /   342 tokens (   12.12 ms per token,    82.49 tokens per second)
2026-05-16 22:47:06.563 |       total time =    5048.28 ms /  1455 tokens
2026-05-16 22:47:06.563 | draft acceptance rate = 0.99087 (  217 accepted /   219 generated)
2026-05-16 22:47:06.563 | statistics mtp: #calls(b,g,a) = 16 1955 2093, #gen drafts = 2093, #acc drafts = 2093, #gen tokens = 3733, #acc tokens = 3674, dur(b,g,a) = 0.028, 7915.517, 0.915 ms
2026-05-16 22:47:06.564 | slot      release: id  2 | task 1948 | stop processing: n_tokens = 14963, truncated = 0
2026-05-16 22:47:06.564 | srv  update_slots: all slots are idle
2026-05-16 22:47:06.746 | srv  params_from_: Chat format: peg-native
2026-05-16 22:47:06.749 | slot get_availabl: id  2 | task -1 | selected slot by LCP similarity, sim_best = 0.998 (> 0.100 thold), f_keep = 1.000
2026-05-16 22:47:06.750 | reasoning-budget: activated, budget=2147483647 tokens
2026-05-16 22:47:06.750 | slot launch_slot_: id  2 | task -1 | sampler chain: logits -> penalties -> ?dry -> ?top-n-sigma -> top-k -> ?typical -> ?top-p -> min-p -> ?xtc -> ?temp-ext -> dist 
2026-05-16 22:47:06.750 | slot launch_slot_: id  2 | task 2081 | processing task, is_child = 0
2026-05-16 22:47:06.750 | slot update_slots: id  2 | task 2081 | new prompt, n_ctx_slot = 131072, n_keep = 0, task.n_tokens = 14990
2026-05-16 22:47:06.750 | slot update_slots: id  2 | task 2081 | n_tokens = 14963, memory_seq_rm [14963, end)
2026-05-16 22:47:06.751 | slot update_slots: id  2 | task 2081 | prompt processing progress, n_tokens = 14986, batch.n_tokens = 23, progress = 0.999733
2026-05-16 22:47:06.089 | slot create_check: id  2 | task 2081 | created context checkpoint 8 of 32 (pos_min = 14962, pos_max = 14962, n_tokens = 14963, size = 180.963 MiB)
2026-05-16 22:47:06.128 | slot update_slots: id  2 | task 2081 | n_tokens = 14986, memory_seq_rm [14986, end)
2026-05-16 22:47:06.130 | slot init_sampler: id  2 | task 2081 | init sampler, took 2.00 ms, tokens: text = 14990, total = 14990
2026-05-16 22:47:06.130 | slot update_slots: id  2 | task 2081 | prompt processing done, n_tokens = 14990, batch.n_tokens = 4
2026-05-16 22:47:06.164 | srv  log_server_r: done request: POST /v1/chat/completions 172.18.0.1 200
2026-05-16 22:47:07.163 | reasoning-budget: deactivated (natural end)
2026-05-16 22:47:08.444 | slot print_timing: id  2 | task 2081 | 
2026-05-16 22:47:08.444 | prompt eval time =     280.17 ms /    27 tokens (   10.38 ms per token,    96.37 tokens per second)
2026-05-16 22:47:08.444 |        eval time =    2280.72 ms /   171 tokens (   13.34 ms per token,    74.98 tokens per second)
2026-05-16 22:47:08.444 |       total time =    2560.89 ms /   198 tokens
2026-05-16 22:47:08.444 | draft acceptance rate = 0.99029 (  102 accepted /   103 generated)
2026-05-16 22:47:08.444 | statistics mtp: #calls(b,g,a) = 17 2023 2150, #gen drafts = 2150, #acc drafts = 2150, #gen tokens = 3836, #acc tokens = 3776, dur(b,g,a) = 0.029, 8181.007, 0.937 ms
2026-05-16 22:47:08.445 | slot      release: id  2 | task 2081 | stop processing: n_tokens = 15160, truncated = 0
2026-05-16 22:47:08.445 | srv  update_slots: all slots are idle
2026-05-16 22:47:08.610 | srv  params_from_: Chat format: peg-native
2026-05-16 22:47:08.612 | slot get_availabl: id  2 | task -1 | selected slot by LCP similarity, sim_best = 0.829 (> 0.100 thold), f_keep = 1.000
2026-05-16 22:47:08.614 | reasoning-budget: activated, budget=2147483647 tokens
2026-05-16 22:47:08.614 | slot launch_slot_: id  2 | task -1 | sampler chain: logits -> penalties -> ?dry -> ?top-n-sigma -> top-k -> ?typical -> ?top-p -> min-p -> ?xtc -> ?temp-ext -> dist 
2026-05-16 22:47:08.614 | slot launch_slot_: id  2 | task 2155 | processing task, is_child = 0
2026-05-16 22:47:08.614 | slot update_slots: id  2 | task 2155 | new prompt, n_ctx_slot = 131072, n_keep = 0, task.n_tokens = 18285
2026-05-16 22:47:08.614 | slot update_slots: id  2 | task 2155 | n_tokens = 15160, memory_seq_rm [15160, end)
2026-05-16 22:47:08.614 | slot update_slots: id  2 | task 2155 | prompt processing progress, n_tokens = 17208, batch.n_tokens = 2048, progress = 0.941099
2026-05-16 22:47:09.422 | slot update_slots: id  2 | task 2155 | n_tokens = 17208, memory_seq_rm [17208, end)
2026-05-16 22:47:09.422 | slot update_slots: id  2 | task 2155 | prompt processing progress, n_tokens = 17769, batch.n_tokens = 561, progress = 0.971780
2026-05-16 22:47:09.682 | slot update_slots: id  2 | task 2155 | n_tokens = 17769, memory_seq_rm [17769, end)
2026-05-16 22:47:09.682 | slot update_slots: id  2 | task 2155 | prompt processing progress, n_tokens = 18281, batch.n_tokens = 512, progress = 0.999781
2026-05-16 22:47:09.893 | slot create_check: id  2 | task 2155 | created context checkpoint 9 of 32 (pos_min = 17768, pos_max = 17768, n_tokens = 17769, size = 186.839 MiB)
2026-05-16 22:47:10.095 | slot update_slots: id  2 | task 2155 | n_tokens = 18281, memory_seq_rm [18281, end)
2026-05-16 22:47:10.097 | slot init_sampler: id  2 | task 2155 | init sampler, took 2.52 ms, tokens: text = 18285, total = 18285
2026-05-16 22:47:10.097 | slot update_slots: id  2 | task 2155 | prompt processing done, n_tokens = 18285, batch.n_tokens = 4
2026-05-16 22:47:10.310 | slot create_check: id  2 | task 2155 | created context checkpoint 10 of 32 (pos_min = 18280, pos_max = 18280, n_tokens = 18281, size = 187.911 MiB)
2026-05-16 22:47:10.345 | srv  log_server_r: done request: POST /v1/chat/completions 172.18.0.1 200
2026-05-16 22:47:14.728 | reasoning-budget: deactivated (natural end)
2026-05-16 22:47:19.640 | slot print_timing: id  2 | task 2155 | 
2026-05-16 22:47:19.640 | prompt eval time =    1730.53 ms /  3125 tokens (    0.55 ms per token,  1805.80 tokens per second)
2026-05-16 22:47:19.640 |        eval time =    9295.11 ms /   561 tokens (   16.57 ms per token,    60.35 tokens per second)
2026-05-16 22:47:19.640 |       total time =   11025.64 ms /  3686 tokens
2026-05-16 22:47:19.640 | draft acceptance rate = 0.97799 (  311 accepted /   318 generated)
2026-05-16 22:47:19.640 | statistics mtp: #calls(b,g,a) = 18 2272 2337, #gen drafts = 2337, #acc drafts = 2337, #gen tokens = 4154, #acc tokens = 4087, dur(b,g,a) = 0.030, 9106.298, 1.026 ms
2026-05-16 22:47:19.640 | slot      release: id  2 | task 2155 | stop processing: n_tokens = 18845, truncated = 0
2026-05-16 22:47:19.640 | srv  update_slots: all slots are idle
2026-05-16 22:49:02.993 | srv  params_from_: Chat format: peg-native
2026-05-16 22:49:02.996 | slot get_availabl: id  2 | task -1 | selected slot by LCP similarity, sim_best = 0.681 (> 0.100 thold), f_keep = 0.656
2026-05-16 22:49:02.997 | reasoning-budget: activated, budget=2147483647 tokens
2026-05-16 22:49:02.997 | slot launch_slot_: id  2 | task -1 | sampler chain: logits -> penalties -> ?dry -> ?top-n-sigma -> top-k -> ?typical -> ?top-p -> min-p -> ?xtc -> ?temp-ext -> dist 
2026-05-16 22:49:02.997 | slot launch_slot_: id  2 | task 2436 | processing task, is_child = 0
2026-05-16 22:49:02.997 | slot update_slots: id  2 | task 2436 | new prompt, n_ctx_slot = 131072, n_keep = 0, task.n_tokens = 18136
2026-05-16 22:49:02.997 | slot update_slots: id  2 | task 2436 | n_past = 12353, slot.prompt.tokens.size() = 18845, seq_id = 2, pos_min = 18844, n_swa = 0
2026-05-16 22:49:02.997 | slot update_slots: id  2 | task 2436 | Checking checkpoint with [18280, 18280] against 12353...
2026-05-16 22:49:02.997 | slot update_slots: id  2 | task 2436 | Checking checkpoint with [17768, 17768] against 12353...
2026-05-16 22:49:02.997 | slot update_slots: id  2 | task 2436 | Checking checkpoint with [14962, 14962] against 12353...
2026-05-16 22:49:02.997 | slot update_slots: id  2 | task 2436 | Checking checkpoint with [14617, 14617] against 12353...
2026-05-16 22:49:02.997 | slot update_slots: id  2 | task 2436 | Checking checkpoint with [14105, 14105] against 12353...
2026-05-16 22:49:02.997 | slot update_slots: id  2 | task 2436 | Checking checkpoint with [13195, 13195] against 12353...
2026-05-16 22:49:02.997 | slot update_slots: id  2 | task 2436 | Checking checkpoint with [12948, 12948] against 12353...
2026-05-16 22:49:02.997 | slot update_slots: id  2 | task 2436 | Checking checkpoint with [12663, 12663] against 12353...
2026-05-16 22:49:02.997 | slot update_slots: id  2 | task 2436 | Checking checkpoint with [12151, 12151] against 12353...
2026-05-16 22:49:03.064 | slot update_slots: id  2 | task 2436 | restored context checkpoint (pos_min = 12151, pos_max = 12151, n_tokens = 12152, n_past = 12152, size = 175.076 MiB)
2026-05-16 22:49:03.064 | slot update_slots: id  2 | task 2436 | erased invalidated context checkpoint (pos_min = 12663, pos_max = 12663, n_tokens = 12664, n_swa = 0, pos_next = 12152, size = 176.148 MiB)
2026-05-16 22:49:03.073 | slot update_slots: id  2 | task 2436 | erased invalidated context checkpoint (pos_min = 12948, pos_max = 12948, n_tokens = 12949, n_swa = 0, pos_next = 12152, size = 176.745 MiB)
2026-05-16 22:49:03.083 | slot update_slots: id  2 | task 2436 | erased invalidated context checkpoint (pos_min = 13195, pos_max = 13195, n_tokens = 13196, n_swa = 0, pos_next = 12152, size = 177.262 MiB)
2026-05-16 22:49:03.093 | slot update_slots: id  2 | task 2436 | erased invalidated context checkpoint (pos_min = 14105, pos_max = 14105, n_tokens = 14106, n_swa = 0, pos_next = 12152, size = 179.168 MiB)
2026-05-16 22:49:03.103 | slot update_slots: id  2 | task 2436 | erased invalidated context checkpoint (pos_min = 14617, pos_max = 14617, n_tokens = 14618, n_swa = 0, pos_next = 12152, size = 180.240 MiB)
2026-05-16 22:49:03.113 | slot update_slots: id  2 | task 2436 | erased invalidated context checkpoint (pos_min = 14962, pos_max = 14962, n_tokens = 14963, n_swa = 0, pos_next = 12152, size = 180.963 MiB)
2026-05-16 22:49:03.124 | slot update_slots: id  2 | task 2436 | erased invalidated context checkpoint (pos_min = 17768, pos_max = 17768, n_tokens = 17769, n_swa = 0, pos_next = 12152, size = 186.839 MiB)
2026-05-16 22:49:03.135 | slot update_slots: id  2 | task 2436 | erased invalidated context checkpoint (pos_min = 18280, pos_max = 18280, n_tokens = 18281, n_swa = 0, pos_next = 12152, size = 187.911 MiB)
2026-05-16 22:49:03.145 | slot update_slots: id  2 | task 2436 | n_tokens = 12152, memory_seq_rm [12152, end)
2026-05-16 22:49:03.146 | slot update_slots: id  2 | task 2436 | prompt processing progress, n_tokens = 14200, batch.n_tokens = 2048, progress = 0.782973
2026-05-16 22:49:03.268 | slot update_slots: id  2 | task 2436 | n_tokens = 14200, memory_seq_rm [14200, end)
2026-05-16 22:49:03.268 | slot update_slots: id  2 | task 2436 | prompt processing progress, n_tokens = 16248, batch.n_tokens = 2048, progress = 0.895898
2026-05-16 22:49:04.064 | slot update_slots: id  2 | task 2436 | n_tokens = 16248, memory_seq_rm [16248, end)
2026-05-16 22:49:04.064 | slot update_slots: id  2 | task 2436 | prompt processing progress, n_tokens = 17620, batch.n_tokens = 1372, progress = 0.971548
2026-05-16 22:49:04.624 | slot update_slots: id  2 | task 2436 | n_tokens = 17620, memory_seq_rm [17620, end)
2026-05-16 22:49:04.624 | slot update_slots: id  2 | task 2436 | prompt processing progress, n_tokens = 18132, batch.n_tokens = 512, progress = 0.999779
2026-05-16 22:49:04.800 | slot create_check: id  2 | task 2436 | created context checkpoint 3 of 32 (pos_min = 17619, pos_max = 17619, n_tokens = 17620, size = 186.527 MiB)
2026-05-16 22:49:05.002 | slot update_slots: id  2 | task 2436 | n_tokens = 18132, memory_seq_rm [18132, end)
2026-05-16 22:49:05.005 | slot init_sampler: id  2 | task 2436 | init sampler, took 2.49 ms, tokens: text = 18136, total = 18136
2026-05-16 22:49:05.005 | slot update_slots: id  2 | task 2436 | prompt processing done, n_tokens = 18136, batch.n_tokens = 4
2026-05-16 22:49:05.222 | slot create_check: id  2 | task 2436 | created context checkpoint 4 of 32 (pos_min = 18131, pos_max = 18131, n_tokens = 18132, size = 187.599 MiB)
2026-05-16 22:49:05.257 | srv  log_server_r: done request: POST /v1/chat/completions 172.18.0.1 200
2026-05-16 22:49:11.308 | reasoning-budget: deactivated (natural end)
2026-05-16 22:49:13.883 | slot print_timing: id  2 | task 2436 | 
2026-05-16 22:49:13.883 | prompt eval time =    3129.21 ms /  5984 tokens (    0.52 ms per token,  1912.30 tokens per second)
2026-05-16 22:49:13.883 |        eval time =    8625.84 ms /   484 tokens (   17.82 ms per token,    56.11 tokens per second)
2026-05-16 22:49:13.883 |       total time =   11755.05 ms /  6468 tokens
2026-05-16 22:49:13.883 | draft acceptance rate = 0.97297 (  252 accepted /   259 generated)
2026-05-16 22:49:13.883 | statistics mtp: #calls(b,g,a) = 19 2503 2492, #gen drafts = 2492, #acc drafts = 2492, #gen tokens = 4413, #acc tokens = 4339, dur(b,g,a) = 0.032, 9921.885, 1.108 ms
2026-05-16 22:49:13.883 | slot      release: id  2 | task 2436 | stop processing: n_tokens = 18619, truncated = 0
2026-05-16 22:49:13.883 | srv  update_slots: all slots are idle
2026-05-16 22:49:14.105 | srv  params_from_: Chat format: peg-native
2026-05-16 22:49:14.108 | slot get_availabl: id  2 | task -1 | selected slot by LCP similarity, sim_best = 0.807 (> 0.100 thold), f_keep = 1.000
2026-05-16 22:49:14.109 | reasoning-budget: activated, budget=2147483647 tokens
2026-05-16 22:49:14.109 | slot launch_slot_: id  2 | task -1 | sampler chain: logits -> penalties -> ?dry -> ?top-n-sigma -> top-k -> ?typical -> ?top-p -> min-p -> ?xtc -> ?temp-ext -> dist 
2026-05-16 22:49:14.109 | slot launch_slot_: id  2 | task 2693 | processing task, is_child = 0
2026-05-16 22:49:14.109 | slot update_slots: id  2 | task 2693 | new prompt, n_ctx_slot = 131072, n_keep = 0, task.n_tokens = 23075
2026-05-16 22:49:14.109 | slot update_slots: id  2 | task 2693 | n_tokens = 18619, memory_seq_rm [18619, end)
2026-05-16 22:49:14.109 | slot update_slots: id  2 | task 2693 | prompt processing progress, n_tokens = 20667, batch.n_tokens = 2048, progress = 0.895645
2026-05-16 22:49:14.931 | slot update_slots: id  2 | task 2693 | n_tokens = 20667, memory_seq_rm [20667, end)
2026-05-16 22:49:14.931 | slot update_slots: id  2 | task 2693 | prompt processing progress, n_tokens = 22559, batch.n_tokens = 1892, progress = 0.977638
2026-05-16 22:49:15.719 | slot update_slots: id  2 | task 2693 | n_tokens = 22559, memory_seq_rm [22559, end)
2026-05-16 22:49:15.720 | slot update_slots: id  2 | task 2693 | prompt processing progress, n_tokens = 23071, batch.n_tokens = 512, progress = 0.999827
2026-05-16 22:49:15.940 | slot create_check: id  2 | task 2693 | created context checkpoint 5 of 32 (pos_min = 22558, pos_max = 22558, n_tokens = 22559, size = 196.871 MiB)
2026-05-16 22:49:16.151 | slot update_slots: id  2 | task 2693 | n_tokens = 23071, memory_seq_rm [23071, end)
2026-05-16 22:49:16.155 | slot init_sampler: id  2 | task 2693 | init sampler, took 3.06 ms, tokens: text = 23075, total = 23075
2026-05-16 22:49:16.155 | slot update_slots: id  2 | task 2693 | prompt processing done, n_tokens = 23075, batch.n_tokens = 4
2026-05-16 22:49:16.382 | slot create_check: id  2 | task 2693 | created context checkpoint 6 of 32 (pos_min = 23070, pos_max = 23070, n_tokens = 23071, size = 197.943 MiB)
2026-05-16 22:49:16.418 | srv  log_server_r: done request: POST /v1/chat/completions 172.18.0.1 200
2026-05-16 22:49:22.093 | reasoning-budget: deactivated (natural end)
2026-05-16 22:49:24.150 | slot print_timing: id  2 | task 2693 | 
2026-05-16 22:49:24.150 | prompt eval time =    2308.23 ms /  4456 tokens (    0.52 ms per token,  1930.48 tokens per second)
2026-05-16 22:49:24.150 |        eval time =    7732.13 ms /   439 tokens (   17.61 ms per token,    56.78 tokens per second)
2026-05-16 22:49:24.150 |       total time =   10040.36 ms /  4895 tokens
2026-05-16 22:49:24.150 | draft acceptance rate = 0.98214 (  220 accepted /   224 generated)
2026-05-16 22:49:24.150 | statistics mtp: #calls(b,g,a) = 20 2721 2631, #gen drafts = 2631, #acc drafts = 2631, #gen tokens = 4637, #acc tokens = 4559, dur(b,g,a) = 0.033, 10662.465, 1.192 ms
2026-05-16 22:49:24.150 | slot      release: id  2 | task 2693 | stop processing: n_tokens = 23513, truncated = 0
2026-05-16 22:49:24.150 | srv  update_slots: all slots are idle
2026-05-16 22:49:24.353 | srv  params_from_: Chat format: peg-native
2026-05-16 22:49:24.355 | slot get_availabl: id  2 | task -1 | selected slot by LCP similarity, sim_best = 0.989 (> 0.100 thold), f_keep = 1.000
2026-05-16 22:49:24.356 | reasoning-budget: activated, budget=2147483647 tokens
2026-05-16 22:49:24.357 | slot launch_slot_: id  2 | task -1 | sampler chain: logits -> penalties -> ?dry -> ?top-n-sigma -> top-k -> ?typical -> ?top-p -> min-p -> ?xtc -> ?temp-ext -> dist 
2026-05-16 22:49:24.357 | slot launch_slot_: id  2 | task 2930 | processing task, is_child = 0
2026-05-16 22:49:24.357 | slot update_slots: id  2 | task 2930 | new prompt, n_ctx_slot = 131072, n_keep = 0, task.n_tokens = 23778
2026-05-16 22:49:24.357 | slot update_slots: id  2 | task 2930 | n_tokens = 23513, memory_seq_rm [23513, end)
2026-05-16 22:49:24.357 | slot update_slots: id  2 | task 2930 | prompt processing progress, n_tokens = 23774, batch.n_tokens = 261, progress = 0.999832
2026-05-16 22:49:24.580 | slot create_check: id  2 | task 2930 | created context checkpoint 7 of 32 (pos_min = 23512, pos_max = 23512, n_tokens = 23513, size = 198.869 MiB)
2026-05-16 22:49:24.707 | slot update_slots: id  2 | task 2930 | n_tokens = 23774, memory_seq_rm [23774, end)
2026-05-16 22:49:24.710 | slot init_sampler: id  2 | task 2930 | init sampler, took 3.23 ms, tokens: text = 23778, total = 23778
2026-05-16 22:49:24.710 | slot update_slots: id  2 | task 2930 | prompt processing done, n_tokens = 23778, batch.n_tokens = 4
2026-05-16 22:49:24.936 | slot create_check: id  2 | task 2930 | created context checkpoint 8 of 32 (pos_min = 23773, pos_max = 23773, n_tokens = 23774, size = 199.415 MiB)
2026-05-16 22:49:24.970 | srv  log_server_r: done request: POST /v1/chat/completions 172.18.0.1 200
2026-05-16 22:49:30.010 | reasoning-budget: deactivated (natural end)
2026-05-16 22:49:31.968 | slot print_timing: id  2 | task 2930 | 
2026-05-16 22:49:31.968 | prompt eval time =     613.42 ms /   265 tokens (    2.31 ms per token,   432.00 tokens per second)
2026-05-16 22:49:31.968 |        eval time =    7859.23 ms /   432 tokens (   18.19 ms per token,    54.97 tokens per second)
2026-05-16 22:49:31.968 |       total time =    8472.65 ms /   697 tokens
2026-05-16 22:49:31.968 | draft acceptance rate = 0.97727 (  215 accepted /   220 generated)
2026-05-16 22:49:31.968 | statistics mtp: #calls(b,g,a) = 21 2937 2768, #gen drafts = 2768, #acc drafts = 2768, #gen tokens = 4857, #acc tokens = 4774, dur(b,g,a) = 0.034, 11406.817, 1.258 ms
2026-05-16 22:49:31.969 | slot      release: id  2 | task 2930 | stop processing: n_tokens = 24209, truncated = 0
2026-05-16 22:49:31.969 | srv  update_slots: all slots are idle
2026-05-16 22:49:32.227 | srv  params_from_: Chat format: peg-native
2026-05-16 22:49:32.230 | slot get_availabl: id  2 | task -1 | selected slot by LCP similarity, sim_best = 0.980 (> 0.100 thold), f_keep = 1.000
2026-05-16 22:49:32.231 | reasoning-budget: activated, budget=2147483647 tokens
2026-05-16 22:49:32.231 | slot launch_slot_: id  2 | task -1 | sampler chain: logits -> penalties -> ?dry -> ?top-n-sigma -> top-k -> ?typical -> ?top-p -> min-p -> ?xtc -> ?temp-ext -> dist 
2026-05-16 22:49:32.231 | slot launch_slot_: id  2 | task 3163 | processing task, is_child = 0
2026-05-16 22:49:32.231 | slot update_slots: id  2 | task 3163 | new prompt, n_ctx_slot = 131072, n_keep = 0, task.n_tokens = 24692
2026-05-16 22:49:32.231 | slot update_slots: id  2 | task 3163 | n_tokens = 24209, memory_seq_rm [24209, end)
2026-05-16 22:49:32.231 | slot update_slots: id  2 | task 3163 | prompt processing progress, n_tokens = 24688, batch.n_tokens = 479, progress = 0.999838
2026-05-16 22:49:32.456 | slot create_check: id  2 | task 3163 | created context checkpoint 9 of 32 (pos_min = 24208, pos_max = 24208, n_tokens = 24209, size = 200.326 MiB)
2026-05-16 22:49:32.664 | slot update_slots: id  2 | task 3163 | n_tokens = 24688, memory_seq_rm [24688, end)
2026-05-16 22:49:32.667 | slot init_sampler: id  2 | task 3163 | init sampler, took 3.27 ms, tokens: text = 24692, total = 24692
2026-05-16 22:49:32.667 | slot update_slots: id  2 | task 3163 | prompt processing done, n_tokens = 24692, batch.n_tokens = 4
2026-05-16 22:49:32.826 | slot create_check: id  2 | task 3163 | created context checkpoint 10 of 32 (pos_min = 24687, pos_max = 24687, n_tokens = 24688, size = 201.329 MiB)
2026-05-16 22:49:32.861 | srv  log_server_r: done request: POST /v1/chat/completions 172.18.0.1 200
2026-05-16 22:49:34.588 | reasoning-budget: deactivated (natural end)
2026-05-16 22:49:36.973 | slot print_timing: id  2 | task 3163 | 
2026-05-16 22:49:36.973 | prompt eval time =     629.44 ms /   483 tokens (    1.30 ms per token,   767.35 tokens per second)
2026-05-16 22:49:36.973 |        eval time =    4112.70 ms /   241 tokens (   17.07 ms per token,    58.60 tokens per second)
2026-05-16 22:49:36.973 |       total time =    4742.14 ms /   724 tokens
2026-05-16 22:49:36.973 | draft acceptance rate = 0.98507 (  132 accepted /   134 generated)
2026-05-16 22:49:36.973 | statistics mtp: #calls(b,g,a) = 22 3045 2848, #gen drafts = 2848, #acc drafts = 2848, #gen tokens = 4991, #acc tokens = 4906, dur(b,g,a) = 0.036, 11807.688, 1.303 ms
2026-05-16 22:49:36.974 | slot      release: id  2 | task 3163 | stop processing: n_tokens = 24932, truncated = 0
2026-05-16 22:49:36.974 | srv  update_slots: all slots are idle
2026-05-16 22:51:37.837 | srv  params_from_: Chat format: peg-native
2026-05-16 22:51:37.840 | slot get_availabl: id  2 | task -1 | selected slot by LCP similarity, sim_best = 0.742 (> 0.100 thold), f_keep = 0.715
2026-05-16 22:51:37.841 | reasoning-budget: activated, budget=2147483647 tokens
2026-05-16 22:51:37.841 | slot launch_slot_: id  2 | task -1 | sampler chain: logits -> penalties -> ?dry -> ?top-n-sigma -> top-k -> ?typical -> ?top-p -> min-p -> ?xtc -> ?temp-ext -> dist 
2026-05-16 22:51:37.841 | slot launch_slot_: id  2 | task 3286 | processing task, is_child = 0
2026-05-16 22:51:37.841 | slot update_slots: id  2 | task 3286 | new prompt, n_ctx_slot = 131072, n_keep = 0, task.n_tokens = 24033
2026-05-16 22:51:37.841 | slot update_slots: id  2 | task 3286 | n_past = 17821, slot.prompt.tokens.size() = 24932, seq_id = 2, pos_min = 24931, n_swa = 0
2026-05-16 22:51:37.841 | slot update_slots: id  2 | task 3286 | Checking checkpoint with [24687, 24687] against 17821...
2026-05-16 22:51:37.841 | slot update_slots: id  2 | task 3286 | Checking checkpoint with [24208, 24208] against 17821...
2026-05-16 22:51:37.841 | slot update_slots: id  2 | task 3286 | Checking checkpoint with [23773, 23773] against 17821...
2026-05-16 22:51:37.841 | slot update_slots: id  2 | task 3286 | Checking checkpoint with [23512, 23512] against 17821...
2026-05-16 22:51:37.841 | slot update_slots: id  2 | task 3286 | Checking checkpoint with [23070, 23070] against 17821...
2026-05-16 22:51:37.841 | slot update_slots: id  2 | task 3286 | Checking checkpoint with [22558, 22558] against 17821...
2026-05-16 22:51:37.841 | slot update_slots: id  2 | task 3286 | Checking checkpoint with [18131, 18131] against 17821...
2026-05-16 22:51:37.841 | slot update_slots: id  2 | task 3286 | Checking checkpoint with [17619, 17619] against 17821...
2026-05-16 22:51:37.916 | slot update_slots: id  2 | task 3286 | restored context checkpoint (pos_min = 17619, pos_max = 17619, n_tokens = 17620, n_past = 17620, size = 186.527 MiB)
2026-05-16 22:51:37.916 | slot update_slots: id  2 | task 3286 | erased invalidated context checkpoint (pos_min = 18131, pos_max = 18131, n_tokens = 18132, n_swa = 0, pos_next = 17620, size = 187.599 MiB)
2026-05-16 22:51:37.927 | slot update_slots: id  2 | task 3286 | erased invalidated context checkpoint (pos_min = 22558, pos_max = 22558, n_tokens = 22559, n_swa = 0, pos_next = 17620, size = 196.871 MiB)
2026-05-16 22:51:37.938 | slot update_slots: id  2 | task 3286 | erased invalidated context checkpoint (pos_min = 23070, pos_max = 23070, n_tokens = 23071, n_swa = 0, pos_next = 17620, size = 197.943 MiB)
2026-05-16 22:51:37.950 | slot update_slots: id  2 | task 3286 | erased invalidated context checkpoint (pos_min = 23512, pos_max = 23512, n_tokens = 23513, n_swa = 0, pos_next = 17620, size = 198.869 MiB)
2026-05-16 22:51:37.961 | slot update_slots: id  2 | task 3286 | erased invalidated context checkpoint (pos_min = 23773, pos_max = 23773, n_tokens = 23774, n_swa = 0, pos_next = 17620, size = 199.415 MiB)
2026-05-16 22:51:37.972 | slot update_slots: id  2 | task 3286 | erased invalidated context checkpoint (pos_min = 24208, pos_max = 24208, n_tokens = 24209, n_swa = 0, pos_next = 17620, size = 200.326 MiB)
2026-05-16 22:51:37.984 | slot update_slots: id  2 | task 3286 | erased invalidated context checkpoint (pos_min = 24687, pos_max = 24687, n_tokens = 24688, n_swa = 0, pos_next = 17620, size = 201.329 MiB)
2026-05-16 22:51:37.996 | slot update_slots: id  2 | task 3286 | n_tokens = 17620, memory_seq_rm [17620, end)
2026-05-16 22:51:37.997 | slot update_slots: id  2 | task 3286 | prompt processing progress, n_tokens = 19668, batch.n_tokens = 2048, progress = 0.818375
2026-05-16 22:51:39.044 | slot update_slots: id  2 | task 3286 | n_tokens = 19668, memory_seq_rm [19668, end)
2026-05-16 22:51:39.044 | slot update_slots: id  2 | task 3286 | prompt processing progress, n_tokens = 21716, batch.n_tokens = 2048, progress = 0.903591
2026-05-16 22:51:39.875 | slot update_slots: id  2 | task 3286 | n_tokens = 21716, memory_seq_rm [21716, end)
2026-05-16 22:51:39.875 | slot update_slots: id  2 | task 3286 | prompt processing progress, n_tokens = 23517, batch.n_tokens = 1801, progress = 0.978530
2026-05-16 22:51:40.637 | slot update_slots: id  2 | task 3286 | n_tokens = 23517, memory_seq_rm [23517, end)
2026-05-16 22:51:40.637 | slot update_slots: id  2 | task 3286 | prompt processing progress, n_tokens = 24029, batch.n_tokens = 512, progress = 0.999834
2026-05-16 22:51:40.798 | slot create_check: id  2 | task 3286 | created context checkpoint 4 of 32 (pos_min = 23516, pos_max = 23516, n_tokens = 23517, size = 198.877 MiB)
2026-05-16 22:51:41.012 | slot update_slots: id  2 | task 3286 | n_tokens = 24029, memory_seq_rm [24029, end)
2026-05-16 22:51:41.015 | slot init_sampler: id  2 | task 3286 | init sampler, took 3.16 ms, tokens: text = 24033, total = 24033
2026-05-16 22:51:41.015 | slot update_slots: id  2 | task 3286 | prompt processing done, n_tokens = 24033, batch.n_tokens = 4
2026-05-16 22:51:41.249 | slot create_check: id  2 | task 3286 | created context checkpoint 5 of 32 (pos_min = 24028, pos_max = 24028, n_tokens = 24029, size = 199.949 MiB)
2026-05-16 22:51:41.285 | srv  log_server_r: done request: POST /v1/chat/completions 172.18.0.1 200
2026-05-16 22:51:49.281 | reasoning-budget: deactivated (natural end)
2026-05-16 22:51:53.356 | slot print_timing: id  2 | task 3286 | 
2026-05-16 22:51:53.356 | prompt eval time =    3443.77 ms /  6413 tokens (    0.54 ms per token,  1862.20 tokens per second)
2026-05-16 22:51:53.356 |        eval time =   12070.54 ms /   607 tokens (   19.89 ms per token,    50.29 tokens per second)
2026-05-16 22:51:53.356 |       total time =   15514.31 ms /  7020 tokens
2026-05-16 22:51:53.356 | draft acceptance rate = 0.97810 (  268 accepted /   274 generated)
2026-05-16 22:51:53.356 | statistics mtp: #calls(b,g,a) = 23 3383 3027, #gen drafts = 3027, #acc drafts = 3027, #gen tokens = 5265, #acc tokens = 5174, dur(b,g,a) = 0.037, 12881.958, 1.414 ms
2026-05-16 22:51:53.356 | slot      release: id  2 | task 3286 | stop processing: n_tokens = 24639, truncated = 0
2026-05-16 22:51:53.356 | srv  update_slots: all slots are idle
2026-05-16 22:52:35.023 | srv  params_from_: Chat format: peg-native
2026-05-16 22:52:35.025 | slot get_availabl: id  2 | task -1 | selected slot by LCP similarity, sim_best = 0.961 (> 0.100 thold), f_keep = 0.963
2026-05-16 22:52:35.027 | reasoning-budget: activated, budget=2147483647 tokens
2026-05-16 22:52:35.027 | slot launch_slot_: id  2 | task -1 | sampler chain: logits -> penalties -> ?dry -> ?top-n-sigma -> top-k -> ?typical -> ?top-p -> min-p -> ?xtc -> ?temp-ext -> dist 
2026-05-16 22:52:35.027 | slot launch_slot_: id  2 | task 3657 | processing task, is_child = 0
2026-05-16 22:52:35.027 | slot update_slots: id  2 | task 3657 | new prompt, n_ctx_slot = 131072, n_keep = 0, task.n_tokens = 24692
2026-05-16 22:52:35.027 | slot update_slots: id  2 | task 3657 | n_past = 23718, slot.prompt.tokens.size() = 24639, seq_id = 2, pos_min = 24638, n_swa = 0
2026-05-16 22:52:35.027 | slot update_slots: id  2 | task 3657 | Checking checkpoint with [24028, 24028] against 23718...
2026-05-16 22:52:35.027 | slot update_slots: id  2 | task 3657 | Checking checkpoint with [23516, 23516] against 23718...
2026-05-16 22:52:35.104 | slot update_slots: id  2 | task 3657 | restored context checkpoint (pos_min = 23516, pos_max = 23516, n_tokens = 23517, n_past = 23517, size = 198.877 MiB)
2026-05-16 22:52:35.104 | slot update_slots: id  2 | task 3657 | erased invalidated context checkpoint (pos_min = 24028, pos_max = 24028, n_tokens = 24029, n_swa = 0, pos_next = 23517, size = 199.949 MiB)
2026-05-16 22:52:35.115 | slot update_slots: id  2 | task 3657 | n_tokens = 23517, memory_seq_rm [23517, end)
2026-05-16 22:52:35.116 | slot update_slots: id  2 | task 3657 | prompt processing progress, n_tokens = 24176, batch.n_tokens = 659, progress = 0.979103
2026-05-16 22:52:35.658 | slot update_slots: id  2 | task 3657 | n_tokens = 24176, memory_seq_rm [24176, end)
2026-05-16 22:52:35.658 | slot update_slots: id  2 | task 3657 | prompt processing progress, n_tokens = 24688, batch.n_tokens = 512, progress = 0.999838
2026-05-16 22:52:35.827 | slot create_check: id  2 | task 3657 | created context checkpoint 5 of 32 (pos_min = 24175, pos_max = 24175, n_tokens = 24176, size = 200.257 MiB)
2026-05-16 22:52:36.041 | slot update_slots: id  2 | task 3657 | n_tokens = 24688, memory_seq_rm [24688, end)
2026-05-16 22:52:36.044 | slot init_sampler: id  2 | task 3657 | init sampler, took 3.16 ms, tokens: text = 24692, total = 24692
2026-05-16 22:52:36.044 | slot update_slots: id  2 | task 3657 | prompt processing done, n_tokens = 24692, batch.n_tokens = 4
2026-05-16 22:52:36.246 | slot create_check: id  2 | task 3657 | created context checkpoint 6 of 32 (pos_min = 24687, pos_max = 24687, n_tokens = 24688, size = 201.329 MiB)
2026-05-16 22:52:36.281 | srv  log_server_r: done request: POST /v1/chat/completions 172.18.0.1 200
2026-05-16 22:52:42.064 | reasoning-budget: deactivated (natural end)
2026-05-16 22:52:46.335 | slot print_timing: id  2 | task 3657 | 
2026-05-16 22:52:46.335 | prompt eval time =    1253.65 ms /  1175 tokens (    1.07 ms per token,   937.26 tokens per second)
2026-05-16 22:52:46.335 |        eval time =   10054.61 ms /   556 tokens (   18.08 ms per token,    55.30 tokens per second)
2026-05-16 22:52:46.335 |       total time =   11308.26 ms /  1731 tokens
2026-05-16 22:52:46.335 | draft acceptance rate = 0.97482 (  271 accepted /   278 generated)
2026-05-16 22:52:46.335 | statistics mtp: #calls(b,g,a) = 24 3667 3193, #gen drafts = 3193, #acc drafts = 3193, #gen tokens = 5543, #acc tokens = 5445, dur(b,g,a) = 0.038, 13828.411, 1.502 ms
2026-05-16 22:52:46.336 | slot      release: id  2 | task 3657 | stop processing: n_tokens = 25247, truncated = 0
2026-05-16 22:52:46.336 | srv  update_slots: all slots are idle
2026-05-16 22:54:12.835 | srv  params_from_: Chat format: peg-native
2026-05-16 22:54:12.838 | slot get_availabl: id  2 | task -1 | selected slot by LCP similarity, sim_best = 0.956 (> 0.100 thold), f_keep = 0.966
2026-05-16 22:54:12.839 | reasoning-budget: activated, budget=2147483647 tokens
2026-05-16 22:54:12.839 | slot launch_slot_: id  2 | task -1 | sampler chain: logits -> penalties -> ?dry -> ?top-n-sigma -> top-k -> ?typical -> ?top-p -> min-p -> ?xtc -> ?temp-ext -> dist 
2026-05-16 22:54:12.839 | slot launch_slot_: id  2 | task 3965 | processing task, is_child = 0
2026-05-16 22:54:12.839 | slot update_slots: id  2 | task 3965 | new prompt, n_ctx_slot = 131072, n_keep = 0, task.n_tokens = 25504
2026-05-16 22:54:12.839 | slot update_slots: id  2 | task 3965 | n_past = 24377, slot.prompt.tokens.size() = 25247, seq_id = 2, pos_min = 25246, n_swa = 0
2026-05-16 22:54:12.839 | slot update_slots: id  2 | task 3965 | Checking checkpoint with [24687, 24687] against 24377...
2026-05-16 22:54:12.839 | slot update_slots: id  2 | task 3965 | Checking checkpoint with [24175, 24175] against 24377...
2026-05-16 22:54:12.915 | slot update_slots: id  2 | task 3965 | restored context checkpoint (pos_min = 24175, pos_max = 24175, n_tokens = 24176, n_past = 24176, size = 200.257 MiB)
2026-05-16 22:54:12.915 | slot update_slots: id  2 | task 3965 | erased invalidated context checkpoint (pos_min = 24687, pos_max = 24687, n_tokens = 24688, n_swa = 0, pos_next = 24176, size = 201.329 MiB)
2026-05-16 22:54:12.926 | slot update_slots: id  2 | task 3965 | n_tokens = 24176, memory_seq_rm [24176, end)
2026-05-16 22:54:12.927 | slot update_slots: id  2 | task 3965 | prompt processing progress, n_tokens = 24988, batch.n_tokens = 812, progress = 0.979768
2026-05-16 22:54:13.458 | slot update_slots: id  2 | task 3965 | n_tokens = 24988, memory_seq_rm [24988, end)
2026-05-16 22:54:13.458 | slot update_slots: id  2 | task 3965 | prompt processing progress, n_tokens = 25500, batch.n_tokens = 512, progress = 0.999843
2026-05-16 22:54:13.611 | slot create_check: id  2 | task 3965 | created context checkpoint 6 of 32 (pos_min = 24987, pos_max = 24987, n_tokens = 24988, size = 201.958 MiB)
2026-05-16 22:54:13.829 | slot update_slots: id  2 | task 3965 | n_tokens = 25500, memory_seq_rm [25500, end)
2026-05-16 22:54:13.832 | slot init_sampler: id  2 | task 3965 | init sampler, took 3.55 ms, tokens: text = 25504, total = 25504
2026-05-16 22:54:13.832 | slot update_slots: id  2 | task 3965 | prompt processing done, n_tokens = 25504, batch.n_tokens = 4
2026-05-16 22:54:14.019 | slot create_check: id  2 | task 3965 | created context checkpoint 7 of 32 (pos_min = 25499, pos_max = 25499, n_tokens = 25500, size = 203.030 MiB)
2026-05-16 22:54:14.054 | srv  log_server_r: done request: POST /v1/chat/completions 172.18.0.1 200
2026-05-16 22:54:14.737 | reasoning-budget: deactivated (natural end)
2026-05-16 22:54:15.235 | slot print_timing: id  2 | task 3965 | 
2026-05-16 22:54:15.235 | prompt eval time =    1213.93 ms /  1328 tokens (    0.91 ms per token,  1093.97 tokens per second)
2026-05-16 22:54:15.235 |        eval time =    1181.68 ms /    94 tokens (   12.57 ms per token,    79.55 tokens per second)
2026-05-16 22:54:15.235 |       total time =    2395.61 ms /  1422 tokens
2026-05-16 22:54:15.235 | draft acceptance rate = 1.00000 (   59 accepted /    59 generated)
2026-05-16 22:54:15.235 | statistics mtp: #calls(b,g,a) = 25 3701 3224, #gen drafts = 3224, #acc drafts = 3224, #gen tokens = 5602, #acc tokens = 5504, dur(b,g,a) = 0.039, 13967.754, 1.514 ms
2026-05-16 22:54:15.236 | slot      release: id  2 | task 3965 | stop processing: n_tokens = 25597, truncated = 0
2026-05-16 22:54:15.236 | srv  update_slots: all slots are idle
2026-05-16 22:54:15.423 | srv  params_from_: Chat format: peg-native
2026-05-16 22:54:15.426 | slot get_availabl: id  2 | task -1 | selected slot by LCP similarity, sim_best = 0.877 (> 0.100 thold), f_keep = 1.000
2026-05-16 22:54:15.427 | reasoning-budget: activated, budget=2147483647 tokens
2026-05-16 22:54:15.427 | slot launch_slot_: id  2 | task -1 | sampler chain: logits -> penalties -> ?dry -> ?top-n-sigma -> top-k -> ?typical -> ?top-p -> min-p -> ?xtc -> ?temp-ext -> dist 
2026-05-16 22:54:15.427 | slot launch_slot_: id  2 | task 4004 | processing task, is_child = 0
2026-05-16 22:54:15.427 | slot update_slots: id  2 | task 4004 | new prompt, n_ctx_slot = 131072, n_keep = 0, task.n_tokens = 29196
2026-05-16 22:54:15.427 | slot update_slots: id  2 | task 4004 | n_tokens = 25597, memory_seq_rm [25597, end)
2026-05-16 22:54:15.427 | slot update_slots: id  2 | task 4004 | prompt processing progress, n_tokens = 27645, batch.n_tokens = 2048, progress = 0.946876
2026-05-16 22:54:16.304 | slot update_slots: id  2 | task 4004 | n_tokens = 27645, memory_seq_rm [27645, end)
2026-05-16 22:54:16.304 | slot update_slots: id  2 | task 4004 | prompt processing progress, n_tokens = 28680, batch.n_tokens = 1035, progress = 0.982326
2026-05-16 22:54:16.796 | slot update_slots: id  2 | task 4004 | n_tokens = 28680, memory_seq_rm [28680, end)
2026-05-16 22:54:16.797 | slot update_slots: id  2 | task 4004 | prompt processing progress, n_tokens = 29192, batch.n_tokens = 512, progress = 0.999863
2026-05-16 22:54:17.026 | slot create_check: id  2 | task 4004 | created context checkpoint 8 of 32 (pos_min = 28679, pos_max = 28679, n_tokens = 28680, size = 209.690 MiB)
2026-05-16 22:54:17.250 | slot update_slots: id  2 | task 4004 | n_tokens = 29192, memory_seq_rm [29192, end)
2026-05-16 22:54:17.254 | slot init_sampler: id  2 | task 4004 | init sampler, took 3.87 ms, tokens: text = 29196, total = 29196
2026-05-16 22:54:17.254 | slot update_slots: id  2 | task 4004 | prompt processing done, n_tokens = 29196, batch.n_tokens = 4
2026-05-16 22:54:17.495 | slot create_check: id  2 | task 4004 | created context checkpoint 9 of 32 (pos_min = 29191, pos_max = 29191, n_tokens = 29192, size = 210.762 MiB)
2026-05-16 22:54:17.531 | srv  log_server_r: done request: POST /v1/chat/completions 172.18.0.1 200
2026-05-16 22:54:21.753 | reasoning-budget: deactivated (natural end)
2026-05-16 22:54:25.875 | slot print_timing: id  2 | task 4004 | 
2026-05-16 22:54:25.876 | prompt eval time =    2103.29 ms /  3599 tokens (    0.58 ms per token,  1711.13 tokens per second)
2026-05-16 22:54:25.876 |        eval time =    9207.00 ms /   488 tokens (   18.87 ms per token,    53.00 tokens per second)
2026-05-16 22:54:25.876 |       total time =   11310.29 ms /  4087 tokens
2026-05-16 22:54:25.876 | draft acceptance rate = 0.97308 (  253 accepted /   260 generated)
2026-05-16 22:54:25.876 | statistics mtp: #calls(b,g,a) = 26 3935 3379, #gen drafts = 3379, #acc drafts = 3379, #gen tokens = 5862, #acc tokens = 5757, dur(b,g,a) = 0.041, 14794.910, 1.590 ms
2026-05-16 22:54:25.876 | slot      release: id  2 | task 4004 | stop processing: n_tokens = 29683, truncated = 0
2026-05-16 22:54:25.876 | srv  update_slots: all slots are idle
2026-05-16 22:55:01.393 | srv  params_from_: Chat format: peg-native
2026-05-16 22:55:01.396 | slot get_availabl: id  2 | task -1 | selected slot by LCP similarity, sim_best = 0.855 (> 0.100 thold), f_keep = 0.849
2026-05-16 22:55:01.397 | reasoning-budget: activated, budget=2147483647 tokens
2026-05-16 22:55:01.398 | slot launch_slot_: id  2 | task -1 | sampler chain: logits -> penalties -> ?dry -> ?top-n-sigma -> top-k -> ?typical -> ?top-p -> min-p -> ?xtc -> ?temp-ext -> dist 
2026-05-16 22:55:01.398 | slot launch_slot_: id  2 | task 4270 | processing task, is_child = 0
2026-05-16 22:55:01.398 | slot update_slots: id  2 | task 4270 | new prompt, n_ctx_slot = 131072, n_keep = 0, task.n_tokens = 29455
2026-05-16 22:55:01.398 | slot update_slots: id  2 | task 4270 | n_past = 25189, slot.prompt.tokens.size() = 29683, seq_id = 2, pos_min = 29682, n_swa = 0
2026-05-16 22:55:01.398 | slot update_slots: id  2 | task 4270 | Checking checkpoint with [29191, 29191] against 25189...
2026-05-16 22:55:01.398 | slot update_slots: id  2 | task 4270 | Checking checkpoint with [28679, 28679] against 25189...
2026-05-16 22:55:01.398 | slot update_slots: id  2 | task 4270 | Checking checkpoint with [25499, 25499] against 25189...
2026-05-16 22:55:01.398 | slot update_slots: id  2 | task 4270 | Checking checkpoint with [24987, 24987] against 25189...
2026-05-16 22:55:01.475 | slot update_slots: id  2 | task 4270 | restored context checkpoint (pos_min = 24987, pos_max = 24987, n_tokens = 24988, n_past = 24988, size = 201.958 MiB)
2026-05-16 22:55:01.475 | slot update_slots: id  2 | task 4270 | erased invalidated context checkpoint (pos_min = 25499, pos_max = 25499, n_tokens = 25500, n_swa = 0, pos_next = 24988, size = 203.030 MiB)
2026-05-16 22:55:01.487 | slot update_slots: id  2 | task 4270 | erased invalidated context checkpoint (pos_min = 28679, pos_max = 28679, n_tokens = 28680, n_swa = 0, pos_next = 24988, size = 209.690 MiB)
2026-05-16 22:55:01.500 | slot update_slots: id  2 | task 4270 | erased invalidated context checkpoint (pos_min = 29191, pos_max = 29191, n_tokens = 29192, n_swa = 0, pos_next = 24988, size = 210.762 MiB)
2026-05-16 22:55:01.512 | slot update_slots: id  2 | task 4270 | n_tokens = 24988, memory_seq_rm [24988, end)
2026-05-16 22:55:01.513 | slot update_slots: id  2 | task 4270 | prompt processing progress, n_tokens = 27036, batch.n_tokens = 2048, progress = 0.917875
2026-05-16 22:55:02.518 | slot update_slots: id  2 | task 4270 | n_tokens = 27036, memory_seq_rm [27036, end)
2026-05-16 22:55:02.518 | slot update_slots: id  2 | task 4270 | prompt processing progress, n_tokens = 28939, batch.n_tokens = 1903, progress = 0.982482
2026-05-16 22:55:03.354 | slot update_slots: id  2 | task 4270 | n_tokens = 28939, memory_seq_rm [28939, end)
2026-05-16 22:55:03.354 | slot update_slots: id  2 | task 4270 | prompt processing progress, n_tokens = 29451, batch.n_tokens = 512, progress = 0.999864
2026-05-16 22:55:03.600 | slot create_check: id  2 | task 4270 | created context checkpoint 7 of 32 (pos_min = 28938, pos_max = 28938, n_tokens = 28939, size = 210.232 MiB)
2026-05-16 22:55:03.826 | slot update_slots: id  2 | task 4270 | n_tokens = 29451, memory_seq_rm [29451, end)
2026-05-16 22:55:03.830 | slot init_sampler: id  2 | task 4270 | init sampler, took 3.80 ms, tokens: text = 29455, total = 29455
2026-05-16 22:55:03.830 | slot update_slots: id  2 | task 4270 | prompt processing done, n_tokens = 29455, batch.n_tokens = 4
2026-05-16 22:55:04.067 | slot create_check: id  2 | task 4270 | created context checkpoint 8 of 32 (pos_min = 29450, pos_max = 29450, n_tokens = 29451, size = 211.304 MiB)
2026-05-16 22:55:04.102 | srv  log_server_r: done request: POST /v1/chat/completions 172.18.0.1 200
2026-05-16 22:55:09.191 | reasoning-budget: deactivated (natural end)
2026-05-16 22:55:12.826 | slot print_timing: id  2 | task 4270 | 
2026-05-16 22:55:12.826 | prompt eval time =    2704.41 ms /  4467 tokens (    0.61 ms per token,  1651.75 tokens per second)
2026-05-16 22:55:12.826 |        eval time =    8723.29 ms /   444 tokens (   19.65 ms per token,    50.90 tokens per second)
2026-05-16 22:55:12.826 |       total time =   11427.70 ms /  4911 tokens
2026-05-16 22:55:12.826 | draft acceptance rate = 0.97285 (  215 accepted /   221 generated)
2026-05-16 22:55:12.826 | statistics mtp: #calls(b,g,a) = 27 4163 3522, #gen drafts = 3522, #acc drafts = 3522, #gen tokens = 6083, #acc tokens = 5972, dur(b,g,a) = 0.043, 15594.900, 1.664 ms
2026-05-16 22:55:12.826 | slot      release: id  2 | task 4270 | stop processing: n_tokens = 29898, truncated = 0
2026-05-16 22:55:12.826 | srv  update_slots: all slots are idle
2026-05-16 22:55:41.642 | srv  params_from_: Chat format: peg-native
2026-05-16 22:55:41.644 | slot get_availabl: id  2 | task -1 | selected slot by LCP similarity, sim_best = 0.990 (> 0.100 thold), f_keep = 0.975
2026-05-16 22:55:41.646 | reasoning-budget: activated, budget=2147483647 tokens
2026-05-16 22:55:41.646 | slot launch_slot_: id  2 | task -1 | sampler chain: logits -> penalties -> ?dry -> ?top-n-sigma -> top-k -> ?typical -> ?top-p -> min-p -> ?xtc -> ?temp-ext -> dist 
2026-05-16 22:55:41.646 | slot launch_slot_: id  2 | task 4526 | processing task, is_child = 0
2026-05-16 22:55:41.646 | slot update_slots: id  2 | task 4526 | new prompt, n_ctx_slot = 131072, n_keep = 0, task.n_tokens = 29420
2026-05-16 22:55:41.646 | slot update_slots: id  2 | task 4526 | n_past = 29140, slot.prompt.tokens.size() = 29898, seq_id = 2, pos_min = 29897, n_swa = 0
2026-05-16 22:55:41.646 | slot update_slots: id  2 | task 4526 | Checking checkpoint with [29450, 29450] against 29140...
2026-05-16 22:55:41.646 | slot update_slots: id  2 | task 4526 | Checking checkpoint with [28938, 28938] against 29140...
2026-05-16 22:55:41.725 | slot update_slots: id  2 | task 4526 | restored context checkpoint (pos_min = 28938, pos_max = 28938, n_tokens = 28939, n_past = 28939, size = 210.232 MiB)
2026-05-16 22:55:41.726 | slot update_slots: id  2 | task 4526 | erased invalidated context checkpoint (pos_min = 29450, pos_max = 29450, n_tokens = 29451, n_swa = 0, pos_next = 28939, size = 211.304 MiB)
2026-05-16 22:55:41.738 | slot update_slots: id  2 | task 4526 | n_tokens = 28939, memory_seq_rm [28939, end)
2026-05-16 22:55:41.738 | slot update_slots: id  2 | task 4526 | prompt processing progress, n_tokens = 29416, batch.n_tokens = 477, progress = 0.999864
2026-05-16 22:55:42.148 | slot update_slots: id  2 | task 4526 | n_tokens = 29416, memory_seq_rm [29416, end)
2026-05-16 22:55:42.152 | slot init_sampler: id  2 | task 4526 | init sampler, took 3.88 ms, tokens: text = 29420, total = 29420
2026-05-16 22:55:42.152 | slot update_slots: id  2 | task 4526 | prompt processing done, n_tokens = 29420, batch.n_tokens = 4
2026-05-16 22:55:42.306 | slot create_check: id  2 | task 4526 | created context checkpoint 8 of 32 (pos_min = 29415, pos_max = 29415, n_tokens = 29416, size = 211.231 MiB)
2026-05-16 22:55:42.342 | srv  log_server_r: done request: POST /v1/chat/completions 172.18.0.1 200
2026-05-16 22:55:43.064 | reasoning-budget: deactivated (natural end)
2026-05-16 22:55:50.727 | slot print_timing: id  2 | task 4526 | 
2026-05-16 22:55:50.727 | prompt eval time =     695.38 ms /   481 tokens (    1.45 ms per token,   691.71 tokens per second)
2026-05-16 22:55:50.727 |        eval time =    9242.42 ms /   719 tokens (   12.85 ms per token,    77.79 tokens per second)
2026-05-16 22:55:50.727 |       total time =    9937.80 ms /  1200 tokens
2026-05-16 22:55:50.727 | draft acceptance rate = 0.99559 (  452 accepted /   454 generated)
2026-05-16 22:55:50.727 | statistics mtp: #calls(b,g,a) = 28 4429 3763, #gen drafts = 3763, #acc drafts = 3763, #gen tokens = 6537, #acc tokens = 6424, dur(b,g,a) = 0.044, 16687.452, 1.799 ms
2026-05-16 22:55:50.728 | slot      release: id  2 | task 4526 | stop processing: n_tokens = 30138, truncated = 0
2026-05-16 22:55:50.728 | srv  update_slots: all slots are idle
2026-05-16 22:55:50.983 | srv  params_from_: Chat format: peg-native
2026-05-16 22:55:50.986 | slot get_availabl: id  2 | task -1 | selected slot by LCP similarity, sim_best = 0.999 (> 0.100 thold), f_keep = 1.000
2026-05-16 22:55:50.987 | reasoning-budget: activated, budget=2147483647 tokens
2026-05-16 22:55:50.987 | slot launch_slot_: id  2 | task -1 | sampler chain: logits -> penalties -> ?dry -> ?top-n-sigma -> top-k -> ?typical -> ?top-p -> min-p -> ?xtc -> ?temp-ext -> dist 
2026-05-16 22:55:50.987 | slot launch_slot_: id  2 | task 4799 | processing task, is_child = 0
2026-05-16 22:55:50.987 | slot update_slots: id  2 | task 4799 | new prompt, n_ctx_slot = 131072, n_keep = 0, task.n_tokens = 30158
2026-05-16 22:55:50.987 | slot update_slots: id  2 | task 4799 | n_tokens = 30138, memory_seq_rm [30138, end)
2026-05-16 22:55:50.988 | slot update_slots: id  2 | task 4799 | prompt processing progress, n_tokens = 30154, batch.n_tokens = 16, progress = 0.999867
2026-05-16 22:55:51.195 | slot create_check: id  2 | task 4799 | created context checkpoint 9 of 32 (pos_min = 30137, pos_max = 30137, n_tokens = 30138, size = 212.743 MiB)
2026-05-16 22:55:51.235 | slot update_slots: id  2 | task 4799 | n_tokens = 30154, memory_seq_rm [30154, end)
2026-05-16 22:55:51.240 | slot init_sampler: id  2 | task 4799 | init sampler, took 4.00 ms, tokens: text = 30158, total = 30158
2026-05-16 22:55:51.240 | slot update_slots: id  2 | task 4799 | prompt processing done, n_tokens = 30158, batch.n_tokens = 4
2026-05-16 22:55:51.276 | srv  log_server_r: done request: POST /v1/chat/completions 172.18.0.1 200
2026-05-16 22:55:51.857 | reasoning-budget: deactivated (natural end)
2026-05-16 22:55:52.505 | slot print_timing: id  2 | task 4799 | 
2026-05-16 22:55:52.505 | prompt eval time =     287.83 ms /    20 tokens (   14.39 ms per token,    69.49 tokens per second)
2026-05-16 22:55:52.505 |        eval time =    1229.09 ms /    54 tokens (   22.76 ms per token,    43.94 tokens per second)
2026-05-16 22:55:52.505 |       total time =    1516.92 ms /    74 tokens
2026-05-16 22:55:52.505 | draft acceptance rate = 0.92000 (   23 accepted /    25 generated)
2026-05-16 22:55:52.505 | statistics mtp: #calls(b,g,a) = 29 4459 3779, #gen drafts = 3779, #acc drafts = 3779, #gen tokens = 6562, #acc tokens = 6447, dur(b,g,a) = 0.046, 16785.402, 1.809 ms
2026-05-16 22:55:52.505 | slot      release: id  2 | task 4799 | stop processing: n_tokens = 30211, truncated = 0
2026-05-16 22:55:52.505 | srv  update_slots: all slots are idle
2026-05-16 22:57:36.660 | srv  params_from_: Chat format: peg-native
2026-05-16 22:57:36.663 | slot get_availabl: id  2 | task -1 | selected slot by LCP similarity, sim_best = 0.972 (> 0.100 thold), f_keep = 0.972
2026-05-16 22:57:36.664 | reasoning-budget: activated, budget=2147483647 tokens
2026-05-16 22:57:36.664 | slot launch_slot_: id  2 | task -1 | sampler chain: logits -> penalties -> ?dry -> ?top-n-sigma -> top-k -> ?typical -> ?top-p -> min-p -> ?xtc -> ?temp-ext -> dist 
2026-05-16 22:57:36.664 | slot launch_slot_: id  2 | task 4839 | processing task, is_child = 0
2026-05-16 22:57:36.664 | slot update_slots: id  2 | task 4839 | new prompt, n_ctx_slot = 131072, n_keep = 0, task.n_tokens = 30196
2026-05-16 22:57:36.664 | slot update_slots: id  2 | task 4839 | n_past = 29358, slot.prompt.tokens.size() = 30211, seq_id = 2, pos_min = 30210, n_swa = 0
2026-05-16 22:57:36.664 | slot update_slots: id  2 | task 4839 | Checking checkpoint with [30137, 30137] against 29358...
2026-05-16 22:57:36.664 | slot update_slots: id  2 | task 4839 | Checking checkpoint with [29415, 29415] against 29358...
2026-05-16 22:57:36.664 | slot update_slots: id  2 | task 4839 | Checking checkpoint with [28938, 28938] against 29358...
2026-05-16 22:57:36.747 | slot update_slots: id  2 | task 4839 | restored context checkpoint (pos_min = 28938, pos_max = 28938, n_tokens = 28939, n_past = 28939, size = 210.232 MiB)
2026-05-16 22:57:36.747 | slot update_slots: id  2 | task 4839 | erased invalidated context checkpoint (pos_min = 29415, pos_max = 29415, n_tokens = 29416, n_swa = 0, pos_next = 28939, size = 211.231 MiB)
2026-05-16 22:57:36.760 | slot update_slots: id  2 | task 4839 | erased invalidated context checkpoint (pos_min = 30137, pos_max = 30137, n_tokens = 30138, n_swa = 0, pos_next = 28939, size = 212.743 MiB)
2026-05-16 22:57:36.772 | slot update_slots: id  2 | task 4839 | n_tokens = 28939, memory_seq_rm [28939, end)
2026-05-16 22:57:36.773 | slot update_slots: id  2 | task 4839 | prompt processing progress, n_tokens = 29680, batch.n_tokens = 741, progress = 0.982912
2026-05-16 22:57:37.253 | slot update_slots: id  2 | task 4839 | n_tokens = 29680, memory_seq_rm [29680, end)
2026-05-16 22:57:37.253 | slot update_slots: id  2 | task 4839 | prompt processing progress, n_tokens = 30192, batch.n_tokens = 512, progress = 0.999868
2026-05-16 22:57:37.412 | slot create_check: id  2 | task 4839 | created context checkpoint 8 of 32 (pos_min = 29679, pos_max = 29679, n_tokens = 29680, size = 211.784 MiB)
2026-05-16 22:57:37.638 | slot update_slots: id  2 | task 4839 | n_tokens = 30192, memory_seq_rm [30192, end)
2026-05-16 22:57:37.642 | slot init_sampler: id  2 | task 4839 | init sampler, took 3.91 ms, tokens: text = 30196, total = 30196
2026-05-16 22:57:37.642 | slot update_slots: id  2 | task 4839 | prompt processing done, n_tokens = 30196, batch.n_tokens = 4
2026-05-16 22:57:37.802 | slot create_check: id  2 | task 4839 | created context checkpoint 9 of 32 (pos_min = 30191, pos_max = 30191, n_tokens = 30192, size = 212.856 MiB)
2026-05-16 22:57:37.840 | srv  log_server_r: done request: POST /v1/chat/completions 172.18.0.1 200
2026-05-16 22:57:38.800 | reasoning-budget: deactivated (natural end)
2026-05-16 22:57:40.500 | slot print_timing: id  2 | task 4839 | 
2026-05-16 22:57:40.500 | prompt eval time =    1175.10 ms /  1257 tokens (    0.93 ms per token,  1069.69 tokens per second)
2026-05-16 22:57:40.500 |        eval time =    2660.93 ms /   193 tokens (   13.79 ms per token,    72.53 tokens per second)
2026-05-16 22:57:40.500 |       total time =    3836.04 ms /  1450 tokens
2026-05-16 22:57:40.500 | draft acceptance rate = 0.96800 (  121 accepted /   125 generated)
2026-05-16 22:57:40.500 | statistics mtp: #calls(b,g,a) = 30 4530 3844, #gen drafts = 3844, #acc drafts = 3844, #gen tokens = 6687, #acc tokens = 6568, dur(b,g,a) = 0.048, 17079.928, 1.844 ms
2026-05-16 22:57:40.501 | slot      release: id  2 | task 4839 | stop processing: n_tokens = 30388, truncated = 0
2026-05-16 22:57:40.501 | srv  update_slots: all slots are idle
2026-05-16 22:57:40.728 | srv  params_from_: Chat format: peg-native
2026-05-16 22:57:40.731 | slot get_availabl: id  2 | task -1 | selected slot by LCP similarity, sim_best = 0.976 (> 0.100 thold), f_keep = 1.000
2026-05-16 22:57:40.732 | reasoning-budget: activated, budget=2147483647 tokens
2026-05-16 22:57:40.732 | slot launch_slot_: id  2 | task -1 | sampler chain: logits -> penalties -> ?dry -> ?top-n-sigma -> top-k -> ?typical -> ?top-p -> min-p -> ?xtc -> ?temp-ext -> dist 
2026-05-16 22:57:40.732 | slot launch_slot_: id  2 | task 4920 | processing task, is_child = 0
2026-05-16 22:57:40.732 | slot update_slots: id  2 | task 4920 | new prompt, n_ctx_slot = 131072, n_keep = 0, task.n_tokens = 31122
2026-05-16 22:57:40.732 | slot update_slots: id  2 | task 4920 | n_tokens = 30388, memory_seq_rm [30388, end)
2026-05-16 22:57:40.732 | slot update_slots: id  2 | task 4920 | prompt processing progress, n_tokens = 30606, batch.n_tokens = 218, progress = 0.983420
2026-05-16 22:57:40.844 | slot update_slots: id  2 | task 4920 | n_tokens = 30606, memory_seq_rm [30606, end)
2026-05-16 22:57:40.844 | slot update_slots: id  2 | task 4920 | prompt processing progress, n_tokens = 31118, batch.n_tokens = 512, progress = 0.999871
2026-05-16 22:57:41.084 | slot create_check: id  2 | task 4920 | created context checkpoint 10 of 32 (pos_min = 30605, pos_max = 30605, n_tokens = 30606, size = 213.723 MiB)
2026-05-16 22:57:41.313 | slot update_slots: id  2 | task 4920 | n_tokens = 31118, memory_seq_rm [31118, end)
2026-05-16 22:57:41.317 | slot init_sampler: id  2 | task 4920 | init sampler, took 4.19 ms, tokens: text = 31122, total = 31122
2026-05-16 22:57:41.317 | slot update_slots: id  2 | task 4920 | prompt processing done, n_tokens = 31122, batch.n_tokens = 4
2026-05-16 22:57:41.561 | slot create_check: id  2 | task 4920 | created context checkpoint 11 of 32 (pos_min = 31117, pos_max = 31117, n_tokens = 31118, size = 214.796 MiB)
2026-05-16 22:57:41.599 | srv  log_server_r: done request: POST /v1/chat/completions 172.18.0.1 200
2026-05-16 22:57:44.539 | reasoning-budget: deactivated (natural end)
2026-05-16 22:57:48.394 | slot print_timing: id  2 | task 4920 | 
2026-05-16 22:57:48.394 | prompt eval time =     865.74 ms /   734 tokens (    1.18 ms per token,   847.83 tokens per second)
2026-05-16 22:57:48.394 |        eval time =    7651.58 ms /   482 tokens (   15.87 ms per token,    62.99 tokens per second)
2026-05-16 22:57:48.394 |       total time =    8517.32 ms /  1216 tokens
2026-05-16 22:57:48.394 | draft acceptance rate = 0.98921 (  275 accepted /   278 generated)
2026-05-16 22:57:48.394 | statistics mtp: #calls(b,g,a) = 31 4736 4002, #gen drafts = 4002, #acc drafts = 4002, #gen tokens = 6965, #acc tokens = 6843, dur(b,g,a) = 0.049, 17852.006, 1.919 ms
2026-05-16 22:57:48.394 | slot      release: id  2 | task 4920 | stop processing: n_tokens = 31603, truncated = 0
2026-05-16 22:57:48.394 | srv  update_slots: all slots are idle
2026-05-16 22:57:48.633 | srv  params_from_: Chat format: peg-native
2026-05-16 22:57:48.636 | slot get_availabl: id  2 | task -1 | selected slot by LCP similarity, sim_best = 0.999 (> 0.100 thold), f_keep = 1.000
2026-05-16 22:57:48.637 | reasoning-budget: activated, budget=2147483647 tokens
2026-05-16 22:57:48.637 | slot launch_slot_: id  2 | task -1 | sampler chain: logits -> penalties -> ?dry -> ?top-n-sigma -> top-k -> ?typical -> ?top-p -> min-p -> ?xtc -> ?temp-ext -> dist 
2026-05-16 22:57:48.637 | slot launch_slot_: id  2 | task 5148 | processing task, is_child = 0
2026-05-16 22:57:48.637 | slot update_slots: id  2 | task 5148 | new prompt, n_ctx_slot = 131072, n_keep = 0, task.n_tokens = 31623
2026-05-16 22:57:48.637 | slot update_slots: id  2 | task 5148 | n_tokens = 31603, memory_seq_rm [31603, end)
2026-05-16 22:57:48.637 | slot update_slots: id  2 | task 5148 | prompt processing progress, n_tokens = 31619, batch.n_tokens = 16, progress = 0.999874
2026-05-16 22:57:48.881 | slot create_check: id  2 | task 5148 | created context checkpoint 12 of 32 (pos_min = 31602, pos_max = 31602, n_tokens = 31603, size = 215.811 MiB)
2026-05-16 22:57:48.921 | slot update_slots: id  2 | task 5148 | n_tokens = 31619, memory_seq_rm [31619, end)
2026-05-16 22:57:48.926 | slot init_sampler: id  2 | task 5148 | init sampler, took 4.14 ms, tokens: text = 31623, total = 31623
2026-05-16 22:57:48.926 | slot update_slots: id  2 | task 5148 | prompt processing done, n_tokens = 31623, batch.n_tokens = 4
2026-05-16 22:57:48.961 | srv  log_server_r: done request: POST /v1/chat/completions 172.18.0.1 200
2026-05-16 22:57:49.329 | reasoning-budget: deactivated (natural end)
2026-05-16 22:57:51.727 | slot print_timing: id  2 | task 5148 | 
2026-05-16 22:57:51.727 | prompt eval time =     323.32 ms /    20 tokens (   16.17 ms per token,    61.86 tokens per second)
2026-05-16 22:57:51.727 |        eval time =    2766.11 ms /   169 tokens (   16.37 ms per token,    61.10 tokens per second)
2026-05-16 22:57:51.727 |       total time =    3089.44 ms /   189 tokens
2026-05-16 22:57:51.727 | draft acceptance rate = 0.97917 (   94 accepted /    96 generated)
2026-05-16 22:57:51.727 | statistics mtp: #calls(b,g,a) = 32 4810 4056, #gen drafts = 4056, #acc drafts = 4056, #gen tokens = 7061, #acc tokens = 6937, dur(b,g,a) = 0.050, 18124.326, 1.960 ms
2026-05-16 22:57:51.728 | slot      release: id  2 | task 5148 | stop processing: n_tokens = 31791, truncated = 0
2026-05-16 22:57:51.728 | srv  update_slots: all slots are idle
2026-05-16 22:57:51.980 | srv  params_from_: Chat format: peg-native
2026-05-16 22:57:51.983 | slot get_availabl: id  2 | task -1 | selected slot by LCP similarity, sim_best = 0.998 (> 0.100 thold), f_keep = 1.000
2026-05-16 22:57:51.984 | reasoning-budget: activated, budget=2147483647 tokens
2026-05-16 22:57:51.984 | slot launch_slot_: id  2 | task -1 | sampler chain: logits -> penalties -> ?dry -> ?top-n-sigma -> top-k -> ?typical -> ?top-p -> min-p -> ?xtc -> ?temp-ext -> dist 
2026-05-16 22:57:51.984 | slot launch_slot_: id  2 | task 5231 | processing task, is_child = 0
2026-05-16 22:57:51.984 | slot update_slots: id  2 | task 5231 | new prompt, n_ctx_slot = 131072, n_keep = 0, task.n_tokens = 31855
2026-05-16 22:57:51.984 | slot update_slots: id  2 | task 5231 | n_tokens = 31791, memory_seq_rm [31791, end)
2026-05-16 22:57:51.984 | slot update_slots: id  2 | task 5231 | prompt processing progress, n_tokens = 31851, batch.n_tokens = 60, progress = 0.999874
2026-05-16 22:57:52.227 | slot create_check: id  2 | task 5231 | created context checkpoint 13 of 32 (pos_min = 31790, pos_max = 31790, n_tokens = 31791, size = 216.205 MiB)
2026-05-16 22:57:52.279 | slot update_slots: id  2 | task 5231 | n_tokens = 31851, memory_seq_rm [31851, end)
2026-05-16 22:57:52.283 | slot init_sampler: id  2 | task 5231 | init sampler, took 4.44 ms, tokens: text = 31855, total = 31855
2026-05-16 22:57:52.283 | slot update_slots: id  2 | task 5231 | prompt processing done, n_tokens = 31855, batch.n_tokens = 4
2026-05-16 22:57:52.321 | srv  log_server_r: done request: POST /v1/chat/completions 172.18.0.1 200
2026-05-16 22:57:52.657 | reasoning-budget: deactivated (natural end)
2026-05-16 22:57:55.752 | slot print_timing: id  2 | task 5231 | 
2026-05-16 22:57:55.752 | prompt eval time =     335.61 ms /    64 tokens (    5.24 ms per token,   190.70 tokens per second)
2026-05-16 22:57:55.752 |        eval time =    3431.92 ms /   179 tokens (   19.17 ms per token,    52.16 tokens per second)
2026-05-16 22:57:55.752 |       total time =    3767.53 ms /   243 tokens
2026-05-16 22:57:55.752 | draft acceptance rate = 0.94737 (   90 accepted /    95 generated)
2026-05-16 22:57:55.752 | statistics mtp: #calls(b,g,a) = 33 4898 4114, #gen drafts = 4114, #acc drafts = 4114, #gen tokens = 7156, #acc tokens = 7027, dur(b,g,a) = 0.052, 18443.374, 1.986 ms
2026-05-16 22:57:55.753 | slot      release: id  2 | task 5231 | stop processing: n_tokens = 32033, truncated = 0
2026-05-16 22:57:55.753 | srv  update_slots: all slots are idle
2026-05-16 22:58:48.569 | srv  params_from_: Chat format: peg-native
2026-05-16 22:58:48.572 | slot get_availabl: id  2 | task -1 | selected slot by LCP similarity, sim_best = 0.939 (> 0.100 thold), f_keep = 0.941
2026-05-16 22:58:48.573 | reasoning-budget: activated, budget=2147483647 tokens
2026-05-16 22:58:48.573 | slot launch_slot_: id  2 | task -1 | sampler chain: logits -> penalties -> ?dry -> ?top-n-sigma -> top-k -> ?typical -> ?top-p -> min-p -> ?xtc -> ?temp-ext -> dist 
2026-05-16 22:58:48.573 | slot launch_slot_: id  2 | task 5329 | processing task, is_child = 0
2026-05-16 22:58:48.573 | slot update_slots: id  2 | task 5329 | new prompt, n_ctx_slot = 131072, n_keep = 0, task.n_tokens = 32103
2026-05-16 22:58:48.573 | slot update_slots: id  2 | task 5329 | n_past = 30134, slot.prompt.tokens.size() = 32033, seq_id = 2, pos_min = 32032, n_swa = 0
2026-05-16 22:58:48.573 | slot update_slots: id  2 | task 5329 | Checking checkpoint with [31790, 31790] against 30134...
2026-05-16 22:58:48.573 | slot update_slots: id  2 | task 5329 | Checking checkpoint with [31602, 31602] against 30134...
2026-05-16 22:58:48.573 | slot update_slots: id  2 | task 5329 | Checking checkpoint with [31117, 31117] against 30134...
2026-05-16 22:58:48.573 | slot update_slots: id  2 | task 5329 | Checking checkpoint with [30605, 30605] against 30134...
2026-05-16 22:58:48.573 | slot update_slots: id  2 | task 5329 | Checking checkpoint with [30191, 30191] against 30134...
2026-05-16 22:58:48.573 | slot update_slots: id  2 | task 5329 | Checking checkpoint with [29679, 29679] against 30134...
2026-05-16 22:58:48.655 | slot update_slots: id  2 | task 5329 | restored context checkpoint (pos_min = 29679, pos_max = 29679, n_tokens = 29680, n_past = 29680, size = 211.784 MiB)
2026-05-16 22:58:48.655 | slot update_slots: id  2 | task 5329 | erased invalidated context checkpoint (pos_min = 30191, pos_max = 30191, n_tokens = 30192, n_swa = 0, pos_next = 29680, size = 212.856 MiB)
2026-05-16 22:58:48.668 | slot update_slots: id  2 | task 5329 | erased invalidated context checkpoint (pos_min = 30605, pos_max = 30605, n_tokens = 30606, n_swa = 0, pos_next = 29680, size = 213.723 MiB)
2026-05-16 22:58:48.680 | slot update_slots: id  2 | task 5329 | erased invalidated context checkpoint (pos_min = 31117, pos_max = 31117, n_tokens = 31118, n_swa = 0, pos_next = 29680, size = 214.796 MiB)
2026-05-16 22:58:48.692 | slot update_slots: id  2 | task 5329 | erased invalidated context checkpoint (pos_min = 31602, pos_max = 31602, n_tokens = 31603, n_swa = 0, pos_next = 29680, size = 215.811 MiB)
2026-05-16 22:58:48.705 | slot update_slots: id  2 | task 5329 | erased invalidated context checkpoint (pos_min = 31790, pos_max = 31790, n_tokens = 31791, n_swa = 0, pos_next = 29680, size = 216.205 MiB)
2026-05-16 22:58:48.718 | slot update_slots: id  2 | task 5329 | n_tokens = 29680, memory_seq_rm [29680, end)
2026-05-16 22:58:48.718 | slot update_slots: id  2 | task 5329 | prompt processing progress, n_tokens = 31587, batch.n_tokens = 1907, progress = 0.983927
2026-05-16 22:58:49.699 | slot update_slots: id  2 | task 5329 | n_tokens = 31587, memory_seq_rm [31587, end)
2026-05-16 22:58:49.699 | slot update_slots: id  2 | task 5329 | prompt processing progress, n_tokens = 32099, batch.n_tokens = 512, progress = 0.999875
2026-05-16 22:58:49.876 | slot create_check: id  2 | task 5329 | created context checkpoint 9 of 32 (pos_min = 31586, pos_max = 31586, n_tokens = 31587, size = 215.778 MiB)
2026-05-16 22:58:50.108 | slot update_slots: id  2 | task 5329 | n_tokens = 32099, memory_seq_rm [32099, end)
2026-05-16 22:58:50.112 | slot init_sampler: id  2 | task 5329 | init sampler, took 4.24 ms, tokens: text = 32103, total = 32103
2026-05-16 22:58:50.112 | slot update_slots: id  2 | task 5329 | prompt processing done, n_tokens = 32103, batch.n_tokens = 4
2026-05-16 22:58:50.277 | slot create_check: id  2 | task 5329 | created context checkpoint 10 of 32 (pos_min = 32098, pos_max = 32098, n_tokens = 32099, size = 216.850 MiB)
2026-05-16 22:58:50.314 | srv  log_server_r: done request: POST /v1/chat/completions 172.18.0.1 200
2026-05-16 22:58:55.037 | reasoning-budget: deactivated (natural end)
2026-05-16 22:58:56.843 | slot print_timing: id  2 | task 5329 | 
2026-05-16 22:58:56.843 | prompt eval time =    1740.18 ms /  2423 tokens (    0.72 ms per token,  1392.38 tokens per second)
2026-05-16 22:58:56.843 |        eval time =    6529.49 ms /   410 tokens (   15.93 ms per token,    62.79 tokens per second)
2026-05-16 22:58:56.843 |       total time =    8269.67 ms /  2833 tokens
2026-05-16 22:58:56.843 | draft acceptance rate = 0.99115 (  224 accepted /   226 generated)
2026-05-16 22:58:56.843 | statistics mtp: #calls(b,g,a) = 34 5083 4241, #gen drafts = 4241, #acc drafts = 4241, #gen tokens = 7382, #acc tokens = 7251, dur(b,g,a) = 0.053, 19113.021, 2.043 ms
2026-05-16 22:58:56.844 | slot      release: id  2 | task 5329 | stop processing: n_tokens = 32512, truncated = 0
2026-05-16 22:58:56.844 | srv  update_slots: all slots are idle
2026-05-16 22:58:57.092 | srv  params_from_: Chat format: peg-native
2026-05-16 22:58:57.095 | slot get_availabl: id  2 | task -1 | selected slot by LCP similarity, sim_best = 0.974 (> 0.100 thold), f_keep = 1.000
2026-05-16 22:58:57.096 | reasoning-budget: activated, budget=2147483647 tokens
2026-05-16 22:58:57.096 | slot launch_slot_: id  2 | task -1 | sampler chain: logits -> penalties -> ?dry -> ?top-n-sigma -> top-k -> ?typical -> ?top-p -> min-p -> ?xtc -> ?temp-ext -> dist 
2026-05-16 22:58:57.096 | slot launch_slot_: id  2 | task 5525 | processing task, is_child = 0
2026-05-16 22:58:57.096 | slot update_slots: id  2 | task 5525 | new prompt, n_ctx_slot = 131072, n_keep = 0, task.n_tokens = 33368
2026-05-16 22:58:57.096 | slot update_slots: id  2 | task 5525 | n_tokens = 32512, memory_seq_rm [32512, end)
2026-05-16 22:58:57.096 | slot update_slots: id  2 | task 5525 | prompt processing progress, n_tokens = 32852, batch.n_tokens = 340, progress = 0.984536
2026-05-16 22:58:57.270 | slot update_slots: id  2 | task 5525 | n_tokens = 32852, memory_seq_rm [32852, end)
2026-05-16 22:58:57.270 | slot update_slots: id  2 | task 5525 | prompt processing progress, n_tokens = 33364, batch.n_tokens = 512, progress = 0.999880
2026-05-16 22:58:57.502 | slot create_check: id  2 | task 5525 | created context checkpoint 11 of 32 (pos_min = 32851, pos_max = 32851, n_tokens = 32852, size = 218.427 MiB)
2026-05-16 22:58:57.736 | slot update_slots: id  2 | task 5525 | n_tokens = 33364, memory_seq_rm [33364, end)
2026-05-16 22:58:57.741 | slot init_sampler: id  2 | task 5525 | init sampler, took 4.56 ms, tokens: text = 33368, total = 33368
2026-05-16 22:58:57.741 | slot update_slots: id  2 | task 5525 | prompt processing done, n_tokens = 33368, batch.n_tokens = 4
2026-05-16 22:58:57.989 | slot create_check: id  2 | task 5525 | created context checkpoint 12 of 32 (pos_min = 33363, pos_max = 33363, n_tokens = 33364, size = 219.499 MiB)
2026-05-16 22:58:58.026 | srv  log_server_r: done request: POST /v1/chat/completions 172.18.0.1 200
2026-05-16 22:59:02.467 | reasoning-budget: deactivated (natural end)
2026-05-16 22:59:03.387 | slot print_timing: id  2 | task 5525 | 
2026-05-16 22:59:03.387 | prompt eval time =     929.20 ms /   856 tokens (    1.09 ms per token,   921.22 tokens per second)
2026-05-16 22:59:03.387 |        eval time =    5361.13 ms /   342 tokens (   15.68 ms per token,    63.79 tokens per second)
2026-05-16 22:59:03.387 |       total time =    6290.33 ms /  1198 tokens
2026-05-16 22:59:03.387 | draft acceptance rate = 0.98492 (  196 accepted /   199 generated)
2026-05-16 22:59:03.387 | statistics mtp: #calls(b,g,a) = 35 5228 4351, #gen drafts = 4351, #acc drafts = 4351, #gen tokens = 7581, #acc tokens = 7447, dur(b,g,a) = 0.055, 19668.880, 2.089 ms
2026-05-16 22:59:03.388 | slot      release: id  2 | task 5525 | stop processing: n_tokens = 33709, truncated = 0
2026-05-16 22:59:03.388 | srv  update_slots: all slots are idle
2026-05-16 22:59:03.615 | srv  params_from_: Chat format: peg-native
2026-05-16 22:59:03.618 | slot get_availabl: id  2 | task -1 | selected slot by LCP similarity, sim_best = 0.988 (> 0.100 thold), f_keep = 1.000
2026-05-16 22:59:03.619 | reasoning-budget: activated, budget=2147483647 tokens
2026-05-16 22:59:03.619 | slot launch_slot_: id  2 | task -1 | sampler chain: logits -> penalties -> ?dry -> ?top-n-sigma -> top-k -> ?typical -> ?top-p -> min-p -> ?xtc -> ?temp-ext -> dist 
2026-05-16 22:59:03.619 | slot launch_slot_: id  2 | task 5684 | processing task, is_child = 0
2026-05-16 22:59:03.619 | slot update_slots: id  2 | task 5684 | new prompt, n_ctx_slot = 131072, n_keep = 0, task.n_tokens = 34106
2026-05-16 22:59:03.619 | slot update_slots: id  2 | task 5684 | n_tokens = 33709, memory_seq_rm [33709, end)
2026-05-16 22:59:03.619 | slot update_slots: id  2 | task 5684 | prompt processing progress, n_tokens = 34102, batch.n_tokens = 393, progress = 0.999883
2026-05-16 22:59:03.863 | slot create_check: id  2 | task 5684 | created context checkpoint 13 of 32 (pos_min = 33708, pos_max = 33708, n_tokens = 33709, size = 220.222 MiB)
2026-05-16 22:59:04.056 | slot update_slots: id  2 | task 5684 | n_tokens = 34102, memory_seq_rm [34102, end)
2026-05-16 22:59:04.061 | slot init_sampler: id  2 | task 5684 | init sampler, took 4.66 ms, tokens: text = 34106, total = 34106
2026-05-16 22:59:04.061 | slot update_slots: id  2 | task 5684 | prompt processing done, n_tokens = 34106, batch.n_tokens = 4
2026-05-16 22:59:04.309 | slot create_check: id  2 | task 5684 | created context checkpoint 14 of 32 (pos_min = 34101, pos_max = 34101, n_tokens = 34102, size = 221.045 MiB)
2026-05-16 22:59:04.347 | srv  log_server_r: done request: POST /v1/chat/completions 172.18.0.1 200
2026-05-16 22:59:08.407 | reasoning-budget: deactivated (natural end)
2026-05-16 22:59:12.953 | slot print_timing: id  2 | task 5684 | 
2026-05-16 22:59:12.953 | prompt eval time =     726.82 ms /   397 tokens (    1.83 ms per token,   546.22 tokens per second)
2026-05-16 22:59:12.953 |        eval time =    8606.63 ms /   544 tokens (   15.82 ms per token,    63.21 tokens per second)
2026-05-16 22:59:12.953 |       total time =    9333.44 ms /   941 tokens
2026-05-16 22:59:12.953 | draft acceptance rate = 0.98107 (  311 accepted /   317 generated)
2026-05-16 22:59:12.953 | statistics mtp: #calls(b,g,a) = 36 5460 4530, #gen drafts = 4530, #acc drafts = 4530, #gen tokens = 7898, #acc tokens = 7758, dur(b,g,a) = 0.057, 20580.101, 2.170 ms
2026-05-16 22:59:12.954 | slot      release: id  2 | task 5684 | stop processing: n_tokens = 34649, truncated = 0
2026-05-16 22:59:12.954 | srv  update_slots: all slots are idle
2026-05-16 23:00:01.871 | srv  params_from_: Chat format: peg-native
2026-05-16 23:00:01.874 | slot get_availabl: id  2 | task -1 | selected slot by LCP similarity, sim_best = 0.938 (> 0.100 thold), f_keep = 0.917
2026-05-16 23:00:01.875 | reasoning-budget: activated, budget=2147483647 tokens
2026-05-16 23:00:01.875 | slot launch_slot_: id  2 | task -1 | sampler chain: logits -> penalties -> ?dry -> ?top-n-sigma -> top-k -> ?typical -> ?top-p -> min-p -> ?xtc -> ?temp-ext -> dist 
2026-05-16 23:00:01.875 | slot launch_slot_: id  2 | task 5932 | processing task, is_child = 0
2026-05-16 23:00:01.875 | slot update_slots: id  2 | task 5932 | new prompt, n_ctx_slot = 131072, n_keep = 0, task.n_tokens = 33905
2026-05-16 23:00:01.875 | slot update_slots: id  2 | task 5932 | n_past = 31788, slot.prompt.tokens.size() = 34649, seq_id = 2, pos_min = 34648, n_swa = 0
2026-05-16 23:00:01.875 | slot update_slots: id  2 | task 5932 | Checking checkpoint with [34101, 34101] against 31788...
2026-05-16 23:00:01.875 | slot update_slots: id  2 | task 5932 | Checking checkpoint with [33708, 33708] against 31788...
2026-05-16 23:00:01.875 | slot update_slots: id  2 | task 5932 | Checking checkpoint with [33363, 33363] against 31788...
2026-05-16 23:00:01.875 | slot update_slots: id  2 | task 5932 | Checking checkpoint with [32851, 32851] against 31788...
2026-05-16 23:00:01.875 | slot update_slots: id  2 | task 5932 | Checking checkpoint with [32098, 32098] against 31788...
2026-05-16 23:00:01.875 | slot update_slots: id  2 | task 5932 | Checking checkpoint with [31586, 31586] against 31788...
2026-05-16 23:00:01.959 | slot update_slots: id  2 | task 5932 | restored context checkpoint (pos_min = 31586, pos_max = 31586, n_tokens = 31587, n_past = 31587, size = 215.778 MiB)
2026-05-16 23:00:01.959 | slot update_slots: id  2 | task 5932 | erased invalidated context checkpoint (pos_min = 32098, pos_max = 32098, n_tokens = 32099, n_swa = 0, pos_next = 31587, size = 216.850 MiB)
2026-05-16 23:00:01.972 | slot update_slots: id  2 | task 5932 | erased invalidated context checkpoint (pos_min = 32851, pos_max = 32851, n_tokens = 32852, n_swa = 0, pos_next = 31587, size = 218.427 MiB)
2026-05-16 23:00:01.985 | slot update_slots: id  2 | task 5932 | erased invalidated context checkpoint (pos_min = 33363, pos_max = 33363, n_tokens = 33364, n_swa = 0, pos_next = 31587, size = 219.499 MiB)
2026-05-16 23:00:01.997 | slot update_slots: id  2 | task 5932 | erased invalidated context checkpoint (pos_min = 33708, pos_max = 33708, n_tokens = 33709, n_swa = 0, pos_next = 31587, size = 220.222 MiB)
2026-05-16 23:00:02.010 | slot update_slots: id  2 | task 5932 | erased invalidated context checkpoint (pos_min = 34101, pos_max = 34101, n_tokens = 34102, n_swa = 0, pos_next = 31587, size = 221.045 MiB)
2026-05-16 23:00:02.023 | slot update_slots: id  2 | task 5932 | n_tokens = 31587, memory_seq_rm [31587, end)
2026-05-16 23:00:02.023 | slot update_slots: id  2 | task 5932 | prompt processing progress, n_tokens = 33389, batch.n_tokens = 1802, progress = 0.984781
2026-05-16 23:00:03.107 | slot update_slots: id  2 | task 5932 | n_tokens = 33389, memory_seq_rm [33389, end)
2026-05-16 23:00:03.107 | slot update_slots: id  2 | task 5932 | prompt processing progress, n_tokens = 33901, batch.n_tokens = 512, progress = 0.999882
2026-05-16 23:00:03.280 | slot create_check: id  2 | task 5932 | created context checkpoint 10 of 32 (pos_min = 33388, pos_max = 33388, n_tokens = 33389, size = 219.552 MiB)
2026-05-16 23:00:03.517 | slot update_slots: id  2 | task 5932 | n_tokens = 33901, memory_seq_rm [33901, end)
2026-05-16 23:00:03.521 | slot init_sampler: id  2 | task 5932 | init sampler, took 4.46 ms, tokens: text = 33905, total = 33905
2026-05-16 23:00:03.521 | slot update_slots: id  2 | task 5932 | prompt processing done, n_tokens = 33905, batch.n_tokens = 4
2026-05-16 23:00:03.684 | slot create_check: id  2 | task 5932 | created context checkpoint 11 of 32 (pos_min = 33900, pos_max = 33900, n_tokens = 33901, size = 220.624 MiB)
2026-05-16 23:00:03.721 | srv  log_server_r: done request: POST /v1/chat/completions 172.18.0.1 200
2026-05-16 23:00:05.722 | reasoning-budget: deactivated (natural end)
2026-05-16 23:00:07.278 | slot print_timing: id  2 | task 5932 | 
2026-05-16 23:00:07.278 | prompt eval time =    1844.74 ms /  2318 tokens (    0.80 ms per token,  1256.54 tokens per second)
2026-05-16 23:00:07.278 |        eval time =    3557.41 ms /   230 tokens (   15.47 ms per token,    64.65 tokens per second)
2026-05-16 23:00:07.278 |       total time =    5402.15 ms /  2548 tokens
2026-05-16 23:00:07.278 | draft acceptance rate = 1.00000 (  135 accepted /   135 generated)
2026-05-16 23:00:07.278 | statistics mtp: #calls(b,g,a) = 37 5554 4607, #gen drafts = 4607, #acc drafts = 4607, #gen tokens = 8033, #acc tokens = 7893, dur(b,g,a) = 0.058, 20949.043, 2.206 ms
2026-05-16 23:00:07.279 | slot      release: id  2 | task 5932 | stop processing: n_tokens = 34134, truncated = 0
2026-05-16 23:00:07.279 | srv  update_slots: all slots are idle
2026-05-16 23:00:07.527 | srv  params_from_: Chat format: peg-native
2026-05-16 23:00:07.530 | slot get_availabl: id  2 | task -1 | selected slot by LCP similarity, sim_best = 0.984 (> 0.100 thold), f_keep = 1.000
2026-05-16 23:00:07.531 | reasoning-budget: activated, budget=2147483647 tokens
2026-05-16 23:00:07.531 | slot launch_slot_: id  2 | task -1 | sampler chain: logits -> penalties -> ?dry -> ?top-n-sigma -> top-k -> ?typical -> ?top-p -> min-p -> ?xtc -> ?temp-ext -> dist 
2026-05-16 23:00:07.531 | slot launch_slot_: id  2 | task 6035 | processing task, is_child = 0
2026-05-16 23:00:07.531 | slot update_slots: id  2 | task 6035 | new prompt, n_ctx_slot = 131072, n_keep = 0, task.n_tokens = 34675
2026-05-16 23:00:07.531 | slot update_slots: id  2 | task 6035 | n_tokens = 34134, memory_seq_rm [34134, end)
2026-05-16 23:00:07.532 | slot update_slots: id  2 | task 6035 | prompt processing progress, n_tokens = 34159, batch.n_tokens = 25, progress = 0.985119
2026-05-16 23:00:07.573 | slot update_slots: id  2 | task 6035 | n_tokens = 34159, memory_seq_rm [34159, end)
2026-05-16 23:00:07.573 | slot update_slots: id  2 | task 6035 | prompt processing progress, n_tokens = 34671, batch.n_tokens = 512, progress = 0.999885
2026-05-16 23:00:07.823 | slot create_check: id  2 | task 6035 | created context checkpoint 12 of 32 (pos_min = 34158, pos_max = 34158, n_tokens = 34159, size = 221.164 MiB)
2026-05-16 23:00:08.062 | slot update_slots: id  2 | task 6035 | n_tokens = 34671, memory_seq_rm [34671, end)
2026-05-16 23:00:08.067 | slot init_sampler: id  2 | task 6035 | init sampler, took 4.69 ms, tokens: text = 34675, total = 34675
2026-05-16 23:00:08.067 | slot update_slots: id  2 | task 6035 | prompt processing done, n_tokens = 34675, batch.n_tokens = 4
2026-05-16 23:00:08.317 | slot create_check: id  2 | task 6035 | created context checkpoint 13 of 32 (pos_min = 34670, pos_max = 34670, n_tokens = 34671, size = 222.237 MiB)
2026-05-16 23:00:08.354 | srv  log_server_r: done request: POST /v1/chat/completions 172.18.0.1 200
2026-05-16 23:00:09.156 | reasoning-budget: deactivated (natural end)
2026-05-16 23:00:10.323 | slot print_timing: id  2 | task 6035 | 
2026-05-16 23:00:10.323 | prompt eval time =     821.28 ms /   541 tokens (    1.52 ms per token,   658.72 tokens per second)
2026-05-16 23:00:10.323 |        eval time =    1969.76 ms /   138 tokens (   14.27 ms per token,    70.06 tokens per second)
2026-05-16 23:00:10.323 |       total time =    2791.05 ms /   679 tokens
2026-05-16 23:00:10.323 | draft acceptance rate = 0.98837 (   85 accepted /    86 generated)
2026-05-16 23:00:10.323 | statistics mtp: #calls(b,g,a) = 38 5606 4653, #gen drafts = 4653, #acc drafts = 4653, #gen tokens = 8119, #acc tokens = 7978, dur(b,g,a) = 0.059, 21162.844, 2.226 ms
2026-05-16 23:00:10.324 | slot      release: id  2 | task 6035 | stop processing: n_tokens = 34812, truncated = 0
2026-05-16 23:00:10.324 | srv  update_slots: all slots are idle
2026-05-16 23:00:10.583 | srv  params_from_: Chat format: peg-native
2026-05-16 23:00:10.585 | slot get_availabl: id  2 | task -1 | selected slot by LCP similarity, sim_best = 0.915 (> 0.100 thold), f_keep = 1.000
2026-05-16 23:00:10.587 | reasoning-budget: activated, budget=2147483647 tokens
2026-05-16 23:00:10.587 | slot launch_slot_: id  2 | task -1 | sampler chain: logits -> penalties -> ?dry -> ?top-n-sigma -> top-k -> ?typical -> ?top-p -> min-p -> ?xtc -> ?temp-ext -> dist 
2026-05-16 23:00:10.587 | slot launch_slot_: id  2 | task 6094 | processing task, is_child = 0
2026-05-16 23:00:10.587 | slot update_slots: id  2 | task 6094 | new prompt, n_ctx_slot = 131072, n_keep = 0, task.n_tokens = 38052
2026-05-16 23:00:10.587 | slot update_slots: id  2 | task 6094 | n_tokens = 34812, memory_seq_rm [34812, end)
2026-05-16 23:00:10.587 | slot update_slots: id  2 | task 6094 | prompt processing progress, n_tokens = 36860, batch.n_tokens = 2048, progress = 0.968674
2026-05-16 23:00:11.546 | slot update_slots: id  2 | task 6094 | n_tokens = 36860, memory_seq_rm [36860, end)
2026-05-16 23:00:11.547 | slot update_slots: id  2 | task 6094 | prompt processing progress, n_tokens = 37536, batch.n_tokens = 676, progress = 0.986440
2026-05-16 23:00:11.895 | slot update_slots: id  2 | task 6094 | n_tokens = 37536, memory_seq_rm [37536, end)
2026-05-16 23:00:11.895 | slot update_slots: id  2 | task 6094 | prompt processing progress, n_tokens = 38048, batch.n_tokens = 512, progress = 0.999895
2026-05-16 23:00:12.153 | slot create_check: id  2 | task 6094 | created context checkpoint 14 of 32 (pos_min = 37535, pos_max = 37535, n_tokens = 37536, size = 228.237 MiB)
2026-05-16 23:00:12.399 | slot update_slots: id  2 | task 6094 | n_tokens = 38048, memory_seq_rm [38048, end)
2026-05-16 23:00:12.405 | slot init_sampler: id  2 | task 6094 | init sampler, took 5.66 ms, tokens: text = 38052, total = 38052
2026-05-16 23:00:12.405 | slot update_slots: id  2 | task 6094 | prompt processing done, n_tokens = 38052, batch.n_tokens = 4
2026-05-16 23:00:12.664 | slot create_check: id  2 | task 6094 | created context checkpoint 15 of 32 (pos_min = 38047, pos_max = 38047, n_tokens = 38048, size = 229.309 MiB)
2026-05-16 23:00:12.700 | srv  log_server_r: done request: POST /v1/chat/completions 172.18.0.1 200
2026-05-16 23:00:13.600 | reasoning-budget: deactivated (natural end)
2026-05-16 23:00:18.495 | slot print_timing: id  2 | task 6094 | 
2026-05-16 23:00:18.495 | prompt eval time =    2112.54 ms /  3240 tokens (    0.65 ms per token,  1533.70 tokens per second)
2026-05-16 23:00:18.495 |        eval time =    6651.17 ms /   535 tokens (   12.43 ms per token,    80.44 tokens per second)
2026-05-16 23:00:18.495 |       total time =    8763.71 ms /  3775 tokens
2026-05-16 23:00:18.495 | draft acceptance rate = 0.99415 (  340 accepted /   342 generated)
2026-05-16 23:00:18.495 | statistics mtp: #calls(b,g,a) = 39 5800 4828, #gen drafts = 4828, #acc drafts = 4828, #gen tokens = 8461, #acc tokens = 8318, dur(b,g,a) = 0.060, 21974.822, 2.316 ms
2026-05-16 23:00:18.496 | slot      release: id  2 | task 6094 | stop processing: n_tokens = 38586, truncated = 0
2026-05-16 23:00:18.496 | srv  update_slots: all slots are idle
2026-05-16 23:00:18.746 | srv  params_from_: Chat format: peg-native
2026-05-16 23:00:18.749 | slot get_availabl: id  2 | task -1 | selected slot by LCP similarity, sim_best = 0.971 (> 0.100 thold), f_keep = 1.000
2026-05-16 23:00:18.750 | reasoning-budget: activated, budget=2147483647 tokens
2026-05-16 23:00:18.750 | slot launch_slot_: id  2 | task -1 | sampler chain: logits -> penalties -> ?dry -> ?top-n-sigma -> top-k -> ?typical -> ?top-p -> min-p -> ?xtc -> ?temp-ext -> dist 
2026-05-16 23:00:18.750 | slot launch_slot_: id  2 | task 6297 | processing task, is_child = 0
2026-05-16 23:00:18.750 | slot update_slots: id  2 | task 6297 | new prompt, n_ctx_slot = 131072, n_keep = 0, task.n_tokens = 39727
2026-05-16 23:00:18.750 | slot update_slots: id  2 | task 6297 | n_tokens = 38586, memory_seq_rm [38586, end)
2026-05-16 23:00:18.750 | slot update_slots: id  2 | task 6297 | prompt processing progress, n_tokens = 39211, batch.n_tokens = 625, progress = 0.987011
2026-05-16 23:00:19.085 | slot update_slots: id  2 | task 6297 | n_tokens = 39211, memory_seq_rm [39211, end)
2026-05-16 23:00:19.085 | slot update_slots: id  2 | task 6297 | prompt processing progress, n_tokens = 39723, batch.n_tokens = 512, progress = 0.999899
2026-05-16 23:00:19.348 | slot create_check: id  2 | task 6297 | created context checkpoint 16 of 32 (pos_min = 39210, pos_max = 39210, n_tokens = 39211, size = 231.745 MiB)
2026-05-16 23:00:19.600 | slot update_slots: id  2 | task 6297 | n_tokens = 39723, memory_seq_rm [39723, end)
2026-05-16 23:00:19.605 | slot init_sampler: id  2 | task 6297 | init sampler, took 5.33 ms, tokens: text = 39727, total = 39727
2026-05-16 23:00:19.605 | slot update_slots: id  2 | task 6297 | prompt processing done, n_tokens = 39727, batch.n_tokens = 4
2026-05-16 23:00:19.870 | slot create_check: id  2 | task 6297 | created context checkpoint 17 of 32 (pos_min = 39722, pos_max = 39722, n_tokens = 39723, size = 232.817 MiB)
2026-05-16 23:00:19.908 | srv  log_server_r: done request: POST /v1/chat/completions 172.18.0.1 200
2026-05-16 23:00:28.501 | reasoning-budget: deactivated (natural end)
2026-05-16 23:00:33.755 | slot print_timing: id  2 | task 6297 | 
2026-05-16 23:00:33.755 | prompt eval time =    1157.29 ms /  1141 tokens (    1.01 ms per token,   985.92 tokens per second)
2026-05-16 23:00:33.755 |        eval time =   13847.47 ms /   877 tokens (   15.79 ms per token,    63.33 tokens per second)
2026-05-16 23:00:33.755 |       total time =   15004.76 ms /  2018 tokens
2026-05-16 23:00:33.755 | draft acceptance rate = 0.98428 (  501 accepted /   509 generated)
2026-05-16 23:00:33.755 | statistics mtp: #calls(b,g,a) = 40 6175 5108, #gen drafts = 5108, #acc drafts = 5108, #gen tokens = 8970, #acc tokens = 8819, dur(b,g,a) = 0.062, 23420.365, 2.460 ms
2026-05-16 23:00:33.757 | slot      release: id  2 | task 6297 | stop processing: n_tokens = 40603, truncated = 0
2026-05-16 23:00:33.757 | srv  update_slots: all slots are idle
2026-05-16 23:03:27.300 | srv  params_from_: Chat format: peg-native
2026-05-16 23:03:27.303 | slot get_availabl: id  2 | task -1 | selected slot by LCP similarity, sim_best = 0.847 (> 0.100 thold), f_keep = 0.827
2026-05-16 23:03:27.304 | reasoning-budget: activated, budget=2147483647 tokens
2026-05-16 23:03:27.304 | slot launch_slot_: id  2 | task -1 | sampler chain: logits -> penalties -> ?dry -> ?top-n-sigma -> top-k -> ?typical -> ?top-p -> min-p -> ?xtc -> ?temp-ext -> dist 
2026-05-16 23:03:27.304 | slot launch_slot_: id  2 | task 6699 | processing task, is_child = 0
2026-05-16 23:03:27.304 | slot update_slots: id  2 | task 6699 | new prompt, n_ctx_slot = 131072, n_keep = 0, task.n_tokens = 39641
2026-05-16 23:03:27.304 | slot update_slots: id  2 | task 6699 | n_past = 33590, slot.prompt.tokens.size() = 40603, seq_id = 2, pos_min = 40602, n_swa = 0
2026-05-16 23:03:27.304 | slot update_slots: id  2 | task 6699 | Checking checkpoint with [39722, 39722] against 33590...
2026-05-16 23:03:27.304 | slot update_slots: id  2 | task 6699 | Checking checkpoint with [39210, 39210] against 33590...
2026-05-16 23:03:27.304 | slot update_slots: id  2 | task 6699 | Checking checkpoint with [38047, 38047] against 33590...
2026-05-16 23:03:27.304 | slot update_slots: id  2 | task 6699 | Checking checkpoint with [37535, 37535] against 33590...
2026-05-16 23:03:27.304 | slot update_slots: id  2 | task 6699 | Checking checkpoint with [34670, 34670] against 33590...
2026-05-16 23:03:27.304 | slot update_slots: id  2 | task 6699 | Checking checkpoint with [34158, 34158] against 33590...
2026-05-16 23:03:27.304 | slot update_slots: id  2 | task 6699 | Checking checkpoint with [33900, 33900] against 33590...
2026-05-16 23:03:27.304 | slot update_slots: id  2 | task 6699 | Checking checkpoint with [33388, 33388] against 33590...
2026-05-16 23:03:27.393 | slot update_slots: id  2 | task 6699 | restored context checkpoint (pos_min = 33388, pos_max = 33388, n_tokens = 33389, n_past = 33389, size = 219.552 MiB)
2026-05-16 23:03:27.393 | slot update_slots: id  2 | task 6699 | erased invalidated context checkpoint (pos_min = 33900, pos_max = 33900, n_tokens = 33901, n_swa = 0, pos_next = 33389, size = 220.624 MiB)
2026-05-16 23:03:27.405 | slot update_slots: id  2 | task 6699 | erased invalidated context checkpoint (pos_min = 34158, pos_max = 34158, n_tokens = 34159, n_swa = 0, pos_next = 33389, size = 221.164 MiB)
2026-05-16 23:03:27.418 | slot update_slots: id  2 | task 6699 | erased invalidated context checkpoint (pos_min = 34670, pos_max = 34670, n_tokens = 34671, n_swa = 0, pos_next = 33389, size = 222.237 MiB)
2026-05-16 23:03:27.431 | slot update_slots: id  2 | task 6699 | erased invalidated context checkpoint (pos_min = 37535, pos_max = 37535, n_tokens = 37536, n_swa = 0, pos_next = 33389, size = 228.237 MiB)
2026-05-16 23:03:27.444 | slot update_slots: id  2 | task 6699 | erased invalidated context checkpoint (pos_min = 38047, pos_max = 38047, n_tokens = 38048, n_swa = 0, pos_next = 33389, size = 229.309 MiB)
2026-05-16 23:03:27.457 | slot update_slots: id  2 | task 6699 | erased invalidated context checkpoint (pos_min = 39210, pos_max = 39210, n_tokens = 39211, n_swa = 0, pos_next = 33389, size = 231.745 MiB)
2026-05-16 23:03:27.471 | slot update_slots: id  2 | task 6699 | erased invalidated context checkpoint (pos_min = 39722, pos_max = 39722, n_tokens = 39723, n_swa = 0, pos_next = 33389, size = 232.817 MiB)
2026-05-16 23:03:27.484 | slot update_slots: id  2 | task 6699 | n_tokens = 33389, memory_seq_rm [33389, end)
2026-05-16 23:03:27.485 | slot update_slots: id  2 | task 6699 | prompt processing progress, n_tokens = 35437, batch.n_tokens = 2048, progress = 0.893948
2026-05-16 23:03:28.647 | slot update_slots: id  2 | task 6699 | n_tokens = 35437, memory_seq_rm [35437, end)
2026-05-16 23:03:28.647 | slot update_slots: id  2 | task 6699 | prompt processing progress, n_tokens = 37485, batch.n_tokens = 2048, progress = 0.945612
2026-05-16 23:03:29.624 | slot update_slots: id  2 | task 6699 | n_tokens = 37485, memory_seq_rm [37485, end)
2026-05-16 23:03:29.624 | slot update_slots: id  2 | task 6699 | prompt processing progress, n_tokens = 39125, batch.n_tokens = 1640, progress = 0.986983
2026-05-16 23:03:30.461 | slot update_slots: id  2 | task 6699 | n_tokens = 39125, memory_seq_rm [39125, end)
2026-05-16 23:03:30.461 | slot update_slots: id  2 | task 6699 | prompt processing progress, n_tokens = 39637, batch.n_tokens = 512, progress = 0.999899
2026-05-16 23:03:30.717 | slot create_check: id  2 | task 6699 | created context checkpoint 11 of 32 (pos_min = 39124, pos_max = 39124, n_tokens = 39125, size = 231.564 MiB)
2026-05-16 23:03:30.970 | slot update_slots: id  2 | task 6699 | n_tokens = 39637, memory_seq_rm [39637, end)
2026-05-16 23:03:30.975 | slot init_sampler: id  2 | task 6699 | init sampler, took 5.15 ms, tokens: text = 39641, total = 39641
2026-05-16 23:03:30.975 | slot update_slots: id  2 | task 6699 | prompt processing done, n_tokens = 39641, batch.n_tokens = 4
2026-05-16 23:03:31.238 | slot create_check: id  2 | task 6699 | created context checkpoint 12 of 32 (pos_min = 39636, pos_max = 39636, n_tokens = 39637, size = 232.637 MiB)
2026-05-16 23:03:31.275 | srv  log_server_r: done request: POST /v1/chat/completions 172.18.0.1 200
2026-05-16 23:03:31.730 | reasoning-budget: deactivated (natural end)
2026-05-16 23:03:38.682 | slot print_timing: id  2 | task 6699 | 
2026-05-16 23:03:38.683 | prompt eval time =    3970.76 ms /  6252 tokens (    0.64 ms per token,  1574.51 tokens per second)
2026-05-16 23:03:38.683 |        eval time =    8261.08 ms /   718 tokens (   11.51 ms per token,    86.91 tokens per second)
2026-05-16 23:03:38.683 |       total time =   12231.84 ms /  6970 tokens
2026-05-16 23:03:38.683 | draft acceptance rate = 0.99581 (  475 accepted /   477 generated)
2026-05-16 23:03:38.683 | statistics mtp: #calls(b,g,a) = 41 6417 5349, #gen drafts = 5349, #acc drafts = 5349, #gen tokens = 9447, #acc tokens = 9294, dur(b,g,a) = 0.064, 24498.167, 2.563 ms
2026-05-16 23:03:38.683 | slot      release: id  2 | task 6699 | stop processing: n_tokens = 40358, truncated = 0
2026-05-16 23:03:38.683 | srv  update_slots: all slots are idle
2026-05-16 23:03:38.972 | srv  params_from_: Chat format: peg-native
2026-05-16 23:03:38.975 | slot get_availabl: id  2 | task -1 | selected slot by LCP similarity, sim_best = 0.999 (> 0.100 thold), f_keep = 1.000
2026-05-16 23:03:38.976 | reasoning-budget: activated, budget=2147483647 tokens
2026-05-16 23:03:38.976 | slot launch_slot_: id  2 | task -1 | sampler chain: logits -> penalties -> ?dry -> ?top-n-sigma -> top-k -> ?typical -> ?top-p -> min-p -> ?xtc -> ?temp-ext -> dist 
2026-05-16 23:03:38.976 | slot launch_slot_: id  2 | task 6951 | processing task, is_child = 0
2026-05-16 23:03:38.976 | slot update_slots: id  2 | task 6951 | new prompt, n_ctx_slot = 131072, n_keep = 0, task.n_tokens = 40395
2026-05-16 23:03:38.976 | slot update_slots: id  2 | task 6951 | n_tokens = 40358, memory_seq_rm [40358, end)
2026-05-16 23:03:38.976 | slot update_slots: id  2 | task 6951 | prompt processing progress, n_tokens = 40391, batch.n_tokens = 33, progress = 0.999901
2026-05-16 23:03:39.253 | slot create_check: id  2 | task 6951 | created context checkpoint 13 of 32 (pos_min = 40357, pos_max = 40357, n_tokens = 40358, size = 234.147 MiB)
2026-05-16 23:03:39.299 | slot update_slots: id  2 | task 6951 | n_tokens = 40391, memory_seq_rm [40391, end)
2026-05-16 23:03:39.304 | slot init_sampler: id  2 | task 6951 | init sampler, took 5.22 ms, tokens: text = 40395, total = 40395
2026-05-16 23:03:39.304 | slot update_slots: id  2 | task 6951 | prompt processing done, n_tokens = 40395, batch.n_tokens = 4
2026-05-16 23:03:39.341 | srv  log_server_r: done request: POST /v1/chat/completions 172.18.0.1 200
2026-05-16 23:03:39.803 | reasoning-budget: deactivated (natural end)
2026-05-16 23:03:42.941 | slot print_timing: id  2 | task 6951 | 
2026-05-16 23:03:42.941 | prompt eval time =     364.41 ms /    37 tokens (    9.85 ms per token,   101.53 tokens per second)
2026-05-16 23:03:42.941 |        eval time =    3599.40 ms /   246 tokens (   14.63 ms per token,    68.34 tokens per second)
2026-05-16 23:03:42.941 |       total time =    3963.81 ms /   283 tokens
2026-05-16 23:03:42.941 | draft acceptance rate = 1.00000 (  151 accepted /   151 generated)
2026-05-16 23:03:42.941 | statistics mtp: #calls(b,g,a) = 42 6511 5429, #gen drafts = 5429, #acc drafts = 5429, #gen tokens = 9598, #acc tokens = 9445, dur(b,g,a) = 0.065, 24881.455, 2.604 ms
2026-05-16 23:03:42.942 | slot      release: id  2 | task 6951 | stop processing: n_tokens = 40640, truncated = 0
2026-05-16 23:03:42.942 | srv  update_slots: all slots are idle
2026-05-16 23:03:43.205 | srv  params_from_: Chat format: peg-native
2026-05-16 23:03:43.207 | slot get_availabl: id  2 | task -1 | selected slot by LCP similarity, sim_best = 0.999 (> 0.100 thold), f_keep = 1.000
2026-05-16 23:03:43.209 | reasoning-budget: activated, budget=2147483647 tokens
2026-05-16 23:03:43.209 | slot launch_slot_: id  2 | task -1 | sampler chain: logits -> penalties -> ?dry -> ?top-n-sigma -> top-k -> ?typical -> ?top-p -> min-p -> ?xtc -> ?temp-ext -> dist 
2026-05-16 23:03:43.209 | slot launch_slot_: id  2 | task 7055 | processing task, is_child = 0
2026-05-16 23:03:43.209 | slot update_slots: id  2 | task 7055 | new prompt, n_ctx_slot = 131072, n_keep = 0, task.n_tokens = 40693
2026-05-16 23:03:43.209 | slot update_slots: id  2 | task 7055 | n_tokens = 40640, memory_seq_rm [40640, end)
2026-05-16 23:03:43.209 | slot update_slots: id  2 | task 7055 | prompt processing progress, n_tokens = 40689, batch.n_tokens = 49, progress = 0.999902
2026-05-16 23:03:43.473 | slot create_check: id  2 | task 7055 | created context checkpoint 14 of 32 (pos_min = 40639, pos_max = 40639, n_tokens = 40640, size = 234.737 MiB)
2026-05-16 23:03:43.526 | slot update_slots: id  2 | task 7055 | n_tokens = 40689, memory_seq_rm [40689, end)
2026-05-16 23:03:43.532 | slot init_sampler: id  2 | task 7055 | init sampler, took 5.89 ms, tokens: text = 40693, total = 40693
2026-05-16 23:03:43.532 | slot update_slots: id  2 | task 7055 | prompt processing done, n_tokens = 40693, batch.n_tokens = 4
2026-05-16 23:03:43.572 | srv  log_server_r: done request: POST /v1/chat/completions 172.18.0.1 200
2026-05-16 23:03:43.955 | reasoning-budget: deactivated (natural end)
2026-05-16 23:03:46.472 | slot print_timing: id  2 | task 7055 | 
2026-05-16 23:03:46.472 | prompt eval time =     363.04 ms /    53 tokens (    6.85 ms per token,   145.99 tokens per second)
2026-05-16 23:03:46.472 |        eval time =    2899.75 ms /   203 tokens (   14.28 ms per token,    70.01 tokens per second)
2026-05-16 23:03:46.472 |       total time =    3262.79 ms /   256 tokens
2026-05-16 23:03:46.472 | draft acceptance rate = 1.00000 (  120 accepted /   120 generated)
2026-05-16 23:03:46.472 | statistics mtp: #calls(b,g,a) = 43 6593 5494, #gen drafts = 5494, #acc drafts = 5494, #gen tokens = 9718, #acc tokens = 9565, dur(b,g,a) = 0.066, 25214.980, 2.638 ms
2026-05-16 23:03:46.473 | slot      release: id  2 | task 7055 | stop processing: n_tokens = 40895, truncated = 0
2026-05-16 23:03:46.473 | srv  update_slots: all slots are idle
2026-05-16 23:04:53.412 | srv  params_from_: Chat format: peg-native
2026-05-16 23:04:53.415 | slot get_availabl: id  2 | task -1 | selected slot by LCP similarity, sim_best = 0.955 (> 0.100 thold), f_keep = 0.968
2026-05-16 23:04:53.417 | reasoning-budget: activated, budget=2147483647 tokens
2026-05-16 23:04:53.417 | slot launch_slot_: id  2 | task -1 | sampler chain: logits -> penalties -> ?dry -> ?top-n-sigma -> top-k -> ?typical -> ?top-p -> min-p -> ?xtc -> ?temp-ext -> dist 
2026-05-16 23:04:53.417 | slot launch_slot_: id  2 | task 7142 | processing task, is_child = 0
2026-05-16 23:04:53.417 | slot update_slots: id  2 | task 7142 | new prompt, n_ctx_slot = 131072, n_keep = 0, task.n_tokens = 41440
2026-05-16 23:04:53.417 | slot update_slots: id  2 | task 7142 | n_past = 39579, slot.prompt.tokens.size() = 40895, seq_id = 2, pos_min = 40894, n_swa = 0
2026-05-16 23:04:53.417 | slot update_slots: id  2 | task 7142 | Checking checkpoint with [40639, 40639] against 39579...
2026-05-16 23:04:53.417 | slot update_slots: id  2 | task 7142 | Checking checkpoint with [40357, 40357] against 39579...
2026-05-16 23:04:53.417 | slot update_slots: id  2 | task 7142 | Checking checkpoint with [39636, 39636] against 39579...
2026-05-16 23:04:53.417 | slot update_slots: id  2 | task 7142 | Checking checkpoint with [39124, 39124] against 39579...
2026-05-16 23:04:53.507 | slot update_slots: id  2 | task 7142 | restored context checkpoint (pos_min = 39124, pos_max = 39124, n_tokens = 39125, n_past = 39125, size = 231.564 MiB)
2026-05-16 23:04:53.507 | slot update_slots: id  2 | task 7142 | erased invalidated context checkpoint (pos_min = 39636, pos_max = 39636, n_tokens = 39637, n_swa = 0, pos_next = 39125, size = 232.637 MiB)
2026-05-16 23:04:53.521 | slot update_slots: id  2 | task 7142 | erased invalidated context checkpoint (pos_min = 40357, pos_max = 40357, n_tokens = 40358, n_swa = 0, pos_next = 39125, size = 234.147 MiB)
2026-05-16 23:04:53.535 | slot update_slots: id  2 | task 7142 | erased invalidated context checkpoint (pos_min = 40639, pos_max = 40639, n_tokens = 40640, n_swa = 0, pos_next = 39125, size = 234.737 MiB)
2026-05-16 23:04:53.549 | slot update_slots: id  2 | task 7142 | n_tokens = 39125, memory_seq_rm [39125, end)
2026-05-16 23:04:53.549 | slot update_slots: id  2 | task 7142 | prompt processing progress, n_tokens = 40924, batch.n_tokens = 1799, progress = 0.987548
2026-05-16 23:04:54.614 | slot update_slots: id  2 | task 7142 | n_tokens = 40924, memory_seq_rm [40924, end)
2026-05-16 23:04:54.614 | slot update_slots: id  2 | task 7142 | prompt processing progress, n_tokens = 41436, batch.n_tokens = 512, progress = 0.999904
2026-05-16 23:04:54.836 | slot create_check: id  2 | task 7142 | created context checkpoint 12 of 32 (pos_min = 40923, pos_max = 40923, n_tokens = 40924, size = 235.332 MiB)
2026-05-16 23:04:55.094 | slot update_slots: id  2 | task 7142 | n_tokens = 41436, memory_seq_rm [41436, end)
2026-05-16 23:04:55.100 | slot init_sampler: id  2 | task 7142 | init sampler, took 5.40 ms, tokens: text = 41440, total = 41440
2026-05-16 23:04:55.100 | slot update_slots: id  2 | task 7142 | prompt processing done, n_tokens = 41440, batch.n_tokens = 4
2026-05-16 23:04:55.286 | slot create_check: id  2 | task 7142 | created context checkpoint 13 of 32 (pos_min = 41435, pos_max = 41435, n_tokens = 41436, size = 236.404 MiB)
2026-05-16 23:04:55.325 | srv  log_server_r: done request: POST /v1/chat/completions 172.18.0.1 200
2026-05-16 23:04:56.735 | reasoning-budget: deactivated (natural end)
2026-05-16 23:04:57.957 | slot print_timing: id  2 | task 7142 | 
2026-05-16 23:04:57.957 | prompt eval time =    1907.17 ms /  2315 tokens (    0.82 ms per token,  1213.84 tokens per second)
2026-05-16 23:04:57.957 |        eval time =    2632.87 ms /   189 tokens (   13.93 ms per token,    71.78 tokens per second)
2026-05-16 23:04:57.957 |       total time =    4540.04 ms /  2504 tokens
2026-05-16 23:04:57.957 | draft acceptance rate = 0.99130 (  114 accepted /   115 generated)
2026-05-16 23:04:57.957 | statistics mtp: #calls(b,g,a) = 44 6667 5553, #gen drafts = 5553, #acc drafts = 5553, #gen tokens = 9833, #acc tokens = 9679, dur(b,g,a) = 0.067, 25508.725, 2.670 ms
2026-05-16 23:04:57.958 | slot      release: id  2 | task 7142 | stop processing: n_tokens = 41628, truncated = 0
2026-05-16 23:04:57.958 | srv  update_slots: all slots are idle
2026-05-16 23:04:58.244 | srv  params_from_: Chat format: peg-native
2026-05-16 23:04:58.246 | slot get_availabl: id  2 | task -1 | selected slot by LCP similarity, sim_best = 0.944 (> 0.100 thold), f_keep = 1.000
2026-05-16 23:04:58.248 | reasoning-budget: activated, budget=2147483647 tokens
2026-05-16 23:04:58.248 | slot launch_slot_: id  2 | task -1 | sampler chain: logits -> penalties -> ?dry -> ?top-n-sigma -> top-k -> ?typical -> ?top-p -> min-p -> ?xtc -> ?temp-ext -> dist 
2026-05-16 23:04:58.248 | slot launch_slot_: id  2 | task 7223 | processing task, is_child = 0
2026-05-16 23:04:58.248 | slot update_slots: id  2 | task 7223 | new prompt, n_ctx_slot = 131072, n_keep = 0, task.n_tokens = 44117
2026-05-16 23:04:58.248 | slot update_slots: id  2 | task 7223 | n_tokens = 41628, memory_seq_rm [41628, end)
2026-05-16 23:04:58.248 | slot update_slots: id  2 | task 7223 | prompt processing progress, n_tokens = 43601, batch.n_tokens = 1973, progress = 0.988304
2026-05-16 23:04:59.235 | slot update_slots: id  2 | task 7223 | n_tokens = 43601, memory_seq_rm [43601, end)
2026-05-16 23:04:59.235 | slot update_slots: id  2 | task 7223 | prompt processing progress, n_tokens = 44113, batch.n_tokens = 512, progress = 0.999909
2026-05-16 23:04:59.507 | slot create_check: id  2 | task 7223 | created context checkpoint 14 of 32 (pos_min = 43600, pos_max = 43600, n_tokens = 43601, size = 240.938 MiB)
2026-05-16 23:04:59.774 | slot update_slots: id  2 | task 7223 | n_tokens = 44113, memory_seq_rm [44113, end)
2026-05-16 23:04:59.780 | slot init_sampler: id  2 | task 7223 | init sampler, took 5.75 ms, tokens: text = 44117, total = 44117
2026-05-16 23:04:59.780 | slot update_slots: id  2 | task 7223 | prompt processing done, n_tokens = 44117, batch.n_tokens = 4
2026-05-16 23:05:00.048 | slot create_check: id  2 | task 7223 | created context checkpoint 15 of 32 (pos_min = 44112, pos_max = 44112, n_tokens = 44113, size = 242.011 MiB)
2026-05-16 23:05:00.086 | srv  log_server_r: done request: POST /v1/chat/completions 172.18.0.1 200
2026-05-16 23:05:05.095 | reasoning-budget: deactivated (natural end)
2026-05-16 23:05:10.050 | slot print_timing: id  2 | task 7223 | 
2026-05-16 23:05:10.050 | prompt eval time =    1837.04 ms /  2489 tokens (    0.74 ms per token,  1354.89 tokens per second)
2026-05-16 23:05:10.050 |        eval time =   10817.30 ms /   593 tokens (   18.24 ms per token,    54.82 tokens per second)
2026-05-16 23:05:10.050 |       total time =   12654.34 ms /  3082 tokens
2026-05-16 23:05:10.050 | draft acceptance rate = 0.97840 (  317 accepted /   324 generated)
2026-05-16 23:05:10.050 | statistics mtp: #calls(b,g,a) = 45 6942 5739, #gen drafts = 5739, #acc drafts = 5739, #gen tokens = 10157, #acc tokens = 9996, dur(b,g,a) = 0.069, 26536.201, 2.756 ms
2026-05-16 23:05:10.051 | slot      release: id  2 | task 7223 | stop processing: n_tokens = 44709, truncated = 0
2026-05-16 23:05:10.051 | srv  update_slots: all slots are idle
2026-05-16 23:23:05.017 | srv  params_from_: Chat format: peg-native
2026-05-16 23:23:05.019 | slot get_availabl: id  2 | task -1 | selected slot by LCP similarity, sim_best = 0.900 (> 0.100 thold), f_keep = 0.920
2026-05-16 23:23:05.021 | reasoning-budget: activated, budget=2147483647 tokens
2026-05-16 23:23:05.021 | slot launch_slot_: id  2 | task -1 | sampler chain: logits -> penalties -> ?dry -> ?top-n-sigma -> top-k -> ?typical -> ?top-p -> min-p -> ?xtc -> ?temp-ext -> dist 
2026-05-16 23:23:05.021 | slot launch_slot_: id  2 | task 7528 | processing task, is_child = 0
2026-05-16 23:23:05.021 | slot update_slots: id  2 | task 7528 | new prompt, n_ctx_slot = 131072, n_keep = 0, task.n_tokens = 45689
2026-05-16 23:23:05.021 | slot update_slots: id  2 | task 7528 | n_past = 41125, slot.prompt.tokens.size() = 44709, seq_id = 2, pos_min = 44708, n_swa = 0
2026-05-16 23:23:05.021 | slot update_slots: id  2 | task 7528 | Checking checkpoint with [44112, 44112] against 41125...
2026-05-16 23:23:05.021 | slot update_slots: id  2 | task 7528 | Checking checkpoint with [43600, 43600] against 41125...
2026-05-16 23:23:05.021 | slot update_slots: id  2 | task 7528 | Checking checkpoint with [41435, 41435] against 41125...
2026-05-16 23:23:05.021 | slot update_slots: id  2 | task 7528 | Checking checkpoint with [40923, 40923] against 41125...
2026-05-16 23:23:05.117 | slot update_slots: id  2 | task 7528 | restored context checkpoint (pos_min = 40923, pos_max = 40923, n_tokens = 40924, n_past = 40924, size = 235.332 MiB)
2026-05-16 23:23:05.117 | slot update_slots: id  2 | task 7528 | erased invalidated context checkpoint (pos_min = 41435, pos_max = 41435, n_tokens = 41436, n_swa = 0, pos_next = 40924, size = 236.404 MiB)
2026-05-16 23:23:05.131 | slot update_slots: id  2 | task 7528 | erased invalidated context checkpoint (pos_min = 43600, pos_max = 43600, n_tokens = 43601, n_swa = 0, pos_next = 40924, size = 240.938 MiB)
2026-05-16 23:23:05.145 | slot update_slots: id  2 | task 7528 | erased invalidated context checkpoint (pos_min = 44112, pos_max = 44112, n_tokens = 44113, n_swa = 0, pos_next = 40924, size = 242.011 MiB)
2026-05-16 23:23:05.159 | slot update_slots: id  2 | task 7528 | n_tokens = 40924, memory_seq_rm [40924, end)
2026-05-16 23:23:05.160 | slot update_slots: id  2 | task 7528 | prompt processing progress, n_tokens = 42972, batch.n_tokens = 2048, progress = 0.940533
2026-05-16 23:23:06.392 | slot update_slots: id  2 | task 7528 | n_tokens = 42972, memory_seq_rm [42972, end)
2026-05-16 23:23:06.392 | slot update_slots: id  2 | task 7528 | prompt processing progress, n_tokens = 45020, batch.n_tokens = 2048, progress = 0.985358
2026-05-16 23:23:07.452 | slot update_slots: id  2 | task 7528 | n_tokens = 45020, memory_seq_rm [45020, end)
2026-05-16 23:23:07.452 | slot update_slots: id  2 | task 7528 | prompt processing progress, n_tokens = 45173, batch.n_tokens = 153, progress = 0.988706
2026-05-16 23:23:07.554 | slot update_slots: id  2 | task 7528 | n_tokens = 45173, memory_seq_rm [45173, end)
2026-05-16 23:23:07.554 | slot update_slots: id  2 | task 7528 | prompt processing progress, n_tokens = 45685, batch.n_tokens = 512, progress = 0.999912
2026-05-16 23:23:07.812 | slot create_check: id  2 | task 7528 | created context checkpoint 13 of 32 (pos_min = 45172, pos_max = 45172, n_tokens = 45173, size = 244.231 MiB)
2026-05-16 23:23:08.085 | slot update_slots: id  2 | task 7528 | n_tokens = 45685, memory_seq_rm [45685, end)
2026-05-16 23:23:08.091 | slot init_sampler: id  2 | task 7528 | init sampler, took 5.88 ms, tokens: text = 45689, total = 45689
2026-05-16 23:23:08.091 | slot update_slots: id  2 | task 7528 | prompt processing done, n_tokens = 45689, batch.n_tokens = 4
2026-05-16 23:23:08.368 | slot create_check: id  2 | task 7528 | created context checkpoint 14 of 32 (pos_min = 45684, pos_max = 45684, n_tokens = 45685, size = 245.303 MiB)
2026-05-16 23:23:08.406 | srv  log_server_r: done request: POST /v1/chat/completions 172.18.0.1 200
2026-05-16 23:23:09.467 | reasoning-budget: deactivated (natural end)
2026-05-16 23:23:11.147 | slot print_timing: id  2 | task 7528 | 
2026-05-16 23:23:11.147 | prompt eval time =    3384.39 ms /  4765 tokens (    0.71 ms per token,  1407.94 tokens per second)
2026-05-16 23:23:11.147 |        eval time =    2741.37 ms /   189 tokens (   14.50 ms per token,    68.94 tokens per second)
2026-05-16 23:23:11.147 |       total time =    6125.76 ms /  4954 tokens
2026-05-16 23:23:11.147 | draft acceptance rate = 1.00000 (  114 accepted /   114 generated)
2026-05-16 23:23:11.147 | statistics mtp: #calls(b,g,a) = 46 7016 5802, #gen drafts = 5802, #acc drafts = 5802, #gen tokens = 10271, #acc tokens = 10110, dur(b,g,a) = 0.071, 26846.025, 2.783 ms
2026-05-16 23:23:11.148 | slot      release: id  2 | task 7528 | stop processing: n_tokens = 45877, truncated = 0
2026-05-16 23:23:11.148 | srv  update_slots: all slots are idle
2026-05-16 23:23:11.456 | srv  params_from_: Chat format: peg-native
2026-05-16 23:23:11.459 | slot get_availabl: id  2 | task -1 | selected slot by LCP similarity, sim_best = 0.996 (> 0.100 thold), f_keep = 1.000
2026-05-16 23:23:11.460 | reasoning-budget: activated, budget=2147483647 tokens
2026-05-16 23:23:11.460 | slot launch_slot_: id  2 | task -1 | sampler chain: logits -> penalties -> ?dry -> ?top-n-sigma -> top-k -> ?typical -> ?top-p -> min-p -> ?xtc -> ?temp-ext -> dist 
2026-05-16 23:23:11.460 | slot launch_slot_: id  2 | task 7611 | processing task, is_child = 0
2026-05-16 23:23:11.460 | slot update_slots: id  2 | task 7611 | new prompt, n_ctx_slot = 131072, n_keep = 0, task.n_tokens = 46057
2026-05-16 23:23:11.460 | slot update_slots: id  2 | task 7611 | n_tokens = 45877, memory_seq_rm [45877, end)
2026-05-16 23:23:11.461 | slot update_slots: id  2 | task 7611 | prompt processing progress, n_tokens = 46053, batch.n_tokens = 176, progress = 0.999913
2026-05-16 23:23:11.739 | slot create_check: id  2 | task 7611 | created context checkpoint 15 of 32 (pos_min = 45876, pos_max = 45876, n_tokens = 45877, size = 245.705 MiB)
2026-05-16 23:23:11.859 | slot update_slots: id  2 | task 7611 | n_tokens = 46053, memory_seq_rm [46053, end)
2026-05-16 23:23:11.865 | slot init_sampler: id  2 | task 7611 | init sampler, took 5.99 ms, tokens: text = 46057, total = 46057
2026-05-16 23:23:11.865 | slot update_slots: id  2 | task 7611 | prompt processing done, n_tokens = 46057, batch.n_tokens = 4
2026-05-16 23:23:12.140 | slot create_check: id  2 | task 7611 | created context checkpoint 16 of 32 (pos_min = 46052, pos_max = 46052, n_tokens = 46053, size = 246.074 MiB)
2026-05-16 23:23:12.178 | srv  log_server_r: done request: POST /v1/chat/completions 172.18.0.1 200
2026-05-16 23:23:12.843 | reasoning-budget: deactivated (natural end)
2026-05-16 23:23:14.172 | slot print_timing: id  2 | task 7611 | 
2026-05-16 23:23:14.172 | prompt eval time =     716.84 ms /   180 tokens (    3.98 ms per token,   251.10 tokens per second)
2026-05-16 23:23:14.172 |        eval time =    1993.89 ms /   147 tokens (   13.56 ms per token,    73.73 tokens per second)
2026-05-16 23:23:14.172 |       total time =    2710.73 ms /   327 tokens
2026-05-16 23:23:14.172 | draft acceptance rate = 1.00000 (   92 accepted /    92 generated)
2026-05-16 23:23:14.172 | statistics mtp: #calls(b,g,a) = 47 7070 5851, #gen drafts = 5851, #acc drafts = 5851, #gen tokens = 10363, #acc tokens = 10202, dur(b,g,a) = 0.072, 27077.210, 2.808 ms
2026-05-16 23:23:14.173 | slot      release: id  2 | task 7611 | stop processing: n_tokens = 46203, truncated = 0
2026-05-16 23:23:14.173 | srv  update_slots: all slots are idle
2026-05-16 23:23:14.494 | srv  params_from_: Chat format: peg-native
2026-05-16 23:23:14.497 | slot get_availabl: id  2 | task -1 | selected slot by LCP similarity, sim_best = 0.936 (> 0.100 thold), f_keep = 1.000
2026-05-16 23:23:14.498 | reasoning-budget: activated, budget=2147483647 tokens
2026-05-16 23:23:14.498 | slot launch_slot_: id  2 | task -1 | sampler chain: logits -> penalties -> ?dry -> ?top-n-sigma -> top-k -> ?typical -> ?top-p -> min-p -> ?xtc -> ?temp-ext -> dist 
2026-05-16 23:23:14.498 | slot launch_slot_: id  2 | task 7672 | processing task, is_child = 0
2026-05-16 23:23:14.498 | slot update_slots: id  2 | task 7672 | new prompt, n_ctx_slot = 131072, n_keep = 0, task.n_tokens = 49377
2026-05-16 23:23:14.498 | slot update_slots: id  2 | task 7672 | n_tokens = 46203, memory_seq_rm [46203, end)
2026-05-16 23:23:14.499 | slot update_slots: id  2 | task 7672 | prompt processing progress, n_tokens = 48251, batch.n_tokens = 2048, progress = 0.977196
2026-05-16 23:23:15.599 | slot update_slots: id  2 | task 7672 | n_tokens = 48251, memory_seq_rm [48251, end)
2026-05-16 23:23:15.600 | slot update_slots: id  2 | task 7672 | prompt processing progress, n_tokens = 48861, batch.n_tokens = 610, progress = 0.989550
2026-05-16 23:23:15.980 | slot update_slots: id  2 | task 7672 | n_tokens = 48861, memory_seq_rm [48861, end)
2026-05-16 23:23:15.980 | slot update_slots: id  2 | task 7672 | prompt processing progress, n_tokens = 49373, batch.n_tokens = 512, progress = 0.999919
2026-05-16 23:23:16.263 | slot create_check: id  2 | task 7672 | created context checkpoint 17 of 32 (pos_min = 48860, pos_max = 48860, n_tokens = 48861, size = 251.954 MiB)
2026-05-16 23:23:16.548 | slot update_slots: id  2 | task 7672 | n_tokens = 49373, memory_seq_rm [49373, end)
2026-05-16 23:23:16.555 | slot init_sampler: id  2 | task 7672 | init sampler, took 6.31 ms, tokens: text = 49377, total = 49377
2026-05-16 23:23:16.555 | slot update_slots: id  2 | task 7672 | prompt processing done, n_tokens = 49377, batch.n_tokens = 4
2026-05-16 23:23:16.857 | slot create_check: id  2 | task 7672 | created context checkpoint 18 of 32 (pos_min = 49372, pos_max = 49372, n_tokens = 49373, size = 253.027 MiB)
2026-05-16 23:23:16.896 | srv  log_server_r: done request: POST /v1/chat/completions 172.18.0.1 200
2026-05-16 23:23:21.414 | reasoning-budget: deactivated (natural end)
2026-05-16 23:23:28.292 | slot print_timing: id  2 | task 7672 | 
2026-05-16 23:23:28.292 | prompt eval time =    2396.78 ms /  3174 tokens (    0.76 ms per token,  1324.27 tokens per second)
2026-05-16 23:23:28.292 |        eval time =   11396.60 ms /   657 tokens (   17.35 ms per token,    57.65 tokens per second)
2026-05-16 23:23:28.292 |       total time =   13793.39 ms /  3831 tokens
2026-05-16 23:23:28.292 | draft acceptance rate = 0.98378 (  364 accepted /   370 generated)
2026-05-16 23:23:28.292 | statistics mtp: #calls(b,g,a) = 48 7362 6064, #gen drafts = 6064, #acc drafts = 6064, #gen tokens = 10733, #acc tokens = 10566, dur(b,g,a) = 0.074, 28232.353, 2.908 ms
2026-05-16 23:23:28.293 | slot      release: id  2 | task 7672 | stop processing: n_tokens = 50033, truncated = 0
2026-05-16 23:23:28.293 | srv  update_slots: all slots are idle
2026-05-16 23:24:15.069 | srv  params_from_: Chat format: peg-native
2026-05-16 23:24:15.071 | slot get_availabl: id  2 | task -1 | selected slot by LCP similarity, sim_best = 0.912 (> 0.100 thold), f_keep = 0.907
2026-05-16 23:24:15.073 | reasoning-budget: activated, budget=2147483647 tokens
2026-05-16 23:24:15.073 | slot launch_slot_: id  2 | task -1 | sampler chain: logits -> penalties -> ?dry -> ?top-n-sigma -> top-k -> ?typical -> ?top-p -> min-p -> ?xtc -> ?temp-ext -> dist 
2026-05-16 23:24:15.073 | slot launch_slot_: id  2 | task 7992 | processing task, is_child = 0
2026-05-16 23:24:15.073 | slot update_slots: id  2 | task 7992 | new prompt, n_ctx_slot = 131072, n_keep = 0, task.n_tokens = 49760
2026-05-16 23:24:15.073 | slot update_slots: id  2 | task 7992 | n_past = 45374, slot.prompt.tokens.size() = 50033, seq_id = 2, pos_min = 50032, n_swa = 0
2026-05-16 23:24:15.073 | slot update_slots: id  2 | task 7992 | Checking checkpoint with [49372, 49372] against 45374...
2026-05-16 23:24:15.073 | slot update_slots: id  2 | task 7992 | Checking checkpoint with [48860, 48860] against 45374...
2026-05-16 23:24:15.073 | slot update_slots: id  2 | task 7992 | Checking checkpoint with [46052, 46052] against 45374...
2026-05-16 23:24:15.073 | slot update_slots: id  2 | task 7992 | Checking checkpoint with [45876, 45876] against 45374...
2026-05-16 23:24:15.073 | slot update_slots: id  2 | task 7992 | Checking checkpoint with [45684, 45684] against 45374...
2026-05-16 23:24:15.073 | slot update_slots: id  2 | task 7992 | Checking checkpoint with [45172, 45172] against 45374...
2026-05-16 23:24:15.171 | slot update_slots: id  2 | task 7992 | restored context checkpoint (pos_min = 45172, pos_max = 45172, n_tokens = 45173, n_past = 45173, size = 244.231 MiB)
2026-05-16 23:24:15.171 | slot update_slots: id  2 | task 7992 | erased invalidated context checkpoint (pos_min = 45684, pos_max = 45684, n_tokens = 45685, n_swa = 0, pos_next = 45173, size = 245.303 MiB)
2026-05-16 23:24:15.185 | slot update_slots: id  2 | task 7992 | erased invalidated context checkpoint (pos_min = 45876, pos_max = 45876, n_tokens = 45877, n_swa = 0, pos_next = 45173, size = 245.705 MiB)
2026-05-16 23:24:15.199 | slot update_slots: id  2 | task 7992 | erased invalidated context checkpoint (pos_min = 46052, pos_max = 46052, n_tokens = 46053, n_swa = 0, pos_next = 45173, size = 246.074 MiB)
2026-05-16 23:24:15.213 | slot update_slots: id  2 | task 7992 | erased invalidated context checkpoint (pos_min = 48860, pos_max = 48860, n_tokens = 48861, n_swa = 0, pos_next = 45173, size = 251.954 MiB)
2026-05-16 23:24:15.228 | slot update_slots: id  2 | task 7992 | erased invalidated context checkpoint (pos_min = 49372, pos_max = 49372, n_tokens = 49373, n_swa = 0, pos_next = 45173, size = 253.027 MiB)
2026-05-16 23:24:15.242 | slot update_slots: id  2 | task 7992 | n_tokens = 45173, memory_seq_rm [45173, end)
2026-05-16 23:24:15.243 | slot update_slots: id  2 | task 7992 | prompt processing progress, n_tokens = 47221, batch.n_tokens = 2048, progress = 0.948975
2026-05-16 23:24:16.575 | slot update_slots: id  2 | task 7992 | n_tokens = 47221, memory_seq_rm [47221, end)
2026-05-16 23:24:16.575 | slot update_slots: id  2 | task 7992 | prompt processing progress, n_tokens = 49244, batch.n_tokens = 2023, progress = 0.989630
2026-05-16 23:24:17.683 | slot update_slots: id  2 | task 7992 | n_tokens = 49244, memory_seq_rm [49244, end)
2026-05-16 23:24:17.683 | slot update_slots: id  2 | task 7992 | prompt processing progress, n_tokens = 49756, batch.n_tokens = 512, progress = 0.999920
2026-05-16 23:24:17.953 | slot create_check: id  2 | task 7992 | created context checkpoint 14 of 32 (pos_min = 49243, pos_max = 49243, n_tokens = 49244, size = 252.756 MiB)
2026-05-16 23:24:18.240 | slot update_slots: id  2 | task 7992 | n_tokens = 49756, memory_seq_rm [49756, end)
2026-05-16 23:24:18.247 | slot init_sampler: id  2 | task 7992 | init sampler, took 6.45 ms, tokens: text = 49760, total = 49760
2026-05-16 23:24:18.247 | slot update_slots: id  2 | task 7992 | prompt processing done, n_tokens = 49760, batch.n_tokens = 4
2026-05-16 23:24:18.534 | slot create_check: id  2 | task 7992 | created context checkpoint 15 of 32 (pos_min = 49755, pos_max = 49755, n_tokens = 49756, size = 253.829 MiB)
2026-05-16 23:24:18.574 | srv  log_server_r: done request: POST /v1/chat/completions 172.18.0.1 200
2026-05-16 23:24:21.616 | reasoning-budget: deactivated (natural end)
2026-05-16 23:24:23.326 | slot print_timing: id  2 | task 7992 | 
2026-05-16 23:24:23.326 | prompt eval time =    3500.14 ms /  4587 tokens (    0.76 ms per token,  1310.52 tokens per second)
2026-05-16 23:24:23.326 |        eval time =    4753.11 ms /   308 tokens (   15.43 ms per token,    64.80 tokens per second)
2026-05-16 23:24:23.326 |       total time =    8253.25 ms /  4895 tokens
2026-05-16 23:24:23.326 | draft acceptance rate = 1.00000 (  182 accepted /   182 generated)
2026-05-16 23:24:23.326 | statistics mtp: #calls(b,g,a) = 49 7487 6165, #gen drafts = 6165, #acc drafts = 6165, #gen tokens = 10915, #acc tokens = 10748, dur(b,g,a) = 0.075, 28755.826, 2.964 ms
2026-05-16 23:24:23.328 | slot      release: id  2 | task 7992 | stop processing: n_tokens = 50067, truncated = 0
2026-05-16 23:24:23.328 | srv  update_slots: all slots are idle
2026-05-16 23:24:45.161 | srv  params_from_: Chat format: peg-native
2026-05-16 23:24:45.163 | slot get_availabl: id  2 | task -1 | selected slot by LCP similarity, sim_best = 0.996 (> 0.100 thold), f_keep = 0.988
2026-05-16 23:24:45.164 | reasoning-budget: activated, budget=2147483647 tokens
2026-05-16 23:24:45.165 | slot launch_slot_: id  2 | task -1 | sampler chain: logits -> penalties -> ?dry -> ?top-n-sigma -> top-k -> ?typical -> ?top-p -> min-p -> ?xtc -> ?temp-ext -> dist 
2026-05-16 23:24:45.165 | slot launch_slot_: id  2 | task 8126 | processing task, is_child = 0
2026-05-16 23:24:45.165 | slot update_slots: id  2 | task 8126 | new prompt, n_ctx_slot = 131072, n_keep = 0, task.n_tokens = 49633
2026-05-16 23:24:45.165 | slot update_slots: id  2 | task 8126 | n_past = 49445, slot.prompt.tokens.size() = 50067, seq_id = 2, pos_min = 50066, n_swa = 0
2026-05-16 23:24:45.165 | slot update_slots: id  2 | task 8126 | Checking checkpoint with [49755, 49755] against 49445...
2026-05-16 23:24:45.165 | slot update_slots: id  2 | task 8126 | Checking checkpoint with [49243, 49243] against 49445...
2026-05-16 23:24:45.262 | slot update_slots: id  2 | task 8126 | restored context checkpoint (pos_min = 49243, pos_max = 49243, n_tokens = 49244, n_past = 49244, size = 252.756 MiB)
2026-05-16 23:24:45.262 | slot update_slots: id  2 | task 8126 | erased invalidated context checkpoint (pos_min = 49755, pos_max = 49755, n_tokens = 49756, n_swa = 0, pos_next = 49244, size = 253.829 MiB)
2026-05-16 23:24:45.276 | slot update_slots: id  2 | task 8126 | n_tokens = 49244, memory_seq_rm [49244, end)
2026-05-16 23:24:45.276 | slot update_slots: id  2 | task 8126 | prompt processing progress, n_tokens = 49629, batch.n_tokens = 385, progress = 0.999919
2026-05-16 23:24:45.640 | slot update_slots: id  2 | task 8126 | n_tokens = 49629, memory_seq_rm [49629, end)
2026-05-16 23:24:45.646 | slot init_sampler: id  2 | task 8126 | init sampler, took 6.36 ms, tokens: text = 49633, total = 49633
2026-05-16 23:24:45.646 | slot update_slots: id  2 | task 8126 | prompt processing done, n_tokens = 49633, batch.n_tokens = 4
2026-05-16 23:24:45.829 | slot create_check: id  2 | task 8126 | created context checkpoint 15 of 32 (pos_min = 49628, pos_max = 49628, n_tokens = 49629, size = 253.563 MiB)
2026-05-16 23:24:45.866 | srv  log_server_r: done request: POST /v1/chat/completions 172.18.0.1 200
2026-05-16 23:24:46.153 | reasoning-budget: deactivated (natural end)
2026-05-16 23:24:57.566 | slot print_timing: id  2 | task 8126 | 
2026-05-16 23:24:57.566 | prompt eval time =     701.27 ms /   389 tokens (    1.80 ms per token,   554.71 tokens per second)
2026-05-16 23:24:57.566 |        eval time =   11699.58 ms /   933 tokens (   12.54 ms per token,    79.75 tokens per second)
2026-05-16 23:24:57.566 |       total time =   12400.85 ms /  1322 tokens
2026-05-16 23:24:57.566 | draft acceptance rate = 0.99511 (  610 accepted /   613 generated)
2026-05-16 23:24:57.566 | statistics mtp: #calls(b,g,a) = 50 7809 6477, #gen drafts = 6477, #acc drafts = 6477, #gen tokens = 11528, #acc tokens = 11358, dur(b,g,a) = 0.077, 30188.752, 3.111 ms
2026-05-16 23:24:57.568 | slot      release: id  2 | task 8126 | stop processing: n_tokens = 50565, truncated = 0
2026-05-16 23:24:57.568 | srv  update_slots: all slots are idle
2026-05-16 23:24:57.915 | srv  params_from_: Chat format: peg-native
2026-05-16 23:24:57.918 | slot get_availabl: id  2 | task -1 | selected slot by LCP similarity, sim_best = 0.982 (> 0.100 thold), f_keep = 0.983
2026-05-16 23:24:57.919 | reasoning-budget: activated, budget=2147483647 tokens
2026-05-16 23:24:57.919 | slot launch_slot_: id  2 | task -1 | sampler chain: logits -> penalties -> ?dry -> ?top-n-sigma -> top-k -> ?typical -> ?top-p -> min-p -> ?xtc -> ?temp-ext -> dist 
2026-05-16 23:24:57.919 | slot launch_slot_: id  2 | task 8461 | processing task, is_child = 0
2026-05-16 23:24:57.919 | slot update_slots: id  2 | task 8461 | new prompt, n_ctx_slot = 131072, n_keep = 0, task.n_tokens = 50628
2026-05-16 23:24:57.919 | slot update_slots: id  2 | task 8461 | n_past = 49703, slot.prompt.tokens.size() = 50565, seq_id = 2, pos_min = 50564, n_swa = 0
2026-05-16 23:24:57.919 | slot update_slots: id  2 | task 8461 | Checking checkpoint with [49628, 49628] against 49703...
2026-05-16 23:24:57.961 | slot update_slots: id  2 | task 8461 | restored context checkpoint (pos_min = 49628, pos_max = 49628, n_tokens = 49629, n_past = 49629, size = 253.563 MiB)
2026-05-16 23:24:57.961 | slot update_slots: id  2 | task 8461 | n_tokens = 49629, memory_seq_rm [49629, end)
2026-05-16 23:24:57.961 | slot update_slots: id  2 | task 8461 | prompt processing progress, n_tokens = 50112, batch.n_tokens = 483, progress = 0.989808
2026-05-16 23:24:58.238 | slot update_slots: id  2 | task 8461 | n_tokens = 50112, memory_seq_rm [50112, end)
2026-05-16 23:24:58.238 | slot update_slots: id  2 | task 8461 | prompt processing progress, n_tokens = 50624, batch.n_tokens = 512, progress = 0.999921
2026-05-16 23:24:58.508 | slot create_check: id  2 | task 8461 | created context checkpoint 16 of 32 (pos_min = 50111, pos_max = 50111, n_tokens = 50112, size = 254.574 MiB)
2026-05-16 23:24:58.794 | slot update_slots: id  2 | task 8461 | n_tokens = 50624, memory_seq_rm [50624, end)
2026-05-16 23:24:58.801 | slot init_sampler: id  2 | task 8461 | init sampler, took 6.50 ms, tokens: text = 50628, total = 50628
2026-05-16 23:24:58.801 | slot update_slots: id  2 | task 8461 | prompt processing done, n_tokens = 50628, batch.n_tokens = 4
2026-05-16 23:24:59.087 | slot create_check: id  2 | task 8461 | created context checkpoint 17 of 32 (pos_min = 50623, pos_max = 50623, n_tokens = 50624, size = 255.646 MiB)
2026-05-16 23:24:59.126 | srv  log_server_r: done request: POST /v1/chat/completions 172.18.0.1 200
2026-05-16 23:24:59.536 | reasoning-budget: deactivated (natural end)
2026-05-16 23:25:04.748 | slot print_timing: id  2 | task 8461 | 
2026-05-16 23:25:04.748 | prompt eval time =    1206.18 ms /   999 tokens (    1.21 ms per token,   828.24 tokens per second)
2026-05-16 23:25:04.748 |        eval time =    6045.91 ms /   390 tokens (   15.50 ms per token,    64.51 tokens per second)
2026-05-16 23:25:04.748 |       total time =    7252.09 ms /  1389 tokens
2026-05-16 23:25:04.748 | draft acceptance rate = 1.00000 (  230 accepted /   230 generated)
2026-05-16 23:25:04.748 | statistics mtp: #calls(b,g,a) = 51 7968 6602, #gen drafts = 6602, #acc drafts = 6602, #gen tokens = 11758, #acc tokens = 11588, dur(b,g,a) = 0.079, 30822.971, 3.176 ms
2026-05-16 23:25:04.750 | slot      release: id  2 | task 8461 | stop processing: n_tokens = 51017, truncated = 0
2026-05-16 23:25:04.750 | srv  update_slots: all slots are idle
2026-05-16 23:25:05.104 | srv  params_from_: Chat format: peg-native
2026-05-16 23:25:05.107 | slot get_availabl: id  2 | task -1 | selected slot by LCP similarity, sim_best = 1.000 (> 0.100 thold), f_keep = 1.000
2026-05-16 23:25:05.108 | reasoning-budget: activated, budget=2147483647 tokens
2026-05-16 23:25:05.108 | slot launch_slot_: id  2 | task -1 | sampler chain: logits -> penalties -> ?dry -> ?top-n-sigma -> top-k -> ?typical -> ?top-p -> min-p -> ?xtc -> ?temp-ext -> dist 
2026-05-16 23:25:05.108 | slot launch_slot_: id  2 | task 8631 | processing task, is_child = 0
2026-05-16 23:25:05.108 | slot update_slots: id  2 | task 8631 | new prompt, n_ctx_slot = 131072, n_keep = 0, task.n_tokens = 51036
2026-05-16 23:25:05.108 | slot update_slots: id  2 | task 8631 | n_tokens = 51017, memory_seq_rm [51017, end)
2026-05-16 23:25:05.109 | slot update_slots: id  2 | task 8631 | prompt processing progress, n_tokens = 51032, batch.n_tokens = 15, progress = 0.999922
2026-05-16 23:25:05.375 | slot create_check: id  2 | task 8631 | created context checkpoint 18 of 32 (pos_min = 51016, pos_max = 51016, n_tokens = 51017, size = 256.469 MiB)
2026-05-16 23:25:05.417 | slot update_slots: id  2 | task 8631 | n_tokens = 51032, memory_seq_rm [51032, end)
2026-05-16 23:25:05.423 | slot init_sampler: id  2 | task 8631 | init sampler, took 6.58 ms, tokens: text = 51036, total = 51036
2026-05-16 23:25:05.423 | slot update_slots: id  2 | task 8631 | prompt processing done, n_tokens = 51036, batch.n_tokens = 4
2026-05-16 23:25:05.464 | srv  log_server_r: done request: POST /v1/chat/completions 172.18.0.1 200
2026-05-16 23:25:05.608 | reasoning-budget: deactivated (natural end)
2026-05-16 23:25:08.749 | slot print_timing: id  2 | task 8631 | 
2026-05-16 23:25:08.749 | prompt eval time =     353.74 ms /    19 tokens (   18.62 ms per token,    53.71 tokens per second)
2026-05-16 23:25:08.749 |        eval time =    3286.85 ms /   192 tokens (   17.12 ms per token,    58.41 tokens per second)
2026-05-16 23:25:08.749 |       total time =    3640.59 ms /   211 tokens
2026-05-16 23:25:08.749 | draft acceptance rate = 0.98230 (  111 accepted /   113 generated)
2026-05-16 23:25:08.749 | statistics mtp: #calls(b,g,a) = 52 8048 6666, #gen drafts = 6666, #acc drafts = 6666, #gen tokens = 11871, #acc tokens = 11699, dur(b,g,a) = 0.080, 31155.241, 3.212 ms
2026-05-16 23:25:08.750 | slot      release: id  2 | task 8631 | stop processing: n_tokens = 51227, truncated = 0
2026-05-16 23:25:08.750 | srv  update_slots: all slots are idle
2026-05-16 23:25:09.082 | srv  params_from_: Chat format: peg-native
2026-05-16 23:25:09.084 | slot get_availabl: id  2 | task -1 | selected slot by LCP similarity, sim_best = 0.999 (> 0.100 thold), f_keep = 1.000
2026-05-16 23:25:09.086 | reasoning-budget: activated, budget=2147483647 tokens
2026-05-16 23:25:09.086 | slot launch_slot_: id  2 | task -1 | sampler chain: logits -> penalties -> ?dry -> ?top-n-sigma -> top-k -> ?typical -> ?top-p -> min-p -> ?xtc -> ?temp-ext -> dist 
2026-05-16 23:25:09.086 | slot launch_slot_: id  2 | task 8719 | processing task, is_child = 0
2026-05-16 23:25:09.086 | slot update_slots: id  2 | task 8719 | new prompt, n_ctx_slot = 131072, n_keep = 0, task.n_tokens = 51297
2026-05-16 23:25:09.086 | slot update_slots: id  2 | task 8719 | n_tokens = 51227, memory_seq_rm [51227, end)
2026-05-16 23:25:09.086 | slot update_slots: id  2 | task 8719 | prompt processing progress, n_tokens = 51293, batch.n_tokens = 66, progress = 0.999922
2026-05-16 23:25:09.384 | slot create_check: id  2 | task 8719 | created context checkpoint 19 of 32 (pos_min = 51226, pos_max = 51226, n_tokens = 51227, size = 256.909 MiB)
2026-05-16 23:25:09.447 | slot update_slots: id  2 | task 8719 | n_tokens = 51293, memory_seq_rm [51293, end)
2026-05-16 23:25:09.454 | slot init_sampler: id  2 | task 8719 | init sampler, took 6.58 ms, tokens: text = 51297, total = 51297
2026-05-16 23:25:09.454 | slot update_slots: id  2 | task 8719 | prompt processing done, n_tokens = 51297, batch.n_tokens = 4
2026-05-16 23:25:09.755 | slot create_check: id  2 | task 8719 | created context checkpoint 20 of 32 (pos_min = 51292, pos_max = 51292, n_tokens = 51293, size = 257.047 MiB)
2026-05-16 23:25:09.797 | srv  log_server_r: done request: POST /v1/chat/completions 172.18.0.1 200
2026-05-16 23:25:10.080 | reasoning-budget: deactivated (natural end)
2026-05-16 23:25:12.668 | slot print_timing: id  2 | task 8719 | 
2026-05-16 23:25:12.668 | prompt eval time =     710.15 ms /    70 tokens (   10.15 ms per token,    98.57 tokens per second)
2026-05-16 23:25:12.668 |        eval time =    2872.05 ms /   171 tokens (   16.80 ms per token,    59.54 tokens per second)
2026-05-16 23:25:12.668 |       total time =    3582.20 ms /   241 tokens
2026-05-16 23:25:12.668 | draft acceptance rate = 0.99000 (   99 accepted /   100 generated)
2026-05-16 23:25:12.668 | statistics mtp: #calls(b,g,a) = 53 8119 6720, #gen drafts = 6720, #acc drafts = 6720, #gen tokens = 11971, #acc tokens = 11798, dur(b,g,a) = 0.082, 31450.458, 3.240 ms
2026-05-16 23:25:12.669 | slot      release: id  2 | task 8719 | stop processing: n_tokens = 51467, truncated = 0
2026-05-16 23:25:12.669 | srv  update_slots: all slots are idle
2026-05-16 23:30:14.959 | srv  params_from_: Chat format: peg-native
2026-05-16 23:30:14.962 | slot get_availabl: id  2 | task -1 | selected slot by LCP similarity, sim_best = 0.954 (> 0.100 thold), f_keep = 0.963
2026-05-16 23:30:14.964 | reasoning-budget: activated, budget=2147483647 tokens
2026-05-16 23:30:14.964 | slot launch_slot_: id  2 | task -1 | sampler chain: logits -> penalties -> ?dry -> ?top-n-sigma -> top-k -> ?typical -> ?top-p -> min-p -> ?xtc -> ?temp-ext -> dist 
2026-05-16 23:30:14.964 | slot launch_slot_: id  2 | task 8800 | processing task, is_child = 0
2026-05-16 23:30:14.964 | slot update_slots: id  2 | task 8800 | new prompt, n_ctx_slot = 131072, n_keep = 0, task.n_tokens = 51976
2026-05-16 23:30:14.964 | slot update_slots: id  2 | task 8800 | n_past = 49571, slot.prompt.tokens.size() = 51467, seq_id = 2, pos_min = 51466, n_swa = 0
2026-05-16 23:30:14.964 | slot update_slots: id  2 | task 8800 | Checking checkpoint with [51292, 51292] against 49571...
2026-05-16 23:30:14.964 | slot update_slots: id  2 | task 8800 | Checking checkpoint with [51226, 51226] against 49571...
2026-05-16 23:30:14.964 | slot update_slots: id  2 | task 8800 | Checking checkpoint with [51016, 51016] against 49571...
2026-05-16 23:30:14.964 | slot update_slots: id  2 | task 8800 | Checking checkpoint with [50623, 50623] against 49571...
2026-05-16 23:30:14.964 | slot update_slots: id  2 | task 8800 | Checking checkpoint with [50111, 50111] against 49571...
2026-05-16 23:30:14.964 | slot update_slots: id  2 | task 8800 | Checking checkpoint with [49628, 49628] against 49571...
2026-05-16 23:30:14.964 | slot update_slots: id  2 | task 8800 | Checking checkpoint with [49243, 49243] against 49571...
2026-05-16 23:30:15.065 | slot update_slots: id  2 | task 8800 | restored context checkpoint (pos_min = 49243, pos_max = 49243, n_tokens = 49244, n_past = 49244, size = 252.756 MiB)
2026-05-16 23:30:15.065 | slot update_slots: id  2 | task 8800 | erased invalidated context checkpoint (pos_min = 49628, pos_max = 49628, n_tokens = 49629, n_swa = 0, pos_next = 49244, size = 253.563 MiB)
2026-05-16 23:30:15.080 | slot update_slots: id  2 | task 8800 | erased invalidated context checkpoint (pos_min = 50111, pos_max = 50111, n_tokens = 50112, n_swa = 0, pos_next = 49244, size = 254.574 MiB)
2026-05-16 23:30:15.095 | slot update_slots: id  2 | task 8800 | erased invalidated context checkpoint (pos_min = 50623, pos_max = 50623, n_tokens = 50624, n_swa = 0, pos_next = 49244, size = 255.646 MiB)
2026-05-16 23:30:15.110 | slot update_slots: id  2 | task 8800 | erased invalidated context checkpoint (pos_min = 51016, pos_max = 51016, n_tokens = 51017, n_swa = 0, pos_next = 49244, size = 256.469 MiB)
2026-05-16 23:30:15.131 | slot update_slots: id  2 | task 8800 | erased invalidated context checkpoint (pos_min = 51226, pos_max = 51226, n_tokens = 51227, n_swa = 0, pos_next = 49244, size = 256.909 MiB)
2026-05-16 23:30:15.151 | slot update_slots: id  2 | task 8800 | erased invalidated context checkpoint (pos_min = 51292, pos_max = 51292, n_tokens = 51293, n_swa = 0, pos_next = 49244, size = 257.047 MiB)
2026-05-16 23:30:15.165 | slot update_slots: id  2 | task 8800 | n_tokens = 49244, memory_seq_rm [49244, end)
2026-05-16 23:30:15.166 | slot update_slots: id  2 | task 8800 | prompt processing progress, n_tokens = 51292, batch.n_tokens = 2048, progress = 0.986840
2026-05-16 23:30:16.515 | slot update_slots: id  2 | task 8800 | n_tokens = 51292, memory_seq_rm [51292, end)
2026-05-16 23:30:16.515 | slot update_slots: id  2 | task 8800 | prompt processing progress, n_tokens = 51460, batch.n_tokens = 168, progress = 0.990072
2026-05-16 23:30:16.628 | slot update_slots: id  2 | task 8800 | n_tokens = 51460, memory_seq_rm [51460, end)
2026-05-16 23:30:16.628 | slot update_slots: id  2 | task 8800 | prompt processing progress, n_tokens = 51972, batch.n_tokens = 512, progress = 0.999923
2026-05-16 23:30:16.878 | slot create_check: id  2 | task 8800 | created context checkpoint 15 of 32 (pos_min = 51459, pos_max = 51459, n_tokens = 51460, size = 257.397 MiB)
2026-05-16 23:30:17.173 | slot update_slots: id  2 | task 8800 | n_tokens = 51972, memory_seq_rm [51972, end)
2026-05-16 23:30:17.180 | slot init_sampler: id  2 | task 8800 | init sampler, took 6.83 ms, tokens: text = 51976, total = 51976
2026-05-16 23:30:17.180 | slot update_slots: id  2 | task 8800 | prompt processing done, n_tokens = 51976, batch.n_tokens = 4
2026-05-16 23:30:17.468 | slot create_check: id  2 | task 8800 | created context checkpoint 16 of 32 (pos_min = 51971, pos_max = 51971, n_tokens = 51972, size = 258.470 MiB)
2026-05-16 23:30:17.506 | srv  log_server_r: done request: POST /v1/chat/completions 172.18.0.1 200
2026-05-16 23:30:27.480 | reasoning-budget: deactivated (natural end)
2026-05-16 23:30:34.182 | slot print_timing: id  2 | task 8800 | 
2026-05-16 23:30:34.182 | prompt eval time =    2541.29 ms /  2732 tokens (    0.93 ms per token,  1075.04 tokens per second)
2026-05-16 23:30:34.182 |        eval time =   16997.88 ms /   862 tokens (   19.72 ms per token,    50.71 tokens per second)
2026-05-16 23:30:34.182 |       total time =   19539.17 ms /  3594 tokens
2026-05-16 23:30:34.182 | draft acceptance rate = 0.97448 (  420 accepted /   431 generated)
2026-05-16 23:30:34.182 | statistics mtp: #calls(b,g,a) = 54 8560 6991, #gen drafts = 6991, #acc drafts = 6991, #gen tokens = 12402, #acc tokens = 12218, dur(b,g,a) = 0.083, 33022.565, 3.368 ms
2026-05-16 23:30:34.183 | slot      release: id  2 | task 8800 | stop processing: n_tokens = 52837, truncated = 0
2026-05-16 23:30:34.183 | srv  update_slots: all slots are idle
2026-05-16 23:55:42.390 | srv  params_from_: Chat format: peg-native
2026-05-16 23:55:42.393 | slot get_availabl: id  2 | task -1 | selected slot by LCP similarity, sim_best = 0.916 (> 0.100 thold), f_keep = 0.978
2026-05-16 23:55:42.394 | reasoning-budget: activated, budget=2147483647 tokens
2026-05-16 23:55:42.394 | slot launch_slot_: id  2 | task -1 | sampler chain: logits -> penalties -> ?dry -> ?top-n-sigma -> top-k -> ?typical -> ?top-p -> min-p -> ?xtc -> ?temp-ext -> dist 
2026-05-16 23:55:42.394 | slot launch_slot_: id  2 | task 9280 | processing task, is_child = 0
2026-05-16 23:55:42.394 | slot update_slots: id  2 | task 9280 | new prompt, n_ctx_slot = 131072, n_keep = 0, task.n_tokens = 56415
2026-05-16 23:55:42.394 | slot update_slots: id  2 | task 9280 | n_past = 51661, slot.prompt.tokens.size() = 52837, seq_id = 2, pos_min = 52836, n_swa = 0
2026-05-16 23:55:42.394 | slot update_slots: id  2 | task 9280 | Checking checkpoint with [51971, 51971] against 51661...
2026-05-16 23:55:42.394 | slot update_slots: id  2 | task 9280 | Checking checkpoint with [51459, 51459] against 51661...
2026-05-16 23:55:42.498 | slot update_slots: id  2 | task 9280 | restored context checkpoint (pos_min = 51459, pos_max = 51459, n_tokens = 51460, n_past = 51460, size = 257.397 MiB)
2026-05-16 23:55:42.498 | slot update_slots: id  2 | task 9280 | erased invalidated context checkpoint (pos_min = 51971, pos_max = 51971, n_tokens = 51972, n_swa = 0, pos_next = 51460, size = 258.470 MiB)
2026-05-16 23:55:42.512 | slot update_slots: id  2 | task 9280 | n_tokens = 51460, memory_seq_rm [51460, end)
2026-05-16 23:55:42.513 | slot update_slots: id  2 | task 9280 | prompt processing progress, n_tokens = 53508, batch.n_tokens = 2048, progress = 0.948471
2026-05-16 23:55:43.645 | slot update_slots: id  2 | task 9280 | n_tokens = 53508, memory_seq_rm [53508, end)
2026-05-16 23:55:43.645 | slot update_slots: id  2 | task 9280 | prompt processing progress, n_tokens = 55556, batch.n_tokens = 2048, progress = 0.984774
2026-05-16 23:55:44.813 | slot update_slots: id  2 | task 9280 | n_tokens = 55556, memory_seq_rm [55556, end)
2026-05-16 23:55:44.813 | slot update_slots: id  2 | task 9280 | prompt processing progress, n_tokens = 55899, batch.n_tokens = 343, progress = 0.990853
2026-05-16 23:55:45.041 | slot update_slots: id  2 | task 9280 | n_tokens = 55899, memory_seq_rm [55899, end)
2026-05-16 23:55:45.041 | slot update_slots: id  2 | task 9280 | prompt processing progress, n_tokens = 56411, batch.n_tokens = 512, progress = 0.999929
2026-05-16 23:55:45.274 | slot create_check: id  2 | task 9280 | created context checkpoint 16 of 32 (pos_min = 55898, pos_max = 55898, n_tokens = 55899, size = 266.694 MiB)
2026-05-16 23:55:45.569 | slot update_slots: id  2 | task 9280 | n_tokens = 56411, memory_seq_rm [56411, end)
2026-05-16 23:55:45.577 | slot init_sampler: id  2 | task 9280 | init sampler, took 7.08 ms, tokens: text = 56415, total = 56415
2026-05-16 23:55:45.577 | slot update_slots: id  2 | task 9280 | prompt processing done, n_tokens = 56415, batch.n_tokens = 4
2026-05-16 23:55:45.863 | slot create_check: id  2 | task 9280 | created context checkpoint 17 of 32 (pos_min = 56410, pos_max = 56410, n_tokens = 56411, size = 267.766 MiB)
2026-05-16 23:55:45.902 | srv  log_server_r: done request: POST /v1/chat/completions 172.18.0.1 200
2026-05-16 23:55:58.820 | reasoning-budget: deactivated (natural end)
2026-05-16 23:56:11.122 | slot print_timing: id  2 | task 9280 | 
2026-05-16 23:56:11.122 | prompt eval time =    3722.07 ms /  4955 tokens (    0.75 ms per token,  1331.25 tokens per second)
2026-05-16 23:56:11.122 |        eval time =   25219.90 ms /  1386 tokens (   18.20 ms per token,    54.96 tokens per second)
2026-05-16 23:56:11.122 |       total time =   28941.97 ms /  6341 tokens
2026-05-16 23:56:11.122 | draft acceptance rate = 0.97784 (  750 accepted /   767 generated)
2026-05-16 23:56:11.122 | statistics mtp: #calls(b,g,a) = 55 9195 7429, #gen drafts = 7429, #acc drafts = 7429, #gen tokens = 13169, #acc tokens = 12968, dur(b,g,a) = 0.085, 35488.301, 3.581 ms
2026-05-16 23:56:11.123 | slot      release: id  2 | task 9280 | stop processing: n_tokens = 57800, truncated = 0
2026-05-16 23:56:11.123 | srv  update_slots: all slots are idle
2026-05-16 23:57:55.215 | srv  params_from_: Chat format: peg-native
2026-05-16 23:57:55.218 | slot get_availabl: id  2 | task -1 | selected slot by LCP similarity, sim_best = 0.982 (> 0.100 thold), f_keep = 0.971
2026-05-16 23:57:55.219 | reasoning-budget: activated, budget=2147483647 tokens
2026-05-16 23:57:55.219 | slot launch_slot_: id  2 | task -1 | sampler chain: logits -> penalties -> ?dry -> ?top-n-sigma -> top-k -> ?typical -> ?top-p -> min-p -> ?xtc -> ?temp-ext -> dist 
2026-05-16 23:57:55.219 | slot launch_slot_: id  2 | task 9971 | processing task, is_child = 0
2026-05-16 23:57:55.219 | slot update_slots: id  2 | task 9971 | new prompt, n_ctx_slot = 131072, n_keep = 0, task.n_tokens = 57110
2026-05-16 23:57:55.219 | slot update_slots: id  2 | task 9971 | n_past = 56100, slot.prompt.tokens.size() = 57800, seq_id = 2, pos_min = 57799, n_swa = 0
2026-05-16 23:57:55.219 | slot update_slots: id  2 | task 9971 | Checking checkpoint with [56410, 56410] against 56100...
2026-05-16 23:57:55.219 | slot update_slots: id  2 | task 9971 | Checking checkpoint with [55898, 55898] against 56100...
2026-05-16 23:57:55.327 | slot update_slots: id  2 | task 9971 | restored context checkpoint (pos_min = 55898, pos_max = 55898, n_tokens = 55899, n_past = 55899, size = 266.694 MiB)
2026-05-16 23:57:55.327 | slot update_slots: id  2 | task 9971 | erased invalidated context checkpoint (pos_min = 56410, pos_max = 56410, n_tokens = 56411, n_swa = 0, pos_next = 55899, size = 267.766 MiB)
2026-05-16 23:57:55.342 | slot update_slots: id  2 | task 9971 | n_tokens = 55899, memory_seq_rm [55899, end)
2026-05-16 23:57:55.343 | slot update_slots: id  2 | task 9971 | prompt processing progress, n_tokens = 56594, batch.n_tokens = 695, progress = 0.990965
2026-05-16 23:57:55.891 | slot update_slots: id  2 | task 9971 | n_tokens = 56594, memory_seq_rm [56594, end)
2026-05-16 23:57:55.891 | slot update_slots: id  2 | task 9971 | prompt processing progress, n_tokens = 57106, batch.n_tokens = 512, progress = 0.999930
2026-05-16 23:57:56.096 | slot create_check: id  2 | task 9971 | created context checkpoint 17 of 32 (pos_min = 56593, pos_max = 56593, n_tokens = 56594, size = 268.149 MiB)
2026-05-16 23:57:56.407 | slot update_slots: id  2 | task 9971 | n_tokens = 57106, memory_seq_rm [57106, end)
2026-05-16 23:57:56.414 | slot init_sampler: id  2 | task 9971 | init sampler, took 7.71 ms, tokens: text = 57110, total = 57110
2026-05-16 23:57:56.414 | slot update_slots: id  2 | task 9971 | prompt processing done, n_tokens = 57110, batch.n_tokens = 4
2026-05-16 23:57:56.685 | slot create_check: id  2 | task 9971 | created context checkpoint 18 of 32 (pos_min = 57105, pos_max = 57105, n_tokens = 57106, size = 269.221 MiB)
2026-05-16 23:57:56.724 | srv  log_server_r: done request: POST /v1/chat/completions 172.18.0.1 200
2026-05-16 23:58:04.426 | reasoning-budget: deactivated (natural end)
2026-05-16 23:58:07.528 | slot print_timing: id  2 | task 9971 | 
2026-05-16 23:58:07.528 | prompt eval time =    1504.57 ms /  1211 tokens (    1.24 ms per token,   804.88 tokens per second)
2026-05-16 23:58:07.528 |        eval time =   10804.17 ms /   520 tokens (   20.78 ms per token,    48.13 tokens per second)
2026-05-16 23:58:07.528 |       total time =   12308.74 ms /  1731 tokens
2026-05-16 23:58:07.528 | draft acceptance rate = 0.96863 (  247 accepted /   255 generated)
2026-05-16 23:58:07.528 | statistics mtp: #calls(b,g,a) = 56 9467 7594, #gen drafts = 7594, #acc drafts = 7594, #gen tokens = 13424, #acc tokens = 13215, dur(b,g,a) = 0.087, 36486.484, 3.668 ms
2026-05-16 23:58:07.529 | slot      release: id  2 | task 9971 | stop processing: n_tokens = 57629, truncated = 0
2026-05-16 23:58:07.529 | srv  update_slots: all slots are idle
2026-05-16 23:58:33.913 | srv  params_from_: Chat format: peg-native
2026-05-16 23:58:33.916 | slot get_availabl: id  2 | task -1 | selected slot by LCP similarity, sim_best = 0.996 (> 0.100 thold), f_keep = 0.986
2026-05-16 23:58:33.917 | reasoning-budget: activated, budget=2147483647 tokens
2026-05-16 23:58:33.917 | slot launch_slot_: id  2 | task -1 | sampler chain: logits -> penalties -> ?dry -> ?top-n-sigma -> top-k -> ?typical -> ?top-p -> min-p -> ?xtc -> ?temp-ext -> dist 
2026-05-16 23:58:33.917 | slot launch_slot_: id  2 | task 10262 | processing task, is_child = 0
2026-05-16 23:58:33.917 | slot update_slots: id  2 | task 10262 | new prompt, n_ctx_slot = 131072, n_keep = 0, task.n_tokens = 57033
2026-05-16 23:58:33.917 | slot update_slots: id  2 | task 10262 | n_past = 56795, slot.prompt.tokens.size() = 57629, seq_id = 2, pos_min = 57628, n_swa = 0
2026-05-16 23:58:33.917 | slot update_slots: id  2 | task 10262 | Checking checkpoint with [57105, 57105] against 56795...
2026-05-16 23:58:33.917 | slot update_slots: id  2 | task 10262 | Checking checkpoint with [56593, 56593] against 56795...
2026-05-16 23:58:34.022 | slot update_slots: id  2 | task 10262 | restored context checkpoint (pos_min = 56593, pos_max = 56593, n_tokens = 56594, n_past = 56594, size = 268.149 MiB)
2026-05-16 23:58:34.022 | slot update_slots: id  2 | task 10262 | erased invalidated context checkpoint (pos_min = 57105, pos_max = 57105, n_tokens = 57106, n_swa = 0, pos_next = 56594, size = 269.221 MiB)
2026-05-16 23:58:34.037 | slot update_slots: id  2 | task 10262 | n_tokens = 56594, memory_seq_rm [56594, end)
2026-05-16 23:58:34.038 | slot update_slots: id  2 | task 10262 | prompt processing progress, n_tokens = 57029, batch.n_tokens = 435, progress = 0.999930
2026-05-16 23:58:34.414 | slot update_slots: id  2 | task 10262 | n_tokens = 57029, memory_seq_rm [57029, end)
2026-05-16 23:58:34.421 | slot init_sampler: id  2 | task 10262 | init sampler, took 7.26 ms, tokens: text = 57033, total = 57033
2026-05-16 23:58:34.421 | slot update_slots: id  2 | task 10262 | prompt processing done, n_tokens = 57033, batch.n_tokens = 4
2026-05-16 23:58:34.624 | slot create_check: id  2 | task 10262 | created context checkpoint 18 of 32 (pos_min = 57028, pos_max = 57028, n_tokens = 57029, size = 269.060 MiB)
2026-05-16 23:58:34.664 | srv  log_server_r: done request: POST /v1/chat/completions 172.18.0.1 200
2026-05-16 23:58:37.109 | reasoning-budget: deactivated (natural end)
2026-05-16 23:58:44.017 | slot print_timing: id  2 | task 10262 | 
2026-05-16 23:58:44.017 | prompt eval time =     746.42 ms /   439 tokens (    1.70 ms per token,   588.14 tokens per second)
2026-05-16 23:58:44.017 |        eval time =    9603.13 ms /   712 tokens (   13.49 ms per token,    74.14 tokens per second)
2026-05-16 23:58:44.017 |       total time =   10349.55 ms /  1151 tokens
2026-05-16 23:58:44.017 | draft acceptance rate = 0.98908 (  453 accepted /   458 generated)
2026-05-16 23:58:44.017 | statistics mtp: #calls(b,g,a) = 57 9725 7829, #gen drafts = 7829, #acc drafts = 7829, #gen tokens = 13882, #acc tokens = 13668, dur(b,g,a) = 0.088, 37621.273, 3.798 ms
2026-05-16 23:58:44.018 | slot      release: id  2 | task 10262 | stop processing: n_tokens = 57744, truncated = 0
2026-05-16 23:58:44.018 | srv  update_slots: all slots are idle
2026-05-16 23:58:44.350 | srv  params_from_: Chat format: peg-native
2026-05-16 23:58:44.352 | slot get_availabl: id  2 | task -1 | selected slot by LCP similarity, sim_best = 0.964 (> 0.100 thold), f_keep = 1.000
2026-05-16 23:58:44.353 | reasoning-budget: activated, budget=2147483647 tokens
2026-05-16 23:58:44.354 | slot launch_slot_: id  2 | task -1 | sampler chain: logits -> penalties -> ?dry -> ?top-n-sigma -> top-k -> ?typical -> ?top-p -> min-p -> ?xtc -> ?temp-ext -> dist 
2026-05-16 23:58:44.354 | slot launch_slot_: id  2 | task 10533 | processing task, is_child = 0
2026-05-16 23:58:44.354 | slot update_slots: id  2 | task 10533 | new prompt, n_ctx_slot = 131072, n_keep = 0, task.n_tokens = 59918
2026-05-16 23:58:44.354 | slot update_slots: id  2 | task 10533 | n_tokens = 57744, memory_seq_rm [57744, end)
2026-05-16 23:58:44.354 | slot update_slots: id  2 | task 10533 | prompt processing progress, n_tokens = 59402, batch.n_tokens = 1658, progress = 0.991388
2026-05-16 23:58:45.355 | slot update_slots: id  2 | task 10533 | n_tokens = 59402, memory_seq_rm [59402, end)
2026-05-16 23:58:45.355 | slot update_slots: id  2 | task 10533 | prompt processing progress, n_tokens = 59914, batch.n_tokens = 512, progress = 0.999933
2026-05-16 23:58:45.643 | slot create_check: id  2 | task 10533 | created context checkpoint 19 of 32 (pos_min = 59401, pos_max = 59401, n_tokens = 59402, size = 274.030 MiB)
2026-05-16 23:58:45.956 | slot update_slots: id  2 | task 10533 | n_tokens = 59914, memory_seq_rm [59914, end)
2026-05-16 23:58:45.963 | slot init_sampler: id  2 | task 10533 | init sampler, took 7.49 ms, tokens: text = 59918, total = 59918
2026-05-16 23:58:45.963 | slot update_slots: id  2 | task 10533 | prompt processing done, n_tokens = 59918, batch.n_tokens = 4
2026-05-16 23:58:46.265 | slot create_check: id  2 | task 10533 | created context checkpoint 20 of 32 (pos_min = 59913, pos_max = 59913, n_tokens = 59914, size = 275.102 MiB)
2026-05-16 23:58:46.303 | srv  log_server_r: done request: POST /v1/chat/completions 172.18.0.1 200
2026-05-16 23:58:50.739 | reasoning-budget: deactivated (natural end)
2026-05-16 23:58:52.003 | slot print_timing: id  2 | task 10533 | 
2026-05-16 23:58:52.003 | prompt eval time =    1948.90 ms /  2174 tokens (    0.90 ms per token,  1115.50 tokens per second)
2026-05-16 23:58:52.003 |        eval time =    5700.24 ms /   341 tokens (   16.72 ms per token,    59.82 tokens per second)
2026-05-16 23:58:52.003 |       total time =    7649.14 ms /  2515 tokens
2026-05-16 23:58:52.003 | draft acceptance rate = 0.98974 (  193 accepted /   195 generated)
2026-05-16 23:58:52.003 | statistics mtp: #calls(b,g,a) = 58 9872 7938, #gen drafts = 7938, #acc drafts = 7938, #gen tokens = 14077, #acc tokens = 13861, dur(b,g,a) = 0.089, 38203.698, 3.868 ms
2026-05-16 23:58:52.004 | slot      release: id  2 | task 10533 | stop processing: n_tokens = 60258, truncated = 0
2026-05-16 23:58:52.004 | srv  update_slots: all slots are idle
2026-05-16 23:58:52.353 | srv  params_from_: Chat format: peg-native
2026-05-16 23:58:52.355 | slot get_availabl: id  2 | task -1 | selected slot by LCP similarity, sim_best = 0.976 (> 0.100 thold), f_keep = 1.000
2026-05-16 23:58:52.357 | reasoning-budget: activated, budget=2147483647 tokens
2026-05-16 23:58:52.357 | slot launch_slot_: id  2 | task -1 | sampler chain: logits -> penalties -> ?dry -> ?top-n-sigma -> top-k -> ?typical -> ?top-p -> min-p -> ?xtc -> ?temp-ext -> dist 
2026-05-16 23:58:52.357 | slot launch_slot_: id  2 | task 10697 | processing task, is_child = 0
2026-05-16 23:58:52.357 | slot update_slots: id  2 | task 10697 | new prompt, n_ctx_slot = 131072, n_keep = 0, task.n_tokens = 61765
2026-05-16 23:58:52.357 | slot update_slots: id  2 | task 10697 | n_tokens = 60258, memory_seq_rm [60258, end)
2026-05-16 23:58:52.357 | slot update_slots: id  2 | task 10697 | prompt processing progress, n_tokens = 61249, batch.n_tokens = 991, progress = 0.991646
2026-05-16 23:58:52.941 | slot update_slots: id  2 | task 10697 | n_tokens = 61249, memory_seq_rm [61249, end)
2026-05-16 23:58:52.941 | slot update_slots: id  2 | task 10697 | prompt processing progress, n_tokens = 61761, batch.n_tokens = 512, progress = 0.999935
2026-05-16 23:58:53.177 | slot create_check: id  2 | task 10697 | created context checkpoint 21 of 32 (pos_min = 61248, pos_max = 61248, n_tokens = 61249, size = 277.898 MiB)
2026-05-16 23:58:53.504 | slot update_slots: id  2 | task 10697 | n_tokens = 61761, memory_seq_rm [61761, end)
2026-05-16 23:58:53.512 | slot init_sampler: id  2 | task 10697 | init sampler, took 7.85 ms, tokens: text = 61765, total = 61765
2026-05-16 23:58:53.512 | slot update_slots: id  2 | task 10697 | prompt processing done, n_tokens = 61765, batch.n_tokens = 4
2026-05-16 23:58:53.824 | slot create_check: id  2 | task 10697 | created context checkpoint 22 of 32 (pos_min = 61760, pos_max = 61760, n_tokens = 61761, size = 278.970 MiB)
2026-05-16 23:58:53.864 | srv  log_server_r: done request: POST /v1/chat/completions 172.18.0.1 200
2026-05-16 23:58:54.903 | reasoning-budget: deactivated (natural end)
2026-05-16 23:58:56.237 | slot print_timing: id  2 | task 10697 | 
2026-05-16 23:58:56.237 | prompt eval time =    1506.92 ms /  1507 tokens (    1.00 ms per token,  1000.06 tokens per second)
2026-05-16 23:58:56.237 |        eval time =    2372.48 ms /   150 tokens (   15.82 ms per token,    63.23 tokens per second)
2026-05-16 23:58:56.237 |       total time =    3879.39 ms /  1657 tokens
2026-05-16 23:58:56.237 | draft acceptance rate = 1.00000 (   86 accepted /    86 generated)
2026-05-16 23:58:56.237 | statistics mtp: #calls(b,g,a) = 59 9935 7986, #gen drafts = 7986, #acc drafts = 7986, #gen tokens = 14163, #acc tokens = 13947, dur(b,g,a) = 0.091, 38457.868, 3.894 ms
2026-05-16 23:58:56.238 | slot      release: id  2 | task 10697 | stop processing: n_tokens = 61914, truncated = 0
2026-05-16 23:58:56.238 | srv  update_slots: all slots are idle
2026-05-16 23:58:56.619 | srv  params_from_: Chat format: peg-native
2026-05-16 23:58:56.621 | slot get_availabl: id  2 | task -1 | selected slot by LCP similarity, sim_best = 1.000 (> 0.100 thold), f_keep = 1.000
2026-05-16 23:58:56.622 | reasoning-budget: activated, budget=2147483647 tokens
2026-05-16 23:58:56.623 | slot launch_slot_: id  2 | task -1 | sampler chain: logits -> penalties -> ?dry -> ?top-n-sigma -> top-k -> ?typical -> ?top-p -> min-p -> ?xtc -> ?temp-ext -> dist 
2026-05-16 23:58:56.623 | slot launch_slot_: id  2 | task 10765 | processing task, is_child = 0
2026-05-16 23:58:56.623 | slot update_slots: id  2 | task 10765 | new prompt, n_ctx_slot = 131072, n_keep = 0, task.n_tokens = 61932
2026-05-16 23:58:56.623 | slot update_slots: id  2 | task 10765 | n_tokens = 61914, memory_seq_rm [61914, end)
2026-05-16 23:58:56.623 | slot update_slots: id  2 | task 10765 | prompt processing progress, n_tokens = 61928, batch.n_tokens = 14, progress = 0.999935
2026-05-16 23:58:56.931 | slot create_check: id  2 | task 10765 | created context checkpoint 23 of 32 (pos_min = 61913, pos_max = 61913, n_tokens = 61914, size = 279.291 MiB)
2026-05-16 23:58:56.973 | slot update_slots: id  2 | task 10765 | n_tokens = 61928, memory_seq_rm [61928, end)
2026-05-16 23:58:56.981 | slot init_sampler: id  2 | task 10765 | init sampler, took 7.89 ms, tokens: text = 61932, total = 61932
2026-05-16 23:58:56.981 | slot update_slots: id  2 | task 10765 | prompt processing done, n_tokens = 61932, batch.n_tokens = 4
2026-05-16 23:58:57.020 | srv  log_server_r: done request: POST /v1/chat/completions 172.18.0.1 200
2026-05-16 23:58:57.452 | reasoning-budget: deactivated (natural end)
2026-05-16 23:59:28.795 | slot print_timing: id  2 | task 10765 | 
2026-05-16 23:59:28.795 | prompt eval time =     396.39 ms /    18 tokens (   22.02 ms per token,    45.41 tokens per second)
2026-05-16 23:59:28.795 |        eval time =   32029.82 ms /  2589 tokens (   12.37 ms per token,    80.83 tokens per second)
2026-05-16 23:59:28.795 |       total time =   32426.22 ms /  2607 tokens
2026-05-16 23:59:28.795 | draft acceptance rate = 0.99766 ( 1709 accepted /  1713 generated)
2026-05-16 23:59:28.795 | statistics mtp: #calls(b,g,a) = 60 10814 8851, #gen drafts = 8851, #acc drafts = 8851, #gen tokens = 15876, #acc tokens = 15656, dur(b,g,a) = 0.092, 42505.904, 4.327 ms
2026-05-16 23:59:28.796 | slot      release: id  2 | task 10765 | stop processing: n_tokens = 64520, truncated = 0
2026-05-16 23:59:28.796 | srv  update_slots: all slots are idle
2026-05-16 23:59:29.225 | srv  params_from_: Chat format: peg-native
2026-05-16 23:59:29.227 | slot get_availabl: id  2 | task -1 | selected slot by LCP similarity, sim_best = 0.959 (> 0.100 thold), f_keep = 0.960
2026-05-16 23:59:29.229 | reasoning-budget: activated, budget=2147483647 tokens
2026-05-16 23:59:29.229 | slot launch_slot_: id  2 | task -1 | sampler chain: logits -> penalties -> ?dry -> ?top-n-sigma -> top-k -> ?typical -> ?top-p -> min-p -> ?xtc -> ?temp-ext -> dist 
2026-05-16 23:59:29.229 | slot launch_slot_: id  2 | task 11658 | processing task, is_child = 0
2026-05-16 23:59:29.229 | slot update_slots: id  2 | task 11658 | new prompt, n_ctx_slot = 131072, n_keep = 0, task.n_tokens = 64641
2026-05-16 23:59:29.229 | slot update_slots: id  2 | task 11658 | n_past = 61971, slot.prompt.tokens.size() = 64520, seq_id = 2, pos_min = 64519, n_swa = 0
2026-05-16 23:59:29.229 | slot update_slots: id  2 | task 11658 | Checking checkpoint with [61913, 61913] against 61971...
2026-05-16 23:59:29.276 | slot update_slots: id  2 | task 11658 | restored context checkpoint (pos_min = 61913, pos_max = 61913, n_tokens = 61914, n_past = 61914, size = 279.291 MiB)
2026-05-16 23:59:29.276 | slot update_slots: id  2 | task 11658 | n_tokens = 61914, memory_seq_rm [61914, end)
2026-05-16 23:59:29.277 | slot update_slots: id  2 | task 11658 | prompt processing progress, n_tokens = 63962, batch.n_tokens = 2048, progress = 0.989496
2026-05-16 23:59:30.612 | slot update_slots: id  2 | task 11658 | n_tokens = 63962, memory_seq_rm [63962, end)
2026-05-16 23:59:30.612 | slot update_slots: id  2 | task 11658 | prompt processing progress, n_tokens = 64125, batch.n_tokens = 163, progress = 0.992017
2026-05-16 23:59:30.735 | slot update_slots: id  2 | task 11658 | n_tokens = 64125, memory_seq_rm [64125, end)
2026-05-16 23:59:30.735 | slot update_slots: id  2 | task 11658 | prompt processing progress, n_tokens = 64637, batch.n_tokens = 512, progress = 0.999938
2026-05-16 23:59:31.051 | slot create_check: id  2 | task 11658 | created context checkpoint 24 of 32 (pos_min = 64124, pos_max = 64124, n_tokens = 64125, size = 283.921 MiB)
2026-05-16 23:59:31.393 | slot update_slots: id  2 | task 11658 | n_tokens = 64637, memory_seq_rm [64637, end)
2026-05-16 23:59:31.402 | slot init_sampler: id  2 | task 11658 | init sampler, took 8.52 ms, tokens: text = 64641, total = 64641
2026-05-16 23:59:31.402 | slot update_slots: id  2 | task 11658 | prompt processing done, n_tokens = 64641, batch.n_tokens = 4
2026-05-16 23:59:31.723 | slot create_check: id  2 | task 11658 | created context checkpoint 25 of 32 (pos_min = 64636, pos_max = 64636, n_tokens = 64637, size = 284.993 MiB)
2026-05-16 23:59:31.763 | srv  log_server_r: done request: POST /v1/chat/completions 172.18.0.1 200
2026-05-16 23:59:32.172 | reasoning-budget: deactivated (natural end)
2026-05-16 23:59:50.007 | slot print_timing: id  2 | task 11658 | 
2026-05-16 23:59:50.008 | prompt eval time =    2533.55 ms /  2727 tokens (    0.93 ms per token,  1076.35 tokens per second)
2026-05-16 23:59:50.008 |        eval time =   18463.60 ms /  1252 tokens (   14.75 ms per token,    67.81 tokens per second)
2026-05-16 23:59:50.008 |       total time =   20997.15 ms /  3979 tokens
2026-05-16 23:59:50.008 | draft acceptance rate = 0.98496 (  786 accepted /   798 generated)
2026-05-16 23:59:50.008 | statistics mtp: #calls(b,g,a) = 61 11279 9274, #gen drafts = 9274, #acc drafts = 9274, #gen tokens = 16674, #acc tokens = 16442, dur(b,g,a) = 0.093, 44557.801, 4.536 ms
2026-05-16 23:59:50.009 | slot      release: id  2 | task 11658 | stop processing: n_tokens = 65892, truncated = 0
2026-05-16 23:59:50.009 | srv  update_slots: all slots are idle
2026-05-16 23:59:50.429 | srv  params_from_: Chat format: peg-native
2026-05-16 23:59:50.431 | slot get_availabl: id  2 | task -1 | selected slot by LCP similarity, sim_best = 1.000 (> 0.100 thold), f_keep = 1.000
2026-05-16 23:59:50.432 | reasoning-budget: activated, budget=2147483647 tokens
2026-05-16 23:59:50.432 | slot launch_slot_: id  2 | task -1 | sampler chain: logits -> penalties -> ?dry -> ?top-n-sigma -> top-k -> ?typical -> ?top-p -> min-p -> ?xtc -> ?temp-ext -> dist 
2026-05-16 23:59:50.432 | slot launch_slot_: id  2 | task 12151 | processing task, is_child = 0
2026-05-16 23:59:50.432 | slot update_slots: id  2 | task 12151 | new prompt, n_ctx_slot = 131072, n_keep = 0, task.n_tokens = 65913
2026-05-16 23:59:50.432 | slot update_slots: id  2 | task 12151 | n_tokens = 65892, memory_seq_rm [65892, end)
2026-05-16 23:59:50.433 | slot update_slots: id  2 | task 12151 | prompt processing progress, n_tokens = 65909, batch.n_tokens = 17, progress = 0.999939
2026-05-16 23:59:50.755 | slot create_check: id  2 | task 12151 | created context checkpoint 26 of 32 (pos_min = 65891, pos_max = 65891, n_tokens = 65892, size = 287.622 MiB)
2026-05-16 23:59:50.800 | slot update_slots: id  2 | task 12151 | n_tokens = 65909, memory_seq_rm [65909, end)
2026-05-16 23:59:50.809 | slot init_sampler: id  2 | task 12151 | init sampler, took 8.91 ms, tokens: text = 65913, total = 65913
2026-05-16 23:59:50.809 | slot update_slots: id  2 | task 12151 | prompt processing done, n_tokens = 65913, batch.n_tokens = 4
2026-05-16 23:59:50.848 | srv  log_server_r: done request: POST /v1/chat/completions 172.18.0.1 200
2026-05-16 23:59:51.489 | reasoning-budget: deactivated (natural end)
2026-05-17 00:00:37.431 | slot print_timing: id  2 | task 12151 | 
2026-05-17 00:00:37.431 | prompt eval time =     414.82 ms /    21 tokens (   19.75 ms per token,    50.62 tokens per second)
2026-05-17 00:00:37.431 |        eval time =   46835.69 ms /  2951 tokens (   15.87 ms per token,    63.01 tokens per second)
2026-05-17 00:00:37.431 |       total time =   47250.51 ms /  2972 tokens
2026-05-17 00:00:37.431 | draft acceptance rate = 0.98795 ( 1803 accepted /  1825 generated)
2026-05-17 00:00:37.431 | statistics mtp: #calls(b,g,a) = 62 12426 10257, #gen drafts = 10257, #acc drafts = 10257, #gen tokens = 18499, #acc tokens = 18245, dur(b,g,a) = 0.094, 49540.922, 5.080 ms
2026-05-17 00:00:37.433 | slot      release: id  2 | task 12151 | stop processing: n_tokens = 68863, truncated = 0
2026-05-17 00:00:37.433 | srv  update_slots: all slots are idle
2026-05-17 00:00:37.910 | srv  params_from_: Chat format: peg-native
2026-05-17 00:00:37.913 | slot get_availabl: id  2 | task -1 | selected slot by LCP similarity, sim_best = 0.117 (> 0.100 thold), f_keep = 0.117
2026-05-17 00:00:37.913 | srv  get_availabl: updating prompt cache
2026-05-17 00:00:37.915 | srv   prompt_save:  - saving prompt with length 68863, total state size = 2581.624 MiB (draft: 144.218 MiB)
2026-05-17 00:00:47.179 | srv          load:  - looking for better prompt, base f_keep = 0.117, sim = 0.117
2026-05-17 00:00:47.179 | srv        update:  - cache size limit reached, removing oldest entry (size = 520.787 MiB)
2026-05-17 00:00:47.209 | srv        update:  - cache size limit reached, removing oldest entry (size = 697.797 MiB)
2026-05-17 00:00:47.250 | srv        update:  - cache state: 1 prompts, 8835.769 MiB (limits: 8192.000 MiB, 131072 tokens, 131072 est)
2026-05-17 00:00:47.250 | srv        update:    - prompt 0x590a33303010:   68863 tokens, checkpoints: 26,  8835.769 MiB
2026-05-17 00:00:47.250 | srv  get_availabl: prompt cache update took 9549.66 ms
2026-05-17 00:00:47.251 | reasoning-budget: activated, budget=2147483647 tokens
2026-05-17 00:00:47.251 | slot launch_slot_: id  2 | task -1 | sampler chain: logits -> penalties -> ?dry -> ?top-n-sigma -> top-k -> ?typical -> ?top-p -> min-p -> ?xtc -> ?temp-ext -> dist 
2026-05-17 00:00:47.251 | slot launch_slot_: id  2 | task 13361 | processing task, is_child = 0
2026-05-17 00:00:47.251 | slot update_slots: id  2 | task 13361 | new prompt, n_ctx_slot = 131072, n_keep = 0, task.n_tokens = 68884
2026-05-17 00:00:47.251 | slot update_slots: id  2 | task 13361 | n_past = 8072, slot.prompt.tokens.size() = 68863, seq_id = 2, pos_min = 68862, n_swa = 0
2026-05-17 00:00:47.251 | slot update_slots: id  2 | task 13361 | Checking checkpoint with [65891, 65891] against 8072...
2026-05-17 00:00:47.251 | slot update_slots: id  2 | task 13361 | Checking checkpoint with [64636, 64636] against 8072...
2026-05-17 00:00:47.251 | slot update_slots: id  2 | task 13361 | Checking checkpoint with [64124, 64124] against 8072...
2026-05-17 00:00:47.251 | slot update_slots: id  2 | task 13361 | Checking checkpoint with [61913, 61913] against 8072...
2026-05-17 00:00:47.251 | slot update_slots: id  2 | task 13361 | Checking checkpoint with [61760, 61760] against 8072...
2026-05-17 00:00:47.251 | slot update_slots: id  2 | task 13361 | Checking checkpoint with [61248, 61248] against 8072...
2026-05-17 00:00:47.251 | slot update_slots: id  2 | task 13361 | Checking checkpoint with [59913, 59913] against 8072...
2026-05-17 00:00:47.251 | slot update_slots: id  2 | task 13361 | Checking checkpoint with [59401, 59401] against 8072...
2026-05-17 00:00:47.251 | slot update_slots: id  2 | task 13361 | Checking checkpoint with [57028, 57028] against 8072...
2026-05-17 00:00:47.251 | slot update_slots: id  2 | task 13361 | Checking checkpoint with [56593, 56593] against 8072...
2026-05-17 00:00:47.251 | slot update_slots: id  2 | task 13361 | Checking checkpoint with [55898, 55898] against 8072...
2026-05-17 00:00:47.251 | slot update_slots: id  2 | task 13361 | Checking checkpoint with [51459, 51459] against 8072...
2026-05-17 00:00:47.251 | slot update_slots: id  2 | task 13361 | Checking checkpoint with [49243, 49243] against 8072...
2026-05-17 00:00:47.251 | slot update_slots: id  2 | task 13361 | Checking checkpoint with [45172, 45172] against 8072...
2026-05-17 00:00:47.251 | slot update_slots: id  2 | task 13361 | Checking checkpoint with [40923, 40923] against 8072...
2026-05-17 00:00:47.251 | slot update_slots: id  2 | task 13361 | Checking checkpoint with [39124, 39124] against 8072...
2026-05-17 00:00:47.251 | slot update_slots: id  2 | task 13361 | Checking checkpoint with [33388, 33388] against 8072...
2026-05-17 00:00:47.251 | slot update_slots: id  2 | task 13361 | Checking checkpoint with [31586, 31586] against 8072...
2026-05-17 00:00:47.251 | slot update_slots: id  2 | task 13361 | Checking checkpoint with [29679, 29679] against 8072...
2026-05-17 00:00:47.251 | slot update_slots: id  2 | task 13361 | Checking checkpoint with [28938, 28938] against 8072...
2026-05-17 00:00:47.251 | slot update_slots: id  2 | task 13361 | Checking checkpoint with [24987, 24987] against 8072...
2026-05-17 00:00:47.251 | slot update_slots: id  2 | task 13361 | Checking checkpoint with [24175, 24175] against 8072...
2026-05-17 00:00:47.251 | slot update_slots: id  2 | task 13361 | Checking checkpoint with [23516, 23516] against 8072...
2026-05-17 00:00:47.251 | slot update_slots: id  2 | task 13361 | Checking checkpoint with [17619, 17619] against 8072...
2026-05-17 00:00:47.251 | slot update_slots: id  2 | task 13361 | Checking checkpoint with [12151, 12151] against 8072...
2026-05-17 00:00:47.251 | slot update_slots: id  2 | task 13361 | Checking checkpoint with [8339, 8339] against 8072...
2026-05-17 00:00:47.251 | slot update_slots: id  2 | task 13361 | forcing full prompt re-processing due to lack of cache data (likely due to SWA or hybrid/recurrent memory, see https://github.com/ggml-org/llama.cpp/pull/13194#issuecomment-2868343055)
2026-05-17 00:00:47.251 | slot update_slots: id  2 | task 13361 | erased invalidated context checkpoint (pos_min = 8339, pos_max = 8339, n_tokens = 8340, n_swa = 0, pos_next = 0, size = 167.092 MiB)
2026-05-17 00:00:47.261 | slot update_slots: id  2 | task 13361 | erased invalidated context checkpoint (pos_min = 12151, pos_max = 12151, n_tokens = 12152, n_swa = 0, pos_next = 0, size = 175.076 MiB)
2026-05-17 00:00:47.270 | slot update_slots: id  2 | task 13361 | erased invalidated context checkpoint (pos_min = 17619, pos_max = 17619, n_tokens = 17620, n_swa = 0, pos_next = 0, size = 186.527 MiB)
2026-05-17 00:00:47.281 | slot update_slots: id  2 | task 13361 | erased invalidated context checkpoint (pos_min = 23516, pos_max = 23516, n_tokens = 23517, n_swa = 0, pos_next = 0, size = 198.877 MiB)
2026-05-17 00:00:47.294 | slot update_slots: id  2 | task 13361 | erased invalidated context checkpoint (pos_min = 24175, pos_max = 24175, n_tokens = 24176, n_swa = 0, pos_next = 0, size = 200.257 MiB)
2026-05-17 00:00:47.306 | slot update_slots: id  2 | task 13361 | erased invalidated context checkpoint (pos_min = 24987, pos_max = 24987, n_tokens = 24988, n_swa = 0, pos_next = 0, size = 201.958 MiB)
2026-05-17 00:00:47.319 | slot update_slots: id  2 | task 13361 | erased invalidated context checkpoint (pos_min = 28938, pos_max = 28938, n_tokens = 28939, n_swa = 0, pos_next = 0, size = 210.232 MiB)
2026-05-17 00:00:47.332 | slot update_slots: id  2 | task 13361 | erased invalidated context checkpoint (pos_min = 29679, pos_max = 29679, n_tokens = 29680, n_swa = 0, pos_next = 0, size = 211.784 MiB)
2026-05-17 00:00:47.344 | slot update_slots: id  2 | task 13361 | erased invalidated context checkpoint (pos_min = 31586, pos_max = 31586, n_tokens = 31587, n_swa = 0, pos_next = 0, size = 215.778 MiB)
2026-05-17 00:00:47.358 | slot update_slots: id  2 | task 13361 | erased invalidated context checkpoint (pos_min = 33388, pos_max = 33388, n_tokens = 33389, n_swa = 0, pos_next = 0, size = 219.552 MiB)
2026-05-17 00:00:47.372 | slot update_slots: id  2 | task 13361 | erased invalidated context checkpoint (pos_min = 39124, pos_max = 39124, n_tokens = 39125, n_swa = 0, pos_next = 0, size = 231.564 MiB)
2026-05-17 00:00:47.386 | slot update_slots: id  2 | task 13361 | erased invalidated context checkpoint (pos_min = 40923, pos_max = 40923, n_tokens = 40924, n_swa = 0, pos_next = 0, size = 235.332 MiB)
2026-05-17 00:00:47.400 | slot update_slots: id  2 | task 13361 | erased invalidated context checkpoint (pos_min = 45172, pos_max = 45172, n_tokens = 45173, n_swa = 0, pos_next = 0, size = 244.231 MiB)
2026-05-17 00:00:47.415 | slot update_slots: id  2 | task 13361 | erased invalidated context checkpoint (pos_min = 49243, pos_max = 49243, n_tokens = 49244, n_swa = 0, pos_next = 0, size = 252.756 MiB)
2026-05-17 00:00:47.431 | slot update_slots: id  2 | task 13361 | erased invalidated context checkpoint (pos_min = 51459, pos_max = 51459, n_tokens = 51460, n_swa = 0, pos_next = 0, size = 257.397 MiB)
2026-05-17 00:00:47.447 | slot update_slots: id  2 | task 13361 | erased invalidated context checkpoint (pos_min = 55898, pos_max = 55898, n_tokens = 55899, n_swa = 0, pos_next = 0, size = 266.694 MiB)
2026-05-17 00:00:47.466 | slot update_slots: id  2 | task 13361 | erased invalidated context checkpoint (pos_min = 56593, pos_max = 56593, n_tokens = 56594, n_swa = 0, pos_next = 0, size = 268.149 MiB)
2026-05-17 00:00:47.484 | slot update_slots: id  2 | task 13361 | erased invalidated context checkpoint (pos_min = 57028, pos_max = 57028, n_tokens = 57029, n_swa = 0, pos_next = 0, size = 269.060 MiB)
2026-05-17 00:00:47.501 | slot update_slots: id  2 | task 13361 | erased invalidated context checkpoint (pos_min = 59401, pos_max = 59401, n_tokens = 59402, n_swa = 0, pos_next = 0, size = 274.030 MiB)
2026-05-17 00:00:47.518 | slot update_slots: id  2 | task 13361 | erased invalidated context checkpoint (pos_min = 59913, pos_max = 59913, n_tokens = 59914, n_swa = 0, pos_next = 0, size = 275.102 MiB)
2026-05-17 00:00:47.534 | slot update_slots: id  2 | task 13361 | erased invalidated context checkpoint (pos_min = 61248, pos_max = 61248, n_tokens = 61249, n_swa = 0, pos_next = 0, size = 277.898 MiB)
2026-05-17 00:00:47.551 | slot update_slots: id  2 | task 13361 | erased invalidated context checkpoint (pos_min = 61760, pos_max = 61760, n_tokens = 61761, n_swa = 0, pos_next = 0, size = 278.970 MiB)
2026-05-17 00:00:47.568 | slot update_slots: id  2 | task 13361 | erased invalidated context checkpoint (pos_min = 61913, pos_max = 61913, n_tokens = 61914, n_swa = 0, pos_next = 0, size = 279.291 MiB)
2026-05-17 00:00:47.584 | slot update_slots: id  2 | task 13361 | erased invalidated context checkpoint (pos_min = 64124, pos_max = 64124, n_tokens = 64125, n_swa = 0, pos_next = 0, size = 283.921 MiB)
2026-05-17 00:00:47.601 | slot update_slots: id  2 | task 13361 | erased invalidated context checkpoint (pos_min = 64636, pos_max = 64636, n_tokens = 64637, n_swa = 0, pos_next = 0, size = 284.993 MiB)
2026-05-17 00:00:47.618 | slot update_slots: id  2 | task 13361 | erased invalidated context checkpoint (pos_min = 65891, pos_max = 65891, n_tokens = 65892, n_swa = 0, pos_next = 0, size = 287.622 MiB)
2026-05-17 00:00:47.635 | slot update_slots: id  2 | task 13361 | n_tokens = 0, memory_seq_rm [0, end)
2026-05-17 00:00:47.649 | slot update_slots: id  2 | task 13361 | prompt processing progress, n_tokens = 2048, batch.n_tokens = 2048, progress = 0.029731
2026-05-17 00:00:48.385 | slot update_slots: id  2 | task 13361 | n_tokens = 2048, memory_seq_rm [2048, end)
2026-05-17 00:00:48.385 | slot update_slots: id  2 | task 13361 | prompt processing progress, n_tokens = 4096, batch.n_tokens = 2048, progress = 0.059462
2026-05-17 00:00:49.123 | slot update_slots: id  2 | task 13361 | n_tokens = 4096, memory_seq_rm [4096, end)
2026-05-17 00:00:49.123 | slot update_slots: id  2 | task 13361 | prompt processing progress, n_tokens = 6144, batch.n_tokens = 2048, progress = 0.089193
2026-05-17 00:00:49.856 | slot update_slots: id  2 | task 13361 | n_tokens = 6144, memory_seq_rm [6144, end)
2026-05-17 00:00:49.856 | slot update_slots: id  2 | task 13361 | prompt processing progress, n_tokens = 8192, batch.n_tokens = 2048, progress = 0.118925
2026-05-17 00:00:50.603 | slot update_slots: id  2 | task 13361 | n_tokens = 8192, memory_seq_rm [8192, end)
2026-05-17 00:00:50.603 | slot update_slots: id  2 | task 13361 | 8192 tokens since last checkpoint at 0, creating new checkpoint during processing at position 10240
2026-05-17 00:00:50.603 | slot update_slots: id  2 | task 13361 | prompt processing progress, n_tokens = 10240, batch.n_tokens = 2048, progress = 0.148656
2026-05-17 00:00:50.730 | slot create_check: id  2 | task 13361 | created context checkpoint 1 of 32 (pos_min = 8191, pos_max = 8191, n_tokens = 8192, size = 166.782 MiB)
2026-05-17 00:00:51.486 | slot update_slots: id  2 | task 13361 | n_tokens = 10240, memory_seq_rm [10240, end)
2026-05-17 00:00:51.486 | slot update_slots: id  2 | task 13361 | prompt processing progress, n_tokens = 12288, batch.n_tokens = 2048, progress = 0.178387
2026-05-17 00:00:52.259 | slot update_slots: id  2 | task 13361 | n_tokens = 12288, memory_seq_rm [12288, end)
2026-05-17 00:00:52.259 | slot update_slots: id  2 | task 13361 | prompt processing progress, n_tokens = 14336, batch.n_tokens = 2048, progress = 0.208118
2026-05-17 00:00:53.053 | slot update_slots: id  2 | task 13361 | n_tokens = 14336, memory_seq_rm [14336, end)
2026-05-17 00:00:53.053 | slot update_slots: id  2 | task 13361 | prompt processing progress, n_tokens = 16384, batch.n_tokens = 2048, progress = 0.237849
2026-05-17 00:00:53.851 | slot update_slots: id  2 | task 13361 | n_tokens = 16384, memory_seq_rm [16384, end)
2026-05-17 00:00:53.852 | slot update_slots: id  2 | task 13361 | 8192 tokens since last checkpoint at 8192, creating new checkpoint during processing at position 18432
2026-05-17 00:00:53.852 | slot update_slots: id  2 | task 13361 | prompt processing progress, n_tokens = 18432, batch.n_tokens = 2048, progress = 0.267580
2026-05-17 00:00:53.999 | slot create_check: id  2 | task 13361 | created context checkpoint 2 of 32 (pos_min = 16383, pos_max = 16383, n_tokens = 16384, size = 183.939 MiB)
2026-05-17 00:00:54.827 | slot update_slots: id  2 | task 13361 | n_tokens = 18432, memory_seq_rm [18432, end)
2026-05-17 00:00:54.828 | slot update_slots: id  2 | task 13361 | prompt processing progress, n_tokens = 20480, batch.n_tokens = 2048, progress = 0.297311
2026-05-17 00:00:55.658 | slot update_slots: id  2 | task 13361 | n_tokens = 20480, memory_seq_rm [20480, end)
2026-05-17 00:00:55.658 | slot update_slots: id  2 | task 13361 | prompt processing progress, n_tokens = 22528, batch.n_tokens = 2048, progress = 0.327043
2026-05-17 00:00:56.492 | slot update_slots: id  2 | task 13361 | n_tokens = 22528, memory_seq_rm [22528, end)
2026-05-17 00:00:56.492 | slot update_slots: id  2 | task 13361 | prompt processing progress, n_tokens = 24576, batch.n_tokens = 2048, progress = 0.356774
2026-05-17 00:00:57.342 | slot update_slots: id  2 | task 13361 | n_tokens = 24576, memory_seq_rm [24576, end)
2026-05-17 00:00:57.342 | slot update_slots: id  2 | task 13361 | 8192 tokens since last checkpoint at 16384, creating new checkpoint during processing at position 26624
2026-05-17 00:00:57.342 | slot update_slots: id  2 | task 13361 | prompt processing progress, n_tokens = 26624, batch.n_tokens = 2048, progress = 0.386505
2026-05-17 00:00:57.497 | slot create_check: id  2 | task 13361 | created context checkpoint 3 of 32 (pos_min = 24575, pos_max = 24575, n_tokens = 24576, size = 201.095 MiB)
2026-05-17 00:00:58.361 | slot update_slots: id  2 | task 13361 | n_tokens = 26624, memory_seq_rm [26624, end)
2026-05-17 00:00:58.361 | slot update_slots: id  2 | task 13361 | prompt processing progress, n_tokens = 28672, batch.n_tokens = 2048, progress = 0.416236
2026-05-17 00:00:59.246 | slot update_slots: id  2 | task 13361 | n_tokens = 28672, memory_seq_rm [28672, end)
2026-05-17 00:00:59.246 | slot update_slots: id  2 | task 13361 | prompt processing progress, n_tokens = 30720, batch.n_tokens = 2048, progress = 0.445967
2026-05-17 00:01:00.149 | slot update_slots: id  2 | task 13361 | n_tokens = 30720, memory_seq_rm [30720, end)
2026-05-17 00:01:00.149 | slot update_slots: id  2 | task 13361 | prompt processing progress, n_tokens = 32768, batch.n_tokens = 2048, progress = 0.475698
2026-05-17 00:01:01.075 | slot update_slots: id  2 | task 13361 | n_tokens = 32768, memory_seq_rm [32768, end)
2026-05-17 00:01:01.075 | slot update_slots: id  2 | task 13361 | 8192 tokens since last checkpoint at 24576, creating new checkpoint during processing at position 34816
2026-05-17 00:01:01.075 | slot update_slots: id  2 | task 13361 | prompt processing progress, n_tokens = 34816, batch.n_tokens = 2048, progress = 0.505429
2026-05-17 00:01:01.244 | slot create_check: id  2 | task 13361 | created context checkpoint 4 of 32 (pos_min = 32767, pos_max = 32767, n_tokens = 32768, size = 218.251 MiB)
2026-05-17 00:01:02.188 | slot update_slots: id  2 | task 13361 | n_tokens = 34816, memory_seq_rm [34816, end)
2026-05-17 00:01:02.188 | slot update_slots: id  2 | task 13361 | prompt processing progress, n_tokens = 36864, batch.n_tokens = 2048, progress = 0.535161
2026-05-17 00:01:03.155 | slot update_slots: id  2 | task 13361 | n_tokens = 36864, memory_seq_rm [36864, end)
2026-05-17 00:01:03.155 | slot update_slots: id  2 | task 13361 | prompt processing progress, n_tokens = 38912, batch.n_tokens = 2048, progress = 0.564892
2026-05-17 00:01:04.142 | slot update_slots: id  2 | task 13361 | n_tokens = 38912, memory_seq_rm [38912, end)
2026-05-17 00:01:04.142 | slot update_slots: id  2 | task 13361 | prompt processing progress, n_tokens = 40960, batch.n_tokens = 2048, progress = 0.594623
2026-05-17 00:01:05.152 | slot update_slots: id  2 | task 13361 | n_tokens = 40960, memory_seq_rm [40960, end)
2026-05-17 00:01:05.152 | slot update_slots: id  2 | task 13361 | 8192 tokens since last checkpoint at 32768, creating new checkpoint during processing at position 43008
2026-05-17 00:01:05.152 | slot update_slots: id  2 | task 13361 | prompt processing progress, n_tokens = 43008, batch.n_tokens = 2048, progress = 0.624354
2026-05-17 00:01:05.331 | slot create_check: id  2 | task 13361 | created context checkpoint 5 of 32 (pos_min = 40959, pos_max = 40959, n_tokens = 40960, size = 235.407 MiB)
2026-05-17 00:01:06.364 | slot update_slots: id  2 | task 13361 | n_tokens = 43008, memory_seq_rm [43008, end)
2026-05-17 00:01:06.364 | slot update_slots: id  2 | task 13361 | prompt processing progress, n_tokens = 45056, batch.n_tokens = 2048, progress = 0.654085
2026-05-17 00:01:07.425 | slot update_slots: id  2 | task 13361 | n_tokens = 45056, memory_seq_rm [45056, end)
2026-05-17 00:01:07.425 | slot update_slots: id  2 | task 13361 | prompt processing progress, n_tokens = 47104, batch.n_tokens = 2048, progress = 0.683816
2026-05-17 00:01:08.520 | slot update_slots: id  2 | task 13361 | n_tokens = 47104, memory_seq_rm [47104, end)
2026-05-17 00:01:08.521 | slot update_slots: id  2 | task 13361 | prompt processing progress, n_tokens = 49152, batch.n_tokens = 2048, progress = 0.713547
2026-05-17 00:01:09.643 | slot update_slots: id  2 | task 13361 | n_tokens = 49152, memory_seq_rm [49152, end)
2026-05-17 00:01:09.643 | slot update_slots: id  2 | task 13361 | 8192 tokens since last checkpoint at 40960, creating new checkpoint during processing at position 51200
2026-05-17 00:01:09.643 | slot update_slots: id  2 | task 13361 | prompt processing progress, n_tokens = 51200, batch.n_tokens = 2048, progress = 0.743279
2026-05-17 00:01:09.836 | slot create_check: id  2 | task 13361 | created context checkpoint 6 of 32 (pos_min = 49151, pos_max = 49151, n_tokens = 49152, size = 252.564 MiB)
2026-05-17 00:01:10.986 | slot update_slots: id  2 | task 13361 | n_tokens = 51200, memory_seq_rm [51200, end)
2026-05-17 00:01:10.986 | slot update_slots: id  2 | task 13361 | prompt processing progress, n_tokens = 53248, batch.n_tokens = 2048, progress = 0.773010
2026-05-17 00:01:11.902 | slot update_slots: id  2 | task 13361 | n_tokens = 53248, memory_seq_rm [53248, end)
2026-05-17 00:01:11.902 | slot update_slots: id  2 | task 13361 | prompt processing progress, n_tokens = 55296, batch.n_tokens = 2048, progress = 0.802741
2026-05-17 00:01:13.068 | slot update_slots: id  2 | task 13361 | n_tokens = 55296, memory_seq_rm [55296, end)
2026-05-17 00:01:13.069 | slot update_slots: id  2 | task 13361 | prompt processing progress, n_tokens = 57344, batch.n_tokens = 2048, progress = 0.832472
2026-05-17 00:01:14.259 | slot update_slots: id  2 | task 13361 | n_tokens = 57344, memory_seq_rm [57344, end)
2026-05-17 00:01:14.259 | slot update_slots: id  2 | task 13361 | 8192 tokens since last checkpoint at 49152, creating new checkpoint during processing at position 59392
2026-05-17 00:01:14.259 | slot update_slots: id  2 | task 13361 | prompt processing progress, n_tokens = 59392, batch.n_tokens = 2048, progress = 0.862203
2026-05-17 00:01:14.459 | slot create_check: id  2 | task 13361 | created context checkpoint 7 of 32 (pos_min = 57343, pos_max = 57343, n_tokens = 57344, size = 269.720 MiB)
2026-05-17 00:01:15.683 | slot update_slots: id  2 | task 13361 | n_tokens = 59392, memory_seq_rm [59392, end)
2026-05-17 00:01:15.683 | slot update_slots: id  2 | task 13361 | prompt processing progress, n_tokens = 61440, batch.n_tokens = 2048, progress = 0.891934
2026-05-17 00:01:16.958 | slot update_slots: id  2 | task 13361 | n_tokens = 61440, memory_seq_rm [61440, end)
2026-05-17 00:01:16.959 | slot update_slots: id  2 | task 13361 | prompt processing progress, n_tokens = 63488, batch.n_tokens = 2048, progress = 0.921665
2026-05-17 00:01:18.266 | slot update_slots: id  2 | task 13361 | n_tokens = 63488, memory_seq_rm [63488, end)
2026-05-17 00:01:18.266 | slot update_slots: id  2 | task 13361 | prompt processing progress, n_tokens = 65536, batch.n_tokens = 2048, progress = 0.951397
2026-05-17 00:01:19.613 | slot update_slots: id  2 | task 13361 | n_tokens = 65536, memory_seq_rm [65536, end)
2026-05-17 00:01:19.613 | slot update_slots: id  2 | task 13361 | 8192 tokens since last checkpoint at 57344, creating new checkpoint during processing at position 67584
2026-05-17 00:01:19.613 | slot update_slots: id  2 | task 13361 | prompt processing progress, n_tokens = 67584, batch.n_tokens = 2048, progress = 0.981128
2026-05-17 00:01:19.933 | slot create_check: id  2 | task 13361 | created context checkpoint 8 of 32 (pos_min = 65535, pos_max = 65535, n_tokens = 65536, size = 286.876 MiB)
2026-05-17 00:01:21.312 | slot update_slots: id  2 | task 13361 | n_tokens = 67584, memory_seq_rm [67584, end)
2026-05-17 00:01:21.312 | slot update_slots: id  2 | task 13361 | prompt processing progress, n_tokens = 68368, batch.n_tokens = 784, progress = 0.992509
2026-05-17 00:01:21.841 | slot update_slots: id  2 | task 13361 | n_tokens = 68368, memory_seq_rm [68368, end)
2026-05-17 00:01:21.841 | slot update_slots: id  2 | task 13361 | prompt processing progress, n_tokens = 68880, batch.n_tokens = 512, progress = 0.999942
2026-05-17 00:01:22.172 | slot create_check: id  2 | task 13361 | created context checkpoint 9 of 32 (pos_min = 68367, pos_max = 68367, n_tokens = 68368, size = 292.807 MiB)
2026-05-17 00:01:22.531 | slot update_slots: id  2 | task 13361 | n_tokens = 68880, memory_seq_rm [68880, end)
2026-05-17 00:01:22.540 | slot init_sampler: id  2 | task 13361 | init sampler, took 9.02 ms, tokens: text = 68884, total = 68884
2026-05-17 00:01:22.540 | slot update_slots: id  2 | task 13361 | prompt processing done, n_tokens = 68884, batch.n_tokens = 4
2026-05-17 00:01:22.874 | slot create_check: id  2 | task 13361 | created context checkpoint 10 of 32 (pos_min = 68879, pos_max = 68879, n_tokens = 68880, size = 293.879 MiB)
2026-05-17 00:01:22.916 | srv  log_server_r: done request: POST /v1/chat/completions 172.18.0.1 200
2026-05-17 00:01:23.256 | reasoning-budget: deactivated (natural end)
2026-05-17 00:01:24.826 | slot print_timing: id  2 | task 13361 | 
2026-05-17 00:01:24.826 | prompt eval time =   35908.69 ms / 68884 tokens (    0.52 ms per token,  1918.31 tokens per second)
2026-05-17 00:01:24.826 |        eval time =    1911.03 ms /   137 tokens (   13.95 ms per token,    71.69 tokens per second)
2026-05-17 00:01:24.826 |       total time =   37819.72 ms / 69021 tokens
2026-05-17 00:01:24.826 | draft acceptance rate = 1.00000 (   86 accepted /    86 generated)
2026-05-17 00:01:24.826 | statistics mtp: #calls(b,g,a) = 63 12476 10302, #gen drafts = 10302, #acc drafts = 10302, #gen tokens = 18585, #acc tokens = 18331, dur(b,g,a) = 0.095, 49765.742, 5.103 ms
2026-05-17 00:01:24.828 | slot      release: id  2 | task 13361 | stop processing: n_tokens = 69020, truncated = 0
2026-05-17 00:01:24.828 | srv  update_slots: all slots are idle
2026-05-17 00:01:25.274 | srv  params_from_: Chat format: peg-native
2026-05-17 00:01:25.276 | slot get_availabl: id  2 | task -1 | selected slot by LCP similarity, sim_best = 1.000 (> 0.100 thold), f_keep = 1.000
2026-05-17 00:01:25.278 | reasoning-budget: activated, budget=2147483647 tokens
2026-05-17 00:01:25.278 | slot launch_slot_: id  2 | task -1 | sampler chain: logits -> penalties -> ?dry -> ?top-n-sigma -> top-k -> ?typical -> ?top-p -> min-p -> ?xtc -> ?temp-ext -> dist 
2026-05-17 00:01:25.278 | slot launch_slot_: id  2 | task 13448 | processing task, is_child = 0
2026-05-17 00:01:25.278 | slot update_slots: id  2 | task 13448 | new prompt, n_ctx_slot = 131072, n_keep = 0, task.n_tokens = 69039
2026-05-17 00:01:25.278 | slot update_slots: id  2 | task 13448 | n_tokens = 69020, memory_seq_rm [69020, end)
2026-05-17 00:01:25.278 | slot update_slots: id  2 | task 13448 | prompt processing progress, n_tokens = 69035, batch.n_tokens = 15, progress = 0.999942
2026-05-17 00:01:25.607 | slot create_check: id  2 | task 13448 | created context checkpoint 11 of 32 (pos_min = 69019, pos_max = 69019, n_tokens = 69020, size = 294.173 MiB)
2026-05-17 00:01:25.652 | slot update_slots: id  2 | task 13448 | n_tokens = 69035, memory_seq_rm [69035, end)
2026-05-17 00:01:25.661 | slot init_sampler: id  2 | task 13448 | init sampler, took 8.91 ms, tokens: text = 69039, total = 69039
2026-05-17 00:01:25.661 | slot update_slots: id  2 | task 13448 | prompt processing done, n_tokens = 69039, batch.n_tokens = 4
2026-05-17 00:01:25.704 | srv  log_server_r: done request: POST /v1/chat/completions 172.18.0.1 200
2026-05-17 00:01:25.943 | reasoning-budget: deactivated (natural end)
2026-05-17 00:01:27.041 | slot print_timing: id  2 | task 13448 | 
2026-05-17 00:01:27.041 | prompt eval time =     425.59 ms /    19 tokens (   22.40 ms per token,    44.64 tokens per second)
2026-05-17 00:01:27.041 |        eval time =    1337.72 ms /    85 tokens (   15.74 ms per token,    63.54 tokens per second)
2026-05-17 00:01:27.041 |       total time =    1763.32 ms /   104 tokens
2026-05-17 00:01:27.041 | draft acceptance rate = 0.98113 (   52 accepted /    53 generated)
2026-05-17 00:01:27.041 | statistics mtp: #calls(b,g,a) = 64 12508 10330, #gen drafts = 10330, #acc drafts = 10330, #gen tokens = 18638, #acc tokens = 18383, dur(b,g,a) = 0.097, 49907.420, 5.120 ms
2026-05-17 00:01:27.043 | slot      release: id  2 | task 13448 | stop processing: n_tokens = 69123, truncated = 0
2026-05-17 00:01:27.043 | srv  update_slots: all slots are idle
2026-05-17 00:01:27.465 | srv  params_from_: Chat format: peg-native
2026-05-17 00:01:27.468 | slot get_availabl: id  2 | task -1 | selected slot by LCP similarity, sim_best = 0.993 (> 0.100 thold), f_keep = 1.000
2026-05-17 00:01:27.469 | reasoning-budget: activated, budget=2147483647 tokens
2026-05-17 00:01:27.469 | slot launch_slot_: id  2 | task -1 | sampler chain: logits -> penalties -> ?dry -> ?top-n-sigma -> top-k -> ?typical -> ?top-p -> min-p -> ?xtc -> ?temp-ext -> dist 
2026-05-17 00:01:27.469 | slot launch_slot_: id  2 | task 13486 | processing task, is_child = 0
2026-05-17 00:01:27.469 | slot update_slots: id  2 | task 13486 | new prompt, n_ctx_slot = 131072, n_keep = 0, task.n_tokens = 69589
2026-05-17 00:01:27.469 | slot update_slots: id  2 | task 13486 | n_tokens = 69123, memory_seq_rm [69123, end)
2026-05-17 00:01:27.469 | slot update_slots: id  2 | task 13486 | prompt processing progress, n_tokens = 69585, batch.n_tokens = 462, progress = 0.999943
2026-05-17 00:01:27.801 | slot create_check: id  2 | task 13486 | created context checkpoint 12 of 32 (pos_min = 69122, pos_max = 69122, n_tokens = 69123, size = 294.388 MiB)
2026-05-17 00:01:28.133 | slot update_slots: id  2 | task 13486 | n_tokens = 69585, memory_seq_rm [69585, end)
2026-05-17 00:01:28.142 | slot init_sampler: id  2 | task 13486 | init sampler, took 8.96 ms, tokens: text = 69589, total = 69589
2026-05-17 00:01:28.142 | slot update_slots: id  2 | task 13486 | prompt processing done, n_tokens = 69589, batch.n_tokens = 4
2026-05-17 00:01:28.473 | slot create_check: id  2 | task 13486 | created context checkpoint 13 of 32 (pos_min = 69584, pos_max = 69584, n_tokens = 69585, size = 295.356 MiB)
2026-05-17 00:01:28.516 | srv  log_server_r: done request: POST /v1/chat/completions 172.18.0.1 200
2026-05-17 00:01:28.969 | reasoning-budget: deactivated (natural end)
2026-05-17 00:01:30.116 | slot print_timing: id  2 | task 13486 | 
2026-05-17 00:01:30.116 | prompt eval time =    1045.58 ms /   466 tokens (    2.24 ms per token,   445.68 tokens per second)
2026-05-17 00:01:30.116 |        eval time =    1600.94 ms /   104 tokens (   15.39 ms per token,    64.96 tokens per second)
2026-05-17 00:01:30.116 |       total time =    2646.52 ms /   570 tokens
2026-05-17 00:01:30.116 | draft acceptance rate = 1.00000 (   65 accepted /    65 generated)
2026-05-17 00:01:30.116 | statistics mtp: #calls(b,g,a) = 65 12546 10365, #gen drafts = 10365, #acc drafts = 10365, #gen tokens = 18703, #acc tokens = 18448, dur(b,g,a) = 0.099, 50080.322, 5.136 ms
2026-05-17 00:01:30.117 | slot      release: id  2 | task 13486 | stop processing: n_tokens = 69692, truncated = 0
2026-05-17 00:01:30.117 | srv  update_slots: all slots are idle
2026-05-17 00:01:30.555 | srv  params_from_: Chat format: peg-native
2026-05-17 00:01:30.558 | slot get_availabl: id  2 | task -1 | selected slot by LCP similarity, sim_best = 0.999 (> 0.100 thold), f_keep = 1.000
2026-05-17 00:01:30.559 | reasoning-budget: activated, budget=2147483647 tokens
2026-05-17 00:01:30.559 | slot launch_slot_: id  2 | task -1 | sampler chain: logits -> penalties -> ?dry -> ?top-n-sigma -> top-k -> ?typical -> ?top-p -> min-p -> ?xtc -> ?temp-ext -> dist 
2026-05-17 00:01:30.559 | slot launch_slot_: id  2 | task 13529 | processing task, is_child = 0
2026-05-17 00:01:30.559 | slot update_slots: id  2 | task 13529 | new prompt, n_ctx_slot = 131072, n_keep = 0, task.n_tokens = 69787
2026-05-17 00:01:30.559 | slot update_slots: id  2 | task 13529 | n_tokens = 69692, memory_seq_rm [69692, end)
2026-05-17 00:01:30.559 | slot update_slots: id  2 | task 13529 | prompt processing progress, n_tokens = 69783, batch.n_tokens = 91, progress = 0.999943
2026-05-17 00:01:30.885 | slot create_check: id  2 | task 13529 | created context checkpoint 14 of 32 (pos_min = 69691, pos_max = 69691, n_tokens = 69692, size = 295.580 MiB)
2026-05-17 00:01:30.965 | slot update_slots: id  2 | task 13529 | n_tokens = 69783, memory_seq_rm [69783, end)
2026-05-17 00:01:30.974 | slot init_sampler: id  2 | task 13529 | init sampler, took 9.29 ms, tokens: text = 69787, total = 69787
2026-05-17 00:01:30.974 | slot update_slots: id  2 | task 13529 | prompt processing done, n_tokens = 69787, batch.n_tokens = 4
2026-05-17 00:01:31.310 | slot create_check: id  2 | task 13529 | created context checkpoint 15 of 32 (pos_min = 69782, pos_max = 69782, n_tokens = 69783, size = 295.771 MiB)
2026-05-17 00:01:31.356 | srv  log_server_r: done request: POST /v1/chat/completions 172.18.0.1 200
2026-05-17 00:01:32.284 | reasoning-budget: deactivated (natural end)
2026-05-17 00:01:38.079 | slot print_timing: id  2 | task 13529 | 
2026-05-17 00:01:38.079 | prompt eval time =     795.76 ms /    95 tokens (    8.38 ms per token,   119.38 tokens per second)
2026-05-17 00:01:38.079 |        eval time =    6723.30 ms /   360 tokens (   18.68 ms per token,    53.55 tokens per second)
2026-05-17 00:01:38.079 |       total time =    7519.06 ms /   455 tokens
2026-05-17 00:01:38.079 | draft acceptance rate = 0.96651 (  202 accepted /   209 generated)
2026-05-17 00:01:38.079 | statistics mtp: #calls(b,g,a) = 66 12703 10483, #gen drafts = 10483, #acc drafts = 10483, #gen tokens = 18912, #acc tokens = 18650, dur(b,g,a) = 0.102, 50725.797, 5.195 ms
2026-05-17 00:01:38.080 | slot      release: id  2 | task 13529 | stop processing: n_tokens = 70146, truncated = 0
2026-05-17 00:01:38.080 | srv  update_slots: all slots are idle
2026-05-17 00:01:38.508 | srv  params_from_: Chat format: peg-native
2026-05-17 00:01:38.510 | slot get_availabl: id  2 | task -1 | selected slot by LCP similarity, sim_best = 0.992 (> 0.100 thold), f_keep = 1.000
2026-05-17 00:01:38.512 | reasoning-budget: activated, budget=2147483647 tokens
2026-05-17 00:01:38.512 | slot launch_slot_: id  2 | task -1 | sampler chain: logits -> penalties -> ?dry -> ?top-n-sigma -> top-k -> ?typical -> ?top-p -> min-p -> ?xtc -> ?temp-ext -> dist 
2026-05-17 00:01:38.512 | slot launch_slot_: id  2 | task 13704 | processing task, is_child = 0
2026-05-17 00:01:38.512 | slot update_slots: id  2 | task 13704 | new prompt, n_ctx_slot = 131072, n_keep = 0, task.n_tokens = 70681
2026-05-17 00:01:38.512 | slot update_slots: id  2 | task 13704 | n_tokens = 70146, memory_seq_rm [70146, end)
2026-05-17 00:01:38.512 | slot update_slots: id  2 | task 13704 | prompt processing progress, n_tokens = 70165, batch.n_tokens = 19, progress = 0.992700
2026-05-17 00:01:38.560 | slot update_slots: id  2 | task 13704 | n_tokens = 70165, memory_seq_rm [70165, end)
2026-05-17 00:01:38.560 | slot update_slots: id  2 | task 13704 | prompt processing progress, n_tokens = 70677, batch.n_tokens = 512, progress = 0.999943
2026-05-17 00:01:38.894 | slot create_check: id  2 | task 13704 | created context checkpoint 16 of 32 (pos_min = 70164, pos_max = 70164, n_tokens = 70165, size = 296.571 MiB)
2026-05-17 00:01:39.259 | slot update_slots: id  2 | task 13704 | n_tokens = 70677, memory_seq_rm [70677, end)
2026-05-17 00:01:39.269 | slot init_sampler: id  2 | task 13704 | init sampler, took 9.32 ms, tokens: text = 70681, total = 70681
2026-05-17 00:01:39.269 | slot update_slots: id  2 | task 13704 | prompt processing done, n_tokens = 70681, batch.n_tokens = 4
2026-05-17 00:01:39.605 | slot create_check: id  2 | task 13704 | created context checkpoint 17 of 32 (pos_min = 70676, pos_max = 70676, n_tokens = 70677, size = 297.643 MiB)
2026-05-17 00:01:39.647 | srv  log_server_r: done request: POST /v1/chat/completions 172.18.0.1 200
2026-05-17 00:01:39.978 | reasoning-budget: deactivated (natural end)
2026-05-17 00:01:44.561 | slot print_timing: id  2 | task 13704 | 
2026-05-17 00:01:44.561 | prompt eval time =    1134.42 ms /   535 tokens (    2.12 ms per token,   471.61 tokens per second)
2026-05-17 00:01:44.561 |        eval time =    5159.06 ms /   327 tokens (   15.78 ms per token,    63.38 tokens per second)
2026-05-17 00:01:44.561 |       total time =    6293.48 ms /   862 tokens
2026-05-17 00:01:44.561 | draft acceptance rate = 0.99497 (  198 accepted /   199 generated)
2026-05-17 00:01:44.561 | statistics mtp: #calls(b,g,a) = 67 12831 10590, #gen drafts = 10590, #acc drafts = 10590, #gen tokens = 19111, #acc tokens = 18848, dur(b,g,a) = 0.104, 51287.964, 5.242 ms
2026-05-17 00:01:44.562 | slot      release: id  2 | task 13704 | stop processing: n_tokens = 71007, truncated = 0
2026-05-17 00:01:44.562 | srv  update_slots: all slots are idle
2026-05-17 00:05:40.821 | srv  params_from_: Chat format: peg-native
2026-05-17 00:05:40.822 | slot get_availabl: id  3 | task -1 | selected slot by LRU, t_last = 7492396329
2026-05-17 00:05:40.822 | srv  get_availabl: updating prompt cache
2026-05-17 00:05:40.822 | srv          load:  - looking for better prompt, base f_keep = -1.000, sim = 0.000
2026-05-17 00:05:40.822 | srv        update:  - cache state: 1 prompts, 8835.769 MiB (limits: 8192.000 MiB, 131072 tokens, 131072 est)
2026-05-17 00:05:40.822 | srv        update:    - prompt 0x590a33303010:   68863 tokens, checkpoints: 26,  8835.769 MiB
2026-05-17 00:05:40.822 | srv  get_availabl: prompt cache update took 0.02 ms
2026-05-17 00:05:40.823 | slot launch_slot_: id  3 | task -1 | sampler chain: logits -> penalties -> ?dry -> ?top-n-sigma -> top-k -> ?typical -> ?top-p -> min-p -> ?xtc -> ?temp-ext -> dist 
2026-05-17 00:05:40.823 | slot launch_slot_: id  3 | task 13843 | processing task, is_child = 0
2026-05-17 00:05:40.823 | slot slot_save_an: id  2 | task -1 | saving idle slot to prompt cache
2026-05-17 00:05:40.825 | srv   prompt_save:  - saving prompt with length 71007, total state size = 2657.343 MiB (draft: 148.708 MiB)
2026-05-17 00:05:48.541 | slot prompt_clear: id  2 | task -1 | clearing prompt with 71007 tokens
2026-05-17 00:05:48.553 | srv        update:  - cache size limit reached, removing oldest entry (size = 8835.769 MiB)
2026-05-17 00:05:49.051 | srv        update:  - cache state: 1 prompts, 7128.144 MiB (limits: 8192.000 MiB, 131072 tokens, 131072 est)
2026-05-17 00:05:49.051 | srv        update:    - prompt 0x590a376be480:   71007 tokens, checkpoints: 17,  7128.144 MiB
2026-05-17 00:05:49.051 | slot update_slots: id  3 | task 13843 | new prompt, n_ctx_slot = 131072, n_keep = 0, task.n_tokens = 39814
2026-05-17 00:05:49.051 | slot update_slots: id  3 | task 13843 | erased invalidated context checkpoint (pos_min = 345, pos_max = 345, n_tokens = 346, n_swa = 0, pos_next = 0, size = 150.351 MiB)
2026-05-17 00:05:49.059 | slot update_slots: id  3 | task 13843 | erased invalidated context checkpoint (pos_min = 869, pos_max = 869, n_tokens = 870, n_swa = 0, pos_next = 0, size = 151.448 MiB)
2026-05-17 00:05:49.068 | slot update_slots: id  3 | task 13843 | n_tokens = 0, memory_seq_rm [0, end)
2026-05-17 00:05:49.068 | slot update_slots: id  3 | task 13843 | prompt processing progress, n_tokens = 2048, batch.n_tokens = 2048, progress = 0.051439
2026-05-17 00:05:49.768 | slot update_slots: id  3 | task 13843 | n_tokens = 2048, memory_seq_rm [2048, end)
2026-05-17 00:05:49.768 | slot update_slots: id  3 | task 13843 | prompt processing progress, n_tokens = 4096, batch.n_tokens = 2048, progress = 0.102878
2026-05-17 00:05:50.475 | slot update_slots: id  3 | task 13843 | n_tokens = 4096, memory_seq_rm [4096, end)
2026-05-17 00:05:50.475 | slot update_slots: id  3 | task 13843 | prompt processing progress, n_tokens = 6144, batch.n_tokens = 2048, progress = 0.154318
2026-05-17 00:05:51.197 | slot update_slots: id  3 | task 13843 | n_tokens = 6144, memory_seq_rm [6144, end)
2026-05-17 00:05:51.197 | slot update_slots: id  3 | task 13843 | prompt processing progress, n_tokens = 8192, batch.n_tokens = 2048, progress = 0.205757
2026-05-17 00:05:51.929 | slot update_slots: id  3 | task 13843 | n_tokens = 8192, memory_seq_rm [8192, end)
2026-05-17 00:05:51.929 | slot update_slots: id  3 | task 13843 | 8192 tokens since last checkpoint at 0, creating new checkpoint during processing at position 10240
2026-05-17 00:05:51.929 | slot update_slots: id  3 | task 13843 | prompt processing progress, n_tokens = 10240, batch.n_tokens = 2048, progress = 0.257196
2026-05-17 00:05:52.062 | slot create_check: id  3 | task 13843 | created context checkpoint 1 of 32 (pos_min = 8191, pos_max = 8191, n_tokens = 8192, size = 166.782 MiB)
2026-05-17 00:05:52.804 | slot update_slots: id  3 | task 13843 | n_tokens = 10240, memory_seq_rm [10240, end)
2026-05-17 00:05:52.804 | slot update_slots: id  3 | task 13843 | prompt processing progress, n_tokens = 12288, batch.n_tokens = 2048, progress = 0.308635
2026-05-17 00:05:53.562 | slot update_slots: id  3 | task 13843 | n_tokens = 12288, memory_seq_rm [12288, end)
2026-05-17 00:05:53.562 | slot update_slots: id  3 | task 13843 | prompt processing progress, n_tokens = 14336, batch.n_tokens = 2048, progress = 0.360074
2026-05-17 00:05:54.332 | slot update_slots: id  3 | task 13843 | n_tokens = 14336, memory_seq_rm [14336, end)
2026-05-17 00:05:54.332 | slot update_slots: id  3 | task 13843 | prompt processing progress, n_tokens = 16384, batch.n_tokens = 2048, progress = 0.411514
2026-05-17 00:05:55.114 | slot update_slots: id  3 | task 13843 | n_tokens = 16384, memory_seq_rm [16384, end)
2026-05-17 00:05:55.114 | slot update_slots: id  3 | task 13843 | 8192 tokens since last checkpoint at 8192, creating new checkpoint during processing at position 18432
2026-05-17 00:05:55.114 | slot update_slots: id  3 | task 13843 | prompt processing progress, n_tokens = 18432, batch.n_tokens = 2048, progress = 0.462953
2026-05-17 00:05:55.371 | slot create_check: id  3 | task 13843 | created context checkpoint 2 of 32 (pos_min = 16383, pos_max = 16383, n_tokens = 16384, size = 183.939 MiB)
2026-05-17 00:05:56.165 | slot update_slots: id  3 | task 13843 | n_tokens = 18432, memory_seq_rm [18432, end)
2026-05-17 00:05:56.166 | slot update_slots: id  3 | task 13843 | prompt processing progress, n_tokens = 20480, batch.n_tokens = 2048, progress = 0.514392
2026-05-17 00:05:56.981 | slot update_slots: id  3 | task 13843 | n_tokens = 20480, memory_seq_rm [20480, end)
2026-05-17 00:05:56.981 | slot update_slots: id  3 | task 13843 | prompt processing progress, n_tokens = 22528, batch.n_tokens = 2048, progress = 0.565831
2026-05-17 00:05:57.812 | slot update_slots: id  3 | task 13843 | n_tokens = 22528, memory_seq_rm [22528, end)
2026-05-17 00:05:57.812 | slot update_slots: id  3 | task 13843 | prompt processing progress, n_tokens = 24576, batch.n_tokens = 2048, progress = 0.617270
2026-05-17 00:05:58.659 | slot update_slots: id  3 | task 13843 | n_tokens = 24576, memory_seq_rm [24576, end)
2026-05-17 00:05:58.659 | slot update_slots: id  3 | task 13843 | 8192 tokens since last checkpoint at 16384, creating new checkpoint during processing at position 26624
2026-05-17 00:05:58.659 | slot update_slots: id  3 | task 13843 | prompt processing progress, n_tokens = 26624, batch.n_tokens = 2048, progress = 0.668710
2026-05-17 00:05:58.902 | slot create_check: id  3 | task 13843 | created context checkpoint 3 of 32 (pos_min = 24575, pos_max = 24575, n_tokens = 24576, size = 201.095 MiB)
2026-05-17 00:05:59.761 | slot update_slots: id  3 | task 13843 | n_tokens = 26624, memory_seq_rm [26624, end)
2026-05-17 00:05:59.761 | slot update_slots: id  3 | task 13843 | prompt processing progress, n_tokens = 28672, batch.n_tokens = 2048, progress = 0.720149
2026-05-17 00:06:00.640 | slot update_slots: id  3 | task 13843 | n_tokens = 28672, memory_seq_rm [28672, end)
2026-05-17 00:06:00.640 | slot update_slots: id  3 | task 13843 | prompt processing progress, n_tokens = 30720, batch.n_tokens = 2048, progress = 0.771588
2026-05-17 00:06:01.539 | slot update_slots: id  3 | task 13843 | n_tokens = 30720, memory_seq_rm [30720, end)
2026-05-17 00:06:01.539 | slot update_slots: id  3 | task 13843 | prompt processing progress, n_tokens = 32768, batch.n_tokens = 2048, progress = 0.823027
2026-05-17 00:06:02.459 | slot update_slots: id  3 | task 13843 | n_tokens = 32768, memory_seq_rm [32768, end)
2026-05-17 00:06:02.459 | slot update_slots: id  3 | task 13843 | 8192 tokens since last checkpoint at 24576, creating new checkpoint during processing at position 34816
2026-05-17 00:06:02.459 | slot update_slots: id  3 | task 13843 | prompt processing progress, n_tokens = 34816, batch.n_tokens = 2048, progress = 0.874466
2026-05-17 00:06:02.714 | slot create_check: id  3 | task 13843 | created context checkpoint 4 of 32 (pos_min = 32767, pos_max = 32767, n_tokens = 32768, size = 218.251 MiB)
2026-05-17 00:06:03.646 | slot update_slots: id  3 | task 13843 | n_tokens = 34816, memory_seq_rm [34816, end)
2026-05-17 00:06:03.646 | slot update_slots: id  3 | task 13843 | prompt processing progress, n_tokens = 36864, batch.n_tokens = 2048, progress = 0.925905
2026-05-17 00:06:04.601 | slot update_slots: id  3 | task 13843 | n_tokens = 36864, memory_seq_rm [36864, end)
2026-05-17 00:06:04.601 | slot update_slots: id  3 | task 13843 | prompt processing progress, n_tokens = 38912, batch.n_tokens = 2048, progress = 0.977345
2026-05-17 00:06:05.578 | slot update_slots: id  3 | task 13843 | n_tokens = 38912, memory_seq_rm [38912, end)
2026-05-17 00:06:05.578 | slot update_slots: id  3 | task 13843 | prompt processing progress, n_tokens = 39298, batch.n_tokens = 386, progress = 0.987040
2026-05-17 00:06:05.786 | slot update_slots: id  3 | task 13843 | n_tokens = 39298, memory_seq_rm [39298, end)
2026-05-17 00:06:05.786 | slot update_slots: id  3 | task 13843 | prompt processing progress, n_tokens = 39810, batch.n_tokens = 512, progress = 0.999900
2026-05-17 00:06:06.045 | slot create_check: id  3 | task 13843 | created context checkpoint 5 of 32 (pos_min = 39297, pos_max = 39297, n_tokens = 39298, size = 231.927 MiB)
2026-05-17 00:06:06.295 | slot update_slots: id  3 | task 13843 | n_tokens = 39810, memory_seq_rm [39810, end)
2026-05-17 00:06:06.300 | slot init_sampler: id  3 | task 13843 | init sampler, took 5.16 ms, tokens: text = 39814, total = 39814
2026-05-17 00:06:06.300 | slot update_slots: id  3 | task 13843 | prompt processing done, n_tokens = 39814, batch.n_tokens = 4
2026-05-17 00:06:06.560 | slot create_check: id  3 | task 13843 | created context checkpoint 6 of 32 (pos_min = 39809, pos_max = 39809, n_tokens = 39810, size = 232.999 MiB)
2026-05-17 00:06:06.599 | srv  log_server_r: done request: POST /v1/chat/completions 172.18.0.1 200
2026-05-17 00:06:33.305 | slot print_timing: id  3 | task 13843 | 
2026-05-17 00:06:33.305 | prompt eval time =   17547.62 ms / 39814 tokens (    0.44 ms per token,  2268.91 tokens per second)
2026-05-17 00:06:33.305 |        eval time =   26946.53 ms /  1549 tokens (   17.40 ms per token,    57.48 tokens per second)
2026-05-17 00:06:33.305 |       total time =   44494.15 ms / 41363 tokens
2026-05-17 00:06:33.305 | draft acceptance rate = 0.97291 (  862 accepted /   886 generated)
2026-05-17 00:06:33.305 | statistics mtp: #calls(b,g,a) = 68 13517 11088, #gen drafts = 11088, #acc drafts = 11088, #gen tokens = 19997, #acc tokens = 19710, dur(b,g,a) = 0.106, 53966.062, 5.512 ms
2026-05-17 00:06:33.306 | slot      release: id  3 | task 13843 | stop processing: n_tokens = 41362, truncated = 0
2026-05-17 00:06:33.306 | srv  update_slots: all slots are idle
2026-05-17 00:50:55.270 | srv  params_from_: Chat format: peg-native
2026-05-17 00:50:55.273 | slot get_availabl: id  1 | task -1 | selected slot by LRU, t_last = 7535752969
2026-05-17 00:50:55.273 | srv  get_availabl: updating prompt cache
2026-05-17 00:50:55.273 | srv          load:  - looking for better prompt, base f_keep = -1.000, sim = 0.000
2026-05-17 00:50:55.273 | srv        update:  - cache state: 1 prompts, 7128.144 MiB (limits: 8192.000 MiB, 131072 tokens, 131072 est)
2026-05-17 00:50:55.273 | srv        update:    - prompt 0x590a376be480:   71007 tokens, checkpoints: 17,  7128.144 MiB
2026-05-17 00:50:55.273 | srv  get_availabl: prompt cache update took 0.03 ms
2026-05-17 00:50:55.274 | reasoning-budget: activated, budget=2147483647 tokens
2026-05-17 00:50:55.274 | slot launch_slot_: id  1 | task -1 | sampler chain: logits -> penalties -> ?dry -> ?top-n-sigma -> top-k -> ?typical -> ?top-p -> min-p -> ?xtc -> ?temp-ext -> dist 
2026-05-17 00:50:55.274 | slot launch_slot_: id  1 | task 14614 | processing task, is_child = 0
2026-05-17 00:50:55.274 | slot slot_save_an: id  3 | task -1 | saving idle slot to prompt cache
2026-05-17 00:50:55.276 | srv   prompt_save:  - saving prompt with length 41362, total state size = 1610.386 MiB (draft: 86.623 MiB)
2026-05-17 00:50:58.390 | slot prompt_clear: id  3 | task -1 | clearing prompt with 41362 tokens
2026-05-17 00:50:58.397 | srv        update:  - cache size limit reached, removing oldest entry (size = 7128.144 MiB)
2026-05-17 00:50:58.793 | srv        update:  - cache state: 1 prompts, 2845.379 MiB (limits: 8192.000 MiB, 131072 tokens, 131072 est)
2026-05-17 00:50:58.793 | srv        update:    - prompt 0x590a384d2ce0:   41362 tokens, checkpoints:  6,  2845.379 MiB
2026-05-17 00:50:58.793 | slot update_slots: id  1 | task 14614 | new prompt, n_ctx_slot = 131072, n_keep = 0, task.n_tokens = 27367
2026-05-17 00:50:58.793 | slot update_slots: id  1 | task 14614 | erased invalidated context checkpoint (pos_min = 8191, pos_max = 8191, n_tokens = 8192, n_swa = 0, pos_next = 0, size = 166.782 MiB)
2026-05-17 00:50:58.802 | slot update_slots: id  1 | task 14614 | erased invalidated context checkpoint (pos_min = 9294, pos_max = 9294, n_tokens = 9295, n_swa = 0, pos_next = 0, size = 169.092 MiB)
2026-05-17 00:50:58.810 | slot update_slots: id  1 | task 14614 | erased invalidated context checkpoint (pos_min = 9806, pos_max = 9806, n_tokens = 9807, n_swa = 0, pos_next = 0, size = 170.165 MiB)
2026-05-17 00:50:58.819 | slot update_slots: id  1 | task 14614 | erased invalidated context checkpoint (pos_min = 9894, pos_max = 9894, n_tokens = 9895, n_swa = 0, pos_next = 0, size = 170.349 MiB)
2026-05-17 00:50:58.827 | slot update_slots: id  1 | task 14614 | n_tokens = 0, memory_seq_rm [0, end)
2026-05-17 00:50:58.827 | slot update_slots: id  1 | task 14614 | prompt processing progress, n_tokens = 2048, batch.n_tokens = 2048, progress = 0.074835
2026-05-17 00:50:59.529 | slot update_slots: id  1 | task 14614 | n_tokens = 2048, memory_seq_rm [2048, end)
2026-05-17 00:50:59.530 | slot update_slots: id  1 | task 14614 | prompt processing progress, n_tokens = 4096, batch.n_tokens = 2048, progress = 0.149669
2026-05-17 00:51:00.236 | slot update_slots: id  1 | task 14614 | n_tokens = 4096, memory_seq_rm [4096, end)
2026-05-17 00:51:00.236 | slot update_slots: id  1 | task 14614 | prompt processing progress, n_tokens = 6144, batch.n_tokens = 2048, progress = 0.224504
2026-05-17 00:51:00.955 | slot update_slots: id  1 | task 14614 | n_tokens = 6144, memory_seq_rm [6144, end)
2026-05-17 00:51:00.955 | slot update_slots: id  1 | task 14614 | prompt processing progress, n_tokens = 8192, batch.n_tokens = 2048, progress = 0.299339
2026-05-17 00:51:01.686 | slot update_slots: id  1 | task 14614 | n_tokens = 8192, memory_seq_rm [8192, end)
2026-05-17 00:51:01.686 | slot update_slots: id  1 | task 14614 | 8192 tokens since last checkpoint at 0, creating new checkpoint during processing at position 10240
2026-05-17 00:51:01.686 | slot update_slots: id  1 | task 14614 | prompt processing progress, n_tokens = 10240, batch.n_tokens = 2048, progress = 0.374173
2026-05-17 00:51:01.800 | slot create_check: id  1 | task 14614 | created context checkpoint 1 of 32 (pos_min = 8191, pos_max = 8191, n_tokens = 8192, size = 166.782 MiB)
2026-05-17 00:51:02.542 | slot update_slots: id  1 | task 14614 | n_tokens = 10240, memory_seq_rm [10240, end)
2026-05-17 00:51:02.542 | slot update_slots: id  1 | task 14614 | prompt processing progress, n_tokens = 12288, batch.n_tokens = 2048, progress = 0.449008
2026-05-17 00:51:03.296 | slot update_slots: id  1 | task 14614 | n_tokens = 12288, memory_seq_rm [12288, end)
2026-05-17 00:51:03.296 | slot update_slots: id  1 | task 14614 | prompt processing progress, n_tokens = 14336, batch.n_tokens = 2048, progress = 0.523843
2026-05-17 00:51:04.065 | slot update_slots: id  1 | task 14614 | n_tokens = 14336, memory_seq_rm [14336, end)
2026-05-17 00:51:04.065 | slot update_slots: id  1 | task 14614 | prompt processing progress, n_tokens = 16384, batch.n_tokens = 2048, progress = 0.598677
2026-05-17 00:51:04.844 | slot update_slots: id  1 | task 14614 | n_tokens = 16384, memory_seq_rm [16384, end)
2026-05-17 00:51:04.844 | slot update_slots: id  1 | task 14614 | 8192 tokens since last checkpoint at 8192, creating new checkpoint during processing at position 18432
2026-05-17 00:51:04.844 | slot update_slots: id  1 | task 14614 | prompt processing progress, n_tokens = 18432, batch.n_tokens = 2048, progress = 0.673512
2026-05-17 00:51:05.027 | slot create_check: id  1 | task 14614 | created context checkpoint 2 of 32 (pos_min = 16383, pos_max = 16383, n_tokens = 16384, size = 183.939 MiB)
2026-05-17 00:51:05.820 | slot update_slots: id  1 | task 14614 | n_tokens = 18432, memory_seq_rm [18432, end)
2026-05-17 00:51:05.820 | slot update_slots: id  1 | task 14614 | prompt processing progress, n_tokens = 20480, batch.n_tokens = 2048, progress = 0.748347
2026-05-17 00:51:06.632 | slot update_slots: id  1 | task 14614 | n_tokens = 20480, memory_seq_rm [20480, end)
2026-05-17 00:51:06.632 | slot update_slots: id  1 | task 14614 | prompt processing progress, n_tokens = 22528, batch.n_tokens = 2048, progress = 0.823181
2026-05-17 00:51:07.468 | slot update_slots: id  1 | task 14614 | n_tokens = 22528, memory_seq_rm [22528, end)
2026-05-17 00:51:07.469 | slot update_slots: id  1 | task 14614 | prompt processing progress, n_tokens = 24576, batch.n_tokens = 2048, progress = 0.898016
2026-05-17 00:51:08.325 | slot update_slots: id  1 | task 14614 | n_tokens = 24576, memory_seq_rm [24576, end)
2026-05-17 00:51:08.325 | slot update_slots: id  1 | task 14614 | 8192 tokens since last checkpoint at 16384, creating new checkpoint during processing at position 26624
2026-05-17 00:51:08.325 | slot update_slots: id  1 | task 14614 | prompt processing progress, n_tokens = 26624, batch.n_tokens = 2048, progress = 0.972851
2026-05-17 00:51:08.580 | slot create_check: id  1 | task 14614 | created context checkpoint 3 of 32 (pos_min = 24575, pos_max = 24575, n_tokens = 24576, size = 201.095 MiB)
2026-05-17 00:51:09.452 | slot update_slots: id  1 | task 14614 | n_tokens = 26624, memory_seq_rm [26624, end)
2026-05-17 00:51:09.452 | slot update_slots: id  1 | task 14614 | prompt processing progress, n_tokens = 26851, batch.n_tokens = 227, progress = 0.981145
2026-05-17 00:51:09.574 | slot update_slots: id  1 | task 14614 | n_tokens = 26851, memory_seq_rm [26851, end)
2026-05-17 00:51:09.574 | slot update_slots: id  1 | task 14614 | prompt processing progress, n_tokens = 27363, batch.n_tokens = 512, progress = 0.999854
2026-05-17 00:51:09.824 | slot create_check: id  1 | task 14614 | created context checkpoint 4 of 32 (pos_min = 26850, pos_max = 26850, n_tokens = 26851, size = 205.859 MiB)
2026-05-17 00:51:10.047 | slot update_slots: id  1 | task 14614 | n_tokens = 27363, memory_seq_rm [27363, end)
2026-05-17 00:51:10.051 | slot init_sampler: id  1 | task 14614 | init sampler, took 3.70 ms, tokens: text = 27367, total = 27367
2026-05-17 00:51:10.051 | slot update_slots: id  1 | task 14614 | prompt processing done, n_tokens = 27367, batch.n_tokens = 4
2026-05-17 00:51:10.300 | slot create_check: id  1 | task 14614 | created context checkpoint 5 of 32 (pos_min = 27362, pos_max = 27362, n_tokens = 27363, size = 206.932 MiB)
2026-05-17 00:51:10.339 | srv  log_server_r: done request: POST /v1/chat/completions 172.18.0.1 200
2026-05-17 00:51:20.117 | reasoning-budget: deactivated (natural end)
2026-05-17 00:51:29.077 | slot print_timing: id  1 | task 14614 | 
2026-05-17 00:51:29.077 | prompt eval time =   11544.72 ms / 27367 tokens (    0.42 ms per token,  2370.52 tokens per second)
2026-05-17 00:51:29.077 |        eval time =   18918.92 ms /  1046 tokens (   18.09 ms per token,    55.29 tokens per second)
2026-05-17 00:51:29.077 |       total time =   30463.64 ms / 28413 tokens
2026-05-17 00:51:29.077 | draft acceptance rate = 0.97810 (  536 accepted /   548 generated)
2026-05-17 00:51:29.077 | statistics mtp: #calls(b,g,a) = 69 14026 11414, #gen drafts = 11414, #acc drafts = 11414, #gen tokens = 20545, #acc tokens = 20246, dur(b,g,a) = 0.107, 55795.726, 5.673 ms
2026-05-17 00:51:29.078 | slot      release: id  1 | task 14614 | stop processing: n_tokens = 28412, truncated = 0
2026-05-17 00:51:29.078 | srv  update_slots: all slots are idle
2026-05-17 01:00:24.749 | srv  params_from_: Chat format: peg-native
2026-05-17 01:00:24.751 | slot get_availabl: id  1 | task -1 | selected slot by LCP similarity, sim_best = 0.847 (> 0.100 thold), f_keep = 0.952
2026-05-17 01:00:24.753 | reasoning-budget: activated, budget=2147483647 tokens
2026-05-17 01:00:24.753 | slot launch_slot_: id  1 | task -1 | sampler chain: logits -> penalties -> ?dry -> ?top-n-sigma -> top-k -> ?typical -> ?top-p -> min-p -> ?xtc -> ?temp-ext -> dist 
2026-05-17 01:00:24.753 | slot launch_slot_: id  1 | task 15182 | processing task, is_child = 0
2026-05-17 01:00:24.753 | slot update_slots: id  1 | task 15182 | new prompt, n_ctx_slot = 131072, n_keep = 0, task.n_tokens = 31951
2026-05-17 01:00:24.753 | slot update_slots: id  1 | task 15182 | n_past = 27052, slot.prompt.tokens.size() = 28412, seq_id = 1, pos_min = 28411, n_swa = 0
2026-05-17 01:00:24.753 | slot update_slots: id  1 | task 15182 | Checking checkpoint with [27362, 27362] against 27052...
2026-05-17 01:00:24.753 | slot update_slots: id  1 | task 15182 | Checking checkpoint with [26850, 26850] against 27052...
2026-05-17 01:00:24.832 | slot update_slots: id  1 | task 15182 | restored context checkpoint (pos_min = 26850, pos_max = 26850, n_tokens = 26851, n_past = 26851, size = 205.859 MiB)
2026-05-17 01:00:24.832 | slot update_slots: id  1 | task 15182 | erased invalidated context checkpoint (pos_min = 27362, pos_max = 27362, n_tokens = 27363, n_swa = 0, pos_next = 26851, size = 206.932 MiB)
2026-05-17 01:00:24.844 | slot update_slots: id  1 | task 15182 | n_tokens = 26851, memory_seq_rm [26851, end)
2026-05-17 01:00:24.845 | slot update_slots: id  1 | task 15182 | prompt processing progress, n_tokens = 28899, batch.n_tokens = 2048, progress = 0.904479
2026-05-17 01:00:25.940 | slot update_slots: id  1 | task 15182 | n_tokens = 28899, memory_seq_rm [28899, end)
2026-05-17 01:00:25.940 | slot update_slots: id  1 | task 15182 | prompt processing progress, n_tokens = 30947, batch.n_tokens = 2048, progress = 0.968577
2026-05-17 01:00:26.828 | slot update_slots: id  1 | task 15182 | n_tokens = 30947, memory_seq_rm [30947, end)
2026-05-17 01:00:26.828 | slot update_slots: id  1 | task 15182 | prompt processing progress, n_tokens = 31435, batch.n_tokens = 488, progress = 0.983850
2026-05-17 01:00:27.051 | slot update_slots: id  1 | task 15182 | n_tokens = 31435, memory_seq_rm [31435, end)
2026-05-17 01:00:27.051 | slot update_slots: id  1 | task 15182 | prompt processing progress, n_tokens = 31947, batch.n_tokens = 512, progress = 0.999875
2026-05-17 01:00:27.283 | slot create_check: id  1 | task 15182 | created context checkpoint 5 of 32 (pos_min = 31434, pos_max = 31434, n_tokens = 31435, size = 215.460 MiB)
2026-05-17 01:00:27.509 | slot update_slots: id  1 | task 15182 | n_tokens = 31947, memory_seq_rm [31947, end)
2026-05-17 01:00:27.513 | slot init_sampler: id  1 | task 15182 | init sampler, took 4.00 ms, tokens: text = 31951, total = 31951
2026-05-17 01:00:27.513 | slot update_slots: id  1 | task 15182 | prompt processing done, n_tokens = 31951, batch.n_tokens = 4
2026-05-17 01:00:27.751 | slot create_check: id  1 | task 15182 | created context checkpoint 6 of 32 (pos_min = 31946, pos_max = 31946, n_tokens = 31947, size = 216.532 MiB)
2026-05-17 01:00:27.786 | srv  log_server_r: done request: POST /v1/chat/completions 172.18.0.1 200
2026-05-17 01:00:29.813 | reasoning-budget: deactivated (natural end)
2026-05-17 01:00:31.135 | slot print_timing: id  1 | task 15182 | 
2026-05-17 01:00:31.135 | prompt eval time =    3032.92 ms /  5100 tokens (    0.59 ms per token,  1681.55 tokens per second)
2026-05-17 01:00:31.135 |        eval time =    3349.04 ms /   230 tokens (   14.56 ms per token,    68.68 tokens per second)
2026-05-17 01:00:31.135 |       total time =    6381.96 ms /  5330 tokens
2026-05-17 01:00:31.135 | draft acceptance rate = 0.99254 (  133 accepted /   134 generated)
2026-05-17 01:00:31.135 | statistics mtp: #calls(b,g,a) = 70 14122 11488, #gen drafts = 11488, #acc drafts = 11488, #gen tokens = 20679, #acc tokens = 20379, dur(b,g,a) = 0.108, 56153.020, 5.706 ms
2026-05-17 01:00:31.136 | slot      release: id  1 | task 15182 | stop processing: n_tokens = 32180, truncated = 0
2026-05-17 01:00:31.136 | srv  update_slots: all slots are idle
2026-05-17 01:00:31.351 | srv  params_from_: Chat format: peg-native
2026-05-17 01:00:31.353 | slot get_availabl: id  1 | task -1 | selected slot by LCP similarity, sim_best = 0.998 (> 0.100 thold), f_keep = 0.998
2026-05-17 01:00:31.354 | reasoning-budget: activated, budget=2147483647 tokens
2026-05-17 01:00:31.355 | slot launch_slot_: id  1 | task -1 | sampler chain: logits -> penalties -> ?dry -> ?top-n-sigma -> top-k -> ?typical -> ?top-p -> min-p -> ?xtc -> ?temp-ext -> dist 
2026-05-17 01:00:31.355 | slot launch_slot_: id  1 | task 15287 | processing task, is_child = 0
2026-05-17 01:00:31.355 | slot update_slots: id  1 | task 15287 | new prompt, n_ctx_slot = 131072, n_keep = 0, task.n_tokens = 32198
2026-05-17 01:00:31.355 | slot update_slots: id  1 | task 15287 | n_past = 32124, slot.prompt.tokens.size() = 32180, seq_id = 1, pos_min = 32179, n_swa = 0
2026-05-17 01:00:31.355 | slot update_slots: id  1 | task 15287 | Checking checkpoint with [31946, 31946] against 32124...
2026-05-17 01:00:31.387 | slot update_slots: id  1 | task 15287 | restored context checkpoint (pos_min = 31946, pos_max = 31946, n_tokens = 31947, n_past = 31947, size = 216.532 MiB)
2026-05-17 01:00:31.387 | slot update_slots: id  1 | task 15287 | n_tokens = 31947, memory_seq_rm [31947, end)
2026-05-17 01:00:31.387 | slot update_slots: id  1 | task 15287 | prompt processing progress, n_tokens = 32194, batch.n_tokens = 247, progress = 0.999876
2026-05-17 01:00:31.512 | slot update_slots: id  1 | task 15287 | n_tokens = 32194, memory_seq_rm [32194, end)
2026-05-17 01:00:31.517 | slot init_sampler: id  1 | task 15287 | init sampler, took 4.10 ms, tokens: text = 32198, total = 32198
2026-05-17 01:00:31.517 | slot update_slots: id  1 | task 15287 | prompt processing done, n_tokens = 32198, batch.n_tokens = 4
2026-05-17 01:00:31.756 | slot create_check: id  1 | task 15287 | created context checkpoint 7 of 32 (pos_min = 32193, pos_max = 32193, n_tokens = 32194, size = 217.049 MiB)
2026-05-17 01:00:31.792 | srv  log_server_r: done request: POST /v1/chat/completions 172.18.0.1 200
2026-05-17 01:00:33.046 | reasoning-budget: deactivated (natural end)
2026-05-17 01:00:35.461 | slot print_timing: id  1 | task 15287 | 
2026-05-17 01:00:35.461 | prompt eval time =     436.90 ms /   251 tokens (    1.74 ms per token,   574.50 tokens per second)
2026-05-17 01:00:35.461 |        eval time =    3669.31 ms /   240 tokens (   15.29 ms per token,    65.41 tokens per second)
2026-05-17 01:00:35.461 |       total time =    4106.21 ms /   491 tokens
2026-05-17 01:00:35.461 | draft acceptance rate = 0.98540 (  135 accepted /   137 generated)
2026-05-17 01:00:35.461 | statistics mtp: #calls(b,g,a) = 71 14226 11564, #gen drafts = 11564, #acc drafts = 11564, #gen tokens = 20816, #acc tokens = 20514, dur(b,g,a) = 0.110, 56533.807, 5.742 ms
2026-05-17 01:00:35.462 | slot      release: id  1 | task 15287 | stop processing: n_tokens = 32437, truncated = 0
2026-05-17 01:00:35.462 | srv  update_slots: all slots are idle
2026-05-17 01:00:35.666 | srv  params_from_: Chat format: peg-native
2026-05-17 01:00:35.668 | slot get_availabl: id  1 | task -1 | selected slot by LCP similarity, sim_best = 0.997 (> 0.100 thold), f_keep = 0.998
2026-05-17 01:00:35.669 | reasoning-budget: activated, budget=2147483647 tokens
2026-05-17 01:00:35.669 | slot launch_slot_: id  1 | task -1 | sampler chain: logits -> penalties -> ?dry -> ?top-n-sigma -> top-k -> ?typical -> ?top-p -> min-p -> ?xtc -> ?temp-ext -> dist 
2026-05-17 01:00:35.669 | slot launch_slot_: id  1 | task 15400 | processing task, is_child = 0
2026-05-17 01:00:35.669 | slot update_slots: id  1 | task 15400 | new prompt, n_ctx_slot = 131072, n_keep = 0, task.n_tokens = 32456
2026-05-17 01:00:35.669 | slot update_slots: id  1 | task 15400 | n_past = 32364, slot.prompt.tokens.size() = 32437, seq_id = 1, pos_min = 32436, n_swa = 0
2026-05-17 01:00:35.669 | slot update_slots: id  1 | task 15400 | Checking checkpoint with [32193, 32193] against 32364...
2026-05-17 01:00:35.701 | slot update_slots: id  1 | task 15400 | restored context checkpoint (pos_min = 32193, pos_max = 32193, n_tokens = 32194, n_past = 32194, size = 217.049 MiB)
2026-05-17 01:00:35.701 | slot update_slots: id  1 | task 15400 | n_tokens = 32194, memory_seq_rm [32194, end)
2026-05-17 01:00:35.701 | slot update_slots: id  1 | task 15400 | prompt processing progress, n_tokens = 32452, batch.n_tokens = 258, progress = 0.999877
2026-05-17 01:00:35.837 | slot update_slots: id  1 | task 15400 | n_tokens = 32452, memory_seq_rm [32452, end)
2026-05-17 01:00:35.841 | slot init_sampler: id  1 | task 15400 | init sampler, took 4.10 ms, tokens: text = 32456, total = 32456
2026-05-17 01:00:35.841 | slot update_slots: id  1 | task 15400 | prompt processing done, n_tokens = 32456, batch.n_tokens = 4
2026-05-17 01:00:36.078 | slot create_check: id  1 | task 15400 | created context checkpoint 8 of 32 (pos_min = 32451, pos_max = 32451, n_tokens = 32452, size = 217.589 MiB)
2026-05-17 01:00:36.114 | srv  log_server_r: done request: POST /v1/chat/completions 172.18.0.1 200
2026-05-17 01:00:37.142 | reasoning-budget: deactivated (natural end)
2026-05-17 01:00:39.179 | slot print_timing: id  1 | task 15400 | 
2026-05-17 01:00:39.179 | prompt eval time =     443.51 ms /   262 tokens (    1.69 ms per token,   590.74 tokens per second)
2026-05-17 01:00:39.179 |        eval time =    3065.19 ms /   208 tokens (   14.74 ms per token,    67.86 tokens per second)
2026-05-17 01:00:39.179 |       total time =    3508.71 ms /   470 tokens
2026-05-17 01:00:39.179 | draft acceptance rate = 0.98347 (  119 accepted /   121 generated)
2026-05-17 01:00:39.179 | statistics mtp: #calls(b,g,a) = 72 14314 11630, #gen drafts = 11630, #acc drafts = 11630, #gen tokens = 20937, #acc tokens = 20633, dur(b,g,a) = 0.111, 56859.641, 5.772 ms
2026-05-17 01:00:39.179 | slot      release: id  1 | task 15400 | stop processing: n_tokens = 32663, truncated = 0
2026-05-17 01:00:39.180 | srv  update_slots: all slots are idle
2026-05-17 01:00:39.399 | srv  params_from_: Chat format: peg-native
2026-05-17 01:00:39.401 | slot get_availabl: id  1 | task -1 | selected slot by LCP similarity, sim_best = 0.999 (> 0.100 thold), f_keep = 1.000
2026-05-17 01:00:39.403 | reasoning-budget: activated, budget=2147483647 tokens
2026-05-17 01:00:39.403 | slot launch_slot_: id  1 | task -1 | sampler chain: logits -> penalties -> ?dry -> ?top-n-sigma -> top-k -> ?typical -> ?top-p -> min-p -> ?xtc -> ?temp-ext -> dist 
2026-05-17 01:00:39.403 | slot launch_slot_: id  1 | task 15497 | processing task, is_child = 0
2026-05-17 01:00:39.403 | slot update_slots: id  1 | task 15497 | new prompt, n_ctx_slot = 131072, n_keep = 0, task.n_tokens = 32683
2026-05-17 01:00:39.403 | slot update_slots: id  1 | task 15497 | n_tokens = 32663, memory_seq_rm [32663, end)
2026-05-17 01:00:39.403 | slot update_slots: id  1 | task 15497 | prompt processing progress, n_tokens = 32679, batch.n_tokens = 16, progress = 0.999878
2026-05-17 01:00:39.643 | slot create_check: id  1 | task 15497 | created context checkpoint 9 of 32 (pos_min = 32662, pos_max = 32662, n_tokens = 32663, size = 218.031 MiB)
2026-05-17 01:00:39.680 | slot update_slots: id  1 | task 15497 | n_tokens = 32679, memory_seq_rm [32679, end)
2026-05-17 01:00:39.685 | slot init_sampler: id  1 | task 15497 | init sampler, took 4.28 ms, tokens: text = 32683, total = 32683
2026-05-17 01:00:39.685 | slot update_slots: id  1 | task 15497 | prompt processing done, n_tokens = 32683, batch.n_tokens = 4
2026-05-17 01:00:39.722 | srv  log_server_r: done request: POST /v1/chat/completions 172.18.0.1 200
2026-05-17 01:00:41.022 | reasoning-budget: deactivated (natural end)
2026-05-17 01:00:47.511 | slot print_timing: id  1 | task 15497 | 
2026-05-17 01:00:47.511 | prompt eval time =     317.97 ms /    20 tokens (   15.90 ms per token,    62.90 tokens per second)
2026-05-17 01:00:47.512 |        eval time =    7974.57 ms /   444 tokens (   17.96 ms per token,    55.68 tokens per second)
2026-05-17 01:00:47.512 |       total time =    8292.53 ms /   464 tokens
2026-05-17 01:00:47.512 | draft acceptance rate = 0.98276 (  228 accepted /   232 generated)
2026-05-17 01:00:47.512 | statistics mtp: #calls(b,g,a) = 73 14529 11768, #gen drafts = 11768, #acc drafts = 11768, #gen tokens = 21169, #acc tokens = 20861, dur(b,g,a) = 0.113, 57619.095, 5.842 ms
2026-05-17 01:00:47.512 | slot      release: id  1 | task 15497 | stop processing: n_tokens = 33126, truncated = 0
2026-05-17 01:00:47.512 | srv  update_slots: all slots are idle
2026-05-17 01:01:36.068 | srv  params_from_: Chat format: peg-native
2026-05-17 01:01:36.070 | slot get_availabl: id  1 | task -1 | selected slot by LCP similarity, sim_best = 0.971 (> 0.100 thold), f_keep = 0.963
2026-05-17 01:01:36.072 | reasoning-budget: activated, budget=2147483647 tokens
2026-05-17 01:01:36.072 | slot launch_slot_: id  1 | task -1 | sampler chain: logits -> penalties -> ?dry -> ?top-n-sigma -> top-k -> ?typical -> ?top-p -> min-p -> ?xtc -> ?temp-ext -> dist 
2026-05-17 01:01:36.072 | slot launch_slot_: id  1 | task 15735 | processing task, is_child = 0
2026-05-17 01:01:36.072 | slot update_slots: id  1 | task 15735 | new prompt, n_ctx_slot = 131072, n_keep = 0, task.n_tokens = 32839
2026-05-17 01:01:36.072 | slot update_slots: id  1 | task 15735 | n_past = 31889, slot.prompt.tokens.size() = 33126, seq_id = 1, pos_min = 33125, n_swa = 0
2026-05-17 01:01:36.072 | slot update_slots: id  1 | task 15735 | Checking checkpoint with [32662, 32662] against 31889...
2026-05-17 01:01:36.072 | slot update_slots: id  1 | task 15735 | Checking checkpoint with [32451, 32451] against 31889...
2026-05-17 01:01:36.072 | slot update_slots: id  1 | task 15735 | Checking checkpoint with [32193, 32193] against 31889...
2026-05-17 01:01:36.072 | slot update_slots: id  1 | task 15735 | Checking checkpoint with [31946, 31946] against 31889...
2026-05-17 01:01:36.072 | slot update_slots: id  1 | task 15735 | Checking checkpoint with [31434, 31434] against 31889...
2026-05-17 01:01:36.155 | slot update_slots: id  1 | task 15735 | restored context checkpoint (pos_min = 31434, pos_max = 31434, n_tokens = 31435, n_past = 31435, size = 215.460 MiB)
2026-05-17 01:01:36.155 | slot update_slots: id  1 | task 15735 | erased invalidated context checkpoint (pos_min = 31946, pos_max = 31946, n_tokens = 31947, n_swa = 0, pos_next = 31435, size = 216.532 MiB)
2026-05-17 01:01:36.167 | slot update_slots: id  1 | task 15735 | erased invalidated context checkpoint (pos_min = 32193, pos_max = 32193, n_tokens = 32194, n_swa = 0, pos_next = 31435, size = 217.049 MiB)
2026-05-17 01:01:36.179 | slot update_slots: id  1 | task 15735 | erased invalidated context checkpoint (pos_min = 32451, pos_max = 32451, n_tokens = 32452, n_swa = 0, pos_next = 31435, size = 217.589 MiB)
2026-05-17 01:01:36.192 | slot update_slots: id  1 | task 15735 | erased invalidated context checkpoint (pos_min = 32662, pos_max = 32662, n_tokens = 32663, n_swa = 0, pos_next = 31435, size = 218.031 MiB)
2026-05-17 01:01:36.204 | slot update_slots: id  1 | task 15735 | n_tokens = 31435, memory_seq_rm [31435, end)
2026-05-17 01:01:36.205 | slot update_slots: id  1 | task 15735 | prompt processing progress, n_tokens = 32323, batch.n_tokens = 888, progress = 0.984287
2026-05-17 01:01:36.809 | slot update_slots: id  1 | task 15735 | n_tokens = 32323, memory_seq_rm [32323, end)
2026-05-17 01:01:36.809 | slot update_slots: id  1 | task 15735 | prompt processing progress, n_tokens = 32835, batch.n_tokens = 512, progress = 0.999878
2026-05-17 01:01:36.967 | slot create_check: id  1 | task 15735 | created context checkpoint 6 of 32 (pos_min = 32322, pos_max = 32322, n_tokens = 32323, size = 217.319 MiB)
2026-05-17 01:01:37.197 | slot update_slots: id  1 | task 15735 | n_tokens = 32835, memory_seq_rm [32835, end)
2026-05-17 01:01:37.201 | slot init_sampler: id  1 | task 15735 | init sampler, took 4.17 ms, tokens: text = 32839, total = 32839
2026-05-17 01:01:37.201 | slot update_slots: id  1 | task 15735 | prompt processing done, n_tokens = 32839, batch.n_tokens = 4
2026-05-17 01:01:37.408 | slot create_check: id  1 | task 15735 | created context checkpoint 7 of 32 (pos_min = 32834, pos_max = 32834, n_tokens = 32835, size = 218.391 MiB)
2026-05-17 01:01:37.449 | srv  log_server_r: done request: POST /v1/chat/completions 172.18.0.1 200
2026-05-17 01:01:37.782 | reasoning-budget: deactivated (natural end)
2026-05-17 01:01:38.597 | slot print_timing: id  1 | task 15735 | 
2026-05-17 01:01:38.597 | prompt eval time =    1376.51 ms /  1404 tokens (    0.98 ms per token,  1019.97 tokens per second)
2026-05-17 01:01:38.597 |        eval time =    1147.81 ms /    76 tokens (   15.10 ms per token,    66.21 tokens per second)
2026-05-17 01:01:38.597 |       total time =    2524.32 ms /  1480 tokens
2026-05-17 01:01:38.597 | draft acceptance rate = 0.97872 (   46 accepted /    47 generated)
2026-05-17 01:01:38.597 | statistics mtp: #calls(b,g,a) = 74 14558 11794, #gen drafts = 11794, #acc drafts = 11794, #gen tokens = 21216, #acc tokens = 20907, dur(b,g,a) = 0.115, 57736.109, 5.851 ms
2026-05-17 01:01:38.597 | slot      release: id  1 | task 15735 | stop processing: n_tokens = 32914, truncated = 0
2026-05-17 01:01:38.597 | srv  update_slots: all slots are idle
2026-05-17 01:01:38.800 | srv  params_from_: Chat format: peg-native
2026-05-17 01:01:38.804 | slot get_availabl: id  1 | task -1 | selected slot by LCP similarity, sim_best = 0.997 (> 0.100 thold), f_keep = 1.000
2026-05-17 01:01:38.806 | reasoning-budget: activated, budget=2147483647 tokens
2026-05-17 01:01:38.806 | slot launch_slot_: id  1 | task -1 | sampler chain: logits -> penalties -> ?dry -> ?top-n-sigma -> top-k -> ?typical -> ?top-p -> min-p -> ?xtc -> ?temp-ext -> dist 
2026-05-17 01:01:38.806 | slot launch_slot_: id  1 | task 15771 | processing task, is_child = 0
2026-05-17 01:01:38.806 | slot update_slots: id  1 | task 15771 | new prompt, n_ctx_slot = 131072, n_keep = 0, task.n_tokens = 33009
2026-05-17 01:01:38.806 | slot update_slots: id  1 | task 15771 | n_tokens = 32914, memory_seq_rm [32914, end)
2026-05-17 01:01:38.806 | slot update_slots: id  1 | task 15771 | prompt processing progress, n_tokens = 33005, batch.n_tokens = 91, progress = 0.999879
2026-05-17 01:01:39.054 | slot create_check: id  1 | task 15771 | created context checkpoint 8 of 32 (pos_min = 32913, pos_max = 32913, n_tokens = 32914, size = 218.557 MiB)
2026-05-17 01:01:39.117 | slot update_slots: id  1 | task 15771 | n_tokens = 33005, memory_seq_rm [33005, end)
2026-05-17 01:01:39.121 | slot init_sampler: id  1 | task 15771 | init sampler, took 4.20 ms, tokens: text = 33009, total = 33009
2026-05-17 01:01:39.121 | slot update_slots: id  1 | task 15771 | prompt processing done, n_tokens = 33009, batch.n_tokens = 4
2026-05-17 01:01:39.363 | slot create_check: id  1 | task 15771 | created context checkpoint 9 of 32 (pos_min = 33004, pos_max = 33004, n_tokens = 33005, size = 218.748 MiB)
2026-05-17 01:01:39.399 | srv  log_server_r: done request: POST /v1/chat/completions 172.18.0.1 200
2026-05-17 01:01:39.882 | reasoning-budget: deactivated (natural end)
2026-05-17 01:01:42.033 | slot print_timing: id  1 | task 15771 | 
2026-05-17 01:01:42.033 | prompt eval time =     592.59 ms /    95 tokens (    6.24 ms per token,   160.31 tokens per second)
2026-05-17 01:01:42.033 |        eval time =    2634.03 ms /   162 tokens (   16.26 ms per token,    61.50 tokens per second)
2026-05-17 01:01:42.033 |       total time =    3226.62 ms /   257 tokens
2026-05-17 01:01:42.033 | draft acceptance rate = 0.98913 (   91 accepted /    92 generated)
2026-05-17 01:01:42.033 | statistics mtp: #calls(b,g,a) = 75 14628 11846, #gen drafts = 11846, #acc drafts = 11846, #gen tokens = 21308, #acc tokens = 20998, dur(b,g,a) = 0.117, 57993.049, 5.878 ms
2026-05-17 01:01:42.034 | slot      release: id  1 | task 15771 | stop processing: n_tokens = 33170, truncated = 0
2026-05-17 01:01:42.034 | srv  update_slots: all slots are idle
2026-05-17 01:01:42.227 | srv  params_from_: Chat format: peg-native
2026-05-17 01:01:42.229 | slot get_availabl: id  1 | task -1 | selected slot by LCP similarity, sim_best = 0.998 (> 0.100 thold), f_keep = 1.000
2026-05-17 01:01:42.230 | reasoning-budget: activated, budget=2147483647 tokens
2026-05-17 01:01:42.231 | slot launch_slot_: id  1 | task -1 | sampler chain: logits -> penalties -> ?dry -> ?top-n-sigma -> top-k -> ?typical -> ?top-p -> min-p -> ?xtc -> ?temp-ext -> dist 
2026-05-17 01:01:42.231 | slot launch_slot_: id  1 | task 15849 | processing task, is_child = 0
2026-05-17 01:01:42.231 | slot update_slots: id  1 | task 15849 | new prompt, n_ctx_slot = 131072, n_keep = 0, task.n_tokens = 33238
2026-05-17 01:01:42.231 | slot update_slots: id  1 | task 15849 | n_tokens = 33170, memory_seq_rm [33170, end)
2026-05-17 01:01:42.231 | slot update_slots: id  1 | task 15849 | prompt processing progress, n_tokens = 33234, batch.n_tokens = 64, progress = 0.999880
2026-05-17 01:01:42.476 | slot create_check: id  1 | task 15849 | created context checkpoint 10 of 32 (pos_min = 33169, pos_max = 33169, n_tokens = 33170, size = 219.093 MiB)
2026-05-17 01:01:42.528 | slot update_slots: id  1 | task 15849 | n_tokens = 33234, memory_seq_rm [33234, end)
2026-05-17 01:01:42.533 | slot init_sampler: id  1 | task 15849 | init sampler, took 4.36 ms, tokens: text = 33238, total = 33238
2026-05-17 01:01:42.533 | slot update_slots: id  1 | task 15849 | prompt processing done, n_tokens = 33238, batch.n_tokens = 4
2026-05-17 01:01:42.572 | srv  log_server_r: done request: POST /v1/chat/completions 172.18.0.1 200
2026-05-17 01:01:49.648 | reasoning-budget: deactivated (natural end)
2026-05-17 01:01:58.180 | slot print_timing: id  1 | task 15849 | 
2026-05-17 01:01:58.180 | prompt eval time =     340.89 ms /    68 tokens (    5.01 ms per token,   199.48 tokens per second)
2026-05-17 01:01:58.180 |        eval time =   15796.38 ms /   767 tokens (   20.60 ms per token,    48.56 tokens per second)
2026-05-17 01:01:58.180 |       total time =   16137.27 ms /   835 tokens
2026-05-17 01:01:58.180 | draft acceptance rate = 0.98235 (  334 accepted /   340 generated)
2026-05-17 01:01:58.180 | statistics mtp: #calls(b,g,a) = 76 15060 12066, #gen drafts = 12066, #acc drafts = 12066, #gen tokens = 21648, #acc tokens = 21332, dur(b,g,a) = 0.118, 59372.000, 5.989 ms
2026-05-17 01:01:58.181 | slot      release: id  1 | task 15849 | stop processing: n_tokens = 34004, truncated = 0
2026-05-17 01:01:58.181 | srv  update_slots: all slots are idle
2026-05-17 01:02:59.884 | srv  params_from_: Chat format: peg-native
2026-05-17 01:02:59.887 | slot get_availabl: id  1 | task -1 | selected slot by LCP similarity, sim_best = 0.974 (> 0.100 thold), f_keep = 0.964
2026-05-17 01:02:59.888 | reasoning-budget: activated, budget=2147483647 tokens
2026-05-17 01:02:59.888 | slot launch_slot_: id  1 | task -1 | sampler chain: logits -> penalties -> ?dry -> ?top-n-sigma -> top-k -> ?typical -> ?top-p -> min-p -> ?xtc -> ?temp-ext -> dist 
2026-05-17 01:02:59.888 | slot launch_slot_: id  1 | task 16322 | processing task, is_child = 0
2026-05-17 01:02:59.888 | slot update_slots: id  1 | task 16322 | new prompt, n_ctx_slot = 131072, n_keep = 0, task.n_tokens = 33636
2026-05-17 01:02:59.889 | slot update_slots: id  1 | task 16322 | n_past = 32777, slot.prompt.tokens.size() = 34004, seq_id = 1, pos_min = 34003, n_swa = 0
2026-05-17 01:02:59.889 | slot update_slots: id  1 | task 16322 | Checking checkpoint with [33169, 33169] against 32777...
2026-05-17 01:02:59.889 | slot update_slots: id  1 | task 16322 | Checking checkpoint with [33004, 33004] against 32777...
2026-05-17 01:02:59.889 | slot update_slots: id  1 | task 16322 | Checking checkpoint with [32913, 32913] against 32777...
2026-05-17 01:02:59.889 | slot update_slots: id  1 | task 16322 | Checking checkpoint with [32834, 32834] against 32777...
2026-05-17 01:02:59.889 | slot update_slots: id  1 | task 16322 | Checking checkpoint with [32322, 32322] against 32777...
2026-05-17 01:02:59.972 | slot update_slots: id  1 | task 16322 | restored context checkpoint (pos_min = 32322, pos_max = 32322, n_tokens = 32323, n_past = 32323, size = 217.319 MiB)
2026-05-17 01:02:59.972 | slot update_slots: id  1 | task 16322 | erased invalidated context checkpoint (pos_min = 32834, pos_max = 32834, n_tokens = 32835, n_swa = 0, pos_next = 32323, size = 218.391 MiB)
2026-05-17 01:02:59.985 | slot update_slots: id  1 | task 16322 | erased invalidated context checkpoint (pos_min = 32913, pos_max = 32913, n_tokens = 32914, n_swa = 0, pos_next = 32323, size = 218.557 MiB)
2026-05-17 01:02:59.998 | slot update_slots: id  1 | task 16322 | erased invalidated context checkpoint (pos_min = 33004, pos_max = 33004, n_tokens = 33005, n_swa = 0, pos_next = 32323, size = 218.748 MiB)
2026-05-17 01:03:00.010 | slot update_slots: id  1 | task 16322 | erased invalidated context checkpoint (pos_min = 33169, pos_max = 33169, n_tokens = 33170, n_swa = 0, pos_next = 32323, size = 219.093 MiB)
2026-05-17 01:03:00.023 | slot update_slots: id  1 | task 16322 | n_tokens = 32323, memory_seq_rm [32323, end)
2026-05-17 01:03:00.023 | slot update_slots: id  1 | task 16322 | prompt processing progress, n_tokens = 33120, batch.n_tokens = 797, progress = 0.984659
2026-05-17 01:03:00.532 | slot update_slots: id  1 | task 16322 | n_tokens = 33120, memory_seq_rm [33120, end)
2026-05-17 01:03:00.532 | slot update_slots: id  1 | task 16322 | prompt processing progress, n_tokens = 33632, batch.n_tokens = 512, progress = 0.999881
2026-05-17 01:03:00.742 | slot create_check: id  1 | task 16322 | created context checkpoint 7 of 32 (pos_min = 33119, pos_max = 33119, n_tokens = 33120, size = 218.988 MiB)
2026-05-17 01:03:00.975 | slot update_slots: id  1 | task 16322 | n_tokens = 33632, memory_seq_rm [33632, end)
2026-05-17 01:03:00.979 | slot init_sampler: id  1 | task 16322 | init sampler, took 4.20 ms, tokens: text = 33636, total = 33636
2026-05-17 01:03:00.979 | slot update_slots: id  1 | task 16322 | prompt processing done, n_tokens = 33636, batch.n_tokens = 4
2026-05-17 01:03:01.138 | slot create_check: id  1 | task 16322 | created context checkpoint 8 of 32 (pos_min = 33631, pos_max = 33631, n_tokens = 33632, size = 220.061 MiB)
2026-05-17 01:03:01.176 | srv  log_server_r: done request: POST /v1/chat/completions 172.18.0.1 200
2026-05-17 01:03:12.257 | reasoning-budget: deactivated (natural end)
2026-05-17 01:03:12.290 | reasoning-budget: deactivated (natural end)
2026-05-17 01:03:19.540 | slot print_timing: id  1 | task 16322 | 
2026-05-17 01:03:19.540 | prompt eval time =    1287.10 ms /  1313 tokens (    0.98 ms per token,  1020.13 tokens per second)
2026-05-17 01:03:19.540 |        eval time =   18521.88 ms /   947 tokens (   19.56 ms per token,    51.13 tokens per second)
2026-05-17 01:03:19.540 |       total time =   19808.98 ms /  2260 tokens
2026-05-17 01:03:19.540 | draft acceptance rate = 0.96256 (  437 accepted /   454 generated)
2026-05-17 01:03:19.540 | statistics mtp: #calls(b,g,a) = 77 15569 12337, #gen drafts = 12337, #acc drafts = 12337, #gen tokens = 22102, #acc tokens = 21769, dur(b,g,a) = 0.120, 61032.279, 6.121 ms
2026-05-17 01:03:19.541 | slot      release: id  1 | task 16322 | stop processing: n_tokens = 34582, truncated = 0
2026-05-17 01:03:19.541 | srv  update_slots: all slots are idle
2026-05-17 01:11:50.731 | srv  params_from_: Chat format: peg-native
2026-05-17 01:11:50.734 | slot get_availabl: id  1 | task -1 | selected slot by LCP similarity, sim_best = 0.979 (> 0.100 thold), f_keep = 0.971
2026-05-17 01:11:50.735 | reasoning-budget: activated, budget=2147483647 tokens
2026-05-17 01:11:50.735 | slot launch_slot_: id  1 | task -1 | sampler chain: logits -> penalties -> ?dry -> ?top-n-sigma -> top-k -> ?typical -> ?top-p -> min-p -> ?xtc -> ?temp-ext -> dist 
2026-05-17 01:11:50.735 | slot launch_slot_: id  1 | task 16881 | processing task, is_child = 0
2026-05-17 01:11:50.735 | slot update_slots: id  1 | task 16881 | new prompt, n_ctx_slot = 131072, n_keep = 0, task.n_tokens = 34302
2026-05-17 01:11:50.735 | slot update_slots: id  1 | task 16881 | n_past = 33574, slot.prompt.tokens.size() = 34582, seq_id = 1, pos_min = 34581, n_swa = 0
2026-05-17 01:11:50.735 | slot update_slots: id  1 | task 16881 | Checking checkpoint with [33631, 33631] against 33574...
2026-05-17 01:11:50.735 | slot update_slots: id  1 | task 16881 | Checking checkpoint with [33119, 33119] against 33574...
2026-05-17 01:11:50.822 | slot update_slots: id  1 | task 16881 | restored context checkpoint (pos_min = 33119, pos_max = 33119, n_tokens = 33120, n_past = 33120, size = 218.988 MiB)
2026-05-17 01:11:50.822 | slot update_slots: id  1 | task 16881 | erased invalidated context checkpoint (pos_min = 33631, pos_max = 33631, n_tokens = 33632, n_swa = 0, pos_next = 33120, size = 220.061 MiB)
2026-05-17 01:11:50.834 | slot update_slots: id  1 | task 16881 | n_tokens = 33120, memory_seq_rm [33120, end)
2026-05-17 01:11:50.835 | slot update_slots: id  1 | task 16881 | prompt processing progress, n_tokens = 33786, batch.n_tokens = 666, progress = 0.984957
2026-05-17 01:11:51.405 | slot update_slots: id  1 | task 16881 | n_tokens = 33786, memory_seq_rm [33786, end)
2026-05-17 01:11:51.405 | slot update_slots: id  1 | task 16881 | prompt processing progress, n_tokens = 34298, batch.n_tokens = 512, progress = 0.999883
2026-05-17 01:11:51.566 | slot create_check: id  1 | task 16881 | created context checkpoint 8 of 32 (pos_min = 33785, pos_max = 33785, n_tokens = 33786, size = 220.383 MiB)
2026-05-17 01:11:51.799 | slot update_slots: id  1 | task 16881 | n_tokens = 34298, memory_seq_rm [34298, end)
2026-05-17 01:11:51.804 | slot init_sampler: id  1 | task 16881 | init sampler, took 4.34 ms, tokens: text = 34302, total = 34302
2026-05-17 01:11:51.804 | slot update_slots: id  1 | task 16881 | prompt processing done, n_tokens = 34302, batch.n_tokens = 4
2026-05-17 01:11:52.049 | slot create_check: id  1 | task 16881 | created context checkpoint 9 of 32 (pos_min = 34297, pos_max = 34297, n_tokens = 34298, size = 221.455 MiB)
2026-05-17 01:11:52.088 | srv  log_server_r: done request: POST /v1/chat/completions 172.18.0.1 200
2026-05-17 01:11:52.920 | reasoning-budget: deactivated (natural end)
2026-05-17 01:11:53.913 | slot print_timing: id  1 | task 16881 | 
2026-05-17 01:11:53.913 | prompt eval time =    1352.28 ms /  1182 tokens (    1.14 ms per token,   874.08 tokens per second)
2026-05-17 01:11:53.913 |        eval time =    1824.90 ms /    89 tokens (   20.50 ms per token,    48.77 tokens per second)
2026-05-17 01:11:53.913 |       total time =    3177.17 ms /  1271 tokens
2026-05-17 01:11:53.913 | draft acceptance rate = 1.00000 (   45 accepted /    45 generated)
2026-05-17 01:11:53.913 | statistics mtp: #calls(b,g,a) = 78 15612 12366, #gen drafts = 12366, #acc drafts = 12366, #gen tokens = 22147, #acc tokens = 21814, dur(b,g,a) = 0.121, 61198.638, 6.140 ms
2026-05-17 01:11:53.914 | slot      release: id  1 | task 16881 | stop processing: n_tokens = 34390, truncated = 0
2026-05-17 01:11:53.914 | srv  update_slots: all slots are idle
2026-05-17 01:31:29.522 | srv  params_from_: Chat format: peg-native
2026-05-17 01:31:29.525 | slot get_availabl: id  1 | task -1 | selected slot by LCP similarity, sim_best = 0.988 (> 0.100 thold), f_keep = 0.988
2026-05-17 01:31:29.526 | reasoning-budget: activated, budget=2147483647 tokens
2026-05-17 01:31:29.526 | slot launch_slot_: id  1 | task -1 | sampler chain: logits -> penalties -> ?dry -> ?top-n-sigma -> top-k -> ?typical -> ?top-p -> min-p -> ?xtc -> ?temp-ext -> dist 
2026-05-17 01:31:29.526 | slot launch_slot_: id  1 | task 16935 | processing task, is_child = 0
2026-05-17 01:31:29.526 | slot update_slots: id  1 | task 16935 | new prompt, n_ctx_slot = 131072, n_keep = 0, task.n_tokens = 34415
2026-05-17 01:31:29.526 | slot update_slots: id  1 | task 16935 | n_past = 33987, slot.prompt.tokens.size() = 34390, seq_id = 1, pos_min = 34389, n_swa = 0
2026-05-17 01:31:29.526 | slot update_slots: id  1 | task 16935 | Checking checkpoint with [34297, 34297] against 33987...
2026-05-17 01:31:29.526 | slot update_slots: id  1 | task 16935 | Checking checkpoint with [33785, 33785] against 33987...
2026-05-17 01:31:29.612 | slot update_slots: id  1 | task 16935 | restored context checkpoint (pos_min = 33785, pos_max = 33785, n_tokens = 33786, n_past = 33786, size = 220.383 MiB)
2026-05-17 01:31:29.612 | slot update_slots: id  1 | task 16935 | erased invalidated context checkpoint (pos_min = 34297, pos_max = 34297, n_tokens = 34298, n_swa = 0, pos_next = 33786, size = 221.455 MiB)
2026-05-17 01:31:29.625 | slot update_slots: id  1 | task 16935 | n_tokens = 33786, memory_seq_rm [33786, end)
2026-05-17 01:31:29.625 | slot update_slots: id  1 | task 16935 | prompt processing progress, n_tokens = 33899, batch.n_tokens = 113, progress = 0.985007
2026-05-17 01:31:29.874 | slot update_slots: id  1 | task 16935 | n_tokens = 33899, memory_seq_rm [33899, end)
2026-05-17 01:31:29.874 | slot update_slots: id  1 | task 16935 | prompt processing progress, n_tokens = 34411, batch.n_tokens = 512, progress = 0.999884
2026-05-17 01:31:30.038 | slot create_check: id  1 | task 16935 | created context checkpoint 9 of 32 (pos_min = 33898, pos_max = 33898, n_tokens = 33899, size = 220.620 MiB)
2026-05-17 01:31:30.276 | slot update_slots: id  1 | task 16935 | n_tokens = 34411, memory_seq_rm [34411, end)
2026-05-17 01:31:30.280 | slot init_sampler: id  1 | task 16935 | init sampler, took 4.35 ms, tokens: text = 34415, total = 34415
2026-05-17 01:31:30.280 | slot update_slots: id  1 | task 16935 | prompt processing done, n_tokens = 34415, batch.n_tokens = 4
2026-05-17 01:31:30.520 | slot create_check: id  1 | task 16935 | created context checkpoint 10 of 32 (pos_min = 34410, pos_max = 34410, n_tokens = 34411, size = 221.692 MiB)
2026-05-17 01:31:30.559 | srv  log_server_r: done request: POST /v1/chat/completions 172.18.0.1 200
2026-05-17 01:31:31.060 | reasoning-budget: deactivated (natural end)
2026-05-17 01:31:31.930 | slot print_timing: id  1 | task 16935 | 
2026-05-17 01:31:31.930 | prompt eval time =    1031.52 ms /   629 tokens (    1.64 ms per token,   609.78 tokens per second)
2026-05-17 01:31:31.930 |        eval time =    1371.86 ms /   106 tokens (   12.94 ms per token,    77.27 tokens per second)
2026-05-17 01:31:31.930 |       total time =    2403.38 ms /   735 tokens
2026-05-17 01:31:31.930 | draft acceptance rate = 0.98529 (   67 accepted /    68 generated)
2026-05-17 01:31:31.930 | statistics mtp: #calls(b,g,a) = 79 15650 12402, #gen drafts = 12402, #acc drafts = 12402, #gen tokens = 22215, #acc tokens = 21881, dur(b,g,a) = 0.122, 61356.653, 6.154 ms
2026-05-17 01:31:31.931 | slot      release: id  1 | task 16935 | stop processing: n_tokens = 34520, truncated = 0
2026-05-17 01:31:31.931 | srv  update_slots: all slots are idle
2026-05-17 01:31:32.166 | srv  params_from_: Chat format: peg-native
2026-05-17 01:31:32.168 | slot get_availabl: id  1 | task -1 | selected slot by LCP similarity, sim_best = 0.693 (> 0.100 thold), f_keep = 1.000
2026-05-17 01:31:32.169 | reasoning-budget: activated, budget=2147483647 tokens
2026-05-17 01:31:32.170 | slot launch_slot_: id  1 | task -1 | sampler chain: logits -> penalties -> ?dry -> ?top-n-sigma -> top-k -> ?typical -> ?top-p -> min-p -> ?xtc -> ?temp-ext -> dist 
2026-05-17 01:31:32.170 | slot launch_slot_: id  1 | task 16979 | processing task, is_child = 0
2026-05-17 01:31:32.170 | slot update_slots: id  1 | task 16979 | new prompt, n_ctx_slot = 131072, n_keep = 0, task.n_tokens = 49779
2026-05-17 01:31:32.170 | slot update_slots: id  1 | task 16979 | n_tokens = 34520, memory_seq_rm [34520, end)
2026-05-17 01:31:32.170 | slot update_slots: id  1 | task 16979 | prompt processing progress, n_tokens = 36568, batch.n_tokens = 2048, progress = 0.734607
2026-05-17 01:31:33.118 | slot update_slots: id  1 | task 16979 | n_tokens = 36568, memory_seq_rm [36568, end)
2026-05-17 01:31:33.119 | slot update_slots: id  1 | task 16979 | prompt processing progress, n_tokens = 38616, batch.n_tokens = 2048, progress = 0.775749
2026-05-17 01:31:34.086 | slot update_slots: id  1 | task 16979 | n_tokens = 38616, memory_seq_rm [38616, end)
2026-05-17 01:31:34.086 | slot update_slots: id  1 | task 16979 | prompt processing progress, n_tokens = 40664, batch.n_tokens = 2048, progress = 0.816891
2026-05-17 01:31:35.074 | slot update_slots: id  1 | task 16979 | n_tokens = 40664, memory_seq_rm [40664, end)
2026-05-17 01:31:35.074 | slot update_slots: id  1 | task 16979 | prompt processing progress, n_tokens = 42712, batch.n_tokens = 2048, progress = 0.858033
2026-05-17 01:31:35.923 | slot update_slots: id  1 | task 16979 | n_tokens = 42712, memory_seq_rm [42712, end)
2026-05-17 01:31:35.923 | slot update_slots: id  1 | task 16979 | 8192 tokens since last checkpoint at 34411, creating new checkpoint during processing at position 44760
2026-05-17 01:31:35.923 | slot update_slots: id  1 | task 16979 | prompt processing progress, n_tokens = 44760, batch.n_tokens = 2048, progress = 0.899174
2026-05-17 01:31:36.185 | slot create_check: id  1 | task 16979 | created context checkpoint 11 of 32 (pos_min = 42711, pos_max = 42711, n_tokens = 42712, size = 239.077 MiB)
2026-05-17 01:31:37.195 | slot update_slots: id  1 | task 16979 | n_tokens = 44760, memory_seq_rm [44760, end)
2026-05-17 01:31:37.195 | slot update_slots: id  1 | task 16979 | prompt processing progress, n_tokens = 46808, batch.n_tokens = 2048, progress = 0.940316
2026-05-17 01:31:38.238 | slot update_slots: id  1 | task 16979 | n_tokens = 46808, memory_seq_rm [46808, end)
2026-05-17 01:31:38.238 | slot update_slots: id  1 | task 16979 | prompt processing progress, n_tokens = 48856, batch.n_tokens = 2048, progress = 0.981458
2026-05-17 01:31:39.311 | slot update_slots: id  1 | task 16979 | n_tokens = 48856, memory_seq_rm [48856, end)
2026-05-17 01:31:39.311 | slot update_slots: id  1 | task 16979 | prompt processing progress, n_tokens = 49263, batch.n_tokens = 407, progress = 0.989634
2026-05-17 01:31:39.524 | slot update_slots: id  1 | task 16979 | n_tokens = 49263, memory_seq_rm [49263, end)
2026-05-17 01:31:39.524 | slot update_slots: id  1 | task 16979 | prompt processing progress, n_tokens = 49775, batch.n_tokens = 512, progress = 0.999920
2026-05-17 01:31:39.799 | slot create_check: id  1 | task 16979 | created context checkpoint 12 of 32 (pos_min = 49262, pos_max = 49262, n_tokens = 49263, size = 252.796 MiB)
2026-05-17 01:31:40.073 | slot update_slots: id  1 | task 16979 | n_tokens = 49775, memory_seq_rm [49775, end)
2026-05-17 01:31:40.079 | slot init_sampler: id  1 | task 16979 | init sampler, took 6.11 ms, tokens: text = 49779, total = 49779
2026-05-17 01:31:40.098 | slot update_slots: id  1 | task 16979 | prompt processing done, n_tokens = 49779, batch.n_tokens = 4
2026-05-17 01:31:40.356 | slot create_check: id  1 | task 16979 | created context checkpoint 13 of 32 (pos_min = 49774, pos_max = 49774, n_tokens = 49775, size = 253.868 MiB)
2026-05-17 01:31:40.394 | srv  log_server_r: done request: POST /v1/chat/completions 172.18.0.1 200
2026-05-17 01:32:05.376 | reasoning-budget: deactivated (natural end)
2026-05-17 01:32:16.620 | slot print_timing: id  1 | task 16979 | 
2026-05-17 01:32:16.620 | prompt eval time =    8386.47 ms / 15259 tokens (    0.55 ms per token,  1819.48 tokens per second)
2026-05-17 01:32:16.620 |        eval time =   36388.76 ms /  1620 tokens (   22.46 ms per token,    44.52 tokens per second)
2026-05-17 01:32:16.620 |       total time =   44775.24 ms / 16879 tokens
2026-05-17 01:32:16.620 | draft acceptance rate = 0.96662 (  637 accepted /   659 generated)
2026-05-17 01:32:16.620 | statistics mtp: #calls(b,g,a) = 80 16632 12849, #gen drafts = 12849, #acc drafts = 12849, #gen tokens = 22874, #acc tokens = 22518, dur(b,g,a) = 0.123, 64454.134, 6.370 ms
2026-05-17 01:32:16.621 | slot      release: id  1 | task 16979 | stop processing: n_tokens = 51398, truncated = 0
2026-05-17 01:32:16.621 | srv  update_slots: all slots are idle
2026-05-17 01:38:01.546 | srv  params_from_: Chat format: peg-native
2026-05-17 01:38:01.549 | slot get_availabl: id  1 | task -1 | selected slot by LCP similarity, sim_best = 0.670 (> 0.100 thold), f_keep = 0.663
2026-05-17 01:38:01.550 | reasoning-budget: activated, budget=2147483647 tokens
2026-05-17 01:38:01.550 | slot launch_slot_: id  1 | task -1 | sampler chain: logits -> penalties -> ?dry -> ?top-n-sigma -> top-k -> ?typical -> ?top-p -> min-p -> ?xtc -> ?temp-ext -> dist 
2026-05-17 01:38:01.550 | slot launch_slot_: id  1 | task 18070 | processing task, is_child = 0
2026-05-17 01:38:01.550 | slot update_slots: id  1 | task 18070 | new prompt, n_ctx_slot = 131072, n_keep = 0, task.n_tokens = 50885
2026-05-17 01:38:01.550 | slot update_slots: id  1 | task 18070 | n_past = 34100, slot.prompt.tokens.size() = 51398, seq_id = 1, pos_min = 51397, n_swa = 0
2026-05-17 01:38:01.550 | slot update_slots: id  1 | task 18070 | Checking checkpoint with [49774, 49774] against 34100...
2026-05-17 01:38:01.550 | slot update_slots: id  1 | task 18070 | Checking checkpoint with [49262, 49262] against 34100...
2026-05-17 01:38:01.550 | slot update_slots: id  1 | task 18070 | Checking checkpoint with [42711, 42711] against 34100...
2026-05-17 01:38:01.550 | slot update_slots: id  1 | task 18070 | Checking checkpoint with [34410, 34410] against 34100...
2026-05-17 01:38:01.550 | slot update_slots: id  1 | task 18070 | Checking checkpoint with [33898, 33898] against 34100...
2026-05-17 01:38:01.639 | slot update_slots: id  1 | task 18070 | restored context checkpoint (pos_min = 33898, pos_max = 33898, n_tokens = 33899, n_past = 33899, size = 220.620 MiB)
2026-05-17 01:38:01.639 | slot update_slots: id  1 | task 18070 | erased invalidated context checkpoint (pos_min = 34410, pos_max = 34410, n_tokens = 34411, n_swa = 0, pos_next = 33899, size = 221.692 MiB)
2026-05-17 01:38:01.651 | slot update_slots: id  1 | task 18070 | erased invalidated context checkpoint (pos_min = 42711, pos_max = 42711, n_tokens = 42712, n_swa = 0, pos_next = 33899, size = 239.077 MiB)
2026-05-17 01:38:01.664 | slot update_slots: id  1 | task 18070 | erased invalidated context checkpoint (pos_min = 49262, pos_max = 49262, n_tokens = 49263, n_swa = 0, pos_next = 33899, size = 252.796 MiB)
2026-05-17 01:38:01.679 | slot update_slots: id  1 | task 18070 | erased invalidated context checkpoint (pos_min = 49774, pos_max = 49774, n_tokens = 49775, n_swa = 0, pos_next = 33899, size = 253.868 MiB)
2026-05-17 01:38:01.693 | slot update_slots: id  1 | task 18070 | n_tokens = 33899, memory_seq_rm [33899, end)
2026-05-17 01:38:01.695 | slot update_slots: id  1 | task 18070 | prompt processing progress, n_tokens = 35947, batch.n_tokens = 2048, progress = 0.706436
2026-05-17 01:38:02.780 | slot update_slots: id  1 | task 18070 | n_tokens = 35947, memory_seq_rm [35947, end)
2026-05-17 01:38:02.780 | slot update_slots: id  1 | task 18070 | prompt processing progress, n_tokens = 37995, batch.n_tokens = 2048, progress = 0.746684
2026-05-17 01:38:03.744 | slot update_slots: id  1 | task 18070 | n_tokens = 37995, memory_seq_rm [37995, end)
2026-05-17 01:38:03.744 | slot update_slots: id  1 | task 18070 | prompt processing progress, n_tokens = 40043, batch.n_tokens = 2048, progress = 0.786931
2026-05-17 01:38:04.571 | slot update_slots: id  1 | task 18070 | n_tokens = 40043, memory_seq_rm [40043, end)
2026-05-17 01:38:04.571 | slot update_slots: id  1 | task 18070 | prompt processing progress, n_tokens = 42091, batch.n_tokens = 2048, progress = 0.827179
2026-05-17 01:38:05.558 | slot update_slots: id  1 | task 18070 | n_tokens = 42091, memory_seq_rm [42091, end)
2026-05-17 01:38:05.558 | slot update_slots: id  1 | task 18070 | 8192 tokens since last checkpoint at 33899, creating new checkpoint during processing at position 44139
2026-05-17 01:38:05.558 | slot update_slots: id  1 | task 18070 | prompt processing progress, n_tokens = 44139, batch.n_tokens = 2048, progress = 0.867427
2026-05-17 01:38:05.798 | slot create_check: id  1 | task 18070 | created context checkpoint 10 of 32 (pos_min = 42090, pos_max = 42090, n_tokens = 42091, size = 237.776 MiB)
2026-05-17 01:38:06.810 | slot update_slots: id  1 | task 18070 | n_tokens = 44139, memory_seq_rm [44139, end)
2026-05-17 01:38:06.810 | slot update_slots: id  1 | task 18070 | prompt processing progress, n_tokens = 46187, batch.n_tokens = 2048, progress = 0.907674
2026-05-17 01:38:07.848 | slot update_slots: id  1 | task 18070 | n_tokens = 46187, memory_seq_rm [46187, end)
2026-05-17 01:38:07.848 | slot update_slots: id  1 | task 18070 | prompt processing progress, n_tokens = 48235, batch.n_tokens = 2048, progress = 0.947922
2026-05-17 01:38:08.919 | slot update_slots: id  1 | task 18070 | n_tokens = 48235, memory_seq_rm [48235, end)
2026-05-17 01:38:08.919 | slot update_slots: id  1 | task 18070 | prompt processing progress, n_tokens = 50283, batch.n_tokens = 2048, progress = 0.988169
2026-05-17 01:38:10.024 | slot update_slots: id  1 | task 18070 | n_tokens = 50283, memory_seq_rm [50283, end)
2026-05-17 01:38:10.024 | slot update_slots: id  1 | task 18070 | 8192 tokens since last checkpoint at 42091, creating new checkpoint during processing at position 50369
2026-05-17 01:38:10.024 | slot update_slots: id  1 | task 18070 | prompt processing progress, n_tokens = 50369, batch.n_tokens = 86, progress = 0.989859
2026-05-17 01:38:10.301 | slot create_check: id  1 | task 18070 | created context checkpoint 11 of 32 (pos_min = 50282, pos_max = 50282, n_tokens = 50283, size = 254.932 MiB)
2026-05-17 01:38:10.378 | slot update_slots: id  1 | task 18070 | n_tokens = 50369, memory_seq_rm [50369, end)
2026-05-17 01:38:10.378 | slot update_slots: id  1 | task 18070 | prompt processing progress, n_tokens = 50881, batch.n_tokens = 512, progress = 0.999921
2026-05-17 01:38:10.656 | slot create_check: id  1 | task 18070 | created context checkpoint 12 of 32 (pos_min = 50368, pos_max = 50368, n_tokens = 50369, size = 255.112 MiB)
2026-05-17 01:38:10.945 | slot update_slots: id  1 | task 18070 | n_tokens = 50881, memory_seq_rm [50881, end)
2026-05-17 01:38:10.952 | slot init_sampler: id  1 | task 18070 | init sampler, took 6.38 ms, tokens: text = 50885, total = 50885
2026-05-17 01:38:10.952 | slot update_slots: id  1 | task 18070 | prompt processing done, n_tokens = 50885, batch.n_tokens = 4
2026-05-17 01:38:11.237 | slot create_check: id  1 | task 18070 | created context checkpoint 13 of 32 (pos_min = 50880, pos_max = 50880, n_tokens = 50881, size = 256.185 MiB)
2026-05-17 01:38:11.274 | srv  log_server_r: done request: POST /v1/chat/completions 172.18.0.1 200
2026-05-17 01:38:20.295 | reasoning-budget: deactivated (natural end)
2026-05-17 01:38:29.572 | slot print_timing: id  1 | task 18070 | 
2026-05-17 01:38:29.572 | prompt eval time =    9869.16 ms / 16986 tokens (    0.58 ms per token,  1721.12 tokens per second)
2026-05-17 01:38:29.572 |        eval time =   18297.40 ms /   901 tokens (   20.31 ms per token,    49.24 tokens per second)
2026-05-17 01:38:29.572 |       total time =   28166.56 ms / 17887 tokens
2026-05-17 01:38:29.572 | draft acceptance rate = 0.96896 (  437 accepted /   451 generated)
2026-05-17 01:38:29.572 | statistics mtp: #calls(b,g,a) = 81 17095 13127, #gen drafts = 13127, #acc drafts = 13127, #gen tokens = 23325, #acc tokens = 22955, dur(b,g,a) = 0.124, 66102.959, 6.484 ms
2026-05-17 01:38:29.573 | slot      release: id  1 | task 18070 | stop processing: n_tokens = 51785, truncated = 0
2026-05-17 01:38:29.573 | srv  update_slots: all slots are idle
2026-05-17 01:40:02.548 | srv  params_from_: Chat format: peg-native
2026-05-17 01:40:02.550 | slot get_availabl: id  1 | task -1 | selected slot by LCP similarity, sim_best = 0.984 (> 0.100 thold), f_keep = 0.977
2026-05-17 01:40:02.552 | reasoning-budget: activated, budget=2147483647 tokens
2026-05-17 01:40:02.552 | slot launch_slot_: id  1 | task -1 | sampler chain: logits -> penalties -> ?dry -> ?top-n-sigma -> top-k -> ?typical -> ?top-p -> min-p -> ?xtc -> ?temp-ext -> dist 
2026-05-17 01:40:02.552 | slot launch_slot_: id  1 | task 18590 | processing task, is_child = 0
2026-05-17 01:40:02.552 | slot update_slots: id  1 | task 18590 | new prompt, n_ctx_slot = 131072, n_keep = 0, task.n_tokens = 51382
2026-05-17 01:40:02.552 | slot update_slots: id  1 | task 18590 | n_past = 50570, slot.prompt.tokens.size() = 51785, seq_id = 1, pos_min = 51784, n_swa = 0
2026-05-17 01:40:02.552 | slot update_slots: id  1 | task 18590 | Checking checkpoint with [50880, 50880] against 50570...
2026-05-17 01:40:02.552 | slot update_slots: id  1 | task 18590 | Checking checkpoint with [50368, 50368] against 50570...
2026-05-17 01:40:02.650 | slot update_slots: id  1 | task 18590 | restored context checkpoint (pos_min = 50368, pos_max = 50368, n_tokens = 50369, n_past = 50369, size = 255.112 MiB)
2026-05-17 01:40:02.651 | slot update_slots: id  1 | task 18590 | erased invalidated context checkpoint (pos_min = 50880, pos_max = 50880, n_tokens = 50881, n_swa = 0, pos_next = 50369, size = 256.185 MiB)
2026-05-17 01:40:02.665 | slot update_slots: id  1 | task 18590 | n_tokens = 50369, memory_seq_rm [50369, end)
2026-05-17 01:40:02.666 | slot update_slots: id  1 | task 18590 | prompt processing progress, n_tokens = 50866, batch.n_tokens = 497, progress = 0.989958
2026-05-17 01:40:03.088 | slot update_slots: id  1 | task 18590 | n_tokens = 50866, memory_seq_rm [50866, end)
2026-05-17 01:40:03.089 | slot update_slots: id  1 | task 18590 | prompt processing progress, n_tokens = 51378, batch.n_tokens = 512, progress = 0.999922
2026-05-17 01:40:03.285 | slot create_check: id  1 | task 18590 | created context checkpoint 13 of 32 (pos_min = 50865, pos_max = 50865, n_tokens = 50866, size = 256.153 MiB)
2026-05-17 01:40:03.426 | slot update_slots: id  1 | task 18590 | n_tokens = 51378, memory_seq_rm [51378, end)
2026-05-17 01:40:03.432 | slot init_sampler: id  1 | task 18590 | init sampler, took 6.45 ms, tokens: text = 51382, total = 51382
2026-05-17 01:40:03.432 | slot update_slots: id  1 | task 18590 | prompt processing done, n_tokens = 51382, batch.n_tokens = 4
2026-05-17 01:40:03.721 | slot create_check: id  1 | task 18590 | created context checkpoint 14 of 32 (pos_min = 51377, pos_max = 51377, n_tokens = 51378, size = 257.226 MiB)
2026-05-17 01:40:03.760 | srv  log_server_r: done request: POST /v1/chat/completions 172.18.0.1 200
2026-05-17 01:40:08.271 | reasoning-budget: deactivated (natural end)
2026-05-17 01:40:09.361 | slot print_timing: id  1 | task 18590 | 
2026-05-17 01:40:09.361 | prompt eval time =    1356.14 ms /  1013 tokens (    1.34 ms per token,   746.97 tokens per second)
2026-05-17 01:40:09.361 |        eval time =    5600.32 ms /   318 tokens (   17.61 ms per token,    56.78 tokens per second)
2026-05-17 01:40:09.361 |       total time =    6956.47 ms /  1331 tokens
2026-05-17 01:40:09.361 | draft acceptance rate = 0.97661 (  167 accepted /   171 generated)
2026-05-17 01:40:09.361 | statistics mtp: #calls(b,g,a) = 82 17245 13234, #gen drafts = 13234, #acc drafts = 13234, #gen tokens = 23496, #acc tokens = 23122, dur(b,g,a) = 0.126, 66657.860, 6.528 ms
2026-05-17 01:40:09.362 | slot      release: id  1 | task 18590 | stop processing: n_tokens = 51699, truncated = 0
2026-05-17 01:40:09.362 | srv  update_slots: all slots are idle
2026-05-17 01:40:09.593 | srv  params_from_: Chat format: peg-native
2026-05-17 01:40:09.595 | slot get_availabl: id  1 | task -1 | selected slot by LCP similarity, sim_best = 0.982 (> 0.100 thold), f_keep = 1.000
2026-05-17 01:40:09.596 | reasoning-budget: activated, budget=2147483647 tokens
2026-05-17 01:40:09.597 | slot launch_slot_: id  1 | task -1 | sampler chain: logits -> penalties -> ?dry -> ?top-n-sigma -> top-k -> ?typical -> ?top-p -> min-p -> ?xtc -> ?temp-ext -> dist 
2026-05-17 01:40:09.597 | slot launch_slot_: id  1 | task 18753 | processing task, is_child = 0
2026-05-17 01:40:09.597 | slot update_slots: id  1 | task 18753 | new prompt, n_ctx_slot = 131072, n_keep = 0, task.n_tokens = 52642
2026-05-17 01:40:09.597 | slot update_slots: id  1 | task 18753 | n_tokens = 51699, memory_seq_rm [51699, end)
2026-05-17 01:40:09.597 | slot update_slots: id  1 | task 18753 | prompt processing progress, n_tokens = 52126, batch.n_tokens = 427, progress = 0.990198
2026-05-17 01:40:09.840 | slot update_slots: id  1 | task 18753 | n_tokens = 52126, memory_seq_rm [52126, end)
2026-05-17 01:40:09.840 | slot update_slots: id  1 | task 18753 | prompt processing progress, n_tokens = 52638, batch.n_tokens = 512, progress = 0.999924
2026-05-17 01:40:10.123 | slot create_check: id  1 | task 18753 | created context checkpoint 15 of 32 (pos_min = 52125, pos_max = 52125, n_tokens = 52126, size = 258.792 MiB)
2026-05-17 01:40:10.412 | slot update_slots: id  1 | task 18753 | n_tokens = 52638, memory_seq_rm [52638, end)
2026-05-17 01:40:10.419 | slot init_sampler: id  1 | task 18753 | init sampler, took 6.59 ms, tokens: text = 52642, total = 52642
2026-05-17 01:40:10.419 | slot update_slots: id  1 | task 18753 | prompt processing done, n_tokens = 52642, batch.n_tokens = 4
2026-05-17 01:40:10.700 | slot create_check: id  1 | task 18753 | created context checkpoint 16 of 32 (pos_min = 52637, pos_max = 52637, n_tokens = 52638, size = 259.864 MiB)
2026-05-17 01:40:10.738 | srv  log_server_r: done request: POST /v1/chat/completions 172.18.0.1 200
2026-05-17 01:40:13.472 | reasoning-budget: deactivated (natural end)
2026-05-17 01:40:15.039 | slot print_timing: id  1 | task 18753 | 
2026-05-17 01:40:15.039 | prompt eval time =    1141.24 ms /   943 tokens (    1.21 ms per token,   826.29 tokens per second)
2026-05-17 01:40:15.039 |        eval time =    4300.53 ms /   270 tokens (   15.93 ms per token,    62.78 tokens per second)
2026-05-17 01:40:15.039 |       total time =    5441.77 ms /  1213 tokens
2026-05-17 01:40:15.039 | draft acceptance rate = 1.00000 (  157 accepted /   157 generated)
2026-05-17 01:40:15.039 | statistics mtp: #calls(b,g,a) = 83 17357 13324, #gen drafts = 13324, #acc drafts = 13324, #gen tokens = 23653, #acc tokens = 23279, dur(b,g,a) = 0.127, 67106.443, 6.571 ms
2026-05-17 01:40:15.040 | slot      release: id  1 | task 18753 | stop processing: n_tokens = 52911, truncated = 0
2026-05-17 01:40:15.040 | srv  update_slots: all slots are idle
2026-05-17 01:43:59.420 | srv  params_from_: Chat format: peg-native
2026-05-17 01:43:59.422 | slot get_availabl: id  1 | task -1 | selected slot by LCP similarity, sim_best = 0.971 (> 0.100 thold), f_keep = 0.965
2026-05-17 01:43:59.424 | reasoning-budget: activated, budget=2147483647 tokens
2026-05-17 01:43:59.424 | slot launch_slot_: id  1 | task -1 | sampler chain: logits -> penalties -> ?dry -> ?top-n-sigma -> top-k -> ?typical -> ?top-p -> min-p -> ?xtc -> ?temp-ext -> dist 
2026-05-17 01:43:59.424 | slot launch_slot_: id  1 | task 18873 | processing task, is_child = 0
2026-05-17 01:43:59.424 | slot update_slots: id  1 | task 18873 | new prompt, n_ctx_slot = 131072, n_keep = 0, task.n_tokens = 52572
2026-05-17 01:43:59.424 | slot update_slots: id  1 | task 18873 | n_past = 51067, slot.prompt.tokens.size() = 52911, seq_id = 1, pos_min = 52910, n_swa = 0
2026-05-17 01:43:59.424 | slot update_slots: id  1 | task 18873 | Checking checkpoint with [52637, 52637] against 51067...
2026-05-17 01:43:59.424 | slot update_slots: id  1 | task 18873 | Checking checkpoint with [52125, 52125] against 51067...
2026-05-17 01:43:59.424 | slot update_slots: id  1 | task 18873 | Checking checkpoint with [51377, 51377] against 51067...
2026-05-17 01:43:59.424 | slot update_slots: id  1 | task 18873 | Checking checkpoint with [50865, 50865] against 51067...
2026-05-17 01:43:59.525 | slot update_slots: id  1 | task 18873 | restored context checkpoint (pos_min = 50865, pos_max = 50865, n_tokens = 50866, n_past = 50866, size = 256.153 MiB)
2026-05-17 01:43:59.525 | slot update_slots: id  1 | task 18873 | erased invalidated context checkpoint (pos_min = 51377, pos_max = 51377, n_tokens = 51378, n_swa = 0, pos_next = 50866, size = 257.226 MiB)
2026-05-17 01:43:59.540 | slot update_slots: id  1 | task 18873 | erased invalidated context checkpoint (pos_min = 52125, pos_max = 52125, n_tokens = 52126, n_swa = 0, pos_next = 50866, size = 258.792 MiB)
2026-05-17 01:43:59.554 | slot update_slots: id  1 | task 18873 | erased invalidated context checkpoint (pos_min = 52637, pos_max = 52637, n_tokens = 52638, n_swa = 0, pos_next = 50866, size = 259.864 MiB)
2026-05-17 01:43:59.569 | slot update_slots: id  1 | task 18873 | n_tokens = 50866, memory_seq_rm [50866, end)
2026-05-17 01:43:59.569 | slot update_slots: id  1 | task 18873 | prompt processing progress, n_tokens = 52056, batch.n_tokens = 1190, progress = 0.990185
2026-05-17 01:44:00.453 | slot update_slots: id  1 | task 18873 | n_tokens = 52056, memory_seq_rm [52056, end)
2026-05-17 01:44:00.453 | slot update_slots: id  1 | task 18873 | prompt processing progress, n_tokens = 52568, batch.n_tokens = 512, progress = 0.999924
2026-05-17 01:44:00.664 | slot create_check: id  1 | task 18873 | created context checkpoint 14 of 32 (pos_min = 52055, pos_max = 52055, n_tokens = 52056, size = 258.645 MiB)
2026-05-17 01:44:00.956 | slot update_slots: id  1 | task 18873 | n_tokens = 52568, memory_seq_rm [52568, end)
2026-05-17 01:44:00.962 | slot init_sampler: id  1 | task 18873 | init sampler, took 6.46 ms, tokens: text = 52572, total = 52572
2026-05-17 01:44:00.962 | slot update_slots: id  1 | task 18873 | prompt processing done, n_tokens = 52572, batch.n_tokens = 4
2026-05-17 01:44:01.151 | slot create_check: id  1 | task 18873 | created context checkpoint 15 of 32 (pos_min = 52567, pos_max = 52567, n_tokens = 52568, size = 259.718 MiB)
2026-05-17 01:44:01.190 | srv  log_server_r: done request: POST /v1/chat/completions 172.18.0.1 200
2026-05-17 01:44:09.717 | reasoning-budget: deactivated (natural end)
2026-05-17 01:44:19.080 | slot print_timing: id  1 | task 18873 | 
2026-05-17 01:44:19.080 | prompt eval time =    1764.86 ms /  1706 tokens (    1.03 ms per token,   966.65 tokens per second)
2026-05-17 01:44:19.080 |        eval time =   18022.37 ms /   858 tokens (   21.01 ms per token,    47.61 tokens per second)
2026-05-17 01:44:19.080 |       total time =   19787.23 ms /  2564 tokens
2026-05-17 01:44:19.080 | draft acceptance rate = 0.97222 (  385 accepted /   396 generated)
2026-05-17 01:44:19.080 | statistics mtp: #calls(b,g,a) = 84 17829 13584, #gen drafts = 13584, #acc drafts = 13584, #gen tokens = 24049, #acc tokens = 23664, dur(b,g,a) = 0.129, 68698.219, 6.683 ms
2026-05-17 01:44:19.081 | slot      release: id  1 | task 18873 | stop processing: n_tokens = 53429, truncated = 0
2026-05-17 01:44:19.081 | srv  update_slots: all slots are idle
2026-05-17 01:47:02.867 | srv  params_from_: Chat format: peg-native
2026-05-17 01:47:02.870 | slot get_availabl: id  1 | task -1 | selected slot by LCP similarity, sim_best = 0.898 (> 0.100 thold), f_keep = 0.978
2026-05-17 01:47:02.871 | reasoning-budget: activated, budget=2147483647 tokens
2026-05-17 01:47:02.871 | slot launch_slot_: id  1 | task -1 | sampler chain: logits -> penalties -> ?dry -> ?top-n-sigma -> top-k -> ?typical -> ?top-p -> min-p -> ?xtc -> ?temp-ext -> dist 
2026-05-17 01:47:02.871 | slot launch_slot_: id  1 | task 19385 | processing task, is_child = 0
2026-05-17 01:47:02.871 | slot update_slots: id  1 | task 19385 | new prompt, n_ctx_slot = 131072, n_keep = 0, task.n_tokens = 58184
2026-05-17 01:47:02.871 | slot update_slots: id  1 | task 19385 | n_past = 52257, slot.prompt.tokens.size() = 53429, seq_id = 1, pos_min = 53428, n_swa = 0
2026-05-17 01:47:02.871 | slot update_slots: id  1 | task 19385 | Checking checkpoint with [52567, 52567] against 52257...
2026-05-17 01:47:02.871 | slot update_slots: id  1 | task 19385 | Checking checkpoint with [52055, 52055] against 52257...
2026-05-17 01:47:02.968 | slot update_slots: id  1 | task 19385 | restored context checkpoint (pos_min = 52055, pos_max = 52055, n_tokens = 52056, n_past = 52056, size = 258.645 MiB)
2026-05-17 01:47:02.968 | slot update_slots: id  1 | task 19385 | erased invalidated context checkpoint (pos_min = 52567, pos_max = 52567, n_tokens = 52568, n_swa = 0, pos_next = 52056, size = 259.718 MiB)
2026-05-17 01:47:02.982 | slot update_slots: id  1 | task 19385 | n_tokens = 52056, memory_seq_rm [52056, end)
2026-05-17 01:47:02.983 | slot update_slots: id  1 | task 19385 | prompt processing progress, n_tokens = 54104, batch.n_tokens = 2048, progress = 0.929878
2026-05-17 01:47:04.368 | slot update_slots: id  1 | task 19385 | n_tokens = 54104, memory_seq_rm [54104, end)
2026-05-17 01:47:04.368 | slot update_slots: id  1 | task 19385 | prompt processing progress, n_tokens = 56152, batch.n_tokens = 2048, progress = 0.965076
2026-05-17 01:47:05.535 | slot update_slots: id  1 | task 19385 | n_tokens = 56152, memory_seq_rm [56152, end)
2026-05-17 01:47:05.535 | slot update_slots: id  1 | task 19385 | prompt processing progress, n_tokens = 57668, batch.n_tokens = 1516, progress = 0.991132
2026-05-17 01:47:06.419 | slot update_slots: id  1 | task 19385 | n_tokens = 57668, memory_seq_rm [57668, end)
2026-05-17 01:47:06.419 | slot update_slots: id  1 | task 19385 | prompt processing progress, n_tokens = 58180, batch.n_tokens = 512, progress = 0.999931
2026-05-17 01:47:06.707 | slot create_check: id  1 | task 19385 | created context checkpoint 15 of 32 (pos_min = 57667, pos_max = 57667, n_tokens = 57668, size = 270.398 MiB)
2026-05-17 01:47:07.017 | slot update_slots: id  1 | task 19385 | n_tokens = 58180, memory_seq_rm [58180, end)
2026-05-17 01:47:07.025 | slot init_sampler: id  1 | task 19385 | init sampler, took 7.18 ms, tokens: text = 58184, total = 58184
2026-05-17 01:47:07.025 | slot update_slots: id  1 | task 19385 | prompt processing done, n_tokens = 58184, batch.n_tokens = 4
2026-05-17 01:47:07.321 | slot create_check: id  1 | task 19385 | created context checkpoint 16 of 32 (pos_min = 58179, pos_max = 58179, n_tokens = 58180, size = 271.471 MiB)
2026-05-17 01:47:07.359 | srv  log_server_r: done request: POST /v1/chat/completions 172.18.0.1 200
2026-05-17 01:47:12.983 | reasoning-budget: deactivated (natural end)
2026-05-17 01:47:19.308 | slot print_timing: id  1 | task 19385 | 
2026-05-17 01:47:19.308 | prompt eval time =    4487.13 ms /  6128 tokens (    0.73 ms per token,  1365.68 tokens per second)
2026-05-17 01:47:19.308 |        eval time =   11949.36 ms /   651 tokens (   18.36 ms per token,    54.48 tokens per second)
2026-05-17 01:47:19.308 |       total time =   16436.50 ms /  6779 tokens
2026-05-17 01:47:19.308 | draft acceptance rate = 0.97414 (  339 accepted /   348 generated)
2026-05-17 01:47:19.308 | statistics mtp: #calls(b,g,a) = 85 18140 13789, #gen drafts = 13789, #acc drafts = 13789, #gen tokens = 24397, #acc tokens = 24003, dur(b,g,a) = 0.129, 69862.269, 6.791 ms
2026-05-17 01:47:19.309 | slot      release: id  1 | task 19385 | stop processing: n_tokens = 58834, truncated = 0
2026-05-17 01:47:19.309 | srv  update_slots: all slots are idle
2026-05-17 01:48:57.939 | srv  params_from_: Chat format: peg-native
2026-05-17 01:48:57.942 | slot get_availabl: id  1 | task -1 | selected slot by LCP similarity, sim_best = 0.931 (> 0.100 thold), f_keep = 0.984
2026-05-17 01:48:57.943 | reasoning-budget: activated, budget=2147483647 tokens
2026-05-17 01:48:57.943 | slot launch_slot_: id  1 | task -1 | sampler chain: logits -> penalties -> ?dry -> ?top-n-sigma -> top-k -> ?typical -> ?top-p -> min-p -> ?xtc -> ?temp-ext -> dist 
2026-05-17 01:48:57.943 | slot launch_slot_: id  1 | task 19726 | processing task, is_child = 0
2026-05-17 01:48:57.943 | slot update_slots: id  1 | task 19726 | new prompt, n_ctx_slot = 131072, n_keep = 0, task.n_tokens = 62163
2026-05-17 01:48:57.943 | slot update_slots: id  1 | task 19726 | n_past = 57869, slot.prompt.tokens.size() = 58834, seq_id = 1, pos_min = 58833, n_swa = 0
2026-05-17 01:48:57.943 | slot update_slots: id  1 | task 19726 | Checking checkpoint with [58179, 58179] against 57869...
2026-05-17 01:48:57.943 | slot update_slots: id  1 | task 19726 | Checking checkpoint with [57667, 57667] against 57869...
2026-05-17 01:48:58.050 | slot update_slots: id  1 | task 19726 | restored context checkpoint (pos_min = 57667, pos_max = 57667, n_tokens = 57668, n_past = 57668, size = 270.398 MiB)
2026-05-17 01:48:58.050 | slot update_slots: id  1 | task 19726 | erased invalidated context checkpoint (pos_min = 58179, pos_max = 58179, n_tokens = 58180, n_swa = 0, pos_next = 57668, size = 271.471 MiB)
2026-05-17 01:48:58.066 | slot update_slots: id  1 | task 19726 | n_tokens = 57668, memory_seq_rm [57668, end)
2026-05-17 01:48:58.066 | slot update_slots: id  1 | task 19726 | prompt processing progress, n_tokens = 59716, batch.n_tokens = 2048, progress = 0.960636
2026-05-17 01:48:59.460 | slot update_slots: id  1 | task 19726 | n_tokens = 59716, memory_seq_rm [59716, end)
2026-05-17 01:48:59.460 | slot update_slots: id  1 | task 19726 | prompt processing progress, n_tokens = 61647, batch.n_tokens = 1931, progress = 0.991699
2026-05-17 01:49:00.651 | slot update_slots: id  1 | task 19726 | n_tokens = 61647, memory_seq_rm [61647, end)
2026-05-17 01:49:00.651 | slot update_slots: id  1 | task 19726 | prompt processing progress, n_tokens = 62159, batch.n_tokens = 512, progress = 0.999936
2026-05-17 01:49:00.818 | slot create_check: id  1 | task 19726 | created context checkpoint 16 of 32 (pos_min = 61646, pos_max = 61646, n_tokens = 61647, size = 278.732 MiB)
2026-05-17 01:49:01.149 | slot update_slots: id  1 | task 19726 | n_tokens = 62159, memory_seq_rm [62159, end)
2026-05-17 01:49:01.157 | slot init_sampler: id  1 | task 19726 | init sampler, took 7.72 ms, tokens: text = 62163, total = 62163
2026-05-17 01:49:01.157 | slot update_slots: id  1 | task 19726 | prompt processing done, n_tokens = 62163, batch.n_tokens = 4
2026-05-17 01:49:01.461 | slot create_check: id  1 | task 19726 | created context checkpoint 17 of 32 (pos_min = 62158, pos_max = 62158, n_tokens = 62159, size = 279.804 MiB)
2026-05-17 01:49:01.500 | srv  log_server_r: done request: POST /v1/chat/completions 172.18.0.1 200
2026-05-17 01:49:04.301 | reasoning-budget: deactivated (natural end)
2026-05-17 01:49:08.733 | slot print_timing: id  1 | task 19726 | 
2026-05-17 01:49:08.733 | prompt eval time =    3699.93 ms /  4495 tokens (    0.82 ms per token,  1214.89 tokens per second)
2026-05-17 01:49:08.733 |        eval time =    7233.51 ms /   354 tokens (   20.43 ms per token,    48.94 tokens per second)
2026-05-17 01:49:08.733 |       total time =   10933.44 ms /  4849 tokens
2026-05-17 01:49:08.733 | draft acceptance rate = 0.99394 (  164 accepted /   165 generated)
2026-05-17 01:49:08.733 | statistics mtp: #calls(b,g,a) = 86 18329 13893, #gen drafts = 13893, #acc drafts = 13893, #gen tokens = 24562, #acc tokens = 24167, dur(b,g,a) = 0.130, 70517.029, 6.835 ms
2026-05-17 01:49:08.734 | slot      release: id  1 | task 19726 | stop processing: n_tokens = 62516, truncated = 0
2026-05-17 01:49:08.734 | srv  update_slots: all slots are idle
2026-05-17 01:51:12.278 | srv  params_from_: Chat format: peg-native
2026-05-17 01:51:12.281 | slot get_availabl: id  1 | task -1 | selected slot by LCP similarity, sim_best = 0.991 (> 0.100 thold), f_keep = 0.989
2026-05-17 01:51:12.282 | reasoning-budget: activated, budget=2147483647 tokens
2026-05-17 01:51:12.282 | slot launch_slot_: id  1 | task -1 | sampler chain: logits -> penalties -> ?dry -> ?top-n-sigma -> top-k -> ?typical -> ?top-p -> min-p -> ?xtc -> ?temp-ext -> dist 
2026-05-17 01:51:12.282 | slot launch_slot_: id  1 | task 19936 | processing task, is_child = 0
2026-05-17 01:51:12.282 | slot update_slots: id  1 | task 19936 | new prompt, n_ctx_slot = 131072, n_keep = 0, task.n_tokens = 62399
2026-05-17 01:51:12.282 | slot update_slots: id  1 | task 19936 | n_past = 61848, slot.prompt.tokens.size() = 62516, seq_id = 1, pos_min = 62515, n_swa = 0
2026-05-17 01:51:12.282 | slot update_slots: id  1 | task 19936 | Checking checkpoint with [62158, 62158] against 61848...
2026-05-17 01:51:12.282 | slot update_slots: id  1 | task 19936 | Checking checkpoint with [61646, 61646] against 61848...
2026-05-17 01:51:12.390 | slot update_slots: id  1 | task 19936 | restored context checkpoint (pos_min = 61646, pos_max = 61646, n_tokens = 61647, n_past = 61647, size = 278.732 MiB)
2026-05-17 01:51:12.390 | slot update_slots: id  1 | task 19936 | erased invalidated context checkpoint (pos_min = 62158, pos_max = 62158, n_tokens = 62159, n_swa = 0, pos_next = 61647, size = 279.804 MiB)
2026-05-17 01:51:12.405 | slot update_slots: id  1 | task 19936 | n_tokens = 61647, memory_seq_rm [61647, end)
2026-05-17 01:51:12.406 | slot update_slots: id  1 | task 19936 | prompt processing progress, n_tokens = 61883, batch.n_tokens = 236, progress = 0.991731
2026-05-17 01:51:12.787 | slot update_slots: id  1 | task 19936 | n_tokens = 61883, memory_seq_rm [61883, end)
2026-05-17 01:51:12.787 | slot update_slots: id  1 | task 19936 | prompt processing progress, n_tokens = 62395, batch.n_tokens = 512, progress = 0.999936
2026-05-17 01:51:13.092 | slot create_check: id  1 | task 19936 | created context checkpoint 17 of 32 (pos_min = 61882, pos_max = 61882, n_tokens = 61883, size = 279.226 MiB)
2026-05-17 01:51:13.421 | slot update_slots: id  1 | task 19936 | n_tokens = 62395, memory_seq_rm [62395, end)
2026-05-17 01:51:13.429 | slot init_sampler: id  1 | task 19936 | init sampler, took 7.75 ms, tokens: text = 62399, total = 62399
2026-05-17 01:51:13.429 | slot update_slots: id  1 | task 19936 | prompt processing done, n_tokens = 62399, batch.n_tokens = 4
2026-05-17 01:51:13.740 | slot create_check: id  1 | task 19936 | created context checkpoint 18 of 32 (pos_min = 62394, pos_max = 62394, n_tokens = 62395, size = 280.298 MiB)
2026-05-17 01:51:13.779 | reasoning-budget: deactivated (natural end)
2026-05-17 01:51:13.779 | srv  log_server_r: done request: POST /v1/chat/completions 172.18.0.1 200
2026-05-17 01:51:18.494 | slot print_timing: id  1 | task 19936 | 
2026-05-17 01:51:18.494 | prompt eval time =    1496.59 ms /   752 tokens (    1.99 ms per token,   502.48 tokens per second)
2026-05-17 01:51:18.494 |        eval time =    4714.71 ms /   213 tokens (   22.13 ms per token,    45.18 tokens per second)
2026-05-17 01:51:18.494 |       total time =    6211.30 ms /   965 tokens
2026-05-17 01:51:18.494 | draft acceptance rate = 0.97826 (   90 accepted /    92 generated)
2026-05-17 01:51:18.494 | statistics mtp: #calls(b,g,a) = 87 18451 13956, #gen drafts = 13956, #acc drafts = 13956, #gen tokens = 24654, #acc tokens = 24257, dur(b,g,a) = 0.131, 70929.779, 6.863 ms
2026-05-17 01:51:18.496 | slot      release: id  1 | task 19936 | stop processing: n_tokens = 62611, truncated = 0
2026-05-17 01:51:18.496 | srv  update_slots: all slots are idle
2026-05-17 01:56:04.469 | srv  params_from_: Chat format: peg-native
2026-05-17 01:56:04.472 | slot get_availabl: id  1 | task -1 | selected slot by LCP similarity, sim_best = 0.991 (> 0.100 thold), f_keep = 0.992
2026-05-17 01:56:04.473 | reasoning-budget: activated, budget=2147483647 tokens
2026-05-17 01:56:04.473 | slot launch_slot_: id  1 | task -1 | sampler chain: logits -> penalties -> ?dry -> ?top-n-sigma -> top-k -> ?typical -> ?top-p -> min-p -> ?xtc -> ?temp-ext -> dist 
2026-05-17 01:56:04.473 | slot launch_slot_: id  1 | task 20072 | processing task, is_child = 0
2026-05-17 01:56:04.473 | slot update_slots: id  1 | task 20072 | new prompt, n_ctx_slot = 131072, n_keep = 0, task.n_tokens = 62677
2026-05-17 01:56:04.473 | slot update_slots: id  1 | task 20072 | n_past = 62084, slot.prompt.tokens.size() = 62611, seq_id = 1, pos_min = 62610, n_swa = 0
2026-05-17 01:56:04.473 | slot update_slots: id  1 | task 20072 | Checking checkpoint with [62394, 62394] against 62084...
2026-05-17 01:56:04.473 | slot update_slots: id  1 | task 20072 | Checking checkpoint with [61882, 61882] against 62084...
2026-05-17 01:56:04.582 | slot update_slots: id  1 | task 20072 | restored context checkpoint (pos_min = 61882, pos_max = 61882, n_tokens = 61883, n_past = 61883, size = 279.226 MiB)
2026-05-17 01:56:04.582 | slot update_slots: id  1 | task 20072 | erased invalidated context checkpoint (pos_min = 62394, pos_max = 62394, n_tokens = 62395, n_swa = 0, pos_next = 61883, size = 280.298 MiB)
2026-05-17 01:56:04.599 | slot update_slots: id  1 | task 20072 | n_tokens = 61883, memory_seq_rm [61883, end)
2026-05-17 01:56:04.599 | slot update_slots: id  1 | task 20072 | prompt processing progress, n_tokens = 62161, batch.n_tokens = 278, progress = 0.991767
2026-05-17 01:56:04.966 | slot update_slots: id  1 | task 20072 | n_tokens = 62161, memory_seq_rm [62161, end)
2026-05-17 01:56:04.966 | slot update_slots: id  1 | task 20072 | prompt processing progress, n_tokens = 62673, batch.n_tokens = 512, progress = 0.999936
2026-05-17 01:56:05.208 | slot create_check: id  1 | task 20072 | created context checkpoint 18 of 32 (pos_min = 62160, pos_max = 62160, n_tokens = 62161, size = 279.808 MiB)
2026-05-17 01:56:05.536 | slot update_slots: id  1 | task 20072 | n_tokens = 62673, memory_seq_rm [62673, end)
2026-05-17 01:56:05.544 | slot init_sampler: id  1 | task 20072 | init sampler, took 7.89 ms, tokens: text = 62677, total = 62677
2026-05-17 01:56:05.544 | slot update_slots: id  1 | task 20072 | prompt processing done, n_tokens = 62677, batch.n_tokens = 4
2026-05-17 01:56:05.855 | slot create_check: id  1 | task 20072 | created context checkpoint 19 of 32 (pos_min = 62672, pos_max = 62672, n_tokens = 62673, size = 280.880 MiB)
2026-05-17 01:56:05.895 | srv  log_server_r: done request: POST /v1/chat/completions 172.18.0.1 200
2026-05-17 01:56:06.851 | reasoning-budget: deactivated (natural end)
2026-05-17 01:56:07.812 | slot print_timing: id  1 | task 20072 | 
2026-05-17 01:56:07.812 | prompt eval time =    1420.74 ms /   794 tokens (    1.79 ms per token,   558.86 tokens per second)
2026-05-17 01:56:07.812 |        eval time =    1917.39 ms /   122 tokens (   15.72 ms per token,    63.63 tokens per second)
2026-05-17 01:56:07.812 |       total time =    3338.13 ms /   916 tokens
2026-05-17 01:56:07.812 | draft acceptance rate = 0.98611 (   71 accepted /    72 generated)
2026-05-17 01:56:07.812 | statistics mtp: #calls(b,g,a) = 88 18501 13993, #gen drafts = 13993, #acc drafts = 13993, #gen tokens = 24726, #acc tokens = 24328, dur(b,g,a) = 0.133, 71126.437, 6.886 ms
2026-05-17 01:56:07.813 | slot      release: id  1 | task 20072 | stop processing: n_tokens = 62798, truncated = 0
2026-05-17 01:56:07.813 | srv  update_slots: all slots are idle
2026-05-17 01:56:08.072 | srv  params_from_: Chat format: peg-native
2026-05-17 01:56:08.075 | slot get_availabl: id  1 | task -1 | selected slot by LCP similarity, sim_best = 0.857 (> 0.100 thold), f_keep = 1.000
2026-05-17 01:56:08.076 | reasoning-budget: activated, budget=2147483647 tokens
2026-05-17 01:56:08.076 | slot launch_slot_: id  1 | task -1 | sampler chain: logits -> penalties -> ?dry -> ?top-n-sigma -> top-k -> ?typical -> ?top-p -> min-p -> ?xtc -> ?temp-ext -> dist 
2026-05-17 01:56:08.076 | slot launch_slot_: id  1 | task 20131 | processing task, is_child = 0
2026-05-17 01:56:08.076 | slot update_slots: id  1 | task 20131 | new prompt, n_ctx_slot = 131072, n_keep = 0, task.n_tokens = 73243
2026-05-17 01:56:08.076 | slot update_slots: id  1 | task 20131 | n_tokens = 62798, memory_seq_rm [62798, end)
2026-05-17 01:56:08.076 | slot update_slots: id  1 | task 20131 | prompt processing progress, n_tokens = 64846, batch.n_tokens = 2048, progress = 0.885354
2026-05-17 01:56:09.400 | slot update_slots: id  1 | task 20131 | n_tokens = 64846, memory_seq_rm [64846, end)
2026-05-17 01:56:09.400 | slot update_slots: id  1 | task 20131 | prompt processing progress, n_tokens = 66894, batch.n_tokens = 2048, progress = 0.913316
2026-05-17 01:56:10.751 | slot update_slots: id  1 | task 20131 | n_tokens = 66894, memory_seq_rm [66894, end)
2026-05-17 01:56:10.751 | slot update_slots: id  1 | task 20131 | prompt processing progress, n_tokens = 68942, batch.n_tokens = 2048, progress = 0.941278
2026-05-17 01:56:12.137 | slot update_slots: id  1 | task 20131 | n_tokens = 68942, memory_seq_rm [68942, end)
2026-05-17 01:56:12.137 | slot update_slots: id  1 | task 20131 | prompt processing progress, n_tokens = 70990, batch.n_tokens = 2048, progress = 0.969239
2026-05-17 01:56:13.553 | slot update_slots: id  1 | task 20131 | n_tokens = 70990, memory_seq_rm [70990, end)
2026-05-17 01:56:13.553 | slot update_slots: id  1 | task 20131 | 8192 tokens since last checkpoint at 62673, creating new checkpoint during processing at position 72727
2026-05-17 01:56:13.553 | slot update_slots: id  1 | task 20131 | prompt processing progress, n_tokens = 72727, batch.n_tokens = 1737, progress = 0.992955
2026-05-17 01:56:13.880 | slot create_check: id  1 | task 20131 | created context checkpoint 20 of 32 (pos_min = 70989, pos_max = 70989, n_tokens = 70990, size = 298.298 MiB)
2026-05-17 01:56:15.123 | slot update_slots: id  1 | task 20131 | n_tokens = 72727, memory_seq_rm [72727, end)
2026-05-17 01:56:15.123 | slot update_slots: id  1 | task 20131 | prompt processing progress, n_tokens = 73239, batch.n_tokens = 512, progress = 0.999945
2026-05-17 01:56:15.463 | slot create_check: id  1 | task 20131 | created context checkpoint 21 of 32 (pos_min = 72726, pos_max = 72726, n_tokens = 72727, size = 301.936 MiB)
2026-05-17 01:56:15.838 | slot update_slots: id  1 | task 20131 | n_tokens = 73239, memory_seq_rm [73239, end)
2026-05-17 01:56:15.848 | slot init_sampler: id  1 | task 20131 | init sampler, took 9.73 ms, tokens: text = 73243, total = 73243
2026-05-17 01:56:15.848 | slot update_slots: id  1 | task 20131 | prompt processing done, n_tokens = 73243, batch.n_tokens = 4
2026-05-17 01:56:16.186 | slot create_check: id  1 | task 20131 | created context checkpoint 22 of 32 (pos_min = 73238, pos_max = 73238, n_tokens = 73239, size = 303.008 MiB)
2026-05-17 01:56:16.228 | srv  log_server_r: done request: POST /v1/chat/completions 172.18.0.1 200
2026-05-17 01:56:22.449 | reasoning-budget: deactivated (natural end)
2026-05-17 01:56:29.440 | slot print_timing: id  1 | task 20131 | 
2026-05-17 01:56:29.440 | prompt eval time =    8151.35 ms / 10445 tokens (    0.78 ms per token,  1281.38 tokens per second)
2026-05-17 01:56:29.440 |        eval time =   13332.09 ms /   618 tokens (   21.57 ms per token,    46.35 tokens per second)
2026-05-17 01:56:29.440 |       total time =   21483.44 ms / 11063 tokens
2026-05-17 01:56:29.440 | draft acceptance rate = 0.98089 (  308 accepted /   314 generated)
2026-05-17 01:56:29.440 | statistics mtp: #calls(b,g,a) = 89 18810 14188, #gen drafts = 14188, #acc drafts = 14188, #gen tokens = 25040, #acc tokens = 24636, dur(b,g,a) = 0.135, 72324.567, 6.966 ms
2026-05-17 01:56:29.441 | slot      release: id  1 | task 20131 | stop processing: n_tokens = 73860, truncated = 0
2026-05-17 01:56:29.441 | srv  update_slots: all slots are idle
2026-05-17 02:07:12.007 | srv  params_from_: Chat format: peg-native
2026-05-17 02:07:12.010 | slot get_availabl: id  1 | task -1 | selected slot by LCP similarity, sim_best = 0.847 (> 0.100 thold), f_keep = 0.844
2026-05-17 02:07:12.011 | reasoning-budget: activated, budget=2147483647 tokens
2026-05-17 02:07:12.011 | slot launch_slot_: id  1 | task -1 | sampler chain: logits -> penalties -> ?dry -> ?top-n-sigma -> top-k -> ?typical -> ?top-p -> min-p -> ?xtc -> ?temp-ext -> dist 
2026-05-17 02:07:12.011 | slot launch_slot_: id  1 | task 20481 | processing task, is_child = 0
2026-05-17 02:07:12.011 | slot update_slots: id  1 | task 20481 | new prompt, n_ctx_slot = 131072, n_keep = 0, task.n_tokens = 73623
2026-05-17 02:07:12.011 | slot update_slots: id  1 | task 20481 | n_past = 62362, slot.prompt.tokens.size() = 73860, seq_id = 1, pos_min = 73859, n_swa = 0
2026-05-17 02:07:12.011 | slot update_slots: id  1 | task 20481 | Checking checkpoint with [73238, 73238] against 62362...
2026-05-17 02:07:12.011 | slot update_slots: id  1 | task 20481 | Checking checkpoint with [72726, 72726] against 62362...
2026-05-17 02:07:12.011 | slot update_slots: id  1 | task 20481 | Checking checkpoint with [70989, 70989] against 62362...
2026-05-17 02:07:12.011 | slot update_slots: id  1 | task 20481 | Checking checkpoint with [62672, 62672] against 62362...
2026-05-17 02:07:12.011 | slot update_slots: id  1 | task 20481 | Checking checkpoint with [62160, 62160] against 62362...
2026-05-17 02:07:12.127 | slot update_slots: id  1 | task 20481 | restored context checkpoint (pos_min = 62160, pos_max = 62160, n_tokens = 62161, n_past = 62161, size = 279.808 MiB)
2026-05-17 02:07:12.127 | slot update_slots: id  1 | task 20481 | erased invalidated context checkpoint (pos_min = 62672, pos_max = 62672, n_tokens = 62673, n_swa = 0, pos_next = 62161, size = 280.880 MiB)
2026-05-17 02:07:12.143 | slot update_slots: id  1 | task 20481 | erased invalidated context checkpoint (pos_min = 70989, pos_max = 70989, n_tokens = 70990, n_swa = 0, pos_next = 62161, size = 298.298 MiB)
2026-05-17 02:07:12.161 | slot update_slots: id  1 | task 20481 | erased invalidated context checkpoint (pos_min = 72726, pos_max = 72726, n_tokens = 72727, n_swa = 0, pos_next = 62161, size = 301.936 MiB)
2026-05-17 02:07:12.179 | slot update_slots: id  1 | task 20481 | erased invalidated context checkpoint (pos_min = 73238, pos_max = 73238, n_tokens = 73239, n_swa = 0, pos_next = 62161, size = 303.008 MiB)
2026-05-17 02:07:12.198 | slot update_slots: id  1 | task 20481 | n_tokens = 62161, memory_seq_rm [62161, end)
2026-05-17 02:07:12.199 | slot update_slots: id  1 | task 20481 | prompt processing progress, n_tokens = 64209, batch.n_tokens = 2048, progress = 0.872132
2026-05-17 02:07:13.761 | slot update_slots: id  1 | task 20481 | n_tokens = 64209, memory_seq_rm [64209, end)
2026-05-17 02:07:13.761 | slot update_slots: id  1 | task 20481 | prompt processing progress, n_tokens = 66257, batch.n_tokens = 2048, progress = 0.899950
2026-05-17 02:07:15.106 | slot update_slots: id  1 | task 20481 | n_tokens = 66257, memory_seq_rm [66257, end)
2026-05-17 02:07:15.106 | slot update_slots: id  1 | task 20481 | prompt processing progress, n_tokens = 68305, batch.n_tokens = 2048, progress = 0.927767
2026-05-17 02:07:16.487 | slot update_slots: id  1 | task 20481 | n_tokens = 68305, memory_seq_rm [68305, end)
2026-05-17 02:07:16.487 | slot update_slots: id  1 | task 20481 | prompt processing progress, n_tokens = 70353, batch.n_tokens = 2048, progress = 0.955585
2026-05-17 02:07:17.894 | slot update_slots: id  1 | task 20481 | n_tokens = 70353, memory_seq_rm [70353, end)
2026-05-17 02:07:17.894 | slot update_slots: id  1 | task 20481 | 8192 tokens since last checkpoint at 62161, creating new checkpoint during processing at position 72401
2026-05-17 02:07:17.894 | slot update_slots: id  1 | task 20481 | prompt processing progress, n_tokens = 72401, batch.n_tokens = 2048, progress = 0.983402
2026-05-17 02:07:18.227 | slot create_check: id  1 | task 20481 | created context checkpoint 19 of 32 (pos_min = 70352, pos_max = 70352, n_tokens = 70353, size = 296.964 MiB)
2026-05-17 02:07:19.663 | slot update_slots: id  1 | task 20481 | n_tokens = 72401, memory_seq_rm [72401, end)
2026-05-17 02:07:19.663 | slot update_slots: id  1 | task 20481 | prompt processing progress, n_tokens = 73107, batch.n_tokens = 706, progress = 0.992991
2026-05-17 02:07:20.177 | slot update_slots: id  1 | task 20481 | n_tokens = 73107, memory_seq_rm [73107, end)
2026-05-17 02:07:20.177 | slot update_slots: id  1 | task 20481 | prompt processing progress, n_tokens = 73619, batch.n_tokens = 512, progress = 0.999946
2026-05-17 02:07:20.512 | slot create_check: id  1 | task 20481 | created context checkpoint 20 of 32 (pos_min = 73106, pos_max = 73106, n_tokens = 73107, size = 302.732 MiB)
2026-05-17 02:07:20.875 | slot update_slots: id  1 | task 20481 | n_tokens = 73619, memory_seq_rm [73619, end)
2026-05-17 02:07:20.885 | slot init_sampler: id  1 | task 20481 | init sampler, took 9.16 ms, tokens: text = 73623, total = 73623
2026-05-17 02:07:20.885 | slot update_slots: id  1 | task 20481 | prompt processing done, n_tokens = 73623, batch.n_tokens = 4
2026-05-17 02:07:21.220 | slot create_check: id  1 | task 20481 | created context checkpoint 21 of 32 (pos_min = 73618, pos_max = 73618, n_tokens = 73619, size = 303.804 MiB)
2026-05-17 02:07:21.263 | srv  log_server_r: done request: POST /v1/chat/completions 172.18.0.1 200
2026-05-17 02:07:23.843 | reasoning-budget: deactivated (natural end)
2026-05-17 02:07:25.005 | slot print_timing: id  1 | task 20481 | 
2026-05-17 02:07:25.005 | prompt eval time =    9250.79 ms / 11462 tokens (    0.81 ms per token,  1239.03 tokens per second)
2026-05-17 02:07:25.005 |        eval time =    3742.13 ms /   218 tokens (   17.17 ms per token,    58.26 tokens per second)
2026-05-17 02:07:25.005 |       total time =   12992.92 ms / 11680 tokens
2026-05-17 02:07:25.005 | draft acceptance rate = 0.98400 (  123 accepted /   125 generated)
2026-05-17 02:07:25.005 | statistics mtp: #calls(b,g,a) = 90 18904 14257, #gen drafts = 14257, #acc drafts = 14257, #gen tokens = 25165, #acc tokens = 24759, dur(b,g,a) = 0.136, 72712.448, 6.992 ms
2026-05-17 02:07:25.006 | slot      release: id  1 | task 20481 | stop processing: n_tokens = 73840, truncated = 0
2026-05-17 02:07:25.006 | srv  update_slots: all slots are idle
2026-05-17 02:07:25.284 | srv  params_from_: Chat format: peg-native
2026-05-17 02:07:25.287 | slot get_availabl: id  1 | task -1 | selected slot by LCP similarity, sim_best = 0.998 (> 0.100 thold), f_keep = 1.000
2026-05-17 02:07:25.288 | reasoning-budget: activated, budget=2147483647 tokens
2026-05-17 02:07:25.288 | slot launch_slot_: id  1 | task -1 | sampler chain: logits -> penalties -> ?dry -> ?top-n-sigma -> top-k -> ?typical -> ?top-p -> min-p -> ?xtc -> ?temp-ext -> dist 
2026-05-17 02:07:25.288 | slot launch_slot_: id  1 | task 20589 | processing task, is_child = 0
2026-05-17 02:07:25.288 | slot update_slots: id  1 | task 20589 | new prompt, n_ctx_slot = 131072, n_keep = 0, task.n_tokens = 74018
2026-05-17 02:07:25.288 | slot update_slots: id  1 | task 20589 | n_tokens = 73840, memory_seq_rm [73840, end)
2026-05-17 02:07:25.288 | slot update_slots: id  1 | task 20589 | prompt processing progress, n_tokens = 74014, batch.n_tokens = 174, progress = 0.999946
2026-05-17 02:07:25.626 | slot create_check: id  1 | task 20589 | created context checkpoint 22 of 32 (pos_min = 73839, pos_max = 73839, n_tokens = 73840, size = 304.267 MiB)
2026-05-17 02:07:25.782 | slot update_slots: id  1 | task 20589 | n_tokens = 74014, memory_seq_rm [74014, end)
2026-05-17 02:07:25.791 | slot init_sampler: id  1 | task 20589 | init sampler, took 9.15 ms, tokens: text = 74018, total = 74018
2026-05-17 02:07:25.791 | slot update_slots: id  1 | task 20589 | prompt processing done, n_tokens = 74018, batch.n_tokens = 4
2026-05-17 02:07:26.132 | slot create_check: id  1 | task 20589 | created context checkpoint 23 of 32 (pos_min = 74013, pos_max = 74013, n_tokens = 74014, size = 304.631 MiB)
2026-05-17 02:07:26.173 | srv  log_server_r: done request: POST /v1/chat/completions 172.18.0.1 200
2026-05-17 02:07:26.766 | reasoning-budget: deactivated (natural end)
2026-05-17 02:07:28.276 | slot print_timing: id  1 | task 20589 | 
2026-05-17 02:07:28.276 | prompt eval time =     884.71 ms /   178 tokens (    4.97 ms per token,   201.20 tokens per second)
2026-05-17 02:07:28.276 |        eval time =    2222.11 ms /   155 tokens (   14.34 ms per token,    69.75 tokens per second)
2026-05-17 02:07:28.276 |       total time =    3106.82 ms /   333 tokens
2026-05-17 02:07:28.276 | draft acceptance rate = 0.98969 (   96 accepted /    97 generated)
2026-05-17 02:07:28.276 | statistics mtp: #calls(b,g,a) = 91 18962 14306, #gen drafts = 14306, #acc drafts = 14306, #gen tokens = 25262, #acc tokens = 24855, dur(b,g,a) = 0.138, 72971.923, 7.013 ms
2026-05-17 02:07:28.278 | slot      release: id  1 | task 20589 | stop processing: n_tokens = 74172, truncated = 0
2026-05-17 02:07:28.278 | srv  update_slots: all slots are idle
2026-05-17 02:07:28.568 | srv  params_from_: Chat format: peg-native
2026-05-17 02:07:28.571 | slot get_availabl: id  1 | task -1 | selected slot by LCP similarity, sim_best = 0.955 (> 0.100 thold), f_keep = 1.000
2026-05-17 02:07:28.572 | reasoning-budget: activated, budget=2147483647 tokens
2026-05-17 02:07:28.572 | slot launch_slot_: id  1 | task -1 | sampler chain: logits -> penalties -> ?dry -> ?top-n-sigma -> top-k -> ?typical -> ?top-p -> min-p -> ?xtc -> ?temp-ext -> dist 
2026-05-17 02:07:28.572 | slot launch_slot_: id  1 | task 20653 | processing task, is_child = 0
2026-05-17 02:07:28.572 | slot update_slots: id  1 | task 20653 | new prompt, n_ctx_slot = 131072, n_keep = 0, task.n_tokens = 77707
2026-05-17 02:07:28.572 | slot update_slots: id  1 | task 20653 | n_tokens = 74172, memory_seq_rm [74172, end)
2026-05-17 02:07:28.573 | slot update_slots: id  1 | task 20653 | prompt processing progress, n_tokens = 76220, batch.n_tokens = 2048, progress = 0.980864
2026-05-17 02:07:30.028 | slot update_slots: id  1 | task 20653 | n_tokens = 76220, memory_seq_rm [76220, end)
2026-05-17 02:07:30.028 | slot update_slots: id  1 | task 20653 | prompt processing progress, n_tokens = 77191, batch.n_tokens = 971, progress = 0.993360
2026-05-17 02:07:30.753 | slot update_slots: id  1 | task 20653 | n_tokens = 77191, memory_seq_rm [77191, end)
2026-05-17 02:07:30.753 | slot update_slots: id  1 | task 20653 | prompt processing progress, n_tokens = 77703, batch.n_tokens = 512, progress = 0.999949
2026-05-17 02:07:31.104 | slot create_check: id  1 | task 20653 | created context checkpoint 24 of 32 (pos_min = 77190, pos_max = 77190, n_tokens = 77191, size = 311.285 MiB)
2026-05-17 02:07:31.482 | slot update_slots: id  1 | task 20653 | n_tokens = 77703, memory_seq_rm [77703, end)
2026-05-17 02:07:31.493 | slot init_sampler: id  1 | task 20653 | init sampler, took 10.23 ms, tokens: text = 77707, total = 77707
2026-05-17 02:07:31.493 | slot update_slots: id  1 | task 20653 | prompt processing done, n_tokens = 77707, batch.n_tokens = 4
2026-05-17 02:07:31.841 | slot create_check: id  1 | task 20653 | created context checkpoint 25 of 32 (pos_min = 77702, pos_max = 77702, n_tokens = 77703, size = 312.357 MiB)
2026-05-17 02:07:31.883 | srv  log_server_r: done request: POST /v1/chat/completions 172.18.0.1 200
2026-05-17 02:07:42.320 | reasoning-budget: deactivated (natural end)
2026-05-17 02:07:43.175 | slot print_timing: id  1 | task 20653 | 
2026-05-17 02:07:43.175 | prompt eval time =    3310.10 ms /  3535 tokens (    0.94 ms per token,  1067.94 tokens per second)
2026-05-17 02:07:43.175 |        eval time =   11292.19 ms /   559 tokens (   20.20 ms per token,    49.50 tokens per second)
2026-05-17 02:07:43.175 |       total time =   14602.29 ms /  4094 tokens
2026-05-17 02:07:43.175 | draft acceptance rate = 0.97902 (  280 accepted /   286 generated)
2026-05-17 02:07:43.175 | statistics mtp: #calls(b,g,a) = 92 19240 14474, #gen drafts = 14474, #acc drafts = 14474, #gen tokens = 25548, #acc tokens = 25135, dur(b,g,a) = 0.140, 74029.916, 7.103 ms
2026-05-17 02:07:43.177 | slot      release: id  1 | task 20653 | stop processing: n_tokens = 78265, truncated = 0
2026-05-17 02:07:43.177 | srv  update_slots: all slots are idle
2026-05-17 02:07:43.779 | srv  params_from_: Chat format: peg-native
2026-05-17 02:07:43.782 | slot get_availabl: id  1 | task -1 | selected slot by LCP similarity, sim_best = 0.876 (> 0.100 thold), f_keep = 1.000
2026-05-17 02:07:43.783 | reasoning-budget: activated, budget=2147483647 tokens
2026-05-17 02:07:43.783 | slot launch_slot_: id  1 | task -1 | sampler chain: logits -> penalties -> ?dry -> ?top-n-sigma -> top-k -> ?typical -> ?top-p -> min-p -> ?xtc -> ?temp-ext -> dist 
2026-05-17 02:07:43.783 | slot launch_slot_: id  1 | task 20959 | processing task, is_child = 0
2026-05-17 02:07:43.783 | slot update_slots: id  1 | task 20959 | new prompt, n_ctx_slot = 131072, n_keep = 0, task.n_tokens = 89301
2026-05-17 02:07:43.783 | slot update_slots: id  1 | task 20959 | n_tokens = 78265, memory_seq_rm [78265, end)
2026-05-17 02:07:43.783 | slot update_slots: id  1 | task 20959 | prompt processing progress, n_tokens = 80313, batch.n_tokens = 2048, progress = 0.899352
2026-05-17 02:07:45.335 | slot update_slots: id  1 | task 20959 | n_tokens = 80313, memory_seq_rm [80313, end)
2026-05-17 02:07:45.336 | slot update_slots: id  1 | task 20959 | prompt processing progress, n_tokens = 82361, batch.n_tokens = 2048, progress = 0.922285
2026-05-17 02:07:46.907 | slot update_slots: id  1 | task 20959 | n_tokens = 82361, memory_seq_rm [82361, end)
2026-05-17 02:07:46.907 | slot update_slots: id  1 | task 20959 | prompt processing progress, n_tokens = 84409, batch.n_tokens = 2048, progress = 0.945219
2026-05-17 02:07:48.495 | slot update_slots: id  1 | task 20959 | n_tokens = 84409, memory_seq_rm [84409, end)
2026-05-17 02:07:48.495 | slot update_slots: id  1 | task 20959 | prompt processing progress, n_tokens = 86457, batch.n_tokens = 2048, progress = 0.968153
2026-05-17 02:07:50.115 | slot update_slots: id  1 | task 20959 | n_tokens = 86457, memory_seq_rm [86457, end)
2026-05-17 02:07:50.115 | slot update_slots: id  1 | task 20959 | 8192 tokens since last checkpoint at 77703, creating new checkpoint during processing at position 88505
2026-05-17 02:07:50.115 | slot update_slots: id  1 | task 20959 | prompt processing progress, n_tokens = 88505, batch.n_tokens = 2048, progress = 0.991086
2026-05-17 02:07:50.458 | slot create_check: id  1 | task 20959 | created context checkpoint 26 of 32 (pos_min = 86456, pos_max = 86456, n_tokens = 86457, size = 330.690 MiB)
2026-05-17 02:07:52.103 | slot update_slots: id  1 | task 20959 | n_tokens = 88505, memory_seq_rm [88505, end)
2026-05-17 02:07:52.103 | slot update_slots: id  1 | task 20959 | prompt processing progress, n_tokens = 88785, batch.n_tokens = 280, progress = 0.994222
2026-05-17 02:07:52.303 | slot update_slots: id  1 | task 20959 | n_tokens = 88785, memory_seq_rm [88785, end)
2026-05-17 02:07:52.303 | slot update_slots: id  1 | task 20959 | prompt processing progress, n_tokens = 89297, batch.n_tokens = 512, progress = 0.999955
2026-05-17 02:07:52.675 | slot create_check: id  1 | task 20959 | created context checkpoint 27 of 32 (pos_min = 88784, pos_max = 88784, n_tokens = 88785, size = 335.566 MiB)
2026-05-17 02:07:53.103 | slot update_slots: id  1 | task 20959 | n_tokens = 89297, memory_seq_rm [89297, end)
2026-05-17 02:07:53.114 | slot init_sampler: id  1 | task 20959 | init sampler, took 11.23 ms, tokens: text = 89301, total = 89301
2026-05-17 02:07:53.114 | slot update_slots: id  1 | task 20959 | prompt processing done, n_tokens = 89301, batch.n_tokens = 4
2026-05-17 02:07:53.484 | slot create_check: id  1 | task 20959 | created context checkpoint 28 of 32 (pos_min = 89296, pos_max = 89296, n_tokens = 89297, size = 336.638 MiB)
2026-05-17 02:07:53.527 | srv  log_server_r: done request: POST /v1/chat/completions 172.18.0.1 200
2026-05-17 02:08:08.113 | reasoning-budget: deactivated (natural end)
2026-05-17 02:08:20.725 | slot print_timing: id  1 | task 20959 | 
2026-05-17 02:08:20.725 | prompt eval time =    9743.23 ms / 11036 tokens (    0.88 ms per token,  1132.68 tokens per second)
2026-05-17 02:08:20.725 |        eval time =   27317.76 ms /  1326 tokens (   20.60 ms per token,    48.54 tokens per second)
2026-05-17 02:08:20.725 |       total time =   37060.99 ms / 12362 tokens
2026-05-17 02:08:20.725 | draft acceptance rate = 0.98514 (  663 accepted /   673 generated)
2026-05-17 02:08:20.725 | statistics mtp: #calls(b,g,a) = 93 19902 14872, #gen drafts = 14872, #acc drafts = 14872, #gen tokens = 26221, #acc tokens = 25798, dur(b,g,a) = 0.142, 76591.628, 7.323 ms
2026-05-17 02:08:20.727 | slot      release: id  1 | task 20959 | stop processing: n_tokens = 90626, truncated = 0
2026-05-17 02:08:20.727 | srv  update_slots: all slots are idle
2026-05-17 02:11:24.147 | srv  params_from_: Chat format: peg-native
2026-05-17 02:11:24.150 | slot get_availabl: id  1 | task -1 | selected slot by LCP similarity, sim_best = 0.821 (> 0.100 thold), f_keep = 0.809
2026-05-17 02:11:24.151 | reasoning-budget: activated, budget=2147483647 tokens
2026-05-17 02:11:24.152 | slot launch_slot_: id  1 | task -1 | sampler chain: logits -> penalties -> ?dry -> ?top-n-sigma -> top-k -> ?typical -> ?top-p -> min-p -> ?xtc -> ?temp-ext -> dist 
2026-05-17 02:11:24.152 | slot launch_slot_: id  1 | task 21668 | processing task, is_child = 0
2026-05-17 02:11:24.152 | slot update_slots: id  1 | task 21668 | new prompt, n_ctx_slot = 131072, n_keep = 0, task.n_tokens = 89309
2026-05-17 02:11:24.152 | slot update_slots: id  1 | task 21668 | n_past = 73308, slot.prompt.tokens.size() = 90626, seq_id = 1, pos_min = 90625, n_swa = 0
2026-05-17 02:11:24.152 | slot update_slots: id  1 | task 21668 | Checking checkpoint with [89296, 89296] against 73308...
2026-05-17 02:11:24.152 | slot update_slots: id  1 | task 21668 | Checking checkpoint with [88784, 88784] against 73308...
2026-05-17 02:11:24.152 | slot update_slots: id  1 | task 21668 | Checking checkpoint with [86456, 86456] against 73308...
2026-05-17 02:11:24.152 | slot update_slots: id  1 | task 21668 | Checking checkpoint with [77702, 77702] against 73308...
2026-05-17 02:11:24.152 | slot update_slots: id  1 | task 21668 | Checking checkpoint with [77190, 77190] against 73308...
2026-05-17 02:11:24.152 | slot update_slots: id  1 | task 21668 | Checking checkpoint with [74013, 74013] against 73308...
2026-05-17 02:11:24.152 | slot update_slots: id  1 | task 21668 | Checking checkpoint with [73839, 73839] against 73308...
2026-05-17 02:11:24.152 | slot update_slots: id  1 | task 21668 | Checking checkpoint with [73618, 73618] against 73308...
2026-05-17 02:11:24.152 | slot update_slots: id  1 | task 21668 | Checking checkpoint with [73106, 73106] against 73308...
2026-05-17 02:11:24.218 | slot update_slots: id  1 | task 21668 | restored context checkpoint (pos_min = 73106, pos_max = 73106, n_tokens = 73107, n_past = 73107, size = 302.732 MiB)
2026-05-17 02:11:24.218 | slot update_slots: id  1 | task 21668 | erased invalidated context checkpoint (pos_min = 73618, pos_max = 73618, n_tokens = 73619, n_swa = 0, pos_next = 73107, size = 303.804 MiB)
2026-05-17 02:11:24.235 | slot update_slots: id  1 | task 21668 | erased invalidated context checkpoint (pos_min = 73839, pos_max = 73839, n_tokens = 73840, n_swa = 0, pos_next = 73107, size = 304.267 MiB)
2026-05-17 02:11:24.253 | slot update_slots: id  1 | task 21668 | erased invalidated context checkpoint (pos_min = 74013, pos_max = 74013, n_tokens = 74014, n_swa = 0, pos_next = 73107, size = 304.631 MiB)
2026-05-17 02:11:24.270 | slot update_slots: id  1 | task 21668 | erased invalidated context checkpoint (pos_min = 77190, pos_max = 77190, n_tokens = 77191, n_swa = 0, pos_next = 73107, size = 311.285 MiB)
2026-05-17 02:11:24.288 | slot update_slots: id  1 | task 21668 | erased invalidated context checkpoint (pos_min = 77702, pos_max = 77702, n_tokens = 77703, n_swa = 0, pos_next = 73107, size = 312.357 MiB)
2026-05-17 02:11:24.307 | slot update_slots: id  1 | task 21668 | erased invalidated context checkpoint (pos_min = 86456, pos_max = 86456, n_tokens = 86457, n_swa = 0, pos_next = 73107, size = 330.690 MiB)
2026-05-17 02:11:24.327 | slot update_slots: id  1 | task 21668 | erased invalidated context checkpoint (pos_min = 88784, pos_max = 88784, n_tokens = 88785, n_swa = 0, pos_next = 73107, size = 335.566 MiB)
2026-05-17 02:11:24.347 | slot update_slots: id  1 | task 21668 | erased invalidated context checkpoint (pos_min = 89296, pos_max = 89296, n_tokens = 89297, n_swa = 0, pos_next = 73107, size = 336.638 MiB)
2026-05-17 02:11:24.366 | slot update_slots: id  1 | task 21668 | n_tokens = 73107, memory_seq_rm [73107, end)
2026-05-17 02:11:24.368 | slot update_slots: id  1 | task 21668 | prompt processing progress, n_tokens = 75155, batch.n_tokens = 2048, progress = 0.841517
2026-05-17 02:11:25.723 | slot update_slots: id  1 | task 21668 | n_tokens = 75155, memory_seq_rm [75155, end)
2026-05-17 02:11:25.723 | slot update_slots: id  1 | task 21668 | prompt processing progress, n_tokens = 77203, batch.n_tokens = 2048, progress = 0.864448
2026-05-17 02:11:27.194 | slot update_slots: id  1 | task 21668 | n_tokens = 77203, memory_seq_rm [77203, end)
2026-05-17 02:11:27.194 | slot update_slots: id  1 | task 21668 | prompt processing progress, n_tokens = 79251, batch.n_tokens = 2048, progress = 0.887380
2026-05-17 02:11:28.704 | slot update_slots: id  1 | task 21668 | n_tokens = 79251, memory_seq_rm [79251, end)
2026-05-17 02:11:28.704 | slot update_slots: id  1 | task 21668 | prompt processing progress, n_tokens = 81299, batch.n_tokens = 2048, progress = 0.910311
2026-05-17 02:11:30.229 | slot update_slots: id  1 | task 21668 | n_tokens = 81299, memory_seq_rm [81299, end)
2026-05-17 02:11:30.230 | slot update_slots: id  1 | task 21668 | 8192 tokens since last checkpoint at 73107, creating new checkpoint during processing at position 83347
2026-05-17 02:11:30.230 | slot update_slots: id  1 | task 21668 | prompt processing progress, n_tokens = 83347, batch.n_tokens = 2048, progress = 0.933243
2026-05-17 02:11:30.560 | slot create_check: id  1 | task 21668 | created context checkpoint 21 of 32 (pos_min = 81298, pos_max = 81298, n_tokens = 81299, size = 319.888 MiB)
2026-05-17 02:11:32.125 | slot update_slots: id  1 | task 21668 | n_tokens = 83347, memory_seq_rm [83347, end)
2026-05-17 02:11:32.125 | slot update_slots: id  1 | task 21668 | prompt processing progress, n_tokens = 85395, batch.n_tokens = 2048, progress = 0.956175
2026-05-17 02:11:33.718 | slot update_slots: id  1 | task 21668 | n_tokens = 85395, memory_seq_rm [85395, end)
2026-05-17 02:11:33.718 | slot update_slots: id  1 | task 21668 | prompt processing progress, n_tokens = 87443, batch.n_tokens = 2048, progress = 0.979106
2026-05-17 02:11:35.359 | slot update_slots: id  1 | task 21668 | n_tokens = 87443, memory_seq_rm [87443, end)
2026-05-17 02:11:35.359 | slot update_slots: id  1 | task 21668 | prompt processing progress, n_tokens = 88793, batch.n_tokens = 1350, progress = 0.994222
2026-05-17 02:11:36.408 | slot update_slots: id  1 | task 21668 | n_tokens = 88793, memory_seq_rm [88793, end)
2026-05-17 02:11:36.408 | slot update_slots: id  1 | task 21668 | prompt processing progress, n_tokens = 89305, batch.n_tokens = 512, progress = 0.999955
2026-05-17 02:11:36.770 | slot create_check: id  1 | task 21668 | created context checkpoint 22 of 32 (pos_min = 88792, pos_max = 88792, n_tokens = 88793, size = 335.583 MiB)
2026-05-17 02:11:37.192 | slot update_slots: id  1 | task 21668 | n_tokens = 89305, memory_seq_rm [89305, end)
2026-05-17 02:11:37.203 | slot init_sampler: id  1 | task 21668 | init sampler, took 11.23 ms, tokens: text = 89309, total = 89309
2026-05-17 02:11:37.203 | slot update_slots: id  1 | task 21668 | prompt processing done, n_tokens = 89309, batch.n_tokens = 4
2026-05-17 02:11:37.580 | slot create_check: id  1 | task 21668 | created context checkpoint 23 of 32 (pos_min = 89304, pos_max = 89304, n_tokens = 89305, size = 336.655 MiB)
2026-05-17 02:11:37.624 | srv  log_server_r: done request: POST /v1/chat/completions 172.18.0.1 200
2026-05-17 02:11:43.732 | reasoning-budget: deactivated (natural end)
2026-05-17 02:11:45.054 | slot print_timing: id  1 | task 21668 | 
2026-05-17 02:11:45.054 | prompt eval time =   13585.12 ms / 16202 tokens (    0.84 ms per token,  1192.63 tokens per second)
2026-05-17 02:11:45.054 |        eval time =    7429.75 ms /   416 tokens (   17.86 ms per token,    55.99 tokens per second)
2026-05-17 02:11:45.054 |       total time =   21014.88 ms / 16618 tokens
2026-05-17 02:11:45.054 | draft acceptance rate = 0.99200 (  248 accepted /   250 generated)
2026-05-17 02:11:45.054 | statistics mtp: #calls(b,g,a) = 94 20069 15013, #gen drafts = 15013, #acc drafts = 15013, #gen tokens = 26471, #acc tokens = 26046, dur(b,g,a) = 0.144, 77352.015, 7.402 ms
2026-05-17 02:11:45.056 | slot      release: id  1 | task 21668 | stop processing: n_tokens = 89724, truncated = 0
2026-05-17 02:11:45.056 | srv  update_slots: all slots are idle
2026-05-17 02:11:45.378 | srv  params_from_: Chat format: peg-native
2026-05-17 02:11:45.380 | slot get_availabl: id  1 | task -1 | selected slot by LCP similarity, sim_best = 0.924 (> 0.100 thold), f_keep = 1.000
2026-05-17 02:11:45.382 | reasoning-budget: activated, budget=2147483647 tokens
2026-05-17 02:11:45.382 | slot launch_slot_: id  1 | task -1 | sampler chain: logits -> penalties -> ?dry -> ?top-n-sigma -> top-k -> ?typical -> ?top-p -> min-p -> ?xtc -> ?temp-ext -> dist 
2026-05-17 02:11:45.382 | slot launch_slot_: id  1 | task 21861 | processing task, is_child = 0
2026-05-17 02:11:45.382 | slot update_slots: id  1 | task 21861 | new prompt, n_ctx_slot = 131072, n_keep = 0, task.n_tokens = 97113
2026-05-17 02:11:45.382 | slot update_slots: id  1 | task 21861 | n_tokens = 89724, memory_seq_rm [89724, end)
2026-05-17 02:11:45.382 | slot update_slots: id  1 | task 21861 | prompt processing progress, n_tokens = 91772, batch.n_tokens = 2048, progress = 0.945002
2026-05-17 02:11:47.078 | slot update_slots: id  1 | task 21861 | n_tokens = 91772, memory_seq_rm [91772, end)
2026-05-17 02:11:47.078 | slot update_slots: id  1 | task 21861 | prompt processing progress, n_tokens = 93820, batch.n_tokens = 2048, progress = 0.966091
2026-05-17 02:11:48.782 | slot update_slots: id  1 | task 21861 | n_tokens = 93820, memory_seq_rm [93820, end)
2026-05-17 02:11:48.782 | slot update_slots: id  1 | task 21861 | prompt processing progress, n_tokens = 95868, batch.n_tokens = 2048, progress = 0.987180
2026-05-17 02:11:50.514 | slot update_slots: id  1 | task 21861 | n_tokens = 95868, memory_seq_rm [95868, end)
2026-05-17 02:11:50.514 | slot update_slots: id  1 | task 21861 | prompt processing progress, n_tokens = 96597, batch.n_tokens = 729, progress = 0.994687
2026-05-17 02:11:51.120 | slot update_slots: id  1 | task 21861 | n_tokens = 96597, memory_seq_rm [96597, end)
2026-05-17 02:11:51.120 | slot update_slots: id  1 | task 21861 | prompt processing progress, n_tokens = 97109, batch.n_tokens = 512, progress = 0.999959
2026-05-17 02:11:51.508 | slot create_check: id  1 | task 21861 | created context checkpoint 24 of 32 (pos_min = 96596, pos_max = 96596, n_tokens = 96597, size = 351.926 MiB)
2026-05-17 02:11:51.951 | slot update_slots: id  1 | task 21861 | n_tokens = 97109, memory_seq_rm [97109, end)
2026-05-17 02:11:51.964 | slot init_sampler: id  1 | task 21861 | init sampler, took 12.32 ms, tokens: text = 97113, total = 97113
2026-05-17 02:11:51.964 | slot update_slots: id  1 | task 21861 | prompt processing done, n_tokens = 97113, batch.n_tokens = 4
2026-05-17 02:11:52.359 | slot create_check: id  1 | task 21861 | created context checkpoint 25 of 32 (pos_min = 97108, pos_max = 97108, n_tokens = 97109, size = 352.999 MiB)
2026-05-17 02:11:52.403 | srv  log_server_r: done request: POST /v1/chat/completions 172.18.0.1 200
2026-05-17 02:11:52.911 | reasoning-budget: deactivated (natural end)
2026-05-17 02:11:58.028 | srv          stop: cancel task, id_task = 21861
2026-05-17 02:11:58.078 | slot      release: id  1 | task 21861 | stop processing: n_tokens = 97450, truncated = 0
2026-05-17 02:11:58.078 | srv  update_slots: all slots are idle
2026-05-17 02:18:24.780 | srv  params_from_: Chat format: peg-native
2026-05-17 02:18:24.783 | slot get_availabl: id  1 | task -1 | selected slot by LCP similarity, sim_best = 0.890 (> 0.100 thold), f_keep = 0.913
2026-05-17 02:18:24.784 | reasoning-budget: activated, budget=2147483647 tokens
2026-05-17 02:18:24.784 | slot launch_slot_: id  1 | task -1 | sampler chain: logits -> penalties -> ?dry -> ?top-n-sigma -> top-k -> ?typical -> ?top-p -> min-p -> ?xtc -> ?temp-ext -> dist 
2026-05-17 02:18:24.784 | slot launch_slot_: id  1 | task 22008 | processing task, is_child = 0
2026-05-17 02:18:24.784 | slot update_slots: id  1 | task 22008 | new prompt, n_ctx_slot = 131072, n_keep = 0, task.n_tokens = 99964
2026-05-17 02:18:24.784 | slot update_slots: id  1 | task 22008 | n_past = 88994, slot.prompt.tokens.size() = 97450, seq_id = 1, pos_min = 97449, n_swa = 0
2026-05-17 02:18:24.784 | slot update_slots: id  1 | task 22008 | Checking checkpoint with [97108, 97108] against 88994...
2026-05-17 02:18:24.784 | slot update_slots: id  1 | task 22008 | Checking checkpoint with [96596, 96596] against 88994...
2026-05-17 02:18:24.784 | slot update_slots: id  1 | task 22008 | Checking checkpoint with [89304, 89304] against 88994...
2026-05-17 02:18:24.784 | slot update_slots: id  1 | task 22008 | Checking checkpoint with [88792, 88792] against 88994...
2026-05-17 02:18:24.919 | slot update_slots: id  1 | task 22008 | restored context checkpoint (pos_min = 88792, pos_max = 88792, n_tokens = 88793, n_past = 88793, size = 335.583 MiB)
2026-05-17 02:18:24.919 | slot update_slots: id  1 | task 22008 | erased invalidated context checkpoint (pos_min = 89304, pos_max = 89304, n_tokens = 89305, n_swa = 0, pos_next = 88793, size = 336.655 MiB)
2026-05-17 02:18:24.938 | slot update_slots: id  1 | task 22008 | erased invalidated context checkpoint (pos_min = 96596, pos_max = 96596, n_tokens = 96597, n_swa = 0, pos_next = 88793, size = 351.926 MiB)
2026-05-17 02:18:24.957 | slot update_slots: id  1 | task 22008 | erased invalidated context checkpoint (pos_min = 97108, pos_max = 97108, n_tokens = 97109, n_swa = 0, pos_next = 88793, size = 352.999 MiB)
2026-05-17 02:18:24.977 | slot update_slots: id  1 | task 22008 | n_tokens = 88793, memory_seq_rm [88793, end)
2026-05-17 02:18:24.978 | slot update_slots: id  1 | task 22008 | prompt processing progress, n_tokens = 90841, batch.n_tokens = 2048, progress = 0.908737
2026-05-17 02:18:26.842 | slot update_slots: id  1 | task 22008 | n_tokens = 90841, memory_seq_rm [90841, end)
2026-05-17 02:18:26.843 | slot update_slots: id  1 | task 22008 | prompt processing progress, n_tokens = 92889, batch.n_tokens = 2048, progress = 0.929224
2026-05-17 02:18:28.527 | slot update_slots: id  1 | task 22008 | n_tokens = 92889, memory_seq_rm [92889, end)
2026-05-17 02:18:28.527 | slot update_slots: id  1 | task 22008 | prompt processing progress, n_tokens = 94937, batch.n_tokens = 2048, progress = 0.949712
2026-05-17 02:18:30.229 | slot update_slots: id  1 | task 22008 | n_tokens = 94937, memory_seq_rm [94937, end)
2026-05-17 02:18:30.229 | slot update_slots: id  1 | task 22008 | prompt processing progress, n_tokens = 96985, batch.n_tokens = 2048, progress = 0.970199
2026-05-17 02:18:31.926 | slot update_slots: id  1 | task 22008 | n_tokens = 96985, memory_seq_rm [96985, end)
2026-05-17 02:18:31.926 | slot update_slots: id  1 | task 22008 | 8192 tokens since last checkpoint at 88793, creating new checkpoint during processing at position 99033
2026-05-17 02:18:31.926 | slot update_slots: id  1 | task 22008 | prompt processing progress, n_tokens = 99033, batch.n_tokens = 2048, progress = 0.990687
2026-05-17 02:18:32.286 | slot create_check: id  1 | task 22008 | created context checkpoint 23 of 32 (pos_min = 96984, pos_max = 96984, n_tokens = 96985, size = 352.739 MiB)
2026-05-17 02:18:34.065 | slot update_slots: id  1 | task 22008 | n_tokens = 99033, memory_seq_rm [99033, end)
2026-05-17 02:18:34.065 | slot update_slots: id  1 | task 22008 | prompt processing progress, n_tokens = 99448, batch.n_tokens = 415, progress = 0.994838
2026-05-17 02:18:34.444 | slot update_slots: id  1 | task 22008 | n_tokens = 99448, memory_seq_rm [99448, end)
2026-05-17 02:18:34.444 | slot update_slots: id  1 | task 22008 | prompt processing progress, n_tokens = 99960, batch.n_tokens = 512, progress = 0.999960
2026-05-17 02:18:34.840 | slot create_check: id  1 | task 22008 | created context checkpoint 24 of 32 (pos_min = 99447, pos_max = 99447, n_tokens = 99448, size = 357.897 MiB)
2026-05-17 02:18:35.289 | slot update_slots: id  1 | task 22008 | n_tokens = 99960, memory_seq_rm [99960, end)
2026-05-17 02:18:35.302 | slot init_sampler: id  1 | task 22008 | init sampler, took 12.88 ms, tokens: text = 99964, total = 99964
2026-05-17 02:18:35.302 | slot update_slots: id  1 | task 22008 | prompt processing done, n_tokens = 99964, batch.n_tokens = 4
2026-05-17 02:18:35.703 | slot create_check: id  1 | task 22008 | created context checkpoint 25 of 32 (pos_min = 99959, pos_max = 99959, n_tokens = 99960, size = 358.969 MiB)
2026-05-17 02:18:35.749 | srv  log_server_r: done request: POST /v1/chat/completions 172.18.0.1 200
2026-05-17 02:18:42.756 | reasoning-budget: deactivated (natural end)
2026-05-17 02:18:47.740 | slot print_timing: id  1 | task 22008 | 
2026-05-17 02:18:47.740 | prompt eval time =   10963.85 ms / 11171 tokens (    0.98 ms per token,  1018.89 tokens per second)
2026-05-17 02:18:47.740 |        eval time =   11991.00 ms /   571 tokens (   21.00 ms per token,    47.62 tokens per second)
2026-05-17 02:18:47.740 |       total time =   22954.85 ms / 11742 tokens
2026-05-17 02:18:47.740 | draft acceptance rate = 0.98333 (  295 accepted /   300 generated)
2026-05-17 02:18:47.740 | statistics mtp: #calls(b,g,a) = 96 20474 15308, #gen drafts = 15308, #acc drafts = 15308, #gen tokens = 26980, #acc tokens = 26548, dur(b,g,a) = 0.148, 79111.641, 7.544 ms
2026-05-17 02:18:47.742 | slot      release: id  1 | task 22008 | stop processing: n_tokens = 100534, truncated = 0
2026-05-17 02:18:47.742 | srv  update_slots: all slots are idle
2026-05-17 02:18:48.004 | srv  params_from_: Chat format: peg-native
2026-05-17 02:18:48.005 | slot get_availabl: id  0 | task -1 | selected slot by LRU, t_last = 8040065712
2026-05-17 02:18:48.005 | srv  get_availabl: updating prompt cache
2026-05-17 02:18:48.005 | srv          load:  - looking for better prompt, base f_keep = -1.000, sim = 0.000
2026-05-17 02:18:48.005 | srv        update:  - cache state: 1 prompts, 2845.379 MiB (limits: 8192.000 MiB, 131072 tokens, 131072 est)
2026-05-17 02:18:48.005 | srv        update:    - prompt 0x590a384d2ce0:   41362 tokens, checkpoints:  6,  2845.379 MiB
2026-05-17 02:18:48.005 | srv  get_availabl: prompt cache update took 0.04 ms
2026-05-17 02:18:48.006 | slot launch_slot_: id  0 | task -1 | sampler chain: logits -> penalties -> ?dry -> ?top-n-sigma -> top-k -> ?typical -> ?top-p -> min-p -> ?xtc -> ?temp-ext -> dist 
2026-05-17 02:18:48.006 | slot launch_slot_: id  0 | task 22309 | processing task, is_child = 0
2026-05-17 02:18:48.006 | slot slot_save_an: id  1 | task -1 | saving idle slot to prompt cache
2026-05-17 02:18:48.010 | srv   prompt_save:  - saving prompt with length 100534, total state size = 3700.132 MiB (draft: 210.545 MiB)
2026-05-17 02:18:59.016 | slot prompt_clear: id  1 | task -1 | clearing prompt with 100534 tokens
2026-05-17 02:18:59.034 | srv        update:  - cache size limit reached, removing oldest entry (size = 2845.379 MiB)
2026-05-17 02:18:59.213 | srv        update:  - cache state: 1 prompts, 10246.133 MiB (limits: 8192.000 MiB, 131072 tokens, 131072 est)
2026-05-17 02:18:59.213 | srv        update:    - prompt 0x590a38300210:  100534 tokens, checkpoints: 25, 10246.133 MiB
2026-05-17 02:18:59.214 | slot update_slots: id  0 | task 22309 | new prompt, n_ctx_slot = 131072, n_keep = 0, task.n_tokens = 45668
2026-05-17 02:18:59.214 | slot update_slots: id  0 | task 22309 | erased invalidated context checkpoint (pos_min = 345, pos_max = 345, n_tokens = 346, n_swa = 0, pos_next = 0, size = 150.351 MiB)
2026-05-17 02:18:59.223 | slot update_slots: id  0 | task 22309 | erased invalidated context checkpoint (pos_min = 468, pos_max = 468, n_tokens = 469, n_swa = 0, pos_next = 0, size = 150.608 MiB)
2026-05-17 02:18:59.232 | slot update_slots: id  0 | task 22309 | erased invalidated context checkpoint (pos_min = 980, pos_max = 980, n_tokens = 981, n_swa = 0, pos_next = 0, size = 151.681 MiB)
2026-05-17 02:18:59.242 | slot update_slots: id  0 | task 22309 | n_tokens = 0, memory_seq_rm [0, end)
2026-05-17 02:18:59.242 | slot update_slots: id  0 | task 22309 | prompt processing progress, n_tokens = 2048, batch.n_tokens = 2048, progress = 0.044845
2026-05-17 02:18:59.939 | slot update_slots: id  0 | task 22309 | n_tokens = 2048, memory_seq_rm [2048, end)
2026-05-17 02:18:59.939 | slot update_slots: id  0 | task 22309 | prompt processing progress, n_tokens = 4096, batch.n_tokens = 2048, progress = 0.089691
2026-05-17 02:19:00.644 | slot update_slots: id  0 | task 22309 | n_tokens = 4096, memory_seq_rm [4096, end)
2026-05-17 02:19:00.644 | slot update_slots: id  0 | task 22309 | prompt processing progress, n_tokens = 6144, batch.n_tokens = 2048, progress = 0.134536
2026-05-17 02:19:01.361 | slot update_slots: id  0 | task 22309 | n_tokens = 6144, memory_seq_rm [6144, end)
2026-05-17 02:19:01.361 | slot update_slots: id  0 | task 22309 | prompt processing progress, n_tokens = 8192, batch.n_tokens = 2048, progress = 0.179382
2026-05-17 02:19:02.091 | slot update_slots: id  0 | task 22309 | n_tokens = 8192, memory_seq_rm [8192, end)
2026-05-17 02:19:02.091 | slot update_slots: id  0 | task 22309 | 8192 tokens since last checkpoint at 0, creating new checkpoint during processing at position 10240
2026-05-17 02:19:02.091 | slot update_slots: id  0 | task 22309 | prompt processing progress, n_tokens = 10240, batch.n_tokens = 2048, progress = 0.224227
2026-05-17 02:19:02.210 | slot create_check: id  0 | task 22309 | created context checkpoint 1 of 32 (pos_min = 8191, pos_max = 8191, n_tokens = 8192, size = 166.782 MiB)
2026-05-17 02:19:02.951 | slot update_slots: id  0 | task 22309 | n_tokens = 10240, memory_seq_rm [10240, end)
2026-05-17 02:19:02.951 | slot update_slots: id  0 | task 22309 | prompt processing progress, n_tokens = 12288, batch.n_tokens = 2048, progress = 0.269072
2026-05-17 02:19:03.704 | slot update_slots: id  0 | task 22309 | n_tokens = 12288, memory_seq_rm [12288, end)
2026-05-17 02:19:03.704 | slot update_slots: id  0 | task 22309 | prompt processing progress, n_tokens = 14336, batch.n_tokens = 2048, progress = 0.313918
2026-05-17 02:19:04.470 | slot update_slots: id  0 | task 22309 | n_tokens = 14336, memory_seq_rm [14336, end)
2026-05-17 02:19:04.470 | slot update_slots: id  0 | task 22309 | prompt processing progress, n_tokens = 16384, batch.n_tokens = 2048, progress = 0.358763
2026-05-17 02:19:05.249 | slot update_slots: id  0 | task 22309 | n_tokens = 16384, memory_seq_rm [16384, end)
2026-05-17 02:19:05.249 | slot update_slots: id  0 | task 22309 | 8192 tokens since last checkpoint at 8192, creating new checkpoint during processing at position 18432
2026-05-17 02:19:05.249 | slot update_slots: id  0 | task 22309 | prompt processing progress, n_tokens = 18432, batch.n_tokens = 2048, progress = 0.403609
2026-05-17 02:19:05.387 | slot create_check: id  0 | task 22309 | created context checkpoint 2 of 32 (pos_min = 16383, pos_max = 16383, n_tokens = 16384, size = 183.939 MiB)
2026-05-17 02:19:06.176 | slot update_slots: id  0 | task 22309 | n_tokens = 18432, memory_seq_rm [18432, end)
2026-05-17 02:19:06.176 | slot update_slots: id  0 | task 22309 | prompt processing progress, n_tokens = 20480, batch.n_tokens = 2048, progress = 0.448454
2026-05-17 02:19:06.981 | slot update_slots: id  0 | task 22309 | n_tokens = 20480, memory_seq_rm [20480, end)
2026-05-17 02:19:06.981 | slot update_slots: id  0 | task 22309 | prompt processing progress, n_tokens = 22528, batch.n_tokens = 2048, progress = 0.493299
2026-05-17 02:19:07.800 | slot update_slots: id  0 | task 22309 | n_tokens = 22528, memory_seq_rm [22528, end)
2026-05-17 02:19:07.800 | slot update_slots: id  0 | task 22309 | prompt processing progress, n_tokens = 24576, batch.n_tokens = 2048, progress = 0.538145
2026-05-17 02:19:08.635 | slot update_slots: id  0 | task 22309 | n_tokens = 24576, memory_seq_rm [24576, end)
2026-05-17 02:19:08.635 | slot update_slots: id  0 | task 22309 | 8192 tokens since last checkpoint at 16384, creating new checkpoint during processing at position 26624
2026-05-17 02:19:08.635 | slot update_slots: id  0 | task 22309 | prompt processing progress, n_tokens = 26624, batch.n_tokens = 2048, progress = 0.582990
2026-05-17 02:19:08.864 | slot create_check: id  0 | task 22309 | created context checkpoint 3 of 32 (pos_min = 24575, pos_max = 24575, n_tokens = 24576, size = 201.095 MiB)
2026-05-17 02:19:09.713 | slot update_slots: id  0 | task 22309 | n_tokens = 26624, memory_seq_rm [26624, end)
2026-05-17 02:19:09.713 | slot update_slots: id  0 | task 22309 | prompt processing progress, n_tokens = 28672, batch.n_tokens = 2048, progress = 0.627836
2026-05-17 02:19:10.582 | slot update_slots: id  0 | task 22309 | n_tokens = 28672, memory_seq_rm [28672, end)
2026-05-17 02:19:10.582 | slot update_slots: id  0 | task 22309 | prompt processing progress, n_tokens = 30720, batch.n_tokens = 2048, progress = 0.672681
2026-05-17 02:19:11.469 | slot update_slots: id  0 | task 22309 | n_tokens = 30720, memory_seq_rm [30720, end)
2026-05-17 02:19:11.469 | slot update_slots: id  0 | task 22309 | prompt processing progress, n_tokens = 32768, batch.n_tokens = 2048, progress = 0.717526
2026-05-17 02:19:12.376 | slot update_slots: id  0 | task 22309 | n_tokens = 32768, memory_seq_rm [32768, end)
2026-05-17 02:19:12.376 | slot update_slots: id  0 | task 22309 | 8192 tokens since last checkpoint at 24576, creating new checkpoint during processing at position 34816
2026-05-17 02:19:12.376 | slot update_slots: id  0 | task 22309 | prompt processing progress, n_tokens = 34816, batch.n_tokens = 2048, progress = 0.762372
2026-05-17 02:19:12.607 | slot create_check: id  0 | task 22309 | created context checkpoint 4 of 32 (pos_min = 32767, pos_max = 32767, n_tokens = 32768, size = 218.251 MiB)
2026-05-17 02:19:13.533 | slot update_slots: id  0 | task 22309 | n_tokens = 34816, memory_seq_rm [34816, end)
2026-05-17 02:19:13.533 | slot update_slots: id  0 | task 22309 | prompt processing progress, n_tokens = 36864, batch.n_tokens = 2048, progress = 0.807217
2026-05-17 02:19:14.482 | slot update_slots: id  0 | task 22309 | n_tokens = 36864, memory_seq_rm [36864, end)
2026-05-17 02:19:14.482 | slot update_slots: id  0 | task 22309 | prompt processing progress, n_tokens = 38912, batch.n_tokens = 2048, progress = 0.852063
2026-05-17 02:19:15.449 | slot update_slots: id  0 | task 22309 | n_tokens = 38912, memory_seq_rm [38912, end)
2026-05-17 02:19:15.449 | slot update_slots: id  0 | task 22309 | prompt processing progress, n_tokens = 40960, batch.n_tokens = 2048, progress = 0.896908
2026-05-17 02:19:16.440 | slot update_slots: id  0 | task 22309 | n_tokens = 40960, memory_seq_rm [40960, end)
2026-05-17 02:19:16.440 | slot update_slots: id  0 | task 22309 | 8192 tokens since last checkpoint at 32768, creating new checkpoint during processing at position 43008
2026-05-17 02:19:16.440 | slot update_slots: id  0 | task 22309 | prompt processing progress, n_tokens = 43008, batch.n_tokens = 2048, progress = 0.941754
2026-05-17 02:19:16.702 | slot create_check: id  0 | task 22309 | created context checkpoint 5 of 32 (pos_min = 40959, pos_max = 40959, n_tokens = 40960, size = 235.407 MiB)
2026-05-17 02:19:17.732 | slot update_slots: id  0 | task 22309 | n_tokens = 43008, memory_seq_rm [43008, end)
2026-05-17 02:19:17.732 | slot update_slots: id  0 | task 22309 | prompt processing progress, n_tokens = 45056, batch.n_tokens = 2048, progress = 0.986599
2026-05-17 02:19:18.777 | slot update_slots: id  0 | task 22309 | n_tokens = 45056, memory_seq_rm [45056, end)
2026-05-17 02:19:18.777 | slot update_slots: id  0 | task 22309 | prompt processing progress, n_tokens = 45152, batch.n_tokens = 96, progress = 0.988701
2026-05-17 02:19:18.854 | slot update_slots: id  0 | task 22309 | n_tokens = 45152, memory_seq_rm [45152, end)
2026-05-17 02:19:18.854 | slot update_slots: id  0 | task 22309 | prompt processing progress, n_tokens = 45664, batch.n_tokens = 512, progress = 0.999912
2026-05-17 02:19:19.124 | slot create_check: id  0 | task 22309 | created context checkpoint 6 of 32 (pos_min = 45151, pos_max = 45151, n_tokens = 45152, size = 244.187 MiB)
2026-05-17 02:19:19.392 | slot update_slots: id  0 | task 22309 | n_tokens = 45664, memory_seq_rm [45664, end)
2026-05-17 02:19:19.397 | slot init_sampler: id  0 | task 22309 | init sampler, took 5.80 ms, tokens: text = 45668, total = 45668
2026-05-17 02:19:19.397 | slot update_slots: id  0 | task 22309 | prompt processing done, n_tokens = 45668, batch.n_tokens = 4
2026-05-17 02:19:19.672 | slot create_check: id  0 | task 22309 | created context checkpoint 7 of 32 (pos_min = 45663, pos_max = 45663, n_tokens = 45664, size = 245.259 MiB)
2026-05-17 02:19:19.710 | srv  log_server_r: done request: POST /v1/chat/completions 172.18.0.1 200
2026-05-17 02:19:53.613 | slot print_timing: id  0 | task 22309 | 
2026-05-17 02:19:53.613 | prompt eval time =   20495.51 ms / 45668 tokens (    0.45 ms per token,  2228.20 tokens per second)
2026-05-17 02:19:53.613 |        eval time =   34001.13 ms /  2008 tokens (   16.93 ms per token,    59.06 tokens per second)
2026-05-17 02:19:53.613 |       total time =   54496.63 ms / 47676 tokens
2026-05-17 02:19:53.613 | draft acceptance rate = 0.99023 ( 1115 accepted /  1126 generated)
2026-05-17 02:19:53.613 | statistics mtp: #calls(b,g,a) = 97 21366 15943, #gen drafts = 15943, #acc drafts = 15943, #gen tokens = 28106, #acc tokens = 27663, dur(b,g,a) = 0.149, 82553.318, 7.845 ms
2026-05-17 02:19:53.614 | slot      release: id  0 | task 22309 | stop processing: n_tokens = 47675, truncated = 0
2026-05-17 02:19:53.614 | srv  update_slots: all slots are idle
2026-05-17 02:19:53.693 | srv  params_from_: Chat format: peg-native
2026-05-17 02:19:53.696 | slot get_availabl: id  2 | task -1 | selected slot by LRU, t_last = 12676056293
2026-05-17 02:19:53.696 | srv  get_availabl: updating prompt cache
2026-05-17 02:19:53.696 | srv          load:  - looking for better prompt, base f_keep = -1.000, sim = 0.000
2026-05-17 02:19:53.696 | srv        update:  - cache state: 1 prompts, 10246.133 MiB (limits: 8192.000 MiB, 131072 tokens, 131072 est)
2026-05-17 02:19:53.696 | srv        update:    - prompt 0x590a38300210:  100534 tokens, checkpoints: 25, 10246.133 MiB
2026-05-17 02:19:53.696 | srv  get_availabl: prompt cache update took 0.03 ms
2026-05-17 02:19:53.697 | reasoning-budget: activated, budget=2147483647 tokens
2026-05-17 02:19:53.697 | slot launch_slot_: id  2 | task -1 | sampler chain: logits -> penalties -> ?dry -> ?top-n-sigma -> top-k -> ?typical -> ?top-p -> min-p -> ?xtc -> ?temp-ext -> dist 
2026-05-17 02:19:53.697 | slot launch_slot_: id  2 | task 23275 | processing task, is_child = 0
2026-05-17 02:19:53.697 | slot slot_save_an: id  0 | task -1 | saving idle slot to prompt cache
2026-05-17 02:19:53.699 | srv   prompt_save:  - saving prompt with length 47675, total state size = 1833.339 MiB (draft: 99.844 MiB)
2026-05-17 02:19:57.123 | slot prompt_clear: id  0 | task -1 | clearing prompt with 47675 tokens
2026-05-17 02:19:57.131 | srv        update:  - cache size limit reached, removing oldest entry (size = 10246.133 MiB)
2026-05-17 02:19:57.706 | srv        update:  - cache state: 1 prompts, 3328.259 MiB (limits: 8192.000 MiB, 131072 tokens, 131072 est)
2026-05-17 02:19:57.706 | srv        update:    - prompt 0x590a332c8f00:   47675 tokens, checkpoints:  7,  3328.259 MiB
2026-05-17 02:19:57.706 | slot update_slots: id  2 | task 23275 | new prompt, n_ctx_slot = 131072, n_keep = 0, task.n_tokens = 13273
2026-05-17 02:19:57.706 | slot update_slots: id  2 | task 23275 | erased invalidated context checkpoint (pos_min = 8191, pos_max = 8191, n_tokens = 8192, n_swa = 0, pos_next = 0, size = 166.782 MiB)
2026-05-17 02:19:57.720 | slot update_slots: id  2 | task 23275 | erased invalidated context checkpoint (pos_min = 16383, pos_max = 16383, n_tokens = 16384, n_swa = 0, pos_next = 0, size = 183.939 MiB)
2026-05-17 02:19:57.734 | slot update_slots: id  2 | task 23275 | erased invalidated context checkpoint (pos_min = 24575, pos_max = 24575, n_tokens = 24576, n_swa = 0, pos_next = 0, size = 201.095 MiB)
2026-05-17 02:19:57.748 | slot update_slots: id  2 | task 23275 | erased invalidated context checkpoint (pos_min = 32767, pos_max = 32767, n_tokens = 32768, n_swa = 0, pos_next = 0, size = 218.251 MiB)
2026-05-17 02:19:57.762 | slot update_slots: id  2 | task 23275 | erased invalidated context checkpoint (pos_min = 40959, pos_max = 40959, n_tokens = 40960, n_swa = 0, pos_next = 0, size = 235.407 MiB)
2026-05-17 02:19:57.776 | slot update_slots: id  2 | task 23275 | erased invalidated context checkpoint (pos_min = 49151, pos_max = 49151, n_tokens = 49152, n_swa = 0, pos_next = 0, size = 252.564 MiB)
2026-05-17 02:19:57.791 | slot update_slots: id  2 | task 23275 | erased invalidated context checkpoint (pos_min = 57343, pos_max = 57343, n_tokens = 57344, n_swa = 0, pos_next = 0, size = 269.720 MiB)
2026-05-17 02:19:57.808 | slot update_slots: id  2 | task 23275 | erased invalidated context checkpoint (pos_min = 65535, pos_max = 65535, n_tokens = 65536, n_swa = 0, pos_next = 0, size = 286.876 MiB)
2026-05-17 02:19:57.824 | slot update_slots: id  2 | task 23275 | erased invalidated context checkpoint (pos_min = 68367, pos_max = 68367, n_tokens = 68368, n_swa = 0, pos_next = 0, size = 292.807 MiB)
2026-05-17 02:19:57.841 | slot update_slots: id  2 | task 23275 | erased invalidated context checkpoint (pos_min = 68879, pos_max = 68879, n_tokens = 68880, n_swa = 0, pos_next = 0, size = 293.879 MiB)
2026-05-17 02:19:57.858 | slot update_slots: id  2 | task 23275 | erased invalidated context checkpoint (pos_min = 69019, pos_max = 69019, n_tokens = 69020, n_swa = 0, pos_next = 0, size = 294.173 MiB)
2026-05-17 02:19:57.876 | slot update_slots: id  2 | task 23275 | erased invalidated context checkpoint (pos_min = 69122, pos_max = 69122, n_tokens = 69123, n_swa = 0, pos_next = 0, size = 294.388 MiB)
2026-05-17 02:19:57.893 | slot update_slots: id  2 | task 23275 | erased invalidated context checkpoint (pos_min = 69584, pos_max = 69584, n_tokens = 69585, n_swa = 0, pos_next = 0, size = 295.356 MiB)
2026-05-17 02:19:57.910 | slot update_slots: id  2 | task 23275 | erased invalidated context checkpoint (pos_min = 69691, pos_max = 69691, n_tokens = 69692, n_swa = 0, pos_next = 0, size = 295.580 MiB)
2026-05-17 02:19:57.927 | slot update_slots: id  2 | task 23275 | erased invalidated context checkpoint (pos_min = 69782, pos_max = 69782, n_tokens = 69783, n_swa = 0, pos_next = 0, size = 295.771 MiB)
2026-05-17 02:19:57.944 | slot update_slots: id  2 | task 23275 | erased invalidated context checkpoint (pos_min = 70164, pos_max = 70164, n_tokens = 70165, n_swa = 0, pos_next = 0, size = 296.571 MiB)
2026-05-17 02:19:57.962 | slot update_slots: id  2 | task 23275 | erased invalidated context checkpoint (pos_min = 70676, pos_max = 70676, n_tokens = 70677, n_swa = 0, pos_next = 0, size = 297.643 MiB)
2026-05-17 02:19:57.979 | slot update_slots: id  2 | task 23275 | n_tokens = 0, memory_seq_rm [0, end)
2026-05-17 02:19:57.979 | slot update_slots: id  2 | task 23275 | prompt processing progress, n_tokens = 2048, batch.n_tokens = 2048, progress = 0.154298
2026-05-17 02:19:58.686 | slot update_slots: id  2 | task 23275 | n_tokens = 2048, memory_seq_rm [2048, end)
2026-05-17 02:19:58.686 | slot update_slots: id  2 | task 23275 | prompt processing progress, n_tokens = 4096, batch.n_tokens = 2048, progress = 0.308596
2026-05-17 02:19:59.397 | slot update_slots: id  2 | task 23275 | n_tokens = 4096, memory_seq_rm [4096, end)
2026-05-17 02:19:59.397 | slot update_slots: id  2 | task 23275 | prompt processing progress, n_tokens = 6144, batch.n_tokens = 2048, progress = 0.462895
2026-05-17 02:20:00.117 | slot update_slots: id  2 | task 23275 | n_tokens = 6144, memory_seq_rm [6144, end)
2026-05-17 02:20:00.118 | slot update_slots: id  2 | task 23275 | prompt processing progress, n_tokens = 8192, batch.n_tokens = 2048, progress = 0.617193
2026-05-17 02:20:00.849 | slot update_slots: id  2 | task 23275 | n_tokens = 8192, memory_seq_rm [8192, end)
2026-05-17 02:20:00.849 | slot update_slots: id  2 | task 23275 | 8192 tokens since last checkpoint at 0, creating new checkpoint during processing at position 10240
2026-05-17 02:20:00.849 | slot update_slots: id  2 | task 23275 | prompt processing progress, n_tokens = 10240, batch.n_tokens = 2048, progress = 0.771491
2026-05-17 02:20:00.974 | slot create_check: id  2 | task 23275 | created context checkpoint 1 of 32 (pos_min = 8191, pos_max = 8191, n_tokens = 8192, size = 166.782 MiB)
2026-05-17 02:20:01.717 | slot update_slots: id  2 | task 23275 | n_tokens = 10240, memory_seq_rm [10240, end)
2026-05-17 02:20:01.717 | slot update_slots: id  2 | task 23275 | prompt processing progress, n_tokens = 12288, batch.n_tokens = 2048, progress = 0.925789
2026-05-17 02:20:02.473 | slot update_slots: id  2 | task 23275 | n_tokens = 12288, memory_seq_rm [12288, end)
2026-05-17 02:20:02.473 | slot update_slots: id  2 | task 23275 | prompt processing progress, n_tokens = 12757, batch.n_tokens = 469, progress = 0.961124
2026-05-17 02:20:02.659 | slot update_slots: id  2 | task 23275 | n_tokens = 12757, memory_seq_rm [12757, end)
2026-05-17 02:20:02.660 | slot update_slots: id  2 | task 23275 | prompt processing progress, n_tokens = 13269, batch.n_tokens = 512, progress = 0.999699
2026-05-17 02:20:02.786 | slot create_check: id  2 | task 23275 | created context checkpoint 2 of 32 (pos_min = 12756, pos_max = 12756, n_tokens = 12757, size = 176.343 MiB)
2026-05-17 02:20:02.979 | slot update_slots: id  2 | task 23275 | n_tokens = 13269, memory_seq_rm [13269, end)
2026-05-17 02:20:02.980 | slot init_sampler: id  2 | task 23275 | init sampler, took 1.74 ms, tokens: text = 13273, total = 13273
2026-05-17 02:20:02.980 | slot update_slots: id  2 | task 23275 | prompt processing done, n_tokens = 13273, batch.n_tokens = 4
2026-05-17 02:20:03.119 | slot create_check: id  2 | task 23275 | created context checkpoint 3 of 32 (pos_min = 13268, pos_max = 13268, n_tokens = 13269, size = 177.415 MiB)
2026-05-17 02:20:03.154 | srv  log_server_r: done request: POST /v1/chat/completions 172.18.0.1 200
2026-05-17 02:20:05.111 | reasoning-budget: deactivated (natural end)
2026-05-17 02:20:07.366 | slot print_timing: id  2 | task 23275 | 
2026-05-17 02:20:07.366 | prompt eval time =    5446.62 ms / 13273 tokens (    0.41 ms per token,  2436.92 tokens per second)
2026-05-17 02:20:07.366 |        eval time =    4212.24 ms /   319 tokens (   13.20 ms per token,    75.73 tokens per second)
2026-05-17 02:20:07.366 |       total time =    9658.87 ms / 13592 tokens
2026-05-17 02:20:07.366 | draft acceptance rate = 0.98958 (  190 accepted /   192 generated)
2026-05-17 02:20:07.366 | statistics mtp: #calls(b,g,a) = 98 21494 16048, #gen drafts = 16048, #acc drafts = 16048, #gen tokens = 28298, #acc tokens = 27853, dur(b,g,a) = 0.150, 83038.347, 7.898 ms
2026-05-17 02:20:07.366 | slot      release: id  2 | task 23275 | stop processing: n_tokens = 13591, truncated = 0
2026-05-17 02:20:07.366 | srv  update_slots: all slots are idle
2026-05-17 02:20:07.521 | srv  params_from_: Chat format: peg-native
2026-05-17 02:20:07.523 | slot get_availabl: id  2 | task -1 | selected slot by LCP similarity, sim_best = 0.807 (> 0.100 thold), f_keep = 1.000
2026-05-17 02:20:07.525 | reasoning-budget: activated, budget=2147483647 tokens
2026-05-17 02:20:07.525 | slot launch_slot_: id  2 | task -1 | sampler chain: logits -> penalties -> ?dry -> ?top-n-sigma -> top-k -> ?typical -> ?top-p -> min-p -> ?xtc -> ?temp-ext -> dist 
2026-05-17 02:20:07.525 | slot launch_slot_: id  2 | task 23418 | processing task, is_child = 0
2026-05-17 02:20:07.525 | slot update_slots: id  2 | task 23418 | new prompt, n_ctx_slot = 131072, n_keep = 0, task.n_tokens = 16837
2026-05-17 02:20:07.525 | slot update_slots: id  2 | task 23418 | n_tokens = 13591, memory_seq_rm [13591, end)
2026-05-17 02:20:07.525 | slot update_slots: id  2 | task 23418 | prompt processing progress, n_tokens = 15639, batch.n_tokens = 2048, progress = 0.928847
2026-05-17 02:20:08.308 | slot update_slots: id  2 | task 23418 | n_tokens = 15639, memory_seq_rm [15639, end)
2026-05-17 02:20:08.308 | slot update_slots: id  2 | task 23418 | prompt processing progress, n_tokens = 16321, batch.n_tokens = 682, progress = 0.969353
2026-05-17 02:20:08.598 | slot update_slots: id  2 | task 23418 | n_tokens = 16321, memory_seq_rm [16321, end)
2026-05-17 02:20:08.598 | slot update_slots: id  2 | task 23418 | prompt processing progress, n_tokens = 16833, batch.n_tokens = 512, progress = 0.999762
2026-05-17 02:20:08.748 | slot create_check: id  2 | task 23418 | created context checkpoint 4 of 32 (pos_min = 16320, pos_max = 16320, n_tokens = 16321, size = 183.807 MiB)
2026-05-17 02:20:08.946 | slot update_slots: id  2 | task 23418 | n_tokens = 16833, memory_seq_rm [16833, end)
2026-05-17 02:20:08.949 | slot init_sampler: id  2 | task 23418 | init sampler, took 2.27 ms, tokens: text = 16837, total = 16837
2026-05-17 02:20:08.949 | slot update_slots: id  2 | task 23418 | prompt processing done, n_tokens = 16837, batch.n_tokens = 4
2026-05-17 02:20:09.098 | slot create_check: id  2 | task 23418 | created context checkpoint 5 of 32 (pos_min = 16832, pos_max = 16832, n_tokens = 16833, size = 184.879 MiB)
2026-05-17 02:20:09.132 | srv  log_server_r: done request: POST /v1/chat/completions 172.18.0.1 200
2026-05-17 02:20:16.134 | reasoning-budget: deactivated (natural end)
2026-05-17 02:20:19.701 | slot print_timing: id  2 | task 23418 | 
2026-05-17 02:20:19.701 | prompt eval time =    1606.94 ms /  3246 tokens (    0.50 ms per token,  2019.99 tokens per second)
2026-05-17 02:20:19.701 |        eval time =   10568.67 ms /   638 tokens (   16.57 ms per token,    60.37 tokens per second)
2026-05-17 02:20:19.701 |       total time =   12175.60 ms /  3884 tokens
2026-05-17 02:20:19.701 | draft acceptance rate = 0.98580 (  347 accepted /   352 generated)
2026-05-17 02:20:19.701 | statistics mtp: #calls(b,g,a) = 99 21784 16248, #gen drafts = 16248, #acc drafts = 16248, #gen tokens = 28650, #acc tokens = 28200, dur(b,g,a) = 0.151, 84113.429, 8.008 ms
2026-05-17 02:20:19.702 | slot      release: id  2 | task 23418 | stop processing: n_tokens = 17474, truncated = 0
2026-05-17 02:20:19.702 | srv  update_slots: all slots are idle
2026-05-17 02:21:37.667 | srv  params_from_: Chat format: peg-native
2026-05-17 02:21:37.670 | slot get_availabl: id  2 | task -1 | selected slot by LCP similarity, sim_best = 0.598 (> 0.100 thold), f_keep = 0.742
2026-05-17 02:21:37.671 | reasoning-budget: activated, budget=2147483647 tokens
2026-05-17 02:21:37.672 | slot launch_slot_: id  2 | task -1 | sampler chain: logits -> penalties -> ?dry -> ?top-n-sigma -> top-k -> ?typical -> ?top-p -> min-p -> ?xtc -> ?temp-ext -> dist 
2026-05-17 02:21:37.672 | slot launch_slot_: id  2 | task 23736 | processing task, is_child = 0
2026-05-17 02:21:37.672 | slot update_slots: id  2 | task 23736 | new prompt, n_ctx_slot = 131072, n_keep = 0, task.n_tokens = 21656
2026-05-17 02:21:37.672 | slot update_slots: id  2 | task 23736 | n_past = 12958, slot.prompt.tokens.size() = 17474, seq_id = 2, pos_min = 17473, n_swa = 0
2026-05-17 02:21:37.672 | slot update_slots: id  2 | task 23736 | Checking checkpoint with [16832, 16832] against 12958...
2026-05-17 02:21:37.672 | slot update_slots: id  2 | task 23736 | Checking checkpoint with [16320, 16320] against 12958...
2026-05-17 02:21:37.672 | slot update_slots: id  2 | task 23736 | Checking checkpoint with [13268, 13268] against 12958...
2026-05-17 02:21:37.672 | slot update_slots: id  2 | task 23736 | Checking checkpoint with [12756, 12756] against 12958...
2026-05-17 02:21:37.739 | slot update_slots: id  2 | task 23736 | restored context checkpoint (pos_min = 12756, pos_max = 12756, n_tokens = 12757, n_past = 12757, size = 176.343 MiB)
2026-05-17 02:21:37.739 | slot update_slots: id  2 | task 23736 | erased invalidated context checkpoint (pos_min = 13268, pos_max = 13268, n_tokens = 13269, n_swa = 0, pos_next = 12757, size = 177.415 MiB)
2026-05-17 02:21:37.750 | slot update_slots: id  2 | task 23736 | erased invalidated context checkpoint (pos_min = 16320, pos_max = 16320, n_tokens = 16321, n_swa = 0, pos_next = 12757, size = 183.807 MiB)
2026-05-17 02:21:37.761 | slot update_slots: id  2 | task 23736 | erased invalidated context checkpoint (pos_min = 16832, pos_max = 16832, n_tokens = 16833, n_swa = 0, pos_next = 12757, size = 184.879 MiB)
2026-05-17 02:21:37.773 | slot update_slots: id  2 | task 23736 | n_tokens = 12757, memory_seq_rm [12757, end)
2026-05-17 02:21:37.774 | slot update_slots: id  2 | task 23736 | prompt processing progress, n_tokens = 14805, batch.n_tokens = 2048, progress = 0.683644
2026-05-17 02:21:38.771 | slot update_slots: id  2 | task 23736 | n_tokens = 14805, memory_seq_rm [14805, end)
2026-05-17 02:21:38.771 | slot update_slots: id  2 | task 23736 | prompt processing progress, n_tokens = 16853, batch.n_tokens = 2048, progress = 0.778214
2026-05-17 02:21:39.554 | slot update_slots: id  2 | task 23736 | n_tokens = 16853, memory_seq_rm [16853, end)
2026-05-17 02:21:39.554 | slot update_slots: id  2 | task 23736 | prompt processing progress, n_tokens = 18901, batch.n_tokens = 2048, progress = 0.872784
2026-05-17 02:21:40.350 | slot update_slots: id  2 | task 23736 | n_tokens = 18901, memory_seq_rm [18901, end)
2026-05-17 02:21:40.350 | slot update_slots: id  2 | task 23736 | prompt processing progress, n_tokens = 20949, batch.n_tokens = 2048, progress = 0.967353
2026-05-17 02:21:41.161 | slot update_slots: id  2 | task 23736 | n_tokens = 20949, memory_seq_rm [20949, end)
2026-05-17 02:21:41.161 | slot update_slots: id  2 | task 23736 | 8192 tokens since last checkpoint at 12757, creating new checkpoint during processing at position 21140
2026-05-17 02:21:41.161 | slot update_slots: id  2 | task 23736 | prompt processing progress, n_tokens = 21140, batch.n_tokens = 191, progress = 0.976173
2026-05-17 02:21:41.307 | slot create_check: id  2 | task 23736 | created context checkpoint 3 of 32 (pos_min = 20948, pos_max = 20948, n_tokens = 20949, size = 193.499 MiB)
2026-05-17 02:21:41.401 | slot update_slots: id  2 | task 23736 | n_tokens = 21140, memory_seq_rm [21140, end)
2026-05-17 02:21:41.401 | slot update_slots: id  2 | task 23736 | prompt processing progress, n_tokens = 21652, batch.n_tokens = 512, progress = 0.999815
2026-05-17 02:21:41.544 | slot create_check: id  2 | task 23736 | created context checkpoint 4 of 32 (pos_min = 21139, pos_max = 21139, n_tokens = 21140, size = 193.899 MiB)
2026-05-17 02:21:41.747 | slot update_slots: id  2 | task 23736 | n_tokens = 21652, memory_seq_rm [21652, end)
2026-05-17 02:21:41.750 | slot init_sampler: id  2 | task 23736 | init sampler, took 2.81 ms, tokens: text = 21656, total = 21656
2026-05-17 02:21:41.750 | slot update_slots: id  2 | task 23736 | prompt processing done, n_tokens = 21656, batch.n_tokens = 4
2026-05-17 02:21:41.893 | slot create_check: id  2 | task 23736 | created context checkpoint 5 of 32 (pos_min = 21651, pos_max = 21651, n_tokens = 21652, size = 194.971 MiB)
2026-05-17 02:21:41.928 | srv  log_server_r: done request: POST /v1/chat/completions 172.18.0.1 200
2026-05-17 02:21:50.093 | reasoning-budget: deactivated (natural end)
2026-05-17 02:21:56.973 | slot print_timing: id  2 | task 23736 | 
2026-05-17 02:21:56.973 | prompt eval time =    4255.27 ms /  8899 tokens (    0.48 ms per token,  2091.29 tokens per second)
2026-05-17 02:21:56.973 |        eval time =   15135.98 ms /   863 tokens (   17.54 ms per token,    57.02 tokens per second)
2026-05-17 02:21:56.973 |       total time =   19391.25 ms /  9762 tokens
2026-05-17 02:21:56.973 | draft acceptance rate = 0.97634 (  454 accepted /   465 generated)
2026-05-17 02:21:56.973 | statistics mtp: #calls(b,g,a) = 100 22192 16525, #gen drafts = 16525, #acc drafts = 16525, #gen tokens = 29115, #acc tokens = 28654, dur(b,g,a) = 0.152, 85540.602, 8.142 ms
2026-05-17 02:21:56.974 | slot      release: id  2 | task 23736 | stop processing: n_tokens = 22518, truncated = 0
2026-05-17 02:21:56.974 | srv  update_slots: all slots are idle
2026-05-17 02:25:32.166 | srv  params_from_: Chat format: peg-native
2026-05-17 02:25:32.169 | slot get_availabl: id  2 | task -1 | selected slot by LCP similarity, sim_best = 0.945 (> 0.100 thold), f_keep = 0.948
2026-05-17 02:25:32.170 | reasoning-budget: activated, budget=2147483647 tokens
2026-05-17 02:25:32.171 | slot launch_slot_: id  2 | task -1 | sampler chain: logits -> penalties -> ?dry -> ?top-n-sigma -> top-k -> ?typical -> ?top-p -> min-p -> ?xtc -> ?temp-ext -> dist 
2026-05-17 02:25:32.171 | slot launch_slot_: id  2 | task 24192 | processing task, is_child = 0
2026-05-17 02:25:32.171 | slot update_slots: id  2 | task 24192 | new prompt, n_ctx_slot = 131072, n_keep = 0, task.n_tokens = 22594
2026-05-17 02:25:32.171 | slot update_slots: id  2 | task 24192 | n_past = 21341, slot.prompt.tokens.size() = 22518, seq_id = 2, pos_min = 22517, n_swa = 0
2026-05-17 02:25:32.171 | slot update_slots: id  2 | task 24192 | Checking checkpoint with [21651, 21651] against 21341...
2026-05-17 02:25:32.171 | slot update_slots: id  2 | task 24192 | Checking checkpoint with [21139, 21139] against 21341...
2026-05-17 02:25:32.245 | slot update_slots: id  2 | task 24192 | restored context checkpoint (pos_min = 21139, pos_max = 21139, n_tokens = 21140, n_past = 21140, size = 193.899 MiB)
2026-05-17 02:25:32.245 | slot update_slots: id  2 | task 24192 | erased invalidated context checkpoint (pos_min = 21651, pos_max = 21651, n_tokens = 21652, n_swa = 0, pos_next = 21140, size = 194.971 MiB)
2026-05-17 02:25:32.257 | slot update_slots: id  2 | task 24192 | n_tokens = 21140, memory_seq_rm [21140, end)
2026-05-17 02:25:32.258 | slot update_slots: id  2 | task 24192 | prompt processing progress, n_tokens = 22078, batch.n_tokens = 938, progress = 0.977162
2026-05-17 02:25:32.793 | slot update_slots: id  2 | task 24192 | n_tokens = 22078, memory_seq_rm [22078, end)
2026-05-17 02:25:32.793 | slot update_slots: id  2 | task 24192 | prompt processing progress, n_tokens = 22590, batch.n_tokens = 512, progress = 0.999823
2026-05-17 02:25:32.939 | slot create_check: id  2 | task 24192 | created context checkpoint 5 of 32 (pos_min = 22077, pos_max = 22077, n_tokens = 22078, size = 195.863 MiB)
2026-05-17 02:25:33.146 | slot update_slots: id  2 | task 24192 | n_tokens = 22590, memory_seq_rm [22590, end)
2026-05-17 02:25:33.149 | slot init_sampler: id  2 | task 24192 | init sampler, took 2.98 ms, tokens: text = 22594, total = 22594
2026-05-17 02:25:33.149 | slot update_slots: id  2 | task 24192 | prompt processing done, n_tokens = 22594, batch.n_tokens = 4
2026-05-17 02:25:33.323 | slot create_check: id  2 | task 24192 | created context checkpoint 6 of 32 (pos_min = 22589, pos_max = 22589, n_tokens = 22590, size = 196.936 MiB)
2026-05-17 02:25:33.357 | srv  log_server_r: done request: POST /v1/chat/completions 172.18.0.1 200
2026-05-17 02:25:38.967 | reasoning-budget: deactivated (natural end)
2026-05-17 02:25:40.744 | slot print_timing: id  2 | task 24192 | 
2026-05-17 02:25:40.744 | prompt eval time =    1186.30 ms /  1454 tokens (    0.82 ms per token,  1225.66 tokens per second)
2026-05-17 02:25:40.744 |        eval time =    7386.88 ms /   441 tokens (   16.75 ms per token,    59.70 tokens per second)
2026-05-17 02:25:40.744 |       total time =    8573.19 ms /  1895 tokens
2026-05-17 02:25:40.744 | draft acceptance rate = 0.99119 (  225 accepted /   227 generated)
2026-05-17 02:25:40.744 | statistics mtp: #calls(b,g,a) = 101 22407 16661, #gen drafts = 16661, #acc drafts = 16661, #gen tokens = 29342, #acc tokens = 28879, dur(b,g,a) = 0.154, 86261.424, 8.202 ms
2026-05-17 02:25:40.745 | slot      release: id  2 | task 24192 | stop processing: n_tokens = 23034, truncated = 0
2026-05-17 02:25:40.745 | srv  update_slots: all slots are idle
2026-05-17 02:25:40.937 | srv  params_from_: Chat format: peg-native
2026-05-17 02:25:40.939 | slot get_availabl: id  2 | task -1 | selected slot by LCP similarity, sim_best = 0.990 (> 0.100 thold), f_keep = 1.000
2026-05-17 02:25:40.941 | reasoning-budget: activated, budget=2147483647 tokens
2026-05-17 02:25:40.941 | slot launch_slot_: id  2 | task -1 | sampler chain: logits -> penalties -> ?dry -> ?top-n-sigma -> top-k -> ?typical -> ?top-p -> min-p -> ?xtc -> ?temp-ext -> dist 
2026-05-17 02:25:40.941 | slot launch_slot_: id  2 | task 24425 | processing task, is_child = 0
2026-05-17 02:25:40.941 | slot update_slots: id  2 | task 24425 | new prompt, n_ctx_slot = 131072, n_keep = 0, task.n_tokens = 23271
2026-05-17 02:25:40.941 | slot update_slots: id  2 | task 24425 | n_tokens = 23034, memory_seq_rm [23034, end)
2026-05-17 02:25:40.941 | slot update_slots: id  2 | task 24425 | prompt processing progress, n_tokens = 23267, batch.n_tokens = 233, progress = 0.999828
2026-05-17 02:25:41.159 | slot create_check: id  2 | task 24425 | created context checkpoint 7 of 32 (pos_min = 23033, pos_max = 23033, n_tokens = 23034, size = 197.866 MiB)
2026-05-17 02:25:41.270 | slot update_slots: id  2 | task 24425 | n_tokens = 23267, memory_seq_rm [23267, end)
2026-05-17 02:25:41.274 | slot init_sampler: id  2 | task 24425 | init sampler, took 3.06 ms, tokens: text = 23271, total = 23271
2026-05-17 02:25:41.274 | slot update_slots: id  2 | task 24425 | prompt processing done, n_tokens = 23271, batch.n_tokens = 4
2026-05-17 02:25:41.493 | slot create_check: id  2 | task 24425 | created context checkpoint 8 of 32 (pos_min = 23266, pos_max = 23266, n_tokens = 23267, size = 198.354 MiB)
2026-05-17 02:25:41.528 | srv  log_server_r: done request: POST /v1/chat/completions 172.18.0.1 200
2026-05-17 02:25:41.837 | reasoning-budget: deactivated (natural end)
2026-05-17 02:25:42.908 | slot print_timing: id  2 | task 24425 | 
2026-05-17 02:25:42.908 | prompt eval time =     586.42 ms /   237 tokens (    2.47 ms per token,   404.15 tokens per second)
2026-05-17 02:25:42.908 |        eval time =    1380.16 ms /    92 tokens (   15.00 ms per token,    66.66 tokens per second)
2026-05-17 02:25:42.908 |       total time =    1966.58 ms /   329 tokens
2026-05-17 02:25:42.908 | draft acceptance rate = 0.98214 (   55 accepted /    56 generated)
2026-05-17 02:25:42.908 | statistics mtp: #calls(b,g,a) = 102 22443 16694, #gen drafts = 16694, #acc drafts = 16694, #gen tokens = 29398, #acc tokens = 28934, dur(b,g,a) = 0.155, 86404.669, 8.215 ms
2026-05-17 02:25:42.909 | slot      release: id  2 | task 24425 | stop processing: n_tokens = 23362, truncated = 0
2026-05-17 02:25:42.909 | srv  update_slots: all slots are idle
2026-05-17 02:25:43.064 | srv  params_from_: Chat format: peg-native
2026-05-17 02:25:43.066 | slot get_availabl: id  2 | task -1 | selected slot by LCP similarity, sim_best = 0.999 (> 0.100 thold), f_keep = 1.000
2026-05-17 02:25:43.068 | reasoning-budget: activated, budget=2147483647 tokens
2026-05-17 02:25:43.068 | slot launch_slot_: id  2 | task -1 | sampler chain: logits -> penalties -> ?dry -> ?top-n-sigma -> top-k -> ?typical -> ?top-p -> min-p -> ?xtc -> ?temp-ext -> dist 
2026-05-17 02:25:43.068 | slot launch_slot_: id  2 | task 24467 | processing task, is_child = 0
2026-05-17 02:25:43.068 | slot update_slots: id  2 | task 24467 | new prompt, n_ctx_slot = 131072, n_keep = 0, task.n_tokens = 23379
2026-05-17 02:25:43.068 | slot update_slots: id  2 | task 24467 | n_tokens = 23362, memory_seq_rm [23362, end)
2026-05-17 02:25:43.068 | slot update_slots: id  2 | task 24467 | prompt processing progress, n_tokens = 23375, batch.n_tokens = 13, progress = 0.999829
2026-05-17 02:25:43.287 | slot create_check: id  2 | task 24467 | created context checkpoint 9 of 32 (pos_min = 23361, pos_max = 23361, n_tokens = 23362, size = 198.552 MiB)
2026-05-17 02:25:43.324 | slot update_slots: id  2 | task 24467 | n_tokens = 23375, memory_seq_rm [23375, end)
2026-05-17 02:25:43.327 | slot init_sampler: id  2 | task 24467 | init sampler, took 3.02 ms, tokens: text = 23379, total = 23379
2026-05-17 02:25:43.327 | slot update_slots: id  2 | task 24467 | prompt processing done, n_tokens = 23379, batch.n_tokens = 4
2026-05-17 02:25:43.361 | srv  log_server_r: done request: POST /v1/chat/completions 172.18.0.1 200
2026-05-17 02:25:43.959 | reasoning-budget: deactivated (natural end)
2026-05-17 02:25:44.605 | slot print_timing: id  2 | task 24467 | 
2026-05-17 02:25:44.605 | prompt eval time =     292.69 ms /    17 tokens (   17.22 ms per token,    58.08 tokens per second)
2026-05-17 02:25:44.605 |        eval time =    1244.10 ms /    97 tokens (   12.83 ms per token,    77.97 tokens per second)
2026-05-17 02:25:44.605 |       total time =    1536.79 ms /   114 tokens
2026-05-17 02:25:44.605 | draft acceptance rate = 1.00000 (   57 accepted /    57 generated)
2026-05-17 02:25:44.605 | statistics mtp: #calls(b,g,a) = 103 22482 16724, #gen drafts = 16724, #acc drafts = 16724, #gen tokens = 29455, #acc tokens = 28991, dur(b,g,a) = 0.156, 86545.805, 8.233 ms
2026-05-17 02:25:44.605 | slot      release: id  2 | task 24467 | stop processing: n_tokens = 23475, truncated = 0
2026-05-17 02:25:44.605 | srv  update_slots: all slots are idle
2026-05-17 02:25:44.789 | srv  params_from_: Chat format: peg-native
2026-05-17 02:25:44.792 | slot get_availabl: id  2 | task -1 | selected slot by LCP similarity, sim_best = 0.976 (> 0.100 thold), f_keep = 1.000
2026-05-17 02:25:44.793 | reasoning-budget: activated, budget=2147483647 tokens
2026-05-17 02:25:44.793 | slot launch_slot_: id  2 | task -1 | sampler chain: logits -> penalties -> ?dry -> ?top-n-sigma -> top-k -> ?typical -> ?top-p -> min-p -> ?xtc -> ?temp-ext -> dist 
2026-05-17 02:25:44.793 | slot launch_slot_: id  2 | task 24510 | processing task, is_child = 0
2026-05-17 02:25:44.793 | slot update_slots: id  2 | task 24510 | new prompt, n_ctx_slot = 131072, n_keep = 0, task.n_tokens = 24045
2026-05-17 02:25:44.793 | slot update_slots: id  2 | task 24510 | n_tokens = 23475, memory_seq_rm [23475, end)
2026-05-17 02:25:44.793 | slot update_slots: id  2 | task 24510 | prompt processing progress, n_tokens = 23529, batch.n_tokens = 54, progress = 0.978540
2026-05-17 02:25:44.840 | slot update_slots: id  2 | task 24510 | n_tokens = 23529, memory_seq_rm [23529, end)
2026-05-17 02:25:44.840 | slot update_slots: id  2 | task 24510 | prompt processing progress, n_tokens = 24041, batch.n_tokens = 512, progress = 0.999834
2026-05-17 02:25:45.060 | slot create_check: id  2 | task 24510 | created context checkpoint 10 of 32 (pos_min = 23528, pos_max = 23528, n_tokens = 23529, size = 198.902 MiB)
2026-05-17 02:25:45.268 | slot update_slots: id  2 | task 24510 | n_tokens = 24041, memory_seq_rm [24041, end)
2026-05-17 02:25:45.271 | slot init_sampler: id  2 | task 24510 | init sampler, took 3.16 ms, tokens: text = 24045, total = 24045
2026-05-17 02:25:45.271 | slot update_slots: id  2 | task 24510 | prompt processing done, n_tokens = 24045, batch.n_tokens = 4
2026-05-17 02:25:45.493 | slot create_check: id  2 | task 24510 | created context checkpoint 11 of 32 (pos_min = 24040, pos_max = 24040, n_tokens = 24041, size = 199.974 MiB)
2026-05-17 02:25:45.527 | srv  log_server_r: done request: POST /v1/chat/completions 172.18.0.1 200
2026-05-17 02:25:53.494 | reasoning-budget: deactivated (natural end)
2026-05-17 02:25:58.964 | slot print_timing: id  2 | task 24510 | 
2026-05-17 02:25:58.968 | prompt eval time =     733.90 ms /   570 tokens (    1.29 ms per token,   776.68 tokens per second)
2026-05-17 02:25:58.968 |        eval time =   13537.22 ms /   759 tokens (   17.84 ms per token,    56.07 tokens per second)
2026-05-17 02:25:58.968 |       total time =   14271.11 ms /  1329 tokens
2026-05-17 02:25:58.968 | draft acceptance rate = 0.98438 (  378 accepted /   384 generated)
2026-05-17 02:25:58.968 | statistics mtp: #calls(b,g,a) = 104 22862 16958, #gen drafts = 16958, #acc drafts = 16958, #gen tokens = 29839, #acc tokens = 29369, dur(b,g,a) = 0.157, 87830.882, 8.349 ms
2026-05-17 02:25:58.968 | slot      release: id  2 | task 24510 | stop processing: n_tokens = 24803, truncated = 0
2026-05-17 02:25:58.968 | srv  update_slots: all slots are idle
2026-05-17 02:30:04.268 | srv  params_from_: Chat format: peg-native
2026-05-17 02:30:04.271 | slot get_availabl: id  2 | task -1 | selected slot by LCP similarity, sim_best = 0.919 (> 0.100 thold), f_keep = 0.898
2026-05-17 02:30:04.273 | reasoning-budget: activated, budget=2147483647 tokens
2026-05-17 02:30:04.273 | slot launch_slot_: id  2 | task -1 | sampler chain: logits -> penalties -> ?dry -> ?top-n-sigma -> top-k -> ?typical -> ?top-p -> min-p -> ?xtc -> ?temp-ext -> dist 
2026-05-17 02:30:04.273 | slot launch_slot_: id  2 | task 24921 | processing task, is_child = 0
2026-05-17 02:30:04.273 | slot update_slots: id  2 | task 24921 | new prompt, n_ctx_slot = 131072, n_keep = 0, task.n_tokens = 24233
2026-05-17 02:30:04.273 | slot update_slots: id  2 | task 24921 | n_past = 22279, slot.prompt.tokens.size() = 24803, seq_id = 2, pos_min = 24802, n_swa = 0
2026-05-17 02:30:04.273 | slot update_slots: id  2 | task 24921 | Checking checkpoint with [24040, 24040] against 22279...
2026-05-17 02:30:04.273 | slot update_slots: id  2 | task 24921 | Checking checkpoint with [23528, 23528] against 22279...
2026-05-17 02:30:04.273 | slot update_slots: id  2 | task 24921 | Checking checkpoint with [23361, 23361] against 22279...
2026-05-17 02:30:04.273 | slot update_slots: id  2 | task 24921 | Checking checkpoint with [23266, 23266] against 22279...
2026-05-17 02:30:04.273 | slot update_slots: id  2 | task 24921 | Checking checkpoint with [23033, 23033] against 22279...
2026-05-17 02:30:04.273 | slot update_slots: id  2 | task 24921 | Checking checkpoint with [22589, 22589] against 22279...
2026-05-17 02:30:04.273 | slot update_slots: id  2 | task 24921 | Checking checkpoint with [22077, 22077] against 22279...
2026-05-17 02:30:04.351 | slot update_slots: id  2 | task 24921 | restored context checkpoint (pos_min = 22077, pos_max = 22077, n_tokens = 22078, n_past = 22078, size = 195.863 MiB)
2026-05-17 02:30:04.351 | slot update_slots: id  2 | task 24921 | erased invalidated context checkpoint (pos_min = 22589, pos_max = 22589, n_tokens = 22590, n_swa = 0, pos_next = 22078, size = 196.936 MiB)
2026-05-17 02:30:04.363 | slot update_slots: id  2 | task 24921 | erased invalidated context checkpoint (pos_min = 23033, pos_max = 23033, n_tokens = 23034, n_swa = 0, pos_next = 22078, size = 197.866 MiB)
2026-05-17 02:30:04.374 | slot update_slots: id  2 | task 24921 | erased invalidated context checkpoint (pos_min = 23266, pos_max = 23266, n_tokens = 23267, n_swa = 0, pos_next = 22078, size = 198.354 MiB)
2026-05-17 02:30:04.385 | slot update_slots: id  2 | task 24921 | erased invalidated context checkpoint (pos_min = 23361, pos_max = 23361, n_tokens = 23362, n_swa = 0, pos_next = 22078, size = 198.552 MiB)
2026-05-17 02:30:04.396 | slot update_slots: id  2 | task 24921 | erased invalidated context checkpoint (pos_min = 23528, pos_max = 23528, n_tokens = 23529, n_swa = 0, pos_next = 22078, size = 198.902 MiB)
2026-05-17 02:30:04.407 | slot update_slots: id  2 | task 24921 | erased invalidated context checkpoint (pos_min = 24040, pos_max = 24040, n_tokens = 24041, n_swa = 0, pos_next = 22078, size = 199.974 MiB)
2026-05-17 02:30:04.419 | slot update_slots: id  2 | task 24921 | n_tokens = 22078, memory_seq_rm [22078, end)
2026-05-17 02:30:04.419 | slot update_slots: id  2 | task 24921 | prompt processing progress, n_tokens = 23717, batch.n_tokens = 1639, progress = 0.978707
2026-05-17 02:30:05.299 | slot update_slots: id  2 | task 24921 | n_tokens = 23717, memory_seq_rm [23717, end)
2026-05-17 02:30:05.299 | slot update_slots: id  2 | task 24921 | prompt processing progress, n_tokens = 24229, batch.n_tokens = 512, progress = 0.999835
2026-05-17 02:30:05.449 | slot create_check: id  2 | task 24921 | created context checkpoint 6 of 32 (pos_min = 23716, pos_max = 23716, n_tokens = 23717, size = 199.296 MiB)
2026-05-17 02:30:05.659 | slot update_slots: id  2 | task 24921 | n_tokens = 24229, memory_seq_rm [24229, end)
2026-05-17 02:30:05.662 | slot init_sampler: id  2 | task 24921 | init sampler, took 3.19 ms, tokens: text = 24233, total = 24233
2026-05-17 02:30:05.662 | slot update_slots: id  2 | task 24921 | prompt processing done, n_tokens = 24233, batch.n_tokens = 4
2026-05-17 02:30:05.863 | slot create_check: id  2 | task 24921 | created context checkpoint 7 of 32 (pos_min = 24228, pos_max = 24228, n_tokens = 24229, size = 200.368 MiB)
2026-05-17 02:30:05.899 | srv  log_server_r: done request: POST /v1/chat/completions 172.18.0.1 200
2026-05-17 02:30:07.572 | reasoning-budget: deactivated (natural end)
2026-05-17 02:30:09.226 | slot print_timing: id  2 | task 24921 | 
2026-05-17 02:30:09.226 | prompt eval time =    1625.28 ms /  2155 tokens (    0.75 ms per token,  1325.92 tokens per second)
2026-05-17 02:30:09.226 |        eval time =    3327.54 ms /   260 tokens (   12.80 ms per token,    78.14 tokens per second)
2026-05-17 02:30:09.226 |       total time =    4952.82 ms /  2415 tokens
2026-05-17 02:30:09.226 | draft acceptance rate = 0.99367 (  157 accepted /   158 generated)
2026-05-17 02:30:09.226 | statistics mtp: #calls(b,g,a) = 105 22964 17042, #gen drafts = 17042, #acc drafts = 17042, #gen tokens = 29997, #acc tokens = 29526, dur(b,g,a) = 0.159, 88223.762, 8.392 ms
2026-05-17 02:30:09.227 | slot      release: id  2 | task 24921 | stop processing: n_tokens = 24492, truncated = 0
2026-05-17 02:30:09.227 | srv  update_slots: all slots are idle
2026-05-17 02:30:09.400 | srv  params_from_: Chat format: peg-native
2026-05-17 02:30:09.403 | slot get_availabl: id  2 | task -1 | selected slot by LCP similarity, sim_best = 0.996 (> 0.100 thold), f_keep = 1.000
2026-05-17 02:30:09.404 | reasoning-budget: activated, budget=2147483647 tokens
2026-05-17 02:30:09.404 | slot launch_slot_: id  2 | task -1 | sampler chain: logits -> penalties -> ?dry -> ?top-n-sigma -> top-k -> ?typical -> ?top-p -> min-p -> ?xtc -> ?temp-ext -> dist 
2026-05-17 02:30:09.404 | slot launch_slot_: id  2 | task 25028 | processing task, is_child = 0
2026-05-17 02:30:09.404 | slot update_slots: id  2 | task 25028 | new prompt, n_ctx_slot = 131072, n_keep = 0, task.n_tokens = 24594
2026-05-17 02:30:09.404 | slot update_slots: id  2 | task 25028 | n_tokens = 24492, memory_seq_rm [24492, end)
2026-05-17 02:30:09.405 | slot update_slots: id  2 | task 25028 | prompt processing progress, n_tokens = 24590, batch.n_tokens = 98, progress = 0.999837
2026-05-17 02:30:09.553 | slot create_check: id  2 | task 25028 | created context checkpoint 8 of 32 (pos_min = 24491, pos_max = 24491, n_tokens = 24492, size = 200.919 MiB)
2026-05-17 02:30:09.617 | slot update_slots: id  2 | task 25028 | n_tokens = 24590, memory_seq_rm [24590, end)
2026-05-17 02:30:09.621 | slot init_sampler: id  2 | task 25028 | init sampler, took 3.29 ms, tokens: text = 24594, total = 24594
2026-05-17 02:30:09.621 | slot update_slots: id  2 | task 25028 | prompt processing done, n_tokens = 24594, batch.n_tokens = 4
2026-05-17 02:30:09.780 | slot create_check: id  2 | task 25028 | created context checkpoint 9 of 32 (pos_min = 24589, pos_max = 24589, n_tokens = 24590, size = 201.124 MiB)
2026-05-17 02:30:09.814 | srv  log_server_r: done request: POST /v1/chat/completions 172.18.0.1 200
2026-05-17 02:30:10.244 | reasoning-budget: deactivated (natural end)
2026-05-17 02:30:12.026 | slot print_timing: id  2 | task 25028 | 
2026-05-17 02:30:12.026 | prompt eval time =     409.50 ms /   102 tokens (    4.01 ms per token,   249.08 tokens per second)
2026-05-17 02:30:12.026 |        eval time =    2212.20 ms /   126 tokens (   17.56 ms per token,    56.96 tokens per second)
2026-05-17 02:30:12.026 |       total time =    2621.70 ms /   228 tokens
2026-05-17 02:30:12.026 | draft acceptance rate = 0.97059 (   66 accepted /    68 generated)
2026-05-17 02:30:12.026 | statistics mtp: #calls(b,g,a) = 106 23023 17083, #gen drafts = 17083, #acc drafts = 17083, #gen tokens = 30065, #acc tokens = 29592, dur(b,g,a) = 0.161, 88436.678, 8.405 ms
2026-05-17 02:30:12.027 | slot      release: id  2 | task 25028 | stop processing: n_tokens = 24719, truncated = 0
2026-05-17 02:30:12.027 | srv  update_slots: all slots are idle
2026-05-17 02:30:23.388 | srv  params_from_: Chat format: peg-native
2026-05-17 02:30:23.390 | slot get_availabl: id  2 | task -1 | selected slot by LCP similarity, sim_best = 0.982 (> 0.100 thold), f_keep = 0.968
2026-05-17 02:30:23.391 | reasoning-budget: activated, budget=2147483647 tokens
2026-05-17 02:30:23.391 | slot launch_slot_: id  2 | task -1 | sampler chain: logits -> penalties -> ?dry -> ?top-n-sigma -> top-k -> ?typical -> ?top-p -> min-p -> ?xtc -> ?temp-ext -> dist 
2026-05-17 02:30:23.391 | slot launch_slot_: id  2 | task 25096 | processing task, is_child = 0
2026-05-17 02:30:23.391 | slot update_slots: id  2 | task 25096 | new prompt, n_ctx_slot = 131072, n_keep = 0, task.n_tokens = 24348
2026-05-17 02:30:23.392 | slot update_slots: id  2 | task 25096 | n_past = 23918, slot.prompt.tokens.size() = 24719, seq_id = 2, pos_min = 24718, n_swa = 0
2026-05-17 02:30:23.392 | slot update_slots: id  2 | task 25096 | Checking checkpoint with [24589, 24589] against 23918...
2026-05-17 02:30:23.392 | slot update_slots: id  2 | task 25096 | Checking checkpoint with [24491, 24491] against 23918...
2026-05-17 02:30:23.392 | slot update_slots: id  2 | task 25096 | Checking checkpoint with [24228, 24228] against 23918...
2026-05-17 02:30:23.392 | slot update_slots: id  2 | task 25096 | Checking checkpoint with [23716, 23716] against 23918...
2026-05-17 02:30:23.465 | slot update_slots: id  2 | task 25096 | restored context checkpoint (pos_min = 23716, pos_max = 23716, n_tokens = 23717, n_past = 23717, size = 199.296 MiB)
2026-05-17 02:30:23.465 | slot update_slots: id  2 | task 25096 | erased invalidated context checkpoint (pos_min = 24228, pos_max = 24228, n_tokens = 24229, n_swa = 0, pos_next = 23717, size = 200.368 MiB)
2026-05-17 02:30:23.476 | slot update_slots: id  2 | task 25096 | erased invalidated context checkpoint (pos_min = 24491, pos_max = 24491, n_tokens = 24492, n_swa = 0, pos_next = 23717, size = 200.919 MiB)
2026-05-17 02:30:23.487 | slot update_slots: id  2 | task 25096 | erased invalidated context checkpoint (pos_min = 24589, pos_max = 24589, n_tokens = 24590, n_swa = 0, pos_next = 23717, size = 201.124 MiB)
2026-05-17 02:30:23.498 | slot update_slots: id  2 | task 25096 | n_tokens = 23717, memory_seq_rm [23717, end)
2026-05-17 02:30:23.499 | slot update_slots: id  2 | task 25096 | prompt processing progress, n_tokens = 23832, batch.n_tokens = 115, progress = 0.978807
2026-05-17 02:30:23.685 | slot update_slots: id  2 | task 25096 | n_tokens = 23832, memory_seq_rm [23832, end)
2026-05-17 02:30:23.685 | slot update_slots: id  2 | task 25096 | prompt processing progress, n_tokens = 24344, batch.n_tokens = 512, progress = 0.999836
2026-05-17 02:30:23.826 | slot create_check: id  2 | task 25096 | created context checkpoint 7 of 32 (pos_min = 23831, pos_max = 23831, n_tokens = 23832, size = 199.537 MiB)
2026-05-17 02:30:24.035 | slot update_slots: id  2 | task 25096 | n_tokens = 24344, memory_seq_rm [24344, end)
2026-05-17 02:30:24.038 | slot init_sampler: id  2 | task 25096 | init sampler, took 3.06 ms, tokens: text = 24348, total = 24348
2026-05-17 02:30:24.038 | slot update_slots: id  2 | task 25096 | prompt processing done, n_tokens = 24348, batch.n_tokens = 4
2026-05-17 02:30:24.181 | slot create_check: id  2 | task 25096 | created context checkpoint 8 of 32 (pos_min = 24343, pos_max = 24343, n_tokens = 24344, size = 200.609 MiB)
2026-05-17 02:30:24.218 | srv  log_server_r: done request: POST /v1/chat/completions 172.18.0.1 200
2026-05-17 02:30:24.784 | reasoning-budget: deactivated (natural end)
2026-05-17 02:30:26.877 | slot print_timing: id  2 | task 25096 | 
2026-05-17 02:30:26.877 | prompt eval time =     825.54 ms /   631 tokens (    1.31 ms per token,   764.35 tokens per second)
2026-05-17 02:30:26.877 |        eval time =    2659.78 ms /   233 tokens (   11.42 ms per token,    87.60 tokens per second)
2026-05-17 02:30:26.877 |       total time =    3485.32 ms /   864 tokens
2026-05-17 02:30:26.877 | draft acceptance rate = 1.00000 (  152 accepted /   152 generated)
2026-05-17 02:30:26.877 | statistics mtp: #calls(b,g,a) = 107 23103 17162, #gen drafts = 17162, #acc drafts = 17162, #gen tokens = 30217, #acc tokens = 29744, dur(b,g,a) = 0.162, 88779.902, 8.484 ms
2026-05-17 02:30:26.878 | slot      release: id  2 | task 25096 | stop processing: n_tokens = 24580, truncated = 0
2026-05-17 02:30:26.878 | srv  update_slots: all slots are idle
2026-05-17 02:30:27.091 | srv  params_from_: Chat format: peg-native
2026-05-17 02:30:27.094 | slot get_availabl: id  2 | task -1 | selected slot by LCP similarity, sim_best = 0.999 (> 0.100 thold), f_keep = 1.000
2026-05-17 02:30:27.095 | reasoning-budget: activated, budget=2147483647 tokens
2026-05-17 02:30:27.095 | slot launch_slot_: id  2 | task -1 | sampler chain: logits -> penalties -> ?dry -> ?top-n-sigma -> top-k -> ?typical -> ?top-p -> min-p -> ?xtc -> ?temp-ext -> dist 
2026-05-17 02:30:27.095 | slot launch_slot_: id  2 | task 25182 | processing task, is_child = 0
2026-05-17 02:30:27.095 | slot update_slots: id  2 | task 25182 | new prompt, n_ctx_slot = 131072, n_keep = 0, task.n_tokens = 24600
2026-05-17 02:30:27.095 | slot update_slots: id  2 | task 25182 | n_tokens = 24580, memory_seq_rm [24580, end)
2026-05-17 02:30:27.095 | slot update_slots: id  2 | task 25182 | prompt processing progress, n_tokens = 24596, batch.n_tokens = 16, progress = 0.999837
2026-05-17 02:30:27.283 | slot create_check: id  2 | task 25182 | created context checkpoint 9 of 32 (pos_min = 24579, pos_max = 24579, n_tokens = 24580, size = 201.103 MiB)
2026-05-17 02:30:27.322 | slot update_slots: id  2 | task 25182 | n_tokens = 24596, memory_seq_rm [24596, end)
2026-05-17 02:30:27.326 | slot init_sampler: id  2 | task 25182 | init sampler, took 3.31 ms, tokens: text = 24600, total = 24600
2026-05-17 02:30:27.326 | slot update_slots: id  2 | task 25182 | prompt processing done, n_tokens = 24600, batch.n_tokens = 4
2026-05-17 02:30:27.363 | srv  log_server_r: done request: POST /v1/chat/completions 172.18.0.1 200
2026-05-17 02:30:27.873 | reasoning-budget: deactivated (natural end)
2026-05-17 02:30:28.623 | slot print_timing: id  2 | task 25182 | 
2026-05-17 02:30:28.623 | prompt eval time =     267.27 ms /    20 tokens (   13.36 ms per token,    74.83 tokens per second)
2026-05-17 02:30:28.623 |        eval time =    1260.41 ms /    89 tokens (   14.16 ms per token,    70.61 tokens per second)
2026-05-17 02:30:28.623 |       total time =    1527.68 ms /   109 tokens
2026-05-17 02:30:28.623 | draft acceptance rate = 0.96429 (   54 accepted /    56 generated)
2026-05-17 02:30:28.623 | statistics mtp: #calls(b,g,a) = 108 23137 17191, #gen drafts = 17191, #acc drafts = 17191, #gen tokens = 30273, #acc tokens = 29798, dur(b,g,a) = 0.164, 88916.108, 8.504 ms
2026-05-17 02:30:28.624 | slot      release: id  2 | task 25182 | stop processing: n_tokens = 24688, truncated = 0
2026-05-17 02:30:28.624 | srv  update_slots: all slots are idle
2026-05-17 02:48:24.271 | srv  params_from_: Chat format: peg-native
2026-05-17 02:48:24.274 | slot get_availabl: id  2 | task -1 | selected slot by LCP similarity, sim_best = 0.986 (> 0.100 thold), f_keep = 0.984
2026-05-17 02:48:24.275 | reasoning-budget: activated, budget=2147483647 tokens
2026-05-17 02:48:24.275 | slot launch_slot_: id  2 | task -1 | sampler chain: logits -> penalties -> ?dry -> ?top-n-sigma -> top-k -> ?typical -> ?top-p -> min-p -> ?xtc -> ?temp-ext -> dist 
2026-05-17 02:48:24.275 | slot launch_slot_: id  2 | task 25224 | processing task, is_child = 0
2026-05-17 02:48:24.275 | slot update_slots: id  2 | task 25224 | new prompt, n_ctx_slot = 131072, n_keep = 0, task.n_tokens = 24640
2026-05-17 02:48:24.275 | slot update_slots: id  2 | task 25224 | n_past = 24286, slot.prompt.tokens.size() = 24688, seq_id = 2, pos_min = 24687, n_swa = 0
2026-05-17 02:48:24.275 | slot update_slots: id  2 | task 25224 | Checking checkpoint with [24579, 24579] against 24286...
2026-05-17 02:48:24.275 | slot update_slots: id  2 | task 25224 | Checking checkpoint with [24343, 24343] against 24286...
2026-05-17 02:48:24.275 | slot update_slots: id  2 | task 25224 | Checking checkpoint with [23831, 23831] against 24286...
2026-05-17 02:48:24.353 | slot update_slots: id  2 | task 25224 | restored context checkpoint (pos_min = 23831, pos_max = 23831, n_tokens = 23832, n_past = 23832, size = 199.537 MiB)
2026-05-17 02:48:24.353 | slot update_slots: id  2 | task 25224 | erased invalidated context checkpoint (pos_min = 24343, pos_max = 24343, n_tokens = 24344, n_swa = 0, pos_next = 23832, size = 200.609 MiB)
2026-05-17 02:48:24.365 | slot update_slots: id  2 | task 25224 | erased invalidated context checkpoint (pos_min = 24579, pos_max = 24579, n_tokens = 24580, n_swa = 0, pos_next = 23832, size = 201.103 MiB)
2026-05-17 02:48:24.376 | slot update_slots: id  2 | task 25224 | n_tokens = 23832, memory_seq_rm [23832, end)
2026-05-17 02:48:24.377 | slot update_slots: id  2 | task 25224 | prompt processing progress, n_tokens = 24124, batch.n_tokens = 292, progress = 0.979058
2026-05-17 02:48:24.698 | slot update_slots: id  2 | task 25224 | n_tokens = 24124, memory_seq_rm [24124, end)
2026-05-17 02:48:24.698 | slot update_slots: id  2 | task 25224 | prompt processing progress, n_tokens = 24636, batch.n_tokens = 512, progress = 0.999838
2026-05-17 02:48:24.858 | slot create_check: id  2 | task 25224 | created context checkpoint 8 of 32 (pos_min = 24123, pos_max = 24123, n_tokens = 24124, size = 200.148 MiB)
2026-05-17 02:48:25.068 | slot update_slots: id  2 | task 25224 | n_tokens = 24636, memory_seq_rm [24636, end)
2026-05-17 02:48:25.071 | slot init_sampler: id  2 | task 25224 | init sampler, took 3.26 ms, tokens: text = 24640, total = 24640
2026-05-17 02:48:25.071 | slot update_slots: id  2 | task 25224 | prompt processing done, n_tokens = 24640, batch.n_tokens = 4
2026-05-17 02:48:25.219 | slot create_check: id  2 | task 25224 | created context checkpoint 9 of 32 (pos_min = 24635, pos_max = 24635, n_tokens = 24636, size = 201.221 MiB)
2026-05-17 02:48:25.256 | srv  log_server_r: done request: POST /v1/chat/completions 172.18.0.1 200
2026-05-17 02:48:25.505 | reasoning-budget: deactivated (natural end)
2026-05-17 02:48:26.190 | slot print_timing: id  2 | task 25224 | 
2026-05-17 02:48:26.190 | prompt eval time =     979.96 ms /   808 tokens (    1.21 ms per token,   824.53 tokens per second)
2026-05-17 02:48:26.190 |        eval time =     934.41 ms /    75 tokens (   12.46 ms per token,    80.26 tokens per second)
2026-05-17 02:48:26.190 |       total time =    1914.37 ms /   883 tokens
2026-05-17 02:48:26.190 | draft acceptance rate = 0.97959 (   48 accepted /    49 generated)
2026-05-17 02:48:26.190 | statistics mtp: #calls(b,g,a) = 109 23163 17216, #gen drafts = 17216, #acc drafts = 17216, #gen tokens = 30322, #acc tokens = 29846, dur(b,g,a) = 0.165, 89029.771, 8.518 ms
2026-05-17 02:48:26.191 | slot      release: id  2 | task 25224 | stop processing: n_tokens = 24714, truncated = 0
2026-05-17 02:48:26.191 | srv  update_slots: all slots are idle
2026-05-17 02:48:26.368 | srv  params_from_: Chat format: peg-native
2026-05-17 02:48:26.371 | slot get_availabl: id  2 | task -1 | selected slot by LCP similarity, sim_best = 0.996 (> 0.100 thold), f_keep = 1.000
2026-05-17 02:48:26.372 | reasoning-budget: activated, budget=2147483647 tokens
2026-05-17 02:48:26.372 | slot launch_slot_: id  2 | task -1 | sampler chain: logits -> penalties -> ?dry -> ?top-n-sigma -> top-k -> ?typical -> ?top-p -> min-p -> ?xtc -> ?temp-ext -> dist 
2026-05-17 02:48:26.372 | slot launch_slot_: id  2 | task 25256 | processing task, is_child = 0
2026-05-17 02:48:26.372 | slot update_slots: id  2 | task 25256 | new prompt, n_ctx_slot = 131072, n_keep = 0, task.n_tokens = 24807
2026-05-17 02:48:26.372 | slot update_slots: id  2 | task 25256 | n_tokens = 24714, memory_seq_rm [24714, end)
2026-05-17 02:48:26.373 | slot update_slots: id  2 | task 25256 | prompt processing progress, n_tokens = 24803, batch.n_tokens = 89, progress = 0.999839
2026-05-17 02:48:26.592 | slot create_check: id  2 | task 25256 | created context checkpoint 10 of 32 (pos_min = 24713, pos_max = 24713, n_tokens = 24714, size = 201.384 MiB)
2026-05-17 02:48:26.652 | slot update_slots: id  2 | task 25256 | n_tokens = 24803, memory_seq_rm [24803, end)
2026-05-17 02:48:26.655 | slot init_sampler: id  2 | task 25256 | init sampler, took 3.25 ms, tokens: text = 24807, total = 24807
2026-05-17 02:48:26.655 | slot update_slots: id  2 | task 25256 | prompt processing done, n_tokens = 24807, batch.n_tokens = 4
2026-05-17 02:48:26.877 | slot create_check: id  2 | task 25256 | created context checkpoint 11 of 32 (pos_min = 24802, pos_max = 24802, n_tokens = 24803, size = 201.570 MiB)
2026-05-17 02:48:26.912 | srv  log_server_r: done request: POST /v1/chat/completions 172.18.0.1 200
2026-05-17 02:48:27.530 | reasoning-budget: deactivated (natural end)
2026-05-17 02:48:28.094 | slot print_timing: id  2 | task 25256 | 
2026-05-17 02:48:28.094 | prompt eval time =     539.44 ms /    93 tokens (    5.80 ms per token,   172.40 tokens per second)
2026-05-17 02:48:28.094 |        eval time =    1182.06 ms /    76 tokens (   15.55 ms per token,    64.29 tokens per second)
2026-05-17 02:48:28.094 |       total time =    1721.50 ms /   169 tokens
2026-05-17 02:48:28.094 | draft acceptance rate = 1.00000 (   39 accepted /    39 generated)
2026-05-17 02:48:28.094 | statistics mtp: #calls(b,g,a) = 110 23199 17239, #gen drafts = 17239, #acc drafts = 17239, #gen tokens = 30361, #acc tokens = 29885, dur(b,g,a) = 0.166, 89150.290, 8.537 ms
2026-05-17 02:48:28.095 | slot      release: id  2 | task 25256 | stop processing: n_tokens = 24882, truncated = 0
2026-05-17 02:48:28.095 | srv  update_slots: all slots are idle
2026-05-17 02:48:28.276 | srv  params_from_: Chat format: peg-native
2026-05-17 02:48:28.279 | slot get_availabl: id  2 | task -1 | selected slot by LCP similarity, sim_best = 0.987 (> 0.100 thold), f_keep = 1.000
2026-05-17 02:48:28.280 | reasoning-budget: activated, budget=2147483647 tokens
2026-05-17 02:48:28.280 | slot launch_slot_: id  2 | task -1 | sampler chain: logits -> penalties -> ?dry -> ?top-n-sigma -> top-k -> ?typical -> ?top-p -> min-p -> ?xtc -> ?temp-ext -> dist 
2026-05-17 02:48:28.280 | slot launch_slot_: id  2 | task 25296 | processing task, is_child = 0
2026-05-17 02:48:28.280 | slot update_slots: id  2 | task 25296 | new prompt, n_ctx_slot = 131072, n_keep = 0, task.n_tokens = 25197
2026-05-17 02:48:28.280 | slot update_slots: id  2 | task 25296 | n_tokens = 24882, memory_seq_rm [24882, end)
2026-05-17 02:48:28.281 | slot update_slots: id  2 | task 25296 | prompt processing progress, n_tokens = 25193, batch.n_tokens = 311, progress = 0.999841
2026-05-17 02:48:28.502 | slot create_check: id  2 | task 25296 | created context checkpoint 12 of 32 (pos_min = 24881, pos_max = 24881, n_tokens = 24882, size = 201.736 MiB)
2026-05-17 02:48:28.644 | slot update_slots: id  2 | task 25296 | n_tokens = 25193, memory_seq_rm [25193, end)
2026-05-17 02:48:28.647 | slot init_sampler: id  2 | task 25296 | init sampler, took 3.27 ms, tokens: text = 25197, total = 25197
2026-05-17 02:48:28.647 | slot update_slots: id  2 | task 25296 | prompt processing done, n_tokens = 25197, batch.n_tokens = 4
2026-05-17 02:48:28.870 | slot create_check: id  2 | task 25296 | created context checkpoint 13 of 32 (pos_min = 25192, pos_max = 25192, n_tokens = 25193, size = 202.387 MiB)
2026-05-17 02:48:28.907 | srv  log_server_r: done request: POST /v1/chat/completions 172.18.0.1 200
2026-05-17 02:48:29.196 | reasoning-budget: deactivated (natural end)
2026-05-17 02:48:29.988 | slot print_timing: id  2 | task 25296 | 
2026-05-17 02:48:29.988 | prompt eval time =     625.70 ms /   315 tokens (    1.99 ms per token,   503.44 tokens per second)
2026-05-17 02:48:29.988 |        eval time =    1081.17 ms /    76 tokens (   14.23 ms per token,    70.29 tokens per second)
2026-05-17 02:48:29.988 |       total time =    1706.87 ms /   391 tokens
2026-05-17 02:48:29.988 | draft acceptance rate = 0.97872 (   46 accepted /    47 generated)
2026-05-17 02:48:29.988 | statistics mtp: #calls(b,g,a) = 111 23228 17264, #gen drafts = 17264, #acc drafts = 17264, #gen tokens = 30408, #acc tokens = 29931, dur(b,g,a) = 0.179, 89265.023, 8.552 ms
2026-05-17 02:48:29.989 | slot      release: id  2 | task 25296 | stop processing: n_tokens = 25272, truncated = 0
2026-05-17 02:48:29.989 | srv  update_slots: all slots are idle
2026-05-17 02:48:30.168 | srv  params_from_: Chat format: peg-native
2026-05-17 02:48:30.170 | slot get_availabl: id  2 | task -1 | selected slot by LCP similarity, sim_best = 0.998 (> 0.100 thold), f_keep = 1.000
2026-05-17 02:48:30.172 | reasoning-budget: activated, budget=2147483647 tokens
2026-05-17 02:48:30.172 | slot launch_slot_: id  2 | task -1 | sampler chain: logits -> penalties -> ?dry -> ?top-n-sigma -> top-k -> ?typical -> ?top-p -> min-p -> ?xtc -> ?temp-ext -> dist 
2026-05-17 02:48:30.172 | slot launch_slot_: id  2 | task 25330 | processing task, is_child = 0
2026-05-17 02:48:30.172 | slot update_slots: id  2 | task 25330 | new prompt, n_ctx_slot = 131072, n_keep = 0, task.n_tokens = 25330
2026-05-17 02:48:30.172 | slot update_slots: id  2 | task 25330 | n_tokens = 25272, memory_seq_rm [25272, end)
2026-05-17 02:48:30.172 | slot update_slots: id  2 | task 25330 | prompt processing progress, n_tokens = 25326, batch.n_tokens = 54, progress = 0.999842
2026-05-17 02:48:30.388 | slot create_check: id  2 | task 25330 | created context checkpoint 14 of 32 (pos_min = 25271, pos_max = 25271, n_tokens = 25272, size = 202.553 MiB)
2026-05-17 02:48:30.436 | slot update_slots: id  2 | task 25330 | n_tokens = 25326, memory_seq_rm [25326, end)
2026-05-17 02:48:30.440 | slot init_sampler: id  2 | task 25330 | init sampler, took 3.25 ms, tokens: text = 25330, total = 25330
2026-05-17 02:48:30.440 | slot update_slots: id  2 | task 25330 | prompt processing done, n_tokens = 25330, batch.n_tokens = 4
2026-05-17 02:48:30.475 | srv  log_server_r: done request: POST /v1/chat/completions 172.18.0.1 200
2026-05-17 02:48:30.735 | reasoning-budget: deactivated (natural end)
2026-05-17 02:48:31.265 | slot print_timing: id  2 | task 25330 | 
2026-05-17 02:48:31.265 | prompt eval time =     302.90 ms /    58 tokens (    5.22 ms per token,   191.48 tokens per second)
2026-05-17 02:48:31.265 |        eval time =     789.88 ms /    56 tokens (   14.11 ms per token,    70.90 tokens per second)
2026-05-17 02:48:31.265 |       total time =    1092.79 ms /   114 tokens
2026-05-17 02:48:31.265 | draft acceptance rate = 1.00000 (   34 accepted /    34 generated)
2026-05-17 02:48:31.265 | statistics mtp: #calls(b,g,a) = 112 23249 17283, #gen drafts = 17283, #acc drafts = 17283, #gen tokens = 30442, #acc tokens = 29965, dur(b,g,a) = 0.180, 89350.964, 8.564 ms
2026-05-17 02:48:31.266 | slot      release: id  2 | task 25330 | stop processing: n_tokens = 25385, truncated = 0
2026-05-17 02:48:31.266 | srv  update_slots: all slots are idle
2026-05-17 02:48:32.214 | srv  params_from_: Chat format: peg-native
2026-05-17 02:48:32.216 | slot get_availabl: id  2 | task -1 | selected slot by LCP similarity, sim_best = 0.997 (> 0.100 thold), f_keep = 1.000
2026-05-17 02:48:32.217 | reasoning-budget: activated, budget=2147483647 tokens
2026-05-17 02:48:32.218 | slot launch_slot_: id  2 | task -1 | sampler chain: logits -> penalties -> ?dry -> ?top-n-sigma -> top-k -> ?typical -> ?top-p -> min-p -> ?xtc -> ?temp-ext -> dist 
2026-05-17 02:48:32.218 | slot launch_slot_: id  2 | task 25355 | processing task, is_child = 0
2026-05-17 02:48:32.218 | slot update_slots: id  2 | task 25355 | new prompt, n_ctx_slot = 131072, n_keep = 0, task.n_tokens = 25457
2026-05-17 02:48:32.218 | slot update_slots: id  2 | task 25355 | n_tokens = 25385, memory_seq_rm [25385, end)
2026-05-17 02:48:32.218 | slot update_slots: id  2 | task 25355 | prompt processing progress, n_tokens = 25453, batch.n_tokens = 68, progress = 0.999843
2026-05-17 02:48:32.441 | slot create_check: id  2 | task 25355 | created context checkpoint 15 of 32 (pos_min = 25384, pos_max = 25384, n_tokens = 25385, size = 202.789 MiB)
2026-05-17 02:48:32.494 | slot update_slots: id  2 | task 25355 | n_tokens = 25453, memory_seq_rm [25453, end)
2026-05-17 02:48:32.497 | slot init_sampler: id  2 | task 25355 | init sampler, took 3.25 ms, tokens: text = 25457, total = 25457
2026-05-17 02:48:32.497 | slot update_slots: id  2 | task 25355 | prompt processing done, n_tokens = 25457, batch.n_tokens = 4
2026-05-17 02:48:32.719 | slot create_check: id  2 | task 25355 | created context checkpoint 16 of 32 (pos_min = 25452, pos_max = 25452, n_tokens = 25453, size = 202.932 MiB)
2026-05-17 02:48:32.755 | srv  log_server_r: done request: POST /v1/chat/completions 172.18.0.1 200
2026-05-17 02:48:33.305 | reasoning-budget: deactivated (natural end)
2026-05-17 02:48:34.082 | slot print_timing: id  2 | task 25355 | 
2026-05-17 02:48:34.082 | prompt eval time =     536.99 ms /    72 tokens (    7.46 ms per token,   134.08 tokens per second)
2026-05-17 02:48:34.082 |        eval time =    1327.22 ms /    70 tokens (   18.96 ms per token,    52.74 tokens per second)
2026-05-17 02:48:34.082 |       total time =    1864.21 ms /   142 tokens
2026-05-17 02:48:34.082 | draft acceptance rate = 0.94595 (   35 accepted /    37 generated)
2026-05-17 02:48:34.082 | statistics mtp: #calls(b,g,a) = 113 23283 17306, #gen drafts = 17306, #acc drafts = 17306, #gen tokens = 30479, #acc tokens = 30000, dur(b,g,a) = 0.182, 89475.736, 8.574 ms
2026-05-17 02:48:34.083 | slot      release: id  2 | task 25355 | stop processing: n_tokens = 25526, truncated = 0
2026-05-17 02:48:34.083 | srv  update_slots: all slots are idle
2026-05-17 02:49:06.423 | srv  params_from_: Chat format: peg-native
2026-05-17 02:49:06.426 | slot get_availabl: id  2 | task -1 | selected slot by LCP similarity, sim_best = 0.947 (> 0.100 thold), f_keep = 0.963
2026-05-17 02:49:06.428 | reasoning-budget: activated, budget=2147483647 tokens
2026-05-17 02:49:06.428 | slot launch_slot_: id  2 | task -1 | sampler chain: logits -> penalties -> ?dry -> ?top-n-sigma -> top-k -> ?typical -> ?top-p -> min-p -> ?xtc -> ?temp-ext -> dist 
2026-05-17 02:49:06.428 | slot launch_slot_: id  2 | task 25394 | processing task, is_child = 0
2026-05-17 02:49:06.428 | slot update_slots: id  2 | task 25394 | new prompt, n_ctx_slot = 131072, n_keep = 0, task.n_tokens = 25948
2026-05-17 02:49:06.428 | slot update_slots: id  2 | task 25394 | n_past = 24578, slot.prompt.tokens.size() = 25526, seq_id = 2, pos_min = 25525, n_swa = 0
2026-05-17 02:49:06.428 | slot update_slots: id  2 | task 25394 | Checking checkpoint with [25452, 25452] against 24578...
2026-05-17 02:49:06.428 | slot update_slots: id  2 | task 25394 | Checking checkpoint with [25384, 25384] against 24578...
2026-05-17 02:49:06.428 | slot update_slots: id  2 | task 25394 | Checking checkpoint with [25271, 25271] against 24578...
2026-05-17 02:49:06.428 | slot update_slots: id  2 | task 25394 | Checking checkpoint with [25192, 25192] against 24578...
2026-05-17 02:49:06.428 | slot update_slots: id  2 | task 25394 | Checking checkpoint with [24881, 24881] against 24578...
2026-05-17 02:49:06.428 | slot update_slots: id  2 | task 25394 | Checking checkpoint with [24802, 24802] against 24578...
2026-05-17 02:49:06.428 | slot update_slots: id  2 | task 25394 | Checking checkpoint with [24713, 24713] against 24578...
2026-05-17 02:49:06.428 | slot update_slots: id  2 | task 25394 | Checking checkpoint with [24635, 24635] against 24578...
2026-05-17 02:49:06.428 | slot update_slots: id  2 | task 25394 | Checking checkpoint with [24123, 24123] against 24578...
2026-05-17 02:49:06.502 | slot update_slots: id  2 | task 25394 | restored context checkpoint (pos_min = 24123, pos_max = 24123, n_tokens = 24124, n_past = 24124, size = 200.148 MiB)
2026-05-17 02:49:06.502 | slot update_slots: id  2 | task 25394 | erased invalidated context checkpoint (pos_min = 24635, pos_max = 24635, n_tokens = 24636, n_swa = 0, pos_next = 24124, size = 201.221 MiB)
2026-05-17 02:49:06.514 | slot update_slots: id  2 | task 25394 | erased invalidated context checkpoint (pos_min = 24713, pos_max = 24713, n_tokens = 24714, n_swa = 0, pos_next = 24124, size = 201.384 MiB)
2026-05-17 02:49:06.525 | slot update_slots: id  2 | task 25394 | erased invalidated context checkpoint (pos_min = 24802, pos_max = 24802, n_tokens = 24803, n_swa = 0, pos_next = 24124, size = 201.570 MiB)
2026-05-17 02:49:06.536 | slot update_slots: id  2 | task 25394 | erased invalidated context checkpoint (pos_min = 24881, pos_max = 24881, n_tokens = 24882, n_swa = 0, pos_next = 24124, size = 201.736 MiB)
2026-05-17 02:49:06.548 | slot update_slots: id  2 | task 25394 | erased invalidated context checkpoint (pos_min = 25192, pos_max = 25192, n_tokens = 25193, n_swa = 0, pos_next = 24124, size = 202.387 MiB)
2026-05-17 02:49:06.559 | slot update_slots: id  2 | task 25394 | erased invalidated context checkpoint (pos_min = 25271, pos_max = 25271, n_tokens = 25272, n_swa = 0, pos_next = 24124, size = 202.553 MiB)
2026-05-17 02:49:06.570 | slot update_slots: id  2 | task 25394 | erased invalidated context checkpoint (pos_min = 25384, pos_max = 25384, n_tokens = 25385, n_swa = 0, pos_next = 24124, size = 202.789 MiB)
2026-05-17 02:49:06.582 | slot update_slots: id  2 | task 25394 | erased invalidated context checkpoint (pos_min = 25452, pos_max = 25452, n_tokens = 25453, n_swa = 0, pos_next = 24124, size = 202.932 MiB)
2026-05-17 02:49:06.593 | slot update_slots: id  2 | task 25394 | n_tokens = 24124, memory_seq_rm [24124, end)
2026-05-17 02:49:06.594 | slot update_slots: id  2 | task 25394 | prompt processing progress, n_tokens = 25432, batch.n_tokens = 1308, progress = 0.980114
2026-05-17 02:49:07.318 | slot update_slots: id  2 | task 25394 | n_tokens = 25432, memory_seq_rm [25432, end)
2026-05-17 02:49:07.318 | slot update_slots: id  2 | task 25394 | prompt processing progress, n_tokens = 25944, batch.n_tokens = 512, progress = 0.999846
2026-05-17 02:49:07.468 | slot create_check: id  2 | task 25394 | created context checkpoint 9 of 32 (pos_min = 25431, pos_max = 25431, n_tokens = 25432, size = 202.888 MiB)
2026-05-17 02:49:07.682 | slot update_slots: id  2 | task 25394 | n_tokens = 25944, memory_seq_rm [25944, end)
2026-05-17 02:49:07.685 | slot init_sampler: id  2 | task 25394 | init sampler, took 3.32 ms, tokens: text = 25948, total = 25948
2026-05-17 02:49:07.685 | slot update_slots: id  2 | task 25394 | prompt processing done, n_tokens = 25948, batch.n_tokens = 4
2026-05-17 02:49:07.829 | slot create_check: id  2 | task 25394 | created context checkpoint 10 of 32 (pos_min = 25943, pos_max = 25943, n_tokens = 25944, size = 203.960 MiB)
2026-05-17 02:49:07.867 | srv  log_server_r: done request: POST /v1/chat/completions 172.18.0.1 200
2026-05-17 02:49:11.816 | slot print_timing: id  2 | task 25394 | 
2026-05-17 02:49:11.817 | prompt eval time =    1438.59 ms /  1824 tokens (    0.79 ms per token,  1267.91 tokens per second)
2026-05-17 02:49:11.817 |        eval time =    3949.78 ms /   218 tokens (   18.12 ms per token,    55.19 tokens per second)
2026-05-17 02:49:11.817 |       total time =    5388.37 ms /  2042 tokens
2026-05-17 02:49:11.817 | draft acceptance rate = 0.96552 (  112 accepted /   116 generated)
2026-05-17 02:49:11.817 | statistics mtp: #calls(b,g,a) = 114 23388 17377, #gen drafts = 17377, #acc drafts = 17377, #gen tokens = 30595, #acc tokens = 30112, dur(b,g,a) = 0.183, 89849.826, 8.610 ms
2026-05-17 02:49:11.817 | slot      release: id  2 | task 25394 | stop processing: n_tokens = 26165, truncated = 0
2026-05-17 02:49:11.817 | srv  update_slots: all slots are idle
2026-05-17 02:50:35.523 | srv    operator(): operator(): cleaning up before exit...
2026-05-17 02:50:35.525 | common_memory_breakdown_print: | memory breakdown [MiB] | total   free     self   model   context   compute    unaccounted |
2026-05-17 02:50:35.525 | common_memory_breakdown_print: |   - CUDA0 (RTX 5090)   | 32606 = 4649 + (21832 = 16386 +    4950 +     495) +        6124 |
2026-05-17 02:50:35.525 | common_memory_breakdown_print: |   - Host               |                   958 =   682 +       0 +     276                |
```