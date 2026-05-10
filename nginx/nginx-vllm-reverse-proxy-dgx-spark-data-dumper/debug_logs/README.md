# Debug Logs Directory

## Purpose
This directory stores captured HTTP request and response bodies from the debug proxy.

The files are generated automatically when the debug proxy is running and traffic flows through it.

## Files

### `requests.log`
Captured request bodies sent to the debug proxy (originally from OpenCode or other clients).

**Format:**
```
2026-05-10 08:30:00 REQUEST
Method: POST
URI: /v1/chat/completions
Body:
{"model": "...", "messages": [...], "tools": [...]}
---
```

### `responses.log`
Captured response bodies received from vLLM and forwarded to the client.

**Format:**
```
2026-05-10 08:30:01 RESPONSE
Status: 200
Body:
{"id": "chatcmpl-...", "object": "chat.completion", ...}
---
```

## Log Details
- Each entry is preceded by a timestamp, HTTP method, URI, and status code
- The actual JSON/XML body follows on subsequent lines
- Entries are separated by `---` delimiters
- Logs are appended (old data persists)

## Debugging Workflow
1. Start the debug proxy: `./01_up.sh`
2. Watch logs in real-time: `./04_follow_requests.sh` or `./05_follow_responses.sh`
3. Trigger the bug in OpenCode
4. Stop the proxy: `./02_down.sh`
5. Analyze captured logs in this directory

## Maintenance
- Logs accumulate over time – delete or truncate manually when done debugging
- No automatic log rotation is implemented
