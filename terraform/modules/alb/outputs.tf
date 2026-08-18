output "arn" {
  description = "ARN of the Application Load Balancer."
  value       = aws_lb.this.arn
}

output "dns_name" {
  description = "AWS-assigned DNS name of the Application Load Balancer."
  value       = aws_lb.this.dns_name
}

output "zone_id" {
  description = "Canonical hosted zone ID of the Application Load Balancer."
  value       = aws_lb.this.zone_id
}

output "security_group_id" {
  description = "ID of the Application Load Balancer security group."
  value       = aws_security_group.this.id
}

output "target_group_arn" {
  description = "ARN of the IP target group."
  value       = aws_lb_target_group.this.arn
}
