aws_region               = "us-east-1"
state_bucket_name_prefix = "aws-eks-architecture-lab-tfstate"
kms_alias_name           = "aws-eks-architecture-lab-terraform-state"

tags = {
  Component = "TerraformState"
}
