import { Construct } from 'constructs';
import { Vpc } from '@cdktf/provider-aws/lib/vpc';
import { Subnet } from '@cdktf/provider-aws/lib/subnet';
import { InternetGateway } from '@cdktf/provider-aws/lib/internet-gateway';
import { RouteTable } from '@cdktf/provider-aws/lib/route-table';
import { Route } from '@cdktf/provider-aws/lib/route';
import { RouteTableAssociation } from '@cdktf/provider-aws/lib/route-table-association';
import { NatGateway } from '@cdktf/provider-aws/lib/nat-gateway';
import { Eip } from '@cdktf/provider-aws/lib/eip';
import { SecurityGroup } from '@cdktf/provider-aws/lib/security-group';
import { SecurityGroupRule } from '@cdktf/provider-aws/lib/security-group-rule';
import { DataAwsAvailabilityZones } from '@cdktf/provider-aws/lib/data-aws-availability-zones';

/**
 * VPC Network configuration for the EKS cluster
 */
export interface VpcProps {
  cidrBlock: string;
  name: string;
  environment: string;
}

export class VpcConstruct extends Construct {
  public readonly vpc: Vpc;
  public readonly publicSubnets: Subnet[];
  public readonly privateSubnets: Subnet[];
  public readonly clusterSg: SecurityGroup;

  constructor(scope: Construct, id: string, props: VpcProps) {
    super(scope, id);

    // Determine available AZs
    const availabilityZones = new DataAwsAvailabilityZones(this, 'available-azs', {
      state: 'available',
    });

    // Create VPC
    this.vpc = new Vpc(this, 'vpc', {
      cidrBlock: props.cidrBlock,
      enableDnsHostnames: true,
      enableDnsSupport: true,
      tags: {
        Name: `${props.name}-vpc`,
        Environment: props.environment,
      },
    });

    // Create Internet Gateway
    const igw = new InternetGateway(this, 'igw', {
      vpcId: this.vpc.id,
      tags: {
        Name: `${props.name}-igw`,
        Environment: props.environment,
      },
    });

    // Create public subnets, route tables and associations
    this.publicSubnets = [];
    const publicRouteTable = new RouteTable(this, 'public-route-table', {
      vpcId: this.vpc.id,
      tags: {
        Name: `${props.name}-public-rt`,
        Environment: props.environment,
      },
    });

    // Create default route for public route table
    new Route(this, 'public-route', {
      routeTableId: publicRouteTable.id,
      destinationCidrBlock: '0.0.0.0/0',
      gatewayId: igw.id,
    });

    // Create EIPs for NAT Gateways - one per AZ
    const eips: Eip[] = [];
    for (let i = 0; i < 2; i++) {
      eips.push(
        new Eip(this, `eip-${i}`, {
          vpc: true,
          tags: {
            Name: `${props.name}-nat-eip-${i}`,
            Environment: props.environment,
          },
        })
      );
    }

    // Create private subnets, NAT Gateways, route tables and associations
    this.privateSubnets = [];
    const natGateways: NatGateway[] = [];
    const privateRouteTables: RouteTable[] = [];

    // Create public and private subnets across multiple AZs
    for (let i = 0; i < 2 && i < (availabilityZones.names?.length || 0); i++) {
      // Get AZ name with fallback
      const azName = availabilityZones.names?.[i] || `${props.name}-az-${i}`;
      
      // Public subnet in each AZ
      const publicSubnet = new Subnet(this, `public-subnet-${i}`, {
        vpcId: this.vpc.id,
        cidrBlock: `10.0.${i * 2}.0/24`,
        availabilityZone: azName,
        mapPublicIpOnLaunch: true,
        tags: {
          Name: `${props.name}-public-subnet-${i}`,
          Environment: props.environment,
          'kubernetes.io/role/elb': '1', // Tag for AWS Load Balancer Controller
        },
      });
      this.publicSubnets.push(publicSubnet);

      // Associate public subnet with public route table
      new RouteTableAssociation(this, `public-route-association-${i}`, {
        subnetId: publicSubnet.id,
        routeTableId: publicRouteTable.id,
      });

      // Create NAT Gateway in this public subnet
      const natGateway = new NatGateway(this, `nat-gateway-${i}`, {
        allocationId: eips[i].id,
        subnetId: publicSubnet.id,
        tags: {
          Name: `${props.name}-nat-${i}`,
          Environment: props.environment,
        },
      });
      natGateways.push(natGateway);

      // Private subnet in each AZ
      const privateSubnet = new Subnet(this, `private-subnet-${i}`, {
        vpcId: this.vpc.id,
        cidrBlock: `10.0.${i * 2 + 1}.0/24`,
        availabilityZone: azName,
        tags: {
          Name: `${props.name}-private-subnet-${i}`,
          Environment: props.environment,
          'kubernetes.io/role/internal-elb': '1', // Tag for AWS Load Balancer Controller
        },
      });
      this.privateSubnets.push(privateSubnet);

      // Create route table for this private subnet
      const privateRouteTable = new RouteTable(this, `private-route-table-${i}`, {
        vpcId: this.vpc.id,
        tags: {
          Name: `${props.name}-private-rt-${i}`,
          Environment: props.environment,
        },
      });
      privateRouteTables.push(privateRouteTable);

      // Create default route via the NAT Gateway
      new Route(this, `private-route-${i}`, {
        routeTableId: privateRouteTable.id,
        destinationCidrBlock: '0.0.0.0/0',
        natGatewayId: natGateway.id,
      });

      // Associate private subnet with its route table
      new RouteTableAssociation(this, `private-route-association-${i}`, {
        subnetId: privateSubnet.id,
        routeTableId: privateRouteTable.id,
      });
    }

    // Create security group for EKS cluster
    this.clusterSg = new SecurityGroup(this, 'cluster-sg', {
      vpcId: this.vpc.id,
      description: 'Security group for EKS cluster control plane communication with worker nodes',
      tags: {
        Name: `${props.name}-cluster-sg`,
        Environment: props.environment,
      },
    });

    // Allow all outbound traffic
    new SecurityGroupRule(this, 'cluster-sg-egress', {
      securityGroupId: this.clusterSg.id,
      type: 'egress',
      fromPort: 0,
      toPort: 0,
      protocol: '-1',
      cidrBlocks: ['0.0.0.0/0'],
      description: 'Allow all outbound traffic',
    });

    // Allow inbound HTTPS traffic from anywhere (for API server)
    new SecurityGroupRule(this, 'cluster-sg-ingress-https', {
      securityGroupId: this.clusterSg.id,
      type: 'ingress',
      fromPort: 443,
      toPort: 443,
      protocol: 'tcp',
      cidrBlocks: ['0.0.0.0/0'],
      description: 'Allow HTTPS traffic from anywhere to API server',
    });
  }
} 