# Qwen3.6-27B-NVFP4 — First Startup Log (No MTP)

## docker-compose.yml

```yaml
services:
  qwen36-27b-nvfp4:
    image: vllm/vllm-openai:nightly
    container_name: qwen36-27b-nvfp4-nightly
    hostname: inference-server
    platform: linux/arm64
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
      VLLM_WORKER_MULTIPROC_METHOD: spawn
      PYTORCH_CUDA_ALLOC_CONF: "expandable_segments:True"
      HF_XET_HIGH_PERFORMANCE: "1"
      VLLM_USE_RUST_FRONTEND: "0"
    command:
      - "--model"
      - "nvidia/Qwen3.6-27B-NVFP4"
      - "--served-model-name"
      - "${INFERENCE_MODEL_ALIAS:-qwen3.6-27b}"
      - "--api-key"
      - "${INFERENCE_API_KEY:-dummy-key}"
      - "--trust-remote-code"
      - "--host"
      - "0.0.0.0"
      - "--port"
      - "${INFERENCE_SERVER_PORT:-8000}"
      - "--gpu-memory-utilization"
      - "0.70"
      - "--max-model-len"
      - "262144"
      - "--max-num-seqs"
      - "8"
      - "--max-num-batched-tokens"
      - "65536"
      - "--kv-cache-dtype"
      - "fp8"
      - "--dtype"
      - "auto"
      - "--quantization"
      - "modelopt"
      - "--reasoning-parser"
      - "qwen3"
      - "--tool-call-parser"
      - "qwen3_coder"
      - "--enable-auto-tool-choice"
      - "--enable-prefix-caching"
      - "--enable-chunked-prefill"
      - "--async-scheduling"
      - "--safetensors-load-strategy"
      - "prefetch"
    networks:
      - development-network
networks:
  development-network:
    external: true
```

## Experiment Notes

- **Model:** nvidia/Qwen3.6-27B-NVFP4
- **Hardware:** DGX Spark (Blackwell GB10, 128GB UMA)
- **Config:** dense 27B, NVFP4, no MTP, fp8 KV cache, 262K ctx, gpu-memory 0.70, max-num-seqs 8
- **Model load:** 19.78 GiB
- **Init time:** 443.17 s total (torch.compile 75.32 s, warmup 117.91 s)
- **KV cache:** 47.84 GiB (1,505,068 tokens, ~5.74x concurrency at 262K)
- **Throughput:** ~11–12 tok/s generation (single request, no MTP)

## vLLM Container Log

```
WARNING 07-02 21:27:15 [argparse_utils.py:257] With `vllm serve`, you should provide the model as a positional argument or in a config file instead of via the `--model` option. The `--model` option will be removed in a future version.
(APIServer pid=1) INFO 07-02 21:27:15 [api_utils.py:339] 
(APIServer pid=1) INFO 07-02 21:27:15 [api_utils.py:339]        █     █     █▄   ▄█
(APIServer pid=1) INFO 07-02 21:27:15 [api_utils.py:339]  ▄▄ ▄█ █     █     █ ▀▄▀ █  version 0.23.1rc1.dev531+ga65f93fb2
(APIServer pid=1) INFO 07-02 21:27:15 [api_utils.py:339]   █▄█▀ █     █     █     █  model   nvidia/Qwen3.6-27B-NVFP4
(APIServer pid=1) INFO 07-02 21:27:15 [api_utils.py:339]    ▀▀  ▀▀▀▀▀ ▀▀▀▀▀ ▀     ▀
(APIServer pid=1) INFO 07-02 21:27:15 [api_utils.py:339] 
(APIServer pid=1) INFO 07-02 21:27:15 [api_utils.py:273] non-default args: {'model_tag': 'nvidia/Qwen3.6-27B-NVFP4', 'enable_auto_tool_choice': True, 'tool_call_parser': 'qwen3_coder', 'host': '0.0.0.0', 'api_key': ['__REDACTED__'], 'model': 'nvidia/Qwen3.6-27B-NVFP4', 'trust_remote_code': True, 'max_model_len': 262144, 'quantization': 'modelopt', 'served_model_name': ['qwen3.6-27b'], 'safetensors_load_strategy': 'prefetch', 'reasoning_parser': 'qwen3', 'gpu_memory_utilization': 0.7, 'kv_cache_dtype': 'fp8', 'enable_prefix_caching': True, 'max_num_batched_tokens': 65536, 'max_num_seqs': 8, 'enable_chunked_prefill': True, 'async_scheduling': True}
(APIServer pid=1) WARNING 07-02 21:27:15 [envs.py:2027] Unknown vLLM environment variable detected: VLLM_BUILD_COMMIT
(APIServer pid=1) WARNING 07-02 21:27:15 [envs.py:2027] Unknown vLLM environment variable detected: VLLM_BUILD_PIPELINE
(APIServer pid=1) WARNING 07-02 21:27:15 [envs.py:2027] Unknown vLLM environment variable detected: VLLM_BUILD_URL
(APIServer pid=1) WARNING 07-02 21:27:15 [envs.py:2027] Unknown vLLM environment variable detected: VLLM_IMAGE_TAG
(APIServer pid=1) INFO 07-02 21:27:25 [model.py:601] Resolved architecture: Qwen3_5ForConditionalGeneration
(APIServer pid=1) INFO 07-02 21:27:25 [model.py:1727] Using max model len 262144
(APIServer pid=1) INFO 07-02 21:27:25 [cache.py:280] Using fp8 data type to store kv cache. It reduces the GPU memory footprint and boosts the performance. Meanwhile, it may cause accuracy drop without a proper scaling factor
(APIServer pid=1) INFO 07-02 21:27:25 [scheduler.py:252] Chunked prefill is enabled with max_num_batched_tokens=65536.
(APIServer pid=1) WARNING 07-02 21:27:25 [config.py:422] Mamba cache mode is set to 'align' for Qwen3_5ForConditionalGeneration by default when prefix caching is enabled
(APIServer pid=1) INFO 07-02 21:27:25 [config.py:442] Warning: Prefix caching in Mamba cache 'align' mode is currently enabled. Its support for Mamba layers is experimental. Please report any issues you may observe.
(APIServer pid=1) WARNING 07-02 21:27:25 [modelopt.py:384] Detected ModelOpt fp8 checkpoint (quant_algo=FP8). Please note that the format is experimental and could change.
(APIServer pid=1) WARNING 07-02 21:27:25 [modelopt.py:1028] Detected ModelOpt NVFP4 checkpoint (quant_algo=NVFP4). Please note that the format is experimental and could change in future.
(APIServer pid=1) WARNING 07-02 21:27:25 [modelopt.py:1028] Detected ModelOpt NVFP4 checkpoint (quant_algo=W4A16_NVFP4). Please note that the format is experimental and could change in future.
(APIServer pid=1) INFO 07-02 21:27:25 [vllm.py:1006] Asynchronous scheduling is enabled.
(APIServer pid=1) INFO 07-02 21:27:25 [kernel.py:278] Final IR op priority after setting platform defaults: IrOpPriorityConfig(rms_norm=['native'], fused_add_rms_norm=['native'])
(EngineCore pid=134) INFO 07-02 21:27:42 [core.py:114] Initializing a V1 LLM engine (v0.23.1rc1.dev531+ga65f93fb2) with config: model='nvidia/Qwen3.6-27B-NVFP4', speculative_config=None, tokenizer='nvidia/Qwen3.6-27B-NVFP4', skip_tokenizer_init=False, tokenizer_mode=auto, revision=None, tokenizer_revision=None, trust_remote_code=True, dtype=torch.bfloat16, max_seq_len=262144, download_dir=None, load_format=auto, tensor_parallel_size=1, pipeline_parallel_size=1, data_parallel_size=1, decode_context_parallel_size=1, dcp_comm_backend=ag_rs, disable_custom_all_reduce=False, quantization=modelopt_mixed, quantization_config=None, enforce_eager=False, enable_return_routed_experts=False, kv_cache_dtype=fp8, device_config=cuda, structured_outputs_config=StructuredOutputsConfig(backend='auto', disable_any_whitespace=False, disable_additional_properties=False, reasoning_parser='qwen3', reasoning_parser_plugin='', enable_in_reasoning=False), observability_config=ObservabilityConfig(show_hidden_metrics_for_version=None, otlp_traces_endpoint=None, collect_detailed_traces=None, kv_cache_metrics=False, kv_cache_metrics_sample=0.01, cudagraph_metrics=False, enable_layerwise_nvtx_tracing=False, enable_mfu_metrics=False, enable_mm_processor_stats=False, enable_logging_iteration_details=False, jit_monitor_mode='warn', jit_monitor_verbose=False), seed=0, served_model_name=qwen3.6-27b, enable_prefix_caching=True, enable_chunked_prefill=True, pooler_config=None, compilation_config={'mode': <CompilationMode.VLLM_COMPILE: 3>, 'debug_dump_path': None, 'cache_dir': '', 'compile_cache_save_format': 'binary', 'backend': 'inductor', 'custom_ops': ['none'], 'ir_enable_torch_wrap': True, 'splitting_ops': ['vllm::unified_attention_with_output', 'vllm::unified_mla_attention_with_output', 'vllm::mamba_mixer2', 'vllm::mamba_mixer', 'vllm::short_conv', 'vllm::linear_attention', 'vllm::plamo2_mamba_mixer', 'vllm::qwen_gdn_attention_core', 'vllm::gdn_attention_core_xpu', 'vllm::olmo_hybrid_gdn_full_forward', 'vllm::kda_attention', 'vllm::sparse_attn_indexer', 'vllm::rocm_aiter_sparse_attn_indexer', 'vllm::deepseek_v4_attention', 'vllm::unified_kv_cache_update', 'vllm::unified_mla_kv_cache_update'], 'compile_mm_encoder': False, 'cudagraph_mm_encoder': False, 'encoder_cudagraph_token_budgets': [], 'encoder_cudagraph_max_vision_items_per_batch': 0, 'encoder_cudagraph_max_frames_per_batch': None, 'compile_sizes': [], 'compile_ranges_endpoints': [65536], 'inductor_compile_config': {'enable_auto_functionalized_v2': False, 'size_asserts': False, 'alignment_asserts': False, 'scalar_asserts': False, 'combo_kernels': True, 'benchmark_combo_kernel': True}, 'inductor_passes': {}, 'cudagraph_mode': <CUDAGraphMode.FULL_AND_PIECEWISE: (2, 1)>, 'cudagraph_num_of_warmups': 1, 'cudagraph_capture_sizes': [1, 2, 4, 8, 16], 'cudagraph_copy_inputs': False, 'cudagraph_specialize_lora': True, 'use_inductor_graph_partition': False, 'pass_config': {'fuse_norm_quant': False, 'fuse_act_quant': False, 'fuse_attn_quant': False, 'enable_sp': False, 'fuse_gemm_comms': False, 'fuse_allreduce_rms': False, 'fuse_rope_kvcache_cat_mla': False, 'fuse_act_padding': False}, 'max_cudagraph_capture_size': 16, 'dynamic_shapes_config': {'type': <DynamicShapesType.BACKED: 'backed'>, 'evaluate_guards': False, 'assume_32_bit_indexing': False}, 'local_cache_dir': None, 'fast_moe_cold_start': False, 'static_all_moe_layers': []}, kernel_config=KernelConfig(ir_op_priority=IrOpPriorityConfig(rms_norm=['native'], fused_add_rms_norm=['native']), enable_flashinfer_autotune=True, moe_backend='auto', linear_backend='auto')
(EngineCore pid=134) INFO 07-02 21:27:44 [parallel_state.py:1588] world_size=1 rank=0 local_rank=0 distributed_init_method=tcp://172.18.0.2:47525 backend=nccl
(EngineCore pid=134) INFO 07-02 21:27:44 [parallel_state.py:1923] rank 0 in world size 1 is assigned as DP rank 0, PP rank 0, PCP rank 0, TP rank 0, EP rank N/A, EPLB rank N/A
(EngineCore pid=134) INFO 07-02 21:27:44 [topk_topp_sampler.py:55] Using FlashInfer for top-p & top-k sampling.
(EngineCore pid=134) INFO 07-02 21:27:53 [gpu_model_runner.py:5160] Starting to load model nvidia/Qwen3.6-27B-NVFP4...
(EngineCore pid=134) INFO 07-02 21:27:53 [cuda.py:542] Using backend AttentionBackendEnum.FLASH_ATTN for vit attention
(EngineCore pid=134) INFO 07-02 21:27:53 [mm_encoder_attention.py:373] Using AttentionBackendEnum.FLASH_ATTN for MMEncoderAttention.
(EngineCore pid=134) INFO 07-02 21:27:53 [__init__.py:594] Selected FlashInferFP8ScaledMMLinearKernel for ModelOptFp8LinearMethod
(EngineCore pid=134) INFO 07-02 21:27:53 [deep_gemm.py:175] deep_gemm not found in site-packages, trying vendored vllm.third_party.deep_gemm
(EngineCore pid=134) INFO 07-02 21:27:53 [deep_gemm.py:202] DeepGEMM PDL enabled on vllm.third_party.deep_gemm.
(EngineCore pid=134) INFO 07-02 21:27:53 [deep_gemm.py:120] DeepGEMM E8M0 enabled on current platform.
(EngineCore pid=134) INFO 07-02 21:27:53 [qwen_gdn_linear_attn.py:228] Using Triton/FLA GDN prefill kernel (requested=auto, head_k_dim=128).
(EngineCore pid=134) INFO 07-02 21:27:54 [cuda.py:483] Using FLASHINFER attention backend out of potential backends: ['FLASHINFER', 'TRITON_ATTN'].
(EngineCore pid=134) INFO 07-02 21:27:55 [weight_utils.py:849] Filesystem type for checkpoints: EXT4. Checkpoint size: 20.42 GiB. Available RAM: 88.21 GiB.
(EngineCore pid=134) INFO 07-02 21:27:55 [weight_utils.py:811] Prefetching checkpoint files into page cache started (in background, num_threads=8, block_size=16777216 bytes)
(EngineCore pid=134) INFO 07-02 21:27:55 [weight_utils.py:783] Prefetching checkpoint files: 10% (1/3)
(EngineCore pid=134) INFO 07-02 21:27:56 [weight_utils.py:783] Prefetching checkpoint files: 20% (2/3)
(EngineCore pid=134) INFO 07-02 21:27:56 [weight_utils.py:783] Prefetching checkpoint files: 30% (3/3)
(EngineCore pid=134) INFO 07-02 21:27:56 [weight_utils.py:806] Prefetching checkpoint files into page cache finished in 0.77s
(EngineCore pid=134) INFO 07-02 21:30:01 [default_loader.py:430] Loading weights took 125.41 seconds
(EngineCore pid=134) WARNING 07-02 21:30:01 [marlin.py:34] Your GPU does not have native support for FP4 computation but FP4 quantization is being used. Weight-only FP4 compression will be used leveraging the Marlin kernel. This may degrade performance for compute-heavy workloads.
(EngineCore pid=134) WARNING 07-02 21:30:01 [kv_cache.py:134] Checkpoint does not provide a q scaling factor. Setting it to k_scale. This only matters for FP8 Attention backends (flash-attn or flashinfer).
(EngineCore pid=134) WARNING 07-02 21:30:01 [kv_cache.py:148] Using KV cache scaling factor 1.0 for fp8_e4m3. If this is unintended, verify that k/v_scale scaling factors are properly set in the checkpoint.
(EngineCore pid=134) WARNING 07-02 21:30:01 [kv_cache.py:187] Using uncalibrated q_scale 1.0 and/or prob_scale 1.0 with fp8 attention. This may cause accuracy issues. Please make sure q/prob scaling factors are available in the fp8 checkpoint.
(EngineCore pid=134) INFO 07-02 21:30:03 [gpu_model_runner.py:5255] Model loading took 19.78 GiB memory and 129.689615 seconds
(EngineCore pid=134) INFO 07-02 21:30:03 [interface.py:773] Setting attention block size to 1568 tokens to ensure that attention page size is >= mamba page size.
(EngineCore pid=134) INFO 07-02 21:30:03 [interface.py:797] Padding mamba page size by 0.13% to ensure that mamba page size and attention page size are exactly equal.
(EngineCore pid=134) INFO 07-02 21:30:04 [gpu_model_runner.py:6271] Encoder cache will be initialized with a budget of 65536 tokens, and profiled with 4 image items of the maximum feature size.
(EngineCore pid=134) INFO 07-02 21:30:22 [backends.py:1089] Using cache directory: /root/.cache/vllm/torch_compile_cache/558c916507/rank_0_0/backbone for vLLM's torch.compile
(EngineCore pid=134) INFO 07-02 21:30:22 [backends.py:1148] Dynamo bytecode transform time: 10.78 s
(EngineCore pid=134) INFO 07-02 21:30:54 [backends.py:378] Cache the graph of compile range (1, 65536) for later use
(EngineCore pid=134) INFO 07-02 21:31:22 [backends.py:393] Compiling a graph for compile range (1, 65536) takes 59.23 s
(EngineCore pid=134) INFO 07-02 21:31:27 [decorators.py:708] saved AOT compiled function to /root/.cache/vllm/torch_compile_cache/torch_aot_compile/ce7de4a40d3b350e07021d004ce66b28f92a053110b11bfd9554ccb0b0698f3e/rank_0_0/model
(EngineCore pid=134) INFO 07-02 21:31:27 [monitor.py:53] torch.compile took 75.32 s in total
(EngineCore pid=134) INFO 07-02 21:33:25 [monitor.py:81] Initial profiling/warmup run took 117.91 s
(EngineCore pid=134) INFO 07-02 21:33:29 [gpu_model_runner.py:6483] Profiling CUDA graph memory: PIECEWISE=5 (largest=16), FULL=4 (largest=8)
(EngineCore pid=134) INFO 07-02 21:33:32 [gpu_model_runner.py:6588] Estimated CUDA graph memory: 0.61 GiB total
(EngineCore pid=134) INFO 07-02 21:33:32 [gpu_worker.py:515] Available KV cache memory: 47.84 GiB
(EngineCore pid=134) INFO 07-02 21:33:32 [gpu_worker.py:530] CUDA graph memory profiling is enabled (default since v0.21.0). The current --gpu-memory-utilization=0.7000 is equivalent to --gpu-memory-utilization=0.6950 without CUDA graph memory profiling. To maintain the same effective KV cache size as before, increase --gpu-memory-utilization to 0.7050. To disable, set VLLM_MEMORY_PROFILER_ESTIMATE_CUDAGRAPHS=0.
(EngineCore pid=134) INFO 07-02 21:33:32 [kv_cache_utils.py:2146] GPU KV cache size: 1,505,068 tokens
(EngineCore pid=134) INFO 07-02 21:33:32 [kv_cache_utils.py:2147] Maximum concurrency for 262,144 tokens per request: 5.74x
(EngineCore pid=134) cudnn_handle created for device_id = 0
(EngineCore pid=134) 
(EngineCore pid=134) INFO 07-02 21:37:26 [gpu_model_runner.py:6656] Graph capturing finished in 3 secs, took 0.62 GiB
(EngineCore pid=134) INFO 07-02 21:37:26 [gpu_worker.py:748] CUDA graph pool memory: 0.62 GiB (actual), 0.61 GiB (estimated), difference: 0.02 GiB (2.7%).
(EngineCore pid=134) INFO 07-02 21:37:26 [jit_monitor.py:71] Kernel JIT monitor activated; monitored JIT compilations during inference will use mode=warn.
(EngineCore pid=134) INFO 07-02 21:37:27 [core.py:337] init engine (profile, create kv cache, warmup model) took 443.17 s (compilation: 75.32 s)
(EngineCore pid=134) INFO 07-02 21:37:27 [vllm.py:1006] Asynchronous scheduling is enabled.
(EngineCore pid=134) INFO 07-02 21:37:27 [kernel.py:278] Final IR op priority after setting platform defaults: IrOpPriorityConfig(rms_norm=['native'], fused_add_rms_norm=['native'])
(APIServer pid=1) INFO 07-02 21:37:27 [api_server.py:619] Supported tasks: ['generate']
(APIServer pid=1) INFO 07-02 21:37:27 [parser_manager.py:37] "auto" tool choice has been enabled.
(APIServer pid=1) WARNING 07-02 21:37:27 [model.py:1479] Default vLLM sampling parameters have been overridden by the model's `generation_config.json`: `{'temperature': 1.0, 'top_k': 20, 'top_p': 0.95}`. If this is not intended, please relaunch vLLM instance with `--generation-config vllm`.
(APIServer pid=1) INFO 07-02 21:37:31 [hf.py:548] Detected the chat template content format to be 'openai'. You can set `--chat-template-content-format` to override this.
(APIServer pid=1) INFO 07-02 21:37:44 [base.py:236] Multi-modal warmup completed in 13.041s
(APIServer pid=1) INFO 07-02 21:37:45 [base.py:236] Readonly multi-modal warmup completed in 0.604s
(APIServer pid=1) INFO 07-02 21:37:45 [api_server.py:623] Starting vLLM server on http://0.0.0.0:8000
(APIServer pid=1) INFO 07-02 21:37:45 [launcher.py:37] Available routes are:
(APIServer pid=1) INFO 07-02 21:37:45 [launcher.py:46] Route: /openapi.json, Methods: HEAD, GET
(APIServer pid=1) INFO 07-02 21:37:45 [launcher.py:46] Route: /docs, Methods: HEAD, GET
(APIServer pid=1) INFO 07-02 21:37:45 [launcher.py:46] Route: /docs/oauth2-redirect, Methods: HEAD, GET
(APIServer pid=1) INFO 07-02 21:37:45 [launcher.py:46] Route: /redoc, Methods: HEAD, GET
(APIServer pid=1) INFO 07-02 21:37:45 [launcher.py:46] Route: /load, Methods: GET
(APIServer pid=1) INFO 07-02 21:37:45 [launcher.py:46] Route: /version, Methods: GET
(APIServer pid=1) INFO 07-02 21:37:45 [launcher.py:46] Route: /health, Methods: GET
(APIServer pid=1) INFO 07-02 21:37:45 [launcher.py:46] Route: /metrics, Methods: GET
(APIServer pid=1) INFO 07-02 21:37:45 [launcher.py:46] Route: /tokenize, Methods: POST
(APIServer pid=1) INFO 07-02 21:37:45 [launcher.py:46] Route: /detokenize, Methods: POST
(APIServer pid=1) INFO 07-02 21:37:45 [launcher.py:46] Route: /v1/models, Methods: GET
(APIServer pid=1) INFO 07-02 21:37:45 [launcher.py:46] Route: /ping, Methods: GET
(APIServer pid=1) INFO 07-02 21:37:45 [launcher.py:46] Route: /ping, Methods: POST
(APIServer pid=1) INFO 07-02 21:37:45 [launcher.py:46] Route: /invocations, Methods: POST
(APIServer pid=1) INFO 07-02 21:37:45 [launcher.py:46] Route: /v1/chat/completions, Methods: POST
(APIServer pid=1) INFO 07-02 21:37:45 [launcher.py:46] Route: /v1/chat/completions/batch, Methods: POST
(APIServer pid=1) INFO 07-02 21:37:45 [launcher.py:46] Route: /v1/responses, Methods: POST
(APIServer pid=1) INFO 07-02 21:37:45 [launcher.py:46] Route: /v1/responses/{response_id}, Methods: GET
(APIServer pid=1) INFO 07-02 21:37:45 [launcher.py:46] Route: /v1/responses/{response_id}/cancel, Methods: POST
(APIServer pid=1) INFO 07-02 21:37:45 [launcher.py:46] Route: /v1/completions, Methods: POST
(APIServer pid=1) INFO 07-02 21:37:45 [launcher.py:46] Route: /v1/messages, Methods: POST
(APIServer pid=1) INFO 07-02 21:37:45 [launcher.py:46] Route: /v1/messages/count_tokens, Methods: POST
(APIServer pid=1) INFO 07-02 21:37:45 [launcher.py:46] Route: /generative_scoring, Methods: POST
(APIServer pid=1) INFO 07-02 21:37:45 [launcher.py:46] Route: /inference/v1/generate, Methods: POST
(APIServer pid=1) INFO 07-02 21:37:45 [launcher.py:46] Route: /scale_elastic_ep, Methods: POST
(APIServer pid=1) INFO 07-02 21:37:45 [launcher.py:46] Route: /is_scaling_elastic_ep, Methods: POST
(APIServer pid=1) INFO 07-02 21:37:45 [launcher.py:46] Route: /v1/chat/completions/render, Methods: POST
(APIServer pid=1) INFO 07-02 21:37:45 [launcher.py:46] Route: /v1/completions/render, Methods: POST
(APIServer pid=1) INFO 07-02 21:37:45 [launcher.py:46] Route: /v1/chat/completions/derender, Methods: POST
(APIServer pid=1) INFO 07-02 21:37:45 [launcher.py:46] Route: /v1/completions/derender, Methods: POST
(APIServer pid=1) INFO:     172.18.0.3:39362 - "GET /v1/models HTTP/1.1" 200 OK
(APIServer pid=1) INFO:     172.18.0.3:39372 - "GET /v1/models HTTP/1.1" 200 OK
(APIServer pid=1) INFO:     172.18.0.3:39374 - "GET /v1/models HTTP/1.1" 200 OK
(APIServer pid=1) INFO:     172.18.0.3:52110 - "GET /v1/models HTTP/1.1" 200 OK
(APIServer pid=1) INFO:     172.18.0.3:45834 - "POST /v1/chat/completions HTTP/1.1" 200 OK
(EngineCore pid=134) WARNING 07-02 21:38:49 [jit_monitor.py:127] Triton kernel JIT compilation during inference: _zero_kv_blocks_kernel. This causes a latency spike; consider extending warmup to cover this shape/config.
(EngineCore pid=134) WARNING 07-02 21:38:49 [jit_monitor.py:127] Triton kernel JIT compilation during inference: _compute_slot_mapping_kernel. This causes a latency spike; consider extending warmup to cover this shape/config.
(EngineCore pid=134) WARNING 07-02 21:38:49 [jit_monitor.py:127] Triton kernel JIT compilation during inference: _causal_conv1d_fwd_kernel. This causes a latency spike; consider extending warmup to cover this shape/config.
(EngineCore pid=134) WARNING 07-02 21:38:50 [jit_monitor.py:127] Triton kernel JIT compilation during inference: _fused_post_conv_kernel. This causes a latency spike; consider extending warmup to cover this shape/config.
(APIServer pid=1) INFO 07-02 21:38:56 [loggers.py:273] Engine 000: Avg prompt throughput: 5.3 tokens/s, Avg generation throughput: 6.8 tokens/s, Running: 1 reqs, Waiting: 0 reqs, GPU KV cache usage: 0.4%, Prefix cache hit rate: 0.0%
(APIServer pid=1) INFO 07-02 21:39:06 [loggers.py:273] Engine 000: Avg prompt throughput: 0.0 tokens/s, Avg generation throughput: 11.6 tokens/s, Running: 1 reqs, Waiting: 0 reqs, GPU KV cache usage: 0.4%, Prefix cache hit rate: 0.0%
(APIServer pid=1) INFO 07-02 21:39:16 [loggers.py:273] Engine 000: Avg prompt throughput: 0.0 tokens/s, Avg generation throughput: 11.3 tokens/s, Running: 1 reqs, Waiting: 0 reqs, GPU KV cache usage: 0.4%, Prefix cache hit rate: 0.0%
(APIServer pid=1) INFO 07-02 21:39:26 [loggers.py:273] Engine 000: Avg prompt throughput: 0.0 tokens/s, Avg generation throughput: 11.0 tokens/s, Running: 1 reqs, Waiting: 0 reqs, GPU KV cache usage: 0.4%, Prefix cache hit rate: 0.0%
(APIServer pid=1) INFO 07-02 21:39:36 [loggers.py:273] Engine 000: Avg prompt throughput: 33.1 tokens/s, Avg generation throughput: 11.0 tokens/s, Running: 1 reqs, Waiting: 0 reqs, GPU KV cache usage: 0.4%, Prefix cache hit rate: 0.0%
(APIServer pid=1) INFO 07-02 21:39:46 [loggers.py:273] Engine 000: Avg prompt throughput: 0.0 tokens/s, Avg generation throughput: 12.0 tokens/s, Running: 1 reqs, Waiting: 0 reqs, GPU KV cache usage: 0.4%, Prefix cache hit rate: 0.0%
(APIServer pid=1) INFO 07-02 21:39:56 [loggers.py:273] Engine 000: Avg prompt throughput: 0.0 tokens/s, Avg generation throughput: 12.0 tokens/s, Running: 1 reqs, Waiting: 0 reqs, GPU KV cache usage: 0.4%, Prefix cache hit rate: 0.0%
(APIServer pid=1) INFO 07-02 21:40:06 [loggers.py:273] Engine 000: Avg prompt throughput: 0.0 tokens/s, Avg generation throughput: 12.0 tokens/s, Running: 1 reqs, Waiting: 0 reqs, GPU KV cache usage: 0.4%, Prefix cache hit rate: 0.0%
(APIServer pid=1) INFO 07-02 21:40:16 [loggers.py:273] Engine 000: Avg prompt throughput: 0.0 tokens/s, Avg generation throughput: 12.1 tokens/s, Running: 1 reqs, Waiting: 0 reqs, GPU KV cache usage: 0.4%, Prefix cache hit rate: 0.0%
(APIServer pid=1) INFO 07-02 21:40:26 [loggers.py:273] Engine 000: Avg prompt throughput: 0.0 tokens/s, Avg generation throughput: 12.2 tokens/s, Running: 1 reqs, Waiting: 0 reqs, GPU KV cache usage: 0.4%, Prefix cache hit rate: 0.0%
(APIServer pid=1) INFO 07-02 21:40:36 [loggers.py:273] Engine 000: Avg prompt throughput: 0.0 tokens/s, Avg generation throughput: 12.0 tokens/s, Running: 1 reqs, Waiting: 0 reqs, GPU KV cache usage: 0.4%, Prefix cache hit rate: 0.0%
(APIServer pid=1) INFO 07-02 21:40:46 [loggers.py:273] Engine 000: Avg prompt throughput: 0.0 tokens/s, Avg generation throughput: 12.4 tokens/s, Running: 1 reqs, Waiting: 0 reqs, GPU KV cache usage: 0.4%, Prefix cache hit rate: 0.0%
(APIServer pid=1) INFO 07-02 21:40:56 [loggers.py:273] Engine 000: Avg prompt throughput: 0.0 tokens/s, Avg generation throughput: 12.2 tokens/s, Running: 1 reqs, Waiting: 0 reqs, GPU KV cache usage: 0.4%, Prefix cache hit rate: 0.0%
(APIServer pid=1) INFO 07-02 21:41:06 [loggers.py:273] Engine 000: Avg prompt throughput: 0.0 tokens/s, Avg generation throughput: 12.3 tokens/s, Running: 1 reqs, Waiting: 0 reqs, GPU KV cache usage: 0.4%, Prefix cache hit rate: 0.0%
(APIServer pid=1) INFO 07-02 21:41:16 [loggers.py:273] Engine 000: Avg prompt throughput: 0.0 tokens/s, Avg generation throughput: 12.1 tokens/s, Running: 1 reqs, Waiting: 0 reqs, GPU KV cache usage: 0.4%, Prefix cache hit rate: 0.0%
(EngineCore pid=134) WARNING 07-02 21:41:17 [jit_monitor.py:127] Triton kernel JIT compilation during inference: batch_memcpy_kernel. This causes a latency spike; consider extending warmup to cover this shape/config.
(APIServer pid=1) INFO 07-02 21:41:26 [loggers.py:273] Engine 000: Avg prompt throughput: 0.0 tokens/s, Avg generation throughput: 12.1 tokens/s, Running: 1 reqs, Waiting: 0 reqs, GPU KV cache usage: 0.5%, Prefix cache hit rate: 0.0%
(APIServer pid=1) INFO 07-02 21:41:36 [loggers.py:273] Engine 000: Avg prompt throughput: 0.0 tokens/s, Avg generation throughput: 12.1 tokens/s, Running: 1 reqs, Waiting: 0 reqs, GPU KV cache usage: 0.5%, Prefix cache hit rate: 0.0%
(APIServer pid=1) INFO:     172.18.0.3:45834 - "POST /v1/chat/completions HTTP/1.1" 200 OK
(APIServer pid=1) INFO 07-02 21:41:46 [loggers.py:273] Engine 000: Avg prompt throughput: 0.0 tokens/s, Avg generation throughput: 3.2 tokens/s, Running: 0 reqs, Waiting: 0 reqs, GPU KV cache usage: 0.0%, Prefix cache hit rate: 0.0%
(APIServer pid=1) INFO 07-02 21:41:56 [loggers.py:273] Engine 000: Avg prompt throughput: 0.0 tokens/s, Avg generation throughput: 0.0 tokens/s, Running: 0 reqs, Waiting: 0 reqs, GPU KV cache usage: 0.0%, Prefix cache hit rate: 0.0%
```
