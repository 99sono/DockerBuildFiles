#!/usr/bin/env python3
"""
04_test_vllm.py - Clean test script for Nemotron-Cascade-2 using OpenAI client
"""

import sys
from pathlib import Path
from openai import OpenAI

# ========================= CONFIGURATION =========================
TEST_PROMPT_FILE = Path("test/test_file_01_prompt.md")
OUTPUT_FILE = Path("test/test_output_01.md")
URL = "http://localhost:8000/v1"
MODEL = "chankhavu/Nemotron-Cascade-2-30B-A3B-NVFP4"

# ========================= VALIDATION =========================
if not TEST_PROMPT_FILE.exists():
    print(f"❌ Prompt file not found: {TEST_PROMPT_FILE}")
    sys.exit(1)

prompt = TEST_PROMPT_FILE.read_text(encoding="utf-8")

print("🚀 Sending request to Nemotron-Cascade-2 via Python client")
print(f"   Prompt file : {TEST_PROMPT_FILE}")
print(f"   Output file : {OUTPUT_FILE}")
print(f"   Model       : {MODEL}")
print("-" * 60)

# ========================= CLIENT SETUP =========================
client = OpenAI(
    base_url=URL,
    api_key="dummy-key",   # vLLM doesn't require a real key
)

# ========================= SEND REQUEST =========================
try:
    response = client.chat.completions.create(
        model=MODEL,
        messages=[{"role": "user", "content": prompt}],
        temperature=0.7,
        # max_tokens=None,     # commented out = no limit
    )

    content = response.choices[0].message.content

    OUTPUT_FILE.write_text(content, encoding="utf-8")

    print("✅ Success! Response saved to", OUTPUT_FILE)
    print("\nPreview of response:")
    print("-" * 60)
    print(content[:600] + ("..." if len(content) > 600 else ""))
    print("-" * 60)

except Exception as e:
    print(f"❌ Error: {e}")
    if hasattr(e, "response") and e.response is not None:
        print("Raw error response:", e.response.text)