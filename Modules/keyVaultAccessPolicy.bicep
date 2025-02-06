param keyVaultName string
param tenantId string = subscription().tenantId
param vmPrincipalId string

resource keyVaultAccessPolicy 'Microsoft.KeyVault/vaults/accessPolicies@2023-07-01' = {
  name: '${keyVaultName}/add'
  properties: {
    accessPolicies: [
      {
        tenantId: tenantId
        objectId: vmPrincipalId
        permissions: {
          secrets: [
            'get'
          ]
        }
      }
    ]
  }
}
