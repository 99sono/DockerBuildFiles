2026-04-19 13:22:58.590 | WARNING 04-19 11:22:58 [interface.py:686] Using 'pin_memory=False' as WSL is detected. This may slow down the performance.
2026-04-19 13:22:58.684 | (APIServer pid=1) INFO 04-19 11:22:58 [utils.py:299] 
2026-04-19 13:22:58.684 | (APIServer pid=1) INFO 04-19 11:22:58 [utils.py:299]        █     █     █▄   ▄█
2026-04-19 13:22:58.684 | (APIServer pid=1) INFO 04-19 11:22:58 [utils.py:299]  ▄▄ ▄█ █     █     █ ▀▄▀ █  version 0.19.2rc1.dev8+g4b7f5ea1a
2026-04-19 13:22:58.684 | (APIServer pid=1) INFO 04-19 11:22:58 [utils.py:299]   █▄█▀ █     █     █     █  model   RedHatAI/gemma-4-26B-A4B-it-NVFP4
2026-04-19 13:22:58.684 | (APIServer pid=1) INFO 04-19 11:22:58 [utils.py:299]    ▀▀  ▀▀▀▀▀ ▀▀▀▀▀ ▀     ▀
2026-04-19 13:22:58.684 | (APIServer pid=1) INFO 04-19 11:22:58 [utils.py:299] 
2026-04-19 13:22:58.687 | (APIServer pid=1) INFO 04-19 11:22:58 [utils.py:233] non-default args: {'model_tag': 'RedHatAI/gemma-4-26B-A4B-it-NVFP4', 'tool_call_parser': 'gemma4', 'host': '0.0.0.0', 'model': 'RedHatAI/gemma-4-26B-A4B-it-NVFP4', 'trust_remote_code': True, 'max_model_len': 98304, 'quantization': 'compressed-tensors', 'served_model_name': ['gemma-4-26b-it-nvfp4'], 'reasoning_parser': 'gemma4', 'gpu_memory_utilization': 0.85, 'kv_cache_dtype': 'fp8_e4m3', 'enable_prefix_caching': True, 'max_num_batched_tokens': 8192, 'max_num_seqs': 2, 'enable_chunked_prefill': True, 'moe_backend': 'cutlass'}
2026-04-19 13:22:58.688 | (APIServer pid=1) WARNING 04-19 11:22:58 [envs.py:1785] Unknown vLLM environment variable detected: VLLM_ATTENTION_BACKEND
2026-04-19 13:22:59.095 | (APIServer pid=1) Warning: You are sending unauthenticated requests to the HF Hub. Please set a HF_TOKEN to enable higher rate limits and faster downloads.
2026-04-19 13:23:08.997 | (APIServer pid=1) INFO 04-19 11:23:08 [model.py:554] Resolved architecture: Gemma4ForConditionalGeneration
2026-04-19 13:23:08.997 | (APIServer pid=1) INFO 04-19 11:23:08 [model.py:1685] Using max model len 98304
2026-04-19 13:23:09.315 | (APIServer pid=1) INFO 04-19 11:23:09 [cache.py:247] Using fp8_e4m3 data type to store kv cache. It reduces the GPU memory footprint and boosts the performance. Meanwhile, it may cause accuracy drop without a proper scaling factor
2026-04-19 13:23:09.315 | (APIServer pid=1) INFO 04-19 11:23:09 [scheduler.py:239] Chunked prefill is enabled with max_num_batched_tokens=8192.
2026-04-19 13:23:09.316 | (APIServer pid=1) INFO 04-19 11:23:09 [config.py:101] Gemma4 model has heterogeneous head dimensions (head_dim=256, global_head_dim=512). Forcing TRITON_ATTN backend to prevent mixed-backend numerical divergence.
2026-04-19 13:23:09.316 | (APIServer pid=1) INFO 04-19 11:23:09 [vllm.py:834] Asynchronous scheduling is enabled.
2026-04-19 13:23:09.316 | (APIServer pid=1) INFO 04-19 11:23:09 [kernel.py:199] Final IR op priority after setting platform defaults: IrOpPriorityConfig(rms_norm=['native'])
2026-04-19 13:23:12.690 | (APIServer pid=1) INFO 04-19 11:23:12 [compilation.py:294] Enabled custom fusions: act_quant
2026-04-19 13:23:22.345 | (EngineCore pid=196) INFO 04-19 11:23:22 [core.py:107] Initializing a V1 LLM engine (v0.19.2rc1.dev8+g4b7f5ea1a) with config: model='RedHatAI/gemma-4-26B-A4B-it-NVFP4', speculative_config=None, tokenizer='RedHatAI/gemma-4-26B-A4B-it-NVFP4', skip_tokenizer_init=False, tokenizer_mode=auto, revision=None, tokenizer_revision=None, trust_remote_code=True, dtype=torch.bfloat16, max_seq_len=98304, download_dir=None, load_format=auto, tensor_parallel_size=1, pipeline_parallel_size=1, data_parallel_size=1, decode_context_parallel_size=1, dcp_comm_backend=ag_rs, disable_custom_all_reduce=False, quantization=compressed-tensors, quantization_config=None, enforce_eager=False, enable_return_routed_experts=False, kv_cache_dtype=fp8_e4m3, device_config=cuda, structured_outputs_config=StructuredOutputsConfig(backend='auto', disable_any_whitespace=False, disable_additional_properties=False, reasoning_parser='gemma4', reasoning_parser_plugin='', enable_in_reasoning=False), observability_config=ObservabilityConfig(show_hidden_metrics_for_version=None, otlp_traces_endpoint=None, collect_detailed_traces=None, kv_cache_metrics=False, kv_cache_metrics_sample=0.01, cudagraph_metrics=False, enable_layerwise_nvtx_tracing=False, enable_mfu_metrics=False, enable_mm_processor_stats=False, enable_logging_iteration_details=False), seed=0, served_model_name=gemma-4-26b-it-nvfp4, enable_prefix_caching=True, enable_chunked_prefill=True, pooler_config=None, compilation_config={'mode': <CompilationMode.VLLM_COMPILE: 3>, 'debug_dump_path': None, 'cache_dir': '', 'compile_cache_save_format': 'binary', 'backend': 'inductor', 'custom_ops': ['none'], 'ir_enable_torch_wrap': True, 'splitting_ops': ['vllm::unified_attention_with_output', 'vllm::unified_mla_attention_with_output', 'vllm::mamba_mixer2', 'vllm::mamba_mixer', 'vllm::short_conv', 'vllm::linear_attention', 'vllm::plamo2_mamba_mixer', 'vllm::gdn_attention_core', 'vllm::olmo_hybrid_gdn_full_forward', 'vllm::kda_attention', 'vllm::sparse_attn_indexer', 'vllm::rocm_aiter_sparse_attn_indexer', 'vllm::unified_kv_cache_update', 'vllm::unified_mla_kv_cache_update'], 'compile_mm_encoder': False, 'cudagraph_mm_encoder': False, 'encoder_cudagraph_token_budgets': [], 'encoder_cudagraph_max_vision_items_per_batch': 0, 'encoder_cudagraph_max_frames_per_batch': 0, 'compile_sizes': [], 'compile_ranges_endpoints': [8192], 'inductor_compile_config': {'enable_auto_functionalized_v2': False, 'size_asserts': False, 'alignment_asserts': False, 'scalar_asserts': False, 'combo_kernels': True, 'benchmark_combo_kernel': True}, 'inductor_passes': {}, 'cudagraph_mode': <CUDAGraphMode.FULL_AND_PIECEWISE: (2, 1)>, 'cudagraph_num_of_warmups': 1, 'cudagraph_capture_sizes': [1, 2, 4], 'cudagraph_copy_inputs': False, 'cudagraph_specialize_lora': True, 'use_inductor_graph_partition': False, 'pass_config': {'fuse_norm_quant': False, 'fuse_act_quant': True, 'fuse_attn_quant': False, 'enable_sp': False, 'fuse_gemm_comms': False, 'fuse_allreduce_rms': False}, 'max_cudagraph_capture_size': 4, 'dynamic_shapes_config': {'type': <DynamicShapesType.BACKED: 'backed'>, 'evaluate_guards': False, 'assume_32_bit_indexing': False}, 'local_cache_dir': None, 'fast_moe_cold_start': False, 'static_all_moe_layers': []}, kernel_config=KernelConfig(ir_op_priority=IrOpPriorityConfig(rms_norm=['native']), enable_flashinfer_autotune=True, moe_backend='cutlass')
2026-04-19 13:23:22.564 | (EngineCore pid=196) WARNING 04-19 11:23:22 [interface.py:686] Using 'pin_memory=False' as WSL is detected. This may slow down the performance.
2026-04-19 13:23:22.867 | (EngineCore pid=196) Warning: You are sending unauthenticated requests to the HF Hub. Please set a HF_TOKEN to enable higher rate limits and faster downloads.
2026-04-19 13:23:26.282 | (EngineCore pid=196) INFO 04-19 11:23:26 [parallel_state.py:1400] world_size=1 rank=0 local_rank=0 distributed_init_method=tcp://172.18.0.2:37235 backend=nccl
2026-04-19 13:23:26.587 | (EngineCore pid=196) INFO 04-19 11:23:26 [parallel_state.py:1713] rank 0 in world size 1 is assigned as DP rank 0, PP rank 0, PCP rank 0, TP rank 0, EP rank 0, EPLB rank N/A
2026-04-19 13:23:27.200 | (EngineCore pid=196) INFO 04-19 11:23:27 [gpu_model_runner.py:4752] Starting to load model RedHatAI/gemma-4-26B-A4B-it-NVFP4...
2026-04-19 13:23:27.647 | (EngineCore pid=196) INFO 04-19 11:23:27 [vllm.py:834] Asynchronous scheduling is enabled.
2026-04-19 13:23:27.648 | (EngineCore pid=196) INFO 04-19 11:23:27 [kernel.py:199] Final IR op priority after setting platform defaults: IrOpPriorityConfig(rms_norm=['native'])
2026-04-19 13:23:27.648 | (EngineCore pid=196) INFO 04-19 11:23:27 [compilation.py:294] Enabled custom fusions: act_quant
2026-04-19 13:23:27.659 | (EngineCore pid=196) INFO 04-19 11:23:27 [__init__.py:683] Using FlashInferCutlassNvFp4LinearKernel for NVFP4 GEMM
2026-04-19 13:23:27.693 | (EngineCore pid=196) INFO 04-19 11:23:27 [cuda.py:308] Using AttentionBackendEnum.TRITON_ATTN backend.
2026-04-19 13:23:27.714 | (EngineCore pid=196) INFO 04-19 11:23:27 [nvfp4.py:203] Using 'VLLM_CUTLASS' NvFp4 MoE backend out of potential backends: ['FLASHINFER_TRTLLM', 'FLASHINFER_CUTEDSL', 'FLASHINFER_CUTEDSL_BATCHED', 'FLASHINFER_CUTLASS', 'VLLM_CUTLASS', 'MARLIN'].
2026-04-19 13:23:27.775 | (EngineCore pid=196) INFO 04-19 11:23:27 [cuda.py:308] Using AttentionBackendEnum.TRITON_ATTN backend.
2026-04-19 13:23:28.569 | (EngineCore pid=196) <frozen importlib._bootstrap_external>:1301: FutureWarning: The cuda.cudart module is deprecated and will be removed in a future release, please switch to use the cuda.bindings.runtime module instead.
2026-04-19 13:23:28.569 | (EngineCore pid=196) <frozen importlib._bootstrap_external>:1301: FutureWarning: The cuda.nvrtc module is deprecated and will be removed in a future release, please switch to use the cuda.bindings.nvrtc module instead.
2026-04-19 13:23:29.475 | (EngineCore pid=196) INFO 04-19 11:23:29 [weight_utils.py:904] Filesystem type for checkpoints: EXT4. Checkpoint size: 15.30 GiB. Available RAM: 56.55 GiB.
2026-04-19 13:23:29.475 | (EngineCore pid=196) INFO 04-19 11:23:29 [weight_utils.py:927] Auto-prefetch is disabled because the filesystem (EXT4) is not a recognized network FS (NFS/Lustre). If you want to force prefetching, start vLLM with --safetensors-load-strategy=prefetch.
2026-04-19 13:23:29.475 | (EngineCore pid=196) 
2026-04-19 13:23:29.475 | Loading safetensors checkpoint shards:   0% Completed | 0/1 [00:00<?, ?it/s]
2026-04-19 13:23:53.541 | (EngineCore pid=196) 
2026-04-19 13:23:53.541 | Loading safetensors checkpoint shards: 100% Completed | 1/1 [00:24<00:00, 24.06s/it]
2026-04-19 13:23:53.541 | (EngineCore pid=196) 
2026-04-19 13:23:53.541 | Loading safetensors checkpoint shards: 100% Completed | 1/1 [00:24<00:00, 24.07s/it]
2026-04-19 13:23:53.541 | (EngineCore pid=196) 
2026-04-19 13:23:54.240 | (EngineCore pid=196) INFO 04-19 11:23:54 [default_loader.py:384] Loading weights took 24.80 seconds
2026-04-19 13:23:54.414 | (EngineCore pid=196) INFO 04-19 11:23:54 [nvfp4.py:448] Using MoEPrepareAndFinalizeNoDPEPModular
2026-04-19 13:23:54.437 | (EngineCore pid=196) WARNING 04-19 11:23:54 [compressed_tensors_w4a4_nvfp4.py:97] In NVFP4 linear, the global scale for input or weight are different for parallel layers (e.g. q_proj, k_proj, v_proj). This  will likely result in reduced accuracy. Please verify the model accuracy. Consider using a checkpoint with a shared global NVFP4 scale for fused layers.
2026-04-19 13:23:55.057 | (EngineCore pid=196) INFO 04-19 11:23:55 [gpu_model_runner.py:4837] Model loading took 15.77 GiB memory and 27.208125 seconds
2026-04-19 13:23:55.306 | (EngineCore pid=196) INFO 04-19 11:23:55 [gpu_model_runner.py:5786] Encoder cache will be initialized with a budget of 8192 tokens, and profiled with 3 video items of the maximum feature size.
2026-04-19 13:24:10.951 | (EngineCore pid=196) /usr/local/lib/python3.12/dist-packages/transformers/tokenization_utils_base.py:2341: UserWarning: `max_length` is ignored when `padding`=`True` and there is no truncation strategy. To pad to max length, use `padding='max_length'`.
2026-04-19 13:24:10.951 | (EngineCore pid=196)   warnings.warn(
2026-04-19 13:24:11.606 | (EngineCore pid=196) WARNING 04-19 11:24:11 [op.py:236] Priority not set for op rms_norm, using native implementation.
2026-04-19 13:24:28.280 | (EngineCore pid=196) INFO 04-19 11:24:28 [backends.py:1077] Using cache directory: /root/.cache/vllm/torch_compile_cache/cbcca6dad7/rank_0_0/backbone for vLLM's torch.compile
2026-04-19 13:24:28.281 | (EngineCore pid=196) INFO 04-19 11:24:28 [backends.py:1137] Dynamo bytecode transform time: 11.15 s
2026-04-19 13:24:41.642 | (EngineCore pid=196) INFO 04-19 11:24:41 [backends.py:377] Cache the graph of compile range (1, 8192) for later use
2026-04-19 13:25:11.153 | (EngineCore pid=196) INFO 04-19 11:25:11 [backends.py:398] Compiling a graph for compile range (1, 8192) takes 41.93 s
2026-04-19 13:25:16.535 | (EngineCore pid=196) INFO 04-19 11:25:16 [decorators.py:665] saved AOT compiled function to /root/.cache/vllm/torch_compile_cache/torch_aot_compile/172412f502501fc0df29f1910dae7e61ae77e24cb9eab0eba428ec32d66b55b0/rank_0_0/model
2026-04-19 13:25:16.535 | (EngineCore pid=196) INFO 04-19 11:25:16 [monitor.py:48] torch.compile took 59.48 s in total
2026-04-19 13:25:18.652 | (EngineCore pid=196) INFO 04-19 11:25:18 [monitor.py:76] Initial profiling/warmup run took 2.12 s
2026-04-19 13:25:19.158 | (EngineCore pid=196) INFO 04-19 11:25:19 [kv_cache_utils.py:829] Overriding num_gpu_blocks=0 with num_gpu_blocks_override=4
2026-04-19 13:25:19.162 | (EngineCore pid=196) INFO 04-19 11:25:19 [gpu_model_runner.py:5916] Profiling CUDA graph memory: PIECEWISE=3 (largest=4), FULL=2 (largest=2)
2026-04-19 13:25:24.687 | (EngineCore pid=196) INFO 04-19 11:25:24 [gpu_model_runner.py:5995] Estimated CUDA graph memory: 0.26 GiB total
2026-04-19 13:25:25.137 | (EngineCore pid=196) INFO 04-19 11:25:25 [gpu_worker.py:436] Available KV cache memory: 9.08 GiB
2026-04-19 13:25:25.137 | (EngineCore pid=196) INFO 04-19 11:25:25 [gpu_worker.py:470] In v0.19, CUDA graph memory profiling will be enabled by default (VLLM_MEMORY_PROFILER_ESTIMATE_CUDAGRAPHS=1), which more accurately accounts for CUDA graph memory during KV cache allocation. To try it now, set VLLM_MEMORY_PROFILER_ESTIMATE_CUDAGRAPHS=1 and increase --gpu-memory-utilization from 0.8500 to 0.8582 to maintain the same effective KV cache size.
2026-04-19 13:25:25.137 | (EngineCore pid=196) INFO 04-19 11:25:25 [kv_cache_utils.py:1319] GPU KV cache size: 79,344 tokens
2026-04-19 13:25:25.137 | (EngineCore pid=196) INFO 04-19 11:25:25 [kv_cache_utils.py:1324] Maximum concurrency for 98,304 tokens per request: 5.00x
2026-04-19 13:25:25.203 | (EngineCore pid=196) 2026-04-19 11:25:25,203 - INFO - autotuner.py:446 - flashinfer.jit: [Autotuner]: Autotuning process starts ...
2026-04-19 13:25:26.892 | (EngineCore pid=196) 2026-04-19 11:25:26,891 - INFO - autotuner.py:455 - flashinfer.jit: [Autotuner]: Autotuning process ends
2026-04-19 13:25:27.727 | (EngineCore pid=196) 
2026-04-19 13:25:27.727 | Capturing CUDA graphs (mixed prefill-decode, PIECEWISE):   0%|          | 0/3 [00:00<?, ?it/s]
2026-04-19 13:25:27.727 | Capturing CUDA graphs (mixed prefill-decode, PIECEWISE):  33%|███▎      | 1/3 [00:00<00:00,  7.58it/s]
2026-04-19 13:25:27.727 | Capturing CUDA graphs (mixed prefill-decode, PIECEWISE):  67%|██████▋   | 2/3 [00:00<00:00,  7.65it/s]
2026-04-19 13:25:27.727 | Capturing CUDA graphs (mixed prefill-decode, PIECEWISE): 100%|██████████| 3/3 [00:00<00:00,  7.64it/s]
2026-04-19 13:25:27.727 | Capturing CUDA graphs (mixed prefill-decode, PIECEWISE): 100%|██████████| 3/3 [00:00<00:00,  7.63it/s]
2026-04-19 13:25:28.009 | (EngineCore pid=196) 
2026-04-19 13:25:28.009 | Capturing CUDA graphs (decode, FULL):   0%|          | 0/2 [00:00<?, ?it/s]
2026-04-19 13:25:28.009 | Capturing CUDA graphs (decode, FULL):  50%|█████     | 1/2 [00:00<00:00,  7.12it/s]
2026-04-19 13:25:28.009 | Capturing CUDA graphs (decode, FULL): 100%|██████████| 2/2 [00:00<00:00,  7.10it/s]
2026-04-19 13:25:28.009 | Capturing CUDA graphs (decode, FULL): 100%|██████████| 2/2 [00:00<00:00,  7.10it/s]
2026-04-19 13:25:28.455 | (EngineCore pid=196) INFO 04-19 11:25:28 [gpu_model_runner.py:6086] Graph capturing finished in 2 secs, took 0.25 GiB
2026-04-19 13:25:28.455 | (EngineCore pid=196) INFO 04-19 11:25:28 [gpu_worker.py:597] CUDA graph pool memory: 0.25 GiB (actual), 0.26 GiB (estimated), difference: 0.01 GiB (5.8%).
2026-04-19 13:25:28.534 | (EngineCore pid=196) INFO 04-19 11:25:28 [core.py:299] init engine (profile, create kv cache, warmup model) took 93.48 s (compilation: 53.07 s)
2026-04-19 13:25:29.047 | (EngineCore pid=196) INFO 04-19 11:25:29 [kernel.py:199] Final IR op priority after setting platform defaults: IrOpPriorityConfig(rms_norm=['native'])
2026-04-19 13:25:29.064 | (APIServer pid=1) INFO 04-19 11:25:29 [api_server.py:598] Supported tasks: ['generate']
2026-04-19 13:25:29.457 | (APIServer pid=1) WARNING 04-19 11:25:29 [model.py:1442] Default vLLM sampling parameters have been overridden by the model's `generation_config.json`: `{'temperature': 1.0, 'top_k': 64, 'top_p': 0.95}`. If this is not intended, please relaunch vLLM instance with `--generation-config vllm`.
2026-04-19 13:25:35.777 | (APIServer pid=1) INFO 04-19 11:25:35 [hf.py:314] Detected the chat template content format to be 'openai'. You can set `--chat-template-content-format` to override this.
2026-04-19 13:25:51.178 | (APIServer pid=1) /usr/local/lib/python3.12/dist-packages/transformers/tokenization_utils_base.py:2341: UserWarning: `max_length` is ignored when `padding`=`True` and there is no truncation strategy. To pad to max length, use `padding='max_length'`.
2026-04-19 13:25:51.178 | (APIServer pid=1)   warnings.warn(
2026-04-19 13:25:51.328 | (APIServer pid=1) INFO 04-19 11:25:51 [base.py:245] Multi-modal warmup completed in 15.477s
2026-04-19 13:25:51.586 | (APIServer pid=1) INFO 04-19 11:25:51 [api_server.py:602] Starting vLLM server on http://0.0.0.0:8000
2026-04-19 13:25:51.586 | (APIServer pid=1) INFO 04-19 11:25:51 [launcher.py:37] Available routes are:
2026-04-19 13:25:51.586 | (APIServer pid=1) INFO 04-19 11:25:51 [launcher.py:46] Route: /openapi.json, Methods: HEAD, GET
2026-04-19 13:25:51.586 | (APIServer pid=1) INFO 04-19 11:25:51 [launcher.py:46] Route: /docs, Methods: HEAD, GET
2026-04-19 13:25:51.586 | (APIServer pid=1) INFO 04-19 11:25:51 [launcher.py:46] Route: /docs/oauth2-redirect, Methods: HEAD, GET
2026-04-19 13:25:51.586 | (APIServer pid=1) INFO 04-19 11:25:51 [launcher.py:46] Route: /redoc, Methods: HEAD, GET
2026-04-19 13:25:51.586 | (APIServer pid=1) INFO 04-19 11:25:51 [launcher.py:46] Route: /tokenize, Methods: POST
2026-04-19 13:25:51.586 | (APIServer pid=1) INFO 04-19 11:25:51 [launcher.py:46] Route: /detokenize, Methods: POST
2026-04-19 13:25:51.586 | (APIServer pid=1) INFO 04-19 11:25:51 [launcher.py:46] Route: /load, Methods: GET
2026-04-19 13:25:51.586 | (APIServer pid=1) INFO 04-19 11:25:51 [launcher.py:46] Route: /version, Methods: GET
2026-04-19 13:25:51.586 | (APIServer pid=1) INFO 04-19 11:25:51 [launcher.py:46] Route: /health, Methods: GET
2026-04-19 13:25:51.586 | (APIServer pid=1) INFO 04-19 11:25:51 [launcher.py:46] Route: /metrics, Methods: GET
2026-04-19 13:25:51.586 | (APIServer pid=1) INFO 04-19 11:25:51 [launcher.py:46] Route: /v1/models, Methods: GET
2026-04-19 13:25:51.587 | (APIServer pid=1) INFO 04-19 11:25:51 [launcher.py:46] Route: /ping, Methods: GET
2026-04-19 13:25:51.587 | (APIServer pid=1) INFO 04-19 11:25:51 [launcher.py:46] Route: /ping, Methods: POST
2026-04-19 13:25:51.587 | (APIServer pid=1) INFO 04-19 11:25:51 [launcher.py:46] Route: /invocations, Methods: POST
2026-04-19 13:25:51.587 | (APIServer pid=1) INFO 04-19 11:25:51 [launcher.py:46] Route: /v1/chat/completions, Methods: POST
2026-04-19 13:25:51.587 | (APIServer pid=1) INFO 04-19 11:25:51 [launcher.py:46] Route: /v1/chat/completions/batch, Methods: POST
2026-04-19 13:25:51.587 | (APIServer pid=1) INFO 04-19 11:25:51 [launcher.py:46] Route: /v1/responses, Methods: POST
2026-04-19 13:25:51.587 | (APIServer pid=1) INFO 04-19 11:25:51 [launcher.py:46] Route: /v1/responses/{response_id}, Methods: GET
2026-04-19 13:25:51.587 | (APIServer pid=1) INFO 04-19 11:25:51 [launcher.py:46] Route: /v1/responses/{response_id}/cancel, Methods: POST
2026-04-19 13:25:51.587 | (APIServer pid=1) INFO 04-19 11:25:51 [launcher.py:46] Route: /v1/completions, Methods: POST
2026-04-19 13:25:51.587 | (APIServer pid=1) INFO 04-19 11:25:51 [launcher.py:46] Route: /v1/messages, Methods: POST
2026-04-19 13:25:51.587 | (APIServer pid=1) INFO 04-19 11:25:51 [launcher.py:46] Route: /v1/messages/count_tokens, Methods: POST
2026-04-19 13:25:51.587 | (APIServer pid=1) INFO 04-19 11:25:51 [launcher.py:46] Route: /inference/v1/generate, Methods: POST
2026-04-19 13:25:51.587 | (APIServer pid=1) INFO 04-19 11:25:51 [launcher.py:46] Route: /scale_elastic_ep, Methods: POST
2026-04-19 13:25:51.587 | (APIServer pid=1) INFO 04-19 11:25:51 [launcher.py:46] Route: /is_scaling_elastic_ep, Methods: POST
2026-04-19 13:25:51.587 | (APIServer pid=1) INFO 04-19 11:25:51 [launcher.py:46] Route: /generative_scoring, Methods: POST
2026-04-19 13:25:51.587 | (APIServer pid=1) INFO 04-19 11:25:51 [launcher.py:46] Route: /v1/chat/completions/render, Methods: POST
2026-04-19 13:25:51.587 | (APIServer pid=1) INFO 04-19 11:25:51 [launcher.py:46] Route: /v1/completions/render, Methods: POST
2026-04-19 13:25:51.670 | (APIServer pid=1) INFO:     Started server process [1]
2026-04-19 13:25:51.670 | (APIServer pid=1) INFO:     Waiting for application startup.
2026-04-19 13:25:51.937 | (APIServer pid=1) INFO:     Application startup complete.
2026-04-19 13:27:51.838 | (APIServer pid=1) INFO 04-19 11:27:51 [loggers.py:271] Engine 000: Avg prompt throughput: 10.8 tokens/s, Avg generation throughput: 0.5 tokens/s, Running: 1 reqs, Waiting: 0 reqs, GPU KV cache usage: 0.1%, Prefix cache hit rate: 0.0%
2026-04-19 13:27:53.013 | (APIServer pid=1) INFO:     172.18.0.1:53246 - "POST /v1/chat/completions HTTP/1.1" 200 OK
2026-04-19 13:28:01.838 | (APIServer pid=1) INFO 04-19 11:28:01 [loggers.py:271] Engine 000: Avg prompt throughput: 0.0 tokens/s, Avg generation throughput: 16.3 tokens/s, Running: 0 reqs, Waiting: 0 reqs, GPU KV cache usage: 0.0%, Prefix cache hit rate: 0.0%
2026-04-19 13:28:11.818 | (APIServer pid=1) INFO 04-19 11:28:11 [loggers.py:271] Engine 000: Avg prompt throughput: 0.0 tokens/s, Avg generation throughput: 0.0 tokens/s, Running: 0 reqs, Waiting: 0 reqs, GPU KV cache usage: 0.0%, Prefix cache hit rate: 0.0%
2026-04-19 13:28:37.773 | (APIServer pid=1) INFO:     172.18.0.1:47798 - "POST /v1/chat/completions HTTP/1.1" 200 OK
2026-04-19 13:28:41.795 | (APIServer pid=1) INFO 04-19 11:28:41 [loggers.py:271] Engine 000: Avg prompt throughput: 1.2 tokens/s, Avg generation throughput: 15.5 tokens/s, Running: 0 reqs, Waiting: 0 reqs, GPU KV cache usage: 0.0%, Prefix cache hit rate: 44.4%
2026-04-19 13:28:51.795 | (APIServer pid=1) INFO 04-19 11:28:51 [loggers.py:271] Engine 000: Avg prompt throughput: 0.0 tokens/s, Avg generation throughput: 0.0 tokens/s, Running: 0 reqs, Waiting: 0 reqs, GPU KV cache usage: 0.0%, Prefix cache hit rate: 44.4%
2026-04-19 13:38:51.140 | (APIServer pid=1) INFO:     172.18.0.1:54580 - "GET /v1/models HTTP/1.1" 200 OK
2026-04-19 13:38:58.875 | (APIServer pid=1) INFO:     172.18.0.1:46396 - "POST /v1/chat/completions HTTP/1.1" 200 OK
2026-04-19 13:39:01.398 | (APIServer pid=1) INFO 04-19 11:39:01 [loggers.py:271] Engine 000: Avg prompt throughput: 2686.8 tokens/s, Avg generation throughput: 14.9 tokens/s, Running: 1 reqs, Waiting: 0 reqs, GPU KV cache usage: 3.9%, Prefix cache hit rate: 0.4%
2026-04-19 13:39:11.378 | (APIServer pid=1) INFO 04-19 11:39:11 [loggers.py:271] Engine 000: Avg prompt throughput: 0.0 tokens/s, Avg generation throughput: 56.8 tokens/s, Running: 0 reqs, Waiting: 0 reqs, GPU KV cache usage: 0.0%, Prefix cache hit rate: 0.4%
2026-04-19 13:39:21.378 | (APIServer pid=1) INFO 04-19 11:39:21 [loggers.py:271] Engine 000: Avg prompt throughput: 0.0 tokens/s, Avg generation throughput: 0.0 tokens/s, Running: 0 reqs, Waiting: 0 reqs, GPU KV cache usage: 0.0%, Prefix cache hit rate: 0.4%
2026-04-19 13:39:39.068 | (APIServer pid=1) INFO:     172.18.0.1:37738 - "POST /v1/chat/completions HTTP/1.1" 200 OK
2026-04-19 13:39:41.362 | (APIServer pid=1) INFO:     172.18.0.1:37738 - "POST /v1/chat/completions HTTP/1.1" 200 OK
2026-04-19 13:39:41.367 | (APIServer pid=1) INFO 04-19 11:39:41 [loggers.py:271] Engine 000: Avg prompt throughput: 135.9 tokens/s, Avg generation throughput: 18.9 tokens/s, Running: 0 reqs, Waiting: 0 reqs, GPU KV cache usage: 0.0%, Prefix cache hit rate: 48.7%
2026-04-19 13:39:51.366 | (APIServer pid=1) INFO 04-19 11:39:51 [loggers.py:271] Engine 000: Avg prompt throughput: 156.4 tokens/s, Avg generation throughput: 115.0 tokens/s, Running: 1 reqs, Waiting: 0 reqs, GPU KV cache usage: 4.3%, Prefix cache hit rate: 64.8%
2026-04-19 13:39:57.162 | (APIServer pid=1) INFO:     172.18.0.1:55752 - "POST /v1/chat/completions HTTP/1.1" 200 OK
2026-04-19 13:40:01.367 | (APIServer pid=1) INFO 04-19 11:40:01 [loggers.py:271] Engine 000: Avg prompt throughput: 326.8 tokens/s, Avg generation throughput: 37.6 tokens/s, Running: 0 reqs, Waiting: 0 reqs, GPU KV cache usage: 0.0%, Prefix cache hit rate: 71.9%
2026-04-19 13:40:11.349 | (APIServer pid=1) INFO 04-19 11:40:11 [loggers.py:271] Engine 000: Avg prompt throughput: 0.0 tokens/s, Avg generation throughput: 0.0 tokens/s, Running: 0 reqs, Waiting: 0 reqs, GPU KV cache usage: 0.0%, Prefix cache hit rate: 71.9%
2026-04-19 13:40:47.422 | (APIServer pid=1) INFO:     172.18.0.1:50476 - "POST /v1/chat/completions HTTP/1.1" 200 OK
2026-04-19 13:40:51.339 | (APIServer pid=1) INFO 04-19 11:40:51 [loggers.py:271] Engine 000: Avg prompt throughput: 89.8 tokens/s, Avg generation throughput: 41.2 tokens/s, Running: 1 reqs, Waiting: 0 reqs, GPU KV cache usage: 4.7%, Prefix cache hit rate: 77.6%
2026-04-19 13:40:55.889 | (APIServer pid=1) INFO:     172.18.0.1:43234 - "POST /v1/chat/completions HTTP/1.1" 200 OK
2026-04-19 13:40:57.871 | (APIServer pid=1) INFO:     172.18.0.1:43234 - "POST /v1/chat/completions HTTP/1.1" 200 OK
2026-04-19 13:41:01.340 | (APIServer pid=1) INFO 04-19 11:41:01 [loggers.py:271] Engine 000: Avg prompt throughput: 325.0 tokens/s, Avg generation throughput: 28.0 tokens/s, Running: 0 reqs, Waiting: 0 reqs, GPU KV cache usage: 0.0%, Prefix cache hit rate: 83.4%
2026-04-19 13:41:11.328 | (APIServer pid=1) INFO 04-19 11:41:11 [loggers.py:271] Engine 000: Avg prompt throughput: 0.0 tokens/s, Avg generation throughput: 0.0 tokens/s, Running: 0 reqs, Waiting: 0 reqs, GPU KV cache usage: 0.0%, Prefix cache hit rate: 83.4%