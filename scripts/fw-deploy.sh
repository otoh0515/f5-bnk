#! /bin/bash

SCRIPT_DIR="$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )/"

# run 
# bash ~/udf-cne/reclone-repo.sh # run this first
# bash ~/udf-cne/bnk-2.2.0-ga/scripts/full-deploy.sh # <-- this script3

#ln -sf /home/ubuntu/udf-cne/bnk-2.2.0-ga/ /home/ubuntu/my-bnk

source ${SCRIPT_DIR}check-auto.sh
kubectl config set-context --current --namespace default
echo "$(date) INFO starting FIREWALL deployment"
source ${SCRIPT_DIR}environment-deploy.sh
source ${SCRIPT_DIR}bnk-fw-deploy.sh
echo "$(date) INFO completed FIREWALL deployment"

# bash ~/udf-cne/bnk-2.2.0-ga/scripts/full-remov
