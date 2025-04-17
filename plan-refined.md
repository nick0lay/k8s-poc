# Refined Implementation Plan for TypeScript Fastify Service on AWS EKS

This refined plan outlines the step-by-step implementation of a Fastify service deployed on AWS EKS using Terraform HCL for infrastructure and organized in a Turborepo monorepo structure. It incorporates existing infrastructure sketches from the `tmp` directory and completed work.

## Legenda:
- 🟢 Completed task
- 🟡 Task in progress
- 🔴 Task blocked or has issues
- ⚪ Task not started

## 🧱 Phase 1: Project Foundations

### 🟢 1. Initialize Monorepo with Turborepo
- **Description**: Create the project's foundation using Turborepo CLI
- **Status**: Completed as evidenced by the existing project structure
- **Confidence**: 10/10

### 🟢 2. Create Minimal Fastify Application
- **Description**: Implement a bare-bones Fastify app with a health check endpoint
- **Status**: Completed with `apps/fastify-api` directory structure and package.json in place
- **Confidence**: 10/10

## ☁️ Phase 2: Infrastructure Foundation

### 🟢 3. Initialize Infrastructure Project
- **Description**: Set up infrastructure as code foundation
- **Status**: Completed with `infrastructure` directory structure and files
- **Note**: We will use Terraform HCL in a new `infrastructure-hcl` directory
- **Confidence**: 10/10

### 🟢 4. Containerize the Fastify Application
- **Description**: Create a Docker image for the application
- **Status**: Completed with Dockerfile and docker-compose.yml in place
- **Confidence**: 10/10

## 🛠️ Phase 3: Basic Infrastructure Deployment

### 🟢 4.5. Create Terraform HCL Project Structure
- **Description**: Set up new Terraform HCL infrastructure directory
- **Details**:
  - Create `infrastructure-hcl` directory
  - Initialize Terraform project with proper provider configuration
  - Create directory structure for modules and resources
  - Configure remote state if needed
- **Confidence**: 9/10
- **Assumptions**:
  - Terraform CLI is installed locally
  - AWS credentials are configured for CLI access
  - Local state management for initial development

### 🟢 5. Configure Network Resources for EKS
- **Description**: Configure existing VPC and subnet resources for EKS using Terraform HCL
- **Status**: Implementation in progress, needs to be moved to `infrastructure-hcl` directory
- **Details**: Network configuration includes:
  - Using existing VPC and subnets as specified in variables.tf
  - Creating security groups for cluster access
  - Adding required tags to existing subnets for EKS and AWS Load Balancer Controller
  - Setting up proper IAM roles for EKS to access network resources
  - Creating a tfvars file to specify VPC ID and subnet IDs
- **Confidence**: 9/10
- **Dependencies**:
  - Task 4.5 (Create Terraform HCL Project Structure)
- **Assumptions**:
  - VPC and subnets already exist in eu-central-1 region
  - Existing subnets span at least 2 AZs for high availability
  - Permission to tag existing subnets is available

### 🟢 6. Create ECR Repository
- **Description**: Set up container registry for application images
- **Details**:
  - Add ECR repository resource to Terraform HCL configuration
  - Configure lifecycle policy (keep latest 5 images)
  - Create script for building and pushing images
- **Confidence**: 8/10
- **Assumptions**:
  - Repository will be in eu-central-1 region based on cluster configuration in sketches
  - Repository will be named "fastify-app" to match deployment manifest references

## 🚢 Phase 4: EKS Cluster Setup

### ⚪ 7. Deploy EKS Cluster
- **Description**: Create a working EKS cluster in the existing VPC
- **Details**:
  - Adapt the sketch in `tmp/infra/cluster.tf` to the Terraform HCL infrastructure
  - Use AWS managed node group with ARM64 instances (t4g.small)
  - Configure IAM roles for cluster and nodes
  - Enable public and private endpoint access
  - Use existing subnets with proper tagging for EKS
- **Confidence**: 8/10
- **Dependencies**:
  - Task 5 (Configure Network Resources for EKS)
- **Assumptions**:
  - Using EKS 1.28 or newer
  - Using Graviton (ARM64) instances for better price-performance
  - Cluster will be named "fastify-eks-cluster" as in variables.tf


### ⚪ 9. Set Up Karpenter for Node Provisioning
- **Description**: Configure dynamic node provisioning
- **Details**:
  - Implement the equivalent of `tmp/manifests/provisioner.yaml` through Terraform
  - Configure provisioner for on-demand ARM64 instances (t4g.small, c6g.medium)
  - Set up proper IAM roles and instance profile
  - Configure node termination after 30 seconds of being empty
  - Add Helm provider to Terraform for Karpenter installation
- **Confidence**: 7/10
- **Dependencies**:
  - Task 7 (Deploy EKS Cluster)
- **Assumptions**:
  - Karpenter is preferred over Cluster Autoscaler
  - Karpenter will be installed using Helm via Terraform
  - IAM roles for service accounts (IRSA) will be configured

## 📦 Phase 5: Application Deployment

### ⚪ 10. Deploy Core Kubernetes Resources
- **Description**: Deploy the application and related resources
- **Details**:
  - Use manifests similar to those in `tmp/manifests/`
  - Deploy ConfigMap based on sketch in `tmp/manifests/config-map.yaml`
  - Deploy the application with 2 initial replicas
  - Configure resource requests (100m CPU, 128Mi memory) and limits (200m CPU, 256Mi memory)
  - Set up the service for access within the cluster
- **Confidence**: 9/10
- **Assumptions**:
  - Container image will be available in ECR
  - Application listens on port 3000 inside the container

### ⚪ 11. Configure Horizontal Pod Autoscaling
- **Description**: Set up automatic scaling based on workload
- **Details**:
  - Deploy metrics-server if not included with EKS
  - Use HPA manifest similar to `tmp/manifests/hpa.yaml`
  - Configure min 2, max 10 replicas
  - Target 70% CPU utilization
- **Confidence**: 8/10
- **Assumptions**:
  - Metrics server will be compatible with EKS version
  - Application pod has resource requests defined for proper scaling

## 📡 Phase 6: External Access Configuration

### ⚪ 12. Set Up AWS Load Balancer Controller
- **Description**: Configure external access to the application
- **Details**:
  - Add Helm chart for AWS Load Balancer Controller to Terraform configuration
  - Configure service account with necessary IAM permissions
  - Utilize existing subnet tags for ALB discovery
- **Confidence**: 7/10
- **Assumptions**:
  - AWS Load Balancer Controller preferred over NGINX Ingress
  - IAM roles for service accounts (IRSA) will be configured
  - Existing subnets will have proper tags for ALB discovery

### ⚪ 13. Create Ingress Resource
- **Description**: Expose the application externally
- **Details**:
  - Deploy Ingress manifest similar to `tmp/manifests/ingress.yaml`
  - Configure ALB with internet-facing scheme
  - Set target type to IP for direct pod routing
  - Initially configure for HTTP only on port 80
- **Confidence**: 8/10
- **Assumptions**:
  - AWS Load Balancer Controller is properly installed
  - No SSL/TLS required for initial implementation

## 🔍 Phase 7: Monitoring and Observability (Will be implemented only if all the other task are marked as `Completed task`)

### ⚪ 14. Set Up Prometheus and Grafana
- **Description**: Implement monitoring solution
- **Details**:
  - Add Prometheus and Grafana Helm charts to Terraform configuration
  - Configure service monitors for application metrics
  - Set up dashboard for key metrics (CPU, memory, request rate, latency)
  - Configure persistent storage for metrics data
- **Confidence**: 6/10
- **Assumptions**:
  - Using Prometheus Operator via Helm
  - Persistence required for metrics data
  - Metrics will be exposed by the application

### ⚪ 15. Implement Application Metrics
- **Description**: Add custom metrics to the Fastify application
- **Details**:
  - Add Prometheus client to the Fastify application
  - Expose standard HTTP metrics (request count, latency, etc.)
  - Configure `/metrics` endpoint for Prometheus scraping
- **Confidence**: 7/10
- **Assumptions**:
  - Using prom-client Node.js library
  - Metrics will be used by the HPA for scaling decisions

## 🚀 Phase 8: Advanced Application Features (Will be implemented only if all the other task are marked as `Completed task` )

### ⚪ 16. Enhance Fastify Application
- **Description**: Add more advanced REST endpoints and features
- **Details**:
  - Implement structured routes directory
  - Add JSON validation with JSON Schema
  - Implement basic caching mechanism
  - Add request/response logging with Pino
  - Create artificial delay endpoint for load testing
- **Confidence**: 8/10
- **Assumptions**:
  - No database integration yet
  - In-memory caching initially

## ⚙️ Phase 9: CI/CD Pipeline (Will be implemented only if all the other task are marked as `Completed task` )

### ⚪ 17. Implement CI/CD Pipeline
- **Description**: Automate building, testing, and deployment
- **Details**:
  - Set up GitHub Actions workflow in `.github/workflows`
  - Configure build and push steps for the container
  - Set up automated testing with proper caching
  - Configure deployment to update Kubernetes resources
  - Implement environment-specific configurations
- **Confidence**: 6/10
- **Assumptions**:
  - Using GitHub as code repository
  - Secrets for AWS credentials will be properly configured
  - Single environment (development) initially

## 🧪 Phase 10: Testing and Validation (Will be implemented only if all the other task are marked as `Completed task` )

### ⚪ 18. Implement Load Testing
- **Description**: Create comprehensive load tests for the deployment
- **Details**:
  - Create load test scripts with k6
  - Configure test scenarios for scaling validation
  - Test HPA behavior under various load conditions
  - Document performance characteristics
- **Confidence**: 7/10
- **Assumptions**:
  - Using k6 for load testing
  - Defining specific SLOs to measure against

### ⚪ 19. Document Deployment and Operations
- **Description**: Create comprehensive documentation
- **Details**:
  - Document infrastructure architecture
  - Create runbooks for common operations
  - Document scaling parameters and monitoring setup
  - Add development guidelines for local testing
- **Confidence**: 8/10
- **Assumptions**:
  - Markdown documentation in repository
  - Basic diagrams of architecture

## 🔍 Phase 11: Further improvements (Will be implemented only if all the other task are marked as `Completed task` )

### ⚪ 20. Configure kubectl Access and Context
- **Description**: Ensure proper local access to the cluster
- **Details**:
  - Create script to update kubeconfig after cluster creation
  - Configure service account for deployment
  - Add namespaces for application deployment
- **Confidence**: 8/10
- **Dependencies**:
  - Task 7 (Deploy EKS Cluster)
- **Assumptions**:
  - AWS CLI and kubectl installed locally
  - IAM permissions allow updating kubeconfig

## Major Considerations and Uncertainties

1. **Cost Management**: Setting up cost monitoring for EKS cluster (especially for ARM instances)
2. **Security Configuration**: IAM roles, network policies, and pod security policies
3. **State Management**: Transitioning from local to remote state for Terraform
4. **Secret Management**: Strategy for managing application secrets (AWS Secrets Manager, SSM, etc.)
5. **Karpenter vs. Cluster Autoscaler**: Decision to use Karpenter for node provisioning
6. **ARM64 Architecture**: Using Graviton instances for improved price-performance ratio
7. **Monitoring Strategy**: Determining what metrics are most critical for the application
8. **Existing VPC Configuration**: Ensuring existing network resources meet EKS requirements

## Open Questions

1. Is ARM64 architecture (Graviton) acceptable, or should we use x86_64 instances?
2. Should we implement SSL/TLS for the ingress from the beginning?
3. What specific endpoints beyond the health check are required for the Fastify application?
4. Are there specific metrics or alerts that should be prioritized for monitoring?
5. Do we have a target cost model or budget constraints for the infrastructure?
6. Are there specific requirements for the existing VPC and subnets (e.g., specific CIDR ranges or naming conventions)?
7. Should we implement any additional security measures for the existing VPC configuration?
