#!/bin/bash
set -eu

# Extract Kubernetes identity in URI format from token
# Uses kubernetes.io claim if available (preferred), falls back to parsing sub
# Output: https://kubernetes.io/namespaces/NAMESPACE/serviceaccounts/SERVICEACCOUNT

TOKEN_FILE=${1:-}

if [[ -z "$TOKEN_FILE" ]]; then
  echo "Usage: $0 <token-file-path>" >&2
  echo "   or: echo \$TOKEN | $0 -" >&2
  exit 1
fi

# Read token from file or stdin
if [[ "$TOKEN_FILE" == "-" ]]; then
  TOKEN=$(cat)
else
  TOKEN=$(cat "$TOKEN_FILE")
fi

# Decode payload
PAYLOAD=$(echo "$TOKEN" | cut -d'.' -f2)
case $((${#PAYLOAD} % 4)) in
  2) PAYLOAD="${PAYLOAD}==" ;;
  3) PAYLOAD="${PAYLOAD}=" ;;
esac

CLAIMS=$(echo "$PAYLOAD" | base64 -d 2>/dev/null)

# Try to extract from kubernetes.io structured claim (preferred)
NAMESPACE=$(echo "$CLAIMS" | jq -r '."kubernetes.io".namespace // empty' 2>/dev/null)
SERVICEACCOUNT=$(echo "$CLAIMS" | jq -r '."kubernetes.io".serviceaccount.name // empty' 2>/dev/null)

if [[ -n "$NAMESPACE" && -n "$SERVICEACCOUNT" ]]; then
  # Found structured Kubernetes claims
  echo "https://kubernetes.io/namespaces/$NAMESPACE/serviceaccounts/$SERVICEACCOUNT"
  exit 0
fi

# Fallback: parse sub claim
SUB=$(echo "$CLAIMS" | jq -r '.sub // empty' 2>/dev/null)

if [[ -z "$SUB" ]]; then
  echo "Error: Could not extract Kubernetes identity from token" >&2
  exit 1
fi

# Parse: system:serviceaccount:NAMESPACE:SERVICEACCOUNT
if [[ ! "$SUB" =~ ^system:serviceaccount:([^:]+):([^:]+)$ ]]; then
  echo "Error: sub claim is not in service account format: $SUB" >&2
  exit 1
fi

NAMESPACE="${BASH_REMATCH[1]}"
SERVICEACCOUNT="${BASH_REMATCH[2]}"

# Output in Kubernetes URI format
echo "https://kubernetes.io/namespaces/$NAMESPACE/serviceaccounts/$SERVICEACCOUNT"
