param suffix string
param location string 

resource logWorkspace 'Microsoft.OperationalInsights/workspaces@2020-08-01' = {
  location: location
  name: 'logs-${suffix}'
}

output logWorkspaceId string = logWorkspace.id
