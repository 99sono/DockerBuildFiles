# DeepSeek Analysis — Session 01 (2026-06-21) — Head (spark01)

## Status: NCCL handshake SUCCESSFUL. Model loading completed.

### Key log sequence (head)

```
EngineCore pid=33] multiproc_executor.py:139] DP group leader:
  node_rank=0, master_addr=10.0.1.1, mq_connect_ip=192.168.1.55 (local)
```
Head (rank 0) established the GLOO rendezvous on 10.0.1.1:29501.

```
Worker pid=56] parallel_state.py:1422] world_size=2 rank=0 local_rank=0
  distributed_init_method=tcp://10.0.1.1:29501 backend=nccl
```
NCCL initialized successfully on the head side. GID index 2 was correct.

```
Worker pid=56] pynccl.py:113] vLLM is using nccl==2.30.4
Worker pid=56] Using ['PYNCCL'] all-reduce backends for group 'tp:0'
Worker pid=56] rank 0 ... TP rank 0, EP rank 0
```
Head got TP rank 0, EP rank 0. Worker got TP rank 1, EP rank 1. Perfect.

```
Worker_TP0 pid=56] Starting to load model...
Worker_TP0 pid=56] checkpoint size: 148.66 GiB
Loading safetensors checkpoint shards:   7% Completed | 3/46
```
Model loading started on head. 46 shards total, ~3.3s per shard.

### Worker model load completed (from worker logs)

```
default_loader.py:397] Loading weights took 116.23 seconds
mxfp4.py:1789] Using MoEPrepareAndFinalizeNoDPEPModular
gpu_model_runner.py:5061] Loading drafter model...
mtp.py:474] MTP draft model loaded: 39 params
default_loader.py:397] Loading weights took 27.08 seconds
```

## Key difference from the failed run

Before the GID fix, NCCL failed at QP transition:
```
ibv_modify_qp failed with 61 No data available, on dev roceP2p1s0f0:1
  local GID ::, remote GID ::ffff:10.0.2.2
```

After the fix (`NCCL_IB_GID_INDEX="2,2"` instead of `4,4`):
```
parallel_state.py:1422] world_size=2 rank=0 ... backend=nccl   ✅
```

The fix was: the head's IPv4 RoCE GIDs live at index 2, not index 4.
