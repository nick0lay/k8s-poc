terraform {
  backend "s3" {
    bucket  = "coople-terraform-playground-states"
    key     = "apps/fastify-eks-poc/env-dev"
    region  = "eu-central-1"
    profile = "playground"
  }
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.23"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.11"
    }
  }
  required_version = ">= 1.0"
}

provider "aws" {
  region = var.aws_region
  profile = "playground"

  default_tags {
    tags = {
      Project     = "fastify-eks-poc"
      Environment = var.environment
      ManagedBy   = "terraform"
    }
  }
}

# These providers will be configured later after the EKS cluster is created
provider "kubernetes" {
  # Configuration will be provided after EKS cluster creation
}

provider "helm" {
  # Configuration will be provided after EKS cluster creation
}

# Include modules
module "network" {
  source = "./modules/network"

  environment        = var.environment
  vpc_id             = var.vpc_id
  private_subnet_ids = var.private_subnet_ids
  public_subnet_ids  = var.public_subnet_ids
}

module "ecr" {
  source = "./modules/ecr"

  environment     = var.environment
  repository_name = "fastify-app"
}

# This module will be uncommented when we implement the EKS cluster
module "eks" {
  source = "./modules/eks"

  environment        = var.environment
  cluster_name       = var.cluster_name
  vpc_id             = var.vpc_id
  private_subnet_ids = var.private_subnet_ids
  public_subnet_ids  = var.public_subnet_ids
  
  # Pass network module outputs to EKS module
  cluster_security_group_id = module.network.cluster_security_group_id
  node_security_group_id    = module.network.node_security_group_id
  cluster_iam_role_arn      = module.network.cluster_iam_role_arn
  node_iam_role_arn         = module.network.node_iam_role_arn
} 