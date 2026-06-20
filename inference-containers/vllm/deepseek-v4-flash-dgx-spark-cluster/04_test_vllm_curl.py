#!/usr/bin/env python3
"""Quick test for the DeepSeek-V4-Flash cluster endpoint."""
import os, sys
from pathlib import Path
from openai import OpenAI
from dotenv import load_dotenv

load_dotenv()

URL = os.environ.get("INFERENCE_SERVER_URL", "http://localhost:8000/v1")
MODEL = os.environ.get("INFERENCE_MODEL_ALIAS", "deepseek-v4-flash")
API_KEY = os.environ.get("INFERENCE_API_KEY", "dummy-key")

print(f"Server: {URL}")
print(f"Model:  {MODEL}")
print()

# 1. List models
client = OpenAI(base_url=URL, api_key=API_KEY)
try:
    models = client.models.list()
    print("--- Available models ---")
    for m in models:
        print(f"  {m.id}")
    print()
except Exception as e:
    print(f"Error listing models: {e}")
    sys.exit(1)

# 2. Chat completion
try:
    response = client.chat.completions.create(
        model=MODEL,
        messages=[
            {"role": "system", "content": "You are a helpful assistant."},
            {"role": "user", "content": "Write a short Python hello world."}
        ],
        max_tokens=100,
        temperature=0.7,
    )
    content = response.choices[0].message.content
    print("--- Response ---")
    print(content)
    print()
    usage = response.usage
    print(f"Prompt tokens: {usage.prompt_tokens}")
    print(f"Completion tokens: {usage.completion_tokens}")
    print(f"Total tokens: {usage.total_tokens}")
except Exception as e:
    print(f"Error: {e}")
    if hasattr(e, "response") and e.response is not None:
        print("Raw error response:", e.response.text)
