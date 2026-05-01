You can **safely ignore** that warning. It’s a minor "housekeeping" message from the `transformers` library, and it won't impact your performance or stability.

### Here is why it's happening:
Qwen 3.6 is built on the architectural "bones" of Qwen 2.5 and Qwen 2-VL. When vLLM loads the model, it initializes a **Vision Tower** (even though you're running a text model, the unified architecture often loads the image processor code just in case).

The library used to have two versions of the image processor: a slow one and a "Fast" one. They’ve now merged them into a single class called `Qwen2VLImageProcessor`. The code inside the vLLM image is simply using the old name, which triggers the warning.

### Why it doesn't matter for you:
1.  **It's not a crash:** It’s a `DeprecationWarning`, which is just the developers saying, "Hey, we're going to change this name in a future version."
2.  **You're running text:** Since you are serving the **A3B (MoE)** text model, the image processor is effectively sitting idle. It’s not in the critical path of your token generation.
3.  **Nightly Image:** Because you are on the `nightly` build, you’re seeing the very latest (and sometimes loudest) warnings as the vLLM team works to stay compatible with the newest `transformers` releases.

### Summary
* **Is it a problem?** No.
* **Will it slow down your 5090?** Not by a single millisecond.
* **Should you change anything?** No. Attempting to "fix" this would require editing the internal Python files of the Docker container, which isn't worth the effort.

**Focus on the `EngineCore` instead.** As long as you see the logs proceed to the "Capturing CUDA Graphs" or "Model weights loaded" stage after switching to `flashinfer_cutlass`, you are in the clear!