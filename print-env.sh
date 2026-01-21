#!/bin/bash

# Print all environment variables set by setup-env.sh

echo "================== Environment Variables =================="

# List of variables to print
VARS_TO_PRINT=(
  "MODEL_DIR"
  "IDENTITY_NAMESPACE"
  "SERVICE_ACCOUNT"
  "TAS_NAMESPACE"
  "IDENTITY_TOKEN_FILE"
  "IDENTITY_TOKEN"
  "OIDC_ISSUER"
  "CLIENT_ID"
  "FULCIO_URL"
  "REKOR_URL"
  "TUF_URL"
  "TSA_URL"
  "CLI_SERVER_URL"
  "ROOT_URL"
  "EXPECTED_IDENTITY"
)

# Print each variable
for var in "${VARS_TO_PRINT[@]}"; do
  if [[ -n "${!var:-}" ]]; then
    echo "$var=${!var}"
  else
    echo "$var=(not set)"
  fi
done

echo "==========================================================="
