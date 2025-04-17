variable "environment" {
  description = "Environment name (dev, stage, prod)"
  type        = string
}

variable "cluster_name" {
  description = "Name of the EKS cluster"
  type        = string
}

variable "vpc_id" {
  description = "ID of the existing VPC"
  type        = string
}

variable "private_subnet_ids" {
  description = "List of private subnet IDs for EKS worker nodes"
  type        = list(string)
}

variable "public_subnet_ids" {
  description = "List of public subnet IDs for load balancers"
  type        = list(string)
}

variable "kubernetes_version" {
  description = "Kubernetes version to use for the EKS cluster"
  type        = string
  default     = "1.28"
}

variable "node_desired_size" {
  description = "Desired number of worker nodes"
  type        = number
  default     = 1
}

variable "node_min_size" {
  description = "Minimum number of worker nodes"
  type        = number
  default     = 1
}

variable "node_max_size" {
  description = "Maximum number of worker nodes"
  type        = number
  default     = 2
}

# Network module resources
variable "cluster_security_group_id" {
  description = "Security group ID for the EKS cluster from network module"
  type        = string
}

variable "node_security_group_id" {
  description = "Security group ID for the EKS worker nodes from network module"
  type        = string
}

variable "cluster_iam_role_arn" {
  description = "ARN of the IAM role for EKS cluster from network module"
  type        = string
}

variable "node_iam_role_arn" {
  description = "ARN of the IAM role for EKS worker nodes from network module"
  type        = string
} 