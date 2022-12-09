targetScope = 'subscription'

param resGroupName string
param objectId string
param location string = 'eastus'
param suffix string = 'bigbang-${substring(uniqueString(resGroupName), 0, 4)}'

param enableMonitoring bool = true

param kube object = {
  version: '1.23.12'
  nodeSize: 'Standard_D4s_v4'
  nodeCount: 5
  nodeCountMax: 10
}

resource resGroup 'Microsoft.Resources/resourceGroups@2020-06-01' = {
  name: resGroupName
  location: location
}

module network 'modules/network.bicep' = {
  scope: resGroup
  name: 'network'
  params: {
    location: location
    suffix: suffix
  }
}

module other 'modules/monitoring.bicep' = if(enableMonitoring) {
  scope: resGroup
  name: 'monitors'
  params: {
    location: location
    suffix: suffix
  }
}

module kv 'modules/keyvault.bicep' = {
  scope: resGroup
  name: 'keyvault'
  params: {
    location: location
    suffix: suffix
    objectId: objectId
  }
}

module aks 'modules/aks.bicep' = {
  scope: resGroup
  name: 'aks'
  params: {
    location: location
    objectId: objectId
    suffix: suffix
    // Base AKS config like version and nodes sizes
    kube: kube

    // Network details
    netVnet: network.outputs.vnetName
    netSubnet: network.outputs.aksSubnetName

    // Optional features
    logsWorkspaceId: enableMonitoring ? other.outputs.logWorkspaceId : ''
  }
}

output clusterName string = aks.outputs.clusterName
output clusterFQDN string = aks.outputs.clusterFQDN
output aksState string = aks.outputs.provisioningState
