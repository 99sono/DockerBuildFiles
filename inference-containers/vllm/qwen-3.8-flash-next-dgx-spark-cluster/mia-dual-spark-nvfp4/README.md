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

## 2. Cluster Architecture & Sizing

| Metric | Single Spark (TP=1) | Dual Spark Cluster (TP=2) |
|---|---|---|
| **Hardware** | 1x DGX Spark (GB10) | 2x DGX Spark (`spark01` head + `spark02` worker) |
| **Total Memory** | 128 GiB unified LPDDR5X | 256 GiB unified LPDDR5X |
| **Interconnect** | Local NVLink/PCIe | ConnectX-7 Dual-RoCE / InfiniBand (`10.0.1.0/24`) |
| **Speculative Decoding** | MTP=3 (CPU-offloaded PLE) | **MTP=3 (Native GPU memory, no offload bottleneck)** |
| **KV Cache Capacity** | ~16 GiB | **~32 GiB per node (3,652,200 cache tokens)** |
| **Native Context Headroom** | ~1×–2× @ 262K | **~13.9× concurrent sequences @ 262K** |

---

## 3. Directory Layout

```text
mia-dual-spark-nvfp4/
├── agent-metadata/             # Architectural records, network contracts, and plans
│   ├── 01_cluster_architecture_and_strategy.md
│   ├── 02_network_and_fabric_contracts.md
│   └── 03_implementation_plan.md
├── files/                      # Overlay patches generated from base image
├── head/                       # Head node configuration (spark01)
│   ├── .env.example
│   ├── 01_up.sh
│   ├── 02_down.sh
│   ├── 03_enter_container.sh
│   ├── 04_check_nccl.sh
│   ├── 05_a_follow_logs.sh
│   ├── 05_b_dump_logs.sh
│   └── docker-compose.yml
├── worker/                     # Worker node configuration (spark02)
│   ├── .env.example
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

## 4. How to Launch

### Step 1: Pre-requisites on Both Nodes
Ensure the Docker image `vllm/vllm-openai:qwen38-flash-next` and weights `Mia-AiLab/Qwen3.8-Flash-Next-NVFP4` are present in `~/.cache/huggingface/hub/` on both `spark01` and `spark02`.

Run patch preparation on each machine:
```bash
bash 00_a_prepare_patches.sh
```

### Step 2: Start the Cluster
1. **Start Head Node on `spark01`**:
   ```bash
   cd head
   ./01_up.sh
   ./05_a_follow_logs.sh
   ```
2. **Start Worker Node on `spark02`**:
   ```bash
   cd worker
   ./01_up.sh
   ./05_a_follow_logs.sh
   ```

### Step 3: Verify the Cluster
Once both nodes report initialized and `spark01` returns `200 OK` on `/health`:
```bash
python3 04_test_vllm_curl.py
```
