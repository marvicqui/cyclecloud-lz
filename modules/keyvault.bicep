// modules/keyvault.bicep
// Key Vault con RBAC y soft delete habilitado

targetScope = 'resourceGroup'

param location string
param kvName string

resource kv 'Microsoft.KeyVault/vaults@2024-12-01-preview' = {
  name: kvName
  location: location
  properties: {
    tenantId: subscription().tenantId
    enableRbacAuthorization: true
    enableSoftDelete: true
    softDeleteRetentionInDays: 90
    sku: { family: 'A', name: 'standard' }
    publicNetworkAccess: 'Disabled'
    networkAcls: { bypass: 'AzureServices', defaultAction: 'Deny' }
  }
}

output kvName string = kv.name
output kvId string = kv.id
output kvUri string = 'https://${kv.name}.vault.azure.net/'
