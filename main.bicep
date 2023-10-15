param location string = resourceGroup().location

@allowed([
  'Enabled'
  'Disabled'
])
@description('Enable or disable Azure Bastion. If enabled, Azure Bastion will be deployed in the same VNet as the web VMs. If disabled, you will need to connect to the web VMs using a public IP address.')
param bastionEnabled string 

@minValue(1)
@maxValue(3)
@description('Number of web VMs to deploy.')
param webVmCount int = 2

param adminUsername string
@secure()
param adminPassword string

var vnetName = 'vnet-webdb'
@description('The bool variable to determine if Azure Bastion should be deployed.')
var deployBastion = bastionEnabled == 'Enabled'

// create virtual network
module createVnet './modules/vnet.bicep' = {
  name: 'createVnet'
  params: {
    location: location
    vnetName: vnetName
  }
}

// create web server vms
module createWebVms './modules/vm.bicep' = [for i in range(1, webVmCount):{
  name: 'createWebVm-${i}'
  params: {
    location: location
    subnetId: createVnet.outputs.webSubnetId
    vmName: 'webvm-${i}'
    adminUsername: adminUsername
    adminPassword: adminPassword
    vmSize: 'Standard_B1s'
    vmZone: '${i}'
  }
}]

// create Application Gateway
module createAppGw './modules/appgw.bicep' = {
  name: 'createAppGw'
  params: {
    location: location
    appGwSubnetId: createVnet.outputs.appGwSubnetId
    backendVmPrivateIps: [for i in range(0, webVmCount): createWebVms[i].outputs.vmPrivateIp]
  }
  dependsOn: [
    createVnet
  ]
}

// create postgreSQL with private endpoints
module createPostgreSql './modules/postgreSql.bicep' = {
  name: 'createPostgreSql'
  params: {
    location: location
    availabilityZone: '1'
    postgreSqlAdminUser: adminUsername
    postgreSqlAdminPassword: adminPassword
    serverName: 'postgresql-${take(uniqueString(resourceGroup().id),4)}'
    linkedVnetId: createVnet.outputs.webDbVnetId
    dbSubnetId: createVnet.outputs.dbSubnetId
  }
  dependsOn: [
    createVnet
  ]
}

// deploy Azure Bastion if needed to connect to web VMs for administration
module createAzureBastion './modules/bastion.bicep' = if(deployBastion) {
  name: 'deployAzureBastion'
  params: {
    location: location
    bastionVnetName: vnetName
  }
  dependsOn: [
    createVnet
  ]
}
