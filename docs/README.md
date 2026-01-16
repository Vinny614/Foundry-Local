# Foundry Local + MCP + Phi: Offline AI Demo on Azure

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

A complete, reproducible demonstration of **Foundry Local** with **Phi model** running fully offline on a single Windows Azure VM, using **MCP (Model Context Protocol) tools** for local data analytics.

## 🎯 Overview

This project demonstrates:

- **Foundry Local**: Microsoft's on-device AI inference solution running Phi models
- **Offline Operation**: Complete AI inference with no internet connectivity required after setup
- **MCP Tools**: Local tool/function calling for database queries
- **Table Analytics**: SQL-based data analysis with natural language queries
- **Reproducible Infrastructure**: Bicep-based deployment with modular design

### Key Features

✅ **Fully Offline Runtime** - No internet required after model caching  
✅ **Local Tool Calling** - MCP server exposes read-only database tools  
✅ **Bicep Infrastructure** - Modular, maintainable IaC  
✅ **Security-First** - NSG restrictions, firewall lockdown, no public endpoints  
✅ **Single VM Demo** - Everything runs on one Azure Windows Server 2022 VM

---

## 📐 Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                    Azure Resource Group                      │
│                                                               │
│  ┌──────────────────────────────────────────────────────┐   │
│  │         Virtual Network (10.0.0.0/16)                │   │
│  │                                                        │   │
│  │  ┌───────────────────────────────────────────────┐   │   │
│  │  │  Subnet (10.0.1.0/24) + NSG                   │   │   │
│  │  │                                                │   │   │
│  │  │  ┌──────────────────────────────────────┐    │   │   │
│  │  │  │   Windows Server 2022 VM             │    │   │   │
│  │  │  │   (Standard_D8s_v5)                  │    │   │   │
│  │  │  │                                       │    │   │   │
│  │  │  │  ┌─────────────────────────────────┐ │    │   │   │
│  │  │  │  │ Foundry Local + Phi Model       │ │    │   │   │
│  │  │  │  │ (localhost:PORT)                │ │    │   │   │
│  │  │  │  └─────────────────────────────────┘ │    │   │   │
│  │  │  │                 ↕                     │    │   │   │
│  │  │  │  ┌─────────────────────────────────┐ │    │   │   │
│  │  │  │  │ Agent Application (Python)      │ │    │   │   │
│  │  │  │  └─────────────────────────────────┘ │    │   │   │
│  │  │  │                 ↕                     │    │   │   │
│  │  │  │  ┌─────────────────────────────────┐ │    │   │   │
│  │  │  │  │ MCP Server (localhost)          │ │    │   │   │
│  │  │  │  └─────────────────────────────────┘ │    │   │   │
│  │  │  │                 ↕                     │    │   │   │
│  │  │  │  ┌─────────────────────────────────┐ │    │   │   │
│  │  │  │  │ SQLite Database                 │ │    │   │   │
│  │  │  │  │ (analytics.db - Sales Data)     │ │    │   │   │
│  │  │  │  └─────────────────────────────────┘ │    │   │   │
│  │  │  └──────────────────────────────────────┘    │   │   │
│  │  └───────────────────────────────────────────────┘   │   │
│  └──────────────────────────────────────────────────────┘   │
│                                                               │
│  Public IP (RDP: 3389) ← Your IP Only                       │
└─────────────────────────────────────────────────────────────┘
```

### Data Flow

1. **User** asks a natural language question
2. **Agent** processes query with Foundry Local (Phi model)
3. **Model** determines if database query is needed
4. **Agent** calls **MCP Server** with SQL tool
5. **MCP Server** executes read-only query on **SQLite**
6. **Results** returned to Agent
7. **Agent** synthesizes with Foundry Local
8. **Natural language answer** returned to user

---

## 📁 Repository Structure

```
Foundry-Local/
├── infra/bicep/              # Infrastructure as Code
│   ├── main.bicep            # Orchestrator
│   ├── main.bicepparam       # Parameters
│   ├── modules/              # Modular Bicep resources
│   │   ├── nsg.bicep
│   │   ├── vnet.bicep
│   │   ├── publicip.bicep
│   │   ├── storage.bicep
│   │   └── vm.bicep
│   ├── deploy.sh             # Linux deployment script
│   └── deploy.ps1            # Windows deployment script
│
├── vm/bootstrap/             # VM setup scripts (PowerShell)
│   ├── install_foundry_local.ps1
│   ├── install_db_and_seed_data.ps1
│   ├── start_mcp_server.ps1
│   ├── lock_down_offline.ps1
│   └── verify_offline.ps1
│
├── app/                      # Agent application
│   ├── agent.py              # Main agent code
│   ├── requirements.txt      # Python dependencies
│   ├── example_queries.txt   # Sample queries
│   └── README.md
│
├── scripts/                  # Helper scripts
│   ├── copy_to_vm.ps1
│   ├── get_outputs.ps1
│   └── get_outputs.sh
│
├── docs/                     # Documentation
│   └── README.md            # This file
│
└── README.md                # Project overview
```

---

## 🚀 Quick Start

### Prerequisites

**On Your Local Machine:**
- Azure CLI ([Install](https://learn.microsoft.com/en-us/cli/azure/install-azure-cli))
- Azure subscription with appropriate permissions
- Your public IP address (for RDP access)

**Azure Resources Created:**
- Resource Group
- Virtual Network + Subnet
- Network Security Group (NSG)
- Public IP Address
- Windows Server 2022 VM
- Storage Account (for scripts)

### Step 1: Clone Repository

```bash
git clone <repository-url>
cd Foundry-Local
```

### Step 2: Update Parameters

Edit `infra/bicep/main.bicepparam`:

```bicep
param allowedRdpSourceIp = 'YOUR_PUBLIC_IP/32'  // IMPORTANT: Change this!
param location = 'eastus'  // Choose your region
param vmSize = 'Standard_D8s_v5'  // 8 vCPU, 32GB RAM
```

**Get your public IP:**
```bash
curl ifconfig.me
```

### Step 3: Deploy Infrastructure

**Using PowerShell:**
```powershell
cd infra/bicep
.\deploy.ps1 -ResourceGroupName "foundry-demo-rg" -Location "eastus"
```

**Using Bash:**
```bash
cd infra/bicep
./deploy.sh foundry-demo-rg eastus
```

**What happens:**
- Resource group created
- Network infrastructure deployed
- Windows VM provisioned
- Outputs displayed (VM IP, resource names)

**Deployment time:** ~10-15 minutes

### Step 4: Connect to VM

```powershell
# Get VM Public IP
$vmIp = az deployment group show -g foundry-demo-rg -n vm-deployment --query 'properties.outputs.vmPublicIp.value' -o tsv

# Connect via RDP
mstsc /v:$vmIp
```

**Credentials:**
- Username: `azureuser` (or as configured in parameters)
- Password: (as provided during deployment)

### Step 5: Copy Scripts to VM

**Option A: Manual Copy via RDP**
1. In RDP session, create `C:\FoundryDemo` directory
2. Copy files from `vm/bootstrap/` to `C:\FoundryDemo\`
3. Copy files from `app/` to `C:\FoundryDemo\agent\`

**Option B: Use helper script**
```powershell
.\scripts\copy_to_vm.ps1 -VMPublicIP $vmIp
```

### Step 6: Run Bootstrap Scripts (On VM)

**Run these in order as Administrator on the VM:**

```powershell
# 1. Install Foundry Local and cache Phi model
cd C:\FoundryDemo
.\install_foundry_local.ps1

# 2. Create SQLite database and seed with sample data
.\install_db_and_seed_data.ps1

# 3. Setup and test MCP server
.\start_mcp_server.ps1
```

**Each script provides detailed output and verification.**

### Step 7: Test Agent (Connected Mode)

```powershell
cd C:\FoundryDemo\agent
python agent.py
```

Try example queries:
- "What are the top 5 products by revenue?"
- "Which region has the highest total sales?"
- "Show me sales data for the Electronics category"

### Step 8: Go Offline

```powershell
cd C:\FoundryDemo
.\lock_down_offline.ps1
```

**This script:**
- Blocks all outbound internet traffic via Windows Firewall
- Preserves localhost connectivity
- Creates unlock script for later

### Step 9: Verify Offline Operation

```powershell
.\verify_offline.ps1
```

**Tests performed:**
- ✅ DNS resolution (should fail)
- ✅ HTTP requests (should fail)
- ✅ Ping external IP (should fail)
- ✅ Localhost connectivity (should work)
- ✅ Foundry Local service (should work)
- ✅ Cached models (should list Phi model)
- ✅ SQLite database (should be accessible)
- ✅ Firewall configuration (should block outbound)

### Step 10: Test Agent (Offline Mode)

```powershell
cd C:\FoundryDemo\agent
python agent.py
```

**The agent should work exactly as before, proving:**
- Model inference works offline
- MCP tools function locally
- Database queries execute
- Full AI + tool calling without internet

---

## 📚 Documentation References

### Microsoft Learn

This project follows official guidance from Microsoft Learn:

1. **Foundry Local**
   - [Get started with Foundry Local](https://learn.microsoft.com/en-us/azure/ai-foundry/foundry-local/get-started?view=foundry-classic)
   - Key finding: *"After you download a model, you can run cached models offline."*
   
2. **Bicep VM Extensions**
   - [Tutorial - Deploy applications to a Windows VM with Custom Script Extension](https://learn.microsoft.com/en-us/azure/virtual-machines/windows/tutorial-automate-vm-deployment)
   
3. **Deployment Stacks**
   - [Create and deploy Azure deployment stacks in Bicep](https://learn.microsoft.com/en-us/azure/azure-resource-manager/bicep/deployment-stacks)

4. **GitHub Copilot for Azure**
   - [Generate Bicep files using GitHub Copilot for Azure](https://learn.microsoft.com/en-us/azure/developer/github-copilot-azure/bicep-generate-edit)

### Azure Verified Modules

Infrastructure uses native Bicep resources following AVM patterns:
- Network Security Groups (NSG)
- Virtual Networks (VNet)
- Virtual Machines (Windows Server 2022)
- Public IP Addresses
- Storage Accounts

**Note:** While AVM Bicep modules are available in the public registry (`br/public:avm/res/*`), this demo uses native Bicep resources for transparency and educational purposes.

---

## 🔐 Security Considerations

### Network Security

**Inbound:**
- RDP (3389) allowed ONLY from your specified IP
- All other inbound traffic denied

**Outbound (After Lockdown):**
- All internet traffic blocked by Windows Firewall
- Localhost (127.0.0.1) traffic allowed
- Optional: NSG egress deny rule (manual step)

### Application Security

- **Foundry Local**: Binds to localhost only, not publicly exposed
- **MCP Server**: Localhost only, no public listener
- **SQLite Database**: Local file, read-only tool access
- **No Secrets in Code**: Admin password passed securely at deployment

### Best Practices

✅ Change `allowedRdpSourceIp` to YOUR IP  
✅ Use strong admin password  
✅ Consider Azure Bastion for RDP (more secure)  
✅ Review NSG rules before deployment  
✅ Disable RDP after setup if not needed  
✅ Use Azure Key Vault for production secrets

---

## 🧪 Testing & Validation

### Connectivity Tests (Offline)

```powershell
# Should FAIL (no internet)
Test-Connection -ComputerName "8.8.8.8" -Count 2
Resolve-DnsName "www.microsoft.com"
Invoke-WebRequest "https://www.microsoft.com"

# Should SUCCEED (localhost)
Test-Connection -ComputerName "127.0.0.1" -Count 2
```

### Foundry Local Tests

```powershell
# Check service
foundry service status

# List cached models
foundry cache list

# Interactive test
foundry model run phi-3-mini-4k-instruct
```

### Database Tests

```powershell
$sqlite = "C:\FoundryDemo\sqlite\sqlite3.exe"
$db = "C:\FoundryDemo\data\analytics.db"

# Query database
& $sqlite $db "SELECT COUNT(*) FROM sales;"
& $sqlite $db "SELECT * FROM sales_by_category;"
```

### MCP Server Tests

```powershell
cd C:\FoundryDemo\mcp-server
.\test_server.ps1
```

---

## 🛠️ Troubleshooting

### Issue: Foundry Local installation fails with error 0x80073cf3

**Error message:** `Package failed updates, dependency or conflict validation. This package has a dependency missing from your system.`

**Solution:**
```powershell
# Option 1: Run the dependency fix script (recommended)
C:\FoundryDemo\fix_foundry_dependencies.ps1
# Then reboot and run install_foundry_local.ps1 again

# Option 2: Manual installation
winget install Microsoft.DotNet.DesktopRuntime.8
winget install Microsoft.VCRedist.2015+.x64
# Reboot the VM
# Then: winget install Microsoft.FoundryLocal --source winget
```

**Root cause:** Foundry Local requires .NET 8 Desktop Runtime and Visual C++ Redistributables. The updated installation script now handles this automatically, but if you encounter this error, use the fix script above.

### Issue: 'foundry' command not recognized after installation

**Solution:**
```powershell
# 1. First verify Foundry Local is actually installed
Get-AppxPackage | Select-String "Foundry"

# 2. If not installed, there was an installation error - see above
# 3. If installed but command not found, refresh PATH:
$env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")

# 4. If still not working, close PowerShell and open a NEW Administrator PowerShell window
# 5. Check if foundry.exe exists:
Test-Path "$env:LOCALAPPDATA\Microsoft\WindowsApps\foundry.exe"
```

### Issue: Foundry Local service not starting

**Solution:**
```powershell
foundry service restart
foundry service status
```

### Issue: Model not cached

**Solution:**
```powershell
foundry model download phi-3-mini-4k-instruct
foundry model load phi-3-mini-4k-instruct
foundry cache list
```

### Issue: Database not found

**Solution:**
```powershell
# Re-run database setup
cd C:\FoundryDemo
.\install_db_and_seed_data.ps1
```

### Issue: Python not found

**Solution:**
```powershell
# Install Python via winget
winget install Python.Python.3.12

# Refresh PATH
$env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")
```

### Issue: Cannot RDP to VM

**Solutions:**
1. Check NSG rules in Azure Portal
2. Verify your public IP hasn't changed
3. Update NSG rule with new IP
4. Check Windows Firewall on VM (if accessible)

### Issue: Bicep deployment fails

**Solution:**
```bash
# Get detailed error
az deployment group show -g <resource-group> -n vm-deployment

# Check VM size availability
az vm list-sizes --location eastus --output table | grep Standard_D8s_v5

# Try different region or VM size
```

---

## 🧹 Cleanup

### Delete All Resources

```bash
# Delete entire resource group
az group delete --name foundry-demo-rg --yes --no-wait
```

### Selective Cleanup

```bash
# Delete just the VM
az vm delete --resource-group foundry-demo-rg --name <vm-name> --yes

# Delete deployment stack (if using stacks)
az stack group delete --name demoStack --resource-group foundry-demo-rg --yes
```

---

## 📊 Cost Estimation

**Approximate monthly costs (East US region):**

| Resource | Size/SKU | Est. Monthly Cost |
|----------|----------|-------------------|
| VM | Standard_D8s_v5 | ~$280 |
| Managed Disk | Premium SSD 256 GB | ~$40 |
| Public IP | Standard Static | ~$4 |
| VNet | Basic | ~$0 |
| Storage Account | Standard LRS | ~$1 |
| **Total** | | **~$325/month** |

**Cost optimization:**
- Stop VM when not in use (~$44/month for storage only)
- Use smaller VM size for testing
- Delete resource group after demo
- Consider Azure Reserved Instances for long-term use

**Note:** Foundry Local itself has no licensing cost for on-device use.

---

## 🎓 Learning Resources

### Foundry Local
- [Foundry Local Documentation](https://learn.microsoft.com/en-us/azure/ai-foundry/foundry-local/)
- [Foundry Local Architecture](https://learn.microsoft.com/en-us/azure/ai-foundry/foundry-local/concepts/foundry-local-architecture)
- [Best Practices and Troubleshooting](https://learn.microsoft.com/en-us/azure/ai-foundry/foundry-local/reference/reference-best-practice)

### Phi Models
- [Phi-3 Model Family](https://azure.microsoft.com/en-us/blog/introducing-phi-3-redefining-whats-possible-with-slms/)
- [Phi Models on Hugging Face](https://huggingface.co/collections/microsoft/phi-3-6626e15e9585a200d2d761e3)

### Model Context Protocol (MCP)
- [MCP Specification](https://spec.modelcontextprotocol.io/)
- [MCP GitHub](https://github.com/modelcontextprotocol)

### Azure Bicep
- [Bicep Documentation](https://learn.microsoft.com/en-us/azure/azure-resource-manager/bicep/)
- [Azure Verified Modules](https://aka.ms/avm)

---

## 🤝 Contributing

Contributions are welcome! Please:

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Submit a pull request

### Areas for Improvement

- [ ] Add Data Access Builder (DAB) for MCP instead of custom Python
- [ ] Implement deployment stack management
- [ ] Add Azure Monitor integration
- [ ] Create Terraform version
- [ ] Add Linux VM support
- [ ] Multi-model support (different Phi variants)
- [ ] Streaming responses in agent
- [ ] Web UI for agent

---

## 📜 License

This project is licensed under the MIT License - see the LICENSE file for details.

---

## 🙏 Acknowledgments

- **Microsoft Foundry Local** team for the excellent offline AI solution
- **Azure Verified Modules** for Bicep best practices
- **Model Context Protocol** specification authors
- **Phi Model** researchers at Microsoft

---

## 📞 Support

For issues and questions:
- Open an issue in this repository
- Review [Foundry Local documentation](https://learn.microsoft.com/en-us/azure/ai-foundry/foundry-local/)
- Check [troubleshooting section](#🛠️-troubleshooting) above

---

**Built with ❤️ using Foundry Local, MCP, Phi, and Azure**

*Last updated: January 2026*
