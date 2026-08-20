variable "oidc_issuer_url" {
  description = "OIDC issuer URL published by the EKS cluster."
  type        = string

  validation {
    condition     = startswith(var.oidc_issuer_url, "https://")
    error_message = "The OIDC issuer URL must use HTTPS."
  }
}

variable "namespace" {
  description = "Kubernetes namespace containing the workload service accounts."
  type        = string
}

variable "identities" {
  description = "IRSA workload identities keyed by a stable logical name."
  type = map(object({
    service_account_name = string
    role_name            = string
  }))
}

variable "tags" {
  description = "Tags applied to the IAM OIDC provider and IRSA roles."
  type        = map(string)
  default     = {}
}
