# docker-compose
services:
  qwen3-6-moe-nvfp4:
    image: vllm/vllm-openai:nightly
    container_name: qwen3-6-moe-35b-a3b-nvfp4
    hostname: qwen3-6-moe-35b-a3b-nvfp4
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
      - "RedHatAI/Qwen3.6-35B-A3B-NVFP4"
      - "--served-model-name"
      - "RedHatAI/Qwen3.6-35B-A3B-NVFP4"
      - "--host"
      - "0.0.0.0"
      - "--port"
      - "8000"
      - "--tensor-parallel-size"
      - "1"
      - "--gpu-memory-utilization"
      - "0.88"
      - "--max-model-len"
      - "131072"
      - "--kv-cache-dtype"
      - "fp8_e4m3"
      - "--quantization"
      - "compressed-tensors"
      - "--reasoning-parser"
      - "qwen3"
      - "--tool-call-parser"
      - "qwen3_coder"
      - "--moe-backend"
      - "triton"
      - "--enable-prefix-caching"
      - "--enable-chunked-prefill"
      - "--max-num-seqs"
      - "256"
      - "--max-num-batched-tokens"
      - "32768"
      - "--trust-remote-code"
    networks:
      - development-network

networks:
  development-network:
    external: true


# vllm log
2026-04-19 11:01:32.190 | WARNING 04-19 09:01:32 [interface.py:686] Using 'pin_memory=False' as WSL is detected. This may slow down the performance.
2026-04-19 11:01:32.275 | (APIServer pid=1) INFO 04-19 09:01:32 [utils.py:299] 
2026-04-19 11:01:32.275 | (APIServer pid=1) INFO 04-19 09:01:32 [utils.py:299]        █     █     █▄   ▄█
2026-04-19 11:01:32.275 | (APIServer pid=1) INFO 04-19 09:01:32 [utils.py:299]  ▄▄ ▄█ █     █     █ ▀▄▀ █  version 0.19.2rc1.dev8+g4b7f5ea1a
2026-04-19 11:01:32.275 | (APIServer pid=1) INFO 04-19 09:01:32 [utils.py:299]   █▄█▀ █     █     █     █  model   RedHatAI/Qwen3.6-35B-A3B-NVFP4
2026-04-19 11:01:32.275 | (APIServer pid=1) INFO 04-19 09:01:32 [utils.py:299]    ▀▀  ▀▀▀▀▀ ▀▀▀▀▀ ▀     ▀
2026-04-19 11:01:32.275 | (APIServer pid=1) INFO 04-19 09:01:32 [utils.py:299] 
2026-04-19 11:01:32.278 | (APIServer pid=1) INFO 04-19 09:01:32 [utils.py:233] non-default args: {'model_tag': 'RedHatAI/Qwen3.6-35B-A3B-NVFP4', 'tool_call_parser': 'qwen3_coder', 'host': '0.0.0.0', 'model': 'RedHatAI/Qwen3.6-35B-A3B-NVFP4', 'trust_remote_code': True, 'max_model_len': 131072, 'quantization': 'compressed-tensors', 'served_model_name': ['RedHatAI/Qwen3.6-35B-A3B-NVFP4'], 'reasoning_parser': 'qwen3', 'gpu_memory_utilization': 0.88, 'kv_cache_dtype': 'fp8_e4m3', 'enable_prefix_caching': True, 'max_num_batched_tokens': 32768, 'max_num_seqs': 256, 'enable_chunked_prefill': True, 'moe_backend': 'triton'}
2026-04-19 11:01:32.715 | (APIServer pid=1) Warning: You are sending unauthenticated requests to the HF Hub. Please set a HF_TOKEN to enable higher rate limits and faster downloads.
2026-04-19 11:01:42.552 | (APIServer pid=1) INFO 04-19 09:01:42 [model.py:554] Resolved architecture: Qwen3_5MoeForConditionalGeneration
2026-04-19 11:01:42.553 | (APIServer pid=1) INFO 04-19 09:01:42 [model.py:1685] Using max model len 131072
2026-04-19 11:01:42.834 | (APIServer pid=1) INFO 04-19 09:01:42 [cache.py:247] Using fp8_e4m3 data type to store kv cache. It reduces the GPU memory footprint and boosts the performance. Meanwhile, it may cause accuracy drop without a proper scaling factor
2026-04-19 11:01:42.835 | (APIServer pid=1) INFO 04-19 09:01:42 [scheduler.py:239] Chunked prefill is enabled with max_num_batched_tokens=32768.
2026-04-19 11:01:42.835 | (APIServer pid=1) WARNING 04-19 09:01:42 [config.py:331] Mamba cache mode is set to 'align' for Qwen3_5MoeForConditionalGeneration by default when prefix caching is enabled
2026-04-19 11:01:42.835 | (APIServer pid=1) INFO 04-19 09:01:42 [config.py:351] Warning: Prefix caching in Mamba cache 'align' mode is currently enabled. Its support for Mamba layers is experimental. Please report any issues you may observe.
2026-04-19 11:01:42.835 | (APIServer pid=1) INFO 04-19 09:01:42 [vllm.py:834] Asynchronous scheduling is enabled.
2026-04-19 11:01:42.836 | (APIServer pid=1) INFO 04-19 09:01:42 [kernel.py:199] Final IR op priority after setting platform defaults: IrOpPriorityConfig(rms_norm=['native'])
2026-04-19 11:01:45.572 | (APIServer pid=1) INFO 04-19 09:01:45 [compilation.py:294] Enabled custom fusions: act_quant
2026-04-19 11:01:45.734 | (APIServer pid=1) `Qwen2VLImageProcessorFast` is deprecated. The `Fast` suffix for image processors has been removed; use `Qwen2VLImageProcessor` instead.
2026-04-19 11:01:53.952 | (APIServer pid=1) The `use_fast` parameter is deprecated and will be removed in a future version. Use `backend="torchvision"` instead of `use_fast=True`, or `backend="pil"` instead of `use_fast=False`.
2026-04-19 11:02:05.036 | (EngineCore pid=207) INFO 04-19 09:02:05 [core.py:107] Initializing a V1 LLM engine (v0.19.2rc1.dev8+g4b7f5ea1a) with config: model='RedHatAI/Qwen3.6-35B-A3B-NVFP4', speculative_config=None, tokenizer='RedHatAI/Qwen3.6-35B-A3B-NVFP4', skip_tokenizer_init=False, tokenizer_mode=auto, revision=None, tokenizer_revision=None, trust_remote_code=True, dtype=torch.bfloat16, max_seq_len=131072, download_dir=None, load_format=auto, tensor_parallel_size=1, pipeline_parallel_size=1, data_parallel_size=1, decode_context_parallel_size=1, dcp_comm_backend=ag_rs, disable_custom_all_reduce=False, quantization=compressed-tensors, quantization_config=None, enforce_eager=False, enable_return_routed_experts=False, kv_cache_dtype=fp8_e4m3, device_config=cuda, structured_outputs_config=StructuredOutputsConfig(backend='auto', disable_any_whitespace=False, disable_additional_properties=False, reasoning_parser='qwen3', reasoning_parser_plugin='', enable_in_reasoning=False), observability_config=ObservabilityConfig(show_hidden_metrics_for_version=None, otlp_traces_endpoint=None, collect_detailed_traces=None, kv_cache_metrics=False, kv_cache_metrics_sample=0.01, cudagraph_metrics=False, enable_layerwise_nvtx_tracing=False, enable_mfu_metrics=False, enable_mm_processor_stats=False, enable_logging_iteration_details=False), seed=0, served_model_name=RedHatAI/Qwen3.6-35B-A3B-NVFP4, enable_prefix_caching=True, enable_chunked_prefill=True, pooler_config=None, compilation_config={'mode': <CompilationMode.VLLM_COMPILE: 3>, 'debug_dump_path': None, 'cache_dir': '', 'compile_cache_save_format': 'binary', 'backend': 'inductor', 'custom_ops': ['none'], 'ir_enable_torch_wrap': True, 'splitting_ops': ['vllm::unified_attention_with_output', 'vllm::unified_mla_attention_with_output', 'vllm::mamba_mixer2', 'vllm::mamba_mixer', 'vllm::short_conv', 'vllm::linear_attention', 'vllm::plamo2_mamba_mixer', 'vllm::gdn_attention_core', 'vllm::olmo_hybrid_gdn_full_forward', 'vllm::kda_attention', 'vllm::sparse_attn_indexer', 'vllm::rocm_aiter_sparse_attn_indexer', 'vllm::unified_kv_cache_update', 'vllm::unified_mla_kv_cache_update'], 'compile_mm_encoder': False, 'cudagraph_mm_encoder': False, 'encoder_cudagraph_token_budgets': [], 'encoder_cudagraph_max_vision_items_per_batch': 0, 'encoder_cudagraph_max_frames_per_batch': 0, 'compile_sizes': [], 'compile_ranges_endpoints': [32768], 'inductor_compile_config': {'enable_auto_functionalized_v2': False, 'size_asserts': False, 'alignment_asserts': False, 'scalar_asserts': False, 'combo_kernels': True, 'benchmark_combo_kernel': True}, 'inductor_passes': {}, 'cudagraph_mode': <CUDAGraphMode.FULL_AND_PIECEWISE: (2, 1)>, 'cudagraph_num_of_warmups': 1, 'cudagraph_capture_sizes': [1, 2, 4, 8, 16, 24, 32, 40, 48, 56, 64, 72, 80, 88, 96, 104, 112, 120, 128, 136, 144, 152, 160, 168, 176, 184, 192, 200, 208, 216, 224, 232, 240, 248, 256, 272, 288, 304, 320, 336, 352, 368, 384, 400, 416, 432, 448, 464, 480, 496, 512], 'cudagraph_copy_inputs': False, 'cudagraph_specialize_lora': True, 'use_inductor_graph_partition': False, 'pass_config': {'fuse_norm_quant': False, 'fuse_act_quant': True, 'fuse_attn_quant': False, 'enable_sp': False, 'fuse_gemm_comms': False, 'fuse_allreduce_rms': False}, 'max_cudagraph_capture_size': 512, 'dynamic_shapes_config': {'type': <DynamicShapesType.BACKED: 'backed'>, 'evaluate_guards': False, 'assume_32_bit_indexing': False}, 'local_cache_dir': None, 'fast_moe_cold_start': False, 'static_all_moe_layers': []}, kernel_config=KernelConfig(ir_op_priority=IrOpPriorityConfig(rms_norm=['native']), enable_flashinfer_autotune=True, moe_backend='triton')
2026-04-19 11:02:05.231 | (EngineCore pid=207) WARNING 04-19 09:02:05 [interface.py:686] Using 'pin_memory=False' as WSL is detected. This may slow down the performance.
2026-04-19 11:02:05.343 | (EngineCore pid=207) `Qwen2VLImageProcessorFast` is deprecated. The `Fast` suffix for image processors has been removed; use `Qwen2VLImageProcessor` instead.
2026-04-19 11:02:05.640 | (EngineCore pid=207) Warning: You are sending unauthenticated requests to the HF Hub. Please set a HF_TOKEN to enable higher rate limits and faster downloads.
2026-04-19 11:02:08.479 | (EngineCore pid=207) INFO 04-19 09:02:08 [parallel_state.py:1400] world_size=1 rank=0 local_rank=0 distributed_init_method=tcp://172.18.0.2:39779 backend=nccl
2026-04-19 11:02:08.636 | (EngineCore pid=207) INFO 04-19 09:02:08 [parallel_state.py:1713] rank 0 in world size 1 is assigned as DP rank 0, PP rank 0, PCP rank 0, TP rank 0, EP rank 0, EPLB rank N/A
2026-04-19 11:02:15.108 | (EngineCore pid=207) The `use_fast` parameter is deprecated and will be removed in a future version. Use `backend="torchvision"` instead of `use_fast=True`, or `backend="pil"` instead of `use_fast=False`.
2026-04-19 11:02:20.547 | (EngineCore pid=207) INFO 04-19 09:02:20 [gpu_model_runner.py:4752] Starting to load model RedHatAI/Qwen3.6-35B-A3B-NVFP4...
2026-04-19 11:02:20.928 | (EngineCore pid=207) INFO 04-19 09:02:20 [cuda.py:424] Using backend AttentionBackendEnum.FLASH_ATTN for vit attention
2026-04-19 11:02:20.930 | (EngineCore pid=207) INFO 04-19 09:02:20 [mm_encoder_attention.py:230] Using AttentionBackendEnum.FLASH_ATTN for MMEncoderAttention.
2026-04-19 11:02:20.980 | (EngineCore pid=207) INFO 04-19 09:02:20 [gdn_linear_attn.py:155] Using Triton/FLA GDN prefill kernel
2026-04-19 11:02:20.981 | (EngineCore pid=207) INFO 04-19 09:02:20 [__init__.py:683] Using FlashInferCutlassNvFp4LinearKernel for NVFP4 GEMM
2026-04-19 11:02:21.410 | (EngineCore pid=207) Process EngineCore:
2026-04-19 11:02:21.410 | (EngineCore pid=207) ERROR 04-19 09:02:21 [core.py:1132] EngineCore failed to start.
2026-04-19 11:02:21.410 | (EngineCore pid=207) ERROR 04-19 09:02:21 [core.py:1132] Traceback (most recent call last):
2026-04-19 11:02:21.410 | (EngineCore pid=207) ERROR 04-19 09:02:21 [core.py:1132]   File "/usr/local/lib/python3.12/dist-packages/vllm/v1/engine/core.py", line 1106, in run_engine_core
2026-04-19 11:02:21.410 | (EngineCore pid=207) ERROR 04-19 09:02:21 [core.py:1132]     engine_core = EngineCoreProc(*args, engine_index=dp_rank, **kwargs)
2026-04-19 11:02:21.410 | (EngineCore pid=207) ERROR 04-19 09:02:21 [core.py:1132]                   ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
2026-04-19 11:02:21.410 | (EngineCore pid=207) ERROR 04-19 09:02:21 [core.py:1132]   File "/usr/local/lib/python3.12/dist-packages/vllm/tracing/otel.py", line 178, in sync_wrapper
2026-04-19 11:02:21.410 | (EngineCore pid=207) ERROR 04-19 09:02:21 [core.py:1132]     return func(*args, **kwargs)
2026-04-19 11:02:21.410 | (EngineCore pid=207) ERROR 04-19 09:02:21 [core.py:1132]            ^^^^^^^^^^^^^^^^^^^^^
2026-04-19 11:02:21.410 | (EngineCore pid=207) ERROR 04-19 09:02:21 [core.py:1132]   File "/usr/local/lib/python3.12/dist-packages/vllm/v1/engine/core.py", line 872, in __init__
2026-04-19 11:02:21.410 | (EngineCore pid=207) ERROR 04-19 09:02:21 [core.py:1132]     super().__init__(
2026-04-19 11:02:21.410 | (EngineCore pid=207) ERROR 04-19 09:02:21 [core.py:1132]   File "/usr/local/lib/python3.12/dist-packages/vllm/v1/engine/core.py", line 116, in __init__
2026-04-19 11:02:21.410 | (EngineCore pid=207) ERROR 04-19 09:02:21 [core.py:1132]     self.model_executor = executor_class(vllm_config)
2026-04-19 11:02:21.410 | (EngineCore pid=207) ERROR 04-19 09:02:21 [core.py:1132]                           ^^^^^^^^^^^^^^^^^^^^^^^^^^^
2026-04-19 11:02:21.410 | (EngineCore pid=207) ERROR 04-19 09:02:21 [core.py:1132]   File "/usr/local/lib/python3.12/dist-packages/vllm/tracing/otel.py", line 178, in sync_wrapper
2026-04-19 11:02:21.410 | (EngineCore pid=207) ERROR 04-19 09:02:21 [core.py:1132]     return func(*args, **kwargs)
2026-04-19 11:02:21.410 | (EngineCore pid=207) ERROR 04-19 09:02:21 [core.py:1132]            ^^^^^^^^^^^^^^^^^^^^^
2026-04-19 11:02:21.410 | (EngineCore pid=207) ERROR 04-19 09:02:21 [core.py:1132]   File "/usr/local/lib/python3.12/dist-packages/vllm/v1/executor/abstract.py", line 109, in __init__
2026-04-19 11:02:21.410 | (EngineCore pid=207) ERROR 04-19 09:02:21 [core.py:1132]     self._init_executor()
2026-04-19 11:02:21.410 | (EngineCore pid=207) ERROR 04-19 09:02:21 [core.py:1132]   File "/usr/local/lib/python3.12/dist-packages/vllm/v1/executor/uniproc_executor.py", line 52, in _init_executor
2026-04-19 11:02:21.410 | (EngineCore pid=207) ERROR 04-19 09:02:21 [core.py:1132]     self.driver_worker.load_model()
2026-04-19 11:02:21.410 | (EngineCore pid=207) ERROR 04-19 09:02:21 [core.py:1132]   File "/usr/local/lib/python3.12/dist-packages/vllm/v1/worker/gpu_worker.py", line 323, in load_model
2026-04-19 11:02:21.410 | (EngineCore pid=207) ERROR 04-19 09:02:21 [core.py:1132]     self.model_runner.load_model(load_dummy_weights=load_dummy_weights)
2026-04-19 11:02:21.410 | (EngineCore pid=207) ERROR 04-19 09:02:21 [core.py:1132]   File "/usr/local/lib/python3.12/dist-packages/vllm/tracing/otel.py", line 178, in sync_wrapper
2026-04-19 11:02:21.410 | (EngineCore pid=207) ERROR 04-19 09:02:21 [core.py:1132]     return func(*args, **kwargs)
2026-04-19 11:02:21.410 | (EngineCore pid=207) ERROR 04-19 09:02:21 [core.py:1132]            ^^^^^^^^^^^^^^^^^^^^^
2026-04-19 11:02:21.410 | (EngineCore pid=207) ERROR 04-19 09:02:21 [core.py:1132]   File "/usr/local/lib/python3.12/dist-packages/vllm/v1/worker/gpu_model_runner.py", line 4768, in load_model
2026-04-19 11:02:21.410 | (EngineCore pid=207) ERROR 04-19 09:02:21 [core.py:1132]     self.model = model_loader.load_model(
2026-04-19 11:02:21.410 | (EngineCore pid=207) ERROR 04-19 09:02:21 [core.py:1132]                  ^^^^^^^^^^^^^^^^^^^^^^^^
2026-04-19 11:02:21.410 | (EngineCore pid=207) ERROR 04-19 09:02:21 [core.py:1132]   File "/usr/local/lib/python3.12/dist-packages/vllm/tracing/otel.py", line 178, in sync_wrapper
2026-04-19 11:02:21.410 | (EngineCore pid=207) ERROR 04-19 09:02:21 [core.py:1132]     return func(*args, **kwargs)
2026-04-19 11:02:21.410 | (EngineCore pid=207) ERROR 04-19 09:02:21 [core.py:1132]            ^^^^^^^^^^^^^^^^^^^^^
2026-04-19 11:02:21.410 | (EngineCore pid=207) ERROR 04-19 09:02:21 [core.py:1132]   File "/usr/local/lib/python3.12/dist-packages/vllm/model_executor/model_loader/base_loader.py", line 55, in load_model
2026-04-19 11:02:21.410 | (EngineCore pid=207) ERROR 04-19 09:02:21 [core.py:1132]     model = initialize_model(
2026-04-19 11:02:21.410 | (EngineCore pid=207) ERROR 04-19 09:02:21 [core.py:1132]             ^^^^^^^^^^^^^^^^^
2026-04-19 11:02:21.410 | (EngineCore pid=207) ERROR 04-19 09:02:21 [core.py:1132]   File "/usr/local/lib/python3.12/dist-packages/vllm/tracing/otel.py", line 178, in sync_wrapper
2026-04-19 11:02:21.410 | (EngineCore pid=207) ERROR 04-19 09:02:21 [core.py:1132]     return func(*args, **kwargs)
2026-04-19 11:02:21.410 | (EngineCore pid=207) ERROR 04-19 09:02:21 [core.py:1132]            ^^^^^^^^^^^^^^^^^^^^^
2026-04-19 11:02:21.410 | (EngineCore pid=207) ERROR 04-19 09:02:21 [core.py:1132]   File "/usr/local/lib/python3.12/dist-packages/vllm/model_executor/model_loader/utils.py", line 57, in initialize_model
2026-04-19 11:02:21.410 | (EngineCore pid=207) ERROR 04-19 09:02:21 [core.py:1132]     model = model_class(vllm_config=vllm_config, prefix=prefix)
2026-04-19 11:02:21.410 | (EngineCore pid=207) ERROR 04-19 09:02:21 [core.py:1132]             ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
2026-04-19 11:02:21.410 | (EngineCore pid=207) ERROR 04-19 09:02:21 [core.py:1132]   File "/usr/local/lib/python3.12/dist-packages/vllm/model_executor/models/qwen3_5.py", line 831, in __init__
2026-04-19 11:02:21.410 | (EngineCore pid=207) ERROR 04-19 09:02:21 [core.py:1132]     self.language_model = Qwen3_5MoeForCausalLM(
2026-04-19 11:02:21.410 | (EngineCore pid=207) ERROR 04-19 09:02:21 [core.py:1132]                           ^^^^^^^^^^^^^^^^^^^^^^
2026-04-19 11:02:21.410 | (EngineCore pid=207) ERROR 04-19 09:02:21 [core.py:1132]   File "/usr/local/lib/python3.12/dist-packages/vllm/model_executor/models/qwen3_5.py", line 555, in __init__
2026-04-19 11:02:21.410 | (EngineCore pid=207) ERROR 04-19 09:02:21 [core.py:1132]     super().__init__(vllm_config=vllm_config, prefix=prefix)
2026-04-19 11:02:21.410 | (EngineCore pid=207) ERROR 04-19 09:02:21 [core.py:1132]   File "/usr/local/lib/python3.12/dist-packages/vllm/model_executor/models/qwen3_5.py", line 481, in __init__
2026-04-19 11:02:21.410 | (EngineCore pid=207) ERROR 04-19 09:02:21 [core.py:1132]     self.model = Qwen3_5Model(
2026-04-19 11:02:21.410 | (EngineCore pid=207) ERROR 04-19 09:02:21 [core.py:1132]                  ^^^^^^^^^^^^^
2026-04-19 11:02:21.410 | (EngineCore pid=207) ERROR 04-19 09:02:21 [core.py:1132]   File "/usr/local/lib/python3.12/dist-packages/vllm/compilation/decorators.py", line 379, in __init__
2026-04-19 11:02:21.410 | (EngineCore pid=207) ERROR 04-19 09:02:21 [core.py:1132]     old_init(self, *args, **kwargs)
2026-04-19 11:02:21.410 | (EngineCore pid=207) ERROR 04-19 09:02:21 [core.py:1132]   File "/usr/local/lib/python3.12/dist-packages/vllm/model_executor/models/qwen3_5.py", line 236, in __init__
2026-04-19 11:02:21.410 | (EngineCore pid=207) ERROR 04-19 09:02:21 [core.py:1132]     self.start_layer, self.end_layer, self.layers = make_layers(
2026-04-19 11:02:21.410 | (EngineCore pid=207) ERROR 04-19 09:02:21 [core.py:1132]                                                     ^^^^^^^^^^^^
2026-04-19 11:02:21.410 | (EngineCore pid=207) ERROR 04-19 09:02:21 [core.py:1132]   File "/usr/local/lib/python3.12/dist-packages/vllm/model_executor/models/utils.py", line 646, in make_layers
2026-04-19 11:02:21.410 | (EngineCore pid=207) ERROR 04-19 09:02:21 [core.py:1132]     + get_offloader().wrap_modules(
2026-04-19 11:02:21.410 | (EngineCore pid=207) ERROR 04-19 09:02:21 [core.py:1132]       ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
2026-04-19 11:02:21.410 | (EngineCore pid=207) ERROR 04-19 09:02:21 [core.py:1132]   File "/usr/local/lib/python3.12/dist-packages/vllm/model_executor/offloader/base.py", line 104, in wrap_modules
2026-04-19 11:02:21.410 | (EngineCore pid=207) ERROR 04-19 09:02:21 [core.py:1132]     return list(modules_generator)
2026-04-19 11:02:21.410 | (EngineCore pid=207) ERROR 04-19 09:02:21 [core.py:1132]            ^^^^^^^^^^^^^^^^^^^^^^^
2026-04-19 11:02:21.410 | (EngineCore pid=207) ERROR 04-19 09:02:21 [core.py:1132]   File "/usr/local/lib/python3.12/dist-packages/vllm/model_executor/models/utils.py", line 647, in <genexpr>
2026-04-19 11:02:21.410 | (EngineCore pid=207) ERROR 04-19 09:02:21 [core.py:1132]     layer_fn(prefix=f"{prefix}.{idx}") for idx in range(start_layer, end_layer)
2026-04-19 11:02:21.410 | (EngineCore pid=207) ERROR 04-19 09:02:21 [core.py:1132]     ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
2026-04-19 11:02:21.410 | (EngineCore pid=207) ERROR 04-19 09:02:21 [core.py:1132]   File "/usr/local/lib/python3.12/dist-packages/vllm/model_executor/models/qwen3_5.py", line 230, in get_layer
2026-04-19 11:02:21.410 | (EngineCore pid=207) ERROR 04-19 09:02:21 [core.py:1132]     return Qwen3_5DecoderLayer(
2026-04-19 11:02:21.410 | (EngineCore pid=207) ERROR 04-19 09:02:21 [core.py:1132]            ^^^^^^^^^^^^^^^^^^^^
2026-04-19 11:02:21.410 | (EngineCore pid=207) ERROR 04-19 09:02:21 [core.py:1132]   File "/usr/local/lib/python3.12/dist-packages/vllm/model_executor/models/qwen3_5.py", line 157, in __init__
2026-04-19 11:02:21.410 | (EngineCore pid=207) ERROR 04-19 09:02:21 [core.py:1132]     self.mlp = Qwen3NextSparseMoeBlock(
2026-04-19 11:02:21.410 | (EngineCore pid=207) ERROR 04-19 09:02:21 [core.py:1132]                ^^^^^^^^^^^^^^^^^^^^^^^^
2026-04-19 11:02:21.410 | (EngineCore pid=207) ERROR 04-19 09:02:21 [core.py:1132]   File "/usr/local/lib/python3.12/dist-packages/vllm/model_executor/models/qwen3_next.py", line 149, in __init__
2026-04-19 11:02:21.410 | (EngineCore pid=207) ERROR 04-19 09:02:21 [core.py:1132]     self.experts = SharedFusedMoE(
2026-04-19 11:02:21.410 | (EngineCore pid=207) ERROR 04-19 09:02:21 [core.py:1132]                    ^^^^^^^^^^^^^^^
2026-04-19 11:02:21.410 | (EngineCore pid=207) ERROR 04-19 09:02:21 [core.py:1132]   File "/usr/local/lib/python3.12/dist-packages/vllm/model_executor/layers/fused_moe/layer.py", line 520, in __init__
2026-04-19 11:02:21.410 | (EngineCore pid=207) ERROR 04-19 09:02:21 [core.py:1132]     self.quant_method: FusedMoEMethodBase = _get_quant_method()
2026-04-19 11:02:21.410 | (EngineCore pid=207) ERROR 04-19 09:02:21 [core.py:1132]                                             ^^^^^^^^^^^^^^^^^^^
2026-04-19 11:02:21.410 | (EngineCore pid=207) ERROR 04-19 09:02:21 [core.py:1132]   File "/usr/local/lib/python3.12/dist-packages/vllm/model_executor/layers/fused_moe/layer.py", line 512, in _get_quant_method
2026-04-19 11:02:21.410 | (EngineCore pid=207) ERROR 04-19 09:02:21 [core.py:1132]     quant_method = self.quant_config.get_quant_method(self, prefix)
2026-04-19 11:02:21.410 | (EngineCore pid=207) ERROR 04-19 09:02:21 [core.py:1132]                    ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
2026-04-19 11:02:21.410 | (EngineCore pid=207) ERROR 04-19 09:02:21 [core.py:1132]   File "/usr/local/lib/python3.12/dist-packages/vllm/model_executor/layers/quantization/compressed_tensors/compressed_tensors.py", line 196, in get_quant_method
2026-04-19 11:02:21.410 | (EngineCore pid=207) ERROR 04-19 09:02:21 [core.py:1132]     return CompressedTensorsMoEMethod.get_moe_method(
2026-04-19 11:02:21.410 | (EngineCore pid=207) ERROR 04-19 09:02:21 [core.py:1132]            ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
2026-04-19 11:02:21.410 | (EngineCore pid=207) ERROR 04-19 09:02:21 [core.py:1132]   File "/usr/local/lib/python3.12/dist-packages/vllm/model_executor/layers/quantization/compressed_tensors/compressed_tensors_moe/compressed_tensors_moe.py", line 139, in get_moe_method
2026-04-19 11:02:21.410 | (EngineCore pid=207) ERROR 04-19 09:02:21 [core.py:1132]     return CompressedTensorsW4A4Nvfp4MoEMethod(
2026-04-19 11:02:21.410 | (EngineCore pid=207) ERROR 04-19 09:02:21 [core.py:1132]            ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
2026-04-19 11:02:21.410 | (EngineCore pid=207) ERROR 04-19 09:02:21 [core.py:1132]   File "/usr/local/lib/python3.12/dist-packages/vllm/model_executor/layers/quantization/compressed_tensors/compressed_tensors_moe/compressed_tensors_moe_w4a4_nvfp4.py", line 47, in __init__
2026-04-19 11:02:21.410 | (EngineCore pid=207) ERROR 04-19 09:02:21 [core.py:1132]     self.nvfp4_backend, self.experts_cls = select_nvfp4_moe_backend(
2026-04-19 11:02:21.410 | (EngineCore pid=207) ERROR 04-19 09:02:21 [core.py:1132]                                            ^^^^^^^^^^^^^^^^^^^^^^^^^
2026-04-19 11:02:21.410 | (EngineCore pid=207) ERROR 04-19 09:02:21 [core.py:1132]   File "/usr/local/lib/python3.12/dist-packages/vllm/model_executor/layers/fused_moe/oracle/nvfp4.py", line 211, in select_nvfp4_moe_backend
2026-04-19 11:02:21.410 | (EngineCore pid=207) ERROR 04-19 09:02:21 [core.py:1132]     requested_backend = map_nvfp4_backend(runner_backend)
2026-04-19 11:02:21.410 | (EngineCore pid=207) ERROR 04-19 09:02:21 [core.py:1132]                         ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
2026-04-19 11:02:21.410 | (EngineCore pid=207) ERROR 04-19 09:02:21 [core.py:1132]   File "/usr/local/lib/python3.12/dist-packages/vllm/model_executor/layers/fused_moe/oracle/nvfp4.py", line 136, in map_nvfp4_backend
2026-04-19 11:02:21.410 | (EngineCore pid=207) ERROR 04-19 09:02:21 [core.py:1132]     raise ValueError(
2026-04-19 11:02:21.410 | (EngineCore pid=207) ERROR 04-19 09:02:21 [core.py:1132] ValueError: moe_backend='triton' is not supported for NvFP4 MoE. Expected one of ['cutlass', 'flashinfer_trtllm', 'flashinfer_cutlass', 'flashinfer_cutedsl', 'marlin'].
2026-04-19 11:02:21.411 | (EngineCore pid=207) Traceback (most recent call last):
2026-04-19 11:02:21.411 | (EngineCore pid=207)   File "/usr/lib/python3.12/multiprocessing/process.py", line 314, in _bootstrap
2026-04-19 11:02:21.411 | (EngineCore pid=207)     self.run()
2026-04-19 11:02:21.411 | (EngineCore pid=207)   File "/usr/lib/python3.12/multiprocessing/process.py", line 108, in run
2026-04-19 11:02:21.411 | (EngineCore pid=207)     self._target(*self._args, **self._kwargs)
2026-04-19 11:02:21.411 | (EngineCore pid=207)   File "/usr/local/lib/python3.12/dist-packages/vllm/v1/engine/core.py", line 1136, in run_engine_core
2026-04-19 11:02:21.411 | (EngineCore pid=207)     raise e
2026-04-19 11:02:21.411 | (EngineCore pid=207)   File "/usr/local/lib/python3.12/dist-packages/vllm/v1/engine/core.py", line 1106, in run_engine_core
2026-04-19 11:02:21.411 | (EngineCore pid=207)     engine_core = EngineCoreProc(*args, engine_index=dp_rank, **kwargs)
2026-04-19 11:02:21.411 | (EngineCore pid=207)                   ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
2026-04-19 11:02:21.411 | (EngineCore pid=207)   File "/usr/local/lib/python3.12/dist-packages/vllm/tracing/otel.py", line 178, in sync_wrapper
2026-04-19 11:02:21.411 | (EngineCore pid=207)     return func(*args, **kwargs)
2026-04-19 11:02:21.411 | (EngineCore pid=207)            ^^^^^^^^^^^^^^^^^^^^^
2026-04-19 11:02:21.411 | (EngineCore pid=207)   File "/usr/local/lib/python3.12/dist-packages/vllm/v1/engine/core.py", line 872, in __init__
2026-04-19 11:02:21.411 | (EngineCore pid=207)     super().__init__(
2026-04-19 11:02:21.411 | (EngineCore pid=207)   File "/usr/local/lib/python3.12/dist-packages/vllm/v1/engine/core.py", line 116, in __init__
2026-04-19 11:02:21.411 | (EngineCore pid=207)     self.model_executor = executor_class(vllm_config)
2026-04-19 11:02:21.411 | (EngineCore pid=207)                           ^^^^^^^^^^^^^^^^^^^^^^^^^^^
2026-04-19 11:02:21.411 | (EngineCore pid=207)   File "/usr/local/lib/python3.12/dist-packages/vllm/tracing/otel.py", line 178, in sync_wrapper
2026-04-19 11:02:21.411 | (EngineCore pid=207)     return func(*args, **kwargs)
2026-04-19 11:02:21.411 | (EngineCore pid=207)            ^^^^^^^^^^^^^^^^^^^^^
2026-04-19 11:02:21.411 | (EngineCore pid=207)   File "/usr/local/lib/python3.12/dist-packages/vllm/v1/executor/abstract.py", line 109, in __init__
2026-04-19 11:02:21.411 | (EngineCore pid=207)     self._init_executor()
2026-04-19 11:02:21.411 | (EngineCore pid=207)   File "/usr/local/lib/python3.12/dist-packages/vllm/v1/executor/uniproc_executor.py", line 52, in _init_executor
2026-04-19 11:02:21.411 | (EngineCore pid=207)     self.driver_worker.load_model()
2026-04-19 11:02:21.411 | (EngineCore pid=207)   File "/usr/local/lib/python3.12/dist-packages/vllm/v1/worker/gpu_worker.py", line 323, in load_model
2026-04-19 11:02:21.411 | (EngineCore pid=207)     self.model_runner.load_model(load_dummy_weights=load_dummy_weights)
2026-04-19 11:02:21.411 | (EngineCore pid=207)   File "/usr/local/lib/python3.12/dist-packages/vllm/tracing/otel.py", line 178, in sync_wrapper
2026-04-19 11:02:21.411 | (EngineCore pid=207)     return func(*args, **kwargs)
2026-04-19 11:02:21.411 | (EngineCore pid=207)            ^^^^^^^^^^^^^^^^^^^^^
2026-04-19 11:02:21.411 | (EngineCore pid=207)   File "/usr/local/lib/python3.12/dist-packages/vllm/v1/worker/gpu_model_runner.py", line 4768, in load_model
2026-04-19 11:02:21.411 | (EngineCore pid=207)     self.model = model_loader.load_model(
2026-04-19 11:02:21.411 | (EngineCore pid=207)                  ^^^^^^^^^^^^^^^^^^^^^^^^
2026-04-19 11:02:21.411 | (EngineCore pid=207)   File "/usr/local/lib/python3.12/dist-packages/vllm/tracing/otel.py", line 178, in sync_wrapper
2026-04-19 11:02:21.411 | (EngineCore pid=207)     return func(*args, **kwargs)
2026-04-19 11:02:21.411 | (EngineCore pid=207)            ^^^^^^^^^^^^^^^^^^^^^
2026-04-19 11:02:21.411 | (EngineCore pid=207)   File "/usr/local/lib/python3.12/dist-packages/vllm/model_executor/model_loader/base_loader.py", line 55, in load_model
2026-04-19 11:02:21.411 | (EngineCore pid=207)     model = initialize_model(
2026-04-19 11:02:21.411 | (EngineCore pid=207)             ^^^^^^^^^^^^^^^^^
2026-04-19 11:02:21.411 | (EngineCore pid=207)   File "/usr/local/lib/python3.12/dist-packages/vllm/tracing/otel.py", line 178, in sync_wrapper
2026-04-19 11:02:21.411 | (EngineCore pid=207)     return func(*args, **kwargs)
2026-04-19 11:02:21.411 | (EngineCore pid=207)            ^^^^^^^^^^^^^^^^^^^^^
2026-04-19 11:02:21.411 | (EngineCore pid=207)   File "/usr/local/lib/python3.12/dist-packages/vllm/model_executor/model_loader/utils.py", line 57, in initialize_model
2026-04-19 11:02:21.411 | (EngineCore pid=207)     model = model_class(vllm_config=vllm_config, prefix=prefix)
2026-04-19 11:02:21.411 | (EngineCore pid=207)             ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
2026-04-19 11:02:21.411 | (EngineCore pid=207)   File "/usr/local/lib/python3.12/dist-packages/vllm/model_executor/models/qwen3_5.py", line 831, in __init__
2026-04-19 11:02:21.411 | (EngineCore pid=207)     self.language_model = Qwen3_5MoeForCausalLM(
2026-04-19 11:02:21.411 | (EngineCore pid=207)                           ^^^^^^^^^^^^^^^^^^^^^^
2026-04-19 11:02:21.411 | (EngineCore pid=207)   File "/usr/local/lib/python3.12/dist-packages/vllm/model_executor/models/qwen3_5.py", line 555, in __init__
2026-04-19 11:02:21.411 | (EngineCore pid=207)     super().__init__(vllm_config=vllm_config, prefix=prefix)
2026-04-19 11:02:21.411 | (EngineCore pid=207)   File "/usr/local/lib/python3.12/dist-packages/vllm/model_executor/models/qwen3_5.py", line 481, in __init__
2026-04-19 11:02:21.411 | (EngineCore pid=207)     self.model = Qwen3_5Model(
2026-04-19 11:02:21.411 | (EngineCore pid=207)                  ^^^^^^^^^^^^^
2026-04-19 11:02:21.411 | (EngineCore pid=207)   File "/usr/local/lib/python3.12/dist-packages/vllm/compilation/decorators.py", line 379, in __init__
2026-04-19 11:02:21.411 | (EngineCore pid=207)     old_init(self, *args, **kwargs)
2026-04-19 11:02:21.411 | (EngineCore pid=207)   File "/usr/local/lib/python3.12/dist-packages/vllm/model_executor/models/qwen3_5.py", line 236, in __init__
2026-04-19 11:02:21.411 | (EngineCore pid=207)     self.start_layer, self.end_layer, self.layers = make_layers(
2026-04-19 11:02:21.411 | (EngineCore pid=207)                                                     ^^^^^^^^^^^^
2026-04-19 11:02:21.411 | (EngineCore pid=207)   File "/usr/local/lib/python3.12/dist-packages/vllm/model_executor/models/utils.py", line 646, in make_layers
2026-04-19 11:02:21.411 | (EngineCore pid=207)     + get_offloader().wrap_modules(
2026-04-19 11:02:21.411 | (EngineCore pid=207)       ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
2026-04-19 11:02:21.411 | (EngineCore pid=207)   File "/usr/local/lib/python3.12/dist-packages/vllm/model_executor/offloader/base.py", line 104, in wrap_modules
2026-04-19 11:02:21.411 | (EngineCore pid=207)     return list(modules_generator)
2026-04-19 11:02:21.411 | (EngineCore pid=207)            ^^^^^^^^^^^^^^^^^^^^^^^
2026-04-19 11:02:21.411 | (EngineCore pid=207)   File "/usr/local/lib/python3.12/dist-packages/vllm/model_executor/models/utils.py", line 647, in <genexpr>
2026-04-19 11:02:21.411 | (EngineCore pid=207)     layer_fn(prefix=f"{prefix}.{idx}") for idx in range(start_layer, end_layer)
2026-04-19 11:02:21.411 | (EngineCore pid=207)     ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
2026-04-19 11:02:21.411 | (EngineCore pid=207)   File "/usr/local/lib/python3.12/dist-packages/vllm/model_executor/models/qwen3_5.py", line 230, in get_layer
2026-04-19 11:02:21.411 | (EngineCore pid=207)     return Qwen3_5DecoderLayer(
2026-04-19 11:02:21.411 | (EngineCore pid=207)            ^^^^^^^^^^^^^^^^^^^^
2026-04-19 11:02:21.411 | (EngineCore pid=207)   File "/usr/local/lib/python3.12/dist-packages/vllm/model_executor/models/qwen3_5.py", line 157, in __init__
2026-04-19 11:02:21.411 | (EngineCore pid=207)     self.mlp = Qwen3NextSparseMoeBlock(
2026-04-19 11:02:21.411 | (EngineCore pid=207)                ^^^^^^^^^^^^^^^^^^^^^^^^
2026-04-19 11:02:21.411 | (EngineCore pid=207)   File "/usr/local/lib/python3.12/dist-packages/vllm/model_executor/models/qwen3_next.py", line 149, in __init__
2026-04-19 11:02:21.411 | (EngineCore pid=207)     self.experts = SharedFusedMoE(
2026-04-19 11:02:21.411 | (EngineCore pid=207)                    ^^^^^^^^^^^^^^^
2026-04-19 11:02:21.411 | (EngineCore pid=207)   File "/usr/local/lib/python3.12/dist-packages/vllm/model_executor/layers/fused_moe/layer.py", line 520, in __init__
2026-04-19 11:02:21.411 | (EngineCore pid=207)     self.quant_method: FusedMoEMethodBase = _get_quant_method()
2026-04-19 11:02:21.411 | (EngineCore pid=207)                                             ^^^^^^^^^^^^^^^^^^^
2026-04-19 11:02:21.411 | (EngineCore pid=207)   File "/usr/local/lib/python3.12/dist-packages/vllm/model_executor/layers/fused_moe/layer.py", line 512, in _get_quant_method
2026-04-19 11:02:21.411 | (EngineCore pid=207)     quant_method = self.quant_config.get_quant_method(self, prefix)
2026-04-19 11:02:21.411 | (EngineCore pid=207)                    ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
2026-04-19 11:02:21.411 | (EngineCore pid=207)   File "/usr/local/lib/python3.12/dist-packages/vllm/model_executor/layers/quantization/compressed_tensors/compressed_tensors.py", line 196, in get_quant_method
2026-04-19 11:02:21.411 | (EngineCore pid=207)     return CompressedTensorsMoEMethod.get_moe_method(
2026-04-19 11:02:21.411 | (EngineCore pid=207)            ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
2026-04-19 11:02:21.411 | (EngineCore pid=207)   File "/usr/local/lib/python3.12/dist-packages/vllm/model_executor/layers/quantization/compressed_tensors/compressed_tensors_moe/compressed_tensors_moe.py", line 139, in get_moe_method
2026-04-19 11:02:21.411 | (EngineCore pid=207)     return CompressedTensorsW4A4Nvfp4MoEMethod(
2026-04-19 11:02:21.411 | (EngineCore pid=207)            ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
2026-04-19 11:02:21.411 | (EngineCore pid=207)   File "/usr/local/lib/python3.12/dist-packages/vllm/model_executor/layers/quantization/compressed_tensors/compressed_tensors_moe/compressed_tensors_moe_w4a4_nvfp4.py", line 47, in __init__
2026-04-19 11:02:21.411 | (EngineCore pid=207)     self.nvfp4_backend, self.experts_cls = select_nvfp4_moe_backend(
2026-04-19 11:02:21.411 | (EngineCore pid=207)                                            ^^^^^^^^^^^^^^^^^^^^^^^^^
2026-04-19 11:02:21.411 | (EngineCore pid=207)   File "/usr/local/lib/python3.12/dist-packages/vllm/model_executor/layers/fused_moe/oracle/nvfp4.py", line 211, in select_nvfp4_moe_backend
2026-04-19 11:02:21.411 | (EngineCore pid=207)     requested_backend = map_nvfp4_backend(runner_backend)
2026-04-19 11:02:21.411 | (EngineCore pid=207)                         ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
2026-04-19 11:02:21.411 | (EngineCore pid=207)   File "/usr/local/lib/python3.12/dist-packages/vllm/model_executor/layers/fused_moe/oracle/nvfp4.py", line 136, in map_nvfp4_backend
2026-04-19 11:02:21.412 | (EngineCore pid=207)     raise ValueError(
2026-04-19 11:02:21.412 | (EngineCore pid=207) ValueError: moe_backend='triton' is not supported for NvFP4 MoE. Expected one of ['cutlass', 'flashinfer_trtllm', 'flashinfer_cutlass', 'flashinfer_cutedsl', 'marlin'].
2026-04-19 11:02:22.064 | [rank0]:[W419 09:02:22.704826814 ProcessGroupNCCL.cpp:1575] Warning: WARNING: destroy_process_group() was not called before program exit, which can leak resources. For more info, please see https://pytorch.org/docs/stable/distributed.html#shutdown (function operator())
2026-04-19 11:02:22.856 | (APIServer pid=1) Traceback (most recent call last):
2026-04-19 11:02:22.856 | (APIServer pid=1)   File "/usr/local/bin/vllm", line 10, in <module>
2026-04-19 11:02:22.856 | (APIServer pid=1)     sys.exit(main())
2026-04-19 11:02:22.856 | (APIServer pid=1)              ^^^^^^
2026-04-19 11:02:22.856 | (APIServer pid=1)   File "/usr/local/lib/python3.12/dist-packages/vllm/entrypoints/cli/main.py", line 75, in main
2026-04-19 11:02:22.856 | (APIServer pid=1)     args.dispatch_function(args)
2026-04-19 11:02:22.856 | (APIServer pid=1)   File "/usr/local/lib/python3.12/dist-packages/vllm/entrypoints/cli/serve.py", line 122, in cmd
2026-04-19 11:02:22.856 | (APIServer pid=1)     uvloop.run(run_server(args))
2026-04-19 11:02:22.856 | (APIServer pid=1)   File "/usr/local/lib/python3.12/dist-packages/uvloop/__init__.py", line 96, in run
2026-04-19 11:02:22.857 | (APIServer pid=1)     return __asyncio.run(
2026-04-19 11:02:22.857 | (APIServer pid=1)            ^^^^^^^^^^^^^^
2026-04-19 11:02:22.857 | (APIServer pid=1)   File "/usr/lib/python3.12/asyncio/runners.py", line 195, in run
2026-04-19 11:02:22.857 | (APIServer pid=1)     return runner.run(main)
2026-04-19 11:02:22.857 | (APIServer pid=1)            ^^^^^^^^^^^^^^^^
2026-04-19 11:02:22.857 | (APIServer pid=1)   File "/usr/lib/python3.12/asyncio/runners.py", line 118, in run
2026-04-19 11:02:22.857 | (APIServer pid=1)     return self._loop.run_until_complete(task)
2026-04-19 11:02:22.857 | (APIServer pid=1)            ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
2026-04-19 11:02:22.857 | (APIServer pid=1)   File "uvloop/loop.pyx", line 1518, in uvloop.loop.Loop.run_until_complete
2026-04-19 11:02:22.857 | (APIServer pid=1)   File "/usr/local/lib/python3.12/dist-packages/uvloop/__init__.py", line 48, in wrapper
2026-04-19 11:02:22.857 | (APIServer pid=1)     return await main
2026-04-19 11:02:22.857 | (APIServer pid=1)            ^^^^^^^^^^
2026-04-19 11:02:22.857 | (APIServer pid=1)   File "/usr/local/lib/python3.12/dist-packages/vllm/entrypoints/openai/api_server.py", line 678, in run_server
2026-04-19 11:02:22.857 | (APIServer pid=1)     await run_server_worker(listen_address, sock, args, **uvicorn_kwargs)
2026-04-19 11:02:22.857 | (APIServer pid=1)   File "/usr/local/lib/python3.12/dist-packages/vllm/entrypoints/openai/api_server.py", line 692, in run_server_worker
2026-04-19 11:02:22.857 | (APIServer pid=1)     async with build_async_engine_client(
2026-04-19 11:02:22.857 | (APIServer pid=1)                ^^^^^^^^^^^^^^^^^^^^^^^^^^
2026-04-19 11:02:22.857 | (APIServer pid=1)   File "/usr/lib/python3.12/contextlib.py", line 210, in __aenter__
2026-04-19 11:02:22.857 | (APIServer pid=1)     return await anext(self.gen)
2026-04-19 11:02:22.857 | (APIServer pid=1)            ^^^^^^^^^^^^^^^^^^^^^
2026-04-19 11:02:22.857 | (APIServer pid=1)   File "/usr/local/lib/python3.12/dist-packages/vllm/entrypoints/openai/api_server.py", line 100, in build_async_engine_client
2026-04-19 11:02:22.857 | (APIServer pid=1)     async with build_async_engine_client_from_engine_args(
2026-04-19 11:02:22.857 | (APIServer pid=1)                ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
2026-04-19 11:02:22.857 | (APIServer pid=1)   File "/usr/lib/python3.12/contextlib.py", line 210, in __aenter__
2026-04-19 11:02:22.857 | (APIServer pid=1)     return await anext(self.gen)
2026-04-19 11:02:22.858 | (APIServer pid=1)            ^^^^^^^^^^^^^^^^^^^^^
2026-04-19 11:02:22.858 | (APIServer pid=1)   File "/usr/local/lib/python3.12/dist-packages/vllm/entrypoints/openai/api_server.py", line 136, in build_async_engine_client_from_engine_args
2026-04-19 11:02:22.858 | (APIServer pid=1)     async_llm = AsyncLLM.from_vllm_config(
2026-04-19 11:02:22.858 | (APIServer pid=1)                 ^^^^^^^^^^^^^^^^^^^^^^^^^^
2026-04-19 11:02:22.858 | (APIServer pid=1)   File "/usr/local/lib/python3.12/dist-packages/vllm/v1/engine/async_llm.py", line 219, in from_vllm_config
2026-04-19 11:02:22.858 | (APIServer pid=1)     return cls(
2026-04-19 11:02:22.858 | (APIServer pid=1)            ^^^^
2026-04-19 11:02:22.858 | (APIServer pid=1)   File "/usr/local/lib/python3.12/dist-packages/vllm/v1/engine/async_llm.py", line 148, in __init__
2026-04-19 11:02:22.858 | (APIServer pid=1)     self.engine_core = EngineCoreClient.make_async_mp_client(
2026-04-19 11:02:22.858 | (APIServer pid=1)                        ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
2026-04-19 11:02:22.858 | (APIServer pid=1)   File "/usr/local/lib/python3.12/dist-packages/vllm/tracing/otel.py", line 178, in sync_wrapper
2026-04-19 11:02:22.858 | (APIServer pid=1)     return func(*args, **kwargs)
2026-04-19 11:02:22.858 | (APIServer pid=1)            ^^^^^^^^^^^^^^^^^^^^^
2026-04-19 11:02:22.858 | (APIServer pid=1)   File "/usr/local/lib/python3.12/dist-packages/vllm/v1/engine/core_client.py", line 130, in make_async_mp_client
2026-04-19 11:02:22.858 | (APIServer pid=1)     return AsyncMPClient(*client_args)
2026-04-19 11:02:22.858 | (APIServer pid=1)            ^^^^^^^^^^^^^^^^^^^^^^^^^^^
2026-04-19 11:02:22.858 | (APIServer pid=1)   File "/usr/local/lib/python3.12/dist-packages/vllm/tracing/otel.py", line 178, in sync_wrapper
2026-04-19 11:02:22.858 | (APIServer pid=1)     return func(*args, **kwargs)
2026-04-19 11:02:22.858 | (APIServer pid=1)            ^^^^^^^^^^^^^^^^^^^^^
2026-04-19 11:02:22.858 | (APIServer pid=1)   File "/usr/local/lib/python3.12/dist-packages/vllm/v1/engine/core_client.py", line 900, in __init__
2026-04-19 11:02:22.858 | (APIServer pid=1)     super().__init__(
2026-04-19 11:02:22.858 | (APIServer pid=1)   File "/usr/local/lib/python3.12/dist-packages/vllm/v1/engine/core_client.py", line 535, in __init__
2026-04-19 11:02:22.858 | (APIServer pid=1)     with launch_core_engines(
2026-04-19 11:02:22.858 | (APIServer pid=1)          ^^^^^^^^^^^^^^^^^^^^
2026-04-19 11:02:22.858 | (APIServer pid=1)   File "/usr/lib/python3.12/contextlib.py", line 144, in __exit__
2026-04-19 11:02:22.858 | (APIServer pid=1)     next(self.gen)
2026-04-19 11:02:22.858 | (APIServer pid=1)   File "/usr/local/lib/python3.12/dist-packages/vllm/v1/engine/utils.py", line 1094, in launch_core_engines
2026-04-19 11:02:22.859 | (APIServer pid=1)     wait_for_engine_startup(
2026-04-19 11:02:22.859 | (APIServer pid=1)   File "/usr/local/lib/python3.12/dist-packages/vllm/v1/engine/utils.py", line 1153, in wait_for_engine_startup
2026-04-19 11:02:22.859 | (APIServer pid=1)     raise RuntimeError(
2026-04-19 11:02:22.859 | (APIServer pid=1) RuntimeError: Engine core initialization failed. See root cause above. Failed core proc(s): {}
2026-04-19 11:02:31.127 | WARNING 04-19 09:02:31 [interface.py:686] Using 'pin_memory=False' as WSL is detected. This may slow down the performance.
2026-04-19 11:02:31.182 | (APIServer pid=1) INFO 04-19 09:02:31 [utils.py:299] 
2026-04-19 11:02:31.182 | (APIServer pid=1) INFO 04-19 09:02:31 [utils.py:299]        █     █     █▄   ▄█
2026-04-19 11:02:31.182 | (APIServer pid=1) INFO 04-19 09:02:31 [utils.py:299]  ▄▄ ▄█ █     █     █ ▀▄▀ █  version 0.19.2rc1.dev8+g4b7f5ea1a
2026-04-19 11:02:31.182 | (APIServer pid=1) INFO 04-19 09:02:31 [utils.py:299]   █▄█▀ █     █     █     █  model   RedHatAI/Qwen3.6-35B-A3B-NVFP4
2026-04-19 11:02:31.182 | (APIServer pid=1) INFO 04-19 09:02:31 [utils.py:299]    ▀▀  ▀▀▀▀▀ ▀▀▀▀▀ ▀     ▀
2026-04-19 11:02:31.182 | (APIServer pid=1) INFO 04-19 09:02:31 [utils.py:299] 
2026-04-19 11:02:31.186 | (APIServer pid=1) INFO 04-19 09:02:31 [utils.py:233] non-default args: {'model_tag': 'RedHatAI/Qwen3.6-35B-A3B-NVFP4', 'tool_call_parser': 'qwen3_coder', 'host': '0.0.0.0', 'model': 'RedHatAI/Qwen3.6-35B-A3B-NVFP4', 'trust_remote_code': True, 'max_model_len': 131072, 'quantization': 'compressed-tensors', 'served_model_name': ['RedHatAI/Qwen3.6-35B-A3B-NVFP4'], 'reasoning_parser': 'qwen3', 'gpu_memory_utilization': 0.88, 'kv_cache_dtype': 'fp8_e4m3', 'enable_prefix_caching': True, 'max_num_batched_tokens': 32768, 'max_num_seqs': 256, 'enable_chunked_prefill': True, 'moe_backend': 'triton'}
2026-04-19 11:02:31.729 | (APIServer pid=1) Warning: You are sending unauthenticated requests to the HF Hub. Please set a HF_TOKEN to enable higher rate limits and faster downloads.
2026-04-19 11:02:32.226 | (APIServer pid=1) INFO 04-19 09:02:32 [model.py:554] Resolved architecture: Qwen3_5MoeForConditionalGeneration
2026-04-19 11:02:32.226 | (APIServer pid=1) INFO 04-19 09:02:32 [model.py:1685] Using max model len 131072
2026-04-19 11:02:33.252 | (APIServer pid=1) INFO 04-19 09:02:33 [cache.py:247] Using fp8_e4m3 data type to store kv cache. It reduces the GPU memory footprint and boosts the performance. Meanwhile, it may cause accuracy drop without a proper scaling factor
2026-04-19 11:02:33.253 | (APIServer pid=1) INFO 04-19 09:02:33 [scheduler.py:239] Chunked prefill is enabled with max_num_batched_tokens=32768.
2026-04-19 11:02:33.253 | (APIServer pid=1) WARNING 04-19 09:02:33 [config.py:331] Mamba cache mode is set to 'align' for Qwen3_5MoeForConditionalGeneration by default when prefix caching is enabled
2026-04-19 11:02:33.253 | (APIServer pid=1) INFO 04-19 09:02:33 [config.py:351] Warning: Prefix caching in Mamba cache 'align' mode is currently enabled. Its support for Mamba layers is experimental. Please report any issues you may observe.
2026-04-19 11:02:33.254 | (APIServer pid=1) INFO 04-19 09:02:33 [vllm.py:834] Asynchronous scheduling is enabled.
2026-04-19 11:02:33.255 | (APIServer pid=1) INFO 04-19 09:02:33 [kernel.py:199] Final IR op priority after setting platform defaults: IrOpPriorityConfig(rms_norm=['native'])
2026-04-19 11:02:36.133 | (APIServer pid=1) INFO 04-19 09:02:36 [compilation.py:294] Enabled custom fusions: act_quant
2026-04-19 11:02:36.271 | (APIServer pid=1) `Qwen2VLImageProcessorFast` is deprecated. The `Fast` suffix for image processors has been removed; use `Qwen2VLImageProcessor` instead.
2026-04-19 11:02:44.323 | (APIServer pid=1) The `use_fast` parameter is deprecated and will be removed in a future version. Use `backend="torchvision"` instead of `use_fast=True`, or `backend="pil"` instead of `use_fast=False`.
2026-04-19 11:02:44.442 | (APIServer pid=1) Traceback (most recent call last):
2026-04-19 11:02:44.442 | (APIServer pid=1)   File "/usr/local/bin/vllm", line 10, in <module>
2026-04-19 11:02:44.442 | (APIServer pid=1)     sys.exit(main())
2026-04-19 11:02:44.442 | (APIServer pid=1)              ^^^^^^
2026-04-19 11:02:44.443 | (APIServer pid=1)   File "/usr/local/lib/python3.12/dist-packages/vllm/entrypoints/cli/main.py", line 75, in main
2026-04-19 11:02:44.443 | (APIServer pid=1)     args.dispatch_function(args)
2026-04-19 11:02:44.443 | (APIServer pid=1)   File "/usr/local/lib/python3.12/dist-packages/vllm/entrypoints/cli/serve.py", line 122, in cmd
2026-04-19 11:02:44.443 | (APIServer pid=1)     uvloop.run(run_server(args))
2026-04-19 11:02:44.443 | (APIServer pid=1)   File "/usr/local/lib/python3.12/dist-packages/uvloop/__init__.py", line 96, in run
2026-04-19 11:02:44.443 | (APIServer pid=1)     return __asyncio.run(
2026-04-19 11:02:44.443 | (APIServer pid=1)            ^^^^^^^^^^^^^^
2026-04-19 11:02:44.443 | (APIServer pid=1)   File "/usr/lib/python3.12/asyncio/runners.py", line 195, in run
2026-04-19 11:02:44.443 | (APIServer pid=1)     return runner.run(main)
2026-04-19 11:02:44.443 | (APIServer pid=1)            ^^^^^^^^^^^^^^^^
2026-04-19 11:02:44.443 | (APIServer pid=1)   File "/usr/lib/python3.12/asyncio/runners.py", line 118, in run
2026-04-19 11:02:44.443 | (APIServer pid=1)     return self._loop.run_until_complete(task)
2026-04-19 11:02:44.443 | (APIServer pid=1)            ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
2026-04-19 11:02:44.443 | (APIServer pid=1)   File "uvloop/loop.pyx", line 1512, in uvloop.loop.Loop.run_until_complete
2026-04-19 11:02:44.444 | (APIServer pid=1)   File "uvloop/loop.pyx", line 1505, in uvloop.loop.Loop.run_until_complete
2026-04-19 11:02:44.444 | (APIServer pid=1)   File "uvloop/loop.pyx", line 1379, in uvloop.loop.Loop.run_forever
2026-04-19 11:02:44.444 | (APIServer pid=1)   File "uvloop/loop.pyx", line 557, in uvloop.loop.Loop._run
2026-04-19 11:02:44.444 | (APIServer pid=1)   File "uvloop/loop.pyx", line 476, in uvloop.loop.Loop._on_idle
2026-04-19 11:02:44.444 | (APIServer pid=1)   File "uvloop/cbhandles.pyx", line 83, in uvloop.loop.Handle._run
2026-04-19 11:02:44.444 | (APIServer pid=1)   File "uvloop/cbhandles.pyx", line 61, in uvloop.loop.Handle._run
2026-04-19 11:02:44.444 | (APIServer pid=1)   File "/usr/local/lib/python3.12/dist-packages/uvloop/__init__.py", line 48, in wrapper
2026-04-19 11:02:44.445 | (APIServer pid=1)     return await main
2026-04-19 11:02:44.445 | (APIServer pid=1)            ^^^^^^^^^^
2026-04-19 11:02:44.445 | (APIServer pid=1)   File "/usr/local/lib/python3.12/dist-packages/vllm/entrypoints/openai/api_server.py", line 678, in run_server
2026-04-19 11:02:44.445 | (APIServer pid=1)     await run_server_worker(listen_address, sock, args, **uvicorn_kwargs)
2026-04-19 11:02:44.445 | (APIServer pid=1)   File "/usr/local/lib/python3.12/dist-packages/vllm/entrypoints/openai/api_server.py", line 692, in run_server_worker
2026-04-19 11:02:44.445 | (APIServer pid=1)     async with build_async_engine_client(
2026-04-19 11:02:44.445 | (APIServer pid=1)                ^^^^^^^^^^^^^^^^^^^^^^^^^^
2026-04-19 11:02:44.445 | (APIServer pid=1)   File "/usr/lib/python3.12/contextlib.py", line 210, in __aenter__
2026-04-19 11:02:44.445 | (APIServer pid=1)     return await anext(self.gen)
2026-04-19 11:02:44.445 | (APIServer pid=1)            ^^^^^^^^^^^^^^^^^^^^^
2026-04-19 11:02:44.445 | (APIServer pid=1)   File "/usr/local/lib/python3.12/dist-packages/vllm/entrypoints/openai/api_server.py", line 100, in build_async_engine_client
2026-04-19 11:02:44.445 | (APIServer pid=1)     async with build_async_engine_client_from_engine_args(
2026-04-19 11:02:44.445 | (APIServer pid=1)                ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
2026-04-19 11:02:44.445 | (APIServer pid=1)   File "/usr/lib/python3.12/contextlib.py", line 210, in __aenter__
2026-04-19 11:02:44.446 | (APIServer pid=1)     return await anext(self.gen)
2026-04-19 11:02:44.446 | (APIServer pid=1)            ^^^^^^^^^^^^^^^^^^^^^
2026-04-19 11:02:44.446 | (APIServer pid=1)   File "/usr/local/lib/python3.12/dist-packages/vllm/entrypoints/openai/api_server.py", line 136, in build_async_engine_client_from_engine_args
2026-04-19 11:02:44.446 | (APIServer pid=1)     async_llm = AsyncLLM.from_vllm_config(
2026-04-19 11:02:44.446 | (APIServer pid=1)                 ^^^^^^^^^^^^^^^^^^^^^^^^^^
2026-04-19 11:02:44.446 | (APIServer pid=1)   File "/usr/local/lib/python3.12/dist-packages/vllm/v1/engine/async_llm.py", line 219, in from_vllm_config
2026-04-19 11:02:44.446 | (APIServer pid=1)     return cls(
2026-04-19 11:02:44.446 | (APIServer pid=1)            ^^^^
2026-04-19 11:02:44.446 | (APIServer pid=1)   File "/usr/local/lib/python3.12/dist-packages/vllm/v1/engine/async_llm.py", line 137, in __init__
2026-04-19 11:02:44.446 | (APIServer pid=1)     self.input_processor = InputProcessor(self.vllm_config, renderer)
2026-04-19 11:02:44.446 | (APIServer pid=1)                            ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
2026-04-19 11:02:44.446 | (APIServer pid=1)   File "/usr/local/lib/python3.12/dist-packages/vllm/v1/engine/input_processor.py", line 61, in __init__
2026-04-19 11:02:44.446 | (APIServer pid=1)     mm_budget = MultiModalBudget(vllm_config, mm_registry)
2026-04-19 11:02:44.446 | (APIServer pid=1)                 ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
2026-04-19 11:02:44.446 | (APIServer pid=1)   File "/usr/local/lib/python3.12/dist-packages/vllm/multimodal/encoder_budget.py", line 87, in __init__
2026-04-19 11:02:44.446 | (APIServer pid=1)     all_mm_max_toks_per_item = get_mm_max_toks_per_item(
2026-04-19 11:02:44.446 | (APIServer pid=1)                                ^^^^^^^^^^^^^^^^^^^^^^^^^
2026-04-19 11:02:44.446 | (APIServer pid=1)   File "/usr/local/lib/python3.12/dist-packages/vllm/multimodal/encoder_budget.py", line 25, in get_mm_max_toks_per_item
2026-04-19 11:02:44.447 | (APIServer pid=1)     max_tokens_per_item = processor.info.get_mm_max_tokens_per_item(
2026-04-19 11:02:44.447 | (APIServer pid=1)                           ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
2026-04-19 11:02:44.447 | (APIServer pid=1)   File "/usr/local/lib/python3.12/dist-packages/vllm/model_executor/models/qwen2_vl.py", line 825, in get_mm_max_tokens_per_item
2026-04-19 11:02:44.447 | (APIServer pid=1)     max_image_tokens = self.get_max_image_tokens()
2026-04-19 11:02:44.447 | (APIServer pid=1)                        ^^^^^^^^^^^^^^^^^^^^^^^^^^^
2026-04-19 11:02:44.447 | (APIServer pid=1)   File "/usr/local/lib/python3.12/dist-packages/vllm/model_executor/models/qwen2_vl.py", line 968, in get_max_image_tokens
2026-04-19 11:02:44.447 | (APIServer pid=1)     image_processor = self.get_image_processor()
2026-04-19 11:02:44.447 | (APIServer pid=1)                       ^^^^^^^^^^^^^^^^^^^^^^^^^^
2026-04-19 11:02:44.447 | (APIServer pid=1)   File "/usr/local/lib/python3.12/dist-packages/vllm/model_executor/models/qwen3_vl.py", line 866, in get_image_processor
2026-04-19 11:02:44.447 | (APIServer pid=1)     return self.get_hf_processor(**kwargs).image_processor
2026-04-19 11:02:44.447 | (APIServer pid=1)            ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
2026-04-19 11:02:44.447 | (APIServer pid=1)   File "/usr/local/lib/python3.12/dist-packages/vllm/model_executor/models/qwen3_vl.py", line 859, in get_hf_processor
2026-04-19 11:02:44.448 | (APIServer pid=1)     return self.ctx.get_hf_processor(
2026-04-19 11:02:44.448 | (APIServer pid=1)            ^^^^^^^^^^^^^^^^^^^^^^^^^^
2026-04-19 11:02:44.448 | (APIServer pid=1)   File "/usr/local/lib/python3.12/dist-packages/vllm/multimodal/processing/context.py", line 204, in get_hf_processor
2026-04-19 11:02:44.448 | (APIServer pid=1)     return cached_processor_from_config(
2026-04-19 11:02:44.448 | (APIServer pid=1)            ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
2026-04-19 11:02:44.448 | (APIServer pid=1)   File "/usr/local/lib/python3.12/dist-packages/vllm/transformers_utils/processor.py", line 355, in cached_processor_from_config
2026-04-19 11:02:44.448 | (APIServer pid=1)     return cached_get_processor_without_dynamic_kwargs(
2026-04-19 11:02:44.448 | (APIServer pid=1)            ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
2026-04-19 11:02:44.448 | (APIServer pid=1)   File "/usr/local/lib/python3.12/dist-packages/vllm/transformers_utils/processor.py", line 328, in cached_get_processor_without_dynamic_kwargs
2026-04-19 11:02:44.448 | (APIServer pid=1)     final_processor = cached_get_processor(
2026-04-19 11:02:44.448 | (APIServer pid=1)                       ^^^^^^^^^^^^^^^^^^^^^
2026-04-19 11:02:44.448 | (APIServer pid=1)   File "/usr/local/lib/python3.12/dist-packages/vllm/transformers_utils/processor.py", line 198, in get_processor
2026-04-19 11:02:44.448 | (APIServer pid=1)     processor = processor_cls.from_pretrained(
2026-04-19 11:02:44.448 | (APIServer pid=1)                 ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
2026-04-19 11:02:44.448 | (APIServer pid=1)   File "/usr/local/lib/python3.12/dist-packages/transformers/processing_utils.py", line 1421, in from_pretrained
2026-04-19 11:02:44.449 | (APIServer pid=1)     args = cls._get_arguments_from_pretrained(pretrained_model_name_or_path, processor_dict, **kwargs)
2026-04-19 11:02:44.449 | (APIServer pid=1)            ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
2026-04-19 11:02:44.449 | (APIServer pid=1)   File "/usr/local/lib/python3.12/dist-packages/transformers/processing_utils.py", line 1550, in _get_arguments_from_pretrained
2026-04-19 11:02:44.449 | (APIServer pid=1)     sub_processor = auto_processor_class.from_pretrained(
2026-04-19 11:02:44.449 | (APIServer pid=1)                     ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
2026-04-19 11:02:44.449 | (APIServer pid=1)   File "/usr/local/lib/python3.12/dist-packages/transformers/models/auto/image_processing_auto.py", line 744, in from_pretrained
2026-04-19 11:02:44.449 | (APIServer pid=1)     return image_processor_class.from_pretrained(pretrained_model_name_or_path, *inputs, **kwargs)
2026-04-19 11:02:44.449 | (APIServer pid=1)            ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
2026-04-19 11:02:44.449 | (APIServer pid=1)   File "/usr/local/lib/python3.12/dist-packages/transformers/image_processing_base.py", line 179, in from_pretrained
2026-04-19 11:02:44.449 | (APIServer pid=1)     image_processor_dict, kwargs = cls.get_image_processor_dict(pretrained_model_name_or_path, **kwargs)
2026-04-19 11:02:44.449 | (APIServer pid=1)                                    ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
2026-04-19 11:02:44.449 | (APIServer pid=1)   File "/usr/local/lib/python3.12/dist-packages/transformers/image_processing_base.py", line 282, in get_image_processor_dict
2026-04-19 11:02:44.450 | (APIServer pid=1)     resolved_processor_file = cached_file(
2026-04-19 11:02:44.450 | (APIServer pid=1)                               ^^^^^^^^^^^^
2026-04-19 11:02:44.450 | (APIServer pid=1)   File "/usr/local/lib/python3.12/dist-packages/transformers/utils/hub.py", line 278, in cached_file
2026-04-19 11:02:44.450 | (APIServer pid=1)     file = cached_files(path_or_repo_id=path_or_repo_id, filenames=[filename], **kwargs)
2026-04-19 11:02:44.450 | (APIServer pid=1)            ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
2026-04-19 11:02:44.450 | (APIServer pid=1)   File "/usr/local/lib/python3.12/dist-packages/transformers/utils/hub.py", line 422, in cached_files
2026-04-19 11:02:44.450 | (APIServer pid=1)     hf_hub_download(
2026-04-19 11:02:44.450 | (APIServer pid=1)   File "/usr/local/lib/python3.12/dist-packages/huggingface_hub/utils/_validators.py", line 88, in _inner_fn
2026-04-19 11:02:44.450 | (APIServer pid=1)     return fn(*args, **kwargs)
2026-04-19 11:02:44.450 | (APIServer pid=1)            ^^^^^^^^^^^^^^^^^^^
2026-04-19 11:02:44.450 | (APIServer pid=1)   File "/usr/local/lib/python3.12/dist-packages/huggingface_hub/file_download.py", line 997, in hf_hub_download
2026-04-19 11:02:44.451 | (APIServer pid=1)     return _hf_hub_download_to_cache_dir(
2026-04-19 11:02:44.451 | (APIServer pid=1)            ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
2026-04-19 11:02:44.451 | (APIServer pid=1)   File "/usr/local/lib/python3.12/dist-packages/huggingface_hub/file_download.py", line 1072, in _hf_hub_download_to_cache_dir
2026-04-19 11:02:44.451 | (APIServer pid=1)     (url_to_download, etag, commit_hash, expected_size, xet_file_data, head_call_error) = _get_metadata_or_catch_error(
2026-04-19 11:02:44.451 | (APIServer pid=1)                                                                                           ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
2026-04-19 11:02:44.451 | (APIServer pid=1)   File "/usr/local/lib/python3.12/dist-packages/huggingface_hub/file_download.py", line 1669, in _get_metadata_or_catch_error
2026-04-19 11:02:44.451 | (APIServer pid=1)     metadata = get_hf_file_metadata(
2026-04-19 11:02:44.451 | (APIServer pid=1)                ^^^^^^^^^^^^^^^^^^^^^
2026-04-19 11:02:44.451 | (APIServer pid=1)   File "/usr/local/lib/python3.12/dist-packages/huggingface_hub/utils/_validators.py", line 88, in _inner_fn
2026-04-19 11:02:44.451 | (APIServer pid=1)     return fn(*args, **kwargs)
2026-04-19 11:02:44.451 | (APIServer pid=1)            ^^^^^^^^^^^^^^^^^^^
2026-04-19 11:02:44.451 | (APIServer pid=1)   File "/usr/local/lib/python3.12/dist-packages/huggingface_hub/file_download.py", line 1591, in get_hf_file_metadata
2026-04-19 11:02:44.452 | (APIServer pid=1)     response = _httpx_follow_relative_redirects_with_backoff(
2026-04-19 11:02:44.452 | (APIServer pid=1)                ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
2026-04-19 11:02:44.452 | (APIServer pid=1)   File "/usr/local/lib/python3.12/dist-packages/huggingface_hub/utils/_http.py", line 685, in _httpx_follow_relative_redirects_with_backoff
2026-04-19 11:02:44.452 | (APIServer pid=1)     response = http_backoff(
2026-04-19 11:02:44.452 | (APIServer pid=1)                ^^^^^^^^^^^^^
2026-04-19 11:02:44.452 | (APIServer pid=1)   File "/usr/local/lib/python3.12/dist-packages/huggingface_hub/utils/_http.py", line 559, in http_backoff
2026-04-19 11:02:44.452 | (APIServer pid=1)     return next(
2026-04-19 11:02:44.452 | (APIServer pid=1)            ^^^^^
2026-04-19 11:02:44.452 | (APIServer pid=1)   File "/usr/local/lib/python3.12/dist-packages/huggingface_hub/utils/_http.py", line 467, in _http_backoff_base
2026-04-19 11:02:44.452 | (APIServer pid=1)     response = client.request(method=method, url=url, **kwargs)
2026-04-19 11:02:44.452 | (APIServer pid=1)                ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
2026-04-19 11:02:44.452 | (APIServer pid=1)   File "/usr/local/lib/python3.12/dist-packages/httpx/_client.py", line 825, in request
2026-04-19 11:02:44.452 | (APIServer pid=1)     return self.send(request, auth=auth, follow_redirects=follow_redirects)
2026-04-19 11:02:44.452 | (APIServer pid=1)            ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
2026-04-19 11:02:44.452 | (APIServer pid=1)   File "/usr/local/lib/python3.12/dist-packages/httpx/_client.py", line 914, in send
2026-04-19 11:02:44.453 | (APIServer pid=1)     response = self._send_handling_auth(
2026-04-19 11:02:44.453 | (APIServer pid=1)                ^^^^^^^^^^^^^^^^^^^^^^^^^
2026-04-19 11:02:44.453 | (APIServer pid=1)   File "/usr/local/lib/python3.12/dist-packages/httpx/_client.py", line 942, in _send_handling_auth
2026-04-19 11:02:44.453 | (APIServer pid=1)     response = self._send_handling_redirects(
2026-04-19 11:02:44.453 | (APIServer pid=1)                ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
2026-04-19 11:02:44.453 | (APIServer pid=1)   File "/usr/local/lib/python3.12/dist-packages/httpx/_client.py", line 979, in _send_handling_redirects
2026-04-19 11:02:44.453 | (APIServer pid=1)     response = self._send_single_request(request)
2026-04-19 11:02:44.453 | (APIServer pid=1)                ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
2026-04-19 11:02:44.453 | (APIServer pid=1)   File "/usr/local/lib/python3.12/dist-packages/httpx/_client.py", line 1014, in _send_single_request
2026-04-19 11:02:44.453 | (APIServer pid=1)     response = transport.handle_request(request)
2026-04-19 11:02:44.453 | (APIServer pid=1)                ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
2026-04-19 11:02:44.453 | (APIServer pid=1)   File "/usr/local/lib/python3.12/dist-packages/httpx/_transports/default.py", line 250, in handle_request
2026-04-19 11:02:44.453 | (APIServer pid=1)     resp = self._pool.handle_request(req)
2026-04-19 11:02:44.453 | (APIServer pid=1)            ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
2026-04-19 11:02:44.453 | (APIServer pid=1)   File "/usr/local/lib/python3.12/dist-packages/httpcore/_sync/connection_pool.py", line 256, in handle_request
2026-04-19 11:02:44.454 | (APIServer pid=1)     raise exc from None
2026-04-19 11:02:44.454 | (APIServer pid=1)   File "/usr/local/lib/python3.12/dist-packages/httpcore/_sync/connection_pool.py", line 236, in handle_request
2026-04-19 11:02:44.454 | (APIServer pid=1)     response = connection.handle_request(
2026-04-19 11:02:44.454 | (APIServer pid=1)                ^^^^^^^^^^^^^^^^^^^^^^^^^^
2026-04-19 11:02:44.454 | (APIServer pid=1)   File "/usr/local/lib/python3.12/dist-packages/httpcore/_sync/connection.py", line 103, in handle_request
2026-04-19 11:02:44.454 | (APIServer pid=1)     return self._connection.handle_request(request)
2026-04-19 11:02:44.454 | (APIServer pid=1)            ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
2026-04-19 11:02:44.454 | (APIServer pid=1)   File "/usr/local/lib/python3.12/dist-packages/httpcore/_sync/http11.py", line 136, in handle_request
2026-04-19 11:02:44.454 | (APIServer pid=1)     raise exc
2026-04-19 11:02:44.454 | (APIServer pid=1)   File "/usr/local/lib/python3.12/dist-packages/httpcore/_sync/http11.py", line 106, in handle_request
2026-04-19 11:02:44.454 | (APIServer pid=1)     ) = self._receive_response_headers(**kwargs)
2026-04-19 11:02:44.454 | (APIServer pid=1)         ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
2026-04-19 11:02:44.454 | (APIServer pid=1)   File "/usr/local/lib/python3.12/dist-packages/httpcore/_sync/http11.py", line 177, in _receive_response_headers
2026-04-19 11:02:44.454 | (APIServer pid=1)     event = self._receive_event(timeout=timeout)
2026-04-19 11:02:44.454 | (APIServer pid=1)             ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
2026-04-19 11:02:44.454 | (APIServer pid=1)   File "/usr/local/lib/python3.12/dist-packages/httpcore/_sync/http11.py", line 217, in _receive_event
2026-04-19 11:02:44.454 | (APIServer pid=1)     data = self._network_stream.read(
2026-04-19 11:02:44.454 | (APIServer pid=1)            ^^^^^^^^^^^^^^^^^^^^^^^^^^
2026-04-19 11:02:44.454 | (APIServer pid=1)   File "/usr/local/lib/python3.12/dist-packages/httpcore/_backends/sync.py", line 128, in read
2026-04-19 11:02:44.455 | (APIServer pid=1)     return self._sock.recv(max_bytes)
2026-04-19 11:02:44.455 | (APIServer pid=1)            ^^^^^^^^^^^^^^^^^^^^^^^^^^
2026-04-19 11:02:44.455 | (APIServer pid=1)   File "/usr/lib/python3.12/ssl.py", line 1232, in recv
2026-04-19 11:02:44.456 | (APIServer pid=1)     return self.read(buflen)
2026-04-19 11:02:44.456 | (APIServer pid=1)            ^^^^^^^^^^^^^^^^^
2026-04-19 11:02:44.456 | (APIServer pid=1)   File "/usr/lib/python3.12/ssl.py", line 1105, in read
2026-04-19 11:02:44.456 | (APIServer pid=1)     return self._sslobj.read(len)
2026-04-19 11:02:44.456 | (APIServer pid=1)            ^^^^^^^^^^^^^^^^^^^^^^
2026-04-19 11:02:44.456 | (APIServer pid=1)   File "/usr/local/lib/python3.12/dist-packages/vllm/entrypoints/openai/api_server.py", line 564, in signal_handler
2026-04-19 11:02:44.456 | (APIServer pid=1)     raise KeyboardInterrupt("terminated")
2026-04-19 11:02:44.456 | (APIServer pid=1) KeyboardInterrupt: terminated