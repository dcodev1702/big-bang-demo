# Platform One - AKS Big Bang Software Factory Deployment

This is the BigBang Control Plane Seed blueprint intended to help ease the barrier of entry for platform teams looking to provision instances of Platform One within Azure. This solution is based off Big Bang's customer [template](https://repo1.dso.mil/platform-one/big-bang/customers/template).

![image](https://user-images.githubusercontent.com/7635865/206611836-c1b68274-65ad-4011-8c80-12e18e75652c.png)

## Customer Use-Case

Platform Teams seeking to onboard Software Factories like Platform One involves a complex setup process requiring deep technical expertise with limited dev tools available to help automate the journey.

Platform and Application Dev teams can use [Coral](https://github.com/csemissionplatformops/coral) to auto provision Software Factory blueprints in just 2 commands. Coral helps simplify platform and application onboarding while promoting consistency, reuse and ease of maintenance. 

## AKS BigBang Software Factory

This control plane template has been customized to scale and integrate with Azure [AKS](https://azure.microsoft.com/en-us/products/kubernetes-service/).

The BigBang seed shares the initial setup of the platform as described in [coral's platform setup instructions](https://github.com/csemissionplatformops/coral/tree/main/docs/platform-setup.md).

However, since this seed assumes that the neither the UI portal nor the API will be used for management of the platform, neither the AAD nor the Portal UI setup are required. Instead, a workflow in this repo is used to [register a new application with Coral](https://github.com/csemissionplatformops/coral/tree/main/docs/application-registration.md).

For more information on other aspects of Coral, please refer to the [Coral documentation](https://github.com/csemissionplatformops/coral/tree/main/docs)

## Technical Background - Intended for Platform / Infra Team Audience

### Big Bang Architecture

#### Network Ingress Diagram

##### Goals of this Architecture Diagram - Help new users better understand:

- That the CNI component of Kubernetes creates an Inner Cluster Network.
- Kubernetes Ingress (How network traffic flows from LAN to Inner Cluster Network)
- How Big Bang is leveraging Istio Operator
- Network Encryption in the context of Big Bang (HTTPS, mTLS, and spots where Network Encryption is not present by default.)

![network_encryption_and_ingress_diagram.app.diagrams.net.png](https://repo1.dso.mil/platform-one/big-bang/bigbang/-/raw/master/docs/assets/imgs/understanding-bigbang/network-encryption-and-ingress-diagram.app.diagrams.net.png)

### Control Plane Repo Overview

The control plane repo keeps track of information in a set of folders and files, with this strucure:

- `.github/workflows` - Runs a workflow on each push to transform Coral entities into cluster gitops repo YAML to be processed by Flux
- `applications`
  - `<workspace-name>`
    - `ApplicationRegistrations` - defines the `ApplicationRegistrations` for a given workspace ([sample](https://github.com/csemissionplatformops/coral/blob/main/docs/samples/ApplicationRegistration.yaml))
    - `ManifestDeployments` - defines the `ManifestDeployments` (dialtone services) for a given workspace
- `assignments` - holds the application:cluster assignments after Coral processes the repo
- `clusters` - defines the `Clusters` in your platform ([sample](https://github.com/csemissionplatformops/coral/tree/main/docs/samples/Cluster.yaml))
- `infra` - defines the Infrastructure as Code bicep templates used to provision one instance of AKS, a private virtual network, one Keyvault (used to store the hostname and PGP key pairs) and monitoring services.
- `manifests` - holds Kubernetes YAML for use with `ManifestDeployments`
- `templates` - defines the available `ApplicationTemplates` in your platform ([sample](https://github.com/csemissionplatformops/coral/tree/main/docs/samples/ApplicationTemplate.yaml))
- `utils` - holds scripts and templates for Zarf package management.
- `workspaces` - defines the `Workspaces` in your platform ([sample](https://github.com/csemissionplatformops/coral/tree/main/docs/samples/Workspace.yaml))

## Platform Deployment  - Intended for Platform / Infra Team Audience

### Prerequisites

#### Azure Account 
You'll need an Azure account as this project deploys various cloud resources like a VNET, AKS and an Azure Key Vault. For those that don't have an Azure account, you can follow these [instructions](https://learn.microsoft.com/en-us/training/modules/create-an-azure-account/) to help get you started.

#### VS Code
This project includes a VSCode dev container to help automate the setup of the required tools. VSCode can be downloaded [here](https://code.visualstudio.com/download).

#### Azure Deployment Credentials
Create a new service principal using the Azure CLI. The Github Action CD pipelines will use this system identity to provision the cloud resources in Azure.

NOTE: The service principal will be created with an owner level role assignment on the subscription given the bicep template creates [role assignments](https://learn.microsoft.com/en-us/azure/aks/manage-azure-rbac#create-role-assignments-for-users-to-access-cluster) scoped to the AKS resource.

```sh
az login

az ad sp create-for-rbac --name "<replace-with-your-sp-name>" --role owner --scopes /subscriptions/<replace-with-your-target-subscription-id> --sdk-auth
```

#### Iron Bank Credentials
The Big Bang software factory Helm chart pulls it's platform docker images from the Iron Bank registry. Each deployment requires Iron Bank credentials to be provided as secrets in the Github repository. Follow these [instructions](https://login.dso.mil/auth/realms/baby-yoda/protocol/openid-connect/registrations?client_id=account&response_type=code) for setting up a new Iron Bank account.

The following secrets need to be [added](https://docs.github.com/en/actions/security-guides/encrypted-secrets#creating-encrypted-secrets-for-a-repository) to the repository (post platform deployment) so that the CD Github Action can deploy the Big Bang to the AKS cluster.

### Project Setup

#### Fork and Own

This software factory template follows a fork and own model to provide platform operators with a baseline starting point for Big Bang. Fork this repository and customize however you’d like to meet your business requirements. The intent is for customers to own and maintain the software factory blueprint(s) which works best for them.

#### Pre-installed Packages

This project's dev container pre-installs the following packages onto your local workstation: [coral CLI](https://github.com/CSEMissionPlatformOps/coral/blob/main/docs/platform-cli-commands.md), [kubectl](https://kubernetes.io/docs/reference/kubectl/), [azure cli](https://learn.microsoft.com/en-us/cli/azure/), [flux](https://fluxcd.io/flux/cmd/), [helm](https://helm.sh/docs/helm/), [octant](https://octant.dev/), [github CLI](https://cli.github.com/), [kubelogin CLI](https://github.com/Azure/kubelogin), [NPM](https://docs.npmjs.com/getting-started)

#### Local Workstation Usage - Option 1: Setup Local Dev Container
Start VS Code, run the Dev Containers: Open Folder in Container... command from the Command Palette (F1) or quick actions Status bar item, and select the project folder you would like to set up the container for.

![Dev Container](https://code.visualstudio.com/assets/docs/devcontainers/containers/remote-dev-status-bar.png)

#### Local Workstation Usage - Option 2: Open with Codespaces

- Click the `Code` button on this repo
- Click the `Codespaces` tab
- Click `New Codespace`

![Create Codespace](./images/OpenWithCodespaces.jpg)

#### Create Github Access Token

Coral utilizes [GitOps](https://www.weave.works/technologies/gitops/) to provide a scalable, open, and secure operational model for the Kubernetes clusters.

The next step is to use the Coral CLI to create these repositories.

[create a GitHub personal access token (PAT)](https://docs.github.com/en/authentication/keeping-your-account-and-data-secure/creating-a-personal-access-token) with `repo` and `workflow` scopes. If you are part of a single sign-on (SSO) organization, you may need to authorize your PAT using `Configure SSO`.

Next, place this GitHub PAT in an environmental variable named `GITHUB_TOKEN` in your development shell. For example:

```bash
export GITHUB_TOKEN=<TOKEN>
```

Be sure that Git is configured with your `user.name` and `user.email`

```bash
git config --global user.name "Your Name"
git config --global user.email "youremail@yourdomain.com"
```

#### Coral CLI Setup (required if not using Dev Container)
The CLI is available as the [@coraldev/cli](https://www.npmjs.com/package/@coral/cli) package on npm.

```bash
npm install -g @coraldev/cli

coral --help
```

### Big Bang Deployment

#### Control Plane Setup

Setup your local environment to configure where you'd like Coral to setup the Control Plane and GitOps Repositories

```sh
export CONTROL_PLANE_REPO_NAME=p1-bigbang-test
# NOTE: Provide your github organization / account name ie erikschlegel. Please make sure the org / account name is all lowercase
export GH_ORG=<replace-with-your-github-org>
export CONTROL_PLANE_REPO=$GH_ORG/$CONTROL_PLANE_REPO_NAME
export CONTROL_PLANE_TEMPLATE=$GH_ORG/big-bang-control-plane-seed
export CONTROL_PLANE_GITOPS=$GH_ORG/$CONTROL_PLANE_REPO_NAME-gitops
```

Provision the Big Bang control plane enviroment via Coral

```sh
coral init --control-plane-seed $CONTROL_PLANE_TEMPLATE --control-plane $CONTROL_PLANE_REPO --gitops $CONTROL_PLANE_GITOPS
```

#### Control Plane Repository Secrets

![image](https://user-images.githubusercontent.com/7635865/193352577-48f1d579-5d6f-4011-8b52-43588e6680e4.png)

- AZURE_CREDENTIALS: Copy the entire JSON output from the above mentioned `az ad sp create-for-rbac command`

```sh
# NOTE: Remove all tabs, leading spaces and carriage returns from the json string before saving as a string

# Ex. outputted JSON string from az ad sp create-for-rbac command

{
  "clientId": "####",
  "clientSecret": "####",
  "subscriptionId": "####",
  "tenantId": "####",
  "activeDirectoryEndpointUrl": "https://login.microsoftonline.com",
  "resourceManagerEndpointUrl": "https://management.azure.com/",
  "activeDirectoryGraphResourceId": "https://graph.windows.net/",
  "sqlManagementEndpointUrl": "https://management.core.windows.net:8443/",
  "galleryEndpointUrl": "https://gallery.azure.com/",
  "managementEndpointUrl": "https://management.core.windows.net/"
}

# Secret should be set as the following
AZURE_CREDENTIALS="{"clientId": "####", "clientSecret": "####", "subscriptionId": "####", "tenantId": "####", "activeDirectoryEndpointUrl": "https://login.microsoftonline.com", "resourceManagerEndpointUrl": "https://management.azure.com/", "activeDirectoryGraphResourceId": "https://graph.windows.net/", "sqlManagementEndpointUrl": "https://management.core.windows.net:8443/", "galleryEndpointUrl": "https://gallery.azure.com/", "managementEndpointUrl": "https://management.core.windows.net/"}"
```
- CLUSTER_NAME: The azure resource name for the AKS cluster
- CLUSTER_RESOURCE_GROUP: The azure resource group name containing the AKS cluster
- CLUSTER_REGION: The Azure resource group location
- P1_REGISTRY_PASSWORD: The authenitcation token for Iron Bank. This token can be accessed by logging into [Registry One](registry1.dso.mil) and copying the CLI Secret from your profile settings.
- P1_REGISTRY_P1_USERNAME: The authenitcation username for Iron Bank. This username can be accessed by logging into [Registry One](registry1.dso.mil) and copying the username from your profile settings.

You can automate uploading these secrets to the repository following `coral init` by using GitHub's [CLI](https://cli.github.com/manual/gh_secret_set)

This repository includes an environment file template `coral.env.template` to depict which secrets need to be defined within the control plane.

```sh
cp coral.env.template coral.env
# NOTE: Update coral.env with your secret values
gh secret set -f coral.env --repo $CONTROL_PLANE_REPO
```

## Application Deployment - Intended for Application Team Engineers

### Onboard Application to Big Bang 

Deploy a new application service to Big Bang. For the initial application, the below command will provision the AKS cluster using Big Bang's version `1.41` base [helm chart](https://repo1.dso.mil/platform-one/big-bang/bigbang/-/tree/1.41.0) then setup a Java Spring Boot Hello World Istio service onto Platform One's Service Mesh.

```sh
export NAME=<replace-with-your-username>
export APPLICATION_TEMPLATE=csemissionplatformops/coral-seed-java-p1-api
## NOTE: The istio service name cannot exceed 26 characters
export APPLICATION_REPO=$GH_ORG/$NAME-istio-svc

## Get the target $CONTROL_PLANE_REPO from the platform team
coral app init --control-plane $CONTROL_PLANE_REPO --starter-application-seed $APPLICATION_TEMPLATE --starter-application $APPLICATION_REPO
```

## Platform Team Members Only - Cluster Dashboard

```sh
az login --service-principal -u <spn client id> -p <spn secret> --tenant <tenant id>

az aks get-credentials --resource-group $RESOURCE_GROUP --name $CLUSTER_NAME

kubelogin convert-kubeconfig -l spn

export AAD_SERVICE_PRINCIPAL_CLIENT_ID=<spn client id>
export AAD_SERVICE_PRINCIPAL_CLIENT_SECRET=<spn secret>

# This command will open the Kubernetes Dashboard interface
octant

# Test deployment by opening a browser to "kiali.bigbang.dev" to get to the Kiali application deployed by Istio.
# Note that the owner of "bigbang.dev" has setup the domain to point to 127.0.0.1 for this type of testing.
# If you are deployed on a remote host you will need to point "kiali.bigbang.dev" to your cluster master node via your /etc/hosts file (described below)
```

## Big Bang Usage

###  Configure local domain to IP address mapping
The Big Bang deployed platform services are accessible by dns entries like kiali.bigbang.dev, grafana.bigbang.dev, etc.

In development, when using a domain name not recorded in a DNS server, if we want to access the virtual services created by Bigbang, we can add the IP address - domain mapping to /etc/hosts running the following commands:

```sh
# get istio gateway ip address
ip=$(kubectl -n istio-system get service public-ingressgateway -o jsonpath='{.status.loadBalancer.ingress[0].ip}')

# get big bang deployed domains
domains=$(kubectl get virtualservices  -A -o jsonpath="{ .items[*].spec.hosts[*] }")

# add entry in /etc/hosts
echo "$ip $domains" | sudo tee -a /etc/hosts
```

### Export Public Certificate from Bigbang Cluster

```sh
kubectl get secret -n istio-system public-cert -o jsonpath="{.data['tls\.crt']}" | base64 -d > public-cert.crt
```

You'll need to import the above exported certificate into your local OS keychain. Here are the instructions for [Mac Users](https://support.apple.com/guide/keychain-access/add-certificates-to-a-keychain-kyca2431/mac) and [Windows Users](https://support.globalsign.com/ssl/ssl-certificates-installation/import-and-export-certificate-microsoft-windows).

Before moving to Production, you'll want to choose a certificate authority to generate and validate your SSL / TLS certificate. You can import the public certificate and private key into the Azure Keyvault Instance used for this deployment. 
 
## Customizations

After importing this repo to GiHub it should be [marked as a template](https://docs.github.com/en/repositories/creating-and-managing-repositories/creating-a-template-repository). 

## See Also

- [Credentials for Big Bang Packages](https://repo1.dso.mil/platform-one/big-bang/bigbang/-/blob/master/docs/guides/using-bigbang/default-credentials.md#packages-with-built-in-authentication)
- [Big Bang Package Architecture](https://repo1.dso.mil/platform-one/big-bang/bigbang/-/tree/master/docs/understanding-bigbang/package-architecture#dependency-tree)
- [Big Bang Configuration Overview](https://repo1.dso.mil/platform-one/big-bang/bigbang/-/blob/master/docs/understanding-bigbang/configuration/configuration.md)
- [Register a new application with Coral](https://github.com/csemissionplatformops/coral/tree/main/docs/application-registration.md)
- [Coral Documentation](https://github.com/csemissionplatformops/coral/tree/main/docs)
