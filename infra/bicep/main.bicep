targetScope = 'resourceGroup'

@description('Prefix for all resource names')
param namingPrefix string

@description('Azure region for resources')
param location string = resourceGroup().location

@description('Admin username for VM')
param adminUsername string

@description('Admin password for VM - pass securely at deployment')
@secure()
param adminPassword string

@description('Your public IP for RDP access (CIDR format)')
param allowedRdpSourceIp string

@description('VM size for compute')
param vmSize string = 'Standard_D8s_v5'

@description('Virtual network address prefix')
param vnetAddressPrefix string = '10.0.0.0/16'

@description('Subnet address prefix')
param subnetAddressPrefix string = '10.0.1.0/24'

@description('Resource tags')
param tags object = {}

// Generate unique names
var uniqueSuffix = substring(uniqueString(resourceGroup().id), 0, 6)
var vmName = '${namingPrefix}-vm-${uniqueSuffix}'
var vnetName = '${namingPrefix}-vnet-${uniqueSuffix}'
var subnetName = 'default'
var nsgName = '${namingPrefix}-nsg-${uniqueSuffix}'
var pipName = '${namingPrefix}-pip-${uniqueSuffix}'
var nicName = '${namingPrefix}-nic-${uniqueSuffix}'
var storageName = '${namingPrefix}st${uniqueSuffix}' // lowercase, no hyphens for storage

// Module: Network Security Group
module nsg 'modules/nsg.bicep' = {
  name: 'nsg-deployment'
  params: {
    nsgName: nsgName
    location: location
    allowedRdpSourceIp: allowedRdpSourceIp
    tags: tags
  }
}

// Module: Virtual Network with Subnet
module vnet 'modules/vnet.bicep' = {
  name: 'vnet-deployment'
  params: {
    vnetName: vnetName
    subnetName: subnetName
    location: location
    vnetAddressPrefix: vnetAddressPrefix
    subnetAddressPrefix: subnetAddressPrefix
    nsgId: nsg.outputs.nsgId
    tags: tags
  }
}

// Module: Public IP
module pip 'modules/publicip.bicep' = {
  name: 'pip-deployment'
  params: {
    pipName: pipName
    location: location
    tags: tags
  }
}

// Module: Storage Account for scripts
module storage 'modules/storage.bicep' = {
  name: 'storage-deployment'
  params: {
    storageName: storageName
    location: location
    tags: tags
  }
}

// Module: Virtual Machine
module vm 'modules/vm.bicep' = {
  name: 'vm-deployment'
  params: {
    vmName: vmName
    nicName: nicName
    location: location
    vmSize: vmSize
    adminUsername: adminUsername
    adminPassword: adminPassword
    subnetId: vnet.outputs.subnetId
    publicIpId: pip.outputs.pipId
    tags: tags
  }
}

// Outputs
output vmName string = vm.outputs.vmName
output vmPublicIp string = pip.outputs.pipAddress
output resourceGroupName string = resourceGroup().name
output storageAccountName string = storage.outputs.storageAccountName
output vnetName string = vnet.outputs.vnetName
output subnetName string = vnet.outputs.subnetName
output nsgName string = nsg.outputs.nsgName
