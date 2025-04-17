# Terraform HCL Infrastructure for K8s POC

This directory contains Terraform HCL code for provisioning and managing the infrastructure for the Kubernetes POC project.

## Directory Structure

```
infrastructure-hcl/
├── main.tf            # Main Terraform configuration file
├── variables.tf       # Variable declarations
├── outputs.tf         # Output definitions
├── terraform.tfvars.example # Example variable values (copy to terraform.tfvars for use)
└── modules/           # Module directories
    ├── network/       # Network configuration (VPC, subnets, etc.)
    ├── ecr/           # ECR repository for container images
    └── eks/           # EKS cluster (to be implemented)
```

## Usage

1. Install Terraform CLI (version >= 1.0)
2. Configure AWS credentials
3. Copy `terraform.tfvars.example` to `terraform.tfvars` and fill in your values
4. Initialize the project:

```
terraform init
```

5. Plan the deployment:

```
terraform plan
```

6. Apply the changes:

```
terraform apply
```

## Implemented Features

- [x] Basic project structure
- [x] Network module (VPC/subnet tagging)
- [x] ECR repository configuration
- [ ] EKS cluster (scheduled for Phase 4)
- [ ] Karpenter for node provisioning (scheduled for Phase 4)
- [ ] AWS Load Balancer Controller (scheduled for Phase 6)
- [ ] External access configuration (scheduled for Phase 6)

## Notes

This project uses local state by default. For production use, it's recommended to configure remote state with proper locking (S3 + DynamoDB). 