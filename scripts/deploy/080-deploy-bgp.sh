#! /bin/bash

## 080-deploy-bgp.sh
echo "## 080-deploy-bgp.sh"

kubectl apply -f external-vlan.yaml -n f5-bnk
kubectl wait --for=condition=Programmed f5-spk-vlans.k8s.f5net.com external-vlan -n f5-bnk --timeout=120s

#kubectl create configmap f5-tmm-dynamic-routing-template -n f5-bnk
kubectl replace -f zebos-conf.yaml -n f5-bnk
