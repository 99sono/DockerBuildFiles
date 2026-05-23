# docker compose
```yml
version: "3.9"

services:
  qwen3-6-moe-nvfp4:
    # 1. FIX: Swapped to the exact image build we know works for your stack
    image: vllm/vllm-openai:v0.20.0-cu130-ubuntu2404
    container_name: qwen3-6-moe-35b-a3b-nvfp4
    hostname: qwen3-6-moe-35b-a3b-nvfp4
    platform: linux/amd64
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
      # 2. FIX: Disable FlashInfer Autotuning to prevent WSL2 driver TDR resets
      FLASHINFER_AUTOTUNE: "0"
      VLLM_FLASHINFER_CHECK_SAFE_OPS: "0"
      VLLM_NO_USAGE_STATS: "1"
      VLLM_WORKER_MULTIPROC_METHOD: spawn
      PYTORCH_CUDA_ALLOC_CONF: "expandable_segments:True"
      HF_HUB_ENABLE_HF_TRANSFER: "1"

    command:
      - "--model"
      - "RedHatAI/Qwen3.6-35B-A3B-NVFP4"
      - "--served-model-name"
      - "RedHatAI/Qwen3.6-35B-A3B-NVFP4"
      - "--host"
      - "0.0.0.0"
      - "--port"
      - "8000"
      
      # 3. FIX: Conservative VRAM budget to leave room for Windows DWM
      - "--gpu-memory-utilization"
      - "0.80"
      - "--max-model-len"
      - "8192"
      
      - "--kv-cache-dtype"
      - "fp8_e4m3"
      - "--quantization"
      - "compressed-tensors"
      - "--reasoning-parser"
      - "qwen3"
      - "--tool-call-parser"
      - "qwen3_coder"
      
      # 4. FIX: Swap to the Triton backend to avoid the Cutlass/TMA hardware crash
      - "--moe-backend"
      - "triton"
      
      - "--enable-prefix-caching"
      - "--enable-chunked-prefill"
      - "--max-num-seqs"
      - "32"
      - "--max-num-batched-tokens"
      - "8192"
      - "--trust-remote-code"

      # 5. FIX: CRITICAL - Disable CUDA Graph capture
      - "--enforce-eager"

    networks:
      - development-network

networks:
  development-network:
    external: true
```
    
# vllm crash log

2026-05-01 20:48:41.997 | WARNING 05-01 18:48:41 [interface.py:686] Using 'pin_memory=False' as WSL is detected. This may slow down the performance.
2026-05-01 20:48:42.103 | WARNING 05-01 18:48:42 [argparse_utils.py:257] With `vllm serve`, you should provide the model as a positional argument or in a config file instead of via the `--model` option. The `--model` option will be removed in a future version.
2026-05-01 20:48:42.107 | (APIServer pid=1) INFO 05-01 18:48:42 [utils.py:299] 
2026-05-01 20:48:42.107 | (APIServer pid=1) INFO 05-01 18:48:42 [utils.py:299]        █     █     █▄   ▄█
2026-05-01 20:48:42.107 | (APIServer pid=1) INFO 05-01 18:48:42 [utils.py:299]  ▄▄ ▄█ █     █     █ ▀▄▀ █  version 0.20.0
2026-05-01 20:48:42.107 | (APIServer pid=1) INFO 05-01 18:48:42 [utils.py:299]   █▄█▀ █     █     █     █  model   RedHatAI/Qwen3.6-35B-A3B-NVFP4
2026-05-01 20:48:42.107 | (APIServer pid=1) INFO 05-01 18:48:42 [utils.py:299]    ▀▀  ▀▀▀▀▀ ▀▀▀▀▀ ▀     ▀
2026-05-01 20:48:42.107 | (APIServer pid=1) INFO 05-01 18:48:42 [utils.py:299] 
2026-05-01 20:48:42.110 | (APIServer pid=1) INFO 05-01 18:48:42 [utils.py:233] non-default args: {'model_tag': 'RedHatAI/Qwen3.6-35B-A3B-NVFP4', 'tool_call_parser': 'qwen3_coder', 'host': '0.0.0.0', 'model': 'RedHatAI/Qwen3.6-35B-A3B-NVFP4', 'trust_remote_code': True, 'max_model_len': 8192, 'quantization': 'compressed-tensors', 'enforce_eager': True, 'served_model_name': ['RedHatAI/Qwen3.6-35B-A3B-NVFP4'], 'reasoning_parser': 'qwen3', 'gpu_memory_utilization': 0.8, 'kv_cache_dtype': 'fp8_e4m3', 'enable_prefix_caching': True, 'max_num_batched_tokens': 8192, 'max_num_seqs': 32, 'enable_chunked_prefill': True, 'moe_backend': 'triton'}
2026-05-01 20:48:42.112 | (APIServer pid=1) WARNING 05-01 18:48:42 [envs.py:1818] Unknown vLLM environment variable detected: VLLM_FLASHINFER_CHECK_SAFE_OPS
2026-05-01 20:48:42.542 | (APIServer pid=1) Warning: You are sending unauthenticated requests to the HF Hub. Please set a HF_TOKEN to enable higher rate limits and faster downloads.
2026-05-01 20:48:53.797 | (APIServer pid=1) INFO 05-01 18:48:53 [nixl_utils.py:20] Setting UCX_RCACHE_MAX_UNRELEASED to '1024' to avoid a rare memory leak in UCX when using NIXL.
2026-05-01 20:48:53.828 | (APIServer pid=1) INFO 05-01 18:48:53 [nixl_utils.py:32] NIXL is available
2026-05-01 20:48:54.029 | (APIServer pid=1) INFO 05-01 18:48:54 [model.py:555] Resolved architecture: Qwen3_5MoeForConditionalGeneration
2026-05-01 20:48:54.029 | (APIServer pid=1) INFO 05-01 18:48:54 [model.py:1680] Using max model len 8192
2026-05-01 20:48:54.457 | (APIServer pid=1) INFO 05-01 18:48:54 [cache.py:261] Using fp8_e4m3 data type to store kv cache. It reduces the GPU memory footprint and boosts the performance. Meanwhile, it may cause accuracy drop without a proper scaling factor
2026-05-01 20:48:54.458 | (APIServer pid=1) INFO 05-01 18:48:54 [scheduler.py:239] Chunked prefill is enabled with max_num_batched_tokens=8192.
2026-05-01 20:48:54.458 | (APIServer pid=1) WARNING 05-01 18:48:54 [config.py:367] Mamba cache mode is set to 'align' for Qwen3_5MoeForConditionalGeneration by default when prefix caching is enabled
2026-05-01 20:48:54.458 | (APIServer pid=1) INFO 05-01 18:48:54 [config.py:387] Warning: Prefix caching in Mamba cache 'align' mode is currently enabled. Its support for Mamba layers is experimental. Please report any issues you may observe.
2026-05-01 20:48:54.459 | (APIServer pid=1) INFO 05-01 18:48:54 [vllm.py:840] Asynchronous scheduling is enabled.
2026-05-01 20:48:54.459 | (APIServer pid=1) WARNING 05-01 18:48:54 [vllm.py:896] Enforce eager set, disabling torch.compile and CUDAGraphs. This is equivalent to setting -cc.mode=none -cc.cudagraph_mode=none
2026-05-01 20:48:54.459 | (APIServer pid=1) WARNING 05-01 18:48:54 [vllm.py:914] Inductor compilation was disabled by user settings, optimizations settings that are only active during inductor compilation will be ignored.
2026-05-01 20:48:54.459 | (APIServer pid=1) INFO 05-01 18:48:54 [kernel.py:205] Final IR op priority after setting platform defaults: IrOpPriorityConfig(rms_norm=['vllm_c', 'native'])
2026-05-01 20:48:54.459 | (APIServer pid=1) INFO 05-01 18:48:54 [vllm.py:1089] Cudagraph is disabled under eager mode
2026-05-01 20:48:59.342 | (APIServer pid=1) INFO 05-01 18:48:59 [compilation.py:303] Enabled custom fusions: norm_quant, act_quant
2026-05-01 20:48:59.530 | (APIServer pid=1) [transformers] `Qwen2VLImageProcessorFast` is deprecated. The `Fast` suffix for image processors has been removed; use `Qwen2VLImageProcessor` instead.
2026-05-01 20:49:07.968 | (APIServer pid=1) [transformers] The `use_fast` parameter is deprecated and will be removed in a future version. Use `backend="torchvision"` instead of `use_fast=True`, or `backend="pil"` instead of `use_fast=False`.
2026-05-01 20:49:18.964 | INFO 05-01 18:49:18 [nixl_utils.py:32] NIXL is available
2026-05-01 20:49:19.034 | (EngineCore pid=228) INFO 05-01 18:49:19 [core.py:109] Initializing a V1 LLM engine (v0.20.0) with config: model='RedHatAI/Qwen3.6-35B-A3B-NVFP4', speculative_config=None, tokenizer='RedHatAI/Qwen3.6-35B-A3B-NVFP4', skip_tokenizer_init=False, tokenizer_mode=auto, revision=None, tokenizer_revision=None, trust_remote_code=True, dtype=torch.bfloat16, max_seq_len=8192, download_dir=None, load_format=auto, tensor_parallel_size=1, pipeline_parallel_size=1, data_parallel_size=1, decode_context_parallel_size=1, dcp_comm_backend=ag_rs, disable_custom_all_reduce=False, quantization=compressed-tensors, quantization_config=None, enforce_eager=True, enable_return_routed_experts=False, kv_cache_dtype=fp8_e4m3, device_config=cuda, structured_outputs_config=StructuredOutputsConfig(backend='auto', disable_any_whitespace=False, disable_additional_properties=False, reasoning_parser='qwen3', reasoning_parser_plugin='', enable_in_reasoning=False), observability_config=ObservabilityConfig(show_hidden_metrics_for_version=None, otlp_traces_endpoint=None, collect_detailed_traces=None, kv_cache_metrics=False, kv_cache_metrics_sample=0.01, cudagraph_metrics=False, enable_layerwise_nvtx_tracing=False, enable_mfu_metrics=False, enable_mm_processor_stats=False, enable_logging_iteration_details=False), seed=0, served_model_name=RedHatAI/Qwen3.6-35B-A3B-NVFP4, enable_prefix_caching=True, enable_chunked_prefill=True, pooler_config=None, compilation_config={'mode': <CompilationMode.NONE: 0>, 'debug_dump_path': None, 'cache_dir': '', 'compile_cache_save_format': 'binary', 'backend': 'inductor', 'custom_ops': ['all'], 'ir_enable_torch_wrap': False, 'splitting_ops': [], 'compile_mm_encoder': False, 'cudagraph_mm_encoder': False, 'encoder_cudagraph_token_budgets': [], 'encoder_cudagraph_max_vision_items_per_batch': 0, 'encoder_cudagraph_max_frames_per_batch': None, 'compile_sizes': [], 'compile_ranges_endpoints': [8192], 'inductor_compile_config': {'enable_auto_functionalized_v2': False, 'size_asserts': False, 'alignment_asserts': False, 'scalar_asserts': False, 'combo_kernels': True, 'benchmark_combo_kernel': True}, 'inductor_passes': {}, 'cudagraph_mode': <CUDAGraphMode.NONE: 0>, 'cudagraph_num_of_warmups': 0, 'cudagraph_capture_sizes': [], 'cudagraph_copy_inputs': False, 'cudagraph_specialize_lora': True, 'use_inductor_graph_partition': False, 'pass_config': {'fuse_norm_quant': True, 'fuse_act_quant': True, 'fuse_attn_quant': False, 'enable_sp': False, 'fuse_gemm_comms': False, 'fuse_allreduce_rms': False}, 'max_cudagraph_capture_size': 0, 'dynamic_shapes_config': {'type': <DynamicShapesType.BACKED: 'backed'>, 'evaluate_guards': False, 'assume_32_bit_indexing': False}, 'local_cache_dir': None, 'fast_moe_cold_start': False, 'static_all_moe_layers': []}, kernel_config=KernelConfig(ir_op_priority=IrOpPriorityConfig(rms_norm=['vllm_c', 'native']), enable_flashinfer_autotune=True, moe_backend='triton')
2026-05-01 20:49:19.207 | (EngineCore pid=228) WARNING 05-01 18:49:19 [interface.py:686] Using 'pin_memory=False' as WSL is detected. This may slow down the performance.
2026-05-01 20:49:19.330 | (EngineCore pid=228) [transformers] `Qwen2VLImageProcessorFast` is deprecated. The `Fast` suffix for image processors has been removed; use `Qwen2VLImageProcessor` instead.
2026-05-01 20:49:19.750 | (EngineCore pid=228) Warning: You are sending unauthenticated requests to the HF Hub. Please set a HF_TOKEN to enable higher rate limits and faster downloads.
2026-05-01 20:49:22.388 | (EngineCore pid=228) INFO 05-01 18:49:22 [parallel_state.py:1402] world_size=1 rank=0 local_rank=0 distributed_init_method=tcp://172.18.0.2:36865 backend=nccl
2026-05-01 20:49:22.685 | (EngineCore pid=228) INFO 05-01 18:49:22 [parallel_state.py:1715] rank 0 in world size 1 is assigned as DP rank 0, PP rank 0, PCP rank 0, TP rank 0, EP rank 0, EPLB rank N/A
2026-05-01 20:49:29.214 | (EngineCore pid=228) [transformers] The `use_fast` parameter is deprecated and will be removed in a future version. Use `backend="torchvision"` instead of `use_fast=True`, or `backend="pil"` instead of `use_fast=False`.
2026-05-01 20:49:34.721 | (EngineCore pid=228) INFO 05-01 18:49:34 [gpu_model_runner.py:4777] Starting to load model RedHatAI/Qwen3.6-35B-A3B-NVFP4...
2026-05-01 20:49:35.115 | (EngineCore pid=228) INFO 05-01 18:49:35 [cuda.py:423] Using backend AttentionBackendEnum.FLASH_ATTN for vit attention
2026-05-01 20:49:35.116 | (EngineCore pid=228) INFO 05-01 18:49:35 [mm_encoder_attention.py:230] Using AttentionBackendEnum.FLASH_ATTN for MMEncoderAttention.
2026-05-01 20:49:35.197 | (EngineCore pid=228) INFO 05-01 18:49:35 [gdn_linear_attn.py:153] Using Triton/FLA GDN prefill kernel
2026-05-01 20:49:35.198 | (EngineCore pid=228) INFO 05-01 18:49:35 [__init__.py:683] Using FlashInferCutlassNvFp4LinearKernel for NVFP4 GEMM
2026-05-01 20:49:35.616 | (EngineCore pid=228) ERROR 05-01 18:49:35 [core.py:1136] EngineCore failed to start.
2026-05-01 20:49:35.616 | (EngineCore pid=228) ERROR 05-01 18:49:35 [core.py:1136] Traceback (most recent call last):
2026-05-01 20:49:35.616 | (EngineCore pid=228) ERROR 05-01 18:49:35 [core.py:1136]   File "/usr/local/lib/python3.12/dist-packages/vllm/v1/engine/core.py", line 1110, in run_engine_core
2026-05-01 20:49:35.616 | (EngineCore pid=228) ERROR 05-01 18:49:35 [core.py:1136]     engine_core = EngineCoreProc(*args, engine_index=dp_rank, **kwargs)
2026-05-01 20:49:35.616 | (EngineCore pid=228) ERROR 05-01 18:49:35 [core.py:1136]                   ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
2026-05-01 20:49:35.616 | (EngineCore pid=228) Process EngineCore:
2026-05-01 20:49:35.616 | (EngineCore pid=228) ERROR 05-01 18:49:35 [core.py:1136]   File "/usr/local/lib/python3.12/dist-packages/vllm/tracing/otel.py", line 178, in sync_wrapper
2026-05-01 20:49:35.616 | (EngineCore pid=228) ERROR 05-01 18:49:35 [core.py:1136]     return func(*args, **kwargs)
2026-05-01 20:49:35.616 | (EngineCore pid=228) ERROR 05-01 18:49:35 [core.py:1136]            ^^^^^^^^^^^^^^^^^^^^^
2026-05-01 20:49:35.616 | (EngineCore pid=228) ERROR 05-01 18:49:35 [core.py:1136]   File "/usr/local/lib/python3.12/dist-packages/vllm/v1/engine/core.py", line 876, in __init__
2026-05-01 20:49:35.616 | (EngineCore pid=228) ERROR 05-01 18:49:35 [core.py:1136]     super().__init__(
2026-05-01 20:49:35.616 | (EngineCore pid=228) ERROR 05-01 18:49:35 [core.py:1136]   File "/usr/local/lib/python3.12/dist-packages/vllm/v1/engine/core.py", line 118, in __init__
2026-05-01 20:49:35.616 | (EngineCore pid=228) ERROR 05-01 18:49:35 [core.py:1136]     self.model_executor = executor_class(vllm_config)
2026-05-01 20:49:35.616 | (EngineCore pid=228) ERROR 05-01 18:49:35 [core.py:1136]                           ^^^^^^^^^^^^^^^^^^^^^^^^^^^
2026-05-01 20:49:35.616 | (EngineCore pid=228) ERROR 05-01 18:49:35 [core.py:1136]   File "/usr/local/lib/python3.12/dist-packages/vllm/tracing/otel.py", line 178, in sync_wrapper
2026-05-01 20:49:35.616 | (EngineCore pid=228) ERROR 05-01 18:49:35 [core.py:1136]     return func(*args, **kwargs)
2026-05-01 20:49:35.616 | (EngineCore pid=228) ERROR 05-01 18:49:35 [core.py:1136]            ^^^^^^^^^^^^^^^^^^^^^
2026-05-01 20:49:35.616 | (EngineCore pid=228) ERROR 05-01 18:49:35 [core.py:1136]   File "/usr/local/lib/python3.12/dist-packages/vllm/v1/executor/abstract.py", line 109, in __init__
2026-05-01 20:49:35.616 | (EngineCore pid=228) ERROR 05-01 18:49:35 [core.py:1136]     self._init_executor()
2026-05-01 20:49:35.616 | (EngineCore pid=228) ERROR 05-01 18:49:35 [core.py:1136]   File "/usr/local/lib/python3.12/dist-packages/vllm/v1/executor/uniproc_executor.py", line 52, in _init_executor
2026-05-01 20:49:35.616 | (EngineCore pid=228) ERROR 05-01 18:49:35 [core.py:1136]     self.driver_worker.load_model()
2026-05-01 20:49:35.616 | (EngineCore pid=228) ERROR 05-01 18:49:35 [core.py:1136]   File "/usr/local/lib/python3.12/dist-packages/vllm/v1/worker/gpu_worker.py", line 323, in load_model
2026-05-01 20:49:35.616 | (EngineCore pid=228) ERROR 05-01 18:49:35 [core.py:1136]     self.model_runner.load_model(load_dummy_weights=load_dummy_weights)
2026-05-01 20:49:35.616 | (EngineCore pid=228) ERROR 05-01 18:49:35 [core.py:1136]   File "/usr/local/lib/python3.12/dist-packages/vllm/tracing/otel.py", line 178, in sync_wrapper
2026-05-01 20:49:35.616 | (EngineCore pid=228) ERROR 05-01 18:49:35 [core.py:1136]     return func(*args, **kwargs)
2026-05-01 20:49:35.616 | (EngineCore pid=228) ERROR 05-01 18:49:35 [core.py:1136]            ^^^^^^^^^^^^^^^^^^^^^
2026-05-01 20:49:35.616 | (EngineCore pid=228) ERROR 05-01 18:49:35 [core.py:1136]   File "/usr/local/lib/python3.12/dist-packages/vllm/v1/worker/gpu_model_runner.py", line 4793, in load_model
2026-05-01 20:49:35.616 | (EngineCore pid=228) ERROR 05-01 18:49:35 [core.py:1136]     self.model = model_loader.load_model(
2026-05-01 20:49:35.616 | (EngineCore pid=228) ERROR 05-01 18:49:35 [core.py:1136]                  ^^^^^^^^^^^^^^^^^^^^^^^^
2026-05-01 20:49:35.616 | (EngineCore pid=228) ERROR 05-01 18:49:35 [core.py:1136]   File "/usr/local/lib/python3.12/dist-packages/vllm/tracing/otel.py", line 178, in sync_wrapper
2026-05-01 20:49:35.616 | (EngineCore pid=228) ERROR 05-01 18:49:35 [core.py:1136]     return func(*args, **kwargs)
2026-05-01 20:49:35.616 | (EngineCore pid=228) ERROR 05-01 18:49:35 [core.py:1136]            ^^^^^^^^^^^^^^^^^^^^^
2026-05-01 20:49:35.616 | (EngineCore pid=228) ERROR 05-01 18:49:35 [core.py:1136]   File "/usr/local/lib/python3.12/dist-packages/vllm/model_executor/model_loader/base_loader.py", line 55, in load_model
2026-05-01 20:49:35.616 | (EngineCore pid=228) ERROR 05-01 18:49:35 [core.py:1136]     model = initialize_model(
2026-05-01 20:49:35.616 | (EngineCore pid=228) ERROR 05-01 18:49:35 [core.py:1136]             ^^^^^^^^^^^^^^^^^
2026-05-01 20:49:35.616 | (EngineCore pid=228) ERROR 05-01 18:49:35 [core.py:1136]   File "/usr/local/lib/python3.12/dist-packages/vllm/tracing/otel.py", line 178, in sync_wrapper
2026-05-01 20:49:35.616 | (EngineCore pid=228) ERROR 05-01 18:49:35 [core.py:1136]     return func(*args, **kwargs)
2026-05-01 20:49:35.616 | (EngineCore pid=228) ERROR 05-01 18:49:35 [core.py:1136]            ^^^^^^^^^^^^^^^^^^^^^
2026-05-01 20:49:35.616 | (EngineCore pid=228) ERROR 05-01 18:49:35 [core.py:1136]   File "/usr/local/lib/python3.12/dist-packages/vllm/model_executor/model_loader/utils.py", line 57, in initialize_model
2026-05-01 20:49:35.616 | (EngineCore pid=228) ERROR 05-01 18:49:35 [core.py:1136]     model = model_class(vllm_config=vllm_config, prefix=prefix)
2026-05-01 20:49:35.616 | (EngineCore pid=228) ERROR 05-01 18:49:35 [core.py:1136]             ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
2026-05-01 20:49:35.616 | (EngineCore pid=228) ERROR 05-01 18:49:35 [core.py:1136]   File "/usr/local/lib/python3.12/dist-packages/vllm/model_executor/models/qwen3_5.py", line 834, in __init__
2026-05-01 20:49:35.616 | (EngineCore pid=228) ERROR 05-01 18:49:35 [core.py:1136]     self.language_model = Qwen3_5MoeForCausalLM(
2026-05-01 20:49:35.616 | (EngineCore pid=228) ERROR 05-01 18:49:35 [core.py:1136]                           ^^^^^^^^^^^^^^^^^^^^^^
2026-05-01 20:49:35.616 | (EngineCore pid=228) ERROR 05-01 18:49:35 [core.py:1136]   File "/usr/local/lib/python3.12/dist-packages/vllm/model_executor/models/qwen3_5.py", line 558, in __init__
2026-05-01 20:49:35.616 | (EngineCore pid=228) ERROR 05-01 18:49:35 [core.py:1136]     super().__init__(vllm_config=vllm_config, prefix=prefix)
2026-05-01 20:49:35.616 | (EngineCore pid=228) ERROR 05-01 18:49:35 [core.py:1136]   File "/usr/local/lib/python3.12/dist-packages/vllm/model_executor/models/qwen3_5.py", line 484, in __init__
2026-05-01 20:49:35.616 | (EngineCore pid=228) ERROR 05-01 18:49:35 [core.py:1136]     self.model = Qwen3_5Model(
2026-05-01 20:49:35.616 | (EngineCore pid=228) ERROR 05-01 18:49:35 [core.py:1136]                  ^^^^^^^^^^^^^
2026-05-01 20:49:35.616 | (EngineCore pid=228) ERROR 05-01 18:49:35 [core.py:1136]   File "/usr/local/lib/python3.12/dist-packages/vllm/compilation/decorators.py", line 379, in __init__
2026-05-01 20:49:35.616 | (EngineCore pid=228) ERROR 05-01 18:49:35 [core.py:1136]     old_init(self, *args, **kwargs)
2026-05-01 20:49:35.616 | (EngineCore pid=228) ERROR 05-01 18:49:35 [core.py:1136]   File "/usr/local/lib/python3.12/dist-packages/vllm/model_executor/models/qwen3_5.py", line 236, in __init__
2026-05-01 20:49:35.616 | (EngineCore pid=228) ERROR 05-01 18:49:35 [core.py:1136]     self.start_layer, self.end_layer, self.layers = make_layers(
2026-05-01 20:49:35.616 | (EngineCore pid=228) ERROR 05-01 18:49:35 [core.py:1136]                                                     ^^^^^^^^^^^^
2026-05-01 20:49:35.616 | (EngineCore pid=228) ERROR 05-01 18:49:35 [core.py:1136]   File "/usr/local/lib/python3.12/dist-packages/vllm/model_executor/models/utils.py", line 646, in make_layers
2026-05-01 20:49:35.616 | (EngineCore pid=228) ERROR 05-01 18:49:35 [core.py:1136]     + get_offloader().wrap_modules(
2026-05-01 20:49:35.616 | (EngineCore pid=228) ERROR 05-01 18:49:35 [core.py:1136]       ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
2026-05-01 20:49:35.616 | (EngineCore pid=228) ERROR 05-01 18:49:35 [core.py:1136]   File "/usr/local/lib/python3.12/dist-packages/vllm/model_executor/offloader/base.py", line 104, in wrap_modules
2026-05-01 20:49:35.616 | (EngineCore pid=228) ERROR 05-01 18:49:35 [core.py:1136]     return list(modules_generator)
2026-05-01 20:49:35.616 | (EngineCore pid=228) ERROR 05-01 18:49:35 [core.py:1136]            ^^^^^^^^^^^^^^^^^^^^^^^
2026-05-01 20:49:35.616 | (EngineCore pid=228) ERROR 05-01 18:49:35 [core.py:1136]   File "/usr/local/lib/python3.12/dist-packages/vllm/model_executor/models/utils.py", line 647, in <genexpr>
2026-05-01 20:49:35.616 | (EngineCore pid=228) ERROR 05-01 18:49:35 [core.py:1136]     layer_fn(prefix=f"{prefix}.{idx}") for idx in range(start_layer, end_layer)
2026-05-01 20:49:35.616 | (EngineCore pid=228) ERROR 05-01 18:49:35 [core.py:1136]     ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
2026-05-01 20:49:35.616 | (EngineCore pid=228) ERROR 05-01 18:49:35 [core.py:1136]   File "/usr/local/lib/python3.12/dist-packages/vllm/model_executor/models/qwen3_5.py", line 230, in get_layer
2026-05-01 20:49:35.616 | (EngineCore pid=228) ERROR 05-01 18:49:35 [core.py:1136]     return Qwen3_5DecoderLayer(
2026-05-01 20:49:35.616 | (EngineCore pid=228) ERROR 05-01 18:49:35 [core.py:1136]            ^^^^^^^^^^^^^^^^^^^^
2026-05-01 20:49:35.616 | (EngineCore pid=228) ERROR 05-01 18:49:35 [core.py:1136]   File "/usr/local/lib/python3.12/dist-packages/vllm/model_executor/models/qwen3_5.py", line 157, in __init__
2026-05-01 20:49:35.616 | (EngineCore pid=228) ERROR 05-01 18:49:35 [core.py:1136]     self.mlp = Qwen3NextSparseMoeBlock(
2026-05-01 20:49:35.616 | (EngineCore pid=228) ERROR 05-01 18:49:35 [core.py:1136]                ^^^^^^^^^^^^^^^^^^^^^^^^
2026-05-01 20:49:35.616 | (EngineCore pid=228) ERROR 05-01 18:49:35 [core.py:1136]   File "/usr/local/lib/python3.12/dist-packages/vllm/model_executor/models/qwen3_next.py", line 152, in __init__
2026-05-01 20:49:35.616 | (EngineCore pid=228) ERROR 05-01 18:49:35 [core.py:1136]     self.experts = FusedMoE(
2026-05-01 20:49:35.616 | (EngineCore pid=228) ERROR 05-01 18:49:35 [core.py:1136]                    ^^^^^^^^^
2026-05-01 20:49:35.616 | (EngineCore pid=228) ERROR 05-01 18:49:35 [core.py:1136]   File "/usr/local/lib/python3.12/dist-packages/vllm/model_executor/layers/fused_moe/layer.py", line 539, in __init__
2026-05-01 20:49:35.616 | (EngineCore pid=228) ERROR 05-01 18:49:35 [core.py:1136]     self.quant_method: FusedMoEMethodBase = _get_quant_method()
2026-05-01 20:49:35.616 | (EngineCore pid=228) ERROR 05-01 18:49:35 [core.py:1136]                                             ^^^^^^^^^^^^^^^^^^^
2026-05-01 20:49:35.616 | (EngineCore pid=228) ERROR 05-01 18:49:35 [core.py:1136]   File "/usr/local/lib/python3.12/dist-packages/vllm/model_executor/layers/fused_moe/layer.py", line 531, in _get_quant_method
2026-05-01 20:49:35.616 | (EngineCore pid=228) ERROR 05-01 18:49:35 [core.py:1136]     quant_method = self.quant_config.get_quant_method(self, prefix)
2026-05-01 20:49:35.616 | (EngineCore pid=228) ERROR 05-01 18:49:35 [core.py:1136]                    ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
2026-05-01 20:49:35.616 | (EngineCore pid=228) ERROR 05-01 18:49:35 [core.py:1136]   File "/usr/local/lib/python3.12/dist-packages/vllm/model_executor/layers/quantization/compressed_tensors/compressed_tensors.py", line 196, in get_quant_method
2026-05-01 20:49:35.616 | (EngineCore pid=228) ERROR 05-01 18:49:35 [core.py:1136]     return CompressedTensorsMoEMethod.get_moe_method(
2026-05-01 20:49:35.616 | (EngineCore pid=228) ERROR 05-01 18:49:35 [core.py:1136]            ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
2026-05-01 20:49:35.616 | (EngineCore pid=228) ERROR 05-01 18:49:35 [core.py:1136]   File "/usr/local/lib/python3.12/dist-packages/vllm/model_executor/layers/quantization/compressed_tensors/compressed_tensors_moe/compressed_tensors_moe.py", line 139, in get_moe_method
2026-05-01 20:49:35.616 | (EngineCore pid=228) ERROR 05-01 18:49:35 [core.py:1136]     return CompressedTensorsW4A4Nvfp4MoEMethod(
2026-05-01 20:49:35.616 | (EngineCore pid=228) ERROR 05-01 18:49:35 [core.py:1136]            ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
2026-05-01 20:49:35.616 | (EngineCore pid=228) ERROR 05-01 18:49:35 [core.py:1136]   File "/usr/local/lib/python3.12/dist-packages/vllm/model_executor/layers/quantization/compressed_tensors/compressed_tensors_moe/compressed_tensors_moe_w4a4_nvfp4.py", line 47, in __init__
2026-05-01 20:49:35.616 | (EngineCore pid=228) ERROR 05-01 18:49:35 [core.py:1136]     self.nvfp4_backend, self.experts_cls = select_nvfp4_moe_backend(
2026-05-01 20:49:35.616 | (EngineCore pid=228) ERROR 05-01 18:49:35 [core.py:1136]                                            ^^^^^^^^^^^^^^^^^^^^^^^^^
2026-05-01 20:49:35.616 | (EngineCore pid=228) ERROR 05-01 18:49:35 [core.py:1136]   File "/usr/local/lib/python3.12/dist-packages/vllm/model_executor/layers/fused_moe/oracle/nvfp4.py", line 217, in select_nvfp4_moe_backend
2026-05-01 20:49:35.616 | (EngineCore pid=228) ERROR 05-01 18:49:35 [core.py:1136]     requested_backend = map_nvfp4_backend(runner_backend)
2026-05-01 20:49:35.616 | (EngineCore pid=228) ERROR 05-01 18:49:35 [core.py:1136]                         ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
2026-05-01 20:49:35.616 | (EngineCore pid=228) ERROR 05-01 18:49:35 [core.py:1136]   File "/usr/local/lib/python3.12/dist-packages/vllm/model_executor/layers/fused_moe/oracle/nvfp4.py", line 144, in map_nvfp4_backend
2026-05-01 20:49:35.616 | (EngineCore pid=228) ERROR 05-01 18:49:35 [core.py:1136]     raise ValueError(
2026-05-01 20:49:35.616 | (EngineCore pid=228) ERROR 05-01 18:49:35 [core.py:1136] ValueError: moe_backend='triton' is not supported for NvFP4 MoE. Expected one of ['cutlass', 'flashinfer_trtllm', 'flashinfer_cutlass', 'flashinfer_cutedsl', 'marlin', 'emulation'].
2026-05-01 20:49:35.617 | (EngineCore pid=228) Traceback (most recent call last):
2026-05-01 20:49:35.617 | (EngineCore pid=228)   File "/usr/lib/python3.12/multiprocessing/process.py", line 314, in _bootstrap
2026-05-01 20:49:35.617 | (EngineCore pid=228)     self.run()
2026-05-01 20:49:35.617 | (EngineCore pid=228)   File "/usr/lib/python3.12/multiprocessing/process.py", line 108, in run
2026-05-01 20:49:35.617 | (EngineCore pid=228)     self._target(*self._args, **self._kwargs)
2026-05-01 20:49:35.617 | (EngineCore pid=228)   File "/usr/local/lib/python3.12/dist-packages/vllm/v1/engine/core.py", line 1140, in run_engine_core
2026-05-01 20:49:35.617 | (EngineCore pid=228)     raise e
2026-05-01 20:49:35.617 | (EngineCore pid=228)   File "/usr/local/lib/python3.12/dist-packages/vllm/v1/engine/core.py", line 1110, in run_engine_core
2026-05-01 20:49:35.617 | (EngineCore pid=228)     engine_core = EngineCoreProc(*args, engine_index=dp_rank, **kwargs)
2026-05-01 20:49:35.617 | (EngineCore pid=228)                   ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
2026-05-01 20:49:35.617 | (EngineCore pid=228)   File "/usr/local/lib/python3.12/dist-packages/vllm/tracing/otel.py", line 178, in sync_wrapper
2026-05-01 20:49:35.617 | (EngineCore pid=228)     return func(*args, **kwargs)
2026-05-01 20:49:35.617 | (EngineCore pid=228)            ^^^^^^^^^^^^^^^^^^^^^
2026-05-01 20:49:35.617 | (EngineCore pid=228)   File "/usr/local/lib/python3.12/dist-packages/vllm/v1/engine/core.py", line 876, in __init__
2026-05-01 20:49:35.617 | (EngineCore pid=228)     super().__init__(
2026-05-01 20:49:35.617 | (EngineCore pid=228)   File "/usr/local/lib/python3.12/dist-packages/vllm/v1/engine/core.py", line 118, in __init__
2026-05-01 20:49:35.617 | (EngineCore pid=228)     self.model_executor = executor_class(vllm_config)
2026-05-01 20:49:35.617 | (EngineCore pid=228)                           ^^^^^^^^^^^^^^^^^^^^^^^^^^^
2026-05-01 20:49:35.617 | (EngineCore pid=228)   File "/usr/local/lib/python3.12/dist-packages/vllm/tracing/otel.py", line 178, in sync_wrapper
2026-05-01 20:49:35.617 | (EngineCore pid=228)     return func(*args, **kwargs)
2026-05-01 20:49:35.617 | (EngineCore pid=228)            ^^^^^^^^^^^^^^^^^^^^^
2026-05-01 20:49:35.617 | (EngineCore pid=228)   File "/usr/local/lib/python3.12/dist-packages/vllm/v1/executor/abstract.py", line 109, in __init__
2026-05-01 20:49:35.617 | (EngineCore pid=228)     self._init_executor()
2026-05-01 20:49:35.617 | (EngineCore pid=228)   File "/usr/local/lib/python3.12/dist-packages/vllm/v1/executor/uniproc_executor.py", line 52, in _init_executor
2026-05-01 20:49:35.617 | (EngineCore pid=228)     self.driver_worker.load_model()
2026-05-01 20:49:35.617 | (EngineCore pid=228)   File "/usr/local/lib/python3.12/dist-packages/vllm/v1/worker/gpu_worker.py", line 323, in load_model
2026-05-01 20:49:35.617 | (EngineCore pid=228)     self.model_runner.load_model(load_dummy_weights=load_dummy_weights)
2026-05-01 20:49:35.617 | (EngineCore pid=228)   File "/usr/local/lib/python3.12/dist-packages/vllm/tracing/otel.py", line 178, in sync_wrapper
2026-05-01 20:49:35.617 | (EngineCore pid=228)     return func(*args, **kwargs)
2026-05-01 20:49:35.617 | (EngineCore pid=228)            ^^^^^^^^^^^^^^^^^^^^^
2026-05-01 20:49:35.617 | (EngineCore pid=228)   File "/usr/local/lib/python3.12/dist-packages/vllm/v1/worker/gpu_model_runner.py", line 4793, in load_model
2026-05-01 20:49:35.617 | (EngineCore pid=228)     self.model = model_loader.load_model(
2026-05-01 20:49:35.617 | (EngineCore pid=228)                  ^^^^^^^^^^^^^^^^^^^^^^^^
2026-05-01 20:49:35.617 | (EngineCore pid=228)   File "/usr/local/lib/python3.12/dist-packages/vllm/tracing/otel.py", line 178, in sync_wrapper
2026-05-01 20:49:35.617 | (EngineCore pid=228)     return func(*args, **kwargs)
2026-05-01 20:49:35.617 | (EngineCore pid=228)            ^^^^^^^^^^^^^^^^^^^^^
2026-05-01 20:49:35.617 | (EngineCore pid=228)   File "/usr/local/lib/python3.12/dist-packages/vllm/model_executor/model_loader/base_loader.py", line 55, in load_model
2026-05-01 20:49:35.617 | (EngineCore pid=228)     model = initialize_model(
2026-05-01 20:49:35.617 | (EngineCore pid=228)             ^^^^^^^^^^^^^^^^^
2026-05-01 20:49:35.617 | (EngineCore pid=228)   File "/usr/local/lib/python3.12/dist-packages/vllm/tracing/otel.py", line 178, in sync_wrapper
2026-05-01 20:49:35.617 | (EngineCore pid=228)     return func(*args, **kwargs)
2026-05-01 20:49:35.617 | (EngineCore pid=228)            ^^^^^^^^^^^^^^^^^^^^^
2026-05-01 20:49:35.617 | (EngineCore pid=228)   File "/usr/local/lib/python3.12/dist-packages/vllm/model_executor/model_loader/utils.py", line 57, in initialize_model
2026-05-01 20:49:35.617 | (EngineCore pid=228)     model = model_class(vllm_config=vllm_config, prefix=prefix)
2026-05-01 20:49:35.617 | (EngineCore pid=228)             ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
2026-05-01 20:49:35.617 | (EngineCore pid=228)   File "/usr/local/lib/python3.12/dist-packages/vllm/model_executor/models/qwen3_5.py", line 834, in __init__
2026-05-01 20:49:35.617 | (EngineCore pid=228)     self.language_model = Qwen3_5MoeForCausalLM(
2026-05-01 20:49:35.617 | (EngineCore pid=228)                           ^^^^^^^^^^^^^^^^^^^^^^
2026-05-01 20:49:35.617 | (EngineCore pid=228)   File "/usr/local/lib/python3.12/dist-packages/vllm/model_executor/models/qwen3_5.py", line 558, in __init__
2026-05-01 20:49:35.617 | (EngineCore pid=228)     super().__init__(vllm_config=vllm_config, prefix=prefix)
2026-05-01 20:49:35.617 | (EngineCore pid=228)   File "/usr/local/lib/python3.12/dist-packages/vllm/model_executor/models/qwen3_5.py", line 484, in __init__
2026-05-01 20:49:35.617 | (EngineCore pid=228)     self.model = Qwen3_5Model(
2026-05-01 20:49:35.617 | (EngineCore pid=228)                  ^^^^^^^^^^^^^
2026-05-01 20:49:35.617 | (EngineCore pid=228)   File "/usr/local/lib/python3.12/dist-packages/vllm/compilation/decorators.py", line 379, in __init__
2026-05-01 20:49:35.617 | (EngineCore pid=228)     old_init(self, *args, **kwargs)
2026-05-01 20:49:35.617 | (EngineCore pid=228)   File "/usr/local/lib/python3.12/dist-packages/vllm/model_executor/models/qwen3_5.py", line 236, in __init__
2026-05-01 20:49:35.617 | (EngineCore pid=228)     self.start_layer, self.end_layer, self.layers = make_layers(
2026-05-01 20:49:35.617 | (EngineCore pid=228)                                                     ^^^^^^^^^^^^
2026-05-01 20:49:35.617 | (EngineCore pid=228)   File "/usr/local/lib/python3.12/dist-packages/vllm/model_executor/models/utils.py", line 646, in make_layers
2026-05-01 20:49:35.617 | (EngineCore pid=228)     + get_offloader().wrap_modules(
2026-05-01 20:49:35.617 | (EngineCore pid=228)       ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
2026-05-01 20:49:35.617 | (EngineCore pid=228)   File "/usr/local/lib/python3.12/dist-packages/vllm/model_executor/offloader/base.py", line 104, in wrap_modules
2026-05-01 20:49:35.617 | (EngineCore pid=228)     return list(modules_generator)
2026-05-01 20:49:35.617 | (EngineCore pid=228)            ^^^^^^^^^^^^^^^^^^^^^^^
2026-05-01 20:49:35.617 | (EngineCore pid=228)   File "/usr/local/lib/python3.12/dist-packages/vllm/model_executor/models/utils.py", line 647, in <genexpr>
2026-05-01 20:49:35.617 | (EngineCore pid=228)     layer_fn(prefix=f"{prefix}.{idx}") for idx in range(start_layer, end_layer)
2026-05-01 20:49:35.617 | (EngineCore pid=228)     ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
2026-05-01 20:49:35.617 | (EngineCore pid=228)   File "/usr/local/lib/python3.12/dist-packages/vllm/model_executor/models/qwen3_5.py", line 230, in get_layer
2026-05-01 20:49:35.617 | (EngineCore pid=228)     return Qwen3_5DecoderLayer(
2026-05-01 20:49:35.617 | (EngineCore pid=228)            ^^^^^^^^^^^^^^^^^^^^
2026-05-01 20:49:35.617 | (EngineCore pid=228)   File "/usr/local/lib/python3.12/dist-packages/vllm/model_executor/models/qwen3_5.py", line 157, in __init__
2026-05-01 20:49:35.617 | (EngineCore pid=228)     self.mlp = Qwen3NextSparseMoeBlock(
2026-05-01 20:49:35.617 | (EngineCore pid=228)                ^^^^^^^^^^^^^^^^^^^^^^^^
2026-05-01 20:49:35.617 | (EngineCore pid=228)   File "/usr/local/lib/python3.12/dist-packages/vllm/model_executor/models/qwen3_next.py", line 152, in __init__
2026-05-01 20:49:35.617 | (EngineCore pid=228)     self.experts = FusedMoE(
2026-05-01 20:49:35.617 | (EngineCore pid=228)                    ^^^^^^^^^
2026-05-01 20:49:35.617 | (EngineCore pid=228)   File "/usr/local/lib/python3.12/dist-packages/vllm/model_executor/layers/fused_moe/layer.py", line 539, in __init__
2026-05-01 20:49:35.617 | (EngineCore pid=228)     self.quant_method: FusedMoEMethodBase = _get_quant_method()
2026-05-01 20:49:35.617 | (EngineCore pid=228)                                             ^^^^^^^^^^^^^^^^^^^
2026-05-01 20:49:35.617 | (EngineCore pid=228)   File "/usr/local/lib/python3.12/dist-packages/vllm/model_executor/layers/fused_moe/layer.py", line 531, in _get_quant_method
2026-05-01 20:49:35.617 | (EngineCore pid=228)     quant_method = self.quant_config.get_quant_method(self, prefix)
2026-05-01 20:49:35.617 | (EngineCore pid=228)                    ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
2026-05-01 20:49:35.617 | (EngineCore pid=228)   File "/usr/local/lib/python3.12/dist-packages/vllm/model_executor/layers/quantization/compressed_tensors/compressed_tensors.py", line 196, in get_quant_method
2026-05-01 20:49:35.618 | (EngineCore pid=228)     return CompressedTensorsMoEMethod.get_moe_method(
2026-05-01 20:49:35.618 | (EngineCore pid=228)            ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
2026-05-01 20:49:35.618 | (EngineCore pid=228)   File "/usr/local/lib/python3.12/dist-packages/vllm/model_executor/layers/quantization/compressed_tensors/compressed_tensors_moe/compressed_tensors_moe.py", line 139, in get_moe_method
2026-05-01 20:49:35.618 | (EngineCore pid=228)     return CompressedTensorsW4A4Nvfp4MoEMethod(
2026-05-01 20:49:35.618 | (EngineCore pid=228)            ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
2026-05-01 20:49:35.618 | (EngineCore pid=228)   File "/usr/local/lib/python3.12/dist-packages/vllm/model_executor/layers/quantization/compressed_tensors/compressed_tensors_moe/compressed_tensors_moe_w4a4_nvfp4.py", line 47, in __init__
2026-05-01 20:49:35.618 | (EngineCore pid=228)     self.nvfp4_backend, self.experts_cls = select_nvfp4_moe_backend(
2026-05-01 20:49:35.618 | (EngineCore pid=228)                                            ^^^^^^^^^^^^^^^^^^^^^^^^^
2026-05-01 20:49:35.618 | (EngineCore pid=228)   File "/usr/local/lib/python3.12/dist-packages/vllm/model_executor/layers/fused_moe/oracle/nvfp4.py", line 217, in select_nvfp4_moe_backend
2026-05-01 20:49:35.618 | (EngineCore pid=228)     requested_backend = map_nvfp4_backend(runner_backend)
2026-05-01 20:49:35.618 | (EngineCore pid=228)                         ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
2026-05-01 20:49:35.618 | (EngineCore pid=228)   File "/usr/local/lib/python3.12/dist-packages/vllm/model_executor/layers/fused_moe/oracle/nvfp4.py", line 144, in map_nvfp4_backend
2026-05-01 20:49:35.618 | (EngineCore pid=228)     raise ValueError(
2026-05-01 20:49:35.618 | (EngineCore pid=228) ValueError: moe_backend='triton' is not supported for NvFP4 MoE. Expected one of ['cutlass', 'flashinfer_trtllm', 'flashinfer_cutlass', 'flashinfer_cutedsl', 'marlin', 'emulation'].
2026-05-01 20:49:36.195 | [rank0]:[W501 18:49:36.689142079 ProcessGroupNCCL.cpp:1575] Warning: WARNING: destroy_process_group() was not called before program exit, which can leak resources. For more info, please see https://pytorch.org/docs/stable/distributed.html#shutdown (function operator())
2026-05-01 20:49:37.032 | (APIServer pid=1) Traceback (most recent call last):
2026-05-01 20:49:37.032 | (APIServer pid=1)   File "/usr/local/bin/vllm", line 10, in <module>
2026-05-01 20:49:37.032 | (APIServer pid=1)     sys.exit(main())
2026-05-01 20:49:37.032 | (APIServer pid=1)              ^^^^^^
2026-05-01 20:49:37.032 | (APIServer pid=1)   File "/usr/local/lib/python3.12/dist-packages/vllm/entrypoints/cli/main.py", line 92, in main
2026-05-01 20:49:37.032 | (APIServer pid=1)     args.dispatch_function(args)
2026-05-01 20:49:37.032 | (APIServer pid=1)   File "/usr/local/lib/python3.12/dist-packages/vllm/entrypoints/cli/serve.py", line 122, in cmd
2026-05-01 20:49:37.032 | (APIServer pid=1)     uvloop.run(run_server(args))
2026-05-01 20:49:37.033 | (APIServer pid=1)   File "/usr/local/lib/python3.12/dist-packages/uvloop/__init__.py", line 96, in run
2026-05-01 20:49:37.033 | (APIServer pid=1)     return __asyncio.run(
2026-05-01 20:49:37.033 | (APIServer pid=1)            ^^^^^^^^^^^^^^
2026-05-01 20:49:37.033 | (APIServer pid=1)   File "/usr/lib/python3.12/asyncio/runners.py", line 194, in run
2026-05-01 20:49:37.036 | (APIServer pid=1)     return runner.run(main)
2026-05-01 20:49:37.036 | (APIServer pid=1)            ^^^^^^^^^^^^^^^^
2026-05-01 20:49:37.036 | (APIServer pid=1)   File "/usr/lib/python3.12/asyncio/runners.py", line 118, in run
2026-05-01 20:49:37.036 | (APIServer pid=1)     return self._loop.run_until_complete(task)
2026-05-01 20:49:37.036 | (APIServer pid=1)            ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
2026-05-01 20:49:37.036 | (APIServer pid=1)   File "uvloop/loop.pyx", line 1518, in uvloop.loop.Loop.run_until_complete
2026-05-01 20:49:37.036 | (APIServer pid=1)   File "/usr/local/lib/python3.12/dist-packages/uvloop/__init__.py", line 48, in wrapper
2026-05-01 20:49:37.036 | (APIServer pid=1)     return await main
2026-05-01 20:49:37.036 | (APIServer pid=1)            ^^^^^^^^^^
2026-05-01 20:49:37.036 | (APIServer pid=1)   File "/usr/local/lib/python3.12/dist-packages/vllm/entrypoints/openai/api_server.py", line 678, in run_server
2026-05-01 20:49:37.036 | (APIServer pid=1)     await run_server_worker(listen_address, sock, args, **uvicorn_kwargs)
2026-05-01 20:49:37.036 | (APIServer pid=1)   File "/usr/local/lib/python3.12/dist-packages/vllm/entrypoints/openai/api_server.py", line 692, in run_server_worker
2026-05-01 20:49:37.036 | (APIServer pid=1)     async with build_async_engine_client(
2026-05-01 20:49:37.036 | (APIServer pid=1)   File "/usr/lib/python3.12/contextlib.py", line 210, in __aenter__
2026-05-01 20:49:37.037 | (APIServer pid=1)     return await anext(self.gen)
2026-05-01 20:49:37.037 | (APIServer pid=1)            ^^^^^^^^^^^^^^^^^^^^^
2026-05-01 20:49:37.037 | (APIServer pid=1)   File "/usr/local/lib/python3.12/dist-packages/vllm/entrypoints/openai/api_server.py", line 100, in build_async_engine_client
2026-05-01 20:49:37.037 | (APIServer pid=1)     async with build_async_engine_client_from_engine_args(
2026-05-01 20:49:37.037 | (APIServer pid=1)   File "/usr/lib/python3.12/contextlib.py", line 210, in __aenter__
2026-05-01 20:49:37.037 | (APIServer pid=1)     return await anext(self.gen)
2026-05-01 20:49:37.037 | (APIServer pid=1)            ^^^^^^^^^^^^^^^^^^^^^
2026-05-01 20:49:37.037 | (APIServer pid=1)   File "/usr/local/lib/python3.12/dist-packages/vllm/entrypoints/openai/api_server.py", line 136, in build_async_engine_client_from_engine_args
2026-05-01 20:49:37.037 | (APIServer pid=1)     async_llm = AsyncLLM.from_vllm_config(
2026-05-01 20:49:37.037 | (APIServer pid=1)                 ^^^^^^^^^^^^^^^^^^^^^^^^^^
2026-05-01 20:49:37.037 | (APIServer pid=1)   File "/usr/local/lib/python3.12/dist-packages/vllm/v1/engine/async_llm.py", line 217, in from_vllm_config
2026-05-01 20:49:37.037 | (APIServer pid=1)     return cls(
2026-05-01 20:49:37.037 | (APIServer pid=1)            ^^^^
2026-05-01 20:49:37.037 | (APIServer pid=1)   File "/usr/local/lib/python3.12/dist-packages/vllm/v1/engine/async_llm.py", line 146, in __init__
2026-05-01 20:49:37.037 | (APIServer pid=1)     self.engine_core = EngineCoreClient.make_async_mp_client(
2026-05-01 20:49:37.037 | (APIServer pid=1)                        ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
2026-05-01 20:49:37.037 | (APIServer pid=1)   File "/usr/local/lib/python3.12/dist-packages/vllm/tracing/otel.py", line 178, in sync_wrapper
2026-05-01 20:49:37.037 | (APIServer pid=1)     return func(*args, **kwargs)
2026-05-01 20:49:37.037 | (APIServer pid=1)            ^^^^^^^^^^^^^^^^^^^^^
2026-05-01 20:49:37.037 | (APIServer pid=1)   File "/usr/local/lib/python3.12/dist-packages/vllm/v1/engine/core_client.py", line 130, in make_async_mp_client
2026-05-01 20:49:37.038 | (APIServer pid=1)     return AsyncMPClient(*client_args)
2026-05-01 20:49:37.038 | (APIServer pid=1)            ^^^^^^^^^^^^^^^^^^^^^^^^^^^
2026-05-01 20:49:37.038 | (APIServer pid=1)   File "/usr/local/lib/python3.12/dist-packages/vllm/tracing/otel.py", line 178, in sync_wrapper
2026-05-01 20:49:37.038 | (APIServer pid=1)     return func(*args, **kwargs)
2026-05-01 20:49:37.038 | (APIServer pid=1)            ^^^^^^^^^^^^^^^^^^^^^
2026-05-01 20:49:37.038 | (APIServer pid=1)   File "/usr/local/lib/python3.12/dist-packages/vllm/v1/engine/core_client.py", line 900, in __init__
2026-05-01 20:49:37.038 | (APIServer pid=1)     super().__init__(
2026-05-01 20:49:37.038 | (APIServer pid=1)   File "/usr/local/lib/python3.12/dist-packages/vllm/v1/engine/core_client.py", line 535, in __init__
2026-05-01 20:49:37.038 | (APIServer pid=1)     with launch_core_engines(
2026-05-01 20:49:37.038 | (APIServer pid=1)   File "/usr/lib/python3.12/contextlib.py", line 144, in __exit__
2026-05-01 20:49:37.038 | (APIServer pid=1)     next(self.gen)
2026-05-01 20:49:37.038 | (APIServer pid=1)   File "/usr/local/lib/python3.12/dist-packages/vllm/v1/engine/utils.py", line 1119, in launch_core_engines
2026-05-01 20:49:37.038 | (APIServer pid=1)     wait_for_engine_startup(
2026-05-01 20:49:37.038 | (APIServer pid=1)   File "/usr/local/lib/python3.12/dist-packages/vllm/v1/engine/utils.py", line 1178, in wait_for_engine_startup
2026-05-01 20:49:37.038 | (APIServer pid=1)     raise RuntimeError(
2026-05-01 20:49:37.038 | (APIServer pid=1) RuntimeError: Engine core initialization failed. See root cause above. Failed core proc(s): {}
2026-05-01 20:49:45.437 | WARNING 05-01 18:49:45 [interface.py:686] Using 'pin_memory=False' as WSL is detected. This may slow down the performance.
2026-05-01 20:49:45.491 | WARNING 05-01 18:49:45 [argparse_utils.py:257] With `vllm serve`, you should provide the model as a positional argument or in a config file instead of via the `--model` option. The `--model` option will be removed in a future version.
2026-05-01 20:49:45.493 | (APIServer pid=1) INFO 05-01 18:49:45 [utils.py:299] 
2026-05-01 20:49:45.493 | (APIServer pid=1) INFO 05-01 18:49:45 [utils.py:299]        █     █     █▄   ▄█
2026-05-01 20:49:45.493 | (APIServer pid=1) INFO 05-01 18:49:45 [utils.py:299]  ▄▄ ▄█ █     █     █ ▀▄▀ █  version 0.20.0
2026-05-01 20:49:45.493 | (APIServer pid=1) INFO 05-01 18:49:45 [utils.py:299]   █▄█▀ █     █     █     █  model   RedHatAI/Qwen3.6-35B-A3B-NVFP4
2026-05-01 20:49:45.493 | (APIServer pid=1) INFO 05-01 18:49:45 [utils.py:299]    ▀▀  ▀▀▀▀▀ ▀▀▀▀▀ ▀     ▀
2026-05-01 20:49:45.493 | (APIServer pid=1) INFO 05-01 18:49:45 [utils.py:299] 
2026-05-01 20:49:45.496 | (APIServer pid=1) INFO 05-01 18:49:45 [utils.py:233] non-default args: {'model_tag': 'RedHatAI/Qwen3.6-35B-A3B-NVFP4', 'tool_call_parser': 'qwen3_coder', 'host': '0.0.0.0', 'model': 'RedHatAI/Qwen3.6-35B-A3B-NVFP4', 'trust_remote_code': True, 'max_model_len': 8192, 'quantization': 'compressed-tensors', 'enforce_eager': True, 'served_model_name': ['RedHatAI/Qwen3.6-35B-A3B-NVFP4'], 'reasoning_parser': 'qwen3', 'gpu_memory_utilization': 0.8, 'kv_cache_dtype': 'fp8_e4m3', 'enable_prefix_caching': True, 'max_num_batched_tokens': 8192, 'max_num_seqs': 32, 'enable_chunked_prefill': True, 'moe_backend': 'triton'}
2026-05-01 20:49:45.498 | (APIServer pid=1) WARNING 05-01 18:49:45 [envs.py:1818] Unknown vLLM environment variable detected: VLLM_FLASHINFER_CHECK_SAFE_OPS
2026-05-01 20:49:46.015 | (APIServer pid=1) Warning: You are sending unauthenticated requests to the HF Hub. Please set a HF_TOKEN to enable higher rate limits and faster downloads.
2026-05-01 20:49:46.502 | (APIServer pid=1) INFO 05-01 18:49:46 [model.py:555] Resolved architecture: Qwen3_5MoeForConditionalGeneration
2026-05-01 20:49:46.503 | (APIServer pid=1) INFO 05-01 18:49:46 [model.py:1680] Using max model len 8192
2026-05-01 20:49:47.250 | (APIServer pid=1) INFO 05-01 18:49:47 [nixl_utils.py:20] Setting UCX_RCACHE_MAX_UNRELEASED to '1024' to avoid a rare memory leak in UCX when using NIXL.
2026-05-01 20:49:47.281 | (APIServer pid=1) INFO 05-01 18:49:47 [nixl_utils.py:32] NIXL is available
2026-05-01 20:49:47.683 | (APIServer pid=1) INFO 05-01 18:49:47 [cache.py:261] Using fp8_e4m3 data type to store kv cache. It reduces the GPU memory footprint and boosts the performance. Meanwhile, it may cause accuracy drop without a proper scaling factor
2026-05-01 20:49:47.683 | (APIServer pid=1) INFO 05-01 18:49:47 [scheduler.py:239] Chunked prefill is enabled with max_num_batched_tokens=8192.
2026-05-01 20:49:47.684 | (APIServer pid=1) WARNING 05-01 18:49:47 [config.py:367] Mamba cache mode is set to 'align' for Qwen3_5MoeForConditionalGeneration by default when prefix caching is enabled
2026-05-01 20:49:47.684 | (APIServer pid=1) INFO 05-01 18:49:47 [config.py:387] Warning: Prefix caching in Mamba cache 'align' mode is currently enabled. Its support for Mamba layers is experimental. Please report any issues you may observe.
2026-05-01 20:49:47.684 | (APIServer pid=1) INFO 05-01 18:49:47 [vllm.py:840] Asynchronous scheduling is enabled.
2026-05-01 20:49:47.684 | (APIServer pid=1) WARNING 05-01 18:49:47 [vllm.py:896] Enforce eager set, disabling torch.compile and CUDAGraphs. This is equivalent to setting -cc.mode=none -cc.cudagraph_mode=none
2026-05-01 20:49:47.684 | (APIServer pid=1) WARNING 05-01 18:49:47 [vllm.py:914] Inductor compilation was disabled by user settings, optimizations settings that are only active during inductor compilation will be ignored.
2026-05-01 20:49:47.684 | (APIServer pid=1) INFO 05-01 18:49:47 [kernel.py:205] Final IR op priority after setting platform defaults: IrOpPriorityConfig(rms_norm=['vllm_c', 'native'])
2026-05-01 20:49:47.684 | (APIServer pid=1) INFO 05-01 18:49:47 [vllm.py:1089] Cudagraph is disabled under eager mode
2026-05-01 20:49:50.541 | (APIServer pid=1) INFO 05-01 18:49:50 [compilation.py:303] Enabled custom fusions: norm_quant, act_quant
2026-05-01 20:49:50.669 | (APIServer pid=1) [transformers] `Qwen2VLImageProcessorFast` is deprecated. The `Fast` suffix for image processors has been removed; use `Qwen2VLImageProcessor` instead.
2026-05-01 20:49:58.998 | (APIServer pid=1) [transformers] The `use_fast` parameter is deprecated and will be removed in a future version. Use `backend="torchvision"` instead of `use_fast=True`, or `backend="pil"` instead of `use_fast=False`.
2026-05-01 20:50:10.343 | INFO 05-01 18:50:10 [nixl_utils.py:32] NIXL is available
2026-05-01 20:50:10.406 | (EngineCore pid=114) INFO 05-01 18:50:10 [core.py:109] Initializing a V1 LLM engine (v0.20.0) with config: model='RedHatAI/Qwen3.6-35B-A3B-NVFP4', speculative_config=None, tokenizer='RedHatAI/Qwen3.6-35B-A3B-NVFP4', skip_tokenizer_init=False, tokenizer_mode=auto, revision=None, tokenizer_revision=None, trust_remote_code=True, dtype=torch.bfloat16, max_seq_len=8192, download_dir=None, load_format=auto, tensor_parallel_size=1, pipeline_parallel_size=1, data_parallel_size=1, decode_context_parallel_size=1, dcp_comm_backend=ag_rs, disable_custom_all_reduce=False, quantization=compressed-tensors, quantization_config=None, enforce_eager=True, enable_return_routed_experts=False, kv_cache_dtype=fp8_e4m3, device_config=cuda, structured_outputs_config=StructuredOutputsConfig(backend='auto', disable_any_whitespace=False, disable_additional_properties=False, reasoning_parser='qwen3', reasoning_parser_plugin='', enable_in_reasoning=False), observability_config=ObservabilityConfig(show_hidden_metrics_for_version=None, otlp_traces_endpoint=None, collect_detailed_traces=None, kv_cache_metrics=False, kv_cache_metrics_sample=0.01, cudagraph_metrics=False, enable_layerwise_nvtx_tracing=False, enable_mfu_metrics=False, enable_mm_processor_stats=False, enable_logging_iteration_details=False), seed=0, served_model_name=RedHatAI/Qwen3.6-35B-A3B-NVFP4, enable_prefix_caching=True, enable_chunked_prefill=True, pooler_config=None, compilation_config={'mode': <CompilationMode.NONE: 0>, 'debug_dump_path': None, 'cache_dir': '', 'compile_cache_save_format': 'binary', 'backend': 'inductor', 'custom_ops': ['all'], 'ir_enable_torch_wrap': False, 'splitting_ops': [], 'compile_mm_encoder': False, 'cudagraph_mm_encoder': False, 'encoder_cudagraph_token_budgets': [], 'encoder_cudagraph_max_vision_items_per_batch': 0, 'encoder_cudagraph_max_frames_per_batch': None, 'compile_sizes': [], 'compile_ranges_endpoints': [8192], 'inductor_compile_config': {'enable_auto_functionalized_v2': False, 'size_asserts': False, 'alignment_asserts': False, 'scalar_asserts': False, 'combo_kernels': True, 'benchmark_combo_kernel': True}, 'inductor_passes': {}, 'cudagraph_mode': <CUDAGraphMode.NONE: 0>, 'cudagraph_num_of_warmups': 0, 'cudagraph_capture_sizes': [], 'cudagraph_copy_inputs': False, 'cudagraph_specialize_lora': True, 'use_inductor_graph_partition': False, 'pass_config': {'fuse_norm_quant': True, 'fuse_act_quant': True, 'fuse_attn_quant': False, 'enable_sp': False, 'fuse_gemm_comms': False, 'fuse_allreduce_rms': False}, 'max_cudagraph_capture_size': 0, 'dynamic_shapes_config': {'type': <DynamicShapesType.BACKED: 'backed'>, 'evaluate_guards': False, 'assume_32_bit_indexing': False}, 'local_cache_dir': None, 'fast_moe_cold_start': False, 'static_all_moe_layers': []}, kernel_config=KernelConfig(ir_op_priority=IrOpPriorityConfig(rms_norm=['vllm_c', 'native']), enable_flashinfer_autotune=True, moe_backend='triton')
2026-05-01 20:50:10.505 | (EngineCore pid=114) WARNING 05-01 18:50:10 [interface.py:686] Using 'pin_memory=False' as WSL is detected. This may slow down the performance.
2026-05-01 20:50:10.624 | (EngineCore pid=114) [transformers] `Qwen2VLImageProcessorFast` is deprecated. The `Fast` suffix for image processors has been removed; use `Qwen2VLImageProcessor` instead.
2026-05-01 20:50:10.924 | (EngineCore pid=114) Warning: You are sending unauthenticated requests to the HF Hub. Please set a HF_TOKEN to enable higher rate limits and faster downloads.
2026-05-01 20:50:13.770 | (EngineCore pid=114) INFO 05-01 18:50:13 [parallel_state.py:1402] world_size=1 rank=0 local_rank=0 distributed_init_method=tcp://172.18.0.2:60605 backend=nccl
2026-05-01 20:50:14.094 | (EngineCore pid=114) INFO 05-01 18:50:14 [parallel_state.py:1715] rank 0 in world size 1 is assigned as DP rank 0, PP rank 0, PCP rank 0, TP rank 0, EP rank 0, EPLB rank N/A
2026-05-01 20:50:20.527 | (EngineCore pid=114) [transformers] The `use_fast` parameter is deprecated and will be removed in a future version. Use `backend="torchvision"` instead of `use_fast=True`, or `backend="pil"` instead of `use_fast=False`.
2026-05-01 20:50:25.929 | (EngineCore pid=114) INFO 05-01 18:50:25 [gpu_model_runner.py:4777] Starting to load model RedHatAI/Qwen3.6-35B-A3B-NVFP4...
2026-05-01 20:50:26.285 | (EngineCore pid=114) INFO 05-01 18:50:26 [cuda.py:423] Using backend AttentionBackendEnum.FLASH_ATTN for vit attention
2026-05-01 20:50:26.286 | (EngineCore pid=114) INFO 05-01 18:50:26 [mm_encoder_attention.py:230] Using AttentionBackendEnum.FLASH_ATTN for MMEncoderAttention.
2026-05-01 20:50:26.368 | (EngineCore pid=114) INFO 05-01 18:50:26 [gdn_linear_attn.py:153] Using Triton/FLA GDN prefill kernel
2026-05-01 20:50:26.369 | (EngineCore pid=114) INFO 05-01 18:50:26 [__init__.py:683] Using FlashInferCutlassNvFp4LinearKernel for NVFP4 GEMM
2026-05-01 20:50:26.797 | (EngineCore pid=114) Process EngineCore:
2026-05-01 20:50:26.797 | (EngineCore pid=114) ERROR 05-01 18:50:26 [core.py:1136] EngineCore failed to start.
2026-05-01 20:50:26.797 | (EngineCore pid=114) ERROR 05-01 18:50:26 [core.py:1136] Traceback (most recent call last):
2026-05-01 20:50:26.797 | (EngineCore pid=114) ERROR 05-01 18:50:26 [core.py:1136]   File "/usr/local/lib/python3.12/dist-packages/vllm/v1/engine/core.py", line 1110, in run_engine_core
2026-05-01 20:50:26.797 | (EngineCore pid=114) ERROR 05-01 18:50:26 [core.py:1136]     engine_core = EngineCoreProc(*args, engine_index=dp_rank, **kwargs)
2026-05-01 20:50:26.797 | (EngineCore pid=114) ERROR 05-01 18:50:26 [core.py:1136]                   ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
2026-05-01 20:50:26.797 | (EngineCore pid=114) ERROR 05-01 18:50:26 [core.py:1136]   File "/usr/local/lib/python3.12/dist-packages/vllm/tracing/otel.py", line 178, in sync_wrapper
2026-05-01 20:50:26.797 | (EngineCore pid=114) ERROR 05-01 18:50:26 [core.py:1136]     return func(*args, **kwargs)
2026-05-01 20:50:26.797 | (EngineCore pid=114) ERROR 05-01 18:50:26 [core.py:1136]            ^^^^^^^^^^^^^^^^^^^^^
2026-05-01 20:50:26.797 | (EngineCore pid=114) ERROR 05-01 18:50:26 [core.py:1136]   File "/usr/local/lib/python3.12/dist-packages/vllm/v1/engine/core.py", line 876, in __init__
2026-05-01 20:50:26.797 | (EngineCore pid=114) ERROR 05-01 18:50:26 [core.py:1136]     super().__init__(
2026-05-01 20:50:26.797 | (EngineCore pid=114) ERROR 05-01 18:50:26 [core.py:1136]   File "/usr/local/lib/python3.12/dist-packages/vllm/v1/engine/core.py", line 118, in __init__
2026-05-01 20:50:26.797 | (EngineCore pid=114) ERROR 05-01 18:50:26 [core.py:1136]     self.model_executor = executor_class(vllm_config)
2026-05-01 20:50:26.797 | (EngineCore pid=114) ERROR 05-01 18:50:26 [core.py:1136]                           ^^^^^^^^^^^^^^^^^^^^^^^^^^^
2026-05-01 20:50:26.797 | (EngineCore pid=114) ERROR 05-01 18:50:26 [core.py:1136]   File "/usr/local/lib/python3.12/dist-packages/vllm/tracing/otel.py", line 178, in sync_wrapper
2026-05-01 20:50:26.797 | (EngineCore pid=114) ERROR 05-01 18:50:26 [core.py:1136]     return func(*args, **kwargs)
2026-05-01 20:50:26.797 | (EngineCore pid=114) ERROR 05-01 18:50:26 [core.py:1136]            ^^^^^^^^^^^^^^^^^^^^^
2026-05-01 20:50:26.797 | (EngineCore pid=114) ERROR 05-01 18:50:26 [core.py:1136]   File "/usr/local/lib/python3.12/dist-packages/vllm/v1/executor/abstract.py", line 109, in __init__
2026-05-01 20:50:26.797 | (EngineCore pid=114) ERROR 05-01 18:50:26 [core.py:1136]     self._init_executor()
2026-05-01 20:50:26.797 | (EngineCore pid=114) ERROR 05-01 18:50:26 [core.py:1136]   File "/usr/local/lib/python3.12/dist-packages/vllm/v1/executor/uniproc_executor.py", line 52, in _init_executor
2026-05-01 20:50:26.797 | (EngineCore pid=114) ERROR 05-01 18:50:26 [core.py:1136]     self.driver_worker.load_model()
2026-05-01 20:50:26.797 | (EngineCore pid=114) ERROR 05-01 18:50:26 [core.py:1136]   File "/usr/local/lib/python3.12/dist-packages/vllm/v1/worker/gpu_worker.py", line 323, in load_model
2026-05-01 20:50:26.797 | (EngineCore pid=114) ERROR 05-01 18:50:26 [core.py:1136]     self.model_runner.load_model(load_dummy_weights=load_dummy_weights)
2026-05-01 20:50:26.797 | (EngineCore pid=114) ERROR 05-01 18:50:26 [core.py:1136]   File "/usr/local/lib/python3.12/dist-packages/vllm/tracing/otel.py", line 178, in sync_wrapper
2026-05-01 20:50:26.797 | (EngineCore pid=114) ERROR 05-01 18:50:26 [core.py:1136]     return func(*args, **kwargs)
2026-05-01 20:50:26.797 | (EngineCore pid=114) ERROR 05-01 18:50:26 [core.py:1136]            ^^^^^^^^^^^^^^^^^^^^^
2026-05-01 20:50:26.797 | (EngineCore pid=114) ERROR 05-01 18:50:26 [core.py:1136]   File "/usr/local/lib/python3.12/dist-packages/vllm/v1/worker/gpu_model_runner.py", line 4793, in load_model
2026-05-01 20:50:26.797 | (EngineCore pid=114) ERROR 05-01 18:50:26 [core.py:1136]     self.model = model_loader.load_model(
2026-05-01 20:50:26.797 | (EngineCore pid=114) ERROR 05-01 18:50:26 [core.py:1136]                  ^^^^^^^^^^^^^^^^^^^^^^^^
2026-05-01 20:50:26.797 | (EngineCore pid=114) ERROR 05-01 18:50:26 [core.py:1136]   File "/usr/local/lib/python3.12/dist-packages/vllm/tracing/otel.py", line 178, in sync_wrapper
2026-05-01 20:50:26.797 | (EngineCore pid=114) ERROR 05-01 18:50:26 [core.py:1136]     return func(*args, **kwargs)
2026-05-01 20:50:26.797 | (EngineCore pid=114) ERROR 05-01 18:50:26 [core.py:1136]            ^^^^^^^^^^^^^^^^^^^^^
2026-05-01 20:50:26.797 | (EngineCore pid=114) ERROR 05-01 18:50:26 [core.py:1136]   File "/usr/local/lib/python3.12/dist-packages/vllm/model_executor/model_loader/base_loader.py", line 55, in load_model
2026-05-01 20:50:26.797 | (EngineCore pid=114) ERROR 05-01 18:50:26 [core.py:1136]     model = initialize_model(
2026-05-01 20:50:26.797 | (EngineCore pid=114) ERROR 05-01 18:50:26 [core.py:1136]             ^^^^^^^^^^^^^^^^^
2026-05-01 20:50:26.797 | (EngineCore pid=114) ERROR 05-01 18:50:26 [core.py:1136]   File "/usr/local/lib/python3.12/dist-packages/vllm/tracing/otel.py", line 178, in sync_wrapper
2026-05-01 20:50:26.797 | (EngineCore pid=114) ERROR 05-01 18:50:26 [core.py:1136]     return func(*args, **kwargs)
2026-05-01 20:50:26.797 | (EngineCore pid=114) ERROR 05-01 18:50:26 [core.py:1136]            ^^^^^^^^^^^^^^^^^^^^^
2026-05-01 20:50:26.797 | (EngineCore pid=114) ERROR 05-01 18:50:26 [core.py:1136]   File "/usr/local/lib/python3.12/dist-packages/vllm/model_executor/model_loader/utils.py", line 57, in initialize_model
2026-05-01 20:50:26.797 | (EngineCore pid=114) ERROR 05-01 18:50:26 [core.py:1136]     model = model_class(vllm_config=vllm_config, prefix=prefix)
2026-05-01 20:50:26.797 | (EngineCore pid=114) ERROR 05-01 18:50:26 [core.py:1136]             ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
2026-05-01 20:50:26.797 | (EngineCore pid=114) ERROR 05-01 18:50:26 [core.py:1136]   File "/usr/local/lib/python3.12/dist-packages/vllm/model_executor/models/qwen3_5.py", line 834, in __init__
2026-05-01 20:50:26.797 | (EngineCore pid=114) ERROR 05-01 18:50:26 [core.py:1136]     self.language_model = Qwen3_5MoeForCausalLM(
2026-05-01 20:50:26.797 | (EngineCore pid=114) ERROR 05-01 18:50:26 [core.py:1136]                           ^^^^^^^^^^^^^^^^^^^^^^
2026-05-01 20:50:26.797 | (EngineCore pid=114) ERROR 05-01 18:50:26 [core.py:1136]   File "/usr/local/lib/python3.12/dist-packages/vllm/model_executor/models/qwen3_5.py", line 558, in __init__
2026-05-01 20:50:26.797 | (EngineCore pid=114) ERROR 05-01 18:50:26 [core.py:1136]     super().__init__(vllm_config=vllm_config, prefix=prefix)
2026-05-01 20:50:26.797 | (EngineCore pid=114) ERROR 05-01 18:50:26 [core.py:1136]   File "/usr/local/lib/python3.12/dist-packages/vllm/model_executor/models/qwen3_5.py", line 484, in __init__
2026-05-01 20:50:26.797 | (EngineCore pid=114) ERROR 05-01 18:50:26 [core.py:1136]     self.model = Qwen3_5Model(
2026-05-01 20:50:26.797 | (EngineCore pid=114) ERROR 05-01 18:50:26 [core.py:1136]                  ^^^^^^^^^^^^^
2026-05-01 20:50:26.797 | (EngineCore pid=114) ERROR 05-01 18:50:26 [core.py:1136]   File "/usr/local/lib/python3.12/dist-packages/vllm/compilation/decorators.py", line 379, in __init__
2026-05-01 20:50:26.797 | (EngineCore pid=114) ERROR 05-01 18:50:26 [core.py:1136]     old_init(self, *args, **kwargs)
2026-05-01 20:50:26.797 | (EngineCore pid=114) ERROR 05-01 18:50:26 [core.py:1136]   File "/usr/local/lib/python3.12/dist-packages/vllm/model_executor/models/qwen3_5.py", line 236, in __init__
2026-05-01 20:50:26.797 | (EngineCore pid=114) ERROR 05-01 18:50:26 [core.py:1136]     self.start_layer, self.end_layer, self.layers = make_layers(
2026-05-01 20:50:26.797 | (EngineCore pid=114) ERROR 05-01 18:50:26 [core.py:1136]                                                     ^^^^^^^^^^^^
2026-05-01 20:50:26.797 | (EngineCore pid=114) ERROR 05-01 18:50:26 [core.py:1136]   File "/usr/local/lib/python3.12/dist-packages/vllm/model_executor/models/utils.py", line 646, in make_layers
2026-05-01 20:50:26.797 | (EngineCore pid=114) ERROR 05-01 18:50:26 [core.py:1136]     + get_offloader().wrap_modules(
2026-05-01 20:50:26.797 | (EngineCore pid=114) ERROR 05-01 18:50:26 [core.py:1136]       ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
2026-05-01 20:50:26.797 | (EngineCore pid=114) ERROR 05-01 18:50:26 [core.py:1136]   File "/usr/local/lib/python3.12/dist-packages/vllm/model_executor/offloader/base.py", line 104, in wrap_modules
2026-05-01 20:50:26.797 | (EngineCore pid=114) ERROR 05-01 18:50:26 [core.py:1136]     return list(modules_generator)
2026-05-01 20:50:26.797 | (EngineCore pid=114) ERROR 05-01 18:50:26 [core.py:1136]            ^^^^^^^^^^^^^^^^^^^^^^^
2026-05-01 20:50:26.797 | (EngineCore pid=114) ERROR 05-01 18:50:26 [core.py:1136]   File "/usr/local/lib/python3.12/dist-packages/vllm/model_executor/models/utils.py", line 647, in <genexpr>
2026-05-01 20:50:26.797 | (EngineCore pid=114) ERROR 05-01 18:50:26 [core.py:1136]     layer_fn(prefix=f"{prefix}.{idx}") for idx in range(start_layer, end_layer)
2026-05-01 20:50:26.797 | (EngineCore pid=114) ERROR 05-01 18:50:26 [core.py:1136]     ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
2026-05-01 20:50:26.797 | (EngineCore pid=114) ERROR 05-01 18:50:26 [core.py:1136]   File "/usr/local/lib/python3.12/dist-packages/vllm/model_executor/models/qwen3_5.py", line 230, in get_layer
2026-05-01 20:50:26.797 | (EngineCore pid=114) ERROR 05-01 18:50:26 [core.py:1136]     return Qwen3_5DecoderLayer(
2026-05-01 20:50:26.797 | (EngineCore pid=114) ERROR 05-01 18:50:26 [core.py:1136]            ^^^^^^^^^^^^^^^^^^^^
2026-05-01 20:50:26.797 | (EngineCore pid=114) ERROR 05-01 18:50:26 [core.py:1136]   File "/usr/local/lib/python3.12/dist-packages/vllm/model_executor/models/qwen3_5.py", line 157, in __init__
2026-05-01 20:50:26.797 | (EngineCore pid=114) ERROR 05-01 18:50:26 [core.py:1136]     self.mlp = Qwen3NextSparseMoeBlock(
2026-05-01 20:50:26.797 | (EngineCore pid=114) ERROR 05-01 18:50:26 [core.py:1136]                ^^^^^^^^^^^^^^^^^^^^^^^^
2026-05-01 20:50:26.797 | (EngineCore pid=114) ERROR 05-01 18:50:26 [core.py:1136]   File "/usr/local/lib/python3.12/dist-packages/vllm/model_executor/models/qwen3_next.py", line 152, in __init__
2026-05-01 20:50:26.797 | (EngineCore pid=114) ERROR 05-01 18:50:26 [core.py:1136]     self.experts = FusedMoE(
2026-05-01 20:50:26.797 | (EngineCore pid=114) ERROR 05-01 18:50:26 [core.py:1136]                    ^^^^^^^^^
2026-05-01 20:50:26.797 | (EngineCore pid=114) ERROR 05-01 18:50:26 [core.py:1136]   File "/usr/local/lib/python3.12/dist-packages/vllm/model_executor/layers/fused_moe/layer.py", line 539, in __init__
2026-05-01 20:50:26.797 | (EngineCore pid=114) ERROR 05-01 18:50:26 [core.py:1136]     self.quant_method: FusedMoEMethodBase = _get_quant_method()
2026-05-01 20:50:26.797 | (EngineCore pid=114) ERROR 05-01 18:50:26 [core.py:1136]                                             ^^^^^^^^^^^^^^^^^^^
2026-05-01 20:50:26.797 | (EngineCore pid=114) ERROR 05-01 18:50:26 [core.py:1136]   File "/usr/local/lib/python3.12/dist-packages/vllm/model_executor/layers/fused_moe/layer.py", line 531, in _get_quant_method
2026-05-01 20:50:26.797 | (EngineCore pid=114) ERROR 05-01 18:50:26 [core.py:1136]     quant_method = self.quant_config.get_quant_method(self, prefix)
2026-05-01 20:50:26.797 | (EngineCore pid=114) ERROR 05-01 18:50:26 [core.py:1136]                    ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
2026-05-01 20:50:26.797 | (EngineCore pid=114) ERROR 05-01 18:50:26 [core.py:1136]   File "/usr/local/lib/python3.12/dist-packages/vllm/model_executor/layers/quantization/compressed_tensors/compressed_tensors.py", line 196, in get_quant_method
2026-05-01 20:50:26.797 | (EngineCore pid=114) ERROR 05-01 18:50:26 [core.py:1136]     return CompressedTensorsMoEMethod.get_moe_method(
2026-05-01 20:50:26.797 | (EngineCore pid=114) ERROR 05-01 18:50:26 [core.py:1136]            ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
2026-05-01 20:50:26.797 | (EngineCore pid=114) ERROR 05-01 18:50:26 [core.py:1136]   File "/usr/local/lib/python3.12/dist-packages/vllm/model_executor/layers/quantization/compressed_tensors/compressed_tensors_moe/compressed_tensors_moe.py", line 139, in get_moe_method
2026-05-01 20:50:26.797 | (EngineCore pid=114) ERROR 05-01 18:50:26 [core.py:1136]     return CompressedTensorsW4A4Nvfp4MoEMethod(
2026-05-01 20:50:26.797 | (EngineCore pid=114) ERROR 05-01 18:50:26 [core.py:1136]            ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
2026-05-01 20:50:26.797 | (EngineCore pid=114) ERROR 05-01 18:50:26 [core.py:1136]   File "/usr/local/lib/python3.12/dist-packages/vllm/model_executor/layers/quantization/compressed_tensors/compressed_tensors_moe/compressed_tensors_moe_w4a4_nvfp4.py", line 47, in __init__
2026-05-01 20:50:26.797 | (EngineCore pid=114) ERROR 05-01 18:50:26 [core.py:1136]     self.nvfp4_backend, self.experts_cls = select_nvfp4_moe_backend(
2026-05-01 20:50:26.797 | (EngineCore pid=114) ERROR 05-01 18:50:26 [core.py:1136]                                            ^^^^^^^^^^^^^^^^^^^^^^^^^
2026-05-01 20:50:26.797 | (EngineCore pid=114) ERROR 05-01 18:50:26 [core.py:1136]   File "/usr/local/lib/python3.12/dist-packages/vllm/model_executor/layers/fused_moe/oracle/nvfp4.py", line 217, in select_nvfp4_moe_backend
2026-05-01 20:50:26.797 | (EngineCore pid=114) ERROR 05-01 18:50:26 [core.py:1136]     requested_backend = map_nvfp4_backend(runner_backend)
2026-05-01 20:50:26.797 | (EngineCore pid=114) ERROR 05-01 18:50:26 [core.py:1136]                         ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
2026-05-01 20:50:26.797 | (EngineCore pid=114) ERROR 05-01 18:50:26 [core.py:1136]   File "/usr/local/lib/python3.12/dist-packages/vllm/model_executor/layers/fused_moe/oracle/nvfp4.py", line 144, in map_nvfp4_backend
2026-05-01 20:50:26.797 | (EngineCore pid=114) ERROR 05-01 18:50:26 [core.py:1136]     raise ValueError(
2026-05-01 20:50:26.797 | (EngineCore pid=114) ERROR 05-01 18:50:26 [core.py:1136] ValueError: moe_backend='triton' is not supported for NvFP4 MoE. Expected one of ['cutlass', 'flashinfer_trtllm', 'flashinfer_cutlass', 'flashinfer_cutedsl', 'marlin', 'emulation'].
2026-05-01 20:50:26.798 | (EngineCore pid=114) Traceback (most recent call last):
2026-05-01 20:50:26.798 | (EngineCore pid=114)   File "/usr/lib/python3.12/multiprocessing/process.py", line 314, in _bootstrap
2026-05-01 20:50:26.798 | (EngineCore pid=114)     self.run()
2026-05-01 20:50:26.798 | (EngineCore pid=114)   File "/usr/lib/python3.12/multiprocessing/process.py", line 108, in run
2026-05-01 20:50:26.798 | (EngineCore pid=114)     self._target(*self._args, **self._kwargs)
2026-05-01 20:50:26.798 | (EngineCore pid=114)   File "/usr/local/lib/python3.12/dist-packages/vllm/v1/engine/core.py", line 1140, in run_engine_core
2026-05-01 20:50:26.798 | (EngineCore pid=114)     raise e
2026-05-01 20:50:26.798 | (EngineCore pid=114)   File "/usr/local/lib/python3.12/dist-packages/vllm/v1/engine/core.py", line 1110, in run_engine_core
2026-05-01 20:50:26.798 | (EngineCore pid=114)     engine_core = EngineCoreProc(*args, engine_index=dp_rank, **kwargs)
2026-05-01 20:50:26.798 | (EngineCore pid=114)                   ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
2026-05-01 20:50:26.798 | (EngineCore pid=114)   File "/usr/local/lib/python3.12/dist-packages/vllm/tracing/otel.py", line 178, in sync_wrapper
2026-05-01 20:50:26.798 | (EngineCore pid=114)     return func(*args, **kwargs)
2026-05-01 20:50:26.798 | (EngineCore pid=114)            ^^^^^^^^^^^^^^^^^^^^^
2026-05-01 20:50:26.798 | (EngineCore pid=114)   File "/usr/local/lib/python3.12/dist-packages/vllm/v1/engine/core.py", line 876, in __init__
2026-05-01 20:50:26.798 | (EngineCore pid=114)     super().__init__(
2026-05-01 20:50:26.798 | (EngineCore pid=114)   File "/usr/local/lib/python3.12/dist-packages/vllm/v1/engine/core.py", line 118, in __init__
2026-05-01 20:50:26.798 | (EngineCore pid=114)     self.model_executor = executor_class(vllm_config)
2026-05-01 20:50:26.798 | (EngineCore pid=114)                           ^^^^^^^^^^^^^^^^^^^^^^^^^^^
2026-05-01 20:50:26.798 | (EngineCore pid=114)   File "/usr/local/lib/python3.12/dist-packages/vllm/tracing/otel.py", line 178, in sync_wrapper
2026-05-01 20:50:26.798 | (EngineCore pid=114)     return func(*args, **kwargs)
2026-05-01 20:50:26.798 | (EngineCore pid=114)            ^^^^^^^^^^^^^^^^^^^^^
2026-05-01 20:50:26.798 | (EngineCore pid=114)   File "/usr/local/lib/python3.12/dist-packages/vllm/v1/executor/abstract.py", line 109, in __init__
2026-05-01 20:50:26.798 | (EngineCore pid=114)     self._init_executor()
2026-05-01 20:50:26.798 | (EngineCore pid=114)   File "/usr/local/lib/python3.12/dist-packages/vllm/v1/executor/uniproc_executor.py", line 52, in _init_executor
2026-05-01 20:50:26.798 | (EngineCore pid=114)     self.driver_worker.load_model()
2026-05-01 20:50:26.798 | (EngineCore pid=114)   File "/usr/local/lib/python3.12/dist-packages/vllm/v1/worker/gpu_worker.py", line 323, in load_model
2026-05-01 20:50:26.798 | (EngineCore pid=114)     self.model_runner.load_model(load_dummy_weights=load_dummy_weights)
2026-05-01 20:50:26.798 | (EngineCore pid=114)   File "/usr/local/lib/python3.12/dist-packages/vllm/tracing/otel.py", line 178, in sync_wrapper
2026-05-01 20:50:26.798 | (EngineCore pid=114)     return func(*args, **kwargs)
2026-05-01 20:50:26.798 | (EngineCore pid=114)            ^^^^^^^^^^^^^^^^^^^^^
2026-05-01 20:50:26.798 | (EngineCore pid=114)   File "/usr/local/lib/python3.12/dist-packages/vllm/v1/worker/gpu_model_runner.py", line 4793, in load_model
2026-05-01 20:50:26.798 | (EngineCore pid=114)     self.model = model_loader.load_model(
2026-05-01 20:50:26.798 | (EngineCore pid=114)                  ^^^^^^^^^^^^^^^^^^^^^^^^
2026-05-01 20:50:26.798 | (EngineCore pid=114)   File "/usr/local/lib/python3.12/dist-packages/vllm/tracing/otel.py", line 178, in sync_wrapper
2026-05-01 20:50:26.798 | (EngineCore pid=114)     return func(*args, **kwargs)
2026-05-01 20:50:26.798 | (EngineCore pid=114)            ^^^^^^^^^^^^^^^^^^^^^
2026-05-01 20:50:26.798 | (EngineCore pid=114)   File "/usr/local/lib/python3.12/dist-packages/vllm/model_executor/model_loader/base_loader.py", line 55, in load_model
2026-05-01 20:50:26.798 | (EngineCore pid=114)     model = initialize_model(
2026-05-01 20:50:26.798 | (EngineCore pid=114)             ^^^^^^^^^^^^^^^^^
2026-05-01 20:50:26.798 | (EngineCore pid=114)   File "/usr/local/lib/python3.12/dist-packages/vllm/tracing/otel.py", line 178, in sync_wrapper
2026-05-01 20:50:26.798 | (EngineCore pid=114)     return func(*args, **kwargs)
2026-05-01 20:50:26.798 | (EngineCore pid=114)            ^^^^^^^^^^^^^^^^^^^^^
2026-05-01 20:50:26.798 | (EngineCore pid=114)   File "/usr/local/lib/python3.12/dist-packages/vllm/model_executor/model_loader/utils.py", line 57, in initialize_model
2026-05-01 20:50:26.798 | (EngineCore pid=114)     model = model_class(vllm_config=vllm_config, prefix=prefix)
2026-05-01 20:50:26.798 | (EngineCore pid=114)             ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
2026-05-01 20:50:26.798 | (EngineCore pid=114)   File "/usr/local/lib/python3.12/dist-packages/vllm/model_executor/models/qwen3_5.py", line 834, in __init__
2026-05-01 20:50:26.798 | (EngineCore pid=114)     self.language_model = Qwen3_5MoeForCausalLM(
2026-05-01 20:50:26.798 | (EngineCore pid=114)                           ^^^^^^^^^^^^^^^^^^^^^^
2026-05-01 20:50:26.798 | (EngineCore pid=114)   File "/usr/local/lib/python3.12/dist-packages/vllm/model_executor/models/qwen3_5.py", line 558, in __init__
2026-05-01 20:50:26.798 | (EngineCore pid=114)     super().__init__(vllm_config=vllm_config, prefix=prefix)
2026-05-01 20:50:26.798 | (EngineCore pid=114)   File "/usr/local/lib/python3.12/dist-packages/vllm/model_executor/models/qwen3_5.py", line 484, in __init__
2026-05-01 20:50:26.798 | (EngineCore pid=114)     self.model = Qwen3_5Model(
2026-05-01 20:50:26.798 | (EngineCore pid=114)                  ^^^^^^^^^^^^^
2026-05-01 20:50:26.798 | (EngineCore pid=114)   File "/usr/local/lib/python3.12/dist-packages/vllm/compilation/decorators.py", line 379, in __init__
2026-05-01 20:50:26.798 | (EngineCore pid=114)     old_init(self, *args, **kwargs)
2026-05-01 20:50:26.798 | (EngineCore pid=114)   File "/usr/local/lib/python3.12/dist-packages/vllm/model_executor/models/qwen3_5.py", line 236, in __init__
2026-05-01 20:50:26.798 | (EngineCore pid=114)     self.start_layer, self.end_layer, self.layers = make_layers(
2026-05-01 20:50:26.798 | (EngineCore pid=114)                                                     ^^^^^^^^^^^^
2026-05-01 20:50:26.798 | (EngineCore pid=114)   File "/usr/local/lib/python3.12/dist-packages/vllm/model_executor/models/utils.py", line 646, in make_layers
2026-05-01 20:50:26.798 | (EngineCore pid=114)     + get_offloader().wrap_modules(
2026-05-01 20:50:26.798 | (EngineCore pid=114)       ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
2026-05-01 20:50:26.798 | (EngineCore pid=114)   File "/usr/local/lib/python3.12/dist-packages/vllm/model_executor/offloader/base.py", line 104, in wrap_modules
2026-05-01 20:50:26.798 | (EngineCore pid=114)     return list(modules_generator)
2026-05-01 20:50:26.798 | (EngineCore pid=114)            ^^^^^^^^^^^^^^^^^^^^^^^
2026-05-01 20:50:26.798 | (EngineCore pid=114)   File "/usr/local/lib/python3.12/dist-packages/vllm/model_executor/models/utils.py", line 647, in <genexpr>
2026-05-01 20:50:26.798 | (EngineCore pid=114)     layer_fn(prefix=f"{prefix}.{idx}") for idx in range(start_layer, end_layer)
2026-05-01 20:50:26.798 | (EngineCore pid=114)     ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
2026-05-01 20:50:26.798 | (EngineCore pid=114)   File "/usr/local/lib/python3.12/dist-packages/vllm/model_executor/models/qwen3_5.py", line 230, in get_layer
2026-05-01 20:50:26.798 | (EngineCore pid=114)     return Qwen3_5DecoderLayer(
2026-05-01 20:50:26.798 | (EngineCore pid=114)            ^^^^^^^^^^^^^^^^^^^^
2026-05-01 20:50:26.798 | (EngineCore pid=114)   File "/usr/local/lib/python3.12/dist-packages/vllm/model_executor/models/qwen3_5.py", line 157, in __init__
2026-05-01 20:50:26.798 | (EngineCore pid=114)     self.mlp = Qwen3NextSparseMoeBlock(
2026-05-01 20:50:26.798 | (EngineCore pid=114)                ^^^^^^^^^^^^^^^^^^^^^^^^
2026-05-01 20:50:26.798 | (EngineCore pid=114)   File "/usr/local/lib/python3.12/dist-packages/vllm/model_executor/models/qwen3_next.py", line 152, in __init__
2026-05-01 20:50:26.798 | (EngineCore pid=114)     self.experts = FusedMoE(
2026-05-01 20:50:26.798 | (EngineCore pid=114)                    ^^^^^^^^^
2026-05-01 20:50:26.798 | (EngineCore pid=114)   File "/usr/local/lib/python3.12/dist-packages/vllm/model_executor/layers/fused_moe/layer.py", line 539, in __init__
2026-05-01 20:50:26.798 | (EngineCore pid=114)     self.quant_method: FusedMoEMethodBase = _get_quant_method()
2026-05-01 20:50:26.798 | (EngineCore pid=114)                                             ^^^^^^^^^^^^^^^^^^^
2026-05-01 20:50:26.798 | (EngineCore pid=114)   File "/usr/local/lib/python3.12/dist-packages/vllm/model_executor/layers/fused_moe/layer.py", line 531, in _get_quant_method
2026-05-01 20:50:26.798 | (EngineCore pid=114)     quant_method = self.quant_config.get_quant_method(self, prefix)
2026-05-01 20:50:26.798 | (EngineCore pid=114)                    ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
2026-05-01 20:50:26.798 | (EngineCore pid=114)   File "/usr/local/lib/python3.12/dist-packages/vllm/model_executor/layers/quantization/compressed_tensors/compressed_tensors.py", line 196, in get_quant_method
2026-05-01 20:50:26.798 | (EngineCore pid=114)     return CompressedTensorsMoEMethod.get_moe_method(
2026-05-01 20:50:26.798 | (EngineCore pid=114)            ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
2026-05-01 20:50:26.798 | (EngineCore pid=114)   File "/usr/local/lib/python3.12/dist-packages/vllm/model_executor/layers/quantization/compressed_tensors/compressed_tensors_moe/compressed_tensors_moe.py", line 139, in get_moe_method
2026-05-01 20:50:26.798 | (EngineCore pid=114)     return CompressedTensorsW4A4Nvfp4MoEMethod(
2026-05-01 20:50:26.798 | (EngineCore pid=114)            ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
2026-05-01 20:50:26.798 | (EngineCore pid=114)   File "/usr/local/lib/python3.12/dist-packages/vllm/model_executor/layers/quantization/compressed_tensors/compressed_tensors_moe/compressed_tensors_moe_w4a4_nvfp4.py", line 47, in __init__
2026-05-01 20:50:26.798 | (EngineCore pid=114)     self.nvfp4_backend, self.experts_cls = select_nvfp4_moe_backend(
2026-05-01 20:50:26.798 | (EngineCore pid=114)                                            ^^^^^^^^^^^^^^^^^^^^^^^^^
2026-05-01 20:50:26.798 | (EngineCore pid=114)   File "/usr/local/lib/python3.12/dist-packages/vllm/model_executor/layers/fused_moe/oracle/nvfp4.py", line 217, in select_nvfp4_moe_backend
2026-05-01 20:50:26.798 | (EngineCore pid=114)     requested_backend = map_nvfp4_backend(runner_backend)
2026-05-01 20:50:26.798 | (EngineCore pid=114)                         ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
2026-05-01 20:50:26.798 | (EngineCore pid=114)   File "/usr/local/lib/python3.12/dist-packages/vllm/model_executor/layers/fused_moe/oracle/nvfp4.py", line 144, in map_nvfp4_backend
2026-05-01 20:50:26.798 | (EngineCore pid=114)     raise ValueError(
2026-05-01 20:50:26.798 | (EngineCore pid=114) ValueError: moe_backend='triton' is not supported for NvFP4 MoE. Expected one of ['cutlass', 'flashinfer_trtllm', 'flashinfer_cutlass', 'flashinfer_cutedsl', 'marlin', 'emulation'].
2026-05-01 20:50:27.425 | [rank0]:[W501 18:50:27.769676287 ProcessGroupNCCL.cpp:1575] Warning: WARNING: destroy_process_group() was not called before program exit, which can leak resources. For more info, please see https://pytorch.org/docs/stable/distributed.html#shutdown (function operator())
2026-05-01 20:50:28.174 | (APIServer pid=1) Traceback (most recent call last):
2026-05-01 20:50:28.174 | (APIServer pid=1)   File "/usr/local/bin/vllm", line 10, in <module>
2026-05-01 20:50:28.174 | (APIServer pid=1)     sys.exit(main())
2026-05-01 20:50:28.174 | (APIServer pid=1)              ^^^^^^
2026-05-01 20:50:28.174 | (APIServer pid=1)   File "/usr/local/lib/python3.12/dist-packages/vllm/entrypoints/cli/main.py", line 92, in main
2026-05-01 20:50:28.174 | (APIServer pid=1)     args.dispatch_function(args)
2026-05-01 20:50:28.174 | (APIServer pid=1)   File "/usr/local/lib/python3.12/dist-packages/vllm/entrypoints/cli/serve.py", line 122, in cmd
2026-05-01 20:50:28.174 | (APIServer pid=1)     uvloop.run(run_server(args))
2026-05-01 20:50:28.175 | (APIServer pid=1)   File "/usr/local/lib/python3.12/dist-packages/uvloop/__init__.py", line 96, in run
2026-05-01 20:50:28.175 | (APIServer pid=1)     return __asyncio.run(
2026-05-01 20:50:28.175 | (APIServer pid=1)            ^^^^^^^^^^^^^^
2026-05-01 20:50:28.175 | (APIServer pid=1)   File "/usr/lib/python3.12/asyncio/runners.py", line 194, in run
2026-05-01 20:50:28.175 | (APIServer pid=1)     return runner.run(main)
2026-05-01 20:50:28.175 | (APIServer pid=1)            ^^^^^^^^^^^^^^^^
2026-05-01 20:50:28.175 | (APIServer pid=1)   File "/usr/lib/python3.12/asyncio/runners.py", line 118, in run
2026-05-01 20:50:28.175 | (APIServer pid=1)     return self._loop.run_until_complete(task)
2026-05-01 20:50:28.175 | (APIServer pid=1)            ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
2026-05-01 20:50:28.175 | (APIServer pid=1)   File "uvloop/loop.pyx", line 1518, in uvloop.loop.Loop.run_until_complete
2026-05-01 20:50:28.175 | (APIServer pid=1)   File "/usr/local/lib/python3.12/dist-packages/uvloop/__init__.py", line 48, in wrapper
2026-05-01 20:50:28.175 | (APIServer pid=1)     return await main
2026-05-01 20:50:28.175 | (APIServer pid=1)            ^^^^^^^^^^
2026-05-01 20:50:28.175 | (APIServer pid=1)   File "/usr/local/lib/python3.12/dist-packages/vllm/entrypoints/openai/api_server.py", line 678, in run_server
2026-05-01 20:50:28.175 | (APIServer pid=1)     await run_server_worker(listen_address, sock, args, **uvicorn_kwargs)
2026-05-01 20:50:28.175 | (APIServer pid=1)   File "/usr/local/lib/python3.12/dist-packages/vllm/entrypoints/openai/api_server.py", line 692, in run_server_worker
2026-05-01 20:50:28.176 | (APIServer pid=1)     async with build_async_engine_client(
2026-05-01 20:50:28.176 | (APIServer pid=1)   File "/usr/lib/python3.12/contextlib.py", line 210, in __aenter__
2026-05-01 20:50:28.176 | (APIServer pid=1)     return await anext(self.gen)
2026-05-01 20:50:28.176 | (APIServer pid=1)            ^^^^^^^^^^^^^^^^^^^^^
2026-05-01 20:50:28.176 | (APIServer pid=1)   File "/usr/local/lib/python3.12/dist-packages/vllm/entrypoints/openai/api_server.py", line 100, in build_async_engine_client
2026-05-01 20:50:28.176 | (APIServer pid=1)     async with build_async_engine_client_from_engine_args(
2026-05-01 20:50:28.176 | (APIServer pid=1)   File "/usr/lib/python3.12/contextlib.py", line 210, in __aenter__
2026-05-01 20:50:28.176 | (APIServer pid=1)     return await anext(self.gen)
2026-05-01 20:50:28.176 | (APIServer pid=1)            ^^^^^^^^^^^^^^^^^^^^^
2026-05-01 20:50:28.176 | (APIServer pid=1)   File "/usr/local/lib/python3.12/dist-packages/vllm/entrypoints/openai/api_server.py", line 136, in build_async_engine_client_from_engine_args
2026-05-01 20:50:28.176 | (APIServer pid=1)     async_llm = AsyncLLM.from_vllm_config(
2026-05-01 20:50:28.176 | (APIServer pid=1)                 ^^^^^^^^^^^^^^^^^^^^^^^^^^
2026-05-01 20:50:28.176 | (APIServer pid=1)   File "/usr/local/lib/python3.12/dist-packages/vllm/v1/engine/async_llm.py", line 217, in from_vllm_config
2026-05-01 20:50:28.176 | (APIServer pid=1)     return cls(
2026-05-01 20:50:28.176 | (APIServer pid=1)            ^^^^
2026-05-01 20:50:28.176 | (APIServer pid=1)   File "/usr/local/lib/python3.12/dist-packages/vllm/v1/engine/async_llm.py", line 146, in __init__
2026-05-01 20:50:28.176 | (APIServer pid=1)     self.engine_core = EngineCoreClient.make_async_mp_client(
2026-05-01 20:50:28.176 | (APIServer pid=1)                        ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
2026-05-01 20:50:28.176 | (APIServer pid=1)   File "/usr/local/lib/python3.12/dist-packages/vllm/tracing/otel.py", line 178, in sync_wrapper
2026-05-01 20:50:28.176 | (APIServer pid=1)     return func(*args, **kwargs)
2026-05-01 20:50:28.176 | (APIServer pid=1)            ^^^^^^^^^^^^^^^^^^^^^
2026-05-01 20:50:28.176 | (APIServer pid=1)   File "/usr/local/lib/python3.12/dist-packages/vllm/v1/engine/core_client.py", line 130, in make_async_mp_client
2026-05-01 20:50:28.176 | (APIServer pid=1)     return AsyncMPClient(*client_args)
2026-05-01 20:50:28.176 | (APIServer pid=1)            ^^^^^^^^^^^^^^^^^^^^^^^^^^^
2026-05-01 20:50:28.176 | (APIServer pid=1)   File "/usr/local/lib/python3.12/dist-packages/vllm/tracing/otel.py", line 178, in sync_wrapper
2026-05-01 20:50:28.176 | (APIServer pid=1)     return func(*args, **kwargs)
2026-05-01 20:50:28.176 | (APIServer pid=1)            ^^^^^^^^^^^^^^^^^^^^^
2026-05-01 20:50:28.176 | (APIServer pid=1)   File "/usr/local/lib/python3.12/dist-packages/vllm/v1/engine/core_client.py", line 900, in __init__
2026-05-01 20:50:28.176 | (APIServer pid=1)     super().__init__(
2026-05-01 20:50:28.176 | (APIServer pid=1)   File "/usr/local/lib/python3.12/dist-packages/vllm/v1/engine/core_client.py", line 535, in __init__
2026-05-01 20:50:28.177 | (APIServer pid=1)     with launch_core_engines(
2026-05-01 20:50:28.177 | (APIServer pid=1)   File "/usr/lib/python3.12/contextlib.py", line 144, in __exit__
2026-05-01 20:50:28.177 | (APIServer pid=1)     next(self.gen)
2026-05-01 20:50:28.177 | (APIServer pid=1)   File "/usr/local/lib/python3.12/dist-packages/vllm/v1/engine/utils.py", line 1119, in launch_core_engines
2026-05-01 20:50:28.177 | (APIServer pid=1)     wait_for_engine_startup(
2026-05-01 20:50:28.177 | (APIServer pid=1)   File "/usr/local/lib/python3.12/dist-packages/vllm/v1/engine/utils.py", line 1178, in wait_for_engine_startup
2026-05-01 20:50:28.177 | (APIServer pid=1)     raise RuntimeError(
2026-05-01 20:50:28.177 | (APIServer pid=1) RuntimeError: Engine core initialization failed. See root cause above. Failed core proc(s): {}
2026-05-01 20:50:36.488 | WARNING 05-01 18:50:36 [interface.py:686] Using 'pin_memory=False' as WSL is detected. This may slow down the performance.
2026-05-01 20:50:36.538 | WARNING 05-01 18:50:36 [argparse_utils.py:257] With `vllm serve`, you should provide the model as a positional argument or in a config file instead of via the `--model` option. The `--model` option will be removed in a future version.
2026-05-01 20:50:36.540 | (APIServer pid=1) INFO 05-01 18:50:36 [utils.py:299] 
2026-05-01 20:50:36.540 | (APIServer pid=1) INFO 05-01 18:50:36 [utils.py:299]        █     █     █▄   ▄█
2026-05-01 20:50:36.540 | (APIServer pid=1) INFO 05-01 18:50:36 [utils.py:299]  ▄▄ ▄█ █     █     █ ▀▄▀ █  version 0.20.0
2026-05-01 20:50:36.540 | (APIServer pid=1) INFO 05-01 18:50:36 [utils.py:299]   █▄█▀ █     █     █     █  model   RedHatAI/Qwen3.6-35B-A3B-NVFP4
2026-05-01 20:50:36.540 | (APIServer pid=1) INFO 05-01 18:50:36 [utils.py:299]    ▀▀  ▀▀▀▀▀ ▀▀▀▀▀ ▀     ▀
2026-05-01 20:50:36.540 | (APIServer pid=1) INFO 05-01 18:50:36 [utils.py:299] 
2026-05-01 20:50:36.543 | (APIServer pid=1) INFO 05-01 18:50:36 [utils.py:233] non-default args: {'model_tag': 'RedHatAI/Qwen3.6-35B-A3B-NVFP4', 'tool_call_parser': 'qwen3_coder', 'host': '0.0.0.0', 'model': 'RedHatAI/Qwen3.6-35B-A3B-NVFP4', 'trust_remote_code': True, 'max_model_len': 8192, 'quantization': 'compressed-tensors', 'enforce_eager': True, 'served_model_name': ['RedHatAI/Qwen3.6-35B-A3B-NVFP4'], 'reasoning_parser': 'qwen3', 'gpu_memory_utilization': 0.8, 'kv_cache_dtype': 'fp8_e4m3', 'enable_prefix_caching': True, 'max_num_batched_tokens': 8192, 'max_num_seqs': 32, 'enable_chunked_prefill': True, 'moe_backend': 'triton'}
2026-05-01 20:50:36.544 | (APIServer pid=1) WARNING 05-01 18:50:36 [envs.py:1818] Unknown vLLM environment variable detected: VLLM_FLASHINFER_CHECK_SAFE_OPS
2026-05-01 20:50:36.701 | (APIServer pid=1) Warning: You are sending unauthenticated requests to the HF Hub. Please set a HF_TOKEN to enable higher rate limits and faster downloads.
2026-05-01 20:50:37.560 | (APIServer pid=1) INFO 05-01 18:50:37 [model.py:555] Resolved architecture: Qwen3_5MoeForConditionalGeneration
2026-05-01 20:50:37.560 | (APIServer pid=1) INFO 05-01 18:50:37 [model.py:1680] Using max model len 8192
2026-05-01 20:50:38.310 | (APIServer pid=1) INFO 05-01 18:50:38 [nixl_utils.py:20] Setting UCX_RCACHE_MAX_UNRELEASED to '1024' to avoid a rare memory leak in UCX when using NIXL.
2026-05-01 20:50:38.342 | (APIServer pid=1) INFO 05-01 18:50:38 [nixl_utils.py:32] NIXL is available
2026-05-01 20:50:38.773 | (APIServer pid=1) INFO 05-01 18:50:38 [cache.py:261] Using fp8_e4m3 data type to store kv cache. It reduces the GPU memory footprint and boosts the performance. Meanwhile, it may cause accuracy drop without a proper scaling factor
2026-05-01 20:50:38.773 | (APIServer pid=1) INFO 05-01 18:50:38 [scheduler.py:239] Chunked prefill is enabled with max_num_batched_tokens=8192.
2026-05-01 20:50:38.774 | (APIServer pid=1) WARNING 05-01 18:50:38 [config.py:367] Mamba cache mode is set to 'align' for Qwen3_5MoeForConditionalGeneration by default when prefix caching is enabled
2026-05-01 20:50:38.774 | (APIServer pid=1) INFO 05-01 18:50:38 [config.py:387] Warning: Prefix caching in Mamba cache 'align' mode is currently enabled. Its support for Mamba layers is experimental. Please report any issues you may observe.
2026-05-01 20:50:38.774 | (APIServer pid=1) INFO 05-01 18:50:38 [vllm.py:840] Asynchronous scheduling is enabled.
2026-05-01 20:50:38.774 | (APIServer pid=1) WARNING 05-01 18:50:38 [vllm.py:896] Enforce eager set, disabling torch.compile and CUDAGraphs. This is equivalent to setting -cc.mode=none -cc.cudagraph_mode=none
2026-05-01 20:50:38.774 | (APIServer pid=1) WARNING 05-01 18:50:38 [vllm.py:914] Inductor compilation was disabled by user settings, optimizations settings that are only active during inductor compilation will be ignored.
2026-05-01 20:50:38.774 | (APIServer pid=1) INFO 05-01 18:50:38 [kernel.py:205] Final IR op priority after setting platform defaults: IrOpPriorityConfig(rms_norm=['vllm_c', 'native'])
2026-05-01 20:50:38.774 | (APIServer pid=1) INFO 05-01 18:50:38 [vllm.py:1089] Cudagraph is disabled under eager mode
2026-05-01 20:50:41.790 | (APIServer pid=1) Traceback (most recent call last):
2026-05-01 20:50:41.790 | (APIServer pid=1)   File "/usr/local/bin/vllm", line 10, in <module>
2026-05-01 20:50:41.793 | (APIServer pid=1)     sys.exit(main())
2026-05-01 20:50:41.793 | (APIServer pid=1)              ^^^^^^
2026-05-01 20:50:41.793 | (APIServer pid=1)   File "/usr/local/lib/python3.12/dist-packages/vllm/entrypoints/cli/main.py", line 92, in main
2026-05-01 20:50:41.793 | (APIServer pid=1)     args.dispatch_function(args)
2026-05-01 20:50:41.793 | (APIServer pid=1)   File "/usr/local/lib/python3.12/dist-packages/vllm/entrypoints/cli/serve.py", line 122, in cmd
2026-05-01 20:50:41.793 | (APIServer pid=1)     uvloop.run(run_server(args))
2026-05-01 20:50:41.793 | (APIServer pid=1)   File "/usr/local/lib/python3.12/dist-packages/uvloop/__init__.py", line 96, in run
2026-05-01 20:50:41.793 | (APIServer pid=1)     return __asyncio.run(
2026-05-01 20:50:41.793 | (APIServer pid=1)            ^^^^^^^^^^^^^^
2026-05-01 20:50:41.793 | (APIServer pid=1)   File "/usr/lib/python3.12/asyncio/runners.py", line 194, in run
2026-05-01 20:50:41.793 | (APIServer pid=1)     return runner.run(main)
2026-05-01 20:50:41.793 | (APIServer pid=1)            ^^^^^^^^^^^^^^^^
2026-05-01 20:50:41.793 | (APIServer pid=1)   File "/usr/lib/python3.12/asyncio/runners.py", line 118, in run
2026-05-01 20:50:41.793 | (APIServer pid=1)     return self._loop.run_until_complete(task)
2026-05-01 20:50:41.793 | (APIServer pid=1)            ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
2026-05-01 20:50:41.793 | (APIServer pid=1)   File "uvloop/loop.pyx", line 1512, in uvloop.loop.Loop.run_until_complete
2026-05-01 20:50:41.794 | (APIServer pid=1)   File "uvloop/loop.pyx", line 1505, in uvloop.loop.Loop.run_until_complete
2026-05-01 20:50:41.794 | (APIServer pid=1)   File "uvloop/loop.pyx", line 1379, in uvloop.loop.Loop.run_forever
2026-05-01 20:50:41.794 | (APIServer pid=1)   File "uvloop/loop.pyx", line 557, in uvloop.loop.Loop._run
2026-05-01 20:50:41.794 | (APIServer pid=1)   File "uvloop/loop.pyx", line 476, in uvloop.loop.Loop._on_idle
2026-05-01 20:50:41.794 | (APIServer pid=1)   File "uvloop/cbhandles.pyx", line 83, in uvloop.loop.Handle._run
2026-05-01 20:50:41.794 | (APIServer pid=1)   File "uvloop/cbhandles.pyx", line 61, in uvloop.loop.Handle._run
2026-05-01 20:50:41.794 | (APIServer pid=1)   File "/usr/local/lib/python3.12/dist-packages/uvloop/__init__.py", line 48, in wrapper
2026-05-01 20:50:41.794 | (APIServer pid=1)     return await main
2026-05-01 20:50:41.794 | (APIServer pid=1)            ^^^^^^^^^^
2026-05-01 20:50:41.794 | (APIServer pid=1)   File "/usr/local/lib/python3.12/dist-packages/vllm/entrypoints/openai/api_server.py", line 678, in run_server
2026-05-01 20:50:41.794 | (APIServer pid=1)     await run_server_worker(listen_address, sock, args, **uvicorn_kwargs)
2026-05-01 20:50:41.794 | (APIServer pid=1)   File "/usr/local/lib/python3.12/dist-packages/vllm/entrypoints/openai/api_server.py", line 692, in run_server_worker
2026-05-01 20:50:41.794 | (APIServer pid=1)     async with build_async_engine_client(
2026-05-01 20:50:41.794 | (APIServer pid=1)   File "/usr/lib/python3.12/contextlib.py", line 210, in __aenter__
2026-05-01 20:50:41.794 | (APIServer pid=1)     return await anext(self.gen)
2026-05-01 20:50:41.795 | (APIServer pid=1)            ^^^^^^^^^^^^^^^^^^^^^
2026-05-01 20:50:41.795 | (APIServer pid=1)   File "/usr/local/lib/python3.12/dist-packages/vllm/entrypoints/openai/api_server.py", line 100, in build_async_engine_client
2026-05-01 20:50:41.795 | (APIServer pid=1)     async with build_async_engine_client_from_engine_args(
2026-05-01 20:50:41.795 | (APIServer pid=1)   File "/usr/lib/python3.12/contextlib.py", line 210, in __aenter__
2026-05-01 20:50:41.795 | (APIServer pid=1)     return await anext(self.gen)
2026-05-01 20:50:41.795 | (APIServer pid=1)            ^^^^^^^^^^^^^^^^^^^^^
2026-05-01 20:50:41.795 | (APIServer pid=1)   File "/usr/local/lib/python3.12/dist-packages/vllm/entrypoints/openai/api_server.py", line 124, in build_async_engine_client_from_engine_args
2026-05-01 20:50:41.795 | (APIServer pid=1)     vllm_config = engine_args.create_engine_config(usage_context=usage_context)
2026-05-01 20:50:41.795 | (APIServer pid=1)                   ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
2026-05-01 20:50:41.795 | (APIServer pid=1)   File "/usr/local/lib/python3.12/dist-packages/vllm/engine/arg_utils.py", line 2121, in create_engine_config
2026-05-01 20:50:41.795 | (APIServer pid=1)     config = VllmConfig(
2026-05-01 20:50:41.795 | (APIServer pid=1)              ^^^^^^^^^^^
2026-05-01 20:50:41.795 | (APIServer pid=1)   File "/usr/local/lib/python3.12/dist-packages/pydantic/_internal/_dataclasses.py", line 121, in __init__
2026-05-01 20:50:41.795 | (APIServer pid=1)     s.__pydantic_validator__.validate_python(ArgsKwargs(args, kwargs), self_instance=s)
2026-05-01 20:50:41.796 | (APIServer pid=1)   File "/usr/local/lib/python3.12/dist-packages/vllm/config/vllm.py", line 1246, in __post_init__
2026-05-01 20:50:41.796 | (APIServer pid=1)     self.reasoning_config.initialize_token_ids(self.model_config)
2026-05-01 20:50:41.796 | (APIServer pid=1)   File "/usr/local/lib/python3.12/dist-packages/vllm/config/reasoning.py", line 77, in initialize_token_ids
2026-05-01 20:50:41.796 | (APIServer pid=1)     parser_cls = ReasoningParserManager.get_reasoning_parser(
2026-05-01 20:50:41.796 | (APIServer pid=1)                  ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
2026-05-01 20:50:41.796 | (APIServer pid=1)   File "/usr/local/lib/python3.12/dist-packages/vllm/reasoning/abs_reasoning_parsers.py", line 218, in get_reasoning_parser
2026-05-01 20:50:41.796 | (APIServer pid=1)     return cls._load_lazy_parser(name)
2026-05-01 20:50:41.796 | (APIServer pid=1)            ^^^^^^^^^^^^^^^^^^^^^^^^^^^
2026-05-01 20:50:41.796 | (APIServer pid=1)   File "/usr/local/lib/python3.12/dist-packages/vllm/reasoning/abs_reasoning_parsers.py", line 235, in _load_lazy_parser
2026-05-01 20:50:41.796 | (APIServer pid=1)     mod = importlib.import_module(module_path)
2026-05-01 20:50:41.796 | (APIServer pid=1)           ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
2026-05-01 20:50:41.796 | (APIServer pid=1)   File "/usr/lib/python3.12/importlib/__init__.py", line 90, in import_module
2026-05-01 20:50:41.797 | (APIServer pid=1)     return _bootstrap._gcd_import(name[level:], package, level)
2026-05-01 20:50:41.797 | (APIServer pid=1)            ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
2026-05-01 20:50:41.797 | (APIServer pid=1)   File "<frozen importlib._bootstrap>", line 1387, in _gcd_import
2026-05-01 20:50:41.797 | (APIServer pid=1)   File "<frozen importlib._bootstrap>", line 1360, in _find_and_load
2026-05-01 20:50:41.797 | (APIServer pid=1)   File "<frozen importlib._bootstrap>", line 1331, in _find_and_load_unlocked
2026-05-01 20:50:41.797 | (APIServer pid=1)   File "<frozen importlib._bootstrap>", line 935, in _load_unlocked
2026-05-01 20:50:41.797 | (APIServer pid=1)   File "<frozen importlib._bootstrap_external>", line 991, in exec_module
2026-05-01 20:50:41.797 | (APIServer pid=1)   File "<frozen importlib._bootstrap_external>", line 1124, in get_code
2026-05-01 20:50:41.797 | (APIServer pid=1)   File "<frozen importlib._bootstrap_external>", line 753, in _compile_bytecode
2026-05-01 20:50:41.797 | (APIServer pid=1)   File "/usr/local/lib/python3.12/dist-packages/vllm/entrypoints/openai/api_server.py", line 564, in signal_handler
2026-05-01 20:50:41.797 | (APIServer pid=1)     raise KeyboardInterrupt("terminated")
2026-05-01 20:50:41.797 | (APIServer pid=1) KeyboardInterrupt: terminated