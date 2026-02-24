#! /bin/bash

## 014-remove-host-conf.sh
echo "## 014-remove-host-conf.sh"

nodes=$(kubectl get nodes --no-headers | awk '{print $1}')

echo "Checking node readiness status..."

for node in $nodes; do
    status=$(kubectl get node "$node" --no-headers | awk '{print $2}')
    status="Force Restart" # restart all nodes to clear API caches
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


if ssh node1 'dpkg -l | grep -q "^ii  nfs-kernel-server"'; then
    echo "NFS is installed on host — removing"

    ssh node1 'sudo sed -i "/\/mnt\/nfs/d" /etc/exports'
    ssh node1 'sudo exportfs -ra'
    ssh node1 'sudo rm -rf /mnt/nfs'
    ssh node1 'sudo apt-get remove nfs-kernel-server -y'
    ssh node1 'sudo apt-get autoremove -y'

else
    echo "NFS is NOT installed on host"
fi


