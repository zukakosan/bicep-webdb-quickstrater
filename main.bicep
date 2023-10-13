param location string = resourceGroup().location
@allowed([
  'Enabled'
  'Disabled'
])
param bastionEnabled string 
@minValue(1)
@maxValue(3)
param webVmCount int = 2
@allowed([
  'Enabled'
  'Disabled'
])
param vmApacheEnabled string 

param adminUsername string
@secure()
param adminPassword string

var vnetName = 'vnet-webdb'
var deployBastion = bastionEnabled == 'Enabled'
var installApache = vmApacheEnabled == 'Enabled'


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

// create Application Gateway
module createAppGw './modules/appgw.bicep' = {
  name: 'createAppGw'
  params: {
    location: location
    appGwVnetName: vnetName
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
    installApache: installApache
  }
}]

// create internal load balancer
// create postgreSQL with private endpoints
