# docker compose file 
```yml
services:
  qwen3-6-moe-nvfp4:
    image: vllm/vllm-openai:v0.20.2-ubuntu2404
    container_name: qwen3-6-moe-35b-a3b-nvfp4
    hostname: vllm
    platform: linux/arm64
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
      VLLM_WORKER_MULTIPROC_METHOD: spawn
      PYTORCH_CUDA_ALLOC_CONF: "expandable_segments:True"
      HF_HUB_ENABLE_HF_TRANSFER: "1"
      # Asynchronous CPU/GPU overlap for max speed
      # VLLM_USE_V2_MODEL_RUNNER: "1"

    command:
      - "--model"
      - "RedHatAI/Qwen3.6-35B-A3B-NVFP4"
      - "--served-model-name"
      - "Qwen3.6-35B-A3B-NVFP4"
      - "--api-key"
      - "${VLLM_API_KEY:-dummy-key}"
      - "--trust-remote-code"
      - "--host"
      - "0.0.0.0"
      - "--port"
      - "8000"

      # --- MEMORY & CONTEXT ---
      # --gpu-memory-utilization: Fraction of GPU VRAM reserved for the model.
      #   0.85 = 85% of 128GB UMA = ~108.8 GB for model weights + KV cache.
      #   Dropped from 0.90 to leave more room for System/CPU in the unified memory architecture.
      #
      # --max-model-len: Maximum context length (prompt + response) in tokens.
      #   262144 = ~256K tokens = maximum context window.
      #   With 128GB UMA, the Spark can handle massive context windows.
      #
      # --max-num-seqs: Maximum number of concurrent request sequences.
      #   Set to 8 for multi-agent / multi-user parallelism.
      - "--gpu-memory-utilization"
      - "0.85"
      - "--max-model-len"
      - "262144"
      - "--max-num-seqs"
      - "8"

      # --- BATCHING / PREFILL OPTIMIZATION ---
      # --max-num-batched-tokens controls how many tokens the model can process
      # during the prompt prefill phase (before generating output tokens).
      #
      # Higher values = faster prompt processing but more GPU memory consumed
      # for KV cache allocation. Lower values = slower prefill but more memory
      # available for context window.
      #
      # DGX Spark (Grace Blackwell) trade-offs:
      #   - 65536: Massive prefill for high-speed document ingestion (★ GODZILLA MODE)
      #   - 32768: Fast prefill, still excellent KV cache headroom
      #   -  8192: Conservative prefill, good for smaller contexts
      #
      # 65536 leverages the 128GB unified memory for blazing-fast prefill.
      - "--max-num-batched-tokens"
      - "65536"

      # --- ARCHITECTURE & QUANTIZATION ---
      - "--kv-cache-dtype"
      - "fp8_e4m3"
      - "--quantization"
      - "compressed-tensors"
      - "--reasoning-parser"
      - "qwen3"
      - "--tool-call-parser"
      - "qwen3_coder"
      # Auto tool choice is needed for open code, otherwise a snippet of code like the one bellow will raise an error HTTO 400 (bad request).
      #       response = client.chat.completions.create(
      # model="meta-llama/Llama-3.1-8B-Instruct",
      # messages=[{"role": "user", "content": "What's the weather in Paris?"}],
      # tools=tools,
      # tool_choice="auto"
      # )
      # ❌ Raises: 400 "auto" 
      # In short: tool choice requires --enable-auto-tool-choice and --tool-call-parser to be set
      - "--enable-auto-tool-choice"

      # --- KERNEL FUSION (The Speed Unlock) ---
      - "--moe-backend"
      - "flashinfer_cutlass"
      - "--enable-prefix-caching"
      - "--enable-chunked-prefill"

      # --- STARTUP OPTIMIZATIONS (Boot Faster) ---
      # Force disk I/O overlap
      - "--safetensors-load-strategy"
      - "prefetch"
      
      # Stop capturing useless batch graphs you won't use in single-user mode
      - "--max-cudagraph-capture-size"
      - "1"

      # --- SPECULATIVE DECODING (Speed Enhancement) ---
      # N-Gram Speculative Decoding: Uses existing KV cache to guess
      # repeating tokens. Zero memory overhead. Can push generation from
      # ~112 tokens/s → 150-200+ tokens/s if acceptance rate > 50%.
      # - "--speculative-model"
      # - "[ngram]"
      # - "--num-speculative-tokens"
      # - "5"
      # error: vllm: error: unrecognized arguments: --speculative-model [ngram] --num-speculative-tokens 5
      # something is wrong there. 

      # --- MTP ALTERNATIVE (Commented Out) ---
      # Qwen3.6 native Multi-Token Prediction — enabled for reference.
      # To use, uncomment below and comment out the ngram flags above.
      # Requires vLLM 0.20.0+ with MTP support.
      #
      - "--speculative-config"
      - '{"method":"qwen3_next_mtp","num_speculative_tokens":2}'

    networks:
      - development-network

networks:
  development-network:
    external: true

```
# Vllm Log
WARNING 05-14 08:20:13 [argparse_utils.py:257] With `vllm serve`, you should provide the model as a positional argument or in a config file instead of via the `--model` option. The `--model` option will be removed in a future version.
(APIServer pid=1) INFO 05-14 08:20:13 [utils.py:299] 
(APIServer pid=1) INFO 05-14 08:20:13 [utils.py:299]        █     █     █▄   ▄█
(APIServer pid=1) INFO 05-14 08:20:13 [utils.py:299]  ▄▄ ▄█ █     █     █ ▀▄▀ █  version 0.20.2
(APIServer pid=1) INFO 05-14 08:20:13 [utils.py:299]   █▄█▀ █     █     █     █  model   RedHatAI/Qwen3.6-35B-A3B-NVFP4
(APIServer pid=1) INFO 05-14 08:20:13 [utils.py:299]    ▀▀  ▀▀▀▀▀ ▀▀▀▀▀ ▀     ▀
(APIServer pid=1) INFO 05-14 08:20:13 [utils.py:299] 
(APIServer pid=1) INFO 05-14 08:20:13 [utils.py:233] non-default args: {'model_tag': 'RedHatAI/Qwen3.6-35B-A3B-NVFP4', 'enable_auto_tool_choice': True, 'tool_call_parser': 'qwen3_coder', 'host': '0.0.0.0', 'api_key': ['dummy-key'], 'model': 'RedHatAI/Qwen3.6-35B-A3B-NVFP4', 'trust_remote_code': True, 'max_model_len': 262144, 'quantization': 'compressed-tensors', 'served_model_name': ['Qwen3.6-35B-A3B-NVFP4'], 'safetensors_load_strategy': 'prefetch', 'reasoning_parser': 'qwen3', 'gpu_memory_utilization': 0.85, 'kv_cache_dtype': 'fp8_e4m3', 'enable_prefix_caching': True, 'max_num_batched_tokens': 65536, 'max_num_seqs': 8, 'enable_chunked_prefill': True, 'max_cudagraph_capture_size': 1, 'moe_backend': 'flashinfer_cutlass', 'speculative_config': {'method': 'qwen3_next_mtp', 'num_speculative_tokens': 2}}
(APIServer pid=1) Warning: You are sending unauthenticated requests to the HF Hub. Please set a HF_TOKEN to enable higher rate limits and faster downloads.
(APIServer pid=1) INFO 05-14 08:20:20 [nixl_utils.py:20] Setting UCX_RCACHE_MAX_UNRELEASED to '1024' to avoid a rare memory leak in UCX when using NIXL.
(APIServer pid=1) INFO 05-14 08:20:20 [nixl_utils.py:32] NIXL is available
(APIServer pid=1) INFO 05-14 08:20:20 [model.py:555] Resolved architecture: Qwen3_5MoeForConditionalGeneration
(APIServer pid=1) INFO 05-14 08:20:20 [model.py:1680] Using max model len 262144
(APIServer pid=1) INFO 05-14 08:20:20 [cache.py:261] Using fp8_e4m3 data type to store kv cache. It reduces the GPU memory footprint and boosts the performance. Meanwhile, it may cause accuracy drop without a proper scaling factor
(APIServer pid=1) WARNING 05-14 08:20:20 [speculative.py:456] method `qwen3_next_mtp` is deprecated and replaced with mtp.
(APIServer pid=1) INFO 05-14 08:20:25 [model.py:555] Resolved architecture: Qwen3_5MoeMTP
(APIServer pid=1) INFO 05-14 08:20:25 [model.py:1680] Using max model len 262144
(APIServer pid=1) WARNING 05-14 08:20:25 [speculative.py:602] Enabling num_speculative_tokens > 1 will run multiple times of forward on same MTP layer,which may result in lower acceptance rate
(APIServer pid=1) INFO 05-14 08:20:25 [scheduler.py:239] Chunked prefill is enabled with max_num_batched_tokens=65536.
(APIServer pid=1) WARNING 05-14 08:20:25 [config.py:367] Mamba cache mode is set to 'align' for Qwen3_5MoeForConditionalGeneration by default when prefix caching is enabled
(APIServer pid=1) INFO 05-14 08:20:25 [config.py:387] Warning: Prefix caching in Mamba cache 'align' mode is currently enabled. Its support for Mamba layers is experimental. Please report any issues you may observe.
(APIServer pid=1) INFO 05-14 08:20:25 [vllm.py:840] Asynchronous scheduling is enabled.
(APIServer pid=1) INFO 05-14 08:20:25 [kernel.py:205] Final IR op priority after setting platform defaults: IrOpPriorityConfig(rms_norm=['native'])
(APIServer pid=1) INFO 05-14 08:20:27 [compilation.py:303] Enabled custom fusions: act_quant
(APIServer pid=1) [transformers] `Qwen2VLImageProcessorFast` is deprecated. The `Fast` suffix for image processors has been removed; use `Qwen2VLImageProcessor` instead.
(APIServer pid=1) [transformers] The `use_fast` parameter is deprecated and will be removed in a future version. Use `backend="torchvision"` instead of `use_fast=True`, or `backend="pil"` instead of `use_fast=False`.
INFO 05-14 08:20:42 [nixl_utils.py:32] NIXL is available
(EngineCore pid=168) INFO 05-14 08:20:42 [core.py:109] Initializing a V1 LLM engine (v0.20.2) with config: model='RedHatAI/Qwen3.6-35B-A3B-NVFP4', speculative_config=SpeculativeConfig(method='mtp', model='RedHatAI/Qwen3.6-35B-A3B-NVFP4', num_spec_tokens=2), tokenizer='RedHatAI/Qwen3.6-35B-A3B-NVFP4', skip_tokenizer_init=False, tokenizer_mode=auto, revision=None, tokenizer_revision=None, trust_remote_code=True, dtype=torch.bfloat16, max_seq_len=262144, download_dir=None, load_format=auto, tensor_parallel_size=1, pipeline_parallel_size=1, data_parallel_size=1, decode_context_parallel_size=1, dcp_comm_backend=ag_rs, disable_custom_all_reduce=False, quantization=compressed-tensors, quantization_config=None, enforce_eager=False, enable_return_routed_experts=False, kv_cache_dtype=fp8_e4m3, device_config=cuda, structured_outputs_config=StructuredOutputsConfig(backend='auto', disable_any_whitespace=False, disable_additional_properties=False, reasoning_parser='qwen3', reasoning_parser_plugin='', enable_in_reasoning=False), observability_config=ObservabilityConfig(show_hidden_metrics_for_version=None, otlp_traces_endpoint=None, collect_detailed_traces=None, kv_cache_metrics=False, kv_cache_metrics_sample=0.01, cudagraph_metrics=False, enable_layerwise_nvtx_tracing=False, enable_mfu_metrics=False, enable_mm_processor_stats=False, enable_logging_iteration_details=False), seed=0, served_model_name=Qwen3.6-35B-A3B-NVFP4, enable_prefix_caching=True, enable_chunked_prefill=True, pooler_config=None, compilation_config={'mode': <CompilationMode.VLLM_COMPILE: 3>, 'debug_dump_path': None, 'cache_dir': '', 'compile_cache_save_format': 'binary', 'backend': 'inductor', 'custom_ops': ['none'], 'ir_enable_torch_wrap': True, 'splitting_ops': ['vllm::unified_attention_with_output', 'vllm::unified_mla_attention_with_output', 'vllm::mamba_mixer2', 'vllm::mamba_mixer', 'vllm::short_conv', 'vllm::linear_attention', 'vllm::plamo2_mamba_mixer', 'vllm::gdn_attention_core', 'vllm::gdn_attention_core_xpu', 'vllm::olmo_hybrid_gdn_full_forward', 'vllm::kda_attention', 'vllm::sparse_attn_indexer', 'vllm::rocm_aiter_sparse_attn_indexer', 'vllm::deepseek_v4_attention', 'vllm::unified_kv_cache_update', 'vllm::unified_mla_kv_cache_update'], 'compile_mm_encoder': False, 'cudagraph_mm_encoder': False, 'encoder_cudagraph_token_budgets': [], 'encoder_cudagraph_max_vision_items_per_batch': 0, 'encoder_cudagraph_max_frames_per_batch': None, 'compile_sizes': [], 'compile_ranges_endpoints': [65536], 'inductor_compile_config': {'enable_auto_functionalized_v2': False, 'size_asserts': False, 'alignment_asserts': False, 'scalar_asserts': False, 'combo_kernels': True, 'benchmark_combo_kernel': True}, 'inductor_passes': {}, 'cudagraph_mode': <CUDAGraphMode.FULL_AND_PIECEWISE: (2, 1)>, 'cudagraph_num_of_warmups': 1, 'cudagraph_capture_sizes': [1], 'cudagraph_copy_inputs': False, 'cudagraph_specialize_lora': True, 'use_inductor_graph_partition': False, 'pass_config': {'fuse_norm_quant': False, 'fuse_act_quant': True, 'fuse_attn_quant': False, 'enable_sp': False, 'fuse_gemm_comms': False, 'fuse_allreduce_rms': False}, 'max_cudagraph_capture_size': 1, 'dynamic_shapes_config': {'type': <DynamicShapesType.BACKED: 'backed'>, 'evaluate_guards': False, 'assume_32_bit_indexing': False}, 'local_cache_dir': None, 'fast_moe_cold_start': False, 'static_all_moe_layers': []}, kernel_config=KernelConfig(ir_op_priority=IrOpPriorityConfig(rms_norm=['native']), enable_flashinfer_autotune=True, moe_backend='flashinfer_cutlass')
(EngineCore pid=168) [transformers] `Qwen2VLImageProcessorFast` is deprecated. The `Fast` suffix for image processors has been removed; use `Qwen2VLImageProcessor` instead.
(EngineCore pid=168) Warning: You are sending unauthenticated requests to the HF Hub. Please set a HF_TOKEN to enable higher rate limits and faster downloads.
(EngineCore pid=168) INFO 05-14 08:20:45 [parallel_state.py:1402] world_size=1 rank=0 local_rank=0 distributed_init_method=tcp://172.18.0.2:53535 backend=nccl
(EngineCore pid=168) INFO 05-14 08:20:45 [parallel_state.py:1715] rank 0 in world size 1 is assigned as DP rank 0, PP rank 0, PCP rank 0, TP rank 0, EP rank 0, EPLB rank N/A
(EngineCore pid=168) WARNING 05-14 08:20:45 [__init__.py:206] min_p and logit_bias parameters won't work with speculative decoding.
(EngineCore pid=168) [transformers] The `use_fast` parameter is deprecated and will be removed in a future version. Use `backend="torchvision"` instead of `use_fast=True`, or `backend="pil"` instead of `use_fast=False`.
(EngineCore pid=168) INFO 05-14 08:20:56 [gpu_model_runner.py:4777] Starting to load model RedHatAI/Qwen3.6-35B-A3B-NVFP4...
(EngineCore pid=168) INFO 05-14 08:20:56 [cuda.py:423] Using backend AttentionBackendEnum.FLASH_ATTN for vit attention
(EngineCore pid=168) INFO 05-14 08:20:56 [mm_encoder_attention.py:230] Using AttentionBackendEnum.FLASH_ATTN for MMEncoderAttention.
(EngineCore pid=168) INFO 05-14 08:20:56 [gdn_linear_attn.py:153] Using Triton/FLA GDN prefill kernel
(EngineCore pid=168) INFO 05-14 08:20:56 [__init__.py:683] Using FlashInferCutlassNvFp4LinearKernel for NVFP4 GEMM
(EngineCore pid=168) INFO 05-14 08:20:57 [nvfp4.py:209] Using 'FLASHINFER_CUTLASS' NvFp4 MoE backend out of potential backends: ['FLASHINFER_TRTLLM', 'FLASHINFER_CUTEDSL', 'FLASHINFER_CUTEDSL_BATCHED', 'FLASHINFER_CUTLASS', 'VLLM_CUTLASS', 'MARLIN', 'EMULATION'].
(EngineCore pid=168) INFO 05-14 08:20:57 [cuda.py:368] Using FLASHINFER attention backend out of potential backends: ['FLASHINFER', 'TRITON_ATTN'].
(EngineCore pid=168) INFO 05-14 08:20:58 [weight_utils.py:904] Filesystem type for checkpoints: EXT4. Checkpoint size: 23.32 GiB. Available RAM: 89.13 GiB.
(EngineCore pid=168) INFO 05-14 08:20:58 [weight_utils.py:874] Prefetching checkpoint files into page cache started (in background)
(EngineCore pid=168) Loading safetensors checkpoint shards:   0% Completed | 0/3 [00:00<?, ?it/s]
(EngineCore pid=168) INFO 05-14 08:21:00 [weight_utils.py:851] Prefetching checkpoint files: 10% (1/3)
(EngineCore pid=168) INFO 05-14 08:21:01 [weight_utils.py:851] Prefetching checkpoint files: 20% (2/3)
(EngineCore pid=168) INFO 05-14 08:21:22 [weight_utils.py:851] Prefetching checkpoint files: 30% (3/3)
(EngineCore pid=168) INFO 05-14 08:21:22 [weight_utils.py:869] Prefetching checkpoint files into page cache finished in 23.58s
(EngineCore pid=168) Loading safetensors checkpoint shards:  33% Completed | 1/3 [01:57<03:55, 117.74s/it]
(EngineCore pid=168) Loading safetensors checkpoint shards: 100% Completed | 3/3 [02:06<00:00, 33.63s/it]
(EngineCore pid=168)  Loading safetensors checkpoint shards: 100% Completed | 3/3 [02:06<00:00, 42.04s/it]
(EngineCore pid=168) 
(EngineCore pid=168) INFO 05-14 08:23:05 [default_loader.py:384] Loading weights took 126.18 seconds
(EngineCore pid=168) INFO 05-14 08:23:05 [nvfp4.py:485] Using MoEPrepareAndFinalizeNoDPEPModular
(EngineCore pid=168) INFO 05-14 08:23:05 [gpu_model_runner.py:4801] Loading drafter model...
(EngineCore pid=168) INFO 05-14 08:23:05 [unquantized.py:213] Using FlashInfer CUTLASS Unquantized MoE backend out of potential backends: ['FlashInfer TRTLLM', 'FlashInfer CUTLASS', 'TRITON', 'BATCHED_TRITON'].
(EngineCore pid=168) INFO 05-14 08:23:06 [weight_utils.py:904] Filesystem type for checkpoints: EXT4. Checkpoint size: 23.32 GiB. Available RAM: 84.99 GiB.
(EngineCore pid=168) INFO 05-14 08:23:06 [weight_utils.py:874] Prefetching checkpoint files into page cache started (in background)
(EngineCore pid=168) Loading safetensors checkpoint shards:   0% Completed | 0/3 [00:00<?, ?it/s]
(EngineCore pid=168) INFO 05-14 08:23:06 [weight_utils.py:851] Prefetching checkpoint files: 10% (1/3)
(EngineCore pid=168) INFO 05-14 08:23:06 [weight_utils.py:851] Prefetching checkpoint files: 20% (2/3)
(EngineCore pid=168) INFO 05-14 08:23:07 [weight_utils.py:851] Prefetching checkpoint files: 30% (3/3)
(EngineCore pid=168) INFO 05-14 08:23:07 [weight_utils.py:869] Prefetching checkpoint files into page cache finished in 1.82s
(EngineCore pid=168) Loading safetensors checkpoint shards:  33% Completed | 1/3 [00:16<00:32, 16.12s/it]
(EngineCore pid=168) Loading safetensors checkpoint shards:  67% Completed | 2/3 [00:17<00:07,  7.32s/it]
(EngineCore pid=168) Loading safetensors checkpoint shards: 100% Completed | 3/3 [00:17<00:00,  5.76s/it]
(EngineCore pid=168) 
(EngineCore pid=168) INFO 05-14 08:23:23 [default_loader.py:384] Loading weights took 17.33 seconds
(EngineCore pid=168) INFO 05-14 08:23:23 [unquantized.py:343] Using MoEPrepareAndFinalizeNoDPEPModular
(EngineCore pid=168) INFO 05-14 08:23:23 [llm_base_proposer.py:1445] Detected MTP model. Sharing target model embedding weights with the draft model.
(EngineCore pid=168) INFO 05-14 08:23:23 [llm_base_proposer.py:1501] Detected MTP model. Sharing target model lm_head weights with the draft model.
(EngineCore pid=168) INFO 05-14 08:23:23 [gpu_model_runner.py:4879] Model loading took 23.43 GiB memory and 146.682945 seconds
(EngineCore pid=168) INFO 05-14 08:23:23 [interface.py:606] Setting attention block size to 2128 tokens to ensure that attention page size is >= mamba page size.
(EngineCore pid=168) INFO 05-14 08:23:23 [gpu_model_runner.py:5820] Encoder cache will be initialized with a budget of 65536 tokens, and profiled with 4 image items of the maximum feature size.
(EngineCore pid=168) INFO 05-14 08:23:37 [backends.py:1069] Using cache directory: /root/.cache/vllm/torch_compile_cache/ad64f07dcd/rank_0_0/backbone for vLLM's torch.compile
(EngineCore pid=168) INFO 05-14 08:23:37 [backends.py:1128] Dynamo bytecode transform time: 5.10 s
(EngineCore pid=168) [rank0]:W0514 08:24:07.714000 168 site-packages/torch/_inductor/utils.py:1731] Not enough SMs to use max_autotune_gemm mode
(EngineCore pid=168) INFO 05-14 08:24:09 [backends.py:376] Cache the graph of compile range (1, 65536) for later use
(EngineCore pid=168) INFO 05-14 08:24:33 [backends.py:391] Compiling a graph for compile range (1, 65536) takes 55.59 s
(EngineCore pid=168) INFO 05-14 08:24:35 [decorators.py:668] saved AOT compiled function to /root/.cache/vllm/torch_compile_cache/torch_aot_compile/1821919f8c1175f908378447d121801513f41654b3af0c9378b99d16cc2852a4/rank_0_0/model
(EngineCore pid=168) INFO 05-14 08:24:35 [monitor.py:53] torch.compile took 63.00 s in total
(EngineCore pid=168) INFO 05-14 08:25:25 [monitor.py:81] Initial profiling/warmup run took 50.12 s
(EngineCore pid=168) INFO 05-14 08:25:25 [backends.py:1069] Using cache directory: /root/.cache/vllm/torch_compile_cache/ad64f07dcd/rank_0_0/eagle_head for vLLM's torch.compile
(EngineCore pid=168) INFO 05-14 08:25:25 [backends.py:1128] Dynamo bytecode transform time: 0.34 s
(EngineCore pid=168) INFO 05-14 08:25:33 [backends.py:391] Compiling a graph for compile range (1, 65536) takes 7.55 s
(EngineCore pid=168) INFO 05-14 08:25:33 [decorators.py:668] saved AOT compiled function to /root/.cache/vllm/torch_compile_cache/torch_aot_compile/c423703cd49c1461626513459e7b592d9528fc63115aed7005bdbd2486a024ae/rank_0_0/model
(EngineCore pid=168) INFO 05-14 08:25:33 [monitor.py:53] torch.compile took 8.12 s in total
(EngineCore pid=168) INFO 05-14 08:25:34 [monitor.py:81] Initial profiling/warmup run took 1.58 s
(EngineCore pid=168) WARNING 05-14 08:25:39 [kv_cache_utils.py:1152] Add 3 padding layers, may waste at most 10.00% KV cache memory
(EngineCore pid=168) WARNING 05-14 08:25:39 [compilation.py:1390] CUDAGraphMode.FULL_AND_PIECEWISE is not supported with spec-decode for attention backend FlashInferBackend (support: AttentionCGSupport.UNIFORM_SINGLE_TOKEN_DECODE); setting cudagraph_mode=PIECEWISE
(EngineCore pid=168) INFO 05-14 08:25:39 [gpu_model_runner.py:5963] Profiling CUDA graph memory: PIECEWISE=1 (largest=1)
(EngineCore pid=168) INFO 05-14 08:25:41 [gpu_model_runner.py:6042] Estimated CUDA graph memory: -0.90 GiB total
(EngineCore pid=168) INFO 05-14 08:25:41 [gpu_worker.py:440] Available KV cache memory: 66.58 GiB
(EngineCore pid=168) WARNING 05-14 08:25:41 [kv_cache_utils.py:1152] Add 3 padding layers, may waste at most 10.00% KV cache memory
(EngineCore pid=168) INFO 05-14 08:25:41 [kv_cache_utils.py:1708] GPU KV cache size: 5,747,892 tokens
(EngineCore pid=168) INFO 05-14 08:25:41 [kv_cache_utils.py:1709] Maximum concurrency for 262,144 tokens per request: 21.93x
(EngineCore pid=168) 2026-05-14 08:25:45,631 - INFO - autotuner.py:457 - flashinfer.jit: [Autotuner]: Autotuning process starts ...
(EngineCore pid=168) [AutoTuner]: Tuning fp4_gemm:   0%|          | 0/17 [00:00<?, ?profile/s][AutoTuner]: Tuning fp4_gemm:  76%|███████▋  | 13/17 [00:00<00:00, 120.10profile/s][AutoTuner]: Tuning fp4_gemm: 100%|██████████| 17/17 [00:00<00:00, 35.55profile/s] 
(EngineCore pid=168) [AutoTuner]: Tuning fp4_gemm:   0%|          | 0/17 [00:00<?, ?profile/s][AutoTuner]: Tuning fp4_gemm:  76%|███████▋  | 13/17 [00:00<00:00, 128.48profile/s][AutoTuner]: Tuning fp4_gemm: 100%|██████████| 17/17 [00:00<00:00, 35.75profile/s] 
(EngineCore pid=168) [AutoTuner]: Tuning trtllm::fused_moe::gemm1:   0%|          | 0/1 [00:00<?, ?profile/s]2026-05-14 08:25:47,099 - INFO - autotuner.py:833 - flashinfer.jit: [Autotuner]: Skipped 4 unsupported tactic(s) for trtllm::fused_moe::gemm1 (enable debug logs to see details)
(EngineCore pid=168) [AutoTuner]: Tuning trtllm::fused_moe::gemm1: 100%|██████████| 1/1 [00:00<00:00, 35.99profile/s]
(EngineCore pid=168) [AutoTuner]: Tuning trtllm::fused_moe::gemm2:   0%|          | 0/1 [00:00<?, ?profile/s]2026-05-14 08:25:47,142 - INFO - autotuner.py:833 - flashinfer.jit: [Autotuner]: Skipped 10 unsupported tactic(s) for trtllm::fused_moe::gemm2 (enable debug logs to see details)
(EngineCore pid=168) [AutoTuner]: Tuning trtllm::fused_moe::gemm2: 100%|██████████| 1/1 [00:00<00:00, 23.63profile/s]
(EngineCore pid=168) [AutoTuner]: Tuning fp4_gemm:   0%|          | 0/17 [00:00<?, ?profile/s][AutoTuner]: Tuning fp4_gemm:   6%|▌         | 1/17 [00:00<00:04,  3.67profile/s][AutoTuner]: Tuning fp4_gemm:  65%|██████▍   | 11/17 [00:00<00:00, 34.83profile/s][AutoTuner]: Tuning fp4_gemm: 100%|██████████| 17/17 [00:03<00:00,  3.93profile/s][AutoTuner]: Tuning fp4_gemm: 100%|██████████| 17/17 [00:03<00:00,  4.72profile/s]
(EngineCore pid=168) [AutoTuner]: Tuning fp4_gemm:   0%|          | 0/17 [00:00<?, ?profile/s][AutoTuner]: Tuning fp4_gemm:  47%|████▋     | 8/17 [00:00<00:00, 78.11profile/s][AutoTuner]: Tuning fp4_gemm:  94%|█████████▍| 16/17 [00:00<00:00, 23.52profile/s][AutoTuner]: Tuning fp4_gemm: 100%|██████████| 17/17 [00:01<00:00, 14.74profile/s]
(EngineCore pid=168) [AutoTuner]: Tuning trtllm::fused_moe::gemm1:   0%|          | 0/1 [00:00<?, ?profile/s]2026-05-14 08:26:02,341 - INFO - autotuner.py:833 - flashinfer.jit: [Autotuner]: Skipped 3 unsupported tactic(s) for trtllm::fused_moe::gemm1 (enable debug logs to see details)
(EngineCore pid=168) [AutoTuner]: Tuning trtllm::fused_moe::gemm1: 100%|██████████| 1/1 [00:00<00:00,  1.56profile/s][AutoTuner]: Tuning trtllm::fused_moe::gemm1: 100%|██████████| 1/1 [00:00<00:00,  1.56profile/s]
(EngineCore pid=168) [AutoTuner]: Tuning trtllm::fused_moe::gemm2:   0%|          | 0/1 [00:00<?, ?profile/s]2026-05-14 08:26:02,362 - INFO - autotuner.py:833 - flashinfer.jit: [Autotuner]: Skipped 1 unsupported tactic(s) for trtllm::fused_moe::gemm2 (enable debug logs to see details)
(EngineCore pid=168) [AutoTuner]: Tuning trtllm::fused_moe::gemm2: 100%|██████████| 1/1 [00:00<00:00, 47.82profile/s]
(EngineCore pid=168) 2026-05-14 08:26:02,367 - INFO - autotuner.py:466 - flashinfer.jit: [Autotuner]: Autotuning process ends
(EngineCore pid=168) Capturing CUDA graphs (mixed prefill-decode, PIECEWISE):   0%|          | 0/1 [00:00<?, ?it/s]Capturing CUDA graphs (mixed prefill-decode, PIECEWISE): 100%|██████████| 1/1 [00:00<00:00, 13.39it/s]
(EngineCore pid=168) INFO 05-14 08:26:03 [gpu_model_runner.py:6133] Graph capturing finished in 1 secs, took 0.05 GiB
(EngineCore pid=168) INFO 05-14 08:26:03 [core.py:299] init engine (profile, create kv cache, warmup model) took 159.54 s (compilation: 71.12 s)
(EngineCore pid=168) INFO 05-14 08:26:03 [vllm.py:840] Asynchronous scheduling is enabled.
(EngineCore pid=168) INFO 05-14 08:26:03 [kernel.py:205] Final IR op priority after setting platform defaults: IrOpPriorityConfig(rms_norm=['native'])
(EngineCore pid=168) INFO 05-14 08:26:03 [compilation.py:303] Enabled custom fusions: act_quant
(APIServer pid=1) INFO 05-14 08:26:03 [api_server.py:598] Supported tasks: ['generate']
(APIServer pid=1) INFO 05-14 08:26:03 [parser_manager.py:202] "auto" tool choice has been enabled.
(APIServer pid=1) WARNING 05-14 08:26:04 [model.py:1437] Default vLLM sampling parameters have been overridden by the model's `generation_config.json`: `{'temperature': 1.0, 'top_k': 20, 'top_p': 0.95}`. If this is not intended, please relaunch vLLM instance with `--generation-config vllm`.
(APIServer pid=1) INFO 05-14 08:26:09 [hf.py:314] Detected the chat template content format to be 'string'. You can set `--chat-template-content-format` to override this.
(APIServer pid=1) INFO 05-14 08:26:15 [base.py:233] Multi-modal warmup completed in 6.698s
(APIServer pid=1) INFO 05-14 08:26:22 [base.py:233] Readonly multi-modal warmup completed in 6.859s
(APIServer pid=1) INFO 05-14 08:26:22 [api_server.py:602] Starting vLLM server on http://0.0.0.0:8000
(APIServer pid=1) INFO 05-14 08:26:22 [launcher.py:37] Available routes are:
(APIServer pid=1) INFO 05-14 08:26:22 [launcher.py:46] Route: /openapi.json, Methods: GET, HEAD
(APIServer pid=1) INFO 05-14 08:26:22 [launcher.py:46] Route: /docs, Methods: GET, HEAD
(APIServer pid=1) INFO 05-14 08:26:22 [launcher.py:46] Route: /docs/oauth2-redirect, Methods: GET, HEAD
(APIServer pid=1) INFO 05-14 08:26:22 [launcher.py:46] Route: /redoc, Methods: GET, HEAD
(APIServer pid=1) INFO 05-14 08:26:22 [launcher.py:46] Route: /tokenize, Methods: POST
(APIServer pid=1) INFO 05-14 08:26:22 [launcher.py:46] Route: /detokenize, Methods: POST
(APIServer pid=1) INFO 05-14 08:26:22 [launcher.py:46] Route: /load, Methods: GET
(APIServer pid=1) INFO 05-14 08:26:22 [launcher.py:46] Route: /version, Methods: GET
(APIServer pid=1) INFO 05-14 08:26:22 [launcher.py:46] Route: /health, Methods: GET
(APIServer pid=1) INFO 05-14 08:26:22 [launcher.py:46] Route: /metrics, Methods: GET
(APIServer pid=1) INFO 05-14 08:26:22 [launcher.py:46] Route: /v1/models, Methods: GET
(APIServer pid=1) INFO 05-14 08:26:22 [launcher.py:46] Route: /ping, Methods: GET
(APIServer pid=1) INFO 05-14 08:26:22 [launcher.py:46] Route: /ping, Methods: POST
(APIServer pid=1) INFO 05-14 08:26:22 [launcher.py:46] Route: /invocations, Methods: POST
(APIServer pid=1) INFO 05-14 08:26:22 [launcher.py:46] Route: /v1/chat/completions, Methods: POST
(APIServer pid=1) INFO 05-14 08:26:22 [launcher.py:46] Route: /v1/chat/completions/batch, Methods: POST
(APIServer pid=1) INFO 05-14 08:26:22 [launcher.py:46] Route: /v1/responses, Methods: POST
(APIServer pid=1) INFO 05-14 08:26:22 [launcher.py:46] Route: /v1/responses/{response_id}, Methods: GET
(APIServer pid=1) INFO 05-14 08:26:22 [launcher.py:46] Route: /v1/responses/{response_id}/cancel, Methods: POST
(APIServer pid=1) INFO 05-14 08:26:22 [launcher.py:46] Route: /v1/completions, Methods: POST
(APIServer pid=1) INFO 05-14 08:26:22 [launcher.py:46] Route: /v1/messages, Methods: POST
(APIServer pid=1) INFO 05-14 08:26:22 [launcher.py:46] Route: /v1/messages/count_tokens, Methods: POST
(APIServer pid=1) INFO 05-14 08:26:22 [launcher.py:46] Route: /inference/v1/generate, Methods: POST
(APIServer pid=1) INFO 05-14 08:26:22 [launcher.py:46] Route: /scale_elastic_ep, Methods: POST
(APIServer pid=1) INFO 05-14 08:26:22 [launcher.py:46] Route: /is_scaling_elastic_ep, Methods: POST
(APIServer pid=1) INFO 05-14 08:26:22 [launcher.py:46] Route: /generative_scoring, Methods: POST
(APIServer pid=1) INFO 05-14 08:26:22 [launcher.py:46] Route: /v1/chat/completions/render, Methods: POST
(APIServer pid=1) INFO 05-14 08:26:22 [launcher.py:46] Route: /v1/completions/render, Methods: POST
(APIServer pid=1) INFO:     Started server process [1]
(APIServer pid=1) INFO:     Waiting for application startup.
(APIServer pid=1) INFO:     Application startup complete.
(APIServer pid=1) INFO:     172.18.0.3:47716 - "POST /v1/chat/completions HTTP/1.1" 200 OK
(APIServer pid=1) INFO:     172.18.0.3:48982 - "POST /v1/chat/completions HTTP/1.1" 200 OK
(APIServer pid=1) INFO 05-14 08:39:13 [loggers.py:271] Engine 000: Avg prompt throughput: 2111.5 tokens/s, Avg generation throughput: 19.3 tokens/s, Running: 0 reqs, Waiting: 0 reqs, GPU KV cache usage: 0.0%, Prefix cache hit rate: 41.4%
(APIServer pid=1) INFO 05-14 08:39:13 [metrics.py:101] SpecDecoding metrics: Mean acceptance length: 2.44, Accepted throughput: 0.14 tokens/s, Drafted throughput: 0.20 tokens/s, Accepted: 114 tokens, Drafted: 158 tokens, Per-position acceptance rate: 0.810, 0.633, Avg Draft acceptance rate: 72.2%
(APIServer pid=1) INFO 05-14 08:39:23 [loggers.py:271] Engine 000: Avg prompt throughput: 0.0 tokens/s, Avg generation throughput: 0.0 tokens/s, Running: 0 reqs, Waiting: 0 reqs, GPU KV cache usage: 0.0%, Prefix cache hit rate: 41.4%
(APIServer pid=1) INFO:     172.18.0.3:55064 - "GET /v1/models HTTP/1.1" 200 OK
(APIServer pid=1) INFO:     172.18.0.3:49002 - "POST /v1/chat/completions HTTP/1.1" 200 OK
(APIServer pid=1) INFO 05-14 09:38:13 [loggers.py:271] Engine 000: Avg prompt throughput: 395.8 tokens/s, Avg generation throughput: 6.1 tokens/s, Running: 1 reqs, Waiting: 0 reqs, GPU KV cache usage: 0.6%, Prefix cache hit rate: 54.3%
(APIServer pid=1) INFO 05-14 09:38:13 [metrics.py:101] SpecDecoding metrics: Mean acceptance length: 2.50, Accepted throughput: 0.01 tokens/s, Drafted throughput: 0.01 tokens/s, Accepted: 36 tokens, Drafted: 48 tokens, Per-position acceptance rate: 0.833, 0.667, Avg Draft acceptance rate: 75.0%
(APIServer pid=1) INFO:     172.18.0.3:41930 - "POST /v1/chat/completions HTTP/1.1" 200 OK
(APIServer pid=1) INFO:     172.18.0.3:41936 - "POST /v1/chat/completions HTTP/1.1" 200 OK
(APIServer pid=1) INFO 05-14 09:38:23 [loggers.py:271] Engine 000: Avg prompt throughput: 857.0 tokens/s, Avg generation throughput: 31.8 tokens/s, Running: 0 reqs, Waiting: 0 reqs, GPU KV cache usage: 0.0%, Prefix cache hit rate: 64.7%
(APIServer pid=1) INFO 05-14 09:38:23 [metrics.py:101] SpecDecoding metrics: Mean acceptance length: 2.66, Accepted throughput: 19.80 tokens/s, Drafted throughput: 23.80 tokens/s, Accepted: 198 tokens, Drafted: 238 tokens, Per-position acceptance rate: 0.899, 0.765, Avg Draft acceptance rate: 83.2%
(APIServer pid=1) INFO 05-14 09:38:33 [loggers.py:271] Engine 000: Avg prompt throughput: 0.0 tokens/s, Avg generation throughput: 0.0 tokens/s, Running: 0 reqs, Waiting: 0 reqs, GPU KV cache usage: 0.0%, Prefix cache hit rate: 64.7%
(APIServer pid=1) INFO:     172.18.0.3:43220 - "POST /v1/chat/completions HTTP/1.1" 200 OK
(APIServer pid=1) INFO:     172.18.0.3:43226 - "POST /v1/chat/completions HTTP/1.1" 200 OK
(APIServer pid=1) INFO 05-14 09:38:43 [loggers.py:271] Engine 000: Avg prompt throughput: 762.4 tokens/s, Avg generation throughput: 24.0 tokens/s, Running: 0 reqs, Waiting: 0 reqs, GPU KV cache usage: 0.0%, Prefix cache hit rate: 70.3%
(APIServer pid=1) INFO 05-14 09:38:43 [metrics.py:101] SpecDecoding metrics: Mean acceptance length: 2.78, Accepted throughput: 7.65 tokens/s, Drafted throughput: 8.60 tokens/s, Accepted: 153 tokens, Drafted: 172 tokens, Per-position acceptance rate: 0.919, 0.860, Avg Draft acceptance rate: 89.0%
(APIServer pid=1) INFO 05-14 09:38:53 [loggers.py:271] Engine 000: Avg prompt throughput: 0.0 tokens/s, Avg generation throughput: 0.0 tokens/s, Running: 0 reqs, Waiting: 0 reqs, GPU KV cache usage: 0.0%, Prefix cache hit rate: 70.3%
(APIServer pid=1) INFO:     172.18.0.3:38412 - "POST /v1/chat/completions HTTP/1.1" 200 OK
(APIServer pid=1) INFO:     172.18.0.3:38422 - "POST /v1/chat/completions HTTP/1.1" 200 OK
(APIServer pid=1) INFO 05-14 09:42:13 [loggers.py:271] Engine 000: Avg prompt throughput: 960.8 tokens/s, Avg generation throughput: 9.5 tokens/s, Running: 1 reqs, Waiting: 0 reqs, GPU KV cache usage: 0.9%, Prefix cache hit rate: 71.6%
(APIServer pid=1) INFO 05-14 09:42:13 [metrics.py:101] SpecDecoding metrics: Mean acceptance length: 2.57, Accepted throughput: 0.28 tokens/s, Drafted throughput: 0.35 tokens/s, Accepted: 58 tokens, Drafted: 74 tokens, Per-position acceptance rate: 0.865, 0.703, Avg Draft acceptance rate: 78.4%
(APIServer pid=1) INFO 05-14 09:42:23 [loggers.py:271] Engine 000: Avg prompt throughput: 576.3 tokens/s, Avg generation throughput: 50.2 tokens/s, Running: 1 reqs, Waiting: 0 reqs, GPU KV cache usage: 0.8%, Prefix cache hit rate: 71.6%
(APIServer pid=1) INFO 05-14 09:42:23 [metrics.py:101] SpecDecoding metrics: Mean acceptance length: 2.46, Accepted throughput: 29.70 tokens/s, Drafted throughput: 40.80 tokens/s, Accepted: 297 tokens, Drafted: 408 tokens, Per-position acceptance rate: 0.794, 0.662, Avg Draft acceptance rate: 72.8%
(APIServer pid=1) INFO 05-14 09:42:33 [loggers.py:271] Engine 000: Avg prompt throughput: 0.0 tokens/s, Avg generation throughput: 19.9 tokens/s, Running: 0 reqs, Waiting: 0 reqs, GPU KV cache usage: 0.0%, Prefix cache hit rate: 71.6%
(APIServer pid=1) INFO 05-14 09:42:33 [metrics.py:101] SpecDecoding metrics: Mean acceptance length: 2.49, Accepted throughput: 11.90 tokens/s, Drafted throughput: 16.00 tokens/s, Accepted: 119 tokens, Drafted: 160 tokens, Per-position acceptance rate: 0.838, 0.650, Avg Draft acceptance rate: 74.4%
(APIServer pid=1) INFO 05-14 09:42:43 [loggers.py:271] Engine 000: Avg prompt throughput: 0.0 tokens/s, Avg generation throughput: 0.0 tokens/s, Running: 0 reqs, Waiting: 0 reqs, GPU KV cache usage: 0.0%, Prefix cache hit rate: 71.6%
(APIServer pid=1) INFO:     172.18.0.3:43258 - "POST /v1/chat/completions HTTP/1.1" 200 OK
(APIServer pid=1) INFO 05-14 09:43:53 [loggers.py:271] Engine 000: Avg prompt throughput: 494.0 tokens/s, Avg generation throughput: 7.9 tokens/s, Running: 1 reqs, Waiting: 0 reqs, GPU KV cache usage: 0.8%, Prefix cache hit rate: 73.4%
(APIServer pid=1) INFO 05-14 09:43:53 [metrics.py:101] SpecDecoding metrics: Mean acceptance length: 2.36, Accepted throughput: 0.56 tokens/s, Drafted throughput: 0.82 tokens/s, Accepted: 45 tokens, Drafted: 66 tokens, Per-position acceptance rate: 0.788, 0.576, Avg Draft acceptance rate: 68.2%
(APIServer pid=1) INFO:     172.18.0.3:39928 - "POST /v1/chat/completions HTTP/1.1" 200 OK
(APIServer pid=1) INFO:     172.18.0.3:39938 - "POST /v1/chat/completions HTTP/1.1" 200 OK
(APIServer pid=1) INFO 05-14 09:44:03 [loggers.py:271] Engine 000: Avg prompt throughput: 909.6 tokens/s, Avg generation throughput: 32.9 tokens/s, Running: 1 reqs, Waiting: 0 reqs, GPU KV cache usage: 0.9%, Prefix cache hit rate: 76.6%
(APIServer pid=1) INFO 05-14 09:44:03 [metrics.py:101] SpecDecoding metrics: Mean acceptance length: 2.63, Accepted throughput: 20.50 tokens/s, Drafted throughput: 25.20 tokens/s, Accepted: 205 tokens, Drafted: 252 tokens, Per-position acceptance rate: 0.881, 0.746, Avg Draft acceptance rate: 81.3%
(APIServer pid=1) INFO:     172.18.0.3:49902 - "POST /v1/chat/completions HTTP/1.1" 200 OK
(APIServer pid=1) INFO:     172.18.0.3:49910 - "POST /v1/chat/completions HTTP/1.1" 200 OK
(APIServer pid=1) INFO:     172.18.0.3:49924 - "POST /v1/chat/completions HTTP/1.1" 200 OK
(APIServer pid=1) INFO:     172.18.0.3:49934 - "POST /v1/chat/completions HTTP/1.1" 200 OK
(APIServer pid=1) INFO 05-14 09:44:13 [loggers.py:271] Engine 000: Avg prompt throughput: 1182.3 tokens/s, Avg generation throughput: 23.5 tokens/s, Running: 0 reqs, Waiting: 0 reqs, GPU KV cache usage: 0.0%, Prefix cache hit rate: 80.2%
(APIServer pid=1) INFO 05-14 09:44:13 [metrics.py:101] SpecDecoding metrics: Mean acceptance length: 2.79, Accepted throughput: 15.00 tokens/s, Drafted throughput: 16.80 tokens/s, Accepted: 150 tokens, Drafted: 168 tokens, Per-position acceptance rate: 0.940, 0.845, Avg Draft acceptance rate: 89.3%
(APIServer pid=1) INFO:     172.18.0.3:37232 - "POST /v1/chat/completions HTTP/1.1" 200 OK
(APIServer pid=1) INFO 05-14 09:44:23 [loggers.py:271] Engine 000: Avg prompt throughput: 803.1 tokens/s, Avg generation throughput: 39.6 tokens/s, Running: 1 reqs, Waiting: 0 reqs, GPU KV cache usage: 1.0%, Prefix cache hit rate: 81.8%
(APIServer pid=1) INFO 05-14 09:44:23 [metrics.py:101] SpecDecoding metrics: Mean acceptance length: 2.54, Accepted throughput: 23.90 tokens/s, Drafted throughput: 31.00 tokens/s, Accepted: 239 tokens, Drafted: 310 tokens, Per-position acceptance rate: 0.826, 0.716, Avg Draft acceptance rate: 77.1%
(APIServer pid=1) INFO 05-14 09:44:33 [loggers.py:271] Engine 000: Avg prompt throughput: 0.0 tokens/s, Avg generation throughput: 47.2 tokens/s, Running: 1 reqs, Waiting: 0 reqs, GPU KV cache usage: 1.0%, Prefix cache hit rate: 81.8%
(APIServer pid=1) INFO 05-14 09:44:33 [metrics.py:101] SpecDecoding metrics: Mean acceptance length: 2.55, Accepted throughput: 28.70 tokens/s, Drafted throughput: 37.00 tokens/s, Accepted: 287 tokens, Drafted: 370 tokens, Per-position acceptance rate: 0.854, 0.697, Avg Draft acceptance rate: 77.6%
(APIServer pid=1) INFO 05-14 09:44:43 [loggers.py:271] Engine 000: Avg prompt throughput: 0.0 tokens/s, Avg generation throughput: 45.7 tokens/s, Running: 1 reqs, Waiting: 0 reqs, GPU KV cache usage: 1.0%, Prefix cache hit rate: 81.8%
(APIServer pid=1) INFO 05-14 09:44:43 [metrics.py:101] SpecDecoding metrics: Mean acceptance length: 2.46, Accepted throughput: 27.10 tokens/s, Drafted throughput: 37.20 tokens/s, Accepted: 271 tokens, Drafted: 372 tokens, Per-position acceptance rate: 0.806, 0.651, Avg Draft acceptance rate: 72.8%
(APIServer pid=1) INFO 05-14 09:44:53 [loggers.py:271] Engine 000: Avg prompt throughput: 0.0 tokens/s, Avg generation throughput: 48.6 tokens/s, Running: 1 reqs, Waiting: 0 reqs, GPU KV cache usage: 1.0%, Prefix cache hit rate: 81.8%
(APIServer pid=1) INFO 05-14 09:44:53 [metrics.py:101] SpecDecoding metrics: Mean acceptance length: 2.61, Accepted throughput: 30.00 tokens/s, Drafted throughput: 37.20 tokens/s, Accepted: 300 tokens, Drafted: 372 tokens, Per-position acceptance rate: 0.866, 0.747, Avg Draft acceptance rate: 80.6%
(APIServer pid=1) INFO 05-14 09:45:03 [loggers.py:271] Engine 000: Avg prompt throughput: 0.0 tokens/s, Avg generation throughput: 48.4 tokens/s, Running: 1 reqs, Waiting: 0 reqs, GPU KV cache usage: 1.0%, Prefix cache hit rate: 81.8%
(APIServer pid=1) INFO 05-14 09:45:03 [metrics.py:101] SpecDecoding metrics: Mean acceptance length: 2.62, Accepted throughput: 29.90 tokens/s, Drafted throughput: 37.00 tokens/s, Accepted: 299 tokens, Drafted: 370 tokens, Per-position acceptance rate: 0.897, 0.719, Avg Draft acceptance rate: 80.8%
(APIServer pid=1) INFO 05-14 09:45:13 [loggers.py:271] Engine 000: Avg prompt throughput: 0.0 tokens/s, Avg generation throughput: 13.7 tokens/s, Running: 0 reqs, Waiting: 0 reqs, GPU KV cache usage: 0.0%, Prefix cache hit rate: 81.8%
(APIServer pid=1) INFO 05-14 09:45:13 [metrics.py:101] SpecDecoding metrics: Mean acceptance length: 2.85, Accepted throughput: 8.90 tokens/s, Drafted throughput: 9.60 tokens/s, Accepted: 89 tokens, Drafted: 96 tokens, Per-position acceptance rate: 0.938, 0.917, Avg Draft acceptance rate: 92.7%
(APIServer pid=1) INFO 05-14 09:45:23 [loggers.py:271] Engine 000: Avg prompt throughput: 0.0 tokens/s, Avg generation throughput: 0.0 tokens/s, Running: 0 reqs, Waiting: 0 reqs, GPU KV cache usage: 0.0%, Prefix cache hit rate: 81.8%
(APIServer pid=1) INFO:     172.18.0.3:33670 - "POST /v1/chat/completions HTTP/1.1" 200 OK
(APIServer pid=1) INFO 05-14 09:48:03 [loggers.py:271] Engine 000: Avg prompt throughput: 478.0 tokens/s, Avg generation throughput: 26.4 tokens/s, Running: 0 reqs, Waiting: 0 reqs, GPU KV cache usage: 0.0%, Prefix cache hit rate: 82.4%
(APIServer pid=1) INFO 05-14 09:48:03 [metrics.py:101] SpecDecoding metrics: Mean acceptance length: 2.68, Accepted throughput: 0.97 tokens/s, Drafted throughput: 1.15 tokens/s, Accepted: 165 tokens, Drafted: 196 tokens, Per-position acceptance rate: 0.888, 0.796, Avg Draft acceptance rate: 84.2%
(APIServer pid=1) INFO:     172.18.0.3:55036 - "POST /v1/chat/completions HTTP/1.1" 200 OK
(APIServer pid=1) INFO:     172.18.0.3:55046 - "POST /v1/chat/completions HTTP/1.1" 200 OK
(APIServer pid=1) INFO 05-14 09:48:13 [loggers.py:271] Engine 000: Avg prompt throughput: 789.8 tokens/s, Avg generation throughput: 17.0 tokens/s, Running: 1 reqs, Waiting: 0 reqs, GPU KV cache usage: 1.0%, Prefix cache hit rate: 83.6%
(APIServer pid=1) INFO 05-14 09:48:13 [metrics.py:101] SpecDecoding metrics: Mean acceptance length: 2.49, Accepted throughput: 10.10 tokens/s, Drafted throughput: 13.60 tokens/s, Accepted: 101 tokens, Drafted: 136 tokens, Per-position acceptance rate: 0.794, 0.691, Avg Draft acceptance rate: 74.3%
(APIServer pid=1) INFO 05-14 09:48:23 [loggers.py:271] Engine 000: Avg prompt throughput: 0.0 tokens/s, Avg generation throughput: 52.8 tokens/s, Running: 1 reqs, Waiting: 0 reqs, GPU KV cache usage: 1.0%, Prefix cache hit rate: 83.6%
(APIServer pid=1) INFO 05-14 09:48:23 [metrics.py:101] SpecDecoding metrics: Mean acceptance length: 2.84, Accepted throughput: 34.20 tokens/s, Drafted throughput: 37.20 tokens/s, Accepted: 342 tokens, Drafted: 372 tokens, Per-position acceptance rate: 0.935, 0.903, Avg Draft acceptance rate: 91.9%
(APIServer pid=1) INFO 05-14 09:48:33 [loggers.py:271] Engine 000: Avg prompt throughput: 0.0 tokens/s, Avg generation throughput: 55.3 tokens/s, Running: 1 reqs, Waiting: 0 reqs, GPU KV cache usage: 1.0%, Prefix cache hit rate: 83.6%
(APIServer pid=1) INFO 05-14 09:48:33 [metrics.py:101] SpecDecoding metrics: Mean acceptance length: 2.97, Accepted throughput: 36.70 tokens/s, Drafted throughput: 37.20 tokens/s, Accepted: 367 tokens, Drafted: 372 tokens, Per-position acceptance rate: 0.995, 0.978, Avg Draft acceptance rate: 98.7%
(APIServer pid=1) INFO:     172.18.0.3:59434 - "POST /v1/chat/completions HTTP/1.1" 200 OK
(APIServer pid=1) INFO 05-14 09:48:43 [loggers.py:271] Engine 000: Avg prompt throughput: 471.0 tokens/s, Avg generation throughput: 23.1 tokens/s, Running: 1 reqs, Waiting: 0 reqs, GPU KV cache usage: 1.1%, Prefix cache hit rate: 84.0%
(APIServer pid=1) INFO 05-14 09:48:43 [metrics.py:101] SpecDecoding metrics: Mean acceptance length: 2.78, Accepted throughput: 14.80 tokens/s, Drafted throughput: 16.60 tokens/s, Accepted: 148 tokens, Drafted: 166 tokens, Per-position acceptance rate: 0.964, 0.819, Avg Draft acceptance rate: 89.2%
(APIServer pid=1) INFO 05-14 09:48:53 [loggers.py:271] Engine 000: Avg prompt throughput: 0.0 tokens/s, Avg generation throughput: 52.0 tokens/s, Running: 1 reqs, Waiting: 0 reqs, GPU KV cache usage: 1.1%, Prefix cache hit rate: 84.0%
(APIServer pid=1) INFO 05-14 09:48:53 [metrics.py:101] SpecDecoding metrics: Mean acceptance length: 2.80, Accepted throughput: 33.40 tokens/s, Drafted throughput: 37.20 tokens/s, Accepted: 334 tokens, Drafted: 372 tokens, Per-position acceptance rate: 0.925, 0.871, Avg Draft acceptance rate: 89.8%
(APIServer pid=1) INFO 05-14 09:49:03 [loggers.py:271] Engine 000: Avg prompt throughput: 0.0 tokens/s, Avg generation throughput: 52.0 tokens/s, Running: 1 reqs, Waiting: 0 reqs, GPU KV cache usage: 1.1%, Prefix cache hit rate: 84.0%
(APIServer pid=1) INFO 05-14 09:49:03 [metrics.py:101] SpecDecoding metrics: Mean acceptance length: 2.81, Accepted throughput: 33.50 tokens/s, Drafted throughput: 37.00 tokens/s, Accepted: 335 tokens, Drafted: 370 tokens, Per-position acceptance rate: 0.935, 0.876, Avg Draft acceptance rate: 90.5%
(APIServer pid=1) INFO:     172.18.0.3:56444 - "POST /v1/chat/completions HTTP/1.1" 200 OK
(APIServer pid=1) INFO 05-14 09:49:13 [loggers.py:271] Engine 000: Avg prompt throughput: 543.5 tokens/s, Avg generation throughput: 20.4 tokens/s, Running: 1 reqs, Waiting: 0 reqs, GPU KV cache usage: 1.1%, Prefix cache hit rate: 84.4%
(APIServer pid=1) INFO 05-14 09:49:13 [metrics.py:101] SpecDecoding metrics: Mean acceptance length: 2.54, Accepted throughput: 12.30 tokens/s, Drafted throughput: 16.00 tokens/s, Accepted: 123 tokens, Drafted: 160 tokens, Per-position acceptance rate: 0.838, 0.700, Avg Draft acceptance rate: 76.9%
(APIServer pid=1) INFO:     172.18.0.3:50830 - "POST /v1/chat/completions HTTP/1.1" 200 OK
(APIServer pid=1) INFO 05-14 09:49:23 [loggers.py:271] Engine 000: Avg prompt throughput: 417.6 tokens/s, Avg generation throughput: 25.0 tokens/s, Running: 1 reqs, Waiting: 0 reqs, GPU KV cache usage: 1.1%, Prefix cache hit rate: 84.9%
(APIServer pid=1) INFO 05-14 09:49:23 [metrics.py:101] SpecDecoding metrics: Mean acceptance length: 2.83, Accepted throughput: 16.10 tokens/s, Drafted throughput: 17.60 tokens/s, Accepted: 161 tokens, Drafted: 176 tokens, Per-position acceptance rate: 0.943, 0.886, Avg Draft acceptance rate: 91.5%
(APIServer pid=1) INFO:     172.18.0.3:53730 - "POST /v1/chat/completions HTTP/1.1" 200 OK
(APIServer pid=1) INFO 05-14 09:49:33 [loggers.py:271] Engine 000: Avg prompt throughput: 503.7 tokens/s, Avg generation throughput: 21.6 tokens/s, Running: 1 reqs, Waiting: 0 reqs, GPU KV cache usage: 1.1%, Prefix cache hit rate: 85.2%
(APIServer pid=1) INFO 05-14 09:49:33 [metrics.py:101] SpecDecoding metrics: Mean acceptance length: 2.65, Accepted throughput: 13.40 tokens/s, Drafted throughput: 16.20 tokens/s, Accepted: 134 tokens, Drafted: 162 tokens, Per-position acceptance rate: 0.877, 0.778, Avg Draft acceptance rate: 82.7%
(APIServer pid=1) INFO:     172.18.0.3:38810 - "POST /v1/chat/completions HTTP/1.1" 200 OK
(APIServer pid=1) INFO 05-14 09:49:43 [loggers.py:271] Engine 000: Avg prompt throughput: 0.0 tokens/s, Avg generation throughput: 28.9 tokens/s, Running: 0 reqs, Waiting: 0 reqs, GPU KV cache usage: 0.0%, Prefix cache hit rate: 85.2%
(APIServer pid=1) INFO 05-14 09:49:43 [metrics.py:101] SpecDecoding metrics: Mean acceptance length: 2.93, Accepted throughput: 19.10 tokens/s, Drafted throughput: 19.80 tokens/s, Accepted: 191 tokens, Drafted: 198 tokens, Per-position acceptance rate: 0.980, 0.949, Avg Draft acceptance rate: 96.5%
(APIServer pid=1) INFO 05-14 09:49:53 [loggers.py:271] Engine 000: Avg prompt throughput: 393.3 tokens/s, Avg generation throughput: 49.2 tokens/s, Running: 1 reqs, Waiting: 0 reqs, GPU KV cache usage: 1.2%, Prefix cache hit rate: 85.7%
(APIServer pid=1) INFO 05-14 09:49:53 [metrics.py:101] SpecDecoding metrics: Mean acceptance length: 2.84, Accepted throughput: 31.80 tokens/s, Drafted throughput: 34.60 tokens/s, Accepted: 318 tokens, Drafted: 346 tokens, Per-position acceptance rate: 0.983, 0.855, Avg Draft acceptance rate: 91.9%
(APIServer pid=1) INFO:     172.18.0.3:50808 - "POST /v1/chat/completions HTTP/1.1" 200 OK
(APIServer pid=1) INFO 05-14 09:50:03 [loggers.py:271] Engine 000: Avg prompt throughput: 491.0 tokens/s, Avg generation throughput: 22.8 tokens/s, Running: 1 reqs, Waiting: 0 reqs, GPU KV cache usage: 1.2%, Prefix cache hit rate: 86.0%
(APIServer pid=1) INFO 05-14 09:50:03 [metrics.py:101] SpecDecoding metrics: Mean acceptance length: 2.90, Accepted throughput: 15.00 tokens/s, Drafted throughput: 15.80 tokens/s, Accepted: 150 tokens, Drafted: 158 tokens, Per-position acceptance rate: 0.975, 0.924, Avg Draft acceptance rate: 94.9%
(APIServer pid=1) INFO:     172.18.0.3:55694 - "POST /v1/chat/completions HTTP/1.1" 200 OK
(APIServer pid=1) INFO 05-14 09:50:13 [loggers.py:271] Engine 000: Avg prompt throughput: 407.8 tokens/s, Avg generation throughput: 25.7 tokens/s, Running: 1 reqs, Waiting: 0 reqs, GPU KV cache usage: 1.2%, Prefix cache hit rate: 86.3%
(APIServer pid=1) INFO 05-14 09:50:13 [metrics.py:101] SpecDecoding metrics: Mean acceptance length: 2.99, Accepted throughput: 17.10 tokens/s, Drafted throughput: 17.20 tokens/s, Accepted: 171 tokens, Drafted: 172 tokens, Per-position acceptance rate: 1.000, 0.988, Avg Draft acceptance rate: 99.4%
(APIServer pid=1) INFO:     172.18.0.3:43324 - "POST /v1/chat/completions HTTP/1.1" 200 OK
(APIServer pid=1) INFO 05-14 09:50:23 [loggers.py:271] Engine 000: Avg prompt throughput: 0.0 tokens/s, Avg generation throughput: 25.3 tokens/s, Running: 0 reqs, Waiting: 0 reqs, GPU KV cache usage: 0.0%, Prefix cache hit rate: 86.3%
(APIServer pid=1) INFO 05-14 09:50:23 [metrics.py:101] SpecDecoding metrics: Mean acceptance length: 2.98, Accepted throughput: 16.80 tokens/s, Drafted throughput: 17.00 tokens/s, Accepted: 168 tokens, Drafted: 170 tokens, Per-position acceptance rate: 0.988, 0.988, Avg Draft acceptance rate: 98.8%
(APIServer pid=1) INFO:     172.18.0.3:45820 - "POST /v1/chat/completions HTTP/1.1" 200 OK
(APIServer pid=1) INFO 05-14 09:50:33 [loggers.py:271] Engine 000: Avg prompt throughput: 901.5 tokens/s, Avg generation throughput: 24.1 tokens/s, Running: 1 reqs, Waiting: 0 reqs, GPU KV cache usage: 1.2%, Prefix cache hit rate: 86.9%
(APIServer pid=1) INFO 05-14 09:50:33 [metrics.py:101] SpecDecoding metrics: Mean acceptance length: 2.96, Accepted throughput: 15.90 tokens/s, Drafted throughput: 16.20 tokens/s, Accepted: 159 tokens, Drafted: 162 tokens, Per-position acceptance rate: 0.988, 0.975, Avg Draft acceptance rate: 98.1%
(APIServer pid=1) INFO:     172.18.0.3:41244 - "POST /v1/chat/completions HTTP/1.1" 200 OK
(APIServer pid=1) INFO 05-14 09:50:43 [loggers.py:271] Engine 000: Avg prompt throughput: 0.0 tokens/s, Avg generation throughput: 26.9 tokens/s, Running: 0 reqs, Waiting: 0 reqs, GPU KV cache usage: 0.0%, Prefix cache hit rate: 86.9%
(APIServer pid=1) INFO 05-14 09:50:43 [metrics.py:101] SpecDecoding metrics: Mean acceptance length: 2.95, Accepted throughput: 17.90 tokens/s, Drafted throughput: 18.40 tokens/s, Accepted: 179 tokens, Drafted: 184 tokens, Per-position acceptance rate: 0.978, 0.967, Avg Draft acceptance rate: 97.3%
(APIServer pid=1) INFO:     172.18.0.3:60252 - "POST /v1/chat/completions HTTP/1.1" 200 OK
(APIServer pid=1) INFO 05-14 09:50:53 [loggers.py:271] Engine 000: Avg prompt throughput: 891.8 tokens/s, Avg generation throughput: 39.5 tokens/s, Running: 1 reqs, Waiting: 0 reqs, GPU KV cache usage: 1.2%, Prefix cache hit rate: 87.4%
(APIServer pid=1) INFO 05-14 09:50:53 [metrics.py:101] SpecDecoding metrics: Mean acceptance length: 2.86, Accepted throughput: 25.70 tokens/s, Drafted throughput: 27.60 tokens/s, Accepted: 257 tokens, Drafted: 276 tokens, Per-position acceptance rate: 0.949, 0.913, Avg Draft acceptance rate: 93.1%
(APIServer pid=1) INFO:     172.18.0.3:41360 - "POST /v1/chat/completions HTTP/1.1" 200 OK
(APIServer pid=1) INFO 05-14 09:51:03 [loggers.py:271] Engine 000: Avg prompt throughput: 0.0 tokens/s, Avg generation throughput: 28.8 tokens/s, Running: 0 reqs, Waiting: 0 reqs, GPU KV cache usage: 0.0%, Prefix cache hit rate: 87.4%
(APIServer pid=1) INFO 05-14 09:51:03 [metrics.py:101] SpecDecoding metrics: Mean acceptance length: 2.96, Accepted throughput: 19.20 tokens/s, Drafted throughput: 19.60 tokens/s, Accepted: 192 tokens, Drafted: 196 tokens, Per-position acceptance rate: 1.000, 0.959, Avg Draft acceptance rate: 98.0%
(APIServer pid=1) INFO 05-14 09:51:13 [loggers.py:271] Engine 000: Avg prompt throughput: 549.0 tokens/s, Avg generation throughput: 41.0 tokens/s, Running: 1 reqs, Waiting: 0 reqs, GPU KV cache usage: 1.3%, Prefix cache hit rate: 87.6%
(APIServer pid=1) INFO 05-14 09:51:13 [metrics.py:101] SpecDecoding metrics: Mean acceptance length: 2.54, Accepted throughput: 24.80 tokens/s, Drafted throughput: 32.20 tokens/s, Accepted: 248 tokens, Drafted: 322 tokens, Per-position acceptance rate: 0.851, 0.689, Avg Draft acceptance rate: 77.0%
(APIServer pid=1) INFO 05-14 09:51:23 [loggers.py:271] Engine 000: Avg prompt throughput: 0.0 tokens/s, Avg generation throughput: 55.2 tokens/s, Running: 1 reqs, Waiting: 0 reqs, GPU KV cache usage: 1.3%, Prefix cache hit rate: 87.6%
(APIServer pid=1) INFO 05-14 09:51:23 [metrics.py:101] SpecDecoding metrics: Mean acceptance length: 3.00, Accepted throughput: 36.79 tokens/s, Drafted throughput: 36.79 tokens/s, Accepted: 368 tokens, Drafted: 368 tokens, Per-position acceptance rate: 1.000, 1.000, Avg Draft acceptance rate: 100.0%
(APIServer pid=1) INFO:     172.18.0.3:59918 - "POST /v1/chat/completions HTTP/1.1" 200 OK
(APIServer pid=1) INFO 05-14 09:51:33 [loggers.py:271] Engine 000: Avg prompt throughput: 571.5 tokens/s, Avg generation throughput: 20.6 tokens/s, Running: 1 reqs, Waiting: 0 reqs, GPU KV cache usage: 1.3%, Prefix cache hit rate: 87.8%
(APIServer pid=1) INFO 05-14 09:51:33 [metrics.py:101] SpecDecoding metrics: Mean acceptance length: 2.88, Accepted throughput: 13.46 tokens/s, Drafted throughput: 14.36 tokens/s, Accepted: 135 tokens, Drafted: 144 tokens, Per-position acceptance rate: 0.972, 0.903, Avg Draft acceptance rate: 93.8%
(APIServer pid=1) INFO 05-14 09:51:43 [loggers.py:271] Engine 000: Avg prompt throughput: 0.0 tokens/s, Avg generation throughput: 51.6 tokens/s, Running: 1 reqs, Waiting: 0 reqs, GPU KV cache usage: 1.3%, Prefix cache hit rate: 87.8%
(APIServer pid=1) INFO 05-14 09:51:43 [metrics.py:101] SpecDecoding metrics: Mean acceptance length: 2.80, Accepted throughput: 33.20 tokens/s, Drafted throughput: 36.80 tokens/s, Accepted: 332 tokens, Drafted: 368 tokens, Per-position acceptance rate: 0.935, 0.870, Avg Draft acceptance rate: 90.2%
(APIServer pid=1) INFO 05-14 09:51:53 [loggers.py:271] Engine 000: Avg prompt throughput: 0.0 tokens/s, Avg generation throughput: 46.7 tokens/s, Running: 0 reqs, Waiting: 0 reqs, GPU KV cache usage: 0.0%, Prefix cache hit rate: 87.8%
(APIServer pid=1) INFO 05-14 09:51:53 [metrics.py:101] SpecDecoding metrics: Mean acceptance length: 3.00, Accepted throughput: 31.20 tokens/s, Drafted throughput: 31.20 tokens/s, Accepted: 312 tokens, Drafted: 312 tokens, Per-position acceptance rate: 1.000, 1.000, Avg Draft acceptance rate: 100.0%
(APIServer pid=1) INFO:     172.18.0.3:49950 - "POST /v1/chat/completions HTTP/1.1" 200 OK
(APIServer pid=1) INFO 05-14 09:52:03 [loggers.py:271] Engine 000: Avg prompt throughput: 591.7 tokens/s, Avg generation throughput: 28.3 tokens/s, Running: 1 reqs, Waiting: 0 reqs, GPU KV cache usage: 1.3%, Prefix cache hit rate: 87.9%
(APIServer pid=1) INFO 05-14 09:52:03 [metrics.py:101] SpecDecoding metrics: Mean acceptance length: 2.88, Accepted throughput: 18.40 tokens/s, Drafted throughput: 19.60 tokens/s, Accepted: 184 tokens, Drafted: 196 tokens, Per-position acceptance rate: 0.959, 0.918, Avg Draft acceptance rate: 93.9%
(APIServer pid=1) INFO 05-14 09:52:13 [loggers.py:271] Engine 000: Avg prompt throughput: 0.0 tokens/s, Avg generation throughput: 53.1 tokens/s, Running: 1 reqs, Waiting: 0 reqs, GPU KV cache usage: 1.4%, Prefix cache hit rate: 87.9%
(APIServer pid=1) INFO 05-14 09:52:13 [metrics.py:101] SpecDecoding metrics: Mean acceptance length: 2.90, Accepted throughput: 34.80 tokens/s, Drafted throughput: 36.60 tokens/s, Accepted: 348 tokens, Drafted: 366 tokens, Per-position acceptance rate: 0.962, 0.940, Avg Draft acceptance rate: 95.1%
(APIServer pid=1) INFO 05-14 09:52:23 [loggers.py:271] Engine 000: Avg prompt throughput: 0.0 tokens/s, Avg generation throughput: 55.2 tokens/s, Running: 1 reqs, Waiting: 0 reqs, GPU KV cache usage: 1.4%, Prefix cache hit rate: 87.9%
(APIServer pid=1) INFO 05-14 09:52:23 [metrics.py:101] SpecDecoding metrics: Mean acceptance length: 3.00, Accepted throughput: 36.80 tokens/s, Drafted throughput: 36.80 tokens/s, Accepted: 368 tokens, Drafted: 368 tokens, Per-position acceptance rate: 1.000, 1.000, Avg Draft acceptance rate: 100.0%
(APIServer pid=1) INFO:     172.18.0.3:33846 - "POST /v1/chat/completions HTTP/1.1" 200 OK
(APIServer pid=1) INFO 05-14 09:52:33 [loggers.py:271] Engine 000: Avg prompt throughput: 715.9 tokens/s, Avg generation throughput: 15.8 tokens/s, Running: 1 reqs, Waiting: 0 reqs, GPU KV cache usage: 1.4%, Prefix cache hit rate: 88.0%
(APIServer pid=1) INFO 05-14 09:52:33 [metrics.py:101] SpecDecoding metrics: Mean acceptance length: 2.57, Accepted throughput: 9.60 tokens/s, Drafted throughput: 12.20 tokens/s, Accepted: 96 tokens, Drafted: 122 tokens, Per-position acceptance rate: 0.885, 0.689, Avg Draft acceptance rate: 78.7%
(APIServer pid=1) INFO 05-14 09:52:43 [loggers.py:271] Engine 000: Avg prompt throughput: 0.0 tokens/s, Avg generation throughput: 52.2 tokens/s, Running: 1 reqs, Waiting: 0 reqs, GPU KV cache usage: 1.4%, Prefix cache hit rate: 88.0%
(APIServer pid=1) INFO 05-14 09:52:43 [metrics.py:101] SpecDecoding metrics: Mean acceptance length: 2.85, Accepted throughput: 33.90 tokens/s, Drafted throughput: 36.60 tokens/s, Accepted: 339 tokens, Drafted: 366 tokens, Per-position acceptance rate: 0.940, 0.913, Avg Draft acceptance rate: 92.6%
(APIServer pid=1) INFO 05-14 09:52:53 [loggers.py:271] Engine 000: Avg prompt throughput: 0.0 tokens/s, Avg generation throughput: 52.6 tokens/s, Running: 0 reqs, Waiting: 0 reqs, GPU KV cache usage: 0.0%, Prefix cache hit rate: 88.0%
(APIServer pid=1) INFO 05-14 09:52:53 [metrics.py:101] SpecDecoding metrics: Mean acceptance length: 2.94, Accepted throughput: 34.80 tokens/s, Drafted throughput: 35.80 tokens/s, Accepted: 348 tokens, Drafted: 358 tokens, Per-position acceptance rate: 0.972, 0.972, Avg Draft acceptance rate: 97.2%
(APIServer pid=1) INFO:     172.18.0.3:54826 - "POST /v1/chat/completions HTTP/1.1" 200 OK
(APIServer pid=1) INFO 05-14 09:53:03 [loggers.py:271] Engine 000: Avg prompt throughput: 369.4 tokens/s, Avg generation throughput: 34.8 tokens/s, Running: 0 reqs, Waiting: 0 reqs, GPU KV cache usage: 0.0%, Prefix cache hit rate: 88.3%
(APIServer pid=1) INFO 05-14 09:53:03 [metrics.py:101] SpecDecoding metrics: Mean acceptance length: 2.87, Accepted throughput: 22.60 tokens/s, Drafted throughput: 24.20 tokens/s, Accepted: 226 tokens, Drafted: 242 tokens, Per-position acceptance rate: 0.950, 0.917, Avg Draft acceptance rate: 93.4%
(APIServer pid=1) INFO:     172.18.0.3:32800 - "POST /v1/chat/completions HTTP/1.1" 200 OK
(APIServer pid=1) INFO 05-14 09:53:13 [loggers.py:271] Engine 000: Avg prompt throughput: 482.5 tokens/s, Avg generation throughput: 21.3 tokens/s, Running: 1 reqs, Waiting: 0 reqs, GPU KV cache usage: 1.4%, Prefix cache hit rate: 88.5%
(APIServer pid=1) INFO 05-14 09:53:13 [metrics.py:101] SpecDecoding metrics: Mean acceptance length: 2.86, Accepted throughput: 13.80 tokens/s, Drafted throughput: 14.80 tokens/s, Accepted: 138 tokens, Drafted: 148 tokens, Per-position acceptance rate: 0.946, 0.919, Avg Draft acceptance rate: 93.2%
(APIServer pid=1) INFO:     172.18.0.3:47620 - "POST /v1/chat/completions HTTP/1.1" 200 OK
(APIServer pid=1) INFO 05-14 09:53:23 [loggers.py:271] Engine 000: Avg prompt throughput: 386.5 tokens/s, Avg generation throughput: 22.8 tokens/s, Running: 1 reqs, Waiting: 0 reqs, GPU KV cache usage: 1.4%, Prefix cache hit rate: 88.8%
(APIServer pid=1) INFO 05-14 09:53:23 [metrics.py:101] SpecDecoding metrics: Mean acceptance length: 2.80, Accepted throughput: 14.60 tokens/s, Drafted throughput: 16.20 tokens/s, Accepted: 146 tokens, Drafted: 162 tokens, Per-position acceptance rate: 0.914, 0.889, Avg Draft acceptance rate: 90.1%
(APIServer pid=1) INFO:     172.18.0.3:36102 - "POST /v1/chat/completions HTTP/1.1" 200 OK
(APIServer pid=1) INFO:     172.18.0.3:36116 - "POST /v1/chat/completions HTTP/1.1" 200 OK
(APIServer pid=1) INFO 05-14 09:53:33 [loggers.py:271] Engine 000: Avg prompt throughput: 1064.9 tokens/s, Avg generation throughput: 24.2 tokens/s, Running: 1 reqs, Waiting: 0 reqs, GPU KV cache usage: 1.5%, Prefix cache hit rate: 89.1%
(APIServer pid=1) INFO 05-14 09:53:33 [metrics.py:101] SpecDecoding metrics: Mean acceptance length: 2.57, Accepted throughput: 14.80 tokens/s, Drafted throughput: 18.80 tokens/s, Accepted: 148 tokens, Drafted: 188 tokens, Per-position acceptance rate: 0.830, 0.745, Avg Draft acceptance rate: 78.7%
(APIServer pid=1) INFO:     172.18.0.3:47934 - "POST /v1/chat/completions HTTP/1.1" 200 OK
(APIServer pid=1) INFO 05-14 09:53:43 [loggers.py:271] Engine 000: Avg prompt throughput: 353.7 tokens/s, Avg generation throughput: 44.8 tokens/s, Running: 1 reqs, Waiting: 0 reqs, GPU KV cache usage: 1.5%, Prefix cache hit rate: 89.3%
(APIServer pid=1) INFO 05-14 09:53:43 [metrics.py:101] SpecDecoding metrics: Mean acceptance length: 2.75, Accepted throughput: 28.60 tokens/s, Drafted throughput: 32.60 tokens/s, Accepted: 286 tokens, Drafted: 326 tokens, Per-position acceptance rate: 0.920, 0.834, Avg Draft acceptance rate: 87.7%
(APIServer pid=1) INFO 05-14 09:53:53 [loggers.py:271] Engine 000: Avg prompt throughput: 0.0 tokens/s, Avg generation throughput: 36.7 tokens/s, Running: 0 reqs, Waiting: 0 reqs, GPU KV cache usage: 0.0%, Prefix cache hit rate: 89.3%
(APIServer pid=1) INFO 05-14 09:53:53 [metrics.py:101] SpecDecoding metrics: Mean acceptance length: 2.84, Accepted throughput: 23.80 tokens/s, Drafted throughput: 25.80 tokens/s, Accepted: 238 tokens, Drafted: 258 tokens, Per-position acceptance rate: 0.969, 0.876, Avg Draft acceptance rate: 92.2%
(APIServer pid=1) INFO 05-14 09:54:03 [loggers.py:271] Engine 000: Avg prompt throughput: 0.0 tokens/s, Avg generation throughput: 0.0 tokens/s, Running: 0 reqs, Waiting: 0 reqs, GPU KV cache usage: 0.0%, Prefix cache hit rate: 89.3%
(APIServer pid=1) INFO:     172.18.0.3:58016 - "POST /v1/chat/completions HTTP/1.1" 200 OK
(APIServer pid=1) INFO:     172.18.0.3:58032 - "POST /v1/chat/completions HTTP/1.1" 200 OK
(APIServer pid=1) INFO 05-14 10:13:43 [loggers.py:271] Engine 000: Avg prompt throughput: 480.3 tokens/s, Avg generation throughput: 19.3 tokens/s, Running: 0 reqs, Waiting: 0 reqs, GPU KV cache usage: 0.0%, Prefix cache hit rate: 89.5%
(APIServer pid=1) INFO 05-14 10:13:43 [metrics.py:101] SpecDecoding metrics: Mean acceptance length: 2.73, Accepted throughput: 0.10 tokens/s, Drafted throughput: 0.12 tokens/s, Accepted: 123 tokens, Drafted: 142 tokens, Per-position acceptance rate: 0.930, 0.803, Avg Draft acceptance rate: 86.6%
(APIServer pid=1) INFO:     172.18.0.3:50562 - "POST /v1/chat/completions HTTP/1.1" 200 OK
(APIServer pid=1) INFO 05-14 10:13:53 [loggers.py:271] Engine 000: Avg prompt throughput: 354.5 tokens/s, Avg generation throughput: 22.4 tokens/s, Running: 0 reqs, Waiting: 0 reqs, GPU KV cache usage: 0.0%, Prefix cache hit rate: 89.7%
(APIServer pid=1) INFO 05-14 10:13:53 [metrics.py:101] SpecDecoding metrics: Mean acceptance length: 2.84, Accepted throughput: 14.50 tokens/s, Drafted throughput: 15.80 tokens/s, Accepted: 145 tokens, Drafted: 158 tokens, Per-position acceptance rate: 0.949, 0.886, Avg Draft acceptance rate: 91.8%
(APIServer pid=1) INFO:     172.18.0.3:32910 - "POST /v1/chat/completions HTTP/1.1" 200 OK
(APIServer pid=1) INFO 05-14 10:14:03 [loggers.py:271] Engine 000: Avg prompt throughput: 464.9 tokens/s, Avg generation throughput: 26.2 tokens/s, Running: 0 reqs, Waiting: 0 reqs, GPU KV cache usage: 0.0%, Prefix cache hit rate: 89.9%
(APIServer pid=1) INFO 05-14 10:14:03 [metrics.py:101] SpecDecoding metrics: Mean acceptance length: 2.79, Accepted throughput: 16.80 tokens/s, Drafted throughput: 18.80 tokens/s, Accepted: 168 tokens, Drafted: 188 tokens, Per-position acceptance rate: 0.915, 0.872, Avg Draft acceptance rate: 89.4%
(APIServer pid=1) INFO 05-14 10:14:13 [loggers.py:271] Engine 000: Avg prompt throughput: 372.3 tokens/s, Avg generation throughput: 44.8 tokens/s, Running: 0 reqs, Waiting: 0 reqs, GPU KV cache usage: 0.0%, Prefix cache hit rate: 90.1%
(APIServer pid=1) INFO 05-14 10:14:13 [metrics.py:101] SpecDecoding metrics: Mean acceptance length: 2.90, Accepted throughput: 29.30 tokens/s, Drafted throughput: 30.80 tokens/s, Accepted: 293 tokens, Drafted: 308 tokens, Per-position acceptance rate: 0.974, 0.929, Avg Draft acceptance rate: 95.1%
(APIServer pid=1) INFO 05-14 10:14:23 [loggers.py:271] Engine 000: Avg prompt throughput: 0.0 tokens/s, Avg generation throughput: 0.0 tokens/s, Running: 0 reqs, Waiting: 0 reqs, GPU KV cache usage: 0.0%, Prefix cache hit rate: 90.1%
(APIServer pid=1) INFO:     172.18.0.3:39380 - "POST /v1/chat/completions HTTP/1.1" 200 OK
(APIServer pid=1) INFO 05-14 10:17:23 [loggers.py:271] Engine 000: Avg prompt throughput: 1028.7 tokens/s, Avg generation throughput: 22.1 tokens/s, Running: 1 reqs, Waiting: 0 reqs, GPU KV cache usage: 1.7%, Prefix cache hit rate: 90.0%
(APIServer pid=1) INFO 05-14 10:17:23 [metrics.py:101] SpecDecoding metrics: Mean acceptance length: 2.37, Accepted throughput: 0.67 tokens/s, Drafted throughput: 0.98 tokens/s, Accepted: 127 tokens, Drafted: 186 tokens, Per-position acceptance rate: 0.785, 0.581, Avg Draft acceptance rate: 68.3%
(APIServer pid=1) INFO 05-14 10:17:33 [loggers.py:271] Engine 000: Avg prompt throughput: 0.0 tokens/s, Avg generation throughput: 12.3 tokens/s, Running: 0 reqs, Waiting: 0 reqs, GPU KV cache usage: 0.0%, Prefix cache hit rate: 90.0%
(APIServer pid=1) INFO 05-14 10:17:33 [metrics.py:101] SpecDecoding metrics: Mean acceptance length: 2.80, Accepted throughput: 7.90 tokens/s, Drafted throughput: 8.80 tokens/s, Accepted: 79 tokens, Drafted: 88 tokens, Per-position acceptance rate: 0.909, 0.886, Avg Draft acceptance rate: 89.8%
(APIServer pid=1) INFO:     172.18.0.3:36788 - "POST /v1/chat/completions HTTP/1.1" 200 OK
(APIServer pid=1) INFO 05-14 10:17:43 [loggers.py:271] Engine 000: Avg prompt throughput: 1016.3 tokens/s, Avg generation throughput: 25.3 tokens/s, Running: 1 reqs, Waiting: 0 reqs, GPU KV cache usage: 1.8%, Prefix cache hit rate: 90.0%
(APIServer pid=1) INFO 05-14 10:17:43 [metrics.py:101] SpecDecoding metrics: Mean acceptance length: 2.80, Accepted throughput: 16.20 tokens/s, Drafted throughput: 18.00 tokens/s, Accepted: 162 tokens, Drafted: 180 tokens, Per-position acceptance rate: 0.933, 0.867, Avg Draft acceptance rate: 90.0%
(APIServer pid=1) INFO:     172.18.0.3:39300 - "POST /v1/chat/completions HTTP/1.1" 200 OK
(APIServer pid=1) INFO 05-14 10:17:53 [loggers.py:271] Engine 000: Avg prompt throughput: 499.8 tokens/s, Avg generation throughput: 19.0 tokens/s, Running: 1 reqs, Waiting: 0 reqs, GPU KV cache usage: 1.8%, Prefix cache hit rate: 90.2%
(APIServer pid=1) INFO 05-14 10:17:53 [metrics.py:101] SpecDecoding metrics: Mean acceptance length: 2.69, Accepted throughput: 12.00 tokens/s, Drafted throughput: 14.20 tokens/s, Accepted: 120 tokens, Drafted: 142 tokens, Per-position acceptance rate: 0.901, 0.789, Avg Draft acceptance rate: 84.5%
(APIServer pid=1) INFO 05-14 10:18:03 [loggers.py:271] Engine 000: Avg prompt throughput: 0.0 tokens/s, Avg generation throughput: 34.4 tokens/s, Running: 0 reqs, Waiting: 0 reqs, GPU KV cache usage: 0.0%, Prefix cache hit rate: 90.2%
(APIServer pid=1) INFO 05-14 10:18:03 [metrics.py:101] SpecDecoding metrics: Mean acceptance length: 2.95, Accepted throughput: 22.80 tokens/s, Drafted throughput: 23.40 tokens/s, Accepted: 228 tokens, Drafted: 234 tokens, Per-position acceptance rate: 0.983, 0.966, Avg Draft acceptance rate: 97.4%
(APIServer pid=1) INFO 05-14 10:18:13 [loggers.py:271] Engine 000: Avg prompt throughput: 0.0 tokens/s, Avg generation throughput: 0.0 tokens/s, Running: 0 reqs, Waiting: 0 reqs, GPU KV cache usage: 0.0%, Prefix cache hit rate: 90.2%
(APIServer pid=1) INFO:     172.18.0.3:47220 - "POST /v1/chat/completions HTTP/1.1" 200 OK
(APIServer pid=1) INFO 05-14 10:19:23 [loggers.py:271] Engine 000: Avg prompt throughput: 415.4 tokens/s, Avg generation throughput: 21.2 tokens/s, Running: 1 reqs, Waiting: 0 reqs, GPU KV cache usage: 1.8%, Prefix cache hit rate: 90.4%
(APIServer pid=1) INFO 05-14 10:19:23 [metrics.py:101] SpecDecoding metrics: Mean acceptance length: 2.34, Accepted throughput: 1.51 tokens/s, Drafted throughput: 2.25 tokens/s, Accepted: 121 tokens, Drafted: 180 tokens, Per-position acceptance rate: 0.733, 0.611, Avg Draft acceptance rate: 67.2%
(APIServer pid=1) INFO:     172.18.0.3:54238 - "POST /v1/chat/completions HTTP/1.1" 200 OK
(APIServer pid=1) INFO 05-14 10:19:33 [loggers.py:271] Engine 000: Avg prompt throughput: 0.0 tokens/s, Avg generation throughput: 20.0 tokens/s, Running: 0 reqs, Waiting: 0 reqs, GPU KV cache usage: 0.0%, Prefix cache hit rate: 90.4%
(APIServer pid=1) INFO 05-14 10:19:33 [metrics.py:101] SpecDecoding metrics: Mean acceptance length: 2.56, Accepted throughput: 12.30 tokens/s, Drafted throughput: 15.80 tokens/s, Accepted: 123 tokens, Drafted: 158 tokens, Per-position acceptance rate: 0.861, 0.696, Avg Draft acceptance rate: 77.8%
(APIServer pid=1) INFO 05-14 10:19:43 [loggers.py:271] Engine 000: Avg prompt throughput: 564.2 tokens/s, Avg generation throughput: 39.9 tokens/s, Running: 0 reqs, Waiting: 0 reqs, GPU KV cache usage: 0.0%, Prefix cache hit rate: 90.5%
(APIServer pid=1) INFO 05-14 10:19:43 [metrics.py:101] SpecDecoding metrics: Mean acceptance length: 2.71, Accepted throughput: 25.20 tokens/s, Drafted throughput: 29.40 tokens/s, Accepted: 252 tokens, Drafted: 294 tokens, Per-position acceptance rate: 0.884, 0.830, Avg Draft acceptance rate: 85.7%
(APIServer pid=1) INFO 05-14 10:19:53 [loggers.py:271] Engine 000: Avg prompt throughput: 0.0 tokens/s, Avg generation throughput: 0.0 tokens/s, Running: 0 reqs, Waiting: 0 reqs, GPU KV cache usage: 0.0%, Prefix cache hit rate: 90.5%
(APIServer pid=1) INFO:     172.18.0.3:37082 - "POST /v1/chat/completions HTTP/1.1" 200 OK
(APIServer pid=1) INFO:     172.18.0.3:37096 - "POST /v1/chat/completions HTTP/1.1" 200 OK
(APIServer pid=1) INFO 05-14 10:20:03 [loggers.py:271] Engine 000: Avg prompt throughput: 465.3 tokens/s, Avg generation throughput: 6.7 tokens/s, Running: 0 reqs, Waiting: 0 reqs, GPU KV cache usage: 0.0%, Prefix cache hit rate: 90.7%
(APIServer pid=1) INFO 05-14 10:20:03 [metrics.py:101] SpecDecoding metrics: Mean acceptance length: 2.91, Accepted throughput: 2.20 tokens/s, Drafted throughput: 2.30 tokens/s, Accepted: 44 tokens, Drafted: 46 tokens, Per-position acceptance rate: 0.957, 0.957, Avg Draft acceptance rate: 95.7%
(APIServer pid=1) INFO:     172.18.0.3:50262 - "POST /v1/chat/completions HTTP/1.1" 200 OK
(APIServer pid=1) INFO 05-14 10:20:13 [loggers.py:271] Engine 000: Avg prompt throughput: 960.5 tokens/s, Avg generation throughput: 26.9 tokens/s, Running: 1 reqs, Waiting: 0 reqs, GPU KV cache usage: 1.9%, Prefix cache hit rate: 91.0%
(APIServer pid=1) INFO 05-14 10:20:13 [metrics.py:101] SpecDecoding metrics: Mean acceptance length: 2.63, Accepted throughput: 16.60 tokens/s, Drafted throughput: 20.40 tokens/s, Accepted: 166 tokens, Drafted: 204 tokens, Per-position acceptance rate: 0.882, 0.745, Avg Draft acceptance rate: 81.4%
(APIServer pid=1) INFO 05-14 10:20:23 [loggers.py:271] Engine 000: Avg prompt throughput: 0.0 tokens/s, Avg generation throughput: 19.2 tokens/s, Running: 0 reqs, Waiting: 0 reqs, GPU KV cache usage: 0.0%, Prefix cache hit rate: 91.0%
(APIServer pid=1) INFO 05-14 10:20:23 [metrics.py:101] SpecDecoding metrics: Mean acceptance length: 2.90, Accepted throughput: 12.70 tokens/s, Drafted throughput: 13.40 tokens/s, Accepted: 127 tokens, Drafted: 134 tokens, Per-position acceptance rate: 0.970, 0.925, Avg Draft acceptance rate: 94.8%
(APIServer pid=1) INFO 05-14 10:20:33 [loggers.py:271] Engine 000: Avg prompt throughput: 0.0 tokens/s, Avg generation throughput: 0.0 tokens/s, Running: 0 reqs, Waiting: 0 reqs, GPU KV cache usage: 0.0%, Prefix cache hit rate: 91.0%
(APIServer pid=1) INFO:     172.18.0.3:42036 - "POST /v1/chat/completions HTTP/1.1" 200 OK
(APIServer pid=1) INFO 05-14 10:21:43 [loggers.py:271] Engine 000: Avg prompt throughput: 973.5 tokens/s, Avg generation throughput: 34.9 tokens/s, Running: 0 reqs, Waiting: 0 reqs, GPU KV cache usage: 0.0%, Prefix cache hit rate: 91.0%
(APIServer pid=1) INFO 05-14 10:21:43 [metrics.py:101] SpecDecoding metrics: Mean acceptance length: 2.25, Accepted throughput: 2.41 tokens/s, Drafted throughput: 3.87 tokens/s, Accepted: 193 tokens, Drafted: 310 tokens, Per-position acceptance rate: 0.729, 0.516, Avg Draft acceptance rate: 62.3%
(APIServer pid=1) INFO 05-14 10:21:53 [loggers.py:271] Engine 000: Avg prompt throughput: 0.0 tokens/s, Avg generation throughput: 0.0 tokens/s, Running: 0 reqs, Waiting: 0 reqs, GPU KV cache usage: 0.0%, Prefix cache hit rate: 91.0%
(APIServer pid=1) INFO:     172.18.0.3:44546 - "POST /v1/chat/completions HTTP/1.1" 200 OK
(APIServer pid=1) INFO 05-14 10:25:43 [loggers.py:271] Engine 000: Avg prompt throughput: 688.1 tokens/s, Avg generation throughput: 48.0 tokens/s, Running: 1 reqs, Waiting: 0 reqs, GPU KV cache usage: 2.1%, Prefix cache hit rate: 91.1%
(APIServer pid=1) INFO 05-14 10:25:43 [metrics.py:101] SpecDecoding metrics: Mean acceptance length: 2.49, Accepted throughput: 1.20 tokens/s, Drafted throughput: 1.60 tokens/s, Accepted: 287 tokens, Drafted: 384 tokens, Per-position acceptance rate: 0.823, 0.672, Avg Draft acceptance rate: 74.7%
(APIServer pid=1) INFO 05-14 10:25:53 [loggers.py:271] Engine 000: Avg prompt throughput: 0.0 tokens/s, Avg generation throughput: 47.9 tokens/s, Running: 1 reqs, Waiting: 0 reqs, GPU KV cache usage: 2.1%, Prefix cache hit rate: 91.1%
(APIServer pid=1) INFO 05-14 10:25:53 [metrics.py:101] SpecDecoding metrics: Mean acceptance length: 2.42, Accepted throughput: 28.10 tokens/s, Drafted throughput: 39.59 tokens/s, Accepted: 281 tokens, Drafted: 396 tokens, Per-position acceptance rate: 0.788, 0.631, Avg Draft acceptance rate: 71.0%
(APIServer pid=1) INFO 05-14 10:26:03 [loggers.py:271] Engine 000: Avg prompt throughput: 0.0 tokens/s, Avg generation throughput: 16.9 tokens/s, Running: 0 reqs, Waiting: 0 reqs, GPU KV cache usage: 0.0%, Prefix cache hit rate: 91.1%
(APIServer pid=1) INFO 05-14 10:26:03 [metrics.py:101] SpecDecoding metrics: Mean acceptance length: 2.88, Accepted throughput: 11.10 tokens/s, Drafted throughput: 11.80 tokens/s, Accepted: 111 tokens, Drafted: 118 tokens, Per-position acceptance rate: 0.966, 0.915, Avg Draft acceptance rate: 94.1%
(APIServer pid=1) INFO 05-14 10:26:13 [loggers.py:271] Engine 000: Avg prompt throughput: 0.0 tokens/s, Avg generation throughput: 0.0 tokens/s, Running: 0 reqs, Waiting: 0 reqs, GPU KV cache usage: 0.0%, Prefix cache hit rate: 91.1%
(APIServer pid=1) INFO:     172.18.0.3:48364 - "POST /v1/chat/completions HTTP/1.1" 200 OK
(APIServer pid=1) INFO 05-14 10:27:33 [loggers.py:271] Engine 000: Avg prompt throughput: 464.8 tokens/s, Avg generation throughput: 12.6 tokens/s, Running: 1 reqs, Waiting: 0 reqs, GPU KV cache usage: 2.1%, Prefix cache hit rate: 91.3%
(APIServer pid=1) INFO 05-14 10:27:33 [metrics.py:101] SpecDecoding metrics: Mean acceptance length: 2.40, Accepted throughput: 0.81 tokens/s, Drafted throughput: 1.16 tokens/s, Accepted: 73 tokens, Drafted: 104 tokens, Per-position acceptance rate: 0.808, 0.596, Avg Draft acceptance rate: 70.2%
(APIServer pid=1) INFO 05-14 10:27:43 [loggers.py:271] Engine 000: Avg prompt throughput: 0.0 tokens/s, Avg generation throughput: 50.9 tokens/s, Running: 1 reqs, Waiting: 0 reqs, GPU KV cache usage: 2.1%, Prefix cache hit rate: 91.3%
(APIServer pid=1) INFO 05-14 10:27:43 [metrics.py:101] SpecDecoding metrics: Mean acceptance length: 2.57, Accepted throughput: 31.10 tokens/s, Drafted throughput: 39.60 tokens/s, Accepted: 311 tokens, Drafted: 396 tokens, Per-position acceptance rate: 0.838, 0.732, Avg Draft acceptance rate: 78.5%
(APIServer pid=1) INFO 05-14 10:27:53 [loggers.py:271] Engine 000: Avg prompt throughput: 0.0 tokens/s, Avg generation throughput: 25.0 tokens/s, Running: 0 reqs, Waiting: 0 reqs, GPU KV cache usage: 0.0%, Prefix cache hit rate: 91.3%
(APIServer pid=1) INFO 05-14 10:27:53 [metrics.py:101] SpecDecoding metrics: Mean acceptance length: 2.79, Accepted throughput: 16.10 tokens/s, Drafted throughput: 18.00 tokens/s, Accepted: 161 tokens, Drafted: 180 tokens, Per-position acceptance rate: 0.933, 0.856, Avg Draft acceptance rate: 89.4%
(APIServer pid=1) INFO 05-14 10:28:03 [loggers.py:271] Engine 000: Avg prompt throughput: 0.0 tokens/s, Avg generation throughput: 0.0 tokens/s, Running: 0 reqs, Waiting: 0 reqs, GPU KV cache usage: 0.0%, Prefix cache hit rate: 91.3%
(APIServer pid=1) INFO:     172.18.0.3:58502 - "POST /v1/chat/completions HTTP/1.1" 200 OK
(APIServer pid=1) INFO 05-14 10:28:23 [loggers.py:271] Engine 000: Avg prompt throughput: 450.5 tokens/s, Avg generation throughput: 10.8 tokens/s, Running: 1 reqs, Waiting: 0 reqs, GPU KV cache usage: 2.2%, Prefix cache hit rate: 91.4%
(APIServer pid=1) INFO 05-14 10:28:23 [metrics.py:101] SpecDecoding metrics: Mean acceptance length: 2.28, Accepted throughput: 2.00 tokens/s, Drafted throughput: 3.13 tokens/s, Accepted: 60 tokens, Drafted: 94 tokens, Per-position acceptance rate: 0.766, 0.511, Avg Draft acceptance rate: 63.8%
(APIServer pid=1) INFO 05-14 10:28:33 [loggers.py:271] Engine 000: Avg prompt throughput: 0.0 tokens/s, Avg generation throughput: 41.2 tokens/s, Running: 0 reqs, Waiting: 0 reqs, GPU KV cache usage: 0.0%, Prefix cache hit rate: 91.4%
(APIServer pid=1) INFO 05-14 10:28:33 [metrics.py:101] SpecDecoding metrics: Mean acceptance length: 2.82, Accepted throughput: 26.60 tokens/s, Drafted throughput: 29.20 tokens/s, Accepted: 266 tokens, Drafted: 292 tokens, Per-position acceptance rate: 0.938, 0.884, Avg Draft acceptance rate: 91.1%
(APIServer pid=1) INFO:     172.18.0.3:44668 - "POST /v1/chat/completions HTTP/1.1" 200 OK
(APIServer pid=1) INFO 05-14 10:28:43 [loggers.py:271] Engine 000: Avg prompt throughput: 360.0 tokens/s, Avg generation throughput: 7.6 tokens/s, Running: 1 reqs, Waiting: 0 reqs, GPU KV cache usage: 2.2%, Prefix cache hit rate: 91.6%
(APIServer pid=1) INFO 05-14 10:28:43 [metrics.py:101] SpecDecoding metrics: Mean acceptance length: 2.27, Accepted throughput: 4.20 tokens/s, Drafted throughput: 6.60 tokens/s, Accepted: 42 tokens, Drafted: 66 tokens, Per-position acceptance rate: 0.727, 0.545, Avg Draft acceptance rate: 63.6%
(APIServer pid=1) INFO:     172.18.0.3:34500 - "POST /v1/chat/completions HTTP/1.1" 200 OK
(APIServer pid=1) INFO 05-14 10:28:53 [loggers.py:271] Engine 000: Avg prompt throughput: 580.6 tokens/s, Avg generation throughput: 34.6 tokens/s, Running: 1 reqs, Waiting: 0 reqs, GPU KV cache usage: 2.2%, Prefix cache hit rate: 91.7%
(APIServer pid=1) INFO 05-14 10:28:53 [metrics.py:101] SpecDecoding metrics: Mean acceptance length: 2.91, Accepted throughput: 22.70 tokens/s, Drafted throughput: 23.80 tokens/s, Accepted: 227 tokens, Drafted: 238 tokens, Per-position acceptance rate: 0.975, 0.933, Avg Draft acceptance rate: 95.4%
(APIServer pid=1) INFO 05-14 10:29:03 [loggers.py:271] Engine 000: Avg prompt throughput: 0.0 tokens/s, Avg generation throughput: 32.3 tokens/s, Running: 0 reqs, Waiting: 0 reqs, GPU KV cache usage: 0.0%, Prefix cache hit rate: 91.7%
(APIServer pid=1) INFO 05-14 10:29:03 [metrics.py:101] SpecDecoding metrics: Mean acceptance length: 2.99, Accepted throughput: 21.50 tokens/s, Drafted throughput: 21.60 tokens/s, Accepted: 215 tokens, Drafted: 216 tokens, Per-position acceptance rate: 1.000, 0.991, Avg Draft acceptance rate: 99.5%
(APIServer pid=1) INFO:     172.18.0.3:59958 - "POST /v1/chat/completions HTTP/1.1" 200 OK
(APIServer pid=1) INFO 05-14 10:29:13 [loggers.py:271] Engine 000: Avg prompt throughput: 581.9 tokens/s, Avg generation throughput: 33.4 tokens/s, Running: 1 reqs, Waiting: 0 reqs, GPU KV cache usage: 2.2%, Prefix cache hit rate: 91.8%
(APIServer pid=1) INFO 05-14 10:29:13 [metrics.py:101] SpecDecoding metrics: Mean acceptance length: 2.95, Accepted throughput: 22.00 tokens/s, Drafted throughput: 22.60 tokens/s, Accepted: 220 tokens, Drafted: 226 tokens, Per-position acceptance rate: 0.991, 0.956, Avg Draft acceptance rate: 97.3%
(APIServer pid=1) INFO:     172.18.0.3:44338 - "POST /v1/chat/completions HTTP/1.1" 200 OK
(APIServer pid=1) INFO 05-14 10:29:23 [loggers.py:271] Engine 000: Avg prompt throughput: 571.0 tokens/s, Avg generation throughput: 12.3 tokens/s, Running: 1 reqs, Waiting: 0 reqs, GPU KV cache usage: 2.3%, Prefix cache hit rate: 92.0%
(APIServer pid=1) INFO 05-14 10:29:23 [metrics.py:101] SpecDecoding metrics: Mean acceptance length: 2.76, Accepted throughput: 7.90 tokens/s, Drafted throughput: 9.00 tokens/s, Accepted: 79 tokens, Drafted: 90 tokens, Per-position acceptance rate: 0.933, 0.822, Avg Draft acceptance rate: 87.8%
(APIServer pid=1) INFO 05-14 10:29:33 [loggers.py:271] Engine 000: Avg prompt throughput: 0.0 tokens/s, Avg generation throughput: 39.7 tokens/s, Running: 0 reqs, Waiting: 0 reqs, GPU KV cache usage: 0.0%, Prefix cache hit rate: 92.0%
(APIServer pid=1) INFO 05-14 10:29:33 [metrics.py:101] SpecDecoding metrics: Mean acceptance length: 2.91, Accepted throughput: 26.20 tokens/s, Drafted throughput: 27.40 tokens/s, Accepted: 262 tokens, Drafted: 274 tokens, Per-position acceptance rate: 0.971, 0.942, Avg Draft acceptance rate: 95.6%
(APIServer pid=1) INFO:     172.18.0.3:50920 - "POST /v1/chat/completions HTTP/1.1" 200 OK
(APIServer pid=1) INFO 05-14 10:29:43 [loggers.py:271] Engine 000: Avg prompt throughput: 558.0 tokens/s, Avg generation throughput: 24.5 tokens/s, Running: 1 reqs, Waiting: 0 reqs, GPU KV cache usage: 2.3%, Prefix cache hit rate: 92.1%
(APIServer pid=1) INFO 05-14 10:29:43 [metrics.py:101] SpecDecoding metrics: Mean acceptance length: 2.87, Accepted throughput: 15.90 tokens/s, Drafted throughput: 17.00 tokens/s, Accepted: 159 tokens, Drafted: 170 tokens, Per-position acceptance rate: 0.965, 0.906, Avg Draft acceptance rate: 93.5%
(APIServer pid=1) INFO 05-14 10:29:53 [loggers.py:271] Engine 000: Avg prompt throughput: 0.0 tokens/s, Avg generation throughput: 52.4 tokens/s, Running: 1 reqs, Waiting: 0 reqs, GPU KV cache usage: 2.3%, Prefix cache hit rate: 92.1%
(APIServer pid=1) INFO 05-14 10:29:53 [metrics.py:101] SpecDecoding metrics: Mean acceptance length: 2.93, Accepted throughput: 34.49 tokens/s, Drafted throughput: 35.79 tokens/s, Accepted: 345 tokens, Drafted: 358 tokens, Per-position acceptance rate: 0.978, 0.950, Avg Draft acceptance rate: 96.4%
(APIServer pid=1) INFO:     172.18.0.3:59446 - "POST /v1/chat/completions HTTP/1.1" 200 OK
(APIServer pid=1) INFO 05-14 10:30:03 [loggers.py:271] Engine 000: Avg prompt throughput: 561.0 tokens/s, Avg generation throughput: 13.7 tokens/s, Running: 1 reqs, Waiting: 0 reqs, GPU KV cache usage: 2.3%, Prefix cache hit rate: 92.2%
(APIServer pid=1) INFO 05-14 10:30:03 [metrics.py:101] SpecDecoding metrics: Mean acceptance length: 2.98, Accepted throughput: 9.10 tokens/s, Drafted throughput: 9.20 tokens/s, Accepted: 91 tokens, Drafted: 92 tokens, Per-position acceptance rate: 1.000, 0.978, Avg Draft acceptance rate: 98.9%
(APIServer pid=1) INFO 05-14 10:30:13 [loggers.py:271] Engine 000: Avg prompt throughput: 0.0 tokens/s, Avg generation throughput: 52.5 tokens/s, Running: 1 reqs, Waiting: 0 reqs, GPU KV cache usage: 2.3%, Prefix cache hit rate: 92.2%
(APIServer pid=1) INFO 05-14 10:30:13 [metrics.py:101] SpecDecoding metrics: Mean acceptance length: 3.00, Accepted throughput: 34.99 tokens/s, Drafted throughput: 34.99 tokens/s, Accepted: 350 tokens, Drafted: 350 tokens, Per-position acceptance rate: 1.000, 1.000, Avg Draft acceptance rate: 100.0%
(APIServer pid=1) INFO:     172.18.0.3:34814 - "POST /v1/chat/completions HTTP/1.1" 200 OK
(APIServer pid=1) INFO 05-14 10:30:23 [loggers.py:271] Engine 000: Avg prompt throughput: 561.6 tokens/s, Avg generation throughput: 12.5 tokens/s, Running: 1 reqs, Waiting: 0 reqs, GPU KV cache usage: 2.4%, Prefix cache hit rate: 92.3%
(APIServer pid=1) INFO 05-14 10:30:23 [metrics.py:101] SpecDecoding metrics: Mean acceptance length: 2.93, Accepted throughput: 8.30 tokens/s, Drafted throughput: 8.60 tokens/s, Accepted: 83 tokens, Drafted: 86 tokens, Per-position acceptance rate: 0.977, 0.953, Avg Draft acceptance rate: 96.5%
(APIServer pid=1) INFO 05-14 10:30:33 [loggers.py:271] Engine 000: Avg prompt throughput: 0.0 tokens/s, Avg generation throughput: 52.7 tokens/s, Running: 1 reqs, Waiting: 0 reqs, GPU KV cache usage: 2.4%, Prefix cache hit rate: 92.3%
(APIServer pid=1) INFO 05-14 10:30:33 [metrics.py:101] SpecDecoding metrics: Mean acceptance length: 2.96, Accepted throughput: 34.90 tokens/s, Drafted throughput: 35.60 tokens/s, Accepted: 349 tokens, Drafted: 356 tokens, Per-position acceptance rate: 0.983, 0.978, Avg Draft acceptance rate: 98.0%
(APIServer pid=1) INFO:     172.18.0.3:43074 - "POST /v1/chat/completions HTTP/1.1" 200 OK
(APIServer pid=1) INFO 05-14 10:30:43 [loggers.py:271] Engine 000: Avg prompt throughput: 530.3 tokens/s, Avg generation throughput: 13.5 tokens/s, Running: 1 reqs, Waiting: 0 reqs, GPU KV cache usage: 2.4%, Prefix cache hit rate: 92.4%
(APIServer pid=1) INFO 05-14 10:30:43 [metrics.py:101] SpecDecoding metrics: Mean acceptance length: 3.00, Accepted throughput: 9.00 tokens/s, Drafted throughput: 9.00 tokens/s, Accepted: 90 tokens, Drafted: 90 tokens, Per-position acceptance rate: 1.000, 1.000, Avg Draft acceptance rate: 100.0%
(APIServer pid=1) INFO 05-14 10:30:53 [loggers.py:271] Engine 000: Avg prompt throughput: 0.0 tokens/s, Avg generation throughput: 44.2 tokens/s, Running: 0 reqs, Waiting: 0 reqs, GPU KV cache usage: 0.0%, Prefix cache hit rate: 92.4%
(APIServer pid=1) INFO 05-14 10:30:53 [metrics.py:101] SpecDecoding metrics: Mean acceptance length: 3.00, Accepted throughput: 29.60 tokens/s, Drafted throughput: 29.60 tokens/s, Accepted: 296 tokens, Drafted: 296 tokens, Per-position acceptance rate: 1.000, 1.000, Avg Draft acceptance rate: 100.0%
(APIServer pid=1) INFO:     172.18.0.3:43030 - "POST /v1/chat/completions HTTP/1.1" 200 OK
(APIServer pid=1) INFO 05-14 10:31:03 [loggers.py:271] Engine 000: Avg prompt throughput: 497.7 tokens/s, Avg generation throughput: 22.1 tokens/s, Running: 1 reqs, Waiting: 0 reqs, GPU KV cache usage: 2.4%, Prefix cache hit rate: 92.5%
(APIServer pid=1) INFO 05-14 10:31:03 [metrics.py:101] SpecDecoding metrics: Mean acceptance length: 2.78, Accepted throughput: 14.10 tokens/s, Drafted throughput: 15.80 tokens/s, Accepted: 141 tokens, Drafted: 158 tokens, Per-position acceptance rate: 0.937, 0.848, Avg Draft acceptance rate: 89.2%
(APIServer pid=1) INFO 05-14 10:31:13 [loggers.py:271] Engine 000: Avg prompt throughput: 0.0 tokens/s, Avg generation throughput: 51.6 tokens/s, Running: 1 reqs, Waiting: 0 reqs, GPU KV cache usage: 2.4%, Prefix cache hit rate: 92.5%
(APIServer pid=1) INFO 05-14 10:31:13 [metrics.py:101] SpecDecoding metrics: Mean acceptance length: 2.88, Accepted throughput: 33.70 tokens/s, Drafted throughput: 35.80 tokens/s, Accepted: 337 tokens, Drafted: 358 tokens, Per-position acceptance rate: 0.961, 0.922, Avg Draft acceptance rate: 94.1%
(APIServer pid=1) INFO 05-14 10:31:23 [loggers.py:271] Engine 000: Avg prompt throughput: 0.0 tokens/s, Avg generation throughput: 52.4 tokens/s, Running: 1 reqs, Waiting: 0 reqs, GPU KV cache usage: 2.4%, Prefix cache hit rate: 92.5%
(APIServer pid=1) INFO 05-14 10:31:23 [metrics.py:101] SpecDecoding metrics: Mean acceptance length: 2.93, Accepted throughput: 34.50 tokens/s, Drafted throughput: 35.80 tokens/s, Accepted: 345 tokens, Drafted: 358 tokens, Per-position acceptance rate: 0.978, 0.950, Avg Draft acceptance rate: 96.4%
(APIServer pid=1) INFO:     172.18.0.3:41522 - "POST /v1/chat/completions HTTP/1.1" 200 OK
(APIServer pid=1) INFO 05-14 10:31:33 [loggers.py:271] Engine 000: Avg prompt throughput: 0.0 tokens/s, Avg generation throughput: 13.5 tokens/s, Running: 0 reqs, Waiting: 0 reqs, GPU KV cache usage: 0.0%, Prefix cache hit rate: 92.5%
(APIServer pid=1) INFO 05-14 10:31:33 [metrics.py:101] SpecDecoding metrics: Mean acceptance length: 3.00, Accepted throughput: 9.00 tokens/s, Drafted throughput: 9.00 tokens/s, Accepted: 90 tokens, Drafted: 90 tokens, Per-position acceptance rate: 1.000, 1.000, Avg Draft acceptance rate: 100.0%
(APIServer pid=1) INFO 05-14 10:31:43 [loggers.py:271] Engine 000: Avg prompt throughput: 628.6 tokens/s, Avg generation throughput: 50.5 tokens/s, Running: 1 reqs, Waiting: 0 reqs, GPU KV cache usage: 2.5%, Prefix cache hit rate: 92.6%
(APIServer pid=1) INFO 05-14 10:31:43 [metrics.py:101] SpecDecoding metrics: Mean acceptance length: 2.98, Accepted throughput: 33.50 tokens/s, Drafted throughput: 33.80 tokens/s, Accepted: 335 tokens, Drafted: 338 tokens, Per-position acceptance rate: 0.994, 0.988, Avg Draft acceptance rate: 99.1%
(APIServer pid=1) INFO 05-14 10:31:53 [loggers.py:271] Engine 000: Avg prompt throughput: 0.0 tokens/s, Avg generation throughput: 52.1 tokens/s, Running: 1 reqs, Waiting: 0 reqs, GPU KV cache usage: 2.5%, Prefix cache hit rate: 92.6%
(APIServer pid=1) INFO 05-14 10:31:53 [metrics.py:101] SpecDecoding metrics: Mean acceptance length: 2.94, Accepted throughput: 34.39 tokens/s, Drafted throughput: 35.39 tokens/s, Accepted: 344 tokens, Drafted: 354 tokens, Per-position acceptance rate: 0.977, 0.966, Avg Draft acceptance rate: 97.2%
(APIServer pid=1) INFO 05-14 10:32:03 [loggers.py:271] Engine 000: Avg prompt throughput: 0.0 tokens/s, Avg generation throughput: 52.8 tokens/s, Running: 1 reqs, Waiting: 0 reqs, GPU KV cache usage: 2.5%, Prefix cache hit rate: 92.6%
(APIServer pid=1) INFO 05-14 10:32:03 [metrics.py:101] SpecDecoding metrics: Mean acceptance length: 3.00, Accepted throughput: 35.20 tokens/s, Drafted throughput: 35.20 tokens/s, Accepted: 352 tokens, Drafted: 352 tokens, Per-position acceptance rate: 1.000, 1.000, Avg Draft acceptance rate: 100.0%
(APIServer pid=1) INFO:     172.18.0.3:51224 - "POST /v1/chat/completions HTTP/1.1" 200 OK
(APIServer pid=1) INFO 05-14 10:32:13 [loggers.py:271] Engine 000: Avg prompt throughput: 0.0 tokens/s, Avg generation throughput: 8.9 tokens/s, Running: 0 reqs, Waiting: 0 reqs, GPU KV cache usage: 0.0%, Prefix cache hit rate: 92.6%
(APIServer pid=1) INFO 05-14 10:32:13 [metrics.py:101] SpecDecoding metrics: Mean acceptance length: 3.00, Accepted throughput: 6.00 tokens/s, Drafted throughput: 6.00 tokens/s, Accepted: 60 tokens, Drafted: 60 tokens, Per-position acceptance rate: 1.000, 1.000, Avg Draft acceptance rate: 100.0%
(APIServer pid=1) INFO:     172.18.0.3:33156 - "POST /v1/chat/completions HTTP/1.1" 200 OK
(APIServer pid=1) INFO 05-14 10:32:23 [loggers.py:271] Engine 000: Avg prompt throughput: 811.9 tokens/s, Avg generation throughput: 30.8 tokens/s, Running: 0 reqs, Waiting: 0 reqs, GPU KV cache usage: 0.0%, Prefix cache hit rate: 92.6%
(APIServer pid=1) INFO 05-14 10:32:23 [metrics.py:101] SpecDecoding metrics: Mean acceptance length: 2.93, Accepted throughput: 20.30 tokens/s, Drafted throughput: 21.00 tokens/s, Accepted: 203 tokens, Drafted: 210 tokens, Per-position acceptance rate: 0.981, 0.952, Avg Draft acceptance rate: 96.7%
(APIServer pid=1) INFO 05-14 10:32:33 [loggers.py:271] Engine 000: Avg prompt throughput: 572.4 tokens/s, Avg generation throughput: 41.9 tokens/s, Running: 0 reqs, Waiting: 0 reqs, GPU KV cache usage: 0.0%, Prefix cache hit rate: 92.7%
(APIServer pid=1) INFO 05-14 10:32:33 [metrics.py:101] SpecDecoding metrics: Mean acceptance length: 2.81, Accepted throughput: 26.90 tokens/s, Drafted throughput: 29.80 tokens/s, Accepted: 269 tokens, Drafted: 298 tokens, Per-position acceptance rate: 0.926, 0.879, Avg Draft acceptance rate: 90.3%
(APIServer pid=1) INFO:     172.18.0.3:38114 - "POST /v1/chat/completions HTTP/1.1" 200 OK
(APIServer pid=1) INFO 05-14 10:32:43 [loggers.py:271] Engine 000: Avg prompt throughput: 0.0 tokens/s, Avg generation throughput: 0.0 tokens/s, Running: 0 reqs, Waiting: 0 reqs, GPU KV cache usage: 0.0%, Prefix cache hit rate: 92.7%
(APIServer pid=1) INFO 05-14 10:33:03 [loggers.py:271] Engine 000: Avg prompt throughput: 7568.1 tokens/s, Avg generation throughput: 23.4 tokens/s, Running: 1 reqs, Waiting: 0 reqs, GPU KV cache usage: 1.8%, Prefix cache hit rate: 91.4%
(APIServer pid=1) INFO 05-14 10:33:03 [metrics.py:101] SpecDecoding metrics: Mean acceptance length: 2.62, Accepted throughput: 4.80 tokens/s, Drafted throughput: 5.93 tokens/s, Accepted: 144 tokens, Drafted: 178 tokens, Per-position acceptance rate: 0.865, 0.753, Avg Draft acceptance rate: 80.9%
(APIServer pid=1) INFO 05-14 10:33:13 [loggers.py:271] Engine 000: Avg prompt throughput: 0.0 tokens/s, Avg generation throughput: 41.3 tokens/s, Running: 0 reqs, Waiting: 0 reqs, GPU KV cache usage: 0.0%, Prefix cache hit rate: 91.4%
(APIServer pid=1) INFO 05-14 10:33:13 [metrics.py:101] SpecDecoding metrics: Mean acceptance length: 2.88, Accepted throughput: 27.00 tokens/s, Drafted throughput: 28.80 tokens/s, Accepted: 270 tokens, Drafted: 288 tokens, Per-position acceptance rate: 0.958, 0.917, Avg Draft acceptance rate: 93.8%
(APIServer pid=1) INFO 05-14 10:33:23 [loggers.py:271] Engine 000: Avg prompt throughput: 0.0 tokens/s, Avg generation throughput: 0.0 tokens/s, Running: 0 reqs, Waiting: 0 reqs, GPU KV cache usage: 0.0%, Prefix cache hit rate: 91.4%
(APIServer pid=1) INFO:     172.18.0.3:35388 - "POST /v1/chat/completions HTTP/1.1" 200 OK
(APIServer pid=1) INFO:     172.18.0.3:35398 - "POST /v1/chat/completions HTTP/1.1" 200 OK
(APIServer pid=1) INFO 05-14 10:34:13 [loggers.py:271] Engine 000: Avg prompt throughput: 1035.7 tokens/s, Avg generation throughput: 9.5 tokens/s, Running: 0 reqs, Waiting: 0 reqs, GPU KV cache usage: 0.0%, Prefix cache hit rate: 91.4%
(APIServer pid=1) INFO 05-14 10:34:13 [metrics.py:101] SpecDecoding metrics: Mean acceptance length: 2.53, Accepted throughput: 0.97 tokens/s, Drafted throughput: 1.27 tokens/s, Accepted: 58 tokens, Drafted: 76 tokens, Per-position acceptance rate: 0.842, 0.684, Avg Draft acceptance rate: 76.3%
(APIServer pid=1) INFO 05-14 10:34:23 [loggers.py:271] Engine 000: Avg prompt throughput: 550.3 tokens/s, Avg generation throughput: 37.1 tokens/s, Running: 0 reqs, Waiting: 0 reqs, GPU KV cache usage: 0.0%, Prefix cache hit rate: 91.4%
(APIServer pid=1) INFO 05-14 10:34:23 [metrics.py:101] SpecDecoding metrics: Mean acceptance length: 2.81, Accepted throughput: 23.90 tokens/s, Drafted throughput: 26.40 tokens/s, Accepted: 239 tokens, Drafted: 264 tokens, Per-position acceptance rate: 0.924, 0.886, Avg Draft acceptance rate: 90.5%
(APIServer pid=1) INFO:     172.18.0.3:46622 - "POST /v1/chat/completions HTTP/1.1" 200 OK
(APIServer pid=1) INFO 05-14 10:34:33 [loggers.py:271] Engine 000: Avg prompt throughput: 528.9 tokens/s, Avg generation throughput: 30.3 tokens/s, Running: 1 reqs, Waiting: 0 reqs, GPU KV cache usage: 1.9%, Prefix cache hit rate: 91.5%
(APIServer pid=1) INFO 05-14 10:34:33 [metrics.py:101] SpecDecoding metrics: Mean acceptance length: 2.34, Accepted throughput: 17.30 tokens/s, Drafted throughput: 25.80 tokens/s, Accepted: 173 tokens, Drafted: 258 tokens, Per-position acceptance rate: 0.729, 0.612, Avg Draft acceptance rate: 67.1%
(APIServer pid=1) INFO 05-14 10:34:43 [loggers.py:271] Engine 000: Avg prompt throughput: 0.0 tokens/s, Avg generation throughput: 28.1 tokens/s, Running: 0 reqs, Waiting: 0 reqs, GPU KV cache usage: 0.0%, Prefix cache hit rate: 91.5%
(APIServer pid=1) INFO 05-14 10:34:43 [metrics.py:101] SpecDecoding metrics: Mean acceptance length: 2.78, Accepted throughput: 18.00 tokens/s, Drafted throughput: 20.20 tokens/s, Accepted: 180 tokens, Drafted: 202 tokens, Per-position acceptance rate: 0.921, 0.861, Avg Draft acceptance rate: 89.1%
(APIServer pid=1) INFO:     172.18.0.3:37696 - "POST /v1/chat/completions HTTP/1.1" 200 OK
(APIServer pid=1) INFO 05-14 10:34:53 [loggers.py:271] Engine 000: Avg prompt throughput: 961.4 tokens/s, Avg generation throughput: 15.6 tokens/s, Running: 1 reqs, Waiting: 0 reqs, GPU KV cache usage: 2.0%, Prefix cache hit rate: 91.5%
(APIServer pid=1) INFO 05-14 10:34:53 [metrics.py:101] SpecDecoding metrics: Mean acceptance length: 2.63, Accepted throughput: 9.60 tokens/s, Drafted throughput: 11.80 tokens/s, Accepted: 96 tokens, Drafted: 118 tokens, Per-position acceptance rate: 0.847, 0.780, Avg Draft acceptance rate: 81.4%
(APIServer pid=1) INFO:     172.18.0.3:58950 - "POST /v1/chat/completions HTTP/1.1" 200 OK
(APIServer pid=1) INFO 05-14 10:35:03 [loggers.py:271] Engine 000: Avg prompt throughput: 439.6 tokens/s, Avg generation throughput: 37.1 tokens/s, Running: 1 reqs, Waiting: 0 reqs, GPU KV cache usage: 2.1%, Prefix cache hit rate: 91.6%
(APIServer pid=1) INFO 05-14 10:35:03 [metrics.py:101] SpecDecoding metrics: Mean acceptance length: 2.95, Accepted throughput: 24.60 tokens/s, Drafted throughput: 25.20 tokens/s, Accepted: 246 tokens, Drafted: 252 tokens, Per-position acceptance rate: 0.976, 0.976, Avg Draft acceptance rate: 97.6%
(APIServer pid=1) INFO 05-14 10:35:13 [loggers.py:271] Engine 000: Avg prompt throughput: 0.0 tokens/s, Avg generation throughput: 54.0 tokens/s, Running: 1 reqs, Waiting: 0 reqs, GPU KV cache usage: 2.1%, Prefix cache hit rate: 91.6%
(APIServer pid=1) INFO 05-14 10:35:13 [metrics.py:101] SpecDecoding metrics: Mean acceptance length: 3.00, Accepted throughput: 35.99 tokens/s, Drafted throughput: 35.99 tokens/s, Accepted: 360 tokens, Drafted: 360 tokens, Per-position acceptance rate: 1.000, 1.000, Avg Draft acceptance rate: 100.0%
(APIServer pid=1) INFO 05-14 10:35:23 [loggers.py:271] Engine 000: Avg prompt throughput: 0.0 tokens/s, Avg generation throughput: 41.2 tokens/s, Running: 0 reqs, Waiting: 0 reqs, GPU KV cache usage: 0.0%, Prefix cache hit rate: 91.6%
(APIServer pid=1) INFO 05-14 10:35:23 [metrics.py:101] SpecDecoding metrics: Mean acceptance length: 2.86, Accepted throughput: 26.80 tokens/s, Drafted throughput: 28.80 tokens/s, Accepted: 268 tokens, Drafted: 288 tokens, Per-position acceptance rate: 0.938, 0.924, Avg Draft acceptance rate: 93.1%
(APIServer pid=1) INFO:     172.18.0.3:55056 - "POST /v1/chat/completions HTTP/1.1" 200 OK
(APIServer pid=1) INFO 05-14 10:35:33 [loggers.py:271] Engine 000: Avg prompt throughput: 528.5 tokens/s, Avg generation throughput: 22.4 tokens/s, Running: 1 reqs, Waiting: 0 reqs, GPU KV cache usage: 2.1%, Prefix cache hit rate: 91.6%
(APIServer pid=1) INFO 05-14 10:35:33 [metrics.py:101] SpecDecoding metrics: Mean acceptance length: 2.53, Accepted throughput: 13.50 tokens/s, Drafted throughput: 17.60 tokens/s, Accepted: 135 tokens, Drafted: 176 tokens, Per-position acceptance rate: 0.807, 0.727, Avg Draft acceptance rate: 76.7%
(APIServer pid=1) INFO:     172.18.0.3:60020 - "POST /v1/chat/completions HTTP/1.1" 200 OK
(APIServer pid=1) INFO 05-14 10:35:43 [loggers.py:271] Engine 000: Avg prompt throughput: 487.2 tokens/s, Avg generation throughput: 33.2 tokens/s, Running: 1 reqs, Waiting: 0 reqs, GPU KV cache usage: 2.1%, Prefix cache hit rate: 91.7%
(APIServer pid=1) INFO 05-14 10:35:43 [metrics.py:101] SpecDecoding metrics: Mean acceptance length: 2.78, Accepted throughput: 21.20 tokens/s, Drafted throughput: 23.80 tokens/s, Accepted: 212 tokens, Drafted: 238 tokens, Per-position acceptance rate: 0.908, 0.874, Avg Draft acceptance rate: 89.1%
(APIServer pid=1) INFO 05-14 10:35:53 [loggers.py:271] Engine 000: Avg prompt throughput: 0.0 tokens/s, Avg generation throughput: 37.3 tokens/s, Running: 0 reqs, Waiting: 0 reqs, GPU KV cache usage: 0.0%, Prefix cache hit rate: 91.7%
(APIServer pid=1) INFO 05-14 10:35:53 [metrics.py:101] SpecDecoding metrics: Mean acceptance length: 2.88, Accepted throughput: 24.40 tokens/s, Drafted throughput: 26.00 tokens/s, Accepted: 244 tokens, Drafted: 260 tokens, Per-position acceptance rate: 0.954, 0.923, Avg Draft acceptance rate: 93.8%
(APIServer pid=1) INFO 05-14 10:36:03 [loggers.py:271] Engine 000: Avg prompt throughput: 0.0 tokens/s, Avg generation throughput: 0.0 tokens/s, Running: 0 reqs, Waiting: 0 reqs, GPU KV cache usage: 0.0%, Prefix cache hit rate: 91.7%
(APIServer pid=1) INFO:     172.18.0.3:42186 - "POST /v1/chat/completions HTTP/1.1" 200 OK
(APIServer pid=1) INFO:     172.18.0.3:49608 - "POST /v1/chat/completions HTTP/1.1" 200 OK
(APIServer pid=1) INFO 05-14 10:36:23 [loggers.py:271] Engine 000: Avg prompt throughput: 956.7 tokens/s, Avg generation throughput: 27.3 tokens/s, Running: 0 reqs, Waiting: 0 reqs, GPU KV cache usage: 0.0%, Prefix cache hit rate: 91.7%
(APIServer pid=1) INFO 05-14 10:36:23 [metrics.py:101] SpecDecoding metrics: Mean acceptance length: 2.67, Accepted throughput: 5.67 tokens/s, Drafted throughput: 6.80 tokens/s, Accepted: 170 tokens, Drafted: 204 tokens, Per-position acceptance rate: 0.853, 0.814, Avg Draft acceptance rate: 83.3%
(APIServer pid=1) INFO:     172.18.0.3:36310 - "POST /v1/chat/completions HTTP/1.1" 200 OK
(APIServer pid=1) INFO 05-14 10:36:33 [loggers.py:271] Engine 000: Avg prompt throughput: 960.3 tokens/s, Avg generation throughput: 26.0 tokens/s, Running: 1 reqs, Waiting: 0 reqs, GPU KV cache usage: 2.3%, Prefix cache hit rate: 91.9%
(APIServer pid=1) INFO 05-14 10:36:33 [metrics.py:101] SpecDecoding metrics: Mean acceptance length: 2.66, Accepted throughput: 16.10 tokens/s, Drafted throughput: 19.39 tokens/s, Accepted: 161 tokens, Drafted: 194 tokens, Per-position acceptance rate: 0.897, 0.763, Avg Draft acceptance rate: 83.0%
(APIServer pid=1) INFO:     172.18.0.3:35862 - "POST /v1/chat/completions HTTP/1.1" 200 OK
(APIServer pid=1) INFO 05-14 10:36:43 [loggers.py:271] Engine 000: Avg prompt throughput: 995.9 tokens/s, Avg generation throughput: 17.4 tokens/s, Running: 1 reqs, Waiting: 0 reqs, GPU KV cache usage: 2.4%, Prefix cache hit rate: 91.9%
(APIServer pid=1) INFO 05-14 10:36:43 [metrics.py:101] SpecDecoding metrics: Mean acceptance length: 2.68, Accepted throughput: 10.90 tokens/s, Drafted throughput: 13.00 tokens/s, Accepted: 109 tokens, Drafted: 130 tokens, Per-position acceptance rate: 0.846, 0.831, Avg Draft acceptance rate: 83.8%
(APIServer pid=1) INFO:     172.18.0.3:37030 - "POST /v1/chat/completions HTTP/1.1" 200 OK
(APIServer pid=1) INFO 05-14 10:36:53 [loggers.py:271] Engine 000: Avg prompt throughput: 0.0 tokens/s, Avg generation throughput: 26.5 tokens/s, Running: 0 reqs, Waiting: 0 reqs, GPU KV cache usage: 0.0%, Prefix cache hit rate: 91.9%
(APIServer pid=1) INFO 05-14 10:36:53 [metrics.py:101] SpecDecoding metrics: Mean acceptance length: 2.80, Accepted throughput: 17.10 tokens/s, Drafted throughput: 19.00 tokens/s, Accepted: 171 tokens, Drafted: 190 tokens, Per-position acceptance rate: 0.937, 0.863, Avg Draft acceptance rate: 90.0%
(APIServer pid=1) INFO:     172.18.0.3:43870 - "POST /v1/chat/completions HTTP/1.1" 200 OK
(APIServer pid=1) INFO 05-14 10:37:03 [loggers.py:271] Engine 000: Avg prompt throughput: 936.1 tokens/s, Avg generation throughput: 31.1 tokens/s, Running: 0 reqs, Waiting: 0 reqs, GPU KV cache usage: 0.0%, Prefix cache hit rate: 92.0%
(APIServer pid=1) INFO 05-14 10:37:03 [metrics.py:101] SpecDecoding metrics: Mean acceptance length: 2.64, Accepted throughput: 19.40 tokens/s, Drafted throughput: 23.60 tokens/s, Accepted: 194 tokens, Drafted: 236 tokens, Per-position acceptance rate: 0.856, 0.788, Avg Draft acceptance rate: 82.2%
(APIServer pid=1) INFO 05-14 10:37:13 [loggers.py:271] Engine 000: Avg prompt throughput: 492.7 tokens/s, Avg generation throughput: 40.2 tokens/s, Running: 1 reqs, Waiting: 0 reqs, GPU KV cache usage: 2.5%, Prefix cache hit rate: 92.1%
(APIServer pid=1) INFO 05-14 10:37:13 [metrics.py:101] SpecDecoding metrics: Mean acceptance length: 2.52, Accepted throughput: 24.20 tokens/s, Drafted throughput: 31.80 tokens/s, Accepted: 242 tokens, Drafted: 318 tokens, Per-position acceptance rate: 0.830, 0.692, Avg Draft acceptance rate: 76.1%
(APIServer pid=1) INFO:     172.18.0.3:57598 - "POST /v1/chat/completions HTTP/1.1" 200 OK
(APIServer pid=1) INFO 05-14 10:37:23 [loggers.py:271] Engine 000: Avg prompt throughput: 1018.3 tokens/s, Avg generation throughput: 11.2 tokens/s, Running: 1 reqs, Waiting: 0 reqs, GPU KV cache usage: 2.7%, Prefix cache hit rate: 92.1%
(APIServer pid=1) INFO 05-14 10:37:23 [metrics.py:101] SpecDecoding metrics: Mean acceptance length: 2.22, Accepted throughput: 6.20 tokens/s, Drafted throughput: 10.20 tokens/s, Accepted: 62 tokens, Drafted: 102 tokens, Per-position acceptance rate: 0.706, 0.510, Avg Draft acceptance rate: 60.8%
(APIServer pid=1) INFO 05-14 10:37:33 [loggers.py:271] Engine 000: Avg prompt throughput: 0.0 tokens/s, Avg generation throughput: 12.4 tokens/s, Running: 0 reqs, Waiting: 0 reqs, GPU KV cache usage: 0.0%, Prefix cache hit rate: 92.1%
(APIServer pid=1) INFO 05-14 10:37:33 [metrics.py:101] SpecDecoding metrics: Mean acceptance length: 2.38, Accepted throughput: 7.20 tokens/s, Drafted throughput: 10.40 tokens/s, Accepted: 72 tokens, Drafted: 104 tokens, Per-position acceptance rate: 0.808, 0.577, Avg Draft acceptance rate: 69.2%
(APIServer pid=1) INFO 05-14 10:37:43 [loggers.py:271] Engine 000: Avg prompt throughput: 0.0 tokens/s, Avg generation throughput: 0.0 tokens/s, Running: 0 reqs, Waiting: 0 reqs, GPU KV cache usage: 0.0%, Prefix cache hit rate: 92.1%
(APIServer pid=1) INFO:     172.18.0.3:49002 - "POST /v1/chat/completions HTTP/1.1" 200 OK
(APIServer pid=1) INFO 05-14 10:38:23 [loggers.py:271] Engine 000: Avg prompt throughput: 1028.5 tokens/s, Avg generation throughput: 35.8 tokens/s, Running: 1 reqs, Waiting: 0 reqs, GPU KV cache usage: 2.8%, Prefix cache hit rate: 92.1%
(APIServer pid=1) INFO 05-14 10:38:23 [metrics.py:101] SpecDecoding metrics: Mean acceptance length: 2.64, Accepted throughput: 4.44 tokens/s, Drafted throughput: 5.40 tokens/s, Accepted: 222 tokens, Drafted: 270 tokens, Per-position acceptance rate: 0.889, 0.756, Avg Draft acceptance rate: 82.2%
(APIServer pid=1) INFO:     172.18.0.3:34244 - "POST /v1/chat/completions HTTP/1.1" 200 OK
(APIServer pid=1) INFO 05-14 10:38:33 [loggers.py:271] Engine 000: Avg prompt throughput: 0.0 tokens/s, Avg generation throughput: 33.7 tokens/s, Running: 0 reqs, Waiting: 0 reqs, GPU KV cache usage: 0.0%, Prefix cache hit rate: 92.1%
(APIServer pid=1) INFO 05-14 10:38:33 [metrics.py:101] SpecDecoding metrics: Mean acceptance length: 2.50, Accepted throughput: 20.30 tokens/s, Drafted throughput: 27.00 tokens/s, Accepted: 203 tokens, Drafted: 270 tokens, Per-position acceptance rate: 0.822, 0.681, Avg Draft acceptance rate: 75.2%
(APIServer pid=1) INFO 05-14 10:38:43 [loggers.py:271] Engine 000: Avg prompt throughput: 0.0 tokens/s, Avg generation throughput: 0.0 tokens/s, Running: 0 reqs, Waiting: 0 reqs, GPU KV cache usage: 0.0%, Prefix cache hit rate: 92.1%
(APIServer pid=1) INFO 05-14 10:39:03 [loggers.py:271] Engine 000: Avg prompt throughput: 8799.9 tokens/s, Avg generation throughput: 12.4 tokens/s, Running: 1 reqs, Waiting: 0 reqs, GPU KV cache usage: 2.0%, Prefix cache hit rate: 91.0%
(APIServer pid=1) INFO 05-14 10:39:03 [metrics.py:101] SpecDecoding metrics: Mean acceptance length: 2.62, Accepted throughput: 2.53 tokens/s, Drafted throughput: 3.13 tokens/s, Accepted: 76 tokens, Drafted: 94 tokens, Per-position acceptance rate: 0.830, 0.787, Avg Draft acceptance rate: 80.9%
(APIServer pid=1) INFO 05-14 10:39:13 [loggers.py:271] Engine 000: Avg prompt throughput: 0.0 tokens/s, Avg generation throughput: 45.3 tokens/s, Running: 0 reqs, Waiting: 0 reqs, GPU KV cache usage: 0.0%, Prefix cache hit rate: 91.0%
(APIServer pid=1) INFO 05-14 10:39:13 [metrics.py:101] SpecDecoding metrics: Mean acceptance length: 2.86, Accepted throughput: 29.50 tokens/s, Drafted throughput: 31.80 tokens/s, Accepted: 295 tokens, Drafted: 318 tokens, Per-position acceptance rate: 0.962, 0.893, Avg Draft acceptance rate: 92.8%
(APIServer pid=1) INFO:     172.18.0.3:49792 - "POST /v1/chat/completions HTTP/1.1" 200 OK
(APIServer pid=1) INFO 05-14 10:39:23 [loggers.py:271] Engine 000: Avg prompt throughput: 568.8 tokens/s, Avg generation throughput: 11.9 tokens/s, Running: 1 reqs, Waiting: 0 reqs, GPU KV cache usage: 2.0%, Prefix cache hit rate: 91.0%
(APIServer pid=1) INFO 05-14 10:39:23 [metrics.py:101] SpecDecoding metrics: Mean acceptance length: 2.36, Accepted throughput: 6.80 tokens/s, Drafted throughput: 10.00 tokens/s, Accepted: 68 tokens, Drafted: 100 tokens, Per-position acceptance rate: 0.800, 0.560, Avg Draft acceptance rate: 68.0%
(APIServer pid=1) INFO 05-14 10:39:33 [loggers.py:271] Engine 000: Avg prompt throughput: 0.0 tokens/s, Avg generation throughput: 50.3 tokens/s, Running: 1 reqs, Waiting: 0 reqs, GPU KV cache usage: 2.0%, Prefix cache hit rate: 91.0%
(APIServer pid=1) INFO 05-14 10:39:33 [metrics.py:101] SpecDecoding metrics: Mean acceptance length: 2.54, Accepted throughput: 30.50 tokens/s, Drafted throughput: 39.60 tokens/s, Accepted: 305 tokens, Drafted: 396 tokens, Per-position acceptance rate: 0.864, 0.677, Avg Draft acceptance rate: 77.0%
(APIServer pid=1) INFO 05-14 10:39:43 [loggers.py:271] Engine 000: Avg prompt throughput: 0.0 tokens/s, Avg generation throughput: 54.1 tokens/s, Running: 1 reqs, Waiting: 0 reqs, GPU KV cache usage: 2.0%, Prefix cache hit rate: 91.0%
(APIServer pid=1) INFO 05-14 10:39:43 [metrics.py:101] SpecDecoding metrics: Mean acceptance length: 2.75, Accepted throughput: 34.40 tokens/s, Drafted throughput: 39.40 tokens/s, Accepted: 344 tokens, Drafted: 394 tokens, Per-position acceptance rate: 0.929, 0.817, Avg Draft acceptance rate: 87.3%
(APIServer pid=1) INFO:     172.18.0.3:57458 - "POST /v1/chat/completions HTTP/1.1" 200 OK
(APIServer pid=1) INFO 05-14 10:39:53 [loggers.py:271] Engine 000: Avg prompt throughput: 0.0 tokens/s, Avg generation throughput: 26.8 tokens/s, Running: 0 reqs, Waiting: 0 reqs, GPU KV cache usage: 0.0%, Prefix cache hit rate: 91.0%
(APIServer pid=1) INFO 05-14 10:39:53 [metrics.py:101] SpecDecoding metrics: Mean acceptance length: 2.64, Accepted throughput: 16.70 tokens/s, Drafted throughput: 20.40 tokens/s, Accepted: 167 tokens, Drafted: 204 tokens, Per-position acceptance rate: 0.863, 0.775, Avg Draft acceptance rate: 81.9%
(APIServer pid=1) INFO:     172.18.0.3:58424 - "POST /v1/chat/completions HTTP/1.1" 200 OK
(APIServer pid=1) INFO 05-14 10:40:03 [loggers.py:271] Engine 000: Avg prompt throughput: 2826.3 tokens/s, Avg generation throughput: 33.6 tokens/s, Running: 0 reqs, Waiting: 0 reqs, GPU KV cache usage: 0.0%, Prefix cache hit rate: 90.7%
(APIServer pid=1) INFO 05-14 10:40:03 [metrics.py:101] SpecDecoding metrics: Mean acceptance length: 2.65, Accepted throughput: 21.00 tokens/s, Drafted throughput: 25.40 tokens/s, Accepted: 210 tokens, Drafted: 254 tokens, Per-position acceptance rate: 0.882, 0.772, Avg Draft acceptance rate: 82.7%
(APIServer pid=1) INFO 05-14 10:40:13 [loggers.py:271] Engine 000: Avg prompt throughput: 0.0 tokens/s, Avg generation throughput: 0.0 tokens/s, Running: 0 reqs, Waiting: 0 reqs, GPU KV cache usage: 0.0%, Prefix cache hit rate: 90.7%
(APIServer pid=1) INFO:     172.18.0.3:35712 - "POST /v1/chat/completions HTTP/1.1" 200 OK
(APIServer pid=1) INFO 05-14 10:41:43 [loggers.py:271] Engine 000: Avg prompt throughput: 869.1 tokens/s, Avg generation throughput: 11.7 tokens/s, Running: 1 reqs, Waiting: 0 reqs, GPU KV cache usage: 0.8%, Prefix cache hit rate: 90.6%
(APIServer pid=1) INFO 05-14 10:41:43 [metrics.py:101] SpecDecoding metrics: Mean acceptance length: 2.52, Accepted throughput: 0.70 tokens/s, Drafted throughput: 0.92 tokens/s, Accepted: 70 tokens, Drafted: 92 tokens, Per-position acceptance rate: 0.870, 0.652, Avg Draft acceptance rate: 76.1%
(APIServer pid=1) INFO 05-14 10:41:53 [loggers.py:271] Engine 000: Avg prompt throughput: 0.0 tokens/s, Avg generation throughput: 38.3 tokens/s, Running: 0 reqs, Waiting: 0 reqs, GPU KV cache usage: 0.0%, Prefix cache hit rate: 90.6%
(APIServer pid=1) INFO 05-14 10:41:53 [metrics.py:101] SpecDecoding metrics: Mean acceptance length: 2.46, Accepted throughput: 22.70 tokens/s, Drafted throughput: 31.20 tokens/s, Accepted: 227 tokens, Drafted: 312 tokens, Per-position acceptance rate: 0.808, 0.647, Avg Draft acceptance rate: 72.8%
(APIServer pid=1) INFO 05-14 10:42:03 [loggers.py:271] Engine 000: Avg prompt throughput: 0.0 tokens/s, Avg generation throughput: 0.0 tokens/s, Running: 0 reqs, Waiting: 0 reqs, GPU KV cache usage: 0.0%, Prefix cache hit rate: 90.6%
(APIServer pid=1) INFO:     172.18.0.3:43314 - "POST /v1/chat/completions HTTP/1.1" 200 OK
(APIServer pid=1) INFO 05-14 10:56:43 [loggers.py:271] Engine 000: Avg prompt throughput: 390.6 tokens/s, Avg generation throughput: 28.8 tokens/s, Running: 0 reqs, Waiting: 0 reqs, GPU KV cache usage: 0.0%, Prefix cache hit rate: 90.6%
(APIServer pid=1) INFO 05-14 10:56:43 [metrics.py:101] SpecDecoding metrics: Mean acceptance length: 2.73, Accepted throughput: 0.20 tokens/s, Drafted throughput: 0.24 tokens/s, Accepted: 182 tokens, Drafted: 210 tokens, Per-position acceptance rate: 0.905, 0.829, Avg Draft acceptance rate: 86.7%
(APIServer pid=1) INFO:     172.18.0.3:32966 - "POST /v1/chat/completions HTTP/1.1" 200 OK
(APIServer pid=1) INFO:     172.18.0.3:32976 - "POST /v1/chat/completions HTTP/1.1" 200 OK
(APIServer pid=1) INFO 05-14 10:56:53 [loggers.py:271] Engine 000: Avg prompt throughput: 1367.3 tokens/s, Avg generation throughput: 26.1 tokens/s, Running: 1 reqs, Waiting: 0 reqs, GPU KV cache usage: 0.9%, Prefix cache hit rate: 90.5%
(APIServer pid=1) INFO 05-14 10:56:53 [metrics.py:101] SpecDecoding metrics: Mean acceptance length: 2.75, Accepted throughput: 16.60 tokens/s, Drafted throughput: 19.00 tokens/s, Accepted: 166 tokens, Drafted: 190 tokens, Per-position acceptance rate: 0.916, 0.832, Avg Draft acceptance rate: 87.4%
(APIServer pid=1) INFO:     172.18.0.3:51204 - "POST /v1/chat/completions HTTP/1.1" 200 OK
(APIServer pid=1) INFO 05-14 10:57:03 [loggers.py:271] Engine 000: Avg prompt throughput: 485.3 tokens/s, Avg generation throughput: 42.3 tokens/s, Running: 0 reqs, Waiting: 0 reqs, GPU KV cache usage: 0.0%, Prefix cache hit rate: 90.5%
(APIServer pid=1) INFO 05-14 10:57:03 [metrics.py:101] SpecDecoding metrics: Mean acceptance length: 2.85, Accepted throughput: 27.40 tokens/s, Drafted throughput: 29.60 tokens/s, Accepted: 274 tokens, Drafted: 296 tokens, Per-position acceptance rate: 0.939, 0.912, Avg Draft acceptance rate: 92.6%
(APIServer pid=1) INFO:     172.18.0.3:47012 - "POST /v1/chat/completions HTTP/1.1" 200 OK
(APIServer pid=1) INFO:     172.18.0.3:47022 - "POST /v1/chat/completions HTTP/1.1" 200 OK
(APIServer pid=1) INFO 05-14 10:57:13 [loggers.py:271] Engine 000: Avg prompt throughput: 724.9 tokens/s, Avg generation throughput: 38.1 tokens/s, Running: 1 reqs, Waiting: 0 reqs, GPU KV cache usage: 0.9%, Prefix cache hit rate: 90.5%
(APIServer pid=1) INFO 05-14 10:57:13 [metrics.py:101] SpecDecoding metrics: Mean acceptance length: 2.61, Accepted throughput: 23.40 tokens/s, Drafted throughput: 29.00 tokens/s, Accepted: 234 tokens, Drafted: 290 tokens, Per-position acceptance rate: 0.869, 0.745, Avg Draft acceptance rate: 80.7%
(APIServer pid=1) INFO 05-14 10:57:23 [loggers.py:271] Engine 000: Avg prompt throughput: 0.0 tokens/s, Avg generation throughput: 18.1 tokens/s, Running: 0 reqs, Waiting: 0 reqs, GPU KV cache usage: 0.0%, Prefix cache hit rate: 90.5%
(APIServer pid=1) INFO 05-14 10:57:23 [metrics.py:101] SpecDecoding metrics: Mean acceptance length: 2.83, Accepted throughput: 11.70 tokens/s, Drafted throughput: 12.80 tokens/s, Accepted: 117 tokens, Drafted: 128 tokens, Per-position acceptance rate: 0.938, 0.891, Avg Draft acceptance rate: 91.4%
(APIServer pid=1) INFO 05-14 10:57:33 [loggers.py:271] Engine 000: Avg prompt throughput: 0.0 tokens/s, Avg generation throughput: 0.0 tokens/s, Running: 0 reqs, Waiting: 0 reqs, GPU KV cache usage: 0.0%, Prefix cache hit rate: 90.5%
(APIServer pid=1) INFO:     172.18.0.3:50236 - "POST /v1/chat/completions HTTP/1.1" 200 OK
(APIServer pid=1) INFO 05-14 11:09:23 [loggers.py:271] Engine 000: Avg prompt throughput: 661.9 tokens/s, Avg generation throughput: 25.6 tokens/s, Running: 1 reqs, Waiting: 0 reqs, GPU KV cache usage: 1.0%, Prefix cache hit rate: 90.5%
(APIServer pid=1) INFO 05-14 11:09:23 [metrics.py:101] SpecDecoding metrics: Mean acceptance length: 3.00, Accepted throughput: 0.24 tokens/s, Drafted throughput: 0.24 tokens/s, Accepted: 170 tokens, Drafted: 170 tokens, Per-position acceptance rate: 1.000, 1.000, Avg Draft acceptance rate: 100.0%
(APIServer pid=1) INFO:     172.18.0.3:45038 - "POST /v1/chat/completions HTTP/1.1" 200 OK
(APIServer pid=1) INFO 05-14 11:09:33 [loggers.py:271] Engine 000: Avg prompt throughput: 306.0 tokens/s, Avg generation throughput: 37.0 tokens/s, Running: 0 reqs, Waiting: 0 reqs, GPU KV cache usage: 0.0%, Prefix cache hit rate: 90.5%
(APIServer pid=1) INFO 05-14 11:09:33 [metrics.py:101] SpecDecoding metrics: Mean acceptance length: 2.91, Accepted throughput: 24.40 tokens/s, Drafted throughput: 25.60 tokens/s, Accepted: 244 tokens, Drafted: 256 tokens, Per-position acceptance rate: 0.969, 0.938, Avg Draft acceptance rate: 95.3%
(APIServer pid=1) INFO:     172.18.0.3:51408 - "POST /v1/chat/completions HTTP/1.1" 200 OK
(APIServer pid=1) INFO 05-14 11:09:43 [loggers.py:271] Engine 000: Avg prompt throughput: 397.1 tokens/s, Avg generation throughput: 39.3 tokens/s, Running: 1 reqs, Waiting: 0 reqs, GPU KV cache usage: 1.0%, Prefix cache hit rate: 90.5%
(APIServer pid=1) INFO 05-14 11:09:43 [metrics.py:101] SpecDecoding metrics: Mean acceptance length: 2.68, Accepted throughput: 24.60 tokens/s, Drafted throughput: 29.20 tokens/s, Accepted: 246 tokens, Drafted: 292 tokens, Per-position acceptance rate: 0.890, 0.795, Avg Draft acceptance rate: 84.2%
(APIServer pid=1) INFO 05-14 11:09:53 [loggers.py:271] Engine 000: Avg prompt throughput: 0.0 tokens/s, Avg generation throughput: 4.7 tokens/s, Running: 0 reqs, Waiting: 0 reqs, GPU KV cache usage: 0.0%, Prefix cache hit rate: 90.5%
(APIServer pid=1) INFO 05-14 11:09:53 [metrics.py:101] SpecDecoding metrics: Mean acceptance length: 3.00, Accepted throughput: 3.20 tokens/s, Drafted throughput: 3.20 tokens/s, Accepted: 32 tokens, Drafted: 32 tokens, Per-position acceptance rate: 1.000, 1.000, Avg Draft acceptance rate: 100.0%
(APIServer pid=1) INFO 05-14 11:10:03 [loggers.py:271] Engine 000: Avg prompt throughput: 0.0 tokens/s, Avg generation throughput: 0.0 tokens/s, Running: 0 reqs, Waiting: 0 reqs, GPU KV cache usage: 0.0%, Prefix cache hit rate: 90.5%
(APIServer pid=1) INFO:     172.18.0.3:46302 - "POST /v1/chat/completions HTTP/1.1" 200 OK
(APIServer pid=1) INFO:     172.18.0.3:46310 - "POST /v1/chat/completions HTTP/1.1" 200 OK
(APIServer pid=1) INFO 05-14 11:10:43 [loggers.py:271] Engine 000: Avg prompt throughput: 854.5 tokens/s, Avg generation throughput: 27.5 tokens/s, Running: 1 reqs, Waiting: 0 reqs, GPU KV cache usage: 1.0%, Prefix cache hit rate: 90.5%
(APIServer pid=1) INFO 05-14 11:10:43 [metrics.py:101] SpecDecoding metrics: Mean acceptance length: 2.97, Accepted throughput: 3.62 tokens/s, Drafted throughput: 3.68 tokens/s, Accepted: 181 tokens, Drafted: 184 tokens, Per-position acceptance rate: 1.000, 0.967, Avg Draft acceptance rate: 98.4%
(APIServer pid=1) INFO:     172.18.0.3:49246 - "POST /v1/chat/completions HTTP/1.1" 200 OK
(APIServer pid=1) INFO 05-14 11:10:53 [loggers.py:271] Engine 000: Avg prompt throughput: 434.9 tokens/s, Avg generation throughput: 41.1 tokens/s, Running: 1 reqs, Waiting: 0 reqs, GPU KV cache usage: 1.1%, Prefix cache hit rate: 90.5%
(APIServer pid=1) INFO 05-14 11:10:53 [metrics.py:101] SpecDecoding metrics: Mean acceptance length: 2.89, Accepted throughput: 26.90 tokens/s, Drafted throughput: 28.40 tokens/s, Accepted: 269 tokens, Drafted: 284 tokens, Per-position acceptance rate: 0.986, 0.908, Avg Draft acceptance rate: 94.7%
(APIServer pid=1) INFO 05-14 11:11:03 [loggers.py:271] Engine 000: Avg prompt throughput: 0.0 tokens/s, Avg generation throughput: 21.5 tokens/s, Running: 0 reqs, Waiting: 0 reqs, GPU KV cache usage: 0.0%, Prefix cache hit rate: 90.5%
(APIServer pid=1) INFO 05-14 11:11:03 [metrics.py:101] SpecDecoding metrics: Mean acceptance length: 2.84, Accepted throughput: 14.00 tokens/s, Drafted throughput: 15.20 tokens/s, Accepted: 140 tokens, Drafted: 152 tokens, Per-position acceptance rate: 0.934, 0.908, Avg Draft acceptance rate: 92.1%
(APIServer pid=1) INFO 05-14 11:11:13 [loggers.py:271] Engine 000: Avg prompt throughput: 0.0 tokens/s, Avg generation throughput: 0.0 tokens/s, Running: 0 reqs, Waiting: 0 reqs, GPU KV cache usage: 0.0%, Prefix cache hit rate: 90.5%
(APIServer pid=1) INFO:     172.18.0.3:39428 - "POST /v1/chat/completions HTTP/1.1" 200 OK
(APIServer pid=1) INFO 05-14 11:12:03 [loggers.py:271] Engine 000: Avg prompt throughput: 964.5 tokens/s, Avg generation throughput: 43.2 tokens/s, Running: 1 reqs, Waiting: 0 reqs, GPU KV cache usage: 1.2%, Prefix cache hit rate: 90.4%
(APIServer pid=1) INFO 05-14 11:12:03 [metrics.py:101] SpecDecoding metrics: Mean acceptance length: 2.28, Accepted throughput: 4.03 tokens/s, Drafted throughput: 6.30 tokens/s, Accepted: 242 tokens, Drafted: 378 tokens, Per-position acceptance rate: 0.746, 0.534, Avg Draft acceptance rate: 64.0%
(APIServer pid=1) INFO 05-14 11:12:13 [loggers.py:271] Engine 000: Avg prompt throughput: 0.0 tokens/s, Avg generation throughput: 16.7 tokens/s, Running: 0 reqs, Waiting: 0 reqs, GPU KV cache usage: 0.0%, Prefix cache hit rate: 90.4%
(APIServer pid=1) INFO 05-14 11:12:13 [metrics.py:101] SpecDecoding metrics: Mean acceptance length: 2.85, Accepted throughput: 10.90 tokens/s, Drafted throughput: 11.80 tokens/s, Accepted: 109 tokens, Drafted: 118 tokens, Per-position acceptance rate: 0.932, 0.915, Avg Draft acceptance rate: 92.4%
(APIServer pid=1) INFO 05-14 11:12:23 [loggers.py:271] Engine 000: Avg prompt throughput: 0.0 tokens/s, Avg generation throughput: 0.0 tokens/s, Running: 0 reqs, Waiting: 0 reqs, GPU KV cache usage: 0.0%, Prefix cache hit rate: 90.4%
(APIServer pid=1) INFO:     172.18.0.3:58684 - "POST /v1/chat/completions HTTP/1.1" 200 OK
(APIServer pid=1) INFO 05-14 11:13:13 [loggers.py:271] Engine 000: Avg prompt throughput: 459.6 tokens/s, Avg generation throughput: 22.0 tokens/s, Running: 1 reqs, Waiting: 0 reqs, GPU KV cache usage: 1.2%, Prefix cache hit rate: 90.4%
(APIServer pid=1) INFO 05-14 11:13:13 [metrics.py:101] SpecDecoding metrics: Mean acceptance length: 2.41, Accepted throughput: 2.13 tokens/s, Drafted throughput: 3.03 tokens/s, Accepted: 128 tokens, Drafted: 182 tokens, Per-position acceptance rate: 0.769, 0.637, Avg Draft acceptance rate: 70.3%
(APIServer pid=1) INFO 05-14 11:13:23 [loggers.py:271] Engine 000: Avg prompt throughput: 0.0 tokens/s, Avg generation throughput: 37.6 tokens/s, Running: 0 reqs, Waiting: 0 reqs, GPU KV cache usage: 0.0%, Prefix cache hit rate: 90.4%
(APIServer pid=1) INFO 05-14 11:13:23 [metrics.py:101] SpecDecoding metrics: Mean acceptance length: 2.64, Accepted throughput: 23.40 tokens/s, Drafted throughput: 28.60 tokens/s, Accepted: 234 tokens, Drafted: 286 tokens, Per-position acceptance rate: 0.874, 0.762, Avg Draft acceptance rate: 81.8%
(APIServer pid=1) INFO 05-14 11:13:33 [loggers.py:271] Engine 000: Avg prompt throughput: 0.0 tokens/s, Avg generation throughput: 0.0 tokens/s, Running: 0 reqs, Waiting: 0 reqs, GPU KV cache usage: 0.0%, Prefix cache hit rate: 90.4%
(APIServer pid=1) INFO:     172.18.0.3:58410 - "POST /v1/chat/completions HTTP/1.1" 200 OK
(APIServer pid=1) INFO 05-14 11:14:33 [loggers.py:271] Engine 000: Avg prompt throughput: 377.8 tokens/s, Avg generation throughput: 31.4 tokens/s, Running: 1 reqs, Waiting: 0 reqs, GPU KV cache usage: 1.2%, Prefix cache hit rate: 90.5%
(APIServer pid=1) INFO 05-14 11:14:33 [metrics.py:101] SpecDecoding metrics: Mean acceptance length: 2.59, Accepted throughput: 2.74 tokens/s, Drafted throughput: 3.46 tokens/s, Accepted: 192 tokens, Drafted: 242 tokens, Per-position acceptance rate: 0.843, 0.744, Avg Draft acceptance rate: 79.3%
(APIServer pid=1) INFO:     172.18.0.3:46508 - "POST /v1/chat/completions HTTP/1.1" 200 OK
(APIServer pid=1) INFO 05-14 11:14:43 [loggers.py:271] Engine 000: Avg prompt throughput: 0.0 tokens/s, Avg generation throughput: 26.9 tokens/s, Running: 0 reqs, Waiting: 0 reqs, GPU KV cache usage: 0.0%, Prefix cache hit rate: 90.5%
(APIServer pid=1) INFO 05-14 11:14:43 [metrics.py:101] SpecDecoding metrics: Mean acceptance length: 2.89, Accepted throughput: 17.60 tokens/s, Drafted throughput: 18.60 tokens/s, Accepted: 176 tokens, Drafted: 186 tokens, Per-position acceptance rate: 0.978, 0.914, Avg Draft acceptance rate: 94.6%
(APIServer pid=1) INFO:     172.18.0.3:50784 - "POST /v1/chat/completions HTTP/1.1" 200 OK
(APIServer pid=1) INFO 05-14 11:14:53 [loggers.py:271] Engine 000: Avg prompt throughput: 1373.2 tokens/s, Avg generation throughput: 33.6 tokens/s, Running: 1 reqs, Waiting: 0 reqs, GPU KV cache usage: 1.3%, Prefix cache hit rate: 90.4%
(APIServer pid=1) INFO 05-14 11:14:53 [metrics.py:101] SpecDecoding metrics: Mean acceptance length: 2.95, Accepted throughput: 22.20 tokens/s, Drafted throughput: 22.80 tokens/s, Accepted: 222 tokens, Drafted: 228 tokens, Per-position acceptance rate: 0.991, 0.956, Avg Draft acceptance rate: 97.4%
(APIServer pid=1) INFO:     172.18.0.3:60716 - "POST /v1/chat/completions HTTP/1.1" 200 OK
(APIServer pid=1) INFO 05-14 11:15:03 [loggers.py:271] Engine 000: Avg prompt throughput: 491.4 tokens/s, Avg generation throughput: 24.4 tokens/s, Running: 1 reqs, Waiting: 0 reqs, GPU KV cache usage: 1.3%, Prefix cache hit rate: 90.5%
(APIServer pid=1) INFO 05-14 11:15:03 [metrics.py:101] SpecDecoding metrics: Mean acceptance length: 2.99, Accepted throughput: 16.30 tokens/s, Drafted throughput: 16.40 tokens/s, Accepted: 163 tokens, Drafted: 164 tokens, Per-position acceptance rate: 1.000, 0.988, Avg Draft acceptance rate: 99.4%
(APIServer pid=1) INFO 05-14 11:15:13 [loggers.py:271] Engine 000: Avg prompt throughput: 0.0 tokens/s, Avg generation throughput: 37.5 tokens/s, Running: 0 reqs, Waiting: 0 reqs, GPU KV cache usage: 0.0%, Prefix cache hit rate: 90.5%
(APIServer pid=1) INFO 05-14 11:15:13 [metrics.py:101] SpecDecoding metrics: Mean acceptance length: 2.79, Accepted throughput: 24.20 tokens/s, Drafted throughput: 27.00 tokens/s, Accepted: 242 tokens, Drafted: 270 tokens, Per-position acceptance rate: 0.941, 0.852, Avg Draft acceptance rate: 89.6%
(APIServer pid=1) INFO:     172.18.0.3:50654 - "POST /v1/chat/completions HTTP/1.1" 200 OK
(APIServer pid=1) INFO:     172.18.0.3:50660 - "POST /v1/chat/completions HTTP/1.1" 200 OK
(APIServer pid=1) INFO 05-14 11:15:23 [loggers.py:271] Engine 000: Avg prompt throughput: 758.8 tokens/s, Avg generation throughput: 25.1 tokens/s, Running: 1 reqs, Waiting: 0 reqs, GPU KV cache usage: 1.3%, Prefix cache hit rate: 90.5%
(APIServer pid=1) INFO 05-14 11:15:23 [metrics.py:101] SpecDecoding metrics: Mean acceptance length: 2.91, Accepted throughput: 16.40 tokens/s, Drafted throughput: 17.20 tokens/s, Accepted: 164 tokens, Drafted: 172 tokens, Per-position acceptance rate: 0.977, 0.930, Avg Draft acceptance rate: 95.3%
(APIServer pid=1) INFO:     172.18.0.3:34768 - "POST /v1/chat/completions HTTP/1.1" 200 OK
(APIServer pid=1) INFO 05-14 11:15:33 [loggers.py:271] Engine 000: Avg prompt throughput: 509.3 tokens/s, Avg generation throughput: 37.7 tokens/s, Running: 1 reqs, Waiting: 0 reqs, GPU KV cache usage: 1.4%, Prefix cache hit rate: 90.5%
(APIServer pid=1) INFO 05-14 11:15:33 [metrics.py:101] SpecDecoding metrics: Mean acceptance length: 2.90, Accepted throughput: 24.70 tokens/s, Drafted throughput: 26.00 tokens/s, Accepted: 247 tokens, Drafted: 260 tokens, Per-position acceptance rate: 0.962, 0.938, Avg Draft acceptance rate: 95.0%
(APIServer pid=1) INFO:     172.18.0.3:59288 - "POST /v1/chat/completions HTTP/1.1" 200 OK
(APIServer pid=1) INFO 05-14 11:15:43 [loggers.py:271] Engine 000: Avg prompt throughput: 355.2 tokens/s, Avg generation throughput: 32.7 tokens/s, Running: 1 reqs, Waiting: 0 reqs, GPU KV cache usage: 1.4%, Prefix cache hit rate: 90.6%
(APIServer pid=1) INFO 05-14 11:15:43 [metrics.py:101] SpecDecoding metrics: Mean acceptance length: 2.74, Accepted throughput: 20.70 tokens/s, Drafted throughput: 23.80 tokens/s, Accepted: 207 tokens, Drafted: 238 tokens, Per-position acceptance rate: 0.899, 0.840, Avg Draft acceptance rate: 87.0%
(APIServer pid=1) INFO:     172.18.0.3:38666 - "POST /v1/chat/completions HTTP/1.1" 200 OK
(APIServer pid=1) INFO 05-14 11:15:53 [loggers.py:271] Engine 000: Avg prompt throughput: 405.9 tokens/s, Avg generation throughput: 41.8 tokens/s, Running: 1 reqs, Waiting: 0 reqs, GPU KV cache usage: 1.4%, Prefix cache hit rate: 90.6%
(APIServer pid=1) INFO 05-14 11:15:53 [metrics.py:101] SpecDecoding metrics: Mean acceptance length: 2.60, Accepted throughput: 25.80 tokens/s, Drafted throughput: 32.20 tokens/s, Accepted: 258 tokens, Drafted: 322 tokens, Per-position acceptance rate: 0.863, 0.739, Avg Draft acceptance rate: 80.1%
(APIServer pid=1) INFO 05-14 11:16:03 [loggers.py:271] Engine 000: Avg prompt throughput: 0.0 tokens/s, Avg generation throughput: 11.3 tokens/s, Running: 0 reqs, Waiting: 0 reqs, GPU KV cache usage: 0.0%, Prefix cache hit rate: 90.6%
(APIServer pid=1) INFO 05-14 11:16:03 [metrics.py:101] SpecDecoding metrics: Mean acceptance length: 2.97, Accepted throughput: 7.50 tokens/s, Drafted throughput: 7.60 tokens/s, Accepted: 75 tokens, Drafted: 76 tokens, Per-position acceptance rate: 1.000, 0.974, Avg Draft acceptance rate: 98.7%
(APIServer pid=1) INFO 05-14 11:16:13 [loggers.py:271] Engine 000: Avg prompt throughput: 0.0 tokens/s, Avg generation throughput: 0.0 tokens/s, Running: 0 reqs, Waiting: 0 reqs, GPU KV cache usage: 0.0%, Prefix cache hit rate: 90.6%
(APIServer pid=1) INFO:     172.18.0.3:56250 - "POST /v1/chat/completions HTTP/1.1" 200 OK
(APIServer pid=1) INFO 05-14 11:18:03 [loggers.py:271] Engine 000: Avg prompt throughput: 1043.8 tokens/s, Avg generation throughput: 7.6 tokens/s, Running: 1 reqs, Waiting: 0 reqs, GPU KV cache usage: 1.5%, Prefix cache hit rate: 90.6%
(APIServer pid=1) INFO 05-14 11:18:03 [metrics.py:101] SpecDecoding metrics: Mean acceptance length: 2.78, Accepted throughput: 0.40 tokens/s, Drafted throughput: 0.45 tokens/s, Accepted: 48 tokens, Drafted: 54 tokens, Per-position acceptance rate: 1.000, 0.778, Avg Draft acceptance rate: 88.9%
(APIServer pid=1) INFO:     172.18.0.3:55964 - "POST /v1/chat/completions HTTP/1.1" 200 OK
(APIServer pid=1) INFO 05-14 11:18:13 [loggers.py:271] Engine 000: Avg prompt throughput: 584.3 tokens/s, Avg generation throughput: 35.2 tokens/s, Running: 0 reqs, Waiting: 0 reqs, GPU KV cache usage: 0.0%, Prefix cache hit rate: 90.6%
(APIServer pid=1) INFO 05-14 11:18:13 [metrics.py:101] SpecDecoding metrics: Mean acceptance length: 2.75, Accepted throughput: 22.40 tokens/s, Drafted throughput: 25.60 tokens/s, Accepted: 224 tokens, Drafted: 256 tokens, Per-position acceptance rate: 0.891, 0.859, Avg Draft acceptance rate: 87.5%
(APIServer pid=1) INFO:     172.18.0.3:60812 - "POST /v1/chat/completions HTTP/1.1" 200 OK
(APIServer pid=1) INFO 05-14 11:18:23 [loggers.py:271] Engine 000: Avg prompt throughput: 512.0 tokens/s, Avg generation throughput: 37.6 tokens/s, Running: 1 reqs, Waiting: 0 reqs, GPU KV cache usage: 1.5%, Prefix cache hit rate: 90.6%
(APIServer pid=1) INFO 05-14 11:18:23 [metrics.py:101] SpecDecoding metrics: Mean acceptance length: 2.76, Accepted throughput: 23.90 tokens/s, Drafted throughput: 27.20 tokens/s, Accepted: 239 tokens, Drafted: 272 tokens, Per-position acceptance rate: 0.904, 0.853, Avg Draft acceptance rate: 87.9%
(APIServer pid=1) INFO 05-14 11:18:33 [loggers.py:271] Engine 000: Avg prompt throughput: 0.0 tokens/s, Avg generation throughput: 52.1 tokens/s, Running: 0 reqs, Waiting: 0 reqs, GPU KV cache usage: 0.0%, Prefix cache hit rate: 90.6%
(APIServer pid=1) INFO 05-14 11:18:33 [metrics.py:101] SpecDecoding metrics: Mean acceptance length: 2.93, Accepted throughput: 34.40 tokens/s, Drafted throughput: 35.60 tokens/s, Accepted: 344 tokens, Drafted: 356 tokens, Per-position acceptance rate: 0.989, 0.944, Avg Draft acceptance rate: 96.6%
(APIServer pid=1) INFO 05-14 11:18:43 [loggers.py:271] Engine 000: Avg prompt throughput: 0.0 tokens/s, Avg generation throughput: 0.0 tokens/s, Running: 0 reqs, Waiting: 0 reqs, GPU KV cache usage: 0.0%, Prefix cache hit rate: 90.6%
(APIServer pid=1) INFO:     172.18.0.3:32884 - "POST /v1/chat/completions HTTP/1.1" 200 OK
(APIServer pid=1) INFO 05-14 11:18:53 [loggers.py:271] Engine 000: Avg prompt throughput: 408.3 tokens/s, Avg generation throughput: 15.6 tokens/s, Running: 1 reqs, Waiting: 0 reqs, GPU KV cache usage: 1.5%, Prefix cache hit rate: 90.6%
(APIServer pid=1) INFO 05-14 11:18:53 [metrics.py:101] SpecDecoding metrics: Mean acceptance length: 2.92, Accepted throughput: 5.10 tokens/s, Drafted throughput: 5.30 tokens/s, Accepted: 102 tokens, Drafted: 106 tokens, Per-position acceptance rate: 0.981, 0.943, Avg Draft acceptance rate: 96.2%
(APIServer pid=1) INFO:     172.18.0.3:44430 - "POST /v1/chat/completions HTTP/1.1" 200 OK
(APIServer pid=1) INFO 05-14 11:19:03 [loggers.py:271] Engine 000: Avg prompt throughput: 494.1 tokens/s, Avg generation throughput: 39.6 tokens/s, Running: 1 reqs, Waiting: 0 reqs, GPU KV cache usage: 1.6%, Prefix cache hit rate: 90.7%
(APIServer pid=1) INFO 05-14 11:19:03 [metrics.py:101] SpecDecoding metrics: Mean acceptance length: 2.96, Accepted throughput: 26.20 tokens/s, Drafted throughput: 26.80 tokens/s, Accepted: 262 tokens, Drafted: 268 tokens, Per-position acceptance rate: 0.993, 0.963, Avg Draft acceptance rate: 97.8%
(APIServer pid=1) INFO:     172.18.0.3:53086 - "POST /v1/chat/completions HTTP/1.1" 200 OK
(APIServer pid=1) INFO 05-14 11:19:13 [loggers.py:271] Engine 000: Avg prompt throughput: 390.8 tokens/s, Avg generation throughput: 22.3 tokens/s, Running: 1 reqs, Waiting: 0 reqs, GPU KV cache usage: 1.6%, Prefix cache hit rate: 90.7%
(APIServer pid=1) INFO 05-14 11:19:13 [metrics.py:101] SpecDecoding metrics: Mean acceptance length: 2.96, Accepted throughput: 14.70 tokens/s, Drafted throughput: 15.00 tokens/s, Accepted: 147 tokens, Drafted: 150 tokens, Per-position acceptance rate: 0.987, 0.973, Avg Draft acceptance rate: 98.0%
(APIServer pid=1) INFO:     172.18.0.3:37416 - "POST /v1/chat/completions HTTP/1.1" 200 OK
(APIServer pid=1) INFO 05-14 11:19:23 [loggers.py:271] Engine 000: Avg prompt throughput: 0.0 tokens/s, Avg generation throughput: 28.9 tokens/s, Running: 0 reqs, Waiting: 0 reqs, GPU KV cache usage: 0.0%, Prefix cache hit rate: 90.7%
(APIServer pid=1) INFO 05-14 11:19:23 [metrics.py:101] SpecDecoding metrics: Mean acceptance length: 3.00, Accepted throughput: 19.40 tokens/s, Drafted throughput: 19.40 tokens/s, Accepted: 194 tokens, Drafted: 194 tokens, Per-position acceptance rate: 1.000, 1.000, Avg Draft acceptance rate: 100.0%
(APIServer pid=1) INFO:     172.18.0.3:45660 - "POST /v1/chat/completions HTTP/1.1" 200 OK
(APIServer pid=1) INFO 05-14 11:19:33 [loggers.py:271] Engine 000: Avg prompt throughput: 886.3 tokens/s, Avg generation throughput: 31.4 tokens/s, Running: 1 reqs, Waiting: 0 reqs, GPU KV cache usage: 1.6%, Prefix cache hit rate: 90.8%
(APIServer pid=1) INFO 05-14 11:19:33 [metrics.py:101] SpecDecoding metrics: Mean acceptance length: 2.91, Accepted throughput: 20.60 tokens/s, Drafted throughput: 21.60 tokens/s, Accepted: 206 tokens, Drafted: 216 tokens, Per-position acceptance rate: 0.972, 0.935, Avg Draft acceptance rate: 95.4%
(APIServer pid=1) INFO 05-14 11:19:43 [loggers.py:271] Engine 000: Avg prompt throughput: 0.0 tokens/s, Avg generation throughput: 36.1 tokens/s, Running: 0 reqs, Waiting: 0 reqs, GPU KV cache usage: 0.0%, Prefix cache hit rate: 90.8%
(APIServer pid=1) INFO 05-14 11:19:43 [metrics.py:101] SpecDecoding metrics: Mean acceptance length: 2.96, Accepted throughput: 23.89 tokens/s, Drafted throughput: 24.39 tokens/s, Accepted: 239 tokens, Drafted: 244 tokens, Per-position acceptance rate: 0.984, 0.975, Avg Draft acceptance rate: 98.0%
(APIServer pid=1) INFO:     172.18.0.3:49672 - "POST /v1/chat/completions HTTP/1.1" 200 OK
(APIServer pid=1) INFO:     172.18.0.3:49676 - "POST /v1/chat/completions HTTP/1.1" 200 OK
(APIServer pid=1) INFO 05-14 11:19:53 [loggers.py:271] Engine 000: Avg prompt throughput: 500.1 tokens/s, Avg generation throughput: 29.0 tokens/s, Running: 0 reqs, Waiting: 0 reqs, GPU KV cache usage: 0.0%, Prefix cache hit rate: 90.8%
(APIServer pid=1) INFO 05-14 11:19:53 [metrics.py:101] SpecDecoding metrics: Mean acceptance length: 2.94, Accepted throughput: 19.20 tokens/s, Drafted throughput: 19.80 tokens/s, Accepted: 192 tokens, Drafted: 198 tokens, Per-position acceptance rate: 0.980, 0.960, Avg Draft acceptance rate: 97.0%
(APIServer pid=1) INFO 05-14 11:20:03 [loggers.py:271] Engine 000: Avg prompt throughput: 392.5 tokens/s, Avg generation throughput: 44.5 tokens/s, Running: 0 reqs, Waiting: 0 reqs, GPU KV cache usage: 0.0%, Prefix cache hit rate: 90.8%
(APIServer pid=1) INFO 05-14 11:20:03 [metrics.py:101] SpecDecoding metrics: Mean acceptance length: 2.92, Accepted throughput: 29.30 tokens/s, Drafted throughput: 30.60 tokens/s, Accepted: 293 tokens, Drafted: 306 tokens, Per-position acceptance rate: 0.967, 0.948, Avg Draft acceptance rate: 95.8%
(APIServer pid=1) INFO:     172.18.0.3:45170 - "POST /v1/chat/completions HTTP/1.1" 200 OK
(APIServer pid=1) INFO 05-14 11:20:13 [loggers.py:271] Engine 000: Avg prompt throughput: 520.6 tokens/s, Avg generation throughput: 19.9 tokens/s, Running: 1 reqs, Waiting: 0 reqs, GPU KV cache usage: 1.7%, Prefix cache hit rate: 90.9%
(APIServer pid=1) INFO 05-14 11:20:13 [metrics.py:101] SpecDecoding metrics: Mean acceptance length: 2.75, Accepted throughput: 12.60 tokens/s, Drafted throughput: 14.40 tokens/s, Accepted: 126 tokens, Drafted: 144 tokens, Per-position acceptance rate: 0.903, 0.847, Avg Draft acceptance rate: 87.5%
(APIServer pid=1) INFO:     172.18.0.3:50134 - "POST /v1/chat/completions HTTP/1.1" 200 OK
(APIServer pid=1) INFO 05-14 11:20:23 [loggers.py:271] Engine 000: Avg prompt throughput: 416.6 tokens/s, Avg generation throughput: 40.3 tokens/s, Running: 1 reqs, Waiting: 0 reqs, GPU KV cache usage: 1.7%, Prefix cache hit rate: 90.9%
(APIServer pid=1) INFO 05-14 11:20:23 [metrics.py:101] SpecDecoding metrics: Mean acceptance length: 2.99, Accepted throughput: 26.80 tokens/s, Drafted throughput: 27.00 tokens/s, Accepted: 268 tokens, Drafted: 270 tokens, Per-position acceptance rate: 1.000, 0.985, Avg Draft acceptance rate: 99.3%
(APIServer pid=1) INFO:     172.18.0.3:50314 - "POST /v1/chat/completions HTTP/1.1" 200 OK
(APIServer pid=1) INFO 05-14 11:20:33 [loggers.py:271] Engine 000: Avg prompt throughput: 547.9 tokens/s, Avg generation throughput: 17.0 tokens/s, Running: 1 reqs, Waiting: 0 reqs, GPU KV cache usage: 1.7%, Prefix cache hit rate: 90.9%
(APIServer pid=1) INFO 05-14 11:20:33 [metrics.py:101] SpecDecoding metrics: Mean acceptance length: 2.80, Accepted throughput: 11.00 tokens/s, Drafted throughput: 12.20 tokens/s, Accepted: 110 tokens, Drafted: 122 tokens, Per-position acceptance rate: 0.918, 0.885, Avg Draft acceptance rate: 90.2%
(APIServer pid=1) INFO:     172.18.0.3:33196 - "POST /v1/chat/completions HTTP/1.1" 200 OK
(APIServer pid=1) INFO 05-14 11:20:43 [loggers.py:271] Engine 000: Avg prompt throughput: 414.0 tokens/s, Avg generation throughput: 40.8 tokens/s, Running: 1 reqs, Waiting: 0 reqs, GPU KV cache usage: 1.7%, Prefix cache hit rate: 91.0%
(APIServer pid=1) INFO 05-14 11:20:43 [metrics.py:101] SpecDecoding metrics: Mean acceptance length: 3.00, Accepted throughput: 27.19 tokens/s, Drafted throughput: 27.19 tokens/s, Accepted: 272 tokens, Drafted: 272 tokens, Per-position acceptance rate: 1.000, 1.000, Avg Draft acceptance rate: 100.0%
(APIServer pid=1) INFO:     172.18.0.3:58212 - "POST /v1/chat/completions HTTP/1.1" 200 OK
(APIServer pid=1) INFO 05-14 11:20:53 [loggers.py:271] Engine 000: Avg prompt throughput: 506.3 tokens/s, Avg generation throughput: 36.6 tokens/s, Running: 1 reqs, Waiting: 0 reqs, GPU KV cache usage: 1.7%, Prefix cache hit rate: 91.0%
(APIServer pid=1) INFO 05-14 11:20:53 [metrics.py:101] SpecDecoding metrics: Mean acceptance length: 2.90, Accepted throughput: 23.90 tokens/s, Drafted throughput: 25.20 tokens/s, Accepted: 239 tokens, Drafted: 252 tokens, Per-position acceptance rate: 0.968, 0.929, Avg Draft acceptance rate: 94.8%
(APIServer pid=1) INFO:     172.18.0.3:34070 - "POST /v1/chat/completions HTTP/1.1" 200 OK
(APIServer pid=1) INFO 05-14 11:21:03 [loggers.py:271] Engine 000: Avg prompt throughput: 401.6 tokens/s, Avg generation throughput: 20.8 tokens/s, Running: 1 reqs, Waiting: 0 reqs, GPU KV cache usage: 1.7%, Prefix cache hit rate: 91.1%
(APIServer pid=1) INFO 05-14 11:21:03 [metrics.py:101] SpecDecoding metrics: Mean acceptance length: 2.94, Accepted throughput: 13.80 tokens/s, Drafted throughput: 14.20 tokens/s, Accepted: 138 tokens, Drafted: 142 tokens, Per-position acceptance rate: 0.986, 0.958, Avg Draft acceptance rate: 97.2%
(APIServer pid=1) INFO:     172.18.0.3:44966 - "POST /v1/chat/completions HTTP/1.1" 200 OK
(APIServer pid=1) INFO 05-14 11:21:13 [loggers.py:271] Engine 000: Avg prompt throughput: 491.2 tokens/s, Avg generation throughput: 37.4 tokens/s, Running: 1 reqs, Waiting: 0 reqs, GPU KV cache usage: 1.8%, Prefix cache hit rate: 91.1%
(APIServer pid=1) INFO 05-14 11:21:13 [metrics.py:101] SpecDecoding metrics: Mean acceptance length: 2.98, Accepted throughput: 24.90 tokens/s, Drafted throughput: 25.20 tokens/s, Accepted: 249 tokens, Drafted: 252 tokens, Per-position acceptance rate: 0.992, 0.984, Avg Draft acceptance rate: 98.8%
(APIServer pid=1) INFO:     172.18.0.3:35406 - "POST /v1/chat/completions HTTP/1.1" 200 OK
(APIServer pid=1) INFO 05-14 11:21:23 [loggers.py:271] Engine 000: Avg prompt throughput: 394.3 tokens/s, Avg generation throughput: 19.8 tokens/s, Running: 1 reqs, Waiting: 0 reqs, GPU KV cache usage: 1.8%, Prefix cache hit rate: 91.1%
(APIServer pid=1) INFO 05-14 11:21:23 [metrics.py:101] SpecDecoding metrics: Mean acceptance length: 2.80, Accepted throughput: 12.80 tokens/s, Drafted throughput: 14.20 tokens/s, Accepted: 128 tokens, Drafted: 142 tokens, Per-position acceptance rate: 0.930, 0.873, Avg Draft acceptance rate: 90.1%
(APIServer pid=1) INFO:     172.18.0.3:36334 - "POST /v1/chat/completions HTTP/1.1" 200 OK
(APIServer pid=1) INFO 05-14 11:21:33 [loggers.py:271] Engine 000: Avg prompt throughput: 0.0 tokens/s, Avg generation throughput: 40.5 tokens/s, Running: 0 reqs, Waiting: 0 reqs, GPU KV cache usage: 0.0%, Prefix cache hit rate: 91.1%
(APIServer pid=1) INFO 05-14 11:21:33 [metrics.py:101] SpecDecoding metrics: Mean acceptance length: 2.97, Accepted throughput: 27.00 tokens/s, Drafted throughput: 27.40 tokens/s, Accepted: 270 tokens, Drafted: 274 tokens, Per-position acceptance rate: 0.985, 0.985, Avg Draft acceptance rate: 98.5%
(APIServer pid=1) INFO 05-14 11:21:43 [loggers.py:271] Engine 000: Avg prompt throughput: 513.2 tokens/s, Avg generation throughput: 34.3 tokens/s, Running: 0 reqs, Waiting: 0 reqs, GPU KV cache usage: 0.0%, Prefix cache hit rate: 91.2%
(APIServer pid=1) INFO 05-14 11:21:43 [metrics.py:101] SpecDecoding metrics: Mean acceptance length: 3.00, Accepted throughput: 22.80 tokens/s, Drafted throughput: 22.80 tokens/s, Accepted: 228 tokens, Drafted: 228 tokens, Per-position acceptance rate: 1.000, 1.000, Avg Draft acceptance rate: 100.0%
(APIServer pid=1) INFO:     172.18.0.3:53934 - "POST /v1/chat/completions HTTP/1.1" 200 OK
(APIServer pid=1) INFO:     172.18.0.3:53080 - "POST /v1/chat/completions HTTP/1.1" 200 OK
(APIServer pid=1) INFO 05-14 11:21:53 [loggers.py:271] Engine 000: Avg prompt throughput: 433.4 tokens/s, Avg generation throughput: 32.9 tokens/s, Running: 0 reqs, Waiting: 0 reqs, GPU KV cache usage: 0.0%, Prefix cache hit rate: 91.2%
(APIServer pid=1) INFO 05-14 11:21:53 [metrics.py:101] SpecDecoding metrics: Mean acceptance length: 2.99, Accepted throughput: 21.89 tokens/s, Drafted throughput: 21.99 tokens/s, Accepted: 219 tokens, Drafted: 220 tokens, Per-position acceptance rate: 1.000, 0.991, Avg Draft acceptance rate: 99.5%
(APIServer pid=1) INFO 05-14 11:22:03 [loggers.py:271] Engine 000: Avg prompt throughput: 331.6 tokens/s, Avg generation throughput: 36.9 tokens/s, Running: 0 reqs, Waiting: 0 reqs, GPU KV cache usage: 0.0%, Prefix cache hit rate: 91.3%
(APIServer pid=1) INFO 05-14 11:22:03 [metrics.py:101] SpecDecoding metrics: Mean acceptance length: 2.96, Accepted throughput: 24.50 tokens/s, Drafted throughput: 25.00 tokens/s, Accepted: 245 tokens, Drafted: 250 tokens, Per-position acceptance rate: 0.984, 0.976, Avg Draft acceptance rate: 98.0%
(APIServer pid=1) INFO:     172.18.0.3:45334 - "POST /v1/chat/completions HTTP/1.1" 200 OK
(APIServer pid=1) INFO 05-14 11:22:13 [loggers.py:271] Engine 000: Avg prompt throughput: 467.7 tokens/s, Avg generation throughput: 26.3 tokens/s, Running: 1 reqs, Waiting: 0 reqs, GPU KV cache usage: 1.9%, Prefix cache hit rate: 91.3%
(APIServer pid=1) INFO 05-14 11:22:13 [metrics.py:101] SpecDecoding metrics: Mean acceptance length: 2.98, Accepted throughput: 17.40 tokens/s, Drafted throughput: 17.60 tokens/s, Accepted: 174 tokens, Drafted: 176 tokens, Per-position acceptance rate: 1.000, 0.977, Avg Draft acceptance rate: 98.9%
(APIServer pid=1) INFO:     172.18.0.3:58920 - "POST /v1/chat/completions HTTP/1.1" 200 OK
(APIServer pid=1) INFO 05-14 11:22:23 [loggers.py:271] Engine 000: Avg prompt throughput: 357.8 tokens/s, Avg generation throughput: 41.3 tokens/s, Running: 1 reqs, Waiting: 0 reqs, GPU KV cache usage: 1.9%, Prefix cache hit rate: 91.3%
(APIServer pid=1) INFO 05-14 11:22:23 [metrics.py:101] SpecDecoding metrics: Mean acceptance length: 2.96, Accepted throughput: 27.29 tokens/s, Drafted throughput: 27.79 tokens/s, Accepted: 273 tokens, Drafted: 278 tokens, Per-position acceptance rate: 0.986, 0.978, Avg Draft acceptance rate: 98.2%
(APIServer pid=1) INFO:     172.18.0.3:45210 - "POST /v1/chat/completions HTTP/1.1" 200 OK
(APIServer pid=1) INFO 05-14 11:22:34 [loggers.py:271] Engine 000: Avg prompt throughput: 483.7 tokens/s, Avg generation throughput: 17.4 tokens/s, Running: 1 reqs, Waiting: 0 reqs, GPU KV cache usage: 1.9%, Prefix cache hit rate: 91.4%
(APIServer pid=1) INFO 05-14 11:22:34 [metrics.py:101] SpecDecoding metrics: Mean acceptance length: 2.93, Accepted throughput: 11.40 tokens/s, Drafted throughput: 11.80 tokens/s, Accepted: 114 tokens, Drafted: 118 tokens, Per-position acceptance rate: 0.966, 0.966, Avg Draft acceptance rate: 96.6%
(APIServer pid=1) INFO:     172.18.0.3:39768 - "POST /v1/chat/completions HTTP/1.1" 200 OK
(APIServer pid=1) INFO 05-14 11:22:44 [loggers.py:271] Engine 000: Avg prompt throughput: 441.8 tokens/s, Avg generation throughput: 37.2 tokens/s, Running: 1 reqs, Waiting: 0 reqs, GPU KV cache usage: 1.9%, Prefix cache hit rate: 91.4%
(APIServer pid=1) INFO 05-14 11:22:44 [metrics.py:101] SpecDecoding metrics: Mean acceptance length: 2.95, Accepted throughput: 24.60 tokens/s, Drafted throughput: 25.20 tokens/s, Accepted: 246 tokens, Drafted: 252 tokens, Per-position acceptance rate: 0.984, 0.968, Avg Draft acceptance rate: 97.6%
(APIServer pid=1) INFO:     172.18.0.3:49934 - "POST /v1/chat/completions HTTP/1.1" 200 OK
(APIServer pid=1) INFO 05-14 11:22:54 [loggers.py:271] Engine 000: Avg prompt throughput: 348.1 tokens/s, Avg generation throughput: 35.1 tokens/s, Running: 1 reqs, Waiting: 0 reqs, GPU KV cache usage: 1.9%, Prefix cache hit rate: 91.5%
(APIServer pid=1) INFO 05-14 11:22:54 [metrics.py:101] SpecDecoding metrics: Mean acceptance length: 2.92, Accepted throughput: 23.00 tokens/s, Drafted throughput: 24.00 tokens/s, Accepted: 230 tokens, Drafted: 240 tokens, Per-position acceptance rate: 0.975, 0.942, Avg Draft acceptance rate: 95.8%
(APIServer pid=1) INFO 05-14 11:23:04 [loggers.py:271] Engine 000: Avg prompt throughput: 0.0 tokens/s, Avg generation throughput: 53.4 tokens/s, Running: 1 reqs, Waiting: 0 reqs, GPU KV cache usage: 2.0%, Prefix cache hit rate: 91.5%
(APIServer pid=1) INFO 05-14 11:23:04 [metrics.py:101] SpecDecoding metrics: Mean acceptance length: 2.95, Accepted throughput: 35.30 tokens/s, Drafted throughput: 36.20 tokens/s, Accepted: 353 tokens, Drafted: 362 tokens, Per-position acceptance rate: 0.983, 0.967, Avg Draft acceptance rate: 97.5%
(APIServer pid=1) INFO 05-14 11:23:14 [loggers.py:271] Engine 000: Avg prompt throughput: 0.0 tokens/s, Avg generation throughput: 2.6 tokens/s, Running: 0 reqs, Waiting: 0 reqs, GPU KV cache usage: 0.0%, Prefix cache hit rate: 91.5%
(APIServer pid=1) INFO 05-14 11:23:14 [metrics.py:101] SpecDecoding metrics: Mean acceptance length: 3.00, Accepted throughput: 1.80 tokens/s, Drafted throughput: 1.80 tokens/s, Accepted: 18 tokens, Drafted: 18 tokens, Per-position acceptance rate: 1.000, 1.000, Avg Draft acceptance rate: 100.0%
(APIServer pid=1) INFO 05-14 11:23:24 [loggers.py:271] Engine 000: Avg prompt throughput: 0.0 tokens/s, Avg generation throughput: 0.0 tokens/s, Running: 0 reqs, Waiting: 0 reqs, GPU KV cache usage: 0.0%, Prefix cache hit rate: 91.5%
(APIServer pid=1) INFO:     172.18.0.3:60798 - "POST /v1/chat/completions HTTP/1.1" 200 OK
(APIServer pid=1) INFO 05-14 11:25:44 [loggers.py:271] Engine 000: Avg prompt throughput: 1195.9 tokens/s, Avg generation throughput: 36.8 tokens/s, Running: 1 reqs, Waiting: 0 reqs, GPU KV cache usage: 2.1%, Prefix cache hit rate: 91.5%
(APIServer pid=1) INFO 05-14 11:25:44 [metrics.py:101] SpecDecoding metrics: Mean acceptance length: 2.57, Accepted throughput: 1.49 tokens/s, Drafted throughput: 1.91 tokens/s, Accepted: 224 tokens, Drafted: 286 tokens, Per-position acceptance rate: 0.825, 0.741, Avg Draft acceptance rate: 78.3%
(APIServer pid=1) INFO 05-14 11:25:54 [loggers.py:271] Engine 000: Avg prompt throughput: 0.0 tokens/s, Avg generation throughput: 18.5 tokens/s, Running: 0 reqs, Waiting: 0 reqs, GPU KV cache usage: 0.0%, Prefix cache hit rate: 91.5%
(APIServer pid=1) INFO 05-14 11:25:54 [metrics.py:101] SpecDecoding metrics: Mean acceptance length: 2.89, Accepted throughput: 12.09 tokens/s, Drafted throughput: 12.79 tokens/s, Accepted: 121 tokens, Drafted: 128 tokens, Per-position acceptance rate: 0.969, 0.922, Avg Draft acceptance rate: 94.5%
(APIServer pid=1) INFO:     172.18.0.3:45384 - "POST /v1/chat/completions HTTP/1.1" 200 OK
(APIServer pid=1) INFO 05-14 11:26:04 [loggers.py:271] Engine 000: Avg prompt throughput: 510.5 tokens/s, Avg generation throughput: 29.6 tokens/s, Running: 1 reqs, Waiting: 0 reqs, GPU KV cache usage: 2.1%, Prefix cache hit rate: 91.5%
(APIServer pid=1) INFO 05-14 11:26:04 [metrics.py:101] SpecDecoding metrics: Mean acceptance length: 2.86, Accepted throughput: 19.20 tokens/s, Drafted throughput: 20.60 tokens/s, Accepted: 192 tokens, Drafted: 206 tokens, Per-position acceptance rate: 0.961, 0.903, Avg Draft acceptance rate: 93.2%
(APIServer pid=1) INFO 05-14 11:26:14 [loggers.py:271] Engine 000: Avg prompt throughput: 0.0 tokens/s, Avg generation throughput: 15.5 tokens/s, Running: 0 reqs, Waiting: 0 reqs, GPU KV cache usage: 0.0%, Prefix cache hit rate: 91.5%
(APIServer pid=1) INFO 05-14 11:26:14 [metrics.py:101] SpecDecoding metrics: Mean acceptance length: 3.00, Accepted throughput: 10.36 tokens/s, Drafted throughput: 10.36 tokens/s, Accepted: 104 tokens, Drafted: 104 tokens, Per-position acceptance rate: 1.000, 1.000, Avg Draft acceptance rate: 100.0%
(APIServer pid=1) INFO 05-14 11:26:24 [loggers.py:271] Engine 000: Avg prompt throughput: 0.0 tokens/s, Avg generation throughput: 0.0 tokens/s, Running: 0 reqs, Waiting: 0 reqs, GPU KV cache usage: 0.0%, Prefix cache hit rate: 91.5%
