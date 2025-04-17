# EKS Module - Main Implementation
# Based on the original sketch in tmp/infra/cluster.tf

# EKS Cluster Resource - using IAM roles from network module
resource "aws_eks_cluster" "eks_cluster" {
  name     = var.cluster_name
  role_arn = var.cluster_iam_role_arn  # Using the IAM role from network module
  version  = var.kubernetes_version

  vpc_config {
    subnet_ids              = concat(var.private_subnet_ids, var.public_subnet_ids)
    endpoint_public_access  = true
    endpoint_private_access = true
    security_group_ids      = [var.cluster_security_group_id]  # Using security group from network module
  }

  enabled_cluster_log_types = ["api", "audit", "authenticator", "controllerManager", "scheduler"]

  tags = {
    Name = var.cluster_name
  }
}

# EKS Managed Node Group - using IAM role from network module
resource "aws_eks_node_group" "default_node_group" {
  cluster_name    = aws_eks_cluster.eks_cluster.name
  node_group_name = "${var.cluster_name}-managed-node-group"
  node_role_arn   = var.node_iam_role_arn  # Using the IAM role from network module
  subnet_ids      = var.private_subnet_ids
  
  ami_type        = "AL2_ARM_64"  # Graviton (ARM64) processors for better price-performance
  instance_types  = ["t4g.small"]
  capacity_type   = "ON_DEMAND"
  
  scaling_config {
    desired_size = var.node_desired_size
    min_size     = var.node_min_size
    max_size     = var.node_max_size
  }
  
  update_config {
    max_unavailable = 1
  }
  
  tags = {
    Name = "${var.cluster_name}-managed-node-group"
  }
}

# Create IAM OIDC provider for the cluster
data "tls_certificate" "eks" {
  url = aws_eks_cluster.eks_cluster.identity[0].oidc[0].issuer
}

resource "aws_iam_openid_connect_provider" "eks_oidc" {
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = [data.tls_certificate.eks.certificates[0].sha1_fingerprint]
  url             = aws_eks_cluster.eks_cluster.identity[0].oidc[0].issuer
  
  tags = {
    Name = "${var.cluster_name}-eks-oidc-provider"
  }
} 