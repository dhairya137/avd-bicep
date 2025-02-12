targetScope = 'subscription'

param tags object = {
  'Created By': 'Bicep'
}

param date string = utcNow()
param location string = 'centralindia'
param resourceGroupName string = 'rg-avd'

//hostpool Params
param hostPoolName string = 'hp-avd'

// applicationGroup Params
param applicationGroupName string = 'ag-avd'

//Workspace Params 
param workspaceName string = 'ws-avd'

// Virtual Network Parameters
param virtualNetworkName string = 'vnet-avd'
param vnetCIDR string = '10.0.0.0/16'
param subnets array = [
  {
    name: 'subnet1'
    addressPrefix: '10.0.0.0/24'
  }
  {
    name: 'subnet2'
    addressPrefix: '10.0.1.0/24'
  }
]

// Virtual Machine params
param adminUsername string = 'azadmin'
@description('Object ID of the user/service principal that needs access to Key Vault')
param keyVaultObjectId string
param keyVaultName string = 'kv-${resourceGroupName}'
param OSVersion string = 'win11-22h2-avd'
param vmSize string = 'Standard_B1ms'
param vmName string = 'vm-avd-001'
param securityType string = 'Standard'

param userPrincipalIds array = []

module RG 'Modules/resourceGroup.bicep' = {
  name: '${resourceGroupName}-${date}'
  params: {
    location: location
    tags: tags
    resourceGroupName: resourceGroupName
  }
}

module virtualNetwork 'Modules/virtualNetwork.bicep' = {
  dependsOn: [
    RG
  ]
  name: '${virtualNetworkName}-${date}'
  scope: resourceGroup(resourceGroupName)
  params: {
    tags: tags
    virtualNetworkName: virtualNetworkName
    subnets: subnets
    virtualNetworkCIDR: vnetCIDR
    location: location
  }
}

module hostpool 'Modules/hostPool.bicep' = {
  dependsOn: [
    RG
  ]
  name: '${hostPoolName}-${date}'
  scope: resourceGroup(resourceGroupName)
  params: {
    hostPoolName: hostPoolName
    location: location
    tags: tags
  }
}

module applicationGroup 'Modules/applicationGroup.bicep' = {
  name: '${applicationGroupName}-${date}'
  scope: resourceGroup(resourceGroupName)
  params: {
    location: location
    tags: tags
    applicationGroupName: applicationGroupName
    hostpoolId: hostpool.outputs.hostpoolId
  }
}

module workspace 'Modules/workspace.bicep' = {
  name: '${workspaceName}-${date}'
  scope: resourceGroup(resourceGroupName)
  params: {
    location: location
    tags: tags
    workspaceName: workspaceName
    applicationGroupId: applicationGroup.outputs.applicationGroupId
  }
}

module keyVault 'Modules/keyVault.bicep' = {
  name: '${keyVaultName}-${date}'
  scope: resourceGroup(resourceGroupName)
  dependsOn: [
    RG
  ]
  params: {
    keyVaultName: keyVaultName
    location: location
    tags: tags
    objectId: keyVaultObjectId
  }
}

module vm 'Modules/virtualMachine.bicep' = {
  name: '${vmName}-${date}'
  scope: resourceGroup(resourceGroupName)
  dependsOn: [
    RG
    virtualNetwork
    keyVault
  ]
  params: {
    location: location
    tags: tags
    adminUsername: adminUsername
    keyVaultName: keyVaultName
    sku: OSVersion
    securityType: securityType
    aadJoin: true
    hostpoolToken: hostpool.outputs.registrationInfoToken
    HostPoolName: hostpool.outputs.hostpoolName
    sessionHostName: vmName
    vmName: vmName
    vmSize: vmSize
    virtualNetworkName: virtualNetworkName
    subnetName: subnets[0].name
    userPrincipalIds: userPrincipalIds
  }
}

module keyVaultAccessPolicy 'Modules/keyVaultAccessPolicy.bicep' = {
  name: '${keyVaultName}-access-policy-${date}'
  scope: resourceGroup(resourceGroupName)
  dependsOn: [
    vm
  ]
  params: {
    keyVaultName: keyVaultName
    vmPrincipalId: reference(resourceId(subscription().subscriptionId, resourceGroupName, 'Microsoft.Compute/virtualMachines', vmName), '2024-07-01', 'Full').identity.principalId
  }
}
