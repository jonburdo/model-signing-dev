#!/bin/bash
set -eu

# Decode and display JWT token contents

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

echo "=== JWT Header ==="
echo "$TOKEN" | cut -d'.' -f1 | base64 -d 2>/dev/null | jq .

echo ""
echo "=== JWT Payload ==="
PAYLOAD=$(echo "$TOKEN" | cut -d'.' -f2)
# Add padding if needed
case $((${#PAYLOAD} % 4)) in
  2) PAYLOAD="${PAYLOAD}==" ;;
  3) PAYLOAD="${PAYLOAD}=" ;;
esac
echo "$PAYLOAD" | base64 -d 2>/dev/null | jq .
