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

variable "tags" {
  description = "Tags applied to EKS and supporting AWS resources."
  type        = map(string)
  default     = {}
}
