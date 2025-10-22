// modules/storage.bicep
// Storage Account endurecido

targetScope = 'resourceGroup'

param location string
param saName string

resource sa 'Microsoft.Storage/storageAccounts@2023-05-01' = {
  name: saName
  location: location
  sku: { name: 'Standard_LRS' }
  kind: 'StorageV2'
  properties: {
    allowBlobPublicAccess: false
    minimumTlsVersion: 'TLS1_2'
    supportsHttpsTrafficOnly: true
    networkAcls: { bypass: 'AzureServices', defaultAction: 'Deny' }
  }
}

output saName string = sa.name
output saId string = sa.id
