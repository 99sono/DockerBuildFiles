#!/usr/bin/env bash
set -euo pipefail

# ============================================================
# Copy SSL certificates from the original (dev-network) nginx proxy.
#
# The hostmode proxy reuses the same self-signed certificates
# from the sibling folder. This script copies them locally.
# ============================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ORIGINAL_DIR="$SCRIPT_DIR/../nginx-vllm-reverse-proxy-dgx-spark"

SRC_CERT="$ORIGINAL_DIR/nginx-proxy/ssl/nginx-selfsigned.crt"
SRC_KEY="$ORIGINAL_DIR/nginx-proxy/ssl/nginx-selfsigned.key"
DST_DIR="$SCRIPT_DIR/nginx-proxy/ssl"

if [ ! -f "$SRC_CERT" ] || [ ! -f "$SRC_KEY" ]; then
  echo "❌ Certificates not found in $ORIGINAL_DIR/nginx-proxy/ssl/"
  echo ""
  echo "   Generate them first by running:"
  echo "   cd $ORIGINAL_DIR && ./00_b_generate_self_signed_cert.sh"
  exit 1
fi

mkdir -p "$DST_DIR"
cp "$SRC_CERT" "$DST_DIR/nginx-selfsigned.crt"
cp "$SRC_KEY" "$DST_DIR/nginx-selfsigned.key"
chmod 644 "$DST_DIR/nginx-selfsigned.crt"
chmod 600 "$DST_DIR/nginx-selfsigned.key"

echo "✅ Certificates copied from:"
echo "   $ORIGINAL_DIR/nginx-proxy/ssl/"
echo "   → $DST_DIR/"