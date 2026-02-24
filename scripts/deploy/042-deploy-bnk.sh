#! /bin/bash

## 042-deploy-bnk.sh
echo "## 042-deploy-bnk.sh"

wait_for () { source ${HOME}/udf-cne/cne-tools/bin/wait_for.sh "$@" ; } # call directly in case cne-tools not available
cwc-api () { bash ${HOME}/udf-cne/cne-tools/bin/cwc-api.sh --quiet "$@" ; } # call directly in case cne-tools not available
cne-version () { bash ${HOME}/udf-cne/cne-tools/bin/cne-version.sh "$@" ; } # call directly in case cne-tools not available


# Deploy the correct version of BNK based on manifest in cne-instance.yaml
MANIFEST="$(grep -v '^[[:space:]]*#' cne-instance.yaml | grep 'manifestVersion:' | sed -E 's/.*manifestVersion:[[:space:]]*"?([^"]*)"?/\1/')"

case "${MANIFEST}" in
  2.0.0-1.7.8-0.3.37)           
    SECRET="GA"
    ;;
  2.0.0-EHF-1-1.7.8-0.3.39)
    SECRET="NON-GA"
    ;;
  2.1.0-3.1736.1-0.1.27)
    SECRET="GA"
    ;;
  2.1.0-EHF-1-3.1736.1-0.1.63)
    SECRET="NON-GA"
    ;;
  2.1.0-EHF-2-3.1736.1-0.1.65)
    SECRET="NON-GA"
    ;;
  2.1.0-EHF-3-3.1736.1-0.1.80)
    SECRET="NON-GA"
    ;;
  2.2.0-3.2226.0-0.0.385)
    SECRET="GA"
    ;;
  *)                            
    echo "Unknown CNEinstance manifest: ${MANIFEST}"
    exit 1
    ;;
esac

if [[ "${MANIFEST}" == "2.0.0-EHF-1-1.7.8-0.3.39" ]]; then
  : # required if kubectl removed
fi

#SECRET="$(cne-version --secret --manifest="${MANIFEST}")"
echo "Deploying BNK ${MANIFEST} [${SECRET}] cne-version info:$(cne-version --secret --manifest="${MANIFEST}" --quiet)"

if [[ "${SECRET}" == "GA" ]]; then
  kubectl apply -f far-secret.yaml -n f5-bnk
  kubectl apply -f far-secret.yaml -n f5-utils
else
  kubectl apply -f far-secret-ehf.yaml -n f5-bnk
  kubectl apply -f far-secret-ehf.yaml -n f5-utils
fi

# WORKAROUND FOR USING PRODUCTION JWT WITH v2.0.0 GA - see BZ1967881 # not required for v2.1.0
# kubectl replace -f cpcl-key.yaml -n f5-utils

jku="$(cat secrets/latest.jwt | cut -d. -f1 | base64  -d | jq .jku | tr -d '"')"
if [ "${jku}" != "https://product.apis.f5.com/ee/v1/keys/jwks" ]; then
  echo "*** INTERNAL JWT - updating FLO ***"
  FLO_VERSION="$(helm list -n f5-bnk -o json | jq -r '.[] | select(.name=="flo") | .app_version')"
  helm upgrade flo oci://repo.f5.com/charts/f5-lifecycle-operator --version ${FLO_VERSION} --reuse-values -f flo-values-cpcl-internal.yaml -n f5-bnk
  # kubectl delete -f cpcl-key.yaml -n f5-utils
fi

kubectl apply -f cne-instance.yaml -n f5-bnk

echo "***** $(date) CNEinstance configured"

# configure Maintenance mode and patch resources (note: BNK does not start when maintenance mode configured in FLO CR)
# - Maintenance mode is required to reduce resources required by pods for lab tests
# wait for TMM to start - do not deploy any CRs until TMM is ready
# create internal vlan, wait for internal vlan to be programmed

kubectl wait --for=create daemonset f5-tmm -n f5-bnk --timeout=60s

#echo "***** $(date) Waiting for TMM to run" # from v2.2, CWC needs to be licenced before TMM will report ready
#kubectl wait --for=condition=Ready pod -l app=f5-tmm -n f5-bnk --timeout=300s

echo "***** $(date) Waiting for CSRC to run"
# manually start csrc as FLO does not do this in v2.0.0-GA  # not required for v2.1.0
# kubectl apply -f csrc.yaml -n f5-utils # installed by FLO in v2.1.0-GA
kubectl wait --for=condition=Ready pod -l name=f5-spk-csrc -n f5-utils --timeout=120s

# fix in v2.1.0 - manually configure management route via TMM 169.254.1.1
# kubectl apply -f calico-static-route.yaml -n f5-bnk

# Deploy Gateway API CRDs # not required for v2.1.0
# kubectl apply -f https://github.com/kubernetes-sigs/gateway-api/releases/download/v1.2.0/standard-install.yaml # installed with FLO in v2.1
kubectl wait --for=condition=established crd/gatewayclasses.gateway.networking.k8s.io --timeout=60s
kubectl apply -f gatewayclass.yaml # not namespaced

kubectl wait --for=jsonpath='{.status.conditions[?(@.type=="CwcAvailable")].status}'=True --timeout=300s cneinstances.k8s.f5.com/f5-cne-controller -n f5-bnk

echo "***** $(date) Waiting for CWC to start"
cwc="$(kubectl get pods -n f5-utils | grep "^f5-spk-cwc-" | cut -f1 -d' ')"
kubectl wait --for=condition=Ready pod ${cwc} -n f5-utils --timeout=500s

set +u

echo "manifest: ${MANIFEST}"

kubectl wait --for=jsonpath='{.status.conditions[?(@.type=="CwcAvailable")].status}'=True --timeout=10s cneinstances.k8s.f5.com/f5-cne-controller -n f5-bnk

wait_for_command () {
  if [[ "$(cwc-api status -o /dev/null -w "%{http_code}")" == "200" ]]; then
    echo "CWC running"
  fi
}
wait_for "CWC to be active" 

wait_for_command () {
  if [[ "$(cwc-api | jq '.InitialRegistrationStatus.LicenseStatus.State' | tr -d '"')" != "Device Registration In Progress" ]]; then
    echo "CWC registration complete"
  fi
}
wait_for "CWC device registration" 

wait_for_command () {
  if [[ "$(cwc-api | jq '.TelemetryStatus.NextReport.State' | tr -d '"')" == "Telemetry In Progress" ]]; then
    echo "CWC licenced"
  elif [[ "$(cwc-api | jq '.InitialRegistrationStatus.LicenseStatus.State' | tr -d '"')" == "Device Registration Failed" ]]; then
    cwc-api reactivate -X POST -d@/home/ubuntu/udf-cne/bnk-2.2.0-ga/secrets/latest.jwt 

  fi
}
wait_for "CWC to be licenced" 

echo "***** $(date) Waiting for TMM to run" # from v2.2, CWC needs to be licenced before TMM will report ready
kubectl wait --for=condition=Ready pod -l app=f5-tmm -n f5-bnk --timeout=300s

kubectl apply -f internal-vlan.yaml -n f5-bnk
kubectl wait --for=condition=Programmed f5-spk-vlans.k8s.f5net.com internal-vlan -n f5-bnk --timeout=120s

echo "***** $(date) BNK is READY"

