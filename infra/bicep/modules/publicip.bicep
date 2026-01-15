@description('Name of the Public IP')
param pipName string

@description('Azure region')
param location string

@description('Resource tags')
param tags object

// Public IP Address
resource pip 'Microsoft.Network/publicIPAddresses@2023-11-01' = {
  name: pipName
  location: location
  tags: tags
  sku: {
    name: 'Standard'
  }
  properties: {
    publicIPAllocationMethod: 'Static'
    publicIPAddressVersion: 'IPv4'
  }
}

output pipId string = pip.id
output pipAddress string = pip.properties.ipAddress
output pipName string = pip.name
