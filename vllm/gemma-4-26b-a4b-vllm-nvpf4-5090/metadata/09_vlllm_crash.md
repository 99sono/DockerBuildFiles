# docker compose
services:
  gemma-4-26b-it-nvfp4:
    image: vllm/vllm-openai:nightly
    container_name: gemma-4-26b-it-nvfp4
    hostname: gemma-4-26b-it-nvfp4
    runtime: nvidia
    restart: unless-stopped
    ports:
      - "8000:8000"
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
      - NVIDIA_VISIBLE_DEVICES=all
      - HF_HUB_ENABLE_HF_TRANSFER=1
      - VLLM_WORKER_MULTIPROC_METHOD=spawn
    command:
      - "RedHatAI/gemma-4-26B-A4B-it-NVFP4"
      - "--served-model-name"
      - "gemma-4-26b-it-nvfp4"
      - "--host"
      - "0.0.0.0"
      - "--port"
      - "8000"
      - "--gpu-memory-utilization"
      - "0.80"
      - "--max-model-len"
      - "98304"
      - "--kv-cache-dtype"
      - "fp8_e4m3"
      - "--quantization"
      - "compressed-tensors"
      - "--reasoning-parser"
      - "gemma4"
      - "--tool-call-parser"
      - "gemma4"
      - "--moe-backend"
      - "triton"
      - "--enable-prefix-caching"
      - "--enable-chunked-prefill"
      - "--trust-remote-code"
    networks:
      - development-network

networks:
  development-network:
    external: true

# vllm crash
2026-04-19 12:58:51.656 | WARNING 04-19 10:58:51 [interface.py:686] Using 'pin_memory=False' as WSL is detected. This may slow down the performance.
2026-04-19 12:58:51.742 | (APIServer pid=1) INFO 04-19 10:58:51 [utils.py:299] 
2026-04-19 12:58:51.742 | (APIServer pid=1) INFO 04-19 10:58:51 [utils.py:299]        █     █     █▄   ▄█
2026-04-19 12:58:51.742 | (APIServer pid=1) INFO 04-19 10:58:51 [utils.py:299]  ▄▄ ▄█ █     █     █ ▀▄▀ █  version 0.19.2rc1.dev8+g4b7f5ea1a
2026-04-19 12:58:51.742 | (APIServer pid=1) INFO 04-19 10:58:51 [utils.py:299]   █▄█▀ █     █     █     █  model   RedHatAI/gemma-4-26B-A4B-it-NVFP4
2026-04-19 12:58:51.742 | (APIServer pid=1) INFO 04-19 10:58:51 [utils.py:299]    ▀▀  ▀▀▀▀▀ ▀▀▀▀▀ ▀     ▀
2026-04-19 12:58:51.742 | (APIServer pid=1) INFO 04-19 10:58:51 [utils.py:299] 
2026-04-19 12:58:51.745 | (APIServer pid=1) INFO 04-19 10:58:51 [utils.py:233] non-default args: {'model_tag': 'RedHatAI/gemma-4-26B-A4B-it-NVFP4', 'tool_call_parser': 'gemma4', 'host': '0.0.0.0', 'model': 'RedHatAI/gemma-4-26B-A4B-it-NVFP4', 'trust_remote_code': True, 'max_model_len': 98304, 'quantization': 'compressed-tensors', 'served_model_name': ['gemma-4-26b-it-nvfp4'], 'reasoning_parser': 'gemma4', 'gpu_memory_utilization': 0.8, 'kv_cache_dtype': 'fp8_e4m3', 'enable_prefix_caching': True, 'enable_chunked_prefill': True, 'moe_backend': 'triton'}
2026-04-19 12:58:51.902 | (APIServer pid=1) Warning: You are sending unauthenticated requests to the HF Hub. Please set a HF_TOKEN to enable higher rate limits and faster downloads.
2026-04-19 12:59:01.875 | (APIServer pid=1) INFO 04-19 10:59:01 [model.py:554] Resolved architecture: Gemma4ForConditionalGeneration
2026-04-19 12:59:01.876 | (APIServer pid=1) INFO 04-19 10:59:01 [model.py:1685] Using max model len 98304
2026-04-19 12:59:02.157 | (APIServer pid=1) INFO 04-19 10:59:02 [cache.py:247] Using fp8_e4m3 data type to store kv cache. It reduces the GPU memory footprint and boosts the performance. Meanwhile, it may cause accuracy drop without a proper scaling factor
2026-04-19 12:59:02.158 | (APIServer pid=1) INFO 04-19 10:59:02 [config.py:101] Gemma4 model has heterogeneous head dimensions (head_dim=256, global_head_dim=512). Forcing TRITON_ATTN backend to prevent mixed-backend numerical divergence.
2026-04-19 12:59:02.159 | (APIServer pid=1) INFO 04-19 10:59:02 [vllm.py:834] Asynchronous scheduling is enabled.
2026-04-19 12:59:02.159 | (APIServer pid=1) INFO 04-19 10:59:02 [kernel.py:199] Final IR op priority after setting platform defaults: IrOpPriorityConfig(rms_norm=['native'])
2026-04-19 12:59:05.367 | (APIServer pid=1) INFO 04-19 10:59:05 [compilation.py:294] Enabled custom fusions: act_quant
2026-04-19 12:59:14.391 | (EngineCore pid=196) INFO 04-19 10:59:14 [core.py:107] Initializing a V1 LLM engine (v0.19.2rc1.dev8+g4b7f5ea1a) with config: model='RedHatAI/gemma-4-26B-A4B-it-NVFP4', speculative_config=None, tokenizer='RedHatAI/gemma-4-26B-A4B-it-NVFP4', skip_tokenizer_init=False, tokenizer_mode=auto, revision=None, tokenizer_revision=None, trust_remote_code=True, dtype=torch.bfloat16, max_seq_len=98304, download_dir=None, load_format=auto, tensor_parallel_size=1, pipeline_parallel_size=1, data_parallel_size=1, decode_context_parallel_size=1, dcp_comm_backend=ag_rs, disable_custom_all_reduce=False, quantization=compressed-tensors, quantization_config=None, enforce_eager=False, enable_return_routed_experts=False, kv_cache_dtype=fp8_e4m3, device_config=cuda, structured_outputs_config=StructuredOutputsConfig(backend='auto', disable_any_whitespace=False, disable_additional_properties=False, reasoning_parser='gemma4', reasoning_parser_plugin='', enable_in_reasoning=False), observability_config=ObservabilityConfig(show_hidden_metrics_for_version=None, otlp_traces_endpoint=None, collect_detailed_traces=None, kv_cache_metrics=False, kv_cache_metrics_sample=0.01, cudagraph_metrics=False, enable_layerwise_nvtx_tracing=False, enable_mfu_metrics=False, enable_mm_processor_stats=False, enable_logging_iteration_details=False), seed=0, served_model_name=gemma-4-26b-it-nvfp4, enable_prefix_caching=True, enable_chunked_prefill=True, pooler_config=None, compilation_config={'mode': <CompilationMode.VLLM_COMPILE: 3>, 'debug_dump_path': None, 'cache_dir': '', 'compile_cache_save_format': 'binary', 'backend': 'inductor', 'custom_ops': ['none'], 'ir_enable_torch_wrap': True, 'splitting_ops': ['vllm::unified_attention_with_output', 'vllm::unified_mla_attention_with_output', 'vllm::mamba_mixer2', 'vllm::mamba_mixer', 'vllm::short_conv', 'vllm::linear_attention', 'vllm::plamo2_mamba_mixer', 'vllm::gdn_attention_core', 'vllm::olmo_hybrid_gdn_full_forward', 'vllm::kda_attention', 'vllm::sparse_attn_indexer', 'vllm::rocm_aiter_sparse_attn_indexer', 'vllm::unified_kv_cache_update', 'vllm::unified_mla_kv_cache_update'], 'compile_mm_encoder': False, 'cudagraph_mm_encoder': False, 'encoder_cudagraph_token_budgets': [], 'encoder_cudagraph_max_vision_items_per_batch': 0, 'encoder_cudagraph_max_frames_per_batch': 0, 'compile_sizes': [], 'compile_ranges_endpoints': [2048], 'inductor_compile_config': {'enable_auto_functionalized_v2': False, 'size_asserts': False, 'alignment_asserts': False, 'scalar_asserts': False, 'combo_kernels': True, 'benchmark_combo_kernel': True}, 'inductor_passes': {}, 'cudagraph_mode': <CUDAGraphMode.FULL_AND_PIECEWISE: (2, 1)>, 'cudagraph_num_of_warmups': 1, 'cudagraph_capture_sizes': [1, 2, 4, 8, 16, 24, 32, 40, 48, 56, 64, 72, 80, 88, 96, 104, 112, 120, 128, 136, 144, 152, 160, 168, 176, 184, 192, 200, 208, 216, 224, 232, 240, 248, 256, 272, 288, 304, 320, 336, 352, 368, 384, 400, 416, 432, 448, 464, 480, 496, 512], 'cudagraph_copy_inputs': False, 'cudagraph_specialize_lora': True, 'use_inductor_graph_partition': False, 'pass_config': {'fuse_norm_quant': False, 'fuse_act_quant': True, 'fuse_attn_quant': False, 'enable_sp': False, 'fuse_gemm_comms': False, 'fuse_allreduce_rms': False}, 'max_cudagraph_capture_size': 512, 'dynamic_shapes_config': {'type': <DynamicShapesType.BACKED: 'backed'>, 'evaluate_guards': False, 'assume_32_bit_indexing': False}, 'local_cache_dir': None, 'fast_moe_cold_start': False, 'static_all_moe_layers': []}, kernel_config=KernelConfig(ir_op_priority=IrOpPriorityConfig(rms_norm=['native']), enable_flashinfer_autotune=True, moe_backend='triton')
2026-04-19 12:59:14.585 | (EngineCore pid=196) WARNING 04-19 10:59:14 [interface.py:686] Using 'pin_memory=False' as WSL is detected. This may slow down the performance.
2026-04-19 12:59:14.877 | (EngineCore pid=196) Warning: You are sending unauthenticated requests to the HF Hub. Please set a HF_TOKEN to enable higher rate limits and faster downloads.
2026-04-19 12:59:18.350 | (EngineCore pid=196) INFO 04-19 10:59:18 [parallel_state.py:1400] world_size=1 rank=0 local_rank=0 distributed_init_method=tcp://172.18.0.2:37565 backend=nccl
2026-04-19 12:59:18.672 | (EngineCore pid=196) INFO 04-19 10:59:18 [parallel_state.py:1713] rank 0 in world size 1 is assigned as DP rank 0, PP rank 0, PCP rank 0, TP rank 0, EP rank 0, EPLB rank N/A
2026-04-19 12:59:19.264 | (EngineCore pid=196) INFO 04-19 10:59:19 [gpu_model_runner.py:4752] Starting to load model RedHatAI/gemma-4-26B-A4B-it-NVFP4...
2026-04-19 12:59:19.735 | (EngineCore pid=196) INFO 04-19 10:59:19 [vllm.py:834] Asynchronous scheduling is enabled.
2026-04-19 12:59:19.736 | (EngineCore pid=196) INFO 04-19 10:59:19 [kernel.py:199] Final IR op priority after setting platform defaults: IrOpPriorityConfig(rms_norm=['native'])
2026-04-19 12:59:19.736 | (EngineCore pid=196) INFO 04-19 10:59:19 [compilation.py:294] Enabled custom fusions: act_quant
2026-04-19 12:59:19.745 | (EngineCore pid=196) INFO 04-19 10:59:19 [__init__.py:683] Using FlashInferCutlassNvFp4LinearKernel for NVFP4 GEMM
2026-04-19 12:59:19.781 | (EngineCore pid=196) INFO 04-19 10:59:19 [cuda.py:308] Using AttentionBackendEnum.TRITON_ATTN backend.
2026-04-19 12:59:20.215 | (EngineCore pid=196) ERROR 04-19 10:59:20 [core.py:1132] EngineCore failed to start.
2026-04-19 12:59:20.215 | (EngineCore pid=196) ERROR 04-19 10:59:20 [core.py:1132] Traceback (most recent call last):
2026-04-19 12:59:20.215 | (EngineCore pid=196) ERROR 04-19 10:59:20 [core.py:1132]   File "/usr/local/lib/python3.12/dist-packages/vllm/v1/engine/core.py", line 1106, in run_engine_core
2026-04-19 12:59:20.215 | (EngineCore pid=196) ERROR 04-19 10:59:20 [core.py:1132]     engine_core = EngineCoreProc(*args, engine_index=dp_rank, **kwargs)
2026-04-19 12:59:20.215 | (EngineCore pid=196) ERROR 04-19 10:59:20 [core.py:1132]                   ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
2026-04-19 12:59:20.215 | (EngineCore pid=196) ERROR 04-19 10:59:20 [core.py:1132]   File "/usr/local/lib/python3.12/dist-packages/vllm/tracing/otel.py", line 178, in sync_wrapper
2026-04-19 12:59:20.215 | (EngineCore pid=196) ERROR 04-19 10:59:20 [core.py:1132]     return func(*args, **kwargs)
2026-04-19 12:59:20.215 | (EngineCore pid=196) ERROR 04-19 10:59:20 [core.py:1132]            ^^^^^^^^^^^^^^^^^^^^^
2026-04-19 12:59:20.215 | (EngineCore pid=196) Process EngineCore:
2026-04-19 12:59:20.215 | (EngineCore pid=196) ERROR 04-19 10:59:20 [core.py:1132]   File "/usr/local/lib/python3.12/dist-packages/vllm/v1/engine/core.py", line 872, in __init__
2026-04-19 12:59:20.215 | (EngineCore pid=196) ERROR 04-19 10:59:20 [core.py:1132]     super().__init__(
2026-04-19 12:59:20.215 | (EngineCore pid=196) ERROR 04-19 10:59:20 [core.py:1132]   File "/usr/local/lib/python3.12/dist-packages/vllm/v1/engine/core.py", line 116, in __init__
2026-04-19 12:59:20.215 | (EngineCore pid=196) ERROR 04-19 10:59:20 [core.py:1132]     self.model_executor = executor_class(vllm_config)
2026-04-19 12:59:20.215 | (EngineCore pid=196) ERROR 04-19 10:59:20 [core.py:1132]                           ^^^^^^^^^^^^^^^^^^^^^^^^^^^
2026-04-19 12:59:20.215 | (EngineCore pid=196) ERROR 04-19 10:59:20 [core.py:1132]   File "/usr/local/lib/python3.12/dist-packages/vllm/tracing/otel.py", line 178, in sync_wrapper
2026-04-19 12:59:20.215 | (EngineCore pid=196) ERROR 04-19 10:59:20 [core.py:1132]     return func(*args, **kwargs)
2026-04-19 12:59:20.215 | (EngineCore pid=196) ERROR 04-19 10:59:20 [core.py:1132]            ^^^^^^^^^^^^^^^^^^^^^
2026-04-19 12:59:20.216 | (EngineCore pid=196) ERROR 04-19 10:59:20 [core.py:1132]   File "/usr/local/lib/python3.12/dist-packages/vllm/v1/executor/abstract.py", line 109, in __init__
2026-04-19 12:59:20.216 | (EngineCore pid=196) ERROR 04-19 10:59:20 [core.py:1132]     self._init_executor()
2026-04-19 12:59:20.216 | (EngineCore pid=196) ERROR 04-19 10:59:20 [core.py:1132]   File "/usr/local/lib/python3.12/dist-packages/vllm/v1/executor/uniproc_executor.py", line 52, in _init_executor
2026-04-19 12:59:20.216 | (EngineCore pid=196) ERROR 04-19 10:59:20 [core.py:1132]     self.driver_worker.load_model()
2026-04-19 12:59:20.216 | (EngineCore pid=196) ERROR 04-19 10:59:20 [core.py:1132]   File "/usr/local/lib/python3.12/dist-packages/vllm/v1/worker/gpu_worker.py", line 323, in load_model
2026-04-19 12:59:20.216 | (EngineCore pid=196) ERROR 04-19 10:59:20 [core.py:1132]     self.model_runner.load_model(load_dummy_weights=load_dummy_weights)
2026-04-19 12:59:20.216 | (EngineCore pid=196) ERROR 04-19 10:59:20 [core.py:1132]   File "/usr/local/lib/python3.12/dist-packages/vllm/tracing/otel.py", line 178, in sync_wrapper
2026-04-19 12:59:20.216 | (EngineCore pid=196) ERROR 04-19 10:59:20 [core.py:1132]     return func(*args, **kwargs)
2026-04-19 12:59:20.216 | (EngineCore pid=196) ERROR 04-19 10:59:20 [core.py:1132]            ^^^^^^^^^^^^^^^^^^^^^
2026-04-19 12:59:20.216 | (EngineCore pid=196) ERROR 04-19 10:59:20 [core.py:1132]   File "/usr/local/lib/python3.12/dist-packages/vllm/v1/worker/gpu_model_runner.py", line 4768, in load_model
2026-04-19 12:59:20.216 | (EngineCore pid=196) ERROR 04-19 10:59:20 [core.py:1132]     self.model = model_loader.load_model(
2026-04-19 12:59:20.216 | (EngineCore pid=196) ERROR 04-19 10:59:20 [core.py:1132]                  ^^^^^^^^^^^^^^^^^^^^^^^^
2026-04-19 12:59:20.216 | (EngineCore pid=196) ERROR 04-19 10:59:20 [core.py:1132]   File "/usr/local/lib/python3.12/dist-packages/vllm/tracing/otel.py", line 178, in sync_wrapper
2026-04-19 12:59:20.216 | (EngineCore pid=196) ERROR 04-19 10:59:20 [core.py:1132]     return func(*args, **kwargs)
2026-04-19 12:59:20.216 | (EngineCore pid=196) ERROR 04-19 10:59:20 [core.py:1132]            ^^^^^^^^^^^^^^^^^^^^^
2026-04-19 12:59:20.216 | (EngineCore pid=196) ERROR 04-19 10:59:20 [core.py:1132]   File "/usr/local/lib/python3.12/dist-packages/vllm/model_executor/model_loader/base_loader.py", line 55, in load_model
2026-04-19 12:59:20.216 | (EngineCore pid=196) ERROR 04-19 10:59:20 [core.py:1132]     model = initialize_model(
2026-04-19 12:59:20.216 | (EngineCore pid=196) ERROR 04-19 10:59:20 [core.py:1132]             ^^^^^^^^^^^^^^^^^
2026-04-19 12:59:20.216 | (EngineCore pid=196) ERROR 04-19 10:59:20 [core.py:1132]   File "/usr/local/lib/python3.12/dist-packages/vllm/tracing/otel.py", line 178, in sync_wrapper
2026-04-19 12:59:20.216 | (EngineCore pid=196) ERROR 04-19 10:59:20 [core.py:1132]     return func(*args, **kwargs)
2026-04-19 12:59:20.216 | (EngineCore pid=196) ERROR 04-19 10:59:20 [core.py:1132]            ^^^^^^^^^^^^^^^^^^^^^
2026-04-19 12:59:20.216 | (EngineCore pid=196) ERROR 04-19 10:59:20 [core.py:1132]   File "/usr/local/lib/python3.12/dist-packages/vllm/model_executor/model_loader/utils.py", line 57, in initialize_model
2026-04-19 12:59:20.216 | (EngineCore pid=196) ERROR 04-19 10:59:20 [core.py:1132]     model = model_class(vllm_config=vllm_config, prefix=prefix)
2026-04-19 12:59:20.216 | (EngineCore pid=196) ERROR 04-19 10:59:20 [core.py:1132]             ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
2026-04-19 12:59:20.216 | (EngineCore pid=196) ERROR 04-19 10:59:20 [core.py:1132]   File "/usr/local/lib/python3.12/dist-packages/vllm/model_executor/models/gemma4_mm.py", line 946, in __init__
2026-04-19 12:59:20.216 | (EngineCore pid=196) ERROR 04-19 10:59:20 [core.py:1132]     self.language_model: Gemma4ForCausalLM = init_vllm_registered_model(
2026-04-19 12:59:20.216 | (EngineCore pid=196) ERROR 04-19 10:59:20 [core.py:1132]                                              ^^^^^^^^^^^^^^^^^^^^^^^^^^^
2026-04-19 12:59:20.216 | (EngineCore pid=196) ERROR 04-19 10:59:20 [core.py:1132]   File "/usr/local/lib/python3.12/dist-packages/vllm/model_executor/models/utils.py", line 379, in init_vllm_registered_model
2026-04-19 12:59:20.216 | (EngineCore pid=196) ERROR 04-19 10:59:20 [core.py:1132]     return initialize_model(vllm_config=vllm_config, prefix=prefix)
2026-04-19 12:59:20.216 | (EngineCore pid=196) ERROR 04-19 10:59:20 [core.py:1132]            ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
2026-04-19 12:59:20.216 | (EngineCore pid=196) ERROR 04-19 10:59:20 [core.py:1132]   File "/usr/local/lib/python3.12/dist-packages/vllm/tracing/otel.py", line 178, in sync_wrapper
2026-04-19 12:59:20.216 | (EngineCore pid=196) ERROR 04-19 10:59:20 [core.py:1132]     return func(*args, **kwargs)
2026-04-19 12:59:20.216 | (EngineCore pid=196) ERROR 04-19 10:59:20 [core.py:1132]            ^^^^^^^^^^^^^^^^^^^^^
2026-04-19 12:59:20.216 | (EngineCore pid=196) ERROR 04-19 10:59:20 [core.py:1132]   File "/usr/local/lib/python3.12/dist-packages/vllm/model_executor/model_loader/utils.py", line 57, in initialize_model
2026-04-19 12:59:20.216 | (EngineCore pid=196) ERROR 04-19 10:59:20 [core.py:1132]     model = model_class(vllm_config=vllm_config, prefix=prefix)
2026-04-19 12:59:20.216 | (EngineCore pid=196) ERROR 04-19 10:59:20 [core.py:1132]             ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
2026-04-19 12:59:20.216 | (EngineCore pid=196) ERROR 04-19 10:59:20 [core.py:1132]   File "/usr/local/lib/python3.12/dist-packages/vllm/model_executor/models/gemma4.py", line 1439, in __init__
2026-04-19 12:59:20.216 | (EngineCore pid=196) ERROR 04-19 10:59:20 [core.py:1132]     self.model = Gemma4Model(
2026-04-19 12:59:20.216 | (EngineCore pid=196) ERROR 04-19 10:59:20 [core.py:1132]                  ^^^^^^^^^^^^
2026-04-19 12:59:20.216 | (EngineCore pid=196) ERROR 04-19 10:59:20 [core.py:1132]   File "/usr/local/lib/python3.12/dist-packages/vllm/compilation/decorators.py", line 379, in __init__
2026-04-19 12:59:20.216 | (EngineCore pid=196) ERROR 04-19 10:59:20 [core.py:1132]     old_init(self, *args, **kwargs)
2026-04-19 12:59:20.216 | (EngineCore pid=196) ERROR 04-19 10:59:20 [core.py:1132]   File "/usr/local/lib/python3.12/dist-packages/vllm/model_executor/models/gemma4.py", line 931, in __init__
2026-04-19 12:59:20.216 | (EngineCore pid=196) ERROR 04-19 10:59:20 [core.py:1132]     self.start_layer, self.end_layer, self.layers = make_layers(
2026-04-19 12:59:20.216 | (EngineCore pid=196) ERROR 04-19 10:59:20 [core.py:1132]                                                     ^^^^^^^^^^^^
2026-04-19 12:59:20.216 | (EngineCore pid=196) ERROR 04-19 10:59:20 [core.py:1132]   File "/usr/local/lib/python3.12/dist-packages/vllm/model_executor/models/utils.py", line 646, in make_layers
2026-04-19 12:59:20.216 | (EngineCore pid=196) ERROR 04-19 10:59:20 [core.py:1132]     + get_offloader().wrap_modules(
2026-04-19 12:59:20.216 | (EngineCore pid=196) ERROR 04-19 10:59:20 [core.py:1132]       ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
2026-04-19 12:59:20.216 | (EngineCore pid=196) ERROR 04-19 10:59:20 [core.py:1132]   File "/usr/local/lib/python3.12/dist-packages/vllm/model_executor/offloader/base.py", line 104, in wrap_modules
2026-04-19 12:59:20.216 | (EngineCore pid=196) ERROR 04-19 10:59:20 [core.py:1132]     return list(modules_generator)
2026-04-19 12:59:20.216 | (EngineCore pid=196) ERROR 04-19 10:59:20 [core.py:1132]            ^^^^^^^^^^^^^^^^^^^^^^^
2026-04-19 12:59:20.216 | (EngineCore pid=196) ERROR 04-19 10:59:20 [core.py:1132]   File "/usr/local/lib/python3.12/dist-packages/vllm/model_executor/models/utils.py", line 647, in <genexpr>
2026-04-19 12:59:20.216 | (EngineCore pid=196) ERROR 04-19 10:59:20 [core.py:1132]     layer_fn(prefix=f"{prefix}.{idx}") for idx in range(start_layer, end_layer)
2026-04-19 12:59:20.216 | (EngineCore pid=196) ERROR 04-19 10:59:20 [core.py:1132]     ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
2026-04-19 12:59:20.216 | (EngineCore pid=196) ERROR 04-19 10:59:20 [core.py:1132]   File "/usr/local/lib/python3.12/dist-packages/vllm/model_executor/models/gemma4.py", line 933, in <lambda>
2026-04-19 12:59:20.216 | (EngineCore pid=196) ERROR 04-19 10:59:20 [core.py:1132]     lambda prefix: Gemma4DecoderLayer(
2026-04-19 12:59:20.216 | (EngineCore pid=196) ERROR 04-19 10:59:20 [core.py:1132]                    ^^^^^^^^^^^^^^^^^^^
2026-04-19 12:59:20.216 | (EngineCore pid=196) ERROR 04-19 10:59:20 [core.py:1132]   File "/usr/local/lib/python3.12/dist-packages/vllm/model_executor/models/gemma4.py", line 530, in __init__
2026-04-19 12:59:20.216 | (EngineCore pid=196) ERROR 04-19 10:59:20 [core.py:1132]     self.moe = Gemma4MoE(
2026-04-19 12:59:20.216 | (EngineCore pid=196) ERROR 04-19 10:59:20 [core.py:1132]                ^^^^^^^^^^
2026-04-19 12:59:20.216 | (EngineCore pid=196) ERROR 04-19 10:59:20 [core.py:1132]   File "/usr/local/lib/python3.12/dist-packages/vllm/model_executor/models/gemma4.py", line 237, in __init__
2026-04-19 12:59:20.216 | (EngineCore pid=196) ERROR 04-19 10:59:20 [core.py:1132]     self.experts = FusedMoE(
2026-04-19 12:59:20.216 | (EngineCore pid=196) ERROR 04-19 10:59:20 [core.py:1132]                    ^^^^^^^^^
2026-04-19 12:59:20.216 | (EngineCore pid=196) ERROR 04-19 10:59:20 [core.py:1132]   File "/usr/local/lib/python3.12/dist-packages/vllm/model_executor/layers/fused_moe/layer.py", line 520, in __init__
2026-04-19 12:59:20.216 | (EngineCore pid=196) ERROR 04-19 10:59:20 [core.py:1132]     self.quant_method: FusedMoEMethodBase = _get_quant_method()
2026-04-19 12:59:20.216 | (EngineCore pid=196) ERROR 04-19 10:59:20 [core.py:1132]                                             ^^^^^^^^^^^^^^^^^^^
2026-04-19 12:59:20.216 | (EngineCore pid=196) ERROR 04-19 10:59:20 [core.py:1132]   File "/usr/local/lib/python3.12/dist-packages/vllm/model_executor/layers/fused_moe/layer.py", line 512, in _get_quant_method
2026-04-19 12:59:20.216 | (EngineCore pid=196) ERROR 04-19 10:59:20 [core.py:1132]     quant_method = self.quant_config.get_quant_method(self, prefix)
2026-04-19 12:59:20.216 | (EngineCore pid=196) ERROR 04-19 10:59:20 [core.py:1132]                    ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
2026-04-19 12:59:20.216 | (EngineCore pid=196) ERROR 04-19 10:59:20 [core.py:1132]   File "/usr/local/lib/python3.12/dist-packages/vllm/model_executor/layers/quantization/compressed_tensors/compressed_tensors.py", line 196, in get_quant_method
2026-04-19 12:59:20.216 | (EngineCore pid=196) ERROR 04-19 10:59:20 [core.py:1132]     return CompressedTensorsMoEMethod.get_moe_method(
2026-04-19 12:59:20.216 | (EngineCore pid=196) ERROR 04-19 10:59:20 [core.py:1132]            ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
2026-04-19 12:59:20.216 | (EngineCore pid=196) ERROR 04-19 10:59:20 [core.py:1132]   File "/usr/local/lib/python3.12/dist-packages/vllm/model_executor/layers/quantization/compressed_tensors/compressed_tensors_moe/compressed_tensors_moe.py", line 139, in get_moe_method
2026-04-19 12:59:20.216 | (EngineCore pid=196) ERROR 04-19 10:59:20 [core.py:1132]     return CompressedTensorsW4A4Nvfp4MoEMethod(
2026-04-19 12:59:20.216 | (EngineCore pid=196) ERROR 04-19 10:59:20 [core.py:1132]            ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
2026-04-19 12:59:20.216 | (EngineCore pid=196) ERROR 04-19 10:59:20 [core.py:1132]   File "/usr/local/lib/python3.12/dist-packages/vllm/model_executor/layers/quantization/compressed_tensors/compressed_tensors_moe/compressed_tensors_moe_w4a4_nvfp4.py", line 47, in __init__
2026-04-19 12:59:20.216 | (EngineCore pid=196) ERROR 04-19 10:59:20 [core.py:1132]     self.nvfp4_backend, self.experts_cls = select_nvfp4_moe_backend(
2026-04-19 12:59:20.216 | (EngineCore pid=196) ERROR 04-19 10:59:20 [core.py:1132]                                            ^^^^^^^^^^^^^^^^^^^^^^^^^
2026-04-19 12:59:20.216 | (EngineCore pid=196) ERROR 04-19 10:59:20 [core.py:1132]   File "/usr/local/lib/python3.12/dist-packages/vllm/model_executor/layers/fused_moe/oracle/nvfp4.py", line 211, in select_nvfp4_moe_backend
2026-04-19 12:59:20.216 | (EngineCore pid=196) ERROR 04-19 10:59:20 [core.py:1132]     requested_backend = map_nvfp4_backend(runner_backend)
2026-04-19 12:59:20.216 | (EngineCore pid=196) ERROR 04-19 10:59:20 [core.py:1132]                         ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
2026-04-19 12:59:20.216 | (EngineCore pid=196) ERROR 04-19 10:59:20 [core.py:1132]   File "/usr/local/lib/python3.12/dist-packages/vllm/model_executor/layers/fused_moe/oracle/nvfp4.py", line 136, in map_nvfp4_backend
2026-04-19 12:59:20.216 | (EngineCore pid=196) ERROR 04-19 10:59:20 [core.py:1132]     raise ValueError(
2026-04-19 12:59:20.216 | (EngineCore pid=196) ERROR 04-19 10:59:20 [core.py:1132] ValueError: moe_backend='triton' is not supported for NvFP4 MoE. Expected one of ['cutlass', 'flashinfer_trtllm', 'flashinfer_cutlass', 'flashinfer_cutedsl', 'marlin'].
2026-04-19 12:59:20.216 | (EngineCore pid=196) Traceback (most recent call last):
2026-04-19 12:59:20.217 | (EngineCore pid=196)   File "/usr/lib/python3.12/multiprocessing/process.py", line 314, in _bootstrap
2026-04-19 12:59:20.217 | (EngineCore pid=196)     self.run()
2026-04-19 12:59:20.217 | (EngineCore pid=196)   File "/usr/lib/python3.12/multiprocessing/process.py", line 108, in run
2026-04-19 12:59:20.217 | (EngineCore pid=196)     self._target(*self._args, **self._kwargs)
2026-04-19 12:59:20.217 | (EngineCore pid=196)   File "/usr/local/lib/python3.12/dist-packages/vllm/v1/engine/core.py", line 1136, in run_engine_core
2026-04-19 12:59:20.217 | (EngineCore pid=196)     raise e
2026-04-19 12:59:20.217 | (EngineCore pid=196)   File "/usr/local/lib/python3.12/dist-packages/vllm/v1/engine/core.py", line 1106, in run_engine_core
2026-04-19 12:59:20.217 | (EngineCore pid=196)     engine_core = EngineCoreProc(*args, engine_index=dp_rank, **kwargs)
2026-04-19 12:59:20.217 | (EngineCore pid=196)                   ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
2026-04-19 12:59:20.217 | (EngineCore pid=196)   File "/usr/local/lib/python3.12/dist-packages/vllm/tracing/otel.py", line 178, in sync_wrapper
2026-04-19 12:59:20.217 | (EngineCore pid=196)     return func(*args, **kwargs)
2026-04-19 12:59:20.217 | (EngineCore pid=196)            ^^^^^^^^^^^^^^^^^^^^^
2026-04-19 12:59:20.217 | (EngineCore pid=196)   File "/usr/local/lib/python3.12/dist-packages/vllm/v1/engine/core.py", line 872, in __init__
2026-04-19 12:59:20.217 | (EngineCore pid=196)     super().__init__(
2026-04-19 12:59:20.217 | (EngineCore pid=196)   File "/usr/local/lib/python3.12/dist-packages/vllm/v1/engine/core.py", line 116, in __init__
2026-04-19 12:59:20.217 | (EngineCore pid=196)     self.model_executor = executor_class(vllm_config)
2026-04-19 12:59:20.217 | (EngineCore pid=196)                           ^^^^^^^^^^^^^^^^^^^^^^^^^^^
2026-04-19 12:59:20.217 | (EngineCore pid=196)   File "/usr/local/lib/python3.12/dist-packages/vllm/tracing/otel.py", line 178, in sync_wrapper
2026-04-19 12:59:20.217 | (EngineCore pid=196)     return func(*args, **kwargs)
2026-04-19 12:59:20.217 | (EngineCore pid=196)            ^^^^^^^^^^^^^^^^^^^^^
2026-04-19 12:59:20.217 | (EngineCore pid=196)   File "/usr/local/lib/python3.12/dist-packages/vllm/v1/executor/abstract.py", line 109, in __init__
2026-04-19 12:59:20.217 | (EngineCore pid=196)     self._init_executor()
2026-04-19 12:59:20.217 | (EngineCore pid=196)   File "/usr/local/lib/python3.12/dist-packages/vllm/v1/executor/uniproc_executor.py", line 52, in _init_executor
2026-04-19 12:59:20.217 | (EngineCore pid=196)     self.driver_worker.load_model()
2026-04-19 12:59:20.217 | (EngineCore pid=196)   File "/usr/local/lib/python3.12/dist-packages/vllm/v1/worker/gpu_worker.py", line 323, in load_model
2026-04-19 12:59:20.217 | (EngineCore pid=196)     self.model_runner.load_model(load_dummy_weights=load_dummy_weights)
2026-04-19 12:59:20.217 | (EngineCore pid=196)   File "/usr/local/lib/python3.12/dist-packages/vllm/tracing/otel.py", line 178, in sync_wrapper
2026-04-19 12:59:20.217 | (EngineCore pid=196)     return func(*args, **kwargs)
2026-04-19 12:59:20.217 | (EngineCore pid=196)            ^^^^^^^^^^^^^^^^^^^^^
2026-04-19 12:59:20.217 | (EngineCore pid=196)   File "/usr/local/lib/python3.12/dist-packages/vllm/v1/worker/gpu_model_runner.py", line 4768, in load_model
2026-04-19 12:59:20.217 | (EngineCore pid=196)     self.model = model_loader.load_model(
2026-04-19 12:59:20.217 | (EngineCore pid=196)                  ^^^^^^^^^^^^^^^^^^^^^^^^
2026-04-19 12:59:20.217 | (EngineCore pid=196)   File "/usr/local/lib/python3.12/dist-packages/vllm/tracing/otel.py", line 178, in sync_wrapper
2026-04-19 12:59:20.217 | (EngineCore pid=196)     return func(*args, **kwargs)
2026-04-19 12:59:20.217 | (EngineCore pid=196)            ^^^^^^^^^^^^^^^^^^^^^
2026-04-19 12:59:20.217 | (EngineCore pid=196)   File "/usr/local/lib/python3.12/dist-packages/vllm/model_executor/model_loader/base_loader.py", line 55, in load_model
2026-04-19 12:59:20.217 | (EngineCore pid=196)     model = initialize_model(
2026-04-19 12:59:20.217 | (EngineCore pid=196)             ^^^^^^^^^^^^^^^^^
2026-04-19 12:59:20.217 | (EngineCore pid=196)   File "/usr/local/lib/python3.12/dist-packages/vllm/tracing/otel.py", line 178, in sync_wrapper
2026-04-19 12:59:20.217 | (EngineCore pid=196)     return func(*args, **kwargs)
2026-04-19 12:59:20.217 | (EngineCore pid=196)            ^^^^^^^^^^^^^^^^^^^^^
2026-04-19 12:59:20.217 | (EngineCore pid=196)   File "/usr/local/lib/python3.12/dist-packages/vllm/model_executor/model_loader/utils.py", line 57, in initialize_model
2026-04-19 12:59:20.217 | (EngineCore pid=196)     model = model_class(vllm_config=vllm_config, prefix=prefix)
2026-04-19 12:59:20.217 | (EngineCore pid=196)             ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
2026-04-19 12:59:20.217 | (EngineCore pid=196)   File "/usr/local/lib/python3.12/dist-packages/vllm/model_executor/models/gemma4_mm.py", line 946, in __init__
2026-04-19 12:59:20.217 | (EngineCore pid=196)     self.language_model: Gemma4ForCausalLM = init_vllm_registered_model(
2026-04-19 12:59:20.217 | (EngineCore pid=196)                                              ^^^^^^^^^^^^^^^^^^^^^^^^^^^
2026-04-19 12:59:20.217 | (EngineCore pid=196)   File "/usr/local/lib/python3.12/dist-packages/vllm/model_executor/models/utils.py", line 379, in init_vllm_registered_model
2026-04-19 12:59:20.217 | (EngineCore pid=196)     return initialize_model(vllm_config=vllm_config, prefix=prefix)
2026-04-19 12:59:20.217 | (EngineCore pid=196)            ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
2026-04-19 12:59:20.217 | (EngineCore pid=196)   File "/usr/local/lib/python3.12/dist-packages/vllm/tracing/otel.py", line 178, in sync_wrapper
2026-04-19 12:59:20.217 | (EngineCore pid=196)     return func(*args, **kwargs)
2026-04-19 12:59:20.217 | (EngineCore pid=196)            ^^^^^^^^^^^^^^^^^^^^^
2026-04-19 12:59:20.217 | (EngineCore pid=196)   File "/usr/local/lib/python3.12/dist-packages/vllm/model_executor/model_loader/utils.py", line 57, in initialize_model
2026-04-19 12:59:20.217 | (EngineCore pid=196)     model = model_class(vllm_config=vllm_config, prefix=prefix)
2026-04-19 12:59:20.217 | (EngineCore pid=196)             ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
2026-04-19 12:59:20.217 | (EngineCore pid=196)   File "/usr/local/lib/python3.12/dist-packages/vllm/model_executor/models/gemma4.py", line 1439, in __init__
2026-04-19 12:59:20.217 | (EngineCore pid=196)     self.model = Gemma4Model(
2026-04-19 12:59:20.217 | (EngineCore pid=196)                  ^^^^^^^^^^^^
2026-04-19 12:59:20.217 | (EngineCore pid=196)   File "/usr/local/lib/python3.12/dist-packages/vllm/compilation/decorators.py", line 379, in __init__
2026-04-19 12:59:20.217 | (EngineCore pid=196)     old_init(self, *args, **kwargs)
2026-04-19 12:59:20.217 | (EngineCore pid=196)   File "/usr/local/lib/python3.12/dist-packages/vllm/model_executor/models/gemma4.py", line 931, in __init__
2026-04-19 12:59:20.217 | (EngineCore pid=196)     self.start_layer, self.end_layer, self.layers = make_layers(
2026-04-19 12:59:20.217 | (EngineCore pid=196)                                                     ^^^^^^^^^^^^
2026-04-19 12:59:20.217 | (EngineCore pid=196)   File "/usr/local/lib/python3.12/dist-packages/vllm/model_executor/models/utils.py", line 646, in make_layers
2026-04-19 12:59:20.217 | (EngineCore pid=196)     + get_offloader().wrap_modules(
2026-04-19 12:59:20.217 | (EngineCore pid=196)       ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
2026-04-19 12:59:20.217 | (EngineCore pid=196)   File "/usr/local/lib/python3.12/dist-packages/vllm/model_executor/offloader/base.py", line 104, in wrap_modules
2026-04-19 12:59:20.217 | (EngineCore pid=196)     return list(modules_generator)
2026-04-19 12:59:20.217 | (EngineCore pid=196)            ^^^^^^^^^^^^^^^^^^^^^^^
2026-04-19 12:59:20.217 | (EngineCore pid=196)   File "/usr/local/lib/python3.12/dist-packages/vllm/model_executor/models/utils.py", line 647, in <genexpr>
2026-04-19 12:59:20.217 | (EngineCore pid=196)     layer_fn(prefix=f"{prefix}.{idx}") for idx in range(start_layer, end_layer)
2026-04-19 12:59:20.217 | (EngineCore pid=196)     ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
2026-04-19 12:59:20.217 | (EngineCore pid=196)   File "/usr/local/lib/python3.12/dist-packages/vllm/model_executor/models/gemma4.py", line 933, in <lambda>
2026-04-19 12:59:20.217 | (EngineCore pid=196)     lambda prefix: Gemma4DecoderLayer(
2026-04-19 12:59:20.217 | (EngineCore pid=196)                    ^^^^^^^^^^^^^^^^^^^
2026-04-19 12:59:20.217 | (EngineCore pid=196)   File "/usr/local/lib/python3.12/dist-packages/vllm/model_executor/models/gemma4.py", line 530, in __init__
2026-04-19 12:59:20.217 | (EngineCore pid=196)     self.moe = Gemma4MoE(
2026-04-19 12:59:20.217 | (EngineCore pid=196)                ^^^^^^^^^^
2026-04-19 12:59:20.217 | (EngineCore pid=196)   File "/usr/local/lib/python3.12/dist-packages/vllm/model_executor/models/gemma4.py", line 237, in __init__
2026-04-19 12:59:20.217 | (EngineCore pid=196)     self.experts = FusedMoE(
2026-04-19 12:59:20.217 | (EngineCore pid=196)                    ^^^^^^^^^
2026-04-19 12:59:20.217 | (EngineCore pid=196)   File "/usr/local/lib/python3.12/dist-packages/vllm/model_executor/layers/fused_moe/layer.py", line 520, in __init__
2026-04-19 12:59:20.217 | (EngineCore pid=196)     self.quant_method: FusedMoEMethodBase = _get_quant_method()
2026-04-19 12:59:20.217 | (EngineCore pid=196)                                             ^^^^^^^^^^^^^^^^^^^
2026-04-19 12:59:20.217 | (EngineCore pid=196)   File "/usr/local/lib/python3.12/dist-packages/vllm/model_executor/layers/fused_moe/layer.py", line 512, in _get_quant_method
2026-04-19 12:59:20.217 | (EngineCore pid=196)     quant_method = self.quant_config.get_quant_method(self, prefix)
2026-04-19 12:59:20.217 | (EngineCore pid=196)                    ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
2026-04-19 12:59:20.217 | (EngineCore pid=196)   File "/usr/local/lib/python3.12/dist-packages/vllm/model_executor/layers/quantization/compressed_tensors/compressed_tensors.py", line 196, in get_quant_method
2026-04-19 12:59:20.217 | (EngineCore pid=196)     return CompressedTensorsMoEMethod.get_moe_method(
2026-04-19 12:59:20.217 | (EngineCore pid=196)            ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
2026-04-19 12:59:20.217 | (EngineCore pid=196)   File "/usr/local/lib/python3.12/dist-packages/vllm/model_executor/layers/quantization/compressed_tensors/compressed_tensors_moe/compressed_tensors_moe.py", line 139, in get_moe_method
2026-04-19 12:59:20.217 | (EngineCore pid=196)     return CompressedTensorsW4A4Nvfp4MoEMethod(
2026-04-19 12:59:20.217 | (EngineCore pid=196)            ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
2026-04-19 12:59:20.217 | (EngineCore pid=196)   File "/usr/local/lib/python3.12/dist-packages/vllm/model_executor/layers/quantization/compressed_tensors/compressed_tensors_moe/compressed_tensors_moe_w4a4_nvfp4.py", line 47, in __init__
2026-04-19 12:59:20.217 | (EngineCore pid=196)     self.nvfp4_backend, self.experts_cls = select_nvfp4_moe_backend(
2026-04-19 12:59:20.217 | (EngineCore pid=196)                                            ^^^^^^^^^^^^^^^^^^^^^^^^^
2026-04-19 12:59:20.217 | (EngineCore pid=196)   File "/usr/local/lib/python3.12/dist-packages/vllm/model_executor/layers/fused_moe/oracle/nvfp4.py", line 211, in select_nvfp4_moe_backend
2026-04-19 12:59:20.217 | (EngineCore pid=196)     requested_backend = map_nvfp4_backend(runner_backend)
2026-04-19 12:59:20.217 | (EngineCore pid=196)                         ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
2026-04-19 12:59:20.217 | (EngineCore pid=196)   File "/usr/local/lib/python3.12/dist-packages/vllm/model_executor/layers/fused_moe/oracle/nvfp4.py", line 136, in map_nvfp4_backend
2026-04-19 12:59:20.217 | (EngineCore pid=196)     raise ValueError(
2026-04-19 12:59:20.217 | (EngineCore pid=196) ValueError: moe_backend='triton' is not supported for NvFP4 MoE. Expected one of ['cutlass', 'flashinfer_trtllm', 'flashinfer_cutlass', 'flashinfer_cutedsl', 'marlin'].
2026-04-19 12:59:20.756 | [rank0]:[W419 10:59:20.169257541 ProcessGroupNCCL.cpp:1575] Warning: WARNING: destroy_process_group() was not called before program exit, which can leak resources. For more info, please see https://pytorch.org/docs/stable/distributed.html#shutdown (function operator())
2026-04-19 12:59:21.541 | (APIServer pid=1) Traceback (most recent call last):
2026-04-19 12:59:21.541 | (APIServer pid=1)   File "/usr/local/bin/vllm", line 10, in <module>
2026-04-19 12:59:21.541 | (APIServer pid=1)     sys.exit(main())
2026-04-19 12:59:21.541 | (APIServer pid=1)              ^^^^^^
2026-04-19 12:59:21.541 | (APIServer pid=1)   File "/usr/local/lib/python3.12/dist-packages/vllm/entrypoints/cli/main.py", line 75, in main
2026-04-19 12:59:21.541 | (APIServer pid=1)     args.dispatch_function(args)
2026-04-19 12:59:21.541 | (APIServer pid=1)   File "/usr/local/lib/python3.12/dist-packages/vllm/entrypoints/cli/serve.py", line 122, in cmd
2026-04-19 12:59:21.541 | (APIServer pid=1)     uvloop.run(run_server(args))
2026-04-19 12:59:21.541 | (APIServer pid=1)   File "/usr/local/lib/python3.12/dist-packages/uvloop/__init__.py", line 96, in run
2026-04-19 12:59:21.541 | (APIServer pid=1)     return __asyncio.run(
2026-04-19 12:59:21.541 | (APIServer pid=1)            ^^^^^^^^^^^^^^
2026-04-19 12:59:21.541 | (APIServer pid=1)   File "/usr/lib/python3.12/asyncio/runners.py", line 195, in run
2026-04-19 12:59:21.541 | (APIServer pid=1)     return runner.run(main)
2026-04-19 12:59:21.541 | (APIServer pid=1)            ^^^^^^^^^^^^^^^^
2026-04-19 12:59:21.541 | (APIServer pid=1)   File "/usr/lib/python3.12/asyncio/runners.py", line 118, in run
2026-04-19 12:59:21.541 | (APIServer pid=1)     return self._loop.run_until_complete(task)
2026-04-19 12:59:21.541 | (APIServer pid=1)            ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
2026-04-19 12:59:21.541 | (APIServer pid=1)   File "uvloop/loop.pyx", line 1518, in uvloop.loop.Loop.run_until_complete
2026-04-19 12:59:21.541 | (APIServer pid=1)   File "/usr/local/lib/python3.12/dist-packages/uvloop/__init__.py", line 48, in wrapper
2026-04-19 12:59:21.541 | (APIServer pid=1)     return await main
2026-04-19 12:59:21.541 | (APIServer pid=1)            ^^^^^^^^^^
2026-04-19 12:59:21.541 | (APIServer pid=1)   File "/usr/local/lib/python3.12/dist-packages/vllm/entrypoints/openai/api_server.py", line 678, in run_server
2026-04-19 12:59:21.542 | (APIServer pid=1)     await run_server_worker(listen_address, sock, args, **uvicorn_kwargs)
2026-04-19 12:59:21.542 | (APIServer pid=1)   File "/usr/local/lib/python3.12/dist-packages/vllm/entrypoints/openai/api_server.py", line 692, in run_server_worker
2026-04-19 12:59:21.542 | (APIServer pid=1)     async with build_async_engine_client(
2026-04-19 12:59:21.542 | (APIServer pid=1)                ^^^^^^^^^^^^^^^^^^^^^^^^^^
2026-04-19 12:59:21.542 | (APIServer pid=1)   File "/usr/lib/python3.12/contextlib.py", line 210, in __aenter__
2026-04-19 12:59:21.542 | (APIServer pid=1)     return await anext(self.gen)
2026-04-19 12:59:21.542 | (APIServer pid=1)            ^^^^^^^^^^^^^^^^^^^^^
2026-04-19 12:59:21.542 | (APIServer pid=1)   File "/usr/local/lib/python3.12/dist-packages/vllm/entrypoints/openai/api_server.py", line 100, in build_async_engine_client
2026-04-19 12:59:21.542 | (APIServer pid=1)     async with build_async_engine_client_from_engine_args(
2026-04-19 12:59:21.542 | (APIServer pid=1)                ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
2026-04-19 12:59:21.542 | (APIServer pid=1)   File "/usr/lib/python3.12/contextlib.py", line 210, in __aenter__
2026-04-19 12:59:21.542 | (APIServer pid=1)     return await anext(self.gen)
2026-04-19 12:59:21.542 | (APIServer pid=1)            ^^^^^^^^^^^^^^^^^^^^^
2026-04-19 12:59:21.542 | (APIServer pid=1)   File "/usr/local/lib/python3.12/dist-packages/vllm/entrypoints/openai/api_server.py", line 136, in build_async_engine_client_from_engine_args
2026-04-19 12:59:21.542 | (APIServer pid=1)     async_llm = AsyncLLM.from_vllm_config(
2026-04-19 12:59:21.542 | (APIServer pid=1)                 ^^^^^^^^^^^^^^^^^^^^^^^^^^
2026-04-19 12:59:21.542 | (APIServer pid=1)   File "/usr/local/lib/python3.12/dist-packages/vllm/v1/engine/async_llm.py", line 219, in from_vllm_config
2026-04-19 12:59:21.542 | (APIServer pid=1)     return cls(
2026-04-19 12:59:21.542 | (APIServer pid=1)            ^^^^
2026-04-19 12:59:21.542 | (APIServer pid=1)   File "/usr/local/lib/python3.12/dist-packages/vllm/v1/engine/async_llm.py", line 148, in __init__
2026-04-19 12:59:21.542 | (APIServer pid=1)     self.engine_core = EngineCoreClient.make_async_mp_client(
2026-04-19 12:59:21.542 | (APIServer pid=1)                        ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
2026-04-19 12:59:21.542 | (APIServer pid=1)   File "/usr/local/lib/python3.12/dist-packages/vllm/tracing/otel.py", line 178, in sync_wrapper
2026-04-19 12:59:21.542 | (APIServer pid=1)     return func(*args, **kwargs)
2026-04-19 12:59:21.542 | (APIServer pid=1)            ^^^^^^^^^^^^^^^^^^^^^
2026-04-19 12:59:21.542 | (APIServer pid=1)   File "/usr/local/lib/python3.12/dist-packages/vllm/v1/engine/core_client.py", line 130, in make_async_mp_client
2026-04-19 12:59:21.543 | (APIServer pid=1)     return AsyncMPClient(*client_args)
2026-04-19 12:59:21.543 | (APIServer pid=1)            ^^^^^^^^^^^^^^^^^^^^^^^^^^^
2026-04-19 12:59:21.543 | (APIServer pid=1)   File "/usr/local/lib/python3.12/dist-packages/vllm/tracing/otel.py", line 178, in sync_wrapper
2026-04-19 12:59:21.543 | (APIServer pid=1)     return func(*args, **kwargs)
2026-04-19 12:59:21.543 | (APIServer pid=1)            ^^^^^^^^^^^^^^^^^^^^^
2026-04-19 12:59:21.543 | (APIServer pid=1)   File "/usr/local/lib/python3.12/dist-packages/vllm/v1/engine/core_client.py", line 900, in __init__
2026-04-19 12:59:21.543 | (APIServer pid=1)     super().__init__(
2026-04-19 12:59:21.543 | (APIServer pid=1)   File "/usr/local/lib/python3.12/dist-packages/vllm/v1/engine/core_client.py", line 535, in __init__
2026-04-19 12:59:21.543 | (APIServer pid=1)     with launch_core_engines(
2026-04-19 12:59:21.543 | (APIServer pid=1)          ^^^^^^^^^^^^^^^^^^^^
2026-04-19 12:59:21.543 | (APIServer pid=1)   File "/usr/lib/python3.12/contextlib.py", line 144, in __exit__
2026-04-19 12:59:21.543 | (APIServer pid=1)     next(self.gen)
2026-04-19 12:59:21.543 | (APIServer pid=1)   File "/usr/local/lib/python3.12/dist-packages/vllm/v1/engine/utils.py", line 1094, in launch_core_engines
2026-04-19 12:59:21.543 | (APIServer pid=1)     wait_for_engine_startup(
2026-04-19 12:59:21.543 | (APIServer pid=1)   File "/usr/local/lib/python3.12/dist-packages/vllm/v1/engine/utils.py", line 1153, in wait_for_engine_startup
2026-04-19 12:59:21.543 | (APIServer pid=1)     raise RuntimeError(
2026-04-19 12:59:21.543 | (APIServer pid=1) RuntimeError: Engine core initialization failed. See root cause above. Failed core proc(s): {}