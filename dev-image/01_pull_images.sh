#!/bin/bash
# Pull required Docker images for development environment

set -e

# Source environment variables
if [ -f .env ]; then
    export $(cat .env | xargs)
fi

# pull docker images
docker-compose pull

echo "=== All images pulled successfully ==="
echo ""
echo "Next steps:"
echo "1. Modify .env as needed"
echo "2. Run ./02_start_dev.sh to start the development environment"
echo "3. Run ./03_enter_container.sh to enter the container interactively"
