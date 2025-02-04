param location string
param tags object 
param applicationGroupName string
param hostpoolId string 
param applicationGroupType string = 'Desktop'
var sessionDesktop = 'sessionDesktop'

resource applicationGroup 'Microsoft.DesktopVirtualization/applicationGroups@2024-08-08-preview' = {
 name: applicationGroupName
 location: location
 tags: tags
 properties: {
  friendlyName: sessionDesktop
  hostPoolArmPath: hostpoolId
  applicationGroupType: applicationGroupType
 }
}

output applicationGroupName string = applicationGroup.name
output applicationGroupId string = applicationGroup.id
