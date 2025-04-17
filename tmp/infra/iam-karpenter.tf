# IAM Policy for Karpenter Controller (allow it to provision and manage EC2 instances for the cluster)
data "aws_caller_identity" "current" {}  # Get current account ID for constructing ARNs

resource "aws_iam_policy" "karpenter_controller" {
  name        = "${var.cluster_name}-KarpenterControllerPolicy"
  description = "IAM policy granting Karpenter permissions to manage EC2 for EKS cluster"
  policy      = <<-EOF
    {
      "Version": "2012-10-17",
      "Statement": [
        {
          "Sid": "KarpenterControllerPermissions",
          "Effect": "Allow",
          "Action": [
            "ec2:CreateLaunchTemplate",
            "ec2:CreateFleet",
            "ec2:RunInstances",
            "ec2:CreateTags",
            "ec2:TerminateInstances",
            "ec2:DeleteLaunchTemplate",
            "ec2:DescribeLaunchTemplates",
            "ec2:DescribeInstances",
            "ec2:DescribeSecurityGroups",
            "ec2:DescribeSubnets",
            "ec2:DescribeImages",
            "ec2:DescribeInstanceTypes",
            "ec2:DescribeInstanceTypeOfferings",
            "ec2:DescribeAvailabilityZones",
            "ec2:DescribeSpotPriceHistory",
            "ssm:GetParameter",
            "pricing:GetProducts"
          ],
          "Resource": "*"
        },
        {
          "Sid": "KarpenterConditionalTerminate",
          "Effect": "Allow",
          "Action": "ec2:TerminateInstances",
          "Resource": "*",
          "Condition": {
            "StringLike": {
              "ec2:ResourceTag/Name": "*karpenter*"
            }
          }
        },
        {
          "Sid": "PassNodeInstanceRole",
          "Effect": "Allow",
          "Action": "iam:PassRole",
          "Resource": "${aws_iam_role.node.arn}"
        },
        {
          "Sid": "EKSClusterDescribe",
          "Effect": "Allow",
          "Action": "eks:DescribeCluster",
          "Resource": "arn:aws:eks:${var.region}:${data.aws_caller_identity.current.account_id}:cluster/${var.cluster_name}"
        }
      ]
    }
  EOF
}

# IAM Role for Karpenter Controller (IRSA)
resource "aws_iam_role" "karpenter_controller" {
  name = "${var.cluster_name}-karpenter-controller"
  assume_role_policy = jsonencode({
    "Version": "2012-10-17",
    "Statement": [{
      "Effect": "Allow",
      "Principal": {
        "Federated": aws_iam_openid_connect_provider.eks_oidc.arn    # Trust the OIDC provider of our EKS cluster
      },
      "Action": "sts:AssumeRoleWithWebIdentity",
      "Condition": {
        "StringEquals": {
          # Only allow assumption by the specific service account "karpenter" in namespace "karpenter"
          "${replace(aws_iam_openid_connect_provider.eks_oidc.url, "https://", "")}:sub": "system:serviceaccount:karpenter:karpenter"
        }
      }
    }]
  })
}
# Attach the Karpenter Controller policy to the role
resource "aws_iam_role_policy_attachment" "karpenter_controller_attach" {
  role       = aws_iam_role.karpenter_controller.name
  policy_arn = aws_iam_policy.karpenter_controller.arn
}
