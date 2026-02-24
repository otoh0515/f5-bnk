#! /bin/bash

## 070 deploy-egress.sh
echo "## 070-deploy-egress.sh"

kubectl apply -f red-snat.yaml -n f5-bnk
kubectl wait --for=condition=Programmed=True f5-spk-snatpools.k8s.f5net.com red-snat -n f5-bnk --timeout=120s

kubectl apply -f client-route.yaml -n f5-bnk
kubectl wait --for=condition=Programmed=True f5-spk-staticroutes.k8s.f5net.com client-route -n f5-bnk --timeout=120s
kubectl wait --for=condition=Programmed=True f5-spk-staticroutes.k8s.f5net.com client-dnat-route -n f5-bnk --timeout=120s

kubectl apply -f egress.yaml -n f5-bnk
kubectl wait --for=condition=Programmed=True f5spkegress.k8s.f5net.com/red-egress -n f5-bnk --timeout=300s
