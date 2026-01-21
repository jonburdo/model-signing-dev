echo "Unsetting environment variables..."

# List of variables to unset
VARS_TO_UNSET=(
  "MODEL_DIR"
  "IDENTITY_NAMESPACE"
  "SERVICE_ACCOUNT"
  "TAS_NAMESPACE"
  "IDENTITY_TOKEN_FILE"
  "OIDC_ISSUER"
  "CLIENT_ID"
  "IDENTITY_TOKEN"
  "FULCIO_URL"
  "REKOR_URL"
  "TUF_URL"
  "TSA_URL"
  "CLI_SERVER_URL"
  "ROOT_URL"
  "EXPECTED_IDENTITY"
)

# Unset each variable and report
for var in "${VARS_TO_UNSET[@]}"; do
  if [[ -n "${!var:-}" ]]; then
    echo "  Unset: $var (was: ${!var})"
    unset "$var"
  else
    echo "  Skip:  $var (not set)"
  fi
done

echo "Done."
