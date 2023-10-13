param location string
param bastionVnetName string

@description('Address prefix for AzureBastionSubnet')
var bastionAddressPrefix = '10.0.100.0/24'

resource hubVnet 'Microsoft.Network/virtualNetworks@2023-04-01' existing = {
  name: bastionVnetName
}

resource bastionSubnet 'Microsoft.Network/virtualNetworks/subnets@2023-04-01' = {
  name: 'AzureBastionSubnet'
  parent: hubVnet
  properties: {
    addressPrefix: bastionAddressPrefix
  }
}

resource bastionPip 'Microsoft.Network/publicIPAddresses@2023-04-01' = {
  name: 'bastion-hub-pip'
  location: location
  sku:{
    name: 'Standard'
  }
  properties: {
    publicIPAllocationMethod: 'Static'
    publicIPAddressVersion: 'IPv4'
  }
}

resource azureBastion 'Microsoft.Network/bastionHosts@2023-04-01' = {
  name: 'bastion-hub'
  location: location
  properties: {
    ipConfigurations: [
      {
        name: 'bastionIpConfig'
        properties: {
          subnet: {
            id: bastionSubnet.id
          }
          publicIPAddress: {
            id: bastionPip.id
          }
        }
      }
    ]
  }
}
