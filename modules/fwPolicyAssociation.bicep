// modules/fwPolicyAssociation.bicep
// Asocia Firewall Policy al vHub (puede variar por API/región)

targetScope = 'resourceGroup'

param vhubId string
param firewallPolicyId string
param enabled bool = true

resource assoc 'Microsoft.Network/virtualHubs/hubFirewallPolicies@2023-11-01' = if (enabled) {
  name: '${last(split(vhubId, '/'))}/default'
  properties: {
    firewallPolicy: { id: firewallPolicyId }
  }
}
