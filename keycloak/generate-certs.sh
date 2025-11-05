#!/bin/bash

# Generate self-signed certificate for Keycloak
mkdir -p certs

openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
  -keyout certs/tls.key \
  -out certs/tls.crt \
  -subj "/C=US/ST=State/L=City/O=Organization/CN=localhost" \
  -addext "subjectAltName=DNS:localhost,DNS:keycloak,IP:127.0.0.1"

chmod 644 certs/tls.crt
chmod 600 certs/tls.key

echo "Certificates generated in certs/ directory"

