targetScope = 'subscription'

param location1 string = 'canadacentral'
param location2 string = 'canadaeast'
param networkResourceGroupName string = 'network-rg'
param storageResourceGroupName string = 'storage-rg'
param cacheResourceGroupName string = 'cache-rg'
param dbResourceGroupName string = 'db-rg'
param vmResourceGroupName string = 'vm-rg'
param serviceBusResourceGroupName string = 'sb-rg'
param trafficmanagerResourceGroupName string = 'tm-rg'

param resourceToken string = 'myproject${substring(uniqueString('resourceTokens'), 0, 4)}'

// DATABASE username & password
@secure()
param administratorLogin string
@secure()
param administratorLoginPassword string


// Virtual machine username & password
@secure()
param adminUsername string 
@secure()
param adminPassword string



module network 'network.bicep' = {
  name: 'NetworkModule'
  scope: resourceGroup(networkResourceGroupName)
  params: {
    location1: location1
    location2: location2
  }
}

module storage 'storage.bicep' = {
  name: 'StorageModule'
  scope: resourceGroup(storageResourceGroupName)
  params: {
    resourceToken: resourceToken
    location: location1
    subnetId: network.outputs.compSubnet1Id
    vnet1ID: network.outputs.vnet1ID
    vnet2ID: network.outputs.vnet2ID
  }
  dependsOn: [
    network
  ]
}

module cache 'cache.bicep' = {
  name: 'CacheModule'
  scope: resourceGroup(cacheResourceGroupName)
  params: {
    resourceToken: resourceToken
    location1: location1
    location2: location2 
    subnet1Id: network.outputs.cacheSubnet1Id
    subnet2Id: network.outputs.cacheSubnet2Id
    vnet1ID: network.outputs.vnet1ID
    vnet2ID: network.outputs.vnet2ID
  }
  dependsOn: [
    network
  ]
}

module database 'database.bicep' = {
  name: 'DataBaseModule'
  scope: resourceGroup(dbResourceGroupName)
  params: {
    resourceToken: resourceToken
    administratorLogin: administratorLogin
    administratorLoginPassword: administratorLoginPassword
    location1: location1
    location2: location2 
    subnet1Id: network.outputs.dataSubnet1Id
    subnet2Id: network.outputs.dataSubnet2Id
    vnet1ID: network.outputs.vnet1ID
    vnet2ID: network.outputs.vnet2ID
  }
  dependsOn: [
    network
  ]
}

module servicebus 'servicebus.bicep' = {
  name: 'ServiceBusModule'
  scope: resourceGroup(serviceBusResourceGroupName)
  params: {
    resourceToken: resourceToken
    location1: location1
    location2: location2 
    subnet1Id: network.outputs.serviceBusSubnet1Id
    subnet2Id: network.outputs.serviceBusSubnet2Id
    vnet1ID: network.outputs.vnet1ID
    vnet2ID: network.outputs.vnet2ID
  }
  dependsOn: [
    network
  ]
}

module virtualmachine 'virtualmachine.bicep' = {
  name: 'VirtualMachineModule'
  scope: resourceGroup(vmResourceGroupName)
  params: {
    location1: location1
    location2: location2 
    subnet1Id: network.outputs.compSubnet1Id
    subnet2Id: network.outputs.compSubnet2Id
    MYSQL_HOST: database.outputs.MYSQL_HOST
    MYSQL_DB_NAME: database.outputs.MYSQL_DB_NAME
    administratorLogin: administratorLogin
    administratorLoginPassword: administratorLoginPassword
    storageAccountName: storage.outputs.AZ_ACCOUNT_NAME
    AZ_ACCOUNT_KEY: storage.outputs.AZ_ACCOUNT_KEY
    AZURE_SERVICE_BUS_CONNECTION_STRING: servicebus.outputs.sb1ConnectionStr
    AZURE_SERVICE_BUS_QUEUE_NAME: servicebus.outputs.sb1QueueName
    adminUsername: adminUsername
    adminPassword: adminPassword
  }
  dependsOn: [
    network
    storage
    cache
    database
    servicebus
  ]
}

module trafficmanager 'trafficman.bicep' = {
  name: 'TrafficManModule'
  scope: resourceGroup(trafficmanagerResourceGroupName)
  params: {
    resourceToken: resourceToken
    location1: location1
    location2: location2
    lb1IP: virtualmachine.outputs.lb1PublicIP
    lb2IP: virtualmachine.outputs.lb2PublicIP
  }
  dependsOn: [
    virtualmachine
  ]
}


// module frontdoor 'frontdoor.bicep' = {
//   name: 'FrontDoorModule'
//   scope: resourceGroup(fdResourceGroupName)
//   params: {
//     lb1privateIP: virtualmachine.outputs.lb1privateIP
//     lb2privateIP: virtualmachine.outputs.lb2privateIP 
//     storageBlobEndpoint: storage.outputs.storageBlobEndpoint
//   }
//   dependsOn: [
//     network
//     privatedns
//     virtualmachine
//     storage
//   ]
// }
