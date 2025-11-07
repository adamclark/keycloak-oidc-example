#!/bin/bash

# Script to generate realm-config.json from template and environment variables
# Usage: ./generate-realm-config.sh [config-file]

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TEMPLATE_FILE="${SCRIPT_DIR}/realm-config.json.template"
OUTPUT_FILE="${SCRIPT_DIR}/realm-config.json"
CONFIG_FILE="${1:-${SCRIPT_DIR}/keycloak-idp-config.env}"

# Check if template exists
if [ ! -f "$TEMPLATE_FILE" ]; then
    echo "Error: Template file not found: $TEMPLATE_FILE" >&2
    exit 1
fi

# Load config file if it exists
if [ -f "$CONFIG_FILE" ]; then
    echo "Loading configuration from: $CONFIG_FILE"
    set -a
    source "$CONFIG_FILE"
    set +a
else
    echo "Warning: Config file not found: $CONFIG_FILE" >&2
    echo "Using environment variables or defaults from template" >&2
fi

# Check required variables
if [ -z "$ENTRA_ID_TENANT_ID" ] || [ -z "$ENTRA_ID_CLIENT_ID" ] || [ -z "$ENTRA_ID_CLIENT_SECRET" ] || [ -z "$ENTRA_ID_ENABLED" ]; then
    echo "Error: Required environment variables not set:" >&2
    [ -z "$ENTRA_ID_TENANT_ID" ] && echo "  - ENTRA_ID_TENANT_ID" >&2
    [ -z "$ENTRA_ID_CLIENT_ID" ] && echo "  - ENTRA_ID_CLIENT_ID" >&2
    [ -z "$ENTRA_ID_CLIENT_SECRET" ] && echo "  - ENTRA_ID_CLIENT_SECRET" >&2
    [ -z "$ENTRA_ID_ENABLED" ] && echo "  - ENTRA_ID_ENABLED" >&2
    echo "" >&2
    echo "Set these variables in $CONFIG_FILE or as environment variables" >&2
    exit 1
fi

# Use envsubst to replace variables in template
# Note: envsubst replaces ${VAR} or $VAR patterns
envsubst < "$TEMPLATE_FILE" > "$OUTPUT_FILE"

echo "Generated realm-config.json successfully"
echo "Output file: $OUTPUT_FILE"

