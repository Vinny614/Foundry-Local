# Get Deployment Outputs
# Usage: .\get_outputs.ps1 -ResourceGroupName <name>

param(
    [Parameter(Mandatory=$true)]
    [string]$ResourceGroupName
)

Write-Host "==================================================" -ForegroundColor Cyan
Write-Host "Deployment Outputs" -ForegroundColor Cyan
Write-Host "==================================================" -ForegroundColor Cyan

az deployment group show `
  --resource-group $ResourceGroupName `
  --name "vm-deployment" `
  --query 'properties.outputs' `
  --output table

Write-Host ""
Write-Host "To get VM public IP:" -ForegroundColor Yellow
Write-Host "az deployment group show -g $ResourceGroupName -n vm-deployment --query 'properties.outputs.vmPublicIp.value' -o tsv"
