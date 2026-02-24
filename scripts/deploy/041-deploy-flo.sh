#! /bin/bash

## 041-deploy-flo.sh
echo "## 041-deploy-flo.sh"

cne-version () { bash ${HOME}/udf-cne/cne-tools/bin/cne-version.sh "$@" ; } # call directly in case cne-tools not available

# Deploy the correct version of FLO based on manifest in cne-instance.yaml

MANIFEST="$(grep -v '^[[:space:]]*#' cne-instance.yaml | grep 'manifestVersion:' | sed -E 's/.*manifestVersion:[[:space:]]*"?([^"]*)"?/\1/')"

case "${MANIFEST}" in
  2.0.0-1.7.8-0.3.37)           
    FLO_VERSION="v1.7.8-0.3.37"
    SECRET="GA"
    ;;
  2.0.0-EHF-1-1.7.8-0.3.39)
    FLO_VERSION="v1.7.8-0.3.37"
    SECRET="GA"
    ;;
  2.1.0-3.1736.1-0.1.27)
    FLO_VERSION="v1.198.4-0.1.36"
    SECRET="GA"
    ;;
  2.1.0-EHF-1-3.1736.1-0.1.63)
    FLO_VERSION="v1.198.4-0.1.42"
    SECRET="NON-GA"
    ;;
  2.1.0-EHF-2-3.1736.1-0.1.65)
    FLO_VERSION="v1.198.4-0.1.42"
    SECRET="NON-GA"
    ;;
  2.1.0-EHF-3-3.1736.1-0.1.80)
    FLO_VERSION="v1.198.4-0.1.42"
    SECRET="NON-GA"
    ;;
  2.2.0-3.2226.0-0.0.385)
    FLO_VERSION="v2.9.27-0.2.10"
    SECRET="GA"
    ;;
  *)                            
    echo "Unknown CNEinstance manifest: ${MANIFEST}"
    exit 1
    ;;
esac

check_webhook_ready() {
    echo "Checking cert-manager webhook health..."
    
    # Check if webhook pod is running
    if ! kubectl get pods -n cert-manager -l app=webhook | grep -q "Running"; then
        echo "ERROR: cert-manager webhook pod is not running"
        exit 1
    fi
    
    # Check if webhook has endpoints
    if ! kubectl get endpoints -n cert-manager cert-manager-webhook | grep -q -v "^NAME"; then
        echo "ERROR: cert-manager webhook has no endpoints"
        exit 1
    fi
    
    # Wait for webhook to be ready
    if ! kubectl wait --for=condition=ready pod -l app=webhook -n cert-manager --timeout=60s 2>/dev/null; then
        echo "ERROR: cert-manager webhook is not ready"
        exit 1
    fi
    
    echo "cert-manager webhook is healthy"
}

# Main script
check_webhook_ready

# note documentation shows install of flo before CRDs
cat cne_pull_64.json | helm registry login -u _json_key_base64 --password-stdin repo.f5.com

# CRDs must be deployed manually prior to v2.1
# helm upgrade --install f5-spk-crds-common oci://repo.f5.com/charts/f5-spk-crds-common --version 8.7.4 -f crd-values.yaml # installed with FLO in v2.1
# helm upgrade --install f5-spk-crds-service-proxy oci://repo.f5.com/charts/f5-spk-crds-service-proxy --version 8.7.4 -f crd-values.yaml # installed with FLO in v2.1

echo "Deploying FLO ${FLO_VERSION} [${SECRET}]"

if [[ "${SECRET}" == "GA" ]]; then
  echo "DEBUG: using GA secret"
  kubectl apply -f far-secret.yaml -n f5-bnk
  kubectl apply -f far-secret.yaml -n f5-utils
else
  echo "DEBUG: using non-GA secret"
  cat non-ga-prod-pull-key.json | helm registry login -u _json_key_base64 --password-stdin repo.f5.com
  kubectl apply -f far-secret-ehf.yaml -n f5-bnk
  kubectl apply -f far-secret-ehf.yaml -n f5-utils
fi

helm upgrade --install flo oci://repo.f5.com/charts/f5-lifecycle-operator --version "${FLO_VERSION}" -f flo-values.yaml -n f5-bnk

echo "waiting for flo"
kubectl wait pod --all --for=condition=Ready --namespace=f5-bnk --timeout=60s
if [[ "${?}" != "0" ]]; then
  echo "FLO install failed - certificate failure"
#  kubectl apply -f qkview-cert-workaround.yaml -n f5-bnk
#  kubectl wait pod --all --for=condition=Ready --namespace=f5-bnk --timeout=60s
fi
