variable "cluster_name" {
  description = "Name of the EKS cluster that receives the Pod Identity associations."
  type        = string
}

variable "namespace" {
  description = "Kubernetes namespace containing the workload service accounts."
  type        = string
}

variable "identities" {
  description = "Workload identities keyed by a stable logical name."
  type = map(object({
    service_account_name = string
    role_name            = string
  }))
}

variable "tags" {
  description = "Tags applied to Pod Identity IAM roles and associations."
  type        = map(string)
  default     = {}
}
