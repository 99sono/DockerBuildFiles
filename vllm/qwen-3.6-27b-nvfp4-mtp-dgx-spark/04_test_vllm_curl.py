#!/usr/bin/env python3
"""
Test vLLM Qwen3.6-27B NVFP4 MTP server via Nginx reverse proxy.

Tests:
  1. GET /health
  2. GET /v1/models
  3. POST /v1/chat/completions
  4. POST /v1/chat/completions with tool call
"""

import json
import sys
import os

try:
    import requests
except ImportError:
    print("❌ 'requests' package not found. Install with: pip install requests")
    sys.exit(1)

# Load API key from environment or .env
if os.path.isfile(".env"):
    for line in open(".env"):
        line = line.strip()
        if line.startswith("VLLM_API_KEY="):
            os.environ["VLLM_API_KEY"] = line.split("=", 1)[1]

API_KEY = os.environ.get("VLLM_API_KEY", "dummy-key")
BASE_URL = "https://spark-8ddc"

headers = {
    "Content-Type": "application/json",
    "Authorization": f"Bearer {API_KEY}",
}


def test_health():
    print("=== Test 1: GET /health ===")
    resp = requests.get(f"{BASE_URL}/health", verify=False)
    print(f"Status: {resp.status_code}")
    print(f"Response: {resp.text}\n")


def test_models():
    print("=== Test 2: GET /v1/models ===")
    resp = requests.get(f"{BASE_URL}/v1/models", headers=headers, verify=False)
    print(f"Status: {resp.status_code}")
    data = resp.json()
    for m in data.get("data", []):
        print(f"  Model: {m['id']}")
    print()


def test_chat():
    print("=== Test 3: POST /v1/chat/completions ===")
    payload = {
        "model": "Qwen3.6-27B-Text-NVFP4-MTP",
        "messages": [
            {"role": "user", "content": "What is 2+2? Answer in one sentence."}
        ],
        "max_tokens": 64,
    }
    resp = requests.post(
        f"{BASE_URL}/v1/chat/completions",
        headers=headers,
        json=payload,
        verify=False,
    )
    print(f"Status: {resp.status_code}")
    if resp.status_code == 200:
        data = resp.json()
        content = data["choices"][0]["message"].get("content", "")
        print(f"Response: {content[:200]}")
    else:
        print(f"Error: {resp.text[:300]}")
    print()


def test_tool_choice():
    print("=== Test 4: POST /v1/chat/completions (with tool_call: auto) ===")
    tools = [
        {
            "type": "function",
            "function": {
                "name": "get_weather",
                "description": "Get the current weather in a given location",
                "parameters": {
                    "type": "object",
                    "properties": {
                        "location": {
                            "type": "string",
                            "description": "The city and state, e.g. San Francisco, CA",
                        },
                    },
                    "required": ["location"],
                },
            },
        }
    ]
    payload = {
        "model": "Qwen3.6-27B-Text-NVFP4-MTP",
        "messages": [
            {"role": "user", "content": "What's the weather in Paris?"}
        ],
        "tools": tools,
        "tool_choice": "auto",
        "max_tokens": 128,
    }
    resp = requests.post(
        f"{BASE_URL}/v1/chat/completions",
        headers=headers,
        json=payload,
        verify=False,
    )
    print(f"Status: {resp.status_code}")
    if resp.status_code == 200:
        data = resp.json()
        choice = data["choices"][0]["message"]
        if choice.get("tool_calls"):
            print(f"Tool call: {choice['tool_calls'][0]['function']['name']}")
            args = choice["tool_calls"][0]["function"]["arguments"]
            print(f"Arguments: {args[:120]}")
        else:
            print(f"Response: {choice.get('content', '')[:200]}")
    else:
        print(f"Error: {resp.text[:300]}")
    print()


if __name__ == "__main__":
    requests.packages.urllib3.disable_warnings()

    print(f"Testing vLLM server at {BASE_URL} ...")
    print()

    test_health()
    test_models()
    test_chat()
    test_tool_choice()

    print("All tests complete.")