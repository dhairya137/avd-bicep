param location string

param tags object

param workspaceName string

param publicNetworkAccess string = 'Enabled'

param applicationGroupId string

param applicationGroupReferences array = [
  applicationGroupId
]

resource workspace 'Microsoft.DesktopVirtualization/workspaces@2024-08-08-preview' = {
  name: workspaceName
  location: location
  tags: tags
  properties: {
    description: workspaceName
    friendlyName: workspaceName
    publicNetworkAccess: publicNetworkAccess
    applicationGroupReferences: applicationGroupReferences
  }
}

output workspaceName string = workspace.name
output workspaceId string = workspace.id
