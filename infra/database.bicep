param resourceToken string
param location1 string
param location2 string
param subnet1Id string
param subnet2Id string
param vnet1ID string
param vnet2ID string

param db1Name string = '${resourceToken}db1'
param db2Name string = '${resourceToken}db2'
// param skuName string = 'Standard_B1ms'
// param skuTier string = 'Burstable'
param skuName string = 'Standard_D2ads_v5'
param skuTier string = 'GeneralPurpose'
param mysqlVersion string = '8.0.21'
param storageSizeGB int = 20

param MYSQL_DB_NAME string = 'ecommerce'
@secure()
param administratorLogin string
@secure() 
param administratorLoginPassword string


param privateDnsZoneName string = 'privatelink.mysql.database.azure.com'

// Azure Private DNS Zone is a service that provides DNS resolution for your virtual networks 
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


// DATABASES
resource DataBase1 'Microsoft.DBforMySQL/flexibleServers@2023-06-01-preview' = {
  name: db1Name
  location: location1
  sku: {
    name: skuName
    tier: skuTier
  }
  properties: {
    version: mysqlVersion
    administratorLogin: administratorLogin
    administratorLoginPassword: administratorLoginPassword
    storage: {
      storageSizeGB: storageSizeGB
      autoGrow: 'Enabled'
    }
    replicationRole: 'Source'
    network: {
      delegatedSubnetResourceId: subnet1Id
      privateDnsZoneResourceId: privateDnsZone.id
    }
  }
  dependsOn: [
    privateDnsZone
    vnetLink1
  ]
}

resource mysqlSchema1 'Microsoft.DBforMySQL/flexibleServers/databases@2023-06-01-preview' = {
  name: MYSQL_DB_NAME
  parent: DataBase1
  properties: {
    charset: 'utf8'
    collation: 'utf8_general_ci'
  }
}


resource DataBase2 'Microsoft.DBforMySQL/flexibleServers@2023-06-01-preview' = {
  name: db2Name
  location: location2  
  sku: {
    name: skuName
    tier: skuTier
  }
  properties: {
    version: mysqlVersion
    administratorLogin: administratorLogin
    administratorLoginPassword: administratorLoginPassword
    storage: {
      storageSizeGB: storageSizeGB
      autoGrow: 'Enabled'
    }
    network: {
      delegatedSubnetResourceId: subnet2Id
      privateDnsZoneResourceId: privateDnsZone.id
    }
    replicationRole: 'Replica'
    createMode: 'Replica'
    sourceServerResourceId: DataBase1.id
  }
  dependsOn: [
    privateDnsZone
    vnetLink2 
  ]

}

resource mysqlSchema2 'Microsoft.DBforMySQL/flexibleServers/databases@2023-06-01-preview' = {
  name: MYSQL_DB_NAME
  parent: DataBase2
  properties: {
    charset: 'utf8'
    collation: 'utf8_general_ci'
  }
}


output primaryDbFQDN string = DataBase1.properties.fullyQualifiedDomainName
// output secondaryDbFQDN string = DataBase2.properties.fullyQualifiedDomainName

output MYSQL_HOST string = DataBase1.properties.fullyQualifiedDomainName
output MYSQL_DB_NAME string = MYSQL_DB_NAME
