#!/bin/bash
set -eu

# Read token from a running pod's mounted service account token
# Connects to a pod via oc exec and reads the token file
# Also detects and exports the service account name

IDENTITY_NAMESPACE=${IDENTITY_NAMESPACE:-project2}
POD_NAME=${POD_NAME:-}
CONTAINER_NAME=${CONTAINER_NAME:-}
TOKEN_PATH=${TOKEN_PATH:-/var/run/secrets/kubernetes.io/serviceaccount/token}
OUTPUT_ENV=${OUTPUT_ENV:-false}

echo "Getting token from pod in namespace: $IDENTITY_NAMESPACE" >&2

# If no pod name provided, try to find one
if [[ -z "$POD_NAME" ]]; then
  echo "No POD_NAME provided, searching for running pods..." >&2
  POD_NAME=$(oc get pods -n "$IDENTITY_NAMESPACE" -o json | \
    jq -r '.items[] | select(.status.phase=="Running") | .metadata.name' | head -1)

  if [[ -z "$POD_NAME" ]]; then
    echo "Error: No running pods found in namespace $IDENTITY_NAMESPACE" >&2
    exit 1
  fi
  echo "Found pod: $POD_NAME" >&2
fi

# Get the service account that the pod is using
DETECTED_SA=$(oc get pod "$POD_NAME" -n "$IDENTITY_NAMESPACE" -o jsonpath='{.spec.serviceAccountName}')
if [[ -z "$DETECTED_SA" ]]; then
  DETECTED_SA="default"
fi
echo "Pod is using service account: $DETECTED_SA" >&2

# If no container name provided, use the first one
if [[ -z "$CONTAINER_NAME" ]]; then
  CONTAINER_NAME=$(oc get pod "$POD_NAME" -n "$IDENTITY_NAMESPACE" -o jsonpath='{.spec.containers[0].name}')
  echo "Using container: $CONTAINER_NAME" >&2
fi

echo "Reading token from $TOKEN_PATH" >&2

# Execute cat command in the pod to read the token
TOKEN=$(oc exec "$POD_NAME" -n "$IDENTITY_NAMESPACE" -c "$CONTAINER_NAME" -- cat "$TOKEN_PATH")

# Output format options
if [[ "$OUTPUT_ENV" == "true" ]]; then
  # Output as environment variable exports
  echo "export SERVICE_ACCOUNT='$DETECTED_SA'"
  echo "export IDENTITY_NAMESPACE='$IDENTITY_NAMESPACE'"
  echo "export TOKEN='$TOKEN'"
else
  # Just output the token (default)
  echo "$TOKEN"
fi
