# Image Build & Provenance

How the runtime image is built, where it comes from, and how to verify two nodes are
running the same thing.

## Build chain

`00_build_dspark_image.sh` is the shared engine. The two wrappers only set
`WORKER_BUILD` and exec it:

| Wrapper | `WORKER_BUILD` | Behavior |
|---|---|---|
| `00_a_build_head_dspark_image.sh` | `0` | Builds on **this node only**. Use on a node that must build locally without touching the other. |
| `00_b_build_worker_dspark_image.sh` | `1` | Builds on this node **and** rsyncs the variant folder to `WORKER_HOST` and rebuilds there. Run from the head (spark01) to provision both nodes in one step. |

`WORKER_HOST` (e.g. `sono99@10.0.1.2`) must be in the shared variant-root `.env`.

## Base image

`ghcr.io/bjk110/vllm-spark:unholy-fusion-prod-ready` (~22.7 GB). Pull it on each node
before building; the build is not reproducible from scratch without it.

## Provenance / upstream pin

The `recipe/` overlay is a **vendored snapshot** of the upstream DSpark repo
(`tonyd2wild/DeepSeek-v4-Flash-DSpark-1M-NVFP4-KV-2x-DGX-Spark`). It is pinned to a
specific upstream commit — see `recipe/README.md` for the exact pin table. Key facts:

- All 21 `recipe/overlay/` files + `Dockerfile.dspark-runtime-overlay` +
  `verify-overlay-sources.sh` are byte-identical to the pinned upstream commit.
- The only local modification: the `# CONTRACT` sparkrun comment block is stripped from
  `nvfp4/Dockerfile.stage-{a,b,c}` (we use plain `docker build`, not sparkrun).
- "Patch 4" (`shared_experts.gate_up_proj`) now comes from upstream itself. The build
  script greps for it and fails fast if absent — do not "fix" a missing Patch 4 by
  re-adding a local patch; re-sync from upstream instead.

## Cross-node parity — the trap

**Do NOT use `docker image inspect Id` to confirm the two nodes run the same image.**
The image IDs legitimately differ per node: the stage-1 `py_compile` / import `RUN`
steps write `__pycache__` / JIT artifacts, so the build is **not** bit-reproducible.

The real parity signals (should be identical on both nodes):

- vLLM version string: `0.21.1rc1.dev339+g1967a5627bc3`
- The final build smoke line: `dspark nvfp4 stage-c 0731 image ok`

If those match, the nodes are running the same logical image.