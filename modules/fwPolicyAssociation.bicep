// modules/fwPolicyAssociation.bicep
// Asociación del Firewall Policy al Virtual Hub (Secure vHub).
// Puede variar por apiVersion/región. Si da error, asócielo vía Azure Firewall Manager.

targetScope = 'resourceGroup'

param vhubId string
param firewallPolicyId string
@description('Habilitar la asociación (true/false)')
param enabled bool = true

resource assoc 'Microsoft.Network/virtualHubs/hubFirewallPolicies@2023-11-01' = if (enabled) {
  name: '${last(split(vhubId, '/'))}/default'
  properties: {
    firewallPolicy: { id: firewallPolicyId }
  }
}
