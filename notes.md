# Notes

## 1. Set-up HNC

Provided that a cluster has been spun up already HNC can easily be added using the script below:

```
#!/bin/bash
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
```

Something to note however, I noticed that creating the 'main' namespace, in our case the controller namespace should be done before installing HNC. Otherwise the command for creating namespaces (kubectl create namespace) seems to have some issues as it uses HNC. Once HNC has been set up we can create the tree structure for the namespaces.

```
kubectl create namespace a-spi-controller
kubectl-hns create -n a-spi-controller a-spi-managed-1
kubectl-hns create -n a-spi-managed-1 a-spi-managed-1-iam
```

## 2. Configure context controls in sub-namespace

In order to control the resources in each namespace an overarching ClusterRole was created and then a RoleBinding on each sub-namespace using the ClusterRole.
ClusterRoles, as the name implies, are cluster wide, they are not attached to a namespace, making them favorable when compare to the Role equivalent which is namespace specific. With ClusterRoles all we need to do is create the role with the right permissions and then we can use the RoleBinding to manage permissions on the namespace.
In this case, the service account was located in the managed project (a-spi-managed-1), and the role manifests used were:
```
# iam-admin-clusterrole.yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: iam-admin-clusterrole
rules:
- apiGroups: ["iam.cnrm.cloud.google.com"]
  resources: ["iampolicies", "iampolicymembers", "iamserviceaccounts"]
  verbs: ["get", "watch", "list", "create", "update", "patch", "delete"]
---
# iam-manager-iam-admin-clusterrole-rolebinding.yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: iam-manager-iam-admin-clusterrole-rolebinding
  namespace: a-spi-managed-1-iam
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: iam-admin-clusterrole
subjects:
- kind: User
  name: iam-manager@a-spi-managed-1.iam.gserviceaccount.com
```

## 3. Verify Control isolation between resource-based namespace and Google Project

With the role added to the service account deployments via Config Connector could be ran against the cluster. For example to deploy a service account the following manifest was used:

```
apiVersion: iam.cnrm.cloud.google.com/v1beta1
kind: IAMServiceAccount
metadata:
  name: iamserviceaccount-test
  namespace: a-spi-managed-1-iam
spec:
  displayName: Example Service Account
```

Unless the role is added this will throw a 403 error, if the namespace specified is different there will also be a 403 error thrown. 
Furthermore, if we use a VM where the calls run from (The VM uses the iam-manager SA), the call will also return a 403 error, the way to resolve this is by changing the VM scopes or by assigning the role to the UID of the SA instead of the name as per https://cloud.google.com/kubernetes-engine/docs/how-to/role-based-access-control#forbidden_error_for_service_accounts_on_vm_instances 

## 4. Control access in managed project's root namespace

As long as we do not add any RoleBindings on the root namespace, the group using Kubernetes Admin in the project is able to manage the resources within. Otherwise, the control can be granted similarly to what we did for managed projects, but this time using the root project. 