# fix_foundry_dependencies.ps1
# Fixes missing dependencies for Microsoft Foundry Local

#Requires -RunAsAdministrator

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Foundry Local Dependency Fix" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

Write-Host "This script will install missing dependencies for Foundry Local." -ForegroundColor Yellow
Write-Host ""

# Install .NET Desktop Runtime 8
Write-Host "Installing .NET 8 Desktop Runtime..." -ForegroundColor Cyan
try {
    winget install Microsoft.DotNet.DesktopRuntime.8 --source winget --accept-package-agreements --accept-source-agreements --silent
    Write-Host "✓ .NET 8 Desktop Runtime installed" -ForegroundColor Green
} catch {
    Write-Warning "Failed to install .NET 8 Desktop Runtime"
}

# Install VC++ Redistributable
Write-Host "Installing Visual C++ Redistributable..." -ForegroundColor Cyan
try {
    winget install Microsoft.VCRedist.2015+.x64 --source winget --accept-package-agreements --accept-source-agreements --silent
    Write-Host "✓ VC++ Redistributable installed" -ForegroundColor Green
} catch {
    Write-Warning "Failed to install VC++ Redistributable"
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Dependencies Installed" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Please do the following:" -ForegroundColor Yellow
Write-Host "1. Reboot the VM (recommended)" -ForegroundColor White
Write-Host "2. After reboot, run install_foundry_local.ps1 again" -ForegroundColor White
Write-Host ""
Write-Host "Or if you don't want to reboot:" -ForegroundColor Yellow
Write-Host "1. Close this PowerShell window" -ForegroundColor White
Write-Host "2. Open a NEW PowerShell window as Administrator" -ForegroundColor White
Write-Host "3. Run: winget install Microsoft.FoundryLocal --source winget" -ForegroundColor White
Write-Host ""
