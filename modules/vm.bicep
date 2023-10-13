param location string
param subnetId string
param vmName string
param adminUsername string
@secure()
param adminPassword string
// param diskName string
param vmSize string
param vmZone string
param installApache bool

var nicName = '${vmName}-nic'
var osDiskName = '${vmName}-disk'
// var vmDeployZone = {
//   value: vmZone
// }

// create network interface for ubuntu vm
resource networkInterface 'Microsoft.Network/networkInterfaces@2023-04-01' = {
  name: nicName
  location: location
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          privateIPAllocationMethod: 'Dynamic'
          subnet: {
            id: subnetId
          }
        }
      }
    ]
  }
}

// create ubuntu vm in spoke vnet
resource ubuntuVM 'Microsoft.Compute/virtualMachines@2023-03-01' = {
  name: vmName
  location: location
  properties: {
    hardwareProfile: {
      vmSize: vmSize
    }
    osProfile: {
      computerName: vmName
      adminUsername: adminUsername
      adminPassword: adminPassword
    }
    storageProfile: {
      imageReference: {
        publisher: 'Canonical'
        offer: '0001-com-ubuntu-server-focal'
        sku: '20_04-lts-gen2'
        version: 'latest'
      }
      osDisk: {
        name: osDiskName
        caching: 'ReadWrite'
        createOption: 'FromImage'
      }
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: networkInterface.id
        }
      ]
    }
    diagnosticsProfile: {
      bootDiagnostics: {
        enabled: false
      }
    }
  }
  zones: [
    vmZone
  ]
}

// install apache on ubuntu vm if needed
resource vmInstallApache 'Microsoft.Compute/virtualMachines/extensions@2023-03-01' = if (installApache) {
  name: 'installApache-${vmName}'
  location: location
  parent: ubuntuVM
  properties: {
    publisher: 'Microsoft.Azure.Extensions' // Linux VM のカスタム スクリプト拡張機能のパブリッシャー名
    type: 'CustomScript' // Linux VM のカスタム スクリプト拡張機能のタイプ名
    typeHandlerVersion: '2.0' // Linux VM のカスタム スクリプト拡張機能のバージョン
    autoUpgradeMinorVersion: true
    settings: {
      // カスタム スクリプト拡張機能に渡すコマンド
      commandToExecute: 'sudo apt-get -y update && sudo apt-get -y install apache2 && sudo systemctl start apache2.service'
    }
  }
}

// @description('return the private ip address of the vm to use from parent template')
// output vmPrivateIp string = networkInterface.properties.ipConfigurations[0].properties.privateIPAddress
