#!/bin/bash
# Deploy the Foundry Local infrastructure using Azure CLI
# Usage: ./deploy.sh <resource-group-name> [location]

set -e

RG_NAME="${1}"
LOCATION="${2:-eastus}"

if [ -z "$RG_NAME" ]; then
  echo "Usage: ./deploy.sh <resource-group-name> [location]"
  echo "Example: ./deploy.sh foundry-demo-rg eastus"
  exit 1
fi

echo "=================================================="
echo "Foundry Local Infrastructure Deployment"
echo "=================================================="
echo "Resource Group: $RG_NAME"
echo "Location: $LOCATION"
echo "=================================================="

# Check if resource group exists
if ! az group show --name "$RG_NAME" &>/dev/null; then
  echo "Creating resource group: $RG_NAME"
  az group create --name "$RG_NAME" --location "$LOCATION"
else
  echo "Resource group already exists: $RG_NAME"
fi

# Get admin password securely
read -sp 'Enter VM Admin Password: ' ADMIN_PASSWORD
echo ""

# Deploy using Bicep
echo "Deploying infrastructure..."
echo "Note: Using Standard_D8s_v3 (8 vCPU, 32GB RAM) for better availability"
az deployment group create \
  --resource-group "$RG_NAME" \
  --template-file ./main.bicep \
  --parameters namingPrefix=foundry \
  --parameters location="$LOCATION" \
  --parameters adminUsername=azureuser \
  --parameters adminPassword="$ADMIN_PASSWORD" \
  --parameters allowedRdpSourceIp='0.0.0.0/0' \
  --parameters vmSize='Standard_D8s_v3' \
  --parameters vnetAddressPrefix='10.0.0.0/16' \
  --parameters subnetAddressPrefix='10.0.1.0/24' \
  --parameters tags='{"Environment":"Demo","Project":"Foundry-Local-MCP","Purpose":"Offline-AI-Demo"}' \
  --query 'properties.outputs' \
  --output table

echo ""
echo "=================================================="
echo "Deployment completed successfully!"
echo "=================================================="
echo "Next steps:"
echo "1. RDP to the VM using the public IP from outputs"
echo "2. Run bootstrap scripts in this order:"
echo "   - install_foundry_local.ps1"
echo "   - install_db_and_seed_data.ps1"
echo "   - start_mcp_server.ps1"
echo "3. Test the agent application"
echo "4. Run lock_down_offline.ps1 to disconnect"
echo "5. Run verify_offline.ps1 to verify offline operation"
echo "=================================================="
