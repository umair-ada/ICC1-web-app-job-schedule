@description('Name of the ACR (must exist in this resource group).')
param acrName string

@description('Principal ID of the identity that needs AcrPull.')
param principalId string

resource acr 'Microsoft.ContainerRegistry/registries@2023-11-01-preview' existing = {
  name: acrName
}

var acrPullRoleId = '7f951dda-4ed3-4680-a7ca-43fe172d538d'

resource ra 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  scope: acr
  name: guid(acr.id, principalId, acrPullRoleId)
  properties: {
    principalId: principalId
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', acrPullRoleId)
    principalType: 'ServicePrincipal'
  }
}
