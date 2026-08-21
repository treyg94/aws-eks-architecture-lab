data "aws_iam_policy_document" "cluster_assume_role" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["eks.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "cluster" {
  name               = "${var.cluster_name}-cluster-role"
  assume_role_policy = data.aws_iam_policy_document.cluster_assume_role.json
  tags               = var.tags
}

resource "aws_iam_role_policy_attachment" "cluster" {
  role       = aws_iam_role.cluster.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
}

resource "aws_iam_role_policy_attachment" "vpc_resource_controller" {
  count = var.vpc_cni.enable_pod_eni ? 1 : 0

  role       = aws_iam_role.cluster.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSVPCResourceController"
}

resource "aws_cloudwatch_log_group" "cluster" {
  name              = "/aws/eks/${var.cluster_name}/cluster"
  retention_in_days = var.log_retention_days
  tags              = var.tags
}

resource "aws_eks_cluster" "this" {
  name     = var.cluster_name
  role_arn = aws_iam_role.cluster.arn
  version  = var.kubernetes_version

  enabled_cluster_log_types = [
    "api",
    "audit",
    "authenticator",
    "controllerManager",
    "scheduler",
  ]

  access_config {
    authentication_mode                         = "API_AND_CONFIG_MAP"
    bootstrap_cluster_creator_admin_permissions = false
  }

  vpc_config {
    endpoint_private_access = true
    endpoint_public_access  = true
    public_access_cidrs     = var.public_access_cidrs
    subnet_ids              = var.subnet_ids
  }

  tags = var.tags

  depends_on = [
    aws_cloudwatch_log_group.cluster,
    aws_iam_role_policy_attachment.cluster,
    aws_iam_role_policy_attachment.vpc_resource_controller,
  ]
}

resource "aws_eks_access_entry" "operator" {
  cluster_name  = aws_eks_cluster.this.name
  principal_arn = var.operator_principal_arn
  type          = "STANDARD"

  tags = var.tags
}

resource "aws_eks_access_policy_association" "operator_admin" {
  cluster_name  = aws_eks_cluster.this.name
  principal_arn = aws_eks_access_entry.operator.principal_arn
  policy_arn    = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"

  access_scope {
    type = "cluster"
  }
}

locals {
  addons = toset(concat(
    ["vpc-cni", "coredns", "kube-proxy"],
    var.enable_pod_identity_agent ? ["eks-pod-identity-agent"] : [],
  ))

  vpc_cni_environment = merge(
    var.vpc_cni.enable_pod_eni ? { ENABLE_POD_ENI = "true" } : {},
    var.vpc_cni.pod_security_group_enforcing_mode != null ? {
      POD_SECURITY_GROUP_ENFORCING_MODE = var.vpc_cni.pod_security_group_enforcing_mode
    } : {},
    var.vpc_cni.enable_prefix_delegation ? { ENABLE_PREFIX_DELEGATION = "true" } : {},
    var.vpc_cni.warm_ip_target != null ? { WARM_IP_TARGET = tostring(var.vpc_cni.warm_ip_target) } : {},
    var.vpc_cni.minimum_ip_target != null ? { MINIMUM_IP_TARGET = tostring(var.vpc_cni.minimum_ip_target) } : {},
  )

  addon_configuration_values = {
    "vpc-cni" = length(local.vpc_cni_environment) > 0 ? jsonencode({
      env = local.vpc_cni_environment
    }) : null
    coredns = var.coredns_compute_type != null ? jsonencode({
      computeType = var.coredns_compute_type
    }) : null
    kube-proxy             = null
    eks-pod-identity-agent = null
  }
}

resource "aws_eks_addon" "this" {
  for_each = local.addons

  cluster_name = aws_eks_cluster.this.name
  addon_name   = each.value

  configuration_values = local.addon_configuration_values[each.value]

  tags = var.tags
}
