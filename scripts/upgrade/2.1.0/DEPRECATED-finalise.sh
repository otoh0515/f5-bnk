#!/bin/bash

# scripts moved to ~/udf-cne/cne-tools/bin

# Script to force delete a stuck Kubernetes namespace with lingering resources

NAMESPACE="${1:-f5-utils}"

echo "Attempting to force delete namespace: $NAMESPACE"
echo "=================================================="

# Step 1: Check if namespace exists
echo ""
echo "Step 1: Checking if namespace exists..."
if kubectl get namespace "$NAMESPACE" &>/dev/null; then
    echo "✓ Namespace $NAMESPACE found"
else
    echo "✗ Namespace $NAMESPACE not found"
    exit 1
fi

# Step 2: Check for finalizers on the namespace
echo ""
echo "Step 2: Checking for finalizers on namespace..."
FINALIZERS=$(kubectl get namespace "$NAMESPACE" -o jsonpath='{.metadata.finalizers}')
if [ "$FINALIZERS" != "null" ] && [ ! -z "$FINALIZERS" ]; then
    echo "✓ Found finalizers: $FINALIZERS"
    echo "  Removing finalizers..."
    kubectl patch namespace "$NAMESPACE" -p '{"metadata":{"finalizers":[]}}' --type=merge
    echo "✓ Finalizers removed"
else
    echo "✓ No finalizers found on namespace"
fi

# Step 3: Check for resources with finalizers in the namespace
echo ""
echo "Step 3: Checking for resources with finalizers..."
RESOURCES=$(kubectl api-resources --verbs=list --namespaced=true -o name 2>/dev/null)
FOUND_FINALIZERS=false

while IFS= read -r resource; do
    if ITEMS=$(kubectl get "$resource" -n "$NAMESPACE" -o jsonpath='{.items[*].metadata.name}' 2>/dev/null); then
        for item in $ITEMS; do
            ITEM_FINALIZERS=$(kubectl get "$resource" "$item" -n "$NAMESPACE" -o jsonpath='{.metadata.finalizers}' 2>/dev/null)
            if [ "$ITEM_FINALIZERS" != "null" ] && [ ! -z "$ITEM_FINALIZERS" ]; then
                echo "✓ Found finalizers on $resource/$item: $ITEM_FINALIZERS"
                echo "  Removing finalizers..."
                kubectl patch "$resource" "$item" -n "$NAMESPACE" -p '{"metadata":{"finalizers":[]}}' --type=merge 2>/dev/null
                echo "✓ Finalizers removed from $resource/$item"
                FOUND_FINALIZERS=true
            fi
        done
    fi
done <<< "$RESOURCES"

if [ "$FOUND_FINALIZERS" = false ]; then
    echo "✓ No resources with finalizers found"
fi

# Step 4: Force delete the namespace
echo ""
echo "Step 4: Force deleting namespace..."
kubectl delete namespace "$NAMESPACE" --grace-period=0 --force 2>/dev/null

# Step 5: Verify deletion
echo ""
echo "Step 5: Verifying namespace deletion..."
sleep 2
if kubectl get namespace "$NAMESPACE" &>/dev/null; then
    echo "✗ Namespace still exists, trying again..."
    kubectl patch namespace "$NAMESPACE" -p '{"metadata":{"finalizers":[]}}' --type=merge
    kubectl delete namespace "$NAMESPACE" --grace-period=0 --force
    sleep 2
    if kubectl get namespace "$NAMESPACE" &>/dev/null; then
        echo "✗ Failed to delete namespace"
        exit 1
    fi
fi

echo "✓ Namespace $NAMESPACE successfully deleted!"
echo ""
echo "=================================================="
echo "Done!"