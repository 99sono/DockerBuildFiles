import asyncio
import time
import httpx

PROMPTS = [
    "Explain the difference between Monads and Functors in Haskell with practical examples.",
    "Write a detailed Python implementation of an LRU Cache with O(1) operations.",
    "Discuss the trade-offs between Paxos and Raft consensus algorithms.",
    "How does the Linux kernel epoll mechanism work under the hood?",
    "Explain how Transformer Multi-Head Latent Attention (MLA) works mathematically.",
    "Write a comprehensive step-by-step guide to calculating matrix eigenvalues and eigenvectors.",
    "Explain the physics and engineering behind quantum error correction using surface codes.",
    "Explain how speculative decoding with draft verification works in modern LLM inference engines."
]

async def send_request(client, req_id, prompt):
    url = "http://localhost:8000/v1/chat/completions"
    headers = {"Authorization": "Bearer dummy-key"}
    payload = {
        "model": "qwen3.8-27b",
        "messages": [{"role": "user", "content": prompt}],
        "max_tokens": 1500,
        "temperature": 1.0,
        "top_p": 0.95
    }
    start = time.time()
    resp = await client.post(url, json=payload, headers=headers, timeout=120.0)
    elapsed = time.time() - start
    data = resp.json()
    usage = data.get("usage", {})
    gen_tokens = usage.get("completion_tokens", 0)
    tok_per_sec = gen_tokens / elapsed if elapsed > 0 else 0
    print(f"[Req {req_id}] Done: {gen_tokens} tokens in {elapsed:.2f}s ({tok_per_sec:.1f} tok/s)")
    return gen_tokens, elapsed

async def main():
    print("🚀 Launching 8 concurrent streams to test aggregate throughput (Marshall Gould test recipe)...")
    start_total = time.time()
    async with httpx.AsyncClient() as client:
        tasks = [send_request(client, i+1, prompt) for i, prompt in enumerate(PROMPTS)]
        results = await asyncio.gather(*tasks)
    
    total_time = time.time() - start_total
    total_tokens = sum(r[0] for r in results)
    aggregate_tps = total_tokens / total_time
    print(f"\n==========================================")
    print(f"📊 AGGREGATE RESULTS (Concurrency = 8)")
    print(f"Total Generated Tokens : {total_tokens}")
    print(f"Total Wall Time        : {total_time:.2f} s")
    print(f"Aggregate Throughput   : {aggregate_tps:.2f} tokens/second")
    print(f"==========================================")

if __name__ == "__main__":
    asyncio.run(main())
