#! /bin/bash

## 030-remove-dpu-conf.sh
echo "## 030-remove-dpu-conf.sh"

echo "Removing macvlan-host from Node 4"
ssh ubuntu@node4 sudo ip route del 10.1.20.0/24 dev macvlan-host src 10.1.20.21 metric 10
ssh ubuntu@node4 sudo ip link set macvlan-host down
ssh ubuntu@node4 sudo ip link del macvlan-host

echo "Removing macvlan-host from Node 5"
ssh ubuntu@node5 sudo ip route del 10.1.20.0/24 dev macvlan-host src 10.1.20.22 metric 10
ssh ubuntu@node5 sudo ip link set macvlan-host down
ssh ubuntu@node5 sudo ip link del macvlan-host

ssh ubuntu@node2 'sudo rm /etc/netplan/70-netplan-set.yaml'
ssh ubuntu@node3 'sudo rm /etc/netplan/70-netplan-set.yaml'
ssh ubuntu@node4 'sudo rm /etc/netplan/70-netplan-set.yaml'
ssh ubuntu@node5 'sudo rm /etc/netplan/70-netplan-set.yaml'

ssh ubuntu@node2 'sudo netplan apply'
ssh ubuntu@node3 'sudo netplan apply'
ssh ubuntu@node4 'sudo netplan apply'
ssh ubuntu@node5 'sudo netplan apply'

calicoctl --allow-version-mismatch patch node node2 -p '{"spec":{"bgp":{"ipv4Address":"'"$(dig +short node2)/24"'"}}}' --type=merge   
calicoctl --allow-version-mismatch patch node node3 -p '{"spec":{"bgp":{"ipv4Address":"'"$(dig +short node3)/24"'"}}}' --type=merge   
calicoctl --allow-version-mismatch patch node node4 -p '{"spec":{"bgp":{"ipv4Address":"'"$(dig +short node4)/24"'"}}}' --type=merge   
calicoctl --allow-version-mismatch patch node node5 -p '{"spec":{"bgp":{"ipv4Address":"'"$(dig +short node5)/24"'"}}}' --type=merge   

