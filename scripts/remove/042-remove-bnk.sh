#! /bin/bash

## 042-remove-bnk.sh
echo "042-remove-bnk.sh"

wait_for () { source /home/ubuntu/udf-cne/cne-tools/bin/wait_for.sh "$@" ; } # call directly in case cne-tools not available

kubectl delete -f gatewayclass.yaml
kubectl delete -f internal-vlan.yaml -n f5-bnk
kubectl delete -f cne-instance.yaml -n f5-bnk
# kubectl delete -f csrc.yaml -n f5-utils # installed by FLO in v2.1.0-GA

# fix in v2.1.0 - manually configure management route via TMM 169.254.1.1
# kubectl apply -f calico-static-route.yaml -n f5-bnk

# kubectl delete -f cpcl-key.yaml -n f5-utils


wait_for_command () {
  if [[ -z "$(kubectl get pods -n f5-bnk | grep -v "^NAME" | grep -v "operator")" ]]; then echo "no CNE pods running"; fi
}

wait_for "CNEinstance to terminate"

