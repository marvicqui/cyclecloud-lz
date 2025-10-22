// main.bicep
// Crea RG, UAMI, roles a nivel subscription y despliega el landing zone en el RG

targetScope = 'subscription'

@description('Resource Group name')
param rgName string

@description('Deployment location (for RG and regional resources)')
param location string = deployment().location

@description('User Assigned Managed Identity name')
param uamiName string = 'uami-lz'

@description('Role definition GUIDs to assign at subscription level to the UAMI (e.g., Reader, Contributor, Monitoring Reader, etc.)')
param subRoleDefinitionIds array = []

// Crea el Resource Group
resource rg 'Microsoft.Resources/resourceGroups@2022-09-01' = {
  name: rgName
  location: location
}

// Crea la UAMI
resource uami 'Microsoft.ManagedIdentity/userAssignedIdentities@2023-01-31-preview' = {
  name: uamiName
  location: location
}

// Role assignments a nivel suscripción para la UAMI
resource subRoleAssignments 'Microsoft.Authorization/roleAssignments@2022-04-01' = [for roleId in subRoleDefinitionIds: {
  name: guid(subscription().id, uami.id, roleId)
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', roleId)
    principalId: uami.properties.principalId
    principalType: 'ServicePrincipal'
  }
}]

// Parámetros para el despliegue en el RG
@description('Virtual network address space')
param vnetAddressPrefixes array = [ '10.10.0.0/16' ]

@description('Subnets map (name -> prefix)')
param subnets object = {
  'AzureBastionSubnet': '10.10.0.0/26'
  'snet-workload': '10.10.1.0/24'
  'snet-mysql': '10.10.2.0/26'
}

@description('Virtual WAN name')
param vwanName string = 'vwan-lz'

@description('Virtual Hub name')
param vhubName string = 'vhub-lz'

@description('P2S VPN name')
param p2sName string = 'p2s-lz'

@description('VPN Server Configuration name')
param vpnServerConfigName string = 'vpnsc-lz'

@description('Root certificates for P2S (Base64)')
param p2sRootCerts array = []

@description('Enable AAD authentication for P2S (true/false)')
param useAadAuthForP2S bool = false

@description('AAD Tenant ID for P2S (GUID)')
param aadTenantId string = ''

@description('AAD Audience (App ID) for P2S')
param aadAudience string = ''

@description('AAD Issuer for P2S (e.g., https://sts.windows.net/<tenantId>/)')
param aadIssuer string = ''

@description('Firewall Policy name (for secured hub usage)')
param fwPolicyName string = 'fwp-lz'

@description('Rule Collection Groups definition for the Firewall Policy')
param fwRuleCollections array = [] // ver esquema en modules/firewallPolicy.bicep

@description('Key Vault name')
param kvName string = 'kv-lz-001'

@description('Storage Account name (global unique, 3-24 chars)')
param saName string

@description('MySQL Flexible Server settings')
param mysql object = {
  name: 'mysql-lz-001'
  version: '8.0.21'
  sku: 'Standard_D2ds_v4'
  tier: 'GeneralPurpose'
  storageSizeGB: 128
  backupRetentionDays: 7
  geoRedundantBackup: 'Disabled'
  administratorLogin: 'mysqladmin'
}

@secure()
param mysqlAdminPassword string

@description('Azure Managed Grafana name')
param grafanaName string = 'grafana-lz'

@description('Role definition GUIDs to assign at RG level to the UAMI')
param rgRoleDefinitionIds array = []

module rgDeploy './rg.lz.bicep' = {
  name: 'rg-lz'
  scope: rg
  params: {
    location: location
    uamiId: uami.id
    vnetAddressPrefixes: vnetAddressPrefixes
    subnets: subnets
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

output resourceGroupName string = rg.name
output uamiPrincipalId string = uami.properties.principalId
