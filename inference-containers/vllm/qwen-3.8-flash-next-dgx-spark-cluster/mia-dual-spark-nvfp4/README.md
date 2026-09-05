# Qwen 3.8 Flash Next on Dual DGX Spark Cluster (Mia NVFP4)

Multi-node inference preset for **Qwen 3.8 Flash Next** across 2x DGX Spark nodes (NVIDIA GB10, 256 GiB combined unified LPDDR5X memory) using vLLM with **TP=2 + EP=true + MTP=3**.

---

## 1. Credit & Attribution

This cluster preset is based on the multi-node research, kernel patches, and configurations developed by **Mia AI Lab**:
- Repository: [MiaAI-Lab/Qwen3.8-Flash-Next-Dual-DGX-Sparks](https://github.com/MiaAI-Lab/Qwen3.8-Flash-Next-Dual-DGX-Sparks)
- Follow Mia on X: [@MiaAI_lab](https://x.com/MiaAI_lab)
- GitHub Sponsors: [sponsors/MiaAI-Lab](https://github.com/sponsors/MiaAI-Lab)

Key breakthroughs contributed by Mia AI Lab incorporated here:
1. **MXFP8 Emulation Fallback**: Routes non-compliant MXFP8 GEMM shapes (`linear_attn.in_proj_a/b` and vision MLP `fc1`) to BF16 emulation, avoiding fatal engine aborts on FlashInfer.
2. **`FP8_BLOCK_SCALES` MoE Routing**: Adds the missing block-scaled FP8 expert dispatch for MTP speculative decoding in vLLM.
3. **QSA Sparse Attention FP8 KV**: Patches Triton QSA kernels to accept FP8 KV cache, boosting available cache tokens from 2.13M to 3.65M (~13.9× context at 262K).
4. **Checkpoint MTP Layer Aliasing**: Fixes `quantization_config` to recognize absolute MTP layer indexes (`mtp.layers.48.*`).

---

## 2. Hardware Environment & Sizing

| Metric | Single Spark (TP=1) | Dual Spark Cluster (TP=2) |
|---|---|---|
| **Hardware** | 1x DGX Spark (GB10) | 2x DGX Spark (`spark01` head + `spark02` worker) |
| **Nodes Specification** | Acer model (`spark01`) | Gigabyte model (`spark02`) + Acer model (`spark01`) |
| **Total Memory** | 128 GiB unified LPDDR5X | 256 GiB unified LPDDR5X |
| **Interconnect** | Local NVLink/PCIe | ConnectX-7 Dual-RoCE / InfiniBand (`10.0.1.0/24`) |
| **RoCE GID Index** | N/A | **`2,2` on `spark01` (Acer)** / **`4,4` on `spark02` (Gigabyte)** |
| **Speculative Decoding** | MTP=3 (CPU-offloaded PLE) | **MTP=3 (Native GPU memory, no offload bottleneck)** |
| **KV Cache Capacity** | ~16 GiB | **~32 GiB per node (3,652,200 cache tokens)** |
| **Native Context Headroom** | ~1×–2× @ 262K | **~13.9× concurrent sequences @ 262K** |

> [!NOTE]
> **Hardware GID Index Difference**: The PCIe network configuration differs between the two machines:
> - `spark01` (Acer chassis): ConnectX-7 RoCE IPv4 GIDs are at index **`2,2`**.
> - `spark02` (Gigabyte chassis): ConnectX-7 RoCE IPv4 GIDs are at index **`4,4`**.
> The respective `.env.example` files in `head/` and `worker/` have these correct GID presets pre-configured.

---

## 3. Educational Deep Dive: Understanding the Parallelism Architecture

To get the most out of a dual-Spark cluster, it is crucial to understand how model computations and memory are divided across the two physical machines.

### A. Pipeline Parallelism (PP) — What We Deliberately Avoid
* **The Concept**: Splitting the model *sequentially* by layers (e.g., in a 48-layer model, `spark01` holds Layers 1–24, and `spark02` holds Layers 25–48).
* **The "Pipeline Bubble" Problem**: During inference, `spark01` computes Layers 1–24 while `spark02` sits completely idle waiting for activations over the wire. Then, while `spark02` computes Layers 25–48, `spark01` sits idle waiting for the next pass.
* **Verdict**: Sequential dependency creates massive idle gaps ("bubbles"), cutting effective cluster compute utilization roughly in half.

### B. Tensor Parallelism (TP=2) — Slicing Every Layer Simultaneously
* **The Concept**: Instead of splitting layers sequentially, **every single layer is split mathematically across both GPUs**:
  * In **Layer 1**, `spark01` holds half the attention heads ($Q, K, V$) and `spark02` holds the other half.
  * Both GB10 chips compute their half of the matrix **at the exact same microsecond in parallel**.
  * At the end of each layer, an ultrafast NCCL `all-reduce` over your 200G ConnectX-7 link sums the outputs, and both GPUs immediately advance to Layer 2 together in lockstep.

### C. Expert Parallelism (EP=true) — Partitioning Whole MoE Experts
Qwen 3.8 Flash Next features an MoE architecture with **512 routed experts**.

* **Why not pure TP on MoE?** Slicing 512 tiny expert matrices into even smaller slivers harms GPU arithmetic intensity (the Tensor Cores finish in nanoseconds and spend all their time waiting on memory bandwidth).
* **The EP Solution**: Rather than slicing individual expert matrices, **the experts themselves are partitioned whole**:

```text
               Token Embeddings arrive at Layer Router
                                 │
           Router determines which expert each token activates
                                 │
              ┌──────────────────┴──────────────────┐
              ▼                                     ▼
     spark01 (Rank 0)                      spark02 (Rank 1)
     Holds Experts 0 to 255                Holds Experts 256 to 511
     (256 full experts in RAM)             (256 full experts in RAM)
```

* If a token activates **Expert 42**: it runs locally on `spark01` without network traffic.
* If a token activates **Expert 380**: vLLM dispatches the token embedding across the RoCE link to `spark02` via `allgather_reducescatter`, `spark02` executes the expert, and the output vectors are reduced back.

### Summary: Why This Architecture Kicks Ass
By combining **TP=2** (for attention & dense projections) with **EP=true** (for the 512 MoE experts) while **avoiding Pipeline Parallelism (PP=1)**:
1. **Zero Pipeline Bubbles**: Both GB10 chips are compute-active throughout 100% of every generation step.
2. **Maximum Hardware Utilization**: Matrix calculations run in parallel with high arithmetic intensity on Blackwell cores.
3. **Halved Memory Footprint**: The massive ~99 GiB weight footprint is split into ~50 GiB per Spark, freeing ~32 GiB on each node purely for FP8 KV cache (~3.65M tokens / ~13.9× context headroom).

---

## 4. Directory Layout

```text
mia-dual-spark-nvfp4/
├── agent-metadata/             # Architectural records, network contracts, and plans
│   ├── 01_cluster_architecture_and_strategy.md
│   ├── 02_network_and_fabric_contracts.md
│   └── 03_implementation_plan.md
├── files/                      # Overlay patches generated from base image
├── head/                       # Head node configuration (spark01)
│   ├── .env.example            # GID_INDEX="2,2", rank 0
│   ├── 01_up.sh
│   ├── 02_down.sh
│   ├── 03_enter_container.sh
│   ├── 04_check_nccl.sh
│   ├── 05_a_follow_logs.sh
│   ├── 05_b_dump_logs.sh
│   └── docker-compose.yml
├── worker/                     # Worker node configuration (spark02)
│   ├── .env.example            # GID_INDEX="4,4", rank 1 --headless
│   ├── 01_up.sh
│   ├── 02_down.sh
│   ├── 03_enter_container.sh
│   ├── 04_check_nccl.sh
│   ├── 05_a_follow_logs.sh
│   ├── 05_b_dump_logs.sh
│   └── docker-compose.yml
├── 00_a_prepare_patches.sh     # One-time patch extraction and generator
├── 00_b_pre_download_model.sh  # Pre-download weights to local HF cache
└── 04_test_vllm_curl.py        # Verification client
```

---

## 5. Operational Step-by-Step Guide

### Step A: Prerequisites on Both Nodes
1. Ensure the Docker image `vllm/vllm-openai:qwen38-flash-next` is present.
2. Ensure model weights `Mia-AiLab/Qwen3.8-Flash-Next-NVFP4` are downloaded in `~/.cache/huggingface/hub/` on **both** nodes:
   ```bash
   bash 00_b_pre_download_model.sh
   ```
3. Run the automated patch generator on **both** nodes:
   ```bash
   bash 00_a_prepare_patches.sh
   ```

---

### Step B: Stop Single-Spark Stack on `spark01` (if running)
If you previously ran the single-spark container or the bridge-mode WebUI/Nginx, stop them to free port 8000, 80/443, and ~90 GiB of unified GPU memory:

```bash
# 1. Stop single-spark inference container
cd inference-containers/vllm/qwen-3.8-flash-next-dgx-spark/mia-nvfp4 && ./02_down.sh

# 2. Stop bridge-mode WebUI and Nginx reverse proxy
cd ../../../open-webui/web-ui-devnetwork && ./02_down.sh
cd ../../nginx/nginx-vllm-reverse-proxy-dgx-spark && ./02_down.sh
```

---

### Step C: Launch Worker on `spark02` (Worker Node First)
In multi-node PyTorch/vLLM distributed execution, **always start the worker first**:

```bash
cd inference-containers/vllm/qwen-3.8-flash-next-dgx-spark-cluster/mia-dual-spark-nvfp4/worker
./01_up.sh
./05_a_follow_logs.sh
```
* The worker starts in `--headless` mode and actively waits/polls for the head node at `10.0.1.1:25000`.

---

### Step D: Launch Head on `spark01`
Once the worker is up and listening:

```bash
cd inference-containers/vllm/qwen-3.8-flash-next-dgx-spark-cluster/mia-dual-spark-nvfp4/head
./01_up.sh
./05_a_follow_logs.sh
```
* Head opens master port `25000` on `10.0.1.1`.
* The rendezvous socket immediately handshakes with the waiting worker on `spark02`.
* Model weights and MTP speculative layers load across both GPUs in ~5–6 minutes.
* You will see: `Application startup complete.` and `/health` returns `200 OK`.

---

### Step E: Launch Host-Mode WebUI & Nginx on `spark01`
In cluster mode, the model runs in host network mode (`network_mode: "host"`). Bring up the host-mode companion containers on `spark01`:

```bash
# 1. Open WebUI in host network mode (listens on :11435, connects to 127.0.0.1:8000)
cd inference-containers/open-webui/web-ui-hostnetwork && ./01_up.sh

# 2. Nginx reverse proxy in host mode (listens on :80/:443, routes to WebUI and vLLM)
cd inference-containers/nginx/nginx-vllm-reverse-proxy-dgx-spark-hostmode && ./01_up.sh
```

---

### Step F: End-to-End Verification
Test the cluster endpoint directly from `spark01`:

```bash
cd inference-containers/vllm/qwen-3.8-flash-next-dgx-spark-cluster/mia-dual-spark-nvfp4
python3 04_test_vllm_curl.py
```
This tests:
1. Model enumeration on `/v1/models`.
2. Reasoning chat completion with step-by-step reasoning tokens.
3. OpenAI-compatible tool calling (`get_weather`).
