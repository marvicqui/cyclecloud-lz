// Create the identity at resource-group scope for the subscription composition.
targetScope = 'resourceGroup'
param location string
param uamiName string
resource identity 'Microsoft.ManagedIdentity/userAssignedIdentities@2023-01-31' = {
  name: uamiName
  location: location
}
output id string = identity.id
output principalId string = identity.properties.principalId
