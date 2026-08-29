# Operational Runbook

Day-to-day operations for this variant: bring-up, verification, teardown, and the
failure modes that actually happen.

## Bring-up (order matters)

1. **One variant per node.** Ensure no other variant's container is up on either node
   (host networking — port 8000 collides).
2. **Worker first:** on spark02 run `worker/01_up.sh`. The worker starts, loads
   config, and **parks at the torch.distributed rendezvous**
   (`tcp://10.0.1.1:25000`) waiting for the head. This is normal and idle-safe.
3. **Head second:** on spark01 run `head/01_up.sh`. Both nodes then load weights
   together (~48 shards × ~4 s ≈ 3–4 min of shard loading, observed end-to-end
   ~5–6 min to `Application startup complete`).
4. Watch head logs (`head/05_a_follow_logs.sh`) for `Application startup complete`.

If the head never comes up, the worker hangs at the rendezvous — that's the symptom
to look for, not an error on the worker.

## Verification (smoke)

```bash
# Alive check (401 without key = server is up and authenticating):
curl -fsS http://10.0.1.1:8000/v1/models

# Model list + real inference (key from the node's .env; convention: real key
# lives only in gitignored .env):
curl -fsS -H "Authorization: Bearer $INFERENCE_API_KEY" http://10.0.1.1:8000/v1/models

# Chat completion:
curl -fsS -H "Authorization: Bearer $INFERENCE_API_KEY" \
  -H "Content-Type: application/json" \
  http://10.0.1.1:8000/v1/chat/completions \
  -d '{"model":"deepseek-v4-flash-0731","messages":[{"role":"user","content":"hi"}],"max_tokens":32}'
```

- Baseline reference (2026-08-29 first bring-up): first real chat completion
  ~3 s for 67 tokens.
- The first request after a cold start can time out on torch.compile warmup —
  retry once before declaring failure.
- `04_test_vllm_curl.py` needs `openai` + `python-dotenv` (absent from system
  python3) — use a conda env or raw curl.
- `docker compose -f <node>/docker-compose.yml config -q` validates the compose +
  env resolution without starting anything — run it after any `.env`/compose edit.

## Teardown / logs

- `02_down.sh` per node (order doesn't matter for down).
- `05_a_follow_logs.sh` / `05_b_dump_logs.sh` / `05_c_dump_logs_to_dump_txt.sh` (head).
- NCCL/RDMA diagnosis: `04_check_nccl.sh` on each node.

## Failure modes (observed)

| Symptom | Cause / fix |
|---|---|
| Worker sits forever at rendezvous | Head not up, or `MASTER_ADDR`/fabric IP wrong on head. |
| NCCL hang/crash at connect | Per-node GID mismatch — head must be `2,2`, worker `4,4`; `.env` files were copied across nodes. Run `04_check_nccl.sh`. |
| Container dies immediately at boot after a flag change | Unrecognized engine flag — that vLLM version rejects it hard. Check the flag name against the image's vLLM version. |
| `HF` download attempts / model not found | Weights missing on that node, or `HF_HUB_OFFLINE=1`/`HF_HOME` not pointing at the mounted cache dir. |
| 401 from `/v1/models` | Normal — auth required. Not an error. |

## Repo gotchas (touching this variant)

- **`.gitignore` weight guard swallows recipe files.** `inference-containers/**/models/`
  (the model-weight guard) also matches vendored overlay files under `models/` paths —
  plain `git add` silently skips them. Use `git add -f` for any recipe file under a
  `models/` path (this bit us: 7 files).
- **Never commit:** `.env`, model weights, anything in `model_chain_of_thought/`.
- Per-node `.env` files are gitignored; the committed templates are the per-node
  `.env.example` files. `01_up.sh` seeds `.env` from `.env.example` if missing.

## Environment access note

From spark02, reaching spark01 over the fabric requires
`source ~/.ssh/agent-env` before `ssh sono99@10.0.1.1` (agent key; no password auth).