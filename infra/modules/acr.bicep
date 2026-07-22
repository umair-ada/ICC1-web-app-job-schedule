@description('Region for the ACR.')
param location string

@description('Globally unique ACR name (5-50 chars, alphanumeric only).')
@minLength(5)
@maxLength(50)
param name string

@description('Resource tags.')
param tags object

resource acr 'Microsoft.ContainerRegistry/registries@2023-11-01-preview' = {
  name: name
  location: location
  tags: tags
  sku: {
    name: 'Basic'
  }
  properties: {
    adminUserEnabled: false
    publicNetworkAccess: 'Enabled'
    anonymousPullEnabled: false
  }
}

output name string = acr.name
output loginServer string = acr.properties.loginServer
