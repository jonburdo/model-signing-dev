#!/bin/bash
set -eu

# Extract service account name from a JWT token
# Uses kubernetes.io claim if available (preferred), falls back to parsing sub

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

# JWT tokens have 3 parts separated by dots: header.payload.signature
# We need the payload (middle part)
PAYLOAD=$(echo "$TOKEN" | cut -d'.' -f2)

# Add padding if needed (base64 requires length to be multiple of 4)
case $((${#PAYLOAD} % 4)) in
  2) PAYLOAD="${PAYLOAD}==" ;;
  3) PAYLOAD="${PAYLOAD}=" ;;
esac

CLAIMS=$(echo "$PAYLOAD" | base64 -d 2>/dev/null)

# Try to extract from kubernetes.io structured claim (preferred)
SERVICE_ACCOUNT=$(echo "$CLAIMS" | jq -r '."kubernetes.io".serviceaccount.name // empty' 2>/dev/null)

if [[ -n "$SERVICE_ACCOUNT" ]]; then
  echo "$SERVICE_ACCOUNT"
  exit 0
fi

# Fallback: parse sub claim
# Subject format is: system:serviceaccount:NAMESPACE:SERVICEACCOUNT
# Extract the service account name (last field)
SUBJECT=$(echo "$CLAIMS" | jq -r '.sub // empty' 2>/dev/null)

if [[ -z "$SUBJECT" ]]; then
  echo "Error: Could not parse token or extract service account" >&2
  exit 1
fi

SERVICE_ACCOUNT=$(echo "$SUBJECT" | cut -d':' -f4)

if [[ -z "$SERVICE_ACCOUNT" ]]; then
  echo "Error: Could not extract service account from subject: $SUBJECT" >&2
  exit 1
fi

echo "$SERVICE_ACCOUNT"
