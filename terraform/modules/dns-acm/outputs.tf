output "certificate_arn" {
  description = "ARN of the DNS-validated ACM certificate."
  value       = aws_acm_certificate_validation.this.certificate_arn
}

output "hosted_zone_id" {
  description = "ID of the existing public Route 53 hosted zone."
  value       = data.aws_route53_zone.this.zone_id
}
