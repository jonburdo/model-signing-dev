# Base configuration
export MODEL_DIR=${MODEL_DIR:-~/models/fraud-detection}
export IDENTITY_NAMESPACE=${IDENTITY_NAMESPACE:-project2}
export SERVICE_ACCOUNT=${SERVICE_ACCOUNT:-default}
export TAS_NAMESPACE=${TAS_NAMESPACE:-trusted-artifact-signer}

# Handle identity token
if [[ -n "${IDENTITY_TOKEN_FILE:-}" ]]; then
  echo "Using existing IDENTITY_TOKEN_FILE: $IDENTITY_TOKEN_FILE"
else
  # No token provided, extract from running pod
  IDENTITY_TOKEN_FILE=$(mktemp)
  IDENTITY_NAMESPACE="$IDENTITY_NAMESPACE" ./tokens/get-token-from-pod.sh > "$IDENTITY_TOKEN_FILE"
  echo "Extracted token from pod into IDENTITY_TOKEN_FILE: $IDENTITY_TOKEN_FILE"
fi
export IDENTITY_TOKEN_FILE

# Auto-detect service account from token if not explicitly set
if [[ "${SERVICE_ACCOUNT}" == "default" ]]; then
  DETECTED_SA=$(./tokens/detect-sa-from-token.sh "$IDENTITY_TOKEN_FILE" 2>/dev/null || echo "")
  if [[ -n "$DETECTED_SA" ]]; then
    export SERVICE_ACCOUNT="$DETECTED_SA"
    echo "Auto-detected SERVICE_ACCOUNT from token: $SERVICE_ACCOUNT"
  fi
fi

# Extract OIDC issuer and client_id from token
# Decode token payload once and extract both values
if [[ -z "${OIDC_ISSUER:-}" ]] || [[ -z "${CLIENT_ID:-}" ]]; then
  TOKEN_PAYLOAD=$(cat "$IDENTITY_TOKEN_FILE" | cut -d'.' -f2)
  case $((${#TOKEN_PAYLOAD} % 4)) in
    2) TOKEN_PAYLOAD="${TOKEN_PAYLOAD}==" ;;
    3) TOKEN_PAYLOAD="${TOKEN_PAYLOAD}=" ;;
  esac
  TOKEN_CLAIMS=$(echo "$TOKEN_PAYLOAD" | base64 -d 2>/dev/null)
  export OIDC_ISSUER=${OIDC_ISSUER:-$(echo "$TOKEN_CLAIMS" | jq -r '.iss')}
  export CLIENT_ID=${CLIENT_ID:-$(echo "$TOKEN_CLAIMS" | jq -r '.aud | if type == "array" then .[0] else . end')}
fi

export IDENTITY_TOKEN=${IDENTITY_TOKEN:-"$IDENTITY_TOKEN_FILE"}

# Fetch TAS service URLs
export FULCIO_URL=${FULCIO_URL:-https://$(oc get route -n "$TAS_NAMESPACE" -o json | jq -r '.items[] | select(.spec.to.name=="fulcio-server") | .spec.host' | head -1)}
export REKOR_URL=${REKOR_URL:-https://$(oc get route -n "$TAS_NAMESPACE" -o json | jq -r '.items[] | select(.spec.to.name=="rekor-server") | .spec.host' | head -1)}
export TUF_URL=${TUF_URL:-https://$(oc get route -n "$TAS_NAMESPACE" -o json | jq -r '.items[] | select(.spec.to.name=="tuf") | .spec.host' | head -1)}
export TSA_URL=${TSA_URL:-https://$(oc get route -n "$TAS_NAMESPACE" -o json | jq -r '.items[] | select(.spec.to.name=="tsa-server") | .spec.host' | head -1)}
export CLI_SERVER_URL=${CLI_SERVER_URL:-https://$(oc get route -n "$TAS_NAMESPACE" -o json | jq -r '.items[] | select(.spec.to.name=="cli-server") | .spec.host' | head -1)}

export ROOT_URL=${ROOT_URL:-"$TUF_URL/root.json"}

# Extract identity in Kubernetes URI format from token
export EXPECTED_IDENTITY=${EXPECTED_IDENTITY:-$(./tokens/get-kubernetes-identity.sh "$IDENTITY_TOKEN_FILE")}

# Print all environment variables
echo "================== Environment Variables =================="
echo "MODEL_DIR=$MODEL_DIR"
echo "IDENTITY_NAMESPACE=$IDENTITY_NAMESPACE"
echo "SERVICE_ACCOUNT=$SERVICE_ACCOUNT"
echo "TAS_NAMESPACE=$TAS_NAMESPACE"
echo "IDENTITY_TOKEN_FILE=$IDENTITY_TOKEN_FILE"
echo "IDENTITY_TOKEN=$IDENTITY_TOKEN"
echo "OIDC_ISSUER=$OIDC_ISSUER"
echo "CLIENT_ID=$CLIENT_ID"
echo "FULCIO_URL=$FULCIO_URL"
echo "REKOR_URL=$REKOR_URL"
echo "TUF_URL=$TUF_URL"
echo "TSA_URL=$TSA_URL"
echo "CLI_SERVER_URL=$CLI_SERVER_URL"
echo "ROOT_URL=$ROOT_URL"
echo "EXPECTED_IDENTITY=$EXPECTED_IDENTITY"
echo "==========================================================="
