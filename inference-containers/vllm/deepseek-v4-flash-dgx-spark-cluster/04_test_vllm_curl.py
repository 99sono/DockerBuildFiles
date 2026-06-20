#!/usr/bin/env python3
"""Quick test for the DeepSeek-V4-Flash endpoint on the head node."""
import os
import sys
import json
import urllib.request
import urllib.error
from pathlib import Path

# Load .env from parent directory
env_path = Path(__file__).resolve().parent / ".env"
if env_path.exists():
    for line in env_path.read_text().splitlines():
        if "=" in line and not line.startswith("#"):
            k, v = line.strip().split("=", 1)
            os.environ.setdefault(k, v)

SERVER_URL = os.environ.get("INFERENCE_SERVER_URL", "http://localhost:8000/v1")
API_KEY = os.environ.get("INFERENCE_API_KEY", "dummy-key")
MODEL = os.environ.get("INFERENCE_MODEL_ALIAS", "deepseek-v4-flash")

print(f"Server: {SERVER_URL}")
print(f"Model:  {MODEL}")
print()

# 1. List models
try:
    req = urllib.request.Request(f"{SERVER_URL}/models")
    req.add_header("Authorization", f"Bearer {API_KEY}")
    with urllib.request.urlopen(req, timeout=30) as r:
        data = json.loads(r.read())
        print("--- Available models ---")
        for m in data.get("data", []):
            print(f"  {m['id']}")
        print()
except Exception as e:
    print(f"Error listing models: {e}")
    sys.exit(1)

# 2. Chat completion
payload = {
    "model": MODEL,
    "messages": [
        {"role": "system", "content": "You are a helpful assistant."},
        {"role": "user", "content": "Write a short Python hello world."}
    ],
    "max_tokens": 100,
    "temperature": 0.7
}

try:
    req = urllib.request.Request(
        f"{SERVER_URL}/chat/completions",
        data=json.dumps(payload).encode(),
        headers={
            "Content-Type": "application/json",
            "Authorization": f"Bearer {API_KEY}"
        }
    )
    with urllib.request.urlopen(req, timeout=120) as r:
        data = json.loads(r.read())
        content = data["choices"][0]["message"]["content"]
        print("--- Response ---")
        print(content)
        print()
        print(f"Usage: {data.get('usage', {})}")
except urllib.error.HTTPError as e:
    print(f"HTTP {e.code}: {e.read().decode()}")
except Exception as e:
    print(f"Error: {e}")
