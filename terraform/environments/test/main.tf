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

output "private_db_subnet_ids" {
  description = "IDs of the Test private database subnets, keyed by Availability Zone."
  value       = module.vpc.private_db_subnet_ids
}
