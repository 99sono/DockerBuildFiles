2026-04-19 17:30:52.611 | WARNING 04-19 15:30:52 [interface.py:686] Using 'pin_memory=False' as WSL is detected. This may slow down the performance.
2026-04-19 17:30:52.704 | (APIServer pid=1) INFO 04-19 15:30:52 [utils.py:299] 
2026-04-19 17:30:52.704 | (APIServer pid=1) INFO 04-19 15:30:52 [utils.py:299]        █     █     █▄   ▄█
2026-04-19 17:30:52.704 | (APIServer pid=1) INFO 04-19 15:30:52 [utils.py:299]  ▄▄ ▄█ █     █     █ ▀▄▀ █  version 0.19.2rc1.dev8+g4b7f5ea1a
2026-04-19 17:30:52.704 | (APIServer pid=1) INFO 04-19 15:30:52 [utils.py:299]   █▄█▀ █     █     █     █  model   RedHatAI/gemma-4-26B-A4B-it-NVFP4
2026-04-19 17:30:52.704 | (APIServer pid=1) INFO 04-19 15:30:52 [utils.py:299]    ▀▀  ▀▀▀▀▀ ▀▀▀▀▀ ▀     ▀
2026-04-19 17:30:52.704 | (APIServer pid=1) INFO 04-19 15:30:52 [utils.py:299] 
2026-04-19 17:30:52.706 | (APIServer pid=1) INFO 04-19 15:30:52 [utils.py:233] non-default args: {'model_tag': 'RedHatAI/gemma-4-26B-A4B-it-NVFP4', 'tool_call_parser': 'gemma4', 'host': '0.0.0.0', 'model': 'RedHatAI/gemma-4-26B-A4B-it-NVFP4', 'trust_remote_code': True, 'max_model_len': 98304, 'quantization': 'compressed-tensors', 'served_model_name': ['gemma-4-26b-it-nvfp4'], 'reasoning_parser': 'gemma4', 'gpu_memory_utilization': 0.82, 'kv_cache_dtype': 'fp8_e4m3', 'enable_prefix_caching': True, 'max_num_batched_tokens': 8192, 'max_num_seqs': 2, 'enable_chunked_prefill': True, 'moe_backend': 'cutlass', 'speculative_config': {'method': 'eagle', 'model': 'RedHatAI/gemma-4-26B-A4B-it-speculator.eagle3', 'num_speculative_tokens': 3}}
2026-04-19 17:30:52.707 | (APIServer pid=1) WARNING 04-19 15:30:52 [envs.py:1785] Unknown vLLM environment variable detected: VLLM_ATTENTION_BACKEND
2026-04-19 17:30:53.114 | (APIServer pid=1) Warning: You are sending unauthenticated requests to the HF Hub. Please set a HF_TOKEN to enable higher rate limits and faster downloads.
2026-04-19 17:31:03.073 | (APIServer pid=1) INFO 04-19 15:31:03 [model.py:554] Resolved architecture: Gemma4ForConditionalGeneration
2026-04-19 17:31:03.073 | (APIServer pid=1) INFO 04-19 15:31:03 [model.py:1685] Using max model len 98304
2026-04-19 17:31:03.394 | (APIServer pid=1) INFO 04-19 15:31:03 [cache.py:247] Using fp8_e4m3 data type to store kv cache. It reduces the GPU memory footprint and boosts the performance. Meanwhile, it may cause accuracy drop without a proper scaling factor
2026-04-19 17:31:10.944 | (APIServer pid=1) INFO 04-19 15:31:10 [model.py:554] Resolved architecture: Eagle3LlamaForCausalLM
2026-04-19 17:31:11.368 | (APIServer pid=1) INFO 04-19 15:31:11 [model.py:1685] Using max model len 262144
2026-04-19 17:31:11.380 | (APIServer pid=1) INFO 04-19 15:31:11 [scheduler.py:239] Chunked prefill is enabled with max_num_batched_tokens=8192.
2026-04-19 17:31:11.380 | (APIServer pid=1) INFO 04-19 15:31:11 [config.py:101] Gemma4 model has heterogeneous head dimensions (head_dim=256, global_head_dim=512). Forcing TRITON_ATTN backend to prevent mixed-backend numerical divergence.
2026-04-19 17:31:11.381 | (APIServer pid=1) INFO 04-19 15:31:11 [vllm.py:834] Asynchronous scheduling is enabled.
2026-04-19 17:31:11.381 | (APIServer pid=1) INFO 04-19 15:31:11 [kernel.py:199] Final IR op priority after setting platform defaults: IrOpPriorityConfig(rms_norm=['native'])
2026-04-19 17:31:14.679 | (APIServer pid=1) INFO 04-19 15:31:14 [compilation.py:294] Enabled custom fusions: act_quant
2026-04-19 17:31:23.914 | (EngineCore pid=263) INFO 04-19 15:31:23 [core.py:107] Initializing a V1 LLM engine (v0.19.2rc1.dev8+g4b7f5ea1a) with config: model='RedHatAI/gemma-4-26B-A4B-it-NVFP4', speculative_config=SpeculativeConfig(method='eagle', model='RedHatAI/gemma-4-26B-A4B-it-speculator.eagle3', num_spec_tokens=3), tokenizer='RedHatAI/gemma-4-26B-A4B-it-NVFP4', skip_tokenizer_init=False, tokenizer_mode=auto, revision=None, tokenizer_revision=None, trust_remote_code=True, dtype=torch.bfloat16, max_seq_len=98304, download_dir=None, load_format=auto, tensor_parallel_size=1, pipeline_parallel_size=1, data_parallel_size=1, decode_context_parallel_size=1, dcp_comm_backend=ag_rs, disable_custom_all_reduce=False, quantization=compressed-tensors, quantization_config=None, enforce_eager=False, enable_return_routed_experts=False, kv_cache_dtype=fp8_e4m3, device_config=cuda, structured_outputs_config=StructuredOutputsConfig(backend='auto', disable_any_whitespace=False, disable_additional_properties=False, reasoning_parser='gemma4', reasoning_parser_plugin='', enable_in_reasoning=False), observability_config=ObservabilityConfig(show_hidden_metrics_for_version=None, otlp_traces_endpoint=None, collect_detailed_traces=None, kv_cache_metrics=False, kv_cache_metrics_sample=0.01, cudagraph_metrics=False, enable_layerwise_nvtx_tracing=False, enable_mfu_metrics=False, enable_mm_processor_stats=False, enable_logging_iteration_details=False), seed=0, served_model_name=gemma-4-26b-it-nvfp4, enable_prefix_caching=True, enable_chunked_prefill=True, pooler_config=None, compilation_config={'mode': <CompilationMode.VLLM_COMPILE: 3>, 'debug_dump_path': None, 'cache_dir': '', 'compile_cache_save_format': 'binary', 'backend': 'inductor', 'custom_ops': ['none'], 'ir_enable_torch_wrap': True, 'splitting_ops': ['vllm::unified_attention_with_output', 'vllm::unified_mla_attention_with_output', 'vllm::mamba_mixer2', 'vllm::mamba_mixer', 'vllm::short_conv', 'vllm::linear_attention', 'vllm::plamo2_mamba_mixer', 'vllm::gdn_attention_core', 'vllm::olmo_hybrid_gdn_full_forward', 'vllm::kda_attention', 'vllm::sparse_attn_indexer', 'vllm::rocm_aiter_sparse_attn_indexer', 'vllm::unified_kv_cache_update', 'vllm::unified_mla_kv_cache_update'], 'compile_mm_encoder': False, 'cudagraph_mm_encoder': False, 'encoder_cudagraph_token_budgets': [], 'encoder_cudagraph_max_vision_items_per_batch': 0, 'encoder_cudagraph_max_frames_per_batch': 0, 'compile_sizes': [], 'compile_ranges_endpoints': [8192], 'inductor_compile_config': {'enable_auto_functionalized_v2': False, 'size_asserts': False, 'alignment_asserts': False, 'scalar_asserts': False, 'combo_kernels': True, 'benchmark_combo_kernel': True}, 'inductor_passes': {}, 'cudagraph_mode': <CUDAGraphMode.FULL_AND_PIECEWISE: (2, 1)>, 'cudagraph_num_of_warmups': 1, 'cudagraph_capture_sizes': [1, 2, 4, 8, 16], 'cudagraph_copy_inputs': False, 'cudagraph_specialize_lora': True, 'use_inductor_graph_partition': False, 'pass_config': {'fuse_norm_quant': False, 'fuse_act_quant': True, 'fuse_attn_quant': False, 'enable_sp': False, 'fuse_gemm_comms': False, 'fuse_allreduce_rms': False}, 'max_cudagraph_capture_size': 16, 'dynamic_shapes_config': {'type': <DynamicShapesType.BACKED: 'backed'>, 'evaluate_guards': False, 'assume_32_bit_indexing': False}, 'local_cache_dir': None, 'fast_moe_cold_start': False, 'static_all_moe_layers': []}, kernel_config=KernelConfig(ir_op_priority=IrOpPriorityConfig(rms_norm=['native']), enable_flashinfer_autotune=True, moe_backend='cutlass')
2026-04-19 17:31:24.118 | (EngineCore pid=263) WARNING 04-19 15:31:24 [interface.py:686] Using 'pin_memory=False' as WSL is detected. This may slow down the performance.
2026-04-19 17:31:24.403 | (EngineCore pid=263) Warning: You are sending unauthenticated requests to the HF Hub. Please set a HF_TOKEN to enable higher rate limits and faster downloads.
2026-04-19 17:31:27.805 | (EngineCore pid=263) INFO 04-19 15:31:27 [parallel_state.py:1400] world_size=1 rank=0 local_rank=0 distributed_init_method=tcp://172.18.0.2:33255 backend=nccl
2026-04-19 17:31:28.127 | (EngineCore pid=263) INFO 04-19 15:31:28 [parallel_state.py:1713] rank 0 in world size 1 is assigned as DP rank 0, PP rank 0, PCP rank 0, TP rank 0, EP rank 0, EPLB rank N/A
2026-04-19 17:31:28.779 | (EngineCore pid=263) WARNING 04-19 15:31:28 [__init__.py:206] min_p and logit_bias parameters won't work with speculative decoding.
2026-04-19 17:31:28.800 | (EngineCore pid=263) INFO 04-19 15:31:28 [gpu_model_runner.py:4752] Starting to load model RedHatAI/gemma-4-26B-A4B-it-NVFP4...
2026-04-19 17:31:29.269 | (EngineCore pid=263) INFO 04-19 15:31:29 [vllm.py:834] Asynchronous scheduling is enabled.
2026-04-19 17:31:29.270 | (EngineCore pid=263) INFO 04-19 15:31:29 [kernel.py:199] Final IR op priority after setting platform defaults: IrOpPriorityConfig(rms_norm=['native'])
2026-04-19 17:31:29.271 | (EngineCore pid=263) INFO 04-19 15:31:29 [compilation.py:294] Enabled custom fusions: act_quant
2026-04-19 17:31:29.280 | (EngineCore pid=263) INFO 04-19 15:31:29 [__init__.py:683] Using FlashInferCutlassNvFp4LinearKernel for NVFP4 GEMM
2026-04-19 17:31:29.320 | (EngineCore pid=263) INFO 04-19 15:31:29 [cuda.py:308] Using AttentionBackendEnum.TRITON_ATTN backend.
2026-04-19 17:31:29.339 | (EngineCore pid=263) INFO 04-19 15:31:29 [nvfp4.py:203] Using 'VLLM_CUTLASS' NvFp4 MoE backend out of potential backends: ['FLASHINFER_TRTLLM', 'FLASHINFER_CUTEDSL', 'FLASHINFER_CUTEDSL_BATCHED', 'FLASHINFER_CUTLASS', 'VLLM_CUTLASS', 'MARLIN'].
2026-04-19 17:31:29.396 | (EngineCore pid=263) INFO 04-19 15:31:29 [cuda.py:308] Using AttentionBackendEnum.TRITON_ATTN backend.
2026-04-19 17:31:30.311 | (EngineCore pid=263) <frozen importlib._bootstrap_external>:1301: FutureWarning: The cuda.cudart module is deprecated and will be removed in a future release, please switch to use the cuda.bindings.runtime module instead.
2026-04-19 17:31:30.311 | (EngineCore pid=263) <frozen importlib._bootstrap_external>:1301: FutureWarning: The cuda.nvrtc module is deprecated and will be removed in a future release, please switch to use the cuda.bindings.nvrtc module instead.
2026-04-19 17:31:31.130 | (EngineCore pid=263) INFO 04-19 15:31:31 [weight_utils.py:904] Filesystem type for checkpoints: EXT4. Checkpoint size: 15.30 GiB. Available RAM: 55.52 GiB.
2026-04-19 17:31:31.130 | (EngineCore pid=263) INFO 04-19 15:31:31 [weight_utils.py:927] Auto-prefetch is disabled because the filesystem (EXT4) is not a recognized network FS (NFS/Lustre). If you want to force prefetching, start vLLM with --safetensors-load-strategy=prefetch.
2026-04-19 17:31:31.131 | (EngineCore pid=263) 
2026-04-19 17:31:31.131 | Loading safetensors checkpoint shards:   0% Completed | 0/1 [00:00<?, ?it/s]
2026-04-19 17:31:55.825 | (EngineCore pid=263) 
2026-04-19 17:31:55.825 | Loading safetensors checkpoint shards: 100% Completed | 1/1 [00:24<00:00, 24.69s/it]
2026-04-19 17:31:55.825 | (EngineCore pid=263) 
2026-04-19 17:31:55.825 | Loading safetensors checkpoint shards: 100% Completed | 1/1 [00:24<00:00, 24.69s/it]
2026-04-19 17:31:55.825 | (EngineCore pid=263) 
2026-04-19 17:31:56.525 | (EngineCore pid=263) INFO 04-19 15:31:56 [default_loader.py:384] Loading weights took 25.25 seconds
2026-04-19 17:31:56.733 | (EngineCore pid=263) INFO 04-19 15:31:56 [nvfp4.py:448] Using MoEPrepareAndFinalizeNoDPEPModular
2026-04-19 17:31:56.771 | (EngineCore pid=263) WARNING 04-19 15:31:56 [compressed_tensors_w4a4_nvfp4.py:97] In NVFP4 linear, the global scale for input or weight are different for parallel layers (e.g. q_proj, k_proj, v_proj). This  will likely result in reduced accuracy. Please verify the model accuracy. Consider using a checkpoint with a shared global NVFP4 scale for fused layers.
2026-04-19 17:31:56.941 | (EngineCore pid=263) INFO 04-19 15:31:56 [gpu_model_runner.py:4776] Loading drafter model...
2026-04-19 17:31:57.587 | (EngineCore pid=263) INFO 04-19 15:31:57 [weight_utils.py:659] No model.safetensors.index.json found in remote.
2026-04-19 17:31:57.588 | (EngineCore pid=263) INFO 04-19 15:31:57 [weight_utils.py:904] Filesystem type for checkpoints: EXT4. Checkpoint size: 1.73 GiB. Available RAM: 55.38 GiB.
2026-04-19 17:31:57.588 | (EngineCore pid=263) 
2026-04-19 17:31:57.588 | Loading safetensors checkpoint shards:   0% Completed | 0/1 [00:00<?, ?it/s]
2026-04-19 17:31:57.596 | (EngineCore pid=263) 
2026-04-19 17:31:57.596 | Loading safetensors checkpoint shards: 100% Completed | 1/1 [00:00<00:00, 128.05it/s]
2026-04-19 17:31:57.596 | (EngineCore pid=263) 
2026-04-19 17:31:59.475 | (EngineCore pid=263) INFO 04-19 15:31:59 [default_loader.py:384] Loading weights took 1.89 seconds
2026-04-19 17:32:03.076 | (EngineCore pid=263) INFO 04-19 15:32:03 [eagle.py:1412] Detected EAGLE model with embed_tokens identical to the target model. Sharing target model embedding weights with the draft model.
2026-04-19 17:32:04.325 | (EngineCore pid=263) INFO 04-19 15:32:04 [eagle.py:1474] Detected EAGLE model with distinct lm_head weights. Keeping separate lm_head weights from the target model.
2026-04-19 17:32:04.824 | (EngineCore pid=263) INFO 04-19 15:32:04 [gpu_model_runner.py:4837] Model loading took 16.12 GiB memory and 35.183543 seconds
2026-04-19 17:32:05.064 | (EngineCore pid=263) INFO 04-19 15:32:05 [gpu_model_runner.py:5786] Encoder cache will be initialized with a budget of 8192 tokens, and profiled with 3 video items of the maximum feature size.
2026-04-19 17:32:20.878 | (EngineCore pid=263) /usr/local/lib/python3.12/dist-packages/transformers/tokenization_utils_base.py:2341: UserWarning: `max_length` is ignored when `padding`=`True` and there is no truncation strategy. To pad to max length, use `padding='max_length'`.
2026-04-19 17:32:20.878 | (EngineCore pid=263)   warnings.warn(
2026-04-19 17:32:21.534 | (EngineCore pid=263) WARNING 04-19 15:32:21 [op.py:236] Priority not set for op rms_norm, using native implementation.
2026-04-19 17:32:38.491 | (EngineCore pid=263) INFO 04-19 15:32:38 [backends.py:1077] Using cache directory: /root/.cache/vllm/torch_compile_cache/0f768fd1b9/rank_0_0/backbone for vLLM's torch.compile
2026-04-19 17:32:38.491 | (EngineCore pid=263) INFO 04-19 15:32:38 [backends.py:1137] Dynamo bytecode transform time: 11.21 s
2026-04-19 17:32:52.043 | (EngineCore pid=263) INFO 04-19 15:32:52 [backends.py:377] Cache the graph of compile range (1, 8192) for later use
2026-04-19 17:33:22.508 | (EngineCore pid=263) INFO 04-19 15:33:22 [backends.py:398] Compiling a graph for compile range (1, 8192) takes 42.88 s
2026-04-19 17:33:28.495 | (EngineCore pid=263) INFO 04-19 15:33:28 [decorators.py:665] saved AOT compiled function to /root/.cache/vllm/torch_compile_cache/torch_aot_compile/67f763c129f1064972f2ce5cefb254390fbe96f7293a9ff96f44ca3f69ab0d25/rank_0_0/model
2026-04-19 17:33:28.495 | (EngineCore pid=263) INFO 04-19 15:33:28 [monitor.py:48] torch.compile took 61.09 s in total
2026-04-19 17:33:30.621 | (EngineCore pid=263) INFO 04-19 15:33:30 [monitor.py:76] Initial profiling/warmup run took 2.13 s
2026-04-19 17:33:31.118 | (EngineCore pid=263) INFO 04-19 15:33:31 [backends.py:1077] Using cache directory: /root/.cache/vllm/torch_compile_cache/0f768fd1b9/rank_0_0/eagle_head for vLLM's torch.compile
2026-04-19 17:33:31.119 | (EngineCore pid=263) INFO 04-19 15:33:31 [backends.py:1137] Dynamo bytecode transform time: 0.49 s
2026-04-19 17:33:36.493 | (EngineCore pid=263) INFO 04-19 15:33:36 [backends.py:398] Compiling a graph for compile range (1, 8192) takes 5.16 s
2026-04-19 17:33:36.669 | (EngineCore pid=263) INFO 04-19 15:33:36 [decorators.py:665] saved AOT compiled function to /root/.cache/vllm/torch_compile_cache/torch_aot_compile/e139bfae108e31a22bbf25550003da278f670a4a06b1f7a5d3c3e3601a7acbb9/rank_0_0/model
2026-04-19 17:33:36.669 | (EngineCore pid=263) INFO 04-19 15:33:36 [monitor.py:48] torch.compile took 6.05 s in total
2026-04-19 17:33:36.882 | (EngineCore pid=263) INFO 04-19 15:33:36 [monitor.py:76] Initial profiling/warmup run took 0.21 s
2026-04-19 17:33:38.693 | (EngineCore pid=263) INFO 04-19 15:33:38 [kv_cache_utils.py:829] Overriding num_gpu_blocks=0 with num_gpu_blocks_override=16
2026-04-19 17:33:38.700 | (EngineCore pid=263) INFO 04-19 15:33:38 [gpu_model_runner.py:5916] Profiling CUDA graph memory: PIECEWISE=3 (largest=16), FULL=2 (largest=8)
2026-04-19 17:33:43.496 | (EngineCore pid=263) INFO 04-19 15:33:43 [gpu_model_runner.py:5995] Estimated CUDA graph memory: 0.27 GiB total
2026-04-19 17:33:43.953 | (EngineCore pid=263) INFO 04-19 15:33:43 [gpu_worker.py:436] Available KV cache memory: 7.77 GiB
2026-04-19 17:33:43.953 | (EngineCore pid=263) INFO 04-19 15:33:43 [gpu_worker.py:470] In v0.19, CUDA graph memory profiling will be enabled by default (VLLM_MEMORY_PROFILER_ESTIMATE_CUDAGRAPHS=1), which more accurately accounts for CUDA graph memory during KV cache allocation. To try it now, set VLLM_MEMORY_PROFILER_ESTIMATE_CUDAGRAPHS=1 and increase --gpu-memory-utilization from 0.8200 to 0.8283 to maintain the same effective KV cache size.
2026-04-19 17:33:43.954 | (EngineCore pid=263) INFO 04-19 15:33:43 [kv_cache_utils.py:1319] GPU KV cache size: 65,696 tokens
2026-04-19 17:33:43.954 | (EngineCore pid=263) INFO 04-19 15:33:43 [kv_cache_utils.py:1324] Maximum concurrency for 98,304 tokens per request: 3.54x
2026-04-19 17:33:44.001 | (EngineCore pid=263) 2026-04-19 15:33:44,000 - INFO - autotuner.py:446 - flashinfer.jit: [Autotuner]: Autotuning process starts ...
2026-04-19 17:33:45.771 | (EngineCore pid=263) 2026-04-19 15:33:45,771 - INFO - autotuner.py:455 - flashinfer.jit: [Autotuner]: Autotuning process ends
2026-04-19 17:33:46.642 | (EngineCore pid=263) 
2026-04-19 17:33:46.642 | Capturing CUDA graphs (mixed prefill-decode, PIECEWISE):   0%|          | 0/3 [00:00<?, ?it/s]
2026-04-19 17:33:46.642 | Capturing CUDA graphs (mixed prefill-decode, PIECEWISE):  33%|███▎      | 1/3 [00:00<00:00,  7.30it/s]
2026-04-19 17:33:46.642 | Capturing CUDA graphs (mixed prefill-decode, PIECEWISE):  67%|██████▋   | 2/3 [00:00<00:00,  7.22it/s]
2026-04-19 17:33:46.642 | Capturing CUDA graphs (mixed prefill-decode, PIECEWISE): 100%|██████████| 3/3 [00:00<00:00,  7.44it/s]
2026-04-19 17:33:46.642 | Capturing CUDA graphs (mixed prefill-decode, PIECEWISE): 100%|██████████| 3/3 [00:00<00:00,  7.38it/s]
2026-04-19 17:33:46.918 | (EngineCore pid=263) 
2026-04-19 17:33:46.918 | Capturing CUDA graphs (decode, FULL):   0%|          | 0/2 [00:00<?, ?it/s]
2026-04-19 17:33:46.918 | Capturing CUDA graphs (decode, FULL):  50%|█████     | 1/2 [00:00<00:00,  7.53it/s]
2026-04-19 17:33:46.918 | Capturing CUDA graphs (decode, FULL): 100%|██████████| 2/2 [00:00<00:00,  7.21it/s]
2026-04-19 17:33:46.918 | Capturing CUDA graphs (decode, FULL): 100%|██████████| 2/2 [00:00<00:00,  7.25it/s]
2026-04-19 17:33:47.361 | (EngineCore pid=263) INFO 04-19 15:33:47 [gpu_model_runner.py:6086] Graph capturing finished in 2 secs, took 0.24 GiB
2026-04-19 17:33:47.361 | (EngineCore pid=263) INFO 04-19 15:33:47 [gpu_worker.py:597] CUDA graph pool memory: 0.24 GiB (actual), 0.27 GiB (estimated), difference: 0.03 GiB (11.2%).
2026-04-19 17:33:47.438 | (EngineCore pid=263) INFO 04-19 15:33:47 [core.py:299] init engine (profile, create kv cache, warmup model) took 102.61 s (compilation: 59.75 s)
2026-04-19 17:33:48.009 | (EngineCore pid=263) INFO 04-19 15:33:48 [kernel.py:199] Final IR op priority after setting platform defaults: IrOpPriorityConfig(rms_norm=['native'])
2026-04-19 17:33:48.018 | (APIServer pid=1) INFO 04-19 15:33:48 [api_server.py:598] Supported tasks: ['generate']
2026-04-19 17:33:48.372 | (APIServer pid=1) WARNING 04-19 15:33:48 [model.py:1442] Default vLLM sampling parameters have been overridden by the model's `generation_config.json`: `{'temperature': 1.0, 'top_k': 64, 'top_p': 0.95}`. If this is not intended, please relaunch vLLM instance with `--generation-config vllm`.
2026-04-19 17:33:54.734 | (APIServer pid=1) INFO 04-19 15:33:54 [hf.py:314] Detected the chat template content format to be 'openai'. You can set `--chat-template-content-format` to override this.
2026-04-19 17:34:10.652 | (APIServer pid=1) /usr/local/lib/python3.12/dist-packages/transformers/tokenization_utils_base.py:2341: UserWarning: `max_length` is ignored when `padding`=`True` and there is no truncation strategy. To pad to max length, use `padding='max_length'`.
2026-04-19 17:34:10.652 | (APIServer pid=1)   warnings.warn(
2026-04-19 17:34:10.819 | (APIServer pid=1) INFO 04-19 15:34:10 [base.py:245] Multi-modal warmup completed in 15.934s
2026-04-19 17:34:11.073 | (APIServer pid=1) INFO 04-19 15:34:11 [api_server.py:602] Starting vLLM server on http://0.0.0.0:8000
2026-04-19 17:34:11.073 | (APIServer pid=1) INFO 04-19 15:34:11 [launcher.py:37] Available routes are:
2026-04-19 17:34:11.073 | (APIServer pid=1) INFO 04-19 15:34:11 [launcher.py:46] Route: /openapi.json, Methods: GET, HEAD
2026-04-19 17:34:11.073 | (APIServer pid=1) INFO 04-19 15:34:11 [launcher.py:46] Route: /docs, Methods: GET, HEAD
2026-04-19 17:34:11.073 | (APIServer pid=1) INFO 04-19 15:34:11 [launcher.py:46] Route: /docs/oauth2-redirect, Methods: GET, HEAD
2026-04-19 17:34:11.073 | (APIServer pid=1) INFO 04-19 15:34:11 [launcher.py:46] Route: /redoc, Methods: GET, HEAD
2026-04-19 17:34:11.073 | (APIServer pid=1) INFO 04-19 15:34:11 [launcher.py:46] Route: /tokenize, Methods: POST
2026-04-19 17:34:11.073 | (APIServer pid=1) INFO 04-19 15:34:11 [launcher.py:46] Route: /detokenize, Methods: POST
2026-04-19 17:34:11.073 | (APIServer pid=1) INFO 04-19 15:34:11 [launcher.py:46] Route: /load, Methods: GET
2026-04-19 17:34:11.073 | (APIServer pid=1) INFO 04-19 15:34:11 [launcher.py:46] Route: /version, Methods: GET
2026-04-19 17:34:11.073 | (APIServer pid=1) INFO 04-19 15:34:11 [launcher.py:46] Route: /health, Methods: GET
2026-04-19 17:34:11.073 | (APIServer pid=1) INFO 04-19 15:34:11 [launcher.py:46] Route: /metrics, Methods: GET
2026-04-19 17:34:11.073 | (APIServer pid=1) INFO 04-19 15:34:11 [launcher.py:46] Route: /v1/models, Methods: GET
2026-04-19 17:34:11.073 | (APIServer pid=1) INFO 04-19 15:34:11 [launcher.py:46] Route: /ping, Methods: GET
2026-04-19 17:34:11.073 | (APIServer pid=1) INFO 04-19 15:34:11 [launcher.py:46] Route: /ping, Methods: POST
2026-04-19 17:34:11.073 | (APIServer pid=1) INFO 04-19 15:34:11 [launcher.py:46] Route: /invocations, Methods: POST
2026-04-19 17:34:11.074 | (APIServer pid=1) INFO 04-19 15:34:11 [launcher.py:46] Route: /v1/chat/completions, Methods: POST
2026-04-19 17:34:11.074 | (APIServer pid=1) INFO 04-19 15:34:11 [launcher.py:46] Route: /v1/chat/completions/batch, Methods: POST
2026-04-19 17:34:11.074 | (APIServer pid=1) INFO 04-19 15:34:11 [launcher.py:46] Route: /v1/responses, Methods: POST
2026-04-19 17:34:11.074 | (APIServer pid=1) INFO 04-19 15:34:11 [launcher.py:46] Route: /v1/responses/{response_id}, Methods: GET
2026-04-19 17:34:11.074 | (APIServer pid=1) INFO 04-19 15:34:11 [launcher.py:46] Route: /v1/responses/{response_id}/cancel, Methods: POST
2026-04-19 17:34:11.074 | (APIServer pid=1) INFO 04-19 15:34:11 [launcher.py:46] Route: /v1/completions, Methods: POST
2026-04-19 17:34:11.074 | (APIServer pid=1) INFO 04-19 15:34:11 [launcher.py:46] Route: /v1/messages, Methods: POST
2026-04-19 17:34:11.074 | (APIServer pid=1) INFO 04-19 15:34:11 [launcher.py:46] Route: /v1/messages/count_tokens, Methods: POST
2026-04-19 17:34:11.074 | (APIServer pid=1) INFO 04-19 15:34:11 [launcher.py:46] Route: /inference/v1/generate, Methods: POST
2026-04-19 17:34:11.074 | (APIServer pid=1) INFO 04-19 15:34:11 [launcher.py:46] Route: /scale_elastic_ep, Methods: POST
2026-04-19 17:34:11.074 | (APIServer pid=1) INFO 04-19 15:34:11 [launcher.py:46] Route: /is_scaling_elastic_ep, Methods: POST
2026-04-19 17:34:11.074 | (APIServer pid=1) INFO 04-19 15:34:11 [launcher.py:46] Route: /generative_scoring, Methods: POST
2026-04-19 17:34:11.074 | (APIServer pid=1) INFO 04-19 15:34:11 [launcher.py:46] Route: /v1/chat/completions/render, Methods: POST
2026-04-19 17:34:11.074 | (APIServer pid=1) INFO 04-19 15:34:11 [launcher.py:46] Route: /v1/completions/render, Methods: POST
2026-04-19 17:34:11.166 | (APIServer pid=1) INFO:     Started server process [1]
2026-04-19 17:34:11.166 | (APIServer pid=1) INFO:     Waiting for application startup.
2026-04-19 17:34:11.437 | (APIServer pid=1) INFO:     Application startup complete.
2026-04-19 17:36:34.226 | (APIServer pid=1) INFO:     172.18.0.1:49422 - "POST /v1/chat/completions HTTP/1.1" 200 OK
2026-04-19 17:36:42.061 | (APIServer pid=1) INFO 04-19 15:36:42 [loggers.py:271] Engine 000: Avg prompt throughput: 2085.2 tokens/s, Avg generation throughput: 14.3 tokens/s, Running: 1 reqs, Waiting: 0 reqs, GPU KV cache usage: 4.9%, Prefix cache hit rate: 0.0%
2026-04-19 17:36:42.061 | (APIServer pid=1) INFO 04-19 15:36:42 [metrics.py:101] SpecDecoding metrics: Mean acceptance length: 1.00, Accepted throughput: 0.00 tokens/s, Drafted throughput: 2.46 tokens/s, Accepted: 0 tokens, Drafted: 426 tokens, Per-position acceptance rate: 0.000, 0.000, 0.000, Avg Draft acceptance rate: 0.0%
2026-04-19 17:36:47.575 | (APIServer pid=1) INFO:     172.18.0.1:49422 - "POST /v1/chat/completions HTTP/1.1" 200 OK
2026-04-19 17:36:52.062 | (APIServer pid=1) INFO 04-19 15:36:52 [loggers.py:271] Engine 000: Avg prompt throughput: 4682.7 tokens/s, Avg generation throughput: 24.9 tokens/s, Running: 1 reqs, Waiting: 0 reqs, GPU KV cache usage: 9.3%, Prefix cache hit rate: 0.0%
2026-04-19 17:36:52.062 | (APIServer pid=1) INFO 04-19 15:36:52 [metrics.py:101] SpecDecoding metrics: Mean acceptance length: 1.00, Accepted throughput: 0.10 tokens/s, Drafted throughput: 74.09 tokens/s, Accepted: 1 tokens, Drafted: 741 tokens, Per-position acceptance rate: 0.004, 0.000, 0.000, Avg Draft acceptance rate: 0.1%
2026-04-19 17:37:02.062 | (APIServer pid=1) INFO 04-19 15:37:02 [loggers.py:271] Engine 000: Avg prompt throughput: 0.0 tokens/s, Avg generation throughput: 30.9 tokens/s, Running: 1 reqs, Waiting: 0 reqs, GPU KV cache usage: 9.4%, Prefix cache hit rate: 0.0%
2026-04-19 17:37:02.062 | (APIServer pid=1) INFO 04-19 15:37:02 [metrics.py:101] SpecDecoding metrics: Mean acceptance length: 1.03, Accepted throughput: 0.80 tokens/s, Drafted throughput: 90.30 tokens/s, Accepted: 8 tokens, Drafted: 903 tokens, Per-position acceptance rate: 0.027, 0.000, 0.000, Avg Draft acceptance rate: 0.9%
2026-04-19 17:37:04.366 | (APIServer pid=1) INFO:     172.18.0.1:49422 - "POST /v1/chat/completions HTTP/1.1" 200 OK
2026-04-19 17:37:12.198 | (APIServer pid=1) INFO 04-19 15:37:12 [loggers.py:271] Engine 000: Avg prompt throughput: 6906.9 tokens/s, Avg generation throughput: 10.2 tokens/s, Running: 1 reqs, Waiting: 0 reqs, GPU KV cache usage: 13.2%, Prefix cache hit rate: 0.0%
2026-04-19 17:37:12.198 | (APIServer pid=1) INFO 04-19 15:37:12 [metrics.py:101] SpecDecoding metrics: Mean acceptance length: 1.00, Accepted throughput: 0.00 tokens/s, Drafted throughput: 30.30 tokens/s, Accepted: 0 tokens, Drafted: 303 tokens, Per-position acceptance rate: 0.000, 0.000, 0.000, Avg Draft acceptance rate: 0.0%
2026-04-19 17:37:22.199 | (APIServer pid=1) INFO 04-19 15:37:22 [loggers.py:271] Engine 000: Avg prompt throughput: 0.0 tokens/s, Avg generation throughput: 24.5 tokens/s, Running: 1 reqs, Waiting: 0 reqs, GPU KV cache usage: 13.2%, Prefix cache hit rate: 0.0%
2026-04-19 17:37:22.199 | (APIServer pid=1) INFO 04-19 15:37:22 [metrics.py:101] SpecDecoding metrics: Mean acceptance length: 1.01, Accepted throughput: 0.20 tokens/s, Drafted throughput: 72.89 tokens/s, Accepted: 2 tokens, Drafted: 729 tokens, Per-position acceptance rate: 0.008, 0.000, 0.000, Avg Draft acceptance rate: 0.3%
2026-04-19 17:37:32.199 | (APIServer pid=1) INFO 04-19 15:37:32 [loggers.py:271] Engine 000: Avg prompt throughput: 0.0 tokens/s, Avg generation throughput: 24.8 tokens/s, Running: 1 reqs, Waiting: 0 reqs, GPU KV cache usage: 13.2%, Prefix cache hit rate: 0.0%
2026-04-19 17:37:32.200 | (APIServer pid=1) INFO 04-19 15:37:32 [metrics.py:101] SpecDecoding metrics: Mean acceptance length: 1.00, Accepted throughput: 0.00 tokens/s, Drafted throughput: 74.40 tokens/s, Accepted: 0 tokens, Drafted: 744 tokens, Per-position acceptance rate: 0.000, 0.000, 0.000, Avg Draft acceptance rate: 0.0%
2026-04-19 17:37:42.320 | (APIServer pid=1) INFO 04-19 15:37:42 [loggers.py:271] Engine 000: Avg prompt throughput: 0.0 tokens/s, Avg generation throughput: 24.9 tokens/s, Running: 1 reqs, Waiting: 0 reqs, GPU KV cache usage: 13.3%, Prefix cache hit rate: 0.0%
2026-04-19 17:37:42.320 | (APIServer pid=1) INFO 04-19 15:37:42 [metrics.py:101] SpecDecoding metrics: Mean acceptance length: 1.00, Accepted throughput: 0.00 tokens/s, Drafted throughput: 74.70 tokens/s, Accepted: 0 tokens, Drafted: 747 tokens, Per-position acceptance rate: 0.000, 0.000, 0.000, Avg Draft acceptance rate: 0.0%
2026-04-19 17:37:52.321 | (APIServer pid=1) INFO 04-19 15:37:52 [loggers.py:271] Engine 000: Avg prompt throughput: 0.0 tokens/s, Avg generation throughput: 4.9 tokens/s, Running: 0 reqs, Waiting: 0 reqs, GPU KV cache usage: 0.0%, Prefix cache hit rate: 0.0%
2026-04-19 17:37:52.321 | (APIServer pid=1) INFO 04-19 15:37:52 [metrics.py:101] SpecDecoding metrics: Mean acceptance length: 1.04, Accepted throughput: 0.20 tokens/s, Drafted throughput: 14.10 tokens/s, Accepted: 2 tokens, Drafted: 141 tokens, Per-position acceptance rate: 0.043, 0.000, 0.000, Avg Draft acceptance rate: 1.4%
2026-04-19 17:38:02.321 | (APIServer pid=1) INFO 04-19 15:38:02 [loggers.py:271] Engine 000: Avg prompt throughput: 0.0 tokens/s, Avg generation throughput: 0.0 tokens/s, Running: 0 reqs, Waiting: 0 reqs, GPU KV cache usage: 0.0%, Prefix cache hit rate: 0.0%