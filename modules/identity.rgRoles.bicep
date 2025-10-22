// modules/identity.rgRoles.bicep
// Role assignments a nivel RG a la UAMI

targetScope = 'resourceGroup'

param principalId string
param roleDefinitionIds array

resource rgRoleAssignments 'Microsoft.Authorization/roleAssignments@2022-04-01' = [for roleId in roleDefinitionIds: {
  name: guid(resourceGroup().id, principalId, roleId)
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', roleId)
    principalId: principalId
    principalType: 'ServicePrincipal'
  }
}]
