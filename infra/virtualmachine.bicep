param location1 string
param location2 string
param subnet1Id string
param subnet2Id string

// DATABASE
param MYSQL_HOST string
param MYSQL_DB_NAME string
@secure()
param administratorLogin string
@secure()
param administratorLoginPassword string

// STORAGE
param storageAccountName string
param AZ_ACCOUNT_KEY string

// SERVICE BUS
param AZURE_SERVICE_BUS_CONNECTION_STRING string
param AZURE_SERVICE_BUS_QUEUE_NAME string  

// VIRTUAL MACHINES
@secure()
param adminUsername string
@secure()
param adminPassword string
param vmCount int = 2
param vmSize string = 'Standard_B2s'
param platformFaultDomainCount int = 2
param platformUpdateDomainCount int = 2


resource availabilitySet1 'Microsoft.Compute/availabilitySets@2023-09-01' = {
  name: 'AvailabilitySet1'
  location: location1 
  properties: {
    platformFaultDomainCount: platformFaultDomainCount
    platformUpdateDomainCount: platformUpdateDomainCount
  }
  sku: {
    name: 'Aligned'
  }
}

resource lbPublicIP1 'Microsoft.Network/publicIPAddresses@2023-11-01' = {
  name: 'lbPublicIP1'
  location: location1
  sku: {
    name: 'Standard'
  }
  properties: {
    publicIPAllocationMethod: 'Static'
    dnsSettings: {
      domainNameLabel: 'lb1'
    }

  }
}


resource loadBalancer1 'Microsoft.Network/loadBalancers@2023-09-01' = {
  name: 'LoadBalancer1'
  location: location1 
  sku: {
    name: 'Standard'
  }
  properties: {
    frontendIPConfigurations: [
      {
        name: 'LoadBalancerFrontEnd1'
        properties: {
          publicIPAddress: {
            id: lbPublicIP1.id
          }
        }
      }
    ]
    backendAddressPools: [
      {
        name: 'BackendPool1'
      }
    ]
    loadBalancingRules: [
      {
        name: 'LoadBalancingRule1'
        properties: {
          frontendIPConfiguration: {
            id: resourceId('Microsoft.Network/loadBalancers/frontendIpConfigurations', 'LoadBalancer1', 'LoadBalancerFrontEnd1')
          }
          backendAddressPool: {
            id: resourceId('Microsoft.Network/loadBalancers/backendAddressPools', 'LoadBalancer1', 'BackendPool1')
          }
          protocol: 'Tcp'
          frontendPort: 80
          backendPort: 80
          enableFloatingIP: false
          idleTimeoutInMinutes: 4
          loadDistribution: 'Default'
          probe: {
            id: resourceId('Microsoft.Network/loadBalancers/probes', 'LoadBalancer1', 'lbProbe1')
          }
        }
      }
    ]
    probes: [
      {
        name: 'lbProbe1'
        properties: {
          protocol: 'Tcp'
          port: 80
          intervalInSeconds: 15
          numberOfProbes: 2
        }
      }
    ]
  }
}

resource nsg1 'Microsoft.Network/networkSecurityGroups@2023-09-01' = {
  name: 'vm-nsg1'
  location: location1 
  properties: {
    securityRules: [
      {
        name: 'AllowInternetOutbound'
        properties: {
          priority: 100
          direction: 'Outbound'
          access: 'Allow'
          protocol: '*'
          sourcePortRange: '*'
          destinationPortRange: '*'
          sourceAddressPrefix: '*'
          destinationAddressPrefix: 'Internet'
        }
      }
      {
        name: 'Allow-HTTP'
        properties: {
          priority: 100
          direction: 'Inbound'
          access: 'Allow'
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '80'
          sourceAddressPrefix: '*'
          destinationAddressPrefix: '*'
        }
      }
      {
        name: 'Allow-HTTPS'
        properties: {
          priority: 200
          direction: 'Inbound'
          access: 'Allow'
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '443'
          sourceAddressPrefix: '*'
          destinationAddressPrefix: '*'
        }
      }
      {
        name: 'Allow-SSH'
        properties: {
          priority: 300
          direction: 'Inbound'
          access: 'Allow'
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '22'
          sourceAddressPrefix: '*'
          destinationAddressPrefix: '*'
        }
      }
    ]
  }
}


resource networkInterface1 'Microsoft.Network/networkInterfaces@2023-09-01' = [for i in range(0, vmCount): {
  name: 'availabilitySet1-nic${i+1}'
  location: location1 
  properties: {
    ipConfigurations: [
      {
        name: 'avlSet1ipconfig1'
        properties: {
          subnet: {
            id: subnet1Id
          }
          privateIPAllocationMethod: 'Dynamic'
          loadBalancerBackendAddressPools: [
            {
              id: resourceId('Microsoft.Network/loadBalancers/backendAddressPools', 'LoadBalancer1', 'BackendPool1')
            }
          ]
        }
      }
    ]
    networkSecurityGroup: {
      id: nsg1.id
    }

  }
  dependsOn: [
    loadBalancer1
  ]
}]


resource virtualMachine 'Microsoft.Compute/virtualMachines@2023-09-01' = [for i in range(0, vmCount): {
  name: 'avlSet1-vm${i+1}'
  location: location1 
  properties: {
    availabilitySet: {
      id: availabilitySet1.id 
    }
    hardwareProfile: {
      vmSize: vmSize
    }
    osProfile: {
      computerName: 'avlSet1-vm${i+1}'
      adminUsername: adminUsername
      adminPassword: adminPassword
      linuxConfiguration: {
        disablePasswordAuthentication: false
      }
    }
    storageProfile: {
      imageReference: {
        publisher: 'Canonical'
        offer: '0001-com-ubuntu-server-jammy'
        sku: '22_04-lts-gen2'
        version: 'latest'
      }
      osDisk: {
        createOption: 'FromImage'
      }
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: networkInterface1[i].id
        }
      ]
    }
  }
}]

resource vmExtension1 'Microsoft.Compute/virtualMachines/extensions@2023-09-01' = [for i in range(0, vmCount): {
  name: 'avlSet1-vm${i+1}-runCommand'
  parent: virtualMachine[i]
  location: location1
  properties: {
    publisher: 'Microsoft.Azure.Extensions'
    type: 'CustomScript'
    typeHandlerVersion: '2.1'
    autoUpgradeMinorVersion: true
    settings: {
      fileUris: [
        'https://raw.githubusercontent.com/WIP-2024/CloudNine/main/env_setup/vm_setup.sh'
      ]
    }
    protectedSettings: {
      commandToExecute: 'sh vm_setup.sh "${MYSQL_HOST}" "${MYSQL_DB_NAME}" "${administratorLogin}" "${administratorLoginPassword}" "${storageAccountName}" "${AZ_ACCOUNT_KEY}" "${AZURE_SERVICE_BUS_QUEUE_NAME}" "${AZURE_SERVICE_BUS_CONNECTION_STRING}"'
    }
  }
  dependsOn: [
    networkInterface1
  ]
}]



// ====================== Start of the 2nd availability set ==========================

resource availabilitySet2 'Microsoft.Compute/availabilitySets@2023-09-01' = {
  name: 'AvailabilitySet2'
  location: location2  
  properties: {
    platformFaultDomainCount: platformFaultDomainCount
    platformUpdateDomainCount: platformUpdateDomainCount
  }
  sku: {
    name: 'Aligned'
  }
}

resource lbPublicIP2 'Microsoft.Network/publicIPAddresses@2023-11-01' = {
  name: 'lbPublicIP2'
  location: location2 
  sku: {
    name: 'Standard'
  }
  properties: {
    publicIPAllocationMethod: 'Static'
    dnsSettings: {
      domainNameLabel: 'lb2'
    }
  }
}

resource loadBalancer2 'Microsoft.Network/loadBalancers@2023-09-01' = {
  name: 'LoadBalancer2'
  location: location2 
  sku: {
    name: 'Standard'
  }
  properties: {
    frontendIPConfigurations: [
      {
        name: 'LoadBalancerFrontEnd2'
        properties: {
          publicIPAddress: {
            id: lbPublicIP2.id
          }
        }
      }
    ]
    backendAddressPools: [
      {
        name: 'BackendPool2'
      }
    ]
    loadBalancingRules: [
      {
        name: 'LoadBalancingRule2'
        properties: {
          frontendIPConfiguration: {
            id: resourceId('Microsoft.Network/loadBalancers/frontendIpConfigurations', 'LoadBalancer2', 'LoadBalancerFrontEnd2')
          }
          backendAddressPool: {
            id: resourceId('Microsoft.Network/loadBalancers/backendAddressPools', 'LoadBalancer2', 'BackendPool2')
          }
          protocol: 'Tcp'
          frontendPort: 80
          backendPort: 80
          enableFloatingIP: false
          idleTimeoutInMinutes: 4
          loadDistribution: 'Default'
          probe: {
            id: resourceId('Microsoft.Network/loadBalancers/probes', 'LoadBalancer2', 'lbProbe2')
          }
        }
      }
    ]
    probes: [
      {
        name: 'lbProbe2'
        properties: {
          protocol: 'Tcp'
          port: 80
          intervalInSeconds: 15
          numberOfProbes: 2
        }
      }
    ]
  }
}

resource nsg2 'Microsoft.Network/networkSecurityGroups@2023-09-01' = {
  name: 'vm-nsg2'
  location: location2  
  properties: {
    securityRules: [
      {
        name: 'AllowInternetOutbound'
        properties: {
          priority: 100
          direction: 'Outbound'
          access: 'Allow'
          protocol: '*'
          sourcePortRange: '*'
          destinationPortRange: '*'
          sourceAddressPrefix: '*'
          destinationAddressPrefix: 'Internet'
        }
      }
      {
        name: 'Allow-HTTP'
        properties: {
          priority: 100
          direction: 'Inbound'
          access: 'Allow'
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '80'
          sourceAddressPrefix: '*'
          destinationAddressPrefix: '*'
        }
      }
      {
        name: 'Allow-HTTPS'
        properties: {
          priority: 200
          direction: 'Inbound'
          access: 'Allow'
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '443'
          sourceAddressPrefix: '*'
          destinationAddressPrefix: '*'
        }
      }
      {
        name: 'Allow-SSH'
        properties: {
          priority: 300
          direction: 'Inbound'
          access: 'Allow'
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '22'
          sourceAddressPrefix: '*'
          destinationAddressPrefix: '*'
        }
      }
    ]
  }
}

resource networkInterface2 'Microsoft.Network/networkInterfaces@2023-09-01' = [for i in range(0, vmCount): {
  name: 'availabilitySet2-nic${i+1}'
  location: location2  
  properties: {
    ipConfigurations: [
      {
        name: 'avlSet2ipconfig1'
        properties: {
          subnet: {
            id: subnet2Id
          }
          privateIPAllocationMethod: 'Dynamic'
          loadBalancerBackendAddressPools: [
            {
              id: resourceId('Microsoft.Network/loadBalancers/backendAddressPools', 'LoadBalancer2', 'BackendPool2')
            }
          ]
        }
      }
    ]
    networkSecurityGroup: {
      id: nsg2.id 
    }
  }
  dependsOn: [
    loadBalancer2
  ]
}]


resource virtualMachine2 'Microsoft.Compute/virtualMachines@2023-09-01' = [for i in range(0, vmCount): {
  name: 'avlSet2-vm${i+1}'
  location: location2  
  properties: {
    availabilitySet: {
      id: availabilitySet2.id  
    }
    hardwareProfile: {
      vmSize: vmSize
    }
    osProfile: {
      computerName: 'avlSet2-vm${i+1}'
      adminUsername: adminUsername
      adminPassword: adminPassword
      linuxConfiguration: {
        disablePasswordAuthentication: false
      }
    }
    storageProfile: {
      imageReference: {
        publisher: 'Canonical'
        offer: '0001-com-ubuntu-server-jammy'
        sku: '22_04-lts-gen2'
        version: 'latest'
      }
      osDisk: {
        createOption: 'FromImage'
      }
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: networkInterface2[i].id 
        }
      ]
    }
  }
}]


resource vmExtension2 'Microsoft.Compute/virtualMachines/extensions@2023-09-01' = [for i in range(0, vmCount): {
  name: 'avlSet2-vm${i+1}-runCommand'
  parent: virtualMachine2[i]
  location: location2
  properties: {
    publisher: 'Microsoft.Azure.Extensions'
    type: 'CustomScript'
    typeHandlerVersion: '2.1'
    autoUpgradeMinorVersion: true
    settings: {
      fileUris: [
        'https://raw.githubusercontent.com/WIP-2024/CloudNine/main/env_setup/vm_setup.sh'
      ]
    }
    protectedSettings: {
      commandToExecute: 'sh vm_setup.sh "${MYSQL_HOST}" "${MYSQL_DB_NAME}" "${administratorLogin}" "${administratorLoginPassword}" "${storageAccountName}" "${AZ_ACCOUNT_KEY}" "${AZURE_SERVICE_BUS_QUEUE_NAME}" "${AZURE_SERVICE_BUS_CONNECTION_STRING}"'
    }
  }
  dependsOn: [
    networkInterface2
  ]
}]


output lb1Id string = loadBalancer1.id
output lb2Id string = loadBalancer2.id

// output lb1privateIP string = loadBalancer1.properties.frontendIPConfigurations[0].properties.privateIPAddress
// output lb2privateIP string = loadBalancer2.properties.frontendIPConfigurations[0].properties.privateIPAddress
