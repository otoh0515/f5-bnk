#! /bin/bash

#SCRIPT_DIR="$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )/"
DEPLOY_DIR="${SCRIPT_DIR}deploy/"
source ${SCRIPT_DIR}check-auto.sh

cd ~/udf-cne/bnk-2.2.0-ga

echo "$(date) INFO starting FLO deployment"
#source ${DEPLOY_DIR}041-deploy-flo.sh
echo "$(date) INFO starting BNK deployment"
#source ${DEPLOY_DIR}042-deploy-bnk.sh
echo "$(date) INFO deploying services"
source ${DEPLOY_DIR}040-deploy-bnk.sh
source ${DEPLOY_DIR}050-deploy-red-gateway.sh
#source ${DEPLOY_DIR}060-deploy-blue-gateway.sh
#source ${DEPLOY_DIR}070-deploy-egress.sh
#source ${DEPLOY_DIR}080-deploy-bgp.sh
source ${DEPLOY_DIR}090-deploy-bnk-fw.sh
#source ${DEPLOY_DIR}100-deploy-analytics.sh

# wait for 10s to allow configuration to be loaded
sleep 10
echo "$(date) INFO testing..."

source ${SCRIPT_DIR}test.sh

