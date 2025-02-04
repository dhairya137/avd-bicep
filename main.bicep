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
param adminPassword string = '123!@#ABCabc'
param OSVersion string = 'win11-22h2-avd'
param vmSize string = 'Standard_B1ms'
param vmName string = 'vm-avd-001'
param securityType string = 'Standard'

param userEmails array = []

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

module vm 'Modules/virtualMachine.bicep' = {
  name: '${vmName}-${date}'
  scope: resourceGroup(resourceGroupName)
  dependsOn: [
    RG
    virtualNetwork
    workspace
  ]
  params: {
    location: location
    tags: tags
    adminUsername: adminUsername
    adminPassword: adminPassword
    sku: OSVersion
    securityType: securityType
    aadJoin: true
    hostpoolToken: hostpool.outputs.registrationInfoToken
    HostPoolName: hostpool.name
    sessionHostName: vmName
    vmName: vmName
    vmSize: vmSize
    virtualNetworkName: virtualNetworkName
    subnetName: subnets[0].name
    userEmails: userEmails
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
