# docker compose log

```yaml
# Gemma-4-26B NVFP4 - TurboQuant Experimental Configuration (~200K Context)
# Uses TurboQuant KV cache compression (FP8 keys + 4-bit values).
# Monitor output quality on long contexts as this is experimental.

services:
  gemma-4-26b-it-nvfp4-turbo:
    image: vllm/vllm-openai:nightly
    container_name: gemma-4-26b-it-nvfp4-turbo
    hostname: gemma-4-26b-it-nvfp4-turbo
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
      - VLLM_ATTENTION_BACKEND=FLASHINFER
    command:
      - "RedHatAI/gemma-4-26B-A4B-it-NVFP4"
      - "--served-model-name"
      - "gemma-4-26b-it-nvfp4"
      - "--host"
      - "0.0.0.0"
      - "--port"
      - "8000"
      - "--gpu-memory-utilization"
      - "0.85"
      - "--max-model-len"
      - "196608" # ~200K Context enabled by TurboQuant
      - "--max-num-batched-tokens"
      - "8192"
      - "--kv-cache-dtype"
      - "turboquant_k8v4" # FP8 keys + 4-bit values
      - "--quantization"
      - "compressed-tensors"
      - "--enable-prefix-caching"
      - "--enable-chunked-prefill"
      - "--max-num-seqs"
      - "2"
      - "--reasoning-parser"
      - "gemma4"
      - "--tool-call-parser"
      - "gemma4"
      - "--moe-backend"
      - "cutlass"
      - "--trust-remote-code"
    networks:
      - development-network

networks:
  development-network:
    external: true

```

# key messages
2026-04-19 14:28:52.238 | (APIServer pid=1) WARNING 04-19 12:28:52 [arg_utils.py:1982] TurboQuant is not yet compatible with FlashAttention >= 3. Overriding flash_attn_version to 2. To silence this warning, pass --attention-config.flash_attn_version=2



2026-04-19 14:29:10.606 | (EngineCore pid=196) ERROR 04-19 12:29:10 [core.py:1132]     raise ValueError(
2026-04-19 14:29:10.606 | (EngineCore pid=196) ERROR 04-19 12:29:10 [core.py:1132] ValueError: Selected backend AttentionBackendEnum.TRITON_ATTN is not valid for this configuration. Reason: ['kv_cache_dtype not supported']

# vllm crash log 
2026-04-19 14:28:41.423 | WARNING 04-19 12:28:41 [interface.py:686] Using 'pin_memory=False' as WSL is detected. This may slow down the performance.
2026-04-19 14:28:41.530 | (APIServer pid=1) INFO 04-19 12:28:41 [utils.py:299] 
2026-04-19 14:28:41.530 | (APIServer pid=1) INFO 04-19 12:28:41 [utils.py:299]        █     █     █▄   ▄█
2026-04-19 14:28:41.530 | (APIServer pid=1) INFO 04-19 12:28:41 [utils.py:299]  ▄▄ ▄█ █     █     █ ▀▄▀ █  version 0.19.2rc1.dev8+g4b7f5ea1a
2026-04-19 14:28:41.530 | (APIServer pid=1) INFO 04-19 12:28:41 [utils.py:299]   █▄█▀ █     █     █     █  model   RedHatAI/gemma-4-26B-A4B-it-NVFP4
2026-04-19 14:28:41.530 | (APIServer pid=1) INFO 04-19 12:28:41 [utils.py:299]    ▀▀  ▀▀▀▀▀ ▀▀▀▀▀ ▀     ▀
2026-04-19 14:28:41.530 | (APIServer pid=1) INFO 04-19 12:28:41 [utils.py:299] 
2026-04-19 14:28:41.532 | (APIServer pid=1) INFO 04-19 12:28:41 [utils.py:233] non-default args: {'model_tag': 'RedHatAI/gemma-4-26B-A4B-it-NVFP4', 'tool_call_parser': 'gemma4', 'host': '0.0.0.0', 'model': 'RedHatAI/gemma-4-26B-A4B-it-NVFP4', 'trust_remote_code': True, 'max_model_len': 196608, 'quantization': 'compressed-tensors', 'served_model_name': ['gemma-4-26b-it-nvfp4'], 'reasoning_parser': 'gemma4', 'gpu_memory_utilization': 0.85, 'kv_cache_dtype': 'turboquant_k8v4', 'enable_prefix_caching': True, 'max_num_batched_tokens': 8192, 'max_num_seqs': 2, 'enable_chunked_prefill': True, 'moe_backend': 'cutlass'}
2026-04-19 14:28:41.534 | (APIServer pid=1) WARNING 04-19 12:28:41 [envs.py:1785] Unknown vLLM environment variable detected: VLLM_ATTENTION_BACKEND
2026-04-19 14:28:42.098 | (APIServer pid=1) Warning: You are sending unauthenticated requests to the HF Hub. Please set a HF_TOKEN to enable higher rate limits and faster downloads.
2026-04-19 14:28:51.927 | (APIServer pid=1) INFO 04-19 12:28:51 [model.py:554] Resolved architecture: Gemma4ForConditionalGeneration
2026-04-19 14:28:51.927 | (APIServer pid=1) INFO 04-19 12:28:51 [model.py:1685] Using max model len 196608
2026-04-19 14:28:52.238 | (APIServer pid=1) INFO 04-19 12:28:52 [arg_utils.py:1664] TQ: skipping layers ['0', '1', '28', '29'] for boundary protection (num_layers=30)
2026-04-19 14:28:52.238 | (APIServer pid=1) INFO 04-19 12:28:52 [scheduler.py:239] Chunked prefill is enabled with max_num_batched_tokens=8192.
2026-04-19 14:28:52.238 | (APIServer pid=1) WARNING 04-19 12:28:52 [arg_utils.py:1982] TurboQuant is not yet compatible with FlashAttention >= 3. Overriding flash_attn_version to 2. To silence this warning, pass --attention-config.flash_attn_version=2
2026-04-19 14:28:52.239 | (APIServer pid=1) INFO 04-19 12:28:52 [config.py:101] Gemma4 model has heterogeneous head dimensions (head_dim=256, global_head_dim=512). Forcing TRITON_ATTN backend to prevent mixed-backend numerical divergence.
2026-04-19 14:28:52.239 | (APIServer pid=1) INFO 04-19 12:28:52 [vllm.py:834] Asynchronous scheduling is enabled.
2026-04-19 14:28:52.239 | (APIServer pid=1) INFO 04-19 12:28:52 [kernel.py:199] Final IR op priority after setting platform defaults: IrOpPriorityConfig(rms_norm=['native'])
2026-04-19 14:28:55.524 | (APIServer pid=1) INFO 04-19 12:28:55 [compilation.py:294] Enabled custom fusions: act_quant
2026-04-19 14:29:04.862 | (EngineCore pid=196) INFO 04-19 12:29:04 [core.py:107] Initializing a V1 LLM engine (v0.19.2rc1.dev8+g4b7f5ea1a) with config: model='RedHatAI/gemma-4-26B-A4B-it-NVFP4', speculative_config=None, tokenizer='RedHatAI/gemma-4-26B-A4B-it-NVFP4', skip_tokenizer_init=False, tokenizer_mode=auto, revision=None, tokenizer_revision=None, trust_remote_code=True, dtype=torch.bfloat16, max_seq_len=196608, download_dir=None, load_format=auto, tensor_parallel_size=1, pipeline_parallel_size=1, data_parallel_size=1, decode_context_parallel_size=1, dcp_comm_backend=ag_rs, disable_custom_all_reduce=False, quantization=compressed-tensors, quantization_config=None, enforce_eager=False, enable_return_routed_experts=False, kv_cache_dtype=turboquant_k8v4, device_config=cuda, structured_outputs_config=StructuredOutputsConfig(backend='auto', disable_any_whitespace=False, disable_additional_properties=False, reasoning_parser='gemma4', reasoning_parser_plugin='', enable_in_reasoning=False), observability_config=ObservabilityConfig(show_hidden_metrics_for_version=None, otlp_traces_endpoint=None, collect_detailed_traces=None, kv_cache_metrics=False, kv_cache_metrics_sample=0.01, cudagraph_metrics=False, enable_layerwise_nvtx_tracing=False, enable_mfu_metrics=False, enable_mm_processor_stats=False, enable_logging_iteration_details=False), seed=0, served_model_name=gemma-4-26b-it-nvfp4, enable_prefix_caching=True, enable_chunked_prefill=True, pooler_config=None, compilation_config={'mode': <CompilationMode.VLLM_COMPILE: 3>, 'debug_dump_path': None, 'cache_dir': '', 'compile_cache_save_format': 'binary', 'backend': 'inductor', 'custom_ops': ['none'], 'ir_enable_torch_wrap': True, 'splitting_ops': ['vllm::unified_attention_with_output', 'vllm::unified_mla_attention_with_output', 'vllm::mamba_mixer2', 'vllm::mamba_mixer', 'vllm::short_conv', 'vllm::linear_attention', 'vllm::plamo2_mamba_mixer', 'vllm::gdn_attention_core', 'vllm::olmo_hybrid_gdn_full_forward', 'vllm::kda_attention', 'vllm::sparse_attn_indexer', 'vllm::rocm_aiter_sparse_attn_indexer', 'vllm::unified_kv_cache_update', 'vllm::unified_mla_kv_cache_update'], 'compile_mm_encoder': False, 'cudagraph_mm_encoder': False, 'encoder_cudagraph_token_budgets': [], 'encoder_cudagraph_max_vision_items_per_batch': 0, 'encoder_cudagraph_max_frames_per_batch': 0, 'compile_sizes': [], 'compile_ranges_endpoints': [8192], 'inductor_compile_config': {'enable_auto_functionalized_v2': False, 'size_asserts': False, 'alignment_asserts': False, 'scalar_asserts': False, 'combo_kernels': True, 'benchmark_combo_kernel': True}, 'inductor_passes': {}, 'cudagraph_mode': <CUDAGraphMode.FULL_AND_PIECEWISE: (2, 1)>, 'cudagraph_num_of_warmups': 1, 'cudagraph_capture_sizes': [1, 2, 4], 'cudagraph_copy_inputs': False, 'cudagraph_specialize_lora': True, 'use_inductor_graph_partition': False, 'pass_config': {'fuse_norm_quant': False, 'fuse_act_quant': True, 'fuse_attn_quant': False, 'enable_sp': False, 'fuse_gemm_comms': False, 'fuse_allreduce_rms': False}, 'max_cudagraph_capture_size': 4, 'dynamic_shapes_config': {'type': <DynamicShapesType.BACKED: 'backed'>, 'evaluate_guards': False, 'assume_32_bit_indexing': False}, 'local_cache_dir': None, 'fast_moe_cold_start': False, 'static_all_moe_layers': []}, kernel_config=KernelConfig(ir_op_priority=IrOpPriorityConfig(rms_norm=['native']), enable_flashinfer_autotune=True, moe_backend='cutlass')
2026-04-19 14:29:05.072 | (EngineCore pid=196) WARNING 04-19 12:29:05 [interface.py:686] Using 'pin_memory=False' as WSL is detected. This may slow down the performance.
2026-04-19 14:29:05.383 | (EngineCore pid=196) Warning: You are sending unauthenticated requests to the HF Hub. Please set a HF_TOKEN to enable higher rate limits and faster downloads.
2026-04-19 14:29:08.722 | (EngineCore pid=196) INFO 04-19 12:29:08 [parallel_state.py:1400] world_size=1 rank=0 local_rank=0 distributed_init_method=tcp://172.18.0.2:52587 backend=nccl
2026-04-19 14:29:09.027 | (EngineCore pid=196) INFO 04-19 12:29:09 [parallel_state.py:1713] rank 0 in world size 1 is assigned as DP rank 0, PP rank 0, PCP rank 0, TP rank 0, EP rank 0, EPLB rank N/A
2026-04-19 14:29:09.636 | (EngineCore pid=196) INFO 04-19 12:29:09 [gpu_model_runner.py:4752] Starting to load model RedHatAI/gemma-4-26B-A4B-it-NVFP4...
2026-04-19 14:29:10.111 | (EngineCore pid=196) INFO 04-19 12:29:10 [vllm.py:834] Asynchronous scheduling is enabled.
2026-04-19 14:29:10.112 | (EngineCore pid=196) INFO 04-19 12:29:10 [kernel.py:199] Final IR op priority after setting platform defaults: IrOpPriorityConfig(rms_norm=['native'])
2026-04-19 14:29:10.112 | (EngineCore pid=196) INFO 04-19 12:29:10 [compilation.py:294] Enabled custom fusions: act_quant
2026-04-19 14:29:10.121 | (EngineCore pid=196) INFO 04-19 12:29:10 [__init__.py:683] Using FlashInferCutlassNvFp4LinearKernel for NVFP4 GEMM
2026-04-19 14:29:10.153 | (EngineCore pid=196) INFO 04-19 12:29:10 [attention.py:262] Layer language_model.model.layers.0.self_attn.attn: kv_cache_dtype=auto, sliding_window=1024
2026-04-19 14:29:10.154 | (EngineCore pid=196) INFO 04-19 12:29:10 [cuda.py:308] Using AttentionBackendEnum.TRITON_ATTN backend.
2026-04-19 14:29:10.176 | (EngineCore pid=196) INFO 04-19 12:29:10 [nvfp4.py:203] Using 'VLLM_CUTLASS' NvFp4 MoE backend out of potential backends: ['FLASHINFER_TRTLLM', 'FLASHINFER_CUTEDSL', 'FLASHINFER_CUTEDSL_BATCHED', 'FLASHINFER_CUTLASS', 'VLLM_CUTLASS', 'MARLIN'].
2026-04-19 14:29:10.178 | (EngineCore pid=196) INFO 04-19 12:29:10 [attention.py:262] Layer language_model.model.layers.1.self_attn.attn: kv_cache_dtype=auto, sliding_window=1024
2026-04-19 14:29:10.187 | (EngineCore pid=196) INFO 04-19 12:29:10 [attention.py:262] Layer language_model.model.layers.2.self_attn.attn: kv_cache_dtype=turboquant_k8v4, sliding_window=1024
2026-04-19 14:29:10.606 | (EngineCore pid=196) Process EngineCore:
2026-04-19 14:29:10.606 | (EngineCore pid=196) ERROR 04-19 12:29:10 [core.py:1132] EngineCore failed to start.
2026-04-19 14:29:10.606 | (EngineCore pid=196) ERROR 04-19 12:29:10 [core.py:1132] Traceback (most recent call last):
2026-04-19 14:29:10.606 | (EngineCore pid=196) ERROR 04-19 12:29:10 [core.py:1132]   File "/usr/local/lib/python3.12/dist-packages/vllm/v1/engine/core.py", line 1106, in run_engine_core
2026-04-19 14:29:10.606 | (EngineCore pid=196) ERROR 04-19 12:29:10 [core.py:1132]     engine_core = EngineCoreProc(*args, engine_index=dp_rank, **kwargs)
2026-04-19 14:29:10.606 | (EngineCore pid=196) ERROR 04-19 12:29:10 [core.py:1132]                   ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
2026-04-19 14:29:10.606 | (EngineCore pid=196) ERROR 04-19 12:29:10 [core.py:1132]   File "/usr/local/lib/python3.12/dist-packages/vllm/tracing/otel.py", line 178, in sync_wrapper
2026-04-19 14:29:10.606 | (EngineCore pid=196) ERROR 04-19 12:29:10 [core.py:1132]     return func(*args, **kwargs)
2026-04-19 14:29:10.606 | (EngineCore pid=196) ERROR 04-19 12:29:10 [core.py:1132]            ^^^^^^^^^^^^^^^^^^^^^
2026-04-19 14:29:10.606 | (EngineCore pid=196) ERROR 04-19 12:29:10 [core.py:1132]   File "/usr/local/lib/python3.12/dist-packages/vllm/v1/engine/core.py", line 872, in __init__
2026-04-19 14:29:10.606 | (EngineCore pid=196) ERROR 04-19 12:29:10 [core.py:1132]     super().__init__(
2026-04-19 14:29:10.606 | (EngineCore pid=196) ERROR 04-19 12:29:10 [core.py:1132]   File "/usr/local/lib/python3.12/dist-packages/vllm/v1/engine/core.py", line 116, in __init__
2026-04-19 14:29:10.606 | (EngineCore pid=196) ERROR 04-19 12:29:10 [core.py:1132]     self.model_executor = executor_class(vllm_config)
2026-04-19 14:29:10.606 | (EngineCore pid=196) ERROR 04-19 12:29:10 [core.py:1132]                           ^^^^^^^^^^^^^^^^^^^^^^^^^^^
2026-04-19 14:29:10.606 | (EngineCore pid=196) ERROR 04-19 12:29:10 [core.py:1132]   File "/usr/local/lib/python3.12/dist-packages/vllm/tracing/otel.py", line 178, in sync_wrapper
2026-04-19 14:29:10.606 | (EngineCore pid=196) ERROR 04-19 12:29:10 [core.py:1132]     return func(*args, **kwargs)
2026-04-19 14:29:10.606 | (EngineCore pid=196) ERROR 04-19 12:29:10 [core.py:1132]            ^^^^^^^^^^^^^^^^^^^^^
2026-04-19 14:29:10.606 | (EngineCore pid=196) ERROR 04-19 12:29:10 [core.py:1132]   File "/usr/local/lib/python3.12/dist-packages/vllm/v1/executor/abstract.py", line 109, in __init__
2026-04-19 14:29:10.606 | (EngineCore pid=196) ERROR 04-19 12:29:10 [core.py:1132]     self._init_executor()
2026-04-19 14:29:10.606 | (EngineCore pid=196) ERROR 04-19 12:29:10 [core.py:1132]   File "/usr/local/lib/python3.12/dist-packages/vllm/v1/executor/uniproc_executor.py", line 52, in _init_executor
2026-04-19 14:29:10.606 | (EngineCore pid=196) ERROR 04-19 12:29:10 [core.py:1132]     self.driver_worker.load_model()
2026-04-19 14:29:10.606 | (EngineCore pid=196) ERROR 04-19 12:29:10 [core.py:1132]   File "/usr/local/lib/python3.12/dist-packages/vllm/v1/worker/gpu_worker.py", line 323, in load_model
2026-04-19 14:29:10.606 | (EngineCore pid=196) ERROR 04-19 12:29:10 [core.py:1132]     self.model_runner.load_model(load_dummy_weights=load_dummy_weights)
2026-04-19 14:29:10.606 | (EngineCore pid=196) ERROR 04-19 12:29:10 [core.py:1132]   File "/usr/local/lib/python3.12/dist-packages/vllm/tracing/otel.py", line 178, in sync_wrapper
2026-04-19 14:29:10.606 | (EngineCore pid=196) ERROR 04-19 12:29:10 [core.py:1132]     return func(*args, **kwargs)
2026-04-19 14:29:10.606 | (EngineCore pid=196) ERROR 04-19 12:29:10 [core.py:1132]            ^^^^^^^^^^^^^^^^^^^^^
2026-04-19 14:29:10.606 | (EngineCore pid=196) ERROR 04-19 12:29:10 [core.py:1132]   File "/usr/local/lib/python3.12/dist-packages/vllm/v1/worker/gpu_model_runner.py", line 4768, in load_model
2026-04-19 14:29:10.606 | (EngineCore pid=196) ERROR 04-19 12:29:10 [core.py:1132]     self.model = model_loader.load_model(
2026-04-19 14:29:10.606 | (EngineCore pid=196) ERROR 04-19 12:29:10 [core.py:1132]                  ^^^^^^^^^^^^^^^^^^^^^^^^
2026-04-19 14:29:10.606 | (EngineCore pid=196) ERROR 04-19 12:29:10 [core.py:1132]   File "/usr/local/lib/python3.12/dist-packages/vllm/tracing/otel.py", line 178, in sync_wrapper
2026-04-19 14:29:10.606 | (EngineCore pid=196) ERROR 04-19 12:29:10 [core.py:1132]     return func(*args, **kwargs)
2026-04-19 14:29:10.606 | (EngineCore pid=196) ERROR 04-19 12:29:10 [core.py:1132]            ^^^^^^^^^^^^^^^^^^^^^
2026-04-19 14:29:10.606 | (EngineCore pid=196) ERROR 04-19 12:29:10 [core.py:1132]   File "/usr/local/lib/python3.12/dist-packages/vllm/model_executor/model_loader/base_loader.py", line 55, in load_model
2026-04-19 14:29:10.606 | (EngineCore pid=196) ERROR 04-19 12:29:10 [core.py:1132]     model = initialize_model(
2026-04-19 14:29:10.606 | (EngineCore pid=196) ERROR 04-19 12:29:10 [core.py:1132]             ^^^^^^^^^^^^^^^^^
2026-04-19 14:29:10.606 | (EngineCore pid=196) ERROR 04-19 12:29:10 [core.py:1132]   File "/usr/local/lib/python3.12/dist-packages/vllm/tracing/otel.py", line 178, in sync_wrapper
2026-04-19 14:29:10.606 | (EngineCore pid=196) ERROR 04-19 12:29:10 [core.py:1132]     return func(*args, **kwargs)
2026-04-19 14:29:10.606 | (EngineCore pid=196) ERROR 04-19 12:29:10 [core.py:1132]            ^^^^^^^^^^^^^^^^^^^^^
2026-04-19 14:29:10.606 | (EngineCore pid=196) ERROR 04-19 12:29:10 [core.py:1132]   File "/usr/local/lib/python3.12/dist-packages/vllm/model_executor/model_loader/utils.py", line 57, in initialize_model
2026-04-19 14:29:10.606 | (EngineCore pid=196) ERROR 04-19 12:29:10 [core.py:1132]     model = model_class(vllm_config=vllm_config, prefix=prefix)
2026-04-19 14:29:10.606 | (EngineCore pid=196) ERROR 04-19 12:29:10 [core.py:1132]             ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
2026-04-19 14:29:10.606 | (EngineCore pid=196) ERROR 04-19 12:29:10 [core.py:1132]   File "/usr/local/lib/python3.12/dist-packages/vllm/model_executor/models/gemma4_mm.py", line 946, in __init__
2026-04-19 14:29:10.606 | (EngineCore pid=196) ERROR 04-19 12:29:10 [core.py:1132]     self.language_model: Gemma4ForCausalLM = init_vllm_registered_model(
2026-04-19 14:29:10.606 | (EngineCore pid=196) ERROR 04-19 12:29:10 [core.py:1132]                                              ^^^^^^^^^^^^^^^^^^^^^^^^^^^
2026-04-19 14:29:10.606 | (EngineCore pid=196) ERROR 04-19 12:29:10 [core.py:1132]   File "/usr/local/lib/python3.12/dist-packages/vllm/model_executor/models/utils.py", line 379, in init_vllm_registered_model
2026-04-19 14:29:10.606 | (EngineCore pid=196) ERROR 04-19 12:29:10 [core.py:1132]     return initialize_model(vllm_config=vllm_config, prefix=prefix)
2026-04-19 14:29:10.606 | (EngineCore pid=196) ERROR 04-19 12:29:10 [core.py:1132]            ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
2026-04-19 14:29:10.606 | (EngineCore pid=196) ERROR 04-19 12:29:10 [core.py:1132]   File "/usr/local/lib/python3.12/dist-packages/vllm/tracing/otel.py", line 178, in sync_wrapper
2026-04-19 14:29:10.606 | (EngineCore pid=196) ERROR 04-19 12:29:10 [core.py:1132]     return func(*args, **kwargs)
2026-04-19 14:29:10.606 | (EngineCore pid=196) ERROR 04-19 12:29:10 [core.py:1132]            ^^^^^^^^^^^^^^^^^^^^^
2026-04-19 14:29:10.606 | (EngineCore pid=196) ERROR 04-19 12:29:10 [core.py:1132]   File "/usr/local/lib/python3.12/dist-packages/vllm/model_executor/model_loader/utils.py", line 57, in initialize_model
2026-04-19 14:29:10.606 | (EngineCore pid=196) ERROR 04-19 12:29:10 [core.py:1132]     model = model_class(vllm_config=vllm_config, prefix=prefix)
2026-04-19 14:29:10.606 | (EngineCore pid=196) ERROR 04-19 12:29:10 [core.py:1132]             ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
2026-04-19 14:29:10.606 | (EngineCore pid=196) ERROR 04-19 12:29:10 [core.py:1132]   File "/usr/local/lib/python3.12/dist-packages/vllm/model_executor/models/gemma4.py", line 1439, in __init__
2026-04-19 14:29:10.606 | (EngineCore pid=196) ERROR 04-19 12:29:10 [core.py:1132]     self.model = Gemma4Model(
2026-04-19 14:29:10.606 | (EngineCore pid=196) ERROR 04-19 12:29:10 [core.py:1132]                  ^^^^^^^^^^^^
2026-04-19 14:29:10.606 | (EngineCore pid=196) ERROR 04-19 12:29:10 [core.py:1132]   File "/usr/local/lib/python3.12/dist-packages/vllm/compilation/decorators.py", line 379, in __init__
2026-04-19 14:29:10.606 | (EngineCore pid=196) ERROR 04-19 12:29:10 [core.py:1132]     old_init(self, *args, **kwargs)
2026-04-19 14:29:10.606 | (EngineCore pid=196) ERROR 04-19 12:29:10 [core.py:1132]   File "/usr/local/lib/python3.12/dist-packages/vllm/model_executor/models/gemma4.py", line 931, in __init__
2026-04-19 14:29:10.606 | (EngineCore pid=196) ERROR 04-19 12:29:10 [core.py:1132]     self.start_layer, self.end_layer, self.layers = make_layers(
2026-04-19 14:29:10.606 | (EngineCore pid=196) ERROR 04-19 12:29:10 [core.py:1132]                                                     ^^^^^^^^^^^^
2026-04-19 14:29:10.606 | (EngineCore pid=196) ERROR 04-19 12:29:10 [core.py:1132]   File "/usr/local/lib/python3.12/dist-packages/vllm/model_executor/models/utils.py", line 646, in make_layers
2026-04-19 14:29:10.606 | (EngineCore pid=196) ERROR 04-19 12:29:10 [core.py:1132]     + get_offloader().wrap_modules(
2026-04-19 14:29:10.606 | (EngineCore pid=196) ERROR 04-19 12:29:10 [core.py:1132]       ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
2026-04-19 14:29:10.606 | (EngineCore pid=196) ERROR 04-19 12:29:10 [core.py:1132]   File "/usr/local/lib/python3.12/dist-packages/vllm/model_executor/offloader/base.py", line 104, in wrap_modules
2026-04-19 14:29:10.606 | (EngineCore pid=196) ERROR 04-19 12:29:10 [core.py:1132]     return list(modules_generator)
2026-04-19 14:29:10.606 | (EngineCore pid=196) ERROR 04-19 12:29:10 [core.py:1132]            ^^^^^^^^^^^^^^^^^^^^^^^
2026-04-19 14:29:10.606 | (EngineCore pid=196) ERROR 04-19 12:29:10 [core.py:1132]   File "/usr/local/lib/python3.12/dist-packages/vllm/model_executor/models/utils.py", line 647, in <genexpr>
2026-04-19 14:29:10.606 | (EngineCore pid=196) ERROR 04-19 12:29:10 [core.py:1132]     layer_fn(prefix=f"{prefix}.{idx}") for idx in range(start_layer, end_layer)
2026-04-19 14:29:10.606 | (EngineCore pid=196) ERROR 04-19 12:29:10 [core.py:1132]     ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
2026-04-19 14:29:10.606 | (EngineCore pid=196) ERROR 04-19 12:29:10 [core.py:1132]   File "/usr/local/lib/python3.12/dist-packages/vllm/model_executor/models/gemma4.py", line 933, in <lambda>
2026-04-19 14:29:10.606 | (EngineCore pid=196) ERROR 04-19 12:29:10 [core.py:1132]     lambda prefix: Gemma4DecoderLayer(
2026-04-19 14:29:10.606 | (EngineCore pid=196) ERROR 04-19 12:29:10 [core.py:1132]                    ^^^^^^^^^^^^^^^^^^^
2026-04-19 14:29:10.606 | (EngineCore pid=196) ERROR 04-19 12:29:10 [core.py:1132]   File "/usr/local/lib/python3.12/dist-packages/vllm/model_executor/models/gemma4.py", line 472, in __init__
2026-04-19 14:29:10.606 | (EngineCore pid=196) ERROR 04-19 12:29:10 [core.py:1132]     self.self_attn = Gemma4Attention(
2026-04-19 14:29:10.606 | (EngineCore pid=196) ERROR 04-19 12:29:10 [core.py:1132]                      ^^^^^^^^^^^^^^^^
2026-04-19 14:29:10.606 | (EngineCore pid=196) ERROR 04-19 12:29:10 [core.py:1132]   File "/usr/local/lib/python3.12/dist-packages/vllm/model_executor/models/gemma4.py", line 382, in __init__
2026-04-19 14:29:10.606 | (EngineCore pid=196) ERROR 04-19 12:29:10 [core.py:1132]     self.attn = Attention(
2026-04-19 14:29:10.606 | (EngineCore pid=196) ERROR 04-19 12:29:10 [core.py:1132]                 ^^^^^^^^^^
2026-04-19 14:29:10.606 | (EngineCore pid=196) ERROR 04-19 12:29:10 [core.py:1132]   File "/usr/local/lib/python3.12/dist-packages/vllm/model_executor/layers/attention/attention.py", line 297, in __init__
2026-04-19 14:29:10.606 | (EngineCore pid=196) ERROR 04-19 12:29:10 [core.py:1132]     self.attn_backend = get_attn_backend(
2026-04-19 14:29:10.606 | (EngineCore pid=196) ERROR 04-19 12:29:10 [core.py:1132]                         ^^^^^^^^^^^^^^^^^
2026-04-19 14:29:10.606 | (EngineCore pid=196) ERROR 04-19 12:29:10 [core.py:1132]   File "/usr/local/lib/python3.12/dist-packages/vllm/v1/attention/selector.py", line 100, in get_attn_backend
2026-04-19 14:29:10.606 | (EngineCore pid=196) ERROR 04-19 12:29:10 [core.py:1132]     return _cached_get_attn_backend(
2026-04-19 14:29:10.606 | (EngineCore pid=196) ERROR 04-19 12:29:10 [core.py:1132]            ^^^^^^^^^^^^^^^^^^^^^^^^^
2026-04-19 14:29:10.606 | (EngineCore pid=196) ERROR 04-19 12:29:10 [core.py:1132]   File "/usr/local/lib/python3.12/dist-packages/vllm/v1/attention/selector.py", line 115, in _cached_get_attn_backend
2026-04-19 14:29:10.606 | (EngineCore pid=196) ERROR 04-19 12:29:10 [core.py:1132]     attention_cls = current_platform.get_attn_backend_cls(
2026-04-19 14:29:10.606 | (EngineCore pid=196) ERROR 04-19 12:29:10 [core.py:1132]                     ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
2026-04-19 14:29:10.606 | (EngineCore pid=196) ERROR 04-19 12:29:10 [core.py:1132]   File "/usr/local/lib/python3.12/dist-packages/vllm/platforms/cuda.py", line 303, in get_attn_backend_cls
2026-04-19 14:29:10.606 | (EngineCore pid=196) ERROR 04-19 12:29:10 [core.py:1132]     raise ValueError(
2026-04-19 14:29:10.606 | (EngineCore pid=196) ERROR 04-19 12:29:10 [core.py:1132] ValueError: Selected backend AttentionBackendEnum.TRITON_ATTN is not valid for this configuration. Reason: ['kv_cache_dtype not supported']
2026-04-19 14:29:10.607 | (EngineCore pid=196) Traceback (most recent call last):
2026-04-19 14:29:10.607 | (EngineCore pid=196)   File "/usr/lib/python3.12/multiprocessing/process.py", line 314, in _bootstrap
2026-04-19 14:29:10.607 | (EngineCore pid=196)     self.run()
2026-04-19 14:29:10.607 | (EngineCore pid=196)   File "/usr/lib/python3.12/multiprocessing/process.py", line 108, in run
2026-04-19 14:29:10.607 | (EngineCore pid=196)     self._target(*self._args, **self._kwargs)
2026-04-19 14:29:10.607 | (EngineCore pid=196)   File "/usr/local/lib/python3.12/dist-packages/vllm/v1/engine/core.py", line 1136, in run_engine_core
2026-04-19 14:29:10.607 | (EngineCore pid=196)     raise e
2026-04-19 14:29:10.607 | (EngineCore pid=196)   File "/usr/local/lib/python3.12/dist-packages/vllm/v1/engine/core.py", line 1106, in run_engine_core
2026-04-19 14:29:10.607 | (EngineCore pid=196)     engine_core = EngineCoreProc(*args, engine_index=dp_rank, **kwargs)
2026-04-19 14:29:10.607 | (EngineCore pid=196)                   ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
2026-04-19 14:29:10.607 | (EngineCore pid=196)   File "/usr/local/lib/python3.12/dist-packages/vllm/tracing/otel.py", line 178, in sync_wrapper
2026-04-19 14:29:10.607 | (EngineCore pid=196)     return func(*args, **kwargs)
2026-04-19 14:29:10.607 | (EngineCore pid=196)            ^^^^^^^^^^^^^^^^^^^^^
2026-04-19 14:29:10.607 | (EngineCore pid=196)   File "/usr/local/lib/python3.12/dist-packages/vllm/v1/engine/core.py", line 872, in __init__
2026-04-19 14:29:10.607 | (EngineCore pid=196)     super().__init__(
2026-04-19 14:29:10.607 | (EngineCore pid=196)   File "/usr/local/lib/python3.12/dist-packages/vllm/v1/engine/core.py", line 116, in __init__
2026-04-19 14:29:10.607 | (EngineCore pid=196)     self.model_executor = executor_class(vllm_config)
2026-04-19 14:29:10.607 | (EngineCore pid=196)                           ^^^^^^^^^^^^^^^^^^^^^^^^^^^
2026-04-19 14:29:10.607 | (EngineCore pid=196)   File "/usr/local/lib/python3.12/dist-packages/vllm/tracing/otel.py", line 178, in sync_wrapper
2026-04-19 14:29:10.607 | (EngineCore pid=196)     return func(*args, **kwargs)
2026-04-19 14:29:10.607 | (EngineCore pid=196)            ^^^^^^^^^^^^^^^^^^^^^
2026-04-19 14:29:10.607 | (EngineCore pid=196)   File "/usr/local/lib/python3.12/dist-packages/vllm/v1/executor/abstract.py", line 109, in __init__
2026-04-19 14:29:10.607 | (EngineCore pid=196)     self._init_executor()
2026-04-19 14:29:10.607 | (EngineCore pid=196)   File "/usr/local/lib/python3.12/dist-packages/vllm/v1/executor/uniproc_executor.py", line 52, in _init_executor
2026-04-19 14:29:10.607 | (EngineCore pid=196)     self.driver_worker.load_model()
2026-04-19 14:29:10.607 | (EngineCore pid=196)   File "/usr/local/lib/python3.12/dist-packages/vllm/v1/worker/gpu_worker.py", line 323, in load_model
2026-04-19 14:29:10.607 | (EngineCore pid=196)     self.model_runner.load_model(load_dummy_weights=load_dummy_weights)
2026-04-19 14:29:10.607 | (EngineCore pid=196)   File "/usr/local/lib/python3.12/dist-packages/vllm/tracing/otel.py", line 178, in sync_wrapper
2026-04-19 14:29:10.607 | (EngineCore pid=196)     return func(*args, **kwargs)
2026-04-19 14:29:10.607 | (EngineCore pid=196)            ^^^^^^^^^^^^^^^^^^^^^
2026-04-19 14:29:10.607 | (EngineCore pid=196)   File "/usr/local/lib/python3.12/dist-packages/vllm/v1/worker/gpu_model_runner.py", line 4768, in load_model
2026-04-19 14:29:10.607 | (EngineCore pid=196)     self.model = model_loader.load_model(
2026-04-19 14:29:10.607 | (EngineCore pid=196)                  ^^^^^^^^^^^^^^^^^^^^^^^^
2026-04-19 14:29:10.607 | (EngineCore pid=196)   File "/usr/local/lib/python3.12/dist-packages/vllm/tracing/otel.py", line 178, in sync_wrapper
2026-04-19 14:29:10.607 | (EngineCore pid=196)     return func(*args, **kwargs)
2026-04-19 14:29:10.607 | (EngineCore pid=196)            ^^^^^^^^^^^^^^^^^^^^^
2026-04-19 14:29:10.607 | (EngineCore pid=196)   File "/usr/local/lib/python3.12/dist-packages/vllm/model_executor/model_loader/base_loader.py", line 55, in load_model
2026-04-19 14:29:10.607 | (EngineCore pid=196)     model = initialize_model(
2026-04-19 14:29:10.607 | (EngineCore pid=196)             ^^^^^^^^^^^^^^^^^
2026-04-19 14:29:10.607 | (EngineCore pid=196)   File "/usr/local/lib/python3.12/dist-packages/vllm/tracing/otel.py", line 178, in sync_wrapper
2026-04-19 14:29:10.607 | (EngineCore pid=196)     return func(*args, **kwargs)
2026-04-19 14:29:10.607 | (EngineCore pid=196)            ^^^^^^^^^^^^^^^^^^^^^
2026-04-19 14:29:10.607 | (EngineCore pid=196)   File "/usr/local/lib/python3.12/dist-packages/vllm/model_executor/model_loader/utils.py", line 57, in initialize_model
2026-04-19 14:29:10.607 | (EngineCore pid=196)     model = model_class(vllm_config=vllm_config, prefix=prefix)
2026-04-19 14:29:10.607 | (EngineCore pid=196)             ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
2026-04-19 14:29:10.607 | (EngineCore pid=196)   File "/usr/local/lib/python3.12/dist-packages/vllm/model_executor/models/gemma4_mm.py", line 946, in __init__
2026-04-19 14:29:10.607 | (EngineCore pid=196)     self.language_model: Gemma4ForCausalLM = init_vllm_registered_model(
2026-04-19 14:29:10.607 | (EngineCore pid=196)                                              ^^^^^^^^^^^^^^^^^^^^^^^^^^^
2026-04-19 14:29:10.607 | (EngineCore pid=196)   File "/usr/local/lib/python3.12/dist-packages/vllm/model_executor/models/utils.py", line 379, in init_vllm_registered_model
2026-04-19 14:29:10.607 | (EngineCore pid=196)     return initialize_model(vllm_config=vllm_config, prefix=prefix)
2026-04-19 14:29:10.607 | (EngineCore pid=196)            ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
2026-04-19 14:29:10.607 | (EngineCore pid=196)   File "/usr/local/lib/python3.12/dist-packages/vllm/tracing/otel.py", line 178, in sync_wrapper
2026-04-19 14:29:10.607 | (EngineCore pid=196)     return func(*args, **kwargs)
2026-04-19 14:29:10.607 | (EngineCore pid=196)            ^^^^^^^^^^^^^^^^^^^^^
2026-04-19 14:29:10.607 | (EngineCore pid=196)   File "/usr/local/lib/python3.12/dist-packages/vllm/model_executor/model_loader/utils.py", line 57, in initialize_model
2026-04-19 14:29:10.607 | (EngineCore pid=196)     model = model_class(vllm_config=vllm_config, prefix=prefix)
2026-04-19 14:29:10.607 | (EngineCore pid=196)             ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
2026-04-19 14:29:10.607 | (EngineCore pid=196)   File "/usr/local/lib/python3.12/dist-packages/vllm/model_executor/models/gemma4.py", line 1439, in __init__
2026-04-19 14:29:10.607 | (EngineCore pid=196)     self.model = Gemma4Model(
2026-04-19 14:29:10.607 | (EngineCore pid=196)                  ^^^^^^^^^^^^
2026-04-19 14:29:10.607 | (EngineCore pid=196)   File "/usr/local/lib/python3.12/dist-packages/vllm/compilation/decorators.py", line 379, in __init__
2026-04-19 14:29:10.607 | (EngineCore pid=196)     old_init(self, *args, **kwargs)
2026-04-19 14:29:10.607 | (EngineCore pid=196)   File "/usr/local/lib/python3.12/dist-packages/vllm/model_executor/models/gemma4.py", line 931, in __init__
2026-04-19 14:29:10.607 | (EngineCore pid=196)     self.start_layer, self.end_layer, self.layers = make_layers(
2026-04-19 14:29:10.607 | (EngineCore pid=196)                                                     ^^^^^^^^^^^^
2026-04-19 14:29:10.607 | (EngineCore pid=196)   File "/usr/local/lib/python3.12/dist-packages/vllm/model_executor/models/utils.py", line 646, in make_layers
2026-04-19 14:29:10.607 | (EngineCore pid=196)     + get_offloader().wrap_modules(
2026-04-19 14:29:10.607 | (EngineCore pid=196)       ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
2026-04-19 14:29:10.607 | (EngineCore pid=196)   File "/usr/local/lib/python3.12/dist-packages/vllm/model_executor/offloader/base.py", line 104, in wrap_modules
2026-04-19 14:29:10.607 | (EngineCore pid=196)     return list(modules_generator)
2026-04-19 14:29:10.607 | (EngineCore pid=196)            ^^^^^^^^^^^^^^^^^^^^^^^
2026-04-19 14:29:10.607 | (EngineCore pid=196)   File "/usr/local/lib/python3.12/dist-packages/vllm/model_executor/models/utils.py", line 647, in <genexpr>
2026-04-19 14:29:10.607 | (EngineCore pid=196)     layer_fn(prefix=f"{prefix}.{idx}") for idx in range(start_layer, end_layer)
2026-04-19 14:29:10.607 | (EngineCore pid=196)     ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
2026-04-19 14:29:10.607 | (EngineCore pid=196)   File "/usr/local/lib/python3.12/dist-packages/vllm/model_executor/models/gemma4.py", line 933, in <lambda>
2026-04-19 14:29:10.607 | (EngineCore pid=196)     lambda prefix: Gemma4DecoderLayer(
2026-04-19 14:29:10.607 | (EngineCore pid=196)                    ^^^^^^^^^^^^^^^^^^^
2026-04-19 14:29:10.607 | (EngineCore pid=196)   File "/usr/local/lib/python3.12/dist-packages/vllm/model_executor/models/gemma4.py", line 472, in __init__
2026-04-19 14:29:10.607 | (EngineCore pid=196)     self.self_attn = Gemma4Attention(
2026-04-19 14:29:10.607 | (EngineCore pid=196)                      ^^^^^^^^^^^^^^^^
2026-04-19 14:29:10.607 | (EngineCore pid=196)   File "/usr/local/lib/python3.12/dist-packages/vllm/model_executor/models/gemma4.py", line 382, in __init__
2026-04-19 14:29:10.607 | (EngineCore pid=196)     self.attn = Attention(
2026-04-19 14:29:10.607 | (EngineCore pid=196)                 ^^^^^^^^^^
2026-04-19 14:29:10.607 | (EngineCore pid=196)   File "/usr/local/lib/python3.12/dist-packages/vllm/model_executor/layers/attention/attention.py", line 297, in __init__
2026-04-19 14:29:10.607 | (EngineCore pid=196)     self.attn_backend = get_attn_backend(
2026-04-19 14:29:10.607 | (EngineCore pid=196)                         ^^^^^^^^^^^^^^^^^
2026-04-19 14:29:10.607 | (EngineCore pid=196)   File "/usr/local/lib/python3.12/dist-packages/vllm/v1/attention/selector.py", line 100, in get_attn_backend
2026-04-19 14:29:10.607 | (EngineCore pid=196)     return _cached_get_attn_backend(
2026-04-19 14:29:10.607 | (EngineCore pid=196)            ^^^^^^^^^^^^^^^^^^^^^^^^^
2026-04-19 14:29:10.607 | (EngineCore pid=196)   File "/usr/local/lib/python3.12/dist-packages/vllm/v1/attention/selector.py", line 115, in _cached_get_attn_backend
2026-04-19 14:29:10.607 | (EngineCore pid=196)     attention_cls = current_platform.get_attn_backend_cls(
2026-04-19 14:29:10.607 | (EngineCore pid=196)                     ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
2026-04-19 14:29:10.607 | (EngineCore pid=196)   File "/usr/local/lib/python3.12/dist-packages/vllm/platforms/cuda.py", line 303, in get_attn_backend_cls
2026-04-19 14:29:10.607 | (EngineCore pid=196)     raise ValueError(
2026-04-19 14:29:10.607 | (EngineCore pid=196) ValueError: Selected backend AttentionBackendEnum.TRITON_ATTN is not valid for this configuration. Reason: ['kv_cache_dtype not supported']
2026-04-19 14:29:11.110 | [rank0]:[W419 12:29:11.668883197 ProcessGroupNCCL.cpp:1575] Warning: WARNING: destroy_process_group() was not called before program exit, which can leak resources. For more info, please see https://pytorch.org/docs/stable/distributed.html#shutdown (function operator())
2026-04-19 14:29:11.880 | (APIServer pid=1) Traceback (most recent call last):
2026-04-19 14:29:11.880 | (APIServer pid=1)   File "/usr/local/bin/vllm", line 10, in <module>
2026-04-19 14:29:11.880 | (APIServer pid=1)     sys.exit(main())
2026-04-19 14:29:11.880 | (APIServer pid=1)              ^^^^^^
2026-04-19 14:29:11.880 | (APIServer pid=1)   File "/usr/local/lib/python3.12/dist-packages/vllm/entrypoints/cli/main.py", line 75, in main
2026-04-19 14:29:11.880 | (APIServer pid=1)     args.dispatch_function(args)
2026-04-19 14:29:11.880 | (APIServer pid=1)   File "/usr/local/lib/python3.12/dist-packages/vllm/entrypoints/cli/serve.py", line 122, in cmd
2026-04-19 14:29:11.880 | (APIServer pid=1)     uvloop.run(run_server(args))
2026-04-19 14:29:11.880 | (APIServer pid=1)   File "/usr/local/lib/python3.12/dist-packages/uvloop/__init__.py", line 96, in run
2026-04-19 14:29:11.880 | (APIServer pid=1)     return __asyncio.run(
2026-04-19 14:29:11.880 | (APIServer pid=1)            ^^^^^^^^^^^^^^
2026-04-19 14:29:11.880 | (APIServer pid=1)   File "/usr/lib/python3.12/asyncio/runners.py", line 195, in run
2026-04-19 14:29:11.883 | (APIServer pid=1)     return runner.run(main)
2026-04-19 14:29:11.883 | (APIServer pid=1)            ^^^^^^^^^^^^^^^^
2026-04-19 14:29:11.883 | (APIServer pid=1)   File "/usr/lib/python3.12/asyncio/runners.py", line 118, in run
2026-04-19 14:29:11.883 | (APIServer pid=1)     return self._loop.run_until_complete(task)
2026-04-19 14:29:11.884 | (APIServer pid=1)            ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
2026-04-19 14:29:11.884 | (APIServer pid=1)   File "uvloop/loop.pyx", line 1518, in uvloop.loop.Loop.run_until_complete
2026-04-19 14:29:11.884 | (APIServer pid=1)   File "/usr/local/lib/python3.12/dist-packages/uvloop/__init__.py", line 48, in wrapper
2026-04-19 14:29:11.884 | (APIServer pid=1)     return await main
2026-04-19 14:29:11.884 | (APIServer pid=1)            ^^^^^^^^^^
2026-04-19 14:29:11.884 | (APIServer pid=1)   File "/usr/local/lib/python3.12/dist-packages/vllm/entrypoints/openai/api_server.py", line 678, in run_server
2026-04-19 14:29:11.884 | (APIServer pid=1)     await run_server_worker(listen_address, sock, args, **uvicorn_kwargs)
2026-04-19 14:29:11.884 | (APIServer pid=1)   File "/usr/local/lib/python3.12/dist-packages/vllm/entrypoints/openai/api_server.py", line 692, in run_server_worker
2026-04-19 14:29:11.884 | (APIServer pid=1)     async with build_async_engine_client(
2026-04-19 14:29:11.884 | (APIServer pid=1)                ^^^^^^^^^^^^^^^^^^^^^^^^^^
2026-04-19 14:29:11.884 | (APIServer pid=1)   File "/usr/lib/python3.12/contextlib.py", line 210, in __aenter__
2026-04-19 14:29:11.884 | (APIServer pid=1)     return await anext(self.gen)
2026-04-19 14:29:11.884 | (APIServer pid=1)            ^^^^^^^^^^^^^^^^^^^^^
2026-04-19 14:29:11.884 | (APIServer pid=1)   File "/usr/local/lib/python3.12/dist-packages/vllm/entrypoints/openai/api_server.py", line 100, in build_async_engine_client
2026-04-19 14:29:11.884 | (APIServer pid=1)     async with build_async_engine_client_from_engine_args(
2026-04-19 14:29:11.884 | (APIServer pid=1)                ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
2026-04-19 14:29:11.884 | (APIServer pid=1)   File "/usr/lib/python3.12/contextlib.py", line 210, in __aenter__
2026-04-19 14:29:11.885 | (APIServer pid=1)     return await anext(self.gen)
2026-04-19 14:29:11.885 | (APIServer pid=1)            ^^^^^^^^^^^^^^^^^^^^^
2026-04-19 14:29:11.885 | (APIServer pid=1)   File "/usr/local/lib/python3.12/dist-packages/vllm/entrypoints/openai/api_server.py", line 136, in build_async_engine_client_from_engine_args
2026-04-19 14:29:11.885 | (APIServer pid=1)     async_llm = AsyncLLM.from_vllm_config(
2026-04-19 14:29:11.885 | (APIServer pid=1)                 ^^^^^^^^^^^^^^^^^^^^^^^^^^
2026-04-19 14:29:11.885 | (APIServer pid=1)   File "/usr/local/lib/python3.12/dist-packages/vllm/v1/engine/async_llm.py", line 219, in from_vllm_config
2026-04-19 14:29:11.885 | (APIServer pid=1)     return cls(
2026-04-19 14:29:11.885 | (APIServer pid=1)            ^^^^
2026-04-19 14:29:11.885 | (APIServer pid=1)   File "/usr/local/lib/python3.12/dist-packages/vllm/v1/engine/async_llm.py", line 148, in __init__
2026-04-19 14:29:11.885 | (APIServer pid=1)     self.engine_core = EngineCoreClient.make_async_mp_client(
2026-04-19 14:29:11.885 | (APIServer pid=1)                        ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
2026-04-19 14:29:11.885 | (APIServer pid=1)   File "/usr/local/lib/python3.12/dist-packages/vllm/tracing/otel.py", line 178, in sync_wrapper
2026-04-19 14:29:11.885 | (APIServer pid=1)     return func(*args, **kwargs)
2026-04-19 14:29:11.885 | (APIServer pid=1)            ^^^^^^^^^^^^^^^^^^^^^
2026-04-19 14:29:11.885 | (APIServer pid=1)   File "/usr/local/lib/python3.12/dist-packages/vllm/v1/engine/core_client.py", line 130, in make_async_mp_client
2026-04-19 14:29:11.885 | (APIServer pid=1)     return AsyncMPClient(*client_args)
2026-04-19 14:29:11.885 | (APIServer pid=1)            ^^^^^^^^^^^^^^^^^^^^^^^^^^^
2026-04-19 14:29:11.885 | (APIServer pid=1)   File "/usr/local/lib/python3.12/dist-packages/vllm/tracing/otel.py", line 178, in sync_wrapper
2026-04-19 14:29:11.885 | (APIServer pid=1)     return func(*args, **kwargs)
2026-04-19 14:29:11.885 | (APIServer pid=1)            ^^^^^^^^^^^^^^^^^^^^^
2026-04-19 14:29:11.885 | (APIServer pid=1)   File "/usr/local/lib/python3.12/dist-packages/vllm/v1/engine/core_client.py", line 900, in __init__
2026-04-19 14:29:11.885 | (APIServer pid=1)     super().__init__(
2026-04-19 14:29:11.885 | (APIServer pid=1)   File "/usr/local/lib/python3.12/dist-packages/vllm/v1/engine/core_client.py", line 535, in __init__
2026-04-19 14:29:11.886 | (APIServer pid=1)     with launch_core_engines(
2026-04-19 14:29:11.886 | (APIServer pid=1)          ^^^^^^^^^^^^^^^^^^^^
2026-04-19 14:29:11.886 | (APIServer pid=1)   File "/usr/lib/python3.12/contextlib.py", line 144, in __exit__
2026-04-19 14:29:11.886 | (APIServer pid=1)     next(self.gen)
2026-04-19 14:29:11.886 | (APIServer pid=1)   File "/usr/local/lib/python3.12/dist-packages/vllm/v1/engine/utils.py", line 1094, in launch_core_engines
2026-04-19 14:29:11.886 | (APIServer pid=1)     wait_for_engine_startup(
2026-04-19 14:29:11.886 | (APIServer pid=1)   File "/usr/local/lib/python3.12/dist-packages/vllm/v1/engine/utils.py", line 1153, in wait_for_engine_startup
2026-04-19 14:29:11.886 | (APIServer pid=1)     raise RuntimeError(
2026-04-19 14:29:11.886 | (APIServer pid=1) RuntimeError: Engine core initialization failed. See root cause above. Failed core proc(s): {}
2026-04-19 14:29:19.992 | WARNING 04-19 12:29:19 [interface.py:686] Using 'pin_memory=False' as WSL is detected. This may slow down the performance.
2026-04-19 14:29:20.044 | (APIServer pid=1) INFO 04-19 12:29:20 [utils.py:299] 
2026-04-19 14:29:20.044 | (APIServer pid=1) INFO 04-19 12:29:20 [utils.py:299]        █     █     █▄   ▄█
2026-04-19 14:29:20.044 | (APIServer pid=1) INFO 04-19 12:29:20 [utils.py:299]  ▄▄ ▄█ █     █     █ ▀▄▀ █  version 0.19.2rc1.dev8+g4b7f5ea1a
2026-04-19 14:29:20.044 | (APIServer pid=1) INFO 04-19 12:29:20 [utils.py:299]   █▄█▀ █     █     █     █  model   RedHatAI/gemma-4-26B-A4B-it-NVFP4
2026-04-19 14:29:20.044 | (APIServer pid=1) INFO 04-19 12:29:20 [utils.py:299]    ▀▀  ▀▀▀▀▀ ▀▀▀▀▀ ▀     ▀
2026-04-19 14:29:20.044 | (APIServer pid=1) INFO 04-19 12:29:20 [utils.py:299] 
2026-04-19 14:29:20.046 | (APIServer pid=1) INFO 04-19 12:29:20 [utils.py:233] non-default args: {'model_tag': 'RedHatAI/gemma-4-26B-A4B-it-NVFP4', 'tool_call_parser': 'gemma4', 'host': '0.0.0.0', 'model': 'RedHatAI/gemma-4-26B-A4B-it-NVFP4', 'trust_remote_code': True, 'max_model_len': 196608, 'quantization': 'compressed-tensors', 'served_model_name': ['gemma-4-26b-it-nvfp4'], 'reasoning_parser': 'gemma4', 'gpu_memory_utilization': 0.85, 'kv_cache_dtype': 'turboquant_k8v4', 'enable_prefix_caching': True, 'max_num_batched_tokens': 8192, 'max_num_seqs': 2, 'enable_chunked_prefill': True, 'moe_backend': 'cutlass'}
2026-04-19 14:29:20.048 | (APIServer pid=1) WARNING 04-19 12:29:20 [envs.py:1785] Unknown vLLM environment variable detected: VLLM_ATTENTION_BACKEND
2026-04-19 14:29:20.448 | (APIServer pid=1) Warning: You are sending unauthenticated requests to the HF Hub. Please set a HF_TOKEN to enable higher rate limits and faster downloads.
2026-04-19 14:29:21.114 | (APIServer pid=1) INFO 04-19 12:29:21 [model.py:554] Resolved architecture: Gemma4ForConditionalGeneration
2026-04-19 14:29:21.114 | (APIServer pid=1) INFO 04-19 12:29:21 [model.py:1685] Using max model len 196608
2026-04-19 14:29:22.163 | (APIServer pid=1) INFO 04-19 12:29:22 [arg_utils.py:1664] TQ: skipping layers ['0', '1', '28', '29'] for boundary protection (num_layers=30)
2026-04-19 14:29:22.165 | (APIServer pid=1) INFO 04-19 12:29:22 [scheduler.py:239] Chunked prefill is enabled with max_num_batched_tokens=8192.
2026-04-19 14:29:22.165 | (APIServer pid=1) WARNING 04-19 12:29:22 [arg_utils.py:1982] TurboQuant is not yet compatible with FlashAttention >= 3. Overriding flash_attn_version to 2. To silence this warning, pass --attention-config.flash_attn_version=2
2026-04-19 14:29:22.165 | (APIServer pid=1) INFO 04-19 12:29:22 [config.py:101] Gemma4 model has heterogeneous head dimensions (head_dim=256, global_head_dim=512). Forcing TRITON_ATTN backend to prevent mixed-backend numerical divergence.
2026-04-19 14:29:22.166 | (APIServer pid=1) INFO 04-19 12:29:22 [vllm.py:834] Asynchronous scheduling is enabled.
2026-04-19 14:29:22.166 | (APIServer pid=1) INFO 04-19 12:29:22 [kernel.py:199] Final IR op priority after setting platform defaults: IrOpPriorityConfig(rms_norm=['native'])
2026-04-19 14:29:25.460 | (APIServer pid=1) INFO 04-19 12:29:25 [compilation.py:294] Enabled custom fusions: act_quant
2026-04-19 14:29:34.688 | (EngineCore pid=131) INFO 04-19 12:29:34 [core.py:107] Initializing a V1 LLM engine (v0.19.2rc1.dev8+g4b7f5ea1a) with config: model='RedHatAI/gemma-4-26B-A4B-it-NVFP4', speculative_config=None, tokenizer='RedHatAI/gemma-4-26B-A4B-it-NVFP4', skip_tokenizer_init=False, tokenizer_mode=auto, revision=None, tokenizer_revision=None, trust_remote_code=True, dtype=torch.bfloat16, max_seq_len=196608, download_dir=None, load_format=auto, tensor_parallel_size=1, pipeline_parallel_size=1, data_parallel_size=1, decode_context_parallel_size=1, dcp_comm_backend=ag_rs, disable_custom_all_reduce=False, quantization=compressed-tensors, quantization_config=None, enforce_eager=False, enable_return_routed_experts=False, kv_cache_dtype=turboquant_k8v4, device_config=cuda, structured_outputs_config=StructuredOutputsConfig(backend='auto', disable_any_whitespace=False, disable_additional_properties=False, reasoning_parser='gemma4', reasoning_parser_plugin='', enable_in_reasoning=False), observability_config=ObservabilityConfig(show_hidden_metrics_for_version=None, otlp_traces_endpoint=None, collect_detailed_traces=None, kv_cache_metrics=False, kv_cache_metrics_sample=0.01, cudagraph_metrics=False, enable_layerwise_nvtx_tracing=False, enable_mfu_metrics=False, enable_mm_processor_stats=False, enable_logging_iteration_details=False), seed=0, served_model_name=gemma-4-26b-it-nvfp4, enable_prefix_caching=True, enable_chunked_prefill=True, pooler_config=None, compilation_config={'mode': <CompilationMode.VLLM_COMPILE: 3>, 'debug_dump_path': None, 'cache_dir': '', 'compile_cache_save_format': 'binary', 'backend': 'inductor', 'custom_ops': ['none'], 'ir_enable_torch_wrap': True, 'splitting_ops': ['vllm::unified_attention_with_output', 'vllm::unified_mla_attention_with_output', 'vllm::mamba_mixer2', 'vllm::mamba_mixer', 'vllm::short_conv', 'vllm::linear_attention', 'vllm::plamo2_mamba_mixer', 'vllm::gdn_attention_core', 'vllm::olmo_hybrid_gdn_full_forward', 'vllm::kda_attention', 'vllm::sparse_attn_indexer', 'vllm::rocm_aiter_sparse_attn_indexer', 'vllm::unified_kv_cache_update', 'vllm::unified_mla_kv_cache_update'], 'compile_mm_encoder': False, 'cudagraph_mm_encoder': False, 'encoder_cudagraph_token_budgets': [], 'encoder_cudagraph_max_vision_items_per_batch': 0, 'encoder_cudagraph_max_frames_per_batch': 0, 'compile_sizes': [], 'compile_ranges_endpoints': [8192], 'inductor_compile_config': {'enable_auto_functionalized_v2': False, 'size_asserts': False, 'alignment_asserts': False, 'scalar_asserts': False, 'combo_kernels': True, 'benchmark_combo_kernel': True}, 'inductor_passes': {}, 'cudagraph_mode': <CUDAGraphMode.FULL_AND_PIECEWISE: (2, 1)>, 'cudagraph_num_of_warmups': 1, 'cudagraph_capture_sizes': [1, 2, 4], 'cudagraph_copy_inputs': False, 'cudagraph_specialize_lora': True, 'use_inductor_graph_partition': False, 'pass_config': {'fuse_norm_quant': False, 'fuse_act_quant': True, 'fuse_attn_quant': False, 'enable_sp': False, 'fuse_gemm_comms': False, 'fuse_allreduce_rms': False}, 'max_cudagraph_capture_size': 4, 'dynamic_shapes_config': {'type': <DynamicShapesType.BACKED: 'backed'>, 'evaluate_guards': False, 'assume_32_bit_indexing': False}, 'local_cache_dir': None, 'fast_moe_cold_start': False, 'static_all_moe_layers': []}, kernel_config=KernelConfig(ir_op_priority=IrOpPriorityConfig(rms_norm=['native']), enable_flashinfer_autotune=True, moe_backend='cutlass')
2026-04-19 14:29:34.823 | (EngineCore pid=131) WARNING 04-19 12:29:34 [interface.py:686] Using 'pin_memory=False' as WSL is detected. This may slow down the performance.
2026-04-19 14:29:35.521 | (EngineCore pid=131) Warning: You are sending unauthenticated requests to the HF Hub. Please set a HF_TOKEN to enable higher rate limits and faster downloads.
2026-04-19 14:29:38.551 | (EngineCore pid=131) INFO 04-19 12:29:38 [parallel_state.py:1400] world_size=1 rank=0 local_rank=0 distributed_init_method=tcp://172.18.0.2:60227 backend=nccl
2026-04-19 14:29:38.847 | (EngineCore pid=131) INFO 04-19 12:29:38 [parallel_state.py:1713] rank 0 in world size 1 is assigned as DP rank 0, PP rank 0, PCP rank 0, TP rank 0, EP rank 0, EPLB rank N/A
2026-04-19 14:29:39.382 | (EngineCore pid=131) INFO 04-19 12:29:39 [gpu_model_runner.py:4752] Starting to load model RedHatAI/gemma-4-26B-A4B-it-NVFP4...
2026-04-19 14:29:39.859 | (EngineCore pid=131) INFO 04-19 12:29:39 [vllm.py:834] Asynchronous scheduling is enabled.
2026-04-19 14:29:39.860 | (EngineCore pid=131) INFO 04-19 12:29:39 [kernel.py:199] Final IR op priority after setting platform defaults: IrOpPriorityConfig(rms_norm=['native'])
2026-04-19 14:29:39.860 | (EngineCore pid=131) INFO 04-19 12:29:39 [compilation.py:294] Enabled custom fusions: act_quant
2026-04-19 14:29:39.868 | (EngineCore pid=131) INFO 04-19 12:29:39 [__init__.py:683] Using FlashInferCutlassNvFp4LinearKernel for NVFP4 GEMM
2026-04-19 14:29:39.902 | (EngineCore pid=131) INFO 04-19 12:29:39 [attention.py:262] Layer language_model.model.layers.0.self_attn.attn: kv_cache_dtype=auto, sliding_window=1024
2026-04-19 14:29:39.903 | (EngineCore pid=131) INFO 04-19 12:29:39 [cuda.py:308] Using AttentionBackendEnum.TRITON_ATTN backend.
2026-04-19 14:29:39.913 | (EngineCore pid=131) INFO 04-19 12:29:39 [nvfp4.py:203] Using 'VLLM_CUTLASS' NvFp4 MoE backend out of potential backends: ['FLASHINFER_TRTLLM', 'FLASHINFER_CUTEDSL', 'FLASHINFER_CUTEDSL_BATCHED', 'FLASHINFER_CUTLASS', 'VLLM_CUTLASS', 'MARLIN'].
2026-04-19 14:29:39.915 | (EngineCore pid=131) INFO 04-19 12:29:39 [attention.py:262] Layer language_model.model.layers.1.self_attn.attn: kv_cache_dtype=auto, sliding_window=1024
2026-04-19 14:29:39.921 | (EngineCore pid=131) INFO 04-19 12:29:39 [attention.py:262] Layer language_model.model.layers.2.self_attn.attn: kv_cache_dtype=turboquant_k8v4, sliding_window=1024
2026-04-19 14:29:40.388 | (EngineCore pid=131) Process EngineCore:
2026-04-19 14:29:40.388 | (EngineCore pid=131) ERROR 04-19 12:29:40 [core.py:1132] EngineCore failed to start.
2026-04-19 14:29:40.388 | (EngineCore pid=131) ERROR 04-19 12:29:40 [core.py:1132] Traceback (most recent call last):
2026-04-19 14:29:40.388 | (EngineCore pid=131) ERROR 04-19 12:29:40 [core.py:1132]   File "/usr/local/lib/python3.12/dist-packages/vllm/v1/engine/core.py", line 1106, in run_engine_core
2026-04-19 14:29:40.388 | (EngineCore pid=131) ERROR 04-19 12:29:40 [core.py:1132]     engine_core = EngineCoreProc(*args, engine_index=dp_rank, **kwargs)
2026-04-19 14:29:40.388 | (EngineCore pid=131) ERROR 04-19 12:29:40 [core.py:1132]                   ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
2026-04-19 14:29:40.388 | (EngineCore pid=131) ERROR 04-19 12:29:40 [core.py:1132]   File "/usr/local/lib/python3.12/dist-packages/vllm/tracing/otel.py", line 178, in sync_wrapper
2026-04-19 14:29:40.388 | (EngineCore pid=131) ERROR 04-19 12:29:40 [core.py:1132]     return func(*args, **kwargs)
2026-04-19 14:29:40.388 | (EngineCore pid=131) ERROR 04-19 12:29:40 [core.py:1132]            ^^^^^^^^^^^^^^^^^^^^^
2026-04-19 14:29:40.388 | (EngineCore pid=131) ERROR 04-19 12:29:40 [core.py:1132]   File "/usr/local/lib/python3.12/dist-packages/vllm/v1/engine/core.py", line 872, in __init__
2026-04-19 14:29:40.388 | (EngineCore pid=131) ERROR 04-19 12:29:40 [core.py:1132]     super().__init__(
2026-04-19 14:29:40.388 | (EngineCore pid=131) ERROR 04-19 12:29:40 [core.py:1132]   File "/usr/local/lib/python3.12/dist-packages/vllm/v1/engine/core.py", line 116, in __init__
2026-04-19 14:29:40.388 | (EngineCore pid=131) ERROR 04-19 12:29:40 [core.py:1132]     self.model_executor = executor_class(vllm_config)
2026-04-19 14:29:40.388 | (EngineCore pid=131) ERROR 04-19 12:29:40 [core.py:1132]                           ^^^^^^^^^^^^^^^^^^^^^^^^^^^
2026-04-19 14:29:40.388 | (EngineCore pid=131) ERROR 04-19 12:29:40 [core.py:1132]   File "/usr/local/lib/python3.12/dist-packages/vllm/tracing/otel.py", line 178, in sync_wrapper
2026-04-19 14:29:40.388 | (EngineCore pid=131) ERROR 04-19 12:29:40 [core.py:1132]     return func(*args, **kwargs)
2026-04-19 14:29:40.388 | (EngineCore pid=131) ERROR 04-19 12:29:40 [core.py:1132]            ^^^^^^^^^^^^^^^^^^^^^
2026-04-19 14:29:40.388 | (EngineCore pid=131) ERROR 04-19 12:29:40 [core.py:1132]   File "/usr/local/lib/python3.12/dist-packages/vllm/v1/executor/abstract.py", line 109, in __init__
2026-04-19 14:29:40.388 | (EngineCore pid=131) ERROR 04-19 12:29:40 [core.py:1132]     self._init_executor()
2026-04-19 14:29:40.388 | (EngineCore pid=131) ERROR 04-19 12:29:40 [core.py:1132]   File "/usr/local/lib/python3.12/dist-packages/vllm/v1/executor/uniproc_executor.py", line 52, in _init_executor
2026-04-19 14:29:40.388 | (EngineCore pid=131) ERROR 04-19 12:29:40 [core.py:1132]     self.driver_worker.load_model()
2026-04-19 14:29:40.388 | (EngineCore pid=131) ERROR 04-19 12:29:40 [core.py:1132]   File "/usr/local/lib/python3.12/dist-packages/vllm/v1/worker/gpu_worker.py", line 323, in load_model
2026-04-19 14:29:40.388 | (EngineCore pid=131) ERROR 04-19 12:29:40 [core.py:1132]     self.model_runner.load_model(load_dummy_weights=load_dummy_weights)
2026-04-19 14:29:40.388 | (EngineCore pid=131) ERROR 04-19 12:29:40 [core.py:1132]   File "/usr/local/lib/python3.12/dist-packages/vllm/tracing/otel.py", line 178, in sync_wrapper
2026-04-19 14:29:40.388 | (EngineCore pid=131) ERROR 04-19 12:29:40 [core.py:1132]     return func(*args, **kwargs)
2026-04-19 14:29:40.388 | (EngineCore pid=131) ERROR 04-19 12:29:40 [core.py:1132]            ^^^^^^^^^^^^^^^^^^^^^
2026-04-19 14:29:40.388 | (EngineCore pid=131) ERROR 04-19 12:29:40 [core.py:1132]   File "/usr/local/lib/python3.12/dist-packages/vllm/v1/worker/gpu_model_runner.py", line 4768, in load_model
2026-04-19 14:29:40.388 | (EngineCore pid=131) ERROR 04-19 12:29:40 [core.py:1132]     self.model = model_loader.load_model(
2026-04-19 14:29:40.388 | (EngineCore pid=131) ERROR 04-19 12:29:40 [core.py:1132]                  ^^^^^^^^^^^^^^^^^^^^^^^^
2026-04-19 14:29:40.388 | (EngineCore pid=131) ERROR 04-19 12:29:40 [core.py:1132]   File "/usr/local/lib/python3.12/dist-packages/vllm/tracing/otel.py", line 178, in sync_wrapper
2026-04-19 14:29:40.388 | (EngineCore pid=131) ERROR 04-19 12:29:40 [core.py:1132]     return func(*args, **kwargs)
2026-04-19 14:29:40.388 | (EngineCore pid=131) ERROR 04-19 12:29:40 [core.py:1132]            ^^^^^^^^^^^^^^^^^^^^^
2026-04-19 14:29:40.388 | (EngineCore pid=131) ERROR 04-19 12:29:40 [core.py:1132]   File "/usr/local/lib/python3.12/dist-packages/vllm/model_executor/model_loader/base_loader.py", line 55, in load_model
2026-04-19 14:29:40.388 | (EngineCore pid=131) ERROR 04-19 12:29:40 [core.py:1132]     model = initialize_model(
2026-04-19 14:29:40.388 | (EngineCore pid=131) ERROR 04-19 12:29:40 [core.py:1132]             ^^^^^^^^^^^^^^^^^
2026-04-19 14:29:40.388 | (EngineCore pid=131) ERROR 04-19 12:29:40 [core.py:1132]   File "/usr/local/lib/python3.12/dist-packages/vllm/tracing/otel.py", line 178, in sync_wrapper
2026-04-19 14:29:40.388 | (EngineCore pid=131) ERROR 04-19 12:29:40 [core.py:1132]     return func(*args, **kwargs)
2026-04-19 14:29:40.388 | (EngineCore pid=131) ERROR 04-19 12:29:40 [core.py:1132]            ^^^^^^^^^^^^^^^^^^^^^
2026-04-19 14:29:40.388 | (EngineCore pid=131) ERROR 04-19 12:29:40 [core.py:1132]   File "/usr/local/lib/python3.12/dist-packages/vllm/model_executor/model_loader/utils.py", line 57, in initialize_model
2026-04-19 14:29:40.388 | (EngineCore pid=131) ERROR 04-19 12:29:40 [core.py:1132]     model = model_class(vllm_config=vllm_config, prefix=prefix)
2026-04-19 14:29:40.388 | (EngineCore pid=131) ERROR 04-19 12:29:40 [core.py:1132]             ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
2026-04-19 14:29:40.388 | (EngineCore pid=131) ERROR 04-19 12:29:40 [core.py:1132]   File "/usr/local/lib/python3.12/dist-packages/vllm/model_executor/models/gemma4_mm.py", line 946, in __init__
2026-04-19 14:29:40.388 | (EngineCore pid=131) ERROR 04-19 12:29:40 [core.py:1132]     self.language_model: Gemma4ForCausalLM = init_vllm_registered_model(
2026-04-19 14:29:40.388 | (EngineCore pid=131) ERROR 04-19 12:29:40 [core.py:1132]                                              ^^^^^^^^^^^^^^^^^^^^^^^^^^^
2026-04-19 14:29:40.388 | (EngineCore pid=131) ERROR 04-19 12:29:40 [core.py:1132]   File "/usr/local/lib/python3.12/dist-packages/vllm/model_executor/models/utils.py", line 379, in init_vllm_registered_model
2026-04-19 14:29:40.388 | (EngineCore pid=131) ERROR 04-19 12:29:40 [core.py:1132]     return initialize_model(vllm_config=vllm_config, prefix=prefix)
2026-04-19 14:29:40.388 | (EngineCore pid=131) ERROR 04-19 12:29:40 [core.py:1132]            ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
2026-04-19 14:29:40.388 | (EngineCore pid=131) ERROR 04-19 12:29:40 [core.py:1132]   File "/usr/local/lib/python3.12/dist-packages/vllm/tracing/otel.py", line 178, in sync_wrapper
2026-04-19 14:29:40.388 | (EngineCore pid=131) ERROR 04-19 12:29:40 [core.py:1132]     return func(*args, **kwargs)
2026-04-19 14:29:40.388 | (EngineCore pid=131) ERROR 04-19 12:29:40 [core.py:1132]            ^^^^^^^^^^^^^^^^^^^^^
2026-04-19 14:29:40.388 | (EngineCore pid=131) ERROR 04-19 12:29:40 [core.py:1132]   File "/usr/local/lib/python3.12/dist-packages/vllm/model_executor/model_loader/utils.py", line 57, in initialize_model
2026-04-19 14:29:40.388 | (EngineCore pid=131) ERROR 04-19 12:29:40 [core.py:1132]     model = model_class(vllm_config=vllm_config, prefix=prefix)
2026-04-19 14:29:40.388 | (EngineCore pid=131) ERROR 04-19 12:29:40 [core.py:1132]             ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
2026-04-19 14:29:40.388 | (EngineCore pid=131) ERROR 04-19 12:29:40 [core.py:1132]   File "/usr/local/lib/python3.12/dist-packages/vllm/model_executor/models/gemma4.py", line 1439, in __init__
2026-04-19 14:29:40.388 | (EngineCore pid=131) ERROR 04-19 12:29:40 [core.py:1132]     self.model = Gemma4Model(
2026-04-19 14:29:40.388 | (EngineCore pid=131) ERROR 04-19 12:29:40 [core.py:1132]                  ^^^^^^^^^^^^
2026-04-19 14:29:40.388 | (EngineCore pid=131) ERROR 04-19 12:29:40 [core.py:1132]   File "/usr/local/lib/python3.12/dist-packages/vllm/compilation/decorators.py", line 379, in __init__
2026-04-19 14:29:40.388 | (EngineCore pid=131) ERROR 04-19 12:29:40 [core.py:1132]     old_init(self, *args, **kwargs)
2026-04-19 14:29:40.388 | (EngineCore pid=131) ERROR 04-19 12:29:40 [core.py:1132]   File "/usr/local/lib/python3.12/dist-packages/vllm/model_executor/models/gemma4.py", line 931, in __init__
2026-04-19 14:29:40.388 | (EngineCore pid=131) ERROR 04-19 12:29:40 [core.py:1132]     self.start_layer, self.end_layer, self.layers = make_layers(
2026-04-19 14:29:40.388 | (EngineCore pid=131) ERROR 04-19 12:29:40 [core.py:1132]                                                     ^^^^^^^^^^^^
2026-04-19 14:29:40.388 | (EngineCore pid=131) ERROR 04-19 12:29:40 [core.py:1132]   File "/usr/local/lib/python3.12/dist-packages/vllm/model_executor/models/utils.py", line 646, in make_layers
2026-04-19 14:29:40.388 | (EngineCore pid=131) ERROR 04-19 12:29:40 [core.py:1132]     + get_offloader().wrap_modules(
2026-04-19 14:29:40.388 | (EngineCore pid=131) ERROR 04-19 12:29:40 [core.py:1132]       ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
2026-04-19 14:29:40.388 | (EngineCore pid=131) ERROR 04-19 12:29:40 [core.py:1132]   File "/usr/local/lib/python3.12/dist-packages/vllm/model_executor/offloader/base.py", line 104, in wrap_modules
2026-04-19 14:29:40.388 | (EngineCore pid=131) ERROR 04-19 12:29:40 [core.py:1132]     return list(modules_generator)
2026-04-19 14:29:40.388 | (EngineCore pid=131) ERROR 04-19 12:29:40 [core.py:1132]            ^^^^^^^^^^^^^^^^^^^^^^^
2026-04-19 14:29:40.388 | (EngineCore pid=131) ERROR 04-19 12:29:40 [core.py:1132]   File "/usr/local/lib/python3.12/dist-packages/vllm/model_executor/models/utils.py", line 647, in <genexpr>
2026-04-19 14:29:40.388 | (EngineCore pid=131) ERROR 04-19 12:29:40 [core.py:1132]     layer_fn(prefix=f"{prefix}.{idx}") for idx in range(start_layer, end_layer)
2026-04-19 14:29:40.388 | (EngineCore pid=131) ERROR 04-19 12:29:40 [core.py:1132]     ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
2026-04-19 14:29:40.388 | (EngineCore pid=131) ERROR 04-19 12:29:40 [core.py:1132]   File "/usr/local/lib/python3.12/dist-packages/vllm/model_executor/models/gemma4.py", line 933, in <lambda>
2026-04-19 14:29:40.388 | (EngineCore pid=131) ERROR 04-19 12:29:40 [core.py:1132]     lambda prefix: Gemma4DecoderLayer(
2026-04-19 14:29:40.388 | (EngineCore pid=131) ERROR 04-19 12:29:40 [core.py:1132]                    ^^^^^^^^^^^^^^^^^^^
2026-04-19 14:29:40.388 | (EngineCore pid=131) ERROR 04-19 12:29:40 [core.py:1132]   File "/usr/local/lib/python3.12/dist-packages/vllm/model_executor/models/gemma4.py", line 472, in __init__
2026-04-19 14:29:40.388 | (EngineCore pid=131) ERROR 04-19 12:29:40 [core.py:1132]     self.self_attn = Gemma4Attention(
2026-04-19 14:29:40.388 | (EngineCore pid=131) ERROR 04-19 12:29:40 [core.py:1132]                      ^^^^^^^^^^^^^^^^
2026-04-19 14:29:40.388 | (EngineCore pid=131) ERROR 04-19 12:29:40 [core.py:1132]   File "/usr/local/lib/python3.12/dist-packages/vllm/model_executor/models/gemma4.py", line 382, in __init__
2026-04-19 14:29:40.388 | (EngineCore pid=131) ERROR 04-19 12:29:40 [core.py:1132]     self.attn = Attention(
2026-04-19 14:29:40.388 | (EngineCore pid=131) ERROR 04-19 12:29:40 [core.py:1132]                 ^^^^^^^^^^
2026-04-19 14:29:40.388 | (EngineCore pid=131) ERROR 04-19 12:29:40 [core.py:1132]   File "/usr/local/lib/python3.12/dist-packages/vllm/model_executor/layers/attention/attention.py", line 297, in __init__
2026-04-19 14:29:40.388 | (EngineCore pid=131) ERROR 04-19 12:29:40 [core.py:1132]     self.attn_backend = get_attn_backend(
2026-04-19 14:29:40.388 | (EngineCore pid=131) ERROR 04-19 12:29:40 [core.py:1132]                         ^^^^^^^^^^^^^^^^^
2026-04-19 14:29:40.388 | (EngineCore pid=131) ERROR 04-19 12:29:40 [core.py:1132]   File "/usr/local/lib/python3.12/dist-packages/vllm/v1/attention/selector.py", line 100, in get_attn_backend
2026-04-19 14:29:40.388 | (EngineCore pid=131) ERROR 04-19 12:29:40 [core.py:1132]     return _cached_get_attn_backend(
2026-04-19 14:29:40.388 | (EngineCore pid=131) ERROR 04-19 12:29:40 [core.py:1132]            ^^^^^^^^^^^^^^^^^^^^^^^^^
2026-04-19 14:29:40.388 | (EngineCore pid=131) ERROR 04-19 12:29:40 [core.py:1132]   File "/usr/local/lib/python3.12/dist-packages/vllm/v1/attention/selector.py", line 115, in _cached_get_attn_backend
2026-04-19 14:29:40.388 | (EngineCore pid=131) ERROR 04-19 12:29:40 [core.py:1132]     attention_cls = current_platform.get_attn_backend_cls(
2026-04-19 14:29:40.388 | (EngineCore pid=131) ERROR 04-19 12:29:40 [core.py:1132]                     ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
2026-04-19 14:29:40.388 | (EngineCore pid=131) ERROR 04-19 12:29:40 [core.py:1132]   File "/usr/local/lib/python3.12/dist-packages/vllm/platforms/cuda.py", line 303, in get_attn_backend_cls
2026-04-19 14:29:40.388 | (EngineCore pid=131) ERROR 04-19 12:29:40 [core.py:1132]     raise ValueError(
2026-04-19 14:29:40.388 | (EngineCore pid=131) ERROR 04-19 12:29:40 [core.py:1132] ValueError: Selected backend AttentionBackendEnum.TRITON_ATTN is not valid for this configuration. Reason: ['kv_cache_dtype not supported']
2026-04-19 14:29:40.389 | (EngineCore pid=131) Traceback (most recent call last):
2026-04-19 14:29:40.389 | (EngineCore pid=131)   File "/usr/lib/python3.12/multiprocessing/process.py", line 314, in _bootstrap
2026-04-19 14:29:40.389 | (EngineCore pid=131)     self.run()
2026-04-19 14:29:40.389 | (EngineCore pid=131)   File "/usr/lib/python3.12/multiprocessing/process.py", line 108, in run
2026-04-19 14:29:40.389 | (EngineCore pid=131)     self._target(*self._args, **self._kwargs)
2026-04-19 14:29:40.389 | (EngineCore pid=131)   File "/usr/local/lib/python3.12/dist-packages/vllm/v1/engine/core.py", line 1136, in run_engine_core
2026-04-19 14:29:40.389 | (EngineCore pid=131)     raise e
2026-04-19 14:29:40.389 | (EngineCore pid=131)   File "/usr/local/lib/python3.12/dist-packages/vllm/v1/engine/core.py", line 1106, in run_engine_core
2026-04-19 14:29:40.389 | (EngineCore pid=131)     engine_core = EngineCoreProc(*args, engine_index=dp_rank, **kwargs)
2026-04-19 14:29:40.389 | (EngineCore pid=131)                   ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
2026-04-19 14:29:40.389 | (EngineCore pid=131)   File "/usr/local/lib/python3.12/dist-packages/vllm/tracing/otel.py", line 178, in sync_wrapper
2026-04-19 14:29:40.389 | (EngineCore pid=131)     return func(*args, **kwargs)
2026-04-19 14:29:40.389 | (EngineCore pid=131)            ^^^^^^^^^^^^^^^^^^^^^
2026-04-19 14:29:40.389 | (EngineCore pid=131)   File "/usr/local/lib/python3.12/dist-packages/vllm/v1/engine/core.py", line 872, in __init__
2026-04-19 14:29:40.389 | (EngineCore pid=131)     super().__init__(
2026-04-19 14:29:40.389 | (EngineCore pid=131)   File "/usr/local/lib/python3.12/dist-packages/vllm/v1/engine/core.py", line 116, in __init__
2026-04-19 14:29:40.389 | (EngineCore pid=131)     self.model_executor = executor_class(vllm_config)
2026-04-19 14:29:40.389 | (EngineCore pid=131)                           ^^^^^^^^^^^^^^^^^^^^^^^^^^^
2026-04-19 14:29:40.389 | (EngineCore pid=131)   File "/usr/local/lib/python3.12/dist-packages/vllm/tracing/otel.py", line 178, in sync_wrapper
2026-04-19 14:29:40.389 | (EngineCore pid=131)     return func(*args, **kwargs)
2026-04-19 14:29:40.389 | (EngineCore pid=131)            ^^^^^^^^^^^^^^^^^^^^^
2026-04-19 14:29:40.389 | (EngineCore pid=131)   File "/usr/local/lib/python3.12/dist-packages/vllm/v1/executor/abstract.py", line 109, in __init__
2026-04-19 14:29:40.389 | (EngineCore pid=131)     self._init_executor()
2026-04-19 14:29:40.389 | (EngineCore pid=131)   File "/usr/local/lib/python3.12/dist-packages/vllm/v1/executor/uniproc_executor.py", line 52, in _init_executor
2026-04-19 14:29:40.389 | (EngineCore pid=131)     self.driver_worker.load_model()
2026-04-19 14:29:40.389 | (EngineCore pid=131)   File "/usr/local/lib/python3.12/dist-packages/vllm/v1/worker/gpu_worker.py", line 323, in load_model
2026-04-19 14:29:40.389 | (EngineCore pid=131)     self.model_runner.load_model(load_dummy_weights=load_dummy_weights)
2026-04-19 14:29:40.389 | (EngineCore pid=131)   File "/usr/local/lib/python3.12/dist-packages/vllm/tracing/otel.py", line 178, in sync_wrapper
2026-04-19 14:29:40.389 | (EngineCore pid=131)     return func(*args, **kwargs)
2026-04-19 14:29:40.389 | (EngineCore pid=131)            ^^^^^^^^^^^^^^^^^^^^^
2026-04-19 14:29:40.389 | (EngineCore pid=131)   File "/usr/local/lib/python3.12/dist-packages/vllm/v1/worker/gpu_model_runner.py", line 4768, in load_model
2026-04-19 14:29:40.389 | (EngineCore pid=131)     self.model = model_loader.load_model(
2026-04-19 14:29:40.389 | (EngineCore pid=131)                  ^^^^^^^^^^^^^^^^^^^^^^^^
2026-04-19 14:29:40.389 | (EngineCore pid=131)   File "/usr/local/lib/python3.12/dist-packages/vllm/tracing/otel.py", line 178, in sync_wrapper
2026-04-19 14:29:40.389 | (EngineCore pid=131)     return func(*args, **kwargs)
2026-04-19 14:29:40.389 | (EngineCore pid=131)            ^^^^^^^^^^^^^^^^^^^^^
2026-04-19 14:29:40.389 | (EngineCore pid=131)   File "/usr/local/lib/python3.12/dist-packages/vllm/model_executor/model_loader/base_loader.py", line 55, in load_model
2026-04-19 14:29:40.389 | (EngineCore pid=131)     model = initialize_model(
2026-04-19 14:29:40.389 | (EngineCore pid=131)             ^^^^^^^^^^^^^^^^^
2026-04-19 14:29:40.389 | (EngineCore pid=131)   File "/usr/local/lib/python3.12/dist-packages/vllm/tracing/otel.py", line 178, in sync_wrapper
2026-04-19 14:29:40.389 | (EngineCore pid=131)     return func(*args, **kwargs)
2026-04-19 14:29:40.389 | (EngineCore pid=131)            ^^^^^^^^^^^^^^^^^^^^^
2026-04-19 14:29:40.389 | (EngineCore pid=131)   File "/usr/local/lib/python3.12/dist-packages/vllm/model_executor/model_loader/utils.py", line 57, in initialize_model
2026-04-19 14:29:40.389 | (EngineCore pid=131)     model = model_class(vllm_config=vllm_config, prefix=prefix)
2026-04-19 14:29:40.389 | (EngineCore pid=131)             ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
2026-04-19 14:29:40.389 | (EngineCore pid=131)   File "/usr/local/lib/python3.12/dist-packages/vllm/model_executor/models/gemma4_mm.py", line 946, in __init__
2026-04-19 14:29:40.389 | (EngineCore pid=131)     self.language_model: Gemma4ForCausalLM = init_vllm_registered_model(
2026-04-19 14:29:40.389 | (EngineCore pid=131)                                              ^^^^^^^^^^^^^^^^^^^^^^^^^^^
2026-04-19 14:29:40.389 | (EngineCore pid=131)   File "/usr/local/lib/python3.12/dist-packages/vllm/model_executor/models/utils.py", line 379, in init_vllm_registered_model
2026-04-19 14:29:40.389 | (EngineCore pid=131)     return initialize_model(vllm_config=vllm_config, prefix=prefix)
2026-04-19 14:29:40.389 | (EngineCore pid=131)            ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
2026-04-19 14:29:40.389 | (EngineCore pid=131)   File "/usr/local/lib/python3.12/dist-packages/vllm/tracing/otel.py", line 178, in sync_wrapper
2026-04-19 14:29:40.389 | (EngineCore pid=131)     return func(*args, **kwargs)
2026-04-19 14:29:40.389 | (EngineCore pid=131)            ^^^^^^^^^^^^^^^^^^^^^
2026-04-19 14:29:40.389 | (EngineCore pid=131)   File "/usr/local/lib/python3.12/dist-packages/vllm/model_executor/model_loader/utils.py", line 57, in initialize_model
2026-04-19 14:29:40.389 | (EngineCore pid=131)     model = model_class(vllm_config=vllm_config, prefix=prefix)
2026-04-19 14:29:40.389 | (EngineCore pid=131)             ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
2026-04-19 14:29:40.389 | (EngineCore pid=131)   File "/usr/local/lib/python3.12/dist-packages/vllm/model_executor/models/gemma4.py", line 1439, in __init__
2026-04-19 14:29:40.389 | (EngineCore pid=131)     self.model = Gemma4Model(
2026-04-19 14:29:40.389 | (EngineCore pid=131)                  ^^^^^^^^^^^^
2026-04-19 14:29:40.389 | (EngineCore pid=131)   File "/usr/local/lib/python3.12/dist-packages/vllm/compilation/decorators.py", line 379, in __init__
2026-04-19 14:29:40.389 | (EngineCore pid=131)     old_init(self, *args, **kwargs)
2026-04-19 14:29:40.389 | (EngineCore pid=131)   File "/usr/local/lib/python3.12/dist-packages/vllm/model_executor/models/gemma4.py", line 931, in __init__
2026-04-19 14:29:40.389 | (EngineCore pid=131)     self.start_layer, self.end_layer, self.layers = make_layers(
2026-04-19 14:29:40.389 | (EngineCore pid=131)                                                     ^^^^^^^^^^^^
2026-04-19 14:29:40.389 | (EngineCore pid=131)   File "/usr/local/lib/python3.12/dist-packages/vllm/model_executor/models/utils.py", line 646, in make_layers
2026-04-19 14:29:40.389 | (EngineCore pid=131)     + get_offloader().wrap_modules(
2026-04-19 14:29:40.389 | (EngineCore pid=131)       ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
2026-04-19 14:29:40.389 | (EngineCore pid=131)   File "/usr/local/lib/python3.12/dist-packages/vllm/model_executor/offloader/base.py", line 104, in wrap_modules
2026-04-19 14:29:40.389 | (EngineCore pid=131)     return list(modules_generator)
2026-04-19 14:29:40.389 | (EngineCore pid=131)            ^^^^^^^^^^^^^^^^^^^^^^^
2026-04-19 14:29:40.389 | (EngineCore pid=131)   File "/usr/local/lib/python3.12/dist-packages/vllm/model_executor/models/utils.py", line 647, in <genexpr>
2026-04-19 14:29:40.389 | (EngineCore pid=131)     layer_fn(prefix=f"{prefix}.{idx}") for idx in range(start_layer, end_layer)
2026-04-19 14:29:40.389 | (EngineCore pid=131)     ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
2026-04-19 14:29:40.389 | (EngineCore pid=131)   File "/usr/local/lib/python3.12/dist-packages/vllm/model_executor/models/gemma4.py", line 933, in <lambda>
2026-04-19 14:29:40.389 | (EngineCore pid=131)     lambda prefix: Gemma4DecoderLayer(
2026-04-19 14:29:40.389 | (EngineCore pid=131)                    ^^^^^^^^^^^^^^^^^^^
2026-04-19 14:29:40.389 | (EngineCore pid=131)   File "/usr/local/lib/python3.12/dist-packages/vllm/model_executor/models/gemma4.py", line 472, in __init__
2026-04-19 14:29:40.389 | (EngineCore pid=131)     self.self_attn = Gemma4Attention(
2026-04-19 14:29:40.389 | (EngineCore pid=131)                      ^^^^^^^^^^^^^^^^
2026-04-19 14:29:40.389 | (EngineCore pid=131)   File "/usr/local/lib/python3.12/dist-packages/vllm/model_executor/models/gemma4.py", line 382, in __init__
2026-04-19 14:29:40.389 | (EngineCore pid=131)     self.attn = Attention(
2026-04-19 14:29:40.389 | (EngineCore pid=131)                 ^^^^^^^^^^
2026-04-19 14:29:40.389 | (EngineCore pid=131)   File "/usr/local/lib/python3.12/dist-packages/vllm/model_executor/layers/attention/attention.py", line 297, in __init__
2026-04-19 14:29:40.389 | (EngineCore pid=131)     self.attn_backend = get_attn_backend(
2026-04-19 14:29:40.389 | (EngineCore pid=131)                         ^^^^^^^^^^^^^^^^^
2026-04-19 14:29:40.389 | (EngineCore pid=131)   File "/usr/local/lib/python3.12/dist-packages/vllm/v1/attention/selector.py", line 100, in get_attn_backend
2026-04-19 14:29:40.389 | (EngineCore pid=131)     return _cached_get_attn_backend(
2026-04-19 14:29:40.389 | (EngineCore pid=131)            ^^^^^^^^^^^^^^^^^^^^^^^^^
2026-04-19 14:29:40.389 | (EngineCore pid=131)   File "/usr/local/lib/python3.12/dist-packages/vllm/v1/attention/selector.py", line 115, in _cached_get_attn_backend
2026-04-19 14:29:40.389 | (EngineCore pid=131)     attention_cls = current_platform.get_attn_backend_cls(
2026-04-19 14:29:40.389 | (EngineCore pid=131)                     ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
2026-04-19 14:29:40.389 | (EngineCore pid=131)   File "/usr/local/lib/python3.12/dist-packages/vllm/platforms/cuda.py", line 303, in get_attn_backend_cls
2026-04-19 14:29:40.389 | (EngineCore pid=131)     raise ValueError(
2026-04-19 14:29:40.389 | (EngineCore pid=131) ValueError: Selected backend AttentionBackendEnum.TRITON_ATTN is not valid for this configuration. Reason: ['kv_cache_dtype not supported']
2026-04-19 14:29:40.933 | [rank0]:[W419 12:29:40.474206125 ProcessGroupNCCL.cpp:1575] Warning: WARNING: destroy_process_group() was not called before program exit, which can leak resources. For more info, please see https://pytorch.org/docs/stable/distributed.html#shutdown (function operator())
2026-04-19 14:29:41.788 | (APIServer pid=1) Traceback (most recent call last):
2026-04-19 14:29:41.788 | (APIServer pid=1)   File "/usr/local/bin/vllm", line 10, in <module>
2026-04-19 14:29:41.788 | (APIServer pid=1)     sys.exit(main())
2026-04-19 14:29:41.788 | (APIServer pid=1)              ^^^^^^
2026-04-19 14:29:41.788 | (APIServer pid=1)   File "/usr/local/lib/python3.12/dist-packages/vllm/entrypoints/cli/main.py", line 75, in main
2026-04-19 14:29:41.788 | (APIServer pid=1)     args.dispatch_function(args)
2026-04-19 14:29:41.788 | (APIServer pid=1)   File "/usr/local/lib/python3.12/dist-packages/vllm/entrypoints/cli/serve.py", line 122, in cmd
2026-04-19 14:29:41.788 | (APIServer pid=1)     uvloop.run(run_server(args))
2026-04-19 14:29:41.788 | (APIServer pid=1)   File "/usr/local/lib/python3.12/dist-packages/uvloop/__init__.py", line 96, in run
2026-04-19 14:29:41.788 | (APIServer pid=1)     return __asyncio.run(
2026-04-19 14:29:41.788 | (APIServer pid=1)            ^^^^^^^^^^^^^^
2026-04-19 14:29:41.788 | (APIServer pid=1)   File "/usr/lib/python3.12/asyncio/runners.py", line 195, in run
2026-04-19 14:29:41.788 | (APIServer pid=1)     return runner.run(main)
2026-04-19 14:29:41.788 | (APIServer pid=1)            ^^^^^^^^^^^^^^^^
2026-04-19 14:29:41.788 | (APIServer pid=1)   File "/usr/lib/python3.12/asyncio/runners.py", line 118, in run
2026-04-19 14:29:41.789 | (APIServer pid=1)     return self._loop.run_until_complete(task)
2026-04-19 14:29:41.789 | (APIServer pid=1)            ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
2026-04-19 14:29:41.789 | (APIServer pid=1)   File "uvloop/loop.pyx", line 1518, in uvloop.loop.Loop.run_until_complete
2026-04-19 14:29:41.789 | (APIServer pid=1)   File "/usr/local/lib/python3.12/dist-packages/uvloop/__init__.py", line 48, in wrapper
2026-04-19 14:29:41.789 | (APIServer pid=1)     return await main
2026-04-19 14:29:41.789 | (APIServer pid=1)            ^^^^^^^^^^
2026-04-19 14:29:41.789 | (APIServer pid=1)   File "/usr/local/lib/python3.12/dist-packages/vllm/entrypoints/openai/api_server.py", line 678, in run_server
2026-04-19 14:29:41.789 | (APIServer pid=1)     await run_server_worker(listen_address, sock, args, **uvicorn_kwargs)
2026-04-19 14:29:41.789 | (APIServer pid=1)   File "/usr/local/lib/python3.12/dist-packages/vllm/entrypoints/openai/api_server.py", line 692, in run_server_worker
2026-04-19 14:29:41.789 | (APIServer pid=1)     async with build_async_engine_client(
2026-04-19 14:29:41.789 | (APIServer pid=1)                ^^^^^^^^^^^^^^^^^^^^^^^^^^
2026-04-19 14:29:41.789 | (APIServer pid=1)   File "/usr/lib/python3.12/contextlib.py", line 210, in __aenter__
2026-04-19 14:29:41.789 | (APIServer pid=1)     return await anext(self.gen)
2026-04-19 14:29:41.789 | (APIServer pid=1)            ^^^^^^^^^^^^^^^^^^^^^
2026-04-19 14:29:41.789 | (APIServer pid=1)   File "/usr/local/lib/python3.12/dist-packages/vllm/entrypoints/openai/api_server.py", line 100, in build_async_engine_client
2026-04-19 14:29:41.789 | (APIServer pid=1)     async with build_async_engine_client_from_engine_args(
2026-04-19 14:29:41.789 | (APIServer pid=1)                ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
2026-04-19 14:29:41.789 | (APIServer pid=1)   File "/usr/lib/python3.12/contextlib.py", line 210, in __aenter__
2026-04-19 14:29:41.789 | (APIServer pid=1)     return await anext(self.gen)
2026-04-19 14:29:41.789 | (APIServer pid=1)            ^^^^^^^^^^^^^^^^^^^^^
2026-04-19 14:29:41.789 | (APIServer pid=1)   File "/usr/local/lib/python3.12/dist-packages/vllm/entrypoints/openai/api_server.py", line 136, in build_async_engine_client_from_engine_args
2026-04-19 14:29:41.790 | (APIServer pid=1)     async_llm = AsyncLLM.from_vllm_config(
2026-04-19 14:29:41.790 | (APIServer pid=1)                 ^^^^^^^^^^^^^^^^^^^^^^^^^^
2026-04-19 14:29:41.790 | (APIServer pid=1)   File "/usr/local/lib/python3.12/dist-packages/vllm/v1/engine/async_llm.py", line 219, in from_vllm_config
2026-04-19 14:29:41.790 | (APIServer pid=1)     return cls(
2026-04-19 14:29:41.790 | (APIServer pid=1)            ^^^^
2026-04-19 14:29:41.790 | (APIServer pid=1)   File "/usr/local/lib/python3.12/dist-packages/vllm/v1/engine/async_llm.py", line 148, in __init__
2026-04-19 14:29:41.790 | (APIServer pid=1)     self.engine_core = EngineCoreClient.make_async_mp_client(
2026-04-19 14:29:41.790 | (APIServer pid=1)                        ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
2026-04-19 14:29:41.790 | (APIServer pid=1)   File "/usr/local/lib/python3.12/dist-packages/vllm/tracing/otel.py", line 178, in sync_wrapper
2026-04-19 14:29:41.790 | (APIServer pid=1)     return func(*args, **kwargs)
2026-04-19 14:29:41.790 | (APIServer pid=1)            ^^^^^^^^^^^^^^^^^^^^^
2026-04-19 14:29:41.790 | (APIServer pid=1)   File "/usr/local/lib/python3.12/dist-packages/vllm/v1/engine/core_client.py", line 130, in make_async_mp_client
2026-04-19 14:29:41.790 | (APIServer pid=1)     return AsyncMPClient(*client_args)
2026-04-19 14:29:41.790 | (APIServer pid=1)            ^^^^^^^^^^^^^^^^^^^^^^^^^^^
2026-04-19 14:29:41.790 | (APIServer pid=1)   File "/usr/local/lib/python3.12/dist-packages/vllm/tracing/otel.py", line 178, in sync_wrapper
2026-04-19 14:29:41.790 | (APIServer pid=1)     return func(*args, **kwargs)
2026-04-19 14:29:41.790 | (APIServer pid=1)            ^^^^^^^^^^^^^^^^^^^^^
2026-04-19 14:29:41.790 | (APIServer pid=1)   File "/usr/local/lib/python3.12/dist-packages/vllm/v1/engine/core_client.py", line 900, in __init__
2026-04-19 14:29:41.790 | (APIServer pid=1)     super().__init__(
2026-04-19 14:29:41.791 | (APIServer pid=1)   File "/usr/local/lib/python3.12/dist-packages/vllm/v1/engine/core_client.py", line 535, in __init__
2026-04-19 14:29:41.791 | (APIServer pid=1)     with launch_core_engines(
2026-04-19 14:29:41.791 | (APIServer pid=1)          ^^^^^^^^^^^^^^^^^^^^
2026-04-19 14:29:41.791 | (APIServer pid=1)   File "/usr/lib/python3.12/contextlib.py", line 144, in __exit__
2026-04-19 14:29:41.792 | (APIServer pid=1)     next(self.gen)
2026-04-19 14:29:41.792 | (APIServer pid=1)   File "/usr/local/lib/python3.12/dist-packages/vllm/v1/engine/utils.py", line 1094, in launch_core_engines
2026-04-19 14:29:41.792 | (APIServer pid=1)     wait_for_engine_startup(
2026-04-19 14:29:41.792 | (APIServer pid=1)   File "/usr/local/lib/python3.12/dist-packages/vllm/v1/engine/utils.py", line 1153, in wait_for_engine_startup
2026-04-19 14:29:41.792 | (APIServer pid=1)     raise RuntimeError(
2026-04-19 14:29:41.792 | (APIServer pid=1) RuntimeError: Engine core initialization failed. See root cause above. Failed core proc(s): {}
2026-04-19 14:29:49.969 | WARNING 04-19 12:29:49 [interface.py:686] Using 'pin_memory=False' as WSL is detected. This may slow down the performance.
2026-04-19 14:29:50.019 | (APIServer pid=1) INFO 04-19 12:29:50 [utils.py:299] 
2026-04-19 14:29:50.019 | (APIServer pid=1) INFO 04-19 12:29:50 [utils.py:299]        █     █     █▄   ▄█
2026-04-19 14:29:50.019 | (APIServer pid=1) INFO 04-19 12:29:50 [utils.py:299]  ▄▄ ▄█ █     █     █ ▀▄▀ █  version 0.19.2rc1.dev8+g4b7f5ea1a
2026-04-19 14:29:50.019 | (APIServer pid=1) INFO 04-19 12:29:50 [utils.py:299]   █▄█▀ █     █     █     █  model   RedHatAI/gemma-4-26B-A4B-it-NVFP4
2026-04-19 14:29:50.019 | (APIServer pid=1) INFO 04-19 12:29:50 [utils.py:299]    ▀▀  ▀▀▀▀▀ ▀▀▀▀▀ ▀     ▀
2026-04-19 14:29:50.019 | (APIServer pid=1) INFO 04-19 12:29:50 [utils.py:299] 
2026-04-19 14:29:50.022 | (APIServer pid=1) INFO 04-19 12:29:50 [utils.py:233] non-default args: {'model_tag': 'RedHatAI/gemma-4-26B-A4B-it-NVFP4', 'tool_call_parser': 'gemma4', 'host': '0.0.0.0', 'model': 'RedHatAI/gemma-4-26B-A4B-it-NVFP4', 'trust_remote_code': True, 'max_model_len': 196608, 'quantization': 'compressed-tensors', 'served_model_name': ['gemma-4-26b-it-nvfp4'], 'reasoning_parser': 'gemma4', 'gpu_memory_utilization': 0.85, 'kv_cache_dtype': 'turboquant_k8v4', 'enable_prefix_caching': True, 'max_num_batched_tokens': 8192, 'max_num_seqs': 2, 'enable_chunked_prefill': True, 'moe_backend': 'cutlass'}
2026-04-19 14:29:50.023 | (APIServer pid=1) WARNING 04-19 12:29:50 [envs.py:1785] Unknown vLLM environment variable detected: VLLM_ATTENTION_BACKEND
2026-04-19 14:29:50.927 | (APIServer pid=1) Warning: You are sending unauthenticated requests to the HF Hub. Please set a HF_TOKEN to enable higher rate limits and faster downloads.
2026-04-19 14:29:51.044 | (APIServer pid=1) INFO 04-19 12:29:51 [model.py:554] Resolved architecture: Gemma4ForConditionalGeneration
2026-04-19 14:29:51.044 | (APIServer pid=1) INFO 04-19 12:29:51 [model.py:1685] Using max model len 196608
2026-04-19 14:29:52.106 | (APIServer pid=1) INFO 04-19 12:29:52 [arg_utils.py:1664] TQ: skipping layers ['0', '1', '28', '29'] for boundary protection (num_layers=30)
2026-04-19 14:29:52.107 | (APIServer pid=1) INFO 04-19 12:29:52 [scheduler.py:239] Chunked prefill is enabled with max_num_batched_tokens=8192.
2026-04-19 14:29:52.107 | (APIServer pid=1) WARNING 04-19 12:29:52 [arg_utils.py:1982] TurboQuant is not yet compatible with FlashAttention >= 3. Overriding flash_attn_version to 2. To silence this warning, pass --attention-config.flash_attn_version=2
2026-04-19 14:29:52.107 | (APIServer pid=1) INFO 04-19 12:29:52 [config.py:101] Gemma4 model has heterogeneous head dimensions (head_dim=256, global_head_dim=512). Forcing TRITON_ATTN backend to prevent mixed-backend numerical divergence.
2026-04-19 14:29:52.108 | (APIServer pid=1) INFO 04-19 12:29:52 [vllm.py:834] Asynchronous scheduling is enabled.
2026-04-19 14:29:52.108 | (APIServer pid=1) INFO 04-19 12:29:52 [kernel.py:199] Final IR op priority after setting platform defaults: IrOpPriorityConfig(rms_norm=['native'])
2026-04-19 14:29:55.436 | (APIServer pid=1) INFO 04-19 12:29:55 [compilation.py:294] Enabled custom fusions: act_quant
2026-04-19 14:30:04.570 | (EngineCore pid=131) INFO 04-19 12:30:04 [core.py:107] Initializing a V1 LLM engine (v0.19.2rc1.dev8+g4b7f5ea1a) with config: model='RedHatAI/gemma-4-26B-A4B-it-NVFP4', speculative_config=None, tokenizer='RedHatAI/gemma-4-26B-A4B-it-NVFP4', skip_tokenizer_init=False, tokenizer_mode=auto, revision=None, tokenizer_revision=None, trust_remote_code=True, dtype=torch.bfloat16, max_seq_len=196608, download_dir=None, load_format=auto, tensor_parallel_size=1, pipeline_parallel_size=1, data_parallel_size=1, decode_context_parallel_size=1, dcp_comm_backend=ag_rs, disable_custom_all_reduce=False, quantization=compressed-tensors, quantization_config=None, enforce_eager=False, enable_return_routed_experts=False, kv_cache_dtype=turboquant_k8v4, device_config=cuda, structured_outputs_config=StructuredOutputsConfig(backend='auto', disable_any_whitespace=False, disable_additional_properties=False, reasoning_parser='gemma4', reasoning_parser_plugin='', enable_in_reasoning=False), observability_config=ObservabilityConfig(show_hidden_metrics_for_version=None, otlp_traces_endpoint=None, collect_detailed_traces=None, kv_cache_metrics=False, kv_cache_metrics_sample=0.01, cudagraph_metrics=False, enable_layerwise_nvtx_tracing=False, enable_mfu_metrics=False, enable_mm_processor_stats=False, enable_logging_iteration_details=False), seed=0, served_model_name=gemma-4-26b-it-nvfp4, enable_prefix_caching=True, enable_chunked_prefill=True, pooler_config=None, compilation_config={'mode': <CompilationMode.VLLM_COMPILE: 3>, 'debug_dump_path': None, 'cache_dir': '', 'compile_cache_save_format': 'binary', 'backend': 'inductor', 'custom_ops': ['none'], 'ir_enable_torch_wrap': True, 'splitting_ops': ['vllm::unified_attention_with_output', 'vllm::unified_mla_attention_with_output', 'vllm::mamba_mixer2', 'vllm::mamba_mixer', 'vllm::short_conv', 'vllm::linear_attention', 'vllm::plamo2_mamba_mixer', 'vllm::gdn_attention_core', 'vllm::olmo_hybrid_gdn_full_forward', 'vllm::kda_attention', 'vllm::sparse_attn_indexer', 'vllm::rocm_aiter_sparse_attn_indexer', 'vllm::unified_kv_cache_update', 'vllm::unified_mla_kv_cache_update'], 'compile_mm_encoder': False, 'cudagraph_mm_encoder': False, 'encoder_cudagraph_token_budgets': [], 'encoder_cudagraph_max_vision_items_per_batch': 0, 'encoder_cudagraph_max_frames_per_batch': 0, 'compile_sizes': [], 'compile_ranges_endpoints': [8192], 'inductor_compile_config': {'enable_auto_functionalized_v2': False, 'size_asserts': False, 'alignment_asserts': False, 'scalar_asserts': False, 'combo_kernels': True, 'benchmark_combo_kernel': True}, 'inductor_passes': {}, 'cudagraph_mode': <CUDAGraphMode.FULL_AND_PIECEWISE: (2, 1)>, 'cudagraph_num_of_warmups': 1, 'cudagraph_capture_sizes': [1, 2, 4], 'cudagraph_copy_inputs': False, 'cudagraph_specialize_lora': True, 'use_inductor_graph_partition': False, 'pass_config': {'fuse_norm_quant': False, 'fuse_act_quant': True, 'fuse_attn_quant': False, 'enable_sp': False, 'fuse_gemm_comms': False, 'fuse_allreduce_rms': False}, 'max_cudagraph_capture_size': 4, 'dynamic_shapes_config': {'type': <DynamicShapesType.BACKED: 'backed'>, 'evaluate_guards': False, 'assume_32_bit_indexing': False}, 'local_cache_dir': None, 'fast_moe_cold_start': False, 'static_all_moe_layers': []}, kernel_config=KernelConfig(ir_op_priority=IrOpPriorityConfig(rms_norm=['native']), enable_flashinfer_autotune=True, moe_backend='cutlass')
2026-04-19 14:30:04.699 | (EngineCore pid=131) WARNING 04-19 12:30:04 [interface.py:686] Using 'pin_memory=False' as WSL is detected. This may slow down the performance.
2026-04-19 14:30:04.987 | (EngineCore pid=131) Warning: You are sending unauthenticated requests to the HF Hub. Please set a HF_TOKEN to enable higher rate limits and faster downloads.
2026-04-19 14:30:08.344 | (EngineCore pid=131) INFO 04-19 12:30:08 [parallel_state.py:1400] world_size=1 rank=0 local_rank=0 distributed_init_method=tcp://172.18.0.2:47459 backend=nccl
2026-04-19 14:30:08.646 | (EngineCore pid=131) INFO 04-19 12:30:08 [parallel_state.py:1713] rank 0 in world size 1 is assigned as DP rank 0, PP rank 0, PCP rank 0, TP rank 0, EP rank 0, EPLB rank N/A
2026-04-19 14:30:09.154 | (EngineCore pid=131) INFO 04-19 12:30:09 [gpu_model_runner.py:4752] Starting to load model RedHatAI/gemma-4-26B-A4B-it-NVFP4...
2026-04-19 14:30:09.573 | (EngineCore pid=131) INFO 04-19 12:30:09 [vllm.py:834] Asynchronous scheduling is enabled.
2026-04-19 14:30:09.574 | (EngineCore pid=131) INFO 04-19 12:30:09 [kernel.py:199] Final IR op priority after setting platform defaults: IrOpPriorityConfig(rms_norm=['native'])
2026-04-19 14:30:09.574 | (EngineCore pid=131) INFO 04-19 12:30:09 [compilation.py:294] Enabled custom fusions: act_quant
2026-04-19 14:30:09.583 | (EngineCore pid=131) INFO 04-19 12:30:09 [__init__.py:683] Using FlashInferCutlassNvFp4LinearKernel for NVFP4 GEMM
2026-04-19 14:30:09.615 | (EngineCore pid=131) INFO 04-19 12:30:09 [attention.py:262] Layer language_model.model.layers.0.self_attn.attn: kv_cache_dtype=auto, sliding_window=1024
2026-04-19 14:30:09.616 | (EngineCore pid=131) INFO 04-19 12:30:09 [cuda.py:308] Using AttentionBackendEnum.TRITON_ATTN backend.
2026-04-19 14:30:09.625 | (EngineCore pid=131) INFO 04-19 12:30:09 [nvfp4.py:203] Using 'VLLM_CUTLASS' NvFp4 MoE backend out of potential backends: ['FLASHINFER_TRTLLM', 'FLASHINFER_CUTEDSL', 'FLASHINFER_CUTEDSL_BATCHED', 'FLASHINFER_CUTLASS', 'VLLM_CUTLASS', 'MARLIN'].
2026-04-19 14:30:09.627 | (EngineCore pid=131) INFO 04-19 12:30:09 [attention.py:262] Layer language_model.model.layers.1.self_attn.attn: kv_cache_dtype=auto, sliding_window=1024
2026-04-19 14:30:09.635 | (EngineCore pid=131) INFO 04-19 12:30:09 [attention.py:262] Layer language_model.model.layers.2.self_attn.attn: kv_cache_dtype=turboquant_k8v4, sliding_window=1024
2026-04-19 14:30:10.065 | (EngineCore pid=131) ERROR 04-19 12:30:10 [core.py:1132] EngineCore failed to start.
2026-04-19 14:30:10.065 | (EngineCore pid=131) ERROR 04-19 12:30:10 [core.py:1132] Traceback (most recent call last):
2026-04-19 14:30:10.065 | (EngineCore pid=131) ERROR 04-19 12:30:10 [core.py:1132]   File "/usr/local/lib/python3.12/dist-packages/vllm/v1/engine/core.py", line 1106, in run_engine_core
2026-04-19 14:30:10.065 | (EngineCore pid=131) ERROR 04-19 12:30:10 [core.py:1132]     engine_core = EngineCoreProc(*args, engine_index=dp_rank, **kwargs)
2026-04-19 14:30:10.065 | (EngineCore pid=131) ERROR 04-19 12:30:10 [core.py:1132]                   ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
2026-04-19 14:30:10.065 | (EngineCore pid=131) ERROR 04-19 12:30:10 [core.py:1132]   File "/usr/local/lib/python3.12/dist-packages/vllm/tracing/otel.py", line 178, in sync_wrapper
2026-04-19 14:30:10.065 | (EngineCore pid=131) ERROR 04-19 12:30:10 [core.py:1132]     return func(*args, **kwargs)
2026-04-19 14:30:10.065 | (EngineCore pid=131) ERROR 04-19 12:30:10 [core.py:1132]            ^^^^^^^^^^^^^^^^^^^^^
2026-04-19 14:30:10.065 | (EngineCore pid=131) ERROR 04-19 12:30:10 [core.py:1132]   File "/usr/local/lib/python3.12/dist-packages/vllm/v1/engine/core.py", line 872, in __init__
2026-04-19 14:30:10.065 | (EngineCore pid=131) Process EngineCore:
2026-04-19 14:30:10.065 | (EngineCore pid=131) ERROR 04-19 12:30:10 [core.py:1132]     super().__init__(
2026-04-19 14:30:10.065 | (EngineCore pid=131) ERROR 04-19 12:30:10 [core.py:1132]   File "/usr/local/lib/python3.12/dist-packages/vllm/v1/engine/core.py", line 116, in __init__
2026-04-19 14:30:10.065 | (EngineCore pid=131) ERROR 04-19 12:30:10 [core.py:1132]     self.model_executor = executor_class(vllm_config)
2026-04-19 14:30:10.065 | (EngineCore pid=131) ERROR 04-19 12:30:10 [core.py:1132]                           ^^^^^^^^^^^^^^^^^^^^^^^^^^^
2026-04-19 14:30:10.065 | (EngineCore pid=131) ERROR 04-19 12:30:10 [core.py:1132]   File "/usr/local/lib/python3.12/dist-packages/vllm/tracing/otel.py", line 178, in sync_wrapper
2026-04-19 14:30:10.065 | (EngineCore pid=131) ERROR 04-19 12:30:10 [core.py:1132]     return func(*args, **kwargs)
2026-04-19 14:30:10.065 | (EngineCore pid=131) ERROR 04-19 12:30:10 [core.py:1132]            ^^^^^^^^^^^^^^^^^^^^^
2026-04-19 14:30:10.065 | (EngineCore pid=131) ERROR 04-19 12:30:10 [core.py:1132]   File "/usr/local/lib/python3.12/dist-packages/vllm/v1/executor/abstract.py", line 109, in __init__
2026-04-19 14:30:10.065 | (EngineCore pid=131) ERROR 04-19 12:30:10 [core.py:1132]     self._init_executor()
2026-04-19 14:30:10.065 | (EngineCore pid=131) ERROR 04-19 12:30:10 [core.py:1132]   File "/usr/local/lib/python3.12/dist-packages/vllm/v1/executor/uniproc_executor.py", line 52, in _init_executor
2026-04-19 14:30:10.065 | (EngineCore pid=131) ERROR 04-19 12:30:10 [core.py:1132]     self.driver_worker.load_model()
2026-04-19 14:30:10.065 | (EngineCore pid=131) ERROR 04-19 12:30:10 [core.py:1132]   File "/usr/local/lib/python3.12/dist-packages/vllm/v1/worker/gpu_worker.py", line 323, in load_model
2026-04-19 14:30:10.065 | (EngineCore pid=131) ERROR 04-19 12:30:10 [core.py:1132]     self.model_runner.load_model(load_dummy_weights=load_dummy_weights)
2026-04-19 14:30:10.065 | (EngineCore pid=131) ERROR 04-19 12:30:10 [core.py:1132]   File "/usr/local/lib/python3.12/dist-packages/vllm/tracing/otel.py", line 178, in sync_wrapper
2026-04-19 14:30:10.065 | (EngineCore pid=131) ERROR 04-19 12:30:10 [core.py:1132]     return func(*args, **kwargs)
2026-04-19 14:30:10.065 | (EngineCore pid=131) ERROR 04-19 12:30:10 [core.py:1132]            ^^^^^^^^^^^^^^^^^^^^^
2026-04-19 14:30:10.065 | (EngineCore pid=131) ERROR 04-19 12:30:10 [core.py:1132]   File "/usr/local/lib/python3.12/dist-packages/vllm/v1/worker/gpu_model_runner.py", line 4768, in load_model
2026-04-19 14:30:10.065 | (EngineCore pid=131) ERROR 04-19 12:30:10 [core.py:1132]     self.model = model_loader.load_model(
2026-04-19 14:30:10.065 | (EngineCore pid=131) ERROR 04-19 12:30:10 [core.py:1132]                  ^^^^^^^^^^^^^^^^^^^^^^^^
2026-04-19 14:30:10.065 | (EngineCore pid=131) ERROR 04-19 12:30:10 [core.py:1132]   File "/usr/local/lib/python3.12/dist-packages/vllm/tracing/otel.py", line 178, in sync_wrapper
2026-04-19 14:30:10.065 | (EngineCore pid=131) ERROR 04-19 12:30:10 [core.py:1132]     return func(*args, **kwargs)
2026-04-19 14:30:10.065 | (EngineCore pid=131) ERROR 04-19 12:30:10 [core.py:1132]            ^^^^^^^^^^^^^^^^^^^^^
2026-04-19 14:30:10.065 | (EngineCore pid=131) ERROR 04-19 12:30:10 [core.py:1132]   File "/usr/local/lib/python3.12/dist-packages/vllm/model_executor/model_loader/base_loader.py", line 55, in load_model
2026-04-19 14:30:10.065 | (EngineCore pid=131) ERROR 04-19 12:30:10 [core.py:1132]     model = initialize_model(
2026-04-19 14:30:10.065 | (EngineCore pid=131) ERROR 04-19 12:30:10 [core.py:1132]             ^^^^^^^^^^^^^^^^^
2026-04-19 14:30:10.065 | (EngineCore pid=131) ERROR 04-19 12:30:10 [core.py:1132]   File "/usr/local/lib/python3.12/dist-packages/vllm/tracing/otel.py", line 178, in sync_wrapper
2026-04-19 14:30:10.065 | (EngineCore pid=131) ERROR 04-19 12:30:10 [core.py:1132]     return func(*args, **kwargs)
2026-04-19 14:30:10.065 | (EngineCore pid=131) ERROR 04-19 12:30:10 [core.py:1132]            ^^^^^^^^^^^^^^^^^^^^^
2026-04-19 14:30:10.065 | (EngineCore pid=131) ERROR 04-19 12:30:10 [core.py:1132]   File "/usr/local/lib/python3.12/dist-packages/vllm/model_executor/model_loader/utils.py", line 57, in initialize_model
2026-04-19 14:30:10.065 | (EngineCore pid=131) ERROR 04-19 12:30:10 [core.py:1132]     model = model_class(vllm_config=vllm_config, prefix=prefix)
2026-04-19 14:30:10.065 | (EngineCore pid=131) ERROR 04-19 12:30:10 [core.py:1132]             ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
2026-04-19 14:30:10.065 | (EngineCore pid=131) ERROR 04-19 12:30:10 [core.py:1132]   File "/usr/local/lib/python3.12/dist-packages/vllm/model_executor/models/gemma4_mm.py", line 946, in __init__
2026-04-19 14:30:10.065 | (EngineCore pid=131) ERROR 04-19 12:30:10 [core.py:1132]     self.language_model: Gemma4ForCausalLM = init_vllm_registered_model(
2026-04-19 14:30:10.065 | (EngineCore pid=131) ERROR 04-19 12:30:10 [core.py:1132]                                              ^^^^^^^^^^^^^^^^^^^^^^^^^^^
2026-04-19 14:30:10.065 | (EngineCore pid=131) ERROR 04-19 12:30:10 [core.py:1132]   File "/usr/local/lib/python3.12/dist-packages/vllm/model_executor/models/utils.py", line 379, in init_vllm_registered_model
2026-04-19 14:30:10.065 | (EngineCore pid=131) ERROR 04-19 12:30:10 [core.py:1132]     return initialize_model(vllm_config=vllm_config, prefix=prefix)
2026-04-19 14:30:10.065 | (EngineCore pid=131) ERROR 04-19 12:30:10 [core.py:1132]            ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
2026-04-19 14:30:10.065 | (EngineCore pid=131) ERROR 04-19 12:30:10 [core.py:1132]   File "/usr/local/lib/python3.12/dist-packages/vllm/tracing/otel.py", line 178, in sync_wrapper
2026-04-19 14:30:10.065 | (EngineCore pid=131) ERROR 04-19 12:30:10 [core.py:1132]     return func(*args, **kwargs)
2026-04-19 14:30:10.065 | (EngineCore pid=131) ERROR 04-19 12:30:10 [core.py:1132]            ^^^^^^^^^^^^^^^^^^^^^
2026-04-19 14:30:10.065 | (EngineCore pid=131) ERROR 04-19 12:30:10 [core.py:1132]   File "/usr/local/lib/python3.12/dist-packages/vllm/model_executor/model_loader/utils.py", line 57, in initialize_model
2026-04-19 14:30:10.065 | (EngineCore pid=131) ERROR 04-19 12:30:10 [core.py:1132]     model = model_class(vllm_config=vllm_config, prefix=prefix)
2026-04-19 14:30:10.065 | (EngineCore pid=131) ERROR 04-19 12:30:10 [core.py:1132]             ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
2026-04-19 14:30:10.065 | (EngineCore pid=131) ERROR 04-19 12:30:10 [core.py:1132]   File "/usr/local/lib/python3.12/dist-packages/vllm/model_executor/models/gemma4.py", line 1439, in __init__
2026-04-19 14:30:10.065 | (EngineCore pid=131) ERROR 04-19 12:30:10 [core.py:1132]     self.model = Gemma4Model(
2026-04-19 14:30:10.065 | (EngineCore pid=131) ERROR 04-19 12:30:10 [core.py:1132]                  ^^^^^^^^^^^^
2026-04-19 14:30:10.065 | (EngineCore pid=131) ERROR 04-19 12:30:10 [core.py:1132]   File "/usr/local/lib/python3.12/dist-packages/vllm/compilation/decorators.py", line 379, in __init__
2026-04-19 14:30:10.065 | (EngineCore pid=131) ERROR 04-19 12:30:10 [core.py:1132]     old_init(self, *args, **kwargs)
2026-04-19 14:30:10.065 | (EngineCore pid=131) ERROR 04-19 12:30:10 [core.py:1132]   File "/usr/local/lib/python3.12/dist-packages/vllm/model_executor/models/gemma4.py", line 931, in __init__
2026-04-19 14:30:10.065 | (EngineCore pid=131) ERROR 04-19 12:30:10 [core.py:1132]     self.start_layer, self.end_layer, self.layers = make_layers(
2026-04-19 14:30:10.065 | (EngineCore pid=131) ERROR 04-19 12:30:10 [core.py:1132]                                                     ^^^^^^^^^^^^
2026-04-19 14:30:10.065 | (EngineCore pid=131) ERROR 04-19 12:30:10 [core.py:1132]   File "/usr/local/lib/python3.12/dist-packages/vllm/model_executor/models/utils.py", line 646, in make_layers
2026-04-19 14:30:10.065 | (EngineCore pid=131) ERROR 04-19 12:30:10 [core.py:1132]     + get_offloader().wrap_modules(
2026-04-19 14:30:10.065 | (EngineCore pid=131) ERROR 04-19 12:30:10 [core.py:1132]       ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
2026-04-19 14:30:10.065 | (EngineCore pid=131) ERROR 04-19 12:30:10 [core.py:1132]   File "/usr/local/lib/python3.12/dist-packages/vllm/model_executor/offloader/base.py", line 104, in wrap_modules
2026-04-19 14:30:10.065 | (EngineCore pid=131) ERROR 04-19 12:30:10 [core.py:1132]     return list(modules_generator)
2026-04-19 14:30:10.065 | (EngineCore pid=131) ERROR 04-19 12:30:10 [core.py:1132]            ^^^^^^^^^^^^^^^^^^^^^^^
2026-04-19 14:30:10.065 | (EngineCore pid=131) ERROR 04-19 12:30:10 [core.py:1132]   File "/usr/local/lib/python3.12/dist-packages/vllm/model_executor/models/utils.py", line 647, in <genexpr>
2026-04-19 14:30:10.065 | (EngineCore pid=131) ERROR 04-19 12:30:10 [core.py:1132]     layer_fn(prefix=f"{prefix}.{idx}") for idx in range(start_layer, end_layer)
2026-04-19 14:30:10.065 | (EngineCore pid=131) ERROR 04-19 12:30:10 [core.py:1132]     ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
2026-04-19 14:30:10.065 | (EngineCore pid=131) ERROR 04-19 12:30:10 [core.py:1132]   File "/usr/local/lib/python3.12/dist-packages/vllm/model_executor/models/gemma4.py", line 933, in <lambda>
2026-04-19 14:30:10.065 | (EngineCore pid=131) ERROR 04-19 12:30:10 [core.py:1132]     lambda prefix: Gemma4DecoderLayer(
2026-04-19 14:30:10.065 | (EngineCore pid=131) ERROR 04-19 12:30:10 [core.py:1132]                    ^^^^^^^^^^^^^^^^^^^
2026-04-19 14:30:10.065 | (EngineCore pid=131) ERROR 04-19 12:30:10 [core.py:1132]   File "/usr/local/lib/python3.12/dist-packages/vllm/model_executor/models/gemma4.py", line 472, in __init__
2026-04-19 14:30:10.065 | (EngineCore pid=131) ERROR 04-19 12:30:10 [core.py:1132]     self.self_attn = Gemma4Attention(
2026-04-19 14:30:10.065 | (EngineCore pid=131) ERROR 04-19 12:30:10 [core.py:1132]                      ^^^^^^^^^^^^^^^^
2026-04-19 14:30:10.065 | (EngineCore pid=131) ERROR 04-19 12:30:10 [core.py:1132]   File "/usr/local/lib/python3.12/dist-packages/vllm/model_executor/models/gemma4.py", line 382, in __init__
2026-04-19 14:30:10.065 | (EngineCore pid=131) ERROR 04-19 12:30:10 [core.py:1132]     self.attn = Attention(
2026-04-19 14:30:10.065 | (EngineCore pid=131) ERROR 04-19 12:30:10 [core.py:1132]                 ^^^^^^^^^^
2026-04-19 14:30:10.065 | (EngineCore pid=131) ERROR 04-19 12:30:10 [core.py:1132]   File "/usr/local/lib/python3.12/dist-packages/vllm/model_executor/layers/attention/attention.py", line 297, in __init__
2026-04-19 14:30:10.065 | (EngineCore pid=131) ERROR 04-19 12:30:10 [core.py:1132]     self.attn_backend = get_attn_backend(
2026-04-19 14:30:10.065 | (EngineCore pid=131) ERROR 04-19 12:30:10 [core.py:1132]                         ^^^^^^^^^^^^^^^^^
2026-04-19 14:30:10.065 | (EngineCore pid=131) ERROR 04-19 12:30:10 [core.py:1132]   File "/usr/local/lib/python3.12/dist-packages/vllm/v1/attention/selector.py", line 100, in get_attn_backend
2026-04-19 14:30:10.065 | (EngineCore pid=131) ERROR 04-19 12:30:10 [core.py:1132]     return _cached_get_attn_backend(
2026-04-19 14:30:10.065 | (EngineCore pid=131) ERROR 04-19 12:30:10 [core.py:1132]            ^^^^^^^^^^^^^^^^^^^^^^^^^
2026-04-19 14:30:10.065 | (EngineCore pid=131) ERROR 04-19 12:30:10 [core.py:1132]   File "/usr/local/lib/python3.12/dist-packages/vllm/v1/attention/selector.py", line 115, in _cached_get_attn_backend
2026-04-19 14:30:10.065 | (EngineCore pid=131) ERROR 04-19 12:30:10 [core.py:1132]     attention_cls = current_platform.get_attn_backend_cls(
2026-04-19 14:30:10.065 | (EngineCore pid=131) ERROR 04-19 12:30:10 [core.py:1132]                     ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
2026-04-19 14:30:10.065 | (EngineCore pid=131) ERROR 04-19 12:30:10 [core.py:1132]   File "/usr/local/lib/python3.12/dist-packages/vllm/platforms/cuda.py", line 303, in get_attn_backend_cls
2026-04-19 14:30:10.065 | (EngineCore pid=131) ERROR 04-19 12:30:10 [core.py:1132]     raise ValueError(
2026-04-19 14:30:10.065 | (EngineCore pid=131) ERROR 04-19 12:30:10 [core.py:1132] ValueError: Selected backend AttentionBackendEnum.TRITON_ATTN is not valid for this configuration. Reason: ['kv_cache_dtype not supported']
2026-04-19 14:30:10.065 | (EngineCore pid=131) Traceback (most recent call last):
2026-04-19 14:30:10.065 | (EngineCore pid=131)   File "/usr/lib/python3.12/multiprocessing/process.py", line 314, in _bootstrap
2026-04-19 14:30:10.065 | (EngineCore pid=131)     self.run()
2026-04-19 14:30:10.066 | (EngineCore pid=131)   File "/usr/lib/python3.12/multiprocessing/process.py", line 108, in run
2026-04-19 14:30:10.066 | (EngineCore pid=131)     self._target(*self._args, **self._kwargs)
2026-04-19 14:30:10.066 | (EngineCore pid=131)   File "/usr/local/lib/python3.12/dist-packages/vllm/v1/engine/core.py", line 1136, in run_engine_core
2026-04-19 14:30:10.066 | (EngineCore pid=131)     raise e
2026-04-19 14:30:10.066 | (EngineCore pid=131)   File "/usr/local/lib/python3.12/dist-packages/vllm/v1/engine/core.py", line 1106, in run_engine_core
2026-04-19 14:30:10.066 | (EngineCore pid=131)     engine_core = EngineCoreProc(*args, engine_index=dp_rank, **kwargs)
2026-04-19 14:30:10.066 | (EngineCore pid=131)                   ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
2026-04-19 14:30:10.066 | (EngineCore pid=131)   File "/usr/local/lib/python3.12/dist-packages/vllm/tracing/otel.py", line 178, in sync_wrapper
2026-04-19 14:30:10.066 | (EngineCore pid=131)     return func(*args, **kwargs)
2026-04-19 14:30:10.066 | (EngineCore pid=131)            ^^^^^^^^^^^^^^^^^^^^^
2026-04-19 14:30:10.066 | (EngineCore pid=131)   File "/usr/local/lib/python3.12/dist-packages/vllm/v1/engine/core.py", line 872, in __init__
2026-04-19 14:30:10.066 | (EngineCore pid=131)     super().__init__(
2026-04-19 14:30:10.066 | (EngineCore pid=131)   File "/usr/local/lib/python3.12/dist-packages/vllm/v1/engine/core.py", line 116, in __init__
2026-04-19 14:30:10.066 | (EngineCore pid=131)     self.model_executor = executor_class(vllm_config)
2026-04-19 14:30:10.066 | (EngineCore pid=131)                           ^^^^^^^^^^^^^^^^^^^^^^^^^^^
2026-04-19 14:30:10.066 | (EngineCore pid=131)   File "/usr/local/lib/python3.12/dist-packages/vllm/tracing/otel.py", line 178, in sync_wrapper
2026-04-19 14:30:10.066 | (EngineCore pid=131)     return func(*args, **kwargs)
2026-04-19 14:30:10.066 | (EngineCore pid=131)            ^^^^^^^^^^^^^^^^^^^^^
2026-04-19 14:30:10.066 | (EngineCore pid=131)   File "/usr/local/lib/python3.12/dist-packages/vllm/v1/executor/abstract.py", line 109, in __init__
2026-04-19 14:30:10.066 | (EngineCore pid=131)     self._init_executor()
2026-04-19 14:30:10.066 | (EngineCore pid=131)   File "/usr/local/lib/python3.12/dist-packages/vllm/v1/executor/uniproc_executor.py", line 52, in _init_executor
2026-04-19 14:30:10.066 | (EngineCore pid=131)     self.driver_worker.load_model()
2026-04-19 14:30:10.066 | (EngineCore pid=131)   File "/usr/local/lib/python3.12/dist-packages/vllm/v1/worker/gpu_worker.py", line 323, in load_model
2026-04-19 14:30:10.066 | (EngineCore pid=131)     self.model_runner.load_model(load_dummy_weights=load_dummy_weights)
2026-04-19 14:30:10.066 | (EngineCore pid=131)   File "/usr/local/lib/python3.12/dist-packages/vllm/tracing/otel.py", line 178, in sync_wrapper
2026-04-19 14:30:10.066 | (EngineCore pid=131)     return func(*args, **kwargs)
2026-04-19 14:30:10.066 | (EngineCore pid=131)            ^^^^^^^^^^^^^^^^^^^^^
2026-04-19 14:30:10.066 | (EngineCore pid=131)   File "/usr/local/lib/python3.12/dist-packages/vllm/v1/worker/gpu_model_runner.py", line 4768, in load_model
2026-04-19 14:30:10.066 | (EngineCore pid=131)     self.model = model_loader.load_model(
2026-04-19 14:30:10.066 | (EngineCore pid=131)                  ^^^^^^^^^^^^^^^^^^^^^^^^
2026-04-19 14:30:10.066 | (EngineCore pid=131)   File "/usr/local/lib/python3.12/dist-packages/vllm/tracing/otel.py", line 178, in sync_wrapper
2026-04-19 14:30:10.066 | (EngineCore pid=131)     return func(*args, **kwargs)
2026-04-19 14:30:10.066 | (EngineCore pid=131)            ^^^^^^^^^^^^^^^^^^^^^
2026-04-19 14:30:10.066 | (EngineCore pid=131)   File "/usr/local/lib/python3.12/dist-packages/vllm/model_executor/model_loader/base_loader.py", line 55, in load_model
2026-04-19 14:30:10.066 | (EngineCore pid=131)     model = initialize_model(
2026-04-19 14:30:10.066 | (EngineCore pid=131)             ^^^^^^^^^^^^^^^^^
2026-04-19 14:30:10.066 | (EngineCore pid=131)   File "/usr/local/lib/python3.12/dist-packages/vllm/tracing/otel.py", line 178, in sync_wrapper
2026-04-19 14:30:10.066 | (EngineCore pid=131)     return func(*args, **kwargs)
2026-04-19 14:30:10.066 | (EngineCore pid=131)            ^^^^^^^^^^^^^^^^^^^^^
2026-04-19 14:30:10.066 | (EngineCore pid=131)   File "/usr/local/lib/python3.12/dist-packages/vllm/model_executor/model_loader/utils.py", line 57, in initialize_model
2026-04-19 14:30:10.066 | (EngineCore pid=131)     model = model_class(vllm_config=vllm_config, prefix=prefix)
2026-04-19 14:30:10.066 | (EngineCore pid=131)             ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
2026-04-19 14:30:10.066 | (EngineCore pid=131)   File "/usr/local/lib/python3.12/dist-packages/vllm/model_executor/models/gemma4_mm.py", line 946, in __init__
2026-04-19 14:30:10.066 | (EngineCore pid=131)     self.language_model: Gemma4ForCausalLM = init_vllm_registered_model(
2026-04-19 14:30:10.066 | (EngineCore pid=131)                                              ^^^^^^^^^^^^^^^^^^^^^^^^^^^
2026-04-19 14:30:10.066 | (EngineCore pid=131)   File "/usr/local/lib/python3.12/dist-packages/vllm/model_executor/models/utils.py", line 379, in init_vllm_registered_model
2026-04-19 14:30:10.066 | (EngineCore pid=131)     return initialize_model(vllm_config=vllm_config, prefix=prefix)
2026-04-19 14:30:10.066 | (EngineCore pid=131)            ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
2026-04-19 14:30:10.066 | (EngineCore pid=131)   File "/usr/local/lib/python3.12/dist-packages/vllm/tracing/otel.py", line 178, in sync_wrapper
2026-04-19 14:30:10.066 | (EngineCore pid=131)     return func(*args, **kwargs)
2026-04-19 14:30:10.066 | (EngineCore pid=131)            ^^^^^^^^^^^^^^^^^^^^^
2026-04-19 14:30:10.066 | (EngineCore pid=131)   File "/usr/local/lib/python3.12/dist-packages/vllm/model_executor/model_loader/utils.py", line 57, in initialize_model
2026-04-19 14:30:10.066 | (EngineCore pid=131)     model = model_class(vllm_config=vllm_config, prefix=prefix)
2026-04-19 14:30:10.066 | (EngineCore pid=131)             ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
2026-04-19 14:30:10.066 | (EngineCore pid=131)   File "/usr/local/lib/python3.12/dist-packages/vllm/model_executor/models/gemma4.py", line 1439, in __init__
2026-04-19 14:30:10.066 | (EngineCore pid=131)     self.model = Gemma4Model(
2026-04-19 14:30:10.066 | (EngineCore pid=131)                  ^^^^^^^^^^^^
2026-04-19 14:30:10.066 | (EngineCore pid=131)   File "/usr/local/lib/python3.12/dist-packages/vllm/compilation/decorators.py", line 379, in __init__
2026-04-19 14:30:10.066 | (EngineCore pid=131)     old_init(self, *args, **kwargs)
2026-04-19 14:30:10.066 | (EngineCore pid=131)   File "/usr/local/lib/python3.12/dist-packages/vllm/model_executor/models/gemma4.py", line 931, in __init__
2026-04-19 14:30:10.066 | (EngineCore pid=131)     self.start_layer, self.end_layer, self.layers = make_layers(
2026-04-19 14:30:10.066 | (EngineCore pid=131)                                                     ^^^^^^^^^^^^
2026-04-19 14:30:10.066 | (EngineCore pid=131)   File "/usr/local/lib/python3.12/dist-packages/vllm/model_executor/models/utils.py", line 646, in make_layers
2026-04-19 14:30:10.066 | (EngineCore pid=131)     + get_offloader().wrap_modules(
2026-04-19 14:30:10.066 | (EngineCore pid=131)       ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
2026-04-19 14:30:10.066 | (EngineCore pid=131)   File "/usr/local/lib/python3.12/dist-packages/vllm/model_executor/offloader/base.py", line 104, in wrap_modules
2026-04-19 14:30:10.066 | (EngineCore pid=131)     return list(modules_generator)
2026-04-19 14:30:10.066 | (EngineCore pid=131)            ^^^^^^^^^^^^^^^^^^^^^^^
2026-04-19 14:30:10.066 | (EngineCore pid=131)   File "/usr/local/lib/python3.12/dist-packages/vllm/model_executor/models/utils.py", line 647, in <genexpr>
2026-04-19 14:30:10.066 | (EngineCore pid=131)     layer_fn(prefix=f"{prefix}.{idx}") for idx in range(start_layer, end_layer)
2026-04-19 14:30:10.066 | (EngineCore pid=131)     ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
2026-04-19 14:30:10.066 | (EngineCore pid=131)   File "/usr/local/lib/python3.12/dist-packages/vllm/model_executor/models/gemma4.py", line 933, in <lambda>
2026-04-19 14:30:10.066 | (EngineCore pid=131)     lambda prefix: Gemma4DecoderLayer(
2026-04-19 14:30:10.066 | (EngineCore pid=131)                    ^^^^^^^^^^^^^^^^^^^
2026-04-19 14:30:10.066 | (EngineCore pid=131)   File "/usr/local/lib/python3.12/dist-packages/vllm/model_executor/models/gemma4.py", line 472, in __init__
2026-04-19 14:30:10.066 | (EngineCore pid=131)     self.self_attn = Gemma4Attention(
2026-04-19 14:30:10.066 | (EngineCore pid=131)                      ^^^^^^^^^^^^^^^^
2026-04-19 14:30:10.066 | (EngineCore pid=131)   File "/usr/local/lib/python3.12/dist-packages/vllm/model_executor/models/gemma4.py", line 382, in __init__
2026-04-19 14:30:10.066 | (EngineCore pid=131)     self.attn = Attention(
2026-04-19 14:30:10.066 | (EngineCore pid=131)                 ^^^^^^^^^^
2026-04-19 14:30:10.066 | (EngineCore pid=131)   File "/usr/local/lib/python3.12/dist-packages/vllm/model_executor/layers/attention/attention.py", line 297, in __init__
2026-04-19 14:30:10.066 | (EngineCore pid=131)     self.attn_backend = get_attn_backend(
2026-04-19 14:30:10.066 | (EngineCore pid=131)                         ^^^^^^^^^^^^^^^^^
2026-04-19 14:30:10.066 | (EngineCore pid=131)   File "/usr/local/lib/python3.12/dist-packages/vllm/v1/attention/selector.py", line 100, in get_attn_backend
2026-04-19 14:30:10.066 | (EngineCore pid=131)     return _cached_get_attn_backend(
2026-04-19 14:30:10.066 | (EngineCore pid=131)            ^^^^^^^^^^^^^^^^^^^^^^^^^
2026-04-19 14:30:10.066 | (EngineCore pid=131)   File "/usr/local/lib/python3.12/dist-packages/vllm/v1/attention/selector.py", line 115, in _cached_get_attn_backend
2026-04-19 14:30:10.066 | (EngineCore pid=131)     attention_cls = current_platform.get_attn_backend_cls(
2026-04-19 14:30:10.066 | (EngineCore pid=131)                     ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
2026-04-19 14:30:10.066 | (EngineCore pid=131)   File "/usr/local/lib/python3.12/dist-packages/vllm/platforms/cuda.py", line 303, in get_attn_backend_cls
2026-04-19 14:30:10.066 | (EngineCore pid=131)     raise ValueError(
2026-04-19 14:30:10.066 | (EngineCore pid=131) ValueError: Selected backend AttentionBackendEnum.TRITON_ATTN is not valid for this configuration. Reason: ['kv_cache_dtype not supported']
2026-04-19 14:30:10.629 | [rank0]:[W419 12:30:10.150720585 ProcessGroupNCCL.cpp:1575] Warning: WARNING: destroy_process_group() was not called before program exit, which can leak resources. For more info, please see https://pytorch.org/docs/stable/distributed.html#shutdown (function operator())
2026-04-19 14:30:11.388 | (APIServer pid=1) Traceback (most recent call last):
2026-04-19 14:30:11.388 | (APIServer pid=1)   File "/usr/local/bin/vllm", line 10, in <module>
2026-04-19 14:30:11.388 | (APIServer pid=1)     sys.exit(main())
2026-04-19 14:30:11.388 | (APIServer pid=1)              ^^^^^^
2026-04-19 14:30:11.388 | (APIServer pid=1)   File "/usr/local/lib/python3.12/dist-packages/vllm/entrypoints/cli/main.py", line 75, in main
2026-04-19 14:30:11.388 | (APIServer pid=1)     args.dispatch_function(args)
2026-04-19 14:30:11.388 | (APIServer pid=1)   File "/usr/local/lib/python3.12/dist-packages/vllm/entrypoints/cli/serve.py", line 122, in cmd
2026-04-19 14:30:11.388 | (APIServer pid=1)     uvloop.run(run_server(args))
2026-04-19 14:30:11.388 | (APIServer pid=1)   File "/usr/local/lib/python3.12/dist-packages/uvloop/__init__.py", line 96, in run
2026-04-19 14:30:11.388 | (APIServer pid=1)     return __asyncio.run(
2026-04-19 14:30:11.388 | (APIServer pid=1)            ^^^^^^^^^^^^^^
2026-04-19 14:30:11.388 | (APIServer pid=1)   File "/usr/lib/python3.12/asyncio/runners.py", line 195, in run
2026-04-19 14:30:11.388 | (APIServer pid=1)     return runner.run(main)
2026-04-19 14:30:11.388 | (APIServer pid=1)            ^^^^^^^^^^^^^^^^
2026-04-19 14:30:11.388 | (APIServer pid=1)   File "/usr/lib/python3.12/asyncio/runners.py", line 118, in run
2026-04-19 14:30:11.388 | (APIServer pid=1)     return self._loop.run_until_complete(task)
2026-04-19 14:30:11.388 | (APIServer pid=1)            ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
2026-04-19 14:30:11.388 | (APIServer pid=1)   File "uvloop/loop.pyx", line 1518, in uvloop.loop.Loop.run_until_complete
2026-04-19 14:30:11.389 | (APIServer pid=1)   File "/usr/local/lib/python3.12/dist-packages/uvloop/__init__.py", line 48, in wrapper
2026-04-19 14:30:11.389 | (APIServer pid=1)     return await main
2026-04-19 14:30:11.389 | (APIServer pid=1)            ^^^^^^^^^^
2026-04-19 14:30:11.389 | (APIServer pid=1)   File "/usr/local/lib/python3.12/dist-packages/vllm/entrypoints/openai/api_server.py", line 678, in run_server
2026-04-19 14:30:11.389 | (APIServer pid=1)     await run_server_worker(listen_address, sock, args, **uvicorn_kwargs)
2026-04-19 14:30:11.389 | (APIServer pid=1)   File "/usr/local/lib/python3.12/dist-packages/vllm/entrypoints/openai/api_server.py", line 692, in run_server_worker
2026-04-19 14:30:11.389 | (APIServer pid=1)     async with build_async_engine_client(
2026-04-19 14:30:11.389 | (APIServer pid=1)                ^^^^^^^^^^^^^^^^^^^^^^^^^^
2026-04-19 14:30:11.389 | (APIServer pid=1)   File "/usr/lib/python3.12/contextlib.py", line 210, in __aenter__
2026-04-19 14:30:11.389 | (APIServer pid=1)     return await anext(self.gen)
2026-04-19 14:30:11.389 | (APIServer pid=1)            ^^^^^^^^^^^^^^^^^^^^^
2026-04-19 14:30:11.389 | (APIServer pid=1)   File "/usr/local/lib/python3.12/dist-packages/vllm/entrypoints/openai/api_server.py", line 100, in build_async_engine_client
2026-04-19 14:30:11.389 | (APIServer pid=1)     async with build_async_engine_client_from_engine_args(
2026-04-19 14:30:11.389 | (APIServer pid=1)                ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
2026-04-19 14:30:11.389 | (APIServer pid=1)   File "/usr/lib/python3.12/contextlib.py", line 210, in __aenter__
2026-04-19 14:30:11.389 | (APIServer pid=1)     return await anext(self.gen)
2026-04-19 14:30:11.389 | (APIServer pid=1)            ^^^^^^^^^^^^^^^^^^^^^
2026-04-19 14:30:11.389 | (APIServer pid=1)   File "/usr/local/lib/python3.12/dist-packages/vllm/entrypoints/openai/api_server.py", line 136, in build_async_engine_client_from_engine_args
2026-04-19 14:30:11.389 | (APIServer pid=1)     async_llm = AsyncLLM.from_vllm_config(
2026-04-19 14:30:11.389 | (APIServer pid=1)                 ^^^^^^^^^^^^^^^^^^^^^^^^^^
2026-04-19 14:30:11.389 | (APIServer pid=1)   File "/usr/local/lib/python3.12/dist-packages/vllm/v1/engine/async_llm.py", line 219, in from_vllm_config
2026-04-19 14:30:11.390 | (APIServer pid=1)     return cls(
2026-04-19 14:30:11.390 | (APIServer pid=1)            ^^^^
2026-04-19 14:30:11.390 | (APIServer pid=1)   File "/usr/local/lib/python3.12/dist-packages/vllm/v1/engine/async_llm.py", line 148, in __init__
2026-04-19 14:30:11.390 | (APIServer pid=1)     self.engine_core = EngineCoreClient.make_async_mp_client(
2026-04-19 14:30:11.390 | (APIServer pid=1)                        ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
2026-04-19 14:30:11.390 | (APIServer pid=1)   File "/usr/local/lib/python3.12/dist-packages/vllm/tracing/otel.py", line 178, in sync_wrapper
2026-04-19 14:30:11.390 | (APIServer pid=1)     return func(*args, **kwargs)
2026-04-19 14:30:11.390 | (APIServer pid=1)            ^^^^^^^^^^^^^^^^^^^^^
2026-04-19 14:30:11.390 | (APIServer pid=1)   File "/usr/local/lib/python3.12/dist-packages/vllm/v1/engine/core_client.py", line 130, in make_async_mp_client
2026-04-19 14:30:11.390 | (APIServer pid=1)     return AsyncMPClient(*client_args)
2026-04-19 14:30:11.390 | (APIServer pid=1)            ^^^^^^^^^^^^^^^^^^^^^^^^^^^
2026-04-19 14:30:11.390 | (APIServer pid=1)   File "/usr/local/lib/python3.12/dist-packages/vllm/tracing/otel.py", line 178, in sync_wrapper
2026-04-19 14:30:11.390 | (APIServer pid=1)     return func(*args, **kwargs)
2026-04-19 14:30:11.390 | (APIServer pid=1)            ^^^^^^^^^^^^^^^^^^^^^
2026-04-19 14:30:11.390 | (APIServer pid=1)   File "/usr/local/lib/python3.12/dist-packages/vllm/v1/engine/core_client.py", line 900, in __init__
2026-04-19 14:30:11.390 | (APIServer pid=1)     super().__init__(
2026-04-19 14:30:11.390 | (APIServer pid=1)   File "/usr/local/lib/python3.12/dist-packages/vllm/v1/engine/core_client.py", line 535, in __init__
2026-04-19 14:30:11.390 | (APIServer pid=1)     with launch_core_engines(
2026-04-19 14:30:11.390 | (APIServer pid=1)          ^^^^^^^^^^^^^^^^^^^^
2026-04-19 14:30:11.390 | (APIServer pid=1)   File "/usr/lib/python3.12/contextlib.py", line 144, in __exit__
2026-04-19 14:30:11.390 | (APIServer pid=1)     next(self.gen)
2026-04-19 14:30:11.390 | (APIServer pid=1)   File "/usr/local/lib/python3.12/dist-packages/vllm/v1/engine/utils.py", line 1094, in launch_core_engines
2026-04-19 14:30:11.391 | (APIServer pid=1)     wait_for_engine_startup(
2026-04-19 14:30:11.391 | (APIServer pid=1)   File "/usr/local/lib/python3.12/dist-packages/vllm/v1/engine/utils.py", line 1153, in wait_for_engine_startup
2026-04-19 14:30:11.391 | (APIServer pid=1)     raise RuntimeError(
2026-04-19 14:30:11.391 | (APIServer pid=1) RuntimeError: Engine core initialization failed. See root cause above. Failed core proc(s): {}
2026-04-19 14:30:19.399 | WARNING 04-19 12:30:19 [interface.py:686] Using 'pin_memory=False' as WSL is detected. This may slow down the performance.
2026-04-19 14:30:19.449 | (APIServer pid=1) INFO 04-19 12:30:19 [utils.py:299] 
2026-04-19 14:30:19.449 | (APIServer pid=1) INFO 04-19 12:30:19 [utils.py:299]        █     █     █▄   ▄█
2026-04-19 14:30:19.449 | (APIServer pid=1) INFO 04-19 12:30:19 [utils.py:299]  ▄▄ ▄█ █     █     █ ▀▄▀ █  version 0.19.2rc1.dev8+g4b7f5ea1a
2026-04-19 14:30:19.449 | (APIServer pid=1) INFO 04-19 12:30:19 [utils.py:299]   █▄█▀ █     █     █     █  model   RedHatAI/gemma-4-26B-A4B-it-NVFP4
2026-04-19 14:30:19.449 | (APIServer pid=1) INFO 04-19 12:30:19 [utils.py:299]    ▀▀  ▀▀▀▀▀ ▀▀▀▀▀ ▀     ▀
2026-04-19 14:30:19.449 | (APIServer pid=1) INFO 04-19 12:30:19 [utils.py:299] 
2026-04-19 14:30:19.451 | (APIServer pid=1) INFO 04-19 12:30:19 [utils.py:233] non-default args: {'model_tag': 'RedHatAI/gemma-4-26B-A4B-it-NVFP4', 'tool_call_parser': 'gemma4', 'host': '0.0.0.0', 'model': 'RedHatAI/gemma-4-26B-A4B-it-NVFP4', 'trust_remote_code': True, 'max_model_len': 196608, 'quantization': 'compressed-tensors', 'served_model_name': ['gemma-4-26b-it-nvfp4'], 'reasoning_parser': 'gemma4', 'gpu_memory_utilization': 0.85, 'kv_cache_dtype': 'turboquant_k8v4', 'enable_prefix_caching': True, 'max_num_batched_tokens': 8192, 'max_num_seqs': 2, 'enable_chunked_prefill': True, 'moe_backend': 'cutlass'}
2026-04-19 14:30:19.452 | (APIServer pid=1) WARNING 04-19 12:30:19 [envs.py:1785] Unknown vLLM environment variable detected: VLLM_ATTENTION_BACKEND
2026-04-19 14:30:19.843 | (APIServer pid=1) Warning: You are sending unauthenticated requests to the HF Hub. Please set a HF_TOKEN to enable higher rate limits and faster downloads.
2026-04-19 14:30:20.461 | (APIServer pid=1) INFO 04-19 12:30:20 [model.py:554] Resolved architecture: Gemma4ForConditionalGeneration
2026-04-19 14:30:20.462 | (APIServer pid=1) INFO 04-19 12:30:20 [model.py:1685] Using max model len 196608
2026-04-19 14:30:21.515 | (APIServer pid=1) INFO 04-19 12:30:21 [arg_utils.py:1664] TQ: skipping layers ['0', '1', '28', '29'] for boundary protection (num_layers=30)
2026-04-19 14:30:21.516 | (APIServer pid=1) INFO 04-19 12:30:21 [scheduler.py:239] Chunked prefill is enabled with max_num_batched_tokens=8192.
2026-04-19 14:30:21.516 | (APIServer pid=1) WARNING 04-19 12:30:21 [arg_utils.py:1982] TurboQuant is not yet compatible with FlashAttention >= 3. Overriding flash_attn_version to 2. To silence this warning, pass --attention-config.flash_attn_version=2
2026-04-19 14:30:21.516 | (APIServer pid=1) INFO 04-19 12:30:21 [config.py:101] Gemma4 model has heterogeneous head dimensions (head_dim=256, global_head_dim=512). Forcing TRITON_ATTN backend to prevent mixed-backend numerical divergence.
2026-04-19 14:30:21.516 | (APIServer pid=1) INFO 04-19 12:30:21 [vllm.py:834] Asynchronous scheduling is enabled.
2026-04-19 14:30:21.517 | (APIServer pid=1) INFO 04-19 12:30:21 [kernel.py:199] Final IR op priority after setting platform defaults: IrOpPriorityConfig(rms_norm=['native'])
2026-04-19 14:30:24.836 | (APIServer pid=1) INFO 04-19 12:30:24 [compilation.py:294] Enabled custom fusions: act_quant
2026-04-19 14:30:28.634 | (APIServer pid=1) Traceback (most recent call last):
2026-04-19 14:30:28.634 | (APIServer pid=1)   File "/usr/local/bin/vllm", line 10, in <module>
2026-04-19 14:30:28.634 | (APIServer pid=1)     sys.exit(main())
2026-04-19 14:30:28.634 | (APIServer pid=1)              ^^^^^^
2026-04-19 14:30:28.634 | (APIServer pid=1)   File "/usr/local/lib/python3.12/dist-packages/vllm/entrypoints/cli/main.py", line 75, in main
2026-04-19 14:30:28.634 | (APIServer pid=1)     args.dispatch_function(args)
2026-04-19 14:30:28.634 | (APIServer pid=1)   File "/usr/local/lib/python3.12/dist-packages/vllm/entrypoints/cli/serve.py", line 122, in cmd
2026-04-19 14:30:28.635 | (APIServer pid=1)     uvloop.run(run_server(args))
2026-04-19 14:30:28.635 | (APIServer pid=1)   File "/usr/local/lib/python3.12/dist-packages/uvloop/__init__.py", line 96, in run
2026-04-19 14:30:28.635 | (APIServer pid=1)     return __asyncio.run(
2026-04-19 14:30:28.635 | (APIServer pid=1)            ^^^^^^^^^^^^^^
2026-04-19 14:30:28.635 | (APIServer pid=1)   File "/usr/lib/python3.12/asyncio/runners.py", line 195, in run
2026-04-19 14:30:28.635 | (APIServer pid=1)     return runner.run(main)
2026-04-19 14:30:28.635 | (APIServer pid=1)            ^^^^^^^^^^^^^^^^
2026-04-19 14:30:28.635 | (APIServer pid=1)   File "/usr/lib/python3.12/asyncio/runners.py", line 118, in run
2026-04-19 14:30:28.635 | (APIServer pid=1)     return self._loop.run_until_complete(task)
2026-04-19 14:30:28.635 | (APIServer pid=1)            ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
2026-04-19 14:30:28.635 | (APIServer pid=1)   File "uvloop/loop.pyx", line 1512, in uvloop.loop.Loop.run_until_complete
2026-04-19 14:30:28.635 | (APIServer pid=1)   File "uvloop/loop.pyx", line 1505, in uvloop.loop.Loop.run_until_complete
2026-04-19 14:30:28.635 | (APIServer pid=1)   File "uvloop/loop.pyx", line 1379, in uvloop.loop.Loop.run_forever
2026-04-19 14:30:28.635 | (APIServer pid=1)   File "uvloop/loop.pyx", line 557, in uvloop.loop.Loop._run
2026-04-19 14:30:28.635 | (APIServer pid=1)   File "uvloop/loop.pyx", line 476, in uvloop.loop.Loop._on_idle
2026-04-19 14:30:28.635 | (APIServer pid=1)   File "uvloop/cbhandles.pyx", line 83, in uvloop.loop.Handle._run
2026-04-19 14:30:28.635 | (APIServer pid=1)   File "uvloop/cbhandles.pyx", line 61, in uvloop.loop.Handle._run
2026-04-19 14:30:28.635 | (APIServer pid=1)   File "/usr/local/lib/python3.12/dist-packages/uvloop/__init__.py", line 48, in wrapper
2026-04-19 14:30:28.635 | (APIServer pid=1)     return await main
2026-04-19 14:30:28.635 | (APIServer pid=1)            ^^^^^^^^^^
2026-04-19 14:30:28.635 | (APIServer pid=1)   File "/usr/local/lib/python3.12/dist-packages/vllm/entrypoints/openai/api_server.py", line 678, in run_server
2026-04-19 14:30:28.635 | (APIServer pid=1)     await run_server_worker(listen_address, sock, args, **uvicorn_kwargs)
2026-04-19 14:30:28.636 | (APIServer pid=1)   File "/usr/local/lib/python3.12/dist-packages/vllm/entrypoints/openai/api_server.py", line 692, in run_server_worker
2026-04-19 14:30:28.636 | (APIServer pid=1)     async with build_async_engine_client(
2026-04-19 14:30:28.636 | (APIServer pid=1)                ^^^^^^^^^^^^^^^^^^^^^^^^^^
2026-04-19 14:30:28.636 | (APIServer pid=1)   File "/usr/lib/python3.12/contextlib.py", line 210, in __aenter__
2026-04-19 14:30:28.636 | (APIServer pid=1)     return await anext(self.gen)
2026-04-19 14:30:28.636 | (APIServer pid=1)            ^^^^^^^^^^^^^^^^^^^^^
2026-04-19 14:30:28.636 | (APIServer pid=1)   File "/usr/local/lib/python3.12/dist-packages/vllm/entrypoints/openai/api_server.py", line 100, in build_async_engine_client
2026-04-19 14:30:28.636 | (APIServer pid=1)     async with build_async_engine_client_from_engine_args(
2026-04-19 14:30:28.636 | (APIServer pid=1)                ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
2026-04-19 14:30:28.636 | (APIServer pid=1)   File "/usr/lib/python3.12/contextlib.py", line 210, in __aenter__
2026-04-19 14:30:28.636 | (APIServer pid=1)     return await anext(self.gen)
2026-04-19 14:30:28.636 | (APIServer pid=1)            ^^^^^^^^^^^^^^^^^^^^^
2026-04-19 14:30:28.636 | (APIServer pid=1)   File "/usr/local/lib/python3.12/dist-packages/vllm/entrypoints/openai/api_server.py", line 136, in build_async_engine_client_from_engine_args
2026-04-19 14:30:28.636 | (APIServer pid=1)     async_llm = AsyncLLM.from_vllm_config(
2026-04-19 14:30:28.636 | (APIServer pid=1)                 ^^^^^^^^^^^^^^^^^^^^^^^^^^
2026-04-19 14:30:28.636 | (APIServer pid=1)   File "/usr/local/lib/python3.12/dist-packages/vllm/v1/engine/async_llm.py", line 219, in from_vllm_config
2026-04-19 14:30:28.636 | (APIServer pid=1)     return cls(
2026-04-19 14:30:28.636 | (APIServer pid=1)            ^^^^
2026-04-19 14:30:28.636 | (APIServer pid=1)   File "/usr/local/lib/python3.12/dist-packages/vllm/v1/engine/async_llm.py", line 134, in __init__
2026-04-19 14:30:28.636 | (APIServer pid=1)     self.renderer = renderer = renderer_from_config(self.vllm_config)
2026-04-19 14:30:28.636 | (APIServer pid=1)                                ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
2026-04-19 14:30:28.636 | (APIServer pid=1)   File "/usr/local/lib/python3.12/dist-packages/vllm/renderers/registry.py", line 86, in renderer_from_config
2026-04-19 14:30:28.637 | (APIServer pid=1)     return RENDERER_REGISTRY.load_renderer(renderer_mode, config, tokenizer)
2026-04-19 14:30:28.637 | (APIServer pid=1)            ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
2026-04-19 14:30:28.637 | (APIServer pid=1)   File "/usr/local/lib/python3.12/dist-packages/vllm/renderers/registry.py", line 68, in load_renderer
2026-04-19 14:30:28.637 | (APIServer pid=1)     return renderer_cls(config, tokenizer)
2026-04-19 14:30:28.637 | (APIServer pid=1)            ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
2026-04-19 14:30:28.637 | (APIServer pid=1)   File "/usr/local/lib/python3.12/dist-packages/vllm/renderers/hf.py", line 612, in __init__
2026-04-19 14:30:28.637 | (APIServer pid=1)     super().__init__(config, tokenizer)
2026-04-19 14:30:28.637 | (APIServer pid=1)   File "/usr/local/lib/python3.12/dist-packages/vllm/renderers/base.py", line 133, in __init__
2026-04-19 14:30:28.637 | (APIServer pid=1)     ro_tokenizer = copy.deepcopy(tokenizer)
2026-04-19 14:30:28.637 | (APIServer pid=1)                    ^^^^^^^^^^^^^^^^^^^^^^^^
2026-04-19 14:30:28.637 | (APIServer pid=1)   File "/usr/lib/python3.12/copy.py", line 162, in deepcopy
2026-04-19 14:30:28.637 | (APIServer pid=1)     y = _reconstruct(x, memo, *rv)
2026-04-19 14:30:28.637 | (APIServer pid=1)         ^^^^^^^^^^^^^^^^^^^^^^^^^^
2026-04-19 14:30:28.637 | (APIServer pid=1)   File "/usr/lib/python3.12/copy.py", line 253, in _reconstruct
2026-04-19 14:30:28.637 | (APIServer pid=1)     y = func(*args)
2026-04-19 14:30:28.637 | (APIServer pid=1)         ^^^^^^^^^^^
2026-04-19 14:30:28.637 | (APIServer pid=1)   File "/usr/local/lib/python3.12/dist-packages/vllm/tokenizers/hf.py", line 28, in get_cached_tokenizer
2026-04-19 14:30:28.638 | (APIServer pid=1)     tokenizer_len = len(tokenizer)
2026-04-19 14:30:28.638 | (APIServer pid=1)                     ^^^^^^^^^^^^^^
2026-04-19 14:30:28.638 | (APIServer pid=1)   File "/usr/local/lib/python3.12/dist-packages/transformers/tokenization_utils_tokenizers.py", line 654, in __len__
2026-04-19 14:30:28.638 | (APIServer pid=1)     return self._tokenizer.get_vocab_size(with_added_tokens=True)
2026-04-19 14:30:28.638 | (APIServer pid=1)            ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
2026-04-19 14:30:28.638 | (APIServer pid=1)   File "/usr/local/lib/python3.12/dist-packages/vllm/entrypoints/openai/api_server.py", line 564, in signal_handler
2026-04-19 14:30:28.638 | (APIServer pid=1)     raise KeyboardInterrupt("terminated")
2026-04-19 14:30:28.638 | (APIServer pid=1) KeyboardInterrupt: terminated
