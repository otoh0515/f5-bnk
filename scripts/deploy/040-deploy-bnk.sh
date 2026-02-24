#! /bin/bash

## 040-deploy-bnk.sh
echo "## 040-deploy-bnk.sh"

# This is a shim script to deploy BNK in two stages:
# first F5 Lifecycle Orchestrator, then the CNE Instance
# this makes it possible to deploy/remove the CNE Instance
# independently using the deployment scripts

echo "$(date) INFO starting FLO deployment"
source ${DEPLOY_DIR}041-deploy-flo.sh
echo "$(date) INFO starting BNK deployment"
source ${DEPLOY_DIR}042-deploy-bnk.sh
echo "$(date) INFO deploying services"