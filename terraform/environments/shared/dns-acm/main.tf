terraform {
  required_version = ">= 1.15.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Project     = "aws-eks-architecture-lab"
      Environment = "shared"
      ManagedBy   = "Terraform"
    }
  }
}

module "dns_acm" {
  source = "../../../modules/dns-acm"

  hosted_zone_name   = var.hosted_zone_name
  certificate_domain = var.certificate_domain

  tags = {
    Application = "App1"
  }
}

output "certificate_arn" {
  description = "ARN of the validated shared wildcard ACM certificate."
  value       = module.dns_acm.certificate_arn
}

output "hosted_zone_id" {
  description = "ID of the existing public Route 53 hosted zone."
  value       = module.dns_acm.hosted_zone_id
}
