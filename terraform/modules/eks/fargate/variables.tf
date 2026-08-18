variable "cluster_name" {
  description = "Name of the EKS cluster."
  type        = string
}

variable "subnet_ids" {
  description = "Private subnet IDs available to every Fargate profile."
  type        = list(string)
}

variable "profiles" {
  description = "Fargate profiles and their namespace and label selectors."
  type = list(object({
    name = string
    selectors = list(object({
      namespace = string
      labels    = map(string)
    }))
  }))

  validation {
    condition     = length(var.profiles) > 0 && alltrue([for profile in var.profiles : length(profile.selectors) > 0])
    error_message = "At least one Fargate profile is required, and every profile must have at least one selector."
  }
}

variable "tags" {
  description = "Tags applied to Fargate AWS resources."
  type        = map(string)
  default     = {}
}
