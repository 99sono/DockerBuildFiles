# Open WebUI - DGX Spark

Open WebUI container configured to connect to an existing inference server (`inference-server`) on the `development-network`.

## Setup

1. Copy `.env.example` to `.env` and configure your `INFERENCE_API_KEY` and `WEBUI_AUTH` settings.
2. Ensure your inference server (vLLM or llama.cpp) is running with hostname `inference-server` on port `8000`.

## Usage

- **Start**: `./01_up.sh`
- **Stop**: `./02_down.sh`
- **Logs**: `./03_logs.sh`
- **Test Connection**: `./04_test_connection.sh`

## Access

Open WebUI will be available at `http://localhost:11435`.
