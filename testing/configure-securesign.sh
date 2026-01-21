#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TEMPLATE_FILE="${SCRIPT_DIR}/securesign-instance.template.yaml"
OUTPUT_FILE="${SCRIPT_DIR}/securesign-instance.yaml"

# Optional parameter: EXTERNAL_ACCESS (default: true)
EXTERNAL_ACCESS="${1:-true}"

# Ensure namespace exists
echo "Ensuring trusted-artifact-signer namespace exists..."
oc apply -f "${SCRIPT_DIR}/namespace.yaml"

# Check if OIDC_ISSUER is already set as environment variable
if [ -z "${OIDC_ISSUER:-}" ]; then
    # OIDC_ISSUER not set, fetch from cluster
    APISERVER=$(oc whoami --show-server)
    TOKEN=$(oc whoami -t)

    OIDC_ISSUER=$(curl -sS -H "Authorization: Bearer $TOKEN" "$APISERVER/.well-known/openid-configuration" | jq -r '.issuer')

    if [ -z "$OIDC_ISSUER" ] || [ "$OIDC_ISSUER" = "null" ]; then
        echo "ERROR: Failed to fetch OIDC issuer from cluster"
        exit 1
    fi
else
    echo "Using OIDC_ISSUER from environment variable"
fi

# Process template and save to file
oc process -f "$TEMPLATE_FILE" \
  -p OIDC_ISSUER="$OIDC_ISSUER" \
  -p EXTERNAL_ACCESS="$EXTERNAL_ACCESS" \
  -o yaml > "$OUTPUT_FILE"

echo "Generated: ${OUTPUT_FILE}"
echo "OIDC Issuer: ${OIDC_ISSUER}"
echo "External Access: ${EXTERNAL_ACCESS}"
echo ""
echo "To apply: oc apply -f ${OUTPUT_FILE}"
