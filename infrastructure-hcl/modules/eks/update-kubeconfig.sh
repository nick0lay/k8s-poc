#!/bin/bash

# Script to update kubeconfig for EKS cluster access
# This script should be run after the EKS cluster is deployed

# Set variables
CLUSTER_NAME="fastify-eks-cluster"
REGION="eu-central-1"
PROFILE="playground"

# Update kubeconfig
echo "Updating kubeconfig for EKS cluster: ${CLUSTER_NAME}"
aws eks update-kubeconfig --name "${CLUSTER_NAME}" --region "${REGION}" --profile "${PROFILE}"

# Verify connection
echo "Verifying connection to cluster..."
kubectl get svc

# Output success message
echo "Kubeconfig updated successfully. You can now use kubectl to interact with your EKS cluster." 