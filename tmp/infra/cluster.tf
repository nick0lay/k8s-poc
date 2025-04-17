provider "aws" {
  region = var.region                           # Use the specified AWS region (eu-central-1 for Frankfurt)
}

# Create an IAM role for EKS cluster control plane (to interact with AWS resources)
resource "aws_iam_role" "eks_cluster" {
  name = "${var.cluster_name}-eks-cluster-role"
  assume_role_policy = jsonencode({            # Trust policy for EKS service to assume this role
    "Version" : "2012-10-17",
    "Statement": [{
      "Effect": "Allow",
      "Principal": {
        "Service": "eks.amazonaws.com"         # EKS service will assume this role
      },
      "Action": "sts:AssumeRole"
    }]
  })
}
# Attach AWS managed policies to the EKS cluster role for it to manage AWS resources on your behalf
resource "aws_iam_role_policy_attachment" "eks_cluster_AmazonEKSClusterPolicy" {
  role       = aws_iam_role.eks_cluster.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"   # Allows EKS control plane to manage EKS cluster resources
}
resource "aws_iam_role_policy_attachment" "eks_cluster_AmazonEKSServicePolicy" {
  role       = aws_iam_role.eks_cluster.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSServicePolicy"   # Allows EKS to work with other AWS services (e.g., create load balancers)
}

# EKS Cluster Resource
resource "aws_eks_cluster" "eks_cluster" {
  name     = var.cluster_name
  role_arn = aws_iam_role.eks_cluster.arn       # Attach the IAM role for the EKS control plane

  # Provide the subnets for the cluster (use private subnets for control plane ENIs for better security)
  vpc_config {
    subnet_ids = var.private_subnet_ids         # At least two subnets in different AZs (we assume private_subnet_ids covers multiple AZs)
    endpoint_public_access = true              # (Optional) Allow public access to Kubernetes API (could be set false for private API endpoint)
    endpoint_private_access = true             # Enable private access to API (so cluster API is reachable within VPC)
  }

  # Enable the IAM OIDC provider for the cluster (to allow IRSA)
  # This creates an OIDC identity provider that will be used by service accounts (like Karpenter, ALB controller)
  enabled_cluster_log_types = ["api", "authenticator"]  # Enable some control plane logs (optional)
  # (Note: After creation, we'll create an aws_iam_openid_connect_provider resource for IRSA using the cluster's OIDC issuer URL)
}
# Tag the subnets for Kubernetes and ALB usage (EKS and controllers rely on specific tags on subnets)
# We tag private subnets for internal Kubernetes use and public subnets for external load balancers.
resource "aws_ec2_tag" "tag_private_subnets" {
  for_each = toset(var.private_subnet_ids)
  resource_id = each.value
  key   = "kubernetes.io/role/internal-elb"    # Tag for internal load balancer usage
  value = "1"
}
resource "aws_ec2_tag" "tag_private_subnets_cluster" {
  for_each = toset(var.private_subnet_ids)
  resource_id = each.value
  key   = "kubernetes.io/cluster/${var.cluster_name}"
  value = "shared"                             # Marks subnet as usable by this EKS cluster
}
resource "aws_ec2_tag" "tag_public_subnets" {
  for_each = toset(var.public_subnet_ids)
  resource_id = each.value
  key   = "kubernetes.io/role/elb"             # Tag for public load balancer (ELB/ALB) usage
  value = "1"
}
resource "aws_ec2_tag" "tag_public_subnets_cluster" {
  for_each = toset(var.public_subnet_ids)
  resource_id = each.value
  key   = "kubernetes.io/cluster/${var.cluster_name}"
  value = "shared"                             # Marks subnet as usable by this EKS cluster (for ALB Controller to discover)
}

# IAM Role for EKS Worker Nodes (to be assumed by EC2 instances = worker nodes)
resource "aws_iam_role" "node" {
  name = "${var.cluster_name}-node-role"
  assume_role_policy = jsonencode({            # Trust policy allowing EC2 instances (worker nodes) to assume this role
    "Version": "2012-10-17",
    "Statement": [{
      "Effect": "Allow",
      "Principal": {
        "Service": "ec2.amazonaws.com"         # EC2 service can assume this role (for instances launched as part of EKS worker nodes)
      },
      "Action": "sts:AssumeRole"
    }]
  })
}
# Attach AWS managed policies to the node role to give worker nodes necessary permissions
resource "aws_iam_role_policy_attachment" "node_AmazonEKSWorkerNodePolicy" {
  role       = aws_iam_role.node.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"        # Allows nodes to communicate with EKS control plane (join cluster, etc.)
}
resource "aws_iam_role_policy_attachment" "node_AmazonEKS_CNI_Policy" {
  role       = aws_iam_role.node.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"             # Allows nodes to manage networking (required for VPC CNI plugin)
}
resource "aws_iam_role_policy_attachment" "node_AmazonEC2ContainerRegistryReadOnly" {
  role       = aws_iam_role.node.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"  # Allows pulling container images from ECR
}
resource "aws_iam_role_policy_attachment" "node_AmazonSSMManagedInstanceCore" {
  role       = aws_iam_role.node.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"    # Allows SSM (AWS Systems Manager) access (e.g., for AWS SSM agent, optional but useful for debugging)
}

# Instance Profile for the node role (needed to attach IAM role to EC2 instances)
resource "aws_iam_instance_profile" "node_instance_profile" {
  name = "${var.cluster_name}-node-instance-profile"
  role = aws_iam_role.node.name                 # Associate the node IAM role with an instance profile
}

# EKS Managed Node Group for initial cluster nodes
resource "aws_eks_node_group" "default_node_group" {
  cluster_name    = aws_eks_cluster.eks_cluster.name   # Associate with our EKS cluster
  node_group_name = "${var.cluster_name}-node-group"
  node_role_arn   = aws_iam_role.node.arn              # IAM role that nodes will use (our node role created above)
  subnet_ids      = var.private_subnet_ids             # Place nodes in private subnets only
  ami_type        = "AL2_ARM_64"                       # Use Amazon Linux 2 ARM64 AMI (for Graviton instances)
  instance_types  = ["t4g.small"]                      # Use a small Graviton2 instance type for nodes (as baseline capacity)
  capacity_type   = "ON_DEMAND"                        # On-Demand instances (no Spot for the baseline node)
  scaling_config {
    desired_size = 1                                   # Start with 1 node (just enough to run system pods like Karpenter controller)
    min_size     = 1                                   # Ensure at least 1 node is always running (so Karpenter pod itself has a place to run)
    max_size     = 2                                   # Max 2 in node group (we rely on Karpenter for further scaling beyond this)
  }
  update_config {
    max_unavailable = 1                                # Rolling update settings (at most 1 node unavailable at a time during updates)
  }
  depends_on = [aws_eks_cluster.eks_cluster]           # Ensure the cluster is created before the node group
}
