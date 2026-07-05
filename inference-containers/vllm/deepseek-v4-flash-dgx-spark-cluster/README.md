# DeepSeek-V4-Flash — Dual DGX Spark Cluster

Adaptation of [tonyd2wild](https://github.com/tonyd2wild)'s recipes for a local cluster of **ACER Veriton** (head/spark01) + **Gigabyte Top AI** (worker/spark02), both DGX Spark (GB10) class, connected via dual-port 200G RoCE.

All credit goes upstream:
- **variant02 (DSpark NVFP4)** — [DeepSeek-v4-Flash-DSpark-1M-NVFP4-KV-2x-DGX-Spark](https://github.com/tonyd2wild/DeepSeek-v4-Flash-DSpark-1M-NVFP4-KV-2x-DGX-Spark)
- **variant01 (MTP fp8)** — [deepseek-v4-flash-dual-spark-recipe](https://github.com/tonyd2wild/deepseek-v4-flash-dual-spark-recipe)

Multi-node vLLM inference serving **DeepSeek-V4-Flash** across two nodes with tensor parallelism (TP=2), dual-port 200G RoCE interconnect.

## Quick Start

Each variant lives in its own subfolder under this directory. Choose one:

### variant01 (MTP fp8 — original recipe)

On **spark01 (head):**
```bash
cd variant01-tony2wild-original
# 1. Set up head config:
cp head/.env.example head/.env   # edit NCCL_IB_GID_INDEX and IPs
# 2. Pull image:
./00_a_pull_image.sh
# 3. Download model:
./00_b_create_conda_env.sh && ./00_c_install_packages.sh && ./00_d_pre_download_model.sh
# 4. Start head:
head/01_up.sh
```

On **spark02 (worker):**
```bash
cd variant01-tony2wild-original
# 1. Set up worker config (different GID!):
cp worker/.env.example worker/.env   # edit NCCL_IB_GID_INDEX and IPs
# 2. Pull image:
./00_a_pull_image.sh
# 3. Start worker (after head is ready):
worker/01_up.sh
```

### variant02 (DSpark NVFP4 — 1M context)

On **spark01 (head):**
```bash
cd variant02-dspark-nvfp4
# 1. Set up head config:
cp head/.env.example head/.env   # edit NCCL_IB_GID_INDEX and IPs
# 2. Build Docker image (4-stage: overlay + NVFP4 A/B/C):
./00_pull_base_image.sh
WORKER_BUILD=0 ./00_a_build_dspark_image.sh
# 3. Download model:
./00_b_create_conda_env.sh && ./00_c_install_packages.sh && ./00_d_pre_download_model.sh
# 4. Start head:
head/01_up.sh
```

On **spark02 (worker):**
```bash
cd variant02-dspark-nvfp4
# 1. Set up worker config (different GID!):
cp worker/.env.example worker/.env   # edit NCCL_IB_GID_INDEX and IPs
# 2. Build image:
./00_pull_base_image.sh
WORKER_BUILD=0 ./00_a_build_dspark_image.sh
# 3. Sync model cache from head (avoid downloading 40GB twice):
rsync -ahvP --delete "your_user@10.0.1.1:$HOME/.cache/huggingface/hub/" "$HOME/.cache/huggingface/hub/"
# 4. Start worker (after head is ready):
worker/01_up.sh
```

The build produces the image `vllm-dspark-runtime:dspark-nvfp4-stage-c` — a 22.7GB runtime with the DSpark speculative decoding overlay and NVFP4 KV cache path patched in.

## Architecture

```
spark01 (HEAD, rank 0)           spark02 (WORKER, rank 1)
┌──────────────────────────┐    ┌──────────────────────────┐
│ deepseek-v4-flash-head   │    │ deepseek-v4-flash-worker │
│                          │    │                          │
│ Serves API on :8000      │    │ Headless (no API)        │
│                          │    │                          │
│  ┌──────────────────┐    │    │  ┌──────────────────┐    │
│  │ vLLM rank 0      │    │    │  │ vLLM rank 1      │    │
│  │ (TP half)        │◄──┼────┼──┤ (TP half)         │    │
│  └──────────────────┘    │NCCL│  └──────────────────┘    │
│         ▲                │RDEV│                          │
│         │ GLOO (TCP)     │    │                          │
│   192.168.1.55 ◄─────────┼────┼──► 192.168.1.56          │
│                          │    │                          │
│ Clients → :8000          │    │                          │
└──────────────────────────┘    └──────────────────────────┘
```

- **NCCL data plane** (GPU→GPU communication) — travels over both ConnectX-7 cables at 10.0.1.x + 10.0.2.x (dual-port, 400 Gb/s aggregate)
- **GLOO control plane** (TCP bootstrap/rendezvous) — travels over regular ethernet at 192.168.1.x
- Only the **head** node exposes the API on port 8000; the worker is headless

## Prerequisites

### Hardware
- 2× DGX Spark (GB10), both with the same firmware/driver/kernel version
- Both ConnectX-7 cables connected (Port 1 + Port 2 on each node)
- ConnectX-7 ports configured with static IPs (see [Networking Setup](#networking-setup))

### Software
- Docker + NVIDIA Container Toolkit on both nodes
- The Docker image pre-pulled on both nodes

## Networking Setup

### IP Scheme

| Interface | spark01 (head) | spark02 (worker) | Purpose |
|-----------|---------------|-----------------|---------|
| `enP7s7` (Realtek) | `192.168.1.55` | `192.168.1.56` | Management, SSH, GLOO control plane |
| `enp1s0f0np0` (CX7 Port 1) | `10.0.1.1/24` | `10.0.1.2/24` | NCCL data (Cable 1) |
| `enP2p1s0f0np0` (CX7 Port 2) | `10.0.2.1/24` | `10.0.2.2/24` | NCCL data (Cable 2) |

### Dual-Port Bandwidth

Both ConnectX-7 ports are used for NCCL communication. NCCL automatically stripes traffic across all available HCAs, giving ~400 Gb/s aggregate bandwidth between the two nodes.

The Docker image and vLLM are pre-built with SM121 (GB10 Blackwell) architecture support and include the DeepSeek-V4 specific sparse MLA kernels.

### NVIDIA Host Networking

This setup uses **host networking** (`--network host`) because:

1. The container needs direct access to the RoCE fabric (no docker routing)
2. `/dev/infiniband` devices must be visible inside the container for RDMA
3. `--privileged` + `--ulimit memlock=-1` is required for `ibv_reg_mr` (memory pinning)

This is different from the single-node containers in this repo (which use docker bridge networking + nginx reverse proxy). For multi-node GPU communication over RDMA, host networking is the standard approach.

### RDMA / NCCL Configuration

```
NCCL_IB_HCA=rocep1s0f0,roceP2p1s0f0   # Both RoCE HCAs (dual-port)
NCCL_IB_GID_INDEX=4,4                  # GID index for each HCA
NCCL_SOCKET_IFNAME=enP7s7             # TCP control plane (regular ethernet)
GLOO_SOCKET_IFNAME=enP7s7
TP_SOCKET_IFNAME=enP7s7
```

---

### ⚠️ The GID Index Pitfall (Critical)

This is the most common cause of NCCL failures in a dual-Spark setup.

#### What is a GID?

A **GID** (Global Identifier) is the RDMA equivalent of an IP address. On a RoCE
(RDMA over Converged Ethernet) link, every IP assigned to the network interface
is registered in a **GID table** — a small lookup table (8 entries, index 0–7)
that maps an index number to an IPv4 or IPv6 address.

When NCCL wants to establish a QP (Queue Pair) connection between two nodes, it
needs to tell the InfiniBand hardware: *"use GID index X to reach the remote
node"*. If the wrong index is configured, NCCL reads an empty or wrong GID, the
QP transition fails, and the cluster handshake crashes.

#### How GIDs relate to IPv4

Each ConnectX-7 port has its own GID table. An IPv4 address like `10.0.1.1`
appears in the table as a **mapped IPv4 GID** — the format is
`0000:0000:0000:0000:0000:ffff:0a00:0101` where the last 4 bytes are the hex
encoding of the IP (`0a` = 10, `00` = 0, `01` = 1, `01` = 1).

The index at which this entry appears is **not deterministic** — it depends on
the order in which IPs were assigned and how the kernel registered link-local
IPv6 addresses at boot. Two identical DGX Sparks can have their IPv4 GID at
different indices.

For example, on our two nodes:

| Node | Port | IPv4 | GID index (this node) |
|------|------|------|----------------------|
| spark01 (head) | `rocep1s0f0` | 10.0.1.1 | **2** |
| spark01 (head) | `roceP2p1s0f0` | 10.0.2.1 | **2** |
| spark02 (worker) | `rocep1s0f0` | 10.0.1.2 | **4** |
| spark02 (worker) | `roceP2p1s0f0` | 10.0.2.2 | **4** |

The same IP scheme, but the head's GID lands at index 2 and the worker's at
index 4. Using a shared `.env` with `NCCL_IB_GID_INDEX="4,4"` on both nodes
would be **correct for the worker but broken for the head**.

#### Reading a GID Table (Intuition)

When you dump a GID table, you see lines like this:

```
rocep1s0f0  GID 0: fe80:0000:0000:0000:4a21:0bff:fe96:8ddd
rocep1s0f0  GID 1: fe80:0000:0000:0000:4a21:0bff:fe96:8ddd
rocep1s0f0  GID 2: 0000:0000:0000:0000:0000:ffff:0a00:0101
rocep1s0f0  GID 3: 0000:0000:0000:0000:0000:ffff:0a00:0101
rocep1s0f0  GID 4: 0000:0000:0000:0000:0000:0000:0000:0000
rocep1s0f0  GID 5: 0000:0000:0000:0000:0000:0000:0000:0000
rocep1s0f0  GID 6: 0000:0000:0000:0000:0000:0000:0000:0000
rocep1s0f0  GID 7: 0000:0000:0000:0000:0000:0000:0000:0000
```

There are only **three types** of entries. Train your eye:

| Prefix | Meaning | Action |
|--------|---------|--------|
| `fe80:*` | Link-local IPv6 (auto-generated from MAC) | **Ignore** — works only on the same wire, not cross-node |
| `0000:*:ffff:*` | **Mapped IPv4** ← our RoCE IPs | **This is what we need** |
| `0000:*:0000` | Empty slot | Ignore |

The IPv4 address is hex-encoded in the last 4 byte-pairs. For `10.0.1.1`:

```
0a  00  01  01
10   0   1   1   →  10.0.1.1
```

And for `10.0.2.2`:

```
0a  00  02  02
10   0   2   2   →  10.0.2.2
```

**The trick:** Scroll down the table looking for the *first* non-`fe80`, non-empty
line. That's your GID index. Ignore `fe80:` lines entirely — they're just noise.

In the head's table above, indices 0-1 are `fe80:` noise, index 2 is the first
IPv4 entry. In the worker's table, there are more `fe80:` entries (4 per port),
so the first IPv4 lands at index 4 instead.

**Why the difference?** The worker happened to register extra link-local IPv6
addresses before the IPv4 was added (different boot order or IP assignment
sequence). Perfectly normal. The two nodes don't need to agree on the index —
they just need each to use *their own* correct index.

Also note: each IPv4 appears **twice** (e.g., indices 2 and 3, or 4 and 5).
This duplication is normal — NCCL can use either. Always use the first one.

#### How to find the right GID index

**Method 1 — Automated (recommended):** Run the diagnostic script on each node:

```bash
./04_check_nccl.sh
```

This scans GID indices 0–7 on both HCAs, finds the first IPv4 entry
(containing `ffff:0a00:xxxx`), reports the detected index, and warns if your
`.env` has a different value.

**Method 2 — Manual:**

```bash
for i in $(seq 0 7); do
  echo -n "rocep1s0f0  GID $i: "
  cat /sys/class/infiniband/rocep1s0f0/ports/1/gids/$i
done
```

Look for a line containing `ffff:0a00:xxxx` — that index is your
`NCCL_IB_GID_INDEX` value for that port. Repeat for `roceP2p1s0f0`.
Both ports on the same node almost always use the same index.

#### Setting the value

`NCCL_IB_GID_INDEX` takes one index per HCA, comma-separated:

| Syntax | Meaning |
|--------|---------|
| `"2,2"` | Both ports use GID index 2 (head) |
| `"4,4"` | Both ports use GID index 4 (worker) |

**The two nodes must use different values if their GID tables differ.**
The `.env` files are per-node and cannot be blindly identical.

Use the per-node `.env.example` templates:
- `head/.env.example` — pre-configured with index `2,2`
- `worker/.env.example` — pre-configured with index `4,4`

Copy the relevant one to `.env` on each node:

```bash
# On spark01:
cp head/.env.example head/.env

# On spark02:
cp worker/.env.example worker/.env
```

> **If you see** `ibv_modify_qp failed with 22 Invalid argument` and
> `remote GID ::` or `local GID ::` in the container logs, your
> `NCCL_IB_GID_INDEX` is wrong on at least one node.

## Usage

### Step 0: Configure .env

Copy `.env.example` to `.env` and edit for your setup:

```bash
cp .env.example .env
```

Key settings:
- `MASTER_ADDR` — spark01's Port 1 IP (`10.0.1.1`)
- `NCCL_IB_HCA` and `NCCL_IB_GID_INDEX` — confirm and adjust if needed
- `INFERENCE_API_KEY` — set a real API key

### Step 1: Pull the Docker image (both nodes)

```bash
./00_pull_image.sh
```

### Step 2: Pre-download model weights (both nodes)

The container uses the host's HuggingFace cache. Pre-download the model so both nodes have it local:

```bash
docker run --rm -v ~/.cache/huggingface:/cache/huggingface \
  -e HF_HOME=/cache/huggingface \
  aidendle94/sparkrun-vllm-ds4-gb10:production-ready \
  bash -c "huggingface-cli download deepseek-ai/DeepSeek-V4-Flash --local-dir /cache/huggingface/hub/models--deepseek-ai--DeepSeek-V4-Flash"
```

> This saves ~6-7 minutes of download time at cold start. The model is ~150 GB so ensure at least 200 GB free disk on each node.

### Step 3: Start the WORKER first (spark02)

```bash
cd worker
./01_up.sh
```

Wait a few seconds for the container to initialize.

### Step 4: Start the HEAD (spark01)

```bash
cd head
./01_up.sh
```

### Step 5: Wait for model loading

Monitor the head node logs:

```bash
cd head
./05_docker_logs.sh
```

Wait until you see: `"Application startup complete"` (typically ~6-7 minutes).

### Step 6: Test the API

From any machine that can reach spark01:

```bash
curl http://192.168.1.55:8000/v1/models
```

Or use the test script (runs from the repo root):

```bash
INFERENCE_SERVER_URL=http://192.168.1.55:8000/v1 ./04_test_vllm_curl.py
```

### Step 7: Shutdown

On each node:

```bash
# On spark01:
cd head && ./02_down.sh

# On spark02:
cd worker && ./02_down.sh
```

## Startup Order

Always start **worker first, then head**. The head coordinates the NCCL rendezvous and the API server; if it comes up before the worker is listening, the multi-node handshake can stall.

## Important Notes

| Topic | Detail |
|-------|--------|
| **Direct HTTP** | This setup does NOT use the nginx reverse proxy. Access the head node directly on port 8000 over HTTP. |
| **Host networking** | The container shares the host's network stack. Only one container can bind port 8000 at a time. |
| **First request timeout** | The very first request after cold start may time out (torch.compile + cudagraph warmup). Just retry — the warm path is instant. |
| **Model alias** | The model is served under three names: `deepseek-v4-flash`, `deepseek-v4-flash-spark`, and `stepfun-ai/Step-3.7-Flash-NVFP4`. Clients can use any of them. |
| **Disk space** | Docker image is ~36 GB, model weights are ~150 GB. Ensure ~200 GB free on each node. |

## Troubleshooting

### NCCL fails with "unhandled system error" / "Cannot allocate memory"
The container needs `--privileged` + `--ulimit memlock=-1`. Check the container was started with these flags.

### Cluster handshake hangs
Run the diagnostic script on both nodes:
```bash
./04_check_nccl.sh
```

Or manually:
- Verify both RoCE ports show LinkUp: `cat /sys/class/infiniband/*/ports/1/state`
- Verify you can ping both RoCE IPs between nodes: `ping 10.0.1.2` from spark01
- Check GID indices: `for i in 0 1 2 3 4 5 6 7; do cat /sys/class/infiniband/rocep1s0f0/ports/1/gids/$i; done`

### NCCL "ibv_modify_qp failed" / GID mismatch
If NCCL fails with `Call to ibv_modify_qp failed` and `remote GID ::` or
`local GID ::`, the `NCCL_IB_GID_INDEX` is wrong for that node.
Run `./04_check_nccl.sh` — it auto-detects the correct index and warns on
mismatch. The GID index often differs between head and worker.

**On our setup:**
- Head (spark01): `NCCL_IB_GID_INDEX="2,2"`
- Worker (spark02): `NCCL_IB_GID_INDEX="4,4"`

### Slow performance
- Match firmware/driver/kernel versions on both nodes — the recipe's author saw **+140% prefill** from this alone
- Verify both ConnectX-7 cables are active at 200 Gb/s

## Variants

| Variant | Spec | KV Cache | Context | Image |
|---------|------|----------|---------|-------|
| `variant01-tony2wild-original` | MTP (2 tokens, greedy) | fp8 | 200K | `aidendle94/sparkrun-vllm-ds4-gb10:production-ready` |
| `variant02-dspark-nvfp4` | DSpark (3 tokens, probabilistic) | `nvfp4_ds_mla` | 1M+ | `vllm-dspark-runtime:dspark-nvfp4-stage-c` (local build) |

## Credits

- **variant01** — based on the [tonyd2wild/deepseek-v4-flash-dgx-spark](https://github.com/tonyd2wild/deepseek-v4-flash-dgx-spark) recipe and the `aidendle94/sparkrun-vllm-ds4-gb10` Docker image.
- **variant02** — based on the [tonyd2wild/DeepSeek-v4-Flash-DSpark-1M-NVFP4-KV-2x-DGX-Spark](https://github.com/tonyd2wild/DeepSeek-v4-Flash-DSpark-1M-NVFP4-KV-2x-DGX-Spark) recipe with the DSpark speculative decoding overlay, NVFP4 KV cache path, and Keys' concurrency patch.
