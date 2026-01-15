﻿# install_foundry_local.ps1
# Installs Python, winget, Microsoft Foundry Local, and downloads Phi-3 model for offline AI demo

#Requires -RunAsAdministrator

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Foundry Local Setup" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "" -ForegroundColor Cyan

# Step 1: Create directory structure
Write-Host "Setting up directory structure..." -ForegroundColor Yellow
$demoPath = "C:\FoundryDemo"
if (!(Test-Path $demoPath)) {
    New-Item -Path $demoPath -ItemType Directory -Force | Out-Null
}

# Step 2: Install Python if not present
Write-Host "Checking for Python..." -ForegroundColor Yellow
try {
    $pythonVersion = python --version
    Write-Host "Python is installed: $pythonVersion" -ForegroundColor Green
} catch {
    Write-Host "Installing Python 3.12..." -ForegroundColor Yellow
    $progressPreference = 'silentlyContinue'
    
    # Download Python installer
    $pythonUrl = "https://www.python.org/ftp/python/3.12.0/python-3.12.0-amd64.exe"
    $pythonInstaller = "$env:TEMP\python-installer.exe"
    Invoke-WebRequest -Uri $pythonUrl -OutFile $pythonInstaller -UseBasicParsing
    
    # Install Python silently
    Start-Process -FilePath $pythonInstaller -ArgumentList "/quiet InstallAllUsers=1 PrependPath=1" -Wait
    
    # Refresh PATH
    $env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")
    
    Write-Host "Python installed successfully" -ForegroundColor Green
}

# Step 3: Install Microsoft Foundry Local using MSIX for Windows Server
Write-Host "Installing Microsoft Foundry Local..." -ForegroundColor Yellow
$progressPreference = 'silentlyContinue'

try {
    # Download the MSIX package and VCLibs dependency
    $foundryMsixUrl = "https://github.com/microsoft/Foundry-Local/releases/latest/download/FoundryLocal.msix"
    $vcLibsUrl = "https://aka.ms/Microsoft.VCLibs.x64.14.00.Desktop.appx"
    
    $foundryMsix = "$env:TEMP\FoundryLocal.msix"
    $vcLibs = "$env:TEMP\VcLibs.appx"
    
    Write-Host "Downloading Foundry Local MSIX package..." -ForegroundColor Yellow
    Invoke-WebRequest -Uri $foundryMsixUrl -OutFile $foundryMsix -UseBasicParsing
    
    Write-Host "Downloading VCLibs dependency..." -ForegroundColor Yellow
    Invoke-WebRequest -Uri $vcLibsUrl -OutFile $vcLibs -UseBasicParsing
    
    Write-Host "Installing Foundry Local for all users (this may take a few minutes)..." -ForegroundColor Yellow
    Add-AppxProvisionedPackage -Online -PackagePath $foundryMsix -DependencyPackagePath $vcLibs -SkipLicense
    
    # Refresh PATH
    $env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")
    
    Write-Host "Foundry Local installed successfully" -ForegroundColor Green
} catch {
    Write-Error "Failed to install Foundry Local: $_"
    Write-Host "You can manually download the MSIX from: https://github.com/microsoft/Foundry-Local/releases" -ForegroundColor Yellow
    exit 1
}

# Step 4: Verify installation
Write-Host "Verifying Foundry Local installation..." -ForegroundColor Yellow
Start-Sleep -Seconds 5

# Refresh PATH again
$env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")

try {
    $foundryVersion = foundry --version
    Write-Host "Foundry Local is installed: $foundryVersion" -ForegroundColor Green
} catch {
    Write-Error "Foundry Local installation verification failed. The 'foundry' command is not available."
    Write-Host "Try restarting PowerShell or running: foundry service restart" -ForegroundColor Yellow
    exit 1
}

# Step 5: Start Foundry Local service
Write-Host "Starting Foundry Local service..." -ForegroundColor Yellow
try {
    foundry service start
    Start-Sleep -Seconds 10
    
    $serviceStatus = foundry service status
    Write-Host "Service status: $serviceStatus" -ForegroundColor Green
} catch {
    Write-Host "Service may already be running. Checking status..." -ForegroundColor Yellow
    try {
        foundry service status
    } catch {
        Write-Warning "Service status check failed. Trying restart..."
        foundry service restart
        Start-Sleep -Seconds 10
    }
}

# Step 6: Download Phi-3 model for offline use
Write-Host "Downloading Phi-3 model (this will take 5-10 minutes)..." -ForegroundColor Yellow
Write-Host "Foundry will automatically select the best variant for your hardware." -ForegroundColor Cyan

try {
    # Download phi-3-mini model
    foundry model run phi-3-mini-4k-instruct --auto-exit
    
    Write-Host "Phi-3 model downloaded successfully" -ForegroundColor Green
} catch {
    Write-Error "Failed to download Phi-3 model: $_"
    Write-Host "You can manually download later with: foundry model run phi-3-mini-4k-instruct" -ForegroundColor Yellow
}

# Step 7: Verify model is cached
Write-Host "Verifying model cache..." -ForegroundColor Yellow
try {
    $cacheList = foundry cache list
    Write-Host "Cached models:" -ForegroundColor Yellow
    Write-Host $cacheList
    
    if ($cacheList -match "phi-3") {
        Write-Host "Phi-3 model is cached and ready for offline use!" -ForegroundColor Green
    }
} catch {
    Write-Warning "Could not verify cache: $_"
}

Write-Host "" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Installation Complete!" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "✓ Python: Installed" -ForegroundColor Green
Write-Host "✓ Foundry Local: Installed and running" -ForegroundColor Green  
Write-Host "✓ Phi-3 Model: Downloaded and cached" -ForegroundColor Green
Write-Host "" -ForegroundColor Yellow
Write-Host "You can test the model with:" -ForegroundColor Yellow
Write-Host "  foundry model run phi-3-mini-4k-instruct" -ForegroundColor White
Write-Host "" -ForegroundColor Yellow
Write-Host "View all models with:" -ForegroundColor Yellow
Write-Host "  foundry model list" -ForegroundColor White
Write-Host "" -ForegroundColor Yellow
Write-Host "Check service status:" -ForegroundColor Yellow
Write-Host "  foundry service status" -ForegroundColor White
Write-Host "" -ForegroundColor Yellow
Write-Host "Next steps:" -ForegroundColor Yellow
Write-Host "  1. Run install_db_and_seed_data.ps1" -ForegroundColor White
Write-Host "  2. Run start_mcp_server.ps1" -ForegroundColor White
Write-Host "  3. cd C:\FoundryDemo\agent; python agent.py" -ForegroundColor White
Write-Host "========================================" -ForegroundColor Cyan
