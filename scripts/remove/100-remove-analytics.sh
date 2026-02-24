#! /bin/bash

## 100-remove-analytics.sh

kubectl delete -f grafana.yaml -n f5-analytics
kubectl delete -f prometheus.yaml
kubectl delete -f otel-certs.yaml -n f5-bnk
#kubectl delete ns f5-analytics

