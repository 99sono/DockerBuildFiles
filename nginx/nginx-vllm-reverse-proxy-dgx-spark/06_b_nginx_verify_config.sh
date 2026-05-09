#!/usr/bin/env bash
set -euo pipefail

# 06_b_nginx_verify_config.sh
# Validate nginx.conf syntax before applying changes.
# Use this to verify configuration is valid before running 06_a_nginx_reload_config.sh

echo "Validating nginx configuration in 'nginx-proxy' container ..."
docker exec nginx-proxy nginx -t

echo "Done. Configuration syntax validated."