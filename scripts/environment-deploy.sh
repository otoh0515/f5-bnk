#! /bin/bash

## environment-deploy.sh

SCRIPT_DIR="$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )/"
DEPLOY_DIR="${SCRIPT_DIR}deploy/"
source ${SCRIPT_DIR}check-auto.sh

cd ~/udf-cne/bnk-2.2.0-ga

#source ${DEPLOY_DIR}010-deploy-server-conf.sh
source ${DEPLOY_DIR}011-deploy-jumphost-conf.sh
source ${DEPLOY_DIR}012-deploy-client-conf.sh
source ${DEPLOY_DIR}013-deploy-router-conf.sh
source ${DEPLOY_DIR}014-deploy-host-conf.sh
#source ${DEPLOY_DIR}020-deploy-kubernetes-conf.sh
source ${DEPLOY_DIR}021-deploy-node-labels.sh
source ${DEPLOY_DIR}022-deploy-certmgr.sh
source ${DEPLOY_DIR}023-deploy-node-conf.sh
source ${DEPLOY_DIR}030-deploy-dpu-conf.sh

