#! /bin/bash

SCRIPT_DIR="$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )/"

# run 
# bash ~/udf-cne/bnk-2.2.0-ga/scripts/full-remove.sh # <-- this script

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
