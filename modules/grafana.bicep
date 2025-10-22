// modules/grafana.bicep
// Azure Managed Grafana (Standard) con identidad de sistema

targetScope = 'resourceGroup'

param location string
param grafanaName string

resource graf 'Microsoft.Dashboard/grafana@2023-10-01' = {
  name: grafanaName
  location: location
  identity: { type: 'SystemAssigned' }
  properties: {
    publicNetworkAccess: 'Enabled'
    zoneRedundancy: 'Disabled'
    deterministicOutboundIP: 'Disabled'
    apiKey: 'Disabled'
  }
  sku: { name: 'Standard' }
}

output endpoint string = 'https://${graf.name}.grafana.azure.com'
output grafanaId string = graf.id
