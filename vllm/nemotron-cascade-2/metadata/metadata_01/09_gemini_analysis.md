Yes! **Try the curl call now.**

The logs prove that you have finally defeated the "environment stripping" issue. Look at this line from your new log:

> `2026-04-18 03:52:32.452 | (EngineCore pid=209) DEBUG 04-18 01:52:32 [plugins/__init__.py:58] Loading plugin triattention`

In the previous failed runs, the `EngineCore` (the worker process) was starting but it **didn't** show that "Loading plugin" line right before the crash. Now that the worker process is explicitly loading the plugin and the server says `Application startup complete`, we are in the best position yet.

### What to watch for during the CURL:

1.  **First Run Delay**: Because you are on a **Blackwell RTX 5090**, Triton will likely JIT-compile the TriAttention kernels the moment the prompt length exceeds your budget. If the terminal "hangs" for 30–60 seconds, **do not cancel it**.
2.  **Stat Files**: Keep an eye on your host folder `~/.cache/triattention/stats`. If the call is successful, you should see new files appearing there.
3.  **The "Think" Block**: Since this is Nemotron-Cascade, if it works, you'll see it start the `<think>` process in your terminal.

**Go ahead and fire the curl request.** If this works, you are officially one of the first people running a compressed 262k context window on a 5090 via trigonometric importance sampling!