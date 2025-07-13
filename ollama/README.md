# Ollama with Open-WebUI Docker Setup

This project sets up Ollama (a large language model service) and Open-WebUI (a web interface) using Docker with GPU acceleration.

## Prerequisites

- Docker
- Docker Compose
- NVIDIA GPU with appropriate drivers
- NVIDIA Container Toolkit

## Setup Instructions

1. Clone this repository
2. Run `./00_add_executable_flag.sh` to make all scripts executable
3. Run `./01_01_docker_compose_up.sh` to start the services
4. Run `./01_02_docker_compose_pull.sh` to pull the latest images

## Available Scripts

- `00_add_executable_flag.sh`: Makes all scripts in the directory executable
- `01_01_docker_compose_up.sh`: Starts the Docker services
- `01_02_docker_compose_pull.sh`: Pulls the latest Docker images
- `02_connect_to_ollama.sh`: Connects to the Ollama container
- `03_01_curl_gemma3_4b_context_8k.sh`: Example curl command to interact with Ollama
- `04_cat_linux_operating_system_ollama.sh`: Shows the operating system of the Ollama container
- `05_google_01_pull_gemma3-4b.sh`: Pulls the Gemma3 4B model
- `05_google_02_pull_gemma3-12b.sh`: Pulls the Gemma3 12B model
- `05_google_03_pull_gemma3-24b.sh`: Pulls the Gemma3 24B model
- `05_qwen_01_pull_qwen3-30b-a3b.sh`: Pulls the Qwen3 30B model
- `05_deepseek_01_pull_deepseek-coder-v2-16b.sh`: Pulls the DeepSeek Coder V2 16B model
- `05_deepseek_02_pull_deepseek-r1-8b-0528-qwen3-fp16.sh`: Pulls the DeepSeek R1 8B model

## Model Management

To pull a model, use the appropriate script from the list above or run:
