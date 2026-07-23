@description('Region for the Container Apps Environment + App.')
param location string

@description('Managed environment name.')
param envName string

@description('Container App name (2-32 lowercase alphanumeric + hyphens).')
@minLength(2)
@maxLength(32)
param appName string

@description('Resource ID of the /23 subnet delegated to Microsoft.App/environments.')
param infrastructureSubnetId string

@description('Resource ID of the Log Analytics workspace backing the environment.')
param logAnalyticsWorkspaceId string

@description('App Insights connection string.')
param appInsightsConnectionString string

@description('ACR login server (e.g. britedgeacr...azurecr.io).')
param acrLoginServer string

@description('Key Vault URI (https://<name>.vault.azure.net/).')
param keyVaultUri string

@description('Container image the CA runs.')
param appImage string = '${acrLoginServer}/britedge:latest'

@description('Custom hostname to bind to the CA (leave empty on fresh deploys).')
param customHostname string = ''

@description('Managed certificate name in the CA environment for the custom hostname.')
param managedCertificateName string = ''

@description('Resource tags.')
param tags object

resource law 'Microsoft.OperationalInsights/workspaces@2023-09-01' existing = {
  name: last(split(logAnalyticsWorkspaceId, '/'))
}

resource env 'Microsoft.App/managedEnvironments@2024-03-01' = {
  name: envName
  location: location
  tags: tags
  properties: {
    appLogsConfiguration: {
      destination: 'log-analytics'
      logAnalyticsConfiguration: {
        customerId: law.properties.customerId
        sharedKey: law.listKeys().primarySharedKey
      }
    }
    vnetConfiguration: {
      internal: false
      infrastructureSubnetId: infrastructureSubnetId
    }
    workloadProfiles: [
      {
        name: 'Consumption'
        workloadProfileType: 'Consumption'
      }
    ]
    zoneRedundant: false
  }
}

resource app 'Microsoft.App/containerApps@2024-03-01' = {
  name: appName
  location: location
  tags: tags
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    managedEnvironmentId: env.id
    workloadProfileName: 'Consumption'
    configuration: {
      activeRevisionsMode: 'Multiple'
      ingress: {
        external: true
        targetPort: 8080
        transport: 'auto'
        allowInsecure: false
        traffic: [
          {
            latestRevision: true
            weight: 100
          }
        ]
        customDomains: empty(customHostname) || empty(managedCertificateName) ? [] : [
          {
            name: customHostname
            bindingType: 'SniEnabled'
            certificateId: '${env.id}/managedCertificates/${managedCertificateName}'
          }
        ]
      }
      registries: [
        {
          server: acrLoginServer
          identity: 'system'
        }
      ]
      secrets: [
        {
          name: 'flask-secret-key'
          keyVaultUrl: '${keyVaultUri}secrets/flask-secret-key'
          identity: 'system'
        }
        {
          name: 'database-url'
          keyVaultUrl: '${keyVaultUri}secrets/database-url'
          identity: 'system'
        }
      ]
    }
    template: {
      containers: [
        {
          name: 'app'
          image: appImage
          resources: {
            cpu: json('0.5')
            memory: '1.0Gi'
          }
          env: [
            {
              name: 'APPLICATIONINSIGHTS_CONNECTION_STRING'
              value: appInsightsConnectionString
            }
            {
              name: 'PORT'
              value: '8080'
            }
            {
              name: 'SECRET_KEY'
              secretRef: 'flask-secret-key'
            }
            {
              name: 'DATABASE_URL'
              secretRef: 'database-url'
            }
          ]
          probes: [
            {
              type: 'Liveness'
              httpGet: {
                path: '/healthz'
                port: 8080
              }
              initialDelaySeconds: 15
              periodSeconds: 30
            }
            {
              type: 'Readiness'
              httpGet: {
                path: '/healthz'
                port: 8080
              }
              initialDelaySeconds: 5
              periodSeconds: 10
            }
          ]
        }
      ]
      scale: {
        minReplicas: 0
        maxReplicas: 10
        rules: [
          {
            name: 'http-concurrency'
            http: {
              metadata: {
                concurrentRequests: '50'
              }
            }
          }
        ]
      }
    }
  }
}

output principalId string = app.identity.principalId
output fqdn string = app.properties.configuration.ingress.fqdn
output name string = app.name
