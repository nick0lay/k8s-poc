variable "environment" {
  description = "Environment name (dev, stage, prod)"
  type        = string
}

variable "vpc_id" {
  description = "ID of the existing VPC"
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
