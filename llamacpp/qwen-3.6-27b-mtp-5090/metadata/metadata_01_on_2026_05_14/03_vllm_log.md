
# vllm log (used opencode to)

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

