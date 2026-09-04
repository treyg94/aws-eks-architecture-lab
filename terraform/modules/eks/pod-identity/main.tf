data "aws_iam_policy_document" "assume_role" {
  statement {
    effect = "Allow"
    actions = [
      "sts:AssumeRole",
      "sts:TagSession",
    ]

    principals {
      type        = "Service"
      identifiers = ["pods.eks.amazonaws.com"]
    }
  }
}

locals {
  identities = merge(
    {
      for name, identity in var.identities : name => {
        namespace            = var.namespace
        service_account_name = identity.service_account_name
        role_name            = identity.role_name
      }
    },
    var.additional_identities,
  )
}

resource "aws_iam_role" "this" {
  for_each = local.identities

  name               = each.value.role_name
  assume_role_policy = data.aws_iam_policy_document.assume_role.json
  tags               = var.tags
}

resource "aws_eks_pod_identity_association" "this" {
  for_each = local.identities

  cluster_name    = var.cluster_name
  namespace       = each.value.namespace
  service_account = each.value.service_account_name
  role_arn        = aws_iam_role.this[each.key].arn

  tags = var.tags
}
