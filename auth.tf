# -------------------------------
# Kubernetes Provider
# -------------------------------
provider "kubernetes" {
  host                   = module.eks.cluster_endpoint
  cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)
  token                  = data.aws_eks_cluster_auth.cluster.token
}

data "aws_eks_cluster_auth" "cluster" {
  name = module.eks.cluster_id
}

# -------------------------------
# aws-auth ConfigMap
# -------------------------------
resource "kubernetes_config_map" "aws_auth" {
  depends_on = [module.eks]  # make sure EKS cluster is ready

  metadata {
    name      = "aws-auth"
    namespace = "kube-system"
  }

  data = {
    # Node group IAM role mapping
    mapRoles = yamlencode([
      {
        rolearn  = module.iam.eks_node_role_arn
        username = "system:node:{{EC2PrivateDNSName}}"
        groups   = ["system:bootstrappers", "system:nodes"]
      }
    ])

    # Map your AWS root user to Kubernetes admin
    mapUsers = yamlencode([
      {
        userarn  = "arn:aws:iam::742674388365:root"  # <-- your root ARN
        username = "root"
        groups   = ["system:masters"]
      }
    ])
  }
}
