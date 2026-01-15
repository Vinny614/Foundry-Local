# Lock Down VM for Offline Operation
# This script configures Windows Firewall to block all outbound connections

$ErrorActionPreference = "Stop"

Write-Host "==================================================" -ForegroundColor Cyan
Write-Host "Offline Lock-Down Script" -ForegroundColor Cyan
Write-Host "==================================================" -ForegroundColor Cyan
Write-Warning "This script will block ALL outbound internet traffic!"
Write-Host "Press Ctrl+C within 10 seconds to cancel..." -ForegroundColor Yellow

Start-Sleep -Seconds 10

# Check for admin rights
if (-NOT ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Error "This script must be run as Administrator"
    exit 1
}

# Step 1: Windows Firewall - Block outbound
Write-Host "Configuring Windows Firewall to block outbound traffic..." -ForegroundColor Yellow

try {
    # Set default outbound action to Block for all profiles
    Set-NetFirewallProfile -Profile Domain,Public,Private -DefaultOutboundAction Block
    Write-Host "Windows Firewall outbound traffic blocked" -ForegroundColor Green
} catch {
    Write-Error "Failed to configure Windows Firewall: $_"
    exit 1
}

# Step 2: Verify localhost is still allowed
Write-Host "Ensuring localhost traffic is still allowed..." -ForegroundColor Yellow
try {
    # Create rule to allow localhost traffic
    New-NetFirewallRule -DisplayName "Allow Localhost" `
        -Direction Outbound `
        -Action Allow `
        -RemoteAddress 127.0.0.1,::1 `
        -ErrorAction SilentlyContinue | Out-Null
    
    Write-Host "Localhost traffic allowed" -ForegroundColor Green
} catch {
    Write-Host "Localhost rule already exists or created" -ForegroundColor Yellow
}

# Step 3: Document NSG changes for Azure
Write-Host "`nDocumenting NSG changes for Azure Portal..." -ForegroundColor Yellow
$nsgInstructions = @"
=================================================
OPTIONAL: Azure NSG Egress Deny Configuration
=================================================

To completely block outbound traffic at the Azure network level:

1. Go to Azure Portal
2. Navigate to your Resource Group
3. Open the Network Security Group (NSG)
4. Click on "Outbound security rules"
5. Add a new rule:
   - Name: DenyAllOutbound
   - Priority: 100
   - Source: Any
   - Source port ranges: *
   - Destination: Any
   - Destination port ranges: *
   - Protocol: Any
   - Action: Deny

This ensures no traffic can leave the VM at the network layer.
=================================================
"@

$nsgInstructions | Out-File -FilePath "C:\FoundryDemo\nsg_instructions.txt" -Encoding UTF8
Write-Host "NSG instructions saved to: C:\FoundryDemo\nsg_instructions.txt" -ForegroundColor Green

# Step 4: Create unlock script
Write-Host "Creating unlock script for later..." -ForegroundColor Yellow
$unlockScript = @"
# Unlock VM - Restore Internet Connectivity
# Run this script as Administrator to restore outbound connectivity

`$ErrorActionPreference = "Stop"

Write-Host "Restoring outbound internet connectivity..." -ForegroundColor Yellow

# Restore default outbound action to Allow
Set-NetFirewallProfile -Profile Domain,Public,Private -DefaultOutboundAction Allow

Write-Host "Internet connectivity restored!" -ForegroundColor Green
Write-Host "You may also need to remove the NSG egress deny rule in Azure Portal." -ForegroundColor Yellow
"@

$unlockScript | Out-File -FilePath "C:\FoundryDemo\unlock_offline.ps1" -Encoding UTF8
Write-Host "Unlock script saved to: C:\FoundryDemo\unlock_offline.ps1" -ForegroundColor Green

Write-Host ""
Write-Host "==================================================" -ForegroundColor Cyan
Write-Host "VM Locked Down for Offline Operation!" -ForegroundColor Green
Write-Host "==================================================" -ForegroundColor Cyan
Write-Host "Status:" -ForegroundColor Yellow
Write-Host "  - Windows Firewall: Outbound traffic BLOCKED" -ForegroundColor Red
Write-Host "  - Localhost: Traffic ALLOWED" -ForegroundColor Green
Write-Host "  - NSG: Manual configuration required (optional)" -ForegroundColor Yellow
Write-Host ""
Write-Host "To restore connectivity:" -ForegroundColor Yellow
Write-Host "  C:\FoundryDemo\unlock_offline.ps1" -ForegroundColor Cyan
Write-Host ""
Write-Host "==================================================" -ForegroundColor Cyan
Write-Host "Next Step: Run verify_offline.ps1 to verify" -ForegroundColor Green
Write-Host "==================================================" -ForegroundColor Cyan
