#! /bin/bash

## 021-deploy-node-labels.sh
echo "## 021-deploy-node-lables.sh"

kubectl taint node node4 dpu=true:NoSchedule
kubectl taint node node5 dpu=true:NoSchedule
kubectl label node node1 app=f5-control
kubectl label node node2 app=workload
kubectl label node node3 app=workload
kubectl label node node4 app=f5-tmm
kubectl label node node5 app=f5-tmm
