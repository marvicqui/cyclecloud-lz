// modules/network.bicep
// VNet + Subnets + NSGs + Delegación para MySQL Flexible Server

targetScope = 'resourceGroup'

param location string
param vnetAddressPrefixes array
@description('Map: subnetName -> prefix')
param subnets object

resource nsgs 'Microsoft.Network/networkSecurityGroups@2023-11-01' = [for subnetName in union([], keys(subnets)): {
  name: 'nsg-${subnetName}'
  location: location
}]

resource vnet 'Microsoft.Network/virtualNetworks@2023-11-01' = {
  name: 'vnet-lz'
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: vnetAddressPrefixes
    }
    subnets: [for subnetName in union([], keys(subnets)): {
      name: subnetName
      properties: {
        addressPrefix: subnets[subnetName]
        networkSecurityGroup: {
          id: nsgs[arrayIndex(keys(subnets), subnetName)].id
        }
        // Delegación específica para MySQL
        delegations: contains(keys(subnets), 'snet-mysql') && subnetName == 'snet-mysql' ? [
          {
            name: 'dlg-mysql'
            properties: {
              serviceName: 'Microsoft.DBforMySQL/flexibleServers'
            }
          }
        ] : []
      }
    }]
  }
}

var mysqlSubnet = contains(keys(subnets), 'snet-mysql') ? last(vnet.properties.subnets[? name == 'snet-mysql']) : null

output vnetId string = vnet.id
output mysqlSubnetId string = mysqlSubnet == null ? '' : resourceId('Microsoft.Network/virtualNetworks/subnets', vnet.name, 'snet-mysql')
