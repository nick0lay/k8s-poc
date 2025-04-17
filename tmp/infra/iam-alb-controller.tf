# IAM Policy for AWS Load Balancer Controller
resource "aws_iam_policy" "alb_controller" {
  name        = "${var.cluster_name}-AWSLoadBalancerControllerPolicy"
  description = "IAM policy for AWS Load Balancer Controller to manage ALB/NLB"
  policy      = <<-EOF
    {
      "Version": "2012-10-17",
      "Statement": [
        # (The full list of actions is lengthy; refer to AWS docs for AWSLoadBalancerControllerIAMPolicy)
        # This policy should include permissions like:
        # elasticloadbalancing: (Create/Delete/Describe LoadBalancers, Listeners, TargetGroups, etc.)
        # ec2: (Describe subnets, security groups, create security groups, modify network interfaces, etc.)
        # cognito-idp:DescribeUserPoolClient, ACM:DescribeCertificate, WAF/GetWebACL (if using those features)
        # iam:CreateServiceLinkedRole (for ELB)
        # (Omitted full details for brevity; use the official AWSLoadBalancerController policy document)
      ]
    }
  EOF
}

# IAM Role for AWS Load Balancer Controller (IRSA)
resource "aws_iam_role" "alb_controller" {
  name = "${var.cluster_name}-alb-controller"
  assume_role_policy = jsonencode({
    "Version": "2012-10-17",
    "Statement": [{
      "Effect": "Allow",
      "Principal": {
        "Federated": aws_iam_openid_connect_provider.eks_oidc.arn   # Trust EKS OIDC provider
      },
      "Action": "sts:AssumeRoleWithWebIdentity",
      "Condition": {
        "StringEquals": {
          # Only allow assumption by service account "aws-load-balancer-controller" in "kube-system"
          "${replace(aws_iam_openid_connect_provider.eks_oidc.url, "https://", "")}:sub": "system:serviceaccount:kube-system:aws-load-balancer-controller"
        }
      }
    }]
  })
}
# Attach the ALB Controller policy to the role
resource "aws_iam_role_policy_attachment" "alb_controller_attach" {
  role       = aws_iam_role.alb_controller.name
  policy_arn = aws_iam_policy.alb_controller.arn
}
