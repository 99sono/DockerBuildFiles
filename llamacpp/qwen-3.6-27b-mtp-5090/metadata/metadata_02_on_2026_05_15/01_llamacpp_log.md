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
    
# llamacpp log

```log
2026-05-14 22:13:25.196 | ggml_cuda_init: found 1 CUDA devices (Total VRAM: 32606 MiB):
2026-05-14 22:13:25.196 |   Device 0: NVIDIA GeForce RTX 5090, compute capability 12.0, VMM: yes, VRAM: 32606 MiB
2026-05-14 22:13:25.196 | load_backend: loaded CUDA backend from /app/libggml-cuda.so
2026-05-14 22:13:25.231 | load_backend: loaded CPU backend from /app/libggml-cpu-haswell.so
2026-05-14 22:13:25.231 | warn: LLAMA_ARG_HOST environment variable is set, but will be overwritten by command line argument --host
2026-05-14 22:13:25.424 | common_download_file_single_online: HEAD failed, status: 404
2026-05-14 22:13:25.425 | no remote preset found, skipping
2026-05-14 22:14:13.264 | main: n_parallel is set to auto, using n_parallel = 4 and kv_unified = true
2026-05-14 22:14:13.291 | build_info: b484-2c4055912
2026-05-14 22:14:13.292 | system_info: n_threads = 16 (n_threads_batch = 16) / 32 | CUDA : ARCHS = 750,800,860,890,1200,1210 | USE_GRAPHS = 1 | PEER_MAX_BATCH_SIZE = 128 | BLACKWELL_NATIVE_FP4 = 1 | CPU : SSE3 = 1 | SSSE3 = 1 | AVX = 1 | AVX2 = 1 | F16C = 1 | FMA = 1 | BMI2 = 1 | LLAMAFILE = 1 | OPENMP = 1 | REPACK = 1 | 
2026-05-14 22:14:13.292 | Running without SSL
2026-05-14 22:14:13.292 | init: using 31 threads for HTTP server
2026-05-14 22:14:13.292 | start: binding port with default address family
2026-05-14 22:14:13.294 | main: loading model
2026-05-14 22:14:13.295 | srv    load_model: loading model '/root/.cache/huggingface/hub/models--unsloth--Qwen3.6-27B-MTP-GGUF/snapshots/53b097416d6346f849b530e4bc1b5590dfe9d758/Qwen3.6-27B-UD-Q4_K_XL.gguf'
2026-05-14 22:14:13.296 | common_init_result: fitting params to device memory, for bugs during this step try to reproduce them with -fit off, or provide --verbose logs if the bug only occurs with -fit on
2026-05-14 22:14:13.296 | common_params_fit_impl: getting device memory data for initial parameters:
2026-05-14 22:14:14.048 | common_memory_breakdown_print: | memory breakdown [MiB] | total    free     self   model   context   compute    unaccounted |
2026-05-14 22:14:14.048 | common_memory_breakdown_print: |   - CUDA0 (RTX 5090)   | 32606 = 30330 + (21832 = 16386 +    4950 +     495) +      -19555 |
2026-05-14 22:14:14.048 | common_memory_breakdown_print: |   - Host               |                    958 =   682 +       0 +     276                |
2026-05-14 22:14:14.115 | common_params_fit_impl: projected to use 21832 MiB of device memory vs. 30330 MiB of free device memory
2026-05-14 22:14:14.115 | common_params_fit_impl: will leave 8497 >= 1024 MiB of free device memory, no changes needed
2026-05-14 22:14:14.115 | common_fit_params: successfully fit params to free device memory
2026-05-14 22:14:14.115 | common_fit_params: fitting params to free memory took 0.82 seconds
2026-05-14 22:14:14.149 | llama_model_loader: loaded meta data with 52 key-value pairs and 866 tensors from /root/.cache/huggingface/hub/models--unsloth--Qwen3.6-27B-MTP-GGUF/snapshots/53b097416d6346f849b530e4bc1b5590dfe9d758/Qwen3.6-27B-UD-Q4_K_XL.gguf (version GGUF V3 (latest))
2026-05-14 22:14:14.149 | llama_model_loader: Dumping metadata keys/values. Note: KV overrides do not apply in this output.
2026-05-14 22:14:14.149 | llama_model_loader: - kv   0:                       general.architecture str              = qwen35
2026-05-14 22:14:14.149 | llama_model_loader: - kv   1:                               general.type str              = model
2026-05-14 22:14:14.149 | llama_model_loader: - kv   2:                     general.sampling.top_k i32              = 20
2026-05-14 22:14:14.149 | llama_model_loader: - kv   3:                     general.sampling.top_p f32              = 0.950000
2026-05-14 22:14:14.149 | llama_model_loader: - kv   4:                      general.sampling.temp f32              = 1.000000
2026-05-14 22:14:14.149 | llama_model_loader: - kv   5:                               general.name str              = Qwen3.6-27B
2026-05-14 22:14:14.149 | llama_model_loader: - kv   6:                           general.basename str              = Qwen3.6-27B
2026-05-14 22:14:14.149 | llama_model_loader: - kv   7:                       general.quantized_by str              = Unsloth
2026-05-14 22:14:14.149 | llama_model_loader: - kv   8:                         general.size_label str              = 27B
2026-05-14 22:14:14.149 | llama_model_loader: - kv   9:                            general.license str              = apache-2.0
2026-05-14 22:14:14.149 | llama_model_loader: - kv  10:                       general.license.link str              = https://huggingface.co/Qwen/Qwen3.6-2...
2026-05-14 22:14:14.149 | llama_model_loader: - kv  11:                           general.repo_url str              = https://huggingface.co/unsloth
2026-05-14 22:14:14.149 | llama_model_loader: - kv  12:                   general.base_model.count u32              = 1
2026-05-14 22:14:14.149 | llama_model_loader: - kv  13:                  general.base_model.0.name str              = Qwen3.6 27B
2026-05-14 22:14:14.149 | llama_model_loader: - kv  14:          general.base_model.0.organization str              = Qwen
2026-05-14 22:14:14.149 | llama_model_loader: - kv  15:              general.base_model.0.repo_url str              = https://huggingface.co/Qwen/Qwen3.6-27B
2026-05-14 22:14:14.149 | llama_model_loader: - kv  16:                               general.tags arr[str,2]       = ["unsloth", "image-text-to-text"]
2026-05-14 22:14:14.149 | llama_model_loader: - kv  17:                         qwen35.block_count u32              = 65
2026-05-14 22:14:14.149 | llama_model_loader: - kv  18:                      qwen35.context_length u32              = 262144
2026-05-14 22:14:14.149 | llama_model_loader: - kv  19:                    qwen35.embedding_length u32              = 5120
2026-05-14 22:14:14.149 | llama_model_loader: - kv  20:                 qwen35.feed_forward_length u32              = 17408
2026-05-14 22:14:14.149 | llama_model_loader: - kv  21:                qwen35.attention.head_count u32              = 24
2026-05-14 22:14:14.149 | llama_model_loader: - kv  22:             qwen35.attention.head_count_kv u32              = 4
2026-05-14 22:14:14.149 | llama_model_loader: - kv  23:             qwen35.rope.dimension_sections arr[i32,4]       = [11, 11, 10, 0]
2026-05-14 22:14:14.149 | llama_model_loader: - kv  24:                      qwen35.rope.freq_base f32              = 10000000.000000
2026-05-14 22:14:14.149 | llama_model_loader: - kv  25:    qwen35.attention.layer_norm_rms_epsilon f32              = 0.000001
2026-05-14 22:14:14.149 | llama_model_loader: - kv  26:                qwen35.attention.key_length u32              = 256
2026-05-14 22:14:14.149 | llama_model_loader: - kv  27:              qwen35.attention.value_length u32              = 256
2026-05-14 22:14:14.149 | llama_model_loader: - kv  28:                     qwen35.ssm.conv_kernel u32              = 4
2026-05-14 22:14:14.149 | llama_model_loader: - kv  29:                      qwen35.ssm.state_size u32              = 128
2026-05-14 22:14:14.149 | llama_model_loader: - kv  30:                     qwen35.ssm.group_count u32              = 16
2026-05-14 22:14:14.149 | llama_model_loader: - kv  31:                  qwen35.ssm.time_step_rank u32              = 48
2026-05-14 22:14:14.149 | llama_model_loader: - kv  32:                      qwen35.ssm.inner_size u32              = 6144
2026-05-14 22:14:14.149 | llama_model_loader: - kv  33:             qwen35.full_attention_interval u32              = 4
2026-05-14 22:14:14.149 | llama_model_loader: - kv  34:                qwen35.rope.dimension_count u32              = 64
2026-05-14 22:14:14.149 | llama_model_loader: - kv  35:                qwen35.nextn_predict_layers u32              = 1
2026-05-14 22:14:14.149 | llama_model_loader: - kv  36:                       tokenizer.ggml.model str              = gpt2
2026-05-14 22:14:14.149 | llama_model_loader: - kv  37:                         tokenizer.ggml.pre str              = qwen35
2026-05-14 22:14:14.169 | llama_model_loader: - kv  38:                      tokenizer.ggml.tokens arr[str,248320]  = ["!", "\"", "#", "$", "%", "&", "'", ...
2026-05-14 22:14:14.175 | llama_model_loader: - kv  39:                  tokenizer.ggml.token_type arr[i32,248320]  = [1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, ...
2026-05-14 22:14:14.195 | llama_model_loader: - kv  40:                      tokenizer.ggml.merges arr[str,247587]  = ["Ġ Ġ", "ĠĠ ĠĠ", "i n", "Ġ t",...
2026-05-14 22:14:14.195 | llama_model_loader: - kv  41:                tokenizer.ggml.eos_token_id u32              = 248046
2026-05-14 22:14:14.195 | llama_model_loader: - kv  42:            tokenizer.ggml.padding_token_id u32              = 248055
2026-05-14 22:14:14.195 | llama_model_loader: - kv  43:                tokenizer.ggml.bos_token_id u32              = 248044
2026-05-14 22:14:14.195 | llama_model_loader: - kv  44:               tokenizer.ggml.add_bos_token bool             = false
2026-05-14 22:14:14.195 | llama_model_loader: - kv  45:                    tokenizer.chat_template str              = {%- set image_count = namespace(value...
2026-05-14 22:14:14.195 | llama_model_loader: - kv  46:               general.quantization_version u32              = 2
2026-05-14 22:14:14.195 | llama_model_loader: - kv  47:                          general.file_type u32              = 15
2026-05-14 22:14:14.195 | llama_model_loader: - kv  48:                      quantize.imatrix.file str              = Qwen3.6-27B-GGUF/imatrix_unsloth.gguf
2026-05-14 22:14:14.195 | llama_model_loader: - kv  49:                   quantize.imatrix.dataset str              = unsloth_calibration_Qwen3.6-27B.txt
2026-05-14 22:14:14.195 | llama_model_loader: - kv  50:             quantize.imatrix.entries_count u32              = 496
2026-05-14 22:14:14.195 | llama_model_loader: - kv  51:              quantize.imatrix.chunks_count u32              = 76
2026-05-14 22:14:14.195 | llama_model_loader: - type  f32:  456 tensors
2026-05-14 22:14:14.195 | llama_model_loader: - type q8_0:   49 tensors
2026-05-14 22:14:14.195 | llama_model_loader: - type q4_K:  225 tensors
2026-05-14 22:14:14.195 | llama_model_loader: - type q5_K:   70 tensors
2026-05-14 22:14:14.195 | llama_model_loader: - type q6_K:   66 tensors
2026-05-14 22:14:14.195 | print_info: file format = GGUF V3 (latest)
2026-05-14 22:14:14.195 | print_info: file type   = Q4_K - Medium
2026-05-14 22:14:14.195 | print_info: file size   = 16.67 GiB (5.24 BPW) 
2026-05-14 22:14:14.195 | llama_prepare_model_devices: using device CUDA0 (NVIDIA GeForce RTX 5090) (0000:0b:00.0) - 30930 MiB free
2026-05-14 22:14:14.366 | load: 0 unused tokens
2026-05-14 22:14:14.417 | load: printing all EOG tokens:
2026-05-14 22:14:14.417 | load:   - 248044 ('<|endoftext|>')
2026-05-14 22:14:14.417 | load:   - 248046 ('<|im_end|>')
2026-05-14 22:14:14.417 | load:   - 248063 ('<|fim_pad|>')
2026-05-14 22:14:14.417 | load:   - 248064 ('<|repo_name|>')
2026-05-14 22:14:14.417 | load:   - 248065 ('<|file_sep|>')
2026-05-14 22:14:14.417 | load: special tokens cache size = 33
2026-05-14 22:14:14.493 | load: token to piece cache size = 1.7581 MB
2026-05-14 22:14:14.493 | print_info: arch                  = qwen35
2026-05-14 22:14:14.493 | print_info: vocab_only            = 0
2026-05-14 22:14:14.493 | print_info: no_alloc              = 0
2026-05-14 22:14:14.493 | print_info: n_ctx_train           = 262144
2026-05-14 22:14:14.493 | print_info: n_embd                = 5120
2026-05-14 22:14:14.493 | print_info: n_embd_inp            = 5120
2026-05-14 22:14:14.493 | print_info: n_layer               = 65
2026-05-14 22:14:14.493 | print_info: n_head                = 24
2026-05-14 22:14:14.493 | print_info: n_head_kv             = 4
2026-05-14 22:14:14.493 | print_info: n_rot                 = 64
2026-05-14 22:14:14.493 | print_info: n_swa                 = 0
2026-05-14 22:14:14.493 | print_info: is_swa_any            = 0
2026-05-14 22:14:14.493 | print_info: n_embd_head_k         = 256
2026-05-14 22:14:14.493 | print_info: n_embd_head_v         = 256
2026-05-14 22:14:14.493 | print_info: n_gqa                 = 6
2026-05-14 22:14:14.493 | print_info: n_embd_k_gqa          = 1024
2026-05-14 22:14:14.493 | print_info: n_embd_v_gqa          = 1024
2026-05-14 22:14:14.493 | print_info: f_norm_eps            = 0.0e+00
2026-05-14 22:14:14.493 | print_info: f_norm_rms_eps        = 1.0e-06
2026-05-14 22:14:14.493 | print_info: f_clamp_kqv           = 0.0e+00
2026-05-14 22:14:14.493 | print_info: f_max_alibi_bias      = 0.0e+00
2026-05-14 22:14:14.493 | print_info: f_logit_scale         = 0.0e+00
2026-05-14 22:14:14.493 | print_info: f_attn_scale          = 0.0e+00
2026-05-14 22:14:14.493 | print_info: f_attn_value_scale    = 0.0000
2026-05-14 22:14:14.493 | print_info: n_ff                  = 17408
2026-05-14 22:14:14.493 | print_info: n_expert              = 0
2026-05-14 22:14:14.493 | print_info: n_expert_used         = 0
2026-05-14 22:14:14.493 | print_info: n_expert_groups       = 0
2026-05-14 22:14:14.493 | print_info: n_group_used          = 0
2026-05-14 22:14:14.493 | print_info: causal attn           = 1
2026-05-14 22:14:14.493 | print_info: pooling type          = -1
2026-05-14 22:14:14.493 | print_info: rope type             = 40
2026-05-14 22:14:14.493 | print_info: rope scaling          = linear
2026-05-14 22:14:14.493 | print_info: freq_base_train       = 10000000.0
2026-05-14 22:14:14.493 | print_info: freq_scale_train      = 1
2026-05-14 22:14:14.493 | print_info: n_ctx_orig_yarn       = 262144
2026-05-14 22:14:14.493 | print_info: rope_yarn_log_mul     = 0.0000
2026-05-14 22:14:14.493 | print_info: rope_finetuned        = unknown
2026-05-14 22:14:14.493 | print_info: mrope sections        = [11, 11, 10, 0]
2026-05-14 22:14:14.493 | print_info: ssm_d_conv            = 4
2026-05-14 22:14:14.493 | print_info: ssm_d_inner           = 6144
2026-05-14 22:14:14.493 | print_info: ssm_d_state           = 128
2026-05-14 22:14:14.493 | print_info: ssm_dt_rank           = 48
2026-05-14 22:14:14.493 | print_info: ssm_n_group           = 16
2026-05-14 22:14:14.493 | print_info: ssm_dt_b_c_rms        = 0
2026-05-14 22:14:14.493 | print_info: model type            = 27B
2026-05-14 22:14:14.493 | print_info: model params          = 27.32 B
2026-05-14 22:14:14.493 | print_info: general.name          = Qwen3.6-27B
2026-05-14 22:14:14.493 | print_info: vocab type            = BPE
2026-05-14 22:14:14.493 | print_info: n_vocab               = 248320
2026-05-14 22:14:14.493 | print_info: n_merges              = 247587
2026-05-14 22:14:14.493 | print_info: BOS token             = 248044 '<|endoftext|>'
2026-05-14 22:14:14.493 | print_info: EOS token             = 248046 '<|im_end|>'
2026-05-14 22:14:14.493 | print_info: EOT token             = 248046 '<|im_end|>'
2026-05-14 22:14:14.493 | print_info: PAD token             = 248055 '<|vision_pad|>'
2026-05-14 22:14:14.493 | print_info: LF token              = 198 'Ċ'
2026-05-14 22:14:14.493 | print_info: FIM PRE token         = 248060 '<|fim_prefix|>'
2026-05-14 22:14:14.493 | print_info: FIM SUF token         = 248062 '<|fim_suffix|>'
2026-05-14 22:14:14.493 | print_info: FIM MID token         = 248061 '<|fim_middle|>'
2026-05-14 22:14:14.494 | print_info: FIM PAD token         = 248063 '<|fim_pad|>'
2026-05-14 22:14:14.494 | print_info: FIM REP token         = 248064 '<|repo_name|>'
2026-05-14 22:14:14.494 | print_info: FIM SEP token         = 248065 '<|file_sep|>'
2026-05-14 22:14:14.494 | print_info: EOG token             = 248044 '<|endoftext|>'
2026-05-14 22:14:14.494 | print_info: EOG token             = 248046 '<|im_end|>'
2026-05-14 22:14:14.494 | print_info: EOG token             = 248063 '<|fim_pad|>'
2026-05-14 22:14:14.494 | print_info: EOG token             = 248064 '<|repo_name|>'
2026-05-14 22:14:14.494 | print_info: EOG token             = 248065 '<|file_sep|>'
2026-05-14 22:14:14.494 | print_info: max token length      = 256
2026-05-14 22:14:14.494 | load_tensors: loading model tensors, this can take a while... (mmap = true, direct_io = false)
2026-05-14 22:14:27.974 | load_tensors: offloading output layer to GPU
2026-05-14 22:14:27.974 | load_tensors: offloading 64 repeating layers to GPU
2026-05-14 22:14:27.974 | load_tensors: offloaded 66/66 layers to GPU
2026-05-14 22:14:27.974 | load_tensors:   CPU_Mapped model buffer size =   682.03 MiB
2026-05-14 22:14:27.974 | load_tensors:        CUDA0 model buffer size = 16386.94 MiB
2026-05-14 22:14:30.962 | .............................................................................................
2026-05-14 22:14:30.967 | common_init_result: added <|endoftext|> logit bias = -inf
2026-05-14 22:14:30.967 | common_init_result: added <|im_end|> logit bias = -inf
2026-05-14 22:14:30.967 | common_init_result: added <|fim_pad|> logit bias = -inf
2026-05-14 22:14:30.967 | common_init_result: added <|repo_name|> logit bias = -inf
2026-05-14 22:14:30.967 | common_init_result: added <|file_sep|> logit bias = -inf
2026-05-14 22:14:30.967 | llama_context: constructing llama_context
2026-05-14 22:14:30.967 | llama_context: n_seq_max     = 4
2026-05-14 22:14:30.967 | llama_context: n_ctx         = 131072
2026-05-14 22:14:30.967 | llama_context: n_ctx_seq     = 131072
2026-05-14 22:14:30.967 | llama_context: n_batch       = 2048
2026-05-14 22:14:30.967 | llama_context: n_ubatch      = 512
2026-05-14 22:14:30.967 | llama_context: causal_attn   = 1
2026-05-14 22:14:30.967 | llama_context: flash_attn    = enabled
2026-05-14 22:14:30.967 | llama_context: kv_unified    = true
2026-05-14 22:14:30.967 | llama_context: freq_base     = 10000000.0
2026-05-14 22:14:30.967 | llama_context: freq_scale    = 1
2026-05-14 22:14:30.967 | llama_context: n_ctx_seq (131072) < n_ctx_train (262144) -- the full capacity of the model will not be utilized
2026-05-14 22:14:30.972 | llama_context:  CUDA_Host  output buffer size =     3.79 MiB
2026-05-14 22:14:30.995 | llama_kv_cache:      CUDA0 KV buffer size =  4352.00 MiB
2026-05-14 22:14:31.035 | llama_kv_cache: size = 4352.00 MiB (131072 cells,  16 layers,  4/1 seqs), K (q8_0): 2176.00 MiB, V (q8_0): 2176.00 MiB
2026-05-14 22:14:31.035 | llama_kv_cache: attn_rot_k = 1, n_embd_head_k_all = 256
2026-05-14 22:14:31.035 | llama_kv_cache: attn_rot_v = 1, n_embd_head_k_all = 256
2026-05-14 22:14:31.046 | llama_memory_recurrent:      CUDA0 RS buffer size =   598.50 MiB
2026-05-14 22:14:31.046 | llama_memory_recurrent: size =  598.50 MiB (     4 cells,  65 layers,  4 seqs), R (f32):   22.50 MiB, S (f32):  576.00 MiB
2026-05-14 22:14:31.046 | sched_reserve: reserving ...
2026-05-14 22:14:31.069 | sched_reserve: resolving fused Gated Delta Net support:
2026-05-14 22:14:31.071 | sched_reserve: fused Gated Delta Net (autoregressive) enabled
2026-05-14 22:14:31.071 | sched_reserve: fused Gated Delta Net (chunked) enabled
2026-05-14 22:14:31.360 | sched_reserve:      CUDA0 compute buffer size =   495.00 MiB
2026-05-14 22:14:31.360 | sched_reserve:  CUDA_Host compute buffer size =   276.29 MiB
2026-05-14 22:14:31.360 | sched_reserve: graph nodes  = 3849
2026-05-14 22:14:31.360 | sched_reserve: graph splits = 2
2026-05-14 22:14:31.360 | sched_reserve: reserve took 314.06 ms, sched copies = 1
2026-05-14 22:14:31.360 | common_init_from_params: warming up the model with an empty run - please wait ... (--no-warmup to disable)
2026-05-14 22:14:31.712 | srv    load_model: creating MTP draft context against the target model '/root/.cache/huggingface/hub/models--unsloth--Qwen3.6-27B-MTP-GGUF/snapshots/53b097416d6346f849b530e4bc1b5590dfe9d758/Qwen3.6-27B-UD-Q4_K_XL.gguf'
2026-05-14 22:14:31.712 | llama_context: constructing llama_context
2026-05-14 22:14:31.712 | llama_context: n_seq_max     = 4
2026-05-14 22:14:31.712 | llama_context: n_ctx         = 131072
2026-05-14 22:14:31.712 | llama_context: n_ctx_seq     = 131072
2026-05-14 22:14:31.712 | llama_context: n_batch       = 2048
2026-05-14 22:14:31.712 | llama_context: n_ubatch      = 512
2026-05-14 22:14:31.712 | llama_context: causal_attn   = 1
2026-05-14 22:14:31.712 | llama_context: flash_attn    = enabled
2026-05-14 22:14:31.712 | llama_context: kv_unified    = true
2026-05-14 22:14:31.712 | llama_context: freq_base     = 10000000.0
2026-05-14 22:14:31.712 | llama_context: freq_scale    = 1
2026-05-14 22:14:31.712 | llama_context: n_ctx_seq (131072) < n_ctx_train (262144) -- the full capacity of the model will not be utilized
2026-05-14 22:14:31.717 | llama_context:  CUDA_Host  output buffer size =     3.79 MiB
2026-05-14 22:14:31.725 | llama_kv_cache:      CUDA0 KV buffer size =   272.00 MiB
2026-05-14 22:14:31.728 | llama_kv_cache: size =  272.00 MiB (131072 cells,   1 layers,  4/1 seqs), K (q8_0):  136.00 MiB, V (q8_0):  136.00 MiB
2026-05-14 22:14:31.728 | llama_kv_cache: attn_rot_k = 1, n_embd_head_k_all = 256
2026-05-14 22:14:31.728 | llama_kv_cache: attn_rot_v = 1, n_embd_head_k_all = 256
2026-05-14 22:14:31.728 | sched_reserve: reserving ...
2026-05-14 22:14:31.753 | sched_reserve: resolving fused Gated Delta Net support:
2026-05-14 22:14:31.754 | sched_reserve: fused Gated Delta Net (autoregressive) enabled
2026-05-14 22:14:31.754 | sched_reserve: fused Gated Delta Net (chunked) enabled
2026-05-14 22:14:32.050 | sched_reserve:      CUDA0 compute buffer size =   495.00 MiB
2026-05-14 22:14:32.050 | sched_reserve:  CUDA_Host compute buffer size =   276.28 MiB
2026-05-14 22:14:32.050 | sched_reserve: graph nodes  = 62
2026-05-14 22:14:32.050 | sched_reserve: graph splits = 2
2026-05-14 22:14:32.050 | sched_reserve: reserve took 321.23 ms, sched copies = 1
2026-05-14 22:14:32.063 | clip_model_loader: model name:   Qwen3.6-27B
2026-05-14 22:14:32.063 | clip_model_loader: description:  
2026-05-14 22:14:32.063 | clip_model_loader: GGUF version: 3
2026-05-14 22:14:32.063 | clip_model_loader: alignment:    32
2026-05-14 22:14:32.063 | clip_model_loader: n_tensors:    334
2026-05-14 22:14:32.063 | clip_model_loader: n_kv:         33
2026-05-14 22:14:32.063 | 
2026-05-14 22:14:32.063 | clip_model_loader: has vision encoder
2026-05-14 22:14:32.063 | clip_ctx: CLIP using CUDA0 backend
2026-05-14 22:14:32.068 | load_hparams: Qwen-VL models require at minimum 1024 image tokens to function correctly on grounding tasks
2026-05-14 22:14:32.068 | load_hparams: if you encounter problems with accuracy, try adding --image-min-tokens 1024
2026-05-14 22:14:32.068 | load_hparams: more info: https://github.com/ggml-org/llama.cpp/issues/16842
2026-05-14 22:14:32.068 | 
2026-05-14 22:14:32.068 | load_hparams: projector:          qwen3vl_merger
2026-05-14 22:14:32.068 | load_hparams: n_embd:             1152
2026-05-14 22:14:32.068 | load_hparams: n_head:             16
2026-05-14 22:14:32.068 | load_hparams: n_ff:               4304
2026-05-14 22:14:32.068 | load_hparams: n_layer:            27
2026-05-14 22:14:32.068 | load_hparams: ffn_op:             gelu
2026-05-14 22:14:32.068 | load_hparams: projection_dim:     5120
2026-05-14 22:14:32.068 | 
2026-05-14 22:14:32.068 | --- vision hparams ---
2026-05-14 22:14:32.068 | load_hparams: image_size:         768
2026-05-14 22:14:32.068 | load_hparams: patch_size:         16
2026-05-14 22:14:32.068 | load_hparams: has_llava_proj:     0
2026-05-14 22:14:32.068 | load_hparams: minicpmv_version:   0
2026-05-14 22:14:32.068 | load_hparams: n_merge:            2
2026-05-14 22:14:32.068 | load_hparams: n_wa_pattern: 0
2026-05-14 22:14:32.068 | load_hparams: image_min_pixels:   8192
2026-05-14 22:14:32.068 | load_hparams: image_max_pixels:   4194304
2026-05-14 22:14:32.068 | 
2026-05-14 22:14:32.068 | load_hparams: model size:         887.99 MiB
2026-05-14 22:14:32.068 | load_hparams: metadata size:      0.12 MiB
2026-05-14 22:14:32.411 | warmup: warmup with image size = 1472 x 1472
2026-05-14 22:14:32.413 | alloc_compute_meta:      CUDA0 compute buffer size =   248.10 MiB
2026-05-14 22:14:32.413 | alloc_compute_meta:        CPU compute buffer size =    24.93 MiB
2026-05-14 22:14:32.413 | alloc_compute_meta: graph splits = 1, nodes = 823
2026-05-14 22:14:32.413 | warmup: flash attention is enabled
2026-05-14 22:14:32.413 | srv    load_model: loaded multimodal model, '/root/.cache/huggingface/hub/models--unsloth--Qwen3.6-27B-MTP-GGUF/snapshots/53b097416d6346f849b530e4bc1b5590dfe9d758/mmproj-BF16.gguf'
2026-05-14 22:14:32.413 | srv    load_model: initializing slots, n_slots = 4
2026-05-14 22:14:32.457 | common_context_can_seq_rm: the context does not support partial sequence removal
2026-05-14 22:14:32.491 | srv    load_model: speculative decoding will use checkpoints
2026-05-14 22:14:32.491 | common_speculative_init: adding speculative implementation 'mtp'
2026-05-14 22:14:32.491 | srv    load_model: speculative decoding context initialized
2026-05-14 22:14:32.491 | slot   load_model: id  0 | task -1 | new slot, n_ctx = 131072
2026-05-14 22:14:32.491 | slot   load_model: id  1 | task -1 | new slot, n_ctx = 131072
2026-05-14 22:14:32.491 | slot   load_model: id  2 | task -1 | new slot, n_ctx = 131072
2026-05-14 22:14:32.491 | slot   load_model: id  3 | task -1 | new slot, n_ctx = 131072
2026-05-14 22:14:32.491 | srv    load_model: prompt cache is enabled, size limit: 8192 MiB
2026-05-14 22:14:32.491 | srv    load_model: use `--cache-ram 0` to disable the prompt cache
2026-05-14 22:14:32.491 | srv    load_model: for more info see https://github.com/ggml-org/llama.cpp/pull/16391
2026-05-14 22:14:32.491 | srv          init: init: idle slots will be saved to prompt cache and cleared upon starting a new task
2026-05-14 22:14:32.507 | init: chat template, example_format: '<|im_start|>system
2026-05-14 22:14:32.507 | You are a helpful assistant<|im_end|>
2026-05-14 22:14:32.507 | <|im_start|>user
2026-05-14 22:14:32.507 | Hello<|im_end|>
2026-05-14 22:14:32.507 | <|im_start|>assistant
2026-05-14 22:14:32.507 | Hi there<|im_end|>
2026-05-14 22:14:32.507 | <|im_start|>user
2026-05-14 22:14:32.507 | How are you?<|im_end|>
2026-05-14 22:14:32.507 | <|im_start|>assistant
2026-05-14 22:14:32.507 | <think>
2026-05-14 22:14:32.507 | '
2026-05-14 22:14:32.517 | srv          init: init: chat template, thinking = 1
2026-05-14 22:14:32.517 | main: model loaded
2026-05-14 22:14:32.517 | main: server is listening on http://0.0.0.0:8080
2026-05-14 22:14:32.517 | main: starting the main loop...
2026-05-14 22:14:32.517 | srv  update_slots: all slots are idle
2026-05-14 22:21:50.934 | srv  log_server_r: done request: GET /favicon.ico 172.18.0.1 404
2026-05-14 22:36:21.379 | srv    operator(): got exception: {"error":{"code":500,"message":"[json.exception.parse_error.101] parse error at line 11, column 0: syntax error while parsing value - invalid string: control character U+000A (LF) must be escaped to \\u000A or \\n; last read: '\"# Test Prompt for Qwen3.6-27B MTP Server<U+000A>'","type":"server_error"}}
2026-05-14 22:36:21.379 | srv  log_server_r: done request: POST /v1/chat/completions 172.18.0.1 500
2026-05-14 22:40:00.313 | srv  params_from_: Chat format: peg-native
2026-05-14 22:40:00.315 | slot get_availabl: id  3 | task -1 | selected slot by LRU, t_last = -1
2026-05-14 22:40:00.315 | srv  get_availabl: updating prompt cache
2026-05-14 22:40:00.315 | srv          load:  - looking for better prompt, base f_keep = -1.000, sim = 0.000
2026-05-14 22:40:00.315 | srv        update:  - cache state: 0 prompts, 0.000 MiB (limits: 8192.000 MiB, 131072 tokens, 8589934592 est)
2026-05-14 22:40:00.315 | srv  get_availabl: prompt cache update took 0.01 ms
2026-05-14 22:40:00.316 | slot launch_slot_: id  3 | task -1 | sampler chain: logits -> penalties -> ?dry -> ?top-n-sigma -> top-k -> ?typical -> top-p -> min-p -> ?xtc -> ?temp-ext -> dist 
2026-05-14 22:40:00.316 | slot launch_slot_: id  3 | task 0 | processing task, is_child = 0
2026-05-14 22:40:00.316 | slot update_slots: id  3 | task 0 | new prompt, n_ctx_slot = 131072, n_keep = 0, task.n_tokens = 133
2026-05-14 22:40:00.316 | slot update_slots: id  3 | task 0 | n_tokens = 0, memory_seq_rm [0, end)
2026-05-14 22:40:00.316 | slot update_slots: id  3 | task 0 | prompt processing progress, n_tokens = 129, batch.n_tokens = 129, progress = 0.969925
2026-05-14 22:40:00.708 | slot update_slots: id  3 | task 0 | n_tokens = 129, memory_seq_rm [129, end)
2026-05-14 22:40:00.708 | slot init_sampler: id  3 | task 0 | init sampler, took 0.04 ms, tokens: text = 133, total = 133
2026-05-14 22:40:00.708 | slot update_slots: id  3 | task 0 | prompt processing done, n_tokens = 133, batch.n_tokens = 4
2026-05-14 22:40:00.890 | slot create_check: id  3 | task 0 | created context checkpoint 1 of 32 (pos_min = 128, pos_max = 128, n_tokens = 129, size = 149.896 MiB)
2026-05-14 22:40:00.983 | ~llama_io_write_device: allocated 'CUDA0' buffer 149.625 MiB
2026-05-14 22:40:29.046 | slot print_timing: id  3 | task 0 | 
2026-05-14 22:40:29.046 | prompt eval time =     648.99 ms /   133 tokens (    4.88 ms per token,   204.94 tokens per second)
2026-05-14 22:40:29.046 |        eval time =   30387.12 ms /  2048 tokens (   14.84 ms per token,    67.40 tokens per second)
2026-05-14 22:40:29.046 |       total time =   31036.11 ms /  2181 tokens
2026-05-14 22:40:29.046 | draft acceptance rate = 0.98260 ( 1186 accepted /  1207 generated)
2026-05-14 22:40:29.046 | statistics mtp: #calls(b,g,a) = 1 861 690, #gen drafts = 690, #acc drafts = 690, #gen tokens = 1207, #acc tokens = 1186, dur(b,g,a) = 0.006, 3112.317, 0.287 ms
2026-05-14 22:40:29.046 | slot      release: id  3 | task 0 | stop processing: n_tokens = 2180, truncated = 0
2026-05-14 22:40:29.046 | srv  update_slots: all slots are idle
2026-05-14 22:40:29.051 | srv  log_server_r: done request: POST /v1/chat/completions 172.18.0.1 200
2026-05-14 22:40:42.201 | srv  params_from_: Chat format: peg-native
2026-05-14 22:40:42.203 | slot get_availabl: id  3 | task -1 | selected slot by LCP similarity, sim_best = 0.273 (> 0.100 thold), f_keep = 0.001
2026-05-14 22:40:42.203 | srv  get_availabl: updating prompt cache
2026-05-14 22:40:42.203 | srv   prompt_save:  - saving prompt with length 2180, total state size = 226.616 MiB (draft: 4.566 MiB)
2026-05-14 22:40:42.674 | srv          load:  - looking for better prompt, base f_keep = 0.001, sim = 0.273
2026-05-14 22:40:42.674 | srv        update:  - cache state: 1 prompts, 376.513 MiB (limits: 8192.000 MiB, 131072 tokens, 131072 est)
2026-05-14 22:40:42.674 | srv        update:    - prompt 0x63cea385af30:    2180 tokens, checkpoints:  1,   376.513 MiB
2026-05-14 22:40:42.674 | srv  get_availabl: prompt cache update took 471.03 ms
2026-05-14 22:40:42.674 | slot launch_slot_: id  3 | task -1 | sampler chain: logits -> penalties -> ?dry -> ?top-n-sigma -> top-k -> ?typical -> top-p -> min-p -> ?xtc -> ?temp-ext -> dist 
2026-05-14 22:40:42.674 | slot launch_slot_: id  3 | task 921 | processing task, is_child = 0
2026-05-14 22:40:42.674 | slot update_slots: id  3 | task 921 | new prompt, n_ctx_slot = 131072, n_keep = 0, task.n_tokens = 11
2026-05-14 22:40:42.674 | slot update_slots: id  3 | task 921 | n_past = 3, slot.prompt.tokens.size() = 2180, seq_id = 3, pos_min = 2179, n_swa = 0
2026-05-14 22:40:42.674 | slot update_slots: id  3 | task 921 | Checking checkpoint with [128, 128] against 3...
2026-05-14 22:40:42.674 | slot update_slots: id  3 | task 921 | forcing full prompt re-processing due to lack of cache data (likely due to SWA or hybrid/recurrent memory, see https://github.com/ggml-org/llama.cpp/pull/13194#issuecomment-2868343055)
2026-05-14 22:40:42.674 | slot update_slots: id  3 | task 921 | erased invalidated context checkpoint (pos_min = 128, pos_max = 128, n_tokens = 129, n_swa = 0, pos_next = 0, size = 149.896 MiB)
2026-05-14 22:40:42.684 | slot update_slots: id  3 | task 921 | n_tokens = 0, memory_seq_rm [0, end)
2026-05-14 22:40:42.684 | slot update_slots: id  3 | task 921 | prompt processing progress, n_tokens = 7, batch.n_tokens = 7, progress = 0.636364
2026-05-14 22:40:42.981 | slot update_slots: id  3 | task 921 | n_tokens = 7, memory_seq_rm [7, end)
2026-05-14 22:40:42.981 | slot init_sampler: id  3 | task 921 | init sampler, took 0.01 ms, tokens: text = 11, total = 11
2026-05-14 22:40:42.981 | slot update_slots: id  3 | task 921 | prompt processing done, n_tokens = 11, batch.n_tokens = 4
2026-05-14 22:40:43.119 | slot print_timing: id  3 | task 921 | 
2026-05-14 22:40:43.119 | prompt eval time =     339.88 ms /    11 tokens (   30.90 ms per token,    32.36 tokens per second)
2026-05-14 22:40:43.119 |        eval time =     104.28 ms /    10 tokens (   10.43 ms per token,    95.89 tokens per second)
2026-05-14 22:40:43.119 |       total time =     444.16 ms /    21 tokens
2026-05-14 22:40:43.119 | draft acceptance rate = 1.00000 (    6 accepted /     6 generated)
2026-05-14 22:40:43.119 | statistics mtp: #calls(b,g,a) = 2 864 693, #gen drafts = 693, #acc drafts = 693, #gen tokens = 1213, #acc tokens = 1192, dur(b,g,a) = 0.007, 3124.913, 0.287 ms
2026-05-14 22:40:43.119 | slot      release: id  3 | task 921 | stop processing: n_tokens = 20, truncated = 0
2026-05-14 22:40:43.119 | srv  update_slots: all slots are idle
2026-05-14 22:40:43.119 | srv  log_server_r: done request: POST /v1/chat/completions 172.18.0.1 200
2026-05-14 23:19:32.572 | srv  params_from_: Chat format: peg-native
2026-05-14 23:19:32.574 | slot get_availabl: id  2 | task -1 | selected slot by LRU, t_last = -1
2026-05-14 23:19:32.574 | srv  get_availabl: updating prompt cache
2026-05-14 23:19:32.574 | srv          load:  - looking for better prompt, base f_keep = -1.000, sim = 0.000
2026-05-14 23:19:32.574 | srv        update:  - cache state: 1 prompts, 376.513 MiB (limits: 8192.000 MiB, 131072 tokens, 131072 est)
2026-05-14 23:19:32.574 | srv        update:    - prompt 0x63cea385af30:    2180 tokens, checkpoints:  1,   376.513 MiB
2026-05-14 23:19:32.574 | srv  get_availabl: prompt cache update took 0.01 ms
2026-05-14 23:19:32.574 | slot launch_slot_: id  2 | task -1 | sampler chain: logits -> penalties -> ?dry -> ?top-n-sigma -> top-k -> ?typical -> top-p -> min-p -> ?xtc -> ?temp-ext -> dist 
2026-05-14 23:19:32.574 | slot launch_slot_: id  2 | task 927 | processing task, is_child = 0
2026-05-14 23:19:32.574 | slot slot_save_an: id  3 | task -1 | saving idle slot to prompt cache
2026-05-14 23:19:32.574 | srv   prompt_save:  - saving prompt with length 20, total state size = 150.333 MiB (draft: 0.042 MiB)
2026-05-14 23:19:32.801 | slot prompt_clear: id  3 | task -1 | clearing prompt with 20 tokens
2026-05-14 23:19:32.801 | srv        update:  - cache state: 2 prompts, 526.846 MiB (limits: 8192.000 MiB, 131072 tokens, 131072 est)
2026-05-14 23:19:32.801 | srv        update:    - prompt 0x63cea385af30:    2180 tokens, checkpoints:  1,   376.513 MiB
2026-05-14 23:19:32.801 | srv        update:    - prompt 0x63cea3373580:      20 tokens, checkpoints:  0,   150.333 MiB
2026-05-14 23:19:32.801 | slot update_slots: id  2 | task 927 | new prompt, n_ctx_slot = 131072, n_keep = 0, task.n_tokens = 133
2026-05-14 23:19:32.801 | slot update_slots: id  2 | task 927 | n_tokens = 0, memory_seq_rm [0, end)
2026-05-14 23:19:32.801 | slot update_slots: id  2 | task 927 | prompt processing progress, n_tokens = 129, batch.n_tokens = 129, progress = 0.969925
2026-05-14 23:19:32.990 | slot update_slots: id  2 | task 927 | n_tokens = 129, memory_seq_rm [129, end)
2026-05-14 23:19:32.990 | slot init_sampler: id  2 | task 927 | init sampler, took 0.03 ms, tokens: text = 133, total = 133
2026-05-14 23:19:32.990 | slot update_slots: id  2 | task 927 | prompt processing done, n_tokens = 133, batch.n_tokens = 4
2026-05-14 23:19:33.172 | slot create_check: id  2 | task 927 | created context checkpoint 1 of 32 (pos_min = 128, pos_max = 128, n_tokens = 129, size = 149.896 MiB)
2026-05-14 23:19:33.215 | ~llama_io_write_device: allocated 'CUDA0' buffer 149.625 MiB
2026-05-14 23:20:02.510 | slot print_timing: id  2 | task 927 | 
2026-05-14 23:20:02.510 | prompt eval time =     406.69 ms /   133 tokens (    3.06 ms per token,   327.03 tokens per second)
2026-05-14 23:20:02.510 |        eval time =   33916.97 ms /  2048 tokens (   16.56 ms per token,    60.38 tokens per second)
2026-05-14 23:20:02.510 |       total time =   34323.66 ms /  2181 tokens
2026-05-14 23:20:02.510 | draft acceptance rate = 0.98719 ( 1156 accepted /  1171 generated)
2026-05-14 23:20:02.510 | statistics mtp: #calls(b,g,a) = 3 1754 1381, #gen drafts = 1381, #acc drafts = 1381, #gen tokens = 2384, #acc tokens = 2348, dur(b,g,a) = 0.009, 6512.132, 0.625 ms
2026-05-14 23:20:02.510 | slot      release: id  2 | task 927 | stop processing: n_tokens = 2180, truncated = 0
2026-05-14 23:20:02.510 | srv  update_slots: all slots are idle
2026-05-14 23:20:02.510 | srv  log_server_r: done request: POST /v1/chat/completions 172.18.0.1 200
2026-05-14 23:32:48.050 | srv  params_from_: Chat format: peg-native
2026-05-14 23:32:48.052 | slot get_availabl: id  1 | task -1 | selected slot by LRU, t_last = -1
2026-05-14 23:32:48.052 | srv  get_availabl: updating prompt cache
2026-05-14 23:32:48.052 | srv          load:  - looking for better prompt, base f_keep = -1.000, sim = 0.000
2026-05-14 23:32:48.052 | srv        update:  - cache state: 2 prompts, 526.846 MiB (limits: 8192.000 MiB, 131072 tokens, 131072 est)
2026-05-14 23:32:48.052 | srv        update:    - prompt 0x63cea385af30:    2180 tokens, checkpoints:  1,   376.513 MiB
2026-05-14 23:32:48.052 | srv        update:    - prompt 0x63cea3373580:      20 tokens, checkpoints:  0,   150.333 MiB
2026-05-14 23:32:48.052 | srv  get_availabl: prompt cache update took 0.01 ms
2026-05-14 23:32:48.052 | slot launch_slot_: id  1 | task -1 | sampler chain: logits -> penalties -> ?dry -> ?top-n-sigma -> top-k -> ?typical -> ?top-p -> min-p -> ?xtc -> ?temp-ext -> dist 
2026-05-14 23:32:48.052 | slot launch_slot_: id  1 | task 1895 | processing task, is_child = 0
2026-05-14 23:32:48.052 | slot slot_save_an: id  2 | task -1 | saving idle slot to prompt cache
2026-05-14 23:32:48.053 | srv   prompt_save:  - saving prompt with length 2180, total state size = 226.616 MiB (draft: 4.566 MiB)
2026-05-14 23:32:48.245 | srv  params_from_: Chat format: peg-native
2026-05-14 23:32:48.563 | slot prompt_clear: id  2 | task -1 | clearing prompt with 2180 tokens
2026-05-14 23:32:48.564 | srv        update:  - cache state: 3 prompts, 903.358 MiB (limits: 8192.000 MiB, 131072 tokens, 131072 est)
2026-05-14 23:32:48.564 | srv        update:    - prompt 0x63cea385af30:    2180 tokens, checkpoints:  1,   376.513 MiB
2026-05-14 23:32:48.564 | srv        update:    - prompt 0x63cea3373580:      20 tokens, checkpoints:  0,   150.333 MiB
2026-05-14 23:32:48.564 | srv        update:    - prompt 0x63cea3b8e460:    2180 tokens, checkpoints:  1,   376.513 MiB
2026-05-14 23:32:48.564 | slot get_availabl: id  0 | task -1 | selected slot by LRU, t_last = -1
2026-05-14 23:32:48.564 | srv  get_availabl: updating prompt cache
2026-05-14 23:32:48.564 | srv          load:  - looking for better prompt, base f_keep = -1.000, sim = 0.000
2026-05-14 23:32:48.564 | srv        update:  - cache state: 3 prompts, 903.358 MiB (limits: 8192.000 MiB, 131072 tokens, 131072 est)
2026-05-14 23:32:48.564 | srv        update:    - prompt 0x63cea385af30:    2180 tokens, checkpoints:  1,   376.513 MiB
2026-05-14 23:32:48.564 | srv        update:    - prompt 0x63cea3373580:      20 tokens, checkpoints:  0,   150.333 MiB
2026-05-14 23:32:48.564 | srv        update:    - prompt 0x63cea3b8e460:    2180 tokens, checkpoints:  1,   376.513 MiB
2026-05-14 23:32:48.564 | srv  get_availabl: prompt cache update took 0.00 ms
2026-05-14 23:32:48.569 | reasoning-budget: activated, budget=2147483647 tokens
2026-05-14 23:32:48.569 | slot launch_slot_: id  0 | task -1 | sampler chain: logits -> penalties -> ?dry -> ?top-n-sigma -> top-k -> ?typical -> ?top-p -> min-p -> ?xtc -> ?temp-ext -> dist 
2026-05-14 23:32:48.569 | slot launch_slot_: id  0 | task 1896 | processing task, is_child = 0
2026-05-14 23:32:48.569 | slot update_slots: id  0 | task 1896 | new prompt, n_ctx_slot = 131072, n_keep = 0, task.n_tokens = 11756
2026-05-14 23:32:48.569 | slot update_slots: id  0 | task 1896 | n_tokens = 0, memory_seq_rm [0, end)
2026-05-14 23:32:48.569 | slot update_slots: id  0 | task 1896 | prompt processing progress, n_tokens = 2048, batch.n_tokens = 2048, progress = 0.174209
2026-05-14 23:32:51.928 | slot update_slots: id  0 | task 1896 | n_tokens = 2048, memory_seq_rm [2048, end)
2026-05-14 23:32:51.928 | slot update_slots: id  0 | task 1896 | prompt processing progress, n_tokens = 4096, batch.n_tokens = 2048, progress = 0.348418
2026-05-14 23:32:52.712 | slot update_slots: id  0 | task 1896 | n_tokens = 4096, memory_seq_rm [4096, end)
2026-05-14 23:32:52.712 | slot update_slots: id  0 | task 1896 | prompt processing progress, n_tokens = 6144, batch.n_tokens = 2048, progress = 0.522627
2026-05-14 23:32:53.500 | slot update_slots: id  0 | task 1896 | n_tokens = 6144, memory_seq_rm [6144, end)
2026-05-14 23:32:53.500 | slot update_slots: id  0 | task 1896 | prompt processing progress, n_tokens = 8192, batch.n_tokens = 2048, progress = 0.696836
2026-05-14 23:32:54.299 | slot update_slots: id  0 | task 1896 | n_tokens = 8192, memory_seq_rm [8192, end)
2026-05-14 23:32:54.299 | slot update_slots: id  0 | task 1896 | 8192 tokens since last checkpoint at 0, creating new checkpoint during processing at position 10240
2026-05-14 23:32:54.299 | slot update_slots: id  0 | task 1896 | prompt processing progress, n_tokens = 10240, batch.n_tokens = 2048, progress = 0.871045
2026-05-14 23:32:54.481 | slot create_check: id  0 | task 1896 | created context checkpoint 1 of 32 (pos_min = 8191, pos_max = 8191, n_tokens = 8192, size = 166.782 MiB)
2026-05-14 23:32:55.309 | slot update_slots: id  0 | task 1896 | n_tokens = 10240, memory_seq_rm [10240, end)
2026-05-14 23:32:55.309 | slot update_slots: id  0 | task 1896 | prompt processing progress, n_tokens = 11240, batch.n_tokens = 1000, progress = 0.956107
2026-05-14 23:32:55.309 | slot update_slots: id  1 | task 1895 | new prompt, n_ctx_slot = 131072, n_keep = 0, task.n_tokens = 867
2026-05-14 23:32:55.309 | slot update_slots: id  1 | task 1895 | n_tokens = 0, memory_seq_rm [0, end)
2026-05-14 23:32:55.309 | slot update_slots: id  1 | task 1895 | prompt processing progress, n_tokens = 351, batch.n_tokens = 1351, progress = 0.404844
2026-05-14 23:32:55.873 | slot update_slots: id  0 | task 1896 | n_tokens = 11240, memory_seq_rm [11240, end)
2026-05-14 23:32:55.873 | slot update_slots: id  0 | task 1896 | prompt processing progress, n_tokens = 11752, batch.n_tokens = 512, progress = 0.999660
2026-05-14 23:32:56.074 | slot create_check: id  0 | task 1896 | created context checkpoint 2 of 32 (pos_min = 11239, pos_max = 11239, n_tokens = 11240, size = 173.166 MiB)
2026-05-14 23:32:56.074 | slot update_slots: id  1 | task 1895 | n_tokens = 351, memory_seq_rm [351, end)
2026-05-14 23:32:56.074 | slot update_slots: id  1 | task 1895 | prompt processing progress, n_tokens = 863, batch.n_tokens = 1024, progress = 0.995386
2026-05-14 23:32:56.258 | slot create_check: id  1 | task 1895 | created context checkpoint 1 of 32 (pos_min = 350, pos_max = 350, n_tokens = 351, size = 150.361 MiB)
2026-05-14 23:32:56.669 | slot update_slots: id  0 | task 1896 | n_tokens = 11752, memory_seq_rm [11752, end)
2026-05-14 23:32:56.671 | slot init_sampler: id  0 | task 1896 | init sampler, took 1.82 ms, tokens: text = 11756, total = 11756
2026-05-14 23:32:56.671 | slot update_slots: id  0 | task 1896 | prompt processing done, n_tokens = 11756, batch.n_tokens = 4
2026-05-14 23:32:56.883 | slot create_check: id  0 | task 1896 | created context checkpoint 3 of 32 (pos_min = 11751, pos_max = 11751, n_tokens = 11752, size = 174.238 MiB)
2026-05-14 23:32:56.883 | slot update_slots: id  1 | task 1895 | n_tokens = 863, memory_seq_rm [863, end)
2026-05-14 23:32:56.883 | slot init_sampler: id  1 | task 1895 | init sampler, took 0.15 ms, tokens: text = 867, total = 867
2026-05-14 23:32:56.883 | slot update_slots: id  1 | task 1895 | prompt processing done, n_tokens = 867, batch.n_tokens = 8
2026-05-14 23:32:57.066 | slot create_check: id  1 | task 1895 | created context checkpoint 2 of 32 (pos_min = 862, pos_max = 862, n_tokens = 863, size = 151.434 MiB)
2026-05-14 23:32:57.141 | srv  log_server_r: done request: POST /v1/chat/completions 172.18.0.1 200
2026-05-14 23:32:57.144 | srv  log_server_r: done request: POST /v1/chat/completions 172.18.0.1 200
2026-05-14 23:32:57.156 | ~llama_io_write_device: allocated 'CUDA0' buffer 149.625 MiB
2026-05-14 23:32:57.163 | ~llama_io_write_device: allocated 'CUDA0' buffer 149.625 MiB
2026-05-14 23:32:58.279 | reasoning-budget: deactivated (natural end)
2026-05-14 23:32:58.673 | slot print_timing: id  0 | task 1896 | 
2026-05-14 23:32:58.673 | prompt eval time =    8571.75 ms / 11756 tokens (    0.73 ms per token,  1371.48 tokens per second)
2026-05-14 23:32:58.673 |        eval time =    1531.81 ms /    40 tokens (   38.30 ms per token,    26.11 tokens per second)
2026-05-14 23:32:58.673 |       total time =   10103.56 ms / 11796 tokens
2026-05-14 23:32:58.673 | draft acceptance rate = 1.00000 (   22 accepted /    22 generated)
2026-05-14 23:32:58.673 | statistics mtp: #calls(b,g,a) = 5 1773 1409, #gen drafts = 1410, #acc drafts = 1409, #gen tokens = 2435, #acc tokens = 2397, dur(b,g,a) = 0.013, 6620.238, 0.632 ms
2026-05-14 23:32:58.673 | slot      release: id  0 | task 1896 | stop processing: n_tokens = 11795, truncated = 0
2026-05-14 23:33:05.970 | slot print_timing: id  1 | task 1895 | 
2026-05-14 23:33:05.970 | prompt eval time =    1834.13 ms /   867 tokens (    2.12 ms per token,   472.70 tokens per second)
2026-05-14 23:33:05.970 |        eval time =   11132.61 ms /   565 tokens (   19.70 ms per token,    50.75 tokens per second)
2026-05-14 23:33:05.970 |       total time =   12966.73 ms /  1432 tokens
2026-05-14 23:33:05.970 | draft acceptance rate = 0.95570 (  302 accepted /   316 generated)
2026-05-14 23:33:05.970 | statistics mtp: #calls(b,g,a) = 5 2016 1581, #gen drafts = 1581, #acc drafts = 1581, #gen tokens = 2722, #acc tokens = 2672, dur(b,g,a) = 0.013, 7522.915, 0.722 ms
2026-05-14 23:33:05.970 | slot      release: id  1 | task 1895 | stop processing: n_tokens = 1431, truncated = 0
2026-05-14 23:33:05.970 | srv  update_slots: all slots are idle
2026-05-14 23:33:20.087 | srv  params_from_: Chat format: peg-native
2026-05-14 23:33:20.090 | slot get_availabl: id  0 | task -1 | selected slot by LCP similarity, sim_best = 0.969 (> 0.100 thold), f_keep = 0.970
2026-05-14 23:33:20.091 | reasoning-budget: activated, budget=2147483647 tokens
2026-05-14 23:33:20.091 | slot launch_slot_: id  0 | task -1 | sampler chain: logits -> penalties -> ?dry -> ?top-n-sigma -> top-k -> ?typical -> ?top-p -> min-p -> ?xtc -> ?temp-ext -> dist 
2026-05-14 23:33:20.091 | slot launch_slot_: id  0 | task 2193 | processing task, is_child = 0
2026-05-14 23:33:20.091 | slot slot_save_an: id  1 | task -1 | saving idle slot to prompt cache
2026-05-14 23:33:20.092 | srv   prompt_save:  - saving prompt with length 1431, total state size = 200.164 MiB (draft: 2.997 MiB)
2026-05-14 23:33:20.717 | slot prompt_clear: id  1 | task -1 | clearing prompt with 1431 tokens
2026-05-14 23:33:20.718 | srv        update:  - cache state: 4 prompts, 1405.318 MiB (limits: 8192.000 MiB, 131072 tokens, 131072 est)
2026-05-14 23:33:20.718 | srv        update:    - prompt 0x63cea385af30:    2180 tokens, checkpoints:  1,   376.513 MiB
2026-05-14 23:33:20.718 | srv        update:    - prompt 0x63cea3373580:      20 tokens, checkpoints:  0,   150.333 MiB
2026-05-14 23:33:20.718 | srv        update:    - prompt 0x63cea3b8e460:    2180 tokens, checkpoints:  1,   376.513 MiB
2026-05-14 23:33:20.718 | srv        update:    - prompt 0x63cea4cd88b0:    1431 tokens, checkpoints:  2,   501.959 MiB
2026-05-14 23:33:20.718 | slot update_slots: id  0 | task 2193 | new prompt, n_ctx_slot = 131072, n_keep = 0, task.n_tokens = 11801
2026-05-14 23:33:20.718 | slot update_slots: id  0 | task 2193 | n_past = 11441, slot.prompt.tokens.size() = 11795, seq_id = 0, pos_min = 11794, n_swa = 0
2026-05-14 23:33:20.718 | slot update_slots: id  0 | task 2193 | Checking checkpoint with [11751, 11751] against 11441...
2026-05-14 23:33:20.718 | slot update_slots: id  0 | task 2193 | Checking checkpoint with [11239, 11239] against 11441...
2026-05-14 23:33:20.787 | slot update_slots: id  0 | task 2193 | restored context checkpoint (pos_min = 11239, pos_max = 11239, n_tokens = 11240, n_past = 11240, size = 173.166 MiB)
2026-05-14 23:33:20.787 | slot update_slots: id  0 | task 2193 | erased invalidated context checkpoint (pos_min = 11751, pos_max = 11751, n_tokens = 11752, n_swa = 0, pos_next = 11240, size = 174.238 MiB)
2026-05-14 23:33:20.798 | slot update_slots: id  0 | task 2193 | n_tokens = 11240, memory_seq_rm [11240, end)
2026-05-14 23:33:20.798 | slot update_slots: id  0 | task 2193 | prompt processing progress, n_tokens = 11285, batch.n_tokens = 45, progress = 0.956275
2026-05-14 23:33:20.906 | slot update_slots: id  0 | task 2193 | n_tokens = 11285, memory_seq_rm [11285, end)
2026-05-14 23:33:20.906 | slot update_slots: id  0 | task 2193 | prompt processing progress, n_tokens = 11797, batch.n_tokens = 512, progress = 0.999661
2026-05-14 23:33:21.210 | slot update_slots: id  0 | task 2193 | n_tokens = 11797, memory_seq_rm [11797, end)
2026-05-14 23:33:21.212 | slot init_sampler: id  0 | task 2193 | init sampler, took 1.77 ms, tokens: text = 11801, total = 11801
2026-05-14 23:33:21.212 | slot update_slots: id  0 | task 2193 | prompt processing done, n_tokens = 11801, batch.n_tokens = 4
2026-05-14 23:33:21.351 | slot create_check: id  0 | task 2193 | created context checkpoint 3 of 32 (pos_min = 11796, pos_max = 11796, n_tokens = 11797, size = 174.332 MiB)
2026-05-14 23:33:21.387 | srv  log_server_r: done request: POST /v1/chat/completions 172.18.0.1 200
2026-05-14 23:33:24.800 | reasoning-budget: deactivated (natural end)
2026-05-14 23:33:26.248 | slot print_timing: id  0 | task 2193 | 
2026-05-14 23:33:26.248 | prompt eval time =     668.58 ms /   561 tokens (    1.19 ms per token,   839.09 tokens per second)
2026-05-14 23:33:26.248 |        eval time =    4860.92 ms /   262 tokens (   18.55 ms per token,    53.90 tokens per second)
2026-05-14 23:33:26.248 |       total time =    5529.50 ms /   823 tokens
2026-05-14 23:33:26.248 | draft acceptance rate = 0.99265 (  135 accepted /   136 generated)
2026-05-14 23:33:26.248 | statistics mtp: #calls(b,g,a) = 6 2142 1668, #gen drafts = 1668, #acc drafts = 1668, #gen tokens = 2858, #acc tokens = 2807, dur(b,g,a) = 0.014, 8014.150, 0.763 ms
2026-05-14 23:33:26.248 | slot      release: id  0 | task 2193 | stop processing: n_tokens = 12062, truncated = 0
2026-05-14 23:33:26.248 | srv  update_slots: all slots are idle
2026-05-14 23:34:19.495 | srv  params_from_: Chat format: peg-native
2026-05-14 23:34:19.498 | slot get_availabl: id  0 | task -1 | selected slot by LCP similarity, sim_best = 0.300 (> 0.100 thold), f_keep = 0.952
2026-05-14 23:34:19.499 | reasoning-budget: activated, budget=2147483647 tokens
2026-05-14 23:34:19.499 | slot launch_slot_: id  0 | task -1 | sampler chain: logits -> penalties -> ?dry -> ?top-n-sigma -> top-k -> ?typical -> ?top-p -> min-p -> ?xtc -> ?temp-ext -> dist 
2026-05-14 23:34:19.499 | slot launch_slot_: id  0 | task 2330 | processing task, is_child = 0
2026-05-14 23:34:19.499 | slot update_slots: id  0 | task 2330 | new prompt, n_ctx_slot = 131072, n_keep = 0, task.n_tokens = 38252
2026-05-14 23:34:19.499 | slot update_slots: id  0 | task 2330 | n_past = 11486, slot.prompt.tokens.size() = 12062, seq_id = 0, pos_min = 12061, n_swa = 0
2026-05-14 23:34:19.499 | slot update_slots: id  0 | task 2330 | Checking checkpoint with [11796, 11796] against 11486...
2026-05-14 23:34:19.499 | slot update_slots: id  0 | task 2330 | Checking checkpoint with [11239, 11239] against 11486...
2026-05-14 23:34:19.573 | slot update_slots: id  0 | task 2330 | restored context checkpoint (pos_min = 11239, pos_max = 11239, n_tokens = 11240, n_past = 11240, size = 173.166 MiB)
2026-05-14 23:34:19.573 | slot update_slots: id  0 | task 2330 | erased invalidated context checkpoint (pos_min = 11796, pos_max = 11796, n_tokens = 11797, n_swa = 0, pos_next = 11240, size = 174.332 MiB)
2026-05-14 23:34:19.584 | slot update_slots: id  0 | task 2330 | n_tokens = 11240, memory_seq_rm [11240, end)
2026-05-14 23:34:19.584 | slot update_slots: id  0 | task 2330 | prompt processing progress, n_tokens = 13288, batch.n_tokens = 2048, progress = 0.347381
2026-05-14 23:34:20.570 | slot update_slots: id  0 | task 2330 | n_tokens = 13288, memory_seq_rm [13288, end)
2026-05-14 23:34:20.570 | slot update_slots: id  0 | task 2330 | prompt processing progress, n_tokens = 15336, batch.n_tokens = 2048, progress = 0.400920
2026-05-14 23:34:21.419 | slot update_slots: id  0 | task 2330 | n_tokens = 15336, memory_seq_rm [15336, end)
2026-05-14 23:34:21.420 | slot update_slots: id  0 | task 2330 | prompt processing progress, n_tokens = 17384, batch.n_tokens = 2048, progress = 0.454460
2026-05-14 23:34:19.969 | slot update_slots: id  0 | task 2330 | n_tokens = 17384, memory_seq_rm [17384, end)
2026-05-14 23:34:19.969 | slot update_slots: id  0 | task 2330 | prompt processing progress, n_tokens = 19432, batch.n_tokens = 2048, progress = 0.508000
2026-05-14 23:34:20.836 | slot update_slots: id  0 | task 2330 | n_tokens = 19432, memory_seq_rm [19432, end)
2026-05-14 23:34:20.836 | slot update_slots: id  0 | task 2330 | 8192 tokens since last checkpoint at 11240, creating new checkpoint during processing at position 21480
2026-05-14 23:34:20.836 | slot update_slots: id  0 | task 2330 | prompt processing progress, n_tokens = 21480, batch.n_tokens = 2048, progress = 0.561539
2026-05-14 23:34:21.026 | slot create_check: id  0 | task 2330 | created context checkpoint 3 of 32 (pos_min = 19431, pos_max = 19431, n_tokens = 19432, size = 190.322 MiB)
2026-05-14 23:34:21.905 | slot update_slots: id  0 | task 2330 | n_tokens = 21480, memory_seq_rm [21480, end)
2026-05-14 23:34:21.905 | slot update_slots: id  0 | task 2330 | prompt processing progress, n_tokens = 23528, batch.n_tokens = 2048, progress = 0.615079
2026-05-14 23:34:22.801 | slot update_slots: id  0 | task 2330 | n_tokens = 23528, memory_seq_rm [23528, end)
2026-05-14 23:34:22.801 | slot update_slots: id  0 | task 2330 | prompt processing progress, n_tokens = 25576, batch.n_tokens = 2048, progress = 0.668619
2026-05-14 23:34:23.712 | slot update_slots: id  0 | task 2330 | n_tokens = 25576, memory_seq_rm [25576, end)
2026-05-14 23:34:23.712 | slot update_slots: id  0 | task 2330 | prompt processing progress, n_tokens = 27624, batch.n_tokens = 2048, progress = 0.722158
2026-05-14 23:34:24.645 | slot update_slots: id  0 | task 2330 | n_tokens = 27624, memory_seq_rm [27624, end)
2026-05-14 23:34:24.646 | slot update_slots: id  0 | task 2330 | 8192 tokens since last checkpoint at 19432, creating new checkpoint during processing at position 29672
2026-05-14 23:34:24.646 | slot update_slots: id  0 | task 2330 | prompt processing progress, n_tokens = 29672, batch.n_tokens = 2048, progress = 0.775698
2026-05-14 23:34:24.910 | slot create_check: id  0 | task 2330 | created context checkpoint 4 of 32 (pos_min = 27623, pos_max = 27623, n_tokens = 27624, size = 207.478 MiB)
2026-05-14 23:34:25.862 | slot update_slots: id  0 | task 2330 | n_tokens = 29672, memory_seq_rm [29672, end)
2026-05-14 23:34:25.862 | slot update_slots: id  0 | task 2330 | prompt processing progress, n_tokens = 31720, batch.n_tokens = 2048, progress = 0.829238
2026-05-14 23:34:26.837 | slot update_slots: id  0 | task 2330 | n_tokens = 31720, memory_seq_rm [31720, end)
2026-05-14 23:34:26.837 | slot update_slots: id  0 | task 2330 | prompt processing progress, n_tokens = 33768, batch.n_tokens = 2048, progress = 0.882777
2026-05-14 23:34:27.837 | slot update_slots: id  0 | task 2330 | n_tokens = 33768, memory_seq_rm [33768, end)
2026-05-14 23:34:27.837 | slot update_slots: id  0 | task 2330 | prompt processing progress, n_tokens = 35816, batch.n_tokens = 2048, progress = 0.936317
2026-05-14 23:34:28.860 | slot update_slots: id  0 | task 2330 | n_tokens = 35816, memory_seq_rm [35816, end)
2026-05-14 23:34:28.860 | slot update_slots: id  0 | task 2330 | 8192 tokens since last checkpoint at 27624, creating new checkpoint during processing at position 37736
2026-05-14 23:34:28.860 | slot update_slots: id  0 | task 2330 | prompt processing progress, n_tokens = 37736, batch.n_tokens = 1920, progress = 0.986511
2026-05-14 23:34:29.134 | slot create_check: id  0 | task 2330 | created context checkpoint 5 of 32 (pos_min = 35815, pos_max = 35815, n_tokens = 35816, size = 224.635 MiB)
2026-05-14 23:34:30.123 | slot update_slots: id  0 | task 2330 | n_tokens = 37736, memory_seq_rm [37736, end)
2026-05-14 23:34:30.123 | slot update_slots: id  0 | task 2330 | prompt processing progress, n_tokens = 38248, batch.n_tokens = 512, progress = 0.999895
2026-05-14 23:34:30.405 | slot create_check: id  0 | task 2330 | created context checkpoint 6 of 32 (pos_min = 37735, pos_max = 37735, n_tokens = 37736, size = 228.656 MiB)
2026-05-14 23:34:30.673 | slot update_slots: id  0 | task 2330 | n_tokens = 38248, memory_seq_rm [38248, end)
2026-05-14 23:34:30.678 | slot init_sampler: id  0 | task 2330 | init sampler, took 5.09 ms, tokens: text = 38252, total = 38252
2026-05-14 23:34:30.678 | slot update_slots: id  0 | task 2330 | prompt processing done, n_tokens = 38252, batch.n_tokens = 4
2026-05-14 23:34:30.961 | slot create_check: id  0 | task 2330 | created context checkpoint 7 of 32 (pos_min = 38247, pos_max = 38247, n_tokens = 38248, size = 229.728 MiB)
2026-05-14 23:34:31.005 | srv  log_server_r: done request: POST /v1/chat/completions 172.18.0.1 200
2026-05-14 23:35:26.392 | reasoning-budget: deactivated (natural end)
2026-05-14 23:35:37.675 | slot print_timing: id  0 | task 2330 | 
2026-05-14 23:35:37.675 | prompt eval time =   13812.00 ms / 27012 tokens (    0.51 ms per token,  1955.69 tokens per second)
2026-05-14 23:35:37.675 |        eval time =   71283.12 ms /  3235 tokens (   22.03 ms per token,    45.38 tokens per second)
2026-05-14 23:35:37.675 |       total time =   85095.12 ms / 30247 tokens
2026-05-14 23:35:37.675 | draft acceptance rate = 0.97598 ( 1544 accepted /  1582 generated)
2026-05-14 23:35:37.675 | statistics mtp: #calls(b,g,a) = 7 3832 2667, #gen drafts = 2667, #acc drafts = 2667, #gen tokens = 4440, #acc tokens = 4351, dur(b,g,a) = 0.016, 14603.773, 1.301 ms
2026-05-14 23:35:37.676 | slot      release: id  0 | task 2330 | stop processing: n_tokens = 41486, truncated = 0
2026-05-14 23:35:37.676 | srv  update_slots: all slots are idle
2026-05-14 23:37:08.234 | srv  params_from_: Chat format: peg-native
2026-05-14 23:37:08.237 | slot get_availabl: id  0 | task -1 | selected slot by LCP similarity, sim_best = 0.546 (> 0.100 thold), f_keep = 0.914
2026-05-14 23:37:08.238 | reasoning-budget: activated, budget=2147483647 tokens
2026-05-14 23:37:08.238 | slot launch_slot_: id  0 | task -1 | sampler chain: logits -> penalties -> ?dry -> ?top-n-sigma -> top-k -> ?typical -> ?top-p -> min-p -> ?xtc -> ?temp-ext -> dist 
2026-05-14 23:37:08.238 | slot launch_slot_: id  0 | task 4199 | processing task, is_child = 0
2026-05-14 23:37:08.238 | slot update_slots: id  0 | task 4199 | new prompt, n_ctx_slot = 131072, n_keep = 0, task.n_tokens = 69424
2026-05-14 23:37:08.238 | slot update_slots: id  0 | task 4199 | n_past = 37937, slot.prompt.tokens.size() = 41486, seq_id = 0, pos_min = 41485, n_swa = 0
2026-05-14 23:37:08.238 | slot update_slots: id  0 | task 4199 | Checking checkpoint with [38247, 38247] against 37937...
2026-05-14 23:37:08.238 | slot update_slots: id  0 | task 4199 | Checking checkpoint with [37735, 37735] against 37937...
2026-05-14 23:37:08.324 | slot update_slots: id  0 | task 4199 | restored context checkpoint (pos_min = 37735, pos_max = 37735, n_tokens = 37736, n_past = 37736, size = 228.656 MiB)
2026-05-14 23:37:08.324 | slot update_slots: id  0 | task 4199 | erased invalidated context checkpoint (pos_min = 38247, pos_max = 38247, n_tokens = 38248, n_swa = 0, pos_next = 37736, size = 229.728 MiB)
2026-05-14 23:37:08.339 | slot update_slots: id  0 | task 4199 | n_tokens = 37736, memory_seq_rm [37736, end)
2026-05-14 23:37:08.339 | slot update_slots: id  0 | task 4199 | prompt processing progress, n_tokens = 39784, batch.n_tokens = 2048, progress = 0.573058
2026-05-14 23:37:09.641 | slot update_slots: id  0 | task 4199 | n_tokens = 39784, memory_seq_rm [39784, end)
2026-05-14 23:37:09.641 | slot update_slots: id  0 | task 4199 | prompt processing progress, n_tokens = 41832, batch.n_tokens = 2048, progress = 0.602558
2026-05-14 23:37:10.741 | slot update_slots: id  0 | task 4199 | n_tokens = 41832, memory_seq_rm [41832, end)
2026-05-14 23:37:10.742 | slot update_slots: id  0 | task 4199 | prompt processing progress, n_tokens = 43880, batch.n_tokens = 2048, progress = 0.632058
2026-05-14 23:37:11.863 | slot update_slots: id  0 | task 4199 | n_tokens = 43880, memory_seq_rm [43880, end)
2026-05-14 23:37:11.863 | slot update_slots: id  0 | task 4199 | prompt processing progress, n_tokens = 45928, batch.n_tokens = 2048, progress = 0.661558
2026-05-14 23:37:13.011 | slot update_slots: id  0 | task 4199 | n_tokens = 45928, memory_seq_rm [45928, end)
2026-05-14 23:37:13.011 | slot update_slots: id  0 | task 4199 | 8192 tokens since last checkpoint at 37736, creating new checkpoint during processing at position 47976
2026-05-14 23:37:13.011 | slot update_slots: id  0 | task 4199 | prompt processing progress, n_tokens = 47976, batch.n_tokens = 2048, progress = 0.691058
2026-05-14 23:37:13.302 | slot create_check: id  0 | task 4199 | created context checkpoint 7 of 32 (pos_min = 45927, pos_max = 45927, n_tokens = 45928, size = 245.812 MiB)
2026-05-14 23:37:14.484 | slot update_slots: id  0 | task 4199 | n_tokens = 47976, memory_seq_rm [47976, end)
2026-05-14 23:37:14.484 | slot update_slots: id  0 | task 4199 | prompt processing progress, n_tokens = 50024, batch.n_tokens = 2048, progress = 0.720558
2026-05-14 23:37:15.697 | slot update_slots: id  0 | task 4199 | n_tokens = 50024, memory_seq_rm [50024, end)
2026-05-14 23:37:15.697 | slot update_slots: id  0 | task 4199 | prompt processing progress, n_tokens = 52072, batch.n_tokens = 2048, progress = 0.750058
2026-05-14 23:37:16.939 | slot update_slots: id  0 | task 4199 | n_tokens = 52072, memory_seq_rm [52072, end)
2026-05-14 23:37:16.939 | slot update_slots: id  0 | task 4199 | prompt processing progress, n_tokens = 54120, batch.n_tokens = 2048, progress = 0.779558
2026-05-14 23:37:18.209 | slot update_slots: id  0 | task 4199 | n_tokens = 54120, memory_seq_rm [54120, end)
2026-05-14 23:37:18.209 | slot update_slots: id  0 | task 4199 | 8192 tokens since last checkpoint at 45928, creating new checkpoint during processing at position 56168
2026-05-14 23:37:18.209 | slot update_slots: id  0 | task 4199 | prompt processing progress, n_tokens = 56168, batch.n_tokens = 2048, progress = 0.809057
2026-05-14 23:37:18.537 | slot create_check: id  0 | task 4199 | created context checkpoint 8 of 32 (pos_min = 54119, pos_max = 54119, n_tokens = 54120, size = 262.968 MiB)
2026-05-14 23:37:19.835 | slot update_slots: id  0 | task 4199 | n_tokens = 56168, memory_seq_rm [56168, end)
2026-05-14 23:37:19.835 | slot update_slots: id  0 | task 4199 | prompt processing progress, n_tokens = 58216, batch.n_tokens = 2048, progress = 0.838557
2026-05-14 23:37:21.153 | slot update_slots: id  0 | task 4199 | n_tokens = 58216, memory_seq_rm [58216, end)
2026-05-14 23:37:21.153 | slot update_slots: id  0 | task 4199 | prompt processing progress, n_tokens = 60264, batch.n_tokens = 2048, progress = 0.868057
2026-05-14 23:37:22.528 | slot update_slots: id  0 | task 4199 | n_tokens = 60264, memory_seq_rm [60264, end)
2026-05-14 23:37:22.528 | slot update_slots: id  0 | task 4199 | prompt processing progress, n_tokens = 62312, batch.n_tokens = 2048, progress = 0.897557
2026-05-14 23:37:23.931 | slot update_slots: id  0 | task 4199 | n_tokens = 62312, memory_seq_rm [62312, end)
2026-05-14 23:37:23.931 | slot update_slots: id  0 | task 4199 | 8192 tokens since last checkpoint at 54120, creating new checkpoint during processing at position 64360
2026-05-14 23:37:23.935 | slot update_slots: id  0 | task 4199 | prompt processing progress, n_tokens = 64360, batch.n_tokens = 2048, progress = 0.927057
2026-05-14 23:37:24.282 | slot create_check: id  0 | task 4199 | created context checkpoint 9 of 32 (pos_min = 62311, pos_max = 62311, n_tokens = 62312, size = 280.124 MiB)
2026-05-14 23:37:25.716 | slot update_slots: id  0 | task 4199 | n_tokens = 64360, memory_seq_rm [64360, end)
2026-05-14 23:37:25.716 | slot update_slots: id  0 | task 4199 | prompt processing progress, n_tokens = 66408, batch.n_tokens = 2048, progress = 0.956557
2026-05-14 23:37:27.187 | slot update_slots: id  0 | task 4199 | n_tokens = 66408, memory_seq_rm [66408, end)
2026-05-14 23:37:27.188 | slot update_slots: id  0 | task 4199 | prompt processing progress, n_tokens = 68456, batch.n_tokens = 2048, progress = 0.986057
2026-05-14 23:37:28.684 | slot update_slots: id  0 | task 4199 | n_tokens = 68456, memory_seq_rm [68456, end)
2026-05-14 23:37:28.684 | slot update_slots: id  0 | task 4199 | prompt processing progress, n_tokens = 68908, batch.n_tokens = 452, progress = 0.992567
2026-05-14 23:37:29.048 | slot update_slots: id  0 | task 4199 | n_tokens = 68908, memory_seq_rm [68908, end)
2026-05-14 23:37:29.049 | slot update_slots: id  0 | task 4199 | prompt processing progress, n_tokens = 69420, batch.n_tokens = 512, progress = 0.999942
2026-05-14 23:37:29.409 | slot create_check: id  0 | task 4199 | created context checkpoint 10 of 32 (pos_min = 68907, pos_max = 68907, n_tokens = 68908, size = 293.938 MiB)
2026-05-14 23:37:29.795 | slot update_slots: id  0 | task 4199 | n_tokens = 69420, memory_seq_rm [69420, end)
2026-05-14 23:37:29.804 | slot init_sampler: id  0 | task 4199 | init sampler, took 8.75 ms, tokens: text = 69424, total = 69424
2026-05-14 23:37:29.804 | slot update_slots: id  0 | task 4199 | prompt processing done, n_tokens = 69424, batch.n_tokens = 4
2026-05-14 23:37:30.166 | slot create_check: id  0 | task 4199 | created context checkpoint 11 of 32 (pos_min = 69419, pos_max = 69419, n_tokens = 69420, size = 295.010 MiB)
2026-05-14 23:37:30.216 | srv  log_server_r: done request: POST /v1/chat/completions 172.18.0.1 200
2026-05-14 23:37:52.332 | reasoning-budget: deactivated (natural end)
2026-05-14 23:38:06.823 | slot print_timing: id  0 | task 4199 | 
2026-05-14 23:38:06.823 | prompt eval time =   21977.55 ms / 31688 tokens (    0.69 ms per token,  1441.83 tokens per second)
2026-05-14 23:38:06.823 |        eval time =   41220.05 ms /  2141 tokens (   19.25 ms per token,    51.94 tokens per second)
2026-05-14 23:38:06.823 |       total time =   63197.60 ms / 33829 tokens
2026-05-14 23:38:06.823 | draft acceptance rate = 0.99020 ( 1213 accepted /  1225 generated)
2026-05-14 23:38:06.823 | statistics mtp: #calls(b,g,a) = 8 4759 3355, #gen drafts = 3355, #acc drafts = 3355, #gen tokens = 5665, #acc tokens = 5564, dur(b,g,a) = 0.018, 18899.773, 1.686 ms
2026-05-14 23:38:06.825 | slot      release: id  0 | task 4199 | stop processing: n_tokens = 71564, truncated = 0
2026-05-14 23:38:06.825 | srv  update_slots: all slots are idle
2026-05-14 23:39:36.447 | srv  params_from_: Chat format: peg-native
2026-05-14 23:39:36.450 | slot get_availabl: id  0 | task -1 | selected slot by LCP similarity, sim_best = 0.986 (> 0.100 thold), f_keep = 0.966
2026-05-14 23:39:36.451 | reasoning-budget: activated, budget=2147483647 tokens
2026-05-14 23:39:36.452 | slot launch_slot_: id  0 | task -1 | sampler chain: logits -> penalties -> ?dry -> ?top-n-sigma -> top-k -> ?typical -> ?top-p -> min-p -> ?xtc -> ?temp-ext -> dist 
2026-05-14 23:39:36.452 | slot launch_slot_: id  0 | task 5199 | processing task, is_child = 0
2026-05-14 23:39:36.452 | slot update_slots: id  0 | task 5199 | new prompt, n_ctx_slot = 131072, n_keep = 0, task.n_tokens = 70071
2026-05-14 23:39:36.452 | slot update_slots: id  0 | task 5199 | n_past = 69109, slot.prompt.tokens.size() = 71564, seq_id = 0, pos_min = 71563, n_swa = 0
2026-05-14 23:39:36.452 | slot update_slots: id  0 | task 5199 | Checking checkpoint with [69419, 69419] against 69109...
2026-05-14 23:39:36.452 | slot update_slots: id  0 | task 5199 | Checking checkpoint with [68907, 68907] against 69109...
2026-05-14 23:39:36.577 | slot update_slots: id  0 | task 5199 | restored context checkpoint (pos_min = 68907, pos_max = 68907, n_tokens = 68908, n_past = 68908, size = 293.938 MiB)
2026-05-14 23:39:36.577 | slot update_slots: id  0 | task 5199 | erased invalidated context checkpoint (pos_min = 69419, pos_max = 69419, n_tokens = 69420, n_swa = 0, pos_next = 68908, size = 295.010 MiB)
2026-05-14 23:39:36.595 | slot update_slots: id  0 | task 5199 | n_tokens = 68908, memory_seq_rm [68908, end)
2026-05-14 23:39:36.596 | slot update_slots: id  0 | task 5199 | prompt processing progress, n_tokens = 69555, batch.n_tokens = 647, progress = 0.992636
2026-05-14 23:39:37.231 | slot update_slots: id  0 | task 5199 | n_tokens = 69555, memory_seq_rm [69555, end)
2026-05-14 23:39:37.231 | slot update_slots: id  0 | task 5199 | prompt processing progress, n_tokens = 70067, batch.n_tokens = 512, progress = 0.999943
2026-05-14 23:39:37.482 | slot create_check: id  0 | task 5199 | created context checkpoint 11 of 32 (pos_min = 69554, pos_max = 69554, n_tokens = 69555, size = 295.293 MiB)
2026-05-14 23:39:37.869 | slot update_slots: id  0 | task 5199 | n_tokens = 70067, memory_seq_rm [70067, end)
2026-05-14 23:39:37.878 | slot init_sampler: id  0 | task 5199 | init sampler, took 8.91 ms, tokens: text = 70071, total = 70071
2026-05-14 23:39:37.878 | slot update_slots: id  0 | task 5199 | prompt processing done, n_tokens = 70071, batch.n_tokens = 4
2026-05-14 23:39:38.213 | slot create_check: id  0 | task 5199 | created context checkpoint 12 of 32 (pos_min = 70066, pos_max = 70066, n_tokens = 70067, size = 296.365 MiB)
2026-05-14 23:39:38.261 | srv  log_server_r: done request: POST /v1/chat/completions 172.18.0.1 200
2026-05-14 23:39:39.129 | reasoning-budget: deactivated (natural end)
2026-05-14 23:40:17.212 | slot print_timing: id  0 | task 5199 | 
2026-05-14 23:40:17.212 | prompt eval time =    1808.99 ms /  1163 tokens (    1.56 ms per token,   642.90 tokens per second)
2026-05-14 23:40:17.212 |        eval time =   41258.54 ms /  2229 tokens (   18.51 ms per token,    54.03 tokens per second)
2026-05-14 23:40:17.212 |       total time =   43067.53 ms /  3392 tokens
2026-05-14 23:40:17.212 | draft acceptance rate = 0.98289 ( 1321 accepted /  1344 generated)
2026-05-14 23:40:17.212 | statistics mtp: #calls(b,g,a) = 9 5666 4097, #gen drafts = 4097, #acc drafts = 4097, #gen tokens = 7009, #acc tokens = 6885, dur(b,g,a) = 0.019, 23179.172, 2.087 ms
2026-05-14 23:40:17.214 | slot      release: id  0 | task 5199 | stop processing: n_tokens = 72299, truncated = 0
2026-05-14 23:40:17.214 | srv  update_slots: all slots are idle
2026-05-14 23:40:17.507 | srv  params_from_: Chat format: peg-native
2026-05-14 23:40:17.510 | slot get_availabl: id  0 | task -1 | selected slot by LCP similarity, sim_best = 1.000 (> 0.100 thold), f_keep = 1.000
2026-05-14 23:40:17.512 | reasoning-budget: activated, budget=2147483647 tokens
2026-05-14 23:40:17.512 | slot launch_slot_: id  0 | task -1 | sampler chain: logits -> penalties -> ?dry -> ?top-n-sigma -> top-k -> ?typical -> ?top-p -> min-p -> ?xtc -> ?temp-ext -> dist 
2026-05-14 23:40:17.512 | slot launch_slot_: id  0 | task 6173 | processing task, is_child = 0
2026-05-14 23:40:17.512 | slot update_slots: id  0 | task 6173 | new prompt, n_ctx_slot = 131072, n_keep = 0, task.n_tokens = 72320
2026-05-14 23:40:17.512 | slot update_slots: id  0 | task 6173 | n_tokens = 72299, memory_seq_rm [72299, end)
2026-05-14 23:40:17.512 | slot update_slots: id  0 | task 6173 | prompt processing progress, n_tokens = 72316, batch.n_tokens = 17, progress = 0.999945
2026-05-14 23:40:17.886 | slot create_check: id  0 | task 6173 | created context checkpoint 13 of 32 (pos_min = 72298, pos_max = 72298, n_tokens = 72299, size = 301.040 MiB)
2026-05-14 23:40:17.949 | slot update_slots: id  0 | task 6173 | n_tokens = 72316, memory_seq_rm [72316, end)
2026-05-14 23:40:17.958 | slot init_sampler: id  0 | task 6173 | init sampler, took 9.32 ms, tokens: text = 72320, total = 72320
2026-05-14 23:40:17.958 | slot update_slots: id  0 | task 6173 | prompt processing done, n_tokens = 72320, batch.n_tokens = 4
2026-05-14 23:40:18.003 | srv  log_server_r: done request: POST /v1/chat/completions 172.18.0.1 200
2026-05-14 23:40:18.446 | reasoning-budget: deactivated (natural end)
2026-05-14 23:40:18.817 | slot print_timing: id  0 | task 6173 | 
2026-05-14 23:40:18.817 | prompt eval time =     491.09 ms /    21 tokens (   23.39 ms per token,    42.76 tokens per second)
2026-05-14 23:40:18.817 |        eval time =     813.86 ms /    42 tokens (   19.38 ms per token,    51.61 tokens per second)
2026-05-14 23:40:18.817 |       total time =    1304.95 ms /    63 tokens
2026-05-14 23:40:18.817 | draft acceptance rate = 1.00000 (   25 accepted /    25 generated)
2026-05-14 23:40:18.817 | statistics mtp: #calls(b,g,a) = 10 5682 4111, #gen drafts = 4111, #acc drafts = 4111, #gen tokens = 7034, #acc tokens = 6910, dur(b,g,a) = 0.021, 23261.659, 2.095 ms
2026-05-14 23:40:18.819 | slot      release: id  0 | task 6173 | stop processing: n_tokens = 72361, truncated = 0
2026-05-14 23:40:18.819 | srv  update_slots: all slots are idle
2026-05-14 23:56:42.768 | srv    operator(): operator(): cleaning up before exit...
2026-05-14 23:56:42.771 | common_memory_breakdown_print: | memory breakdown [MiB] | total   free     self   model   context   compute    unaccounted |
2026-05-14 23:56:42.771 | common_memory_breakdown_print: |   - CUDA0 (RTX 5090)   | 32606 = 4837 + (21832 = 16386 +    4950 +     495) +        5936 |
2026-05-14 23:56:42.771 | common_memory_breakdown_print: |   - Host               |                   958 =   682 +       0 +     276                |
2026-05-15 09:03:51.958 | ggml_cuda_init: found 1 CUDA devices (Total VRAM: 32606 MiB):
2026-05-15 09:03:51.959 |   Device 0: NVIDIA GeForce RTX 5090, compute capability 12.0, VMM: yes, VRAM: 32606 MiB
2026-05-15 09:03:51.959 | load_backend: loaded CUDA backend from /app/libggml-cuda.so
2026-05-15 09:03:51.990 | load_backend: loaded CPU backend from /app/libggml-cpu-haswell.so
2026-05-15 09:03:51.990 | warn: LLAMA_ARG_HOST environment variable is set, but will be overwritten by command line argument --host
2026-05-15 09:03:52.168 | common_download_file_single_online: HEAD failed, status: 404
2026-05-15 09:03:52.169 | no remote preset found, skipping
2026-05-15 09:03:52.476 | main: n_parallel is set to auto, using n_parallel = 4 and kv_unified = true
2026-05-15 09:03:52.476 | build_info: b484-2c4055912
2026-05-15 09:03:52.477 | system_info: n_threads = 16 (n_threads_batch = 16) / 32 | CUDA : ARCHS = 750,800,860,890,1200,1210 | USE_GRAPHS = 1 | PEER_MAX_BATCH_SIZE = 128 | BLACKWELL_NATIVE_FP4 = 1 | CPU : SSE3 = 1 | SSSE3 = 1 | AVX = 1 | AVX2 = 1 | F16C = 1 | FMA = 1 | BMI2 = 1 | LLAMAFILE = 1 | OPENMP = 1 | REPACK = 1 | 
2026-05-15 09:03:52.477 | Running without SSL
2026-05-15 09:03:52.477 | init: using 31 threads for HTTP server
2026-05-15 09:03:52.477 | start: binding port with default address family
2026-05-15 09:03:52.479 | main: loading model
2026-05-15 09:03:52.479 | srv    load_model: loading model '/root/.cache/huggingface/hub/models--unsloth--Qwen3.6-27B-MTP-GGUF/snapshots/296162df313e8eebe1e15a00d60b3f8f33962e18/Qwen3.6-27B-UD-Q4_K_XL.gguf'
2026-05-15 09:03:52.480 | common_init_result: fitting params to device memory, for bugs during this step try to reproduce them with -fit off, or provide --verbose logs if the bug only occurs with -fit on
2026-05-15 09:03:52.480 | common_params_fit_impl: getting device memory data for initial parameters:
2026-05-15 09:03:53.189 | common_memory_breakdown_print: | memory breakdown [MiB] | total    free     self   model   context   compute    unaccounted |
2026-05-15 09:03:53.189 | common_memory_breakdown_print: |   - CUDA0 (RTX 5090)   | 32606 = 30330 + (21832 = 16386 +    4950 +     495) +      -19555 |
2026-05-15 09:03:53.189 | common_memory_breakdown_print: |   - Host               |                    958 =   682 +       0 +     276                |
2026-05-15 09:03:53.232 | common_params_fit_impl: projected to use 21832 MiB of device memory vs. 30330 MiB of free device memory
2026-05-15 09:03:53.232 | common_params_fit_impl: will leave 8497 >= 1024 MiB of free device memory, no changes needed
2026-05-15 09:03:53.232 | common_fit_params: successfully fit params to free device memory
2026-05-15 09:03:53.232 | common_fit_params: fitting params to free memory took 0.75 seconds
2026-05-15 09:03:53.263 | llama_model_loader: loaded meta data with 52 key-value pairs and 866 tensors from /root/.cache/huggingface/hub/models--unsloth--Qwen3.6-27B-MTP-GGUF/snapshots/296162df313e8eebe1e15a00d60b3f8f33962e18/Qwen3.6-27B-UD-Q4_K_XL.gguf (version GGUF V3 (latest))
2026-05-15 09:03:53.263 | llama_model_loader: Dumping metadata keys/values. Note: KV overrides do not apply in this output.
2026-05-15 09:03:53.263 | llama_model_loader: - kv   0:                       general.architecture str              = qwen35
2026-05-15 09:03:53.263 | llama_model_loader: - kv   1:                               general.type str              = model
2026-05-15 09:03:53.263 | llama_model_loader: - kv   2:                     general.sampling.top_k i32              = 20
2026-05-15 09:03:53.263 | llama_model_loader: - kv   3:                     general.sampling.top_p f32              = 0.950000
2026-05-15 09:03:53.263 | llama_model_loader: - kv   4:                      general.sampling.temp f32              = 1.000000
2026-05-15 09:03:53.263 | llama_model_loader: - kv   5:                               general.name str              = Qwen3.6-27B
2026-05-15 09:03:53.263 | llama_model_loader: - kv   6:                           general.basename str              = Qwen3.6-27B
2026-05-15 09:03:53.263 | llama_model_loader: - kv   7:                       general.quantized_by str              = Unsloth
2026-05-15 09:03:53.263 | llama_model_loader: - kv   8:                         general.size_label str              = 27B
2026-05-15 09:03:53.263 | llama_model_loader: - kv   9:                            general.license str              = apache-2.0
2026-05-15 09:03:53.263 | llama_model_loader: - kv  10:                       general.license.link str              = https://huggingface.co/Qwen/Qwen3.6-2...
2026-05-15 09:03:53.263 | llama_model_loader: - kv  11:                           general.repo_url str              = https://huggingface.co/unsloth
2026-05-15 09:03:53.263 | llama_model_loader: - kv  12:                   general.base_model.count u32              = 1
2026-05-15 09:03:53.263 | llama_model_loader: - kv  13:                  general.base_model.0.name str              = Qwen3.6 27B
2026-05-15 09:03:53.263 | llama_model_loader: - kv  14:          general.base_model.0.organization str              = Qwen
2026-05-15 09:03:53.263 | llama_model_loader: - kv  15:              general.base_model.0.repo_url str              = https://huggingface.co/Qwen/Qwen3.6-27B
2026-05-15 09:03:53.263 | llama_model_loader: - kv  16:                               general.tags arr[str,2]       = ["unsloth", "image-text-to-text"]
2026-05-15 09:03:53.263 | llama_model_loader: - kv  17:                         qwen35.block_count u32              = 65
2026-05-15 09:03:53.263 | llama_model_loader: - kv  18:                      qwen35.context_length u32              = 262144
2026-05-15 09:03:53.263 | llama_model_loader: - kv  19:                    qwen35.embedding_length u32              = 5120
2026-05-15 09:03:53.263 | llama_model_loader: - kv  20:                 qwen35.feed_forward_length u32              = 17408
2026-05-15 09:03:53.263 | llama_model_loader: - kv  21:                qwen35.attention.head_count u32              = 24
2026-05-15 09:03:53.263 | llama_model_loader: - kv  22:             qwen35.attention.head_count_kv u32              = 4
2026-05-15 09:03:53.263 | llama_model_loader: - kv  23:             qwen35.rope.dimension_sections arr[i32,4]       = [11, 11, 10, 0]
2026-05-15 09:03:53.263 | llama_model_loader: - kv  24:                      qwen35.rope.freq_base f32              = 10000000.000000
2026-05-15 09:03:53.263 | llama_model_loader: - kv  25:    qwen35.attention.layer_norm_rms_epsilon f32              = 0.000001
2026-05-15 09:03:53.263 | llama_model_loader: - kv  26:                qwen35.attention.key_length u32              = 256
2026-05-15 09:03:53.263 | llama_model_loader: - kv  27:              qwen35.attention.value_length u32              = 256
2026-05-15 09:03:53.263 | llama_model_loader: - kv  28:                     qwen35.ssm.conv_kernel u32              = 4
2026-05-15 09:03:53.263 | llama_model_loader: - kv  29:                      qwen35.ssm.state_size u32              = 128
2026-05-15 09:03:53.263 | llama_model_loader: - kv  30:                     qwen35.ssm.group_count u32              = 16
2026-05-15 09:03:53.263 | llama_model_loader: - kv  31:                  qwen35.ssm.time_step_rank u32              = 48
2026-05-15 09:03:53.263 | llama_model_loader: - kv  32:                      qwen35.ssm.inner_size u32              = 6144
2026-05-15 09:03:53.263 | llama_model_loader: - kv  33:             qwen35.full_attention_interval u32              = 4
2026-05-15 09:03:53.263 | llama_model_loader: - kv  34:                qwen35.rope.dimension_count u32              = 64
2026-05-15 09:03:53.263 | llama_model_loader: - kv  35:                qwen35.nextn_predict_layers u32              = 1
2026-05-15 09:03:53.263 | llama_model_loader: - kv  36:                       tokenizer.ggml.model str              = gpt2
2026-05-15 09:03:53.263 | llama_model_loader: - kv  37:                         tokenizer.ggml.pre str              = qwen35
2026-05-15 09:03:53.280 | llama_model_loader: - kv  38:                      tokenizer.ggml.tokens arr[str,248320]  = ["!", "\"", "#", "$", "%", "&", "'", ...
2026-05-15 09:03:53.285 | llama_model_loader: - kv  39:                  tokenizer.ggml.token_type arr[i32,248320]  = [1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, ...
2026-05-15 09:03:53.303 | llama_model_loader: - kv  40:                      tokenizer.ggml.merges arr[str,247587]  = ["Ġ Ġ", "ĠĠ ĠĠ", "i n", "Ġ t",...
2026-05-15 09:03:53.303 | llama_model_loader: - kv  41:                tokenizer.ggml.eos_token_id u32              = 248046
2026-05-15 09:03:53.303 | llama_model_loader: - kv  42:            tokenizer.ggml.padding_token_id u32              = 248055
2026-05-15 09:03:53.303 | llama_model_loader: - kv  43:                tokenizer.ggml.bos_token_id u32              = 248044
2026-05-15 09:03:53.303 | llama_model_loader: - kv  44:               tokenizer.ggml.add_bos_token bool             = false
2026-05-15 09:03:53.303 | llama_model_loader: - kv  45:                    tokenizer.chat_template str              = {%- set image_count = namespace(value...
2026-05-15 09:03:53.303 | llama_model_loader: - kv  46:               general.quantization_version u32              = 2
2026-05-15 09:03:53.303 | llama_model_loader: - kv  47:                          general.file_type u32              = 15
2026-05-15 09:03:53.303 | llama_model_loader: - kv  48:                      quantize.imatrix.file str              = Qwen3.6-27B-GGUF/imatrix_unsloth.gguf
2026-05-15 09:03:53.303 | llama_model_loader: - kv  49:                   quantize.imatrix.dataset str              = unsloth_calibration_Qwen3.6-27B.txt
2026-05-15 09:03:53.303 | llama_model_loader: - kv  50:             quantize.imatrix.entries_count u32              = 496
2026-05-15 09:03:53.303 | llama_model_loader: - kv  51:              quantize.imatrix.chunks_count u32              = 76
2026-05-15 09:03:53.303 | llama_model_loader: - type  f32:  456 tensors
2026-05-15 09:03:53.303 | llama_model_loader: - type q8_0:   49 tensors
2026-05-15 09:03:53.303 | llama_model_loader: - type q4_K:  225 tensors
2026-05-15 09:03:53.303 | llama_model_loader: - type q5_K:   70 tensors
2026-05-15 09:03:53.303 | llama_model_loader: - type q6_K:   66 tensors
2026-05-15 09:03:53.303 | print_info: file format = GGUF V3 (latest)
2026-05-15 09:03:53.303 | print_info: file type   = Q4_K - Medium
2026-05-15 09:03:53.303 | print_info: file size   = 16.67 GiB (5.24 BPW) 
2026-05-15 09:03:53.303 | llama_prepare_model_devices: using device CUDA0 (NVIDIA GeForce RTX 5090) (0000:0b:00.0) - 30930 MiB free
2026-05-15 09:03:53.393 | load: 0 unused tokens
2026-05-15 09:03:53.421 | load: printing all EOG tokens:
2026-05-15 09:03:53.421 | load:   - 248044 ('<|endoftext|>')
2026-05-15 09:03:53.421 | load:   - 248046 ('<|im_end|>')
2026-05-15 09:03:53.421 | load:   - 248063 ('<|fim_pad|>')
2026-05-15 09:03:53.421 | load:   - 248064 ('<|repo_name|>')
2026-05-15 09:03:53.421 | load:   - 248065 ('<|file_sep|>')
2026-05-15 09:03:53.422 | load: special tokens cache size = 33
2026-05-15 09:03:53.485 | load: token to piece cache size = 1.7581 MB
2026-05-15 09:03:53.485 | print_info: arch                  = qwen35
2026-05-15 09:03:53.485 | print_info: vocab_only            = 0
2026-05-15 09:03:53.485 | print_info: no_alloc              = 0
2026-05-15 09:03:53.485 | print_info: n_ctx_train           = 262144
2026-05-15 09:03:53.485 | print_info: n_embd                = 5120
2026-05-15 09:03:53.485 | print_info: n_embd_inp            = 5120
2026-05-15 09:03:53.485 | print_info: n_layer               = 65
2026-05-15 09:03:53.485 | print_info: n_head                = 24
2026-05-15 09:03:53.485 | print_info: n_head_kv             = 4
2026-05-15 09:03:53.485 | print_info: n_rot                 = 64
2026-05-15 09:03:53.485 | print_info: n_swa                 = 0
2026-05-15 09:03:53.485 | print_info: is_swa_any            = 0
2026-05-15 09:03:53.485 | print_info: n_embd_head_k         = 256
2026-05-15 09:03:53.485 | print_info: n_embd_head_v         = 256
2026-05-15 09:03:53.485 | print_info: n_gqa                 = 6
2026-05-15 09:03:53.485 | print_info: n_embd_k_gqa          = 1024
2026-05-15 09:03:53.485 | print_info: n_embd_v_gqa          = 1024
2026-05-15 09:03:53.485 | print_info: f_norm_eps            = 0.0e+00
2026-05-15 09:03:53.485 | print_info: f_norm_rms_eps        = 1.0e-06
2026-05-15 09:03:53.485 | print_info: f_clamp_kqv           = 0.0e+00
2026-05-15 09:03:53.485 | print_info: f_max_alibi_bias      = 0.0e+00
2026-05-15 09:03:53.485 | print_info: f_logit_scale         = 0.0e+00
2026-05-15 09:03:53.485 | print_info: f_attn_scale          = 0.0e+00
2026-05-15 09:03:53.485 | print_info: f_attn_value_scale    = 0.0000
2026-05-15 09:03:53.485 | print_info: n_ff                  = 17408
2026-05-15 09:03:53.485 | print_info: n_expert              = 0
2026-05-15 09:03:53.485 | print_info: n_expert_used         = 0
2026-05-15 09:03:53.485 | print_info: n_expert_groups       = 0
2026-05-15 09:03:53.485 | print_info: n_group_used          = 0
2026-05-15 09:03:53.485 | print_info: causal attn           = 1
2026-05-15 09:03:53.485 | print_info: pooling type          = -1
2026-05-15 09:03:53.485 | print_info: rope type             = 40
2026-05-15 09:03:53.485 | print_info: rope scaling          = linear
2026-05-15 09:03:53.485 | print_info: freq_base_train       = 10000000.0
2026-05-15 09:03:53.485 | print_info: freq_scale_train      = 1
2026-05-15 09:03:53.485 | print_info: n_ctx_orig_yarn       = 262144
2026-05-15 09:03:53.485 | print_info: rope_yarn_log_mul     = 0.0000
2026-05-15 09:03:53.486 | print_info: rope_finetuned        = unknown
2026-05-15 09:03:53.486 | print_info: mrope sections        = [11, 11, 10, 0]
2026-05-15 09:03:53.486 | print_info: ssm_d_conv            = 4
2026-05-15 09:03:53.486 | print_info: ssm_d_inner           = 6144
2026-05-15 09:03:53.486 | print_info: ssm_d_state           = 128
2026-05-15 09:03:53.486 | print_info: ssm_dt_rank           = 48
2026-05-15 09:03:53.486 | print_info: ssm_n_group           = 16
2026-05-15 09:03:53.486 | print_info: ssm_dt_b_c_rms        = 0
2026-05-15 09:03:53.486 | print_info: model type            = 27B
2026-05-15 09:03:53.486 | print_info: model params          = 27.32 B
2026-05-15 09:03:53.486 | print_info: general.name          = Qwen3.6-27B
2026-05-15 09:03:53.486 | print_info: vocab type            = BPE
2026-05-15 09:03:53.486 | print_info: n_vocab               = 248320
2026-05-15 09:03:53.486 | print_info: n_merges              = 247587
2026-05-15 09:03:53.486 | print_info: BOS token             = 248044 '<|endoftext|>'
2026-05-15 09:03:53.486 | print_info: EOS token             = 248046 '<|im_end|>'
2026-05-15 09:03:53.486 | print_info: EOT token             = 248046 '<|im_end|>'
2026-05-15 09:03:53.486 | print_info: PAD token             = 248055 '<|vision_pad|>'
2026-05-15 09:03:53.486 | print_info: LF token              = 198 'Ċ'
2026-05-15 09:03:53.486 | print_info: FIM PRE token         = 248060 '<|fim_prefix|>'
2026-05-15 09:03:53.486 | print_info: FIM SUF token         = 248062 '<|fim_suffix|>'
2026-05-15 09:03:53.486 | print_info: FIM MID token         = 248061 '<|fim_middle|>'
2026-05-15 09:03:53.486 | print_info: FIM PAD token         = 248063 '<|fim_pad|>'
2026-05-15 09:03:53.486 | print_info: FIM REP token         = 248064 '<|repo_name|>'
2026-05-15 09:03:53.486 | print_info: FIM SEP token         = 248065 '<|file_sep|>'
2026-05-15 09:03:53.486 | print_info: EOG token             = 248044 '<|endoftext|>'
2026-05-15 09:03:53.486 | print_info: EOG token             = 248046 '<|im_end|>'
2026-05-15 09:03:53.486 | print_info: EOG token             = 248063 '<|fim_pad|>'
2026-05-15 09:03:53.486 | print_info: EOG token             = 248064 '<|repo_name|>'
2026-05-15 09:03:53.486 | print_info: EOG token             = 248065 '<|file_sep|>'
2026-05-15 09:03:53.486 | print_info: max token length      = 256
2026-05-15 09:03:53.486 | load_tensors: loading model tensors, this can take a while... (mmap = true, direct_io = false)
2026-05-15 09:04:07.741 | load_tensors: offloading output layer to GPU
2026-05-15 09:04:07.741 | load_tensors: offloading 64 repeating layers to GPU
2026-05-15 09:04:07.741 | load_tensors: offloaded 66/66 layers to GPU
2026-05-15 09:04:07.741 | load_tensors:   CPU_Mapped model buffer size =   682.03 MiB
2026-05-15 09:04:07.741 | load_tensors:        CUDA0 model buffer size = 16386.94 MiB
2026-05-15 09:04:10.620 | .............................................................................................
2026-05-15 09:04:10.624 | common_init_result: added <|endoftext|> logit bias = -inf
2026-05-15 09:04:10.624 | common_init_result: added <|im_end|> logit bias = -inf
2026-05-15 09:04:10.624 | common_init_result: added <|fim_pad|> logit bias = -inf
2026-05-15 09:04:10.624 | common_init_result: added <|repo_name|> logit bias = -inf
2026-05-15 09:04:10.624 | common_init_result: added <|file_sep|> logit bias = -inf
2026-05-15 09:04:10.624 | llama_context: constructing llama_context
2026-05-15 09:04:10.624 | llama_context: n_seq_max     = 4
2026-05-15 09:04:10.624 | llama_context: n_ctx         = 131072
2026-05-15 09:04:10.624 | llama_context: n_ctx_seq     = 131072
2026-05-15 09:04:10.624 | llama_context: n_batch       = 2048
2026-05-15 09:04:10.624 | llama_context: n_ubatch      = 512
2026-05-15 09:04:10.624 | llama_context: causal_attn   = 1
2026-05-15 09:04:10.624 | llama_context: flash_attn    = enabled
2026-05-15 09:04:10.624 | llama_context: kv_unified    = true
2026-05-15 09:04:10.624 | llama_context: freq_base     = 10000000.0
2026-05-15 09:04:10.624 | llama_context: freq_scale    = 1
2026-05-15 09:04:10.624 | llama_context: n_ctx_seq (131072) < n_ctx_train (262144) -- the full capacity of the model will not be utilized
2026-05-15 09:04:10.629 | llama_context:  CUDA_Host  output buffer size =     3.79 MiB
2026-05-15 09:04:10.651 | llama_kv_cache:      CUDA0 KV buffer size =  4352.00 MiB
2026-05-15 09:04:10.681 | llama_kv_cache: size = 4352.00 MiB (131072 cells,  16 layers,  4/1 seqs), K (q8_0): 2176.00 MiB, V (q8_0): 2176.00 MiB
2026-05-15 09:04:10.681 | llama_kv_cache: attn_rot_k = 1, n_embd_head_k_all = 256
2026-05-15 09:04:10.681 | llama_kv_cache: attn_rot_v = 1, n_embd_head_k_all = 256
2026-05-15 09:04:10.688 | llama_memory_recurrent:      CUDA0 RS buffer size =   598.50 MiB
2026-05-15 09:04:10.688 | llama_memory_recurrent: size =  598.50 MiB (     4 cells,  65 layers,  4 seqs), R (f32):   22.50 MiB, S (f32):  576.00 MiB
2026-05-15 09:04:10.689 | sched_reserve: reserving ...
2026-05-15 09:04:10.710 | sched_reserve: resolving fused Gated Delta Net support:
2026-05-15 09:04:10.711 | sched_reserve: fused Gated Delta Net (autoregressive) enabled
2026-05-15 09:04:10.712 | sched_reserve: fused Gated Delta Net (chunked) enabled
2026-05-15 09:04:10.975 | sched_reserve:      CUDA0 compute buffer size =   495.00 MiB
2026-05-15 09:04:10.975 | sched_reserve:  CUDA_Host compute buffer size =   276.29 MiB
2026-05-15 09:04:10.975 | sched_reserve: graph nodes  = 3849
2026-05-15 09:04:10.975 | sched_reserve: graph splits = 2
2026-05-15 09:04:10.975 | sched_reserve: reserve took 286.65 ms, sched copies = 1
2026-05-15 09:04:10.975 | common_init_from_params: warming up the model with an empty run - please wait ... (--no-warmup to disable)
2026-05-15 09:04:11.292 | srv    load_model: creating MTP draft context against the target model '/root/.cache/huggingface/hub/models--unsloth--Qwen3.6-27B-MTP-GGUF/snapshots/296162df313e8eebe1e15a00d60b3f8f33962e18/Qwen3.6-27B-UD-Q4_K_XL.gguf'
2026-05-15 09:04:11.292 | llama_context: constructing llama_context
2026-05-15 09:04:11.292 | llama_context: n_seq_max     = 4
2026-05-15 09:04:11.292 | llama_context: n_ctx         = 131072
2026-05-15 09:04:11.292 | llama_context: n_ctx_seq     = 131072
2026-05-15 09:04:11.292 | llama_context: n_batch       = 2048
2026-05-15 09:04:11.292 | llama_context: n_ubatch      = 512
2026-05-15 09:04:11.292 | llama_context: causal_attn   = 1
2026-05-15 09:04:11.292 | llama_context: flash_attn    = enabled
2026-05-15 09:04:11.292 | llama_context: kv_unified    = true
2026-05-15 09:04:11.292 | llama_context: freq_base     = 10000000.0
2026-05-15 09:04:11.292 | llama_context: freq_scale    = 1
2026-05-15 09:04:11.292 | llama_context: n_ctx_seq (131072) < n_ctx_train (262144) -- the full capacity of the model will not be utilized
2026-05-15 09:04:11.297 | llama_context:  CUDA_Host  output buffer size =     3.79 MiB
2026-05-15 09:04:11.304 | llama_kv_cache:      CUDA0 KV buffer size =   272.00 MiB
2026-05-15 09:04:11.306 | llama_kv_cache: size =  272.00 MiB (131072 cells,   1 layers,  4/1 seqs), K (q8_0):  136.00 MiB, V (q8_0):  136.00 MiB
2026-05-15 09:04:11.306 | llama_kv_cache: attn_rot_k = 1, n_embd_head_k_all = 256
2026-05-15 09:04:11.306 | llama_kv_cache: attn_rot_v = 1, n_embd_head_k_all = 256
2026-05-15 09:04:11.307 | sched_reserve: reserving ...
2026-05-15 09:04:11.329 | sched_reserve: resolving fused Gated Delta Net support:
2026-05-15 09:04:11.329 | sched_reserve: fused Gated Delta Net (autoregressive) enabled
2026-05-15 09:04:11.329 | sched_reserve: fused Gated Delta Net (chunked) enabled
2026-05-15 09:04:11.602 | sched_reserve:      CUDA0 compute buffer size =   495.00 MiB
2026-05-15 09:04:11.602 | sched_reserve:  CUDA_Host compute buffer size =   276.28 MiB
2026-05-15 09:04:11.602 | sched_reserve: graph nodes  = 62
2026-05-15 09:04:11.602 | sched_reserve: graph splits = 2
2026-05-15 09:04:11.602 | sched_reserve: reserve took 295.59 ms, sched copies = 1
2026-05-15 09:04:11.620 | clip_model_loader: model name:   Qwen3.6-27B
2026-05-15 09:04:11.620 | clip_model_loader: description:  
2026-05-15 09:04:11.620 | clip_model_loader: GGUF version: 3
2026-05-15 09:04:11.620 | clip_model_loader: alignment:    32
2026-05-15 09:04:11.620 | clip_model_loader: n_tensors:    334
2026-05-15 09:04:11.620 | clip_model_loader: n_kv:         33
2026-05-15 09:04:11.620 | 
2026-05-15 09:04:11.620 | clip_model_loader: has vision encoder
2026-05-15 09:04:11.620 | clip_ctx: CLIP using CUDA0 backend
2026-05-15 09:04:11.621 | load_hparams: Qwen-VL models require at minimum 1024 image tokens to function correctly on grounding tasks
2026-05-15 09:04:11.621 | load_hparams: if you encounter problems with accuracy, try adding --image-min-tokens 1024
2026-05-15 09:04:11.621 | load_hparams: more info: https://github.com/ggml-org/llama.cpp/issues/16842
2026-05-15 09:04:11.621 | 
2026-05-15 09:04:11.621 | load_hparams: projector:          qwen3vl_merger
2026-05-15 09:04:11.621 | load_hparams: n_embd:             1152
2026-05-15 09:04:11.621 | load_hparams: n_head:             16
2026-05-15 09:04:11.621 | load_hparams: n_ff:               4304
2026-05-15 09:04:11.621 | load_hparams: n_layer:            27
2026-05-15 09:04:11.621 | load_hparams: ffn_op:             gelu
2026-05-15 09:04:11.621 | load_hparams: projection_dim:     5120
2026-05-15 09:04:11.621 | 
2026-05-15 09:04:11.621 | --- vision hparams ---
2026-05-15 09:04:11.621 | load_hparams: image_size:         768
2026-05-15 09:04:11.621 | load_hparams: patch_size:         16
2026-05-15 09:04:11.621 | load_hparams: has_llava_proj:     0
2026-05-15 09:04:11.621 | load_hparams: minicpmv_version:   0
2026-05-15 09:04:11.621 | load_hparams: n_merge:            2
2026-05-15 09:04:11.621 | load_hparams: n_wa_pattern: 0
2026-05-15 09:04:11.621 | load_hparams: image_min_pixels:   8192
2026-05-15 09:04:11.621 | load_hparams: image_max_pixels:   4194304
2026-05-15 09:04:11.621 | 
2026-05-15 09:04:11.621 | load_hparams: model size:         887.99 MiB
2026-05-15 09:04:11.621 | load_hparams: metadata size:      0.12 MiB
2026-05-15 09:04:12.491 | warmup: warmup with image size = 1472 x 1472
2026-05-15 09:04:12.493 | alloc_compute_meta:      CUDA0 compute buffer size =   248.10 MiB
2026-05-15 09:04:12.493 | alloc_compute_meta:        CPU compute buffer size =    24.93 MiB
2026-05-15 09:04:12.493 | alloc_compute_meta: graph splits = 1, nodes = 823
2026-05-15 09:04:12.493 | warmup: flash attention is enabled
2026-05-15 09:04:12.493 | srv    load_model: loaded multimodal model, '/root/.cache/huggingface/hub/models--unsloth--Qwen3.6-27B-MTP-GGUF/snapshots/296162df313e8eebe1e15a00d60b3f8f33962e18/mmproj-BF16.gguf'
2026-05-15 09:04:12.493 | srv    load_model: initializing slots, n_slots = 4
2026-05-15 09:04:12.534 | common_context_can_seq_rm: the context does not support partial sequence removal
2026-05-15 09:04:12.564 | srv    load_model: speculative decoding will use checkpoints
2026-05-15 09:04:12.564 | common_speculative_init: adding speculative implementation 'mtp'
2026-05-15 09:04:12.565 | srv    load_model: speculative decoding context initialized
2026-05-15 09:04:12.565 | slot   load_model: id  0 | task -1 | new slot, n_ctx = 131072
2026-05-15 09:04:12.565 | slot   load_model: id  1 | task -1 | new slot, n_ctx = 131072
2026-05-15 09:04:12.565 | slot   load_model: id  2 | task -1 | new slot, n_ctx = 131072
2026-05-15 09:04:12.565 | slot   load_model: id  3 | task -1 | new slot, n_ctx = 131072
2026-05-15 09:04:12.565 | srv    load_model: prompt cache is enabled, size limit: 8192 MiB
2026-05-15 09:04:12.565 | srv    load_model: use `--cache-ram 0` to disable the prompt cache
2026-05-15 09:04:12.565 | srv    load_model: for more info see https://github.com/ggml-org/llama.cpp/pull/16391
2026-05-15 09:04:12.565 | srv          init: init: idle slots will be saved to prompt cache and cleared upon starting a new task
2026-05-15 09:04:12.578 | init: chat template, example_format: '<|im_start|>system
2026-05-15 09:04:12.579 | You are a helpful assistant<|im_end|>
2026-05-15 09:04:12.579 | <|im_start|>user
2026-05-15 09:04:12.579 | Hello<|im_end|>
2026-05-15 09:04:12.579 | <|im_start|>assistant
2026-05-15 09:04:12.579 | Hi there<|im_end|>
2026-05-15 09:04:12.579 | <|im_start|>user
2026-05-15 09:04:12.579 | How are you?<|im_end|>
2026-05-15 09:04:12.579 | <|im_start|>assistant
2026-05-15 09:04:12.579 | <think>
2026-05-15 09:04:12.579 | '
2026-05-15 09:04:12.588 | srv          init: init: chat template, thinking = 1
2026-05-15 09:04:12.588 | main: model loaded
2026-05-15 09:04:12.588 | main: server is listening on http://0.0.0.0:8080
2026-05-15 09:04:12.588 | main: starting the main loop...
2026-05-15 09:04:12.588 | srv  update_slots: all slots are idle
2026-05-15 10:41:27.048 | srv  params_from_: Chat format: peg-native
2026-05-15 10:41:27.050 | slot get_availabl: id  3 | task -1 | selected slot by LRU, t_last = -1
2026-05-15 10:41:27.050 | srv  get_availabl: updating prompt cache
2026-05-15 10:41:27.050 | srv          load:  - looking for better prompt, base f_keep = -1.000, sim = 0.000
2026-05-15 10:41:27.050 | srv        update:  - cache state: 0 prompts, 0.000 MiB (limits: 8192.000 MiB, 131072 tokens, 8589934592 est)
2026-05-15 10:41:27.050 | srv  get_availabl: prompt cache update took 0.01 ms
2026-05-15 10:41:27.051 | slot launch_slot_: id  3 | task -1 | sampler chain: logits -> penalties -> ?dry -> ?top-n-sigma -> top-k -> ?typical -> ?top-p -> min-p -> ?xtc -> ?temp-ext -> dist 
2026-05-15 10:41:27.051 | slot launch_slot_: id  3 | task 0 | processing task, is_child = 0
2026-05-15 10:41:27.051 | slot update_slots: id  3 | task 0 | new prompt, n_ctx_slot = 131072, n_keep = 0, task.n_tokens = 922
2026-05-15 10:41:27.051 | slot update_slots: id  3 | task 0 | n_tokens = 0, memory_seq_rm [0, end)
2026-05-15 10:41:27.051 | slot update_slots: id  3 | task 0 | prompt processing progress, n_tokens = 406, batch.n_tokens = 406, progress = 0.440347
2026-05-15 10:41:27.355 | srv  params_from_: Chat format: peg-native
2026-05-15 10:41:27.976 | slot get_availabl: id  2 | task -1 | selected slot by LRU, t_last = -1
2026-05-15 10:41:27.976 | srv  get_availabl: updating prompt cache
2026-05-15 10:41:27.976 | srv          load:  - looking for better prompt, base f_keep = -1.000, sim = 0.000
2026-05-15 10:41:27.976 | srv        update:  - cache state: 0 prompts, 0.000 MiB (limits: 8192.000 MiB, 131072 tokens, 8589934592 est)
2026-05-15 10:41:27.976 | srv  get_availabl: prompt cache update took 0.01 ms
2026-05-15 10:41:27.978 | reasoning-budget: activated, budget=2147483647 tokens
2026-05-15 10:41:27.978 | slot launch_slot_: id  2 | task -1 | sampler chain: logits -> penalties -> ?dry -> ?top-n-sigma -> top-k -> ?typical -> ?top-p -> min-p -> ?xtc -> ?temp-ext -> dist 
2026-05-15 10:41:27.978 | slot launch_slot_: id  2 | task 2 | processing task, is_child = 0
2026-05-15 10:41:27.978 | slot update_slots: id  2 | task 2 | new prompt, n_ctx_slot = 131072, n_keep = 0, task.n_tokens = 11851
2026-05-15 10:41:27.978 | slot update_slots: id  2 | task 2 | n_tokens = 0, memory_seq_rm [0, end)
2026-05-15 10:41:27.978 | slot update_slots: id  2 | task 2 | prompt processing progress, n_tokens = 2048, batch.n_tokens = 2048, progress = 0.172812
2026-05-15 10:41:31.020 | slot update_slots: id  2 | task 2 | n_tokens = 2048, memory_seq_rm [2048, end)
2026-05-15 10:41:31.020 | slot update_slots: id  2 | task 2 | prompt processing progress, n_tokens = 4096, batch.n_tokens = 2048, progress = 0.345625
2026-05-15 10:41:31.801 | slot update_slots: id  2 | task 2 | n_tokens = 4096, memory_seq_rm [4096, end)
2026-05-15 10:41:31.802 | slot update_slots: id  2 | task 2 | prompt processing progress, n_tokens = 6144, batch.n_tokens = 2048, progress = 0.518437
2026-05-15 10:41:32.581 | slot update_slots: id  2 | task 2 | n_tokens = 6144, memory_seq_rm [6144, end)
2026-05-15 10:41:32.582 | slot update_slots: id  2 | task 2 | prompt processing progress, n_tokens = 8192, batch.n_tokens = 2048, progress = 0.691250
2026-05-15 10:41:33.377 | slot update_slots: id  2 | task 2 | n_tokens = 8192, memory_seq_rm [8192, end)
2026-05-15 10:41:33.377 | slot update_slots: id  2 | task 2 | 8192 tokens since last checkpoint at 0, creating new checkpoint during processing at position 10240
2026-05-15 10:41:33.377 | slot update_slots: id  2 | task 2 | prompt processing progress, n_tokens = 10240, batch.n_tokens = 2048, progress = 0.864062
2026-05-15 10:41:33.550 | slot create_check: id  2 | task 2 | created context checkpoint 1 of 32 (pos_min = 8191, pos_max = 8191, n_tokens = 8192, size = 166.782 MiB)
2026-05-15 10:41:34.375 | slot update_slots: id  2 | task 2 | n_tokens = 10240, memory_seq_rm [10240, end)
2026-05-15 10:41:34.375 | slot update_slots: id  2 | task 2 | prompt processing progress, n_tokens = 11335, batch.n_tokens = 1095, progress = 0.956459
2026-05-15 10:41:34.375 | slot update_slots: id  3 | task 0 | n_tokens = 406, memory_seq_rm [406, end)
2026-05-15 10:41:34.375 | slot update_slots: id  3 | task 0 | prompt processing progress, n_tokens = 918, batch.n_tokens = 1607, progress = 0.995662
2026-05-15 10:41:34.551 | slot create_check: id  3 | task 0 | created context checkpoint 1 of 32 (pos_min = 405, pos_max = 405, n_tokens = 406, size = 150.476 MiB)
2026-05-15 10:41:35.224 | slot update_slots: id  2 | task 2 | n_tokens = 11335, memory_seq_rm [11335, end)
2026-05-15 10:41:35.224 | slot update_slots: id  2 | task 2 | prompt processing progress, n_tokens = 11847, batch.n_tokens = 512, progress = 0.999662
2026-05-15 10:41:35.418 | slot create_check: id  2 | task 2 | created context checkpoint 2 of 32 (pos_min = 11334, pos_max = 11334, n_tokens = 11335, size = 173.365 MiB)
2026-05-15 10:41:35.418 | slot update_slots: id  3 | task 0 | n_tokens = 918, memory_seq_rm [918, end)
2026-05-15 10:41:35.418 | slot init_sampler: id  3 | task 0 | init sampler, took 0.16 ms, tokens: text = 922, total = 922
2026-05-15 10:41:35.418 | slot update_slots: id  3 | task 0 | prompt processing done, n_tokens = 922, batch.n_tokens = 516
2026-05-15 10:41:35.593 | slot create_check: id  3 | task 0 | created context checkpoint 2 of 32 (pos_min = 917, pos_max = 917, n_tokens = 918, size = 151.549 MiB)
2026-05-15 10:41:35.865 | srv  log_server_r: done request: POST /v1/chat/completions 172.18.0.1 200
2026-05-15 10:41:35.884 | ~llama_io_write_device: allocated 'CUDA0' buffer 149.625 MiB
2026-05-15 10:41:35.889 | slot update_slots: id  2 | task 2 | n_tokens = 11847, memory_seq_rm [11847, end)
2026-05-15 10:41:35.891 | slot init_sampler: id  2 | task 2 | init sampler, took 1.75 ms, tokens: text = 11851, total = 11851
2026-05-15 10:41:35.891 | slot update_slots: id  2 | task 2 | prompt processing done, n_tokens = 11851, batch.n_tokens = 7
2026-05-15 10:41:36.093 | slot create_check: id  2 | task 2 | created context checkpoint 3 of 32 (pos_min = 11846, pos_max = 11846, n_tokens = 11847, size = 174.437 MiB)
2026-05-15 10:41:36.170 | srv  log_server_r: done request: POST /v1/chat/completions 172.18.0.1 200
2026-05-15 10:41:36.184 | ~llama_io_write_device: allocated 'CUDA0' buffer 149.625 MiB
2026-05-15 10:41:35.369 | reasoning-budget: deactivated (natural end)
2026-05-15 10:41:37.324 | slot print_timing: id  2 | task 2 | 
2026-05-15 10:41:37.324 | prompt eval time =    8192.28 ms / 11851 tokens (    0.69 ms per token,  1446.61 tokens per second)
2026-05-15 10:41:37.324 |        eval time =    3459.30 ms /   111 tokens (   31.16 ms per token,    32.09 tokens per second)
2026-05-15 10:41:37.324 |       total time =   11651.58 ms / 11962 tokens
2026-05-15 10:41:37.324 | draft acceptance rate = 0.98630 (   72 accepted /    73 generated)
2026-05-15 10:41:37.324 | statistics mtp: #calls(b,g,a) = 2 44 75, #gen drafts = 76, #acc drafts = 75, #gen tokens = 145, #acc tokens = 142, dur(b,g,a) = 0.006, 245.250, 0.028 ms
2026-05-15 10:41:37.324 | slot      release: id  2 | task 2 | stop processing: n_tokens = 11961, truncated = 0
2026-05-15 10:41:37.525 | srv  params_from_: Chat format: peg-native
2026-05-15 10:41:37.572 | slot get_availabl: id  2 | task -1 | selected slot by LCP similarity, sim_best = 0.789 (> 0.100 thold), f_keep = 0.991
2026-05-15 10:41:37.573 | reasoning-budget: activated, budget=2147483647 tokens
2026-05-15 10:41:37.573 | slot launch_slot_: id  2 | task -1 | sampler chain: logits -> penalties -> ?dry -> ?top-n-sigma -> top-k -> ?typical -> ?top-p -> min-p -> ?xtc -> ?temp-ext -> dist 
2026-05-15 10:41:37.573 | slot launch_slot_: id  2 | task 59 | processing task, is_child = 0
2026-05-15 10:41:37.581 | slot update_slots: id  2 | task 59 | new prompt, n_ctx_slot = 131072, n_keep = 0, task.n_tokens = 15028
2026-05-15 10:41:37.581 | slot update_slots: id  2 | task 59 | n_past = 11850, slot.prompt.tokens.size() = 11961, seq_id = 2, pos_min = 11960, n_swa = 0
2026-05-15 10:41:37.581 | slot update_slots: id  2 | task 59 | Checking checkpoint with [11846, 11846] against 11850...
2026-05-15 10:41:38.180 | slot update_slots: id  2 | task 59 | restored context checkpoint (pos_min = 11846, pos_max = 11846, n_tokens = 11847, n_past = 11847, size = 174.437 MiB)
2026-05-15 10:41:38.180 | slot update_slots: id  2 | task 59 | n_tokens = 11847, memory_seq_rm [11847, end)
2026-05-15 10:41:38.180 | slot update_slots: id  2 | task 59 | prompt processing progress, n_tokens = 13892, batch.n_tokens = 2048, progress = 0.924408
2026-05-15 10:41:39.078 | slot update_slots: id  2 | task 59 | n_tokens = 13892, memory_seq_rm [13892, end)
2026-05-15 10:41:39.078 | slot update_slots: id  2 | task 59 | prompt processing progress, n_tokens = 14512, batch.n_tokens = 623, progress = 0.965664
2026-05-15 10:41:39.394 | slot update_slots: id  2 | task 59 | n_tokens = 14512, memory_seq_rm [14512, end)
2026-05-15 10:41:39.394 | slot update_slots: id  2 | task 59 | prompt processing progress, n_tokens = 15024, batch.n_tokens = 513, progress = 0.999734
2026-05-15 10:41:39.608 | slot create_check: id  2 | task 59 | created context checkpoint 4 of 32 (pos_min = 14511, pos_max = 14511, n_tokens = 14512, size = 180.018 MiB)
2026-05-15 10:41:39.859 | slot update_slots: id  2 | task 59 | n_tokens = 15024, memory_seq_rm [15024, end)
2026-05-15 10:41:39.861 | slot init_sampler: id  2 | task 59 | init sampler, took 2.06 ms, tokens: text = 15028, total = 15028
2026-05-15 10:41:39.861 | slot update_slots: id  2 | task 59 | prompt processing done, n_tokens = 15028, batch.n_tokens = 6
2026-05-15 10:41:40.079 | slot create_check: id  2 | task 59 | created context checkpoint 5 of 32 (pos_min = 15023, pos_max = 15023, n_tokens = 15024, size = 181.090 MiB)
2026-05-15 10:41:40.140 | srv  log_server_r: done request: POST /v1/chat/completions 172.18.0.1 200
2026-05-15 10:41:48.100 | reasoning-budget: deactivated (natural end)
2026-05-15 10:41:57.309 | slot print_timing: id  2 | task 59 | 
2026-05-15 10:41:57.309 | prompt eval time =    2559.37 ms /  3181 tokens (    0.80 ms per token,  1242.89 tokens per second)
2026-05-15 10:41:57.309 |        eval time =   17169.12 ms /   494 tokens (   34.76 ms per token,    28.77 tokens per second)
2026-05-15 10:41:57.310 |       total time =   19728.49 ms /  3675 tokens
2026-05-15 10:41:57.310 | draft acceptance rate = 0.98182 (  270 accepted /   275 generated)
2026-05-15 10:41:57.310 | statistics mtp: #calls(b,g,a) = 3 287 406, #gen drafts = 406, #acc drafts = 406, #gen tokens = 722, #acc tokens = 709, dur(b,g,a) = 0.007, 1425.524, 0.172 ms
2026-05-15 10:41:57.310 | slot      release: id  2 | task 59 | stop processing: n_tokens = 15521, truncated = 0
2026-05-15 10:42:12.556 | slot print_timing: id  3 | task 0 | 
2026-05-15 10:42:12.556 | prompt eval time =    8813.65 ms /   922 tokens (    9.56 ms per token,   104.61 tokens per second)
2026-05-15 10:42:12.556 |        eval time =   41304.02 ms /  1769 tokens (   23.35 ms per token,    42.83 tokens per second)
2026-05-15 10:42:12.556 |       total time =   50117.67 ms /  2691 tokens
2026-05-15 10:42:12.556 | draft acceptance rate = 0.98356 ( 1017 accepted /  1034 generated)
2026-05-15 10:42:12.556 | statistics mtp: #calls(b,g,a) = 3 775 792, #gen drafts = 792, #acc drafts = 792, #gen tokens = 1382, #acc tokens = 1359, dur(b,g,a) = 0.007, 3243.723, 0.352 ms
2026-05-15 10:42:12.556 | slot      release: id  3 | task 0 | stop processing: n_tokens = 2690, truncated = 0
2026-05-15 10:42:12.556 | srv  update_slots: all slots are idle
2026-05-15 10:43:23.163 | srv  params_from_: Chat format: peg-native
2026-05-15 10:43:23.167 | slot get_availabl: id  2 | task -1 | selected slot by LCP similarity, sim_best = 0.764 (> 0.100 thold), f_keep = 0.743
2026-05-15 10:43:23.168 | reasoning-budget: activated, budget=2147483647 tokens
2026-05-15 10:43:23.168 | slot launch_slot_: id  2 | task -1 | sampler chain: logits -> penalties -> ?dry -> ?top-n-sigma -> top-k -> ?typical -> ?top-p -> min-p -> ?xtc -> ?temp-ext -> dist 
2026-05-15 10:43:23.169 | slot launch_slot_: id  2 | task 809 | processing task, is_child = 0
2026-05-15 10:43:23.169 | slot slot_save_an: id  3 | task -1 | saving idle slot to prompt cache
2026-05-15 10:43:23.169 | srv   prompt_save:  - saving prompt with length 2690, total state size = 244.628 MiB (draft: 5.634 MiB)
2026-05-15 10:43:24.338 | slot prompt_clear: id  3 | task -1 | clearing prompt with 2690 tokens
2026-05-15 10:43:24.339 | srv        update:  - cache state: 1 prompts, 546.653 MiB (limits: 8192.000 MiB, 131072 tokens, 131072 est)
2026-05-15 10:43:24.339 | srv        update:    - prompt 0x652afb9fd820:    2690 tokens, checkpoints:  2,   546.653 MiB
2026-05-15 10:43:24.339 | slot update_slots: id  2 | task 809 | new prompt, n_ctx_slot = 131072, n_keep = 0, task.n_tokens = 15094
2026-05-15 10:43:24.339 | slot update_slots: id  2 | task 809 | n_past = 11536, slot.prompt.tokens.size() = 15521, seq_id = 2, pos_min = 15520, n_swa = 0
2026-05-15 10:43:24.339 | slot update_slots: id  2 | task 809 | Checking checkpoint with [15023, 15023] against 11536...
2026-05-15 10:43:24.339 | slot update_slots: id  2 | task 809 | Checking checkpoint with [14511, 14511] against 11536...
2026-05-15 10:43:24.339 | slot update_slots: id  2 | task 809 | Checking checkpoint with [11846, 11846] against 11536...
2026-05-15 10:43:24.339 | slot update_slots: id  2 | task 809 | Checking checkpoint with [11334, 11334] against 11536...
2026-05-15 10:43:24.408 | slot update_slots: id  2 | task 809 | restored context checkpoint (pos_min = 11334, pos_max = 11334, n_tokens = 11335, n_past = 11335, size = 173.365 MiB)
2026-05-15 10:43:24.408 | slot update_slots: id  2 | task 809 | erased invalidated context checkpoint (pos_min = 11846, pos_max = 11846, n_tokens = 11847, n_swa = 0, pos_next = 11335, size = 174.437 MiB)
2026-05-15 10:43:24.418 | slot update_slots: id  2 | task 809 | erased invalidated context checkpoint (pos_min = 14511, pos_max = 14511, n_tokens = 14512, n_swa = 0, pos_next = 11335, size = 180.018 MiB)
2026-05-15 10:43:24.429 | slot update_slots: id  2 | task 809 | erased invalidated context checkpoint (pos_min = 15023, pos_max = 15023, n_tokens = 15024, n_swa = 0, pos_next = 11335, size = 181.090 MiB)
2026-05-15 10:43:24.440 | slot update_slots: id  2 | task 809 | n_tokens = 11335, memory_seq_rm [11335, end)
2026-05-15 10:43:24.441 | slot update_slots: id  2 | task 809 | prompt processing progress, n_tokens = 13383, batch.n_tokens = 2048, progress = 0.886644
2026-05-15 10:43:25.315 | slot update_slots: id  2 | task 809 | n_tokens = 13383, memory_seq_rm [13383, end)
2026-05-15 10:43:25.315 | slot update_slots: id  2 | task 809 | prompt processing progress, n_tokens = 14578, batch.n_tokens = 1195, progress = 0.965814
2026-05-15 10:43:25.825 | slot update_slots: id  2 | task 809 | n_tokens = 14578, memory_seq_rm [14578, end)
2026-05-15 10:43:25.825 | slot update_slots: id  2 | task 809 | prompt processing progress, n_tokens = 15090, batch.n_tokens = 512, progress = 0.999735
2026-05-15 10:43:26.019 | slot create_check: id  2 | task 809 | created context checkpoint 3 of 32 (pos_min = 14577, pos_max = 14577, n_tokens = 14578, size = 180.156 MiB)
2026-05-15 10:43:26.227 | slot update_slots: id  2 | task 809 | n_tokens = 15090, memory_seq_rm [15090, end)
2026-05-15 10:43:26.230 | slot init_sampler: id  2 | task 809 | init sampler, took 2.13 ms, tokens: text = 15094, total = 15094
2026-05-15 10:43:26.230 | slot update_slots: id  2 | task 809 | prompt processing done, n_tokens = 15094, batch.n_tokens = 4
2026-05-15 10:43:26.440 | slot create_check: id  2 | task 809 | created context checkpoint 4 of 32 (pos_min = 15089, pos_max = 15089, n_tokens = 15090, size = 181.229 MiB)
2026-05-15 10:43:26.485 | srv  log_server_r: done request: POST /v1/chat/completions 172.18.0.1 200
2026-05-15 10:43:27.046 | reasoning-budget: deactivated (natural end)
2026-05-15 10:43:26.605 | slot print_timing: id  2 | task 809 | 
2026-05-15 10:43:26.605 | prompt eval time =    2145.34 ms /  3759 tokens (    0.57 ms per token,  1752.17 tokens per second)
2026-05-15 10:43:26.605 |        eval time =    2426.72 ms /   204 tokens (   11.90 ms per token,    84.06 tokens per second)
2026-05-15 10:43:26.605 |       total time =    4572.05 ms /  3963 tokens
2026-05-15 10:43:26.605 | draft acceptance rate = 1.00000 (  131 accepted /   131 generated)
2026-05-15 10:43:26.605 | statistics mtp: #calls(b,g,a) = 4 847 860, #gen drafts = 860, #acc drafts = 860, #gen tokens = 1513, #acc tokens = 1490, dur(b,g,a) = 0.008, 3549.227, 0.391 ms
2026-05-15 10:43:26.605 | slot      release: id  2 | task 809 | stop processing: n_tokens = 15297, truncated = 0
2026-05-15 10:43:26.605 | srv  update_slots: all slots are idle
2026-05-15 10:43:26.799 | srv  params_from_: Chat format: peg-native
2026-05-15 10:43:26.801 | slot get_availabl: id  2 | task -1 | selected slot by LCP similarity, sim_best = 0.910 (> 0.100 thold), f_keep = 0.987
2026-05-15 10:43:26.803 | reasoning-budget: activated, budget=2147483647 tokens
2026-05-15 10:43:26.803 | slot launch_slot_: id  2 | task -1 | sampler chain: logits -> penalties -> ?dry -> ?top-n-sigma -> top-k -> ?typical -> ?top-p -> min-p -> ?xtc -> ?temp-ext -> dist 
2026-05-15 10:43:26.803 | slot launch_slot_: id  2 | task 888 | processing task, is_child = 0
2026-05-15 10:43:26.803 | slot update_slots: id  2 | task 888 | new prompt, n_ctx_slot = 131072, n_keep = 0, task.n_tokens = 16586
2026-05-15 10:43:26.803 | slot update_slots: id  2 | task 888 | n_past = 15093, slot.prompt.tokens.size() = 15297, seq_id = 2, pos_min = 15296, n_swa = 0
2026-05-15 10:43:26.803 | slot update_slots: id  2 | task 888 | Checking checkpoint with [15089, 15089] against 15093...
2026-05-15 10:43:26.828 | slot update_slots: id  2 | task 888 | restored context checkpoint (pos_min = 15089, pos_max = 15089, n_tokens = 15090, n_past = 15090, size = 181.229 MiB)
2026-05-15 10:43:26.828 | slot update_slots: id  2 | task 888 | n_tokens = 15090, memory_seq_rm [15090, end)
2026-05-15 10:43:26.828 | slot update_slots: id  2 | task 888 | prompt processing progress, n_tokens = 16070, batch.n_tokens = 980, progress = 0.968889
2026-05-15 10:43:27.243 | slot update_slots: id  2 | task 888 | n_tokens = 16070, memory_seq_rm [16070, end)
2026-05-15 10:43:27.243 | slot update_slots: id  2 | task 888 | prompt processing progress, n_tokens = 16582, batch.n_tokens = 512, progress = 0.999759
2026-05-15 10:43:27.464 | slot create_check: id  2 | task 888 | created context checkpoint 5 of 32 (pos_min = 16069, pos_max = 16069, n_tokens = 16070, size = 183.281 MiB)
2026-05-15 10:43:27.674 | slot update_slots: id  2 | task 888 | n_tokens = 16582, memory_seq_rm [16582, end)
2026-05-15 10:43:27.677 | slot init_sampler: id  2 | task 888 | init sampler, took 2.35 ms, tokens: text = 16586, total = 16586
2026-05-15 10:43:27.677 | slot update_slots: id  2 | task 888 | prompt processing done, n_tokens = 16586, batch.n_tokens = 4
2026-05-15 10:43:27.897 | slot create_check: id  2 | task 888 | created context checkpoint 6 of 32 (pos_min = 16581, pos_max = 16581, n_tokens = 16582, size = 184.353 MiB)
2026-05-15 10:43:27.934 | srv  log_server_r: done request: POST /v1/chat/completions 172.18.0.1 200
2026-05-15 10:43:28.213 | reasoning-budget: deactivated (natural end)
2026-05-15 10:43:30.205 | slot print_timing: id  2 | task 888 | 
2026-05-15 10:43:30.205 | prompt eval time =    1130.37 ms /  1496 tokens (    0.76 ms per token,  1323.47 tokens per second)
2026-05-15 10:43:30.205 |        eval time =    2271.57 ms /   195 tokens (   11.65 ms per token,    85.84 tokens per second)
2026-05-15 10:43:30.205 |       total time =    3401.93 ms /  1691 tokens
2026-05-15 10:43:30.205 | draft acceptance rate = 0.99219 (  127 accepted /   128 generated)
2026-05-15 10:43:30.205 | statistics mtp: #calls(b,g,a) = 5 914 925, #gen drafts = 925, #acc drafts = 925, #gen tokens = 1641, #acc tokens = 1617, dur(b,g,a) = 0.009, 3832.966, 0.421 ms
2026-05-15 10:43:30.206 | slot      release: id  2 | task 888 | stop processing: n_tokens = 16780, truncated = 0
2026-05-15 10:43:30.206 | srv  update_slots: all slots are idle
2026-05-15 10:43:30.373 | srv  params_from_: Chat format: peg-native
2026-05-15 10:43:30.376 | slot get_availabl: id  2 | task -1 | selected slot by LCP similarity, sim_best = 0.978 (> 0.100 thold), f_keep = 1.000
2026-05-15 10:43:30.377 | reasoning-budget: activated, budget=2147483647 tokens
2026-05-15 10:43:30.377 | slot launch_slot_: id  2 | task -1 | sampler chain: logits -> penalties -> ?dry -> ?top-n-sigma -> top-k -> ?typical -> ?top-p -> min-p -> ?xtc -> ?temp-ext -> dist 
2026-05-15 10:43:30.377 | slot launch_slot_: id  2 | task 962 | processing task, is_child = 0
2026-05-15 10:43:30.377 | slot update_slots: id  2 | task 962 | new prompt, n_ctx_slot = 131072, n_keep = 0, task.n_tokens = 17161
2026-05-15 10:43:30.378 | slot update_slots: id  2 | task 962 | n_tokens = 16780, memory_seq_rm [16780, end)
2026-05-15 10:43:30.378 | slot update_slots: id  2 | task 962 | prompt processing progress, n_tokens = 17157, batch.n_tokens = 377, progress = 0.999767
2026-05-15 10:43:30.610 | slot create_check: id  2 | task 962 | created context checkpoint 7 of 32 (pos_min = 16779, pos_max = 16779, n_tokens = 16780, size = 184.768 MiB)
2026-05-15 10:43:30.774 | slot update_slots: id  2 | task 962 | n_tokens = 17157, memory_seq_rm [17157, end)
2026-05-15 10:43:30.777 | slot init_sampler: id  2 | task 962 | init sampler, took 2.31 ms, tokens: text = 17161, total = 17161
2026-05-15 10:43:30.777 | slot update_slots: id  2 | task 962 | prompt processing done, n_tokens = 17161, batch.n_tokens = 4
2026-05-15 10:43:30.990 | slot create_check: id  2 | task 962 | created context checkpoint 8 of 32 (pos_min = 17156, pos_max = 17156, n_tokens = 17157, size = 185.558 MiB)
2026-05-15 10:43:31.027 | srv  log_server_r: done request: POST /v1/chat/completions 172.18.0.1 200
2026-05-15 10:43:31.703 | reasoning-budget: deactivated (natural end)
2026-05-15 10:43:36.314 | slot print_timing: id  2 | task 962 | 
2026-05-15 10:43:36.314 | prompt eval time =     648.85 ms /   381 tokens (    1.70 ms per token,   587.20 tokens per second)
2026-05-15 10:43:36.314 |        eval time =    5287.00 ms /   307 tokens (   17.22 ms per token,    58.07 tokens per second)
2026-05-15 10:43:36.314 |       total time =    5935.84 ms /   688 tokens
2026-05-15 10:43:36.314 | draft acceptance rate = 0.98204 (  164 accepted /   167 generated)
2026-05-15 10:43:36.314 | statistics mtp: #calls(b,g,a) = 6 1056 1025, #gen drafts = 1025, #acc drafts = 1025, #gen tokens = 1808, #acc tokens = 1781, dur(b,g,a) = 0.010, 4364.083, 0.472 ms
2026-05-15 10:43:36.314 | slot      release: id  2 | task 962 | stop processing: n_tokens = 17467, truncated = 0
2026-05-15 10:43:36.314 | srv  update_slots: all slots are idle
2026-05-15 10:44:17.431 | srv  params_from_: Chat format: peg-native
2026-05-15 10:44:17.434 | slot get_availabl: id  2 | task -1 | selected slot by LCP similarity, sim_best = 0.865 (> 0.100 thold), f_keep = 0.861
2026-05-15 10:44:17.435 | reasoning-budget: activated, budget=2147483647 tokens
2026-05-15 10:44:17.435 | slot launch_slot_: id  2 | task -1 | sampler chain: logits -> penalties -> ?dry -> ?top-n-sigma -> top-k -> ?typical -> ?top-p -> min-p -> ?xtc -> ?temp-ext -> dist 
2026-05-15 10:44:17.435 | slot launch_slot_: id  2 | task 1115 | processing task, is_child = 0
2026-05-15 10:44:17.435 | slot update_slots: id  2 | task 1115 | new prompt, n_ctx_slot = 131072, n_keep = 0, task.n_tokens = 17384
2026-05-15 10:44:17.435 | slot update_slots: id  2 | task 1115 | n_past = 15032, slot.prompt.tokens.size() = 17467, seq_id = 2, pos_min = 17466, n_swa = 0
2026-05-15 10:44:17.435 | slot update_slots: id  2 | task 1115 | Checking checkpoint with [17156, 17156] against 15032...
2026-05-15 10:44:17.435 | slot update_slots: id  2 | task 1115 | Checking checkpoint with [16779, 16779] against 15032...
2026-05-15 10:44:17.435 | slot update_slots: id  2 | task 1115 | Checking checkpoint with [16581, 16581] against 15032...
2026-05-15 10:44:17.435 | slot update_slots: id  2 | task 1115 | Checking checkpoint with [16069, 16069] against 15032...
2026-05-15 10:44:17.435 | slot update_slots: id  2 | task 1115 | Checking checkpoint with [15089, 15089] against 15032...
2026-05-15 10:44:17.435 | slot update_slots: id  2 | task 1115 | Checking checkpoint with [14577, 14577] against 15032...
2026-05-15 10:44:17.511 | slot update_slots: id  2 | task 1115 | restored context checkpoint (pos_min = 14577, pos_max = 14577, n_tokens = 14578, n_past = 14578, size = 180.156 MiB)
2026-05-15 10:44:17.511 | slot update_slots: id  2 | task 1115 | erased invalidated context checkpoint (pos_min = 15089, pos_max = 15089, n_tokens = 15090, n_swa = 0, pos_next = 14578, size = 181.229 MiB)
2026-05-15 10:44:17.522 | slot update_slots: id  2 | task 1115 | erased invalidated context checkpoint (pos_min = 16069, pos_max = 16069, n_tokens = 16070, n_swa = 0, pos_next = 14578, size = 183.281 MiB)
2026-05-15 10:44:17.533 | slot update_slots: id  2 | task 1115 | erased invalidated context checkpoint (pos_min = 16581, pos_max = 16581, n_tokens = 16582, n_swa = 0, pos_next = 14578, size = 184.353 MiB)
2026-05-15 10:44:17.544 | slot update_slots: id  2 | task 1115 | erased invalidated context checkpoint (pos_min = 16779, pos_max = 16779, n_tokens = 16780, n_swa = 0, pos_next = 14578, size = 184.768 MiB)
2026-05-15 10:44:17.555 | slot update_slots: id  2 | task 1115 | erased invalidated context checkpoint (pos_min = 17156, pos_max = 17156, n_tokens = 17157, n_swa = 0, pos_next = 14578, size = 185.558 MiB)
2026-05-15 10:44:17.567 | slot update_slots: id  2 | task 1115 | n_tokens = 14578, memory_seq_rm [14578, end)
2026-05-15 10:44:17.567 | slot update_slots: id  2 | task 1115 | prompt processing progress, n_tokens = 16626, batch.n_tokens = 2048, progress = 0.956397
2026-05-15 10:44:18.579 | slot update_slots: id  2 | task 1115 | n_tokens = 16626, memory_seq_rm [16626, end)
2026-05-15 10:44:18.579 | slot update_slots: id  2 | task 1115 | prompt processing progress, n_tokens = 16868, batch.n_tokens = 242, progress = 0.970318
2026-05-15 10:44:18.702 | slot update_slots: id  2 | task 1115 | n_tokens = 16868, memory_seq_rm [16868, end)
2026-05-15 10:44:18.702 | slot update_slots: id  2 | task 1115 | prompt processing progress, n_tokens = 17380, batch.n_tokens = 512, progress = 0.999770
2026-05-15 10:44:18.863 | slot create_check: id  2 | task 1115 | created context checkpoint 4 of 32 (pos_min = 16867, pos_max = 16867, n_tokens = 16868, size = 184.952 MiB)
2026-05-15 10:44:19.074 | slot update_slots: id  2 | task 1115 | n_tokens = 17380, memory_seq_rm [17380, end)
2026-05-15 10:44:19.077 | slot init_sampler: id  2 | task 1115 | init sampler, took 2.45 ms, tokens: text = 17384, total = 17384
2026-05-15 10:44:19.077 | slot update_slots: id  2 | task 1115 | prompt processing done, n_tokens = 17384, batch.n_tokens = 4
2026-05-15 10:44:19.219 | slot create_check: id  2 | task 1115 | created context checkpoint 5 of 32 (pos_min = 17379, pos_max = 17379, n_tokens = 17380, size = 186.025 MiB)
2026-05-15 10:44:19.255 | srv  log_server_r: done request: POST /v1/chat/completions 172.18.0.1 200
2026-05-15 10:44:19.466 | reasoning-budget: deactivated (natural end)
2026-05-15 10:44:20.397 | slot print_timing: id  2 | task 1115 | 
2026-05-15 10:44:20.397 | prompt eval time =    1819.43 ms /  2806 tokens (    0.65 ms per token,  1542.24 tokens per second)
2026-05-15 10:44:20.397 |        eval time =    1142.14 ms /    97 tokens (   11.77 ms per token,    84.93 tokens per second)
2026-05-15 10:44:20.397 |       total time =    2961.58 ms /  2903 tokens
2026-05-15 10:44:20.397 | draft acceptance rate = 1.00000 (   63 accepted /    63 generated)
2026-05-15 10:44:20.397 | statistics mtp: #calls(b,g,a) = 7 1089 1057, #gen drafts = 1057, #acc drafts = 1057, #gen tokens = 1871, #acc tokens = 1844, dur(b,g,a) = 0.012, 4506.878, 0.483 ms
2026-05-15 10:44:20.398 | slot      release: id  2 | task 1115 | stop processing: n_tokens = 17480, truncated = 0
2026-05-15 10:44:20.398 | srv  update_slots: all slots are idle
2026-05-15 10:44:20.571 | srv  params_from_: Chat format: peg-native
2026-05-15 10:44:20.574 | slot get_availabl: id  2 | task -1 | selected slot by LCP similarity, sim_best = 0.999 (> 0.100 thold), f_keep = 1.000
2026-05-15 10:44:20.575 | reasoning-budget: activated, budget=2147483647 tokens
2026-05-15 10:44:20.575 | slot launch_slot_: id  2 | task -1 | sampler chain: logits -> penalties -> ?dry -> ?top-n-sigma -> top-k -> ?typical -> ?top-p -> min-p -> ?xtc -> ?temp-ext -> dist 
2026-05-15 10:44:20.575 | slot launch_slot_: id  2 | task 1153 | processing task, is_child = 0
2026-05-15 10:44:20.575 | slot update_slots: id  2 | task 1153 | new prompt, n_ctx_slot = 131072, n_keep = 0, task.n_tokens = 17499
2026-05-15 10:44:20.575 | slot update_slots: id  2 | task 1153 | n_tokens = 17480, memory_seq_rm [17480, end)
2026-05-15 10:44:20.576 | slot update_slots: id  2 | task 1153 | prompt processing progress, n_tokens = 17495, batch.n_tokens = 15, progress = 0.999771
2026-05-15 10:44:20.799 | slot create_check: id  2 | task 1153 | created context checkpoint 6 of 32 (pos_min = 17479, pos_max = 17479, n_tokens = 17480, size = 186.234 MiB)
2026-05-15 10:44:20.844 | slot update_slots: id  2 | task 1153 | n_tokens = 17495, memory_seq_rm [17495, end)
2026-05-15 10:44:20.846 | slot init_sampler: id  2 | task 1153 | init sampler, took 2.40 ms, tokens: text = 17499, total = 17499
2026-05-15 10:44:20.846 | slot update_slots: id  2 | task 1153 | prompt processing done, n_tokens = 17499, batch.n_tokens = 4
2026-05-15 10:44:20.884 | srv  log_server_r: done request: POST /v1/chat/completions 172.18.0.1 200
2026-05-15 10:44:21.149 | reasoning-budget: deactivated (natural end)
2026-05-15 10:44:21.770 | slot print_timing: id  2 | task 1153 | 
2026-05-15 10:44:21.771 | prompt eval time =     308.30 ms /    19 tokens (   16.23 ms per token,    61.63 tokens per second)
2026-05-15 10:44:21.771 |        eval time =     886.61 ms /    51 tokens (   17.38 ms per token,    57.52 tokens per second)
2026-05-15 10:44:21.771 |       total time =    1194.91 ms /    70 tokens
2026-05-15 10:44:21.771 | draft acceptance rate = 1.00000 (   27 accepted /    27 generated)
2026-05-15 10:44:21.771 | statistics mtp: #calls(b,g,a) = 8 1112 1072, #gen drafts = 1072, #acc drafts = 1072, #gen tokens = 1898, #acc tokens = 1871, dur(b,g,a) = 0.013, 4591.170, 0.488 ms
2026-05-15 10:44:21.771 | slot      release: id  2 | task 1153 | stop processing: n_tokens = 17549, truncated = 0
2026-05-15 10:44:21.771 | srv  update_slots: all slots are idle
2026-05-15 10:45:06.678 | srv  params_from_: Chat format: peg-native
2026-05-15 10:45:06.680 | slot get_availabl: id  2 | task -1 | selected slot by LCP similarity, sim_best = 0.987 (> 0.100 thold), f_keep = 0.987
2026-05-15 10:45:06.681 | reasoning-budget: activated, budget=2147483647 tokens
2026-05-15 10:45:06.682 | slot launch_slot_: id  2 | task -1 | sampler chain: logits -> penalties -> ?dry -> ?top-n-sigma -> top-k -> ?typical -> ?top-p -> min-p -> ?xtc -> ?temp-ext -> dist 
2026-05-15 10:45:06.682 | slot launch_slot_: id  2 | task 1181 | processing task, is_child = 0
2026-05-15 10:45:06.682 | slot update_slots: id  2 | task 1181 | new prompt, n_ctx_slot = 131072, n_keep = 0, task.n_tokens = 17545
2026-05-15 10:45:06.682 | slot update_slots: id  2 | task 1181 | n_past = 17322, slot.prompt.tokens.size() = 17549, seq_id = 2, pos_min = 17548, n_swa = 0
2026-05-15 10:45:06.682 | slot update_slots: id  2 | task 1181 | Checking checkpoint with [17479, 17479] against 17322...
2026-05-15 10:45:06.682 | slot update_slots: id  2 | task 1181 | Checking checkpoint with [17379, 17379] against 17322...
2026-05-15 10:45:06.682 | slot update_slots: id  2 | task 1181 | Checking checkpoint with [16867, 16867] against 17322...
2026-05-15 10:45:06.758 | slot update_slots: id  2 | task 1181 | restored context checkpoint (pos_min = 16867, pos_max = 16867, n_tokens = 16868, n_past = 16868, size = 184.952 MiB)
2026-05-15 10:45:06.758 | slot update_slots: id  2 | task 1181 | erased invalidated context checkpoint (pos_min = 17379, pos_max = 17379, n_tokens = 17380, n_swa = 0, pos_next = 16868, size = 186.025 MiB)
2026-05-15 10:45:06.769 | slot update_slots: id  2 | task 1181 | erased invalidated context checkpoint (pos_min = 17479, pos_max = 17479, n_tokens = 17480, n_swa = 0, pos_next = 16868, size = 186.234 MiB)
2026-05-15 10:45:06.781 | slot update_slots: id  2 | task 1181 | n_tokens = 16868, memory_seq_rm [16868, end)
2026-05-15 10:45:06.781 | slot update_slots: id  2 | task 1181 | prompt processing progress, n_tokens = 17029, batch.n_tokens = 161, progress = 0.970590
2026-05-15 10:45:06.983 | slot update_slots: id  2 | task 1181 | n_tokens = 17029, memory_seq_rm [17029, end)
2026-05-15 10:45:06.983 | slot update_slots: id  2 | task 1181 | prompt processing progress, n_tokens = 17541, batch.n_tokens = 512, progress = 0.999772
2026-05-15 10:45:07.198 | slot create_check: id  2 | task 1181 | created context checkpoint 5 of 32 (pos_min = 17028, pos_max = 17028, n_tokens = 17029, size = 185.289 MiB)
2026-05-15 10:45:07.411 | slot update_slots: id  2 | task 1181 | n_tokens = 17541, memory_seq_rm [17541, end)
2026-05-15 10:45:07.413 | slot init_sampler: id  2 | task 1181 | init sampler, took 2.49 ms, tokens: text = 17545, total = 17545
2026-05-15 10:45:07.414 | slot update_slots: id  2 | task 1181 | prompt processing done, n_tokens = 17545, batch.n_tokens = 4
2026-05-15 10:45:07.634 | slot create_check: id  2 | task 1181 | created context checkpoint 6 of 32 (pos_min = 17540, pos_max = 17540, n_tokens = 17541, size = 186.362 MiB)
2026-05-15 10:45:07.672 | srv  log_server_r: done request: POST /v1/chat/completions 172.18.0.1 200
2026-05-15 10:45:08.606 | reasoning-budget: deactivated (natural end)
2026-05-15 10:45:09.471 | slot print_timing: id  2 | task 1181 | 
2026-05-15 10:45:09.471 | prompt eval time =     989.75 ms /   677 tokens (    1.46 ms per token,   684.01 tokens per second)
2026-05-15 10:45:09.471 |        eval time =    1799.18 ms /    90 tokens (   19.99 ms per token,    50.02 tokens per second)
2026-05-15 10:45:09.471 |       total time =    2788.93 ms /   767 tokens
2026-05-15 10:45:09.471 | draft acceptance rate = 0.95745 (   45 accepted /    47 generated)
2026-05-15 10:45:09.471 | statistics mtp: #calls(b,g,a) = 9 1156 1100, #gen drafts = 1100, #acc drafts = 1100, #gen tokens = 1945, #acc tokens = 1916, dur(b,g,a) = 0.014, 4750.970, 0.504 ms
2026-05-15 10:45:09.471 | slot      release: id  2 | task 1181 | stop processing: n_tokens = 17634, truncated = 0
2026-05-15 10:45:09.471 | srv  update_slots: all slots are idle
2026-05-15 10:45:27.788 | srv  params_from_: Chat format: peg-native
2026-05-15 10:45:27.790 | slot get_availabl: id  2 | task -1 | selected slot by LCP similarity, sim_best = 0.992 (> 0.100 thold), f_keep = 0.991
2026-05-15 10:45:27.792 | reasoning-budget: activated, budget=2147483647 tokens
2026-05-15 10:45:27.792 | slot launch_slot_: id  2 | task -1 | sampler chain: logits -> penalties -> ?dry -> ?top-n-sigma -> top-k -> ?typical -> ?top-p -> min-p -> ?xtc -> ?temp-ext -> dist 
2026-05-15 10:45:27.792 | slot launch_slot_: id  2 | task 1235 | processing task, is_child = 0
2026-05-15 10:45:27.792 | slot update_slots: id  2 | task 1235 | new prompt, n_ctx_slot = 131072, n_keep = 0, task.n_tokens = 17619
2026-05-15 10:45:27.792 | slot update_slots: id  2 | task 1235 | n_past = 17483, slot.prompt.tokens.size() = 17634, seq_id = 2, pos_min = 17633, n_swa = 0
2026-05-15 10:45:27.792 | slot update_slots: id  2 | task 1235 | Checking checkpoint with [17540, 17540] against 17483...
2026-05-15 10:45:27.792 | slot update_slots: id  2 | task 1235 | Checking checkpoint with [17028, 17028] against 17483...
2026-05-15 10:45:27.867 | slot update_slots: id  2 | task 1235 | restored context checkpoint (pos_min = 17028, pos_max = 17028, n_tokens = 17029, n_past = 17029, size = 185.289 MiB)
2026-05-15 10:45:27.867 | slot update_slots: id  2 | task 1235 | erased invalidated context checkpoint (pos_min = 17540, pos_max = 17540, n_tokens = 17541, n_swa = 0, pos_next = 17029, size = 186.362 MiB)
2026-05-15 10:45:27.878 | slot update_slots: id  2 | task 1235 | n_tokens = 17029, memory_seq_rm [17029, end)
2026-05-15 10:45:27.878 | slot update_slots: id  2 | task 1235 | prompt processing progress, n_tokens = 17103, batch.n_tokens = 74, progress = 0.970713
2026-05-15 10:45:28.006 | slot update_slots: id  2 | task 1235 | n_tokens = 17103, memory_seq_rm [17103, end)
2026-05-15 10:45:28.006 | slot update_slots: id  2 | task 1235 | prompt processing progress, n_tokens = 17615, batch.n_tokens = 512, progress = 0.999773
2026-05-15 10:45:28.154 | slot create_check: id  2 | task 1235 | created context checkpoint 6 of 32 (pos_min = 17102, pos_max = 17102, n_tokens = 17103, size = 185.444 MiB)
2026-05-15 10:45:28.368 | slot update_slots: id  2 | task 1235 | n_tokens = 17615, memory_seq_rm [17615, end)
2026-05-15 10:45:28.371 | slot init_sampler: id  2 | task 1235 | init sampler, took 2.45 ms, tokens: text = 17619, total = 17619
2026-05-15 10:45:28.371 | slot update_slots: id  2 | task 1235 | prompt processing done, n_tokens = 17619, batch.n_tokens = 4
2026-05-15 10:45:28.577 | slot create_check: id  2 | task 1235 | created context checkpoint 7 of 32 (pos_min = 17614, pos_max = 17614, n_tokens = 17615, size = 186.517 MiB)
2026-05-15 10:45:28.616 | srv  log_server_r: done request: POST /v1/chat/completions 172.18.0.1 200
2026-05-15 10:45:28.972 | reasoning-budget: deactivated (natural end)
2026-05-15 10:45:29.550 | slot print_timing: id  2 | task 1235 | 
2026-05-15 10:45:29.550 | prompt eval time =     823.32 ms /   590 tokens (    1.40 ms per token,   716.61 tokens per second)
2026-05-15 10:45:29.550 |        eval time =     934.56 ms /    67 tokens (   13.95 ms per token,    71.69 tokens per second)
2026-05-15 10:45:29.550 |       total time =    1757.88 ms /   657 tokens
2026-05-15 10:45:29.550 | draft acceptance rate = 1.00000 (   42 accepted /    42 generated)
2026-05-15 10:45:29.550 | statistics mtp: #calls(b,g,a) = 10 1180 1123, #gen drafts = 1123, #acc drafts = 1123, #gen tokens = 1987, #acc tokens = 1958, dur(b,g,a) = 0.016, 4857.514, 0.512 ms
2026-05-15 10:45:29.551 | slot      release: id  2 | task 1235 | stop processing: n_tokens = 17685, truncated = 0
2026-05-15 10:45:29.551 | srv  update_slots: all slots are idle
2026-05-15 10:45:29.795 | srv  params_from_: Chat format: peg-native
2026-05-15 10:45:29.798 | slot get_availabl: id  2 | task -1 | selected slot by LCP similarity, sim_best = 0.999 (> 0.100 thold), f_keep = 1.000
2026-05-15 10:45:29.799 | reasoning-budget: activated, budget=2147483647 tokens
2026-05-15 10:45:29.799 | slot launch_slot_: id  2 | task -1 | sampler chain: logits -> penalties -> ?dry -> ?top-n-sigma -> top-k -> ?typical -> ?top-p -> min-p -> ?xtc -> ?temp-ext -> dist 
2026-05-15 10:45:29.799 | slot launch_slot_: id  2 | task 1264 | processing task, is_child = 0
2026-05-15 10:45:29.799 | slot update_slots: id  2 | task 1264 | new prompt, n_ctx_slot = 131072, n_keep = 0, task.n_tokens = 17703
2026-05-15 10:45:29.799 | slot update_slots: id  2 | task 1264 | n_tokens = 17685, memory_seq_rm [17685, end)
2026-05-15 10:45:29.800 | slot update_slots: id  2 | task 1264 | prompt processing progress, n_tokens = 17699, batch.n_tokens = 14, progress = 0.999774
2026-05-15 10:45:30.009 | slot create_check: id  2 | task 1264 | created context checkpoint 8 of 32 (pos_min = 17684, pos_max = 17684, n_tokens = 17685, size = 186.663 MiB)
2026-05-15 10:45:30.052 | slot update_slots: id  2 | task 1264 | n_tokens = 17699, memory_seq_rm [17699, end)
2026-05-15 10:45:30.055 | slot init_sampler: id  2 | task 1264 | init sampler, took 2.41 ms, tokens: text = 17703, total = 17703
2026-05-15 10:45:30.055 | slot update_slots: id  2 | task 1264 | prompt processing done, n_tokens = 17703, batch.n_tokens = 4
2026-05-15 10:45:30.093 | srv  log_server_r: done request: POST /v1/chat/completions 172.18.0.1 200
2026-05-15 10:45:30.386 | reasoning-budget: deactivated (natural end)
2026-05-15 10:45:30.868 | slot print_timing: id  2 | task 1264 | 
2026-05-15 10:45:30.868 | prompt eval time =     293.39 ms /    18 tokens (   16.30 ms per token,    61.35 tokens per second)
2026-05-15 10:45:30.868 |        eval time =     775.15 ms /    58 tokens (   13.36 ms per token,    74.82 tokens per second)
2026-05-15 10:45:30.869 |       total time =    1068.55 ms /    76 tokens
2026-05-15 10:45:30.869 | draft acceptance rate = 0.97222 (   35 accepted /    36 generated)
2026-05-15 10:45:30.869 | statistics mtp: #calls(b,g,a) = 11 1202 1141, #gen drafts = 1141, #acc drafts = 1141, #gen tokens = 2023, #acc tokens = 1993, dur(b,g,a) = 0.017, 4945.142, 0.520 ms
2026-05-15 10:45:30.869 | slot      release: id  2 | task 1264 | stop processing: n_tokens = 17760, truncated = 0
2026-05-15 10:45:30.869 | srv  update_slots: all slots are idle
2026-05-15 10:45:31.038 | srv  params_from_: Chat format: peg-native
2026-05-15 10:45:31.040 | slot get_availabl: id  2 | task -1 | selected slot by LCP similarity, sim_best = 0.987 (> 0.100 thold), f_keep = 1.000
2026-05-15 10:45:31.041 | reasoning-budget: activated, budget=2147483647 tokens
2026-05-15 10:45:31.042 | slot launch_slot_: id  2 | task -1 | sampler chain: logits -> penalties -> ?dry -> ?top-n-sigma -> top-k -> ?typical -> ?top-p -> min-p -> ?xtc -> ?temp-ext -> dist 
2026-05-15 10:45:31.042 | slot launch_slot_: id  2 | task 1290 | processing task, is_child = 0
2026-05-15 10:45:31.042 | slot update_slots: id  2 | task 1290 | new prompt, n_ctx_slot = 131072, n_keep = 0, task.n_tokens = 17986
2026-05-15 10:45:31.042 | slot update_slots: id  2 | task 1290 | n_tokens = 17760, memory_seq_rm [17760, end)
2026-05-15 10:45:31.042 | slot update_slots: id  2 | task 1290 | prompt processing progress, n_tokens = 17982, batch.n_tokens = 222, progress = 0.999778
2026-05-15 10:45:31.264 | slot create_check: id  2 | task 1290 | created context checkpoint 9 of 32 (pos_min = 17759, pos_max = 17759, n_tokens = 17760, size = 186.820 MiB)
2026-05-15 10:45:31.374 | slot update_slots: id  2 | task 1290 | n_tokens = 17982, memory_seq_rm [17982, end)
2026-05-15 10:45:31.376 | slot init_sampler: id  2 | task 1290 | init sampler, took 2.47 ms, tokens: text = 17986, total = 17986
2026-05-15 10:45:31.376 | slot update_slots: id  2 | task 1290 | prompt processing done, n_tokens = 17986, batch.n_tokens = 4
2026-05-15 10:45:31.596 | slot create_check: id  2 | task 1290 | created context checkpoint 10 of 32 (pos_min = 17981, pos_max = 17981, n_tokens = 17982, size = 187.285 MiB)
2026-05-15 10:45:31.634 | srv  log_server_r: done request: POST /v1/chat/completions 172.18.0.1 200
2026-05-15 10:45:32.712 | reasoning-budget: deactivated (natural end)
2026-05-15 10:45:34.228 | slot print_timing: id  2 | task 1290 | 
2026-05-15 10:45:34.228 | prompt eval time =     591.75 ms /   226 tokens (    2.62 ms per token,   381.92 tokens per second)
2026-05-15 10:45:34.228 |        eval time =    2594.46 ms /   135 tokens (   19.22 ms per token,    52.03 tokens per second)
2026-05-15 10:45:34.228 |       total time =    3186.21 ms /   361 tokens
2026-05-15 10:45:34.228 | draft acceptance rate = 0.98529 (   67 accepted /    68 generated)
2026-05-15 10:45:34.228 | statistics mtp: #calls(b,g,a) = 12 1269 1183, #gen drafts = 1183, #acc drafts = 1183, #gen tokens = 2091, #acc tokens = 2060, dur(b,g,a) = 0.018, 5184.802, 0.543 ms
2026-05-15 10:45:34.229 | slot      release: id  2 | task 1290 | stop processing: n_tokens = 18120, truncated = 0
2026-05-15 10:45:34.229 | srv  update_slots: all slots are idle
2026-05-15 10:46:07.918 | srv  params_from_: Chat format: peg-native
2026-05-15 10:46:07.920 | slot get_availabl: id  2 | task -1 | selected slot by LCP similarity, sim_best = 0.972 (> 0.100 thold), f_keep = 0.969
2026-05-15 10:46:07.922 | reasoning-budget: activated, budget=2147483647 tokens
2026-05-15 10:46:07.922 | slot launch_slot_: id  2 | task -1 | sampler chain: logits -> penalties -> ?dry -> ?top-n-sigma -> top-k -> ?typical -> ?top-p -> min-p -> ?xtc -> ?temp-ext -> dist 
2026-05-15 10:46:07.922 | slot launch_slot_: id  2 | task 1365 | processing task, is_child = 0
2026-05-15 10:46:07.922 | slot update_slots: id  2 | task 1365 | new prompt, n_ctx_slot = 131072, n_keep = 0, task.n_tokens = 18057
2026-05-15 10:46:07.922 | slot update_slots: id  2 | task 1365 | n_past = 17557, slot.prompt.tokens.size() = 18120, seq_id = 2, pos_min = 18119, n_swa = 0
2026-05-15 10:46:07.922 | slot update_slots: id  2 | task 1365 | Checking checkpoint with [17981, 17981] against 17557...
2026-05-15 10:46:07.922 | slot update_slots: id  2 | task 1365 | Checking checkpoint with [17759, 17759] against 17557...
2026-05-15 10:46:07.922 | slot update_slots: id  2 | task 1365 | Checking checkpoint with [17684, 17684] against 17557...
2026-05-15 10:46:07.922 | slot update_slots: id  2 | task 1365 | Checking checkpoint with [17614, 17614] against 17557...
2026-05-15 10:46:07.922 | slot update_slots: id  2 | task 1365 | Checking checkpoint with [17102, 17102] against 17557...
2026-05-15 10:46:07.998 | slot update_slots: id  2 | task 1365 | restored context checkpoint (pos_min = 17102, pos_max = 17102, n_tokens = 17103, n_past = 17103, size = 185.444 MiB)
2026-05-15 10:46:07.998 | slot update_slots: id  2 | task 1365 | erased invalidated context checkpoint (pos_min = 17614, pos_max = 17614, n_tokens = 17615, n_swa = 0, pos_next = 17103, size = 186.517 MiB)
2026-05-15 10:46:08.009 | slot update_slots: id  2 | task 1365 | erased invalidated context checkpoint (pos_min = 17684, pos_max = 17684, n_tokens = 17685, n_swa = 0, pos_next = 17103, size = 186.663 MiB)
2026-05-15 10:46:08.021 | slot update_slots: id  2 | task 1365 | erased invalidated context checkpoint (pos_min = 17759, pos_max = 17759, n_tokens = 17760, n_swa = 0, pos_next = 17103, size = 186.820 MiB)
2026-05-15 10:46:08.032 | slot update_slots: id  2 | task 1365 | erased invalidated context checkpoint (pos_min = 17981, pos_max = 17981, n_tokens = 17982, n_swa = 0, pos_next = 17103, size = 187.285 MiB)
2026-05-15 10:46:08.044 | slot update_slots: id  2 | task 1365 | n_tokens = 17103, memory_seq_rm [17103, end)
2026-05-15 10:46:08.044 | slot update_slots: id  2 | task 1365 | prompt processing progress, n_tokens = 17541, batch.n_tokens = 438, progress = 0.971424
2026-05-15 10:46:08.333 | slot update_slots: id  2 | task 1365 | n_tokens = 17541, memory_seq_rm [17541, end)
2026-05-15 10:46:08.333 | slot update_slots: id  2 | task 1365 | prompt processing progress, n_tokens = 18053, batch.n_tokens = 512, progress = 0.999778
2026-05-15 10:46:08.552 | slot create_check: id  2 | task 1365 | created context checkpoint 7 of 32 (pos_min = 17540, pos_max = 17540, n_tokens = 17541, size = 186.362 MiB)
2026-05-15 10:46:08.768 | slot update_slots: id  2 | task 1365 | n_tokens = 18053, memory_seq_rm [18053, end)
2026-05-15 10:46:08.770 | slot init_sampler: id  2 | task 1365 | init sampler, took 2.48 ms, tokens: text = 18057, total = 18057
2026-05-15 10:46:08.770 | slot update_slots: id  2 | task 1365 | prompt processing done, n_tokens = 18057, batch.n_tokens = 4
2026-05-15 10:46:08.993 | slot create_check: id  2 | task 1365 | created context checkpoint 8 of 32 (pos_min = 18052, pos_max = 18052, n_tokens = 18053, size = 187.434 MiB)
2026-05-15 10:46:09.033 | srv  log_server_r: done request: POST /v1/chat/completions 172.18.0.1 200
2026-05-15 10:46:10.123 | reasoning-budget: deactivated (natural end)
2026-05-15 10:46:13.806 | slot print_timing: id  2 | task 1365 | 
2026-05-15 10:46:13.806 | prompt eval time =    1111.13 ms /   954 tokens (    1.16 ms per token,   858.58 tokens per second)
2026-05-15 10:46:13.809 |        eval time =    4772.76 ms /   305 tokens (   15.65 ms per token,    63.90 tokens per second)
2026-05-15 10:46:13.809 |       total time =    5883.89 ms /  1259 tokens
2026-05-15 10:46:13.809 | draft acceptance rate = 0.97253 (  177 accepted /   182 generated)
2026-05-15 10:46:13.809 | statistics mtp: #calls(b,g,a) = 13 1396 1285, #gen drafts = 1285, #acc drafts = 1285, #gen tokens = 2273, #acc tokens = 2237, dur(b,g,a) = 0.019, 5678.268, 0.585 ms
2026-05-15 10:46:13.809 | slot      release: id  2 | task 1365 | stop processing: n_tokens = 18361, truncated = 0
2026-05-15 10:46:13.809 | srv  update_slots: all slots are idle
2026-05-15 10:46:13.998 | srv  params_from_: Chat format: peg-native
2026-05-15 10:46:14.001 | slot get_availabl: id  2 | task -1 | selected slot by LCP similarity, sim_best = 0.999 (> 0.100 thold), f_keep = 1.000
2026-05-15 10:46:14.002 | reasoning-budget: activated, budget=2147483647 tokens
2026-05-15 10:46:14.002 | slot launch_slot_: id  2 | task -1 | sampler chain: logits -> penalties -> ?dry -> ?top-n-sigma -> top-k -> ?typical -> ?top-p -> min-p -> ?xtc -> ?temp-ext -> dist 
2026-05-15 10:46:14.002 | slot launch_slot_: id  2 | task 1507 | processing task, is_child = 0
2026-05-15 10:46:14.002 | slot update_slots: id  2 | task 1507 | new prompt, n_ctx_slot = 131072, n_keep = 0, task.n_tokens = 18381
2026-05-15 10:46:14.002 | slot update_slots: id  2 | task 1507 | n_tokens = 18361, memory_seq_rm [18361, end)
2026-05-15 10:46:14.002 | slot update_slots: id  2 | task 1507 | prompt processing progress, n_tokens = 18377, batch.n_tokens = 16, progress = 0.999782
2026-05-15 10:46:14.227 | slot create_check: id  2 | task 1507 | created context checkpoint 9 of 32 (pos_min = 18360, pos_max = 18360, n_tokens = 18361, size = 188.079 MiB)
2026-05-15 10:46:14.269 | slot update_slots: id  2 | task 1507 | n_tokens = 18377, memory_seq_rm [18377, end)
2026-05-15 10:46:14.272 | slot init_sampler: id  2 | task 1507 | init sampler, took 2.57 ms, tokens: text = 18381, total = 18381
2026-05-15 10:46:14.272 | slot update_slots: id  2 | task 1507 | prompt processing done, n_tokens = 18381, batch.n_tokens = 4
2026-05-15 10:46:14.313 | srv  log_server_r: done request: POST /v1/chat/completions 172.18.0.1 200
2026-05-15 10:46:12.320 | reasoning-budget: deactivated (natural end)
2026-05-15 10:46:13.093 | slot print_timing: id  2 | task 1507 | 
2026-05-15 10:46:13.093 | prompt eval time =     309.68 ms /    20 tokens (   15.48 ms per token,    64.58 tokens per second)
2026-05-15 10:46:13.093 |        eval time =    1085.84 ms /    79 tokens (   13.74 ms per token,    72.75 tokens per second)
2026-05-15 10:46:13.093 |       total time =    1395.53 ms /    99 tokens
2026-05-15 10:46:13.093 | draft acceptance rate = 1.00000 (   49 accepted /    49 generated)
2026-05-15 10:46:13.093 | statistics mtp: #calls(b,g,a) = 14 1425 1311, #gen drafts = 1311, #acc drafts = 1311, #gen tokens = 2322, #acc tokens = 2286, dur(b,g,a) = 0.021, 5798.895, 0.600 ms
2026-05-15 10:46:13.093 | slot      release: id  2 | task 1507 | stop processing: n_tokens = 18459, truncated = 0
2026-05-15 10:46:13.093 | srv  update_slots: all slots are idle
2026-05-15 10:46:13.181 | srv    operator(): got exception: {"error":{"code":400,"message":"Assistant response prefill is incompatible with enable_thinking.","type":"invalid_request_error"}}
2026-05-15 10:46:13.181 | srv  log_server_r: done request: POST /v1/chat/completions 172.18.0.1 400
2026-05-15 10:46:30.146 | srv  params_from_: Chat format: peg-native
2026-05-15 10:46:30.149 | slot get_availabl: id  2 | task -1 | selected slot by LCP similarity, sim_best = 0.976 (> 0.100 thold), f_keep = 0.975
2026-05-15 10:46:30.150 | reasoning-budget: activated, budget=2147483647 tokens
2026-05-15 10:46:30.150 | slot launch_slot_: id  2 | task -1 | sampler chain: logits -> penalties -> ?dry -> ?top-n-sigma -> top-k -> ?typical -> ?top-p -> min-p -> ?xtc -> ?temp-ext -> dist 
2026-05-15 10:46:30.150 | slot launch_slot_: id  2 | task 1540 | processing task, is_child = 0
2026-05-15 10:46:30.150 | slot update_slots: id  2 | task 1540 | new prompt, n_ctx_slot = 131072, n_keep = 0, task.n_tokens = 18444
2026-05-15 10:46:30.150 | slot update_slots: id  2 | task 1540 | n_past = 17995, slot.prompt.tokens.size() = 18459, seq_id = 2, pos_min = 18458, n_swa = 0
2026-05-15 10:46:30.150 | slot update_slots: id  2 | task 1540 | Checking checkpoint with [18360, 18360] against 17995...
2026-05-15 10:46:30.150 | slot update_slots: id  2 | task 1540 | Checking checkpoint with [18052, 18052] against 17995...
2026-05-15 10:46:30.150 | slot update_slots: id  2 | task 1540 | Checking checkpoint with [17540, 17540] against 17995...
2026-05-15 10:46:30.226 | slot update_slots: id  2 | task 1540 | restored context checkpoint (pos_min = 17540, pos_max = 17540, n_tokens = 17541, n_past = 17541, size = 186.362 MiB)
2026-05-15 10:46:30.226 | slot update_slots: id  2 | task 1540 | erased invalidated context checkpoint (pos_min = 18052, pos_max = 18052, n_tokens = 18053, n_swa = 0, pos_next = 17541, size = 187.434 MiB)
2026-05-15 10:46:30.238 | slot update_slots: id  2 | task 1540 | erased invalidated context checkpoint (pos_min = 18360, pos_max = 18360, n_tokens = 18361, n_swa = 0, pos_next = 17541, size = 188.079 MiB)
2026-05-15 10:46:30.249 | slot update_slots: id  2 | task 1540 | n_tokens = 17541, memory_seq_rm [17541, end)
2026-05-15 10:46:30.249 | slot update_slots: id  2 | task 1540 | prompt processing progress, n_tokens = 17928, batch.n_tokens = 387, progress = 0.972023
2026-05-15 10:46:30.662 | slot update_slots: id  2 | task 1540 | n_tokens = 17928, memory_seq_rm [17928, end)
2026-05-15 10:46:30.662 | slot update_slots: id  2 | task 1540 | prompt processing progress, n_tokens = 18440, batch.n_tokens = 512, progress = 0.999783
2026-05-15 10:46:30.804 | slot create_check: id  2 | task 1540 | created context checkpoint 8 of 32 (pos_min = 17927, pos_max = 17927, n_tokens = 17928, size = 187.172 MiB)
2026-05-15 10:46:31.020 | slot update_slots: id  2 | task 1540 | n_tokens = 18440, memory_seq_rm [18440, end)
2026-05-15 10:46:31.023 | slot init_sampler: id  2 | task 1540 | init sampler, took 2.55 ms, tokens: text = 18444, total = 18444
2026-05-15 10:46:31.023 | slot update_slots: id  2 | task 1540 | prompt processing done, n_tokens = 18444, batch.n_tokens = 4
2026-05-15 10:46:31.247 | slot create_check: id  2 | task 1540 | created context checkpoint 9 of 32 (pos_min = 18439, pos_max = 18439, n_tokens = 18440, size = 188.244 MiB)
2026-05-15 10:46:31.286 | srv  log_server_r: done request: POST /v1/chat/completions 172.18.0.1 200
2026-05-15 10:46:31.627 | reasoning-budget: deactivated (natural end)
2026-05-15 10:46:32.251 | slot print_timing: id  2 | task 1540 | 
2026-05-15 10:46:32.251 | prompt eval time =    1134.66 ms /   903 tokens (    1.26 ms per token,   795.83 tokens per second)
2026-05-15 10:46:32.251 |        eval time =     965.57 ms /    85 tokens (   11.36 ms per token,    88.03 tokens per second)
2026-05-15 10:46:32.251 |       total time =    2100.24 ms /   988 tokens
2026-05-15 10:46:32.251 | draft acceptance rate = 1.00000 (   54 accepted /    54 generated)
2026-05-15 10:46:32.251 | statistics mtp: #calls(b,g,a) = 15 1455 1338, #gen drafts = 1338, #acc drafts = 1338, #gen tokens = 2376, #acc tokens = 2340, dur(b,g,a) = 0.022, 5922.991, 0.612 ms
2026-05-15 10:46:32.251 | slot      release: id  2 | task 1540 | stop processing: n_tokens = 18528, truncated = 0
2026-05-15 10:46:32.251 | srv  update_slots: all slots are idle
2026-05-15 10:46:32.433 | srv  params_from_: Chat format: peg-native
2026-05-15 10:46:32.436 | slot get_availabl: id  2 | task -1 | selected slot by LCP similarity, sim_best = 0.996 (> 0.100 thold), f_keep = 1.000
2026-05-15 10:46:32.437 | reasoning-budget: activated, budget=2147483647 tokens
2026-05-15 10:46:32.437 | slot launch_slot_: id  2 | task -1 | sampler chain: logits -> penalties -> ?dry -> ?top-n-sigma -> top-k -> ?typical -> ?top-p -> min-p -> ?xtc -> ?temp-ext -> dist 
2026-05-15 10:46:32.437 | slot launch_slot_: id  2 | task 1574 | processing task, is_child = 0
2026-05-15 10:46:32.437 | slot update_slots: id  2 | task 1574 | new prompt, n_ctx_slot = 131072, n_keep = 0, task.n_tokens = 18602
2026-05-15 10:46:32.437 | slot update_slots: id  2 | task 1574 | n_tokens = 18528, memory_seq_rm [18528, end)
2026-05-15 10:46:32.438 | slot update_slots: id  2 | task 1574 | prompt processing progress, n_tokens = 18598, batch.n_tokens = 70, progress = 0.999785
2026-05-15 10:46:32.662 | slot create_check: id  2 | task 1574 | created context checkpoint 10 of 32 (pos_min = 18527, pos_max = 18527, n_tokens = 18528, size = 188.429 MiB)
2026-05-15 10:46:32.719 | slot update_slots: id  2 | task 1574 | n_tokens = 18598, memory_seq_rm [18598, end)
2026-05-15 10:46:32.722 | slot init_sampler: id  2 | task 1574 | init sampler, took 2.60 ms, tokens: text = 18602, total = 18602
2026-05-15 10:46:32.722 | slot update_slots: id  2 | task 1574 | prompt processing done, n_tokens = 18602, batch.n_tokens = 4
2026-05-15 10:46:32.946 | slot create_check: id  2 | task 1574 | created context checkpoint 11 of 32 (pos_min = 18597, pos_max = 18597, n_tokens = 18598, size = 188.575 MiB)
2026-05-15 10:46:32.984 | srv  log_server_r: done request: POST /v1/chat/completions 172.18.0.1 200
2026-05-15 10:46:33.286 | reasoning-budget: deactivated (natural end)
2026-05-15 10:46:33.806 | slot print_timing: id  2 | task 1574 | 
2026-05-15 10:46:33.806 | prompt eval time =     545.62 ms /    74 tokens (    7.37 ms per token,   135.62 tokens per second)
2026-05-15 10:46:33.806 |        eval time =     822.42 ms /    58 tokens (   14.18 ms per token,    70.52 tokens per second)
2026-05-15 10:46:33.806 |       total time =    1368.05 ms /   132 tokens
2026-05-15 10:46:33.806 | draft acceptance rate = 1.00000 (   35 accepted /    35 generated)
2026-05-15 10:46:33.806 | statistics mtp: #calls(b,g,a) = 16 1477 1358, #gen drafts = 1358, #acc drafts = 1358, #gen tokens = 2411, #acc tokens = 2375, dur(b,g,a) = 0.023, 6015.997, 0.622 ms
2026-05-15 10:46:33.807 | slot      release: id  2 | task 1574 | stop processing: n_tokens = 18659, truncated = 0
2026-05-15 10:46:33.807 | srv  update_slots: all slots are idle
2026-05-15 10:46:33.986 | srv  params_from_: Chat format: peg-native
2026-05-15 10:46:33.989 | slot get_availabl: id  2 | task -1 | selected slot by LCP similarity, sim_best = 0.991 (> 0.100 thold), f_keep = 1.000
2026-05-15 10:46:33.990 | reasoning-budget: activated, budget=2147483647 tokens
2026-05-15 10:46:33.990 | slot launch_slot_: id  2 | task -1 | sampler chain: logits -> penalties -> ?dry -> ?top-n-sigma -> top-k -> ?typical -> ?top-p -> min-p -> ?xtc -> ?temp-ext -> dist 
2026-05-15 10:46:33.990 | slot launch_slot_: id  2 | task 1600 | processing task, is_child = 0
2026-05-15 10:46:33.990 | slot update_slots: id  2 | task 1600 | new prompt, n_ctx_slot = 131072, n_keep = 0, task.n_tokens = 18823
2026-05-15 10:46:33.990 | slot update_slots: id  2 | task 1600 | n_tokens = 18659, memory_seq_rm [18659, end)
2026-05-15 10:46:33.991 | slot update_slots: id  2 | task 1600 | prompt processing progress, n_tokens = 18819, batch.n_tokens = 160, progress = 0.999788
2026-05-15 10:46:34.079 | slot update_slots: id  2 | task 1600 | n_tokens = 18819, memory_seq_rm [18819, end)
2026-05-15 10:46:34.081 | slot init_sampler: id  2 | task 1600 | init sampler, took 2.63 ms, tokens: text = 18823, total = 18823
2026-05-15 10:46:34.081 | slot update_slots: id  2 | task 1600 | prompt processing done, n_tokens = 18823, batch.n_tokens = 4
2026-05-15 10:46:34.307 | slot create_check: id  2 | task 1600 | created context checkpoint 12 of 32 (pos_min = 18818, pos_max = 18818, n_tokens = 18819, size = 189.038 MiB)
2026-05-15 10:46:34.344 | srv  log_server_r: done request: POST /v1/chat/completions 172.18.0.1 200
2026-05-15 10:46:34.768 | reasoning-budget: deactivated (natural end)
2026-05-15 10:46:36.403 | slot print_timing: id  2 | task 1600 | 
2026-05-15 10:46:36.403 | prompt eval time =     352.97 ms /   164 tokens (    2.15 ms per token,   464.63 tokens per second)
2026-05-15 10:46:36.403 |        eval time =    2059.06 ms /   127 tokens (   16.21 ms per token,    61.68 tokens per second)
2026-05-15 10:46:36.403 |       total time =    2412.03 ms /   291 tokens
2026-05-15 10:46:36.403 | draft acceptance rate = 1.00000 (   72 accepted /    72 generated)
2026-05-15 10:46:36.403 | statistics mtp: #calls(b,g,a) = 17 1531 1399, #gen drafts = 1399, #acc drafts = 1399, #gen tokens = 2483, #acc tokens = 2447, dur(b,g,a) = 0.025, 6230.751, 0.640 ms
2026-05-15 10:46:36.403 | slot      release: id  2 | task 1600 | stop processing: n_tokens = 18949, truncated = 0
2026-05-15 10:46:36.403 | srv  update_slots: all slots are idle
2026-05-15 10:47:34.035 | srv  params_from_: Chat format: peg-native
2026-05-15 10:47:34.037 | slot get_availabl: id  2 | task -1 | selected slot by LCP similarity, sim_best = 0.966 (> 0.100 thold), f_keep = 0.970
2026-05-15 10:47:34.038 | reasoning-budget: activated, budget=2147483647 tokens
2026-05-15 10:47:34.038 | slot launch_slot_: id  2 | task -1 | sampler chain: logits -> penalties -> ?dry -> ?top-n-sigma -> top-k -> ?typical -> ?top-p -> min-p -> ?xtc -> ?temp-ext -> dist 
2026-05-15 10:47:34.038 | slot launch_slot_: id  2 | task 1660 | processing task, is_child = 0
2026-05-15 10:47:34.038 | slot update_slots: id  2 | task 1660 | new prompt, n_ctx_slot = 131072, n_keep = 0, task.n_tokens = 19032
2026-05-15 10:47:34.038 | slot update_slots: id  2 | task 1660 | n_past = 18382, slot.prompt.tokens.size() = 18949, seq_id = 2, pos_min = 18948, n_swa = 0
2026-05-15 10:47:34.039 | slot update_slots: id  2 | task 1660 | Checking checkpoint with [18818, 18818] against 18382...
2026-05-15 10:47:34.039 | slot update_slots: id  2 | task 1660 | Checking checkpoint with [18597, 18597] against 18382...
2026-05-15 10:47:34.039 | slot update_slots: id  2 | task 1660 | Checking checkpoint with [18527, 18527] against 18382...
2026-05-15 10:47:34.039 | slot update_slots: id  2 | task 1660 | Checking checkpoint with [18439, 18439] against 18382...
2026-05-15 10:47:34.039 | slot update_slots: id  2 | task 1660 | Checking checkpoint with [17927, 17927] against 18382...
2026-05-15 10:47:34.114 | slot update_slots: id  2 | task 1660 | restored context checkpoint (pos_min = 17927, pos_max = 17927, n_tokens = 17928, n_past = 17928, size = 187.172 MiB)
2026-05-15 10:47:34.114 | slot update_slots: id  2 | task 1660 | erased invalidated context checkpoint (pos_min = 18439, pos_max = 18439, n_tokens = 18440, n_swa = 0, pos_next = 17928, size = 188.244 MiB)
2026-05-15 10:47:34.126 | slot update_slots: id  2 | task 1660 | erased invalidated context checkpoint (pos_min = 18527, pos_max = 18527, n_tokens = 18528, n_swa = 0, pos_next = 17928, size = 188.429 MiB)
2026-05-15 10:47:34.137 | slot update_slots: id  2 | task 1660 | erased invalidated context checkpoint (pos_min = 18597, pos_max = 18597, n_tokens = 18598, n_swa = 0, pos_next = 17928, size = 188.575 MiB)
2026-05-15 10:47:34.149 | slot update_slots: id  2 | task 1660 | erased invalidated context checkpoint (pos_min = 18818, pos_max = 18818, n_tokens = 18819, n_swa = 0, pos_next = 17928, size = 189.038 MiB)
2026-05-15 10:47:34.161 | slot update_slots: id  2 | task 1660 | n_tokens = 17928, memory_seq_rm [17928, end)
2026-05-15 10:47:34.161 | slot update_slots: id  2 | task 1660 | prompt processing progress, n_tokens = 18516, batch.n_tokens = 588, progress = 0.972888
2026-05-15 10:47:34.609 | slot update_slots: id  2 | task 1660 | n_tokens = 18516, memory_seq_rm [18516, end)
2026-05-15 10:47:34.609 | slot update_slots: id  2 | task 1660 | prompt processing progress, n_tokens = 19028, batch.n_tokens = 512, progress = 0.999790
2026-05-15 10:47:34.772 | slot create_check: id  2 | task 1660 | created context checkpoint 9 of 32 (pos_min = 18515, pos_max = 18515, n_tokens = 18516, size = 188.404 MiB)
2026-05-15 10:47:34.989 | slot update_slots: id  2 | task 1660 | n_tokens = 19028, memory_seq_rm [19028, end)
2026-05-15 10:47:34.992 | slot init_sampler: id  2 | task 1660 | init sampler, took 2.67 ms, tokens: text = 19032, total = 19032
2026-05-15 10:47:34.992 | slot update_slots: id  2 | task 1660 | prompt processing done, n_tokens = 19032, batch.n_tokens = 4
2026-05-15 10:47:35.137 | slot create_check: id  2 | task 1660 | created context checkpoint 10 of 32 (pos_min = 19027, pos_max = 19027, n_tokens = 19028, size = 189.476 MiB)
2026-05-15 10:47:35.175 | srv  log_server_r: done request: POST /v1/chat/completions 172.18.0.1 200
2026-05-15 10:47:35.499 | reasoning-budget: deactivated (natural end)
2026-05-15 10:47:36.342 | slot print_timing: id  2 | task 1660 | 
2026-05-15 10:47:36.342 | prompt eval time =    1135.92 ms /  1104 tokens (    1.03 ms per token,   971.90 tokens per second)
2026-05-15 10:47:36.342 |        eval time =    1166.82 ms /    85 tokens (   13.73 ms per token,    72.85 tokens per second)
2026-05-15 10:47:36.342 |       total time =    2302.74 ms /  1189 tokens
2026-05-15 10:47:36.342 | draft acceptance rate = 0.98148 (   53 accepted /    54 generated)
2026-05-15 10:47:36.342 | statistics mtp: #calls(b,g,a) = 18 1562 1427, #gen drafts = 1427, #acc drafts = 1427, #gen tokens = 2537, #acc tokens = 2500, dur(b,g,a) = 0.026, 6360.880, 0.651 ms
2026-05-15 10:47:36.342 | slot      release: id  2 | task 1660 | stop processing: n_tokens = 19116, truncated = 0
2026-05-15 10:47:36.342 | srv  update_slots: all slots are idle
2026-05-15 10:47:36.525 | srv  params_from_: Chat format: peg-native
2026-05-15 10:47:36.528 | slot get_availabl: id  2 | task -1 | selected slot by LCP similarity, sim_best = 0.988 (> 0.100 thold), f_keep = 1.000
2026-05-15 10:47:36.529 | reasoning-budget: activated, budget=2147483647 tokens
2026-05-15 10:47:36.529 | slot launch_slot_: id  2 | task -1 | sampler chain: logits -> penalties -> ?dry -> ?top-n-sigma -> top-k -> ?typical -> ?top-p -> min-p -> ?xtc -> ?temp-ext -> dist 
2026-05-15 10:47:36.529 | slot launch_slot_: id  2 | task 1697 | processing task, is_child = 0
2026-05-15 10:47:36.529 | slot update_slots: id  2 | task 1697 | new prompt, n_ctx_slot = 131072, n_keep = 0, task.n_tokens = 19341
2026-05-15 10:47:36.529 | slot update_slots: id  2 | task 1697 | n_tokens = 19116, memory_seq_rm [19116, end)
2026-05-15 10:47:36.530 | slot update_slots: id  2 | task 1697 | prompt processing progress, n_tokens = 19337, batch.n_tokens = 221, progress = 0.999793
2026-05-15 10:47:36.758 | slot create_check: id  2 | task 1697 | created context checkpoint 11 of 32 (pos_min = 19115, pos_max = 19115, n_tokens = 19116, size = 189.660 MiB)
2026-05-15 10:47:36.867 | slot update_slots: id  2 | task 1697 | n_tokens = 19337, memory_seq_rm [19337, end)
2026-05-15 10:47:36.869 | slot init_sampler: id  2 | task 1697 | init sampler, took 2.71 ms, tokens: text = 19341, total = 19341
2026-05-15 10:47:36.869 | slot update_slots: id  2 | task 1697 | prompt processing done, n_tokens = 19341, batch.n_tokens = 4
2026-05-15 10:47:37.094 | slot create_check: id  2 | task 1697 | created context checkpoint 12 of 32 (pos_min = 19336, pos_max = 19336, n_tokens = 19337, size = 190.123 MiB)
2026-05-15 10:47:37.133 | srv  log_server_r: done request: POST /v1/chat/completions 172.18.0.1 200
2026-05-15 10:47:37.408 | reasoning-budget: deactivated (natural end)
2026-05-15 10:47:40.190 | slot print_timing: id  2 | task 1697 | 
2026-05-15 10:47:40.190 | prompt eval time =     602.80 ms /   225 tokens (    2.68 ms per token,   373.26 tokens per second)
2026-05-15 10:47:40.190 |        eval time =     558.72 ms /    32 tokens (   17.46 ms per token,    57.27 tokens per second)
2026-05-15 10:47:40.190 |       total time =    1161.52 ms /   257 tokens
2026-05-15 10:47:40.190 | draft acceptance rate = 0.94737 (   18 accepted /    19 generated)
2026-05-15 10:47:40.190 | statistics mtp: #calls(b,g,a) = 19 1575 1438, #gen drafts = 1438, #acc drafts = 1438, #gen tokens = 2556, #acc tokens = 2518, dur(b,g,a) = 0.027, 6415.450, 0.657 ms
2026-05-15 10:47:40.191 | slot      release: id  2 | task 1697 | stop processing: n_tokens = 19372, truncated = 0
2026-05-15 10:47:40.191 | srv  update_slots: all slots are idle
2026-05-15 10:47:46.119 | srv  params_from_: Chat format: peg-native
2026-05-15 10:47:46.121 | slot get_availabl: id  2 | task -1 | selected slot by LCP similarity, sim_best = 0.981 (> 0.100 thold), f_keep = 0.979
2026-05-15 10:47:46.123 | reasoning-budget: activated, budget=2147483647 tokens
2026-05-15 10:47:46.123 | slot launch_slot_: id  2 | task -1 | sampler chain: logits -> penalties -> ?dry -> ?top-n-sigma -> top-k -> ?typical -> ?top-p -> min-p -> ?xtc -> ?temp-ext -> dist 
2026-05-15 10:47:46.123 | slot launch_slot_: id  2 | task 1715 | processing task, is_child = 0
2026-05-15 10:47:46.123 | slot update_slots: id  2 | task 1715 | new prompt, n_ctx_slot = 131072, n_keep = 0, task.n_tokens = 19344
2026-05-15 10:47:46.123 | slot update_slots: id  2 | task 1715 | n_past = 18970, slot.prompt.tokens.size() = 19372, seq_id = 2, pos_min = 19371, n_swa = 0
2026-05-15 10:47:46.123 | slot update_slots: id  2 | task 1715 | Checking checkpoint with [19336, 19336] against 18970...
2026-05-15 10:47:46.123 | slot update_slots: id  2 | task 1715 | Checking checkpoint with [19115, 19115] against 18970...
2026-05-15 10:47:46.123 | slot update_slots: id  2 | task 1715 | Checking checkpoint with [19027, 19027] against 18970...
2026-05-15 10:47:46.123 | slot update_slots: id  2 | task 1715 | Checking checkpoint with [18515, 18515] against 18970...
2026-05-15 10:47:46.167 | slot update_slots: id  2 | task 1715 | restored context checkpoint (pos_min = 18515, pos_max = 18515, n_tokens = 18516, n_past = 18516, size = 188.404 MiB)
2026-05-15 10:47:46.167 | slot update_slots: id  2 | task 1715 | erased invalidated context checkpoint (pos_min = 19027, pos_max = 19027, n_tokens = 19028, n_swa = 0, pos_next = 18516, size = 189.476 MiB)
2026-05-15 10:47:46.179 | slot update_slots: id  2 | task 1715 | erased invalidated context checkpoint (pos_min = 19115, pos_max = 19115, n_tokens = 19116, n_swa = 0, pos_next = 18516, size = 189.660 MiB)
2026-05-15 10:47:46.191 | slot update_slots: id  2 | task 1715 | erased invalidated context checkpoint (pos_min = 19336, pos_max = 19336, n_tokens = 19337, n_swa = 0, pos_next = 18516, size = 190.123 MiB)
2026-05-15 10:47:46.202 | slot update_slots: id  2 | task 1715 | n_tokens = 18516, memory_seq_rm [18516, end)
2026-05-15 10:47:46.202 | slot update_slots: id  2 | task 1715 | prompt processing progress, n_tokens = 18828, batch.n_tokens = 312, progress = 0.973325
2026-05-15 10:47:46.450 | slot update_slots: id  2 | task 1715 | n_tokens = 18828, memory_seq_rm [18828, end)
2026-05-15 10:47:46.450 | slot update_slots: id  2 | task 1715 | prompt processing progress, n_tokens = 19340, batch.n_tokens = 512, progress = 0.999793
2026-05-15 10:47:46.596 | slot create_check: id  2 | task 1715 | created context checkpoint 10 of 32 (pos_min = 18827, pos_max = 18827, n_tokens = 18828, size = 189.057 MiB)
2026-05-15 10:47:46.811 | slot update_slots: id  2 | task 1715 | n_tokens = 19340, memory_seq_rm [19340, end)
2026-05-15 10:47:46.814 | slot init_sampler: id  2 | task 1715 | init sampler, took 2.65 ms, tokens: text = 19344, total = 19344
2026-05-15 10:47:46.814 | slot update_slots: id  2 | task 1715 | prompt processing done, n_tokens = 19344, batch.n_tokens = 4
2026-05-15 10:47:46.957 | slot create_check: id  2 | task 1715 | created context checkpoint 11 of 32 (pos_min = 19339, pos_max = 19339, n_tokens = 19340, size = 190.129 MiB)
2026-05-15 10:47:46.997 | srv  log_server_r: done request: POST /v1/chat/completions 172.18.0.1 200
2026-05-15 10:47:47.625 | reasoning-budget: deactivated (natural end)
2026-05-15 10:47:47.746 | slot print_timing: id  2 | task 1715 | 
2026-05-15 10:47:47.746 | prompt eval time =     874.13 ms /   828 tokens (    1.06 ms per token,   947.22 tokens per second)
2026-05-15 10:47:47.746 |        eval time =     748.73 ms /    42 tokens (   17.83 ms per token,    56.09 tokens per second)
2026-05-15 10:47:47.746 |       total time =    1622.87 ms /   870 tokens
2026-05-15 10:47:47.746 | draft acceptance rate = 0.96000 (   24 accepted /    25 generated)
2026-05-15 10:47:47.746 | statistics mtp: #calls(b,g,a) = 20 1592 1453, #gen drafts = 1453, #acc drafts = 1453, #gen tokens = 2581, #acc tokens = 2542, dur(b,g,a) = 0.028, 6487.476, 0.667 ms
2026-05-15 10:47:47.747 | slot      release: id  2 | task 1715 | stop processing: n_tokens = 19385, truncated = 0
2026-05-15 10:47:47.747 | srv  update_slots: all slots are idle
2026-05-15 10:49:01.638 | srv    operator(): operator(): cleaning up before exit...
2026-05-15 10:49:01.640 | common_memory_breakdown_print: | memory breakdown [MiB] | total   free     self   model   context   compute    unaccounted |
2026-05-15 10:49:01.640 | common_memory_breakdown_print: |   - CUDA0 (RTX 5090)   | 32606 = 5473 + (21832 = 16386 +    4950 +     495) +        5300 |
2026-05-15 10:49:01.640 | common_memory_breakdown_print: |   - Host               |                   958 =   682 +       0 +     276                |
2026-05-15 17:28:16.501 | ggml_cuda_init: found 1 CUDA devices (Total VRAM: 32606 MiB):
2026-05-15 17:28:16.501 |   Device 0: NVIDIA GeForce RTX 5090, compute capability 12.0, VMM: yes, VRAM: 32606 MiB
2026-05-15 17:28:16.501 | load_backend: loaded CUDA backend from /app/libggml-cuda.so
2026-05-15 17:28:16.536 | load_backend: loaded CPU backend from /app/libggml-cpu-haswell.so
2026-05-15 17:28:16.536 | warn: LLAMA_ARG_HOST environment variable is set, but will be overwritten by command line argument --host
2026-05-15 17:28:16.713 | common_download_file_single_online: HEAD failed, status: 404
2026-05-15 17:28:16.713 | no remote preset found, skipping
2026-05-15 17:28:17.045 | main: n_parallel is set to auto, using n_parallel = 4 and kv_unified = true
2026-05-15 17:28:17.045 | build_info: b484-2c4055912
2026-05-15 17:28:17.046 | system_info: n_threads = 16 (n_threads_batch = 16) / 32 | CUDA : ARCHS = 750,800,860,890,1200,1210 | USE_GRAPHS = 1 | PEER_MAX_BATCH_SIZE = 128 | BLACKWELL_NATIVE_FP4 = 1 | CPU : SSE3 = 1 | SSSE3 = 1 | AVX = 1 | AVX2 = 1 | F16C = 1 | FMA = 1 | BMI2 = 1 | LLAMAFILE = 1 | OPENMP = 1 | REPACK = 1 | 
2026-05-15 17:28:17.046 | Running without SSL
2026-05-15 17:28:17.046 | init: using 31 threads for HTTP server
2026-05-15 17:28:17.046 | start: binding port with default address family
2026-05-15 17:28:17.048 | main: loading model
2026-05-15 17:28:17.048 | srv    load_model: loading model '/root/.cache/huggingface/hub/models--unsloth--Qwen3.6-27B-MTP-GGUF/snapshots/296162df313e8eebe1e15a00d60b3f8f33962e18/Qwen3.6-27B-UD-Q4_K_XL.gguf'
2026-05-15 17:28:17.049 | common_init_result: fitting params to device memory, for bugs during this step try to reproduce them with -fit off, or provide --verbose logs if the bug only occurs with -fit on
2026-05-15 17:28:17.050 | common_params_fit_impl: getting device memory data for initial parameters:
2026-05-15 17:28:17.698 | common_memory_breakdown_print: | memory breakdown [MiB] | total    free     self   model   context   compute    unaccounted |
2026-05-15 17:28:17.698 | common_memory_breakdown_print: |   - CUDA0 (RTX 5090)   | 32606 = 30330 + (21832 = 16386 +    4950 +     495) +      -19555 |
2026-05-15 17:28:17.698 | common_memory_breakdown_print: |   - Host               |                    958 =   682 +       0 +     276                |
2026-05-15 17:28:17.751 | common_params_fit_impl: projected to use 21832 MiB of device memory vs. 30330 MiB of free device memory
2026-05-15 17:28:17.751 | common_params_fit_impl: will leave 8497 >= 1024 MiB of free device memory, no changes needed
2026-05-15 17:28:17.751 | common_fit_params: successfully fit params to free device memory
2026-05-15 17:28:17.751 | common_fit_params: fitting params to free memory took 0.70 seconds
2026-05-15 17:28:17.782 | llama_model_loader: loaded meta data with 52 key-value pairs and 866 tensors from /root/.cache/huggingface/hub/models--unsloth--Qwen3.6-27B-MTP-GGUF/snapshots/296162df313e8eebe1e15a00d60b3f8f33962e18/Qwen3.6-27B-UD-Q4_K_XL.gguf (version GGUF V3 (latest))
2026-05-15 17:28:17.782 | llama_model_loader: Dumping metadata keys/values. Note: KV overrides do not apply in this output.
2026-05-15 17:28:17.782 | llama_model_loader: - kv   0:                       general.architecture str              = qwen35
2026-05-15 17:28:17.782 | llama_model_loader: - kv   1:                               general.type str              = model
2026-05-15 17:28:17.782 | llama_model_loader: - kv   2:                     general.sampling.top_k i32              = 20
2026-05-15 17:28:17.782 | llama_model_loader: - kv   3:                     general.sampling.top_p f32              = 0.950000
2026-05-15 17:28:17.782 | llama_model_loader: - kv   4:                      general.sampling.temp f32              = 1.000000
2026-05-15 17:28:17.782 | llama_model_loader: - kv   5:                               general.name str              = Qwen3.6-27B
2026-05-15 17:28:17.782 | llama_model_loader: - kv   6:                           general.basename str              = Qwen3.6-27B
2026-05-15 17:28:17.782 | llama_model_loader: - kv   7:                       general.quantized_by str              = Unsloth
2026-05-15 17:28:17.782 | llama_model_loader: - kv   8:                         general.size_label str              = 27B
2026-05-15 17:28:17.782 | llama_model_loader: - kv   9:                            general.license str              = apache-2.0
2026-05-15 17:28:17.782 | llama_model_loader: - kv  10:                       general.license.link str              = https://huggingface.co/Qwen/Qwen3.6-2...
2026-05-15 17:28:17.782 | llama_model_loader: - kv  11:                           general.repo_url str              = https://huggingface.co/unsloth
2026-05-15 17:28:17.782 | llama_model_loader: - kv  12:                   general.base_model.count u32              = 1
2026-05-15 17:28:17.782 | llama_model_loader: - kv  13:                  general.base_model.0.name str              = Qwen3.6 27B
2026-05-15 17:28:17.782 | llama_model_loader: - kv  14:          general.base_model.0.organization str              = Qwen
2026-05-15 17:28:17.782 | llama_model_loader: - kv  15:              general.base_model.0.repo_url str              = https://huggingface.co/Qwen/Qwen3.6-27B
2026-05-15 17:28:17.782 | llama_model_loader: - kv  16:                               general.tags arr[str,2]       = ["unsloth", "image-text-to-text"]
2026-05-15 17:28:17.782 | llama_model_loader: - kv  17:                         qwen35.block_count u32              = 65
2026-05-15 17:28:17.782 | llama_model_loader: - kv  18:                      qwen35.context_length u32              = 262144
2026-05-15 17:28:17.782 | llama_model_loader: - kv  19:                    qwen35.embedding_length u32              = 5120
2026-05-15 17:28:17.782 | llama_model_loader: - kv  20:                 qwen35.feed_forward_length u32              = 17408
2026-05-15 17:28:17.782 | llama_model_loader: - kv  21:                qwen35.attention.head_count u32              = 24
2026-05-15 17:28:17.782 | llama_model_loader: - kv  22:             qwen35.attention.head_count_kv u32              = 4
2026-05-15 17:28:17.782 | llama_model_loader: - kv  23:             qwen35.rope.dimension_sections arr[i32,4]       = [11, 11, 10, 0]
2026-05-15 17:28:17.782 | llama_model_loader: - kv  24:                      qwen35.rope.freq_base f32              = 10000000.000000
2026-05-15 17:28:17.782 | llama_model_loader: - kv  25:    qwen35.attention.layer_norm_rms_epsilon f32              = 0.000001
2026-05-15 17:28:17.782 | llama_model_loader: - kv  26:                qwen35.attention.key_length u32              = 256
2026-05-15 17:28:17.782 | llama_model_loader: - kv  27:              qwen35.attention.value_length u32              = 256
2026-05-15 17:28:17.782 | llama_model_loader: - kv  28:                     qwen35.ssm.conv_kernel u32              = 4
2026-05-15 17:28:17.782 | llama_model_loader: - kv  29:                      qwen35.ssm.state_size u32              = 128
2026-05-15 17:28:17.782 | llama_model_loader: - kv  30:                     qwen35.ssm.group_count u32              = 16
2026-05-15 17:28:17.782 | llama_model_loader: - kv  31:                  qwen35.ssm.time_step_rank u32              = 48
2026-05-15 17:28:17.782 | llama_model_loader: - kv  32:                      qwen35.ssm.inner_size u32              = 6144
2026-05-15 17:28:17.782 | llama_model_loader: - kv  33:             qwen35.full_attention_interval u32              = 4
2026-05-15 17:28:17.782 | llama_model_loader: - kv  34:                qwen35.rope.dimension_count u32              = 64
2026-05-15 17:28:17.782 | llama_model_loader: - kv  35:                qwen35.nextn_predict_layers u32              = 1
2026-05-15 17:28:17.782 | llama_model_loader: - kv  36:                       tokenizer.ggml.model str              = gpt2
2026-05-15 17:28:17.782 | llama_model_loader: - kv  37:                         tokenizer.ggml.pre str              = qwen35
2026-05-15 17:28:17.801 | llama_model_loader: - kv  38:                      tokenizer.ggml.tokens arr[str,248320]  = ["!", "\"", "#", "$", "%", "&", "'", ...
2026-05-15 17:28:17.806 | llama_model_loader: - kv  39:                  tokenizer.ggml.token_type arr[i32,248320]  = [1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, ...
2026-05-15 17:28:17.825 | llama_model_loader: - kv  40:                      tokenizer.ggml.merges arr[str,247587]  = ["Ġ Ġ", "ĠĠ ĠĠ", "i n", "Ġ t",...
2026-05-15 17:28:17.825 | llama_model_loader: - kv  41:                tokenizer.ggml.eos_token_id u32              = 248046
2026-05-15 17:28:17.825 | llama_model_loader: - kv  42:            tokenizer.ggml.padding_token_id u32              = 248055
2026-05-15 17:28:17.825 | llama_model_loader: - kv  43:                tokenizer.ggml.bos_token_id u32              = 248044
2026-05-15 17:28:17.825 | llama_model_loader: - kv  44:               tokenizer.ggml.add_bos_token bool             = false
2026-05-15 17:28:17.825 | llama_model_loader: - kv  45:                    tokenizer.chat_template str              = {%- set image_count = namespace(value...
2026-05-15 17:28:17.825 | llama_model_loader: - kv  46:               general.quantization_version u32              = 2
2026-05-15 17:28:17.825 | llama_model_loader: - kv  47:                          general.file_type u32              = 15
2026-05-15 17:28:17.825 | llama_model_loader: - kv  48:                      quantize.imatrix.file str              = Qwen3.6-27B-GGUF/imatrix_unsloth.gguf
2026-05-15 17:28:17.825 | llama_model_loader: - kv  49:                   quantize.imatrix.dataset str              = unsloth_calibration_Qwen3.6-27B.txt
2026-05-15 17:28:17.825 | llama_model_loader: - kv  50:             quantize.imatrix.entries_count u32              = 496
2026-05-15 17:28:17.825 | llama_model_loader: - kv  51:              quantize.imatrix.chunks_count u32              = 76
2026-05-15 17:28:17.825 | llama_model_loader: - type  f32:  456 tensors
2026-05-15 17:28:17.825 | llama_model_loader: - type q8_0:   49 tensors
2026-05-15 17:28:17.825 | llama_model_loader: - type q4_K:  225 tensors
2026-05-15 17:28:17.825 | llama_model_loader: - type q5_K:   70 tensors
2026-05-15 17:28:17.825 | llama_model_loader: - type q6_K:   66 tensors
2026-05-15 17:28:17.825 | print_info: file format = GGUF V3 (latest)
2026-05-15 17:28:17.825 | print_info: file type   = Q4_K - Medium
2026-05-15 17:28:17.825 | print_info: file size   = 16.67 GiB (5.24 BPW) 
2026-05-15 17:28:17.825 | llama_prepare_model_devices: using device CUDA0 (NVIDIA GeForce RTX 5090) (0000:0b:00.0) - 30930 MiB free
2026-05-15 17:28:17.965 | load: 0 unused tokens
2026-05-15 17:28:18.008 | load: printing all EOG tokens:
2026-05-15 17:28:18.008 | load:   - 248044 ('<|endoftext|>')
2026-05-15 17:28:18.008 | load:   - 248046 ('<|im_end|>')
2026-05-15 17:28:18.008 | load:   - 248063 ('<|fim_pad|>')
2026-05-15 17:28:18.008 | load:   - 248064 ('<|repo_name|>')
2026-05-15 17:28:18.008 | load:   - 248065 ('<|file_sep|>')
2026-05-15 17:28:18.008 | load: special tokens cache size = 33
2026-05-15 17:28:18.075 | load: token to piece cache size = 1.7581 MB
2026-05-15 17:28:18.075 | print_info: arch                  = qwen35
2026-05-15 17:28:18.075 | print_info: vocab_only            = 0
2026-05-15 17:28:18.075 | print_info: no_alloc              = 0
2026-05-15 17:28:18.075 | print_info: n_ctx_train           = 262144
2026-05-15 17:28:18.075 | print_info: n_embd                = 5120
2026-05-15 17:28:18.075 | print_info: n_embd_inp            = 5120
2026-05-15 17:28:18.075 | print_info: n_layer               = 65
2026-05-15 17:28:18.075 | print_info: n_head                = 24
2026-05-15 17:28:18.075 | print_info: n_head_kv             = 4
2026-05-15 17:28:18.075 | print_info: n_rot                 = 64
2026-05-15 17:28:18.075 | print_info: n_swa                 = 0
2026-05-15 17:28:18.075 | print_info: is_swa_any            = 0
2026-05-15 17:28:18.075 | print_info: n_embd_head_k         = 256
2026-05-15 17:28:18.075 | print_info: n_embd_head_v         = 256
2026-05-15 17:28:18.075 | print_info: n_gqa                 = 6
2026-05-15 17:28:18.075 | print_info: n_embd_k_gqa          = 1024
2026-05-15 17:28:18.075 | print_info: n_embd_v_gqa          = 1024
2026-05-15 17:28:18.075 | print_info: f_norm_eps            = 0.0e+00
2026-05-15 17:28:18.075 | print_info: f_norm_rms_eps        = 1.0e-06
2026-05-15 17:28:18.075 | print_info: f_clamp_kqv           = 0.0e+00
2026-05-15 17:28:18.075 | print_info: f_max_alibi_bias      = 0.0e+00
2026-05-15 17:28:18.075 | print_info: f_logit_scale         = 0.0e+00
2026-05-15 17:28:18.075 | print_info: f_attn_scale          = 0.0e+00
2026-05-15 17:28:18.075 | print_info: f_attn_value_scale    = 0.0000
2026-05-15 17:28:18.075 | print_info: n_ff                  = 17408
2026-05-15 17:28:18.075 | print_info: n_expert              = 0
2026-05-15 17:28:18.075 | print_info: n_expert_used         = 0
2026-05-15 17:28:18.075 | print_info: n_expert_groups       = 0
2026-05-15 17:28:18.075 | print_info: n_group_used          = 0
2026-05-15 17:28:18.075 | print_info: causal attn           = 1
2026-05-15 17:28:18.075 | print_info: pooling type          = -1
2026-05-15 17:28:18.075 | print_info: rope type             = 40
2026-05-15 17:28:18.075 | print_info: rope scaling          = linear
2026-05-15 17:28:18.075 | print_info: freq_base_train       = 10000000.0
2026-05-15 17:28:18.075 | print_info: freq_scale_train      = 1
2026-05-15 17:28:18.075 | print_info: n_ctx_orig_yarn       = 262144
2026-05-15 17:28:18.075 | print_info: rope_yarn_log_mul     = 0.0000
2026-05-15 17:28:18.075 | print_info: rope_finetuned        = unknown
2026-05-15 17:28:18.075 | print_info: mrope sections        = [11, 11, 10, 0]
2026-05-15 17:28:18.075 | print_info: ssm_d_conv            = 4
2026-05-15 17:28:18.075 | print_info: ssm_d_inner           = 6144
2026-05-15 17:28:18.075 | print_info: ssm_d_state           = 128
2026-05-15 17:28:18.075 | print_info: ssm_dt_rank           = 48
2026-05-15 17:28:18.075 | print_info: ssm_n_group           = 16
2026-05-15 17:28:18.075 | print_info: ssm_dt_b_c_rms        = 0
2026-05-15 17:28:18.075 | print_info: model type            = 27B
2026-05-15 17:28:18.075 | print_info: model params          = 27.32 B
2026-05-15 17:28:18.075 | print_info: general.name          = Qwen3.6-27B
2026-05-15 17:28:18.075 | print_info: vocab type            = BPE
2026-05-15 17:28:18.075 | print_info: n_vocab               = 248320
2026-05-15 17:28:18.075 | print_info: n_merges              = 247587
2026-05-15 17:28:18.075 | print_info: BOS token             = 248044 '<|endoftext|>'
2026-05-15 17:28:18.075 | print_info: EOS token             = 248046 '<|im_end|>'
2026-05-15 17:28:18.075 | print_info: EOT token             = 248046 '<|im_end|>'
2026-05-15 17:28:18.075 | print_info: PAD token             = 248055 '<|vision_pad|>'
2026-05-15 17:28:18.075 | print_info: LF token              = 198 'Ċ'
2026-05-15 17:28:18.075 | print_info: FIM PRE token         = 248060 '<|fim_prefix|>'
2026-05-15 17:28:18.075 | print_info: FIM SUF token         = 248062 '<|fim_suffix|>'
2026-05-15 17:28:18.075 | print_info: FIM MID token         = 248061 '<|fim_middle|>'
2026-05-15 17:28:18.075 | print_info: FIM PAD token         = 248063 '<|fim_pad|>'
2026-05-15 17:28:18.075 | print_info: FIM REP token         = 248064 '<|repo_name|>'
2026-05-15 17:28:18.075 | print_info: FIM SEP token         = 248065 '<|file_sep|>'
2026-05-15 17:28:18.075 | print_info: EOG token             = 248044 '<|endoftext|>'
2026-05-15 17:28:18.075 | print_info: EOG token             = 248046 '<|im_end|>'
2026-05-15 17:28:18.075 | print_info: EOG token             = 248063 '<|fim_pad|>'
2026-05-15 17:28:18.075 | print_info: EOG token             = 248064 '<|repo_name|>'
2026-05-15 17:28:18.075 | print_info: EOG token             = 248065 '<|file_sep|>'
2026-05-15 17:28:18.075 | print_info: max token length      = 256
2026-05-15 17:28:18.075 | load_tensors: loading model tensors, this can take a while... (mmap = true, direct_io = false)
2026-05-15 17:28:32.376 | load_tensors: offloading output layer to GPU
2026-05-15 17:28:32.376 | load_tensors: offloading 64 repeating layers to GPU
2026-05-15 17:28:32.376 | load_tensors: offloaded 66/66 layers to GPU
2026-05-15 17:28:32.376 | load_tensors:   CPU_Mapped model buffer size =   682.03 MiB
2026-05-15 17:28:32.376 | load_tensors:        CUDA0 model buffer size = 16386.94 MiB
2026-05-15 17:28:35.238 | .............................................................................................
2026-05-15 17:28:35.243 | common_init_result: added <|endoftext|> logit bias = -inf
2026-05-15 17:28:35.243 | common_init_result: added <|im_end|> logit bias = -inf
2026-05-15 17:28:35.243 | common_init_result: added <|fim_pad|> logit bias = -inf
2026-05-15 17:28:35.243 | common_init_result: added <|repo_name|> logit bias = -inf
2026-05-15 17:28:35.243 | common_init_result: added <|file_sep|> logit bias = -inf
2026-05-15 17:28:35.243 | llama_context: constructing llama_context
2026-05-15 17:28:35.243 | llama_context: n_seq_max     = 4
2026-05-15 17:28:35.243 | llama_context: n_ctx         = 131072
2026-05-15 17:28:35.243 | llama_context: n_ctx_seq     = 131072
2026-05-15 17:28:35.243 | llama_context: n_batch       = 2048
2026-05-15 17:28:35.243 | llama_context: n_ubatch      = 512
2026-05-15 17:28:35.243 | llama_context: causal_attn   = 1
2026-05-15 17:28:35.243 | llama_context: flash_attn    = enabled
2026-05-15 17:28:35.243 | llama_context: kv_unified    = true
2026-05-15 17:28:35.243 | llama_context: freq_base     = 10000000.0
2026-05-15 17:28:35.243 | llama_context: freq_scale    = 1
2026-05-15 17:28:35.243 | llama_context: n_ctx_seq (131072) < n_ctx_train (262144) -- the full capacity of the model will not be utilized
2026-05-15 17:28:35.248 | llama_context:  CUDA_Host  output buffer size =     3.79 MiB
2026-05-15 17:28:35.268 | llama_kv_cache:      CUDA0 KV buffer size =  4352.00 MiB
2026-05-15 17:28:35.304 | llama_kv_cache: size = 4352.00 MiB (131072 cells,  16 layers,  4/1 seqs), K (q8_0): 2176.00 MiB, V (q8_0): 2176.00 MiB
2026-05-15 17:28:35.304 | llama_kv_cache: attn_rot_k = 1, n_embd_head_k_all = 256
2026-05-15 17:28:35.304 | llama_kv_cache: attn_rot_v = 1, n_embd_head_k_all = 256
2026-05-15 17:28:35.312 | llama_memory_recurrent:      CUDA0 RS buffer size =   598.50 MiB
2026-05-15 17:28:35.313 | llama_memory_recurrent: size =  598.50 MiB (     4 cells,  65 layers,  4 seqs), R (f32):   22.50 MiB, S (f32):  576.00 MiB
2026-05-15 17:28:35.313 | sched_reserve: reserving ...
2026-05-15 17:28:35.333 | sched_reserve: resolving fused Gated Delta Net support:
2026-05-15 17:28:35.334 | sched_reserve: fused Gated Delta Net (autoregressive) enabled
2026-05-15 17:28:35.335 | sched_reserve: fused Gated Delta Net (chunked) enabled
2026-05-15 17:28:35.599 | sched_reserve:      CUDA0 compute buffer size =   495.00 MiB
2026-05-15 17:28:35.599 | sched_reserve:  CUDA_Host compute buffer size =   276.29 MiB
2026-05-15 17:28:35.599 | sched_reserve: graph nodes  = 3849
2026-05-15 17:28:35.599 | sched_reserve: graph splits = 2
2026-05-15 17:28:35.599 | sched_reserve: reserve took 286.38 ms, sched copies = 1
2026-05-15 17:28:35.599 | common_init_from_params: warming up the model with an empty run - please wait ... (--no-warmup to disable)
2026-05-15 17:28:35.913 | srv    load_model: creating MTP draft context against the target model '/root/.cache/huggingface/hub/models--unsloth--Qwen3.6-27B-MTP-GGUF/snapshots/296162df313e8eebe1e15a00d60b3f8f33962e18/Qwen3.6-27B-UD-Q4_K_XL.gguf'
2026-05-15 17:28:35.913 | llama_context: constructing llama_context
2026-05-15 17:28:35.913 | llama_context: n_seq_max     = 4
2026-05-15 17:28:35.913 | llama_context: n_ctx         = 131072
2026-05-15 17:28:35.913 | llama_context: n_ctx_seq     = 131072
2026-05-15 17:28:35.913 | llama_context: n_batch       = 2048
2026-05-15 17:28:35.913 | llama_context: n_ubatch      = 512
2026-05-15 17:28:35.913 | llama_context: causal_attn   = 1
2026-05-15 17:28:35.913 | llama_context: flash_attn    = enabled
2026-05-15 17:28:35.913 | llama_context: kv_unified    = true
2026-05-15 17:28:35.913 | llama_context: freq_base     = 10000000.0
2026-05-15 17:28:35.913 | llama_context: freq_scale    = 1
2026-05-15 17:28:35.913 | llama_context: n_ctx_seq (131072) < n_ctx_train (262144) -- the full capacity of the model will not be utilized
2026-05-15 17:28:35.918 | llama_context:  CUDA_Host  output buffer size =     3.79 MiB
2026-05-15 17:28:35.925 | llama_kv_cache:      CUDA0 KV buffer size =   272.00 MiB
2026-05-15 17:28:35.927 | llama_kv_cache: size =  272.00 MiB (131072 cells,   1 layers,  4/1 seqs), K (q8_0):  136.00 MiB, V (q8_0):  136.00 MiB
2026-05-15 17:28:35.927 | llama_kv_cache: attn_rot_k = 1, n_embd_head_k_all = 256
2026-05-15 17:28:35.927 | llama_kv_cache: attn_rot_v = 1, n_embd_head_k_all = 256
2026-05-15 17:28:35.928 | sched_reserve: reserving ...
2026-05-15 17:28:35.950 | sched_reserve: resolving fused Gated Delta Net support:
2026-05-15 17:28:35.950 | sched_reserve: fused Gated Delta Net (autoregressive) enabled
2026-05-15 17:28:35.950 | sched_reserve: fused Gated Delta Net (chunked) enabled
2026-05-15 17:28:36.220 | sched_reserve:      CUDA0 compute buffer size =   495.00 MiB
2026-05-15 17:28:36.220 | sched_reserve:  CUDA_Host compute buffer size =   276.28 MiB
2026-05-15 17:28:36.220 | sched_reserve: graph nodes  = 62
2026-05-15 17:28:36.220 | sched_reserve: graph splits = 2
2026-05-15 17:28:36.220 | sched_reserve: reserve took 292.62 ms, sched copies = 1
2026-05-15 17:28:36.239 | clip_model_loader: model name:   Qwen3.6-27B
2026-05-15 17:28:36.239 | clip_model_loader: description:  
2026-05-15 17:28:36.239 | clip_model_loader: GGUF version: 3
2026-05-15 17:28:36.239 | clip_model_loader: alignment:    32
2026-05-15 17:28:36.239 | clip_model_loader: n_tensors:    334
2026-05-15 17:28:36.239 | clip_model_loader: n_kv:         33
2026-05-15 17:28:36.239 | 
2026-05-15 17:28:36.239 | clip_model_loader: has vision encoder
2026-05-15 17:28:36.239 | clip_ctx: CLIP using CUDA0 backend
2026-05-15 17:28:36.240 | load_hparams: Qwen-VL models require at minimum 1024 image tokens to function correctly on grounding tasks
2026-05-15 17:28:36.240 | load_hparams: if you encounter problems with accuracy, try adding --image-min-tokens 1024
2026-05-15 17:28:36.240 | load_hparams: more info: https://github.com/ggml-org/llama.cpp/issues/16842
2026-05-15 17:28:36.240 | 
2026-05-15 17:28:36.240 | load_hparams: projector:          qwen3vl_merger
2026-05-15 17:28:36.240 | load_hparams: n_embd:             1152
2026-05-15 17:28:36.240 | load_hparams: n_head:             16
2026-05-15 17:28:36.240 | load_hparams: n_ff:               4304
2026-05-15 17:28:36.240 | load_hparams: n_layer:            27
2026-05-15 17:28:36.240 | load_hparams: ffn_op:             gelu
2026-05-15 17:28:36.240 | load_hparams: projection_dim:     5120
2026-05-15 17:28:36.240 | 
2026-05-15 17:28:36.240 | --- vision hparams ---
2026-05-15 17:28:36.240 | load_hparams: image_size:         768
2026-05-15 17:28:36.240 | load_hparams: patch_size:         16
2026-05-15 17:28:36.240 | load_hparams: has_llava_proj:     0
2026-05-15 17:28:36.240 | load_hparams: minicpmv_version:   0
2026-05-15 17:28:36.240 | load_hparams: n_merge:            2
2026-05-15 17:28:36.240 | load_hparams: n_wa_pattern: 0
2026-05-15 17:28:36.240 | load_hparams: image_min_pixels:   8192
2026-05-15 17:28:36.240 | load_hparams: image_max_pixels:   4194304
2026-05-15 17:28:36.240 | 
2026-05-15 17:28:36.240 | load_hparams: model size:         887.99 MiB
2026-05-15 17:28:36.240 | load_hparams: metadata size:      0.12 MiB
2026-05-15 17:28:37.068 | warmup: warmup with image size = 1472 x 1472
2026-05-15 17:28:37.070 | alloc_compute_meta:      CUDA0 compute buffer size =   248.10 MiB
2026-05-15 17:28:37.070 | alloc_compute_meta:        CPU compute buffer size =    24.93 MiB
2026-05-15 17:28:37.070 | alloc_compute_meta: graph splits = 1, nodes = 823
2026-05-15 17:28:37.070 | warmup: flash attention is enabled
2026-05-15 17:28:37.070 | srv    load_model: loaded multimodal model, '/root/.cache/huggingface/hub/models--unsloth--Qwen3.6-27B-MTP-GGUF/snapshots/296162df313e8eebe1e15a00d60b3f8f33962e18/mmproj-BF16.gguf'
2026-05-15 17:28:37.070 | srv    load_model: initializing slots, n_slots = 4
2026-05-15 17:28:37.110 | common_context_can_seq_rm: the context does not support partial sequence removal
2026-05-15 17:28:37.141 | srv    load_model: speculative decoding will use checkpoints
2026-05-15 17:28:37.141 | common_speculative_init: adding speculative implementation 'mtp'
2026-05-15 17:28:37.141 | srv    load_model: speculative decoding context initialized
2026-05-15 17:28:37.141 | slot   load_model: id  0 | task -1 | new slot, n_ctx = 131072
2026-05-15 17:28:37.141 | slot   load_model: id  1 | task -1 | new slot, n_ctx = 131072
2026-05-15 17:28:37.141 | slot   load_model: id  2 | task -1 | new slot, n_ctx = 131072
2026-05-15 17:28:37.141 | slot   load_model: id  3 | task -1 | new slot, n_ctx = 131072
2026-05-15 17:28:37.141 | srv    load_model: prompt cache is enabled, size limit: 8192 MiB
2026-05-15 17:28:37.141 | srv    load_model: use `--cache-ram 0` to disable the prompt cache
2026-05-15 17:28:37.141 | srv    load_model: for more info see https://github.com/ggml-org/llama.cpp/pull/16391
2026-05-15 17:28:37.141 | srv          init: init: idle slots will be saved to prompt cache and cleared upon starting a new task
2026-05-15 17:28:37.155 | init: chat template, example_format: '<|im_start|>system
2026-05-15 17:28:37.155 | You are a helpful assistant<|im_end|>
2026-05-15 17:28:37.155 | <|im_start|>user
2026-05-15 17:28:37.155 | Hello<|im_end|>
2026-05-15 17:28:37.155 | <|im_start|>assistant
2026-05-15 17:28:37.155 | Hi there<|im_end|>
2026-05-15 17:28:37.155 | <|im_start|>user
2026-05-15 17:28:37.155 | How are you?<|im_end|>
2026-05-15 17:28:37.155 | <|im_start|>assistant
2026-05-15 17:28:37.155 | <think>
2026-05-15 17:28:37.155 | '
2026-05-15 17:28:37.164 | srv          init: init: chat template, thinking = 1
2026-05-15 17:28:37.164 | main: model loaded
2026-05-15 17:28:37.164 | main: server is listening on http://0.0.0.0:8080
2026-05-15 17:28:37.164 | main: starting the main loop...
2026-05-15 17:28:37.164 | srv  update_slots: all slots are idle
2026-05-15 17:48:18.577 | srv  params_from_: Chat format: peg-native
2026-05-15 17:48:18.579 | slot get_availabl: id  3 | task -1 | selected slot by LRU, t_last = -1
2026-05-15 17:48:18.579 | srv  get_availabl: updating prompt cache
2026-05-15 17:48:18.579 | srv          load:  - looking for better prompt, base f_keep = -1.000, sim = 0.000
2026-05-15 17:48:18.579 | srv        update:  - cache state: 0 prompts, 0.000 MiB (limits: 8192.000 MiB, 131072 tokens, 8589934592 est)
2026-05-15 17:48:18.579 | srv  get_availabl: prompt cache update took 0.01 ms
2026-05-15 17:48:18.580 | slot launch_slot_: id  3 | task -1 | sampler chain: logits -> penalties -> ?dry -> ?top-n-sigma -> top-k -> ?typical -> ?top-p -> min-p -> ?xtc -> ?temp-ext -> dist 
2026-05-15 17:48:18.580 | slot launch_slot_: id  3 | task 0 | processing task, is_child = 0
2026-05-15 17:48:18.580 | slot update_slots: id  3 | task 0 | new prompt, n_ctx_slot = 131072, n_keep = 0, task.n_tokens = 903
2026-05-15 17:48:18.580 | slot update_slots: id  3 | task 0 | n_tokens = 0, memory_seq_rm [0, end)
2026-05-15 17:48:18.580 | slot update_slots: id  3 | task 0 | prompt processing progress, n_tokens = 387, batch.n_tokens = 387, progress = 0.428571
2026-05-15 17:48:18.760 | srv  params_from_: Chat format: peg-native
2026-05-15 17:48:22.292 | slot get_availabl: id  2 | task -1 | selected slot by LRU, t_last = -1
2026-05-15 17:48:22.292 | srv  get_availabl: updating prompt cache
2026-05-15 17:48:22.292 | srv          load:  - looking for better prompt, base f_keep = -1.000, sim = 0.000
2026-05-15 17:48:22.292 | srv        update:  - cache state: 0 prompts, 0.000 MiB (limits: 8192.000 MiB, 131072 tokens, 8589934592 est)
2026-05-15 17:48:22.292 | srv  get_availabl: prompt cache update took 0.01 ms
2026-05-15 17:48:22.297 | reasoning-budget: activated, budget=2147483647 tokens
2026-05-15 17:48:22.297 | slot launch_slot_: id  2 | task -1 | sampler chain: logits -> penalties -> ?dry -> ?top-n-sigma -> top-k -> ?typical -> ?top-p -> min-p -> ?xtc -> ?temp-ext -> dist 
2026-05-15 17:48:22.297 | slot launch_slot_: id  2 | task 2 | processing task, is_child = 0
2026-05-15 17:48:22.297 | slot update_slots: id  2 | task 2 | new prompt, n_ctx_slot = 131072, n_keep = 0, task.n_tokens = 11832
2026-05-15 17:48:22.297 | slot update_slots: id  2 | task 2 | n_tokens = 0, memory_seq_rm [0, end)
2026-05-15 17:48:22.297 | slot update_slots: id  2 | task 2 | prompt processing progress, n_tokens = 2048, batch.n_tokens = 2048, progress = 0.173090
2026-05-15 17:48:20.149 | slot update_slots: id  2 | task 2 | n_tokens = 2048, memory_seq_rm [2048, end)
2026-05-15 17:48:20.149 | slot update_slots: id  2 | task 2 | prompt processing progress, n_tokens = 4096, batch.n_tokens = 2048, progress = 0.346180
2026-05-15 17:48:20.918 | slot update_slots: id  2 | task 2 | n_tokens = 4096, memory_seq_rm [4096, end)
2026-05-15 17:48:20.918 | slot update_slots: id  2 | task 2 | prompt processing progress, n_tokens = 6144, batch.n_tokens = 2048, progress = 0.519270
2026-05-15 17:48:21.692 | slot update_slots: id  2 | task 2 | n_tokens = 6144, memory_seq_rm [6144, end)
2026-05-15 17:48:21.692 | slot update_slots: id  2 | task 2 | prompt processing progress, n_tokens = 8192, batch.n_tokens = 2048, progress = 0.692360
2026-05-15 17:48:22.479 | slot update_slots: id  2 | task 2 | n_tokens = 8192, memory_seq_rm [8192, end)
2026-05-15 17:48:22.480 | slot update_slots: id  2 | task 2 | 8192 tokens since last checkpoint at 0, creating new checkpoint during processing at position 10240
2026-05-15 17:48:22.480 | slot update_slots: id  2 | task 2 | prompt processing progress, n_tokens = 10240, batch.n_tokens = 2048, progress = 0.865450
2026-05-15 17:48:22.657 | slot create_check: id  2 | task 2 | created context checkpoint 1 of 32 (pos_min = 8191, pos_max = 8191, n_tokens = 8192, size = 166.782 MiB)
2026-05-15 17:48:23.473 | slot update_slots: id  2 | task 2 | n_tokens = 10240, memory_seq_rm [10240, end)
2026-05-15 17:48:23.473 | slot update_slots: id  2 | task 2 | prompt processing progress, n_tokens = 11316, batch.n_tokens = 1076, progress = 0.956389
2026-05-15 17:48:23.473 | slot update_slots: id  3 | task 0 | n_tokens = 387, memory_seq_rm [387, end)
2026-05-15 17:48:23.474 | slot update_slots: id  3 | task 0 | prompt processing progress, n_tokens = 899, batch.n_tokens = 1588, progress = 0.995570
2026-05-15 17:48:23.648 | slot create_check: id  3 | task 0 | created context checkpoint 1 of 32 (pos_min = 386, pos_max = 386, n_tokens = 387, size = 150.437 MiB)
2026-05-15 17:48:24.311 | slot update_slots: id  2 | task 2 | n_tokens = 11316, memory_seq_rm [11316, end)
2026-05-15 17:48:24.311 | slot update_slots: id  2 | task 2 | prompt processing progress, n_tokens = 11828, batch.n_tokens = 512, progress = 0.999662
2026-05-15 17:48:24.499 | slot create_check: id  2 | task 2 | created context checkpoint 2 of 32 (pos_min = 11315, pos_max = 11315, n_tokens = 11316, size = 173.325 MiB)
2026-05-15 17:48:24.499 | slot update_slots: id  3 | task 0 | n_tokens = 899, memory_seq_rm [899, end)
2026-05-15 17:48:24.499 | slot init_sampler: id  3 | task 0 | init sampler, took 0.15 ms, tokens: text = 903, total = 903
2026-05-15 17:48:24.499 | slot update_slots: id  3 | task 0 | prompt processing done, n_tokens = 903, batch.n_tokens = 516
2026-05-15 17:48:24.675 | slot create_check: id  3 | task 0 | created context checkpoint 2 of 32 (pos_min = 898, pos_max = 898, n_tokens = 899, size = 151.509 MiB)
2026-05-15 17:48:24.946 | srv  log_server_r: done request: POST /v1/chat/completions 172.18.0.1 200
2026-05-15 17:48:24.965 | ~llama_io_write_device: allocated 'CUDA0' buffer 149.625 MiB
2026-05-15 17:48:24.970 | slot update_slots: id  2 | task 2 | n_tokens = 11828, memory_seq_rm [11828, end)
2026-05-15 17:48:24.972 | slot init_sampler: id  2 | task 2 | init sampler, took 1.68 ms, tokens: text = 11832, total = 11832
2026-05-15 17:48:24.972 | slot update_slots: id  2 | task 2 | prompt processing done, n_tokens = 11832, batch.n_tokens = 7
2026-05-15 17:48:25.175 | slot create_check: id  2 | task 2 | created context checkpoint 3 of 32 (pos_min = 11827, pos_max = 11827, n_tokens = 11828, size = 174.397 MiB)
2026-05-15 17:48:25.252 | srv  log_server_r: done request: POST /v1/chat/completions 172.18.0.1 200
2026-05-15 17:48:25.265 | ~llama_io_write_device: allocated 'CUDA0' buffer 149.625 MiB
2026-05-15 17:48:27.738 | reasoning-budget: deactivated (natural end)
2026-05-15 17:48:30.709 | slot print_timing: id  2 | task 2 | 
2026-05-15 17:48:30.709 | prompt eval time =    8097.99 ms / 11832 tokens (    0.68 ms per token,  1461.10 tokens per second)
2026-05-15 17:48:30.709 |        eval time =    5457.70 ms /   169 tokens (   32.29 ms per token,    30.97 tokens per second)
2026-05-15 17:48:30.709 |       total time =   13555.69 ms / 12001 tokens
2026-05-15 17:48:30.709 | draft acceptance rate = 0.96226 (  102 accepted /   106 generated)
2026-05-15 17:48:30.709 | statistics mtp: #calls(b,g,a) = 2 74 116, #gen drafts = 117, #acc drafts = 116, #gen tokens = 207, #acc tokens = 200, dur(b,g,a) = 0.006, 379.301, 0.044 ms
2026-05-15 17:48:30.710 | slot      release: id  2 | task 2 | stop processing: n_tokens = 12000, truncated = 0
2026-05-15 17:48:30.900 | srv  params_from_: Chat format: peg-native
2026-05-15 17:48:30.918 | slot get_availabl: id  2 | task -1 | selected slot by LCP similarity, sim_best = 0.997 (> 0.100 thold), f_keep = 1.000
2026-05-15 17:48:30.919 | reasoning-budget: activated, budget=2147483647 tokens
2026-05-15 17:48:30.919 | slot launch_slot_: id  2 | task -1 | sampler chain: logits -> penalties -> ?dry -> ?top-n-sigma -> top-k -> ?typical -> ?top-p -> min-p -> ?xtc -> ?temp-ext -> dist 
2026-05-15 17:48:30.919 | slot launch_slot_: id  2 | task 89 | processing task, is_child = 0
2026-05-15 17:48:30.927 | slot update_slots: id  2 | task 89 | new prompt, n_ctx_slot = 131072, n_keep = 0, task.n_tokens = 12033
2026-05-15 17:48:30.927 | slot update_slots: id  2 | task 89 | n_tokens = 12000, memory_seq_rm [12000, end)
2026-05-15 17:48:30.927 | slot update_slots: id  2 | task 89 | prompt processing progress, n_tokens = 12029, batch.n_tokens = 32, progress = 0.999668
2026-05-15 17:48:31.136 | slot create_check: id  2 | task 89 | created context checkpoint 4 of 32 (pos_min = 11999, pos_max = 11999, n_tokens = 12000, size = 174.757 MiB)
2026-05-15 17:48:31.210 | slot update_slots: id  2 | task 89 | n_tokens = 12029, memory_seq_rm [12029, end)
2026-05-15 17:48:31.212 | slot init_sampler: id  2 | task 89 | init sampler, took 1.76 ms, tokens: text = 12033, total = 12033
2026-05-15 17:48:31.212 | slot update_slots: id  2 | task 89 | prompt processing done, n_tokens = 12033, batch.n_tokens = 5
2026-05-15 17:48:31.270 | srv  log_server_r: done request: POST /v1/chat/completions 172.18.0.1 200
2026-05-15 17:48:31.849 | reasoning-budget: deactivated (natural end)
2026-05-15 17:48:34.206 | slot print_timing: id  2 | task 89 | 
2026-05-15 17:48:34.206 | prompt eval time =     342.90 ms /    33 tokens (   10.39 ms per token,    96.24 tokens per second)
2026-05-15 17:48:34.206 |        eval time =    2936.35 ms /   100 tokens (   29.36 ms per token,    34.06 tokens per second)
2026-05-15 17:48:34.206 |       total time =    3279.25 ms /   133 tokens
2026-05-15 17:48:34.206 | draft acceptance rate = 0.98361 (   60 accepted /    61 generated)
2026-05-15 17:48:34.206 | statistics mtp: #calls(b,g,a) = 3 121 182, #gen drafts = 183, #acc drafts = 182, #gen tokens = 323, #acc tokens = 314, dur(b,g,a) = 0.008, 606.680, 0.065 ms
2026-05-15 17:48:34.207 | slot      release: id  2 | task 89 | stop processing: n_tokens = 12132, truncated = 0
2026-05-15 17:48:34.349 | srv  params_from_: Chat format: peg-native
2026-05-15 17:48:34.373 | slot get_availabl: id  2 | task -1 | selected slot by LCP similarity, sim_best = 0.963 (> 0.100 thold), f_keep = 1.000
2026-05-15 17:48:34.374 | reasoning-budget: activated, budget=2147483647 tokens
2026-05-15 17:48:34.374 | slot launch_slot_: id  2 | task -1 | sampler chain: logits -> penalties -> ?dry -> ?top-n-sigma -> top-k -> ?typical -> ?top-p -> min-p -> ?xtc -> ?temp-ext -> dist 
2026-05-15 17:48:34.374 | slot launch_slot_: id  2 | task 137 | processing task, is_child = 0
2026-05-15 17:48:34.382 | slot update_slots: id  2 | task 137 | new prompt, n_ctx_slot = 131072, n_keep = 0, task.n_tokens = 12602
2026-05-15 17:48:34.382 | slot update_slots: id  2 | task 137 | n_tokens = 12132, memory_seq_rm [12132, end)
2026-05-15 17:48:34.382 | slot update_slots: id  2 | task 137 | prompt processing progress, n_tokens = 12598, batch.n_tokens = 469, progress = 0.999683
2026-05-15 17:48:34.595 | slot create_check: id  2 | task 137 | created context checkpoint 5 of 32 (pos_min = 12131, pos_max = 12131, n_tokens = 12132, size = 175.034 MiB)
2026-05-15 17:48:34.827 | slot update_slots: id  2 | task 137 | n_tokens = 12598, memory_seq_rm [12598, end)
2026-05-15 17:48:34.829 | slot init_sampler: id  2 | task 137 | init sampler, took 1.78 ms, tokens: text = 12602, total = 12602
2026-05-15 17:48:34.829 | slot update_slots: id  2 | task 137 | prompt processing done, n_tokens = 12602, batch.n_tokens = 5
2026-05-15 17:48:35.044 | slot create_check: id  2 | task 137 | created context checkpoint 6 of 32 (pos_min = 12597, pos_max = 12597, n_tokens = 12598, size = 176.010 MiB)
2026-05-15 17:48:35.103 | srv  log_server_r: done request: POST /v1/chat/completions 172.18.0.1 200
2026-05-15 17:48:36.210 | reasoning-budget: deactivated (natural end)
2026-05-15 17:48:40.894 | slot print_timing: id  2 | task 137 | 
2026-05-15 17:48:40.894 | prompt eval time =     720.76 ms /   470 tokens (    1.53 ms per token,   652.08 tokens per second)
2026-05-15 17:48:40.894 |        eval time =    5790.86 ms /   192 tokens (   30.16 ms per token,    33.16 tokens per second)
2026-05-15 17:48:40.894 |       total time =    6511.62 ms /   662 tokens
2026-05-15 17:48:40.894 | draft acceptance rate = 0.99145 (  116 accepted /   117 generated)
2026-05-15 17:48:40.894 | statistics mtp: #calls(b,g,a) = 4 204 299, #gen drafts = 299, #acc drafts = 299, #gen tokens = 535, #acc tokens = 524, dur(b,g,a) = 0.009, 1007.894, 0.106 ms
2026-05-15 17:48:40.894 | slot      release: id  2 | task 137 | stop processing: n_tokens = 12793, truncated = 0
2026-05-15 17:48:41.076 | srv  params_from_: Chat format: peg-native
2026-05-15 17:48:41.081 | slot get_availabl: id  2 | task -1 | selected slot by LCP similarity, sim_best = 0.912 (> 0.100 thold), f_keep = 1.000
2026-05-15 17:48:41.082 | reasoning-budget: activated, budget=2147483647 tokens
2026-05-15 17:48:41.082 | slot launch_slot_: id  2 | task -1 | sampler chain: logits -> penalties -> ?dry -> ?top-n-sigma -> top-k -> ?typical -> ?top-p -> min-p -> ?xtc -> ?temp-ext -> dist 
2026-05-15 17:48:41.082 | slot launch_slot_: id  2 | task 223 | processing task, is_child = 0
2026-05-15 17:48:41.084 | slot update_slots: id  2 | task 223 | new prompt, n_ctx_slot = 131072, n_keep = 0, task.n_tokens = 14025
2026-05-15 17:48:41.084 | slot update_slots: id  2 | task 223 | n_tokens = 12793, memory_seq_rm [12793, end)
2026-05-15 17:48:41.084 | slot update_slots: id  2 | task 223 | prompt processing progress, n_tokens = 13509, batch.n_tokens = 717, progress = 0.963209
2026-05-15 17:48:41.431 | slot update_slots: id  2 | task 223 | n_tokens = 13509, memory_seq_rm [13509, end)
2026-05-15 17:48:41.431 | slot update_slots: id  2 | task 223 | prompt processing progress, n_tokens = 14021, batch.n_tokens = 514, progress = 0.999715
2026-05-15 17:48:41.646 | slot create_check: id  2 | task 223 | created context checkpoint 7 of 32 (pos_min = 13508, pos_max = 13508, n_tokens = 13509, size = 177.918 MiB)
2026-05-15 17:48:41.898 | slot update_slots: id  2 | task 223 | n_tokens = 14021, memory_seq_rm [14021, end)
2026-05-15 17:48:41.901 | slot init_sampler: id  2 | task 223 | init sampler, took 2.01 ms, tokens: text = 14025, total = 14025
2026-05-15 17:48:41.901 | slot update_slots: id  2 | task 223 | prompt processing done, n_tokens = 14025, batch.n_tokens = 6
2026-05-15 17:48:42.122 | slot create_check: id  2 | task 223 | created context checkpoint 8 of 32 (pos_min = 14020, pos_max = 14020, n_tokens = 14021, size = 178.990 MiB)
2026-05-15 17:48:42.185 | srv  log_server_r: done request: POST /v1/chat/completions 172.18.0.1 200
2026-05-15 17:48:43.424 | reasoning-budget: deactivated (natural end)
2026-05-15 17:48:46.607 | slot print_timing: id  2 | task 223 | 
2026-05-15 17:48:46.607 | prompt eval time =    1100.06 ms /  1232 tokens (    0.89 ms per token,  1119.93 tokens per second)
2026-05-15 17:48:46.607 |        eval time =    4422.73 ms /   140 tokens (   31.59 ms per token,    31.65 tokens per second)
2026-05-15 17:48:46.608 |       total time =    5522.80 ms /  1372 tokens
2026-05-15 17:48:46.608 | draft acceptance rate = 0.98795 (   82 accepted /    83 generated)
2026-05-15 17:48:46.608 | statistics mtp: #calls(b,g,a) = 5 273 393, #gen drafts = 394, #acc drafts = 393, #gen tokens = 701, #acc tokens = 686, dur(b,g,a) = 0.010, 1332.920, 0.139 ms
2026-05-15 17:48:46.608 | slot      release: id  2 | task 223 | stop processing: n_tokens = 14164, truncated = 0
2026-05-15 17:48:46.844 | srv  params_from_: Chat format: peg-native
2026-05-15 17:48:46.866 | slot get_availabl: id  2 | task -1 | selected slot by LCP similarity, sim_best = 0.991 (> 0.100 thold), f_keep = 1.000
2026-05-15 17:48:46.867 | reasoning-budget: activated, budget=2147483647 tokens
2026-05-15 17:48:46.867 | slot launch_slot_: id  2 | task -1 | sampler chain: logits -> penalties -> ?dry -> ?top-n-sigma -> top-k -> ?typical -> ?top-p -> min-p -> ?xtc -> ?temp-ext -> dist 
2026-05-15 17:48:46.867 | slot launch_slot_: id  2 | task 295 | processing task, is_child = 0
2026-05-15 17:48:46.867 | slot update_slots: id  2 | task 295 | new prompt, n_ctx_slot = 131072, n_keep = 0, task.n_tokens = 14298
2026-05-15 17:48:46.867 | slot update_slots: id  2 | task 295 | n_tokens = 14164, memory_seq_rm [14164, end)
2026-05-15 17:48:46.867 | slot update_slots: id  2 | task 295 | prompt processing progress, n_tokens = 14294, batch.n_tokens = 132, progress = 0.999720
2026-05-15 17:48:47.098 | slot create_check: id  2 | task 295 | created context checkpoint 9 of 32 (pos_min = 14163, pos_max = 14163, n_tokens = 14164, size = 179.289 MiB)
2026-05-15 17:48:44.904 | slot update_slots: id  2 | task 295 | n_tokens = 14294, memory_seq_rm [14294, end)
2026-05-15 17:48:44.906 | slot init_sampler: id  2 | task 295 | init sampler, took 2.01 ms, tokens: text = 14298, total = 14298
2026-05-15 17:48:44.906 | slot update_slots: id  2 | task 295 | prompt processing done, n_tokens = 14298, batch.n_tokens = 6
2026-05-15 17:48:45.132 | slot create_check: id  2 | task 295 | created context checkpoint 10 of 32 (pos_min = 14293, pos_max = 14293, n_tokens = 14294, size = 179.562 MiB)
2026-05-15 17:48:45.194 | srv  log_server_r: done request: POST /v1/chat/completions 172.18.0.1 200
2026-05-15 17:48:50.060 | reasoning-budget: deactivated (natural end)
2026-05-15 17:48:52.974 | slot print_timing: id  2 | task 295 | 
2026-05-15 17:48:52.974 | prompt eval time =     632.53 ms /   134 tokens (    4.72 ms per token,   211.85 tokens per second)
2026-05-15 17:48:52.974 |        eval time =    7852.60 ms /   224 tokens (   35.06 ms per token,    28.53 tokens per second)
2026-05-15 17:48:52.974 |       total time =    8485.13 ms /   358 tokens
2026-05-15 17:48:52.974 | draft acceptance rate = 0.99167 (  119 accepted /   120 generated)
2026-05-15 17:48:52.974 | statistics mtp: #calls(b,g,a) = 6 391 544, #gen drafts = 544, #acc drafts = 544, #gen tokens = 963, #acc tokens = 945, dur(b,g,a) = 0.011, 1884.449, 0.204 ms
2026-05-15 17:48:52.974 | slot      release: id  2 | task 295 | stop processing: n_tokens = 14521, truncated = 0
2026-05-15 17:48:53.245 | srv  params_from_: Chat format: peg-native
2026-05-15 17:48:53.252 | slot get_availabl: id  2 | task -1 | selected slot by LCP similarity, sim_best = 0.693 (> 0.100 thold), f_keep = 1.000
2026-05-15 17:48:53.253 | reasoning-budget: activated, budget=2147483647 tokens
2026-05-15 17:48:53.253 | slot launch_slot_: id  2 | task -1 | sampler chain: logits -> penalties -> ?dry -> ?top-n-sigma -> top-k -> ?typical -> ?top-p -> min-p -> ?xtc -> ?temp-ext -> dist 
2026-05-15 17:48:53.253 | slot launch_slot_: id  2 | task 416 | processing task, is_child = 0
2026-05-15 17:48:53.253 | slot update_slots: id  2 | task 416 | new prompt, n_ctx_slot = 131072, n_keep = 0, task.n_tokens = 20949
2026-05-15 17:48:53.253 | slot update_slots: id  2 | task 416 | n_tokens = 14521, memory_seq_rm [14521, end)
2026-05-15 17:48:53.253 | slot update_slots: id  2 | task 416 | prompt processing progress, n_tokens = 16566, batch.n_tokens = 2048, progress = 0.790778
2026-05-15 17:48:54.141 | slot update_slots: id  2 | task 416 | n_tokens = 16566, memory_seq_rm [16566, end)
2026-05-15 17:48:54.141 | slot update_slots: id  2 | task 416 | prompt processing progress, n_tokens = 18611, batch.n_tokens = 2048, progress = 0.888396
2026-05-15 17:48:55.052 | slot update_slots: id  2 | task 416 | n_tokens = 18611, memory_seq_rm [18611, end)
2026-05-15 17:48:55.052 | slot update_slots: id  2 | task 416 | prompt processing progress, n_tokens = 20433, batch.n_tokens = 1824, progress = 0.975369
2026-05-15 17:48:55.893 | slot update_slots: id  2 | task 416 | n_tokens = 20433, memory_seq_rm [20433, end)
2026-05-15 17:48:55.893 | slot update_slots: id  2 | task 416 | prompt processing progress, n_tokens = 20945, batch.n_tokens = 514, progress = 0.999809
2026-05-15 17:48:56.139 | slot create_check: id  2 | task 416 | created context checkpoint 11 of 32 (pos_min = 20432, pos_max = 20432, n_tokens = 20433, size = 192.418 MiB)
2026-05-15 17:48:56.404 | slot update_slots: id  2 | task 416 | n_tokens = 20945, memory_seq_rm [20945, end)
2026-05-15 17:48:56.407 | slot init_sampler: id  2 | task 416 | init sampler, took 2.92 ms, tokens: text = 20949, total = 20949
2026-05-15 17:48:56.407 | slot update_slots: id  2 | task 416 | prompt processing done, n_tokens = 20949, batch.n_tokens = 6
2026-05-15 17:48:56.664 | slot create_check: id  2 | task 416 | created context checkpoint 12 of 32 (pos_min = 20944, pos_max = 20944, n_tokens = 20945, size = 193.491 MiB)
2026-05-15 17:48:56.732 | srv  log_server_r: done request: POST /v1/chat/completions 172.18.0.1 200
2026-05-15 17:48:58.409 | reasoning-budget: deactivated (natural end)
2026-05-15 17:49:02.017 | slot print_timing: id  2 | task 416 | 
2026-05-15 17:49:02.017 | prompt eval time =    3478.19 ms /  6428 tokens (    0.54 ms per token,  1848.09 tokens per second)
2026-05-15 17:49:02.017 |        eval time =    5285.46 ms /   166 tokens (   31.84 ms per token,    31.41 tokens per second)
2026-05-15 17:49:02.017 |       total time =    8763.65 ms /  6594 tokens
2026-05-15 17:49:02.017 | draft acceptance rate = 1.00000 (   97 accepted /    97 generated)
2026-05-15 17:49:02.017 | statistics mtp: #calls(b,g,a) = 7 473 659, #gen drafts = 660, #acc drafts = 659, #gen tokens = 1161, #acc tokens = 1140, dur(b,g,a) = 0.012, 2292.606, 0.251 ms
2026-05-15 17:49:02.018 | slot      release: id  2 | task 416 | stop processing: n_tokens = 21114, truncated = 0
2026-05-15 17:49:02.288 | srv  params_from_: Chat format: peg-native
2026-05-15 17:49:02.321 | slot get_availabl: id  2 | task -1 | selected slot by LCP similarity, sim_best = 0.857 (> 0.100 thold), f_keep = 1.000
2026-05-15 17:49:02.322 | reasoning-budget: activated, budget=2147483647 tokens
2026-05-15 17:49:02.323 | slot launch_slot_: id  2 | task -1 | sampler chain: logits -> penalties -> ?dry -> ?top-n-sigma -> top-k -> ?typical -> ?top-p -> min-p -> ?xtc -> ?temp-ext -> dist 
2026-05-15 17:49:02.323 | slot launch_slot_: id  2 | task 503 | processing task, is_child = 0
2026-05-15 17:49:02.330 | slot update_slots: id  2 | task 503 | new prompt, n_ctx_slot = 131072, n_keep = 0, task.n_tokens = 24649
2026-05-15 17:49:02.330 | slot update_slots: id  2 | task 503 | n_tokens = 21114, memory_seq_rm [21114, end)
2026-05-15 17:49:02.330 | slot update_slots: id  2 | task 503 | prompt processing progress, n_tokens = 23160, batch.n_tokens = 2048, progress = 0.939592
2026-05-15 17:49:03.276 | slot update_slots: id  2 | task 503 | n_tokens = 23160, memory_seq_rm [23160, end)
2026-05-15 17:49:03.276 | slot update_slots: id  2 | task 503 | prompt processing progress, n_tokens = 24133, batch.n_tokens = 976, progress = 0.979066
2026-05-15 17:49:03.763 | slot update_slots: id  2 | task 503 | n_tokens = 24133, memory_seq_rm [24133, end)
2026-05-15 17:49:03.763 | slot update_slots: id  2 | task 503 | prompt processing progress, n_tokens = 24645, batch.n_tokens = 515, progress = 0.999838
2026-05-15 17:49:04.035 | slot create_check: id  2 | task 503 | created context checkpoint 13 of 32 (pos_min = 24132, pos_max = 24132, n_tokens = 24133, size = 200.167 MiB)
2026-05-15 17:49:04.312 | slot update_slots: id  2 | task 503 | n_tokens = 24645, memory_seq_rm [24645, end)
2026-05-15 17:49:04.316 | slot init_sampler: id  2 | task 503 | init sampler, took 3.41 ms, tokens: text = 24649, total = 24649
2026-05-15 17:49:04.316 | slot update_slots: id  2 | task 503 | prompt processing done, n_tokens = 24649, batch.n_tokens = 7
2026-05-15 17:49:04.584 | slot create_check: id  2 | task 503 | created context checkpoint 14 of 32 (pos_min = 24644, pos_max = 24644, n_tokens = 24645, size = 201.239 MiB)
2026-05-15 17:49:04.651 | srv  log_server_r: done request: POST /v1/chat/completions 172.18.0.1 200
2026-05-15 17:49:07.940 | reasoning-budget: deactivated (natural end)
2026-05-15 17:49:11.884 | slot print_timing: id  2 | task 503 | 
2026-05-15 17:49:11.884 | prompt eval time =    2320.60 ms /  3535 tokens (    0.66 ms per token,  1523.31 tokens per second)
2026-05-15 17:49:11.884 |        eval time =    7232.81 ms /   213 tokens (   33.96 ms per token,    29.45 tokens per second)
2026-05-15 17:49:11.884 |       total time =    9553.41 ms /  3748 tokens
2026-05-15 17:49:11.884 | draft acceptance rate = 1.00000 (  117 accepted /   117 generated)
2026-05-15 17:49:11.884 | statistics mtp: #calls(b,g,a) = 8 583 814, #gen drafts = 815, #acc drafts = 814, #gen tokens = 1436, #acc tokens = 1412, dur(b,g,a) = 0.013, 2835.433, 0.313 ms
2026-05-15 17:49:11.885 | slot      release: id  2 | task 503 | stop processing: n_tokens = 24861, truncated = 0
2026-05-15 17:49:12.087 | srv  params_from_: Chat format: peg-native
2026-05-15 17:49:12.108 | slot get_availabl: id  2 | task -1 | selected slot by LCP similarity, sim_best = 0.944 (> 0.100 thold), f_keep = 1.000
2026-05-15 17:49:12.109 | reasoning-budget: activated, budget=2147483647 tokens
2026-05-15 17:49:12.109 | slot launch_slot_: id  2 | task -1 | sampler chain: logits -> penalties -> ?dry -> ?top-n-sigma -> top-k -> ?typical -> ?top-p -> min-p -> ?xtc -> ?temp-ext -> dist 
2026-05-15 17:49:12.109 | slot launch_slot_: id  2 | task 610 | processing task, is_child = 0
2026-05-15 17:49:12.117 | slot update_slots: id  2 | task 610 | new prompt, n_ctx_slot = 131072, n_keep = 0, task.n_tokens = 26345
2026-05-15 17:49:12.117 | slot update_slots: id  2 | task 610 | n_tokens = 24861, memory_seq_rm [24861, end)
2026-05-15 17:49:12.117 | slot update_slots: id  2 | task 610 | prompt processing progress, n_tokens = 25829, batch.n_tokens = 970, progress = 0.980414
2026-05-15 17:49:12.615 | slot update_slots: id  2 | task 610 | n_tokens = 25829, memory_seq_rm [25829, end)
2026-05-15 17:49:12.615 | slot update_slots: id  2 | task 610 | prompt processing progress, n_tokens = 26341, batch.n_tokens = 515, progress = 0.999848
2026-05-15 17:49:12.894 | slot create_check: id  2 | task 610 | created context checkpoint 15 of 32 (pos_min = 25828, pos_max = 25828, n_tokens = 25829, size = 203.719 MiB)
2026-05-15 17:49:13.180 | slot update_slots: id  2 | task 610 | n_tokens = 26341, memory_seq_rm [26341, end)
2026-05-15 17:49:13.183 | slot init_sampler: id  2 | task 610 | init sampler, took 3.63 ms, tokens: text = 26345, total = 26345
2026-05-15 17:49:13.184 | slot update_slots: id  2 | task 610 | prompt processing done, n_tokens = 26345, batch.n_tokens = 7
2026-05-15 17:49:13.463 | slot create_check: id  2 | task 610 | created context checkpoint 16 of 32 (pos_min = 26340, pos_max = 26340, n_tokens = 26341, size = 204.791 MiB)
2026-05-15 17:49:13.529 | srv  log_server_r: done request: POST /v1/chat/completions 172.18.0.1 200
2026-05-15 17:49:20.633 | slot print_timing: id  3 | task 0 | 
2026-05-15 17:49:20.633 | prompt eval time =    8579.51 ms /   903 tokens (    9.50 ms per token,   105.25 tokens per second)
2026-05-15 17:49:20.633 |        eval time =   60298.55 ms /  1595 tokens (   37.80 ms per token,    26.45 tokens per second)
2026-05-15 17:49:20.633 |       total time =   68878.06 ms /  2498 tokens
2026-05-15 17:49:20.633 | draft acceptance rate = 0.98488 (  912 accepted /   926 generated)
2026-05-15 17:49:20.633 | statistics mtp: #calls(b,g,a) = 9 717 990, #gen drafts = 990, #acc drafts = 990, #gen tokens = 1744, #acc tokens = 1718, dur(b,g,a) = 0.015, 3507.560, 0.387 ms
2026-05-15 17:49:20.633 | slot      release: id  3 | task 0 | stop processing: n_tokens = 2497, truncated = 0
2026-05-15 17:49:23.694 | reasoning-budget: deactivated (natural end)
2026-05-15 17:49:24.153 | slot print_timing: id  2 | task 610 | 
2026-05-15 17:49:24.153 | prompt eval time =    1411.92 ms /  1484 tokens (    0.95 ms per token,  1051.05 tokens per second)
2026-05-15 17:49:24.153 |        eval time =   12857.62 ms /   415 tokens (   30.98 ms per token,    32.28 tokens per second)
2026-05-15 17:49:24.153 |       total time =   14269.54 ms /  1899 tokens
2026-05-15 17:49:24.153 | draft acceptance rate = 0.97608 (  204 accepted /   209 generated)
2026-05-15 17:49:24.153 | statistics mtp: #calls(b,g,a) = 9 811 1048, #gen drafts = 1048, #acc drafts = 1048, #gen tokens = 1836, #acc tokens = 1809, dur(b,g,a) = 0.015, 3845.585, 0.406 ms
2026-05-15 17:49:24.154 | slot      release: id  2 | task 610 | stop processing: n_tokens = 26759, truncated = 0
2026-05-15 17:49:24.154 | srv  update_slots: all slots are idle
2026-05-15 17:49:24.340 | srv  params_from_: Chat format: peg-native
2026-05-15 17:49:24.343 | slot get_availabl: id  2 | task -1 | selected slot by LCP similarity, sim_best = 0.999 (> 0.100 thold), f_keep = 1.000
2026-05-15 17:49:24.344 | reasoning-budget: activated, budget=2147483647 tokens
2026-05-15 17:49:24.344 | slot launch_slot_: id  2 | task -1 | sampler chain: logits -> penalties -> ?dry -> ?top-n-sigma -> top-k -> ?typical -> ?top-p -> min-p -> ?xtc -> ?temp-ext -> dist 
2026-05-15 17:49:24.344 | slot launch_slot_: id  2 | task 841 | processing task, is_child = 0
2026-05-15 17:49:24.344 | slot slot_save_an: id  3 | task -1 | saving idle slot to prompt cache
2026-05-15 17:49:24.345 | srv   prompt_save:  - saving prompt with length 2497, total state size = 237.812 MiB (draft: 5.229 MiB)
2026-05-15 17:49:25.635 | slot prompt_clear: id  3 | task -1 | clearing prompt with 2497 tokens
2026-05-15 17:49:25.637 | srv        update:  - cache state: 1 prompts, 539.757 MiB (limits: 8192.000 MiB, 131072 tokens, 131072 est)
2026-05-15 17:49:25.637 | srv        update:    - prompt 0x6487e845e240:    2497 tokens, checkpoints:  2,   539.757 MiB
2026-05-15 17:49:25.637 | slot update_slots: id  2 | task 841 | new prompt, n_ctx_slot = 131072, n_keep = 0, task.n_tokens = 26784
2026-05-15 17:49:25.637 | slot update_slots: id  2 | task 841 | n_tokens = 26759, memory_seq_rm [26759, end)
2026-05-15 17:49:25.637 | slot update_slots: id  2 | task 841 | prompt processing progress, n_tokens = 26780, batch.n_tokens = 21, progress = 0.999851
2026-05-15 17:49:25.920 | slot create_check: id  2 | task 841 | created context checkpoint 17 of 32 (pos_min = 26758, pos_max = 26758, n_tokens = 26759, size = 205.667 MiB)
2026-05-15 17:49:25.962 | slot update_slots: id  2 | task 841 | n_tokens = 26780, memory_seq_rm [26780, end)
2026-05-15 17:49:25.966 | slot init_sampler: id  2 | task 841 | init sampler, took 3.74 ms, tokens: text = 26784, total = 26784
2026-05-15 17:49:25.966 | slot update_slots: id  2 | task 841 | prompt processing done, n_tokens = 26784, batch.n_tokens = 4
2026-05-15 17:49:26.001 | srv  log_server_r: done request: POST /v1/chat/completions 172.18.0.1 200
2026-05-15 17:49:29.404 | reasoning-budget: deactivated (natural end)
2026-05-15 17:49:29.849 | slot print_timing: id  2 | task 841 | 
2026-05-15 17:49:29.849 | prompt eval time =     363.56 ms /    25 tokens (   14.54 ms per token,    68.76 tokens per second)
2026-05-15 17:49:29.849 |        eval time =    3848.00 ms /   214 tokens (   17.98 ms per token,    55.61 tokens per second)
2026-05-15 17:49:29.849 |       total time =    4211.56 ms /   239 tokens
2026-05-15 17:49:29.849 | draft acceptance rate = 0.99167 (  119 accepted /   120 generated)
2026-05-15 17:49:29.849 | statistics mtp: #calls(b,g,a) = 10 905 1117, #gen drafts = 1117, #acc drafts = 1117, #gen tokens = 1956, #acc tokens = 1928, dur(b,g,a) = 0.016, 4233.493, 0.433 ms
2026-05-15 17:49:29.849 | slot      release: id  2 | task 841 | stop processing: n_tokens = 26997, truncated = 0
2026-05-15 17:49:29.849 | srv  update_slots: all slots are idle
2026-05-15 17:49:30.067 | srv  params_from_: Chat format: peg-native
2026-05-15 17:49:30.070 | slot get_availabl: id  2 | task -1 | selected slot by LCP similarity, sim_best = 0.998 (> 0.100 thold), f_keep = 1.000
2026-05-15 17:49:30.072 | reasoning-budget: activated, budget=2147483647 tokens
2026-05-15 17:49:30.072 | slot launch_slot_: id  2 | task -1 | sampler chain: logits -> penalties -> ?dry -> ?top-n-sigma -> top-k -> ?typical -> ?top-p -> min-p -> ?xtc -> ?temp-ext -> dist 
2026-05-15 17:49:30.072 | slot launch_slot_: id  2 | task 947 | processing task, is_child = 0
2026-05-15 17:49:30.072 | slot update_slots: id  2 | task 947 | new prompt, n_ctx_slot = 131072, n_keep = 0, task.n_tokens = 27055
2026-05-15 17:49:30.072 | slot update_slots: id  2 | task 947 | n_tokens = 26997, memory_seq_rm [26997, end)
2026-05-15 17:49:30.072 | slot update_slots: id  2 | task 947 | prompt processing progress, n_tokens = 27051, batch.n_tokens = 54, progress = 0.999852
2026-05-15 17:49:30.367 | slot create_check: id  2 | task 947 | created context checkpoint 18 of 32 (pos_min = 26996, pos_max = 26996, n_tokens = 26997, size = 206.165 MiB)
2026-05-15 17:49:30.420 | slot update_slots: id  2 | task 947 | n_tokens = 27051, memory_seq_rm [27051, end)
2026-05-15 17:49:30.424 | slot init_sampler: id  2 | task 947 | init sampler, took 3.76 ms, tokens: text = 27055, total = 27055
2026-05-15 17:49:30.424 | slot update_slots: id  2 | task 947 | prompt processing done, n_tokens = 27055, batch.n_tokens = 4
2026-05-15 17:49:30.464 | srv  log_server_r: done request: POST /v1/chat/completions 172.18.0.1 200
2026-05-15 17:49:31.628 | reasoning-budget: deactivated (natural end)
2026-05-15 17:49:32.087 | slot print_timing: id  2 | task 947 | 
2026-05-15 17:49:32.087 | prompt eval time =     392.03 ms /    58 tokens (    6.76 ms per token,   147.95 tokens per second)
2026-05-15 17:49:32.087 |        eval time =    1622.58 ms /    90 tokens (   18.03 ms per token,    55.47 tokens per second)
2026-05-15 17:49:32.087 |       total time =    2014.62 ms /   148 tokens
2026-05-15 17:49:32.087 | draft acceptance rate = 0.97917 (   47 accepted /    48 generated)
2026-05-15 17:49:32.087 | statistics mtp: #calls(b,g,a) = 11 947 1143, #gen drafts = 1143, #acc drafts = 1143, #gen tokens = 2004, #acc tokens = 1975, dur(b,g,a) = 0.017, 4390.030, 0.444 ms
2026-05-15 17:49:32.087 | slot      release: id  2 | task 947 | stop processing: n_tokens = 27144, truncated = 0
2026-05-15 17:49:32.087 | srv  update_slots: all slots are idle
2026-05-15 17:49:32.297 | srv  params_from_: Chat format: peg-native
2026-05-15 17:49:32.300 | slot get_availabl: id  2 | task -1 | selected slot by LCP similarity, sim_best = 0.998 (> 0.100 thold), f_keep = 1.000
2026-05-15 17:49:32.301 | reasoning-budget: activated, budget=2147483647 tokens
2026-05-15 17:49:32.301 | slot launch_slot_: id  2 | task -1 | sampler chain: logits -> penalties -> ?dry -> ?top-n-sigma -> top-k -> ?typical -> ?top-p -> min-p -> ?xtc -> ?temp-ext -> dist 
2026-05-15 17:49:32.301 | slot launch_slot_: id  2 | task 997 | processing task, is_child = 0
2026-05-15 17:49:32.301 | slot update_slots: id  2 | task 997 | new prompt, n_ctx_slot = 131072, n_keep = 0, task.n_tokens = 27211
2026-05-15 17:49:32.301 | slot update_slots: id  2 | task 997 | n_tokens = 27144, memory_seq_rm [27144, end)
2026-05-15 17:49:32.301 | slot update_slots: id  2 | task 997 | prompt processing progress, n_tokens = 27207, batch.n_tokens = 63, progress = 0.999853
2026-05-15 17:49:32.592 | slot create_check: id  2 | task 997 | created context checkpoint 19 of 32 (pos_min = 27143, pos_max = 27143, n_tokens = 27144, size = 206.473 MiB)
2026-05-15 17:49:32.648 | slot update_slots: id  2 | task 997 | n_tokens = 27207, memory_seq_rm [27207, end)
2026-05-15 17:49:32.651 | slot init_sampler: id  2 | task 997 | init sampler, took 3.73 ms, tokens: text = 27211, total = 27211
2026-05-15 17:49:32.651 | slot update_slots: id  2 | task 997 | prompt processing done, n_tokens = 27211, batch.n_tokens = 4
2026-05-15 17:49:32.690 | srv  log_server_r: done request: POST /v1/chat/completions 172.18.0.1 200
2026-05-15 17:49:34.900 | reasoning-budget: deactivated (natural end)
2026-05-15 17:49:35.679 | slot print_timing: id  2 | task 997 | 
2026-05-15 17:49:35.679 | prompt eval time =     388.79 ms /    67 tokens (    5.80 ms per token,   172.33 tokens per second)
2026-05-15 17:49:35.679 |        eval time =    2989.26 ms /   152 tokens (   19.67 ms per token,    50.85 tokens per second)
2026-05-15 17:49:35.679 |       total time =    3378.05 ms /   219 tokens
2026-05-15 17:49:35.679 | draft acceptance rate = 0.96341 (   79 accepted /    82 generated)
2026-05-15 17:49:35.679 | statistics mtp: #calls(b,g,a) = 12 1019 1191, #gen drafts = 1191, #acc drafts = 1191, #gen tokens = 2086, #acc tokens = 2054, dur(b,g,a) = 0.018, 4668.115, 0.466 ms
2026-05-15 17:49:35.680 | slot      release: id  2 | task 997 | stop processing: n_tokens = 27362, truncated = 0
2026-05-15 17:49:35.680 | srv  update_slots: all slots are idle
2026-05-15 17:49:35.967 | srv  params_from_: Chat format: peg-native
2026-05-15 17:49:35.970 | slot get_availabl: id  2 | task -1 | selected slot by LCP similarity, sim_best = 0.999 (> 0.100 thold), f_keep = 1.000
2026-05-15 17:49:35.971 | reasoning-budget: activated, budget=2147483647 tokens
2026-05-15 17:49:35.971 | slot launch_slot_: id  2 | task -1 | sampler chain: logits -> penalties -> ?dry -> ?top-n-sigma -> top-k -> ?typical -> ?top-p -> min-p -> ?xtc -> ?temp-ext -> dist 
2026-05-15 17:49:35.971 | slot launch_slot_: id  2 | task 1081 | processing task, is_child = 0
2026-05-15 17:49:35.971 | slot update_slots: id  2 | task 1081 | new prompt, n_ctx_slot = 131072, n_keep = 0, task.n_tokens = 27383
2026-05-15 17:49:35.971 | slot update_slots: id  2 | task 1081 | n_tokens = 27362, memory_seq_rm [27362, end)
2026-05-15 17:49:35.971 | slot update_slots: id  2 | task 1081 | prompt processing progress, n_tokens = 27379, batch.n_tokens = 17, progress = 0.999854
2026-05-15 17:49:36.252 | slot create_check: id  2 | task 1081 | created context checkpoint 20 of 32 (pos_min = 27361, pos_max = 27361, n_tokens = 27362, size = 206.930 MiB)
2026-05-15 17:49:36.299 | slot update_slots: id  2 | task 1081 | n_tokens = 27379, memory_seq_rm [27379, end)
2026-05-15 17:49:36.303 | slot init_sampler: id  2 | task 1081 | init sampler, took 3.87 ms, tokens: text = 27383, total = 27383
2026-05-15 17:49:36.303 | slot update_slots: id  2 | task 1081 | prompt processing done, n_tokens = 27383, batch.n_tokens = 4
2026-05-15 17:49:36.345 | srv  log_server_r: done request: POST /v1/chat/completions 172.18.0.1 200
2026-05-15 17:49:36.610 | reasoning-budget: deactivated (natural end)
2026-05-15 17:49:37.372 | slot print_timing: id  2 | task 1081 | 
2026-05-15 17:49:37.372 | prompt eval time =     372.98 ms /    21 tokens (   17.76 ms per token,    56.30 tokens per second)
2026-05-15 17:49:37.372 |        eval time =    1027.24 ms /    74 tokens (   13.88 ms per token,    72.04 tokens per second)
2026-05-15 17:49:37.372 |       total time =    1400.22 ms /    95 tokens
2026-05-15 17:49:37.372 | draft acceptance rate = 0.97872 (   46 accepted /    47 generated)
2026-05-15 17:49:37.372 | statistics mtp: #calls(b,g,a) = 13 1046 1216, #gen drafts = 1216, #acc drafts = 1216, #gen tokens = 2133, #acc tokens = 2100, dur(b,g,a) = 0.019, 4786.815, 0.475 ms
2026-05-15 17:49:37.373 | slot      release: id  2 | task 1081 | stop processing: n_tokens = 27456, truncated = 0
2026-05-15 17:49:37.373 | srv  update_slots: all slots are idle
2026-05-15 17:49:37.617 | srv  params_from_: Chat format: peg-native
2026-05-15 17:49:37.620 | slot get_availabl: id  2 | task -1 | selected slot by LCP similarity, sim_best = 0.601 (> 0.100 thold), f_keep = 1.000
2026-05-15 17:49:37.621 | reasoning-budget: activated, budget=2147483647 tokens
2026-05-15 17:49:37.621 | slot launch_slot_: id  2 | task -1 | sampler chain: logits -> penalties -> ?dry -> ?top-n-sigma -> top-k -> ?typical -> ?top-p -> min-p -> ?xtc -> ?temp-ext -> dist 
2026-05-15 17:49:37.621 | slot launch_slot_: id  2 | task 1112 | processing task, is_child = 0
2026-05-15 17:49:37.621 | slot update_slots: id  2 | task 1112 | new prompt, n_ctx_slot = 131072, n_keep = 0, task.n_tokens = 45652
2026-05-15 17:49:37.621 | slot update_slots: id  2 | task 1112 | n_tokens = 27456, memory_seq_rm [27456, end)
2026-05-15 17:49:37.622 | slot update_slots: id  2 | task 1112 | prompt processing progress, n_tokens = 29504, batch.n_tokens = 2048, progress = 0.646281
2026-05-15 17:49:38.596 | slot update_slots: id  2 | task 1112 | n_tokens = 29504, memory_seq_rm [29504, end)
2026-05-15 17:49:38.596 | slot update_slots: id  2 | task 1112 | prompt processing progress, n_tokens = 31552, batch.n_tokens = 2048, progress = 0.691142
2026-05-15 17:49:39.598 | slot update_slots: id  2 | task 1112 | n_tokens = 31552, memory_seq_rm [31552, end)
2026-05-15 17:49:39.598 | slot update_slots: id  2 | task 1112 | prompt processing progress, n_tokens = 33600, batch.n_tokens = 2048, progress = 0.736003
2026-05-15 17:49:40.610 | slot update_slots: id  2 | task 1112 | n_tokens = 33600, memory_seq_rm [33600, end)
2026-05-15 17:49:40.610 | slot update_slots: id  2 | task 1112 | prompt processing progress, n_tokens = 35648, batch.n_tokens = 2048, progress = 0.780864
2026-05-15 17:49:41.628 | slot update_slots: id  2 | task 1112 | n_tokens = 35648, memory_seq_rm [35648, end)
2026-05-15 17:49:41.628 | slot update_slots: id  2 | task 1112 | 8192 tokens since last checkpoint at 27362, creating new checkpoint during processing at position 37696
2026-05-15 17:49:41.628 | slot update_slots: id  2 | task 1112 | prompt processing progress, n_tokens = 37696, batch.n_tokens = 2048, progress = 0.825725
2026-05-15 17:49:41.894 | slot create_check: id  2 | task 1112 | created context checkpoint 21 of 32 (pos_min = 35647, pos_max = 35647, n_tokens = 35648, size = 224.283 MiB)
2026-05-15 17:49:40.653 | slot update_slots: id  2 | task 1112 | n_tokens = 37696, memory_seq_rm [37696, end)
2026-05-15 17:49:40.653 | slot update_slots: id  2 | task 1112 | prompt processing progress, n_tokens = 39744, batch.n_tokens = 2048, progress = 0.870586
2026-05-15 17:49:41.685 | slot update_slots: id  2 | task 1112 | n_tokens = 39744, memory_seq_rm [39744, end)
2026-05-15 17:49:41.685 | slot update_slots: id  2 | task 1112 | prompt processing progress, n_tokens = 41792, batch.n_tokens = 2048, progress = 0.915447
2026-05-15 17:49:42.798 | slot update_slots: id  2 | task 1112 | n_tokens = 41792, memory_seq_rm [41792, end)
2026-05-15 17:49:42.798 | slot update_slots: id  2 | task 1112 | prompt processing progress, n_tokens = 43840, batch.n_tokens = 2048, progress = 0.960308
2026-05-15 17:49:43.939 | slot update_slots: id  2 | task 1112 | n_tokens = 43840, memory_seq_rm [43840, end)
2026-05-15 17:49:43.939 | slot update_slots: id  2 | task 1112 | 8192 tokens since last checkpoint at 35648, creating new checkpoint during processing at position 45136
2026-05-15 17:49:43.939 | slot update_slots: id  2 | task 1112 | prompt processing progress, n_tokens = 45136, batch.n_tokens = 1296, progress = 0.988697
2026-05-15 17:49:44.226 | slot create_check: id  2 | task 1112 | created context checkpoint 22 of 32 (pos_min = 43839, pos_max = 43839, n_tokens = 43840, size = 241.439 MiB)
2026-05-15 17:49:44.972 | slot update_slots: id  2 | task 1112 | n_tokens = 45136, memory_seq_rm [45136, end)
2026-05-15 17:49:44.972 | slot update_slots: id  2 | task 1112 | prompt processing progress, n_tokens = 45648, batch.n_tokens = 512, progress = 0.999912
2026-05-15 17:49:45.249 | slot create_check: id  2 | task 1112 | created context checkpoint 23 of 32 (pos_min = 45135, pos_max = 45135, n_tokens = 45136, size = 244.153 MiB)
2026-05-15 17:49:45.540 | slot update_slots: id  2 | task 1112 | n_tokens = 45648, memory_seq_rm [45648, end)
2026-05-15 17:49:45.547 | slot init_sampler: id  2 | task 1112 | init sampler, took 6.44 ms, tokens: text = 45652, total = 45652
2026-05-15 17:49:45.547 | slot update_slots: id  2 | task 1112 | prompt processing done, n_tokens = 45652, batch.n_tokens = 4
2026-05-15 17:49:45.843 | slot create_check: id  2 | task 1112 | created context checkpoint 24 of 32 (pos_min = 45647, pos_max = 45647, n_tokens = 45648, size = 245.225 MiB)
2026-05-15 17:49:45.886 | srv  log_server_r: done request: POST /v1/chat/completions 172.18.0.1 200
2026-05-15 17:49:46.765 | reasoning-budget: deactivated (natural end)
2026-05-15 17:49:48.199 | slot print_timing: id  2 | task 1112 | 
2026-05-15 17:49:48.199 | prompt eval time =   10616.21 ms / 18196 tokens (    0.58 ms per token,  1713.98 tokens per second)
2026-05-15 17:49:48.199 |        eval time =    2312.85 ms /   126 tokens (   18.36 ms per token,    54.48 tokens per second)
2026-05-15 17:49:48.199 |       total time =   12929.05 ms / 18322 tokens
2026-05-15 17:49:48.199 | draft acceptance rate = 1.00000 (   72 accepted /    72 generated)
2026-05-15 17:49:48.199 | statistics mtp: #calls(b,g,a) = 14 1099 1258, #gen drafts = 1258, #acc drafts = 1258, #gen tokens = 2205, #acc tokens = 2172, dur(b,g,a) = 0.021, 5010.409, 0.485 ms
2026-05-15 17:49:48.200 | slot      release: id  2 | task 1112 | stop processing: n_tokens = 45777, truncated = 0
2026-05-15 17:49:48.200 | srv  update_slots: all slots are idle
2026-05-15 17:49:48.459 | srv  params_from_: Chat format: peg-native
2026-05-15 17:49:48.462 | slot get_availabl: id  2 | task -1 | selected slot by LCP similarity, sim_best = 1.000 (> 0.100 thold), f_keep = 1.000
2026-05-15 17:49:48.463 | reasoning-budget: activated, budget=2147483647 tokens
2026-05-15 17:49:48.463 | slot launch_slot_: id  2 | task -1 | sampler chain: logits -> penalties -> ?dry -> ?top-n-sigma -> top-k -> ?typical -> ?top-p -> min-p -> ?xtc -> ?temp-ext -> dist 
2026-05-15 17:49:48.463 | slot launch_slot_: id  2 | task 1183 | processing task, is_child = 0
2026-05-15 17:49:48.463 | slot update_slots: id  2 | task 1183 | new prompt, n_ctx_slot = 131072, n_keep = 0, task.n_tokens = 45796
2026-05-15 17:49:48.463 | slot update_slots: id  2 | task 1183 | n_tokens = 45777, memory_seq_rm [45777, end)
2026-05-15 17:49:48.463 | slot update_slots: id  2 | task 1183 | prompt processing progress, n_tokens = 45792, batch.n_tokens = 15, progress = 0.999913
2026-05-15 17:49:48.754 | slot create_check: id  2 | task 1183 | created context checkpoint 25 of 32 (pos_min = 45776, pos_max = 45776, n_tokens = 45777, size = 245.496 MiB)
2026-05-15 17:49:48.797 | slot update_slots: id  2 | task 1183 | n_tokens = 45792, memory_seq_rm [45792, end)
2026-05-15 17:49:48.803 | slot init_sampler: id  2 | task 1183 | init sampler, took 6.25 ms, tokens: text = 45796, total = 45796
2026-05-15 17:49:48.803 | slot update_slots: id  2 | task 1183 | prompt processing done, n_tokens = 45796, batch.n_tokens = 4
2026-05-15 17:49:48.842 | srv  log_server_r: done request: POST /v1/chat/completions 172.18.0.1 200
2026-05-15 17:49:49.734 | reasoning-budget: deactivated (natural end)
2026-05-15 17:49:50.845 | slot print_timing: id  2 | task 1183 | 
2026-05-15 17:49:50.845 | prompt eval time =     378.72 ms /    19 tokens (   19.93 ms per token,    50.17 tokens per second)
2026-05-15 17:49:50.845 |        eval time =    2002.59 ms /   111 tokens (   18.04 ms per token,    55.43 tokens per second)
2026-05-15 17:49:50.845 |       total time =    2381.31 ms /   130 tokens
2026-05-15 17:49:50.845 | draft acceptance rate = 1.00000 (   59 accepted /    59 generated)
2026-05-15 17:49:50.845 | statistics mtp: #calls(b,g,a) = 15 1150 1292, #gen drafts = 1292, #acc drafts = 1292, #gen tokens = 2264, #acc tokens = 2231, dur(b,g,a) = 0.022, 5204.355, 0.501 ms
2026-05-15 17:49:50.846 | slot      release: id  2 | task 1183 | stop processing: n_tokens = 45906, truncated = 0
2026-05-15 17:49:50.846 | srv  update_slots: all slots are idle
2026-05-15 17:49:51.082 | srv  params_from_: Chat format: peg-native
2026-05-15 17:49:51.085 | slot get_availabl: id  2 | task -1 | selected slot by LCP similarity, sim_best = 1.000 (> 0.100 thold), f_keep = 1.000
2026-05-15 17:49:51.086 | reasoning-budget: activated, budget=2147483647 tokens
2026-05-15 17:49:51.086 | slot launch_slot_: id  2 | task -1 | sampler chain: logits -> penalties -> ?dry -> ?top-n-sigma -> top-k -> ?typical -> ?top-p -> min-p -> ?xtc -> ?temp-ext -> dist 
2026-05-15 17:49:51.086 | slot launch_slot_: id  2 | task 1241 | processing task, is_child = 0
2026-05-15 17:49:51.086 | slot update_slots: id  2 | task 1241 | new prompt, n_ctx_slot = 131072, n_keep = 0, task.n_tokens = 45925
2026-05-15 17:49:51.086 | slot update_slots: id  2 | task 1241 | n_tokens = 45906, memory_seq_rm [45906, end)
2026-05-15 17:49:51.087 | slot update_slots: id  2 | task 1241 | prompt processing progress, n_tokens = 45921, batch.n_tokens = 15, progress = 0.999913
2026-05-15 17:49:51.376 | slot create_check: id  2 | task 1241 | created context checkpoint 26 of 32 (pos_min = 45905, pos_max = 45905, n_tokens = 45906, size = 245.766 MiB)
2026-05-15 17:49:51.418 | slot update_slots: id  2 | task 1241 | n_tokens = 45921, memory_seq_rm [45921, end)
2026-05-15 17:49:51.425 | slot init_sampler: id  2 | task 1241 | init sampler, took 6.37 ms, tokens: text = 45925, total = 45925
2026-05-15 17:49:51.425 | slot update_slots: id  2 | task 1241 | prompt processing done, n_tokens = 45925, batch.n_tokens = 4
2026-05-15 17:49:51.464 | srv  log_server_r: done request: POST /v1/chat/completions 172.18.0.1 200
2026-05-15 17:49:52.372 | reasoning-budget: deactivated (natural end)
2026-05-15 17:49:53.631 | slot print_timing: id  2 | task 1241 | 
2026-05-15 17:49:53.631 | prompt eval time =     376.86 ms /    19 tokens (   19.83 ms per token,    50.42 tokens per second)
2026-05-15 17:49:53.631 |        eval time =    2167.56 ms /   124 tokens (   17.48 ms per token,    57.21 tokens per second)
2026-05-15 17:49:53.631 |       total time =    2544.41 ms /   143 tokens
2026-05-15 17:49:53.631 | draft acceptance rate = 0.95946 (   71 accepted /    74 generated)
2026-05-15 17:49:53.631 | statistics mtp: #calls(b,g,a) = 16 1202 1335, #gen drafts = 1335, #acc drafts = 1335, #gen tokens = 2338, #acc tokens = 2302, dur(b,g,a) = 0.023, 5420.197, 0.517 ms
2026-05-15 17:49:53.632 | slot      release: id  2 | task 1241 | stop processing: n_tokens = 46048, truncated = 0
2026-05-15 17:49:53.632 | srv  update_slots: all slots are idle
2026-05-15 17:50:20.439 | srv  params_from_: Chat format: peg-native
2026-05-15 17:50:20.442 | slot get_availabl: id  2 | task -1 | selected slot by LCP similarity, sim_best = 0.999 (> 0.100 thold), f_keep = 1.000
2026-05-15 17:50:20.443 | reasoning-budget: activated, budget=2147483647 tokens
2026-05-15 17:50:20.443 | slot launch_slot_: id  2 | task -1 | sampler chain: logits -> penalties -> ?dry -> ?top-n-sigma -> top-k -> ?typical -> ?top-p -> min-p -> ?xtc -> ?temp-ext -> dist 
2026-05-15 17:50:20.443 | slot launch_slot_: id  2 | task 1301 | processing task, is_child = 0
2026-05-15 17:50:20.443 | slot update_slots: id  2 | task 1301 | new prompt, n_ctx_slot = 131072, n_keep = 0, task.n_tokens = 46114
2026-05-15 17:50:20.443 | slot update_slots: id  2 | task 1301 | n_tokens = 46048, memory_seq_rm [46048, end)
2026-05-15 17:50:20.443 | slot update_slots: id  2 | task 1301 | prompt processing progress, n_tokens = 46110, batch.n_tokens = 62, progress = 0.999913
2026-05-15 17:50:20.752 | slot create_check: id  2 | task 1301 | created context checkpoint 27 of 32 (pos_min = 46047, pos_max = 46047, n_tokens = 46048, size = 246.063 MiB)
2026-05-15 17:50:21.038 | slot update_slots: id  2 | task 1301 | n_tokens = 46110, memory_seq_rm [46110, end)
2026-05-15 17:50:21.045 | slot init_sampler: id  2 | task 1301 | init sampler, took 6.29 ms, tokens: text = 46114, total = 46114
2026-05-15 17:50:21.045 | slot update_slots: id  2 | task 1301 | prompt processing done, n_tokens = 46114, batch.n_tokens = 4
2026-05-15 17:50:21.083 | srv  log_server_r: done request: POST /v1/chat/completions 172.18.0.1 200
2026-05-15 17:50:21.846 | reasoning-budget: deactivated (natural end)
2026-05-15 17:50:23.165 | slot print_timing: id  2 | task 1301 | 
2026-05-15 17:50:23.165 | prompt eval time =     639.29 ms /    66 tokens (    9.69 ms per token,   103.24 tokens per second)
2026-05-15 17:50:23.165 |        eval time =    2082.57 ms /   130 tokens (   16.02 ms per token,    62.42 tokens per second)
2026-05-15 17:50:23.165 |       total time =    2721.87 ms /   196 tokens
2026-05-15 17:50:23.165 | draft acceptance rate = 0.98718 (   77 accepted /    78 generated)
2026-05-15 17:50:23.165 | statistics mtp: #calls(b,g,a) = 17 1254 1379, #gen drafts = 1379, #acc drafts = 1379, #gen tokens = 2416, #acc tokens = 2379, dur(b,g,a) = 0.024, 5644.228, 0.540 ms
2026-05-15 17:50:23.167 | slot      release: id  2 | task 1301 | stop processing: n_tokens = 46243, truncated = 0
2026-05-15 17:50:23.167 | srv  update_slots: all slots are idle
2026-05-15 17:50:23.418 | srv  params_from_: Chat format: peg-native
2026-05-15 17:50:23.421 | slot get_availabl: id  2 | task -1 | selected slot by LCP similarity, sim_best = 0.686 (> 0.100 thold), f_keep = 1.000
2026-05-15 17:50:23.422 | reasoning-budget: activated, budget=2147483647 tokens
2026-05-15 17:50:23.422 | slot launch_slot_: id  2 | task -1 | sampler chain: logits -> penalties -> ?dry -> ?top-n-sigma -> top-k -> ?typical -> ?top-p -> min-p -> ?xtc -> ?temp-ext -> dist 
2026-05-15 17:50:23.422 | slot launch_slot_: id  2 | task 1358 | processing task, is_child = 0
2026-05-15 17:50:23.422 | slot update_slots: id  2 | task 1358 | new prompt, n_ctx_slot = 131072, n_keep = 0, task.n_tokens = 67427
2026-05-15 17:50:23.422 | slot update_slots: id  2 | task 1358 | n_tokens = 46243, memory_seq_rm [46243, end)
2026-05-15 17:50:23.422 | slot update_slots: id  2 | task 1358 | prompt processing progress, n_tokens = 48291, batch.n_tokens = 2048, progress = 0.716197
2026-05-15 17:50:24.617 | slot update_slots: id  2 | task 1358 | n_tokens = 48291, memory_seq_rm [48291, end)
2026-05-15 17:50:24.617 | slot update_slots: id  2 | task 1358 | prompt processing progress, n_tokens = 50339, batch.n_tokens = 2048, progress = 0.746570
2026-05-15 17:50:25.835 | slot update_slots: id  2 | task 1358 | n_tokens = 50339, memory_seq_rm [50339, end)
2026-05-15 17:50:25.835 | slot update_slots: id  2 | task 1358 | prompt processing progress, n_tokens = 52387, batch.n_tokens = 2048, progress = 0.776944
2026-05-15 17:50:27.076 | slot update_slots: id  2 | task 1358 | n_tokens = 52387, memory_seq_rm [52387, end)
2026-05-15 17:50:27.076 | slot update_slots: id  2 | task 1358 | prompt processing progress, n_tokens = 54435, batch.n_tokens = 2048, progress = 0.807318
2026-05-15 17:50:28.348 | slot update_slots: id  2 | task 1358 | n_tokens = 54435, memory_seq_rm [54435, end)
2026-05-15 17:50:28.348 | slot update_slots: id  2 | task 1358 | 8192 tokens since last checkpoint at 46048, creating new checkpoint during processing at position 56483
2026-05-15 17:50:28.348 | slot update_slots: id  2 | task 1358 | prompt processing progress, n_tokens = 56483, batch.n_tokens = 2048, progress = 0.837691
2026-05-15 17:50:28.660 | slot create_check: id  2 | task 1358 | created context checkpoint 28 of 32 (pos_min = 54434, pos_max = 54434, n_tokens = 54435, size = 263.628 MiB)
2026-05-15 17:50:29.952 | slot update_slots: id  2 | task 1358 | n_tokens = 56483, memory_seq_rm [56483, end)
2026-05-15 17:50:29.952 | slot update_slots: id  2 | task 1358 | prompt processing progress, n_tokens = 58531, batch.n_tokens = 2048, progress = 0.868065
2026-05-15 17:50:31.274 | slot update_slots: id  2 | task 1358 | n_tokens = 58531, memory_seq_rm [58531, end)
2026-05-15 17:50:31.274 | slot update_slots: id  2 | task 1358 | prompt processing progress, n_tokens = 60579, batch.n_tokens = 2048, progress = 0.898438
2026-05-15 17:50:32.649 | slot update_slots: id  2 | task 1358 | n_tokens = 60579, memory_seq_rm [60579, end)
2026-05-15 17:50:32.649 | slot update_slots: id  2 | task 1358 | prompt processing progress, n_tokens = 62627, batch.n_tokens = 2048, progress = 0.928812
2026-05-15 17:50:34.057 | slot update_slots: id  2 | task 1358 | n_tokens = 62627, memory_seq_rm [62627, end)
2026-05-15 17:50:34.057 | slot update_slots: id  2 | task 1358 | 8192 tokens since last checkpoint at 54435, creating new checkpoint during processing at position 64675
2026-05-15 17:50:34.057 | slot update_slots: id  2 | task 1358 | prompt processing progress, n_tokens = 64675, batch.n_tokens = 2048, progress = 0.959185
2026-05-15 17:50:34.389 | slot create_check: id  2 | task 1358 | created context checkpoint 29 of 32 (pos_min = 62626, pos_max = 62626, n_tokens = 62627, size = 280.784 MiB)
2026-05-15 17:50:35.821 | slot update_slots: id  2 | task 1358 | n_tokens = 64675, memory_seq_rm [64675, end)
2026-05-15 17:50:35.821 | slot update_slots: id  2 | task 1358 | prompt processing progress, n_tokens = 66723, batch.n_tokens = 2048, progress = 0.989559
2026-05-15 17:50:37.290 | slot update_slots: id  2 | task 1358 | n_tokens = 66723, memory_seq_rm [66723, end)
2026-05-15 17:50:37.290 | slot update_slots: id  2 | task 1358 | prompt processing progress, n_tokens = 66911, batch.n_tokens = 188, progress = 0.992347
2026-05-15 17:50:37.462 | slot update_slots: id  2 | task 1358 | n_tokens = 66911, memory_seq_rm [66911, end)
2026-05-15 17:50:37.462 | slot update_slots: id  2 | task 1358 | prompt processing progress, n_tokens = 67423, batch.n_tokens = 512, progress = 0.999941
2026-05-15 17:50:37.793 | slot create_check: id  2 | task 1358 | created context checkpoint 30 of 32 (pos_min = 66910, pos_max = 66910, n_tokens = 66911, size = 289.756 MiB)
2026-05-15 17:50:35.866 | slot update_slots: id  2 | task 1358 | n_tokens = 67423, memory_seq_rm [67423, end)
2026-05-15 17:50:35.875 | slot init_sampler: id  2 | task 1358 | init sampler, took 9.35 ms, tokens: text = 67427, total = 67427
2026-05-15 17:50:35.876 | slot update_slots: id  2 | task 1358 | prompt processing done, n_tokens = 67427, batch.n_tokens = 4
2026-05-15 17:50:36.199 | slot create_check: id  2 | task 1358 | created context checkpoint 31 of 32 (pos_min = 67422, pos_max = 67422, n_tokens = 67423, size = 290.828 MiB)
2026-05-15 17:50:36.240 | srv  log_server_r: done request: POST /v1/chat/completions 172.18.0.1 200
2026-05-15 17:50:36.916 | reasoning-budget: deactivated (natural end)
2026-05-15 17:50:37.917 | slot print_timing: id  2 | task 1358 | 
2026-05-15 17:50:37.917 | prompt eval time =   15142.70 ms / 21184 tokens (    0.71 ms per token,  1398.96 tokens per second)
2026-05-15 17:50:37.917 |        eval time =    1677.88 ms /   103 tokens (   16.29 ms per token,    61.39 tokens per second)
2026-05-15 17:50:37.917 |       total time =   16820.58 ms / 21287 tokens
2026-05-15 17:50:37.917 | draft acceptance rate = 1.00000 (   60 accepted /    60 generated)
2026-05-15 17:50:37.917 | statistics mtp: #calls(b,g,a) = 18 1296 1411, #gen drafts = 1411, #acc drafts = 1411, #gen tokens = 2476, #acc tokens = 2439, dur(b,g,a) = 0.025, 5823.769, 0.551 ms
2026-05-15 17:50:37.919 | slot      release: id  2 | task 1358 | stop processing: n_tokens = 67529, truncated = 0
2026-05-15 17:50:37.919 | srv  update_slots: all slots are idle
2026-05-15 17:50:38.189 | srv  params_from_: Chat format: peg-native
2026-05-15 17:50:38.192 | slot get_availabl: id  2 | task -1 | selected slot by LCP similarity, sim_best = 0.772 (> 0.100 thold), f_keep = 1.000
2026-05-15 17:50:38.193 | reasoning-budget: activated, budget=2147483647 tokens
2026-05-15 17:50:38.193 | slot launch_slot_: id  2 | task -1 | sampler chain: logits -> penalties -> ?dry -> ?top-n-sigma -> top-k -> ?typical -> ?top-p -> min-p -> ?xtc -> ?temp-ext -> dist 
2026-05-15 17:50:38.193 | slot launch_slot_: id  2 | task 1416 | processing task, is_child = 0
2026-05-15 17:50:38.193 | slot update_slots: id  2 | task 1416 | new prompt, n_ctx_slot = 131072, n_keep = 0, task.n_tokens = 87466
2026-05-15 17:50:38.193 | slot update_slots: id  2 | task 1416 | n_tokens = 67529, memory_seq_rm [67529, end)
2026-05-15 17:50:38.193 | slot update_slots: id  2 | task 1416 | prompt processing progress, n_tokens = 69577, batch.n_tokens = 2048, progress = 0.795475
2026-05-15 17:50:39.722 | slot update_slots: id  2 | task 1416 | n_tokens = 69577, memory_seq_rm [69577, end)
2026-05-15 17:50:39.722 | slot update_slots: id  2 | task 1416 | prompt processing progress, n_tokens = 71625, batch.n_tokens = 2048, progress = 0.818890
2026-05-15 17:50:41.265 | slot update_slots: id  2 | task 1416 | n_tokens = 71625, memory_seq_rm [71625, end)
2026-05-15 17:50:41.265 | slot update_slots: id  2 | task 1416 | prompt processing progress, n_tokens = 73673, batch.n_tokens = 2048, progress = 0.842304
2026-05-15 17:50:42.841 | slot update_slots: id  2 | task 1416 | n_tokens = 73673, memory_seq_rm [73673, end)
2026-05-15 17:50:42.841 | slot update_slots: id  2 | task 1416 | prompt processing progress, n_tokens = 75721, batch.n_tokens = 2048, progress = 0.865719
2026-05-15 17:50:44.428 | slot update_slots: id  2 | task 1416 | n_tokens = 75721, memory_seq_rm [75721, end)
2026-05-15 17:50:44.428 | slot update_slots: id  2 | task 1416 | 8192 tokens since last checkpoint at 67423, creating new checkpoint during processing at position 77769
2026-05-15 17:50:44.428 | slot update_slots: id  2 | task 1416 | prompt processing progress, n_tokens = 77769, batch.n_tokens = 2048, progress = 0.889134
2026-05-15 17:50:44.790 | slot create_check: id  2 | task 1416 | created context checkpoint 32 of 32 (pos_min = 75720, pos_max = 75720, n_tokens = 75721, size = 308.206 MiB)
2026-05-15 17:50:46.411 | slot update_slots: id  2 | task 1416 | n_tokens = 77769, memory_seq_rm [77769, end)
2026-05-15 17:50:46.411 | slot update_slots: id  2 | task 1416 | prompt processing progress, n_tokens = 79817, batch.n_tokens = 2048, progress = 0.912549
2026-05-15 17:50:48.081 | slot update_slots: id  2 | task 1416 | n_tokens = 79817, memory_seq_rm [79817, end)
2026-05-15 17:50:48.081 | slot update_slots: id  2 | task 1416 | prompt processing progress, n_tokens = 81865, batch.n_tokens = 2048, progress = 0.935964
2026-05-15 17:50:49.764 | slot update_slots: id  2 | task 1416 | n_tokens = 81865, memory_seq_rm [81865, end)
2026-05-15 17:50:49.764 | slot update_slots: id  2 | task 1416 | prompt processing progress, n_tokens = 83913, batch.n_tokens = 2048, progress = 0.959378
2026-05-15 17:50:51.476 | slot update_slots: id  2 | task 1416 | n_tokens = 83913, memory_seq_rm [83913, end)
2026-05-15 17:50:51.476 | slot update_slots: id  2 | task 1416 | 8192 tokens since last checkpoint at 75721, creating new checkpoint during processing at position 85961
2026-05-15 17:50:51.479 | slot update_slots: id  2 | task 1416 | prompt processing progress, n_tokens = 85961, batch.n_tokens = 2048, progress = 0.982793
2026-05-15 17:50:51.479 | slot create_check: id  2 | task 1416 | erasing old context checkpoint (pos_min = 8191, pos_max = 8191, n_tokens = 8192, size = 166.782 MiB)
2026-05-15 17:50:51.809 | slot create_check: id  2 | task 1416 | created context checkpoint 32 of 32 (pos_min = 83912, pos_max = 83912, n_tokens = 83913, size = 325.363 MiB)
2026-05-15 17:50:53.558 | slot update_slots: id  2 | task 1416 | n_tokens = 85961, memory_seq_rm [85961, end)
2026-05-15 17:50:53.558 | slot update_slots: id  2 | task 1416 | prompt processing progress, n_tokens = 86950, batch.n_tokens = 989, progress = 0.994101
2026-05-15 17:50:54.335 | slot update_slots: id  2 | task 1416 | n_tokens = 86950, memory_seq_rm [86950, end)
2026-05-15 17:50:54.335 | slot update_slots: id  2 | task 1416 | prompt processing progress, n_tokens = 87462, batch.n_tokens = 512, progress = 0.999954
2026-05-15 17:50:54.335 | slot create_check: id  2 | task 1416 | erasing old context checkpoint (pos_min = 11315, pos_max = 11315, n_tokens = 11316, size = 173.325 MiB)
2026-05-15 17:50:54.657 | slot create_check: id  2 | task 1416 | created context checkpoint 32 of 32 (pos_min = 86949, pos_max = 86949, n_tokens = 86950, size = 331.723 MiB)
2026-05-15 17:50:55.109 | slot update_slots: id  2 | task 1416 | n_tokens = 87462, memory_seq_rm [87462, end)
2026-05-15 17:50:55.122 | slot init_sampler: id  2 | task 1416 | init sampler, took 12.02 ms, tokens: text = 87466, total = 87466
2026-05-15 17:50:55.122 | slot update_slots: id  2 | task 1416 | prompt processing done, n_tokens = 87466, batch.n_tokens = 4
2026-05-15 17:50:55.122 | slot create_check: id  2 | task 1416 | erasing old context checkpoint (pos_min = 11827, pos_max = 11827, n_tokens = 11828, size = 174.397 MiB)
2026-05-15 17:50:55.483 | slot create_check: id  2 | task 1416 | created context checkpoint 32 of 32 (pos_min = 87461, pos_max = 87461, n_tokens = 87462, size = 332.795 MiB)
2026-05-15 17:50:55.528 | srv  log_server_r: done request: POST /v1/chat/completions 172.18.0.1 200
2026-05-15 17:50:56.395 | reasoning-budget: deactivated (natural end)
2026-05-15 17:50:58.260 | slot print_timing: id  2 | task 1416 | 
2026-05-15 17:50:58.260 | prompt eval time =   17334.88 ms / 19937 tokens (    0.87 ms per token,  1150.11 tokens per second)
2026-05-15 17:50:58.260 |        eval time =    2731.65 ms /   133 tokens (   20.54 ms per token,    48.69 tokens per second)
2026-05-15 17:50:58.260 |       total time =   20066.54 ms / 20070 tokens
2026-05-15 17:50:58.260 | draft acceptance rate = 0.98684 (   75 accepted /    76 generated)
2026-05-15 17:50:58.260 | statistics mtp: #calls(b,g,a) = 19 1353 1456, #gen drafts = 1456, #acc drafts = 1456, #gen tokens = 2552, #acc tokens = 2514, dur(b,g,a) = 0.026, 6100.116, 0.580 ms
2026-05-15 17:50:58.262 | slot      release: id  2 | task 1416 | stop processing: n_tokens = 87598, truncated = 0
2026-05-15 17:50:58.262 | srv  update_slots: all slots are idle
2026-05-15 17:50:58.670 | srv  params_from_: Chat format: peg-native
2026-05-15 17:50:58.673 | slot get_availabl: id  2 | task -1 | selected slot by LCP similarity, sim_best = 0.998 (> 0.100 thold), f_keep = 1.000
2026-05-15 17:50:58.674 | reasoning-budget: activated, budget=2147483647 tokens
2026-05-15 17:50:58.674 | slot launch_slot_: id  2 | task -1 | sampler chain: logits -> penalties -> ?dry -> ?top-n-sigma -> top-k -> ?typical -> ?top-p -> min-p -> ?xtc -> ?temp-ext -> dist 
2026-05-15 17:50:58.674 | slot launch_slot_: id  2 | task 1491 | processing task, is_child = 0
2026-05-15 17:50:58.674 | slot update_slots: id  2 | task 1491 | new prompt, n_ctx_slot = 131072, n_keep = 0, task.n_tokens = 87741
2026-05-15 17:50:58.674 | slot update_slots: id  2 | task 1491 | n_tokens = 87598, memory_seq_rm [87598, end)
2026-05-15 17:50:58.674 | slot update_slots: id  2 | task 1491 | prompt processing progress, n_tokens = 87737, batch.n_tokens = 139, progress = 0.999954
2026-05-15 17:50:58.674 | slot create_check: id  2 | task 1491 | erasing old context checkpoint (pos_min = 11999, pos_max = 11999, n_tokens = 12000, size = 174.757 MiB)
2026-05-15 17:50:58.948 | slot create_check: id  2 | task 1491 | created context checkpoint 32 of 32 (pos_min = 87597, pos_max = 87597, n_tokens = 87598, size = 333.080 MiB)
2026-05-15 17:50:59.103 | slot update_slots: id  2 | task 1491 | n_tokens = 87737, memory_seq_rm [87737, end)
2026-05-15 17:50:59.115 | slot init_sampler: id  2 | task 1491 | init sampler, took 11.95 ms, tokens: text = 87741, total = 87741
2026-05-15 17:50:59.115 | slot update_slots: id  2 | task 1491 | prompt processing done, n_tokens = 87741, batch.n_tokens = 4
2026-05-15 17:50:59.115 | slot create_check: id  2 | task 1491 | erasing old context checkpoint (pos_min = 12131, pos_max = 12131, n_tokens = 12132, size = 175.034 MiB)
2026-05-15 17:50:59.417 | slot create_check: id  2 | task 1491 | created context checkpoint 32 of 32 (pos_min = 87736, pos_max = 87736, n_tokens = 87737, size = 333.371 MiB)
2026-05-15 17:50:59.463 | srv  log_server_r: done request: POST /v1/chat/completions 172.18.0.1 200
2026-05-15 17:51:02.013 | reasoning-budget: deactivated (natural end)
2026-05-15 17:51:03.428 | slot print_timing: id  2 | task 1491 | 
2026-05-15 17:51:03.428 | prompt eval time =     788.15 ms /   143 tokens (    5.51 ms per token,   181.44 tokens per second)
2026-05-15 17:51:03.428 |        eval time =    3965.28 ms /   207 tokens (   19.16 ms per token,    52.20 tokens per second)
2026-05-15 17:51:03.428 |       total time =    4753.43 ms /   350 tokens
2026-05-15 17:51:03.428 | draft acceptance rate = 0.98261 (  113 accepted /   115 generated)
2026-05-15 17:51:03.428 | statistics mtp: #calls(b,g,a) = 20 1446 1520, #gen drafts = 1520, #acc drafts = 1520, #gen tokens = 2667, #acc tokens = 2627, dur(b,g,a) = 0.029, 6503.051, 0.613 ms
2026-05-15 17:51:03.430 | slot      release: id  2 | task 1491 | stop processing: n_tokens = 87947, truncated = 0
2026-05-15 17:51:03.430 | srv  update_slots: all slots are idle
2026-05-15 17:51:03.950 | srv  params_from_: Chat format: peg-native
2026-05-15 17:51:03.953 | slot get_availabl: id  2 | task -1 | selected slot by LCP similarity, sim_best = 0.995 (> 0.100 thold), f_keep = 1.000
2026-05-15 17:51:03.955 | reasoning-budget: activated, budget=2147483647 tokens
2026-05-15 17:51:03.955 | slot launch_slot_: id  2 | task -1 | sampler chain: logits -> penalties -> ?dry -> ?top-n-sigma -> top-k -> ?typical -> ?top-p -> min-p -> ?xtc -> ?temp-ext -> dist 
2026-05-15 17:51:03.955 | slot launch_slot_: id  2 | task 1590 | processing task, is_child = 0
2026-05-15 17:51:03.955 | slot update_slots: id  2 | task 1590 | new prompt, n_ctx_slot = 131072, n_keep = 0, task.n_tokens = 88361
2026-05-15 17:51:03.955 | slot update_slots: id  2 | task 1590 | n_tokens = 87947, memory_seq_rm [87947, end)
2026-05-15 17:51:03.955 | slot update_slots: id  2 | task 1590 | prompt processing progress, n_tokens = 88357, batch.n_tokens = 410, progress = 0.999955
2026-05-15 17:51:03.955 | slot create_check: id  2 | task 1590 | erasing old context checkpoint (pos_min = 12597, pos_max = 12597, n_tokens = 12598, size = 176.010 MiB)
2026-05-15 17:51:04.257 | slot create_check: id  2 | task 1590 | created context checkpoint 32 of 32 (pos_min = 87946, pos_max = 87946, n_tokens = 87947, size = 333.811 MiB)
2026-05-15 17:51:04.636 | slot update_slots: id  2 | task 1590 | n_tokens = 88357, memory_seq_rm [88357, end)
2026-05-15 17:51:04.649 | slot init_sampler: id  2 | task 1590 | init sampler, took 12.80 ms, tokens: text = 88361, total = 88361
2026-05-15 17:51:04.649 | slot update_slots: id  2 | task 1590 | prompt processing done, n_tokens = 88361, batch.n_tokens = 4
2026-05-15 17:51:04.649 | slot create_check: id  2 | task 1590 | erasing old context checkpoint (pos_min = 13508, pos_max = 13508, n_tokens = 13509, size = 177.918 MiB)
2026-05-15 17:51:05.026 | slot create_check: id  2 | task 1590 | created context checkpoint 32 of 32 (pos_min = 88356, pos_max = 88356, n_tokens = 88357, size = 334.669 MiB)
2026-05-15 17:51:05.072 | srv  log_server_r: done request: POST /v1/chat/completions 172.18.0.1 200
2026-05-15 17:51:05.502 | reasoning-budget: deactivated (natural end)
2026-05-15 17:51:06.708 | slot print_timing: id  2 | task 1590 | 
2026-05-15 17:51:06.708 | prompt eval time =    1116.86 ms /   414 tokens (    2.70 ms per token,   370.68 tokens per second)
2026-05-15 17:51:06.708 |        eval time =    3921.59 ms /   208 tokens (   18.85 ms per token,    53.04 tokens per second)
2026-05-15 17:51:06.708 |       total time =    5038.45 ms /   622 tokens
2026-05-15 17:51:06.708 | draft acceptance rate = 0.98387 (  122 accepted /   124 generated)
2026-05-15 17:51:06.708 | statistics mtp: #calls(b,g,a) = 21 1531 1588, #gen drafts = 1588, #acc drafts = 1588, #gen tokens = 2791, #acc tokens = 2749, dur(b,g,a) = 0.030, 6904.650, 0.646 ms
2026-05-15 17:51:06.710 | slot      release: id  2 | task 1590 | stop processing: n_tokens = 88568, truncated = 0
2026-05-15 17:51:06.710 | srv  update_slots: all slots are idle
2026-05-15 17:51:07.008 | srv  params_from_: Chat format: peg-native
2026-05-15 17:51:07.011 | slot get_availabl: id  2 | task -1 | selected slot by LCP similarity, sim_best = 1.000 (> 0.100 thold), f_keep = 1.000
2026-05-15 17:51:07.012 | reasoning-budget: activated, budget=2147483647 tokens
2026-05-15 17:51:07.012 | slot launch_slot_: id  2 | task -1 | sampler chain: logits -> penalties -> ?dry -> ?top-n-sigma -> top-k -> ?typical -> ?top-p -> min-p -> ?xtc -> ?temp-ext -> dist 
2026-05-15 17:51:07.012 | slot launch_slot_: id  2 | task 1684 | processing task, is_child = 0
2026-05-15 17:51:07.013 | slot update_slots: id  2 | task 1684 | new prompt, n_ctx_slot = 131072, n_keep = 0, task.n_tokens = 88585
2026-05-15 17:51:07.013 | slot update_slots: id  2 | task 1684 | n_tokens = 88568, memory_seq_rm [88568, end)
2026-05-15 17:51:07.013 | slot update_slots: id  2 | task 1684 | prompt processing progress, n_tokens = 88581, batch.n_tokens = 13, progress = 0.999955
2026-05-15 17:51:07.013 | slot create_check: id  2 | task 1684 | erasing old context checkpoint (pos_min = 14020, pos_max = 14020, n_tokens = 14021, size = 178.990 MiB)
2026-05-15 17:51:07.347 | slot create_check: id  2 | task 1684 | created context checkpoint 32 of 32 (pos_min = 88567, pos_max = 88567, n_tokens = 88568, size = 335.111 MiB)
2026-05-15 17:51:07.397 | slot update_slots: id  2 | task 1684 | n_tokens = 88581, memory_seq_rm [88581, end)
2026-05-15 17:51:07.409 | slot init_sampler: id  2 | task 1684 | init sampler, took 12.22 ms, tokens: text = 88585, total = 88585
2026-05-15 17:51:07.409 | slot update_slots: id  2 | task 1684 | prompt processing done, n_tokens = 88585, batch.n_tokens = 4
2026-05-15 17:51:07.453 | srv  log_server_r: done request: POST /v1/chat/completions 172.18.0.1 200
2026-05-15 17:51:08.577 | reasoning-budget: deactivated (natural end)
2026-05-15 17:51:09.815 | slot print_timing: id  2 | task 1684 | 
2026-05-15 17:51:09.815 | prompt eval time =     440.40 ms /    17 tokens (   25.91 ms per token,    38.60 tokens per second)
2026-05-15 17:51:09.815 |        eval time =    2362.11 ms /   128 tokens (   18.45 ms per token,    54.19 tokens per second)
2026-05-15 17:51:09.815 |       total time =    2802.51 ms /   145 tokens
2026-05-15 17:51:09.815 | draft acceptance rate = 0.98667 (   74 accepted /    75 generated)
2026-05-15 17:51:09.815 | statistics mtp: #calls(b,g,a) = 22 1584 1630, #gen drafts = 1630, #acc drafts = 1630, #gen tokens = 2866, #acc tokens = 2823, dur(b,g,a) = 0.032, 7146.772, 0.668 ms
2026-05-15 17:51:09.817 | slot      release: id  2 | task 1684 | stop processing: n_tokens = 88712, truncated = 0
2026-05-15 17:51:09.818 | srv  update_slots: all slots are idle
2026-05-15 17:51:10.104 | srv  params_from_: Chat format: peg-native
2026-05-15 17:51:10.107 | slot get_availabl: id  2 | task -1 | selected slot by LCP similarity, sim_best = 1.000 (> 0.100 thold), f_keep = 1.000
2026-05-15 17:51:10.109 | reasoning-budget: activated, budget=2147483647 tokens
2026-05-15 17:51:10.109 | slot launch_slot_: id  2 | task -1 | sampler chain: logits -> penalties -> ?dry -> ?top-n-sigma -> top-k -> ?typical -> ?top-p -> min-p -> ?xtc -> ?temp-ext -> dist 
2026-05-15 17:51:10.109 | slot launch_slot_: id  2 | task 1743 | processing task, is_child = 0
2026-05-15 17:51:10.109 | slot update_slots: id  2 | task 1743 | new prompt, n_ctx_slot = 131072, n_keep = 0, task.n_tokens = 88741
2026-05-15 17:51:10.109 | slot update_slots: id  2 | task 1743 | n_tokens = 88712, memory_seq_rm [88712, end)
2026-05-15 17:51:10.109 | slot update_slots: id  2 | task 1743 | prompt processing progress, n_tokens = 88737, batch.n_tokens = 25, progress = 0.999955
2026-05-15 17:51:10.109 | slot create_check: id  2 | task 1743 | erasing old context checkpoint (pos_min = 14163, pos_max = 14163, n_tokens = 14164, size = 179.289 MiB)
2026-05-15 17:51:10.433 | slot create_check: id  2 | task 1743 | created context checkpoint 32 of 32 (pos_min = 88711, pos_max = 88711, n_tokens = 88712, size = 335.413 MiB)
2026-05-15 17:51:10.486 | slot update_slots: id  2 | task 1743 | n_tokens = 88737, memory_seq_rm [88737, end)
2026-05-15 17:51:10.499 | slot init_sampler: id  2 | task 1743 | init sampler, took 12.04 ms, tokens: text = 88741, total = 88741
2026-05-15 17:51:10.499 | slot update_slots: id  2 | task 1743 | prompt processing done, n_tokens = 88741, batch.n_tokens = 4
2026-05-15 17:51:10.543 | srv  log_server_r: done request: POST /v1/chat/completions 172.18.0.1 200
2026-05-15 17:51:11.436 | reasoning-budget: deactivated (natural end)
2026-05-15 17:51:12.630 | slot print_timing: id  2 | task 1743 | 
2026-05-15 17:51:12.630 | prompt eval time =     434.01 ms /    29 tokens (   14.97 ms per token,    66.82 tokens per second)
2026-05-15 17:51:12.630 |        eval time =    2086.84 ms /   104 tokens (   20.07 ms per token,    49.84 tokens per second)
2026-05-15 17:51:12.630 |       total time =    2520.85 ms /   133 tokens
2026-05-15 17:51:12.630 | draft acceptance rate = 0.96552 (   56 accepted /    58 generated)
2026-05-15 17:51:12.630 | statistics mtp: #calls(b,g,a) = 23 1631 1662, #gen drafts = 1662, #acc drafts = 1662, #gen tokens = 2924, #acc tokens = 2879, dur(b,g,a) = 0.033, 7350.049, 0.679 ms
2026-05-15 17:51:12.632 | slot      release: id  2 | task 1743 | stop processing: n_tokens = 88844, truncated = 0
2026-05-15 17:51:12.632 | srv  update_slots: all slots are idle
2026-05-15 17:51:12.959 | srv  params_from_: Chat format: peg-native
2026-05-15 17:51:12.962 | slot get_availabl: id  2 | task -1 | selected slot by LCP similarity, sim_best = 0.999 (> 0.100 thold), f_keep = 1.000
2026-05-15 17:51:12.963 | reasoning-budget: activated, budget=2147483647 tokens
2026-05-15 17:51:12.963 | slot launch_slot_: id  2 | task -1 | sampler chain: logits -> penalties -> ?dry -> ?top-n-sigma -> top-k -> ?typical -> ?top-p -> min-p -> ?xtc -> ?temp-ext -> dist 
2026-05-15 17:51:12.963 | slot launch_slot_: id  2 | task 1797 | processing task, is_child = 0
2026-05-15 17:51:12.963 | slot update_slots: id  2 | task 1797 | new prompt, n_ctx_slot = 131072, n_keep = 0, task.n_tokens = 88894
2026-05-15 17:51:12.963 | slot update_slots: id  2 | task 1797 | n_tokens = 88844, memory_seq_rm [88844, end)
2026-05-15 17:51:12.963 | slot update_slots: id  2 | task 1797 | prompt processing progress, n_tokens = 88890, batch.n_tokens = 46, progress = 0.999955
2026-05-15 17:51:12.963 | slot create_check: id  2 | task 1797 | erasing old context checkpoint (pos_min = 14293, pos_max = 14293, n_tokens = 14294, size = 179.562 MiB)
2026-05-15 17:51:13.287 | slot create_check: id  2 | task 1797 | created context checkpoint 32 of 32 (pos_min = 88843, pos_max = 88843, n_tokens = 88844, size = 335.689 MiB)
2026-05-15 17:51:13.351 | slot update_slots: id  2 | task 1797 | n_tokens = 88890, memory_seq_rm [88890, end)
2026-05-15 17:51:13.364 | slot init_sampler: id  2 | task 1797 | init sampler, took 12.72 ms, tokens: text = 88894, total = 88894
2026-05-15 17:51:13.364 | slot update_slots: id  2 | task 1797 | prompt processing done, n_tokens = 88894, batch.n_tokens = 4
2026-05-15 17:51:13.408 | srv  log_server_r: done request: POST /v1/chat/completions 172.18.0.1 200
2026-05-15 17:51:14.238 | reasoning-budget: deactivated (natural end)
2026-05-15 17:51:15.515 | slot print_timing: id  2 | task 1797 | 
2026-05-15 17:51:15.515 | prompt eval time =     444.54 ms /    50 tokens (    8.89 ms per token,   112.48 tokens per second)
2026-05-15 17:51:15.515 |        eval time =    2106.94 ms /   111 tokens (   18.98 ms per token,    52.68 tokens per second)
2026-05-15 17:51:15.515 |       total time =    2551.48 ms /   161 tokens
2026-05-15 17:51:15.515 | draft acceptance rate = 0.98413 (   62 accepted /    63 generated)
2026-05-15 17:51:15.515 | statistics mtp: #calls(b,g,a) = 24 1679 1697, #gen drafts = 1697, #acc drafts = 1697, #gen tokens = 2987, #acc tokens = 2941, dur(b,g,a) = 0.034, 7559.481, 0.691 ms
2026-05-15 17:51:15.517 | slot      release: id  2 | task 1797 | stop processing: n_tokens = 89004, truncated = 0
2026-05-15 17:51:15.517 | srv  update_slots: all slots are idle
2026-05-15 17:51:15.827 | srv  params_from_: Chat format: peg-native
2026-05-15 17:51:15.830 | slot get_availabl: id  2 | task -1 | selected slot by LCP similarity, sim_best = 1.000 (> 0.100 thold), f_keep = 1.000
2026-05-15 17:51:15.831 | reasoning-budget: activated, budget=2147483647 tokens
2026-05-15 17:51:15.831 | slot launch_slot_: id  2 | task -1 | sampler chain: logits -> penalties -> ?dry -> ?top-n-sigma -> top-k -> ?typical -> ?top-p -> min-p -> ?xtc -> ?temp-ext -> dist 
2026-05-15 17:51:15.831 | slot launch_slot_: id  2 | task 1851 | processing task, is_child = 0
2026-05-15 17:51:15.831 | slot update_slots: id  2 | task 1851 | new prompt, n_ctx_slot = 131072, n_keep = 0, task.n_tokens = 89023
2026-05-15 17:51:15.831 | slot update_slots: id  2 | task 1851 | n_tokens = 89004, memory_seq_rm [89004, end)
2026-05-15 17:51:15.831 | slot update_slots: id  2 | task 1851 | prompt processing progress, n_tokens = 89019, batch.n_tokens = 15, progress = 0.999955
2026-05-15 17:51:15.831 | slot create_check: id  2 | task 1851 | erasing old context checkpoint (pos_min = 20432, pos_max = 20432, n_tokens = 20433, size = 192.418 MiB)
2026-05-15 17:51:16.159 | slot create_check: id  2 | task 1851 | created context checkpoint 32 of 32 (pos_min = 89003, pos_max = 89003, n_tokens = 89004, size = 336.024 MiB)
2026-05-15 17:51:16.207 | slot update_slots: id  2 | task 1851 | n_tokens = 89019, memory_seq_rm [89019, end)
2026-05-15 17:51:16.219 | slot init_sampler: id  2 | task 1851 | init sampler, took 12.32 ms, tokens: text = 89023, total = 89023
2026-05-15 17:51:16.219 | slot update_slots: id  2 | task 1851 | prompt processing done, n_tokens = 89023, batch.n_tokens = 4
2026-05-15 17:51:16.264 | srv  log_server_r: done request: POST /v1/chat/completions 172.18.0.1 200
2026-05-15 17:51:17.026 | reasoning-budget: deactivated (natural end)
2026-05-15 17:51:18.231 | slot print_timing: id  2 | task 1851 | 
2026-05-15 17:51:18.231 | prompt eval time =     431.99 ms /    19 tokens (   22.74 ms per token,    43.98 tokens per second)
2026-05-15 17:51:18.231 |        eval time =    1967.27 ms /   110 tokens (   17.88 ms per token,    55.91 tokens per second)
2026-05-15 17:51:18.231 |       total time =    2399.26 ms /   129 tokens
2026-05-15 17:51:18.231 | draft acceptance rate = 1.00000 (   65 accepted /    65 generated)
2026-05-15 17:51:18.231 | statistics mtp: #calls(b,g,a) = 25 1723 1733, #gen drafts = 1733, #acc drafts = 1733, #gen tokens = 3052, #acc tokens = 3006, dur(b,g,a) = 0.035, 7762.686, 0.708 ms
2026-05-15 17:51:18.233 | slot      release: id  2 | task 1851 | stop processing: n_tokens = 89132, truncated = 0
2026-05-15 17:51:18.233 | srv  update_slots: all slots are idle
2026-05-15 17:51:18.564 | srv  params_from_: Chat format: peg-native
2026-05-15 17:51:18.567 | slot get_availabl: id  2 | task -1 | selected slot by LCP similarity, sim_best = 0.999 (> 0.100 thold), f_keep = 1.000
2026-05-15 17:51:18.568 | reasoning-budget: activated, budget=2147483647 tokens
2026-05-15 17:51:18.568 | slot launch_slot_: id  2 | task -1 | sampler chain: logits -> penalties -> ?dry -> ?top-n-sigma -> top-k -> ?typical -> ?top-p -> min-p -> ?xtc -> ?temp-ext -> dist 
2026-05-15 17:51:18.568 | slot launch_slot_: id  2 | task 1901 | processing task, is_child = 0
2026-05-15 17:51:18.568 | slot update_slots: id  2 | task 1901 | new prompt, n_ctx_slot = 131072, n_keep = 0, task.n_tokens = 89207
2026-05-15 17:51:18.568 | slot update_slots: id  2 | task 1901 | n_tokens = 89132, memory_seq_rm [89132, end)
2026-05-15 17:51:18.568 | slot update_slots: id  2 | task 1901 | prompt processing progress, n_tokens = 89203, batch.n_tokens = 71, progress = 0.999955
2026-05-15 17:51:18.568 | slot create_check: id  2 | task 1901 | erasing old context checkpoint (pos_min = 20944, pos_max = 20944, n_tokens = 20945, size = 193.491 MiB)
2026-05-15 17:51:18.907 | slot create_check: id  2 | task 1901 | created context checkpoint 32 of 32 (pos_min = 89131, pos_max = 89131, n_tokens = 89132, size = 336.293 MiB)
2026-05-15 17:51:18.983 | slot update_slots: id  2 | task 1901 | n_tokens = 89203, memory_seq_rm [89203, end)
2026-05-15 17:51:18.995 | slot init_sampler: id  2 | task 1901 | init sampler, took 12.09 ms, tokens: text = 89207, total = 89207
2026-05-15 17:51:18.996 | slot update_slots: id  2 | task 1901 | prompt processing done, n_tokens = 89207, batch.n_tokens = 4
2026-05-15 17:51:18.996 | slot create_check: id  2 | task 1901 | erasing old context checkpoint (pos_min = 24132, pos_max = 24132, n_tokens = 24133, size = 200.167 MiB)
2026-05-15 17:51:19.325 | slot create_check: id  2 | task 1901 | created context checkpoint 32 of 32 (pos_min = 89202, pos_max = 89202, n_tokens = 89203, size = 336.441 MiB)
2026-05-15 17:51:19.370 | srv  log_server_r: done request: POST /v1/chat/completions 172.18.0.1 200
2026-05-15 17:51:20.217 | reasoning-budget: deactivated (natural end)
2026-05-15 17:51:21.448 | slot print_timing: id  2 | task 1901 | 
2026-05-15 17:51:21.448 | prompt eval time =     801.28 ms /    75 tokens (   10.68 ms per token,    93.60 tokens per second)
2026-05-15 17:51:21.448 |        eval time =    2078.16 ms /   120 tokens (   17.32 ms per token,    57.74 tokens per second)
2026-05-15 17:51:21.448 |       total time =    2879.43 ms /   195 tokens
2026-05-15 17:51:21.448 | draft acceptance rate = 1.00000 (   69 accepted /    69 generated)
2026-05-15 17:51:21.448 | statistics mtp: #calls(b,g,a) = 26 1773 1771, #gen drafts = 1771, #acc drafts = 1771, #gen tokens = 3121, #acc tokens = 3075, dur(b,g,a) = 0.036, 7989.235, 0.720 ms
2026-05-15 17:51:21.450 | slot      release: id  2 | task 1901 | stop processing: n_tokens = 89326, truncated = 0
2026-05-15 17:51:21.450 | srv  update_slots: all slots are idle
2026-05-15 17:51:22.189 | srv  params_from_: Chat format: peg-native
2026-05-15 17:51:22.192 | slot get_availabl: id  2 | task -1 | selected slot by LCP similarity, sim_best = 0.998 (> 0.100 thold), f_keep = 1.000
2026-05-15 17:51:22.194 | reasoning-budget: activated, budget=2147483647 tokens
2026-05-15 17:51:22.194 | slot launch_slot_: id  2 | task -1 | sampler chain: logits -> penalties -> ?dry -> ?top-n-sigma -> top-k -> ?typical -> ?top-p -> min-p -> ?xtc -> ?temp-ext -> dist 
2026-05-15 17:51:22.194 | slot launch_slot_: id  2 | task 1954 | processing task, is_child = 0
2026-05-15 17:51:22.194 | slot update_slots: id  2 | task 1954 | new prompt, n_ctx_slot = 131072, n_keep = 0, task.n_tokens = 89502
2026-05-15 17:51:22.194 | slot update_slots: id  2 | task 1954 | n_tokens = 89326, memory_seq_rm [89326, end)
2026-05-15 17:51:22.194 | slot update_slots: id  2 | task 1954 | prompt processing progress, n_tokens = 89498, batch.n_tokens = 172, progress = 0.999955
2026-05-15 17:51:22.194 | slot create_check: id  2 | task 1954 | erasing old context checkpoint (pos_min = 24644, pos_max = 24644, n_tokens = 24645, size = 201.239 MiB)
2026-05-15 17:51:22.514 | slot create_check: id  2 | task 1954 | created context checkpoint 32 of 32 (pos_min = 89325, pos_max = 89325, n_tokens = 89326, size = 336.699 MiB)
2026-05-15 17:51:22.697 | slot update_slots: id  2 | task 1954 | n_tokens = 89498, memory_seq_rm [89498, end)
2026-05-15 17:51:22.710 | slot init_sampler: id  2 | task 1954 | init sampler, took 12.55 ms, tokens: text = 89502, total = 89502
2026-05-15 17:51:22.710 | slot update_slots: id  2 | task 1954 | prompt processing done, n_tokens = 89502, batch.n_tokens = 4
2026-05-15 17:51:22.710 | slot create_check: id  2 | task 1954 | erasing old context checkpoint (pos_min = 25828, pos_max = 25828, n_tokens = 25829, size = 203.719 MiB)
2026-05-15 17:51:23.124 | slot create_check: id  2 | task 1954 | created context checkpoint 32 of 32 (pos_min = 89497, pos_max = 89497, n_tokens = 89498, size = 337.059 MiB)
2026-05-15 17:51:23.168 | srv  log_server_r: done request: POST /v1/chat/completions 172.18.0.1 200
2026-05-15 17:51:25.361 | reasoning-budget: deactivated (natural end)
2026-05-15 17:51:27.005 | slot print_timing: id  2 | task 1954 | 
2026-05-15 17:51:27.005 | prompt eval time =     973.66 ms /   176 tokens (    5.53 ms per token,   180.76 tokens per second)
2026-05-15 17:51:27.005 |        eval time =    3837.36 ms /   171 tokens (   22.44 ms per token,    44.56 tokens per second)
2026-05-15 17:51:27.005 |       total time =    4811.03 ms /   347 tokens
2026-05-15 17:51:27.005 | draft acceptance rate = 0.95604 (   87 accepted /    91 generated)
2026-05-15 17:51:27.005 | statistics mtp: #calls(b,g,a) = 27 1856 1823, #gen drafts = 1823, #acc drafts = 1823, #gen tokens = 3212, #acc tokens = 3162, dur(b,g,a) = 0.038, 8331.342, 0.746 ms
2026-05-15 17:51:27.007 | slot      release: id  2 | task 1954 | stop processing: n_tokens = 89672, truncated = 0
2026-05-15 17:51:27.007 | srv  update_slots: all slots are idle
2026-05-15 17:51:27.303 | srv  params_from_: Chat format: peg-native
2026-05-15 17:51:27.306 | slot get_availabl: id  2 | task -1 | selected slot by LCP similarity, sim_best = 1.000 (> 0.100 thold), f_keep = 1.000
2026-05-15 17:51:27.308 | reasoning-budget: activated, budget=2147483647 tokens
2026-05-15 17:51:27.308 | slot launch_slot_: id  2 | task -1 | sampler chain: logits -> penalties -> ?dry -> ?top-n-sigma -> top-k -> ?typical -> ?top-p -> min-p -> ?xtc -> ?temp-ext -> dist 
2026-05-15 17:51:27.308 | slot launch_slot_: id  2 | task 2049 | processing task, is_child = 0
2026-05-15 17:51:27.308 | slot update_slots: id  2 | task 2049 | new prompt, n_ctx_slot = 131072, n_keep = 0, task.n_tokens = 89689
2026-05-15 17:51:27.308 | slot update_slots: id  2 | task 2049 | n_tokens = 89672, memory_seq_rm [89672, end)
2026-05-15 17:51:27.308 | slot update_slots: id  2 | task 2049 | prompt processing progress, n_tokens = 89685, batch.n_tokens = 13, progress = 0.999955
2026-05-15 17:51:27.308 | slot create_check: id  2 | task 2049 | erasing old context checkpoint (pos_min = 26340, pos_max = 26340, n_tokens = 26341, size = 204.791 MiB)
2026-05-15 17:51:27.634 | slot create_check: id  2 | task 2049 | created context checkpoint 32 of 32 (pos_min = 89671, pos_max = 89671, n_tokens = 89672, size = 337.423 MiB)
2026-05-15 17:51:27.686 | slot update_slots: id  2 | task 2049 | n_tokens = 89685, memory_seq_rm [89685, end)
2026-05-15 17:51:27.699 | slot init_sampler: id  2 | task 2049 | init sampler, took 12.69 ms, tokens: text = 89689, total = 89689
2026-05-15 17:51:27.699 | slot update_slots: id  2 | task 2049 | prompt processing done, n_tokens = 89689, batch.n_tokens = 4
2026-05-15 17:51:27.746 | srv  log_server_r: done request: POST /v1/chat/completions 172.18.0.1 200
2026-05-15 17:51:28.019 | reasoning-budget: deactivated (natural end)
2026-05-15 17:51:29.338 | slot print_timing: id  2 | task 2049 | 
2026-05-15 17:51:29.338 | prompt eval time =     437.48 ms /    17 tokens (   25.73 ms per token,    38.86 tokens per second)
2026-05-15 17:51:29.338 |        eval time =    1592.98 ms /    96 tokens (   16.59 ms per token,    60.26 tokens per second)
2026-05-15 17:51:29.338 |       total time =    2030.45 ms /   113 tokens
2026-05-15 17:51:29.338 | draft acceptance rate = 1.00000 (   58 accepted /    58 generated)
2026-05-15 17:51:29.338 | statistics mtp: #calls(b,g,a) = 28 1893 1854, #gen drafts = 1854, #acc drafts = 1854, #gen tokens = 3270, #acc tokens = 3220, dur(b,g,a) = 0.040, 8503.261, 0.762 ms
2026-05-15 17:51:29.341 | slot      release: id  2 | task 2049 | stop processing: n_tokens = 89784, truncated = 0
2026-05-15 17:51:29.341 | srv  update_slots: all slots are idle
2026-05-15 17:51:29.780 | srv  params_from_: Chat format: peg-native
2026-05-15 17:51:29.783 | slot get_availabl: id  2 | task -1 | selected slot by LCP similarity, sim_best = 0.991 (> 0.100 thold), f_keep = 1.000
2026-05-15 17:51:29.784 | reasoning-budget: activated, budget=2147483647 tokens
2026-05-15 17:51:29.784 | slot launch_slot_: id  2 | task -1 | sampler chain: logits -> penalties -> ?dry -> ?top-n-sigma -> top-k -> ?typical -> ?top-p -> min-p -> ?xtc -> ?temp-ext -> dist 
2026-05-15 17:51:29.784 | slot launch_slot_: id  2 | task 2089 | processing task, is_child = 0
2026-05-15 17:51:29.784 | slot update_slots: id  2 | task 2089 | new prompt, n_ctx_slot = 131072, n_keep = 0, task.n_tokens = 90589
2026-05-15 17:51:29.784 | slot update_slots: id  2 | task 2089 | n_tokens = 89784, memory_seq_rm [89784, end)
2026-05-15 17:51:29.785 | slot update_slots: id  2 | task 2089 | prompt processing progress, n_tokens = 90073, batch.n_tokens = 289, progress = 0.994304
2026-05-15 17:51:30.070 | slot update_slots: id  2 | task 2089 | n_tokens = 90073, memory_seq_rm [90073, end)
2026-05-15 17:51:30.071 | slot update_slots: id  2 | task 2089 | prompt processing progress, n_tokens = 90585, batch.n_tokens = 512, progress = 0.999956
2026-05-15 17:51:30.071 | slot create_check: id  2 | task 2089 | erasing old context checkpoint (pos_min = 26758, pos_max = 26758, n_tokens = 26759, size = 205.667 MiB)
2026-05-15 17:51:30.401 | slot create_check: id  2 | task 2089 | created context checkpoint 32 of 32 (pos_min = 90072, pos_max = 90072, n_tokens = 90073, size = 338.263 MiB)
2026-05-15 17:51:30.867 | slot update_slots: id  2 | task 2089 | n_tokens = 90585, memory_seq_rm [90585, end)
2026-05-15 17:51:30.880 | slot init_sampler: id  2 | task 2089 | init sampler, took 12.64 ms, tokens: text = 90589, total = 90589
2026-05-15 17:51:30.880 | slot update_slots: id  2 | task 2089 | prompt processing done, n_tokens = 90589, batch.n_tokens = 4
2026-05-15 17:51:30.880 | slot create_check: id  2 | task 2089 | erasing old context checkpoint (pos_min = 26996, pos_max = 26996, n_tokens = 26997, size = 206.165 MiB)
2026-05-15 17:51:31.213 | slot create_check: id  2 | task 2089 | created context checkpoint 32 of 32 (pos_min = 90584, pos_max = 90584, n_tokens = 90585, size = 339.336 MiB)
2026-05-15 17:51:31.258 | srv  log_server_r: done request: POST /v1/chat/completions 172.18.0.1 200
2026-05-15 17:51:31.727 | reasoning-budget: deactivated (natural end)
2026-05-15 17:51:33.088 | slot print_timing: id  2 | task 2089 | 
2026-05-15 17:51:33.089 | prompt eval time =    1473.14 ms /   805 tokens (    1.83 ms per token,   546.45 tokens per second)
2026-05-15 17:51:33.089 |        eval time =    1830.71 ms /   102 tokens (   17.95 ms per token,    55.72 tokens per second)
2026-05-15 17:51:33.089 |       total time =    3303.85 ms /   907 tokens
2026-05-15 17:51:33.089 | draft acceptance rate = 1.00000 (   59 accepted /    59 generated)
2026-05-15 17:51:33.089 | statistics mtp: #calls(b,g,a) = 29 1935 1885, #gen drafts = 1885, #acc drafts = 1885, #gen tokens = 3329, #acc tokens = 3279, dur(b,g,a) = 0.042, 8692.684, 0.776 ms
2026-05-15 17:51:33.090 | slot      release: id  2 | task 2089 | stop processing: n_tokens = 90690, truncated = 0
2026-05-15 17:51:33.090 | srv  update_slots: all slots are idle
2026-05-15 17:51:31.094 | srv  params_from_: Chat format: peg-native
2026-05-15 17:51:31.097 | slot get_availabl: id  2 | task -1 | selected slot by LCP similarity, sim_best = 0.999 (> 0.100 thold), f_keep = 1.000
2026-05-15 17:51:31.099 | reasoning-budget: activated, budget=2147483647 tokens
2026-05-15 17:51:31.099 | slot launch_slot_: id  2 | task -1 | sampler chain: logits -> penalties -> ?dry -> ?top-n-sigma -> top-k -> ?typical -> ?top-p -> min-p -> ?xtc -> ?temp-ext -> dist 
2026-05-15 17:51:31.099 | slot launch_slot_: id  2 | task 2136 | processing task, is_child = 0
2026-05-15 17:51:31.099 | slot update_slots: id  2 | task 2136 | new prompt, n_ctx_slot = 131072, n_keep = 0, task.n_tokens = 90786
2026-05-15 17:51:31.099 | slot update_slots: id  2 | task 2136 | n_tokens = 90690, memory_seq_rm [90690, end)
2026-05-15 17:51:31.099 | slot update_slots: id  2 | task 2136 | prompt processing progress, n_tokens = 90782, batch.n_tokens = 92, progress = 0.999956
2026-05-15 17:51:31.099 | slot create_check: id  2 | task 2136 | erasing old context checkpoint (pos_min = 27143, pos_max = 27143, n_tokens = 27144, size = 206.473 MiB)
2026-05-15 17:51:31.426 | slot create_check: id  2 | task 2136 | created context checkpoint 32 of 32 (pos_min = 90689, pos_max = 90689, n_tokens = 90690, size = 339.555 MiB)
2026-05-15 17:51:31.517 | slot update_slots: id  2 | task 2136 | n_tokens = 90782, memory_seq_rm [90782, end)
2026-05-15 17:51:31.530 | slot init_sampler: id  2 | task 2136 | init sampler, took 12.89 ms, tokens: text = 90786, total = 90786
2026-05-15 17:51:31.530 | slot update_slots: id  2 | task 2136 | prompt processing done, n_tokens = 90786, batch.n_tokens = 4
2026-05-15 17:51:31.530 | slot create_check: id  2 | task 2136 | erasing old context checkpoint (pos_min = 27361, pos_max = 27361, n_tokens = 27362, size = 206.930 MiB)
2026-05-15 17:51:31.858 | slot create_check: id  2 | task 2136 | created context checkpoint 32 of 32 (pos_min = 90781, pos_max = 90781, n_tokens = 90782, size = 339.748 MiB)
2026-05-15 17:51:31.903 | srv  log_server_r: done request: POST /v1/chat/completions 172.18.0.1 200
2026-05-15 17:51:32.193 | reasoning-budget: deactivated (natural end)
2026-05-15 17:51:33.537 | slot print_timing: id  2 | task 2136 | 
2026-05-15 17:51:33.537 | prompt eval time =     803.74 ms /    96 tokens (    8.37 ms per token,   119.44 tokens per second)
2026-05-15 17:51:33.537 |        eval time =    1633.65 ms /    91 tokens (   17.95 ms per token,    55.70 tokens per second)
2026-05-15 17:51:33.537 |       total time =    2437.39 ms /   187 tokens
2026-05-15 17:51:33.537 | draft acceptance rate = 1.00000 (   51 accepted /    51 generated)
2026-05-15 17:51:33.537 | statistics mtp: #calls(b,g,a) = 30 1974 1912, #gen drafts = 1912, #acc drafts = 1912, #gen tokens = 3380, #acc tokens = 3330, dur(b,g,a) = 0.043, 8858.655, 0.789 ms
2026-05-15 17:51:33.539 | slot      release: id  2 | task 2136 | stop processing: n_tokens = 90876, truncated = 0
2026-05-15 17:51:33.539 | srv  update_slots: all slots are idle
2026-05-15 17:51:33.869 | srv  params_from_: Chat format: peg-native
2026-05-15 17:51:33.872 | slot get_availabl: id  2 | task -1 | selected slot by LCP similarity, sim_best = 1.000 (> 0.100 thold), f_keep = 1.000
2026-05-15 17:51:33.873 | reasoning-budget: activated, budget=2147483647 tokens
2026-05-15 17:51:33.873 | slot launch_slot_: id  2 | task -1 | sampler chain: logits -> penalties -> ?dry -> ?top-n-sigma -> top-k -> ?typical -> ?top-p -> min-p -> ?xtc -> ?temp-ext -> dist 
2026-05-15 17:51:33.873 | slot launch_slot_: id  2 | task 2179 | processing task, is_child = 0
2026-05-15 17:51:33.873 | slot update_slots: id  2 | task 2179 | new prompt, n_ctx_slot = 131072, n_keep = 0, task.n_tokens = 90894
2026-05-15 17:51:33.873 | slot update_slots: id  2 | task 2179 | n_tokens = 90876, memory_seq_rm [90876, end)
2026-05-15 17:51:33.873 | slot update_slots: id  2 | task 2179 | prompt processing progress, n_tokens = 90890, batch.n_tokens = 14, progress = 0.999956
2026-05-15 17:51:33.873 | slot create_check: id  2 | task 2179 | erasing old context checkpoint (pos_min = 35647, pos_max = 35647, n_tokens = 35648, size = 224.283 MiB)
2026-05-15 17:51:34.194 | slot create_check: id  2 | task 2179 | created context checkpoint 32 of 32 (pos_min = 90875, pos_max = 90875, n_tokens = 90876, size = 339.945 MiB)
2026-05-15 17:51:34.241 | slot update_slots: id  2 | task 2179 | n_tokens = 90890, memory_seq_rm [90890, end)
2026-05-15 17:51:34.254 | slot init_sampler: id  2 | task 2179 | init sampler, took 12.42 ms, tokens: text = 90894, total = 90894
2026-05-15 17:51:34.254 | slot update_slots: id  2 | task 2179 | prompt processing done, n_tokens = 90894, batch.n_tokens = 4
2026-05-15 17:51:34.298 | srv  log_server_r: done request: POST /v1/chat/completions 172.18.0.1 200
2026-05-15 17:51:35.287 | reasoning-budget: deactivated (natural end)
2026-05-15 17:51:36.704 | slot print_timing: id  2 | task 2179 | 
2026-05-15 17:51:36.704 | prompt eval time =     424.89 ms /    18 tokens (   23.61 ms per token,    42.36 tokens per second)
2026-05-15 17:51:36.704 |        eval time =    2405.59 ms /   119 tokens (   20.22 ms per token,    49.47 tokens per second)
2026-05-15 17:51:36.704 |       total time =    2830.48 ms /   137 tokens
2026-05-15 17:51:36.704 | draft acceptance rate = 0.98462 (   64 accepted /    65 generated)
2026-05-15 17:51:36.704 | statistics mtp: #calls(b,g,a) = 31 2028 1949, #gen drafts = 1949, #acc drafts = 1949, #gen tokens = 3445, #acc tokens = 3394, dur(b,g,a) = 0.044, 9088.274, 0.799 ms
2026-05-15 17:51:36.706 | slot      release: id  2 | task 2179 | stop processing: n_tokens = 91012, truncated = 0
2026-05-15 17:51:36.706 | srv  update_slots: all slots are idle
2026-05-15 17:51:37.639 | srv  params_from_: Chat format: peg-native
2026-05-15 17:51:37.642 | slot get_availabl: id  2 | task -1 | selected slot by LCP similarity, sim_best = 0.996 (> 0.100 thold), f_keep = 1.000
2026-05-15 17:51:37.643 | reasoning-budget: activated, budget=2147483647 tokens
2026-05-15 17:51:37.644 | slot launch_slot_: id  2 | task -1 | sampler chain: logits -> penalties -> ?dry -> ?top-n-sigma -> top-k -> ?typical -> ?top-p -> min-p -> ?xtc -> ?temp-ext -> dist 
2026-05-15 17:51:37.644 | slot launch_slot_: id  2 | task 2240 | processing task, is_child = 0
2026-05-15 17:51:37.644 | slot update_slots: id  2 | task 2240 | new prompt, n_ctx_slot = 131072, n_keep = 0, task.n_tokens = 91379
2026-05-15 17:51:37.644 | slot update_slots: id  2 | task 2240 | n_tokens = 91012, memory_seq_rm [91012, end)
2026-05-15 17:51:37.644 | slot update_slots: id  2 | task 2240 | prompt processing progress, n_tokens = 91375, batch.n_tokens = 363, progress = 0.999956
2026-05-15 17:51:37.644 | slot create_check: id  2 | task 2240 | erasing old context checkpoint (pos_min = 43839, pos_max = 43839, n_tokens = 43840, size = 241.439 MiB)
2026-05-15 17:51:37.966 | slot create_check: id  2 | task 2240 | created context checkpoint 32 of 32 (pos_min = 91011, pos_max = 91011, n_tokens = 91012, size = 340.230 MiB)
2026-05-15 17:51:38.307 | slot update_slots: id  2 | task 2240 | n_tokens = 91375, memory_seq_rm [91375, end)
2026-05-15 17:51:38.321 | slot init_sampler: id  2 | task 2240 | init sampler, took 13.37 ms, tokens: text = 91379, total = 91379
2026-05-15 17:51:38.321 | slot update_slots: id  2 | task 2240 | prompt processing done, n_tokens = 91379, batch.n_tokens = 4
2026-05-15 17:51:38.321 | slot create_check: id  2 | task 2240 | erasing old context checkpoint (pos_min = 45135, pos_max = 45135, n_tokens = 45136, size = 244.153 MiB)
2026-05-15 17:51:38.637 | slot create_check: id  2 | task 2240 | created context checkpoint 32 of 32 (pos_min = 91374, pos_max = 91374, n_tokens = 91375, size = 340.990 MiB)
2026-05-15 17:51:38.681 | srv  log_server_r: done request: POST /v1/chat/completions 172.18.0.1 200
2026-05-15 17:51:39.765 | reasoning-budget: deactivated (natural end)
2026-05-15 17:51:41.194 | slot print_timing: id  2 | task 2240 | 
2026-05-15 17:51:41.194 | prompt eval time =    1036.49 ms /   367 tokens (    2.82 ms per token,   354.08 tokens per second)
2026-05-15 17:51:41.194 |        eval time =    2513.15 ms /   127 tokens (   19.79 ms per token,    50.53 tokens per second)
2026-05-15 17:51:41.194 |       total time =    3549.64 ms /   494 tokens
2026-05-15 17:51:41.194 | draft acceptance rate = 1.00000 (   67 accepted /    67 generated)
2026-05-15 17:51:41.194 | statistics mtp: #calls(b,g,a) = 32 2087 1987, #gen drafts = 1987, #acc drafts = 1987, #gen tokens = 3512, #acc tokens = 3461, dur(b,g,a) = 0.045, 9334.669, 0.819 ms
2026-05-15 17:51:41.196 | slot      release: id  2 | task 2240 | stop processing: n_tokens = 91505, truncated = 0
2026-05-15 17:51:41.196 | srv  update_slots: all slots are idle
2026-05-15 17:51:42.655 | srv  params_from_: Chat format: peg-native
2026-05-15 17:51:42.657 | slot get_availabl: id  2 | task -1 | selected slot by LCP similarity, sim_best = 1.000 (> 0.100 thold), f_keep = 1.000
2026-05-15 17:51:42.659 | reasoning-budget: activated, budget=2147483647 tokens
2026-05-15 17:51:42.659 | slot launch_slot_: id  2 | task -1 | sampler chain: logits -> penalties -> ?dry -> ?top-n-sigma -> top-k -> ?typical -> ?top-p -> min-p -> ?xtc -> ?temp-ext -> dist 
2026-05-15 17:51:42.659 | slot launch_slot_: id  2 | task 2303 | processing task, is_child = 0
2026-05-15 17:51:42.659 | slot update_slots: id  2 | task 2303 | new prompt, n_ctx_slot = 131072, n_keep = 0, task.n_tokens = 91523
2026-05-15 17:51:42.659 | slot update_slots: id  2 | task 2303 | n_tokens = 91505, memory_seq_rm [91505, end)
2026-05-15 17:51:42.659 | slot update_slots: id  2 | task 2303 | prompt processing progress, n_tokens = 91519, batch.n_tokens = 14, progress = 0.999956
2026-05-15 17:51:42.659 | slot create_check: id  2 | task 2303 | erasing old context checkpoint (pos_min = 45647, pos_max = 45647, n_tokens = 45648, size = 245.225 MiB)
2026-05-15 17:51:42.980 | slot create_check: id  2 | task 2303 | created context checkpoint 32 of 32 (pos_min = 91504, pos_max = 91504, n_tokens = 91505, size = 341.262 MiB)
2026-05-15 17:51:43.029 | slot update_slots: id  2 | task 2303 | n_tokens = 91519, memory_seq_rm [91519, end)
2026-05-15 17:51:43.042 | slot init_sampler: id  2 | task 2303 | init sampler, took 13.16 ms, tokens: text = 91523, total = 91523
2026-05-15 17:51:43.042 | slot update_slots: id  2 | task 2303 | prompt processing done, n_tokens = 91523, batch.n_tokens = 4
2026-05-15 17:51:43.087 | srv  log_server_r: done request: POST /v1/chat/completions 172.18.0.1 200
2026-05-15 17:51:43.754 | reasoning-budget: deactivated (natural end)
2026-05-15 17:51:44.964 | slot print_timing: id  2 | task 2303 | 
2026-05-15 17:51:44.964 | prompt eval time =     427.24 ms /    18 tokens (   23.74 ms per token,    42.13 tokens per second)
2026-05-15 17:51:44.964 |        eval time =    1877.65 ms /   100 tokens (   18.78 ms per token,    53.26 tokens per second)
2026-05-15 17:51:44.964 |       total time =    2304.89 ms /   118 tokens
2026-05-15 17:51:44.964 | draft acceptance rate = 1.00000 (   59 accepted /    59 generated)
2026-05-15 17:51:44.964 | statistics mtp: #calls(b,g,a) = 33 2127 2020, #gen drafts = 2020, #acc drafts = 2020, #gen tokens = 3571, #acc tokens = 3520, dur(b,g,a) = 0.046, 9521.480, 0.836 ms
2026-05-15 17:51:44.966 | slot      release: id  2 | task 2303 | stop processing: n_tokens = 91622, truncated = 0
2026-05-15 17:51:44.966 | srv  update_slots: all slots are idle
2026-05-15 17:51:46.131 | srv  params_from_: Chat format: peg-native
2026-05-15 17:51:46.134 | slot get_availabl: id  2 | task -1 | selected slot by LCP similarity, sim_best = 0.995 (> 0.100 thold), f_keep = 1.000
2026-05-15 17:51:46.135 | reasoning-budget: activated, budget=2147483647 tokens
2026-05-15 17:51:46.135 | slot launch_slot_: id  2 | task -1 | sampler chain: logits -> penalties -> ?dry -> ?top-n-sigma -> top-k -> ?typical -> ?top-p -> min-p -> ?xtc -> ?temp-ext -> dist 
2026-05-15 17:51:46.135 | slot launch_slot_: id  2 | task 2351 | processing task, is_child = 0
2026-05-15 17:51:46.135 | slot update_slots: id  2 | task 2351 | new prompt, n_ctx_slot = 131072, n_keep = 0, task.n_tokens = 92102
2026-05-15 17:51:46.135 | slot update_slots: id  2 | task 2351 | n_tokens = 91622, memory_seq_rm [91622, end)
2026-05-15 17:51:46.136 | slot update_slots: id  2 | task 2351 | prompt processing progress, n_tokens = 92098, batch.n_tokens = 476, progress = 0.999957
2026-05-15 17:51:46.136 | slot create_check: id  2 | task 2351 | erasing old context checkpoint (pos_min = 45776, pos_max = 45776, n_tokens = 45777, size = 245.496 MiB)
2026-05-15 17:51:46.456 | slot create_check: id  2 | task 2351 | created context checkpoint 32 of 32 (pos_min = 91621, pos_max = 91621, n_tokens = 91622, size = 341.507 MiB)
2026-05-15 17:51:46.798 | slot update_slots: id  2 | task 2351 | n_tokens = 92098, memory_seq_rm [92098, end)
2026-05-15 17:51:46.812 | slot init_sampler: id  2 | task 2351 | init sampler, took 12.88 ms, tokens: text = 92102, total = 92102
2026-05-15 17:51:46.812 | slot update_slots: id  2 | task 2351 | prompt processing done, n_tokens = 92102, batch.n_tokens = 4
2026-05-15 17:51:46.812 | slot create_check: id  2 | task 2351 | erasing old context checkpoint (pos_min = 45905, pos_max = 45905, n_tokens = 45906, size = 245.766 MiB)
2026-05-15 17:51:47.154 | slot create_check: id  2 | task 2351 | created context checkpoint 32 of 32 (pos_min = 92097, pos_max = 92097, n_tokens = 92098, size = 342.504 MiB)
2026-05-15 17:51:47.199 | srv  log_server_r: done request: POST /v1/chat/completions 172.18.0.1 200
2026-05-15 17:51:49.069 | reasoning-budget: deactivated (natural end)
2026-05-15 17:51:50.135 | slot print_timing: id  2 | task 2351 | 
2026-05-15 17:51:50.135 | prompt eval time =    1062.81 ms /   480 tokens (    2.21 ms per token,   451.63 tokens per second)
2026-05-15 17:51:50.135 |        eval time =    2936.57 ms /   155 tokens (   18.95 ms per token,    52.78 tokens per second)
2026-05-15 17:51:50.135 |       total time =    3999.38 ms /   635 tokens
2026-05-15 17:51:50.135 | draft acceptance rate = 1.00000 (   82 accepted /    82 generated)
2026-05-15 17:51:50.135 | statistics mtp: #calls(b,g,a) = 34 2199 2066, #gen drafts = 2066, #acc drafts = 2066, #gen tokens = 3653, #acc tokens = 3602, dur(b,g,a) = 0.048, 9818.041, 0.855 ms
2026-05-15 17:51:50.137 | slot      release: id  2 | task 2351 | stop processing: n_tokens = 92256, truncated = 0
2026-05-15 17:51:50.137 | srv  update_slots: all slots are idle
2026-05-15 17:51:50.505 | srv  params_from_: Chat format: peg-native
2026-05-15 17:51:50.508 | slot get_availabl: id  2 | task -1 | selected slot by LCP similarity, sim_best = 0.813 (> 0.100 thold), f_keep = 1.000
2026-05-15 17:51:50.509 | reasoning-budget: activated, budget=2147483647 tokens
2026-05-15 17:51:50.509 | slot launch_slot_: id  2 | task -1 | sampler chain: logits -> penalties -> ?dry -> ?top-n-sigma -> top-k -> ?typical -> ?top-p -> min-p -> ?xtc -> ?temp-ext -> dist 
2026-05-15 17:51:50.509 | slot launch_slot_: id  2 | task 2426 | processing task, is_child = 0
2026-05-15 17:51:50.509 | slot update_slots: id  2 | task 2426 | new prompt, n_ctx_slot = 131072, n_keep = 0, task.n_tokens = 113426
2026-05-15 17:51:50.509 | slot update_slots: id  2 | task 2426 | n_tokens = 92256, memory_seq_rm [92256, end)
2026-05-15 17:51:50.510 | slot update_slots: id  2 | task 2426 | prompt processing progress, n_tokens = 94304, batch.n_tokens = 2048, progress = 0.831414
2026-05-15 17:51:52.359 | slot update_slots: id  2 | task 2426 | n_tokens = 94304, memory_seq_rm [94304, end)
2026-05-15 17:51:52.360 | slot update_slots: id  2 | task 2426 | prompt processing progress, n_tokens = 96352, batch.n_tokens = 2048, progress = 0.849470
2026-05-15 17:51:54.247 | slot update_slots: id  2 | task 2426 | n_tokens = 96352, memory_seq_rm [96352, end)
2026-05-15 17:51:54.247 | slot update_slots: id  2 | task 2426 | prompt processing progress, n_tokens = 98400, batch.n_tokens = 2048, progress = 0.867526
2026-05-15 17:51:56.161 | slot update_slots: id  2 | task 2426 | n_tokens = 98400, memory_seq_rm [98400, end)
2026-05-15 17:51:56.161 | slot update_slots: id  2 | task 2426 | prompt processing progress, n_tokens = 100448, batch.n_tokens = 2048, progress = 0.885582
2026-05-15 17:51:58.088 | slot update_slots: id  2 | task 2426 | n_tokens = 100448, memory_seq_rm [100448, end)
2026-05-15 17:51:58.088 | slot update_slots: id  2 | task 2426 | 8192 tokens since last checkpoint at 92098, creating new checkpoint during processing at position 102496
2026-05-15 17:51:58.088 | slot update_slots: id  2 | task 2426 | prompt processing progress, n_tokens = 102496, batch.n_tokens = 2048, progress = 0.903638
2026-05-15 17:51:58.088 | slot create_check: id  2 | task 2426 | erasing old context checkpoint (pos_min = 46047, pos_max = 46047, n_tokens = 46048, size = 246.063 MiB)
2026-05-15 17:51:58.428 | slot create_check: id  2 | task 2426 | created context checkpoint 32 of 32 (pos_min = 100447, pos_max = 100447, n_tokens = 100448, size = 359.991 MiB)
2026-05-15 17:52:00.396 | slot update_slots: id  2 | task 2426 | n_tokens = 102496, memory_seq_rm [102496, end)
2026-05-15 17:52:00.396 | slot update_slots: id  2 | task 2426 | prompt processing progress, n_tokens = 104544, batch.n_tokens = 2048, progress = 0.921693
2026-05-15 17:52:00.079 | slot update_slots: id  2 | task 2426 | n_tokens = 104544, memory_seq_rm [104544, end)
2026-05-15 17:52:00.079 | slot update_slots: id  2 | task 2426 | prompt processing progress, n_tokens = 106592, batch.n_tokens = 2048, progress = 0.939749
2026-05-15 17:52:02.119 | slot update_slots: id  2 | task 2426 | n_tokens = 106592, memory_seq_rm [106592, end)
2026-05-15 17:52:02.119 | slot update_slots: id  2 | task 2426 | prompt processing progress, n_tokens = 108640, batch.n_tokens = 2048, progress = 0.957805
2026-05-15 17:52:04.178 | slot update_slots: id  2 | task 2426 | n_tokens = 108640, memory_seq_rm [108640, end)
2026-05-15 17:52:04.179 | slot update_slots: id  2 | task 2426 | 8192 tokens since last checkpoint at 100448, creating new checkpoint during processing at position 110688
2026-05-15 17:52:04.179 | slot update_slots: id  2 | task 2426 | prompt processing progress, n_tokens = 110688, batch.n_tokens = 2048, progress = 0.975861
2026-05-15 17:52:04.179 | slot create_check: id  2 | task 2426 | erasing old context checkpoint (pos_min = 54434, pos_max = 54434, n_tokens = 54435, size = 263.628 MiB)
2026-05-15 17:52:04.530 | slot create_check: id  2 | task 2426 | created context checkpoint 32 of 32 (pos_min = 108639, pos_max = 108639, n_tokens = 108640, size = 377.148 MiB)
2026-05-15 17:52:06.624 | slot update_slots: id  2 | task 2426 | n_tokens = 110688, memory_seq_rm [110688, end)
2026-05-15 17:52:06.624 | slot update_slots: id  2 | task 2426 | prompt processing progress, n_tokens = 112736, batch.n_tokens = 2048, progress = 0.993917
2026-05-15 17:52:08.740 | slot update_slots: id  2 | task 2426 | n_tokens = 112736, memory_seq_rm [112736, end)
2026-05-15 17:52:08.740 | slot update_slots: id  2 | task 2426 | prompt processing progress, n_tokens = 112910, batch.n_tokens = 174, progress = 0.995451
2026-05-15 17:52:08.967 | slot update_slots: id  2 | task 2426 | n_tokens = 112910, memory_seq_rm [112910, end)
2026-05-15 17:52:08.967 | slot update_slots: id  2 | task 2426 | prompt processing progress, n_tokens = 113422, batch.n_tokens = 512, progress = 0.999965
2026-05-15 17:52:08.967 | slot create_check: id  2 | task 2426 | erasing old context checkpoint (pos_min = 62626, pos_max = 62626, n_tokens = 62627, size = 280.784 MiB)
2026-05-15 17:52:09.322 | slot create_check: id  2 | task 2426 | created context checkpoint 32 of 32 (pos_min = 112909, pos_max = 112909, n_tokens = 112910, size = 386.090 MiB)
2026-05-15 17:52:09.866 | slot update_slots: id  2 | task 2426 | n_tokens = 113422, memory_seq_rm [113422, end)
2026-05-15 17:52:09.883 | slot init_sampler: id  2 | task 2426 | init sampler, took 16.81 ms, tokens: text = 113426, total = 113426
2026-05-15 17:52:09.884 | slot update_slots: id  2 | task 2426 | prompt processing done, n_tokens = 113426, batch.n_tokens = 4
2026-05-15 17:52:09.884 | slot create_check: id  2 | task 2426 | erasing old context checkpoint (pos_min = 66910, pos_max = 66910, n_tokens = 66911, size = 289.756 MiB)
2026-05-15 17:52:10.243 | slot create_check: id  2 | task 2426 | created context checkpoint 32 of 32 (pos_min = 113421, pos_max = 113421, n_tokens = 113422, size = 387.162 MiB)
2026-05-15 17:52:10.292 | srv  log_server_r: done request: POST /v1/chat/completions 172.18.0.1 200
2026-05-15 17:52:11.165 | reasoning-budget: deactivated (natural end)
2026-05-15 17:52:12.264 | slot print_timing: id  2 | task 2426 | 
2026-05-15 17:52:12.264 | prompt eval time =   22088.17 ms / 21170 tokens (    1.04 ms per token,   958.43 tokens per second)
2026-05-15 17:52:12.264 |        eval time =    1972.55 ms /    95 tokens (   20.76 ms per token,    48.16 tokens per second)
2026-05-15 17:52:12.264 |       total time =   24060.72 ms / 21265 tokens
2026-05-15 17:52:12.264 | draft acceptance rate = 0.98182 (   54 accepted /    55 generated)
2026-05-15 17:52:12.264 | statistics mtp: #calls(b,g,a) = 35 2239 2098, #gen drafts = 2098, #acc drafts = 2098, #gen tokens = 3708, #acc tokens = 3656, dur(b,g,a) = 0.050, 10015.209, 0.868 ms
2026-05-15 17:52:12.267 | slot      release: id  2 | task 2426 | stop processing: n_tokens = 113520, truncated = 0
2026-05-15 17:52:12.267 | srv  update_slots: all slots are idle
2026-05-15 17:52:12.519 | srv  params_from_: Chat format: peg-native
2026-05-15 17:52:12.520 | slot get_availabl: id  1 | task -1 | selected slot by LRU, t_last = -1
2026-05-15 17:52:12.520 | srv  get_availabl: updating prompt cache
2026-05-15 17:52:12.520 | srv          load:  - looking for better prompt, base f_keep = -1.000, sim = 0.000
2026-05-15 17:52:12.520 | srv        update:  - cache state: 1 prompts, 539.757 MiB (limits: 8192.000 MiB, 131072 tokens, 131072 est)
2026-05-15 17:52:12.520 | srv        update:    - prompt 0x6487e845e240:    2497 tokens, checkpoints:  2,   539.757 MiB
2026-05-15 17:52:12.520 | srv  get_availabl: prompt cache update took 0.01 ms
2026-05-15 17:52:12.521 | slot launch_slot_: id  1 | task -1 | sampler chain: logits -> penalties -> ?dry -> ?top-n-sigma -> top-k -> ?typical -> ?top-p -> min-p -> ?xtc -> ?temp-ext -> dist 
2026-05-15 17:52:12.521 | slot launch_slot_: id  1 | task 2485 | processing task, is_child = 0
2026-05-15 17:52:12.521 | slot slot_save_an: id  2 | task -1 | saving idle slot to prompt cache
2026-05-15 17:52:12.525 | srv   prompt_save:  - saving prompt with length 113520, total state size = 4158.752 MiB (draft: 237.741 MiB)
2026-05-15 17:52:26.889 | slot prompt_clear: id  2 | task -1 | clearing prompt with 113520 tokens
2026-05-15 17:52:26.908 | srv        update:  - cache size limit reached, removing oldest entry (size = 539.757 MiB)
2026-05-15 17:52:26.947 | srv        update:  - cache state: 1 prompts, 15022.483 MiB (limits: 8192.000 MiB, 131072 tokens, 131072 est)
2026-05-15 17:52:26.947 | srv        update:    - prompt 0x6487e7e20bb0:  113520 tokens, checkpoints: 32, 15022.483 MiB
2026-05-15 17:52:26.947 | slot update_slots: id  1 | task 2485 | new prompt, n_ctx_slot = 131072, n_keep = 0, task.n_tokens = 16242
2026-05-15 17:52:26.947 | slot update_slots: id  1 | task 2485 | n_tokens = 0, memory_seq_rm [0, end)
2026-05-15 17:52:26.948 | slot update_slots: id  1 | task 2485 | prompt processing progress, n_tokens = 2048, batch.n_tokens = 2048, progress = 0.126093
2026-05-15 17:52:27.703 | slot update_slots: id  1 | task 2485 | n_tokens = 2048, memory_seq_rm [2048, end)
2026-05-15 17:52:27.703 | slot update_slots: id  1 | task 2485 | prompt processing progress, n_tokens = 4096, batch.n_tokens = 2048, progress = 0.252186
2026-05-15 17:52:28.471 | slot update_slots: id  1 | task 2485 | n_tokens = 4096, memory_seq_rm [4096, end)
2026-05-15 17:52:28.471 | slot update_slots: id  1 | task 2485 | prompt processing progress, n_tokens = 6144, batch.n_tokens = 2048, progress = 0.378279
2026-05-15 17:52:29.249 | slot update_slots: id  1 | task 2485 | n_tokens = 6144, memory_seq_rm [6144, end)
2026-05-15 17:52:29.249 | slot update_slots: id  1 | task 2485 | prompt processing progress, n_tokens = 8192, batch.n_tokens = 2048, progress = 0.504371
2026-05-15 17:52:30.043 | slot update_slots: id  1 | task 2485 | n_tokens = 8192, memory_seq_rm [8192, end)
2026-05-15 17:52:30.043 | slot update_slots: id  1 | task 2485 | 8192 tokens since last checkpoint at 0, creating new checkpoint during processing at position 10240
2026-05-15 17:52:30.043 | slot update_slots: id  1 | task 2485 | prompt processing progress, n_tokens = 10240, batch.n_tokens = 2048, progress = 0.630464
2026-05-15 17:52:30.210 | slot create_check: id  1 | task 2485 | created context checkpoint 1 of 32 (pos_min = 8191, pos_max = 8191, n_tokens = 8192, size = 166.782 MiB)
2026-05-15 17:52:31.022 | slot update_slots: id  1 | task 2485 | n_tokens = 10240, memory_seq_rm [10240, end)
2026-05-15 17:52:31.022 | slot update_slots: id  1 | task 2485 | prompt processing progress, n_tokens = 12288, batch.n_tokens = 2048, progress = 0.756557
2026-05-15 17:52:31.849 | slot update_slots: id  1 | task 2485 | n_tokens = 12288, memory_seq_rm [12288, end)
2026-05-15 17:52:31.849 | slot update_slots: id  1 | task 2485 | prompt processing progress, n_tokens = 14336, batch.n_tokens = 2048, progress = 0.882650
2026-05-15 17:52:32.683 | slot update_slots: id  1 | task 2485 | n_tokens = 14336, memory_seq_rm [14336, end)
2026-05-15 17:52:32.683 | slot update_slots: id  1 | task 2485 | prompt processing progress, n_tokens = 15726, batch.n_tokens = 1390, progress = 0.968230
2026-05-15 17:52:33.270 | slot update_slots: id  1 | task 2485 | n_tokens = 15726, memory_seq_rm [15726, end)
2026-05-15 17:52:33.270 | slot update_slots: id  1 | task 2485 | prompt processing progress, n_tokens = 16238, batch.n_tokens = 512, progress = 0.999754
2026-05-15 17:52:33.485 | slot create_check: id  1 | task 2485 | created context checkpoint 2 of 32 (pos_min = 15725, pos_max = 15725, n_tokens = 15726, size = 182.561 MiB)
2026-05-15 17:52:33.696 | slot update_slots: id  1 | task 2485 | n_tokens = 16238, memory_seq_rm [16238, end)
2026-05-15 17:52:33.699 | slot init_sampler: id  1 | task 2485 | init sampler, took 2.30 ms, tokens: text = 16242, total = 16242
2026-05-15 17:52:33.699 | slot update_slots: id  1 | task 2485 | prompt processing done, n_tokens = 16242, batch.n_tokens = 4
2026-05-15 17:52:33.919 | slot create_check: id  1 | task 2485 | created context checkpoint 3 of 32 (pos_min = 16237, pos_max = 16237, n_tokens = 16238, size = 183.633 MiB)
2026-05-15 17:52:33.954 | srv  log_server_r: done request: POST /v1/chat/completions 172.18.0.1 200
2026-05-15 17:52:33.960 | ~llama_io_write_device: allocated 'CUDA0' buffer 149.625 MiB
2026-05-15 17:52:53.186 | slot print_timing: id  1 | task 2485 | 
2026-05-15 17:52:53.186 | prompt eval time =    7006.79 ms / 16242 tokens (    0.43 ms per token,  2318.04 tokens per second)
2026-05-15 17:52:53.186 |        eval time =   19231.90 ms /  1104 tokens (   17.42 ms per token,    57.40 tokens per second)
2026-05-15 17:52:53.186 |       total time =   26238.69 ms / 17346 tokens
2026-05-15 17:52:53.186 | draft acceptance rate = 0.97561 (  600 accepted /   615 generated)
2026-05-15 17:52:53.186 | statistics mtp: #calls(b,g,a) = 36 2742 2464, #gen drafts = 2464, #acc drafts = 2464, #gen tokens = 4323, #acc tokens = 4256, dur(b,g,a) = 0.052, 11905.234, 1.060 ms
2026-05-15 17:52:53.186 | slot      release: id  1 | task 2485 | stop processing: n_tokens = 17345, truncated = 0
2026-05-15 17:52:53.186 | srv  update_slots: all slots are idle
2026-05-15 17:52:53.335 | srv  params_from_: Chat format: peg-native
2026-05-15 17:52:53.338 | slot get_availabl: id  0 | task -1 | selected slot by LRU, t_last = -1
2026-05-15 17:52:53.338 | srv  get_availabl: updating prompt cache
2026-05-15 17:52:53.338 | srv          load:  - looking for better prompt, base f_keep = -1.000, sim = 0.000
2026-05-15 17:52:53.338 | srv        update:  - cache state: 1 prompts, 15022.483 MiB (limits: 8192.000 MiB, 131072 tokens, 131072 est)
2026-05-15 17:52:53.338 | srv        update:    - prompt 0x6487e7e20bb0:  113520 tokens, checkpoints: 32, 15022.483 MiB
2026-05-15 17:52:53.338 | srv  get_availabl: prompt cache update took 0.03 ms
2026-05-15 17:52:53.339 | reasoning-budget: activated, budget=2147483647 tokens
2026-05-15 17:52:53.339 | slot launch_slot_: id  0 | task -1 | sampler chain: logits -> penalties -> ?dry -> ?top-n-sigma -> top-k -> ?typical -> ?top-p -> min-p -> ?xtc -> ?temp-ext -> dist 
2026-05-15 17:52:53.339 | slot launch_slot_: id  0 | task 3043 | processing task, is_child = 0
2026-05-15 17:52:53.339 | slot slot_save_an: id  1 | task -1 | saving idle slot to prompt cache
2026-05-15 17:52:53.340 | srv   prompt_save:  - saving prompt with length 17345, total state size = 762.191 MiB (draft: 36.325 MiB)
2026-05-15 17:52:54.758 | slot prompt_clear: id  1 | task -1 | clearing prompt with 17345 tokens
2026-05-15 17:52:54.761 | srv        update:  - cache size limit reached, removing oldest entry (size = 15022.483 MiB)
2026-05-15 17:52:55.683 | srv        update:  - cache state: 1 prompts, 1295.167 MiB (limits: 8192.000 MiB, 131072 tokens, 131072 est)
2026-05-15 17:52:55.684 | srv        update:    - prompt 0x6487df0acf00:   17345 tokens, checkpoints:  3,  1295.167 MiB
2026-05-15 17:52:55.684 | slot update_slots: id  0 | task 3043 | new prompt, n_ctx_slot = 131072, n_keep = 0, task.n_tokens = 12752
2026-05-15 17:52:55.684 | slot update_slots: id  0 | task 3043 | n_tokens = 0, memory_seq_rm [0, end)
2026-05-15 17:52:55.684 | slot update_slots: id  0 | task 3043 | prompt processing progress, n_tokens = 2048, batch.n_tokens = 2048, progress = 0.160602
2026-05-15 17:52:59.295 | slot update_slots: id  0 | task 3043 | n_tokens = 2048, memory_seq_rm [2048, end)
2026-05-15 17:52:59.295 | slot update_slots: id  0 | task 3043 | prompt processing progress, n_tokens = 4096, batch.n_tokens = 2048, progress = 0.321205
2026-05-15 17:52:54.937 | slot update_slots: id  0 | task 3043 | n_tokens = 4096, memory_seq_rm [4096, end)
2026-05-15 17:52:54.938 | slot update_slots: id  0 | task 3043 | prompt processing progress, n_tokens = 6144, batch.n_tokens = 2048, progress = 0.481807
2026-05-15 17:52:55.719 | slot update_slots: id  0 | task 3043 | n_tokens = 6144, memory_seq_rm [6144, end)
2026-05-15 17:52:55.719 | slot update_slots: id  0 | task 3043 | prompt processing progress, n_tokens = 8192, batch.n_tokens = 2048, progress = 0.642409
2026-05-15 17:52:56.524 | slot update_slots: id  0 | task 3043 | n_tokens = 8192, memory_seq_rm [8192, end)
2026-05-15 17:52:56.524 | slot update_slots: id  0 | task 3043 | 8192 tokens since last checkpoint at 0, creating new checkpoint during processing at position 10240
2026-05-15 17:52:56.524 | slot update_slots: id  0 | task 3043 | prompt processing progress, n_tokens = 10240, batch.n_tokens = 2048, progress = 0.803011
2026-05-15 17:52:56.645 | slot create_check: id  0 | task 3043 | created context checkpoint 1 of 32 (pos_min = 8191, pos_max = 8191, n_tokens = 8192, size = 166.782 MiB)
2026-05-15 17:52:57.474 | slot update_slots: id  0 | task 3043 | n_tokens = 10240, memory_seq_rm [10240, end)
2026-05-15 17:52:57.474 | slot update_slots: id  0 | task 3043 | prompt processing progress, n_tokens = 12236, batch.n_tokens = 1996, progress = 0.959536
2026-05-15 17:52:58.299 | slot update_slots: id  0 | task 3043 | n_tokens = 12236, memory_seq_rm [12236, end)
2026-05-15 17:52:58.299 | slot update_slots: id  0 | task 3043 | prompt processing progress, n_tokens = 12748, batch.n_tokens = 512, progress = 0.999686
2026-05-15 17:52:58.452 | slot create_check: id  0 | task 3043 | created context checkpoint 2 of 32 (pos_min = 12235, pos_max = 12235, n_tokens = 12236, size = 175.252 MiB)
2026-05-15 17:52:58.661 | slot update_slots: id  0 | task 3043 | n_tokens = 12748, memory_seq_rm [12748, end)
2026-05-15 17:52:58.663 | slot init_sampler: id  0 | task 3043 | init sampler, took 1.97 ms, tokens: text = 12752, total = 12752
2026-05-15 17:52:58.663 | slot update_slots: id  0 | task 3043 | prompt processing done, n_tokens = 12752, batch.n_tokens = 4
2026-05-15 17:52:58.861 | slot create_check: id  0 | task 3043 | created context checkpoint 3 of 32 (pos_min = 12747, pos_max = 12747, n_tokens = 12748, size = 176.324 MiB)
2026-05-15 17:52:58.899 | srv  log_server_r: done request: POST /v1/chat/completions 172.18.0.1 200
2026-05-15 17:52:58.904 | ~llama_io_write_device: allocated 'CUDA0' buffer 149.625 MiB
2026-05-15 17:53:00.274 | reasoning-budget: deactivated (natural end)
2026-05-15 17:53:01.769 | slot print_timing: id  0 | task 3043 | 
2026-05-15 17:53:01.769 | prompt eval time =    5520.75 ms / 12752 tokens (    0.43 ms per token,  2309.83 tokens per second)
2026-05-15 17:53:01.769 |        eval time =    2870.66 ms /   178 tokens (   16.13 ms per token,    62.01 tokens per second)
2026-05-15 17:53:01.769 |       total time =    8391.41 ms / 12930 tokens
2026-05-15 17:53:01.769 | draft acceptance rate = 0.97222 (  105 accepted /   108 generated)
2026-05-15 17:53:01.769 | statistics mtp: #calls(b,g,a) = 37 2814 2524, #gen drafts = 2524, #acc drafts = 2524, #gen tokens = 4431, #acc tokens = 4361, dur(b,g,a) = 0.053, 12214.754, 1.093 ms
2026-05-15 17:53:01.770 | slot      release: id  0 | task 3043 | stop processing: n_tokens = 12929, truncated = 0
2026-05-15 17:53:01.770 | srv  update_slots: all slots are idle
2026-05-15 18:05:15.209 | srv  params_from_: Chat format: peg-native
2026-05-15 18:05:15.212 | slot get_availabl: id  0 | task -1 | selected slot by LCP similarity, sim_best = 0.557 (> 0.100 thold), f_keep = 1.000
2026-05-15 18:05:15.214 | reasoning-budget: activated, budget=2147483647 tokens
2026-05-15 18:05:15.214 | slot launch_slot_: id  0 | task -1 | sampler chain: logits -> penalties -> ?dry -> ?top-n-sigma -> top-k -> ?typical -> ?top-p -> min-p -> ?xtc -> ?temp-ext -> dist 
2026-05-15 18:05:15.214 | slot launch_slot_: id  0 | task 3130 | processing task, is_child = 0
2026-05-15 18:05:15.214 | slot update_slots: id  0 | task 3130 | new prompt, n_ctx_slot = 131072, n_keep = 0, task.n_tokens = 23196
2026-05-15 18:05:15.214 | slot update_slots: id  0 | task 3130 | n_tokens = 12929, memory_seq_rm [12929, end)
2026-05-15 18:05:15.214 | slot update_slots: id  0 | task 3130 | prompt processing progress, n_tokens = 14977, batch.n_tokens = 2048, progress = 0.645672
2026-05-15 18:05:16.238 | slot update_slots: id  0 | task 3130 | n_tokens = 14977, memory_seq_rm [14977, end)
2026-05-15 18:05:16.238 | slot update_slots: id  0 | task 3130 | prompt processing progress, n_tokens = 17025, batch.n_tokens = 2048, progress = 0.733963
2026-05-15 18:05:17.098 | slot update_slots: id  0 | task 3130 | n_tokens = 17025, memory_seq_rm [17025, end)
2026-05-15 18:05:17.098 | slot update_slots: id  0 | task 3130 | prompt processing progress, n_tokens = 19073, batch.n_tokens = 2048, progress = 0.822254
2026-05-15 18:05:17.962 | slot update_slots: id  0 | task 3130 | n_tokens = 19073, memory_seq_rm [19073, end)
2026-05-15 18:05:17.962 | slot update_slots: id  0 | task 3130 | prompt processing progress, n_tokens = 21121, batch.n_tokens = 2048, progress = 0.910545
2026-05-15 18:05:18.834 | slot update_slots: id  0 | task 3130 | n_tokens = 21121, memory_seq_rm [21121, end)
2026-05-15 18:05:18.834 | slot update_slots: id  0 | task 3130 | 8192 tokens since last checkpoint at 12748, creating new checkpoint during processing at position 22680
2026-05-15 18:05:18.834 | slot update_slots: id  0 | task 3130 | prompt processing progress, n_tokens = 22680, batch.n_tokens = 1559, progress = 0.977755
2026-05-15 18:05:19.060 | slot create_check: id  0 | task 3130 | created context checkpoint 4 of 32 (pos_min = 21120, pos_max = 21120, n_tokens = 21121, size = 193.859 MiB)
2026-05-15 18:05:19.761 | slot update_slots: id  0 | task 3130 | n_tokens = 22680, memory_seq_rm [22680, end)
2026-05-15 18:05:19.761 | slot update_slots: id  0 | task 3130 | prompt processing progress, n_tokens = 23192, batch.n_tokens = 512, progress = 0.999828
2026-05-15 18:05:19.943 | slot create_check: id  0 | task 3130 | created context checkpoint 5 of 32 (pos_min = 22679, pos_max = 22679, n_tokens = 22680, size = 197.124 MiB)
2026-05-15 18:05:20.175 | slot update_slots: id  0 | task 3130 | n_tokens = 23192, memory_seq_rm [23192, end)
2026-05-15 18:05:20.178 | slot init_sampler: id  0 | task 3130 | init sampler, took 3.25 ms, tokens: text = 23196, total = 23196
2026-05-15 18:05:20.178 | slot update_slots: id  0 | task 3130 | prompt processing done, n_tokens = 23196, batch.n_tokens = 4
2026-05-15 18:05:20.411 | slot create_check: id  0 | task 3130 | created context checkpoint 6 of 32 (pos_min = 23191, pos_max = 23191, n_tokens = 23192, size = 198.196 MiB)
2026-05-15 18:05:20.448 | srv  log_server_r: done request: POST /v1/chat/completions 172.18.0.1 200
2026-05-15 18:05:21.424 | reasoning-budget: deactivated (natural end)
2026-05-15 18:05:23.306 | slot print_timing: id  0 | task 3130 | 
2026-05-15 18:05:23.306 | prompt eval time =    5233.64 ms / 10267 tokens (    0.51 ms per token,  1961.73 tokens per second)
2026-05-15 18:05:23.306 |        eval time =    2858.01 ms /   199 tokens (   14.36 ms per token,    69.63 tokens per second)
2026-05-15 18:05:23.306 |       total time =    8091.66 ms / 10466 tokens
2026-05-15 18:05:23.306 | draft acceptance rate = 0.99174 (  120 accepted /   121 generated)
2026-05-15 18:05:23.306 | statistics mtp: #calls(b,g,a) = 38 2892 2591, #gen drafts = 2591, #acc drafts = 2591, #gen tokens = 4552, #acc tokens = 4481, dur(b,g,a) = 0.055, 12528.748, 1.126 ms
2026-05-15 18:05:23.307 | slot      release: id  0 | task 3130 | stop processing: n_tokens = 23394, truncated = 0
2026-05-15 18:05:23.307 | srv  update_slots: all slots are idle
2026-05-15 18:05:23.520 | srv  params_from_: Chat format: peg-native
2026-05-15 18:05:23.523 | slot get_availabl: id  0 | task -1 | selected slot by LCP similarity, sim_best = 0.539 (> 0.100 thold), f_keep = 1.000
2026-05-15 18:05:23.524 | reasoning-budget: activated, budget=2147483647 tokens
2026-05-15 18:05:23.524 | slot launch_slot_: id  0 | task -1 | sampler chain: logits -> penalties -> ?dry -> ?top-n-sigma -> top-k -> ?typical -> ?top-p -> min-p -> ?xtc -> ?temp-ext -> dist 
2026-05-15 18:05:23.525 | slot launch_slot_: id  0 | task 3220 | processing task, is_child = 0
2026-05-15 18:05:23.525 | slot update_slots: id  0 | task 3220 | new prompt, n_ctx_slot = 131072, n_keep = 0, task.n_tokens = 43384
2026-05-15 18:05:23.525 | slot update_slots: id  0 | task 3220 | n_tokens = 23394, memory_seq_rm [23394, end)
2026-05-15 18:05:23.525 | slot update_slots: id  0 | task 3220 | prompt processing progress, n_tokens = 25442, batch.n_tokens = 2048, progress = 0.586437
2026-05-15 18:05:27.305 | slot update_slots: id  0 | task 3220 | n_tokens = 25442, memory_seq_rm [25442, end)
2026-05-15 18:05:27.305 | slot update_slots: id  0 | task 3220 | prompt processing progress, n_tokens = 27490, batch.n_tokens = 2048, progress = 0.633644
2026-05-15 18:05:23.118 | slot update_slots: id  0 | task 3220 | n_tokens = 27490, memory_seq_rm [27490, end)
2026-05-15 18:05:23.118 | slot update_slots: id  0 | task 3220 | prompt processing progress, n_tokens = 29538, batch.n_tokens = 2048, progress = 0.680850
2026-05-15 18:05:24.062 | slot update_slots: id  0 | task 3220 | n_tokens = 29538, memory_seq_rm [29538, end)
2026-05-15 18:05:24.062 | slot update_slots: id  0 | task 3220 | prompt processing progress, n_tokens = 31586, batch.n_tokens = 2048, progress = 0.728056
2026-05-15 18:05:25.025 | slot update_slots: id  0 | task 3220 | n_tokens = 31586, memory_seq_rm [31586, end)
2026-05-15 18:05:25.025 | slot update_slots: id  0 | task 3220 | 8192 tokens since last checkpoint at 23192, creating new checkpoint during processing at position 33634
2026-05-15 18:05:25.025 | slot update_slots: id  0 | task 3220 | prompt processing progress, n_tokens = 33634, batch.n_tokens = 2048, progress = 0.775263
2026-05-15 18:05:25.281 | slot create_check: id  0 | task 3220 | created context checkpoint 7 of 32 (pos_min = 31585, pos_max = 31585, n_tokens = 31586, size = 215.776 MiB)
2026-05-15 18:05:26.312 | slot update_slots: id  0 | task 3220 | n_tokens = 33634, memory_seq_rm [33634, end)
2026-05-15 18:05:26.312 | slot update_slots: id  0 | task 3220 | prompt processing progress, n_tokens = 35682, batch.n_tokens = 2048, progress = 0.822469
2026-05-15 18:05:27.381 | slot update_slots: id  0 | task 3220 | n_tokens = 35682, memory_seq_rm [35682, end)
2026-05-15 18:05:27.381 | slot update_slots: id  0 | task 3220 | prompt processing progress, n_tokens = 37730, batch.n_tokens = 2048, progress = 0.869675
2026-05-15 18:05:28.461 | slot update_slots: id  0 | task 3220 | n_tokens = 37730, memory_seq_rm [37730, end)
2026-05-15 18:05:28.461 | slot update_slots: id  0 | task 3220 | prompt processing progress, n_tokens = 39778, batch.n_tokens = 2048, progress = 0.916882
2026-05-15 18:05:29.546 | slot update_slots: id  0 | task 3220 | n_tokens = 39778, memory_seq_rm [39778, end)
2026-05-15 18:05:29.546 | slot update_slots: id  0 | task 3220 | 8192 tokens since last checkpoint at 31586, creating new checkpoint during processing at position 41826
2026-05-15 18:05:29.546 | slot update_slots: id  0 | task 3220 | prompt processing progress, n_tokens = 41826, batch.n_tokens = 2048, progress = 0.964088
2026-05-15 18:05:29.820 | slot create_check: id  0 | task 3220 | created context checkpoint 8 of 32 (pos_min = 39777, pos_max = 39777, n_tokens = 39778, size = 232.932 MiB)
2026-05-15 18:05:30.899 | slot update_slots: id  0 | task 3220 | n_tokens = 41826, memory_seq_rm [41826, end)
2026-05-15 18:05:30.899 | slot update_slots: id  0 | task 3220 | prompt processing progress, n_tokens = 42868, batch.n_tokens = 1042, progress = 0.988106
2026-05-15 18:05:31.505 | slot update_slots: id  0 | task 3220 | n_tokens = 42868, memory_seq_rm [42868, end)
2026-05-15 18:05:31.505 | slot update_slots: id  0 | task 3220 | prompt processing progress, n_tokens = 43380, batch.n_tokens = 512, progress = 0.999908
2026-05-15 18:05:31.788 | slot create_check: id  0 | task 3220 | created context checkpoint 9 of 32 (pos_min = 42867, pos_max = 42867, n_tokens = 42868, size = 239.403 MiB)
2026-05-15 18:05:32.067 | slot update_slots: id  0 | task 3220 | n_tokens = 43380, memory_seq_rm [43380, end)
2026-05-15 18:05:32.073 | slot init_sampler: id  0 | task 3220 | init sampler, took 6.04 ms, tokens: text = 43384, total = 43384
2026-05-15 18:05:32.073 | slot update_slots: id  0 | task 3220 | prompt processing done, n_tokens = 43384, batch.n_tokens = 4
2026-05-15 18:05:32.356 | slot create_check: id  0 | task 3220 | created context checkpoint 10 of 32 (pos_min = 43379, pos_max = 43379, n_tokens = 43380, size = 240.476 MiB)
2026-05-15 18:05:32.395 | srv  log_server_r: done request: POST /v1/chat/completions 172.18.0.1 200
2026-05-15 18:05:32.984 | reasoning-budget: deactivated (natural end)
2026-05-15 18:05:34.192 | slot print_timing: id  0 | task 3220 | 
2026-05-15 18:05:34.192 | prompt eval time =   11181.37 ms / 19990 tokens (    0.56 ms per token,  1787.80 tokens per second)
2026-05-15 18:05:34.192 |        eval time =    1796.79 ms /   113 tokens (   15.90 ms per token,    62.89 tokens per second)
2026-05-15 18:05:34.192 |       total time =   12978.16 ms / 20103 tokens
2026-05-15 18:05:34.192 | draft acceptance rate = 0.98571 (   69 accepted /    70 generated)
2026-05-15 18:05:34.192 | statistics mtp: #calls(b,g,a) = 39 2935 2629, #gen drafts = 2629, #acc drafts = 2629, #gen tokens = 4622, #acc tokens = 4550, dur(b,g,a) = 0.056, 12714.740, 1.139 ms
2026-05-15 18:05:34.193 | slot      release: id  0 | task 3220 | stop processing: n_tokens = 43496, truncated = 0
2026-05-15 18:05:34.193 | srv  update_slots: all slots are idle
2026-05-15 18:05:38.369 | srv  params_from_: Chat format: peg-native
2026-05-15 18:05:38.371 | slot get_availabl: id  0 | task -1 | selected slot by LCP similarity, sim_best = 0.998 (> 0.100 thold), f_keep = 1.000
2026-05-15 18:05:38.373 | reasoning-budget: activated, budget=2147483647 tokens
2026-05-15 18:05:38.373 | slot launch_slot_: id  0 | task -1 | sampler chain: logits -> penalties -> ?dry -> ?top-n-sigma -> top-k -> ?typical -> ?top-p -> min-p -> ?xtc -> ?temp-ext -> dist 
2026-05-15 18:05:38.373 | slot launch_slot_: id  0 | task 3282 | processing task, is_child = 0
2026-05-15 18:05:38.373 | slot update_slots: id  0 | task 3282 | new prompt, n_ctx_slot = 131072, n_keep = 0, task.n_tokens = 43566
2026-05-15 18:05:38.373 | slot update_slots: id  0 | task 3282 | n_tokens = 43496, memory_seq_rm [43496, end)
2026-05-15 18:05:38.373 | slot update_slots: id  0 | task 3282 | prompt processing progress, n_tokens = 43562, batch.n_tokens = 66, progress = 0.999908
2026-05-15 18:05:38.651 | slot create_check: id  0 | task 3282 | created context checkpoint 11 of 32 (pos_min = 43495, pos_max = 43495, n_tokens = 43496, size = 240.718 MiB)
2026-05-15 18:05:38.725 | slot update_slots: id  0 | task 3282 | n_tokens = 43562, memory_seq_rm [43562, end)
2026-05-15 18:05:38.731 | slot init_sampler: id  0 | task 3282 | init sampler, took 6.00 ms, tokens: text = 43566, total = 43566
2026-05-15 18:05:38.731 | slot update_slots: id  0 | task 3282 | prompt processing done, n_tokens = 43566, batch.n_tokens = 4
2026-05-15 18:05:39.018 | slot create_check: id  0 | task 3282 | created context checkpoint 12 of 32 (pos_min = 43561, pos_max = 43561, n_tokens = 43562, size = 240.857 MiB)
2026-05-15 18:05:39.070 | srv  log_server_r: done request: POST /v1/chat/completions 172.18.0.1 200
2026-05-15 18:05:40.124 | reasoning-budget: deactivated (natural end)
2026-05-15 18:05:41.316 | slot print_timing: id  0 | task 3282 | 
2026-05-15 18:05:41.316 | prompt eval time =     696.43 ms /    70 tokens (    9.95 ms per token,   100.51 tokens per second)
2026-05-15 18:05:41.316 |        eval time =    2246.39 ms /   143 tokens (   15.71 ms per token,    63.66 tokens per second)
2026-05-15 18:05:41.316 |       total time =    2942.82 ms /   213 tokens
2026-05-15 18:05:41.316 | draft acceptance rate = 1.00000 (   86 accepted /    86 generated)
2026-05-15 18:05:41.316 | statistics mtp: #calls(b,g,a) = 40 2991 2677, #gen drafts = 2677, #acc drafts = 2677, #gen tokens = 4708, #acc tokens = 4636, dur(b,g,a) = 0.058, 12962.786, 1.160 ms
2026-05-15 18:05:41.317 | slot      release: id  0 | task 3282 | stop processing: n_tokens = 43708, truncated = 0
2026-05-15 18:05:41.317 | srv  update_slots: all slots are idle
2026-05-15 18:06:02.644 | srv  params_from_: Chat format: peg-native
2026-05-15 18:06:02.646 | slot get_availabl: id  0 | task -1 | selected slot by LCP similarity, sim_best = 0.991 (> 0.100 thold), f_keep = 1.000
2026-05-15 18:06:02.648 | reasoning-budget: activated, budget=2147483647 tokens
2026-05-15 18:06:02.648 | slot launch_slot_: id  0 | task -1 | sampler chain: logits -> penalties -> ?dry -> ?top-n-sigma -> top-k -> ?typical -> ?top-p -> min-p -> ?xtc -> ?temp-ext -> dist 
2026-05-15 18:06:02.648 | slot launch_slot_: id  0 | task 3344 | processing task, is_child = 0
2026-05-15 18:06:02.648 | slot update_slots: id  0 | task 3344 | new prompt, n_ctx_slot = 131072, n_keep = 0, task.n_tokens = 44086
2026-05-15 18:06:02.648 | slot update_slots: id  0 | task 3344 | n_tokens = 43708, memory_seq_rm [43708, end)
2026-05-15 18:06:02.648 | slot update_slots: id  0 | task 3344 | prompt processing progress, n_tokens = 44082, batch.n_tokens = 374, progress = 0.999909
2026-05-15 18:06:02.985 | slot create_check: id  0 | task 3344 | created context checkpoint 13 of 32 (pos_min = 43707, pos_max = 43707, n_tokens = 43708, size = 241.162 MiB)
2026-05-15 18:06:03.389 | slot update_slots: id  0 | task 3344 | n_tokens = 44082, memory_seq_rm [44082, end)
2026-05-15 18:06:03.396 | slot init_sampler: id  0 | task 3344 | init sampler, took 6.05 ms, tokens: text = 44086, total = 44086
2026-05-15 18:06:03.396 | slot update_slots: id  0 | task 3344 | prompt processing done, n_tokens = 44086, batch.n_tokens = 4
2026-05-15 18:06:03.677 | slot create_check: id  0 | task 3344 | created context checkpoint 14 of 32 (pos_min = 44081, pos_max = 44081, n_tokens = 44082, size = 241.946 MiB)
2026-05-15 18:06:03.715 | srv  log_server_r: done request: POST /v1/chat/completions 172.18.0.1 200
2026-05-15 18:06:04.404 | reasoning-budget: deactivated (natural end)
2026-05-15 18:06:05.515 | slot print_timing: id  0 | task 3344 | 
2026-05-15 18:06:05.515 | prompt eval time =    1067.17 ms /   378 tokens (    2.82 ms per token,   354.21 tokens per second)
2026-05-15 18:06:05.515 |        eval time =    1799.43 ms /   124 tokens (   14.51 ms per token,    68.91 tokens per second)
2026-05-15 18:06:05.515 |       total time =    2866.60 ms /   502 tokens
2026-05-15 18:06:05.515 | draft acceptance rate = 1.00000 (   75 accepted /    75 generated)
2026-05-15 18:06:05.515 | statistics mtp: #calls(b,g,a) = 41 3039 2718, #gen drafts = 2718, #acc drafts = 2718, #gen tokens = 4783, #acc tokens = 4711, dur(b,g,a) = 0.059, 13163.965, 1.177 ms
2026-05-15 18:06:05.516 | slot      release: id  0 | task 3344 | stop processing: n_tokens = 44209, truncated = 0
2026-05-15 18:06:05.516 | srv  update_slots: all slots are idle
2026-05-15 18:06:05.827 | srv  params_from_: Chat format: peg-native
2026-05-15 18:06:05.830 | slot get_availabl: id  0 | task -1 | selected slot by LCP similarity, sim_best = 0.997 (> 0.100 thold), f_keep = 1.000
2026-05-15 18:06:05.831 | reasoning-budget: activated, budget=2147483647 tokens
2026-05-15 18:06:05.831 | slot launch_slot_: id  0 | task -1 | sampler chain: logits -> penalties -> ?dry -> ?top-n-sigma -> top-k -> ?typical -> ?top-p -> min-p -> ?xtc -> ?temp-ext -> dist 
2026-05-15 18:06:05.831 | slot launch_slot_: id  0 | task 3395 | processing task, is_child = 0
2026-05-15 18:06:05.831 | slot update_slots: id  0 | task 3395 | new prompt, n_ctx_slot = 131072, n_keep = 0, task.n_tokens = 44322
2026-05-15 18:06:05.831 | slot update_slots: id  0 | task 3395 | n_tokens = 44209, memory_seq_rm [44209, end)
2026-05-15 18:06:05.831 | slot update_slots: id  0 | task 3395 | prompt processing progress, n_tokens = 44318, batch.n_tokens = 109, progress = 0.999910
2026-05-15 18:06:06.112 | slot create_check: id  0 | task 3395 | created context checkpoint 15 of 32 (pos_min = 44208, pos_max = 44208, n_tokens = 44209, size = 242.212 MiB)
2026-05-15 18:06:06.190 | slot update_slots: id  0 | task 3395 | n_tokens = 44318, memory_seq_rm [44318, end)
2026-05-15 18:06:06.196 | slot init_sampler: id  0 | task 3395 | init sampler, took 6.01 ms, tokens: text = 44322, total = 44322
2026-05-15 18:06:06.196 | slot update_slots: id  0 | task 3395 | prompt processing done, n_tokens = 44322, batch.n_tokens = 4
2026-05-15 18:06:06.482 | slot create_check: id  0 | task 3395 | created context checkpoint 16 of 32 (pos_min = 44317, pos_max = 44317, n_tokens = 44318, size = 242.440 MiB)
2026-05-15 18:06:06.520 | srv  log_server_r: done request: POST /v1/chat/completions 172.18.0.1 200
2026-05-15 18:06:08.493 | reasoning-budget: deactivated (natural end)
2026-05-15 18:06:09.558 | slot print_timing: id  0 | task 3395 | 
2026-05-15 18:06:09.558 | prompt eval time =     688.18 ms /   113 tokens (    6.09 ms per token,   164.20 tokens per second)
2026-05-15 18:06:09.558 |        eval time =    3037.99 ms /   183 tokens (   16.60 ms per token,    60.24 tokens per second)
2026-05-15 18:06:09.558 |       total time =    3726.17 ms /   296 tokens
2026-05-15 18:06:09.558 | draft acceptance rate = 0.99048 (  104 accepted /   105 generated)
2026-05-15 18:06:09.558 | statistics mtp: #calls(b,g,a) = 42 3117 2778, #gen drafts = 2778, #acc drafts = 2778, #gen tokens = 4888, #acc tokens = 4815, dur(b,g,a) = 0.060, 13480.665, 1.198 ms
2026-05-15 18:06:09.559 | slot      release: id  0 | task 3395 | stop processing: n_tokens = 44504, truncated = 0
2026-05-15 18:06:09.559 | srv  update_slots: all slots are idle
2026-05-15 18:06:09.747 | srv  params_from_: Chat format: peg-native
2026-05-15 18:06:09.749 | slot get_availabl: id  0 | task -1 | selected slot by LCP similarity, sim_best = 0.999 (> 0.100 thold), f_keep = 1.000
2026-05-15 18:06:09.751 | reasoning-budget: activated, budget=2147483647 tokens
2026-05-15 18:06:09.751 | slot launch_slot_: id  0 | task -1 | sampler chain: logits -> penalties -> ?dry -> ?top-n-sigma -> top-k -> ?typical -> ?top-p -> min-p -> ?xtc -> ?temp-ext -> dist 
2026-05-15 18:06:09.751 | slot launch_slot_: id  0 | task 3481 | processing task, is_child = 0
2026-05-15 18:06:09.751 | slot update_slots: id  0 | task 3481 | new prompt, n_ctx_slot = 131072, n_keep = 0, task.n_tokens = 44544
2026-05-15 18:06:09.751 | slot update_slots: id  0 | task 3481 | n_tokens = 44504, memory_seq_rm [44504, end)
2026-05-15 18:06:09.751 | slot update_slots: id  0 | task 3481 | prompt processing progress, n_tokens = 44540, batch.n_tokens = 36, progress = 0.999910
2026-05-15 18:06:10.037 | slot create_check: id  0 | task 3481 | created context checkpoint 17 of 32 (pos_min = 44503, pos_max = 44503, n_tokens = 44504, size = 242.830 MiB)
2026-05-15 18:06:10.086 | slot update_slots: id  0 | task 3481 | n_tokens = 44540, memory_seq_rm [44540, end)
2026-05-15 18:06:10.092 | slot init_sampler: id  0 | task 3481 | init sampler, took 6.13 ms, tokens: text = 44544, total = 44544
2026-05-15 18:06:10.092 | slot update_slots: id  0 | task 3481 | prompt processing done, n_tokens = 44544, batch.n_tokens = 4
2026-05-15 18:06:10.131 | srv  log_server_r: done request: POST /v1/chat/completions 172.18.0.1 200
2026-05-15 18:06:10.978 | reasoning-budget: deactivated (natural end)
2026-05-15 18:06:12.113 | slot print_timing: id  0 | task 3481 | 
2026-05-15 18:06:12.113 | prompt eval time =     379.46 ms /    40 tokens (    9.49 ms per token,   105.41 tokens per second)
2026-05-15 18:06:12.113 |        eval time =    1982.01 ms /   131 tokens (   15.13 ms per token,    66.09 tokens per second)
2026-05-15 18:06:12.113 |       total time =    2361.48 ms /   171 tokens
2026-05-15 18:06:12.113 | draft acceptance rate = 1.00000 (   76 accepted /    76 generated)
2026-05-15 18:06:12.113 | statistics mtp: #calls(b,g,a) = 43 3171 2818, #gen drafts = 2818, #acc drafts = 2818, #gen tokens = 4964, #acc tokens = 4891, dur(b,g,a) = 0.062, 13696.271, 1.207 ms
2026-05-15 18:06:12.114 | slot      release: id  0 | task 3481 | stop processing: n_tokens = 44674, truncated = 0
2026-05-15 18:06:12.114 | srv  update_slots: all slots are idle
2026-05-15 18:06:14.028 | srv  params_from_: Chat format: peg-native
2026-05-15 18:06:14.030 | slot get_availabl: id  0 | task -1 | selected slot by LCP similarity, sim_best = 0.965 (> 0.100 thold), f_keep = 1.000
2026-05-15 18:06:14.032 | reasoning-budget: activated, budget=2147483647 tokens
2026-05-15 18:06:14.032 | slot launch_slot_: id  0 | task -1 | sampler chain: logits -> penalties -> ?dry -> ?top-n-sigma -> top-k -> ?typical -> ?top-p -> min-p -> ?xtc -> ?temp-ext -> dist 
2026-05-15 18:06:14.032 | slot launch_slot_: id  0 | task 3539 | processing task, is_child = 0
2026-05-15 18:06:14.032 | slot update_slots: id  0 | task 3539 | new prompt, n_ctx_slot = 131072, n_keep = 0, task.n_tokens = 46299
2026-05-15 18:06:14.032 | slot update_slots: id  0 | task 3539 | n_tokens = 44674, memory_seq_rm [44674, end)
2026-05-15 18:06:14.032 | slot update_slots: id  0 | task 3539 | prompt processing progress, n_tokens = 45783, batch.n_tokens = 1109, progress = 0.988855
2026-05-15 18:06:14.728 | slot update_slots: id  0 | task 3539 | n_tokens = 45783, memory_seq_rm [45783, end)
2026-05-15 18:06:14.728 | slot update_slots: id  0 | task 3539 | prompt processing progress, n_tokens = 46295, batch.n_tokens = 512, progress = 0.999914
2026-05-15 18:06:15.016 | slot create_check: id  0 | task 3539 | created context checkpoint 18 of 32 (pos_min = 45782, pos_max = 45782, n_tokens = 45783, size = 245.508 MiB)
2026-05-15 18:06:15.309 | slot update_slots: id  0 | task 3539 | n_tokens = 46295, memory_seq_rm [46295, end)
2026-05-15 18:06:15.316 | slot init_sampler: id  0 | task 3539 | init sampler, took 6.45 ms, tokens: text = 46299, total = 46299
2026-05-15 18:06:15.316 | slot update_slots: id  0 | task 3539 | prompt processing done, n_tokens = 46299, batch.n_tokens = 4
2026-05-15 18:06:15.606 | slot create_check: id  0 | task 3539 | created context checkpoint 19 of 32 (pos_min = 46294, pos_max = 46294, n_tokens = 46295, size = 246.580 MiB)
2026-05-15 18:06:15.645 | srv  log_server_r: done request: POST /v1/chat/completions 172.18.0.1 200
2026-05-15 18:06:17.503 | reasoning-budget: deactivated (natural end)
2026-05-15 18:06:18.716 | slot print_timing: id  0 | task 3539 | 
2026-05-15 18:06:18.716 | prompt eval time =    1613.03 ms /  1625 tokens (    0.99 ms per token,  1007.42 tokens per second)
2026-05-15 18:06:18.716 |        eval time =    3070.68 ms /   162 tokens (   18.95 ms per token,    52.76 tokens per second)
2026-05-15 18:06:18.716 |       total time =    4683.71 ms /  1787 tokens
2026-05-15 18:06:18.716 | draft acceptance rate = 1.00000 (   83 accepted /    83 generated)
2026-05-15 18:06:18.716 | statistics mtp: #calls(b,g,a) = 44 3249 2868, #gen drafts = 2868, #acc drafts = 2868, #gen tokens = 5047, #acc tokens = 4974, dur(b,g,a) = 0.063, 13988.143, 1.224 ms
2026-05-15 18:06:18.717 | slot      release: id  0 | task 3539 | stop processing: n_tokens = 46460, truncated = 0
2026-05-15 18:06:18.717 | srv  update_slots: all slots are idle
2026-05-15 18:06:20.617 | srv  params_from_: Chat format: peg-native
2026-05-15 18:06:20.620 | slot get_availabl: id  0 | task -1 | selected slot by LCP similarity, sim_best = 0.993 (> 0.100 thold), f_keep = 1.000
2026-05-15 18:06:20.621 | reasoning-budget: activated, budget=2147483647 tokens
2026-05-15 18:06:20.621 | slot launch_slot_: id  0 | task -1 | sampler chain: logits -> penalties -> ?dry -> ?top-n-sigma -> top-k -> ?typical -> ?top-p -> min-p -> ?xtc -> ?temp-ext -> dist 
2026-05-15 18:06:20.621 | slot launch_slot_: id  0 | task 3627 | processing task, is_child = 0
2026-05-15 18:06:20.621 | slot update_slots: id  0 | task 3627 | new prompt, n_ctx_slot = 131072, n_keep = 0, task.n_tokens = 46808
2026-05-15 18:06:20.621 | slot update_slots: id  0 | task 3627 | n_tokens = 46460, memory_seq_rm [46460, end)
2026-05-15 18:06:20.622 | slot update_slots: id  0 | task 3627 | prompt processing progress, n_tokens = 46804, batch.n_tokens = 344, progress = 0.999915
2026-05-15 18:06:20.907 | slot create_check: id  0 | task 3627 | created context checkpoint 20 of 32 (pos_min = 46459, pos_max = 46459, n_tokens = 46460, size = 246.926 MiB)
2026-05-15 18:06:21.200 | slot update_slots: id  0 | task 3627 | n_tokens = 46804, memory_seq_rm [46804, end)
2026-05-15 18:06:21.206 | slot init_sampler: id  0 | task 3627 | init sampler, took 6.43 ms, tokens: text = 46808, total = 46808
2026-05-15 18:06:21.206 | slot update_slots: id  0 | task 3627 | prompt processing done, n_tokens = 46808, batch.n_tokens = 4
2026-05-15 18:06:21.499 | slot create_check: id  0 | task 3627 | created context checkpoint 21 of 32 (pos_min = 46803, pos_max = 46803, n_tokens = 46804, size = 247.646 MiB)
2026-05-15 18:06:21.540 | srv  log_server_r: done request: POST /v1/chat/completions 172.18.0.1 200
2026-05-15 18:06:28.635 | reasoning-budget: deactivated (natural end)
2026-05-15 18:06:29.889 | slot print_timing: id  0 | task 3627 | 
2026-05-15 18:06:29.889 | prompt eval time =     918.01 ms /   348 tokens (    2.64 ms per token,   379.08 tokens per second)
2026-05-15 18:06:29.889 |        eval time =    8348.85 ms /   425 tokens (   19.64 ms per token,    50.91 tokens per second)
2026-05-15 18:06:29.889 |       total time =    9266.86 ms /   773 tokens
2026-05-15 18:06:29.889 | draft acceptance rate = 0.97368 (  222 accepted /   228 generated)
2026-05-15 18:06:29.889 | statistics mtp: #calls(b,g,a) = 45 3451 2999, #gen drafts = 2999, #acc drafts = 2999, #gen tokens = 5275, #acc tokens = 5196, dur(b,g,a) = 0.064, 14767.427, 1.297 ms
2026-05-15 18:06:29.890 | slot      release: id  0 | task 3627 | stop processing: n_tokens = 47232, truncated = 0
2026-05-15 18:06:29.890 | srv  update_slots: all slots are idle
2026-05-15 18:06:30.114 | srv  params_from_: Chat format: peg-native
2026-05-15 18:06:30.117 | slot get_availabl: id  0 | task -1 | selected slot by LCP similarity, sim_best = 0.976 (> 0.100 thold), f_keep = 1.000
2026-05-15 18:06:30.119 | reasoning-budget: activated, budget=2147483647 tokens
2026-05-15 18:06:30.119 | slot launch_slot_: id  0 | task -1 | sampler chain: logits -> penalties -> ?dry -> ?top-n-sigma -> top-k -> ?typical -> ?top-p -> min-p -> ?xtc -> ?temp-ext -> dist 
2026-05-15 18:06:30.119 | slot launch_slot_: id  0 | task 3848 | processing task, is_child = 0
2026-05-15 18:06:30.119 | slot update_slots: id  0 | task 3848 | new prompt, n_ctx_slot = 131072, n_keep = 0, task.n_tokens = 48408
2026-05-15 18:06:30.119 | slot update_slots: id  0 | task 3848 | n_tokens = 47232, memory_seq_rm [47232, end)
2026-05-15 18:06:30.119 | slot update_slots: id  0 | task 3848 | prompt processing progress, n_tokens = 47892, batch.n_tokens = 660, progress = 0.989341
2026-05-15 18:06:30.564 | slot update_slots: id  0 | task 3848 | n_tokens = 47892, memory_seq_rm [47892, end)
2026-05-15 18:06:30.564 | slot update_slots: id  0 | task 3848 | prompt processing progress, n_tokens = 48404, batch.n_tokens = 512, progress = 0.999917
2026-05-15 18:06:30.857 | slot create_check: id  0 | task 3848 | created context checkpoint 22 of 32 (pos_min = 47891, pos_max = 47891, n_tokens = 47892, size = 249.925 MiB)
2026-05-15 18:06:31.172 | slot update_slots: id  0 | task 3848 | n_tokens = 48404, memory_seq_rm [48404, end)
2026-05-15 18:06:31.178 | slot init_sampler: id  0 | task 3848 | init sampler, took 6.68 ms, tokens: text = 48408, total = 48408
2026-05-15 18:06:31.178 | slot update_slots: id  0 | task 3848 | prompt processing done, n_tokens = 48408, batch.n_tokens = 4
2026-05-15 18:06:31.476 | slot create_check: id  0 | task 3848 | created context checkpoint 23 of 32 (pos_min = 48403, pos_max = 48403, n_tokens = 48404, size = 250.997 MiB)
2026-05-15 18:06:31.517 | srv  log_server_r: done request: POST /v1/chat/completions 172.18.0.1 200
2026-05-15 18:06:33.632 | reasoning-budget: deactivated (natural end)
2026-05-15 18:06:34.659 | slot print_timing: id  0 | task 3848 | 
2026-05-15 18:06:34.659 | prompt eval time =    1398.01 ms /  1176 tokens (    1.19 ms per token,   841.19 tokens per second)
2026-05-15 18:06:34.659 |        eval time =    3141.85 ms /   186 tokens (   16.89 ms per token,    59.20 tokens per second)
2026-05-15 18:06:34.659 |       total time =    4539.86 ms /  1362 tokens
2026-05-15 18:06:34.659 | draft acceptance rate = 0.98182 (  108 accepted /   110 generated)
2026-05-15 18:06:34.659 | statistics mtp: #calls(b,g,a) = 46 3528 3060, #gen drafts = 3060, #acc drafts = 3060, #gen tokens = 5385, #acc tokens = 5304, dur(b,g,a) = 0.065, 15100.641, 1.324 ms
2026-05-15 18:06:34.660 | slot      release: id  0 | task 3848 | stop processing: n_tokens = 48593, truncated = 0
2026-05-15 18:06:34.660 | srv  update_slots: all slots are idle
2026-05-15 18:06:34.858 | srv  params_from_: Chat format: peg-native
2026-05-15 18:06:34.861 | slot get_availabl: id  0 | task -1 | selected slot by LCP similarity, sim_best = 0.997 (> 0.100 thold), f_keep = 1.000
2026-05-15 18:06:34.862 | reasoning-budget: activated, budget=2147483647 tokens
2026-05-15 18:06:34.862 | slot launch_slot_: id  0 | task -1 | sampler chain: logits -> penalties -> ?dry -> ?top-n-sigma -> top-k -> ?typical -> ?top-p -> min-p -> ?xtc -> ?temp-ext -> dist 
2026-05-15 18:06:34.862 | slot launch_slot_: id  0 | task 3934 | processing task, is_child = 0
2026-05-15 18:06:34.862 | slot update_slots: id  0 | task 3934 | new prompt, n_ctx_slot = 131072, n_keep = 0, task.n_tokens = 48736
2026-05-15 18:06:34.862 | slot update_slots: id  0 | task 3934 | n_tokens = 48593, memory_seq_rm [48593, end)
2026-05-15 18:06:34.862 | slot update_slots: id  0 | task 3934 | prompt processing progress, n_tokens = 48732, batch.n_tokens = 139, progress = 0.999918
2026-05-15 18:06:35.145 | slot create_check: id  0 | task 3934 | created context checkpoint 24 of 32 (pos_min = 48592, pos_max = 48592, n_tokens = 48593, size = 251.393 MiB)
2026-05-15 18:06:35.257 | slot update_slots: id  0 | task 3934 | n_tokens = 48732, memory_seq_rm [48732, end)
2026-05-15 18:06:35.264 | slot init_sampler: id  0 | task 3934 | init sampler, took 6.80 ms, tokens: text = 48736, total = 48736
2026-05-15 18:06:35.264 | slot update_slots: id  0 | task 3934 | prompt processing done, n_tokens = 48736, batch.n_tokens = 4
2026-05-15 18:06:35.567 | slot create_check: id  0 | task 3934 | created context checkpoint 25 of 32 (pos_min = 48731, pos_max = 48731, n_tokens = 48732, size = 251.684 MiB)
2026-05-15 18:06:35.606 | srv  log_server_r: done request: POST /v1/chat/completions 172.18.0.1 200
2026-05-15 18:06:35.888 | reasoning-budget: deactivated (natural end)
2026-05-15 18:06:36.746 | slot print_timing: id  0 | task 3934 | 
2026-05-15 18:06:36.746 | prompt eval time =     742.86 ms /   143 tokens (    5.19 ms per token,   192.50 tokens per second)
2026-05-15 18:06:36.746 |        eval time =    1140.38 ms /    81 tokens (   14.08 ms per token,    71.03 tokens per second)
2026-05-15 18:06:36.746 |       total time =    1883.23 ms /   224 tokens
2026-05-15 18:06:36.746 | draft acceptance rate = 1.00000 (   50 accepted /    50 generated)
2026-05-15 18:06:36.746 | statistics mtp: #calls(b,g,a) = 47 3558 3087, #gen drafts = 3087, #acc drafts = 3087, #gen tokens = 5435, #acc tokens = 5354, dur(b,g,a) = 0.066, 15233.525, 1.341 ms
2026-05-15 18:06:36.747 | slot      release: id  0 | task 3934 | stop processing: n_tokens = 48816, truncated = 0
2026-05-15 18:06:36.747 | srv  update_slots: all slots are idle
2026-05-15 18:07:02.053 | srv  params_from_: Chat format: peg-native
2026-05-15 18:07:02.055 | slot get_availabl: id  0 | task -1 | selected slot by LCP similarity, sim_best = 0.953 (> 0.100 thold), f_keep = 1.000
2026-05-15 18:07:02.057 | reasoning-budget: activated, budget=2147483647 tokens
2026-05-15 18:07:02.057 | slot launch_slot_: id  0 | task -1 | sampler chain: logits -> penalties -> ?dry -> ?top-n-sigma -> top-k -> ?typical -> ?top-p -> min-p -> ?xtc -> ?temp-ext -> dist 
2026-05-15 18:07:02.057 | slot launch_slot_: id  0 | task 3967 | processing task, is_child = 0
2026-05-15 18:07:02.057 | slot update_slots: id  0 | task 3967 | new prompt, n_ctx_slot = 131072, n_keep = 0, task.n_tokens = 51244
2026-05-15 18:07:02.057 | slot update_slots: id  0 | task 3967 | n_tokens = 48816, memory_seq_rm [48816, end)
2026-05-15 18:07:02.057 | slot update_slots: id  0 | task 3967 | prompt processing progress, n_tokens = 50728, batch.n_tokens = 1912, progress = 0.989931
2026-05-15 18:07:03.168 | slot update_slots: id  0 | task 3967 | n_tokens = 50728, memory_seq_rm [50728, end)
2026-05-15 18:07:03.168 | slot update_slots: id  0 | task 3967 | prompt processing progress, n_tokens = 51240, batch.n_tokens = 512, progress = 0.999922
2026-05-15 18:07:03.422 | slot create_check: id  0 | task 3967 | created context checkpoint 26 of 32 (pos_min = 50727, pos_max = 50727, n_tokens = 50728, size = 255.864 MiB)
2026-05-15 18:07:03.685 | slot update_slots: id  0 | task 3967 | n_tokens = 51240, memory_seq_rm [51240, end)
2026-05-15 18:07:03.691 | slot init_sampler: id  0 | task 3967 | init sampler, took 6.25 ms, tokens: text = 51244, total = 51244
2026-05-15 18:07:03.691 | slot update_slots: id  0 | task 3967 | prompt processing done, n_tokens = 51244, batch.n_tokens = 4
2026-05-15 18:07:03.948 | slot create_check: id  0 | task 3967 | created context checkpoint 27 of 32 (pos_min = 51239, pos_max = 51239, n_tokens = 51240, size = 256.936 MiB)
2026-05-15 18:07:03.982 | srv  log_server_r: done request: POST /v1/chat/completions 172.18.0.1 200
2026-05-15 18:07:04.880 | reasoning-budget: deactivated (natural end)
2026-05-15 18:07:05.596 | slot print_timing: id  0 | task 3967 | 
2026-05-15 18:07:05.596 | prompt eval time =    1924.98 ms /  2428 tokens (    0.79 ms per token,  1261.31 tokens per second)
2026-05-15 18:07:05.596 |        eval time =    1613.69 ms /   116 tokens (   13.91 ms per token,    71.88 tokens per second)
2026-05-15 18:07:05.596 |       total time =    3538.67 ms /  2544 tokens
2026-05-15 18:07:05.596 | draft acceptance rate = 0.98551 (   68 accepted /    69 generated)
2026-05-15 18:07:05.596 | statistics mtp: #calls(b,g,a) = 48 3605 3124, #gen drafts = 3124, #acc drafts = 3124, #gen tokens = 5504, #acc tokens = 5422, dur(b,g,a) = 0.067, 15395.320, 1.348 ms
2026-05-15 18:07:05.597 | slot      release: id  0 | task 3967 | stop processing: n_tokens = 51359, truncated = 0
2026-05-15 18:07:05.597 | srv  update_slots: all slots are idle
2026-05-15 18:07:10.964 | srv  params_from_: Chat format: peg-native
2026-05-15 18:07:10.966 | slot get_availabl: id  0 | task -1 | selected slot by LCP similarity, sim_best = 0.951 (> 0.100 thold), f_keep = 1.000
2026-05-15 18:07:10.967 | reasoning-budget: activated, budget=2147483647 tokens
2026-05-15 18:07:10.967 | slot launch_slot_: id  0 | task -1 | sampler chain: logits -> penalties -> ?dry -> ?top-n-sigma -> top-k -> ?typical -> ?top-p -> min-p -> ?xtc -> ?temp-ext -> dist 
2026-05-15 18:07:10.967 | slot launch_slot_: id  0 | task 4021 | processing task, is_child = 0
2026-05-15 18:07:10.967 | slot update_slots: id  0 | task 4021 | new prompt, n_ctx_slot = 131072, n_keep = 0, task.n_tokens = 53983
2026-05-15 18:07:10.968 | slot update_slots: id  0 | task 4021 | n_tokens = 51359, memory_seq_rm [51359, end)
2026-05-15 18:07:10.968 | slot update_slots: id  0 | task 4021 | prompt processing progress, n_tokens = 53407, batch.n_tokens = 2048, progress = 0.989330
2026-05-15 18:07:12.148 | slot update_slots: id  0 | task 4021 | n_tokens = 53407, memory_seq_rm [53407, end)
2026-05-15 18:07:12.148 | slot update_slots: id  0 | task 4021 | prompt processing progress, n_tokens = 53467, batch.n_tokens = 60, progress = 0.990441
2026-05-15 18:07:12.212 | slot update_slots: id  0 | task 4021 | n_tokens = 53467, memory_seq_rm [53467, end)
2026-05-15 18:07:12.212 | slot update_slots: id  0 | task 4021 | prompt processing progress, n_tokens = 53979, batch.n_tokens = 512, progress = 0.999926
2026-05-15 18:07:12.494 | slot create_check: id  0 | task 4021 | created context checkpoint 28 of 32 (pos_min = 53466, pos_max = 53466, n_tokens = 53467, size = 261.600 MiB)
2026-05-15 18:07:12.789 | slot update_slots: id  0 | task 4021 | n_tokens = 53979, memory_seq_rm [53979, end)
2026-05-15 18:07:12.796 | slot init_sampler: id  0 | task 4021 | init sampler, took 6.93 ms, tokens: text = 53983, total = 53983
2026-05-15 18:07:12.796 | slot update_slots: id  0 | task 4021 | prompt processing done, n_tokens = 53983, batch.n_tokens = 4
2026-05-15 18:07:13.082 | slot create_check: id  0 | task 4021 | created context checkpoint 29 of 32 (pos_min = 53978, pos_max = 53978, n_tokens = 53979, size = 262.673 MiB)
2026-05-15 18:07:13.119 | srv  log_server_r: done request: POST /v1/chat/completions 172.18.0.1 200
2026-05-15 18:07:16.828 | reasoning-budget: deactivated (natural end)
2026-05-15 18:07:17.717 | slot print_timing: id  0 | task 4021 | 
2026-05-15 18:07:17.717 | prompt eval time =    2150.66 ms /  2624 tokens (    0.82 ms per token,  1220.09 tokens per second)
2026-05-15 18:07:17.717 |        eval time =    5147.12 ms /   372 tokens (   13.84 ms per token,    72.27 tokens per second)
2026-05-15 18:07:17.717 |       total time =    7297.78 ms /  2996 tokens
2026-05-15 18:07:17.717 | draft acceptance rate = 0.99556 (  224 accepted /   225 generated)
2026-05-15 18:07:17.717 | statistics mtp: #calls(b,g,a) = 49 3752 3243, #gen drafts = 3243, #acc drafts = 3243, #gen tokens = 5729, #acc tokens = 5646, dur(b,g,a) = 0.068, 15972.197, 1.402 ms
2026-05-15 18:07:17.718 | slot      release: id  0 | task 4021 | stop processing: n_tokens = 54354, truncated = 0
2026-05-15 18:07:17.718 | srv  update_slots: all slots are idle
2026-05-15 18:07:17.951 | srv  params_from_: Chat format: peg-native
2026-05-15 18:07:17.954 | slot get_availabl: id  0 | task -1 | selected slot by LCP similarity, sim_best = 1.000 (> 0.100 thold), f_keep = 1.000
2026-05-15 18:07:17.955 | reasoning-budget: activated, budget=2147483647 tokens
2026-05-15 18:07:17.955 | slot launch_slot_: id  0 | task -1 | sampler chain: logits -> penalties -> ?dry -> ?top-n-sigma -> top-k -> ?typical -> ?top-p -> min-p -> ?xtc -> ?temp-ext -> dist 
2026-05-15 18:07:17.955 | slot launch_slot_: id  0 | task 4174 | processing task, is_child = 0
2026-05-15 18:07:17.955 | slot update_slots: id  0 | task 4174 | new prompt, n_ctx_slot = 131072, n_keep = 0, task.n_tokens = 54373
2026-05-15 18:07:17.955 | slot update_slots: id  0 | task 4174 | n_tokens = 54354, memory_seq_rm [54354, end)
2026-05-15 18:07:17.955 | slot update_slots: id  0 | task 4174 | prompt processing progress, n_tokens = 54369, batch.n_tokens = 15, progress = 0.999926
2026-05-15 18:07:18.243 | slot create_check: id  0 | task 4174 | created context checkpoint 30 of 32 (pos_min = 54353, pos_max = 54353, n_tokens = 54354, size = 263.458 MiB)
2026-05-15 18:07:18.282 | slot update_slots: id  0 | task 4174 | n_tokens = 54369, memory_seq_rm [54369, end)
2026-05-15 18:07:18.289 | slot init_sampler: id  0 | task 4174 | init sampler, took 6.96 ms, tokens: text = 54373, total = 54373
2026-05-15 18:07:18.289 | slot update_slots: id  0 | task 4174 | prompt processing done, n_tokens = 54373, batch.n_tokens = 4
2026-05-15 18:07:18.326 | srv  log_server_r: done request: POST /v1/chat/completions 172.18.0.1 200
2026-05-15 18:07:18.944 | reasoning-budget: deactivated (natural end)
2026-05-15 18:07:19.875 | slot print_timing: id  0 | task 4174 | 
2026-05-15 18:07:19.875 | prompt eval time =     370.53 ms /    19 tokens (   19.50 ms per token,    51.28 tokens per second)
2026-05-15 18:07:19.875 |        eval time =    1549.23 ms /    99 tokens (   15.65 ms per token,    63.90 tokens per second)
2026-05-15 18:07:19.875 |       total time =    1919.76 ms /   118 tokens
2026-05-15 18:07:19.875 | draft acceptance rate = 0.98333 (   59 accepted /    60 generated)
2026-05-15 18:07:19.875 | statistics mtp: #calls(b,g,a) = 50 3791 3275, #gen drafts = 3275, #acc drafts = 3275, #gen tokens = 5789, #acc tokens = 5705, dur(b,g,a) = 0.069, 16128.307, 1.414 ms
2026-05-15 18:07:19.876 | slot      release: id  0 | task 4174 | stop processing: n_tokens = 54471, truncated = 0
2026-05-15 18:07:19.876 | srv  update_slots: all slots are idle
2026-05-15 18:07:20.076 | srv  params_from_: Chat format: peg-native
2026-05-15 18:07:20.079 | slot get_availabl: id  0 | task -1 | selected slot by LCP similarity, sim_best = 0.996 (> 0.100 thold), f_keep = 1.000
2026-05-15 18:07:20.080 | reasoning-budget: activated, budget=2147483647 tokens
2026-05-15 18:07:20.080 | slot launch_slot_: id  0 | task -1 | sampler chain: logits -> penalties -> ?dry -> ?top-n-sigma -> top-k -> ?typical -> ?top-p -> min-p -> ?xtc -> ?temp-ext -> dist 
2026-05-15 18:07:20.080 | slot launch_slot_: id  0 | task 4220 | processing task, is_child = 0
2026-05-15 18:07:20.080 | slot update_slots: id  0 | task 4220 | new prompt, n_ctx_slot = 131072, n_keep = 0, task.n_tokens = 54707
2026-05-15 18:07:20.080 | slot update_slots: id  0 | task 4220 | n_tokens = 54471, memory_seq_rm [54471, end)
2026-05-15 18:07:20.080 | slot update_slots: id  0 | task 4220 | prompt processing progress, n_tokens = 54703, batch.n_tokens = 232, progress = 0.999927
2026-05-15 18:07:20.364 | slot create_check: id  0 | task 4220 | created context checkpoint 31 of 32 (pos_min = 54470, pos_max = 54470, n_tokens = 54471, size = 263.703 MiB)
2026-05-15 18:07:20.522 | slot update_slots: id  0 | task 4220 | n_tokens = 54703, memory_seq_rm [54703, end)
2026-05-15 18:07:20.529 | slot init_sampler: id  0 | task 4220 | init sampler, took 6.99 ms, tokens: text = 54707, total = 54707
2026-05-15 18:07:20.530 | slot update_slots: id  0 | task 4220 | prompt processing done, n_tokens = 54707, batch.n_tokens = 4
2026-05-15 18:07:20.817 | slot create_check: id  0 | task 4220 | created context checkpoint 32 of 32 (pos_min = 54702, pos_max = 54702, n_tokens = 54703, size = 264.189 MiB)
2026-05-15 18:07:20.854 | srv  log_server_r: done request: POST /v1/chat/completions 172.18.0.1 200
2026-05-15 18:07:21.363 | reasoning-budget: deactivated (natural end)
2026-05-15 18:07:22.087 | slot print_timing: id  0 | task 4220 | 
2026-05-15 18:07:22.087 | prompt eval time =     773.61 ms /   236 tokens (    3.28 ms per token,   305.06 tokens per second)
2026-05-15 18:07:22.087 |        eval time =    1233.09 ms /    90 tokens (   13.70 ms per token,    72.99 tokens per second)
2026-05-15 18:07:22.087 |       total time =    2006.69 ms /   326 tokens
2026-05-15 18:07:22.087 | draft acceptance rate = 1.00000 (   54 accepted /    54 generated)
2026-05-15 18:07:22.087 | statistics mtp: #calls(b,g,a) = 51 3826 3305, #gen drafts = 3305, #acc drafts = 3305, #gen tokens = 5843, #acc tokens = 5759, dur(b,g,a) = 0.071, 16267.171, 1.427 ms
2026-05-15 18:07:22.088 | slot      release: id  0 | task 4220 | stop processing: n_tokens = 54796, truncated = 0
2026-05-15 18:07:22.088 | srv  update_slots: all slots are idle
2026-05-15 18:07:22.324 | srv  params_from_: Chat format: peg-native
2026-05-15 18:07:22.326 | slot get_availabl: id  0 | task -1 | selected slot by LCP similarity, sim_best = 1.000 (> 0.100 thold), f_keep = 1.000
2026-05-15 18:07:22.327 | reasoning-budget: activated, budget=2147483647 tokens
2026-05-15 18:07:22.327 | slot launch_slot_: id  0 | task -1 | sampler chain: logits -> penalties -> ?dry -> ?top-n-sigma -> top-k -> ?typical -> ?top-p -> min-p -> ?xtc -> ?temp-ext -> dist 
2026-05-15 18:07:22.327 | slot launch_slot_: id  0 | task 4258 | processing task, is_child = 0
2026-05-15 18:07:22.327 | slot update_slots: id  0 | task 4258 | new prompt, n_ctx_slot = 131072, n_keep = 0, task.n_tokens = 54815
2026-05-15 18:07:22.327 | slot update_slots: id  0 | task 4258 | n_tokens = 54796, memory_seq_rm [54796, end)
2026-05-15 18:07:22.328 | slot update_slots: id  0 | task 4258 | prompt processing progress, n_tokens = 54811, batch.n_tokens = 15, progress = 0.999927
2026-05-15 18:07:22.328 | slot create_check: id  0 | task 4258 | erasing old context checkpoint (pos_min = 8191, pos_max = 8191, n_tokens = 8192, size = 166.782 MiB)
2026-05-15 18:07:22.571 | slot create_check: id  0 | task 4258 | created context checkpoint 32 of 32 (pos_min = 54795, pos_max = 54795, n_tokens = 54796, size = 264.384 MiB)
2026-05-15 18:07:22.611 | slot update_slots: id  0 | task 4258 | n_tokens = 54811, memory_seq_rm [54811, end)
2026-05-15 18:07:22.618 | slot init_sampler: id  0 | task 4258 | init sampler, took 6.91 ms, tokens: text = 54815, total = 54815
2026-05-15 18:07:22.618 | slot update_slots: id  0 | task 4258 | prompt processing done, n_tokens = 54815, batch.n_tokens = 4
2026-05-15 18:07:22.655 | srv  log_server_r: done request: POST /v1/chat/completions 172.18.0.1 200
2026-05-15 18:07:23.034 | reasoning-budget: deactivated (natural end)
2026-05-15 18:07:23.895 | slot print_timing: id  0 | task 4258 | 
2026-05-15 18:07:23.895 | prompt eval time =     326.77 ms /    19 tokens (   17.20 ms per token,    58.14 tokens per second)
2026-05-15 18:07:23.895 |        eval time =    1240.81 ms /    92 tokens (   13.49 ms per token,    74.15 tokens per second)
2026-05-15 18:07:23.895 |       total time =    1567.58 ms /   111 tokens
2026-05-15 18:07:23.895 | draft acceptance rate = 1.00000 (   55 accepted /    55 generated)
2026-05-15 18:07:23.895 | statistics mtp: #calls(b,g,a) = 52 3862 3335, #gen drafts = 3335, #acc drafts = 3335, #gen tokens = 5898, #acc tokens = 5814, dur(b,g,a) = 0.072, 16407.744, 1.437 ms
2026-05-15 18:07:23.897 | slot      release: id  0 | task 4258 | stop processing: n_tokens = 54906, truncated = 0
2026-05-15 18:07:23.897 | srv  update_slots: all slots are idle
2026-05-15 18:07:24.133 | srv  params_from_: Chat format: peg-native
2026-05-15 18:07:24.135 | slot get_availabl: id  0 | task -1 | selected slot by LCP similarity, sim_best = 0.999 (> 0.100 thold), f_keep = 1.000
2026-05-15 18:07:24.137 | reasoning-budget: activated, budget=2147483647 tokens
2026-05-15 18:07:24.137 | slot launch_slot_: id  0 | task -1 | sampler chain: logits -> penalties -> ?dry -> ?top-n-sigma -> top-k -> ?typical -> ?top-p -> min-p -> ?xtc -> ?temp-ext -> dist 
2026-05-15 18:07:24.137 | slot launch_slot_: id  0 | task 4297 | processing task, is_child = 0
2026-05-15 18:07:24.137 | slot update_slots: id  0 | task 4297 | new prompt, n_ctx_slot = 131072, n_keep = 0, task.n_tokens = 54958
2026-05-15 18:07:24.137 | slot update_slots: id  0 | task 4297 | n_tokens = 54906, memory_seq_rm [54906, end)
2026-05-15 18:07:24.137 | slot update_slots: id  0 | task 4297 | prompt processing progress, n_tokens = 54954, batch.n_tokens = 48, progress = 0.999927
2026-05-15 18:07:24.137 | slot create_check: id  0 | task 4297 | erasing old context checkpoint (pos_min = 12235, pos_max = 12235, n_tokens = 12236, size = 175.252 MiB)
2026-05-15 18:07:24.380 | slot create_check: id  0 | task 4297 | created context checkpoint 32 of 32 (pos_min = 54905, pos_max = 54905, n_tokens = 54906, size = 264.614 MiB)
2026-05-15 18:07:24.429 | slot update_slots: id  0 | task 4297 | n_tokens = 54954, memory_seq_rm [54954, end)
2026-05-15 18:07:24.437 | slot init_sampler: id  0 | task 4297 | init sampler, took 7.04 ms, tokens: text = 54958, total = 54958
2026-05-15 18:07:24.437 | slot update_slots: id  0 | task 4297 | prompt processing done, n_tokens = 54958, batch.n_tokens = 4
2026-05-15 18:07:24.472 | srv  log_server_r: done request: POST /v1/chat/completions 172.18.0.1 200
2026-05-15 18:07:25.533 | reasoning-budget: deactivated (natural end)
2026-05-15 18:07:26.935 | slot print_timing: id  0 | task 4297 | 
2026-05-15 18:07:26.935 | prompt eval time =     335.14 ms /    52 tokens (    6.44 ms per token,   155.16 tokens per second)
2026-05-15 18:07:26.935 |        eval time =    2462.39 ms /   138 tokens (   17.84 ms per token,    56.04 tokens per second)
2026-05-15 18:07:26.935 |       total time =    2797.53 ms /   190 tokens
2026-05-15 18:07:26.935 | draft acceptance rate = 0.95122 (   78 accepted /    82 generated)
2026-05-15 18:07:26.935 | statistics mtp: #calls(b,g,a) = 53 3921 3380, #gen drafts = 3380, #acc drafts = 3380, #gen tokens = 5980, #acc tokens = 5892, dur(b,g,a) = 0.073, 16635.916, 1.453 ms
2026-05-15 18:07:26.936 | slot      release: id  0 | task 4297 | stop processing: n_tokens = 55095, truncated = 0
2026-05-15 18:07:26.936 | srv  update_slots: all slots are idle
2026-05-15 18:07:27.163 | srv  params_from_: Chat format: peg-native
2026-05-15 18:07:27.165 | slot get_availabl: id  0 | task -1 | selected slot by LCP similarity, sim_best = 1.000 (> 0.100 thold), f_keep = 1.000
2026-05-15 18:07:27.189 | reasoning-budget: activated, budget=2147483647 tokens
2026-05-15 18:07:27.189 | slot launch_slot_: id  0 | task -1 | sampler chain: logits -> penalties -> ?dry -> ?top-n-sigma -> top-k -> ?typical -> ?top-p -> min-p -> ?xtc -> ?temp-ext -> dist 
2026-05-15 18:07:27.189 | slot launch_slot_: id  0 | task 4369 | processing task, is_child = 0
2026-05-15 18:07:27.189 | slot update_slots: id  0 | task 4369 | new prompt, n_ctx_slot = 131072, n_keep = 0, task.n_tokens = 55113
2026-05-15 18:07:27.189 | slot update_slots: id  0 | task 4369 | n_tokens = 55095, memory_seq_rm [55095, end)
2026-05-15 18:07:27.189 | slot update_slots: id  0 | task 4369 | prompt processing progress, n_tokens = 55109, batch.n_tokens = 14, progress = 0.999927
2026-05-15 18:07:27.189 | slot create_check: id  0 | task 4369 | erasing old context checkpoint (pos_min = 12747, pos_max = 12747, n_tokens = 12748, size = 176.324 MiB)
2026-05-15 18:07:27.421 | slot create_check: id  0 | task 4369 | created context checkpoint 32 of 32 (pos_min = 55094, pos_max = 55094, n_tokens = 55095, size = 265.010 MiB)
2026-05-15 18:07:27.463 | slot update_slots: id  0 | task 4369 | n_tokens = 55109, memory_seq_rm [55109, end)
2026-05-15 18:07:27.470 | slot init_sampler: id  0 | task 4369 | init sampler, took 7.37 ms, tokens: text = 55113, total = 55113
2026-05-15 18:07:27.470 | slot update_slots: id  0 | task 4369 | prompt processing done, n_tokens = 55113, batch.n_tokens = 4
2026-05-15 18:07:27.509 | srv  log_server_r: done request: POST /v1/chat/completions 172.18.0.1 200
2026-05-15 18:07:27.818 | reasoning-budget: deactivated (natural end)
2026-05-15 18:07:28.739 | slot print_timing: id  0 | task 4369 | 
2026-05-15 18:07:28.739 | prompt eval time =     341.27 ms /    18 tokens (   18.96 ms per token,    52.74 tokens per second)
2026-05-15 18:07:28.739 |        eval time =    1230.83 ms /    78 tokens (   15.78 ms per token,    63.37 tokens per second)
2026-05-15 18:07:28.739 |       total time =    1572.10 ms /    96 tokens
2026-05-15 18:07:28.739 | draft acceptance rate = 1.00000 (   47 accepted /    47 generated)
2026-05-15 18:07:28.739 | statistics mtp: #calls(b,g,a) = 54 3951 3405, #gen drafts = 3405, #acc drafts = 3405, #gen tokens = 6027, #acc tokens = 5939, dur(b,g,a) = 0.074, 16761.455, 1.467 ms
2026-05-15 18:07:28.741 | slot      release: id  0 | task 4369 | stop processing: n_tokens = 55190, truncated = 0
2026-05-15 18:07:28.741 | srv  update_slots: all slots are idle
2026-05-15 18:07:28.966 | srv  params_from_: Chat format: peg-native
2026-05-15 18:07:28.969 | slot get_availabl: id  0 | task -1 | selected slot by LCP similarity, sim_best = 1.000 (> 0.100 thold), f_keep = 1.000
2026-05-15 18:07:28.970 | reasoning-budget: activated, budget=2147483647 tokens
2026-05-15 18:07:28.970 | slot launch_slot_: id  0 | task -1 | sampler chain: logits -> penalties -> ?dry -> ?top-n-sigma -> top-k -> ?typical -> ?top-p -> min-p -> ?xtc -> ?temp-ext -> dist 
2026-05-15 18:07:28.970 | slot launch_slot_: id  0 | task 4405 | processing task, is_child = 0
2026-05-15 18:07:28.970 | slot update_slots: id  0 | task 4405 | new prompt, n_ctx_slot = 131072, n_keep = 0, task.n_tokens = 55208
2026-05-15 18:07:28.970 | slot update_slots: id  0 | task 4405 | n_tokens = 55190, memory_seq_rm [55190, end)
2026-05-15 18:07:28.971 | slot update_slots: id  0 | task 4405 | prompt processing progress, n_tokens = 55204, batch.n_tokens = 14, progress = 0.999928
2026-05-15 18:07:28.971 | slot create_check: id  0 | task 4405 | erasing old context checkpoint (pos_min = 21120, pos_max = 21120, n_tokens = 21121, size = 193.859 MiB)
2026-05-15 18:07:29.205 | slot create_check: id  0 | task 4405 | created context checkpoint 32 of 32 (pos_min = 55189, pos_max = 55189, n_tokens = 55190, size = 265.209 MiB)
2026-05-15 18:07:29.245 | slot update_slots: id  0 | task 4405 | n_tokens = 55204, memory_seq_rm [55204, end)
2026-05-15 18:07:29.253 | slot init_sampler: id  0 | task 4405 | init sampler, took 7.54 ms, tokens: text = 55208, total = 55208
2026-05-15 18:07:29.253 | slot update_slots: id  0 | task 4405 | prompt processing done, n_tokens = 55208, batch.n_tokens = 4
2026-05-15 18:07:29.292 | srv  log_server_r: done request: POST /v1/chat/completions 172.18.0.1 200
2026-05-15 18:07:29.666 | reasoning-budget: deactivated (natural end)
2026-05-15 18:07:30.470 | slot print_timing: id  0 | task 4405 | 
2026-05-15 18:07:30.470 | prompt eval time =     320.93 ms /    18 tokens (   17.83 ms per token,    56.09 tokens per second)
2026-05-15 18:07:30.470 |        eval time =    1178.56 ms /    86 tokens (   13.70 ms per token,    72.97 tokens per second)
2026-05-15 18:07:30.470 |       total time =    1499.48 ms /   104 tokens
2026-05-15 18:07:30.470 | draft acceptance rate = 1.00000 (   53 accepted /    53 generated)
2026-05-15 18:07:30.470 | statistics mtp: #calls(b,g,a) = 55 3983 3433, #gen drafts = 3433, #acc drafts = 3433, #gen tokens = 6080, #acc tokens = 5992, dur(b,g,a) = 0.076, 16895.290, 1.484 ms
2026-05-15 18:07:30.471 | slot      release: id  0 | task 4405 | stop processing: n_tokens = 55293, truncated = 0
2026-05-15 18:07:30.471 | srv  update_slots: all slots are idle
2026-05-15 18:07:38.064 | srv  params_from_: Chat format: peg-native
2026-05-15 18:07:38.066 | slot get_availabl: id  0 | task -1 | selected slot by LCP similarity, sim_best = 0.987 (> 0.100 thold), f_keep = 1.000
2026-05-15 18:07:38.068 | reasoning-budget: activated, budget=2147483647 tokens
2026-05-15 18:07:38.068 | slot launch_slot_: id  0 | task -1 | sampler chain: logits -> penalties -> ?dry -> ?top-n-sigma -> top-k -> ?typical -> ?top-p -> min-p -> ?xtc -> ?temp-ext -> dist 
2026-05-15 18:07:38.068 | slot launch_slot_: id  0 | task 4440 | processing task, is_child = 0
2026-05-15 18:07:38.068 | slot update_slots: id  0 | task 4440 | new prompt, n_ctx_slot = 131072, n_keep = 0, task.n_tokens = 56046
2026-05-15 18:07:38.068 | slot update_slots: id  0 | task 4440 | n_tokens = 55293, memory_seq_rm [55293, end)
2026-05-15 18:07:38.068 | slot update_slots: id  0 | task 4440 | prompt processing progress, n_tokens = 55530, batch.n_tokens = 237, progress = 0.990793
2026-05-15 18:07:38.221 | slot update_slots: id  0 | task 4440 | n_tokens = 55530, memory_seq_rm [55530, end)
2026-05-15 18:07:38.221 | slot update_slots: id  0 | task 4440 | prompt processing progress, n_tokens = 56042, batch.n_tokens = 512, progress = 0.999929
2026-05-15 18:07:38.221 | slot create_check: id  0 | task 4440 | erasing old context checkpoint (pos_min = 22679, pos_max = 22679, n_tokens = 22680, size = 197.124 MiB)
2026-05-15 18:07:38.357 | slot create_check: id  0 | task 4440 | created context checkpoint 32 of 32 (pos_min = 55529, pos_max = 55529, n_tokens = 55530, size = 265.921 MiB)
2026-05-15 18:07:38.660 | slot update_slots: id  0 | task 4440 | n_tokens = 56042, memory_seq_rm [56042, end)
2026-05-15 18:07:38.668 | slot init_sampler: id  0 | task 4440 | init sampler, took 7.47 ms, tokens: text = 56046, total = 56046
2026-05-15 18:07:38.668 | slot update_slots: id  0 | task 4440 | prompt processing done, n_tokens = 56046, batch.n_tokens = 4
2026-05-15 18:07:38.668 | slot create_check: id  0 | task 4440 | erasing old context checkpoint (pos_min = 23191, pos_max = 23191, n_tokens = 23192, size = 198.196 MiB)
2026-05-15 18:07:38.890 | slot create_check: id  0 | task 4440 | created context checkpoint 32 of 32 (pos_min = 56041, pos_max = 56041, n_tokens = 56042, size = 266.993 MiB)
2026-05-15 18:07:38.928 | srv  log_server_r: done request: POST /v1/chat/completions 172.18.0.1 200
2026-05-15 18:07:42.219 | reasoning-budget: deactivated (natural end)
2026-05-15 18:07:43.099 | slot print_timing: id  0 | task 4440 | 
2026-05-15 18:07:43.100 | prompt eval time =     859.71 ms /   753 tokens (    1.14 ms per token,   875.87 tokens per second)
2026-05-15 18:07:43.100 |        eval time =    4171.76 ms /   249 tokens (   16.75 ms per token,    59.69 tokens per second)
2026-05-15 18:07:43.100 |       total time =    5031.48 ms /  1002 tokens
2026-05-15 18:07:43.100 | draft acceptance rate = 0.97761 (  131 accepted /   134 generated)
2026-05-15 18:07:43.100 | statistics mtp: #calls(b,g,a) = 56 4100 3510, #gen drafts = 3510, #acc drafts = 3510, #gen tokens = 6214, #acc tokens = 6123, dur(b,g,a) = 0.077, 17303.062, 1.514 ms
2026-05-15 18:07:43.101 | slot      release: id  0 | task 4440 | stop processing: n_tokens = 56294, truncated = 0
2026-05-15 18:07:43.101 | srv  update_slots: all slots are idle
2026-05-15 18:07:43.311 | srv  params_from_: Chat format: peg-native
2026-05-15 18:07:43.313 | slot get_availabl: id  0 | task -1 | selected slot by LCP similarity, sim_best = 0.989 (> 0.100 thold), f_keep = 1.000
2026-05-15 18:07:43.314 | reasoning-budget: activated, budget=2147483647 tokens
2026-05-15 18:07:43.314 | slot launch_slot_: id  0 | task -1 | sampler chain: logits -> penalties -> ?dry -> ?top-n-sigma -> top-k -> ?typical -> ?top-p -> min-p -> ?xtc -> ?temp-ext -> dist 
2026-05-15 18:07:43.314 | slot launch_slot_: id  0 | task 4570 | processing task, is_child = 0
2026-05-15 18:07:43.314 | slot update_slots: id  0 | task 4570 | new prompt, n_ctx_slot = 131072, n_keep = 0, task.n_tokens = 56942
2026-05-15 18:07:43.314 | slot update_slots: id  0 | task 4570 | n_tokens = 56294, memory_seq_rm [56294, end)
2026-05-15 18:07:43.314 | slot update_slots: id  0 | task 4570 | prompt processing progress, n_tokens = 56426, batch.n_tokens = 132, progress = 0.990938
2026-05-15 18:07:43.398 | slot update_slots: id  0 | task 4570 | n_tokens = 56426, memory_seq_rm [56426, end)
2026-05-15 18:07:43.398 | slot update_slots: id  0 | task 4570 | prompt processing progress, n_tokens = 56938, batch.n_tokens = 512, progress = 0.999930
2026-05-15 18:07:43.398 | slot create_check: id  0 | task 4570 | erasing old context checkpoint (pos_min = 31585, pos_max = 31585, n_tokens = 31586, size = 215.776 MiB)
2026-05-15 18:07:43.590 | slot create_check: id  0 | task 4570 | created context checkpoint 32 of 32 (pos_min = 56425, pos_max = 56425, n_tokens = 56426, size = 267.797 MiB)
2026-05-15 18:07:43.866 | slot update_slots: id  0 | task 4570 | n_tokens = 56938, memory_seq_rm [56938, end)
2026-05-15 18:07:43.873 | slot init_sampler: id  0 | task 4570 | init sampler, took 7.03 ms, tokens: text = 56942, total = 56942
2026-05-15 18:07:43.873 | slot update_slots: id  0 | task 4570 | prompt processing done, n_tokens = 56942, batch.n_tokens = 4
2026-05-15 18:07:43.873 | slot create_check: id  0 | task 4570 | erasing old context checkpoint (pos_min = 39777, pos_max = 39777, n_tokens = 39778, size = 232.932 MiB)
2026-05-15 18:07:44.057 | slot create_check: id  0 | task 4570 | created context checkpoint 32 of 32 (pos_min = 56937, pos_max = 56937, n_tokens = 56938, size = 268.870 MiB)
2026-05-15 18:07:44.091 | srv  log_server_r: done request: POST /v1/chat/completions 172.18.0.1 200
2026-05-15 18:07:48.852 | reasoning-budget: deactivated (natural end)
2026-05-15 18:07:49.748 | slot print_timing: id  0 | task 4570 | 
2026-05-15 18:07:49.748 | prompt eval time =     776.37 ms /   648 tokens (    1.20 ms per token,   834.66 tokens per second)
2026-05-15 18:07:49.748 |        eval time =    5905.85 ms /   402 tokens (   14.69 ms per token,    68.07 tokens per second)
2026-05-15 18:07:49.748 |       total time =    6682.22 ms /  1050 tokens
2026-05-15 18:07:49.748 | draft acceptance rate = 0.99153 (  234 accepted /   236 generated)
2026-05-15 18:07:49.748 | statistics mtp: #calls(b,g,a) = 57 4267 3637, #gen drafts = 3637, #acc drafts = 3637, #gen tokens = 6450, #acc tokens = 6357, dur(b,g,a) = 0.078, 17923.123, 1.554 ms
2026-05-15 18:07:49.749 | slot      release: id  0 | task 4570 | stop processing: n_tokens = 57343, truncated = 0
2026-05-15 18:07:49.749 | srv  update_slots: all slots are idle
2026-05-15 18:07:49.982 | srv  params_from_: Chat format: peg-native
2026-05-15 18:07:49.985 | slot get_availabl: id  0 | task -1 | selected slot by LCP similarity, sim_best = 0.939 (> 0.100 thold), f_keep = 1.000
2026-05-15 18:07:49.986 | reasoning-budget: activated, budget=2147483647 tokens
2026-05-15 18:07:49.986 | slot launch_slot_: id  0 | task -1 | sampler chain: logits -> penalties -> ?dry -> ?top-n-sigma -> top-k -> ?typical -> ?top-p -> min-p -> ?xtc -> ?temp-ext -> dist 
2026-05-15 18:07:49.986 | slot launch_slot_: id  0 | task 4747 | processing task, is_child = 0
2026-05-15 18:07:49.986 | slot update_slots: id  0 | task 4747 | new prompt, n_ctx_slot = 131072, n_keep = 0, task.n_tokens = 61038
2026-05-15 18:07:49.986 | slot update_slots: id  0 | task 4747 | n_tokens = 57343, memory_seq_rm [57343, end)
2026-05-15 18:07:49.987 | slot update_slots: id  0 | task 4747 | prompt processing progress, n_tokens = 59391, batch.n_tokens = 2048, progress = 0.973017
2026-05-15 18:07:51.236 | slot update_slots: id  0 | task 4747 | n_tokens = 59391, memory_seq_rm [59391, end)
2026-05-15 18:07:51.236 | slot update_slots: id  0 | task 4747 | prompt processing progress, n_tokens = 60522, batch.n_tokens = 1131, progress = 0.991546
2026-05-15 18:07:51.973 | slot update_slots: id  0 | task 4747 | n_tokens = 60522, memory_seq_rm [60522, end)
2026-05-15 18:07:51.973 | slot update_slots: id  0 | task 4747 | prompt processing progress, n_tokens = 61034, batch.n_tokens = 512, progress = 0.999934
2026-05-15 18:07:51.973 | slot create_check: id  0 | task 4747 | erasing old context checkpoint (pos_min = 42867, pos_max = 42867, n_tokens = 42868, size = 239.403 MiB)
2026-05-15 18:07:52.188 | slot create_check: id  0 | task 4747 | created context checkpoint 32 of 32 (pos_min = 60521, pos_max = 60521, n_tokens = 60522, size = 276.376 MiB)
2026-05-15 18:07:52.518 | slot update_slots: id  0 | task 4747 | n_tokens = 61034, memory_seq_rm [61034, end)
2026-05-15 18:07:52.526 | slot init_sampler: id  0 | task 4747 | init sampler, took 7.88 ms, tokens: text = 61038, total = 61038
2026-05-15 18:07:52.526 | slot update_slots: id  0 | task 4747 | prompt processing done, n_tokens = 61038, batch.n_tokens = 4
2026-05-15 18:07:52.526 | slot create_check: id  0 | task 4747 | erasing old context checkpoint (pos_min = 43379, pos_max = 43379, n_tokens = 43380, size = 240.476 MiB)
2026-05-15 18:07:52.752 | slot create_check: id  0 | task 4747 | created context checkpoint 32 of 32 (pos_min = 61033, pos_max = 61033, n_tokens = 61034, size = 277.448 MiB)
2026-05-15 18:07:52.791 | srv  log_server_r: done request: POST /v1/chat/completions 172.18.0.1 200
2026-05-15 18:07:57.531 | reasoning-budget: deactivated (natural end)
2026-05-15 18:07:58.420 | slot print_timing: id  0 | task 4747 | 
2026-05-15 18:07:58.420 | prompt eval time =    2804.18 ms /  3695 tokens (    0.76 ms per token,  1317.67 tokens per second)
2026-05-15 18:07:58.420 |        eval time =    5628.98 ms /   317 tokens (   17.76 ms per token,    56.32 tokens per second)
2026-05-15 18:07:58.420 |       total time =    8433.16 ms /  4012 tokens
2026-05-15 18:07:58.420 | draft acceptance rate = 0.97688 (  169 accepted /   173 generated)
2026-05-15 18:07:58.420 | statistics mtp: #calls(b,g,a) = 58 4414 3740, #gen drafts = 3740, #acc drafts = 3740, #gen tokens = 6623, #acc tokens = 6526, dur(b,g,a) = 0.079, 18478.919, 1.592 ms
2026-05-15 18:07:58.421 | slot      release: id  0 | task 4747 | stop processing: n_tokens = 61354, truncated = 0
2026-05-15 18:07:58.421 | srv  update_slots: all slots are idle
2026-05-15 18:07:58.660 | srv  params_from_: Chat format: peg-native
2026-05-15 18:07:58.663 | slot get_availabl: id  0 | task -1 | selected slot by LCP similarity, sim_best = 1.000 (> 0.100 thold), f_keep = 1.000
2026-05-15 18:07:58.664 | reasoning-budget: activated, budget=2147483647 tokens
2026-05-15 18:07:58.664 | slot launch_slot_: id  0 | task -1 | sampler chain: logits -> penalties -> ?dry -> ?top-n-sigma -> top-k -> ?typical -> ?top-p -> min-p -> ?xtc -> ?temp-ext -> dist 
2026-05-15 18:07:58.664 | slot launch_slot_: id  0 | task 4907 | processing task, is_child = 0
2026-05-15 18:07:58.664 | slot update_slots: id  0 | task 4907 | new prompt, n_ctx_slot = 131072, n_keep = 0, task.n_tokens = 61372
2026-05-15 18:07:58.664 | slot update_slots: id  0 | task 4907 | n_tokens = 61354, memory_seq_rm [61354, end)
2026-05-15 18:07:58.665 | slot update_slots: id  0 | task 4907 | prompt processing progress, n_tokens = 61368, batch.n_tokens = 14, progress = 0.999935
2026-05-15 18:07:58.665 | slot create_check: id  0 | task 4907 | erasing old context checkpoint (pos_min = 43495, pos_max = 43495, n_tokens = 43496, size = 240.718 MiB)
2026-05-15 18:07:58.889 | slot create_check: id  0 | task 4907 | created context checkpoint 32 of 32 (pos_min = 61353, pos_max = 61353, n_tokens = 61354, size = 278.118 MiB)
2026-05-15 18:07:58.930 | slot update_slots: id  0 | task 4907 | n_tokens = 61368, memory_seq_rm [61368, end)
2026-05-15 18:07:58.938 | slot init_sampler: id  0 | task 4907 | init sampler, took 8.05 ms, tokens: text = 61372, total = 61372
2026-05-15 18:07:58.938 | slot update_slots: id  0 | task 4907 | prompt processing done, n_tokens = 61372, batch.n_tokens = 4
2026-05-15 18:07:58.975 | srv  log_server_r: done request: POST /v1/chat/completions 172.18.0.1 200
2026-05-15 18:08:00.071 | reasoning-budget: deactivated (natural end)
2026-05-15 18:08:00.985 | slot print_timing: id  0 | task 4907 | 
2026-05-15 18:08:00.985 | prompt eval time =     310.20 ms /    18 tokens (   17.23 ms per token,    58.03 tokens per second)
2026-05-15 18:08:00.985 |        eval time =    2010.41 ms /   118 tokens (   17.04 ms per token,    58.69 tokens per second)
2026-05-15 18:08:00.985 |       total time =    2320.60 ms /   136 tokens
2026-05-15 18:08:00.985 | draft acceptance rate = 1.00000 (   58 accepted /    58 generated)
2026-05-15 18:08:00.985 | statistics mtp: #calls(b,g,a) = 59 4473 3774, #gen drafts = 3774, #acc drafts = 3774, #gen tokens = 6681, #acc tokens = 6584, dur(b,g,a) = 0.080, 18681.746, 1.599 ms
2026-05-15 18:08:00.987 | slot      release: id  0 | task 4907 | stop processing: n_tokens = 61489, truncated = 0
2026-05-15 18:08:00.987 | srv  update_slots: all slots are idle
2026-05-15 18:17:10.485 | srv  params_from_: Chat format: peg-native
2026-05-15 18:17:10.488 | slot get_availabl: id  0 | task -1 | selected slot by LCP similarity, sim_best = 0.207 (> 0.100 thold), f_keep = 0.202
2026-05-15 18:17:10.488 | srv  get_availabl: updating prompt cache
2026-05-15 18:17:10.491 | srv   prompt_save:  - saving prompt with length 61489, total state size = 2321.201 MiB (draft: 128.775 MiB)
2026-05-15 18:17:21.676 | srv          load:  - looking for better prompt, base f_keep = 0.202, sim = 0.207
2026-05-15 18:17:21.676 | srv        update:  - cache size limit reached, removing oldest entry (size = 1295.167 MiB)
2026-05-15 18:17:21.745 | srv        update:  - cache state: 1 prompts, 10552.470 MiB (limits: 8192.000 MiB, 131072 tokens, 131072 est)
2026-05-15 18:17:21.745 | srv        update:    - prompt 0x6487df1f3300:   61489 tokens, checkpoints: 32, 10552.470 MiB
2026-05-15 18:17:21.745 | srv  get_availabl: prompt cache update took 11252.76 ms
2026-05-15 18:17:21.746 | reasoning-budget: activated, budget=2147483647 tokens
2026-05-15 18:17:21.746 | slot launch_slot_: id  0 | task -1 | sampler chain: logits -> penalties -> ?dry -> ?top-n-sigma -> top-k -> ?typical -> ?top-p -> min-p -> ?xtc -> ?temp-ext -> dist 
2026-05-15 18:17:21.746 | slot launch_slot_: id  0 | task 4970 | processing task, is_child = 0
2026-05-15 18:17:21.746 | slot update_slots: id  0 | task 4970 | new prompt, n_ctx_slot = 131072, n_keep = 0, task.n_tokens = 59980
2026-05-15 18:17:21.746 | slot update_slots: id  0 | task 4970 | n_past = 12437, slot.prompt.tokens.size() = 61489, seq_id = 0, pos_min = 61488, n_swa = 0
2026-05-15 18:17:21.746 | slot update_slots: id  0 | task 4970 | Checking checkpoint with [61353, 61353] against 12437...
2026-05-15 18:17:21.746 | slot update_slots: id  0 | task 4970 | Checking checkpoint with [61033, 61033] against 12437...
2026-05-15 18:17:21.746 | slot update_slots: id  0 | task 4970 | Checking checkpoint with [60521, 60521] against 12437...
2026-05-15 18:17:21.746 | slot update_slots: id  0 | task 4970 | Checking checkpoint with [56937, 56937] against 12437...
2026-05-15 18:17:21.746 | slot update_slots: id  0 | task 4970 | Checking checkpoint with [56425, 56425] against 12437...
2026-05-15 18:17:21.746 | slot update_slots: id  0 | task 4970 | Checking checkpoint with [56041, 56041] against 12437...
2026-05-15 18:17:21.746 | slot update_slots: id  0 | task 4970 | Checking checkpoint with [55529, 55529] against 12437...
2026-05-15 18:17:21.746 | slot update_slots: id  0 | task 4970 | Checking checkpoint with [55189, 55189] against 12437...
2026-05-15 18:17:21.746 | slot update_slots: id  0 | task 4970 | Checking checkpoint with [55094, 55094] against 12437...
2026-05-15 18:17:21.746 | slot update_slots: id  0 | task 4970 | Checking checkpoint with [54905, 54905] against 12437...
2026-05-15 18:17:21.746 | slot update_slots: id  0 | task 4970 | Checking checkpoint with [54795, 54795] against 12437...
2026-05-15 18:17:21.747 | slot update_slots: id  0 | task 4970 | Checking checkpoint with [54702, 54702] against 12437...
2026-05-15 18:17:21.747 | slot update_slots: id  0 | task 4970 | Checking checkpoint with [54470, 54470] against 12437...
2026-05-15 18:17:21.747 | slot update_slots: id  0 | task 4970 | Checking checkpoint with [54353, 54353] against 12437...
2026-05-15 18:17:21.747 | slot update_slots: id  0 | task 4970 | Checking checkpoint with [53978, 53978] against 12437...
2026-05-15 18:17:21.747 | slot update_slots: id  0 | task 4970 | Checking checkpoint with [53466, 53466] against 12437...
2026-05-15 18:17:21.747 | slot update_slots: id  0 | task 4970 | Checking checkpoint with [51239, 51239] against 12437...
2026-05-15 18:17:21.747 | slot update_slots: id  0 | task 4970 | Checking checkpoint with [50727, 50727] against 12437...
2026-05-15 18:17:21.747 | slot update_slots: id  0 | task 4970 | Checking checkpoint with [48731, 48731] against 12437...
2026-05-15 18:17:21.747 | slot update_slots: id  0 | task 4970 | Checking checkpoint with [48592, 48592] against 12437...
2026-05-15 18:17:21.747 | slot update_slots: id  0 | task 4970 | Checking checkpoint with [48403, 48403] against 12437...
2026-05-15 18:17:21.747 | slot update_slots: id  0 | task 4970 | Checking checkpoint with [47891, 47891] against 12437...
2026-05-15 18:17:21.747 | slot update_slots: id  0 | task 4970 | Checking checkpoint with [46803, 46803] against 12437...
2026-05-15 18:17:21.747 | slot update_slots: id  0 | task 4970 | Checking checkpoint with [46459, 46459] against 12437...
2026-05-15 18:17:21.747 | slot update_slots: id  0 | task 4970 | Checking checkpoint with [46294, 46294] against 12437...
2026-05-15 18:17:21.747 | slot update_slots: id  0 | task 4970 | Checking checkpoint with [45782, 45782] against 12437...
2026-05-15 18:17:21.747 | slot update_slots: id  0 | task 4970 | Checking checkpoint with [44503, 44503] against 12437...
2026-05-15 18:17:21.747 | slot update_slots: id  0 | task 4970 | Checking checkpoint with [44317, 44317] against 12437...
2026-05-15 18:17:21.747 | slot update_slots: id  0 | task 4970 | Checking checkpoint with [44208, 44208] against 12437...
2026-05-15 18:17:21.747 | slot update_slots: id  0 | task 4970 | Checking checkpoint with [44081, 44081] against 12437...
2026-05-15 18:17:21.747 | slot update_slots: id  0 | task 4970 | Checking checkpoint with [43707, 43707] against 12437...
2026-05-15 18:17:21.747 | slot update_slots: id  0 | task 4970 | Checking checkpoint with [43561, 43561] against 12437...
2026-05-15 18:17:21.747 | slot update_slots: id  0 | task 4970 | forcing full prompt re-processing due to lack of cache data (likely due to SWA or hybrid/recurrent memory, see https://github.com/ggml-org/llama.cpp/pull/13194#issuecomment-2868343055)
2026-05-15 18:17:21.747 | slot update_slots: id  0 | task 4970 | erased invalidated context checkpoint (pos_min = 43561, pos_max = 43561, n_tokens = 43562, n_swa = 0, pos_next = 0, size = 240.857 MiB)
2026-05-15 18:17:21.760 | slot update_slots: id  0 | task 4970 | erased invalidated context checkpoint (pos_min = 43707, pos_max = 43707, n_tokens = 43708, n_swa = 0, pos_next = 0, size = 241.162 MiB)
2026-05-15 18:17:21.774 | slot update_slots: id  0 | task 4970 | erased invalidated context checkpoint (pos_min = 44081, pos_max = 44081, n_tokens = 44082, n_swa = 0, pos_next = 0, size = 241.946 MiB)
2026-05-15 18:17:21.787 | slot update_slots: id  0 | task 4970 | erased invalidated context checkpoint (pos_min = 44208, pos_max = 44208, n_tokens = 44209, n_swa = 0, pos_next = 0, size = 242.212 MiB)
2026-05-15 18:17:21.801 | slot update_slots: id  0 | task 4970 | erased invalidated context checkpoint (pos_min = 44317, pos_max = 44317, n_tokens = 44318, n_swa = 0, pos_next = 0, size = 242.440 MiB)
2026-05-15 18:17:21.814 | slot update_slots: id  0 | task 4970 | erased invalidated context checkpoint (pos_min = 44503, pos_max = 44503, n_tokens = 44504, n_swa = 0, pos_next = 0, size = 242.830 MiB)
2026-05-15 18:17:21.827 | slot update_slots: id  0 | task 4970 | erased invalidated context checkpoint (pos_min = 45782, pos_max = 45782, n_tokens = 45783, n_swa = 0, pos_next = 0, size = 245.508 MiB)
2026-05-15 18:17:21.841 | slot update_slots: id  0 | task 4970 | erased invalidated context checkpoint (pos_min = 46294, pos_max = 46294, n_tokens = 46295, n_swa = 0, pos_next = 0, size = 246.580 MiB)
2026-05-15 18:17:21.855 | slot update_slots: id  0 | task 4970 | erased invalidated context checkpoint (pos_min = 46459, pos_max = 46459, n_tokens = 46460, n_swa = 0, pos_next = 0, size = 246.926 MiB)
2026-05-15 18:17:21.869 | slot update_slots: id  0 | task 4970 | erased invalidated context checkpoint (pos_min = 46803, pos_max = 46803, n_tokens = 46804, n_swa = 0, pos_next = 0, size = 247.646 MiB)
2026-05-15 18:17:21.882 | slot update_slots: id  0 | task 4970 | erased invalidated context checkpoint (pos_min = 47891, pos_max = 47891, n_tokens = 47892, n_swa = 0, pos_next = 0, size = 249.925 MiB)
2026-05-15 18:17:21.897 | slot update_slots: id  0 | task 4970 | erased invalidated context checkpoint (pos_min = 48403, pos_max = 48403, n_tokens = 48404, n_swa = 0, pos_next = 0, size = 250.997 MiB)
2026-05-15 18:17:21.911 | slot update_slots: id  0 | task 4970 | erased invalidated context checkpoint (pos_min = 48592, pos_max = 48592, n_tokens = 48593, n_swa = 0, pos_next = 0, size = 251.393 MiB)
2026-05-15 18:17:21.925 | slot update_slots: id  0 | task 4970 | erased invalidated context checkpoint (pos_min = 48731, pos_max = 48731, n_tokens = 48732, n_swa = 0, pos_next = 0, size = 251.684 MiB)
2026-05-15 18:17:21.939 | slot update_slots: id  0 | task 4970 | erased invalidated context checkpoint (pos_min = 50727, pos_max = 50727, n_tokens = 50728, n_swa = 0, pos_next = 0, size = 255.864 MiB)
2026-05-15 18:17:21.953 | slot update_slots: id  0 | task 4970 | erased invalidated context checkpoint (pos_min = 51239, pos_max = 51239, n_tokens = 51240, n_swa = 0, pos_next = 0, size = 256.936 MiB)
2026-05-15 18:17:21.967 | slot update_slots: id  0 | task 4970 | erased invalidated context checkpoint (pos_min = 53466, pos_max = 53466, n_tokens = 53467, n_swa = 0, pos_next = 0, size = 261.600 MiB)
2026-05-15 18:17:21.981 | slot update_slots: id  0 | task 4970 | erased invalidated context checkpoint (pos_min = 53978, pos_max = 53978, n_tokens = 53979, n_swa = 0, pos_next = 0, size = 262.673 MiB)
2026-05-15 18:17:21.996 | slot update_slots: id  0 | task 4970 | erased invalidated context checkpoint (pos_min = 54353, pos_max = 54353, n_tokens = 54354, n_swa = 0, pos_next = 0, size = 263.458 MiB)
2026-05-15 18:17:22.010 | slot update_slots: id  0 | task 4970 | erased invalidated context checkpoint (pos_min = 54470, pos_max = 54470, n_tokens = 54471, n_swa = 0, pos_next = 0, size = 263.703 MiB)
2026-05-15 18:17:22.025 | slot update_slots: id  0 | task 4970 | erased invalidated context checkpoint (pos_min = 54702, pos_max = 54702, n_tokens = 54703, n_swa = 0, pos_next = 0, size = 264.189 MiB)
2026-05-15 18:17:22.040 | slot update_slots: id  0 | task 4970 | erased invalidated context checkpoint (pos_min = 54795, pos_max = 54795, n_tokens = 54796, n_swa = 0, pos_next = 0, size = 264.384 MiB)
2026-05-15 18:17:22.055 | slot update_slots: id  0 | task 4970 | erased invalidated context checkpoint (pos_min = 54905, pos_max = 54905, n_tokens = 54906, n_swa = 0, pos_next = 0, size = 264.614 MiB)
2026-05-15 18:17:22.070 | slot update_slots: id  0 | task 4970 | erased invalidated context checkpoint (pos_min = 55094, pos_max = 55094, n_tokens = 55095, n_swa = 0, pos_next = 0, size = 265.010 MiB)
2026-05-15 18:17:22.085 | slot update_slots: id  0 | task 4970 | erased invalidated context checkpoint (pos_min = 55189, pos_max = 55189, n_tokens = 55190, n_swa = 0, pos_next = 0, size = 265.209 MiB)
2026-05-15 18:17:22.100 | slot update_slots: id  0 | task 4970 | erased invalidated context checkpoint (pos_min = 55529, pos_max = 55529, n_tokens = 55530, n_swa = 0, pos_next = 0, size = 265.921 MiB)
2026-05-15 18:17:22.108 | slot update_slots: id  0 | task 4970 | erased invalidated context checkpoint (pos_min = 56041, pos_max = 56041, n_tokens = 56042, n_swa = 0, pos_next = 0, size = 266.993 MiB)
2026-05-15 18:17:22.123 | slot update_slots: id  0 | task 4970 | erased invalidated context checkpoint (pos_min = 56425, pos_max = 56425, n_tokens = 56426, n_swa = 0, pos_next = 0, size = 267.797 MiB)
2026-05-15 18:17:22.138 | slot update_slots: id  0 | task 4970 | erased invalidated context checkpoint (pos_min = 56937, pos_max = 56937, n_tokens = 56938, n_swa = 0, pos_next = 0, size = 268.870 MiB)
2026-05-15 18:17:22.153 | slot update_slots: id  0 | task 4970 | erased invalidated context checkpoint (pos_min = 60521, pos_max = 60521, n_tokens = 60522, n_swa = 0, pos_next = 0, size = 276.376 MiB)
2026-05-15 18:17:22.169 | slot update_slots: id  0 | task 4970 | erased invalidated context checkpoint (pos_min = 61033, pos_max = 61033, n_tokens = 61034, n_swa = 0, pos_next = 0, size = 277.448 MiB)
2026-05-15 18:17:22.185 | slot update_slots: id  0 | task 4970 | erased invalidated context checkpoint (pos_min = 61353, pos_max = 61353, n_tokens = 61354, n_swa = 0, pos_next = 0, size = 278.118 MiB)
2026-05-15 18:17:22.200 | slot update_slots: id  0 | task 4970 | n_tokens = 0, memory_seq_rm [0, end)
2026-05-15 18:17:22.211 | slot update_slots: id  0 | task 4970 | prompt processing progress, n_tokens = 2048, batch.n_tokens = 2048, progress = 0.034145
2026-05-15 18:17:22.944 | slot update_slots: id  0 | task 4970 | n_tokens = 2048, memory_seq_rm [2048, end)
2026-05-15 18:17:22.944 | slot update_slots: id  0 | task 4970 | prompt processing progress, n_tokens = 4096, batch.n_tokens = 2048, progress = 0.068289
2026-05-15 18:17:23.649 | slot update_slots: id  0 | task 4970 | n_tokens = 4096, memory_seq_rm [4096, end)
2026-05-15 18:17:23.649 | slot update_slots: id  0 | task 4970 | prompt processing progress, n_tokens = 6144, batch.n_tokens = 2048, progress = 0.102434
2026-05-15 18:17:24.361 | slot update_slots: id  0 | task 4970 | n_tokens = 6144, memory_seq_rm [6144, end)
2026-05-15 18:17:24.361 | slot update_slots: id  0 | task 4970 | prompt processing progress, n_tokens = 8192, batch.n_tokens = 2048, progress = 0.136579
2026-05-15 18:17:25.086 | slot update_slots: id  0 | task 4970 | n_tokens = 8192, memory_seq_rm [8192, end)
2026-05-15 18:17:25.086 | slot update_slots: id  0 | task 4970 | 8192 tokens since last checkpoint at 0, creating new checkpoint during processing at position 10240
2026-05-15 18:17:25.086 | slot update_slots: id  0 | task 4970 | prompt processing progress, n_tokens = 10240, batch.n_tokens = 2048, progress = 0.170724
2026-05-15 18:17:25.202 | slot create_check: id  0 | task 4970 | created context checkpoint 1 of 32 (pos_min = 8191, pos_max = 8191, n_tokens = 8192, size = 166.782 MiB)
2026-05-15 18:17:25.947 | slot update_slots: id  0 | task 4970 | n_tokens = 10240, memory_seq_rm [10240, end)
2026-05-15 18:17:25.947 | slot update_slots: id  0 | task 4970 | prompt processing progress, n_tokens = 12288, batch.n_tokens = 2048, progress = 0.204868
2026-05-15 18:17:26.694 | slot update_slots: id  0 | task 4970 | n_tokens = 12288, memory_seq_rm [12288, end)
2026-05-15 18:17:26.694 | slot update_slots: id  0 | task 4970 | prompt processing progress, n_tokens = 14336, batch.n_tokens = 2048, progress = 0.239013
2026-05-15 18:17:27.453 | slot update_slots: id  0 | task 4970 | n_tokens = 14336, memory_seq_rm [14336, end)
2026-05-15 18:17:27.453 | slot update_slots: id  0 | task 4970 | prompt processing progress, n_tokens = 16384, batch.n_tokens = 2048, progress = 0.273158
2026-05-15 18:17:28.223 | slot update_slots: id  0 | task 4970 | n_tokens = 16384, memory_seq_rm [16384, end)
2026-05-15 18:17:28.223 | slot update_slots: id  0 | task 4970 | 8192 tokens since last checkpoint at 8192, creating new checkpoint during processing at position 18432
2026-05-15 18:17:28.223 | slot update_slots: id  0 | task 4970 | prompt processing progress, n_tokens = 18432, batch.n_tokens = 2048, progress = 0.307302
2026-05-15 18:17:28.359 | slot create_check: id  0 | task 4970 | created context checkpoint 2 of 32 (pos_min = 16383, pos_max = 16383, n_tokens = 16384, size = 183.939 MiB)
2026-05-15 18:17:29.140 | slot update_slots: id  0 | task 4970 | n_tokens = 18432, memory_seq_rm [18432, end)
2026-05-15 18:17:29.140 | slot update_slots: id  0 | task 4970 | prompt processing progress, n_tokens = 20480, batch.n_tokens = 2048, progress = 0.341447
2026-05-15 18:17:29.937 | slot update_slots: id  0 | task 4970 | n_tokens = 20480, memory_seq_rm [20480, end)
2026-05-15 18:17:29.937 | slot update_slots: id  0 | task 4970 | prompt processing progress, n_tokens = 22528, batch.n_tokens = 2048, progress = 0.375592
2026-05-15 18:17:30.749 | slot update_slots: id  0 | task 4970 | n_tokens = 22528, memory_seq_rm [22528, end)
2026-05-15 18:17:30.749 | slot update_slots: id  0 | task 4970 | prompt processing progress, n_tokens = 24576, batch.n_tokens = 2048, progress = 0.409737
2026-05-15 18:17:31.578 | slot update_slots: id  0 | task 4970 | n_tokens = 24576, memory_seq_rm [24576, end)
2026-05-15 18:17:31.578 | slot update_slots: id  0 | task 4970 | 8192 tokens since last checkpoint at 16384, creating new checkpoint during processing at position 26624
2026-05-15 18:17:31.578 | slot update_slots: id  0 | task 4970 | prompt processing progress, n_tokens = 26624, batch.n_tokens = 2048, progress = 0.443881
2026-05-15 18:17:31.730 | slot create_check: id  0 | task 4970 | created context checkpoint 3 of 32 (pos_min = 24575, pos_max = 24575, n_tokens = 24576, size = 201.095 MiB)
2026-05-15 18:17:32.573 | slot update_slots: id  0 | task 4970 | n_tokens = 26624, memory_seq_rm [26624, end)
2026-05-15 18:17:32.573 | slot update_slots: id  0 | task 4970 | prompt processing progress, n_tokens = 28672, batch.n_tokens = 2048, progress = 0.478026
2026-05-15 18:17:33.434 | slot update_slots: id  0 | task 4970 | n_tokens = 28672, memory_seq_rm [28672, end)
2026-05-15 18:17:33.434 | slot update_slots: id  0 | task 4970 | prompt processing progress, n_tokens = 30720, batch.n_tokens = 2048, progress = 0.512171
2026-05-15 18:17:34.315 | slot update_slots: id  0 | task 4970 | n_tokens = 30720, memory_seq_rm [30720, end)
2026-05-15 18:17:34.315 | slot update_slots: id  0 | task 4970 | prompt processing progress, n_tokens = 32768, batch.n_tokens = 2048, progress = 0.546315
2026-05-15 18:17:35.217 | slot update_slots: id  0 | task 4970 | n_tokens = 32768, memory_seq_rm [32768, end)
2026-05-15 18:17:35.217 | slot update_slots: id  0 | task 4970 | 8192 tokens since last checkpoint at 24576, creating new checkpoint during processing at position 34816
2026-05-15 18:17:35.217 | slot update_slots: id  0 | task 4970 | prompt processing progress, n_tokens = 34816, batch.n_tokens = 2048, progress = 0.580460
2026-05-15 18:17:35.427 | slot create_check: id  0 | task 4970 | created context checkpoint 4 of 32 (pos_min = 32767, pos_max = 32767, n_tokens = 32768, size = 218.251 MiB)
2026-05-15 18:17:36.348 | slot update_slots: id  0 | task 4970 | n_tokens = 34816, memory_seq_rm [34816, end)
2026-05-15 18:17:36.348 | slot update_slots: id  0 | task 4970 | prompt processing progress, n_tokens = 36864, batch.n_tokens = 2048, progress = 0.614605
2026-05-15 18:17:37.293 | slot update_slots: id  0 | task 4970 | n_tokens = 36864, memory_seq_rm [36864, end)
2026-05-15 18:17:37.293 | slot update_slots: id  0 | task 4970 | prompt processing progress, n_tokens = 38912, batch.n_tokens = 2048, progress = 0.648750
2026-05-15 18:17:38.257 | slot update_slots: id  0 | task 4970 | n_tokens = 38912, memory_seq_rm [38912, end)
2026-05-15 18:17:38.257 | slot update_slots: id  0 | task 4970 | prompt processing progress, n_tokens = 40960, batch.n_tokens = 2048, progress = 0.682894
2026-05-15 18:17:39.243 | slot update_slots: id  0 | task 4970 | n_tokens = 40960, memory_seq_rm [40960, end)
2026-05-15 18:17:39.243 | slot update_slots: id  0 | task 4970 | 8192 tokens since last checkpoint at 32768, creating new checkpoint during processing at position 43008
2026-05-15 18:17:39.243 | slot update_slots: id  0 | task 4970 | prompt processing progress, n_tokens = 43008, batch.n_tokens = 2048, progress = 0.717039
2026-05-15 18:17:39.512 | slot create_check: id  0 | task 4970 | created context checkpoint 5 of 32 (pos_min = 40959, pos_max = 40959, n_tokens = 40960, size = 235.407 MiB)
2026-05-15 18:17:40.517 | slot update_slots: id  0 | task 4970 | n_tokens = 43008, memory_seq_rm [43008, end)
2026-05-15 18:17:40.517 | slot update_slots: id  0 | task 4970 | prompt processing progress, n_tokens = 45056, batch.n_tokens = 2048, progress = 0.751184
2026-05-15 18:17:41.549 | slot update_slots: id  0 | task 4970 | n_tokens = 45056, memory_seq_rm [45056, end)
2026-05-15 18:17:41.549 | slot update_slots: id  0 | task 4970 | prompt processing progress, n_tokens = 47104, batch.n_tokens = 2048, progress = 0.785328
2026-05-15 18:17:42.627 | slot update_slots: id  0 | task 4970 | n_tokens = 47104, memory_seq_rm [47104, end)
2026-05-15 18:17:42.628 | slot update_slots: id  0 | task 4970 | prompt processing progress, n_tokens = 49152, batch.n_tokens = 2048, progress = 0.819473
2026-05-15 18:17:43.788 | slot update_slots: id  0 | task 4970 | n_tokens = 49152, memory_seq_rm [49152, end)
2026-05-15 18:17:43.788 | slot update_slots: id  0 | task 4970 | 8192 tokens since last checkpoint at 40960, creating new checkpoint during processing at position 51200
2026-05-15 18:17:43.788 | slot update_slots: id  0 | task 4970 | prompt processing progress, n_tokens = 51200, batch.n_tokens = 2048, progress = 0.853618
2026-05-15 18:17:44.072 | slot create_check: id  0 | task 4970 | created context checkpoint 6 of 32 (pos_min = 49151, pos_max = 49151, n_tokens = 49152, size = 252.564 MiB)
2026-05-15 18:17:45.202 | slot update_slots: id  0 | task 4970 | n_tokens = 51200, memory_seq_rm [51200, end)
2026-05-15 18:17:45.202 | slot update_slots: id  0 | task 4970 | prompt processing progress, n_tokens = 53248, batch.n_tokens = 2048, progress = 0.887763
2026-05-15 18:17:46.365 | slot update_slots: id  0 | task 4970 | n_tokens = 53248, memory_seq_rm [53248, end)
2026-05-15 18:17:46.365 | slot update_slots: id  0 | task 4970 | prompt processing progress, n_tokens = 55296, batch.n_tokens = 2048, progress = 0.921907
2026-05-15 18:17:47.543 | slot update_slots: id  0 | task 4970 | n_tokens = 55296, memory_seq_rm [55296, end)
2026-05-15 18:17:47.543 | slot update_slots: id  0 | task 4970 | prompt processing progress, n_tokens = 57344, batch.n_tokens = 2048, progress = 0.956052
2026-05-15 18:17:48.731 | slot update_slots: id  0 | task 4970 | n_tokens = 57344, memory_seq_rm [57344, end)
2026-05-15 18:17:48.731 | slot update_slots: id  0 | task 4970 | 8192 tokens since last checkpoint at 49152, creating new checkpoint during processing at position 59392
2026-05-15 18:17:48.731 | slot update_slots: id  0 | task 4970 | prompt processing progress, n_tokens = 59392, batch.n_tokens = 2048, progress = 0.990197
2026-05-15 18:17:49.021 | slot create_check: id  0 | task 4970 | created context checkpoint 7 of 32 (pos_min = 57343, pos_max = 57343, n_tokens = 57344, size = 269.720 MiB)
2026-05-15 18:17:50.250 | slot update_slots: id  0 | task 4970 | n_tokens = 59392, memory_seq_rm [59392, end)
2026-05-15 18:17:50.250 | slot update_slots: id  0 | task 4970 | prompt processing progress, n_tokens = 59464, batch.n_tokens = 72, progress = 0.991397
2026-05-15 18:17:50.322 | slot update_slots: id  0 | task 4970 | n_tokens = 59464, memory_seq_rm [59464, end)
2026-05-15 18:17:50.322 | slot update_slots: id  0 | task 4970 | prompt processing progress, n_tokens = 59976, batch.n_tokens = 512, progress = 0.999933
2026-05-15 18:17:50.620 | slot create_check: id  0 | task 4970 | created context checkpoint 8 of 32 (pos_min = 59463, pos_max = 59463, n_tokens = 59464, size = 274.160 MiB)
2026-05-15 18:17:50.939 | slot update_slots: id  0 | task 4970 | n_tokens = 59976, memory_seq_rm [59976, end)
2026-05-15 18:17:50.947 | slot init_sampler: id  0 | task 4970 | init sampler, took 7.66 ms, tokens: text = 59980, total = 59980
2026-05-15 18:17:50.947 | slot update_slots: id  0 | task 4970 | prompt processing done, n_tokens = 59980, batch.n_tokens = 4
2026-05-15 18:17:51.244 | slot create_check: id  0 | task 4970 | created context checkpoint 9 of 32 (pos_min = 59975, pos_max = 59975, n_tokens = 59976, size = 275.232 MiB)
2026-05-15 18:17:51.282 | srv  log_server_r: done request: POST /v1/chat/completions 172.18.0.1 200
2026-05-15 18:18:06.593 | reasoning-budget: deactivated (natural end)
2026-05-15 18:18:20.190 | slot print_timing: id  0 | task 4970 | 
2026-05-15 18:18:20.191 | prompt eval time =   29529.77 ms / 59980 tokens (    0.49 ms per token,  2031.17 tokens per second)
2026-05-15 18:18:20.191 |        eval time =   28903.31 ms /  1430 tokens (   20.21 ms per token,    49.48 tokens per second)
2026-05-15 18:18:20.191 |       total time =   58433.09 ms / 61410 tokens
2026-05-15 18:18:20.191 | draft acceptance rate = 0.97110 (  672 accepted /   692 generated)
2026-05-15 18:18:20.191 | statistics mtp: #calls(b,g,a) = 60 5230 4208, #gen drafts = 4208, #acc drafts = 4208, #gen tokens = 7373, #acc tokens = 7256, dur(b,g,a) = 0.081, 21296.635, 1.758 ms
2026-05-15 18:18:20.192 | slot      release: id  0 | task 4970 | stop processing: n_tokens = 61409, truncated = 0
2026-05-15 18:18:20.192 | srv  update_slots: all slots are idle
2026-05-15 18:25:12.309 | srv  params_from_: Chat format: peg-native
2026-05-15 18:25:12.311 | slot get_availabl: id  0 | task -1 | selected slot by LCP similarity, sim_best = 0.985 (> 0.100 thold), f_keep = 0.972
2026-05-15 18:25:12.313 | reasoning-budget: activated, budget=2147483647 tokens
2026-05-15 18:25:12.313 | slot launch_slot_: id  0 | task -1 | sampler chain: logits -> penalties -> ?dry -> ?top-n-sigma -> top-k -> ?typical -> ?top-p -> min-p -> ?xtc -> ?temp-ext -> dist 
2026-05-15 18:25:12.313 | slot launch_slot_: id  0 | task 5824 | processing task, is_child = 0
2026-05-15 18:25:12.313 | slot update_slots: id  0 | task 5824 | new prompt, n_ctx_slot = 131072, n_keep = 0, task.n_tokens = 60586
2026-05-15 18:25:12.313 | slot update_slots: id  0 | task 5824 | n_past = 59665, slot.prompt.tokens.size() = 61409, seq_id = 0, pos_min = 61408, n_swa = 0
2026-05-15 18:25:12.313 | slot update_slots: id  0 | task 5824 | Checking checkpoint with [59975, 59975] against 59665...
2026-05-15 18:25:12.313 | slot update_slots: id  0 | task 5824 | Checking checkpoint with [59463, 59463] against 59665...
2026-05-15 18:25:12.419 | slot update_slots: id  0 | task 5824 | restored context checkpoint (pos_min = 59463, pos_max = 59463, n_tokens = 59464, n_past = 59464, size = 274.160 MiB)
2026-05-15 18:25:12.419 | slot update_slots: id  0 | task 5824 | erased invalidated context checkpoint (pos_min = 59975, pos_max = 59975, n_tokens = 59976, n_swa = 0, pos_next = 59464, size = 275.232 MiB)
2026-05-15 18:25:12.434 | slot update_slots: id  0 | task 5824 | n_tokens = 59464, memory_seq_rm [59464, end)
2026-05-15 18:25:12.434 | slot update_slots: id  0 | task 5824 | prompt processing progress, n_tokens = 60070, batch.n_tokens = 606, progress = 0.991483
2026-05-15 18:25:13.095 | slot update_slots: id  0 | task 5824 | n_tokens = 60070, memory_seq_rm [60070, end)
2026-05-15 18:25:13.095 | slot update_slots: id  0 | task 5824 | prompt processing progress, n_tokens = 60582, batch.n_tokens = 512, progress = 0.999934
2026-05-15 18:25:13.299 | slot create_check: id  0 | task 5824 | created context checkpoint 9 of 32 (pos_min = 60069, pos_max = 60069, n_tokens = 60070, size = 275.429 MiB)
2026-05-15 18:25:13.618 | slot update_slots: id  0 | task 5824 | n_tokens = 60582, memory_seq_rm [60582, end)
2026-05-15 18:25:13.625 | slot init_sampler: id  0 | task 5824 | init sampler, took 7.60 ms, tokens: text = 60586, total = 60586
2026-05-15 18:25:13.625 | slot update_slots: id  0 | task 5824 | prompt processing done, n_tokens = 60586, batch.n_tokens = 4
2026-05-15 18:25:13.910 | slot create_check: id  0 | task 5824 | created context checkpoint 10 of 32 (pos_min = 60581, pos_max = 60581, n_tokens = 60582, size = 276.501 MiB)
2026-05-15 18:25:13.948 | srv  log_server_r: done request: POST /v1/chat/completions 172.18.0.1 200
2026-05-15 18:25:14.369 | reasoning-budget: deactivated (natural end)
2026-05-15 18:25:14.999 | slot print_timing: id  0 | task 5824 | 
2026-05-15 18:25:14.999 | prompt eval time =    1634.67 ms /  1122 tokens (    1.46 ms per token,   686.38 tokens per second)
2026-05-15 18:25:14.999 |        eval time =    1052.74 ms /    76 tokens (   13.85 ms per token,    72.19 tokens per second)
2026-05-15 18:25:14.999 |       total time =    2687.42 ms /  1198 tokens
2026-05-15 18:25:14.999 | draft acceptance rate = 1.00000 (   47 accepted /    47 generated)
2026-05-15 18:25:14.999 | statistics mtp: #calls(b,g,a) = 61 5258 4234, #gen drafts = 4234, #acc drafts = 4234, #gen tokens = 7420, #acc tokens = 7303, dur(b,g,a) = 0.082, 21413.258, 1.766 ms
2026-05-15 18:25:15.001 | slot      release: id  0 | task 5824 | stop processing: n_tokens = 60661, truncated = 0
2026-05-15 18:25:15.001 | srv  update_slots: all slots are idle
2026-05-15 18:25:15.238 | srv  params_from_: Chat format: peg-native
2026-05-15 18:25:15.240 | slot get_availabl: id  0 | task -1 | selected slot by LCP similarity, sim_best = 1.000 (> 0.100 thold), f_keep = 1.000
2026-05-15 18:25:15.241 | reasoning-budget: activated, budget=2147483647 tokens
2026-05-15 18:25:15.241 | slot launch_slot_: id  0 | task -1 | sampler chain: logits -> penalties -> ?dry -> ?top-n-sigma -> top-k -> ?typical -> ?top-p -> min-p -> ?xtc -> ?temp-ext -> dist 
2026-05-15 18:25:15.241 | slot launch_slot_: id  0 | task 5857 | processing task, is_child = 0
2026-05-15 18:25:15.241 | slot update_slots: id  0 | task 5857 | new prompt, n_ctx_slot = 131072, n_keep = 0, task.n_tokens = 60679
2026-05-15 18:25:15.241 | slot update_slots: id  0 | task 5857 | n_tokens = 60661, memory_seq_rm [60661, end)
2026-05-15 18:25:15.242 | slot update_slots: id  0 | task 5857 | prompt processing progress, n_tokens = 60675, batch.n_tokens = 14, progress = 0.999934
2026-05-15 18:25:15.538 | slot create_check: id  0 | task 5857 | created context checkpoint 11 of 32 (pos_min = 60660, pos_max = 60660, n_tokens = 60661, size = 276.667 MiB)
2026-05-15 18:25:15.578 | slot update_slots: id  0 | task 5857 | n_tokens = 60675, memory_seq_rm [60675, end)
2026-05-15 18:25:15.586 | slot init_sampler: id  0 | task 5857 | init sampler, took 7.62 ms, tokens: text = 60679, total = 60679
2026-05-15 18:25:15.586 | slot update_slots: id  0 | task 5857 | prompt processing done, n_tokens = 60679, batch.n_tokens = 4
2026-05-15 18:25:15.626 | srv  log_server_r: done request: POST /v1/chat/completions 172.18.0.1 200
2026-05-15 18:25:16.611 | reasoning-budget: deactivated (natural end)
2026-05-15 18:25:50.295 | slot print_timing: id  0 | task 5857 | 
2026-05-15 18:25:50.296 | prompt eval time =     384.21 ms /    18 tokens (   21.34 ms per token,    46.85 tokens per second)
2026-05-15 18:25:50.296 |        eval time =   34661.60 ms /  1982 tokens (   17.49 ms per token,    57.18 tokens per second)
2026-05-15 18:25:50.296 |       total time =   35045.80 ms /  2000 tokens
2026-05-15 18:25:50.296 | draft acceptance rate = 0.97750 ( 1086 accepted /  1111 generated)
2026-05-15 18:25:50.296 | statistics mtp: #calls(b,g,a) = 62 6153 4865, #gen drafts = 4865, #acc drafts = 4865, #gen tokens = 8531, #acc tokens = 8389, dur(b,g,a) = 0.083, 24699.640, 1.994 ms
2026-05-15 18:25:50.297 | slot      release: id  0 | task 5857 | stop processing: n_tokens = 62660, truncated = 0
2026-05-15 18:25:50.297 | srv  update_slots: all slots are idle
2026-05-15 18:25:50.573 | srv  params_from_: Chat format: peg-native
2026-05-15 18:25:50.576 | slot get_availabl: id  0 | task -1 | selected slot by LCP similarity, sim_best = 1.000 (> 0.100 thold), f_keep = 1.000
2026-05-15 18:25:50.577 | reasoning-budget: activated, budget=2147483647 tokens
2026-05-15 18:25:50.577 | slot launch_slot_: id  0 | task -1 | sampler chain: logits -> penalties -> ?dry -> ?top-n-sigma -> top-k -> ?typical -> ?top-p -> min-p -> ?xtc -> ?temp-ext -> dist 
2026-05-15 18:25:50.577 | slot launch_slot_: id  0 | task 6834 | processing task, is_child = 0
2026-05-15 18:25:50.577 | slot update_slots: id  0 | task 6834 | new prompt, n_ctx_slot = 131072, n_keep = 0, task.n_tokens = 62681
2026-05-15 18:25:50.577 | slot update_slots: id  0 | task 6834 | n_tokens = 62660, memory_seq_rm [62660, end)
2026-05-15 18:25:50.577 | slot update_slots: id  0 | task 6834 | prompt processing progress, n_tokens = 62677, batch.n_tokens = 17, progress = 0.999936
2026-05-15 18:25:50.898 | slot create_check: id  0 | task 6834 | created context checkpoint 12 of 32 (pos_min = 62659, pos_max = 62659, n_tokens = 62660, size = 280.853 MiB)
2026-05-15 18:25:50.940 | slot update_slots: id  0 | task 6834 | n_tokens = 62677, memory_seq_rm [62677, end)
2026-05-15 18:25:50.948 | slot init_sampler: id  0 | task 6834 | init sampler, took 7.94 ms, tokens: text = 62681, total = 62681
2026-05-15 18:25:50.948 | slot update_slots: id  0 | task 6834 | prompt processing done, n_tokens = 62681, batch.n_tokens = 4
2026-05-15 18:25:50.985 | srv  log_server_r: done request: POST /v1/chat/completions 172.18.0.1 200
2026-05-15 18:25:51.437 | reasoning-budget: deactivated (natural end)
2026-05-15 18:25:55.103 | slot print_timing: id  0 | task 6834 | 
2026-05-15 18:25:55.103 | prompt eval time =     407.59 ms /    21 tokens (   19.41 ms per token,    51.52 tokens per second)
2026-05-15 18:25:55.103 |        eval time =    4118.26 ms /   198 tokens (   20.80 ms per token,    48.08 tokens per second)
2026-05-15 18:25:55.103 |       total time =    4525.85 ms /   219 tokens
2026-05-15 18:25:55.103 | draft acceptance rate = 0.96703 (   88 accepted /    91 generated)
2026-05-15 18:25:55.103 | statistics mtp: #calls(b,g,a) = 63 6262 4923, #gen drafts = 4923, #acc drafts = 4923, #gen tokens = 8622, #acc tokens = 8477, dur(b,g,a) = 0.084, 25069.478, 2.018 ms
2026-05-15 18:25:55.105 | slot      release: id  0 | task 6834 | stop processing: n_tokens = 62878, truncated = 0
2026-05-15 18:25:55.105 | srv  update_slots: all slots are idle
2026-05-15 18:42:49.981 | srv  params_from_: Chat format: peg-native
2026-05-15 18:42:49.983 | slot get_availabl: id  0 | task -1 | selected slot by LCP similarity, sim_best = 0.941 (> 0.100 thold), f_keep = 0.963
2026-05-15 18:42:49.985 | reasoning-budget: activated, budget=2147483647 tokens
2026-05-15 18:42:49.985 | slot launch_slot_: id  0 | task -1 | sampler chain: logits -> penalties -> ?dry -> ?top-n-sigma -> top-k -> ?typical -> ?top-p -> min-p -> ?xtc -> ?temp-ext -> dist 
2026-05-15 18:42:49.985 | slot launch_slot_: id  0 | task 6955 | processing task, is_child = 0
2026-05-15 18:42:49.985 | slot update_slots: id  0 | task 6955 | new prompt, n_ctx_slot = 131072, n_keep = 0, task.n_tokens = 64335
2026-05-15 18:42:49.985 | slot update_slots: id  0 | task 6955 | n_past = 60524, slot.prompt.tokens.size() = 62878, seq_id = 0, pos_min = 62877, n_swa = 0
2026-05-15 18:42:49.985 | slot update_slots: id  0 | task 6955 | Checking checkpoint with [62659, 62659] against 60524...
2026-05-15 18:42:49.985 | slot update_slots: id  0 | task 6955 | Checking checkpoint with [60660, 60660] against 60524...
2026-05-15 18:42:49.985 | slot update_slots: id  0 | task 6955 | Checking checkpoint with [60581, 60581] against 60524...
2026-05-15 18:42:49.985 | slot update_slots: id  0 | task 6955 | Checking checkpoint with [60069, 60069] against 60524...
2026-05-15 18:42:50.092 | slot update_slots: id  0 | task 6955 | restored context checkpoint (pos_min = 60069, pos_max = 60069, n_tokens = 60070, n_past = 60070, size = 275.429 MiB)
2026-05-15 18:42:50.092 | slot update_slots: id  0 | task 6955 | erased invalidated context checkpoint (pos_min = 60581, pos_max = 60581, n_tokens = 60582, n_swa = 0, pos_next = 60070, size = 276.501 MiB)
2026-05-15 18:42:50.108 | slot update_slots: id  0 | task 6955 | erased invalidated context checkpoint (pos_min = 60660, pos_max = 60660, n_tokens = 60661, n_swa = 0, pos_next = 60070, size = 276.667 MiB)
2026-05-15 18:42:50.124 | slot update_slots: id  0 | task 6955 | erased invalidated context checkpoint (pos_min = 62659, pos_max = 62659, n_tokens = 62660, n_swa = 0, pos_next = 60070, size = 280.853 MiB)
2026-05-15 18:42:50.140 | slot update_slots: id  0 | task 6955 | n_tokens = 60070, memory_seq_rm [60070, end)
2026-05-15 18:42:50.141 | slot update_slots: id  0 | task 6955 | prompt processing progress, n_tokens = 62118, batch.n_tokens = 2048, progress = 0.965540
2026-05-15 18:42:51.591 | slot update_slots: id  0 | task 6955 | n_tokens = 62118, memory_seq_rm [62118, end)
2026-05-15 18:42:51.591 | slot update_slots: id  0 | task 6955 | prompt processing progress, n_tokens = 63819, batch.n_tokens = 1701, progress = 0.991979
2026-05-15 18:42:52.688 | slot update_slots: id  0 | task 6955 | n_tokens = 63819, memory_seq_rm [63819, end)
2026-05-15 18:42:52.688 | slot update_slots: id  0 | task 6955 | prompt processing progress, n_tokens = 64331, batch.n_tokens = 512, progress = 0.999938
2026-05-15 18:42:52.918 | slot create_check: id  0 | task 6955 | created context checkpoint 10 of 32 (pos_min = 63818, pos_max = 63818, n_tokens = 63819, size = 283.280 MiB)
2026-05-15 18:42:53.251 | slot update_slots: id  0 | task 6955 | n_tokens = 64331, memory_seq_rm [64331, end)
2026-05-15 18:42:53.259 | slot init_sampler: id  0 | task 6955 | init sampler, took 8.06 ms, tokens: text = 64335, total = 64335
2026-05-15 18:42:53.259 | slot update_slots: id  0 | task 6955 | prompt processing done, n_tokens = 64335, batch.n_tokens = 4
2026-05-15 18:42:53.566 | slot create_check: id  0 | task 6955 | created context checkpoint 11 of 32 (pos_min = 64330, pos_max = 64330, n_tokens = 64331, size = 284.353 MiB)
2026-05-15 18:42:53.604 | srv  log_server_r: done request: POST /v1/chat/completions 172.18.0.1 200
2026-05-15 18:42:54.388 | reasoning-budget: deactivated (natural end)
2026-05-15 18:42:57.775 | srv  params_from_: Chat format: peg-native
2026-05-15 18:42:57.793 | slot get_availabl: id  3 | task -1 | selected slot by LRU, t_last = 1392429582
2026-05-15 18:42:57.793 | srv  get_availabl: updating prompt cache
2026-05-15 18:42:57.793 | srv          load:  - looking for better prompt, base f_keep = -1.000, sim = 0.000
2026-05-15 18:42:57.793 | srv        update:  - cache state: 1 prompts, 10552.470 MiB (limits: 8192.000 MiB, 131072 tokens, 131072 est)
2026-05-15 18:42:57.793 | srv        update:    - prompt 0x6487df1f3300:   61489 tokens, checkpoints: 32, 10552.470 MiB
2026-05-15 18:42:57.793 | srv  get_availabl: prompt cache update took 0.02 ms
2026-05-15 18:42:57.794 | reasoning-budget: activated, budget=2147483647 tokens
2026-05-15 18:42:57.794 | slot launch_slot_: id  3 | task -1 | sampler chain: logits -> penalties -> ?dry -> ?top-n-sigma -> top-k -> ?typical -> ?top-p -> min-p -> ?xtc -> ?temp-ext -> dist 
2026-05-15 18:42:57.794 | slot launch_slot_: id  3 | task 7072 | processing task, is_child = 0
2026-05-15 18:42:57.801 | slot update_slots: id  3 | task 7072 | new prompt, n_ctx_slot = 131072, n_keep = 0, task.n_tokens = 4619
2026-05-15 18:42:57.801 | slot update_slots: id  3 | task 7072 | erased invalidated context checkpoint (pos_min = 386, pos_max = 386, n_tokens = 387, n_swa = 0, pos_next = 0, size = 150.437 MiB)
2026-05-15 18:42:57.809 | slot update_slots: id  3 | task 7072 | erased invalidated context checkpoint (pos_min = 898, pos_max = 898, n_tokens = 899, n_swa = 0, pos_next = 0, size = 151.509 MiB)
2026-05-15 18:42:57.818 | slot update_slots: id  3 | task 7072 | n_tokens = 0, memory_seq_rm [0, end)
2026-05-15 18:42:57.818 | slot update_slots: id  3 | task 7072 | prompt processing progress, n_tokens = 2045, batch.n_tokens = 2048, progress = 0.442737
2026-05-15 18:42:59.193 | slot update_slots: id  3 | task 7072 | n_tokens = 2045, memory_seq_rm [2045, end)
2026-05-15 18:42:59.193 | slot update_slots: id  3 | task 7072 | prompt processing progress, n_tokens = 4090, batch.n_tokens = 2048, progress = 0.885473
2026-05-15 18:43:00.608 | slot update_slots: id  3 | task 7072 | n_tokens = 4090, memory_seq_rm [4090, end)
2026-05-15 18:43:00.608 | slot update_slots: id  3 | task 7072 | prompt processing progress, n_tokens = 4103, batch.n_tokens = 16, progress = 0.888287
2026-05-15 18:43:00.693 | slot update_slots: id  3 | task 7072 | n_tokens = 4103, memory_seq_rm [4103, end)
2026-05-15 18:43:00.693 | slot update_slots: id  3 | task 7072 | prompt processing progress, n_tokens = 4615, batch.n_tokens = 515, progress = 0.999134
2026-05-15 18:43:00.856 | slot create_check: id  3 | task 7072 | created context checkpoint 1 of 32 (pos_min = 4102, pos_max = 4102, n_tokens = 4103, size = 158.219 MiB)
2026-05-15 18:43:01.259 | slot update_slots: id  3 | task 7072 | n_tokens = 4615, memory_seq_rm [4615, end)
2026-05-15 18:43:01.260 | slot init_sampler: id  3 | task 7072 | init sampler, took 0.64 ms, tokens: text = 4619, total = 4619
2026-05-15 18:43:01.260 | slot update_slots: id  3 | task 7072 | prompt processing done, n_tokens = 4619, batch.n_tokens = 7
2026-05-15 18:43:01.424 | slot create_check: id  3 | task 7072 | created context checkpoint 2 of 32 (pos_min = 4614, pos_max = 4614, n_tokens = 4615, size = 159.291 MiB)
2026-05-15 18:43:01.495 | srv  log_server_r: done request: POST /v1/chat/completions 172.18.0.1 200
2026-05-15 18:43:03.562 | reasoning-budget: deactivated (natural end)
2026-05-15 18:43:07.405 | srv  params_from_: Chat format: peg-native
2026-05-15 18:43:07.427 | slot print_timing: id  0 | task 6955 | 
2026-05-15 18:43:07.427 | prompt eval time =    3618.46 ms /  4265 tokens (    0.85 ms per token,  1178.68 tokens per second)
2026-05-15 18:43:07.427 |        eval time =   13823.50 ms /   433 tokens (   31.92 ms per token,    31.32 tokens per second)
2026-05-15 18:43:07.427 |       total time =   17441.96 ms /  4698 tokens
2026-05-15 18:43:07.427 | draft acceptance rate = 0.98400 (  246 accepted /   250 generated)
2026-05-15 18:43:07.427 | statistics mtp: #calls(b,g,a) = 65 6449 5129, #gen drafts = 5130, #acc drafts = 5129, #gen tokens = 8987, #acc tokens = 8834, dur(b,g,a) = 0.086, 25925.456, 2.093 ms
2026-05-15 18:43:07.429 | slot      release: id  0 | task 6955 | stop processing: n_tokens = 64767, truncated = 0
2026-05-15 18:43:07.432 | slot get_availabl: id  0 | task -1 | selected slot by LCP similarity, sim_best = 0.565 (> 0.100 thold), f_keep = 0.040
2026-05-15 18:43:07.432 | srv  get_availabl: updating prompt cache
2026-05-15 18:43:07.435 | srv   prompt_save:  - saving prompt with length 64767, total state size = 2436.968 MiB (draft: 135.640 MiB)
2026-05-15 18:43:12.793 | srv          load:  - looking for better prompt, base f_keep = 0.040, sim = 0.565
2026-05-15 18:43:12.793 | srv        update:  - cache size limit reached, removing oldest entry (size = 10552.470 MiB)
2026-05-15 18:43:13.400 | srv        update:  - cache state: 1 prompts, 5081.948 MiB (limits: 8192.000 MiB, 131072 tokens, 131072 est)
2026-05-15 18:43:13.400 | srv        update:    - prompt 0x6487e6082f70:   64767 tokens, checkpoints: 11,  5081.948 MiB
2026-05-15 18:43:13.400 | srv  get_availabl: prompt cache update took 5967.52 ms
2026-05-15 18:43:13.401 | reasoning-budget: activated, budget=2147483647 tokens
2026-05-15 18:43:13.401 | slot launch_slot_: id  0 | task -1 | sampler chain: logits -> penalties -> ?dry -> ?top-n-sigma -> top-k -> ?typical -> ?top-p -> min-p -> ?xtc -> ?temp-ext -> dist 
2026-05-15 18:43:13.401 | slot launch_slot_: id  0 | task 7155 | processing task, is_child = 0
2026-05-15 18:43:13.410 | slot update_slots: id  0 | task 7155 | new prompt, n_ctx_slot = 131072, n_keep = 0, task.n_tokens = 4605
2026-05-15 18:43:13.410 | slot update_slots: id  0 | task 7155 | n_past = 2601, slot.prompt.tokens.size() = 64767, seq_id = 0, pos_min = 64766, n_swa = 0
2026-05-15 18:43:13.410 | slot update_slots: id  0 | task 7155 | Checking checkpoint with [64330, 64330] against 2601...
2026-05-15 18:43:13.410 | slot update_slots: id  0 | task 7155 | Checking checkpoint with [63818, 63818] against 2601...
2026-05-15 18:43:13.410 | slot update_slots: id  0 | task 7155 | Checking checkpoint with [60069, 60069] against 2601...
2026-05-15 18:43:13.410 | slot update_slots: id  0 | task 7155 | Checking checkpoint with [59463, 59463] against 2601...
2026-05-15 18:43:13.410 | slot update_slots: id  0 | task 7155 | Checking checkpoint with [57343, 57343] against 2601...
2026-05-15 18:43:13.410 | slot update_slots: id  0 | task 7155 | Checking checkpoint with [49151, 49151] against 2601...
2026-05-15 18:43:13.410 | slot update_slots: id  0 | task 7155 | Checking checkpoint with [40959, 40959] against 2601...
2026-05-15 18:43:13.410 | slot update_slots: id  0 | task 7155 | Checking checkpoint with [32767, 32767] against 2601...
2026-05-15 18:43:13.410 | slot update_slots: id  0 | task 7155 | Checking checkpoint with [24575, 24575] against 2601...
2026-05-15 18:43:13.410 | slot update_slots: id  0 | task 7155 | Checking checkpoint with [16383, 16383] against 2601...
2026-05-15 18:43:13.410 | slot update_slots: id  0 | task 7155 | Checking checkpoint with [8191, 8191] against 2601...
2026-05-15 18:43:13.410 | slot update_slots: id  0 | task 7155 | forcing full prompt re-processing due to lack of cache data (likely due to SWA or hybrid/recurrent memory, see https://github.com/ggml-org/llama.cpp/pull/13194#issuecomment-2868343055)
2026-05-15 18:43:13.410 | slot update_slots: id  0 | task 7155 | erased invalidated context checkpoint (pos_min = 8191, pos_max = 8191, n_tokens = 8192, n_swa = 0, pos_next = 0, size = 166.782 MiB)
2026-05-15 18:43:13.421 | slot update_slots: id  0 | task 7155 | erased invalidated context checkpoint (pos_min = 16383, pos_max = 16383, n_tokens = 16384, n_swa = 0, pos_next = 0, size = 183.939 MiB)
2026-05-15 18:43:13.432 | slot update_slots: id  0 | task 7155 | erased invalidated context checkpoint (pos_min = 24575, pos_max = 24575, n_tokens = 24576, n_swa = 0, pos_next = 0, size = 201.095 MiB)
2026-05-15 18:43:13.444 | slot update_slots: id  0 | task 7155 | erased invalidated context checkpoint (pos_min = 32767, pos_max = 32767, n_tokens = 32768, n_swa = 0, pos_next = 0, size = 218.251 MiB)
2026-05-15 18:43:13.456 | slot update_slots: id  0 | task 7155 | erased invalidated context checkpoint (pos_min = 40959, pos_max = 40959, n_tokens = 40960, n_swa = 0, pos_next = 0, size = 235.407 MiB)
2026-05-15 18:43:13.470 | slot update_slots: id  0 | task 7155 | erased invalidated context checkpoint (pos_min = 49151, pos_max = 49151, n_tokens = 49152, n_swa = 0, pos_next = 0, size = 252.564 MiB)
2026-05-15 18:43:13.484 | slot update_slots: id  0 | task 7155 | erased invalidated context checkpoint (pos_min = 57343, pos_max = 57343, n_tokens = 57344, n_swa = 0, pos_next = 0, size = 269.720 MiB)
2026-05-15 18:43:13.500 | slot update_slots: id  0 | task 7155 | erased invalidated context checkpoint (pos_min = 59463, pos_max = 59463, n_tokens = 59464, n_swa = 0, pos_next = 0, size = 274.160 MiB)
2026-05-15 18:43:13.515 | slot update_slots: id  0 | task 7155 | erased invalidated context checkpoint (pos_min = 60069, pos_max = 60069, n_tokens = 60070, n_swa = 0, pos_next = 0, size = 275.429 MiB)
2026-05-15 18:43:13.531 | slot update_slots: id  0 | task 7155 | erased invalidated context checkpoint (pos_min = 63818, pos_max = 63818, n_tokens = 63819, n_swa = 0, pos_next = 0, size = 283.280 MiB)
2026-05-15 18:43:13.549 | slot update_slots: id  0 | task 7155 | erased invalidated context checkpoint (pos_min = 64330, pos_max = 64330, n_tokens = 64331, n_swa = 0, pos_next = 0, size = 284.353 MiB)
2026-05-15 18:43:13.565 | slot update_slots: id  0 | task 7155 | n_tokens = 0, memory_seq_rm [0, end)
2026-05-15 18:43:13.575 | slot update_slots: id  0 | task 7155 | prompt processing progress, n_tokens = 2045, batch.n_tokens = 2048, progress = 0.444083
2026-05-15 18:43:15.150 | slot update_slots: id  0 | task 7155 | n_tokens = 2045, memory_seq_rm [2045, end)
2026-05-15 18:43:15.151 | slot update_slots: id  0 | task 7155 | prompt processing progress, n_tokens = 4089, batch.n_tokens = 2047, progress = 0.887948
2026-05-15 18:43:16.589 | slot update_slots: id  0 | task 7155 | n_tokens = 4089, memory_seq_rm [4089, end)
2026-05-15 18:43:16.589 | slot update_slots: id  0 | task 7155 | prompt processing progress, n_tokens = 4601, batch.n_tokens = 515, progress = 0.999131
2026-05-15 18:43:16.709 | slot create_check: id  0 | task 7155 | created context checkpoint 1 of 32 (pos_min = 4088, pos_max = 4088, n_tokens = 4089, size = 158.190 MiB)
2026-05-15 18:43:17.114 | slot update_slots: id  0 | task 7155 | n_tokens = 4601, memory_seq_rm [4601, end)
2026-05-15 18:43:17.115 | slot init_sampler: id  0 | task 7155 | init sampler, took 0.62 ms, tokens: text = 4605, total = 4605
2026-05-15 18:43:17.115 | slot update_slots: id  0 | task 7155 | prompt processing done, n_tokens = 4605, batch.n_tokens = 7
2026-05-15 18:43:17.231 | slot create_check: id  0 | task 7155 | created context checkpoint 2 of 32 (pos_min = 4600, pos_max = 4600, n_tokens = 4601, size = 159.262 MiB)
2026-05-15 18:43:17.303 | srv  log_server_r: done request: POST /v1/chat/completions 172.18.0.1 200
2026-05-15 18:43:20.549 | reasoning-budget: deactivated (natural end)
2026-05-15 18:43:27.524 | slot print_timing: id  0 | task 7155 | 
2026-05-15 18:43:27.524 | prompt eval time =    3868.53 ms /  4605 tokens (    0.84 ms per token,  1190.37 tokens per second)
2026-05-15 18:43:27.524 |        eval time =   10220.93 ms /   320 tokens (   31.94 ms per token,    31.31 tokens per second)
2026-05-15 18:43:27.524 |       total time =   14089.47 ms /  4925 tokens
2026-05-15 18:43:27.524 | draft acceptance rate = 0.99512 (  204 accepted /   205 generated)
2026-05-15 18:43:27.524 | statistics mtp: #calls(b,g,a) = 66 6574 5347, #gen drafts = 5348, #acc drafts = 5347, #gen tokens = 9399, #acc tokens = 9244, dur(b,g,a) = 0.088, 26634.939, 2.180 ms
2026-05-15 18:43:27.524 | slot      release: id  0 | task 7155 | stop processing: n_tokens = 4924, truncated = 0
2026-05-15 18:43:27.650 | srv  params_from_: Chat format: peg-native
2026-05-15 18:43:27.688 | slot get_availabl: id  0 | task -1 | selected slot by LCP similarity, sim_best = 0.704 (> 0.100 thold), f_keep = 1.000
2026-05-15 18:43:27.689 | reasoning-budget: activated, budget=2147483647 tokens
2026-05-15 18:43:27.690 | slot launch_slot_: id  0 | task -1 | sampler chain: logits -> penalties -> ?dry -> ?top-n-sigma -> top-k -> ?typical -> ?top-p -> min-p -> ?xtc -> ?temp-ext -> dist 
2026-05-15 18:43:27.690 | slot launch_slot_: id  0 | task 7285 | processing task, is_child = 0
2026-05-15 18:43:27.697 | slot update_slots: id  0 | task 7285 | new prompt, n_ctx_slot = 131072, n_keep = 0, task.n_tokens = 6992
2026-05-15 18:43:27.697 | slot update_slots: id  0 | task 7285 | n_tokens = 4924, memory_seq_rm [4924, end)
2026-05-15 18:43:27.697 | slot update_slots: id  0 | task 7285 | prompt processing progress, n_tokens = 6476, batch.n_tokens = 1555, progress = 0.926201
2026-05-15 18:43:28.837 | slot update_slots: id  0 | task 7285 | n_tokens = 6476, memory_seq_rm [6476, end)
2026-05-15 18:43:28.837 | slot update_slots: id  0 | task 7285 | prompt processing progress, n_tokens = 6988, batch.n_tokens = 515, progress = 0.999428
2026-05-15 18:43:28.967 | slot create_check: id  0 | task 7285 | created context checkpoint 3 of 32 (pos_min = 6475, pos_max = 6475, n_tokens = 6476, size = 163.189 MiB)
2026-05-15 18:43:29.370 | slot print_timing: id  3 | task 7072 | 
2026-05-15 18:43:29.370 | prompt eval time =    3693.72 ms /  4619 tokens (    0.80 ms per token,  1250.50 tokens per second)
2026-05-15 18:43:29.370 |        eval time =   27851.07 ms /   531 tokens (   52.45 ms per token,    19.07 tokens per second)
2026-05-15 18:43:29.370 |       total time =   31544.79 ms /  5150 tokens
2026-05-15 18:43:29.370 | draft acceptance rate = 0.99102 (  331 accepted /   334 generated)
2026-05-15 18:43:29.370 | statistics mtp: #calls(b,g,a) = 66 6580 5354, #gen drafts = 5354, #acc drafts = 5354, #gen tokens = 9411, #acc tokens = 9258, dur(b,g,a) = 0.088, 26664.262, 2.181 ms
2026-05-15 18:43:29.370 | slot      release: id  3 | task 7072 | stop processing: n_tokens = 5149, truncated = 0
2026-05-15 18:43:29.370 | slot update_slots: id  0 | task 7285 | n_tokens = 6988, memory_seq_rm [6988, end)
2026-05-15 18:43:29.371 | slot init_sampler: id  0 | task 7285 | init sampler, took 0.93 ms, tokens: text = 6992, total = 6992
2026-05-15 18:43:29.371 | slot update_slots: id  0 | task 7285 | prompt processing done, n_tokens = 6992, batch.n_tokens = 4
2026-05-15 18:43:29.502 | slot create_check: id  0 | task 7285 | created context checkpoint 4 of 32 (pos_min = 6987, pos_max = 6987, n_tokens = 6988, size = 164.261 MiB)
2026-05-15 18:43:29.511 | srv  params_from_: Chat format: peg-native
2026-05-15 18:43:29.543 | slot get_availabl: id  3 | task -1 | selected slot by LCP similarity, sim_best = 0.859 (> 0.100 thold), f_keep = 1.000
2026-05-15 18:43:29.543 | srv  log_server_r: done request: POST /v1/chat/completions 172.18.0.1 200
2026-05-15 18:43:29.544 | reasoning-budget: activated, budget=2147483647 tokens
2026-05-15 18:43:29.544 | slot launch_slot_: id  3 | task -1 | sampler chain: logits -> penalties -> ?dry -> ?top-n-sigma -> top-k -> ?typical -> ?top-p -> min-p -> ?xtc -> ?temp-ext -> dist 
2026-05-15 18:43:29.544 | slot launch_slot_: id  3 | task 7290 | processing task, is_child = 0
2026-05-15 18:43:29.552 | slot update_slots: id  3 | task 7290 | new prompt, n_ctx_slot = 131072, n_keep = 0, task.n_tokens = 5997
2026-05-15 18:43:29.552 | slot update_slots: id  3 | task 7290 | n_tokens = 5149, memory_seq_rm [5149, end)
2026-05-15 18:43:29.552 | slot update_slots: id  3 | task 7290 | prompt processing progress, n_tokens = 5481, batch.n_tokens = 335, progress = 0.913957
2026-05-15 18:43:29.785 | slot update_slots: id  3 | task 7290 | n_tokens = 5481, memory_seq_rm [5481, end)
2026-05-15 18:43:29.785 | slot update_slots: id  3 | task 7290 | prompt processing progress, n_tokens = 5993, batch.n_tokens = 514, progress = 0.999333
2026-05-15 18:43:29.919 | slot create_check: id  3 | task 7290 | created context checkpoint 3 of 32 (pos_min = 5480, pos_max = 5480, n_tokens = 5481, size = 161.105 MiB)
2026-05-15 18:43:30.321 | slot update_slots: id  3 | task 7290 | n_tokens = 5993, memory_seq_rm [5993, end)
2026-05-15 18:43:30.321 | slot init_sampler: id  3 | task 7290 | init sampler, took 0.82 ms, tokens: text = 5997, total = 5997
2026-05-15 18:43:30.321 | slot update_slots: id  3 | task 7290 | prompt processing done, n_tokens = 5997, batch.n_tokens = 6
2026-05-15 18:43:30.454 | slot create_check: id  3 | task 7290 | created context checkpoint 4 of 32 (pos_min = 5992, pos_max = 5992, n_tokens = 5993, size = 162.177 MiB)
2026-05-15 18:43:30.522 | srv  log_server_r: done request: POST /v1/chat/completions 172.18.0.1 200
2026-05-15 18:43:32.854 | reasoning-budget: deactivated (natural end)
2026-05-15 18:43:33.096 | reasoning-budget: deactivated (natural end)
2026-05-15 18:43:38.556 | slot print_timing: id  0 | task 7285 | 
2026-05-15 18:43:38.556 | prompt eval time =    1845.39 ms /  2068 tokens (    0.89 ms per token,  1120.63 tokens per second)
2026-05-15 18:43:38.556 |        eval time =    9013.01 ms /   267 tokens (   33.76 ms per token,    29.62 tokens per second)
2026-05-15 18:43:38.556 |       total time =   10858.40 ms /  2335 tokens
2026-05-15 18:43:38.556 | draft acceptance rate = 0.99405 (  167 accepted /   168 generated)
2026-05-15 18:43:38.556 | statistics mtp: #calls(b,g,a) = 68 6681 5525, #gen drafts = 5526, #acc drafts = 5525, #gen tokens = 9739, #acc tokens = 9582, dur(b,g,a) = 0.091, 27186.802, 2.233 ms
2026-05-15 18:43:38.556 | slot      release: id  0 | task 7285 | stop processing: n_tokens = 7258, truncated = 0
2026-05-15 18:43:38.717 | srv  params_from_: Chat format: peg-native
2026-05-15 18:43:38.753 | slot get_availabl: id  0 | task -1 | selected slot by LCP similarity, sim_best = 0.254 (> 0.100 thold), f_keep = 1.000
2026-05-15 18:43:38.754 | reasoning-budget: activated, budget=2147483647 tokens
2026-05-15 18:43:38.754 | slot launch_slot_: id  0 | task -1 | sampler chain: logits -> penalties -> ?dry -> ?top-n-sigma -> top-k -> ?typical -> ?top-p -> min-p -> ?xtc -> ?temp-ext -> dist 
2026-05-15 18:43:38.754 | slot launch_slot_: id  0 | task 7399 | processing task, is_child = 0
2026-05-15 18:43:38.762 | slot update_slots: id  0 | task 7399 | new prompt, n_ctx_slot = 131072, n_keep = 0, task.n_tokens = 28526
2026-05-15 18:43:38.762 | slot update_slots: id  0 | task 7399 | n_tokens = 7258, memory_seq_rm [7258, end)
2026-05-15 18:43:38.762 | slot update_slots: id  0 | task 7399 | prompt processing progress, n_tokens = 9303, batch.n_tokens = 2048, progress = 0.326124
2026-05-15 18:43:40.214 | slot update_slots: id  0 | task 7399 | n_tokens = 9303, memory_seq_rm [9303, end)
2026-05-15 18:43:40.214 | slot update_slots: id  0 | task 7399 | prompt processing progress, n_tokens = 11348, batch.n_tokens = 2048, progress = 0.397813
2026-05-15 18:43:41.654 | slot update_slots: id  0 | task 7399 | n_tokens = 11348, memory_seq_rm [11348, end)
2026-05-15 18:43:41.655 | slot update_slots: id  0 | task 7399 | prompt processing progress, n_tokens = 13393, batch.n_tokens = 2048, progress = 0.469501
2026-05-15 18:43:43.095 | slot update_slots: id  0 | task 7399 | n_tokens = 13393, memory_seq_rm [13393, end)
2026-05-15 18:43:43.095 | slot update_slots: id  0 | task 7399 | prompt processing progress, n_tokens = 15438, batch.n_tokens = 2048, progress = 0.541191
2026-05-15 18:43:44.552 | slot update_slots: id  0 | task 7399 | n_tokens = 15438, memory_seq_rm [15438, end)
2026-05-15 18:43:44.552 | slot update_slots: id  0 | task 7399 | 8192 tokens since last checkpoint at 6988, creating new checkpoint during processing at position 17483
2026-05-15 18:43:44.552 | slot update_slots: id  0 | task 7399 | prompt processing progress, n_tokens = 17483, batch.n_tokens = 2048, progress = 0.612879
2026-05-15 18:43:44.687 | slot create_check: id  0 | task 7399 | created context checkpoint 5 of 32 (pos_min = 15437, pos_max = 15437, n_tokens = 15438, size = 181.957 MiB)
2026-05-15 18:43:46.181 | slot update_slots: id  0 | task 7399 | n_tokens = 17483, memory_seq_rm [17483, end)
2026-05-15 18:43:46.181 | slot update_slots: id  0 | task 7399 | prompt processing progress, n_tokens = 19528, batch.n_tokens = 2048, progress = 0.684568
2026-05-15 18:43:47.645 | slot update_slots: id  0 | task 7399 | n_tokens = 19528, memory_seq_rm [19528, end)
2026-05-15 18:43:47.645 | slot update_slots: id  0 | task 7399 | prompt processing progress, n_tokens = 21574, batch.n_tokens = 2048, progress = 0.756293
2026-05-15 18:43:49.143 | slot update_slots: id  0 | task 7399 | n_tokens = 21574, memory_seq_rm [21574, end)
2026-05-15 18:43:49.144 | slot update_slots: id  0 | task 7399 | prompt processing progress, n_tokens = 23621, batch.n_tokens = 2048, progress = 0.828052
2026-05-15 18:43:50.584 | slot update_slots: id  0 | task 7399 | n_tokens = 23621, memory_seq_rm [23621, end)
2026-05-15 18:43:50.585 | slot update_slots: id  0 | task 7399 | prompt processing progress, n_tokens = 25668, batch.n_tokens = 2048, progress = 0.899811
2026-05-15 18:43:52.029 | slot update_slots: id  0 | task 7399 | n_tokens = 25668, memory_seq_rm [25668, end)
2026-05-15 18:43:52.029 | slot update_slots: id  0 | task 7399 | 8192 tokens since last checkpoint at 15438, creating new checkpoint during processing at position 27715
2026-05-15 18:43:52.029 | slot update_slots: id  0 | task 7399 | prompt processing progress, n_tokens = 27715, batch.n_tokens = 2048, progress = 0.971570
2026-05-15 18:43:52.233 | slot create_check: id  0 | task 7399 | created context checkpoint 6 of 32 (pos_min = 25667, pos_max = 25667, n_tokens = 25668, size = 203.382 MiB)
2026-05-15 18:43:53.670 | slot update_slots: id  0 | task 7399 | n_tokens = 27715, memory_seq_rm [27715, end)
2026-05-15 18:43:53.670 | slot update_slots: id  0 | task 7399 | prompt processing progress, n_tokens = 28010, batch.n_tokens = 296, progress = 0.981911
2026-05-15 18:43:53.930 | slot update_slots: id  0 | task 7399 | n_tokens = 28010, memory_seq_rm [28010, end)
2026-05-15 18:43:53.930 | slot update_slots: id  0 | task 7399 | prompt processing progress, n_tokens = 28522, batch.n_tokens = 513, progress = 0.999860
2026-05-15 18:43:54.176 | slot create_check: id  0 | task 7399 | created context checkpoint 7 of 32 (pos_min = 28009, pos_max = 28009, n_tokens = 28010, size = 208.287 MiB)
2026-05-15 18:43:54.571 | slot update_slots: id  0 | task 7399 | n_tokens = 28522, memory_seq_rm [28522, end)
2026-05-15 18:43:54.575 | slot init_sampler: id  0 | task 7399 | init sampler, took 3.62 ms, tokens: text = 28526, total = 28526
2026-05-15 18:43:54.575 | slot update_slots: id  0 | task 7399 | prompt processing done, n_tokens = 28526, batch.n_tokens = 5
2026-05-15 18:43:54.818 | slot create_check: id  0 | task 7399 | created context checkpoint 8 of 32 (pos_min = 28521, pos_max = 28521, n_tokens = 28522, size = 209.359 MiB)
2026-05-15 18:43:54.882 | srv  log_server_r: done request: POST /v1/chat/completions 172.18.0.1 200
2026-05-15 18:43:57.939 | reasoning-budget: deactivated (natural end)
2026-05-15 18:43:58.720 | slot print_timing: id  3 | task 7290 | 
2026-05-15 18:43:58.720 | prompt eval time =     969.83 ms /   848 tokens (    1.14 ms per token,   874.38 tokens per second)
2026-05-15 18:43:58.720 |        eval time =   28176.59 ms /   415 tokens (   67.90 ms per token,    14.73 tokens per second)
2026-05-15 18:43:58.720 |       total time =   29146.42 ms /  1263 tokens
2026-05-15 18:43:58.720 | draft acceptance rate = 0.98833 (  254 accepted /   257 generated)
2026-05-15 18:43:58.720 | statistics mtp: #calls(b,g,a) = 69 6748 5600, #gen drafts = 5600, #acc drafts = 5600, #gen tokens = 9873, #acc tokens = 9714, dur(b,g,a) = 0.092, 27654.777, 2.262 ms
2026-05-15 18:43:58.720 | slot      release: id  3 | task 7290 | stop processing: n_tokens = 6411, truncated = 0
2026-05-15 18:43:58.911 | srv  params_from_: Chat format: peg-native
2026-05-15 18:43:58.923 | slot get_availabl: id  3 | task -1 | selected slot by LCP similarity, sim_best = 0.195 (> 0.100 thold), f_keep = 1.000
2026-05-15 18:43:58.924 | reasoning-budget: activated, budget=2147483647 tokens
2026-05-15 18:43:58.924 | slot launch_slot_: id  3 | task -1 | sampler chain: logits -> penalties -> ?dry -> ?top-n-sigma -> top-k -> ?typical -> ?top-p -> min-p -> ?xtc -> ?temp-ext -> dist 
2026-05-15 18:43:58.924 | slot launch_slot_: id  3 | task 7469 | processing task, is_child = 0
2026-05-15 18:43:58.932 | slot update_slots: id  3 | task 7469 | new prompt, n_ctx_slot = 131072, n_keep = 0, task.n_tokens = 32880
2026-05-15 18:43:58.932 | slot update_slots: id  3 | task 7469 | n_tokens = 6411, memory_seq_rm [6411, end)
2026-05-15 18:43:58.932 | slot update_slots: id  3 | task 7469 | prompt processing progress, n_tokens = 8456, batch.n_tokens = 2048, progress = 0.257178
2026-05-15 18:44:00.371 | slot update_slots: id  3 | task 7469 | n_tokens = 8456, memory_seq_rm [8456, end)
2026-05-15 18:44:00.371 | slot update_slots: id  3 | task 7469 | prompt processing progress, n_tokens = 10501, batch.n_tokens = 2048, progress = 0.319373
2026-05-15 18:44:01.821 | slot update_slots: id  3 | task 7469 | n_tokens = 10501, memory_seq_rm [10501, end)
2026-05-15 18:44:01.821 | slot update_slots: id  3 | task 7469 | prompt processing progress, n_tokens = 12546, batch.n_tokens = 2048, progress = 0.381569
2026-05-15 18:44:03.298 | slot update_slots: id  3 | task 7469 | n_tokens = 12546, memory_seq_rm [12546, end)
2026-05-15 18:44:03.298 | slot update_slots: id  3 | task 7469 | prompt processing progress, n_tokens = 14591, batch.n_tokens = 2048, progress = 0.443765
2026-05-15 18:44:04.759 | slot update_slots: id  3 | task 7469 | n_tokens = 14591, memory_seq_rm [14591, end)
2026-05-15 18:44:04.759 | slot update_slots: id  3 | task 7469 | 8192 tokens since last checkpoint at 5993, creating new checkpoint during processing at position 16636
2026-05-15 18:44:04.759 | slot update_slots: id  3 | task 7469 | prompt processing progress, n_tokens = 16636, batch.n_tokens = 2048, progress = 0.505961
2026-05-15 18:44:04.948 | slot create_check: id  3 | task 7469 | created context checkpoint 5 of 32 (pos_min = 14590, pos_max = 14590, n_tokens = 14591, size = 180.184 MiB)
2026-05-15 18:44:06.420 | slot update_slots: id  3 | task 7469 | n_tokens = 16636, memory_seq_rm [16636, end)
2026-05-15 18:44:06.420 | slot update_slots: id  3 | task 7469 | prompt processing progress, n_tokens = 18681, batch.n_tokens = 2048, progress = 0.568157
2026-05-15 18:44:07.863 | slot update_slots: id  3 | task 7469 | n_tokens = 18681, memory_seq_rm [18681, end)
2026-05-15 18:44:07.863 | slot update_slots: id  3 | task 7469 | prompt processing progress, n_tokens = 20726, batch.n_tokens = 2048, progress = 0.630353
2026-05-15 18:44:09.315 | slot update_slots: id  3 | task 7469 | n_tokens = 20726, memory_seq_rm [20726, end)
2026-05-15 18:44:09.315 | slot update_slots: id  3 | task 7469 | prompt processing progress, n_tokens = 22771, batch.n_tokens = 2048, progress = 0.692549
2026-05-15 18:44:10.758 | slot update_slots: id  3 | task 7469 | n_tokens = 22771, memory_seq_rm [22771, end)
2026-05-15 18:44:10.758 | slot update_slots: id  3 | task 7469 | prompt processing progress, n_tokens = 24816, batch.n_tokens = 2048, progress = 0.754745
2026-05-15 18:44:12.199 | slot update_slots: id  3 | task 7469 | n_tokens = 24816, memory_seq_rm [24816, end)
2026-05-15 18:44:12.199 | slot update_slots: id  3 | task 7469 | 8192 tokens since last checkpoint at 14591, creating new checkpoint during processing at position 26861
2026-05-15 18:44:12.199 | slot update_slots: id  3 | task 7469 | prompt processing progress, n_tokens = 26861, batch.n_tokens = 2048, progress = 0.816940
2026-05-15 18:44:12.444 | slot create_check: id  3 | task 7469 | created context checkpoint 6 of 32 (pos_min = 24815, pos_max = 24815, n_tokens = 24816, size = 201.598 MiB)
2026-05-15 18:44:13.889 | slot update_slots: id  3 | task 7469 | n_tokens = 26861, memory_seq_rm [26861, end)
2026-05-15 18:44:13.889 | slot update_slots: id  3 | task 7469 | prompt processing progress, n_tokens = 28906, batch.n_tokens = 2048, progress = 0.879136
2026-05-15 18:44:15.366 | slot update_slots: id  3 | task 7469 | n_tokens = 28906, memory_seq_rm [28906, end)
2026-05-15 18:44:15.366 | slot update_slots: id  3 | task 7469 | prompt processing progress, n_tokens = 30951, batch.n_tokens = 2048, progress = 0.941332
2026-05-15 18:44:16.819 | slot update_slots: id  3 | task 7469 | n_tokens = 30951, memory_seq_rm [30951, end)
2026-05-15 18:44:16.819 | slot update_slots: id  3 | task 7469 | prompt processing progress, n_tokens = 32364, batch.n_tokens = 1416, progress = 0.984307
2026-05-15 18:44:17.875 | slot update_slots: id  3 | task 7469 | n_tokens = 32364, memory_seq_rm [32364, end)
2026-05-15 18:44:17.875 | slot update_slots: id  3 | task 7469 | prompt processing progress, n_tokens = 32876, batch.n_tokens = 515, progress = 0.999878
2026-05-15 18:44:18.138 | slot create_check: id  3 | task 7469 | created context checkpoint 7 of 32 (pos_min = 32363, pos_max = 32363, n_tokens = 32364, size = 217.405 MiB)
2026-05-15 18:44:18.551 | slot update_slots: id  3 | task 7469 | n_tokens = 32876, memory_seq_rm [32876, end)
2026-05-15 18:44:18.555 | slot init_sampler: id  3 | task 7469 | init sampler, took 4.08 ms, tokens: text = 32880, total = 32880
2026-05-15 18:44:18.555 | slot update_slots: id  3 | task 7469 | prompt processing done, n_tokens = 32880, batch.n_tokens = 7
2026-05-15 18:44:18.818 | slot create_check: id  3 | task 7469 | created context checkpoint 8 of 32 (pos_min = 32875, pos_max = 32875, n_tokens = 32876, size = 218.477 MiB)
2026-05-15 18:44:18.890 | srv  log_server_r: done request: POST /v1/chat/completions 172.18.0.1 200
2026-05-15 18:44:21.721 | slot print_timing: id  0 | task 7399 | 
2026-05-15 18:44:21.721 | prompt eval time =   16098.43 ms / 21268 tokens (    0.76 ms per token,  1321.12 tokens per second)
2026-05-15 18:44:21.721 |        eval time =   26818.11 ms /   246 tokens (  109.02 ms per token,     9.17 tokens per second)
2026-05-15 18:44:21.721 |       total time =   42916.54 ms / 21514 tokens
2026-05-15 18:44:21.721 | draft acceptance rate = 0.98621 (  143 accepted /   145 generated)
2026-05-15 18:44:21.721 | statistics mtp: #calls(b,g,a) = 70 6804 5672, #gen drafts = 5672, #acc drafts = 5672, #gen tokens = 10008, #acc tokens = 9849, dur(b,g,a) = 0.094, 28114.333, 2.289 ms
2026-05-15 18:44:21.721 | slot      release: id  0 | task 7399 | stop processing: n_tokens = 28771, truncated = 0
2026-05-15 18:44:21.978 | srv  params_from_: Chat format: peg-native
2026-05-15 18:44:21.998 | slot get_availabl: id  0 | task -1 | selected slot by LCP similarity, sim_best = 0.501 (> 0.100 thold), f_keep = 1.000
2026-05-15 18:44:21.999 | reasoning-budget: activated, budget=2147483647 tokens
2026-05-15 18:44:21.999 | slot launch_slot_: id  0 | task -1 | sampler chain: logits -> penalties -> ?dry -> ?top-n-sigma -> top-k -> ?typical -> ?top-p -> min-p -> ?xtc -> ?temp-ext -> dist 
2026-05-15 18:44:21.999 | slot launch_slot_: id  0 | task 7527 | processing task, is_child = 0
2026-05-15 18:44:22.007 | slot update_slots: id  0 | task 7527 | new prompt, n_ctx_slot = 131072, n_keep = 0, task.n_tokens = 57442
2026-05-15 18:44:22.007 | slot update_slots: id  0 | task 7527 | n_tokens = 28771, memory_seq_rm [28771, end)
2026-05-15 18:44:22.008 | slot update_slots: id  0 | task 7527 | prompt processing progress, n_tokens = 30816, batch.n_tokens = 2048, progress = 0.536472
2026-05-15 18:44:23.452 | slot update_slots: id  0 | task 7527 | n_tokens = 30816, memory_seq_rm [30816, end)
2026-05-15 18:44:23.452 | slot update_slots: id  0 | task 7527 | prompt processing progress, n_tokens = 32861, batch.n_tokens = 2048, progress = 0.572073
2026-05-15 18:44:24.918 | slot update_slots: id  0 | task 7527 | n_tokens = 32861, memory_seq_rm [32861, end)
2026-05-15 18:44:24.918 | slot update_slots: id  0 | task 7527 | prompt processing progress, n_tokens = 34906, batch.n_tokens = 2048, progress = 0.607674
2026-05-15 18:44:26.368 | slot update_slots: id  0 | task 7527 | n_tokens = 34906, memory_seq_rm [34906, end)
2026-05-15 18:44:26.368 | slot update_slots: id  0 | task 7527 | prompt processing progress, n_tokens = 36953, batch.n_tokens = 2048, progress = 0.643310
2026-05-15 18:44:27.811 | slot update_slots: id  0 | task 7527 | n_tokens = 36953, memory_seq_rm [36953, end)
2026-05-15 18:44:27.812 | slot update_slots: id  0 | task 7527 | 8192 tokens since last checkpoint at 28522, creating new checkpoint during processing at position 39000
2026-05-15 18:44:27.812 | slot update_slots: id  0 | task 7527 | prompt processing progress, n_tokens = 39000, batch.n_tokens = 2048, progress = 0.678946
2026-05-15 18:44:28.089 | slot create_check: id  0 | task 7527 | created context checkpoint 9 of 32 (pos_min = 36952, pos_max = 36952, n_tokens = 36953, size = 227.016 MiB)
2026-05-15 18:44:29.545 | slot update_slots: id  0 | task 7527 | n_tokens = 39000, memory_seq_rm [39000, end)
2026-05-15 18:44:29.545 | slot update_slots: id  0 | task 7527 | prompt processing progress, n_tokens = 41047, batch.n_tokens = 2048, progress = 0.714582
2026-05-15 18:44:31.027 | slot update_slots: id  0 | task 7527 | n_tokens = 41047, memory_seq_rm [41047, end)
2026-05-15 18:44:31.028 | slot update_slots: id  0 | task 7527 | prompt processing progress, n_tokens = 43092, batch.n_tokens = 2048, progress = 0.750183
2026-05-15 18:44:32.523 | reasoning-budget: deactivated (natural end)
2026-05-15 18:44:32.547 | slot update_slots: id  0 | task 7527 | n_tokens = 43092, memory_seq_rm [43092, end)
2026-05-15 18:44:32.547 | slot update_slots: id  0 | task 7527 | prompt processing progress, n_tokens = 45137, batch.n_tokens = 2048, progress = 0.785784
2026-05-15 18:44:34.112 | slot update_slots: id  0 | task 7527 | n_tokens = 45137, memory_seq_rm [45137, end)
2026-05-15 18:44:34.112 | slot update_slots: id  0 | task 7527 | prompt processing progress, n_tokens = 47183, batch.n_tokens = 2048, progress = 0.821402
2026-05-15 18:44:35.672 | slot update_slots: id  0 | task 7527 | n_tokens = 47183, memory_seq_rm [47183, end)
2026-05-15 18:44:35.672 | slot update_slots: id  0 | task 7527 | 8192 tokens since last checkpoint at 36953, creating new checkpoint during processing at position 49229
2026-05-15 18:44:35.672 | slot update_slots: id  0 | task 7527 | prompt processing progress, n_tokens = 49229, batch.n_tokens = 2048, progress = 0.857021
2026-05-15 18:44:35.969 | slot create_check: id  0 | task 7527 | created context checkpoint 10 of 32 (pos_min = 47182, pos_max = 47182, n_tokens = 47183, size = 248.440 MiB)
2026-05-15 18:44:37.551 | slot update_slots: id  0 | task 7527 | n_tokens = 49229, memory_seq_rm [49229, end)
2026-05-15 18:44:37.551 | slot update_slots: id  0 | task 7527 | prompt processing progress, n_tokens = 51275, batch.n_tokens = 2048, progress = 0.892640
2026-05-15 18:44:39.197 | slot update_slots: id  0 | task 7527 | n_tokens = 51275, memory_seq_rm [51275, end)
2026-05-15 18:44:39.197 | slot update_slots: id  0 | task 7527 | prompt processing progress, n_tokens = 53320, batch.n_tokens = 2048, progress = 0.928241
2026-05-15 18:44:40.871 | slot update_slots: id  0 | task 7527 | n_tokens = 53320, memory_seq_rm [53320, end)
2026-05-15 18:44:40.871 | slot update_slots: id  0 | task 7527 | prompt processing progress, n_tokens = 55366, batch.n_tokens = 2048, progress = 0.963859
2026-05-15 18:44:42.588 | slot update_slots: id  0 | task 7527 | n_tokens = 55366, memory_seq_rm [55366, end)
2026-05-15 18:44:42.588 | slot update_slots: id  0 | task 7527 | prompt processing progress, n_tokens = 56926, batch.n_tokens = 1561, progress = 0.991017
2026-05-15 18:44:43.918 | slot update_slots: id  0 | task 7527 | n_tokens = 56926, memory_seq_rm [56926, end)
2026-05-15 18:44:43.918 | slot update_slots: id  0 | task 7527 | prompt processing progress, n_tokens = 57438, batch.n_tokens = 513, progress = 0.999930
2026-05-15 18:44:44.235 | slot create_check: id  0 | task 7527 | created context checkpoint 11 of 32 (pos_min = 56925, pos_max = 56925, n_tokens = 56926, size = 268.845 MiB)
2026-05-15 18:44:44.703 | slot update_slots: id  0 | task 7527 | n_tokens = 57438, memory_seq_rm [57438, end)
2026-05-15 18:44:44.710 | slot init_sampler: id  0 | task 7527 | init sampler, took 7.20 ms, tokens: text = 57442, total = 57442
2026-05-15 18:44:44.710 | slot update_slots: id  0 | task 7527 | prompt processing done, n_tokens = 57442, batch.n_tokens = 5
2026-05-15 18:44:45.038 | slot create_check: id  0 | task 7527 | created context checkpoint 12 of 32 (pos_min = 57437, pos_max = 57437, n_tokens = 57438, size = 269.917 MiB)
2026-05-15 18:44:45.108 | srv  log_server_r: done request: POST /v1/chat/completions 172.18.0.1 200
2026-05-15 18:44:49.756 | reasoning-budget: deactivated (natural end)
2026-05-15 18:44:54.858 | slot print_timing: id  0 | task 7527 | 
2026-05-15 18:44:54.858 | prompt eval time =   23100.61 ms / 28671 tokens (    0.81 ms per token,  1241.14 tokens per second)
2026-05-15 18:44:54.858 |        eval time =    9732.28 ms /   254 tokens (   38.32 ms per token,    26.10 tokens per second)
2026-05-15 18:44:54.858 |       total time =   32832.89 ms / 28925 tokens
2026-05-15 18:44:54.858 | draft acceptance rate = 0.98649 (  146 accepted /   148 generated)
2026-05-15 18:44:54.858 | statistics mtp: #calls(b,g,a) = 71 6935 5861, #gen drafts = 5861, #acc drafts = 5861, #gen tokens = 10355, #acc tokens = 10193, dur(b,g,a) = 0.095, 28975.651, 2.360 ms
2026-05-15 18:44:54.859 | slot      release: id  0 | task 7527 | stop processing: n_tokens = 57695, truncated = 0
2026-05-15 18:44:55.121 | srv  params_from_: Chat format: peg-native
2026-05-15 18:44:55.139 | slot get_availabl: id  0 | task -1 | selected slot by LCP similarity, sim_best = 0.729 (> 0.100 thold), f_keep = 1.000
2026-05-15 18:44:55.140 | reasoning-budget: activated, budget=2147483647 tokens
2026-05-15 18:44:55.140 | slot launch_slot_: id  0 | task -1 | sampler chain: logits -> penalties -> ?dry -> ?top-n-sigma -> top-k -> ?typical -> ?top-p -> min-p -> ?xtc -> ?temp-ext -> dist 
2026-05-15 18:44:55.140 | slot launch_slot_: id  0 | task 7664 | processing task, is_child = 0
2026-05-15 18:44:55.149 | slot update_slots: id  0 | task 7664 | new prompt, n_ctx_slot = 131072, n_keep = 0, task.n_tokens = 79167
2026-05-15 18:44:55.149 | slot update_slots: id  0 | task 7664 | n_tokens = 57695, memory_seq_rm [57695, end)
2026-05-15 18:44:55.149 | slot update_slots: id  0 | task 7664 | prompt processing progress, n_tokens = 59740, batch.n_tokens = 2048, progress = 0.754607
2026-05-15 18:44:56.885 | slot update_slots: id  0 | task 7664 | n_tokens = 59740, memory_seq_rm [59740, end)
2026-05-15 18:44:56.886 | slot update_slots: id  0 | task 7664 | prompt processing progress, n_tokens = 61785, batch.n_tokens = 2048, progress = 0.780439
2026-05-15 18:44:58.661 | slot update_slots: id  0 | task 7664 | n_tokens = 61785, memory_seq_rm [61785, end)
2026-05-15 18:44:58.661 | slot update_slots: id  0 | task 7664 | prompt processing progress, n_tokens = 63830, batch.n_tokens = 2048, progress = 0.806270
2026-05-15 18:45:00.457 | slot update_slots: id  0 | task 7664 | n_tokens = 63830, memory_seq_rm [63830, end)
2026-05-15 18:45:00.457 | slot update_slots: id  0 | task 7664 | prompt processing progress, n_tokens = 65875, batch.n_tokens = 2048, progress = 0.832102
2026-05-15 18:45:02.278 | slot update_slots: id  0 | task 7664 | n_tokens = 65875, memory_seq_rm [65875, end)
2026-05-15 18:45:02.278 | slot update_slots: id  0 | task 7664 | 8192 tokens since last checkpoint at 57438, creating new checkpoint during processing at position 67920
2026-05-15 18:45:02.278 | slot update_slots: id  0 | task 7664 | prompt processing progress, n_tokens = 67920, batch.n_tokens = 2048, progress = 0.857933
2026-05-15 18:45:02.624 | slot create_check: id  0 | task 7664 | created context checkpoint 13 of 32 (pos_min = 65874, pos_max = 65874, n_tokens = 65875, size = 287.586 MiB)
2026-05-15 18:45:04.456 | slot update_slots: id  0 | task 7664 | n_tokens = 67920, memory_seq_rm [67920, end)
2026-05-15 18:45:04.456 | slot update_slots: id  0 | task 7664 | prompt processing progress, n_tokens = 69965, batch.n_tokens = 2048, progress = 0.883765
2026-05-15 18:45:06.354 | slot update_slots: id  0 | task 7664 | n_tokens = 69965, memory_seq_rm [69965, end)
2026-05-15 18:45:06.354 | slot update_slots: id  0 | task 7664 | prompt processing progress, n_tokens = 72012, batch.n_tokens = 2048, progress = 0.909621
2026-05-15 18:45:08.251 | slot update_slots: id  0 | task 7664 | n_tokens = 72012, memory_seq_rm [72012, end)
2026-05-15 18:45:08.251 | slot update_slots: id  0 | task 7664 | prompt processing progress, n_tokens = 74057, batch.n_tokens = 2048, progress = 0.935453
2026-05-15 18:45:10.180 | slot update_slots: id  0 | task 7664 | n_tokens = 74057, memory_seq_rm [74057, end)
2026-05-15 18:45:10.180 | slot update_slots: id  0 | task 7664 | prompt processing progress, n_tokens = 76102, batch.n_tokens = 2048, progress = 0.961284
2026-05-15 18:45:12.180 | slot update_slots: id  0 | task 7664 | n_tokens = 76102, memory_seq_rm [76102, end)
2026-05-15 18:45:12.180 | slot update_slots: id  0 | task 7664 | 8192 tokens since last checkpoint at 65875, creating new checkpoint during processing at position 78147
2026-05-15 18:45:12.180 | slot update_slots: id  0 | task 7664 | prompt processing progress, n_tokens = 78147, batch.n_tokens = 2048, progress = 0.987116
2026-05-15 18:45:12.561 | slot create_check: id  0 | task 7664 | created context checkpoint 14 of 32 (pos_min = 76101, pos_max = 76101, n_tokens = 76102, size = 309.004 MiB)
2026-05-15 18:45:14.545 | slot update_slots: id  0 | task 7664 | n_tokens = 78147, memory_seq_rm [78147, end)
2026-05-15 18:45:14.545 | slot update_slots: id  0 | task 7664 | prompt processing progress, n_tokens = 78651, batch.n_tokens = 507, progress = 0.993482
2026-05-15 18:45:15.082 | slot update_slots: id  0 | task 7664 | n_tokens = 78651, memory_seq_rm [78651, end)
2026-05-15 18:45:15.082 | slot update_slots: id  0 | task 7664 | prompt processing progress, n_tokens = 79163, batch.n_tokens = 515, progress = 0.999949
2026-05-15 18:45:15.482 | slot create_check: id  0 | task 7664 | created context checkpoint 15 of 32 (pos_min = 78650, pos_max = 78650, n_tokens = 78651, size = 314.342 MiB)
2026-05-15 18:45:16.032 | slot update_slots: id  0 | task 7664 | n_tokens = 79163, memory_seq_rm [79163, end)
2026-05-15 18:45:16.042 | slot init_sampler: id  0 | task 7664 | init sampler, took 9.97 ms, tokens: text = 79167, total = 79167
2026-05-15 18:45:16.042 | slot update_slots: id  0 | task 7664 | prompt processing done, n_tokens = 79167, batch.n_tokens = 7
2026-05-15 18:45:16.430 | slot create_check: id  0 | task 7664 | created context checkpoint 16 of 32 (pos_min = 79162, pos_max = 79162, n_tokens = 79163, size = 315.415 MiB)
2026-05-15 18:45:16.513 | srv  log_server_r: done request: POST /v1/chat/completions 172.18.0.1 200
2026-05-15 18:45:19.188 | reasoning-budget: deactivated (natural end)
2026-05-15 18:45:20.763 | slot print_timing: id  3 | task 7469 | 
2026-05-15 18:45:20.763 | prompt eval time =   19937.58 ms / 26469 tokens (    0.75 ms per token,  1327.59 tokens per second)
2026-05-15 18:45:20.763 |        eval time =   61837.32 ms /   559 tokens (  110.62 ms per token,     9.04 tokens per second)
2026-05-15 18:45:20.763 |       total time =   81774.90 ms / 27028 tokens
2026-05-15 18:45:20.763 | draft acceptance rate = 0.99702 (  335 accepted /   336 generated)
2026-05-15 18:45:20.763 | statistics mtp: #calls(b,g,a) = 72 6998 5943, #gen drafts = 5943, #acc drafts = 5943, #gen tokens = 10505, #acc tokens = 10340, dur(b,g,a) = 0.096, 29553.598, 2.397 ms
2026-05-15 18:45:20.764 | slot      release: id  3 | task 7469 | stop processing: n_tokens = 33438, truncated = 0
2026-05-15 18:45:20.989 | srv  params_from_: Chat format: peg-native
2026-05-15 18:45:21.016 | slot get_availabl: id  3 | task -1 | selected slot by LCP similarity, sim_best = 0.900 (> 0.100 thold), f_keep = 1.000
2026-05-15 18:45:21.017 | reasoning-budget: activated, budget=2147483647 tokens
2026-05-15 18:45:21.017 | slot launch_slot_: id  3 | task -1 | sampler chain: logits -> penalties -> ?dry -> ?top-n-sigma -> top-k -> ?typical -> ?top-p -> min-p -> ?xtc -> ?temp-ext -> dist 
2026-05-15 18:45:21.017 | slot launch_slot_: id  3 | task 7728 | processing task, is_child = 0
2026-05-15 18:45:21.028 | slot update_slots: id  3 | task 7728 | new prompt, n_ctx_slot = 131072, n_keep = 0, task.n_tokens = 37137
2026-05-15 18:45:21.029 | slot update_slots: id  3 | task 7728 | n_tokens = 33438, memory_seq_rm [33438, end)
2026-05-15 18:45:21.029 | slot update_slots: id  3 | task 7728 | prompt processing progress, n_tokens = 35483, batch.n_tokens = 2048, progress = 0.955462
2026-05-15 18:45:23.105 | slot update_slots: id  3 | task 7728 | n_tokens = 35483, memory_seq_rm [35483, end)
2026-05-15 18:45:23.106 | slot update_slots: id  3 | task 7728 | prompt processing progress, n_tokens = 36621, batch.n_tokens = 1141, progress = 0.986106
2026-05-15 18:45:24.278 | slot update_slots: id  3 | task 7728 | n_tokens = 36621, memory_seq_rm [36621, end)
2026-05-15 18:45:24.278 | slot update_slots: id  3 | task 7728 | prompt processing progress, n_tokens = 37133, batch.n_tokens = 515, progress = 0.999892
2026-05-15 18:45:24.546 | slot create_check: id  3 | task 7728 | created context checkpoint 9 of 32 (pos_min = 36620, pos_max = 36620, n_tokens = 36621, size = 226.320 MiB)
2026-05-15 18:45:25.122 | slot update_slots: id  3 | task 7728 | n_tokens = 37133, memory_seq_rm [37133, end)
2026-05-15 18:45:25.127 | slot init_sampler: id  3 | task 7728 | init sampler, took 4.79 ms, tokens: text = 37137, total = 37137
2026-05-15 18:45:25.127 | slot update_slots: id  3 | task 7728 | prompt processing done, n_tokens = 37137, batch.n_tokens = 7
2026-05-15 18:45:25.412 | slot create_check: id  3 | task 7728 | created context checkpoint 10 of 32 (pos_min = 37132, pos_max = 37132, n_tokens = 37133, size = 227.393 MiB)
2026-05-15 18:45:25.496 | srv  log_server_r: done request: POST /v1/chat/completions 172.18.0.1 200
2026-05-15 18:45:27.031 | reasoning-budget: deactivated (natural end)
2026-05-15 18:45:29.746 | slot print_timing: id  0 | task 7664 | 
2026-05-15 18:45:29.747 | prompt eval time =   21345.67 ms / 21472 tokens (    0.99 ms per token,  1005.92 tokens per second)
2026-05-15 18:45:29.747 |        eval time =   13233.02 ms /   226 tokens (   58.55 ms per token,    17.08 tokens per second)
2026-05-15 18:45:29.747 |       total time =   34578.69 ms / 21698 tokens
2026-05-15 18:45:29.747 | draft acceptance rate = 0.96350 (  132 accepted /   137 generated)
2026-05-15 18:45:29.747 | statistics mtp: #calls(b,g,a) = 73 7052 6022, #gen drafts = 6023, #acc drafts = 6022, #gen tokens = 10657, #acc tokens = 10488, dur(b,g,a) = 0.097, 29907.435, 2.433 ms
2026-05-15 18:45:29.748 | slot      release: id  0 | task 7664 | stop processing: n_tokens = 79392, truncated = 0
2026-05-15 18:45:30.012 | srv  params_from_: Chat format: peg-native
2026-05-15 18:45:30.016 | slot get_availabl: id  0 | task -1 | selected slot by LCP similarity, sim_best = 0.838 (> 0.100 thold), f_keep = 1.000
2026-05-15 18:45:30.017 | reasoning-budget: activated, budget=2147483647 tokens
2026-05-15 18:45:30.017 | slot launch_slot_: id  0 | task -1 | sampler chain: logits -> penalties -> ?dry -> ?top-n-sigma -> top-k -> ?typical -> ?top-p -> min-p -> ?xtc -> ?temp-ext -> dist 
2026-05-15 18:45:30.017 | slot launch_slot_: id  0 | task 7784 | processing task, is_child = 0
2026-05-15 18:45:30.026 | slot update_slots: id  0 | task 7784 | new prompt, n_ctx_slot = 131072, n_keep = 0, task.n_tokens = 94689
2026-05-15 18:45:30.026 | slot update_slots: id  0 | task 7784 | n_tokens = 79392, memory_seq_rm [79392, end)
2026-05-15 18:45:30.027 | slot update_slots: id  0 | task 7784 | prompt processing progress, n_tokens = 81437, batch.n_tokens = 2048, progress = 0.860047
2026-05-15 18:45:32.087 | slot update_slots: id  0 | task 7784 | n_tokens = 81437, memory_seq_rm [81437, end)
2026-05-15 18:45:32.087 | slot update_slots: id  0 | task 7784 | prompt processing progress, n_tokens = 83482, batch.n_tokens = 2048, progress = 0.881644
2026-05-15 18:45:34.192 | slot update_slots: id  0 | task 7784 | n_tokens = 83482, memory_seq_rm [83482, end)
2026-05-15 18:45:34.192 | slot update_slots: id  0 | task 7784 | prompt processing progress, n_tokens = 85527, batch.n_tokens = 2048, progress = 0.903241
2026-05-15 18:45:36.318 | slot update_slots: id  0 | task 7784 | n_tokens = 85527, memory_seq_rm [85527, end)
2026-05-15 18:45:36.318 | slot update_slots: id  0 | task 7784 | prompt processing progress, n_tokens = 87572, batch.n_tokens = 2048, progress = 0.924838
2026-05-15 18:45:38.477 | slot update_slots: id  0 | task 7784 | n_tokens = 87572, memory_seq_rm [87572, end)
2026-05-15 18:45:38.477 | slot update_slots: id  0 | task 7784 | 8192 tokens since last checkpoint at 79163, creating new checkpoint during processing at position 89617
2026-05-15 18:45:38.477 | slot update_slots: id  0 | task 7784 | prompt processing progress, n_tokens = 89617, batch.n_tokens = 2048, progress = 0.946435
2026-05-15 18:45:38.907 | slot create_check: id  0 | task 7784 | created context checkpoint 17 of 32 (pos_min = 87571, pos_max = 87571, n_tokens = 87572, size = 333.025 MiB)
2026-05-15 18:45:41.111 | slot update_slots: id  0 | task 7784 | n_tokens = 89617, memory_seq_rm [89617, end)
2026-05-15 18:45:41.111 | slot update_slots: id  0 | task 7784 | prompt processing progress, n_tokens = 91662, batch.n_tokens = 2048, progress = 0.968032
2026-05-15 18:45:43.324 | slot update_slots: id  0 | task 7784 | n_tokens = 91662, memory_seq_rm [91662, end)
2026-05-15 18:45:43.324 | slot update_slots: id  0 | task 7784 | prompt processing progress, n_tokens = 93709, batch.n_tokens = 2048, progress = 0.989650
2026-05-15 18:45:45.560 | slot update_slots: id  0 | task 7784 | n_tokens = 93709, memory_seq_rm [93709, end)
2026-05-15 18:45:45.560 | slot update_slots: id  0 | task 7784 | prompt processing progress, n_tokens = 94173, batch.n_tokens = 465, progress = 0.994551
2026-05-15 18:45:45.562 | init_batch: failed to prepare attention ubatches
2026-05-15 18:45:45.562 | decode: failed to find a memory slot for batch of size 465
2026-05-15 18:45:45.562 | srv  update_slots: failed to find free space in the KV cache, retrying with smaller batch size, i = 0, n_batch = 1024, ret = 1
2026-05-15 18:45:45.564 | init_batch: failed to prepare attention ubatches
2026-05-15 18:45:45.564 | decode: failed to find a memory slot for batch of size 465
2026-05-15 18:45:45.564 | srv  update_slots: failed to find free space in the KV cache, retrying with smaller batch size, i = 0, n_batch = 512, ret = 1
2026-05-15 18:45:45.565 | init_batch: failed to prepare attention ubatches
2026-05-15 18:45:45.565 | decode: failed to find a memory slot for batch of size 465
2026-05-15 18:45:45.565 | srv  update_slots: failed to find free space in the KV cache, retrying with smaller batch size, i = 0, n_batch = 256, ret = 1
2026-05-15 18:45:45.566 | init_batch: failed to prepare attention ubatches
2026-05-15 18:45:45.566 | decode: failed to find a memory slot for batch of size 256
2026-05-15 18:45:45.566 | srv  update_slots: failed to find free space in the KV cache, retrying with smaller batch size, i = 0, n_batch = 128, ret = 1
2026-05-15 18:45:45.568 | init_batch: failed to prepare attention ubatches
2026-05-15 18:45:45.568 | decode: failed to find a memory slot for batch of size 128
2026-05-15 18:45:45.568 | srv  update_slots: failed to find free space in the KV cache, retrying with smaller batch size, i = 0, n_batch = 64, ret = 1
2026-05-15 18:45:45.677 | init_batch: failed to prepare attention ubatches
2026-05-15 18:45:45.677 | decode: failed to find a memory slot for batch of size 401
2026-05-15 18:45:45.677 | srv  update_slots: failed to find free space in the KV cache, retrying with smaller batch size, i = 64, n_batch = 1024, ret = 1
2026-05-15 18:45:45.679 | init_batch: failed to prepare attention ubatches
2026-05-15 18:45:45.679 | decode: failed to find a memory slot for batch of size 401
2026-05-15 18:45:45.679 | srv  update_slots: failed to find free space in the KV cache, retrying with smaller batch size, i = 64, n_batch = 512, ret = 1
2026-05-15 18:45:45.680 | init_batch: failed to prepare attention ubatches
2026-05-15 18:45:45.680 | decode: failed to find a memory slot for batch of size 401
2026-05-15 18:45:45.680 | srv  update_slots: failed to find free space in the KV cache, retrying with smaller batch size, i = 64, n_batch = 256, ret = 1
2026-05-15 18:45:45.682 | init_batch: failed to prepare attention ubatches
2026-05-15 18:45:45.682 | decode: failed to find a memory slot for batch of size 256
2026-05-15 18:45:45.682 | srv  update_slots: failed to find free space in the KV cache, retrying with smaller batch size, i = 64, n_batch = 128, ret = 1
2026-05-15 18:45:45.683 | init_batch: failed to prepare attention ubatches
2026-05-15 18:45:45.683 | decode: failed to find a memory slot for batch of size 128
2026-05-15 18:45:45.683 | srv  update_slots: failed to find free space in the KV cache, retrying with smaller batch size, i = 64, n_batch = 64, ret = 1
2026-05-15 18:45:45.684 | init_batch: failed to prepare attention ubatches
2026-05-15 18:45:45.685 | decode: failed to find a memory slot for batch of size 64
2026-05-15 18:45:45.685 | srv  update_slots: failed to find free space in the KV cache, retrying with smaller batch size, i = 64, n_batch = 32, ret = 1
2026-05-15 18:45:45.686 | init_batch: failed to prepare attention ubatches
2026-05-15 18:45:45.686 | decode: failed to find a memory slot for batch of size 32
2026-05-15 18:45:45.686 | srv  update_slots: failed to find free space in the KV cache, retrying with smaller batch size, i = 64, n_batch = 16, ret = 1
2026-05-15 18:45:45.738 | init_batch: failed to prepare attention ubatches
2026-05-15 18:45:45.738 | decode: failed to find a memory slot for batch of size 385
2026-05-15 18:45:45.738 | srv  update_slots: failed to find free space in the KV cache, retrying with smaller batch size, i = 80, n_batch = 1024, ret = 1
2026-05-15 18:45:45.739 | init_batch: failed to prepare attention ubatches
2026-05-15 18:45:45.739 | decode: failed to find a memory slot for batch of size 385
2026-05-15 18:45:45.739 | srv  update_slots: failed to find free space in the KV cache, retrying with smaller batch size, i = 80, n_batch = 512, ret = 1
2026-05-15 18:45:45.741 | init_batch: failed to prepare attention ubatches
2026-05-15 18:45:45.741 | decode: failed to find a memory slot for batch of size 385
2026-05-15 18:45:45.741 | srv  update_slots: failed to find free space in the KV cache, retrying with smaller batch size, i = 80, n_batch = 256, ret = 1
2026-05-15 18:45:45.742 | init_batch: failed to prepare attention ubatches
2026-05-15 18:45:45.742 | decode: failed to find a memory slot for batch of size 256
2026-05-15 18:45:45.742 | srv  update_slots: failed to find free space in the KV cache, retrying with smaller batch size, i = 80, n_batch = 128, ret = 1
2026-05-15 18:45:45.743 | init_batch: failed to prepare attention ubatches
2026-05-15 18:45:45.743 | decode: failed to find a memory slot for batch of size 128
2026-05-15 18:45:45.743 | srv  update_slots: failed to find free space in the KV cache, retrying with smaller batch size, i = 80, n_batch = 64, ret = 1
2026-05-15 18:45:45.745 | init_batch: failed to prepare attention ubatches
2026-05-15 18:45:45.745 | decode: failed to find a memory slot for batch of size 64
2026-05-15 18:45:45.745 | srv  update_slots: failed to find free space in the KV cache, retrying with smaller batch size, i = 80, n_batch = 32, ret = 1
2026-05-15 18:45:45.746 | init_batch: failed to prepare attention ubatches
2026-05-15 18:45:45.746 | decode: failed to find a memory slot for batch of size 32
2026-05-15 18:45:45.746 | srv  update_slots: failed to find free space in the KV cache, retrying with smaller batch size, i = 80, n_batch = 16, ret = 1
2026-05-15 18:45:45.748 | init_batch: failed to prepare attention ubatches
2026-05-15 18:45:45.748 | decode: failed to find a memory slot for batch of size 16
2026-05-15 18:45:45.748 | srv  update_slots: failed to find free space in the KV cache, retrying with smaller batch size, i = 80, n_batch = 8, ret = 1
2026-05-15 18:45:45.802 | init_batch: failed to prepare attention ubatches
2026-05-15 18:45:45.802 | decode: failed to find a memory slot for batch of size 377
2026-05-15 18:45:45.802 | srv  update_slots: failed to find free space in the KV cache, retrying with smaller batch size, i = 88, n_batch = 1024, ret = 1
2026-05-15 18:45:45.803 | init_batch: failed to prepare attention ubatches
2026-05-15 18:45:45.803 | decode: failed to find a memory slot for batch of size 377
2026-05-15 18:45:45.803 | srv  update_slots: failed to find free space in the KV cache, retrying with smaller batch size, i = 88, n_batch = 512, ret = 1
2026-05-15 18:45:45.804 | init_batch: failed to prepare attention ubatches
2026-05-15 18:45:45.804 | decode: failed to find a memory slot for batch of size 377
2026-05-15 18:45:45.804 | srv  update_slots: failed to find free space in the KV cache, retrying with smaller batch size, i = 88, n_batch = 256, ret = 1
2026-05-15 18:45:45.806 | init_batch: failed to prepare attention ubatches
2026-05-15 18:45:45.806 | decode: failed to find a memory slot for batch of size 256
2026-05-15 18:45:45.806 | srv  update_slots: failed to find free space in the KV cache, retrying with smaller batch size, i = 88, n_batch = 128, ret = 1
2026-05-15 18:45:45.807 | init_batch: failed to prepare attention ubatches
2026-05-15 18:45:45.807 | decode: failed to find a memory slot for batch of size 128
2026-05-15 18:45:45.807 | srv  update_slots: failed to find free space in the KV cache, retrying with smaller batch size, i = 88, n_batch = 64, ret = 1
2026-05-15 18:45:45.809 | init_batch: failed to prepare attention ubatches
2026-05-15 18:45:45.809 | decode: failed to find a memory slot for batch of size 64
2026-05-15 18:45:45.809 | srv  update_slots: failed to find free space in the KV cache, retrying with smaller batch size, i = 88, n_batch = 32, ret = 1
2026-05-15 18:45:45.810 | init_batch: failed to prepare attention ubatches
2026-05-15 18:45:45.810 | decode: failed to find a memory slot for batch of size 32
2026-05-15 18:45:45.810 | srv  update_slots: failed to find free space in the KV cache, retrying with smaller batch size, i = 88, n_batch = 16, ret = 1
2026-05-15 18:45:45.812 | init_batch: failed to prepare attention ubatches
2026-05-15 18:45:45.812 | decode: failed to find a memory slot for batch of size 16
2026-05-15 18:45:45.812 | srv  update_slots: failed to find free space in the KV cache, retrying with smaller batch size, i = 88, n_batch = 8, ret = 1
2026-05-15 18:45:45.813 | init_batch: failed to prepare attention ubatches
2026-05-15 18:45:45.813 | decode: failed to find a memory slot for batch of size 8
2026-05-15 18:45:45.813 | srv  update_slots: failed to find free space in the KV cache, retrying with smaller batch size, i = 88, n_batch = 4, ret = 1
2026-05-15 18:45:45.861 | init_batch: failed to prepare attention ubatches
2026-05-15 18:45:45.861 | decode: failed to find a memory slot for batch of size 373
2026-05-15 18:45:45.861 | srv  update_slots: failed to find free space in the KV cache, retrying with smaller batch size, i = 92, n_batch = 1024, ret = 1
2026-05-15 18:45:45.862 | init_batch: failed to prepare attention ubatches
2026-05-15 18:45:45.862 | decode: failed to find a memory slot for batch of size 373
2026-05-15 18:45:45.862 | srv  update_slots: failed to find free space in the KV cache, retrying with smaller batch size, i = 92, n_batch = 512, ret = 1
2026-05-15 18:45:45.864 | init_batch: failed to prepare attention ubatches
2026-05-15 18:45:45.864 | decode: failed to find a memory slot for batch of size 373
2026-05-15 18:45:45.864 | srv  update_slots: failed to find free space in the KV cache, retrying with smaller batch size, i = 92, n_batch = 256, ret = 1
2026-05-15 18:45:45.865 | init_batch: failed to prepare attention ubatches
2026-05-15 18:45:45.865 | decode: failed to find a memory slot for batch of size 256
2026-05-15 18:45:45.865 | srv  update_slots: failed to find free space in the KV cache, retrying with smaller batch size, i = 92, n_batch = 128, ret = 1
2026-05-15 18:45:45.867 | init_batch: failed to prepare attention ubatches
2026-05-15 18:45:45.867 | decode: failed to find a memory slot for batch of size 128
2026-05-15 18:45:45.867 | srv  update_slots: failed to find free space in the KV cache, retrying with smaller batch size, i = 92, n_batch = 64, ret = 1
2026-05-15 18:45:45.868 | init_batch: failed to prepare attention ubatches
2026-05-15 18:45:45.868 | decode: failed to find a memory slot for batch of size 64
2026-05-15 18:45:45.868 | srv  update_slots: failed to find free space in the KV cache, retrying with smaller batch size, i = 92, n_batch = 32, ret = 1
2026-05-15 18:45:45.869 | init_batch: failed to prepare attention ubatches
2026-05-15 18:45:45.869 | decode: failed to find a memory slot for batch of size 32
2026-05-15 18:45:45.869 | srv  update_slots: failed to find free space in the KV cache, retrying with smaller batch size, i = 92, n_batch = 16, ret = 1
2026-05-15 18:45:45.871 | init_batch: failed to prepare attention ubatches
2026-05-15 18:45:45.871 | decode: failed to find a memory slot for batch of size 16
2026-05-15 18:45:45.871 | srv  update_slots: failed to find free space in the KV cache, retrying with smaller batch size, i = 92, n_batch = 8, ret = 1
2026-05-15 18:45:45.872 | init_batch: failed to prepare attention ubatches
2026-05-15 18:45:45.872 | decode: failed to find a memory slot for batch of size 8
2026-05-15 18:45:45.872 | srv  update_slots: failed to find free space in the KV cache, retrying with smaller batch size, i = 92, n_batch = 4, ret = 1
2026-05-15 18:45:45.874 | init_batch: failed to prepare attention ubatches
2026-05-15 18:45:45.874 | decode: failed to find a memory slot for batch of size 4
2026-05-15 18:45:45.874 | srv  update_slots: failed to find free space in the KV cache, retrying with smaller batch size, i = 92, n_batch = 2, ret = 1
2026-05-15 18:45:45.875 | init_batch: failed to prepare attention ubatches
2026-05-15 18:45:45.875 | decode: failed to find a memory slot for batch of size 2
2026-05-15 18:45:45.875 | srv  update_slots: failed to find free space in the KV cache, retrying with smaller batch size, i = 92, n_batch = 1, ret = 1
2026-05-15 18:45:45.909 | init_batch: failed to prepare attention ubatches
2026-05-15 18:45:45.909 | decode: failed to find a memory slot for batch of size 372
2026-05-15 18:45:45.909 | srv  update_slots: failed to find free space in the KV cache, retrying with smaller batch size, i = 93, n_batch = 1024, ret = 1
2026-05-15 18:45:45.910 | init_batch: failed to prepare attention ubatches
2026-05-15 18:45:45.910 | decode: failed to find a memory slot for batch of size 372
2026-05-15 18:45:45.910 | srv  update_slots: failed to find free space in the KV cache, retrying with smaller batch size, i = 93, n_batch = 512, ret = 1
2026-05-15 18:45:45.912 | init_batch: failed to prepare attention ubatches
2026-05-15 18:45:45.912 | decode: failed to find a memory slot for batch of size 372
2026-05-15 18:45:45.912 | srv  update_slots: failed to find free space in the KV cache, retrying with smaller batch size, i = 93, n_batch = 256, ret = 1
2026-05-15 18:45:45.913 | init_batch: failed to prepare attention ubatches
2026-05-15 18:45:45.913 | decode: failed to find a memory slot for batch of size 256
2026-05-15 18:45:45.913 | srv  update_slots: failed to find free space in the KV cache, retrying with smaller batch size, i = 93, n_batch = 128, ret = 1
2026-05-15 18:45:45.915 | init_batch: failed to prepare attention ubatches
2026-05-15 18:45:45.915 | decode: failed to find a memory slot for batch of size 128
2026-05-15 18:45:45.915 | srv  update_slots: failed to find free space in the KV cache, retrying with smaller batch size, i = 93, n_batch = 64, ret = 1
2026-05-15 18:45:45.916 | init_batch: failed to prepare attention ubatches
2026-05-15 18:45:45.916 | decode: failed to find a memory slot for batch of size 64
2026-05-15 18:45:45.916 | srv  update_slots: failed to find free space in the KV cache, retrying with smaller batch size, i = 93, n_batch = 32, ret = 1
2026-05-15 18:45:45.917 | init_batch: failed to prepare attention ubatches
2026-05-15 18:45:45.917 | decode: failed to find a memory slot for batch of size 32
2026-05-15 18:45:45.917 | srv  update_slots: failed to find free space in the KV cache, retrying with smaller batch size, i = 93, n_batch = 16, ret = 1
2026-05-15 18:45:45.919 | init_batch: failed to prepare attention ubatches
2026-05-15 18:45:45.919 | decode: failed to find a memory slot for batch of size 16
2026-05-15 18:45:45.919 | srv  update_slots: failed to find free space in the KV cache, retrying with smaller batch size, i = 93, n_batch = 8, ret = 1
2026-05-15 18:45:45.920 | init_batch: failed to prepare attention ubatches
2026-05-15 18:45:45.920 | decode: failed to find a memory slot for batch of size 8
2026-05-15 18:45:45.920 | srv  update_slots: failed to find free space in the KV cache, retrying with smaller batch size, i = 93, n_batch = 4, ret = 1
2026-05-15 18:45:45.922 | init_batch: failed to prepare attention ubatches
2026-05-15 18:45:45.922 | decode: failed to find a memory slot for batch of size 4
2026-05-15 18:45:45.922 | srv  update_slots: failed to find free space in the KV cache, retrying with smaller batch size, i = 93, n_batch = 2, ret = 1
2026-05-15 18:45:45.923 | init_batch: failed to prepare attention ubatches
2026-05-15 18:45:45.923 | decode: failed to find a memory slot for batch of size 2
2026-05-15 18:45:45.923 | srv  update_slots: failed to find free space in the KV cache, retrying with smaller batch size, i = 93, n_batch = 1, ret = 1
2026-05-15 18:45:45.925 | init_batch: failed to prepare attention ubatches
2026-05-15 18:45:45.925 | decode: failed to find a memory slot for batch of size 1
2026-05-15 18:45:45.925 | srv  update_slots: Context size has been exceeded. i = 93, n_batch = 1, ret = 1
2026-05-15 18:45:45.925 | srv    send_error: task id = 7784, error: Context size has been exceeded.
2026-05-15 18:45:45.925 | slot      release: id  0 | task 7784 | stop processing: n_tokens = 94173, truncated = 0
2026-05-15 18:45:45.925 | srv          stop: cancel task, id_task = 7784
2026-05-15 18:45:45.925 | slot prompt_clear: id  0 | task -1 | clearing prompt with 94173 tokens
2026-05-15 18:45:45.925 | srv  log_server_r: done request: POST /v1/chat/completions 172.18.0.1 500
2026-05-15 18:45:45.942 | srv    send_error: task id = 7728, error: Context size has been exceeded.
2026-05-15 18:45:45.942 | slot      release: id  3 | task 7728 | stop processing: n_tokens = 37271, truncated = 0
2026-05-15 18:45:45.942 | slot prompt_clear: id  3 | task -1 | clearing prompt with 37271 tokens
2026-05-15 18:45:45.942 | srv          stop: cancel task, id_task = 7728
2026-05-15 18:45:45.949 | srv  update_slots: all slots are idle
2026-05-15 18:45:48.140 | srv  params_from_: Chat format: peg-native
2026-05-15 18:45:48.142 | slot get_availabl: id  2 | task -1 | selected slot by LRU, t_last = 1577898775
2026-05-15 18:45:48.142 | srv  get_availabl: updating prompt cache
2026-05-15 18:45:48.142 | srv          load:  - looking for better prompt, base f_keep = -1.000, sim = 0.000
2026-05-15 18:45:48.142 | srv        update:  - cache state: 1 prompts, 5081.948 MiB (limits: 8192.000 MiB, 131072 tokens, 131072 est)
2026-05-15 18:45:48.142 | srv        update:    - prompt 0x6487e6082f70:   64767 tokens, checkpoints: 11,  5081.948 MiB
2026-05-15 18:45:48.142 | srv  get_availabl: prompt cache update took 0.01 ms
2026-05-15 18:45:48.152 | reasoning-budget: activated, budget=2147483647 tokens
2026-05-15 18:45:48.152 | slot launch_slot_: id  2 | task -1 | sampler chain: logits -> penalties -> ?dry -> ?top-n-sigma -> top-k -> ?typical -> ?top-p -> min-p -> ?xtc -> ?temp-ext -> dist 
2026-05-15 18:45:48.152 | slot launch_slot_: id  2 | task 7795 | processing task, is_child = 0
2026-05-15 18:45:48.152 | slot update_slots: id  2 | task 7795 | new prompt, n_ctx_slot = 131072, n_keep = 0, task.n_tokens = 94689
2026-05-15 18:45:48.152 | slot update_slots: id  2 | task 7795 | erased invalidated context checkpoint (pos_min = 67422, pos_max = 67422, n_tokens = 67423, n_swa = 0, pos_next = 0, size = 290.828 MiB)
2026-05-15 18:45:48.169 | slot update_slots: id  2 | task 7795 | erased invalidated context checkpoint (pos_min = 75720, pos_max = 75720, n_tokens = 75721, n_swa = 0, pos_next = 0, size = 308.206 MiB)
2026-05-15 18:45:48.187 | slot update_slots: id  2 | task 7795 | erased invalidated context checkpoint (pos_min = 83912, pos_max = 83912, n_tokens = 83913, n_swa = 0, pos_next = 0, size = 325.363 MiB)
2026-05-15 18:45:48.207 | slot update_slots: id  2 | task 7795 | erased invalidated context checkpoint (pos_min = 86949, pos_max = 86949, n_tokens = 86950, n_swa = 0, pos_next = 0, size = 331.723 MiB)
2026-05-15 18:45:48.226 | slot update_slots: id  2 | task 7795 | erased invalidated context checkpoint (pos_min = 87461, pos_max = 87461, n_tokens = 87462, n_swa = 0, pos_next = 0, size = 332.795 MiB)
2026-05-15 18:45:48.246 | slot update_slots: id  2 | task 7795 | erased invalidated context checkpoint (pos_min = 87597, pos_max = 87597, n_tokens = 87598, n_swa = 0, pos_next = 0, size = 333.080 MiB)
2026-05-15 18:45:48.266 | slot update_slots: id  2 | task 7795 | erased invalidated context checkpoint (pos_min = 87736, pos_max = 87736, n_tokens = 87737, n_swa = 0, pos_next = 0, size = 333.371 MiB)
2026-05-15 18:45:48.285 | slot update_slots: id  2 | task 7795 | erased invalidated context checkpoint (pos_min = 87946, pos_max = 87946, n_tokens = 87947, n_swa = 0, pos_next = 0, size = 333.811 MiB)
2026-05-15 18:45:48.306 | slot update_slots: id  2 | task 7795 | erased invalidated context checkpoint (pos_min = 88356, pos_max = 88356, n_tokens = 88357, n_swa = 0, pos_next = 0, size = 334.669 MiB)
2026-05-15 18:45:48.326 | slot update_slots: id  2 | task 7795 | erased invalidated context checkpoint (pos_min = 88567, pos_max = 88567, n_tokens = 88568, n_swa = 0, pos_next = 0, size = 335.111 MiB)
2026-05-15 18:45:48.346 | slot update_slots: id  2 | task 7795 | erased invalidated context checkpoint (pos_min = 88711, pos_max = 88711, n_tokens = 88712, n_swa = 0, pos_next = 0, size = 335.413 MiB)
2026-05-15 18:45:48.365 | slot update_slots: id  2 | task 7795 | erased invalidated context checkpoint (pos_min = 88843, pos_max = 88843, n_tokens = 88844, n_swa = 0, pos_next = 0, size = 335.689 MiB)
2026-05-15 18:45:48.385 | slot update_slots: id  2 | task 7795 | erased invalidated context checkpoint (pos_min = 89003, pos_max = 89003, n_tokens = 89004, n_swa = 0, pos_next = 0, size = 336.024 MiB)
2026-05-15 18:45:48.405 | slot update_slots: id  2 | task 7795 | erased invalidated context checkpoint (pos_min = 89131, pos_max = 89131, n_tokens = 89132, n_swa = 0, pos_next = 0, size = 336.293 MiB)
2026-05-15 18:45:48.425 | slot update_slots: id  2 | task 7795 | erased invalidated context checkpoint (pos_min = 89202, pos_max = 89202, n_tokens = 89203, n_swa = 0, pos_next = 0, size = 336.441 MiB)
2026-05-15 18:45:48.445 | slot update_slots: id  2 | task 7795 | erased invalidated context checkpoint (pos_min = 89325, pos_max = 89325, n_tokens = 89326, n_swa = 0, pos_next = 0, size = 336.699 MiB)
2026-05-15 18:45:48.465 | slot update_slots: id  2 | task 7795 | erased invalidated context checkpoint (pos_min = 89497, pos_max = 89497, n_tokens = 89498, n_swa = 0, pos_next = 0, size = 337.059 MiB)
2026-05-15 18:45:48.485 | slot update_slots: id  2 | task 7795 | erased invalidated context checkpoint (pos_min = 89671, pos_max = 89671, n_tokens = 89672, n_swa = 0, pos_next = 0, size = 337.423 MiB)
2026-05-15 18:45:48.506 | slot update_slots: id  2 | task 7795 | erased invalidated context checkpoint (pos_min = 90072, pos_max = 90072, n_tokens = 90073, n_swa = 0, pos_next = 0, size = 338.263 MiB)
2026-05-15 18:45:48.526 | slot update_slots: id  2 | task 7795 | erased invalidated context checkpoint (pos_min = 90584, pos_max = 90584, n_tokens = 90585, n_swa = 0, pos_next = 0, size = 339.336 MiB)
2026-05-15 18:45:48.546 | slot update_slots: id  2 | task 7795 | erased invalidated context checkpoint (pos_min = 90689, pos_max = 90689, n_tokens = 90690, n_swa = 0, pos_next = 0, size = 339.555 MiB)
2026-05-15 18:45:48.566 | slot update_slots: id  2 | task 7795 | erased invalidated context checkpoint (pos_min = 90781, pos_max = 90781, n_tokens = 90782, n_swa = 0, pos_next = 0, size = 339.748 MiB)
2026-05-15 18:45:48.587 | slot update_slots: id  2 | task 7795 | erased invalidated context checkpoint (pos_min = 90875, pos_max = 90875, n_tokens = 90876, n_swa = 0, pos_next = 0, size = 339.945 MiB)
2026-05-15 18:45:48.608 | slot update_slots: id  2 | task 7795 | erased invalidated context checkpoint (pos_min = 91011, pos_max = 91011, n_tokens = 91012, n_swa = 0, pos_next = 0, size = 340.230 MiB)
2026-05-15 18:45:48.627 | slot update_slots: id  2 | task 7795 | erased invalidated context checkpoint (pos_min = 91374, pos_max = 91374, n_tokens = 91375, n_swa = 0, pos_next = 0, size = 340.990 MiB)
2026-05-15 18:45:48.648 | slot update_slots: id  2 | task 7795 | erased invalidated context checkpoint (pos_min = 91504, pos_max = 91504, n_tokens = 91505, n_swa = 0, pos_next = 0, size = 341.262 MiB)
2026-05-15 18:45:48.668 | slot update_slots: id  2 | task 7795 | erased invalidated context checkpoint (pos_min = 91621, pos_max = 91621, n_tokens = 91622, n_swa = 0, pos_next = 0, size = 341.507 MiB)
2026-05-15 18:45:48.688 | slot update_slots: id  2 | task 7795 | erased invalidated context checkpoint (pos_min = 92097, pos_max = 92097, n_tokens = 92098, n_swa = 0, pos_next = 0, size = 342.504 MiB)
2026-05-15 18:45:48.708 | slot update_slots: id  2 | task 7795 | erased invalidated context checkpoint (pos_min = 100447, pos_max = 100447, n_tokens = 100448, n_swa = 0, pos_next = 0, size = 359.991 MiB)
2026-05-15 18:45:48.729 | slot update_slots: id  2 | task 7795 | erased invalidated context checkpoint (pos_min = 108639, pos_max = 108639, n_tokens = 108640, n_swa = 0, pos_next = 0, size = 377.148 MiB)
2026-05-15 18:45:48.751 | slot update_slots: id  2 | task 7795 | erased invalidated context checkpoint (pos_min = 112909, pos_max = 112909, n_tokens = 112910, n_swa = 0, pos_next = 0, size = 386.090 MiB)
2026-05-15 18:45:48.774 | slot update_slots: id  2 | task 7795 | erased invalidated context checkpoint (pos_min = 113421, pos_max = 113421, n_tokens = 113422, n_swa = 0, pos_next = 0, size = 387.162 MiB)
2026-05-15 18:45:48.797 | slot update_slots: id  2 | task 7795 | n_tokens = 0, memory_seq_rm [0, end)
2026-05-15 18:45:48.797 | slot update_slots: id  2 | task 7795 | prompt processing progress, n_tokens = 2048, batch.n_tokens = 2048, progress = 0.021629
2026-05-15 18:45:49.533 | slot update_slots: id  2 | task 7795 | n_tokens = 2048, memory_seq_rm [2048, end)
2026-05-15 18:45:49.533 | slot update_slots: id  2 | task 7795 | prompt processing progress, n_tokens = 4096, batch.n_tokens = 2048, progress = 0.043257
2026-05-15 18:45:50.258 | slot update_slots: id  2 | task 7795 | n_tokens = 4096, memory_seq_rm [4096, end)
2026-05-15 18:45:50.258 | slot update_slots: id  2 | task 7795 | prompt processing progress, n_tokens = 6144, batch.n_tokens = 2048, progress = 0.064886
2026-05-15 18:45:50.994 | slot update_slots: id  2 | task 7795 | n_tokens = 6144, memory_seq_rm [6144, end)
2026-05-15 18:45:50.994 | slot update_slots: id  2 | task 7795 | prompt processing progress, n_tokens = 8192, batch.n_tokens = 2048, progress = 0.086515
2026-05-15 18:45:51.741 | slot update_slots: id  2 | task 7795 | n_tokens = 8192, memory_seq_rm [8192, end)
2026-05-15 18:45:51.741 | slot update_slots: id  2 | task 7795 | 8192 tokens since last checkpoint at 0, creating new checkpoint during processing at position 10240
2026-05-15 18:45:51.741 | slot update_slots: id  2 | task 7795 | prompt processing progress, n_tokens = 10240, batch.n_tokens = 2048, progress = 0.108144
2026-05-15 18:45:51.861 | slot create_check: id  2 | task 7795 | created context checkpoint 1 of 32 (pos_min = 8191, pos_max = 8191, n_tokens = 8192, size = 166.782 MiB)
2026-05-15 18:45:52.635 | slot update_slots: id  2 | task 7795 | n_tokens = 10240, memory_seq_rm [10240, end)
2026-05-15 18:45:52.635 | slot update_slots: id  2 | task 7795 | prompt processing progress, n_tokens = 12288, batch.n_tokens = 2048, progress = 0.129772
2026-05-15 18:45:53.405 | slot update_slots: id  2 | task 7795 | n_tokens = 12288, memory_seq_rm [12288, end)
2026-05-15 18:45:53.406 | slot update_slots: id  2 | task 7795 | prompt processing progress, n_tokens = 14336, batch.n_tokens = 2048, progress = 0.151401
2026-05-15 18:45:54.187 | slot update_slots: id  2 | task 7795 | n_tokens = 14336, memory_seq_rm [14336, end)
2026-05-15 18:45:54.187 | slot update_slots: id  2 | task 7795 | prompt processing progress, n_tokens = 16384, batch.n_tokens = 2048, progress = 0.173030
2026-05-15 18:45:54.982 | slot update_slots: id  2 | task 7795 | n_tokens = 16384, memory_seq_rm [16384, end)
2026-05-15 18:45:54.982 | slot update_slots: id  2 | task 7795 | 8192 tokens since last checkpoint at 8192, creating new checkpoint during processing at position 18432
2026-05-15 18:45:54.982 | slot update_slots: id  2 | task 7795 | prompt processing progress, n_tokens = 18432, batch.n_tokens = 2048, progress = 0.194658
2026-05-15 18:45:55.130 | slot create_check: id  2 | task 7795 | created context checkpoint 2 of 32 (pos_min = 16383, pos_max = 16383, n_tokens = 16384, size = 183.939 MiB)
2026-05-15 18:45:55.935 | slot update_slots: id  2 | task 7795 | n_tokens = 18432, memory_seq_rm [18432, end)
2026-05-15 18:45:55.935 | slot update_slots: id  2 | task 7795 | prompt processing progress, n_tokens = 20480, batch.n_tokens = 2048, progress = 0.216287
2026-05-15 18:45:56.755 | slot update_slots: id  2 | task 7795 | n_tokens = 20480, memory_seq_rm [20480, end)
2026-05-15 18:45:56.755 | slot update_slots: id  2 | task 7795 | prompt processing progress, n_tokens = 22528, batch.n_tokens = 2048, progress = 0.237916
2026-05-15 18:45:57.588 | slot update_slots: id  2 | task 7795 | n_tokens = 22528, memory_seq_rm [22528, end)
2026-05-15 18:45:57.588 | slot update_slots: id  2 | task 7795 | prompt processing progress, n_tokens = 24576, batch.n_tokens = 2048, progress = 0.259544
2026-05-15 18:45:58.435 | slot update_slots: id  2 | task 7795 | n_tokens = 24576, memory_seq_rm [24576, end)
2026-05-15 18:45:58.436 | slot update_slots: id  2 | task 7795 | 8192 tokens since last checkpoint at 16384, creating new checkpoint during processing at position 26624
2026-05-15 18:45:58.436 | slot update_slots: id  2 | task 7795 | prompt processing progress, n_tokens = 26624, batch.n_tokens = 2048, progress = 0.281173
2026-05-15 18:45:58.594 | slot create_check: id  2 | task 7795 | created context checkpoint 3 of 32 (pos_min = 24575, pos_max = 24575, n_tokens = 24576, size = 201.095 MiB)
2026-05-15 18:45:59.454 | slot update_slots: id  2 | task 7795 | n_tokens = 26624, memory_seq_rm [26624, end)
2026-05-15 18:45:59.454 | slot update_slots: id  2 | task 7795 | prompt processing progress, n_tokens = 28672, batch.n_tokens = 2048, progress = 0.302802
2026-05-15 18:46:00.334 | slot update_slots: id  2 | task 7795 | n_tokens = 28672, memory_seq_rm [28672, end)
2026-05-15 18:46:00.334 | slot update_slots: id  2 | task 7795 | prompt processing progress, n_tokens = 30720, batch.n_tokens = 2048, progress = 0.324430
2026-05-15 18:46:01.235 | slot update_slots: id  2 | task 7795 | n_tokens = 30720, memory_seq_rm [30720, end)
2026-05-15 18:46:01.235 | slot update_slots: id  2 | task 7795 | prompt processing progress, n_tokens = 32768, batch.n_tokens = 2048, progress = 0.346059
2026-05-15 18:46:02.155 | slot update_slots: id  2 | task 7795 | n_tokens = 32768, memory_seq_rm [32768, end)
2026-05-15 18:46:02.155 | slot update_slots: id  2 | task 7795 | 8192 tokens since last checkpoint at 24576, creating new checkpoint during processing at position 34816
2026-05-15 18:46:02.155 | slot update_slots: id  2 | task 7795 | prompt processing progress, n_tokens = 34816, batch.n_tokens = 2048, progress = 0.367688
2026-05-15 18:46:02.380 | slot create_check: id  2 | task 7795 | created context checkpoint 4 of 32 (pos_min = 32767, pos_max = 32767, n_tokens = 32768, size = 218.251 MiB)
2026-05-15 18:46:03.314 | slot update_slots: id  2 | task 7795 | n_tokens = 34816, memory_seq_rm [34816, end)
2026-05-15 18:46:03.314 | slot update_slots: id  2 | task 7795 | prompt processing progress, n_tokens = 36864, batch.n_tokens = 2048, progress = 0.389317
2026-05-15 18:46:04.274 | slot update_slots: id  2 | task 7795 | n_tokens = 36864, memory_seq_rm [36864, end)
2026-05-15 18:46:04.274 | slot update_slots: id  2 | task 7795 | prompt processing progress, n_tokens = 38912, batch.n_tokens = 2048, progress = 0.410945
2026-05-15 18:46:05.259 | slot update_slots: id  2 | task 7795 | n_tokens = 38912, memory_seq_rm [38912, end)
2026-05-15 18:46:05.259 | slot update_slots: id  2 | task 7795 | prompt processing progress, n_tokens = 40960, batch.n_tokens = 2048, progress = 0.432574
2026-05-15 18:46:06.264 | slot update_slots: id  2 | task 7795 | n_tokens = 40960, memory_seq_rm [40960, end)
2026-05-15 18:46:06.264 | slot update_slots: id  2 | task 7795 | 8192 tokens since last checkpoint at 32768, creating new checkpoint during processing at position 43008
2026-05-15 18:46:06.264 | slot update_slots: id  2 | task 7795 | prompt processing progress, n_tokens = 43008, batch.n_tokens = 2048, progress = 0.454203
2026-05-15 18:46:06.517 | slot create_check: id  2 | task 7795 | created context checkpoint 5 of 32 (pos_min = 40959, pos_max = 40959, n_tokens = 40960, size = 235.407 MiB)
2026-05-15 18:46:07.543 | slot update_slots: id  2 | task 7795 | n_tokens = 43008, memory_seq_rm [43008, end)
2026-05-15 18:46:07.543 | slot update_slots: id  2 | task 7795 | prompt processing progress, n_tokens = 45056, batch.n_tokens = 2048, progress = 0.475831
2026-05-15 18:46:08.593 | slot update_slots: id  2 | task 7795 | n_tokens = 45056, memory_seq_rm [45056, end)
2026-05-15 18:46:08.593 | slot update_slots: id  2 | task 7795 | prompt processing progress, n_tokens = 47104, batch.n_tokens = 2048, progress = 0.497460
2026-05-15 18:46:09.676 | slot update_slots: id  2 | task 7795 | n_tokens = 47104, memory_seq_rm [47104, end)
2026-05-15 18:46:09.676 | slot update_slots: id  2 | task 7795 | prompt processing progress, n_tokens = 49152, batch.n_tokens = 2048, progress = 0.519089
2026-05-15 18:46:10.787 | slot update_slots: id  2 | task 7795 | n_tokens = 49152, memory_seq_rm [49152, end)
2026-05-15 18:46:10.788 | slot update_slots: id  2 | task 7795 | 8192 tokens since last checkpoint at 40960, creating new checkpoint during processing at position 51200
2026-05-15 18:46:10.788 | slot update_slots: id  2 | task 7795 | prompt processing progress, n_tokens = 51200, batch.n_tokens = 2048, progress = 0.540717
2026-05-15 18:46:11.076 | slot create_check: id  2 | task 7795 | created context checkpoint 6 of 32 (pos_min = 49151, pos_max = 49151, n_tokens = 49152, size = 252.564 MiB)
2026-05-15 18:46:12.220 | slot update_slots: id  2 | task 7795 | n_tokens = 51200, memory_seq_rm [51200, end)
2026-05-15 18:46:12.220 | slot update_slots: id  2 | task 7795 | prompt processing progress, n_tokens = 53248, batch.n_tokens = 2048, progress = 0.562346
2026-05-15 18:46:13.409 | slot update_slots: id  2 | task 7795 | n_tokens = 53248, memory_seq_rm [53248, end)
2026-05-15 18:46:13.409 | slot update_slots: id  2 | task 7795 | prompt processing progress, n_tokens = 55296, batch.n_tokens = 2048, progress = 0.583975
2026-05-15 18:46:14.605 | slot update_slots: id  2 | task 7795 | n_tokens = 55296, memory_seq_rm [55296, end)
2026-05-15 18:46:14.605 | slot update_slots: id  2 | task 7795 | prompt processing progress, n_tokens = 57344, batch.n_tokens = 2048, progress = 0.605604
2026-05-15 18:46:15.854 | slot update_slots: id  2 | task 7795 | n_tokens = 57344, memory_seq_rm [57344, end)
2026-05-15 18:46:15.854 | slot update_slots: id  2 | task 7795 | 8192 tokens since last checkpoint at 49152, creating new checkpoint during processing at position 59392
2026-05-15 18:46:15.854 | slot update_slots: id  2 | task 7795 | prompt processing progress, n_tokens = 59392, batch.n_tokens = 2048, progress = 0.627232
2026-05-15 18:46:16.300 | slot create_check: id  2 | task 7795 | created context checkpoint 7 of 32 (pos_min = 57343, pos_max = 57343, n_tokens = 57344, size = 269.720 MiB)
2026-05-15 18:46:17.564 | slot update_slots: id  2 | task 7795 | n_tokens = 59392, memory_seq_rm [59392, end)
2026-05-15 18:46:17.564 | slot update_slots: id  2 | task 7795 | prompt processing progress, n_tokens = 61440, batch.n_tokens = 2048, progress = 0.648861
2026-05-15 18:46:18.877 | slot update_slots: id  2 | task 7795 | n_tokens = 61440, memory_seq_rm [61440, end)
2026-05-15 18:46:18.877 | slot update_slots: id  2 | task 7795 | prompt processing progress, n_tokens = 63488, batch.n_tokens = 2048, progress = 0.670490
2026-05-15 18:46:20.228 | slot update_slots: id  2 | task 7795 | n_tokens = 63488, memory_seq_rm [63488, end)
2026-05-15 18:46:20.228 | slot update_slots: id  2 | task 7795 | prompt processing progress, n_tokens = 65536, batch.n_tokens = 2048, progress = 0.692118
2026-05-15 18:46:21.579 | slot update_slots: id  2 | task 7795 | n_tokens = 65536, memory_seq_rm [65536, end)
2026-05-15 18:46:21.579 | slot update_slots: id  2 | task 7795 | 8192 tokens since last checkpoint at 57344, creating new checkpoint during processing at position 67584
2026-05-15 18:46:21.579 | slot update_slots: id  2 | task 7795 | prompt processing progress, n_tokens = 67584, batch.n_tokens = 2048, progress = 0.713747
2026-05-15 18:46:21.901 | slot create_check: id  2 | task 7795 | created context checkpoint 8 of 32 (pos_min = 65535, pos_max = 65535, n_tokens = 65536, size = 286.876 MiB)
2026-05-15 18:46:23.277 | slot update_slots: id  2 | task 7795 | n_tokens = 67584, memory_seq_rm [67584, end)
2026-05-15 18:46:23.277 | slot update_slots: id  2 | task 7795 | prompt processing progress, n_tokens = 69632, batch.n_tokens = 2048, progress = 0.735376
2026-05-15 18:46:24.686 | slot update_slots: id  2 | task 7795 | n_tokens = 69632, memory_seq_rm [69632, end)
2026-05-15 18:46:24.686 | slot update_slots: id  2 | task 7795 | prompt processing progress, n_tokens = 71680, batch.n_tokens = 2048, progress = 0.757004
2026-05-15 18:46:26.116 | slot update_slots: id  2 | task 7795 | n_tokens = 71680, memory_seq_rm [71680, end)
2026-05-15 18:46:26.116 | slot update_slots: id  2 | task 7795 | prompt processing progress, n_tokens = 73728, batch.n_tokens = 2048, progress = 0.778633
2026-05-15 18:46:27.567 | slot update_slots: id  2 | task 7795 | n_tokens = 73728, memory_seq_rm [73728, end)
2026-05-15 18:46:27.567 | slot update_slots: id  2 | task 7795 | 8192 tokens since last checkpoint at 65536, creating new checkpoint during processing at position 75776
2026-05-15 18:46:27.567 | slot update_slots: id  2 | task 7795 | prompt processing progress, n_tokens = 75776, batch.n_tokens = 2048, progress = 0.800262
2026-05-15 18:46:27.909 | slot create_check: id  2 | task 7795 | created context checkpoint 9 of 32 (pos_min = 73727, pos_max = 73727, n_tokens = 73728, size = 304.032 MiB)
2026-05-15 18:46:29.381 | slot update_slots: id  2 | task 7795 | n_tokens = 75776, memory_seq_rm [75776, end)
2026-05-15 18:46:29.381 | slot update_slots: id  2 | task 7795 | prompt processing progress, n_tokens = 77824, batch.n_tokens = 2048, progress = 0.821891
2026-05-15 18:46:30.887 | slot update_slots: id  2 | task 7795 | n_tokens = 77824, memory_seq_rm [77824, end)
2026-05-15 18:46:30.887 | slot update_slots: id  2 | task 7795 | prompt processing progress, n_tokens = 79872, batch.n_tokens = 2048, progress = 0.843519
2026-05-15 18:46:32.434 | slot update_slots: id  2 | task 7795 | n_tokens = 79872, memory_seq_rm [79872, end)
2026-05-15 18:46:32.434 | slot update_slots: id  2 | task 7795 | prompt processing progress, n_tokens = 81920, batch.n_tokens = 2048, progress = 0.865148
2026-05-15 18:46:33.997 | slot update_slots: id  2 | task 7795 | n_tokens = 81920, memory_seq_rm [81920, end)
2026-05-15 18:46:33.997 | slot update_slots: id  2 | task 7795 | 8192 tokens since last checkpoint at 73728, creating new checkpoint during processing at position 83968
2026-05-15 18:46:33.997 | slot update_slots: id  2 | task 7795 | prompt processing progress, n_tokens = 83968, batch.n_tokens = 2048, progress = 0.886777
2026-05-15 18:46:34.392 | slot create_check: id  2 | task 7795 | created context checkpoint 10 of 32 (pos_min = 81919, pos_max = 81919, n_tokens = 81920, size = 321.189 MiB)
2026-05-15 18:46:35.979 | slot update_slots: id  2 | task 7795 | n_tokens = 83968, memory_seq_rm [83968, end)
2026-05-15 18:46:35.979 | slot update_slots: id  2 | task 7795 | prompt processing progress, n_tokens = 86016, batch.n_tokens = 2048, progress = 0.908405
2026-05-15 18:46:37.594 | slot update_slots: id  2 | task 7795 | n_tokens = 86016, memory_seq_rm [86016, end)
2026-05-15 18:46:37.594 | slot update_slots: id  2 | task 7795 | prompt processing progress, n_tokens = 88064, batch.n_tokens = 2048, progress = 0.930034
2026-05-15 18:46:39.239 | slot update_slots: id  2 | task 7795 | n_tokens = 88064, memory_seq_rm [88064, end)
2026-05-15 18:46:39.239 | slot update_slots: id  2 | task 7795 | prompt processing progress, n_tokens = 90112, batch.n_tokens = 2048, progress = 0.951663
2026-05-15 18:46:40.902 | slot update_slots: id  2 | task 7795 | n_tokens = 90112, memory_seq_rm [90112, end)
2026-05-15 18:46:40.902 | slot update_slots: id  2 | task 7795 | 8192 tokens since last checkpoint at 81920, creating new checkpoint during processing at position 92160
2026-05-15 18:46:40.902 | slot update_slots: id  2 | task 7795 | prompt processing progress, n_tokens = 92160, batch.n_tokens = 2048, progress = 0.973292
2026-05-15 18:46:41.269 | slot create_check: id  2 | task 7795 | created context checkpoint 11 of 32 (pos_min = 90111, pos_max = 90111, n_tokens = 90112, size = 338.345 MiB)
2026-05-15 18:46:42.943 | slot update_slots: id  2 | task 7795 | n_tokens = 92160, memory_seq_rm [92160, end)
2026-05-15 18:46:42.943 | slot update_slots: id  2 | task 7795 | prompt processing progress, n_tokens = 94173, batch.n_tokens = 2013, progress = 0.994551
2026-05-15 18:46:44.530 | slot update_slots: id  2 | task 7795 | n_tokens = 94173, memory_seq_rm [94173, end)
2026-05-15 18:46:44.530 | slot update_slots: id  2 | task 7795 | prompt processing progress, n_tokens = 94685, batch.n_tokens = 512, progress = 0.999958
2026-05-15 18:46:44.912 | slot create_check: id  2 | task 7795 | created context checkpoint 12 of 32 (pos_min = 94172, pos_max = 94172, n_tokens = 94173, size = 346.850 MiB)
2026-05-15 18:46:45.366 | slot update_slots: id  2 | task 7795 | n_tokens = 94685, memory_seq_rm [94685, end)
2026-05-15 18:46:45.378 | slot init_sampler: id  2 | task 7795 | init sampler, took 11.78 ms, tokens: text = 94689, total = 94689
2026-05-15 18:46:45.378 | slot update_slots: id  2 | task 7795 | prompt processing done, n_tokens = 94689, batch.n_tokens = 4
2026-05-15 18:46:45.764 | slot create_check: id  2 | task 7795 | created context checkpoint 13 of 32 (pos_min = 94684, pos_max = 94684, n_tokens = 94685, size = 347.922 MiB)
2026-05-15 18:46:45.806 | srv  log_server_r: done request: POST /v1/chat/completions 172.18.0.1 200
2026-05-15 18:46:47.544 | reasoning-budget: deactivated (natural end)
2026-05-15 18:46:50.612 | slot print_timing: id  2 | task 7795 | 
2026-05-15 18:46:50.612 | prompt eval time =   57617.31 ms / 94689 tokens (    0.61 ms per token,  1643.41 tokens per second)
2026-05-15 18:46:50.612 |        eval time =    4805.86 ms /   261 tokens (   18.41 ms per token,    54.31 tokens per second)
2026-05-15 18:46:50.612 |       total time =   62423.18 ms / 94950 tokens
2026-05-15 18:46:50.612 | draft acceptance rate = 0.99306 (  143 accepted /   144 generated)
2026-05-15 18:46:50.612 | statistics mtp: #calls(b,g,a) = 74 7183 6116, #gen drafts = 6116, #acc drafts = 6116, #gen tokens = 10825, #acc tokens = 10657, dur(b,g,a) = 0.099, 30603.597, 2.470 ms
2026-05-15 18:46:50.614 | slot      release: id  2 | task 7795 | stop processing: n_tokens = 94949, truncated = 0
2026-05-15 18:46:50.614 | srv  update_slots: all slots are idle
2026-05-15 18:46:50.883 | srv  params_from_: Chat format: peg-native
2026-05-15 18:46:50.885 | slot get_availabl: id  2 | task -1 | selected slot by LCP similarity, sim_best = 0.965 (> 0.100 thold), f_keep = 1.000
2026-05-15 18:46:50.887 | reasoning-budget: activated, budget=2147483647 tokens
2026-05-15 18:46:50.887 | slot launch_slot_: id  2 | task -1 | sampler chain: logits -> penalties -> ?dry -> ?top-n-sigma -> top-k -> ?typical -> ?top-p -> min-p -> ?xtc -> ?temp-ext -> dist 
2026-05-15 18:46:50.887 | slot launch_slot_: id  2 | task 7969 | processing task, is_child = 0
2026-05-15 18:46:50.887 | slot update_slots: id  2 | task 7969 | new prompt, n_ctx_slot = 131072, n_keep = 0, task.n_tokens = 98392
2026-05-15 18:46:50.887 | slot update_slots: id  2 | task 7969 | n_tokens = 94949, memory_seq_rm [94949, end)
2026-05-15 18:46:50.887 | slot update_slots: id  2 | task 7969 | prompt processing progress, n_tokens = 96997, batch.n_tokens = 2048, progress = 0.985822
2026-05-15 18:46:52.620 | slot update_slots: id  2 | task 7969 | n_tokens = 96997, memory_seq_rm [96997, end)
2026-05-15 18:46:52.620 | slot update_slots: id  2 | task 7969 | prompt processing progress, n_tokens = 97876, batch.n_tokens = 879, progress = 0.994756
2026-05-15 18:46:53.398 | slot update_slots: id  2 | task 7969 | n_tokens = 97876, memory_seq_rm [97876, end)
2026-05-15 18:46:53.398 | slot update_slots: id  2 | task 7969 | prompt processing progress, n_tokens = 98388, batch.n_tokens = 512, progress = 0.999959
2026-05-15 18:46:53.796 | slot create_check: id  2 | task 7969 | created context checkpoint 14 of 32 (pos_min = 97875, pos_max = 97875, n_tokens = 97876, size = 354.605 MiB)
2026-05-15 18:46:54.251 | slot update_slots: id  2 | task 7969 | n_tokens = 98388, memory_seq_rm [98388, end)
2026-05-15 18:46:54.263 | slot init_sampler: id  2 | task 7969 | init sampler, took 12.29 ms, tokens: text = 98392, total = 98392
2026-05-15 18:46:54.263 | slot update_slots: id  2 | task 7969 | prompt processing done, n_tokens = 98392, batch.n_tokens = 4
2026-05-15 18:46:54.645 | slot create_check: id  2 | task 7969 | created context checkpoint 15 of 32 (pos_min = 98387, pos_max = 98387, n_tokens = 98388, size = 355.677 MiB)
2026-05-15 18:46:54.688 | srv  log_server_r: done request: POST /v1/chat/completions 172.18.0.1 200
2026-05-15 18:46:55.987 | reasoning-budget: deactivated (natural end)
2026-05-15 18:46:58.033 | slot print_timing: id  2 | task 7969 | 
2026-05-15 18:46:58.033 | prompt eval time =    3800.55 ms /  3443 tokens (    1.10 ms per token,   905.92 tokens per second)
2026-05-15 18:46:58.033 |        eval time =    3345.46 ms /   185 tokens (   18.08 ms per token,    55.30 tokens per second)
2026-05-15 18:46:58.033 |       total time =    7146.01 ms /  3628 tokens
2026-05-15 18:46:58.033 | draft acceptance rate = 1.00000 (  105 accepted /   105 generated)
2026-05-15 18:46:58.033 | statistics mtp: #calls(b,g,a) = 75 7262 6176, #gen drafts = 6176, #acc drafts = 6176, #gen tokens = 10930, #acc tokens = 10762, dur(b,g,a) = 0.101, 30940.353, 2.503 ms
2026-05-15 18:46:58.035 | slot      release: id  2 | task 7969 | stop processing: n_tokens = 98576, truncated = 0
2026-05-15 18:46:58.035 | srv  update_slots: all slots are idle
2026-05-15 18:46:58.307 | srv  params_from_: Chat format: peg-native
2026-05-15 18:46:58.309 | slot get_availabl: id  2 | task -1 | selected slot by LCP similarity, sim_best = 0.890 (> 0.100 thold), f_keep = 1.000
2026-05-15 18:46:58.311 | reasoning-budget: activated, budget=2147483647 tokens
2026-05-15 18:46:58.311 | slot launch_slot_: id  2 | task -1 | sampler chain: logits -> penalties -> ?dry -> ?top-n-sigma -> top-k -> ?typical -> ?top-p -> min-p -> ?xtc -> ?temp-ext -> dist 
2026-05-15 18:46:58.311 | slot launch_slot_: id  2 | task 8057 | processing task, is_child = 0
2026-05-15 18:46:58.311 | slot update_slots: id  2 | task 8057 | new prompt, n_ctx_slot = 131072, n_keep = 0, task.n_tokens = 110727
2026-05-15 18:46:58.311 | slot update_slots: id  2 | task 8057 | n_tokens = 98576, memory_seq_rm [98576, end)
2026-05-15 18:46:58.311 | slot update_slots: id  2 | task 8057 | prompt processing progress, n_tokens = 100624, batch.n_tokens = 2048, progress = 0.908758
2026-05-15 18:47:00.093 | slot update_slots: id  2 | task 8057 | n_tokens = 100624, memory_seq_rm [100624, end)
2026-05-15 18:47:00.093 | slot update_slots: id  2 | task 8057 | prompt processing progress, n_tokens = 102672, batch.n_tokens = 2048, progress = 0.927254
2026-05-15 18:47:01.914 | slot update_slots: id  2 | task 8057 | n_tokens = 102672, memory_seq_rm [102672, end)
2026-05-15 18:47:01.914 | slot update_slots: id  2 | task 8057 | prompt processing progress, n_tokens = 104720, batch.n_tokens = 2048, progress = 0.945749
2026-05-15 18:47:03.766 | slot update_slots: id  2 | task 8057 | n_tokens = 104720, memory_seq_rm [104720, end)
2026-05-15 18:47:03.766 | slot update_slots: id  2 | task 8057 | prompt processing progress, n_tokens = 106768, batch.n_tokens = 2048, progress = 0.964245
2026-05-15 18:47:05.671 | slot update_slots: id  2 | task 8057 | n_tokens = 106768, memory_seq_rm [106768, end)
2026-05-15 18:47:05.671 | slot update_slots: id  2 | task 8057 | 8192 tokens since last checkpoint at 98388, creating new checkpoint during processing at position 108816
2026-05-15 18:47:05.671 | slot update_slots: id  2 | task 8057 | prompt processing progress, n_tokens = 108816, batch.n_tokens = 2048, progress = 0.982741
2026-05-15 18:47:06.082 | slot create_check: id  2 | task 8057 | created context checkpoint 16 of 32 (pos_min = 106767, pos_max = 106767, n_tokens = 106768, size = 373.227 MiB)
2026-05-15 18:47:07.975 | slot update_slots: id  2 | task 8057 | n_tokens = 108816, memory_seq_rm [108816, end)
2026-05-15 18:47:07.975 | slot update_slots: id  2 | task 8057 | prompt processing progress, n_tokens = 110211, batch.n_tokens = 1395, progress = 0.995340
2026-05-15 18:47:09.297 | slot update_slots: id  2 | task 8057 | n_tokens = 110211, memory_seq_rm [110211, end)
2026-05-15 18:47:09.297 | slot update_slots: id  2 | task 8057 | prompt processing progress, n_tokens = 110723, batch.n_tokens = 512, progress = 0.999964
2026-05-15 18:47:09.717 | slot create_check: id  2 | task 8057 | created context checkpoint 17 of 32 (pos_min = 110210, pos_max = 110210, n_tokens = 110211, size = 380.438 MiB)
2026-05-15 18:47:10.207 | slot update_slots: id  2 | task 8057 | n_tokens = 110723, memory_seq_rm [110723, end)
2026-05-15 18:47:10.221 | slot init_sampler: id  2 | task 8057 | init sampler, took 13.64 ms, tokens: text = 110727, total = 110727
2026-05-15 18:47:10.221 | slot update_slots: id  2 | task 8057 | prompt processing done, n_tokens = 110727, batch.n_tokens = 4
2026-05-15 18:47:10.644 | slot create_check: id  2 | task 8057 | created context checkpoint 18 of 32 (pos_min = 110722, pos_max = 110722, n_tokens = 110723, size = 381.510 MiB)
2026-05-15 18:47:10.687 | srv  log_server_r: done request: POST /v1/chat/completions 172.18.0.1 200
2026-05-15 18:47:11.862 | reasoning-budget: deactivated (natural end)
2026-05-15 18:47:14.230 | slot print_timing: id  2 | task 8057 | 
2026-05-15 18:47:14.230 | prompt eval time =   12375.93 ms / 12151 tokens (    1.02 ms per token,   981.82 tokens per second)
2026-05-15 18:47:14.230 |        eval time =    3543.37 ms /   186 tokens (   19.05 ms per token,    52.49 tokens per second)
2026-05-15 18:47:14.230 |       total time =   15919.31 ms / 12337 tokens
2026-05-15 18:47:14.230 | draft acceptance rate = 0.98077 (  102 accepted /   104 generated)
2026-05-15 18:47:14.230 | statistics mtp: #calls(b,g,a) = 76 7345 6231, #gen drafts = 6231, #acc drafts = 6231, #gen tokens = 11034, #acc tokens = 10864, dur(b,g,a) = 0.102, 31272.364, 2.529 ms
2026-05-15 18:47:14.233 | slot      release: id  2 | task 8057 | stop processing: n_tokens = 110912, truncated = 0
2026-05-15 18:47:14.233 | srv  update_slots: all slots are idle
2026-05-15 18:47:14.387 | srv  params_from_: Chat format: peg-native
2026-05-15 18:47:14.388 | slot get_availabl: id  1 | task -1 | selected slot by LRU, t_last = 1621123810
2026-05-15 18:47:14.388 | srv  get_availabl: updating prompt cache
2026-05-15 18:47:14.388 | srv          load:  - looking for better prompt, base f_keep = -1.000, sim = 0.000
2026-05-15 18:47:14.388 | srv        update:  - cache state: 1 prompts, 5081.948 MiB (limits: 8192.000 MiB, 131072 tokens, 131072 est)
2026-05-15 18:47:14.388 | srv        update:    - prompt 0x6487e6082f70:   64767 tokens, checkpoints: 11,  5081.948 MiB
2026-05-15 18:47:14.388 | srv  get_availabl: prompt cache update took 0.01 ms
2026-05-15 18:47:14.389 | slot launch_slot_: id  1 | task -1 | sampler chain: logits -> penalties -> ?dry -> ?top-n-sigma -> top-k -> ?typical -> ?top-p -> min-p -> ?xtc -> ?temp-ext -> dist 
2026-05-15 18:47:14.389 | slot launch_slot_: id  1 | task 8153 | processing task, is_child = 0
2026-05-15 18:47:14.389 | slot slot_save_an: id  2 | task -1 | saving idle slot to prompt cache
2026-05-15 18:47:14.393 | srv   prompt_save:  - saving prompt with length 110912, total state size = 4066.647 MiB (draft: 232.280 MiB)
2026-05-15 18:47:24.158 | slot prompt_clear: id  2 | task -1 | clearing prompt with 110912 tokens
2026-05-15 18:47:24.175 | srv        update:  - cache size limit reached, removing oldest entry (size = 5081.948 MiB)
2026-05-15 18:47:24.466 | srv        update:  - cache state: 1 prompts, 9385.075 MiB (limits: 8192.000 MiB, 131072 tokens, 131072 est)
2026-05-15 18:47:24.466 | srv        update:    - prompt 0x6487e9643e80:  110912 tokens, checkpoints: 18,  9385.075 MiB
2026-05-15 18:47:24.466 | slot update_slots: id  1 | task 8153 | new prompt, n_ctx_slot = 131072, n_keep = 0, task.n_tokens = 13607
2026-05-15 18:47:24.466 | slot update_slots: id  1 | task 8153 | erased invalidated context checkpoint (pos_min = 8191, pos_max = 8191, n_tokens = 8192, n_swa = 0, pos_next = 0, size = 166.782 MiB)
2026-05-15 18:47:24.475 | slot update_slots: id  1 | task 8153 | erased invalidated context checkpoint (pos_min = 15725, pos_max = 15725, n_tokens = 15726, n_swa = 0, pos_next = 0, size = 182.561 MiB)
2026-05-15 18:47:24.486 | slot update_slots: id  1 | task 8153 | erased invalidated context checkpoint (pos_min = 16237, pos_max = 16237, n_tokens = 16238, n_swa = 0, pos_next = 0, size = 183.633 MiB)
2026-05-15 18:47:24.498 | slot update_slots: id  1 | task 8153 | n_tokens = 0, memory_seq_rm [0, end)
2026-05-15 18:47:24.499 | slot update_slots: id  1 | task 8153 | prompt processing progress, n_tokens = 2048, batch.n_tokens = 2048, progress = 0.150511
2026-05-15 18:47:25.206 | slot update_slots: id  1 | task 8153 | n_tokens = 2048, memory_seq_rm [2048, end)
2026-05-15 18:47:25.206 | slot update_slots: id  1 | task 8153 | prompt processing progress, n_tokens = 4096, batch.n_tokens = 2048, progress = 0.301022
2026-05-15 18:47:25.924 | slot update_slots: id  1 | task 8153 | n_tokens = 4096, memory_seq_rm [4096, end)
2026-05-15 18:47:25.924 | slot update_slots: id  1 | task 8153 | prompt processing progress, n_tokens = 6144, batch.n_tokens = 2048, progress = 0.451532
2026-05-15 18:47:26.647 | slot update_slots: id  1 | task 8153 | n_tokens = 6144, memory_seq_rm [6144, end)
2026-05-15 18:47:26.647 | slot update_slots: id  1 | task 8153 | prompt processing progress, n_tokens = 8192, batch.n_tokens = 2048, progress = 0.602043
2026-05-15 18:47:27.381 | slot update_slots: id  1 | task 8153 | n_tokens = 8192, memory_seq_rm [8192, end)
2026-05-15 18:47:27.381 | slot update_slots: id  1 | task 8153 | 8192 tokens since last checkpoint at 0, creating new checkpoint during processing at position 10240
2026-05-15 18:47:27.381 | slot update_slots: id  1 | task 8153 | prompt processing progress, n_tokens = 10240, batch.n_tokens = 2048, progress = 0.752554
2026-05-15 18:47:27.507 | slot create_check: id  1 | task 8153 | created context checkpoint 1 of 32 (pos_min = 8191, pos_max = 8191, n_tokens = 8192, size = 166.782 MiB)
2026-05-15 18:47:28.260 | slot update_slots: id  1 | task 8153 | n_tokens = 10240, memory_seq_rm [10240, end)
2026-05-15 18:47:28.260 | slot update_slots: id  1 | task 8153 | prompt processing progress, n_tokens = 12288, batch.n_tokens = 2048, progress = 0.903065
2026-05-15 18:47:29.017 | slot update_slots: id  1 | task 8153 | n_tokens = 12288, memory_seq_rm [12288, end)
2026-05-15 18:47:29.017 | slot update_slots: id  1 | task 8153 | prompt processing progress, n_tokens = 13091, batch.n_tokens = 803, progress = 0.962078
2026-05-15 18:47:29.339 | slot update_slots: id  1 | task 8153 | n_tokens = 13091, memory_seq_rm [13091, end)
2026-05-15 18:47:29.339 | slot update_slots: id  1 | task 8153 | prompt processing progress, n_tokens = 13603, batch.n_tokens = 512, progress = 0.999706
2026-05-15 18:47:29.596 | slot create_check: id  1 | task 8153 | created context checkpoint 2 of 32 (pos_min = 13090, pos_max = 13090, n_tokens = 13091, size = 177.042 MiB)
2026-05-15 18:47:29.787 | slot update_slots: id  1 | task 8153 | n_tokens = 13603, memory_seq_rm [13603, end)
2026-05-15 18:47:29.788 | slot init_sampler: id  1 | task 8153 | init sampler, took 1.72 ms, tokens: text = 13607, total = 13607
2026-05-15 18:47:29.788 | slot update_slots: id  1 | task 8153 | prompt processing done, n_tokens = 13607, batch.n_tokens = 4
2026-05-15 18:47:29.974 | slot create_check: id  1 | task 8153 | created context checkpoint 3 of 32 (pos_min = 13602, pos_max = 13602, n_tokens = 13603, size = 178.115 MiB)
2026-05-15 18:47:30.007 | srv  log_server_r: done request: POST /v1/chat/completions 172.18.0.1 200
2026-05-15 18:47:54.410 | slot print_timing: id  1 | task 8153 | 
2026-05-15 18:47:54.410 | prompt eval time =    5541.01 ms / 13607 tokens (    0.41 ms per token,  2455.69 tokens per second)
2026-05-15 18:47:54.410 |        eval time =   24385.47 ms /  1525 tokens (   15.99 ms per token,    62.54 tokens per second)
2026-05-15 18:47:54.410 |       total time =   29926.48 ms / 15132 tokens
2026-05-15 18:47:54.410 | draft acceptance rate = 0.97503 (  820 accepted /   841 generated)
2026-05-15 18:47:54.410 | statistics mtp: #calls(b,g,a) = 77 8049 6712, #gen drafts = 6712, #acc drafts = 6712, #gen tokens = 11875, #acc tokens = 11684, dur(b,g,a) = 0.103, 33678.974, 2.738 ms
2026-05-15 18:47:54.410 | slot      release: id  1 | task 8153 | stop processing: n_tokens = 15131, truncated = 0
2026-05-15 18:47:54.410 | srv  update_slots: all slots are idle
2026-05-15 18:47:54.537 | srv  params_from_: Chat format: peg-native
2026-05-15 18:47:54.539 | slot get_availabl: id  0 | task -1 | selected slot by LRU, t_last = 4865731001
2026-05-15 18:47:54.539 | srv  get_availabl: updating prompt cache
2026-05-15 18:47:54.539 | srv          load:  - looking for better prompt, base f_keep = -1.000, sim = 0.000
2026-05-15 18:47:54.539 | srv        update:  - cache state: 1 prompts, 9385.075 MiB (limits: 8192.000 MiB, 131072 tokens, 131072 est)
2026-05-15 18:47:54.539 | srv        update:    - prompt 0x6487e9643e80:  110912 tokens, checkpoints: 18,  9385.075 MiB
2026-05-15 18:47:54.539 | srv  get_availabl: prompt cache update took 0.02 ms
2026-05-15 18:47:54.540 | reasoning-budget: activated, budget=2147483647 tokens
2026-05-15 18:47:54.540 | slot launch_slot_: id  0 | task -1 | sampler chain: logits -> penalties -> ?dry -> ?top-n-sigma -> top-k -> ?typical -> ?top-p -> min-p -> ?xtc -> ?temp-ext -> dist 
2026-05-15 18:47:54.540 | slot launch_slot_: id  0 | task 8924 | processing task, is_child = 0
2026-05-15 18:47:54.540 | slot slot_save_an: id  1 | task -1 | saving idle slot to prompt cache
2026-05-15 18:47:54.541 | srv   prompt_save:  - saving prompt with length 15131, total state size = 684.000 MiB (draft: 31.688 MiB)
2026-05-15 18:47:55.783 | slot prompt_clear: id  1 | task -1 | clearing prompt with 15131 tokens
2026-05-15 18:47:55.786 | srv        update:  - cache size limit reached, removing oldest entry (size = 9385.075 MiB)
2026-05-15 18:47:56.309 | srv        update:  - cache state: 1 prompts, 1205.939 MiB (limits: 8192.000 MiB, 131072 tokens, 131072 est)
2026-05-15 18:47:56.309 | srv        update:    - prompt 0x6487e7520220:   15131 tokens, checkpoints:  3,  1205.939 MiB
2026-05-15 18:47:56.309 | slot update_slots: id  0 | task 8924 | new prompt, n_ctx_slot = 131072, n_keep = 0, task.n_tokens = 5798
2026-05-15 18:47:56.309 | slot update_slots: id  0 | task 8924 | erased invalidated context checkpoint (pos_min = 4088, pos_max = 4088, n_tokens = 4089, n_swa = 0, pos_next = 0, size = 158.190 MiB)
2026-05-15 18:47:56.322 | slot update_slots: id  0 | task 8924 | erased invalidated context checkpoint (pos_min = 4600, pos_max = 4600, n_tokens = 4601, n_swa = 0, pos_next = 0, size = 159.262 MiB)
2026-05-15 18:47:56.333 | slot update_slots: id  0 | task 8924 | erased invalidated context checkpoint (pos_min = 6475, pos_max = 6475, n_tokens = 6476, n_swa = 0, pos_next = 0, size = 163.189 MiB)
2026-05-15 18:47:56.343 | slot update_slots: id  0 | task 8924 | erased invalidated context checkpoint (pos_min = 6987, pos_max = 6987, n_tokens = 6988, n_swa = 0, pos_next = 0, size = 164.261 MiB)
2026-05-15 18:47:56.353 | slot update_slots: id  0 | task 8924 | erased invalidated context checkpoint (pos_min = 15437, pos_max = 15437, n_tokens = 15438, n_swa = 0, pos_next = 0, size = 181.957 MiB)
2026-05-15 18:47:56.362 | slot update_slots: id  0 | task 8924 | erased invalidated context checkpoint (pos_min = 25667, pos_max = 25667, n_tokens = 25668, n_swa = 0, pos_next = 0, size = 203.382 MiB)
2026-05-15 18:47:56.373 | slot update_slots: id  0 | task 8924 | erased invalidated context checkpoint (pos_min = 28009, pos_max = 28009, n_tokens = 28010, n_swa = 0, pos_next = 0, size = 208.287 MiB)
2026-05-15 18:47:56.385 | slot update_slots: id  0 | task 8924 | erased invalidated context checkpoint (pos_min = 28521, pos_max = 28521, n_tokens = 28522, n_swa = 0, pos_next = 0, size = 209.359 MiB)
2026-05-15 18:47:56.397 | slot update_slots: id  0 | task 8924 | erased invalidated context checkpoint (pos_min = 36952, pos_max = 36952, n_tokens = 36953, n_swa = 0, pos_next = 0, size = 227.016 MiB)
2026-05-15 18:47:56.410 | slot update_slots: id  0 | task 8924 | erased invalidated context checkpoint (pos_min = 47182, pos_max = 47182, n_tokens = 47183, n_swa = 0, pos_next = 0, size = 248.440 MiB)
2026-05-15 18:47:56.424 | slot update_slots: id  0 | task 8924 | erased invalidated context checkpoint (pos_min = 56925, pos_max = 56925, n_tokens = 56926, n_swa = 0, pos_next = 0, size = 268.845 MiB)
2026-05-15 18:47:56.439 | slot update_slots: id  0 | task 8924 | erased invalidated context checkpoint (pos_min = 57437, pos_max = 57437, n_tokens = 57438, n_swa = 0, pos_next = 0, size = 269.917 MiB)
2026-05-15 18:47:56.454 | slot update_slots: id  0 | task 8924 | erased invalidated context checkpoint (pos_min = 65874, pos_max = 65874, n_tokens = 65875, n_swa = 0, pos_next = 0, size = 287.586 MiB)
2026-05-15 18:47:56.471 | slot update_slots: id  0 | task 8924 | erased invalidated context checkpoint (pos_min = 76101, pos_max = 76101, n_tokens = 76102, n_swa = 0, pos_next = 0, size = 309.004 MiB)
2026-05-15 18:47:56.489 | slot update_slots: id  0 | task 8924 | erased invalidated context checkpoint (pos_min = 78650, pos_max = 78650, n_tokens = 78651, n_swa = 0, pos_next = 0, size = 314.342 MiB)
2026-05-15 18:47:56.507 | slot update_slots: id  0 | task 8924 | erased invalidated context checkpoint (pos_min = 79162, pos_max = 79162, n_tokens = 79163, n_swa = 0, pos_next = 0, size = 315.415 MiB)
2026-05-15 18:47:56.525 | slot update_slots: id  0 | task 8924 | erased invalidated context checkpoint (pos_min = 87571, pos_max = 87571, n_tokens = 87572, n_swa = 0, pos_next = 0, size = 333.025 MiB)
2026-05-15 18:47:56.544 | slot update_slots: id  0 | task 8924 | n_tokens = 0, memory_seq_rm [0, end)
2026-05-15 18:47:56.544 | slot update_slots: id  0 | task 8924 | prompt processing progress, n_tokens = 2048, batch.n_tokens = 2048, progress = 0.353225
2026-05-15 18:47:57.256 | slot update_slots: id  0 | task 8924 | n_tokens = 2048, memory_seq_rm [2048, end)
2026-05-15 18:47:57.256 | slot update_slots: id  0 | task 8924 | prompt processing progress, n_tokens = 4096, batch.n_tokens = 2048, progress = 0.706451
2026-05-15 18:47:57.973 | slot update_slots: id  0 | task 8924 | n_tokens = 4096, memory_seq_rm [4096, end)
2026-05-15 18:47:57.973 | slot update_slots: id  0 | task 8924 | prompt processing progress, n_tokens = 5282, batch.n_tokens = 1186, progress = 0.911004
2026-05-15 18:47:58.416 | slot update_slots: id  0 | task 8924 | n_tokens = 5282, memory_seq_rm [5282, end)
2026-05-15 18:47:58.417 | slot update_slots: id  0 | task 8924 | prompt processing progress, n_tokens = 5794, batch.n_tokens = 512, progress = 0.999310
2026-05-15 18:47:58.537 | slot create_check: id  0 | task 8924 | created context checkpoint 1 of 32 (pos_min = 5281, pos_max = 5281, n_tokens = 5282, size = 160.688 MiB)
2026-05-15 18:47:58.716 | slot update_slots: id  0 | task 8924 | n_tokens = 5794, memory_seq_rm [5794, end)
2026-05-15 18:47:58.716 | slot init_sampler: id  0 | task 8924 | init sampler, took 0.78 ms, tokens: text = 5798, total = 5798
2026-05-15 18:47:58.716 | slot update_slots: id  0 | task 8924 | prompt processing done, n_tokens = 5798, batch.n_tokens = 4
2026-05-15 18:47:58.834 | slot create_check: id  0 | task 8924 | created context checkpoint 2 of 32 (pos_min = 5793, pos_max = 5793, n_tokens = 5794, size = 161.760 MiB)
2026-05-15 18:47:58.865 | srv  log_server_r: done request: POST /v1/chat/completions 172.18.0.1 200
2026-05-15 18:47:59.937 | reasoning-budget: deactivated (natural end)
2026-05-15 18:48:02.339 | slot print_timing: id  0 | task 8924 | 
2026-05-15 18:48:02.339 | prompt eval time =    2555.81 ms /  5798 tokens (    0.44 ms per token,  2268.56 tokens per second)
2026-05-15 18:48:02.339 |        eval time =    3473.20 ms /   231 tokens (   15.04 ms per token,    66.51 tokens per second)
2026-05-15 18:48:02.339 |       total time =    6029.01 ms /  6029 tokens
2026-05-15 18:48:02.339 | draft acceptance rate = 0.96403 (  134 accepted /   139 generated)
2026-05-15 18:48:02.339 | statistics mtp: #calls(b,g,a) = 78 8145 6789, #gen drafts = 6789, #acc drafts = 6789, #gen tokens = 12014, #acc tokens = 11818, dur(b,g,a) = 0.104, 34031.874, 2.768 ms
2026-05-15 18:48:02.339 | slot      release: id  0 | task 8924 | stop processing: n_tokens = 6028, truncated = 0
2026-05-15 18:48:02.339 | srv  update_slots: all slots are idle
2026-05-15 18:48:02.476 | srv  params_from_: Chat format: peg-native
2026-05-15 18:48:02.478 | slot get_availabl: id  0 | task -1 | selected slot by LCP similarity, sim_best = 0.776 (> 0.100 thold), f_keep = 1.000
2026-05-15 18:48:02.479 | reasoning-budget: activated, budget=2147483647 tokens
2026-05-15 18:48:02.479 | slot launch_slot_: id  0 | task -1 | sampler chain: logits -> penalties -> ?dry -> ?top-n-sigma -> top-k -> ?typical -> ?top-p -> min-p -> ?xtc -> ?temp-ext -> dist 
2026-05-15 18:48:02.479 | slot launch_slot_: id  0 | task 9036 | processing task, is_child = 0
2026-05-15 18:48:02.479 | slot update_slots: id  0 | task 9036 | new prompt, n_ctx_slot = 131072, n_keep = 0, task.n_tokens = 7773
2026-05-15 18:48:02.479 | slot update_slots: id  0 | task 9036 | n_tokens = 6028, memory_seq_rm [6028, end)
2026-05-15 18:48:02.479 | slot update_slots: id  0 | task 9036 | prompt processing progress, n_tokens = 7257, batch.n_tokens = 1229, progress = 0.933616
2026-05-15 18:48:02.948 | slot update_slots: id  0 | task 9036 | n_tokens = 7257, memory_seq_rm [7257, end)
2026-05-15 18:48:02.948 | slot update_slots: id  0 | task 9036 | prompt processing progress, n_tokens = 7769, batch.n_tokens = 512, progress = 0.999485
2026-05-15 18:48:03.072 | slot create_check: id  0 | task 9036 | created context checkpoint 3 of 32 (pos_min = 7256, pos_max = 7256, n_tokens = 7257, size = 164.824 MiB)
2026-05-15 18:48:03.260 | slot update_slots: id  0 | task 9036 | n_tokens = 7769, memory_seq_rm [7769, end)
2026-05-15 18:48:03.261 | slot init_sampler: id  0 | task 9036 | init sampler, took 1.05 ms, tokens: text = 7773, total = 7773
2026-05-15 18:48:03.261 | slot update_slots: id  0 | task 9036 | prompt processing done, n_tokens = 7773, batch.n_tokens = 4
2026-05-15 18:48:03.383 | slot create_check: id  0 | task 9036 | created context checkpoint 4 of 32 (pos_min = 7768, pos_max = 7768, n_tokens = 7769, size = 165.897 MiB)
2026-05-15 18:48:03.419 | srv  log_server_r: done request: POST /v1/chat/completions 172.18.0.1 200
2026-05-15 18:48:04.130 | reasoning-budget: deactivated (natural end)
2026-05-15 18:48:05.940 | slot print_timing: id  0 | task 9036 | 
2026-05-15 18:48:05.940 | prompt eval time =     938.66 ms /  1745 tokens (    0.54 ms per token,  1859.02 tokens per second)
2026-05-15 18:48:05.940 |        eval time =    2522.09 ms /   196 tokens (   12.87 ms per token,    77.71 tokens per second)
2026-05-15 18:48:05.940 |       total time =    3460.75 ms /  1941 tokens
2026-05-15 18:48:05.940 | draft acceptance rate = 0.99180 (  121 accepted /   122 generated)
2026-05-15 18:48:05.940 | statistics mtp: #calls(b,g,a) = 79 8219 6853, #gen drafts = 6853, #acc drafts = 6853, #gen tokens = 12136, #acc tokens = 11939, dur(b,g,a) = 0.105, 34328.876, 2.797 ms
2026-05-15 18:48:05.941 | slot      release: id  0 | task 9036 | stop processing: n_tokens = 7968, truncated = 0
2026-05-15 18:48:05.941 | srv  update_slots: all slots are idle
2026-05-15 18:48:06.064 | srv  params_from_: Chat format: peg-native
2026-05-15 18:48:06.066 | slot get_availabl: id  0 | task -1 | selected slot by LCP similarity, sim_best = 0.974 (> 0.100 thold), f_keep = 1.000
2026-05-15 18:48:06.068 | reasoning-budget: activated, budget=2147483647 tokens
2026-05-15 18:48:06.068 | slot launch_slot_: id  0 | task -1 | sampler chain: logits -> penalties -> ?dry -> ?top-n-sigma -> top-k -> ?typical -> ?top-p -> min-p -> ?xtc -> ?temp-ext -> dist 
2026-05-15 18:48:06.068 | slot launch_slot_: id  0 | task 9118 | processing task, is_child = 0
2026-05-15 18:48:06.068 | slot update_slots: id  0 | task 9118 | new prompt, n_ctx_slot = 131072, n_keep = 0, task.n_tokens = 8180
2026-05-15 18:48:06.068 | slot update_slots: id  0 | task 9118 | n_tokens = 7968, memory_seq_rm [7968, end)
2026-05-15 18:48:06.068 | slot update_slots: id  0 | task 9118 | prompt processing progress, n_tokens = 8176, batch.n_tokens = 208, progress = 0.999511
2026-05-15 18:48:06.190 | slot create_check: id  0 | task 9118 | created context checkpoint 5 of 32 (pos_min = 7967, pos_max = 7967, n_tokens = 7968, size = 166.313 MiB)
2026-05-15 18:48:06.285 | slot update_slots: id  0 | task 9118 | n_tokens = 8176, memory_seq_rm [8176, end)
2026-05-15 18:48:06.286 | slot init_sampler: id  0 | task 9118 | init sampler, took 1.09 ms, tokens: text = 8180, total = 8180
2026-05-15 18:48:06.286 | slot update_slots: id  0 | task 9118 | prompt processing done, n_tokens = 8180, batch.n_tokens = 4
2026-05-15 18:48:06.407 | slot create_check: id  0 | task 9118 | created context checkpoint 6 of 32 (pos_min = 8175, pos_max = 8175, n_tokens = 8176, size = 166.749 MiB)
2026-05-15 18:48:06.441 | srv  log_server_r: done request: POST /v1/chat/completions 172.18.0.1 200
2026-05-15 18:48:07.753 | reasoning-budget: deactivated (natural end)
2026-05-15 18:48:10.529 | slot print_timing: id  0 | task 9118 | 
2026-05-15 18:48:10.529 | prompt eval time =     372.19 ms /   212 tokens (    1.76 ms per token,   569.60 tokens per second)
2026-05-15 18:48:10.529 |        eval time =    4088.15 ms /   259 tokens (   15.78 ms per token,    63.35 tokens per second)
2026-05-15 18:48:10.529 |       total time =    4460.34 ms /   471 tokens
2026-05-15 18:48:10.529 | draft acceptance rate = 0.98675 (  149 accepted /   151 generated)
2026-05-15 18:48:10.529 | statistics mtp: #calls(b,g,a) = 80 8328 6940, #gen drafts = 6940, #acc drafts = 6940, #gen tokens = 12287, #acc tokens = 12088, dur(b,g,a) = 0.107, 34753.350, 2.849 ms
2026-05-15 18:48:10.529 | slot      release: id  0 | task 9118 | stop processing: n_tokens = 8438, truncated = 0
2026-05-15 18:48:10.529 | srv  update_slots: all slots are idle
2026-05-15 18:48:10.681 | srv  params_from_: Chat format: peg-native
2026-05-15 18:48:10.683 | slot get_availabl: id  0 | task -1 | selected slot by LCP similarity, sim_best = 0.480 (> 0.100 thold), f_keep = 1.000
2026-05-15 18:48:10.684 | reasoning-budget: activated, budget=2147483647 tokens
2026-05-15 18:48:10.685 | slot launch_slot_: id  0 | task -1 | sampler chain: logits -> penalties -> ?dry -> ?top-n-sigma -> top-k -> ?typical -> ?top-p -> min-p -> ?xtc -> ?temp-ext -> dist 
2026-05-15 18:48:10.685 | slot launch_slot_: id  0 | task 9239 | processing task, is_child = 0
2026-05-15 18:48:10.685 | slot update_slots: id  0 | task 9239 | new prompt, n_ctx_slot = 131072, n_keep = 0, task.n_tokens = 17580
2026-05-15 18:48:10.685 | slot update_slots: id  0 | task 9239 | n_tokens = 8438, memory_seq_rm [8438, end)
2026-05-15 18:48:10.685 | slot update_slots: id  0 | task 9239 | prompt processing progress, n_tokens = 10486, batch.n_tokens = 2048, progress = 0.596473
2026-05-15 18:48:11.452 | slot update_slots: id  0 | task 9239 | n_tokens = 10486, memory_seq_rm [10486, end)
2026-05-15 18:48:11.452 | slot update_slots: id  0 | task 9239 | prompt processing progress, n_tokens = 12534, batch.n_tokens = 2048, progress = 0.712969
2026-05-15 18:48:12.225 | slot update_slots: id  0 | task 9239 | n_tokens = 12534, memory_seq_rm [12534, end)
2026-05-15 18:48:12.226 | slot update_slots: id  0 | task 9239 | prompt processing progress, n_tokens = 14582, batch.n_tokens = 2048, progress = 0.829465
2026-05-15 18:48:13.004 | slot update_slots: id  0 | task 9239 | n_tokens = 14582, memory_seq_rm [14582, end)
2026-05-15 18:48:13.004 | slot update_slots: id  0 | task 9239 | prompt processing progress, n_tokens = 16630, batch.n_tokens = 2048, progress = 0.945961
2026-05-15 18:48:13.800 | slot update_slots: id  0 | task 9239 | n_tokens = 16630, memory_seq_rm [16630, end)
2026-05-15 18:48:13.800 | slot update_slots: id  0 | task 9239 | 8192 tokens since last checkpoint at 8176, creating new checkpoint during processing at position 17064
2026-05-15 18:48:13.800 | slot update_slots: id  0 | task 9239 | prompt processing progress, n_tokens = 17064, batch.n_tokens = 434, progress = 0.970648
2026-05-15 18:48:13.940 | slot create_check: id  0 | task 9239 | created context checkpoint 7 of 32 (pos_min = 16629, pos_max = 16629, n_tokens = 16630, size = 184.454 MiB)
2026-05-15 18:48:14.115 | slot update_slots: id  0 | task 9239 | n_tokens = 17064, memory_seq_rm [17064, end)
2026-05-15 18:48:14.115 | slot update_slots: id  0 | task 9239 | prompt processing progress, n_tokens = 17576, batch.n_tokens = 512, progress = 0.999772
2026-05-15 18:48:14.330 | slot create_check: id  0 | task 9239 | created context checkpoint 8 of 32 (pos_min = 17063, pos_max = 17063, n_tokens = 17064, size = 185.363 MiB)
2026-05-15 18:48:14.530 | slot update_slots: id  0 | task 9239 | n_tokens = 17576, memory_seq_rm [17576, end)
2026-05-15 18:48:14.533 | slot init_sampler: id  0 | task 9239 | init sampler, took 2.32 ms, tokens: text = 17580, total = 17580
2026-05-15 18:48:14.533 | slot update_slots: id  0 | task 9239 | prompt processing done, n_tokens = 17580, batch.n_tokens = 4
2026-05-15 18:48:14.754 | slot create_check: id  0 | task 9239 | created context checkpoint 9 of 32 (pos_min = 17575, pos_max = 17575, n_tokens = 17576, size = 186.435 MiB)
2026-05-15 18:48:14.788 | srv  log_server_r: done request: POST /v1/chat/completions 172.18.0.1 200
2026-05-15 18:48:17.669 | reasoning-budget: deactivated (natural end)
2026-05-15 18:48:19.966 | slot print_timing: id  0 | task 9239 | 
2026-05-15 18:48:19.966 | prompt eval time =    4103.08 ms /  9142 tokens (    0.45 ms per token,  2228.08 tokens per second)
2026-05-15 18:48:19.966 |        eval time =    5158.65 ms /   327 tokens (   15.78 ms per token,    63.39 tokens per second)
2026-05-15 18:48:19.966 |       total time =    9261.73 ms /  9469 tokens
2026-05-15 18:48:19.966 | draft acceptance rate = 0.98404 (  185 accepted /   188 generated)
2026-05-15 18:48:19.966 | statistics mtp: #calls(b,g,a) = 81 8469 7049, #gen drafts = 7049, #acc drafts = 7049, #gen tokens = 12475, #acc tokens = 12273, dur(b,g,a) = 0.109, 35306.221, 2.897 ms
2026-05-15 18:48:19.966 | slot      release: id  0 | task 9239 | stop processing: n_tokens = 17906, truncated = 0
2026-05-15 18:48:19.966 | srv  update_slots: all slots are idle
2026-05-15 18:48:21.908 | srv  params_from_: Chat format: peg-native
2026-05-15 18:48:21.911 | slot get_availabl: id  0 | task -1 | selected slot by LCP similarity, sim_best = 0.996 (> 0.100 thold), f_keep = 1.000
2026-05-15 18:48:21.912 | reasoning-budget: activated, budget=2147483647 tokens
2026-05-15 18:48:21.912 | slot launch_slot_: id  0 | task -1 | sampler chain: logits -> penalties -> ?dry -> ?top-n-sigma -> top-k -> ?typical -> ?top-p -> min-p -> ?xtc -> ?temp-ext -> dist 
2026-05-15 18:48:21.912 | slot launch_slot_: id  0 | task 9396 | processing task, is_child = 0
2026-05-15 18:48:21.912 | slot update_slots: id  0 | task 9396 | new prompt, n_ctx_slot = 131072, n_keep = 0, task.n_tokens = 17982
2026-05-15 18:48:21.912 | slot update_slots: id  0 | task 9396 | n_tokens = 17906, memory_seq_rm [17906, end)
2026-05-15 18:48:21.912 | slot update_slots: id  0 | task 9396 | prompt processing progress, n_tokens = 17978, batch.n_tokens = 72, progress = 0.999778
2026-05-15 18:48:22.117 | slot create_check: id  0 | task 9396 | created context checkpoint 10 of 32 (pos_min = 17905, pos_max = 17905, n_tokens = 17906, size = 187.126 MiB)
2026-05-15 18:48:22.191 | slot update_slots: id  0 | task 9396 | n_tokens = 17978, memory_seq_rm [17978, end)
2026-05-15 18:48:22.193 | slot init_sampler: id  0 | task 9396 | init sampler, took 2.38 ms, tokens: text = 17982, total = 17982
2026-05-15 18:48:22.193 | slot update_slots: id  0 | task 9396 | prompt processing done, n_tokens = 17982, batch.n_tokens = 4
2026-05-15 18:48:22.417 | slot create_check: id  0 | task 9396 | created context checkpoint 11 of 32 (pos_min = 17977, pos_max = 17977, n_tokens = 17978, size = 187.277 MiB)
2026-05-15 18:48:22.459 | srv  log_server_r: done request: POST /v1/chat/completions 172.18.0.1 200
2026-05-15 18:48:23.145 | reasoning-budget: deactivated (natural end)
2026-05-15 18:48:24.405 | slot print_timing: id  0 | task 9396 | 
2026-05-15 18:48:24.405 | prompt eval time =     546.63 ms /    76 tokens (    7.19 ms per token,   139.03 tokens per second)
2026-05-15 18:48:24.405 |        eval time =    1945.64 ms /   133 tokens (   14.63 ms per token,    68.36 tokens per second)
2026-05-15 18:48:24.405 |       total time =    2492.27 ms /   209 tokens
2026-05-15 18:48:24.405 | draft acceptance rate = 1.00000 (   76 accepted /    76 generated)
2026-05-15 18:48:24.405 | statistics mtp: #calls(b,g,a) = 82 8525 7092, #gen drafts = 7092, #acc drafts = 7092, #gen tokens = 12551, #acc tokens = 12349, dur(b,g,a) = 0.111, 35522.425, 2.923 ms
2026-05-15 18:48:24.405 | slot      release: id  0 | task 9396 | stop processing: n_tokens = 18114, truncated = 0
2026-05-15 18:48:24.405 | srv  update_slots: all slots are idle
2026-05-15 18:48:24.564 | srv  params_from_: Chat format: peg-native
2026-05-15 18:48:24.566 | slot get_availabl: id  0 | task -1 | selected slot by LCP similarity, sim_best = 0.862 (> 0.100 thold), f_keep = 1.000
2026-05-15 18:48:24.567 | reasoning-budget: activated, budget=2147483647 tokens
2026-05-15 18:48:24.567 | slot launch_slot_: id  0 | task -1 | sampler chain: logits -> penalties -> ?dry -> ?top-n-sigma -> top-k -> ?typical -> ?top-p -> min-p -> ?xtc -> ?temp-ext -> dist 
2026-05-15 18:48:24.567 | slot launch_slot_: id  0 | task 9457 | processing task, is_child = 0
2026-05-15 18:48:24.567 | slot update_slots: id  0 | task 9457 | new prompt, n_ctx_slot = 131072, n_keep = 0, task.n_tokens = 21024
2026-05-15 18:48:24.567 | slot update_slots: id  0 | task 9457 | n_tokens = 18114, memory_seq_rm [18114, end)
2026-05-15 18:48:24.567 | slot update_slots: id  0 | task 9457 | prompt processing progress, n_tokens = 20162, batch.n_tokens = 2048, progress = 0.958999
2026-05-15 18:48:25.374 | slot update_slots: id  0 | task 9457 | n_tokens = 20162, memory_seq_rm [20162, end)
2026-05-15 18:48:25.374 | slot update_slots: id  0 | task 9457 | prompt processing progress, n_tokens = 20508, batch.n_tokens = 346, progress = 0.975457
2026-05-15 18:48:25.529 | slot update_slots: id  0 | task 9457 | n_tokens = 20508, memory_seq_rm [20508, end)
2026-05-15 18:48:25.529 | slot update_slots: id  0 | task 9457 | prompt processing progress, n_tokens = 21020, batch.n_tokens = 512, progress = 0.999810
2026-05-15 18:48:25.746 | slot create_check: id  0 | task 9457 | created context checkpoint 12 of 32 (pos_min = 20507, pos_max = 20507, n_tokens = 20508, size = 192.575 MiB)
2026-05-15 18:48:25.949 | slot update_slots: id  0 | task 9457 | n_tokens = 21020, memory_seq_rm [21020, end)
2026-05-15 18:48:25.952 | slot init_sampler: id  0 | task 9457 | init sampler, took 2.73 ms, tokens: text = 21024, total = 21024
2026-05-15 18:48:25.952 | slot update_slots: id  0 | task 9457 | prompt processing done, n_tokens = 21024, batch.n_tokens = 4
2026-05-15 18:48:26.167 | slot create_check: id  0 | task 9457 | created context checkpoint 13 of 32 (pos_min = 21019, pos_max = 21019, n_tokens = 21020, size = 193.648 MiB)
2026-05-15 18:48:26.201 | srv  log_server_r: done request: POST /v1/chat/completions 172.18.0.1 200
2026-05-15 18:48:26.758 | reasoning-budget: deactivated (natural end)
2026-05-15 18:48:27.866 | slot print_timing: id  0 | task 9457 | 
2026-05-15 18:48:27.866 | prompt eval time =    1633.37 ms /  2910 tokens (    0.56 ms per token,  1781.59 tokens per second)
2026-05-15 18:48:27.866 |        eval time =    1664.90 ms /   123 tokens (   13.54 ms per token,    73.88 tokens per second)
2026-05-15 18:48:27.866 |       total time =    3298.27 ms /  3033 tokens
2026-05-15 18:48:27.866 | draft acceptance rate = 0.98667 (   74 accepted /    75 generated)
2026-05-15 18:48:27.866 | statistics mtp: #calls(b,g,a) = 83 8573 7133, #gen drafts = 7133, #acc drafts = 7133, #gen tokens = 12626, #acc tokens = 12423, dur(b,g,a) = 0.112, 35705.222, 2.940 ms
2026-05-15 18:48:27.866 | slot      release: id  0 | task 9457 | stop processing: n_tokens = 21146, truncated = 0
2026-05-15 18:48:27.866 | srv  update_slots: all slots are idle
2026-05-15 18:48:28.030 | srv  params_from_: Chat format: peg-native
2026-05-15 18:48:28.032 | slot get_availabl: id  0 | task -1 | selected slot by LCP similarity, sim_best = 0.693 (> 0.100 thold), f_keep = 1.000
2026-05-15 18:48:28.033 | reasoning-budget: activated, budget=2147483647 tokens
2026-05-15 18:48:28.033 | slot launch_slot_: id  0 | task -1 | sampler chain: logits -> penalties -> ?dry -> ?top-n-sigma -> top-k -> ?typical -> ?top-p -> min-p -> ?xtc -> ?temp-ext -> dist 
2026-05-15 18:48:28.033 | slot launch_slot_: id  0 | task 9512 | processing task, is_child = 0
2026-05-15 18:48:28.033 | slot update_slots: id  0 | task 9512 | new prompt, n_ctx_slot = 131072, n_keep = 0, task.n_tokens = 30505
2026-05-15 18:48:28.033 | slot update_slots: id  0 | task 9512 | n_tokens = 21146, memory_seq_rm [21146, end)
2026-05-15 18:48:28.033 | slot update_slots: id  0 | task 9512 | prompt processing progress, n_tokens = 23194, batch.n_tokens = 2048, progress = 0.760334
2026-05-15 18:48:28.862 | slot update_slots: id  0 | task 9512 | n_tokens = 23194, memory_seq_rm [23194, end)
2026-05-15 18:48:28.862 | slot update_slots: id  0 | task 9512 | prompt processing progress, n_tokens = 25242, batch.n_tokens = 2048, progress = 0.827471
2026-05-15 18:48:29.710 | slot update_slots: id  0 | task 9512 | n_tokens = 25242, memory_seq_rm [25242, end)
2026-05-15 18:48:29.710 | slot update_slots: id  0 | task 9512 | prompt processing progress, n_tokens = 27290, batch.n_tokens = 2048, progress = 0.894607
2026-05-15 18:48:30.573 | slot update_slots: id  0 | task 9512 | n_tokens = 27290, memory_seq_rm [27290, end)
2026-05-15 18:48:30.573 | slot update_slots: id  0 | task 9512 | prompt processing progress, n_tokens = 29338, batch.n_tokens = 2048, progress = 0.961744
2026-05-15 18:48:31.455 | slot update_slots: id  0 | task 9512 | n_tokens = 29338, memory_seq_rm [29338, end)
2026-05-15 18:48:31.455 | slot update_slots: id  0 | task 9512 | 8192 tokens since last checkpoint at 21020, creating new checkpoint during processing at position 29989
2026-05-15 18:48:31.455 | slot update_slots: id  0 | task 9512 | prompt processing progress, n_tokens = 29989, batch.n_tokens = 651, progress = 0.983085
2026-05-15 18:48:31.685 | slot create_check: id  0 | task 9512 | created context checkpoint 14 of 32 (pos_min = 29337, pos_max = 29337, n_tokens = 29338, size = 211.068 MiB)
2026-05-15 18:48:31.999 | slot update_slots: id  0 | task 9512 | n_tokens = 29989, memory_seq_rm [29989, end)
2026-05-15 18:48:31.999 | slot update_slots: id  0 | task 9512 | prompt processing progress, n_tokens = 30501, batch.n_tokens = 512, progress = 0.999869
2026-05-15 18:48:32.234 | slot create_check: id  0 | task 9512 | created context checkpoint 15 of 32 (pos_min = 29988, pos_max = 29988, n_tokens = 29989, size = 212.431 MiB)
2026-05-15 18:48:32.460 | slot update_slots: id  0 | task 9512 | n_tokens = 30501, memory_seq_rm [30501, end)
2026-05-15 18:48:32.464 | slot init_sampler: id  0 | task 9512 | init sampler, took 3.89 ms, tokens: text = 30505, total = 30505
2026-05-15 18:48:32.464 | slot update_slots: id  0 | task 9512 | prompt processing done, n_tokens = 30505, batch.n_tokens = 4
2026-05-15 18:48:32.697 | slot create_check: id  0 | task 9512 | created context checkpoint 16 of 32 (pos_min = 30500, pos_max = 30500, n_tokens = 30501, size = 213.503 MiB)
2026-05-15 18:48:32.732 | srv  log_server_r: done request: POST /v1/chat/completions 172.18.0.1 200
2026-05-15 18:48:34.205 | reasoning-budget: deactivated (natural end)
2026-05-15 18:48:35.683 | slot print_timing: id  0 | task 9512 | 
2026-05-15 18:48:35.683 | prompt eval time =    4698.42 ms /  9359 tokens (    0.50 ms per token,  1991.95 tokens per second)
2026-05-15 18:48:35.683 |        eval time =    2951.14 ms /   186 tokens (   15.87 ms per token,    63.03 tokens per second)
2026-05-15 18:48:35.683 |       total time =    7649.56 ms /  9545 tokens
2026-05-15 18:48:35.683 | draft acceptance rate = 0.97170 (  103 accepted /   106 generated)
2026-05-15 18:48:35.683 | statistics mtp: #calls(b,g,a) = 84 8655 7195, #gen drafts = 7195, #acc drafts = 7195, #gen tokens = 12732, #acc tokens = 12526, dur(b,g,a) = 0.114, 36004.264, 2.960 ms
2026-05-15 18:48:35.684 | slot      release: id  0 | task 9512 | stop processing: n_tokens = 30690, truncated = 0
2026-05-15 18:48:35.684 | srv  update_slots: all slots are idle
2026-05-15 18:48:35.868 | srv  params_from_: Chat format: peg-native
2026-05-15 18:48:35.870 | slot get_availabl: id  0 | task -1 | selected slot by LCP similarity, sim_best = 0.702 (> 0.100 thold), f_keep = 1.000
2026-05-15 18:48:35.871 | reasoning-budget: activated, budget=2147483647 tokens
2026-05-15 18:48:35.871 | slot launch_slot_: id  0 | task -1 | sampler chain: logits -> penalties -> ?dry -> ?top-n-sigma -> top-k -> ?typical -> ?top-p -> min-p -> ?xtc -> ?temp-ext -> dist 
2026-05-15 18:48:35.871 | slot launch_slot_: id  0 | task 9607 | processing task, is_child = 0
2026-05-15 18:48:35.871 | slot update_slots: id  0 | task 9607 | new prompt, n_ctx_slot = 131072, n_keep = 0, task.n_tokens = 43732
2026-05-15 18:48:35.872 | slot update_slots: id  0 | task 9607 | n_tokens = 30690, memory_seq_rm [30690, end)
2026-05-15 18:48:35.872 | slot update_slots: id  0 | task 9607 | prompt processing progress, n_tokens = 32738, batch.n_tokens = 2048, progress = 0.748605
2026-05-15 18:48:36.779 | slot update_slots: id  0 | task 9607 | n_tokens = 32738, memory_seq_rm [32738, end)
2026-05-15 18:48:36.780 | slot update_slots: id  0 | task 9607 | prompt processing progress, n_tokens = 34786, batch.n_tokens = 2048, progress = 0.795436
2026-05-15 18:48:37.712 | slot update_slots: id  0 | task 9607 | n_tokens = 34786, memory_seq_rm [34786, end)
2026-05-15 18:48:37.712 | slot update_slots: id  0 | task 9607 | prompt processing progress, n_tokens = 36834, batch.n_tokens = 2048, progress = 0.842267
2026-05-15 18:48:38.668 | slot update_slots: id  0 | task 9607 | n_tokens = 36834, memory_seq_rm [36834, end)
2026-05-15 18:48:38.668 | slot update_slots: id  0 | task 9607 | prompt processing progress, n_tokens = 38882, batch.n_tokens = 2048, progress = 0.889097
2026-05-15 18:48:39.679 | slot update_slots: id  0 | task 9607 | n_tokens = 38882, memory_seq_rm [38882, end)
2026-05-15 18:48:39.679 | slot update_slots: id  0 | task 9607 | 8192 tokens since last checkpoint at 30501, creating new checkpoint during processing at position 40930
2026-05-15 18:48:39.679 | slot update_slots: id  0 | task 9607 | prompt processing progress, n_tokens = 40930, batch.n_tokens = 2048, progress = 0.935928
2026-05-15 18:48:39.929 | slot create_check: id  0 | task 9607 | created context checkpoint 17 of 32 (pos_min = 38881, pos_max = 38881, n_tokens = 38882, size = 231.056 MiB)
2026-05-15 18:48:40.971 | slot update_slots: id  0 | task 9607 | n_tokens = 40930, memory_seq_rm [40930, end)
2026-05-15 18:48:40.971 | slot update_slots: id  0 | task 9607 | prompt processing progress, n_tokens = 42978, batch.n_tokens = 2048, progress = 0.982759
2026-05-15 18:48:42.019 | slot update_slots: id  0 | task 9607 | n_tokens = 42978, memory_seq_rm [42978, end)
2026-05-15 18:48:42.019 | slot update_slots: id  0 | task 9607 | prompt processing progress, n_tokens = 43216, batch.n_tokens = 238, progress = 0.988201
2026-05-15 18:48:42.160 | slot update_slots: id  0 | task 9607 | n_tokens = 43216, memory_seq_rm [43216, end)
2026-05-15 18:48:42.161 | slot update_slots: id  0 | task 9607 | prompt processing progress, n_tokens = 43728, batch.n_tokens = 512, progress = 0.999909
2026-05-15 18:48:42.427 | slot create_check: id  0 | task 9607 | created context checkpoint 18 of 32 (pos_min = 43215, pos_max = 43215, n_tokens = 43216, size = 240.132 MiB)
2026-05-15 18:48:42.688 | slot update_slots: id  0 | task 9607 | n_tokens = 43728, memory_seq_rm [43728, end)
2026-05-15 18:48:42.694 | slot init_sampler: id  0 | task 9607 | init sampler, took 5.77 ms, tokens: text = 43732, total = 43732
2026-05-15 18:48:42.694 | slot update_slots: id  0 | task 9607 | prompt processing done, n_tokens = 43732, batch.n_tokens = 4
2026-05-15 18:48:42.966 | slot create_check: id  0 | task 9607 | created context checkpoint 19 of 32 (pos_min = 43727, pos_max = 43727, n_tokens = 43728, size = 241.204 MiB)
2026-05-15 18:48:43.002 | srv  log_server_r: done request: POST /v1/chat/completions 172.18.0.1 200
2026-05-15 18:48:44.449 | reasoning-budget: deactivated (natural end)
2026-05-15 18:48:46.759 | slot print_timing: id  0 | task 9607 | 
2026-05-15 18:48:46.759 | prompt eval time =    7130.50 ms / 13042 tokens (    0.55 ms per token,  1829.04 tokens per second)
2026-05-15 18:48:46.759 |        eval time =    3742.80 ms /   239 tokens (   15.66 ms per token,    63.86 tokens per second)
2026-05-15 18:48:46.759 |       total time =   10873.30 ms / 13281 tokens
2026-05-15 18:48:46.759 | draft acceptance rate = 1.00000 (  136 accepted /   136 generated)
2026-05-15 18:48:46.759 | statistics mtp: #calls(b,g,a) = 85 8757 7272, #gen drafts = 7272, #acc drafts = 7272, #gen tokens = 12868, #acc tokens = 12662, dur(b,g,a) = 0.115, 36402.153, 2.994 ms
2026-05-15 18:48:46.760 | slot      release: id  0 | task 9607 | stop processing: n_tokens = 43970, truncated = 0
2026-05-15 18:48:46.760 | srv  update_slots: all slots are idle
2026-05-15 18:48:46.961 | srv  params_from_: Chat format: peg-native
2026-05-15 18:48:46.964 | slot get_availabl: id  0 | task -1 | selected slot by LCP similarity, sim_best = 0.961 (> 0.100 thold), f_keep = 1.000
2026-05-15 18:48:46.965 | reasoning-budget: activated, budget=2147483647 tokens
2026-05-15 18:48:46.965 | slot launch_slot_: id  0 | task -1 | sampler chain: logits -> penalties -> ?dry -> ?top-n-sigma -> top-k -> ?typical -> ?top-p -> min-p -> ?xtc -> ?temp-ext -> dist 
2026-05-15 18:48:46.965 | slot launch_slot_: id  0 | task 9725 | processing task, is_child = 0
2026-05-15 18:48:46.965 | slot update_slots: id  0 | task 9725 | new prompt, n_ctx_slot = 131072, n_keep = 0, task.n_tokens = 45748
2026-05-15 18:48:46.965 | slot update_slots: id  0 | task 9725 | n_tokens = 43970, memory_seq_rm [43970, end)
2026-05-15 18:48:46.965 | slot update_slots: id  0 | task 9725 | prompt processing progress, n_tokens = 45232, batch.n_tokens = 1262, progress = 0.988721
2026-05-15 18:48:47.656 | slot update_slots: id  0 | task 9725 | n_tokens = 45232, memory_seq_rm [45232, end)
2026-05-15 18:48:47.657 | slot update_slots: id  0 | task 9725 | prompt processing progress, n_tokens = 45744, batch.n_tokens = 512, progress = 0.999913
2026-05-15 18:48:47.929 | slot create_check: id  0 | task 9725 | created context checkpoint 20 of 32 (pos_min = 45231, pos_max = 45231, n_tokens = 45232, size = 244.354 MiB)
2026-05-15 18:48:48.200 | slot update_slots: id  0 | task 9725 | n_tokens = 45744, memory_seq_rm [45744, end)
2026-05-15 18:48:48.206 | slot init_sampler: id  0 | task 9725 | init sampler, took 5.93 ms, tokens: text = 45748, total = 45748
2026-05-15 18:48:48.206 | slot update_slots: id  0 | task 9725 | prompt processing done, n_tokens = 45748, batch.n_tokens = 4
2026-05-15 18:48:48.479 | slot create_check: id  0 | task 9725 | created context checkpoint 21 of 32 (pos_min = 45743, pos_max = 45743, n_tokens = 45744, size = 245.426 MiB)
2026-05-15 18:48:48.516 | srv  log_server_r: done request: POST /v1/chat/completions 172.18.0.1 200
2026-05-15 18:48:49.925 | reasoning-budget: deactivated (natural end)
2026-05-15 18:48:50.945 | slot print_timing: id  0 | task 9725 | 
2026-05-15 18:48:50.945 | prompt eval time =    1550.62 ms /  1778 tokens (    0.87 ms per token,  1146.64 tokens per second)
2026-05-15 18:48:50.945 |        eval time =    2428.73 ms /   159 tokens (   15.28 ms per token,    65.47 tokens per second)
2026-05-15 18:48:50.945 |       total time =    3979.35 ms /  1937 tokens
2026-05-15 18:48:50.945 | draft acceptance rate = 1.00000 (   89 accepted /    89 generated)
2026-05-15 18:48:50.945 | statistics mtp: #calls(b,g,a) = 86 8826 7321, #gen drafts = 7321, #acc drafts = 7321, #gen tokens = 12957, #acc tokens = 12751, dur(b,g,a) = 0.117, 36659.279, 3.014 ms
2026-05-15 18:48:50.946 | slot      release: id  0 | task 9725 | stop processing: n_tokens = 45906, truncated = 0
2026-05-15 18:48:50.946 | srv  update_slots: all slots are idle
2026-05-15 18:48:51.177 | srv  params_from_: Chat format: peg-native
2026-05-15 18:48:51.179 | slot get_availabl: id  0 | task -1 | selected slot by LCP similarity, sim_best = 0.698 (> 0.100 thold), f_keep = 1.000
2026-05-15 18:48:51.180 | reasoning-budget: activated, budget=2147483647 tokens
2026-05-15 18:48:51.180 | slot launch_slot_: id  0 | task -1 | sampler chain: logits -> penalties -> ?dry -> ?top-n-sigma -> top-k -> ?typical -> ?top-p -> min-p -> ?xtc -> ?temp-ext -> dist 
2026-05-15 18:48:51.180 | slot launch_slot_: id  0 | task 9802 | processing task, is_child = 0
2026-05-15 18:48:51.180 | slot update_slots: id  0 | task 9802 | new prompt, n_ctx_slot = 131072, n_keep = 0, task.n_tokens = 65811
2026-05-15 18:48:51.180 | slot update_slots: id  0 | task 9802 | n_tokens = 45906, memory_seq_rm [45906, end)
2026-05-15 18:48:51.181 | slot update_slots: id  0 | task 9802 | prompt processing progress, n_tokens = 47954, batch.n_tokens = 2048, progress = 0.728662
2026-05-15 18:48:52.273 | slot update_slots: id  0 | task 9802 | n_tokens = 47954, memory_seq_rm [47954, end)
2026-05-15 18:48:52.273 | slot update_slots: id  0 | task 9802 | prompt processing progress, n_tokens = 50002, batch.n_tokens = 2048, progress = 0.759782
2026-05-15 18:48:53.397 | slot update_slots: id  0 | task 9802 | n_tokens = 50002, memory_seq_rm [50002, end)
2026-05-15 18:48:53.397 | slot update_slots: id  0 | task 9802 | prompt processing progress, n_tokens = 52050, batch.n_tokens = 2048, progress = 0.790901
2026-05-15 18:48:54.544 | slot update_slots: id  0 | task 9802 | n_tokens = 52050, memory_seq_rm [52050, end)
2026-05-15 18:48:54.544 | slot update_slots: id  0 | task 9802 | prompt processing progress, n_tokens = 54098, batch.n_tokens = 2048, progress = 0.822021
2026-05-15 18:48:55.728 | slot update_slots: id  0 | task 9802 | n_tokens = 54098, memory_seq_rm [54098, end)
2026-05-15 18:48:55.728 | slot update_slots: id  0 | task 9802 | 8192 tokens since last checkpoint at 45744, creating new checkpoint during processing at position 56146
2026-05-15 18:48:55.728 | slot update_slots: id  0 | task 9802 | prompt processing progress, n_tokens = 56146, batch.n_tokens = 2048, progress = 0.853140
2026-05-15 18:48:56.018 | slot create_check: id  0 | task 9802 | created context checkpoint 22 of 32 (pos_min = 54097, pos_max = 54097, n_tokens = 54098, size = 262.922 MiB)
2026-05-15 18:48:57.230 | slot update_slots: id  0 | task 9802 | n_tokens = 56146, memory_seq_rm [56146, end)
2026-05-15 18:48:57.230 | slot update_slots: id  0 | task 9802 | prompt processing progress, n_tokens = 58194, batch.n_tokens = 2048, progress = 0.884259
2026-05-15 18:48:58.456 | slot update_slots: id  0 | task 9802 | n_tokens = 58194, memory_seq_rm [58194, end)
2026-05-15 18:48:58.456 | slot update_slots: id  0 | task 9802 | prompt processing progress, n_tokens = 60242, batch.n_tokens = 2048, progress = 0.915379
2026-05-15 18:48:59.723 | slot update_slots: id  0 | task 9802 | n_tokens = 60242, memory_seq_rm [60242, end)
2026-05-15 18:48:59.723 | slot update_slots: id  0 | task 9802 | prompt processing progress, n_tokens = 62290, batch.n_tokens = 2048, progress = 0.946498
2026-05-15 18:49:01.030 | slot update_slots: id  0 | task 9802 | n_tokens = 62290, memory_seq_rm [62290, end)
2026-05-15 18:49:01.030 | slot update_slots: id  0 | task 9802 | 8192 tokens since last checkpoint at 54098, creating new checkpoint during processing at position 64338
2026-05-15 18:49:01.030 | slot update_slots: id  0 | task 9802 | prompt processing progress, n_tokens = 64338, batch.n_tokens = 2048, progress = 0.977618
2026-05-15 18:49:01.340 | slot create_check: id  0 | task 9802 | created context checkpoint 23 of 32 (pos_min = 62289, pos_max = 62289, n_tokens = 62290, size = 280.078 MiB)
2026-05-15 18:49:02.665 | slot update_slots: id  0 | task 9802 | n_tokens = 64338, memory_seq_rm [64338, end)
2026-05-15 18:49:02.665 | slot update_slots: id  0 | task 9802 | prompt processing progress, n_tokens = 65295, batch.n_tokens = 957, progress = 0.992159
2026-05-15 18:49:03.310 | slot update_slots: id  0 | task 9802 | n_tokens = 65295, memory_seq_rm [65295, end)
2026-05-15 18:49:03.310 | slot update_slots: id  0 | task 9802 | prompt processing progress, n_tokens = 65807, batch.n_tokens = 512, progress = 0.999939
2026-05-15 18:49:03.606 | slot create_check: id  0 | task 9802 | created context checkpoint 24 of 32 (pos_min = 65294, pos_max = 65294, n_tokens = 65295, size = 286.371 MiB)
2026-05-15 18:49:03.947 | slot update_slots: id  0 | task 9802 | n_tokens = 65807, memory_seq_rm [65807, end)
2026-05-15 18:49:03.955 | slot init_sampler: id  0 | task 9802 | init sampler, took 8.39 ms, tokens: text = 65811, total = 65811
2026-05-15 18:49:03.955 | slot update_slots: id  0 | task 9802 | prompt processing done, n_tokens = 65811, batch.n_tokens = 4
2026-05-15 18:49:04.271 | slot create_check: id  0 | task 9802 | created context checkpoint 25 of 32 (pos_min = 65806, pos_max = 65806, n_tokens = 65807, size = 287.444 MiB)
2026-05-15 18:49:04.310 | srv  log_server_r: done request: POST /v1/chat/completions 172.18.0.1 200
2026-05-15 18:49:04.890 | reasoning-budget: deactivated (natural end)
2026-05-15 18:49:05.841 | slot print_timing: id  0 | task 9802 | 
2026-05-15 18:49:05.841 | prompt eval time =   13128.77 ms / 19905 tokens (    0.66 ms per token,  1516.14 tokens per second)
2026-05-15 18:49:05.841 |        eval time =    1531.23 ms /   115 tokens (   13.32 ms per token,    75.10 tokens per second)
2026-05-15 18:49:05.841 |       total time =   14660.00 ms / 20020 tokens
2026-05-15 18:49:05.841 | draft acceptance rate = 1.00000 (   72 accepted /    72 generated)
2026-05-15 18:49:05.841 | statistics mtp: #calls(b,g,a) = 87 8868 7358, #gen drafts = 7358, #acc drafts = 7358, #gen tokens = 13029, #acc tokens = 12823, dur(b,g,a) = 0.118, 36841.115, 3.031 ms
2026-05-15 18:49:05.842 | slot      release: id  0 | task 9802 | stop processing: n_tokens = 65925, truncated = 0
2026-05-15 18:49:05.842 | srv  update_slots: all slots are idle
2026-05-15 18:49:06.098 | srv  params_from_: Chat format: peg-native
2026-05-15 18:49:06.100 | slot get_availabl: id  0 | task -1 | selected slot by LCP similarity, sim_best = 0.818 (> 0.100 thold), f_keep = 1.000
2026-05-15 18:49:06.101 | reasoning-budget: activated, budget=2147483647 tokens
2026-05-15 18:49:06.101 | slot launch_slot_: id  0 | task -1 | sampler chain: logits -> penalties -> ?dry -> ?top-n-sigma -> top-k -> ?typical -> ?top-p -> min-p -> ?xtc -> ?temp-ext -> dist 
2026-05-15 18:49:06.101 | slot launch_slot_: id  0 | task 9857 | processing task, is_child = 0
2026-05-15 18:49:06.101 | slot update_slots: id  0 | task 9857 | new prompt, n_ctx_slot = 131072, n_keep = 0, task.n_tokens = 80595
2026-05-15 18:49:06.101 | slot update_slots: id  0 | task 9857 | n_tokens = 65925, memory_seq_rm [65925, end)
2026-05-15 18:49:06.101 | slot update_slots: id  0 | task 9857 | prompt processing progress, n_tokens = 67973, batch.n_tokens = 2048, progress = 0.843390
2026-05-15 18:49:07.472 | slot update_slots: id  0 | task 9857 | n_tokens = 67973, memory_seq_rm [67973, end)
2026-05-15 18:49:07.472 | slot update_slots: id  0 | task 9857 | prompt processing progress, n_tokens = 70021, batch.n_tokens = 2048, progress = 0.868801
2026-05-15 18:49:08.873 | slot update_slots: id  0 | task 9857 | n_tokens = 70021, memory_seq_rm [70021, end)
2026-05-15 18:49:08.873 | slot update_slots: id  0 | task 9857 | prompt processing progress, n_tokens = 72069, batch.n_tokens = 2048, progress = 0.894212
2026-05-15 18:49:10.301 | slot update_slots: id  0 | task 9857 | n_tokens = 72069, memory_seq_rm [72069, end)
2026-05-15 18:49:10.301 | slot update_slots: id  0 | task 9857 | prompt processing progress, n_tokens = 74117, batch.n_tokens = 2048, progress = 0.919623
2026-05-15 18:49:11.749 | slot update_slots: id  0 | task 9857 | n_tokens = 74117, memory_seq_rm [74117, end)
2026-05-15 18:49:11.750 | slot update_slots: id  0 | task 9857 | 8192 tokens since last checkpoint at 65807, creating new checkpoint during processing at position 76165
2026-05-15 18:49:11.750 | slot update_slots: id  0 | task 9857 | prompt processing progress, n_tokens = 76165, batch.n_tokens = 2048, progress = 0.945034
2026-05-15 18:49:12.089 | slot create_check: id  0 | task 9857 | created context checkpoint 26 of 32 (pos_min = 74116, pos_max = 74116, n_tokens = 74117, size = 304.847 MiB)
2026-05-15 18:49:13.560 | slot update_slots: id  0 | task 9857 | n_tokens = 76165, memory_seq_rm [76165, end)
2026-05-15 18:49:13.560 | slot update_slots: id  0 | task 9857 | prompt processing progress, n_tokens = 78213, batch.n_tokens = 2048, progress = 0.970445
2026-05-15 18:49:15.069 | slot update_slots: id  0 | task 9857 | n_tokens = 78213, memory_seq_rm [78213, end)
2026-05-15 18:49:15.069 | slot update_slots: id  0 | task 9857 | prompt processing progress, n_tokens = 80079, batch.n_tokens = 1866, progress = 0.993598
2026-05-15 18:49:16.450 | slot update_slots: id  0 | task 9857 | n_tokens = 80079, memory_seq_rm [80079, end)
2026-05-15 18:49:16.450 | slot update_slots: id  0 | task 9857 | prompt processing progress, n_tokens = 80591, batch.n_tokens = 512, progress = 0.999950
2026-05-15 18:49:16.804 | slot create_check: id  0 | task 9857 | created context checkpoint 27 of 32 (pos_min = 80078, pos_max = 80078, n_tokens = 80079, size = 317.333 MiB)
2026-05-15 18:49:17.196 | slot update_slots: id  0 | task 9857 | n_tokens = 80591, memory_seq_rm [80591, end)
2026-05-15 18:49:17.206 | slot init_sampler: id  0 | task 9857 | init sampler, took 10.26 ms, tokens: text = 80595, total = 80595
2026-05-15 18:49:17.206 | slot update_slots: id  0 | task 9857 | prompt processing done, n_tokens = 80595, batch.n_tokens = 4
2026-05-15 18:49:17.560 | slot create_check: id  0 | task 9857 | created context checkpoint 28 of 32 (pos_min = 80590, pos_max = 80590, n_tokens = 80591, size = 318.405 MiB)
2026-05-15 18:49:17.600 | srv  log_server_r: done request: POST /v1/chat/completions 172.18.0.1 200
2026-05-15 18:49:18.731 | reasoning-budget: deactivated (natural end)
2026-05-15 18:49:19.225 | slot print_timing: id  0 | task 9857 | 
2026-05-15 18:49:19.225 | prompt eval time =   11483.93 ms / 14670 tokens (    0.78 ms per token,  1277.44 tokens per second)
2026-05-15 18:49:19.225 |        eval time =    1625.48 ms /    86 tokens (   18.90 ms per token,    52.91 tokens per second)
2026-05-15 18:49:19.225 |       total time =   13109.41 ms / 14756 tokens
2026-05-15 18:49:19.225 | draft acceptance rate = 1.00000 (   41 accepted /    41 generated)
2026-05-15 18:49:19.225 | statistics mtp: #calls(b,g,a) = 88 8912 7381, #gen drafts = 7381, #acc drafts = 7381, #gen tokens = 13070, #acc tokens = 12864, dur(b,g,a) = 0.119, 36997.141, 3.038 ms
2026-05-15 18:49:19.227 | slot      release: id  0 | task 9857 | stop processing: n_tokens = 80680, truncated = 0
2026-05-15 18:49:19.227 | srv  update_slots: all slots are idle
2026-05-15 18:49:19.501 | srv  params_from_: Chat format: peg-native
2026-05-15 18:49:19.503 | slot get_availabl: id  0 | task -1 | selected slot by LCP similarity, sim_best = 0.916 (> 0.100 thold), f_keep = 1.000
2026-05-15 18:49:19.504 | reasoning-budget: activated, budget=2147483647 tokens
2026-05-15 18:49:19.504 | slot launch_slot_: id  0 | task -1 | sampler chain: logits -> penalties -> ?dry -> ?top-n-sigma -> top-k -> ?typical -> ?top-p -> min-p -> ?xtc -> ?temp-ext -> dist 
2026-05-15 18:49:19.504 | slot launch_slot_: id  0 | task 9915 | processing task, is_child = 0
2026-05-15 18:49:19.504 | slot update_slots: id  0 | task 9915 | new prompt, n_ctx_slot = 131072, n_keep = 0, task.n_tokens = 88094
2026-05-15 18:49:19.504 | slot update_slots: id  0 | task 9915 | n_tokens = 80680, memory_seq_rm [80680, end)
2026-05-15 18:49:19.505 | slot update_slots: id  0 | task 9915 | prompt processing progress, n_tokens = 82728, batch.n_tokens = 2048, progress = 0.939088
2026-05-15 18:49:21.082 | slot update_slots: id  0 | task 9915 | n_tokens = 82728, memory_seq_rm [82728, end)
2026-05-15 18:49:21.082 | slot update_slots: id  0 | task 9915 | prompt processing progress, n_tokens = 84776, batch.n_tokens = 2048, progress = 0.962336
2026-05-15 18:49:22.691 | slot update_slots: id  0 | task 9915 | n_tokens = 84776, memory_seq_rm [84776, end)
2026-05-15 18:49:22.691 | slot update_slots: id  0 | task 9915 | prompt processing progress, n_tokens = 86824, batch.n_tokens = 2048, progress = 0.985584
2026-05-15 18:49:24.327 | slot update_slots: id  0 | task 9915 | n_tokens = 86824, memory_seq_rm [86824, end)
2026-05-15 18:49:24.327 | slot update_slots: id  0 | task 9915 | prompt processing progress, n_tokens = 87578, batch.n_tokens = 754, progress = 0.994143
2026-05-15 18:49:24.969 | slot update_slots: id  0 | task 9915 | n_tokens = 87578, memory_seq_rm [87578, end)
2026-05-15 18:49:24.969 | slot update_slots: id  0 | task 9915 | prompt processing progress, n_tokens = 88090, batch.n_tokens = 512, progress = 0.999955
2026-05-15 18:49:25.335 | slot create_check: id  0 | task 9915 | created context checkpoint 29 of 32 (pos_min = 87577, pos_max = 87577, n_tokens = 87578, size = 333.038 MiB)
2026-05-15 18:49:25.756 | slot update_slots: id  0 | task 9915 | n_tokens = 88090, memory_seq_rm [88090, end)
2026-05-15 18:49:25.767 | slot init_sampler: id  0 | task 9915 | init sampler, took 11.26 ms, tokens: text = 88094, total = 88094
2026-05-15 18:49:25.767 | slot update_slots: id  0 | task 9915 | prompt processing done, n_tokens = 88094, batch.n_tokens = 4
2026-05-15 18:49:26.135 | slot create_check: id  0 | task 9915 | created context checkpoint 30 of 32 (pos_min = 88089, pos_max = 88089, n_tokens = 88090, size = 334.110 MiB)
2026-05-15 18:49:26.177 | srv  log_server_r: done request: POST /v1/chat/completions 172.18.0.1 200
2026-05-15 18:49:26.764 | reasoning-budget: deactivated (natural end)
2026-05-15 18:49:27.762 | slot print_timing: id  0 | task 9915 | 
2026-05-15 18:49:27.762 | prompt eval time =    6672.26 ms /  7414 tokens (    0.90 ms per token,  1111.17 tokens per second)
2026-05-15 18:49:27.762 |        eval time =    1585.48 ms /    91 tokens (   17.42 ms per token,    57.40 tokens per second)
2026-05-15 18:49:27.762 |       total time =    8257.74 ms /  7505 tokens
2026-05-15 18:49:27.762 | draft acceptance rate = 1.00000 (   50 accepted /    50 generated)
2026-05-15 18:49:27.762 | statistics mtp: #calls(b,g,a) = 89 8952 7408, #gen drafts = 7408, #acc drafts = 7408, #gen tokens = 13120, #acc tokens = 12914, dur(b,g,a) = 0.120, 37155.383, 3.050 ms
2026-05-15 18:49:27.764 | slot      release: id  0 | task 9915 | stop processing: n_tokens = 88184, truncated = 0
2026-05-15 18:49:27.764 | srv  update_slots: all slots are idle
2026-05-15 18:49:28.034 | srv  params_from_: Chat format: peg-native
2026-05-15 18:49:28.036 | slot get_availabl: id  0 | task -1 | selected slot by LCP similarity, sim_best = 0.996 (> 0.100 thold), f_keep = 1.000
2026-05-15 18:49:28.037 | reasoning-budget: activated, budget=2147483647 tokens
2026-05-15 18:49:28.037 | slot launch_slot_: id  0 | task -1 | sampler chain: logits -> penalties -> ?dry -> ?top-n-sigma -> top-k -> ?typical -> ?top-p -> min-p -> ?xtc -> ?temp-ext -> dist 
2026-05-15 18:49:28.037 | slot launch_slot_: id  0 | task 9963 | processing task, is_child = 0
2026-05-15 18:49:28.037 | slot update_slots: id  0 | task 9963 | new prompt, n_ctx_slot = 131072, n_keep = 0, task.n_tokens = 88532
2026-05-15 18:49:28.037 | slot update_slots: id  0 | task 9963 | n_tokens = 88184, memory_seq_rm [88184, end)
2026-05-15 18:49:28.037 | slot update_slots: id  0 | task 9963 | prompt processing progress, n_tokens = 88528, batch.n_tokens = 344, progress = 0.999955
2026-05-15 18:49:28.428 | slot create_check: id  0 | task 9963 | created context checkpoint 31 of 32 (pos_min = 88183, pos_max = 88183, n_tokens = 88184, size = 334.307 MiB)
2026-05-15 18:49:28.739 | slot update_slots: id  0 | task 9963 | n_tokens = 88528, memory_seq_rm [88528, end)
2026-05-15 18:49:28.750 | slot init_sampler: id  0 | task 9963 | init sampler, took 11.38 ms, tokens: text = 88532, total = 88532
2026-05-15 18:49:28.751 | slot update_slots: id  0 | task 9963 | prompt processing done, n_tokens = 88532, batch.n_tokens = 4
2026-05-15 18:49:29.121 | slot create_check: id  0 | task 9963 | created context checkpoint 32 of 32 (pos_min = 88527, pos_max = 88527, n_tokens = 88528, size = 335.028 MiB)
2026-05-15 18:49:29.164 | srv  log_server_r: done request: POST /v1/chat/completions 172.18.0.1 200
2026-05-15 18:49:29.610 | reasoning-budget: deactivated (natural end)
2026-05-15 18:49:30.578 | slot print_timing: id  0 | task 9963 | 
2026-05-15 18:49:30.578 | prompt eval time =    1126.02 ms /   348 tokens (    3.24 ms per token,   309.05 tokens per second)
2026-05-15 18:49:30.578 |        eval time =    1414.64 ms /    91 tokens (   15.55 ms per token,    64.33 tokens per second)
2026-05-15 18:49:30.578 |       total time =    2540.66 ms /   439 tokens
2026-05-15 18:49:30.578 | draft acceptance rate = 1.00000 (   55 accepted /    55 generated)
2026-05-15 18:49:30.578 | statistics mtp: #calls(b,g,a) = 90 8987 7438, #gen drafts = 7438, #acc drafts = 7438, #gen tokens = 13175, #acc tokens = 12969, dur(b,g,a) = 0.121, 37309.707, 3.063 ms
2026-05-15 18:49:30.580 | slot      release: id  0 | task 9963 | stop processing: n_tokens = 88622, truncated = 0
2026-05-15 18:49:30.580 | srv  update_slots: all slots are idle
2026-05-15 18:49:30.854 | srv  params_from_: Chat format: peg-native
2026-05-15 18:49:30.856 | slot get_availabl: id  0 | task -1 | selected slot by LCP similarity, sim_best = 0.978 (> 0.100 thold), f_keep = 1.000
2026-05-15 18:49:30.857 | reasoning-budget: activated, budget=2147483647 tokens
2026-05-15 18:49:30.857 | slot launch_slot_: id  0 | task -1 | sampler chain: logits -> penalties -> ?dry -> ?top-n-sigma -> top-k -> ?typical -> ?top-p -> min-p -> ?xtc -> ?temp-ext -> dist 
2026-05-15 18:49:30.857 | slot launch_slot_: id  0 | task 10001 | processing task, is_child = 0
2026-05-15 18:49:30.857 | slot update_slots: id  0 | task 10001 | new prompt, n_ctx_slot = 131072, n_keep = 0, task.n_tokens = 90651
2026-05-15 18:49:30.858 | slot update_slots: id  0 | task 10001 | n_tokens = 88622, memory_seq_rm [88622, end)
2026-05-15 18:49:30.858 | slot update_slots: id  0 | task 10001 | prompt processing progress, n_tokens = 90135, batch.n_tokens = 1513, progress = 0.994308
2026-05-15 18:49:32.099 | slot update_slots: id  0 | task 10001 | n_tokens = 90135, memory_seq_rm [90135, end)
2026-05-15 18:49:32.099 | slot update_slots: id  0 | task 10001 | prompt processing progress, n_tokens = 90647, batch.n_tokens = 512, progress = 0.999956
2026-05-15 18:49:32.099 | slot create_check: id  0 | task 10001 | erasing old context checkpoint (pos_min = 5281, pos_max = 5281, n_tokens = 5282, size = 160.688 MiB)
2026-05-15 18:49:32.432 | slot create_check: id  0 | task 10001 | created context checkpoint 32 of 32 (pos_min = 90134, pos_max = 90134, n_tokens = 90135, size = 338.393 MiB)
2026-05-15 18:49:32.862 | slot update_slots: id  0 | task 10001 | n_tokens = 90647, memory_seq_rm [90647, end)
2026-05-15 18:49:32.873 | slot init_sampler: id  0 | task 10001 | init sampler, took 11.48 ms, tokens: text = 90651, total = 90651
2026-05-15 18:49:32.874 | slot update_slots: id  0 | task 10001 | prompt processing done, n_tokens = 90651, batch.n_tokens = 4
2026-05-15 18:49:32.874 | slot create_check: id  0 | task 10001 | erasing old context checkpoint (pos_min = 5793, pos_max = 5793, n_tokens = 5794, size = 161.760 MiB)
2026-05-15 18:49:33.201 | slot create_check: id  0 | task 10001 | created context checkpoint 32 of 32 (pos_min = 90646, pos_max = 90646, n_tokens = 90647, size = 339.465 MiB)
2026-05-15 18:49:33.242 | srv  log_server_r: done request: POST /v1/chat/completions 172.18.0.1 200
2026-05-15 18:49:34.048 | reasoning-budget: deactivated (natural end)
2026-05-15 18:49:34.681 | slot print_timing: id  0 | task 10001 | 
2026-05-15 18:49:34.681 | prompt eval time =    2384.16 ms /  2029 tokens (    1.18 ms per token,   851.03 tokens per second)
2026-05-15 18:49:34.681 |        eval time =    1438.71 ms /    77 tokens (   18.68 ms per token,    53.52 tokens per second)
2026-05-15 18:49:34.681 |       total time =    3822.86 ms /  2106 tokens
2026-05-15 18:49:34.681 | draft acceptance rate = 0.97826 (   45 accepted /    46 generated)
2026-05-15 18:49:34.681 | statistics mtp: #calls(b,g,a) = 91 9018 7464, #gen drafts = 7464, #acc drafts = 7464, #gen tokens = 13221, #acc tokens = 13014, dur(b,g,a) = 0.122, 37452.425, 3.078 ms
2026-05-15 18:49:34.683 | slot      release: id  0 | task 10001 | stop processing: n_tokens = 90727, truncated = 0
2026-05-15 18:49:34.683 | srv  update_slots: all slots are idle
2026-05-15 18:49:34.973 | srv  params_from_: Chat format: peg-native
2026-05-15 18:49:34.975 | slot get_availabl: id  0 | task -1 | selected slot by LCP similarity, sim_best = 0.842 (> 0.100 thold), f_keep = 1.000
2026-05-15 18:49:34.976 | reasoning-budget: activated, budget=2147483647 tokens
2026-05-15 18:49:34.976 | slot launch_slot_: id  0 | task -1 | sampler chain: logits -> penalties -> ?dry -> ?top-n-sigma -> top-k -> ?typical -> ?top-p -> min-p -> ?xtc -> ?temp-ext -> dist 
2026-05-15 18:49:34.976 | slot launch_slot_: id  0 | task 10039 | processing task, is_child = 0
2026-05-15 18:49:34.976 | slot update_slots: id  0 | task 10039 | new prompt, n_ctx_slot = 131072, n_keep = 0, task.n_tokens = 107798
2026-05-15 18:49:34.976 | slot update_slots: id  0 | task 10039 | n_tokens = 90727, memory_seq_rm [90727, end)
2026-05-15 18:49:34.976 | slot update_slots: id  0 | task 10039 | prompt processing progress, n_tokens = 92775, batch.n_tokens = 2048, progress = 0.860637
2026-05-15 18:49:36.677 | slot update_slots: id  0 | task 10039 | n_tokens = 92775, memory_seq_rm [92775, end)
2026-05-15 18:49:36.677 | slot update_slots: id  0 | task 10039 | prompt processing progress, n_tokens = 94823, batch.n_tokens = 2048, progress = 0.879636
2026-05-15 18:49:38.406 | slot update_slots: id  0 | task 10039 | n_tokens = 94823, memory_seq_rm [94823, end)
2026-05-15 18:49:38.407 | slot update_slots: id  0 | task 10039 | prompt processing progress, n_tokens = 96871, batch.n_tokens = 2048, progress = 0.898634
2026-05-15 18:49:40.136 | slot update_slots: id  0 | task 10039 | n_tokens = 96871, memory_seq_rm [96871, end)
2026-05-15 18:49:40.136 | slot update_slots: id  0 | task 10039 | prompt processing progress, n_tokens = 98919, batch.n_tokens = 2048, progress = 0.917633
2026-05-15 18:49:41.914 | slot update_slots: id  0 | task 10039 | n_tokens = 98919, memory_seq_rm [98919, end)
2026-05-15 18:49:41.914 | slot update_slots: id  0 | task 10039 | 8192 tokens since last checkpoint at 90647, creating new checkpoint during processing at position 100967
2026-05-15 18:49:41.914 | slot update_slots: id  0 | task 10039 | prompt processing progress, n_tokens = 100967, batch.n_tokens = 2048, progress = 0.936632
2026-05-15 18:49:41.914 | slot create_check: id  0 | task 10039 | erasing old context checkpoint (pos_min = 7256, pos_max = 7256, n_tokens = 7257, size = 164.824 MiB)
2026-05-15 18:49:42.266 | slot create_check: id  0 | task 10039 | created context checkpoint 32 of 32 (pos_min = 98918, pos_max = 98918, n_tokens = 98919, size = 356.789 MiB)
2026-05-15 18:49:44.085 | slot update_slots: id  0 | task 10039 | n_tokens = 100967, memory_seq_rm [100967, end)
2026-05-15 18:49:44.085 | slot update_slots: id  0 | task 10039 | prompt processing progress, n_tokens = 103015, batch.n_tokens = 2048, progress = 0.955630
2026-05-15 18:49:45.951 | slot update_slots: id  0 | task 10039 | n_tokens = 103015, memory_seq_rm [103015, end)
2026-05-15 18:49:45.952 | slot update_slots: id  0 | task 10039 | prompt processing progress, n_tokens = 105063, batch.n_tokens = 2048, progress = 0.974628
2026-05-15 18:49:47.826 | slot update_slots: id  0 | task 10039 | n_tokens = 105063, memory_seq_rm [105063, end)
2026-05-15 18:49:47.826 | slot update_slots: id  0 | task 10039 | prompt processing progress, n_tokens = 107111, batch.n_tokens = 2048, progress = 0.993627
2026-05-15 18:49:47.992 | srv          next: stopping wait for next result due to should_stop condition (adjust the --timeout argument if needed)
2026-05-15 18:49:47.992 | srv          next: ref: https://github.com/ggml-org/llama.cpp/pull/22907
2026-05-15 18:49:47.992 | srv          stop: cancel task, id_task = 10039
2026-05-15 18:49:47.992 | srv  log_server_r: done request: POST /v1/chat/completions 172.18.0.1 200
2026-05-15 18:49:49.716 | slot      release: id  0 | task 10039 | stop processing: n_tokens = 107111, truncated = 0
2026-05-15 18:49:49.716 | srv  update_slots: all slots are idle
2026-05-15 18:50:16.508 | srv  params_from_: Chat format: peg-native
2026-05-15 18:50:16.511 | slot get_availabl: id  3 | task -1 | selected slot by LRU, t_last = 4865748330
2026-05-15 18:50:16.511 | srv  get_availabl: updating prompt cache
2026-05-15 18:50:16.511 | srv          load:  - looking for better prompt, base f_keep = -1.000, sim = 0.000
2026-05-15 18:50:16.511 | srv        update:  - cache state: 1 prompts, 1205.939 MiB (limits: 8192.000 MiB, 131072 tokens, 131072 est)
2026-05-15 18:50:16.511 | srv        update:    - prompt 0x6487e7520220:   15131 tokens, checkpoints:  3,  1205.939 MiB
2026-05-15 18:50:16.511 | srv  get_availabl: prompt cache update took 0.01 ms
2026-05-15 18:50:16.512 | reasoning-budget: activated, budget=2147483647 tokens
2026-05-15 18:50:16.512 | slot launch_slot_: id  3 | task -1 | sampler chain: logits -> penalties -> ?dry -> ?top-n-sigma -> top-k -> ?typical -> ?top-p -> min-p -> ?xtc -> ?temp-ext -> dist 
2026-05-15 18:50:16.512 | slot launch_slot_: id  3 | task 10049 | processing task, is_child = 0
2026-05-15 18:50:16.512 | slot slot_save_an: id  0 | task -1 | saving idle slot to prompt cache
2026-05-15 18:50:16.516 | srv   prompt_save:  - saving prompt with length 107111, total state size = 3932.409 MiB (draft: 224.319 MiB)
2026-05-15 18:50:29.292 | slot prompt_clear: id  0 | task -1 | clearing prompt with 107111 tokens
2026-05-15 18:50:29.309 | srv        update:  - cache size limit reached, removing oldest entry (size = 1205.939 MiB)
2026-05-15 18:50:29.381 | srv        update:  - cache state: 1 prompts, 12015.952 MiB (limits: 8192.000 MiB, 131072 tokens, 131072 est)
2026-05-15 18:50:29.381 | srv        update:    - prompt 0x6487e7d7e430:  107111 tokens, checkpoints: 32, 12015.952 MiB
2026-05-15 18:50:29.381 | slot update_slots: id  3 | task 10049 | new prompt, n_ctx_slot = 131072, n_keep = 0, task.n_tokens = 64894
2026-05-15 18:50:29.381 | slot update_slots: id  3 | task 10049 | erased invalidated context checkpoint (pos_min = 4102, pos_max = 4102, n_tokens = 4103, n_swa = 0, pos_next = 0, size = 158.219 MiB)
2026-05-15 18:50:29.390 | slot update_slots: id  3 | task 10049 | erased invalidated context checkpoint (pos_min = 4614, pos_max = 4614, n_tokens = 4615, n_swa = 0, pos_next = 0, size = 159.291 MiB)
2026-05-15 18:50:29.399 | slot update_slots: id  3 | task 10049 | erased invalidated context checkpoint (pos_min = 5480, pos_max = 5480, n_tokens = 5481, n_swa = 0, pos_next = 0, size = 161.105 MiB)
2026-05-15 18:50:29.409 | slot update_slots: id  3 | task 10049 | erased invalidated context checkpoint (pos_min = 5992, pos_max = 5992, n_tokens = 5993, n_swa = 0, pos_next = 0, size = 162.177 MiB)
2026-05-15 18:50:29.418 | slot update_slots: id  3 | task 10049 | erased invalidated context checkpoint (pos_min = 14590, pos_max = 14590, n_tokens = 14591, n_swa = 0, pos_next = 0, size = 180.184 MiB)
2026-05-15 18:50:29.427 | slot update_slots: id  3 | task 10049 | erased invalidated context checkpoint (pos_min = 24815, pos_max = 24815, n_tokens = 24816, n_swa = 0, pos_next = 0, size = 201.598 MiB)
2026-05-15 18:50:29.438 | slot update_slots: id  3 | task 10049 | erased invalidated context checkpoint (pos_min = 32363, pos_max = 32363, n_tokens = 32364, n_swa = 0, pos_next = 0, size = 217.405 MiB)
2026-05-15 18:50:29.451 | slot update_slots: id  3 | task 10049 | erased invalidated context checkpoint (pos_min = 32875, pos_max = 32875, n_tokens = 32876, n_swa = 0, pos_next = 0, size = 218.477 MiB)
2026-05-15 18:50:29.464 | slot update_slots: id  3 | task 10049 | erased invalidated context checkpoint (pos_min = 36620, pos_max = 36620, n_tokens = 36621, n_swa = 0, pos_next = 0, size = 226.320 MiB)
2026-05-15 18:50:29.478 | slot update_slots: id  3 | task 10049 | erased invalidated context checkpoint (pos_min = 37132, pos_max = 37132, n_tokens = 37133, n_swa = 0, pos_next = 0, size = 227.393 MiB)
2026-05-15 18:50:29.491 | slot update_slots: id  3 | task 10049 | n_tokens = 0, memory_seq_rm [0, end)
2026-05-15 18:50:29.492 | slot update_slots: id  3 | task 10049 | prompt processing progress, n_tokens = 2048, batch.n_tokens = 2048, progress = 0.031559
2026-05-15 18:50:30.196 | slot update_slots: id  3 | task 10049 | n_tokens = 2048, memory_seq_rm [2048, end)
2026-05-15 18:50:30.196 | slot update_slots: id  3 | task 10049 | prompt processing progress, n_tokens = 4096, batch.n_tokens = 2048, progress = 0.063118
2026-05-15 18:50:30.918 | slot update_slots: id  3 | task 10049 | n_tokens = 4096, memory_seq_rm [4096, end)
2026-05-15 18:50:30.918 | slot update_slots: id  3 | task 10049 | prompt processing progress, n_tokens = 6144, batch.n_tokens = 2048, progress = 0.094677
2026-05-15 18:50:31.645 | slot update_slots: id  3 | task 10049 | n_tokens = 6144, memory_seq_rm [6144, end)
2026-05-15 18:50:31.646 | slot update_slots: id  3 | task 10049 | prompt processing progress, n_tokens = 8192, batch.n_tokens = 2048, progress = 0.126237
2026-05-15 18:50:32.382 | slot update_slots: id  3 | task 10049 | n_tokens = 8192, memory_seq_rm [8192, end)
2026-05-15 18:50:32.382 | slot update_slots: id  3 | task 10049 | 8192 tokens since last checkpoint at 0, creating new checkpoint during processing at position 10240
2026-05-15 18:50:32.382 | slot update_slots: id  3 | task 10049 | prompt processing progress, n_tokens = 10240, batch.n_tokens = 2048, progress = 0.157796
2026-05-15 18:50:32.502 | slot create_check: id  3 | task 10049 | created context checkpoint 1 of 32 (pos_min = 8191, pos_max = 8191, n_tokens = 8192, size = 166.782 MiB)
2026-05-15 18:50:33.251 | slot update_slots: id  3 | task 10049 | n_tokens = 10240, memory_seq_rm [10240, end)
2026-05-15 18:50:33.251 | slot update_slots: id  3 | task 10049 | prompt processing progress, n_tokens = 12288, batch.n_tokens = 2048, progress = 0.189355
2026-05-15 18:50:34.019 | slot update_slots: id  3 | task 10049 | n_tokens = 12288, memory_seq_rm [12288, end)
2026-05-15 18:50:34.019 | slot update_slots: id  3 | task 10049 | prompt processing progress, n_tokens = 14336, batch.n_tokens = 2048, progress = 0.220914
2026-05-15 18:50:34.803 | slot update_slots: id  3 | task 10049 | n_tokens = 14336, memory_seq_rm [14336, end)
2026-05-15 18:50:34.803 | slot update_slots: id  3 | task 10049 | prompt processing progress, n_tokens = 16384, batch.n_tokens = 2048, progress = 0.252473
2026-05-15 18:50:35.611 | slot update_slots: id  3 | task 10049 | n_tokens = 16384, memory_seq_rm [16384, end)
2026-05-15 18:50:35.611 | slot update_slots: id  3 | task 10049 | 8192 tokens since last checkpoint at 8192, creating new checkpoint during processing at position 18432
2026-05-15 18:50:35.611 | slot update_slots: id  3 | task 10049 | prompt processing progress, n_tokens = 18432, batch.n_tokens = 2048, progress = 0.284032
2026-05-15 18:50:35.731 | slot create_check: id  3 | task 10049 | created context checkpoint 2 of 32 (pos_min = 16383, pos_max = 16383, n_tokens = 16384, size = 183.939 MiB)
2026-05-15 18:50:36.559 | slot update_slots: id  3 | task 10049 | n_tokens = 18432, memory_seq_rm [18432, end)
2026-05-15 18:50:36.559 | slot update_slots: id  3 | task 10049 | prompt processing progress, n_tokens = 20480, batch.n_tokens = 2048, progress = 0.315592
2026-05-15 18:50:37.375 | slot update_slots: id  3 | task 10049 | n_tokens = 20480, memory_seq_rm [20480, end)
2026-05-15 18:50:37.375 | slot update_slots: id  3 | task 10049 | prompt processing progress, n_tokens = 22528, batch.n_tokens = 2048, progress = 0.347151
2026-05-15 18:50:38.203 | slot update_slots: id  3 | task 10049 | n_tokens = 22528, memory_seq_rm [22528, end)
2026-05-15 18:50:38.204 | slot update_slots: id  3 | task 10049 | prompt processing progress, n_tokens = 24576, batch.n_tokens = 2048, progress = 0.378710
2026-05-15 18:50:39.048 | slot update_slots: id  3 | task 10049 | n_tokens = 24576, memory_seq_rm [24576, end)
2026-05-15 18:50:39.048 | slot update_slots: id  3 | task 10049 | 8192 tokens since last checkpoint at 16384, creating new checkpoint during processing at position 26624
2026-05-15 18:50:39.048 | slot update_slots: id  3 | task 10049 | prompt processing progress, n_tokens = 26624, batch.n_tokens = 2048, progress = 0.410269
2026-05-15 18:50:39.202 | slot create_check: id  3 | task 10049 | created context checkpoint 3 of 32 (pos_min = 24575, pos_max = 24575, n_tokens = 24576, size = 201.095 MiB)
2026-05-15 18:50:40.059 | slot update_slots: id  3 | task 10049 | n_tokens = 26624, memory_seq_rm [26624, end)
2026-05-15 18:50:40.059 | slot update_slots: id  3 | task 10049 | prompt processing progress, n_tokens = 28672, batch.n_tokens = 2048, progress = 0.441828
2026-05-15 18:50:40.946 | slot update_slots: id  3 | task 10049 | n_tokens = 28672, memory_seq_rm [28672, end)
2026-05-15 18:50:40.946 | slot update_slots: id  3 | task 10049 | prompt processing progress, n_tokens = 30720, batch.n_tokens = 2048, progress = 0.473387
2026-05-15 18:50:41.868 | slot update_slots: id  3 | task 10049 | n_tokens = 30720, memory_seq_rm [30720, end)
2026-05-15 18:50:41.868 | slot update_slots: id  3 | task 10049 | prompt processing progress, n_tokens = 32768, batch.n_tokens = 2048, progress = 0.504947
2026-05-15 18:50:42.814 | slot update_slots: id  3 | task 10049 | n_tokens = 32768, memory_seq_rm [32768, end)
2026-05-15 18:50:42.814 | slot update_slots: id  3 | task 10049 | 8192 tokens since last checkpoint at 24576, creating new checkpoint during processing at position 34816
2026-05-15 18:50:42.814 | slot update_slots: id  3 | task 10049 | prompt processing progress, n_tokens = 34816, batch.n_tokens = 2048, progress = 0.536506
2026-05-15 18:50:43.062 | slot create_check: id  3 | task 10049 | created context checkpoint 4 of 32 (pos_min = 32767, pos_max = 32767, n_tokens = 32768, size = 218.251 MiB)
2026-05-15 18:50:44.023 | slot update_slots: id  3 | task 10049 | n_tokens = 34816, memory_seq_rm [34816, end)
2026-05-15 18:50:44.023 | slot update_slots: id  3 | task 10049 | prompt processing progress, n_tokens = 36864, batch.n_tokens = 2048, progress = 0.568065
2026-05-15 18:50:44.983 | slot update_slots: id  3 | task 10049 | n_tokens = 36864, memory_seq_rm [36864, end)
2026-05-15 18:50:44.983 | slot update_slots: id  3 | task 10049 | prompt processing progress, n_tokens = 38912, batch.n_tokens = 2048, progress = 0.599624
2026-05-15 18:50:45.984 | slot update_slots: id  3 | task 10049 | n_tokens = 38912, memory_seq_rm [38912, end)
2026-05-15 18:50:45.985 | slot update_slots: id  3 | task 10049 | prompt processing progress, n_tokens = 40960, batch.n_tokens = 2048, progress = 0.631183
2026-05-15 18:50:46.997 | slot update_slots: id  3 | task 10049 | n_tokens = 40960, memory_seq_rm [40960, end)
2026-05-15 18:50:46.997 | slot update_slots: id  3 | task 10049 | 8192 tokens since last checkpoint at 32768, creating new checkpoint during processing at position 43008
2026-05-15 18:50:46.997 | slot update_slots: id  3 | task 10049 | prompt processing progress, n_tokens = 43008, batch.n_tokens = 2048, progress = 0.662742
2026-05-15 18:50:47.263 | slot create_check: id  3 | task 10049 | created context checkpoint 5 of 32 (pos_min = 40959, pos_max = 40959, n_tokens = 40960, size = 235.407 MiB)
2026-05-15 18:50:48.294 | slot update_slots: id  3 | task 10049 | n_tokens = 43008, memory_seq_rm [43008, end)
2026-05-15 18:50:48.294 | slot update_slots: id  3 | task 10049 | prompt processing progress, n_tokens = 45056, batch.n_tokens = 2048, progress = 0.694301
2026-05-15 18:50:49.353 | slot update_slots: id  3 | task 10049 | n_tokens = 45056, memory_seq_rm [45056, end)
2026-05-15 18:50:49.353 | slot update_slots: id  3 | task 10049 | prompt processing progress, n_tokens = 47104, batch.n_tokens = 2048, progress = 0.725861
2026-05-15 18:50:50.445 | slot update_slots: id  3 | task 10049 | n_tokens = 47104, memory_seq_rm [47104, end)
2026-05-15 18:50:50.446 | slot update_slots: id  3 | task 10049 | prompt processing progress, n_tokens = 49152, batch.n_tokens = 2048, progress = 0.757420
2026-05-15 18:50:51.564 | slot update_slots: id  3 | task 10049 | n_tokens = 49152, memory_seq_rm [49152, end)
2026-05-15 18:50:51.565 | slot update_slots: id  3 | task 10049 | 8192 tokens since last checkpoint at 40960, creating new checkpoint during processing at position 51200
2026-05-15 18:50:51.565 | slot update_slots: id  3 | task 10049 | prompt processing progress, n_tokens = 51200, batch.n_tokens = 2048, progress = 0.788979
2026-05-15 18:50:51.793 | slot create_check: id  3 | task 10049 | created context checkpoint 6 of 32 (pos_min = 49151, pos_max = 49151, n_tokens = 49152, size = 252.564 MiB)
2026-05-15 18:50:52.932 | slot update_slots: id  3 | task 10049 | n_tokens = 51200, memory_seq_rm [51200, end)
2026-05-15 18:50:52.932 | slot update_slots: id  3 | task 10049 | prompt processing progress, n_tokens = 53248, batch.n_tokens = 2048, progress = 0.820538
2026-05-15 18:50:54.099 | slot update_slots: id  3 | task 10049 | n_tokens = 53248, memory_seq_rm [53248, end)
2026-05-15 18:50:54.099 | slot update_slots: id  3 | task 10049 | prompt processing progress, n_tokens = 55296, batch.n_tokens = 2048, progress = 0.852097
2026-05-15 18:50:55.295 | slot update_slots: id  3 | task 10049 | n_tokens = 55296, memory_seq_rm [55296, end)
2026-05-15 18:50:55.295 | slot update_slots: id  3 | task 10049 | prompt processing progress, n_tokens = 57344, batch.n_tokens = 2048, progress = 0.883656
2026-05-15 18:50:56.529 | slot update_slots: id  3 | task 10049 | n_tokens = 57344, memory_seq_rm [57344, end)
2026-05-15 18:50:56.529 | slot update_slots: id  3 | task 10049 | 8192 tokens since last checkpoint at 49152, creating new checkpoint during processing at position 59392
2026-05-15 18:50:56.529 | slot update_slots: id  3 | task 10049 | prompt processing progress, n_tokens = 59392, batch.n_tokens = 2048, progress = 0.915216
2026-05-15 18:50:56.818 | slot create_check: id  3 | task 10049 | created context checkpoint 7 of 32 (pos_min = 57343, pos_max = 57343, n_tokens = 57344, size = 269.720 MiB)
2026-05-15 18:50:58.067 | slot update_slots: id  3 | task 10049 | n_tokens = 59392, memory_seq_rm [59392, end)
2026-05-15 18:50:58.068 | slot update_slots: id  3 | task 10049 | prompt processing progress, n_tokens = 61440, batch.n_tokens = 2048, progress = 0.946775
2026-05-15 18:50:59.351 | slot update_slots: id  3 | task 10049 | n_tokens = 61440, memory_seq_rm [61440, end)
2026-05-15 18:50:59.351 | slot update_slots: id  3 | task 10049 | prompt processing progress, n_tokens = 63488, batch.n_tokens = 2048, progress = 0.978334
2026-05-15 18:51:00.671 | slot update_slots: id  3 | task 10049 | n_tokens = 63488, memory_seq_rm [63488, end)
2026-05-15 18:51:00.671 | slot update_slots: id  3 | task 10049 | prompt processing progress, n_tokens = 64378, batch.n_tokens = 890, progress = 0.992049
2026-05-15 18:51:01.301 | slot update_slots: id  3 | task 10049 | n_tokens = 64378, memory_seq_rm [64378, end)
2026-05-15 18:51:01.301 | slot update_slots: id  3 | task 10049 | prompt processing progress, n_tokens = 64890, batch.n_tokens = 512, progress = 0.999938
2026-05-15 18:51:01.651 | slot create_check: id  3 | task 10049 | created context checkpoint 8 of 32 (pos_min = 64377, pos_max = 64377, n_tokens = 64378, size = 284.451 MiB)
2026-05-15 18:51:02.003 | slot update_slots: id  3 | task 10049 | n_tokens = 64890, memory_seq_rm [64890, end)
2026-05-15 18:51:02.012 | slot init_sampler: id  3 | task 10049 | init sampler, took 8.62 ms, tokens: text = 64894, total = 64894
2026-05-15 18:51:02.012 | slot update_slots: id  3 | task 10049 | prompt processing done, n_tokens = 64894, batch.n_tokens = 4
2026-05-15 18:51:02.339 | slot create_check: id  3 | task 10049 | created context checkpoint 9 of 32 (pos_min = 64889, pos_max = 64889, n_tokens = 64890, size = 285.523 MiB)
2026-05-15 18:51:02.380 | srv  log_server_r: done request: POST /v1/chat/completions 172.18.0.1 200
2026-05-15 18:51:03.677 | reasoning-budget: deactivated (natural end)
2026-05-15 18:51:05.247 | slot print_timing: id  3 | task 10049 | 
2026-05-15 18:51:05.247 | prompt eval time =   32981.54 ms / 64894 tokens (    0.51 ms per token,  1967.59 tokens per second)
2026-05-15 18:51:05.247 |        eval time =    2867.07 ms /   173 tokens (   16.57 ms per token,    60.34 tokens per second)
2026-05-15 18:51:05.247 |       total time =   35848.62 ms / 65067 tokens
2026-05-15 18:51:05.247 | draft acceptance rate = 0.99048 (  104 accepted /   105 generated)
2026-05-15 18:51:05.247 | statistics mtp: #calls(b,g,a) = 92 9086 7522, #gen drafts = 7522, #acc drafts = 7522, #gen tokens = 13326, #acc tokens = 13118, dur(b,g,a) = 0.124, 37750.590, 3.107 ms
2026-05-15 18:51:05.249 | slot      release: id  3 | task 10049 | stop processing: n_tokens = 65066, truncated = 0
2026-05-15 18:51:05.249 | srv  update_slots: all slots are idle
2026-05-15 18:51:05.533 | srv  params_from_: Chat format: peg-native
2026-05-15 18:51:05.535 | slot get_availabl: id  3 | task -1 | selected slot by LCP similarity, sim_best = 0.968 (> 0.100 thold), f_keep = 1.000
2026-05-15 18:51:05.536 | reasoning-budget: activated, budget=2147483647 tokens
2026-05-15 18:51:05.536 | slot launch_slot_: id  3 | task -1 | sampler chain: logits -> penalties -> ?dry -> ?top-n-sigma -> top-k -> ?typical -> ?top-p -> min-p -> ?xtc -> ?temp-ext -> dist 
2026-05-15 18:51:05.536 | slot launch_slot_: id  3 | task 10159 | processing task, is_child = 0
2026-05-15 18:51:05.536 | slot update_slots: id  3 | task 10159 | new prompt, n_ctx_slot = 131072, n_keep = 0, task.n_tokens = 67227
2026-05-15 18:51:05.536 | slot update_slots: id  3 | task 10159 | n_tokens = 65066, memory_seq_rm [65066, end)
2026-05-15 18:51:05.537 | slot update_slots: id  3 | task 10159 | prompt processing progress, n_tokens = 66711, batch.n_tokens = 1645, progress = 0.992325
2026-05-15 18:51:06.649 | slot update_slots: id  3 | task 10159 | n_tokens = 66711, memory_seq_rm [66711, end)
2026-05-15 18:51:06.649 | slot update_slots: id  3 | task 10159 | prompt processing progress, n_tokens = 67223, batch.n_tokens = 512, progress = 0.999941
2026-05-15 18:51:06.967 | slot create_check: id  3 | task 10159 | created context checkpoint 10 of 32 (pos_min = 66710, pos_max = 66710, n_tokens = 66711, size = 289.337 MiB)
2026-05-15 18:51:07.317 | slot update_slots: id  3 | task 10159 | n_tokens = 67223, memory_seq_rm [67223, end)
2026-05-15 18:51:07.325 | slot init_sampler: id  3 | task 10159 | init sampler, took 8.58 ms, tokens: text = 67227, total = 67227
2026-05-15 18:51:07.325 | slot update_slots: id  3 | task 10159 | prompt processing done, n_tokens = 67227, batch.n_tokens = 4
2026-05-15 18:51:07.649 | slot create_check: id  3 | task 10159 | created context checkpoint 11 of 32 (pos_min = 67222, pos_max = 67222, n_tokens = 67223, size = 290.409 MiB)
2026-05-15 18:51:07.690 | srv  log_server_r: done request: POST /v1/chat/completions 172.18.0.1 200
2026-05-15 18:51:08.539 | reasoning-budget: deactivated (natural end)
2026-05-15 18:51:09.185 | slot print_timing: id  3 | task 10159 | 
2026-05-15 18:51:09.185 | prompt eval time =    2152.69 ms /  2161 tokens (    1.00 ms per token,  1003.86 tokens per second)
2026-05-15 18:51:09.185 |        eval time =    1495.97 ms /   107 tokens (   13.98 ms per token,    71.53 tokens per second)
2026-05-15 18:51:09.185 |       total time =    3648.66 ms /  2268 tokens
2026-05-15 18:51:09.185 | draft acceptance rate = 1.00000 (   68 accepted /    68 generated)
2026-05-15 18:51:09.185 | statistics mtp: #calls(b,g,a) = 93 9124 7558, #gen drafts = 7558, #acc drafts = 7558, #gen tokens = 13394, #acc tokens = 13186, dur(b,g,a) = 0.125, 37924.955, 3.125 ms
2026-05-15 18:51:09.187 | slot      release: id  3 | task 10159 | stop processing: n_tokens = 67333, truncated = 0
2026-05-15 18:51:09.187 | srv  update_slots: all slots are idle
2026-05-15 18:51:09.506 | srv  params_from_: Chat format: peg-native
2026-05-15 18:51:09.508 | slot get_availabl: id  3 | task -1 | selected slot by LCP similarity, sim_best = 0.975 (> 0.100 thold), f_keep = 1.000
2026-05-15 18:51:09.509 | reasoning-budget: activated, budget=2147483647 tokens
2026-05-15 18:51:09.509 | slot launch_slot_: id  3 | task -1 | sampler chain: logits -> penalties -> ?dry -> ?top-n-sigma -> top-k -> ?typical -> ?top-p -> min-p -> ?xtc -> ?temp-ext -> dist 
2026-05-15 18:51:09.509 | slot launch_slot_: id  3 | task 10201 | processing task, is_child = 0
2026-05-15 18:51:09.509 | slot update_slots: id  3 | task 10201 | new prompt, n_ctx_slot = 131072, n_keep = 0, task.n_tokens = 69033
2026-05-15 18:51:09.509 | slot update_slots: id  3 | task 10201 | n_tokens = 67333, memory_seq_rm [67333, end)
2026-05-15 18:51:09.510 | slot update_slots: id  3 | task 10201 | prompt processing progress, n_tokens = 68517, batch.n_tokens = 1184, progress = 0.992525
2026-05-15 18:51:10.323 | slot update_slots: id  3 | task 10201 | n_tokens = 68517, memory_seq_rm [68517, end)
2026-05-15 18:51:10.324 | slot update_slots: id  3 | task 10201 | prompt processing progress, n_tokens = 69029, batch.n_tokens = 512, progress = 0.999942
2026-05-15 18:51:10.650 | slot create_check: id  3 | task 10201 | created context checkpoint 12 of 32 (pos_min = 68516, pos_max = 68516, n_tokens = 68517, size = 293.119 MiB)
2026-05-15 18:51:11.005 | slot update_slots: id  3 | task 10201 | n_tokens = 69029, memory_seq_rm [69029, end)
2026-05-15 18:51:11.014 | slot init_sampler: id  3 | task 10201 | init sampler, took 9.03 ms, tokens: text = 69033, total = 69033
2026-05-15 18:51:11.014 | slot update_slots: id  3 | task 10201 | prompt processing done, n_tokens = 69033, batch.n_tokens = 4
2026-05-15 18:51:11.341 | slot create_check: id  3 | task 10201 | created context checkpoint 13 of 32 (pos_min = 69028, pos_max = 69028, n_tokens = 69029, size = 294.191 MiB)
2026-05-15 18:51:11.380 | srv  log_server_r: done request: POST /v1/chat/completions 172.18.0.1 200
2026-05-15 18:51:12.081 | reasoning-budget: deactivated (natural end)
2026-05-15 18:51:13.542 | slot print_timing: id  3 | task 10201 | 
2026-05-15 18:51:13.542 | prompt eval time =    1869.75 ms /  1700 tokens (    1.10 ms per token,   909.21 tokens per second)
2026-05-15 18:51:13.542 |        eval time =    2162.88 ms /   159 tokens (   13.60 ms per token,    73.51 tokens per second)
2026-05-15 18:51:13.542 |       total time =    4032.62 ms /  1859 tokens
2026-05-15 18:51:13.542 | draft acceptance rate = 1.00000 (  102 accepted /   102 generated)
2026-05-15 18:51:13.542 | statistics mtp: #calls(b,g,a) = 94 9180 7612, #gen drafts = 7612, #acc drafts = 7612, #gen tokens = 13496, #acc tokens = 13288, dur(b,g,a) = 0.127, 38183.115, 3.145 ms
2026-05-15 18:51:13.544 | slot      release: id  3 | task 10201 | stop processing: n_tokens = 69191, truncated = 0
2026-05-15 18:51:13.544 | srv  update_slots: all slots are idle
2026-05-15 18:51:13.844 | srv  params_from_: Chat format: peg-native
2026-05-15 18:51:13.846 | slot get_availabl: id  3 | task -1 | selected slot by LCP similarity, sim_best = 0.999 (> 0.100 thold), f_keep = 1.000
2026-05-15 18:51:13.848 | reasoning-budget: activated, budget=2147483647 tokens
2026-05-15 18:51:13.848 | slot launch_slot_: id  3 | task -1 | sampler chain: logits -> penalties -> ?dry -> ?top-n-sigma -> top-k -> ?typical -> ?top-p -> min-p -> ?xtc -> ?temp-ext -> dist 
2026-05-15 18:51:13.848 | slot launch_slot_: id  3 | task 10261 | processing task, is_child = 0
2026-05-15 18:51:13.848 | slot update_slots: id  3 | task 10261 | new prompt, n_ctx_slot = 131072, n_keep = 0, task.n_tokens = 69254
2026-05-15 18:51:13.848 | slot update_slots: id  3 | task 10261 | n_tokens = 69191, memory_seq_rm [69191, end)
2026-05-15 18:51:13.848 | slot update_slots: id  3 | task 10261 | prompt processing progress, n_tokens = 69250, batch.n_tokens = 59, progress = 0.999942
2026-05-15 18:51:14.181 | slot create_check: id  3 | task 10261 | created context checkpoint 14 of 32 (pos_min = 69190, pos_max = 69190, n_tokens = 69191, size = 294.531 MiB)
2026-05-15 18:51:14.242 | slot update_slots: id  3 | task 10261 | n_tokens = 69250, memory_seq_rm [69250, end)
2026-05-15 18:51:14.252 | slot init_sampler: id  3 | task 10261 | init sampler, took 8.98 ms, tokens: text = 69254, total = 69254
2026-05-15 18:51:14.252 | slot update_slots: id  3 | task 10261 | prompt processing done, n_tokens = 69254, batch.n_tokens = 4
2026-05-15 18:51:14.291 | srv  log_server_r: done request: POST /v1/chat/completions 172.18.0.1 200
2026-05-15 18:51:15.504 | reasoning-budget: deactivated (natural end)
2026-05-15 18:51:16.707 | slot print_timing: id  3 | task 10261 | 
2026-05-15 18:51:16.707 | prompt eval time =     442.79 ms /    63 tokens (    7.03 ms per token,   142.28 tokens per second)
2026-05-15 18:51:16.707 |        eval time =    2402.77 ms /   165 tokens (   14.56 ms per token,    68.67 tokens per second)
2026-05-15 18:51:16.707 |       total time =    2845.57 ms /   228 tokens
2026-05-15 18:51:16.707 | draft acceptance rate = 1.00000 (  102 accepted /   102 generated)
2026-05-15 18:51:16.707 | statistics mtp: #calls(b,g,a) = 95 9242 7665, #gen drafts = 7665, #acc drafts = 7665, #gen tokens = 13598, #acc tokens = 13390, dur(b,g,a) = 0.128, 38454.732, 3.173 ms
2026-05-15 18:51:16.709 | slot      release: id  3 | task 10261 | stop processing: n_tokens = 69418, truncated = 0
2026-05-15 18:51:16.709 | srv  update_slots: all slots are idle
2026-05-15 18:51:17.024 | srv  params_from_: Chat format: peg-native
2026-05-15 18:51:17.026 | slot get_availabl: id  3 | task -1 | selected slot by LCP similarity, sim_best = 0.727 (> 0.100 thold), f_keep = 1.000
2026-05-15 18:51:17.028 | reasoning-budget: activated, budget=2147483647 tokens
2026-05-15 18:51:17.028 | slot launch_slot_: id  3 | task -1 | sampler chain: logits -> penalties -> ?dry -> ?top-n-sigma -> top-k -> ?typical -> ?top-p -> min-p -> ?xtc -> ?temp-ext -> dist 
2026-05-15 18:51:17.028 | slot launch_slot_: id  3 | task 10328 | processing task, is_child = 0
2026-05-15 18:51:17.028 | slot update_slots: id  3 | task 10328 | new prompt, n_ctx_slot = 131072, n_keep = 0, task.n_tokens = 95509
2026-05-15 18:51:17.028 | slot update_slots: id  3 | task 10328 | n_tokens = 69418, memory_seq_rm [69418, end)
2026-05-15 18:51:17.028 | slot update_slots: id  3 | task 10328 | prompt processing progress, n_tokens = 71466, batch.n_tokens = 2048, progress = 0.748265
2026-05-15 18:51:18.465 | slot update_slots: id  3 | task 10328 | n_tokens = 71466, memory_seq_rm [71466, end)
2026-05-15 18:51:18.465 | slot update_slots: id  3 | task 10328 | prompt processing progress, n_tokens = 73514, batch.n_tokens = 2048, progress = 0.769708
2026-05-15 18:51:19.919 | slot update_slots: id  3 | task 10328 | n_tokens = 73514, memory_seq_rm [73514, end)
2026-05-15 18:51:19.919 | slot update_slots: id  3 | task 10328 | prompt processing progress, n_tokens = 75562, batch.n_tokens = 2048, progress = 0.791151
2026-05-15 18:51:21.400 | slot update_slots: id  3 | task 10328 | n_tokens = 75562, memory_seq_rm [75562, end)
2026-05-15 18:51:21.400 | slot update_slots: id  3 | task 10328 | prompt processing progress, n_tokens = 77610, batch.n_tokens = 2048, progress = 0.812594
2026-05-15 18:51:22.916 | slot update_slots: id  3 | task 10328 | n_tokens = 77610, memory_seq_rm [77610, end)
2026-05-15 18:51:22.916 | slot update_slots: id  3 | task 10328 | 8192 tokens since last checkpoint at 69191, creating new checkpoint during processing at position 79658
2026-05-15 18:51:22.916 | slot update_slots: id  3 | task 10328 | prompt processing progress, n_tokens = 79658, batch.n_tokens = 2048, progress = 0.834037
2026-05-15 18:51:23.260 | slot create_check: id  3 | task 10328 | created context checkpoint 15 of 32 (pos_min = 77609, pos_max = 77609, n_tokens = 77610, size = 312.162 MiB)
2026-05-15 18:51:24.795 | slot update_slots: id  3 | task 10328 | n_tokens = 79658, memory_seq_rm [79658, end)
2026-05-15 18:51:24.796 | slot update_slots: id  3 | task 10328 | prompt processing progress, n_tokens = 81706, batch.n_tokens = 2048, progress = 0.855480
2026-05-15 18:51:26.363 | slot update_slots: id  3 | task 10328 | n_tokens = 81706, memory_seq_rm [81706, end)
2026-05-15 18:51:26.363 | slot update_slots: id  3 | task 10328 | prompt processing progress, n_tokens = 83754, batch.n_tokens = 2048, progress = 0.876923
2026-05-15 18:51:27.948 | slot update_slots: id  3 | task 10328 | n_tokens = 83754, memory_seq_rm [83754, end)
2026-05-15 18:51:27.948 | slot update_slots: id  3 | task 10328 | prompt processing progress, n_tokens = 85802, batch.n_tokens = 2048, progress = 0.898366
2026-05-15 18:51:29.570 | slot update_slots: id  3 | task 10328 | n_tokens = 85802, memory_seq_rm [85802, end)
2026-05-15 18:51:29.570 | slot update_slots: id  3 | task 10328 | 8192 tokens since last checkpoint at 77610, creating new checkpoint during processing at position 87850
2026-05-15 18:51:29.570 | slot update_slots: id  3 | task 10328 | prompt processing progress, n_tokens = 87850, batch.n_tokens = 2048, progress = 0.919809
2026-05-15 18:51:29.937 | slot create_check: id  3 | task 10328 | created context checkpoint 16 of 32 (pos_min = 85801, pos_max = 85801, n_tokens = 85802, size = 329.319 MiB)
2026-05-15 18:51:31.578 | slot update_slots: id  3 | task 10328 | n_tokens = 87850, memory_seq_rm [87850, end)
2026-05-15 18:51:31.578 | slot update_slots: id  3 | task 10328 | prompt processing progress, n_tokens = 89898, batch.n_tokens = 2048, progress = 0.941252
2026-05-15 18:51:33.246 | slot update_slots: id  3 | task 10328 | n_tokens = 89898, memory_seq_rm [89898, end)
2026-05-15 18:51:33.247 | slot update_slots: id  3 | task 10328 | prompt processing progress, n_tokens = 91946, batch.n_tokens = 2048, progress = 0.962695
2026-05-15 18:51:34.923 | slot update_slots: id  3 | task 10328 | n_tokens = 91946, memory_seq_rm [91946, end)
2026-05-15 18:51:34.923 | slot update_slots: id  3 | task 10328 | prompt processing progress, n_tokens = 93994, batch.n_tokens = 2048, progress = 0.984138
2026-05-15 18:51:36.619 | slot update_slots: id  3 | task 10328 | n_tokens = 93994, memory_seq_rm [93994, end)
2026-05-15 18:51:36.619 | slot update_slots: id  3 | task 10328 | 8192 tokens since last checkpoint at 85802, creating new checkpoint during processing at position 94993
2026-05-15 18:51:36.619 | slot update_slots: id  3 | task 10328 | prompt processing progress, n_tokens = 94993, batch.n_tokens = 999, progress = 0.994597
2026-05-15 18:51:37.001 | slot create_check: id  3 | task 10328 | created context checkpoint 17 of 32 (pos_min = 93993, pos_max = 93993, n_tokens = 93994, size = 346.475 MiB)
2026-05-15 18:51:37.852 | slot update_slots: id  3 | task 10328 | n_tokens = 94993, memory_seq_rm [94993, end)
2026-05-15 18:51:37.852 | slot update_slots: id  3 | task 10328 | prompt processing progress, n_tokens = 95505, batch.n_tokens = 512, progress = 0.999958
2026-05-15 18:51:38.236 | slot create_check: id  3 | task 10328 | created context checkpoint 18 of 32 (pos_min = 94992, pos_max = 94992, n_tokens = 94993, size = 348.567 MiB)
2026-05-15 18:51:38.671 | slot update_slots: id  3 | task 10328 | n_tokens = 95505, memory_seq_rm [95505, end)
2026-05-15 18:51:38.683 | slot init_sampler: id  3 | task 10328 | init sampler, took 12.12 ms, tokens: text = 95509, total = 95509
2026-05-15 18:51:38.683 | slot update_slots: id  3 | task 10328 | prompt processing done, n_tokens = 95509, batch.n_tokens = 4
2026-05-15 18:51:39.072 | slot create_check: id  3 | task 10328 | created context checkpoint 19 of 32 (pos_min = 95504, pos_max = 95504, n_tokens = 95505, size = 349.639 MiB)
2026-05-15 18:51:39.115 | srv  log_server_r: done request: POST /v1/chat/completions 172.18.0.1 200
2026-05-15 18:51:45.471 | reasoning-budget: deactivated (natural end)
2026-05-15 18:51:47.001 | slot print_timing: id  3 | task 10328 | 
2026-05-15 18:51:47.001 | prompt eval time =   22086.79 ms / 26091 tokens (    0.85 ms per token,  1181.29 tokens per second)
2026-05-15 18:51:47.001 |        eval time =    7863.54 ms /   402 tokens (   19.56 ms per token,    51.12 tokens per second)
2026-05-15 18:51:47.001 |       total time =   29950.33 ms / 26493 tokens
2026-05-15 18:51:47.001 | draft acceptance rate = 0.98214 (  220 accepted /   224 generated)
2026-05-15 18:51:47.001 | statistics mtp: #calls(b,g,a) = 96 9423 7794, #gen drafts = 7794, #acc drafts = 7794, #gen tokens = 13822, #acc tokens = 13610, dur(b,g,a) = 0.129, 39206.937, 3.224 ms
2026-05-15 18:51:47.003 | slot      release: id  3 | task 10328 | stop processing: n_tokens = 95910, truncated = 0
2026-05-15 18:51:47.003 | srv  update_slots: all slots are idle
2026-05-15 18:51:47.332 | srv  params_from_: Chat format: peg-native
2026-05-15 18:51:47.335 | slot get_availabl: id  3 | task -1 | selected slot by LCP similarity, sim_best = 0.998 (> 0.100 thold), f_keep = 1.000
2026-05-15 18:51:47.336 | reasoning-budget: activated, budget=2147483647 tokens
2026-05-15 18:51:47.336 | slot launch_slot_: id  3 | task -1 | sampler chain: logits -> penalties -> ?dry -> ?top-n-sigma -> top-k -> ?typical -> ?top-p -> min-p -> ?xtc -> ?temp-ext -> dist 
2026-05-15 18:51:47.336 | slot launch_slot_: id  3 | task 10542 | processing task, is_child = 0
2026-05-15 18:51:47.336 | slot update_slots: id  3 | task 10542 | new prompt, n_ctx_slot = 131072, n_keep = 0, task.n_tokens = 96147
2026-05-15 18:51:47.337 | slot update_slots: id  3 | task 10542 | n_tokens = 95910, memory_seq_rm [95910, end)
2026-05-15 18:51:47.337 | slot update_slots: id  3 | task 10542 | prompt processing progress, n_tokens = 96143, batch.n_tokens = 233, progress = 0.999958
2026-05-15 18:51:47.723 | slot create_check: id  3 | task 10542 | created context checkpoint 20 of 32 (pos_min = 95909, pos_max = 95909, n_tokens = 95910, size = 350.487 MiB)
2026-05-15 18:51:47.897 | slot update_slots: id  3 | task 10542 | n_tokens = 96143, memory_seq_rm [96143, end)
2026-05-15 18:51:47.909 | slot init_sampler: id  3 | task 10542 | init sampler, took 12.22 ms, tokens: text = 96147, total = 96147
2026-05-15 18:51:47.909 | slot update_slots: id  3 | task 10542 | prompt processing done, n_tokens = 96147, batch.n_tokens = 4
2026-05-15 18:51:48.303 | slot create_check: id  3 | task 10542 | created context checkpoint 21 of 32 (pos_min = 96142, pos_max = 96142, n_tokens = 96143, size = 350.975 MiB)
2026-05-15 18:51:48.348 | srv  log_server_r: done request: POST /v1/chat/completions 172.18.0.1 200
2026-05-15 18:51:51.393 | reasoning-budget: deactivated (natural end)
2026-05-15 18:51:52.039 | slot print_timing: id  3 | task 10542 | 
2026-05-15 18:51:52.039 | prompt eval time =    1011.22 ms /   237 tokens (    4.27 ms per token,   234.37 tokens per second)
2026-05-15 18:51:52.039 |        eval time =    3691.14 ms /   242 tokens (   15.25 ms per token,    65.56 tokens per second)
2026-05-15 18:51:52.039 |       total time =    4702.36 ms /   479 tokens
2026-05-15 18:51:52.039 | draft acceptance rate = 0.99346 (  152 accepted /   153 generated)
2026-05-15 18:51:52.039 | statistics mtp: #calls(b,g,a) = 97 9512 7876, #gen drafts = 7876, #acc drafts = 7876, #gen tokens = 13975, #acc tokens = 13762, dur(b,g,a) = 0.130, 39632.756, 3.260 ms
2026-05-15 18:51:52.041 | slot      release: id  3 | task 10542 | stop processing: n_tokens = 96388, truncated = 0
2026-05-15 18:51:52.042 | srv  update_slots: all slots are idle
2026-05-15 18:51:52.363 | srv  params_from_: Chat format: peg-native
2026-05-15 18:51:52.366 | slot get_availabl: id  3 | task -1 | selected slot by LCP similarity, sim_best = 0.995 (> 0.100 thold), f_keep = 1.000
2026-05-15 18:51:52.367 | reasoning-budget: activated, budget=2147483647 tokens
2026-05-15 18:51:52.367 | slot launch_slot_: id  3 | task -1 | sampler chain: logits -> penalties -> ?dry -> ?top-n-sigma -> top-k -> ?typical -> ?top-p -> min-p -> ?xtc -> ?temp-ext -> dist 
2026-05-15 18:51:52.367 | slot launch_slot_: id  3 | task 10635 | processing task, is_child = 0
2026-05-15 18:51:52.367 | slot update_slots: id  3 | task 10635 | new prompt, n_ctx_slot = 131072, n_keep = 0, task.n_tokens = 96909
2026-05-15 18:51:52.367 | slot update_slots: id  3 | task 10635 | n_tokens = 96388, memory_seq_rm [96388, end)
2026-05-15 18:51:52.367 | slot update_slots: id  3 | task 10635 | prompt processing progress, n_tokens = 96393, batch.n_tokens = 5, progress = 0.994675
2026-05-15 18:51:52.412 | slot update_slots: id  3 | task 10635 | n_tokens = 96393, memory_seq_rm [96393, end)
2026-05-15 18:51:52.412 | slot update_slots: id  3 | task 10635 | prompt processing progress, n_tokens = 96905, batch.n_tokens = 512, progress = 0.999959
2026-05-15 18:51:52.783 | slot create_check: id  3 | task 10635 | created context checkpoint 22 of 32 (pos_min = 96392, pos_max = 96392, n_tokens = 96393, size = 351.499 MiB)
2026-05-15 18:51:53.221 | slot update_slots: id  3 | task 10635 | n_tokens = 96905, memory_seq_rm [96905, end)
2026-05-15 18:51:53.234 | slot init_sampler: id  3 | task 10635 | init sampler, took 12.49 ms, tokens: text = 96909, total = 96909
2026-05-15 18:51:53.234 | slot update_slots: id  3 | task 10635 | prompt processing done, n_tokens = 96909, batch.n_tokens = 4
2026-05-15 18:51:53.628 | slot create_check: id  3 | task 10635 | created context checkpoint 23 of 32 (pos_min = 96904, pos_max = 96904, n_tokens = 96905, size = 352.571 MiB)
2026-05-15 18:51:53.671 | srv  log_server_r: done request: POST /v1/chat/completions 172.18.0.1 200
2026-05-15 18:51:56.581 | reasoning-budget: deactivated (natural end)
2026-05-15 18:51:57.328 | slot print_timing: id  3 | task 10635 | 
2026-05-15 18:51:57.328 | prompt eval time =    1303.24 ms /   521 tokens (    2.50 ms per token,   399.77 tokens per second)
2026-05-15 18:51:57.328 |        eval time =    3656.93 ms /   238 tokens (   15.37 ms per token,    65.08 tokens per second)
2026-05-15 18:51:57.328 |       total time =    4960.17 ms /   759 tokens
2026-05-15 18:51:57.328 | draft acceptance rate = 0.98684 (  150 accepted /   152 generated)
2026-05-15 18:51:57.328 | statistics mtp: #calls(b,g,a) = 98 9599 7954, #gen drafts = 7954, #acc drafts = 7954, #gen tokens = 14127, #acc tokens = 13912, dur(b,g,a) = 0.132, 40041.255, 3.292 ms
2026-05-15 18:51:57.330 | slot      release: id  3 | task 10635 | stop processing: n_tokens = 97146, truncated = 0
2026-05-15 18:51:57.330 | srv  update_slots: all slots are idle
2026-05-15 18:51:57.677 | srv  params_from_: Chat format: peg-native
2026-05-15 18:51:57.680 | slot get_availabl: id  3 | task -1 | selected slot by LCP similarity, sim_best = 0.890 (> 0.100 thold), f_keep = 1.000
2026-05-15 18:51:57.681 | reasoning-budget: activated, budget=2147483647 tokens
2026-05-15 18:51:57.681 | slot launch_slot_: id  3 | task -1 | sampler chain: logits -> penalties -> ?dry -> ?top-n-sigma -> top-k -> ?typical -> ?top-p -> min-p -> ?xtc -> ?temp-ext -> dist 
2026-05-15 18:51:57.681 | slot launch_slot_: id  3 | task 10730 | processing task, is_child = 0
2026-05-15 18:51:57.681 | slot update_slots: id  3 | task 10730 | new prompt, n_ctx_slot = 131072, n_keep = 0, task.n_tokens = 109152
2026-05-15 18:51:57.681 | slot update_slots: id  3 | task 10730 | n_tokens = 97146, memory_seq_rm [97146, end)
2026-05-15 18:51:57.681 | slot update_slots: id  3 | task 10730 | prompt processing progress, n_tokens = 99194, batch.n_tokens = 2048, progress = 0.908769
2026-05-15 18:51:59.445 | slot update_slots: id  3 | task 10730 | n_tokens = 99194, memory_seq_rm [99194, end)
2026-05-15 18:51:59.445 | slot update_slots: id  3 | task 10730 | prompt processing progress, n_tokens = 101242, batch.n_tokens = 2048, progress = 0.927532
2026-05-15 18:52:01.231 | slot update_slots: id  3 | task 10730 | n_tokens = 101242, memory_seq_rm [101242, end)
2026-05-15 18:52:01.231 | slot update_slots: id  3 | task 10730 | prompt processing progress, n_tokens = 103290, batch.n_tokens = 2048, progress = 0.946295
2026-05-15 18:52:03.051 | slot update_slots: id  3 | task 10730 | n_tokens = 103290, memory_seq_rm [103290, end)
2026-05-15 18:52:03.051 | slot update_slots: id  3 | task 10730 | prompt processing progress, n_tokens = 105338, batch.n_tokens = 2048, progress = 0.965058
2026-05-15 18:52:04.894 | slot update_slots: id  3 | task 10730 | n_tokens = 105338, memory_seq_rm [105338, end)
2026-05-15 18:52:04.894 | slot update_slots: id  3 | task 10730 | 8192 tokens since last checkpoint at 96905, creating new checkpoint during processing at position 107386
2026-05-15 18:52:04.894 | slot update_slots: id  3 | task 10730 | prompt processing progress, n_tokens = 107386, batch.n_tokens = 2048, progress = 0.983821
2026-05-15 18:52:05.301 | slot create_check: id  3 | task 10730 | created context checkpoint 24 of 32 (pos_min = 105337, pos_max = 105337, n_tokens = 105338, size = 370.232 MiB)
2026-05-15 18:52:07.167 | slot update_slots: id  3 | task 10730 | n_tokens = 107386, memory_seq_rm [107386, end)
2026-05-15 18:52:07.167 | slot update_slots: id  3 | task 10730 | prompt processing progress, n_tokens = 108636, batch.n_tokens = 1250, progress = 0.995273
2026-05-15 18:52:08.363 | slot update_slots: id  3 | task 10730 | n_tokens = 108636, memory_seq_rm [108636, end)
2026-05-15 18:52:08.363 | slot update_slots: id  3 | task 10730 | prompt processing progress, n_tokens = 109148, batch.n_tokens = 512, progress = 0.999963
2026-05-15 18:52:08.775 | slot create_check: id  3 | task 10730 | created context checkpoint 25 of 32 (pos_min = 108635, pos_max = 108635, n_tokens = 108636, size = 377.139 MiB)
2026-05-15 18:52:09.260 | slot update_slots: id  3 | task 10730 | n_tokens = 109148, memory_seq_rm [109148, end)
2026-05-15 18:52:09.274 | slot init_sampler: id  3 | task 10730 | init sampler, took 13.80 ms, tokens: text = 109152, total = 109152
2026-05-15 18:52:09.274 | slot update_slots: id  3 | task 10730 | prompt processing done, n_tokens = 109152, batch.n_tokens = 4
2026-05-15 18:52:09.691 | slot create_check: id  3 | task 10730 | created context checkpoint 26 of 32 (pos_min = 109147, pos_max = 109147, n_tokens = 109148, size = 378.211 MiB)
2026-05-15 18:52:09.735 | srv  log_server_r: done request: POST /v1/chat/completions 172.18.0.1 200
2026-05-15 18:52:12.441 | reasoning-budget: deactivated (natural end)
2026-05-15 18:52:13.682 | slot print_timing: id  3 | task 10730 | 
2026-05-15 18:52:13.682 | prompt eval time =   12053.03 ms / 12006 tokens (    1.00 ms per token,   996.10 tokens per second)
2026-05-15 18:52:13.685 |        eval time =    3947.25 ms /   261 tokens (   15.12 ms per token,    66.12 tokens per second)
2026-05-15 18:52:13.685 |       total time =   16000.28 ms / 12267 tokens
2026-05-15 18:52:13.685 | draft acceptance rate = 0.99401 (  166 accepted /   167 generated)
2026-05-15 18:52:13.685 | statistics mtp: #calls(b,g,a) = 99 9693 8038, #gen drafts = 8038, #acc drafts = 8038, #gen tokens = 14294, #acc tokens = 14078, dur(b,g,a) = 0.134, 40490.996, 3.322 ms
2026-05-15 18:52:13.685 | slot      release: id  3 | task 10730 | stop processing: n_tokens = 109412, truncated = 0
2026-05-15 18:52:13.685 | srv  update_slots: all slots are idle
2026-05-15 18:52:13.919 | srv  params_from_: Chat format: peg-native
2026-05-15 18:52:13.921 | slot get_availabl: id  2 | task -1 | selected slot by LRU, t_last = 4954002612
2026-05-15 18:52:13.921 | srv  get_availabl: updating prompt cache
2026-05-15 18:52:13.921 | srv          load:  - looking for better prompt, base f_keep = -1.000, sim = 0.000
2026-05-15 18:52:13.921 | srv        update:  - cache state: 1 prompts, 12015.952 MiB (limits: 8192.000 MiB, 131072 tokens, 131072 est)
2026-05-15 18:52:13.921 | srv        update:    - prompt 0x6487e7d7e430:  107111 tokens, checkpoints: 32, 12015.952 MiB
2026-05-15 18:52:13.921 | srv  get_availabl: prompt cache update took 0.02 ms
2026-05-15 18:52:13.921 | slot launch_slot_: id  2 | task -1 | sampler chain: logits -> penalties -> ?dry -> ?top-n-sigma -> top-k -> ?typical -> ?top-p -> min-p -> ?xtc -> ?temp-ext -> dist 
2026-05-15 18:52:13.921 | slot launch_slot_: id  2 | task 10835 | processing task, is_child = 0
2026-05-15 18:52:13.921 | slot slot_save_an: id  3 | task -1 | saving idle slot to prompt cache
2026-05-15 18:52:13.926 | srv   prompt_save:  - saving prompt with length 109412, total state size = 4013.672 MiB (draft: 229.138 MiB)
2026-05-15 18:52:26.339 | slot prompt_clear: id  3 | task -1 | clearing prompt with 109412 tokens
2026-05-15 18:52:26.357 | srv        update:  - cache size limit reached, removing oldest entry (size = 12015.952 MiB)
2026-05-15 18:52:27.039 | srv        update:  - cache state: 1 prompts, 11790.270 MiB (limits: 8192.000 MiB, 131072 tokens, 131072 est)
2026-05-15 18:52:27.039 | srv        update:    - prompt 0x6487e67598f0:  109412 tokens, checkpoints: 26, 11790.270 MiB
2026-05-15 18:52:27.039 | slot update_slots: id  2 | task 10835 | new prompt, n_ctx_slot = 131072, n_keep = 0, task.n_tokens = 23395
2026-05-15 18:52:27.039 | slot update_slots: id  2 | task 10835 | erased invalidated context checkpoint (pos_min = 8191, pos_max = 8191, n_tokens = 8192, n_swa = 0, pos_next = 0, size = 166.782 MiB)
2026-05-15 18:52:27.050 | slot update_slots: id  2 | task 10835 | erased invalidated context checkpoint (pos_min = 16383, pos_max = 16383, n_tokens = 16384, n_swa = 0, pos_next = 0, size = 183.939 MiB)
2026-05-15 18:52:27.061 | slot update_slots: id  2 | task 10835 | erased invalidated context checkpoint (pos_min = 24575, pos_max = 24575, n_tokens = 24576, n_swa = 0, pos_next = 0, size = 201.095 MiB)
2026-05-15 18:52:27.073 | slot update_slots: id  2 | task 10835 | erased invalidated context checkpoint (pos_min = 32767, pos_max = 32767, n_tokens = 32768, n_swa = 0, pos_next = 0, size = 218.251 MiB)
2026-05-15 18:52:27.086 | slot update_slots: id  2 | task 10835 | erased invalidated context checkpoint (pos_min = 40959, pos_max = 40959, n_tokens = 40960, n_swa = 0, pos_next = 0, size = 235.407 MiB)
2026-05-15 18:52:27.100 | slot update_slots: id  2 | task 10835 | erased invalidated context checkpoint (pos_min = 49151, pos_max = 49151, n_tokens = 49152, n_swa = 0, pos_next = 0, size = 252.564 MiB)
2026-05-15 18:52:27.115 | slot update_slots: id  2 | task 10835 | erased invalidated context checkpoint (pos_min = 57343, pos_max = 57343, n_tokens = 57344, n_swa = 0, pos_next = 0, size = 269.720 MiB)
2026-05-15 18:52:27.131 | slot update_slots: id  2 | task 10835 | erased invalidated context checkpoint (pos_min = 65535, pos_max = 65535, n_tokens = 65536, n_swa = 0, pos_next = 0, size = 286.876 MiB)
2026-05-15 18:52:27.148 | slot update_slots: id  2 | task 10835 | erased invalidated context checkpoint (pos_min = 73727, pos_max = 73727, n_tokens = 73728, n_swa = 0, pos_next = 0, size = 304.032 MiB)
2026-05-15 18:52:27.166 | slot update_slots: id  2 | task 10835 | erased invalidated context checkpoint (pos_min = 81919, pos_max = 81919, n_tokens = 81920, n_swa = 0, pos_next = 0, size = 321.189 MiB)
2026-05-15 18:52:27.185 | slot update_slots: id  2 | task 10835 | erased invalidated context checkpoint (pos_min = 90111, pos_max = 90111, n_tokens = 90112, n_swa = 0, pos_next = 0, size = 338.345 MiB)
2026-05-15 18:52:27.204 | slot update_slots: id  2 | task 10835 | erased invalidated context checkpoint (pos_min = 94172, pos_max = 94172, n_tokens = 94173, n_swa = 0, pos_next = 0, size = 346.850 MiB)
2026-05-15 18:52:27.225 | slot update_slots: id  2 | task 10835 | erased invalidated context checkpoint (pos_min = 94684, pos_max = 94684, n_tokens = 94685, n_swa = 0, pos_next = 0, size = 347.922 MiB)
2026-05-15 18:52:27.245 | slot update_slots: id  2 | task 10835 | erased invalidated context checkpoint (pos_min = 97875, pos_max = 97875, n_tokens = 97876, n_swa = 0, pos_next = 0, size = 354.605 MiB)
2026-05-15 18:52:27.266 | slot update_slots: id  2 | task 10835 | erased invalidated context checkpoint (pos_min = 98387, pos_max = 98387, n_tokens = 98388, n_swa = 0, pos_next = 0, size = 355.677 MiB)
2026-05-15 18:52:27.287 | slot update_slots: id  2 | task 10835 | erased invalidated context checkpoint (pos_min = 106767, pos_max = 106767, n_tokens = 106768, n_swa = 0, pos_next = 0, size = 373.227 MiB)
2026-05-15 18:52:27.309 | slot update_slots: id  2 | task 10835 | erased invalidated context checkpoint (pos_min = 110210, pos_max = 110210, n_tokens = 110211, n_swa = 0, pos_next = 0, size = 380.438 MiB)
2026-05-15 18:52:27.331 | slot update_slots: id  2 | task 10835 | erased invalidated context checkpoint (pos_min = 110722, pos_max = 110722, n_tokens = 110723, n_swa = 0, pos_next = 0, size = 381.510 MiB)
2026-05-15 18:52:27.354 | slot update_slots: id  2 | task 10835 | n_tokens = 0, memory_seq_rm [0, end)
2026-05-15 18:52:27.354 | slot update_slots: id  2 | task 10835 | prompt processing progress, n_tokens = 2048, batch.n_tokens = 2048, progress = 0.087540
2026-05-15 18:52:28.054 | slot update_slots: id  2 | task 10835 | n_tokens = 2048, memory_seq_rm [2048, end)
2026-05-15 18:52:28.054 | slot update_slots: id  2 | task 10835 | prompt processing progress, n_tokens = 4096, batch.n_tokens = 2048, progress = 0.175080
2026-05-15 18:52:28.763 | slot update_slots: id  2 | task 10835 | n_tokens = 4096, memory_seq_rm [4096, end)
2026-05-15 18:52:28.763 | slot update_slots: id  2 | task 10835 | prompt processing progress, n_tokens = 6144, batch.n_tokens = 2048, progress = 0.262620
2026-05-15 18:52:29.483 | slot update_slots: id  2 | task 10835 | n_tokens = 6144, memory_seq_rm [6144, end)
2026-05-15 18:52:29.483 | slot update_slots: id  2 | task 10835 | prompt processing progress, n_tokens = 8192, batch.n_tokens = 2048, progress = 0.350160
2026-05-15 18:52:30.218 | slot update_slots: id  2 | task 10835 | n_tokens = 8192, memory_seq_rm [8192, end)
2026-05-15 18:52:30.218 | slot update_slots: id  2 | task 10835 | 8192 tokens since last checkpoint at 0, creating new checkpoint during processing at position 10240
2026-05-15 18:52:30.218 | slot update_slots: id  2 | task 10835 | prompt processing progress, n_tokens = 10240, batch.n_tokens = 2048, progress = 0.437700
2026-05-15 18:52:30.338 | slot create_check: id  2 | task 10835 | created context checkpoint 1 of 32 (pos_min = 8191, pos_max = 8191, n_tokens = 8192, size = 166.782 MiB)
2026-05-15 18:52:31.079 | slot update_slots: id  2 | task 10835 | n_tokens = 10240, memory_seq_rm [10240, end)
2026-05-15 18:52:31.079 | slot update_slots: id  2 | task 10835 | prompt processing progress, n_tokens = 12288, batch.n_tokens = 2048, progress = 0.525240
2026-05-15 18:52:31.836 | slot update_slots: id  2 | task 10835 | n_tokens = 12288, memory_seq_rm [12288, end)
2026-05-15 18:52:31.836 | slot update_slots: id  2 | task 10835 | prompt processing progress, n_tokens = 14336, batch.n_tokens = 2048, progress = 0.612781
2026-05-15 18:52:32.606 | slot update_slots: id  2 | task 10835 | n_tokens = 14336, memory_seq_rm [14336, end)
2026-05-15 18:52:32.607 | slot update_slots: id  2 | task 10835 | prompt processing progress, n_tokens = 16384, batch.n_tokens = 2048, progress = 0.700321
2026-05-15 18:52:33.391 | slot update_slots: id  2 | task 10835 | n_tokens = 16384, memory_seq_rm [16384, end)
2026-05-15 18:52:33.391 | slot update_slots: id  2 | task 10835 | 8192 tokens since last checkpoint at 8192, creating new checkpoint during processing at position 18432
2026-05-15 18:52:33.391 | slot update_slots: id  2 | task 10835 | prompt processing progress, n_tokens = 18432, batch.n_tokens = 2048, progress = 0.787861
2026-05-15 18:52:33.517 | slot create_check: id  2 | task 10835 | created context checkpoint 2 of 32 (pos_min = 16383, pos_max = 16383, n_tokens = 16384, size = 183.939 MiB)
2026-05-15 18:52:34.310 | slot update_slots: id  2 | task 10835 | n_tokens = 18432, memory_seq_rm [18432, end)
2026-05-15 18:52:34.311 | slot update_slots: id  2 | task 10835 | prompt processing progress, n_tokens = 20480, batch.n_tokens = 2048, progress = 0.875401
2026-05-15 18:52:35.120 | slot update_slots: id  2 | task 10835 | n_tokens = 20480, memory_seq_rm [20480, end)
2026-05-15 18:52:35.120 | slot update_slots: id  2 | task 10835 | prompt processing progress, n_tokens = 22528, batch.n_tokens = 2048, progress = 0.962941
2026-05-15 18:52:35.944 | slot update_slots: id  2 | task 10835 | n_tokens = 22528, memory_seq_rm [22528, end)
2026-05-15 18:52:35.944 | slot update_slots: id  2 | task 10835 | prompt processing progress, n_tokens = 22879, batch.n_tokens = 351, progress = 0.977944
2026-05-15 18:52:36.104 | slot update_slots: id  2 | task 10835 | n_tokens = 22879, memory_seq_rm [22879, end)
2026-05-15 18:52:36.104 | slot update_slots: id  2 | task 10835 | prompt processing progress, n_tokens = 23391, batch.n_tokens = 512, progress = 0.999829
2026-05-15 18:52:36.269 | slot create_check: id  2 | task 10835 | created context checkpoint 3 of 32 (pos_min = 22878, pos_max = 22878, n_tokens = 22879, size = 197.541 MiB)
2026-05-15 18:52:36.478 | slot update_slots: id  2 | task 10835 | n_tokens = 23391, memory_seq_rm [23391, end)
2026-05-15 18:52:36.482 | slot init_sampler: id  2 | task 10835 | init sampler, took 3.23 ms, tokens: text = 23395, total = 23395
2026-05-15 18:52:36.482 | slot update_slots: id  2 | task 10835 | prompt processing done, n_tokens = 23395, batch.n_tokens = 4
2026-05-15 18:52:36.640 | slot create_check: id  2 | task 10835 | created context checkpoint 4 of 32 (pos_min = 23390, pos_max = 23390, n_tokens = 23391, size = 198.613 MiB)
2026-05-15 18:52:36.676 | srv  log_server_r: done request: POST /v1/chat/completions 172.18.0.1 200
2026-05-15 18:52:59.927 | slot print_timing: id  2 | task 10835 | 
2026-05-15 18:52:59.928 | prompt eval time =    9636.68 ms / 23395 tokens (    0.41 ms per token,  2427.70 tokens per second)
2026-05-15 18:52:59.928 |        eval time =   23238.49 ms /  1427 tokens (   16.28 ms per token,    61.41 tokens per second)
2026-05-15 18:52:59.928 |       total time =   32875.17 ms / 24822 tokens
2026-05-15 18:52:59.928 | draft acceptance rate = 0.98157 (  799 accepted /   814 generated)
2026-05-15 18:52:59.928 | statistics mtp: #calls(b,g,a) = 100 10320 8496, #gen drafts = 8496, #acc drafts = 8496, #gen tokens = 15108, #acc tokens = 14877, dur(b,g,a) = 0.135, 42928.200, 3.546 ms
2026-05-15 18:52:59.928 | slot      release: id  2 | task 10835 | stop processing: n_tokens = 24821, truncated = 0
2026-05-15 18:52:59.928 | srv  update_slots: all slots are idle
2026-05-15 18:53:00.085 | srv  params_from_: Chat format: peg-native
2026-05-15 18:53:00.088 | slot get_availabl: id  1 | task -1 | selected slot by LRU, t_last = 4994147256
2026-05-15 18:53:00.088 | srv  get_availabl: updating prompt cache
2026-05-15 18:53:00.088 | srv          load:  - looking for better prompt, base f_keep = -1.000, sim = 0.000
2026-05-15 18:53:00.088 | srv        update:  - cache state: 1 prompts, 11790.270 MiB (limits: 8192.000 MiB, 131072 tokens, 131072 est)
2026-05-15 18:53:00.088 | srv        update:    - prompt 0x6487e67598f0:  109412 tokens, checkpoints: 26, 11790.270 MiB
2026-05-15 18:53:00.088 | srv  get_availabl: prompt cache update took 0.02 ms
2026-05-15 18:53:00.089 | reasoning-budget: activated, budget=2147483647 tokens
2026-05-15 18:53:00.089 | slot launch_slot_: id  1 | task -1 | sampler chain: logits -> penalties -> ?dry -> ?top-n-sigma -> top-k -> ?typical -> ?top-p -> min-p -> ?xtc -> ?temp-ext -> dist 
2026-05-15 18:53:00.089 | slot launch_slot_: id  1 | task 11528 | processing task, is_child = 0
2026-05-15 18:53:00.089 | slot slot_save_an: id  2 | task -1 | saving idle slot to prompt cache
2026-05-15 18:53:00.090 | srv   prompt_save:  - saving prompt with length 24821, total state size = 1026.217 MiB (draft: 51.982 MiB)
2026-05-15 18:53:02.058 | slot prompt_clear: id  2 | task -1 | clearing prompt with 24821 tokens
2026-05-15 18:53:02.062 | srv        update:  - cache size limit reached, removing oldest entry (size = 11790.270 MiB)
2026-05-15 18:53:02.725 | srv        update:  - cache state: 1 prompts, 1773.092 MiB (limits: 8192.000 MiB, 131072 tokens, 131072 est)
2026-05-15 18:53:02.725 | srv        update:    - prompt 0x6487e5e65ea0:   24821 tokens, checkpoints:  4,  1773.092 MiB
2026-05-15 18:53:02.725 | slot update_slots: id  1 | task 11528 | new prompt, n_ctx_slot = 131072, n_keep = 0, task.n_tokens = 20914
2026-05-15 18:53:02.725 | slot update_slots: id  1 | task 11528 | erased invalidated context checkpoint (pos_min = 8191, pos_max = 8191, n_tokens = 8192, n_swa = 0, pos_next = 0, size = 166.782 MiB)
2026-05-15 18:53:02.734 | slot update_slots: id  1 | task 11528 | erased invalidated context checkpoint (pos_min = 13090, pos_max = 13090, n_tokens = 13091, n_swa = 0, pos_next = 0, size = 177.042 MiB)
2026-05-15 18:53:02.743 | slot update_slots: id  1 | task 11528 | erased invalidated context checkpoint (pos_min = 13602, pos_max = 13602, n_tokens = 13603, n_swa = 0, pos_next = 0, size = 178.115 MiB)
2026-05-15 18:53:02.752 | slot update_slots: id  1 | task 11528 | n_tokens = 0, memory_seq_rm [0, end)
2026-05-15 18:53:02.752 | slot update_slots: id  1 | task 11528 | prompt processing progress, n_tokens = 2048, batch.n_tokens = 2048, progress = 0.097925
2026-05-15 18:53:03.460 | slot update_slots: id  1 | task 11528 | n_tokens = 2048, memory_seq_rm [2048, end)
2026-05-15 18:53:03.460 | slot update_slots: id  1 | task 11528 | prompt processing progress, n_tokens = 4096, batch.n_tokens = 2048, progress = 0.195850
2026-05-15 18:53:04.168 | slot update_slots: id  1 | task 11528 | n_tokens = 4096, memory_seq_rm [4096, end)
2026-05-15 18:53:04.168 | slot update_slots: id  1 | task 11528 | prompt processing progress, n_tokens = 6144, batch.n_tokens = 2048, progress = 0.293775
2026-05-15 18:53:04.890 | slot update_slots: id  1 | task 11528 | n_tokens = 6144, memory_seq_rm [6144, end)
2026-05-15 18:53:04.890 | slot update_slots: id  1 | task 11528 | prompt processing progress, n_tokens = 8192, batch.n_tokens = 2048, progress = 0.391699
2026-05-15 18:53:05.621 | slot update_slots: id  1 | task 11528 | n_tokens = 8192, memory_seq_rm [8192, end)
2026-05-15 18:53:05.622 | slot update_slots: id  1 | task 11528 | 8192 tokens since last checkpoint at 0, creating new checkpoint during processing at position 10240
2026-05-15 18:53:05.622 | slot update_slots: id  1 | task 11528 | prompt processing progress, n_tokens = 10240, batch.n_tokens = 2048, progress = 0.489624
2026-05-15 18:53:05.737 | slot create_check: id  1 | task 11528 | created context checkpoint 1 of 32 (pos_min = 8191, pos_max = 8191, n_tokens = 8192, size = 166.782 MiB)
2026-05-15 18:53:06.479 | slot update_slots: id  1 | task 11528 | n_tokens = 10240, memory_seq_rm [10240, end)
2026-05-15 18:53:06.479 | slot update_slots: id  1 | task 11528 | prompt processing progress, n_tokens = 12288, batch.n_tokens = 2048, progress = 0.587549
2026-05-15 18:53:07.234 | slot update_slots: id  1 | task 11528 | n_tokens = 12288, memory_seq_rm [12288, end)
2026-05-15 18:53:07.234 | slot update_slots: id  1 | task 11528 | prompt processing progress, n_tokens = 14336, batch.n_tokens = 2048, progress = 0.685474
2026-05-15 18:53:08.003 | slot update_slots: id  1 | task 11528 | n_tokens = 14336, memory_seq_rm [14336, end)
2026-05-15 18:53:08.003 | slot update_slots: id  1 | task 11528 | prompt processing progress, n_tokens = 16384, batch.n_tokens = 2048, progress = 0.783399
2026-05-15 18:53:08.785 | slot update_slots: id  1 | task 11528 | n_tokens = 16384, memory_seq_rm [16384, end)
2026-05-15 18:53:08.785 | slot update_slots: id  1 | task 11528 | 8192 tokens since last checkpoint at 8192, creating new checkpoint during processing at position 18432
2026-05-15 18:53:08.785 | slot update_slots: id  1 | task 11528 | prompt processing progress, n_tokens = 18432, batch.n_tokens = 2048, progress = 0.881324
2026-05-15 18:53:08.938 | slot create_check: id  1 | task 11528 | created context checkpoint 2 of 32 (pos_min = 16383, pos_max = 16383, n_tokens = 16384, size = 183.939 MiB)
2026-05-15 18:53:09.732 | slot update_slots: id  1 | task 11528 | n_tokens = 18432, memory_seq_rm [18432, end)
2026-05-15 18:53:09.732 | slot update_slots: id  1 | task 11528 | prompt processing progress, n_tokens = 20398, batch.n_tokens = 1966, progress = 0.975328
2026-05-15 18:53:10.522 | slot update_slots: id  1 | task 11528 | n_tokens = 20398, memory_seq_rm [20398, end)
2026-05-15 18:53:10.522 | slot update_slots: id  1 | task 11528 | prompt processing progress, n_tokens = 20910, batch.n_tokens = 512, progress = 0.999809
2026-05-15 18:53:10.712 | slot create_check: id  1 | task 11528 | created context checkpoint 3 of 32 (pos_min = 20397, pos_max = 20397, n_tokens = 20398, size = 192.345 MiB)
2026-05-15 18:53:10.917 | slot update_slots: id  1 | task 11528 | n_tokens = 20910, memory_seq_rm [20910, end)
2026-05-15 18:53:10.920 | slot init_sampler: id  1 | task 11528 | init sampler, took 2.85 ms, tokens: text = 20914, total = 20914
2026-05-15 18:53:10.920 | slot update_slots: id  1 | task 11528 | prompt processing done, n_tokens = 20914, batch.n_tokens = 4
2026-05-15 18:53:11.153 | slot create_check: id  1 | task 11528 | created context checkpoint 4 of 32 (pos_min = 20909, pos_max = 20909, n_tokens = 20910, size = 193.417 MiB)
2026-05-15 18:53:11.187 | srv  log_server_r: done request: POST /v1/chat/completions 172.18.0.1 200
2026-05-15 18:53:13.093 | reasoning-budget: deactivated (natural end)
2026-05-15 18:53:13.881 | slot print_timing: id  1 | task 11528 | 
2026-05-15 18:53:13.881 | prompt eval time =    8461.80 ms / 20914 tokens (    0.40 ms per token,  2471.58 tokens per second)
2026-05-15 18:53:13.881 |        eval time =    2693.58 ms /   141 tokens (   19.10 ms per token,    52.35 tokens per second)
2026-05-15 18:53:13.881 |       total time =   11155.38 ms / 21055 tokens
2026-05-15 18:53:13.881 | draft acceptance rate = 0.96875 (   62 accepted /    64 generated)
2026-05-15 18:53:13.881 | statistics mtp: #calls(b,g,a) = 101 10398 8535, #gen drafts = 8535, #acc drafts = 8535, #gen tokens = 15172, #acc tokens = 14939, dur(b,g,a) = 0.136, 43176.363, 3.562 ms
2026-05-15 18:53:13.881 | slot      release: id  1 | task 11528 | stop processing: n_tokens = 21054, truncated = 0
2026-05-15 18:53:13.881 | srv  update_slots: all slots are idle
2026-05-15 18:53:14.065 | srv  params_from_: Chat format: peg-native
2026-05-15 18:53:14.068 | slot get_availabl: id  1 | task -1 | selected slot by LCP similarity, sim_best = 0.893 (> 0.100 thold), f_keep = 1.000
2026-05-15 18:53:14.069 | reasoning-budget: activated, budget=2147483647 tokens
2026-05-15 18:53:14.069 | slot launch_slot_: id  1 | task -1 | sampler chain: logits -> penalties -> ?dry -> ?top-n-sigma -> top-k -> ?typical -> ?top-p -> min-p -> ?xtc -> ?temp-ext -> dist 
2026-05-15 18:53:14.069 | slot launch_slot_: id  1 | task 11626 | processing task, is_child = 0
2026-05-15 18:53:14.069 | slot update_slots: id  1 | task 11626 | new prompt, n_ctx_slot = 131072, n_keep = 0, task.n_tokens = 23571
2026-05-15 18:53:14.070 | slot update_slots: id  1 | task 11626 | n_tokens = 21054, memory_seq_rm [21054, end)
2026-05-15 18:53:14.070 | slot update_slots: id  1 | task 11626 | prompt processing progress, n_tokens = 23055, batch.n_tokens = 2001, progress = 0.978109
2026-05-15 18:53:14.883 | slot update_slots: id  1 | task 11626 | n_tokens = 23055, memory_seq_rm [23055, end)
2026-05-15 18:53:14.883 | slot update_slots: id  1 | task 11626 | prompt processing progress, n_tokens = 23567, batch.n_tokens = 512, progress = 0.999830
2026-05-15 18:53:15.118 | slot create_check: id  1 | task 11626 | created context checkpoint 5 of 32 (pos_min = 23054, pos_max = 23054, n_tokens = 23055, size = 197.910 MiB)
2026-05-15 18:53:15.328 | slot update_slots: id  1 | task 11626 | n_tokens = 23567, memory_seq_rm [23567, end)
2026-05-15 18:53:15.331 | slot init_sampler: id  1 | task 11626 | init sampler, took 3.15 ms, tokens: text = 23571, total = 23571
2026-05-15 18:53:15.331 | slot update_slots: id  1 | task 11626 | prompt processing done, n_tokens = 23571, batch.n_tokens = 4
2026-05-15 18:53:15.583 | slot create_check: id  1 | task 11626 | created context checkpoint 6 of 32 (pos_min = 23566, pos_max = 23566, n_tokens = 23567, size = 198.982 MiB)
2026-05-15 18:53:15.616 | srv  log_server_r: done request: POST /v1/chat/completions 172.18.0.1 200
2026-05-15 18:53:16.976 | reasoning-budget: deactivated (natural end)
2026-05-15 18:53:24.004 | slot print_timing: id  1 | task 11626 | 
2026-05-15 18:53:24.004 | prompt eval time =    1526.32 ms /  2517 tokens (    0.61 ms per token,  1649.07 tokens per second)
2026-05-15 18:53:24.004 |        eval time =    8387.88 ms /   454 tokens (   18.48 ms per token,    54.13 tokens per second)
2026-05-15 18:53:24.004 |       total time =    9914.20 ms /  2971 tokens
2026-05-15 18:53:24.004 | draft acceptance rate = 0.97826 (  225 accepted /   230 generated)
2026-05-15 18:53:24.004 | statistics mtp: #calls(b,g,a) = 102 10626 8680, #gen drafts = 8680, #acc drafts = 8680, #gen tokens = 15402, #acc tokens = 15164, dur(b,g,a) = 0.137, 43967.810, 3.626 ms
2026-05-15 18:53:24.004 | slot      release: id  1 | task 11626 | stop processing: n_tokens = 24024, truncated = 0
2026-05-15 18:53:24.004 | srv  update_slots: all slots are idle
2026-05-15 18:55:31.979 | srv  params_from_: Chat format: peg-native
2026-05-15 18:55:31.982 | slot get_availabl: id  1 | task -1 | selected slot by LCP similarity, sim_best = 0.868 (> 0.100 thold), f_keep = 0.857
2026-05-15 18:55:31.983 | reasoning-budget: activated, budget=2147483647 tokens
2026-05-15 18:55:31.983 | slot launch_slot_: id  1 | task -1 | sampler chain: logits -> penalties -> ?dry -> ?top-n-sigma -> top-k -> ?typical -> ?top-p -> min-p -> ?xtc -> ?temp-ext -> dist 
2026-05-15 18:55:31.983 | slot launch_slot_: id  1 | task 11876 | processing task, is_child = 0
2026-05-15 18:55:31.983 | slot update_slots: id  1 | task 11876 | new prompt, n_ctx_slot = 131072, n_keep = 0, task.n_tokens = 23723
2026-05-15 18:55:31.983 | slot update_slots: id  1 | task 11876 | n_past = 20599, slot.prompt.tokens.size() = 24024, seq_id = 1, pos_min = 24023, n_swa = 0
2026-05-15 18:55:31.983 | slot update_slots: id  1 | task 11876 | Checking checkpoint with [23566, 23566] against 20599...
2026-05-15 18:55:31.983 | slot update_slots: id  1 | task 11876 | Checking checkpoint with [23054, 23054] against 20599...
2026-05-15 18:55:31.983 | slot update_slots: id  1 | task 11876 | Checking checkpoint with [20909, 20909] against 20599...
2026-05-15 18:55:31.983 | slot update_slots: id  1 | task 11876 | Checking checkpoint with [20397, 20397] against 20599...
2026-05-15 18:55:32.058 | slot update_slots: id  1 | task 11876 | restored context checkpoint (pos_min = 20397, pos_max = 20397, n_tokens = 20398, n_past = 20398, size = 192.345 MiB)
2026-05-15 18:55:32.058 | slot update_slots: id  1 | task 11876 | erased invalidated context checkpoint (pos_min = 20909, pos_max = 20909, n_tokens = 20910, n_swa = 0, pos_next = 20398, size = 193.417 MiB)
2026-05-15 18:55:32.069 | slot update_slots: id  1 | task 11876 | erased invalidated context checkpoint (pos_min = 23054, pos_max = 23054, n_tokens = 23055, n_swa = 0, pos_next = 20398, size = 197.910 MiB)
2026-05-15 18:55:32.080 | slot update_slots: id  1 | task 11876 | erased invalidated context checkpoint (pos_min = 23566, pos_max = 23566, n_tokens = 23567, n_swa = 0, pos_next = 20398, size = 198.982 MiB)
2026-05-15 18:55:32.091 | slot update_slots: id  1 | task 11876 | n_tokens = 20398, memory_seq_rm [20398, end)
2026-05-15 18:55:32.092 | slot update_slots: id  1 | task 11876 | prompt processing progress, n_tokens = 22446, batch.n_tokens = 2048, progress = 0.946170
2026-05-15 18:55:33.096 | slot update_slots: id  1 | task 11876 | n_tokens = 22446, memory_seq_rm [22446, end)
2026-05-15 18:55:33.096 | slot update_slots: id  1 | task 11876 | prompt processing progress, n_tokens = 23207, batch.n_tokens = 761, progress = 0.978249
2026-05-15 18:55:33.417 | slot update_slots: id  1 | task 11876 | n_tokens = 23207, memory_seq_rm [23207, end)
2026-05-15 18:55:33.417 | slot update_slots: id  1 | task 11876 | prompt processing progress, n_tokens = 23719, batch.n_tokens = 512, progress = 0.999831
2026-05-15 18:55:33.576 | slot create_check: id  1 | task 11876 | created context checkpoint 4 of 32 (pos_min = 23206, pos_max = 23206, n_tokens = 23207, size = 198.228 MiB)
2026-05-15 18:55:33.782 | slot update_slots: id  1 | task 11876 | n_tokens = 23719, memory_seq_rm [23719, end)
2026-05-15 18:55:33.785 | slot init_sampler: id  1 | task 11876 | init sampler, took 3.08 ms, tokens: text = 23723, total = 23723
2026-05-15 18:55:33.785 | slot update_slots: id  1 | task 11876 | prompt processing done, n_tokens = 23723, batch.n_tokens = 4
2026-05-15 18:55:33.925 | slot create_check: id  1 | task 11876 | created context checkpoint 5 of 32 (pos_min = 23718, pos_max = 23718, n_tokens = 23719, size = 199.300 MiB)
2026-05-15 18:55:33.960 | srv  log_server_r: done request: POST /v1/chat/completions 172.18.0.1 200
2026-05-15 18:55:36.181 | reasoning-budget: deactivated (natural end)
2026-05-15 18:55:38.101 | slot print_timing: id  1 | task 11876 | 
2026-05-15 18:55:38.101 | prompt eval time =    1976.20 ms /  3325 tokens (    0.59 ms per token,  1682.52 tokens per second)
2026-05-15 18:55:38.101 |        eval time =    4140.65 ms /   287 tokens (   14.43 ms per token,    69.31 tokens per second)
2026-05-15 18:55:38.101 |       total time =    6116.85 ms /  3612 tokens
2026-05-15 18:55:38.101 | draft acceptance rate = 0.99422 (  172 accepted /   173 generated)
2026-05-15 18:55:38.101 | statistics mtp: #calls(b,g,a) = 103 10740 8776, #gen drafts = 8776, #acc drafts = 8776, #gen tokens = 15575, #acc tokens = 15336, dur(b,g,a) = 0.139, 44398.367, 3.667 ms
2026-05-15 18:55:38.101 | slot      release: id  1 | task 11876 | stop processing: n_tokens = 24009, truncated = 0
2026-05-15 18:55:38.101 | srv  update_slots: all slots are idle
2026-05-15 18:55:38.293 | srv  params_from_: Chat format: peg-native
2026-05-15 18:55:38.295 | slot get_availabl: id  1 | task -1 | selected slot by LCP similarity, sim_best = 0.465 (> 0.100 thold), f_keep = 1.000
2026-05-15 18:55:38.297 | reasoning-budget: activated, budget=2147483647 tokens
2026-05-15 18:55:38.297 | slot launch_slot_: id  1 | task -1 | sampler chain: logits -> penalties -> ?dry -> ?top-n-sigma -> top-k -> ?typical -> ?top-p -> min-p -> ?xtc -> ?temp-ext -> dist 
2026-05-15 18:55:38.297 | slot launch_slot_: id  1 | task 12011 | processing task, is_child = 0
2026-05-15 18:55:38.297 | slot update_slots: id  1 | task 12011 | new prompt, n_ctx_slot = 131072, n_keep = 0, task.n_tokens = 51591
2026-05-15 18:55:38.297 | slot update_slots: id  1 | task 12011 | n_tokens = 24009, memory_seq_rm [24009, end)
2026-05-15 18:55:38.297 | slot update_slots: id  1 | task 12011 | prompt processing progress, n_tokens = 26057, batch.n_tokens = 2048, progress = 0.505069
2026-05-15 18:55:39.128 | slot update_slots: id  1 | task 12011 | n_tokens = 26057, memory_seq_rm [26057, end)
2026-05-15 18:55:39.128 | slot update_slots: id  1 | task 12011 | prompt processing progress, n_tokens = 28105, batch.n_tokens = 2048, progress = 0.544766
2026-05-15 18:55:39.978 | slot update_slots: id  1 | task 12011 | n_tokens = 28105, memory_seq_rm [28105, end)
2026-05-15 18:55:39.978 | slot update_slots: id  1 | task 12011 | prompt processing progress, n_tokens = 30153, batch.n_tokens = 2048, progress = 0.584462
2026-05-15 18:55:40.849 | slot update_slots: id  1 | task 12011 | n_tokens = 30153, memory_seq_rm [30153, end)
2026-05-15 18:55:40.849 | slot update_slots: id  1 | task 12011 | prompt processing progress, n_tokens = 32201, batch.n_tokens = 2048, progress = 0.624159
2026-05-15 18:55:41.740 | slot update_slots: id  1 | task 12011 | n_tokens = 32201, memory_seq_rm [32201, end)
2026-05-15 18:55:41.740 | slot update_slots: id  1 | task 12011 | 8192 tokens since last checkpoint at 23719, creating new checkpoint during processing at position 34249
2026-05-15 18:55:41.740 | slot update_slots: id  1 | task 12011 | prompt processing progress, n_tokens = 34249, batch.n_tokens = 2048, progress = 0.663856
2026-05-15 18:55:41.978 | slot create_check: id  1 | task 12011 | created context checkpoint 6 of 32 (pos_min = 32200, pos_max = 32200, n_tokens = 32201, size = 217.064 MiB)
2026-05-15 18:55:42.886 | slot update_slots: id  1 | task 12011 | n_tokens = 34249, memory_seq_rm [34249, end)
2026-05-15 18:55:42.886 | slot update_slots: id  1 | task 12011 | prompt processing progress, n_tokens = 36297, batch.n_tokens = 2048, progress = 0.703553
2026-05-15 18:55:43.817 | slot update_slots: id  1 | task 12011 | n_tokens = 36297, memory_seq_rm [36297, end)
2026-05-15 18:55:43.817 | slot update_slots: id  1 | task 12011 | prompt processing progress, n_tokens = 38345, batch.n_tokens = 2048, progress = 0.743250
2026-05-15 18:55:44.774 | slot update_slots: id  1 | task 12011 | n_tokens = 38345, memory_seq_rm [38345, end)
2026-05-15 18:55:44.774 | slot update_slots: id  1 | task 12011 | prompt processing progress, n_tokens = 40393, batch.n_tokens = 2048, progress = 0.782947
2026-05-15 18:55:45.774 | slot update_slots: id  1 | task 12011 | n_tokens = 40393, memory_seq_rm [40393, end)
2026-05-15 18:55:45.774 | slot update_slots: id  1 | task 12011 | 8192 tokens since last checkpoint at 32201, creating new checkpoint during processing at position 42441
2026-05-15 18:55:45.774 | slot update_slots: id  1 | task 12011 | prompt processing progress, n_tokens = 42441, batch.n_tokens = 2048, progress = 0.822643
2026-05-15 18:55:46.035 | slot create_check: id  1 | task 12011 | created context checkpoint 7 of 32 (pos_min = 40392, pos_max = 40392, n_tokens = 40393, size = 234.220 MiB)
2026-05-15 18:55:47.045 | slot update_slots: id  1 | task 12011 | n_tokens = 42441, memory_seq_rm [42441, end)
2026-05-15 18:55:47.045 | slot update_slots: id  1 | task 12011 | prompt processing progress, n_tokens = 44489, batch.n_tokens = 2048, progress = 0.862340
2026-05-15 18:55:48.079 | slot update_slots: id  1 | task 12011 | n_tokens = 44489, memory_seq_rm [44489, end)
2026-05-15 18:55:48.079 | slot update_slots: id  1 | task 12011 | prompt processing progress, n_tokens = 46537, batch.n_tokens = 2048, progress = 0.902037
2026-05-15 18:55:49.145 | slot update_slots: id  1 | task 12011 | n_tokens = 46537, memory_seq_rm [46537, end)
2026-05-15 18:55:49.145 | slot update_slots: id  1 | task 12011 | prompt processing progress, n_tokens = 48585, batch.n_tokens = 2048, progress = 0.941734
2026-05-15 18:55:50.237 | slot update_slots: id  1 | task 12011 | n_tokens = 48585, memory_seq_rm [48585, end)
2026-05-15 18:55:50.237 | slot update_slots: id  1 | task 12011 | 8192 tokens since last checkpoint at 40393, creating new checkpoint during processing at position 50633
2026-05-15 18:55:50.237 | slot update_slots: id  1 | task 12011 | prompt processing progress, n_tokens = 50633, batch.n_tokens = 2048, progress = 0.981431
2026-05-15 18:55:50.515 | slot create_check: id  1 | task 12011 | created context checkpoint 8 of 32 (pos_min = 48584, pos_max = 48584, n_tokens = 48585, size = 251.376 MiB)
2026-05-15 18:55:51.633 | slot update_slots: id  1 | task 12011 | n_tokens = 50633, memory_seq_rm [50633, end)
2026-05-15 18:55:51.633 | slot update_slots: id  1 | task 12011 | prompt processing progress, n_tokens = 51075, batch.n_tokens = 442, progress = 0.989998
2026-05-15 18:55:51.892 | slot update_slots: id  1 | task 12011 | n_tokens = 51075, memory_seq_rm [51075, end)
2026-05-15 18:55:51.892 | slot update_slots: id  1 | task 12011 | prompt processing progress, n_tokens = 51587, batch.n_tokens = 512, progress = 0.999922
2026-05-15 18:55:52.174 | slot create_check: id  1 | task 12011 | created context checkpoint 9 of 32 (pos_min = 51074, pos_max = 51074, n_tokens = 51075, size = 256.591 MiB)
2026-05-15 18:55:52.464 | slot update_slots: id  1 | task 12011 | n_tokens = 51587, memory_seq_rm [51587, end)
2026-05-15 18:55:52.470 | slot init_sampler: id  1 | task 12011 | init sampler, took 6.49 ms, tokens: text = 51591, total = 51591
2026-05-15 18:55:52.470 | slot update_slots: id  1 | task 12011 | prompt processing done, n_tokens = 51591, batch.n_tokens = 4
2026-05-15 18:55:52.751 | slot create_check: id  1 | task 12011 | created context checkpoint 10 of 32 (pos_min = 51586, pos_max = 51586, n_tokens = 51587, size = 257.663 MiB)
2026-05-15 18:55:52.788 | srv  log_server_r: done request: POST /v1/chat/completions 172.18.0.1 200
2026-05-15 18:56:00.863 | reasoning-budget: deactivated (natural end)
2026-05-15 18:56:02.434 | slot print_timing: id  1 | task 12011 | 
2026-05-15 18:56:02.434 | prompt eval time =   14466.09 ms / 27582 tokens (    0.52 ms per token,  1906.67 tokens per second)
2026-05-15 18:56:02.434 |        eval time =    9646.04 ms /   540 tokens (   17.86 ms per token,    55.98 tokens per second)
2026-05-15 18:56:02.434 |       total time =   24112.12 ms / 28122 tokens
2026-05-15 18:56:02.434 | draft acceptance rate = 0.98980 (  291 accepted /   294 generated)
2026-05-15 18:56:02.434 | statistics mtp: #calls(b,g,a) = 104 10988 8949, #gen drafts = 8949, #acc drafts = 8949, #gen tokens = 15869, #acc tokens = 15627, dur(b,g,a) = 0.140, 45310.788, 3.741 ms
2026-05-15 18:56:02.435 | slot      release: id  1 | task 12011 | stop processing: n_tokens = 52130, truncated = 0
2026-05-15 18:56:02.435 | srv  update_slots: all slots are idle
2026-05-15 18:56:02.628 | srv  params_from_: Chat format: peg-native
2026-05-15 18:56:02.631 | slot get_availabl: id  1 | task -1 | selected slot by LCP similarity, sim_best = 0.989 (> 0.100 thold), f_keep = 1.000
2026-05-15 18:56:02.632 | reasoning-budget: activated, budget=2147483647 tokens
2026-05-15 18:56:02.632 | slot launch_slot_: id  1 | task -1 | sampler chain: logits -> penalties -> ?dry -> ?top-n-sigma -> top-k -> ?typical -> ?top-p -> min-p -> ?xtc -> ?temp-ext -> dist 
2026-05-15 18:56:02.632 | slot launch_slot_: id  1 | task 12300 | processing task, is_child = 0
2026-05-15 18:56:02.632 | slot update_slots: id  1 | task 12300 | new prompt, n_ctx_slot = 131072, n_keep = 0, task.n_tokens = 52713
2026-05-15 18:56:02.632 | slot update_slots: id  1 | task 12300 | n_tokens = 52130, memory_seq_rm [52130, end)
2026-05-15 18:56:02.632 | slot update_slots: id  1 | task 12300 | prompt processing progress, n_tokens = 52197, batch.n_tokens = 67, progress = 0.990211
2026-05-15 18:56:02.693 | slot update_slots: id  1 | task 12300 | n_tokens = 52197, memory_seq_rm [52197, end)
2026-05-15 18:56:02.693 | slot update_slots: id  1 | task 12300 | prompt processing progress, n_tokens = 52709, batch.n_tokens = 512, progress = 0.999924
2026-05-15 18:56:02.975 | slot create_check: id  1 | task 12300 | created context checkpoint 11 of 32 (pos_min = 52196, pos_max = 52196, n_tokens = 52197, size = 258.941 MiB)
2026-05-15 18:56:03.267 | slot update_slots: id  1 | task 12300 | n_tokens = 52709, memory_seq_rm [52709, end)
2026-05-15 18:56:03.274 | slot init_sampler: id  1 | task 12300 | init sampler, took 6.58 ms, tokens: text = 52713, total = 52713
2026-05-15 18:56:03.274 | slot update_slots: id  1 | task 12300 | prompt processing done, n_tokens = 52713, batch.n_tokens = 4
2026-05-15 18:56:03.561 | slot create_check: id  1 | task 12300 | created context checkpoint 12 of 32 (pos_min = 52708, pos_max = 52708, n_tokens = 52709, size = 260.013 MiB)
2026-05-15 18:56:03.598 | srv  log_server_r: done request: POST /v1/chat/completions 172.18.0.1 200
2026-05-15 18:56:06.942 | reasoning-budget: deactivated (natural end)
2026-05-15 18:56:08.093 | slot print_timing: id  1 | task 12300 | 
2026-05-15 18:56:08.093 | prompt eval time =     965.70 ms /   583 tokens (    1.66 ms per token,   603.71 tokens per second)
2026-05-15 18:56:08.093 |        eval time =    4495.51 ms /   274 tokens (   16.41 ms per token,    60.95 tokens per second)
2026-05-15 18:56:08.093 |       total time =    5461.20 ms /   857 tokens
2026-05-15 18:56:08.093 | draft acceptance rate = 0.98718 (  154 accepted /   156 generated)
2026-05-15 18:56:08.093 | statistics mtp: #calls(b,g,a) = 105 11107 9040, #gen drafts = 9040, #acc drafts = 9040, #gen tokens = 16025, #acc tokens = 15781, dur(b,g,a) = 0.141, 45770.089, 3.782 ms
2026-05-15 18:56:08.095 | slot      release: id  1 | task 12300 | stop processing: n_tokens = 52986, truncated = 0
2026-05-15 18:56:08.095 | srv  update_slots: all slots are idle
2026-05-15 18:56:08.297 | srv  params_from_: Chat format: peg-native
2026-05-15 18:56:08.299 | slot get_availabl: id  1 | task -1 | selected slot by LCP similarity, sim_best = 0.976 (> 0.100 thold), f_keep = 1.000
2026-05-15 18:56:08.300 | reasoning-budget: activated, budget=2147483647 tokens
2026-05-15 18:56:08.300 | slot launch_slot_: id  1 | task -1 | sampler chain: logits -> penalties -> ?dry -> ?top-n-sigma -> top-k -> ?typical -> ?top-p -> min-p -> ?xtc -> ?temp-ext -> dist 
2026-05-15 18:56:08.301 | slot launch_slot_: id  1 | task 12431 | processing task, is_child = 0
2026-05-15 18:56:08.301 | slot update_slots: id  1 | task 12431 | new prompt, n_ctx_slot = 131072, n_keep = 0, task.n_tokens = 54294
2026-05-15 18:56:08.301 | slot update_slots: id  1 | task 12431 | n_tokens = 52986, memory_seq_rm [52986, end)
2026-05-15 18:56:08.301 | slot update_slots: id  1 | task 12431 | prompt processing progress, n_tokens = 53778, batch.n_tokens = 792, progress = 0.990496
2026-05-15 18:56:08.754 | slot update_slots: id  1 | task 12431 | n_tokens = 53778, memory_seq_rm [53778, end)
2026-05-15 18:56:08.754 | slot update_slots: id  1 | task 12431 | prompt processing progress, n_tokens = 54290, batch.n_tokens = 512, progress = 0.999926
2026-05-15 18:56:09.039 | slot create_check: id  1 | task 12431 | created context checkpoint 13 of 32 (pos_min = 53777, pos_max = 53777, n_tokens = 53778, size = 262.252 MiB)
2026-05-15 18:56:09.337 | slot update_slots: id  1 | task 12431 | n_tokens = 54290, memory_seq_rm [54290, end)
2026-05-15 18:56:09.344 | slot init_sampler: id  1 | task 12431 | init sampler, took 7.04 ms, tokens: text = 54294, total = 54294
2026-05-15 18:56:09.344 | slot update_slots: id  1 | task 12431 | prompt processing done, n_tokens = 54294, batch.n_tokens = 4
2026-05-15 18:56:09.638 | slot create_check: id  1 | task 12431 | created context checkpoint 14 of 32 (pos_min = 54289, pos_max = 54289, n_tokens = 54290, size = 263.324 MiB)
2026-05-15 18:56:09.675 | srv  log_server_r: done request: POST /v1/chat/completions 172.18.0.1 200
2026-05-15 18:56:14.171 | reasoning-budget: deactivated (natural end)
2026-05-15 18:56:42.967 | slot print_timing: id  1 | task 12431 | 
2026-05-15 18:56:42.967 | prompt eval time =    1373.76 ms /  1308 tokens (    1.05 ms per token,   952.13 tokens per second)
2026-05-15 18:56:42.967 |        eval time =   33264.89 ms /  2151 tokens (   15.46 ms per token,    64.66 tokens per second)
2026-05-15 18:56:42.967 |       total time =   34638.64 ms /  3459 tokens
2026-05-15 18:56:42.967 | draft acceptance rate = 0.99287 ( 1254 accepted /  1263 generated)
2026-05-15 18:56:42.967 | statistics mtp: #calls(b,g,a) = 106 12003 9739, #gen drafts = 9739, #acc drafts = 9739, #gen tokens = 17288, #acc tokens = 17035, dur(b,g,a) = 0.142, 49250.294, 4.086 ms
2026-05-15 18:56:42.968 | slot      release: id  1 | task 12431 | stop processing: n_tokens = 56444, truncated = 0
2026-05-15 18:56:42.968 | srv  update_slots: all slots are idle
2026-05-15 18:56:43.202 | srv  params_from_: Chat format: peg-native
2026-05-15 18:56:43.205 | slot get_availabl: id  1 | task -1 | selected slot by LCP similarity, sim_best = 1.000 (> 0.100 thold), f_keep = 1.000
2026-05-15 18:56:43.206 | reasoning-budget: activated, budget=2147483647 tokens
2026-05-15 18:56:43.206 | slot launch_slot_: id  1 | task -1 | sampler chain: logits -> penalties -> ?dry -> ?top-n-sigma -> top-k -> ?typical -> ?top-p -> min-p -> ?xtc -> ?temp-ext -> dist 
2026-05-15 18:56:43.206 | slot launch_slot_: id  1 | task 13379 | processing task, is_child = 0
2026-05-15 18:56:43.206 | slot update_slots: id  1 | task 13379 | new prompt, n_ctx_slot = 131072, n_keep = 0, task.n_tokens = 56463
2026-05-15 18:56:43.206 | slot update_slots: id  1 | task 13379 | n_tokens = 56444, memory_seq_rm [56444, end)
2026-05-15 18:56:43.206 | slot update_slots: id  1 | task 13379 | prompt processing progress, n_tokens = 56459, batch.n_tokens = 15, progress = 0.999929
2026-05-15 18:56:43.486 | slot create_check: id  1 | task 13379 | created context checkpoint 15 of 32 (pos_min = 56443, pos_max = 56443, n_tokens = 56444, size = 267.835 MiB)
2026-05-15 18:56:43.526 | slot update_slots: id  1 | task 13379 | n_tokens = 56459, memory_seq_rm [56459, end)
2026-05-15 18:56:43.534 | slot init_sampler: id  1 | task 13379 | init sampler, took 7.29 ms, tokens: text = 56463, total = 56463
2026-05-15 18:56:43.534 | slot update_slots: id  1 | task 13379 | prompt processing done, n_tokens = 56463, batch.n_tokens = 4
2026-05-15 18:56:43.574 | srv  log_server_r: done request: POST /v1/chat/completions 172.18.0.1 200
2026-05-15 18:56:46.355 | reasoning-budget: deactivated (natural end)
2026-05-15 18:56:48.087 | slot print_timing: id  1 | task 13379 | 
2026-05-15 18:56:48.087 | prompt eval time =     366.90 ms /    19 tokens (   19.31 ms per token,    51.79 tokens per second)
2026-05-15 18:56:48.087 |        eval time =    4493.64 ms /   233 tokens (   19.29 ms per token,    51.85 tokens per second)
2026-05-15 18:56:48.087 |       total time =    4860.54 ms /   252 tokens
2026-05-15 18:56:48.087 | draft acceptance rate = 0.97521 (  118 accepted /   121 generated)
2026-05-15 18:56:48.087 | statistics mtp: #calls(b,g,a) = 107 12117 9815, #gen drafts = 9815, #acc drafts = 9815, #gen tokens = 17409, #acc tokens = 17153, dur(b,g,a) = 0.144, 49678.820, 4.116 ms
2026-05-15 18:56:48.088 | slot      release: id  1 | task 13379 | stop processing: n_tokens = 56695, truncated = 0
2026-05-15 18:56:48.088 | srv  update_slots: all slots are idle
2026-05-15 19:00:36.801 | srv  params_from_: Chat format: peg-native
2026-05-15 19:00:36.803 | slot get_availabl: id  1 | task -1 | selected slot by LCP similarity, sim_best = 0.425 (> 0.100 thold), f_keep = 0.417
2026-05-15 19:00:36.803 | srv  get_availabl: updating prompt cache
2026-05-15 19:00:36.806 | srv   prompt_save:  - saving prompt with length 56695, total state size = 2151.894 MiB (draft: 118.735 MiB)
2026-05-15 19:00:42.789 | srv          load:  - looking for better prompt, base f_keep = 0.417, sim = 0.425
2026-05-15 19:00:42.789 | srv        update:  - cache state: 2 prompts, 7394.858 MiB (limits: 8192.000 MiB, 131072 tokens, 131072 est)
2026-05-15 19:00:42.789 | srv        update:    - prompt 0x6487e5e65ea0:   24821 tokens, checkpoints:  4,  1773.092 MiB
2026-05-15 19:00:42.789 | srv        update:    - prompt 0x6487e6b94a90:   56695 tokens, checkpoints: 15,  5621.766 MiB
2026-05-15 19:00:42.789 | srv  get_availabl: prompt cache update took 5985.38 ms
2026-05-15 19:00:42.790 | reasoning-budget: activated, budget=2147483647 tokens
2026-05-15 19:00:42.790 | slot launch_slot_: id  1 | task -1 | sampler chain: logits -> penalties -> ?dry -> ?top-n-sigma -> top-k -> ?typical -> ?top-p -> min-p -> ?xtc -> ?temp-ext -> dist 
2026-05-15 19:00:42.790 | slot launch_slot_: id  1 | task 13507 | processing task, is_child = 0
2026-05-15 19:00:42.790 | slot update_slots: id  1 | task 13507 | new prompt, n_ctx_slot = 131072, n_keep = 0, task.n_tokens = 55699
2026-05-15 19:00:42.790 | slot update_slots: id  1 | task 13507 | n_past = 23661, slot.prompt.tokens.size() = 56695, seq_id = 1, pos_min = 56694, n_swa = 0
2026-05-15 19:00:42.790 | slot update_slots: id  1 | task 13507 | Checking checkpoint with [56443, 56443] against 23661...
2026-05-15 19:00:42.790 | slot update_slots: id  1 | task 13507 | Checking checkpoint with [54289, 54289] against 23661...
2026-05-15 19:00:42.790 | slot update_slots: id  1 | task 13507 | Checking checkpoint with [53777, 53777] against 23661...
2026-05-15 19:00:42.790 | slot update_slots: id  1 | task 13507 | Checking checkpoint with [52708, 52708] against 23661...
2026-05-15 19:00:42.790 | slot update_slots: id  1 | task 13507 | Checking checkpoint with [52196, 52196] against 23661...
2026-05-15 19:00:42.790 | slot update_slots: id  1 | task 13507 | Checking checkpoint with [51586, 51586] against 23661...
2026-05-15 19:00:42.790 | slot update_slots: id  1 | task 13507 | Checking checkpoint with [51074, 51074] against 23661...
2026-05-15 19:00:42.790 | slot update_slots: id  1 | task 13507 | Checking checkpoint with [48584, 48584] against 23661...
2026-05-15 19:00:42.790 | slot update_slots: id  1 | task 13507 | Checking checkpoint with [40392, 40392] against 23661...
2026-05-15 19:00:42.790 | slot update_slots: id  1 | task 13507 | Checking checkpoint with [32200, 32200] against 23661...
2026-05-15 19:00:42.790 | slot update_slots: id  1 | task 13507 | Checking checkpoint with [23718, 23718] against 23661...
2026-05-15 19:00:42.790 | slot update_slots: id  1 | task 13507 | Checking checkpoint with [23206, 23206] against 23661...
2026-05-15 19:00:42.823 | slot update_slots: id  1 | task 13507 | restored context checkpoint (pos_min = 23206, pos_max = 23206, n_tokens = 23207, n_past = 23207, size = 198.228 MiB)
2026-05-15 19:00:42.823 | slot update_slots: id  1 | task 13507 | erased invalidated context checkpoint (pos_min = 23718, pos_max = 23718, n_tokens = 23719, n_swa = 0, pos_next = 23207, size = 199.300 MiB)
2026-05-15 19:00:42.834 | slot update_slots: id  1 | task 13507 | erased invalidated context checkpoint (pos_min = 32200, pos_max = 32200, n_tokens = 32201, n_swa = 0, pos_next = 23207, size = 217.064 MiB)
2026-05-15 19:00:42.847 | slot update_slots: id  1 | task 13507 | erased invalidated context checkpoint (pos_min = 40392, pos_max = 40392, n_tokens = 40393, n_swa = 0, pos_next = 23207, size = 234.220 MiB)
2026-05-15 19:00:42.860 | slot update_slots: id  1 | task 13507 | erased invalidated context checkpoint (pos_min = 48584, pos_max = 48584, n_tokens = 48585, n_swa = 0, pos_next = 23207, size = 251.376 MiB)
2026-05-15 19:00:42.874 | slot update_slots: id  1 | task 13507 | erased invalidated context checkpoint (pos_min = 51074, pos_max = 51074, n_tokens = 51075, n_swa = 0, pos_next = 23207, size = 256.591 MiB)
2026-05-15 19:00:42.888 | slot update_slots: id  1 | task 13507 | erased invalidated context checkpoint (pos_min = 51586, pos_max = 51586, n_tokens = 51587, n_swa = 0, pos_next = 23207, size = 257.663 MiB)
2026-05-15 19:00:42.903 | slot update_slots: id  1 | task 13507 | erased invalidated context checkpoint (pos_min = 52196, pos_max = 52196, n_tokens = 52197, n_swa = 0, pos_next = 23207, size = 258.941 MiB)
2026-05-15 19:00:42.917 | slot update_slots: id  1 | task 13507 | erased invalidated context checkpoint (pos_min = 52708, pos_max = 52708, n_tokens = 52709, n_swa = 0, pos_next = 23207, size = 260.013 MiB)
2026-05-15 19:00:42.932 | slot update_slots: id  1 | task 13507 | erased invalidated context checkpoint (pos_min = 53777, pos_max = 53777, n_tokens = 53778, n_swa = 0, pos_next = 23207, size = 262.252 MiB)
2026-05-15 19:00:42.947 | slot update_slots: id  1 | task 13507 | erased invalidated context checkpoint (pos_min = 54289, pos_max = 54289, n_tokens = 54290, n_swa = 0, pos_next = 23207, size = 263.324 MiB)
2026-05-15 19:00:42.962 | slot update_slots: id  1 | task 13507 | erased invalidated context checkpoint (pos_min = 56443, pos_max = 56443, n_tokens = 56444, n_swa = 0, pos_next = 23207, size = 267.835 MiB)
2026-05-15 19:00:42.977 | slot update_slots: id  1 | task 13507 | n_tokens = 23207, memory_seq_rm [23207, end)
2026-05-15 19:00:42.981 | slot update_slots: id  1 | task 13507 | prompt processing progress, n_tokens = 25255, batch.n_tokens = 2048, progress = 0.453419
2026-05-15 19:00:43.815 | slot update_slots: id  1 | task 13507 | n_tokens = 25255, memory_seq_rm [25255, end)
2026-05-15 19:00:43.815 | slot update_slots: id  1 | task 13507 | prompt processing progress, n_tokens = 27303, batch.n_tokens = 2048, progress = 0.490188
2026-05-15 19:00:44.658 | slot update_slots: id  1 | task 13507 | n_tokens = 27303, memory_seq_rm [27303, end)
2026-05-15 19:00:44.658 | slot update_slots: id  1 | task 13507 | prompt processing progress, n_tokens = 29351, batch.n_tokens = 2048, progress = 0.526957
2026-05-15 19:00:45.517 | slot update_slots: id  1 | task 13507 | n_tokens = 29351, memory_seq_rm [29351, end)
2026-05-15 19:00:45.517 | slot update_slots: id  1 | task 13507 | prompt processing progress, n_tokens = 31399, batch.n_tokens = 2048, progress = 0.563726
2026-05-15 19:00:46.421 | slot update_slots: id  1 | task 13507 | n_tokens = 31399, memory_seq_rm [31399, end)
2026-05-15 19:00:46.421 | slot update_slots: id  1 | task 13507 | 8192 tokens since last checkpoint at 23207, creating new checkpoint during processing at position 33447
2026-05-15 19:00:46.421 | slot update_slots: id  1 | task 13507 | prompt processing progress, n_tokens = 33447, batch.n_tokens = 2048, progress = 0.600496
2026-05-15 19:00:46.582 | slot create_check: id  1 | task 13507 | created context checkpoint 5 of 32 (pos_min = 31398, pos_max = 31398, n_tokens = 31399, size = 215.384 MiB)
2026-05-15 19:00:47.490 | slot update_slots: id  1 | task 13507 | n_tokens = 33447, memory_seq_rm [33447, end)
2026-05-15 19:00:47.490 | slot update_slots: id  1 | task 13507 | prompt processing progress, n_tokens = 35495, batch.n_tokens = 2048, progress = 0.637265
2026-05-15 19:00:48.423 | slot update_slots: id  1 | task 13507 | n_tokens = 35495, memory_seq_rm [35495, end)
2026-05-15 19:00:48.423 | slot update_slots: id  1 | task 13507 | prompt processing progress, n_tokens = 37543, batch.n_tokens = 2048, progress = 0.674034
2026-05-15 19:00:49.376 | slot update_slots: id  1 | task 13507 | n_tokens = 37543, memory_seq_rm [37543, end)
2026-05-15 19:00:49.376 | slot update_slots: id  1 | task 13507 | prompt processing progress, n_tokens = 39591, batch.n_tokens = 2048, progress = 0.710803
2026-05-15 19:00:50.352 | slot update_slots: id  1 | task 13507 | n_tokens = 39591, memory_seq_rm [39591, end)
2026-05-15 19:00:50.352 | slot update_slots: id  1 | task 13507 | 8192 tokens since last checkpoint at 31399, creating new checkpoint during processing at position 41639
2026-05-15 19:00:50.352 | slot update_slots: id  1 | task 13507 | prompt processing progress, n_tokens = 41639, batch.n_tokens = 2048, progress = 0.747572
2026-05-15 19:00:50.581 | slot create_check: id  1 | task 13507 | created context checkpoint 6 of 32 (pos_min = 39590, pos_max = 39590, n_tokens = 39591, size = 232.540 MiB)
2026-05-15 19:00:51.578 | slot update_slots: id  1 | task 13507 | n_tokens = 41639, memory_seq_rm [41639, end)
2026-05-15 19:00:51.578 | slot update_slots: id  1 | task 13507 | prompt processing progress, n_tokens = 43687, batch.n_tokens = 2048, progress = 0.784341
2026-05-15 19:00:52.597 | slot update_slots: id  1 | task 13507 | n_tokens = 43687, memory_seq_rm [43687, end)
2026-05-15 19:00:52.598 | slot update_slots: id  1 | task 13507 | prompt processing progress, n_tokens = 45735, batch.n_tokens = 2048, progress = 0.821110
2026-05-15 19:00:53.646 | slot update_slots: id  1 | task 13507 | n_tokens = 45735, memory_seq_rm [45735, end)
2026-05-15 19:00:53.646 | slot update_slots: id  1 | task 13507 | prompt processing progress, n_tokens = 47783, batch.n_tokens = 2048, progress = 0.857879
2026-05-15 19:00:54.724 | slot update_slots: id  1 | task 13507 | n_tokens = 47783, memory_seq_rm [47783, end)
2026-05-15 19:00:54.724 | slot update_slots: id  1 | task 13507 | 8192 tokens since last checkpoint at 39591, creating new checkpoint during processing at position 49831
2026-05-15 19:00:54.724 | slot update_slots: id  1 | task 13507 | prompt processing progress, n_tokens = 49831, batch.n_tokens = 2048, progress = 0.894648
2026-05-15 19:00:55.008 | slot create_check: id  1 | task 13507 | created context checkpoint 7 of 32 (pos_min = 47782, pos_max = 47782, n_tokens = 47783, size = 249.697 MiB)
2026-05-15 19:00:56.110 | slot update_slots: id  1 | task 13507 | n_tokens = 49831, memory_seq_rm [49831, end)
2026-05-15 19:00:56.110 | slot update_slots: id  1 | task 13507 | prompt processing progress, n_tokens = 51879, batch.n_tokens = 2048, progress = 0.931417
2026-05-15 19:00:57.254 | slot update_slots: id  1 | task 13507 | n_tokens = 51879, memory_seq_rm [51879, end)
2026-05-15 19:00:57.254 | slot update_slots: id  1 | task 13507 | prompt processing progress, n_tokens = 53927, batch.n_tokens = 2048, progress = 0.968186
2026-05-15 19:00:58.420 | slot update_slots: id  1 | task 13507 | n_tokens = 53927, memory_seq_rm [53927, end)
2026-05-15 19:00:58.420 | slot update_slots: id  1 | task 13507 | prompt processing progress, n_tokens = 55183, batch.n_tokens = 1256, progress = 0.990736
2026-05-15 19:00:59.180 | slot update_slots: id  1 | task 13507 | n_tokens = 55183, memory_seq_rm [55183, end)
2026-05-15 19:00:59.180 | slot update_slots: id  1 | task 13507 | prompt processing progress, n_tokens = 55695, batch.n_tokens = 512, progress = 0.999928
2026-05-15 19:00:59.466 | slot create_check: id  1 | task 13507 | created context checkpoint 8 of 32 (pos_min = 55182, pos_max = 55182, n_tokens = 55183, size = 265.194 MiB)
2026-05-15 19:00:59.766 | slot update_slots: id  1 | task 13507 | n_tokens = 55695, memory_seq_rm [55695, end)
2026-05-15 19:00:59.772 | slot init_sampler: id  1 | task 13507 | init sampler, took 6.91 ms, tokens: text = 55699, total = 55699
2026-05-15 19:00:59.773 | slot update_slots: id  1 | task 13507 | prompt processing done, n_tokens = 55699, batch.n_tokens = 4
2026-05-15 19:01:00.064 | slot create_check: id  1 | task 13507 | created context checkpoint 9 of 32 (pos_min = 55694, pos_max = 55694, n_tokens = 55695, size = 266.266 MiB)
2026-05-15 19:01:00.103 | srv  log_server_r: done request: POST /v1/chat/completions 172.18.0.1 200
2026-05-15 19:01:03.418 | reasoning-budget: deactivated (natural end)
2026-05-15 19:01:06.012 | slot print_timing: id  1 | task 13507 | 
2026-05-15 19:01:06.012 | prompt eval time =   17294.64 ms / 32492 tokens (    0.53 ms per token,  1878.73 tokens per second)
2026-05-15 19:01:06.012 |        eval time =    5908.88 ms /   332 tokens (   17.80 ms per token,    56.19 tokens per second)
2026-05-15 19:01:06.012 |       total time =   23203.52 ms / 32824 tokens
2026-05-15 19:01:06.012 | draft acceptance rate = 0.97838 (  181 accepted /   185 generated)
2026-05-15 19:01:06.012 | statistics mtp: #calls(b,g,a) = 108 12267 9922, #gen drafts = 9922, #acc drafts = 9922, #gen tokens = 17594, #acc tokens = 17334, dur(b,g,a) = 0.146, 50237.469, 4.158 ms
2026-05-15 19:01:06.013 | slot      release: id  1 | task 13507 | stop processing: n_tokens = 56030, truncated = 0
2026-05-15 19:01:06.013 | srv  update_slots: all slots are idle
2026-05-15 19:01:06.253 | srv  params_from_: Chat format: peg-native
2026-05-15 19:01:06.256 | slot get_availabl: id  1 | task -1 | selected slot by LCP similarity, sim_best = 0.992 (> 0.100 thold), f_keep = 1.000
2026-05-15 19:01:06.257 | reasoning-budget: activated, budget=2147483647 tokens
2026-05-15 19:01:06.257 | slot launch_slot_: id  1 | task -1 | sampler chain: logits -> penalties -> ?dry -> ?top-n-sigma -> top-k -> ?typical -> ?top-p -> min-p -> ?xtc -> ?temp-ext -> dist 
2026-05-15 19:01:06.257 | slot launch_slot_: id  1 | task 13691 | processing task, is_child = 0
2026-05-15 19:01:06.257 | slot update_slots: id  1 | task 13691 | new prompt, n_ctx_slot = 131072, n_keep = 0, task.n_tokens = 56472
2026-05-15 19:01:06.257 | slot update_slots: id  1 | task 13691 | n_tokens = 56030, memory_seq_rm [56030, end)
2026-05-15 19:01:06.257 | slot update_slots: id  1 | task 13691 | prompt processing progress, n_tokens = 56468, batch.n_tokens = 438, progress = 0.999929
2026-05-15 19:01:06.550 | slot create_check: id  1 | task 13691 | created context checkpoint 10 of 32 (pos_min = 56029, pos_max = 56029, n_tokens = 56030, size = 266.968 MiB)
2026-05-15 19:01:06.783 | slot update_slots: id  1 | task 13691 | n_tokens = 56468, memory_seq_rm [56468, end)
2026-05-15 19:01:06.790 | slot init_sampler: id  1 | task 13691 | init sampler, took 7.28 ms, tokens: text = 56472, total = 56472
2026-05-15 19:01:06.790 | slot update_slots: id  1 | task 13691 | prompt processing done, n_tokens = 56472, batch.n_tokens = 4
2026-05-15 19:01:07.082 | slot create_check: id  1 | task 13691 | created context checkpoint 11 of 32 (pos_min = 56467, pos_max = 56467, n_tokens = 56468, size = 267.885 MiB)
2026-05-15 19:01:07.122 | srv  log_server_r: done request: POST /v1/chat/completions 172.18.0.1 200
2026-05-15 19:01:07.518 | reasoning-budget: deactivated (natural end)
2026-05-15 19:01:08.204 | slot print_timing: id  1 | task 13691 | 
2026-05-15 19:01:08.204 | prompt eval time =     864.18 ms /   442 tokens (    1.96 ms per token,   511.47 tokens per second)
2026-05-15 19:01:08.204 |        eval time =    1082.26 ms /    70 tokens (   15.46 ms per token,    64.68 tokens per second)
2026-05-15 19:01:08.204 |       total time =    1946.44 ms /   512 tokens
2026-05-15 19:01:08.204 | draft acceptance rate = 1.00000 (   41 accepted /    41 generated)
2026-05-15 19:01:08.204 | statistics mtp: #calls(b,g,a) = 109 12295 9945, #gen drafts = 9945, #acc drafts = 9945, #gen tokens = 17635, #acc tokens = 17375, dur(b,g,a) = 0.147, 50348.786, 4.165 ms
2026-05-15 19:01:08.205 | slot      release: id  1 | task 13691 | stop processing: n_tokens = 56541, truncated = 0
2026-05-15 19:01:08.205 | srv  update_slots: all slots are idle
2026-05-15 19:01:08.412 | srv  params_from_: Chat format: peg-native
2026-05-15 19:01:08.415 | slot get_availabl: id  1 | task -1 | selected slot by LCP similarity, sim_best = 0.976 (> 0.100 thold), f_keep = 1.000
2026-05-15 19:01:08.416 | reasoning-budget: activated, budget=2147483647 tokens
2026-05-15 19:01:08.416 | slot launch_slot_: id  1 | task -1 | sampler chain: logits -> penalties -> ?dry -> ?top-n-sigma -> top-k -> ?typical -> ?top-p -> min-p -> ?xtc -> ?temp-ext -> dist 
2026-05-15 19:01:08.416 | slot launch_slot_: id  1 | task 13725 | processing task, is_child = 0
2026-05-15 19:01:08.416 | slot update_slots: id  1 | task 13725 | new prompt, n_ctx_slot = 131072, n_keep = 0, task.n_tokens = 57931
2026-05-15 19:01:08.416 | slot update_slots: id  1 | task 13725 | n_tokens = 56541, memory_seq_rm [56541, end)
2026-05-15 19:01:08.416 | slot update_slots: id  1 | task 13725 | prompt processing progress, n_tokens = 57415, batch.n_tokens = 874, progress = 0.991093
2026-05-15 19:01:08.949 | slot update_slots: id  1 | task 13725 | n_tokens = 57415, memory_seq_rm [57415, end)
2026-05-15 19:01:08.949 | slot update_slots: id  1 | task 13725 | prompt processing progress, n_tokens = 57927, batch.n_tokens = 512, progress = 0.999931
2026-05-15 19:01:09.242 | slot create_check: id  1 | task 13725 | created context checkpoint 12 of 32 (pos_min = 57414, pos_max = 57414, n_tokens = 57415, size = 269.869 MiB)
2026-05-15 19:01:09.550 | slot update_slots: id  1 | task 13725 | n_tokens = 57927, memory_seq_rm [57927, end)
2026-05-15 19:01:09.557 | slot init_sampler: id  1 | task 13725 | init sampler, took 7.28 ms, tokens: text = 57931, total = 57931
2026-05-15 19:01:09.557 | slot update_slots: id  1 | task 13725 | prompt processing done, n_tokens = 57931, batch.n_tokens = 4
2026-05-15 19:01:09.852 | slot create_check: id  1 | task 13725 | created context checkpoint 13 of 32 (pos_min = 57926, pos_max = 57926, n_tokens = 57927, size = 270.941 MiB)
2026-05-15 19:01:09.890 | srv  log_server_r: done request: POST /v1/chat/completions 172.18.0.1 200
2026-05-15 19:01:13.159 | reasoning-budget: deactivated (natural end)
2026-05-15 19:01:13.952 | slot print_timing: id  1 | task 13725 | 
2026-05-15 19:01:13.952 | prompt eval time =    1473.46 ms /  1390 tokens (    1.06 ms per token,   943.36 tokens per second)
2026-05-15 19:01:13.952 |        eval time =    4061.66 ms /   222 tokens (   18.30 ms per token,    54.66 tokens per second)
2026-05-15 19:01:13.952 |       total time =    5535.13 ms /  1612 tokens
2026-05-15 19:01:13.952 | draft acceptance rate = 0.96491 (  110 accepted /   114 generated)
2026-05-15 19:01:13.952 | statistics mtp: #calls(b,g,a) = 110 12406 10011, #gen drafts = 10011, #acc drafts = 10011, #gen tokens = 17749, #acc tokens = 17485, dur(b,g,a) = 0.148, 50730.050, 4.198 ms
2026-05-15 19:01:13.953 | slot      release: id  1 | task 13725 | stop processing: n_tokens = 58152, truncated = 0
2026-05-15 19:01:13.953 | srv  update_slots: all slots are idle
2026-05-15 19:01:14.166 | srv  params_from_: Chat format: peg-native
2026-05-15 19:01:14.168 | slot get_availabl: id  1 | task -1 | selected slot by LCP similarity, sim_best = 0.977 (> 0.100 thold), f_keep = 1.000
2026-05-15 19:01:14.169 | reasoning-budget: activated, budget=2147483647 tokens
2026-05-15 19:01:14.170 | slot launch_slot_: id  1 | task -1 | sampler chain: logits -> penalties -> ?dry -> ?top-n-sigma -> top-k -> ?typical -> ?top-p -> min-p -> ?xtc -> ?temp-ext -> dist 
2026-05-15 19:01:14.170 | slot launch_slot_: id  1 | task 13847 | processing task, is_child = 0
2026-05-15 19:01:14.170 | slot update_slots: id  1 | task 13847 | new prompt, n_ctx_slot = 131072, n_keep = 0, task.n_tokens = 59534
2026-05-15 19:01:14.170 | slot update_slots: id  1 | task 13847 | n_tokens = 58152, memory_seq_rm [58152, end)
2026-05-15 19:01:14.170 | slot update_slots: id  1 | task 13847 | prompt processing progress, n_tokens = 59018, batch.n_tokens = 866, progress = 0.991333
2026-05-15 19:01:14.681 | slot update_slots: id  1 | task 13847 | n_tokens = 59018, memory_seq_rm [59018, end)
2026-05-15 19:01:14.681 | slot update_slots: id  1 | task 13847 | prompt processing progress, n_tokens = 59530, batch.n_tokens = 512, progress = 0.999933
2026-05-15 19:01:14.973 | slot create_check: id  1 | task 13847 | created context checkpoint 14 of 32 (pos_min = 59017, pos_max = 59017, n_tokens = 59018, size = 273.226 MiB)
2026-05-15 19:01:15.289 | slot update_slots: id  1 | task 13847 | n_tokens = 59530, memory_seq_rm [59530, end)
2026-05-15 19:01:15.296 | slot init_sampler: id  1 | task 13847 | init sampler, took 7.30 ms, tokens: text = 59534, total = 59534
2026-05-15 19:01:15.296 | slot update_slots: id  1 | task 13847 | prompt processing done, n_tokens = 59534, batch.n_tokens = 4
2026-05-15 19:01:15.596 | slot create_check: id  1 | task 13847 | created context checkpoint 15 of 32 (pos_min = 59529, pos_max = 59529, n_tokens = 59530, size = 274.298 MiB)
2026-05-15 19:01:15.636 | srv  log_server_r: done request: POST /v1/chat/completions 172.18.0.1 200
2026-05-15 19:01:22.763 | reasoning-budget: deactivated (natural end)
2026-05-15 19:01:23.316 | slot print_timing: id  1 | task 13847 | 
2026-05-15 19:01:23.316 | prompt eval time =    1465.70 ms /  1382 tokens (    1.06 ms per token,   942.89 tokens per second)
2026-05-15 19:01:23.316 |        eval time =    7659.60 ms /   375 tokens (   20.43 ms per token,    48.96 tokens per second)
2026-05-15 19:01:23.316 |       total time =    9125.30 ms /  1757 tokens
2026-05-15 19:01:23.316 | draft acceptance rate = 0.97110 (  168 accepted /   173 generated)
2026-05-15 19:01:23.316 | statistics mtp: #calls(b,g,a) = 111 12612 10117, #gen drafts = 10117, #acc drafts = 10117, #gen tokens = 17922, #acc tokens = 17653, dur(b,g,a) = 0.149, 51414.246, 4.242 ms
2026-05-15 19:01:23.317 | slot      release: id  1 | task 13847 | stop processing: n_tokens = 59908, truncated = 0
2026-05-15 19:01:23.317 | srv  update_slots: all slots are idle
2026-05-15 19:01:23.544 | srv  params_from_: Chat format: peg-native
2026-05-15 19:01:23.547 | slot get_availabl: id  1 | task -1 | selected slot by LCP similarity, sim_best = 0.833 (> 0.100 thold), f_keep = 1.000
2026-05-15 19:01:23.548 | reasoning-budget: activated, budget=2147483647 tokens
2026-05-15 19:01:23.548 | slot launch_slot_: id  1 | task -1 | sampler chain: logits -> penalties -> ?dry -> ?top-n-sigma -> top-k -> ?typical -> ?top-p -> min-p -> ?xtc -> ?temp-ext -> dist 
2026-05-15 19:01:23.548 | slot launch_slot_: id  1 | task 14074 | processing task, is_child = 0
2026-05-15 19:01:23.548 | slot update_slots: id  1 | task 14074 | new prompt, n_ctx_slot = 131072, n_keep = 0, task.n_tokens = 71914
2026-05-15 19:01:23.548 | slot update_slots: id  1 | task 14074 | n_tokens = 59908, memory_seq_rm [59908, end)
2026-05-15 19:01:23.548 | slot update_slots: id  1 | task 14074 | prompt processing progress, n_tokens = 61956, batch.n_tokens = 2048, progress = 0.861529
2026-05-15 19:01:24.839 | slot update_slots: id  1 | task 14074 | n_tokens = 61956, memory_seq_rm [61956, end)
2026-05-15 19:01:24.839 | slot update_slots: id  1 | task 14074 | prompt processing progress, n_tokens = 64004, batch.n_tokens = 2048, progress = 0.890007
2026-05-15 19:01:26.152 | slot update_slots: id  1 | task 14074 | n_tokens = 64004, memory_seq_rm [64004, end)
2026-05-15 19:01:26.152 | slot update_slots: id  1 | task 14074 | prompt processing progress, n_tokens = 66052, batch.n_tokens = 2048, progress = 0.918486
2026-05-15 19:01:27.496 | slot update_slots: id  1 | task 14074 | n_tokens = 66052, memory_seq_rm [66052, end)
2026-05-15 19:01:27.496 | slot update_slots: id  1 | task 14074 | prompt processing progress, n_tokens = 68100, batch.n_tokens = 2048, progress = 0.946964
2026-05-15 19:01:28.864 | slot update_slots: id  1 | task 14074 | n_tokens = 68100, memory_seq_rm [68100, end)
2026-05-15 19:01:28.864 | slot update_slots: id  1 | task 14074 | 8192 tokens since last checkpoint at 59530, creating new checkpoint during processing at position 70148
2026-05-15 19:01:28.864 | slot update_slots: id  1 | task 14074 | prompt processing progress, n_tokens = 70148, batch.n_tokens = 2048, progress = 0.975443
2026-05-15 19:01:29.171 | slot create_check: id  1 | task 14074 | created context checkpoint 16 of 32 (pos_min = 68099, pos_max = 68099, n_tokens = 68100, size = 292.246 MiB)
2026-05-15 19:01:30.575 | slot update_slots: id  1 | task 14074 | n_tokens = 70148, memory_seq_rm [70148, end)
2026-05-15 19:01:30.575 | slot update_slots: id  1 | task 14074 | prompt processing progress, n_tokens = 71398, batch.n_tokens = 1250, progress = 0.992825
2026-05-15 19:01:31.480 | slot update_slots: id  1 | task 14074 | n_tokens = 71398, memory_seq_rm [71398, end)
2026-05-15 19:01:31.480 | slot update_slots: id  1 | task 14074 | prompt processing progress, n_tokens = 71910, batch.n_tokens = 512, progress = 0.999944
2026-05-15 19:01:31.808 | slot create_check: id  1 | task 14074 | created context checkpoint 17 of 32 (pos_min = 71397, pos_max = 71397, n_tokens = 71398, size = 299.153 MiB)
2026-05-15 19:01:32.170 | slot update_slots: id  1 | task 14074 | n_tokens = 71910, memory_seq_rm [71910, end)
2026-05-15 19:01:32.179 | slot init_sampler: id  1 | task 14074 | init sampler, took 9.12 ms, tokens: text = 71914, total = 71914
2026-05-15 19:01:32.179 | slot update_slots: id  1 | task 14074 | prompt processing done, n_tokens = 71914, batch.n_tokens = 4
2026-05-15 19:01:32.508 | slot create_check: id  1 | task 14074 | created context checkpoint 18 of 32 (pos_min = 71909, pos_max = 71909, n_tokens = 71910, size = 300.225 MiB)
2026-05-15 19:01:32.548 | srv  log_server_r: done request: POST /v1/chat/completions 172.18.0.1 200
2026-05-15 19:01:46.787 | reasoning-budget: deactivated (natural end)
2026-05-15 19:01:53.121 | slot print_timing: id  1 | task 14074 | 
2026-05-15 19:01:53.121 | prompt eval time =    8999.86 ms / 12006 tokens (    0.75 ms per token,  1334.02 tokens per second)
2026-05-15 19:01:53.121 |        eval time =   20551.38 ms /  1011 tokens (   20.33 ms per token,    49.19 tokens per second)
2026-05-15 19:01:53.121 |       total time =   29551.24 ms / 13017 tokens
2026-05-15 19:01:53.121 | draft acceptance rate = 0.97468 (  462 accepted /   474 generated)
2026-05-15 19:01:53.121 | statistics mtp: #calls(b,g,a) = 112 13160 10415, #gen drafts = 10415, #acc drafts = 10415, #gen tokens = 18396, #acc tokens = 18115, dur(b,g,a) = 0.150, 53303.075, 4.366 ms
2026-05-15 19:01:53.123 | slot      release: id  1 | task 14074 | stop processing: n_tokens = 72924, truncated = 0
2026-05-15 19:01:53.123 | srv  update_slots: all slots are idle
2026-05-15 19:01:53.362 | srv  params_from_: Chat format: peg-native
2026-05-15 19:01:53.365 | slot get_availabl: id  1 | task -1 | selected slot by LCP similarity, sim_best = 1.000 (> 0.100 thold), f_keep = 1.000
2026-05-15 19:01:53.366 | reasoning-budget: activated, budget=2147483647 tokens
2026-05-15 19:01:53.366 | slot launch_slot_: id  1 | task -1 | sampler chain: logits -> penalties -> ?dry -> ?top-n-sigma -> top-k -> ?typical -> ?top-p -> min-p -> ?xtc -> ?temp-ext -> dist 
2026-05-15 19:01:53.366 | slot launch_slot_: id  1 | task 14664 | processing task, is_child = 0
2026-05-15 19:01:53.366 | slot update_slots: id  1 | task 14664 | new prompt, n_ctx_slot = 131072, n_keep = 0, task.n_tokens = 72943
2026-05-15 19:01:53.366 | slot update_slots: id  1 | task 14664 | n_tokens = 72924, memory_seq_rm [72924, end)
2026-05-15 19:01:53.367 | slot update_slots: id  1 | task 14664 | prompt processing progress, n_tokens = 72939, batch.n_tokens = 15, progress = 0.999945
2026-05-15 19:01:53.655 | slot create_check: id  1 | task 14664 | created context checkpoint 19 of 32 (pos_min = 72923, pos_max = 72923, n_tokens = 72924, size = 302.349 MiB)
2026-05-15 19:01:53.699 | slot update_slots: id  1 | task 14664 | n_tokens = 72939, memory_seq_rm [72939, end)
2026-05-15 19:01:53.708 | slot init_sampler: id  1 | task 14664 | init sampler, took 9.05 ms, tokens: text = 72943, total = 72943
2026-05-15 19:01:53.708 | slot update_slots: id  1 | task 14664 | prompt processing done, n_tokens = 72943, batch.n_tokens = 4
2026-05-15 19:01:53.748 | srv  log_server_r: done request: POST /v1/chat/completions 172.18.0.1 200
2026-05-15 19:01:56.057 | reasoning-budget: deactivated (natural end)
2026-05-15 19:01:57.733 | slot print_timing: id  1 | task 14664 | 
2026-05-15 19:01:57.733 | prompt eval time =     381.23 ms /    19 tokens (   20.06 ms per token,    49.84 tokens per second)
2026-05-15 19:01:57.733 |        eval time =    3984.96 ms /   230 tokens (   17.33 ms per token,    57.72 tokens per second)
2026-05-15 19:01:57.733 |       total time =    4366.19 ms /   249 tokens
2026-05-15 19:01:57.733 | draft acceptance rate = 0.99219 (  127 accepted /   128 generated)
2026-05-15 19:01:57.733 | statistics mtp: #calls(b,g,a) = 113 13262 10486, #gen drafts = 10486, #acc drafts = 10486, #gen tokens = 18524, #acc tokens = 18242, dur(b,g,a) = 0.151, 53694.400, 4.401 ms
2026-05-15 19:01:57.735 | slot      release: id  1 | task 14664 | stop processing: n_tokens = 73172, truncated = 0
2026-05-15 19:01:57.735 | srv  update_slots: all slots are idle
2026-05-15 19:01:57.967 | srv  params_from_: Chat format: peg-native
2026-05-15 19:01:57.969 | slot get_availabl: id  1 | task -1 | selected slot by LCP similarity, sim_best = 1.000 (> 0.100 thold), f_keep = 1.000
2026-05-15 19:01:57.971 | reasoning-budget: activated, budget=2147483647 tokens
2026-05-15 19:01:57.971 | slot launch_slot_: id  1 | task -1 | sampler chain: logits -> penalties -> ?dry -> ?top-n-sigma -> top-k -> ?typical -> ?top-p -> min-p -> ?xtc -> ?temp-ext -> dist 
2026-05-15 19:01:57.971 | slot launch_slot_: id  1 | task 14774 | processing task, is_child = 0
2026-05-15 19:01:57.971 | slot update_slots: id  1 | task 14774 | new prompt, n_ctx_slot = 131072, n_keep = 0, task.n_tokens = 73190
2026-05-15 19:01:57.971 | slot update_slots: id  1 | task 14774 | n_tokens = 73172, memory_seq_rm [73172, end)
2026-05-15 19:01:57.971 | slot update_slots: id  1 | task 14774 | prompt processing progress, n_tokens = 73186, batch.n_tokens = 14, progress = 0.999945
2026-05-15 19:01:58.305 | slot create_check: id  1 | task 14774 | created context checkpoint 20 of 32 (pos_min = 73171, pos_max = 73171, n_tokens = 73172, size = 302.868 MiB)
2026-05-15 19:01:58.351 | slot update_slots: id  1 | task 14774 | n_tokens = 73186, memory_seq_rm [73186, end)
2026-05-15 19:01:58.360 | slot init_sampler: id  1 | task 14774 | init sampler, took 9.21 ms, tokens: text = 73190, total = 73190
2026-05-15 19:01:58.360 | slot update_slots: id  1 | task 14774 | prompt processing done, n_tokens = 73190, batch.n_tokens = 4
2026-05-15 19:01:58.402 | srv  log_server_r: done request: POST /v1/chat/completions 172.18.0.1 200
2026-05-15 19:02:03.877 | reasoning-budget: deactivated (natural end)
2026-05-15 19:02:06.916 | slot print_timing: id  1 | task 14774 | 
2026-05-15 19:02:06.916 | prompt eval time =     430.57 ms /    18 tokens (   23.92 ms per token,    41.80 tokens per second)
2026-05-15 19:02:06.916 |        eval time =    8514.36 ms /   442 tokens (   19.26 ms per token,    51.91 tokens per second)
2026-05-15 19:02:06.916 |       total time =    8944.93 ms /   460 tokens
2026-05-15 19:02:06.916 | draft acceptance rate = 0.97845 (  227 accepted /   232 generated)
2026-05-15 19:02:06.916 | statistics mtp: #calls(b,g,a) = 114 13476 10626, #gen drafts = 10626, #acc drafts = 10626, #gen tokens = 18756, #acc tokens = 18469, dur(b,g,a) = 0.153, 54491.839, 4.444 ms
2026-05-15 19:02:06.918 | slot      release: id  1 | task 14774 | stop processing: n_tokens = 73631, truncated = 0
2026-05-15 19:02:06.918 | srv  update_slots: all slots are idle
2026-05-15 19:02:07.152 | srv  params_from_: Chat format: peg-native
2026-05-15 19:02:07.155 | slot get_availabl: id  1 | task -1 | selected slot by LCP similarity, sim_best = 1.000 (> 0.100 thold), f_keep = 1.000
2026-05-15 19:02:07.156 | reasoning-budget: activated, budget=2147483647 tokens
2026-05-15 19:02:07.156 | slot launch_slot_: id  1 | task -1 | sampler chain: logits -> penalties -> ?dry -> ?top-n-sigma -> top-k -> ?typical -> ?top-p -> min-p -> ?xtc -> ?temp-ext -> dist 
2026-05-15 19:02:07.156 | slot launch_slot_: id  1 | task 15007 | processing task, is_child = 0
2026-05-15 19:02:07.156 | slot update_slots: id  1 | task 15007 | new prompt, n_ctx_slot = 131072, n_keep = 0, task.n_tokens = 73649
2026-05-15 19:02:07.156 | slot update_slots: id  1 | task 15007 | n_tokens = 73631, memory_seq_rm [73631, end)
2026-05-15 19:02:07.156 | slot update_slots: id  1 | task 15007 | prompt processing progress, n_tokens = 73645, batch.n_tokens = 14, progress = 0.999946
2026-05-15 19:02:07.506 | slot create_check: id  1 | task 15007 | created context checkpoint 21 of 32 (pos_min = 73630, pos_max = 73630, n_tokens = 73631, size = 303.829 MiB)
2026-05-15 19:02:07.551 | slot update_slots: id  1 | task 15007 | n_tokens = 73645, memory_seq_rm [73645, end)
2026-05-15 19:02:07.560 | slot init_sampler: id  1 | task 15007 | init sampler, took 9.25 ms, tokens: text = 73649, total = 73649
2026-05-15 19:02:07.560 | slot update_slots: id  1 | task 15007 | prompt processing done, n_tokens = 73649, batch.n_tokens = 4
2026-05-15 19:02:07.602 | srv  log_server_r: done request: POST /v1/chat/completions 172.18.0.1 200
2026-05-15 19:02:12.622 | reasoning-budget: deactivated (natural end)
2026-05-15 19:02:14.004 | slot print_timing: id  1 | task 15007 | 
2026-05-15 19:02:14.004 | prompt eval time =     445.81 ms /    18 tokens (   24.77 ms per token,    40.38 tokens per second)
2026-05-15 19:02:14.004 |        eval time =    6401.43 ms /   334 tokens (   19.17 ms per token,    52.18 tokens per second)
2026-05-15 19:02:14.004 |       total time =    6847.24 ms /   352 tokens
2026-05-15 19:02:14.004 | draft acceptance rate = 0.97619 (  164 accepted /   168 generated)
2026-05-15 19:02:14.004 | statistics mtp: #calls(b,g,a) = 115 13645 10724, #gen drafts = 10724, #acc drafts = 10724, #gen tokens = 18924, #acc tokens = 18633, dur(b,g,a) = 0.155, 55094.995, 4.499 ms
2026-05-15 19:02:14.005 | slot      release: id  1 | task 15007 | stop processing: n_tokens = 73982, truncated = 0
2026-05-15 19:02:14.005 | srv  update_slots: all slots are idle
2026-05-15 19:02:14.259 | srv  params_from_: Chat format: peg-native
2026-05-15 19:02:14.262 | slot get_availabl: id  1 | task -1 | selected slot by LCP similarity, sim_best = 0.992 (> 0.100 thold), f_keep = 1.000
2026-05-15 19:02:14.263 | reasoning-budget: activated, budget=2147483647 tokens
2026-05-15 19:02:14.263 | slot launch_slot_: id  1 | task -1 | sampler chain: logits -> penalties -> ?dry -> ?top-n-sigma -> top-k -> ?typical -> ?top-p -> min-p -> ?xtc -> ?temp-ext -> dist 
2026-05-15 19:02:14.263 | slot launch_slot_: id  1 | task 15190 | processing task, is_child = 0
2026-05-15 19:02:14.263 | slot update_slots: id  1 | task 15190 | new prompt, n_ctx_slot = 131072, n_keep = 0, task.n_tokens = 74547
2026-05-15 19:02:14.263 | slot update_slots: id  1 | task 15190 | n_tokens = 73982, memory_seq_rm [73982, end)
2026-05-15 19:02:14.264 | slot update_slots: id  1 | task 15190 | prompt processing progress, n_tokens = 74031, batch.n_tokens = 49, progress = 0.993078
2026-05-15 19:02:14.322 | slot update_slots: id  1 | task 15190 | n_tokens = 74031, memory_seq_rm [74031, end)
2026-05-15 19:02:14.322 | slot update_slots: id  1 | task 15190 | prompt processing progress, n_tokens = 74543, batch.n_tokens = 512, progress = 0.999946
2026-05-15 19:02:14.651 | slot create_check: id  1 | task 15190 | created context checkpoint 22 of 32 (pos_min = 74030, pos_max = 74030, n_tokens = 74031, size = 304.667 MiB)
2026-05-15 19:02:15.021 | slot update_slots: id  1 | task 15190 | n_tokens = 74543, memory_seq_rm [74543, end)
2026-05-15 19:02:15.030 | slot init_sampler: id  1 | task 15190 | init sampler, took 9.46 ms, tokens: text = 74547, total = 74547
2026-05-15 19:02:15.030 | slot update_slots: id  1 | task 15190 | prompt processing done, n_tokens = 74547, batch.n_tokens = 4
2026-05-15 19:02:15.367 | slot create_check: id  1 | task 15190 | created context checkpoint 23 of 32 (pos_min = 74542, pos_max = 74542, n_tokens = 74543, size = 305.739 MiB)
2026-05-15 19:02:15.407 | srv  log_server_r: done request: POST /v1/chat/completions 172.18.0.1 200
2026-05-15 19:02:15.976 | reasoning-budget: deactivated (natural end)
2026-05-15 19:02:16.782 | slot print_timing: id  1 | task 15190 | 
2026-05-15 19:02:16.782 | prompt eval time =    1143.54 ms /   565 tokens (    2.02 ms per token,   494.08 tokens per second)
2026-05-15 19:02:16.783 |        eval time =    1358.24 ms /    92 tokens (   14.76 ms per token,    67.73 tokens per second)
2026-05-15 19:02:16.783 |       total time =    2501.78 ms /   657 tokens
2026-05-15 19:02:16.783 | draft acceptance rate = 0.96610 (   57 accepted /    59 generated)
2026-05-15 19:02:16.783 | statistics mtp: #calls(b,g,a) = 116 13679 10754, #gen drafts = 10754, #acc drafts = 10754, #gen tokens = 18983, #acc tokens = 18690, dur(b,g,a) = 0.156, 55240.718, 4.507 ms
2026-05-15 19:02:16.784 | slot      release: id  1 | task 15190 | stop processing: n_tokens = 74638, truncated = 0
2026-05-15 19:02:16.784 | srv  update_slots: all slots are idle
2026-05-15 19:02:17.048 | srv  params_from_: Chat format: peg-native
2026-05-15 19:02:17.050 | slot get_availabl: id  1 | task -1 | selected slot by LCP similarity, sim_best = 0.983 (> 0.100 thold), f_keep = 1.000
2026-05-15 19:02:17.052 | reasoning-budget: activated, budget=2147483647 tokens
2026-05-15 19:02:17.052 | slot launch_slot_: id  1 | task -1 | sampler chain: logits -> penalties -> ?dry -> ?top-n-sigma -> top-k -> ?typical -> ?top-p -> min-p -> ?xtc -> ?temp-ext -> dist 
2026-05-15 19:02:17.052 | slot launch_slot_: id  1 | task 15230 | processing task, is_child = 0
2026-05-15 19:02:17.052 | slot update_slots: id  1 | task 15230 | new prompt, n_ctx_slot = 131072, n_keep = 0, task.n_tokens = 75953
2026-05-15 19:02:17.052 | slot update_slots: id  1 | task 15230 | n_tokens = 74638, memory_seq_rm [74638, end)
2026-05-15 19:02:17.052 | slot update_slots: id  1 | task 15230 | prompt processing progress, n_tokens = 75437, batch.n_tokens = 799, progress = 0.993206
2026-05-15 19:02:17.658 | slot update_slots: id  1 | task 15230 | n_tokens = 75437, memory_seq_rm [75437, end)
2026-05-15 19:02:17.658 | slot update_slots: id  1 | task 15230 | prompt processing progress, n_tokens = 75949, batch.n_tokens = 512, progress = 0.999947
2026-05-15 19:02:17.996 | slot create_check: id  1 | task 15230 | created context checkpoint 24 of 32 (pos_min = 75436, pos_max = 75436, n_tokens = 75437, size = 307.612 MiB)
2026-05-15 19:02:18.374 | slot update_slots: id  1 | task 15230 | n_tokens = 75949, memory_seq_rm [75949, end)
2026-05-15 19:02:18.384 | slot init_sampler: id  1 | task 15230 | init sampler, took 9.58 ms, tokens: text = 75953, total = 75953
2026-05-15 19:02:18.384 | slot update_slots: id  1 | task 15230 | prompt processing done, n_tokens = 75953, batch.n_tokens = 4
2026-05-15 19:02:18.727 | slot create_check: id  1 | task 15230 | created context checkpoint 25 of 32 (pos_min = 75948, pos_max = 75948, n_tokens = 75949, size = 308.684 MiB)
2026-05-15 19:02:18.769 | srv  log_server_r: done request: POST /v1/chat/completions 172.18.0.1 200
2026-05-15 19:02:25.765 | reasoning-budget: deactivated (natural end)
2026-05-15 19:02:27.169 | slot print_timing: id  1 | task 15230 | 
2026-05-15 19:02:27.169 | prompt eval time =    1717.21 ms /  1315 tokens (    1.31 ms per token,   765.77 tokens per second)
2026-05-15 19:02:27.169 |        eval time =    8400.18 ms /   452 tokens (   18.58 ms per token,    53.81 tokens per second)
2026-05-15 19:02:27.169 |       total time =   10117.40 ms /  1767 tokens
2026-05-15 19:02:27.169 | draft acceptance rate = 0.98770 (  241 accepted /   244 generated)
2026-05-15 19:02:27.169 | statistics mtp: #calls(b,g,a) = 117 13889 10895, #gen drafts = 10895, #acc drafts = 10895, #gen tokens = 19227, #acc tokens = 18931, dur(b,g,a) = 0.157, 56045.509, 4.572 ms
2026-05-15 19:02:27.171 | slot      release: id  1 | task 15230 | stop processing: n_tokens = 76404, truncated = 0
2026-05-15 19:02:27.171 | srv  update_slots: all slots are idle
2026-05-15 19:02:27.434 | srv  params_from_: Chat format: peg-native
2026-05-15 19:02:27.437 | slot get_availabl: id  1 | task -1 | selected slot by LCP similarity, sim_best = 0.996 (> 0.100 thold), f_keep = 1.000
2026-05-15 19:02:27.438 | reasoning-budget: activated, budget=2147483647 tokens
2026-05-15 19:02:27.438 | slot launch_slot_: id  1 | task -1 | sampler chain: logits -> penalties -> ?dry -> ?top-n-sigma -> top-k -> ?typical -> ?top-p -> min-p -> ?xtc -> ?temp-ext -> dist 
2026-05-15 19:02:27.438 | slot launch_slot_: id  1 | task 15456 | processing task, is_child = 0
2026-05-15 19:02:27.438 | slot update_slots: id  1 | task 15456 | new prompt, n_ctx_slot = 131072, n_keep = 0, task.n_tokens = 76733
2026-05-15 19:02:27.439 | slot update_slots: id  1 | task 15456 | n_tokens = 76404, memory_seq_rm [76404, end)
2026-05-15 19:02:27.439 | slot update_slots: id  1 | task 15456 | prompt processing progress, n_tokens = 76729, batch.n_tokens = 325, progress = 0.999948
2026-05-15 19:02:27.782 | slot create_check: id  1 | task 15456 | created context checkpoint 26 of 32 (pos_min = 76403, pos_max = 76403, n_tokens = 76404, size = 309.637 MiB)
2026-05-15 19:02:27.984 | slot update_slots: id  1 | task 15456 | n_tokens = 76729, memory_seq_rm [76729, end)
2026-05-15 19:02:27.994 | slot init_sampler: id  1 | task 15456 | init sampler, took 9.67 ms, tokens: text = 76733, total = 76733
2026-05-15 19:02:27.994 | slot update_slots: id  1 | task 15456 | prompt processing done, n_tokens = 76733, batch.n_tokens = 4
2026-05-15 19:02:28.336 | slot create_check: id  1 | task 15456 | created context checkpoint 27 of 32 (pos_min = 76728, pos_max = 76728, n_tokens = 76729, size = 310.317 MiB)
2026-05-15 19:02:28.378 | srv  log_server_r: done request: POST /v1/chat/completions 172.18.0.1 200
2026-05-15 19:02:29.232 | reasoning-budget: deactivated (natural end)
2026-05-15 19:02:31.657 | slot print_timing: id  1 | task 15456 | 
2026-05-15 19:02:31.657 | prompt eval time =     939.28 ms /   329 tokens (    2.85 ms per token,   350.27 tokens per second)
2026-05-15 19:02:31.657 |        eval time =    3278.41 ms /   225 tokens (   14.57 ms per token,    68.63 tokens per second)
2026-05-15 19:02:31.657 |       total time =    4217.70 ms /   554 tokens
2026-05-15 19:02:31.657 | draft acceptance rate = 0.97945 (  143 accepted /   146 generated)
2026-05-15 19:02:31.657 | statistics mtp: #calls(b,g,a) = 118 13970 10969, #gen drafts = 10969, #acc drafts = 10969, #gen tokens = 19373, #acc tokens = 19074, dur(b,g,a) = 0.159, 56401.989, 4.599 ms
2026-05-15 19:02:31.659 | slot      release: id  1 | task 15456 | stop processing: n_tokens = 76957, truncated = 0
2026-05-15 19:02:31.660 | srv  update_slots: all slots are idle
2026-05-15 19:02:31.928 | srv  params_from_: Chat format: peg-native
2026-05-15 19:02:31.931 | slot get_availabl: id  1 | task -1 | selected slot by LCP similarity, sim_best = 1.000 (> 0.100 thold), f_keep = 1.000
2026-05-15 19:02:31.932 | reasoning-budget: activated, budget=2147483647 tokens
2026-05-15 19:02:31.932 | slot launch_slot_: id  1 | task -1 | sampler chain: logits -> penalties -> ?dry -> ?top-n-sigma -> top-k -> ?typical -> ?top-p -> min-p -> ?xtc -> ?temp-ext -> dist 
2026-05-15 19:02:31.932 | slot launch_slot_: id  1 | task 15545 | processing task, is_child = 0
2026-05-15 19:02:31.932 | slot update_slots: id  1 | task 15545 | new prompt, n_ctx_slot = 131072, n_keep = 0, task.n_tokens = 76975
2026-05-15 19:02:31.932 | slot update_slots: id  1 | task 15545 | n_tokens = 76957, memory_seq_rm [76957, end)
2026-05-15 19:02:31.933 | slot update_slots: id  1 | task 15545 | prompt processing progress, n_tokens = 76971, batch.n_tokens = 14, progress = 0.999948
2026-05-15 19:02:32.267 | slot create_check: id  1 | task 15545 | created context checkpoint 28 of 32 (pos_min = 76956, pos_max = 76956, n_tokens = 76957, size = 310.795 MiB)
2026-05-15 19:02:32.314 | slot update_slots: id  1 | task 15545 | n_tokens = 76971, memory_seq_rm [76971, end)
2026-05-15 19:02:32.323 | slot init_sampler: id  1 | task 15545 | init sampler, took 9.78 ms, tokens: text = 76975, total = 76975
2026-05-15 19:02:32.323 | slot update_slots: id  1 | task 15545 | prompt processing done, n_tokens = 76975, batch.n_tokens = 4
2026-05-15 19:02:32.364 | srv  log_server_r: done request: POST /v1/chat/completions 172.18.0.1 200
2026-05-15 19:02:32.946 | reasoning-budget: deactivated (natural end)
2026-05-15 19:02:37.155 | slot print_timing: id  1 | task 15545 | 
2026-05-15 19:02:37.155 | prompt eval time =     430.94 ms /    18 tokens (   23.94 ms per token,    41.77 tokens per second)
2026-05-15 19:02:37.155 |        eval time =    4791.87 ms /   341 tokens (   14.05 ms per token,    71.16 tokens per second)
2026-05-15 19:02:37.155 |       total time =    5222.80 ms /   359 tokens
2026-05-15 19:02:37.155 | draft acceptance rate = 0.99541 (  217 accepted /   218 generated)
2026-05-15 19:02:37.155 | statistics mtp: #calls(b,g,a) = 119 14093 11082, #gen drafts = 11082, #acc drafts = 11082, #gen tokens = 19591, #acc tokens = 19291, dur(b,g,a) = 0.160, 56951.079, 4.645 ms
2026-05-15 19:02:37.157 | slot      release: id  1 | task 15545 | stop processing: n_tokens = 77315, truncated = 0
2026-05-15 19:02:37.157 | srv  update_slots: all slots are idle
2026-05-15 19:02:37.431 | srv  params_from_: Chat format: peg-native
2026-05-15 19:02:37.434 | slot get_availabl: id  1 | task -1 | selected slot by LCP similarity, sim_best = 0.996 (> 0.100 thold), f_keep = 0.997
2026-05-15 19:02:37.435 | reasoning-budget: activated, budget=2147483647 tokens
2026-05-15 19:02:37.435 | slot launch_slot_: id  1 | task -1 | sampler chain: logits -> penalties -> ?dry -> ?top-n-sigma -> top-k -> ?typical -> ?top-p -> min-p -> ?xtc -> ?temp-ext -> dist 
2026-05-15 19:02:37.435 | slot launch_slot_: id  1 | task 15675 | processing task, is_child = 0
2026-05-15 19:02:37.435 | slot update_slots: id  1 | task 15675 | new prompt, n_ctx_slot = 131072, n_keep = 0, task.n_tokens = 77335
2026-05-15 19:02:37.435 | slot update_slots: id  1 | task 15675 | n_past = 77054, slot.prompt.tokens.size() = 77315, seq_id = 1, pos_min = 77314, n_swa = 0
2026-05-15 19:02:37.435 | slot update_slots: id  1 | task 15675 | Checking checkpoint with [76956, 76956] against 77054...
2026-05-15 19:02:37.486 | slot update_slots: id  1 | task 15675 | restored context checkpoint (pos_min = 76956, pos_max = 76956, n_tokens = 76957, n_past = 76957, size = 310.795 MiB)
2026-05-15 19:02:37.486 | slot update_slots: id  1 | task 15675 | n_tokens = 76957, memory_seq_rm [76957, end)
2026-05-15 19:02:37.487 | slot update_slots: id  1 | task 15675 | prompt processing progress, n_tokens = 77331, batch.n_tokens = 374, progress = 0.999948
2026-05-15 19:02:37.775 | slot update_slots: id  1 | task 15675 | n_tokens = 77331, memory_seq_rm [77331, end)
2026-05-15 19:02:37.785 | slot init_sampler: id  1 | task 15675 | init sampler, took 9.75 ms, tokens: text = 77335, total = 77335
2026-05-15 19:02:37.785 | slot update_slots: id  1 | task 15675 | prompt processing done, n_tokens = 77335, batch.n_tokens = 4
2026-05-15 19:02:38.126 | slot create_check: id  1 | task 15675 | created context checkpoint 29 of 32 (pos_min = 77330, pos_max = 77330, n_tokens = 77331, size = 311.578 MiB)
2026-05-15 19:02:38.167 | srv  log_server_r: done request: POST /v1/chat/completions 172.18.0.1 200
2026-05-15 19:02:43.068 | reasoning-budget: deactivated (natural end)
2026-05-15 19:02:44.980 | slot print_timing: id  1 | task 15675 | 
2026-05-15 19:02:44.980 | prompt eval time =     731.41 ms /   378 tokens (    1.93 ms per token,   516.81 tokens per second)
2026-05-15 19:02:44.980 |        eval time =    6812.77 ms /   366 tokens (   18.61 ms per token,    53.72 tokens per second)
2026-05-15 19:02:44.980 |       total time =    7544.18 ms /   744 tokens
2026-05-15 19:02:44.980 | draft acceptance rate = 0.99448 (  180 accepted /   181 generated)
2026-05-15 19:02:44.980 | statistics mtp: #calls(b,g,a) = 120 14278 11190, #gen drafts = 11190, #acc drafts = 11190, #gen tokens = 19772, #acc tokens = 19471, dur(b,g,a) = 0.162, 57612.598, 4.673 ms
2026-05-15 19:02:44.981 | slot      release: id  1 | task 15675 | stop processing: n_tokens = 77700, truncated = 0
2026-05-15 19:02:44.981 | srv  update_slots: all slots are idle
2026-05-15 19:02:45.277 | srv  params_from_: Chat format: peg-native
2026-05-15 19:02:45.280 | slot get_availabl: id  1 | task -1 | selected slot by LCP similarity, sim_best = 1.000 (> 0.100 thold), f_keep = 1.000
2026-05-15 19:02:45.281 | reasoning-budget: activated, budget=2147483647 tokens
2026-05-15 19:02:45.281 | slot launch_slot_: id  1 | task -1 | sampler chain: logits -> penalties -> ?dry -> ?top-n-sigma -> top-k -> ?typical -> ?top-p -> min-p -> ?xtc -> ?temp-ext -> dist 
2026-05-15 19:02:45.281 | slot launch_slot_: id  1 | task 15870 | processing task, is_child = 0
2026-05-15 19:02:45.281 | slot update_slots: id  1 | task 15870 | new prompt, n_ctx_slot = 131072, n_keep = 0, task.n_tokens = 77719
2026-05-15 19:02:45.281 | slot update_slots: id  1 | task 15870 | n_tokens = 77700, memory_seq_rm [77700, end)
2026-05-15 19:02:45.281 | slot update_slots: id  1 | task 15870 | prompt processing progress, n_tokens = 77715, batch.n_tokens = 15, progress = 0.999949
2026-05-15 19:02:45.623 | slot create_check: id  1 | task 15870 | created context checkpoint 30 of 32 (pos_min = 77699, pos_max = 77699, n_tokens = 77700, size = 312.351 MiB)
2026-05-15 19:02:45.669 | slot update_slots: id  1 | task 15870 | n_tokens = 77715, memory_seq_rm [77715, end)
2026-05-15 19:02:45.679 | slot init_sampler: id  1 | task 15870 | init sampler, took 9.82 ms, tokens: text = 77719, total = 77719
2026-05-15 19:02:45.679 | slot update_slots: id  1 | task 15870 | prompt processing done, n_tokens = 77719, batch.n_tokens = 4
2026-05-15 19:02:45.720 | srv  log_server_r: done request: POST /v1/chat/completions 172.18.0.1 200
2026-05-15 19:02:45.955 | reasoning-budget: deactivated (natural end)
2026-05-15 19:02:48.190 | slot print_timing: id  1 | task 15870 | 
2026-05-15 19:02:48.190 | prompt eval time =     438.43 ms /    19 tokens (   23.08 ms per token,    43.34 tokens per second)
2026-05-15 19:02:48.190 |        eval time =    2449.65 ms /   189 tokens (   12.96 ms per token,    77.15 tokens per second)
2026-05-15 19:02:48.190 |       total time =    2888.08 ms /   208 tokens
2026-05-15 19:02:48.190 | draft acceptance rate = 1.00000 (  124 accepted /   124 generated)
2026-05-15 19:02:48.190 | statistics mtp: #calls(b,g,a) = 121 14342 11253, #gen drafts = 11253, #acc drafts = 11253, #gen tokens = 19896, #acc tokens = 19595, dur(b,g,a) = 0.163, 57910.027, 4.695 ms
2026-05-15 19:02:48.192 | slot      release: id  1 | task 15870 | stop processing: n_tokens = 77907, truncated = 0
2026-05-15 19:02:48.193 | srv  update_slots: all slots are idle
2026-05-15 19:02:48.454 | srv  params_from_: Chat format: peg-native
2026-05-15 19:02:48.457 | slot get_availabl: id  1 | task -1 | selected slot by LCP similarity, sim_best = 1.000 (> 0.100 thold), f_keep = 1.000
2026-05-15 19:02:48.458 | reasoning-budget: activated, budget=2147483647 tokens
2026-05-15 19:02:48.458 | slot launch_slot_: id  1 | task -1 | sampler chain: logits -> penalties -> ?dry -> ?top-n-sigma -> top-k -> ?typical -> ?top-p -> min-p -> ?xtc -> ?temp-ext -> dist 
2026-05-15 19:02:48.458 | slot launch_slot_: id  1 | task 15937 | processing task, is_child = 0
2026-05-15 19:02:48.458 | slot update_slots: id  1 | task 15937 | new prompt, n_ctx_slot = 131072, n_keep = 0, task.n_tokens = 77925
2026-05-15 19:02:48.458 | slot update_slots: id  1 | task 15937 | n_tokens = 77907, memory_seq_rm [77907, end)
2026-05-15 19:02:48.458 | slot update_slots: id  1 | task 15937 | prompt processing progress, n_tokens = 77921, batch.n_tokens = 14, progress = 0.999949
2026-05-15 19:02:48.798 | slot create_check: id  1 | task 15937 | created context checkpoint 31 of 32 (pos_min = 77906, pos_max = 77906, n_tokens = 77907, size = 312.784 MiB)
2026-05-15 19:02:48.845 | slot update_slots: id  1 | task 15937 | n_tokens = 77921, memory_seq_rm [77921, end)
2026-05-15 19:02:48.855 | slot init_sampler: id  1 | task 15937 | init sampler, took 9.85 ms, tokens: text = 77925, total = 77925
2026-05-15 19:02:48.855 | slot update_slots: id  1 | task 15937 | prompt processing done, n_tokens = 77925, batch.n_tokens = 4
2026-05-15 19:02:48.897 | srv  log_server_r: done request: POST /v1/chat/completions 172.18.0.1 200
2026-05-15 19:02:49.144 | reasoning-budget: deactivated (natural end)
2026-05-15 19:02:50.263 | slot print_timing: id  1 | task 15937 | 
2026-05-15 19:02:50.263 | prompt eval time =     438.07 ms /    18 tokens (   24.34 ms per token,    41.09 tokens per second)
2026-05-15 19:02:50.263 |        eval time =    1366.09 ms /    90 tokens (   15.18 ms per token,    65.88 tokens per second)
2026-05-15 19:02:50.263 |       total time =    1804.16 ms /   108 tokens
2026-05-15 19:02:50.263 | draft acceptance rate = 1.00000 (   56 accepted /    56 generated)
2026-05-15 19:02:50.263 | statistics mtp: #calls(b,g,a) = 122 14375 11283, #gen drafts = 11283, #acc drafts = 11283, #gen tokens = 19952, #acc tokens = 19651, dur(b,g,a) = 0.165, 58058.353, 4.709 ms
2026-05-15 19:02:50.265 | slot      release: id  1 | task 15937 | stop processing: n_tokens = 78014, truncated = 0
2026-05-15 19:02:50.265 | srv  update_slots: all slots are idle
2026-05-15 19:02:50.572 | srv  params_from_: Chat format: peg-native
2026-05-15 19:02:50.575 | slot get_availabl: id  1 | task -1 | selected slot by LCP similarity, sim_best = 0.991 (> 0.100 thold), f_keep = 1.000
2026-05-15 19:02:50.576 | reasoning-budget: activated, budget=2147483647 tokens
2026-05-15 19:02:50.576 | slot launch_slot_: id  1 | task -1 | sampler chain: logits -> penalties -> ?dry -> ?top-n-sigma -> top-k -> ?typical -> ?top-p -> min-p -> ?xtc -> ?temp-ext -> dist 
2026-05-15 19:02:50.576 | slot launch_slot_: id  1 | task 15974 | processing task, is_child = 0
2026-05-15 19:02:50.576 | slot update_slots: id  1 | task 15974 | new prompt, n_ctx_slot = 131072, n_keep = 0, task.n_tokens = 78710
2026-05-15 19:02:50.576 | slot update_slots: id  1 | task 15974 | n_tokens = 78014, memory_seq_rm [78014, end)
2026-05-15 19:02:50.576 | slot update_slots: id  1 | task 15974 | prompt processing progress, n_tokens = 78194, batch.n_tokens = 180, progress = 0.993444
2026-05-15 19:02:50.737 | slot update_slots: id  1 | task 15974 | n_tokens = 78194, memory_seq_rm [78194, end)
2026-05-15 19:02:50.737 | slot update_slots: id  1 | task 15974 | prompt processing progress, n_tokens = 78706, batch.n_tokens = 512, progress = 0.999949
2026-05-15 19:02:51.082 | slot create_check: id  1 | task 15974 | created context checkpoint 32 of 32 (pos_min = 78193, pos_max = 78193, n_tokens = 78194, size = 313.385 MiB)
2026-05-15 19:02:51.472 | slot update_slots: id  1 | task 15974 | n_tokens = 78706, memory_seq_rm [78706, end)
2026-05-15 19:02:51.482 | slot init_sampler: id  1 | task 15974 | init sampler, took 10.03 ms, tokens: text = 78710, total = 78710
2026-05-15 19:02:51.482 | slot update_slots: id  1 | task 15974 | prompt processing done, n_tokens = 78710, batch.n_tokens = 4
2026-05-15 19:02:51.483 | slot create_check: id  1 | task 15974 | erasing old context checkpoint (pos_min = 8191, pos_max = 8191, n_tokens = 8192, size = 166.782 MiB)
2026-05-15 19:02:51.786 | slot create_check: id  1 | task 15974 | created context checkpoint 32 of 32 (pos_min = 78705, pos_max = 78705, n_tokens = 78706, size = 314.458 MiB)
2026-05-15 19:02:51.828 | srv  log_server_r: done request: POST /v1/chat/completions 172.18.0.1 200
2026-05-15 19:02:52.426 | reasoning-budget: deactivated (natural end)
2026-05-15 19:02:54.059 | slot print_timing: id  1 | task 15974 | 
2026-05-15 19:02:54.060 | prompt eval time =    1251.12 ms /   696 tokens (    1.80 ms per token,   556.30 tokens per second)
2026-05-15 19:02:54.060 |        eval time =    2231.60 ms /   138 tokens (   16.17 ms per token,    61.84 tokens per second)
2026-05-15 19:02:54.060 |       total time =    3482.72 ms /   834 tokens
2026-05-15 19:02:54.060 | draft acceptance rate = 1.00000 (   80 accepted /    80 generated)
2026-05-15 19:02:54.060 | statistics mtp: #calls(b,g,a) = 123 14432 11327, #gen drafts = 11327, #acc drafts = 11327, #gen tokens = 20032, #acc tokens = 19731, dur(b,g,a) = 0.166, 58287.937, 4.728 ms
2026-05-15 19:02:54.061 | slot      release: id  1 | task 15974 | stop processing: n_tokens = 78847, truncated = 0
2026-05-15 19:02:54.061 | srv  update_slots: all slots are idle
2026-05-15 19:02:55.565 | srv  params_from_: Chat format: peg-native
2026-05-15 19:02:55.568 | slot get_availabl: id  1 | task -1 | selected slot by LCP similarity, sim_best = 0.998 (> 0.100 thold), f_keep = 1.000
2026-05-15 19:02:55.569 | reasoning-budget: activated, budget=2147483647 tokens
2026-05-15 19:02:55.569 | slot launch_slot_: id  1 | task -1 | sampler chain: logits -> penalties -> ?dry -> ?top-n-sigma -> top-k -> ?typical -> ?top-p -> min-p -> ?xtc -> ?temp-ext -> dist 
2026-05-15 19:02:55.569 | slot launch_slot_: id  1 | task 16037 | processing task, is_child = 0
2026-05-15 19:02:55.569 | slot update_slots: id  1 | task 16037 | new prompt, n_ctx_slot = 131072, n_keep = 0, task.n_tokens = 79007
2026-05-15 19:02:55.569 | slot update_slots: id  1 | task 16037 | n_tokens = 78847, memory_seq_rm [78847, end)
2026-05-15 19:02:55.569 | slot update_slots: id  1 | task 16037 | prompt processing progress, n_tokens = 79003, batch.n_tokens = 156, progress = 0.999949
2026-05-15 19:02:55.569 | slot create_check: id  1 | task 16037 | erasing old context checkpoint (pos_min = 16383, pos_max = 16383, n_tokens = 16384, size = 183.939 MiB)
2026-05-15 19:02:55.848 | slot create_check: id  1 | task 16037 | created context checkpoint 32 of 32 (pos_min = 78846, pos_max = 78846, n_tokens = 78847, size = 314.753 MiB)
2026-05-15 19:02:55.973 | slot update_slots: id  1 | task 16037 | n_tokens = 79003, memory_seq_rm [79003, end)
2026-05-15 19:02:55.983 | slot init_sampler: id  1 | task 16037 | init sampler, took 9.97 ms, tokens: text = 79007, total = 79007
2026-05-15 19:02:55.983 | slot update_slots: id  1 | task 16037 | prompt processing done, n_tokens = 79007, batch.n_tokens = 4
2026-05-15 19:02:55.983 | slot create_check: id  1 | task 16037 | erasing old context checkpoint (pos_min = 20397, pos_max = 20397, n_tokens = 20398, size = 192.345 MiB)
2026-05-15 19:02:56.286 | slot create_check: id  1 | task 16037 | created context checkpoint 32 of 32 (pos_min = 79002, pos_max = 79002, n_tokens = 79003, size = 315.080 MiB)
2026-05-15 19:02:56.330 | srv  log_server_r: done request: POST /v1/chat/completions 172.18.0.1 200
2026-05-15 19:02:56.892 | reasoning-budget: deactivated (natural end)
2026-05-15 19:02:58.233 | slot print_timing: id  1 | task 16037 | 
2026-05-15 19:02:58.233 | prompt eval time =     760.13 ms /   160 tokens (    4.75 ms per token,   210.49 tokens per second)
2026-05-15 19:02:58.233 |        eval time =    1903.92 ms /   115 tokens (   16.56 ms per token,    60.40 tokens per second)
2026-05-15 19:02:58.233 |       total time =    2664.05 ms /   275 tokens
2026-05-15 19:02:58.233 | draft acceptance rate = 0.97183 (   69 accepted /    71 generated)
2026-05-15 19:02:58.233 | statistics mtp: #calls(b,g,a) = 124 14477 11366, #gen drafts = 11366, #acc drafts = 11366, #gen tokens = 20103, #acc tokens = 19800, dur(b,g,a) = 0.168, 58479.409, 4.747 ms
2026-05-15 19:02:58.235 | slot      release: id  1 | task 16037 | stop processing: n_tokens = 79121, truncated = 0
2026-05-15 19:02:58.235 | srv  update_slots: all slots are idle
2026-05-15 19:02:58.693 | srv  params_from_: Chat format: peg-native
2026-05-15 19:02:58.695 | slot get_availabl: id  1 | task -1 | selected slot by LCP similarity, sim_best = 0.999 (> 0.100 thold), f_keep = 1.000
2026-05-15 19:02:58.697 | reasoning-budget: activated, budget=2147483647 tokens
2026-05-15 19:02:58.697 | slot launch_slot_: id  1 | task -1 | sampler chain: logits -> penalties -> ?dry -> ?top-n-sigma -> top-k -> ?typical -> ?top-p -> min-p -> ?xtc -> ?temp-ext -> dist 
2026-05-15 19:02:58.697 | slot launch_slot_: id  1 | task 16089 | processing task, is_child = 0
2026-05-15 19:02:58.697 | slot update_slots: id  1 | task 16089 | new prompt, n_ctx_slot = 131072, n_keep = 0, task.n_tokens = 79238
2026-05-15 19:02:58.697 | slot update_slots: id  1 | task 16089 | n_tokens = 79121, memory_seq_rm [79121, end)
2026-05-15 19:02:58.697 | slot update_slots: id  1 | task 16089 | prompt processing progress, n_tokens = 79234, batch.n_tokens = 113, progress = 0.999950
2026-05-15 19:02:58.697 | slot create_check: id  1 | task 16089 | erasing old context checkpoint (pos_min = 23206, pos_max = 23206, n_tokens = 23207, size = 198.228 MiB)
2026-05-15 19:02:58.977 | slot create_check: id  1 | task 16089 | created context checkpoint 32 of 32 (pos_min = 79120, pos_max = 79120, n_tokens = 79121, size = 315.327 MiB)
2026-05-15 19:02:59.071 | slot update_slots: id  1 | task 16089 | n_tokens = 79234, memory_seq_rm [79234, end)
2026-05-15 19:02:59.081 | slot init_sampler: id  1 | task 16089 | init sampler, took 9.95 ms, tokens: text = 79238, total = 79238
2026-05-15 19:02:59.081 | slot update_slots: id  1 | task 16089 | prompt processing done, n_tokens = 79238, batch.n_tokens = 4
2026-05-15 19:02:59.081 | slot create_check: id  1 | task 16089 | erasing old context checkpoint (pos_min = 31398, pos_max = 31398, n_tokens = 31399, size = 215.384 MiB)
2026-05-15 19:02:59.361 | slot create_check: id  1 | task 16089 | created context checkpoint 32 of 32 (pos_min = 79233, pos_max = 79233, n_tokens = 79234, size = 315.563 MiB)
2026-05-15 19:02:59.401 | srv  log_server_r: done request: POST /v1/chat/completions 172.18.0.1 200
2026-05-15 19:03:07.510 | reasoning-budget: deactivated (natural end)
2026-05-15 19:03:11.379 | slot print_timing: id  1 | task 16089 | 
2026-05-15 19:03:11.379 | prompt eval time =     704.04 ms /   117 tokens (    6.02 ms per token,   166.18 tokens per second)
2026-05-15 19:03:11.379 |        eval time =   11977.73 ms /   566 tokens (   21.16 ms per token,    47.25 tokens per second)
2026-05-15 19:03:11.379 |       total time =   12681.77 ms /   683 tokens
2026-05-15 19:03:11.379 | draft acceptance rate = 0.97070 (  265 accepted /   273 generated)
2026-05-15 19:03:11.379 | statistics mtp: #calls(b,g,a) = 125 14777 11537, #gen drafts = 11537, #acc drafts = 11537, #gen tokens = 20376, #acc tokens = 20065, dur(b,g,a) = 0.168, 59549.929, 4.824 ms
2026-05-15 19:03:11.381 | slot      release: id  1 | task 16089 | stop processing: n_tokens = 79803, truncated = 0
2026-05-15 19:03:11.381 | srv  update_slots: all slots are idle
2026-05-15 19:03:11.668 | srv  params_from_: Chat format: peg-native
2026-05-15 19:03:11.670 | slot get_availabl: id  1 | task -1 | selected slot by LCP similarity, sim_best = 1.000 (> 0.100 thold), f_keep = 1.000
2026-05-15 19:03:11.672 | reasoning-budget: activated, budget=2147483647 tokens
2026-05-15 19:03:11.672 | slot launch_slot_: id  1 | task -1 | sampler chain: logits -> penalties -> ?dry -> ?top-n-sigma -> top-k -> ?typical -> ?top-p -> min-p -> ?xtc -> ?temp-ext -> dist 
2026-05-15 19:03:11.672 | slot launch_slot_: id  1 | task 16424 | processing task, is_child = 0
2026-05-15 19:03:11.672 | slot update_slots: id  1 | task 16424 | new prompt, n_ctx_slot = 131072, n_keep = 0, task.n_tokens = 79820
2026-05-15 19:03:11.672 | slot update_slots: id  1 | task 16424 | n_tokens = 79803, memory_seq_rm [79803, end)
2026-05-15 19:03:11.672 | slot update_slots: id  1 | task 16424 | prompt processing progress, n_tokens = 79816, batch.n_tokens = 13, progress = 0.999950
2026-05-15 19:03:11.672 | slot create_check: id  1 | task 16424 | erasing old context checkpoint (pos_min = 39590, pos_max = 39590, n_tokens = 39591, size = 232.540 MiB)
2026-05-15 19:03:11.940 | slot create_check: id  1 | task 16424 | created context checkpoint 32 of 32 (pos_min = 79802, pos_max = 79802, n_tokens = 79803, size = 316.755 MiB)
2026-05-15 19:03:11.987 | slot update_slots: id  1 | task 16424 | n_tokens = 79816, memory_seq_rm [79816, end)
2026-05-15 19:03:11.997 | slot init_sampler: id  1 | task 16424 | init sampler, took 10.09 ms, tokens: text = 79820, total = 79820
2026-05-15 19:03:11.997 | slot update_slots: id  1 | task 16424 | prompt processing done, n_tokens = 79820, batch.n_tokens = 4
2026-05-15 19:03:12.039 | srv  log_server_r: done request: POST /v1/chat/completions 172.18.0.1 200
2026-05-15 19:03:12.693 | reasoning-budget: deactivated (natural end)
2026-05-15 19:03:13.586 | slot print_timing: id  1 | task 16424 | 
2026-05-15 19:03:13.586 | prompt eval time =     366.34 ms /    17 tokens (   21.55 ms per token,    46.40 tokens per second)
2026-05-15 19:03:13.586 |        eval time =    1547.93 ms /   105 tokens (   14.74 ms per token,    67.83 tokens per second)
2026-05-15 19:03:13.586 |       total time =    1914.27 ms /   122 tokens
2026-05-15 19:03:13.586 | draft acceptance rate = 1.00000 (   66 accepted /    66 generated)
2026-05-15 19:03:13.586 | statistics mtp: #calls(b,g,a) = 126 14815 11573, #gen drafts = 11573, #acc drafts = 11573, #gen tokens = 20442, #acc tokens = 20131, dur(b,g,a) = 0.169, 59720.032, 4.839 ms
2026-05-15 19:03:13.589 | slot      release: id  1 | task 16424 | stop processing: n_tokens = 79924, truncated = 0
2026-05-15 19:03:13.589 | srv  update_slots: all slots are idle
2026-05-15 19:03:13.875 | srv  params_from_: Chat format: peg-native
2026-05-15 19:03:13.878 | slot get_availabl: id  1 | task -1 | selected slot by LCP similarity, sim_best = 1.000 (> 0.100 thold), f_keep = 1.000
2026-05-15 19:03:13.879 | reasoning-budget: activated, budget=2147483647 tokens
2026-05-15 19:03:13.879 | slot launch_slot_: id  1 | task -1 | sampler chain: logits -> penalties -> ?dry -> ?top-n-sigma -> top-k -> ?typical -> ?top-p -> min-p -> ?xtc -> ?temp-ext -> dist 
2026-05-15 19:03:13.879 | slot launch_slot_: id  1 | task 16467 | processing task, is_child = 0
2026-05-15 19:03:13.879 | slot update_slots: id  1 | task 16467 | new prompt, n_ctx_slot = 131072, n_keep = 0, task.n_tokens = 79941
2026-05-15 19:03:13.879 | slot update_slots: id  1 | task 16467 | n_tokens = 79924, memory_seq_rm [79924, end)
2026-05-15 19:03:13.879 | slot update_slots: id  1 | task 16467 | prompt processing progress, n_tokens = 79937, batch.n_tokens = 13, progress = 0.999950
2026-05-15 19:03:13.879 | slot create_check: id  1 | task 16467 | erasing old context checkpoint (pos_min = 47782, pos_max = 47782, n_tokens = 47783, size = 249.697 MiB)
2026-05-15 19:03:14.146 | slot create_check: id  1 | task 16467 | created context checkpoint 32 of 32 (pos_min = 79923, pos_max = 79923, n_tokens = 79924, size = 317.009 MiB)
2026-05-15 19:03:14.191 | slot update_slots: id  1 | task 16467 | n_tokens = 79937, memory_seq_rm [79937, end)
2026-05-15 19:03:14.201 | slot init_sampler: id  1 | task 16467 | init sampler, took 9.95 ms, tokens: text = 79941, total = 79941
2026-05-15 19:03:14.201 | slot update_slots: id  1 | task 16467 | prompt processing done, n_tokens = 79941, batch.n_tokens = 4
2026-05-15 19:03:14.242 | srv  log_server_r: done request: POST /v1/chat/completions 172.18.0.1 200
2026-05-15 19:03:14.781 | reasoning-budget: deactivated (natural end)
2026-05-15 19:03:15.693 | slot print_timing: id  1 | task 16467 | 
2026-05-15 19:03:15.693 | prompt eval time =     362.88 ms /    17 tokens (   21.35 ms per token,    46.85 tokens per second)
2026-05-15 19:03:15.693 |        eval time =    1450.73 ms /    95 tokens (   15.27 ms per token,    65.48 tokens per second)
2026-05-15 19:03:15.693 |       total time =    1813.61 ms /   112 tokens
2026-05-15 19:03:15.693 | draft acceptance rate = 1.00000 (   54 accepted /    54 generated)
2026-05-15 19:03:15.693 | statistics mtp: #calls(b,g,a) = 127 14855 11602, #gen drafts = 11602, #acc drafts = 11602, #gen tokens = 20496, #acc tokens = 20185, dur(b,g,a) = 0.171, 59877.750, 4.850 ms
2026-05-15 19:03:15.695 | slot      release: id  1 | task 16467 | stop processing: n_tokens = 80035, truncated = 0
2026-05-15 19:03:15.695 | srv  update_slots: all slots are idle
2026-05-15 19:03:16.025 | srv  params_from_: Chat format: peg-native
2026-05-15 19:03:16.027 | slot get_availabl: id  1 | task -1 | selected slot by LCP similarity, sim_best = 1.000 (> 0.100 thold), f_keep = 1.000
2026-05-15 19:03:16.029 | reasoning-budget: activated, budget=2147483647 tokens
2026-05-15 19:03:16.029 | slot launch_slot_: id  1 | task -1 | sampler chain: logits -> penalties -> ?dry -> ?top-n-sigma -> top-k -> ?typical -> ?top-p -> min-p -> ?xtc -> ?temp-ext -> dist 
2026-05-15 19:03:16.029 | slot launch_slot_: id  1 | task 16510 | processing task, is_child = 0
2026-05-15 19:03:16.029 | slot update_slots: id  1 | task 16510 | new prompt, n_ctx_slot = 131072, n_keep = 0, task.n_tokens = 80054
2026-05-15 19:03:16.029 | slot update_slots: id  1 | task 16510 | n_tokens = 80035, memory_seq_rm [80035, end)
2026-05-15 19:03:16.029 | slot update_slots: id  1 | task 16510 | prompt processing progress, n_tokens = 80050, batch.n_tokens = 15, progress = 0.999950
2026-05-15 19:03:16.029 | slot create_check: id  1 | task 16510 | erasing old context checkpoint (pos_min = 55182, pos_max = 55182, n_tokens = 55183, size = 265.194 MiB)
2026-05-15 19:03:16.296 | slot create_check: id  1 | task 16510 | created context checkpoint 32 of 32 (pos_min = 80034, pos_max = 80034, n_tokens = 80035, size = 317.241 MiB)
2026-05-15 19:03:16.340 | slot update_slots: id  1 | task 16510 | n_tokens = 80050, memory_seq_rm [80050, end)
2026-05-15 19:03:16.350 | slot init_sampler: id  1 | task 16510 | init sampler, took 10.16 ms, tokens: text = 80054, total = 80054
2026-05-15 19:03:16.350 | slot update_slots: id  1 | task 16510 | prompt processing done, n_tokens = 80054, batch.n_tokens = 4
2026-05-15 19:03:16.392 | srv  log_server_r: done request: POST /v1/chat/completions 172.18.0.1 200
2026-05-15 19:03:17.012 | reasoning-budget: deactivated (natural end)
2026-05-15 19:03:17.979 | slot print_timing: id  1 | task 16510 | 
2026-05-15 19:03:17.979 | prompt eval time =     362.27 ms /    19 tokens (   19.07 ms per token,    52.45 tokens per second)
2026-05-15 19:03:17.979 |        eval time =    1588.00 ms /   100 tokens (   15.88 ms per token,    62.97 tokens per second)
2026-05-15 19:03:17.979 |       total time =    1950.27 ms /   119 tokens
2026-05-15 19:03:17.979 | draft acceptance rate = 1.00000 (   59 accepted /    59 generated)
2026-05-15 19:03:17.979 | statistics mtp: #calls(b,g,a) = 128 14895 11634, #gen drafts = 11634, #acc drafts = 11634, #gen tokens = 20555, #acc tokens = 20244, dur(b,g,a) = 0.172, 60043.541, 4.865 ms
2026-05-15 19:03:17.981 | slot      release: id  1 | task 16510 | stop processing: n_tokens = 80153, truncated = 0
2026-05-15 19:03:17.983 | srv  update_slots: all slots are idle
2026-05-15 19:03:18.295 | srv  params_from_: Chat format: peg-native
2026-05-15 19:03:18.298 | slot get_availabl: id  1 | task -1 | selected slot by LCP similarity, sim_best = 0.999 (> 0.100 thold), f_keep = 1.000
2026-05-15 19:03:18.299 | reasoning-budget: activated, budget=2147483647 tokens
2026-05-15 19:03:18.299 | slot launch_slot_: id  1 | task -1 | sampler chain: logits -> penalties -> ?dry -> ?top-n-sigma -> top-k -> ?typical -> ?top-p -> min-p -> ?xtc -> ?temp-ext -> dist 
2026-05-15 19:03:18.299 | slot launch_slot_: id  1 | task 16555 | processing task, is_child = 0
2026-05-15 19:03:18.299 | slot update_slots: id  1 | task 16555 | new prompt, n_ctx_slot = 131072, n_keep = 0, task.n_tokens = 80198
2026-05-15 19:03:18.299 | slot update_slots: id  1 | task 16555 | n_tokens = 80153, memory_seq_rm [80153, end)
2026-05-15 19:03:18.300 | slot update_slots: id  1 | task 16555 | prompt processing progress, n_tokens = 80194, batch.n_tokens = 41, progress = 0.999950
2026-05-15 19:03:18.300 | slot create_check: id  1 | task 16555 | erasing old context checkpoint (pos_min = 55694, pos_max = 55694, n_tokens = 55695, size = 266.266 MiB)
2026-05-15 19:03:18.546 | slot create_check: id  1 | task 16555 | created context checkpoint 32 of 32 (pos_min = 80152, pos_max = 80152, n_tokens = 80153, size = 317.488 MiB)
2026-05-15 19:03:18.603 | slot update_slots: id  1 | task 16555 | n_tokens = 80194, memory_seq_rm [80194, end)
2026-05-15 19:03:18.613 | slot init_sampler: id  1 | task 16555 | init sampler, took 10.30 ms, tokens: text = 80198, total = 80198
2026-05-15 19:03:18.613 | slot update_slots: id  1 | task 16555 | prompt processing done, n_tokens = 80198, batch.n_tokens = 4
2026-05-15 19:03:18.656 | srv  log_server_r: done request: POST /v1/chat/completions 172.18.0.1 200
2026-05-15 19:03:19.471 | reasoning-budget: deactivated (natural end)
2026-05-15 19:03:20.861 | slot print_timing: id  1 | task 16555 | 
2026-05-15 19:03:20.861 | prompt eval time =     355.70 ms /    45 tokens (    7.90 ms per token,   126.51 tokens per second)
2026-05-15 19:03:20.861 |        eval time =    2206.16 ms /   121 tokens (   18.23 ms per token,    54.85 tokens per second)
2026-05-15 19:03:20.861 |       total time =    2561.86 ms /   166 tokens
2026-05-15 19:03:20.861 | draft acceptance rate = 0.98571 (   69 accepted /    70 generated)
2026-05-15 19:03:20.861 | statistics mtp: #calls(b,g,a) = 129 14946 11674, #gen drafts = 11674, #acc drafts = 11674, #gen tokens = 20625, #acc tokens = 20313, dur(b,g,a) = 0.174, 60255.186, 4.886 ms
2026-05-15 19:03:20.863 | slot      release: id  1 | task 16555 | stop processing: n_tokens = 80318, truncated = 0
2026-05-15 19:03:20.863 | srv  update_slots: all slots are idle
2026-05-15 19:03:21.203 | srv  params_from_: Chat format: peg-native
2026-05-15 19:03:21.206 | slot get_availabl: id  1 | task -1 | selected slot by LCP similarity, sim_best = 0.989 (> 0.100 thold), f_keep = 1.000
2026-05-15 19:03:21.207 | reasoning-budget: activated, budget=2147483647 tokens
2026-05-15 19:03:21.207 | slot launch_slot_: id  1 | task -1 | sampler chain: logits -> penalties -> ?dry -> ?top-n-sigma -> top-k -> ?typical -> ?top-p -> min-p -> ?xtc -> ?temp-ext -> dist 
2026-05-15 19:03:21.207 | slot launch_slot_: id  1 | task 16614 | processing task, is_child = 0
2026-05-15 19:03:21.207 | slot update_slots: id  1 | task 16614 | new prompt, n_ctx_slot = 131072, n_keep = 0, task.n_tokens = 81191
2026-05-15 19:03:21.207 | slot update_slots: id  1 | task 16614 | n_tokens = 80318, memory_seq_rm [80318, end)
2026-05-15 19:03:21.207 | slot update_slots: id  1 | task 16614 | prompt processing progress, n_tokens = 80675, batch.n_tokens = 357, progress = 0.993645
2026-05-15 19:03:21.438 | slot update_slots: id  1 | task 16614 | n_tokens = 80675, memory_seq_rm [80675, end)
2026-05-15 19:03:21.438 | slot update_slots: id  1 | task 16614 | prompt processing progress, n_tokens = 81187, batch.n_tokens = 512, progress = 0.999951
2026-05-15 19:03:21.438 | slot create_check: id  1 | task 16614 | erasing old context checkpoint (pos_min = 56029, pos_max = 56029, n_tokens = 56030, size = 266.968 MiB)
2026-05-15 19:03:21.696 | slot create_check: id  1 | task 16614 | created context checkpoint 32 of 32 (pos_min = 80674, pos_max = 80674, n_tokens = 80675, size = 318.581 MiB)
2026-05-15 19:03:22.091 | slot update_slots: id  1 | task 16614 | n_tokens = 81187, memory_seq_rm [81187, end)
2026-05-15 19:03:22.101 | slot init_sampler: id  1 | task 16614 | init sampler, took 10.52 ms, tokens: text = 81191, total = 81191
2026-05-15 19:03:22.101 | slot update_slots: id  1 | task 16614 | prompt processing done, n_tokens = 81191, batch.n_tokens = 4
2026-05-15 19:03:22.101 | slot create_check: id  1 | task 16614 | erasing old context checkpoint (pos_min = 56467, pos_max = 56467, n_tokens = 56468, size = 267.885 MiB)
2026-05-15 19:03:22.363 | slot create_check: id  1 | task 16614 | created context checkpoint 32 of 32 (pos_min = 81186, pos_max = 81186, n_tokens = 81187, size = 319.654 MiB)
2026-05-15 19:03:22.404 | srv  log_server_r: done request: POST /v1/chat/completions 172.18.0.1 200
2026-05-15 19:03:25.817 | reasoning-budget: deactivated (natural end)
2026-05-15 19:03:26.826 | slot print_timing: id  1 | task 16614 | 
2026-05-15 19:03:26.827 | prompt eval time =    1196.88 ms /   873 tokens (    1.37 ms per token,   729.40 tokens per second)
2026-05-15 19:03:26.827 |        eval time =    4422.27 ms /   226 tokens (   19.57 ms per token,    51.11 tokens per second)
2026-05-15 19:03:26.827 |       total time =    5619.15 ms /  1099 tokens
2026-05-15 19:03:26.827 | draft acceptance rate = 0.98347 (  119 accepted /   121 generated)
2026-05-15 19:03:26.827 | statistics mtp: #calls(b,g,a) = 130 15052 11747, #gen drafts = 11747, #acc drafts = 11747, #gen tokens = 20746, #acc tokens = 20432, dur(b,g,a) = 0.176, 60669.893, 4.916 ms
2026-05-15 19:03:26.829 | slot      release: id  1 | task 16614 | stop processing: n_tokens = 81416, truncated = 0
2026-05-15 19:03:26.829 | srv  update_slots: all slots are idle
2026-05-15 19:03:27.129 | srv  params_from_: Chat format: peg-native
2026-05-15 19:03:27.131 | slot get_availabl: id  1 | task -1 | selected slot by LCP similarity, sim_best = 1.000 (> 0.100 thold), f_keep = 1.000
2026-05-15 19:03:27.133 | reasoning-budget: activated, budget=2147483647 tokens
2026-05-15 19:03:27.133 | slot launch_slot_: id  1 | task -1 | sampler chain: logits -> penalties -> ?dry -> ?top-n-sigma -> top-k -> ?typical -> ?top-p -> min-p -> ?xtc -> ?temp-ext -> dist 
2026-05-15 19:03:27.133 | slot launch_slot_: id  1 | task 16733 | processing task, is_child = 0
2026-05-15 19:03:27.133 | slot update_slots: id  1 | task 16733 | new prompt, n_ctx_slot = 131072, n_keep = 0, task.n_tokens = 81433
2026-05-15 19:03:27.133 | slot update_slots: id  1 | task 16733 | n_tokens = 81416, memory_seq_rm [81416, end)
2026-05-15 19:03:27.133 | slot update_slots: id  1 | task 16733 | prompt processing progress, n_tokens = 81429, batch.n_tokens = 13, progress = 0.999951
2026-05-15 19:03:27.133 | slot create_check: id  1 | task 16733 | erasing old context checkpoint (pos_min = 57414, pos_max = 57414, n_tokens = 57415, size = 269.869 MiB)
2026-05-15 19:03:27.393 | slot create_check: id  1 | task 16733 | created context checkpoint 32 of 32 (pos_min = 81415, pos_max = 81415, n_tokens = 81416, size = 320.133 MiB)
2026-05-15 19:03:27.439 | slot update_slots: id  1 | task 16733 | n_tokens = 81429, memory_seq_rm [81429, end)
2026-05-15 19:03:27.449 | slot init_sampler: id  1 | task 16733 | init sampler, took 10.22 ms, tokens: text = 81433, total = 81433
2026-05-15 19:03:27.449 | slot update_slots: id  1 | task 16733 | prompt processing done, n_tokens = 81433, batch.n_tokens = 4
2026-05-15 19:03:27.490 | srv  log_server_r: done request: POST /v1/chat/completions 172.18.0.1 200
2026-05-15 19:03:28.264 | reasoning-budget: deactivated (natural end)
2026-05-15 19:03:29.029 | slot print_timing: id  1 | task 16733 | 
2026-05-15 19:03:29.029 | prompt eval time =     356.86 ms /    17 tokens (   20.99 ms per token,    47.64 tokens per second)
2026-05-15 19:03:29.029 |        eval time =    1539.18 ms /   101 tokens (   15.24 ms per token,    65.62 tokens per second)
2026-05-15 19:03:29.029 |       total time =    1896.03 ms /   118 tokens
2026-05-15 19:03:29.029 | draft acceptance rate = 1.00000 (   61 accepted /    61 generated)
2026-05-15 19:03:29.029 | statistics mtp: #calls(b,g,a) = 131 15091 11778, #gen drafts = 11778, #acc drafts = 11778, #gen tokens = 20807, #acc tokens = 20493, dur(b,g,a) = 0.178, 60833.919, 4.932 ms
2026-05-15 19:03:29.031 | slot      release: id  1 | task 16733 | stop processing: n_tokens = 81533, truncated = 0
2026-05-15 19:03:29.031 | srv  update_slots: all slots are idle
2026-05-15 19:03:29.341 | srv  params_from_: Chat format: peg-native
2026-05-15 19:03:29.344 | slot get_availabl: id  1 | task -1 | selected slot by LCP similarity, sim_best = 0.997 (> 0.100 thold), f_keep = 1.000
2026-05-15 19:03:29.345 | reasoning-budget: activated, budget=2147483647 tokens
2026-05-15 19:03:29.345 | slot launch_slot_: id  1 | task -1 | sampler chain: logits -> penalties -> ?dry -> ?top-n-sigma -> top-k -> ?typical -> ?top-p -> min-p -> ?xtc -> ?temp-ext -> dist 
2026-05-15 19:03:29.345 | slot launch_slot_: id  1 | task 16776 | processing task, is_child = 0
2026-05-15 19:03:29.345 | slot update_slots: id  1 | task 16776 | new prompt, n_ctx_slot = 131072, n_keep = 0, task.n_tokens = 81740
2026-05-15 19:03:29.345 | slot update_slots: id  1 | task 16776 | n_tokens = 81533, memory_seq_rm [81533, end)
2026-05-15 19:03:29.345 | slot update_slots: id  1 | task 16776 | prompt processing progress, n_tokens = 81736, batch.n_tokens = 203, progress = 0.999951
2026-05-15 19:03:29.345 | slot create_check: id  1 | task 16776 | erasing old context checkpoint (pos_min = 57926, pos_max = 57926, n_tokens = 57927, size = 270.941 MiB)
2026-05-15 19:03:29.606 | slot create_check: id  1 | task 16776 | created context checkpoint 32 of 32 (pos_min = 81532, pos_max = 81532, n_tokens = 81533, size = 320.378 MiB)
2026-05-15 19:03:29.788 | slot update_slots: id  1 | task 16776 | n_tokens = 81736, memory_seq_rm [81736, end)
2026-05-15 19:03:29.799 | slot init_sampler: id  1 | task 16776 | init sampler, took 10.60 ms, tokens: text = 81740, total = 81740
2026-05-15 19:03:29.799 | slot update_slots: id  1 | task 16776 | prompt processing done, n_tokens = 81740, batch.n_tokens = 4
2026-05-15 19:03:29.799 | slot create_check: id  1 | task 16776 | erasing old context checkpoint (pos_min = 59017, pos_max = 59017, n_tokens = 59018, size = 273.226 MiB)
2026-05-15 19:03:30.059 | slot create_check: id  1 | task 16776 | created context checkpoint 32 of 32 (pos_min = 81735, pos_max = 81735, n_tokens = 81736, size = 320.803 MiB)
2026-05-15 19:03:30.101 | srv  log_server_r: done request: POST /v1/chat/completions 172.18.0.1 200
2026-05-15 19:03:30.496 | reasoning-budget: deactivated (natural end)
2026-05-15 19:03:31.759 | slot print_timing: id  1 | task 16776 | 
2026-05-15 19:03:31.759 | prompt eval time =     755.25 ms /   207 tokens (    3.65 ms per token,   274.08 tokens per second)
2026-05-15 19:03:31.759 |        eval time =    1658.64 ms /   100 tokens (   16.59 ms per token,    60.29 tokens per second)
2026-05-15 19:03:31.759 |       total time =    2413.89 ms /   307 tokens
2026-05-15 19:03:31.759 | draft acceptance rate = 0.96721 (   59 accepted /    61 generated)
2026-05-15 19:03:31.759 | statistics mtp: #calls(b,g,a) = 132 15131 11810, #gen drafts = 11810, #acc drafts = 11810, #gen tokens = 20868, #acc tokens = 20552, dur(b,g,a) = 0.179, 60999.788, 4.946 ms
2026-05-15 19:03:31.762 | slot      release: id  1 | task 16776 | stop processing: n_tokens = 81839, truncated = 0
2026-05-15 19:03:31.762 | srv  update_slots: all slots are idle
2026-05-15 19:03:32.133 | srv  params_from_: Chat format: peg-native
2026-05-15 19:03:32.136 | slot get_availabl: id  1 | task -1 | selected slot by LCP similarity, sim_best = 0.988 (> 0.100 thold), f_keep = 1.000
2026-05-15 19:03:32.137 | reasoning-budget: activated, budget=2147483647 tokens
2026-05-15 19:03:32.137 | slot launch_slot_: id  1 | task -1 | sampler chain: logits -> penalties -> ?dry -> ?top-n-sigma -> top-k -> ?typical -> ?top-p -> min-p -> ?xtc -> ?temp-ext -> dist 
2026-05-15 19:03:32.137 | slot launch_slot_: id  1 | task 16821 | processing task, is_child = 0
2026-05-15 19:03:32.137 | slot update_slots: id  1 | task 16821 | new prompt, n_ctx_slot = 131072, n_keep = 0, task.n_tokens = 82863
2026-05-15 19:03:32.137 | slot update_slots: id  1 | task 16821 | n_tokens = 81839, memory_seq_rm [81839, end)
2026-05-15 19:03:32.138 | slot update_slots: id  1 | task 16821 | prompt processing progress, n_tokens = 82347, batch.n_tokens = 508, progress = 0.993773
2026-05-15 19:03:32.536 | slot update_slots: id  1 | task 16821 | n_tokens = 82347, memory_seq_rm [82347, end)
2026-05-15 19:03:32.536 | slot update_slots: id  1 | task 16821 | prompt processing progress, n_tokens = 82859, batch.n_tokens = 512, progress = 0.999952
2026-05-15 19:03:32.536 | slot create_check: id  1 | task 16821 | erasing old context checkpoint (pos_min = 59529, pos_max = 59529, n_tokens = 59530, size = 274.298 MiB)
2026-05-15 19:03:32.810 | slot create_check: id  1 | task 16821 | created context checkpoint 32 of 32 (pos_min = 82346, pos_max = 82346, n_tokens = 82347, size = 322.083 MiB)
2026-05-15 19:03:33.208 | slot update_slots: id  1 | task 16821 | n_tokens = 82859, memory_seq_rm [82859, end)
2026-05-15 19:03:33.218 | slot init_sampler: id  1 | task 16821 | init sampler, took 10.78 ms, tokens: text = 82863, total = 82863
2026-05-15 19:03:33.219 | slot update_slots: id  1 | task 16821 | prompt processing done, n_tokens = 82863, batch.n_tokens = 4
2026-05-15 19:03:33.219 | slot create_check: id  1 | task 16821 | erasing old context checkpoint (pos_min = 68099, pos_max = 68099, n_tokens = 68100, size = 292.246 MiB)
2026-05-15 19:03:33.477 | slot create_check: id  1 | task 16821 | created context checkpoint 32 of 32 (pos_min = 82858, pos_max = 82858, n_tokens = 82859, size = 323.155 MiB)
2026-05-15 19:03:33.520 | srv  log_server_r: done request: POST /v1/chat/completions 172.18.0.1 200
2026-05-15 19:03:35.922 | reasoning-budget: deactivated (natural end)
2026-05-15 19:03:36.444 | srv          stop: cancel task, id_task = 16821
2026-05-15 19:03:36.493 | slot      release: id  1 | task 16821 | stop processing: n_tokens = 83012, truncated = 0
2026-05-15 19:03:36.493 | srv  update_slots: all slots are idle
2026-05-15 19:04:40.652 | srv  params_from_: Chat format: peg-native
2026-05-15 19:04:40.655 | slot get_availabl: id  1 | task -1 | selected slot by LCP similarity, sim_best = 0.699 (> 0.100 thold), f_keep = 0.670
2026-05-15 19:04:40.656 | reasoning-budget: activated, budget=2147483647 tokens
2026-05-15 19:04:40.656 | slot launch_slot_: id  1 | task -1 | sampler chain: logits -> penalties -> ?dry -> ?top-n-sigma -> top-k -> ?typical -> ?top-p -> min-p -> ?xtc -> ?temp-ext -> dist 
2026-05-15 19:04:40.656 | slot launch_slot_: id  1 | task 16903 | processing task, is_child = 0
2026-05-15 19:04:40.656 | slot update_slots: id  1 | task 16903 | new prompt, n_ctx_slot = 131072, n_keep = 0, task.n_tokens = 79542
2026-05-15 19:04:40.656 | slot update_slots: id  1 | task 16903 | n_past = 55637, slot.prompt.tokens.size() = 83012, seq_id = 1, pos_min = 83011, n_swa = 0
2026-05-15 19:04:40.656 | slot update_slots: id  1 | task 16903 | Checking checkpoint with [82858, 82858] against 55637...
2026-05-15 19:04:40.656 | slot update_slots: id  1 | task 16903 | Checking checkpoint with [82346, 82346] against 55637...
2026-05-15 19:04:40.656 | slot update_slots: id  1 | task 16903 | Checking checkpoint with [81735, 81735] against 55637...
2026-05-15 19:04:40.656 | slot update_slots: id  1 | task 16903 | Checking checkpoint with [81532, 81532] against 55637...
2026-05-15 19:04:40.656 | slot update_slots: id  1 | task 16903 | Checking checkpoint with [81415, 81415] against 55637...
2026-05-15 19:04:40.656 | slot update_slots: id  1 | task 16903 | Checking checkpoint with [81186, 81186] against 55637...
2026-05-15 19:04:40.656 | slot update_slots: id  1 | task 16903 | Checking checkpoint with [80674, 80674] against 55637...
2026-05-15 19:04:40.656 | slot update_slots: id  1 | task 16903 | Checking checkpoint with [80152, 80152] against 55637...
2026-05-15 19:04:40.656 | slot update_slots: id  1 | task 16903 | Checking checkpoint with [80034, 80034] against 55637...
2026-05-15 19:04:40.656 | slot update_slots: id  1 | task 16903 | Checking checkpoint with [79923, 79923] against 55637...
2026-05-15 19:04:40.656 | slot update_slots: id  1 | task 16903 | Checking checkpoint with [79802, 79802] against 55637...
2026-05-15 19:04:40.656 | slot update_slots: id  1 | task 16903 | Checking checkpoint with [79233, 79233] against 55637...
2026-05-15 19:04:40.656 | slot update_slots: id  1 | task 16903 | Checking checkpoint with [79120, 79120] against 55637...
2026-05-15 19:04:40.656 | slot update_slots: id  1 | task 16903 | Checking checkpoint with [79002, 79002] against 55637...
2026-05-15 19:04:40.656 | slot update_slots: id  1 | task 16903 | Checking checkpoint with [78846, 78846] against 55637...
2026-05-15 19:04:40.656 | slot update_slots: id  1 | task 16903 | Checking checkpoint with [78705, 78705] against 55637...
2026-05-15 19:04:40.656 | slot update_slots: id  1 | task 16903 | Checking checkpoint with [78193, 78193] against 55637...
2026-05-15 19:04:40.656 | slot update_slots: id  1 | task 16903 | Checking checkpoint with [77906, 77906] against 55637...
2026-05-15 19:04:40.656 | slot update_slots: id  1 | task 16903 | Checking checkpoint with [77699, 77699] against 55637...
2026-05-15 19:04:40.656 | slot update_slots: id  1 | task 16903 | Checking checkpoint with [77330, 77330] against 55637...
2026-05-15 19:04:40.656 | slot update_slots: id  1 | task 16903 | Checking checkpoint with [76956, 76956] against 55637...
2026-05-15 19:04:40.656 | slot update_slots: id  1 | task 16903 | Checking checkpoint with [76728, 76728] against 55637...
2026-05-15 19:04:40.656 | slot update_slots: id  1 | task 16903 | Checking checkpoint with [76403, 76403] against 55637...
2026-05-15 19:04:40.656 | slot update_slots: id  1 | task 16903 | Checking checkpoint with [75948, 75948] against 55637...
2026-05-15 19:04:40.656 | slot update_slots: id  1 | task 16903 | Checking checkpoint with [75436, 75436] against 55637...
2026-05-15 19:04:40.656 | slot update_slots: id  1 | task 16903 | Checking checkpoint with [74542, 74542] against 55637...
2026-05-15 19:04:40.656 | slot update_slots: id  1 | task 16903 | Checking checkpoint with [74030, 74030] against 55637...
2026-05-15 19:04:40.656 | slot update_slots: id  1 | task 16903 | Checking checkpoint with [73630, 73630] against 55637...
2026-05-15 19:04:40.656 | slot update_slots: id  1 | task 16903 | Checking checkpoint with [73171, 73171] against 55637...
2026-05-15 19:04:40.656 | slot update_slots: id  1 | task 16903 | Checking checkpoint with [72923, 72923] against 55637...
2026-05-15 19:04:40.656 | slot update_slots: id  1 | task 16903 | Checking checkpoint with [71909, 71909] against 55637...
2026-05-15 19:04:40.656 | slot update_slots: id  1 | task 16903 | Checking checkpoint with [71397, 71397] against 55637...
2026-05-15 19:04:40.656 | slot update_slots: id  1 | task 16903 | forcing full prompt re-processing due to lack of cache data (likely due to SWA or hybrid/recurrent memory, see https://github.com/ggml-org/llama.cpp/pull/13194#issuecomment-2868343055)
2026-05-15 19:04:40.656 | slot update_slots: id  1 | task 16903 | erased invalidated context checkpoint (pos_min = 71397, pos_max = 71397, n_tokens = 71398, n_swa = 0, pos_next = 0, size = 299.153 MiB)
2026-05-15 19:04:40.674 | slot update_slots: id  1 | task 16903 | erased invalidated context checkpoint (pos_min = 71909, pos_max = 71909, n_tokens = 71910, n_swa = 0, pos_next = 0, size = 300.225 MiB)
2026-05-15 19:04:40.690 | slot update_slots: id  1 | task 16903 | erased invalidated context checkpoint (pos_min = 72923, pos_max = 72923, n_tokens = 72924, n_swa = 0, pos_next = 0, size = 302.349 MiB)
2026-05-15 19:04:40.708 | slot update_slots: id  1 | task 16903 | erased invalidated context checkpoint (pos_min = 73171, pos_max = 73171, n_tokens = 73172, n_swa = 0, pos_next = 0, size = 302.868 MiB)
2026-05-15 19:04:40.725 | slot update_slots: id  1 | task 16903 | erased invalidated context checkpoint (pos_min = 73630, pos_max = 73630, n_tokens = 73631, n_swa = 0, pos_next = 0, size = 303.829 MiB)
2026-05-15 19:04:40.742 | slot update_slots: id  1 | task 16903 | erased invalidated context checkpoint (pos_min = 74030, pos_max = 74030, n_tokens = 74031, n_swa = 0, pos_next = 0, size = 304.667 MiB)
2026-05-15 19:04:40.760 | slot update_slots: id  1 | task 16903 | erased invalidated context checkpoint (pos_min = 74542, pos_max = 74542, n_tokens = 74543, n_swa = 0, pos_next = 0, size = 305.739 MiB)
2026-05-15 19:04:40.777 | slot update_slots: id  1 | task 16903 | erased invalidated context checkpoint (pos_min = 75436, pos_max = 75436, n_tokens = 75437, n_swa = 0, pos_next = 0, size = 307.612 MiB)
2026-05-15 19:04:40.794 | slot update_slots: id  1 | task 16903 | erased invalidated context checkpoint (pos_min = 75948, pos_max = 75948, n_tokens = 75949, n_swa = 0, pos_next = 0, size = 308.684 MiB)
2026-05-15 19:04:40.812 | slot update_slots: id  1 | task 16903 | erased invalidated context checkpoint (pos_min = 76403, pos_max = 76403, n_tokens = 76404, n_swa = 0, pos_next = 0, size = 309.637 MiB)
2026-05-15 19:04:40.830 | slot update_slots: id  1 | task 16903 | erased invalidated context checkpoint (pos_min = 76728, pos_max = 76728, n_tokens = 76729, n_swa = 0, pos_next = 0, size = 310.317 MiB)
2026-05-15 19:04:40.847 | slot update_slots: id  1 | task 16903 | erased invalidated context checkpoint (pos_min = 76956, pos_max = 76956, n_tokens = 76957, n_swa = 0, pos_next = 0, size = 310.795 MiB)
2026-05-15 19:04:40.865 | slot update_slots: id  1 | task 16903 | erased invalidated context checkpoint (pos_min = 77330, pos_max = 77330, n_tokens = 77331, n_swa = 0, pos_next = 0, size = 311.578 MiB)
2026-05-15 19:04:40.882 | slot update_slots: id  1 | task 16903 | erased invalidated context checkpoint (pos_min = 77699, pos_max = 77699, n_tokens = 77700, n_swa = 0, pos_next = 0, size = 312.351 MiB)
2026-05-15 19:04:40.900 | slot update_slots: id  1 | task 16903 | erased invalidated context checkpoint (pos_min = 77906, pos_max = 77906, n_tokens = 77907, n_swa = 0, pos_next = 0, size = 312.784 MiB)
2026-05-15 19:04:40.918 | slot update_slots: id  1 | task 16903 | erased invalidated context checkpoint (pos_min = 78193, pos_max = 78193, n_tokens = 78194, n_swa = 0, pos_next = 0, size = 313.385 MiB)
2026-05-15 19:04:40.936 | slot update_slots: id  1 | task 16903 | erased invalidated context checkpoint (pos_min = 78705, pos_max = 78705, n_tokens = 78706, n_swa = 0, pos_next = 0, size = 314.458 MiB)
2026-05-15 19:04:40.955 | slot update_slots: id  1 | task 16903 | erased invalidated context checkpoint (pos_min = 78846, pos_max = 78846, n_tokens = 78847, n_swa = 0, pos_next = 0, size = 314.753 MiB)
2026-05-15 19:04:40.974 | slot update_slots: id  1 | task 16903 | erased invalidated context checkpoint (pos_min = 79002, pos_max = 79002, n_tokens = 79003, n_swa = 0, pos_next = 0, size = 315.080 MiB)
2026-05-15 19:04:40.993 | slot update_slots: id  1 | task 16903 | erased invalidated context checkpoint (pos_min = 79120, pos_max = 79120, n_tokens = 79121, n_swa = 0, pos_next = 0, size = 315.327 MiB)
2026-05-15 19:04:41.011 | slot update_slots: id  1 | task 16903 | erased invalidated context checkpoint (pos_min = 79233, pos_max = 79233, n_tokens = 79234, n_swa = 0, pos_next = 0, size = 315.563 MiB)
2026-05-15 19:04:41.030 | slot update_slots: id  1 | task 16903 | erased invalidated context checkpoint (pos_min = 79802, pos_max = 79802, n_tokens = 79803, n_swa = 0, pos_next = 0, size = 316.755 MiB)
2026-05-15 19:04:41.049 | slot update_slots: id  1 | task 16903 | erased invalidated context checkpoint (pos_min = 79923, pos_max = 79923, n_tokens = 79924, n_swa = 0, pos_next = 0, size = 317.009 MiB)
2026-05-15 19:04:41.067 | slot update_slots: id  1 | task 16903 | erased invalidated context checkpoint (pos_min = 80034, pos_max = 80034, n_tokens = 80035, n_swa = 0, pos_next = 0, size = 317.241 MiB)
2026-05-15 19:04:41.085 | slot update_slots: id  1 | task 16903 | erased invalidated context checkpoint (pos_min = 80152, pos_max = 80152, n_tokens = 80153, n_swa = 0, pos_next = 0, size = 317.488 MiB)
2026-05-15 19:04:41.104 | slot update_slots: id  1 | task 16903 | erased invalidated context checkpoint (pos_min = 80674, pos_max = 80674, n_tokens = 80675, n_swa = 0, pos_next = 0, size = 318.581 MiB)
2026-05-15 19:04:41.122 | slot update_slots: id  1 | task 16903 | erased invalidated context checkpoint (pos_min = 81186, pos_max = 81186, n_tokens = 81187, n_swa = 0, pos_next = 0, size = 319.654 MiB)
2026-05-15 19:04:41.140 | slot update_slots: id  1 | task 16903 | erased invalidated context checkpoint (pos_min = 81415, pos_max = 81415, n_tokens = 81416, n_swa = 0, pos_next = 0, size = 320.133 MiB)
2026-05-15 19:04:41.158 | slot update_slots: id  1 | task 16903 | erased invalidated context checkpoint (pos_min = 81532, pos_max = 81532, n_tokens = 81533, n_swa = 0, pos_next = 0, size = 320.378 MiB)
2026-05-15 19:04:41.176 | slot update_slots: id  1 | task 16903 | erased invalidated context checkpoint (pos_min = 81735, pos_max = 81735, n_tokens = 81736, n_swa = 0, pos_next = 0, size = 320.803 MiB)
2026-05-15 19:04:41.195 | slot update_slots: id  1 | task 16903 | erased invalidated context checkpoint (pos_min = 82346, pos_max = 82346, n_tokens = 82347, n_swa = 0, pos_next = 0, size = 322.083 MiB)
2026-05-15 19:04:41.213 | slot update_slots: id  1 | task 16903 | erased invalidated context checkpoint (pos_min = 82858, pos_max = 82858, n_tokens = 82859, n_swa = 0, pos_next = 0, size = 323.155 MiB)
2026-05-15 19:04:41.232 | slot update_slots: id  1 | task 16903 | n_tokens = 0, memory_seq_rm [0, end)
2026-05-15 19:04:41.247 | slot update_slots: id  1 | task 16903 | prompt processing progress, n_tokens = 2048, batch.n_tokens = 2048, progress = 0.025747
2026-05-15 19:04:42.128 | slot update_slots: id  1 | task 16903 | n_tokens = 2048, memory_seq_rm [2048, end)
2026-05-15 19:04:42.128 | slot update_slots: id  1 | task 16903 | prompt processing progress, n_tokens = 4096, batch.n_tokens = 2048, progress = 0.051495
2026-05-15 19:04:42.829 | slot update_slots: id  1 | task 16903 | n_tokens = 4096, memory_seq_rm [4096, end)
2026-05-15 19:04:42.830 | slot update_slots: id  1 | task 16903 | prompt processing progress, n_tokens = 6144, batch.n_tokens = 2048, progress = 0.077242
2026-05-15 19:04:43.541 | slot update_slots: id  1 | task 16903 | n_tokens = 6144, memory_seq_rm [6144, end)
2026-05-15 19:04:43.541 | slot update_slots: id  1 | task 16903 | prompt processing progress, n_tokens = 8192, batch.n_tokens = 2048, progress = 0.102990
2026-05-15 19:04:44.264 | slot update_slots: id  1 | task 16903 | n_tokens = 8192, memory_seq_rm [8192, end)
2026-05-15 19:04:44.264 | slot update_slots: id  1 | task 16903 | 8192 tokens since last checkpoint at 0, creating new checkpoint during processing at position 10240
2026-05-15 19:04:44.264 | slot update_slots: id  1 | task 16903 | prompt processing progress, n_tokens = 10240, batch.n_tokens = 2048, progress = 0.128737
2026-05-15 19:04:44.383 | slot create_check: id  1 | task 16903 | created context checkpoint 1 of 32 (pos_min = 8191, pos_max = 8191, n_tokens = 8192, size = 166.782 MiB)
2026-05-15 19:04:45.116 | slot update_slots: id  1 | task 16903 | n_tokens = 10240, memory_seq_rm [10240, end)
2026-05-15 19:04:45.116 | slot update_slots: id  1 | task 16903 | prompt processing progress, n_tokens = 12288, batch.n_tokens = 2048, progress = 0.154484
2026-05-15 19:04:45.863 | slot update_slots: id  1 | task 16903 | n_tokens = 12288, memory_seq_rm [12288, end)
2026-05-15 19:04:45.864 | slot update_slots: id  1 | task 16903 | prompt processing progress, n_tokens = 14336, batch.n_tokens = 2048, progress = 0.180232
2026-05-15 19:04:46.644 | slot update_slots: id  1 | task 16903 | n_tokens = 14336, memory_seq_rm [14336, end)
2026-05-15 19:04:46.644 | slot update_slots: id  1 | task 16903 | prompt processing progress, n_tokens = 16384, batch.n_tokens = 2048, progress = 0.205979
2026-05-15 19:04:47.415 | slot update_slots: id  1 | task 16903 | n_tokens = 16384, memory_seq_rm [16384, end)
2026-05-15 19:04:47.415 | slot update_slots: id  1 | task 16903 | 8192 tokens since last checkpoint at 8192, creating new checkpoint during processing at position 18432
2026-05-15 19:04:47.415 | slot update_slots: id  1 | task 16903 | prompt processing progress, n_tokens = 18432, batch.n_tokens = 2048, progress = 0.231727
2026-05-15 19:04:47.532 | slot create_check: id  1 | task 16903 | created context checkpoint 2 of 32 (pos_min = 16383, pos_max = 16383, n_tokens = 16384, size = 183.939 MiB)
2026-05-15 19:04:48.315 | slot update_slots: id  1 | task 16903 | n_tokens = 18432, memory_seq_rm [18432, end)
2026-05-15 19:04:48.315 | slot update_slots: id  1 | task 16903 | prompt processing progress, n_tokens = 20480, batch.n_tokens = 2048, progress = 0.257474
2026-05-15 19:04:49.112 | slot update_slots: id  1 | task 16903 | n_tokens = 20480, memory_seq_rm [20480, end)
2026-05-15 19:04:49.112 | slot update_slots: id  1 | task 16903 | prompt processing progress, n_tokens = 22528, batch.n_tokens = 2048, progress = 0.283221
2026-05-15 19:04:49.926 | slot update_slots: id  1 | task 16903 | n_tokens = 22528, memory_seq_rm [22528, end)
2026-05-15 19:04:49.926 | slot update_slots: id  1 | task 16903 | prompt processing progress, n_tokens = 24576, batch.n_tokens = 2048, progress = 0.308969
2026-05-15 19:04:50.755 | slot update_slots: id  1 | task 16903 | n_tokens = 24576, memory_seq_rm [24576, end)
2026-05-15 19:04:50.755 | slot update_slots: id  1 | task 16903 | 8192 tokens since last checkpoint at 16384, creating new checkpoint during processing at position 26624
2026-05-15 19:04:50.755 | slot update_slots: id  1 | task 16903 | prompt processing progress, n_tokens = 26624, batch.n_tokens = 2048, progress = 0.334716
2026-05-15 19:04:50.879 | slot create_check: id  1 | task 16903 | created context checkpoint 3 of 32 (pos_min = 24575, pos_max = 24575, n_tokens = 24576, size = 201.095 MiB)
2026-05-15 19:04:51.726 | slot update_slots: id  1 | task 16903 | n_tokens = 26624, memory_seq_rm [26624, end)
2026-05-15 19:04:51.726 | slot update_slots: id  1 | task 16903 | prompt processing progress, n_tokens = 28672, batch.n_tokens = 2048, progress = 0.360464
2026-05-15 19:04:52.588 | slot update_slots: id  1 | task 16903 | n_tokens = 28672, memory_seq_rm [28672, end)
2026-05-15 19:04:52.588 | slot update_slots: id  1 | task 16903 | prompt processing progress, n_tokens = 30720, batch.n_tokens = 2048, progress = 0.386211
2026-05-15 19:04:53.470 | slot update_slots: id  1 | task 16903 | n_tokens = 30720, memory_seq_rm [30720, end)
2026-05-15 19:04:53.470 | slot update_slots: id  1 | task 16903 | prompt processing progress, n_tokens = 32768, batch.n_tokens = 2048, progress = 0.411958
2026-05-15 19:04:54.371 | slot update_slots: id  1 | task 16903 | n_tokens = 32768, memory_seq_rm [32768, end)
2026-05-15 19:04:54.371 | slot update_slots: id  1 | task 16903 | 8192 tokens since last checkpoint at 24576, creating new checkpoint during processing at position 34816
2026-05-15 19:04:54.371 | slot update_slots: id  1 | task 16903 | prompt processing progress, n_tokens = 34816, batch.n_tokens = 2048, progress = 0.437706
2026-05-15 19:04:54.535 | slot create_check: id  1 | task 16903 | created context checkpoint 4 of 32 (pos_min = 32767, pos_max = 32767, n_tokens = 32768, size = 218.251 MiB)
2026-05-15 19:04:55.457 | slot update_slots: id  1 | task 16903 | n_tokens = 34816, memory_seq_rm [34816, end)
2026-05-15 19:04:55.457 | slot update_slots: id  1 | task 16903 | prompt processing progress, n_tokens = 36864, batch.n_tokens = 2048, progress = 0.463453
2026-05-15 19:04:56.403 | slot update_slots: id  1 | task 16903 | n_tokens = 36864, memory_seq_rm [36864, end)
2026-05-15 19:04:56.403 | slot update_slots: id  1 | task 16903 | prompt processing progress, n_tokens = 38912, batch.n_tokens = 2048, progress = 0.489201
2026-05-15 19:04:57.368 | slot update_slots: id  1 | task 16903 | n_tokens = 38912, memory_seq_rm [38912, end)
2026-05-15 19:04:57.368 | slot update_slots: id  1 | task 16903 | prompt processing progress, n_tokens = 40960, batch.n_tokens = 2048, progress = 0.514948
2026-05-15 19:04:58.417 | slot update_slots: id  1 | task 16903 | n_tokens = 40960, memory_seq_rm [40960, end)
2026-05-15 19:04:58.417 | slot update_slots: id  1 | task 16903 | 8192 tokens since last checkpoint at 32768, creating new checkpoint during processing at position 43008
2026-05-15 19:04:58.417 | slot update_slots: id  1 | task 16903 | prompt processing progress, n_tokens = 43008, batch.n_tokens = 2048, progress = 0.540695
2026-05-15 19:04:58.658 | slot create_check: id  1 | task 16903 | created context checkpoint 5 of 32 (pos_min = 40959, pos_max = 40959, n_tokens = 40960, size = 235.407 MiB)
2026-05-15 19:04:59.669 | slot update_slots: id  1 | task 16903 | n_tokens = 43008, memory_seq_rm [43008, end)
2026-05-15 19:04:59.669 | slot update_slots: id  1 | task 16903 | prompt processing progress, n_tokens = 45056, batch.n_tokens = 2048, progress = 0.566443
2026-05-15 19:05:00.709 | slot update_slots: id  1 | task 16903 | n_tokens = 45056, memory_seq_rm [45056, end)
2026-05-15 19:05:00.710 | slot update_slots: id  1 | task 16903 | prompt processing progress, n_tokens = 47104, batch.n_tokens = 2048, progress = 0.592190
2026-05-15 19:05:01.778 | slot update_slots: id  1 | task 16903 | n_tokens = 47104, memory_seq_rm [47104, end)
2026-05-15 19:05:01.778 | slot update_slots: id  1 | task 16903 | prompt processing progress, n_tokens = 49152, batch.n_tokens = 2048, progress = 0.617938
2026-05-15 19:05:02.887 | slot update_slots: id  1 | task 16903 | n_tokens = 49152, memory_seq_rm [49152, end)
2026-05-15 19:05:02.887 | slot update_slots: id  1 | task 16903 | 8192 tokens since last checkpoint at 40960, creating new checkpoint during processing at position 51200
2026-05-15 19:05:02.890 | slot update_slots: id  1 | task 16903 | prompt processing progress, n_tokens = 51200, batch.n_tokens = 2048, progress = 0.643685
2026-05-15 19:05:03.172 | slot create_check: id  1 | task 16903 | created context checkpoint 6 of 32 (pos_min = 49151, pos_max = 49151, n_tokens = 49152, size = 252.564 MiB)
2026-05-15 19:05:04.310 | slot update_slots: id  1 | task 16903 | n_tokens = 51200, memory_seq_rm [51200, end)
2026-05-15 19:05:04.310 | slot update_slots: id  1 | task 16903 | prompt processing progress, n_tokens = 53248, batch.n_tokens = 2048, progress = 0.669433
2026-05-15 19:05:05.476 | slot update_slots: id  1 | task 16903 | n_tokens = 53248, memory_seq_rm [53248, end)
2026-05-15 19:05:05.476 | slot update_slots: id  1 | task 16903 | prompt processing progress, n_tokens = 55296, batch.n_tokens = 2048, progress = 0.695180
2026-05-15 19:05:06.657 | slot update_slots: id  1 | task 16903 | n_tokens = 55296, memory_seq_rm [55296, end)
2026-05-15 19:05:06.657 | slot update_slots: id  1 | task 16903 | prompt processing progress, n_tokens = 57344, batch.n_tokens = 2048, progress = 0.720927
2026-05-15 19:05:07.855 | slot update_slots: id  1 | task 16903 | n_tokens = 57344, memory_seq_rm [57344, end)
2026-05-15 19:05:07.855 | slot update_slots: id  1 | task 16903 | 8192 tokens since last checkpoint at 49152, creating new checkpoint during processing at position 59392
2026-05-15 19:05:07.855 | slot update_slots: id  1 | task 16903 | prompt processing progress, n_tokens = 59392, batch.n_tokens = 2048, progress = 0.746675
2026-05-15 19:05:08.153 | slot create_check: id  1 | task 16903 | created context checkpoint 7 of 32 (pos_min = 57343, pos_max = 57343, n_tokens = 57344, size = 269.720 MiB)
2026-05-15 19:05:09.399 | slot update_slots: id  1 | task 16903 | n_tokens = 59392, memory_seq_rm [59392, end)
2026-05-15 19:05:09.399 | slot update_slots: id  1 | task 16903 | prompt processing progress, n_tokens = 61440, batch.n_tokens = 2048, progress = 0.772422
2026-05-15 19:05:10.697 | slot update_slots: id  1 | task 16903 | n_tokens = 61440, memory_seq_rm [61440, end)
2026-05-15 19:05:10.697 | slot update_slots: id  1 | task 16903 | prompt processing progress, n_tokens = 63488, batch.n_tokens = 2048, progress = 0.798169
2026-05-15 19:05:12.040 | slot update_slots: id  1 | task 16903 | n_tokens = 63488, memory_seq_rm [63488, end)
2026-05-15 19:05:12.040 | slot update_slots: id  1 | task 16903 | prompt processing progress, n_tokens = 65536, batch.n_tokens = 2048, progress = 0.823917
2026-05-15 19:05:13.403 | slot update_slots: id  1 | task 16903 | n_tokens = 65536, memory_seq_rm [65536, end)
2026-05-15 19:05:13.403 | slot update_slots: id  1 | task 16903 | 8192 tokens since last checkpoint at 57344, creating new checkpoint during processing at position 67584
2026-05-15 19:05:13.406 | slot update_slots: id  1 | task 16903 | prompt processing progress, n_tokens = 67584, batch.n_tokens = 2048, progress = 0.849664
2026-05-15 19:05:13.716 | slot create_check: id  1 | task 16903 | created context checkpoint 8 of 32 (pos_min = 65535, pos_max = 65535, n_tokens = 65536, size = 286.876 MiB)
2026-05-15 19:05:15.087 | slot update_slots: id  1 | task 16903 | n_tokens = 67584, memory_seq_rm [67584, end)
2026-05-15 19:05:15.088 | slot update_slots: id  1 | task 16903 | prompt processing progress, n_tokens = 69632, batch.n_tokens = 2048, progress = 0.875412
2026-05-15 19:05:16.486 | slot update_slots: id  1 | task 16903 | n_tokens = 69632, memory_seq_rm [69632, end)
2026-05-15 19:05:16.486 | slot update_slots: id  1 | task 16903 | prompt processing progress, n_tokens = 71680, batch.n_tokens = 2048, progress = 0.901159
2026-05-15 19:05:17.924 | slot update_slots: id  1 | task 16903 | n_tokens = 71680, memory_seq_rm [71680, end)
2026-05-15 19:05:17.924 | slot update_slots: id  1 | task 16903 | prompt processing progress, n_tokens = 73728, batch.n_tokens = 2048, progress = 0.926907
2026-05-15 19:05:19.377 | slot update_slots: id  1 | task 16903 | n_tokens = 73728, memory_seq_rm [73728, end)
2026-05-15 19:05:19.377 | slot update_slots: id  1 | task 16903 | 8192 tokens since last checkpoint at 65536, creating new checkpoint during processing at position 75776
2026-05-15 19:05:19.377 | slot update_slots: id  1 | task 16903 | prompt processing progress, n_tokens = 75776, batch.n_tokens = 2048, progress = 0.952654
2026-05-15 19:05:19.715 | slot create_check: id  1 | task 16903 | created context checkpoint 9 of 32 (pos_min = 73727, pos_max = 73727, n_tokens = 73728, size = 304.032 MiB)
2026-05-15 19:05:21.207 | slot update_slots: id  1 | task 16903 | n_tokens = 75776, memory_seq_rm [75776, end)
2026-05-15 19:05:21.207 | slot update_slots: id  1 | task 16903 | prompt processing progress, n_tokens = 77824, batch.n_tokens = 2048, progress = 0.978401
2026-05-15 19:05:22.742 | slot update_slots: id  1 | task 16903 | n_tokens = 77824, memory_seq_rm [77824, end)
2026-05-15 19:05:22.742 | slot update_slots: id  1 | task 16903 | prompt processing progress, n_tokens = 79026, batch.n_tokens = 1202, progress = 0.993513
2026-05-15 19:05:23.696 | slot update_slots: id  1 | task 16903 | n_tokens = 79026, memory_seq_rm [79026, end)
2026-05-15 19:05:23.696 | slot update_slots: id  1 | task 16903 | prompt processing progress, n_tokens = 79538, batch.n_tokens = 512, progress = 0.999950
2026-05-15 19:05:24.050 | slot create_check: id  1 | task 16903 | created context checkpoint 10 of 32 (pos_min = 79025, pos_max = 79025, n_tokens = 79026, size = 315.128 MiB)
2026-05-15 19:05:24.444 | slot update_slots: id  1 | task 16903 | n_tokens = 79538, memory_seq_rm [79538, end)
2026-05-15 19:05:24.453 | slot init_sampler: id  1 | task 16903 | init sampler, took 9.91 ms, tokens: text = 79542, total = 79542
2026-05-15 19:05:24.454 | slot update_slots: id  1 | task 16903 | prompt processing done, n_tokens = 79542, batch.n_tokens = 4
2026-05-15 19:05:24.804 | slot create_check: id  1 | task 16903 | created context checkpoint 11 of 32 (pos_min = 79537, pos_max = 79537, n_tokens = 79538, size = 316.200 MiB)
2026-05-15 19:05:24.846 | srv  log_server_r: done request: POST /v1/chat/completions 172.18.0.1 200
2026-05-15 19:05:29.305 | reasoning-budget: deactivated (natural end)
2026-05-15 19:05:31.391 | slot print_timing: id  1 | task 16903 | 
2026-05-15 19:05:31.391 | prompt eval time =   44185.00 ms / 79542 tokens (    0.56 ms per token,  1800.20 tokens per second)
2026-05-15 19:05:31.391 |        eval time =    6546.16 ms /   308 tokens (   21.25 ms per token,    47.05 tokens per second)
2026-05-15 19:05:31.391 |       total time =   50731.16 ms / 79850 tokens
2026-05-15 19:05:31.391 | draft acceptance rate = 0.95808 (  160 accepted /   167 generated)
2026-05-15 19:05:31.391 | statistics mtp: #calls(b,g,a) = 134 15348 11958, #gen drafts = 11958, #acc drafts = 11958, #gen tokens = 21116, #acc tokens = 20791, dur(b,g,a) = 0.182, 61874.871, 5.027 ms
2026-05-15 19:05:31.393 | slot      release: id  1 | task 16903 | stop processing: n_tokens = 79849, truncated = 0
2026-05-15 19:05:31.393 | srv  update_slots: all slots are idle
2026-05-15 19:12:35.999 | srv  params_from_: Chat format: peg-native
2026-05-15 19:12:36.001 | slot get_availabl: id  1 | task -1 | selected slot by LCP similarity, sim_best = 0.995 (> 0.100 thold), f_keep = 0.995
2026-05-15 19:12:36.003 | reasoning-budget: activated, budget=2147483647 tokens
2026-05-15 19:12:36.003 | slot launch_slot_: id  1 | task -1 | sampler chain: logits -> penalties -> ?dry -> ?top-n-sigma -> top-k -> ?typical -> ?top-p -> min-p -> ?xtc -> ?temp-ext -> dist 
2026-05-15 19:12:36.003 | slot launch_slot_: id  1 | task 17109 | processing task, is_child = 0
2026-05-15 19:12:36.003 | slot update_slots: id  1 | task 17109 | new prompt, n_ctx_slot = 131072, n_keep = 0, task.n_tokens = 79909
2026-05-15 19:12:36.003 | slot update_slots: id  1 | task 17109 | n_past = 79480, slot.prompt.tokens.size() = 79849, seq_id = 1, pos_min = 79848, n_swa = 0
2026-05-15 19:12:36.003 | slot update_slots: id  1 | task 17109 | Checking checkpoint with [79537, 79537] against 79480...
2026-05-15 19:12:36.003 | slot update_slots: id  1 | task 17109 | Checking checkpoint with [79025, 79025] against 79480...
2026-05-15 19:12:36.132 | slot update_slots: id  1 | task 17109 | restored context checkpoint (pos_min = 79025, pos_max = 79025, n_tokens = 79026, n_past = 79026, size = 315.128 MiB)
2026-05-15 19:12:36.132 | slot update_slots: id  1 | task 17109 | erased invalidated context checkpoint (pos_min = 79537, pos_max = 79537, n_tokens = 79538, n_swa = 0, pos_next = 79026, size = 316.200 MiB)
2026-05-15 19:12:36.150 | slot update_slots: id  1 | task 17109 | n_tokens = 79026, memory_seq_rm [79026, end)
2026-05-15 19:12:36.151 | slot update_slots: id  1 | task 17109 | prompt processing progress, n_tokens = 79393, batch.n_tokens = 367, progress = 0.993543
2026-05-15 19:12:36.541 | slot update_slots: id  1 | task 17109 | n_tokens = 79393, memory_seq_rm [79393, end)
2026-05-15 19:12:36.541 | slot update_slots: id  1 | task 17109 | prompt processing progress, n_tokens = 79905, batch.n_tokens = 512, progress = 0.999950
2026-05-15 19:12:36.892 | slot create_check: id  1 | task 17109 | created context checkpoint 11 of 32 (pos_min = 79392, pos_max = 79392, n_tokens = 79393, size = 315.896 MiB)
2026-05-15 19:12:37.279 | slot update_slots: id  1 | task 17109 | n_tokens = 79905, memory_seq_rm [79905, end)
2026-05-15 19:12:37.289 | slot init_sampler: id  1 | task 17109 | init sampler, took 10.01 ms, tokens: text = 79909, total = 79909
2026-05-15 19:12:37.289 | slot update_slots: id  1 | task 17109 | prompt processing done, n_tokens = 79909, batch.n_tokens = 4
2026-05-15 19:12:37.643 | slot create_check: id  1 | task 17109 | created context checkpoint 12 of 32 (pos_min = 79904, pos_max = 79904, n_tokens = 79905, size = 316.969 MiB)
2026-05-15 19:12:37.683 | srv  log_server_r: done request: POST /v1/chat/completions 172.18.0.1 200
2026-05-15 19:12:41.897 | reasoning-budget: deactivated (natural end)
2026-05-15 19:12:43.580 | slot print_timing: id  1 | task 17109 | 
2026-05-15 19:12:43.581 | prompt eval time =    1679.61 ms /   883 tokens (    1.90 ms per token,   525.72 tokens per second)
2026-05-15 19:12:43.581 |        eval time =    5897.15 ms /   260 tokens (   22.68 ms per token,    44.09 tokens per second)
2026-05-15 19:12:43.581 |       total time =    7576.77 ms /  1143 tokens
2026-05-15 19:12:43.581 | draft acceptance rate = 0.97458 (  115 accepted /   118 generated)
2026-05-15 19:12:43.581 | statistics mtp: #calls(b,g,a) = 135 15492 12039, #gen drafts = 12039, #acc drafts = 12039, #gen tokens = 21234, #acc tokens = 20906, dur(b,g,a) = 0.183, 62431.891, 5.070 ms
2026-05-15 19:12:43.583 | slot      release: id  1 | task 17109 | stop processing: n_tokens = 80168, truncated = 0
2026-05-15 19:12:43.583 | srv  update_slots: all slots are idle
2026-05-15 19:13:01.583 | srv    operator(): operator(): cleaning up before exit...
2026-05-15 19:13:01.585 | common_memory_breakdown_print: | memory breakdown [MiB] | total   free     self   model   context   compute    unaccounted |
2026-05-15 19:13:01.585 | common_memory_breakdown_print: |   - CUDA0 (RTX 5090)   | 32606 = 4334 + (21832 = 16386 +    4950 +     495) +        6439 |
2026-05-15 19:13:01.585 | common_memory_breakdown_print: |   - Host               |                   958 =   682 +       0 +     276                |
```