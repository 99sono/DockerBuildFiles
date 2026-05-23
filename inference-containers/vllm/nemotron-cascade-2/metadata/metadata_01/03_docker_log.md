
personal

Containers
nemotron-cascade-2-nvfp4

nemotron-cascade-2-nvfp4
7cdea6410acc
vllm/vllm-openai:latest
8000:8000
STATUS
Running (2 minutes ago)


(APIServer pid=1) INFO 04-17 18:06:17 [utils.py:299] 

(APIServer pid=1) INFO 04-17 18:06:17 [utils.py:299]        █     █     █▄   ▄█

(APIServer pid=1) INFO 04-17 18:06:17 [utils.py:299]  ▄▄ ▄█ █     █     █ ▀▄▀ █  version 0.19.0

(APIServer pid=1) INFO 04-17 18:06:17 [utils.py:299]   █▄█▀ █     █     █     █  model   chankhavu/Nemotron-Cascade-2-30B-A3B-NVFP4

(APIServer pid=1) INFO 04-17 18:06:17 [utils.py:299]    ▀▀  ▀▀▀▀▀ ▀▀▀▀▀ ▀     ▀

(APIServer pid=1) INFO 04-17 18:06:17 [utils.py:299] 

(APIServer pid=1) INFO 04-17 18:06:17 [utils.py:233] non-default args: {'model_tag': 'chankhavu/Nemotron-Cascade-2-30B-A3B-NVFP4', 'enable_auto_tool_choice': True, 'tool_call_parser': 'qwen3_coder', 'model': 'chankhavu/Nemotron-Cascade-2-30B-A3B-NVFP4', 'trust_remote_code': True, 'max_model_len': 131072, 'enforce_eager': True, 'reasoning_parser': 'nemotron_v3', 'gpu_memory_utilization': 0.75, 'kv_cache_dtype': 'fp8', 'mamba_ssm_cache_dtype': 'float32'}

(APIServer pid=1) WARNING 04-17 18:06:17 [envs.py:1744] Unknown vLLM environment variable detected: VLLM_USE_V1

(APIServer pid=1) A new version of the following files was downloaded from https://huggingface.co/chankhavu/Nemotron-Cascade-2-30B-A3B-NVFP4:

(APIServer pid=1) - configuration_nemotron_h.py

(APIServer pid=1) . Make sure to double-check they do not contain any added malicious code. To avoid downloading new versions of the code file, you can pin a revision.

(APIServer pid=1) INFO 04-17 18:06:24 [model.py:549] Resolved architecture: NemotronHForCausalLM

(APIServer pid=1) INFO 04-17 18:06:24 [model.py:1678] Using max model len 131072

(APIServer pid=1) INFO 04-17 18:06:25 [cache.py:227] Using fp8 data type to store kv cache. It reduces the GPU memory footprint and boosts the performance. Meanwhile, it may cause accuracy drop without a proper scaling factor.

(APIServer pid=1) INFO 04-17 18:06:25 [config.py:281] Setting attention block size to 4176 tokens to ensure that attention page size is >= mamba page size.

(APIServer pid=1) INFO 04-17 18:06:25 [config.py:312] Padding mamba page size by 0.19% to ensure that mamba page size and attention page size are exactly equal.

(APIServer pid=1) WARNING 04-17 18:06:25 [modelopt.py:998] Detected ModelOpt NVFP4 checkpoint. Please note that the format is experimental and could change in future.

(APIServer pid=1) INFO 04-17 18:06:25 [vllm.py:790] Asynchronous scheduling is enabled.

(APIServer pid=1) WARNING 04-17 18:06:25 [vllm.py:848] Enforce eager set, disabling torch.compile and CUDAGraphs. This is equivalent to setting -cc.mode=none -cc.cudagraph_mode=none

(APIServer pid=1) WARNING 04-17 18:06:25 [vllm.py:859] Inductor compilation was disabled by user settings, optimizations settings that are only active during inductor compilation will be ignored.

(APIServer pid=1) INFO 04-17 18:06:25 [vllm.py:1025] Cudagraph is disabled under eager mode

(APIServer pid=1) INFO 04-17 18:06:25 [compilation.py:290] Enabled custom fusions: norm_quant, act_quant

(EngineCore pid=184) INFO 04-17 18:06:34 [core.py:105] Initializing a V1 LLM engine (v0.19.0) with config: model='chankhavu/Nemotron-Cascade-2-30B-A3B-NVFP4', speculative_config=None, tokenizer='chankhavu/Nemotron-Cascade-2-30B-A3B-NVFP4', skip_tokenizer_init=False, tokenizer_mode=auto, revision=None, tokenizer_revision=None, trust_remote_code=True, dtype=torch.bfloat16, max_seq_len=131072, download_dir=None, load_format=auto, tensor_parallel_size=1, pipeline_parallel_size=1, data_parallel_size=1, decode_context_parallel_size=1, dcp_comm_backend=ag_rs, disable_custom_all_reduce=False, quantization=modelopt_fp4, enforce_eager=True, enable_return_routed_experts=False, kv_cache_dtype=fp8, device_config=cuda, structured_outputs_config=StructuredOutputsConfig(backend='auto', disable_any_whitespace=False, disable_additional_properties=False, reasoning_parser='nemotron_v3', reasoning_parser_plugin='', enable_in_reasoning=False), observability_config=ObservabilityConfig(show_hidden_metrics_for_version=None, otlp_traces_endpoint=None, collect_detailed_traces=None, kv_cache_metrics=False, kv_cache_metrics_sample=0.01, cudagraph_metrics=False, enable_layerwise_nvtx_tracing=False, enable_mfu_metrics=False, enable_mm_processor_stats=False, enable_logging_iteration_details=False), seed=0, served_model_name=chankhavu/Nemotron-Cascade-2-30B-A3B-NVFP4, enable_prefix_caching=False, enable_chunked_prefill=True, pooler_config=None, compilation_config={'mode': <CompilationMode.NONE: 0>, 'debug_dump_path': None, 'cache_dir': '', 'compile_cache_save_format': 'binary', 'backend': 'inductor', 'custom_ops': ['all'], 'splitting_ops': [], 'compile_mm_encoder': False, 'cudagraph_mm_encoder': False, 'encoder_cudagraph_token_budgets': [], 'encoder_cudagraph_max_images_per_batch': 0, 'compile_sizes': [], 'compile_ranges_endpoints': [2048], 'inductor_compile_config': {'enable_auto_functionalized_v2': False, 'size_asserts': False, 'alignment_asserts': False, 'scalar_asserts': False, 'combo_kernels': True, 'benchmark_combo_kernel': True}, 'inductor_passes': {}, 'cudagraph_mode': <CUDAGraphMode.NONE: 0>, 'cudagraph_num_of_warmups': 0, 'cudagraph_capture_sizes': [], 'cudagraph_copy_inputs': False, 'cudagraph_specialize_lora': True, 'use_inductor_graph_partition': False, 'pass_config': {'fuse_norm_quant': True, 'fuse_act_quant': True, 'fuse_attn_quant': False, 'enable_sp': False, 'fuse_gemm_comms': False, 'fuse_allreduce_rms': False}, 'max_cudagraph_capture_size': 0, 'dynamic_shapes_config': {'type': <DynamicShapesType.BACKED: 'backed'>, 'evaluate_guards': False, 'assume_32_bit_indexing': False}, 'local_cache_dir': None, 'fast_moe_cold_start': True, 'static_all_moe_layers': []}

(EngineCore pid=184) WARNING 04-17 18:06:34 [interface.py:525] Using 'pin_memory=False' as WSL is detected. This may slow down the performance.

(EngineCore pid=184) INFO 04-17 18:06:34 [parallel_state.py:1400] world_size=1 rank=0 local_rank=0 distributed_init_method=tcp://172.18.0.2:47805 backend=nccl

(EngineCore pid=184) INFO 04-17 18:06:34 [parallel_state.py:1716] rank 0 in world size 1 is assigned as DP rank 0, PP rank 0, PCP rank 0, TP rank 0, EP rank 0, EPLB rank N/A

(EngineCore pid=184) INFO 04-17 18:06:35 [gpu_model_runner.py:4735] Starting to load model chankhavu/Nemotron-Cascade-2-30B-A3B-NVFP4...

(EngineCore pid=184) INFO 04-17 18:06:35 [nvfp4_utils.py:85] Using NvFp4LinearBackend.FLASHINFER_CUTLASS for NVFP4 GEMM

(EngineCore pid=184) INFO 04-17 18:06:36 [nvfp4.py:256] Using 'FLASHINFER_CUTLASS' NvFp4 MoE backend out of potential backends: ['FLASHINFER_TRTLLM', 'FLASHINFER_CUTEDSL', 'FLASHINFER_CUTLASS', 'VLLM_CUTLASS', 'MARLIN'].

(EngineCore pid=184) INFO 04-17 18:06:36 [cuda.py:334] Using FLASHINFER attention backend out of potential backends: ['FLASHINFER', 'TRITON_ATTN'].
