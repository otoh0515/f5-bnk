#! /bin/bash

## 022-deploy-certmgr.sh
echo "## 022-deploy-certmgr.sh"

wait_for () { source /home/ubuntu/udf-cne/cne-tools/bin/wait_for.sh "$@" ; } # call directly in case cne-tools not available

#cat cne_pull_64.json | helm registry login -u _json_key_base64 --password-stdin repo.f5.com
kubectl apply -f https://github.com/cert-manager/cert-manager/releases/download/v1.17.0/cert-manager.yaml

# use cert-manager to generate certificates, rather than legacy solution with gen-cert

kubectl create ns f5-bnk
kubectl create ns f5-utils

kubectl wait --for=condition=ready pod -l app.kubernetes.io/name=webhook -n cert-manager --timeout=120s

wait_for_command () {
  kubectl apply -f certmgr_cluster_issuer.yaml 
}

wait_for "Certificate Manager "

kubectl apply -f cwc-api-certs.yaml -n f5-utils
kubectl apply -f otel-certs.yaml -n f5-bnk

wait_for_command () {
  kubectl get secret cwc-license-certs-out -n f5-utils -o jsonpath='{.data.ca\.crt}'
} 

wait_for "cwc server certificate to be created"
# WORKAROUND: need to map ca.crt-->ca-root-cert, tls.crt-->server-cert, tls.key-->server-key
kubectl get secret cwc-license-certs-out -n f5-utils -o json | jq '{apiVersion: "v1",kind: "Secret",metadata: {name: "cwc-license-certs",namespace: "f5-utils"},type: "Opaque",data: {"ca-root-cert": .data["ca.crt"],"server-cert": .data["tls.crt"],"server-key": .data["tls.key"]}}' | kubectl apply -f -

wait_for_command () {
  kubectl get secret cwc-license-client-certs-out -n f5-utils -o jsonpath='{.data.ca\.crt}'
} 

wait_for "cwc client certificate to be created"
# WORKAROUND: need to map ca.crt-->ca-root-cert, tls.crt-->client-cert, tls.key-->client-key
kubectl get secret cwc-license-client-certs-out -n f5-utils -o json | jq '{apiVersion: "v1",kind: "Secret",metadata: {name: "cwc-license-client-certs",namespace: "f5-utils"},type: "Opaque",data: {"ca-root-cert": .data["ca.crt"],"client-cert": .data["tls.crt"],"client-key": .data["tls.key"]}}' | kubectl apply -f -


