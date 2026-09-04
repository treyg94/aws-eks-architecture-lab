variable "policy_name" {
  description = "Name of the IAM policy for the AWS Load Balancer Controller."
  type        = string
}

variable "role_name" {
  description = "Name of the controller IAM role that receives the required permissions."
  type        = string
}

variable "tags" {
  description = "Tags applied to the controller IAM policy."
  type        = map(string)
  default     = {}
}
