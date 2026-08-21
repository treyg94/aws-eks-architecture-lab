output "frontend_security_group_id" {
  description = "ID of the frontend workload security group."
  value       = aws_security_group.frontend.id
}

output "backend_security_group_id" {
  description = "ID of the backend workload security group."
  value       = aws_security_group.backend.id
}
