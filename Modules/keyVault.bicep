param keyVaultName string
param location string
param tags object
param tenantId string = subscription().tenantId

@description('Object ID of the user/service principal that needs access to Key Vault')
param objectId string

@description('Additional access policies to add to the Key Vault')
param additionalAccessPolicies array = []

resource keyVault 'Microsoft.KeyVault/vaults@2023-07-01' = {
  name: keyVaultName
  location: location
  tags: tags
  properties: {
    enabledForDeployment: true
    enabledForDiskEncryption: true
    enabledForTemplateDeployment: true
    tenantId: tenantId
    accessPolicies: concat([
      {
        tenantId: tenantId
        objectId: objectId
        permissions: {
          secrets: [
            'get'
            'list'
            'set'
          ]
        }
      }
    ], additionalAccessPolicies)
    sku: {
      name: 'standard'
      family: 'A'
    }
  }
}

resource adminPasswordSecret 'Microsoft.KeyVault/vaults/secrets@2023-07-01' = {
  parent: keyVault
  name: 'vmAdminPassword'
  properties: {
    value: '123!@#ABCabc'  // You'll set this via Azure Portal or CLI
  }
}

output keyVaultName string = keyVault.name
output keyVaultId string = keyVault.id
