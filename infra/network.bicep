// GLOBAL PARAMETERS
param location1 string 
param location2 string

param networkResourceGroupName string = 'network-rg'

// VNETs
param vnet1Name string = 'vnet1'
param vnet1AddressPrefix string = '10.0.0.0/16'
param vnet2Name string = 'vnet2'
param vnet2AddressPrefix string = '10.1.0.0/16'

// SubNets in region 1
param compSubnet1Name string = 'compsubnet1'  
param compSubnet1Prefix string = '10.0.1.0/24'
param dataSubnet1Name string = 'datasubnet1'
param dataSubnet1Prefix string = '10.0.2.0/24'
param serviceBusSubnet1Name string = 'sbsubnet1'
param serviceBusSubnet1Prefix string = '10.0.3.0/24'
param inventorySubnet1Name string = 'invsubnet1'
param inventorySubnet1Prefix string = '10.0.4.0/24'
param orderSubnet1Name string = 'ordsubnet1'
param orderSubnet1Prefix string = '10.0.5.0/24'
param cacheSubnet1Name string = 'cachesubnet1'
param cacheSubnet1Prefix string = '10.0.6.0/24'

// SubNets in region 2
param compSubnet2Name string = 'compsubnet2'
param compSubnet2Prefix string = '10.1.1.0/24'
param dataSubnet2Name string = 'datasubnet2'
param dataSubnet2Prefix string = '10.1.2.0/24'
param serviceBusSubnet2Name string = 'sbsubnet2'
param serviceBusSubnet2Prefix string = '10.1.3.0/24'
param inventorySubnet2Name string = 'invsubnet2'
param inventorySubnet2Prefix string = '10.1.4.0/24'
param orderSubnet2Name string = 'ordsubnet2'
param orderSubnet2Prefix string = '10.1.5.0/24'
param cacheSubnet2Name string = 'cachesubnet2'
param cacheSubnet2Prefix string = '10.1.6.0/24'

// NAT Gateways for VM Subnets to access internet and outbound traffic

resource compSubnet1NatPublicIP 'Microsoft.Network/publicIPAddresses@2023-09-01' = {
  name: 'compSubnet1NatPublicIP'
  location: location1 
  sku: {
    name: 'Standard'
  }
  properties: {
    publicIPAddressVersion: 'IPv4'
    publicIPAllocationMethod: 'Static'
  }
}

resource compSubnet1NatGateway 'Microsoft.Network/natGateways@2023-09-01' = {
  name: 'compSubnet1NatGateway'
  location: location1 
  sku: {
    name: 'Standard'
  }
  properties: {
    idleTimeoutInMinutes: 4
    publicIpAddresses: [
      {
        id: compSubnet1NatPublicIP.id
      }
    ]
  }
}


resource compSubnet2NatPublicIP 'Microsoft.Network/publicIPAddresses@2023-09-01' = {
  name: 'compSubnet2NatPublicIP'
  location: location2  
  sku: {
    name: 'Standard'
  }
  properties: {
    publicIPAddressVersion: 'IPv4'
    publicIPAllocationMethod: 'Static'
  }
}

resource compSubnet2NatGateway 'Microsoft.Network/natGateways@2023-09-01' = {
  name: 'compSubnet2NatGateway'
  location: location2  
  sku: {
    name: 'Standard'
  }
  properties: {
    idleTimeoutInMinutes: 4
    publicIpAddresses: [
      {
        id: compSubnet2NatPublicIP.id
      }
    ]
  }
}


// VNETs
resource vnet1 'Microsoft.Network/virtualNetworks@2023-11-01' = {
  name: vnet1Name
  location: location1
  properties: {
    addressSpace: {
      addressPrefixes: [
        vnet1AddressPrefix
      ]
    }
    subnets: [
      {name: compSubnet1Name, properties: { addressPrefix: compSubnet1Prefix, natGateway: {id: compSubnet1NatGateway.id}}}
      {name: dataSubnet1Name, properties: {addressPrefix: dataSubnet1Prefix, delegations: [{name: 'MySQL1Delegation', properties: {serviceName: 'Microsoft.DBforMySQL/flexibleServers'}}]}}
      {name: serviceBusSubnet1Name, properties: {addressPrefix: serviceBusSubnet1Prefix}}
      {name: inventorySubnet1Name, properties: {addressPrefix: inventorySubnet1Prefix}}
      {name: orderSubnet1Name, properties: {addressPrefix: orderSubnet1Prefix}}
      {name: cacheSubnet1Name, properties: {addressPrefix: cacheSubnet1Prefix}}
    ]
  }
}

resource vnet2 'Microsoft.Network/virtualNetworks@2023-11-01' = {
  name: vnet2Name
  location: location2
  properties: {
    addressSpace: {
      addressPrefixes: [
        vnet2AddressPrefix
      ]
    }
    subnets: [
      {name: compSubnet2Name, properties: { addressPrefix: compSubnet2Prefix, natGateway: {id: compSubnet2NatGateway.id}}}
      {name: dataSubnet2Name, properties: {addressPrefix: dataSubnet2Prefix, delegations: [{name: 'MySQL2Delegation', properties: {serviceName: 'Microsoft.DBforMySQL/flexibleServers'}}]}}
      {name: serviceBusSubnet2Name, properties: {addressPrefix: serviceBusSubnet2Prefix}}
      {name: inventorySubnet2Name, properties: {addressPrefix: inventorySubnet2Prefix}}
      {name: orderSubnet2Name, properties: {addressPrefix: orderSubnet2Prefix}}
      {name: cacheSubnet2Name, properties: {addressPrefix: cacheSubnet2Prefix}}
    ]
  }
}

// Azure Virtual Network Peering is a feature in Azure that allows you to connect two or more 
// virtual networks (VNets) to enable seamless and secure communication between them.
resource vnet1ToVnet2Peering 'Microsoft.Network/virtualNetworks/virtualNetworkPeerings@2023-11-01' = {
  name: 'vnet1ToVnet2'
  parent: vnet1
  properties: {
    remoteVirtualNetwork: {
      id: vnet2.id
    }
    allowVirtualNetworkAccess: true
    allowForwardedTraffic: false
    allowGatewayTransit: false
    useRemoteGateways: false
  }
}

resource vnet2ToVnet1Peering 'Microsoft.Network/virtualNetworks/virtualNetworkPeerings@2023-11-01' = {
  name: 'vnet2ToVnet1'
  parent: vnet2
  properties: {
    remoteVirtualNetwork: {
      id: vnet1.id
    }
    allowVirtualNetworkAccess: true
    allowForwardedTraffic: false
    allowGatewayTransit: false
    useRemoteGateways: false
  }
}


output vnet1ID string = vnet1.id
output vnet2ID string = vnet2.id 

output compSubnet1Id string = resourceId(networkResourceGroupName, 'Microsoft.Network/virtualNetworks/subnets', vnet1Name, compSubnet1Name)
output compSubnet2Id string = resourceId(networkResourceGroupName, 'Microsoft.Network/virtualNetworks/subnets', vnet2Name, compSubnet2Name)

output dataSubnet1Id string = resourceId(networkResourceGroupName, 'Microsoft.Network/virtualNetworks/subnets', vnet1Name, dataSubnet1Name)
output dataSubnet2Id string = resourceId(networkResourceGroupName, 'Microsoft.Network/virtualNetworks/subnets', vnet2Name, dataSubnet2Name)

output cacheSubnet1Id string = resourceId(networkResourceGroupName, 'Microsoft.Network/virtualNetworks/subnets', vnet1Name, cacheSubnet1Name)
output cacheSubnet2Id string = resourceId(networkResourceGroupName, 'Microsoft.Network/virtualNetworks/subnets', vnet2Name, cacheSubnet2Name)

output serviceBusSubnet1Id string = resourceId(networkResourceGroupName, 'Microsoft.Network/virtualNetworks/subnets', vnet1Name, serviceBusSubnet1Name)
output serviceBusSubnet2Id string = resourceId(networkResourceGroupName, 'Microsoft.Network/virtualNetworks/subnets', vnet2Name, serviceBusSubnet2Name)
