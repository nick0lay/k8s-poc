# Input variables for existing AWS infrastructure and cluster settings
variable "region" {
  description = "AWS region for EKS cluster"
  default     = "eu-central-1"                # Frankfurt region as required
}
variable "vpc_id" {
  description = "ID of the existing VPC to use for EKS"
  type        = string
}
variable "private_subnet_ids" {
  description = "List of private subnet IDs for EKS worker nodes (no public IPs)"
  type        = list(string)
}
variable "public_subnet_ids" {
  description = "List of public subnet IDs (for ALB ingress to use)"
  type        = list(string)
}
variable "cluster_name" {
  description = "Name for the EKS cluster"
  type        = string
  default     = "fastify-eks-cluster"         # You can change this as needed
}
