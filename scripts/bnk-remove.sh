#! /bin/bash

SCRIPT_DIR="$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )/"
REMOVE_DIR="${SCRIPT_DIR}remove/"
source ${SCRIPT_DIR}check-auto.sh

cd ~/udf-cne/bnk-2.2.0-ga

source ${REMOVE_DIR}100-remove-analytics.sh
#source ${REMOVE_DIR}090-remove-bnk-fw.sh
source ${REMOVE_DIR}080-remove-bgp.sh
source ${REMOVE_DIR}070-remove-egress.sh
source ${REMOVE_DIR}060-remove-blue-gateway.sh
source ${REMOVE_DIR}050-remove-red-gateway.sh
source ${REMOVE_DIR}042-remove-bnk.sh
source ${REMOVE_DIR}041-remove-flo.sh
#source ${REMOVE_DIR}040-remove-bnk.sh
