# ============================================================================
# EKS MODULE - EBS CSI Driver Addon
# ============================================================================

# Get the latest EBS CSI driver version
data "aws_eks_addon_version" "ebs_csi" {
  addon_name         = "aws-ebs-csi-driver"
  kubernetes_version = aws_eks_cluster.main.version
  most_recent        = true
}

# Install EBS CSI driver as EKS managed addon
resource "aws_eks_addon" "ebs_csi_driver" {
  cluster_name             = aws_eks_cluster.main.name
  addon_name               = "aws-ebs-csi-driver"
  addon_version            = data.aws_eks_addon_version.ebs_csi.version
  service_account_role_arn = aws_iam_role.ebs_csi_driver.arn

  # Resolve conflicts by overwriting existing resources
  resolve_conflicts_on_create = "OVERWRITE"
  resolve_conflicts_on_update = "OVERWRITE"

  # Preserve the addon on deletion (optional - change to false if you want to delete it)
  preserve = false

  tags = merge(
    var.tags,
    {
      Name = "${var.project_name}-${var.environment}-ebs-csi-addon"
    }
  )

  depends_on = [
    aws_eks_cluster.main,
    aws_iam_role_policy_attachment.ebs_csi_driver,
    aws_iam_openid_connect_provider.eks
  ]
}
