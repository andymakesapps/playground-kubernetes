#!/bin/bash

kubectl create role pod-admin -n my-lonely-namespace --verb=get,update,create,delete,list,watch --resource=pod
kubectl create role iam-admin -n ama-spi-main --verb=get,list,watch,create,update,patch,delete --resource=iampolicies,iampolicymembers --apiGroups=
  - get
  - list
  - watch
  - create
  - update
  - patch
  - delete