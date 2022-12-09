#!/bin/bash

#
# Creates a private gpg key pair and uploads to an azure keyvault
#

set -e

if [ -z "$1" ]; then
    echo -e "\e[43mMissing pgp secret name!\e[49m"
    echo
    echo "Usage: $0 sops-gpg"
    echo
    echo "This will generate an azure keyvault secret certificate for the SOPS GPG key."
    exit
fi

if [ -z "$2" ]; then
    echo -e "\e[43mMissing keyvault name!\e[49m"
    echo
    echo "Usage: $0 my-azure-keyvault"
    echo
    echo "The keyvault to use for storing the SOPS GPG key."
    exit
fi

if [ -z "$3" ]; then
    echo -e "\e[43mMissing gpg key name!\e[49m"
    echo
    echo "Usage: $0 sops-gpg"
    echo
    echo "The gpg key name."
    exit
fi

SECRET_NAME=$1
KEYVAULT_NAME=$2
GPG_KEY_NAME=$3

scriptPath=$(dirname "$0")

for cmd in gpg; do
  which $cmd > /dev/null || { echo -e "💥 Error! Command $cmd not installed"; exit 1; }
done

echo -e "\e[36m###\e[33m 🔑 Creating GPG keys unattended\e[39m"
gpg --batch --full-generate-key --rfc4880 --digest-algo sha512 --cert-digest-algo sha512 <<EOF
    %no-protection
    # %no-protection: means the private key won't be password protected
    # (no password is a fluxcd requirement, it might also be true for argo & sops)
    Key-Type: RSA
    Key-Length: 4096
    Subkey-Type: RSA
    Subkey-Length: 4096
    Expire-Date: 0
    Name-Real: $GPG_KEY_NAME
    Name-Comment: $GPG_KEY_NAME
EOF

privateKey=$(gpg --export-secret-keys --armor $GPG_KEY_NAME | base64)

## Store GPG private key in AKV as a secret
az keyvault secret set --name $SECRET_NAME --vault-name $KEYVAULT_NAME --encoding base64 --value "$privateKey" > /dev/null