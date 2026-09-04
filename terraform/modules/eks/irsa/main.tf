locals {
  oidc_provider_hostpath = replace(var.oidc_issuer_url, "https://", "")
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

resource "aws_iam_openid_connect_provider" "this" {
  url            = var.oidc_issuer_url
  client_id_list = ["sts.amazonaws.com"]
  tags           = var.tags
}

data "aws_iam_policy_document" "assume_role" {
  for_each = local.identities

  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type        = "Federated"
      identifiers = [aws_iam_openid_connect_provider.this.arn]
    }

    condition {
      test     = "StringEquals"
      variable = "${local.oidc_provider_hostpath}:aud"
      values   = ["sts.amazonaws.com"]
    }

    condition {
      test     = "StringEquals"
      variable = "${local.oidc_provider_hostpath}:sub"
      values   = ["system:serviceaccount:${each.value.namespace}:${each.value.service_account_name}"]
    }
  }
}

resource "aws_iam_role" "this" {
  for_each = local.identities

  name               = each.value.role_name
  assume_role_policy = data.aws_iam_policy_document.assume_role[each.key].json
  tags               = var.tags
}
