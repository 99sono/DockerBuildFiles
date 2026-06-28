# docker compose
```yml
services:
  deepseek-v4-flash-head:
    image: aidendle94/sparkrun-vllm-ds4-gb10:production-ready
    container_name: deepseek-v4-flash-head
    hostname: inference-server
    network_mode: "host"
    privileged: true
    ipc: "host"
    shm_size: "10g"
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
      NCCL_IB_DISABLE: "0"
      NCCL_IB_HCA: "${NCCL_IB_HCA:-rocep1s0f0,roceP2p1s0f0}"
      NCCL_IB_GID_INDEX: "${NCCL_IB_GID_INDEX:-4,4}"
      NCCL_SOCKET_IFNAME: "${NCCL_SOCKET_IFNAME:-enP7s7}"
      GLOO_SOCKET_IFNAME: "${GLOO_SOCKET_IFNAME:-enP7s7}"
      TP_SOCKET_IFNAME: "${TP_SOCKET_IFNAME:-enP7s7}"
      NCCL_IGNORE_CPU_AFFINITY: "1"
      NCCL_DEBUG: "WARN"
      TORCH_CUDA_ARCH_LIST: "12.1a"
      FLASHINFER_CUDA_ARCH_LIST: "12.1a"
      VLLM_ALLOW_LONG_MAX_MODEL_LEN: "1"
      VLLM_USE_B12X_MOE: "1"
      VLLM_SPARSE_INDEXER_MAX_LOGITS_MB: "256"
      CUDA_VISIBLE_DEVICES: "0"
      HF_HOME: /cache/huggingface
      HF_HUB_OFFLINE: "1"
      VLLM_CACHE_ROOT: /cache/huggingface/vllm-cache

    command:
      - "vllm"
      - "serve"
      - "deepseek-ai/DeepSeek-V4-Flash"
      - "--served-model-name"
      - "${INFERENCE_MODEL_ALIAS:-deepseek-v4-flash}"
      - "--api-key"
      - "${INFERENCE_API_KEY:-dummy-key}"
      - "--host"
      - "0.0.0.0"
      - "--port"
      - "8000"
      - "--trust-remote-code"
      - "--tensor-parallel-size"
      - "2"
      - "--pipeline-parallel-size"
      - "1"
      - "--kv-cache-dtype"
      - "fp8"
      - "--block-size"
      - "256"
      - "--max-model-len"
      - "200000"
      - "--max-num-seqs"
      - "4"
      - "--max-num-batched-tokens"
      - "8192"
      - "--gpu-memory-utilization"
      - "0.8"
      - "--enable-prefix-caching"
      - "--speculative-config"
      - '{"method":"mtp","num_speculative_tokens":2}'
      - "--tokenizer-mode"
      - "deepseek_v4"
      - "--distributed-executor-backend"
      - "mp"
      - "--tool-call-parser"
      - "deepseek_v4"
      - "--enable-auto-tool-choice"
      - "--reasoning-parser"
      - "deepseek_v4"
      - "--enable-flashinfer-autotune"
      - "--nnodes"
      - "2"
      - "--node-rank"
      - "0"
      - "--master-addr"
      - "${MASTER_ADDR:-10.0.1.1}"
      - "--master-port"
      - "29501"


```
# Vllm log
```log
(APIServer pid=1) INFO 06-21 07:16:52 [utils.py:344] 
(APIServer pid=1) INFO 06-21 07:16:52 [utils.py:344]        █     █     █▄   ▄█
(APIServer pid=1) INFO 06-21 07:16:52 [utils.py:344]  ▄▄ ▄█ █     █     █ ▀▄▀ █  version 0.21.1rc1.dev339+g1967a5627bc3
(APIServer pid=1) INFO 06-21 07:16:52 [utils.py:344]   █▄█▀ █     █     █     █  model   deepseek-ai/DeepSeek-V4-Flash
(APIServer pid=1) INFO 06-21 07:16:52 [utils.py:344]    ▀▀  ▀▀▀▀▀ ▀▀▀▀▀ ▀     ▀
(APIServer pid=1) INFO 06-21 07:16:52 [utils.py:344] 
(APIServer pid=1) INFO 06-21 07:16:52 [utils.py:278] non-default args: {'model_tag': 'deepseek-ai/DeepSeek-V4-Flash', 'enable_auto_tool_choice': True, 'tool_call_parser': 'deepseek_v4', 'host': '0.0.0.0', 'api_key': ['dummy-key'], 'model': 'deepseek-ai/DeepSeek-V4-Flash', 'tokenizer_mode': 'deepseek_v4', 'trust_remote_code': True, 'max_model_len': 200000, 'served_model_name': ['deepseek-v4-flash'], 'reasoning_parser': 'deepseek_v4', 'distributed_executor_backend': 'mp', 'master_addr': '10.0.1.1', 'nnodes': 2, 'tensor_parallel_size': 2, 'block_size': 256, 'gpu_memory_utilization': 0.8, 'kv_cache_dtype': 'fp8', 'enable_prefix_caching': True, 'max_num_batched_tokens': 8192, 'max_num_seqs': 4, 'enable_flashinfer_autotune': True, 'speculative_config': {'method': 'mtp', 'num_speculative_tokens': 2}}
(APIServer pid=1) INFO 06-21 07:16:52 [arg_utils.py:753] HF_HUB_OFFLINE is True, replace model_id [deepseek-ai/DeepSeek-V4-Flash] to model_path [/cache/huggingface/hub/models--deepseek-ai--DeepSeek-V4-Flash/snapshots/553034d7dd9e06c2eeaee68cf85a17d6d4754cf0]
(APIServer pid=1) INFO 06-21 07:16:52 [config.py:801] Detected quantization_config.scale_fmt=ue8m0; enabling UE8M0 for DeepGEMM.
(APIServer pid=1) INFO 06-21 07:16:52 [model.py:617] Resolved architecture: DeepseekV4ForCausalLM
(APIServer pid=1) INFO 06-21 07:16:52 [model.py:1752] Using max model len 200000
(APIServer pid=1) INFO 06-21 07:16:53 [cache.py:261] Using fp8 data type to store kv cache. It reduces the GPU memory footprint and boosts the performance. Meanwhile, it may cause accuracy drop without a proper scaling factor
(APIServer pid=1) INFO 06-21 07:16:53 [arg_utils.py:1905] Inferred data_parallel_rank 0 from node_rank 0
(APIServer pid=1) INFO 06-21 07:16:53 [model.py:617] Resolved architecture: DeepSeekV4MTPModel
(APIServer pid=1) INFO 06-21 07:16:53 [model.py:1752] Using max model len 1048576
(APIServer pid=1) WARNING 06-21 07:16:53 [speculative.py:709] Enabling num_speculative_tokens > 1 will run multiple times of forward on same MTP layer,which may result in lower acceptance rate
(APIServer pid=1) INFO 06-21 07:16:53 [speculative.py:882] Overriding draft model max model len from 1048576 to 200000
(APIServer pid=1) INFO 06-21 07:16:53 [scheduler.py:239] Chunked prefill is enabled with max_num_batched_tokens=8192.
(APIServer pid=1) INFO 06-21 07:16:53 [vllm.py:977] Asynchronous scheduling is enabled.
(APIServer pid=1) INFO 06-21 07:16:53 [kernel.py:274] Final IR op priority after setting platform defaults: IrOpPriorityConfig(rms_norm=['native'], fused_add_rms_norm=['native'])
(APIServer pid=1) WARNING 06-21 07:16:53 [vllm.py:1396] Auto-initialization of reasoning token IDs failed. Please check whether your reasoning parser has implemented the `reasoning_start_str` and `reasoning_end_str`.
(APIServer pid=1) INFO 06-21 07:16:53 [compilation.py:321] Enabled custom fusions: norm_quant, act_quant
(EngineCore pid=34) INFO 06-21 07:16:57 [core.py:112] Initializing a V1 LLM engine (v0.21.1rc1.dev339+g1967a5627bc3) with config: model='/cache/huggingface/hub/models--deepseek-ai--DeepSeek-V4-Flash/snapshots/553034d7dd9e06c2eeaee68cf85a17d6d4754cf0', speculative_config=SpeculativeConfig(method='mtp', model='/cache/huggingface/hub/models--deepseek-ai--DeepSeek-V4-Flash/snapshots/553034d7dd9e06c2eeaee68cf85a17d6d4754cf0', num_spec_tokens=2), tokenizer='/cache/huggingface/hub/models--deepseek-ai--DeepSeek-V4-Flash/snapshots/553034d7dd9e06c2eeaee68cf85a17d6d4754cf0', skip_tokenizer_init=False, tokenizer_mode=deepseek_v4, revision=None, tokenizer_revision=None, trust_remote_code=True, dtype=torch.bfloat16, max_seq_len=200000, download_dir=None, load_format=auto, tensor_parallel_size=2, pipeline_parallel_size=1, data_parallel_size=1, decode_context_parallel_size=1, dcp_comm_backend=ag_rs, disable_custom_all_reduce=True, quantization=deepseek_v4_fp8, quantization_config=None, enforce_eager=False, enable_return_routed_experts=False, kv_cache_dtype=fp8, device_config=cuda, structured_outputs_config=StructuredOutputsConfig(backend='auto', disable_any_whitespace=False, disable_additional_properties=False, reasoning_parser='deepseek_v4', reasoning_parser_plugin='', enable_in_reasoning=False), observability_config=ObservabilityConfig(show_hidden_metrics_for_version=None, otlp_traces_endpoint=None, collect_detailed_traces=None, kv_cache_metrics=False, kv_cache_metrics_sample=0.01, cudagraph_metrics=False, enable_layerwise_nvtx_tracing=False, enable_mfu_metrics=False, enable_mm_processor_stats=False, enable_logging_iteration_details=False), seed=0, served_model_name=deepseek-v4-flash, enable_prefix_caching=True, enable_chunked_prefill=True, pooler_config=None, compilation_config={'mode': <CompilationMode.VLLM_COMPILE: 3>, 'debug_dump_path': None, 'cache_dir': '', 'compile_cache_save_format': 'binary', 'backend': 'inductor', 'custom_ops': ['+quant_fp8', 'none', '+quant_fp8'], 'ir_enable_torch_wrap': True, 'splitting_ops': ['vllm::unified_attention_with_output', 'vllm::unified_mla_attention_with_output', 'vllm::mamba_mixer2', 'vllm::mamba_mixer', 'vllm::short_conv', 'vllm::linear_attention', 'vllm::plamo2_mamba_mixer', 'vllm::qwen_gdn_attention_core', 'vllm::gdn_attention_core_xpu', 'vllm::olmo_hybrid_gdn_full_forward', 'vllm::kda_attention', 'vllm::sparse_attn_indexer', 'vllm::rocm_aiter_sparse_attn_indexer', 'vllm::deepseek_v4_attention', 'vllm::unified_kv_cache_update', 'vllm::unified_mla_kv_cache_update'], 'compile_mm_encoder': False, 'cudagraph_mm_encoder': False, 'encoder_cudagraph_token_budgets': [], 'encoder_cudagraph_max_vision_items_per_batch': 0, 'encoder_cudagraph_max_frames_per_batch': None, 'compile_sizes': [], 'compile_ranges_endpoints': [8192], 'inductor_compile_config': {'enable_auto_functionalized_v2': False, 'size_asserts': False, 'alignment_asserts': False, 'scalar_asserts': False, 'combo_kernels': True, 'benchmark_combo_kernel': True}, 'inductor_passes': {}, 'cudagraph_mode': <CUDAGraphMode.FULL_AND_PIECEWISE: (2, 1)>, 'cudagraph_num_of_warmups': 1, 'cudagraph_capture_sizes': [1, 2, 4, 8, 16, 24], 'cudagraph_copy_inputs': False, 'cudagraph_specialize_lora': True, 'use_inductor_graph_partition': False, 'pass_config': {'fuse_norm_quant': True, 'fuse_act_quant': True, 'fuse_attn_quant': False, 'enable_sp': False, 'fuse_gemm_comms': False, 'fuse_allreduce_rms': False, 'fuse_rope_kvcache_cat_mla': False, 'fuse_act_padding': False}, 'max_cudagraph_capture_size': 24, 'dynamic_shapes_config': {'type': <DynamicShapesType.BACKED: 'backed'>, 'evaluate_guards': False, 'assume_32_bit_indexing': False}, 'local_cache_dir': None, 'fast_moe_cold_start': False, 'static_all_moe_layers': []}, kernel_config=KernelConfig(ir_op_priority=IrOpPriorityConfig(rms_norm=['native'], fused_add_rms_norm=['native']), enable_flashinfer_autotune=True, moe_backend='auto', linear_backend='auto')
(EngineCore pid=34) INFO 06-21 07:16:57 [multiproc_executor.py:139] DP group leader: node_rank=0, node_rank_within_dp=0, master_addr=10.0.1.1, mq_connect_ip=192.168.1.55 (local), world_size=2, local_world_size=1
(Worker pid=57) INFO 06-21 07:17:00 [parallel_state.py:1422] world_size=2 rank=0 local_rank=0 distributed_init_method=tcp://10.0.1.1:29501 backend=nccl
(Worker pid=57) INFO 06-21 07:17:01 [nccl.py:24] Found nccl from environment variable VLLM_NCCL_SO_PATH=/opt/env/lib/python3.12/site-packages/nvidia/nccl/lib/libnccl.so.2
(Worker pid=57) INFO 06-21 07:17:01 [pynccl.py:113] vLLM is using nccl==2.30.4
(Worker pid=57) WARNING 06-21 07:17:02 [symm_mem.py:66] SymmMemCommunicator: Device capability 12.1 not supported, communicator is not available.
(Worker pid=57) INFO 06-21 07:17:02 [cuda_communicator.py:233] Using ['PYNCCL'] all-reduce backends (in dispatch order) for group 'tp:0' out of potential backends: ['NCCL_SYMM_MEM', 'QUICK_REDUCE', 'FLASHINFER', 'CUSTOM', 'SYMM_MEM', 'PYNCCL'].
(Worker pid=57) INFO 06-21 07:17:02 [nccl.py:24] Found nccl from environment variable VLLM_NCCL_SO_PATH=/opt/env/lib/python3.12/site-packages/nvidia/nccl/lib/libnccl.so.2
(Worker pid=57) INFO 06-21 07:17:03 [cuda_communicator.py:233] Using ['PYNCCL'] all-reduce backends (in dispatch order) for group 'ep:0' out of potential backends: ['NCCL_SYMM_MEM', 'QUICK_REDUCE', 'FLASHINFER', 'CUSTOM', 'SYMM_MEM', 'PYNCCL'].
(Worker pid=57) INFO 06-21 07:17:03 [parallel_state.py:1735] rank 0 in world size 2 is assigned as DP rank 0, PP rank 0, PCP rank 0, TP rank 0, EP rank 0, EPLB rank N/A
(Worker pid=57) INFO 06-21 07:17:03 [topk_topp_sampler.py:45] Using FlashInfer for top-p & top-k sampling.
(Worker pid=57) WARNING 06-21 07:17:03 [__init__.py:204] min_p and logit_bias parameters won't work with speculative decoding.
(Worker_TP0 pid=57) INFO 06-21 07:17:03 [gpu_model_runner.py:5037] Starting to load model /cache/huggingface/hub/models--deepseek-ai--DeepSeek-V4-Flash/snapshots/553034d7dd9e06c2eeaee68cf85a17d6d4754cf0...
(Worker_TP0 pid=57) INFO 06-21 07:17:03 [quant_config.py:73] DeepSeek V4 expert_dtype resolved to 'fp4'
(Worker_TP0 pid=57) INFO 06-21 07:17:03 [__init__.py:550] Selected DeepGemmFp8BlockScaledMMKernel for Fp8LinearMethod
(Worker_TP0 pid=57) INFO 06-21 07:17:03 [deep_gemm.py:117] DeepGEMM E8M0 enabled on current platform.
(Worker_TP0 pid=57) INFO 06-21 07:17:03 [attention.py:923] Using DeepSeek's fp8_ds_mla KV cache format.
(Worker_TP0 pid=57) INFO 06-21 07:17:03 [mxfp4.py:389] Using 'B12X' Mxfp4 MoE backend.
(Worker_TP0 pid=57) INFO 06-21 07:17:03 [attention.py:1032] Using FP8 indexer cache for Lightning Indexer.
(Worker_TP0 pid=57) INFO 06-21 07:17:07 [weight_utils.py:922] Filesystem type for checkpoints: EXT4. Checkpoint size: 148.66 GiB. Available RAM: 37.98 GiB.
(Worker_TP0 pid=57) INFO 06-21 07:17:07 [weight_utils.py:952] Auto-prefetch is disabled because the filesystem (EXT4) is not a recognized network FS (NFS/Lustre) and the checkpoint size (148.66 GiB) exceeds 90% of available RAM (37.98 GiB).
(Worker_TP0 pid=57) Loading safetensors checkpoint shards:   0% Completed | 0/46 [00:00<?, ?it/s]
(Worker_TP0 pid=57) Loading safetensors checkpoint shards:   2% Completed | 1/46 [00:04<03:07,  4.16s/it]
(Worker_TP0 pid=57) Loading safetensors checkpoint shards:   4% Completed | 2/46 [00:06<02:15,  3.07s/it]
(Worker_TP0 pid=57) Loading safetensors checkpoint shards:   7% Completed | 3/46 [00:08<01:57,  2.72s/it]
(Worker_TP0 pid=57) Loading safetensors checkpoint shards:   9% Completed | 4/46 [00:11<01:48,  2.59s/it]
(Worker_TP0 pid=57) Loading safetensors checkpoint shards:  11% Completed | 5/46 [00:13<01:46,  2.60s/it]
(Worker_TP0 pid=57) Loading safetensors checkpoint shards:  13% Completed | 6/46 [00:16<01:44,  2.62s/it]
(Worker_TP0 pid=57) Loading safetensors checkpoint shards:  15% Completed | 7/46 [00:19<01:41,  2.61s/it]
(Worker_TP0 pid=57) Loading safetensors checkpoint shards:  17% Completed | 8/46 [00:21<01:41,  2.68s/it]
(Worker_TP0 pid=57) Loading safetensors checkpoint shards:  20% Completed | 9/46 [00:24<01:38,  2.66s/it]
(Worker_TP0 pid=57) Loading safetensors checkpoint shards:  22% Completed | 10/46 [00:27<01:37,  2.70s/it]
(Worker_TP0 pid=57) Loading safetensors checkpoint shards:  24% Completed | 11/46 [00:29<01:33,  2.67s/it]
(Worker_TP0 pid=57) Loading safetensors checkpoint shards:  26% Completed | 12/46 [00:32<01:31,  2.70s/it]
(Worker_TP0 pid=57) Loading safetensors checkpoint shards:  28% Completed | 13/46 [00:35<01:30,  2.73s/it]
(Worker_TP0 pid=57) Loading safetensors checkpoint shards:  30% Completed | 14/46 [00:38<01:28,  2.75s/it]
(Worker_TP0 pid=57) Loading safetensors checkpoint shards:  33% Completed | 15/46 [00:41<01:25,  2.76s/it]
(Worker_TP0 pid=57) Loading safetensors checkpoint shards:  35% Completed | 16/46 [00:43<01:23,  2.80s/it]
(Worker_TP0 pid=57) Loading safetensors checkpoint shards:  37% Completed | 17/46 [00:46<01:23,  2.87s/it]
(Worker_TP0 pid=57) Loading safetensors checkpoint shards:  39% Completed | 18/46 [00:50<01:26,  3.09s/it]
(Worker_TP0 pid=57) Loading safetensors checkpoint shards:  41% Completed | 19/46 [00:54<01:30,  3.34s/it]
(Worker_TP0 pid=57) Loading safetensors checkpoint shards:  43% Completed | 20/46 [00:57<01:26,  3.33s/it]
(Worker_TP0 pid=57) Loading safetensors checkpoint shards:  46% Completed | 21/46 [01:01<01:23,  3.35s/it]
(Worker_TP0 pid=57) Loading safetensors checkpoint shards:  48% Completed | 22/46 [01:04<01:21,  3.40s/it]
(Worker_TP0 pid=57) Loading safetensors checkpoint shards:  50% Completed | 23/46 [01:08<01:18,  3.40s/it]
(Worker_TP0 pid=57) Loading safetensors checkpoint shards:  52% Completed | 24/46 [01:11<01:15,  3.45s/it]
(Worker_TP0 pid=57) Loading safetensors checkpoint shards:  54% Completed | 25/46 [01:14<01:11,  3.41s/it]
(Worker_TP0 pid=57) Loading safetensors checkpoint shards:  57% Completed | 26/46 [01:18<01:09,  3.50s/it]
(Worker_TP0 pid=57) Loading safetensors checkpoint shards:  59% Completed | 27/46 [01:22<01:06,  3.52s/it]
(Worker_TP0 pid=57) Loading safetensors checkpoint shards:  61% Completed | 28/46 [01:26<01:04,  3.61s/it]
(Worker_TP0 pid=57) Loading safetensors checkpoint shards:  63% Completed | 29/46 [01:29<01:00,  3.58s/it]
(Worker_TP0 pid=57) Loading safetensors checkpoint shards:  65% Completed | 30/46 [01:33<00:57,  3.59s/it]
(Worker_TP0 pid=57) Loading safetensors checkpoint shards:  67% Completed | 31/46 [01:36<00:53,  3.58s/it]
(Worker_TP0 pid=57) Loading safetensors checkpoint shards:  70% Completed | 32/46 [01:40<00:50,  3.62s/it]
(Worker_TP0 pid=57) Loading safetensors checkpoint shards:  72% Completed | 33/46 [01:44<00:46,  3.60s/it]
(Worker_TP0 pid=57) Loading safetensors checkpoint shards:  74% Completed | 34/46 [01:47<00:43,  3.59s/it]
(Worker_TP0 pid=57) Loading safetensors checkpoint shards:  76% Completed | 35/46 [01:51<00:39,  3.61s/it]
(Worker_TP0 pid=57) Loading safetensors checkpoint shards:  78% Completed | 36/46 [01:55<00:37,  3.75s/it]
(Worker_TP0 pid=57) Loading safetensors checkpoint shards:  80% Completed | 37/46 [01:59<00:33,  3.73s/it]
(Worker_TP0 pid=57) Loading safetensors checkpoint shards:  83% Completed | 38/46 [02:02<00:30,  3.78s/it]
(Worker_TP0 pid=57) Loading safetensors checkpoint shards:  85% Completed | 39/46 [02:06<00:26,  3.74s/it]
(Worker_TP0 pid=57) Loading safetensors checkpoint shards:  87% Completed | 40/46 [02:10<00:22,  3.80s/it]
(Worker_TP0 pid=57) Loading safetensors checkpoint shards:  89% Completed | 41/46 [02:14<00:18,  3.77s/it]
(Worker_TP0 pid=57) Loading safetensors checkpoint shards:  91% Completed | 42/46 [02:18<00:15,  3.82s/it]
(Worker_TP0 pid=57) Loading safetensors checkpoint shards:  93% Completed | 43/46 [02:21<00:11,  3.83s/it]
(Worker_TP0 pid=57) Loading safetensors checkpoint shards:  96% Completed | 44/46 [02:25<00:07,  3.86s/it]
(Worker_TP0 pid=57) Loading safetensors checkpoint shards:  98% Completed | 45/46 [02:26<00:02,  2.84s/it]
(Worker_TP0 pid=57) Loading safetensors checkpoint shards: 100% Completed | 46/46 [02:26<00:00,  2.12s/it]
(Worker_TP0 pid=57) Loading safetensors checkpoint shards: 100% Completed | 46/46 [02:26<00:00,  3.19s/it]
(Worker_TP0 pid=57) 
(Worker_TP0 pid=57) INFO 06-21 07:19:33 [default_loader.py:397] Loading weights took 146.88 seconds
(Worker_TP0 pid=57) INFO 06-21 07:19:34 [mxfp4.py:1789] Using MoEPrepareAndFinalizeNoDPEPModular
(Worker_TP0 pid=57) INFO 06-21 07:19:46 [gpu_model_runner.py:5061] Loading drafter model...
(Worker_TP0 pid=57) INFO 06-21 07:19:46 [vllm.py:977] Asynchronous scheduling is enabled.
(Worker_TP0 pid=57) INFO 06-21 07:19:46 [kernel.py:274] Final IR op priority after setting platform defaults: IrOpPriorityConfig(rms_norm=['native'], fused_add_rms_norm=['native'])
(Worker_TP0 pid=57) WARNING 06-21 07:19:47 [vllm.py:1396] Auto-initialization of reasoning token IDs failed. Please check whether your reasoning parser has implemented the `reasoning_start_str` and `reasoning_end_str`.
(Worker_TP0 pid=57) INFO 06-21 07:19:47 [compilation.py:321] Enabled custom fusions: norm_quant, act_quant
(Worker_TP0 pid=57) INFO 06-21 07:19:47 [kernel.py:274] Final IR op priority after setting platform defaults: IrOpPriorityConfig(rms_norm=['native'], fused_add_rms_norm=['native'])
(Worker_TP0 pid=57) INFO 06-21 07:19:47 [weight_utils.py:922] Filesystem type for checkpoints: EXT4. Checkpoint size: 148.66 GiB. Available RAM: 38.16 GiB.
(Worker_TP0 pid=57) INFO 06-21 07:19:47 [weight_utils.py:952] Auto-prefetch is disabled because the filesystem (EXT4) is not a recognized network FS (NFS/Lustre) and the checkpoint size (148.66 GiB) exceeds 90% of available RAM (38.16 GiB).
(Worker_TP0 pid=57) Loading safetensors checkpoint shards:   0% Completed | 0/46 [00:00<?, ?it/s]
(Worker_TP0 pid=57) Loading safetensors checkpoint shards:   4% Completed | 2/46 [00:00<00:09,  4.53it/s]
(Worker_TP0 pid=57) Loading safetensors checkpoint shards:   7% Completed | 3/46 [00:00<00:14,  2.93it/s]
(Worker_TP0 pid=57) Loading safetensors checkpoint shards:   9% Completed | 4/46 [00:01<00:16,  2.60it/s]
(Worker_TP0 pid=57) Loading safetensors checkpoint shards:  11% Completed | 5/46 [00:01<00:16,  2.46it/s]
(Worker_TP0 pid=57) Loading safetensors checkpoint shards:  13% Completed | 6/46 [00:02<00:16,  2.37it/s]
(Worker_TP0 pid=57) Loading safetensors checkpoint shards:  15% Completed | 7/46 [00:02<00:17,  2.28it/s]
(Worker_TP0 pid=57) Loading safetensors checkpoint shards:  17% Completed | 8/46 [00:03<00:16,  2.25it/s]
(Worker_TP0 pid=57) Loading safetensors checkpoint shards:  20% Completed | 9/46 [00:03<00:16,  2.19it/s]
(Worker_TP0 pid=57) Loading safetensors checkpoint shards:  22% Completed | 10/46 [00:04<00:16,  2.19it/s]
(Worker_TP0 pid=57) Loading safetensors checkpoint shards:  24% Completed | 11/46 [00:04<00:16,  2.16it/s]
(Worker_TP0 pid=57) Loading safetensors checkpoint shards:  26% Completed | 12/46 [00:05<00:16,  2.11it/s]
(Worker_TP0 pid=57) Loading safetensors checkpoint shards:  28% Completed | 13/46 [00:05<00:15,  2.14it/s]
(Worker_TP0 pid=57) Loading safetensors checkpoint shards:  30% Completed | 14/46 [00:06<00:14,  2.13it/s]
(Worker_TP0 pid=57) Loading safetensors checkpoint shards:  33% Completed | 15/46 [00:06<00:15,  2.07it/s]
(Worker_TP0 pid=57) Loading safetensors checkpoint shards:  35% Completed | 16/46 [00:07<00:14,  2.10it/s]
(Worker_TP0 pid=57) Loading safetensors checkpoint shards:  37% Completed | 17/46 [00:07<00:13,  2.12it/s]
(Worker_TP0 pid=57) Loading safetensors checkpoint shards:  39% Completed | 18/46 [00:08<00:13,  2.09it/s]
(Worker_TP0 pid=57) Loading safetensors checkpoint shards:  41% Completed | 19/46 [00:08<00:12,  2.12it/s]
(Worker_TP0 pid=57) Loading safetensors checkpoint shards:  43% Completed | 20/46 [00:08<00:12,  2.13it/s]
(Worker_TP0 pid=57) Loading safetensors checkpoint shards:  46% Completed | 21/46 [00:09<00:11,  2.13it/s]
(Worker_TP0 pid=57) Loading safetensors checkpoint shards:  48% Completed | 22/46 [00:09<00:11,  2.15it/s]
(Worker_TP0 pid=57) Loading safetensors checkpoint shards:  50% Completed | 23/46 [00:10<00:10,  2.11it/s]
(Worker_TP0 pid=57) Loading safetensors checkpoint shards:  52% Completed | 24/46 [00:10<00:10,  2.12it/s]
(Worker_TP0 pid=57) Loading safetensors checkpoint shards:  54% Completed | 25/46 [00:11<00:09,  2.15it/s]
(Worker_TP0 pid=57) Loading safetensors checkpoint shards:  57% Completed | 26/46 [00:11<00:09,  2.14it/s]
(Worker_TP0 pid=57) Loading safetensors checkpoint shards:  59% Completed | 27/46 [00:12<00:08,  2.17it/s]
(Worker_TP0 pid=57) Loading safetensors checkpoint shards:  61% Completed | 28/46 [00:12<00:08,  2.17it/s]
(Worker_TP0 pid=57) Loading safetensors checkpoint shards:  63% Completed | 29/46 [00:13<00:07,  2.15it/s]
(Worker_TP0 pid=57) Loading safetensors checkpoint shards:  65% Completed | 30/46 [00:13<00:09,  1.73it/s]
(Worker_TP0 pid=57) Loading safetensors checkpoint shards:  67% Completed | 31/46 [00:14<00:08,  1.82it/s]
(Worker_TP0 pid=57) Loading safetensors checkpoint shards:  70% Completed | 32/46 [00:14<00:07,  1.84it/s]
(Worker_TP0 pid=57) Loading safetensors checkpoint shards:  72% Completed | 33/46 [00:15<00:06,  1.88it/s]
(Worker_TP0 pid=57) Loading safetensors checkpoint shards:  74% Completed | 34/46 [00:15<00:06,  1.93it/s]
(Worker_TP0 pid=57) Loading safetensors checkpoint shards:  76% Completed | 35/46 [00:16<00:04,  2.30it/s]
(Worker_TP0 pid=57) Loading safetensors checkpoint shards:  83% Completed | 38/46 [00:16<00:01,  4.78it/s]
(Worker_TP0 pid=57) Loading safetensors checkpoint shards:  91% Completed | 42/46 [00:16<00:00,  8.77it/s]
(Worker_TP0 pid=57) Loading safetensors checkpoint shards: 100% Completed | 46/46 [00:19<00:00,  2.35it/s]
(Worker_TP0 pid=57) Loading safetensors checkpoint shards: 100% Completed | 46/46 [00:19<00:00,  2.32it/s]
(Worker_TP0 pid=57) 
(Worker_TP0 pid=57) INFO 06-21 07:20:07 [mtp.py:474] MTP draft model loaded: 39 params
(Worker_TP0 pid=57) INFO 06-21 07:20:07 [default_loader.py:397] Loading weights took 19.90 seconds
(Worker_TP0 pid=57) INFO 06-21 07:20:07 [llm_base_proposer.py:1334] Detected MTP model. Sharing target model embedding weights with the draft model.
(Worker_TP0 pid=57) INFO 06-21 07:20:07 [llm_base_proposer.py:1390] Detected MTP model. Sharing target model lm_head weights with the draft model.
(Worker_TP0 pid=57) INFO 06-21 07:20:07 [llm_base_proposer.py:1414] Shared target model lm_head with MTP shared_head.head.
(Worker_TP0 pid=57) INFO 06-21 07:20:07 [llm_base_proposer.py:1424] Detected MTP model with topk_indices_buffer. Sharing target model topk_indices_buffer with the draft model.
(Worker_TP0 pid=57) INFO 06-21 07:20:09 [gpu_model_runner.py:5132] Model loading took 75.86 GiB memory and 184.202604 seconds
(Worker_TP0 pid=57) INFO 06-21 07:20:11 [backends.py:1089] Using cache directory: /cache/huggingface/vllm-cache/torch_compile_cache/da3c862604/rank_0_0/backbone for vLLM's torch.compile
(Worker_TP0 pid=57) INFO 06-21 07:20:11 [backends.py:1148] Dynamo bytecode transform time: 1.47 s
(Worker_TP0 pid=57) INFO 06-21 07:20:13 [backends.py:292] Directly load the compiled graph(s) for compile range (1, 8192) from the cache, took 0.717 s
(Worker_TP0 pid=57) INFO 06-21 07:20:13 [decorators.py:311] Directly load AOT compilation from path /cache/huggingface/vllm-cache/torch_compile_cache/torch_aot_compile/6ee4daa3d72c1c67928ab6e7db1f6c813775dc3fff6b13f5af54737e0ece08e6/rank_0_0/model
(Worker_TP0 pid=57) INFO 06-21 07:20:13 [monitor.py:53] torch.compile took 2.89 s in total
(Worker_TP0 pid=57) INFO 06-21 07:20:22 [monitor.py:81] Initial profiling/warmup run took 9.79 s
(Worker_TP0 pid=57) INFO 06-21 07:20:23 [backends.py:1089] Using cache directory: /cache/huggingface/vllm-cache/torch_compile_cache/da3c862604/rank_0_0/eagle_head for vLLM's torch.compile
(Worker_TP0 pid=57) INFO 06-21 07:20:23 [backends.py:1148] Dynamo bytecode transform time: 0.05 s
(Worker_TP0 pid=57) INFO 06-21 07:20:23 [backends.py:292] Directly load the compiled graph(s) for compile range (1, 8192) from the cache, took 0.019 s
(Worker_TP0 pid=57) INFO 06-21 07:20:23 [decorators.py:311] Directly load AOT compilation from path /cache/huggingface/vllm-cache/torch_compile_cache/torch_aot_compile/c2b44229937c3750c2f29c2f1dd190142b6cf782663fb66f9bbff1e798aa1811/rank_0_0/model
(Worker_TP0 pid=57) INFO 06-21 07:20:23 [monitor.py:53] torch.compile took 0.50 s in total
(Worker_TP0 pid=57) INFO 06-21 07:20:23 [monitor.py:81] Initial profiling/warmup run took 0.01 s
(Worker_TP0 pid=57) INFO 06-21 07:20:24 [gpu_model_runner.py:6290] Profiling CUDA graph memory: PIECEWISE=5 (largest=24), FULL=3 (largest=9)
(Worker_TP0 pid=57) INFO 06-21 07:20:29 [gpu_model_runner.py:6376] Estimated CUDA graph memory: 0.55 GiB total
(Worker_TP0 pid=57) INFO 06-21 07:20:29 [gpu_worker.py:466] Available KV cache memory: 18.65 GiB
(Worker_TP0 pid=57) INFO 06-21 07:20:29 [gpu_worker.py:481] CUDA graph memory profiling is enabled (default since v0.21.0). The current --gpu-memory-utilization=0.8000 is equivalent to --gpu-memory-utilization=0.7955 without CUDA graph memory profiling. To maintain the same effective KV cache size as before, increase --gpu-memory-utilization to 0.8045. To disable, set VLLM_MEMORY_PROFILER_ESTIMATE_CUDAGRAPHS=0.
(EngineCore pid=34) INFO 06-21 07:20:29 [kv_cache_utils.py:1733] GPU KV cache size: 1,001,650 tokens
(EngineCore pid=34) INFO 06-21 07:20:29 [kv_cache_utils.py:1734] Maximum concurrency for 200,000 tokens per request: 5.01x
(Worker_TP0 pid=57) INFO 06-21 07:20:32 [deepseek_v4_mhc_warmup.py:200] Warming up DeepSeek V4 mHC kernels for token sizes: [1, 2, 3, 4, 6, 8, 9, 16, 18, 24, 32, 64, 128, 256, 512, 1024, 2048, 4096, 8192]
(Worker_TP0 pid=57) INFO 06-21 07:20:32 [deepseek_v4_mhc_warmup.py:209] DeepSeek V4 mHC warmup finished in 0.45 seconds.
(Worker_TP0 pid=57) INFO 06-21 07:20:32 [kernel_warmup.py:300] Warming up DeepSeek V4 sparse MLA attention for mixed tokens=16 and prefill tokens=8192.
(Worker_TP0 pid=57) INFO 06-21 07:20:32 [kernel_warmup.py:215] Autotuning DeepSeek V4 SM120 sparse MLA decode with FlashInfer cache file: /cache/huggingface/vllm-cache/flashinfer_autotune_cache/0.6.12/121a/e8c1bd5c40ea54309128d6a09533a531e0728347af890ac704a71ebe8acfac97/autotune_configs.json
(Worker_TP0 pid=57) 2026-06-21 07:20:32,548 - INFO - autotuner.py:1837 - flashinfer.jit: [Autotuner]: Loaded 30 configs from /cache/huggingface/vllm-cache/flashinfer_autotune_cache/0.6.12/121a/e8c1bd5c40ea54309128d6a09533a531e0728347af890ac704a71ebe8acfac97/autotune_configs.json
(Worker_TP0 pid=57) 2026-06-21 07:20:32,548 - INFO - autotuner.py:622 - flashinfer.jit: [Autotuner]: Autotuning process starts ...
(Worker_TP0 pid=57) 2026-06-21 07:20:32,566 - INFO - autotuner.py:961 - flashinfer.jit: [Autotuner]: Config cache hit for sparse_mla_sm120_decode_dsv4 (runner=SparseMlaDecodeV3Runner, source=config file)
(Worker_TP0 pid=57) 2026-06-21 07:20:32,741 - INFO - autotuner.py:641 - flashinfer.jit: [Autotuner]: Autotuning process ends
(Worker_TP0 pid=57) 2026-06-21 07:20:32,754 - INFO - autotuner.py:1837 - flashinfer.jit: [Autotuner]: Loaded 30 configs from /cache/huggingface/vllm-cache/flashinfer_autotune_cache/0.6.12/121a/e8c1bd5c40ea54309128d6a09533a531e0728347af890ac704a71ebe8acfac97/autotune_configs.json
(Worker_TP0 pid=57) INFO 06-21 07:20:32 [kernel_warmup.py:268] DeepSeek V4 sparse MLA decode autotune cache loaded on rank 0 from /cache/huggingface/vllm-cache/flashinfer_autotune_cache/0.6.12/121a/e8c1bd5c40ea54309128d6a09533a531e0728347af890ac704a71ebe8acfac97/autotune_configs.json.
(Worker_TP0 pid=57) INFO 06-21 07:20:37 [kernel_warmup.py:171] Warming up DeepSeek V4 request preparation kernels.
(Worker_TP0 pid=57) DeepGEMM warmup:   0%|          | 0/1762 [00:00<?, ?it/s]DeepGEMM warmup:  30%|███       | 535/1762 [00:00<00:00, 2243.00it/s]DeepGEMM warmup:  49%|████▉     | 861/1762 [00:00<00:00, 2064.23it/s]DeepGEMM warmup:  81%|████████▏ | 1433/1762 [00:00<00:00, 2839.37it/s]DeepGEMM warmup: 100%|██████████| 1762/1762 [00:00<00:00, 3145.39it/s]
(Worker_TP0 pid=57) 2026-06-21 07:20:40,219 - INFO - autotuner.py:622 - flashinfer.jit: [Autotuner]: Autotuning process starts ...
(Worker_TP0 pid=57) 2026-06-21 07:20:41,666 - INFO - autotuner.py:641 - flashinfer.jit: [Autotuner]: Autotuning process ends
(Worker_TP0 pid=57) Capturing CUDA graphs (mixed prefill-decode, PIECEWISE):   0%|          | 0/5 [00:00<?, ?it/s]Capturing CUDA graphs (mixed prefill-decode, PIECEWISE):  20%|██        | 1/5 [00:00<00:02,  1.87it/s]Capturing CUDA graphs (mixed prefill-decode, PIECEWISE):  40%|████      | 2/5 [00:01<00:01,  1.88it/s]Capturing CUDA graphs (mixed prefill-decode, PIECEWISE):  60%|██████    | 3/5 [00:01<00:01,  1.88it/s]Capturing CUDA graphs (mixed prefill-decode, PIECEWISE):  80%|████████  | 4/5 [00:02<00:00,  1.89it/s]Capturing CUDA graphs (mixed prefill-decode, PIECEWISE): 100%|██████████| 5/5 [00:02<00:00,  1.84it/s]Capturing CUDA graphs (mixed prefill-decode, PIECEWISE): 100%|██████████| 5/5 [00:02<00:00,  1.86it/s]
(Worker_TP0 pid=57) Capturing CUDA graphs (decode, FULL):   0%|          | 0/3 [00:00<?, ?it/s]Capturing CUDA graphs (decode, FULL):  33%|███▎      | 1/3 [00:00<00:00,  4.41it/s]Capturing CUDA graphs (decode, FULL):  67%|██████▋   | 2/3 [00:00<00:00,  4.78it/s]Capturing CUDA graphs (decode, FULL): 100%|██████████| 3/3 [00:00<00:00,  4.85it/s]Capturing CUDA graphs (decode, FULL): 100%|██████████| 3/3 [00:00<00:00,  4.79it/s]
(Worker_TP0 pid=57) INFO 06-21 07:20:47 [gpu_model_runner.py:6467] Graph capturing finished in 5 secs, took 0.34 GiB
(Worker_TP0 pid=57) INFO 06-21 07:20:47 [gpu_worker.py:619] CUDA graph pool memory: 0.34 GiB (actual), 0.55 GiB (estimated), difference: 0.21 GiB (62.0%).
(Worker_TP0 pid=57) INFO 06-21 07:20:47 [jit_monitor.py:54] Kernel JIT monitor activated — Triton JIT compilations during inference will be logged as warnings.
(EngineCore pid=34) INFO 06-21 07:20:47 [core.py:302] init engine (profile, create kv cache, warmup model) took 37.22 s (compilation: 5.14 s)
(EngineCore pid=34) INFO 06-21 07:20:49 [vllm.py:977] Asynchronous scheduling is enabled.
(EngineCore pid=34) INFO 06-21 07:20:49 [kernel.py:274] Final IR op priority after setting platform defaults: IrOpPriorityConfig(rms_norm=['native'], fused_add_rms_norm=['native'])
(EngineCore pid=34) WARNING 06-21 07:20:49 [vllm.py:1396] Auto-initialization of reasoning token IDs failed. Please check whether your reasoning parser has implemented the `reasoning_start_str` and `reasoning_end_str`.
(EngineCore pid=34) INFO 06-21 07:20:49 [compilation.py:321] Enabled custom fusions: norm_quant, act_quant
(APIServer pid=1) INFO 06-21 07:20:49 [api_server.py:592] Supported tasks: ['generate']
(APIServer pid=1) INFO 06-21 07:20:50 [parser_manager.py:202] "auto" tool choice has been enabled.
(APIServer pid=1) WARNING 06-21 07:20:50 [model.py:1509] Default vLLM sampling parameters have been overridden by the model's `generation_config.json`: `{'temperature': 1.0, 'top_p': 1.0}`. If this is not intended, please relaunch vLLM instance with `--generation-config vllm`.
(APIServer pid=1) INFO 06-21 07:20:50 [api_server.py:596] Starting vLLM server on http://0.0.0.0:8000
(APIServer pid=1) INFO 06-21 07:20:50 [launcher.py:37] Available routes are:
(APIServer pid=1) INFO 06-21 07:20:50 [launcher.py:46] Route: /openapi.json, Methods: HEAD, GET
(APIServer pid=1) INFO 06-21 07:20:50 [launcher.py:46] Route: /docs, Methods: HEAD, GET
(APIServer pid=1) INFO 06-21 07:20:50 [launcher.py:46] Route: /docs/oauth2-redirect, Methods: HEAD, GET
(APIServer pid=1) INFO 06-21 07:20:50 [launcher.py:46] Route: /redoc, Methods: HEAD, GET
(APIServer pid=1) INFO 06-21 07:20:50 [launcher.py:46] Route: /tokenize, Methods: POST
(APIServer pid=1) INFO 06-21 07:20:50 [launcher.py:46] Route: /detokenize, Methods: POST
(APIServer pid=1) INFO 06-21 07:20:50 [launcher.py:46] Route: /load, Methods: GET
(APIServer pid=1) INFO 06-21 07:20:50 [launcher.py:46] Route: /version, Methods: GET
(APIServer pid=1) INFO 06-21 07:20:50 [launcher.py:46] Route: /health, Methods: GET
(APIServer pid=1) INFO 06-21 07:20:50 [launcher.py:46] Route: /metrics, Methods: GET
(APIServer pid=1) INFO 06-21 07:20:50 [launcher.py:46] Route: /v1/models, Methods: GET
(APIServer pid=1) INFO 06-21 07:20:50 [launcher.py:46] Route: /ping, Methods: GET
(APIServer pid=1) INFO 06-21 07:20:50 [launcher.py:46] Route: /ping, Methods: POST
(APIServer pid=1) INFO 06-21 07:20:50 [launcher.py:46] Route: /invocations, Methods: POST
(APIServer pid=1) INFO 06-21 07:20:50 [launcher.py:46] Route: /v1/chat/completions, Methods: POST
(APIServer pid=1) INFO 06-21 07:20:50 [launcher.py:46] Route: /v1/chat/completions/batch, Methods: POST
(APIServer pid=1) INFO 06-21 07:20:50 [launcher.py:46] Route: /v1/responses, Methods: POST
(APIServer pid=1) INFO 06-21 07:20:50 [launcher.py:46] Route: /v1/responses/{response_id}, Methods: GET
(APIServer pid=1) INFO 06-21 07:20:50 [launcher.py:46] Route: /v1/responses/{response_id}/cancel, Methods: POST
(APIServer pid=1) INFO 06-21 07:20:50 [launcher.py:46] Route: /v1/completions, Methods: POST
(APIServer pid=1) INFO 06-21 07:20:50 [launcher.py:46] Route: /v1/messages, Methods: POST
(APIServer pid=1) INFO 06-21 07:20:50 [launcher.py:46] Route: /v1/messages/count_tokens, Methods: POST
(APIServer pid=1) INFO 06-21 07:20:50 [launcher.py:46] Route: /inference/v1/generate, Methods: POST
(APIServer pid=1) INFO 06-21 07:20:50 [launcher.py:46] Route: /scale_elastic_ep, Methods: POST
(APIServer pid=1) INFO 06-21 07:20:50 [launcher.py:46] Route: /is_scaling_elastic_ep, Methods: POST
(APIServer pid=1) INFO 06-21 07:20:50 [launcher.py:46] Route: /generative_scoring, Methods: POST
(APIServer pid=1) INFO 06-21 07:20:50 [launcher.py:46] Route: /v1/chat/completions/render, Methods: POST
(APIServer pid=1) INFO 06-21 07:20:50 [launcher.py:46] Route: /v1/completions/render, Methods: POST
(APIServer pid=1) INFO:     Started server process [1]
(APIServer pid=1) INFO:     Waiting for application startup.
(APIServer pid=1) INFO:     Application startup complete.
(APIServer pid=1) INFO:     172.18.0.2:35068 - "GET /v1/models HTTP/1.1" 200 OK
(APIServer pid=1) INFO:     172.18.0.2:42774 - "POST /v1/chat/completions HTTP/1.1" 200 OK
(Worker_TP0 pid=57) WARNING 06-21 07:54:39 [jit_monitor.py:103] Triton kernel JIT compilation during inference: _build_prefill_chunk_metadata_kernel. This causes a latency spike; consider extending warmup to cover this shape/config.
(Worker_TP0 pid=57) WARNING 06-21 07:54:39 [jit_monitor.py:103] Triton kernel JIT compilation during inference: eagle_prepare_next_token_padded_kernel. This causes a latency spike; consider extending warmup to cover this shape/config.
(Worker_TP0 pid=57) WARNING 06-21 07:54:39 [jit_monitor.py:103] Triton kernel JIT compilation during inference: eagle_step_slot_mapping_metadata_kernel. This causes a latency spike; consider extending warmup to cover this shape/config.
(Worker_TP0 pid=57) WARNING 06-21 07:54:40 [jit_monitor.py:103] Triton kernel JIT compilation during inference: eagle_prepare_inputs_padded_kernel. This causes a latency spike; consider extending warmup to cover this shape/config.
(APIServer pid=1) INFO:     172.18.0.2:42790 - "GET /v1/models HTTP/1.1" 200 OK
(APIServer pid=1) INFO 06-21 07:54:43 [loggers.py:271] Engine 000: Avg prompt throughput: 1.1 tokens/s, Avg generation throughput: 1.6 tokens/s, Running: 0 reqs, Waiting: 0 reqs, GPU KV cache usage: 0.0%, Prefix cache hit rate: 0.0%
(APIServer pid=1) INFO 06-21 07:54:43 [metrics.py:101] SpecDecoding metrics: Mean acceptance length: 2.83, Accepted throughput: 0.01 tokens/s, Drafted throughput: 0.01 tokens/s, Accepted: 11 tokens, Drafted: 12 tokens, Per-position acceptance rate: 1.000, 0.833, Avg Draft acceptance rate: 91.7%
(APIServer pid=1) INFO:     172.18.0.2:42806 - "GET /v1/models HTTP/1.1" 200 OK
(Worker_TP0 pid=57) 2026-06-21 07:54:41  [TileLang:tilelang.jit.kernel:INFO] (kernel.py:133): TileLang begins to compile kernel `mhc_pre_big_fuse_with_norm_tilelang` with `out_idx=None`
(Worker_TP0 pid=57) 2026-06-21 07:54:46  [TileLang:tilelang.jit.kernel:INFO] (kernel.py:141): TileLang completes to compile kernel `mhc_pre_big_fuse_with_norm_tilelang`
(Worker_TP0 pid=57) WARNING 06-21 07:54:48 [jit_monitor.py:103] Triton kernel JIT compilation during inference: _pack_topk_routes_prefix_kernel. This causes a latency spike; consider extending warmup to cover this shape/config.
(Worker_TP0 pid=57) WARNING 06-21 07:54:48 [jit_monitor.py:103] Triton kernel JIT compilation during inference: _pack_topk_routes_post_prefix_kernel. This causes a latency spike; consider extending warmup to cover this shape/config.
(APIServer pid=1) INFO:     172.18.0.2:42774 - "POST /v1/chat/completions HTTP/1.1" 200 OK
(APIServer pid=1) INFO 06-21 07:54:53 [loggers.py:271] Engine 000: Avg prompt throughput: 24.3 tokens/s, Avg generation throughput: 4.4 tokens/s, Running: 1 reqs, Waiting: 0 reqs, GPU KV cache usage: 0.7%, Prefix cache hit rate: 0.0%
(APIServer pid=1) INFO 06-21 07:54:53 [metrics.py:101] SpecDecoding metrics: Mean acceptance length: 2.44, Accepted throughput: 2.60 tokens/s, Drafted throughput: 3.60 tokens/s, Accepted: 26 tokens, Drafted: 36 tokens, Per-position acceptance rate: 0.833, 0.611, Avg Draft acceptance rate: 72.2%
(APIServer pid=1) INFO:     172.18.0.2:42774 - "POST /v1/chat/completions HTTP/1.1" 200 OK
(APIServer pid=1) INFO:     172.18.0.2:42774 - "POST /v1/chat/completions HTTP/1.1" 200 OK
(APIServer pid=1) INFO 06-21 07:55:03 [loggers.py:271] Engine 000: Avg prompt throughput: 49.7 tokens/s, Avg generation throughput: 2.3 tokens/s, Running: 0 reqs, Waiting: 0 reqs, GPU KV cache usage: 0.1%, Prefix cache hit rate: 0.0%
(APIServer pid=1) INFO 06-21 07:55:03 [metrics.py:101] SpecDecoding metrics: Mean acceptance length: 2.62, Accepted throughput: 1.30 tokens/s, Drafted throughput: 1.60 tokens/s, Accepted: 13 tokens, Drafted: 16 tokens, Per-position acceptance rate: 1.000, 0.625, Avg Draft acceptance rate: 81.2%
(APIServer pid=1) INFO 06-21 07:55:13 [loggers.py:271] Engine 000: Avg prompt throughput: 0.0 tokens/s, Avg generation throughput: 0.0 tokens/s, Running: 0 reqs, Waiting: 0 reqs, GPU KV cache usage: 0.1%, Prefix cache hit rate: 0.0%
(APIServer pid=1) INFO:     172.18.0.2:44130 - "POST /v1/chat/completions HTTP/1.1" 200 OK
(APIServer pid=1) INFO 06-21 08:03:23 [loggers.py:271] Engine 000: Avg prompt throughput: 4.4 tokens/s, Avg generation throughput: 28.8 tokens/s, Running: 1 reqs, Waiting: 0 reqs, GPU KV cache usage: 0.3%, Prefix cache hit rate: 0.0%
(APIServer pid=1) INFO 06-21 08:03:23 [metrics.py:101] SpecDecoding metrics: Mean acceptance length: 2.22, Accepted throughput: 0.32 tokens/s, Drafted throughput: 0.52 tokens/s, Accepted: 158 tokens, Drafted: 258 tokens, Per-position acceptance rate: 0.783, 0.442, Avg Draft acceptance rate: 61.2%
(APIServer pid=1) INFO 06-21 08:03:33 [loggers.py:271] Engine 000: Avg prompt throughput: 0.0 tokens/s, Avg generation throughput: 37.8 tokens/s, Running: 1 reqs, Waiting: 0 reqs, GPU KV cache usage: 0.3%, Prefix cache hit rate: 0.0%
(APIServer pid=1) INFO 06-21 08:03:33 [metrics.py:101] SpecDecoding metrics: Mean acceptance length: 2.02, Accepted throughput: 19.10 tokens/s, Drafted throughput: 37.39 tokens/s, Accepted: 191 tokens, Drafted: 374 tokens, Per-position acceptance rate: 0.711, 0.310, Avg Draft acceptance rate: 51.1%
(APIServer pid=1) INFO:     172.18.0.2:44130 - "POST /v1/chat/completions HTTP/1.1" 200 OK
(APIServer pid=1) INFO 06-21 08:03:43 [loggers.py:271] Engine 000: Avg prompt throughput: 94.7 tokens/s, Avg generation throughput: 11.0 tokens/s, Running: 0 reqs, Waiting: 0 reqs, GPU KV cache usage: 0.3%, Prefix cache hit rate: 0.0%
(APIServer pid=1) INFO 06-21 08:03:43 [metrics.py:101] SpecDecoding metrics: Mean acceptance length: 2.06, Accepted throughput: 5.70 tokens/s, Drafted throughput: 10.80 tokens/s, Accepted: 57 tokens, Drafted: 108 tokens, Per-position acceptance rate: 0.759, 0.296, Avg Draft acceptance rate: 52.8%
(APIServer pid=1) INFO 06-21 08:03:53 [loggers.py:271] Engine 000: Avg prompt throughput: 0.0 tokens/s, Avg generation throughput: 0.0 tokens/s, Running: 0 reqs, Waiting: 0 reqs, GPU KV cache usage: 0.3%, Prefix cache hit rate: 0.0%
(APIServer pid=1) INFO:     127.0.0.1:50696 - "POST /v1/chat/completions HTTP/1.1" 401 Unauthorized
(APIServer pid=1) INFO:     172.18.0.2:33018 - "POST /v1/chat/completions HTTP/1.1" 200 OK
(APIServer pid=1) INFO:     172.18.0.2:33018 - "POST /v1/chat/completions HTTP/1.1" 200 OK
(APIServer pid=1) INFO 06-21 08:17:53 [loggers.py:271] Engine 000: Avg prompt throughput: 43.5 tokens/s, Avg generation throughput: 12.1 tokens/s, Running: 0 reqs, Waiting: 0 reqs, GPU KV cache usage: 0.6%, Prefix cache hit rate: 37.0%
(APIServer pid=1) INFO 06-21 08:17:53 [metrics.py:101] SpecDecoding metrics: Mean acceptance length: 2.33, Accepted throughput: 0.08 tokens/s, Drafted throughput: 0.12 tokens/s, Accepted: 69 tokens, Drafted: 104 tokens, Per-position acceptance rate: 0.846, 0.481, Avg Draft acceptance rate: 66.3%
(APIServer pid=1) INFO 06-21 08:18:03 [loggers.py:271] Engine 000: Avg prompt throughput: 0.0 tokens/s, Avg generation throughput: 0.0 tokens/s, Running: 0 reqs, Waiting: 0 reqs, GPU KV cache usage: 0.6%, Prefix cache hit rate: 37.0%
(APIServer pid=1) INFO:     127.0.0.1:40670 - "POST /v1/chat/completions HTTP/1.1" 401 Unauthorized
(APIServer pid=1) INFO:     127.0.0.1:48124 - "POST /v1/chat/completions HTTP/1.1" 401 Unauthorized
(APIServer pid=1) INFO:     127.0.0.1:33466 - "POST /v1/chat/completions HTTP/1.1" 401 Unauthorized
(APIServer pid=1) INFO:     127.0.0.1:43230 - "POST /v1/chat/completions HTTP/1.1" 200 OK
(APIServer pid=1) INFO 06-21 08:27:13 [loggers.py:271] Engine 000: Avg prompt throughput: 0.9 tokens/s, Avg generation throughput: 0.2 tokens/s, Running: 0 reqs, Waiting: 0 reqs, GPU KV cache usage: 0.6%, Prefix cache hit rate: 36.9%
(APIServer pid=1) INFO 06-21 08:27:13 [metrics.py:101] SpecDecoding metrics: Mean acceptance length: 2.00, Accepted throughput: 0.00 tokens/s, Drafted throughput: 0.00 tokens/s, Accepted: 1 tokens, Drafted: 2 tokens, Per-position acceptance rate: 1.000, 0.000, Avg Draft acceptance rate: 50.0%
(APIServer pid=1) INFO:     127.0.0.1:43242 - "POST /v1/chat/completions HTTP/1.1" 200 OK
(APIServer pid=1) INFO:     127.0.0.1:43248 - "POST /v1/chat/completions HTTP/1.1" 200 OK
(APIServer pid=1) INFO 06-21 08:27:23 [loggers.py:271] Engine 000: Avg prompt throughput: 1.8 tokens/s, Avg generation throughput: 0.6 tokens/s, Running: 0 reqs, Waiting: 0 reqs, GPU KV cache usage: 0.6%, Prefix cache hit rate: 36.7%
(APIServer pid=1) INFO 06-21 08:27:23 [metrics.py:101] SpecDecoding metrics: Mean acceptance length: 1.50, Accepted throughput: 0.20 tokens/s, Drafted throughput: 0.80 tokens/s, Accepted: 2 tokens, Drafted: 8 tokens, Per-position acceptance rate: 0.500, 0.000, Avg Draft acceptance rate: 25.0%
(APIServer pid=1) INFO 06-21 08:27:33 [loggers.py:271] Engine 000: Avg prompt throughput: 0.0 tokens/s, Avg generation throughput: 0.0 tokens/s, Running: 0 reqs, Waiting: 0 reqs, GPU KV cache usage: 0.6%, Prefix cache hit rate: 36.7%
(APIServer pid=1) INFO:     127.0.0.1:35170 - "POST /v1/chat/completions HTTP/1.1" 200 OK
(APIServer pid=1) INFO 06-21 08:33:33 [loggers.py:271] Engine 000: Avg prompt throughput: 0.9 tokens/s, Avg generation throughput: 0.3 tokens/s, Running: 0 reqs, Waiting: 0 reqs, GPU KV cache usage: 0.6%, Prefix cache hit rate: 36.6%
(APIServer pid=1) INFO 06-21 08:33:33 [metrics.py:101] SpecDecoding metrics: Mean acceptance length: 1.50, Accepted throughput: 0.00 tokens/s, Drafted throughput: 0.01 tokens/s, Accepted: 1 tokens, Drafted: 4 tokens, Per-position acceptance rate: 0.500, 0.000, Avg Draft acceptance rate: 25.0%
(APIServer pid=1) INFO 06-21 08:33:43 [loggers.py:271] Engine 000: Avg prompt throughput: 0.0 tokens/s, Avg generation throughput: 0.0 tokens/s, Running: 0 reqs, Waiting: 0 reqs, GPU KV cache usage: 0.6%, Prefix cache hit rate: 36.6%
(APIServer pid=1) INFO:     127.0.0.1:46744 - "POST /v1/chat/completions HTTP/1.1" 200 OK
(APIServer pid=1) INFO 06-21 08:33:53 [loggers.py:271] Engine 000: Avg prompt throughput: 0.9 tokens/s, Avg generation throughput: 0.3 tokens/s, Running: 0 reqs, Waiting: 0 reqs, GPU KV cache usage: 0.6%, Prefix cache hit rate: 36.6%
(APIServer pid=1) INFO 06-21 08:33:53 [metrics.py:101] SpecDecoding metrics: Mean acceptance length: 1.50, Accepted throughput: 0.05 tokens/s, Drafted throughput: 0.20 tokens/s, Accepted: 1 tokens, Drafted: 4 tokens, Per-position acceptance rate: 0.500, 0.000, Avg Draft acceptance rate: 25.0%
(APIServer pid=1) INFO 06-21 08:34:03 [loggers.py:271] Engine 000: Avg prompt throughput: 0.0 tokens/s, Avg generation throughput: 0.0 tokens/s, Running: 0 reqs, Waiting: 0 reqs, GPU KV cache usage: 0.6%, Prefix cache hit rate: 36.6%
(APIServer pid=1) INFO:     172.18.0.2:35776 - "POST /v1/chat/completions HTTP/1.1" 200 OK
(APIServer pid=1) INFO:     172.18.0.2:35776 - "POST /v1/chat/completions HTTP/1.1" 200 OK
(APIServer pid=1) INFO 06-21 08:37:33 [loggers.py:271] Engine 000: Avg prompt throughput: 125.9 tokens/s, Avg generation throughput: 13.6 tokens/s, Running: 0 reqs, Waiting: 0 reqs, GPU KV cache usage: 1.0%, Prefix cache hit rate: 34.0%
(APIServer pid=1) INFO 06-21 08:37:33 [metrics.py:101] SpecDecoding metrics: Mean acceptance length: 2.16, Accepted throughput: 0.33 tokens/s, Drafted throughput: 0.57 tokens/s, Accepted: 73 tokens, Drafted: 126 tokens, Per-position acceptance rate: 0.778, 0.381, Avg Draft acceptance rate: 57.9%
(APIServer pid=1) INFO 06-21 08:37:43 [loggers.py:271] Engine 000: Avg prompt throughput: 0.0 tokens/s, Avg generation throughput: 0.0 tokens/s, Running: 0 reqs, Waiting: 0 reqs, GPU KV cache usage: 1.0%, Prefix cache hit rate: 34.0%
(APIServer pid=1) INFO:     172.18.0.2:47532 - "POST /v1/chat/completions HTTP/1.1" 200 OK
(APIServer pid=1) INFO:     172.18.0.2:47532 - "POST /v1/chat/completions HTTP/1.1" 200 OK
(APIServer pid=1) INFO 06-21 08:41:23 [loggers.py:271] Engine 000: Avg prompt throughput: 68.9 tokens/s, Avg generation throughput: 10.4 tokens/s, Running: 0 reqs, Waiting: 0 reqs, GPU KV cache usage: 1.2%, Prefix cache hit rate: 35.6%
(APIServer pid=1) INFO 06-21 08:41:23 [metrics.py:101] SpecDecoding metrics: Mean acceptance length: 2.08, Accepted throughput: 0.23 tokens/s, Drafted throughput: 0.43 tokens/s, Accepted: 54 tokens, Drafted: 100 tokens, Per-position acceptance rate: 0.780, 0.300, Avg Draft acceptance rate: 54.0%
(APIServer pid=1) INFO 06-21 08:41:33 [loggers.py:271] Engine 000: Avg prompt throughput: 0.0 tokens/s, Avg generation throughput: 0.0 tokens/s, Running: 0 reqs, Waiting: 0 reqs, GPU KV cache usage: 1.2%, Prefix cache hit rate: 35.6%
(APIServer pid=1) INFO:     172.18.0.2:50374 - "GET /v1/models HTTP/1.1" 200 OK
(APIServer pid=1) INFO:     172.18.0.2:43832 - "GET /v1/models HTTP/1.1" 200 OK
(APIServer pid=1) INFO:     192.168.1.244:46400 - "GET //models HTTP/1.1" 404 Not Found
(APIServer pid=1) INFO:     192.168.1.244:46400 - "GET /v1/models HTTP/1.1" 200 OK
(APIServer pid=1) INFO:     192.168.1.244:46050 - "POST /v1/chat/completions HTTP/1.1" 200 OK
(APIServer pid=1) INFO:     192.168.1.244:46050 - "POST /v1/chat/completions HTTP/1.1" 200 OK
(APIServer pid=1) INFO 06-21 12:54:54 [loggers.py:271] Engine 000: Avg prompt throughput: 1399.5 tokens/s, Avg generation throughput: 20.6 tokens/s, Running: 0 reqs, Waiting: 0 reqs, GPU KV cache usage: 1.9%, Prefix cache hit rate: 45.4%
(APIServer pid=1) INFO 06-21 12:54:54 [metrics.py:101] SpecDecoding metrics: Mean acceptance length: 2.23, Accepted throughput: 0.01 tokens/s, Drafted throughput: 0.01 tokens/s, Accepted: 113 tokens, Drafted: 184 tokens, Per-position acceptance rate: 0.761, 0.467, Avg Draft acceptance rate: 61.4%
(APIServer pid=1) INFO 06-21 12:55:04 [loggers.py:271] Engine 000: Avg prompt throughput: 0.0 tokens/s, Avg generation throughput: 0.0 tokens/s, Running: 0 reqs, Waiting: 0 reqs, GPU KV cache usage: 1.9%, Prefix cache hit rate: 45.4%
(APIServer pid=1) INFO:     192.168.1.244:47240 - "POST /v1/chat/completions HTTP/1.1" 200 OK
(APIServer pid=1) INFO:     192.168.1.244:47240 - "POST /v1/chat/completions HTTP/1.1" 200 OK
(APIServer pid=1) INFO 06-21 13:05:54 [loggers.py:271] Engine 000: Avg prompt throughput: 1497.9 tokens/s, Avg generation throughput: 4.4 tokens/s, Running: 0 reqs, Waiting: 0 reqs, GPU KV cache usage: 2.4%, Prefix cache hit rate: 31.7%
(APIServer pid=1) INFO 06-21 13:05:54 [metrics.py:101] SpecDecoding metrics: Mean acceptance length: 2.69, Accepted throughput: 0.04 tokens/s, Drafted throughput: 0.05 tokens/s, Accepted: 27 tokens, Drafted: 32 tokens, Per-position acceptance rate: 1.000, 0.688, Avg Draft acceptance rate: 84.4%
(APIServer pid=1) INFO:     192.168.1.244:47240 - "POST /v1/chat/completions HTTP/1.1" 200 OK
(APIServer pid=1) INFO 06-21 13:06:04 [loggers.py:271] Engine 000: Avg prompt throughput: 288.6 tokens/s, Avg generation throughput: 11.8 tokens/s, Running: 1 reqs, Waiting: 0 reqs, GPU KV cache usage: 2.9%, Prefix cache hit rate: 56.5%
(APIServer pid=1) INFO 06-21 13:06:04 [metrics.py:101] SpecDecoding metrics: Mean acceptance length: 2.64, Accepted throughput: 7.20 tokens/s, Drafted throughput: 8.80 tokens/s, Accepted: 72 tokens, Drafted: 88 tokens, Per-position acceptance rate: 0.932, 0.705, Avg Draft acceptance rate: 81.8%
(APIServer pid=1) INFO 06-21 13:06:14 [loggers.py:271] Engine 000: Avg prompt throughput: 0.0 tokens/s, Avg generation throughput: 42.8 tokens/s, Running: 1 reqs, Waiting: 0 reqs, GPU KV cache usage: 2.9%, Prefix cache hit rate: 56.5%
(APIServer pid=1) INFO 06-21 13:06:14 [metrics.py:101] SpecDecoding metrics: Mean acceptance length: 2.36, Accepted throughput: 24.70 tokens/s, Drafted throughput: 36.20 tokens/s, Accepted: 247 tokens, Drafted: 362 tokens, Per-position acceptance rate: 0.807, 0.558, Avg Draft acceptance rate: 68.2%
(APIServer pid=1) INFO 06-21 13:06:24 [loggers.py:271] Engine 000: Avg prompt throughput: 0.0 tokens/s, Avg generation throughput: 31.3 tokens/s, Running: 0 reqs, Waiting: 0 reqs, GPU KV cache usage: 2.8%, Prefix cache hit rate: 56.5%
(APIServer pid=1) INFO 06-21 13:06:24 [metrics.py:101] SpecDecoding metrics: Mean acceptance length: 2.26, Accepted throughput: 17.50 tokens/s, Drafted throughput: 27.80 tokens/s, Accepted: 175 tokens, Drafted: 278 tokens, Per-position acceptance rate: 0.784, 0.475, Avg Draft acceptance rate: 62.9%
(APIServer pid=1) INFO 06-21 13:06:34 [loggers.py:271] Engine 000: Avg prompt throughput: 0.0 tokens/s, Avg generation throughput: 0.0 tokens/s, Running: 0 reqs, Waiting: 0 reqs, GPU KV cache usage: 2.8%, Prefix cache hit rate: 56.5%
(APIServer pid=1) INFO:     192.168.1.244:44698 - "POST /v1/chat/completions HTTP/1.1" 200 OK
(APIServer pid=1) INFO:     192.168.1.244:44698 - "POST /v1/chat/completions HTTP/1.1" 200 OK
(APIServer pid=1) INFO:     192.168.1.244:44698 - "POST /v1/chat/completions HTTP/1.1" 200 OK
(APIServer pid=1) INFO 06-21 13:11:04 [loggers.py:271] Engine 000: Avg prompt throughput: 918.0 tokens/s, Avg generation throughput: 18.9 tokens/s, Running: 1 reqs, Waiting: 0 reqs, GPU KV cache usage: 3.4%, Prefix cache hit rate: 69.8%
(APIServer pid=1) INFO 06-21 13:11:04 [metrics.py:101] SpecDecoding metrics: Mean acceptance length: 2.51, Accepted throughput: 0.40 tokens/s, Drafted throughput: 0.53 tokens/s, Accepted: 112 tokens, Drafted: 148 tokens, Per-position acceptance rate: 0.892, 0.622, Avg Draft acceptance rate: 75.7%
(APIServer pid=1) INFO:     192.168.1.244:44698 - "POST /v1/chat/completions HTTP/1.1" 200 OK
(APIServer pid=1) INFO:     192.168.1.244:44698 - "POST /v1/chat/completions HTTP/1.1" 200 OK
(APIServer pid=1) INFO 06-21 13:11:14 [loggers.py:271] Engine 000: Avg prompt throughput: 158.5 tokens/s, Avg generation throughput: 29.5 tokens/s, Running: 1 reqs, Waiting: 0 reqs, GPU KV cache usage: 3.9%, Prefix cache hit rate: 77.3%
(APIServer pid=1) INFO 06-21 13:11:14 [metrics.py:101] SpecDecoding metrics: Mean acceptance length: 2.39, Accepted throughput: 17.10 tokens/s, Drafted throughput: 24.60 tokens/s, Accepted: 171 tokens, Drafted: 246 tokens, Per-position acceptance rate: 0.854, 0.537, Avg Draft acceptance rate: 69.5%
(APIServer pid=1) INFO:     192.168.1.244:44698 - "POST /v1/chat/completions HTTP/1.1" 200 OK
(APIServer pid=1) INFO:     192.168.1.244:44698 - "POST /v1/chat/completions HTTP/1.1" 200 OK
(APIServer pid=1) INFO 06-21 13:11:24 [loggers.py:271] Engine 000: Avg prompt throughput: 271.9 tokens/s, Avg generation throughput: 29.6 tokens/s, Running: 1 reqs, Waiting: 0 reqs, GPU KV cache usage: 4.1%, Prefix cache hit rate: 81.5%
(APIServer pid=1) INFO 06-21 13:11:24 [metrics.py:101] SpecDecoding metrics: Mean acceptance length: 2.35, Accepted throughput: 17.00 tokens/s, Drafted throughput: 25.20 tokens/s, Accepted: 170 tokens, Drafted: 252 tokens, Per-position acceptance rate: 0.833, 0.516, Avg Draft acceptance rate: 67.5%
(APIServer pid=1) INFO:     192.168.1.244:44698 - "POST /v1/chat/completions HTTP/1.1" 200 OK
(APIServer pid=1) INFO 06-21 13:11:34 [loggers.py:271] Engine 000: Avg prompt throughput: 113.4 tokens/s, Avg generation throughput: 36.5 tokens/s, Running: 0 reqs, Waiting: 0 reqs, GPU KV cache usage: 4.2%, Prefix cache hit rate: 83.1%
(APIServer pid=1) INFO 06-21 13:11:34 [metrics.py:101] SpecDecoding metrics: Mean acceptance length: 2.45, Accepted throughput: 21.60 tokens/s, Drafted throughput: 29.80 tokens/s, Accepted: 216 tokens, Drafted: 298 tokens, Per-position acceptance rate: 0.906, 0.544, Avg Draft acceptance rate: 72.5%
(APIServer pid=1) INFO:     192.168.1.244:44698 - "POST /v1/chat/completions HTTP/1.1" 200 OK
(APIServer pid=1) INFO:     192.168.1.244:44698 - "POST /v1/chat/completions HTTP/1.1" 200 OK
(APIServer pid=1) INFO:     192.168.1.244:44698 - "POST /v1/chat/completions HTTP/1.1" 200 OK
(APIServer pid=1) INFO 06-21 13:11:44 [loggers.py:271] Engine 000: Avg prompt throughput: 268.5 tokens/s, Avg generation throughput: 26.7 tokens/s, Running: 0 reqs, Waiting: 0 reqs, GPU KV cache usage: 4.6%, Prefix cache hit rate: 85.5%
(APIServer pid=1) INFO 06-21 13:11:44 [metrics.py:101] SpecDecoding metrics: Mean acceptance length: 2.52, Accepted throughput: 16.10 tokens/s, Drafted throughput: 21.20 tokens/s, Accepted: 161 tokens, Drafted: 212 tokens, Per-position acceptance rate: 0.925, 0.594, Avg Draft acceptance rate: 75.9%
(APIServer pid=1) INFO:     192.168.1.244:44698 - "POST /v1/chat/completions HTTP/1.1" 200 OK
(APIServer pid=1) INFO:     192.168.1.244:44698 - "POST /v1/chat/completions HTTP/1.1" 200 OK
(APIServer pid=1) INFO 06-21 13:11:54 [loggers.py:271] Engine 000: Avg prompt throughput: 938.5 tokens/s, Avg generation throughput: 15.8 tokens/s, Running: 1 reqs, Waiting: 0 reqs, GPU KV cache usage: 5.3%, Prefix cache hit rate: 87.1%
(APIServer pid=1) INFO 06-21 13:11:54 [metrics.py:101] SpecDecoding metrics: Mean acceptance length: 2.26, Accepted throughput: 8.70 tokens/s, Drafted throughput: 13.80 tokens/s, Accepted: 87 tokens, Drafted: 138 tokens, Per-position acceptance rate: 0.754, 0.507, Avg Draft acceptance rate: 63.0%
(APIServer pid=1) INFO:     192.168.1.244:44698 - "POST /v1/chat/completions HTTP/1.1" 200 OK
(APIServer pid=1) INFO 06-21 13:12:04 [loggers.py:271] Engine 000: Avg prompt throughput: 85.6 tokens/s, Avg generation throughput: 37.3 tokens/s, Running: 1 reqs, Waiting: 0 reqs, GPU KV cache usage: 5.5%, Prefix cache hit rate: 88.1%
(APIServer pid=1) INFO 06-21 13:12:04 [metrics.py:101] SpecDecoding metrics: Mean acceptance length: 2.34, Accepted throughput: 21.30 tokens/s, Drafted throughput: 31.80 tokens/s, Accepted: 213 tokens, Drafted: 318 tokens, Per-position acceptance rate: 0.774, 0.566, Avg Draft acceptance rate: 67.0%
(APIServer pid=1) INFO 06-21 13:12:14 [loggers.py:271] Engine 000: Avg prompt throughput: 0.0 tokens/s, Avg generation throughput: 39.2 tokens/s, Running: 1 reqs, Waiting: 0 reqs, GPU KV cache usage: 5.5%, Prefix cache hit rate: 88.1%
(APIServer pid=1) INFO 06-21 13:12:14 [metrics.py:101] SpecDecoding metrics: Mean acceptance length: 2.18, Accepted throughput: 21.20 tokens/s, Drafted throughput: 36.00 tokens/s, Accepted: 212 tokens, Drafted: 360 tokens, Per-position acceptance rate: 0.772, 0.406, Avg Draft acceptance rate: 58.9%
(APIServer pid=1) INFO 06-21 13:12:24 [loggers.py:271] Engine 000: Avg prompt throughput: 0.0 tokens/s, Avg generation throughput: 41.9 tokens/s, Running: 1 reqs, Waiting: 0 reqs, GPU KV cache usage: 5.5%, Prefix cache hit rate: 88.1%
(APIServer pid=1) INFO 06-21 13:12:24 [metrics.py:101] SpecDecoding metrics: Mean acceptance length: 2.33, Accepted throughput: 23.90 tokens/s, Drafted throughput: 36.00 tokens/s, Accepted: 239 tokens, Drafted: 360 tokens, Per-position acceptance rate: 0.811, 0.517, Avg Draft acceptance rate: 66.4%
(APIServer pid=1) INFO 06-21 13:12:34 [loggers.py:271] Engine 000: Avg prompt throughput: 0.0 tokens/s, Avg generation throughput: 2.7 tokens/s, Running: 0 reqs, Waiting: 0 reqs, GPU KV cache usage: 5.3%, Prefix cache hit rate: 88.1%
(APIServer pid=1) INFO 06-21 13:12:34 [metrics.py:101] SpecDecoding metrics: Mean acceptance length: 2.15, Accepted throughput: 1.50 tokens/s, Drafted throughput: 2.60 tokens/s, Accepted: 15 tokens, Drafted: 26 tokens, Per-position acceptance rate: 0.769, 0.385, Avg Draft acceptance rate: 57.7%
(APIServer pid=1) INFO 06-21 13:12:44 [loggers.py:271] Engine 000: Avg prompt throughput: 0.0 tokens/s, Avg generation throughput: 0.0 tokens/s, Running: 0 reqs, Waiting: 0 reqs, GPU KV cache usage: 5.3%, Prefix cache hit rate: 88.1%
(APIServer pid=1) INFO:     192.168.1.244:45668 - "POST /v1/chat/completions HTTP/1.1" 200 OK
(APIServer pid=1) INFO 06-21 13:14:54 [loggers.py:271] Engine 000: Avg prompt throughput: 71.5 tokens/s, Avg generation throughput: 36.8 tokens/s, Running: 1 reqs, Waiting: 0 reqs, GPU KV cache usage: 5.7%, Prefix cache hit rate: 88.9%
(APIServer pid=1) INFO 06-21 13:14:54 [metrics.py:101] SpecDecoding metrics: Mean acceptance length: 2.31, Accepted throughput: 1.49 tokens/s, Drafted throughput: 2.27 tokens/s, Accepted: 208 tokens, Drafted: 318 tokens, Per-position acceptance rate: 0.799, 0.509, Avg Draft acceptance rate: 65.4%
(APIServer pid=1) INFO 06-21 13:15:04 [loggers.py:271] Engine 000: Avg prompt throughput: 0.0 tokens/s, Avg generation throughput: 25.7 tokens/s, Running: 0 reqs, Waiting: 0 reqs, GPU KV cache usage: 5.5%, Prefix cache hit rate: 88.9%
(APIServer pid=1) INFO 06-21 13:15:04 [metrics.py:101] SpecDecoding metrics: Mean acceptance length: 2.06, Accepted throughput: 13.30 tokens/s, Drafted throughput: 25.00 tokens/s, Accepted: 133 tokens, Drafted: 250 tokens, Per-position acceptance rate: 0.720, 0.344, Avg Draft acceptance rate: 53.2%
(APIServer pid=1) INFO 06-21 13:15:14 [loggers.py:271] Engine 000: Avg prompt throughput: 0.0 tokens/s, Avg generation throughput: 0.0 tokens/s, Running: 0 reqs, Waiting: 0 reqs, GPU KV cache usage: 5.5%, Prefix cache hit rate: 88.9%
(APIServer pid=1) INFO:     192.168.1.244:47222 - "POST /v1/chat/completions HTTP/1.1" 200 OK
(APIServer pid=1) INFO:     192.168.1.244:47222 - "POST /v1/chat/completions HTTP/1.1" 200 OK
(APIServer pid=1) INFO:     192.168.1.244:47222 - "POST /v1/chat/completions HTTP/1.1" 200 OK
(APIServer pid=1) INFO 06-21 13:16:04 [loggers.py:271] Engine 000: Avg prompt throughput: 327.0 tokens/s, Avg generation throughput: 27.1 tokens/s, Running: 1 reqs, Waiting: 0 reqs, GPU KV cache usage: 6.1%, Prefix cache hit rate: 90.7%
(APIServer pid=1) INFO 06-21 13:16:04 [metrics.py:101] SpecDecoding metrics: Mean acceptance length: 2.36, Accepted throughput: 2.58 tokens/s, Drafted throughput: 3.80 tokens/s, Accepted: 155 tokens, Drafted: 228 tokens, Per-position acceptance rate: 0.825, 0.535, Avg Draft acceptance rate: 68.0%
(APIServer pid=1) INFO 06-21 13:16:14 [loggers.py:271] Engine 000: Avg prompt throughput: 0.0 tokens/s, Avg generation throughput: 39.3 tokens/s, Running: 1 reqs, Waiting: 0 reqs, GPU KV cache usage: 6.1%, Prefix cache hit rate: 90.7%
(APIServer pid=1) INFO 06-21 13:16:14 [metrics.py:101] SpecDecoding metrics: Mean acceptance length: 2.20, Accepted throughput: 21.40 tokens/s, Drafted throughput: 35.80 tokens/s, Accepted: 214 tokens, Drafted: 358 tokens, Per-position acceptance rate: 0.732, 0.464, Avg Draft acceptance rate: 59.8%
(APIServer pid=1) INFO 06-21 13:16:24 [loggers.py:271] Engine 000: Avg prompt throughput: 0.0 tokens/s, Avg generation throughput: 42.1 tokens/s, Running: 1 reqs, Waiting: 0 reqs, GPU KV cache usage: 6.2%, Prefix cache hit rate: 90.7%
(APIServer pid=1) INFO 06-21 13:16:24 [metrics.py:101] SpecDecoding metrics: Mean acceptance length: 2.35, Accepted throughput: 24.20 tokens/s, Drafted throughput: 35.80 tokens/s, Accepted: 242 tokens, Drafted: 358 tokens, Per-position acceptance rate: 0.844, 0.508, Avg Draft acceptance rate: 67.6%
(APIServer pid=1) INFO 06-21 13:16:34 [loggers.py:271] Engine 000: Avg prompt throughput: 0.0 tokens/s, Avg generation throughput: 28.5 tokens/s, Running: 0 reqs, Waiting: 0 reqs, GPU KV cache usage: 6.0%, Prefix cache hit rate: 90.7%
(APIServer pid=1) INFO 06-21 13:16:34 [metrics.py:101] SpecDecoding metrics: Mean acceptance length: 2.36, Accepted throughput: 16.50 tokens/s, Drafted throughput: 24.20 tokens/s, Accepted: 165 tokens, Drafted: 242 tokens, Per-position acceptance rate: 0.843, 0.521, Avg Draft acceptance rate: 68.2%
(APIServer pid=1) INFO 06-21 13:16:44 [loggers.py:271] Engine 000: Avg prompt throughput: 0.0 tokens/s, Avg generation throughput: 0.0 tokens/s, Running: 0 reqs, Waiting: 0 reqs, GPU KV cache usage: 6.0%, Prefix cache hit rate: 90.7%
(APIServer pid=1) INFO:     192.168.1.244:45878 - "POST /v1/chat/completions HTTP/1.1" 200 OK
(APIServer pid=1) INFO 06-21 13:18:44 [loggers.py:271] Engine 000: Avg prompt throughput: 92.8 tokens/s, Avg generation throughput: 3.3 tokens/s, Running: 1 reqs, Waiting: 0 reqs, GPU KV cache usage: 6.3%, Prefix cache hit rate: 91.2%
(APIServer pid=1) INFO 06-21 13:18:44 [metrics.py:101] SpecDecoding metrics: Mean acceptance length: 2.46, Accepted throughput: 0.15 tokens/s, Drafted throughput: 0.20 tokens/s, Accepted: 19 tokens, Drafted: 26 tokens, Per-position acceptance rate: 0.923, 0.538, Avg Draft acceptance rate: 73.1%
(APIServer pid=1) INFO 06-21 13:18:54 [loggers.py:271] Engine 000: Avg prompt throughput: 0.0 tokens/s, Avg generation throughput: 38.7 tokens/s, Running: 1 reqs, Waiting: 0 reqs, GPU KV cache usage: 6.3%, Prefix cache hit rate: 91.2%
(APIServer pid=1) INFO 06-21 13:18:54 [metrics.py:101] SpecDecoding metrics: Mean acceptance length: 2.15, Accepted throughput: 20.70 tokens/s, Drafted throughput: 36.00 tokens/s, Accepted: 207 tokens, Drafted: 360 tokens, Per-position acceptance rate: 0.728, 0.422, Avg Draft acceptance rate: 57.5%
(APIServer pid=1) INFO 06-21 13:19:04 [loggers.py:271] Engine 000: Avg prompt throughput: 0.0 tokens/s, Avg generation throughput: 21.1 tokens/s, Running: 0 reqs, Waiting: 0 reqs, GPU KV cache usage: 6.2%, Prefix cache hit rate: 91.2%
(APIServer pid=1) INFO 06-21 13:19:04 [metrics.py:101] SpecDecoding metrics: Mean acceptance length: 2.16, Accepted throughput: 11.40 tokens/s, Drafted throughput: 19.60 tokens/s, Accepted: 114 tokens, Drafted: 196 tokens, Per-position acceptance rate: 0.745, 0.418, Avg Draft acceptance rate: 58.2%
(APIServer pid=1) INFO 06-21 13:19:14 [loggers.py:271] Engine 000: Avg prompt throughput: 0.0 tokens/s, Avg generation throughput: 0.0 tokens/s, Running: 0 reqs, Waiting: 0 reqs, GPU KV cache usage: 6.2%, Prefix cache hit rate: 91.2%
(APIServer pid=1) INFO:     192.168.1.244:46172 - "POST /v1/chat/completions HTTP/1.1" 200 OK
(APIServer pid=1) INFO:     192.168.1.244:46172 - "POST /v1/chat/completions HTTP/1.1" 200 OK
(APIServer pid=1) INFO 06-21 13:19:54 [loggers.py:271] Engine 000: Avg prompt throughput: 115.0 tokens/s, Avg generation throughput: 11.3 tokens/s, Running: 1 reqs, Waiting: 0 reqs, GPU KV cache usage: 6.6%, Prefix cache hit rate: 92.1%
(APIServer pid=1) INFO 06-21 13:19:54 [metrics.py:101] SpecDecoding metrics: Mean acceptance length: 2.71, Accepted throughput: 1.40 tokens/s, Drafted throughput: 1.64 tokens/s, Accepted: 70 tokens, Drafted: 82 tokens, Per-position acceptance rate: 0.902, 0.805, Avg Draft acceptance rate: 85.4%
(APIServer pid=1) INFO:     192.168.1.244:46172 - "POST /v1/chat/completions HTTP/1.1" 200 OK
(APIServer pid=1) INFO:     192.168.1.244:46172 - "POST /v1/chat/completions HTTP/1.1" 200 OK
(APIServer pid=1) INFO 06-21 13:20:04 [loggers.py:271] Engine 000: Avg prompt throughput: 407.9 tokens/s, Avg generation throughput: 4.4 tokens/s, Running: 1 reqs, Waiting: 0 reqs, GPU KV cache usage: 7.0%, Prefix cache hit rate: 92.6%
(APIServer pid=1) INFO 06-21 13:20:04 [metrics.py:101] SpecDecoding metrics: Mean acceptance length: 2.53, Accepted throughput: 2.60 tokens/s, Drafted throughput: 3.40 tokens/s, Accepted: 26 tokens, Drafted: 34 tokens, Per-position acceptance rate: 0.941, 0.588, Avg Draft acceptance rate: 76.5%
(APIServer pid=1) INFO:     192.168.1.244:46172 - "POST /v1/chat/completions HTTP/1.1" 200 OK
(APIServer pid=1) INFO:     192.168.1.244:46172 - "POST /v1/chat/completions HTTP/1.1" 200 OK
(APIServer pid=1) INFO 06-21 13:20:14 [loggers.py:271] Engine 000: Avg prompt throughput: 187.7 tokens/s, Avg generation throughput: 31.0 tokens/s, Running: 1 reqs, Waiting: 0 reqs, GPU KV cache usage: 7.5%, Prefix cache hit rate: 93.2%
(APIServer pid=1) INFO 06-21 13:20:14 [metrics.py:101] SpecDecoding metrics: Mean acceptance length: 2.44, Accepted throughput: 18.30 tokens/s, Drafted throughput: 25.40 tokens/s, Accepted: 183 tokens, Drafted: 254 tokens, Per-position acceptance rate: 0.874, 0.567, Avg Draft acceptance rate: 72.0%
(APIServer pid=1) INFO 06-21 13:20:24 [loggers.py:271] Engine 000: Avg prompt throughput: 0.0 tokens/s, Avg generation throughput: 45.7 tokens/s, Running: 1 reqs, Waiting: 0 reqs, GPU KV cache usage: 7.5%, Prefix cache hit rate: 93.2%
(APIServer pid=1) INFO 06-21 13:20:24 [metrics.py:101] SpecDecoding metrics: Mean acceptance length: 2.63, Accepted throughput: 28.30 tokens/s, Drafted throughput: 34.80 tokens/s, Accepted: 283 tokens, Drafted: 348 tokens, Per-position acceptance rate: 0.937, 0.690, Avg Draft acceptance rate: 81.3%
(APIServer pid=1) INFO 06-21 13:20:34 [loggers.py:271] Engine 000: Avg prompt throughput: 0.0 tokens/s, Avg generation throughput: 45.6 tokens/s, Running: 1 reqs, Waiting: 0 reqs, GPU KV cache usage: 7.5%, Prefix cache hit rate: 93.2%
(APIServer pid=1) INFO 06-21 13:20:34 [metrics.py:101] SpecDecoding metrics: Mean acceptance length: 2.67, Accepted throughput: 28.50 tokens/s, Drafted throughput: 34.20 tokens/s, Accepted: 285 tokens, Drafted: 342 tokens, Per-position acceptance rate: 0.971, 0.696, Avg Draft acceptance rate: 83.3%
(APIServer pid=1) INFO:     192.168.1.244:47250 - "POST /v1/chat/completions HTTP/1.1" 200 OK
(APIServer pid=1) INFO 06-21 13:20:44 [loggers.py:271] Engine 000: Avg prompt throughput: 117.2 tokens/s, Avg generation throughput: 20.0 tokens/s, Running: 0 reqs, Waiting: 0 reqs, GPU KV cache usage: 7.6%, Prefix cache hit rate: 93.4%
(APIServer pid=1) INFO 06-21 13:20:44 [metrics.py:101] SpecDecoding metrics: Mean acceptance length: 2.83, Accepted throughput: 13.00 tokens/s, Drafted throughput: 14.20 tokens/s, Accepted: 130 tokens, Drafted: 142 tokens, Per-position acceptance rate: 1.000, 0.831, Avg Draft acceptance rate: 91.5%
(APIServer pid=1) INFO:     192.168.1.244:44722 - "POST /v1/chat/completions HTTP/1.1" 200 OK
(APIServer pid=1) INFO 06-21 13:20:54 [loggers.py:271] Engine 000: Avg prompt throughput: 50.7 tokens/s, Avg generation throughput: 20.5 tokens/s, Running: 0 reqs, Waiting: 0 reqs, GPU KV cache usage: 7.8%, Prefix cache hit rate: 93.7%
(APIServer pid=1) INFO 06-21 13:20:54 [metrics.py:101] SpecDecoding metrics: Mean acceptance length: 2.73, Accepted throughput: 13.00 tokens/s, Drafted throughput: 15.00 tokens/s, Accepted: 130 tokens, Drafted: 150 tokens, Per-position acceptance rate: 1.000, 0.733, Avg Draft acceptance rate: 86.7%
(APIServer pid=1) INFO:     192.168.1.244:47064 - "POST /v1/chat/completions HTTP/1.1" 200 OK
(APIServer pid=1) INFO 06-21 13:21:04 [loggers.py:271] Engine 000: Avg prompt throughput: 69.5 tokens/s, Avg generation throughput: 13.3 tokens/s, Running: 0 reqs, Waiting: 0 reqs, GPU KV cache usage: 8.0%, Prefix cache hit rate: 94.0%
(APIServer pid=1) INFO 06-21 13:21:04 [metrics.py:101] SpecDecoding metrics: Mean acceptance length: 2.75, Accepted throughput: 8.40 tokens/s, Drafted throughput: 9.60 tokens/s, Accepted: 84 tokens, Drafted: 96 tokens, Per-position acceptance rate: 1.000, 0.750, Avg Draft acceptance rate: 87.5%
(APIServer pid=1) INFO:     192.168.1.244:45394 - "POST /v1/chat/completions HTTP/1.1" 200 OK
(APIServer pid=1) INFO:     192.168.1.244:45394 - "POST /v1/chat/completions HTTP/1.1" 200 OK
(APIServer pid=1) INFO 06-21 13:21:14 [loggers.py:271] Engine 000: Avg prompt throughput: 129.8 tokens/s, Avg generation throughput: 19.2 tokens/s, Running: 0 reqs, Waiting: 0 reqs, GPU KV cache usage: 8.3%, Prefix cache hit rate: 94.4%
(APIServer pid=1) INFO 06-21 13:21:14 [metrics.py:101] SpecDecoding metrics: Mean acceptance length: 2.67, Accepted throughput: 12.00 tokens/s, Drafted throughput: 14.40 tokens/s, Accepted: 120 tokens, Drafted: 144 tokens, Per-position acceptance rate: 0.972, 0.694, Avg Draft acceptance rate: 83.3%
(APIServer pid=1) INFO:     192.168.1.244:48128 - "POST /v1/chat/completions HTTP/1.1" 200 OK
(APIServer pid=1) INFO:     192.168.1.244:48128 - "POST /v1/chat/completions HTTP/1.1" 200 OK
(APIServer pid=1) INFO 06-21 13:21:24 [loggers.py:271] Engine 000: Avg prompt throughput: 113.2 tokens/s, Avg generation throughput: 30.4 tokens/s, Running: 1 reqs, Waiting: 0 reqs, GPU KV cache usage: 8.9%, Prefix cache hit rate: 94.8%
(APIServer pid=1) INFO 06-21 13:21:24 [metrics.py:101] SpecDecoding metrics: Mean acceptance length: 2.52, Accepted throughput: 18.20 tokens/s, Drafted throughput: 24.00 tokens/s, Accepted: 182 tokens, Drafted: 240 tokens, Per-position acceptance rate: 0.933, 0.583, Avg Draft acceptance rate: 75.8%
(APIServer pid=1) INFO 06-21 13:21:34 [loggers.py:271] Engine 000: Avg prompt throughput: 0.0 tokens/s, Avg generation throughput: 42.5 tokens/s, Running: 0 reqs, Waiting: 0 reqs, GPU KV cache usage: 8.7%, Prefix cache hit rate: 94.8%
(APIServer pid=1) INFO 06-21 13:21:34 [metrics.py:101] SpecDecoding metrics: Mean acceptance length: 2.45, Accepted throughput: 25.20 tokens/s, Drafted throughput: 34.80 tokens/s, Accepted: 252 tokens, Drafted: 348 tokens, Per-position acceptance rate: 0.868, 0.580, Avg Draft acceptance rate: 72.4%
(APIServer pid=1) INFO 06-21 13:21:44 [loggers.py:271] Engine 000: Avg prompt throughput: 0.0 tokens/s, Avg generation throughput: 0.0 tokens/s, Running: 0 reqs, Waiting: 0 reqs, GPU KV cache usage: 8.7%, Prefix cache hit rate: 94.8%
(APIServer pid=1) INFO:     192.168.1.244:45562 - "POST /v1/chat/completions HTTP/1.1" 200 OK
(APIServer pid=1) INFO 06-21 13:25:24 [loggers.py:271] Engine 000: Avg prompt throughput: 66.9 tokens/s, Avg generation throughput: 30.2 tokens/s, Running: 0 reqs, Waiting: 0 reqs, GPU KV cache usage: 8.9%, Prefix cache hit rate: 95.0%
(APIServer pid=1) INFO 06-21 13:25:24 [metrics.py:101] SpecDecoding metrics: Mean acceptance length: 2.50, Accepted throughput: 0.79 tokens/s, Drafted throughput: 1.05 tokens/s, Accepted: 181 tokens, Drafted: 242 tokens, Per-position acceptance rate: 0.884, 0.612, Avg Draft acceptance rate: 74.8%
(APIServer pid=1) INFO:     192.168.1.244:47048 - "POST /v1/chat/completions HTTP/1.1" 200 OK
(APIServer pid=1) INFO:     192.168.1.244:47320 - "POST /v1/chat/completions HTTP/1.1" 200 OK
(APIServer pid=1) INFO 06-21 13:25:34 [loggers.py:271] Engine 000: Avg prompt throughput: 152.6 tokens/s, Avg generation throughput: 12.0 tokens/s, Running: 1 reqs, Waiting: 0 reqs, GPU KV cache usage: 9.3%, Prefix cache hit rate: 95.3%
(APIServer pid=1) INFO 06-21 13:25:34 [metrics.py:101] SpecDecoding metrics: Mean acceptance length: 2.81, Accepted throughput: 7.60 tokens/s, Drafted throughput: 8.40 tokens/s, Accepted: 76 tokens, Drafted: 84 tokens, Per-position acceptance rate: 1.000, 0.810, Avg Draft acceptance rate: 90.5%
(APIServer pid=1) INFO:     192.168.1.244:47322 - "POST /v1/chat/completions HTTP/1.1" 200 OK
(APIServer pid=1) INFO 06-21 13:25:44 [loggers.py:271] Engine 000: Avg prompt throughput: 60.7 tokens/s, Avg generation throughput: 20.6 tokens/s, Running: 1 reqs, Waiting: 0 reqs, GPU KV cache usage: 9.5%, Prefix cache hit rate: 95.4%
(APIServer pid=1) INFO 06-21 13:25:44 [metrics.py:101] SpecDecoding metrics: Mean acceptance length: 2.34, Accepted throughput: 11.80 tokens/s, Drafted throughput: 17.60 tokens/s, Accepted: 118 tokens, Drafted: 176 tokens, Per-position acceptance rate: 0.830, 0.511, Avg Draft acceptance rate: 67.0%
(APIServer pid=1) INFO:     192.168.1.244:47322 - "POST /v1/chat/completions HTTP/1.1" 200 OK
(APIServer pid=1) INFO 06-21 13:25:54 [loggers.py:271] Engine 000: Avg prompt throughput: 35.2 tokens/s, Avg generation throughput: 21.3 tokens/s, Running: 0 reqs, Waiting: 0 reqs, GPU KV cache usage: 9.5%, Prefix cache hit rate: 95.5%
(APIServer pid=1) INFO 06-21 13:25:54 [metrics.py:101] SpecDecoding metrics: Mean acceptance length: 2.32, Accepted throughput: 12.30 tokens/s, Drafted throughput: 18.60 tokens/s, Accepted: 123 tokens, Drafted: 186 tokens, Per-position acceptance rate: 0.839, 0.484, Avg Draft acceptance rate: 66.1%
(APIServer pid=1) INFO 06-21 13:26:04 [loggers.py:271] Engine 000: Avg prompt throughput: 0.0 tokens/s, Avg generation throughput: 0.0 tokens/s, Running: 0 reqs, Waiting: 0 reqs, GPU KV cache usage: 9.5%, Prefix cache hit rate: 95.5%
(APIServer pid=1) INFO:     192.168.1.244:45592 - "POST /v1/chat/completions HTTP/1.1" 200 OK
(APIServer pid=1) INFO:     192.168.1.244:45592 - "POST /v1/chat/completions HTTP/1.1" 200 OK
(APIServer pid=1) INFO 06-21 13:27:04 [loggers.py:271] Engine 000: Avg prompt throughput: 155.1 tokens/s, Avg generation throughput: 20.9 tokens/s, Running: 0 reqs, Waiting: 0 reqs, GPU KV cache usage: 9.9%, Prefix cache hit rate: 95.8%
(APIServer pid=1) INFO 06-21 13:27:04 [metrics.py:101] SpecDecoding metrics: Mean acceptance length: 2.40, Accepted throughput: 1.74 tokens/s, Drafted throughput: 2.49 tokens/s, Accepted: 122 tokens, Drafted: 174 tokens, Per-position acceptance rate: 0.862, 0.540, Avg Draft acceptance rate: 70.1%
(APIServer pid=1) INFO:     192.168.1.244:48626 - "POST /v1/chat/completions HTTP/1.1" 200 OK
(APIServer pid=1) INFO 06-21 13:27:14 [loggers.py:271] Engine 000: Avg prompt throughput: 300.7 tokens/s, Avg generation throughput: 16.8 tokens/s, Running: 1 reqs, Waiting: 0 reqs, GPU KV cache usage: 10.3%, Prefix cache hit rate: 95.8%
(APIServer pid=1) INFO 06-21 13:27:14 [metrics.py:101] SpecDecoding metrics: Mean acceptance length: 2.42, Accepted throughput: 9.80 tokens/s, Drafted throughput: 13.80 tokens/s, Accepted: 98 tokens, Drafted: 138 tokens, Per-position acceptance rate: 0.870, 0.551, Avg Draft acceptance rate: 71.0%
(APIServer pid=1) INFO 06-21 13:27:24 [loggers.py:271] Engine 000: Avg prompt throughput: 0.0 tokens/s, Avg generation throughput: 13.3 tokens/s, Running: 0 reqs, Waiting: 0 reqs, GPU KV cache usage: 10.1%, Prefix cache hit rate: 95.8%
(APIServer pid=1) INFO 06-21 13:27:24 [metrics.py:101] SpecDecoding metrics: Mean acceptance length: 2.31, Accepted throughput: 7.60 tokens/s, Drafted throughput: 11.60 tokens/s, Accepted: 76 tokens, Drafted: 116 tokens, Per-position acceptance rate: 0.810, 0.500, Avg Draft acceptance rate: 65.5%
(APIServer pid=1) INFO 06-21 13:27:34 [loggers.py:271] Engine 000: Avg prompt throughput: 0.0 tokens/s, Avg generation throughput: 0.0 tokens/s, Running: 0 reqs, Waiting: 0 reqs, GPU KV cache usage: 10.1%, Prefix cache hit rate: 95.8%
(APIServer pid=1) INFO:     192.168.1.244:44764 - "POST /v1/chat/completions HTTP/1.1" 200 OK
(APIServer pid=1) INFO 06-21 13:28:04 [loggers.py:271] Engine 000: Avg prompt throughput: 53.4 tokens/s, Avg generation throughput: 1.8 tokens/s, Running: 1 reqs, Waiting: 0 reqs, GPU KV cache usage: 10.3%, Prefix cache hit rate: 95.9%
(APIServer pid=1) INFO 06-21 13:28:04 [metrics.py:101] SpecDecoding metrics: Mean acceptance length: 2.43, Accepted throughput: 0.25 tokens/s, Drafted throughput: 0.35 tokens/s, Accepted: 10 tokens, Drafted: 14 tokens, Per-position acceptance rate: 0.857, 0.571, Avg Draft acceptance rate: 71.4%
(APIServer pid=1) INFO:     192.168.1.244:47210 - "POST /v1/chat/completions HTTP/1.1" 200 OK
(APIServer pid=1) INFO 06-21 13:28:14 [loggers.py:271] Engine 000: Avg prompt throughput: 292.9 tokens/s, Avg generation throughput: 15.3 tokens/s, Running: 1 reqs, Waiting: 0 reqs, GPU KV cache usage: 10.6%, Prefix cache hit rate: 95.9%
(APIServer pid=1) INFO 06-21 13:28:14 [metrics.py:101] SpecDecoding metrics: Mean acceptance length: 2.43, Accepted throughput: 9.00 tokens/s, Drafted throughput: 12.60 tokens/s, Accepted: 90 tokens, Drafted: 126 tokens, Per-position acceptance rate: 0.889, 0.540, Avg Draft acceptance rate: 71.4%
(APIServer pid=1) INFO 06-21 13:28:24 [loggers.py:271] Engine 000: Avg prompt throughput: 0.0 tokens/s, Avg generation throughput: 9.5 tokens/s, Running: 0 reqs, Waiting: 0 reqs, GPU KV cache usage: 10.4%, Prefix cache hit rate: 95.9%
(APIServer pid=1) INFO 06-21 13:28:24 [metrics.py:101] SpecDecoding metrics: Mean acceptance length: 2.29, Accepted throughput: 5.40 tokens/s, Drafted throughput: 8.40 tokens/s, Accepted: 54 tokens, Drafted: 84 tokens, Per-position acceptance rate: 0.833, 0.452, Avg Draft acceptance rate: 64.3%
(APIServer pid=1) INFO 06-21 13:28:34 [loggers.py:271] Engine 000: Avg prompt throughput: 0.0 tokens/s, Avg generation throughput: 0.0 tokens/s, Running: 0 reqs, Waiting: 0 reqs, GPU KV cache usage: 10.4%, Prefix cache hit rate: 95.9%
(APIServer pid=1) INFO:     192.168.1.244:45204 - "POST /v1/chat/completions HTTP/1.1" 200 OK
(APIServer pid=1) INFO 06-21 13:29:24 [loggers.py:271] Engine 000: Avg prompt throughput: 366.8 tokens/s, Avg generation throughput: 15.8 tokens/s, Running: 0 reqs, Waiting: 0 reqs, GPU KV cache usage: 10.6%, Prefix cache hit rate: 95.9%
(APIServer pid=1) INFO 06-21 13:29:24 [metrics.py:101] SpecDecoding metrics: Mean acceptance length: 2.32, Accepted throughput: 1.50 tokens/s, Drafted throughput: 2.27 tokens/s, Accepted: 90 tokens, Drafted: 136 tokens, Per-position acceptance rate: 0.809, 0.515, Avg Draft acceptance rate: 66.2%
(APIServer pid=1) INFO 06-21 13:29:34 [loggers.py:271] Engine 000: Avg prompt throughput: 0.0 tokens/s, Avg generation throughput: 0.0 tokens/s, Running: 0 reqs, Waiting: 0 reqs, GPU KV cache usage: 10.6%, Prefix cache hit rate: 95.9%
(APIServer pid=1) INFO:     192.168.1.244:46388 - "POST /v1/chat/completions HTTP/1.1" 200 OK
(APIServer pid=1) INFO 06-21 13:31:14 [loggers.py:271] Engine 000: Avg prompt throughput: 96.5 tokens/s, Avg generation throughput: 0.1 tokens/s, Running: 1 reqs, Waiting: 0 reqs, GPU KV cache usage: 10.9%, Prefix cache hit rate: 96.0%
(APIServer pid=1) INFO 06-21 13:31:24 [loggers.py:271] Engine 000: Avg prompt throughput: 0.0 tokens/s, Avg generation throughput: 37.5 tokens/s, Running: 1 reqs, Waiting: 0 reqs, GPU KV cache usage: 11.0%, Prefix cache hit rate: 96.0%
(APIServer pid=1) INFO 06-21 13:31:24 [metrics.py:101] SpecDecoding metrics: Mean acceptance length: 2.09, Accepted throughput: 1.63 tokens/s, Drafted throughput: 2.98 tokens/s, Accepted: 196 tokens, Drafted: 358 tokens, Per-position acceptance rate: 0.754, 0.341, Avg Draft acceptance rate: 54.7%
(APIServer pid=1) INFO 06-21 13:31:34 [loggers.py:271] Engine 000: Avg prompt throughput: 0.0 tokens/s, Avg generation throughput: 12.0 tokens/s, Running: 0 reqs, Waiting: 0 reqs, GPU KV cache usage: 10.9%, Prefix cache hit rate: 96.0%
(APIServer pid=1) INFO 06-21 13:31:34 [metrics.py:101] SpecDecoding metrics: Mean acceptance length: 2.16, Accepted throughput: 6.50 tokens/s, Drafted throughput: 11.20 tokens/s, Accepted: 65 tokens, Drafted: 112 tokens, Per-position acceptance rate: 0.732, 0.429, Avg Draft acceptance rate: 58.0%
(APIServer pid=1) INFO 06-21 13:31:44 [loggers.py:271] Engine 000: Avg prompt throughput: 0.0 tokens/s, Avg generation throughput: 0.0 tokens/s, Running: 0 reqs, Waiting: 0 reqs, GPU KV cache usage: 10.9%, Prefix cache hit rate: 96.0%
(APIServer pid=1) INFO:     192.168.1.244:46146 - "POST /v1/chat/completions HTTP/1.1" 200 OK
(APIServer pid=1) INFO 06-21 13:33:04 [loggers.py:271] Engine 000: Avg prompt throughput: 90.5 tokens/s, Avg generation throughput: 23.0 tokens/s, Running: 0 reqs, Waiting: 0 reqs, GPU KV cache usage: 11.0%, Prefix cache hit rate: 96.1%
(APIServer pid=1) INFO 06-21 13:33:04 [metrics.py:101] SpecDecoding metrics: Mean acceptance length: 2.15, Accepted throughput: 1.37 tokens/s, Drafted throughput: 2.38 tokens/s, Accepted: 123 tokens, Drafted: 214 tokens, Per-position acceptance rate: 0.776, 0.374, Avg Draft acceptance rate: 57.5%
(APIServer pid=1) INFO 06-21 13:33:14 [loggers.py:271] Engine 000: Avg prompt throughput: 0.0 tokens/s, Avg generation throughput: 0.0 tokens/s, Running: 0 reqs, Waiting: 0 reqs, GPU KV cache usage: 11.0%, Prefix cache hit rate: 96.1%
(APIServer pid=1) INFO:     192.168.1.244:46314 - "POST /v1/chat/completions HTTP/1.1" 200 OK
(APIServer pid=1) INFO 06-21 13:38:24 [loggers.py:271] Engine 000: Avg prompt throughput: 85.0 tokens/s, Avg generation throughput: 1.8 tokens/s, Running: 1 reqs, Waiting: 0 reqs, GPU KV cache usage: 11.3%, Prefix cache hit rate: 96.2%
(APIServer pid=1) INFO 06-21 13:38:24 [metrics.py:101] SpecDecoding metrics: Mean acceptance length: 2.12, Accepted throughput: 0.03 tokens/s, Drafted throughput: 0.05 tokens/s, Accepted: 9 tokens, Drafted: 16 tokens, Per-position acceptance rate: 0.750, 0.375, Avg Draft acceptance rate: 56.2%
(APIServer pid=1) INFO 06-21 13:38:34 [loggers.py:271] Engine 000: Avg prompt throughput: 0.0 tokens/s, Avg generation throughput: 44.8 tokens/s, Running: 1 reqs, Waiting: 0 reqs, GPU KV cache usage: 11.3%, Prefix cache hit rate: 96.2%
(APIServer pid=1) INFO 06-21 13:38:34 [metrics.py:101] SpecDecoding metrics: Mean acceptance length: 2.55, Accepted throughput: 27.20 tokens/s, Drafted throughput: 35.20 tokens/s, Accepted: 272 tokens, Drafted: 352 tokens, Per-position acceptance rate: 0.875, 0.670, Avg Draft acceptance rate: 77.3%
(APIServer pid=1) INFO 06-21 13:38:44 [loggers.py:271] Engine 000: Avg prompt throughput: 0.0 tokens/s, Avg generation throughput: 41.7 tokens/s, Running: 1 reqs, Waiting: 0 reqs, GPU KV cache usage: 11.3%, Prefix cache hit rate: 96.2%
(APIServer pid=1) INFO 06-21 13:38:44 [metrics.py:101] SpecDecoding metrics: Mean acceptance length: 2.44, Accepted throughput: 24.60 tokens/s, Drafted throughput: 34.20 tokens/s, Accepted: 246 tokens, Drafted: 342 tokens, Per-position acceptance rate: 0.813, 0.626, Avg Draft acceptance rate: 71.9%
(APIServer pid=1) INFO 06-21 13:38:54 [loggers.py:271] Engine 000: Avg prompt throughput: 0.0 tokens/s, Avg generation throughput: 15.4 tokens/s, Running: 0 reqs, Waiting: 0 reqs, GPU KV cache usage: 11.2%, Prefix cache hit rate: 96.2%
(APIServer pid=1) INFO 06-21 13:38:54 [metrics.py:101] SpecDecoding metrics: Mean acceptance length: 2.21, Accepted throughput: 8.50 tokens/s, Drafted throughput: 14.00 tokens/s, Accepted: 85 tokens, Drafted: 140 tokens, Per-position acceptance rate: 0.757, 0.457, Avg Draft acceptance rate: 60.7%
(APIServer pid=1) INFO 06-21 13:39:04 [loggers.py:271] Engine 000: Avg prompt throughput: 0.0 tokens/s, Avg generation throughput: 0.0 tokens/s, Running: 0 reqs, Waiting: 0 reqs, GPU KV cache usage: 11.2%, Prefix cache hit rate: 96.2%
(APIServer pid=1) INFO:     192.168.1.244:45412 - "POST /v1/chat/completions HTTP/1.1" 200 OK
(APIServer pid=1) INFO 06-21 13:41:04 [loggers.py:271] Engine 000: Avg prompt throughput: 88.5 tokens/s, Avg generation throughput: 43.4 tokens/s, Running: 1 reqs, Waiting: 0 reqs, GPU KV cache usage: 11.5%, Prefix cache hit rate: 96.3%
(APIServer pid=1) INFO 06-21 13:41:04 [metrics.py:101] SpecDecoding metrics: Mean acceptance length: 2.55, Accepted throughput: 2.02 tokens/s, Drafted throughput: 2.62 tokens/s, Accepted: 263 tokens, Drafted: 340 tokens, Per-position acceptance rate: 0.888, 0.659, Avg Draft acceptance rate: 77.4%
(APIServer pid=1) INFO 06-21 13:41:14 [loggers.py:271] Engine 000: Avg prompt throughput: 0.0 tokens/s, Avg generation throughput: 34.2 tokens/s, Running: 0 reqs, Waiting: 0 reqs, GPU KV cache usage: 11.3%, Prefix cache hit rate: 96.3%
(APIServer pid=1) INFO 06-21 13:41:14 [metrics.py:101] SpecDecoding metrics: Mean acceptance length: 2.58, Accepted throughput: 21.00 tokens/s, Drafted throughput: 26.60 tokens/s, Accepted: 210 tokens, Drafted: 266 tokens, Per-position acceptance rate: 0.910, 0.669, Avg Draft acceptance rate: 78.9%
(APIServer pid=1) INFO:     192.168.1.244:47488 - "POST /v1/chat/completions HTTP/1.1" 200 OK
(APIServer pid=1) INFO:     192.168.1.244:47488 - "POST /v1/chat/completions HTTP/1.1" 200 OK
(APIServer pid=1) INFO:     192.168.1.244:47488 - "POST /v1/chat/completions HTTP/1.1" 200 OK
(APIServer pid=1) INFO 06-21 13:41:24 [loggers.py:271] Engine 000: Avg prompt throughput: 89.5 tokens/s, Avg generation throughput: 17.1 tokens/s, Running: 0 reqs, Waiting: 0 reqs, GPU KV cache usage: 11.6%, Prefix cache hit rate: 96.4%
(APIServer pid=1) INFO 06-21 13:41:24 [metrics.py:101] SpecDecoding metrics: Mean acceptance length: 2.38, Accepted throughput: 9.90 tokens/s, Drafted throughput: 14.40 tokens/s, Accepted: 99 tokens, Drafted: 144 tokens, Per-position acceptance rate: 0.764, 0.611, Avg Draft acceptance rate: 68.8%
(APIServer pid=1) INFO:     192.168.1.244:47488 - "POST /v1/chat/completions HTTP/1.1" 200 OK
(APIServer pid=1) INFO:     192.168.1.244:47488 - "POST /v1/chat/completions HTTP/1.1" 200 OK
(APIServer pid=1) INFO:     192.168.1.244:47488 - "POST /v1/chat/completions HTTP/1.1" 200 OK
(APIServer pid=1) INFO:     192.168.1.244:47488 - "POST /v1/chat/completions HTTP/1.1" 200 OK
(APIServer pid=1) INFO 06-21 13:41:34 [loggers.py:271] Engine 000: Avg prompt throughput: 333.1 tokens/s, Avg generation throughput: 21.1 tokens/s, Running: 1 reqs, Waiting: 0 reqs, GPU KV cache usage: 12.5%, Prefix cache hit rate: 96.8%
(APIServer pid=1) INFO 06-21 13:41:34 [metrics.py:101] SpecDecoding metrics: Mean acceptance length: 2.73, Accepted throughput: 13.30 tokens/s, Drafted throughput: 15.40 tokens/s, Accepted: 133 tokens, Drafted: 154 tokens, Per-position acceptance rate: 0.974, 0.753, Avg Draft acceptance rate: 86.4%
(APIServer pid=1) INFO:     192.168.1.244:47488 - "POST /v1/chat/completions HTTP/1.1" 200 OK
(APIServer pid=1) INFO:     192.168.1.244:47488 - "POST /v1/chat/completions HTTP/1.1" 200 OK
(APIServer pid=1) INFO 06-21 13:41:44 [loggers.py:271] Engine 000: Avg prompt throughput: 113.0 tokens/s, Avg generation throughput: 34.6 tokens/s, Running: 1 reqs, Waiting: 0 reqs, GPU KV cache usage: 12.9%, Prefix cache hit rate: 97.0%
(APIServer pid=1) INFO 06-21 13:41:44 [metrics.py:101] SpecDecoding metrics: Mean acceptance length: 2.63, Accepted throughput: 21.40 tokens/s, Drafted throughput: 26.20 tokens/s, Accepted: 214 tokens, Drafted: 262 tokens, Per-position acceptance rate: 0.931, 0.702, Avg Draft acceptance rate: 81.7%
(APIServer pid=1) INFO 06-21 13:41:54 [loggers.py:271] Engine 000: Avg prompt throughput: 0.0 tokens/s, Avg generation throughput: 45.7 tokens/s, Running: 1 reqs, Waiting: 0 reqs, GPU KV cache usage: 12.9%, Prefix cache hit rate: 97.0%
(APIServer pid=1) INFO 06-21 13:41:54 [metrics.py:101] SpecDecoding metrics: Mean acceptance length: 2.70, Accepted throughput: 28.80 tokens/s, Drafted throughput: 33.80 tokens/s, Accepted: 288 tokens, Drafted: 338 tokens, Per-position acceptance rate: 0.994, 0.710, Avg Draft acceptance rate: 85.2%
(APIServer pid=1) INFO 06-21 13:42:04 [loggers.py:271] Engine 000: Avg prompt throughput: 0.0 tokens/s, Avg generation throughput: 47.4 tokens/s, Running: 1 reqs, Waiting: 0 reqs, GPU KV cache usage: 12.9%, Prefix cache hit rate: 97.0%
(APIServer pid=1) INFO 06-21 13:42:04 [metrics.py:101] SpecDecoding metrics: Mean acceptance length: 2.77, Accepted throughput: 30.30 tokens/s, Drafted throughput: 34.20 tokens/s, Accepted: 303 tokens, Drafted: 342 tokens, Per-position acceptance rate: 1.000, 0.772, Avg Draft acceptance rate: 88.6%
(APIServer pid=1) INFO 06-21 13:42:14 [loggers.py:271] Engine 000: Avg prompt throughput: 0.0 tokens/s, Avg generation throughput: 41.5 tokens/s, Running: 0 reqs, Waiting: 0 reqs, GPU KV cache usage: 12.7%, Prefix cache hit rate: 97.0%
(APIServer pid=1) INFO 06-21 13:42:14 [metrics.py:101] SpecDecoding metrics: Mean acceptance length: 2.72, Accepted throughput: 26.30 tokens/s, Drafted throughput: 30.60 tokens/s, Accepted: 263 tokens, Drafted: 306 tokens, Per-position acceptance rate: 0.974, 0.745, Avg Draft acceptance rate: 85.9%
(APIServer pid=1) INFO:     192.168.1.244:45274 - "POST /v1/chat/completions HTTP/1.1" 200 OK
(APIServer pid=1) INFO 06-21 13:42:24 [loggers.py:271] Engine 000: Avg prompt throughput: 206.1 tokens/s, Avg generation throughput: 11.1 tokens/s, Running: 0 reqs, Waiting: 0 reqs, GPU KV cache usage: 12.9%, Prefix cache hit rate: 97.0%
(APIServer pid=1) INFO 06-21 13:42:24 [metrics.py:101] SpecDecoding metrics: Mean acceptance length: 2.80, Accepted throughput: 7.20 tokens/s, Drafted throughput: 8.00 tokens/s, Accepted: 72 tokens, Drafted: 80 tokens, Per-position acceptance rate: 0.950, 0.850, Avg Draft acceptance rate: 90.0%
(APIServer pid=1) INFO:     192.168.1.244:46824 - "POST /v1/chat/completions HTTP/1.1" 200 OK
(APIServer pid=1) INFO:     192.168.1.244:47962 - "POST /v1/chat/completions HTTP/1.1" 200 OK
(APIServer pid=1) INFO 06-21 13:42:34 [loggers.py:271] Engine 000: Avg prompt throughput: 154.3 tokens/s, Avg generation throughput: 11.6 tokens/s, Running: 1 reqs, Waiting: 0 reqs, GPU KV cache usage: 13.4%, Prefix cache hit rate: 97.1%
(APIServer pid=1) INFO 06-21 13:42:34 [metrics.py:101] SpecDecoding metrics: Mean acceptance length: 2.76, Accepted throughput: 7.40 tokens/s, Drafted throughput: 8.40 tokens/s, Accepted: 74 tokens, Drafted: 84 tokens, Per-position acceptance rate: 1.000, 0.762, Avg Draft acceptance rate: 88.1%
(APIServer pid=1) INFO:     192.168.1.244:46162 - "POST /v1/chat/completions HTTP/1.1" 200 OK
(APIServer pid=1) INFO 06-21 13:42:44 [loggers.py:271] Engine 000: Avg prompt throughput: 94.6 tokens/s, Avg generation throughput: 23.0 tokens/s, Running: 1 reqs, Waiting: 0 reqs, GPU KV cache usage: 13.6%, Prefix cache hit rate: 97.1%
(APIServer pid=1) INFO 06-21 13:42:44 [metrics.py:101] SpecDecoding metrics: Mean acceptance length: 2.83, Accepted throughput: 14.80 tokens/s, Drafted throughput: 16.20 tokens/s, Accepted: 148 tokens, Drafted: 162 tokens, Per-position acceptance rate: 1.000, 0.827, Avg Draft acceptance rate: 91.4%
(APIServer pid=1) INFO:     192.168.1.244:46166 - "POST /v1/chat/completions HTTP/1.1" 200 OK
(APIServer pid=1) INFO 06-21 13:42:54 [loggers.py:271] Engine 000: Avg prompt throughput: 93.6 tokens/s, Avg generation throughput: 24.7 tokens/s, Running: 1 reqs, Waiting: 0 reqs, GPU KV cache usage: 13.8%, Prefix cache hit rate: 97.2%
(APIServer pid=1) INFO 06-21 13:42:54 [metrics.py:101] SpecDecoding metrics: Mean acceptance length: 2.84, Accepted throughput: 16.00 tokens/s, Drafted throughput: 17.40 tokens/s, Accepted: 160 tokens, Drafted: 174 tokens, Per-position acceptance rate: 1.000, 0.839, Avg Draft acceptance rate: 92.0%
(APIServer pid=1) INFO:     192.168.1.244:48440 - "POST /v1/chat/completions HTTP/1.1" 200 OK
(APIServer pid=1) INFO 06-21 13:43:04 [loggers.py:271] Engine 000: Avg prompt throughput: 125.9 tokens/s, Avg generation throughput: 23.5 tokens/s, Running: 1 reqs, Waiting: 0 reqs, GPU KV cache usage: 14.0%, Prefix cache hit rate: 97.2%
(APIServer pid=1) INFO 06-21 13:43:04 [metrics.py:101] SpecDecoding metrics: Mean acceptance length: 2.85, Accepted throughput: 15.20 tokens/s, Drafted throughput: 16.40 tokens/s, Accepted: 152 tokens, Drafted: 164 tokens, Per-position acceptance rate: 1.000, 0.854, Avg Draft acceptance rate: 92.7%
(APIServer pid=1) INFO:     192.168.1.244:46976 - "POST /v1/chat/completions HTTP/1.1" 200 OK
(APIServer pid=1) INFO 06-21 13:43:14 [loggers.py:271] Engine 000: Avg prompt throughput: 114.1 tokens/s, Avg generation throughput: 20.6 tokens/s, Running: 0 reqs, Waiting: 0 reqs, GPU KV cache usage: 14.0%, Prefix cache hit rate: 97.3%
(APIServer pid=1) INFO 06-21 13:43:14 [metrics.py:101] SpecDecoding metrics: Mean acceptance length: 2.64, Accepted throughput: 12.80 tokens/s, Drafted throughput: 15.60 tokens/s, Accepted: 128 tokens, Drafted: 156 tokens, Per-position acceptance rate: 0.949, 0.692, Avg Draft acceptance rate: 82.1%
(APIServer pid=1) INFO:     192.168.1.244:46982 - "POST /v1/chat/completions HTTP/1.1" 200 OK
(APIServer pid=1) INFO 06-21 13:43:24 [loggers.py:271] Engine 000: Avg prompt throughput: 0.0 tokens/s, Avg generation throughput: 0.0 tokens/s, Running: 1 reqs, Waiting: 0 reqs, GPU KV cache usage: 32.2%, Prefix cache hit rate: 96.5%
(APIServer pid=1) INFO 06-21 13:43:34 [loggers.py:271] Engine 000: Avg prompt throughput: 3342.8 tokens/s, Avg generation throughput: 0.1 tokens/s, Running: 1 reqs, Waiting: 0 reqs, GPU KV cache usage: 15.0%, Prefix cache hit rate: 96.5%
(APIServer pid=1) INFO:     192.168.1.244:46982 - "POST /v1/chat/completions HTTP/1.1" 200 OK
(APIServer pid=1) INFO:     192.168.1.244:45910 - "POST /v1/chat/completions HTTP/1.1" 200 OK
(APIServer pid=1) INFO 06-21 13:43:44 [loggers.py:271] Engine 000: Avg prompt throughput: 167.9 tokens/s, Avg generation throughput: 17.0 tokens/s, Running: 0 reqs, Waiting: 0 reqs, GPU KV cache usage: 15.1%, Prefix cache hit rate: 96.5%
(APIServer pid=1) INFO 06-21 13:43:44 [metrics.py:101] SpecDecoding metrics: Mean acceptance length: 2.50, Accepted throughput: 3.40 tokens/s, Drafted throughput: 4.53 tokens/s, Accepted: 102 tokens, Drafted: 136 tokens, Per-position acceptance rate: 0.882, 0.618, Avg Draft acceptance rate: 75.0%
(APIServer pid=1) INFO 06-21 13:43:54 [loggers.py:271] Engine 000: Avg prompt throughput: 0.0 tokens/s, Avg generation throughput: 0.0 tokens/s, Running: 0 reqs, Waiting: 0 reqs, GPU KV cache usage: 15.1%, Prefix cache hit rate: 96.5%
(APIServer pid=1) INFO:     192.168.1.244:48270 - "POST /v1/chat/completions HTTP/1.1" 200 OK
(APIServer pid=1) INFO 06-21 13:44:54 [loggers.py:271] Engine 000: Avg prompt throughput: 344.7 tokens/s, Avg generation throughput: 1.7 tokens/s, Running: 1 reqs, Waiting: 0 reqs, GPU KV cache usage: 15.5%, Prefix cache hit rate: 96.5%
(APIServer pid=1) INFO 06-21 13:44:54 [metrics.py:101] SpecDecoding metrics: Mean acceptance length: 2.00, Accepted throughput: 0.11 tokens/s, Drafted throughput: 0.23 tokens/s, Accepted: 8 tokens, Drafted: 16 tokens, Per-position acceptance rate: 0.625, 0.375, Avg Draft acceptance rate: 50.0%
(APIServer pid=1) INFO 06-21 13:45:04 [loggers.py:271] Engine 000: Avg prompt throughput: 0.0 tokens/s, Avg generation throughput: 41.0 tokens/s, Running: 1 reqs, Waiting: 0 reqs, GPU KV cache usage: 15.5%, Prefix cache hit rate: 96.5%
(APIServer pid=1) INFO 06-21 13:45:04 [metrics.py:101] SpecDecoding metrics: Mean acceptance length: 2.32, Accepted throughput: 23.30 tokens/s, Drafted throughput: 35.40 tokens/s, Accepted: 233 tokens, Drafted: 354 tokens, Per-position acceptance rate: 0.768, 0.548, Avg Draft acceptance rate: 65.8%
(APIServer pid=1) INFO:     192.168.1.244:48270 - "POST /v1/chat/completions HTTP/1.1" 200 OK
(APIServer pid=1) INFO:     192.168.1.244:48270 - "POST /v1/chat/completions HTTP/1.1" 200 OK
(APIServer pid=1) INFO 06-21 13:45:14 [loggers.py:271] Engine 000: Avg prompt throughput: 161.3 tokens/s, Avg generation throughput: 33.8 tokens/s, Running: 1 reqs, Waiting: 0 reqs, GPU KV cache usage: 15.7%, Prefix cache hit rate: 96.5%
(APIServer pid=1) INFO 06-21 13:45:14 [metrics.py:101] SpecDecoding metrics: Mean acceptance length: 2.58, Accepted throughput: 20.60 tokens/s, Drafted throughput: 26.00 tokens/s, Accepted: 206 tokens, Drafted: 260 tokens, Per-position acceptance rate: 0.908, 0.677, Avg Draft acceptance rate: 79.2%
(APIServer pid=1) INFO:     192.168.1.244:48270 - "POST /v1/chat/completions HTTP/1.1" 200 OK
(APIServer pid=1) INFO:     192.168.1.244:48270 - "POST /v1/chat/completions HTTP/1.1" 200 OK
(APIServer pid=1) INFO:     192.168.1.244:48270 - "POST /v1/chat/completions HTTP/1.1" 200 OK
(APIServer pid=1) INFO 06-21 13:45:24 [loggers.py:271] Engine 000: Avg prompt throughput: 160.7 tokens/s, Avg generation throughput: 31.3 tokens/s, Running: 0 reqs, Waiting: 0 reqs, GPU KV cache usage: 15.9%, Prefix cache hit rate: 96.6%
(APIServer pid=1) INFO 06-21 13:45:24 [metrics.py:101] SpecDecoding metrics: Mean acceptance length: 2.54, Accepted throughput: 19.00 tokens/s, Drafted throughput: 24.60 tokens/s, Accepted: 190 tokens, Drafted: 246 tokens, Per-position acceptance rate: 0.878, 0.667, Avg Draft acceptance rate: 77.2%
(APIServer pid=1) INFO:     192.168.1.244:48270 - "POST /v1/chat/completions HTTP/1.1" 200 OK
(APIServer pid=1) INFO 06-21 13:45:34 [loggers.py:271] Engine 000: Avg prompt throughput: 179.4 tokens/s, Avg generation throughput: 38.3 tokens/s, Running: 1 reqs, Waiting: 0 reqs, GPU KV cache usage: 16.4%, Prefix cache hit rate: 96.6%
(APIServer pid=1) INFO 06-21 13:45:34 [metrics.py:101] SpecDecoding metrics: Mean acceptance length: 2.65, Accepted throughput: 23.80 tokens/s, Drafted throughput: 28.80 tokens/s, Accepted: 238 tokens, Drafted: 288 tokens, Per-position acceptance rate: 0.951, 0.701, Avg Draft acceptance rate: 82.6%
(APIServer pid=1) INFO:     192.168.1.244:46730 - "POST /v1/chat/completions HTTP/1.1" 200 OK
(APIServer pid=1) INFO:     192.168.1.244:46730 - "POST /v1/chat/completions HTTP/1.1" 200 OK
(APIServer pid=1) INFO 06-21 13:45:44 [loggers.py:271] Engine 000: Avg prompt throughput: 190.1 tokens/s, Avg generation throughput: 17.3 tokens/s, Running: 1 reqs, Waiting: 0 reqs, GPU KV cache usage: 16.6%, Prefix cache hit rate: 96.7%
(APIServer pid=1) INFO 06-21 13:45:44 [metrics.py:101] SpecDecoding metrics: Mean acceptance length: 2.73, Accepted throughput: 10.90 tokens/s, Drafted throughput: 12.60 tokens/s, Accepted: 109 tokens, Drafted: 126 tokens, Per-position acceptance rate: 1.000, 0.730, Avg Draft acceptance rate: 86.5%
(APIServer pid=1) INFO:     192.168.1.244:45106 - "POST /v1/chat/completions HTTP/1.1" 200 OK
(APIServer pid=1) INFO 06-21 13:45:54 [loggers.py:271] Engine 000: Avg prompt throughput: 100.3 tokens/s, Avg generation throughput: 23.4 tokens/s, Running: 1 reqs, Waiting: 0 reqs, GPU KV cache usage: 16.8%, Prefix cache hit rate: 96.7%
(APIServer pid=1) INFO 06-21 13:45:54 [metrics.py:101] SpecDecoding metrics: Mean acceptance length: 2.82, Accepted throughput: 15.10 tokens/s, Drafted throughput: 16.60 tokens/s, Accepted: 151 tokens, Drafted: 166 tokens, Per-position acceptance rate: 1.000, 0.819, Avg Draft acceptance rate: 91.0%
(APIServer pid=1) INFO:     192.168.1.244:45106 - "POST /v1/chat/completions HTTP/1.1" 200 OK
(APIServer pid=1) INFO:     192.168.1.244:47306 - "POST /v1/chat/completions HTTP/1.1" 200 OK
(APIServer pid=1) INFO 06-21 13:46:04 [loggers.py:271] Engine 000: Avg prompt throughput: 115.7 tokens/s, Avg generation throughput: 17.0 tokens/s, Running: 0 reqs, Waiting: 0 reqs, GPU KV cache usage: 16.9%, Prefix cache hit rate: 96.7%
(APIServer pid=1) INFO 06-21 13:46:04 [metrics.py:101] SpecDecoding metrics: Mean acceptance length: 2.79, Accepted throughput: 10.90 tokens/s, Drafted throughput: 12.20 tokens/s, Accepted: 109 tokens, Drafted: 122 tokens, Per-position acceptance rate: 0.984, 0.803, Avg Draft acceptance rate: 89.3%
(APIServer pid=1) INFO:     192.168.1.244:47306 - "POST /v1/chat/completions HTTP/1.1" 200 OK
(APIServer pid=1) INFO 06-21 13:46:14 [loggers.py:271] Engine 000: Avg prompt throughput: 278.9 tokens/s, Avg generation throughput: 34.8 tokens/s, Running: 0 reqs, Waiting: 0 reqs, GPU KV cache usage: 17.3%, Prefix cache hit rate: 96.7%
(APIServer pid=1) INFO 06-21 13:46:14 [metrics.py:101] SpecDecoding metrics: Mean acceptance length: 2.78, Accepted throughput: 22.30 tokens/s, Drafted throughput: 25.00 tokens/s, Accepted: 223 tokens, Drafted: 250 tokens, Per-position acceptance rate: 0.984, 0.800, Avg Draft acceptance rate: 89.2%
(APIServer pid=1) INFO:     192.168.1.244:46566 - "POST /v1/chat/completions HTTP/1.1" 200 OK
(APIServer pid=1) INFO:     192.168.1.244:46566 - "POST /v1/chat/completions HTTP/1.1" 200 OK
(APIServer pid=1) INFO 06-21 13:46:24 [loggers.py:271] Engine 000: Avg prompt throughput: 219.9 tokens/s, Avg generation throughput: 19.7 tokens/s, Running: 0 reqs, Waiting: 0 reqs, GPU KV cache usage: 17.6%, Prefix cache hit rate: 96.8%
(APIServer pid=1) INFO 06-21 13:46:24 [metrics.py:101] SpecDecoding metrics: Mean acceptance length: 2.61, Accepted throughput: 12.10 tokens/s, Drafted throughput: 15.00 tokens/s, Accepted: 121 tokens, Drafted: 150 tokens, Per-position acceptance rate: 0.907, 0.707, Avg Draft acceptance rate: 80.7%
(APIServer pid=1) INFO:     192.168.1.244:46376 - "POST /v1/chat/completions HTTP/1.1" 200 OK
(APIServer pid=1) INFO:     192.168.1.244:46376 - "POST /v1/chat/completions HTTP/1.1" 200 OK
(APIServer pid=1) INFO 06-21 13:46:34 [loggers.py:271] Engine 000: Avg prompt throughput: 220.0 tokens/s, Avg generation throughput: 17.4 tokens/s, Running: 1 reqs, Waiting: 0 reqs, GPU KV cache usage: 18.1%, Prefix cache hit rate: 96.8%
(APIServer pid=1) INFO 06-21 13:46:34 [metrics.py:101] SpecDecoding metrics: Mean acceptance length: 2.54, Accepted throughput: 10.50 tokens/s, Drafted throughput: 13.60 tokens/s, Accepted: 105 tokens, Drafted: 136 tokens, Per-position acceptance rate: 0.912, 0.632, Avg Draft acceptance rate: 77.2%
(APIServer pid=1) INFO:     192.168.1.244:46376 - "POST /v1/chat/completions HTTP/1.1" 200 OK
(APIServer pid=1) INFO:     192.168.1.244:46376 - "POST /v1/chat/completions HTTP/1.1" 200 OK
(APIServer pid=1) INFO 06-21 13:46:44 [loggers.py:271] Engine 000: Avg prompt throughput: 215.9 tokens/s, Avg generation throughput: 33.2 tokens/s, Running: 1 reqs, Waiting: 0 reqs, GPU KV cache usage: 18.6%, Prefix cache hit rate: 96.9%
(APIServer pid=1) INFO 06-21 13:46:44 [metrics.py:101] SpecDecoding metrics: Mean acceptance length: 2.63, Accepted throughput: 20.50 tokens/s, Drafted throughput: 25.20 tokens/s, Accepted: 205 tokens, Drafted: 252 tokens, Per-position acceptance rate: 0.921, 0.706, Avg Draft acceptance rate: 81.3%
(APIServer pid=1) INFO:     192.168.1.244:46376 - "POST /v1/chat/completions HTTP/1.1" 200 OK
(APIServer pid=1) INFO:     192.168.1.244:46376 - "POST /v1/chat/completions HTTP/1.1" 200 OK
(APIServer pid=1) INFO 06-21 13:46:54 [loggers.py:271] Engine 000: Avg prompt throughput: 207.8 tokens/s, Avg generation throughput: 32.2 tokens/s, Running: 1 reqs, Waiting: 0 reqs, GPU KV cache usage: 18.9%, Prefix cache hit rate: 96.9%
(APIServer pid=1) INFO 06-21 13:46:54 [metrics.py:101] SpecDecoding metrics: Mean acceptance length: 2.63, Accepted throughput: 19.90 tokens/s, Drafted throughput: 24.40 tokens/s, Accepted: 199 tokens, Drafted: 244 tokens, Per-position acceptance rate: 0.959, 0.672, Avg Draft acceptance rate: 81.6%
(APIServer pid=1) INFO:     192.168.1.244:46376 - "POST /v1/chat/completions HTTP/1.1" 200 OK
(APIServer pid=1) INFO:     192.168.1.244:46376 - "POST /v1/chat/completions HTTP/1.1" 200 OK
(APIServer pid=1) INFO 06-21 13:47:04 [loggers.py:271] Engine 000: Avg prompt throughput: 394.7 tokens/s, Avg generation throughput: 27.2 tokens/s, Running: 1 reqs, Waiting: 0 reqs, GPU KV cache usage: 19.3%, Prefix cache hit rate: 96.9%
(APIServer pid=1) INFO 06-21 13:47:04 [metrics.py:101] SpecDecoding metrics: Mean acceptance length: 2.51, Accepted throughput: 16.30 tokens/s, Drafted throughput: 21.60 tokens/s, Accepted: 163 tokens, Drafted: 216 tokens, Per-position acceptance rate: 0.870, 0.639, Avg Draft acceptance rate: 75.5%
(APIServer pid=1) INFO:     192.168.1.244:45134 - "POST /v1/chat/completions HTTP/1.1" 200 OK
(APIServer pid=1) INFO 06-21 13:47:14 [loggers.py:271] Engine 000: Avg prompt throughput: 127.1 tokens/s, Avg generation throughput: 21.7 tokens/s, Running: 1 reqs, Waiting: 0 reqs, GPU KV cache usage: 19.5%, Prefix cache hit rate: 97.0%
(APIServer pid=1) INFO 06-21 13:47:14 [metrics.py:101] SpecDecoding metrics: Mean acceptance length: 2.77, Accepted throughput: 13.80 tokens/s, Drafted throughput: 15.60 tokens/s, Accepted: 138 tokens, Drafted: 156 tokens, Per-position acceptance rate: 0.962, 0.808, Avg Draft acceptance rate: 88.5%
(APIServer pid=1) INFO:     192.168.1.244:45134 - "POST /v1/chat/completions HTTP/1.1" 200 OK
(APIServer pid=1) INFO:     192.168.1.244:45134 - "POST /v1/chat/completions HTTP/1.1" 200 OK
(APIServer pid=1) INFO 06-21 13:47:24 [loggers.py:271] Engine 000: Avg prompt throughput: 262.9 tokens/s, Avg generation throughput: 33.0 tokens/s, Running: 1 reqs, Waiting: 0 reqs, GPU KV cache usage: 19.9%, Prefix cache hit rate: 97.0%
(APIServer pid=1) INFO 06-21 13:47:24 [metrics.py:101] SpecDecoding metrics: Mean acceptance length: 2.80, Accepted throughput: 21.20 tokens/s, Drafted throughput: 23.60 tokens/s, Accepted: 212 tokens, Drafted: 236 tokens, Per-position acceptance rate: 1.000, 0.797, Avg Draft acceptance rate: 89.8%
(APIServer pid=1) INFO:     192.168.1.244:45564 - "POST /v1/chat/completions HTTP/1.1" 200 OK
(APIServer pid=1) INFO 06-21 13:47:34 [loggers.py:271] Engine 000: Avg prompt throughput: 131.5 tokens/s, Avg generation throughput: 19.8 tokens/s, Running: 1 reqs, Waiting: 0 reqs, GPU KV cache usage: 20.0%, Prefix cache hit rate: 97.0%
(APIServer pid=1) INFO 06-21 13:47:34 [metrics.py:101] SpecDecoding metrics: Mean acceptance length: 2.54, Accepted throughput: 12.00 tokens/s, Drafted throughput: 15.60 tokens/s, Accepted: 120 tokens, Drafted: 156 tokens, Per-position acceptance rate: 0.910, 0.628, Avg Draft acceptance rate: 76.9%
(APIServer pid=1) INFO:     192.168.1.244:45564 - "POST /v1/chat/completions HTTP/1.1" 200 OK
(APIServer pid=1) INFO 06-21 13:47:44 [loggers.py:271] Engine 000: Avg prompt throughput: 0.0 tokens/s, Avg generation throughput: 42.8 tokens/s, Running: 0 reqs, Waiting: 0 reqs, GPU KV cache usage: 19.9%, Prefix cache hit rate: 97.0%
(APIServer pid=1) INFO 06-21 13:47:44 [metrics.py:101] SpecDecoding metrics: Mean acceptance length: 2.63, Accepted throughput: 26.49 tokens/s, Drafted throughput: 32.58 tokens/s, Accepted: 265 tokens, Drafted: 326 tokens, Per-position acceptance rate: 0.920, 0.706, Avg Draft acceptance rate: 81.3%
(APIServer pid=1) INFO 06-21 13:47:54 [loggers.py:271] Engine 000: Avg prompt throughput: 123.8 tokens/s, Avg generation throughput: 40.6 tokens/s, Running: 1 reqs, Waiting: 0 reqs, GPU KV cache usage: 20.3%, Prefix cache hit rate: 97.0%
(APIServer pid=1) INFO 06-21 13:47:54 [metrics.py:101] SpecDecoding metrics: Mean acceptance length: 2.63, Accepted throughput: 25.10 tokens/s, Drafted throughput: 30.80 tokens/s, Accepted: 251 tokens, Drafted: 308 tokens, Per-position acceptance rate: 0.955, 0.675, Avg Draft acceptance rate: 81.5%
(APIServer pid=1) INFO 06-21 13:48:04 [loggers.py:271] Engine 000: Avg prompt throughput: 0.0 tokens/s, Avg generation throughput: 28.3 tokens/s, Running: 0 reqs, Waiting: 0 reqs, GPU KV cache usage: 20.1%, Prefix cache hit rate: 97.0%
(APIServer pid=1) INFO 06-21 13:48:04 [metrics.py:101] SpecDecoding metrics: Mean acceptance length: 2.44, Accepted throughput: 16.70 tokens/s, Drafted throughput: 23.20 tokens/s, Accepted: 167 tokens, Drafted: 232 tokens, Per-position acceptance rate: 0.879, 0.560, Avg Draft acceptance rate: 72.0%
(APIServer pid=1) INFO 06-21 13:48:14 [loggers.py:271] Engine 000: Avg prompt throughput: 0.0 tokens/s, Avg generation throughput: 0.0 tokens/s, Running: 0 reqs, Waiting: 0 reqs, GPU KV cache usage: 20.1%, Prefix cache hit rate: 97.0%
(APIServer pid=1) INFO:     192.168.1.244:45380 - "POST /v1/chat/completions HTTP/1.1" 200 OK
(APIServer pid=1) INFO:     192.168.1.244:45380 - "POST /v1/chat/completions HTTP/1.1" 200 OK
(APIServer pid=1) INFO:     192.168.1.244:45380 - "POST /v1/chat/completions HTTP/1.1" 200 OK
(APIServer pid=1) INFO 06-21 13:50:14 [loggers.py:271] Engine 000: Avg prompt throughput: 361.3 tokens/s, Avg generation throughput: 15.6 tokens/s, Running: 1 reqs, Waiting: 0 reqs, GPU KV cache usage: 20.8%, Prefix cache hit rate: 97.1%
(APIServer pid=1) INFO 06-21 13:50:14 [metrics.py:101] SpecDecoding metrics: Mean acceptance length: 2.46, Accepted throughput: 0.71 tokens/s, Drafted throughput: 0.97 tokens/s, Accepted: 92 tokens, Drafted: 126 tokens, Per-position acceptance rate: 0.889, 0.571, Avg Draft acceptance rate: 73.0%
(APIServer pid=1) INFO 06-21 13:50:24 [loggers.py:271] Engine 000: Avg prompt throughput: 0.0 tokens/s, Avg generation throughput: 27.7 tokens/s, Running: 0 reqs, Waiting: 0 reqs, GPU KV cache usage: 20.7%, Prefix cache hit rate: 97.1%
(APIServer pid=1) INFO 06-21 13:50:24 [metrics.py:101] SpecDecoding metrics: Mean acceptance length: 2.26, Accepted throughput: 15.50 tokens/s, Drafted throughput: 24.60 tokens/s, Accepted: 155 tokens, Drafted: 246 tokens, Per-position acceptance rate: 0.772, 0.488, Avg Draft acceptance rate: 63.0%
(APIServer pid=1) INFO 06-21 13:50:34 [loggers.py:271] Engine 000: Avg prompt throughput: 0.0 tokens/s, Avg generation throughput: 0.0 tokens/s, Running: 0 reqs, Waiting: 0 reqs, GPU KV cache usage: 20.7%, Prefix cache hit rate: 97.1%
(APIServer pid=1) INFO:     192.168.1.244:48148 - "POST /v1/chat/completions HTTP/1.1" 200 OK
(APIServer pid=1) INFO:     192.168.1.244:48148 - "POST /v1/chat/completions HTTP/1.1" 200 OK
(APIServer pid=1) INFO 06-21 13:53:14 [loggers.py:271] Engine 000: Avg prompt throughput: 234.4 tokens/s, Avg generation throughput: 34.4 tokens/s, Running: 1 reqs, Waiting: 0 reqs, GPU KV cache usage: 21.2%, Prefix cache hit rate: 97.1%
(APIServer pid=1) INFO 06-21 13:53:14 [metrics.py:101] SpecDecoding metrics: Mean acceptance length: 2.67, Accepted throughput: 1.26 tokens/s, Drafted throughput: 1.51 tokens/s, Accepted: 214 tokens, Drafted: 256 tokens, Per-position acceptance rate: 0.953, 0.719, Avg Draft acceptance rate: 83.6%
(APIServer pid=1) INFO:     192.168.1.244:48148 - "POST /v1/chat/completions HTTP/1.1" 200 OK
(APIServer pid=1) INFO:     192.168.1.244:48148 - "POST /v1/chat/completions HTTP/1.1" 200 OK
(APIServer pid=1) INFO 06-21 13:53:24 [loggers.py:271] Engine 000: Avg prompt throughput: 183.1 tokens/s, Avg generation throughput: 31.6 tokens/s, Running: 1 reqs, Waiting: 0 reqs, GPU KV cache usage: 21.6%, Prefix cache hit rate: 97.2%
(APIServer pid=1) INFO 06-21 13:53:24 [metrics.py:101] SpecDecoding metrics: Mean acceptance length: 2.62, Accepted throughput: 19.60 tokens/s, Drafted throughput: 24.20 tokens/s, Accepted: 196 tokens, Drafted: 242 tokens, Per-position acceptance rate: 0.926, 0.694, Avg Draft acceptance rate: 81.0%
(APIServer pid=1) INFO 06-21 13:53:34 [loggers.py:271] Engine 000: Avg prompt throughput: 0.0 tokens/s, Avg generation throughput: 39.5 tokens/s, Running: 0 reqs, Waiting: 0 reqs, GPU KV cache usage: 21.4%, Prefix cache hit rate: 97.2%
(APIServer pid=1) INFO 06-21 13:53:34 [metrics.py:101] SpecDecoding metrics: Mean acceptance length: 2.64, Accepted throughput: 24.60 tokens/s, Drafted throughput: 30.00 tokens/s, Accepted: 246 tokens, Drafted: 300 tokens, Per-position acceptance rate: 0.940, 0.700, Avg Draft acceptance rate: 82.0%
(APIServer pid=1) INFO 06-21 13:53:44 [loggers.py:271] Engine 000: Avg prompt throughput: 0.0 tokens/s, Avg generation throughput: 0.0 tokens/s, Running: 0 reqs, Waiting: 0 reqs, GPU KV cache usage: 21.4%, Prefix cache hit rate: 97.2%
(APIServer pid=1) INFO:     192.168.1.244:48150 - "POST /v1/chat/completions HTTP/1.1" 200 OK
(APIServer pid=1) INFO:     192.168.1.244:48150 - "POST /v1/chat/completions HTTP/1.1" 200 OK
(APIServer pid=1) INFO 06-21 13:54:14 [loggers.py:271] Engine 000: Avg prompt throughput: 375.8 tokens/s, Avg generation throughput: 19.5 tokens/s, Running: 1 reqs, Waiting: 0 reqs, GPU KV cache usage: 22.1%, Prefix cache hit rate: 97.2%
(APIServer pid=1) INFO 06-21 13:54:14 [metrics.py:101] SpecDecoding metrics: Mean acceptance length: 2.10, Accepted throughput: 2.52 tokens/s, Drafted throughput: 4.60 tokens/s, Accepted: 101 tokens, Drafted: 184 tokens, Per-position acceptance rate: 0.717, 0.380, Avg Draft acceptance rate: 54.9%
(APIServer pid=1) INFO:     192.168.1.244:48150 - "POST /v1/chat/completions HTTP/1.1" 200 OK
(APIServer pid=1) INFO 06-21 13:54:24 [loggers.py:271] Engine 000: Avg prompt throughput: 304.5 tokens/s, Avg generation throughput: 29.0 tokens/s, Running: 1 reqs, Waiting: 0 reqs, GPU KV cache usage: 22.3%, Prefix cache hit rate: 97.2%
(APIServer pid=1) INFO 06-21 13:54:24 [metrics.py:101] SpecDecoding metrics: Mean acceptance length: 2.25, Accepted throughput: 16.10 tokens/s, Drafted throughput: 25.80 tokens/s, Accepted: 161 tokens, Drafted: 258 tokens, Per-position acceptance rate: 0.775, 0.473, Avg Draft acceptance rate: 62.4%
(APIServer pid=1) INFO 06-21 13:54:34 [loggers.py:271] Engine 000: Avg prompt throughput: 0.0 tokens/s, Avg generation throughput: 2.2 tokens/s, Running: 0 reqs, Waiting: 0 reqs, GPU KV cache usage: 22.2%, Prefix cache hit rate: 97.2%
(APIServer pid=1) INFO 06-21 13:54:34 [metrics.py:101] SpecDecoding metrics: Mean acceptance length: 2.88, Accepted throughput: 1.50 tokens/s, Drafted throughput: 1.60 tokens/s, Accepted: 15 tokens, Drafted: 16 tokens, Per-position acceptance rate: 1.000, 0.875, Avg Draft acceptance rate: 93.8%
(APIServer pid=1) INFO 06-21 13:54:44 [loggers.py:271] Engine 000: Avg prompt throughput: 0.0 tokens/s, Avg generation throughput: 0.0 tokens/s, Running: 0 reqs, Waiting: 0 reqs, GPU KV cache usage: 22.2%, Prefix cache hit rate: 97.2%
(APIServer pid=1) INFO:     192.168.1.244:45606 - "POST /v1/chat/completions HTTP/1.1" 200 OK
(APIServer pid=1) INFO 06-21 13:59:34 [loggers.py:271] Engine 000: Avg prompt throughput: 4727.4 tokens/s, Avg generation throughput: 4.2 tokens/s, Running: 1 reqs, Waiting: 0 reqs, GPU KV cache usage: 23.5%, Prefix cache hit rate: 96.6%
(APIServer pid=1) INFO 06-21 13:59:34 [metrics.py:101] SpecDecoding metrics: Mean acceptance length: 1.86, Accepted throughput: 0.06 tokens/s, Drafted throughput: 0.15 tokens/s, Accepted: 19 tokens, Drafted: 44 tokens, Per-position acceptance rate: 0.545, 0.318, Avg Draft acceptance rate: 43.2%
(APIServer pid=1) INFO:     192.168.1.244:45606 - "POST /v1/chat/completions HTTP/1.1" 200 OK
(APIServer pid=1) INFO 06-21 13:59:44 [loggers.py:271] Engine 000: Avg prompt throughput: 84.7 tokens/s, Avg generation throughput: 19.9 tokens/s, Running: 0 reqs, Waiting: 0 reqs, GPU KV cache usage: 23.5%, Prefix cache hit rate: 96.6%
(APIServer pid=1) INFO 06-21 13:59:44 [metrics.py:101] SpecDecoding metrics: Mean acceptance length: 2.15, Accepted throughput: 10.70 tokens/s, Drafted throughput: 18.60 tokens/s, Accepted: 107 tokens, Drafted: 186 tokens, Per-position acceptance rate: 0.763, 0.387, Avg Draft acceptance rate: 57.5%
(APIServer pid=1) INFO 06-21 13:59:54 [loggers.py:271] Engine 000: Avg prompt throughput: 0.0 tokens/s, Avg generation throughput: 0.0 tokens/s, Running: 0 reqs, Waiting: 0 reqs, GPU KV cache usage: 23.5%, Prefix cache hit rate: 96.6%
(APIServer pid=1) INFO:     192.168.1.244:46014 - "POST /v1/chat/completions HTTP/1.1" 200 OK
(APIServer pid=1) INFO 06-21 14:09:34 [loggers.py:271] Engine 000: Avg prompt throughput: 507.1 tokens/s, Avg generation throughput: 13.4 tokens/s, Running: 1 reqs, Waiting: 0 reqs, GPU KV cache usage: 24.0%, Prefix cache hit rate: 96.6%
(APIServer pid=1) INFO 06-21 14:09:34 [metrics.py:101] SpecDecoding metrics: Mean acceptance length: 2.46, Accepted throughput: 0.13 tokens/s, Drafted throughput: 0.18 tokens/s, Accepted: 79 tokens, Drafted: 108 tokens, Per-position acceptance rate: 0.889, 0.574, Avg Draft acceptance rate: 73.1%
(APIServer pid=1) INFO 06-21 14:09:44 [loggers.py:271] Engine 000: Avg prompt throughput: 0.0 tokens/s, Avg generation throughput: 36.8 tokens/s, Running: 0 reqs, Waiting: 0 reqs, GPU KV cache usage: 23.8%, Prefix cache hit rate: 96.6%
(APIServer pid=1) INFO 06-21 14:09:44 [metrics.py:101] SpecDecoding metrics: Mean acceptance length: 2.27, Accepted throughput: 20.60 tokens/s, Drafted throughput: 32.40 tokens/s, Accepted: 206 tokens, Drafted: 324 tokens, Per-position acceptance rate: 0.778, 0.494, Avg Draft acceptance rate: 63.6%
(APIServer pid=1) INFO 06-21 14:09:54 [loggers.py:271] Engine 000: Avg prompt throughput: 0.0 tokens/s, Avg generation throughput: 0.0 tokens/s, Running: 0 reqs, Waiting: 0 reqs, GPU KV cache usage: 23.8%, Prefix cache hit rate: 96.6%
(APIServer pid=1) INFO:     192.168.1.244:48470 - "POST /v1/chat/completions HTTP/1.1" 200 OK
(APIServer pid=1) INFO 06-21 14:10:44 [loggers.py:271] Engine 000: Avg prompt throughput: 85.8 tokens/s, Avg generation throughput: 3.3 tokens/s, Running: 1 reqs, Waiting: 0 reqs, GPU KV cache usage: 24.1%, Prefix cache hit rate: 96.6%
(APIServer pid=1) INFO 06-21 14:10:44 [metrics.py:101] SpecDecoding metrics: Mean acceptance length: 2.46, Accepted throughput: 0.32 tokens/s, Drafted throughput: 0.43 tokens/s, Accepted: 19 tokens, Drafted: 26 tokens, Per-position acceptance rate: 0.769, 0.692, Avg Draft acceptance rate: 73.1%
(APIServer pid=1) INFO 06-21 14:10:54 [loggers.py:271] Engine 000: Avg prompt throughput: 0.0 tokens/s, Avg generation throughput: 39.0 tokens/s, Running: 1 reqs, Waiting: 0 reqs, GPU KV cache usage: 24.1%, Prefix cache hit rate: 96.6%
(APIServer pid=1) INFO 06-21 14:10:54 [metrics.py:101] SpecDecoding metrics: Mean acceptance length: 2.19, Accepted throughput: 21.20 tokens/s, Drafted throughput: 35.60 tokens/s, Accepted: 212 tokens, Drafted: 356 tokens, Per-position acceptance rate: 0.730, 0.461, Avg Draft acceptance rate: 59.6%
(APIServer pid=1) INFO 06-21 14:11:04 [loggers.py:271] Engine 000: Avg prompt throughput: 0.0 tokens/s, Avg generation throughput: 5.3 tokens/s, Running: 0 reqs, Waiting: 0 reqs, GPU KV cache usage: 24.0%, Prefix cache hit rate: 96.6%
(APIServer pid=1) INFO 06-21 14:11:04 [metrics.py:101] SpecDecoding metrics: Mean acceptance length: 2.30, Accepted throughput: 3.00 tokens/s, Drafted throughput: 4.60 tokens/s, Accepted: 30 tokens, Drafted: 46 tokens, Per-position acceptance rate: 0.826, 0.478, Avg Draft acceptance rate: 65.2%
(APIServer pid=1) INFO 06-21 14:11:14 [loggers.py:271] Engine 000: Avg prompt throughput: 0.0 tokens/s, Avg generation throughput: 0.0 tokens/s, Running: 0 reqs, Waiting: 0 reqs, GPU KV cache usage: 24.0%, Prefix cache hit rate: 96.6%
(APIServer pid=1) INFO:     192.168.1.244:47444 - "POST /v1/chat/completions HTTP/1.1" 200 OK
(APIServer pid=1) INFO:     192.168.1.244:47444 - "POST /v1/chat/completions HTTP/1.1" 200 OK
(APIServer pid=1) INFO:     192.168.1.244:47444 - "POST /v1/chat/completions HTTP/1.1" 200 OK
(APIServer pid=1) INFO:     192.168.1.244:47444 - "POST /v1/chat/completions HTTP/1.1" 200 OK
(APIServer pid=1) INFO 06-21 14:16:14 [loggers.py:271] Engine 000: Avg prompt throughput: 577.7 tokens/s, Avg generation throughput: 17.5 tokens/s, Running: 1 reqs, Waiting: 0 reqs, GPU KV cache usage: 24.8%, Prefix cache hit rate: 96.6%
(APIServer pid=1) INFO 06-21 14:16:14 [metrics.py:101] SpecDecoding metrics: Mean acceptance length: 2.73, Accepted throughput: 0.36 tokens/s, Drafted throughput: 0.41 tokens/s, Accepted: 111 tokens, Drafted: 128 tokens, Per-position acceptance rate: 0.969, 0.766, Avg Draft acceptance rate: 86.7%
(APIServer pid=1) INFO:     192.168.1.244:47444 - "POST /v1/chat/completions HTTP/1.1" 200 OK
(APIServer pid=1) INFO:     192.168.1.244:47444 - "POST /v1/chat/completions HTTP/1.1" 200 OK
(APIServer pid=1) INFO:     192.168.1.244:47444 - "POST /v1/chat/completions HTTP/1.1" 200 OK
(APIServer pid=1) INFO:     192.168.1.244:47444 - "POST /v1/chat/completions HTTP/1.1" 200 OK
(APIServer pid=1) INFO 06-21 14:16:24 [loggers.py:271] Engine 000: Avg prompt throughput: 260.6 tokens/s, Avg generation throughput: 20.1 tokens/s, Running: 0 reqs, Waiting: 0 reqs, GPU KV cache usage: 25.2%, Prefix cache hit rate: 96.7%
(APIServer pid=1) INFO 06-21 14:16:24 [metrics.py:101] SpecDecoding metrics: Mean acceptance length: 2.53, Accepted throughput: 12.10 tokens/s, Drafted throughput: 15.80 tokens/s, Accepted: 121 tokens, Drafted: 158 tokens, Per-position acceptance rate: 0.886, 0.646, Avg Draft acceptance rate: 76.6%
(APIServer pid=1) INFO:     192.168.1.244:47444 - "POST /v1/chat/completions HTTP/1.1" 200 OK
(APIServer pid=1) INFO 06-21 14:16:34 [loggers.py:271] Engine 000: Avg prompt throughput: 302.2 tokens/s, Avg generation throughput: 32.7 tokens/s, Running: 1 reqs, Waiting: 0 reqs, GPU KV cache usage: 25.9%, Prefix cache hit rate: 96.7%
(APIServer pid=1) INFO 06-21 14:16:34 [metrics.py:101] SpecDecoding metrics: Mean acceptance length: 2.33, Accepted throughput: 18.60 tokens/s, Drafted throughput: 28.00 tokens/s, Accepted: 186 tokens, Drafted: 280 tokens, Per-position acceptance rate: 0.807, 0.521, Avg Draft acceptance rate: 66.4%
(APIServer pid=1) INFO:     192.168.1.244:47444 - "POST /v1/chat/completions HTTP/1.1" 200 OK
(APIServer pid=1) INFO 06-21 14:16:44 [loggers.py:271] Engine 000: Avg prompt throughput: 121.0 tokens/s, Avg generation throughput: 35.0 tokens/s, Running: 1 reqs, Waiting: 0 reqs, GPU KV cache usage: 26.1%, Prefix cache hit rate: 96.7%
(APIServer pid=1) INFO 06-21 14:16:44 [metrics.py:101] SpecDecoding metrics: Mean acceptance length: 2.36, Accepted throughput: 20.20 tokens/s, Drafted throughput: 29.60 tokens/s, Accepted: 202 tokens, Drafted: 296 tokens, Per-position acceptance rate: 0.831, 0.534, Avg Draft acceptance rate: 68.2%
(APIServer pid=1) INFO 06-21 14:16:54 [loggers.py:271] Engine 000: Avg prompt throughput: 0.0 tokens/s, Avg generation throughput: 20.4 tokens/s, Running: 0 reqs, Waiting: 0 reqs, GPU KV cache usage: 25.9%, Prefix cache hit rate: 96.7%
(APIServer pid=1) INFO 06-21 14:16:54 [metrics.py:101] SpecDecoding metrics: Mean acceptance length: 2.19, Accepted throughput: 11.10 tokens/s, Drafted throughput: 18.60 tokens/s, Accepted: 111 tokens, Drafted: 186 tokens, Per-position acceptance rate: 0.742, 0.452, Avg Draft acceptance rate: 59.7%
(APIServer pid=1) INFO 06-21 14:17:04 [loggers.py:271] Engine 000: Avg prompt throughput: 0.0 tokens/s, Avg generation throughput: 0.0 tokens/s, Running: 0 reqs, Waiting: 0 reqs, GPU KV cache usage: 25.9%, Prefix cache hit rate: 96.7%
(APIServer pid=1) INFO:     192.168.1.244:48382 - "POST /v1/chat/completions HTTP/1.1" 200 OK
(APIServer pid=1) INFO 06-21 14:18:04 [loggers.py:271] Engine 000: Avg prompt throughput: 86.0 tokens/s, Avg generation throughput: 35.4 tokens/s, Running: 1 reqs, Waiting: 0 reqs, GPU KV cache usage: 26.2%, Prefix cache hit rate: 96.8%
(APIServer pid=1) INFO 06-21 14:18:04 [metrics.py:101] SpecDecoding metrics: Mean acceptance length: 2.23, Accepted throughput: 2.79 tokens/s, Drafted throughput: 4.51 tokens/s, Accepted: 195 tokens, Drafted: 316 tokens, Per-position acceptance rate: 0.778, 0.456, Avg Draft acceptance rate: 61.7%
(APIServer pid=1) INFO 06-21 14:18:14 [loggers.py:271] Engine 000: Avg prompt throughput: 0.0 tokens/s, Avg generation throughput: 23.9 tokens/s, Running: 0 reqs, Waiting: 0 reqs, GPU KV cache usage: 26.1%, Prefix cache hit rate: 96.8%
(APIServer pid=1) INFO 06-21 14:18:14 [metrics.py:101] SpecDecoding metrics: Mean acceptance length: 2.30, Accepted throughput: 13.50 tokens/s, Drafted throughput: 20.80 tokens/s, Accepted: 135 tokens, Drafted: 208 tokens, Per-position acceptance rate: 0.788, 0.510, Avg Draft acceptance rate: 64.9%
(APIServer pid=1) INFO 06-21 14:18:24 [loggers.py:271] Engine 000: Avg prompt throughput: 0.0 tokens/s, Avg generation throughput: 0.0 tokens/s, Running: 0 reqs, Waiting: 0 reqs, GPU KV cache usage: 26.1%, Prefix cache hit rate: 96.8%
(APIServer pid=1) INFO:     192.168.1.244:46922 - "POST /v1/chat/completions HTTP/1.1" 200 OK
(APIServer pid=1) INFO 06-21 14:19:14 [loggers.py:271] Engine 000: Avg prompt throughput: 83.6 tokens/s, Avg generation throughput: 32.0 tokens/s, Running: 1 reqs, Waiting: 0 reqs, GPU KV cache usage: 26.4%, Prefix cache hit rate: 96.8%
(APIServer pid=1) INFO 06-21 14:19:14 [metrics.py:101] SpecDecoding metrics: Mean acceptance length: 2.47, Accepted throughput: 3.17 tokens/s, Drafted throughput: 4.30 tokens/s, Accepted: 190 tokens, Drafted: 258 tokens, Per-position acceptance rate: 0.915, 0.558, Avg Draft acceptance rate: 73.6%
(APIServer pid=1) INFO 06-21 14:19:24 [loggers.py:271] Engine 000: Avg prompt throughput: 0.0 tokens/s, Avg generation throughput: 18.1 tokens/s, Running: 0 reqs, Waiting: 0 reqs, GPU KV cache usage: 26.2%, Prefix cache hit rate: 96.8%
(APIServer pid=1) INFO 06-21 14:19:24 [metrics.py:101] SpecDecoding metrics: Mean acceptance length: 2.29, Accepted throughput: 10.20 tokens/s, Drafted throughput: 15.80 tokens/s, Accepted: 102 tokens, Drafted: 158 tokens, Per-position acceptance rate: 0.785, 0.506, Avg Draft acceptance rate: 64.6%
(APIServer pid=1) INFO 06-21 14:19:34 [loggers.py:271] Engine 000: Avg prompt throughput: 0.0 tokens/s, Avg generation throughput: 0.0 tokens/s, Running: 0 reqs, Waiting: 0 reqs, GPU KV cache usage: 26.2%, Prefix cache hit rate: 96.8%
(APIServer pid=1) INFO:     192.168.1.244:47948 - "POST /v1/chat/completions HTTP/1.1" 200 OK
(APIServer pid=1) INFO 06-21 14:20:04 [loggers.py:271] Engine 000: Avg prompt throughput: 94.1 tokens/s, Avg generation throughput: 40.6 tokens/s, Running: 1 reqs, Waiting: 0 reqs, GPU KV cache usage: 26.6%, Prefix cache hit rate: 96.8%
(APIServer pid=1) INFO 06-21 14:20:04 [metrics.py:101] SpecDecoding metrics: Mean acceptance length: 2.66, Accepted throughput: 6.32 tokens/s, Drafted throughput: 7.60 tokens/s, Accepted: 253 tokens, Drafted: 304 tokens, Per-position acceptance rate: 0.967, 0.697, Avg Draft acceptance rate: 83.2%
(APIServer pid=1) INFO 06-21 14:20:14 [loggers.py:271] Engine 000: Avg prompt throughput: 0.0 tokens/s, Avg generation throughput: 18.4 tokens/s, Running: 0 reqs, Waiting: 0 reqs, GPU KV cache usage: 26.4%, Prefix cache hit rate: 96.8%
(APIServer pid=1) INFO 06-21 14:20:14 [metrics.py:101] SpecDecoding metrics: Mean acceptance length: 2.47, Accepted throughput: 11.00 tokens/s, Drafted throughput: 15.00 tokens/s, Accepted: 110 tokens, Drafted: 150 tokens, Per-position acceptance rate: 0.867, 0.600, Avg Draft acceptance rate: 73.3%
(APIServer pid=1) INFO:     192.168.1.244:46018 - "POST /v1/chat/completions HTTP/1.1" 200 OK
(APIServer pid=1) INFO:     192.168.1.244:46018 - "POST /v1/chat/completions HTTP/1.1" 200 OK
(APIServer pid=1) INFO 06-21 14:20:24 [loggers.py:271] Engine 000: Avg prompt throughput: 111.9 tokens/s, Avg generation throughput: 6.4 tokens/s, Running: 1 reqs, Waiting: 0 reqs, GPU KV cache usage: 26.9%, Prefix cache hit rate: 96.9%
(APIServer pid=1) INFO 06-21 14:20:24 [metrics.py:101] SpecDecoding metrics: Mean acceptance length: 2.30, Accepted throughput: 3.50 tokens/s, Drafted throughput: 5.40 tokens/s, Accepted: 35 tokens, Drafted: 54 tokens, Per-position acceptance rate: 0.852, 0.444, Avg Draft acceptance rate: 64.8%
(APIServer pid=1) INFO:     192.168.1.244:48558 - "POST /v1/chat/completions HTTP/1.1" 200 OK
(APIServer pid=1) INFO 06-21 14:20:34 [loggers.py:271] Engine 000: Avg prompt throughput: 56.0 tokens/s, Avg generation throughput: 23.9 tokens/s, Running: 1 reqs, Waiting: 0 reqs, GPU KV cache usage: 27.1%, Prefix cache hit rate: 96.9%
(APIServer pid=1) INFO 06-21 14:20:34 [metrics.py:101] SpecDecoding metrics: Mean acceptance length: 2.72, Accepted throughput: 15.10 tokens/s, Drafted throughput: 17.60 tokens/s, Accepted: 151 tokens, Drafted: 176 tokens, Per-position acceptance rate: 0.977, 0.739, Avg Draft acceptance rate: 85.8%
(APIServer pid=1) INFO:     192.168.1.244:48006 - "POST /v1/chat/completions HTTP/1.1" 200 OK
(APIServer pid=1) INFO 06-21 14:20:44 [loggers.py:271] Engine 000: Avg prompt throughput: 74.3 tokens/s, Avg generation throughput: 23.4 tokens/s, Running: 1 reqs, Waiting: 0 reqs, GPU KV cache usage: 27.3%, Prefix cache hit rate: 96.9%
(APIServer pid=1) INFO 06-21 14:20:44 [metrics.py:101] SpecDecoding metrics: Mean acceptance length: 2.72, Accepted throughput: 14.80 tokens/s, Drafted throughput: 17.20 tokens/s, Accepted: 148 tokens, Drafted: 172 tokens, Per-position acceptance rate: 0.965, 0.756, Avg Draft acceptance rate: 86.0%
(APIServer pid=1) INFO 06-21 14:20:54 [loggers.py:271] Engine 000: Avg prompt throughput: 0.0 tokens/s, Avg generation throughput: 25.4 tokens/s, Running: 0 reqs, Waiting: 0 reqs, GPU KV cache usage: 27.2%, Prefix cache hit rate: 96.9%
(APIServer pid=1) INFO 06-21 14:20:54 [metrics.py:101] SpecDecoding metrics: Mean acceptance length: 2.70, Accepted throughput: 16.00 tokens/s, Drafted throughput: 18.80 tokens/s, Accepted: 160 tokens, Drafted: 188 tokens, Per-position acceptance rate: 0.979, 0.723, Avg Draft acceptance rate: 85.1%
(APIServer pid=1) INFO 06-21 14:21:04 [loggers.py:271] Engine 000: Avg prompt throughput: 0.0 tokens/s, Avg generation throughput: 0.0 tokens/s, Running: 0 reqs, Waiting: 0 reqs, GPU KV cache usage: 27.2%, Prefix cache hit rate: 96.9%
(APIServer pid=1) INFO:     192.168.1.244:45544 - "POST /v1/chat/completions HTTP/1.1" 200 OK
(APIServer pid=1) INFO:     192.168.1.244:45544 - "POST /v1/chat/completions HTTP/1.1" 200 OK
(APIServer pid=1) INFO:     192.168.1.244:45544 - "POST /v1/chat/completions HTTP/1.1" 200 OK
(APIServer pid=1) INFO 06-21 14:21:24 [loggers.py:271] Engine 000: Avg prompt throughput: 381.1 tokens/s, Avg generation throughput: 17.7 tokens/s, Running: 0 reqs, Waiting: 0 reqs, GPU KV cache usage: 27.5%, Prefix cache hit rate: 96.9%
(APIServer pid=1) INFO 06-21 14:21:24 [metrics.py:101] SpecDecoding metrics: Mean acceptance length: 2.64, Accepted throughput: 3.67 tokens/s, Drafted throughput: 4.47 tokens/s, Accepted: 110 tokens, Drafted: 134 tokens, Per-position acceptance rate: 0.985, 0.657, Avg Draft acceptance rate: 82.1%
(APIServer pid=1) INFO 06-21 14:21:34 [loggers.py:271] Engine 000: Avg prompt throughput: 193.3 tokens/s, Avg generation throughput: 40.7 tokens/s, Running: 1 reqs, Waiting: 0 reqs, GPU KV cache usage: 27.8%, Prefix cache hit rate: 96.9%
(APIServer pid=1) INFO 06-21 14:21:34 [metrics.py:101] SpecDecoding metrics: Mean acceptance length: 2.54, Accepted throughput: 24.60 tokens/s, Drafted throughput: 32.00 tokens/s, Accepted: 246 tokens, Drafted: 320 tokens, Per-position acceptance rate: 0.894, 0.644, Avg Draft acceptance rate: 76.9%
(APIServer pid=1) INFO:     192.168.1.244:45544 - "POST /v1/chat/completions HTTP/1.1" 200 OK
(APIServer pid=1) INFO 06-21 14:21:44 [loggers.py:271] Engine 000: Avg prompt throughput: 69.7 tokens/s, Avg generation throughput: 24.9 tokens/s, Running: 0 reqs, Waiting: 0 reqs, GPU KV cache usage: 27.9%, Prefix cache hit rate: 97.0%
(APIServer pid=1) INFO 06-21 14:21:44 [metrics.py:101] SpecDecoding metrics: Mean acceptance length: 2.67, Accepted throughput: 15.70 tokens/s, Drafted throughput: 18.80 tokens/s, Accepted: 157 tokens, Drafted: 188 tokens, Per-position acceptance rate: 0.968, 0.702, Avg Draft acceptance rate: 83.5%
(APIServer pid=1) INFO:     192.168.1.244:48214 - "POST /v1/chat/completions HTTP/1.1" 200 OK
(APIServer pid=1) INFO:     192.168.1.244:46952 - "POST /v1/chat/completions HTTP/1.1" 200 OK
(APIServer pid=1) INFO 06-21 14:21:54 [loggers.py:271] Engine 000: Avg prompt throughput: 159.8 tokens/s, Avg generation throughput: 11.1 tokens/s, Running: 1 reqs, Waiting: 0 reqs, GPU KV cache usage: 28.3%, Prefix cache hit rate: 97.0%
(APIServer pid=1) INFO 06-21 14:21:54 [metrics.py:101] SpecDecoding metrics: Mean acceptance length: 2.50, Accepted throughput: 6.60 tokens/s, Drafted throughput: 8.80 tokens/s, Accepted: 66 tokens, Drafted: 88 tokens, Per-position acceptance rate: 0.909, 0.591, Avg Draft acceptance rate: 75.0%
(APIServer pid=1) INFO:     192.168.1.244:46952 - "POST /v1/chat/completions HTTP/1.1" 200 OK
(APIServer pid=1) INFO 06-21 14:22:04 [loggers.py:271] Engine 000: Avg prompt throughput: 84.9 tokens/s, Avg generation throughput: 38.8 tokens/s, Running: 1 reqs, Waiting: 0 reqs, GPU KV cache usage: 28.5%, Prefix cache hit rate: 97.0%
(APIServer pid=1) INFO 06-21 14:22:04 [metrics.py:101] SpecDecoding metrics: Mean acceptance length: 2.64, Accepted throughput: 24.10 tokens/s, Drafted throughput: 29.40 tokens/s, Accepted: 241 tokens, Drafted: 294 tokens, Per-position acceptance rate: 0.946, 0.694, Avg Draft acceptance rate: 82.0%
(APIServer pid=1) INFO:     192.168.1.244:44970 - "POST /v1/chat/completions HTTP/1.1" 200 OK
(APIServer pid=1) INFO 06-21 14:22:14 [loggers.py:271] Engine 000: Avg prompt throughput: 107.9 tokens/s, Avg generation throughput: 18.4 tokens/s, Running: 1 reqs, Waiting: 0 reqs, GPU KV cache usage: 28.7%, Prefix cache hit rate: 97.0%
(APIServer pid=1) INFO 06-21 14:22:14 [metrics.py:101] SpecDecoding metrics: Mean acceptance length: 2.47, Accepted throughput: 11.00 tokens/s, Drafted throughput: 15.00 tokens/s, Accepted: 110 tokens, Drafted: 150 tokens, Per-position acceptance rate: 0.867, 0.600, Avg Draft acceptance rate: 73.3%
(APIServer pid=1) INFO:     192.168.1.244:44970 - "POST /v1/chat/completions HTTP/1.1" 200 OK
(APIServer pid=1) INFO:     192.168.1.244:44970 - "POST /v1/chat/completions HTTP/1.1" 200 OK
(APIServer pid=1) INFO 06-21 14:22:24 [loggers.py:271] Engine 000: Avg prompt throughput: 106.2 tokens/s, Avg generation throughput: 18.0 tokens/s, Running: 0 reqs, Waiting: 0 reqs, GPU KV cache usage: 28.7%, Prefix cache hit rate: 97.1%
(APIServer pid=1) INFO 06-21 14:22:24 [metrics.py:101] SpecDecoding metrics: Mean acceptance length: 2.32, Accepted throughput: 10.20 tokens/s, Drafted throughput: 15.40 tokens/s, Accepted: 102 tokens, Drafted: 154 tokens, Per-position acceptance rate: 0.792, 0.532, Avg Draft acceptance rate: 66.2%
(APIServer pid=1) INFO 06-21 14:22:34 [loggers.py:271] Engine 000: Avg prompt throughput: 0.0 tokens/s, Avg generation throughput: 0.0 tokens/s, Running: 1 reqs, Waiting: 0 reqs, GPU KV cache usage: 47.2%, Prefix cache hit rate: 96.6%
(APIServer pid=1) INFO 06-21 14:22:44 [loggers.py:271] Engine 000: Avg prompt throughput: 4812.4 tokens/s, Avg generation throughput: 1.5 tokens/s, Running: 1 reqs, Waiting: 0 reqs, GPU KV cache usage: 30.0%, Prefix cache hit rate: 96.6%
(APIServer pid=1) INFO 06-21 14:22:44 [metrics.py:101] SpecDecoding metrics: Mean acceptance length: 2.80, Accepted throughput: 0.45 tokens/s, Drafted throughput: 0.50 tokens/s, Accepted: 9 tokens, Drafted: 10 tokens, Per-position acceptance rate: 1.000, 0.800, Avg Draft acceptance rate: 90.0%
(APIServer pid=1) INFO:     192.168.1.244:46514 - "POST /v1/chat/completions HTTP/1.1" 200 OK
(APIServer pid=1) INFO 06-21 14:22:54 [loggers.py:271] Engine 000: Avg prompt throughput: 81.5 tokens/s, Avg generation throughput: 20.9 tokens/s, Running: 0 reqs, Waiting: 0 reqs, GPU KV cache usage: 30.0%, Prefix cache hit rate: 96.6%
(APIServer pid=1) INFO 06-21 14:22:54 [metrics.py:101] SpecDecoding metrics: Mean acceptance length: 2.62, Accepted throughput: 13.00 tokens/s, Drafted throughput: 16.00 tokens/s, Accepted: 130 tokens, Drafted: 160 tokens, Per-position acceptance rate: 0.950, 0.675, Avg Draft acceptance rate: 81.2%
(APIServer pid=1) INFO:     192.168.1.244:46514 - "POST /v1/chat/completions HTTP/1.1" 200 OK
(APIServer pid=1) INFO 06-21 14:23:04 [loggers.py:271] Engine 000: Avg prompt throughput: 483.9 tokens/s, Avg generation throughput: 28.3 tokens/s, Running: 1 reqs, Waiting: 0 reqs, GPU KV cache usage: 30.5%, Prefix cache hit rate: 96.6%
(APIServer pid=1) INFO 06-21 14:23:04 [metrics.py:101] SpecDecoding metrics: Mean acceptance length: 2.31, Accepted throughput: 16.00 tokens/s, Drafted throughput: 24.40 tokens/s, Accepted: 160 tokens, Drafted: 244 tokens, Per-position acceptance rate: 0.803, 0.508, Avg Draft acceptance rate: 65.6%
(APIServer pid=1) INFO 06-21 14:23:14 [loggers.py:271] Engine 000: Avg prompt throughput: 0.0 tokens/s, Avg generation throughput: 43.6 tokens/s, Running: 1 reqs, Waiting: 0 reqs, GPU KV cache usage: 30.5%, Prefix cache hit rate: 96.6%
(APIServer pid=1) INFO 06-21 14:23:14 [metrics.py:101] SpecDecoding metrics: Mean acceptance length: 2.48, Accepted throughput: 26.00 tokens/s, Drafted throughput: 35.19 tokens/s, Accepted: 260 tokens, Drafted: 352 tokens, Per-position acceptance rate: 0.875, 0.602, Avg Draft acceptance rate: 73.9%
(APIServer pid=1) INFO 06-21 14:23:24 [loggers.py:271] Engine 000: Avg prompt throughput: 0.0 tokens/s, Avg generation throughput: 42.6 tokens/s, Running: 1 reqs, Waiting: 0 reqs, GPU KV cache usage: 30.5%, Prefix cache hit rate: 96.6%
(APIServer pid=1) INFO 06-21 14:23:24 [metrics.py:101] SpecDecoding metrics: Mean acceptance length: 2.43, Accepted throughput: 25.10 tokens/s, Drafted throughput: 35.00 tokens/s, Accepted: 251 tokens, Drafted: 350 tokens, Per-position acceptance rate: 0.857, 0.577, Avg Draft acceptance rate: 71.7%
(APIServer pid=1) INFO:     192.168.1.244:47290 - "POST /v1/chat/completions HTTP/1.1" 200 OK
(APIServer pid=1) INFO 06-21 14:23:34 [loggers.py:271] Engine 000: Avg prompt throughput: 0.0 tokens/s, Avg generation throughput: 23.7 tokens/s, Running: 0 reqs, Waiting: 0 reqs, GPU KV cache usage: 30.3%, Prefix cache hit rate: 96.6%
(APIServer pid=1) INFO 06-21 14:23:34 [metrics.py:101] SpecDecoding metrics: Mean acceptance length: 2.69, Accepted throughput: 15.00 tokens/s, Drafted throughput: 17.80 tokens/s, Accepted: 150 tokens, Drafted: 178 tokens, Per-position acceptance rate: 0.955, 0.730, Avg Draft acceptance rate: 84.3%
(APIServer pid=1) INFO:     192.168.1.244:47290 - "POST /v1/chat/completions HTTP/1.1" 200 OK
(APIServer pid=1) INFO:     192.168.1.244:47290 - "POST /v1/chat/completions HTTP/1.1" 200 OK
(APIServer pid=1) INFO 06-21 14:23:44 [loggers.py:271] Engine 000: Avg prompt throughput: 335.9 tokens/s, Avg generation throughput: 26.2 tokens/s, Running: 1 reqs, Waiting: 0 reqs, GPU KV cache usage: 31.0%, Prefix cache hit rate: 96.6%
(APIServer pid=1) INFO 06-21 14:23:44 [metrics.py:101] SpecDecoding metrics: Mean acceptance length: 2.57, Accepted throughput: 15.90 tokens/s, Drafted throughput: 20.20 tokens/s, Accepted: 159 tokens, Drafted: 202 tokens, Per-position acceptance rate: 0.921, 0.653, Avg Draft acceptance rate: 78.7%
(APIServer pid=1) INFO:     192.168.1.244:47290 - "POST /v1/chat/completions HTTP/1.1" 200 OK
(APIServer pid=1) INFO:     192.168.1.244:47290 - "POST /v1/chat/completions HTTP/1.1" 200 OK
(APIServer pid=1) INFO 06-21 14:23:54 [loggers.py:271] Engine 000: Avg prompt throughput: 209.5 tokens/s, Avg generation throughput: 29.4 tokens/s, Running: 1 reqs, Waiting: 0 reqs, GPU KV cache usage: 31.3%, Prefix cache hit rate: 96.6%
(APIServer pid=1) INFO 06-21 14:23:54 [metrics.py:101] SpecDecoding metrics: Mean acceptance length: 2.43, Accepted throughput: 17.30 tokens/s, Drafted throughput: 24.20 tokens/s, Accepted: 173 tokens, Drafted: 242 tokens, Per-position acceptance rate: 0.868, 0.562, Avg Draft acceptance rate: 71.5%
(APIServer pid=1) INFO:     192.168.1.244:47290 - "POST /v1/chat/completions HTTP/1.1" 200 OK
(APIServer pid=1) INFO 06-21 14:24:04 [loggers.py:271] Engine 000: Avg prompt throughput: 83.0 tokens/s, Avg generation throughput: 29.4 tokens/s, Running: 0 reqs, Waiting: 0 reqs, GPU KV cache usage: 31.3%, Prefix cache hit rate: 96.7%
(APIServer pid=1) INFO 06-21 14:24:04 [metrics.py:101] SpecDecoding metrics: Mean acceptance length: 2.57, Accepted throughput: 18.00 tokens/s, Drafted throughput: 23.00 tokens/s, Accepted: 180 tokens, Drafted: 230 tokens, Per-position acceptance rate: 0.870, 0.696, Avg Draft acceptance rate: 78.3%
(APIServer pid=1) INFO 06-21 14:24:14 [loggers.py:271] Engine 000: Avg prompt throughput: 0.0 tokens/s, Avg generation throughput: 0.0 tokens/s, Running: 0 reqs, Waiting: 0 reqs, GPU KV cache usage: 31.3%, Prefix cache hit rate: 96.7%
(APIServer pid=1) INFO:     192.168.1.244:47002 - "POST /v1/chat/completions HTTP/1.1" 200 OK
(APIServer pid=1) INFO 06-21 14:26:24 [loggers.py:271] Engine 000: Avg prompt throughput: 81.6 tokens/s, Avg generation throughput: 16.2 tokens/s, Running: 1 reqs, Waiting: 0 reqs, GPU KV cache usage: 31.6%, Prefix cache hit rate: 96.7%
(APIServer pid=1) INFO 06-21 14:26:24 [metrics.py:101] SpecDecoding metrics: Mean acceptance length: 2.27, Accepted throughput: 0.64 tokens/s, Drafted throughput: 1.01 tokens/s, Accepted: 90 tokens, Drafted: 142 tokens, Per-position acceptance rate: 0.761, 0.507, Avg Draft acceptance rate: 63.4%
(APIServer pid=1) INFO:     192.168.1.244:47002 - "POST /v1/chat/completions HTTP/1.1" 200 OK
(APIServer pid=1) INFO:     192.168.1.244:47002 - "POST /v1/chat/completions HTTP/1.1" 200 OK
(APIServer pid=1) INFO 06-21 14:26:34 [loggers.py:271] Engine 000: Avg prompt throughput: 95.4 tokens/s, Avg generation throughput: 20.9 tokens/s, Running: 0 reqs, Waiting: 0 reqs, GPU KV cache usage: 31.9%, Prefix cache hit rate: 96.7%
(APIServer pid=1) INFO 06-21 14:26:34 [metrics.py:101] SpecDecoding metrics: Mean acceptance length: 2.41, Accepted throughput: 12.30 tokens/s, Drafted throughput: 17.40 tokens/s, Accepted: 123 tokens, Drafted: 174 tokens, Per-position acceptance rate: 0.839, 0.575, Avg Draft acceptance rate: 70.7%
(APIServer pid=1) INFO:     192.168.1.244:45538 - "POST /v1/chat/completions HTTP/1.1" 200 OK
(APIServer pid=1) INFO:     192.168.1.244:45546 - "POST /v1/chat/completions HTTP/1.1" 200 OK
(APIServer pid=1) INFO 06-21 14:26:44 [loggers.py:271] Engine 000: Avg prompt throughput: 117.2 tokens/s, Avg generation throughput: 9.0 tokens/s, Running: 1 reqs, Waiting: 0 reqs, GPU KV cache usage: 32.2%, Prefix cache hit rate: 96.8%
(APIServer pid=1) INFO 06-21 14:26:44 [metrics.py:101] SpecDecoding metrics: Mean acceptance length: 2.41, Accepted throughput: 5.20 tokens/s, Drafted throughput: 7.40 tokens/s, Accepted: 52 tokens, Drafted: 74 tokens, Per-position acceptance rate: 0.892, 0.514, Avg Draft acceptance rate: 70.3%
(APIServer pid=1) INFO 06-21 14:26:54 [loggers.py:271] Engine 000: Avg prompt throughput: 0.0 tokens/s, Avg generation throughput: 40.4 tokens/s, Running: 0 reqs, Waiting: 0 reqs, GPU KV cache usage: 32.1%, Prefix cache hit rate: 96.8%
(APIServer pid=1) INFO 06-21 14:26:54 [metrics.py:101] SpecDecoding metrics: Mean acceptance length: 2.44, Accepted throughput: 23.90 tokens/s, Drafted throughput: 33.20 tokens/s, Accepted: 239 tokens, Drafted: 332 tokens, Per-position acceptance rate: 0.873, 0.566, Avg Draft acceptance rate: 72.0%
(APIServer pid=1) INFO:     192.168.1.244:45272 - "POST /v1/chat/completions HTTP/1.1" 200 OK
(APIServer pid=1) INFO 06-21 14:27:04 [loggers.py:271] Engine 000: Avg prompt throughput: 72.2 tokens/s, Avg generation throughput: 24.1 tokens/s, Running: 1 reqs, Waiting: 0 reqs, GPU KV cache usage: 32.5%, Prefix cache hit rate: 96.8%
(APIServer pid=1) INFO 06-21 14:27:04 [metrics.py:101] SpecDecoding metrics: Mean acceptance length: 2.58, Accepted throughput: 14.70 tokens/s, Drafted throughput: 18.60 tokens/s, Accepted: 147 tokens, Drafted: 186 tokens, Per-position acceptance rate: 0.882, 0.699, Avg Draft acceptance rate: 79.0%
(APIServer pid=1) INFO:     192.168.1.244:46058 - "POST /v1/chat/completions HTTP/1.1" 200 OK
(APIServer pid=1) INFO 06-21 14:27:14 [loggers.py:271] Engine 000: Avg prompt throughput: 106.0 tokens/s, Avg generation throughput: 20.5 tokens/s, Running: 1 reqs, Waiting: 0 reqs, GPU KV cache usage: 32.6%, Prefix cache hit rate: 96.8%
(APIServer pid=1) INFO 06-21 14:27:14 [metrics.py:101] SpecDecoding metrics: Mean acceptance length: 2.53, Accepted throughput: 12.40 tokens/s, Drafted throughput: 16.20 tokens/s, Accepted: 124 tokens, Drafted: 162 tokens, Per-position acceptance rate: 0.951, 0.580, Avg Draft acceptance rate: 76.5%
(APIServer pid=1) INFO 06-21 14:27:24 [loggers.py:271] Engine 000: Avg prompt throughput: 0.0 tokens/s, Avg generation throughput: 42.0 tokens/s, Running: 1 reqs, Waiting: 0 reqs, GPU KV cache usage: 32.7%, Prefix cache hit rate: 96.8%
(APIServer pid=1) INFO 06-21 14:27:24 [metrics.py:101] SpecDecoding metrics: Mean acceptance length: 2.44, Accepted throughput: 24.80 tokens/s, Drafted throughput: 34.40 tokens/s, Accepted: 248 tokens, Drafted: 344 tokens, Per-position acceptance rate: 0.837, 0.605, Avg Draft acceptance rate: 72.1%
(APIServer pid=1) INFO:     192.168.1.244:46900 - "POST /v1/chat/completions HTTP/1.1" 200 OK
(APIServer pid=1) INFO 06-21 14:27:34 [loggers.py:271] Engine 000: Avg prompt throughput: 84.4 tokens/s, Avg generation throughput: 20.4 tokens/s, Running: 1 reqs, Waiting: 0 reqs, GPU KV cache usage: 32.8%, Prefix cache hit rate: 96.8%
(APIServer pid=1) INFO 06-21 14:27:34 [metrics.py:101] SpecDecoding metrics: Mean acceptance length: 2.52, Accepted throughput: 12.30 tokens/s, Drafted throughput: 16.20 tokens/s, Accepted: 123 tokens, Drafted: 162 tokens, Per-position acceptance rate: 0.877, 0.642, Avg Draft acceptance rate: 75.9%
(APIServer pid=1) INFO:     192.168.1.244:45610 - "POST /v1/chat/completions HTTP/1.1" 200 OK
(APIServer pid=1) INFO 06-21 14:27:44 [loggers.py:271] Engine 000: Avg prompt throughput: 74.3 tokens/s, Avg generation throughput: 21.4 tokens/s, Running: 1 reqs, Waiting: 0 reqs, GPU KV cache usage: 33.0%, Prefix cache hit rate: 96.8%
(APIServer pid=1) INFO 06-21 14:27:44 [metrics.py:101] SpecDecoding metrics: Mean acceptance length: 2.64, Accepted throughput: 13.30 tokens/s, Drafted throughput: 16.20 tokens/s, Accepted: 133 tokens, Drafted: 162 tokens, Per-position acceptance rate: 0.963, 0.679, Avg Draft acceptance rate: 82.1%
(APIServer pid=1) INFO:     192.168.1.244:46906 - "POST /v1/chat/completions HTTP/1.1" 200 OK
(APIServer pid=1) INFO 06-21 14:27:54 [loggers.py:271] Engine 000: Avg prompt throughput: 70.6 tokens/s, Avg generation throughput: 17.5 tokens/s, Running: 0 reqs, Waiting: 0 reqs, GPU KV cache usage: 33.1%, Prefix cache hit rate: 96.8%
(APIServer pid=1) INFO 06-21 14:27:54 [metrics.py:101] SpecDecoding metrics: Mean acceptance length: 2.71, Accepted throughput: 11.10 tokens/s, Drafted throughput: 13.00 tokens/s, Accepted: 111 tokens, Drafted: 130 tokens, Per-position acceptance rate: 0.954, 0.754, Avg Draft acceptance rate: 85.4%
(APIServer pid=1) INFO:     192.168.1.244:46050 - "POST /v1/chat/completions HTTP/1.1" 200 OK
(APIServer pid=1) INFO 06-21 14:28:04 [loggers.py:271] Engine 000: Avg prompt throughput: 78.5 tokens/s, Avg generation throughput: 28.5 tokens/s, Running: 1 reqs, Waiting: 0 reqs, GPU KV cache usage: 33.4%, Prefix cache hit rate: 96.9%
(APIServer pid=1) INFO 06-21 14:28:04 [metrics.py:101] SpecDecoding metrics: Mean acceptance length: 2.87, Accepted throughput: 18.50 tokens/s, Drafted throughput: 19.80 tokens/s, Accepted: 185 tokens, Drafted: 198 tokens, Per-position acceptance rate: 1.000, 0.869, Avg Draft acceptance rate: 93.4%
(APIServer pid=1) INFO:     192.168.1.244:46042 - "POST /v1/chat/completions HTTP/1.1" 200 OK
(APIServer pid=1) INFO 06-21 14:28:14 [loggers.py:271] Engine 000: Avg prompt throughput: 107.5 tokens/s, Avg generation throughput: 19.7 tokens/s, Running: 1 reqs, Waiting: 0 reqs, GPU KV cache usage: 33.5%, Prefix cache hit rate: 96.9%
(APIServer pid=1) INFO 06-21 14:28:14 [metrics.py:101] SpecDecoding metrics: Mean acceptance length: 2.79, Accepted throughput: 12.70 tokens/s, Drafted throughput: 14.20 tokens/s, Accepted: 127 tokens, Drafted: 142 tokens, Per-position acceptance rate: 1.000, 0.789, Avg Draft acceptance rate: 89.4%
(APIServer pid=1) INFO:     192.168.1.244:45318 - "POST /v1/chat/completions HTTP/1.1" 200 OK
(APIServer pid=1) INFO 06-21 14:28:24 [loggers.py:271] Engine 000: Avg prompt throughput: 109.4 tokens/s, Avg generation throughput: 20.3 tokens/s, Running: 1 reqs, Waiting: 0 reqs, GPU KV cache usage: 33.7%, Prefix cache hit rate: 96.9%
(APIServer pid=1) INFO 06-21 14:28:24 [metrics.py:101] SpecDecoding metrics: Mean acceptance length: 2.87, Accepted throughput: 13.30 tokens/s, Drafted throughput: 14.20 tokens/s, Accepted: 133 tokens, Drafted: 142 tokens, Per-position acceptance rate: 1.000, 0.873, Avg Draft acceptance rate: 93.7%
(APIServer pid=1) INFO:     192.168.1.244:48256 - "POST /v1/chat/completions HTTP/1.1" 200 OK
(APIServer pid=1) INFO 06-21 14:28:34 [loggers.py:271] Engine 000: Avg prompt throughput: 87.7 tokens/s, Avg generation throughput: 17.4 tokens/s, Running: 1 reqs, Waiting: 0 reqs, GPU KV cache usage: 33.8%, Prefix cache hit rate: 96.9%
(APIServer pid=1) INFO 06-21 14:28:34 [metrics.py:101] SpecDecoding metrics: Mean acceptance length: 2.82, Accepted throughput: 11.30 tokens/s, Drafted throughput: 12.40 tokens/s, Accepted: 113 tokens, Drafted: 124 tokens, Per-position acceptance rate: 0.984, 0.839, Avg Draft acceptance rate: 91.1%
(APIServer pid=1) INFO:     192.168.1.244:48310 - "POST /v1/chat/completions HTTP/1.1" 200 OK
(APIServer pid=1) INFO 06-21 14:28:44 [loggers.py:271] Engine 000: Avg prompt throughput: 96.9 tokens/s, Avg generation throughput: 19.1 tokens/s, Running: 1 reqs, Waiting: 0 reqs, GPU KV cache usage: 34.0%, Prefix cache hit rate: 96.9%
(APIServer pid=1) INFO 06-21 14:28:44 [metrics.py:101] SpecDecoding metrics: Mean acceptance length: 2.65, Accepted throughput: 11.90 tokens/s, Drafted throughput: 14.40 tokens/s, Accepted: 119 tokens, Drafted: 144 tokens, Per-position acceptance rate: 0.931, 0.722, Avg Draft acceptance rate: 82.6%
(APIServer pid=1) INFO 06-21 14:28:54 [loggers.py:271] Engine 000: Avg prompt throughput: 0.0 tokens/s, Avg generation throughput: 39.1 tokens/s, Running: 0 reqs, Waiting: 0 reqs, GPU KV cache usage: 33.9%, Prefix cache hit rate: 96.9%
(APIServer pid=1) INFO 06-21 14:28:54 [metrics.py:101] SpecDecoding metrics: Mean acceptance length: 2.86, Accepted throughput: 25.50 tokens/s, Drafted throughput: 27.40 tokens/s, Accepted: 255 tokens, Drafted: 274 tokens, Per-position acceptance rate: 0.985, 0.876, Avg Draft acceptance rate: 93.1%
(APIServer pid=1) INFO:     192.168.1.244:45350 - "POST /v1/chat/completions HTTP/1.1" 200 OK
(APIServer pid=1) INFO 06-21 14:29:04 [loggers.py:271] Engine 000: Avg prompt throughput: 135.8 tokens/s, Avg generation throughput: 29.2 tokens/s, Running: 1 reqs, Waiting: 0 reqs, GPU KV cache usage: 34.2%, Prefix cache hit rate: 96.9%
(APIServer pid=1) INFO 06-21 14:29:04 [metrics.py:101] SpecDecoding metrics: Mean acceptance length: 2.51, Accepted throughput: 17.50 tokens/s, Drafted throughput: 23.20 tokens/s, Accepted: 175 tokens, Drafted: 232 tokens, Per-position acceptance rate: 0.871, 0.638, Avg Draft acceptance rate: 75.4%
(APIServer pid=1) INFO 06-21 14:29:14 [loggers.py:271] Engine 000: Avg prompt throughput: 0.0 tokens/s, Avg generation throughput: 45.7 tokens/s, Running: 1 reqs, Waiting: 0 reqs, GPU KV cache usage: 34.2%, Prefix cache hit rate: 96.9%
(APIServer pid=1) INFO 06-21 14:29:14 [metrics.py:101] SpecDecoding metrics: Mean acceptance length: 2.64, Accepted throughput: 28.40 tokens/s, Drafted throughput: 34.60 tokens/s, Accepted: 284 tokens, Drafted: 346 tokens, Per-position acceptance rate: 0.954, 0.688, Avg Draft acceptance rate: 82.1%
(APIServer pid=1) INFO:     192.168.1.244:47836 - "POST /v1/chat/completions HTTP/1.1" 200 OK
(APIServer pid=1) INFO:     192.168.1.244:47836 - "POST /v1/chat/completions HTTP/1.1" 200 OK
(APIServer pid=1) INFO 06-21 14:29:24 [loggers.py:271] Engine 000: Avg prompt throughput: 223.0 tokens/s, Avg generation throughput: 12.5 tokens/s, Running: 1 reqs, Waiting: 0 reqs, GPU KV cache usage: 34.6%, Prefix cache hit rate: 97.0%
(APIServer pid=1) INFO 06-21 14:29:24 [metrics.py:101] SpecDecoding metrics: Mean acceptance length: 2.58, Accepted throughput: 7.60 tokens/s, Drafted throughput: 9.60 tokens/s, Accepted: 76 tokens, Drafted: 96 tokens, Per-position acceptance rate: 0.938, 0.646, Avg Draft acceptance rate: 79.2%
(APIServer pid=1) INFO:     192.168.1.244:47836 - "POST /v1/chat/completions HTTP/1.1" 200 OK
(APIServer pid=1) INFO 06-21 14:29:34 [loggers.py:271] Engine 000: Avg prompt throughput: 249.0 tokens/s, Avg generation throughput: 32.8 tokens/s, Running: 1 reqs, Waiting: 0 reqs, GPU KV cache usage: 34.9%, Prefix cache hit rate: 97.0%
(APIServer pid=1) INFO 06-21 14:29:34 [metrics.py:101] SpecDecoding metrics: Mean acceptance length: 2.48, Accepted throughput: 19.60 tokens/s, Drafted throughput: 26.40 tokens/s, Accepted: 196 tokens, Drafted: 264 tokens, Per-position acceptance rate: 0.856, 0.629, Avg Draft acceptance rate: 74.2%
(APIServer pid=1) INFO 06-21 14:29:44 [loggers.py:271] Engine 000: Avg prompt throughput: 0.0 tokens/s, Avg generation throughput: 19.8 tokens/s, Running: 0 reqs, Waiting: 0 reqs, GPU KV cache usage: 34.8%, Prefix cache hit rate: 97.0%
(APIServer pid=1) INFO 06-21 14:29:44 [metrics.py:101] SpecDecoding metrics: Mean acceptance length: 2.31, Accepted throughput: 11.30 tokens/s, Drafted throughput: 17.20 tokens/s, Accepted: 113 tokens, Drafted: 172 tokens, Per-position acceptance rate: 0.802, 0.512, Avg Draft acceptance rate: 65.7%
(APIServer pid=1) INFO 06-21 14:29:54 [loggers.py:271] Engine 000: Avg prompt throughput: 0.0 tokens/s, Avg generation throughput: 0.0 tokens/s, Running: 0 reqs, Waiting: 0 reqs, GPU KV cache usage: 34.8%, Prefix cache hit rate: 97.0%
(APIServer pid=1) INFO:     192.168.1.244:48318 - "POST /v1/chat/completions HTTP/1.1" 200 OK
(APIServer pid=1) INFO:     192.168.1.244:48318 - "POST /v1/chat/completions HTTP/1.1" 200 OK
(APIServer pid=1) INFO 06-21 14:36:04 [loggers.py:271] Engine 000: Avg prompt throughput: 68.3 tokens/s, Avg generation throughput: 9.8 tokens/s, Running: 0 reqs, Waiting: 0 reqs, GPU KV cache usage: 34.9%, Prefix cache hit rate: 97.0%
(APIServer pid=1) INFO 06-21 14:36:04 [metrics.py:101] SpecDecoding metrics: Mean acceptance length: 2.45, Accepted throughput: 0.15 tokens/s, Drafted throughput: 0.21 tokens/s, Accepted: 58 tokens, Drafted: 80 tokens, Per-position acceptance rate: 0.875, 0.575, Avg Draft acceptance rate: 72.5%
(APIServer pid=1) INFO 06-21 14:36:14 [loggers.py:271] Engine 000: Avg prompt throughput: 118.3 tokens/s, Avg generation throughput: 20.3 tokens/s, Running: 0 reqs, Waiting: 0 reqs, GPU KV cache usage: 35.1%, Prefix cache hit rate: 97.0%
(APIServer pid=1) INFO 06-21 14:36:14 [metrics.py:101] SpecDecoding metrics: Mean acceptance length: 2.67, Accepted throughput: 12.70 tokens/s, Drafted throughput: 15.20 tokens/s, Accepted: 127 tokens, Drafted: 152 tokens, Per-position acceptance rate: 0.961, 0.711, Avg Draft acceptance rate: 83.6%
(APIServer pid=1) INFO:     192.168.1.244:45014 - "POST /v1/chat/completions HTTP/1.1" 200 OK
(APIServer pid=1) INFO:     192.168.1.244:45014 - "POST /v1/chat/completions HTTP/1.1" 200 OK
(APIServer pid=1) INFO 06-21 14:36:24 [loggers.py:271] Engine 000: Avg prompt throughput: 87.7 tokens/s, Avg generation throughput: 8.2 tokens/s, Running: 1 reqs, Waiting: 0 reqs, GPU KV cache usage: 53.5%, Prefix cache hit rate: 96.8%
(APIServer pid=1) INFO 06-21 14:36:24 [metrics.py:101] SpecDecoding metrics: Mean acceptance length: 2.61, Accepted throughput: 5.00 tokens/s, Drafted throughput: 6.20 tokens/s, Accepted: 50 tokens, Drafted: 62 tokens, Per-position acceptance rate: 1.000, 0.613, Avg Draft acceptance rate: 80.6%
(APIServer pid=1) INFO 06-21 14:36:34 [loggers.py:271] Engine 000: Avg prompt throughput: 3133.3 tokens/s, Avg generation throughput: 6.7 tokens/s, Running: 1 reqs, Waiting: 0 reqs, GPU KV cache usage: 36.1%, Prefix cache hit rate: 96.8%
(APIServer pid=1) INFO 06-21 14:36:34 [metrics.py:101] SpecDecoding metrics: Mean acceptance length: 2.13, Accepted throughput: 3.50 tokens/s, Drafted throughput: 6.20 tokens/s, Accepted: 35 tokens, Drafted: 62 tokens, Per-position acceptance rate: 0.677, 0.452, Avg Draft acceptance rate: 56.5%
(APIServer pid=1) INFO:     192.168.1.244:45014 - "POST /v1/chat/completions HTTP/1.1" 200 OK
(APIServer pid=1) INFO 06-21 14:36:44 [loggers.py:271] Engine 000: Avg prompt throughput: 112.0 tokens/s, Avg generation throughput: 39.7 tokens/s, Running: 1 reqs, Waiting: 0 reqs, GPU KV cache usage: 36.2%, Prefix cache hit rate: 96.8%
(APIServer pid=1) INFO 06-21 14:36:44 [metrics.py:101] SpecDecoding metrics: Mean acceptance length: 2.71, Accepted throughput: 25.00 tokens/s, Drafted throughput: 29.20 tokens/s, Accepted: 250 tokens, Drafted: 292 tokens, Per-position acceptance rate: 0.966, 0.747, Avg Draft acceptance rate: 85.6%
(APIServer pid=1) INFO:     192.168.1.244:47664 - "POST /v1/chat/completions HTTP/1.1" 200 OK
(APIServer pid=1) INFO 06-21 14:36:54 [loggers.py:271] Engine 000: Avg prompt throughput: 133.2 tokens/s, Avg generation throughput: 19.5 tokens/s, Running: 0 reqs, Waiting: 0 reqs, GPU KV cache usage: 36.2%, Prefix cache hit rate: 96.8%
(APIServer pid=1) INFO 06-21 14:36:54 [metrics.py:101] SpecDecoding metrics: Mean acceptance length: 2.67, Accepted throughput: 12.20 tokens/s, Drafted throughput: 14.60 tokens/s, Accepted: 122 tokens, Drafted: 146 tokens, Per-position acceptance rate: 0.973, 0.699, Avg Draft acceptance rate: 83.6%
(APIServer pid=1) INFO:     192.168.1.244:47664 - "POST /v1/chat/completions HTTP/1.1" 200 OK
(APIServer pid=1) INFO:     192.168.1.244:47664 - "POST /v1/chat/completions HTTP/1.1" 200 OK
(APIServer pid=1) INFO 06-21 14:37:04 [loggers.py:271] Engine 000: Avg prompt throughput: 205.3 tokens/s, Avg generation throughput: 32.3 tokens/s, Running: 1 reqs, Waiting: 0 reqs, GPU KV cache usage: 36.6%, Prefix cache hit rate: 96.8%
(APIServer pid=1) INFO 06-21 14:37:04 [metrics.py:101] SpecDecoding metrics: Mean acceptance length: 2.53, Accepted throughput: 19.40 tokens/s, Drafted throughput: 25.40 tokens/s, Accepted: 194 tokens, Drafted: 254 tokens, Per-position acceptance rate: 0.890, 0.638, Avg Draft acceptance rate: 76.4%
(APIServer pid=1) INFO 06-21 14:37:14 [loggers.py:271] Engine 000: Avg prompt throughput: 0.0 tokens/s, Avg generation throughput: 14.4 tokens/s, Running: 0 reqs, Waiting: 0 reqs, GPU KV cache usage: 36.5%, Prefix cache hit rate: 96.8%
(APIServer pid=1) INFO 06-21 14:37:14 [metrics.py:101] SpecDecoding metrics: Mean acceptance length: 2.30, Accepted throughput: 8.20 tokens/s, Drafted throughput: 12.60 tokens/s, Accepted: 82 tokens, Drafted: 126 tokens, Per-position acceptance rate: 0.778, 0.524, Avg Draft acceptance rate: 65.1%
(APIServer pid=1) INFO 06-21 14:37:24 [loggers.py:271] Engine 000: Avg prompt throughput: 0.0 tokens/s, Avg generation throughput: 0.0 tokens/s, Running: 0 reqs, Waiting: 0 reqs, GPU KV cache usage: 36.5%, Prefix cache hit rate: 96.8%
(APIServer pid=1) INFO:     192.168.1.244:47960 - "POST /v1/chat/completions HTTP/1.1" 200 OK
(APIServer pid=1) INFO:     192.168.1.244:47960 - "POST /v1/chat/completions HTTP/1.1" 200 OK
(APIServer pid=1) INFO:     192.168.1.244:47960 - "POST /v1/chat/completions HTTP/1.1" 200 OK
(APIServer pid=1) INFO:     192.168.1.244:47960 - "POST /v1/chat/completions HTTP/1.1" 200 OK
(APIServer pid=1) INFO 06-21 14:41:14 [loggers.py:271] Engine 000: Avg prompt throughput: 464.9 tokens/s, Avg generation throughput: 18.4 tokens/s, Running: 1 reqs, Waiting: 0 reqs, GPU KV cache usage: 37.2%, Prefix cache hit rate: 96.8%
(APIServer pid=1) INFO 06-21 14:41:14 [metrics.py:101] SpecDecoding metrics: Mean acceptance length: 2.65, Accepted throughput: 0.47 tokens/s, Drafted throughput: 0.57 tokens/s, Accepted: 112 tokens, Drafted: 136 tokens, Per-position acceptance rate: 0.971, 0.676, Avg Draft acceptance rate: 82.4%
(APIServer pid=1) INFO:     192.168.1.244:47960 - "POST /v1/chat/completions HTTP/1.1" 200 OK
(APIServer pid=1) INFO 06-21 14:41:24 [loggers.py:271] Engine 000: Avg prompt throughput: 234.2 tokens/s, Avg generation throughput: 32.7 tokens/s, Running: 1 reqs, Waiting: 0 reqs, GPU KV cache usage: 37.4%, Prefix cache hit rate: 96.8%
(APIServer pid=1) INFO 06-21 14:41:24 [metrics.py:101] SpecDecoding metrics: Mean acceptance length: 2.30, Accepted throughput: 18.40 tokens/s, Drafted throughput: 28.40 tokens/s, Accepted: 184 tokens, Drafted: 284 tokens, Per-position acceptance rate: 0.789, 0.507, Avg Draft acceptance rate: 64.8%
(APIServer pid=1) INFO:     192.168.1.244:47960 - "POST /v1/chat/completions HTTP/1.1" 200 OK
(APIServer pid=1) INFO 06-21 14:41:34 [loggers.py:271] Engine 000: Avg prompt throughput: 108.7 tokens/s, Avg generation throughput: 34.0 tokens/s, Running: 1 reqs, Waiting: 0 reqs, GPU KV cache usage: 37.5%, Prefix cache hit rate: 96.8%
(APIServer pid=1) INFO 06-21 14:41:34 [metrics.py:101] SpecDecoding metrics: Mean acceptance length: 2.25, Accepted throughput: 18.80 tokens/s, Drafted throughput: 30.20 tokens/s, Accepted: 188 tokens, Drafted: 302 tokens, Per-position acceptance rate: 0.768, 0.477, Avg Draft acceptance rate: 62.3%
(APIServer pid=1) INFO 06-21 14:41:44 [loggers.py:271] Engine 000: Avg prompt throughput: 0.0 tokens/s, Avg generation throughput: 37.7 tokens/s, Running: 1 reqs, Waiting: 0 reqs, GPU KV cache usage: 37.5%, Prefix cache hit rate: 96.8%
(APIServer pid=1) INFO 06-21 14:41:44 [metrics.py:101] SpecDecoding metrics: Mean acceptance length: 2.14, Accepted throughput: 20.10 tokens/s, Drafted throughput: 35.20 tokens/s, Accepted: 201 tokens, Drafted: 352 tokens, Per-position acceptance rate: 0.699, 0.443, Avg Draft acceptance rate: 57.1%
(APIServer pid=1) INFO 06-21 14:41:54 [loggers.py:271] Engine 000: Avg prompt throughput: 0.0 tokens/s, Avg generation throughput: 38.9 tokens/s, Running: 1 reqs, Waiting: 0 reqs, GPU KV cache usage: 37.6%, Prefix cache hit rate: 96.8%
(APIServer pid=1) INFO 06-21 14:41:54 [metrics.py:101] SpecDecoding metrics: Mean acceptance length: 2.19, Accepted throughput: 21.10 tokens/s, Drafted throughput: 35.60 tokens/s, Accepted: 211 tokens, Drafted: 356 tokens, Per-position acceptance rate: 0.758, 0.427, Avg Draft acceptance rate: 59.3%
(APIServer pid=1) INFO:     192.168.1.244:46966 - "POST /v1/chat/completions HTTP/1.1" 200 OK
(APIServer pid=1) INFO 06-21 14:42:04 [loggers.py:271] Engine 000: Avg prompt throughput: 116.0 tokens/s, Avg generation throughput: 19.3 tokens/s, Running: 1 reqs, Waiting: 0 reqs, GPU KV cache usage: 37.7%, Prefix cache hit rate: 96.8%
(APIServer pid=1) INFO 06-21 14:42:04 [metrics.py:101] SpecDecoding metrics: Mean acceptance length: 2.40, Accepted throughput: 11.20 tokens/s, Drafted throughput: 16.00 tokens/s, Accepted: 112 tokens, Drafted: 160 tokens, Per-position acceptance rate: 0.825, 0.575, Avg Draft acceptance rate: 70.0%
(APIServer pid=1) INFO:     192.168.1.244:46966 - "POST /v1/chat/completions HTTP/1.1" 200 OK
(APIServer pid=1) INFO 06-21 14:42:14 [loggers.py:271] Engine 000: Avg prompt throughput: 75.1 tokens/s, Avg generation throughput: 35.9 tokens/s, Running: 1 reqs, Waiting: 0 reqs, GPU KV cache usage: 37.9%, Prefix cache hit rate: 96.8%
(APIServer pid=1) INFO 06-21 14:42:14 [metrics.py:101] SpecDecoding metrics: Mean acceptance length: 2.39, Accepted throughput: 20.80 tokens/s, Drafted throughput: 30.00 tokens/s, Accepted: 208 tokens, Drafted: 300 tokens, Per-position acceptance rate: 0.827, 0.560, Avg Draft acceptance rate: 69.3%
(APIServer pid=1) INFO:     192.168.1.244:48610 - "POST /v1/chat/completions HTTP/1.1" 200 OK
(APIServer pid=1) INFO 06-21 14:42:24 [loggers.py:271] Engine 000: Avg prompt throughput: 0.0 tokens/s, Avg generation throughput: 23.5 tokens/s, Running: 0 reqs, Waiting: 0 reqs, GPU KV cache usage: 37.7%, Prefix cache hit rate: 96.8%
(APIServer pid=1) INFO 06-21 14:42:24 [metrics.py:101] SpecDecoding metrics: Mean acceptance length: 2.71, Accepted throughput: 14.90 tokens/s, Drafted throughput: 17.40 tokens/s, Accepted: 149 tokens, Drafted: 174 tokens, Per-position acceptance rate: 0.989, 0.724, Avg Draft acceptance rate: 85.6%
(APIServer pid=1) INFO 06-21 14:42:34 [loggers.py:271] Engine 000: Avg prompt throughput: 119.0 tokens/s, Avg generation throughput: 31.4 tokens/s, Running: 0 reqs, Waiting: 0 reqs, GPU KV cache usage: 37.9%, Prefix cache hit rate: 96.8%
(APIServer pid=1) INFO 06-21 14:42:34 [metrics.py:101] SpecDecoding metrics: Mean acceptance length: 2.55, Accepted throughput: 19.10 tokens/s, Drafted throughput: 24.60 tokens/s, Accepted: 191 tokens, Drafted: 246 tokens, Per-position acceptance rate: 0.902, 0.650, Avg Draft acceptance rate: 77.6%
(APIServer pid=1) INFO:     192.168.1.244:46954 - "POST /v1/chat/completions HTTP/1.1" 200 OK
(APIServer pid=1) INFO 06-21 14:42:44 [loggers.py:271] Engine 000: Avg prompt throughput: 130.8 tokens/s, Avg generation throughput: 17.6 tokens/s, Running: 0 reqs, Waiting: 0 reqs, GPU KV cache usage: 38.0%, Prefix cache hit rate: 96.8%
(APIServer pid=1) INFO 06-21 14:42:44 [metrics.py:101] SpecDecoding metrics: Mean acceptance length: 2.54, Accepted throughput: 10.60 tokens/s, Drafted throughput: 13.80 tokens/s, Accepted: 106 tokens, Drafted: 138 tokens, Per-position acceptance rate: 0.957, 0.580, Avg Draft acceptance rate: 76.8%
(APIServer pid=1) INFO:     192.168.1.244:45838 - "POST /v1/chat/completions HTTP/1.1" 200 OK
(APIServer pid=1) INFO 06-21 14:42:54 [loggers.py:271] Engine 000: Avg prompt throughput: 96.7 tokens/s, Avg generation throughput: 35.7 tokens/s, Running: 1 reqs, Waiting: 0 reqs, GPU KV cache usage: 38.4%, Prefix cache hit rate: 96.8%
(APIServer pid=1) INFO 06-21 14:42:54 [metrics.py:101] SpecDecoding metrics: Mean acceptance length: 2.70, Accepted throughput: 22.40 tokens/s, Drafted throughput: 26.40 tokens/s, Accepted: 224 tokens, Drafted: 264 tokens, Per-position acceptance rate: 0.985, 0.712, Avg Draft acceptance rate: 84.8%
(APIServer pid=1) INFO 06-21 14:43:04 [loggers.py:271] Engine 000: Avg prompt throughput: 0.0 tokens/s, Avg generation throughput: 45.2 tokens/s, Running: 1 reqs, Waiting: 0 reqs, GPU KV cache usage: 38.4%, Prefix cache hit rate: 96.8%
(APIServer pid=1) INFO 06-21 14:43:04 [metrics.py:101] SpecDecoding metrics: Mean acceptance length: 2.61, Accepted throughput: 27.90 tokens/s, Drafted throughput: 34.60 tokens/s, Accepted: 279 tokens, Drafted: 346 tokens, Per-position acceptance rate: 0.902, 0.711, Avg Draft acceptance rate: 80.6%
(APIServer pid=1) INFO:     192.168.1.244:46036 - "POST /v1/chat/completions HTTP/1.1" 200 OK
(APIServer pid=1) INFO 06-21 14:43:14 [loggers.py:271] Engine 000: Avg prompt throughput: 173.9 tokens/s, Avg generation throughput: 18.7 tokens/s, Running: 1 reqs, Waiting: 0 reqs, GPU KV cache usage: 38.5%, Prefix cache hit rate: 96.8%
(APIServer pid=1) INFO 06-21 14:43:14 [metrics.py:101] SpecDecoding metrics: Mean acceptance length: 2.65, Accepted throughput: 11.70 tokens/s, Drafted throughput: 14.20 tokens/s, Accepted: 117 tokens, Drafted: 142 tokens, Per-position acceptance rate: 0.944, 0.704, Avg Draft acceptance rate: 82.4%
(APIServer pid=1) INFO:     192.168.1.244:46036 - "POST /v1/chat/completions HTTP/1.1" 200 OK
(APIServer pid=1) INFO:     192.168.1.244:46036 - "POST /v1/chat/completions HTTP/1.1" 200 OK
(APIServer pid=1) INFO 06-21 14:43:24 [loggers.py:271] Engine 000: Avg prompt throughput: 250.0 tokens/s, Avg generation throughput: 27.8 tokens/s, Running: 1 reqs, Waiting: 0 reqs, GPU KV cache usage: 38.8%, Prefix cache hit rate: 96.9%
(APIServer pid=1) INFO 06-21 14:43:24 [metrics.py:101] SpecDecoding metrics: Mean acceptance length: 2.42, Accepted throughput: 16.20 tokens/s, Drafted throughput: 22.80 tokens/s, Accepted: 162 tokens, Drafted: 228 tokens, Per-position acceptance rate: 0.868, 0.553, Avg Draft acceptance rate: 71.1%
(APIServer pid=1) INFO 06-21 14:43:34 [loggers.py:271] Engine 000: Avg prompt throughput: 0.0 tokens/s, Avg generation throughput: 20.3 tokens/s, Running: 0 reqs, Waiting: 0 reqs, GPU KV cache usage: 38.7%, Prefix cache hit rate: 96.9%
(APIServer pid=1) INFO 06-21 14:43:34 [metrics.py:101] SpecDecoding metrics: Mean acceptance length: 2.38, Accepted throughput: 11.90 tokens/s, Drafted throughput: 17.20 tokens/s, Accepted: 119 tokens, Drafted: 172 tokens, Per-position acceptance rate: 0.837, 0.547, Avg Draft acceptance rate: 69.2%
(APIServer pid=1) INFO 06-21 14:43:44 [loggers.py:271] Engine 000: Avg prompt throughput: 0.0 tokens/s, Avg generation throughput: 0.0 tokens/s, Running: 0 reqs, Waiting: 0 reqs, GPU KV cache usage: 38.7%, Prefix cache hit rate: 96.9%
(APIServer pid=1) INFO:     172.18.0.2:49940 - "GET /v1/models HTTP/1.1" 200 OK
(APIServer pid=1) INFO:     172.18.0.2:49948 - "GET /v1/models HTTP/1.1" 200 OK
(APIServer pid=1) INFO:     192.168.1.244:46424 - "POST /v1/chat/completions HTTP/1.1" 200 OK
(APIServer pid=1) INFO:     192.168.1.244:46424 - "POST /v1/chat/completions HTTP/1.1" 200 OK
(APIServer pid=1) INFO 06-21 14:59:14 [loggers.py:271] Engine 000: Avg prompt throughput: 559.1 tokens/s, Avg generation throughput: 23.6 tokens/s, Running: 1 reqs, Waiting: 0 reqs, GPU KV cache usage: 39.1%, Prefix cache hit rate: 96.8%
(APIServer pid=1) INFO 06-21 14:59:14 [metrics.py:101] SpecDecoding metrics: Mean acceptance length: 2.35, Accepted throughput: 0.14 tokens/s, Drafted throughput: 0.21 tokens/s, Accepted: 135 tokens, Drafted: 200 tokens, Per-position acceptance rate: 0.820, 0.530, Avg Draft acceptance rate: 67.5%
(APIServer pid=1) INFO 06-21 14:59:24 [loggers.py:271] Engine 000: Avg prompt throughput: 0.0 tokens/s, Avg generation throughput: 37.3 tokens/s, Running: 1 reqs, Waiting: 0 reqs, GPU KV cache usage: 39.1%, Prefix cache hit rate: 96.8%
(APIServer pid=1) INFO 06-21 14:59:24 [metrics.py:101] SpecDecoding metrics: Mean acceptance length: 2.08, Accepted throughput: 19.40 tokens/s, Drafted throughput: 35.80 tokens/s, Accepted: 194 tokens, Drafted: 358 tokens, Per-position acceptance rate: 0.709, 0.374, Avg Draft acceptance rate: 54.2%
(APIServer pid=1) INFO 06-21 14:59:34 [loggers.py:271] Engine 000: Avg prompt throughput: 0.0 tokens/s, Avg generation throughput: 7.3 tokens/s, Running: 0 reqs, Waiting: 0 reqs, GPU KV cache usage: 38.9%, Prefix cache hit rate: 96.8%
(APIServer pid=1) INFO 06-21 14:59:34 [metrics.py:101] SpecDecoding metrics: Mean acceptance length: 2.21, Accepted throughput: 4.00 tokens/s, Drafted throughput: 6.60 tokens/s, Accepted: 40 tokens, Drafted: 66 tokens, Per-position acceptance rate: 0.818, 0.394, Avg Draft acceptance rate: 60.6%
(APIServer pid=1) INFO 06-21 14:59:44 [loggers.py:271] Engine 000: Avg prompt throughput: 0.0 tokens/s, Avg generation throughput: 0.0 tokens/s, Running: 0 reqs, Waiting: 0 reqs, GPU KV cache usage: 38.9%, Prefix cache hit rate: 96.8%
(APIServer pid=1) INFO:     192.168.1.244:45114 - "POST /v1/chat/completions HTTP/1.1" 200 OK
(APIServer pid=1) INFO 06-21 15:00:14 [loggers.py:271] Engine 000: Avg prompt throughput: 117.6 tokens/s, Avg generation throughput: 32.8 tokens/s, Running: 1 reqs, Waiting: 0 reqs, GPU KV cache usage: 39.2%, Prefix cache hit rate: 96.9%
(APIServer pid=1) INFO 06-21 15:00:14 [metrics.py:101] SpecDecoding metrics: Mean acceptance length: 2.14, Accepted throughput: 4.35 tokens/s, Drafted throughput: 7.65 tokens/s, Accepted: 174 tokens, Drafted: 306 tokens, Per-position acceptance rate: 0.758, 0.379, Avg Draft acceptance rate: 56.9%
(APIServer pid=1) INFO 06-21 15:00:24 [loggers.py:271] Engine 000: Avg prompt throughput: 0.0 tokens/s, Avg generation throughput: 36.2 tokens/s, Running: 0 reqs, Waiting: 0 reqs, GPU KV cache usage: 39.1%, Prefix cache hit rate: 96.9%
(APIServer pid=1) INFO 06-21 15:00:24 [metrics.py:101] SpecDecoding metrics: Mean acceptance length: 2.18, Accepted throughput: 19.60 tokens/s, Drafted throughput: 33.20 tokens/s, Accepted: 196 tokens, Drafted: 332 tokens, Per-position acceptance rate: 0.747, 0.434, Avg Draft acceptance rate: 59.0%
(APIServer pid=1) INFO 06-21 15:00:34 [loggers.py:271] Engine 000: Avg prompt throughput: 0.0 tokens/s, Avg generation throughput: 0.0 tokens/s, Running: 0 reqs, Waiting: 0 reqs, GPU KV cache usage: 39.1%, Prefix cache hit rate: 96.9%
(APIServer pid=1) INFO:     192.168.1.244:48172 - "POST /v1/chat/completions HTTP/1.1" 200 OK
(APIServer pid=1) INFO:     192.168.1.244:48172 - "POST /v1/chat/completions HTTP/1.1" 200 OK
(APIServer pid=1) INFO:     192.168.1.244:48172 - "POST /v1/chat/completions HTTP/1.1" 200 OK
(APIServer pid=1) INFO 06-21 15:02:24 [loggers.py:271] Engine 000: Avg prompt throughput: 240.1 tokens/s, Avg generation throughput: 9.4 tokens/s, Running: 0 reqs, Waiting: 0 reqs, GPU KV cache usage: 39.3%, Prefix cache hit rate: 96.9%
(APIServer pid=1) INFO 06-21 15:02:24 [metrics.py:101] SpecDecoding metrics: Mean acceptance length: 2.71, Accepted throughput: 0.48 tokens/s, Drafted throughput: 0.57 tokens/s, Accepted: 58 tokens, Drafted: 68 tokens, Per-position acceptance rate: 0.941, 0.765, Avg Draft acceptance rate: 85.3%
(APIServer pid=1) INFO 06-21 15:02:34 [loggers.py:271] Engine 000: Avg prompt throughput: 168.5 tokens/s, Avg generation throughput: 37.5 tokens/s, Running: 1 reqs, Waiting: 0 reqs, GPU KV cache usage: 39.6%, Prefix cache hit rate: 96.9%
(APIServer pid=1) INFO 06-21 15:02:34 [metrics.py:101] SpecDecoding metrics: Mean acceptance length: 2.37, Accepted throughput: 21.60 tokens/s, Drafted throughput: 31.60 tokens/s, Accepted: 216 tokens, Drafted: 316 tokens, Per-position acceptance rate: 0.823, 0.544, Avg Draft acceptance rate: 68.4%
(APIServer pid=1) INFO 06-21 15:02:44 [loggers.py:271] Engine 000: Avg prompt throughput: 0.0 tokens/s, Avg generation throughput: 15.6 tokens/s, Running: 0 reqs, Waiting: 0 reqs, GPU KV cache usage: 39.5%, Prefix cache hit rate: 96.9%
(APIServer pid=1) INFO 06-21 15:02:44 [metrics.py:101] SpecDecoding metrics: Mean acceptance length: 2.17, Accepted throughput: 8.40 tokens/s, Drafted throughput: 14.40 tokens/s, Accepted: 84 tokens, Drafted: 144 tokens, Per-position acceptance rate: 0.736, 0.431, Avg Draft acceptance rate: 58.3%
(APIServer pid=1) INFO 06-21 15:02:54 [loggers.py:271] Engine 000: Avg prompt throughput: 0.0 tokens/s, Avg generation throughput: 0.0 tokens/s, Running: 0 reqs, Waiting: 0 reqs, GPU KV cache usage: 39.5%, Prefix cache hit rate: 96.9%
(APIServer pid=1) INFO:     192.168.1.244:48232 - "POST /v1/chat/completions HTTP/1.1" 200 OK
(APIServer pid=1) INFO:     192.168.1.244:48232 - "POST /v1/chat/completions HTTP/1.1" 200 OK
(APIServer pid=1) INFO 06-21 15:03:04 [loggers.py:271] Engine 000: Avg prompt throughput: 167.7 tokens/s, Avg generation throughput: 21.5 tokens/s, Running: 1 reqs, Waiting: 0 reqs, GPU KV cache usage: 39.9%, Prefix cache hit rate: 96.9%
(APIServer pid=1) INFO 06-21 15:03:04 [metrics.py:101] SpecDecoding metrics: Mean acceptance length: 2.64, Accepted throughput: 6.65 tokens/s, Drafted throughput: 8.10 tokens/s, Accepted: 133 tokens, Drafted: 162 tokens, Per-position acceptance rate: 0.963, 0.679, Avg Draft acceptance rate: 82.1%
(APIServer pid=1) INFO:     192.168.1.244:48232 - "POST /v1/chat/completions HTTP/1.1" 200 OK
(APIServer pid=1) INFO:     192.168.1.244:48232 - "POST /v1/chat/completions HTTP/1.1" 200 OK
(APIServer pid=1) INFO 06-21 15:03:14 [loggers.py:271] Engine 000: Avg prompt throughput: 176.2 tokens/s, Avg generation throughput: 29.1 tokens/s, Running: 1 reqs, Waiting: 0 reqs, GPU KV cache usage: 40.3%, Prefix cache hit rate: 96.9%
(APIServer pid=1) INFO 06-21 15:03:14 [metrics.py:101] SpecDecoding metrics: Mean acceptance length: 2.55, Accepted throughput: 17.70 tokens/s, Drafted throughput: 22.80 tokens/s, Accepted: 177 tokens, Drafted: 228 tokens, Per-position acceptance rate: 0.939, 0.614, Avg Draft acceptance rate: 77.6%
(APIServer pid=1) INFO:     192.168.1.244:46090 - "POST /v1/chat/completions HTTP/1.1" 200 OK
(APIServer pid=1) INFO 06-21 15:03:24 [loggers.py:271] Engine 000: Avg prompt throughput: 104.1 tokens/s, Avg generation throughput: 21.1 tokens/s, Running: 0 reqs, Waiting: 0 reqs, GPU KV cache usage: 40.2%, Prefix cache hit rate: 96.9%
(APIServer pid=1) INFO 06-21 15:03:24 [metrics.py:101] SpecDecoding metrics: Mean acceptance length: 2.75, Accepted throughput: 13.50 tokens/s, Drafted throughput: 15.40 tokens/s, Accepted: 135 tokens, Drafted: 154 tokens, Per-position acceptance rate: 0.987, 0.766, Avg Draft acceptance rate: 87.7%
(APIServer pid=1) INFO:     192.168.1.244:46100 - "POST /v1/chat/completions HTTP/1.1" 200 OK
(APIServer pid=1) INFO 06-21 15:03:34 [loggers.py:271] Engine 000: Avg prompt throughput: 144.5 tokens/s, Avg generation throughput: 15.9 tokens/s, Running: 0 reqs, Waiting: 0 reqs, GPU KV cache usage: 40.4%, Prefix cache hit rate: 97.0%
(APIServer pid=1) INFO 06-21 15:03:34 [metrics.py:101] SpecDecoding metrics: Mean acceptance length: 2.52, Accepted throughput: 9.60 tokens/s, Drafted throughput: 12.60 tokens/s, Accepted: 96 tokens, Drafted: 126 tokens, Per-position acceptance rate: 0.889, 0.635, Avg Draft acceptance rate: 76.2%
(APIServer pid=1) INFO:     192.168.1.244:48288 - "POST /v1/chat/completions HTTP/1.1" 200 OK
(APIServer pid=1) INFO 06-21 15:03:44 [loggers.py:271] Engine 000: Avg prompt throughput: 78.2 tokens/s, Avg generation throughput: 18.4 tokens/s, Running: 0 reqs, Waiting: 0 reqs, GPU KV cache usage: 40.5%, Prefix cache hit rate: 97.0%
(APIServer pid=1) INFO 06-21 15:03:44 [metrics.py:101] SpecDecoding metrics: Mean acceptance length: 2.56, Accepted throughput: 11.20 tokens/s, Drafted throughput: 14.40 tokens/s, Accepted: 112 tokens, Drafted: 144 tokens, Per-position acceptance rate: 0.931, 0.625, Avg Draft acceptance rate: 77.8%
(APIServer pid=1) INFO:     192.168.1.244:48612 - "POST /v1/chat/completions HTTP/1.1" 200 OK
(APIServer pid=1) INFO:     192.168.1.244:48612 - "POST /v1/chat/completions HTTP/1.1" 200 OK
(APIServer pid=1) INFO 06-21 15:03:54 [loggers.py:271] Engine 000: Avg prompt throughput: 193.3 tokens/s, Avg generation throughput: 16.8 tokens/s, Running: 1 reqs, Waiting: 0 reqs, GPU KV cache usage: 41.0%, Prefix cache hit rate: 97.0%
(APIServer pid=1) INFO 06-21 15:03:54 [metrics.py:101] SpecDecoding metrics: Mean acceptance length: 2.55, Accepted throughput: 10.20 tokens/s, Drafted throughput: 13.20 tokens/s, Accepted: 102 tokens, Drafted: 132 tokens, Per-position acceptance rate: 0.909, 0.636, Avg Draft acceptance rate: 77.3%
(APIServer pid=1) INFO:     192.168.1.244:48612 - "POST /v1/chat/completions HTTP/1.1" 200 OK
(APIServer pid=1) INFO 06-21 15:04:04 [loggers.py:271] Engine 000: Avg prompt throughput: 98.3 tokens/s, Avg generation throughput: 37.6 tokens/s, Running: 1 reqs, Waiting: 0 reqs, GPU KV cache usage: 41.3%, Prefix cache hit rate: 97.0%
(APIServer pid=1) INFO 06-21 15:04:04 [metrics.py:101] SpecDecoding metrics: Mean acceptance length: 2.64, Accepted throughput: 23.30 tokens/s, Drafted throughput: 28.40 tokens/s, Accepted: 233 tokens, Drafted: 284 tokens, Per-position acceptance rate: 0.951, 0.690, Avg Draft acceptance rate: 82.0%
(APIServer pid=1) INFO 06-21 15:04:14 [loggers.py:271] Engine 000: Avg prompt throughput: 0.0 tokens/s, Avg generation throughput: 47.4 tokens/s, Running: 1 reqs, Waiting: 0 reqs, GPU KV cache usage: 41.3%, Prefix cache hit rate: 97.0%
(APIServer pid=1) INFO 06-21 15:04:14 [metrics.py:101] SpecDecoding metrics: Mean acceptance length: 2.79, Accepted throughput: 30.40 tokens/s, Drafted throughput: 34.00 tokens/s, Accepted: 304 tokens, Drafted: 340 tokens, Per-position acceptance rate: 0.988, 0.800, Avg Draft acceptance rate: 89.4%
(APIServer pid=1) INFO:     192.168.1.244:45672 - "POST /v1/chat/completions HTTP/1.1" 200 OK
(APIServer pid=1) INFO 06-21 15:04:24 [loggers.py:271] Engine 000: Avg prompt throughput: 163.8 tokens/s, Avg generation throughput: 19.3 tokens/s, Running: 1 reqs, Waiting: 0 reqs, GPU KV cache usage: 41.4%, Prefix cache hit rate: 97.0%
(APIServer pid=1) INFO 06-21 15:04:24 [metrics.py:101] SpecDecoding metrics: Mean acceptance length: 2.61, Accepted throughput: 11.90 tokens/s, Drafted throughput: 14.80 tokens/s, Accepted: 119 tokens, Drafted: 148 tokens, Per-position acceptance rate: 0.919, 0.689, Avg Draft acceptance rate: 80.4%
(APIServer pid=1) INFO 06-21 15:04:34 [loggers.py:271] Engine 000: Avg prompt throughput: 0.0 tokens/s, Avg generation throughput: 15.7 tokens/s, Running: 0 reqs, Waiting: 0 reqs, GPU KV cache usage: 41.2%, Prefix cache hit rate: 97.0%
(APIServer pid=1) INFO 06-21 15:04:34 [metrics.py:101] SpecDecoding metrics: Mean acceptance length: 2.47, Accepted throughput: 9.40 tokens/s, Drafted throughput: 12.80 tokens/s, Accepted: 94 tokens, Drafted: 128 tokens, Per-position acceptance rate: 0.828, 0.641, Avg Draft acceptance rate: 73.4%
(APIServer pid=1) INFO 06-21 15:04:44 [loggers.py:271] Engine 000: Avg prompt throughput: 0.0 tokens/s, Avg generation throughput: 0.0 tokens/s, Running: 0 reqs, Waiting: 0 reqs, GPU KV cache usage: 41.2%, Prefix cache hit rate: 97.0%
(APIServer pid=1) INFO:     192.168.1.244:44620 - "POST /v1/chat/completions HTTP/1.1" 200 OK
(APIServer pid=1) INFO:     192.168.1.244:44620 - "POST /v1/chat/completions HTTP/1.1" 200 OK
(APIServer pid=1) INFO 06-21 15:06:44 [loggers.py:271] Engine 000: Avg prompt throughput: 237.6 tokens/s, Avg generation throughput: 15.9 tokens/s, Running: 1 reqs, Waiting: 0 reqs, GPU KV cache usage: 41.7%, Prefix cache hit rate: 97.0%
(APIServer pid=1) INFO 06-21 15:06:44 [metrics.py:101] SpecDecoding metrics: Mean acceptance length: 2.62, Accepted throughput: 0.75 tokens/s, Drafted throughput: 0.92 tokens/s, Accepted: 97 tokens, Drafted: 120 tokens, Per-position acceptance rate: 0.950, 0.667, Avg Draft acceptance rate: 80.8%
(APIServer pid=1) INFO:     192.168.1.244:44620 - "POST /v1/chat/completions HTTP/1.1" 200 OK
(APIServer pid=1) INFO 06-21 15:06:54 [loggers.py:271] Engine 000: Avg prompt throughput: 119.4 tokens/s, Avg generation throughput: 31.9 tokens/s, Running: 1 reqs, Waiting: 0 reqs, GPU KV cache usage: 41.9%, Prefix cache hit rate: 97.0%
(APIServer pid=1) INFO 06-21 15:06:54 [metrics.py:101] SpecDecoding metrics: Mean acceptance length: 2.25, Accepted throughput: 17.70 tokens/s, Drafted throughput: 28.40 tokens/s, Accepted: 177 tokens, Drafted: 284 tokens, Per-position acceptance rate: 0.768, 0.479, Avg Draft acceptance rate: 62.3%
(APIServer pid=1) INFO:     192.168.1.244:44620 - "POST /v1/chat/completions HTTP/1.1" 200 OK
(APIServer pid=1) INFO 06-21 15:07:04 [loggers.py:271] Engine 000: Avg prompt throughput: 197.5 tokens/s, Avg generation throughput: 25.3 tokens/s, Running: 0 reqs, Waiting: 0 reqs, GPU KV cache usage: 41.9%, Prefix cache hit rate: 97.1%
(APIServer pid=1) INFO 06-21 15:07:04 [metrics.py:101] SpecDecoding metrics: Mean acceptance length: 2.58, Accepted throughput: 15.50 tokens/s, Drafted throughput: 19.60 tokens/s, Accepted: 155 tokens, Drafted: 196 tokens, Per-position acceptance rate: 0.898, 0.684, Avg Draft acceptance rate: 79.1%
(APIServer pid=1) INFO 06-21 15:07:14 [loggers.py:271] Engine 000: Avg prompt throughput: 0.0 tokens/s, Avg generation throughput: 0.0 tokens/s, Running: 0 reqs, Waiting: 0 reqs, GPU KV cache usage: 41.9%, Prefix cache hit rate: 97.1%
(APIServer pid=1) INFO:     192.168.1.244:46170 - "POST /v1/chat/completions HTTP/1.1" 200 OK
(APIServer pid=1) INFO:     192.168.1.244:46170 - "POST /v1/chat/completions HTTP/1.1" 200 OK
(APIServer pid=1) INFO 06-21 15:08:14 [loggers.py:271] Engine 000: Avg prompt throughput: 5027.1 tokens/s, Avg generation throughput: 18.1 tokens/s, Running: 1 reqs, Waiting: 0 reqs, GPU KV cache usage: 42.4%, Prefix cache hit rate: 96.7%
(APIServer pid=1) INFO 06-21 15:08:14 [metrics.py:101] SpecDecoding metrics: Mean acceptance length: 2.24, Accepted throughput: 1.41 tokens/s, Drafted throughput: 2.29 tokens/s, Accepted: 99 tokens, Drafted: 160 tokens, Per-position acceptance rate: 0.750, 0.487, Avg Draft acceptance rate: 61.9%
(APIServer pid=1) INFO:     192.168.1.244:46170 - "POST /v1/chat/completions HTTP/1.1" 200 OK
(APIServer pid=1) INFO 06-21 15:08:24 [loggers.py:271] Engine 000: Avg prompt throughput: 96.2 tokens/s, Avg generation throughput: 33.1 tokens/s, Running: 1 reqs, Waiting: 0 reqs, GPU KV cache usage: 42.6%, Prefix cache hit rate: 96.8%
(APIServer pid=1) INFO 06-21 15:08:24 [metrics.py:101] SpecDecoding metrics: Mean acceptance length: 2.25, Accepted throughput: 18.40 tokens/s, Drafted throughput: 29.40 tokens/s, Accepted: 184 tokens, Drafted: 294 tokens, Per-position acceptance rate: 0.782, 0.469, Avg Draft acceptance rate: 62.6%
(APIServer pid=1) INFO:     192.168.1.244:46252 - "POST /v1/chat/completions HTTP/1.1" 200 OK
(APIServer pid=1) INFO:     192.168.1.244:46252 - "POST /v1/chat/completions HTTP/1.1" 200 OK
(APIServer pid=1) INFO 06-21 15:08:34 [loggers.py:271] Engine 000: Avg prompt throughput: 164.1 tokens/s, Avg generation throughput: 15.0 tokens/s, Running: 1 reqs, Waiting: 0 reqs, GPU KV cache usage: 42.8%, Prefix cache hit rate: 96.8%
(APIServer pid=1) INFO 06-21 15:08:34 [metrics.py:101] SpecDecoding metrics: Mean acceptance length: 2.59, Accepted throughput: 9.20 tokens/s, Drafted throughput: 11.60 tokens/s, Accepted: 92 tokens, Drafted: 116 tokens, Per-position acceptance rate: 0.931, 0.655, Avg Draft acceptance rate: 79.3%
(APIServer pid=1) INFO 06-21 15:08:44 [loggers.py:271] Engine 000: Avg prompt throughput: 0.0 tokens/s, Avg generation throughput: 10.0 tokens/s, Running: 0 reqs, Waiting: 0 reqs, GPU KV cache usage: 42.7%, Prefix cache hit rate: 96.8%
(APIServer pid=1) INFO 06-21 15:08:44 [metrics.py:101] SpecDecoding metrics: Mean acceptance length: 2.43, Accepted throughput: 6.00 tokens/s, Drafted throughput: 8.40 tokens/s, Accepted: 60 tokens, Drafted: 84 tokens, Per-position acceptance rate: 0.810, 0.619, Avg Draft acceptance rate: 71.4%
(APIServer pid=1) INFO 06-21 15:08:54 [loggers.py:271] Engine 000: Avg prompt throughput: 0.0 tokens/s, Avg generation throughput: 0.0 tokens/s, Running: 0 reqs, Waiting: 0 reqs, GPU KV cache usage: 42.7%, Prefix cache hit rate: 96.8%
(APIServer pid=1) INFO:     192.168.1.244:45492 - "POST /v1/chat/completions HTTP/1.1" 200 OK
(APIServer pid=1) INFO 06-21 15:15:35 [loggers.py:271] Engine 000: Avg prompt throughput: 102.0 tokens/s, Avg generation throughput: 27.7 tokens/s, Running: 1 reqs, Waiting: 0 reqs, GPU KV cache usage: 43.1%, Prefix cache hit rate: 96.8%
(APIServer pid=1) INFO 06-21 15:15:35 [metrics.py:101] SpecDecoding metrics: Mean acceptance length: 2.17, Accepted throughput: 0.36 tokens/s, Drafted throughput: 0.62 tokens/s, Accepted: 149 tokens, Drafted: 254 tokens, Per-position acceptance rate: 0.740, 0.433, Avg Draft acceptance rate: 58.7%
(APIServer pid=1) INFO:     192.168.1.244:48558 - "POST /v1/chat/completions HTTP/1.1" 200 OK
(APIServer pid=1) INFO 06-21 15:15:45 [loggers.py:271] Engine 000: Avg prompt throughput: 0.0 tokens/s, Avg generation throughput: 17.1 tokens/s, Running: 0 reqs, Waiting: 0 reqs, GPU KV cache usage: 42.9%, Prefix cache hit rate: 96.8%
(APIServer pid=1) INFO 06-21 15:15:45 [metrics.py:101] SpecDecoding metrics: Mean acceptance length: 2.26, Accepted throughput: 9.60 tokens/s, Drafted throughput: 15.20 tokens/s, Accepted: 96 tokens, Drafted: 152 tokens, Per-position acceptance rate: 0.750, 0.513, Avg Draft acceptance rate: 63.2%
(APIServer pid=1) INFO:     192.168.1.244:48558 - "POST /v1/chat/completions HTTP/1.1" 200 OK
(APIServer pid=1) INFO 06-21 15:15:55 [loggers.py:271] Engine 000: Avg prompt throughput: 208.3 tokens/s, Avg generation throughput: 35.6 tokens/s, Running: 1 reqs, Waiting: 0 reqs, GPU KV cache usage: 43.4%, Prefix cache hit rate: 96.8%
(APIServer pid=1) INFO 06-21 15:15:55 [metrics.py:101] SpecDecoding metrics: Mean acceptance length: 2.43, Accepted throughput: 20.90 tokens/s, Drafted throughput: 29.20 tokens/s, Accepted: 209 tokens, Drafted: 292 tokens, Per-position acceptance rate: 0.870, 0.562, Avg Draft acceptance rate: 71.6%
(APIServer pid=1) INFO 06-21 15:16:05 [loggers.py:271] Engine 000: Avg prompt throughput: 0.0 tokens/s, Avg generation throughput: 19.9 tokens/s, Running: 0 reqs, Waiting: 0 reqs, GPU KV cache usage: 43.2%, Prefix cache hit rate: 96.8%
(APIServer pid=1) INFO 06-21 15:16:05 [metrics.py:101] SpecDecoding metrics: Mean acceptance length: 2.34, Accepted throughput: 11.40 tokens/s, Drafted throughput: 17.00 tokens/s, Accepted: 114 tokens, Drafted: 170 tokens, Per-position acceptance rate: 0.812, 0.529, Avg Draft acceptance rate: 67.1%
(APIServer pid=1) INFO 06-21 15:16:15 [loggers.py:271] Engine 000: Avg prompt throughput: 0.0 tokens/s, Avg generation throughput: 0.0 tokens/s, Running: 0 reqs, Waiting: 0 reqs, GPU KV cache usage: 43.2%, Prefix cache hit rate: 96.8%
(APIServer pid=1) INFO:     192.168.1.244:47558 - "POST /v1/chat/completions HTTP/1.1" 200 OK
(APIServer pid=1) INFO:     192.168.1.244:47558 - "POST /v1/chat/completions HTTP/1.1" 200 OK
(APIServer pid=1) INFO 06-21 15:23:35 [loggers.py:271] Engine 000: Avg prompt throughput: 606.0 tokens/s, Avg generation throughput: 11.6 tokens/s, Running: 0 reqs, Waiting: 0 reqs, GPU KV cache usage: 43.5%, Prefix cache hit rate: 96.8%
(APIServer pid=1) INFO 06-21 15:23:35 [metrics.py:101] SpecDecoding metrics: Mean acceptance length: 2.45, Accepted throughput: 0.15 tokens/s, Drafted throughput: 0.21 tokens/s, Accepted: 68 tokens, Drafted: 94 tokens, Per-position acceptance rate: 0.957, 0.489, Avg Draft acceptance rate: 72.3%
(APIServer pid=1) INFO:     192.168.1.244:47558 - "POST /v1/chat/completions HTTP/1.1" 200 OK
(APIServer pid=1) INFO 06-21 15:23:45 [loggers.py:271] Engine 000: Avg prompt throughput: 114.2 tokens/s, Avg generation throughput: 34.0 tokens/s, Running: 1 reqs, Waiting: 0 reqs, GPU KV cache usage: 43.7%, Prefix cache hit rate: 96.8%
(APIServer pid=1) INFO 06-21 15:23:45 [metrics.py:101] SpecDecoding metrics: Mean acceptance length: 2.23, Accepted throughput: 18.70 tokens/s, Drafted throughput: 30.40 tokens/s, Accepted: 187 tokens, Drafted: 304 tokens, Per-position acceptance rate: 0.789, 0.441, Avg Draft acceptance rate: 61.5%
(APIServer pid=1) INFO 06-21 15:23:55 [loggers.py:271] Engine 000: Avg prompt throughput: 0.0 tokens/s, Avg generation throughput: 39.2 tokens/s, Running: 0 reqs, Waiting: 0 reqs, GPU KV cache usage: 43.6%, Prefix cache hit rate: 96.8%
(APIServer pid=1) INFO 06-21 15:23:55 [metrics.py:101] SpecDecoding metrics: Mean acceptance length: 2.30, Accepted throughput: 22.20 tokens/s, Drafted throughput: 34.19 tokens/s, Accepted: 222 tokens, Drafted: 342 tokens, Per-position acceptance rate: 0.819, 0.480, Avg Draft acceptance rate: 64.9%
(APIServer pid=1) INFO 06-21 15:24:05 [loggers.py:271] Engine 000: Avg prompt throughput: 0.0 tokens/s, Avg generation throughput: 0.0 tokens/s, Running: 0 reqs, Waiting: 0 reqs, GPU KV cache usage: 43.6%, Prefix cache hit rate: 96.8%
(APIServer pid=1) INFO:     192.168.1.244:45400 - "POST /v1/chat/completions HTTP/1.1" 200 OK
(APIServer pid=1) INFO:     192.168.1.244:45400 - "POST /v1/chat/completions HTTP/1.1" 200 OK
(APIServer pid=1) INFO 06-21 15:24:15 [loggers.py:271] Engine 000: Avg prompt throughput: 56.0 tokens/s, Avg generation throughput: 5.5 tokens/s, Running: 0 reqs, Waiting: 0 reqs, GPU KV cache usage: 43.7%, Prefix cache hit rate: 96.8%
(APIServer pid=1) INFO 06-21 15:24:15 [metrics.py:101] SpecDecoding metrics: Mean acceptance length: 2.00, Accepted throughput: 1.35 tokens/s, Drafted throughput: 2.70 tokens/s, Accepted: 27 tokens, Drafted: 54 tokens, Per-position acceptance rate: 0.593, 0.407, Avg Draft acceptance rate: 50.0%
(APIServer pid=1) INFO:     192.168.1.244:45400 - "POST /v1/chat/completions HTTP/1.1" 200 OK
(APIServer pid=1) INFO:     192.168.1.244:45400 - "POST /v1/chat/completions HTTP/1.1" 200 OK
(APIServer pid=1) INFO:     192.168.1.244:45400 - "POST /v1/chat/completions HTTP/1.1" 200 OK
(APIServer pid=1) INFO 06-21 15:24:25 [loggers.py:271] Engine 000: Avg prompt throughput: 352.0 tokens/s, Avg generation throughput: 19.7 tokens/s, Running: 0 reqs, Waiting: 0 reqs, GPU KV cache usage: 44.3%, Prefix cache hit rate: 96.9%
(APIServer pid=1) INFO 06-21 15:24:25 [metrics.py:101] SpecDecoding metrics: Mean acceptance length: 2.69, Accepted throughput: 12.20 tokens/s, Drafted throughput: 14.40 tokens/s, Accepted: 122 tokens, Drafted: 144 tokens, Per-position acceptance rate: 0.931, 0.764, Avg Draft acceptance rate: 84.7%
(APIServer pid=1) INFO:     192.168.1.244:45400 - "POST /v1/chat/completions HTTP/1.1" 200 OK
(APIServer pid=1) INFO 06-21 15:24:35 [loggers.py:271] Engine 000: Avg prompt throughput: 135.4 tokens/s, Avg generation throughput: 24.6 tokens/s, Running: 0 reqs, Waiting: 0 reqs, GPU KV cache usage: 44.4%, Prefix cache hit rate: 96.9%
(APIServer pid=1) INFO 06-21 15:24:35 [metrics.py:101] SpecDecoding metrics: Mean acceptance length: 2.60, Accepted throughput: 15.20 tokens/s, Drafted throughput: 19.00 tokens/s, Accepted: 152 tokens, Drafted: 190 tokens, Per-position acceptance rate: 0.979, 0.621, Avg Draft acceptance rate: 80.0%
(APIServer pid=1) INFO:     192.168.1.244:46140 - "POST /v1/chat/completions HTTP/1.1" 200 OK
(APIServer pid=1) INFO 06-21 15:24:45 [loggers.py:271] Engine 000: Avg prompt throughput: 119.8 tokens/s, Avg generation throughput: 35.2 tokens/s, Running: 1 reqs, Waiting: 0 reqs, GPU KV cache usage: 44.7%, Prefix cache hit rate: 96.9%
(APIServer pid=1) INFO 06-21 15:24:45 [metrics.py:101] SpecDecoding metrics: Mean acceptance length: 2.76, Accepted throughput: 22.40 tokens/s, Drafted throughput: 25.40 tokens/s, Accepted: 224 tokens, Drafted: 254 tokens, Per-position acceptance rate: 0.992, 0.772, Avg Draft acceptance rate: 88.2%
(APIServer pid=1) INFO:     192.168.1.244:45320 - "POST /v1/chat/completions HTTP/1.1" 200 OK
(APIServer pid=1) INFO 06-21 15:24:55 [loggers.py:271] Engine 000: Avg prompt throughput: 111.8 tokens/s, Avg generation throughput: 19.9 tokens/s, Running: 1 reqs, Waiting: 0 reqs, GPU KV cache usage: 44.8%, Prefix cache hit rate: 96.9%
(APIServer pid=1) INFO 06-21 15:24:55 [metrics.py:101] SpecDecoding metrics: Mean acceptance length: 2.58, Accepted throughput: 12.20 tokens/s, Drafted throughput: 15.40 tokens/s, Accepted: 122 tokens, Drafted: 154 tokens, Per-position acceptance rate: 0.948, 0.636, Avg Draft acceptance rate: 79.2%
(APIServer pid=1) INFO:     192.168.1.244:45962 - "POST /v1/chat/completions HTTP/1.1" 200 OK
(APIServer pid=1) INFO 06-21 15:25:05 [loggers.py:271] Engine 000: Avg prompt throughput: 0.0 tokens/s, Avg generation throughput: 21.9 tokens/s, Running: 0 reqs, Waiting: 0 reqs, GPU KV cache usage: 44.7%, Prefix cache hit rate: 96.9%
(APIServer pid=1) INFO 06-21 15:25:05 [metrics.py:101] SpecDecoding metrics: Mean acceptance length: 2.70, Accepted throughput: 13.90 tokens/s, Drafted throughput: 16.40 tokens/s, Accepted: 139 tokens, Drafted: 164 tokens, Per-position acceptance rate: 0.951, 0.744, Avg Draft acceptance rate: 84.8%
(APIServer pid=1) INFO:     192.168.1.244:45962 - "POST /v1/chat/completions HTTP/1.1" 200 OK
(APIServer pid=1) INFO 06-21 15:25:15 [loggers.py:271] Engine 000: Avg prompt throughput: 213.9 tokens/s, Avg generation throughput: 32.1 tokens/s, Running: 1 reqs, Waiting: 0 reqs, GPU KV cache usage: 45.2%, Prefix cache hit rate: 96.9%
(APIServer pid=1) INFO 06-21 15:25:15 [metrics.py:101] SpecDecoding metrics: Mean acceptance length: 2.36, Accepted throughput: 18.40 tokens/s, Drafted throughput: 27.00 tokens/s, Accepted: 184 tokens, Drafted: 270 tokens, Per-position acceptance rate: 0.815, 0.548, Avg Draft acceptance rate: 68.1%
(APIServer pid=1) INFO:     192.168.1.244:45962 - "POST /v1/chat/completions HTTP/1.1" 200 OK
(APIServer pid=1) INFO:     192.168.1.244:45962 - "POST /v1/chat/completions HTTP/1.1" 200 OK
(APIServer pid=1) INFO:     192.168.1.244:45962 - "POST /v1/chat/completions HTTP/1.1" 200 OK
(APIServer pid=1) INFO 06-21 15:25:25 [loggers.py:271] Engine 000: Avg prompt throughput: 197.3 tokens/s, Avg generation throughput: 23.8 tokens/s, Running: 0 reqs, Waiting: 0 reqs, GPU KV cache usage: 45.3%, Prefix cache hit rate: 96.9%
(APIServer pid=1) INFO 06-21 15:25:25 [metrics.py:101] SpecDecoding metrics: Mean acceptance length: 2.59, Accepted throughput: 14.60 tokens/s, Drafted throughput: 18.40 tokens/s, Accepted: 146 tokens, Drafted: 184 tokens, Per-position acceptance rate: 0.924, 0.663, Avg Draft acceptance rate: 79.3%
(APIServer pid=1) INFO:     192.168.1.244:45962 - "POST /v1/chat/completions HTTP/1.1" 200 OK
(APIServer pid=1) INFO:     192.168.1.244:45962 - "POST /v1/chat/completions HTTP/1.1" 200 OK
(APIServer pid=1) INFO 06-21 15:25:35 [loggers.py:271] Engine 000: Avg prompt throughput: 282.7 tokens/s, Avg generation throughput: 28.2 tokens/s, Running: 1 reqs, Waiting: 0 reqs, GPU KV cache usage: 45.8%, Prefix cache hit rate: 97.0%
(APIServer pid=1) INFO 06-21 15:25:35 [metrics.py:101] SpecDecoding metrics: Mean acceptance length: 2.63, Accepted throughput: 17.30 tokens/s, Drafted throughput: 21.20 tokens/s, Accepted: 173 tokens, Drafted: 212 tokens, Per-position acceptance rate: 0.925, 0.708, Avg Draft acceptance rate: 81.6%
(APIServer pid=1) INFO 06-21 15:25:45 [loggers.py:271] Engine 000: Avg prompt throughput: 0.0 tokens/s, Avg generation throughput: 41.2 tokens/s, Running: 0 reqs, Waiting: 0 reqs, GPU KV cache usage: 45.7%, Prefix cache hit rate: 97.0%
(APIServer pid=1) INFO 06-21 15:25:45 [metrics.py:101] SpecDecoding metrics: Mean acceptance length: 2.82, Accepted throughput: 26.70 tokens/s, Drafted throughput: 29.40 tokens/s, Accepted: 267 tokens, Drafted: 294 tokens, Per-position acceptance rate: 1.000, 0.816, Avg Draft acceptance rate: 90.8%
(APIServer pid=1) INFO:     192.168.1.244:46180 - "POST /v1/chat/completions HTTP/1.1" 200 OK
(APIServer pid=1) INFO 06-21 15:25:55 [loggers.py:271] Engine 000: Avg prompt throughput: 118.7 tokens/s, Avg generation throughput: 25.0 tokens/s, Running: 1 reqs, Waiting: 0 reqs, GPU KV cache usage: 46.0%, Prefix cache hit rate: 97.0%
(APIServer pid=1) INFO 06-21 15:25:55 [metrics.py:101] SpecDecoding metrics: Mean acceptance length: 2.57, Accepted throughput: 15.20 tokens/s, Drafted throughput: 19.40 tokens/s, Accepted: 152 tokens, Drafted: 194 tokens, Per-position acceptance rate: 0.876, 0.691, Avg Draft acceptance rate: 78.4%
(APIServer pid=1) INFO 06-21 15:26:05 [loggers.py:271] Engine 000: Avg prompt throughput: 0.0 tokens/s, Avg generation throughput: 45.6 tokens/s, Running: 1 reqs, Waiting: 0 reqs, GPU KV cache usage: 46.0%, Prefix cache hit rate: 97.0%
(APIServer pid=1) INFO 06-21 15:26:05 [metrics.py:101] SpecDecoding metrics: Mean acceptance length: 2.62, Accepted throughput: 28.20 tokens/s, Drafted throughput: 34.80 tokens/s, Accepted: 282 tokens, Drafted: 348 tokens, Per-position acceptance rate: 0.925, 0.695, Avg Draft acceptance rate: 81.0%
(APIServer pid=1) INFO:     192.168.1.244:45218 - "POST /v1/chat/completions HTTP/1.1" 200 OK
(APIServer pid=1) INFO 06-21 15:26:15 [loggers.py:271] Engine 000: Avg prompt throughput: 177.7 tokens/s, Avg generation throughput: 18.2 tokens/s, Running: 1 reqs, Waiting: 0 reqs, GPU KV cache usage: 46.1%, Prefix cache hit rate: 97.0%
(APIServer pid=1) INFO 06-21 15:26:15 [metrics.py:101] SpecDecoding metrics: Mean acceptance length: 2.61, Accepted throughput: 11.30 tokens/s, Drafted throughput: 14.00 tokens/s, Accepted: 113 tokens, Drafted: 140 tokens, Per-position acceptance rate: 0.929, 0.686, Avg Draft acceptance rate: 80.7%
(APIServer pid=1) INFO:     192.168.1.244:45218 - "POST /v1/chat/completions HTTP/1.1" 200 OK
(APIServer pid=1) INFO 06-21 15:26:25 [loggers.py:271] Engine 000: Avg prompt throughput: 0.0 tokens/s, Avg generation throughput: 28.8 tokens/s, Running: 0 reqs, Waiting: 0 reqs, GPU KV cache usage: 46.1%, Prefix cache hit rate: 97.0%
(APIServer pid=1) INFO 06-21 15:26:25 [metrics.py:101] SpecDecoding metrics: Mean acceptance length: 2.62, Accepted throughput: 17.80 tokens/s, Drafted throughput: 22.00 tokens/s, Accepted: 178 tokens, Drafted: 220 tokens, Per-position acceptance rate: 0.991, 0.627, Avg Draft acceptance rate: 80.9%
(APIServer pid=1) INFO 06-21 15:26:35 [loggers.py:271] Engine 000: Avg prompt throughput: 0.0 tokens/s, Avg generation throughput: 0.0 tokens/s, Running: 1 reqs, Waiting: 0 reqs, GPU KV cache usage: 64.6%, Prefix cache hit rate: 96.7%
(APIServer pid=1) INFO 06-21 15:26:45 [loggers.py:271] Engine 000: Avg prompt throughput: 4171.4 tokens/s, Avg generation throughput: 10.1 tokens/s, Running: 1 reqs, Waiting: 0 reqs, GPU KV cache usage: 46.4%, Prefix cache hit rate: 96.7%
(APIServer pid=1) INFO 06-21 15:26:45 [metrics.py:101] SpecDecoding metrics: Mean acceptance length: 2.33, Accepted throughput: 2.85 tokens/s, Drafted throughput: 4.30 tokens/s, Accepted: 57 tokens, Drafted: 86 tokens, Per-position acceptance rate: 0.744, 0.581, Avg Draft acceptance rate: 66.3%
(APIServer pid=1) INFO:     192.168.1.244:45218 - "POST /v1/chat/completions HTTP/1.1" 200 OK
(APIServer pid=1) INFO 06-21 15:26:55 [loggers.py:271] Engine 000: Avg prompt throughput: 113.3 tokens/s, Avg generation throughput: 34.6 tokens/s, Running: 1 reqs, Waiting: 0 reqs, GPU KV cache usage: 46.6%, Prefix cache hit rate: 96.7%
(APIServer pid=1) INFO 06-21 15:26:55 [metrics.py:101] SpecDecoding metrics: Mean acceptance length: 2.43, Accepted throughput: 20.30 tokens/s, Drafted throughput: 28.40 tokens/s, Accepted: 203 tokens, Drafted: 284 tokens, Per-position acceptance rate: 0.894, 0.535, Avg Draft acceptance rate: 71.5%
(APIServer pid=1) INFO:     192.168.1.244:45218 - "POST /v1/chat/completions HTTP/1.1" 200 OK
(APIServer pid=1) INFO 06-21 15:27:05 [loggers.py:271] Engine 000: Avg prompt throughput: 116.5 tokens/s, Avg generation throughput: 34.6 tokens/s, Running: 1 reqs, Waiting: 0 reqs, GPU KV cache usage: 46.7%, Prefix cache hit rate: 96.8%
(APIServer pid=1) INFO 06-21 15:27:05 [metrics.py:101] SpecDecoding metrics: Mean acceptance length: 2.38, Accepted throughput: 20.00 tokens/s, Drafted throughput: 29.00 tokens/s, Accepted: 200 tokens, Drafted: 290 tokens, Per-position acceptance rate: 0.841, 0.538, Avg Draft acceptance rate: 69.0%
(APIServer pid=1) INFO 06-21 15:27:15 [loggers.py:271] Engine 000: Avg prompt throughput: 0.0 tokens/s, Avg generation throughput: 14.4 tokens/s, Running: 0 reqs, Waiting: 0 reqs, GPU KV cache usage: 46.5%, Prefix cache hit rate: 96.8%
(APIServer pid=1) INFO 06-21 15:27:15 [metrics.py:101] SpecDecoding metrics: Mean acceptance length: 2.43, Accepted throughput: 8.60 tokens/s, Drafted throughput: 12.00 tokens/s, Accepted: 86 tokens, Drafted: 120 tokens, Per-position acceptance rate: 0.900, 0.533, Avg Draft acceptance rate: 71.7%
(APIServer pid=1) INFO 06-21 15:27:25 [loggers.py:271] Engine 000: Avg prompt throughput: 0.0 tokens/s, Avg generation throughput: 0.0 tokens/s, Running: 0 reqs, Waiting: 0 reqs, GPU KV cache usage: 46.5%, Prefix cache hit rate: 96.8%
(APIServer pid=1) INFO:     192.168.1.244:46382 - "POST /v1/chat/completions HTTP/1.1" 200 OK
(APIServer pid=1) INFO:     192.168.1.244:46382 - "POST /v1/chat/completions HTTP/1.1" 200 OK
(APIServer pid=1) INFO:     192.168.1.244:46382 - "POST /v1/chat/completions HTTP/1.1" 200 OK
(APIServer pid=1) INFO 06-21 15:28:15 [loggers.py:271] Engine 000: Avg prompt throughput: 231.1 tokens/s, Avg generation throughput: 22.8 tokens/s, Running: 1 reqs, Waiting: 0 reqs, GPU KV cache usage: 47.2%, Prefix cache hit rate: 96.8%
(APIServer pid=1) INFO 06-21 15:28:15 [metrics.py:101] SpecDecoding metrics: Mean acceptance length: 2.48, Accepted throughput: 2.25 tokens/s, Drafted throughput: 3.03 tokens/s, Accepted: 135 tokens, Drafted: 182 tokens, Per-position acceptance rate: 0.879, 0.604, Avg Draft acceptance rate: 74.2%
(APIServer pid=1) INFO:     192.168.1.244:46382 - "POST /v1/chat/completions HTTP/1.1" 200 OK
(APIServer pid=1) INFO:     192.168.1.244:46382 - "POST /v1/chat/completions HTTP/1.1" 200 OK
(APIServer pid=1) INFO 06-21 15:28:25 [loggers.py:271] Engine 000: Avg prompt throughput: 280.7 tokens/s, Avg generation throughput: 29.1 tokens/s, Running: 1 reqs, Waiting: 0 reqs, GPU KV cache usage: 47.5%, Prefix cache hit rate: 96.8%
(APIServer pid=1) INFO 06-21 15:28:25 [metrics.py:101] SpecDecoding metrics: Mean acceptance length: 2.54, Accepted throughput: 17.60 tokens/s, Drafted throughput: 22.80 tokens/s, Accepted: 176 tokens, Drafted: 228 tokens, Per-position acceptance rate: 0.904, 0.640, Avg Draft acceptance rate: 77.2%
(APIServer pid=1) INFO 06-21 15:28:35 [loggers.py:271] Engine 000: Avg prompt throughput: 0.0 tokens/s, Avg generation throughput: 46.4 tokens/s, Running: 1 reqs, Waiting: 0 reqs, GPU KV cache usage: 47.5%, Prefix cache hit rate: 96.8%
(APIServer pid=1) INFO 06-21 15:28:35 [metrics.py:101] SpecDecoding metrics: Mean acceptance length: 2.70, Accepted throughput: 29.20 tokens/s, Drafted throughput: 34.40 tokens/s, Accepted: 292 tokens, Drafted: 344 tokens, Per-position acceptance rate: 0.959, 0.738, Avg Draft acceptance rate: 84.9%
(APIServer pid=1) INFO:     192.168.1.244:47974 - "POST /v1/chat/completions HTTP/1.1" 200 OK
(APIServer pid=1) INFO:     192.168.1.244:47974 - "POST /v1/chat/completions HTTP/1.1" 200 OK
(APIServer pid=1) INFO 06-21 15:28:45 [loggers.py:271] Engine 000: Avg prompt throughput: 134.6 tokens/s, Avg generation throughput: 15.8 tokens/s, Running: 0 reqs, Waiting: 0 reqs, GPU KV cache usage: 47.4%, Prefix cache hit rate: 96.8%
(APIServer pid=1) INFO 06-21 15:28:45 [metrics.py:101] SpecDecoding metrics: Mean acceptance length: 2.52, Accepted throughput: 9.60 tokens/s, Drafted throughput: 12.60 tokens/s, Accepted: 96 tokens, Drafted: 126 tokens, Per-position acceptance rate: 0.921, 0.603, Avg Draft acceptance rate: 76.2%
(APIServer pid=1) INFO 06-21 15:28:55 [loggers.py:271] Engine 000: Avg prompt throughput: 83.2 tokens/s, Avg generation throughput: 41.6 tokens/s, Running: 1 reqs, Waiting: 0 reqs, GPU KV cache usage: 47.7%, Prefix cache hit rate: 96.8%
(APIServer pid=1) INFO 06-21 15:28:55 [metrics.py:101] SpecDecoding metrics: Mean acceptance length: 2.55, Accepted throughput: 25.20 tokens/s, Drafted throughput: 32.60 tokens/s, Accepted: 252 tokens, Drafted: 326 tokens, Per-position acceptance rate: 0.883, 0.663, Avg Draft acceptance rate: 77.3%
(APIServer pid=1) INFO:     192.168.1.244:45174 - "POST /v1/chat/completions HTTP/1.1" 200 OK
(APIServer pid=1) INFO 06-21 15:29:05 [loggers.py:271] Engine 000: Avg prompt throughput: 0.0 tokens/s, Avg generation throughput: 21.4 tokens/s, Running: 0 reqs, Waiting: 0 reqs, GPU KV cache usage: 47.6%, Prefix cache hit rate: 96.8%
(APIServer pid=1) INFO 06-21 15:29:05 [metrics.py:101] SpecDecoding metrics: Mean acceptance length: 2.79, Accepted throughput: 13.80 tokens/s, Drafted throughput: 15.40 tokens/s, Accepted: 138 tokens, Drafted: 154 tokens, Per-position acceptance rate: 1.000, 0.792, Avg Draft acceptance rate: 89.6%
(APIServer pid=1) INFO:     192.168.1.244:45174 - "POST /v1/chat/completions HTTP/1.1" 200 OK
(APIServer pid=1) INFO 06-21 15:29:15 [loggers.py:271] Engine 000: Avg prompt throughput: 243.6 tokens/s, Avg generation throughput: 33.5 tokens/s, Running: 1 reqs, Waiting: 0 reqs, GPU KV cache usage: 48.0%, Prefix cache hit rate: 96.8%
(APIServer pid=1) INFO 06-21 15:29:15 [metrics.py:101] SpecDecoding metrics: Mean acceptance length: 2.44, Accepted throughput: 19.70 tokens/s, Drafted throughput: 27.40 tokens/s, Accepted: 197 tokens, Drafted: 274 tokens, Per-position acceptance rate: 0.883, 0.555, Avg Draft acceptance rate: 71.9%
(APIServer pid=1) INFO:     192.168.1.244:45138 - "POST /v1/chat/completions HTTP/1.1" 200 OK
(APIServer pid=1) INFO:     192.168.1.244:45138 - "POST /v1/chat/completions HTTP/1.1" 200 OK
(APIServer pid=1) INFO 06-21 15:29:25 [loggers.py:271] Engine 000: Avg prompt throughput: 470.7 tokens/s, Avg generation throughput: 8.2 tokens/s, Running: 1 reqs, Waiting: 0 reqs, GPU KV cache usage: 48.1%, Prefix cache hit rate: 96.8%
(APIServer pid=1) INFO 06-21 15:29:25 [metrics.py:101] SpecDecoding metrics: Mean acceptance length: 2.41, Accepted throughput: 4.80 tokens/s, Drafted throughput: 6.80 tokens/s, Accepted: 48 tokens, Drafted: 68 tokens, Per-position acceptance rate: 0.824, 0.588, Avg Draft acceptance rate: 70.6%
(APIServer pid=1) INFO 06-21 15:29:35 [loggers.py:271] Engine 000: Avg prompt throughput: 0.0 tokens/s, Avg generation throughput: 46.1 tokens/s, Running: 1 reqs, Waiting: 0 reqs, GPU KV cache usage: 48.2%, Prefix cache hit rate: 96.8%
(APIServer pid=1) INFO 06-21 15:29:35 [metrics.py:101] SpecDecoding metrics: Mean acceptance length: 2.70, Accepted throughput: 29.00 tokens/s, Drafted throughput: 34.19 tokens/s, Accepted: 290 tokens, Drafted: 342 tokens, Per-position acceptance rate: 0.971, 0.725, Avg Draft acceptance rate: 84.8%
(APIServer pid=1) INFO:     192.168.1.244:45964 - "POST /v1/chat/completions HTTP/1.1" 200 OK
(APIServer pid=1) INFO:     192.168.1.244:45964 - "POST /v1/chat/completions HTTP/1.1" 200 OK
(APIServer pid=1) INFO 06-21 15:29:45 [loggers.py:271] Engine 000: Avg prompt throughput: 130.6 tokens/s, Avg generation throughput: 14.5 tokens/s, Running: 0 reqs, Waiting: 0 reqs, GPU KV cache usage: 48.2%, Prefix cache hit rate: 96.8%
(APIServer pid=1) INFO 06-21 15:29:45 [metrics.py:101] SpecDecoding metrics: Mean acceptance length: 2.69, Accepted throughput: 9.10 tokens/s, Drafted throughput: 10.80 tokens/s, Accepted: 91 tokens, Drafted: 108 tokens, Per-position acceptance rate: 0.981, 0.704, Avg Draft acceptance rate: 84.3%
(APIServer pid=1) INFO 06-21 15:29:55 [loggers.py:271] Engine 000: Avg prompt throughput: 76.4 tokens/s, Avg generation throughput: 36.3 tokens/s, Running: 1 reqs, Waiting: 0 reqs, GPU KV cache usage: 48.5%, Prefix cache hit rate: 96.8%
(APIServer pid=1) INFO 06-21 15:29:55 [metrics.py:101] SpecDecoding metrics: Mean acceptance length: 2.12, Accepted throughput: 19.10 tokens/s, Drafted throughput: 34.19 tokens/s, Accepted: 191 tokens, Drafted: 342 tokens, Per-position acceptance rate: 0.737, 0.380, Avg Draft acceptance rate: 55.8%
(APIServer pid=1) INFO 06-21 15:30:05 [loggers.py:271] Engine 000: Avg prompt throughput: 0.0 tokens/s, Avg generation throughput: 40.4 tokens/s, Running: 0 reqs, Waiting: 0 reqs, GPU KV cache usage: 48.4%, Prefix cache hit rate: 96.8%
(APIServer pid=1) INFO 06-21 15:30:05 [metrics.py:101] SpecDecoding metrics: Mean acceptance length: 2.81, Accepted throughput: 26.10 tokens/s, Drafted throughput: 28.80 tokens/s, Accepted: 261 tokens, Drafted: 288 tokens, Per-position acceptance rate: 1.000, 0.812, Avg Draft acceptance rate: 90.6%
(APIServer pid=1) INFO:     192.168.1.244:48232 - "POST /v1/chat/completions HTTP/1.1" 200 OK
(APIServer pid=1) INFO 06-21 15:30:15 [loggers.py:271] Engine 000: Avg prompt throughput: 137.8 tokens/s, Avg generation throughput: 24.2 tokens/s, Running: 0 reqs, Waiting: 0 reqs, GPU KV cache usage: 48.5%, Prefix cache hit rate: 96.8%
(APIServer pid=1) INFO 06-21 15:30:15 [metrics.py:101] SpecDecoding metrics: Mean acceptance length: 2.55, Accepted throughput: 14.70 tokens/s, Drafted throughput: 19.00 tokens/s, Accepted: 147 tokens, Drafted: 190 tokens, Per-position acceptance rate: 0.947, 0.600, Avg Draft acceptance rate: 77.4%
(APIServer pid=1) INFO:     192.168.1.244:48232 - "POST /v1/chat/completions HTTP/1.1" 200 OK
(APIServer pid=1) INFO:     192.168.1.244:48232 - "POST /v1/chat/completions HTTP/1.1" 200 OK
(APIServer pid=1) INFO 06-21 15:30:25 [loggers.py:271] Engine 000: Avg prompt throughput: 233.4 tokens/s, Avg generation throughput: 25.5 tokens/s, Running: 1 reqs, Waiting: 0 reqs, GPU KV cache usage: 49.0%, Prefix cache hit rate: 96.8%
(APIServer pid=1) INFO 06-21 15:30:25 [metrics.py:101] SpecDecoding metrics: Mean acceptance length: 2.39, Accepted throughput: 14.70 tokens/s, Drafted throughput: 21.20 tokens/s, Accepted: 147 tokens, Drafted: 212 tokens, Per-position acceptance rate: 0.868, 0.519, Avg Draft acceptance rate: 69.3%
(APIServer pid=1) INFO:     192.168.1.244:48232 - "POST /v1/chat/completions HTTP/1.1" 200 OK
(APIServer pid=1) INFO 06-21 15:30:35 [loggers.py:271] Engine 000: Avg prompt throughput: 102.0 tokens/s, Avg generation throughput: 27.4 tokens/s, Running: 0 reqs, Waiting: 0 reqs, GPU KV cache usage: 49.1%, Prefix cache hit rate: 96.8%
(APIServer pid=1) INFO 06-21 15:30:35 [metrics.py:101] SpecDecoding metrics: Mean acceptance length: 2.34, Accepted throughput: 15.70 tokens/s, Drafted throughput: 23.40 tokens/s, Accepted: 157 tokens, Drafted: 234 tokens, Per-position acceptance rate: 0.803, 0.538, Avg Draft acceptance rate: 67.1%
(APIServer pid=1) INFO 06-21 15:30:45 [loggers.py:271] Engine 000: Avg prompt throughput: 0.0 tokens/s, Avg generation throughput: 0.0 tokens/s, Running: 0 reqs, Waiting: 0 reqs, GPU KV cache usage: 49.1%, Prefix cache hit rate: 96.8%
(APIServer pid=1) INFO:     192.168.1.244:44914 - "POST /v1/chat/completions HTTP/1.1" 200 OK
(APIServer pid=1) INFO 06-21 15:32:05 [loggers.py:271] Engine 000: Avg prompt throughput: 78.9 tokens/s, Avg generation throughput: 8.4 tokens/s, Running: 1 reqs, Waiting: 0 reqs, GPU KV cache usage: 49.3%, Prefix cache hit rate: 96.9%
(APIServer pid=1) INFO 06-21 15:32:05 [metrics.py:101] SpecDecoding metrics: Mean acceptance length: 2.44, Accepted throughput: 0.54 tokens/s, Drafted throughput: 0.76 tokens/s, Accepted: 49 tokens, Drafted: 68 tokens, Per-position acceptance rate: 0.882, 0.559, Avg Draft acceptance rate: 72.1%
(APIServer pid=1) INFO:     192.168.1.244:47178 - "POST /v1/chat/completions HTTP/1.1" 200 OK
(APIServer pid=1) INFO 06-21 15:32:15 [loggers.py:271] Engine 000: Avg prompt throughput: 131.4 tokens/s, Avg generation throughput: 18.4 tokens/s, Running: 1 reqs, Waiting: 0 reqs, GPU KV cache usage: 49.4%, Prefix cache hit rate: 96.9%
(APIServer pid=1) INFO 06-21 15:32:15 [metrics.py:101] SpecDecoding metrics: Mean acceptance length: 2.63, Accepted throughput: 11.40 tokens/s, Drafted throughput: 14.00 tokens/s, Accepted: 114 tokens, Drafted: 140 tokens, Per-position acceptance rate: 0.943, 0.686, Avg Draft acceptance rate: 81.4%
(APIServer pid=1) INFO:     192.168.1.244:47178 - "POST /v1/chat/completions HTTP/1.1" 200 OK
(APIServer pid=1) INFO 06-21 15:32:25 [loggers.py:271] Engine 000: Avg prompt throughput: 92.2 tokens/s, Avg generation throughput: 12.1 tokens/s, Running: 0 reqs, Waiting: 0 reqs, GPU KV cache usage: 49.5%, Prefix cache hit rate: 96.9%
(APIServer pid=1) INFO 06-21 15:32:25 [metrics.py:101] SpecDecoding metrics: Mean acceptance length: 2.49, Accepted throughput: 7.30 tokens/s, Drafted throughput: 9.80 tokens/s, Accepted: 73 tokens, Drafted: 98 tokens, Per-position acceptance rate: 0.857, 0.633, Avg Draft acceptance rate: 74.5%
(APIServer pid=1) INFO 06-21 15:32:35 [loggers.py:271] Engine 000: Avg prompt throughput: 0.0 tokens/s, Avg generation throughput: 0.0 tokens/s, Running: 0 reqs, Waiting: 0 reqs, GPU KV cache usage: 49.5%, Prefix cache hit rate: 96.9%
(APIServer pid=1) INFO:     192.168.1.244:47412 - "POST /v1/chat/completions HTTP/1.1" 200 OK
(APIServer pid=1) INFO:     192.168.1.244:47412 - "POST /v1/chat/completions HTTP/1.1" 200 OK
(APIServer pid=1) INFO:     192.168.1.244:47412 - "POST /v1/chat/completions HTTP/1.1" 200 OK
(APIServer pid=1) INFO 06-21 15:32:55 [loggers.py:271] Engine 000: Avg prompt throughput: 277.7 tokens/s, Avg generation throughput: 22.0 tokens/s, Running: 1 reqs, Waiting: 0 reqs, GPU KV cache usage: 50.1%, Prefix cache hit rate: 96.9%
(APIServer pid=1) INFO 06-21 15:32:55 [metrics.py:101] SpecDecoding metrics: Mean acceptance length: 2.45, Accepted throughput: 4.30 tokens/s, Drafted throughput: 5.93 tokens/s, Accepted: 129 tokens, Drafted: 178 tokens, Per-position acceptance rate: 0.831, 0.618, Avg Draft acceptance rate: 72.5%
(APIServer pid=1) INFO 06-21 15:33:05 [loggers.py:271] Engine 000: Avg prompt throughput: 0.0 tokens/s, Avg generation throughput: 0.6 tokens/s, Running: 0 reqs, Waiting: 0 reqs, GPU KV cache usage: 50.0%, Prefix cache hit rate: 96.9%
(APIServer pid=1) INFO 06-21 15:33:05 [metrics.py:101] SpecDecoding metrics: Mean acceptance length: 3.00, Accepted throughput: 0.40 tokens/s, Drafted throughput: 0.40 tokens/s, Accepted: 4 tokens, Drafted: 4 tokens, Per-position acceptance rate: 1.000, 1.000, Avg Draft acceptance rate: 100.0%
(APIServer pid=1) INFO 06-21 15:33:15 [loggers.py:271] Engine 000: Avg prompt throughput: 0.0 tokens/s, Avg generation throughput: 0.0 tokens/s, Running: 0 reqs, Waiting: 0 reqs, GPU KV cache usage: 50.0%, Prefix cache hit rate: 96.9%
(APIServer pid=1) INFO:     192.168.1.244:46134 - "GET /v1/models HTTP/1.1" 200 OK
(APIServer pid=1) WARNING:  Invalid HTTP request received.
(APIServer pid=1) INFO:     172.18.0.3:34508 - "GET /models HTTP/1.1" 404 Not Found
(APIServer pid=1) INFO:     172.18.0.3:34522 - "GET /v1/models HTTP/1.1" 200 OK
(APIServer pid=1) INFO:     172.18.0.3:34670 - "POST /v1/chat/completions HTTP/1.1" 200 OK
(APIServer pid=1) INFO 06-21 15:36:45 [loggers.py:271] Engine 000: Avg prompt throughput: 383.0 tokens/s, Avg generation throughput: 6.4 tokens/s, Running: 1 reqs, Waiting: 0 reqs, GPU KV cache usage: 50.3%, Prefix cache hit rate: 96.9%
(APIServer pid=1) INFO 06-21 15:36:45 [metrics.py:101] SpecDecoding metrics: Mean acceptance length: 2.33, Accepted throughput: 0.16 tokens/s, Drafted throughput: 0.25 tokens/s, Accepted: 36 tokens, Drafted: 54 tokens, Per-position acceptance rate: 0.778, 0.556, Avg Draft acceptance rate: 66.7%
(APIServer pid=1) INFO:     172.18.0.3:48878 - "POST /v1/chat/completions HTTP/1.1" 200 OK
(APIServer pid=1) INFO 06-21 15:36:55 [loggers.py:271] Engine 000: Avg prompt throughput: 127.0 tokens/s, Avg generation throughput: 36.3 tokens/s, Running: 1 reqs, Waiting: 0 reqs, GPU KV cache usage: 50.6%, Prefix cache hit rate: 96.9%
(APIServer pid=1) INFO 06-21 15:36:55 [metrics.py:101] SpecDecoding metrics: Mean acceptance length: 2.57, Accepted throughput: 22.20 tokens/s, Drafted throughput: 28.20 tokens/s, Accepted: 222 tokens, Drafted: 282 tokens, Per-position acceptance rate: 0.901, 0.674, Avg Draft acceptance rate: 78.7%
(APIServer pid=1) INFO 06-21 15:37:05 [loggers.py:271] Engine 000: Avg prompt throughput: 0.0 tokens/s, Avg generation throughput: 0.5 tokens/s, Running: 0 reqs, Waiting: 0 reqs, GPU KV cache usage: 50.5%, Prefix cache hit rate: 96.9%
(APIServer pid=1) INFO 06-21 15:37:05 [metrics.py:101] SpecDecoding metrics: Mean acceptance length: 2.50, Accepted throughput: 0.30 tokens/s, Drafted throughput: 0.40 tokens/s, Accepted: 3 tokens, Drafted: 4 tokens, Per-position acceptance rate: 1.000, 0.500, Avg Draft acceptance rate: 75.0%
(APIServer pid=1) INFO 06-21 15:37:15 [loggers.py:271] Engine 000: Avg prompt throughput: 0.0 tokens/s, Avg generation throughput: 0.0 tokens/s, Running: 0 reqs, Waiting: 0 reqs, GPU KV cache usage: 50.5%, Prefix cache hit rate: 96.9%
(APIServer pid=1) INFO:     172.18.0.2:53596 - "GET /v1/models HTTP/1.1" 200 OK
(APIServer pid=1) INFO:     172.18.0.2:45210 - "POST /v1/chat/completions HTTP/1.1" 200 OK
(APIServer pid=1) INFO:     172.18.0.2:45210 - "POST /v1/chat/completions HTTP/1.1" 200 OK
(APIServer pid=1) INFO:     172.18.0.2:45210 - "POST /v1/chat/completions HTTP/1.1" 200 OK
(APIServer pid=1) INFO:     172.18.0.2:45210 - "POST /v1/chat/completions HTTP/1.1" 200 OK
(APIServer pid=1) INFO 06-21 16:14:35 [loggers.py:271] Engine 000: Avg prompt throughput: 75.2 tokens/s, Avg generation throughput: 7.8 tokens/s, Running: 0 reqs, Waiting: 0 reqs, GPU KV cache usage: 50.6%, Prefix cache hit rate: 96.9%
(APIServer pid=1) INFO 06-21 16:14:35 [metrics.py:101] SpecDecoding metrics: Mean acceptance length: 2.29, Accepted throughput: 0.02 tokens/s, Drafted throughput: 0.03 tokens/s, Accepted: 45 tokens, Drafted: 70 tokens, Per-position acceptance rate: 0.771, 0.514, Avg Draft acceptance rate: 64.3%
(APIServer pid=1) INFO:     172.18.0.2:46038 - "GET /v1/models HTTP/1.1" 200 OK
(APIServer pid=1) INFO 06-21 16:14:45 [loggers.py:271] Engine 000: Avg prompt throughput: 0.0 tokens/s, Avg generation throughput: 0.0 tokens/s, Running: 0 reqs, Waiting: 0 reqs, GPU KV cache usage: 50.6%, Prefix cache hit rate: 96.9%
(APIServer pid=1) INFO:     172.18.0.2:53406 - "GET /v1/models HTTP/1.1" 200 OK
(APIServer pid=1) INFO:     172.18.0.2:51582 - "GET /v1/models HTTP/1.1" 200 OK
(APIServer pid=1) INFO:     172.18.0.2:36766 - "POST /v1/chat/completions HTTP/1.1" 200 OK
(APIServer pid=1) INFO:     172.18.0.2:36766 - "POST /v1/chat/completions HTTP/1.1" 200 OK
(APIServer pid=1) INFO 06-21 16:19:15 [loggers.py:271] Engine 000: Avg prompt throughput: 63.0 tokens/s, Avg generation throughput: 10.6 tokens/s, Running: 1 reqs, Waiting: 0 reqs, GPU KV cache usage: 50.9%, Prefix cache hit rate: 96.9%
(APIServer pid=1) INFO 06-21 16:19:15 [metrics.py:101] SpecDecoding metrics: Mean acceptance length: 2.36, Accepted throughput: 0.21 tokens/s, Drafted throughput: 0.31 tokens/s, Accepted: 60 tokens, Drafted: 88 tokens, Per-position acceptance rate: 0.864, 0.500, Avg Draft acceptance rate: 68.2%
(APIServer pid=1) INFO:     172.18.0.2:36766 - "POST /v1/chat/completions HTTP/1.1" 200 OK
(APIServer pid=1) INFO:     172.18.0.2:36766 - "POST /v1/chat/completions HTTP/1.1" 200 OK
(APIServer pid=1) INFO 06-21 16:19:25 [loggers.py:271] Engine 000: Avg prompt throughput: 23.1 tokens/s, Avg generation throughput: 1.1 tokens/s, Running: 0 reqs, Waiting: 0 reqs, GPU KV cache usage: 50.8%, Prefix cache hit rate: 96.9%
(APIServer pid=1) INFO 06-21 16:19:25 [metrics.py:101] SpecDecoding metrics: Mean acceptance length: 2.75, Accepted throughput: 0.70 tokens/s, Drafted throughput: 0.80 tokens/s, Accepted: 7 tokens, Drafted: 8 tokens, Per-position acceptance rate: 1.000, 0.750, Avg Draft acceptance rate: 87.5%
(APIServer pid=1) INFO 06-21 16:19:35 [loggers.py:271] Engine 000: Avg prompt throughput: 0.0 tokens/s, Avg generation throughput: 0.0 tokens/s, Running: 0 reqs, Waiting: 0 reqs, GPU KV cache usage: 50.8%, Prefix cache hit rate: 96.9%
(APIServer pid=1) INFO:     172.18.0.3:35878 - "GET /models HTTP/1.1" 404 Not Found
(APIServer pid=1) INFO:     172.18.0.3:35886 - "GET /v1/models HTTP/1.1" 200 OK
(APIServer pid=1) INFO:     172.18.0.3:33560 - "POST /v1/chat/completions HTTP/1.1" 200 OK
(APIServer pid=1) INFO 06-21 16:20:15 [loggers.py:271] Engine 000: Avg prompt throughput: 122.1 tokens/s, Avg generation throughput: 8.3 tokens/s, Running: 0 reqs, Waiting: 0 reqs, GPU KV cache usage: 51.0%, Prefix cache hit rate: 96.9%
(APIServer pid=1) INFO 06-21 16:20:15 [metrics.py:101] SpecDecoding metrics: Mean acceptance length: 2.37, Accepted throughput: 0.96 tokens/s, Drafted throughput: 1.40 tokens/s, Accepted: 48 tokens, Drafted: 70 tokens, Per-position acceptance rate: 0.829, 0.543, Avg Draft acceptance rate: 68.6%
(APIServer pid=1) INFO 06-21 16:20:25 [loggers.py:271] Engine 000: Avg prompt throughput: 0.0 tokens/s, Avg generation throughput: 0.0 tokens/s, Running: 0 reqs, Waiting: 0 reqs, GPU KV cache usage: 51.0%, Prefix cache hit rate: 96.9%
(APIServer pid=1) INFO:     172.18.0.2:52302 - "GET /v1/models HTTP/1.1" 200 OK
(APIServer pid=1) INFO:     172.18.0.2:44406 - "POST /v1/chat/completions HTTP/1.1" 200 OK
(APIServer pid=1) INFO 06-21 16:22:55 [loggers.py:271] Engine 000: Avg prompt throughput: 16.7 tokens/s, Avg generation throughput: 1.3 tokens/s, Running: 1 reqs, Waiting: 0 reqs, GPU KV cache usage: 51.5%, Prefix cache hit rate: 96.9%
(APIServer pid=1) INFO 06-21 16:22:55 [metrics.py:101] SpecDecoding metrics: Mean acceptance length: 2.80, Accepted throughput: 0.06 tokens/s, Drafted throughput: 0.06 tokens/s, Accepted: 9 tokens, Drafted: 10 tokens, Per-position acceptance rate: 1.000, 0.800, Avg Draft acceptance rate: 90.0%
(APIServer pid=1) INFO:     172.18.0.2:44406 - "POST /v1/chat/completions HTTP/1.1" 200 OK
(APIServer pid=1) INFO:     172.18.0.2:44406 - "POST /v1/chat/completions HTTP/1.1" 200 OK
(APIServer pid=1) INFO:     172.18.0.2:44406 - "POST /v1/chat/completions HTTP/1.1" 200 OK
(APIServer pid=1) INFO 06-21 16:23:05 [loggers.py:271] Engine 000: Avg prompt throughput: 72.5 tokens/s, Avg generation throughput: 6.0 tokens/s, Running: 0 reqs, Waiting: 0 reqs, GPU KV cache usage: 51.1%, Prefix cache hit rate: 96.9%
(APIServer pid=1) INFO 06-21 16:23:05 [metrics.py:101] SpecDecoding metrics: Mean acceptance length: 2.36, Accepted throughput: 3.40 tokens/s, Drafted throughput: 5.00 tokens/s, Accepted: 34 tokens, Drafted: 50 tokens, Per-position acceptance rate: 0.880, 0.480, Avg Draft acceptance rate: 68.0%
(APIServer pid=1) INFO:     172.18.0.2:35306 - "POST /v1/chat/completions HTTP/1.1" 200 OK
(APIServer pid=1) INFO:     172.18.0.2:35306 - "POST /v1/chat/completions HTTP/1.1" 200 OK
(APIServer pid=1) INFO 06-21 16:23:15 [loggers.py:271] Engine 000: Avg prompt throughput: 47.0 tokens/s, Avg generation throughput: 7.5 tokens/s, Running: 0 reqs, Waiting: 0 reqs, GPU KV cache usage: 51.2%, Prefix cache hit rate: 96.9%
(APIServer pid=1) INFO 06-21 16:23:15 [metrics.py:101] SpecDecoding metrics: Mean acceptance length: 2.06, Accepted throughput: 3.80 tokens/s, Drafted throughput: 7.20 tokens/s, Accepted: 38 tokens, Drafted: 72 tokens, Per-position acceptance rate: 0.722, 0.333, Avg Draft acceptance rate: 52.8%
(APIServer pid=1) INFO 06-21 16:23:25 [loggers.py:271] Engine 000: Avg prompt throughput: 0.0 tokens/s, Avg generation throughput: 0.0 tokens/s, Running: 0 reqs, Waiting: 0 reqs, GPU KV cache usage: 51.2%, Prefix cache hit rate: 96.9%
(APIServer pid=1) INFO:     172.18.0.2:48508 - "POST /v1/chat/completions HTTP/1.1" 200 OK
(APIServer pid=1) INFO:     172.18.0.2:48508 - "POST /v1/chat/completions HTTP/1.1" 200 OK
(APIServer pid=1) INFO 06-21 16:23:35 [loggers.py:271] Engine 000: Avg prompt throughput: 59.3 tokens/s, Avg generation throughput: 15.5 tokens/s, Running: 0 reqs, Waiting: 0 reqs, GPU KV cache usage: 51.4%, Prefix cache hit rate: 96.9%
(APIServer pid=1) INFO 06-21 16:23:35 [metrics.py:101] SpecDecoding metrics: Mean acceptance length: 2.17, Accepted throughput: 4.15 tokens/s, Drafted throughput: 7.10 tokens/s, Accepted: 83 tokens, Drafted: 142 tokens, Per-position acceptance rate: 0.704, 0.465, Avg Draft acceptance rate: 58.5%
(APIServer pid=1) INFO 06-21 16:23:45 [loggers.py:271] Engine 000: Avg prompt throughput: 0.0 tokens/s, Avg generation throughput: 0.0 tokens/s, Running: 0 reqs, Waiting: 0 reqs, GPU KV cache usage: 51.4%, Prefix cache hit rate: 96.9%
(APIServer pid=1) INFO:     172.18.0.2:55450 - "POST /v1/chat/completions HTTP/1.1" 200 OK
(APIServer pid=1) INFO:     172.18.0.2:55450 - "POST /v1/chat/completions HTTP/1.1" 200 OK
(APIServer pid=1) INFO 06-21 16:24:05 [loggers.py:271] Engine 000: Avg prompt throughput: 67.6 tokens/s, Avg generation throughput: 11.1 tokens/s, Running: 0 reqs, Waiting: 0 reqs, GPU KV cache usage: 51.6%, Prefix cache hit rate: 96.9%
(APIServer pid=1) INFO 06-21 16:24:05 [metrics.py:101] SpecDecoding metrics: Mean acceptance length: 2.00, Accepted throughput: 1.83 tokens/s, Drafted throughput: 3.67 tokens/s, Accepted: 55 tokens, Drafted: 110 tokens, Per-position acceptance rate: 0.727, 0.273, Avg Draft acceptance rate: 50.0%
(APIServer pid=1) INFO 06-21 16:24:15 [loggers.py:271] Engine 000: Avg prompt throughput: 0.0 tokens/s, Avg generation throughput: 0.0 tokens/s, Running: 0 reqs, Waiting: 0 reqs, GPU KV cache usage: 51.6%, Prefix cache hit rate: 96.9%
(APIServer pid=1) INFO:     172.18.0.2:32810 - "POST /v1/chat/completions HTTP/1.1" 200 OK
(APIServer pid=1) INFO:     172.18.0.2:32810 - "POST /v1/chat/completions HTTP/1.1" 200 OK
(APIServer pid=1) INFO 06-21 16:24:35 [loggers.py:271] Engine 000: Avg prompt throughput: 50.5 tokens/s, Avg generation throughput: 11.8 tokens/s, Running: 0 reqs, Waiting: 0 reqs, GPU KV cache usage: 51.9%, Prefix cache hit rate: 96.9%
(APIServer pid=1) INFO 06-21 16:24:35 [metrics.py:101] SpecDecoding metrics: Mean acceptance length: 2.07, Accepted throughput: 2.03 tokens/s, Drafted throughput: 3.80 tokens/s, Accepted: 61 tokens, Drafted: 114 tokens, Per-position acceptance rate: 0.684, 0.386, Avg Draft acceptance rate: 53.5%
(APIServer pid=1) INFO 06-21 16:24:45 [loggers.py:271] Engine 000: Avg prompt throughput: 0.0 tokens/s, Avg generation throughput: 0.0 tokens/s, Running: 0 reqs, Waiting: 0 reqs, GPU KV cache usage: 51.9%, Prefix cache hit rate: 96.9%
(APIServer pid=1) INFO:     172.18.0.2:52716 - "POST /v1/chat/completions HTTP/1.1" 200 OK
(APIServer pid=1) INFO:     172.18.0.2:52716 - "POST /v1/chat/completions HTTP/1.1" 200 OK
(APIServer pid=1) INFO 06-21 16:25:25 [loggers.py:271] Engine 000: Avg prompt throughput: 74.7 tokens/s, Avg generation throughput: 19.6 tokens/s, Running: 0 reqs, Waiting: 0 reqs, GPU KV cache usage: 52.1%, Prefix cache hit rate: 96.9%
(APIServer pid=1) INFO 06-21 16:25:25 [metrics.py:101] SpecDecoding metrics: Mean acceptance length: 2.31, Accepted throughput: 2.22 tokens/s, Drafted throughput: 3.40 tokens/s, Accepted: 111 tokens, Drafted: 170 tokens, Per-position acceptance rate: 0.859, 0.447, Avg Draft acceptance rate: 65.3%
(APIServer pid=1) INFO 06-21 16:25:35 [loggers.py:271] Engine 000: Avg prompt throughput: 0.0 tokens/s, Avg generation throughput: 0.0 tokens/s, Running: 0 reqs, Waiting: 0 reqs, GPU KV cache usage: 52.1%, Prefix cache hit rate: 96.9%
(APIServer pid=1) INFO:     172.18.0.2:50256 - "POST /v1/chat/completions HTTP/1.1" 200 OK
(APIServer pid=1) INFO 06-21 16:26:15 [loggers.py:271] Engine 000: Avg prompt throughput: 60.9 tokens/s, Avg generation throughput: 7.9 tokens/s, Running: 1 reqs, Waiting: 0 reqs, GPU KV cache usage: 52.4%, Prefix cache hit rate: 96.9%
(APIServer pid=1) INFO 06-21 16:26:15 [metrics.py:101] SpecDecoding metrics: Mean acceptance length: 2.23, Accepted throughput: 0.86 tokens/s, Drafted throughput: 1.40 tokens/s, Accepted: 43 tokens, Drafted: 70 tokens, Per-position acceptance rate: 0.800, 0.429, Avg Draft acceptance rate: 61.4%
(APIServer pid=1) INFO:     172.18.0.2:50256 - "POST /v1/chat/completions HTTP/1.1" 200 OK
(APIServer pid=1) INFO 06-21 16:26:25 [loggers.py:271] Engine 000: Avg prompt throughput: 0.0 tokens/s, Avg generation throughput: 0.1 tokens/s, Running: 0 reqs, Waiting: 0 reqs, GPU KV cache usage: 52.3%, Prefix cache hit rate: 96.9%
(APIServer pid=1) INFO 06-21 16:26:25 [metrics.py:101] SpecDecoding metrics: Mean acceptance length: 2.00, Accepted throughput: 0.10 tokens/s, Drafted throughput: 0.20 tokens/s, Accepted: 1 tokens, Drafted: 2 tokens, Per-position acceptance rate: 1.000, 0.000, Avg Draft acceptance rate: 50.0%
(APIServer pid=1) INFO 06-21 16:26:35 [loggers.py:271] Engine 000: Avg prompt throughput: 0.0 tokens/s, Avg generation throughput: 0.0 tokens/s, Running: 0 reqs, Waiting: 0 reqs, GPU KV cache usage: 52.3%, Prefix cache hit rate: 96.9%
(EngineCore pid=34) INFO 06-21 16:30:34 [core.py:1276] Shutdown initiated (timeout=0)
(EngineCore pid=34) INFO 06-21 16:30:34 [core.py:1299] Shutdown complete
(Worker_TP0 pid=57) 2026-06-21 07:54:50  [TileLang:tilelang.jit.kernel:INFO] (kernel.py:133): TileLang begins to compile kernel `mhc_pre_big_fuse_with_norm_tilelang` with `out_idx=None`
(Worker_TP0 pid=57) 2026-06-21 07:54:55  [TileLang:tilelang.jit.kernel:INFO] (kernel.py:141): TileLang completes to compile kernel `mhc_pre_big_fuse_with_norm_tilelang`
(Worker_TP0 pid=57) 2026-06-21 08:03:33  [TileLang:tilelang.jit.kernel:INFO] (kernel.py:133): TileLang begins to compile kernel `mhc_pre_big_fuse_with_norm_tilelang` with `out_idx=None`
(Worker_TP0 pid=57) 2026-06-21 08:03:38  [TileLang:tilelang.jit.kernel:INFO] (kernel.py:141): TileLang completes to compile kernel `mhc_pre_big_fuse_with_norm_tilelang`
(Worker_TP0 pid=57) 2026-06-21 13:05:53  [TileLang:tilelang.jit.kernel:INFO] (kernel.py:133): TileLang begins to compile kernel `mhc_pre_big_fuse_with_norm_tilelang` with `out_idx=None`
(Worker_TP0 pid=57) 2026-06-21 13:05:58  [TileLang:tilelang.jit.kernel:INFO] (kernel.py:141): TileLang completes to compile kernel `mhc_pre_big_fuse_with_norm_tilelang`
(Worker_TP0 pid=57) 2026-06-21 13:19:47  [TileLang:tilelang.jit.kernel:INFO] (kernel.py:133): TileLang begins to compile kernel `mhc_pre_big_fuse_with_norm_tilelang` with `out_idx=None`
(Worker_TP0 pid=57) 2026-06-21 13:19:52  [TileLang:tilelang.jit.kernel:INFO] (kernel.py:141): TileLang completes to compile kernel `mhc_pre_big_fuse_with_norm_tilelang`
(Worker_TP0 pid=57) 2026-06-21 13:19:55  [TileLang:tilelang.jit.kernel:INFO] (kernel.py:133): TileLang begins to compile kernel `mhc_pre_big_fuse_with_norm_tilelang` with `out_idx=None`
(Worker_TP0 pid=57) 2026-06-21 13:19:59  [TileLang:tilelang.jit.kernel:INFO] (kernel.py:141): TileLang completes to compile kernel `mhc_pre_big_fuse_with_norm_tilelang`
(Worker_TP0 pid=57) 2026-06-21 16:22:49  [TileLang:tilelang.jit.kernel:INFO] (kernel.py:133): TileLang begins to compile kernel `mhc_pre_big_fuse_with_norm_tilelang` with `out_idx=None`
(Worker_TP0 pid=57) 2026-06-21 16:22:53  [TileLang:tilelang.jit.kernel:INFO] (kernel.py:141): TileLang completes to compile kernel `mhc_pre_big_fuse_with_norm_tilelang`
(Worker_TP0 pid=57) 2026-06-21 16:24:21  [TileLang:tilelang.jit.kernel:INFO] (kernel.py:133): TileLang begins to compile kernel `mhc_pre_big_fuse_with_norm_tilelang` with `out_idx=None`
(Worker_TP0 pid=57) 2026-06-21 16:24:26  [TileLang:tilelang.jit.kernel:INFO] (kernel.py:141): TileLang completes to compile kernel `mhc_pre_big_fuse_with_norm_tilelang`
(Worker_TP0 pid=57) INFO 06-21 16:30:34 [multiproc_executor.py:775] Parent process exited, terminating worker queues
(APIServer pid=1) INFO 06-21 16:30:34 [launcher.py:137] Shutting down FastAPI HTTP server.
(APIServer pid=1) INFO:     Shutting down
(APIServer pid=1) INFO:     Waiting for application shutdown.
(APIServer pid=1) INFO:     Application shutdown complete.
/opt/env/lib/python3.12/multiprocessing/resource_tracker.py:279: UserWarning: resource_tracker: There appear to be 1 leaked semaphore objects to clean up at shutdown
  warnings.warn('resource_tracker: There appear to be %d '
/opt/env/lib/python3.12/multiprocessing/resource_tracker.py:279: UserWarning: resource_tracker: There appear to be 2 leaked shared_memory objects to clean up at shutdown
  warnings.warn('resource_tracker: There appear to be %d '
```
