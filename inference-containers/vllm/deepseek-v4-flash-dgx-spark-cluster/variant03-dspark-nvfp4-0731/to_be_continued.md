# To Be Continued — DeepSeek-V4-Flash-0731 (variant03)

> DELETE THIS FILE when the variant is up and validated. It's a handoff note, not documentation.

## State as of last session (2026-08-19, late)

**Done:**
- Weights `deepseek-ai/DeepSeek-V4-Flash-0731` (~167G) downloaded on **spark02**
  at `~/.cache/huggingface/hub/models--deepseek-ai--DeepSeek-V4-Flash-0731/`
  (snapshot `7872f01b1d1fe23eabc4c98b48bffcef5a386062`).
- **rsync to spark01 COMPLETED OK** — same path on spark01. Model is on both nodes.
- variant03 scaffold fully committed on branch `feature/DeepSeek-v4-Flash-0731-DSpark-1M-NVFP4`
  (4 commits: `2f5d643` scaffold, `8dfdd77` README, `28fe9b9` env-split, `989cc89` build-split).
- `head/.env`, `worker/.env`, parent `.env` already in place on **spark02**.
- `node_modules/` + `package.json` at repo root are **unrelated** (untracked, not ours — leave alone).

**NOT done yet — the build:**
- Base image `ghcr.io/bjk110/vllm-spark:unholy-fusion-prod-ready` (22.7GB) is **already on spark02**.
- The variant03 runtime image **has NOT been built yet** on either node.

## Next session — step by step

### 1. Build image on spark02 (local only — this node is the worker)
```bash
cd ~/dev/DockerBuildFiles/inference-containers/vllm/deepseek-v4-flash-dgx-spark-cluster/variant03-dspark-nvfp4-0731
./00_a_build_head_dspark_image.sh
```
- No `WORKER_BUILD=` prefix needed anymore — the wrapper scripts hardcode it:
  - `00_a_build_head_dspark_image.sh` → local only (`WORKER_BUILD=0`)
  - `00_b_build_worker_dspark_image.sh` → this node + `WORKER_HOST` (`WORKER_BUILD=1`)
- 4-stage build: overlay → `nvfp4-a` → `nvfp4-b` → final tag
  `vllm-dspark-runtime:dspark-nvfp4-stage-c-0731`. Takes a while.
- Engine fails fast if **Patch 4** is missing from the overlay — that's expected behavior, not a bug.

### 2. Push the branch (once you're ready — was deliberately held)
```bash
cd ~/dev/DockerBuildFiles
git push origin feature/DeepSeek-v4-Flash-0731-DSpark-1M-NVFP4
```
Pushes `28fe9b9` + `989cc89` (first two commits are already on origin).

### 3. Pull + build on spark01 (head)
```bash
cd ~/dev/DockerBuildFiles
git pull origin feature/DeepSeek-v4-Flash-0731-DSpark-1M-NVFP4
cd inference-containers/vllm/deepseek-v4-flash-dgx-spark-cluster/variant03-dspark-nvfp4-0731
cp .env.example .env            # set WORKER_HOST etc.
cp env.example.head head/.env
./00_a_build_head_dspark_image.sh    # base image already on spark01 too (variant02 used it)
```

### 4. Bring up the cluster
```bash
# spark02 (worker) FIRST:
cd .../variant03-dspark-nvfp4-0731/worker && ./01_up.sh
# spark01 (head) SECOND:
cd .../variant03-dspark-nvfp4-0731/head && ./01_up.sh
```
- Wait for `"Application startup complete"` in head logs (~5-6 min for 167G load).
- Smoke test: `curl -fsS http://10.0.1.1:8000/v1/models`
- Full test: `INFERENCE_SERVER_URL=http://10.0.1.1:8000/v1 ./04_test_vllm_curl.py`

## Gotchas (from our analysis — trust these over intuition)

- **GID index differs per node:** head (spark01) `NCCL_IB_GID_INDEX="2,2"`,
  worker (spark02) `"4,4"`. Never use the same .env on both.
- **k (MTP_NUM_TOKENS) is locked ≤5** — `k=7` from DeepSeek's card crashes on first gen
  (tensor 7 vs 5 mismatch). Keep `MTP_NUM_TOKENS=5`.
- **Profile must be 6 slots / gmu 0.78** — 12/0.85 is the issue-#8 first-request OOM trigger.
- **No** `VLLM_USE_V2_MODEL_RUNNER=1`, **no** `--override-generation-config`,
  **no** `FLASHINFER_MLA_SPARSE_DSV4` backend.
- **JIT/compile caches must be node-local**, never on shared NFS inside the HF cache.
- Only **one** variant runs at a time per node (host networking, port 8000). variant01/02 must be down.
- First request after cold start may time out (torch.compile warmup) — retry.
- Base image is the same for variant02/variant03 — variant03 only differs by overlay patch + image tag.

## Useful refs
- README: `variant03-dspark-nvfp4-0731/README.md` (differences table, build flow, config notes)
- Scratch analysis (gitignored): `variant03-dspark-nvfp4-0731/chain_of_thought/key-facts-and-analysis.md`
- Upstream: `~/dev/thirdparty/DeepSeek-v4-Flash-DSpark-1M-NVFP4-KV-2x-DGX-Spark` (commit `2d4820f`)