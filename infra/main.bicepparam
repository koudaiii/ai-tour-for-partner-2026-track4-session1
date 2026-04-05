using 'main.bicep'

param nowYyyymmddHhmm = readEnvironmentVariable('NOW_YYYYMMDDHHMM', '000000000000')
param storageAccountName = 'privateisu${uniqueString('rg-private-isu-${readEnvironmentVariable('NOW_YYYYMMDDHHMM', '000000000000')}')}'
param containerName = 'images'
param tags = {
  project: 'private-isu'
  environment: 'dev'
}
