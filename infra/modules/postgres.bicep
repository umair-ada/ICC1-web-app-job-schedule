@description('Region for the Postgres server.')
param location string

@description('Server name (3-63 lowercase alphanumeric + hyphens).')
@minLength(3)
@maxLength(63)
param serverName string

@description('Admin login username.')
param adminLogin string

@description('Admin login password.')
@secure()
param adminPassword string

@description('Resource ID of the delegated subnet for VNet-injected private access.')
param delegatedSubnetId string

@description('Resource ID of the private DNS zone linked to the VNet.')
param privateDnsZoneId string

@description('Resource tags.')
param tags object

@description('Postgres engine major version.')
@allowed(['13', '14', '15', '16'])
param version string = '16'

resource pg 'Microsoft.DBforPostgreSQL/flexibleServers@2024-08-01' = {
  name: serverName
  location: location
  tags: tags
  sku: {
    name: 'Standard_B1ms'
    tier: 'Burstable'
  }
  properties: {
    version: version
    administratorLogin: adminLogin
    administratorLoginPassword: adminPassword
    storage: {
      storageSizeGB: 32
      autoGrow: 'Disabled'
    }
    backup: {
      backupRetentionDays: 7
      geoRedundantBackup: 'Disabled'
    }
    network: {
      delegatedSubnetResourceId: delegatedSubnetId
      privateDnsZoneArmResourceId: privateDnsZoneId
      publicNetworkAccess: 'Disabled'
    }
    highAvailability: {
      mode: 'Disabled'
    }
    createMode: 'Default'
  }
}

resource appDb 'Microsoft.DBforPostgreSQL/flexibleServers/databases@2024-08-01' = {
  parent: pg
  name: 'britedge'
  properties: {
    charset: 'UTF8'
    collation: 'en_US.utf8'
  }
}

output serverName string = pg.name
output fqdn string = pg.properties.fullyQualifiedDomainName
output databaseName string = appDb.name
