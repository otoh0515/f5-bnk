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
sed -i "s|manifestVersion: .*$|manifestVersion: ${MANIFEST}|" "${SCRIPT_DIR}/../cne-instance.yaml"

echo "$(date) INFO starting BNK deployment"
source ${DEPLOY_DIR}040-deploy-bnk.sh
#source ${DEPLOY_DIR}041-deploy-flo.sh
#source ${DEPLOY_DIR}042-deploy-bnk.sh
echo "$(date) INFO deploying services"
source ${DEPLOY_DIR}050-deploy-red-gateway.sh
source ${DEPLOY_DIR}060-deploy-blue-gateway.sh
source ${DEPLOY_DIR}070-deploy-egress.sh
source ${DEPLOY_DIR}080-deploy-bgp.sh

# wait for 10s to allow configuration to be loaded
sleep 10
echo "$(date) INFO testing... [PRE-RESIZING]"

source ${SCRIPT_DIR}test.sh

source ${DEPLOY_DIR}090-deploy-bnk-fw.sh
source ${DEPLOY_DIR}100-deploy-analytics.sh

# wait for 10s to allow configuration to be loaded
sleep 10
echo "$(date) INFO testing..."

source ${SCRIPT_DIR}test.sh --fw

