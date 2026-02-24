#! /bin/bash

SCRIPT_DIR="$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )/"
REMOVE_DIR="${SCRIPT_DIR}remove/"
source ${SCRIPT_DIR}check-auto.sh

cd ~/udf-cne/bnk-2.2.0-ga

source ${REMOVE_DIR}030-remove-dpu-conf.sh
source ${REMOVE_DIR}023-remove-node-conf.sh
source ${REMOVE_DIR}022-remove-certmgr.sh
source ${REMOVE_DIR}021-remove-node-labels.sh
source ${REMOVE_DIR}020-remove-kubernetes-conf.sh
source ${REMOVE_DIR}014-remove-host-conf.sh
source ${REMOVE_DIR}013-remove-router-conf.sh
source ${REMOVE_DIR}012-remove-client-conf.sh
# source ${REMOVE_DIR}011-remove-jumphost-conf.sh # keep aliases
source ${REMOVE_DIR}010-remove-server-conf.sh

