#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

CERT_DIR="nginx-proxy/ssl"
CERT_FILE="${CERT_DIR}/nginx-selfsigned.crt"
KEY_FILE="${CERT_DIR}/nginx-selfsigned.key"

echo "Generating self-signed certificate for HTTPS reverse proxy ..."
mkdir -p "$CERT_DIR"

openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
  -keyout "$KEY_FILE" \
  -out "$CERT_FILE" \
  -subj "/CN=spark-8ddc"

echo ""
echo "Certificate generated successfully:"
echo "  ${CERT_FILE}   (public certificate)"
echo "  ${KEY_FILE}    (private key)"
echo ""
echo "Next steps:"
echo "  1. Run: 01_install_ca_cert.sh  (to install in Ubuntu trust store)"
echo "  2. Run: 01_up.sh                (to start the reverse proxy)"