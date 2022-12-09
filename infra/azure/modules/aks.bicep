param suffix string
param location string 

@description('Specifies the object ID of a user, service principal or security group in the Azure Active Directory. The object ID must be unique for the list of access policies. Get it by using Get-AzADUser or Get-AzADServicePrincipal cmdlets.')
param objectId string

param netVnet string
param netSubnet string
param logsWorkspaceId string = ''

param kube object = {
  nodeSize: 'Standard_DS2_v2'
  nodeCount: 1
  nodeCountMin: 5
  nodeCountMax: 10
}

@description('This is the built-in Azure Kubernetes Service RBAC Cluster Admin role. See https://docs.microsoft.com/azure/role-based-access-control/built-in-roles#azure-kubernetes-service-rbac-cluster-admin')
resource aksRbacClusterAdminRoleDefinition 'Microsoft.Authorization/roleDefinitions@2018-01-01-preview' existing = {
  scope: subscription()
  name: 'b1ff04bb-8a4e-4dc4-8eb5-8693973ce19b'
}

var addOns = {
  // Enable monitoring add on, only if logsWorkspaceId is set
  omsagent: logsWorkspaceId != '' ? {
    enabled: true
    config: {
      logAnalyticsWorkspaceResourceID: logsWorkspaceId
    }
  } : {}
}

resource aks 'Microsoft.ContainerService/managedClusters@2020-12-01' = {
  name: 'aks-${suffix}'
  location: location
  
  identity: {
    type: 'SystemAssigned'
  }

  properties: {
    dnsPrefix: 'aks-${suffix}'
    kubernetesVersion: kube.version

    agentPoolProfiles: [
      {
        name: 'default'
        mode: 'System'
        type: 'VirtualMachineScaleSets'
        osType: 'Linux'        
        vnetSubnetID: resourceId('Microsoft.Network/virtualNetworks/subnets', netVnet, netSubnet)
        vmSize: kube.nodeSize
        enableAutoScaling: true
        count: kube.nodeCount
        minCount: kube.nodeCount
        maxCount: kube.nodeCountMax

        // Must enable CustomNodeConfigPreview 
        // https://docs.microsoft.com/en-us/azure/aks/custom-node-configuration#register-the-customnodeconfigpreview-preview-feature
        linuxOSConfig: {
          sysctls: {
            vmMaxMapCount: 262144
          }
        }
      }
    ]
    
    // Enable advanced networking and policy
    networkProfile: {
      networkPlugin: 'azure'
      networkPolicy: 'azure'
    }

    // Add ons are configured above, as a conditional variable object
    addonProfiles: addOns
  }
}

@description('Assign the Azure Kubernetes Service RBAC Cluster Admin role to the cluster admin AAD group')
resource clusterAdminRoleAssignment 'Microsoft.Authorization/roleAssignments@2020-08-01-preview' = {
  scope: aks
  name: guid(resourceGroup().id, objectId, aksRbacClusterAdminRoleDefinition.id)
  properties: {
    roleDefinitionId: aksRbacClusterAdminRoleDefinition.id
    principalId: objectId
    principalType: 'ServicePrincipal'
  }
}

output clusterName string = aks.name
output clusterFQDN string = aks.properties.fqdn
output provisioningState string = aks.properties.provisioningState
