variable "cluster_name" {
  description = "Name of the EKS cluster."
  type        = string
}

variable "kubernetes_version" {
  description = "Kubernetes minor version for EKS."
  type        = string
}

variable "cluster_subnet_type" {
  description = "VPC subnet tier used by EKS control-plane network interfaces."
  type        = string

  validation {
    condition     = contains(["public", "private_app"], var.cluster_subnet_type)
    error_message = "Cluster subnet type must be public or private_app."
  }
}

variable "cluster_public_access_cidrs" {
  description = "IPv4 CIDRs allowed to reach the public EKS API endpoint."
  type        = list(string)
}

variable "enable_managed_nodes" {
  description = "Whether to create an EKS managed node group."
  type        = bool
}

variable "enable_fargate" {
  description = "Whether to create EKS Fargate profiles."
  type        = bool
}

variable "managed_nodes" {
  description = "Managed-node configuration. Required only when managed nodes are enabled."
  type = object({
    node_group_name = string
    subnet_type     = string
    instance_types  = list(string)
    disk_size       = number
    min_size        = number
    desired_size    = number
    max_size        = number
  })
  default  = null
  nullable = true

  validation {
    condition     = var.managed_nodes == null || contains(["public", "private_app"], var.managed_nodes.subnet_type)
    error_message = "Managed-node subnet type must be public or private_app."
  }

  validation {
    condition = var.managed_nodes == null || (
      var.managed_nodes.min_size <= var.managed_nodes.desired_size &&
      var.managed_nodes.desired_size <= var.managed_nodes.max_size
    )
    error_message = "Managed-node sizing must satisfy min_size <= desired_size <= max_size."
  }
}

variable "fargate_profiles" {
  description = "Fargate profiles. Required only when Fargate is enabled."
  type = list(object({
    name = string
    selectors = list(object({
      namespace = string
      labels    = map(string)
    }))
  }))
  default = []

}

variable "workload_identity_mode" {
  description = "Workload identity integration used by the environment."
  type        = string

  validation {
    condition     = contains(["pod_identity", "irsa"], var.workload_identity_mode)
    error_message = "Workload identity mode must be pod_identity or irsa."
  }
}

variable "workload_identity" {
  description = "Namespace and service-account IAM role names for application workloads."
  type = object({
    namespace = string
    identities = map(object({
      service_account_name = string
      role_name            = string
    }))
  })

  validation {
    condition     = toset(keys(var.workload_identity.identities)) == toset(["frontend", "backend"])
    error_message = "Workload identities must define exactly frontend and backend."
  }
}
