# Install Foundry Local on Windows VM
# This script downloads, installs, and configures Foundry Local
# Then downloads and caches a Phi model for offline use

$ErrorActionPreference = "Stop"
$ProgressPreference = 'SilentlyContinue'

Write-Host "==================================================" -ForegroundColor Cyan
Write-Host "Foundry Local Installation Script" -ForegroundColor Cyan
Write-Host "==================================================" -ForegroundColor Cyan

# Check for admin rights
if (-NOT ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Error "This script must be run as Administrator"
    exit 1
}

# Step 1: Check prerequisites
Write-Host "Checking prerequisites..." -ForegroundColor Yellow
$ram = (Get-CimInstance Win32_ComputerSystem).TotalPhysicalMemory / 1GB
Write-Host "System RAM: $([math]::Round($ram, 2)) GB" -ForegroundColor Green

if ($ram -lt 8) {
    Write-Warning "System has less than 8 GB RAM. Foundry Local may not perform optimally."
}

# Step 2: Install winget if not present
Write-Host "Checking for winget..." -ForegroundColor Yellow
try {
    $wingetVersion = winget --version
    Write-Host "winget is installed: $wingetVersion" -ForegroundColor Green
} catch {
    Write-Host "Installing winget..." -ForegroundColor Yellow
    # Download and install App Installer (winget)
    $progressPreference = 'silentlyContinue'
    Write-Host "Downloading winget dependencies..." -ForegroundColor Yellow
    
    # Install VCLibs
    $vcLibsUrl = "https://aka.ms/Microsoft.VCLibs.x64.14.00.Desktop.appx"
    Invoke-WebRequest -Uri $vcLibsUrl -OutFile "$env:TEMP\VCLibs.appx" -UseBasicParsing
    Add-AppxPackage -Path "$env:TEMP\VCLibs.appx"
    
    # Install UI.Xaml
    $uiXamlUrl = "https://github.com/microsoft/microsoft-ui-xaml/releases/download/v2.8.6/Microsoft.UI.Xaml.2.8.x64.appx"
    Invoke-WebRequest -Uri $uiXamlUrl -OutFile "$env:TEMP\UIXaml.appx" -UseBasicParsing
    Add-AppxPackage -Path "$env:TEMP\UIXaml.appx"
    
    # Install winget
    $wingetUrl = "https://github.com/microsoft/winget-cli/releases/latest/download/Microsoft.DesktopAppInstaller_8wekyb3d8bbwe.msixbundle"
    Invoke-WebRequest -Uri $wingetUrl -OutFile "$env:TEMP\winget.msixbundle" -UseBasicParsing
    Add-AppxPackage -Path "$env:TEMP\winget.msixbundle"
    
    # Refresh PATH
    $env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")
    
    Write-Host "winget installed successfully" -ForegroundColor Green
    Start-Sleep -Seconds 5
}

# Step 3: Install Foundry Local using winget
Write-Host "Installing Foundry Local..." -ForegroundColor Yellow
try {
    winget install Microsoft.FoundryLocal --accept-source-agreements --accept-package-agreements
    Write-Host "Foundry Local installed successfully" -ForegroundColor Green
} catch {
    Write-Host "Installation encountered an issue, checking if already installed..." -ForegroundColor Yellow
}

# Step 4: Verify installation
Write-Host "Verifying Foundry Local installation..." -ForegroundColor Yellow
Start-Sleep -Seconds 5

# Refresh PATH
$env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")

try {
    $foundryVersion = foundry --version
    Write-Host "Foundry Local is installed: $foundryVersion" -ForegroundColor Green
} catch {
    Write-Error "Foundry Local installation verification failed. The 'foundry' command is not available."
    exit 1
}

# Step 5: Start Foundry Local service
Write-Host "Starting Foundry Local service..." -ForegroundColor Yellow
try {
    foundry service start
    Start-Sleep -Seconds 10
    $serviceStatus = foundry service status
    Write-Host "Service Status: $serviceStatus" -ForegroundColor Green
} catch {
    Write-Warning "Service start encountered an issue: $_"
}

# Step 6: List available models
Write-Host "Listing available models..." -ForegroundColor Yellow
try {
    foundry model list
} catch {
    Write-Warning "Could not list models: $_"
}

# Step 7: Download and cache Phi model for offline use
Write-Host "Downloading Phi model for offline caching..." -ForegroundColor Yellow
Write-Host "This may take several minutes depending on your internet connection." -ForegroundColor Cyan

# Using phi-3-mini-4k-instruct (smaller, faster for demo)
$modelAlias = "phi-3-mini-4k-instruct"

try {
    Write-Host "Downloading model: $modelAlias" -ForegroundColor Yellow
    foundry model download $modelAlias
    
    Write-Host "Loading model into memory (this caches it)..." -ForegroundColor Yellow
    foundry model load $modelAlias
    
    Write-Host "Verifying model is cached..." -ForegroundColor Yellow
    foundry cache list
    
    Write-Host "Model cached successfully!" -ForegroundColor Green
    Write-Host "The model is now available for offline use." -ForegroundColor Green
} catch {
    Write-Error "Failed to download/cache model: $_"
    Write-Host "You can manually download later with: foundry model download $modelAlias" -ForegroundColor Yellow
}

# Step 8: Get service endpoint
Write-Host "Getting service endpoint..." -ForegroundColor Yellow
try {
    $status = foundry service status
    Write-Host "Foundry Local endpoint: $status" -ForegroundColor Green
} catch {
    Write-Warning "Could not get service endpoint: $_"
}

# Step 9: Create a simple test
Write-Host "Creating test script..." -ForegroundColor Yellow
$testScript = @'
# Test Foundry Local
# Run this to verify Foundry Local is working
$env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")

Write-Host "Testing Foundry Local..." -ForegroundColor Cyan
foundry service status
foundry cache list

Write-Host "`nYou can now run interactive mode with:" -ForegroundColor Yellow
Write-Host "foundry model run phi-3-mini-4k-instruct" -ForegroundColor Green
'@

$testScript | Out-File -FilePath "C:\FoundryTest.ps1" -Encoding UTF8
Write-Host "Test script saved to: C:\FoundryTest.ps1" -ForegroundColor Green

Write-Host ""
Write-Host "==================================================" -ForegroundColor Cyan
Write-Host "Foundry Local Installation Complete!" -ForegroundColor Green
Write-Host "==================================================" -ForegroundColor Cyan
Write-Host "Next Steps:" -ForegroundColor Yellow
Write-Host "1. The Phi model has been cached for offline use"
Write-Host "2. Run: install_db_and_seed_data.ps1"
Write-Host "3. Run: start_mcp_server.ps1"
Write-Host "4. Test the agent application"
Write-Host "==================================================" -ForegroundColor Cyan
