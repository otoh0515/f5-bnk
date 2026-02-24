#! /bin/bash

## 090b-deploy-bnk-fw.sh
echo "## 090b-deploy-bnk-fw.sh"


wait_for () {
  DEPLOY_DIR="$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )/"
  source ${DEPLOY_DIR}wait-for.sh "${1:-}" "${2:-}"
}

echo "DEBUG: $(pwd)"
cd ~/udf-cne/bnk-2.2.0-ga

# create CR with FW enabled
# Note! needs comment to identify the correct line
sed "s|enabled: .* # firewallACL|enabled: true # firewallACL|" cne-instance.yaml > cne-fw-instance.yaml
#sed "s|enabled: .* # firewallACL|enabled: true # firewallACL|" cne-instance-EHF.yaml > cne-fw-instance.yaml
kubectl apply -f cne-fw-instance.yaml -n f5-bnk
sleep 10

# UDF optimisation: reduce the memory of certain pods
# source ${DEPLOY_DIR}091-modify-resources.sh

kubectl rollout status daemonset/f5-tmm -n f5-bnk --timeout=300s

kubectl apply -f red-fw-policy.yaml -n red
kubectl apply -f blue-fw-policy.yaml -n blue

bash ~/udf-cne/bnk-2.2.0-ga/scripts/test.sh --fw

# kubectl delete -f egress.yaml -n f5-bnk
# sleep 10
# kubectl apply -f egress.yaml -n f5-bnk
# kubectl wait --for=condition=Programmed=True f5spkegress.k8s.f5net.com/red-egress -n f5-bnk --timeout=300s

