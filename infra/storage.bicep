param resourceToken string
param location string
param subnetId string
param vnet1ID string
param vnet2ID string

param storageAccountName string = '${resourceToken}static'
param staticContainerName string = 'static'
param mediaContainerName string = 'media'
param skuName string = 'Standard_GRS'

// Azure Private DNS Zone is a service that provides DNS resolution for your virtual networks 
// param privateDnsZoneName string = 'privatelink.blob.core.windows.net'

// resource privateDnsZone 'Microsoft.Network/privateDnsZones@2020-06-01' = {
//   name: privateDnsZoneName
//   location: 'global'
// }

// // Azure Virtual Network Link is a configuration that associates a virtual network (VNet) 
// // with a private DNS zone in Azure. 
// resource vnetLink1 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2020-06-01' = {
//   parent: privateDnsZone
//   name: 'storage-vnet1-link'
//   location: 'global'
//   properties: {
//     registrationEnabled: false 
//     virtualNetwork: {
//       id: vnet1ID
//     }
//   }
// }

// resource vnetLink2 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2020-06-01' = {
//   parent: privateDnsZone
//   name: 'storage-vnet2-link'
//   location: 'global'
//   properties: {
//     registrationEnabled: false 
//     virtualNetwork: {
//       id: vnet2ID
//     }
//   }
// }


resource storageAccount 'Microsoft.Storage/storageAccounts@2023-01-01' = {
  name: storageAccountName
  location: location
  kind: 'StorageV2'
  sku: {
    name: skuName
  }
  properties: {
    supportsHttpsTrafficOnly: true
    allowBlobPublicAccess: true
    minimumTlsVersion: 'TLS1_2'
  }
  // dependsOn: [
  //   privateDnsZone
  //   vnetLink1
  //   vnetLink2
  // ]
}

resource blobservices 'Microsoft.Storage/storageAccounts/blobServices@2023-01-01' = {
  name: 'default'
  parent: storageAccount
}

resource static 'Microsoft.Storage/storageAccounts/blobServices/containers@2023-01-01' = {
  name: staticContainerName
  parent: blobservices
  properties: {
    publicAccess: 'Blob'
  }
}

resource media 'Microsoft.Storage/storageAccounts/blobServices/containers@2023-01-01' = {
  name: mediaContainerName
  parent: blobservices
  properties: {
    publicAccess: 'Blob'
  }
}


// Azure Private Endpoint is a network interface that connects you privately to a service 
// by Azure Private Link. Private Endpoints use a private IP address from your virtual network.
// resource privateEndpoint 'Microsoft.Network/privateEndpoints@2023-11-01' = {
//   name: '${storageAccountName}-pe'
//   location: location
//   properties: {
//     privateLinkServiceConnections: [
//       {
//         name: 'storageAccountLink'
//         properties: {
//           privateLinkServiceId: storageAccount.id
//           groupIds: [
//             'blob'
//           ]
//           requestMessage: 'Requesting private endpoint for blob access'
//         }
//       }
//     ]
//     subnet: {
//       id: subnetId
//     }
//   }
// }


// Azure Private DNS Zone Group is a feature that helps the association of private DNS zones 
// with private endpoints
// resource privateDnsZoneGroup 'Microsoft.Network/privateEndpoints/privateDnsZoneGroups@2023-11-01' = {
//   parent: privateEndpoint
//   name: 'storagednsgroup'
//   properties: {
//     privateDnsZoneConfigs: [
//       {
//         name: 'storagednsconfig1'
//         properties: {
//           privateDnsZoneId: privateDnsZone.id 
//         }
//       }
//     ]
//   }
// }


var storageAccountKeys = listKeys(storageAccount.id, storageAccount.apiVersion)
var AZ_ACCOUNT_KEY = storageAccountKeys.keys[0].value

output AZ_ACCOUNT_NAME string = storageAccountName
output AZ_ACCOUNT_KEY string = AZ_ACCOUNT_KEY

output storageAccountId string = storageAccount.id
// output storagePEId string = privateEndpoint.id
// output storageBlobEndpoint string = storageAccount.properties.primaryEndpoints.blob


