// modules/firewallPolicy.bicep
// Firewall Policy + Rule Collection Groups (acepta applicationRuleCollections/networkRuleCollections)

targetScope = 'resourceGroup'

param location string
param fwPolicyName string

@description('Arreglo de RCGs con applicationRuleCollections y networkRuleCollections')
param fwRuleCollections array

resource fwp 'Microsoft.Network/firewallPolicies@2023-11-01' = {
  name: fwPolicyName
  location: location
  properties: {
    threatIntelMode: 'Alert'
  }
}

// Normaliza cada grupo a la propiedad final "ruleCollections"
var normalizedGroups = [for rcg in fwRuleCollections: {
  name: rcg.name
  priority: rcg.priority
  ruleCollections: concat(
    map(rcg.?applicationRuleCollections ?? [], arc => {
      ruleCollectionType: 'FirewallPolicyFilterRuleCollection'
      name: arc.name
      priority: arc.priority
      action: { type: arc.action }
      rules: map(arc.rules, r => {
        ruleType: 'ApplicationRule'
        name: r.name
        sourceAddresses: r.sourceAddresses
        protocols: map(r.?protocols ?? [], p => {
          protocolType: p.protocolType
          port: p.port
        })
        fqdnTags: r.?fqdnTags ?? []
        targetFqdns: r.?targetFqdns ?? []
      })
    }),
    map(rcg.?networkRuleCollections ?? [], nrc => {
      ruleCollectionType: 'FirewallPolicyFilterRuleCollection'
      name: nrc.name
      priority: nrc.priority
      action: { type: nrc.action }
      rules: map(nrc.rules, r => {
        ruleType: 'NetworkRule'
        name: r.name
        ipProtocols: r.ipProtocols
        sourceAddresses: r.sourceAddresses
        destinationAddresses: r.destinationAddresses
        destinationPorts: r.destinationPorts
      })
    })
  )
}]

resource rcgs 'Microsoft.Network/firewallPolicies/ruleCollectionGroups@2023-11-01' = [for rcg in normalizedGroups: {
  parent: fwp
  name: rcg.name
  properties: {
    priority: rcg.priority
    ruleCollections: rcg.ruleCollections
  }
}]

output firewallPolicyId string = fwp.id
