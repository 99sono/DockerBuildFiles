#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

CERT_DIR="nginx-proxy/ssl"
CERT_FILE="${CERT_DIR}/nginx-selfsigned.crt"
KEY_FILE="${CERT_DIR}/nginx-selfsigned.key"

# Source environment variables from 00_env.sh
ENV_FILE="./00_env.sh"
source "$ENV_FILE"

# Validate required variables
if [[ -z "${DGX_HOSTNAME:-}" ]]; then
  echo "ERROR: DGX_HOSTNAME is not set in $ENV_FILE"
  exit 1
fi

if [[ -z "${SSL_IP_ADDRESS:-}" ]]; then
  echo "ERROR: SSL_IP_ADDRESS is not set in $ENV_FILE"
  exit 1
fi

echo "Generating self-signed certificate for HTTPS reverse proxy ..."
mkdir -p "$CERT_DIR"

openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
  -keyout "$KEY_FILE" \
  -out "$CERT_FILE" \
  -subj "/CN=$DGX_HOSTNAME" \
  -addext "subjectAltName = DNS:$DGX_HOSTNAME, DNS:localhost, IP:$SSL_IP_ADDRESS"

echo ""
echo "Certificate generated successfully:"
echo "  ${CERT_FILE}   (public certificate)"
echo "  ${KEY_FILE}    (private key)"
echo ""
echo "Next steps:"
echo "  1. Run: 01_a_install_ca_cert.sh  (to install in Ubuntu trust store)"
echo "  2. Run: 01_up.sh                 (to start the reverse proxy)"