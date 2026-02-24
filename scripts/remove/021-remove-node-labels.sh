#! /bin/bash

## 021-remove-node-labels.sh
echo "## 021-remove-node-labels.sh"

kubectl taint node node4 dpu=true:NoSchedule-
kubectl taint node node5 dpu=true:NoSchedule-
kubectl label node node1 app-
kubectl label node node2 app-
kubectl label node node3 app-
kubectl label node node4 app-
kubectl label node node5 app-