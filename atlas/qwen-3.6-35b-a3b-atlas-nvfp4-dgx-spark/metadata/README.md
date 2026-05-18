# Metadata

Timestamped Atlas container logs dumped via `../05_b_log_to_metadata_folder.sh`.

## Log File Naming

```
YYYY-MM-DD_HH-MM-SS_atlas_log.txt
```

Logs are captured once (non-following) to preserve a snapshot of the current
container state at the time of invocation. Use `../05_docker_logs.sh` for
live, following tail output instead.

## Typical Usage

After observing anomalous behavior (e.g., high K2 rejection rate), run:

```bash
../05_b_log_to_metadata_folder.sh
```

The script produces a summary with file path, size, and line count for quick
reference in debugging sessions.
