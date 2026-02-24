#! /bin/bash

## 022-remove-certmgr.sh
echo "## 022-remove-certmgr.sh"

kubectl delete -f certmgr_cluster_issuer.yaml
kubectl delete -f cwc-api-certs.yaml -n f5-utils
kubectl delete cwc-license-client-certs-out -n f5-utils
kubectl delete cwc-license-client-certs -n f5-utils
kubectl delete cwc-license-certs-out -n f5-utils
kubectl delete cwc-license-certs -n f5-utils

kubectl delete mutatingwebhookconfiguration cert-manager-webhook
kubectl delete validatingwebhookconfiguration cert-manager-webhook

kubectl delete -f https://github.com/cert-manager/cert-manager/releases/download/v1.17.0/cert-manager.yaml
#kubectl delete ns f5-utils

helm registry logout repo.f5.com

