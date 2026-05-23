# Model unusable with cline

In cline, in plan mode, the model immediately goes into halluncinating mode.
Not usable for any sort of agentic development.
Model 8 bit quantizatio is simply too large for a dgx spark anyway.

# Atlas log

```log
📋 Displaying logs for 'qwen-3-6-27b-fp8-mtp-atlas' (Ctrl+C to stop)...
2026-05-21T18:32:04.774594Z  INFO spark::main_modules::serve: Atlas Spark starting...
2026-05-21T18:32:04.774611Z  INFO spark::main_modules::serve: Licensed under AGPL-3.0-only — see /LICENSE in this container
2026-05-21T18:32:04.774678Z  INFO spark::model_resolver: Model: Qwen/Qwen3.6-27B-FP8 (resolved to /root/.cache/huggingface/hub/models--Qwen--Qwen3.6-27B-FP8/snapshots/e89b16ebf1988b3d6befa7de50abc2d76f26eb09)
2026-05-21T18:32:04.774684Z  INFO spark::main_modules::serve: Port: 8000
2026-05-21T18:32:04.774685Z  INFO spark::main_modules::serve: SSM decode dtype: f32 (full precision)
2026-05-21T18:32:04.774815Z  INFO spark::main_modules::serve: Quantization config: method="fp8", algo="", format="", 0 module(s) in ignore list
2026-05-21T18:32:04.774819Z  INFO spark::main_modules::serve: Model config: 64 layers, 16 attention, 48 SSM, 0 experts, rope_theta=10000000, head_dim=256, rotary_dim=64
2026-05-21T18:32:04.774855Z  INFO spark::main_modules::serve: Selected kernel target: (sm_121, qwen3.6-27b, nvfp4) (86 modules)
2026-05-21T18:32:11.002560Z  INFO spark_runtime::cuda_backend: AtlasCudaBackend initialized on GPU 0 with 86 PTX modules
2026-05-21T18:32:11.002675Z  INFO spark::main_modules::serve_phases::preflight: GPU 0: 119.6 GB total, 114.6 GB free
2026-05-21T18:32:11.002680Z  INFO spark::main_modules::serve_phases::preflight: Preflight reserve: inference=9905 MB, buffer_arena=2308 MB (pre-load free: 114.6 GB)
2026-05-21T18:32:11.002696Z  INFO spark::main_modules::serve: OOM watchdog started (threshold: 2 GB, interval: 2s)
2026-05-21T18:32:11.002700Z  INFO spark::main_modules::serve: OOM guard reserve: 4096 MB
2026-05-21T18:32:11.002702Z  INFO spark::main_modules::serve_phases::weights: Using fast weight loader (O_DIRECT + pipelined read/copy)
2026-05-21T18:32:11.017536Z  INFO spark_runtime::fast_weights: Fast-load pre-flight: 28.75 GB on-disk, 1.1x overhead = 30.18 GB peak, 114.56 GB free, 4.0 GB reserve (FP8: true)
2026-05-21T18:32:11.017571Z  INFO spark_runtime::fast_weights: Fast-loading shard 1/66: layers-0.safetensors (20 tensors)
2026-05-21T18:32:11.153581Z  INFO spark_runtime::fast_weights:   Shard 1/66 done — GPU memory: 0.42 GB used, 114.14 GB free
2026-05-21T18:32:11.153629Z  INFO spark_runtime::fast_weights: Fast-loading shard 2/66: layers-1.safetensors (20 tensors)
2026-05-21T18:32:11.284865Z  INFO spark_runtime::fast_weights:   Shard 2/66 done — GPU memory: 0.79 GB used, 113.77 GB free
2026-05-21T18:32:11.284918Z  INFO spark_runtime::fast_weights: Fast-loading shard 3/66: layers-10.safetensors (20 tensors)
2026-05-21T18:32:11.405231Z  INFO spark_runtime::fast_weights:   Shard 3/66 done — GPU memory: 1.16 GB used, 113.40 GB free
2026-05-21T18:32:11.405285Z  INFO spark_runtime::fast_weights: Fast-loading shard 4/66: layers-11.safetensors (18 tensors)
2026-05-21T18:32:11.526330Z  INFO spark_runtime::fast_weights:   Shard 4/66 done — GPU memory: 1.52 GB used, 113.04 GB free
2026-05-21T18:32:11.526385Z  INFO spark_runtime::fast_weights: Fast-loading shard 5/66: layers-12.safetensors (20 tensors)
2026-05-21T18:32:11.658522Z  INFO spark_runtime::fast_weights:   Shard 5/66 done — GPU memory: 1.89 GB used, 112.67 GB free
2026-05-21T18:32:11.658574Z  INFO spark_runtime::fast_weights: Fast-loading shard 6/66: layers-13.safetensors (20 tensors)
2026-05-21T18:32:11.792048Z  INFO spark_runtime::fast_weights:   Shard 6/66 done — GPU memory: 2.25 GB used, 112.31 GB free
2026-05-21T18:32:11.792100Z  INFO spark_runtime::fast_weights: Fast-loading shard 7/66: layers-14.safetensors (20 tensors)
2026-05-21T18:32:11.921649Z  INFO spark_runtime::fast_weights:   Shard 7/66 done — GPU memory: 2.53 GB used, 112.03 GB free
2026-05-21T18:32:11.921740Z  INFO spark_runtime::fast_weights: Fast-loading shard 8/66: layers-15.safetensors (18 tensors)
2026-05-21T18:32:12.028317Z  INFO spark_runtime::fast_weights:   Shard 8/66 done — GPU memory: 2.90 GB used, 111.66 GB free
2026-05-21T18:32:12.028406Z  INFO spark_runtime::fast_weights: Fast-loading shard 9/66: layers-16.safetensors (20 tensors)
2026-05-21T18:32:12.158173Z  INFO spark_runtime::fast_weights:   Shard 9/66 done — GPU memory: 3.27 GB used, 111.29 GB free
2026-05-21T18:32:12.158261Z  INFO spark_runtime::fast_weights: Fast-loading shard 10/66: layers-17.safetensors (20 tensors)
2026-05-21T18:32:12.280342Z  INFO spark_runtime::fast_weights:   Shard 10/66 done — GPU memory: 3.63 GB used, 110.92 GB free
2026-05-21T18:32:12.280432Z  INFO spark_runtime::fast_weights: Fast-loading shard 11/66: layers-18.safetensors (20 tensors)
2026-05-21T18:32:12.399499Z  INFO spark_runtime::fast_weights:   Shard 11/66 done — GPU memory: 4.01 GB used, 110.55 GB free
2026-05-21T18:32:12.399589Z  INFO spark_runtime::fast_weights: Fast-loading shard 12/66: layers-19.safetensors (18 tensors)
2026-05-21T18:32:12.502805Z  INFO spark_runtime::fast_weights:   Shard 12/66 done — GPU memory: 4.36 GB used, 110.20 GB free
2026-05-21T18:32:12.502878Z  INFO spark_runtime::fast_weights: Fast-loading shard 13/66: layers-2.safetensors (20 tensors)
2026-05-21T18:32:12.634820Z  INFO spark_runtime::fast_weights:   Shard 13/66 done — GPU memory: 4.73 GB used, 109.83 GB free
2026-05-21T18:32:12.634906Z  INFO spark_runtime::fast_weights: Fast-loading shard 14/66: layers-20.safetensors (20 tensors)
2026-05-21T18:32:12.761049Z  INFO spark_runtime::fast_weights:   Shard 14/66 done — GPU memory: 5.10 GB used, 109.46 GB free
2026-05-21T18:32:12.761136Z  INFO spark_runtime::fast_weights: Fast-loading shard 15/66: layers-21.safetensors (20 tensors)
2026-05-21T18:32:12.886414Z  INFO spark_runtime::fast_weights:   Shard 15/66 done — GPU memory: 5.47 GB used, 109.09 GB free
2026-05-21T18:32:12.886507Z  INFO spark_runtime::fast_weights: Fast-loading shard 16/66: layers-22.safetensors (20 tensors)
2026-05-21T18:32:13.011520Z  INFO spark_runtime::fast_weights:   Shard 16/66 done — GPU memory: 5.82 GB used, 108.74 GB free
2026-05-21T18:32:13.011608Z  INFO spark_runtime::fast_weights: Fast-loading shard 17/66: layers-23.safetensors (18 tensors)
2026-05-21T18:32:13.120284Z  INFO spark_runtime::fast_weights:   Shard 17/66 done — GPU memory: 6.17 GB used, 108.38 GB free
2026-05-21T18:32:13.120377Z  INFO spark_runtime::fast_weights: Fast-loading shard 18/66: layers-24.safetensors (20 tensors)
2026-05-21T18:32:13.234715Z  INFO spark_runtime::fast_weights:   Shard 18/66 done — GPU memory: 6.55 GB used, 108.01 GB free
2026-05-21T18:32:13.234806Z  INFO spark_runtime::fast_weights: Fast-loading shard 19/66: layers-25.safetensors (20 tensors)
2026-05-21T18:32:13.347561Z  INFO spark_runtime::fast_weights:   Shard 19/66 done — GPU memory: 6.90 GB used, 107.66 GB free
2026-05-21T18:32:13.347648Z  INFO spark_runtime::fast_weights: Fast-loading shard 20/66: layers-26.safetensors (20 tensors)
2026-05-21T18:32:13.469729Z  INFO spark_runtime::fast_weights:   Shard 20/66 done — GPU memory: 7.27 GB used, 107.29 GB free
2026-05-21T18:32:13.469816Z  INFO spark_runtime::fast_weights: Fast-loading shard 21/66: layers-27.safetensors (18 tensors)
2026-05-21T18:32:13.591491Z  INFO spark_runtime::fast_weights:   Shard 21/66 done — GPU memory: 7.62 GB used, 106.93 GB free
2026-05-21T18:32:13.591582Z  INFO spark_runtime::fast_weights: Fast-loading shard 22/66: layers-28.safetensors (20 tensors)
2026-05-21T18:32:13.708483Z  INFO spark_runtime::fast_weights:   Shard 22/66 done — GPU memory: 7.98 GB used, 106.57 GB free
2026-05-21T18:32:13.708571Z  INFO spark_runtime::fast_weights: Fast-loading shard 23/66: layers-29.safetensors (20 tensors)
2026-05-21T18:32:13.846923Z  INFO spark_runtime::fast_weights:   Shard 23/66 done — GPU memory: 8.35 GB used, 106.21 GB free
2026-05-21T18:32:13.846992Z  INFO spark_runtime::fast_weights: Fast-loading shard 24/66: layers-3.safetensors (18 tensors)
2026-05-21T18:32:13.970317Z  INFO spark_runtime::fast_weights:   Shard 24/66 done — GPU memory: 8.70 GB used, 105.86 GB free
2026-05-21T18:32:13.970410Z  INFO spark_runtime::fast_weights: Fast-loading shard 25/66: layers-30.safetensors (20 tensors)
2026-05-21T18:32:14.102071Z  INFO spark_runtime::fast_weights:   Shard 25/66 done — GPU memory: 9.06 GB used, 105.50 GB free
2026-05-21T18:32:14.102160Z  INFO spark_runtime::fast_weights: Fast-loading shard 26/66: layers-31.safetensors (18 tensors)
2026-05-21T18:32:14.224428Z  INFO spark_runtime::fast_weights:   Shard 26/66 done — GPU memory: 9.42 GB used, 105.14 GB free
2026-05-21T18:32:14.224525Z  INFO spark_runtime::fast_weights: Fast-loading shard 27/66: layers-32.safetensors (20 tensors)
2026-05-21T18:32:14.340591Z  INFO spark_runtime::fast_weights:   Shard 27/66 done — GPU memory: 9.78 GB used, 104.77 GB free
2026-05-21T18:32:14.340679Z  INFO spark_runtime::fast_weights: Fast-loading shard 28/66: layers-33.safetensors (20 tensors)
2026-05-21T18:32:14.472097Z  INFO spark_runtime::fast_weights:   Shard 28/66 done — GPU memory: 10.14 GB used, 104.42 GB free
2026-05-21T18:32:14.472180Z  INFO spark_runtime::fast_weights: Fast-loading shard 29/66: layers-34.safetensors (20 tensors)
2026-05-21T18:32:14.605083Z  INFO spark_runtime::fast_weights:   Shard 29/66 done — GPU memory: 10.50 GB used, 104.06 GB free
2026-05-21T18:32:14.605172Z  INFO spark_runtime::fast_weights: Fast-loading shard 30/66: layers-35.safetensors (18 tensors)
2026-05-21T18:32:14.720964Z  INFO spark_runtime::fast_weights:   Shard 30/66 done — GPU memory: 10.87 GB used, 103.69 GB free
2026-05-21T18:32:14.721056Z  INFO spark_runtime::fast_weights: Fast-loading shard 31/66: layers-36.safetensors (20 tensors)
2026-05-21T18:32:14.846125Z  INFO spark_runtime::fast_weights:   Shard 31/66 done — GPU memory: 11.24 GB used, 103.32 GB free
2026-05-21T18:32:14.846212Z  INFO spark_runtime::fast_weights: Fast-loading shard 32/66: layers-37.safetensors (20 tensors)
2026-05-21T18:32:14.966987Z  INFO spark_runtime::fast_weights:   Shard 32/66 done — GPU memory: 11.60 GB used, 102.96 GB free
2026-05-21T18:32:14.967079Z  INFO spark_runtime::fast_weights: Fast-loading shard 33/66: layers-38.safetensors (20 tensors)
2026-05-21T18:32:15.091627Z  INFO spark_runtime::fast_weights:   Shard 33/66 done — GPU memory: 11.97 GB used, 102.59 GB free
2026-05-21T18:32:15.091714Z  INFO spark_runtime::fast_weights: Fast-loading shard 34/66: layers-39.safetensors (18 tensors)
2026-05-21T18:32:15.209468Z  INFO spark_runtime::fast_weights:   Shard 34/66 done — GPU memory: 12.31 GB used, 102.25 GB free
2026-05-21T18:32:15.209541Z  INFO spark_runtime::fast_weights: Fast-loading shard 35/66: layers-4.safetensors (20 tensors)
2026-05-21T18:32:15.331305Z  INFO spark_runtime::fast_weights:   Shard 35/66 done — GPU memory: 12.69 GB used, 101.87 GB free
2026-05-21T18:32:15.331391Z  INFO spark_runtime::fast_weights: Fast-loading shard 36/66: layers-40.safetensors (20 tensors)
2026-05-21T18:32:15.452774Z  INFO spark_runtime::fast_weights:   Shard 36/66 done — GPU memory: 13.05 GB used, 101.51 GB free
2026-05-21T18:32:15.452863Z  INFO spark_runtime::fast_weights: Fast-loading shard 37/66: layers-41.safetensors (20 tensors)
2026-05-21T18:32:15.583524Z  INFO spark_runtime::fast_weights:   Shard 37/66 done — GPU memory: 13.43 GB used, 101.13 GB free
2026-05-21T18:32:15.583614Z  INFO spark_runtime::fast_weights: Fast-loading shard 38/66: layers-42.safetensors (20 tensors)
2026-05-21T18:32:15.708089Z  INFO spark_runtime::fast_weights:   Shard 38/66 done — GPU memory: 13.79 GB used, 100.77 GB free
2026-05-21T18:32:15.708180Z  INFO spark_runtime::fast_weights: Fast-loading shard 39/66: layers-43.safetensors (18 tensors)
2026-05-21T18:32:15.823480Z  INFO spark_runtime::fast_weights:   Shard 39/66 done — GPU memory: 14.15 GB used, 100.41 GB free
2026-05-21T18:32:15.823574Z  INFO spark_runtime::fast_weights: Fast-loading shard 40/66: layers-44.safetensors (20 tensors)
2026-05-21T18:32:15.940382Z  INFO spark_runtime::fast_weights:   Shard 40/66 done — GPU memory: 14.51 GB used, 100.05 GB free
2026-05-21T18:32:15.940476Z  INFO spark_runtime::fast_weights: Fast-loading shard 41/66: layers-45.safetensors (20 tensors)
2026-05-21T18:32:16.060969Z  INFO spark_runtime::fast_weights:   Shard 41/66 done — GPU memory: 14.88 GB used, 99.68 GB free
2026-05-21T18:32:16.061057Z  INFO spark_runtime::fast_weights: Fast-loading shard 42/66: layers-46.safetensors (20 tensors)
2026-05-21T18:32:16.183630Z  INFO spark_runtime::fast_weights:   Shard 42/66 done — GPU memory: 15.25 GB used, 99.31 GB free
2026-05-21T18:32:16.183718Z  INFO spark_runtime::fast_weights: Fast-loading shard 43/66: layers-47.safetensors (18 tensors)
2026-05-21T18:32:16.306777Z  INFO spark_runtime::fast_weights:   Shard 43/66 done — GPU memory: 15.59 GB used, 98.96 GB free
2026-05-21T18:32:16.306866Z  INFO spark_runtime::fast_weights: Fast-loading shard 44/66: layers-48.safetensors (20 tensors)
2026-05-21T18:32:16.434425Z  INFO spark_runtime::fast_weights:   Shard 44/66 done — GPU memory: 15.96 GB used, 98.60 GB free
2026-05-21T18:32:16.434516Z  INFO spark_runtime::fast_weights: Fast-loading shard 45/66: layers-49.safetensors (20 tensors)
2026-05-21T18:32:16.560225Z  INFO spark_runtime::fast_weights:   Shard 45/66 done — GPU memory: 16.32 GB used, 98.24 GB free
2026-05-21T18:32:16.560296Z  INFO spark_runtime::fast_weights: Fast-loading shard 46/66: layers-5.safetensors (20 tensors)
2026-05-21T18:32:16.693723Z  INFO spark_runtime::fast_weights:   Shard 46/66 done — GPU memory: 16.69 GB used, 97.87 GB free
2026-05-21T18:32:16.693809Z  INFO spark_runtime::fast_weights: Fast-loading shard 47/66: layers-50.safetensors (20 tensors)
2026-05-21T18:32:16.821294Z  INFO spark_runtime::fast_weights:   Shard 47/66 done — GPU memory: 17.06 GB used, 97.50 GB free
2026-05-21T18:32:16.821381Z  INFO spark_runtime::fast_weights: Fast-loading shard 48/66: layers-51.safetensors (18 tensors)
2026-05-21T18:32:16.925260Z  INFO spark_runtime::fast_weights:   Shard 48/66 done — GPU memory: 17.41 GB used, 97.14 GB free
2026-05-21T18:32:16.925350Z  INFO spark_runtime::fast_weights: Fast-loading shard 49/66: layers-52.safetensors (20 tensors)
2026-05-21T18:32:17.060261Z  INFO spark_runtime::fast_weights:   Shard 49/66 done — GPU memory: 17.77 GB used, 96.79 GB free
2026-05-21T18:32:17.060349Z  INFO spark_runtime::fast_weights: Fast-loading shard 50/66: layers-53.safetensors (20 tensors)
2026-05-21T18:32:17.187202Z  INFO spark_runtime::fast_weights:   Shard 50/66 done — GPU memory: 18.13 GB used, 96.42 GB free
2026-05-21T18:32:17.187291Z  INFO spark_runtime::fast_weights: Fast-loading shard 51/66: layers-54.safetensors (20 tensors)
2026-05-21T18:32:17.307929Z  INFO spark_runtime::fast_weights:   Shard 51/66 done — GPU memory: 18.50 GB used, 96.06 GB free
2026-05-21T18:32:17.308013Z  INFO spark_runtime::fast_weights: Fast-loading shard 52/66: layers-55.safetensors (18 tensors)
2026-05-21T18:32:17.422357Z  INFO spark_runtime::fast_weights:   Shard 52/66 done — GPU memory: 18.85 GB used, 95.71 GB free
2026-05-21T18:32:17.422449Z  INFO spark_runtime::fast_weights: Fast-loading shard 53/66: layers-56.safetensors (20 tensors)
2026-05-21T18:32:17.553214Z  INFO spark_runtime::fast_weights:   Shard 53/66 done — GPU memory: 19.22 GB used, 95.34 GB free
2026-05-21T18:32:17.553296Z  INFO spark_runtime::fast_weights: Fast-loading shard 54/66: layers-57.safetensors (20 tensors)
2026-05-21T18:32:17.681555Z  INFO spark_runtime::fast_weights:   Shard 54/66 done — GPU memory: 19.59 GB used, 94.97 GB free
2026-05-21T18:32:17.681640Z  INFO spark_runtime::fast_weights: Fast-loading shard 55/66: layers-58.safetensors (20 tensors)
2026-05-21T18:32:17.817802Z  INFO spark_runtime::fast_weights:   Shard 55/66 done — GPU memory: 19.95 GB used, 94.60 GB free
2026-05-21T18:32:17.817889Z  INFO spark_runtime::fast_weights: Fast-loading shard 56/66: layers-59.safetensors (18 tensors)
2026-05-21T18:32:17.945386Z  INFO spark_runtime::fast_weights:   Shard 56/66 done — GPU memory: 20.30 GB used, 94.26 GB free
2026-05-21T18:32:17.945457Z  INFO spark_runtime::fast_weights: Fast-loading shard 57/66: layers-6.safetensors (20 tensors)
2026-05-21T18:32:18.070114Z  INFO spark_runtime::fast_weights:   Shard 57/66 done — GPU memory: 20.65 GB used, 93.91 GB free
2026-05-21T18:32:18.070202Z  INFO spark_runtime::fast_weights: Fast-loading shard 58/66: layers-60.safetensors (20 tensors)
2026-05-21T18:32:18.196992Z  INFO spark_runtime::fast_weights:   Shard 58/66 done — GPU memory: 21.01 GB used, 93.55 GB free
2026-05-21T18:32:18.197080Z  INFO spark_runtime::fast_weights: Fast-loading shard 59/66: layers-61.safetensors (20 tensors)
2026-05-21T18:32:18.317470Z  INFO spark_runtime::fast_weights:   Shard 59/66 done — GPU memory: 21.38 GB used, 93.18 GB free
2026-05-21T18:32:18.317559Z  INFO spark_runtime::fast_weights: Fast-loading shard 60/66: layers-62.safetensors (20 tensors)
2026-05-21T18:32:18.445086Z  INFO spark_runtime::fast_weights:   Shard 60/66 done — GPU memory: 21.75 GB used, 92.81 GB free
2026-05-21T18:32:18.445170Z  INFO spark_runtime::fast_weights: Fast-loading shard 61/66: layers-63.safetensors (18 tensors)
2026-05-21T18:32:18.567824Z  INFO spark_runtime::fast_weights:   Shard 61/66 done — GPU memory: 22.10 GB used, 92.46 GB free
2026-05-21T18:32:18.567892Z  INFO spark_runtime::fast_weights: Fast-loading shard 62/66: layers-7.safetensors (18 tensors)
2026-05-21T18:32:18.692554Z  INFO spark_runtime::fast_weights:   Shard 62/66 done — GPU memory: 22.45 GB used, 92.11 GB free
2026-05-21T18:32:18.692625Z  INFO spark_runtime::fast_weights: Fast-loading shard 63/66: layers-8.safetensors (20 tensors)
2026-05-21T18:32:18.826579Z  INFO spark_runtime::fast_weights:   Shard 63/66 done — GPU memory: 22.82 GB used, 91.74 GB free
2026-05-21T18:32:18.826648Z  INFO spark_runtime::fast_weights: Fast-loading shard 64/66: layers-9.safetensors (20 tensors)
2026-05-21T18:32:18.961599Z  INFO spark_runtime::fast_weights:   Shard 64/66 done — GPU memory: 23.19 GB used, 91.37 GB free
2026-05-21T18:32:18.961666Z  INFO spark_runtime::fast_weights: Fast-loading shard 65/66: mtp.safetensors (22 tensors)
2026-05-21T18:32:19.131123Z  INFO spark_runtime::fast_weights:   Shard 65/66 done — GPU memory: 23.63 GB used, 90.93 GB free
2026-05-21T18:32:19.131236Z  INFO spark_runtime::fast_weights: Fast-loading shard 66/66: outside.safetensors (336 tensors)
2026-05-21T18:32:21.128770Z  INFO spark_runtime::fast_weights:   Shard 66/66 done — GPU memory: 30.08 GB used, 84.48 GB free
2026-05-21T18:32:21.128822Z  INFO spark_runtime::fast_weights: Fast-loaded 1606 weight tensors
2026-05-21T18:32:21.128914Z  INFO spark::main_modules::serve_phases::weights: Loaded 1606 weight tensors
2026-05-21T18:32:21.128916Z  INFO spark::main_modules::serve_phases::weights: Weight prefix: model.language_model
2026-05-21T18:32:21.129089Z  INFO spark_model::preflight: Pre-flight checks passed
2026-05-21T18:32:21.129100Z  INFO spark_model::quant_format: QuantFormat: fp8 (block-scaled), 0 ignored module(s)
2026-05-21T18:32:21.129101Z  INFO spark::main_modules::serve: Quantization format: fp8-blockscaled (base variant Fp8Dequanted), ignored globs = 0
2026-05-21T18:32:21.129137Z  INFO spark::main_modules::serve_phases::preflight: GDN chunked prefill reserve: 355 MB (chunk_size=8192, max_seq_len=60000)
2026-05-21T18:32:21.129139Z  INFO spark::main_modules::serve_phases::preflight: Weights: 28.75 GB, estimated free: 85.8 GB, actual free: 84.5 GB (reserve: 9905 MB)
2026-05-21T18:32:21.129144Z  INFO spark::main_modules::serve_phases::kv_cache: Prefill config: ssm_prefill_chunk=8192, args.max_prefill_tokens=8192, prefill_budget=8192, max_batch_tokens=8196
2026-05-21T18:32:21.129148Z  INFO spark::main_modules::serve_phases::build: Prefix caching: ENABLED (radix tree)
2026-05-21T18:32:21.445033Z  INFO spark::main_modules::serve_phases::config: Capping vocab_size from 248320 to 248070 (tokenizer)
2026-05-21T18:32:21.472910Z  INFO spark_model::weight_loader::qwen35_dense: Weight format: Fp8BlockScaled, NVFP4 variant: Fp8Dequanted
2026-05-21T18:32:21.742772Z  INFO spark_model::weight_map::quant_helpers: FP8 dequant stats for model.language_model.layers.0.mlp.gate_proj: min=-0.247070, max=0.406250, mean=0.000006, zeros=878/89128960
2026-05-21T18:32:21.742794Z  INFO spark_model::weight_map::quant_helpers:   First 8 BF16 values: [-0.00091934204, 0.0063171387, -0.008422852, 0.0008544922, 0.0057678223, -0.002105713, 0.023071289, -0.0031585693]
2026-05-21T18:32:21.751200Z  INFO spark_model::weight_map::quant_helpers: BF16 GPU readback verified OK for model.language_model.layers.0.mlp.gate_proj
2026-05-21T18:32:21.774599Z  INFO spark_model::weight_map::loaders_fp8: quantize_to_nvfp4: n=17408 k=5120 total=89128960 global_max=0.406250 scale2=0.00015113 grid1=1024
2026-05-21T18:32:22.055295Z  INFO spark_model::weight_map::quant_helpers: FP8 dequant stats for model.language_model.layers.0.mlp.up_proj: min=-0.127930, max=0.165039, mean=0.000002, zeros=707/89128960
2026-05-21T18:32:22.055310Z  INFO spark_model::weight_map::quant_helpers:   First 8 BF16 values: [0.0022888184, 0.006134033, 0.000667572, -0.013793945, 0.0068969727, 0.00031089783, 0.011474609, -0.0057373047]
2026-05-21T18:32:22.063809Z  INFO spark_model::weight_map::quant_helpers: BF16 GPU readback verified OK for model.language_model.layers.0.mlp.up_proj
2026-05-21T18:32:22.076291Z  INFO spark_model::weight_map::loaders_fp8: quantize_to_nvfp4: n=17408 k=5120 total=89128960 global_max=0.165039 scale2=0.00006140 grid1=1024
2026-05-21T18:32:22.357567Z  INFO spark_model::weight_map::quant_helpers: FP8 dequant stats for model.language_model.layers.0.mlp.down_proj: min=-0.933594, max=0.812500, mean=0.000001, zeros=992/89128960
2026-05-21T18:32:22.357584Z  INFO spark_model::weight_map::quant_helpers:   First 8 BF16 values: [-0.0047302246, -0.0068969727, -0.013793945, -0.006439209, -0.0068969727, 0.017211914, -0.01550293, -0.017211914]
2026-05-21T18:32:22.365971Z  INFO spark_model::weight_map::quant_helpers: BF16 GPU readback verified OK for model.language_model.layers.0.mlp.down_proj
2026-05-21T18:32:22.385974Z  INFO spark_model::weight_map::loaders_fp8: quantize_to_nvfp4: n=5120 k=17408 total=89128960 global_max=0.933594 scale2=0.00034732 grid1=1024
2026-05-21T18:32:22.603146Z  INFO spark_model::weight_map::model_a: dense_keep_f32: promoting model.language_model.layers.0.linear_attn.A_log from BF16 to FP32 ([48])
2026-05-21T18:32:22.603203Z  INFO spark_model::weight_map::model_a: dense_keep_f32: promoting model.language_model.layers.0.linear_attn.dt_bias from BF16 to FP32 ([48])
2026-05-21T18:32:22.682097Z  INFO spark_model::weight_map::loaders_fp8: quantize_to_nvfp4: n=16384 k=5120 total=83886080 global_max=0.451172 scale2=0.00016785 grid1=1024
2026-05-21T18:32:22.778485Z  INFO spark_model::weight_map::loaders_fp8: quantize_to_nvfp4: n=5120 k=6144 total=31457280 global_max=1.250000 scale2=0.00046503 grid1=1024
2026-05-21T18:32:23.719898Z  INFO spark_model::weight_map::model_a: dense_keep_f32: promoting model.language_model.layers.1.linear_attn.A_log from BF16 to FP32 ([48])
2026-05-21T18:32:23.719960Z  INFO spark_model::weight_map::model_a: dense_keep_f32: promoting model.language_model.layers.1.linear_attn.dt_bias from BF16 to FP32 ([48])
2026-05-21T18:32:24.820986Z  INFO spark_model::weight_map::model_a: dense_keep_f32: promoting model.language_model.layers.2.linear_attn.A_log from BF16 to FP32 ([48])
2026-05-21T18:32:24.821045Z  INFO spark_model::weight_map::model_a: dense_keep_f32: promoting model.language_model.layers.2.linear_attn.dt_bias from BF16 to FP32 ([48])
2026-05-21T18:32:27.582032Z  INFO spark_model::weight_map::model_a: dense_keep_f32: promoting model.language_model.layers.4.linear_attn.A_log from BF16 to FP32 ([48])
2026-05-21T18:32:27.582093Z  INFO spark_model::weight_map::model_a: dense_keep_f32: promoting model.language_model.layers.4.linear_attn.dt_bias from BF16 to FP32 ([48])
2026-05-21T18:32:28.692666Z  INFO spark_model::weight_map::model_a: dense_keep_f32: promoting model.language_model.layers.5.linear_attn.A_log from BF16 to FP32 ([48])
2026-05-21T18:32:28.692725Z  INFO spark_model::weight_map::model_a: dense_keep_f32: promoting model.language_model.layers.5.linear_attn.dt_bias from BF16 to FP32 ([48])
2026-05-21T18:32:29.804871Z  INFO spark_model::weight_map::model_a: dense_keep_f32: promoting model.language_model.layers.6.linear_attn.A_log from BF16 to FP32 ([48])
2026-05-21T18:32:29.804931Z  INFO spark_model::weight_map::model_a: dense_keep_f32: promoting model.language_model.layers.6.linear_attn.dt_bias from BF16 to FP32 ([48])
2026-05-21T18:32:31.894618Z  INFO spark_model::weight_map::model_a: dense_keep_f32: promoting model.language_model.layers.8.linear_attn.A_log from BF16 to FP32 ([48])
2026-05-21T18:32:31.894679Z  INFO spark_model::weight_map::model_a: dense_keep_f32: promoting model.language_model.layers.8.linear_attn.dt_bias from BF16 to FP32 ([48])
2026-05-21T18:32:33.002428Z  INFO spark_model::weight_map::model_a: dense_keep_f32: promoting model.language_model.layers.9.linear_attn.A_log from BF16 to FP32 ([48])
2026-05-21T18:32:33.002491Z  INFO spark_model::weight_map::model_a: dense_keep_f32: promoting model.language_model.layers.9.linear_attn.dt_bias from BF16 to FP32 ([48])
2026-05-21T18:32:33.211135Z  INFO spark_model::weight_loader::qwen35_dense: Loaded layers 0..10
2026-05-21T18:32:34.782682Z  INFO spark_model::weight_map::model_a: dense_keep_f32: promoting model.language_model.layers.10.linear_attn.A_log from BF16 to FP32 ([48])
2026-05-21T18:32:34.782741Z  INFO spark_model::weight_map::model_a: dense_keep_f32: promoting model.language_model.layers.10.linear_attn.dt_bias from BF16 to FP32 ([48])
2026-05-21T18:32:36.848063Z  INFO spark_model::weight_map::model_a: dense_keep_f32: promoting model.language_model.layers.12.linear_attn.A_log from BF16 to FP32 ([48])
2026-05-21T18:32:36.848127Z  INFO spark_model::weight_map::model_a: dense_keep_f32: promoting model.language_model.layers.12.linear_attn.dt_bias from BF16 to FP32 ([48])
2026-05-21T18:32:37.956252Z  INFO spark_model::weight_map::model_a: dense_keep_f32: promoting model.language_model.layers.13.linear_attn.A_log from BF16 to FP32 ([48])
2026-05-21T18:32:37.956315Z  INFO spark_model::weight_map::model_a: dense_keep_f32: promoting model.language_model.layers.13.linear_attn.dt_bias from BF16 to FP32 ([48])
2026-05-21T18:32:39.077069Z  INFO spark_model::weight_map::model_a: dense_keep_f32: promoting model.language_model.layers.14.linear_attn.A_log from BF16 to FP32 ([48])
2026-05-21T18:32:39.077126Z  INFO spark_model::weight_map::model_a: dense_keep_f32: promoting model.language_model.layers.14.linear_attn.dt_bias from BF16 to FP32 ([48])
2026-05-21T18:32:41.149462Z  INFO spark_model::weight_map::model_a: dense_keep_f32: promoting model.language_model.layers.16.linear_attn.A_log from BF16 to FP32 ([48])
2026-05-21T18:32:41.149524Z  INFO spark_model::weight_map::model_a: dense_keep_f32: promoting model.language_model.layers.16.linear_attn.dt_bias from BF16 to FP32 ([48])
2026-05-21T18:32:42.267722Z  INFO spark_model::weight_map::model_a: dense_keep_f32: promoting model.language_model.layers.17.linear_attn.A_log from BF16 to FP32 ([48])
2026-05-21T18:32:42.267787Z  INFO spark_model::weight_map::model_a: dense_keep_f32: promoting model.language_model.layers.17.linear_attn.dt_bias from BF16 to FP32 ([48])
2026-05-21T18:32:44.061338Z  INFO spark_model::weight_map::model_a: dense_keep_f32: promoting model.language_model.layers.18.linear_attn.A_log from BF16 to FP32 ([48])
2026-05-21T18:32:44.061401Z  INFO spark_model::weight_map::model_a: dense_keep_f32: promoting model.language_model.layers.18.linear_attn.dt_bias from BF16 to FP32 ([48])
2026-05-21T18:32:45.234267Z  INFO spark_model::weight_loader::qwen35_dense: Loaded layers 0..20
2026-05-21T18:32:46.157421Z  INFO spark_model::weight_map::model_a: dense_keep_f32: promoting model.language_model.layers.20.linear_attn.A_log from BF16 to FP32 ([48])
2026-05-21T18:32:46.157487Z  INFO spark_model::weight_map::model_a: dense_keep_f32: promoting model.language_model.layers.20.linear_attn.dt_bias from BF16 to FP32 ([48])
2026-05-21T18:32:47.293338Z  INFO spark_model::weight_map::model_a: dense_keep_f32: promoting model.language_model.layers.21.linear_attn.A_log from BF16 to FP32 ([48])
2026-05-21T18:32:47.293403Z  INFO spark_model::weight_map::model_a: dense_keep_f32: promoting model.language_model.layers.21.linear_attn.dt_bias from BF16 to FP32 ([48])
2026-05-21T18:32:48.411306Z  INFO spark_model::weight_map::model_a: dense_keep_f32: promoting model.language_model.layers.22.linear_attn.A_log from BF16 to FP32 ([48])
2026-05-21T18:32:48.411372Z  INFO spark_model::weight_map::model_a: dense_keep_f32: promoting model.language_model.layers.22.linear_attn.dt_bias from BF16 to FP32 ([48])
2026-05-21T18:32:50.492866Z  INFO spark_model::weight_map::model_a: dense_keep_f32: promoting model.language_model.layers.24.linear_attn.A_log from BF16 to FP32 ([48])
2026-05-21T18:32:50.492927Z  INFO spark_model::weight_map::model_a: dense_keep_f32: promoting model.language_model.layers.24.linear_attn.dt_bias from BF16 to FP32 ([48])
2026-05-21T18:32:51.614768Z  INFO spark_model::weight_map::model_a: dense_keep_f32: promoting model.language_model.layers.25.linear_attn.A_log from BF16 to FP32 ([48])
2026-05-21T18:32:51.614835Z  INFO spark_model::weight_map::model_a: dense_keep_f32: promoting model.language_model.layers.25.linear_attn.dt_bias from BF16 to FP32 ([48])
2026-05-21T18:32:52.742939Z  INFO spark_model::weight_map::model_a: dense_keep_f32: promoting model.language_model.layers.26.linear_attn.A_log from BF16 to FP32 ([48])
2026-05-21T18:32:52.743005Z  INFO spark_model::weight_map::model_a: dense_keep_f32: promoting model.language_model.layers.26.linear_attn.dt_bias from BF16 to FP32 ([48])
2026-05-21T18:32:54.846732Z  INFO spark_model::weight_map::model_a: dense_keep_f32: promoting model.language_model.layers.28.linear_attn.A_log from BF16 to FP32 ([48])
2026-05-21T18:32:54.846796Z  INFO spark_model::weight_map::model_a: dense_keep_f32: promoting model.language_model.layers.28.linear_attn.dt_bias from BF16 to FP32 ([48])
2026-05-21T18:32:55.989917Z  INFO spark_model::weight_map::model_a: dense_keep_f32: promoting model.language_model.layers.29.linear_attn.A_log from BF16 to FP32 ([48])
2026-05-21T18:32:55.989989Z  INFO spark_model::weight_map::model_a: dense_keep_f32: promoting model.language_model.layers.29.linear_attn.dt_bias from BF16 to FP32 ([48])
2026-05-21T18:32:56.201303Z  INFO spark_model::weight_loader::qwen35_dense: Loaded layers 0..30
2026-05-21T18:32:57.136546Z  INFO spark_model::weight_map::model_a: dense_keep_f32: promoting model.language_model.layers.30.linear_attn.A_log from BF16 to FP32 ([48])
2026-05-21T18:32:57.136616Z  INFO spark_model::weight_map::model_a: dense_keep_f32: promoting model.language_model.layers.30.linear_attn.dt_bias from BF16 to FP32 ([48])
2026-05-21T18:32:59.999805Z  INFO spark_model::weight_map::model_a: dense_keep_f32: promoting model.language_model.layers.32.linear_attn.A_log from BF16 to FP32 ([48])
2026-05-21T18:32:59.999874Z  INFO spark_model::weight_map::model_a: dense_keep_f32: promoting model.language_model.layers.32.linear_attn.dt_bias from BF16 to FP32 ([48])
2026-05-21T18:33:01.137477Z  INFO spark_model::weight_map::model_a: dense_keep_f32: promoting model.language_model.layers.33.linear_attn.A_log from BF16 to FP32 ([48])
2026-05-21T18:33:01.137544Z  INFO spark_model::weight_map::model_a: dense_keep_f32: promoting model.language_model.layers.33.linear_attn.dt_bias from BF16 to FP32 ([48])
2026-05-21T18:33:02.273445Z  INFO spark_model::weight_map::model_a: dense_keep_f32: promoting model.language_model.layers.34.linear_attn.A_log from BF16 to FP32 ([48])
2026-05-21T18:33:02.273515Z  INFO spark_model::weight_map::model_a: dense_keep_f32: promoting model.language_model.layers.34.linear_attn.dt_bias from BF16 to FP32 ([48])
2026-05-21T18:33:05.059622Z  INFO spark_model::weight_map::model_a: dense_keep_f32: promoting model.language_model.layers.36.linear_attn.A_log from BF16 to FP32 ([48])
2026-05-21T18:33:05.059695Z  INFO spark_model::weight_map::model_a: dense_keep_f32: promoting model.language_model.layers.36.linear_attn.dt_bias from BF16 to FP32 ([48])
2026-05-21T18:33:06.220047Z  INFO spark_model::weight_map::model_a: dense_keep_f32: promoting model.language_model.layers.37.linear_attn.A_log from BF16 to FP32 ([48])
2026-05-21T18:33:06.220120Z  INFO spark_model::weight_map::model_a: dense_keep_f32: promoting model.language_model.layers.37.linear_attn.dt_bias from BF16 to FP32 ([48])
2026-05-21T18:33:07.365617Z  INFO spark_model::weight_map::model_a: dense_keep_f32: promoting model.language_model.layers.38.linear_attn.A_log from BF16 to FP32 ([48])
2026-05-21T18:33:07.365684Z  INFO spark_model::weight_map::model_a: dense_keep_f32: promoting model.language_model.layers.38.linear_attn.dt_bias from BF16 to FP32 ([48])
2026-05-21T18:33:08.570451Z  INFO spark_model::weight_loader::qwen35_dense: Loaded layers 0..40
2026-05-21T18:33:09.518997Z  INFO spark_model::weight_map::model_a: dense_keep_f32: promoting model.language_model.layers.40.linear_attn.A_log from BF16 to FP32 ([48])
2026-05-21T18:33:09.519065Z  INFO spark_model::weight_map::model_a: dense_keep_f32: promoting model.language_model.layers.40.linear_attn.dt_bias from BF16 to FP32 ([48])
2026-05-21T18:33:10.670280Z  INFO spark_model::weight_map::model_a: dense_keep_f32: promoting model.language_model.layers.41.linear_attn.A_log from BF16 to FP32 ([48])
2026-05-21T18:33:10.670344Z  INFO spark_model::weight_map::model_a: dense_keep_f32: promoting model.language_model.layers.41.linear_attn.dt_bias from BF16 to FP32 ([48])
2026-05-21T18:33:11.825189Z  INFO spark_model::weight_map::model_a: dense_keep_f32: promoting model.language_model.layers.42.linear_attn.A_log from BF16 to FP32 ([48])
2026-05-21T18:33:11.825257Z  INFO spark_model::weight_map::model_a: dense_keep_f32: promoting model.language_model.layers.42.linear_attn.dt_bias from BF16 to FP32 ([48])
2026-05-21T18:33:13.929410Z  INFO spark_model::weight_map::model_a: dense_keep_f32: promoting model.language_model.layers.44.linear_attn.A_log from BF16 to FP32 ([48])
2026-05-21T18:33:13.929478Z  INFO spark_model::weight_map::model_a: dense_keep_f32: promoting model.language_model.layers.44.linear_attn.dt_bias from BF16 to FP32 ([48])
2026-05-21T18:33:15.627156Z  INFO spark_model::weight_map::model_a: dense_keep_f32: promoting model.language_model.layers.45.linear_attn.A_log from BF16 to FP32 ([48])
2026-05-21T18:33:15.627223Z  INFO spark_model::weight_map::model_a: dense_keep_f32: promoting model.language_model.layers.45.linear_attn.dt_bias from BF16 to FP32 ([48])
2026-05-21T18:33:16.783716Z  INFO spark_model::weight_map::model_a: dense_keep_f32: promoting model.language_model.layers.46.linear_attn.A_log from BF16 to FP32 ([48])
2026-05-21T18:33:16.783787Z  INFO spark_model::weight_map::model_a: dense_keep_f32: promoting model.language_model.layers.46.linear_attn.dt_bias from BF16 to FP32 ([48])
2026-05-21T18:33:18.933185Z  INFO spark_model::weight_map::model_a: dense_keep_f32: promoting model.language_model.layers.48.linear_attn.A_log from BF16 to FP32 ([48])
2026-05-21T18:33:18.933257Z  INFO spark_model::weight_map::model_a: dense_keep_f32: promoting model.language_model.layers.48.linear_attn.dt_bias from BF16 to FP32 ([48])
2026-05-21T18:33:20.068462Z  INFO spark_model::weight_map::model_a: dense_keep_f32: promoting model.language_model.layers.49.linear_attn.A_log from BF16 to FP32 ([48])
2026-05-21T18:33:20.068528Z  INFO spark_model::weight_map::model_a: dense_keep_f32: promoting model.language_model.layers.49.linear_attn.dt_bias from BF16 to FP32 ([48])
2026-05-21T18:33:20.277069Z  INFO spark_model::weight_loader::qwen35_dense: Loaded layers 0..50
2026-05-21T18:33:21.214257Z  INFO spark_model::weight_map::model_a: dense_keep_f32: promoting model.language_model.layers.50.linear_attn.A_log from BF16 to FP32 ([48])
2026-05-21T18:33:21.214322Z  INFO spark_model::weight_map::model_a: dense_keep_f32: promoting model.language_model.layers.50.linear_attn.dt_bias from BF16 to FP32 ([48])
2026-05-21T18:33:23.363720Z  INFO spark_model::weight_map::model_a: dense_keep_f32: promoting model.language_model.layers.52.linear_attn.A_log from BF16 to FP32 ([48])
2026-05-21T18:33:23.363792Z  INFO spark_model::weight_map::model_a: dense_keep_f32: promoting model.language_model.layers.52.linear_attn.dt_bias from BF16 to FP32 ([48])
2026-05-21T18:33:24.516443Z  INFO spark_model::weight_map::model_a: dense_keep_f32: promoting model.language_model.layers.53.linear_attn.A_log from BF16 to FP32 ([48])
2026-05-21T18:33:24.516514Z  INFO spark_model::weight_map::model_a: dense_keep_f32: promoting model.language_model.layers.53.linear_attn.dt_bias from BF16 to FP32 ([48])
2026-05-21T18:33:26.348632Z  INFO spark_model::weight_map::model_a: dense_keep_f32: promoting model.language_model.layers.54.linear_attn.A_log from BF16 to FP32 ([48])
2026-05-21T18:33:26.348701Z  INFO spark_model::weight_map::model_a: dense_keep_f32: promoting model.language_model.layers.54.linear_attn.dt_bias from BF16 to FP32 ([48])
2026-05-21T18:33:28.442408Z  INFO spark_model::weight_map::model_a: dense_keep_f32: promoting model.language_model.layers.56.linear_attn.A_log from BF16 to FP32 ([48])
2026-05-21T18:33:28.442483Z  INFO spark_model::weight_map::model_a: dense_keep_f32: promoting model.language_model.layers.56.linear_attn.dt_bias from BF16 to FP32 ([48])
2026-05-21T18:33:29.578669Z  INFO spark_model::weight_map::model_a: dense_keep_f32: promoting model.language_model.layers.57.linear_attn.A_log from BF16 to FP32 ([48])
2026-05-21T18:33:29.578738Z  INFO spark_model::weight_map::model_a: dense_keep_f32: promoting model.language_model.layers.57.linear_attn.dt_bias from BF16 to FP32 ([48])
2026-05-21T18:33:30.707105Z  INFO spark_model::weight_map::model_a: dense_keep_f32: promoting model.language_model.layers.58.linear_attn.A_log from BF16 to FP32 ([48])
2026-05-21T18:33:30.707175Z  INFO spark_model::weight_map::model_a: dense_keep_f32: promoting model.language_model.layers.58.linear_attn.dt_bias from BF16 to FP32 ([48])
2026-05-21T18:33:31.885579Z  INFO spark_model::weight_loader::qwen35_dense: Loaded layers 0..60
2026-05-21T18:33:32.802504Z  INFO spark_model::weight_map::model_a: dense_keep_f32: promoting model.language_model.layers.60.linear_attn.A_log from BF16 to FP32 ([48])
2026-05-21T18:33:32.802572Z  INFO spark_model::weight_map::model_a: dense_keep_f32: promoting model.language_model.layers.60.linear_attn.dt_bias from BF16 to FP32 ([48])
2026-05-21T18:33:33.927881Z  INFO spark_model::weight_map::model_a: dense_keep_f32: promoting model.language_model.layers.61.linear_attn.A_log from BF16 to FP32 ([48])
2026-05-21T18:33:33.927949Z  INFO spark_model::weight_map::model_a: dense_keep_f32: promoting model.language_model.layers.61.linear_attn.dt_bias from BF16 to FP32 ([48])
2026-05-21T18:33:35.055986Z  INFO spark_model::weight_map::model_a: dense_keep_f32: promoting model.language_model.layers.62.linear_attn.A_log from BF16 to FP32 ([48])
2026-05-21T18:33:35.056052Z  INFO spark_model::weight_map::model_a: dense_keep_f32: promoting model.language_model.layers.62.linear_attn.dt_bias from BF16 to FP32 ([48])
2026-05-21T18:33:36.242142Z  INFO spark_model::weight_loader::qwen35_dense: Qwen3.5 dense weight loader: 64 layers (16 attention, 48 SSM, dense FFN)
2026-05-21T18:33:36.290911Z  INFO spark_model::factory::build: LM head quantized to NVFP4 (vocab=248070)
2026-05-21T18:33:36.361567Z  INFO spark_runtime::buffers: Buffer arena: 8196 tokens × 2309.3 MB total (attn_out=96.0MB, ssm_deint=256.1MB, kv_lora_rank=0)
2026-05-21T18:33:36.361658Z  INFO spark_model::factory::build: KV cache (post-construction): 43.4 GB free, 33.7 GB allocatable, 30360 blocks × 16 tok/block = 485760 max tokens
2026-05-21T18:33:37.765391Z  INFO spark_runtime::kv_cache::paged_impl: KV cache: 30360 blocks × 16 layers × 65536 bytes/block = 29.6 GB total
2026-05-21T18:33:37.766244Z  INFO spark_model::model::impl_a1: TransformerModel: 64 layers, vocab=248070, hidden=5120
2026-05-21T18:33:37.801822Z  INFO spark_model::model::ssm_pool: SSM state pool: 4 slots × 48 layers = 606 MB
2026-05-21T18:33:37.891715Z  INFO spark_model::model::ssm_snapshot: SSM snapshot pool (Marconi): 16 slots × 48 layers = 2424 MB
2026-05-21T18:33:37.891726Z  INFO spark_model::model::impl_a1: Marconi intermediate checkpoints: every 256 blocks (4096 tokens at block_size=16)
2026-05-21T18:33:37.893118Z  INFO spark_model::model::impl_a1: Pinned metadata staging: 501 KB
2026-05-21T18:33:37.906972Z  INFO spark_model::model::impl_a1: GDN prefill buffers: 355 MB for 8196 tokens (chunked SSM prefill)
2026-05-21T18:33:37.908998Z  INFO spark::main_modules::serve_phases::runtime: EOS tokens (from generation_config.json): [248046, 248044]
2026-05-21T18:33:37.909011Z  INFO spark::main_modules::serve_phases::runtime: Default sampling: temperature=1, top_k=20, top_p=0.95, top_n_sigma=1, min_p=0
2026-05-21T18:33:38.178453Z  INFO spark::tokenizer::jinja_helpers: Using override Jinja template from ./jinja-templates/qwen3_5.jinja (8079 chars)
2026-05-21T18:33:38.180656Z  INFO spark::tokenizer::chat_impl: Loaded tokenizer from /root/.cache/huggingface/hub/models--Qwen--Qwen3.6-27B-FP8/snapshots/e89b16ebf1988b3d6befa7de50abc2d76f26eb09/tokenizer.json
2026-05-21T18:33:38.228523Z  INFO spark::main_modules::serve_phases::tokenizer_runtime: Reasoning parser: qwen (auto-detected from model_type 'qwen3_5')
2026-05-21T18:33:38.228608Z  INFO spark::main_modules::serve_phases::tokenizer_runtime: Thinking end token: 248069 (</think>)
2026-05-21T18:33:38.228609Z  INFO spark::main_modules::serve_phases::tokenizer_runtime: Thinking start token: 248068 (<think>)
2026-05-21T18:33:38.228614Z  INFO spark::main_modules::serve_phases::tokenizer_runtime: ChatML role-boundary hard stop: <|im_start|> (id 248045) registered
2026-05-21T18:33:38.228684Z  INFO spark::main_modules::serve_phases::tokenizer_runtime: Reflection suppression tokens: 7 IDs resolved
2026-05-21T18:33:38.228700Z  INFO spark::main_modules::serve_phases::tokenizer_runtime: Tool call start token: 248058 (<tool_call>)
2026-05-21T18:33:38.228703Z  INFO spark::main_modules::serve_phases::tokenizer_runtime: Tool call end token: 248059 (</tool_call>)
2026-05-21T18:33:38.479970Z  INFO spark::grammar::engine: Grammar: detected tokenizer vocab_type=byte_level, add_prefix_space=false
2026-05-21T18:33:38.595799Z  INFO spark::main_modules::serve_phases::tokenizer_runtime: Grammar engine initialized (vocab_size=248070, vocab_type=auto-detected from tokenizer)
2026-05-21T18:33:38.596030Z  INFO spark::main_modules::serve: Scheduling policy: SLAI (TBT deadline=100ms)
2026-05-21T18:33:38.598203Z  INFO spark::main_modules::serve_phases::runtime: Tool call parser: qwen3_coder (auto-detected from model_type 'qwen3_5')
2026-05-21T18:33:38.598209Z  INFO spark::main_modules::serve_phases::runtime: Tool call parser: 'qwen3_coder' has registered XGrammar grammar — constrained decoding ENABLED for tool requests
2026-05-21T18:33:38.598216Z  INFO spark::main_modules::serve_phases::runtime: Response store: max_entries=10000, ttl=86400s, persist=memory-only
2026-05-21T18:33:38.598221Z  WARN spark::main_modules::serve: --auth-token sets the bearer token via the command line; the value is visible to other local users via `ps`/`/proc/<pid>/cmdline`. Use --auth-tokens-file with permissions 0600 in production.
2026-05-21T18:33:38.598223Z  INFO spark::main_modules::serve: auth: require_auth=ON (1 bearer token loaded)
2026-05-21T18:33:38.598225Z  INFO spark::main_modules::serve_phases::runtime: Model behavior: thinking disabled when tools active (MODEL.toml)
2026-05-21T18:33:38.598227Z  INFO spark::main_modules::serve_phases::runtime: Model behavior: max_thinking_budget=512, thinking_default=false
2026-05-21T18:33:38.598228Z  INFO spark::main_modules::serve_phases::runtime: Model behavior: content-loop watchdog ENABLED (period-8…64 repetition detector)
2026-05-21T18:33:38.598369Z  WARN spark::main_modules::serve_router: Atlas is listening on 0.0.0.0:8000 — reachable from any host on the network. If this machine is on a shared LAN or has a public IP, pass --bind 127.0.0.1 (or set --require-auth and a real firewall) before accepting traffic.
2026-05-21T18:33:38.598371Z  INFO spark::main_modules::serve_router: Listening on 0.0.0.0:8000
2026-05-21T18:33:38.598438Z  INFO spark::scheduler: Scheduler started (batched mode, max_batch=4, mtp=false, ngram=false, num_drafts=0, policy=slai, chunked_prefill=true, max_prefill_tokens=8192)
2026-05-21T18:33:38.599796Z  INFO spark::scheduler: Swap space: 3 GB at /tmp/atlas-swap/
2026-05-21T18:36:53.469187Z  INFO spark::api::chat: Request: model=Qwen3.6-27B-FP8, messages=2, tools=0, tools_active=false, tool_choice=None, stream=true, temp=None, max_tokens=4096, freq_pen=None, rep_pen=None
2026-05-21T18:36:53.493265Z  INFO spark::api::chat: Session 0xecacf2ef12947de3: 14981 prompt tokens, tools=false
2026-05-21T18:36:53.493477Z  INFO spark::scheduler::prefill_a_step: Chunked prefill start: 14981 prompt tokens, chunk_size=8196, max_tokens=4096
2026-05-21T18:36:53.576392Z  INFO spark_model::layers::qwen3_ssm::trait_prefill: SSM prefill ENTRY: k=8196 h=5120
2026-05-21T18:36:53.618694Z  INFO spark_model::layers::qwen3_ssm::trait_prefill: SSM prefill ENTRY: k=8196 h=5120
2026-05-21T18:36:54.375891Z  INFO spark_model::layers::qwen3_ssm::trait_prefill: SSM prefill ENTRY: k=8196 h=5120
2026-05-21T18:36:55.165770Z  INFO spark_model::layers::qwen3_ssm::trait_prefill: SSM prefill ENTRY: k=8196 h=5120
2026-05-21T18:36:56.869065Z  INFO spark_model::layers::qwen3_ssm::trait_prefill: SSM prefill ENTRY: k=8196 h=5120
2026-05-21T18:36:57.659832Z  INFO spark_model::layers::qwen3_ssm::trait_prefill: SSM prefill ENTRY: k=8196 h=5120
2026-05-21T18:36:58.448969Z  INFO spark_model::layers::qwen3_ssm::trait_prefill: SSM prefill ENTRY: k=8196 h=5120
2026-05-21T18:37:00.153222Z  INFO spark_model::layers::qwen3_ssm::trait_prefill: SSM prefill ENTRY: k=8196 h=5120
2026-05-21T18:37:00.941245Z  INFO spark_model::layers::qwen3_ssm::trait_prefill: SSM prefill ENTRY: k=8196 h=5120
2026-05-21T18:37:01.728018Z  INFO spark_model::layers::qwen3_ssm::trait_prefill: SSM prefill ENTRY: k=8196 h=5120
2026-05-21T18:37:03.437598Z  INFO spark_model::layers::qwen3_ssm::trait_prefill: SSM prefill ENTRY: k=8196 h=5120
2026-05-21T18:37:04.226088Z  INFO spark_model::layers::qwen3_ssm::trait_prefill: SSM prefill ENTRY: k=8196 h=5120
2026-05-21T18:37:05.015705Z  INFO spark_model::layers::qwen3_ssm::trait_prefill: SSM prefill ENTRY: k=8196 h=5120
2026-05-21T18:37:06.730023Z  INFO spark_model::layers::qwen3_ssm::trait_prefill: SSM prefill ENTRY: k=8196 h=5120
2026-05-21T18:37:07.518325Z  INFO spark_model::layers::qwen3_ssm::trait_prefill: SSM prefill ENTRY: k=8196 h=5120
2026-05-21T18:37:08.307760Z  INFO spark_model::layers::qwen3_ssm::trait_prefill: SSM prefill ENTRY: k=8196 h=5120
2026-05-21T18:37:10.016770Z  INFO spark_model::layers::qwen3_ssm::trait_prefill: SSM prefill ENTRY: k=8196 h=5120
2026-05-21T18:37:10.804941Z  INFO spark_model::layers::qwen3_ssm::trait_prefill: SSM prefill ENTRY: k=8196 h=5120
2026-05-21T18:37:11.593178Z  INFO spark_model::layers::qwen3_ssm::trait_prefill: SSM prefill ENTRY: k=8196 h=5120
2026-05-21T18:37:13.299361Z  INFO spark_model::layers::qwen3_ssm::trait_prefill: SSM prefill ENTRY: k=8196 h=5120
2026-05-21T18:37:14.085084Z  INFO spark_model::layers::qwen3_ssm::trait_prefill: SSM prefill ENTRY: k=8196 h=5120
2026-05-21T18:37:14.873835Z  INFO spark_model::layers::qwen3_ssm::trait_prefill: SSM prefill ENTRY: k=8196 h=5120
2026-05-21T18:37:16.581867Z  INFO spark_model::layers::qwen3_ssm::trait_prefill: SSM prefill ENTRY: k=8196 h=5120
2026-05-21T18:37:17.369273Z  INFO spark_model::layers::qwen3_ssm::trait_prefill: SSM prefill ENTRY: k=8196 h=5120
2026-05-21T18:37:18.158287Z  INFO spark_model::layers::qwen3_ssm::trait_prefill: SSM prefill ENTRY: k=8196 h=5120
2026-05-21T18:37:19.863890Z  INFO spark_model::layers::qwen3_ssm::trait_prefill: SSM prefill ENTRY: k=8196 h=5120
2026-05-21T18:37:20.650808Z  INFO spark_model::layers::qwen3_ssm::trait_prefill: SSM prefill ENTRY: k=8196 h=5120
2026-05-21T18:37:21.439791Z  INFO spark_model::layers::qwen3_ssm::trait_prefill: SSM prefill ENTRY: k=8196 h=5120
2026-05-21T18:37:23.142019Z  INFO spark_model::layers::qwen3_ssm::trait_prefill: SSM prefill ENTRY: k=8196 h=5120
2026-05-21T18:37:23.927508Z  INFO spark_model::layers::qwen3_ssm::trait_prefill: SSM prefill ENTRY: k=8196 h=5120
2026-05-21T18:37:24.713523Z  INFO spark_model::layers::qwen3_ssm::trait_prefill: SSM prefill ENTRY: k=8196 h=5120
2026-05-21T18:37:26.416509Z  INFO spark_model::layers::qwen3_ssm::trait_prefill: SSM prefill ENTRY: k=8196 h=5120
2026-05-21T18:37:27.201607Z  INFO spark_model::layers::qwen3_ssm::trait_prefill: SSM prefill ENTRY: k=8196 h=5120
2026-05-21T18:37:27.990036Z  INFO spark_model::layers::qwen3_ssm::trait_prefill: SSM prefill ENTRY: k=8196 h=5120
2026-05-21T18:37:29.693705Z  INFO spark_model::layers::qwen3_ssm::trait_prefill: SSM prefill ENTRY: k=8196 h=5120
2026-05-21T18:37:30.481117Z  INFO spark_model::layers::qwen3_ssm::trait_prefill: SSM prefill ENTRY: k=8196 h=5120
2026-05-21T18:37:31.268392Z  INFO spark_model::layers::qwen3_ssm::trait_prefill: SSM prefill ENTRY: k=8196 h=5120
2026-05-21T18:37:32.982109Z  INFO spark_model::layers::qwen3_ssm::trait_prefill: SSM prefill ENTRY: k=8196 h=5120
2026-05-21T18:37:33.770497Z  INFO spark_model::layers::qwen3_ssm::trait_prefill: SSM prefill ENTRY: k=8196 h=5120
2026-05-21T18:37:34.554317Z  INFO spark_model::layers::qwen3_ssm::trait_prefill: SSM prefill ENTRY: k=8196 h=5120
2026-05-21T18:37:36.251969Z  INFO spark_model::layers::qwen3_ssm::trait_prefill: SSM prefill ENTRY: k=8196 h=5120
2026-05-21T18:37:37.040528Z  INFO spark_model::layers::qwen3_ssm::trait_prefill: SSM prefill ENTRY: k=8196 h=5120
2026-05-21T18:37:37.828054Z  INFO spark_model::layers::qwen3_ssm::trait_prefill: SSM prefill ENTRY: k=8196 h=5120
2026-05-21T18:37:39.531818Z  INFO spark_model::layers::qwen3_ssm::trait_prefill: SSM prefill ENTRY: k=8196 h=5120
2026-05-21T18:37:40.320356Z  INFO spark_model::layers::qwen3_ssm::trait_prefill: SSM prefill ENTRY: k=8196 h=5120
2026-05-21T18:37:41.111659Z  INFO spark_model::layers::qwen3_ssm::trait_prefill: SSM prefill ENTRY: k=8196 h=5120
2026-05-21T18:37:42.818344Z  INFO spark_model::layers::qwen3_ssm::trait_prefill: SSM prefill ENTRY: k=8196 h=5120
2026-05-21T18:37:43.604893Z  INFO spark_model::layers::qwen3_ssm::trait_prefill: SSM prefill ENTRY: k=8196 h=5120
2026-05-21T18:37:44.396631Z  INFO spark_model::model::trait_impl::prefill_b::save_checkpoint: Intermediate SSM checkpoint saved at token 8196 (snapshot_id 0, block 512)
2026-05-21T18:37:44.433860Z  INFO spark::scheduler::phase_start_prefills: Prefill chunk 0/14981: 8196/14981 tokens
2026-05-21T18:37:46.151922Z  INFO spark_model::layers::qwen3_ssm::trait_prefill: SSM prefill ENTRY: k=6785 h=5120
2026-05-21T18:37:46.152934Z  INFO spark_model::layers::qwen3_ssm::trait_prefill: SSM prefill ENTRY: k=6785 h=5120
2026-05-21T18:37:46.812447Z  INFO spark_model::layers::qwen3_ssm::trait_prefill: SSM prefill ENTRY: k=6785 h=5120
2026-05-21T18:37:47.467191Z  INFO spark_model::layers::qwen3_ssm::trait_prefill: SSM prefill ENTRY: k=6785 h=5120
2026-05-21T18:37:48.934607Z  INFO spark_model::layers::qwen3_ssm::trait_prefill: SSM prefill ENTRY: k=6785 h=5120
2026-05-21T18:37:49.589794Z  INFO spark_model::layers::qwen3_ssm::trait_prefill: SSM prefill ENTRY: k=6785 h=5120
2026-05-21T18:37:50.247358Z  INFO spark_model::layers::qwen3_ssm::trait_prefill: SSM prefill ENTRY: k=6785 h=5120
2026-05-21T18:37:51.714074Z  INFO spark_model::layers::qwen3_ssm::trait_prefill: SSM prefill ENTRY: k=6785 h=5120
2026-05-21T18:37:52.368594Z  INFO spark_model::layers::qwen3_ssm::trait_prefill: SSM prefill ENTRY: k=6785 h=5120
2026-05-21T18:37:53.022229Z  INFO spark_model::layers::qwen3_ssm::trait_prefill: SSM prefill ENTRY: k=6785 h=5120
2026-05-21T18:37:54.491102Z  INFO spark_model::layers::qwen3_ssm::trait_prefill: SSM prefill ENTRY: k=6785 h=5120
2026-05-21T18:37:55.144333Z  INFO spark_model::layers::qwen3_ssm::trait_prefill: SSM prefill ENTRY: k=6785 h=5120
2026-05-21T18:37:55.798273Z  INFO spark_model::layers::qwen3_ssm::trait_prefill: SSM prefill ENTRY: k=6785 h=5120
2026-05-21T18:37:57.268750Z  INFO spark_model::layers::qwen3_ssm::trait_prefill: SSM prefill ENTRY: k=6785 h=5120
2026-05-21T18:37:57.923961Z  INFO spark_model::layers::qwen3_ssm::trait_prefill: SSM prefill ENTRY: k=6785 h=5120
2026-05-21T18:37:58.581264Z  INFO spark_model::layers::qwen3_ssm::trait_prefill: SSM prefill ENTRY: k=6785 h=5120
2026-05-21T18:38:00.055968Z  INFO spark_model::layers::qwen3_ssm::trait_prefill: SSM prefill ENTRY: k=6785 h=5120
2026-05-21T18:38:00.708479Z  INFO spark_model::layers::qwen3_ssm::trait_prefill: SSM prefill ENTRY: k=6785 h=5120
2026-05-21T18:38:01.361766Z  INFO spark_model::layers::qwen3_ssm::trait_prefill: SSM prefill ENTRY: k=6785 h=5120
2026-05-21T18:38:02.830043Z  INFO spark_model::layers::qwen3_ssm::trait_prefill: SSM prefill ENTRY: k=6785 h=5120
2026-05-21T18:38:03.483417Z  INFO spark_model::layers::qwen3_ssm::trait_prefill: SSM prefill ENTRY: k=6785 h=5120
2026-05-21T18:38:04.135950Z  INFO spark_model::layers::qwen3_ssm::trait_prefill: SSM prefill ENTRY: k=6785 h=5120
2026-05-21T18:38:05.608109Z  INFO spark_model::layers::qwen3_ssm::trait_prefill: SSM prefill ENTRY: k=6785 h=5120
2026-05-21T18:38:06.261245Z  INFO spark_model::layers::qwen3_ssm::trait_prefill: SSM prefill ENTRY: k=6785 h=5120
2026-05-21T18:38:06.914107Z  INFO spark_model::layers::qwen3_ssm::trait_prefill: SSM prefill ENTRY: k=6785 h=5120
2026-05-21T18:38:08.384921Z  INFO spark_model::layers::qwen3_ssm::trait_prefill: SSM prefill ENTRY: k=6785 h=5120
2026-05-21T18:38:09.037275Z  INFO spark_model::layers::qwen3_ssm::trait_prefill: SSM prefill ENTRY: k=6785 h=5120
2026-05-21T18:38:09.692390Z  INFO spark_model::layers::qwen3_ssm::trait_prefill: SSM prefill ENTRY: k=6785 h=5120
2026-05-21T18:38:11.158556Z  INFO spark_model::layers::qwen3_ssm::trait_prefill: SSM prefill ENTRY: k=6785 h=5120
2026-05-21T18:38:11.809992Z  INFO spark_model::layers::qwen3_ssm::trait_prefill: SSM prefill ENTRY: k=6785 h=5120
2026-05-21T18:38:12.467579Z  INFO spark_model::layers::qwen3_ssm::trait_prefill: SSM prefill ENTRY: k=6785 h=5120
2026-05-21T18:38:13.938107Z  INFO spark_model::layers::qwen3_ssm::trait_prefill: SSM prefill ENTRY: k=6785 h=5120
2026-05-21T18:38:14.589642Z  INFO spark_model::layers::qwen3_ssm::trait_prefill: SSM prefill ENTRY: k=6785 h=5120
2026-05-21T18:38:15.245088Z  INFO spark_model::layers::qwen3_ssm::trait_prefill: SSM prefill ENTRY: k=6785 h=5120
2026-05-21T18:38:16.711768Z  INFO spark_model::layers::qwen3_ssm::trait_prefill: SSM prefill ENTRY: k=6785 h=5120
2026-05-21T18:38:17.366353Z  INFO spark_model::layers::qwen3_ssm::trait_prefill: SSM prefill ENTRY: k=6785 h=5120
2026-05-21T18:38:18.021346Z  INFO spark_model::layers::qwen3_ssm::trait_prefill: SSM prefill ENTRY: k=6785 h=5120
2026-05-21T18:38:19.493204Z  INFO spark_model::layers::qwen3_ssm::trait_prefill: SSM prefill ENTRY: k=6785 h=5120
2026-05-21T18:38:20.147086Z  INFO spark_model::layers::qwen3_ssm::trait_prefill: SSM prefill ENTRY: k=6785 h=5120
2026-05-21T18:38:20.801520Z  INFO spark_model::layers::qwen3_ssm::trait_prefill: SSM prefill ENTRY: k=6785 h=5120
2026-05-21T18:38:22.264001Z  INFO spark_model::layers::qwen3_ssm::trait_prefill: SSM prefill ENTRY: k=6785 h=5120
2026-05-21T18:38:22.919376Z  INFO spark_model::layers::qwen3_ssm::trait_prefill: SSM prefill ENTRY: k=6785 h=5120
2026-05-21T18:38:23.574987Z  INFO spark_model::layers::qwen3_ssm::trait_prefill: SSM prefill ENTRY: k=6785 h=5120
2026-05-21T18:38:25.044894Z  INFO spark_model::layers::qwen3_ssm::trait_prefill: SSM prefill ENTRY: k=6785 h=5120
2026-05-21T18:38:25.701852Z  INFO spark_model::layers::qwen3_ssm::trait_prefill: SSM prefill ENTRY: k=6785 h=5120
2026-05-21T18:38:26.356308Z  INFO spark_model::layers::qwen3_ssm::trait_prefill: SSM prefill ENTRY: k=6785 h=5120
2026-05-21T18:38:27.827574Z  INFO spark_model::layers::qwen3_ssm::trait_prefill: SSM prefill ENTRY: k=6785 h=5120
2026-05-21T18:38:28.484556Z  INFO spark_model::layers::qwen3_ssm::trait_prefill: SSM prefill ENTRY: k=6785 h=5120
2026-05-21T18:38:29.140363Z  INFO spark_model::model::trait_impl::prefill_b::finalize_last: Saved SSM snapshot 1 for 14981 tokens (937 blocks) [chunk]
2026-05-21T18:38:29.140526Z  INFO spark::scheduler::phase_continue_prefills: Prefill chunk 14981/14981 tokens
2026-05-21T18:38:30.626581Z  INFO spark::scheduler::phase_continue_prefills: Prefill first token: 13314
2026-05-21T18:38:30.626633Z  INFO spark_model::model::trait_impl::decode_a: CUDA graph capture: starting for 64 layers
2026-05-21T18:38:30.631415Z  INFO spark_model::model::trait_impl::decode_a: CUDA graph captured successfully for slot=0 (handle=261058314791616)
2026-05-21T18:38:41.777275Z  INFO spark::scheduler::lifecycle: Done: 127 tokens (stop) 11.4 tok/s, TTFT=97133.1ms
2026-05-21T18:38:42.058550Z  INFO spark::api::chat: Request: model=Qwen3.6-27B-FP8, messages=4, tools=0, tools_active=false, tool_choice=None, stream=true, temp=None, max_tokens=4096, freq_pen=None, rep_pen=None
2026-05-21T18:38:42.079643Z  INFO spark::api::chat: Session 0xecacf2ef12947de3: 15707 prompt tokens, tools=false
2026-05-21T18:38:42.080644Z  INFO spark::scheduler::prefill_a_step: Chunked prefill start: 15707 prompt tokens, chunk_size=8196, max_tokens=4096
2026-05-21T18:38:42.083865Z  INFO spark_model::model::trait_impl::prefill_b::prefix_lookup: Marconi intermediate hit: restored from checkpoint at token 8196 (skipping 8196 tokens, recomputing 6780 SSM tokens to match point 14976)
2026-05-21T18:38:42.083884Z  INFO spark::scheduler::phase_start_prefills: Prefill chunk 0/15707: 8196/15707 tokens
2026-05-21T18:38:42.104313Z  INFO spark_model::layers::qwen3_ssm::trait_prefill: SSM prefill ENTRY: k=7511 h=5120
2026-05-21T18:38:42.105456Z  INFO spark_model::layers::qwen3_ssm::trait_prefill: SSM prefill ENTRY: k=7511 h=5120
2026-05-21T18:38:42.830919Z  INFO spark_model::layers::qwen3_ssm::trait_prefill: SSM prefill ENTRY: k=7511 h=5120
2026-05-21T18:38:43.554319Z  INFO spark_model::layers::qwen3_ssm::trait_prefill: SSM prefill ENTRY: k=7511 h=5120
2026-05-21T18:38:45.181429Z  INFO spark_model::layers::qwen3_ssm::trait_prefill: SSM prefill ENTRY: k=7511 h=5120
2026-05-21T18:38:45.907197Z  INFO spark_model::layers::qwen3_ssm::trait_prefill: SSM prefill ENTRY: k=7511 h=5120
2026-05-21T18:38:46.632470Z  INFO spark_model::layers::qwen3_ssm::trait_prefill: SSM prefill ENTRY: k=7511 h=5120
2026-05-21T18:38:48.257822Z  INFO spark_model::layers::qwen3_ssm::trait_prefill: SSM prefill ENTRY: k=7511 h=5120
2026-05-21T18:38:48.979855Z  INFO spark_model::layers::qwen3_ssm::trait_prefill: SSM prefill ENTRY: k=7511 h=5120
2026-05-21T18:38:49.702831Z  INFO spark_model::layers::qwen3_ssm::trait_prefill: SSM prefill ENTRY: k=7511 h=5120
2026-05-21T18:38:51.332548Z  INFO spark_model::layers::qwen3_ssm::trait_prefill: SSM prefill ENTRY: k=7511 h=5120
2026-05-21T18:38:52.057184Z  INFO spark_model::layers::qwen3_ssm::trait_prefill: SSM prefill ENTRY: k=7511 h=5120
2026-05-21T18:38:52.779584Z  INFO spark_model::layers::qwen3_ssm::trait_prefill: SSM prefill ENTRY: k=7511 h=5120
2026-05-21T18:38:54.407238Z  INFO spark_model::layers::qwen3_ssm::trait_prefill: SSM prefill ENTRY: k=7511 h=5120
2026-05-21T18:38:55.130075Z  INFO spark_model::layers::qwen3_ssm::trait_prefill: SSM prefill ENTRY: k=7511 h=5120
2026-05-21T18:38:55.858308Z  INFO spark_model::layers::qwen3_ssm::trait_prefill: SSM prefill ENTRY: k=7511 h=5120
2026-05-21T18:38:57.486981Z  INFO spark_model::layers::qwen3_ssm::trait_prefill: SSM prefill ENTRY: k=7511 h=5120
2026-05-21T18:38:58.211157Z  INFO spark_model::layers::qwen3_ssm::trait_prefill: SSM prefill ENTRY: k=7511 h=5120
2026-05-21T18:38:58.935255Z  INFO spark_model::layers::qwen3_ssm::trait_prefill: SSM prefill ENTRY: k=7511 h=5120
2026-05-21T18:39:00.561008Z  INFO spark_model::layers::qwen3_ssm::trait_prefill: SSM prefill ENTRY: k=7511 h=5120
2026-05-21T18:39:01.284940Z  INFO spark_model::layers::qwen3_ssm::trait_prefill: SSM prefill ENTRY: k=7511 h=5120
2026-05-21T18:39:02.009064Z  INFO spark_model::layers::qwen3_ssm::trait_prefill: SSM prefill ENTRY: k=7511 h=5120
2026-05-21T18:39:03.635722Z  INFO spark_model::layers::qwen3_ssm::trait_prefill: SSM prefill ENTRY: k=7511 h=5120
2026-05-21T18:39:04.358527Z  INFO spark_model::layers::qwen3_ssm::trait_prefill: SSM prefill ENTRY: k=7511 h=5120
2026-05-21T18:39:05.083743Z  INFO spark_model::layers::qwen3_ssm::trait_prefill: SSM prefill ENTRY: k=7511 h=5120
2026-05-21T18:39:06.712153Z  INFO spark_model::layers::qwen3_ssm::trait_prefill: SSM prefill ENTRY: k=7511 h=5120
2026-05-21T18:39:07.433465Z  INFO spark_model::layers::qwen3_ssm::trait_prefill: SSM prefill ENTRY: k=7511 h=5120
2026-05-21T18:39:08.158521Z  INFO spark_model::layers::qwen3_ssm::trait_prefill: SSM prefill ENTRY: k=7511 h=5120
2026-05-21T18:39:09.782634Z  INFO spark_model::layers::qwen3_ssm::trait_prefill: SSM prefill ENTRY: k=7511 h=5120
2026-05-21T18:39:10.504763Z  INFO spark_model::layers::qwen3_ssm::trait_prefill: SSM prefill ENTRY: k=7511 h=5120
2026-05-21T18:39:11.230191Z  INFO spark_model::layers::qwen3_ssm::trait_prefill: SSM prefill ENTRY: k=7511 h=5120
2026-05-21T18:39:12.854179Z  INFO spark_model::layers::qwen3_ssm::trait_prefill: SSM prefill ENTRY: k=7511 h=5120
2026-05-21T18:39:13.576024Z  INFO spark_model::layers::qwen3_ssm::trait_prefill: SSM prefill ENTRY: k=7511 h=5120
2026-05-21T18:39:14.302566Z  INFO spark_model::layers::qwen3_ssm::trait_prefill: SSM prefill ENTRY: k=7511 h=5120
2026-05-21T18:39:15.926335Z  INFO spark_model::layers::qwen3_ssm::trait_prefill: SSM prefill ENTRY: k=7511 h=5120
2026-05-21T18:39:16.652762Z  INFO spark_model::layers::qwen3_ssm::trait_prefill: SSM prefill ENTRY: k=7511 h=5120
2026-05-21T18:39:17.378773Z  INFO spark_model::layers::qwen3_ssm::trait_prefill: SSM prefill ENTRY: k=7511 h=5120
2026-05-21T18:39:19.008423Z  INFO spark_model::layers::qwen3_ssm::trait_prefill: SSM prefill ENTRY: k=7511 h=5120
2026-05-21T18:39:19.731254Z  INFO spark_model::layers::qwen3_ssm::trait_prefill: SSM prefill ENTRY: k=7511 h=5120
2026-05-21T18:39:20.454488Z  INFO spark_model::layers::qwen3_ssm::trait_prefill: SSM prefill ENTRY: k=7511 h=5120
2026-05-21T18:39:22.076215Z  INFO spark_model::layers::qwen3_ssm::trait_prefill: SSM prefill ENTRY: k=7511 h=5120
2026-05-21T18:39:22.801175Z  INFO spark_model::layers::qwen3_ssm::trait_prefill: SSM prefill ENTRY: k=7511 h=5120
2026-05-21T18:39:23.526231Z  INFO spark_model::layers::qwen3_ssm::trait_prefill: SSM prefill ENTRY: k=7511 h=5120
2026-05-21T18:39:25.153519Z  INFO spark_model::layers::qwen3_ssm::trait_prefill: SSM prefill ENTRY: k=7511 h=5120
2026-05-21T18:39:25.879767Z  INFO spark_model::layers::qwen3_ssm::trait_prefill: SSM prefill ENTRY: k=7511 h=5120
2026-05-21T18:39:26.607055Z  INFO spark_model::layers::qwen3_ssm::trait_prefill: SSM prefill ENTRY: k=7511 h=5120
2026-05-21T18:39:28.235573Z  INFO spark_model::layers::qwen3_ssm::trait_prefill: SSM prefill ENTRY: k=7511 h=5120
2026-05-21T18:39:28.958239Z  INFO spark_model::layers::qwen3_ssm::trait_prefill: SSM prefill ENTRY: k=7511 h=5120
2026-05-21T18:39:29.683248Z  INFO spark_model::model::trait_impl::prefill_b::finalize_last: Saved SSM snapshot 2 for 15707 tokens (982 blocks) [chunk]
2026-05-21T18:39:29.683343Z  INFO spark::scheduler::phase_continue_prefills: Prefill chunk 15707/15707 tokens
2026-05-21T18:39:31.324515Z  INFO spark::scheduler::phase_continue_prefills: Prefill first token: 27
2026-05-21T18:39:31.324575Z  INFO spark_model::model::trait_impl::decode_a: CUDA graph capture: starting for 64 layers
2026-05-21T18:39:31.325829Z  INFO spark_model::model::trait_impl::decode_a: CUDA graph captured successfully for slot=0 (handle=261058314256912)
2026-05-21T18:39:36.771072Z  INFO spark::scheduler::lifecycle: Done: 62 tokens (stop) 11.4 tok/s, TTFT=49243.9ms
2026-05-21T18:39:37.070330Z  INFO spark::api::chat: Request: model=Qwen3.6-27B-FP8, messages=6, tools=0, tools_active=false, tool_choice=None, stream=true, temp=None, max_tokens=4096, freq_pen=None, rep_pen=None
2026-05-21T18:39:37.084133Z  INFO spark::api::chat: Session 0xecacf2ef12947de3: 16373 prompt tokens, tools=false
2026-05-21T18:39:37.085262Z  INFO spark::scheduler::prefill_a_step: Chunked prefill start: 16373 prompt tokens, chunk_size=8196, max_tokens=4096
2026-05-21T18:39:37.088508Z  INFO spark_model::model::trait_impl::prefill_b::prefix_lookup: Marconi intermediate hit: restored from checkpoint at token 8196 (skipping 8196 tokens, recomputing 7500 SSM tokens to match point 15696)
2026-05-21T18:39:37.088524Z  INFO spark::scheduler::phase_start_prefills: Prefill chunk 0/16373: 8196/16373 tokens
2026-05-21T18:39:37.108590Z  INFO spark_model::layers::qwen3_ssm::trait_prefill: SSM prefill ENTRY: k=8177 h=5120
2026-05-21T18:39:37.109828Z  INFO spark_model::layers::qwen3_ssm::trait_prefill: SSM prefill ENTRY: k=8177 h=5120
2026-05-21T18:39:37.896008Z  INFO spark_model::layers::qwen3_ssm::trait_prefill: SSM prefill ENTRY: k=8177 h=5120
2026-05-21T18:39:38.682341Z  INFO spark_model::layers::qwen3_ssm::trait_prefill: SSM prefill ENTRY: k=8177 h=5120
2026-05-21T18:39:40.451793Z  INFO spark_model::layers::qwen3_ssm::trait_prefill: SSM prefill ENTRY: k=8177 h=5120
2026-05-21T18:39:41.237331Z  INFO spark_model::layers::qwen3_ssm::trait_prefill: SSM prefill ENTRY: k=8177 h=5120
2026-05-21T18:39:42.024496Z  INFO spark_model::layers::qwen3_ssm::trait_prefill: SSM prefill ENTRY: k=8177 h=5120
2026-05-21T18:39:43.793971Z  INFO spark_model::layers::qwen3_ssm::trait_prefill: SSM prefill ENTRY: k=8177 h=5120
2026-05-21T18:39:44.579583Z  INFO spark_model::layers::qwen3_ssm::trait_prefill: SSM prefill ENTRY: k=8177 h=5120
2026-05-21T18:39:45.366076Z  INFO spark_model::layers::qwen3_ssm::trait_prefill: SSM prefill ENTRY: k=8177 h=5120
2026-05-21T18:39:47.141467Z  INFO spark_model::layers::qwen3_ssm::trait_prefill: SSM prefill ENTRY: k=8177 h=5120
2026-05-21T18:39:47.929322Z  INFO spark_model::layers::qwen3_ssm::trait_prefill: SSM prefill ENTRY: k=8177 h=5120
2026-05-21T18:39:48.715035Z  INFO spark_model::layers::qwen3_ssm::trait_prefill: SSM prefill ENTRY: k=8177 h=5120
2026-05-21T18:39:50.483745Z  INFO spark_model::layers::qwen3_ssm::trait_prefill: SSM prefill ENTRY: k=8177 h=5120
2026-05-21T18:39:51.271480Z  INFO spark_model::layers::qwen3_ssm::trait_prefill: SSM prefill ENTRY: k=8177 h=5120
2026-05-21T18:39:52.057645Z  INFO spark_model::layers::qwen3_ssm::trait_prefill: SSM prefill ENTRY: k=8177 h=5120
2026-05-21T18:39:53.828665Z  INFO spark_model::layers::qwen3_ssm::trait_prefill: SSM prefill ENTRY: k=8177 h=5120
2026-05-21T18:39:54.612850Z  INFO spark_model::layers::qwen3_ssm::trait_prefill: SSM prefill ENTRY: k=8177 h=5120
2026-05-21T18:39:55.396966Z  INFO spark_model::layers::qwen3_ssm::trait_prefill: SSM prefill ENTRY: k=8177 h=5120
2026-05-21T18:39:57.168091Z  INFO spark_model::layers::qwen3_ssm::trait_prefill: SSM prefill ENTRY: k=8177 h=5120
2026-05-21T18:39:57.950827Z  INFO spark_model::layers::qwen3_ssm::trait_prefill: SSM prefill ENTRY: k=8177 h=5120
2026-05-21T18:39:58.736521Z  INFO spark_model::layers::qwen3_ssm::trait_prefill: SSM prefill ENTRY: k=8177 h=5120
2026-05-21T18:40:00.507265Z  INFO spark_model::layers::qwen3_ssm::trait_prefill: SSM prefill ENTRY: k=8177 h=5120
2026-05-21T18:40:01.293327Z  INFO spark_model::layers::qwen3_ssm::trait_prefill: SSM prefill ENTRY: k=8177 h=5120
2026-05-21T18:40:02.079252Z  INFO spark_model::layers::qwen3_ssm::trait_prefill: SSM prefill ENTRY: k=8177 h=5120
2026-05-21T18:40:03.843997Z  INFO spark_model::layers::qwen3_ssm::trait_prefill: SSM prefill ENTRY: k=8177 h=5120
2026-05-21T18:40:04.628284Z  INFO spark_model::layers::qwen3_ssm::trait_prefill: SSM prefill ENTRY: k=8177 h=5120
2026-05-21T18:40:05.412699Z  INFO spark_model::layers::qwen3_ssm::trait_prefill: SSM prefill ENTRY: k=8177 h=5120
2026-05-21T18:40:07.180771Z  INFO spark_model::layers::qwen3_ssm::trait_prefill: SSM prefill ENTRY: k=8177 h=5120
2026-05-21T18:40:07.967459Z  INFO spark_model::layers::qwen3_ssm::trait_prefill: SSM prefill ENTRY: k=8177 h=5120
2026-05-21T18:40:08.754937Z  INFO spark_model::layers::qwen3_ssm::trait_prefill: SSM prefill ENTRY: k=8177 h=5120
2026-05-21T18:40:10.523647Z  INFO spark_model::layers::qwen3_ssm::trait_prefill: SSM prefill ENTRY: k=8177 h=5120
2026-05-21T18:40:11.306555Z  INFO spark_model::layers::qwen3_ssm::trait_prefill: SSM prefill ENTRY: k=8177 h=5120
2026-05-21T18:40:12.094572Z  INFO spark_model::layers::qwen3_ssm::trait_prefill: SSM prefill ENTRY: k=8177 h=5120
2026-05-21T18:40:13.861033Z  INFO spark_model::layers::qwen3_ssm::trait_prefill: SSM prefill ENTRY: k=8177 h=5120
2026-05-21T18:40:14.646009Z  INFO spark_model::layers::qwen3_ssm::trait_prefill: SSM prefill ENTRY: k=8177 h=5120
2026-05-21T18:40:15.433818Z  INFO spark_model::layers::qwen3_ssm::trait_prefill: SSM prefill ENTRY: k=8177 h=5120
2026-05-21T18:40:17.202842Z  INFO spark_model::layers::qwen3_ssm::trait_prefill: SSM prefill ENTRY: k=8177 h=5120
2026-05-21T18:40:17.987707Z  INFO spark_model::layers::qwen3_ssm::trait_prefill: SSM prefill ENTRY: k=8177 h=5120
2026-05-21T18:40:18.770886Z  INFO spark_model::layers::qwen3_ssm::trait_prefill: SSM prefill ENTRY: k=8177 h=5120
2026-05-21T18:40:20.533407Z  INFO spark_model::layers::qwen3_ssm::trait_prefill: SSM prefill ENTRY: k=8177 h=5120
2026-05-21T18:40:21.320147Z  INFO spark_model::layers::qwen3_ssm::trait_prefill: SSM prefill ENTRY: k=8177 h=5120
2026-05-21T18:40:22.105606Z  INFO spark_model::layers::qwen3_ssm::trait_prefill: SSM prefill ENTRY: k=8177 h=5120
2026-05-21T18:40:23.879808Z  INFO spark_model::layers::qwen3_ssm::trait_prefill: SSM prefill ENTRY: k=8177 h=5120
2026-05-21T18:40:24.666821Z  INFO spark_model::layers::qwen3_ssm::trait_prefill: SSM prefill ENTRY: k=8177 h=5120
2026-05-21T18:40:25.457398Z  INFO spark_model::layers::qwen3_ssm::trait_prefill: SSM prefill ENTRY: k=8177 h=5120
2026-05-21T18:40:27.226717Z  INFO spark_model::layers::qwen3_ssm::trait_prefill: SSM prefill ENTRY: k=8177 h=5120
2026-05-21T18:40:28.013178Z  INFO spark_model::layers::qwen3_ssm::trait_prefill: SSM prefill ENTRY: k=8177 h=5120
2026-05-21T18:40:28.803376Z  INFO spark_model::model::trait_impl::prefill_b::finalize_last: Saved SSM snapshot 3 for 16373 tokens (1024 blocks) [chunk]
2026-05-21T18:40:28.803474Z  INFO spark::scheduler::phase_continue_prefills: Prefill chunk 16373/16373 tokens
2026-05-21T18:40:30.582587Z  INFO spark::scheduler::phase_continue_prefills: Prefill first token: 27
2026-05-21T18:40:30.582643Z  INFO spark_model::model::trait_impl::decode_a: CUDA graph capture: starting for 64 layers
2026-05-21T18:40:30.583892Z  INFO spark_model::model::trait_impl::decode_a: CUDA graph captured successfully for slot=0 (handle=261058313069408)
2026-05-21T18:40:36.090234Z  INFO spark::scheduler::lifecycle: Done: 62 tokens (stop) 11.3 tok/s, TTFT=53497.3ms
2026-05-21T18:40:36.402146Z  INFO spark::api::chat: Request: model=Qwen3.6-27B-FP8, messages=8, tools=0, tools_active=false, tool_choice=None, stream=true, temp=None, max_tokens=4096, freq_pen=None, rep_pen=None
2026-05-21T18:40:36.414814Z  INFO spark::api::chat: Session 0xecacf2ef12947de3: 17080 prompt tokens, tools=false
2026-05-21T18:40:36.416172Z  INFO spark::scheduler::prefill_a_step: Chunked prefill start: 17080 prompt tokens, chunk_size=8196, max_tokens=4096
2026-05-21T18:40:36.419461Z  INFO spark_model::model::trait_impl::prefill_b::prefix_lookup: Marconi intermediate hit: restored from checkpoint at token 8196 (skipping 8196 tokens, recomputing 8172 SSM tokens to match point 16368)
2026-05-21T18:40:36.419480Z  INFO spark::scheduler::phase_start_prefills: Prefill chunk 0/17080: 8196/17080 tokens
2026-05-21T18:40:36.434161Z  INFO spark_model::layers::qwen3_ssm::trait_prefill: SSM prefill ENTRY: k=8192 h=5120
2026-05-21T18:40:36.435385Z  INFO spark_model::layers::qwen3_ssm::trait_prefill: SSM prefill ENTRY: k=8192 h=5120
2026-05-21T18:40:37.225171Z  INFO spark_model::layers::qwen3_ssm::trait_prefill: SSM prefill ENTRY: k=8192 h=5120
2026-05-21T18:40:38.012139Z  INFO spark_model::layers::qwen3_ssm::trait_prefill: SSM prefill ENTRY: k=8192 h=5120
2026-05-21T18:40:39.789040Z  INFO spark_model::layers::qwen3_ssm::trait_prefill: SSM prefill ENTRY: k=8192 h=5120
2026-05-21T18:40:40.577201Z  INFO spark_model::layers::qwen3_ssm::trait_prefill: SSM prefill ENTRY: k=8192 h=5120
2026-05-21T18:40:41.366890Z  INFO spark_model::layers::qwen3_ssm::trait_prefill: SSM prefill ENTRY: k=8192 h=5120
2026-05-21T18:40:43.133568Z  INFO spark_model::layers::qwen3_ssm::trait_prefill: SSM prefill ENTRY: k=8192 h=5120
2026-05-21T18:40:43.920932Z  INFO spark_model::layers::qwen3_ssm::trait_prefill: SSM prefill ENTRY: k=8192 h=5120
2026-05-21T18:40:44.706399Z  INFO spark_model::layers::qwen3_ssm::trait_prefill: SSM prefill ENTRY: k=8192 h=5120
2026-05-21T18:40:46.477168Z  INFO spark_model::layers::qwen3_ssm::trait_prefill: SSM prefill ENTRY: k=8192 h=5120
2026-05-21T18:40:47.263930Z  INFO spark_model::layers::qwen3_ssm::trait_prefill: SSM prefill ENTRY: k=8192 h=5120
2026-05-21T18:40:48.050163Z  INFO spark_model::layers::qwen3_ssm::trait_prefill: SSM prefill ENTRY: k=8192 h=5120
2026-05-21T18:40:49.825030Z  INFO spark_model::layers::qwen3_ssm::trait_prefill: SSM prefill ENTRY: k=8192 h=5120
2026-05-21T18:40:50.613043Z  INFO spark_model::layers::qwen3_ssm::trait_prefill: SSM prefill ENTRY: k=8192 h=5120
2026-05-21T18:40:51.400340Z  INFO spark_model::layers::qwen3_ssm::trait_prefill: SSM prefill ENTRY: k=8192 h=5120
2026-05-21T18:40:53.173019Z  INFO spark_model::layers::qwen3_ssm::trait_prefill: SSM prefill ENTRY: k=8192 h=5120
2026-05-21T18:40:53.959265Z  INFO spark_model::layers::qwen3_ssm::trait_prefill: SSM prefill ENTRY: k=8192 h=5120
2026-05-21T18:40:54.750930Z  INFO spark_model::layers::qwen3_ssm::trait_prefill: SSM prefill ENTRY: k=8192 h=5120
2026-05-21T18:40:56.519802Z  INFO spark_model::layers::qwen3_ssm::trait_prefill: SSM prefill ENTRY: k=8192 h=5120
2026-05-21T18:40:57.305658Z  INFO spark_model::layers::qwen3_ssm::trait_prefill: SSM prefill ENTRY: k=8192 h=5120
2026-05-21T18:40:58.094096Z  INFO spark_model::layers::qwen3_ssm::trait_prefill: SSM prefill ENTRY: k=8192 h=5120
2026-05-21T18:40:59.864165Z  INFO spark_model::layers::qwen3_ssm::trait_prefill: SSM prefill ENTRY: k=8192 h=5120
2026-05-21T18:41:00.649745Z  INFO spark_model::layers::qwen3_ssm::trait_prefill: SSM prefill ENTRY: k=8192 h=5120
2026-05-21T18:41:01.436615Z  INFO spark_model::layers::qwen3_ssm::trait_prefill: SSM prefill ENTRY: k=8192 h=5120
2026-05-21T18:41:03.206346Z  INFO spark_model::layers::qwen3_ssm::trait_prefill: SSM prefill ENTRY: k=8192 h=5120
2026-05-21T18:41:03.990443Z  INFO spark_model::layers::qwen3_ssm::trait_prefill: SSM prefill ENTRY: k=8192 h=5120
2026-05-21T18:41:04.777927Z  INFO spark_model::layers::qwen3_ssm::trait_prefill: SSM prefill ENTRY: k=8192 h=5120
2026-05-21T18:41:06.545694Z  INFO spark_model::layers::qwen3_ssm::trait_prefill: SSM prefill ENTRY: k=8192 h=5120
2026-05-21T18:41:07.332974Z  INFO spark_model::layers::qwen3_ssm::trait_prefill: SSM prefill ENTRY: k=8192 h=5120
2026-05-21T18:41:08.118326Z  INFO spark_model::layers::qwen3_ssm::trait_prefill: SSM prefill ENTRY: k=8192 h=5120
2026-05-21T18:41:09.885999Z  INFO spark_model::layers::qwen3_ssm::trait_prefill: SSM prefill ENTRY: k=8192 h=5120
2026-05-21T18:41:10.671174Z  INFO spark_model::layers::qwen3_ssm::trait_prefill: SSM prefill ENTRY: k=8192 h=5120
2026-05-21T18:41:11.458642Z  INFO spark_model::layers::qwen3_ssm::trait_prefill: SSM prefill ENTRY: k=8192 h=5120
2026-05-21T18:41:13.228967Z  INFO spark_model::layers::qwen3_ssm::trait_prefill: SSM prefill ENTRY: k=8192 h=5120
2026-05-21T18:41:14.014639Z  INFO spark_model::layers::qwen3_ssm::trait_prefill: SSM prefill ENTRY: k=8192 h=5120
2026-05-21T18:41:14.801702Z  INFO spark_model::layers::qwen3_ssm::trait_prefill: SSM prefill ENTRY: k=8192 h=5120
2026-05-21T18:41:16.574338Z  INFO spark_model::layers::qwen3_ssm::trait_prefill: SSM prefill ENTRY: k=8192 h=5120
2026-05-21T18:41:17.360763Z  INFO spark_model::layers::qwen3_ssm::trait_prefill: SSM prefill ENTRY: k=8192 h=5120
2026-05-21T18:41:18.143540Z  INFO spark_model::layers::qwen3_ssm::trait_prefill: SSM prefill ENTRY: k=8192 h=5120
2026-05-21T18:41:19.909729Z  INFO spark_model::layers::qwen3_ssm::trait_prefill: SSM prefill ENTRY: k=8192 h=5120
2026-05-21T18:41:20.695955Z  INFO spark_model::layers::qwen3_ssm::trait_prefill: SSM prefill ENTRY: k=8192 h=5120
2026-05-21T18:41:21.481818Z  INFO spark_model::layers::qwen3_ssm::trait_prefill: SSM prefill ENTRY: k=8192 h=5120
2026-05-21T18:41:23.251194Z  INFO spark_model::layers::qwen3_ssm::trait_prefill: SSM prefill ENTRY: k=8192 h=5120
2026-05-21T18:41:24.038638Z  INFO spark_model::layers::qwen3_ssm::trait_prefill: SSM prefill ENTRY: k=8192 h=5120
2026-05-21T18:41:24.826268Z  INFO spark_model::layers::qwen3_ssm::trait_prefill: SSM prefill ENTRY: k=8192 h=5120
2026-05-21T18:41:26.596053Z  INFO spark_model::layers::qwen3_ssm::trait_prefill: SSM prefill ENTRY: k=8192 h=5120
2026-05-21T18:41:27.382049Z  INFO spark_model::layers::qwen3_ssm::trait_prefill: SSM prefill ENTRY: k=8192 h=5120
2026-05-21T18:41:28.172325Z  INFO spark_model::model::trait_impl::prefill_b::save_checkpoint: Intermediate SSM checkpoint saved at token 16388 (snapshot_id 4, block 1024)
2026-05-21T18:41:28.172328Z  INFO spark::scheduler::phase_continue_prefills: Prefill chunk 16388/17080 tokens
2026-05-21T18:41:34.797377Z  WARN spark_model::model::trait_impl::prefill_b::finalize_last: DIAG post-norm: norm=4.6379 first2=[-0.2930, -0.6289]
2026-05-21T18:41:34.802524Z  WARN spark_model::model::trait_impl::prefill_b::finalize_last: DIAG logits[0..248070]: max=18.8750 min=-10.8125 nan=0 top5=[(13314, 18.875), (58, 17.125), (40, 17.0), (27, 15.8125), (248069, 15.1875)]
2026-05-21T18:41:34.802956Z  INFO spark_model::model::trait_impl::prefill_b::finalize_last: Saved SSM snapshot 5 for 17080 tokens (1068 blocks) [chunk]
2026-05-21T18:41:34.803170Z  INFO spark::scheduler::phase_continue_prefills: Prefill chunk 17080/17080 tokens
2026-05-21T18:41:34.807226Z  INFO spark::scheduler::phase_continue_prefills: Prefill first token: 13314
2026-05-21T18:41:34.807268Z  INFO spark_model::model::trait_impl::decode_a: CUDA graph capture: starting for 64 layers
2026-05-21T18:41:34.808523Z  INFO spark_model::model::trait_impl::decode_a: CUDA graph captured successfully for slot=0 (handle=261058313027312)
2026-05-21T18:42:28.168969Z  INFO spark::scheduler::lifecycle: Done: 588 tokens (stop) 11.0 tok/s, TTFT=58391.1ms
2026-05-21T18:42:28.445178Z  INFO spark::api::chat: Request: model=Qwen3.6-27B-FP8, messages=10, tools=0, tools_active=false, tool_choice=None, stream=true, temp=None, max_tokens=4096, freq_pen=None, rep_pen=None
2026-05-21T18:42:28.458634Z  INFO spark::api::chat: Session 0xecacf2ef12947de3: 18462 prompt tokens, tools=false
2026-05-21T18:42:28.459709Z  INFO spark::scheduler::prefill_a_step: Chunked prefill start: 18462 prompt tokens, chunk_size=8196, max_tokens=4096
2026-05-21T18:42:28.463123Z  INFO spark_model::model::trait_impl::prefill_b::prefix_lookup: Marconi intermediate hit: restored from checkpoint at token 16388 (skipping 16388 tokens, recomputing 684 SSM tokens to match point 17072)
2026-05-21T18:42:28.463137Z  INFO spark::scheduler::phase_start_prefills: Prefill chunk 0/18462: 8196/18462 tokens
2026-05-21T18:42:28.463152Z  INFO spark::scheduler::phase_continue_prefills: Prefill chunk 16388/18462 tokens
2026-05-21T18:42:42.529850Z  WARN spark_model::model::trait_impl::prefill_b::finalize_last: DIAG post-norm: norm=6.5758 first2=[-2.4531, -0.9648]
2026-05-21T18:42:42.534917Z  WARN spark_model::model::trait_impl::prefill_b::finalize_last: DIAG logits[0..248070]: max=18.2500 min=-9.8750 nan=0 top5=[(13314, 18.25), (27, 17.75), (248069, 17.375), (1206, 15.25), (38, 14.5625)]
2026-05-21T18:42:42.535356Z  INFO spark_model::model::trait_impl::prefill_b::finalize_last: Saved SSM snapshot 6 for 18462 tokens (1154 blocks) [chunk]
2026-05-21T18:42:42.535604Z  INFO spark::scheduler::phase_continue_prefills: Prefill chunk 18462/18462 tokens
2026-05-21T18:42:42.539602Z  INFO spark::scheduler::phase_continue_prefills: Prefill first token: 13314
2026-05-21T18:42:42.539646Z  INFO spark_model::model::trait_impl::decode_a: CUDA graph capture: starting for 64 layers
2026-05-21T18:42:42.540833Z  INFO spark_model::model::trait_impl::decode_a: CUDA graph captured successfully for slot=0 (handle=261058318145568)
2026-05-21T18:43:01.960817Z  INFO spark::scheduler::lifecycle: Done: 211 tokens (stop) 10.9 tok/s, TTFT=14079.9ms
2026-05-21T18:43:02.174781Z  INFO spark::api::chat: Request: model=Qwen3.6-27B-FP8, messages=12, tools=0, tools_active=false, tool_choice=None, stream=true, temp=None, max_tokens=4096, freq_pen=None, rep_pen=None
2026-05-21T18:43:02.188887Z  INFO spark::api::chat: Session 0xecacf2ef12947de3: 19476 prompt tokens, tools=false
2026-05-21T18:43:02.189802Z  INFO spark::scheduler::prefill_a_step: Chunked prefill start: 19476 prompt tokens, chunk_size=8196, max_tokens=4096
2026-05-21T18:43:02.193276Z  INFO spark_model::model::trait_impl::prefill_b::prefix_lookup: Marconi intermediate hit: restored from checkpoint at token 16388 (skipping 16388 tokens, recomputing 2060 SSM tokens to match point 18448)
2026-05-21T18:43:02.193290Z  INFO spark::scheduler::phase_start_prefills: Prefill chunk 0/19476: 8196/19476 tokens
2026-05-21T18:43:02.193311Z  INFO spark::scheduler::phase_continue_prefills: Prefill chunk 16388/19476 tokens
2026-05-21T18:43:23.085188Z  WARN spark_model::model::trait_impl::prefill_b::finalize_last: DIAG post-norm: norm=6.5508 first2=[-2.8281, 0.8477]
2026-05-21T18:43:23.090283Z  WARN spark_model::model::trait_impl::prefill_b::finalize_last: DIAG logits[0..248070]: max=20.1250 min=-9.8125 nan=0 top5=[(27, 20.125), (1596, 18.125), (13314, 16.5), (90833, 16.25), (90700, 16.125)]
2026-05-21T18:43:23.090827Z  INFO spark_model::model::trait_impl::prefill_b::finalize_last: Saved SSM snapshot 7 for 19476 tokens (1218 blocks) [chunk]
2026-05-21T18:43:23.091085Z  INFO spark::scheduler::phase_continue_prefills: Prefill chunk 19476/19476 tokens
2026-05-21T18:43:23.094990Z  INFO spark::scheduler::phase_continue_prefills: Prefill first token: 27
2026-05-21T18:43:23.095032Z  INFO spark_model::model::trait_impl::decode_a: CUDA graph capture: starting for 64 layers
2026-05-21T18:43:23.096379Z  INFO spark_model::model::trait_impl::decode_a: CUDA graph captured successfully for slot=0 (handle=261058318224480)
2026-05-21T18:43:23.752442Z  WARN spark::api::sanitizer: orphan tool-call leak in content stream; suppressing until close
2026-05-21T18:43:25.340805Z  INFO spark::scheduler::lifecycle: Done: 25 tokens (stop) 11.1 tok/s, TTFT=20905.2ms
```
