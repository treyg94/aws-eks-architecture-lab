module "vpc" {
  source = "../../modules/vpc"

  name       = "app1-test-vpc"
  cidr_block = "10.20.0.0/16"

  enable_dns_support   = true
  enable_dns_hostnames = true

  public_subnets = [
    { availability_zone = "us-east-1a", cidr_block = "10.20.0.0/24" },
    { availability_zone = "us-east-1b", cidr_block = "10.20.1.0/24" },
    { availability_zone = "us-east-1c", cidr_block = "10.20.2.0/24" },
  ]

  private_app_subnets = [
    { availability_zone = "us-east-1a", cidr_block = "10.20.10.0/24" },
    { availability_zone = "us-east-1b", cidr_block = "10.20.11.0/24" },
    { availability_zone = "us-east-1c", cidr_block = "10.20.12.0/24" },
  ]

  private_db_subnets = [
    { availability_zone = "us-east-1a", cidr_block = "10.20.20.0/24" },
    { availability_zone = "us-east-1b", cidr_block = "10.20.21.0/24" },
    { availability_zone = "us-east-1c", cidr_block = "10.20.22.0/24" },
  ]

  create_nat_gateway = true

  tags = {
    Application = "App1"
  }
}

output "vpc_id" {
  description = "ID of the Test VPC."
  value       = module.vpc.vpc_id
}

output "vpc_cidr_block" {
  description = "IPv4 CIDR block of the Test VPC."
  value       = module.vpc.vpc_cidr_block
}

output "public_subnet_ids" {
  description = "IDs of the Test public subnets, keyed by Availability Zone."
  value       = module.vpc.public_subnet_ids
}

output "private_app_subnet_ids" {
  description = "IDs of the Test private application subnets, keyed by Availability Zone."
  value       = module.vpc.private_app_subnet_ids
}


data "aws_caller_identity" "current" {}

data "aws_partition" "current" {}

data "aws_region" "current" {}

data "aws_iam_session_context" "operator" {
  arn = data.aws_caller_identity.current.arn
}

locals {
  eks_subnet_ids = {
    public      = values(module.vpc.public_subnet_ids)
    private_app = values(module.vpc.private_app_subnet_ids)
  }

  eks_tags = {
    Application = "App1"
  }
}

module "eks_cluster" {
  source = "../../modules/eks/cluster"

  cluster_name        = var.cluster_name
  kubernetes_version  = var.kubernetes_version
  subnet_ids          = local.eks_subnet_ids[var.cluster_subnet_type]
  public_access_cidrs = var.cluster_public_access_cidrs

  operator_principal_arn    = data.aws_iam_session_context.operator.issuer_arn
  log_retention_days        = 3
  coredns_compute_type      = var.enable_fargate && !var.enable_managed_nodes ? "Fargate" : null
  enable_pod_identity_agent = var.workload_identity_mode == "pod_identity"
  vpc_cni                   = var.vpc_cni

  tags = local.eks_tags
}

module "eks_managed_nodes" {
  count  = var.enable_managed_nodes ? 1 : 0
  source = "../../modules/eks/managed-nodes"

  cluster_name    = module.eks_cluster.cluster_name
  node_group_name = try(var.managed_nodes.node_group_name, null)
  subnet_ids      = local.eks_subnet_ids[try(var.managed_nodes.subnet_type, "private_app")]
  instance_types  = try(var.managed_nodes.instance_types, [])
  disk_size       = try(var.managed_nodes.disk_size, null)
  min_size        = try(var.managed_nodes.min_size, null)
  desired_size    = try(var.managed_nodes.desired_size, null)
  max_size        = try(var.managed_nodes.max_size, null)

  tags = local.eks_tags
}

module "eks_fargate" {
  count  = var.enable_fargate ? 1 : 0
  source = "../../modules/eks/fargate"

  cluster_name = module.eks_cluster.cluster_name
  subnet_ids   = local.eks_subnet_ids.private_app
  profiles     = var.fargate_profiles

  tags = local.eks_tags
}

module "eks_pod_identity" {
  count  = var.workload_identity_mode == "pod_identity" ? 1 : 0
  source = "../../modules/eks/pod-identity"

  cluster_name = module.eks_cluster.cluster_name
  namespace    = var.workload_identity.namespace
  identities   = var.workload_identity.identities

  tags = local.eks_tags

  depends_on = [module.eks_cluster]
}

module "eks_irsa" {
  count  = var.workload_identity_mode == "irsa" ? 1 : 0
  source = "../../modules/eks/irsa"

  oidc_issuer_url = module.eks_cluster.cluster_oidc_issuer_url
  namespace       = var.workload_identity.namespace
  identities      = var.workload_identity.identities

  tags = local.eks_tags
}

output "eks_cluster_name" {
  description = "Name of the environment EKS cluster."
  value       = module.eks_cluster.cluster_name
}

output "eks_cluster_endpoint" {
  description = "Endpoint of the environment EKS Kubernetes API server."
  value       = module.eks_cluster.cluster_endpoint
}

output "frontend_workload_role_arn" {
  description = "ARN of the Test frontend workload IAM role."
  value = var.workload_identity_mode == "pod_identity" ? (
    module.eks_pod_identity[0].role_arns["frontend"]
  ) : module.eks_irsa[0].role_arns["frontend"]
}

output "backend_workload_role_arn" {
  description = "ARN of the Test backend workload IAM role."
  value = var.workload_identity_mode == "pod_identity" ? (
    module.eks_pod_identity[0].role_arns["backend"]
  ) : module.eks_irsa[0].role_arns["backend"]
}


output "private_db_subnet_ids" {
  description = "IDs of the Test private database subnets, keyed by Availability Zone."
  value       = module.vpc.private_db_subnet_ids
}

module "alb" {
  source = "../../modules/alb"

  name              = var.alb.name
  vpc_id            = module.vpc.vpc_id
  public_subnet_ids = values(module.vpc.public_subnet_ids)

  target_port        = var.alb.target_port
  target_cidr_blocks = [module.vpc.vpc_cidr_block]
  health_check_path  = var.alb.health_check_path
  certificate_arn    = data.aws_acm_certificate.wildcard.arn
  ssl_policy         = var.alb.ssl_policy

  tags = {
    Application = "App1"
  }
}

output "alb_dns_name" {
  description = "AWS-assigned DNS name of the Test Application Load Balancer."
  value       = module.alb.dns_name
}

output "alb_target_group_arn" {
  description = "ARN of the Test ALB IP target group."
  value       = module.alb.target_group_arn
}

data "aws_acm_certificate" "wildcard" {
  domain      = var.dns.certificate_domain
  statuses    = ["ISSUED"]
  types       = ["AMAZON_ISSUED"]
  most_recent = true
}

module "dns_alias" {
  source = "../../modules/dns-alias"

  hosted_zone_name = var.dns.hosted_zone_name
  record_name      = var.dns.record_name
  alias_dns_name   = module.alb.dns_name
  alias_zone_id    = module.alb.zone_id
}

output "application_dns_name" {
  description = "Route 53 alias name for the Test application."
  value       = module.dns_alias.fqdn
}

module "workload_security_groups" {
  source = "../../modules/workload-security-groups"

  name_prefix = var.workload_security_group_name_prefix
  vpc_id      = module.vpc.vpc_id

  tags = {
    Application = "App1"
    Component   = "WorkloadNetworking"
  }
}

module "rds" {
  source = "../../modules/rds"

  identifier                         = var.rds.identifier
  engine_version                     = var.rds.engine_version
  instance_class                     = var.rds.instance_class
  storage_type                       = var.rds.storage_type
  allocated_storage                  = var.rds.allocated_storage
  master_username                    = var.rds.master_username
  vpc_id                             = module.vpc.vpc_id
  backend_workload_security_group_id = module.workload_security_groups.backend_security_group_id
  subnet_ids                         = values(module.vpc.private_db_subnet_ids)
  publicly_accessible                = var.rds.publicly_accessible
  operator_access_cidrs              = var.rds.operator_access_cidrs
  backup_retention_period            = var.rds.backup_retention_period
  kms_alias_name                     = var.rds.kms_alias_name

  tags = {
    Application = "App1"
    Component   = "Database"
  }
}

output "rds_endpoint" {
  description = "Connection endpoint of the Test RDS instance."
  value       = module.rds.endpoint
}

output "rds_port" {
  description = "Connection port of the Test RDS instance."
  value       = module.rds.port
}

output "rds_instance_identifier" {
  description = "Identifier of the Test RDS instance."
  value       = module.rds.db_instance_identifier
}

output "rds_instance_arn" {
  description = "ARN of the Test RDS instance."
  value       = module.rds.db_instance_arn
}

output "rds_master_secret_arn" {
  description = "ARN of the Test RDS-managed master credential secret."
  value       = module.rds.master_secret_arn
}

output "rds_kms_key_arn" {
  description = "ARN of the Test RDS KMS key."
  value       = module.rds.kms_key_arn
}

output "backend_workload_security_group_id" {
  description = "ID of the Test backend workload security group."
  value       = module.workload_security_groups.backend_security_group_id
}

output "rds_security_group_id" {
  description = "ID of the Test RDS security group."
  value       = module.rds.rds_security_group_id
}

output "frontend_workload_security_group_id" {
  description = "ID of the Test frontend workload security group."
  value       = module.workload_security_groups.frontend_security_group_id
}

module "frontend_api_url_parameter" {
  source = "../../modules/parameter-store"

  name        = var.frontend_api_url_parameter.name
  description = "Test frontend API URL."
  value       = var.frontend_api_url_parameter.value

  tags = {
    Application = "App1"
    Component   = "ApplicationConfiguration"
  }
}

data "aws_iam_policy_document" "frontend_api_url_read" {
  statement {
    effect    = "Allow"
    actions   = ["ssm:GetParameter"]
    resources = [module.frontend_api_url_parameter.parameter_arn]
  }
}

resource "aws_iam_role_policy" "frontend_api_url_read" {
  name = "${var.cluster_name}-frontend-api-url-read"
  role = var.workload_identity_mode == "pod_identity" ? (
    module.eks_pod_identity[0].role_names["frontend"]
  ) : module.eks_irsa[0].role_names["frontend"]

  policy = data.aws_iam_policy_document.frontend_api_url_read.json
}

data "aws_iam_policy_document" "backend_rds_connect" {
  statement {
    effect  = "Allow"
    actions = ["rds-db:connect"]
    resources = [
      "arn:${data.aws_partition.current.partition}:rds-db:${data.aws_region.current.region}:${data.aws_caller_identity.current.account_id}:dbuser:${module.rds.db_resource_id}/app1_backend",
    ]
  }
}

resource "aws_iam_role_policy" "backend_rds_connect" {
  name = "${var.cluster_name}-backend-rds-connect"
  role = var.workload_identity_mode == "pod_identity" ? (
    module.eks_pod_identity[0].role_names["backend"]
  ) : module.eks_irsa[0].role_names["backend"]

  policy = data.aws_iam_policy_document.backend_rds_connect.json
}

output "frontend_api_url_parameter_name" {
  description = "Name of the Test frontend API URL parameter."
  value       = module.frontend_api_url_parameter.parameter_name
}

output "frontend_api_url_parameter_arn" {
  description = "ARN of the Test frontend API URL parameter."
  value       = module.frontend_api_url_parameter.parameter_arn
}
