using './main.bicep'

// Core naming and location
param namingPrefix = 'foundry'
param location = 'eastus'

// Admin credentials - use Key Vault or secure input at deployment time
// DO NOT commit plaintext passwords
param adminUsername = 'azureuser'
// param adminPassword will be passed at deployment via --parameters or secure prompt

// Security: Your public IP for RDP access
param allowedRdpSourceIp = '0.0.0.0/0'  // CHANGE THIS to your public IP for security!

// VM Configuration
param vmSize = 'Standard_D8s_v5'  // 8 vCPU, 32GB RAM - suitable for Phi model inference

// Network Configuration
param vnetAddressPrefix = '10.0.0.0/16'
param subnetAddressPrefix = '10.0.1.0/24'

// Tags
param tags = {
  Environment: 'Demo'
  Project: 'Foundry-Local-MCP'
  Purpose: 'Offline-AI-Demo'
}
