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

  operator_principal_arn = data.aws_iam_session_context.operator.issuer_arn
  log_retention_days     = 3
  coredns_compute_type   = var.enable_fargate && !var.enable_managed_nodes ? "Fargate" : null

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

output "eks_cluster_name" {
  description = "Name of the environment EKS cluster."
  value       = module.eks_cluster.cluster_name
}

output "eks_cluster_endpoint" {
  description = "Endpoint of the environment EKS Kubernetes API server."
  value       = module.eks_cluster.cluster_endpoint
}


output "private_db_subnet_ids" {
  description = "IDs of the Test private database subnets, keyed by Availability Zone."
  value       = module.vpc.private_db_subnet_ids
}
