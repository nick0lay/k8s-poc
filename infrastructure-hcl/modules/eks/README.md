# EKS Module

This module will be implemented in Phase 4 of the project, as per the implementation plan.

The module will create:
- EKS Cluster
- Managed Node Groups with ARM64 instances (t4g.small)
- IAM roles for cluster and nodes
- Security groups for cluster access
- Karpenter configuration for dynamic node provisioning

Implementation will follow best practices for EKS on AWS. 