#!/bin/bash
# Enter the development container with an interactive shell

set -e

# Load common environment
source ./00_setup_env.sh || {
    echo "❌ Could not load environment setup. Make sure 00_setup_env.sh exists."
    exit 1
}

echo "=== Entering Development Container ==="
echo "Container: ${CONTAINER_NAME}"

# Check if container is running
if ! docker ps --format '{{.Names}}' | grep -q "^${CONTAINER_NAME}$"; then
    echo "❌ Container '${CONTAINER_NAME}' is not running."
    echo ""
    echo "To start the container, run:"
    echo "  ./02_start_dev.sh"
    exit 1
fi

echo "✅ Container is running. Entering interactive shell..."
echo ""
echo "📁 Current directory: /home/developer/dev"
echo "🎯 Available project types: java/, node/, python/"
echo ""

# Enter the container as developer user
docker exec -it -u developer "${CONTAINER_NAME}" bash -c "cd /home/developer/dev && exec bash"
