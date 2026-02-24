#! /bin/bash

# Create v2.1 repo

bash ~/udf-cne/bnk-dev/create-repo-v2.1.sh

# Remove v2.0 deployment

cd ~/udf-cne/bnk-2.2.0-ga
kubectl delete -f bnk-gatewayclass.yaml -n f5-bnk
helm uninstall flo -n f5-bnk

kubectl delete -f gatewayclass.yaml -n f5-bnk # must delete FLO first
kubectl delete -f https://github.com/kubernetes-sigs/gateway-api/releases/download/v1.2.0/standard-install.yaml

helm uninstall f5-spk-crds-common 
helm uninstall f5-spk-crds-service-proxy 

bash ~/udf-cne/bnk-dev/delete-crds.sh

# Deploy BNK

cd ~/udf-cne/bnk-2.2.0-ga
bash ~/udf-cne/bnk-2.2.0-ga/scripts/full-deploy.sh

