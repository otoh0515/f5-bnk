#! /bin/bash

## 010-deploy-server-conf.sh
echo "## 010-deploy-server-conf.sh"

# This is a shim script to perform configuration
# at the Host OS level for the various components

DEPLOY_DIR="/home/ubuntu/udf-cne/bnk-2.2.0-ga/scripts/deploy/"

source ${DEPLOY_DIR}011-deploy-jumphost-conf.sh
source ${DEPLOY_DIR}012-deploy-client-conf.sh
source ${DEPLOY_DIR}013-deploy-router-conf.sh
source ${DEPLOY_DIR}014-deploy-host-conf.sh
