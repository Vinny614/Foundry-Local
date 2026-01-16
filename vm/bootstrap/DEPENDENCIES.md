# Bootstrap Script Dependencies

## Complete Dependency List

This document lists all dependencies required by the bootstrap scripts and how they're handled.

## System Requirements

### Windows
- **Windows 11 Pro** (as deployed by Bicep) ✅
- **Windows 10** (version 1809 or later) ✅
- **Windows Server 2022** (alternative) ✅

### Hardware (from VM size)
- **8 vCPU** minimum (Standard_D8s_v5) ✅
- **32 GB RAM** minimum ✅
- **256 GB disk** (Premium SSD) ✅

## Dependencies by Script

### 1. install_foundry_local.ps1

**Required:**
- Administrator privileges ✅ (enforced by #Requires)
- Internet connection (for downloads) ✅
- **winget** (Windows Package Manager) ✅ (script checks and installs if missing)

**Installs:**
1. **.NET 8 Desktop Runtime** (for Foundry Local)
   - Package: `Microsoft.DotNet.DesktopRuntime.8`
   - Method: winget
   - Why: Required by Foundry Local

2. **Visual C++ 2015-2022 Redistributables x64** (for Foundry Local)
   - Package: `Microsoft.VCRedist.2015+.x64`
   - Method: winget
   - Why: Required by Foundry Local

3. **Python 3.12**
   - Package: `Python.Python.3.12` or direct download
   - Method: winget (preferred) or direct download
   - Includes: pip, standard library
   - Why: Needed for MCP server and agent

4. **Microsoft Foundry Local**
   - Package: `Microsoft.FoundryLocal`
   - Method: winget
   - Why: AI inference engine

5. **Phi-3-mini-4k-instruct model**
   - Downloaded and cached via Foundry Local
   - Size: ~2-3 GB
   - Why: The AI model for inference

**No additional Python packages needed** - uses stdlib only

### 2. install_db_and_seed_data.ps1

**Required:**
- Administrator privileges (recommended)
- Internet connection (for SQLite download)

**Installs:**
1. **SQLite portable tools**
   - Downloaded from: sqlite.org
   - Version: 3.46.1
   - Includes: sqlite3.exe, sqldiff.exe, sqlite3_analyzer.exe
   - Location: C:\FoundryDemo\sqlite\
   - Why: Local database for demo data

**No Python or other dependencies needed**

### 3. start_mcp_server.ps1

**Required:**
- Python 3.x (checks and installs if missing)
- Database already created (by install_db_and_seed_data.ps1)

**Creates:**
- MCP server Python script (self-contained)
- Uses Python standard library only:
  - `sqlite3` ✅ (in stdlib)
  - `json` ✅ (in stdlib)
  - `sys` ✅ (in stdlib)

**No pip packages required**

### 4. lock_down_offline.ps1

**Required:**
- Administrator privileges ✅ (enforced)
- Windows Firewall enabled

**No installations** - only configures existing Windows Firewall

### 5. verify_offline.ps1

**Required:**
- All previous scripts completed successfully

**No installations** - only verification

## Agent Application (app/agent.py)

**Required:**
- Python 3.x ✅
- MCP server script available ✅
- Foundry Local service running ✅

**Python dependencies:**
- `json` ✅ (stdlib)
- `subprocess` ✅ (stdlib)
- `sys` ✅ (stdlib)

**No external packages from PyPI needed!**

## Optional Dependencies

### For Development/Debugging
None required - project uses only built-in tools

### For Alternative Installations
If winget fails:
- **Chocolatey** (alternative package manager)
- **Manual installers** (URLs provided in error messages)

## Dependency Installation Summary

| Component | Required | Installed By | Method | External Packages |
|-----------|----------|--------------|--------|-------------------|
| .NET 8 Runtime | Yes | install_foundry_local.ps1 | winget | N/A |
| VC++ Redist | Yes | install_foundry_local.ps1 | winget | N/A |
| Python 3.12 | Yes | install_foundry_local.ps1 | winget/direct | None (stdlib only) |
| pip | Yes | Python installer | Included | N/A |
| Foundry Local | Yes | install_foundry_local.ps1 | winget | N/A |
| Phi-3 Model | Yes | install_foundry_local.ps1 | foundry CLI | N/A |
| SQLite | Yes | install_db_and_seed_data.ps1 | Direct download | N/A |
| winget | Yes | install_foundry_local.ps1 | Auto-install | N/A |

## Key Design Decision: No External Python Packages

The project intentionally **does NOT use any external Python packages** from PyPI. This means:

✅ No `pip install` commands needed
✅ No requirements.txt with external dependencies
✅ No compatibility issues with package versions
✅ Faster installation
✅ More reliable offline operation
✅ Fewer potential security vulnerabilities

Everything uses **Python standard library only**:
- `sqlite3` for database
- `json` for serialization
- `subprocess` for process management
- Standard networking and file I/O

## Troubleshooting Missing Dependencies

### If winget is not available
```powershell
# Install from Microsoft Store or web
# The script will attempt auto-installation
```

### If .NET or VC++ installation fails
```powershell
# Use the fix script
C:\FoundryDemo\fix_foundry_dependencies.ps1
```

### If Python pip is not working
```powershell
# Reinstall pip
python -m ensurepip --upgrade
```

### If Foundry Local fails to install
```powershell
# Check dependencies first
winget list | Select-String "DotNet\|VCRedist"

# Then try manual installation
# See: https://aka.ms/foundry-local
```

## Summary

**Total external downloads required:**
1. .NET 8 Desktop Runtime (~50 MB)
2. VC++ Redistributables (~25 MB)
3. Python 3.12 (~30 MB)
4. Foundry Local (~100 MB)
5. Phi-3 Model (~2-3 GB)
6. SQLite tools (~10 MB)

**Total: ~3.2 GB of downloads**

**No pip packages from PyPI needed!**
