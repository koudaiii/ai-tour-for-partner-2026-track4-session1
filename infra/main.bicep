////////////
// Metadata
////////////
targetScope = 'subscription'

metadata description = 'Deploy Azure Storage Account + Azure Database for PostgreSQL Flexible Server for private-isu'

////////////
// Parameters
////////////
@description('The Azure region for resource deployment')
param location string = 'japaneast'

@description('Date suffix for resource group name (YYYYMMDDHHmm format)')
param nowYyyymmddHhmm string

@description('Name of the Storage Account (must be globally unique, 3-24 lowercase alphanumeric)')
@minLength(3)
@maxLength(24)
param storageAccountName string

@description('Name of the blob container for storing images')
param containerName string = 'images'

@description('Name of the PostgreSQL Flexible Server (3-63 lowercase alphanumeric or hyphen)')
@minLength(3)
@maxLength(63)
param postgresServerName string

@description('PostgreSQL administrator login')
param postgresAdminUser string = 'isuconp'

@description('PostgreSQL administrator password')
@secure()
param postgresAdminPassword string

@description('Application database name in PostgreSQL')
param postgresDatabaseName string = 'isuconp'

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

@description('Tags to apply to all resources')
param tags object = {}

////////////
// Variables
////////////
var resourceGroupName = 'rg-private-isu-${nowYyyymmddHhmm}'

////////////
// Resources / Modules
////////////
resource rg 'Microsoft.Resources/resourceGroups@2024-03-01' = {
  name: resourceGroupName
  location: location
  tags: tags
}

module storageAccount 'br/public:avm/res/storage/storage-account:0.32.0' = {
  name: 'storageAccountDeployment'
  scope: rg
  params: {
    name: storageAccountName
    location: location
    tags: tags
    kind: 'StorageV2'
    skuName: 'Standard_LRS'
    accessTier: 'Hot'
    allowBlobPublicAccess: true
    minimumTlsVersion: 'TLS1_2'
    supportsHttpsTrafficOnly: true
    blobServices: {
      containers: [
        {
          name: containerName
          publicAccess: 'Blob'
        }
      ]
    }
  }
}

module postgres 'postgresql.bicep' = {
  name: 'postgresDeployment'
  scope: rg
  params: {
    location: location
    tags: tags
    postgresServerName: postgresServerName
    postgresAdminUser: postgresAdminUser
    postgresAdminPassword: postgresAdminPassword
    postgresDatabaseName: postgresDatabaseName
    postgresVersion: postgresVersion
    postgresTier: postgresTier
    postgresSkuName: postgresSkuName
    postgresStorageSizeGB: postgresStorageSizeGB
  }
}

////////////
// Outputs
////////////
@description('The resource group name')
output resourceGroupName string = rg.name

@description('The primary blob endpoint URL')
output blobEndpoint string = storageAccount.outputs.primaryBlobEndpoint

@description('The full container URL for image access')
output containerUrl string = '${storageAccount.outputs.primaryBlobEndpoint}${containerName}'

@description('The Storage Account name')
output storageAccountName string = storageAccount.outputs.name

@description('The Storage Account resource ID')
output storageAccountId string = storageAccount.outputs.resourceId

@description('PostgreSQL flexible server name')
output postgresServerName string = postgres.outputs.postgresServerName

@description('PostgreSQL flexible server host FQDN')
output postgresHost string = postgres.outputs.postgresHost

@description('PostgreSQL port')
output postgresPort int = postgres.outputs.postgresPort

@description('PostgreSQL admin login')
output postgresAdminLogin string = postgres.outputs.postgresAdminLogin

@description('PostgreSQL database name')
output postgresDatabaseName string = postgres.outputs.postgresDatabaseName
