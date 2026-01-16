@description('Name of the Virtual Machine')
param vmName string

@description('Name of the Network Interface')
param nicName string

@description('Azure region')
param location string

@description('VM size')
param vmSize string

@description('Admin username')
param adminUsername string

@description('Admin password')
@secure()
param adminPassword string

@description('Subnet resource ID')
param subnetId string

@description('Public IP resource ID')
param publicIpId string

@description('Resource tags')
param tags object

// Network Interface
resource nic 'Microsoft.Network/networkInterfaces@2023-11-01' = {
  name: nicName
  location: location
  tags: tags
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          subnet: {
            id: subnetId
          }
          privateIPAllocationMethod: 'Dynamic'
          publicIPAddress: {
            id: publicIpId
          }
        }
      }
    ]
  }
}

// Virtual Machine (Windows Server 2022)
resource vm 'Microsoft.Compute/virtualMachines@2024-03-01' = {
  name: vmName
  location: location
  tags: tags
  properties: {
    hardwareProfile: {
      vmSize: vmSize
    }
    osProfile: {
      computerName: take(vmName, 15)  // Windows limit is 15 characters
      adminUsername: adminUsername
      adminPassword: adminPassword
      windowsConfiguration: {
        enableAutomaticUpdates: true
        provisionVMAgent: true
        patchSettings: {
          patchMode: 'AutomaticByOS'
        }
      }
    }
    storageProfile: {
      imageReference: {
        publisher: 'MicrosoftWindowsDesktop'
        offer: 'Windows-11'
        sku: 'win11-23h2-pro'
        version: 'latest'
      }
      osDisk: {
        createOption: 'FromImage'
        managedDisk: {
          storageAccountType: 'Premium_LRS'
        }
        diskSizeGB: 256
      }
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: nic.id
        }
      ]
    }
  }
}

// Custom Script Extension to download and setup scripts
resource vmExtension 'Microsoft.Compute/virtualMachines/extensions@2024-03-01' = {
  parent: vm
  name: 'SetupScripts'
  location: location
  properties: {
    publisher: 'Microsoft.Compute'
    type: 'CustomScriptExtension'
    typeHandlerVersion: '1.10'
    autoUpgradeMinorVersion: true
    settings: {}
    protectedSettings: {
      commandToExecute: 'powershell -ExecutionPolicy Bypass -Command "& {$baseUrl = \'https://raw.githubusercontent.com/Vinny614/Foundry-Local/main\'; New-Item -ItemType Directory -Path C:\\\\FoundryDemo\\\\agent -Force; Invoke-WebRequest -Uri \\"$baseUrl/vm/bootstrap/install_foundry_local.ps1\\" -OutFile C:\\\\FoundryDemo\\\\install_foundry_local.ps1 -UseBasicParsing; Invoke-WebRequest -Uri \\"$baseUrl/vm/bootstrap/fix_foundry_dependencies.ps1\\" -OutFile C:\\\\FoundryDemo\\\\fix_foundry_dependencies.ps1 -UseBasicParsing; Invoke-WebRequest -Uri \\"$baseUrl/vm/bootstrap/install_db_and_seed_data.ps1\\" -OutFile C:\\\\FoundryDemo\\\\install_db_and_seed_data.ps1 -UseBasicParsing; Invoke-WebRequest -Uri \\"$baseUrl/vm/bootstrap/start_mcp_server.ps1\\" -OutFile C:\\\\FoundryDemo\\\\start_mcp_server.ps1 -UseBasicParsing; Invoke-WebRequest -Uri \\"$baseUrl/vm/bootstrap/lock_down_offline.ps1\\" -OutFile C:\\\\FoundryDemo\\\\lock_down_offline.ps1 -UseBasicParsing; Invoke-WebRequest -Uri \\"$baseUrl/vm/bootstrap/verify_offline.ps1\\" -OutFile C:\\\\FoundryDemo\\\\verify_offline.ps1 -UseBasicParsing; Invoke-WebRequest -Uri \\"$baseUrl/app/agent.py\\" -OutFile C:\\\\FoundryDemo\\\\agent\\\\agent.py -UseBasicParsing; Invoke-WebRequest -Uri \\"$baseUrl/app/requirements.txt\\" -OutFile C:\\\\FoundryDemo\\\\agent\\\\requirements.txt -UseBasicParsing; Invoke-WebRequest -Uri \\"$baseUrl/app/example_queries.txt\\" -OutFile C:\\\\FoundryDemo\\\\agent\\\\example_queries.txt -UseBasicParsing; \'Success\' | Out-File C:\\\\FoundryDemo\\\\download_log.txt}"'
    }
  }
}

output vmName string = vm.name
output vmId string = vm.id
output nicId string = nic.id
