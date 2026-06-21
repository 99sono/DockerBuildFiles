# metadata

Analysis notes and dumped docker logs from inference runs.

## Numbering convention

Each folder `metadataNN_YYYY_MM_DD` represents one debugging or inference
session. The same `NN` number is used on **both** nodes so you can cross-reference:

| Folder | Head (spark01) | Worker (spark02) |
|--------|----------------|-------------------|
| `metadata01_2026_06_21` | Head logs for session 01 | Worker logs for session 01 |
| `metadata02_...` | (next session) | (next session) |

Each session folder contains:
- `01_docker_compose_log_and_analysis.md` — raw log excerpts + config dump
- `02_deep_seek_analysis.md` — root cause analysis, intuitions, next steps
