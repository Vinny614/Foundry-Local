# Foundry Local + MCP + Phi: Offline AI Demo on Azure

A complete, reproducible demonstration of **Foundry Local** with **Phi model** running fully offline on a single Windows Azure VM, using **MCP (Model Context Protocol) tools** for local data analytics.

## 🎯 What This Demo Does

- ✅ Deploys Azure infrastructure using **Bicep**
- ✅ Installs **Foundry Local** and caches a **Phi model** on Windows Server 2022
- ✅ Sets up a **SQLite database** with sample sales data
- ✅ Runs a **local MCP server** exposing read-only SQL tools
- ✅ Provides a **Python agent** that combines Phi + MCP for natural language data queries
- ✅ Proves **complete offline operation** (no internet after setup)
- ✅ Includes **security lockdown** (NSG + Windows Firewall)

## 📁 Repository Structure

```
├── infra/bicep/          # Bicep infrastructure modules
├── vm/bootstrap/         # PowerShell setup scripts for VM
├── app/                  # Python agent application
├── scripts/              # Helper utilities
└── docs/                 # Full documentation
```

## 🚀 Quick Start

1. **Prerequisites**: Azure CLI, Azure subscription, your public IP
2. **Deploy**: `cd infra/bicep && ./deploy.sh <resource-group-name>`
3. **RDP to VM**: Use public IP from deployment outputs
4. **Bootstrap VM**: Run scripts in `vm/bootstrap/` (as Administrator)
5. **Test Agent**: `python C:\FoundryDemo\agent\agent.py`
6. **Go Offline**: Run `lock_down_offline.ps1`
7. **Verify**: Run `verify_offline.ps1` and test agent again

## 📚 Full Documentation

See [docs/README.md](docs/README.md) for:
- Architecture diagrams
- Step-by-step deployment guide
- Security configuration
- Troubleshooting
- Cost estimates
- Testing procedures
- Microsoft Learn references

## 🔗 Key Technologies

- **[Foundry Local](https://learn.microsoft.com/en-us/azure/ai-foundry/foundry-local/)** - Microsoft's on-device AI inference
- **[Phi Models](https://azure.microsoft.com/en-us/blog/introducing-phi-3-redefining-whats-possible-with-slms/)** - Small Language Models from Microsoft
- **[MCP](https://spec.modelcontextprotocol.io/)** - Model Context Protocol for tool calling
- **[Azure Bicep](https://learn.microsoft.com/en-us/azure/azure-resource-manager/bicep/)** - Infrastructure as Code

## 🎓 What You'll Learn

- How to run AI models completely offline after initial caching
- Building local tool calling systems with MCP
- Bicep infrastructure patterns for AI workloads
- Security-first Azure VM configuration
- PowerShell automation for Windows Server setup

## 📊 Architecture

```
User Question → [Foundry Local Phi Model] → Determines tool need
                        ↓
        [MCP Server] → [SQLite Database] → Query results
                        ↓
[Foundry Local] → Natural language response
```

All running on a single Azure VM, completely offline after setup.

## 🔐 Security

- RDP restricted to your IP only
- Foundry Local and MCP bound to localhost
- Windows Firewall blocks all outbound (after lockdown)
- Optional NSG egress deny
- No secrets in repository

## 🧹 Cleanup

```bash
az group delete --name <resource-group-name> --yes
```

## 📜 License

MIT License - See LICENSE file

---

**For complete documentation, see [docs/README.md](docs/README.md)**