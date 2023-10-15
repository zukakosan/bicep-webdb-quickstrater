param location string = resourceGroup().location
@allowed([
  'Enabled'
  'Disabled'
])
param bastionEnabled string 
@minValue(1)
@maxValue(3)
param webVmCount int = 2

param adminUsername string
@secure()
param adminPassword string

var vnetName = 'vnet-webdb'
var deployBastion = bastionEnabled == 'Enabled'

// create Vnet
module createVnet './modules/vnet.bicep' = {
  name: 'createVnet'
  params: {
    location: location
    vnetName: vnetName
  }
}

// deploy Azure Bastion if needed
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

// create web vms
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
    appGwVnetName: vnetName
    backendVmPrivateIps: [for i in range(0, webVmCount): createWebVms[i].outputs.vmPrivateIp]
  }
  dependsOn: [
    createVnet
  ]
}

// not need create internal load balancer
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
