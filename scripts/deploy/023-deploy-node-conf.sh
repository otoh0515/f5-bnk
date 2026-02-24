#! /bin/bash

## 023-deploy-node-conf.sh
echo "## 023-deploy-node-conf.sh"

helm repo add csi-driver-nfs https://raw.githubusercontent.com/kubernetes-csi/csi-driver-nfs/master/charts
helm install csi-driver-nfs csi-driver-nfs/csi-driver-nfs --namespace kube-system --set kubeletDir=/var/lib/kubelet
#kubectl apply -f storageclass-host-nfs.yaml 

# use Containerised NFS
kubectl apply -f https://raw.githubusercontent.com/rancher/local-path-provisioner/master/deploy/local-path-storage.yaml
kubectl apply -f nfs.yaml
kubectl apply -f storageclass.yaml 

kubectl patch storageclass nfs -p '{"metadata": {"annotations":{"storageclass.kubernetes.io/is-default-class":"true"}}}'
