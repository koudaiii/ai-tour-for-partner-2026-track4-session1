targetScope = 'resourceGroup'

@description('The Azure region for PostgreSQL resource deployment')
param location string

@description('Tags to apply to PostgreSQL resources')
param tags object = {}

@description('Name of the PostgreSQL Flexible Server')
param postgresServerName string

@description('PostgreSQL administrator login')
param postgresAdminUser string

@description('PostgreSQL administrator password')
@secure()
param postgresAdminPassword string

@description('Application database name')
param postgresDatabaseName string

@description('PostgreSQL server version')
@allowed([
  '18'
])
param postgresVersion string = '18'

@description('PostgreSQL compute tier')
@allowed([
  'Burstable'
  'GeneralPurpose'
  'MemoryOptimized'
])
param postgresTier string = 'Burstable'

@description('PostgreSQL SKU name')
param postgresSkuName string = 'Standard_B1ms'

@description('PostgreSQL storage size in GiB')
param postgresStorageSizeGB int = 32

module postgresServer 'br/public:avm/res/db-for-postgre-sql/flexible-server:0.15.2' = {
  name: 'postgresFlexibleServerDeployment'
  params: {
    name: postgresServerName
    location: location
    tags: tags
    availabilityZone: -1
    skuName: postgresSkuName
    tier: postgresTier
    administratorLogin: postgresAdminUser
    administratorLoginPassword: postgresAdminPassword
    version: postgresVersion
    storageSizeGB: postgresStorageSizeGB
    backupRetentionDays: 7
    geoRedundantBackup: 'Disabled'
    publicNetworkAccess: 'Enabled'
    firewallRules: [
      {
        name: 'AllowAllWindowsAzureIps'
        startIpAddress: '0.0.0.0'
        endIpAddress: '0.0.0.0'
      }
    ]
    databases: [
      {
        name: postgresDatabaseName
        charset: 'UTF8'
        collation: 'en_US.utf8'
      }
    ]
  }
}

output postgresServerName string = postgresServerName
output postgresHost string = '${postgresServerName}.postgres.database.azure.com'
output postgresPort int = 5432
output postgresAdminLogin string = postgresAdminUser
output postgresDatabaseName string = postgresDatabaseName
