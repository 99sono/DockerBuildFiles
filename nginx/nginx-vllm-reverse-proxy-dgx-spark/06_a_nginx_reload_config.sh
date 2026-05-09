#!/usr/bin/env bash
set -euo pipefail

# 06_a_nginx_reload_config.sh
# Gracefully reload nginx configuration without restarting the container.
# Use this after making changes to nginx.conf inside the container.

echo "Reloading nginx configuration in 'nginx-proxy' container ..."
docker exec nginx-proxy nginx -s reload

echo "Done. Nginx configuration reloaded gracefully."