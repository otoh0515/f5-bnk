#!/bin/bash

# PRODUCTION Create a file with content downloaded from devrepo.f5.com (To be replaced with repo.f5.com when sharing outside F5)
SERVICE_ACCOUNT_KEY=$(cat cne_pull_64.json)
REPO="repo.f5.com"

# link to new script added for compatability
source scripts/deploy/create-far-secret-repo.sh cne_pull_64.json ${REPO} > far-secret.yaml
exit 0

# DEV Create a file with content downloaded from devrepo.f5.com (To be replaced with repo.f5.com when sharing outside F5)
#SERVICE_ACCOUNT_KEY=$(cat dev_pull_64.json)
#REPO="devrepo.f5.com"

# Create the SERVICE_ACCOUNT_K8S_SECRET variable by appending "_json_key_base64:" to the base64 encoded SERVICE_ACCOUNT_KEY
SERVICE_ACCOUNT_K8S_SECRET=$(echo "_json_key_base64:${SERVICE_ACCOUNT_KEY}" | base64 -w 0)

# Create the secret.yaml file with the provided content
cat << EOF > far-secret.yaml
---
apiVersion: v1
kind: Secret
metadata:
  name: far-secret
data:
  .dockerconfigjson: $(echo "{\"auths\": {\
\"${REPO}\":\

{\"auth\": \"${SERVICE_ACCOUNT_K8S_SECRET}\"}}}" | base64 -w 0)
type: kubernetes.io/dockerconfigjson
EOF
