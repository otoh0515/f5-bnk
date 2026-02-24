#!/bin/bash

# scripts moved to ~/udf-cne/cne-tools/bin

# set -euo pipefail # use for debugging only

usage() {
  echo "Usage: $0 <crd-domain-suffix> [--delete] [--force] [--crd] [--verbose]"
  echo "Use 'all' to process all known CRD suffixes."
  exit 1
}

help() {
  echo "Usage: $0 <crd-domain-suffix> [--delete] [--force] [--crd]"
  echo
  echo "Examples:"
  echo "  $0 all --crd"
  echo "  $0 k8s.f5.com fic.f5.com --delete --force"
  echo
  echo "using 'all' for <crd-domain-suffix> will process these CRD suffixes:"
  echo "  ${CRD_SUFFIXES[*]}"
  echo
  echo "Options:"
  echo "  --crd       List CRDs (in addition to CRs)"
  echo "  --delete    Delete CRs (and CRDs if --crd is set)"
  echo "  --force     Remove finalizers when deleting"
  exit 1
}

echo_v() {
  if [[ "${VERBOSE:-false}" == true ]]; then
    echo "$@"
  fi
}

CRD_SUFFIXES=("k8s.f5net.com" "k8s.f5.com" "fic.f5.com" "gateway.networking.k8s.io")

# Initialize flags
DELETE=false
FORCE=false
CRD=false
VERBOSE=false
CRD_DOMAINS=()

# Parse all arguments (order-independent)
while [[ $# -gt 0 ]]; do
  arg="$1"
  case "$arg" in
    --delete)       DELETE=true ;;
    --force)        FORCE=true ;;
    --crd|--crds)   CRD=true ;;
    -v|--verbose)   VERBOSE=true ;;
    -h|--help)      help ;;
    all)            CRD_DOMAINS+=("${CRD_SUFFIXES[@]}") ;;
    -*|--*)         echo "Unknown option: $arg"; usage ;;
    *)              CRD_DOMAINS+=("$arg") ;;
  esac
  shift
done

# Ensure at least one domain suffix was provided
if [[ ${#CRD_DOMAINS[@]} -eq 0 ]]; then
  usage
fi

for CRD_DOMAIN in "${CRD_DOMAINS[@]}"; do
  crds=$(kubectl get crds -o json | jq -r --arg suffix "$CRD_DOMAIN" \
    '.items[] | select(.spec.group | endswith($suffix)) | .metadata.name')

  echo_v "===================================================="
  echo_v "DOMAIN: ${CRD_DOMAIN}"
  echo_v "----------------------------------------------------"
  if [[ -z "$crds" ]]; then
    result="No CRDs found in '$CRD_DOMAIN'"
  fi

  for crd in $crds; do
    crd_json=$(kubectl get crd "$crd" -o json)
    kind=$(echo "$crd_json" | jq -r '.spec.names.kind')
    group=$(echo "$crd_json" | jq -r '.spec.group')
    version=$(echo "$crd_json" | jq -r '.spec.versions[] | select(.served == true) | .name' | head -n1)
    plural=$(echo "$crd_json" | jq -r '.spec.names.plural')
    resource="${plural}.${group}"
    crs=$(kubectl get "$resource" --all-namespaces -o json 2>/dev/null | jq -c '.items[]')
    if [[ -n "$crs" ]]; then
      echo "$crs" | while read -r cr; do
        name=$(echo "$cr" | jq -r '.metadata.name')
        namespace=$(echo "$cr" | jq -r '.metadata.namespace')
        result="${resource}:"
        if $DELETE; then
          if $FORCE; then
            if [[ $(kubectl get "$resource" "$name" -n "$namespace" -o jsonpath='{.metadata.finalizers}') != "[]" && $(kubectl get "$resource" "$name" -n "$namespace" -o jsonpath='{.metadata.finalizers}') != "" ]]; then
              kubectl patch "$resource" "$name" -n "$namespace" --type=merge -p '{"metadata":{"finalizers":[]}}'
              sleep 2
            fi
            result="${result} ${namespace}/${name} force"
          fi
          kubectl delete "$resource" "$name" -n "$namespace" --ignore-not-found
          result="${result} deleted"
          echo_v "${result}"
        else
          echo "${resource}: ${namespace}/${name}"
        fi
      done
    else
      echo_v "${resource}: no CRs found"
    fi

    if $CRD; then
      result="${crd}"
      if $DELETE; then
        if $FORCE; then
          if [[ $(kubectl get crd "$crd" -o jsonpath='{.metadata.finalizers}') != "[]" && $(kubectl get crd "$crd" -o jsonpath='{.metadata.finalizers}') != "" ]]; then
            kubectl patch crd "$crd" --type=merge -p '{"metadata":{"finalizers":[]}}'
            sleep 2
          fi
          result="${result} force "
        fi
        kubectl delete crd "$crd"
        result="${result} deleted"
      fi
      # echo "crd: ${result}"
    fi
  done
  echo_v "----------------------------------------------------"
done

echo_v "done"


