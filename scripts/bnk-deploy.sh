#! /bin/bash

SCRIPT_DIR="$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )/"
DEPLOY_DIR="${SCRIPT_DIR}deploy/"
source ${SCRIPT_DIR}check-auto.sh

echo "BNK DEPLOY DEBUG"
echo "pwd: $(pwd)" 
echo "script-dir: ${SCRIPT_DIR}"
echo "deploy-dir: ${DEPLOY_DIR}"

release="$(basename "$(dirname "$SCRIPT_DIR")")"
version="$(printf '%s\n' "$@" | grep -oP '^--version=\K.*' | tr 'a-z' 'A-Z')"
declare -A VERSION_MANIFEST
VERSION_MANIFEST["bnk-2.0.0-ga|default"]="2.0.0-1.7.8-0.3.37"
VERSION_MANIFEST["bnk-2.0.0-ga|2.0.0-EHF-1"]="2.0.0-EHF-1-1.7.8-0.3.39"
VERSION_MANIFEST["bnk-2.1.0-ga|default"]="2.1.0-3.1736.1-0.1.27"
VERSION_MANIFEST["bnk-2.1.0-ga|2.1.0-EHF-1"]="2.1.0-EHF-1-3.1736.1-0.1.63"
VERSION_MANIFEST["bnk-2.1.0-ga|2.1.0-EHF-2"]="2.1.0-EHF-2-3.1736.1-0.1.65"
VERSION_MANIFEST["bnk-2.1.0-ga|2.1.0-EHF-3"]="2.1.0-EHF-3-3.1736.1-0.1.80"
VERSION_MANIFEST["bnk-2.2.0-ga|default"]="2.2.0-3.2226.0-0.0.385"

if [[ -n "${VERSION_MANIFEST["${release}|${version}"]}" ]]; then
  MANIFEST="${VERSION_MANIFEST["${release}|${version}"]}"
  echo "Release: ${release}, version: ${version} - using MANIFEST ${MANIFEST}"
else
  MANIFEST="${VERSION_MANIFEST["${release}|default"]}"
  if [[ -n "${version}" ]]; then
    echo "WARNING: unknown version ${version} for release ${release}"
  fi
  echo "Release: ${release} - using default MANIFEST ${MANIFEST}"
fi

if [[ "${release}" == "bnk-2.2.0-ga" ]]; then
  sed -i "s|manifestVersion: .*$|manifestVersion: ${MANIFEST}|" "${SCRIPT_DIR}/../cne-instance.yaml"
else
  sed -i "s|manifestVersion: .*$|manifestVersion: ${MANIFEST}|" "${SCRIPT_DIR}/../cne-instance.yaml"
fi

echo "$(date) INFO starting BNK deployment"
#source ${DEPLOY_DIR}040-deploy-bnk.sh
source ${DEPLOY_DIR}041-deploy-flo.sh

# Check if FLO is running, else abort
CNE_POD=$(kubectl get pods -n f5-bnk -o custom-columns=:metadata.name | grep 'flo')
kubectl wait pod  ${CNE_POD} --for=condition=Ready --namespace=f5-bnk --timeout=3s
status="${?}"
if [[ "${status}" != "0" ]]; then
  echo "DEBUG - ERROR FLO deployment failed - reported from BNK deploy script"
  LOG_FILE="/var/log/bnk-deployment.log"
  echo "$(date) ERROR FLO failed ${CNE_POD}" | sudo tee -a "${LOG_FILE}"
  kubectl get events -n f5-bnk --field-selector type=Warning   | grep -i "secret" | grep -i "not found"
  return 1
fi

source ${DEPLOY_DIR}042-deploy-bnk.sh
echo "$(date) INFO deploying services"
source ${DEPLOY_DIR}050-deploy-red-gateway.sh
source ${DEPLOY_DIR}060-deploy-blue-gateway.sh
source ${DEPLOY_DIR}070-deploy-egress.sh
source ${DEPLOY_DIR}080-deploy-bgp.sh

# wait for 10s to allow configuration to be loaded
sleep 10

 #source ${DEPLOY_DIR}090-deploy-bnk-fw.sh
source ${DEPLOY_DIR}100-deploy-analytics.sh

# wait for 10s to allow configuration to be loaded
sleep 10
echo "$(date) INFO testing..."

source ${SCRIPT_DIR}test.sh

