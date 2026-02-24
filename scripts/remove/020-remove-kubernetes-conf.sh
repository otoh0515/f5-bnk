#! /bin/bash

## 020-remove-kubernetes-conf.sh
echo "## 020-remove-kubernetes-conf.sh"

# This is a shim script to remove configuration
# at the Kubernetes level for the various components

REMOVE_DIR="/home/ubuntu/udf-cne/bnk-2.2.0-ga/scripts/remove/"

# force remove any CRDs
#echo "${REMOVE_DIR}../upgrade/2.1.0/crds.sh all --delete --force --crd"
#source ${REMOVE_DIR}../upgrade/2.1.0/crds.sh all --delete --force --crd
source /home/ubuntu/udf-cne/cne-tools/bin/cne-cr.sh all --delete --force --crd # upodated to use cne-tools script

kubectl delete ns f5-analytics
kubectl delete ns blue
kubectl delete ns red
kubectl delete ns f5-bnk
kubectl delete ns f5-utils

#source ${REMOVE_DIR}023-remove-node-conf.sh
#source ${REMOVE_DIR}022-remove-certmgr.sh
#source ${REMOVE_DIR}021-remove-node-labels.sh
