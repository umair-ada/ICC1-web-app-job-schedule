@description('Key Vault name.')
param keyVaultName string

@description('Principal ID to grant Key Vault Secrets User to.')
param principalId string

resource kv 'Microsoft.KeyVault/vaults@2023-07-01' existing = {
  name: keyVaultName
}

var roleId = '4633458b-17de-408a-b874-0445c86b69e6'

resource ra 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  scope: kv
  name: guid(kv.id, principalId, roleId)
  properties: {
    principalId: principalId
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', roleId)
    principalType: 'ServicePrincipal'
  }
}
