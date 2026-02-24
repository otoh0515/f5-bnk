#! /bon/bash

## 013-remove-router-conf.sh
echo "## 013-remove-router-conf.sh"

export DEFAULT_PASSWORD="HelloUDF"
export VYOS_SCRIPT="/opt/vyatta/etc/functions/script-template"
CREDS="vyos@router1"
ssh "${CREDS}" 'vbash -s' <<EOF
source ${VYOS_SCRIPT}
# router1
configure
delete interfaces ethernet eth1 vif 201
delete interfaces ethernet eth1 vif 202
delete interfaces ethernet eth2 vif 30
delete protocols static 
delete protocols bgp
commit
save
EOF

export DEFAULT_PASSWORD="HelloUDF"
export VYOS_SCRIPT="/opt/vyatta/etc/functions/script-template"
CREDS="vyos@router2"
ssh "${CREDS}" 'vbash -s' <<EOF
source ${VYOS_SCRIPT}
# router2
configure
delete protocols static 
commit
save
EOF