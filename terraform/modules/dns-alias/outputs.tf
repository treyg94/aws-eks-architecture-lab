output "fqdn" {
  description = "Fully qualified domain name of the Route 53 alias record."
  value       = aws_route53_record.this.fqdn
}
