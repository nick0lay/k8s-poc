# Helm chart for AWS Load Balancer Controller (ALB Ingress Controller)
resource "helm_release" "aws_load_balancer_controller" {
  name             = "aws-load-balancer-controller"
  repository       = "https://aws.github.io/eks-charts"            # Official EKS charts repository
  chart            = "aws-load-balancer-controller"
  version          = "1.5.3"                                       # Specify the chart version (ensure it's compatible with your EKS version)
  namespace        = "kube-system"                                 # Deploy in kube-system namespace
  create_namespace = false                                         # kube-system already exists
  values = [<<-EOF
    region: ${var.region}
    vpcId: ${var.vpc_id}
    clusterName: "${var.cluster_name}"
    serviceAccount:
      create: false
      name: aws-load-balancer-controller
      annotations:
        eks.amazonaws.com/role-arn: "${aws_iam_role.alb_controller.arn}"
  EOF
  ]
  depends_on = [aws_iam_role.alb_controller, aws_eks_cluster.eks_cluster]  # Ensure IAM role and cluster are ready
}
