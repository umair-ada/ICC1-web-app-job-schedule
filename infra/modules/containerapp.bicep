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

@description('App Insights connection string — surfaced to the app via APPLICATIONINSIGHTS_CONNECTION_STRING.')
param appInsightsConnectionString string

@description('Initial image the Container App runs. Public hello-world at first deploy; CI/CD swaps to the ACR image later.')
param initialImage string

@description('Target port the container listens on. Hello-world bootstrap image uses 80; the Flask app uses 8080. Swapped by build-and-deploy-app.sh at the same time as the image.')
param initialTargetPort int = 80

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
        targetPort: initialTargetPort
        transport: 'auto'
        allowInsecure: false
        traffic: [
          {
            latestRevision: true
            weight: 100
          }
        ]
      }
    }
    template: {
      containers: [
        {
          name: 'app'
          image: initialImage
          resources: {
            cpu: json('0.5')
            memory: '1.0Gi'
          }
          env: [
            {
              name: 'APPLICATIONINSIGHTS_CONNECTION_STRING'
              value: appInsightsConnectionString
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
