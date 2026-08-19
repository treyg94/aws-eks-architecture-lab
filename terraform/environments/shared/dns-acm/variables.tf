variable "aws_region" {
  description = "AWS Region where the ACM certificate is requested."
  type        = string
}

variable "hosted_zone_name" {
  description = "Name of the existing public Route 53 hosted zone."
  type        = string
}

variable "certificate_domain" {
  description = "Wildcard domain name requested on the shared ACM certificate."
  type        = string
}
