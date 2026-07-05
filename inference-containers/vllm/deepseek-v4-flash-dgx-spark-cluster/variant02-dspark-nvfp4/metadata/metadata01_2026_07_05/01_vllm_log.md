# vLLM Log Dump — DeepSeek V4 Flash DSpark
**Date:** 2026-07-05
**Variant:** variant02-dspark-nvfp4

## Head Node docker-compose.yml
```yaml
services:
  deepseek-v4-flash-dspark-head:
    image: ${DSPARK_VLLM_IMAGE:-vllm-dspark-runtime:dspark-nvfp4-stage-c}
    container_name: deepseek-v4-flash-dspark-head
    hostname: inference-server
    network_mode: "host"
    privileged: true
    ipc: "host"
    shm_size: "64gb"
    devices:
      - /dev/infiniband:/dev/infiniband
    ulimits:
      memlock:
        soft: -1
        hard: -1
    volumes:
      - ~/.cache/huggingface:/cache/huggingface
    deploy:
      resources:
        reservations:
          devices:
            - driver: nvidia
              count: 1
              capabilities: [gpu]
    environment:
      HF_HOME: /cache/huggingface
      HF_HUB_OFFLINE: "1"
      VLLM_CACHE_ROOT: /cache/huggingface/vllm-cache
      VLLM_HOST_IP: "${VLLM_HOST_IP:-}"

      VLLM_ALLOW_LONG_MAX_MODEL_LEN: "1"
      VLLM_TRITON_MLA_SPARSE: "1"
      VLLM_SPARSE_INDEXER_MAX_LOGITS_MB: "256"
      VLLM_MEMORY_PROFILER_ESTIMATE_CUDAGRAPHS: "0"
      VLLM_SKIP_INIT_MEMORY_CHECK: "1"

      VLLM_USE_FLASHINFER_SAMPLER: "1"

      VLLM_USE_B12X_MOE: "1"
      VLLM_USE_B12X_WO_PROJECTION: "1"
      VLLM_B12X_W4A16_FORCE_BLOCKS_PER_SM: "0"
      VLLM_B12X_W4A16_FORCE_BLOCKS_MAX_M: "16"
      B12X_W4A16_TC_DECODE: "0"

      VLLM_DSPARK_CONFIDENCE_THRESHOLD: "0.0"
      VLLM_DSPARK_CONFIDENCE_SCHEDULER: "off"
      VLLM_DSPARK_LOCAL_ARGMAX: "1"
      VLLM_DSPARK_REPLICATE_MARKOV_W1: "1"
      VLLM_DSPARK_FUSED_MARKOV_ARGMAX: "0"
      VLLM_DSPARK_GPU_REJECTED_CONTEXT_MASK: "1"
      VLLM_DSPARK_REFERENCE_KV_QUANT_DEQUANT: "0"
      VLLM_DSPARK_HARDWARE_SCHEDULER_EARLY_STOP: "1"
      VLLM_DSV4_B12X_COMPRESSED_MLA: "0"
      VLLM_DSV4_DSPARK_DEFER_TARGET_CAPTURE: "0"
      VLLM_DSV4_DSPARK_DEFER_TARGET_CAPTURE_EXACT: "0"

      TORCH_CUDA_ARCH_LIST: "12.1a"
      FLASHINFER_CUDA_ARCH_LIST: "12.1a"
      FLASHINFER_DISABLE_VERSION_CHECK: "1"
      TILELANG_CLEANUP_TEMP_FILES: "1"
      DG_JIT_USE_NVRTC: "0"
      DG_JIT_NVCC_COMPILER: /opt/env/bin/nvcc
      PYTORCH_CUDA_ALLOC_CONF: "expandable_segments:True"

      NCCL_NET: "IB"
      NCCL_IB_DISABLE: "0"
      NCCL_IB_HCA: "${NCCL_IB_HCA:-rocep1s0f0,roceP2p1s0f0}"
      NCCL_IB_GID_INDEX: "${NCCL_IB_GID_INDEX:-4,4}"
      NCCL_SOCKET_IFNAME: "${NCCL_SOCKET_IFNAME:-enP7s7}"
      GLOO_SOCKET_IFNAME: "${GLOO_SOCKET_IFNAME:-enP7s7}"
      TP_SOCKET_IFNAME: "${TP_SOCKET_IFNAME:-enP7s7}"
      NCCL_CROSS_NIC: "1"
      NCCL_CUMEM_ENABLE: "0"
      NCCL_IGNORE_CPU_AFFINITY: "1"
      NCCL_DEBUG: "${NCCL_DEBUG:-WARN}"
      NCCL_NVLS_ENABLE: "0"

      CUDA_VISIBLE_DEVICES: "0"

    command:
      - bash
      - -lc
      - >
        export PATH="/opt/env/bin:/opt/env/nvvm/bin:/opt/env/targets/sbsa-linux/nvvm/bin:$${PATH:-}";
        export CUDA_HOME="$${CUDA_HOME:-/opt/env/targets/sbsa-linux}";
        export CUDA_PATH="$${CUDA_PATH:-$${CUDA_HOME}}";
        export CUDAToolkit_ROOT="$${CUDAToolkit_ROOT:-$${CUDA_HOME}}";
        export LD_LIBRARY_PATH="/opt/env/lib:/opt/env/targets/sbsa-linux/lib:$${LD_LIBRARY_PATH:-}";
        SPECULATIVE_CONFIG="{\"method\":\"dspark\",\"num_speculative_tokens\":${MTP_NUM_TOKENS:-3},\"draft_sample_method\":\"probabilistic\"}";
        exec /opt/env/bin/vllm serve ${DSPARK_MODEL:-deepseek-ai/DeepSeek-V4-Flash-DSpark}
        --served-model-name ${INFERENCE_MODEL_ALIAS:-deepseek-v4-flash}
        --api-key ${INFERENCE_API_KEY:-dummy-key}
        --host 0.0.0.0
        --port 8000
        --trust-remote-code
        --tensor-parallel-size 2
        --pipeline-parallel-size 1
        --kv-cache-dtype nvfp4_ds_mla
        --block-size 256
        --max-model-len ${MAX_MODEL_LEN:-1048576}
        --max-num-seqs ${MAX_NUM_SEQS:-12}
        --max-num-batched-tokens ${MAX_NUM_BATCHED_TOKENS:-8192}
        --max-cudagraph-capture-size ${MAX_NUM_SEQS:-12}
        --gpu-memory-utilization ${GPU_MEMORY_UTILIZATION:-0.85}
        --enable-prefix-caching
        --async-scheduling
        --enable-chunked-prefill
        --speculative-config "$${SPECULATIVE_CONFIG}"
        --tokenizer-mode deepseek_v4
        --distributed-executor-backend mp
        --tool-call-parser deepseek_v4
        --enable-auto-tool-choice
        --reasoning-parser deepseek_v4
        --reasoning-config '{"reasoning_parser":"deepseek_v4","reasoning_start_str":"<think>","reasoning_end_str":"</think>"}'
        --default-chat-template-kwargs '{"thinking":false}'
        --generation-config vllm
        --enable-flashinfer-autotune
        --nnodes 2
        --node-rank 0
        --master-addr ${MASTER_ADDR}
        --master-port ${MASTER_PORT:-25000}
        ${HEADLESS:+--headless}
```

## Worker Node docker-compose.yml
```yaml
services:
  deepseek-v4-flash-dspark-worker:
    image: ${DSPARK_VLLM_IMAGE:-vllm-dspark-runtime:dspark-nvfp4-stage-c}
    container_name: deepseek-v4-flash-dspark-worker
    hostname: inference-server
    network_mode: "host"
    privileged: true
    ipc: "host"
    shm_size: "64gb"
    devices:
      - /dev/infiniband:/dev/infiniband
    ulimits:
      memlock:
        soft: -1
        hard: -1
    volumes:
      - ~/.cache/huggingface:/cache/huggingface
    deploy:
      resources:
        reservations:
          devices:
            - driver: nvidia
              count: 1
              capabilities: [gpu]
    environment:
      HF_HOME: /cache/huggingface
      HF_HUB_OFFLINE: "1"
      VLLM_CACHE_ROOT: /cache/huggingface/vllm-cache
      VLLM_HOST_IP: "${VLLM_HOST_IP:-}"

      VLLM_ALLOW_LONG_MAX_MODEL_LEN: "1"
      VLLM_TRITON_MLA_SPARSE: "1"
      VLLM_SPARSE_INDEXER_MAX_LOGITS_MB: "256"
      VLLM_MEMORY_PROFILER_ESTIMATE_CUDAGRAPHS: "0"
      VLLM_SKIP_INIT_MEMORY_CHECK: "1"

      VLLM_USE_FLASHINFER_SAMPLER: "1"

      VLLM_USE_B12X_MOE: "1"
      VLLM_USE_B12X_WO_PROJECTION: "1"
      VLLM_B12X_W4A16_FORCE_BLOCKS_PER_SM: "0"
      VLLM_B12X_W4A16_FORCE_BLOCKS_MAX_M: "16"
      B12X_W4A16_TC_DECODE: "0"

      VLLM_DSPARK_CONFIDENCE_THRESHOLD: "0.0"
      VLLM_DSPARK_CONFIDENCE_SCHEDULER: "off"
      VLLM_DSPARK_LOCAL_ARGMAX: "1"
      VLLM_DSPARK_REPLICATE_MARKOV_W1: "1"
      VLLM_DSPARK_FUSED_MARKOV_ARGMAX: "0"
      VLLM_DSPARK_GPU_REJECTED_CONTEXT_MASK: "1"
      VLLM_DSPARK_REFERENCE_KV_QUANT_DEQUANT: "0"
      VLLM_DSPARK_HARDWARE_SCHEDULER_EARLY_STOP: "1"
      VLLM_DSV4_B12X_COMPRESSED_MLA: "0"
      VLLM_DSV4_DSPARK_DEFER_TARGET_CAPTURE: "0"
      VLLM_DSV4_DSPARK_DEFER_TARGET_CAPTURE_EXACT: "0"

      TORCH_CUDA_ARCH_LIST: "12.1a"
      FLASHINFER_CUDA_ARCH_LIST: "12.1a"
      FLASHINFER_DISABLE_VERSION_CHECK: "1"
      TILELANG_CLEANUP_TEMP_FILES: "1"
      DG_JIT_USE_NVRTC: "0"
      DG_JIT_NVCC_COMPILER: /opt/env/bin/nvcc
      PYTORCH_CUDA_ALLOC_CONF: "expandable_segments:True"

      NCCL_NET: "IB"
      NCCL_IB_DISABLE: "0"
      NCCL_IB_HCA: "${NCCL_IB_HCA:-rocep1s0f0,roceP2p1s0f0}"
      NCCL_IB_GID_INDEX: "${NCCL_IB_GID_INDEX:-4,4}"
      NCCL_SOCKET_IFNAME: "${NCCL_SOCKET_IFNAME:-enP7s7}"
      GLOO_SOCKET_IFNAME: "${GLOO_SOCKET_IFNAME:-enP7s7}"
      TP_SOCKET_IFNAME: "${TP_SOCKET_IFNAME:-enP7s7}"
      NCCL_CROSS_NIC: "1"
      NCCL_CUMEM_ENABLE: "0"
      NCCL_IGNORE_CPU_AFFINITY: "1"
      NCCL_DEBUG: "${NCCL_DEBUG:-WARN}"
      NCCL_NVLS_ENABLE: "0"

      CUDA_VISIBLE_DEVICES: "0"

    command:
      - bash
      - -lc
      - >
        export PATH="/opt/env/bin:/opt/env/nvvm/bin:/opt/env/targets/sbsa-linux/nvvm/bin:$${PATH:-}";
        export CUDA_HOME="$${CUDA_HOME:-/opt/env/targets/sbsa-linux}";
        export CUDA_PATH="$${CUDA_PATH:-$${CUDA_HOME}}";
        export CUDAToolkit_ROOT="$${CUDAToolkit_ROOT:-$${CUDA_HOME}}";
        export LD_LIBRARY_PATH="/opt/env/lib:/opt/env/targets/sbsa-linux/lib:$${LD_LIBRARY_PATH:-}";
        SPECULATIVE_CONFIG="{\"method\":\"dspark\",\"num_speculative_tokens\":${MTP_NUM_TOKENS:-3},\"draft_sample_method\":\"probabilistic\"}";
        exec /opt/env/bin/vllm serve ${DSPARK_MODEL:-deepseek-ai/DeepSeek-V4-Flash-DSpark}
        --served-model-name ${INFERENCE_MODEL_ALIAS:-deepseek-v4-flash}
        --api-key ${INFERENCE_API_KEY:-dummy-key}
        --host 0.0.0.0
        --port 8000
        --trust-remote-code
        --tensor-parallel-size 2
        --pipeline-parallel-size 1
        --kv-cache-dtype nvfp4_ds_mla
        --block-size 256
        --max-model-len ${MAX_MODEL_LEN:-1048576}
        --max-num-seqs ${MAX_NUM_SEQS:-12}
        --max-num-batched-tokens ${MAX_NUM_BATCHED_TOKENS:-8192}
        --max-cudagraph-capture-size ${MAX_NUM_SEQS:-12}
        --gpu-memory-utilization ${GPU_MEMORY_UTILIZATION:-0.85}
        --enable-prefix-caching
        --async-scheduling
        --enable-chunked-prefill
        --speculative-config "$${SPECULATIVE_CONFIG}"
        --tokenizer-mode deepseek_v4
        --distributed-executor-backend mp
        --tool-call-parser deepseek_v4
        --enable-auto-tool-choice
        --reasoning-parser deepseek_v4
        --reasoning-config '{"reasoning_parser":"deepseek_v4","reasoning_start_str":"<think>","reasoning_end_str":"</think>"}'
        --default-chat-template-kwargs '{"thinking":false}'
        --generation-config vllm
        --enable-flashinfer-autotune
        --nnodes 2
        --node-rank 1
        --master-addr ${MASTER_ADDR}
        --master-port ${MASTER_PORT:-25000}
        --headless
```

## vLLM Server Log
```
(APIServer pid=1) INFO 07-05 08:51:34 [utils.py:344] 
(APIServer pid=1) INFO 07-05 08:51:34 [utils.py:344]        █     █     █▄   ▄█
(APIServer pid=1) INFO 07-05 08:51:34 [utils.py:344]  ▄▄ ▄█ █     █     █ ▀▄▀ █  version 0.21.1rc1.dev339+g1967a5627bc3
(APIServer pid=1) INFO 07-05 08:51:34 [utils.py:344]   █▄█▀ █     █     █     █  model   deepseek-ai/DeepSeek-V4-Flash-DSpark
(APIServer pid=1) INFO 07-05 08:51:34 [utils.py:344]    ▀▀  ▀▀▀▀▀ ▀▀▀▀▀ ▀     ▀
(APIServer pid=1) INFO 07-05 08:51:34 [utils.py:344] 
(APIServer pid=1) INFO 07-05 08:51:34 [utils.py:278] non-default args: {'model_tag': 'deepseek-ai/DeepSeek-V4-Flash-DSpark', 'default_chat_template_kwargs': {'thinking': False}, 'enable_auto_tool_choice': True, 'tool_call_parser': 'deepseek_v4', 'host': '0.0.0.0', 'api_key': ['dummy-key'], 'model': 'deepseek-ai/DeepSeek-V4-Flash-DSpark', 'tokenizer_mode': 'deepseek_v4', 'trust_remote_code': True, 'max_model_len': 1048576, 'served_model_name': ['deepseek-v4-flash'], 'generation_config': 'vllm', 'reasoning_parser': 'deepseek_v4', 'distributed_executor_backend': 'mp', 'master_addr': '10.0.1.1', 'master_port': 25000, 'nnodes': 2, 'tensor_parallel_size': 2, 'block_size': 256, 'gpu_memory_utilization': 0.85, 'kv_cache_dtype': 'nvfp4_ds_mla', 'enable_prefix_caching': True, 'max_num_batched_tokens': 8192, 'max_num_seqs': 12, 'enable_chunked_prefill': True, 'async_scheduling': True, 'max_cudagraph_capture_size': 12, 'enable_flashinfer_autotune': True, 'speculative_config': {'method': 'dspark', 'num_speculative_tokens': 3, 'draft_sample_method': 'probabilistic'}, 'reasoning_config': ReasoningConfig(reasoning_parser='deepseek_v4', reasoning_start_str='<think>', reasoning_end_str='</think>')}
(APIServer pid=1) INFO 07-05 08:51:34 [arg_utils.py:753] HF_HUB_OFFLINE is True, replace model_id [deepseek-ai/DeepSeek-V4-Flash-DSpark] to model_path [/cache/huggingface/hub/models--deepseek-ai--DeepSeek-V4-Flash-DSpark/snapshots/62af8fffb2f7030cac4de2f0169f5b8d1101b646]
(APIServer pid=1) WARNING 07-05 08:51:34 [envs.py:2194] Unknown vLLM environment variable detected: VLLM_SKIP_INIT_MEMORY_CHECK
(APIServer pid=1) WARNING 07-05 08:51:34 [envs.py:2194] Unknown vLLM environment variable detected: VLLM_TRITON_MLA_SPARSE
(APIServer pid=1) INFO 07-05 08:51:34 [config.py:801] Detected quantization_config.scale_fmt=ue8m0; enabling UE8M0 for DeepGEMM.
(APIServer pid=1) INFO 07-05 08:51:34 [model.py:617] Resolved architecture: DeepseekV4ForCausalLM
(APIServer pid=1) INFO 07-05 08:51:34 [model.py:1752] Using max model len 1048576
(APIServer pid=1) INFO 07-05 08:51:36 [cache.py:262] Using nvfp4_ds_mla data type to store kv cache. It reduces the GPU memory footprint and boosts the performance. Meanwhile, it may cause accuracy drop without a proper scaling factor
(APIServer pid=1) INFO 07-05 08:51:36 [arg_utils.py:1905] Inferred data_parallel_rank 0 from node_rank 0
(APIServer pid=1) INFO 07-05 08:51:36 [model.py:617] Resolved architecture: DeepSeekV4DSparkModel
(APIServer pid=1) INFO 07-05 08:51:36 [model.py:1752] Using max model len 1048576
(APIServer pid=1) INFO 07-05 08:51:36 [scheduler.py:239] Chunked prefill is enabled with max_num_batched_tokens=8192.
(APIServer pid=1) INFO 07-05 08:51:36 [vllm.py:977] Asynchronous scheduling is enabled.
(APIServer pid=1) INFO 07-05 08:51:36 [kernel.py:274] Final IR op priority after setting platform defaults: IrOpPriorityConfig(rms_norm=['native'], fused_add_rms_norm=['native'])
(APIServer pid=1) WARNING 07-05 08:51:36 [vllm.py:1719] Truncating max_cudagraph_capture_size to 8
(APIServer pid=1) INFO 07-05 08:51:36 [compilation.py:321] Enabled custom fusions: norm_quant, act_quant
(EngineCore pid=58) INFO 07-05 08:51:40 [core.py:112] Initializing a V1 LLM engine (v0.21.1rc1.dev339+g1967a5627bc3) with config: model='/cache/huggingface/hub/models--deepseek-ai--DeepSeek-V4-Flash-DSpark/snapshots/62af8fffb2f7030cac4de2f0169f5b8d1101b646', speculative_config=SpeculativeConfig(method='dspark', model='/cache/huggingface/hub/models--deepseek-ai--DeepSeek-V4-Flash-DSpark/snapshots/62af8fffb2f7030cac4de2f0169f5b8d1101b646', num_spec_tokens=3), tokenizer='/cache/huggingface/hub/models--deepseek-ai--DeepSeek-V4-Flash-DSpark/snapshots/62af8fffb2f7030cac4de2f0169f5b8d1101b646', skip_tokenizer_init=False, tokenizer_mode=deepseek_v4, revision=None, tokenizer_revision=None, trust_remote_code=True, dtype=torch.bfloat16, max_seq_len=1048576, download_dir=None, load_format=auto, tensor_parallel_size=2, pipeline_parallel_size=1, data_parallel_size=1, decode_context_parallel_size=1, dcp_comm_backend=ag_rs, disable_custom_all_reduce=True, quantization=deepseek_v4_fp8, quantization_config=None, enforce_eager=False, enable_return_routed_experts=False, kv_cache_dtype=nvfp4_ds_mla, device_config=cuda, structured_outputs_config=StructuredOutputsConfig(backend='auto', disable_any_whitespace=False, disable_additional_properties=False, reasoning_parser='deepseek_v4', reasoning_parser_plugin='', enable_in_reasoning=False), observability_config=ObservabilityConfig(show_hidden_metrics_for_version=None, otlp_traces_endpoint=None, collect_detailed_traces=None, kv_cache_metrics=False, kv_cache_metrics_sample=0.01, cudagraph_metrics=False, enable_layerwise_nvtx_tracing=False, enable_mfu_metrics=False, enable_mm_processor_stats=False, enable_logging_iteration_details=False), seed=0, served_model_name=deepseek-v4-flash, enable_prefix_caching=True, enable_chunked_prefill=True, pooler_config=None, compilation_config={'mode': <CompilationMode.VLLM_COMPILE: 3>, 'debug_dump_path': None, 'cache_dir': '', 'compile_cache_save_format': 'binary', 'backend': 'inductor', 'custom_ops': ['+quant_fp8', 'none', '+quant_fp8'], 'ir_enable_torch_wrap': True, 'splitting_ops': ['vllm::unified_attention_with_output', 'vllm::unified_mla_attention_with_output', 'vllm::mamba_mixer2', 'vllm::mamba_mixer', 'vllm::short_conv', 'vllm::linear_attention', 'vllm::plamo2_mamba_mixer', 'vllm::qwen_gdn_attention_core', 'vllm::gdn_attention_core_xpu', 'vllm::olmo_hybrid_gdn_full_forward', 'vllm::kda_attention', 'vllm::sparse_attn_indexer', 'vllm::rocm_aiter_sparse_attn_indexer', 'vllm::deepseek_v4_attention', 'vllm::unified_kv_cache_update', 'vllm::unified_mla_kv_cache_update'], 'compile_mm_encoder': False, 'cudagraph_mm_encoder': False, 'encoder_cudagraph_token_budgets': [], 'encoder_cudagraph_max_vision_items_per_batch': 0, 'encoder_cudagraph_max_frames_per_batch': None, 'compile_sizes': [], 'compile_ranges_endpoints': [8192], 'inductor_compile_config': {'enable_auto_functionalized_v2': False, 'size_asserts': False, 'alignment_asserts': False, 'scalar_asserts': False, 'combo_kernels': True, 'benchmark_combo_kernel': True}, 'inductor_passes': {}, 'cudagraph_mode': <CUDAGraphMode.FULL_AND_PIECEWISE: (2, 1)>, 'cudagraph_num_of_warmups': 1, 'cudagraph_capture_sizes': [1, 2, 4, 8], 'cudagraph_copy_inputs': False, 'cudagraph_specialize_lora': True, 'use_inductor_graph_partition': False, 'pass_config': {'fuse_norm_quant': True, 'fuse_act_quant': True, 'fuse_attn_quant': False, 'enable_sp': False, 'fuse_gemm_comms': False, 'fuse_allreduce_rms': False, 'fuse_rope_kvcache_cat_mla': False, 'fuse_act_padding': False}, 'max_cudagraph_capture_size': 8, 'dynamic_shapes_config': {'type': <DynamicShapesType.BACKED: 'backed'>, 'evaluate_guards': False, 'assume_32_bit_indexing': False}, 'local_cache_dir': None, 'fast_moe_cold_start': False, 'static_all_moe_layers': []}, kernel_config=KernelConfig(ir_op_priority=IrOpPriorityConfig(rms_norm=['native'], fused_add_rms_norm=['native']), enable_flashinfer_autotune=True, moe_backend='auto', linear_backend='auto')
(EngineCore pid=58) INFO 07-05 08:51:40 [multiproc_executor.py:139] DP group leader: node_rank=0, node_rank_within_dp=0, master_addr=10.0.1.1, mq_connect_ip=10.0.1.1 (local), world_size=2, local_world_size=1
(Worker pid=79) INFO 07-05 08:51:44 [parallel_state.py:1422] world_size=2 rank=0 local_rank=0 distributed_init_method=tcp://10.0.1.1:25000 backend=nccl
(Worker pid=79) INFO 07-05 08:51:56 [nccl.py:24] Found nccl from environment variable VLLM_NCCL_SO_PATH=/opt/env/lib/python3.12/site-packages/nvidia/nccl/lib/libnccl.so.2
(Worker pid=79) INFO 07-05 08:51:56 [pynccl.py:113] vLLM is using nccl==2.30.4
(Worker pid=79) WARNING 07-05 08:51:57 [symm_mem.py:66] SymmMemCommunicator: Device capability 12.1 not supported, communicator is not available.
(Worker pid=79) INFO 07-05 08:51:57 [cuda_communicator.py:233] Using ['PYNCCL'] all-reduce backends (in dispatch order) for group 'tp:0' out of potential backends: ['NCCL_SYMM_MEM', 'QUICK_REDUCE', 'FLASHINFER', 'CUSTOM', 'SYMM_MEM', 'PYNCCL'].
(Worker pid=79) INFO 07-05 08:51:57 [nccl.py:24] Found nccl from environment variable VLLM_NCCL_SO_PATH=/opt/env/lib/python3.12/site-packages/nvidia/nccl/lib/libnccl.so.2
(Worker pid=79) INFO 07-05 08:51:57 [cuda_communicator.py:233] Using ['PYNCCL'] all-reduce backends (in dispatch order) for group 'ep:0' out of potential backends: ['NCCL_SYMM_MEM', 'QUICK_REDUCE', 'FLASHINFER', 'CUSTOM', 'SYMM_MEM', 'PYNCCL'].
(Worker pid=79) INFO 07-05 08:51:57 [parallel_state.py:1735] rank 0 in world size 2 is assigned as DP rank 0, PP rank 0, PCP rank 0, TP rank 0, EP rank 0, EPLB rank N/A
(Worker pid=79) INFO 07-05 08:51:58 [topk_topp_sampler.py:45] Using FlashInfer for top-p & top-k sampling.
(Worker pid=79) INFO 07-05 08:51:58 [dspark_proposer.py:159] DSpark GPU rejected-context mask enabled. Rejected target suffix rows are masked during draft main-KV cache update without synchronizing rejection counts to CPU.
(Worker pid=79) INFO 07-05 08:51:58 [dspark_proposer.py:170] DSpark fast draft-output mode enabled: confidence head and returned draft logits are skipped on the hot path.
(Worker pid=79) WARNING 07-05 08:51:58 [__init__.py:204] min_p and logit_bias parameters won't work with speculative decoding.
(Worker_TP0 pid=79) INFO 07-05 08:51:58 [gpu_model_runner.py:5313] Starting to load model /cache/huggingface/hub/models--deepseek-ai--DeepSeek-V4-Flash-DSpark/snapshots/62af8fffb2f7030cac4de2f0169f5b8d1101b646...
(Worker_TP0 pid=79) INFO 07-05 08:51:58 [quant_config.py:73] DeepSeek V4 expert_dtype resolved to 'fp4'
(Worker_TP0 pid=79) INFO 07-05 08:51:58 [__init__.py:550] Selected DeepGemmFp8BlockScaledMMKernel for Fp8LinearMethod
(Worker_TP0 pid=79) INFO 07-05 08:51:58 [deep_gemm.py:117] DeepGEMM E8M0 enabled on current platform.
(Worker_TP0 pid=79) INFO 07-05 08:51:58 [attention.py:930] Using probe DeepSeek V4 nvfp4_ds_mla KV cache format.
(Worker_TP0 pid=79) INFO 07-05 08:51:58 [mxfp4.py:389] Using 'B12X' Mxfp4 MoE backend.
(Worker_TP0 pid=79) INFO 07-05 08:51:58 [attention.py:1051] Using FP8 indexer cache for Lightning Indexer.
(Worker_TP0 pid=79) INFO 07-05 08:52:01 [weight_utils.py:922] Filesystem type for checkpoints: EXT4. Checkpoint size: 155.43 GiB. Available RAM: 35.60 GiB.
(Worker_TP0 pid=79) INFO 07-05 08:52:01 [weight_utils.py:952] Auto-prefetch is disabled because the filesystem (EXT4) is not a recognized network FS (NFS/Lustre) and the checkpoint size (155.43 GiB) exceeds 90% of available RAM (35.60 GiB).
(Worker_TP0 pid=79) Loading safetensors checkpoint shards:   0% Completed | 0/48 [00:00<?, ?it/s]
(Worker_TP0 pid=79) Loading safetensors checkpoint shards:   2% Completed | 1/48 [00:03<02:26,  3.12s/it]
(Worker_TP0 pid=79) Loading safetensors checkpoint shards:   4% Completed | 2/48 [00:05<02:04,  2.70s/it]
(Worker_TP0 pid=79) Loading safetensors checkpoint shards:   6% Completed | 3/48 [00:07<01:53,  2.53s/it]
(Worker_TP0 pid=79) Loading safetensors checkpoint shards:   8% Completed | 4/48 [00:10<01:49,  2.48s/it]
(Worker_TP0 pid=79) Loading safetensors checkpoint shards:  10% Completed | 5/48 [00:13<01:53,  2.64s/it]
(Worker_TP0 pid=79) Loading safetensors checkpoint shards:  12% Completed | 6/48 [00:16<01:56,  2.76s/it]
(Worker_TP0 pid=79) Loading safetensors checkpoint shards:  15% Completed | 7/48 [00:19<01:54,  2.80s/it]
(Worker_TP0 pid=79) Loading safetensors checkpoint shards:  17% Completed | 8/48 [00:21<01:53,  2.83s/it]
(Worker_TP0 pid=79) Loading safetensors checkpoint shards:  19% Completed | 9/48 [00:24<01:50,  2.82s/it]
(Worker_TP0 pid=79) Loading safetensors checkpoint shards:  21% Completed | 10/48 [00:28<01:56,  3.05s/it]
(Worker_TP0 pid=79) Loading safetensors checkpoint shards:  23% Completed | 11/48 [00:32<02:04,  3.36s/it]
(Worker_TP0 pid=79) Loading safetensors checkpoint shards:  25% Completed | 12/48 [00:35<01:58,  3.28s/it]
(Worker_TP0 pid=79) Loading safetensors checkpoint shards:  27% Completed | 13/48 [00:38<01:51,  3.19s/it]
(Worker_TP0 pid=79) Loading safetensors checkpoint shards:  29% Completed | 14/48 [00:42<01:52,  3.30s/it]
(Worker_TP0 pid=79) Loading safetensors checkpoint shards:  31% Completed | 15/48 [00:45<01:50,  3.34s/it]
(Worker_TP0 pid=79) Loading safetensors checkpoint shards:  33% Completed | 16/48 [00:49<01:50,  3.44s/it]
(Worker_TP0 pid=79) Loading safetensors checkpoint shards:  35% Completed | 17/48 [00:52<01:48,  3.49s/it]
(Worker_TP0 pid=79) Loading safetensors checkpoint shards:  38% Completed | 18/48 [00:56<01:48,  3.60s/it]
(Worker_TP0 pid=79) Loading safetensors checkpoint shards:  40% Completed | 19/48 [01:00<01:43,  3.56s/it]
(Worker_TP0 pid=79) Loading safetensors checkpoint shards:  42% Completed | 20/48 [01:03<01:38,  3.50s/it]
(Worker_TP0 pid=79) Loading safetensors checkpoint shards:  44% Completed | 21/48 [01:06<01:32,  3.42s/it]
(Worker_TP0 pid=79) Loading safetensors checkpoint shards:  46% Completed | 22/48 [01:10<01:29,  3.43s/it]
(Worker_TP0 pid=79) Loading safetensors checkpoint shards:  48% Completed | 23/48 [01:13<01:25,  3.41s/it]
(Worker_TP0 pid=79) Loading safetensors checkpoint shards:  50% Completed | 24/48 [01:16<01:21,  3.38s/it]
(Worker_TP0 pid=79) Loading safetensors checkpoint shards:  52% Completed | 25/48 [01:20<01:16,  3.34s/it]
(Worker_TP0 pid=79) Loading safetensors checkpoint shards:  54% Completed | 26/48 [01:23<01:14,  3.41s/it]
(Worker_TP0 pid=79) Loading safetensors checkpoint shards:  56% Completed | 27/48 [01:27<01:15,  3.57s/it]
(Worker_TP0 pid=79) Loading safetensors checkpoint shards:  58% Completed | 28/48 [01:30<01:10,  3.53s/it]
(Worker_TP0 pid=79) Loading safetensors checkpoint shards:  60% Completed | 29/48 [01:34<01:07,  3.54s/it]
(Worker_TP0 pid=79) Loading safetensors checkpoint shards:  62% Completed | 30/48 [01:38<01:04,  3.60s/it]
(Worker_TP0 pid=79) Loading safetensors checkpoint shards:  65% Completed | 31/48 [01:41<01:00,  3.59s/it]
(Worker_TP0 pid=79) Loading safetensors checkpoint shards:  67% Completed | 32/48 [01:45<00:58,  3.65s/it]
(Worker_TP0 pid=79) Loading safetensors checkpoint shards:  69% Completed | 33/48 [01:49<00:55,  3.67s/it]
(Worker_TP0 pid=79) Loading safetensors checkpoint shards:  71% Completed | 34/48 [01:53<00:51,  3.70s/it]
(Worker_TP0 pid=79) Loading safetensors checkpoint shards:  73% Completed | 35/48 [01:56<00:46,  3.60s/it]
(Worker_TP0 pid=79) Loading safetensors checkpoint shards:  75% Completed | 36/48 [02:00<00:42,  3.58s/it]
(Worker_TP0 pid=79) Loading safetensors checkpoint shards:  77% Completed | 37/48 [02:03<00:38,  3.51s/it]
(Worker_TP0 pid=79) Loading safetensors checkpoint shards:  79% Completed | 38/48 [02:07<00:35,  3.59s/it]
(Worker_TP0 pid=79) Loading safetensors checkpoint shards:  81% Completed | 39/48 [02:10<00:32,  3.62s/it]
(Worker_TP0 pid=79) Loading safetensors checkpoint shards:  83% Completed | 40/48 [02:15<00:31,  3.88s/it]
(Worker_TP0 pid=79) Loading safetensors checkpoint shards:  85% Completed | 41/48 [02:18<00:26,  3.76s/it]
(Worker_TP0 pid=79) Loading safetensors checkpoint shards:  88% Completed | 42/48 [02:22<00:21,  3.64s/it]
(Worker_TP0 pid=79) Loading safetensors checkpoint shards:  90% Completed | 43/48 [02:25<00:17,  3.56s/it]
(Worker_TP0 pid=79) Loading safetensors checkpoint shards:  92% Completed | 44/48 [02:29<00:14,  3.57s/it]
(Worker_TP0 pid=79) Loading safetensors checkpoint shards:  94% Completed | 45/48 [02:29<00:07,  2.63s/it]
(Worker_TP0 pid=79) Loading safetensors checkpoint shards:  96% Completed | 46/48 [02:30<00:03,  1.98s/it]
(Worker_TP0 pid=79) Loading safetensors checkpoint shards:  98% Completed | 47/48 [02:30<00:01,  1.53s/it]
(Worker_TP0 pid=79) Loading safetensors checkpoint shards: 100% Completed | 48/48 [02:31<00:00,  1.25s/it]
(Worker_TP0 pid=79) Loading safetensors checkpoint shards: 100% Completed | 48/48 [02:31<00:00,  3.15s/it]
(Worker_TP0 pid=79) 
(Worker_TP0 pid=79) INFO 07-05 08:54:33 [default_loader.py:397] Loading weights took 151.24 seconds
(Worker_TP0 pid=79) INFO 07-05 08:54:33 [mxfp4.py:1789] Using MoEPrepareAndFinalizeNoDPEPModular
(Worker_TP0 pid=79) INFO 07-05 08:54:45 [gpu_model_runner.py:5337] Loading drafter model...
(Worker_TP0 pid=79) INFO 07-05 08:54:45 [vllm.py:977] Asynchronous scheduling is enabled.
(Worker_TP0 pid=79) INFO 07-05 08:54:45 [kernel.py:274] Final IR op priority after setting platform defaults: IrOpPriorityConfig(rms_norm=['native'], fused_add_rms_norm=['native'])
(Worker_TP0 pid=79) INFO 07-05 08:54:45 [compilation.py:321] Enabled custom fusions: norm_quant, act_quant
(Worker_TP0 pid=79) INFO 07-05 08:54:45 [kernel.py:274] Final IR op priority after setting platform defaults: IrOpPriorityConfig(rms_norm=['native'], fused_add_rms_norm=['native'])
(Worker_TP0 pid=79) INFO 07-05 08:54:46 [dspark.py:494] DSpark replicated Markov W1 enabled for model.layers.45.markov_head. This removes the per-position vocab-parallel embedding all-reduce.
(Worker_TP0 pid=79) INFO 07-05 08:54:46 [dspark.py:767] DSpark local vocab-parallel argmax is enabled. This is experimental and may add per-position synchronization overhead.
(Worker_TP0 pid=79) WARNING 07-05 08:54:47 [vllm.py:2159] `torch.compile` is turned on, but the model /cache/huggingface/hub/models--deepseek-ai--DeepSeek-V4-Flash-DSpark/snapshots/62af8fffb2f7030cac4de2f0169f5b8d1101b646 does not support it. Please open an issue on GitHub if you want it to be supported.
(Worker_TP0 pid=79) INFO 07-05 08:54:47 [weight_utils.py:922] Filesystem type for checkpoints: EXT4. Checkpoint size: 155.43 GiB. Available RAM: 31.73 GiB.
(Worker_TP0 pid=79) INFO 07-05 08:54:47 [weight_utils.py:952] Auto-prefetch is disabled because the filesystem (EXT4) is not a recognized network FS (NFS/Lustre) and the checkpoint size (155.43 GiB) exceeds 90% of available RAM (31.73 GiB).
(Worker_TP0 pid=79) Loading safetensors checkpoint shards:   0% Completed | 0/48 [00:00<?, ?it/s]
(Worker_TP0 pid=79) Loading safetensors checkpoint shards:   4% Completed | 2/48 [00:00<00:09,  4.82it/s]
(Worker_TP0 pid=79) Loading safetensors checkpoint shards:   6% Completed | 3/48 [00:00<00:13,  3.28it/s]
(Worker_TP0 pid=79) Loading safetensors checkpoint shards:   8% Completed | 4/48 [00:01<00:14,  2.95it/s]
(Worker_TP0 pid=79) Loading safetensors checkpoint shards:  10% Completed | 5/48 [00:01<00:15,  2.79it/s]
(Worker_TP0 pid=79) Loading safetensors checkpoint shards:  12% Completed | 6/48 [00:02<00:15,  2.64it/s]
(Worker_TP0 pid=79) Loading safetensors checkpoint shards:  15% Completed | 7/48 [00:02<00:16,  2.49it/s]
(Worker_TP0 pid=79) Loading safetensors checkpoint shards:  17% Completed | 8/48 [00:03<00:17,  2.33it/s]
(Worker_TP0 pid=79) Loading safetensors checkpoint shards:  19% Completed | 9/48 [00:03<00:18,  2.12it/s]
(Worker_TP0 pid=79) Loading safetensors checkpoint shards:  21% Completed | 10/48 [00:04<00:18,  2.01it/s]
(Worker_TP0 pid=79) Loading safetensors checkpoint shards:  23% Completed | 11/48 [00:04<00:19,  1.92it/s]
(Worker_TP0 pid=79) Loading safetensors checkpoint shards:  25% Completed | 12/48 [00:05<00:19,  1.89it/s]
(Worker_TP0 pid=79) Loading safetensors checkpoint shards:  27% Completed | 13/48 [00:05<00:18,  1.86it/s]
(Worker_TP0 pid=79) Loading safetensors checkpoint shards:  29% Completed | 14/48 [00:06<00:18,  1.81it/s]
(Worker_TP0 pid=79) Loading safetensors checkpoint shards:  31% Completed | 15/48 [00:06<00:18,  1.80it/s]
(Worker_TP0 pid=79) Loading safetensors checkpoint shards:  33% Completed | 16/48 [00:07<00:17,  1.79it/s]
(Worker_TP0 pid=79) Loading safetensors checkpoint shards:  35% Completed | 17/48 [00:08<00:17,  1.77it/s]
(Worker_TP0 pid=79) Loading safetensors checkpoint shards:  38% Completed | 18/48 [00:08<00:17,  1.76it/s]
(Worker_TP0 pid=79) Loading safetensors checkpoint shards:  40% Completed | 19/48 [00:09<00:16,  1.75it/s]
(Worker_TP0 pid=79) Loading safetensors checkpoint shards:  42% Completed | 20/48 [00:09<00:16,  1.74it/s]
(Worker_TP0 pid=79) Loading safetensors checkpoint shards:  44% Completed | 21/48 [00:10<00:15,  1.71it/s]
(Worker_TP0 pid=79) Loading safetensors checkpoint shards:  46% Completed | 22/48 [00:11<00:15,  1.71it/s]
(Worker_TP0 pid=79) Loading safetensors checkpoint shards:  48% Completed | 23/48 [00:11<00:14,  1.73it/s]
(Worker_TP0 pid=79) Loading safetensors checkpoint shards:  50% Completed | 24/48 [00:12<00:13,  1.76it/s]
(Worker_TP0 pid=79) Loading safetensors checkpoint shards:  52% Completed | 25/48 [00:12<00:12,  1.90it/s]
(Worker_TP0 pid=79) Loading safetensors checkpoint shards:  54% Completed | 26/48 [00:13<00:11,  1.99it/s]
(Worker_TP0 pid=79) Loading safetensors checkpoint shards:  56% Completed | 27/48 [00:13<00:10,  2.05it/s]
(Worker_TP0 pid=79) Loading safetensors checkpoint shards:  58% Completed | 28/48 [00:13<00:09,  2.10it/s]
(Worker_TP0 pid=79) Loading safetensors checkpoint shards:  60% Completed | 29/48 [00:14<00:09,  1.97it/s]
(Worker_TP0 pid=79) Loading safetensors checkpoint shards:  62% Completed | 30/48 [00:14<00:09,  1.98it/s]
(Worker_TP0 pid=79) Loading safetensors checkpoint shards:  65% Completed | 31/48 [00:15<00:08,  1.92it/s]
(Worker_TP0 pid=79) Loading safetensors checkpoint shards:  67% Completed | 32/48 [00:16<00:08,  1.94it/s]
(Worker_TP0 pid=79) Loading safetensors checkpoint shards:  69% Completed | 33/48 [00:16<00:07,  2.06it/s]
(Worker_TP0 pid=79) Loading safetensors checkpoint shards:  71% Completed | 34/48 [00:16<00:06,  2.30it/s]
(Worker_TP0 pid=79) Loading safetensors checkpoint shards:  73% Completed | 35/48 [00:17<00:05,  2.54it/s]
(Worker_TP0 pid=79) Loading safetensors checkpoint shards:  75% Completed | 36/48 [00:17<00:04,  2.74it/s]
(Worker_TP0 pid=79) Loading safetensors checkpoint shards:  77% Completed | 37/48 [00:17<00:03,  2.82it/s]
(Worker_TP0 pid=79) Loading safetensors checkpoint shards:  79% Completed | 38/48 [00:17<00:03,  3.05it/s]
(Worker_TP0 pid=79) Loading safetensors checkpoint shards:  90% Completed | 43/48 [00:18<00:00,  8.37it/s]
(Worker_TP0 pid=79) Loading safetensors checkpoint shards:  96% Completed | 46/48 [00:21<00:01,  1.99it/s]
(Worker_TP0 pid=79) Loading safetensors checkpoint shards: 100% Completed | 48/48 [00:27<00:00,  1.19s/it]
(Worker_TP0 pid=79) Loading safetensors checkpoint shards: 100% Completed | 48/48 [00:27<00:00,  1.72it/s]
(Worker_TP0 pid=79) 
(Worker_TP0 pid=79) INFO 07-05 08:55:15 [default_loader.py:397] Loading weights took 27.99 seconds
(Worker_TP0 pid=79) INFO 07-05 08:55:15 [llm_base_proposer.py:1334] Detected MTP model. Sharing target model embedding weights with the draft model.
(Worker_TP0 pid=79) INFO 07-05 08:55:15 [llm_base_proposer.py:1390] Detected MTP model. Sharing target model lm_head weights with the draft model.
(Worker_TP0 pid=79) INFO 07-05 08:55:15 [llm_base_proposer.py:1424] Detected MTP model with topk_indices_buffer. Sharing target model topk_indices_buffer with the draft model.
(Worker_TP0 pid=79) INFO 07-05 08:55:18 [gpu_model_runner.py:5408] Model loading took 79.52 GiB memory and 197.764892 seconds
(Worker_TP0 pid=79) INFO 07-05 08:55:19 [backends.py:1089] Using cache directory: /cache/huggingface/vllm-cache/torch_compile_cache/d8d288a9e4/rank_0_0/backbone for vLLM's torch.compile
(Worker_TP0 pid=79) INFO 07-05 08:55:19 [backends.py:1148] Dynamo bytecode transform time: 1.26 s
(Worker_TP0 pid=79) INFO 07-05 08:55:20 [backends.py:292] Directly load the compiled graph(s) for compile range (1, 8192) from the cache, took 0.202 s
(Worker_TP0 pid=79) INFO 07-05 08:55:20 [decorators.py:311] Directly load AOT compilation from path /cache/huggingface/vllm-cache/torch_compile_cache/torch_aot_compile/348fd1f53f1288e7b7d4f92e3b1446d86243296fd5981cd7dd3f01f5b1fe1c3f/rank_0_0/model
(Worker_TP0 pid=79) INFO 07-05 08:55:20 [monitor.py:53] torch.compile took 2.18 s in total
(Worker_TP0 pid=79) INFO 07-05 08:55:35 [monitor.py:81] Initial profiling/warmup run took 14.48 s
(Worker_TP0 pid=79) INFO 07-05 08:55:36 [gpu_model_runner.py:6568] Profiling CUDA graph memory: PIECEWISE=2 (largest=8), FULL=2 (largest=8)
(Worker_TP0 pid=79) INFO 07-05 08:55:49 [gpu_model_runner.py:6654] Estimated CUDA graph memory: 0.30 GiB total
(Worker_TP0 pid=79) INFO 07-05 08:55:49 [gpu_worker.py:466] Available KV cache memory: 20.36 GiB
(Worker_TP0 pid=79) WARNING 07-05 08:55:49 [gpu_worker.py:498] CUDA graph memory profiling is disabled (VLLM_MEMORY_PROFILER_ESTIMATE_CUDAGRAPHS=0). Without it, CUDA graph memory is not accounted for during KV cache allocation, which may require lowering --gpu-memory-utilization to avoid OOM. Consider re-enabling it (the default as of v0.21.0) and increasing --gpu-memory-utilization from 0.8500 to 0.8524.
(EngineCore pid=58) INFO 07-05 08:55:49 [kv_cache_utils.py:1733] GPU KV cache size: 3,076,565 tokens
(EngineCore pid=58) INFO 07-05 08:55:49 [kv_cache_utils.py:1734] Maximum concurrency for 1,048,576 tokens per request: 2.93x
(Worker_TP0 pid=79) INFO 07-05 08:55:54 [deepseek_v4_mhc_warmup.py:200] Warming up DeepSeek V4 mHC kernels for token sizes: [1, 2, 4, 8, 16, 32, 64, 128, 256, 512, 1024, 2048, 4096, 8192]
(Worker_TP0 pid=79) INFO 07-05 08:55:54 [deepseek_v4_mhc_warmup.py:209] DeepSeek V4 mHC warmup finished in 0.46 seconds.
(Worker_TP0 pid=79) INFO 07-05 08:55:54 [kernel_warmup.py:624] Warming up DeepSeek V4 sparse MLA attention for mixed tokens=16 and prefill tokens=8192.
(Worker_TP0 pid=79) INFO 07-05 08:55:54 [kernel_warmup.py:548] Including 2 DSpark uniform-decode sparse MLA autotune shapes.
(Worker_TP0 pid=79) INFO 07-05 08:55:54 [kernel_warmup.py:558] Autotuning DeepSeek V4 SM120 sparse MLA decode with FlashInfer cache file: /cache/huggingface/vllm-cache/flashinfer_autotune_cache/0.6.12/121a/e1e60266726f0f43c8cbc0c4718f9bf226d0d45561c0b3670a11f59521dd39f9/autotune_configs.json
(Worker_TP0 pid=79) 2026-07-05 08:55:54,532 - INFO - autotuner.py:1837 - flashinfer.jit: [Autotuner]: Loaded 30 configs from /cache/huggingface/vllm-cache/flashinfer_autotune_cache/0.6.12/121a/e1e60266726f0f43c8cbc0c4718f9bf226d0d45561c0b3670a11f59521dd39f9/autotune_configs.json
(Worker_TP0 pid=79) 2026-07-05 08:55:54,532 - INFO - autotuner.py:622 - flashinfer.jit: [Autotuner]: Autotuning process starts ...
(Worker_TP0 pid=79) 2026-07-05 08:55:54,552 - INFO - autotuner.py:961 - flashinfer.jit: [Autotuner]: Config cache hit for sparse_mla_sm120_decode_dsv4 (runner=SparseMlaDecodeV3Runner, source=config file)
(Worker_TP0 pid=79) 2026-07-05 08:56:00,424 - INFO - autotuner.py:641 - flashinfer.jit: [Autotuner]: Autotuning process ends
(Worker_TP0 pid=79) 2026-07-05 08:56:00,437 - INFO - autotuner.py:1837 - flashinfer.jit: [Autotuner]: Loaded 30 configs from /cache/huggingface/vllm-cache/flashinfer_autotune_cache/0.6.12/121a/e1e60266726f0f43c8cbc0c4718f9bf226d0d45561c0b3670a11f59521dd39f9/autotune_configs.json
(Worker_TP0 pid=79) INFO 07-05 08:56:00 [kernel_warmup.py:592] DeepSeek V4 sparse MLA decode autotune cache loaded on rank 0 from /cache/huggingface/vllm-cache/flashinfer_autotune_cache/0.6.12/121a/e1e60266726f0f43c8cbc0c4718f9bf226d0d45561c0b3670a11f59521dd39f9/autotune_configs.json.
(Worker_TP0 pid=79) INFO 07-05 08:56:09 [kernel_warmup.py:498] Warming up DeepSeek V4 request preparation kernels.
(Worker_TP0 pid=79) DeepGEMM warmup:   0%|          | 0/1447 [00:00<?, ?it/s]DeepGEMM warmup:  38%|███▊      | 546/1447 [00:00<00:00, 2191.25it/s]DeepGEMM warmup:  77%|███████▋  | 1118/1447 [00:00<00:00, 3058.06it/s]DeepGEMM warmup: 100%|██████████| 1447/1447 [00:00<00:00, 3641.08it/s]
(Worker_TP0 pid=79) 2026-07-05 08:56:11,778 - INFO - autotuner.py:622 - flashinfer.jit: [Autotuner]: Autotuning process starts ...
(Worker_TP0 pid=79) 2026-07-05 08:56:14,436 - INFO - autotuner.py:641 - flashinfer.jit: [Autotuner]: Autotuning process ends
(Worker_TP0 pid=79) Capturing CUDA graphs (mixed prefill-decode, PIECEWISE):   0%|          | 0/2 [00:00<?, ?it/s]Capturing CUDA graphs (mixed prefill-decode, PIECEWISE):  50%|█████     | 1/2 [00:00<00:00,  1.63it/s]Capturing CUDA graphs (mixed prefill-decode, PIECEWISE): 100%|██████████| 2/2 [00:01<00:00,  1.60it/s]Capturing CUDA graphs (mixed prefill-decode, PIECEWISE): 100%|██████████| 2/2 [00:01<00:00,  1.60it/s]
(Worker_TP0 pid=79) Capturing CUDA graphs (decode, FULL):   0%|          | 0/2 [00:00<?, ?it/s]Capturing CUDA graphs (decode, FULL):  50%|█████     | 1/2 [00:00<00:00,  3.56it/s]Capturing CUDA graphs (decode, FULL): 100%|██████████| 2/2 [00:00<00:00,  4.06it/s]Capturing CUDA graphs (decode, FULL): 100%|██████████| 2/2 [00:00<00:00,  3.98it/s]
(Worker_TP0 pid=79) INFO 07-05 08:56:17 [gpu_model_runner.py:6745] Graph capturing finished in 3 secs, took 0.12 GiB
(Worker_TP0 pid=79) INFO 07-05 08:56:17 [gpu_worker.py:619] CUDA graph pool memory: 0.12 GiB (actual), 0.3 GiB (estimated), difference: 0.18 GiB (153.2%).
(Worker_TP0 pid=79) INFO 07-05 08:56:17 [jit_monitor.py:54] Kernel JIT monitor activated — Triton JIT compilations during inference will be logged as warnings.
(EngineCore pid=58) INFO 07-05 08:56:17 [core.py:302] init engine (profile, create kv cache, warmup model) took 59.60 s (compilation: 2.91 s)
(EngineCore pid=58) INFO 07-05 08:56:20 [vllm.py:977] Asynchronous scheduling is enabled.
(EngineCore pid=58) INFO 07-05 08:56:20 [kernel.py:274] Final IR op priority after setting platform defaults: IrOpPriorityConfig(rms_norm=['native'], fused_add_rms_norm=['native'])
(EngineCore pid=58) INFO 07-05 08:56:20 [compilation.py:321] Enabled custom fusions: norm_quant, act_quant
(APIServer pid=1) INFO 07-05 08:56:20 [api_server.py:592] Supported tasks: ['generate']
(APIServer pid=1) INFO 07-05 08:56:21 [parser_manager.py:202] "auto" tool choice has been enabled.
(APIServer pid=1) INFO 07-05 08:56:21 [api_server.py:596] Starting vLLM server on http://0.0.0.0:8000
(APIServer pid=1) INFO 07-05 08:56:21 [launcher.py:37] Available routes are:
(APIServer pid=1) INFO 07-05 08:56:21 [launcher.py:46] Route: /openapi.json, Methods: GET, HEAD
(APIServer pid=1) INFO 07-05 08:56:21 [launcher.py:46] Route: /docs, Methods: GET, HEAD
(APIServer pid=1) INFO 07-05 08:56:21 [launcher.py:46] Route: /docs/oauth2-redirect, Methods: GET, HEAD
(APIServer pid=1) INFO 07-05 08:56:21 [launcher.py:46] Route: /redoc, Methods: GET, HEAD
(APIServer pid=1) INFO 07-05 08:56:21 [launcher.py:46] Route: /tokenize, Methods: POST
(APIServer pid=1) INFO 07-05 08:56:21 [launcher.py:46] Route: /detokenize, Methods: POST
(APIServer pid=1) INFO 07-05 08:56:21 [launcher.py:46] Route: /load, Methods: GET
(APIServer pid=1) INFO 07-05 08:56:21 [launcher.py:46] Route: /version, Methods: GET
(APIServer pid=1) INFO 07-05 08:56:21 [launcher.py:46] Route: /health, Methods: GET
(APIServer pid=1) INFO 07-05 08:56:21 [launcher.py:46] Route: /metrics, Methods: GET
(APIServer pid=1) INFO 07-05 08:56:21 [launcher.py:46] Route: /v1/models, Methods: GET
(APIServer pid=1) INFO 07-05 08:56:21 [launcher.py:46] Route: /ping, Methods: GET
(APIServer pid=1) INFO 07-05 08:56:21 [launcher.py:46] Route: /ping, Methods: POST
(APIServer pid=1) INFO 07-05 08:56:21 [launcher.py:46] Route: /invocations, Methods: POST
(APIServer pid=1) INFO 07-05 08:56:21 [launcher.py:46] Route: /v1/chat/completions, Methods: POST
(APIServer pid=1) INFO 07-05 08:56:21 [launcher.py:46] Route: /v1/chat/completions/batch, Methods: POST
(APIServer pid=1) INFO 07-05 08:56:21 [launcher.py:46] Route: /v1/responses, Methods: POST
(APIServer pid=1) INFO 07-05 08:56:21 [launcher.py:46] Route: /v1/responses/{response_id}, Methods: GET
(APIServer pid=1) INFO 07-05 08:56:21 [launcher.py:46] Route: /v1/responses/{response_id}/cancel, Methods: POST
(APIServer pid=1) INFO 07-05 08:56:21 [launcher.py:46] Route: /v1/completions, Methods: POST
(APIServer pid=1) INFO 07-05 08:56:21 [launcher.py:46] Route: /v1/messages, Methods: POST
(APIServer pid=1) INFO 07-05 08:56:21 [launcher.py:46] Route: /v1/messages/count_tokens, Methods: POST
(APIServer pid=1) INFO 07-05 08:56:21 [launcher.py:46] Route: /inference/v1/generate, Methods: POST
(APIServer pid=1) INFO 07-05 08:56:21 [launcher.py:46] Route: /scale_elastic_ep, Methods: POST
(APIServer pid=1) INFO 07-05 08:56:21 [launcher.py:46] Route: /is_scaling_elastic_ep, Methods: POST
(APIServer pid=1) INFO 07-05 08:56:21 [launcher.py:46] Route: /generative_scoring, Methods: POST
(APIServer pid=1) INFO 07-05 08:56:21 [launcher.py:46] Route: /v1/chat/completions/render, Methods: POST
(APIServer pid=1) INFO 07-05 08:56:21 [launcher.py:46] Route: /v1/completions/render, Methods: POST
(APIServer pid=1) INFO:     Started server process [1]
(APIServer pid=1) INFO:     Waiting for application startup.
(APIServer pid=1) INFO:     Application startup complete.
(APIServer pid=1) INFO:     172.18.0.2:52330 - "GET /v1/models HTTP/1.1" 200 OK
(APIServer pid=1) INFO:     172.18.0.2:38934 - "POST /v1/chat/completions HTTP/1.1" 200 OK
(Worker_TP0 pid=79) WARNING 07-05 09:03:01 [jit_monitor.py:103] Triton kernel JIT compilation during inference: sample_recovered_tokens_kernel. This causes a latency spike; consider extending warmup to cover this shape/config.
(Worker_TP0 pid=79) WARNING 07-05 09:03:01 [jit_monitor.py:103] Triton kernel JIT compilation during inference: rejection_random_sample_kernel. This causes a latency spike; consider extending warmup to cover this shape/config.
(APIServer pid=1) INFO 07-05 09:03:03 [loggers.py:271] Engine 000: Avg prompt throughput: 1.5 tokens/s, Avg generation throughput: 5.3 tokens/s, Running: 0 reqs, Waiting: 0 reqs, GPU KV cache usage: 0.0%, Prefix cache hit rate: 0.0%
(APIServer pid=1) INFO 07-05 09:03:03 [metrics.py:101] SpecDecoding metrics: Mean acceptance length: 2.08, Accepted throughput: 0.07 tokens/s, Drafted throughput: 0.19 tokens/s, Accepted: 27 tokens, Drafted: 75 tokens, Per-position acceptance rate: 0.640, 0.320, 0.120, Avg Draft acceptance rate: 36.0%
(APIServer pid=1) INFO:     172.18.0.2:38934 - "POST /v1/chat/completions HTTP/1.1" 200 OK
(APIServer pid=1) INFO:     172.18.0.2:38934 - "POST /v1/chat/completions HTTP/1.1" 200 OK
(Worker_TP0 pid=79) WARNING 07-05 09:03:09 [jit_monitor.py:103] Triton kernel JIT compilation during inference: _pack_topk_routes_prefix_kernel. This causes a latency spike; consider extending warmup to cover this shape/config.
(Worker_TP0 pid=79) WARNING 07-05 09:03:09 [jit_monitor.py:103] Triton kernel JIT compilation during inference: _pack_topk_routes_post_prefix_kernel. This causes a latency spike; consider extending warmup to cover this shape/config.
(APIServer pid=1) INFO:     172.18.0.2:38934 - "POST /v1/chat/completions HTTP/1.1" 200 OK
(APIServer pid=1) INFO 07-05 09:03:13 [loggers.py:271] Engine 000: Avg prompt throughput: 86.0 tokens/s, Avg generation throughput: 8.4 tokens/s, Running: 0 reqs, Waiting: 0 reqs, GPU KV cache usage: 0.4%, Prefix cache hit rate: 0.0%
(APIServer pid=1) INFO 07-05 09:03:13 [metrics.py:101] SpecDecoding metrics: Mean acceptance length: 2.71, Accepted throughput: 5.30 tokens/s, Drafted throughput: 9.30 tokens/s, Accepted: 53 tokens, Drafted: 93 tokens, Per-position acceptance rate: 0.774, 0.581, 0.355, Avg Draft acceptance rate: 57.0%
(APIServer pid=1) INFO 07-05 09:03:23 [loggers.py:271] Engine 000: Avg prompt throughput: 0.0 tokens/s, Avg generation throughput: 0.0 tokens/s, Running: 0 reqs, Waiting: 0 reqs, GPU KV cache usage: 0.4%, Prefix cache hit rate: 0.0%
(APIServer pid=1) INFO:     172.18.0.2:59406 - "POST /v1/chat/completions HTTP/1.1" 200 OK
(APIServer pid=1) INFO:     172.18.0.2:59406 - "POST /v1/chat/completions HTTP/1.1" 200 OK
(APIServer pid=1) INFO 07-05 09:03:33 [loggers.py:271] Engine 000: Avg prompt throughput: 15.2 tokens/s, Avg generation throughput: 11.3 tokens/s, Running: 0 reqs, Waiting: 0 reqs, GPU KV cache usage: 0.4%, Prefix cache hit rate: 20.0%
(APIServer pid=1) INFO 07-05 09:03:33 [metrics.py:101] SpecDecoding metrics: Mean acceptance length: 2.51, Accepted throughput: 3.40 tokens/s, Drafted throughput: 6.75 tokens/s, Accepted: 68 tokens, Drafted: 135 tokens, Per-position acceptance rate: 0.733, 0.489, 0.289, Avg Draft acceptance rate: 50.4%
(APIServer pid=1) INFO 07-05 09:03:43 [loggers.py:271] Engine 000: Avg prompt throughput: 0.0 tokens/s, Avg generation throughput: 0.0 tokens/s, Running: 0 reqs, Waiting: 0 reqs, GPU KV cache usage: 0.4%, Prefix cache hit rate: 20.0%
(APIServer pid=1) INFO:     172.18.0.3:43724 - "POST /v1/chat/completions HTTP/1.1" 200 OK
(APIServer pid=1) INFO:     172.18.0.3:54624 - "POST /v1/chat/completions HTTP/1.1" 200 OK
(APIServer pid=1) INFO 07-05 09:06:33 [loggers.py:271] Engine 000: Avg prompt throughput: 685.7 tokens/s, Avg generation throughput: 14.6 tokens/s, Running: 1 reqs, Waiting: 0 reqs, GPU KV cache usage: 1.1%, Prefix cache hit rate: 44.8%
(APIServer pid=1) INFO 07-05 09:06:33 [metrics.py:101] SpecDecoding metrics: Mean acceptance length: 3.43, Accepted throughput: 0.57 tokens/s, Drafted throughput: 0.70 tokens/s, Accepted: 102 tokens, Drafted: 126 tokens, Per-position acceptance rate: 0.905, 0.833, 0.690, Avg Draft acceptance rate: 81.0%
(APIServer pid=1) INFO 07-05 09:06:43 [loggers.py:271] Engine 000: Avg prompt throughput: 0.0 tokens/s, Avg generation throughput: 44.8 tokens/s, Running: 1 reqs, Waiting: 0 reqs, GPU KV cache usage: 1.1%, Prefix cache hit rate: 44.8%
(APIServer pid=1) INFO 07-05 09:06:43 [metrics.py:101] SpecDecoding metrics: Mean acceptance length: 3.20, Accepted throughput: 30.80 tokens/s, Drafted throughput: 42.00 tokens/s, Accepted: 308 tokens, Drafted: 420 tokens, Per-position acceptance rate: 0.900, 0.750, 0.550, Avg Draft acceptance rate: 73.3%
(APIServer pid=1) INFO:     172.18.0.3:48346 - "POST /v1/chat/completions HTTP/1.1" 200 OK
(APIServer pid=1) INFO 07-05 09:06:53 [loggers.py:271] Engine 000: Avg prompt throughput: 225.9 tokens/s, Avg generation throughput: 32.8 tokens/s, Running: 1 reqs, Waiting: 0 reqs, GPU KV cache usage: 1.5%, Prefix cache hit rate: 56.3%
(APIServer pid=1) INFO 07-05 09:06:53 [metrics.py:101] SpecDecoding metrics: Mean acceptance length: 3.04, Accepted throughput: 22.00 tokens/s, Drafted throughput: 32.40 tokens/s, Accepted: 220 tokens, Drafted: 324 tokens, Per-position acceptance rate: 0.843, 0.630, 0.565, Avg Draft acceptance rate: 67.9%
(APIServer pid=1) INFO:     172.18.0.3:40136 - "POST /v1/chat/completions HTTP/1.1" 200 OK
(APIServer pid=1) INFO 07-05 09:07:03 [loggers.py:271] Engine 000: Avg prompt throughput: 51.3 tokens/s, Avg generation throughput: 39.4 tokens/s, Running: 1 reqs, Waiting: 0 reqs, GPU KV cache usage: 1.7%, Prefix cache hit rate: 67.1%
(APIServer pid=1) INFO 07-05 09:07:03 [metrics.py:101] SpecDecoding metrics: Mean acceptance length: 3.23, Accepted throughput: 27.20 tokens/s, Drafted throughput: 36.60 tokens/s, Accepted: 272 tokens, Drafted: 366 tokens, Per-position acceptance rate: 0.918, 0.730, 0.582, Avg Draft acceptance rate: 74.3%
(APIServer pid=1) INFO:     172.18.0.3:44602 - "POST /v1/chat/completions HTTP/1.1" 200 OK
(APIServer pid=1) INFO 07-05 09:07:13 [loggers.py:271] Engine 000: Avg prompt throughput: 65.4 tokens/s, Avg generation throughput: 43.0 tokens/s, Running: 1 reqs, Waiting: 0 reqs, GPU KV cache usage: 2.0%, Prefix cache hit rate: 73.3%
(APIServer pid=1) INFO 07-05 09:07:13 [metrics.py:101] SpecDecoding metrics: Mean acceptance length: 3.36, Accepted throughput: 30.17 tokens/s, Drafted throughput: 38.36 tokens/s, Accepted: 302 tokens, Drafted: 384 tokens, Per-position acceptance rate: 0.906, 0.789, 0.664, Avg Draft acceptance rate: 78.6%
(APIServer pid=1) INFO:     172.18.0.3:35284 - "POST /v1/chat/completions HTTP/1.1" 200 OK
(APIServer pid=1) INFO 07-05 09:07:23 [loggers.py:271] Engine 000: Avg prompt throughput: 58.4 tokens/s, Avg generation throughput: 45.4 tokens/s, Running: 1 reqs, Waiting: 0 reqs, GPU KV cache usage: 2.2%, Prefix cache hit rate: 77.4%
(APIServer pid=1) INFO 07-05 09:07:23 [metrics.py:101] SpecDecoding metrics: Mean acceptance length: 3.60, Accepted throughput: 32.70 tokens/s, Drafted throughput: 37.80 tokens/s, Accepted: 327 tokens, Drafted: 378 tokens, Per-position acceptance rate: 0.929, 0.881, 0.786, Avg Draft acceptance rate: 86.5%
(APIServer pid=1) INFO 07-05 09:07:33 [loggers.py:271] Engine 000: Avg prompt throughput: 0.0 tokens/s, Avg generation throughput: 48.1 tokens/s, Running: 1 reqs, Waiting: 0 reqs, GPU KV cache usage: 2.2%, Prefix cache hit rate: 77.4%
(APIServer pid=1) INFO 07-05 09:07:33 [metrics.py:101] SpecDecoding metrics: Mean acceptance length: 3.44, Accepted throughput: 34.10 tokens/s, Drafted throughput: 41.99 tokens/s, Accepted: 341 tokens, Drafted: 420 tokens, Per-position acceptance rate: 0.914, 0.793, 0.729, Avg Draft acceptance rate: 81.2%
(APIServer pid=1) INFO:     172.18.0.3:34780 - "POST /v1/chat/completions HTTP/1.1" 200 OK
(APIServer pid=1) INFO 07-05 09:07:43 [loggers.py:271] Engine 000: Avg prompt throughput: 79.6 tokens/s, Avg generation throughput: 43.2 tokens/s, Running: 1 reqs, Waiting: 0 reqs, GPU KV cache usage: 2.4%, Prefix cache hit rate: 80.1%
(APIServer pid=1) INFO 07-05 09:07:43 [metrics.py:101] SpecDecoding metrics: Mean acceptance length: 3.46, Accepted throughput: 30.70 tokens/s, Drafted throughput: 37.50 tokens/s, Accepted: 307 tokens, Drafted: 375 tokens, Per-position acceptance rate: 0.920, 0.824, 0.712, Avg Draft acceptance rate: 81.9%
(APIServer pid=1) INFO:     172.18.0.3:58268 - "POST /v1/chat/completions HTTP/1.1" 200 OK
(APIServer pid=1) INFO 07-05 09:07:53 [loggers.py:271] Engine 000: Avg prompt throughput: 56.5 tokens/s, Avg generation throughput: 45.7 tokens/s, Running: 1 reqs, Waiting: 0 reqs, GPU KV cache usage: 2.5%, Prefix cache hit rate: 82.4%
(APIServer pid=1) INFO 07-05 09:07:53 [metrics.py:101] SpecDecoding metrics: Mean acceptance length: 3.62, Accepted throughput: 33.00 tokens/s, Drafted throughput: 37.80 tokens/s, Accepted: 330 tokens, Drafted: 378 tokens, Per-position acceptance rate: 0.952, 0.889, 0.778, Avg Draft acceptance rate: 87.3%
(APIServer pid=1) INFO:     172.18.0.3:37068 - "POST /v1/chat/completions HTTP/1.1" 200 OK
(APIServer pid=1) INFO 07-05 09:08:03 [loggers.py:271] Engine 000: Avg prompt throughput: 45.1 tokens/s, Avg generation throughput: 43.6 tokens/s, Running: 1 reqs, Waiting: 0 reqs, GPU KV cache usage: 2.9%, Prefix cache hit rate: 84.3%
(APIServer pid=1) INFO 07-05 09:08:03 [metrics.py:101] SpecDecoding metrics: Mean acceptance length: 3.40, Accepted throughput: 30.70 tokens/s, Drafted throughput: 38.40 tokens/s, Accepted: 307 tokens, Drafted: 384 tokens, Per-position acceptance rate: 0.914, 0.789, 0.695, Avg Draft acceptance rate: 79.9%
(APIServer pid=1) INFO:     172.18.0.3:59158 - "POST /v1/chat/completions HTTP/1.1" 200 OK
(APIServer pid=1) INFO 07-05 09:08:13 [loggers.py:271] Engine 000: Avg prompt throughput: 75.2 tokens/s, Avg generation throughput: 43.1 tokens/s, Running: 1 reqs, Waiting: 0 reqs, GPU KV cache usage: 3.4%, Prefix cache hit rate: 85.5%
(APIServer pid=1) INFO 07-05 09:08:13 [metrics.py:101] SpecDecoding metrics: Mean acceptance length: 3.47, Accepted throughput: 30.60 tokens/s, Drafted throughput: 37.20 tokens/s, Accepted: 306 tokens, Drafted: 372 tokens, Per-position acceptance rate: 0.919, 0.847, 0.702, Avg Draft acceptance rate: 82.3%
(APIServer pid=1) INFO 07-05 09:08:23 [loggers.py:271] Engine 000: Avg prompt throughput: 0.0 tokens/s, Avg generation throughput: 46.5 tokens/s, Running: 1 reqs, Waiting: 0 reqs, GPU KV cache usage: 3.4%, Prefix cache hit rate: 85.5%
(APIServer pid=1) INFO 07-05 09:08:23 [metrics.py:101] SpecDecoding metrics: Mean acceptance length: 3.42, Accepted throughput: 32.90 tokens/s, Drafted throughput: 40.80 tokens/s, Accepted: 329 tokens, Drafted: 408 tokens, Per-position acceptance rate: 0.897, 0.816, 0.706, Avg Draft acceptance rate: 80.6%
(APIServer pid=1) INFO:     172.18.0.3:48592 - "POST /v1/chat/completions HTTP/1.1" 200 OK
(APIServer pid=1) INFO 07-05 09:08:33 [loggers.py:271] Engine 000: Avg prompt throughput: 87.7 tokens/s, Avg generation throughput: 39.2 tokens/s, Running: 1 reqs, Waiting: 0 reqs, GPU KV cache usage: 3.6%, Prefix cache hit rate: 86.4%
(APIServer pid=1) INFO 07-05 09:08:33 [metrics.py:101] SpecDecoding metrics: Mean acceptance length: 3.15, Accepted throughput: 26.70 tokens/s, Drafted throughput: 37.20 tokens/s, Accepted: 267 tokens, Drafted: 372 tokens, Per-position acceptance rate: 0.895, 0.702, 0.556, Avg Draft acceptance rate: 71.8%
(APIServer pid=1) INFO:     172.18.0.3:43858 - "POST /v1/chat/completions HTTP/1.1" 200 OK
(APIServer pid=1) INFO 07-05 09:08:43 [loggers.py:271] Engine 000: Avg prompt throughput: 64.1 tokens/s, Avg generation throughput: 39.9 tokens/s, Running: 1 reqs, Waiting: 0 reqs, GPU KV cache usage: 3.9%, Prefix cache hit rate: 87.4%
(APIServer pid=1) INFO 07-05 09:08:43 [metrics.py:101] SpecDecoding metrics: Mean acceptance length: 3.18, Accepted throughput: 27.30 tokens/s, Drafted throughput: 37.50 tokens/s, Accepted: 273 tokens, Drafted: 375 tokens, Per-position acceptance rate: 0.864, 0.744, 0.576, Avg Draft acceptance rate: 72.8%
(APIServer pid=1) INFO 07-05 09:08:53 [loggers.py:271] Engine 000: Avg prompt throughput: 0.0 tokens/s, Avg generation throughput: 48.2 tokens/s, Running: 1 reqs, Waiting: 0 reqs, GPU KV cache usage: 3.9%, Prefix cache hit rate: 87.4%
(APIServer pid=1) INFO 07-05 09:08:53 [metrics.py:101] SpecDecoding metrics: Mean acceptance length: 3.45, Accepted throughput: 34.20 tokens/s, Drafted throughput: 41.88 tokens/s, Accepted: 343 tokens, Drafted: 420 tokens, Per-position acceptance rate: 0.950, 0.829, 0.671, Avg Draft acceptance rate: 81.7%
(APIServer pid=1) INFO:     172.18.0.3:56288 - "POST /v1/chat/completions HTTP/1.1" 200 OK
(APIServer pid=1) INFO 07-05 09:09:03 [loggers.py:271] Engine 000: Avg prompt throughput: 108.1 tokens/s, Avg generation throughput: 43.4 tokens/s, Running: 1 reqs, Waiting: 0 reqs, GPU KV cache usage: 4.1%, Prefix cache hit rate: 87.9%
(APIServer pid=1) INFO 07-05 09:09:03 [metrics.py:101] SpecDecoding metrics: Mean acceptance length: 3.55, Accepted throughput: 31.10 tokens/s, Drafted throughput: 36.60 tokens/s, Accepted: 311 tokens, Drafted: 366 tokens, Per-position acceptance rate: 0.943, 0.852, 0.754, Avg Draft acceptance rate: 85.0%
(APIServer pid=1) INFO:     172.18.0.3:37560 - "POST /v1/chat/completions HTTP/1.1" 200 OK
(APIServer pid=1) INFO 07-05 09:09:13 [loggers.py:271] Engine 000: Avg prompt throughput: 65.6 tokens/s, Avg generation throughput: 43.4 tokens/s, Running: 1 reqs, Waiting: 0 reqs, GPU KV cache usage: 4.4%, Prefix cache hit rate: 88.7%
(APIServer pid=1) INFO 07-05 09:09:13 [metrics.py:101] SpecDecoding metrics: Mean acceptance length: 3.44, Accepted throughput: 30.70 tokens/s, Drafted throughput: 37.80 tokens/s, Accepted: 307 tokens, Drafted: 378 tokens, Per-position acceptance rate: 0.929, 0.810, 0.698, Avg Draft acceptance rate: 81.2%
(APIServer pid=1) INFO 07-05 09:09:23 [loggers.py:271] Engine 000: Avg prompt throughput: 0.0 tokens/s, Avg generation throughput: 37.8 tokens/s, Running: 1 reqs, Waiting: 0 reqs, GPU KV cache usage: 4.4%, Prefix cache hit rate: 88.7%
(APIServer pid=1) INFO 07-05 09:09:23 [metrics.py:101] SpecDecoding metrics: Mean acceptance length: 2.74, Accepted throughput: 24.00 tokens/s, Drafted throughput: 41.40 tokens/s, Accepted: 240 tokens, Drafted: 414 tokens, Per-position acceptance rate: 0.797, 0.543, 0.399, Avg Draft acceptance rate: 58.0%
(APIServer pid=1) INFO 07-05 09:09:33 [loggers.py:271] Engine 000: Avg prompt throughput: 0.0 tokens/s, Avg generation throughput: 29.3 tokens/s, Running: 1 reqs, Waiting: 0 reqs, GPU KV cache usage: 4.4%, Prefix cache hit rate: 88.7%
(APIServer pid=1) INFO 07-05 09:09:33 [metrics.py:101] SpecDecoding metrics: Mean acceptance length: 2.15, Accepted throughput: 15.70 tokens/s, Drafted throughput: 40.79 tokens/s, Accepted: 157 tokens, Drafted: 408 tokens, Per-position acceptance rate: 0.618, 0.309, 0.228, Avg Draft acceptance rate: 38.5%
(APIServer pid=1) INFO 07-05 09:09:43 [loggers.py:271] Engine 000: Avg prompt throughput: 0.0 tokens/s, Avg generation throughput: 31.6 tokens/s, Running: 1 reqs, Waiting: 0 reqs, GPU KV cache usage: 4.4%, Prefix cache hit rate: 88.7%
(APIServer pid=1) INFO 07-05 09:09:43 [metrics.py:101] SpecDecoding metrics: Mean acceptance length: 2.29, Accepted throughput: 17.80 tokens/s, Drafted throughput: 41.40 tokens/s, Accepted: 178 tokens, Drafted: 414 tokens, Per-position acceptance rate: 0.645, 0.384, 0.261, Avg Draft acceptance rate: 43.0%
(APIServer pid=1) INFO:     172.18.0.3:52976 - "POST /v1/chat/completions HTTP/1.1" 200 OK
(APIServer pid=1) INFO:     172.18.0.3:33930 - "POST /v1/chat/completions HTTP/1.1" 200 OK
(APIServer pid=1) INFO 07-05 09:09:53 [loggers.py:271] Engine 000: Avg prompt throughput: 169.6 tokens/s, Avg generation throughput: 33.1 tokens/s, Running: 1 reqs, Waiting: 0 reqs, GPU KV cache usage: 5.2%, Prefix cache hit rate: 89.8%
(APIServer pid=1) INFO 07-05 09:09:53 [metrics.py:101] SpecDecoding metrics: Mean acceptance length: 3.06, Accepted throughput: 22.30 tokens/s, Drafted throughput: 32.40 tokens/s, Accepted: 223 tokens, Drafted: 324 tokens, Per-position acceptance rate: 0.843, 0.657, 0.565, Avg Draft acceptance rate: 68.8%
(APIServer pid=1) INFO 07-05 09:10:03 [loggers.py:271] Engine 000: Avg prompt throughput: 0.0 tokens/s, Avg generation throughput: 5.4 tokens/s, Running: 0 reqs, Waiting: 0 reqs, GPU KV cache usage: 5.1%, Prefix cache hit rate: 89.8%
(APIServer pid=1) INFO 07-05 09:10:03 [metrics.py:101] SpecDecoding metrics: Mean acceptance length: 2.50, Accepted throughput: 3.30 tokens/s, Drafted throughput: 6.60 tokens/s, Accepted: 33 tokens, Drafted: 66 tokens, Per-position acceptance rate: 0.682, 0.545, 0.273, Avg Draft acceptance rate: 50.0%
(APIServer pid=1) INFO 07-05 09:10:13 [loggers.py:271] Engine 000: Avg prompt throughput: 0.0 tokens/s, Avg generation throughput: 0.0 tokens/s, Running: 0 reqs, Waiting: 0 reqs, GPU KV cache usage: 5.1%, Prefix cache hit rate: 89.8%
```
