#! /bin/bash

## 090-remove-bnk-fw.sh

cd ~/udf-cne/bnk-2.2.0-ga

kubectl delete -f blue-fw-policy.yaml -n blue
kubectl delete -f red-fw-policy.yaml -n red
kubectl apply -f cne-instance.yaml -n f5-bnk
rm cne-fw-instance.yaml

kubectl rollout status daemonset/f5-tmm -n f5-bnk --timeout=300s
