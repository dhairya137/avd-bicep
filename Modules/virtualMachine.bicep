param location string
@description('Name of the virtual machine.')
param vmName string = 'avd-vm'
@description('Size of the virtual machine.')
param vmSize string = 'Standard_D4s_v3'
@description('Username for the Virtual Machine.')
param adminUsername string = 'azadmin'
@description('Password for the Virtual Machine.')
@minLength(12)
@secure()
param adminPassword string = '123!@#ABCabc'
param offer string = 'windows-11'
param publisher string = 'microsoftwindowsdesktop'
param sku string = 'win11-22h2-avd'
param version string = ''
param tags object

@description('Array of user principal IDs to grant access')
param userPrincipalIds array = []
param principalType string = 'User'

@allowed([
  'Standard'
  'TrustedLaunch'
])
param securityType string = 'Standard'
param nicName string = 'nic-${vmName}'
param subnetName string 
param virtualNetworkName string 
var securityProfileJson = {
  uefiSettings: {
    secureBootEnabled: true
    vTpmEnabled: true
  }
  securityType: securityType
}

param publicIpName string = 'IP-${vmName}'
param publicIpSku string = 'Basic'
param publicIPAllocationMethod string = 'Static'
param dnsLabelPrefix string = toLower('${vmName}-${uniqueString(resourceGroup().id, vmName)}')

// Role definition IDs
var virtualMachineUserLoginRoleId = 'fb879df8-f326-4884-b1cf-06f3ad86be52' // Virtual Machine User Login
var desktopVirtualizationUserRoleId = '1d18fff3-a72a-46b5-b4a9-0b38a3cd7e63' // Desktop Virtualization User

resource publicIp 'Microsoft.Network/publicIPAddresses@2022-05-01' = {
  name: publicIpName
  location: location
  tags: tags
  sku: {
    name: publicIpSku
  }
  properties: {
    publicIPAllocationMethod: publicIPAllocationMethod
    dnsSettings: {
      domainNameLabel: dnsLabelPrefix
    }
  }
}

resource nic 'Microsoft.Network/networkInterfaces@2024-05-01' = {
  name: nicName
  location: location
  tags: tags
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          publicIPAddress: {
            id: publicIp.id
          }
          privateIPAllocationMethod: 'Dynamic'
          subnet: {
            id: resourceId('Microsoft.Network/virtualNetworks/subnets', virtualNetworkName, subnetName)
          }
        }
      }
    ]
  }
}

resource vm 'Microsoft.Compute/virtualMachines@2022-03-01' = {
  name: vmName
  location: location
  tags: tags
  properties: {
    hardwareProfile: {
      vmSize: vmSize
    }
    osProfile: {
      computerName: vmName
      adminUsername: adminUsername
      adminPassword: adminPassword
    }
    storageProfile: {
      imageReference: {
        publisher: publisher
        offer: offer
        sku: sku
        version: (empty(version) ? 'latest' : version)
      }
      osDisk: {
        createOption: 'FromImage'
        managedDisk: {
          storageAccountType: 'StandardSSD_LRS'
        }
        diskSizeGB: 128
      }
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: nic.id
        }
      ]
    }
    securityProfile: ((securityType == 'TrustedLaunch') ? securityProfileJson : null)
  }
}

param sessionHostName string
param HostPoolName string
param hostpoolToken string
param aadJoin bool = true

var dscURL = 'https://wvdportalstorageblob.blob.core.windows.net/galleryartifacts/Configuration_01-20-2022.zip'

resource sessionHostAVDAgent 'Microsoft.Compute/virtualMachines/extensions@2024-07-01' = {
  dependsOn: [
    vm
  ]
  name: '${sessionHostName}/AVDAgent'
  location: location
  tags: tags
  properties: {
    publisher: 'Microsoft.Powershell'
    type: 'DSC'
    typeHandlerVersion: '2.83'
    // autoUpgradeMinorVersion: true
    settings: {
      modulesUrl: dscURL
      configurationFunction: 'Configuration.ps1\\AddSessionHost'
      properties: {
        hostPoolName: HostPoolName
        registrationInfoToken: hostpoolToken
        aadJoin: aadJoin
      }
    }
  }
}

resource sessionHostAADLogin 'Microsoft.Compute/virtualMachines/extensions@2024-07-01' = {
  dependsOn: [
    vm
  ]
  name: '${sessionHostName}/AADLoginForWindows'
  location: location
  tags: tags
  properties: {
    publisher: 'Microsoft.Azure.ActiveDirectory'
    type: 'AADLoginForWindows'
    typeHandlerVersion: '2.2'
    autoUpgradeMinorVersion: true
  }
}

resource guestAttestation 'Microsoft.Compute/virtualMachines/extensions@2018-10-01' = {
  dependsOn: [
    vm
  ]
  name: '${sessionHostName}/GuestAttestation'
  // parent: vm
  location: location
  properties: {
    publisher: 'Microsoft.Azure.Security.WindowsAttestation'
    type: 'GuestAttestation'
    typeHandlerVersion: '1.0'
    autoUpgradeMinorVersion: true
    settings: {
      AttestationConfig: {
        MaaSettings: {
          maaEndpoint: ''
          maaTenantName: 'GuestAttestation'
        }
        AscSettings: {
          ascReportingEndpoint: ''
          ascReportingFrequency: ''
        }
        useCustomToken: 'false'
        disableAlerts: 'false'
      }
    }
  }
}

// Role assignments for Virtual Machine User Login
resource vmUserLoginRoleAssignments 'Microsoft.Authorization/roleAssignments@2022-04-01' = [for principalId in userPrincipalIds: {
  name: guid(resourceGroup().id, principalId, virtualMachineUserLoginRoleId)
  properties: {
    roleDefinitionId: resourceId('Microsoft.Authorization/roleDefinitions', virtualMachineUserLoginRoleId)
    principalId: principalId
    principalType: principalType
  }
}]

// Role assignments for Desktop Virtualization User
resource desktopVirtualizationUserRoleAssignments 'Microsoft.Authorization/roleAssignments@2022-04-01' = [for principalId in userPrincipalIds: {
  name: guid(resourceGroup().id, principalId, desktopVirtualizationUserRoleId)
  properties: {
    roleDefinitionId: resourceId('Microsoft.Authorization/roleDefinitions', desktopVirtualizationUserRoleId)
    principalId: principalId
    principalType: principalType
  }
}]
