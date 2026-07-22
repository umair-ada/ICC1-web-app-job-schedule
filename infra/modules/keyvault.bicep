@description('Region for the Key Vault.')
param location string

@description('Key Vault name (3-24 alphanumerics + hyphens).')
@minLength(3)
@maxLength(24)
param name string

@description('Resource tags.')
param tags object

resource kv 'Microsoft.KeyVault/vaults@2023-07-01' = {
  name: name
  location: location
  tags: tags
  properties: {
    tenantId: subscription().tenantId
    sku: {
      family: 'A'
      name: 'standard'
    }
    enableRbacAuthorization: true
    enableSoftDelete: true
    softDeleteRetentionInDays: 7
    enablePurgeProtection: null
    publicNetworkAccess: 'Enabled'
  }
}

output name string = kv.name
output uri string = kv.properties.vaultUri
output id string = kv.id
