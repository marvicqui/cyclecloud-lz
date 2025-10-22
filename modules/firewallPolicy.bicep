// modules/firewallPolicy.bicep
// Firewall Policy + Rule Collection Groups

targetScope = 'resourceGroup'

param location string
param fwPolicyName string
@description('Array de rule collections. Ver ejemplo en parameters.dev.json/prod.json')
param fwRuleCollections array

resource fwp 'Microsoft.Network/firewallPolicies@2023-11-01' = {
  name: fwPolicyName
  location: location
  properties: { threatIntelMode: 'Alert' }
}

resource rcgs 'Microsoft.Network/firewallPolicies/ruleCollectionGroups@2023-11-01' = [for (rcg, i) in fwRuleCollections: {
  name: '${fwp.name}/${rcg.name}'
  properties: {
    priority: rcg.priority
    ruleCollections: union(
      empty(rcg.applicationRuleCollections) ? [] : [for arc in rcg.applicationRuleCollections: {
        ruleCollectionType: 'FirewallPolicyFilterRuleCollection'
        name: arc.name
        priority: arc.priority
        action: { type: arc.action }
        rules: [for r in arc.rules: {
          ruleType: 'ApplicationRule'
          name: r.name
          sourceAddresses: r.sourceAddresses
          protocols: empty(r.protocols) ? [] : [for p in r.protocols: { protocolType: p.protocolType, port: p.port }]
          fqdnTags: r.fqdnTags
          targetFqdns: r.targetFqdns
        }]
      }],
      empty(rcg.networkRuleCollections) ? [] : [for nrc in rcg.networkRuleCollections: {
        ruleCollectionType: 'FirewallPolicyFilterRuleCollection'
        name: nrc.name
        priority: nrc.priority
        action: { type: nrc.action }
        rules: [for r in nrc.rules: {
          ruleType: 'NetworkRule'
          name: r.name
          ipProtocols: r.ipProtocols
          sourceAddresses: r.sourceAddresses
          destinationAddresses: r.destinationAddresses
          destinationPorts: r.destinationPorts
        }]
      }]
    )
  }
}]

output firewallPolicyId string = fwp.id
