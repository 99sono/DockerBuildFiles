#!/usr/bin/env python3
"""
Test vLLM Qwen3.8-Flash-Next NVFP4 server on DGX Spark.

Tests:
  1. GET /health
  2. GET /v1/models
  3. POST /v1/chat/completions (Text inference with reasoning)
  4. POST /v1/chat/completions (Multi-step tool calling)
"""

import json
import os
import sys

try:
    from dotenv import load_dotenv
    load_dotenv()
except ImportError:
    env_file = os.path.join(os.path.dirname(os.path.abspath(__file__)), ".env")
    if os.path.exists(env_file):
        with open(env_file) as f:
            for line in f:
                line = line.strip()
                if line and not line.startswith("#") and "=" in line:
                    k, v = line.split("=", 1)
                    os.environ.setdefault(k.strip(), v.strip())

try:
    import requests
except ImportError:
    print("❌ 'requests' package not found. Install with: pip install requests")
    sys.exit(1)

URL = os.environ.get("INFERENCE_SERVER_URL", "http://localhost:8000/v1")
MODEL = os.environ.get("INFERENCE_MODEL_ALIAS", "qwen3.8-flash-next")
API_KEY = os.environ.get("INFERENCE_API_KEY", "dummy-key")

headers = {
    "Content-Type": "application/json",
    "Authorization": f"Bearer {API_KEY}",
}


def test_health():
    print("=== Test 1: GET /health ===")
    base_url = URL.rstrip("/v1").rstrip("/")
    try:
        resp = requests.get(f"{base_url}/health", verify=False, timeout=10)
        print(f"Status: {resp.status_code}")
        print(f"Response: {resp.text}\n")
    except Exception as e:
        print(f"Health check failed: {e}\n")


def test_models():
    print("=== Test 2: GET /v1/models ===")
    try:
        resp = requests.get(f"{URL}/models", headers=headers, verify=False, timeout=10)
        print(f"Status: {resp.status_code}")
        data = resp.json()
        for m in data.get("data", []):
            print(f"  Model: {m['id']}")
        print()
    except Exception as e:
        print(f"Models check failed: {e}\n")


def test_chat():
    print("=== Test 3: POST /v1/chat/completions (Reasoning) ===")
    payload = {
        "model": MODEL,
        "messages": [
            {"role": "user", "content": "What is 17 * 23? Explain briefly and give the final answer."}
        ],
        "max_tokens": 1024,
        "temperature": 0.7,
    }
    try:
        resp = requests.post(f"{URL}/chat/completions", headers=headers, json=payload, verify=False, timeout=60)
        print(f"Status: {resp.status_code}")
        if resp.status_code == 200:
            result = resp.json()
            choice = result["choices"][0]["message"]
            if "reasoning" in choice and choice["reasoning"]:
                print(f"\n[Thinking]:\n{choice['reasoning']}")
            print(f"\n[Answer]:\n{choice.get('content', '')}")
            if "usage" in result:
                print(f"\nTokens used: {json.dumps(result['usage'], indent=2)}")
        else:
            print(f"Error: {resp.text}")
        print()
    except Exception as e:
        print(f"Chat completion failed: {e}\n")


def test_tool_calling():
    print("=== Test 4: POST /v1/chat/completions (Tool calling) ===")
    tools = [
        {
            "type": "function",
            "function": {
                "name": "get_weather",
                "description": "Get current weather in a city",
                "parameters": {
                    "type": "object",
                    "properties": {
                        "city": {"type": "string", "description": "City name"}
                    },
                    "required": ["city"],
                },
            },
        }
    ]
    payload = {
        "model": MODEL,
        "messages": [
            {"role": "user", "content": "What's the weather like in Lisbon?"}
        ],
        "tools": tools,
        "tool_choice": "auto",
        "max_tokens": 512,
    }
    try:
        resp = requests.post(f"{URL}/chat/completions", headers=headers, json=payload, verify=False, timeout=60)
        print(f"Status: {resp.status_code}")
        if resp.status_code == 200:
            result = resp.json()
            choice = result["choices"][0]["message"]
            if choice.get("tool_calls"):
                print("Tool calls returned:")
                for tc in choice["tool_calls"]:
                    print(f"  Function: {tc['function']['name']}, Args: {tc['function']['arguments']}")
            else:
                print(f"Response (no tool call): {choice.get('content')}")
        else:
            print(f"Error: {resp.text}")
        print()
    except Exception as e:
        print(f"Tool calling test failed: {e}\n")


if __name__ == "__main__":
    test_health()
    test_models()
    test_chat()
    test_tool_calling()
