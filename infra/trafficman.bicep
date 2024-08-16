param resourceToken string 
param location1 string
param location2 string
param lb1IP string
param lb2IP string
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
        type: 'Microsoft.Network/trafficManagerProfiles/ExternalEndpoints'
        properties: {
          endpointStatus: 'Enabled'
          endpointLocation: location1
          target: lb1IP
          // priority: 1
          geoMapping: [
            'GEO-NA' // North America
          ]
        }
      }
      {
        name: '${resourceToken}endpoint2'
        type: 'Microsoft.Network/trafficManagerProfiles/ExternalEndpoints'
        properties: {
          endpointStatus: 'Enabled'
          endpointLocation: location2
          target: lb2IP
          // priority: 2
          geoMapping: [
            'GEO-EU' // Europe
          ]
        }
      }
    ]
  }
}
