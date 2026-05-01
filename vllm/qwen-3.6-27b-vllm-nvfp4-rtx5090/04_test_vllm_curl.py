#!/usr/bin/env python3
import sys
from pathlib import Path
from openai import OpenAI

TEST_PROMPT_FILE = Path("test/test_file_01_prompt.md")
OUTPUT_FILE = Path("test/test_output_01.md")
URL = "http://localhost:8000/v1"
MODEL = "qwen3.6-27b-text-nvfp4-mtp"

if not TEST_PROMPT_FILE.exists():
    print(f"❌ Prompt file not found. Creating default...")
    TEST_PROMPT_FILE.parent.mkdir(parents=True, exist_ok=True)
    TEST_PROMPT_FILE.write_text("Hello Qwen! Write a short haiku about Blackwell architecture.")

prompt = TEST_PROMPT_FILE.read_text()

client = OpenAI(base_url=URL, api_key="dummy")

try:
    response = client.chat.completions.create(
        model=MODEL,
        messages=[{"role": "user", "content": prompt}],
    )
    content = response.choices[0].message.content
    OUTPUT_FILE.write_text(content)
    print("✅ Success! Output saved to", OUTPUT_FILE)
    print("\nPreview:\n", content[:500])
except Exception as e:
    print(f"❌ Error: {e}")
