#!/usr/bin/env python3
"""Quick verification client for Qwen 3.8 Flash Next Dual-Spark cluster."""
import json
import os
import sys
from pathlib import Path
from openai import OpenAI

URL = os.environ.get("INFERENCE_SERVER_URL", "http://localhost:8000/v1")
MODEL = os.environ.get("INFERENCE_MODEL_ALIAS", "qwen3.8-flash-next")
API_KEY = os.environ.get("INFERENCE_API_KEY", "dummy-key")

print(f"Server: {URL}")
print(f"Model:  {MODEL}")
print()

client = OpenAI(base_url=URL, api_key=API_KEY)

# 1. Models List
try:
    models = client.models.list()
    print("--- Available models ---")
    for m in models:
        print(f"  {m.id}")
    print()
except Exception as e:
    print(f"Error listing models: {e}")
    sys.exit(1)

# 2. Reasoning Chat Completion
try:
    print("--- Testing Chat Completion with Reasoning ---")
    response = client.chat.completions.create(
        model=MODEL,
        messages=[
            {"role": "system", "content": "You are a concise mathematician."},
            {"role": "user", "content": "How many r's are in strawberry? Think step by step."}
        ],
        max_tokens=256,
        temperature=0.6,
    )
    choice = response.choices[0]
    if hasattr(choice.message, "reasoning_content") and choice.message.reasoning_content:
        print(f"Reasoning:\n{choice.message.reasoning_content}\n")
    print(f"Content:\n{choice.message.content}\n")

    usage = response.usage
    if usage:
        print(f"Usage -> Prompt: {usage.prompt_tokens}, Completion: {usage.completion_tokens}, Total: {usage.total_tokens}")
    print("✅ Chat completion successful.")
except Exception as e:
    print(f"Error during chat completion: {e}")
    sys.exit(1)

# 3. Tool Calling Verification
try:
    print("\n--- Testing Tool Calling ---")
    tools = [
        {
            "type": "function",
            "function": {
                "name": "get_weather",
                "description": "Get current weather for a city",
                "parameters": {
                    "type": "object",
                    "properties": {
                        "city": {"type": "string", "description": "Name of the city"}
                    },
                    "required": ["city"]
                }
            }
        }
    ]
    tool_resp = client.chat.completions.create(
        model=MODEL,
        messages=[{"role": "user", "content": "What is the weather in Lisbon right now?"}],
        tools=tools,
        tool_choice="auto",
        max_tokens=150,
    )
    msg = tool_resp.choices[0].message
    if msg.tool_calls:
        for tc in msg.tool_calls:
            print(f"Tool Call: {tc.function.name} -> {tc.function.arguments}")
        print("✅ Tool calling parsed successfully.")
    else:
        print(f"No tool call returned; raw response: {msg.content}")
except Exception as e:
    print(f"Error testing tool calls: {e}")

print("\n🎉 All cluster client tests completed!")
