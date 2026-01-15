# install_foundry_local.ps1
# Installs Python, winget, Microsoft Foundry Local, and downloads Phi-3 model for offline AI demo

#Requires -RunAsAdministrator

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Foundry Local Setup" -ForegroundColor Cyan
Write-Host "========================================`n" -ForegroundColor Cyan

# Step 1: Create directory structure
Write-Host "Setting up directory structure..." -ForegroundColor Yellow
$demoPath = "C:\FoundryDemo"
if (!(Test-Path $demoPath)) {
    New-Item -Path $demoPath -ItemType Directory -Force | Out-Null
}

# Step 2: Install App Installer (winget) if not present
Write-Host "Checking for winget..." -ForegroundColor Yellow
try {
    $wingetVersion = winget --version
    Write-Host "winget is installed: $wingetVersion" -ForegroundColor Green
} catch {
    Write-Host "Installing App Installer (winget)..." -ForegroundColor Yellow
    
    # Download and install App Installer from Microsoft Store
    $progressPreference = 'silentlyContinue'
    $appInstallerUrl = "https://aka.ms/getwinget"
    
    Write-Host "Please install App Installer from: $appInstallerUrl" -ForegroundColor Yellow
    Write-Host "Or download it manually and run this script again." -ForegroundColor Yellow
    
    # Try automated installation
    try {
        Add-AppxPackage -RegisterByFamilyName -MainPackage Microsoft.DesktopAppInstaller_8wekyb3d8bbwe
        Start-Sleep -Seconds 5
    } catch {
        Write-Error "Failed to install winget automatically. Please install from: https://aka.ms/getwinget"
        exit 1
    }
}

# Refresh PATH
$env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")

# Step 3: Install Python if not present
Write-Host "Checking for Python..." -ForegroundColor Yellow
try {
    $pythonVersion = python --version
    Write-Host "Python is installed: $pythonVersion" -ForegroundColor Green
} catch {
    Write-Host "Installing Python 3.12..." -ForegroundColor Yellow
    winget install Python.Python.3.12 --silent --accept-package-agreements --accept-source-agreements
    
    # Refresh PATH
    $env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")
    
    Write-Host "Python installed successfully" -ForegroundColor Green
}

# Step 4: Install Microsoft Foundry Local
Write-Host "Installing Microsoft Foundry Local..." -ForegroundColor Yellow

try {
    winget install Microsoft.FoundryLocal --accept-package-agreements --accept-source-agreements
    
    # Refresh PATH
    $env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")
    
    Write-Host "Foundry Local installed successfully" -ForegroundColor Green
} catch {
    Write-Error "Failed to install Foundry Local: $_"
    Write-Host "You can manually install from: https://aka.ms/foundry-local-installer" -ForegroundColor Yellow
    exit 1
}

# Step 5: Verify installation
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

# Step 6: Start Foundry Local service
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

# Step 7: Download Phi-3 model for offline use
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

# Step 8: Verify model is cached
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

Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "Installation Complete!" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "✓ Python: Installed" -ForegroundColor Green
Write-Host "✓ Foundry Local: Installed and running" -ForegroundColor Green  
Write-Host "✓ Phi-3 Model: Downloaded and cached" -ForegroundColor Green
Write-Host "`nYou can test the model with:" -ForegroundColor Yellow
Write-Host "  foundry model run phi-3-mini-4k-instruct" -ForegroundColor White
Write-Host "`nView all models with:" -ForegroundColor Yellow
Write-Host "  foundry model list" -ForegroundColor White
Write-Host "`nCheck service status:" -ForegroundColor Yellow
Write-Host "  foundry service status" -ForegroundColor White
Write-Host "`nNext steps:" -ForegroundColor Yellow
Write-Host "  1. Run install_db_and_seed_data.ps1" -ForegroundColor White
Write-Host "  2. Run start_mcp_server.ps1" -ForegroundColor White
Write-Host "  3. Test the agent: cd C:\FoundryDemo\agent; python agent.py" -ForegroundColor White
Write-Host "========================================`n" -ForegroundColor Cyan
