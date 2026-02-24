#! /bin/bash

# create-repo-2.2.0.sh

# this file programmatically creates NEW_VERSION using OLD_VERSION as the source-of-truth
# as a way to track the configuration changes between versions

# Configuration
BASE_DIR=udf-cne
OLD_VERSION="2.1.0-ga"
NEW_VERSION="2.2.0-ga"
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


#if [[ "$(ls -1 ~/udf-cne/bnk-2.2.0-ga | wc -l)" != "52" ]]; then
#  echo "ERROR - v2.1 repo failed to create: $(ls -1 ~/udf-cne/bnk-2.2.0-ga | wc -l) items"
#  sleep 36000
#  exit 1
#fi

# Replace bnkgatewayclass with cneinstance in v2.2.0

cat <<EOF >> ${NEW_PATH}/flo-values.yaml
# v2.2.0 additions
containerPlatform: Generic
ServiceIPFamily: ipv4
sharedComponentNamespace: f5-utils
EOF

sed -i "s| e:| exponent:|" ${NEW_PATH}/flo-values.yaml
sed -i "s| n:| modulus:|" ${NEW_PATH}/flo-values.yaml


cp -f ~/udf-cne/bnk-2.2.0-ga/scripts/upgrade/2.2.0/cne-instance.yaml ${NEW_PATH}
rm ${NEW_PATH}/bnk-gatewayclass.yaml

# BNKgatewayclass is renamed CNEinstance in v2.2

sed -i "s|bnk-gatewayclass.yaml|cne-instance.yaml|" ${NEW_PATH}/scripts/bnk-deploy.sh
sed -i "s|bnk-gatewayclass.yaml|cne-instance.yaml|" ${NEW_PATH}/scripts/bnk-deploy-complete.sh
sed -i "s|BNK Gateway Class|CNE Instance|" ${NEW_PATH}/scripts/deploy/040-deploy-bnk.sh
sed -i "s|bnk-gatewayclass.yaml|cne-instance.yaml|" ${NEW_PATH}/scripts/deploy/041-deploy-flo.sh
sed -i "s|BNKgatewayclass|CNEinstance|" ${NEW_PATH}/scripts/deploy/041-deploy-flo.sh
sed -i "s|bnk-gatewayclass.yaml|cne-instance.yaml|" ${NEW_PATH}/scripts/deploy/042-deploy-bnk.sh
sed -i "s|BNKgatewayclass|CNEinstance|" ${NEW_PATH}/scripts/deploy/042-deploy-bnk.sh
sed -i "s|bnkgatewayclass.k8s.f5.com|cneinstance.k8s.f5.com|" ${NEW_PATH}/scripts/deploy/042-deploy-bnk.sh
sed -i "s|bnkgatewayclasses.k8s.f5.com|cneinstances.k8s.f5.com|" ${NEW_PATH}/scripts/deploy/042-deploy-bnk.sh
sed -i "s|my-bnkgatewayclass|f5-cne-controller|" ${NEW_PATH}/scripts/deploy/042-deploy-bnk.sh
sed -i "s|bnk-gatewayclass.yaml|cne-instance.yaml|" ${NEW_PATH}/scripts/deploy/090-deploy-bnk-fw.sh
sed -i "s|bnk-fw-gatewayclass.yaml|cne-fw-instance.yaml|" ${NEW_PATH}/scripts/deploy/090-deploy-bnk-fw.sh
sed -i "s|bnk-gatewayclass-EHF.yaml|cne-instance-EHF.yaml|" ${NEW_PATH}/scripts/deploy/090-deploy-bnk-fw.sh
sed -i "s|bnk-gatewayclass.yaml|cne-instance.yaml|" ${NEW_PATH}/scripts/deploy/090b-deploy-bnk-fw.sh
sed -i "s|bnk-fw-gatewayclass.yaml|cne-fw-instance.yaml|" ${NEW_PATH}/scripts/deploy/090b-deploy-bnk-fw.sh
sed -i "s|bnk-gatewayclass-EHF.yaml|cne-instance-EHF.yaml|" ${NEW_PATH}/scripts/deploy/090b-deploy-bnk-fw.sh
sed -i "s|bnkgatewayclass.k8s.f5.com|cneinstance.k8s.f5.com|" ${NEW_PATH}/scripts/deploy/091-modify-resources.sh
sed -i "s|my-bnkgatewayclass|f5-cne-controller|" ${NEW_PATH}/scripts/deploy/091-modify-resources.sh

sed -i "s|BNK Gateway Class|CNE Instance|" ${NEW_PATH}/scripts/remove/040-remove-bnk.sh
sed -i "s|bnk-gatewayclass.yaml|cne-instance.yaml|" ${NEW_PATH}/scripts/remove/042-remove-bnk.sh
sed -i "s|BNKgatewayclass|CNEinstance|" ${NEW_PATH}/scripts/remove/042-remove-bnk.sh
sed -i "s|bnk-gatewayclass.yaml|cne-instance.yaml|" ${NEW_PATH}/scripts/remove/090-remove-bnk-fw.sh
sed -i "s|bnk-fw-gatewayclass.yaml|cne-fw-instance.yaml|" ${NEW_PATH}/scripts/remove/090-remove-bnk-fw.sh

# generate README with creation details
echo "Repo for v${NEW_VERSION}" > "${NEW_PATH}/README"
echo "generated from ${OLD_PATH} on $(date)" >> "${NEW_PATH}/README"
echo "using $(cd "$(dirname "$0")" && pwd)/$(basename "$0")" >> "${NEW_PATH}/README"
echo "based on commit $(git -C ~/udf-cne rev-parse --short HEAD)" >> "${NEW_PATH}/README"


