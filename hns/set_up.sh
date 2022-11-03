#!/bin/bash
gcloud compute networks create ama-spi-network --project=ama-spi-main --subnet-mode=auto --mtu=1460 --bgp-routing-mode=regional



HNC_VERSION=v1.0.0

kubectl apply -f https://github.com/kubernetes-sigs/hierarchical-namespaces/releases/download/${HNC_VERSION}/default.yaml 
sleep 30

install_crew () {
    set -x; cd "$(mktemp -d)"
    OS="$(uname | tr '[:upper:]' '[:lower:]')"
    ARCH="$(uname -m | sed -e 's/x86_64/amd64/' -e 's/\(arm\)\(64\)\?.*/\1\2/' -e 's/aarch64$/arm64/')"
    KREW="krew-${OS}_${ARCH}"
    curl -fsSLO "https://github.com/kubernetes-sigs/krew/releases/latest/download/${KREW}.tar.gz"
    tar zxvf "${KREW}.tar.gz"
    ./"${KREW}" install krew
    export PATH="${KREW_ROOT:-$HOME/.krew}/bin:$PATH"
    export PATH="${PATH}:${HOME}/.krew/bin"
    kubectl krew
}
install_crew
kubectl hns
