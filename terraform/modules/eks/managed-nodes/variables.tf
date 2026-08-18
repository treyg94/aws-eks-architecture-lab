variable "cluster_name" {
  description = "Name of the EKS cluster."
  type        = string
}

variable "node_group_name" {
  description = "Name of the EKS managed node group."
  type        = string
}

variable "subnet_ids" {
  description = "Subnet IDs used by the managed node group."
  type        = list(string)
}

variable "instance_types" {
  description = "EC2 instance types used by the managed node group."
  type        = list(string)
}

variable "disk_size" {
  description = "Node root volume size in GiB."
  type        = number
}

variable "min_size" {
  description = "Minimum managed node count."
  type        = number
}

variable "desired_size" {
  description = "Desired managed node count."
  type        = number
}

variable "max_size" {
  description = "Maximum managed node count."
  type        = number
}

variable "tags" {
  description = "Tags applied to managed-node AWS resources."
  type        = map(string)
  default     = {}
}
