variable "name_prefix" {
  description = "Application and environment prefix used for workload security-group names."
  type        = string
}

variable "vpc_id" {
  description = "ID of the VPC containing the application workloads."
  type        = string
}

variable "tags" {
  description = "Application and workload-networking tags applied to the security groups."
  type        = map(string)
  default     = {}
}
