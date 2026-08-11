module "vpc" {
  source = "../../modules/vpc"

  name       = "app1-prod-vpc"
  cidr_block = "10.30.0.0/16"

  enable_dns_support   = true
  enable_dns_hostnames = true

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
