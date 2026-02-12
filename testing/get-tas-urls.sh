#!/bin/bash
# Get TAS URLs from Securesign instance
# Usage: ./get-tas-urls.sh NAMESPACE

set -euo pipefail

NAMESPACE="${1:?ERROR: Namespace argument required}"

SECURESIGN=$(oc get securesign -n "$NAMESPACE" -o json)

echo "SIGSTORE_TUF_URL=$(echo "$SECURESIGN" | jq -r '.items[0].status.tuf.url')"
echo "SIGSTORE_FULCIO_URL=$(echo "$SECURESIGN" | jq -r '.items[0].status.fulcio.url')"
echo "SIGSTORE_REKOR_URL=$(echo "$SECURESIGN" | jq -r '.items[0].status.rekor.url')"
echo "SIGSTORE_TSA_URL=$(echo "$SECURESIGN" | jq -r '.items[0].status.tsa.url')"
