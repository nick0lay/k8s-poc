# Retrieve the OIDC issuer URL for the EKS cluster
data "aws_eks_cluster" "cluster" {
  name = aws_eks_cluster.eks_cluster.name
}
data "aws_eks_cluster_auth" "cluster" {
  name = aws_eks_cluster.eks_cluster.name
}

# Create an IAM OIDC provider for the cluster (enables IRSA)
resource "aws_iam_openid_connect_provider" "eks_oidc" {
  url               = data.aws_eks_cluster.cluster.identity[0].oidc[0].issuer               # OIDC Issuer URL for the cluster
  client_id_list    = ["sts.amazonaws.com"]                                                # EKS IRSA uses sts.amazonaws.com as client ID
  thumbprint_list   = [data.tls_certificate.eks_oidc.certificates[0].sha1_fingerprint]      # Certificate thumbprint for the OIDC URL (for trust)
}
# Fetch the SSL thumbprint of the OIDC issuer (needed for the provider)
data "tls_certificate" "eks_oidc" {
  url = data.aws_eks_cluster.cluster.identity[0].oidc[0].issuer
}
