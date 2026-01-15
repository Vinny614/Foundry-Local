@description('Name of the Virtual Network')
param vnetName string

@description('Name of the Subnet')
param subnetName string

@description('Azure region')
param location string

@description('Virtual network address prefix')
param vnetAddressPrefix string

@description('Subnet address prefix')
param subnetAddressPrefix string

@description('Network Security Group resource ID')
param nsgId string

@description('Resource tags')
param tags object

// Virtual Network with Subnet
resource vnet 'Microsoft.Network/virtualNetworks@2023-11-01' = {
  name: vnetName
  location: location
  tags: tags
  properties: {
    addressSpace: {
      addressPrefixes: [
        vnetAddressPrefix
      ]
    }
    subnets: [
      {
        name: subnetName
        properties: {
          addressPrefix: subnetAddressPrefix
          networkSecurityGroup: {
            id: nsgId
          }
          privateEndpointNetworkPolicies: 'Disabled'
        }
      }
    ]
  }
}

output vnetId string = vnet.id
output vnetName string = vnet.name
output subnetId string = vnet.properties.subnets[0].id
output subnetName string = vnet.properties.subnets[0].name
