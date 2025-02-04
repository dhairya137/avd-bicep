param principalId string
param principalType string = 'User'

// Role definition IDs
var virtualMachineUserLoginRoleId = 'fb879df8-f326-4884-b1cf-06f3ad86be52' // Virtual Machine User Login
var desktopVirtualizationUserRoleId = '1d18fff3-a72a-46b5-b4a9-0b38a3cd7e63' // Desktop Virtualization User

// Role assignment for Virtual Machine User Login
resource vmUserLoginRoleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(resourceGroup().id, principalId, virtualMachineUserLoginRoleId)
  properties: {
    roleDefinitionId: resourceId('Microsoft.Authorization/roleDefinitions', virtualMachineUserLoginRoleId)
    principalId: principalId
    principalType: principalType
  }
}

// Role assignment for Desktop Virtualization User
resource desktopVirtualizationUserRoleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(resourceGroup().id, principalId, desktopVirtualizationUserRoleId)
  properties: {
    roleDefinitionId: resourceId('Microsoft.Authorization/roleDefinitions', desktopVirtualizationUserRoleId)
    principalId: principalId
    principalType: principalType
  }
}
