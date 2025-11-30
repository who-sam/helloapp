# ============================================================================
# EKS MODULE - EBS CSI Driver OIDC & IAM Configuration
# ============================================================================

# TLS certificate data for OIDC provider thumbprint
data "tls_certificate" "eks_oidc" {
  url = aws_eks_cluster.main.identity[0].oidc[0].issuer
}

# Create OIDC provider for EKS cluster
resource "aws_iam_openid_connect_provider" "eks" {
  url             = aws_eks_cluster.main.identity[0].oidc[0].issuer
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = [data.tls_certificate.eks_oidc.certificates[0].sha1_fingerprint]

  tags = merge(
    var.tags,
    {
      Name = "${var.project_name}-${var.environment}-eks-oidc"
    }
  )
}

# IAM policy document for EBS CSI driver trust relationship
data "aws_iam_policy_document" "ebs_csi_driver_assume_role" {
  statement {
    effect = "Allow"

    principals {
      type        = "Federated"
      identifiers = [aws_iam_openid_connect_provider.eks.arn]
    }

    actions = ["sts:AssumeRoleWithWebIdentity"]

    condition {
      test     = "StringEquals"
      variable = "${replace(aws_iam_openid_connect_provider.eks.url, "https://", "")}:sub"
      values   = ["system:serviceaccount:kube-system:ebs-csi-controller-sa"]
    }

    condition {
      test     = "StringEquals"
      variable = "${replace(aws_iam_openid_connect_provider.eks.url, "https://", "")}:aud"
      values   = ["sts.amazonaws.com"]
    }
  }
}

# IAM role for EBS CSI driver
resource "aws_iam_role" "ebs_csi_driver" {
  name               = "${var.project_name}-${var.environment}-ebs-csi-driver"
  assume_role_policy = data.aws_iam_policy_document.ebs_csi_driver_assume_role.json

  tags = merge(
    var.tags,
    {
      Name = "${var.project_name}-${var.environment}-ebs-csi-driver"
    }
  )
}

# Attach AWS managed policy for EBS CSI driver
resource "aws_iam_role_policy_attachment" "ebs_csi_driver" {
  role       = aws_iam_role.ebs_csi_driver.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy"
}

# Optional: KMS policy for encrypted EBS volumes (if using custom KMS keys)
# Uncomment if you need to use custom KMS encryption for your EBS volumes
# resource "aws_iam_role_policy" "ebs_csi_driver_kms" {
#   count = var.ebs_csi_kms_key_arn != null ? 1 : 0
#   name  = "${var.project_name}-${var.environment}-ebs-csi-kms"
#   role  = aws_iam_role.ebs_csi_driver.name
#
#   policy = jsonencode({
#     Version = "2012-10-17"
#     Statement = [
#       {
#         Effect = "Allow"
#         Action = [
#           "kms:Decrypt",
#           "kms:Encrypt",
#           "kms:ReEncrypt*",
#           "kms:GenerateDataKey*",
#           "kms:CreateGrant",
#           "kms:DescribeKey"
#         ]
#         Resource = var.ebs_csi_kms_key_arn
#       }
#     ]
#   })
# }
