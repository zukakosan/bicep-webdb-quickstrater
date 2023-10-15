param location string
param availabilityZone string
param postgreSqlAdminUser string

@secure()
param postgreSqlAdminPassword string
param serverName string
param linkedVnetId string
param dbSubnetId string

var serverEdition = 'GeneralPurpose'
var skuSizeGB = 128
var dbInstanceType = 'Standard_D2ds_v4'
var haMode = 'ZoneRedundant'
var version = '12'

resource postgreSqlPrivateDnsZone 'Microsoft.Network/privateDnsZones@2020-06-01' = {
  name: '${serverName}.private.postgres.database.azure.com'
  location: 'global'
}

resource virtualNetworkLinks 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2020-06-01' = {
  name: 'vnet-link-${serverName}'
  location: 'global'
  parent: postgreSqlPrivateDnsZone
  properties: {
    registrationEnabled: false
    virtualNetwork: {
      id: linkedVnetId
    }
  }
}

resource postgreSql 'Microsoft.DBforPostgreSQL/flexibleServers@2022-12-01' = {
  name: serverName
  location: location
  sku: {
    name: dbInstanceType
    tier: serverEdition
  }
  properties: {
    version: version
    administratorLogin: postgreSqlAdminUser
    administratorLoginPassword: postgreSqlAdminPassword
    network: {
      delegatedSubnetResourceId: dbSubnetId
      privateDnsZoneArmResourceId: postgreSqlPrivateDnsZone.id
    }
    highAvailability: {
      mode: haMode
    }
    storage: {
      storageSizeGB: skuSizeGB
    }
    backup: {
      backupRetentionDays: 7
      geoRedundantBackup: 'Disabled'
    }
    availabilityZone: availabilityZone
  }
}
