/**
 * Main entry point for the infrastructure code
 * This defines AWS infrastructure resources for the K8s POC project
 */

import { Construct } from 'constructs';
import { App, TerraformStack, TerraformOutput } from 'cdktf';
import { AwsProvider } from '@cdktf/provider-aws/lib/provider';
import { VpcConstruct } from '../lib/vpc';

class K8sPocStack extends TerraformStack {
  constructor(scope: Construct, id: string) {
    super(scope, id);

    // Define AWS provider with region
    new AwsProvider(this, 'AWS', {
      region: 'us-east-1',
      defaultTags: [{
        tags: {
          Project: 'k8s-poc',
          Environment: 'dev',
          ManagedBy: 'cdktf'
        }
      }]
    });

    // Create VPC and network resources
    const vpc = new VpcConstruct(this, 'vpc', {
      cidrBlock: '10.0.0.0/16',
      name: 'k8s-poc',
      environment: 'dev',
    });

    // Output VPC ID
    new TerraformOutput(this, 'vpc_id', {
      value: vpc.vpc.id,
      description: 'The ID of the VPC'
    });

    // Output public subnet IDs
    new TerraformOutput(this, 'public_subnet_ids', {
      value: vpc.publicSubnets.map(subnet => subnet.id),
      description: 'The IDs of the public subnets'
    });

    // Output private subnet IDs
    new TerraformOutput(this, 'private_subnet_ids', {
      value: vpc.privateSubnets.map(subnet => subnet.id),
      description: 'The IDs of the private subnets'
    });

    // Output cluster security group ID
    new TerraformOutput(this, 'cluster_security_group_id', {
      value: vpc.clusterSg.id,
      description: 'The ID of the EKS cluster security group'
    });
  }
}

const app = new App();
new K8sPocStack(app, 'k8s-poc-infrastructure');
app.synth(); 