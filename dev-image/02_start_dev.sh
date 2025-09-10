#!/bin/bash
# Start the development environment using docker-compose

set -e

# Check if .env file exists
if [ ! -f .env ]; then
    echo "⚠️  .env file not found. Creating from .env.example..."
    if [ -f .env.example ]; then
        cp .env.example .env
        echo "✅ Created .env from .env.example"
        echo "📝 Please review and customize .env file before proceeding"
        exit 1
    else
        echo "❌ No .env.example found. Please create .env file manually."
        exit 1
    fi
fi

# Start services
echo "🚀 Starting containers..."
docker-compose up -d
