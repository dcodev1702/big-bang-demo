#!/bin/bash

#
# This is a script that deploys BigBang into Kubernetes
#

scriptPath=$(dirname "$0")
NAMESPACE=bigbang

indent() {
  local indentSize=2
  local indent=1
  if [ -n "$1" ]; then indent=$1; fi
  pr -to $(($indent * $indentSize))
}

for cmd in gpg sops kubectl kustomize; do
  which $cmd >/dev/null || {
    echo -e "💥 Error! Command $cmd not installed"
    exit 1
  }
done

for varName in GPG_KEY_NAME IRON_BANK_USER IRON_BANK_PAT AKV_GPG_SECRET_URI AKV_ISTIO_CRT_SECRET_URI AKV_ISTIO_KEY_SECRET_URI BB_TAG BB_REPO; do
  varVal=$(eval echo "\${$varName}")
  [[ -z $varVal ]] && {
    echo "💥 Error! Required variable '$varName' is not set!"
    varUnset=true
  }
done
[[ $varUnset ]] && exit 1

echo -e "\n\e[34m╔════════════════════════════════════════╗
║   \e[35mBigBang Automated Deployer v0.2 🚀\e[34m   ║
╚════════════════════════════════════════╝\e[39m"

kubectl version
kubectl version >/dev/null 2>&1 || {
  echo -e "💥 Error! kubectl is not pointing at a cluster, configure KUBECONFIG or $HOME/.kube/config"
  exit 1
}

echo
echo -e "You are connected to Kubenetes: $(kubectl config view | grep 'server:' | sed 's/\s*server://')"

export ISTIO_GW_CRT=$(az keyvault secret show --id $AKV_ISTIO_CRT_SECRET_URI --query 'value' -o tsv | base64 -d | indent 8)
export ISTIO_GW_KEY=$(az keyvault secret show --id $AKV_ISTIO_KEY_SECRET_URI --query 'value' -o tsv | base64 -d | indent 8)

az keyvault secret show --id $AKV_GPG_SECRET_URI --query 'value' -o tsv | base64 --decode >pgp.asc
gpg --import pgp.asc
rm pgp.asc

export FINGER_PRINT=$(gpg -K $GPG_KEY_NAME | sed -e 's/ *//;2q;d;')

envsubst <$scriptPath/templates/secrets.enc.yaml.template >./manifests/big-bang/secrets.enc.yaml
envsubst <$scriptPath/templates/bigbang.configmap.template >./manifests/big-bang/configmap.yaml
envsubst <$scriptPath/templates/kustomization.yaml.template >./manifests/big-bang/kustomization.yaml
envsubst <$scriptPath/templates/sops.yaml.template >./.sops.yaml
sops --encrypt --in-place --pgp $FINGER_PRINT ./manifests/big-bang/secrets.enc.yaml

git add ./manifests/big-bang/secrets.enc.yaml ./.sops.yaml ./manifests/big-bang/configmap.yaml ./manifests/big-bang/kustomization.yaml
git commit -m "Updated by deployment script $(date)"
git push -f

echo -e "\n\e[36m###\e[33m 🔐 Creating secret sops-gpg in $NAMESPACE\e[39m"
gpg --export-secret-key --armor ${FINGER_PRINT} | kubectl create secret generic sops-gpg -n $NAMESPACE --from-file=bigbangkey.asc=/dev/stdin

IS_FLUX_INSTALLED=$(kubectl get deployment --ignore-not-found -n flux-system helm-controller)

if [[ "$IS_FLUX_INSTALLED" ]]; then
  echo "Skip initializing flux as it's already installed"
else
  echo -e "\n\e[36m###\e[33m 🚀 Installing flux from bigbang install script\e[39m"
  rm -rf $scriptPath/bigbang
  git clone -b $BB_TAG --single-branch $BB_REPO $scriptPath/bigbang
  pushd $scriptPath/bigbang
  ./scripts/install_flux.sh \
    --registry-username "${IRON_BANK_USER}" \
    --registry-password "${IRON_BANK_PAT}" \
    --registry-email bigbang@bigbang.dev 
  popd

  # Wait for flux to complete
  kubectl get deploy -o name -n flux-system | xargs -n1 -t kubectl rollout status -n flux-system
fi

echo -e "\n\e[36m###\e[33m 🔨 Removing flux-system 'allow-scraping' network policy\e[39m"
# If we don't remove this then kustomization won't be able to reconcile!
CHECK_NETWORK_POLICY=$(kubectl get netpol --ignore-not-found -n flux-system allow-scraping)

if [[ "$CHECK_NETWORK_POLICY" ]]; then
  echo -e "\n\e[36m###\e[33m 🔨 Removing flux-system 'allow-scraping' network policy\e[39m"
  kubectl delete netpol -n flux-system allow-scraping
else
  echo "Network policy allow-scraping doesn't exist";
fi
