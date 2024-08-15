param resourceToken string
param location1 string
param location2 string
param subnet1Id string
param subnet2Id string
param vnet1ID string
param vnet2ID string

param redisCache1Name string = '${resourceToken}cache1'
param redisCache2Name string = '${resourceToken}cache2'
param skuName string = 'Basic'
param skuFamily string = 'C'
param skuCapacity int = 0

// 'Azure Private DNS Zone is a service that provides DNS resolution for your virtual networks'
param privateDnsZoneName string = 'privatelink.redis.cache.windows.net'

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


// REDIS CACHE
resource redisCache1 'Microsoft.Cache/Redis@2023-08-01' = {
  name: redisCache1Name
  location: location1
  properties: {
    sku: {
      name: skuName
      family: skuFamily
      capacity: skuCapacity
    }
    enableNonSslPort: false
    minimumTlsVersion: '1.2'
  }
  dependsOn: [
    privateDnsZone
    vnetLink1
  ]
}

resource redisCache2 'Microsoft.Cache/Redis@2023-08-01' = {
  name: redisCache2Name
  location: location2 
  properties: {
    sku: {
      name: skuName
      family: skuFamily
      capacity: skuCapacity
    }
    enableNonSslPort: false
    minimumTlsVersion: '1.2' 
  }
  dependsOn: [
    privateDnsZone
    vnetLink2 
  ]
}


// Azure Private Endpoint is a network interface that connects you privately to a service 
// by Azure Private Link. Private Endpoints use a private IP address from your virtual network.
resource redisCache1PE 'Microsoft.Network/privateEndpoints@2023-11-01' = {
  name: 'pe-${redisCache1Name}'
  location: location1 
  properties: {
    privateLinkServiceConnections: [
      {
        name: 'redisCache1Link'
        properties: {
          privateLinkServiceId: redisCache1.id
          groupIds: [
            'redisCache'
          ]
          requestMessage: 'Requesting private endpoint for redisCache1 access'
        }
      }
    ]
    subnet: {
      id: subnet1Id
    }
  }
}


resource redisCache2PE 'Microsoft.Network/privateEndpoints@2023-11-01' = {
  name: 'pe-${redisCache2Name}'
  location: location2  
  properties: {
    privateLinkServiceConnections: [
      {
        name: 'redisCache2Link'
        properties: {
          privateLinkServiceId: redisCache2.id 
          groupIds: [
            'redisCache'
          ]
          requestMessage: 'Requesting private endpoint for redisCache2 access'
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
  parent: redisCache1PE
  name: 'redisCache1Group'
  properties: {
    privateDnsZoneConfigs: [
      {
        name: 'redisCache1Config'
        properties: {
          privateDnsZoneId: privateDnsZone.id 
        }
      }
    ]
  }
}

resource privateDnsZoneGroup2 'Microsoft.Network/privateEndpoints/privateDnsZoneGroups@2023-11-01' = {
  parent: redisCache2PE
  name: 'redisCache2Group'
  properties: {
    privateDnsZoneConfigs: [
      {
        name: 'redisCache2Config'
        properties: {
          privateDnsZoneId: privateDnsZone.id
        }
      }
    ]
  }
}

