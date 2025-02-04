param location string
param resourceGroupName string
param tags object

targetScope = 'subscription' 

resource RG 'Microsoft.Resources/resourceGroups@2024-11-01' = {
  name: resourceGroupName
  location: location
  tags: tags
  properties: {}
}

output resourceGroupName string = RG.name
output resourceGroupId string = RG.id
