# AGENTS.md

Shared instructions for AI coding agents working in this repository (Cline, OpenCode, and any other agent reading this file). Human-facing documentation lives in [README.md](README.md) — this file is the operational contract for agents.

## Repo in 30 seconds

- Docker Compose configs + thin bash helper scripts for local LLM inference servers on two hardware targets: **RTX 5090** (AMD64) and **DGX Spark** (ARM64).
- Backends under `inference-containers/`: llama.cpp (GGUF + MTP speculative decoding), vLLM, Ollama, Atlas, nginx (proxy), Open WebUI.
- All wrapper scripts source the shared library `commonScripts/lib.sh` — new scripts must do the same, at the correct relative depth.

## Hard conventions (do not break)

- Every inference server binds **internal port 8000**; **one model per container**.
- `docker-compose.yml` files keep `${VAR:-default}` syntax (`.env` stays optional); variables use the unified `INFERENCE_` prefix.
- Project folder naming: `{model-name}-{size}-{hardware}`; script naming follows the numbered convention (`00_a_...`, `01_up.sh`, `02_down.sh`, ...).
- Compose flag style: short comment block above each flag group explaining *why* — keep this style when editing.
- **Never commit**: `.env`, `**/00_env.sh`, model weights (`inference-containers/**/models/`), or anything inside `model_chain_of_thought/`.

## Validation habits

- After editing any `docker-compose.yml`: run `docker compose -f <path>/docker-compose.yml config` to catch YAML/env errors before proposing the change as done.
- llama.cpp fails hard at boot on unrecognized flags — a failed container start after a flag change means the flag name is wrong for that image tag.
- To test a running server: the project's `04_test_curl.sh` (wraps `commonScripts/test_client.py`).

## Scratchpad protocol — durable thought, disposable context

The conversation window is ephemeral; decisions must outlive it. Working memory that needs to survive beyond the current session lives in `model_chain_of_thought/` (gitignored — **never commit its contents**):

| File | Owner | Purpose | Lifetime |
|---|---|---|---|
| `ImportantKeyThoughts.md` | **master only** | Key decisions, constraints, open questions, and context that is NOT captured in code or repo docs | Durable — master prunes stale entries |
| `SCRATCH.md` | **master only** | Master's working scratch: plans, abandoned approaches, WIP notes | Disposable — master wipes freely |
| `tasks/<task-slug>.md` | **one sub-agent each** | A delegated worker's notes for its task (kebab-case slug, unique per task) | Deleted by master when the task completes |

### Roles

- **Master** = the session the user is actively talking to. It is the only writer to `ImportantKeyThoughts.md` and `SCRATCH.md`, and the only agent allowed to merge or delete `tasks/` files.
- **Sub-agent** = a delegated or parallel worker (orchestrator fan-out, second terminal acting as a worker). It creates `tasks/<task-slug>.md`, writes **only** there, and reports conclusions back through its final answer.

### Rules

1. **One master at a time.** If two sessions are active in this repo, the user designates which one is master; the other behaves as a sub-agent (own `tasks/` file only).
2. **Sub-agents never touch shared files.** No edits to `ImportantKeyThoughts.md`, `SCRATCH.md`, or any other task's file — even to "fix" or "prune" them.
3. **During the task (master):** the moment you make a decision, discover a constraint, or reach a conclusion that (a) is not written in code or repo docs and (b) a future session will need — append it to `ImportantKeyThoughts.md`. Bullet points only, no essays.
4. **Merge, then delete (master):** when a sub-agent's task completes, distill its key conclusions into `ImportantKeyThoughts.md`, then delete its `tasks/` file. A batch is finished when its task files are gone.
5. **Distill, don't hoard:** raw chain-of-thought belongs in your thinking process and burns away. Only *conclusions* survive on disk.
6. **Scoped wipe:** an agent may only wipe files it owns (its own `tasks/` file; master owns the shared files and all task files). Never treat another agent's file as "stale residue" and wipe it — if you are master and a task file looks orphaned, confirm the task is done first.
7. **Keep it lean:** `ImportantKeyThoughts.md` should stay well under ~150 lines. When it grows, prune aggressively — this file is an *index of thought*, not a transcript.
8. **Harness-agnostic:** this protocol is defined once here so Cline and OpenCode sessions hand off cleanly — the next agent, on either harness, in any role, reads the same file.
