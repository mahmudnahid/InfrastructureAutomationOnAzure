param resourceToken string
param location1 string
param location2 string
param subnet1Id string
param subnet2Id string
param vnet1ID string
param vnet2ID string

param serviceBus1NamespaceName string = '${resourceToken}sbnamespace1'
param serviceBus2NamespaceName string = '${resourceToken}sbnamespace2'

param serviceBus1QueueName string = '${resourceToken}sbqueue1'
param serviceBus2QueueName string = '${resourceToken}sbqueue2'


// 'Azure Private DNS Zone is a service that provides DNS resolution for your virtual networks'
param privateDnsZoneName string = 'privatelink.servicebus.windows.net'

resource privateDnsZone 'Microsoft.Network/privateDnsZones@2020-06-01' = {
  name: privateDnsZoneName
  location: 'global'
}

// Azure Virtual Network Link is a configuration that associates a virtual network (VNet) 
// with a private DNS zone in Azure. 
resource vnetLink1 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2020-06-01' = {
  parent: privateDnsZone
  name: '${privateDnsZoneName}-vnet1-link'
  location: 'global'
  properties: {
    registrationEnabled: false 
    virtualNetwork: {
      id: vnet1ID
    }
  }
}

resource vnetLink2 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2020-06-01' = {
  parent: privateDnsZone
  name: '${privateDnsZoneName}-vnet2-link'
  location: 'global'
  properties: {
    registrationEnabled: false 
    virtualNetwork: {
      id: vnet2ID
    }
  }
}

// SERVICE BUS
resource serviceBusNamespace1 'Microsoft.ServiceBus/namespaces@2023-01-01-preview' = {
  name: serviceBus1NamespaceName
  location: location1 
  sku: {
    name: 'Premium'
    tier: 'Premium'
  }
  dependsOn: [
    privateDnsZone
    vnetLink1
  ]
}

resource serviceBus1Queue 'Microsoft.ServiceBus/namespaces/queues@2023-01-01-preview' = {
  parent: serviceBusNamespace1
  name: serviceBus1QueueName
  properties: {
    lockDuration: 'PT5M'
    maxSizeInMegabytes: 1024
    requiresDuplicateDetection: false
    requiresSession: false
    defaultMessageTimeToLive: 'P10675199DT2H48M5.4775807S'
    deadLetteringOnMessageExpiration: false
    duplicateDetectionHistoryTimeWindow: 'PT10M'
    maxDeliveryCount: 10
    autoDeleteOnIdle: 'P10675199DT2H48M5.4775807S'
    enablePartitioning: false
    enableExpress: false
  }
}

resource sb1NamespaceAuthorizationRule 'Microsoft.ServiceBus/namespaces/authorizationRules@2023-01-01-preview' = {
  parent: serviceBusNamespace1
  name: 'RootManageSharedAccessKey'
  properties: {
    rights: [
      'Listen'
      'Send'
      'Manage'
    ]
  }
}




resource serviceBusNamespace2 'Microsoft.ServiceBus/namespaces@2023-01-01-preview' = {
  name: serviceBus2NamespaceName
  location: location2  
  sku: {
    name: 'Premium'
    tier: 'Premium'
  }
  dependsOn: [
    privateDnsZone
    vnetLink2 
  ]
}

resource serviceBus2Queue 'Microsoft.ServiceBus/namespaces/queues@2023-01-01-preview' = {
  parent: serviceBusNamespace2 
  name: serviceBus2QueueName
  properties: {
    lockDuration: 'PT5M'
    maxSizeInMegabytes: 1024
    requiresDuplicateDetection: false
    requiresSession: false
    defaultMessageTimeToLive: 'P10675199DT2H48M5.4775807S'
    deadLetteringOnMessageExpiration: false
    duplicateDetectionHistoryTimeWindow: 'PT10M'
    maxDeliveryCount: 10
    autoDeleteOnIdle: 'P10675199DT2H48M5.4775807S'
    enablePartitioning: false
    enableExpress: false
  }
}

resource sb2NamespaceAuthorizationRule 'Microsoft.ServiceBus/namespaces/authorizationRules@2023-01-01-preview' = {
  parent: serviceBusNamespace2 
  name: 'RootManageSharedAccessKey'
  properties: {
    rights: [
      'Listen'
      'Send'
      'Manage'
    ]
  }
}


// Azure Private Endpoint is a network interface that connects you privately to a service 
// by Azure Private Link. Private Endpoints use a private IP address from your virtual network.
resource serviceBus1PE 'Microsoft.Network/privateEndpoints@2023-11-01' = {
  name: 'pe-${serviceBus1NamespaceName}'
  location: location1 
  properties: {
    privateLinkServiceConnections: [
      {
        name: 'serviceBus1Link'
        properties: {
          privateLinkServiceId: serviceBusNamespace1.id
          groupIds: [
            'namespace'
          ]
          requestMessage: 'Requesting private endpoint for serviceBus1 access'
        }
      }
    ]
    subnet: {
      id: subnet1Id
    }
  }
}

resource serviceBus2PE 'Microsoft.Network/privateEndpoints@2023-11-01' = {
  name: 'pe-${serviceBus2NamespaceName}'
  location: location2  
  properties: {
    privateLinkServiceConnections: [
      {
        name: 'serviceBus2Link'
        properties: {
          privateLinkServiceId: serviceBusNamespace2.id 
          groupIds: [
            'namespace'
          ]
          requestMessage: 'Requesting private endpoint for serviceBus2 access'
        }
      }
    ]
    subnet: {
      id: subnet2Id
    }
  }
}



// Azure Private DNS Zone Group is a feature that helps the association of private DNS zones 
// with private endpoints
resource privateDnsZoneGroup1 'Microsoft.Network/privateEndpoints/privateDnsZoneGroups@2023-11-01' = {
  parent: serviceBus1PE
  name: 'serviceBus1Group'
  properties: {
    privateDnsZoneConfigs: [
      {
        name: 'serviceBus1Config'
        properties: {
          privateDnsZoneId: privateDnsZone.id 
        }
      }
    ]
  }
}

resource privateDnsZoneGroup2 'Microsoft.Network/privateEndpoints/privateDnsZoneGroups@2023-11-01' = {
  parent: serviceBus2PE
  name: 'serviceBus2Group'
  properties: {
    privateDnsZoneConfigs: [
      {
        name: 'serviceBus2Config'
        properties: {
          privateDnsZoneId: privateDnsZone.id 
        }
      }
    ]
  }
}



output sb1ConnectionStr string = listKeys(sb1NamespaceAuthorizationRule.id, '2023-01-01-preview').primaryConnectionString
output sb1QueueName string = serviceBus1Queue.name

output sb2ConnectionStr string = listKeys(sb2NamespaceAuthorizationRule.id, '2023-01-01-preview').primaryConnectionString
output sb2QueueName string = serviceBus2Queue.name

