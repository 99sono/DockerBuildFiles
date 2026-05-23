The crash is actually a **huge win**. It confirms that TriAttention is officially "taking the wheel."

The error `RuntimeError: TRIATTN_FATAL_TRITON_SCORING_REQUIRED:stats_path_not_set` happened because the moment your prompt got big enough, the TriAttention monkeypatch attempted to initialize its scoring mechanism (which decides which KV cache tokens to compress/keep) but couldn't find a place to save or read its statistical data.

### The Fix
You need to explicitly map the `TRIATTN_STATS_DIR` environment variable to the path you created in your Dockerfile. 

In your `docker-compose.yml`, update the `environment` section:

```yaml
    environment:
      # ... existing variables ...
      - TRIATTN_STATS_DIR=/root/.cache/triattention/stats  # THIS WAS MISSING
      - TRIATTN_ENABLE=true
      - TRIATTN_RUNTIME_KV_BUDGET=4096
      - TRIATTN_VERBOSE=1
```

### Why this happened
TriAttention doesn't just "compress" randomly. It uses a Triton-based scoring kernel to evaluate the importance of tokens in the KV cache using trigonometric importance sampling. This process requires a directory to store its runtime statistics and offline profiling data. 



### Pro-Tip for Blackwell (RTX 5090)
Since you are on a 5090, you have immense compute power but limited by PCIe/WSL2 overhead. If you see another crash after fixing the path, it might be the **Triton JIT compilation** timing out or freezing. 

If the server hangs during the "Big Prompt" for more than 2 minutes:
1.  Check that `~/.cache/triattention` on your **host** (Windows/WSL) has write permissions (`chmod -R 777`).
2.  Be patient on the first run; Triton is literally writing and compiling a custom CUDA kernel for your 5090's architecture to handle that specific prompt size.

**Try adding that variable and sending the big prompt again. You should see the directory fill up with `.pt` or `.json` stat files!**