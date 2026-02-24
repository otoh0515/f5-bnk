#! /bin/bash

## upgrade-v2.0-v2.1.sh
echo "upgrade-v2.0-v2.1.sh"

wait_for () { source /home/ubuntu/udf-cne/cne-tools/bin/wait_for.sh "$@" ; } # call directly in case cne-tools not available

# Create v2.1 repo
cd
# if repo does not exist:
#  bash ~/udf-cne/bnk-2.2.0-ga/scripts/upgrade/2.1.0/create-repo-2.1.0.sh
cd ~/udf-cne/bnk-2.2.0-ga
echo "DEBUG 16 : $(pwd)"
bash ~/udf-cne/bnk-2.2.0-ga/scripts/deploy/011-deploy-jumphost-conf.sh # create secrets
echo "DEBUG 17 : $(pwd)"
ls -l ~/udf-cne/bnk-2.2.0-ga/cne_pull_64.json
# Remove v2.0 deployment

cd ~/udf-cne/bnk-2.2.0-ga
kubectl delete -f irule.yaml -n f5-bnk # applied to the gateway namespace # must delete iRules for v2.0.0 EHF-1
kubectl delete -f gatewayclass.yaml # must delete before deleting bnkgatewayclass
kubectl delete bnkgatewayclass.k8s.f5.com my-bnkgatewayclass -n f5-bnk # must delete before uninstalling FLO

wait_for_command () {
  if [[ -z "$(kubectl get pods -n f5-bnk | grep -v "^NAME" | grep -v "operator")" ]]; then echo "no CNE pods running"; fi
}

wait_for "BNK Gatewayclass to terminate"


helm uninstall flo -n f5-bnk

kubectl delete configmap secure-spk-tmmcnfmappings-f5-bnk -n f5-bnk # IMPORTANT - egress will fail if this is not removed

kubectl delete -f https://github.com/kubernetes-sigs/gateway-api/releases/download/v1.2.0/standard-install.yaml # must delete FLO first

helm uninstall f5-spk-crds-common 
helm uninstall f5-spk-crds-service-proxy 

bash ~/udf-cne/bnk-2.2.0-ga/scripts/upgrade/2.1.0/crds.sh all --force --delete --crds

kubectl wait --for=delete pod --all -n f5-bnk --timeout=60s
kubectl wait --for=delete pod --all -n f5-utils --timeout=60s

# additional
kubectl delete ns f5-bnk
#kubectl delete ns f5-utils
sleep 10

# Deploy BNK

cd ~/udf-cne/bnk-2.2.0-ga

if [[ "$1" == "--no-deploy" ]]; then
  echo "--no-deploy set. To deploy:"
  echo "bash ~/udf-cne/bnk-2.2.0-ga/scripts/bnk-deploy.sh"
  exit 0
fi

if [[ ! -f ~/udf-cne/bnk-2.2.0-ga/cne_pull_64.json ]]; then
  echo "$(pwd) Key not found"
  sleep 3600
  exit 1
fi
kubectl create ns f5-bnk
#kubectl create ns f5-utils
kubectl apply -f network-attachments.yaml -n f5-bnk # required as namespace deleleted
#kubectl apply -f cwc-api-certs.yaml -n f5-utils
kubectl apply -f otel-certs.yaml -n f5-bnk
#kubectl get secret cwc-license-certs-out -n f5-utils -o json | jq '{apiVersion: "v1",kind: "Secret",metadata: {name: "cwc-license-certs",namespace: "f5-utils"},type: "Opaque",data: {"ca-root-cert": .data["ca.crt"],"server-cert": .data["tls.crt"],"server-key": .data["tls.key"]}}' | kubectl apply -f -
#kubectl get secret cwc-license-client-certs-out -n f5-utils -o json | jq '{apiVersion: "v1",kind: "Secret",metadata: {name: "cwc-license-client-certs",namespace: "f5-utils"},type: "Opaque",data: {"ca-root-cert": .data["ca.crt"],"client-cert": .data["tls.crt"],"client-key": .data["tls.key"]}}' | kubectl apply -f -

bash ~/udf-cne/bnk-2.2.0-ga/scripts/bnk-deploy.sh

