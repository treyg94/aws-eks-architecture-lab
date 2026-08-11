variable "name" {
  description = "Name applied to the VPC Name tag."
  type        = string

  validation {
    condition     = length(trimspace(var.name)) > 0
    error_message = "The VPC name must not be empty."
  }
}

variable "cidr_block" {
  description = "IPv4 CIDR block assigned to the VPC."
  type        = string

  validation {
    condition     = can(cidrnetmask(var.cidr_block))
    error_message = "The VPC CIDR block must be a valid IPv4 CIDR."
  }
}

variable "enable_dns_support" {
  description = "Whether the VPC supports DNS resolution through the Amazon-provided DNS server."
  type        = bool
  default     = true
}

variable "enable_dns_hostnames" {
  description = "Whether instances launched in the VPC receive DNS hostnames."
  type        = bool
  default     = true
}

variable "tags" {
  description = "Additional tags applied to the VPC. The module controls the Name tag."
  type        = map(string)
  default     = {}
}
