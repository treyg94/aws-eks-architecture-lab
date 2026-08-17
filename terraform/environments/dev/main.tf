module "vpc" {
  source = "../../modules/vpc"

  name       = "app1-dev-vpc"
  cidr_block = "10.10.0.0/16"

  enable_dns_support   = true
  enable_dns_hostnames = true

  public_subnets = [
    { availability_zone = "us-east-1a", cidr_block = "10.10.0.0/24" },
    { availability_zone = "us-east-1b", cidr_block = "10.10.1.0/24" },
  ]

  private_app_subnets = [
    { availability_zone = "us-east-1a", cidr_block = "10.10.10.0/24" },
    { availability_zone = "us-east-1b", cidr_block = "10.10.11.0/24" },
  ]

  create_nat_gateway = false

  tags = {
    Application = "App1"
  }
}

output "vpc_id" {
  description = "ID of the Dev VPC."
  value       = module.vpc.vpc_id
}

output "vpc_cidr_block" {
  description = "IPv4 CIDR block of the Dev VPC."
  value       = module.vpc.vpc_cidr_block
}

output "public_subnet_ids" {
  description = "IDs of the Dev public subnets, keyed by Availability Zone."
  value       = module.vpc.public_subnet_ids
}

output "private_app_subnet_ids" {
  description = "IDs of the Dev private application subnets, keyed by Availability Zone."
  value       = module.vpc.private_app_subnet_ids
}
