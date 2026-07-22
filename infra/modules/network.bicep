@description('Region for the VNet.')
param location string

@description('Prefix for VNet + subnet names.')
param namePrefix string

@description('Resource tags.')
param tags object

var vnetName = '${namePrefix}-vnet'

resource vnet 'Microsoft.Network/virtualNetworks@2024-01-01' = {
  name: vnetName
  location: location
  tags: tags
  properties: {
    addressSpace: {
      addressPrefixes: ['10.20.0.0/16']
    }
    subnets: [
      {
        name: 'containerapps-infra'
        properties: {
          addressPrefix: '10.20.0.0/23'
          delegations: [
            {
              name: 'Microsoft.App/environments'
              properties: {
                serviceName: 'Microsoft.App/environments'
              }
            }
          ]
        }
      }
      {
        name: 'postgres'
        properties: {
          addressPrefix: '10.20.4.0/24'
          delegations: [
            {
              name: 'Microsoft.DBforPostgreSQL/flexibleServers'
              properties: {
                serviceName: 'Microsoft.DBforPostgreSQL/flexibleServers'
              }
            }
          ]
        }
      }
    ]
  }
}

resource pgDnsZone 'Microsoft.Network/privateDnsZones@2024-06-01' = {
  name: '${namePrefix}.private.postgres.database.azure.com'
  location: 'global'
  tags: tags
}

resource pgDnsZoneLink 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2024-06-01' = {
  parent: pgDnsZone
  name: '${namePrefix}-pg-vnet-link'
  location: 'global'
  properties: {
    virtualNetwork: {
      id: vnet.id
    }
    registrationEnabled: false
  }
}

output vnetId string = vnet.id
output containerAppsSubnetId string = vnet.properties.subnets[0].id
output postgresSubnetId string = vnet.properties.subnets[1].id
output postgresPrivateDnsZoneId string = pgDnsZone.id
