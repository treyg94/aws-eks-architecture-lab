variable "repository_name" {
  description = "Name of the ECR repository."
  type        = string

  validation {
    condition     = can(regex("^[a-z0-9]+(?:[._/-][a-z0-9]+)*$", var.repository_name))
    error_message = "The repository name must use lowercase letters, numbers, and supported separators."
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

variable "kms_deletion_window_in_days" {
  description = "Waiting period before a scheduled ECR KMS key deletion."
  type        = number
  default     = 30

  validation {
    condition     = var.kms_deletion_window_in_days >= 7 && var.kms_deletion_window_in_days <= 30
    error_message = "The KMS deletion window must be between 7 and 30 days."
  }
}

variable "untagged_image_retention_days" {
  description = "Number of days to retain untagged images."
  type        = number
  default     = 7

  validation {
    condition     = var.untagged_image_retention_days >= 1
    error_message = "The untagged image retention period must be at least one day."
  }
}

variable "max_image_count" {
  description = "Maximum number of images retained in the repository."
  type        = number
  default     = 20

  validation {
    condition     = var.max_image_count >= 1
    error_message = "The maximum retained image count must be at least one."
  }
}

variable "tags" {
  description = "Tags applied to the ECR repository and KMS key."
  type        = map(string)
  default     = {}
}
