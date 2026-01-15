@description('Name of the Network Security Group')
param nsgName string

@description('Azure region')
param location string

@description('Allowed source IP for RDP (CIDR format)')
param allowedRdpSourceIp string

@description('Resource tags')
param tags object

// Network Security Group with RDP rule
resource nsg 'Microsoft.Network/networkSecurityGroups@2023-11-01' = {
  name: nsgName
  location: location
  tags: tags
  properties: {
    securityRules: [
      {
        name: 'AllowRDP'
        properties: {
          priority: 100
          direction: 'Inbound'
          access: 'Allow'
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '3389'
          sourceAddressPrefix: allowedRdpSourceIp
          destinationAddressPrefix: '*'
          description: 'Allow RDP from specified IP'
        }
      }
      {
        name: 'DenyAllInbound'
        properties: {
          priority: 4096
          direction: 'Inbound'
          access: 'Deny'
          protocol: '*'
          sourcePortRange: '*'
          destinationPortRange: '*'
          sourceAddressPrefix: '*'
          destinationAddressPrefix: '*'
          description: 'Deny all other inbound traffic'
        }
      }
    ]
  }
}

output nsgId string = nsg.id
output nsgName string = nsg.name
