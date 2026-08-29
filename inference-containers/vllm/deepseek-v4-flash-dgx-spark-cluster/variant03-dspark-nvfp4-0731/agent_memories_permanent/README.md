# Agent Memories (Permanent)

Distilled technical knowledge from building, deploying, and validating this variant.
Written for future agent (or human) sessions working in this folder — durable
documentation, not a session transcript.

**Rules:**

- **No secrets, ever.** No API keys, credentials, or private information. This folder
  is committed to the repo and stays there forever. (The API-key *convention* — real
  key only in gitignored `.env`, placeholder in `.env.example` — is fine to document;
  the key itself never is.)
- Conclusions only, not raw thinking. If an entry stops being true, fix it in place.
- Operational state that is only true "right now" (what's running, what's WIP) belongs
  in the repo's scratchpad protocol (`model_chain_of_thought/`), not here.

| File | Contents |
|---|---|
| `00_cluster-topology.md` | Nodes, fabric IPs, NCCL/RoCE config, model artifact, serving endpoint |
| `01_image-build-and-provenance.md` | Image chain, upstream pin, build entry points, cross-node parity checks |
| `02_runtime-profile.md` | Parallelism / memory / speculative-decoding knobs and why they are set |
| `03_operational-runbook.md` | Bring-up order, monitoring, smoke tests, known failure modes, repo gotchas |