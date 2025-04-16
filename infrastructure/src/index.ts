/**
 * Main entry point for the infrastructure code
 * This will be populated with CDKTF code in a later phase
 */

import { Construct } from 'constructs';
import { App, TerraformStack, TerraformOutput } from 'cdktf';
import { AwsProvider } from '../.gen/providers/aws/provider';

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

    // Basic output to verify stack is working
    new TerraformOutput(this, 'stack_region', {
      value: 'us-east-1',
      description: 'The AWS region used for this stack'
    });
  }
}

const app = new App();
new K8sPocStack(app, 'k8s-poc-infrastructure');
app.synth(); 