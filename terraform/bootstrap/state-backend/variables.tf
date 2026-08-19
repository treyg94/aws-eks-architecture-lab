variable "aws_region" {
  description = "AWS Region for the Terraform state bucket and KMS key."
  type        = string
}

variable "state_bucket_name_prefix" {
  description = "Prefix combined with the current AWS account ID and region to form the globally unique state bucket name."
  type        = string

  validation {
    condition     = can(regex("^[a-z0-9][a-z0-9-]{1,36}[a-z0-9]$", var.state_bucket_name_prefix))
    error_message = "The state bucket prefix must be 3-38 lowercase alphanumeric or hyphen characters and cannot begin or end with a hyphen."
  }
}

variable "kms_alias_name" {
  description = "Friendly KMS alias name without the alias/ prefix."
  type        = string

  validation {
    condition     = length(var.kms_alias_name) > 0 && !startswith(var.kms_alias_name, "alias/")
    error_message = "The KMS alias name must be non-empty and must not include the alias/ prefix."
  }
}

variable "tags" {
  description = "Additional tags applied to the state bucket and KMS key."
  type        = map(string)
  default     = {}
}
