data "aws_iam_policy_document" "pod_execution_assume_role" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["eks-fargate-pods.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "pod_execution" {
  name               = "${var.cluster_name}-fargate-pod-execution-role"
  assume_role_policy = data.aws_iam_policy_document.pod_execution_assume_role.json
  tags               = var.tags
}

resource "aws_iam_role_policy_attachment" "pod_execution" {
  role       = aws_iam_role.pod_execution.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSFargatePodExecutionRolePolicy"
}

resource "aws_eks_fargate_profile" "this" {
  for_each = { for profile in var.profiles : profile.name => profile }

  cluster_name           = var.cluster_name
  fargate_profile_name   = each.value.name
  pod_execution_role_arn = aws_iam_role.pod_execution.arn
  subnet_ids             = var.subnet_ids

  dynamic "selector" {
    for_each = each.value.selectors

    content {
      namespace = selector.value.namespace
      labels    = selector.value.labels
    }
  }

  tags = var.tags

  depends_on = [aws_iam_role_policy_attachment.pod_execution]
}
