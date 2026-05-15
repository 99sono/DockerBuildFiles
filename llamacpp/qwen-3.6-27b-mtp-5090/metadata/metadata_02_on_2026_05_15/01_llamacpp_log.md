# llamacpp log

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