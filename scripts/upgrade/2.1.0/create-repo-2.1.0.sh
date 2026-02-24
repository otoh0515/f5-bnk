#! /bin/bash

# create-repo-2.1.0.sh

# this file programmatically creates NEW_VERSION using OLD_VERSION as the source-of-truth
# as a way to track the configuration changes between versions

# Configuration
BASE_DIR=udf-cne
OLD_VERSION="2.0.0-ga"
NEW_VERSION="2.1.0-ga"
PROJECT_NAME="bnk"

OLD_PATH="${BASE_DIR}/${PROJECT_NAME}-${OLD_VERSION}"
NEW_PATH="${BASE_DIR}/${PROJECT_NAME}-${NEW_VERSION}"

echo "Creating repo for v${NEW_VERSION}"
echo "Source: ${OLD_PATH}"
echo "Target: ${NEW_PATH}"
echo ""

# Check if source directory exists
if [ ! -d "${OLD_PATH}" ]; then
    echo "ERROR: Source directory does not exist: ${OLD_PATH}"
    exit 1
fi

# Warn if target already exists
if [ -d "${NEW_PATH}" ]; then
    echo "WARNING: Target directory already exists: ${NEW_PATH}"
#    read -p "Do you want to remove it and continue? (yes/no): " confirm
#    if [ "$confirm" != "yes" ]; then
#        echo "Operation cancelled."
#        exit 0
#    fi
    echo "Removing existing directory..."
    rm -rf "${NEW_PATH}"
fi

# Create parent directory if it doesn't exist
mkdir -p "${BASE_DIR}"

# Copy files
echo "Copying files from ${OLD_VERSION} to ${NEW_VERSION}..."
cp -a "${OLD_PATH}/." "${NEW_PATH}/"

if [ $? -ne 0 ]; then
    echo "ERROR: Failed to copy files"
    exit 1
fi

echo "Copy completed successfully."

# Update paths in files
echo "Updating paths in all files..."

# Find and update paths in all text files (not just scripts)
find "${NEW_PATH}" -type f ! -path "*/\.git/*" -exec grep -l "${OLD_PATH}" {} \; 2>/dev/null | while read -r file; do
    # Check if file is a text file
    if file "$file" | grep -q text; then
        echo "  Updating: $file"
        sed -i.bak "s|${OLD_PATH}|${NEW_PATH}|g" "$file"
        # Remove backup file
        rm -f "${file}.bak"
    fi
done

echo ""
echo "Path updates completed."
echo "New repository created at: ${NEW_PATH}"

# Summary
echo ""
echo "=== Summary ==="
echo "Files copied: $(find "${NEW_PATH}" -type f | wc -l)"
echo "Directories: $(find "${NEW_PATH}" -type d | wc -l)"
echo ""
echo "Done!"

# create v2.1 based on v2.0
#cd
#rm -Rf ~/udf-cne/bnk-2.2.0-ga
#mkdir -p ~/udf-cne/bnk-2.2.0-ga
#cp -a ~/udf-cne/bnk-2.2.0-ga/. ~/udf-cne/bnk-2.2.0-ga/

# update path in all files
#find ~/udf-cne/bnk-2.2.0-ga/scripts -type f -exec sed -i "s|/udf-cne/bnk-2.2.0-ga|/udf-cne/bnk-2.2.0-ga|g" {} +

if [[ "$(ls -1 ~/udf-cne/bnk-2.2.0-ga | wc -l)" -lt 40 ]]; then
  echo "ERROR - v2.1 repo failed to create: $(ls -1 ~/udf-cne/bnk-2.2.0-ga | wc -l) items"
  sleep 36000
  exit 1
fi


# add TEEMS key to flo-values
sed -i '/^license:/,$d' ~/udf-cne/bnk-2.2.0-ga/flo-values.yaml
cat ~/udf-cne/bnk-2.2.0-ga/scripts/upgrade/2.1.0/flo-values-cpcl.yaml >> ~/udf-cne/bnk-2.2.0-ga/flo-values.yaml 
cp ~/udf-cne/bnk-2.2.0-ga/scripts/upgrade/2.1.0/flo-values-cpcl.yaml ~/udf-cne/bnk-2.2.0-ga
cp ~/udf-cne/bnk-2.2.0-ga/scripts/upgrade/2.1.0/flo-values-cpcl-internal.yaml ~/udf-cne/bnk-2.2.0-ga

# modify 041-flo script
sed -i "s|^\(helm upgrade --install f5-spk-crds-.*$\)|# \1 # installed with FLO in v2.1|" ~/udf-cne/bnk-2.2.0-ga/scripts/deploy/041-deploy-flo.sh
sed -i "s|^\(kubectl replace -f cpcl-key.yaml -n f5-utils\)|# \1 # installed with FLO in v2.1.0-GA|" ~/udf-cne/bnk-2.2.0-ga/scripts/deploy/041-deploy-flo.sh
sed -i "s|^\(kubectl delete -f cpcl-key.yaml -n f5-utils\)|# \1 # installed with FLO in v2.1.0-GA|" ~/udf-cne/bnk-2.2.0-ga/scripts/remove/041-remove-flo.sh

# modify 042-bnk script

sed -i "s|^\(.* https://github.com/kubernetes-sigs/gateway-api/releases/download/v1.2.0/standard-install.yaml.*$\)|# \1 # installed with FLO in v2.1|" ~/udf-cne/bnk-2.2.0-ga/scripts/deploy/042-deploy-bnk.sh
sed -i "s|^\(kubectl apply -f csrc.yaml -n f5-utils\)|# \1 # installed by FLO in v2.1.0-GA|" ~/udf-cne/bnk-2.2.0-ga/scripts/deploy/042-deploy-bnk.sh
sed -i "/kubectl apply -f f5-big-cne-irule.yaml/d" ~/udf-cne/bnk-2.2.0-ga/scripts/deploy/042-deploy-bnk.sh
#sed -i "s|# \(kubectl apply -f calico-static-route.yaml -n f5-bnk\)|\1|" ~/udf-cne/bnk-2.2.0-ga/scripts/deploy/042-deploy-bnk.sh # v2.1 routing fix
sed -i "s|\(kubectl replace -f cpcl-key.yaml -n f5-utils\)|# \1|" ~/udf-cne/bnk-2.2.0-ga/scripts/deploy/042-deploy-bnk.sh # remove v2.0 TEEMS fix

sed -i "s|REMOVING BZ1967881 WORKAROUND|updating FLO|" ~/udf-cne/bnk-2.2.0-ga/scripts/deploy/042-deploy-bnk.sh
sed -i "s|flo-values-bz1967881-internal.yaml|flo-values-cpcl-internal.yaml|" ~/udf-cne/bnk-2.2.0-ga/scripts/deploy/042-deploy-bnk.sh
sed -i "s|\(kubectl delete -f cpcl-key.yaml -n f5-utils\)|# \1|" ~/udf-cne/bnk-2.2.0-ga/scripts/deploy/042-deploy-bnk.sh # remove v2.0 TEEMS fix


sed -i "s|^\(.* https://github.com/kubernetes-sigs/gateway-api/releases/download/v1.2.0/standard-install.yaml.*$\)|# \1 # installed with FLO in v2.1|" ~/udf-cne/bnk-2.2.0-ga/scripts/remove/042-remove-bnk.sh
sed -i "s|^\(kubectl delete -f csrc.yaml -n f5-utils\)|# \1 # installed by FLO in v2.1.0-GA|" ~/udf-cne/bnk-2.2.0-ga/scripts/remove/042-remove-bnk.sh
sed -i "/kubectl delete -f f5-big-cne-irule.yaml/d" ~/udf-cne/bnk-2.2.0-ga/scripts/remove/042-remove-bnk.sh
#sed -i "s|# \(kubectl delete -f calico-static-route.yaml -n f5-bnk\)|\1|" ~/udf-cne/bnk-2.2.0-ga/scripts/remove/042-remove-bnk.sh # v2.1 routing fix
sed -i "s|\(kubectl delete -f cpcl-key.yaml -n f5-utils\)|# \1|" ~/udf-cne/bnk-2.2.0-ga/scripts/remove/042-remove-bnk.sh # remove v2.0 TEEMS fix

sed -i "s|manifestVersion: .*$|manifestVersion: 2.1.0-3.1736.1-0.1.27|" ~/udf-cne/bnk-2.2.0-ga/bnk-gatewayclass.yaml

# FW policy updated for v2.1 to include BNKSecPolicy CR
cp -f ~/udf-cne/bnk-2.2.0-ga/scripts/upgrade/2.1.0/red-fw-policy.yaml ~/udf-cne/bnk-2.2.0-ga
cp -f ~/udf-cne/bnk-2.2.0-ga/scripts/upgrade/2.1.0/blue-fw-policy.yaml ~/udf-cne/bnk-2.2.0-ga

# fix for routing change in v2.1
cp -f ~/udf-cne/bnk-2.2.0-ga/scripts/upgrade/2.1.0/calico-static-route.yaml ~/udf-cne/bnk-2.2.0-ga

# iRules policy updated for v2.1 to include BNKNetPolicy CR
sed -i '/^  annotations:$/{
N
/\n    k8s\.f5\.com\/irule-refs: "my-irule"$/d
}' ~/udf-cne/bnk-2.2.0-ga/blue-app-http-gateway.yaml

cp -f ~/udf-cne/bnk-2.2.0-ga/scripts/upgrade/2.1.0/blue-net-policy.yaml ~/udf-cne/bnk-2.2.0-ga

# remove files no longer required for v2.1
rm ~/udf-cne/bnk-2.2.0-ga/crd-values.yaml
rm ~/udf-cne/bnk-2.2.0-ga/csrc.yaml
rm ~/udf-cne/bnk-2.2.0-ga/f5-big-cne-irule.yaml # remove CRD

# modify iRule configuration in HTTP GW
sed -i "s|kubectl apply -f irule.yaml -n f5-bnk.*$|kubectl apply -f irule.yaml -n blue # applied to the GW namespace|"  ~/udf-cne/bnk-2.2.0-ga/scripts/deploy/060-deploy-blue-gateway.sh
sed -i '/kubectl apply -f irule.yaml -n blue # applied to the GW namespace/a\
kubectl apply -f blue-net-policy.yaml -n blue' ~/udf-cne/bnk-2.2.0-ga/scripts/deploy/060-deploy-blue-gateway.sh

sed -i "s|kubectl delete -f irule.yaml -n f5-bnk.*$|kubectl delete -f irule.yaml -n blue # applied to the GW namespace|"  ~/udf-cne/bnk-2.2.0-ga/scripts/remove/060-remove-blue-gateway.sh
sed -i '/kubectl delete -f irule.yaml -n blue # applied to the GW namespace/a\
kubectl delete -f blue-net-policy.yaml -n blue' ~/udf-cne/bnk-2.2.0-ga/scripts/remove/060-remove-blue-gateway.sh

# generate README with creation details
echo "Repo for v${NEW_VERSION}" > "${NEW_PATH}/README"
echo "generated from ${OLD_PATH} on $(date)" >> "${NEW_PATH}/README"
echo "using $(cd "$(dirname "$0")" && pwd)/$(basename "$0")" >> "${NEW_PATH}/README"
echo "based on commit $(git -C ~/udf-cne rev-parse --short HEAD)" >> "${NEW_PATH}/README"


