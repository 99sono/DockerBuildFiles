# To Be Continued — DeepSeek-V4-Flash-0731 (variant03)

> DELETE THIS FILE when the variant is up and validated. It's a handoff note, not documentation.

## State as of last session (2026-08-19, late)

**Done:**
- Weights `deepseek-ai/DeepSeek-V4-Flash-0731` (~167G) downloaded on **spark02**
  at `~/.cache/huggingface/hub/models--deepseek-ai--DeepSeek-V4-Flash-0731/`
  (snapshot `7872f01b1d1fe23eabc4c98b48bffcef5a386062`).
- **rsync to spark01 COMPLETED OK** — same path on spark01. Model is on both nodes.
- variant03 scaffold fully committed on the current working branch (ephemeral feature
  branch — will be merged to master; not pinned here on purpose)
  (commits: `2f5d643` scaffold, `8dfdd77` README, `28fe9b9` env-split, `989cc89` build-split,
  `b27ca46` this note, `f902735` recipe README, then the `0fec808` recipe sync).
- **Recipe synced to upstream `0fec808` (2026-08-23)** — added the 2 tokenizer files
  (`reasoning_effort` three-level fix) + Dockerfile COPY/compile/import lines; all 21 overlay
  files + Dockerfile now byte-identical to upstream. See `recipe/README.md` (pin table).
- `head/.env`, `worker/.env`, parent `.env` already in place on **spark02**.
- `node_modules/` + `package.json` at repo root are **unrelated** (untracked, not ours — leave alone).

- **Image BUILT on BOTH nodes** (2026-08-29) — spark02 `00_b`, spark01 `00_a`, all 4
  `-0731` tags + final smoke on each.
  Image IDs differ by design (84a02c7e0857 on spark02 vs 62cc6866356f on spark01): stage-1's
  `py_compile`/import `RUN` writes `__pycache__`/JIT artifacts, so builds are NOT bit-reproducible.
  **Do NOT use `docker image inspect Id` as a parity check** — it will always differ. The real
  parity signals (both confirmed identical): vLLM version `0.21.1rc1.dev339+g1967a5627bc3` and
  the final smoke line `dspark nvfp4 stage-c 0731 image ok`.
- **Gitignore bug found + fixed (`ec41c7e`):** `inference-containers/**/models/` (weight guard)
  silently swallowed 7 variant03 overlay files under `models/` paths — they existed on spark02
  but were never committed, so spark01's fresh clone was missing them and the build aborted at
  `verify-overlay-sources.sh`. Fixed with `git add -f` + a `.gitignore` comment.
  **If any recipe file under a `models/` path is new, it needs `git add -f`.**

**NOT done yet:**
- Bring up the cluster: worker (spark02) `01_up.sh` FIRST, then head (spark01) `01_up.sh`,
  then smoke-test `curl http://10.0.1.1:8000/v1/models`.
- Optional: `git push` (branch is ahead; only matters if another clone needs the fixes).

## Next session — step by step

### 1. spark02 image: DONE (2026-08-29)
Built with `./00_b_build_worker_dspark_image.sh` (local stages all OK; the final
`WORKER_HOST` error is harmless — it's the "propagate to the other node" step, and
there's nothing to propagate from the worker). All 4 `-0731` tags present.

### 2. spark01 image: DONE (2026-08-29)
`git pull` restored the 7 force-added `models/` files; `./00_a_build_head_dspark_image.sh`
completed all 4 stages + final smoke. All 4 `-0731` tags present. (Image ID differs from
spark02 by design — see parity note above; do not "fix" it.)

### 3. Push (once you're ready — was deliberately held)
```bash
cd ~/dev/DockerBuildFiles
git push          # pushes the current branch to its upstream (no branch name hardcoded)
```
Pushes the unpushed variant03 commits (scaffold/README already on origin).

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
- Upstream: `~/dev/thirdparty/DeepSeek-v4-Flash-DSpark-1M-NVFP4-KV-2x-DGX-Spark` (recipe pinned at `0fec808`)