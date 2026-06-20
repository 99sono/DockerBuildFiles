#!/bin/bash
# Follow WORKER node logs.
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$SCRIPT_DIR"
docker compose logs -f --tail=100
