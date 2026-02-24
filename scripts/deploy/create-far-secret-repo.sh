#!/bin/bash
set -e

# Usage: ./create-far-secret-repo.sh <key_file> <repo>
# Example: ./create-far-secret-repo.sh cne_pull_64.json repo.f5.com

KEY_FILE="$1"
REPO="$2"
SECRET_NAME="far-secret"

if [[ -z "$KEY_FILE" || -z "$REPO" ]]; then
  echo "Usage: $0 <key_file> <repo>"
  exit 1
fi

if [[ ! -f "$KEY_FILE" ]]; then
  echo "Error: Key file '$KEY_FILE' not found."
  exit 1
fi

# Read and encode the service account key
SERVICE_ACCOUNT_KEY=$(cat "$KEY_FILE")
SERVICE_ACCOUNT_K8S_SECRET=$(echo "_json_key_base64:${SERVICE_ACCOUNT_KEY}" | base64 -w 0)

# Output the secret YAML to stdout
cat << EOF
---
apiVersion: v1
kind: Secret
metadata:
  name: ${SECRET_NAME}
data:
  .dockerconfigjson: $(echo "{\"auths\": {\
\"${REPO}\":\
{\"auth\": \"${SERVICE_ACCOUNT_K8S_SECRET}\"}}}" | base64 -w 0)
type: kubernetes.io/dockerconfigjson
EOF