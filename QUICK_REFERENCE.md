# Quick Reference Card

## 🚀 Deployment Commands

```bash
# Deploy infrastructure
cd infra/bicep
./deploy.sh foundry-demo-rg eastus

# Get VM IP
az deployment group show -g foundry-demo-rg -n main --query 'properties.outputs.vmPublicIp.value' -o tsv

# Connect via RDP via the Azure Portal

# Or from Windows machine
# mstsc /v:<VM-IP>

# Or from Linux/Mac
# xfreerdp /v:<VM-IP> /u:azureuser /dynamic-resolution
```

## 📋 VM Bootstrap Sequence (On VM, as Administrator)

```powershell
# Step 1: Install Foundry Local and cache model (~15 min)
C:\FoundryDemo\install_foundry_local.ps1

# Step 2: Setup database (~2 min)
C:\FoundryDemo\install_db_and_seed_data.ps1

# Step 3: Setup MCP server (~2 min)
C:\FoundryDemo\start_mcp_server.ps1

# Step 4: Test agent (connected mode)
cd C:\FoundryDemo\agent
python agent.py

# Step 5: Lock down for offline (~1 min)
cd C:\FoundryDemo
.\lock_down_offline.ps1

# Step 6: Verify offline operation (~1 min)
.\verify_offline.ps1

# Step 7: Test agent (offline mode)
cd C:\FoundryDemo\agent
python agent.py
```

## 🔧 Useful Commands (On VM)

```powershell
# Foundry Local
foundry service status
foundry cache list
foundry model run phi-3-mini-4k-instruct

# Database
$sqlite = "C:\FoundryDemo\sqlite\sqlite3.exe"
$db = "C:\FoundryDemo\data\analytics.db"
& $sqlite $db "SELECT * FROM sales LIMIT 5;"

# MCP Server Test
cd C:\FoundryDemo\mcp-server
.\test_server.ps1

# Restore Internet (if needed)
C:\FoundryDemo\unlock_offline.ps1
```

## 📊 Example Queries for Agent

```
What are the top 5 products by revenue?
Which region has the highest total sales?
Show me sales data for the Electronics category
Compare sales between Electronics and Furniture
What is the total profit for each region?
```

## 🔐 Security Checklist

- [ ] Updated `allowedRdpSourceIp` in main.bicepparam to YOUR IP
- [ ] Used strong admin password during deployment
- [ ] Verified NSG rules in Azure Portal
- [ ] Confirmed Windows Firewall blocking outbound (post-lockdown)
- [ ] Tested agent works offline
- [ ] (Optional) Added NSG egress deny rule

## 🧹 Cleanup

```bash
# Delete everything
az group delete --name foundry-demo-rg --yes

# Or stop VM to save costs
az vm deallocate --resource-group foundry-demo-rg --name <vm-name>
```

## 📁 Key File Locations (On VM)

```
C:\FoundryDemo\
├── install_foundry_local.ps1
├── install_db_and_seed_data.ps1
├── start_mcp_server.ps1
├── lock_down_offline.ps1
├── verify_offline.ps1
├── unlock_offline.ps1
├── data\
│   ├── analytics.db           # SQLite database
│   └── sales_data.csv          # Sample data
├── sqlite\
│   └── sqlite3.exe             # SQLite binary
├── mcp-server\
│   ├── mcp_server.py           # MCP server
│   ├── start_server.ps1        # Start script
│   └── test_server.ps1         # Test script
└── agent\
    ├── agent.py                # Agent application
    └── example_queries.txt     # Sample queries
```

## 🆘 Troubleshooting Quick Fixes

**Foundry installation fails with 0x80073cf3?**
```powershell
# Missing dependencies - run dependency fix script
C:\FoundryDemo\fix_foundry_dependencies.ps1
# Then reboot and run install_foundry_local.ps1 again

# Or manually install dependencies:
winget install Microsoft.DotNet.DesktopRuntime.8
winget install Microsoft.VCRedist.2015+.x64
# Reboot, then: winget install Microsoft.FoundryLocal --source winget
```

**Foundry not starting?**
```powershell
foundry service restart
```

**Model not cached?**
```powershell
foundry model download phi-3-mini-4k-instruct
foundry cache list
```

**Python not found?**
```powershell
winget install Python.Python.3.12
# Restart PowerShell
```

**Database empty?**
```powershell
.\install_db_and_seed_data.ps1
```

**Can't RDP?**
- Check your IP hasn't changed
- Update NSG rule in Azure Portal

## 📚 Documentation Links

- **Main README**: [README.md](README.md)
- **Full Documentation**: [docs/README.md](docs/README.md)
- **Implementation Summary**: [IMPLEMENTATION_SUMMARY.md](IMPLEMENTATION_SUMMARY.md)
- **Project Status**: [PROJECT_STATUS.md](PROJECT_STATUS.md)

## 🎯 Success Indicators

✅ Foundry Local service running  
✅ Phi model cached (check with `foundry cache list`)  
✅ Database has 25+ records  
✅ MCP server responds to test queries  
✅ Agent answers questions correctly  
✅ All outbound internet blocked (after lockdown)  
✅ Agent still works offline  

## ⏱️ Expected Timeline

| Phase | Duration | Status Check |
|-------|----------|--------------|
| Infrastructure deployment | 10-15 min | VM created and accessible |
| Foundry Local installation | 10-15 min | `foundry --version` works |
| Database setup | 2-3 min | SQLite queries work |
| MCP server setup | 2-3 min | Test script passes |
| First agent test | 2-3 min | Agent responds to queries |
| Offline lockdown | 1-2 min | Firewall rules applied |
| Verification | 2-3 min | All tests pass |
| Final agent test | 2-3 min | Agent works offline |

**Total time: 30-45 minutes from deployment to offline validation**

---

**For detailed explanations, see [docs/README.md](docs/README.md)**
