targetScope = 'subscription'

@description('Azure region for all resources.')
param location string = 'francecentral'

@description('Short prefix for all resource names.')
param namePrefix string = 'britedge'

@description('Environment tag.')
@allowed(['dev', 'staging', 'prod'])
param environment string = 'dev'

@description('Postgres admin username.')
param pgAdminLogin string = 'britedgeadmin'

@description('Postgres admin password.')
@secure()
@minLength(16)
param pgAdminPassword string

@description('Container image the CA runs.')
param appImage string = ''

@description('Email addresses that receive Azure Budget alerts.')
param budgetContactEmails array = ['umair.masood@ada.ac.uk']

@description('Custom hostname bound to the Container App. Requires the DNS + managed cert to exist first.')
param customHostname string = 'app.icc1.dev'

@description('Name of the existing managed certificate in the CA environment.')
param managedCertificateName string = 'mc-britedge-cae-d-app-icc1-dev-9527'

var rgName = '${namePrefix}-${environment}-rg'
var resourceToken = substring(uniqueString(subscription().id, rgName), 0, 8)

var tags = {
  project: 'ICC1-BritEdge'
  environment: environment
  managedBy: 'bicep'
  owner: 'umair-ada'
}

resource rg 'Microsoft.Resources/resourceGroups@2024-11-01' = {
  name: rgName
  location: location
  tags: tags
}

module network 'modules/network.bicep' = {
  scope: rg
  name: 'network'
  params: {
    location: location
    namePrefix: namePrefix
    tags: tags
  }
}

module observability 'modules/observability.bicep' = {
  scope: rg
  name: 'observability'
  params: {
    location: location
    namePrefix: namePrefix
    tags: tags
  }
}

module acr 'modules/acr.bicep' = {
  scope: rg
  name: 'acr'
  params: {
    location: location
    name: '${namePrefix}acr${resourceToken}'
    tags: tags
  }
}

module storage 'modules/storage.bicep' = {
  scope: rg
  name: 'storage'
  params: {
    location: location
    name: '${namePrefix}st${resourceToken}'
    tags: tags
  }
}

module keyvault 'modules/keyvault.bicep' = {
  scope: rg
  name: 'keyvault'
  params: {
    location: location
    name: '${namePrefix}-kv-${resourceToken}'
    tags: tags
  }
}

module postgres 'modules/postgres.bicep' = {
  scope: rg
  name: 'postgres'
  params: {
    location: location
    serverName: '${namePrefix}-pg-${resourceToken}'
    adminLogin: pgAdminLogin
    adminPassword: pgAdminPassword
    delegatedSubnetId: network.outputs.postgresSubnetId
    privateDnsZoneId: network.outputs.postgresPrivateDnsZoneId
    tags: tags
  }
}

module containerApp 'modules/containerapp.bicep' = {
  scope: rg
  name: 'containerapp'
  params: {
    location: location
    envName: '${namePrefix}-cae-${environment}'
    appName: '${namePrefix}-app'
    infrastructureSubnetId: network.outputs.containerAppsSubnetId
    logAnalyticsWorkspaceId: observability.outputs.logAnalyticsWorkspaceId
    appInsightsConnectionString: observability.outputs.appInsightsConnectionString
    acrLoginServer: acr.outputs.loginServer
    keyVaultUri: keyvault.outputs.uri
    appImage: empty(appImage) ? '${acr.outputs.loginServer}/britedge:latest' : appImage
    customHostname: customHostname
    managedCertificateName: managedCertificateName
    tags: tags
  }
}

module acrPull 'modules/acrPull.bicep' = {
  scope: rg
  name: 'acrPullForContainerApp'
  params: {
    acrName: acr.outputs.name
    principalId: containerApp.outputs.principalId
  }
}

module kvSecretsUser 'modules/kvSecretsUser.bicep' = {
  scope: rg
  name: 'kvSecretsUserForContainerApp'
  params: {
    keyVaultName: keyvault.outputs.name
    principalId: containerApp.outputs.principalId
  }
}

module budget 'modules/budget.bicep' = {
  scope: rg
  name: 'budget'
  params: {
    budgetName: '${namePrefix}-monthly'
    amount: 100
    contactEmails: budgetContactEmails
    thresholds: [30, 50, 70]
    startDate: '2026-07-01T00:00:00Z'
    endDate: '2027-06-30T00:00:00Z'
  }
}

output resourceGroupName string = rg.name
output containerAppFqdn string = containerApp.outputs.fqdn
output acrLoginServer string = acr.outputs.loginServer
output keyVaultName string = keyvault.outputs.name
output postgresFqdn string = postgres.outputs.fqdn
