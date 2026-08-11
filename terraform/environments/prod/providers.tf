provider "aws" {
  region = "us-east-1"

  default_tags {
    tags = {
      Project     = "aws-eks-architecture-lab"
      Environment = "prod"
      ManagedBy   = "Terraform"
    }
  }
}
