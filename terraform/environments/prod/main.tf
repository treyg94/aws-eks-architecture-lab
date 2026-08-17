module "vpc" {
  source = "../../modules/vpc"

  name       = "app1-prod-vpc"
  cidr_block = "10.30.0.0/16"

  enable_dns_support   = true
  enable_dns_hostnames = true

  public_subnets = [
    { availability_zone = "us-east-1a", cidr_block = "10.30.0.0/24" },
    { availability_zone = "us-east-1b", cidr_block = "10.30.1.0/24" },
    { availability_zone = "us-east-1c", cidr_block = "10.30.2.0/24" },
  ]

  private_app_subnets = [
    { availability_zone = "us-east-1a", cidr_block = "10.30.10.0/24" },
    { availability_zone = "us-east-1b", cidr_block = "10.30.11.0/24" },
    { availability_zone = "us-east-1c", cidr_block = "10.30.12.0/24" },
  ]

  private_db_subnets = [
    { availability_zone = "us-east-1a", cidr_block = "10.30.20.0/24" },
    { availability_zone = "us-east-1b", cidr_block = "10.30.21.0/24" },
    { availability_zone = "us-east-1c", cidr_block = "10.30.22.0/24" },
  ]

  create_nat_gateway = true

  tags = {
    Application = "App1"
  }
}

output "vpc_id" {
  description = "ID of the Prod VPC."
  value       = module.vpc.vpc_id
}

output "vpc_cidr_block" {
  description = "IPv4 CIDR block of the Prod VPC."
  value       = module.vpc.vpc_cidr_block
}

output "public_subnet_ids" {
  description = "IDs of the Prod public subnets, keyed by Availability Zone."
  value       = module.vpc.public_subnet_ids
}

output "private_app_subnet_ids" {
  description = "IDs of the Prod private application subnets, keyed by Availability Zone."
  value       = module.vpc.private_app_subnet_ids
}

output "private_db_subnet_ids" {
  description = "IDs of the Prod private database subnets, keyed by Availability Zone."
  value       = module.vpc.private_db_subnet_ids
}
