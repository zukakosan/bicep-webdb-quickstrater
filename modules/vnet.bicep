param location string
// param installApache bool
// param deployAzureBastion bool
param vnetName string

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
      // {
      //   name: appgwSubnetName
      //   properties: {
      //     addressPrefix: '10.0.0.0/24'
      //   }
      // }
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
          networkSecurityGroup: {
            id: nsgDbSubnet.id
          }
        }
      }
    ]
  }
  resource webSubnet 'subnets' existing = {
    name: webSubnetName
  }
}

// // create azure bastion after hub vnet creattion if deployAzureBastion is true
// module createAzureBastion './bastion.bicep' = if(deployAzureBastion) {
//   name: 'createAzureBastion'
//   params: {
//     location: location
//   }
//   dependsOn: [
//     hubVnet
//   ]
// }

output webSubnetId string = webDbVnet::webSubnet.id
