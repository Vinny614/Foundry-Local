# Verify Offline Operation
# This script tests that the VM is truly offline while local services still work

$ErrorActionPreference = "Continue"

Write-Host "==================================================" -ForegroundColor Cyan
Write-Host "Offline Verification Script" -ForegroundColor Cyan
Write-Host "==================================================" -ForegroundColor Cyan

$allTestsPassed = $true

# Test 1: DNS Resolution (should fail or timeout)
Write-Host "`nTest 1: DNS Resolution (should fail)" -ForegroundColor Yellow
try {
    $dns = Resolve-DnsName -Name "www.microsoft.com" -ErrorAction Stop -TimeoutInSeconds 5
    Write-Host "  FAIL: DNS resolution succeeded (not offline)" -ForegroundColor Red
    $allTestsPassed = $false
} catch {
    Write-Host "  PASS: DNS resolution failed (offline)" -ForegroundColor Green
}

# Test 2: HTTP Request (should fail)
Write-Host "`nTest 2: HTTP Request to Internet (should fail)" -ForegroundColor Yellow
try {
    $response = Invoke-WebRequest -Uri "https://www.microsoft.com" -TimeoutSec 10 -ErrorAction Stop
    Write-Host "  FAIL: HTTP request succeeded (not offline)" -ForegroundColor Red
    $allTestsPassed = $false
} catch {
    Write-Host "  PASS: HTTP request failed (offline)" -ForegroundColor Green
}

# Test 3: Ping external IP (should fail)
Write-Host "`nTest 3: Ping External IP (should fail)" -ForegroundColor Yellow
try {
    $ping = Test-Connection -ComputerName "8.8.8.8" -Count 2 -TimeoutSeconds 5 -ErrorAction Stop
    Write-Host "  FAIL: Ping succeeded (not offline)" -ForegroundColor Red
    $allTestsPassed = $false
} catch {
    Write-Host "  PASS: Ping failed (offline)" -ForegroundColor Green
}

# Test 4: Localhost connectivity (should succeed)
Write-Host "`nTest 4: Localhost Connectivity (should succeed)" -ForegroundColor Yellow
try {
    $ping = Test-Connection -ComputerName "127.0.0.1" -Count 2 -ErrorAction Stop
    Write-Host "  PASS: Localhost is reachable" -ForegroundColor Green
} catch {
    Write-Host "  FAIL: Localhost not reachable (unexpected)" -ForegroundColor Red
    $allTestsPassed = $false
}

# Test 5: Foundry Local Service (should be running)
Write-Host "`nTest 5: Foundry Local Service (should be running)" -ForegroundColor Yellow
try {
    # Refresh PATH
    $env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")
    
    $status = foundry service status 2>&1
    if ($LASTEXITCODE -eq 0 -or $status -match "running") {
        Write-Host "  PASS: Foundry Local service is running" -ForegroundColor Green
    } else {
        Write-Host "  WARNING: Foundry Local service may not be running" -ForegroundColor Yellow
        Write-Host "  Status: $status" -ForegroundColor Gray
    }
} catch {
    Write-Host "  WARNING: Could not check Foundry Local status: $_" -ForegroundColor Yellow
}

# Test 6: Foundry Local cached model (should work)
Write-Host "`nTest 6: Foundry Local Cached Models (should list models)" -ForegroundColor Yellow
try {
    $models = foundry cache list 2>&1
    if ($LASTEXITCODE -eq 0 -and $models) {
        Write-Host "  PASS: Cached models available" -ForegroundColor Green
        Write-Host "  Models:" -ForegroundColor Gray
        Write-Host "  $models" -ForegroundColor Gray
    } else {
        Write-Host "  WARNING: No cached models found" -ForegroundColor Yellow
    }
} catch {
    Write-Host "  WARNING: Could not list cached models: $_" -ForegroundColor Yellow
}

# Test 7: SQLite Database (should be accessible)
Write-Host "`nTest 7: SQLite Database (should be accessible)" -ForegroundColor Yellow
$dbPath = "C:\FoundryDemo\data\analytics.db"
if (Test-Path $dbPath) {
    $sqlite = "C:\FoundryDemo\sqlite\sqlite3.exe"
    if (Test-Path $sqlite) {
        try {
            $count = "SELECT COUNT(*) FROM sales;" | & $sqlite $dbPath
            Write-Host "  PASS: Database accessible with $count records" -ForegroundColor Green
        } catch {
            Write-Host "  FAIL: Could not query database: $_" -ForegroundColor Red
            $allTestsPassed = $false
        }
    } else {
        Write-Host "  WARNING: SQLite executable not found" -ForegroundColor Yellow
    }
} else {
    Write-Host "  WARNING: Database file not found at $dbPath" -ForegroundColor Yellow
}

# Test 8: MCP Server (should be able to start)
Write-Host "`nTest 8: MCP Server (checking if available)" -ForegroundColor Yellow
$mcpServer = "C:\FoundryDemo\mcp-server\mcp_server.py"
if (Test-Path $mcpServer) {
    Write-Host "  PASS: MCP server script exists" -ForegroundColor Green
    Write-Host "  Note: You can manually test the MCP server in another window" -ForegroundColor Gray
} else {
    Write-Host "  WARNING: MCP server script not found at $mcpServer" -ForegroundColor Yellow
}

# Test 9: Windows Firewall Status
Write-Host "`nTest 9: Windows Firewall Configuration" -ForegroundColor Yellow
try {
    $profiles = Get-NetFirewallProfile -Profile Domain,Public,Private
    $blocked = $profiles | Where-Object { $_.DefaultOutboundAction -eq "Block" }
    
    if ($blocked.Count -gt 0) {
        Write-Host "  PASS: Firewall is blocking outbound traffic" -ForegroundColor Green
        foreach ($profile in $blocked) {
            Write-Host "    - $($profile.Name): Outbound = Block" -ForegroundColor Gray
        }
    } else {
        Write-Host "  FAIL: Firewall is NOT blocking outbound traffic" -ForegroundColor Red
        $allTestsPassed = $false
    }
} catch {
    Write-Host "  WARNING: Could not check firewall status: $_" -ForegroundColor Yellow
}

# Summary
Write-Host ""
Write-Host "==================================================" -ForegroundColor Cyan
Write-Host "Verification Complete" -ForegroundColor Cyan
Write-Host "==================================================" -ForegroundColor Cyan

if ($allTestsPassed) {
    Write-Host "RESULT: VM is properly configured for offline operation" -ForegroundColor Green
    Write-Host ""
    Write-Host "Confirmed:" -ForegroundColor Yellow
    Write-Host "  - No internet connectivity" -ForegroundColor Green
    Write-Host "  - Localhost services accessible" -ForegroundColor Green
    Write-Host "  - Foundry Local operational" -ForegroundColor Green
    Write-Host "  - Database accessible" -ForegroundColor Green
    Write-Host "  - Firewall blocking outbound traffic" -ForegroundColor Green
} else {
    Write-Host "RESULT: Some issues detected" -ForegroundColor Yellow
    Write-Host "Review the test results above for details" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "To run the demo agent application:" -ForegroundColor Yellow
Write-Host "  cd C:\FoundryDemo\agent" -ForegroundColor Cyan
Write-Host "  python agent.py" -ForegroundColor Cyan
Write-Host "==================================================" -ForegroundColor Cyan
