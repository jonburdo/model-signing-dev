#!/bin/bash
# Create a TAS Connection Instance
#
# This script creates a connection instance (Secret) for Red Hat Trusted Artifact
# Signer by extracting URLs from a Securesign instance.
#
# Usage:
#   ./create-tas-connection.sh CONNECTION_NAME [SECURESIGN_NAMESPACE] [TARGET_NAMESPACE]
#
# Arguments:
#   CONNECTION_NAME       - Name for the connection instance
#   SECURESIGN_NAMESPACE  - Namespace containing Securesign instance (default: trusted-artifact-signer)
#   TARGET_NAMESPACE      - Namespace where connection will be created (default: current namespace)
#
# Example:
#   ./create-tas-connection.sh my-tas-connection
#   ./create-tas-connection.sh my-tas-connection trusted-artifact-signer my-project

set -euo pipefail

# Parse arguments
if [ $# -lt 1 ]; then
    echo "Usage: $0 CONNECTION_NAME [SECURESIGN_NAMESPACE] [TARGET_NAMESPACE]"
    echo ""
    echo "Arguments:"
    echo "  CONNECTION_NAME       - Name for the connection instance"
    echo "  SECURESIGN_NAMESPACE  - Namespace containing Securesign instance (default: trusted-artifact-signer)"
    echo "  TARGET_NAMESPACE      - Namespace where connection will be created (default: current namespace)"
    exit 1
fi

CONNECTION_NAME="$1"
SECURESIGN_NAMESPACE="${2:-trusted-artifact-signer}"
TARGET_NAMESPACE="${3:-$(oc project -q)}"

echo "Creating TAS connection instance..."
echo "  Connection name: ${CONNECTION_NAME}"
echo "  Securesign namespace: ${SECURESIGN_NAMESPACE}"
echo "  Target namespace: ${TARGET_NAMESPACE}"
echo ""

# Get the first Securesign instance in the namespace
SECURESIGN_JSON=$(oc get securesign -n "$SECURESIGN_NAMESPACE" -o json)
SECURESIGN_COUNT=$(echo "$SECURESIGN_JSON" | jq '.items | length')

if [ "$SECURESIGN_COUNT" -eq 0 ]; then
    echo "ERROR: No Securesign instance found in namespace ${SECURESIGN_NAMESPACE}"
    exit 1
fi

if [ "$SECURESIGN_COUNT" -gt 1 ]; then
    echo "WARNING: Multiple Securesign instances found. Using the first one."
    echo "Available instances:"
    echo "$SECURESIGN_JSON" | jq -r '.items[].metadata.name'
    echo ""
fi

# Extract URLs from the first Securesign instance
FULCIO_URL=$(echo "$SECURESIGN_JSON" | jq -r '.items[0].status.fulcio.url // empty')
REKOR_URL=$(echo "$SECURESIGN_JSON" | jq -r '.items[0].status.rekor.url // empty')
TSA_URL=$(echo "$SECURESIGN_JSON" | jq -r '.items[0].status.tsa.url // empty')
TUF_URL=$(echo "$SECURESIGN_JSON" | jq -r '.items[0].status.tuf.url // empty')

# Validate all required URLs are present
if [ -z "$FULCIO_URL" ] || [ -z "$REKOR_URL" ] || [ -z "$TUF_URL" ]; then
    echo "ERROR: Could not extract all required URLs from Securesign instance"
    echo "  Fulcio URL: ${FULCIO_URL:-NOT FOUND}"
    echo "  Rekor URL: ${REKOR_URL:-NOT FOUND}"
    echo "  TSA URL: ${TSA_URL:-NOT FOUND}"
    echo "  TUF URL: ${TUF_URL:-NOT FOUND}"
    echo ""
    echo "Make sure the Securesign instance is fully deployed and has status.*.url fields"
    exit 1
fi

echo "Extracted URLs from Securesign instance:"
echo "  SIGSTORE_FULCIO_URL: ${FULCIO_URL}"
echo "  SIGSTORE_REKOR_URL: ${REKOR_URL}"
echo "  SIGSTORE_TSA_URL: ${TSA_URL}"
echo "  SIGSTORE_TUF_URL: ${TUF_URL}"
echo ""

# Create connection instance Secret
cat <<EOF | oc apply -f -
apiVersion: v1
kind: Secret
metadata:
  name: ${CONNECTION_NAME}
  namespace: ${TARGET_NAMESPACE}
  labels:
    opendatahub.io/dashboard: "true"
  annotations:
    opendatahub.io/connection-type-ref: tas-securesign-v1
    openshift.io/display-name: "${CONNECTION_NAME}"
    openshift.io/description: ""
type: Opaque
stringData:
  SIGSTORE_TUF_URL: "${TUF_URL}"
  SIGSTORE_FULCIO_URL: "${FULCIO_URL}"
  SIGSTORE_REKOR_URL: "${REKOR_URL}"
  SIGSTORE_TSA_URL: "${TSA_URL}"
EOF

echo ""
echo "✓ Connection instance '${CONNECTION_NAME}' created successfully in namespace '${TARGET_NAMESPACE}'"
echo ""
echo "To view the connection:"
echo "  oc get secret ${CONNECTION_NAME} -n ${TARGET_NAMESPACE} -o yaml"
echo ""
echo "To delete the connection:"
echo "  oc delete secret ${CONNECTION_NAME} -n ${TARGET_NAMESPACE}"
