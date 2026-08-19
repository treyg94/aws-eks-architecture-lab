variable "hosted_zone_name" {
  description = "Name of the existing public Route 53 hosted zone."
  type        = string
}

variable "certificate_domain" {
  description = "Domain name requested on the ACM certificate."
  type        = string
}

variable "tags" {
  description = "Tags applied to the ACM certificate."
  type        = map(string)
  default     = {}
}
