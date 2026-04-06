using 'main.bicep'

param nowYyyymmddHhmm = readEnvironmentVariable('NOW_YYYYMMDDHHMM', '000000000000')
param storageAccountName = 'privateisu${uniqueString('rg-private-isu-${readEnvironmentVariable('NOW_YYYYMMDDHHMM', '000000000000')}')}'
param containerName = 'images'
param postgresServerName = 'privateisu-pg-${readEnvironmentVariable('NOW_YYYYMMDDHHMM', '000000000000')}'
param postgresAdminUser = 'isuconp'
param postgresAdminPassword = readEnvironmentVariable('POSTGRES_ADMIN_PASSWORD', 'ReplaceMe_123!')
param postgresDatabaseName = 'isuconp'
param postgresVersion = '18'
param postgresTier = 'Burstable'
param postgresSkuName = 'Standard_B1ms'
param postgresStorageSizeGB = 32
param tags = {
  project: 'private-isu'
  environment: 'dev'
}
