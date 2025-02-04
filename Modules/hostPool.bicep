param location string
param hostPoolName string = 'avd-vnet'
param tags object

param customRdpProperty string = '''drivestoredirect:s:*;audiomode:i:0;videoplaybackmode:i:1;redirectclipboard:i:1;redirectprinters:i:1;devicestoredirect:s:*;redirectcomports:i:1;
redirectsmartcards:i:1;usbdevicestoredirect:s:*;enablecredsspsupport:i:1;redirectwebauthn:i:1;use multimon:i:1;targetisaadjoined:i:1'''

param hostPoolType string = 'Pooled'
param maxSessionLimit int = 5
param loadBalancerType string = 'DepthFirst'
param baseTime string = utcNow('u')
var add1Days = dateTimeAdd(baseTime, 'P1D')
param validationEnvironment bool = true

resource hostpool 'Microsoft.DesktopVirtualization/hostPools@2024-08-08-preview' = {
  name: hostPoolName
  location: location
  tags: tags
  properties: {
    hostPoolType: hostPoolType
    maxSessionLimit: maxSessionLimit
    preferredAppGroupType: 'Desktop'
    loadBalancerType: loadBalancerType
    registrationInfo: {
      expirationTime: add1Days
      registrationTokenOperation: 'Update'
    }
    customRdpProperty: customRdpProperty
    validationEnvironment: validationEnvironment
  }
}

// resource keyVault 'Microsoft.KeyVault/vaults@2024-04-01-preview' = {
//   name: 'kv-${hostPoolName}'
//   location: location
//   properties: {
//     enabledForDeployment: enabledForDeployment
//     enabledForDiskEncryption: enabledForDiskEncryption
//     enabledForTemplateDeployment: enabledForTemplateDeployment
//     tenantId: tenantId
//     enableSoftDelete: true
//     softDeleteRetentionInDays: 90
//     accessPolicies: [
//       {
//         objectId: objectId
//         tenantId: tenantId
//         permissions: {
//           keys: keysPermissions
//           secrets: secretsPermissions
//         }
//       }
//     ]
//     sku: {
//       name: skuName
//       family: 'A'
//     }
//     networkAcls: {
//       defaultAction: 'Allow'
//       bypass: 'AzureServices'
//     }
//   }
// }

// resource secret 'Microsoft.KeyVault/vaults/secrets@2023-07-01' = {
//   parent: keyVault
//   name: secretName
//   properties: {
//     value: first(hostpool.listRegistrationTokens().value).token
//   }
// }


output hostpoolId string = hostpool.id
output hostpoolName string = hostpool.name
output registrationInfoToken string = hostpool.listRegistrationTokens().value[0].token
