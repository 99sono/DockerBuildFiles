# recipe/ — where this image comes from, and how to keep it honest

## What this directory is

The plain-English version: the base image
(`ghcr.io/bjk110/vllm-spark:unholy-fusion-prod-ready`) ships vLLM **without** the
DeepSeek-V4 DSpark speculative-decoding + NVFP4 + B12X kernel stack. That stack lives
as a set of Python files ("the overlay") plus a chain of `docker build` stages.

This directory is a **vendored snapshot** of exactly those files, so the image can be
rebuilt offline and reproducibly without the upstream repo being present at build time.

## Provenance

Everything in here was cloned out of:

```
git@github.com:tonyd2wild/DeepSeek-v4-Flash-DSpark-1M-NVFP4-KV-2x-DGX-Spark.git
```

| What | Upstream path | Pinned at |
|---|---|---|
| `overlay/**` (21 files) | `recipe/overlay/**` | `0fec808` (2026-08-23) — **byte-identical**, verified 2026-08-29 |
| `Dockerfile.dspark-runtime-overlay` | `recipe/Dockerfile.dspark-runtime-overlay` | `0fec808` — **byte-identical** |
| `nvfp4/Dockerfile.stage-{a,b,c}` | `recipe/nvfp4/Dockerfile.stage-{a,b,c}` | `0fec808` — see "local modifications" |
| `official-main/Dockerfile.python-patch` | `recipe/official-main/Dockerfile.python-patch` | `0fec808` — byte-identical (not used by this build chain) |
| `verify-overlay-sources.sh` | `scripts/verify-overlay-sources.sh` | `0fec808` — byte-identical |

**Note on the pin bump (2026-08-29):** `2d4820f → 0fec808` added two tokenizer files
(`overlay/vllm/tokenizers/deepseek_v4.py`, `deepseek_v4_encoding.py`) plus their COPY /
py_compile / import-check lines in the Dockerfile — the `reasoning_effort` three-level fix.
Side effect worth knowing: after this, a request with `reasoning_effort="max"` injects
DeepSeek's real *max* thinking text (526 chars) instead of the *high* text; `"high"` and
omitted behave exactly as before.

## The one local modification

`nvfp4/Dockerfile.stage-{a,b,c}` are **not** byte-identical to upstream. We stripped
the `# CONTRACT — ...` comment block from the top of each. That contract only matters
to *sparkrun* (an out-of-band tool that sed-extracts the heredoc and rebuilds the stage
inside a running container). We build these stages with plain `docker build`, so the
contract is dead weight here — and leaving it in invites a future editor to "respect"
it for no reason. The functional content of the files is unchanged.

**Rule for future edits:** if you re-sync a stage file from upstream, re-strip the
CONTRACT block. Keep the rest byte-identical.

## How the build uses this (very simply)

1. **Stage 1** (`Dockerfile.dspark-runtime-overlay`): `FROM` the base image, `COPY`
   each `overlay/` file onto the exact `site-packages` path it replaces, then run
   `py_compile` + real import checks on every file copied. A bad file fails the build,
   not the first serving request.
2. **Stages a → b → c** (`nvfp4/`): each `FROM` the previous stage and applies the next
   layer of NVFP4 dtype plumbing, ending at the final tag
   `vllm-dspark-runtime:dspark-nvfp4-stage-c-0731`.

`00_build_dspark_image.sh` drives all of this and also greps the overlay for
`shared_experts.gate_up_proj` (Patch 4 — the 0731 speedup) and fails fast if it is
missing.

## Upgrading the pin (when upstream moves)

The overlay is a **snapshot, not a submodule** — it does not update itself. When you
`git pull` in the upstream repo:

1. In upstream: `git log --oneline <old-pin>..HEAD` and read what changed.
2. Check only the paths this recipe consumes:
   `git diff --stat <old-pin>..HEAD -- recipe/overlay/ recipe/Dockerfile.dspark-runtime-overlay recipe/nvfp4/ scripts/verify-overlay-sources.sh`
3. Re-copy the changed files into the matching paths here (`overlay/` →
   `recipe/overlay/`, etc.). Re-strip any CONTRACT block in `nvfp4/` stage files.
4. Bump the pin in the table above to the new commit + date.
5. Rebuild the image. Stage 1's compile/import checks are your safety net.

## Quick verification

```bash
# every COPY source in the Dockerfile actually exists locally:
./verify-overlay-sources.sh

# Patch 4 (0731 speedup) present in the spec-decode overlay:
grep -c shared_experts.gate_up_proj overlay/vllm/v1/spec_decode/dspark.py
```