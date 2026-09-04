variable "cluster_name" {
  description = "Name of the EKS cluster that receives the Pod Identity associations."
  type        = string
}

variable "namespace" {
  description = "Kubernetes namespace containing the workload service accounts."
  type        = string
}

variable "identities" {
  description = "Identities in the default namespace, keyed by a stable logical name."
  type = map(object({
    service_account_name = string
    role_name            = string
  }))
}

variable "additional_identities" {
  description = "Additional identities that may use namespaces other than the default namespace."
  type = map(object({
    namespace            = string
    service_account_name = string
    role_name            = string
  }))
  default = {}
}

variable "tags" {
  description = "Tags applied to Pod Identity IAM roles and associations."
  type        = map(string)
  default     = {}
}
