variable "environment" {
  description = "Environment name (dev, stage, prod)"
  type        = string
}

variable "repository_name" {
  description = "Name of the ECR repository"
  type        = string
  default     = "fastify-app"
} 