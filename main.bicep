// Subscription-level composition for an infrastructure scaffold, not a cluster.
targetScope = 'subscription'

param rgName string
param location string
param uamiName string
param subRoleDefinitionIds array = []

param vnetAddressPrefixes array
param subnets object
param mysqlSubnetName string = 'snet-mysql'
param mysqlPrivateDnsZoneName string
param vwanName string
param vhubName string
param p2sName string
param vpnServerConfigName string
param p2sRootCerts array
param useAadAuthForP2S bool
param aadTenantId string
param aadAudience string
param aadIssuer string
param fwPolicyName string
param fwRuleCollections array
param kvName string
param saName string
param mysql object
@secure()
param mysqlAdminPassword string
param grafanaName string = ''
param rgRoleDefinitionIds array = []

resource rg 'Microsoft.Resources/resourceGroups@2024-03-01' = {
  name: rgName
  location: location
}

module identity './modules/identity.bicep' = {
  name: 'identity'
  scope: rg
  params: { location: location, uamiName: uamiName }
}

resource subRoles 'Microsoft.Authorization/roleAssignments@2022-04-01' = [for roleId in subRoleDefinitionIds: {
  name: guid(subscription().id, rgName, uamiName, roleId)
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', roleId)
    principalId: identity.outputs.principalId
    principalType: 'ServicePrincipal'
  }
}]

module rgDeploy './rg.lz.bicep' = {
  name: 'rg-lz'
  scope: rg
  params: {
    location: location
    uamiPrincipalId: identity.outputs.principalId
    vnetAddressPrefixes: vnetAddressPrefixes
    subnets: subnets
    mysqlSubnetName: mysqlSubnetName
    mysqlPrivateDnsZoneName: mysqlPrivateDnsZoneName
    vwanName: vwanName
    vhubName: vhubName
    p2sName: p2sName
    vpnServerConfigName: vpnServerConfigName
    p2sRootCerts: p2sRootCerts
    useAadAuthForP2S: useAadAuthForP2S
    aadTenantId: aadTenantId
    aadAudience: aadAudience
    aadIssuer: aadIssuer
    fwPolicyName: fwPolicyName
    fwRuleCollections: fwRuleCollections
    kvName: kvName
    saName: saName
    mysql: mysql
    mysqlAdminPassword: mysqlAdminPassword
    grafanaName: grafanaName
    rgRoleDefinitionIds: rgRoleDefinitionIds
  }
}

output resourceGroupId string = rg.id
output vnetId string = rgDeploy.outputs.vnetId
output mysqlFqdn string = rgDeploy.outputs.mysqlFqdn
output mysqlPrivateDnsZoneId string = rgDeploy.outputs.mysqlPrivateDnsZoneId
