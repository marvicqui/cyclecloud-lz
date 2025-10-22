// modules/mysql.bicep
// MySQL Flexible Server: soporta modo privado (subnet delegada) u público (sin subnet).
// - Si delegatedSubnetId == ''  => publicNetworkAccess = 'Enabled' y puedes crear firewallRules.
// - Si delegatedSubnetId != ''  => publicNetworkAccess = 'Disabled' y usa la subnet delegada.

targetScope = 'resourceGroup'

param location string

@description('settings: { name, version, sku, tier, storageSizeGB, backupRetentionDays, geoRedundantBackup, administratorLogin }')
param settings object

@secure()
param adminPassword string

@description('Subnet delegada (opcional). Si vacío, se despliega público')
param delegatedSubnetId string = ''

@description('Firewall rules para modo público (opcional). Cada item: { name, startIpAddress, endIpAddress }')
param firewallRules array = []

var isPrivate = !empty(delegatedSubnetId)
var effectivePublicAccess = isPrivate ? 'Disabled' : 'Enabled'

resource mysql 'Microsoft.DBforMySQL/flexibleServers@2023-12-30' = {
  name: settings.name
  location: location
  sku: {
    name: settings.sku
    tier: settings.tier
  }
  properties: {
    version: settings.version
    administratorLogin: settings.administratorLogin
    administratorLoginPassword: adminPassword
    storage: {
      storageSizeGB: settings.storageSizeGB
      autoGrow: 'Enabled'
      iops: 600
    }
    backup: {
      backupRetentionDays: settings.backupRetentionDays
      geoRedundantBackup: settings.geoRedundantBackup
    }
    highAvailability: {
      mode: 'Disabled'
    }
    network: {
      // Si viene vacío, ARM ignora los nulls
      delegatedSubnetResourceId: isPrivate ? delegatedSubnetId : null
      publicNetworkAccess: effectivePublicAccess // 'Enabled'|'Disabled'
    }
  }
}

// Reglas de firewall sólo en modo público
resource rules 'Microsoft.DBforMySQL/flexibleServers/firewallRules@2023-12-30' = [for r in firewallRules: if (!isPrivate) {
  name: '${mysql.name}/${r.name}'
  properties: {
    startIpAddress: r.startIpAddress
    endIpAddress: r.endIpAddress
  }
}]

output fqdn string = '${mysql.name}.mysql.database.azure.com'
output serverId string = mysql.id
output publicNetworkAccess string = effectivePublicAccess
