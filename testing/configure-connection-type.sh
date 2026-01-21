#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TEMPLATE_FILE="${SCRIPT_DIR}/tas-connection-type.template.yaml"
OUTPUT_FILE="${SCRIPT_DIR}/tas-connection-type.yaml"

# Check if OIDC_ISSUER is already set as environment variable
if [ -z "${OIDC_ISSUER:-}" ]; then
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

# Get all routes in one call and extract what we need
ROUTES_JSON=$(oc get route -n trusted-artifact-signer -o json)

FULCIO_HOST=$(echo "$ROUTES_JSON" | jq -r '.items[] | select(.spec.to.name=="fulcio-server") | .spec.host // ""')
REKOR_HOST=$(echo "$ROUTES_JSON" | jq -r '.items[] | select(.spec.to.name=="rekor-server") | .spec.host // ""')
TSA_HOST=$(echo "$ROUTES_JSON" | jq -r '.items[] | select(.spec.to.name=="tsa-server") | .spec.host // ""')
TUF_HOST=$(echo "$ROUTES_JSON" | jq -r '.items[] | select(.spec.to.name=="tuf") | .spec.host // ""')
CLI_HOST=$(echo "$ROUTES_JSON" | jq -r '.items[] | select(.spec.to.name=="cli-server") | .spec.host // ""')

# Check if routes exist
if [ -z "$FULCIO_HOST" ] || [ -z "$REKOR_HOST" ] || [ -z "$TUF_HOST" ] || [ -z "$CLI_HOST" ]; then
    echo "ERROR: Could not find required external routes in trusted-artifact-signer namespace"
    echo "Make sure external access is enabled in the Securesign instance"
    echo ""
    echo "Found routes:"
    echo "  Fulcio: ${FULCIO_HOST:-NOT FOUND}"
    echo "  Rekor: ${REKOR_HOST:-NOT FOUND}"
    echo "  TSA: ${TSA_HOST:-NOT FOUND}"
    echo "  TUF: ${TUF_HOST:-NOT FOUND}"
    echo "  CLI: ${CLI_HOST:-NOT FOUND}"
    exit 1
fi

# Build full URLs
FULCIO_URL="https://${FULCIO_HOST}"
REKOR_URL="https://${REKOR_HOST}"
TSA_URL="https://${TSA_HOST}"
TUF_URL="https://${TUF_HOST}"
CLI_SERVER_URL="https://${CLI_HOST}"

# Process template
oc process -f "$TEMPLATE_FILE" \
  -p FULCIO_URL="$FULCIO_URL" \
  -p REKOR_URL="$REKOR_URL" \
  -p TSA_URL="$TSA_URL" \
  -p TUF_URL="$TUF_URL" \
  -p CLI_SERVER_URL="$CLI_SERVER_URL" \
  -p OIDC_ISSUER="$OIDC_ISSUER" \
  -o yaml > "$OUTPUT_FILE"

echo "Generated: ${OUTPUT_FILE}"
echo ""
echo "External Routes:"
echo "  Fulcio: ${FULCIO_URL}"
echo "  Rekor: ${REKOR_URL}"
echo "  TSA: ${TSA_URL}"
echo "  TUF: ${TUF_URL}"
echo "  CLI Server: ${CLI_SERVER_URL}"
echo "  OIDC Issuer: ${OIDC_ISSUER}"
echo ""
echo "To apply: oc apply -f ${OUTPUT_FILE}"
