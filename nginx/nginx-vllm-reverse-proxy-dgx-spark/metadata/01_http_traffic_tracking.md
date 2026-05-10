# Tracking HTTP Traffic: OpenCode ↔ vLLM via Nginx Reverse Proxy

## Overview

This document describes methods for capturing and debugging HTTP traffic flowing through the nginx reverse proxy between OpenCode (client) and vLLM/Qwen (backend API). This is essential for debugging tool_call parsing issues, streaming response problems, and understanding the exact payloads exchanged.

## Quick Start (for OpenCode tool_call debugging)

**Fastest path to see what is happening:**

```bash
# 1. Run mitmproxy
pip install mitmproxy
mitmproxy --mode regular --listen-port 8888 --ssl-insecure

# 2. Configure OpenCode to use proxy: http://localhost:8888
#    (Install mitmproxy CA cert if OpenCode validates SSL)

# 3. Trigger the bug

# 4. Look for responses containing XML tool calls or vLLM error JSON
```

---

## Why Standard Nginx Logs Are Not Enough

Your nginx config has:

```nginx
proxy_buffering off;
proxy_request_buffering off;
```

This means **nginx streams data directly** without buffering. That is great for performance and streaming support, but it prevents nginx from logging full request/response bodies -- because nginx never assembles the entire body in memory.

Standard `access_log` will only give you metadata (URL, status, time, bytes, etc.) -- **not the actual JSON that OpenCode sends or Qwen returns**.

---

## Method 1: mitmproxy (Recommended)

The easiest and most powerful approach for debugging the full interaction.

### Setup

```bash
# Install mitmproxy
pip install mitmproxy

# Run in transparent mode, targeting nginx on port 443
mitmproxy --mode regular --listen-port 8888 --ssl-insecure
```

### Usage

1. Configure OpenCode to use `http://localhost:8888` as its HTTP proxy
2. Trigger your vLLM request from OpenCode
3. All requests and responses will appear in the mitmproxy interface in real-time
4. You can replay requests, save captures to files, filter by URL, etc.

### What You Will See

- Full request headers and bodies (including the JSON payload OpenCode sends)
- Full response bodies (including streaming chunks from vLLM)
- Tool call XML/JSON payloads
- Any errors or malformed responses

### ⚠️ SSL Certificate Warning

When mitmproxy terminates SSL, it generates its own certificate authority. You must install mitmproxy's CA certificate in OpenCode's trust store, otherwise OpenCode will reject the SSL connection to nginx.

To install the mitmproxy CA certificate:

```bash
# Find the CA cert location
find ~/.mitmproxy -name "mitmproxy-ca-cert-*.pem"

# On Linux, copy to your CA store (requires root)
sudo cp ~/.mitmproxy/mitmproxy-ca-cert.pem /usr/local/share/ca-certificates/mitmproxy-ca.crt
sudo update-ca-certificates

# On macOS: open ~/.mitmproxy/mitmproxy-ca-cert.cer
# On Windows: double-click ~/.mitmproxy/mitmproxy-ca-cert.pem
```

Alternatively, if OpenCode supports it, you can disable certificate verification in the proxy settings.

### Streaming Chunk Verification

Streaming responses (when vLLM uses `stream=true`) appear as multiple HTTP chunks. mitmproxy will show each chunk sequentially -- look for incomplete XML/JSON fragments that indicate parser issues.

### Tips

- Use `mitmweb` instead of `mitmproxy` for a web UI
- Save captures: `mitmproxy -w capture.mitm` then replay with `mitmproxy -r capture.mitm`
- Filter by host: `-H spark-8ddc` or similar

---

## Method 2: tcpdump Inside Nginx Container

Docker-native approach for capturing raw HTTP traffic without external tools.

### Setup

```bash
# Install tcpdump inside the nginx container
docker exec nginx-proxy apt-get update && apt-get install -y tcpdump
```

### Usage

```bash
# Capture traffic on ALL interfaces
# This captures raw packets between nginx and the vLLM backend
# Using -i any is important because Docker containers use virtual
# Ethernet pairs for inter-container communication, not just eth0
docker exec nginx-proxy tcpdump -A -i any 'tcp port 8000' -s 65535 -w /tmp/capture.pcap
```

To capture from the client side (port 443 inbound):

```bash
docker exec nginx-proxy tcpdump -A -i any 'tcp port 443' -s 65535 -w /tmp/client_capture.pcap
```

### Analyzing Captures

```bash
# Stop the capture with Ctrl+C
# Copy the pcap file out of the container
docker cp nginx-proxy:/tmp/capture.pcap ./nginx-capture.pcap

# Or read raw output directly
docker exec nginx-proxy tcpdump -A -i any 'tcp port 8000' -s 65535
```

### What You Will See

- Raw TCP packets with HTTP content
- Can be messy but contains the actual payloads
- Good for understanding the raw data flowing through the network

---

## Method 3: Nginx Debug Logging (Partial Help)

Nginx can log headers and some body data, but with limitations due to `proxy_request_buffering off`.

### Configuration

Add this to your `nginx.conf` in the `http` block:

```nginx
log_format debug_format '$remote_addr - $remote_user [$time_local] '
                       '"$request" $status $body_bytes_sent '
                       '"$http_referer" "$http_user_agent" '
                       'request_body="$request_body" '
                       'upstream_response="$upstream_http_x_vllm_response"';
```

And in the `location /` block:

```nginx
location / {
    proxy_pass http://vllm:8000;

    # Log request headers and partial body (helps see tool_call format)
    set $request_body_log $request_body;
    access_log /var/log/nginx/vllm_debug.log debug_format;

    # ... other proxy_set_header lines ...
}
```

### Limitation

Because `proxy_request_buffering off` prevents nginx from storing the full body, `$request_body` may be **empty or partial**. This method is useful for:

- Seeing HTTP headers
- Getting a glimpse of the first chunk of a request
- Tracking request/response timing and status codes
- Identifying which requests are being proxied

But it **will not give you the full JSON payloads** for streaming responses.

### Applying Changes

```bash
# Verify config syntax
bash 06_b_nginx_verify_config.sh

# Reload nginx configuration
bash 06_a_nginx_reload_config.sh

# View the debug log
docker exec nginx-proxy tail -f /var/log/nginx/vllm_debug.log
```

---

## Debugging OpenCode ↔ vLLM Tool Call Issues

From the OpenCode GitHub issues, the root cause of tool_call problems often appears to be:

> Qwen3's reasoning/tool_call XML parser interacting badly with OpenCode's expectation of JSON.

The issue typically manifests as **naked XML tags appearing when the parser fails mid-stream**.

### Important: Parser Location

Your vLLM command includes:

```bash
--enable-auto-tool-choice
--tool-call-parser qwen3_coder
--reasoning-parser qwen3
```

These parsers operate **inside vLLM, not in nginx**. If the bug is a parsing failure, you may see no malformed data at the HTTP level -- because vLLM might be sending back a correct JSON error response (e.g., `{"error": "tool call parsing failed"}`) that OpenCode then mishandles.

In that case, the guides will still show you **that error response**, which is incredibly useful. But if you see perfectly valid JSON and OpenCode still breaks, the problem is in OpenCode's parser, not the wire format.

### What to Look For

When capturing traffic, look for:

1. **What OpenCode sends** -- Is it asking for JSON or XML tool calls?
   - Check the `messages` array in the request body
   - Look for `tool_choice` and `tools` parameters
   - Check if it expects structured JSON or XML-style tool calls

2. **What vLLM/Qwen returns** -- Raw XML that OpenCode fails to parse
   - Look for incomplete or malformed XML blocks
   - Check if the `stop` parameter in your vLLM config handles XML properly
   - Look for streaming artifacts (chunks that do not properly terminate XML)

3. **Comparison with working models**
   - Run the same prompt with a model that works (e.g., Claude or GPT)
   - Compare the tool call format in the response
   - Look for differences in how the XML is structured or terminated

4. **Check vLLM's own error responses**
   If `--tool-call-parser qwen3_coder` fails, vLLM returns a 400 error with a JSON body like:

   ```json
   {"error": "Failed to parse tool call from content: ..."}
   ```

   Capture this -- it is a strong indicator of a parser config mismatch.

---

## Quick Reference: All Nginx Monitoring Commands

```bash
# Follow logs in real-time (from docker compose)
bash 05_a_follow_logs.sh

# Dump logs to file
bash 05_b_dump_logs.sh

# Enter the nginx container for manual inspection
bash 03_enter_container.sh

# View debug log after adding custom log format
docker exec nginx-proxy tail -f /var/log/nginx/vllm_debug.log

# Check nginx error log
docker exec nginx-proxy tail -f /var/log/nginx/error.log

# View vLLM container logs
docker exec nginx-proxy tail -f /var/log/nginx/vllm_upstream.log
```

---

## Recommended Workflow

1. **Start with nginx logs** (`05_a_follow_logs.sh`) for basic request metadata
2. **Use mitmproxy** for full request/response capture (recommended for tool_call debugging)
3. **Fall back to tcpdump** if you need to stay entirely within Docker
4. **Use nginx debug logging** for quick header/timing inspection

For most debugging scenarios, **mitmproxy is the fastest path to understanding what is happening**.

---

## Method 4: Self-Contained Debug Proxy (Lua Dumper)

For debugging without external tools or client changes, use the **parallel debug proxy** in `nginx-vllm-reverse-proxy-dgx-spark-data-dumper/`.

### How it works
- Runs on **port 8888 (HTTP only)** – no SSL complexity
- **Buffers all requests/responses** (unlike production proxy which has buffering off)
- Dumps raw JSON/XML bodies to local log files using inline Lua in nginx
- Completely separate from production nginx – both can run simultaneously

### Project Structure

```
nginx-vllm-reverse-proxy-dgx-spark-data-dumper/
├── 00_env.sh                    # Environment variables
├── 00_env.sh.example            # Template
├── 01_up.sh                     # Start debug proxy
├── 02_down.sh                   # Stop debug proxy
├── 03_enter_container.sh        # Enter container shell
├── 04_follow_requests.sh        # Tail request logs
├── 05_follow_responses.sh       # Tail response logs
├── docker-compose.debug.yml     # OpenResty service
├── nginx.debug.conf             # Nginx config with inline Lua
├── README.md                    # Documentation
├── .gitignore                   # Excludes debug_logs/
└── debug_logs/                  # Captured bodies (gitignored)
    ├── requests.log
    └── responses.log
```

### Quick Start

```bash
cd nginx-vllm-reverse-proxy-dgx-spark-data-dumper/

# 1. Start the debug proxy
./01_up.sh

# 2. Point OpenCode to http://<spark-host>:8888

# 3. Watch logs in real-time (separate terminals)
./04_follow_requests.sh    # Terminal 1: request bodies
./05_follow_responses.sh   # Terminal 2: response bodies

# 4. Trigger the bug in OpenCode

# 5. Stop when done
./02_down.sh
```

### Log Format

**requests.log:**
```
2026-05-10 08:30:00 REQUEST
Method: POST
URI: /v1/chat/completions
Body:
{"model": "...", "messages": [...], "tools": [...]}
---
```

**responses.log:**
```
2026-05-10 08:30:01 RESPONSE
Status: 200
Body:
{"id": "chatcmpl-...", "object": "chat.completion", ...}
---
```

### Key Differences from Production

| Aspect | Production | Debug Variant |
|--------|-----------|---------------|
| Image | `nginx:latest` | `openresty/openresty:alpine` |
| Buffering | OFF (streaming) | ON (full capture) |
| Protocol | HTTPS (443) | HTTP (8888) |
| Body logging | None | Full request/response |
| Container | `nginx-proxy` | `nginx-proxy-debug` |

### When to use this
- You don't want to install mitmproxy
- You can't configure OpenCode's proxy settings
- You need to see complete bodies without streaming chunk boundaries
- You want a completely self-contained, single-port solution

### Limitations
- **HTTP only** – API key visible in logs; change it after debugging
- Adds buffering latency – not for production use
- Logs are appended – manually delete old logs when done debugging
- Requires OpenResty image (larger than plain nginx)

### Technical Details

The debug proxy uses OpenResty with inline Lua scripts:

- **Request capture:** `access_by_lua_block` reads the full request body and writes to `debug_logs/requests.log`
- **Response capture:** `body_filter_by_lua_block` accumulates all chunks and writes the complete body to `debug_logs/responses.log` when the last chunk arrives
- **Buffering enabled:** `proxy_buffering on` and `proxy_request_buffering on` allow full body access (opposite of production)
-------
