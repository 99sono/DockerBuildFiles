WARNING 05-03 17:49:37 [argparse_utils.py:257] With `vllm serve`, you should provide the model as a positional argument or in a config file instead of via the `--model` option. The `--model` option will be removed in a future version.
(APIServer pid=1) INFO 05-03 17:49:37 [utils.py:299] 
(APIServer pid=1) INFO 05-03 17:49:37 [utils.py:299]        █     █     █▄   ▄█
(APIServer pid=1) INFO 05-03 17:49:37 [utils.py:299]  ▄▄ ▄█ █     █     █ ▀▄▀ █  version 0.20.0
(APIServer pid=1) INFO 05-03 17:49:37 [utils.py:299]   █▄█▀ █     █     █     █  model   RedHatAI/Qwen3.6-35B-A3B-NVFP4
(APIServer pid=1) INFO 05-03 17:49:37 [utils.py:299]    ▀▀  ▀▀▀▀▀ ▀▀▀▀▀ ▀     ▀
(APIServer pid=1) INFO 05-03 17:49:37 [utils.py:299] 
(APIServer pid=1) INFO 05-03 17:49:37 [utils.py:233] non-default args: {'model_tag': 'RedHatAI/Qwen3.6-35B-A3B-NVFP4', 'tool_call_parser': 'qwen3_coder', 'host': '0.0.0.0', 'model': 'RedHatAI/Qwen3.6-35B-A3B-NVFP4', 'trust_remote_code': True, 'max_model_len': 262144, 'quantization': 'compressed-tensors', 'served_model_name': ['Qwen3.6-35B-A3B-NVFP4'], 'safetensors_load_strategy': 'prefetch', 'reasoning_parser': 'qwen3', 'gpu_memory_utilization': 0.85, 'kv_cache_dtype': 'fp8_e4m3', 'enable_prefix_caching': True, 'max_num_batched_tokens': 65536, 'max_num_seqs': 8, 'enable_chunked_prefill': True, 'max_cudagraph_capture_size': 1, 'moe_backend': 'flashinfer_cutlass'}
(APIServer pid=1) Warning: You are sending unauthenticated requests to the HF Hub. Please set a HF_TOKEN to enable higher rate limits and faster downloads.
(APIServer pid=1) INFO 05-03 17:49:44 [nixl_utils.py:20] Setting UCX_RCACHE_MAX_UNRELEASED to '1024' to avoid a rare memory leak in UCX when using NIXL.
(APIServer pid=1) INFO 05-03 17:49:44 [nixl_utils.py:32] NIXL is available
(APIServer pid=1) INFO 05-03 17:49:44 [model.py:555] Resolved architecture: Qwen3_5MoeForConditionalGeneration
(APIServer pid=1) INFO 05-03 17:49:44 [model.py:1680] Using max model len 262144
(APIServer pid=1) INFO 05-03 17:49:44 [cache.py:261] Using fp8_e4m3 data type to store kv cache. It reduces the GPU memory footprint and boosts the performance. Meanwhile, it may cause accuracy drop without a proper scaling factor
(APIServer pid=1) INFO 05-03 17:49:44 [scheduler.py:239] Chunked prefill is enabled with max_num_batched_tokens=65536.
(APIServer pid=1) WARNING 05-03 17:49:44 [config.py:367] Mamba cache mode is set to 'align' for Qwen3_5MoeForConditionalGeneration by default when prefix caching is enabled
(APIServer pid=1) INFO 05-03 17:49:44 [config.py:387] Warning: Prefix caching in Mamba cache 'align' mode is currently enabled. Its support for Mamba layers is experimental. Please report any issues you may observe.
(APIServer pid=1) INFO 05-03 17:49:44 [vllm.py:840] Asynchronous scheduling is enabled.
(APIServer pid=1) INFO 05-03 17:49:44 [kernel.py:205] Final IR op priority after setting platform defaults: IrOpPriorityConfig(rms_norm=['native'])
(APIServer pid=1) INFO 05-03 17:49:47 [compilation.py:303] Enabled custom fusions: act_quant
(APIServer pid=1) [transformers] `Qwen2VLImageProcessorFast` is deprecated. The `Fast` suffix for image processors has been removed; use `Qwen2VLImageProcessor` instead.
(APIServer pid=1) [transformers] The `use_fast` parameter is deprecated and will be removed in a future version. Use `backend="torchvision"` instead of `use_fast=True`, or `backend="pil"` instead of `use_fast=False`.
INFO 05-03 17:50:02 [nixl_utils.py:32] NIXL is available
(EngineCore pid=125) INFO 05-03 17:50:02 [core.py:109] Initializing a V1 LLM engine (v0.20.0) with config: model='RedHatAI/Qwen3.6-35B-A3B-NVFP4', speculative_config=None, tokenizer='RedHatAI/Qwen3.6-35B-A3B-NVFP4', skip_tokenizer_init=False, tokenizer_mode=auto, revision=None, tokenizer_revision=None, trust_remote_code=True, dtype=torch.bfloat16, max_seq_len=262144, download_dir=None, load_format=auto, tensor_parallel_size=1, pipeline_parallel_size=1, data_parallel_size=1, decode_context_parallel_size=1, dcp_comm_backend=ag_rs, disable_custom_all_reduce=False, quantization=compressed-tensors, quantization_config=None, enforce_eager=False, enable_return_routed_experts=False, kv_cache_dtype=fp8_e4m3, device_config=cuda, structured_outputs_config=StructuredOutputsConfig(backend='auto', disable_any_whitespace=False, disable_additional_properties=False, reasoning_parser='qwen3', reasoning_parser_plugin='', enable_in_reasoning=False), observability_config=ObservabilityConfig(show_hidden_metrics_for_version=None, otlp_traces_endpoint=None, collect_detailed_traces=None, kv_cache_metrics=False, kv_cache_metrics_sample=0.01, cudagraph_metrics=False, enable_layerwise_nvtx_tracing=False, enable_mfu_metrics=False, enable_mm_processor_stats=False, enable_logging_iteration_details=False), seed=0, served_model_name=Qwen3.6-35B-A3B-NVFP4, enable_prefix_caching=True, enable_chunked_prefill=True, pooler_config=None, compilation_config={'mode': <CompilationMode.VLLM_COMPILE: 3>, 'debug_dump_path': None, 'cache_dir': '', 'compile_cache_save_format': 'binary', 'backend': 'inductor', 'custom_ops': ['none'], 'ir_enable_torch_wrap': True, 'splitting_ops': ['vllm::unified_attention_with_output', 'vllm::unified_mla_attention_with_output', 'vllm::mamba_mixer2', 'vllm::mamba_mixer', 'vllm::short_conv', 'vllm::linear_attention', 'vllm::plamo2_mamba_mixer', 'vllm::gdn_attention_core', 'vllm::gdn_attention_core_xpu', 'vllm::olmo_hybrid_gdn_full_forward', 'vllm::kda_attention', 'vllm::sparse_attn_indexer', 'vllm::rocm_aiter_sparse_attn_indexer', 'vllm::deepseek_v4_attention', 'vllm::unified_kv_cache_update', 'vllm::unified_mla_kv_cache_update'], 'compile_mm_encoder': False, 'cudagraph_mm_encoder': False, 'encoder_cudagraph_token_budgets': [], 'encoder_cudagraph_max_vision_items_per_batch': 0, 'encoder_cudagraph_max_frames_per_batch': None, 'compile_sizes': [], 'compile_ranges_endpoints': [65536], 'inductor_compile_config': {'enable_auto_functionalized_v2': False, 'size_asserts': False, 'alignment_asserts': False, 'scalar_asserts': False, 'combo_kernels': True, 'benchmark_combo_kernel': True}, 'inductor_passes': {}, 'cudagraph_mode': <CUDAGraphMode.FULL_AND_PIECEWISE: (2, 1)>, 'cudagraph_num_of_warmups': 1, 'cudagraph_capture_sizes': [1], 'cudagraph_copy_inputs': False, 'cudagraph_specialize_lora': True, 'use_inductor_graph_partition': False, 'pass_config': {'fuse_norm_quant': False, 'fuse_act_quant': True, 'fuse_attn_quant': False, 'enable_sp': False, 'fuse_gemm_comms': False, 'fuse_allreduce_rms': False}, 'max_cudagraph_capture_size': 1, 'dynamic_shapes_config': {'type': <DynamicShapesType.BACKED: 'backed'>, 'evaluate_guards': False, 'assume_32_bit_indexing': False}, 'local_cache_dir': None, 'fast_moe_cold_start': False, 'static_all_moe_layers': []}, kernel_config=KernelConfig(ir_op_priority=IrOpPriorityConfig(rms_norm=['native']), enable_flashinfer_autotune=True, moe_backend='flashinfer_cutlass')
(EngineCore pid=125) [transformers] `Qwen2VLImageProcessorFast` is deprecated. The `Fast` suffix for image processors has been removed; use `Qwen2VLImageProcessor` instead.
(EngineCore pid=125) Warning: You are sending unauthenticated requests to the HF Hub. Please set a HF_TOKEN to enable higher rate limits and faster downloads.
(EngineCore pid=125) INFO 05-03 17:50:05 [parallel_state.py:1402] world_size=1 rank=0 local_rank=0 distributed_init_method=tcp://172.18.0.2:42365 backend=nccl
(EngineCore pid=125) INFO 05-03 17:50:05 [parallel_state.py:1715] rank 0 in world size 1 is assigned as DP rank 0, PP rank 0, PCP rank 0, TP rank 0, EP rank 0, EPLB rank N/A
(EngineCore pid=125) [transformers] The `use_fast` parameter is deprecated and will be removed in a future version. Use `backend="torchvision"` instead of `use_fast=True`, or `backend="pil"` instead of `use_fast=False`.
(EngineCore pid=125) INFO 05-03 17:50:16 [gpu_model_runner.py:4777] Starting to load model RedHatAI/Qwen3.6-35B-A3B-NVFP4...
(EngineCore pid=125) INFO 05-03 17:50:16 [cuda.py:423] Using backend AttentionBackendEnum.FLASH_ATTN for vit attention
(EngineCore pid=125) INFO 05-03 17:50:16 [mm_encoder_attention.py:230] Using AttentionBackendEnum.FLASH_ATTN for MMEncoderAttention.
(EngineCore pid=125) INFO 05-03 17:50:17 [gdn_linear_attn.py:153] Using Triton/FLA GDN prefill kernel
(EngineCore pid=125) INFO 05-03 17:50:17 [__init__.py:683] Using FlashInferCutlassNvFp4LinearKernel for NVFP4 GEMM
(EngineCore pid=125) INFO 05-03 17:50:17 [nvfp4.py:209] Using 'FLASHINFER_CUTLASS' NvFp4 MoE backend out of potential backends: ['FLASHINFER_TRTLLM', 'FLASHINFER_CUTEDSL', 'FLASHINFER_CUTEDSL_BATCHED', 'FLASHINFER_CUTLASS', 'VLLM_CUTLASS', 'MARLIN', 'EMULATION'].
(EngineCore pid=125) INFO 05-03 17:50:18 [cuda.py:368] Using FLASHINFER attention backend out of potential backends: ['FLASHINFER', 'TRITON_ATTN'].
(EngineCore pid=125) INFO 05-03 17:50:19 [weight_utils.py:904] Filesystem type for checkpoints: EXT4. Checkpoint size: 23.32 GiB. Available RAM: 87.94 GiB.
(EngineCore pid=125) INFO 05-03 17:50:19 [weight_utils.py:874] Prefetching checkpoint files into page cache started (in background)
(EngineCore pid=125) Loading safetensors checkpoint shards:   0% Completed | 0/3 [00:00<?, ?it/s]
(EngineCore pid=125) INFO 05-03 17:50:21 [weight_utils.py:851] Prefetching checkpoint files: 10% (1/3)
(EngineCore pid=125) INFO 05-03 17:50:22 [weight_utils.py:851] Prefetching checkpoint files: 20% (2/3)
(EngineCore pid=125) INFO 05-03 17:50:42 [weight_utils.py:851] Prefetching checkpoint files: 30% (3/3)
(EngineCore pid=125) INFO 05-03 17:50:42 [weight_utils.py:869] Prefetching checkpoint files into page cache finished in 22.80s
(EngineCore pid=125) Loading safetensors checkpoint shards:  33% Completed | 1/3 [01:54<03:49, 114.94s/it]
(EngineCore pid=125) Loading safetensors checkpoint shards: 100% Completed | 3/3 [02:02<00:00, 32.68s/it]
(EngineCore pid=125)  Loading safetensors checkpoint shards: 100% Completed | 3/3 [02:02<00:00, 40.91s/it]
(EngineCore pid=125) 
(EngineCore pid=125) INFO 05-03 17:52:22 [default_loader.py:384] Loading weights took 122.79 seconds
(EngineCore pid=125) INFO 05-03 17:52:22 [nvfp4.py:485] Using MoEPrepareAndFinalizeNoDPEPModular
(EngineCore pid=125) INFO 05-03 17:52:23 [gpu_model_runner.py:4879] Model loading took 21.86 GiB memory and 125.992893 seconds
(EngineCore pid=125) INFO 05-03 17:52:23 [interface.py:606] Setting attention block size to 2096 tokens to ensure that attention page size is >= mamba page size.
(EngineCore pid=125) INFO 05-03 17:52:23 [gpu_model_runner.py:5820] Encoder cache will be initialized with a budget of 65536 tokens, and profiled with 4 image items of the maximum feature size.
(EngineCore pid=125) INFO 05-03 17:52:36 [backends.py:1069] Using cache directory: /root/.cache/vllm/torch_compile_cache/35eba928f9/rank_0_0/backbone for vLLM's torch.compile
(EngineCore pid=125) INFO 05-03 17:52:36 [backends.py:1128] Dynamo bytecode transform time: 5.12 s
(EngineCore pid=125) [rank0]:W0503 17:53:07.724000 125 torch/_inductor/utils.py:1731] Not enough SMs to use max_autotune_gemm mode
(EngineCore pid=125) INFO 05-03 17:53:09 [backends.py:376] Cache the graph of compile range (1, 65536) for later use
(EngineCore pid=125) INFO 05-03 17:53:32 [backends.py:391] Compiling a graph for compile range (1, 65536) takes 55.30 s
(EngineCore pid=125) INFO 05-03 17:53:34 [decorators.py:668] saved AOT compiled function to /root/.cache/vllm/torch_compile_cache/torch_aot_compile/9e64bc48be2c7f22fa84da6fc889747e2233d0c5746f5fb197d39e18ad2cb2f2/rank_0_0/model
(EngineCore pid=125) INFO 05-03 17:53:34 [monitor.py:53] torch.compile took 62.80 s in total
(EngineCore pid=125) INFO 05-03 17:54:25 [monitor.py:81] Initial profiling/warmup run took 51.11 s
(EngineCore pid=125) INFO 05-03 17:54:29 [gpu_model_runner.py:5963] Profiling CUDA graph memory: PIECEWISE=1 (largest=1), FULL=1 (largest=1)
(EngineCore pid=125) INFO 05-03 17:54:32 [gpu_model_runner.py:6042] Estimated CUDA graph memory: 0.47 GiB total
(EngineCore pid=125) INFO 05-03 17:54:32 [gpu_worker.py:440] Available KV cache memory: 66.93 GiB
(EngineCore pid=125) INFO 05-03 17:54:32 [gpu_worker.py:455] CUDA graph memory profiling is enabled (default since v0.21.0). The current --gpu-memory-utilization=0.8500 is equivalent to --gpu-memory-utilization=0.8461 without CUDA graph memory profiling. To maintain the same effective KV cache size as before, increase --gpu-memory-utilization to 0.8539. To disable, set VLLM_MEMORY_PROFILER_ESTIMATE_CUDAGRAPHS=0.
(EngineCore pid=125) INFO 05-03 17:54:32 [kv_cache_utils.py:1711] GPU KV cache size: 1,754,352 tokens
(EngineCore pid=125) INFO 05-03 17:54:32 [kv_cache_utils.py:1716] Maximum concurrency for 262,144 tokens per request: 25.36x
(EngineCore pid=125) 2026-05-03 17:54:35,921 - INFO - autotuner.py:457 - flashinfer.jit: [Autotuner]: Autotuning process starts ...
(EngineCore pid=125) [AutoTuner]: Tuning fp4_gemm:   0%|          | 0/17 [00:00<?, ?profile/s][AutoTuner]: Tuning fp4_gemm:  76%|███████▋  | 13/17 [00:00<00:00, 117.97profile/s][AutoTuner]: Tuning fp4_gemm: 100%|██████████| 17/17 [00:00<00:00, 29.59profile/s] 
(EngineCore pid=125) [AutoTuner]: Tuning fp4_gemm:   0%|          | 0/17 [00:00<?, ?profile/s][AutoTuner]: Tuning fp4_gemm:  76%|███████▋  | 13/17 [00:00<00:00, 128.30profile/s][AutoTuner]: Tuning fp4_gemm: 100%|██████████| 17/17 [00:00<00:00, 35.33profile/s] 
(EngineCore pid=125) [AutoTuner]: Tuning trtllm::fused_moe::gemm1:   0%|          | 0/1 [00:00<?, ?profile/s]2026-05-03 17:54:37,325 - INFO - autotuner.py:833 - flashinfer.jit: [Autotuner]: Skipped 4 unsupported tactic(s) for trtllm::fused_moe::gemm1 (enable debug logs to see details)
(EngineCore pid=125) [AutoTuner]: Tuning trtllm::fused_moe::gemm1: 100%|██████████| 1/1 [00:00<00:00, 25.01profile/s]
(EngineCore pid=125) [AutoTuner]: Tuning trtllm::fused_moe::gemm2:   0%|          | 0/1 [00:00<?, ?profile/s]2026-05-03 17:54:37,371 - INFO - autotuner.py:833 - flashinfer.jit: [Autotuner]: Skipped 10 unsupported tactic(s) for trtllm::fused_moe::gemm2 (enable debug logs to see details)
(EngineCore pid=125) [AutoTuner]: Tuning trtllm::fused_moe::gemm2: 100%|██████████| 1/1 [00:00<00:00, 22.40profile/s]
(EngineCore pid=125) [AutoTuner]: Tuning fp4_gemm:   0%|          | 0/17 [00:00<?, ?profile/s][AutoTuner]: Tuning fp4_gemm:   6%|▌         | 1/17 [00:00<00:05,  3.15profile/s][AutoTuner]: Tuning fp4_gemm:  65%|██████▍   | 11/17 [00:00<00:00, 31.47profile/s][AutoTuner]: Tuning fp4_gemm: 100%|██████████| 17/17 [00:03<00:00,  4.01profile/s][AutoTuner]: Tuning fp4_gemm: 100%|██████████| 17/17 [00:03<00:00,  4.78profile/s]
(EngineCore pid=125) [AutoTuner]: Tuning fp4_gemm:   0%|          | 0/17 [00:00<?, ?profile/s][AutoTuner]: Tuning fp4_gemm:  47%|████▋     | 8/17 [00:00<00:00, 78.31profile/s][AutoTuner]: Tuning fp4_gemm:  94%|█████████▍| 16/17 [00:00<00:00, 23.82profile/s][AutoTuner]: Tuning fp4_gemm: 100%|██████████| 17/17 [00:01<00:00, 14.77profile/s]
(EngineCore pid=125) 2026-05-03 17:54:51,538 - INFO - autotuner.py:466 - flashinfer.jit: [Autotuner]: Autotuning process ends
(EngineCore pid=125) Capturing CUDA graphs (mixed prefill-decode, PIECEWISE):   0%|          | 0/1 [00:00<?, ?it/s]Capturing CUDA graphs (mixed prefill-decode, PIECEWISE): 100%|██████████| 1/1 [00:00<00:00, 12.94it/s]
(EngineCore pid=125) Capturing CUDA graphs (decode, FULL):   0%|          | 0/1 [00:00<?, ?it/s]Capturing CUDA graphs (decode, FULL): 100%|██████████| 1/1 [00:00<00:00,  5.06it/s]Capturing CUDA graphs (decode, FULL): 100%|██████████| 1/1 [00:00<00:00,  5.05it/s]
(EngineCore pid=125) INFO 05-03 17:54:52 [gpu_model_runner.py:6133] Graph capturing finished in 1 secs, took 0.47 GiB
(EngineCore pid=125) INFO 05-03 17:54:52 [gpu_worker.py:599] CUDA graph pool memory: 0.47 GiB (actual), 0.47 GiB (estimated), difference: 0.01 GiB (1.1%).
(EngineCore pid=125) INFO 05-03 17:54:52 [core.py:299] init engine (profile, create kv cache, warmup model) took 149.80 s (compilation: 62.80 s)
(EngineCore pid=125) INFO 05-03 17:54:53 [vllm.py:840] Asynchronous scheduling is enabled.
(EngineCore pid=125) INFO 05-03 17:54:53 [kernel.py:205] Final IR op priority after setting platform defaults: IrOpPriorityConfig(rms_norm=['native'])
(EngineCore pid=125) INFO 05-03 17:54:53 [compilation.py:303] Enabled custom fusions: act_quant
(APIServer pid=1) INFO 05-03 17:54:53 [api_server.py:598] Supported tasks: ['generate']
(APIServer pid=1) WARNING 05-03 17:54:53 [model.py:1437] Default vLLM sampling parameters have been overridden by the model's `generation_config.json`: `{'temperature': 1.0, 'top_k': 20, 'top_p': 0.95}`. If this is not intended, please relaunch vLLM instance with `--generation-config vllm`.
(APIServer pid=1) INFO 05-03 17:54:58 [hf.py:314] Detected the chat template content format to be 'string'. You can set `--chat-template-content-format` to override this.
(APIServer pid=1) INFO 05-03 17:55:05 [base.py:233] Multi-modal warmup completed in 6.721s
(APIServer pid=1) INFO 05-03 17:55:12 [base.py:233] Readonly multi-modal warmup completed in 7.425s
(APIServer pid=1) INFO 05-03 17:55:13 [api_server.py:602] Starting vLLM server on http://0.0.0.0:8000
(APIServer pid=1) INFO 05-03 17:55:13 [launcher.py:37] Available routes are:
(APIServer pid=1) INFO 05-03 17:55:13 [launcher.py:46] Route: /openapi.json, Methods: GET, HEAD
(APIServer pid=1) INFO 05-03 17:55:13 [launcher.py:46] Route: /docs, Methods: GET, HEAD
(APIServer pid=1) INFO 05-03 17:55:13 [launcher.py:46] Route: /docs/oauth2-redirect, Methods: GET, HEAD
(APIServer pid=1) INFO 05-03 17:55:13 [launcher.py:46] Route: /redoc, Methods: GET, HEAD
(APIServer pid=1) INFO 05-03 17:55:13 [launcher.py:46] Route: /tokenize, Methods: POST
(APIServer pid=1) INFO 05-03 17:55:13 [launcher.py:46] Route: /detokenize, Methods: POST
(APIServer pid=1) INFO 05-03 17:55:13 [launcher.py:46] Route: /load, Methods: GET
(APIServer pid=1) INFO 05-03 17:55:13 [launcher.py:46] Route: /version, Methods: GET
(APIServer pid=1) INFO 05-03 17:55:13 [launcher.py:46] Route: /health, Methods: GET
(APIServer pid=1) INFO 05-03 17:55:13 [launcher.py:46] Route: /metrics, Methods: GET
(APIServer pid=1) INFO 05-03 17:55:13 [launcher.py:46] Route: /v1/models, Methods: GET
(APIServer pid=1) INFO 05-03 17:55:13 [launcher.py:46] Route: /ping, Methods: GET
(APIServer pid=1) INFO 05-03 17:55:13 [launcher.py:46] Route: /ping, Methods: POST
(APIServer pid=1) INFO 05-03 17:55:13 [launcher.py:46] Route: /invocations, Methods: POST
(APIServer pid=1) INFO 05-03 17:55:13 [launcher.py:46] Route: /v1/chat/completions, Methods: POST
(APIServer pid=1) INFO 05-03 17:55:13 [launcher.py:46] Route: /v1/chat/completions/batch, Methods: POST
(APIServer pid=1) INFO 05-03 17:55:13 [launcher.py:46] Route: /v1/responses, Methods: POST
(APIServer pid=1) INFO 05-03 17:55:13 [launcher.py:46] Route: /v1/responses/{response_id}, Methods: GET
(APIServer pid=1) INFO 05-03 17:55:13 [launcher.py:46] Route: /v1/responses/{response_id}/cancel, Methods: POST
(APIServer pid=1) INFO 05-03 17:55:13 [launcher.py:46] Route: /v1/completions, Methods: POST
(APIServer pid=1) INFO 05-03 17:55:13 [launcher.py:46] Route: /v1/messages, Methods: POST
(APIServer pid=1) INFO 05-03 17:55:13 [launcher.py:46] Route: /v1/messages/count_tokens, Methods: POST
(APIServer pid=1) INFO 05-03 17:55:13 [launcher.py:46] Route: /inference/v1/generate, Methods: POST
(APIServer pid=1) INFO 05-03 17:55:13 [launcher.py:46] Route: /scale_elastic_ep, Methods: POST
(APIServer pid=1) INFO 05-03 17:55:13 [launcher.py:46] Route: /is_scaling_elastic_ep, Methods: POST
(APIServer pid=1) INFO 05-03 17:55:13 [launcher.py:46] Route: /generative_scoring, Methods: POST
(APIServer pid=1) INFO 05-03 17:55:13 [launcher.py:46] Route: /v1/chat/completions/render, Methods: POST
(APIServer pid=1) INFO 05-03 17:55:13 [launcher.py:46] Route: /v1/completions/render, Methods: POST
(APIServer pid=1) INFO:     Started server process [1]
(APIServer pid=1) INFO:     Waiting for application startup.
(APIServer pid=1) INFO:     Application startup complete.
