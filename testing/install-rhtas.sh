#!/bin/bash
set -euo pipefail

echo "Installing RHTAS Operator..."

# Install operator subscription
oc apply -f install-rhtas-operator.yaml

echo "Waiting for operator to install..."

# Wait for CSV to appear and be in Succeeded state
for i in {1..60}; do
    CSV_STATUS=$(oc get csv -n openshift-operators -o json | jq -r '.items[] | select(.metadata.name | startswith("rhtas-operator")) | .status.phase' 2>/dev/null || echo "")

    if [ "$CSV_STATUS" = "Succeeded" ]; then
        echo "RHTAS Operator installed successfully"
        oc get csv -n openshift-operators | grep rhtas
        break
    elif [ "$CSV_STATUS" = "Failed" ]; then
        echo "ERROR: Operator installation failed"
        oc get csv -n openshift-operators | grep rhtas
        exit 1
    else
        echo "Waiting... ($i/60)"
        sleep 5
    fi
done

if [ "$CSV_STATUS" != "Succeeded" ]; then
    echo "ERROR: Operator installation timed out"
    exit 1
fi

echo ""
echo "RHTAS Operator installation complete!"
echo ""
echo "Next steps:"
echo "  1. Generate Securesign instance: ./configure-securesign.sh"
echo "  2. Deploy Securesign: oc apply -f securesign-instance.yaml"
echo "  3. Wait for ready: oc get securesign -n trusted-artifact-signer -w"
echo "  4. Generate connection type: ./configure-connection-type.sh"
echo "  5. Deploy connection type: oc apply -f tas-connection-type.yaml"
