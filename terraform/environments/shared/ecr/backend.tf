terraform {
  backend "s3" {
    bucket       = "aws-eks-architecture-lab-tfstate-203156341699-us-east-1"
    key          = "shared/ecr/terraform.tfstate"
    region       = "us-east-1"
    kms_key_id   = "arn:aws:kms:us-east-1:203156341699:key/881fa2ea-a930-41e0-a3cd-6e41c291061b"
    encrypt      = true
    use_lockfile = true
  }
}
