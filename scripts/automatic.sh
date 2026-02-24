#! /bin/bash

export LOG_FILE="/var/log/bnk-deployment.log"
SCRIPT_DIR="$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )/"
source ${SCRIPT_DIR}check-auto.sh
 
if [ "$(kubectl get ns | grep "red\|blue\|f5-utils\|cert-manager" | wc -l)" != "0" ]; then
  echo "$(date) INFO ****************************************************************" | sudo tee -a "${LOG_FILE}" > /dev/null
  echo "$(date) INFO removing existing configuration " | sudo tee -a "${LOG_FILE}"
  source ${SCRIPT_DIR}full-remove.sh
fi

count=0
while true
do
  count=$((count + 1))
  echo "$(date) INFO ****************************************************************" | sudo tee -a "${LOG_FILE}" > /dev/null
  echo "$(date) INFO Starting deployment ${count}" | sudo tee -a "${LOG_FILE}"
  bash ~/udf-cne/reclone-repo.sh
  source ${SCRIPT_DIR}full-deploy.sh "${@}"
  echo "$(date) INFO Deployment complete" | sudo tee -a "${LOG_FILE}"
  if [ -f "${SCRIPT_DIR}stop-on-deployment" ]; then
    echo "$(date) INFO Breakpoint tiggered" | sudo tee -a "${LOG_FILE}"
    exit 1
  fi
  echo "*** Deployment completed - removal starting in 20s"
  sleep 20

  echo "$(date) INFO Removing deployment" | sudo tee -a "${LOG_FILE}"
  source ${SCRIPT_DIR}full-remove.sh
  echo "$(date) INFO Removal complete" | sudo tee -a "${LOG_FILE}"
  if [ -f "${SCRIPT_DIR}stop-on-removal" ]; then
    echo "$(date) INFO Breakpoint tiggered" | sudo tee -a "${LOG_FILE}"
    exit 1
  fi
  echo "*** Removal completed - re-deploy starting in 20s"
  sleep 20

done