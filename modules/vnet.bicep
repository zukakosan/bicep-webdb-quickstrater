param location string
param vnetName string

var appgwSubnetName = 'subnet-appgw'
var webSubnetName = 'subnet-web'
var dbSubnetName = 'subnet-db'

resource nsgWebSubnet 'Microsoft.Network/networkSecurityGroups@2023-04-01' = {
  name: 'nsg-web'
  location: location
  properties: {
    securityRules: [
      {
        name: 'nsgRule'
        properties: {
          description: 'allow http traffic from any'
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '80'
          sourceAddressPrefix: '*'
          destinationAddressPrefix: '*'
          access: 'Allow'
          priority: 1000
          direction: 'Inbound'
        }
      }
    ]
  }
}

resource nsgDbSubnet 'Microsoft.Network/networkSecurityGroups@2023-04-01' = {
  name: 'nsg-db'
  location: location
  properties: {
    // securityRules: [
    //   {
    //     name: 'nsgRule'
    //     properties: {
    //       description: 'description'
    //       protocol: 'Tcp'
    //       sourcePortRange: '*'
    //       destinationPortRange: '*'
    //       sourceAddressPrefix: '*'
    //       destinationAddressPrefix: '*'
    //       access: 'Allow'
    //       priority: 100
    //       direction: 'Inbound'
    //     }
    //   }
    // ]
  }
}

// create vnet
resource webDbVnet 'Microsoft.Network/virtualNetworks@2023-04-01' = {
  name: vnetName
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [
        '10.0.0.0/16'
      ]
    }
    subnets: [
      {
        name: appgwSubnetName
        properties: {
          addressPrefix: '10.0.0.0/24'
        }
      }
      {
        name: webSubnetName
        properties: {
          addressPrefix: '10.0.1.0/24'
          networkSecurityGroup: {
            id: nsgWebSubnet.id
          }
        }
      }
      {
        name: dbSubnetName
        properties: {
          addressPrefix: '10.0.2.0/24'
          delegations: [
            {
              name: 'Microsoft.DBforPostgreSQL/flexibleServers'
              properties: {
                serviceName: 'Microsoft.DBforPostgreSQL/flexibleServers'
              }
            }
          ]
          networkSecurityGroup: {
            id: nsgDbSubnet.id
          }
        }
      }
    ]
  }
  resource appGwSubnet 'subnets' existing = {
    name: appgwSubnetName
  }
  resource webSubnet 'subnets' existing = {
    name: webSubnetName
  }
  resource dbSubnet 'subnets' existing = {
    name: dbSubnetName
  }
}

@description('The ID of the virtual network.')
output webDbVnetId string = webDbVnet.id
@description('The ID of the application gateway subnet.')
output appGwSubnetId string = webDbVnet::appGwSubnet.id
@description('The ID of the web subnet.')
output webSubnetId string = webDbVnet::webSubnet.id
@description('The ID of the database subnet.')
output dbSubnetId string = webDbVnet::dbSubnet.id
