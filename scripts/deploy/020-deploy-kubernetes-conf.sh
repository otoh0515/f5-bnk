#! /bin/bash

## 020-deploy-kubernetes-conf.sh
echo "## 020-deploy-kubernetes-conf.sh"

# This is a shim script to deploy configuration
# at the Kubernetes level for the various components

DEPLOY_DIR="/home/ubuntu/udf-cne/bnk-2.2.0-ga/scripts/deploy/"

# remove any existing CRDs!
source ${DEPLOY_DIR}../upgrade/2.1.0/crds.sh all --delete --force --crd

source ${DEPLOY_DIR}023-deploy-node-conf.sh
source ${DEPLOY_DIR}022-deploy-certmgr.sh
source ${DEPLOY_DIR}021-deploy-node-labels.sh
