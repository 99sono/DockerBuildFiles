# DeepSeek Analysis — Session 01 (2026-06-21) — Worker (spark02)

## Status: NCCL handshake SUCCESSFUL. Model loading completed.

### Key log sequence (worker)

```
parallel_state.py:1422] world_size=2 rank=1 local_rank=0
  distributed_init_method=tcp://10.0.1.1:29501 backend=nccl
```
NCCL connected to head at 10.0.1.1:29501 without errors. GID index 4 was correct.

```
pynccl.py:113] vLLM is using nccl==2.30.4
parallel_state.py:1735] rank 1 in world size 2 is assigned as
  DP rank 0, PP rank 0, PCP rank 0, TP rank 1, EP rank 1
```
Worker got TP rank 1, EP rank 1 — exactly right for a 2-node TP=2 setup.

```
quant_config.py:73] DeepSeek V4 expert_dtype resolved to 'fp4'
deep_gemm.py:117] DeepGEMM E8M0 enabled on current platform.
attention.py:923] Using DeepSeek's fp8_ds_mla KV cache format.
mxfp4.py:389] Using 'B12X' Mxfp4 MoE backend.
```
**The model is using its quantized form** — FP8 weights + FP4 experts + FP8 KV cache.
This is NOT the vanilla BF16 mode (which would be ~700 GiB and impossible on
2×128 GB). The 148.66 GiB checkpoint size is the quantized size.

```
weight_utils.py:922] Checkpoint size: 148.66 GiB. Available RAM: 37.99 GiB.
weight_utils.py:952] Auto-prefetch is disabled because...
  checkpoint size (148.66 GiB) exceeds 90% of available RAM (37.99 GiB).
```
The model weights (148 GiB total, ~74 GiB per node at TP=2) are loaded
directly from disk without prefetching because RAM is tight (38 GiB free).
This is expected on a UMA system — the 128 GiB is shared between CPU and GPU.

```
default_loader.py:397] Loading weights took 116.23 seconds
```
~2 minutes to load the main model weights.

```
mtp.py:474] MTP draft model loaded: 39 params
default_loader.py:397] Loading weights took 27.08 seconds
```
MTP (Multi-Token Prediction) draft model loaded in another 27 seconds.
Weight sharing between target and draft model was configured automatically.

## Intuitions & Gotchas

### 1. The GID index fix worked

Before: `ibv_modify_qp failed with 22 Invalid argument, remote GID ::`
After: NCCL connects cleanly, `rank 1 in world size 2`

The root cause was a mismatch between the head (IPv4 at GID index 2) and the
worker (IPv4 at GID index 4). Both `.env` files had `4,4`. The fix was setting
`NCCL_IB_GID_INDEX="2,2"` on the head while keeping `4,4` on the worker.

### 2. The image is quantized — you ARE using NVFP4

The log says:
```
quantization=deepseek_v4_fp8    (weights are FP8)
expert_dtype resolved to 'fp4'  (MoE experts are FP4)
kv_cache_dtype=fp8              (KV cache is FP8)
```

This is the quantized path. No BF16 fallback. The recipe is doing what it
promises. The 148 GiB checkpoint confirms this — the raw model would be
much larger.

### 3. "SymmMemCommunicator not supported" is cosmetic

```
symm_mem.py:66] SymmMemCommunicator: Device capability 12.1 not supported
```

sm_121 (Blackwell GB10) isn't in the supported list for SymmMemCommunicator.
vLLM falls back to PYNCCL (`Using ['PYNCCL'] all-reduce backends`). This is
functionally identical — PyNCCL is the standard NCCL wrapper. No performance
impact. The warning is just the image not being fully scrubbed for Blackwell.

### 4. RAM vs checkpoint size warning is normal

The `Auto-prefetch is disabled` warning at first looks scary but is expected:
- 128 GB UMA total
- ~74 GiB weights loaded per node (TP=2 sharding)
- ~38 GiB free at load time
- Model too big to prefetch into page cache → direct disk I/O

This adds ~2 minutes to cold start but doesn't affect runtime throughput.
Warm starts will be faster because the host page cache holds the weights.

### 5. MTP speculative decoding confirmed

```
num_speculative_tokens=2
MTP draft model loaded: 39 params
Sharing target model embedding weights with the draft model
```

MTP with 2 speculative tokens is active. The draft model shares the target's
embedding and lm_head weights (no extra memory overhead for the draft head).
The warning about `min_p and logit_bias won't work with speculative decoding`
is expected — those sampling parameters are incompatible with speculative
decoding in any framework.
