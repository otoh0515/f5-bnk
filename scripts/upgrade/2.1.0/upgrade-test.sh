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


SCRIPT_DIR="/home/ubuntu/udf-cne/bnk-2.2.0-ga/scripts/"
cd ${SCRIPT_DIR}
source ${SCRIPT_DIR}check-auto.sh
kubectl config set-context --current --namespace default
echo "$(date) INFO starting full remove"
source  ${SCRIPT_DIR}bnk-remove.sh
source  ${SCRIPT_DIR}environment-remove.sh

echo "$(date) INFO forcing NS removal (full-remove.sh)"

force-delete-ns () {
  NS="${1}"

  if ! kubectl get namespace "${NS}" &>/dev/null; then
    echo "${NS} does not exist"
    return 0
  fi

  kubectl get namespace "${NS}" -o json \
  | tr -d "\n" | sed "s/\"finalizers\": \[[^]]\+\]/\"finalizers\": []/" \
  | kubectl replace --raw /api/v1/namespaces/${NS}/finalize -f -
  kubectl delete ns "${NS}"
}

force-delete-ns f5-bnk
force-delete-ns f5-utils
force-delete-ns f5-storage
force-delete-ns cert-manager
force-delete-ns red
force-delete-ns blue


echo "$(date) INFO completed full remove"



SCRIPT_DIR="/home/ubuntu/udf-cne/bnk-2.2.0-ga/scripts/"
cd ${SCRIPT_DIR}

# run 
# bash ~/udf-cne/reclone-repo.sh # run this first
# bash ~/udf-cne/bnk-2.2.0-ga/scripts/full-deploy.sh # <-- this script3

#ln -sf /home/ubuntu/udf-cne/bnk-2.2.0-ga/ /home/ubuntu/my-bnk

source ${SCRIPT_DIR}check-auto.sh
kubectl config set-context --current --namespace default
echo "$(date) INFO starting full deployment"
source ${SCRIPT_DIR}environment-deploy.sh
source ${SCRIPT_DIR}bnk-deploy.sh
echo "$(date) INFO completed full deployment"

# bash ~/udf-cne/bnk-2.2.0-ga/scripts/full-remove.sh
