// modules/vwan.bicep
// vWAN + vHub + P2S (cert y/o AAD) + conexión Hub↔VNet

targetScope = 'resourceGroup'

param location string
param vwanName string
param vhubName string
param vpnServerConfigName string
param p2sName string
param p2sRootCerts array
param vnetId string

// AAD P2S (opcional)
param useAadAuthForP2S bool = false
param aadTenantId string = ''
param aadAudience string = ''
param aadIssuer string = ''

resource vwan 'Microsoft.Network/virtualWans@2023-11-01' = {
  name: vwanName
  location: location
  properties: { type: 'Standard' }
}

resource vhub 'Microsoft.Network/virtualHubs@2023-11-01' = {
  name: vhubName
  location: location
  properties: {
    virtualWan: { id: vwan.id }
    addressPrefix: '10.20.0.0/24'
    sku: 'Standard'
  }
}

resource vsc 'Microsoft.Network/vpnServerConfigurations@2023-11-01' = {
  name: vpnServerConfigName
  location: location
  properties: {
    vpnProtocols: [ 'OpenVPN' ]
    vpnAuthenticationTypes: concat(
      length(p2sRootCerts) > 0 ? [ 'Certificate' ] : [],
      useAadAuthForP2S ? [ 'AAD' ] : []
    )
    vpnClientRootCertificates: [for (c, i) in p2sRootCerts: {
      name: 'rootCert${i}'
      publicCertData: string(c)
    }]
    aadAuthenticationParameters: useAadAuthForP2S ? {
      aadTenant: aadTenantId
      aadAudience: aadAudience
      aadIssuer: aadIssuer
    } : null
  }
}

resource p2s 'Microsoft.Network/p2sVpnGateways@2023-11-01' = {
  name: p2sName
  location: location
  properties: {
    virtualHub: { id: vhub.id }
    vpnServerConfiguration: { id: vsc.id }
    vpnGatewayScaleUnit: 1
  }
}

resource hvnConn 'Microsoft.Network/virtualHubs/hubVirtualNetworkConnections@2023-11-01' = {
  name: '${vhub.name}/conn-to-vnet'
  properties: {
    remoteVirtualNetwork: { id: vnetId }
    allowHubToRemoteVnetTransit: true
    allowRemoteVnetToUseHubVnetGateways: true
    enableInternetSecurity: true
  }
}

output vhubId string = vhub.id
