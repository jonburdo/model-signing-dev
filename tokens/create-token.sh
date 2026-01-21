#!/bin/bash
set -eu

# Create a time-limited token using oc create token
# This is the recommended approach for K8s 1.24+ where token secrets aren't auto-created

IDENTITY_NAMESPACE=${IDENTITY_NAMESPACE:-project2}
SERVICE_ACCOUNT=${SERVICE_ACCOUNT:-default}
DURATION=${DURATION:-8h}

echo "Creating token for SA: $SERVICE_ACCOUNT in namespace: $IDENTITY_NAMESPACE (duration: $DURATION)" >&2

# Create a time-limited token
oc create token "$SERVICE_ACCOUNT" -n "$IDENTITY_NAMESPACE" --duration="$DURATION"
