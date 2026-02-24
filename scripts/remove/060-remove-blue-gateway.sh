#! /bin/bash

## 060-remove-blue-gateway.sh

kubectl delete -f blue-app-https-gateway.yaml
kubectl delete secret tls-secret -n blue

kubectl delete -f blue-app-http-gateway.yaml
kubectl delete -f irule.yaml -n blue # applied to the GW namespace
kubectl delete -f blue-net-policy.yaml -n blue
kubectl delete -f blue-vlan.yaml -n f5-bnk
kubectl delete -f blue-app-conf.yaml 
kubectl delete -f test-app.yaml -n blue
kubectl delete -f blue-app2-conf.yaml 
kubectl delete -f test-app2.yaml -n blue
#kubectl delete ns blue


