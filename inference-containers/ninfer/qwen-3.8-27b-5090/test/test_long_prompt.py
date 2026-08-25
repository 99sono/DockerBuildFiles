import asyncio
import httpx
import time

async def main():
    url = "http://localhost:8000/v1/chat/completions"
    headers = {"Authorization": "Bearer dummy-key"}
    
    # Generate ~20k tokens of synthetic context to test large prompt processing
    filler = ("The quick brown fox jumps over the lazy dog in deep learning systems. " * 1500)
    prompt = f"Here is context:\n{filler}\n\nQuestion: Based on the text above, answer in one short sentence: What jumps over what?"
    
    payload = {
        "model": "qwen3.8-27b",
        "messages": [{"role": "user", "content": prompt}],
        "max_tokens": 100,
        "temperature": 0.7
    }
    
    print("Sending large prompt (>20,000 tokens) to NInfer...")
    start = time.time()
    async with httpx.AsyncClient() as client:
        resp = await client.post(url, json=payload, headers=headers, timeout=120.0)
    elapsed = time.time() - start
    
    data = resp.json()
    print(f"Status code: {resp.status_code}")
    if resp.status_code == 200:
        usage = data.get("usage", {})
        print(f"✅ Success in {elapsed:.2f}s!")
        print(f"Prompt tokens: {usage.get('prompt_tokens')}")
        print(f"Completion tokens: {usage.get('completion_tokens')}")
        print(f"Response: {data['choices'][0]['message']['content']}")
    else:
        print(f"❌ Error response: {data}")

if __name__ == "__main__":
    asyncio.run(main())
