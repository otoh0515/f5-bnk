#! /bin/bash

## 014-deploy-host-conf.sh
echo "## 014-deploy-host-conf.sh"

nodes=$(kubectl get nodes --no-headers | awk '{print $1}')

echo "Checking node readiness status..."

for node in $nodes; do
    status=$(kubectl get node "$node" --no-headers | awk '{print $2}')
    if [[ "$status" != "Ready" ]]; then
        echo "Node $node is not ready - restarting node"
        ssh ${node} sudo systemctl restart containerd
        ssh ${node} sudo systemctl restart kubelet
    else
        echo "Node $node is ready"
    fi
done

echo "Waiting for all nodes to be ready..."
if ! kubectl wait --for=condition=Ready nodes --all --timeout=300s; then
    echo "timeout"
else
    echo "All nodes are ready"
fi

# Enable NFS on Node1
# Not required if NFS is deployed directly on Kuberentes

#ssh node1 sudo apt update
#ssh node1 sudo apt install nfs-kernel-server -y
#ssh node1 sudo mkdir -p /mnt/nfs
#ssh node1 sudo chown nobody:nogroup /mnt/nfs

# workaround for Grafana
#ssh node1 sudo chmod -R 777 /mnt/nfs

#ssh node1 "echo '/mnt/nfs  *(rw,sync,no_subtree_check,no_root_squash)' | sudo tee -a /etc/exports > /dev/null"
#ssh node1 sudo exportfs -ra
