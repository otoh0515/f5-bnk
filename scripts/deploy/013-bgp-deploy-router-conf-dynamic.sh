#! /bin/bash

## 013-bgp-deploy-router-conf-dynamic.sh
echo "## 013-bgp-deploy-router-conf-dynamic.sh"

### this script creates/updates Access-router to remove /32 static routes
### BGP /32 routes should take preference over /24 static routes
### delete the /24 if necessary to confirm BGP is working 

### export DEFAULT_PASSWORD="HelloUDF"
export VYOS_SCRIPT="/opt/vyatta/etc/functions/script-template"
CREDS="vyos@router1"
ssh "${CREDS}" 'vbash -s' <<EOF
source ${VYOS_SCRIPT}
# router1
configure
set interfaces ethernet eth1 vif 201 address 10.2.201.5/24
set interfaces ethernet eth1 vif 202 address 10.2.202.5/24
set interfaces ethernet eth2 vif 30 address 10.2.30.5/24
set protocols static route 172.16.201.0/24 next-hop 10.2.201.201
set protocols static route 172.16.202.0/24 next-hop 10.2.202.202
# delete static /32 routes to use BGP routes
delete protocols static route 172.16.201.100/32
delete protocols static route 172.16.202.100/32
delete protocols static route 172.16.201.221/32
delete protocols static route 172.16.201.222/32
delete protocols static route 172.16.201.223/32
delete protocols static route 172.16.201.224/32
set protocols bgp system-as 64521
set protocols bgp peer-group bnk-peer-group remote-as 64522
set protocols bgp peer-group bnk-peer-group address-family ipv4-unicast 
set protocols bgp peer-group bnk-peer-group update-source 10.1.10.5
set protocols bgp peer-group bnk-peer-group bfd
set protocols bgp neighbor 10.1.10.201 peer-group bnk-peer-group
set protocols bgp neighbor 10.1.10.202 peer-group bnk-peer-group
commit
save
EOF
