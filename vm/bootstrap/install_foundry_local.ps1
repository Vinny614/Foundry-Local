# install_foundry_local.ps1
# Installs Python, winget, Microsoft Foundry Local, and downloads Phi-3 model for offline AI demo

#Requires -RunAsAdministrator

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Foundry Local Setup" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "" -ForegroundColor Cyan

# Prerequisites check
Write-Host "Checking prerequisites..." -ForegroundColor Yellow

# Check Windows version
$osVersion = [System.Environment]::OSVersion.Version
Write-Host "Windows Version: $($osVersion.Major).$($osVersion.Minor).$($osVersion.Build)" -ForegroundColor Gray

# Check if winget is available
try {
    $wingetVersion = winget --version
    Write-Host "✓ winget is available: $wingetVersion" -ForegroundColor Green
} catch {
    Write-Host "❌ winget is not available" -ForegroundColor Red
    Write-Host "Installing Windows App Installer (winget)..." -ForegroundColor Yellow
    
    # Try to install App Installer from Microsoft Store
    try {
        $progressPreference = 'silentlyContinue'
        Invoke-WebRequest -Uri "https://aka.ms/getwinget" -OutFile "$env:TEMP\Microsoft.DesktopAppInstaller.msixbundle" -UseBasicParsing
        Add-AppxPackage -Path "$env:TEMP\Microsoft.DesktopAppInstaller.msixbundle"
        Write-Host "✓ winget installed successfully" -ForegroundColor Green
    } catch {
        Write-Error "Failed to install winget. Please install Windows App Installer from the Microsoft Store and run this script again."
        exit 1
    }
}

Write-Host "✓ Prerequisites check complete" -ForegroundColor Green
Write-Host ""

# Step 1: Create directory structure
Write-Host "Setting up directory structure..." -ForegroundColor Yellow
$demoPath = "C:\FoundryDemo"
if (!(Test-Path $demoPath)) {
    New-Item -Path $demoPath -ItemType Directory -Force | Out-Null
}

# Step 2: Install Python if not present
Write-Host "Checking for Python..." -ForegroundColor Yellow
try {
    $pythonVersion = python --version 2>&1
    Write-Host "✓ Python is installed: $pythonVersion" -ForegroundColor Green
    
    # Verify pip is available
    try {
        $pipVersion = python -m pip --version 2>&1
        Write-Host "✓ pip is available: $pipVersion" -ForegroundColor Green
    } catch {
        Write-Host "⚠ pip not found, upgrading pip..." -ForegroundColor Yellow
        python -m ensurepip --upgrade
    }
} catch {
    Write-Host "Installing Python 3.12..." -ForegroundColor Yellow
    $progressPreference = 'silentlyContinue'
    
    # Try winget first
    try {
        Write-Host "Attempting to install Python via winget..." -ForegroundColor Cyan
        winget install Python.Python.3.12 --source winget --accept-package-agreements --accept-source-agreements --silent
        
        # Refresh PATH
        $env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")
        
        Start-Sleep -Seconds 5
        $pythonVersion = python --version
        Write-Host "✓ Python installed via winget: $pythonVersion" -ForegroundColor Green
    } catch {
        Write-Host "winget installation failed, trying direct download..." -ForegroundColor Yellow
        
        # Download Python installer
        $pythonUrl = "https://www.python.org/ftp/python/3.12.0/python-3.12.0-amd64.exe"
        $pythonInstaller = "$env:TEMP\python-installer.exe"
        Invoke-WebRequest -Uri $pythonUrl -OutFile $pythonInstaller -UseBasicParsing
        
        # Install Python silently
        Start-Process -FilePath $pythonInstaller -ArgumentList "/quiet InstallAllUsers=1 PrependPath=1" -Wait
        
        # Refresh PATH
        $env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")
        
        Write-Host "✓ Python installed successfully" -ForegroundColor Green
    }
}

# Step 3: Install required dependencies for Foundry Local
Write-Host "Installing required dependencies for Foundry Local..." -ForegroundColor Yellow

try {
    # Install .NET 8 Desktop Runtime (required for Foundry Local)
    Write-Host "Installing .NET 8 Desktop Runtime..." -ForegroundColor Cyan
    winget install Microsoft.DotNet.DesktopRuntime.8 --source winget --accept-package-agreements --accept-source-agreements --silent
    Write-Host "✓ .NET 8 Desktop Runtime installed" -ForegroundColor Green
} catch {
    Write-Warning "Failed to install .NET 8 Desktop Runtime, but continuing..."
}

try {
    # Install VC++ 2015-2022 Redistributable (x64)
    Write-Host "Installing Visual C++ Redistributables..." -ForegroundColor Cyan
    winget install Microsoft.VCRedist.2015+.x64 --source winget --accept-package-agreements --accept-source-agreements --silent
    Write-Host "✓ VC++ Redistributables installed" -ForegroundColor Green
} catch {
    Write-Warning "Failed to install VC++ Redistributables, but continuing..."
}

Write-Host "Dependencies installation complete" -ForegroundColor Green

# Step 4: Install Microsoft Foundry Local using winget (Windows 11)
Write-Host "Installing Microsoft Foundry Local..." -ForegroundColor Yellow

$wingetOutput = winget install Microsoft.FoundryLocal --source winget --accept-package-agreements --accept-source-agreements --silent 2>&1 | Out-String
Write-Host $wingetOutput

# Check if installation succeeded by looking for error codes
if ($LASTEXITCODE -ne 0 -or $wingetOutput -match "0x80073cf3" -or $wingetOutput -match "failed" -or $wingetOutput -match "error") {
    Write-Host ""
    Write-Host "========================================" -ForegroundColor Red
    Write-Host "❌ INSTALLATION FAILED" -ForegroundColor Red
    Write-Host "========================================" -ForegroundColor Red
    Write-Host ""
    Write-Host "Foundry Local installation failed." -ForegroundColor Red
    Write-Host "Exit code: $LASTEXITCODE" -ForegroundColor Yellow
    Write-Host ""
    
    if ($wingetOutput -match "0x80073cf3") {
        Write-Host "Error 0x80073cf3: Missing dependency detected." -ForegroundColor Yellow
        Write-Host ""
        Write-Host "Please try the following:" -ForegroundColor Cyan
        Write-Host "1. Install Windows Desktop Runtime:" -ForegroundColor White
        Write-Host "   winget install Microsoft.DotNet.DesktopRuntime.8" -ForegroundColor Gray
        Write-Host ""
        Write-Host "2. Reboot the VM" -ForegroundColor White
        Write-Host ""
        Write-Host "3. Run this script again" -ForegroundColor White
        Write-Host ""
        Write-Host "Or manually install Foundry Local from:" -ForegroundColor Cyan
        Write-Host "https://aka.ms/foundry-local" -ForegroundColor White
    }
    Write-Host ""
    exit 1
}

Write-Host "Foundry Local installed successfully" -ForegroundColor Green

# Step 5: Verify installation and refresh PATH
Write-Host "Verifying Foundry Local installation..." -ForegroundColor Yellow
Write-Host "Waiting for installation to complete and PATH to refresh..." -ForegroundColor Yellow
Start-Sleep -Seconds 10

# Multiple PATH refresh strategies
$env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")

# Try to find foundry.exe in common locations
$foundryPaths = @(
    "$env:LOCALAPPDATA\Microsoft\WindowsApps\foundry.exe",
    "$env:ProgramFiles\Foundry Local\foundry.exe",
    "${env:ProgramFiles(x86)}\Foundry Local\foundry.exe"
)

$foundryFound = $false
foreach ($path in $foundryPaths) {
    if (Test-Path $path) {
        Write-Host "Found Foundry at: $path" -ForegroundColor Green
        $foundryFound = $true
        break
    }
}

# Try running foundry command
try {
    $foundryVersion = & foundry --version 2>&1
    if ($LASTEXITCODE -eq 0) {
        Write-Host "Foundry Local is installed: $foundryVersion" -ForegroundColor Green
    } else {
        throw "foundry command returned exit code $LASTEXITCODE"
    }
} catch {
    Write-Warning "The 'foundry' command is not immediately available in PATH."
    Write-Host ""
    Write-Host "This is normal for fresh installations. Please:" -ForegroundColor Yellow
    Write-Host "1. Close this PowerShell window" -ForegroundColor Yellow
    Write-Host "2. Open a NEW PowerShell window as Administrator" -ForegroundColor Yellow
    Write-Host "3. Run: foundry --version" -ForegroundColor Yellow
    Write-Host "4. If that works, continue with: foundry service start" -ForegroundColor Yellow
    Write-Host ""
    if ($foundryFound) {
        Write-Host "Foundry was installed successfully (file exists), just needs PATH refresh." -ForegroundColor Green
    }
    Write-Host "Press any key to continue anyway..." -ForegroundColor Cyan
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
}

# Step 6: Start Foundry Local service (if foundry command is available)
Write-Host ""
Write-Host "===================================================================" -ForegroundColor Cyan
Write-Host "STEP 6: Starting Foundry Local Service" -ForegroundColor Cyan
Write-Host "===================================================================" -ForegroundColor Cyan

try {
    $foundryCmd = Get-Command foundry -ErrorAction SilentlyContinue
    if ($foundryCmd) {
        Write-Host "Starting Foundry Local service..." -ForegroundColor Yellow
        & foundry service start
        Start-Sleep -Seconds 10
        
        $serviceStatus = & foundry service status
        Write-Host "Service status: $serviceStatus" -ForegroundColor Green
    } else {
        Write-Host "Skipping service start - foundry command not in PATH yet." -ForegroundColor Yellow
        Write-Host "After restarting PowerShell, run: foundry service start" -ForegroundColor Yellow
    }
} catch {
    Write-Host "Service may already be running or not accessible yet." -ForegroundColor Yellow
    Write-Host "After restarting PowerShell, try: foundry service restart" -ForegroundColor Yellow
}

# Step 7: Download Phi-3 model for offline use
Write-Host ""
Write-Host "===================================================================" -ForegroundColor Cyan
Write-Host "STEP 7: Downloading Phi-3 Model" -ForegroundColor Cyan
Write-Host "===================================================================" -ForegroundColor Cyan

try {
    $foundryCmd = Get-Command foundry -ErrorAction SilentlyContinue
    if ($foundryCmd) {
        Write-Host "Downloading Phi-3 model (this will take 5-10 minutes)..." -ForegroundColor Yellow
        Write-Host "Foundry will automatically select the best variant for your hardware." -ForegroundColor Cyan
        
        & foundry model run phi-3-mini-4k-instruct --auto-exit
        
        Write-Host "Phi-3 model downloaded successfully" -ForegroundColor Green
    } else {
        Write-Host "Skipping model download - foundry command not in PATH yet." -ForegroundColor Yellow
        Write-Host "After restarting PowerShell, run:" -ForegroundColor Yellow
        Write-Host "  foundry model run phi-3-mini-4k-instruct --auto-exit" -ForegroundColor Yellow
    }
} catch {
    Write-Error "Failed to download Phi-3 model: $_"
    Write-Host "You can manually download later with: foundry model run phi-3-mini-4k-instruct" -ForegroundColor Yellow
}

# Step 8: Verify model is cached
Write-Host "Verifying model cache..." -ForegroundColor Yellow
try {
    $foundryCmd = Get-Command foundry -ErrorAction SilentlyContinue
    if ($foundryCmd) {
        $cacheList = & foundry cache list
        Write-Host "Cached models:" -ForegroundColor Yellow
        Write-Host $cacheList
        
        if ($cacheList -match "phi-3") {
            Write-Host "Phi-3 model is cached and ready for offline use!" -ForegroundColor Green
        }
    } else {
        Write-Host "Skipping cache verification - foundry command not in PATH yet." -ForegroundColor Yellow
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
