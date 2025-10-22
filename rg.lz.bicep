// rg.lz.bicep
// Despliega los recursos dentro del RG y roles a nivel RG

targetScope = 'resourceGroup'

param location string
param uamiId string

// Red
param vnetAddressPrefixes array
param subnets object

// vWAN
param vwanName string
param vhubName string
param p2sName string
param vpnServerConfigName string
param p2sRootCerts array
param useAadAuthForP2S bool
param aadTenantId string
param aadAudience string
param aadIssuer string

// Firewall Policy
param fwPolicyName string
param fwRuleCollections array

// Key Vault
param kvName string

// Storage
param saName string

// MySQL
param mysql object
@secure()
param mysqlAdminPassword string

// Grafana
param grafanaName string

// Roles a nivel RG para UAMI
param rgRoleDefinitionIds array

module network './modules/network.bicep' = {
  name: 'network'
  params: {
    location: location
    vnetAddressPrefixes: vnetAddressPrefixes
    subnets: subnets
  }
}

module vwan './modules/vwan.bicep' = {
  name: 'vwan'
  params: {
    location: location
    vwanName: vwanName
    vhubName: vhubName
    vpnServerConfigName: vpnServerConfigName
    p2sName: p2sName
    p2sRootCerts: p2sRootCerts
    useAadAuthForP2S: useAadAuthForP2S
    aadTenantId: aadTenantId
    aadAudience: aadAudience
    aadIssuer: aadIssuer
    vnetId: network.outputs.vnetId
  }
}

module fwPolicy './modules/firewallPolicy.bicep' = {
  name: 'fwPolicy'
  params: {
    location: location
    fwPolicyName: fwPolicyName
    fwRuleCollections: fwRuleCollections
  }
}

// Asociación del Firewall Policy al vHub (best-effort; depende de API/Región)
module fwPolicyAssoc './modules/fwPolicyAssociation.bicep' = {
  name: 'fwPolicyAssoc'
  params: {
    vhubId: vwan.outputs.vhubId
    firewallPolicyId: fwPolicy.outputs.firewallPolicyId
    enabled: true
  }
}

module kv './modules/keyvault.bicep' = {
  name: 'kv'
  params: {
    location: location
    kvName: kvName
  }
}

module sa './modules/storage.bicep' = {
  name: 'storage'
  params: {
    location: location
    saName: saName
  }
}

module mysqlMod './modules/mysql.bicep' = {
  name: 'mysql'
  params: {
    location: location
    settings: mysql
    adminPassword: mysqlAdminPassword
    delegatedSubnetId: network.outputs.mysqlSubnetId
  }
}

module graf './modules/grafana.bicep' = {
  name: 'grafana'
  params: {
    location: location
    grafanaName: grafanaName
  }
}

module rgRoles './modules/identity.rgRoles.bicep' = {
  name: 'rgRoles'
  params: {
    principalId: reference(uamiId, '2023-01-31-preview').principalId
    roleDefinitionIds: rgRoleDefinitionIds
  }
}

// Outputs útiles
output vnetId string = network.outputs.vnetId
output vhubId string = vwan.outputs.vhubId
output keyVaultName string = kv.outputs.kvName
output storageAccountName string = sa.outputs.saName
output mysqlFqdn string = mysqlMod.outputs.fqdn
output grafanaEndpoint string = graf.outputs.endpoint
