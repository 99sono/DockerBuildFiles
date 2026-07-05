# Docker Compose Log and Analysis — 2026-06-21 (Worker Copy)

See the head node's copy for full analysis:
`head/metadata/metadata01_2026_06_21/01_docker_compose_log_and_analysis.md`

## GID Table (Worker)

| Index | rocep1s0f0 (Port 1) | roceP2p1s0f0 (Port 2) |
|-------|---------------------|----------------------|
| **4** | **`::ffff:0a00:0102`** ✅ 10.0.1.2 | **`::ffff:0a00:0202`** ✅ 10.0.2.2 |
| 5 | `::ffff:0a00:0102` | `::ffff:0a00:0202` |

Worker's IPv4 GIDs are at index **4** — correct with `NCCL_IB_GID_INDEX="4,4"`.
