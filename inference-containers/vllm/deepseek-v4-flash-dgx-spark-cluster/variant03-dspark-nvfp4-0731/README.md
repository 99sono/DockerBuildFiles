# Variant03 — DeepSeek-V4-Flash-0731 (official) DSpark NVFP4 — 2x DGX Spark

> **What this folder is:** a runner for the upstream recipe
> [tonyd2wild/DeepSeek-v4-Flash-DSpark-1M-NVFP4-KV-2x-DGX-Spark](https://github.com/tonyd2wild/DeepSeek-v4-Flash-DSpark-1M-NVFP4-KV-2x-DGX-Spark),
> following this repo's conventions (numbered `NN_*.sh` scripts, per-node
> `docker-compose.yml`, `.env`/`.env.example` split). Its only job is to help run the
> DeepSeek-V4-Flash DSpark recipe on this hardware.
>
> **The stock vLLM base image is NOT used directly.** DeepSeek-V4-Flash needs
> DSpark-specific patches (speculative draft module, NVFP4 KV dtype, B12X MoE backend)
> that only exist in the upstream recipe. Those recipe files are **vendored here under
> `recipe/`** (a pinned snapshot of the upstream repo — see `recipe/README.md`), and the
> runtime image is **built from them**: base image → 4-stage `docker build` →
> `vllm-dspark-runtime:dspark-nvfp4-stage-c-0731` (the `00_*` scripts, below).

Serves **`deepseek-ai/DeepSeek-V4-Flash-0731`** — DeepSeek's **official** release
(2026-07-31, MIT) — across the two-node DGX Spark cluster (spark01 head + spark02
worker, TP=2, dual-port 200G RoCE). This variant upgrades the DSpark preview
checkpoint from [variant02](../variant02-dspark-nvfp4) to the official release.

**Why a new variant:** variant02 is a deployed, documented known-good preview config
and stays frozen. The 0731 change is a real recipe change — new overlay files, Patch 4,
new profile — so it gets its own folder and its own image tag.

## The 0731 model in 30 seconds

- **Official DeepSeek release** superseding the preview; same model structure as the
  DSpark preview (speculative draft module attached, `dspark_block_size=5`).
- **Already pre-quantized on disk — no separate NVFP4 download needed:**
  `config.json` says `expert_dtype: "fp4"` (MoE experts are FP4) +
  `quantization_config: { quant_method: fp8, fmt: e4m3 }` (everything else FP8).
  Download ≈ **167 GB** for 304B params (not ~600 GB BF16).
- **"NVFP4" in the recipe = the KV cache dtype**, not the weights:
  `--kv-cache-dtype nvfp4_ds_mla` (4-bit KV) + the B12X MoE backend consuming FP4
  experts. Both live in the runtime image, not in the checkpoint.
- **Fits 2×128 GB** because it is already quantized: ~152 GB weights split TP=2
  (~76 GB/node) + 4-bit KV pool (measured 1.55M tokens at `gpu_memory_utilization=0.78`).
- Upstream-measured on 2x DGX Spark, TP=2, k=5, 1M ctx: **55.4 tok/s mean / 66.1 peak**
  (78.4 peak-finder), **without** Patch 4 it runs at roughly **half speed**.

## ⚠️ The critical 0731 change: Patch 4 (baked into the overlay)

vLLM's stock DSpark draft loader silently drops **12 tensors**:

```
model.layers.{43,44,45}.ffn.shared_experts.gate_up_proj.{weight,weight_scale_inv}
```

The draft's always-on shared expert (`n_shared_experts: 1`) then runs
**uninitialised**. Output stays correct (the target verifies every token) but
acceptance collapses. Measured:

| | accept | mean tok/s | peak tok/s |
|---|---|---|---|
| 0731, stock loader | 25.7% | 32.7 | 42.0 |
| **0731, Patch 4** | **60.2%** | **55.4** | **66.1** |

Patch 4 is **baked into the overlay** at `recipe/overlay/vllm/v1/spec_decode/dspark.py`
(`shared_experts.gate_up_proj` → `.shared_experts.w1`/`.w3`). No bind-mount needed —
it ships in the image. Verify before trusting any benchmark:

```bash
grep -n shared_experts.gate_up_proj recipe/overlay/vllm/v1/spec_decode/dspark.py
```

## Big differences vs variant02

| # | Area | variant02 (preview) | variant03 (0731 official) | Why |
|---|---|---|---|---|
| 1 | Model | `deepseek-ai/DeepSeek-V4-Flash-DSpark` | `deepseek-ai/DeepSeek-V4-Flash-0731` | official release |
| 2 | **Patch 4** | not needed | **baked into overlay** | shared-expert loader fix = 0731 speedup |
| 3 | Overlay files | old set | + `common/ops/cache_utils.py` (623 lines), + `tool_parsers/deepseekv32_tool_parser.py` (streaming tool-call fix), updated `nvidia/dspark.py` (slot clamp), `nvidia/sm120.py` (KV bounds) | upstream repo refreshed 2026-07-31 |
| 4 | `MTP_NUM_TOKENS` (k) | 3 | **5** | k=3 costs ~24% decode; k≤5 is locked on this runtime |
| 5 | Profile | 12 slots / gmu 0.85 | **6 slots / gmu 0.78** | 12/0.85 is the documented issue-#8 first-request OOM trigger on 0731 |
| 6 | `--max-cudagraph-capture-size` | set from `MAX_NUM_SEQS` | **removed** | vLLM derives it from max_num_seqs×(k+1); a stale literal truncates capture |
| 7 | New env | — | `DSPARK_SLOT_CLAMP=1`, `VLLM_ENGINE_READY_TIMEOUT_S=3600` | long-context slot-id clamp fix; warm-restart stability |
| 8 | Image tag | `vllm-dspark-runtime:dspark-nvfp4-stage-c` | `vllm-dspark-runtime:dspark-nvfp4-stage-c-0731` | distinct, coexist with variant02 |
| 9 | Alias | `deepseek-v4-flash-dspark` | `deepseek-v4-flash-0731` | served name |

**Unchanged:** same base image (`ghcr.io/bjk110/vllm-spark:unholy-fusion-prod-ready`),
`nvfp4_ds_mla` KV, B12X MoE/WO-projection flags, NCCL/RoCE config, 1M context ceiling,
one model per container on internal port 8000.

## Image build (the flow you asked about)

Yes: **pull the base image, then a 4-stage `docker build` patches it into the new image.**

```bash
# 1. Pull the immutable base runtime (22.7 GB):
./00_pull_base_image.sh
#    -> ghcr.io/bjk110/vllm-spark:unholy-fusion-prod-ready
#       (vLLM 0.21.1rc1.dev339+g1967a5627bc3 + B12X kernels, digest-pinned upstream)

# 2. Build the 4-stage image:
#    on this node only:
./00_a_build_head_dspark_image.sh
#    or, from the head, one-shot build here + worker (needs WORKER_HOST in .env):
./00_b_build_worker_dspark_image.sh
```

| Stage | Dockerfile | Output tag | What it does |
|---|---|---|---|
| 1 | `recipe/Dockerfile.dspark-runtime-overlay` | `vllm-dspark-runtime:mia-raf-pr1-0731` | copies overlay (Patch 3+4, B12X, tool parser, envs) + py_compile + import checks |
| 2 | `recipe/nvfp4/Dockerfile.stage-a` | `...-nvfp4-a` | NVFP4 dtype plumbing |
| 3 | `recipe/nvfp4/Dockerfile.stage-b` | `...-nvfp4-b` | NVFP4 probe path |
| 4 | `recipe/nvfp4/Dockerfile.stage-c` | **`vllm-dspark-runtime:dspark-nvfp4-stage-c-0731`** | padded envelope — the final image |

Both wrappers call the shared engine `00_build_dspark_image.sh` — the head wrapper sets
`WORKER_BUILD=0` (local only), the worker wrapper sets `WORKER_BUILD=1` (local + rsync to
`WORKER_HOST`). A sanity gate inside the engine fails fast if Patch 4 is missing from the
overlay.

## Quick start

```bash
# Per node — node-specific runtime env (committed templates, .env is gitignored):
cd head   && cp .env.example .env    # spark01 — GID 2,2, VLLM_HOST_IP 10.0.1.1
cd ../worker && cp .env.example .env # spark02 — GID 4,4, VLLM_HOST_IP 10.0.1.2
cp .env.example .env                 # variant root: build-script config (WORKER_HOST, image tag)

# 1. Pull base + build image (both nodes):
docker pull ghcr.io/bjk110/vllm-spark:unholy-fusion-prod-ready   # 22.7 GB base (skip if present)
./00_a_build_head_dspark_image.sh

# 2. Get the model (~167 GB) on BOTH nodes:
./00_d_pre_download_model.sh                       # on each node
#   or download once and rsync to the other node:
rsync -av --partial --inplace --progress \
  ~/.cache/huggingface/hub/models--deepseek-ai--DeepSeek-V4-Flash-0731/ \
  sono99@10.0.1.1:~/.cache/huggingface/hub/models--deepseek-ai--DeepSeek-V4-Flash-0731/

# 3. Worker first, then head:
worker/01_up.sh    # spark02
head/01_up.sh      # spark01

# 4. Wait for "Application startup complete" (~5-6 min), then:
./04_test_vllm_curl.py
#    INFERENCE_SERVER_URL=http://10.0.1.1:8000/v1 ./04_test_vllm_curl.py
```

## Serving stack (how it's actually served)

This model is not meant to be consumed by hitting `:8000` directly. On the head node
(spark01) it is served through a **three-container stack**: the vLLM inference
container built by this variant, an **nginx HTTPS reverse proxy**, and **Open WebUI**
behind it.

```
$ docker ps   (spark01, full stack up)
CONTAINER ID   IMAGE                                           NAMES
fbaf469b4edb   vllm-dspark-runtime:dspark-nvfp4-stage-c-0731   deepseek-v4-flash-0731-head
602758eac2b9   nginx:latest                                    nginx-proxy-hostmode
538b8ae81ea2   ghcr.io/open-webui/open-webui:latest            open-webui-host
```

| Container | Role | Networking |
|---|---|---|
| `deepseek-v4-flash-0731-head` | The model (this variant). Serves the OpenAI API on `:8000`. | host mode (RDMA fabric) |
| `nginx-proxy-hostmode` | HTTPS (443) reverse proxy. Splits traffic: `/inference/…` → the model, `/` → Open WebUI. | bridge (`development-network`) |
| `open-webui-host` | Chat UI, behind the proxy. Reached by nginx at `web-ui-server:8080`. | shared `development-network` |

Routing (from the nginx `nginx.conf`):

- `https://<host>/inference/v1/chat/completions` → `/inference` prefix stripped →
  `http://inference-server:8000/v1/chat/completions` (the model). `inference-server`
  resolves via `extra_hosts` to the node's management IP (`DGX_IP`) — the model runs
  host-mode on the RDMA fabric, so it's not reachable by Docker DNS.
- `https://<host>/` → `http://web-ui-server:8080` (Open WebUI), with the WebSocket
  `Upgrade` passthrough needed for real-time streaming.
- `https://<host>/invocations` → 403 (vulnerable endpoint, deliberately blocked).

So end users point a browser at `https://<host>/` for the chat UI, and API clients hit
`https://<host>/inference/v1/…`. The model's `:8000` stays internal to the cluster.

Bring up the proxy and UI **after** the model is serving:

```bash
# nginx — see ../../../nginx/nginx-vllm-reverse-proxy-dgx-spark-hostmode/
cp .env.example .env          # set DGX_IP to this node's management IP
./00_b_copy_certs_from_original.sh
./00_a_pull_nginx_image.sh
./01_up.sh

# Open WebUI — see ../../../open-webui/ (must be reachable as web-ui-server:8080
# on the shared development-network)
```

## Configuration notes (read these)

- **k is locked at ≤5** on this runtime. The draft model emits exactly
  `dspark_block_size=5` tokens per pass; `k=7` (DeepSeek's model-card recommendation)
  **crashes on the first generation** (`size of tensor a (7) must match tensor b (5)`).
  `MTP_NUM_TOKENS=5` is the verified default.
- **Do not** enable `VLLM_USE_V2_MODEL_RUNNER=1` (hard reject with DSpark spec-decode)
  or pass `--attention-backend FLASHINFER_MLA_SPARSE_DSV4` (backend doesn't exist on
  this image — leave attention on AUTO).
- **No** `--override-generation-config` / `repetition_penalty` (documented DSpark
  spec-decode crash: illegal memory access). Keep `--generation-config vllm`.
- **JIT/compile caches must be node-local** (never on shared NFS inside the HF cache) —
  sharing them causes serial torch.compile races, DeepGEMM `runtime != nullptr`, and
  ABI-mismatched FlashInfer `sampling.so`. The compose keeps `VLLM_CACHE_ROOT` inside
  the node-local HF cache mount; if you move the HF cache to NFS, remap all seven JIT
  vars to local disk.
- **Do not** serve a second model on the same port/host — host networking, one container
  per port. variant02 and variant03 cannot run simultaneously on the same node.
- `HF_HUB_OFFLINE=1` in compose — weights must be pre-downloaded.

## Model cache / disk

- Model: `deepseek-ai/DeepSeek-V4-Flash-0731`, ~167 GB per node, MIT license.
- Cache layout: `~/.cache/huggingface/hub/models--deepseek-ai--DeepSeek-V4-Flash-0731/`
  (snapshot `7872f01b1d1fe23eabc4c98b48bffcef5a386062` as of 2026-08-19).
- Disk: ~3.0 T free on `/` — both variants' caches fit comfortably.

## Verification / smoke

```bash
# API up?
curl -fsS http://10.0.1.1:8000/v1/models
# minimal chat:
curl -fsS http://10.0.1.1:8000/v1/chat/completions \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer dummy-key" \
  -d '{"model":"deepseek-v4-flash-0731","messages":[{"role":"user","content":"Reply with OK."}],"max_tokens":8,"temperature":0.0}'
```

Measurement caveats (from upstream 2026-07-29/31):
- **Warm up first** — the first requests after boot (or ~30 min idle) run ~30% slow.
- Use `stream: false` and read `usage.completion_tokens`; under spec-decode, counting
  SSE chunks measures **steps/s**, not tokens/s.

## Agent memories

Durable, distilled knowledge from building and validating this variant — topology,
image build/provenance, the runtime profile (incl. `DSPARK_SLOT_CLAMP`), and the
operational runbook (bring-up order, smoke tests, failure modes). No secrets.
See [`agent_memories_permanent/`](agent_memories_permanent/).

## Credits

- Upstream: [tonyd2wild/DeepSeek-v4-Flash-DSpark-1M-NVFP4-KV-2x-DGX-Spark](https://github.com/tonyd2wild/DeepSeek-v4-Flash-DSpark-1M-NVFP4-KV-2x-DGX-Spark)
  (updated 2026-07-31: Patch 4 shared-expert fix, Patch 5 stop-in-reasoning, slot clamp,
  tool parser refresh, CURRENT BEST profile).
- Base runtime: `ghcr.io/bjk110/vllm-spark:unholy-fusion-prod-ready`.
- Model: [deepseek-ai/DeepSeek-V4-Flash-0731](https://huggingface.co/deepseek-ai/DeepSeek-V4-Flash-0731) (MIT).
- Reuses variant02's proven head/worker script layout and NCCL/RoCE setup.