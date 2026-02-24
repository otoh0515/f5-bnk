#! /bin/bash

## 030-deploy-dpu-conf.sh
echo "## 030-deploy-dpu-conf.sh"

echo "setting up internal connections between DPUs and Servers"
# note: nodes 4/5 are intented to be illustrative of DPU deployment 
# however, in reality, all nodes in this lab are Ubuntu x86

# updates netplan config to create GRE tunnel between DPU and Server to represent PCIE connection

# node4 (dpu1) -- pcie -- node2 (server1)
ssh ubuntu@node2 'sudo tee /etc/netplan/70-netplan-set.yaml > /dev/null' <<EOF
network:
  version: 2
  ethernets:
    ens6:
      dhcp4: true
  tunnels:
      pcie:
        mode: gretap
        remote: 10.1.110.11
        local: 10.1.110.13
        ttl: 255
        addresses:
          - 10.1.20.13/24
        dhcp4: no
EOF

ssh ubuntu@node4 'sudo tee /etc/netplan/70-netplan-set.yaml > /dev/null' <<EOF
network:
  version: 2
  renderer: networkd
  ethernets:
    ens6:
      dhcp4: true
    ens7:
      dhcp4: false
    ens8:
      dhcp4: true
  bridges:
    br0:
      interfaces:
        - ens7
        - pcie
      addresses:
        - 10.1.20.11/32
      dhcp4: no
      optional: true
  tunnels:
    pcie:
      mode: gretap
      remote: 10.1.110.13
      local: 10.1.110.11
      ttl: 255
EOF

# node5 (dpu2) -- pcie -- node3 (server2)
ssh ubuntu@node3 'sudo tee /etc/netplan/70-netplan-set.yaml > /dev/null' <<EOF
network:
  version: 2
  ethernets:
    ens6:
      dhcp4: true
  tunnels:
      pcie:
        mode: gretap
        remote: 10.1.120.12
        local: 10.1.120.14
        ttl: 255
        addresses:
          - 10.1.20.14/24
        dhcp4: no
EOF

ssh ubuntu@node5 'sudo tee /etc/netplan/70-netplan-set.yaml > /dev/null' <<EOF
network:
  version: 2
  renderer: networkd
  ethernets:
    ens6:
      dhcp4: true
    ens7:
      dhcp4: false
    ens8:
      dhcp4: true
  bridges:
    br0:
      interfaces:
        - ens7
        - pcie
      addresses:
        - 10.1.20.12/32
      dhcp4: no
      optional: true
  tunnels:
    pcie:
      mode: gretap
      remote: 10.1.120.14
      local: 10.1.120.12
      ttl: 255
EOF

echo "Updating networking in Node 2"
ssh node2 'sudo chmod 600 /etc/netplan/70-netplan-set.yaml && sudo netplan apply'

echo "Updating networking in Node 3"
ssh node3 'sudo chmod 600 /etc/netplan/70-netplan-set.yaml && sudo netplan apply'

echo "Updating networking in Node 4"
ssh node4 'sudo chmod 600 /etc/netplan/70-netplan-set.yaml && sudo netplan apply'

echo "Updating networking in Node 5"
ssh node5 'sudo chmod 600 /etc/netplan/70-netplan-set.yaml && sudo netplan apply'


# macvlan is not supported in netplan, apply it directly
# macvlan-host configuration is required to provide connectivity from TMM internal interface to same node
# this configuration will not survive a reboot

# macvlan-host is added to the underlying internal interfaces (in this case, it is br0)
# IMPORTANT: the underlying interface must be configured with a /32 address, otherwise same-node traffic will be lost

echo "Adding macvlan-host to Node 4"
ssh ubuntu@node4 sudo ip link add macvlan-host link br0 type macvlan mode bridge
ssh ubuntu@node4 sudo ip addr add 10.1.20.21/24 dev macvlan-host
ssh ubuntu@node4 sudo ip link set macvlan-host up
# ssh ubuntu@node4 sudo ip link set br0 promisc on # may be required
# ssh ubuntu@node4 sudo ip link set ens7 promisc on # may be required
ssh ubuntu@node4 sudo ip route add 10.1.20.0/24 dev macvlan-host src 10.1.20.21 metric 10

echo "Adding macvlan-host to Node 5"
ssh ubuntu@node5 sudo ip link add macvlan-host link br0 type macvlan mode bridge
ssh ubuntu@node5 sudo ip addr add 10.1.20.22/24 dev macvlan-host
ssh ubuntu@node5 sudo ip link set macvlan-host up
# ssh ubuntu@node5 sudo ip link set br0 promisc on # may be required
# ssh ubuntu@node5 sudo ip link set ens7 promisc on # may be required
ssh ubuntu@node5 sudo ip route add 10.1.20.0/24 dev macvlan-host src 10.1.20.22 metric 10

# change CNI to use internal-net for dpus/servers
# --allow-version-mismatch

kubectl annotate node node2 k8s.ovn.org/node-primary-ifaddr='{"ipv4":"10.1.20.13/24"}'
kubectl annotate node node3 k8s.ovn.org/node-primary-ifaddr='{"ipv4":"10.1.20.14/24"}'
kubectl annotate node node4 k8s.ovn.org/node-primary-ifaddr='{"ipv4":"10.1.20.11/24"}'
kubectl annotate node node5 k8s.ovn.org/node-primary-ifaddr='{"ipv4":"10.1.20.12/24"}'

echo "Updating Calico"     
calicoctl --allow-version-mismatch patch node node2 -p '{"spec": {"bgp": {"ipv4Address": "10.1.20.13/24"}}}' --type=merge     
calicoctl --allow-version-mismatch patch node node3 -p '{"spec": {"bgp": {"ipv4Address": "10.1.20.14/24"}}}' --type=merge
calicoctl --allow-version-mismatch patch node node4 -p '{"spec": {"bgp": {"ipv4Address": "10.1.20.11/24"}}}' --type=merge
calicoctl --allow-version-mismatch patch node node5 -p '{"spec": {"bgp": {"ipv4Address": "10.1.20.12/24"}}}' --type=merge

sleep 30

kubectl patch felixconfiguration default --type='merge' -p='{"spec": {"externalNodesList": ["10.1.20.201","10.1.20.202"]}}'
kubectl wait felixconfiguration/default --for=jsonpath='{.spec.externalNodesList}' --timeout=30s


echo "Create Network Attachments"
kubectl apply -f network-attachments.yaml -n f5-bnk
kubectl wait -n f5-bnk networkattachmentdefinition --all --for=condition=Established --timeout=60s



kubectl wait node/node2 --for=jsonpath='{.metadata.annotations.k8s\.ovn\.org/node-primary-ifaddr}' --timeout=30s
kubectl wait node/node3 --for=jsonpath='{.metadata.annotations.k8s\.ovn\.org/node-primary-ifaddr}' --timeout=30s
kubectl wait node/node4 --for=jsonpath='{.metadata.annotations.k8s\.ovn\.org/node-primary-ifaddr}' --timeout=30s
kubectl wait node/node5 --for=jsonpath='{.metadata.annotations.k8s\.ovn\.org/node-primary-ifaddr}' --timeout=30s


NAMESPACE="kube-system"
SLEEP_INTERVAL=5
TIMEOUT=60   # seconds

echo "Checking Calico pods readiness..."

# Wait for calico-node pods to be Ready
while true; do
    NOT_READY=$(kubectl get pods -n $NAMESPACE -l k8s-app=calico-node \
        -o jsonpath='{range .items[*]}{.metadata.name}{"="}{.status.containerStatuses[0].ready}{"\n"}{end}' \
        | grep false || true)

    if [ -z "$NOT_READY" ]; then
        echo "All calico-node pods are Ready"
        break
    fi

    echo "Still waiting for calico-node pods: $NOT_READY"
    sleep $SLEEP_INTERVAL
done

echo "Checking BGP IPs for all nodes..."

for NODE in $(kubectl get nodes -o name | sed 's|node/||'); do

    # Try to get expected IP from Calico node spec
    EXPECTED_IP=$(calicoctl --allow-version-mismatch get node $NODE -o yaml | grep 'ipv4Address' | awk '{print $2}' || true)

    # If no explicit BGP IP set, fall back to InternalIP
    if [ -z "$EXPECTED_IP" ]; then
        EXPECTED_IP=$(kubectl get node $NODE -o jsonpath="{.status.addresses[?(@.type=='InternalIP')].address}")
    fi

    echo "Waiting for node $NODE to report BGP IP: $EXPECTED_IP"

    START=$(date +%s)

    while true; do
        CURRENT_IP=$(calicoctl --allow-version-mismatch get node $NODE -o yaml | grep 'ipv4Address' | awk '{print $2}' || true)

        if [ "$CURRENT_IP" == "$EXPECTED_IP" ]; then
            echo "Node $NODE BGP IP is ready"
            break
        fi

        NOW=$(date +%s)
        ELAPSED=$(( NOW - START ))

        if (( ELAPSED > TIMEOUT )); then
            echo "Timeout: Node $NODE did not report expected BGP IP within $TIMEOUT seconds"
            exit 1
        fi

        echo "Node $NODE current IP: $CURRENT_IP (elapsed ${ELAPSED}s)"
        sleep $SLEEP_INTERVAL
    done
done

#sleep 30
echo "Calico is fully ready"

