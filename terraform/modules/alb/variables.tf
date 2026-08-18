variable "name" {
  description = "Name of the Application Load Balancer and supporting resources."
  type        = string

  validation {
    condition     = length(var.name) > 0 && length(var.name) <= 29
    error_message = "The ALB name must contain 1-29 characters so the target group suffix remains within AWS naming limits."
  }
}

variable "vpc_id" {
  description = "ID of the VPC that contains the ALB and target group."
  type        = string
}

variable "public_subnet_ids" {
  description = "Public subnet IDs spanned by the internet-facing ALB."
  type        = list(string)

  validation {
    condition     = length(var.public_subnet_ids) >= 2
    error_message = "An internet-facing ALB requires at least two public subnets."
  }
}

variable "target_port" {
  description = "TCP port used by the HTTP target group and ALB egress rule."
  type        = number

  validation {
    condition     = var.target_port >= 1 && var.target_port <= 65535
    error_message = "Target port must be between 1 and 65535."
  }
}

variable "target_cidr_blocks" {
  description = "IPv4 CIDR blocks containing application targets allowed by ALB egress."
  type        = list(string)

  validation {
    condition     = length(var.target_cidr_blocks) > 0 && alltrue([for cidr in var.target_cidr_blocks : can(cidrnetmask(cidr))])
    error_message = "At least one valid IPv4 application target CIDR block is required."
  }
}

variable "health_check_path" {
  description = "HTTP path used for target group health checks."
  type        = string
  default     = "/"
}

variable "certificate_arn" {
  description = "Optional ACM certificate ARN. When set, HTTPS is enabled and HTTP redirects to HTTPS."
  type        = string
  default     = null
  nullable    = true
}

variable "ssl_policy" {
  description = "TLS security policy for the optional HTTPS listener."
  type        = string
  default     = "ELBSecurityPolicy-TLS13-1-2-2021-06"
}

variable "tags" {
  description = "Tags applied to ALB resources."
  type        = map(string)
  default     = {}
}
