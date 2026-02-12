#!/bin/bash
# Configure ODH Connection Type for Red Hat Trusted Artifact Signer
#
# This script generates an ODH connection type configuration from the
# Trusted Artifact Signer (TAS) routes in your OpenShift cluster.
#
# Usage:
#   ./configure-connection-type.sh           # Generate config map only
#   source ./configure-connection-type.sh --export  # Generate and keep vars in shell
#
# The --export option (when sourced) makes these variables available in your shell:
#   SIGSTORE_FULCIO_URL, SIGSTORE_REKOR_URL, SIGSTORE_TSA_URL, SIGSTORE_TUF_URL

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TEMPLATE_FILE="${SCRIPT_DIR}/tas-connection-type.template.yaml"
OUTPUT_FILE="${SCRIPT_DIR}/tas-connection-type.yaml"

# Parse arguments
EXPORT_ENV=false
if [[ "${1:-}" == "--export" ]]; then
    EXPORT_ENV=true
fi

# Get all routes in one call and extract what we need
ROUTES_JSON=$(oc get route -n trusted-artifact-signer -o json)

FULCIO_HOST=$(echo "$ROUTES_JSON" | jq -r '.items[] | select(.spec.to.name=="fulcio-server") | .spec.host // ""')
REKOR_HOST=$(echo "$ROUTES_JSON" | jq -r '.items[] | select(.spec.to.name=="rekor-server") | .spec.host // ""')
TSA_HOST=$(echo "$ROUTES_JSON" | jq -r '.items[] | select(.spec.to.name=="tsa-server") | .spec.host // ""')
TUF_HOST=$(echo "$ROUTES_JSON" | jq -r '.items[] | select(.spec.to.name=="tuf") | .spec.host // ""')

# Check if routes exist
if [ -z "$FULCIO_HOST" ] || [ -z "$REKOR_HOST" ] || [ -z "$TUF_HOST" ]; then
    echo "ERROR: Could not find required external routes in trusted-artifact-signer namespace"
    echo "Make sure external access is enabled in the Securesign instance"
    echo ""
    echo "Found routes:"
    echo "  Fulcio: ${FULCIO_HOST:-NOT FOUND}"
    echo "  Rekor: ${REKOR_HOST:-NOT FOUND}"
    echo "  TSA: ${TSA_HOST:-NOT FOUND}"
    echo "  TUF: ${TUF_HOST:-NOT FOUND}"
    exit 1
fi

# Build full URLs with SIGSTORE_ prefix
SIGSTORE_FULCIO_URL="https://${FULCIO_HOST}"
SIGSTORE_REKOR_URL="https://${REKOR_HOST}"
SIGSTORE_TSA_URL="https://${TSA_HOST}"
SIGSTORE_TUF_URL="https://${TUF_HOST}"

# Process template with oc - extract just the ConfigMap from the List
oc process -f "$TEMPLATE_FILE" \
  -p SIGSTORE_FULCIO_URL="$SIGSTORE_FULCIO_URL" \
  -p SIGSTORE_REKOR_URL="$SIGSTORE_REKOR_URL" \
  -p SIGSTORE_TSA_URL="$SIGSTORE_TSA_URL" \
  -p SIGSTORE_TUF_URL="$SIGSTORE_TUF_URL" \
  -o yaml | yq eval '.items[0]' - > "$OUTPUT_FILE"

# Export SIGSTORE_* variables if requested
if [ "$EXPORT_ENV" = true ]; then
    export SIGSTORE_FULCIO_URL
    export SIGSTORE_REKOR_URL
    export SIGSTORE_TSA_URL
    export SIGSTORE_TUF_URL
fi

echo "Generated: ${OUTPUT_FILE}"
echo ""
echo "Signing Configuration:"
echo "  SIGSTORE_FULCIO_URL=${SIGSTORE_FULCIO_URL}"
echo "  SIGSTORE_REKOR_URL=${SIGSTORE_REKOR_URL}"
echo "  SIGSTORE_TSA_URL=${SIGSTORE_TSA_URL}"
echo "  SIGSTORE_TUF_URL=${SIGSTORE_TUF_URL}"
echo ""

if [ "$EXPORT_ENV" = true ]; then
    echo "Environment variables exported for Python client"
    echo "To use in current shell: source ${BASH_SOURCE[0]} --export"
    echo ""
fi

echo "To apply: oc apply -f ${OUTPUT_FILE} -n opendatahub"
echo "To update: oc replace -f ${OUTPUT_FILE} -n opendatahub"
