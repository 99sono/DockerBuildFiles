# Docker Compose Log and Analysis — 2026-06-21

## Cluster Topology

| Node | Hostname | Role | Rank | IP (mgmt) | IP (RoCE Port 1) | IP (RoCE Port 2) |
|------|----------|------|------|-----------|-------------------|-------------------|
| spark01 | `inference-server` | Head | 0 | 192.168.1.55 | 10.0.1.1 | 10.0.2.1 |
| spark02 | `inference-server` | Worker | 1 | 192.168.1.56 | 10.0.1.2 | 10.0.2.2 |

## Docker Image

`aidendle94/sparkrun-vllm-ds4-gb10:production-ready`

## Key Environment Variables

| Variable | Value | Purpose |
|----------|-------|---------|
| `MASTER_ADDR` | `10.0.1.1` | GLOO rendezvous on head's Port 1 |
| `NCCL_IB_DISABLE` | `0` | RDMA enabled |
| `NCCL_IB_HCA` | `rocep1s0f0,roceP2p1s0f0` | Both ConnectX-7 ports |
| `NCCL_IB_GID_INDEX` | `4,4` (both nodes) | ⚠️ Needs per-node tuning |
| `NCCL_SOCKET_IFNAME` | `enP7s7` | TCP fallback on management NIC |
| `GLOO_SOCKET_IFNAME` | `enP7s7` | Bootstrap over management NIC |
| `TP_SOCKET_IFNAME` | `enP7s7` | TP coordination over management NIC |
| `TORCH_CUDA_ARCH_LIST` | `12.1a` | SM121 (Blackwell GB10) |
| `CUDA_VISIBLE_DEVICES` | `0` | Single GPU exposed |

## vLLM Serve Arguments

| Argument | Value |
|----------|-------|
| Model | `deepseek-ai/DeepSeek-V4-Flash` |
| TP size | 2 (across 2 nodes) |
| PP size | 1 |
| KV cache dtype | fp8 |
| Block size | 256 |
| Max model len | 200000 |
| Max num seqs | 4 |
| Max num batched tokens | 8192 |
| GPU mem utilization | 0.8 |
| Distributed backend | `mp` (no Ray) |
| Speculative config | `{"method":"mtp","num_speculative_tokens":2}` |
| Tokenizer mode | `deepseek_v4` |
| Head node | headless on worker, API server on head |

## Worker Log Highlights

```
parallel_state.py:1422] world_size=2 rank=1 local_rank=0
  distributed_init_method=tcp://10.0.1.1:29501 backend=nccl

pynccl_wrapper.py:388] RuntimeError: NCCL error: unhandled system error

ibvwrap.cc:309 NCCL WARN Call to ibv_modify_qp failed with 22 Invalid argument
  dev rocep1s0f0:1, curr state INIT, next state RTR,
  local GID ::ffff:10.0.1.2, remote GID ::

ibvwrap.cc:309 NCCL WARN Call to ibv_modify_qp failed with 22 Invalid argument
  dev roceP2p1s0f0:1, curr state INIT, next state RTR,
  local GID ::ffff:10.0.2.2, remote GID ::
```

## Head Log Highlights

```
multiproc_executor.py:139] DP group leader: node_rank=0, master_addr=10.0.1.1,
  mq_connect_ip=192.168.1.55 (local)

parallel_state.py:1422] world_size=2 rank=0 local_rank=0
  distributed_init_method=tcp://10.0.1.1:29501 backend=nccl

pynccl_wrapper.py:388] RuntimeError: NCCL error: unhandled system error

ibvwrap.cc:309 NCCL WARN Call to ibv_modify_qp failed with 61 No data available
  dev roceP2p1s0f0:1, curr state INIT, next state RTR,
  local GID ::, remote GID ::ffff:10.0.2.2
```

## GID Tables

### Head (spark01)

| Index | rocep1s0f0 (Port 1) | roceP2p1s0f0 (Port 2) |
|-------|---------------------|----------------------|
| 0 | `fe80:...:8ddd` | `fe80:...:8de1` |
| 1 | `fe80:...:8ddd` | `fe80:...:8de1` |
| **2** | **`::ffff:0a00:0101`** ✅ **10.0.1.1** | **`::ffff:0a00:0201`** ✅ **10.0.2.1** |
| 3 | `::ffff:0a00:0101` | `::ffff:0a00:0201` |
| 4 | `0000:...:0000` ❌ empty | `0000:...:0000` ❌ empty |
| 5-7 | `0000:...:0000` | `0000:...:0000` |

### Worker (spark02)

| Index | rocep1s0f0 (Port 1) | roceP2p1s0f0 (Port 2) |
|-------|---------------------|----------------------|
| 0 | `fe80:...:a5cb` | `fe80:...:a5cf` |
| 1 | `fe80:...:a5cb` | `fe80:...:a5cf` |
| 2 | `fe80:...:291a` (link-local) | `fe80:...:6e4f` (link-local) |
| 3 | `fe80:...:291a` (link-local) | `fe80:...:6e4f` (link-local) |
| **4** | **`::ffff:0a00:0102`** ✅ **10.0.1.2** | **`::ffff:0a00:0202`** ✅ **10.0.2.2** |
| 5 | `::ffff:0a00:0102` | `::ffff:0a00:0202` |
| 6-7 | `0000:...:0000` | `0000:...:0000` |
