output "ecr_repository_url" {
  description = "URL of the ECR repository"
  value       = module.ecr.repository_url
}

# Additional outputs will be added as we implement more modules
# output "eks_cluster_endpoint" {
#   description = "Endpoint of the EKS cluster"
#   value       = module.eks.cluster_endpoint
# }
#
# output "eks_cluster_name" {
#   description = "Name of the EKS cluster"
#   value       = module.eks.cluster_name
# }

# EKS Cluster Outputs
output "eks_cluster_id" {
  description = "The name/id of the EKS cluster"
  value       = module.eks.cluster_id
}

output "eks_cluster_endpoint" {
  description = "The endpoint for the Kubernetes API server"
  value       = module.eks.cluster_endpoint
}

output "eks_oidc_provider_arn" {
  description = "The ARN of the OIDC Provider for EKS"
  value       = module.eks.oidc_provider_arn
} 