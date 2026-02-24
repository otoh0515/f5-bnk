#! /bin/bash

## 060-deploy-blue-gateway.sh
echo "## 060-deploy-blue-gateway.sh"

kubectl apply -f blue-vlan.yaml -n f5-bnk
kubectl wait --for=condition=Programmed f5-spk-vlans.k8s.f5net.com blue-vlan -n f5-bnk --timeout=120s

kubectl create ns blue
kubectl apply -f blue-pool.yaml 
kubectl patch namespace blue -p '{"metadata":{"annotations":{"cni.projectcalico.org/ipv4pools":"[\"blue-pool\"]"}}}'

kubectl apply -f test-app.yaml -n blue
kubectl apply -f blue-app-conf.yaml 

kubectl apply -f test-app2.yaml -n blue
kubectl apply -f blue-app2-conf.yaml 

# iRules support requires v2.0.0 EHF-1 or later
kubectl apply -f irule.yaml -n blue # applied to the GW namespace
kubectl apply -f blue-net-policy.yaml -n blue
kubectl apply -f blue-app-http-gateway.yaml

openssl x509 -in secure-demo.crt -noout -subject -enddate
kubectl create secret tls tls-secret --cert=secure-demo.crt --key=secure-demo.key -n blue
kubectl apply -f blue-app-https-gateway.yaml

kubectl wait deployment/nginx-deployment --for=condition=available --timeout=60s -n blue
kubectl wait deployment/nginx2-deployment --for=condition=available --timeout=60s -n blue
