module "vpc" {
  source = "../../modules/vpc"

  name       = "app1-test-vpc"
  cidr_block = "10.20.0.0/16"

  enable_dns_support   = true
  enable_dns_hostnames = true

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
