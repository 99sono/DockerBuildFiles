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
- `05_docker_pull_model.sh`: Pulls any model (see models.md for available models)

## Model Management

All model pull operations are now handled through a single script:
```bash
./05_docker_pull_model.sh [model_name]
```

See [models.md](models.md) for the complete list of available models and their specifications.

## Security Notice
This configuration is designed for **local development only**. The default settings:
- Use a placeholder API key
- Disable authentication in Open-WebUI
- Assume a trusted local network

For production deployments:
1. Generate a secure API key
2. Enable authentication in Open-WebUI
3. Restrict network access

## Shared Development Network

This setup participates in a shared Docker network called `development-network` to enable communication with other development-related containers.

### Network Architecture

The setup uses Docker's **external network** approach to enable cross-compose communication:

- **Network Creation**: `commonScripts/create_development_network.sh` automatically creates/checks for the `development-network`
- **External Reference**: Both docker-compose.yml files reference `development-network: {external: true}`
- **Automatic Setup**: Startup scripts (`01_01_docker_compose_up.sh`) ensure the network exists before launching containers

### Communication

- **Dev containers** can access Ollama APIs via `http://ollama:11434`
- **Future services** can join the common development ecosystem
- **Service Discovery** works via container hostnames on the shared network

### Technical Details

- **Bypasses Project Prefixing**: Docker Compose normally prefixes networks with project names (e.g., `ollama_development-network`)
- **External Networks**: Using `external: true` ensures all compose projects share the exact same network
- **Symmetric Setup**: Either Ollama or Dev containers can be started first - both will create/check the shared network

### Usage Pattern

```bash
# Start independently - both ensure network exists
cd ollama && ./01_01_docker_compose_up.sh
cd dev-image && ./02_start_dev.sh

# Containers communicate via hostnames
# From dev-environment: curl http://ollama:11434/api/tags
```

### For Future Service Folders

New development services should:
1. Reference `networks: development-network: {external: true}` in docker-compose.yml
2. Call `../commonScripts/create_development_network.sh` in startup scripts
3. Use service hostnames for cross-container communication
