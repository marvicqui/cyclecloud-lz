// modules/mysql.bicep
// VNet-integrated MySQL only. This composition has no public-network fallback.

targetScope = 'resourceGroup'

param location string

@description('settings: { name, version, sku, tier, storageSizeGB, backupRetentionDays, geoRedundantBackup, administratorLogin }')
param settings object

@secure()
param adminPassword string

@minLength(1)
param delegatedSubnetId string
@minLength(1)
param privateDnsZoneId string

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
      delegatedSubnetResourceId: delegatedSubnetId
      privateDnsZoneResourceId: privateDnsZoneId
      publicNetworkAccess: 'Disabled'
    }
  }
}

output fqdn string = mysql.properties.fullyQualifiedDomainName
output serverId string = mysql.id
output publicNetworkAccess string = 'Disabled'
