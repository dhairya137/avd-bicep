param location string
param virtualNetworkName string = 'avd-vnet'
param tags object

param virtualNetworkCIDR string = '10.0.0.0/16'
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

resource virtualNetwork 'Microsoft.Network/virtualNetworks@2024-05-01' = {
  name: virtualNetworkName
  location: location
  tags: tags
  properties: {
    addressSpace: {
      addressPrefixes: [
        virtualNetworkCIDR
      ]
    }
    subnets: [
      for subnet in subnets: {
        name: subnet.name
        properties: {
          addressPrefix: subnet.?addressPrefix
          addressPrefixes: subnet.?addressPrefixes
          networkSecurityGroup: subnet.?nsg
          routeTable: subnet.?routeTable
        }
      }
    ]
  }
}

output virtualNetworkId string = virtualNetwork.id
output virtualNetworkName string = virtualNetwork.name
