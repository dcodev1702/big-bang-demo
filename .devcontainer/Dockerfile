# See here for image contents: https://github.com/microsoft/vscode-dev-containers/tree/v0.224.3/containers/ubuntu/.devcontainer/base.Dockerfile

# [Choice] Ubuntu version (use hirsuite or bionic on local arm64/Apple Silicon): hirsute, focal, bionic
FROM debian:bullseye-slim

ENV LANG C.UTF-8

# [Option] Install zsh
ARG INSTALL_ZSH="false"
# [Option] Upgrade OS packages to their latest versions
ARG UPGRADE_PACKAGES="true"

# Install needed packages and setup non-root user.
ARG USERNAME=vscode
ARG USER_UID=1000
ARG USER_GID=$USER_UID

COPY library-scripts/*.sh /tmp/library-scripts/
RUN apt-get update && bash /tmp/library-scripts/azcli-debian.sh

RUN apt-get update \
    && export DEBIAN_FRONTEND=noninteractive \
    && /bin/bash /tmp/library-scripts/common-debian.sh "${INSTALL_ZSH}" "${USERNAME}" "${USER_UID}" "${USER_GID}" "${UPGRADE_PACKAGES}" "true" "true"\
    && rm -rf /tmp/library-scripts \
    && apt-get install -y --no-install-recommends \
    python3 \
    python3-pip \
    sudo \
    wget \
    curl \
    git \
    && apt-get autoremove -y && apt-get clean -y && rm -rf /var/lib/apt/lists/*

# RUN curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash

# Node, NPM, and Coral CLI
RUN curl -fsSL https://deb.nodesource.com/setup_current.x | bash - && apt-get install -y nodejs
RUN npm install -g @coraldev/cli

# Flux
RUN curl -s https://fluxcd.io/install.sh | bash

# Helm
RUN curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash

# Octant 
# RUN wget https://github.com/vmware-tanzu/octant/releases/download/v0.24.0/octant_0.24.0_Linux-ARM64.deb
# RUN dpkg -i octant_0.24.0_Linux-ARM64.deb

# Kubernetes
RUN curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
RUN install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl

# Github CLI for Secret Management
RUN type -p curl >/dev/null || sudo apt install curl -y
RUN curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | sudo dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg \
&& sudo chmod go+r /usr/share/keyrings/githubcli-archive-keyring.gpg \
&& echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | sudo tee /etc/apt/sources.list.d/github-cli.list > /dev/null \
&& sudo apt update \
&& sudo apt install gh -y

# KubeLogin Install
RUN wget https://github.com/Azure/kubelogin/releases/download/v0.0.22/kubelogin-linux-amd64.zip \
&& unzip kubelogin-linux-amd64.zip \
&& sudo mv bin/linux_amd64/kubelogin /usr/bin

USER $USERNAME

ENTRYPOINT /bin/bash
