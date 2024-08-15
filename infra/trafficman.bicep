param resourceToken string 
param location1 string
param location2 string
param lb1Id string
param lb2Id string
param trafficManagerProfileName string = '${resourceToken}trafficmanProf'


resource trafficManager 'Microsoft.Network/trafficmanagerprofiles@2022-04-01' = {
  name: trafficManagerProfileName
  location: 'global'
  properties: {
    trafficRoutingMethod: 'Geographic'
    dnsConfig: {
      relativeName: trafficManagerProfileName
      ttl: 30
    }
    monitorConfig: {
      protocol: 'HTTP'
      port: 80
      path: '/'
    }
    endpoints: [
      {
        name: '${resourceToken}endpoint1'
        type: 'Microsoft.Network/trafficManagerProfiles/AzureEndpoints'
        properties: {
          endpointStatus: 'Enabled'
          endpointLocation: location1
          targetResourceId: lb1Id
          // priority: 1
          geoMapping: [
            'NA' // North America
          ]
        }
      }
      {
        name: '${resourceToken}endpoint2'
        type: 'Microsoft.Network/trafficManagerProfiles/AzureEndpoints'
        properties: {
          endpointStatus: 'Enabled'
          endpointLocation: location2
          targetResourceId: lb2Id
          // priority: 2
          geoMapping: [
            'EU' // Europe
          ]
        }
      }
    ]
  }
}
