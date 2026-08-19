variable "hosted_zone_name" {
  description = "Name of the existing public Route 53 hosted zone."
  type        = string
}

variable "record_name" {
  description = "Fully qualified DNS record name for the ALB alias."
  type        = string
}

variable "alias_dns_name" {
  description = "AWS-assigned DNS name of the alias target."
  type        = string
}

variable "alias_zone_id" {
  description = "Canonical hosted zone ID of the alias target."
  type        = string
}
