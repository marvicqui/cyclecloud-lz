// modules/network.bicep
// VNet + Subnets + NSGs + Delegación en la subnet indicada

targetScope = 'resourceGroup'

param location string
param vnetAddressPrefixes array
@description('Map: subnetName -> prefix')
param subnets object
@description('Nombre de la subnet a delegar para MySQL Flexible Server')
param mysqlSubnetName string = 'CycleCloudSubnet'

var subnetItems = items(subnets)

resource nsgs 'Microsoft.Network/networkSecurityGroups@2023-11-01' = [for (sn, i) in subnetItems: {
  name: 'nsg-${sn.key}'
  location: location
}]

resource vnet 'Microsoft.Network/virtualNetworks@2023-11-01' = {
  name: 'vnet-lz'
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: vnetAddressPrefixes
    }
    subnets: [for (sn, i) in subnetItems: {
      name: sn.key
      properties: {
        addressPrefix: string(sn.value)
        networkSecurityGroup: {
          id: nsgs[i].id
        }
        delegations: sn.key == mysqlSubnetName ? [
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

output vnetId string = vnet.id
output mysqlSubnetId string = resourceId('Microsoft.Network/virtualNetworks/subnets', vnet.name, mysqlSubnetName)
