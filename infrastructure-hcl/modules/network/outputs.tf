output "vpc_id" {
  description = "ID of the VPC used for the infrastructure"
  value       = var.vpc_id
}

output "private_subnet_ids" {
  description = "List of private subnet IDs used for the infrastructure"
  value       = var.private_subnet_ids
}

output "public_subnet_ids" {
  description = "List of public subnet IDs used for the infrastructure"
  value       = var.public_subnet_ids
}

output "cluster_security_group_id" {
  description = "Security group ID for the EKS cluster"
  value       = aws_security_group.eks_cluster.id
}

output "node_security_group_id" {
  description = "Security group ID for the EKS worker nodes"
  value       = aws_security_group.eks_nodes.id
}

output "cluster_iam_role_arn" {
  description = "ARN of the IAM role for EKS cluster"
  value       = aws_iam_role.eks_cluster_role.arn
}

output "node_iam_role_arn" {
  description = "ARN of the IAM role for EKS worker nodes"
  value       = aws_iam_role.eks_node_role.arn
} 