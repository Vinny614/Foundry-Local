# Deploy the Foundry Local infrastructure using Azure CLI
# Usage: .\deploy.ps1 -ResourceGroupName <name> [-Location <location>]

param(
    [Parameter(Mandatory=$true)]
    [string]$ResourceGroupName,
    
    [Parameter(Mandatory=$false)]
    [string]$Location = "eastus"
)

$ErrorActionPreference = "Stop"

Write-Host "==================================================" -ForegroundColor Cyan
Write-Host "Foundry Local Infrastructure Deployment" -ForegroundColor Cyan
Write-Host "==================================================" -ForegroundColor Cyan
Write-Host "Resource Group: $ResourceGroupName" -ForegroundColor Yellow
Write-Host "Location: $Location" -ForegroundColor Yellow
Write-Host "==================================================" -ForegroundColor Cyan

# Check if resource group exists
$rgExists = az group exists --name $ResourceGroupName
if ($rgExists -eq "false") {
    Write-Host "Creating resource group: $ResourceGroupName" -ForegroundColor Green
    az group create --name $ResourceGroupName --location $Location
} else {
    Write-Host "Resource group already exists: $ResourceGroupName" -ForegroundColor Yellow
}

# Get admin password securely
$adminPassword = Read-Host "Enter VM Admin Password" -AsSecureString
$adminPasswordText = [Runtime.InteropServices.Marshal]::PtrToStringAuto(
    [Runtime.InteropServices.Marshal]::SecureStringToBSTR($adminPassword))

# Deploy using Bicep
Write-Host "Deploying infrastructure..." -ForegroundColor Green
az deployment group create `
    --resource-group $ResourceGroupName `
    --template-file ./main.bicep `
    --parameters ./main.bicepparam `
    --parameters adminPassword="$adminPasswordText" `
    --query 'properties.outputs' `
    --output table

Write-Host ""
Write-Host "==================================================" -ForegroundColor Cyan
Write-Host "Deployment completed successfully!" -ForegroundColor Green
Write-Host "==================================================" -ForegroundColor Cyan
Write-Host "Next steps:" -ForegroundColor Yellow
Write-Host "1. RDP to the VM using the public IP from outputs"
Write-Host "2. Copy the /vm/bootstrap scripts to the VM"
Write-Host "3. Run bootstrap scripts in this order:"
Write-Host "   - install_foundry_local.ps1"
Write-Host "   - install_db_and_seed_data.ps1"
Write-Host "   - start_mcp_server.ps1"
Write-Host "4. Copy and run the /app agent application"
Write-Host "5. Run lock_down_offline.ps1 to disconnect"
Write-Host "6. Run verify_offline.ps1 to verify offline operation"
Write-Host "==================================================" -ForegroundColor Cyan
