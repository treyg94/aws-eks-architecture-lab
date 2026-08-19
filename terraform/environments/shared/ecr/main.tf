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

module "ecr" {
  source = "../../../modules/ecr"

  repository_name               = var.repository_name
  kms_alias_name                = var.kms_alias_name
  kms_deletion_window_in_days   = var.kms_deletion_window_in_days
  untagged_image_retention_days = var.untagged_image_retention_days
  max_image_count               = var.max_image_count

  tags = {
    Application = "App1"
    Component   = "ContainerRegistry"
  }
}
