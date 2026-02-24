#! /bin/bash

## 023-remove-node-conf.sh
echo "## 023-remove-node-conf.sh"

# use Containerised NFS

# delete PVs

echo "Removing NFS PVCs"

kubectl get pvc --all-namespaces -o jsonpath='{range .items[?(@.spec.storageClassName=="nfs")]}{.metadata.namespace}{" "}{.metadata.name}{"\n"}{end}' | \
while read ns pvc; do
  echo "Deleting PVC $pvc in namespace $ns"
  kubectl delete pvc "$pvc" -n "$ns"
done

#echo "Removing NFS PVs"
#for pv in $(kubectl get pv -o jsonpath='{.items[?(@.spec.storageClassName=="nfs")].metadata.name}'); do
#  kubectl patch pv "${pv}" -p '{"metadata":{"finalizers":[]}}' --type=merge
#  kubectl delete pv "${pv}" --grace-period=0 --force
#done

#kubectl delete -f storageclass-host-nfs.yaml 

kubectl delete -f storageclass.yaml 
kubectl delete -f nfs.yaml
kubectl delete -f https://raw.githubusercontent.com/rancher/local-path-provisioner/master/deploy/local-path-storage.yaml

helm uninstall csi-driver-nfs --namespace kube-system
helm repo remove csi-driver-nfs

kubectl get pv | grep Released | awk '{print $1}' | xargs kubectl delete pv

kubectl annotate node node2 k8s.ovn.org/node-primary-ifaddr-
kubectl annotate node node3 k8s.ovn.org/node-primary-ifaddr-
kubectl annotate node node4 k8s.ovn.org/node-primary-ifaddr-
kubectl annotate node node5 k8s.ovn.org/node-primary-ifaddr-

kubectl delete -f network-attachments.yaml -n f5-bnk

# workaround for stuck vlans
#kubectl patch f5spkvlan.k8s.f5net.com red-vlan -n f5-bnk -p '{"metadata":{"finalizers":[]}}' --type=merge
#kubectl patch f5spkvlan.k8s.f5net.com blue-vlan -n f5-bnk -p '{"metadata":{"finalizers":[]}}' --type=merge
#kubectl patch f5spkvlan.k8s.f5net.com internal-vlan -n f5-bnk -p '{"metadata":{"finalizers":[]}}' --type=merge
#kubectl patch f5spkvlan.k8s.f5net.com external-vlan -n f5-bnk -p '{"metadata":{"finalizers":[]}}' --type=merge

# kubectl delete ns f5-bnk
#
# kubectl get namespace f5-bnk -o json | tr -d "\n" | sed "s/\"finalizers\": \[[^]]\+\]/\"finalizers\": []/" | kubectl replace --raw /api/v1/namespaces/${NS}/finalize -f -
# kubectl delete ns f5-bnk


