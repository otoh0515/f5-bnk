#! /bin/bash

## 050-remove-red-gateway.sh

kubectl delete -f red-app-gateway.yaml
kubectl delete -f red-vlan.yaml -n f5-bnk
kubectl delete -f red-app-conf.yaml 
kubectl delete -f test-app.yaml -n red
#kubectl delete ns red