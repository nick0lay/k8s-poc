# Helm chart for Karpenter (cluster autoscaler)
resource "helm_release" "karpenter" {
  name             = "karpenter"
  repository       = "https://charts.karpenter.sh"            # Official Karpenter helm repository
  chart            = "karpenter"
  version          = "v1.3.3"                                 # Example Karpenter version (use the latest compatible with your EKS version)
  namespace        = "karpenter"
  create_namespace = true                                     # Create the karpenter namespace
  values = [<<-EOF
    serviceAccount:
      create: false
      name: karpenter
      annotations:
        eks.amazonaws.com/role-arn: "${aws_iam_role.karpenter_controller.arn}"
    controller:
      clusterName: "${var.cluster_name}"
      # clusterEndpoint: "<optional: EKS API endpoint>"       # Not required if Karpenter can auto-discover the in-cluster API. If using a private cluster endpoint, you might provide it.
    settings:
      aws:
        defaultInstanceProfile: "${aws_iam_instance_profile.node_instance_profile.name}"
  EOF
  ]
  depends_on = [aws_iam_role.karpenter_controller, aws_eks_node_group.default_node_group] 
}
