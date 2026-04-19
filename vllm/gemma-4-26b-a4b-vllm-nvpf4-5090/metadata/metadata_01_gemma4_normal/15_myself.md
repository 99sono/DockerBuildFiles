Gemma4 speed is less than i expected:

```speed:

APIServer pid=1)   warnings.warn(

(APIServer pid=1) INFO 04-19 11:08:01 [base.py:245] Multi-modal warmup completed in 15.544s

(APIServer pid=1) INFO 04-19 11:08:02 [api_server.py:602] Starting vLLM server on http://0.0.0.0:8000

(APIServer pid=1) INFO 04-19 11:08:02 [launcher.py:37] Available routes are:

(APIServer pid=1) INFO 04-19 11:08:02 [launcher.py:46] Route: /openapi.json, Methods: HEAD, GET

(APIServer pid=1) INFO 04-19 11:08:02 [launcher.py:46] Route: /docs, Methods: HEAD, GET

(APIServer pid=1) INFO 04-19 11:08:02 [launcher.py:46] Route: /docs/oauth2-redirect, Methods: HEAD, GET

(APIServer pid=1) INFO 04-19 11:08:02 [launcher.py:46] Route: /redoc, Methods: HEAD, GET

(APIServer pid=1) INFO 04-19 11:08:02 [launcher.py:46] Route: /tokenize, Methods: POST

(APIServer pid=1) INFO 04-19 11:08:02 [launcher.py:46] Route: /detokenize, Methods: POST

(APIServer pid=1) INFO 04-19 11:08:02 [launcher.py:46] Route: /load, Methods: GET

(APIServer pid=1) INFO 04-19 11:08:02 [launcher.py:46] Route: /version, Methods: GET

(APIServer pid=1) INFO 04-19 11:08:02 [launcher.py:46] Route: /health, Methods: GET

(APIServer pid=1) INFO 04-19 11:08:02 [launcher.py:46] Route: /metrics, Methods: GET

(APIServer pid=1) INFO 04-19 11:08:02 [launcher.py:46] Route: /v1/models, Methods: GET

(APIServer pid=1) INFO 04-19 11:08:02 [launcher.py:46] Route: /ping, Methods: GET

(APIServer pid=1) INFO 04-19 11:08:02 [launcher.py:46] Route: /ping, Methods: POST

(APIServer pid=1) INFO 04-19 11:08:02 [launcher.py:46] Route: /invocations, Methods: POST

(APIServer pid=1) INFO 04-19 11:08:02 [launcher.py:46] Route: /v1/chat/completions, Methods: POST

(APIServer pid=1) INFO 04-19 11:08:02 [launcher.py:46] Route: /v1/chat/completions/batch, Methods: POST

(APIServer pid=1) INFO 04-19 11:08:02 [launcher.py:46] Route: /v1/responses, Methods: POST

(APIServer pid=1) INFO 04-19 11:08:02 [launcher.py:46] Route: /v1/responses/{response_id}, Methods: GET

(APIServer pid=1) INFO 04-19 11:08:02 [launcher.py:46] Route: /v1/responses/{response_id}/cancel, Methods: POST

(APIServer pid=1) INFO 04-19 11:08:02 [launcher.py:46] Route: /v1/completions, Methods: POST

(APIServer pid=1) INFO 04-19 11:08:02 [launcher.py:46] Route: /v1/messages, Methods: POST

(APIServer pid=1) INFO 04-19 11:08:02 [launcher.py:46] Route: /v1/messages/count_tokens, Methods: POST

(APIServer pid=1) INFO 04-19 11:08:02 [launcher.py:46] Route: /inference/v1/generate, Methods: POST

(APIServer pid=1) INFO 04-19 11:08:02 [launcher.py:46] Route: /scale_elastic_ep, Methods: POST

(APIServer pid=1) INFO 04-19 11:08:02 [launcher.py:46] Route: /is_scaling_elastic_ep, Methods: POST

(APIServer pid=1) INFO 04-19 11:08:02 [launcher.py:46] Route: /generative_scoring, Methods: POST

(APIServer pid=1) INFO 04-19 11:08:02 [launcher.py:46] Route: /v1/chat/completions/render, Methods: POST

(APIServer pid=1) INFO 04-19 11:08:02 [launcher.py:46] Route: /v1/completions/render, Methods: POST

(APIServer pid=1) INFO:     Started server process [1]

(APIServer pid=1) INFO:     Waiting for application startup.

(APIServer pid=1) INFO:     Application startup complete.

(APIServer pid=1) INFO:     172.18.0.1:40280 - "POST /v1/chat/completions HTTP/1.1" 200 OK

(APIServer pid=1) INFO 04-19 11:10:42 [loggers.py:271] Engine 000: Avg prompt throughput: 2.6 tokens/s, Avg generation throughput: 1.9 tokens/s, Running: 0 reqs, Waiting: 0 reqs, GPU KV cache usage: 0.0%, Prefix cache hit rate: 0.0%

(APIServer pid=1) INFO 04-19 11:10:52 [loggers.py:271] Engine 000: Avg prompt throughput: 0.0 tokens/s, Avg generation throughput: 0.0 tokens/s, Running: 0 reqs, Waiting: 0 reqs, GPU KV cache usage: 0.0%, Prefix cache hit rate: 0.0%

(APIServer pid=1) INFO:     172.18.0.1:58736 - "POST /v1/chat/completions HTTP/1.1" 200 OK

(APIServer pid=1) INFO 04-19 11:12:42 [loggers.py:271] Engine 000: Avg prompt throughput: 10.8 tokens/s, Avg generation throughput: 17.1 tokens/s, Running: 0 reqs, Waiting: 0 reqs, GPU KV cache usage: 0.0%, Prefix cache hit rate: 0.0%

(APIServer pid=1) INFO 04-19 11:12:52 [loggers.py:271] Engine 000: Avg prompt throughput: 0.0 tokens/s, Avg generation throughput: 0.0 tokens/s, Running: 0 reqs, Waiting: 0 reqs, GPU KV cache usage: 0.0%, Prefix cache hit rate: 0.0%

```



What do you think?