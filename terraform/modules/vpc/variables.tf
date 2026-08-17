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

variable "public_subnets" {
  description = "Public subnet definitions. Each Availability Zone may appear only once."
  type = list(object({
    availability_zone = string
    cidr_block        = string
  }))

  validation {
    condition     = length(var.public_subnets) > 0 && alltrue([for subnet in var.public_subnets : can(cidrnetmask(subnet.cidr_block))])
    error_message = "At least one public subnet is required, and every CIDR block must be valid IPv4 CIDR notation."
  }

  validation {
    condition     = length(distinct([for subnet in var.public_subnets : subnet.availability_zone])) == length(var.public_subnets)
    error_message = "Each public subnet must use a unique Availability Zone."
  }
}

variable "private_app_subnets" {
  description = "Private application subnet definitions. Each Availability Zone may appear only once."
  type = list(object({
    availability_zone = string
    cidr_block        = string
  }))

  validation {
    condition     = length(var.private_app_subnets) > 0 && alltrue([for subnet in var.private_app_subnets : can(cidrnetmask(subnet.cidr_block))])
    error_message = "At least one private application subnet is required, and every CIDR block must be valid IPv4 CIDR notation."
  }

  validation {
    condition     = length(distinct([for subnet in var.private_app_subnets : subnet.availability_zone])) == length(var.private_app_subnets)
    error_message = "Each private application subnet must use a unique Availability Zone."
  }
}

variable "private_db_subnets" {
  description = "Isolated private database subnet definitions. Each Availability Zone may appear only once."
  type = list(object({
    availability_zone = string
    cidr_block        = string
  }))
  default = []

  validation {
    condition     = alltrue([for subnet in var.private_db_subnets : can(cidrnetmask(subnet.cidr_block))])
    error_message = "Every private database subnet CIDR block must be valid IPv4 CIDR notation."
  }

  validation {
    condition     = length(distinct([for subnet in var.private_db_subnets : subnet.availability_zone])) == length(var.private_db_subnets)
    error_message = "Each private database subnet must use a unique Availability Zone."
  }
}

variable "create_nat_gateway" {
  description = "Whether to create one NAT gateway in the first public subnet for private application egress."
  type        = bool
  default     = false
}

variable "tags" {
  description = "Additional tags applied to the VPC. The module controls the Name tag."
  type        = map(string)
  default     = {}
}
