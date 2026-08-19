variable "aws_region" {
  description = "AWS Region where the shared ECR repository is created."
  type        = string
}

variable "repository_name" {
  description = "Name of the shared application ECR repository."
  type        = string
}

variable "kms_alias_name" {
  description = "Friendly KMS alias name without the alias/ prefix."
  type        = string
}

variable "kms_deletion_window_in_days" {
  description = "Waiting period before a scheduled ECR KMS key deletion."
  type        = number
}

variable "untagged_image_retention_days" {
  description = "Number of days to retain untagged images."
  type        = number
}

variable "max_image_count" {
  description = "Maximum number of images retained in the repository."
  type        = number
}
