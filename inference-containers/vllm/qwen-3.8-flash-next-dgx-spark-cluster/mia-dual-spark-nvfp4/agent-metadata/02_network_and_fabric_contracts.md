# Network and InfiniBand / RoCE Fabric Contracts

## 1. Network Topology

The dual DGX Spark cluster consists of two physical nodes:
- `spark01` (Head node)
- `spark02` (Worker node)

### Interface Mapping

| Interface Name | Description | `spark01` IP | `spark02` IP | MTU | Purpose |
|---|---|---|---|---|---|
| `enp1s0f0np0` | ConnectX-7 RoCE Port 1 | `10.0.1.1/24` | `10.0.1.2/24` | 9000 | Primary Inter-node RoCE Data Path |
| `enP2p1s0f0np0` | ConnectX-7 RoCE Port 2 | `10.0.2.1/24` | `10.0.2.2/24` | 9000 | Secondary RoCE Data Path |
| `enP7s7` | 1GbE/10GbE Onboard LAN | `192.168.1.55/24` | `192.168.1.56/24` | 1500 | Out-of-band / Management / GLOO control |

---

## 2. InfiniBand / RoCE HCAs and GID Indexes

DGX Spark uses NVIDIA ConnectX-7 HCAs configured in RoCE mode (link layer: Ethernet):

- **HCAs**: `rocep1s0f0`, `roceP2p1s0f0`
- **GID Index**:
  - **`spark01` (Head)**: IPv4 GID is index **`2,2`**
  - **`spark02` (Worker)**: IPv4 GID is index **`4,4`**
  *(Matches the proven DeepSeek variant03 NCCL configuration)*

---

## 3. Environment Variable Contracts

### Head Node (`head/.env` on `spark01`)
```bash
MASTER_ADDR="10.0.1.1"
MASTER_PORT="25000"
VLLM_HOST_IP="10.0.1.1"

NCCL_NET="IB"
NCCL_IB_DISABLE="0"
NCCL_IB_HCA="rocep1s0f0,roceP2p1s0f0"
NCCL_IB_GID_INDEX="2,2"
NCCL_SOCKET_IFNAME="enP7s7"
GLOO_SOCKET_IFNAME="enP7s7"
TP_SOCKET_IFNAME="enP7s7"
NCCL_CROSS_NIC="1"
NCCL_IGNORE_CPU_AFFINITY="1"
NCCL_DEBUG="WARN"
```

### Worker Node (`worker/.env` on `spark02`)
```bash
MASTER_ADDR="10.0.1.1"
MASTER_PORT="25000"
VLLM_HOST_IP="10.0.1.2"

NCCL_NET="IB"
NCCL_IB_DISABLE="0"
NCCL_IB_HCA="rocep1s0f0,roceP2p1s0f0"
NCCL_IB_GID_INDEX="4,4"
NCCL_SOCKET_IFNAME="enP7s7"
GLOO_SOCKET_IFNAME="enP7s7"
TP_SOCKET_IFNAME="enP7s7"
NCCL_CROSS_NIC="1"
NCCL_IGNORE_CPU_AFFINITY="1"
NCCL_DEBUG="WARN"
```

---

## 4. Port Allocations

- **Port 8000**: vLLM OpenAI-compatible API server (on `spark01`).
- **Port 25000**: PyTorch c10d / torch.distributed rendezvous coordination.
- **Port 11435**: Open WebUI upstream target (reverse-proxied via Nginx).
