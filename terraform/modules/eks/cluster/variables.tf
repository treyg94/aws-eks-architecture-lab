variable "cluster_name" {
  description = "Name of the EKS cluster and its supporting IAM and logging resources."
  type        = string
}

variable "kubernetes_version" {
  description = "Kubernetes minor version for the EKS control plane."
  type        = string
}

variable "subnet_ids" {
  description = "Subnet IDs used by EKS control-plane network interfaces."
  type        = list(string)

  validation {
    condition     = length(var.subnet_ids) >= 2
    error_message = "The EKS cluster requires at least two subnets."
  }
}

variable "public_access_cidrs" {
  description = "IPv4 CIDR blocks allowed to reach the public EKS API endpoint."
  type        = list(string)
}

variable "operator_principal_arn" {
  description = "Durable IAM user or role ARN granted cluster-admin access through an EKS Access Entry."
  type        = string
}

variable "log_retention_days" {
  description = "CloudWatch retention period for EKS control-plane logs."
  type        = number
  default     = 3
}

variable "coredns_compute_type" {
  description = "Optional CoreDNS add-on compute type, such as Fargate for a Fargate-only cluster."
  type        = string
  default     = null

  validation {
    condition     = var.coredns_compute_type == null || contains(["EC2", "Fargate"], var.coredns_compute_type)
    error_message = "CoreDNS compute type must be EC2, Fargate, or null."
  }
}

variable "enable_pod_identity_agent" {
  description = "Whether to install the EKS Pod Identity Agent add-on."
  type        = bool
  default     = false
}

variable "vpc_cni" {
  description = "Supported Amazon VPC CNI settings translated into EKS add-on configuration."
  type = object({
    enable_pod_eni                    = optional(bool, false)
    pod_security_group_enforcing_mode = optional(string)
    enable_prefix_delegation          = optional(bool, false)
    warm_ip_target                    = optional(number)
    minimum_ip_target                 = optional(number)
  })
  default = {}

  validation {
    condition = (
      var.vpc_cni.pod_security_group_enforcing_mode == null ||
      contains(["standard", "strict"], var.vpc_cni.pod_security_group_enforcing_mode)
    )
    error_message = "VPC CNI Pod security group enforcing mode must be standard, strict, or null."
  }

  validation {
    condition = alltrue([
      try(var.vpc_cni.warm_ip_target >= 0 && floor(var.vpc_cni.warm_ip_target) == var.vpc_cni.warm_ip_target, true),
      try(var.vpc_cni.minimum_ip_target >= 0 && floor(var.vpc_cni.minimum_ip_target) == var.vpc_cni.minimum_ip_target, true),
    ])
    error_message = "VPC CNI warm and minimum IP targets must be non-negative whole numbers or null."
  }
}

variable "tags" {
  description = "Tags applied to EKS and supporting AWS resources."
  type        = map(string)
  default     = {}
}
