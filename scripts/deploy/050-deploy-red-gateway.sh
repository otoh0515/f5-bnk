#! /bin/bash

## 050-deploy-red-gateway.sh
echo "## 050-deploy-red-gateway.sh"

kubectl apply -f red-vlan.yaml -n f5-bnk
kubectl wait --for=condition=Programmed f5-spk-vlans.k8s.f5net.com red-vlan -n f5-bnk --timeout=120s

kubectl create ns red
kubectl apply -f test-app.yaml -n red
kubectl apply -f red-app-conf.yaml

kubectl apply -f red-app-gateway.yaml

kubectl wait deployment/nginx-deployment --for=condition=available --timeout=60s -n red

