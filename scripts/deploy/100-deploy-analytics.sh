#! /bin/bash

## 100-deploy-analytics.sh
echo "## 100-deploy-analytics.sh"

kubectl create ns f5-analytics
#kubectl apply -f otel-certs.yaml -n f5-bnk
kubectl apply -f prometheus.yaml
#ssh node1 sudo chmod -R 777 /mnt/nfs
kubectl apply -f grafana.yaml -n f5-analytics
kubectl apply -f grafana-dashboard.yaml -n f5-analytics

# workaround
#sleep 20
#kubectl delete pods -l component=otel-collector -n f5-bnk
#kubectl wait --for=condition=Ready pods -l component=otel-collector -n f5-bnk --timeout=120s
