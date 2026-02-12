# Securesign Configuration

Dynamic OIDC issuer configuration using OpenShift Templates.

## Quick Start

### 0. Install RHTAS Operator (New Cluster Only)

```bash
# Install the operator
./install-rhtas.sh

# Or manually:
oc apply -f install-rhtas-operator.yaml

# Wait for operator to be ready
oc get csv -n openshift-operators | grep rhtas
```

### 1. Generate and Deploy Securesign Instance

```bash
# Generate configuration from cluster (external access enabled by default)
./configure-securesign.sh

# Or disable external access
./configure-securesign.sh false

# Apply to cluster
oc apply -f securesign-instance.yaml

# Wait for it to be ready (5-10 minutes)
oc get securesign -n trusted-artifact-signer -w
```

### 2. Generate and Deploy ODH Connection Type

```bash
# After Securesign is ready, generate connection type
./configure-connection-type.sh

# Apply to opendatahub namespace
oc apply -f tas-connection-type.yaml
```

## Manual Usage

### Set OIDC Issuer

```bash
APISERVER=$(oc whoami --show-server)
TOKEN=$(oc whoami -t)
OIDC_ISSUER=$(curl -sS -H "Authorization: Bearer $TOKEN" "$APISERVER/.well-known/openid-configuration" | jq -r '.issuer')

echo "OIDC Issuer: $OIDC_ISSUER"
```
Note:

On ROSA clusters, we get something that looks like: `https://rh-oidc.s3.us-east-1.amazonaws.com/14x289st4my8a167xq97d0mi2941klex`

On some clusters you might get an internal route that looks like: `https://kubernetes.default.svc`
This internal route may work (not confirmed) if the securesign instance is also on the cluster.

> Starting with Kubernetes 1.20+, the API server also acts as an OIDC provider:
> https://kubernetes.default.svc/.well-known/openid-configuration

### Process Template

```bash
# Dry-run (display only)
oc process -f securesign-instance.template.yaml \
  -p OIDC_ISSUER="$OIDC_ISSUER"

# Apply directly
oc process -f securesign-instance.template.yaml \
  -p OIDC_ISSUER="$OIDC_ISSUER" | oc apply -f -

# Save to file
oc process -f securesign-instance.template.yaml \
  -p OIDC_ISSUER="$OIDC_ISSUER" > securesign-instance.yaml
```

### Override Parameters

```bash
# Disable external access (cluster-internal only)
oc process -f securesign-instance.template.yaml \
  -p OIDC_ISSUER="$OIDC_ISSUER" \
  -p EXTERNAL_ACCESS="false" | oc apply -f -

# Customize all parameters
oc process -f securesign-instance.template.yaml \
  -p OIDC_ISSUER="$OIDC_ISSUER" \
  -p EXTERNAL_ACCESS="true" \
  -p NAMESPACE="my-custom-namespace" \
  -p ORGANIZATION_NAME="My Org" \
  -p ORGANIZATION_EMAIL="admin@myorg.com" | oc apply -f -
```

## Files

### Templates (commit to git)
- `namespace.yaml` - Namespace for Securesign instance
- `install-rhtas-operator.yaml` - RHTAS operator subscription
- `securesign-instance.template.yaml` - Securesign instance template
- `tas-connection-type.template.yaml` - ODH Connection Type template

### Scripts
- `install-rhtas.sh` - Install RHTAS operator on new cluster
- `configure-securesign.sh` - Generate Securesign instance configuration
- `configure-connection-type.sh` - Generate ODH Connection Type configuration

### Generated Files (add to .gitignore)
- `securesign-instance.yaml` - Securesign instance with cluster-specific values
- `tas-connection-type.yaml` - Connection Type with external routes

## Parameters

| Parameter | Description | Default |
|-----------|-------------|---------|
| `OIDC_ISSUER` | OIDC Issuer URL from cluster | (required) |
| `EXTERNAL_ACCESS` | Enable external routes for all services | `true` |
| `NAMESPACE` | Namespace for Securesign | `trusted-artifact-signer` |
| `ORGANIZATION_NAME` | Organization name for certs | `RHOAI` |
| `ORGANIZATION_EMAIL` | Organization email for certs | `admin@example.com` |
