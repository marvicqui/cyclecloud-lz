// modules/mysql.bicep
// MySQL Flexible Server con acceso privado (subnet delegada) y parámetros básicos

targetScope = 'resourceGroup'

param location string
@description('Objeto de settings: { name, version, sku, tier, storageSizeGB, backupRetentionDays, geoRedundantBackup, administratorLogin }')
param settings object
@secure()
param adminPassword string
@description('Subnet delegada para MySQL Flexible Server')
param delegatedSubnetId string

resource mysql 'Microsoft.DBforMySQL/flexibleServers@2023-12-30' = {
  name: settings.name
  location: location
  sku: { name: settings.sku, tier: settings.tier, capacity: 2 }
  properties: {
    version: settings.version
    administratorLogin: settings.administratorLogin
    administratorLoginPassword: adminPassword
    storage: { storageSizeGB: settings.storageSizeGB, autoGrow: 'Enabled', iops: 600 }
    backup: { backupRetentionDays: settings.backupRetentionDays, geoRedundantBackup: settings.geoRedundantBackup }
    highAvailability: { mode: 'Disabled' }
    network: {
      delegatedSubnetResourceId: delegatedSubnetId
      privateDnsZoneArguments: { privateDnsZoneName: '${settings.name}.mysql.database.azure.com' }
    }
    authConfig: { activeDirectoryAuth: 'Enabled', passwordAuth: 'Enabled' }
  }
}

output fqdn string = '${mysql.name}.mysql.database.azure.com'
output serverId string = mysql.id
