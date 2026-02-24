#! /bin/bash

## 070-remove-egress.sh

kubectl delete -f client-route.yaml -n f5-bnk
#kubectl delete -f csrc.yaml 
kubectl delete -f red-snat.yaml -n f5-bnk
kubectl delete -f egress.yaml -n f5-bnk
