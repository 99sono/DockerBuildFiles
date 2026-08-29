# Cluster Topology

Two NVIDIA DGX Spark nodes (GB10, SM121, 128 GB unified memory each), connected by a
dual-port RoCE fabric ("Port 1"). One model, one TP=2 group spanning both nodes.

## Nodes

| Role | Host | Fabric IP | `NCCL_IB_GID_INDEX` |
|---|---|---|---|
| head (rank 0) | spark01 | 10.0.1.1 | `"2,2"` (IPv4 GIDs at index 2) |
| worker (rank 1) | spark02 | 10.0.1.2 | `"4,4"` (IPv4 GIDs at index 4) |

- **The GID index differs per node — never share a `.env` between nodes.**
  `04_check_nccl.sh` auto-detects the correct value on each node.
- `VLLM_HOST_IP` = the node's runtime fabric IP. `WORKER_HOST` (variant-root `.env`)
  is the SSH target used to propagate the image build to the other node — different
  concept, same IP value.

## NCCL / RDMA

- `MASTER_ADDR=10.0.1.1:25000` — torch.distributed rendezvous. The worker parks here
  until the head joins; if the head never comes up, the worker hangs (see runbook).
- `NCCL_IB_HCA="rocep1s0f0,roceP2p1s0f0"` — both RoCE ports.
- `NCCL_SOCKET_IFNAME` / `GLOO_SOCKET_IFNAME` / `TP_SOCKET_IFNAME="enP7s7"`.

## Model artifact

- `deepseek-ai/DeepSeek-V4-Flash-0731` — 304B MoE, official pre-quantized release
  (2026-07-31): FP4 MoE experts + FP8 e4m3 everything else. **48 safetensors shards,
  156 GB on disk.**
- Weights live in each node's HF cache (`~/.cache/huggingface`), mounted into the
  container at `/cache/huggingface`; served fully offline
  (`HF_HUB_OFFLINE=1`, `HF_HOME=/cache/huggingface`). Both nodes must have the weights
  before bring-up (download on one, rsync to the other).

## Serving

- Internal port **8000** on the head (host networking) → `http://10.0.1.1:8000/v1`.
- **One variant per node**: host networking means port 8000 collides across variants;
  stop any other variant's container before bring-up.
- Model alias: `deepseek-v4-flash-0731`.

## Inter-node access

- spark02 → spark01: `ssh sono99@10.0.1.1` — requires `source ~/.ssh/agent-env`
  first (loads the agent key; there is no password auth on the fabric link).