#! /bin/bash

## 080-remove-bgp.sh

kubectl delete -f zebos-conf.yaml -n f5-bnk
kubectl delete configmap f5-tmm-dynamic-routing-template -n f5-bnk
kubectl delete -f external-vlan.yaml -n f5-bnk

