# docker compose
```yml
services:
  qwen36-35b-nvfp4:
    image: vllm/vllm-openai:nightly
    container_name: qwen36-35b-nvfp4-nightly
    hostname: inference-server
    platform: linux/arm64
    # ports are not exposed.
    # use the nginx/nginx-vllm-reverse-proxy-dgx-spark/nginx.conf to speak with the model
    # ports:
      # - "8000:8000"
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
      # NVIDIA DGX Spark specific env vars
      VLLM_USE_FLASHINFER_MOE_FP4: "0"
      VLLM_FP8_MOE_BACKEND: flashinfer_cutlass
      FLASHINFER_DISABLE_VERSION_CHECK: "1"
      CUTE_DSL_ARCH: sm_121a
      # Rust frontend doesn't support api_key yet
      # Also seems to just crash
      VLLM_USE_RUST_FRONTEND: "1"

    command:
      - "--model"
      - "nvidia/Qwen3.6-35B-A3B-NVFP4"
      - "--served-model-name"
      - "${INFERENCE_MODEL_ALIAS:-qwen3.6-35b}"
      - "--api-key"
      - "${INFERENCE_API_KEY:-dummy-key}"
      - "--trust-remote-code"
      - "--host"
      - "0.0.0.0"
      - "--port"
      - "${INFERENCE_SERVER_PORT:-8000}"

      # --- MEMORY & CONTEXT ---
      # NVFP4 is ~3x smaller than BF16, MoE only 3B active params.
      # Model weights ~7-9 GB. KV cache per session at 262K with fp8 ~2-4 GB.
      # 5 sessions × 4 GB + 9 GB model = ~29 GB. Spark has 128GB UMA.
      - "--gpu-memory-utilization"
      - "0.85"
      - "--max-model-len"
      - "262144"
      - "--max-num-seqs"
      - "5"

      # --- BATCHING / PREFILL OPTIMIZATION ---
      - "--max-num-batched-tokens"
      - "8192"

      # --- ARCHITECTURE & QUANTIZATION ---
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

      # --- BACKENDS (NVIDIA Spark recommendations) ---
      - "--attention-backend"
      - "flashinfer"
      - "--moe-backend"
      - "marlin"
      - "--enable-prefix-caching"
      - "--enable-chunked-prefill"
      - "--async-scheduling"

      # --- STARTUP OPTIMIZATIONS ---
      - "--safetensors-load-strategy"
      - "prefetch"

      # --- SPECULATIVE DECODING (MTP) ---
      # MTP on a 3B active / 35B total MoE is hit-or-miss in vLLM.
      # 1-2 tokens max — 3+ wastes compute on low-quality predictions.
      - "--speculative-config"
      - '{"method":"mtp","num_speculative_tokens":2,"moe_backend":"triton"}'

    networks:
      - development-network

networks:
  development-network:
    external: true
```


# vllm log
```log
qwen36-35b-nvfp4-nightly  | /usr/local/lib/python3.12/dist-packages/huggingface_hub/constants.py:277: FutureWarning: The `HF_HUB_ENABLE_HF_TRANSFER` environment variable is deprecated as 'hf_transfer' is not used anymore. Please use `HF_XET_HIGH_PERFORMANCE` instead to enable high performance transfer with Xet. Visit https://huggingface.co/docs/huggingface_hub/package_reference/environment_variables#hfxethighperformance for more details.
qwen36-35b-nvfp4-nightly  |   warnings.warn(
qwen36-35b-nvfp4-nightly  | WARNING 06-01 21:35:33 [argparse_utils.py:257] With `vllm serve`, you should provide the model as a positional argument or in a config file instead of via the `--model` option. The `--model` option will be removed in a future version.
qwen36-35b-nvfp4-nightly  | INFO 06-01 21:35:33 [utils.py:344] 
qwen36-35b-nvfp4-nightly  | INFO 06-01 21:35:33 [utils.py:344]        █     █     █▄   ▄█
qwen36-35b-nvfp4-nightly  | INFO 06-01 21:35:33 [utils.py:344]  ▄▄ ▄█ █     █     █ ▀▄▀ █  version 0.22.1rc1.dev26+g4721bb3aa
qwen36-35b-nvfp4-nightly  | INFO 06-01 21:35:33 [utils.py:344]   █▄█▀ █     █     █     █  model   nvidia/Qwen3.6-35B-A3B-NVFP4
qwen36-35b-nvfp4-nightly  | INFO 06-01 21:35:33 [utils.py:344]    ▀▀  ▀▀▀▀▀ ▀▀▀▀▀ ▀     ▀
qwen36-35b-nvfp4-nightly  | INFO 06-01 21:35:33 [utils.py:344] 
qwen36-35b-nvfp4-nightly  | INFO 06-01 21:35:33 [utils.py:278] non-default args: {'model_tag': 'nvidia/Qwen3.6-35B-A3B-NVFP4', 'api_server_count': 1, 'enable_auto_tool_choice': True, 'tool_call_parser': 'qwen3_coder', 'host': '0.0.0.0', 'api_key': ['dummy-key'], 'model': 'nvidia/Qwen3.6-35B-A3B-NVFP4', 'trust_remote_code': True, 'max_model_len': 262144, 'quantization': 'modelopt', 'served_model_name': ['qwen3.6-35b'], 'safetensors_load_strategy': 'prefetch', 'attention_backend': 'flashinfer', 'reasoning_parser': 'qwen3', 'gpu_memory_utilization': 0.85, 'kv_cache_dtype': 'fp8', 'enable_prefix_caching': True, 'max_num_batched_tokens': 8192, 'max_num_seqs': 5, 'enable_chunked_prefill': True, 'async_scheduling': True, 'moe_backend': 'marlin', 'speculative_config': {'method': 'mtp', 'num_speculative_tokens': 2, 'moe_backend': 'triton'}}
qwen36-35b-nvfp4-nightly  | WARNING 06-01 21:35:33 [envs.py:2060] Unknown vLLM environment variable detected: VLLM_FP8_MOE_BACKEND
qwen36-35b-nvfp4-nightly  | WARNING 06-01 21:35:33 [envs.py:2060] Unknown vLLM environment variable detected: VLLM_BUILD_COMMIT
qwen36-35b-nvfp4-nightly  | WARNING 06-01 21:35:33 [envs.py:2060] Unknown vLLM environment variable detected: VLLM_BUILD_PIPELINE
qwen36-35b-nvfp4-nightly  | WARNING 06-01 21:35:33 [envs.py:2060] Unknown vLLM environment variable detected: VLLM_BUILD_URL
qwen36-35b-nvfp4-nightly  | WARNING 06-01 21:35:33 [envs.py:2060] Unknown vLLM environment variable detected: VLLM_IMAGE_TAG
qwen36-35b-nvfp4-nightly  | INFO 06-01 21:35:43 [model.py:617] Resolved architecture: Qwen3_5MoeForConditionalGeneration
qwen36-35b-nvfp4-nightly  | INFO 06-01 21:35:43 [model.py:1751] Using max model len 262144
qwen36-35b-nvfp4-nightly  | INFO 06-01 21:35:44 [cache.py:269] Using fp8 data type to store kv cache. It reduces the GPU memory footprint and boosts the performance. Meanwhile, it may cause accuracy drop without a proper scaling factor
qwen36-35b-nvfp4-nightly  | INFO 06-01 21:35:49 [model.py:617] Resolved architecture: Qwen3_5MoeMTP
qwen36-35b-nvfp4-nightly  | INFO 06-01 21:35:49 [model.py:1751] Using max model len 262144
qwen36-35b-nvfp4-nightly  | WARNING 06-01 21:35:49 [speculative.py:722] Enabling num_speculative_tokens > 1 will run multiple times of forward on same MTP layer,which may result in lower acceptance rate
qwen36-35b-nvfp4-nightly  | INFO 06-01 21:35:49 [scheduler.py:239] Chunked prefill is enabled with max_num_batched_tokens=8192.
qwen36-35b-nvfp4-nightly  | WARNING 06-01 21:35:49 [config.py:355] Mamba cache mode is set to 'align' for Qwen3_5MoeForConditionalGeneration by default when prefix caching is enabled
qwen36-35b-nvfp4-nightly  | INFO 06-01 21:35:49 [config.py:375] Warning: Prefix caching in Mamba cache 'align' mode is currently enabled. Its support for Mamba layers is experimental. Please report any issues you may observe.
qwen36-35b-nvfp4-nightly  | WARNING 06-01 21:35:49 [modelopt.py:379] Detected ModelOpt fp8 checkpoint (quant_algo=FP8). Please note that the format is experimental and could change.
qwen36-35b-nvfp4-nightly  | WARNING 06-01 21:35:49 [modelopt.py:1022] Detected ModelOpt NVFP4 checkpoint (quant_algo=NVFP4). Please note that the format is experimental and could change in future.
qwen36-35b-nvfp4-nightly  | WARNING 06-01 21:35:49 [modelopt.py:1022] Detected ModelOpt NVFP4 checkpoint (quant_algo=W4A16_NVFP4). Please note that the format is experimental and could change in future.
qwen36-35b-nvfp4-nightly  | INFO 06-01 21:35:49 [vllm.py:984] Asynchronous scheduling is enabled.
qwen36-35b-nvfp4-nightly  | INFO 06-01 21:35:49 [kernel.py:270] Final IR op priority after setting platform defaults: IrOpPriorityConfig(rms_norm=['native'], fused_add_rms_norm=['native'])
qwen36-35b-nvfp4-nightly  | /usr/local/lib/python3.12/dist-packages/huggingface_hub/constants.py:277: FutureWarning: The `HF_HUB_ENABLE_HF_TRANSFER` environment variable is deprecated as 'hf_transfer' is not used anymore. Please use `HF_XET_HIGH_PERFORMANCE` instead to enable high performance transfer with Xet. Visit https://huggingface.co/docs/huggingface_hub/package_reference/environment_variables#hfxethighperformance for more details.
qwen36-35b-nvfp4-nightly  |   warnings.warn(
qwen36-35b-nvfp4-nightly  | INFO 06-01 21:35:56 [utils.py:370] Launching Rust frontend: /usr/local/lib/python3.12/dist-packages/vllm/vllm-rs frontend --listen-fd 15 --input-address ipc:///tmp/77ae6c31-8bfd-4906-b60f-35ba9dfb0994 --output-address ipc:///tmp/a73d09ea-3ae8-47e7-95a1-850e05f3c00d --engine-count 1 --args-json {"api_key": ["dummy-key"], "async_scheduling": true, "attention_backend": "flashinfer", "enable_auto_tool_choice": true, "enable_chunked_prefill": true, "enable_prefix_caching": true, "gpu_memory_utilization": 0.85, "host": "0.0.0.0", "kv_cache_dtype": "fp8", "max_model_len": 262144, "max_num_batched_tokens": 8192, "max_num_seqs": 5, "model": "nvidia/Qwen3.6-35B-A3B-NVFP4", "model_tag": "nvidia/Qwen3.6-35B-A3B-NVFP4", "moe_backend": "marlin", "quantization": "modelopt", "reasoning_parser": "qwen3", "safetensors_load_strategy": "prefetch", "served_model_name": ["qwen3.6-35b"], "speculative_config": {"method": "mtp", "moe_backend": "triton", "num_speculative_tokens": 2, "target_model_config": {"allow_deprecated_quantization": false, "allowed_local_media_path": "", "allowed_media_domains": null, "code_revision": null, "config_format": "auto", "convert": "auto", "disable_cascade_attn": true, "disable_sliding_window": false, "dtype": "torch.bfloat16", "enable_cumem_allocator": false, "enable_prompt_embeds": false, "enable_return_routed_experts": false, "enable_sleep_mode": false, "enforce_eager": false, "generation_config": "auto", "hf_config": {"architectures": ["Qwen3_5MoeForConditionalGeneration"], "chunk_size_feed_forward": 0, "dtype": "torch.bfloat16", "id2label": {"0": "LABEL_0", "1": "LABEL_1"}, "is_encoder_decoder": false, "label2id": {"LABEL_0": 0, "LABEL_1": 1}, "output_hidden_states": false, "problem_type": null, "return_dict": true, "transformers_version": "5.7.0.dev0"}, "hf_config_path": null, "hf_overrides": {}, "hf_text_config": {"architectures": null, "chunk_size_feed_forward": 0, "dtype": "torch.bfloat16", "id2label": {"0": "LABEL_0", "1": "LABEL_1"}, "is_encoder_decoder": false, "label2id": {"LABEL_0": 0, "LABEL_1": 1}, "output_hidden_states": false, "problem_type": null, "return_dict": true, "transformers_version": null}, "hf_token": null, "io_processor_plugin": null, "logits_processors": null, "logprobs_mode": "raw_logprobs", "max_logprobs": 20, "max_model_len": 262144, "model": "nvidia/Qwen3.6-35B-A3B-NVFP4", "model_impl": "auto", "model_weights": "", "multimodal_config": {"enable_mm_embeds": false, "interleave_mm_strings": false, "language_model_only": false, "limit_per_prompt": {}, "media_io_kwargs": {}, "mm_encoder_attn_backend": null, "mm_encoder_attn_dtype": null, "mm_encoder_fp8_scale_path": null, "mm_encoder_fp8_scale_save_margin": 1.5, "mm_encoder_fp8_scale_save_path": null, "mm_encoder_only": false, "mm_encoder_tp_mode": "weights", "mm_processor_cache_gb": 4.0, "mm_processor_cache_type": "lru", "mm_processor_kwargs": null, "mm_shm_cache_max_object_size_mb": 128, "mm_tensor_ipc": "direct_rpc", "skip_mm_profiling": false, "video_pruning_rate": null}, "override_attention_dtype": null, "override_generation_config": {}, "pooler_config": null, "quantization": "modelopt_mixed", "quantization_config": null, "renderer_num_workers": 1, "revision": null, "runner": "auto", "seed": 0, "served_model_name": "qwen3.6-35b", "skip_tokenizer_init": false, "spec_target_max_model_len": null, "tokenizer": "nvidia/Qwen3.6-35B-A3B-NVFP4", "tokenizer_mode": "auto", "tokenizer_revision": null, "trust_remote_code": true, "use_fp64_gumbel": false}, "target_parallel_config": {"_api_process_count": 1, "_api_process_rank": -1, "_coord_store_port": 0, "_data_parallel_master_port_list": [], "all2all_backend": "allgather_reducescatter", "cp_kv_cache_interleave_size": 1, "cpu_distributed_timeout_seconds": null, "data_parallel_backend": "mp", "data_parallel_external_lb": false, "data_parallel_hybrid_lb": false, "data_parallel_index": 0, "data_parallel_master_ip": "127.0.0.1", "data_parallel_master_port": 0, "data_parallel_rank": 0, "data_parallel_rank_local": 0, "data_parallel_rpc_port": 29550, "data_parallel_size": 1, "data_parallel_size_local": 1, "dbo_decode_token_threshold": 32, "dbo_prefill_token_threshold": 512, "dcp_comm_backend": "ag_rs", "dcp_kv_cache_interleave_size": 1, "decode_context_parallel_size": 1, "disable_custom_all_reduce": false, "disable_nccl_for_dp_synchronization": true, "distributed_executor_backend": "uni", "distributed_timeout_seconds": null, "enable_dbo": false, "enable_elastic_ep": false, "enable_ep_weight_filter": false, "enable_eplb": false, "enable_expert_parallel": false, "eplb_config": {"communicator": null, "log_balancedness": false, "log_balancedness_interval": 1, "num_redundant_experts": 0, "policy": "default", "step_interval": 3000, "use_async": true, "window_size": 1000}, "expert_placement_strategy": "linear", "is_moe_model": true, "master_addr": "127.0.0.1", "master_port": 29501, "max_parallel_loading_workers": null, "nnodes": 1, "node_rank": 0, "numa_bind": false, "numa_bind_cpus": null, "numa_bind_nodes": null, "pipeline_parallel_size": 1, "placement_group": null, "prefill_context_parallel_size": 1, "rank": 0, "ray_runtime_env": null, "ray_workers_use_nsight": false, "sd_worker_cls": "auto", "tensor_parallel_size": 1, "ubatch_size": 0, "worker_cls": "vllm.v1.worker.gpu_worker.Worker", "worker_extension_cls": "", "world_size": 1}}, "structured_outputs_config": {"backend": "auto", "disable_additional_properties": false, "disable_any_whitespace": false, "enable_in_reasoning": false, "reasoning_parser": "qwen3", "reasoning_parser_plugin": ""}, "tool_call_parser": "qwen3_coder", "trust_remote_code": true}
qwen36-35b-nvfp4-nightly  | (RustFrontend pid=353) WARNING 06-01 21:35:56 [unsupported.rs:64] argument 'structured_outputs_config' currently has no effect in Rust frontend, ignoring
qwen36-35b-nvfp4-nightly  | (RustFrontend pid=353) WARNING 06-01 21:35:56 [unsupported.rs:64] argument 'enable_auto_tool_choice' currently has no effect in Rust frontend, ignoring
qwen36-35b-nvfp4-nightly  | error: invalid value '{"api_key": ["dummy-key"], "async_scheduling": true, "attention_backend": "flashinfer", "enable_auto_tool_choice": true, "enable_chunked_prefill": true, "enable_prefix_caching": true, "gpu_memory_utilization": 0.85, "host": "0.0.0.0", "kv_cache_dtype": "fp8", "max_model_len": 262144, "max_num_batched_tokens": 8192, "max_num_seqs": 5, "model": "nvidia/Qwen3.6-35B-A3B-NVFP4", "model_tag": "nvidia/Qwen3.6-35B-A3B-NVFP4", "moe_backend": "marlin", "quantization": "modelopt", "reasoning_parser": "qwen3", "safetensors_load_strategy": "prefetch", "served_model_name": ["qwen3.6-35b"], "speculative_config": {"method": "mtp", "moe_backend": "triton", "num_speculative_tokens": 2, "target_model_config": {"allow_deprecated_quantization": false, "allowed_local_media_path": "", "allowed_media_domains": null, "code_revision": null, "config_format": "auto", "convert": "auto", "disable_cascade_attn": true, "disable_sliding_window": false, "dtype": "torch.bfloat16", "enable_cumem_allocator": false, "enable_prompt_embeds": false, "enable_return_routed_experts": false, "enable_sleep_mode": false, "enforce_eager": false, "generation_config": "auto", "hf_config": {"architectures": ["Qwen3_5MoeForConditionalGeneration"], "chunk_size_feed_forward": 0, "dtype": "torch.bfloat16", "id2label": {"0": "LABEL_0", "1": "LABEL_1"}, "is_encoder_decoder": false, "label2id": {"LABEL_0": 0, "LABEL_1": 1}, "output_hidden_states": false, "problem_type": null, "return_dict": true, "transformers_version": "5.7.0.dev0"}, "hf_config_path": null, "hf_overrides": {}, "hf_text_config": {"architectures": null, "chunk_size_feed_forward": 0, "dtype": "torch.bfloat16", "id2label": {"0": "LABEL_0", "1": "LABEL_1"}, "is_encoder_decoder": false, "label2id": {"LABEL_0": 0, "LABEL_1": 1}, "output_hidden_states": false, "problem_type": null, "return_dict": true, "transformers_version": null}, "hf_token": null, "io_processor_plugin": null, "logits_processors": null, "logprobs_mode": "raw_logprobs", "max_logprobs": 20, "max_model_len": 262144, "model": "nvidia/Qwen3.6-35B-A3B-NVFP4", "model_impl": "auto", "model_weights": "", "multimodal_config": {"enable_mm_embeds": false, "interleave_mm_strings": false, "language_model_only": false, "limit_per_prompt": {}, "media_io_kwargs": {}, "mm_encoder_attn_backend": null, "mm_encoder_attn_dtype": null, "mm_encoder_fp8_scale_path": null, "mm_encoder_fp8_scale_save_margin": 1.5, "mm_encoder_fp8_scale_save_path": null, "mm_encoder_only": false, "mm_encoder_tp_mode": "weights", "mm_processor_cache_gb": 4.0, "mm_processor_cache_type": "lru", "mm_processor_kwargs": null, "mm_shm_cache_max_object_size_mb": 128, "mm_tensor_ipc": "direct_rpc", "skip_mm_profiling": false, "video_pruning_rate": null}, "override_attention_dtype": null, "override_generation_config": {}, "pooler_config": null, "quantization": "modelopt_mixed", "quantization_config": null, "renderer_num_workers": 1, "revision": null, "runner": "auto", "seed": 0, "served_model_name": "qwen3.6-35b", "skip_tokenizer_init": false, "spec_target_max_model_len": null, "tokenizer": "nvidia/Qwen3.6-35B-A3B-NVFP4", "tokenizer_mode": "auto", "tokenizer_revision": null, "trust_remote_code": true, "use_fp64_gumbel": false}, "target_parallel_config": {"_api_process_count": 1, "_api_process_rank": -1, "_coord_store_port": 0, "_data_parallel_master_port_list": [], "all2all_backend": "allgather_reducescatter", "cp_kv_cache_interleave_size": 1, "cpu_distributed_timeout_seconds": null, "data_parallel_backend": "mp", "data_parallel_external_lb": false, "data_parallel_hybrid_lb": false, "data_parallel_index": 0, "data_parallel_master_ip": "127.0.0.1", "data_parallel_master_port": 0, "data_parallel_rank": 0, "data_parallel_rank_local": 0, "data_parallel_rpc_port": 29550, "data_parallel_size": 1, "data_parallel_size_local": 1, "dbo_decode_token_threshold": 32, "dbo_prefill_token_threshold": 512, "dcp_comm_backend": "ag_rs", "dcp_kv_cache_interleave_size": 1, "decode_context_parallel_size": 1, "disable_custom_all_reduce": false, "disable_nccl_for_dp_synchronization": true, "distributed_executor_backend": "uni", "distributed_timeout_seconds": null, "enable_dbo": false, "enable_elastic_ep": false, "enable_ep_weight_filter": false, "enable_eplb": false, "enable_expert_parallel": false, "eplb_config": {"communicator": null, "log_balancedness": false, "log_balancedness_interval": 1, "num_redundant_experts": 0, "policy": "default", "step_interval": 3000, "use_async": true, "window_size": 1000}, "expert_placement_strategy": "linear", "is_moe_model": true, "master_addr": "127.0.0.1", "master_port": 29501, "max_parallel_loading_workers": null, "nnodes": 1, "node_rank": 0, "numa_bind": false, "numa_bind_cpus": null, "numa_bind_nodes": null, "pipeline_parallel_size": 1, "placement_group": null, "prefill_context_parallel_size": 1, "rank": 0, "ray_runtime_env": null, "ray_workers_use_nsight": false, "sd_worker_cls": "auto", "tensor_parallel_size": 1, "ubatch_size": 0, "worker_cls": "vllm.v1.worker.gpu_worker.Worker", "worker_extension_cls": "", "world_size": 1}}, "structured_outputs_config": {"backend": "auto", "disable_additional_properties": false, "disable_any_whitespace": false, "enable_in_reasoning": false, "reasoning_parser": "qwen3", "reasoning_parser_plugin": ""}, "tool_call_parser": "qwen3_coder", "trust_remote_code": true}' for '--args-json <JSON>': 
qwen36-35b-nvfp4-nightly  | The following arguments are not implemented in Rust frontend yet:
qwen36-35b-nvfp4-nightly  | - api_key
qwen36-35b-nvfp4-nightly  | 
qwen36-35b-nvfp4-nightly  | Remove these arguments to continue.
qwen36-35b-nvfp4-nightly  | 
qwen36-35b-nvfp4-nightly  | For more information, try '--help'.
qwen36-35b-nvfp4-nightly  | (EngineCore pid=310) INFO 06-01 21:35:57 [core.py:112] Initializing a V1 LLM engine (v0.22.1rc1.dev26+g4721bb3aa) with config: model='nvidia/Qwen3.6-35B-A3B-NVFP4', speculative_config=SpeculativeConfig(method='mtp', model='nvidia/Qwen3.6-35B-A3B-NVFP4', num_spec_tokens=2), tokenizer='nvidia/Qwen3.6-35B-A3B-NVFP4', skip_tokenizer_init=False, tokenizer_mode=auto, revision=None, tokenizer_revision=None, trust_remote_code=True, dtype=torch.bfloat16, max_seq_len=262144, download_dir=None, load_format=auto, tensor_parallel_size=1, pipeline_parallel_size=1, data_parallel_size=1, decode_context_parallel_size=1, dcp_comm_backend=ag_rs, disable_custom_all_reduce=False, quantization=modelopt_mixed, quantization_config=None, enforce_eager=False, enable_return_routed_experts=False, kv_cache_dtype=fp8, device_config=cuda, structured_outputs_config=StructuredOutputsConfig(backend='auto', disable_any_whitespace=False, disable_additional_properties=False, reasoning_parser='qwen3', reasoning_parser_plugin='', enable_in_reasoning=False), observability_config=ObservabilityConfig(show_hidden_metrics_for_version=None, otlp_traces_endpoint=None, collect_detailed_traces=None, kv_cache_metrics=False, kv_cache_metrics_sample=0.01, cudagraph_metrics=False, enable_layerwise_nvtx_tracing=False, enable_mfu_metrics=False, enable_mm_processor_stats=False, enable_logging_iteration_details=False), seed=0, served_model_name=qwen3.6-35b, enable_prefix_caching=True, enable_chunked_prefill=True, pooler_config=None, compilation_config={'mode': <CompilationMode.VLLM_COMPILE: 3>, 'debug_dump_path': None, 'cache_dir': '', 'compile_cache_save_format': 'binary', 'backend': 'inductor', 'custom_ops': ['none'], 'ir_enable_torch_wrap': True, 'splitting_ops': ['vllm::unified_attention_with_output', 'vllm::unified_mla_attention_with_output', 'vllm::mamba_mixer2', 'vllm::mamba_mixer', 'vllm::short_conv', 'vllm::linear_attention', 'vllm::plamo2_mamba_mixer', 'vllm::qwen_gdn_attention_core', 'vllm::gdn_attention_core_xpu', 'vllm::olmo_hybrid_gdn_full_forward', 'vllm::kda_attention', 'vllm::sparse_attn_indexer', 'vllm::rocm_aiter_sparse_attn_indexer', 'vllm::deepseek_v4_attention', 'vllm::unified_kv_cache_update', 'vllm::unified_mla_kv_cache_update'], 'compile_mm_encoder': False, 'cudagraph_mm_encoder': False, 'encoder_cudagraph_token_budgets': [], 'encoder_cudagraph_max_vision_items_per_batch': 0, 'encoder_cudagraph_max_frames_per_batch': None, 'compile_sizes': [], 'compile_ranges_endpoints': [8192], 'inductor_compile_config': {'enable_auto_functionalized_v2': False, 'size_asserts': False, 'alignment_asserts': False, 'scalar_asserts': False, 'combo_kernels': True, 'benchmark_combo_kernel': True}, 'inductor_passes': {}, 'cudagraph_mode': <CUDAGraphMode.FULL_AND_PIECEWISE: (2, 1)>, 'cudagraph_num_of_warmups': 1, 'cudagraph_capture_sizes': [1, 2, 4, 8, 16, 24], 'cudagraph_copy_inputs': False, 'cudagraph_specialize_lora': True, 'use_inductor_graph_partition': False, 'pass_config': {'fuse_norm_quant': False, 'fuse_act_quant': False, 'fuse_attn_quant': False, 'enable_sp': False, 'fuse_gemm_comms': False, 'fuse_allreduce_rms': False, 'fuse_rope_kvcache_cat_mla': False, 'fuse_act_padding': False}, 'max_cudagraph_capture_size': 24, 'dynamic_shapes_config': {'type': <DynamicShapesType.BACKED: 'backed'>, 'evaluate_guards': False, 'assume_32_bit_indexing': False}, 'local_cache_dir': None, 'fast_moe_cold_start': False, 'static_all_moe_layers': []}, kernel_config=KernelConfig(ir_op_priority=IrOpPriorityConfig(rms_norm=['native'], fused_add_rms_norm=['native']), enable_flashinfer_autotune=True, moe_backend='marlin', linear_backend='auto')
qwen36-35b-nvfp4-nightly  | (EngineCore pid=310) [transformers] `Qwen2VLImageProcessorFast` is deprecated. The `Fast` suffix for image processors has been removed; use `Qwen2VLImageProcessor` instead.
qwen36-35b-nvfp4-nightly  | (EngineCore pid=310) INFO 06-01 21:35:59 [parallel_state.py:1422] world_size=1 rank=0 local_rank=0 distributed_init_method=tcp://172.18.0.2:52739 backend=nccl
qwen36-35b-nvfp4-nightly  | (EngineCore pid=310) INFO 06-01 21:35:59 [parallel_state.py:1735] rank 0 in world size 1 is assigned as DP rank 0, PP rank 0, PCP rank 0, TP rank 0, EP rank 0, EPLB rank N/A
qwen36-35b-nvfp4-nightly  | (EngineCore pid=310) INFO 06-01 21:36:00 [topk_topp_sampler.py:45] Using FlashInfer for top-p & top-k sampling.
qwen36-35b-nvfp4-nightly  | (EngineCore pid=310) WARNING 06-01 21:36:00 [__init__.py:204] min_p and logit_bias parameters won't work with speculative decoding.
qwen36-35b-nvfp4-nightly  | (EngineCore pid=310) [transformers] The `use_fast` parameter is deprecated and will be removed in a future version. Use `backend="torchvision"` instead of `use_fast=True`, or `backend="pil"` instead of `use_fast=False`.
qwen36-35b-nvfp4-nightly  | (EngineCore pid=310) INFO 06-01 21:36:09 [gpu_model_runner.py:5036] Starting to load model nvidia/Qwen3.6-35B-A3B-NVFP4...
qwen36-35b-nvfp4-nightly  | (EngineCore pid=310) INFO 06-01 21:36:09 [cuda.py:433] Using backend AttentionBackendEnum.FLASH_ATTN for vit attention
qwen36-35b-nvfp4-nightly  | (EngineCore pid=310) INFO 06-01 21:36:09 [mm_encoder_attention.py:372] Using AttentionBackendEnum.FLASH_ATTN for MMEncoderAttention.
qwen36-35b-nvfp4-nightly  | (EngineCore pid=310) INFO 06-01 21:36:09 [__init__.py:569] Selected FlashInferFP8ScaledMMLinearKernel for ModelOptFp8LinearMethod
qwen36-35b-nvfp4-nightly  | (EngineCore pid=310) INFO 06-01 21:36:09 [qwen_gdn_linear_attn.py:228] Using Triton/FLA GDN prefill kernel (requested=auto, head_k_dim=None).
qwen36-35b-nvfp4-nightly  | (EngineCore pid=310) INFO 06-01 21:36:09 [nvfp4.py:231] Using 'MARLIN' NvFp4 MoE backend out of potential backends: ['FLASHINFER_TRTLLM', 'FLASHINFER_CUTEDSL', 'FLASHINFER_CUTEDSL_BATCHED', 'FLASHINFER_CUTLASS', 'VLLM_CUTLASS', 'MARLIN', 'EMULATION'].
qwen36-35b-nvfp4-nightly  | (EngineCore pid=310) INFO 06-01 21:36:09 [cuda.py:318] Using AttentionBackendEnum.FLASHINFER backend.
qwen36-35b-nvfp4-nightly  | (EngineCore pid=310) INFO 06-01 21:37:32 [weight_utils.py:603] Time spent downloading weights for nvidia/Qwen3.6-35B-A3B-NVFP4: 80.824437 seconds
qwen36-35b-nvfp4-nightly  | (EngineCore pid=310) INFO 06-01 21:37:33 [weight_utils.py:922] Filesystem type for checkpoints: EXT4. Checkpoint size: 21.82 GiB. Available RAM: 89.06 GiB.
qwen36-35b-nvfp4-nightly  | (EngineCore pid=310) INFO 06-01 21:37:33 [weight_utils.py:884] Prefetching checkpoint files into page cache started (in background, num_threads=8, block_size=16777216 bytes)
Loading safetensors checkpoint shards:   0% Completed | 0/3 [00:00<?, ?it/s]
qwen36-35b-nvfp4-nightly  | (EngineCore pid=310) INFO 06-01 21:37:33 [weight_utils.py:856] Prefetching checkpoint files: 10% (1/3)
qwen36-35b-nvfp4-nightly  | (EngineCore pid=310) INFO 06-01 21:37:33 [weight_utils.py:856] Prefetching checkpoint files: 20% (2/3)
qwen36-35b-nvfp4-nightly  | (EngineCore pid=310) INFO 06-01 21:37:33 [weight_utils.py:856] Prefetching checkpoint files: 30% (3/3)
qwen36-35b-nvfp4-nightly  | (EngineCore pid=310) INFO 06-01 21:37:33 [weight_utils.py:879] Prefetching checkpoint files into page cache finished in 0.82s
Loading safetensors checkpoint shards:  33% Completed | 1/3 [01:15<02:31, 75.94s/it]
Loading safetensors checkpoint shards:  67% Completed | 2/3 [02:33<01:17, 77.16s/it]
Loading safetensors checkpoint shards: 100% Completed | 3/3 [02:47<00:00, 48.04s/it]
Loading safetensors checkpoint shards: 100% Completed | 3/3 [02:47<00:00, 55.78s/it]
qwen36-35b-nvfp4-nightly  | (EngineCore pid=310) 
qwen36-35b-nvfp4-nightly  | (EngineCore pid=310) INFO 06-01 21:40:20 [default_loader.py:397] Loading weights took 167.46 seconds
qwen36-35b-nvfp4-nightly  | (EngineCore pid=310) WARNING 06-01 21:40:20 [marlin.py:34] Your GPU does not have native support for FP4 computation but FP4 quantization is being used. Weight-only FP4 compression will be used leveraging the Marlin kernel. This may degrade performance for compute-heavy workloads.
qwen36-35b-nvfp4-nightly  | (EngineCore pid=310) WARNING 06-01 21:40:20 [marlin_utils_fp4.py:300] Your GPU does not have native support for FP4 computation but FP4 quantization is being used. Weight-only FP4 compression will be used leveraging the Marlin kernel. This may degrade performance for compute-heavy workloads.
qwen36-35b-nvfp4-nightly  | (EngineCore pid=310) INFO 06-01 21:40:21 [nvfp4.py:537] Using MoEPrepareAndFinalizeNoDPEPModular
qwen36-35b-nvfp4-nightly  | (EngineCore pid=310) INFO 06-01 21:40:25 [gpu_model_runner.py:5060] Loading drafter model...
qwen36-35b-nvfp4-nightly  | (EngineCore pid=310) INFO 06-01 21:40:25 [vllm.py:984] Asynchronous scheduling is enabled.
qwen36-35b-nvfp4-nightly  | (EngineCore pid=310) INFO 06-01 21:40:25 [kernel.py:270] Final IR op priority after setting platform defaults: IrOpPriorityConfig(rms_norm=['native'], fused_add_rms_norm=['native'])
qwen36-35b-nvfp4-nightly  | (EngineCore pid=310) INFO 06-01 21:40:25 [kernel.py:270] Final IR op priority after setting platform defaults: IrOpPriorityConfig(rms_norm=['native'], fused_add_rms_norm=['native'])
qwen36-35b-nvfp4-nightly  | (EngineCore pid=310) INFO 06-01 21:40:26 [cuda.py:378] Using FLASHINFER attention backend out of potential backends: ['FLASHINFER', 'TRITON_ATTN'].
qwen36-35b-nvfp4-nightly  | (EngineCore pid=310) INFO 06-01 21:40:26 [unquantized.py:212] Using TRITON Unquantized MoE backend out of potential backends: ['FlashInfer TRTLLM', 'FlashInfer CUTLASS', 'TRITON', 'BATCHED_TRITON'].
qwen36-35b-nvfp4-nightly  | (EngineCore pid=310) INFO 06-01 21:40:26 [weight_utils.py:922] Filesystem type for checkpoints: EXT4. Checkpoint size: 21.82 GiB. Available RAM: 68.80 GiB.
qwen36-35b-nvfp4-nightly  | (EngineCore pid=310) INFO 06-01 21:40:26 [weight_utils.py:884] Prefetching checkpoint files into page cache started (in background, num_threads=8, block_size=16777216 bytes)
Loading safetensors checkpoint shards:   0% Completed | 0/3 [00:00<?, ?it/s]
qwen36-35b-nvfp4-nightly  | (EngineCore pid=310) INFO 06-01 21:40:30 [weight_utils.py:856] Prefetching checkpoint files: 10% (1/3)
Loading safetensors checkpoint shards:  33% Completed | 1/3 [00:10<00:20, 10.24s/it]
qwen36-35b-nvfp4-nightly  | (EngineCore pid=310) INFO 06-01 21:40:37 [weight_utils.py:856] Prefetching checkpoint files: 20% (2/3)
qwen36-35b-nvfp4-nightly  | (EngineCore pid=310) INFO 06-01 21:40:38 [weight_utils.py:856] Prefetching checkpoint files: 30% (3/3)
qwen36-35b-nvfp4-nightly  | (EngineCore pid=310) INFO 06-01 21:40:38 [weight_utils.py:879] Prefetching checkpoint files into page cache finished in 12.05s
Loading safetensors checkpoint shards:  67% Completed | 2/3 [00:14<00:06,  6.79s/it]
Loading safetensors checkpoint shards: 100% Completed | 3/3 [00:23<00:00,  7.81s/it]
Loading safetensors checkpoint shards: 100% Completed | 3/3 [00:23<00:00,  7.88s/it]
qwen36-35b-nvfp4-nightly  | (EngineCore pid=310) 
qwen36-35b-nvfp4-nightly  | (EngineCore pid=310) INFO 06-01 21:40:50 [default_loader.py:397] Loading weights took 23.75 seconds
qwen36-35b-nvfp4-nightly  | (EngineCore pid=310) INFO 06-01 21:40:50 [unquantized.py:341] Using MoEPrepareAndFinalizeNoDPEPModular
qwen36-35b-nvfp4-nightly  | (EngineCore pid=310) INFO 06-01 21:40:50 [llm_base_proposer.py:1328] Detected MTP model. Sharing target model embedding weights with the draft model.
qwen36-35b-nvfp4-nightly  | (EngineCore pid=310) INFO 06-01 21:40:50 [llm_base_proposer.py:1384] Detected MTP model. Sharing target model lm_head weights with the draft model.
qwen36-35b-nvfp4-nightly  | (EngineCore pid=310) INFO 06-01 21:40:51 [gpu_model_runner.py:5131] Model loading took 21.93 GiB memory and 281.243837 seconds
qwen36-35b-nvfp4-nightly  | (EngineCore pid=310) INFO 06-01 21:40:51 [interface.py:662] Setting attention block size to 2128 tokens to ensure that attention page size is >= mamba page size.
qwen36-35b-nvfp4-nightly  | (EngineCore pid=310) INFO 06-01 21:40:51 [gpu_model_runner.py:6140] Encoder cache will be initialized with a budget of 16384 tokens, and profiled with 1 image items of the maximum feature size.
qwen36-35b-nvfp4-nightly  | (EngineCore pid=310) /usr/local/lib/python3.12/dist-packages/vllm/envs.py:2144: FutureWarning: VLLM_USE_FLASHINFER_MOE_FP4 is deprecated and will be removed in v0.23. Use --moe-backend (e.g. flashinfer_trtllm, flashinfer_cutlass, flashinfer_cutedsl).
qwen36-35b-nvfp4-nightly  | (EngineCore pid=310)   raw = getter()
qwen36-35b-nvfp4-nightly  | (EngineCore pid=310) /usr/local/lib/python3.12/dist-packages/vllm/envs.py:2144: FutureWarning: VLLM_USE_FLASHINFER_MOE_FP4 is deprecated and will be removed in v0.23. Use --moe-backend (e.g. flashinfer_trtllm, flashinfer_cutlass, flashinfer_cutedsl).
qwen36-35b-nvfp4-nightly  | (EngineCore pid=310)   raw = getter()
qwen36-35b-nvfp4-nightly  | (EngineCore pid=310) INFO 06-01 21:41:04 [backends.py:1089] Using cache directory: /root/.cache/vllm/torch_compile_cache/512ec61fcb/rank_0_0/backbone for vLLM's torch.compile
qwen36-35b-nvfp4-nightly  | (EngineCore pid=310) INFO 06-01 21:41:04 [backends.py:1148] Dynamo bytecode transform time: 6.57 s
qwen36-35b-nvfp4-nightly  | (EngineCore pid=310) [rank0]:W0601 21:41:09.069000 310 torch/_inductor/utils.py:1731] Not enough SMs to use max_autotune_gemm mode
qwen36-35b-nvfp4-nightly  | (EngineCore pid=310) INFO 06-01 21:41:09 [backends.py:378] Cache the graph of compile range (1, 8192) for later use
qwen36-35b-nvfp4-nightly  | (EngineCore pid=310) INFO 06-01 21:41:27 [backends.py:393] Compiling a graph for compile range (1, 8192) takes 23.26 s
qwen36-35b-nvfp4-nightly  | (EngineCore pid=310) INFO 06-01 21:41:30 [decorators.py:708] saved AOT compiled function to /root/.cache/vllm/torch_compile_cache/torch_aot_compile/73fccadd54d650b1a0e649536224bfe56d312bc3fedb645bdbf06b8568d2288d/rank_0_0/model
qwen36-35b-nvfp4-nightly  | (EngineCore pid=310) INFO 06-01 21:41:30 [monitor.py:53] torch.compile took 32.27 s in total
qwen36-35b-nvfp4-nightly  | (EngineCore pid=310) INFO 06-01 21:42:04 [marlin_utils.py:437] Marlin kernel can achieve better performance for small size_n with experimental use_atomic_add feature. You can consider set environment variable VLLM_MARLIN_USE_ATOMIC_ADD to 1 if possible.
qwen36-35b-nvfp4-nightly  | (EngineCore pid=310) INFO 06-01 21:42:07 [monitor.py:81] Initial profiling/warmup run took 37.10 s
qwen36-35b-nvfp4-nightly  | (EngineCore pid=310) /usr/local/lib/python3.12/dist-packages/vllm/envs.py:2144: FutureWarning: VLLM_USE_FLASHINFER_MOE_FP4 is deprecated and will be removed in v0.23. Use --moe-backend (e.g. flashinfer_trtllm, flashinfer_cutlass, flashinfer_cutedsl).
qwen36-35b-nvfp4-nightly  | (EngineCore pid=310)   raw = getter()
qwen36-35b-nvfp4-nightly  | (EngineCore pid=310) INFO 06-01 21:42:07 [backends.py:1089] Using cache directory: /root/.cache/vllm/torch_compile_cache/512ec61fcb/rank_0_0/eagle_head for vLLM's torch.compile
qwen36-35b-nvfp4-nightly  | (EngineCore pid=310) INFO 06-01 21:42:07 [backends.py:1148] Dynamo bytecode transform time: 0.32 s
qwen36-35b-nvfp4-nightly  | (EngineCore pid=310) INFO 06-01 21:42:13 [backends.py:393] Compiling a graph for compile range (1, 8192) takes 6.18 s
qwen36-35b-nvfp4-nightly  | (EngineCore pid=310) INFO 06-01 21:42:13 [decorators.py:708] saved AOT compiled function to /root/.cache/vllm/torch_compile_cache/torch_aot_compile/26b1585c0d647d5a5315f99a03fd2cb7a5189c4909f4c197ec8302c61c03318c/rank_0_0/model
qwen36-35b-nvfp4-nightly  | (EngineCore pid=310) INFO 06-01 21:42:13 [monitor.py:53] torch.compile took 6.63 s in total
qwen36-35b-nvfp4-nightly  | (EngineCore pid=310) WARNING 06-01 21:42:14 [fused_moe.py:1071] Using default MoE config. Performance might be sub-optimal! Config file not found at /usr/local/lib/python3.12/dist-packages/vllm/model_executor/layers/fused_moe/configs/E=256,N=512,device_name=NVIDIA_GB10.json
qwen36-35b-nvfp4-nightly  | (EngineCore pid=310) INFO 06-01 21:42:15 [monitor.py:81] Initial profiling/warmup run took 1.31 s
qwen36-35b-nvfp4-nightly  | (EngineCore pid=310) WARNING 06-01 21:42:16 [kv_cache_utils.py:1157] Add 3 padding layers, may waste at most 10.00% KV cache memory
qwen36-35b-nvfp4-nightly  | (EngineCore pid=310) WARNING 06-01 21:42:16 [compilation.py:1416] CUDAGraphMode.FULL_AND_PIECEWISE is not supported with spec-decode for attention backend FlashInferBackend (support: AttentionCGSupport.UNIFORM_SINGLE_TOKEN_DECODE); setting cudagraph_mode=PIECEWISE
qwen36-35b-nvfp4-nightly  | (EngineCore pid=310) INFO 06-01 21:42:16 [gpu_model_runner.py:6283] Profiling CUDA graph memory: PIECEWISE=6 (largest=24)
qwen36-35b-nvfp4-nightly  | (EngineCore pid=310) INFO 06-01 21:42:17 [gpu_model_runner.py:6369] Estimated CUDA graph memory: 0.18 GiB total
qwen36-35b-nvfp4-nightly  | (EngineCore pid=310) INFO 06-01 21:42:18 [gpu_worker.py:469] Available KV cache memory: 73.13 GiB
qwen36-35b-nvfp4-nightly  | (EngineCore pid=310) INFO 06-01 21:42:18 [gpu_worker.py:484] CUDA graph memory profiling is enabled (default since v0.21.0). The current --gpu-memory-utilization=0.8500 is equivalent to --gpu-memory-utilization=0.8485 without CUDA graph memory profiling. To maintain the same effective KV cache size as before, increase --gpu-memory-utilization to 0.8515. To disable, set VLLM_MEMORY_PROFILER_ESTIMATE_CUDAGRAPHS=0.
qwen36-35b-nvfp4-nightly  | (EngineCore pid=310) WARNING 06-01 21:42:18 [kv_cache_utils.py:1157] Add 3 padding layers, may waste at most 10.00% KV cache memory
qwen36-35b-nvfp4-nightly  | (EngineCore pid=310) INFO 06-01 21:42:18 [kv_cache_utils.py:1733] GPU KV cache size: 6,312,658 tokens
qwen36-35b-nvfp4-nightly  | (EngineCore pid=310) INFO 06-01 21:42:18 [kv_cache_utils.py:1734] Maximum concurrency for 262,144 tokens per request: 24.08x
qwen36-35b-nvfp4-nightly  | (EngineCore pid=310) 2026-06-01 21:42:26,465 - INFO - autotuner.py:615 - flashinfer.jit: [Autotuner]: Autotuning process starts ...
[AutoTuner]: Tuning fp8_gemm: 100%|██████████| 21/21 [00:07<00:00,  2.69profile/s]
qwen36-35b-nvfp4-nightly  | (EngineCore pid=310) cudnn_handle created for device_id = 0
qwen36-35b-nvfp4-nightly  | (EngineCore pid=310) 
[AutoTuner]: Tuning fp8_gemm: 100%|██████████| 21/21 [00:05<00:00,  3.61profile/s]
[AutoTuner]: Tuning fp8_gemm: 100%|██████████| 21/21 [00:00<00:00,  8.69profile/s]
[AutoTuner]: Tuning fp8_gemm: 100%|██████████| 21/21 [00:00<00:00, 141.67profile/s]
[AutoTuner]: Tuning fp8_gemm: 100%|██████████| 21/21 [00:00<00:00, 12.43profile/s]
[AutoTuner]: Tuning fp8_gemm: 100%|██████████| 21/21 [00:00<00:00, 142.67profile/s]
[AutoTuner]: Tuning fp8_gemm: 100%|██████████| 21/21 [00:05<00:00,  3.83profile/s]
[AutoTuner]: Tuning fp8_gemm: 100%|██████████| 21/21 [00:00<00:00,  9.44profile/s]
[AutoTuner]: Tuning fp8_gemm: 100%|██████████| 21/21 [00:00<00:00,  9.55profile/s]
[AutoTuner]: Tuning fp8_gemm: 100%|██████████| 21/21 [00:00<00:00,  6.17profile/s]
[AutoTuner]: Tuning fp8_gemm: 100%|██████████| 21/21 [00:00<00:00,  8.88profile/s]
[AutoTuner]: Tuning fp8_gemm: 100%|██████████| 21/21 [00:00<00:00,  6.22profile/s]
[AutoTuner]: Tuning fp8_gemm: 100%|██████████| 21/21 [00:00<00:00,  6.17profile/s]
[AutoTuner]: Tuning fp8_gemm: 100%|██████████| 21/21 [00:00<00:00,  6.12profile/s]
[AutoTuner]: Tuning fp8_gemm: 100%|██████████| 21/21 [00:00<00:00, 17.92profile/s]
[AutoTuner]: Tuning fp8_gemm: 100%|██████████| 21/21 [00:00<00:00,  6.15profile/s]
[AutoTuner]: Tuning fp8_gemm: 100%|██████████| 21/21 [00:00<00:00,  6.14profile/s]
[AutoTuner]: Tuning fp8_gemm: 100%|██████████| 21/21 [00:00<00:00,  6.16profile/s]
[AutoTuner]: Tuning fp8_gemm: 100%|██████████| 21/21 [00:00<00:00,  5.94profile/s]
[AutoTuner]: Tuning fp8_gemm: 100%|██████████| 21/21 [00:00<00:00,  6.09profile/s]
[AutoTuner]: Tuning fp8_gemm: 100%|██████████| 21/21 [00:00<00:00,  6.16profile/s]
[AutoTuner]: Tuning fp8_gemm: 100%|██████████| 21/21 [00:00<00:00,  5.92profile/s]
[AutoTuner]: Tuning fp8_gemm: 100%|██████████| 21/21 [00:00<00:00,  6.15profile/s]
[AutoTuner]: Tuning fp8_gemm: 100%|██████████| 21/21 [00:00<00:00,  6.16profile/s]
qwen36-35b-nvfp4-nightly  | (EngineCore pid=310) 2026-06-01 21:42:54,445 - INFO - autotuner.py:634 - flashinfer.jit: [Autotuner]: Autotuning process ends
Capturing CUDA graphs (mixed prefill-decode, PIECEWISE): 100%|██████████| 6/6 [00:01<00:00,  3.27it/s]
qwen36-35b-nvfp4-nightly  | (EngineCore pid=310) INFO 06-01 21:42:59 [gpu_model_runner.py:6460] Graph capturing finished in 5 secs, took 0.32 GiB
qwen36-35b-nvfp4-nightly  | (EngineCore pid=310) INFO 06-01 21:42:59 [gpu_worker.py:622] CUDA graph pool memory: 0.32 GiB (actual), 0.18 GiB (estimated), difference: 0.14 GiB (43.7%).
qwen36-35b-nvfp4-nightly  | (EngineCore pid=310) INFO 06-01 21:42:59 [jit_monitor.py:54] Kernel JIT monitor activated — Triton JIT compilations during inference will be logged as warnings.
qwen36-35b-nvfp4-nightly  | (EngineCore pid=310) INFO 06-01 21:42:59 [core.py:302] init engine (profile, create kv cache, warmup model) took 128.32 s (compilation: 38.89 s)
qwen36-35b-nvfp4-nightly  | (EngineCore pid=310) /usr/local/lib/python3.12/dist-packages/vllm/envs.py:1999: FutureWarning: VLLM_USE_FLASHINFER_MOE_FP4 is deprecated and will be removed in v0.23. Use --moe-backend (e.g. flashinfer_trtllm, flashinfer_cutlass, flashinfer_cutedsl).
qwen36-35b-nvfp4-nightly  | (EngineCore pid=310)   return environment_variables[name]()
qwen36-35b-nvfp4-nightly  | (EngineCore pid=310) INFO 06-01 21:42:59 [kernel.py:270] Final IR op priority after setting platform defaults: IrOpPriorityConfig(rms_norm=['native'], fused_add_rms_norm=['native'])
qwen36-35b-nvfp4-nightly  | INFO 06-01 21:42:59 [utils.py:502] Waiting for API servers to complete ...
qwen36-35b-nvfp4-nightly  | ERROR 06-01 21:42:59 [utils.py:550] Exception occurred while running API servers: Process RustFrontend (PID: 353) died with exit code 2
qwen36-35b-nvfp4-nightly  | ERROR 06-01 21:42:59 [utils.py:550] Traceback (most recent call last):
qwen36-35b-nvfp4-nightly  | ERROR 06-01 21:42:59 [utils.py:550]   File "/usr/local/lib/python3.12/dist-packages/vllm/v1/utils.py", line 537, in wait_for_completion_or_failure
qwen36-35b-nvfp4-nightly  | ERROR 06-01 21:42:59 [utils.py:550]     raise RuntimeError(
qwen36-35b-nvfp4-nightly  | ERROR 06-01 21:42:59 [utils.py:550] RuntimeError: Process RustFrontend (PID: 353) died with exit code 2
qwen36-35b-nvfp4-nightly  | (EngineCore pid=310) INFO 06-01 21:42:59 [core.py:1287] Shutdown initiated (timeout=0)
qwen36-35b-nvfp4-nightly  | (EngineCore pid=310) INFO 06-01 21:42:59 [core.py:1310] Shutdown complete
qwen36-35b-nvfp4-nightly  | Traceback (most recent call last):
qwen36-35b-nvfp4-nightly  |   File "/usr/local/bin/vllm", line 10, in <module>
qwen36-35b-nvfp4-nightly  |     sys.exit(main())
qwen36-35b-nvfp4-nightly  |              ^^^^^^
qwen36-35b-nvfp4-nightly  |   File "/usr/local/lib/python3.12/dist-packages/vllm/entrypoints/cli/main.py", line 92, in main
qwen36-35b-nvfp4-nightly  |     args.dispatch_function(args)
qwen36-35b-nvfp4-nightly  |   File "/usr/local/lib/python3.12/dist-packages/vllm/entrypoints/cli/serve.py", line 144, in cmd
qwen36-35b-nvfp4-nightly  |     run_multi_api_server(args)
qwen36-35b-nvfp4-nightly  |   File "/usr/local/lib/python3.12/dist-packages/vllm/entrypoints/cli/serve.py", line 366, in run_multi_api_server
qwen36-35b-nvfp4-nightly  |     wait_for_completion_or_failure(
qwen36-35b-nvfp4-nightly  |   File "/usr/local/lib/python3.12/dist-packages/vllm/v1/utils.py", line 537, in wait_for_completion_or_failure
qwen36-35b-nvfp4-nightly  |     raise RuntimeError(
qwen36-35b-nvfp4-nightly  | RuntimeError: Process RustFrontend (PID: 353) died with exit code 2
qwen36-35b-nvfp4-nightly exited with code 1
```