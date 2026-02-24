#! /bin/bash

## 091-modify-resources.sh
echo "## 091-modify-resources.sh"

# f5-tmm blobd 4Gi --> 500Mi
# f5-observer 5Gi --> 500Mi
# f5-observer-receiver 5Gi --> 500Mi
# f5-dssm-db 2Gi --> 500Mi
# f5-dssm-sentinel 2Gi --> 500Mi

wait_for () { source /home/ubuntu/udf-cne/cne-tools/bin/wait_for.sh "$@" ; } # call directly in case cne-tools not available

wait_for_command () {
  BLOBD_MEMORY_REQUEST="500Mi"
  blobd_c=$(kubectl get daemonset f5-tmm -n f5-bnk -o json 2> /dev/null | jq '.spec.template.spec.containers | map(.name) | index("blobd")')
  blobd_memory="$(kubectl get daemonset f5-tmm -n f5-bnk -o json | jq ".spec.template.spec.containers[${blobd_c}].resources.requests.memory" | tr -d '"')"  
  if [ "${blobd_memory}" != "${BLOBD_MEMORY_REQUEST}" ]; then
    kubectl patch cneinstance.k8s.f5.com f5-cne-controller -n f5-bnk --type=merge -p '{"spec": {"advanced": {"maintenanceMode": {"enabled": true}}}}' 2>&1> /dev/null
    kubectl patch daemonset f5-tmm -n f5-bnk --type=json -p "[{\"op\": \"replace\",\"path\": \"/spec/template/spec/containers/${blobd_c}/resources/requests/memory\",\"value\": \"${BLOBD_MEMORY_REQUEST}\"}]" 2>&1> /dev/null
  else
    echo "TMM patched"
  fi
}

wait_for "TMM resources to be modified"

kubectl patch cneinstance.k8s.f5.com f5-cne-controller -n f5-bnk --type=merge -p '{"spec": {"advanced": {"maintenanceMode": {"enabled": true}}}}' 2>&1> /dev/null

kubectl patch statefulset f5-observer -n f5-bnk --type='json' -p='[
  {"op": "replace", "path": "/spec/template/spec/containers/0/resources/limits/memory", "value": "500Mi"},
  {"op": "replace", "path": "/spec/template/spec/containers/0/resources/requests/memory", "value": "500Mi"}
]'

kubectl patch statefulset f5-observer-receiver -n f5-bnk --type='json' -p='[
  {"op": "replace", "path": "/spec/template/spec/containers/0/resources/limits/memory", "value": "500Mi"},
  {"op": "replace", "path": "/spec/template/spec/containers/0/resources/requests/memory", "value": "500Mi"}
]'

kubectl scale statefulset f5-dssm-db -n f5-utils --replicas=0
kubectl scale statefulset f5-dssm-sentinel -n f5-utils --replicas=0

kubectl patch statefulset f5-dssm-db -n f5-utils --type='json' -p='[
  {"op": "replace", "path": "/spec/template/spec/containers/0/resources/limits/memory", "value": "500Mi"},
  {"op": "replace", "path": "/spec/template/spec/containers/0/resources/requests/memory", "value": "500Mi"}
]'

kubectl patch statefulset f5-dssm-sentinel -n f5-utils --type='json' -p='[
  {"op": "replace", "path": "/spec/template/spec/containers/0/resources/limits/memory", "value": "500Mi"},
  {"op": "replace", "path": "/spec/template/spec/containers/0/resources/requests/memory", "value": "500Mi"}
]'

kubectl scale statefulset f5-dssm-db -n f5-utils --replicas=3
kubectl scale statefulset f5-dssm-sentinel -n f5-utils --replicas=3

kubectl wait --for=condition=ready pod -l app=f5-dssm-db -n f5-utils --timeout=300s
kubectl wait --for=condition=ready pod -l app=f5-dssm-sentinel -n f5-utils --timeout=300s
