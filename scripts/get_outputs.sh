#!/bin/bash
# Get deployment outputs
# Usage: ./get_outputs.sh <resource-group-name>

RG_NAME="${1}"

if [ -z "$RG_NAME" ]; then
  echo "Usage: ./get_outputs.sh <resource-group-name>"
  exit 1
fi

echo "=================================================="
echo "Deployment Outputs"
echo "=================================================="

az deployment group show \
  --resource-group "$RG_NAME" \
  --name "vm-deployment" \
  --query 'properties.outputs' \
  --output table

echo ""
echo "To get VM public IP:"
echo "az deployment group show -g $RG_NAME -n vm-deployment --query 'properties.outputs.vmPublicIp.value' -o tsv"
