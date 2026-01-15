# Copy Scripts to VM Helper
# This script helps you copy bootstrap scripts to the VM via RDP

param(
    [Parameter(Mandatory=$true)]
    [string]$VMPublicIP
)

Write-Host "==================================================" -ForegroundColor Cyan
Write-Host "Copy Scripts to VM" -ForegroundColor Cyan
Write-Host "==================================================" -ForegroundColor Cyan
Write-Host "VM Public IP: $VMPublicIP" -ForegroundColor Yellow
Write-Host ""

Write-Host "Option 1: Manual Copy via RDP" -ForegroundColor Yellow
Write-Host "1. Connect to VM via RDP: mstsc /v:$VMPublicIP"
Write-Host "2. In RDP session, copy files from this repository to VM"
Write-Host "3. Place scripts in C:\FoundryDemo\ on the VM"
Write-Host ""

Write-Host "Option 2: Use PowerShell Remoting (if configured)" -ForegroundColor Yellow
Write-Host "# Enable PowerShell Remoting on VM first, then:"
Write-Host "`$cred = Get-Credential"
Write-Host "`$session = New-PSSession -ComputerName $VMPublicIP -Credential `$cred"
Write-Host "Copy-Item -ToSession `$session -Path ./vm/bootstrap/*.ps1 -Destination C:\FoundryDemo\"
Write-Host "Copy-Item -ToSession `$session -Path ./app/*.py -Destination C:\FoundryDemo\agent\"
Write-Host ""

Write-Host "Option 3: Azure Bastion (most secure)" -ForegroundColor Yellow
Write-Host "If you have Azure Bastion configured, use it for secure file transfer"
Write-Host ""
Write-Host "==================================================" -ForegroundColor Cyan
