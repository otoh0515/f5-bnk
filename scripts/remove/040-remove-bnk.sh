#! /bin/bash

## 040-remove-bnk.sh
echo "## 040-remove-bnk.sh"

# This is a shim script to remove BNK in two stages:
# first the CNE Instance, then the F5 Lifecycle Orchestrator.
# This makes it possible to deploy/remove the CNE Instance
# independently using the deployment scripts

source ${REMOVE_DIR}041-remove-flo.sh
source ${REMOVE_DIR}042-remove-bnk.sh
