// main.bicep (fragmento relevante)

@description('Subnets map (name -> prefix)')
param subnets object

@description('Subnet a delegar para MySQL (debe existir en el mapa "subnets")')
param mysqlSubnetName string = 'CycleCloudSubnet'

...

module rgDeploy './rg.lz.bicep' = {
  name: 'rg-lz'
  scope: rg
  params: {
    location: location
    uamiId: uami.id
    vnetAddressPrefixes: vnetAddressPrefixes
    subnets: subnets
    mysqlSubnetName: mysqlSubnetName
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
    grafanaName: grafanaName // opcional (puede ir vacío)
    rgRoleDefinitionIds: rgRoleDefinitionIds
  }
}
